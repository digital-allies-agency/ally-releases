#!/usr/bin/env bash
# Ally – Neu-Installation auf einem leeren Hostinger-VPS mit Ubuntu 26.04 LTS (Konzept Installation und Updates C.8 / D.6).
# Aufruf nur über den Startbefehl aus docs/installation.md (lädt das Paket, prüft es und ruft dieses Skript auf):
#   bash <paket>/server/installation/installieren.sh <fassung>
# Fragt die Adressen und die erste Person, installiert Docker und alle Dienste mit festen Versionen, spielt Grundstand und Startwerte ein,
# legt die Zugangsdaten mit den Standardnamen an (leer bis auf interne Dienste), importiert alle Workflows mit festen IDs, setzt die
# Einstellungen und trägt zuletzt die erste Person als Superadmin ein (erstes_superadmin.sql, Link einmal auf dem Bildschirm).
# Geheimnisse entstehen auf dem Server (openssl), stehen nur in /opt/ally/.env (nur root) bzw. verschlüsselt in n8n und werden nie ausgegeben.
# Läuft nur einmal je Server. Bricht etwas ab: Server im Hostinger-Panel neu aufsetzen und den Startbefehl erneut einfügen.
set -Eeuo pipefail
umask 077

FASSUNG="${1:?Fassung fehlt}"
PAKET="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ZIEL=/opt/ally
UPDATE_QUELLE=digital-allies-agency/ally-releases
HILFE="$PAKET/server/installation/hilfe.py"
# Chat-Kennungen unabhängig von der Chat-Adresse (01.11.2026): Servername fest "chat" (Teil hinter dem Doppelpunkt, nie eine Adresse),
# Konten ohne Produktnamen. Die Chat-Adresse (CHAT_HOST) steht nur in public_baseurl, traefik und Element und lässt sich später ändern.
CHAT_SERVER=chat
KONTO_BOT=ki
KONTO_VERWALTUNG=ki-admin

schritt() { printf '\n== %s\n' "$*"; }
abbruch() { printf '\nABBRUCH: %s\nNichts weiter geändert. Hilfe: docs/installation.md, Abschnitt 'Wenn etwas schiefgeht'.\n' "$*" >&2; exit 1; }
trap 'printf "\nABBRUCH im Installationsskript (Zeile %s). Hilfe: docs/installation.md, Abschnitt Wenn etwas schiefgeht.\n" "$LINENO" >&2' ERR
frage() { local text="$1" vorgabe="${2:-}" w; read -rp "$text${vorgabe:+ [$vorgabe]}: " w </dev/tty; printf '%s' "${w:-$vorgabe}"; }
host_ok() { [[ "$1" =~ ^[a-z0-9]([a-z0-9-]*[a-z0-9])?(\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)+$ ]]; }
geheim() { openssl rand -hex 32; }
dc() { (cd "$ZIEL" && docker compose "$@"); }
psql_ally() { dc exec -T postgres psql -X -q -v ON_ERROR_STOP=1 -U ally -d ally "$@"; }

# ---------------------------------------------------------------- 0. Voraussetzungen
schritt "0/9 Voraussetzungen"
[ "$(id -u)" = 0 ] || abbruch "Bitte als root ausführen (Hostinger-Webterminal ist root)."
[ -e "$ZIEL/.einrichtung-begonnen" ] && abbruch "Auf diesem Server wurde Ally schon eingerichtet (ab Schritt 5). Das Skript läuft nur auf einem neuen Server."
. /etc/os-release
[ "${ID:-}" = ubuntu ] || abbruch "Nur für Ubuntu gebaut (gefunden: ${PRETTY_NAME:-unbekannt})."
[ "${VERSION_ID:-}" = 26.04 ] || printf 'Hinweis: gebaut für Ubuntu 26.04 LTS, gefunden %s. Weiter in 10 Sekunden (Abbruch mit Strg+C).\n' "${PRETTY_NAME:-?}"; [ "${VERSION_ID:-}" = 26.04 ] || sleep 10
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq ca-certificates curl openssl python3 iproute2 >/dev/null
python3 "$HILFE" pruefen "$PAKET" "$FASSUNG"
for p in 80 443; do [ -n "$(ss -ltnH "sport = :$p")" ] && abbruch "Port $p ist schon belegt. Bitte einen leeren Server ohne Anwendungsvorlage nehmen."; done

