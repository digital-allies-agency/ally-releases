import asyncio
import base64
import io
import logging
import os
import secrets
import aiohttp
from aiohttp import web
from nio import (
    AsyncClient, AsyncClientConfig, RoomMessageText, MegolmEvent, SyncResponse,
    RoomMessageImage, RoomMessageFile, RoomEncryptedImage, RoomEncryptedFile,
    RoomMemberEvent, RoomCreateError,
)

try:
    from nio import RoomPreset
except ImportError:
    from nio.api import RoomPreset
import json

try:
    from nio.crypto import decrypt_attachment, encrypt_attachment
except ImportError:
    from nio.crypto.attachments import decrypt_attachment, encrypt_attachment

from PIL import Image, ImageOps

try:
    from pillow_heif import register_heif_opener
    register_heif_opener()
except Exception:
    pass

logging.basicConfig(level=logging.WARNING, format="%(asctime)s %(name)s %(levelname)s %(message)s")


# Werte dieser Installation aus der Umgebung (env_file, nur root lesbar); nichts fest eingetragen.
# Standard im Installationspaket: Chat-Server und n8n im selben Docker-Netz, Webhooks von ALLY 1 (ally-matrix-eingang) und ALLY 3 (ally-datei-eingang).
HOMESERVER = os.environ.get("MATRIX_HOMESERVER", "http://synapse:8008")
USER_ID = os.environ["MATRIX_USER_ID"]
DEVICE_ID = os.environ.get("MATRIX_DEVICE_ID", "ALLYBOTV2")
ACCESS_TOKEN = os.environ["MATRIX_ACCESS_TOKEN"]
STORE_PATH = "/app/store"
N8N_WEBHOOK_URL = os.environ.get("N8N_WEBHOOK_URL", "http://n8n:5678/webhook/ally-matrix-eingang")
N8N_DATEI_WEBHOOK_URL = os.environ.get("N8N_DATEI_WEBHOOK_URL", "http://n8n:5678/webhook/ally-datei-eingang")

# Groessenlimit fuer Dateien aus dem Chat (nach Entschluesselung)
MAX_DATEI_BYTES = 10 * 1024 * 1024

# Wartezeiten (Sekunden) vor dem 2., 3., ... Versuch, falls n8n nicht mit 200 antwortet.
# Summe ca. 5 Minuten. Doppelte Zustellung ist unkritisch: n8n verarbeitet jede event_id nur einmal.
RETRY_DELAYS = (5, 15, 30, 60, 90, 120)
POST_TIMEOUT = aiohttp.ClientTimeout(total=60)

SEND_HOST = "0.0.0.0"
SEND_PORT = 8765
INTERNAL_SECRET = os.environ["ALLY_INTERNAL_SECRET"]

UMLEITUNGEN_DATEI = os.path.join(STORE_PATH, "umleitungen.json")

CLIENT = None
PENDING_TASKS = set()
UMLEITUNGEN = {}      # alter Raum -> neuer Raum (wenn der Chat geloescht wurde)
WARTESCHLANGE = {}    # neuer Raum -> Nachrichten, bis der Empfaenger beigetreten ist
RAUM_LOCK = asyncio.Lock()


def lade_umleitungen():
    global UMLEITUNGEN
    try:
        with open(UMLEITUNGEN_DATEI, "r", encoding="utf-8") as f:
            UMLEITUNGEN = json.load(f)
    except FileNotFoundError:
        UMLEITUNGEN = {}
    except Exception as e:
        print(f"[UMLEITUNG] Datei nicht lesbar: {e!r}", flush=True)
        UMLEITUNGEN = {}


def speichere_umleitungen():
    try:
        with open(UMLEITUNGEN_DATEI, "w", encoding="utf-8") as f:
            json.dump(UMLEITUNGEN, f)
    except Exception as e:
        print(f"[UMLEITUNG] Datei nicht speicherbar: {e!r}", flush=True)


def beigetretene_mitglieder(room_id):
    room = CLIENT.rooms.get(room_id) if CLIENT else None
    if room is None:
        return None
    eingeladen = set(getattr(room, "invited_users", {}) or {})
    return [u for u in room.users if u != USER_ID and u not in eingeladen]


async def aktive_mitglieder(room_id):
    # Beigetretene Mitglieder ausser Ally laut Server; None, wenn keine sichere Auskunft.
    try:
        resp = await CLIENT.joined_members(room_id)
        members = getattr(resp, "members", None)
        if members is None:
            print(f"[UMLEITUNG] Mitglieder von {room_id} nicht abrufbar: {resp!r}", flush=True)
            return None
        return [m.user_id for m in members if m.user_id != USER_ID]
    except Exception as e:
        print(f"[UMLEITUNG] Mitgliederabfrage fehlgeschlagen: {e!r}", flush=True)
        return None


