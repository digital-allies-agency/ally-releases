#!/usr/bin/env python3
# Hilfsschritte für installieren.sh (Installationspaket, Konzept Installation und Updates C.8). Nur Standardbibliothek.
# Liest den Beipackzettel fassungen/<fassung>.json im entpackten Paket. Werte dieser Installation kommen aus Umgebungsvariablen,
# nie aus Dateien des Pakets; Geheimnisse werden nie ausgegeben.
#
#   hilfe.py pruefen       <paket> <fassung>             sha256 aller Dateien des Zettels; Status „bereit“
#   hilfe.py zugangsdaten  <paket> <fassung> <ziel.json>  Zugangsdaten mit den Standardnamen und IDs der Workflows (leer bis auf interne Dienste)
#   hilfe.py workflows     <paket> <fassung> <ziel-dir>   Workflows mit ersetzten Platzhaltern + <ziel-dir>/../aktiv.txt (IDs mit Standard an)
#   hilfe.py migrationen   <paket> <fassung>             Migrationen nach dem Grundstand (Zettel „migrationen“, in dieser Reihenfolge), je Zeile ein Pfad
#   hilfe.py einstellungen <paket> <fassung> <ziel.sql>   Einstellungen, Firmenzeile ohne Firmendaten und Web-App-Dateien als SQL (eine Transaktion)
#   hilfe.py n8n_konto     <paket> <fassung>             n8n-Konto (Eigentümer) anlegen, API-Schlüssel erzeugen und in die Zugangsdaten „n8n API“ eintragen
#   hilfe.py ally_passwort <paket> <fassung>             SQL (stdin für psql) zum Setzen des Ally-Passworts über den Einmal-Code aus erstes_superadmin
import hashlib, json, os, sys, time, secrets, http.client


def zettel(paket, fassung):
    z = json.load(open(os.path.join(paket, 'fassungen', fassung + '.json'), encoding='utf-8'))
    if z.get('fassung') != fassung:
        raise SystemExit('Beipackzettel passt nicht zur Fassung %s' % fassung)
    return z


def sha256(p):
    h = hashlib.sha256()
    with open(p, 'rb') as f:
        for b in iter(lambda: f.read(1 << 20), b''):
            h.update(b)
    return h.hexdigest()


def dateien(z):
    g = z.get('grundstand') or {}
    out = [(d['datei'], d['sha256']) for d in g.get('dateien', [])]
    if g.get('erstes_superadmin'):
        out.append((g['erstes_superadmin']['datei'], g['erstes_superadmin']['sha256']))
    for m in z.get('migrationen', []):
        out.append((m['datei'], m['sha256']))
    out += [(w['datei'], w['sha256']) for w in z['workflows']]
    out += [(w['datei'], w['sha256']) for w in z['webapp']]
    return out


def migrationen(paket, fassung):
    # Plan 64: Migrationen nach dem Grundstand (Prüfsummen schon in pruefen); Reihenfolge wie im Zettel
    for m in zettel(paket, fassung).get('migrationen', []):
        if not os.path.isfile(os.path.join(paket, m['datei'])) or sha256(os.path.join(paket, m['datei'])) != m['sha256']:
            raise SystemExit('Prüfsumme falsch oder Datei fehlt: %s' % m['datei'])
        print(m['datei'])


def pruefen(paket, fassung):
    z = zettel(paket, fassung)
    if z.get('status') != 'bereit':
        raise SystemExit('Fassung %s ist nicht „bereit“ (Status %s)' % (fassung, z.get('status')))
    fehler = [d for d, s in dateien(z) if not os.path.isfile(os.path.join(paket, d)) or sha256(os.path.join(paket, d)) != s]
    if fehler:
        raise SystemExit('Prüfsumme falsch oder Datei fehlt (%d): %s' % (len(fehler), ', '.join(fehler[:5])))
    print('Paket geprüft: %d Dateien, Fassung %s' % (len(dateien(z)), fassung))


def zuordnung(paket, z):
    # Name+Typ -> ID, wie in den Workflows eingetragen (eine ID je Name; die Workflows verweisen so ohne Änderung auf die neuen Zugangsdaten)
    m = {}
    for w in z['workflows']:
        for n in json.load(open(os.path.join(paket, w['datei']), encoding='utf-8'))['nodes']:
            for typ, c in (n.get('credentials') or {}).items():
                k = (typ, c['name'])
                if m.setdefault(k, c['id']) != c['id']:
                    raise SystemExit('Zugangsdaten %s haben in den Workflows verschiedene IDs' % (k,))
    return m