# ---------------------------------------------------------------- 1. Fragen
schritt "1/9 Angaben (Eingabe mit Enter bestätigen; Vorschlag in [Klammern] mit Enter übernehmen)"
ALLY_HOST="$(frage 'Adresse der Oberfläche (DNS-Eintrag 1, z. B. ally.firma.de)' | tr 'A-Z' 'a-z')"
CHAT_HOST="$(frage 'Adresse des Chats (DNS-Eintrag 2, z. B. chat.firma.de)' | tr 'A-Z' 'a-z')"
N8N_HOST="$(frage 'Adresse für n8n (Vorschlag: Hostname des Servers)' "$(hostname -f 2>/dev/null | tr 'A-Z' 'a-z')" | tr 'A-Z' 'a-z')"
FIRMA="$(frage 'Firmenname des Kunden')"
SA_NAME="$(frage 'Erste Person (Superadmin): Vor- und Nachname')"
SA_EMAIL="$(frage 'E-Mail-Adresse der ersten Person (Anmeldung an der Oberfläche)' | tr 'A-Z' 'a-z')"
SA_KENNUNG="$(frage 'Chat-Name der ersten Person (nur Kleinbuchstaben/Ziffern)' "$(printf '%s' "${SA_EMAIL%%@*}" | tr -cd 'a-z0-9._-')")"
for h in "$ALLY_HOST" "$CHAT_HOST" "$N8N_HOST"; do host_ok "$h" || abbruch "'$h' ist keine gültige Adresse (nur Kleinbuchstaben, Ziffern, Punkt, Bindestrich)."; done
[ "$ALLY_HOST" != "$CHAT_HOST" ] && [ "$ALLY_HOST" != "$N8N_HOST" ] && [ "$CHAT_HOST" != "$N8N_HOST" ] || abbruch "Die drei Adressen müssen verschieden sein."
[ -n "$FIRMA" ] && [ -n "$SA_NAME" ] || abbruch "Firmenname und Name der ersten Person sind Pflicht."
[[ "$SA_EMAIL" =~ ^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$ ]] || abbruch "'$SA_EMAIL' ist keine gültige E-Mail-Adresse."
[[ "$SA_KENNUNG" =~ ^[a-z0-9._=-]+$ ]] || abbruch "Chat-Name nur aus Kleinbuchstaben, Ziffern, Punkt, Bindestrich, Unterstrich."
case "$SA_KENNUNG" in "$KONTO_BOT"|"$KONTO_VERWALTUNG") abbruch "Chat-Name '$SA_KENNUNG' ist reserviert.";; esac
printf '\nOberfläche: https://%s\nChat:       https://%s\nn8n:        https://%s\nFirma:      %s\nSuperadmin: %s <%s>, Chat @%s:%s\n' \
  "$ALLY_HOST" "$CHAT_HOST" "$N8N_HOST" "$FIRMA" "$SA_NAME" "$SA_EMAIL" "$SA_KENNUNG" "$CHAT_SERVER"
[ "$(frage 'Stimmt das? (j/n)')" = j ] || abbruch "Abgebrochen auf Wunsch. Startbefehl einfach erneut einfügen."

# ---------------------------------------------------------------- 2. DNS
schritt "2/9 DNS prüfen"
IP="$(ip -4 route get 1.1.1.1 | awk '{for (i = 1; i < NF; i++) if ($i == "src") print $(i + 1)}')"
[ -n "$IP" ] || abbruch "Öffentliche IPv4-Adresse des Servers nicht gefunden."
for h in "$ALLY_HOST" "$CHAT_HOST" "$N8N_HOST"; do
  a="$(getent ahostsv4 "$h" | awk '{print $1}' | sort -u || true)"
  if printf '%s\n' "$a" | grep -qx "$IP"; then echo "ok  $h -> $IP"
  elif [ "${ALLY_OHNE_DNS_PRUEFUNG:-}" = 1 ]; then echo "WARNUNG $h zeigt nicht auf $IP (Prüfung abgeschaltet)"
  else abbruch "$h zeigt (noch) nicht auf diesen Server ($IP). A-Eintrag im Domain-Panel prüfen, einige Minuten warten, Startbefehl erneut einfügen."; fi