async def ehemalige_mitglieder(room_id):
    try:
        resp = await CLIENT.room_get_state(room_id)
        ergebnis = []
        for ev in getattr(resp, "events", []) or []:
            if ev.get("type") == "m.room.member" and ev.get("state_key") != USER_ID \
                    and (ev.get("content") or {}).get("membership") in ("leave", "ban"):
                ergebnis.append(ev.get("state_key"))
        return ergebnis
    except Exception as e:
        print(f"[UMLEITUNG] Raumzustand nicht lesbar: {e!r}", flush=True)
        return []


async def raum_fuer_nutzer(nutzer, ausser=None):
    # Sucht einen Chat, in dem genau dieser Nutzer mit Ally ist, sonst neuer Chat mit Einladung.
    # Liefert (Raum, warten). warten=True: Nutzer muss die Einladung erst annehmen.
    for rid in list(CLIENT.rooms.keys()):
        if rid != ausser and beigetretene_mitglieder(rid) == [nutzer]:
            print(f"[UMLEITUNG] bestehender Raum {rid} fuer {nutzer}", flush=True)
            return rid, False
    resp = await CLIENT.room_create(
        is_direct=True,
        invite=[nutzer],
        preset=RoomPreset.trusted_private_chat,
        initial_state=[{"type": "m.room.encryption", "state_key": "",
                        "content": {"algorithm": "m.megolm.v1.aes-sha2"}}],
    )
    if isinstance(resp, RoomCreateError):
        raise RuntimeError(f"Raum konnte nicht angelegt werden: {resp.message}")
    neu = resp.room_id
    WARTESCHLANGE[neu] = [{"msgtype": "m.notice",
                           "body": "Neuer Chat mit Ally: Meine Nachrichten kommen ab jetzt hier an."}]
    print(f"[UMLEITUNG] neuer Raum {neu} fuer {nutzer} angelegt", flush=True)
    return neu, True


async def ziel_raum(room_id, user_id=None):
    # Liefert (Zielraum, warten). warten=True: Empfaenger ist noch nicht im Raum, Nachricht vormerken.
    async with RAUM_LOCK:
        if not room_id:
            if not user_id:
                raise RuntimeError("Weder room_id noch user_id angegeben")
            return await raum_fuer_nutzer(user_id)
        for _ in range(5):
            if room_id in UMLEITUNGEN:
                room_id = UMLEITUNGEN[room_id]
        if room_id in WARTESCHLANGE:
            return room_id, True
        mitglieder = await aktive_mitglieder(room_id)
        if mitglieder is None:
            # Server liefert keine sichere Auskunft: normal senden
            return room_id, False
        if mitglieder:
            if user_id and user_id not in mitglieder:
                # Gespeicherter Raum gehoert nicht (mehr) zu diesem Nutzer: dessen eigenen Chat nehmen
                return await raum_fuer_nutzer(user_id, ausser=room_id)
            return room_id, False
        # Nur Ally ist noch im Raum: Chat wurde geloescht
        if user_id:
            nutzer = user_id
        else:
            ehemalige = await ehemalige_mitglieder(room_id)
            if not ehemalige:
                raise RuntimeError(f"Empfaenger fuer verlassenen Raum {room_id} unbekannt")
            nutzer = ehemalige[0]
        neu, warten = await raum_fuer_nutzer(nutzer, ausser=room_id)
        UMLEITUNGEN[room_id] = neu
        speichere_umleitungen()
        try:
            await CLIENT.room_leave(room_id)
            print(f"[UMLEITUNG] verwaisten Raum {room_id} verlassen (neu: {neu})", flush=True)
        except Exception as e:
            print(f"[UMLEITUNG] Verlassen fehlgeschlagen: {e!r}", flush=True)
        return neu, warten


async def warteschlange_senden(room_id):
    # Kurz warten, damit die Geraeteschluessel des Empfaengers bekannt sind
    await asyncio.sleep(5)
    await trust_known_devices()
    nachrichten = WARTESCHLANGE.pop(room_id, [])
    for content in nachrichten:
        try:
            resp = await CLIENT.room_send(room_id=room_id, message_type="m.room.message",
                                          content=content, ignore_unverified_devices=True)
            print(f"[SEND-NACHGEHOLT] room={room_id} event_id={getattr(resp, 'event_id', None)}", flush=True)
        except Exception as e:
            print(f"[SEND-NACHGEHOLT-ERROR] room={room_id} error={e!r}", flush=True)


