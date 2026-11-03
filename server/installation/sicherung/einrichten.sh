#!/usr/bin/env bash
# Ally – Sicherungsprogramm einrichten (Migration 201, Konzept „Sicherung auf die NAS“, Stefan 03.11.2026). Einmal je Installation als root:
#   bash <paket>/server/installation/sicherung/einrichten.sh
# Für bestehende Installationen aus dem Paket (Nachziehen) und aus installieren.sh. Wiederholbar: kopiert das Programm (neueste Fassung) nach /opt/ally/ally-sicherung.sh,
# ersetzt den bisherigen Cron-Eintrag (/etc/cron.d/ally-sicherung, früher 02:17 /opt/ally/sicherung.sh) durch den Aufruf alle 5 Minuten, entfernt das alte
# Skript /opt/ally/sicherung.sh (nur das vom Installationsskript angelegte), lädt das restic-Image mit fester Version und startet das Programm einmal
# (erzeugt je Ziel ein SSH-Schlüsselpaar unter /opt/ally/sicherung/ssh/<ziel> und meldet den Server an Ally). Bisherige lokale Sicherungen unter /opt/ally/sicherung bleiben;
# das Programm löscht sie nach der eingestellten Aufbewahrung. Danach alles Weitere in Ally: Einstellungen › System › Sicherung.
# Voraussetzung: Migration 201 ist in der Datenbank eingespielt (sonst Abbruch ohne Änderung).
set -Eeuo pipefail
umask 077

ZIEL="${ALLY_ZIEL:-/opt/ally}"
QUELLE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/ally-sicherung.sh"
PROGRAMM="$ZIEL/ally-sicherung.sh"
CRON="${ALLY_CRON:-/etc/cron.d/ally-sicherung}"

abbruch() { printf 'ABBRUCH: %s\nNichts geändert.\n' "$*" >&2; exit 1; }
[ "$(id -u)" = 0 ] || abbruch "Bitte als root ausführen."
[ -f "$ZIEL/docker-compose.yml" ] && [ -f "$ZIEL/.env" ] || abbruch "Keine Ally-Installation unter $ZIEL gefunden."
[ -f "$QUELLE" ] || abbruch "Programm $QUELLE fehlt im Paket."
for p in docker python3 flock ssh-keygen ssh-keyscan sftp; do
  command -v "$p" >/dev/null || abbruch "$p fehlt auf dem Server (ssh-keygen, ssh-keyscan, sftp gehören zum Ubuntu-Paket openssh-client)."
done
DA="$(cd "$ZIEL" && docker compose exec -T postgres psql -X -q -At -U ally -d ally -c "SELECT to_regprocedure('ally_sicherung_host_plan(jsonb)') IS NOT NULL" < /dev/null 2>/dev/null || true)"
[ "$DA" = t ] || abbruch "Migration 201 (Backups) ist in der Datenbank nicht eingespielt oder die Datenbank läuft nicht. Erst die Fassung mit Migration 201 einspielen."
IMAGE="$(grep -o 'restic/restic:[0-9][0-9.]*' "$QUELLE" | head -n 1)"
[ -n "$IMAGE" ] || abbruch "restic-Version im Programm nicht gefunden."
docker pull -q "$IMAGE" >/dev/null || abbruch "restic-Image $IMAGE konnte nicht geladen werden (Netz?)."

install -m 700 -o root -g root "$QUELLE" "$PROGRAMM"
mkdir -p "$ZIEL/sicherung"; chmod 700 "$ZIEL/sicherung"
# Altes nächtliches Skript (installieren.sh bis Migration 201) nur entfernen, wenn es das vom Installationsskript angelegte ist
if [ -f "$ZIEL/sicherung.sh" ] && grep -q 'Übertragung zur NAS: offen' "$ZIEL/sicherung.sh"; then rm -f "$ZIEL/sicherung.sh"; fi
printf '%s\n' '# Ally – Sicherungsprogramm (Migration 201): prüft alle 5 Minuten Zeitplan und Aufträge aus Einstellungen › System › Backups' \
  'PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin' \
  "*/5 * * * * root $PROGRAMM >/dev/null 2>&1" > "$CRON.neu"
chmod 644 "$CRON.neu"; mv "$CRON.neu" "$CRON"
"$PROGRAMM" || true
printf '\nBackup-Programm eingerichtet (%s, alle 5 Minuten, %s).\n' "$PROGRAMM" "$IMAGE"
# Je Ziel ein eigenes Schlüsselpaar; hier nur der Schlüssel des Anbieter-Ziels (der des Kunden-Ziels steht für den Admin in Ally)
if [ -s "$ZIEL/sicherung/ssh/anbieter/id_ed25519.pub" ]; then
  printf 'Öffentlicher Schlüssel für das Anbieter-Ziel (auch in Ally unter Einstellungen › System › Backups):\n%s\n' "$(cat "$ZIEL/sicherung/ssh/anbieter/id_ed25519.pub")"
fi
printf 'Weiter in Ally: Einstellungen › System › Backups (Ziel, Wiederherstellungs-Kennwort, Verbindung prüfen).\n'