done

# ---------------------------------------------------------------- 3. Docker
schritt "3/9 Docker installieren (offizielles Docker-Paketarchiv)"
if ! command -v docker >/dev/null || ! docker compose version >/dev/null 2>&1; then
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  chmod a+r /etc/apt/keyrings/docker.asc
  printf 'deb [arch=%s signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu %s stable\n' \
    "$(dpkg --print-architecture)" "${UBUNTU_CODENAME:-${VERSION_CODENAME:-}}" > /etc/apt/sources.list.d/docker.list
  chmod 644 /etc/apt/sources.list.d/docker.list
  apt-get update -qq
  apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin >/dev/null
fi
systemctl enable --now docker >/dev/null 2>&1 || true
docker --version; docker compose version

# ---------------------------------------------------------------- 4. Dateien, Geheimnisse, Images
schritt "4/9 Dienste vorbereiten und Images laden (feste Versionen)"
mkdir -p "$ZIEL"/{letsencrypt,postgres,n8n,dateien,import,synapse,element,sicherung,matrix-bot/store}
install -m 644 "$PAKET"/server/matrix-bot/{Dockerfile,listener.py,bootstrap_cross_signing.py} "$ZIEL/matrix-bot/"
: > "$ZIEL/matrix-bot.env"; chmod 600 "$ZIEL/matrix-bot.env"   # Werte folgen in Schritt 6 (docker compose braucht die Datei vorher)
install -m 644 "$PAKET/server/installation/docker-compose.yml" "$ZIEL/docker-compose.yml"
POSTGRES_PASSWORD="$(geheim)"; N8N_DB_PASSWORD="$(geheim)"; ALLY_DB_PASSWORD="$(geheim)"; SYNAPSE_DB_PASSWORD="$(geheim)"
N8N_ENCRYPTION_KEY="$(geheim)"; ALLY_SCHLUESSEL="$(geheim)"
{
  echo "# Ally – Werte dieser Installation (erzeugt $(date -u +%F)). Nur root. Nicht weitergeben, nicht ins Repo."
  echo "FASSUNG=$FASSUNG"; echo "ALLY_HOST=$ALLY_HOST"; echo "CHAT_HOST=$CHAT_HOST"; echo "N8N_HOST=$N8N_HOST"; echo "ACME_EMAIL=$SA_EMAIL"
  echo "POSTGRES_PASSWORD=$POSTGRES_PASSWORD"; echo "N8N_DB_PASSWORD=$N8N_DB_PASSWORD"; echo "ALLY_DB_PASSWORD=$ALLY_DB_PASSWORD"
  echo "SYNAPSE_DB_PASSWORD=$SYNAPSE_DB_PASSWORD"; echo "N8N_ENCRYPTION_KEY=$N8N_ENCRYPTION_KEY"
} > "$ZIEL/.env"
chmod 600 "$ZIEL/.env"
dc pull -q --ignore-buildable || abbruch "Images konnten nicht geladen werden (Version fehlt oder Netz). Nichts installiert außer Docker."
dc build -q ally-listener-bot || abbruch "Chat-Bot (Ally) konnte nicht gebaut werden. Nichts installiert außer Docker."