async def on_member(room, event):
    if event.membership == "join" and event.state_key != USER_ID and room.room_id in WARTESCHLANGE:
        print(f"[UMLEITUNG] {event.state_key} ist {room.room_id} beigetreten, sende {len(WARTESCHLANGE[room.room_id])} Nachricht(en)", flush=True)
        start_background(warteschlange_senden(room.room_id))


async def trust_known_devices():
    if CLIENT is None:
        return
    # Alle bekannten Nutzer (Ally und die berechtigten Personen in ihren Chats)
    for user_id in list(CLIENT.device_store.users):
        for device in CLIENT.device_store.active_user_devices(user_id):
            if not device.verified:
                CLIENT.verify_device(device)
                print(f"[TRUST] {user_id} / {device.device_id} als vertrauenswuerdig markiert", flush=True)


async def send_notice(room_id, text):
    try:
        await CLIENT.room_send(
            room_id=room_id,
            message_type="m.room.message",
            content={"msgtype": "m.notice", "body": text},
            ignore_unverified_devices=True,
        )
    except Exception as e:
        print(f"[NOTIFY-ERROR] {e!r}", flush=True)


async def notify_unreachable(room_id):
    await send_notice(room_id, "Ally ist gerade nicht erreichbar (n8n antwortet nicht). Bitte die Nachricht in ein paar Minuten noch einmal schicken.")


async def forward_to_n8n(payload, room_id, url=N8N_WEBHOOK_URL):
    attempts = len(RETRY_DELAYS) + 1
    for attempt in range(1, attempts + 1):
        try:
            async with aiohttp.ClientSession(timeout=POST_TIMEOUT) as session:
                async with session.post(url, json=payload, headers={"X-Internal-Token": INTERNAL_SECRET}) as resp:
                    print(f"[POST] event={payload['event_id']} url={url.rsplit('/', 1)[-1]} versuch={attempt} status={resp.status}", flush=True)
                    if resp.status == 200:
                        return
        except Exception as e:
            print(f"[POST-ERROR] event={payload['event_id']} versuch={attempt} error={e!r}", flush=True)

        if attempt < attempts:
            await asyncio.sleep(RETRY_DELAYS[attempt - 1])

    print(f"[POST-AUFGEGEBEN] event={payload['event_id']} nach {attempts} Versuchen", flush=True)
    await notify_unreachable(room_id)


def start_background(coro):
    task = asyncio.create_task(coro)
    PENDING_TASKS.add(task)
    task.add_done_callback(PENDING_TASKS.discard)


async def on_message(room, event):
    print(f"[EVENT] room={room.room_id} sender={event.sender} body={event.body!r}", flush=True)
    if event.sender == USER_ID:
        return
    # Bei Antworten in Element (Antwort-Funktion) steht die Bezugsnachricht in m.relates_to.
    content = event.source.get("content", {}) if isinstance(event.source, dict) else {}
    reply_to = ((content.get("m.relates_to") or {}).get("m.in_reply_to") or {}).get("event_id", "")
    text = event.body or ""
    if reply_to and text.startswith("> "):
        # Zitat der Originalnachricht (Fallback aelterer Clients) entfernen
        teile = text.split("\n\n", 1)
        text = teile[1] if len(teile) > 1 else text
    payload = {
        "event_id": event.event_id, "room_id": room.room_id,
        "sender": event.sender, "text": text, "reply_to": reply_to
    }
    # Im Hintergrund weiterleiten, damit Wiederholungen den Matrix-Sync nicht blockieren.
    start_background(forward_to_n8n(payload, room.room_id))


async def download_mxc(mxc):
    # Laedt eine Datei vom Homeserver (zuerst authentifizierter Endpunkt, dann klassischer).
    if not mxc or not mxc.startswith("mxc://"):
        raise RuntimeError(f"ungueltige Medien-URL: {mxc!r}")
    server, media_id = mxc[len("mxc://"):].split("/", 1)
    headers = {"Authorization": f"Bearer {ACCESS_TOKEN}"}
    urls = (
        f"{HOMESERVER}/_matrix/client/v1/media/download/{server}/{media_id}",
        f"{HOMESERVER}/_matrix/media/v3/download/{server}/{media_id}",
    )
    async with aiohttp.ClientSession(timeout=aiohttp.ClientTimeout(total=120)) as session:
        for url in urls:
            async with session.get(url, headers=headers) as resp:
                if resp.status == 200:
                    return await resp.read()
                print(f"[DOWNLOAD] {url} status={resp.status}", flush=True)
    raise RuntimeError("Download vom Homeserver fehlgeschlagen")


