#!/usr/bin/env bash
# Ally – Sicherungsprogramm auf dem Server (Migration 201, Konzept „Sicherung auf die NAS“, freigegeben Stefan 03.11.2026 10:45).
# Läuft als root alle 5 Minuten über /etc/cron.d/ally-sicherung (eingerichtet von installieren.sh bzw. einmalig von einrichten.sh). Nie zwei Läufe zugleich (flock).
# Ablauf: meldet sich bei der Datenbank (öffentlicher SSH-Schlüssel, Platz auf dem Server, lokale Kopien) und übernimmt fällige Aufträge je Ziel
# (ally_sicherung_host_plan): „Verbindung prüfen“, „Jetzt sichern“ oder einen Termin des Zeitplans aus Einstellungen › System › Sicherung.
# Eine Sicherung des Anbieter-Ziels umfasst: pg_dump -Fc der Datenbanken ally, n8n, synapse; n8n-Konfiguration (Verschlüsselungsschlüssel) aus /opt/ally/n8n/config;
# /opt/ally/.env und docker-compose.yml; den Ordner /opt/ally/dateien. Zusätzlich (Vorschlag an Stefan, eigener Commit): Konfiguration und Signierschlüssel des
# Chat-Servers (/opt/ally/synapse, ohne Medien), matrix-bot.env, Element-Konfiguration und letsencrypt (Zertifikate). Kunden-Ziel (Entscheidung Stefan
# 03.11.2026 15:04): nur Inhalte = Tabellen mit Kundendaten als CSV und der Ordner dateien (kunde_stand), keine Installation, kein Schlüssel. Anbieter-Ziel: zusätzlich lokale Kopie unter /opt/ally/sicherung/lokal (eine .tar-Datei mit
# Prüfsumme je Sicherung, Aufbewahrung in Tagen). Übertragung mit restic (Docker-Image mit fester Version, nichts auf dem Host installiert) per SFTP,
# verschlüsselt mit dem Wiederherstellungs-Kennwort; danach restic forget --prune nach den Regeln und restic stats für den belegten Platz.
# Das Ergebnis schreibt ally_sicherung_host_ende zurück (bei Fehlern Benachrichtigung an Superadmins bzw. Admins).
# Geheimnisse: Je Ziel (anbieter, kunde) entsteht einmalig ein eigenes SSH-Schlüsselpaar (ed25519) unter /opt/ally/sicherung/ssh/<ziel> (700/600); nur die öffentlichen
# Schlüssel gehen in die Datenbank (der Admin sieht nur den des Kunden-Ziels).
# Das Kennwort holt das Programm je Lauf aus der Datenbank in eine Datei mit Rechten 600 (nur für restic, danach gelöscht); nie in Protokolle oder Meldungen.
# Hostschlüssel der NAS: beim ersten „Verbindung prüfen“ gelernt (Fingerabdruck in Ally), danach strikt geprüft.
# Ein Lauf hält die Installation nicht an: pg_dump sichert im laufenden Betrieb, restic läuft mit niedriger Priorität.
# Vor jeder Sicherung wird zuerst aufgeräumt (alte lokale Kopien und Dumps, verwaiste Arbeitsordner samt Kennwort-Datei), dann der Platz geprüft.
# restic-Ende 3 (Stand angelegt, einzelne Dateien nicht lesbar) = Ergebnis „mit Warnung“; aufgeräumt und gezählt wird trotzdem.
# shellcheck disable=SC1111  # deutsche Anführungszeichen in Meldungstexten sind gewollt
set -Euo pipefail
umask 077

FASSUNG=1
ZIEL="${ALLY_ZIEL:-/opt/ally}"
S="$ZIEL/sicherung"
RESTIC_IMAGE="${ALLY_RESTIC_IMAGE:-restic/restic:0.18.0}"
SCHLUESSEL=""   # je Auftrag $S/ssh/<ziel>/id_ed25519
MIN_FREI="${ALLY_MIN_FREI:-$((100 * 1024 * 1024))}"   # mindestens frei vor einer Sicherung (Byte), sonst klare Meldung
PROTOKOLL="$S/protokoll.log"
RESTIC_HOST=ally
export LC_ALL=C