# ---------------------------------------------------------------- 5. Datenbanken und Grundstand
schritt "5/9 Datenbanken anlegen, Grundstand und Startwerte einspielen"
date -u +%FT%TZ > "$ZIEL/.einrichtung-begonnen"   # ab hier nur noch auf einem neu aufgesetzten Server wiederholbar; bis Schritt 4 einfach erneut starten
dc up -d postgres
for _ in $(seq 60); do dc exec -T postgres pg_isready -U postgres >/dev/null 2>&1 && break; sleep 2; done
dc exec -T postgres pg_isready -U postgres >/dev/null || abbruch "PostgreSQL startet nicht."
dc exec -T postgres psql -X -q -v ON_ERROR_STOP=1 -U postgres <<SQL
CREATE ROLE n8n LOGIN PASSWORD '$N8N_DB_PASSWORD';
CREATE DATABASE n8n OWNER n8n;
CREATE ROLE ally LOGIN PASSWORD '$ALLY_DB_PASSWORD';
CREATE DATABASE ally OWNER ally;
CREATE ROLE synapse LOGIN PASSWORD '$SYNAPSE_DB_PASSWORD';
CREATE DATABASE synapse OWNER synapse TEMPLATE template0 ENCODING 'UTF8' LC_COLLATE 'C' LC_CTYPE 'C';
ALTER DATABASE ally SET ally.schluessel = '$ALLY_SCHLUESSEL';
SQL
unset ALLY_SCHLUESSEL
G="$PAKET/grundstand/$FASSUNG"
for f in schema_vor.sql startwerte.sql schema_nach.sql; do psql_ally -1 -f - < "$G/$f"; echo "ok  $f"; done
python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["grundstand"]["fassung_eintragen"])' "$PAKET/fassungen/$FASSUNG.json" | psql_ally
CHAT_ASSISTENT="@$KONTO_BOT:$CHAT_SERVER"
export ALLY_HOST CHAT_HOST CHAT_SERVER CHAT_ASSISTENT N8N_HOST FIRMA UPDATE_QUELLE
python3 "$HILFE" einstellungen "$PAKET" "$FASSUNG" "$ZIEL/import/einstellungen.sql"
psql_ally < "$ZIEL/import/einstellungen.sql"; rm -f "$ZIEL/import/einstellungen.sql"
psql_ally -At -c "SELECT 'Fassung ' || ally_fassung_aktuell() || ', Verschlüsselung bereit: ' || ally_verschluesselung_bereit();"

# ---------------------------------------------------------------- 6. Chat-Server
schritt "6/9 Chat-Server (Synapse) und Element einrichten"
dc run --rm --no-deps -T -e SYNAPSE_SERVER_NAME="$CHAT_SERVER" -e SYNAPSE_REPORT_STATS=no synapse generate >/dev/null
export SYNAPSE_DB_PASSWORD CHAT_HOST
dc run --rm --no-deps -T -e SYNAPSE_DB_PASSWORD -e CHAT_HOST --entrypoint python synapse - <<'PY'
import os, yaml
p = '/data/homeserver.yaml'
c = yaml.safe_load(open(p))
c['database'] = {'name': 'psycopg2', 'args': {'user': 'synapse', 'password': os.environ['SYNAPSE_DB_PASSWORD'], 'dbname': 'synapse',
                 'host': 'postgres', 'port': 5432, 'cp_min': 5, 'cp_max': 10}}
c['public_baseurl'] = 'https://%s/' % os.environ['CHAT_HOST']
c['enable_registration'] = False
c['report_stats'] = False
c['suppress_key_server_warning'] = True
# Keine Föderation: Listener nur für Clients (ohne federation/keys), keine erlaubten Fremdserver, kein Schlüsselserver
for l in c.get('listeners', []):
    for r in l.get('resources', []):
        r['names'] = [n for n in r.get('names', []) if n not in ('federation', 'keys')] or ['client']
c['federation_domain_whitelist'] = []
c['trusted_key_servers'] = []
yaml.safe_dump(c, open(p, 'w'), sort_keys=False)
PY
chown -R 991:991 "$ZIEL/synapse"
cat > "$ZIEL/element/config.json" <<JSON
{"default_server_config": {"m.homeserver": {"base_url": "https://$CHAT_HOST", "server_name": "$CHAT_SERVER"}},
 "disable_custom_urls": true, "disable_guests": true, "disable_3pid_login": true, "brand": "Chat", "default_theme": "light"}