def bild_zu_pdf(daten):
    # Wandelt ein Foto (JPEG, PNG, HEIC ...) in ein einseitiges PDF um.
    bild = Image.open(io.BytesIO(daten))
    bild = ImageOps.exif_transpose(bild).convert("RGB")
    puffer = io.BytesIO()
    bild.save(puffer, "PDF", resolution=150.0)
    return puffer.getvalue()


async def verarbeite_datei(room, event):
    content = event.source.get("content", {}) if isinstance(event.source, dict) else {}
    info = content.get("info") or {}
    mimetype = (info.get("mimetype") or getattr(event, "mimetype", "") or "").lower()
    body = content.get("body") or ""
    dateiname = content.get("filename") or body or "datei"
    # Neuere Clients: body = Bildunterschrift, filename = Dateiname
    beschriftung = body if content.get("filename") and body and body != content.get("filename") else ""

    try:
        daten = await download_mxc(event.url)
        if isinstance(event, (RoomEncryptedImage, RoomEncryptedFile)):
            daten = decrypt_attachment(daten, event.key["k"], event.hashes["sha256"], event.iv)
        if len(daten) > MAX_DATEI_BYTES:
            await send_notice(room.room_id, f"Die Datei {dateiname} ist zu gross (max. 10 MB).")
            return
        if mimetype.startswith("image/") or isinstance(event, (RoomMessageImage, RoomEncryptedImage)):
            daten = bild_zu_pdf(daten)
            dateiname = dateiname.rsplit(".", 1)[0] + ".pdf"
            mimetype = "application/pdf"
    except Exception as e:
        print(f"[DATEI-ERROR] event={event.event_id} error={e!r}", flush=True)
        await send_notice(room.room_id, f"Die Datei {dateiname} konnte ich nicht lesen. Bitte noch einmal schicken, am besten als PDF.")
        return

    payload = {
        "event_id": event.event_id, "room_id": room.room_id, "sender": event.sender,
        "filename": dateiname, "mimetype": mimetype, "caption": beschriftung,
        "data_base64": base64.b64encode(daten).decode("ascii"),
    }
    print(f"[DATEI] event={event.event_id} name={dateiname!r} typ={mimetype} bytes={len(daten)}", flush=True)
    await forward_to_n8n(payload, room.room_id, url=N8N_DATEI_WEBHOOK_URL)


async def on_file(room, event):
    print(f"[EVENT-DATEI] room={room.room_id} sender={event.sender} typ={type(event).__name__}", flush=True)
    if event.sender == USER_ID:
        return
    start_background(verarbeite_datei(room, event))


async def on_undecryptable(room, event):
    print(f"[UNDECRYPTABLE] room={room.room_id} sender={event.sender}", flush=True)
    try:
        await CLIENT.request_room_key(event)
        print(f"[KEY-REQUEST] angefordert für event={event.event_id}", flush=True)
    except Exception as e:
        print(f"[KEY-REQUEST-ERROR] {e!r}", flush=True)


async def on_sync(response):
    for room_id in response.rooms.invite.keys():
        print(f"[INVITE] trete Raum bei: {room_id}", flush=True)
        result = await CLIENT.join(room_id)
        print(f"[JOIN] {result}", flush=True)

    await trust_known_devices()


async def upload_datei(daten, dateiname, mimetype, verschluesselt):
    # Laedt eine Datei auf den Homeserver und liefert den Inhalt fuer eine m.file-Nachricht.
    # In verschluesselten Chats wird die Datei vorher verschluesselt (Matrix: verschluesselte Anhaenge).
    if verschluesselt:
        inhalt, schluessel = encrypt_attachment(daten)
        art = "application/octet-stream"
    else:
        inhalt, schluessel, art = daten, None, mimetype
    headers = {"Authorization": f"Bearer {ACCESS_TOKEN}", "Content-Type": art}
    async with aiohttp.ClientSession(timeout=aiohttp.ClientTimeout(total=120)) as session:
        async with session.post(f"{HOMESERVER}/_matrix/media/v3/upload", params={"filename": dateiname},
                                data=inhalt, headers=headers) as resp:
            antwort = await resp.json(content_type=None)
            if resp.status != 200 or not antwort.get("content_uri"):
                raise RuntimeError(f"Upload fehlgeschlagen: status={resp.status}")
    content = {"msgtype": "m.file", "body": dateiname, "filename": dateiname,
               "info": {"mimetype": mimetype, "size": len(daten)}}
    if schluessel:
        datei = dict(schluessel)
        datei["url"] = antwort["content_uri"]
        datei["mimetype"] = mimetype
        content["file"] = datei
    else:
        content["url"] = antwort["content_uri"]
    return content