log() { printf '%s %s\n' "$(date -u +%FT%TZ)" "$*" >> "$PROTOKOLL"; }
dc() { (cd "$ZIEL" && docker compose "$@"); }
# SQL über den Postgres-Container; Werte nur als psql-Variablen (-v name=wert, im SQL :'name'), nie in den SQL-Text eingesetzt
sql() { dc exec -T postgres psql -X -q -At -v ON_ERROR_STOP=1 -U ally -d ally "$@"; }

mkdir -p "$S" && chmod 700 "$S"
exec 9>"$S/.sperre"
flock -n 9 || exit 0
mkdir -p "$S/ssh/anbieter" "$S/ssh/kunde" "$S/lokal" "$S/arbeit" "$S/cache"
chmod 700 "$S/ssh" "$S/ssh/anbieter" "$S/ssh/kunde" "$S/lokal" "$S/arbeit" "$S/cache"
# Arbeitsordner eines Laufs entfernen (Kennwort-Datei zuerst mit shred)
arbeit_weg() {
  local d="$1" f
  [ -d "$d" ] || return 0
  for f in "$d"/kennwort*; do [ -f "$f" ] && { shred -u "$f" 2>/dev/null || rm -f "$f"; }; done
  rm -rf -- "${d:?}"
}
# Verwaiste Arbeitsordner früherer, abgebrochener Läufe
for d in "$S"/arbeit/*/; do [ -d "$d" ] && arbeit_weg "${d%/}" && log "verwaisten Arbeitsordner ${d%/} entfernt"; done
# Protokoll klein halten (letzte 2000 Zeilen)
if [ -f "$PROTOKOLL" ] && [ "$(wc -l < "$PROTOKOLL")" -gt 4000 ]; then tail -n 2000 "$PROTOKOLL" > "$PROTOKOLL.neu" && mv "$PROTOKOLL.neu" "$PROTOKOLL"; fi

for p in docker python3 ssh-keygen ssh-keyscan sftp flock; do
  command -v "$p" >/dev/null || { log "FEHLT $p (Paket openssh-client bzw. $p); nichts gesichert"; exit 1; }
done
for a in anbieter kunde; do
  k="$S/ssh/$a/id_ed25519"
  if [ ! -s "$k" ]; then
    ssh-keygen -q -t ed25519 -N '' -C "ally-sicherung-$a" -f "$k" >/dev/null || { log "SSH-Schlüssel ($a) konnte nicht erzeugt werden"; exit 1; }
    log "SSH-Schlüssel ($a) erzeugt"
  fi
  chmod 600 "$k" "$k.pub"
done

# ---------------------------------------------------------------- Meldung und Aufträge
lokal_dateien() { find "$S/lokal" -maxdepth 1 -type f -name 'ally-*.tar' | wc -l; }
MELD_JSON="$(SCHL_A="$(cat "$S/ssh/anbieter/id_ed25519.pub")" SCHL_K="$(cat "$S/ssh/kunde/id_ed25519.pub")" FREI="$(df -B1 --output=avail "$S" | tail -n 1 | tr -dc 0-9)" GESAMT="$(df -B1 --output=size "$S" | tail -n 1 | tr -dc 0-9)" \
  LOKAL="$(du -sb "$S/lokal" | cut -f1)" STAENDE="$(lokal_dateien)" FASSUNG="$FASSUNG" python3 -c '
import json, os
print(json.dumps({"schluessel_anbieter": os.environ["SCHL_A"].strip(), "schluessel_kunde": os.environ["SCHL_K"].strip(), "frei": os.environ["FREI"], "gesamt": os.environ["GESAMT"], "lokal_belegt": os.environ["LOKAL"],
                  "lokal_staende": os.environ["STAENDE"], "fassung": os.environ["FASSUNG"]}))')"
if ! AUFTRAEGE="$(printf '%s\n' "SELECT ally_sicherung_host_plan(:'meldung'::jsonb);" | sql -v meldung="$MELD_JSON" -f - 2>>"$PROTOKOLL")"; then
  log "Datenbank nicht erreichbar oder Migration 201 fehlt; nichts gesichert"
  exit 0
fi
[ -n "$AUFTRAEGE" ] || exit 0
# Abbruch (Signal oder Fehler im Programm): laufenden Auftrag als fehlgeschlagen melden, Arbeitsordner samt Kennwort-Datei entfernen
LAUF_OFFEN=""; ARBEIT=""
# shellcheck disable=SC2329  # Aufruf über trap
aufraeumen() {
  [ -n "$ARBEIT" ] && arbeit_weg "$ARBEIT"
  if [ -n "$LAUF_OFFEN" ]; then ende "$LAUF_OFFEN" fehler "" "" "" "Abgebrochen: Das Backup-Programm wurde während des Laufs beendet."; log "Lauf $LAUF_OFFEN: abgebrochen"; fi
}
trap aufraeumen EXIT
trap 'exit 1' INT TERM HUP

# ---------------------------------------------------------------- Hilfen je Auftrag
ende() {  # lauf ergebnis groesse belegt staende meldung (Meldung ohne Kennwort, siehe sauber)
  printf '%s\n' "SELECT ally_sicherung_host_ende(:lauf, :'erg', nullif(:'gr', '')::bigint, nullif(:'be', '')::bigint, nullif(:'st', '')::integer, :'me');" \
    | sql -v lauf="$1" -v erg="$2" -v gr="$3" -v be="$4" -v st="$5" -v me="$6" -f - >/dev/null 2>>"$PROTOKOLL" || log "Lauf $1: Ergebnis nicht gespeichert"
}
# Meldung säubern: letzte Zeilen, ohne Steuerzeichen, Kennwort (falls je enthalten) ersetzt
sauber() {
  KW="${KW_DATEI:-}" python3 -c '
import os, sys
t = sys.stdin.read()
k = os.environ.get("KW", "")
if k and os.path.isfile(k):
    w = open(k, encoding="utf-8", errors="replace").read().strip()
    if w: t = t.replace(w, "***")
z = [x.strip() for x in t.splitlines() if x.strip()]
print(" / ".join(z[-3:])[:600])'
}
restic_lauf() {  # restic im Container: Repository, SSH-Schlüssel, known_hosts, Kennwort-Datei und Cache je Ziel; weitere Mounts über MOUNTS
  local cmd="ssh -i /ssh/id_ed25519 -p $PORT -o UserKnownHostsFile=/ssh/known_hosts -o StrictHostKeyChecking=yes -o BatchMode=yes -o ServerAliveInterval=60 -o ConnectTimeout=30 -s -- $BENUTZER@$HOST sftp"
  nice -n 10 docker run --rm --cpu-shares 256 --hostname "$RESTIC_HOST" \
    -v "$SCHLUESSEL:/ssh/id_ed25519:ro" -v "$ARBEIT/known_hosts:/ssh/known_hosts:ro" -v "$KW_DATEI:/run/kennwort:ro" -v "$S/cache/$ART:/cache" \
    "${MOUNTS[@]}" -e RESTIC_PASSWORD_FILE=/run/kennwort -e RESTIC_CACHE_DIR=/cache -e RESTIC_REPOSITORY="sftp:$BENUTZER@$HOST:$ORDNER/$REPO" \
    "$RESTIC_IMAGE" -o sftp.command="$cmd" "$@" < /dev/null
}
ssh_fehler() {  # Fehlertext von ssh/sftp in eine verständliche Meldung
  case "$1" in
    *"REMOTE HOST IDENTIFICATION HAS CHANGED"*|*"Host key verification failed"*)
      echo "Der Hostschlüssel der NAS passt nicht zum gespeicherten Fingerabdruck. Wurde die NAS neu eingerichtet, unter Ziel „Hostschlüssel neu lernen“ wählen; sonst nicht sichern und die Verbindung prüfen lassen." ;;
    *"Permission denied"*) echo "Anmeldung an der NAS abgelehnt: Benutzer prüfen und den öffentlichen Schlüssel dieses Ziels beim Benutzer hinterlegen." ;;
    *"no space left"*|*"No space left"*) if platz_voll; then voll_text; else echo "Auf der NAS ist kein Platz mehr frei."; fi ;;
    *"Could not resolve"*|*"Name or service not known"*) echo "Die Adresse der NAS ist unbekannt (DNS)." ;;
    *"Connection refused"*|*"timed out"*|*"No route"*|*"Network is unreachable"*) echo "Die NAS ist nicht erreichbar (Adresse, Port, Router-Freigabe und SFTP auf der NAS prüfen)." ;;
    *) printf '%s' "$1" | sauber ;;
  esac
}
platz_frei() { df -B1 --output=avail "$S" 2>/dev/null | tail -n 1 | tr -dc 0-9; }
platz_voll() { local f; f="$(platz_frei)"; [ -n "$f" ] && [ "$f" -lt "$MIN_FREI" ]; }
voll_text() { echo "Der Datenträger des Servers ist voll (frei: $(( $(platz_frei) / 1024 / 1024 )) MB). Alte Kopien sind schon entfernt; Aufbewahrung auf dem Server verkürzen oder Platz schaffen."; }
voll_oder() { if platz_voll; then voll_text; else echo "$1"; fi; }  # Meldung eines Pflichtschritts; bei vollem Datenträger diese Meldung
ziel_gueltig() {  # Angaben aus der Datenbank vor der Verwendung prüfen (zusätzlich zur Prüfung beim Speichern)
  [[ "$HOST" =~ ^[a-z0-9]([a-z0-9.-]{0,251}[a-z0-9])?$ ]] && [[ "$PORT" =~ ^[0-9]{1,5}$ ]] && [[ "$BENUTZER" =~ ^[A-Za-z0-9_][A-Za-z0-9._-]{0,63}$ ]] \
    && [[ "$ORDNER" =~ ^/?[A-Za-z0-9._-]+(/[A-Za-z0-9._-]+)*$ ]] && [[ "$REPO" =~ ^(ally-[0-9]{8}-[0-9]{6})?$ ]] \
    || { MELDUNG="Die Angaben zum Ziel sind ungültig. Bitte das Ziel neu speichern."; return 1; }
}
# Aufbewahrung auf dem Server: Kopien, Dateien der früheren nächtlichen Sicherung und Reste abgebrochener Kopien älter als LOKAL_TAGE Tage
lokal_aufraeumen() {
  [[ "$LOKAL_TAGE" =~ ^[0-9]{1,2}$ ]] && [ "$LOKAL_TAGE" -ge 1 ] || return 0
  find "$S/lokal" -maxdepth 1 -type f \( -name 'ally-*.tar' -o -name 'ally-*.tar.sha256' \) -mmin +$((LOKAL_TAGE * 1440)) -delete 2>>"$PROTOKOLL" || log "lokale Kopien nicht alle gelöscht"
  find "$S/lokal" -maxdepth 1 -type f -name 'ally-*.tar.teil' -delete 2>>"$PROTOKOLL" || true
  find "$S" -maxdepth 1 -type f -name '*-*.dump' -mmin +$((LOKAL_TAGE * 1440)) -delete 2>>"$PROTOKOLL" || log "alte Dumps nicht alle gelöscht"
}
repo_stand() {  # setzt REPO_STAND = da | fehlt | kennwort | fehler (mit REPO_TEXT)
  local aus rc
  aus="$(restic_lauf cat config 2>&1 >/dev/null)"; rc=$?
  if [ $rc -eq 0 ]; then REPO_STAND=da
  elif [ $rc -eq 10 ] || printf '%s' "$aus" | grep -qi 'does not exist\|Is there a repository'; then REPO_STAND=fehlt
  elif [ $rc -eq 12 ] || printf '%s' "$aus" | grep -qi 'wrong password\|no key found'; then REPO_STAND=kennwort
  else REPO_STAND=fehler; REPO_TEXT="$(ssh_fehler "$aus")"; fi
}

# ---------------------------------------------------------------- Verbindung prüfen
pruefen() {
  [ "$EINGERICHTET" = 1 ] || { MELDUNG="Kein Ziel eingetragen."; return 1; }
  ziel_gueltig || return 1
  local kopf fp aus
  kopf="$HOST"; [ "$PORT" = 22 ] || kopf="[$HOST]:$PORT"
  if [ -z "$HOSTKEY" ]; then
    aus="$(ssh-keyscan -T 20 -p "$PORT" -t ed25519,ecdsa,rsa -- "$HOST" 2>/dev/null)"
    HOSTKEY="$(printf '%s\n' "$aus" | awk -v k="$kopf" '$1 == k && $2 == "ssh-ed25519" {print; exit}')"
    [ -n "$HOSTKEY" ] || HOSTKEY="$(printf '%s\n' "$aus" | awk -v k="$kopf" '$1 == k && $2 ~ /^ecdsa-sha2-/ {print; exit}')"
    [ -n "$HOSTKEY" ] || HOSTKEY="$(printf '%s\n' "$aus" | awk -v k="$kopf" '$1 == k && $2 == "ssh-rsa" {print; exit}')"
    [ -n "$HOSTKEY" ] || { MELDUNG="Die NAS ist nicht erreichbar (Adresse, Port, Router-Freigabe und SFTP auf der NAS prüfen)."; return 1; }
    printf '%s\n' "$HOSTKEY" > "$ARBEIT/known_hosts"
    fp="$(ssh-keygen -l -E sha256 -f "$ARBEIT/known_hosts" | awk '{print $2; exit}')"
    local r; r="$(printf '%s\n' "SELECT ally_sicherung_host_hostschluessel(:lauf, :'zeile', :'fp');" | sql -v lauf="$LAUF" -v zeile="$HOSTKEY" -v fp="$fp" -f - 2>>"$PROTOKOLL")"
    [ "$r" = ok ] || { MELDUNG="Hostschlüssel der NAS nicht gespeichert ($r)."; return 1; }
    HINWEIS="Hostschlüssel der NAS übernommen: $fp. "
  fi
  printf '%s\n' "$HOSTKEY" > "$ARBEIT/known_hosts"
  aus="$(printf 'pwd\n' | sftp -b - -i "$SCHLUESSEL" -P "$PORT" -o UserKnownHostsFile="$ARBEIT/known_hosts" -o StrictHostKeyChecking=yes -o BatchMode=yes \
         -o ConnectTimeout=20 -- "$BENUTZER@$HOST" 2>&1 >/dev/null)" || { MELDUNG="$(ssh_fehler "$aus")"; return 1; }
  if [ "$KW_GESETZT" = 1 ]; then
    kennwort_holen || return 1
    repo_stand
    case "$REPO_STAND" in
      da) HINWEIS+="Anmeldung in Ordnung, Repository vorhanden." ;;
      fehlt) HINWEIS+="Anmeldung in Ordnung. Das Repository legt das erste Backup an." ;;
      kennwort) MELDUNG="Anmeldung in Ordnung, aber das Wiederherstellungs-Kennwort passt nicht zum Repository im Ordner $ORDNER/$REPO."; return 1 ;;
      *) MELDUNG="$REPO_TEXT"; return 1 ;;
    esac
  else
    HINWEIS+="Anmeldung in Ordnung. Das Wiederherstellungs-Kennwort fehlt noch."
  fi
  MELDUNG="$HINWEIS"
}

kennwort_holen() {
  KW_DATEI="$ARBEIT/kennwort"
  ( umask 077; printf '%s\n' "SELECT ally_sicherung_host_kennwort(:lauf);" | sql -v lauf="$LAUF" -f - > "$KW_DATEI" 2>>"$PROTOKOLL" ) \
    || { MELDUNG="Wiederherstellungs-Kennwort nicht lesbar (Verschlüsselung der Installation prüfen)."; return 1; }
  chmod 600 "$KW_DATEI"
  [ -s "$KW_DATEI" ] && [ "$(wc -c < "$KW_DATEI")" -gt 1 ] || { MELDUNG="Das Wiederherstellungs-Kennwort fehlt."; return 1; }
}

# ---------------------------------------------------------------- Sichern
# Anbieter-Ziel: vollständige Installation (Datenbanken, Konfiguration, Chat-Server, Zertifikate)
anbieter_stand() {
  local stand="$1" db f
  mkdir -p "$stand/datenbanken" "$stand/konfiguration" || { MELDUNG="$(voll_oder "Arbeitsordner konnte nicht angelegt werden.")"; return 1; }
  for db in ally n8n synapse; do
    dc exec -T postgres pg_dump -U postgres -Fc "$db" < /dev/null > "$stand/datenbanken/$db.dump" 2>>"$PROTOKOLL" \
      || { MELDUNG="$(voll_oder "Datenbank $db konnte nicht gesichert werden (pg_dump).")"; return 1; }
  done
  cp -p "$ZIEL/.env" "$ZIEL/docker-compose.yml" "$stand/konfiguration/" || { MELDUNG="$(voll_oder "Konfiguration (.env, docker-compose.yml) nicht lesbar.")"; return 1; }
  if [ -f "$ZIEL/n8n/config" ]; then cp -p "$ZIEL/n8n/config" "$stand/konfiguration/n8n-config" || { MELDUNG="$(voll_oder "n8n-Konfiguration nicht lesbar.")"; return 1; }; fi
  # Chat-Server (homeserver.yaml, Signierschlüssel, Log-Konfiguration; ohne media_store), Chat-Bot, Element, letsencrypt – nur was es gibt
  for f in "$ZIEL"/synapse/*.yaml "$ZIEL"/synapse/*.signing.key "$ZIEL"/synapse/*.log.config; do
    [ -f "$f" ] || continue
    { mkdir -p "$stand/konfiguration/synapse" && cp -p "$f" "$stand/konfiguration/synapse/"; } || { MELDUNG="$(voll_oder "Konfiguration des Chat-Servers nicht lesbar.")"; return 1; }
  done
  if [ -f "$ZIEL/matrix-bot.env" ]; then cp -p "$ZIEL/matrix-bot.env" "$stand/konfiguration/" || { MELDUNG="$(voll_oder "matrix-bot.env nicht lesbar.")"; return 1; }; fi
  if [ -f "$ZIEL/element/config.json" ]; then cp -p "$ZIEL/element/config.json" "$stand/konfiguration/element-config.json" || { MELDUNG="$(voll_oder "Element-Konfiguration nicht lesbar.")"; return 1; }; fi
  if [ -d "$ZIEL/letsencrypt" ]; then cp -a "$ZIEL/letsencrypt" "$stand/konfiguration/letsencrypt" || { MELDUNG="$(voll_oder "letsencrypt nicht lesbar.")"; return 1; }; fi
}

# Kunden-Ziel (Entscheidung Stefan 03.11.2026 15:04, „b“): nur Inhalte = Tabellen mit Kundendaten der Datenbank ally als CSV (ally_sicherung_kunde_inhalt:
# Einteilung B7a, ohne Geheimnis-, Token- und verschlüsselte Spalten, ohne Zeilen von Superadmins). Keine Datenbanken n8n/synapse, keine .env, kein Schlüssel der
# Installation, keine Konfiguration. CSV mit Kopfzeile: lesbar ohne PostgreSQL (Tabellenkalkulation) und mit COPY … FROM in eine neue Installation übernehmbar;
# ein pg_dump könnte einzelne Spalten nicht auslassen.
kunde_stand() {
  local stand="$1" liste tab abfrage aus
  mkdir -p "$stand/inhalte" || { MELDUNG="$(voll_oder "Arbeitsordner konnte nicht angelegt werden.")"; return 1; }
  # Trenner Tabulator (Abfragen können | enthalten)
  liste="$(printf '%s\n' "SELECT tabelle || chr(9) || abfrage || chr(9) || ausgelassen FROM ally_sicherung_kunde_inhalt(:lauf);" | sql -v lauf="$LAUF" -f - 2>>"$PROTOKOLL")" \
    || { MELDUNG="Liste der Inhalte nicht lesbar."; return 1; }
  [ -n "$liste" ] || { MELDUNG="Liste der Inhalte ist leer."; return 1; }
  printf '%s\n' "Tabelle|ausgelassene Spalten" > "$stand/inhalte/TABELLEN.txt"
  while IFS=$'\t' read -r tab abfrage aus; do
    [[ "$tab" =~ ^[a-z_][a-z0-9_]{0,62}$ ]] && [[ "$abfrage" == "SELECT "* ]] || { MELDUNG="Liste der Inhalte ungültig."; return 1; }
    printf 'COPY (%s) TO STDOUT WITH (FORMAT csv, HEADER true)\n' "$abfrage" | sql -f - > "$stand/inhalte/$tab.csv" 2>>"$PROTOKOLL" \
      || { MELDUNG="$(voll_oder "Tabelle $tab konnte nicht gesichert werden.")"; return 1; }
    printf '%s|%s\n' "$tab" "$aus" >> "$stand/inhalte/TABELLEN.txt" || { MELDUNG="$(voll_oder "Liste der Tabellen nicht geschrieben.")"; return 1; }
  done <<< "$liste"
  printf '%s\n' 'Kopie der Inhalte (Kundendaten) dieser Ally-Installation, keine Wiederherstellung der Installation.' \
    'inhalte/<Tabelle>.csv: je Tabelle eine CSV-Datei (UTF-8, Komma, Kopfzeile). TABELLEN.txt nennt die bewusst ausgelassenen Spalten' \
    '(Passwort-Prüfsummen, Tokens, verschlüsselte Zugangsdaten). Zeilen von Superadmins sind nicht enthalten.' \
    'dateien/: Ordner der Dateien von Ally. Übernahme in eine Datenbank: COPY <tabelle> (<spalten>) FROM … WITH (FORMAT csv, HEADER true).' > "$stand/LIESMICH.txt" \
    || { MELDUNG="$(voll_oder "LIESMICH.txt nicht geschrieben.")"; return 1; }
}
sichern() {
  local stand="$ARBEIT/stand" zeit db t
  zeit="$(date +%Y-%m-%d_%H%M%S)"
  # zuerst aufräumen, dann den Platz prüfen
  lokal_aufraeumen
  platz_voll && { MELDUNG="$(voll_text)"; return 1; }
  if [ "$EINGERICHTET" = 1 ]; then ziel_gueltig || return 1; fi
  if [ "$ART" = anbieter ]; then anbieter_stand "$stand" || return 1; else kunde_stand "$stand" || return 1; fi
  if ! { (cd "$stand" && find . -type f -print0 | sort -z | xargs -0 -r sha256sum > "$ARBEIT/pruefsummen") && [ -s "$ARBEIT/pruefsummen" ] \
         && mv "$ARBEIT/pruefsummen" "$stand/PRUEFSUMMEN.sha256"; }; then
    MELDUNG="$(voll_oder "Prüfsummen des Backups konnten nicht gebildet werden.")"; return 1
  fi
  GROESSE="$(du -sb "$stand" | cut -f1)" && [[ "$GROESSE" =~ ^[0-9]+$ ]] || { MELDUNG="Größe des Backups nicht ermittelt."; return 1; }
  if [ "$ART" = anbieter ]; then
    t="$S/lokal/ally-$zeit.tar"
    if ! { tar -C "$ARBEIT" -cf "$t.teil" stand && mv "$t.teil" "$t" && (cd "$S/lokal" && sha256sum "$(basename "$t")" > "$(basename "$t").sha256"); }; then
      rm -f "$t.teil" "$t" "$t.sha256"; MELDUNG="$(voll_oder "Lokale Kopie konnte nicht geschrieben werden.")"; return 1
    fi
  fi
  if [ "$EINGERICHTET" != 1 ]; then
    [ "$ART" = anbieter ] && { ERG=nur_lokal; MELDUNG="Kein Ziel eingetragen: nur auf dem Server gesichert."; return 0; }
    MELDUNG="Kein Ziel eingetragen."; return 1
  fi
  if [ "$KW_GESETZT" != 1 ]; then
    MELDUNG="Das Wiederherstellungs-Kennwort fehlt."; [ "$ART" = anbieter ] && MELDUNG="Das Wiederherstellungs-Kennwort fehlt; nur auf dem Server gesichert."
    return 1
  fi
  [ -n "$HOSTKEY" ] || { MELDUNG="Der Hostschlüssel der NAS ist noch unbekannt: bitte „Verbindung prüfen“."; return 1; }
  printf '%s\n' "$HOSTKEY" > "$ARBEIT/known_hosts"
  kennwort_holen || return 1
  repo_stand
  case "$REPO_STAND" in
    da) ;;
    fehlt) local aus; aus="$(restic_lauf init 2>&1 >/dev/null)" || { MELDUNG="Repository nicht angelegt: $(ssh_fehler "$aus")"; return 1; } ;;
    kennwort) MELDUNG="Das Wiederherstellungs-Kennwort passt nicht zum Repository im Ordner $ORDNER/$REPO."; return 1 ;;
    *) MELDUNG="$REPO_TEXT"; return 1 ;;
  esac
  local mounts_alt=("${MOUNTS[@]}") aus json rc warnung=""
  MOUNTS=(-v "$stand:/sicherung/stand:ro")
  [ -d "$ZIEL/dateien" ] && MOUNTS+=(-v "$ZIEL/dateien:/sicherung/dateien:ro")
  json="$(restic_lauf backup --json --host "$RESTIC_HOST" --tag "$ANLASS" /sicherung 2>"$ARBEIT/restic.err")"; rc=$?
  MOUNTS=("${mounts_alt[@]}")
  # restic 3 = Stand angelegt, aber einzelne Dateien waren nicht lesbar: mit Warnung weiter (aufräumen und zählen)
  if [ $rc -eq 3 ]; then warnung="Gesichert, aber einzelne Dateien waren nicht lesbar: $(sauber < "$ARBEIT/restic.err")"
  elif [ $rc -ne 0 ]; then MELDUNG="Übertragung fehlgeschlagen: $(ssh_fehler "$(cat "$ARBEIT/restic.err")")"; return 1; fi
  GROESSE="$(printf '%s\n' "$json" | python3 -c '
import json, sys
for z in sys.stdin:
    try: d = json.loads(z)
    except ValueError: continue
    if d.get("message_type") == "summary": print(d.get("total_bytes_processed", "")); break')"
  local behalten=(--keep-last 1)
  [ "$B_T" -gt 0 ] && behalten+=(--keep-daily "$B_T")
  [ "$B_W" -gt 0 ] && behalten+=(--keep-weekly "$B_W")
  [ "$B_M" -gt 0 ] && behalten+=(--keep-monthly "$B_M")
  aus="$(restic_lauf forget --host "$RESTIC_HOST" --group-by host "${behalten[@]}" --prune 2>&1 >/dev/null)" \
    || { MELDUNG="Gesichert, aber alte Stände nicht aufgeräumt: $(ssh_fehler "$aus")"; return 1; }
  BELEGT="$(restic_lauf stats --mode raw-data --json 2>>"$PROTOKOLL" | python3 -c 'import json, sys; print(json.load(sys.stdin).get("total_size", ""))' 2>/dev/null || true)"
  STAENDE="$(restic_lauf snapshots --json --host "$RESTIC_HOST" 2>>"$PROTOKOLL" | python3 -c 'import json, sys; print(len(json.load(sys.stdin) or []))' 2>/dev/null || true)"
  if [ -n "$warnung" ]; then ERG=warnung; MELDUNG="$warnung"; else ERG=ok; MELDUNG=""; fi
}

# ---------------------------------------------------------------- Aufträge ausführen
# Aufträge über Kanal 3 lesen (docker und psql in der Schleife dürfen die Liste nicht von stdin lesen)
while IFS='|' read -r -u 3 LAUF ART ANLASS; do
  [[ "$LAUF" =~ ^[0-9]+$ ]] || continue
  ARBEIT="$S/arbeit/$LAUF"; LAUF_OFFEN="$LAUF"; mkdir -p "$ARBEIT"; chmod 700 "$ARBEIT"
  SCHLUESSEL="$S/ssh/$ART/id_ed25519"
  ERG=fehler; MELDUNG="Unerwarteter Abbruch."; HINWEIS=""; GROESSE=""; BELEGT=""; STAENDE=""; KW_DATEI=""; MOUNTS=(); REPO_TEXT=""
  ZEILE="$(printf '%s\n' "SELECT ally_sicherung_host_ziel(:lauf);" | sql -v lauf="$LAUF" -f - 2>>"$PROTOKOLL")"
  IFS='|' read -r _ _ EINGERICHTET HOST PORT BENUTZER ORDNER REPO KW_GESETZT HOSTKEY B_T B_W B_M LOKAL_TAGE <<< "$ZEILE"
  log "Lauf $LAUF: $ART $ANLASS beginnt"
  if [ -z "$ZEILE" ]; then MELDUNG="Auftrag nicht gefunden."
  elif [[ ! "$ART" =~ ^(anbieter|kunde)$ ]]; then MELDUNG="Unbekanntes Ziel."
  elif [ "$ANLASS" = pruefen ]; then pruefen && ERG=ok
  else sichern || ERG=fehler; fi
  if [ -n "$KW_DATEI" ] && [ -f "$KW_DATEI" ]; then MELDUNG="$(printf '%s' "$MELDUNG" | sauber)"; fi
  case "$ERG" in ok|warnung|fehler|nur_lokal) ;; *) ERG=fehler ;; esac
  if [ -n "$KW_DATEI" ] && [ -f "$KW_DATEI" ]; then shred -u "$KW_DATEI" 2>/dev/null || rm -f "$KW_DATEI"; fi
  ende "$LAUF" "$ERG" "$GROESSE" "$BELEGT" "$STAENDE" "$MELDUNG"; LAUF_OFFEN=""
  log "Lauf $LAUF: $ERG"
  arbeit_weg "$ARBEIT"; ARBEIT=""
done 3<<< "$AUFTRAEGE"
exit 0