JSON
chmod 644 "$ZIEL/element/config.json"
dc up -d synapse
for _ in $(seq 90); do dc exec -T synapse curl -fsS http://localhost:8008/health >/dev/null 2>&1 && break; sleep 2; done
dc exec -T synapse curl -fsS http://localhost:8008/health >/dev/null || abbruch "Synapse startet nicht (cd /opt/ally && docker compose logs synapse)."
matrix_nutzer() {  # $1 Name, $2 Passwort, $3 admin|-
  local art=--no-admin; [ "$3" = admin ] && art=-a
  printf '%s' "$2" | dc exec -T synapse register_new_matrix_user -c /data/homeserver.yaml -u "$1" --password-file /dev/stdin "$art" http://localhost:8008 >/dev/null
}
matrix_token() {  # Zugangstoken über die Anmeldung im Docker-Netz, nie ausgegeben
  printf '{"type":"m.login.password","identifier":{"type":"m.id.user","user":"%s"},"password":"%s"}' "$1" "$2" \
    | dc exec -T synapse curl -fsS -X POST -H 'Content-Type: application/json' --data-binary @- http://localhost:8008/_matrix/client/v3/login \
    | python3 -c 'import json,sys; print(json.load(sys.stdin)["access_token"])'
}
matrix_token_geraet() {  # wie matrix_token, aber für ein festes Gerät ($3, Gerätename $4) – der Chat-Bot meldet sich mit diesem Gerät an (Schlüssel der Verschlüsselung)
  printf '{"type":"m.login.password","identifier":{"type":"m.id.user","user":"%s"},"password":"%s","device_id":"%s","initial_device_display_name":%s}' "$1" "$2" "$3" "$4" \
    | dc exec -T synapse curl -fsS -X POST -H 'Content-Type: application/json' --data-binary @- http://localhost:8008/_matrix/client/v3/login \
    | python3 -c 'import json,sys; print(json.load(sys.stdin)["access_token"])'
}
PW_ADMIN="$(geheim)"; PW_BOT="$(geheim)"; PW_SA="$(openssl rand -base64 18 | tr -d '/+=' | cut -c1-20)"
matrix_nutzer "$KONTO_VERWALTUNG" "$PW_ADMIN" admin
matrix_nutzer "$KONTO_BOT" "$PW_BOT" -
matrix_nutzer "$SA_KENNUNG" "$PW_SA" -
MATRIX_ADMIN_TOKEN="$(matrix_token "$KONTO_VERWALTUNG" "$PW_ADMIN")"; MATRIX_BOT_TOKEN="$(matrix_token "$KONTO_BOT" "$PW_BOT")"
# Anzeigename des Bots = Produktname (Einstellung produkt_name, sonst „Ally“); Token über stdin, nie in der Prozessliste
PRODUKT_JSON="$(psql_ally -At -c "SELECT to_json(coalesce(nullif(btrim(ally_einstellung('produkt_name')), ''), 'Ally'))")"
printf 'Authorization: Bearer %s\n' "$MATRIX_BOT_TOKEN" | dc exec -T synapse curl -fsS -o /dev/null -X PUT -H @- -H 'Content-Type: application/json' \
  --data-binary "{\"displayname\":$PRODUKT_JSON}" "http://localhost:8008/_matrix/client/v3/profile/%40$KONTO_BOT%3A$CHAT_SERVER/displayname" \
  || echo "WARNUNG Anzeigename des Chat-Bots nicht gesetzt (später im Chat änderbar). Installation läuft weiter."
# Chat-Bot (Container matrix-ally-listener-bot-1, wie in den Workflows): eigenes Gerät ALLYBOTV2, gemeinsames Geheimnis X-Internal-Token mit n8n
ALLY_INTERNAL_SECRET="$(geheim)"
{
  echo "MATRIX_USER_ID=$CHAT_ASSISTENT"; echo "MATRIX_DEVICE_ID=ALLYBOTV2"; echo "MATRIX_HOMESERVER=http://synapse:8008"
  echo "MATRIX_ACCESS_TOKEN=$(matrix_token_geraet "$KONTO_BOT" "$PW_BOT" ALLYBOTV2 "$PRODUKT_JSON")"; echo "ALLY_INTERNAL_SECRET=$ALLY_INTERNAL_SECRET"
  echo "N8N_WEBHOOK_URL=http://n8n:5678/webhook/ally-matrix-eingang"; echo "N8N_DATEI_WEBHOOK_URL=http://n8n:5678/webhook/ally-datei-eingang"
} > "$ZIEL/matrix-bot.env"
chmod 600 "$ZIEL/matrix-bot.env"
grep -q '^MATRIX_ACCESS_TOKEN=.\+' "$ZIEL/matrix-bot.env" || abbruch "Anmeldung des Chat-Bots fehlgeschlagen."
unset PW_ADMIN PW_BOT
echo "ok  Chat-Konten: @$KONTO_VERWALTUNG:$CHAT_SERVER, $CHAT_ASSISTENT ($PRODUKT_JSON), @$SA_KENNUNG:$CHAT_SERVER"