async def handle_send(request):
    token = request.headers.get("X-Internal-Token")
    if not token or not secrets.compare_digest(token, INTERNAL_SECRET):
        return web.json_response({"error": "unauthorized"}, status=401)

    try:
        data = await request.json()
    except Exception:
        return web.json_response({"error": "invalid json"}, status=400)

    room_id = data.get("room_id")
    user_id = data.get("user_id")
    text = data.get("text")
    html = data.get("html")

    if not text or not (room_id or user_id):
        return web.json_response({"error": "text und room_id oder user_id sind Pflichtfelder"}, status=400)

    content = {"msgtype": "m.text", "body": text}
    if html:
        content["format"] = "org.matrix.custom.html"
        content["formatted_body"] = html

    # Optional: Datei (z. B. Beleg-PDF) als eigene Nachricht direkt nach dem Text
    datei = data.get("datei")
    daten = None
    if datei:
        try:
            daten = base64.b64decode(datei.get("data_base64") or "", validate=True)
        except Exception:
            return web.json_response({"error": "datei.data_base64 ungueltig"}, status=400)
        if not daten or len(daten) > MAX_DATEI_BYTES:
            return web.json_response({"error": "Datei leer oder groesser als 10 MB"}, status=400)

    try:
        ziel, warten = await ziel_raum(room_id, user_id)
        inhalte = [content]
        if daten is not None:
            raum = CLIENT.rooms.get(ziel)
            verschluesselt = True if raum is None else bool(getattr(raum, "encrypted", True))
            inhalte.append(await upload_datei(daten, str(datei.get("name") or "datei.pdf"),
                                              str(datei.get("mimetype") or "application/pdf"), verschluesselt))
        if warten:
            WARTESCHLANGE.setdefault(ziel, []).extend(inhalte)
            print(f"[SEND-VORGEMERKT] room={ziel} (wartet auf Beitritt, {len(inhalte)} Nachricht(en))", flush=True)
            return web.json_response({"status": "queued", "event_id": None, "room_id": ziel})
        event_id = None
        datei_event_id = None
        for i, inhalt in enumerate(inhalte):
            resp = await CLIENT.room_send(
                room_id=ziel,
                message_type="m.room.message",
                content=inhalt,
                ignore_unverified_devices=True,
            )
            eid = getattr(resp, "event_id", None)
            if i == 0:
                event_id = eid
            else:
                datei_event_id = eid
            print(f"[SEND] room={ziel} event_id={eid} typ={inhalt.get('msgtype')}", flush=True)
        if daten is not None and not datei_event_id:
            return web.json_response({"status": "teilweise", "event_id": event_id, "room_id": ziel,
                                      "error": "Text gesendet, Datei nicht"}, status=500)
        return web.json_response({"status": "ok", "event_id": event_id, "datei_event_id": datei_event_id, "room_id": ziel})
    except Exception as e:
        print(f"[SEND-ERROR] room={room_id} error={e!r}", flush=True)
        return web.json_response({"error": str(e)}, status=500)


async def start_send_server():
    app = web.Application(client_max_size=20 * 1024 * 1024)
    app.router.add_post("/send", handle_send)
    runner = web.AppRunner(app)
    await runner.setup()
    site = web.TCPSite(runner, SEND_HOST, SEND_PORT)
    await site.start()
    print(f"[START] lokaler Sende-Endpunkt bereit auf http://{SEND_HOST}:{SEND_PORT}/send", flush=True)


async def main():
    global CLIENT
    config = AsyncClientConfig(store_sync_tokens=True, encryption_enabled=True)
    client = AsyncClient(HOMESERVER, USER_ID, device_id=DEVICE_ID, store_path=STORE_PATH, config=config)
    client.restore_login(user_id=USER_ID, device_id=DEVICE_ID, access_token=ACCESS_TOKEN)
    CLIENT = client

    client.add_event_callback(on_message, RoomMessageText)
    client.add_event_callback(on_file, (RoomMessageImage, RoomMessageFile, RoomEncryptedImage, RoomEncryptedFile))
    client.add_event_callback(on_undecryptable, MegolmEvent)
    client.add_event_callback(on_member, RoomMemberEvent)
    lade_umleitungen()
    client.add_response_callback(on_sync, SyncResponse)

    print("[START] Initialer Sync...", flush=True)
    await client.sync(timeout=10000, full_state=True)

    if client.should_upload_keys:
        await client.keys_upload()

    await trust_known_devices()

    await start_send_server()

    print("[START] sync_forever beginnt...", flush=True)
    await client.sync_forever(timeout=30000, full_state=False)


asyncio.run(main())