def zugangsdaten(paket, fassung, ziel):
    z = zettel(paket, fassung)
    e = os.environ
    gefuellt = {
        ('postgres', 'Postgres n8n_data'): {'host': 'postgres', 'database': 'ally', 'user': 'ally', 'password': e['ALLY_DB_PASSWORD'], 'port': 5432,
                                            'ssl': 'disable', 'allowUnauthorizedCerts': False},
        ('httpHeaderAuth', 'Matrix Admin (Ally)'): {'name': 'Authorization', 'value': 'Bearer ' + e['MATRIX_ADMIN_TOKEN']},
        ('matrixApi', 'Matrix - Ally-Bot'): {'accessToken': e['MATRIX_BOT_TOKEN'], 'homeserverUrl': 'http://synapse:8008'},
        ('httpHeaderAuth', 'Matrix Listener Bot'): {'name': 'X-Internal-Token', 'value': e['ALLY_INTERNAL_SECRET']},
        # n8n API: Wert setzt „n8n_konto“ nach dem Anlegen des n8n-Kontos; GitHub: Token aus dem Startbefehl (Stefan 01.11.2026: keine Handgriffe nach der Installation)
        ('httpHeaderAuth', 'n8n API'): {'name': 'X-N8N-API-KEY', 'value': ''},
        ('httpHeaderAuth', 'GitHub'): {'name': 'Authorization', 'value': ('Bearer ' + e['ALLY_GITHUB_TOKEN']) if e.get('ALLY_GITHUB_TOKEN') else ''},
    }
    out = [{'id': i, 'name': name, 'type': typ, 'data': gefuellt.get((typ, name), {})} for (typ, name), i in sorted(zuordnung(paket, z).items())]
    fd = os.open(ziel, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(fd, 'w', encoding='utf-8') as f:
        json.dump(out, f, ensure_ascii=False)
    print('Zugangsdaten vorbereitet: %d (mit internen Werten: Postgres, Matrix-Verwaltung, Ally-Bot, Chat-Bot; übrige leer)' % len(out))


def workflows(paket, fassung, ziel):
    z = zettel(paket, fassung)
    ids = {name: i for (typ, name), i in zuordnung(paket, z).items()}
    werte = {'__ALLY_ZUGANG_SYSTEMNACHRICHTEN_SMTP__': ids.get('Systemnachrichten – Versand (SMTP)', '')}
    # __ALLY_N8N_ORDNER_POSTFAECHER__ (nicht Pflicht): bleibt stehen; ALLY 9 legt Postfach-Workflows dann ohne Ordner an (Zettel „ohne_ersatz“)
    for p in z.get('installationswerte', []):
        if p['pflicht'] and not werte.get(p['platzhalter']):
            raise SystemExit('Kein Wert für Pflicht-Platzhalter %s' % p['platzhalter'])
    os.makedirs(ziel, exist_ok=True)
    aktiv = []
    for w in z['workflows']:
        t = open(os.path.join(paket, w['datei']), encoding='utf-8').read()
        for k, v in werte.items():
            t = t.replace(k, v)
        d = json.loads(t)
        d['active'] = False
        open(os.path.join(ziel, os.path.basename(w['datei'])), 'w', encoding='utf-8').write(json.dumps(d, ensure_ascii=False))
        if w['aktiv_standard'] is True:
            aktiv.append(w['id'])
    open(os.path.join(os.path.dirname(os.path.abspath(ziel)), 'aktiv.txt'), 'w').write('\n'.join(aktiv) + '\n')
    print('Workflows vorbereitet: %d (Standard an: %d)' % (len(z['workflows']), len(aktiv)))


def fnv(t):
    # wie ALLY 42 „Dateien prüfen“ (JavaScript charCodeAt = UTF-16-Codeeinheiten)
    a, b = 2166136261, 5381
    u = t.encode('utf-16-le')
    for i in range(0, len(u), 2):
        c = u[i] | (u[i + 1] << 8)
        a = ((a ^ c) * 16777619) & 0xFFFFFFFF
        b = (b * 33 + c) & 0xFFFFFFFF
    return '%08x%08x' % (a, b)


def q(s):
    return "'" + s.replace("'", "''") + "'"


def einstellungen(paket, fassung, ziel):
    z = zettel(paket, fassung)
    e = os.environ
    ids = {name: i for (typ, name), i in zuordnung(paket, z).items()}
    werte = {
        'oberflaeche_adresse': 'https://' + e['ALLY_HOST'],
        'n8n_oeffentlich': 'https://' + e['ALLY_HOST'],   # Fehler Nr. 26 (Stefan 02.11.2026 „a“): öffentliche Adresse = Oberfläche (traefik leitet /webhook/ an n8n)
        'chat_server_name': e['CHAT_SERVER'],   # fest „chat“, unabhängig von der Chat-Adresse
        'chat_adresse': 'https://' + e['CHAT_HOST'],   # öffentliche Chat-Adresse (Anmeldung in Element), später änderbar
        'chat_assistent': e['CHAT_ASSISTENT'],   # Chat-ID des Bots (@ki:chat)
        'chat_admin_adresse': 'http://synapse:8008',
        'webapp_repo': e['UPDATE_QUELLE'],
        'update_quelle': e['UPDATE_QUELLE'],
        'ki_credential_id': ids.get('KI-Zugang (Anthropic)', ''),
        'systemnachrichten_credential_id': ids.get('Systemnachrichten – Versand (SMTP)', ''),
    }
    sql = ['BEGIN;']
    for k, v in werte.items():
        sql.append("INSERT INTO public.ally_einstellungen (schluessel, wert, geaendert_am, geaendert_von) VALUES (%s, %s, now(), 'Installation') "
                   "ON CONFLICT (schluessel) DO UPDATE SET wert = EXCLUDED.wert, geaendert_am = now(), geaendert_von = 'Installation';" % (q(k), q(v)))
    # Firma (Stefan 01.11.2026: keine Frage im Installationspaket): Zeile id 1 muss es geben (Funktionen schreiben nur per UPDATE auf id 1), ohne Firmendaten.
    # Name, Logo und Farben kommen nur aus dem eigenen Unternehmen der Seite Einstellungen › Firmendaten und Design (Migration 197 verknüpft es beim Anlegen).
    sql.append("INSERT INTO public.ally_firma (id) VALUES (1);")
    for w in z['webapp']:
        t = open(os.path.join(paket, w['datei']), encoding='utf-8').read()
        name = os.path.basename(w['datei'])
        if (name == 'app.js' and len(t) <= 10000) or len(t) <= 1000 or t.lstrip().startswith('<'):
            raise SystemExit('Web-App-Datei %s unplausibel' % name)
        sql.append("INSERT INTO public.ally_webapp_dateien (name, inhalt, fassung, bytes, quelle, geaendert_am) VALUES (%s, %s, %s, %d, %s, now()) "
                   "ON CONFLICT (name) DO UPDATE SET inhalt = EXCLUDED.inhalt, fassung = EXCLUDED.fassung, bytes = EXCLUDED.bytes, quelle = EXCLUDED.quelle, geaendert_am = now();"
                   % (q(name), q(t), q(fnv(t)), len(t.encode('utf-8')), q('Installation Fassung ' + fassung)))
    sql.append('COMMIT;')
    open(ziel, 'w', encoding='utf-8').write('\n'.join(sql) + '\n')
    print('Einstellungen vorbereitet: %d Werte, Firma, Web-App %d Dateien' % (len(werte), len(z['webapp'])))


def _rest(methode, pfad, koerper=None, kopf=None):
    c = http.client.HTTPConnection('127.0.0.1', 5678, timeout=15)
    h = {'Content-Type': 'application/json', 'Accept': 'application/json'}
    h.update(kopf or {})
    c.request(methode, pfad, body=None if koerper is None else json.dumps(koerper), headers=h)
    r = c.getresponse()
    daten = r.read()
    return r.status, r.getheader('Set-Cookie') or '', daten


def n8n_konto(paket, fassung):
    # n8n 2.42.7: POST /rest/owner/setup setzt das Anmelde-Cookie n8n-auth (an die browser-id gebunden); damit Scopes holen, API-Schlüssel anlegen
    # (POST /rest/api-keys, expiresAt null) und die Zugangsdaten „n8n API“ ändern (PATCH /rest/credentials/:id). Schlüssel und Passwort werden nie ausgegeben.
    e = os.environ
    z = zettel(paket, fassung)
    cid = {name: i for (typ, name), i in zuordnung(paket, z).items()}.get('n8n API')
    if not cid:
        raise SystemExit('Zugangsdaten „n8n API“ fehlen im Zettel.')
    bid = secrets.token_hex(16)
    konto = {'email': e['SA_EMAIL'], 'firstName': e['VORNAME'], 'lastName': e['NACHNAME'], 'password': e['SA_PW']}
    status, cookie = 0, ''
    for _ in range(40):  # n8n meldet healthz, bevor die Anmelde-Schnittstelle bereit ist (01.11.2026: erste Anfrage 404)
        try:
            status, cookie, _d = _rest('POST', '/rest/owner/setup', konto, {'browser-id': bid})
        except OSError:
            status, _d = 0, b''
        if status == 200:
            break
        if status == 400:  # n8n lehnt ab (z. B. Konto schon angelegt): nicht wiederholen
            try:
                grund = json.loads(_d).get('message', '')
            except (ValueError, AttributeError):
                grund = ''
            raise SystemExit('n8n-Konto abgelehnt (Antwort 400%s).' % ((': ' + grund[:200]) if grund else ''))
        time.sleep(3)
    if status != 200:
        raise SystemExit('n8n-Konto konnte nicht angelegt werden (Antwort %s; der n8n-Editor bleibt von außen gesperrt).' % status)
    print('ok  n8n-Konto angelegt (%s)' % e['SA_EMAIL'])
    wert = next((s.split('=', 1)[1] for s in cookie.split(';') if s.strip().startswith('n8n-auth=')), '')
    if not wert:
        raise SystemExit('n8n hat keine Anmeldung zurückgegeben; API-Schlüssel nicht angelegt.')
    kopf = {'browser-id': bid, 'Cookie': 'n8n-auth=' + wert}
    s, _c, d = _rest('GET', '/rest/api-keys/scopes', None, kopf)
    if s != 200:
        raise SystemExit('n8n: Berechtigungen für den API-Schlüssel nicht lesbar (Antwort %s).' % s)
    scopes = json.loads(d)['data']
    s, _c, d = _rest('POST', '/rest/api-keys', {'label': 'Ally', 'scopes': scopes, 'expiresAt': None}, kopf)
    if s != 200:
        raise SystemExit('n8n: API-Schlüssel nicht angelegt (Antwort %s).' % s)
    schluessel = json.loads(d)['data']['rawApiKey']
    s, _c, d = _rest('PATCH', '/rest/credentials/' + cid,
                     {'name': 'n8n API', 'type': 'httpHeaderAuth', 'data': {'name': 'X-N8N-API-KEY', 'value': schluessel}}, kopf)
    if s != 200:
        raise SystemExit('n8n: Zugangsdaten „n8n API“ nicht gespeichert (Antwort %s).' % s)
    s, _c, _d = _rest('GET', '/api/v1/workflows?limit=1', None, {'X-N8N-API-KEY': schluessel})
    if s != 200:
        raise SystemExit('n8n: API-Schlüssel angelegt, aber nicht nutzbar (Antwort %s).' % s)
    print('ok  n8n-API-Schlüssel angelegt und eingetragen')


def ally_passwort(paket, fassung):
    # Wie die Web-App (Formular.tsx, Passwortfelder v2): SHA-256 von „ally-v2:“ + Passwort, Länge in UTF-16-Zeichen; gesetzt über ally_web_passwort_neu
    # mit dem Einmal-Code aus erstes_superadmin. Werte nur über stdin an psql (nicht in der Prozessliste); die dabei angelegte Sitzung wird entfernt.
    e = os.environ
    code, pw = e['ALLY_CODE'], e['SA_PW']
    if not (len(code) == 64 and all(ch in '0123456789abcdef' for ch in code)):
        raise SystemExit('Einmal-Code ungültig.')
    h = hashlib.sha256(('ally-v2:' + pw).encode('utf-8')).hexdigest()
    laenge = len(pw.encode('utf-16-le')) // 2
    print("\\set code '%s'\n\\set h '%s'\n\\set l '%d'" % (code, h, laenge))
    print("SELECT (ally_web_passwort_neu(jsonb_build_object('code', :'code', 'neu', :'h', 'wiederholung', :'h', 'laenge', :'l')))->>'ok' AS ok \\gset")
    print("DELETE FROM ally_web_sitzungen s USING ally_personen p WHERE s.matrix_user_id = p.matrix_user_id AND p.pw_hash IS NOT NULL;")
    print("SELECT 'ally_passwort|' || :'ok';")


if __name__ == '__main__':
    if len(sys.argv) < 4:
        raise SystemExit('Aufruf: hilfe.py pruefen|zugangsdaten|workflows|einstellungen|migrationen|n8n_konto|ally_passwort <paket> <fassung> [ziel]')
    befehl, paket, fassung = sys.argv[1:4]
    {'pruefen': lambda: pruefen(paket, fassung), 'zugangsdaten': lambda: zugangsdaten(paket, fassung, sys.argv[4]),
     'workflows': lambda: workflows(paket, fassung, sys.argv[4]), 'einstellungen': lambda: einstellungen(paket, fassung, sys.argv[4]),
     'migrationen': lambda: migrationen(paket, fassung), 'n8n_konto': lambda: n8n_konto(paket, fassung),
     'ally_passwort': lambda: ally_passwort(paket, fassung)}[befehl]()