# ---------------------------------------------------------------- 7. n8n: Zugangsdaten, Workflows
schritt "7/9 n8n: Zugangsdaten und Workflows importieren (dauert einige Minuten)"
export ALLY_DB_PASSWORD MATRIX_ADMIN_TOKEN MATRIX_BOT_TOKEN ALLY_INTERNAL_SECRET
python3 "$HILFE" zugangsdaten "$PAKET" "$FASSUNG" "$ZIEL/import/zugangsdaten.json"
unset MATRIX_ADMIN_TOKEN MATRIX_BOT_TOKEN ALLY_INTERNAL_SECRET
python3 "$HILFE" workflows "$PAKET" "$FASSUNG" "$ZIEL/import/workflows"
chown -R 1000:1000 "$ZIEL/n8n" "$ZIEL/dateien" "$ZIEL/import"
dc run --rm -T n8n import:credentials --input=/import/zugangsdaten.json
shred -u "$ZIEL/import/zugangsdaten.json" 2>/dev/null || rm -f "$ZIEL/import/zugangsdaten.json"
dc run --rm -T n8n import:workflow --separate --input=/import/workflows
dc run --rm -T --entrypoint sh n8n -c 'n=0; f=0; while read -r i; do [ -n "$i" ] || continue; n=$((n+1));
  n8n publish:workflow --id="$i" >/dev/null 2>&1 || n8n update:workflow --id="$i" --active=true >/dev/null 2>&1 || { f=$((f+1)); echo "nicht eingeschaltet: $i"; }; done < /import/aktiv.txt;
  echo "Workflows eingeschaltet: $((n-f)) von $n"'
rm -rf "$ZIEL/import/workflows" "$ZIEL/import/aktiv.txt"

# ---------------------------------------------------------------- 8. Start
schritt "8/9 Alle Dienste starten"
dc up -d
for _ in $(seq 90); do curl -fsS http://127.0.0.1:5678/healthz >/dev/null 2>&1 && break; sleep 2; done
curl -fsS http://127.0.0.1:5678/healthz >/dev/null || abbruch "n8n startet nicht (cd /opt/ally && docker compose logs n8n)."
# n8n-Konto (Eigentümer) anlegen, solange der n8n-Editor von außen nicht erreichbar ist (Router auf .invalid, siehe docker-compose.yml)
PW_N8N="$(openssl rand -base64 24 | tr -d '/+=' | cut -c1-22)Aa7"
VORNAME="${SA_NAME%% *}"; NACHNAME="${SA_NAME#* }"; [ "$NACHNAME" != "$SA_NAME" ] || NACHNAME=Admin
export PW_N8N VORNAME NACHNAME SA_EMAIL
python3 -c 'import json,os; print(json.dumps({"email": os.environ["SA_EMAIL"], "firstName": os.environ["VORNAME"], "lastName": os.environ["NACHNAME"], "password": os.environ["PW_N8N"]}))' \
  | curl -fsS -o /dev/null -X POST -H 'Content-Type: application/json' --data-binary @- http://127.0.0.1:5678/rest/owner/setup \
  || abbruch "n8n-Konto konnte nicht angelegt werden (der n8n-Editor bleibt von außen gesperrt)."
