#!/usr/bin/env bash
# Ally – Update-Programm einrichten (Migration 203, Update-Knopf). Einmal je Installation als root:
#   bash <paket>/server/installation/update/einrichten.sh
# Für bestehende Installationen (Nachziehen) und aus installieren.sh; das Update-Programm ruft es nach einem Update selbst auf, wenn sich das Programm geändert hat
# (dann mit ALLY_UPDATE_OHNE_LAUF=1). Wiederholbar: kopiert das Programm und seine Hilfsdatei nach /opt/ally (ally-update.sh, ally-update-hilfe.py), legt den Cron-Eintrag
# /etc/cron.d/ally-update (alle 5 Minuten) an und startet das Programm einmal (meldet sich in Ally und sucht beim ersten Lauf nach einer neuen Fassung).
# Danach alles Weitere in Ally: Einstellungen › System › Updates. Voraussetzung: Migration 203 ist in der Datenbank eingespielt (sonst Abbruch ohne Änderung).
set -Eeuo pipefail
umask 077

ZIEL="${ALLY_ZIEL:-/opt/ally}"
QUELLE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRON="${ALLY_UPDATE_CRON:-/etc/cron.d/ally-update}"

abbruch() { printf 'ABBRUCH: %s\nNichts geändert.\n' "$*" >&2; exit 1; }
[ "$(id -u)" = 0 ] || abbruch "Bitte als root ausführen."
[ -f "$ZIEL/docker-compose.yml" ] && [ -f "$ZIEL/.env" ] || abbruch "Keine Ally-Installation unter $ZIEL gefunden."
[ -f "$QUELLE/ally-update.sh" ] && [ -f "$QUELLE/ally-update-hilfe.py" ] || abbruch "Update-Programm fehlt im Paket ($QUELLE)."
for p in docker python3 flock curl tar; do command -v "$p" >/dev/null || abbruch "$p fehlt auf dem Server."; done
DA="$(cd "$ZIEL" && docker compose exec -T postgres psql -X -q -At -U ally -d ally -c "SELECT to_regprocedure('ally_update_host_plan(jsonb)') IS NOT NULL" < /dev/null 2>/dev/null || true)"
[ "$DA" = t ] || abbruch "Migration 203 (Updates) ist in der Datenbank nicht eingespielt oder die Datenbank läuft nicht. Erst die Fassung mit Migration 203 einspielen."

# Bestehende Installationen ohne Freigabe-Commit (vor Migration 203 installiert, z. B. shine): Commit nachtragen, wenn das Paket dieser Installation
# (/opt/ally-paket) den Beipackzettel der eingespielten Fassung enthält und freigegeben.json dafür einen Commit nennt. Sonst bleibt es leer (docs/updates.md).
PAKET_ORT="${ALLY_PAKET:-/opt/ally-paket}"
psql_e() { (cd "$ZIEL" && docker compose exec -T postgres psql -X -q -At -v ON_ERROR_STOP=1 -U ally -d ally "$@"); }
NR="$(printf '%s\n' "SELECT f.nummer FROM ally_fassung f WHERE f.nummer = ally_fassung_aktuell() AND f.git_commit IS NULL;" | psql_e -f - 2>/dev/null || true)"
if [[ "$NR" =~ ^[0-9]{1,3}\.[0-9]{1,3}$ ]] && [ -f "$PAKET_ORT/fassungen/$NR.json" ] && [ -f "$PAKET_ORT/fassungen/freigegeben.json" ]; then
  C="$(python3 -I -c 'import json,sys; f=json.load(open(sys.argv[1])).get("fassungen", []); c=[x.get("commit", "") for x in f if x.get("fassung") == sys.argv[2]]; print(c[-1] if c else "")' \
    "$PAKET_ORT/fassungen/freigegeben.json" "$NR" 2>/dev/null || true)"
  if [[ "$C" =~ ^[0-9a-f]{7,40}$ ]]; then
    printf '%s\n' "UPDATE ally_fassung SET git_commit = :'c' WHERE nummer = :'n' AND git_commit IS NULL;" | psql_e -v c="$C" -v n="$NR" -f - >/dev/null \
      && printf 'Freigabe-Commit der Fassung %s nachgetragen (%s).\n' "$NR" "${C:0:7}"
  fi
fi

# fassung.json ohne eingespielt_commit (vor Migration 203 installiert): Commit der Datenbank eintragen, wenn die Nummer zur eingespielten Fassung passt. Sonst glaubt
# das Update-Programm der Datei nicht und probt alle Migrationen (docs/updates.md).
if [ -f "$ZIEL/fassung.json" ]; then
  FC="$(printf '%s\n' "SELECT f.nummer || '|' || f.git_commit FROM ally_fassung f WHERE f.nummer = ally_fassung_aktuell() AND f.git_commit IS NOT NULL;" | psql_e -f - 2>/dev/null || true)"
  if [[ "$FC" =~ ^[0-9]{1,3}\.[0-9]{1,3}\|[0-9a-f]{7,40}$ ]]; then
    python3 -I -c 'import json,os,sys
p, n, c = sys.argv[1], sys.argv[2], sys.argv[3]
z = json.load(open(p))
if z.get("fassung") == n and not z.get("eingespielt_commit"):
    z["eingespielt_commit"] = c
    json.dump(z, open(p + ".neu", "w"), ensure_ascii=False); os.chmod(p + ".neu", 0o644); os.replace(p + ".neu", p)
    print("fassung.json: Freigabe-Commit nachgetragen.")' "$ZIEL/fassung.json" "${FC%%|*}" "${FC#*|}" || true
  fi
fi

install -m 700 -o root -g root "$QUELLE/ally-update.sh" "$ZIEL/ally-update.sh"
install -m 600 -o root -g root "$QUELLE/ally-update-hilfe.py" "$ZIEL/ally-update-hilfe.py"
mkdir -p "$ZIEL/update"; chmod 700 "$ZIEL/update"
printf '%s\n' '# Ally – Update-Programm (Migration 203): prüft alle 5 Minuten die Aufträge aus Einstellungen › System › Updates und sucht einmal am Tag nach einer neuen Fassung' \
  'PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin' \
  "*/5 * * * * root $ZIEL/ally-update.sh >/dev/null 2>&1" > "$CRON.neu"
chmod 644 "$CRON.neu"; mv "$CRON.neu" "$CRON"
[ "${ALLY_UPDATE_OHNE_LAUF:-}" = 1 ] || "$ZIEL/ally-update.sh" || true
printf '\nUpdate-Programm eingerichtet (%s, alle 5 Minuten).\nWeiter in Ally: Einstellungen › System › Updates.\n' "$ZIEL/ally-update.sh"