export -n PW_N8N
echo "ok  n8n-Konto angelegt ($SA_EMAIL)"
echo "N8N_ROUTER_HOST=$N8N_HOST" >> "$ZIEL/.env"
dc up -d n8n
for _ in $(seq 90); do curl -fsS http://127.0.0.1:5678/healthz >/dev/null 2>&1 && break; sleep 2; done
curl -fsS http://127.0.0.1:5678/healthz >/dev/null || abbruch "n8n startet nach dem Freischalten nicht (cd /opt/ally && docker compose logs n8n)."
# Chat-Bot: warten, bis sein Gerät die Schlüssel hochgeladen hat, dann einmal Cross-Signing einrichten (sonst nur eine Warnung in Element)
GERAET='import os,requests; u=os.environ["MATRIX_USER_ID"]; d=os.environ["MATRIX_DEVICE_ID"]
r=requests.post("http://synapse:8008/_matrix/client/v3/keys/query",headers={"Authorization":"Bearer "+os.environ["MATRIX_ACCESS_TOKEN"]},json={"device_keys":{u:[d]}},timeout=10)
raise SystemExit(0 if d in r.json().get("device_keys",{}).get(u,{}) else 1)'
for _ in $(seq 60); do dc exec -T ally-listener-bot python -c "$GERAET" >/dev/null 2>&1 && break; sleep 3; done
if dc exec -T ally-listener-bot python -c "$GERAET" >/dev/null 2>&1 && dc exec -T ally-listener-bot python bootstrap_cross_signing.py >/dev/null 2>&1; then
  echo "ok  Chat-Bot läuft, Cross-Signing eingerichtet"
else
  echo "WARNUNG Chat-Bot: Cross-Signing nicht eingerichtet (cd /opt/ally && docker compose logs ally-listener-bot). Installation läuft weiter."
fi
cat > "$ZIEL/sicherung.sh" <<'SH'
#!/usr/bin/env bash
# Nächtliche Sicherung der Datenbanken (ally, n8n, synapse) nach /opt/ally/sicherung, 7 Tage aufbewahrt. Übertragung zur NAS: offen (docs/installation.md).
set -euo pipefail
cd /opt/ally; t="$(date +%F)"
for db in ally n8n synapse; do docker compose exec -T postgres pg_dump -U postgres -Fc "$db" > "sicherung/$t-$db.dump"; done
find sicherung -name '*.dump' -mtime +7 -delete
SH
chmod 700 "$ZIEL/sicherung.sh"
printf '17 2 * * * root /opt/ally/sicherung.sh >/opt/ally/sicherung/letzte.log 2>&1\n' > /etc/cron.d/ally-sicherung; chmod 644 /etc/cron.d/ally-sicherung

# ---------------------------------------------------------------- 9. Erste Person (allerletzter Schritt, B7a)
schritt "9/9 Erste Person als Superadmin eintragen"
ERG="$(dc exec -T postgres psql -X -q -At -F '|' -U ally -d ally -v name="$SA_NAME" -v email="$SA_EMAIL" -v chat_kennung="@$SA_KENNUNG:$CHAT_SERVER" -f - \
        < "$G/erstes_superadmin.sql" | tail -n 1)"
case "$ERG" in erstes_superadmin\|ok\|*) ;; *) abbruch "Superadmin-Schritt ohne Ergebnis 'ok'.";; esac
LINK="${ERG##*|}"; case "$LINK" in https://*) ;; *) LINK="https://$ALLY_HOST/$LINK";; esac
cp "$PAKET/fassungen/$FASSUNG.json" "$ZIEL/fassung.json"; chmod 644 "$ZIEL/fassung.json"
trap - ERR
cat <<TXT

==================================================================
 Ally $FASSUNG ist installiert.

 Oberfläche:  https://$ALLY_HOST
 Chat:        https://$CHAT_HOST   (Anmeldung: Chat-Name $SA_KENNUNG; in der
              Element-App als Server https://$CHAT_HOST eintragen; Chat-ID @$SA_KENNUNG:$CHAT_SERVER)
 n8n:         https://$N8N_HOST

 NUR JETZT SICHTBAR – bitte sofort an einem sicheren Ort notieren:
 Link zum Passwort-Festlegen (7 Tage, nur einmal):
   $LINK
 Erstes Chat-Passwort für @$SA_KENNUNG (im Chat unter Einstellungen ändern):
   $PW_SA
 n8n-Konto (Anmeldung https://$N8N_HOST mit $SA_EMAIL), Passwort:
   $PW_N8N

 Danach die Handgriffe aus docs/installation.md (n8n-Schlüssel und
 GitHub-Zugang, Passwort über den Link, Pakete und Kunden-Admin,
 Rückleitungs-Adressen in den Meta-/Threads-Apps).
==================================================================
TXT
unset PW_SA PW_N8N LINK ERG
