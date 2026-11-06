#!/usr/bin/env bash
# Ally – Update-Programm auf dem Server (Migration 203, Konzept Installation und Updates Teil 2 C.5–C.7; Entscheidungen Stefan 31.10.2026: Kunde aktualisiert per Knopf,
# nur von Stefan freigegebene Fassungen aus dem Auslieferungs-Repo, Knopf nur Admin und Superadmin, Frist 30 Tage).
# Läuft als root jede Minute über /etc/cron.d/ally-update (eingerichtet von installieren.sh bzw. einmalig von einrichten.sh; Migration 211: jede Minute statt alle
# 5 Minuten – ein Update mit neuer Fassung dieses Programms richtet es danach selbst neu ein, einrichten.sh schreibt den Cron-Eintrag). Nie zwei Läufe zugleich (flock).
# Ablauf: meldet sich bei der Datenbank (ally_update_host_plan) und übernimmt höchstens einen Auftrag:
#  - suchen (einmal am Tag; der Knopf „Update suchen“ sucht seit Migration 211 sofort über n8n, ALLY 20): neueste Fassung aus fassungen/freigegeben.json des Auslieferungs-Repos (Einstellung update_quelle, Zweig main)
#    lesen und an die Datenbank melden (ally_update_host_verfuegbar; dort Vergleich mit ally_fassung und Benachrichtigung „Update verfügbar“).
#  - aktualisieren (Knopf „Jetzt aktualisieren“): Paket des gemeldeten Stands laden (Tarball des Auslieferungs-Repos zum Commit), mit hilfe.py prüfen, sichern
#    (pg_dump ally, alle Workflows, Schaltzustand, Web-App-Dateien), fehlende Migrationen der Reihe nach einspielen („schon eingespielt“ zählt als ok), Workflows aus
#    dem Zettel importieren (nur neue und geänderte, Schaltzustand dieser Installation bleibt), n8n neu starten, Web-App aus dem Paket wie ALLY 42 mit ref = Commit,
#    Fassung setzen (ally_update_host_ende). Bei einem Fehler Rückweg: Workflows aus der Sicherung, Rückbau der in diesem Lauf eingespielten Migrationen in
#    umgekehrter Reihenfolge, Web-App alt, n8n neu starten; Meldung an Admins und Superadmins.
# GitHub-Lesezugang: Zugangsdaten „GitHub“ in n8n (n8n export:credentials --id … --decrypted, Datei im Container sofort gelöscht); der Token steht nie in einer Datei
# auf dem Server, nie in Protokollen und geht nur über stdin an curl.
# Protokoll: /opt/ally/update/protokoll.log (ohne Geheimnisse). Sicherungen: /opt/ally/update/sicherung/<lauf> mit dem Paket des Laufs (die letzten 3 Läufe bleiben).
# Harter Abbruch (SIGKILL, Neustart, OOM): Die Datenbank sperrt weitere Updates (ally_update_host_plan); der nächste Lauf setzt den abgebrochenen Lauf zuerst zurück
# (Migrationen laut Merker migrationen.txt und ally_updates.schritte rückwärts, Workflows und Web-App aus der Sicherung dieses Laufs; Merker wf_ids, webapp, neustart
# im Ordner der Sicherung; fassung.json aus der Sicherung).
# /opt/ally/fassung.json (Beipackzettel der eingespielten Fassung mit eingespielt_commit) wird erst nach dem gespeicherten Ende geschrieben und nur geglaubt, wenn
# Nummer und Commit zu ally_fassung passen; sonst werden alle Migrationen des Pakets geprobt und alle Workflows des Zettels importiert.
# Lässt sich das Ende eines erfolgreichen Updates nicht in der Datenbank speichern, merkt das Programm es in update/ende-offen (und den Zettel in
# update/ende-offen.zettel) und holt es beim nächsten Lauf nach; erst dann wird fassung.json geschrieben.
# shellcheck disable=SC1111  # deutsche Anführungszeichen in Meldungstexten sind gewollt
set -Euo pipefail
umask 077

PROGRAMM_FASSUNG=2
ZIEL="${ALLY_ZIEL:-/opt/ally}"
PAKET_ORT="${ALLY_PAKET:-/opt/ally-paket}"
U="$ZIEL/update"
HILFE_U="${ALLY_UPDATE_HILFE:-$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)/ally-update-hilfe.py}"
PROTOKOLL="$U/protokoll.log"
MIN_FREI="${ALLY_MIN_FREI:-$((500 * 1024 * 1024))}"
ZUSCHLAG="${ALLY_PLATZ_ZUSCHLAG:-$((200 * 1024 * 1024))}"
ZWEIG=main
GITHUB=https://api.github.com
export LC_ALL=C

log() { printf '%s %s\n' "$(date -u +%FT%TZ)" "$*" >> "$PROTOKOLL"; }
dc() { (cd "$ZIEL" && docker compose "$@"); }
# SQL über den Postgres-Container; Werte nur als psql-Variablen (-v name=wert, im SQL :'name')
sql() { dc exec -T postgres psql -X -q -At -v ON_ERROR_STOP=1 -U ally -d ally "$@"; }
sql_n8n() { dc exec -T postgres psql -X -q -At -v ON_ERROR_STOP=1 -U postgres -d n8n "$@"; }
hilfe() { python3 -I "$HILFE_U" "$@"; }
# Meldung säubern: letzte Zeilen, ohne Steuerzeichen, ohne DETAIL/CONTEXT-Zeilen von psql
sauber() { python3 -c '
import sys
import re
z = [re.sub(r"\s+", " ", re.sub(r"^psql:[^:]*:[0-9]+: ", "", x.strip())) for x in sys.stdin.read().splitlines()]
z = [x for x in z if x and not x.startswith(("DETAIL", "CONTEXT", "HINT", "LINE", "^"))]
print(" / ".join(z[-3:])[:600])'; }

mkdir -p "$U" && chmod 700 "$U"
exec 9>"$U/.sperre"
flock -n 9 || exit 0
mkdir -p "$U/arbeit" "$U/sicherung" && chmod 700 "$U/arbeit" "$U/sicherung"
if [ -f "$PROTOKOLL" ] && [ "$(wc -l < "$PROTOKOLL")" -gt 4000 ]; then tail -n 2000 "$PROTOKOLL" > "$PROTOKOLL.neu" && mv "$PROTOKOLL.neu" "$PROTOKOLL"; fi
for d in "$U"/arbeit/*/; do [ -d "$d" ] && rm -rf -- "${d%/}" && log "verwaisten Arbeitsordner ${d%/} entfernt"; done
for p in docker python3 curl tar flock; do
  command -v "$p" >/dev/null || { log "FEHLT $p; nichts getan"; exit 1; }
done
[ -f "$HILFE_U" ] || { log "FEHLT $HILFE_U; nichts getan"; exit 1; }

# Ende eines erfolgreichen Updates nachholen (ende-offen: Lauf, Ergebnis), bevor der Plan liegengebliebene Läufe als abgebrochen wertet
ende_db() {  # ende_db <lauf> <status> <ergebnis> <unvollstaendig t|f> <detail>: Ausgabe der Datenbank (ok, kein laufender Lauf, …)
  printf '%s\n' "SELECT ally_update_host_ende(:lauf, :'s', :'e', :'u'::boolean, nullif(:'d', ''));" \
    | sql -v lauf="$1" -v s="$2" -v e="$3" -v u="$4" -v d="${5:-}" -f - 2>>"$PROTOKOLL"
}
if [ -f "$U/ende-offen" ]; then
  L_O=""; T_O=""; C_O=""
  { read -r L_O; read -r T_O; read -r C_O; } < "$U/ende-offen" || true
  if [[ ! "$L_O" =~ ^[0-9]{1,18}$ ]]; then
    mv -f "$U/ende-offen" "$U/ende-offen.ungueltig"; rm -f "$U/ende-offen.zettel"; log "Merker update/ende-offen ungültig; nach ende-offen.ungueltig verschoben"
  else
    r_o="$(ende_db "$L_O" ok "$T_O" f "" || true)"
    case "$r_o" in
      ok|"kein laufender Lauf")
        if [ "$r_o" = ok ] && [ -f "$U/ende-offen.zettel" ] && [[ "$C_O" =~ ^[0-9a-f]{7,40}$ ]]; then
          hilfe fassung_schreiben "$U/ende-offen.zettel" "$C_O" "$ZIEL/fassung.json" 2>>"$PROTOKOLL" || log "Lauf $L_O: fassung.json nicht ersetzt"
        fi
        rm -f "$U/ende-offen" "$U/ende-offen.zettel"; log "Lauf $L_O: Ende nachgeholt ($r_o)" ;;
      *) log "Lauf $L_O: Ende weiter nicht gespeichert; nichts weiter getan"; exit 0 ;;
    esac
  fi
fi

MELD_JSON="$(printf '{"programm":"%s"}' "$PROGRAMM_FASSUNG")"
if ! AUFTRAG="$(printf '%s\n' "SELECT ally_update_host_plan(:'meldung'::jsonb);" | sql -v meldung="$MELD_JSON" -f - 2>>"$PROTOKOLL")"; then
  log "Datenbank nicht erreichbar oder Migration 203 fehlt; nichts getan"
  exit 0
fi
[ -n "$AUFTRAG" ] || exit 0

# ---------------------------------------------------------------- GitHub
QUELLE=""; T=""
quelle_holen() {
  QUELLE="$(printf '%s\n' "SELECT coalesce(ally_einstellung('update_quelle'), '');" | sql -f - 2>>"$PROTOKOLL")" || QUELLE=""
  [[ "$QUELLE" =~ ^[A-Za-z0-9_.-]{1,100}/[A-Za-z0-9_.-]{1,100}$ && ! "$QUELLE" =~ (^|/)[.]{1,2}(/|$) ]] || { MELDUNG="Die Einstellung update_quelle fehlt oder ist ungültig (Form inhaber/repo)."; return 1; }
}
# Token aus den n8n-Zugangsdaten „GitHub“ (Wert „Bearer …“); nur in einer Variablen dieses Programms
token_holen() {
  local cid f
  cid="$(printf '%s\n' "SELECT id FROM credentials_entity WHERE name = 'GitHub' AND type = 'httpHeaderAuth' ORDER BY id LIMIT 1;" | sql_n8n -f - 2>>"$PROTOKOLL")" || cid=""
  [[ "$cid" =~ ^[A-Za-z0-9]{1,40}$ ]] || { MELDUNG="Der GitHub-Zugang (Zugangsdaten „GitHub“ in n8n) fehlt."; return 1; }
  # Datei im Container mit mktemp (Rechte 600), sofort danach gelöscht
  f="$(dc exec -T n8n mktemp </dev/null 2>/dev/null | tr -d '\r' | tail -n 1)" || f=""
  [[ "$f" =~ ^/tmp/[A-Za-z0-9._-]{1,60}$ ]] || { MELDUNG="Im n8n-Container ließ sich keine Arbeitsdatei anlegen."; return 1; }
  dc exec -T n8n n8n export:credentials --id="$cid" --decrypted --output="$f" </dev/null >/dev/null 2>&1
  T="$(dc exec -T n8n cat "$f" </dev/null 2>/dev/null | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
except ValueError:
    d = []
d = d if isinstance(d, list) else [d]
print(next((str((c.get("data") or {}).get("value") or "") for c in d if isinstance(c, dict) and c.get("name") == "GitHub"), ""))')" || T=""
  dc exec -T n8n rm -f "$f" </dev/null >/dev/null 2>&1 || true
  case "$T" in "Bearer "?*) ;; *) T=""; MELDUNG="Der GitHub-Zugang (Zugangsdaten „GitHub“ in n8n) ist leer oder ungültig."; return 1;; esac
}
gh() {  # gh <accept> <pfad> [curl-optionen]: Anfrage an die GitHub-API mit dem Token über stdin
  local accept="$1" pfad="$2"; shift 2
  printf 'Authorization: %s\n' "$T" | curl -fsSL --max-time 300 -H @- -H "Accept: $accept" -H 'X-GitHub-Api-Version: 2022-11-28' "$@" "$GITHUB/repos/$QUELLE/$pfad"
}

# ---------------------------------------------------------------- Auftrag „suchen“
suchen() {
  local sha fj zeile f c d n erg
  MELDUNG=""
  if quelle_holen && token_holen; then
    if ! sha="$(gh application/vnd.github.sha "commits/$ZWEIG" 2>>"$PROTOKOLL")" || [[ ! "$sha" =~ ^[0-9a-f]{40}$ ]]; then
      MELDUNG="Das Auslieferungs-Repo $QUELLE ist nicht erreichbar (GitHub-Zugang oder Netz prüfen)."
    else
      fj="$U/arbeit/freigegeben.json"
      if ! gh application/vnd.github.raw+json "contents/fassungen/freigegeben.json?ref=$sha" -o "$fj" 2>>"$PROTOKOLL"; then
        MELDUNG="Die Liste der freigegebenen Fassungen ist nicht lesbar."
      elif ! zeile="$(hilfe neueste "$fj" 2>&1)"; then
        MELDUNG="$zeile"
      else
        IFS='|' read -r f c d n <<< "$zeile"
      fi
      rm -f "$fj"
    fi
  fi
  T=""
  erg="$(printf '%s\n' "SELECT ally_update_host_verfuegbar(nullif(:'f', ''), nullif(:'c', ''), nullif(:'d', ''), nullif(:'n', ''), nullif(:'q', ''), nullif(:'m', ''));" \
    | sql -v f="${f:-}" -v c="${c:-}" -v d="${d:-}" -v n="${n:-}" -v q="${sha:-}" -v m="$MELDUNG" -f - 2>>"$PROTOKOLL")" || erg="nicht gespeichert"
  log "Suche: ${MELDUNG:-Fassung ${f:-?} (${c:0:7})} -> $erg"
}

# ---------------------------------------------------------------- Auftrag „aktualisieren“
LAUF=""; VON=""; VON_COMMIT=""; LAUF_OFFEN=""; ARBEIT=""; SICH=""; P=""
MIG_EINGESPIELT=(); WF_BEGONNEN=0; WF_IDS=""; WF_NEU=""; WEBAPP_BEGONNEN=0; NEUSTART_BEGONNEN=0; GEAENDERT=0
schritt() {  # schritt <name> <ok|fehler|uebersprungen|info> <text>; Antwort ≠ ok (z. B. Grenze von 200 Schritten) steht im Protokoll
  local r
  r="$(printf '%s\n' "SELECT ally_update_host_schritt(:lauf, :'s', :'e', :'t');" | sql -v lauf="$LAUF" -v s="$1" -v e="$2" -v t="${3:-}" -f - 2>>"$PROTOKOLL")" \
    || r="nicht gespeichert"
  [ "$r" = ok ] || log "Lauf $LAUF: Schritt $1 nicht gespeichert ($r)"
  log "Lauf $LAUF: $1 $2 ${3:-}"
}
ende() {  # ende <status> <ergebnis (verständlich)> <unvollstaendig t|f> <detail (Rohtext, nur Superadmins)>
  local r
  r="$(ende_db "$LAUF" "$1" "$2" "$3" "${4:-}")" || r="nicht gespeichert"
  log "Lauf $LAUF: Ende $1 ($r) $2 ${4:-}"
  [ "$r" = ok ]
}
n8n_neustart() {
  local i
  dc restart n8n >/dev/null 2>>"$PROTOKOLL" || { MELDUNG="n8n ließ sich nicht neu starten."; return 1; }
  for i in $(seq 60); do curl -fsS --max-time 5 http://127.0.0.1:5678/healthz >/dev/null 2>&1 && return 0; sleep "${ALLY_WARTEN:-2}"; done
  MELDUNG="n8n meldet sich nach dem Neustart nicht (healthz)."; return 1
}
import_workflows() {  # import_workflows <ordner unter $ZIEL/import>
  chown -R 1000:1000 "$ZIEL/import/$1" 2>/dev/null || true
  dc run --rm -T --label traefik.enable=false n8n import:workflow --separate --input="/import/$1" </dev/null >>"$PROTOKOLL" 2>&1
}
aktiv_setzen() {  # aktiv_setzen <ids an> <ids aus>: Schaltzustand in der n8n-Datenbank (wie „n8n publish:workflow“ bzw. unpublish); Ausgabe = Zahl eingeschaltet
  printf '%s\n' "WITH a AS (UPDATE workflow_entity w SET active = false, \"activeVersionId\" = NULL WHERE w.id = ANY (string_to_array(:'aus', ',')) RETURNING 1),
e AS (UPDATE workflow_entity w SET active = true, \"activeVersionId\" = w.\"versionId\" WHERE w.id = ANY (string_to_array(:'an', ',')) AND NOT w.\"isArchived\"
  AND EXISTS (SELECT 1 FROM workflow_history h WHERE h.\"workflowId\" = w.id AND h.\"versionId\" = w.\"versionId\") RETURNING 1)
SELECT (SELECT count(*) FROM e) + 0 * (SELECT count(*) FROM a);" | sql_n8n -v an="$1" -v aus="$2" -f - 2>>"$PROTOKOLL"
}
zaehle() { if [ -z "$1" ]; then echo 0; else awk -F, '{print NF}' <<< "$1"; fi; }

platz() {  # vor dem Download: frei mindestens 2 × Größe der Datenbank + Paket (Schätzung: bisheriges Paket) + Zuschlag, wenigstens MIN_FREI
  local db pk frei noetig
  db="$(printf '%s\n' "SELECT pg_database_size(current_database());" | sql -f - 2>>"$PROTOKOLL")" || db=""
  [[ "$db" =~ ^[0-9]+$ ]] || { MELDUNG="Größe der Datenbank nicht lesbar."; return 1; }
  pk="$(du -sb "$PAKET_ORT" 2>/dev/null | cut -f1)"; [[ "$pk" =~ ^[0-9]+$ ]] || pk=$((50 * 1024 * 1024))
  noetig=$((2 * db + pk + ZUSCHLAG)); [ "$noetig" -lt "$MIN_FREI" ] && noetig="$MIN_FREI"
  frei="$(df -B1 --output=avail "$U" 2>/dev/null | tail -n 1 | tr -dc 0-9)"
  [ -n "$frei" ] && [ "$frei" -lt "$noetig" ] && { MELDUNG="frei $((frei / 1024 / 1024)) MB, nötig $((noetig / 1024 / 1024)) MB"; return 1; }
  return 0
}
laden() {
  quelle_holen || return 1
  token_holen || return 1
  { mkdir -p "$P" && chmod 700 "$SICH"; } || { MELDUNG="Ordner für das Paket nicht angelegt."; return 1; }
  # Tarball genau zum Commit des Auslieferungs-Repos, der bei der Suche gelesen wurde (nicht der aktuelle Kopf von main)
  if ! gh application/vnd.github+json "tarball/$Q_SHA" -o "$SICH/paket.tgz" 2>>"$PROTOKOLL"; then T=""; MELDUNG="Tarball $Q_SHA nicht geladen."; return 1; fi
  T=""
  tar -xzf "$SICH/paket.tgz" -C "$P" --strip-components=1 2>>"$PROTOKOLL" || { MELDUNG="Paket ließ sich nicht entpacken."; return 1; }
  rm -f "$SICH/paket.tgz"
}
pruefen() {
  local aus ist mind
  # zuerst mit dem Programm dieser Installation: Freigabe (genau der gelesene Eintrag), Reihenfolge, Programme und hilfe.py laut Zettel „installation“ (sha256)
  aus="$(hilfe pruefen "$P" "$ZU" "$ZU_COMMIT" "$VON" 2>&1)" || { MELDUNG="$aus"; return 1; }
  mind="$aus"
  aus="$(python3 -I "$P/server/installation/hilfe.py" pruefen "$P" "$ZU" 2>&1)" || { MELDUNG="Paket fehlerhaft: $(printf '%s' "$aus" | sauber)"; return 1; }
  MIGS="$(hilfe migrationen "$P" "$ZU" 2>&1)" || { MELDUNG="$MIGS"; return 1; }
  ist="$(dc exec -T n8n n8n --version </dev/null 2>/dev/null | tr -d '\r' | tail -n 1)" || ist=""
  aus="$(hilfe version_ok "$ist" "$mind" 2>&1)" || { MELDUNG="$aus"; return 1; }
  PRUEF_TEXT="Paket geprüft (Fassung $ZU, n8n ${ist:-?})"
}
sichern() {
  local n
  mkdir -p "$SICH/workflows" || { MELDUNG="Ordner der Sicherung nicht angelegt."; return 1; }
  dc exec -T postgres pg_dump -U postgres -Fc ally </dev/null > "$SICH/ally.dump" 2>>"$PROTOKOLL" && [ -s "$SICH/ally.dump" ] \
    || { MELDUNG="Datenbank-Sicherung fehlgeschlagen (pg_dump)."; return 1; }
  rm -rf "$ZIEL/import/update-$LAUF-alt"; mkdir -p "$ZIEL/import/update-$LAUF-alt"; chown 1000:1000 "$ZIEL/import" "$ZIEL/import/update-$LAUF-alt" 2>/dev/null || true
  dc exec -T n8n n8n export:workflow --all --separate --output="/import/update-$LAUF-alt/" </dev/null >>"$PROTOKOLL" 2>&1 \
    || { MELDUNG="Sicherung der Workflows fehlgeschlagen (n8n export)."; return 1; }
  mv "$ZIEL/import/update-$LAUF-alt"/*.json "$SICH/workflows/" 2>/dev/null; rm -rf "$ZIEL/import/update-$LAUF-alt"
  n="$(find "$SICH/workflows" -name '*.json' | wc -l)"
  [ "$n" -gt 0 ] || { MELDUNG="Sicherung der Workflows ist leer."; return 1; }
  { printf '%s\n' "SELECT coalesce(json_agg(json_build_object('id', w.id, 'active', w.active, 'versionId', w.\"versionId\") ORDER BY w.id), '[]') FROM workflow_entity w;" \
    | sql_n8n -f - > "$SICH/aktiv.json" 2>>"$PROTOKOLL" && [ -s "$SICH/aktiv.json" ]; } || { MELDUNG="Schaltzustand der Workflows nicht gesichert."; return 1; }
  { printf '%s\n' "SELECT coalesce(json_agg(json_build_object('name', x.name, 'inhalt', x.inhalt, 'fassung', x.fassung, 'bytes', x.bytes, 'quelle', x.quelle, 'geaendert_am', x.geaendert_am) ORDER BY x.name), '[]') FROM ally_webapp_dateien x;" \
    | sql -f - > "$SICH/webapp.json" 2>>"$PROTOKOLL" && [ -s "$SICH/webapp.json" ]; } || { MELDUNG="Web-App-Dateien nicht gesichert."; return 1; }
  if [ -f "$ZIEL/fassung.json" ]; then cp "$ZIEL/fassung.json" "$SICH/fassung.json" || { MELDUNG="fassung.json nicht gesichert."; return 1; }
  else : > "$SICH/fassung.keine"; fi
  # Merker je Migration (begonnen N / ok N) für den Rückweg nach einem harten Abbruch; vor dem Schritt „sichern ok“ (dieser meldet der Datenbank den Ordner)
  : > "$SICH/migrationen.txt" || { MELDUNG="Merker der Migrationen nicht angelegt."; return 1; }
  SICH_TEXT="Datenbank, $n Workflows, Schaltzustand und Web-App gesichert"
}
# fassung.json dieser Installation nur glauben, wenn Nummer und eingespielt_commit zu ally_fassung passen (sonst z. B. Datenbank aus einer älteren Sicherung)
zettel_vertraut() {
  [ -f "$ZIEL/fassung.json" ] && [ -n "$VON" ] && hilfe fassung_vertraut "$ZIEL/fassung.json" "$VON" "$VON_COMMIT" 2>/dev/null
}
# Welche Migrationen fehlen? Der Wächter „schon eingespielt“ einer älteren Migration ist nicht verlässlich, sobald eine spätere ihre Funktionen geändert hat (z. B. 201
# nach 202: „unbekannter Stand“). Deshalb: Migrationen, die der Zettel dieser Installation (/opt/ally/fassung.json) schon nennt, gelten ohne Probe als eingespielt.
# Für die übrigen von der neuesten rückwärts je eine Probe (BEGIN … ROLLBACK, ändert nichts) bis zum ersten Treffer: Treffer = Rückgabe ≠ 0 und genau die Meldung
# „Migration <Nr>: schon eingespielt“. Sie und alle davor gelten als eingespielt; alle danach werden der Reihe nach eingespielt (je eine Transaktion, psql -1).
probe_migration() { { printf 'BEGIN;\n'; cat "$P/$1"; printf '\nROLLBACK;\n'; } | dc exec -T postgres psql -X -q -v ON_ERROR_STOP=1 -U ally -d ally -f - 2>&1; }
schon_drin() {  # schon_drin <nr> <ausgabe> <rückgabe>
  [ "$3" -ne 0 ] && grep -qF "Migration $1: schon eingespielt" <<< "$2"
}
migrationen() {
  local nr datei rb wq wn aus rc w i k=-1 start eingespielt=0 ueber=0 zeilen=() bekannt=""
  [ -n "$MIGS" ] && mapfile -t zeilen <<< "$MIGS"
  if zettel_vertraut; then bekannt=",$(hilfe zettel_migrationen "$ZIEL/fassung.json" 2>/dev/null | paste -sd,),"
  else log "Lauf $LAUF: fassung.json passt nicht zur Datenbank (Fassung ${VON:-?}); alle Migrationen werden geprobt"; fi
  for ((i = 0; i < ${#zeilen[@]}; i++)); do IFS='|' read -r nr _ <<< "${zeilen[$i]}"; [[ "$bekannt" == *",$nr,"* ]] && k=$i; done
  start=$((k + 1))
  for ((i = ${#zeilen[@]} - 1; i > k; i--)); do
    IFS='|' read -r nr datei _ <<< "${zeilen[$i]}"
    aus="$(probe_migration "$datei")"; rc=$?
    log "Lauf $LAUF: Probe Migration $nr"
    if schon_drin "$nr" "$aus" "$rc"; then start=$((i + 1)); break; fi
  done
  for ((i = 0; i < ${#zeilen[@]}; i++)); do
    IFS='|' read -r nr datei rb wq wn <<< "${zeilen[$i]}"
    if [ "$i" -lt "$start" ]; then
      ueber=$((ueber + 1)); schritt "migration $nr" uebersprungen "$([ "$i" -le "$k" ] && echo "laut Zettel dieser Installation eingespielt" || echo "schon eingespielt")"
      continue
    fi
    printf 'begonnen %s\n' "$nr" >> "$SICH/migrationen.txt" || { KURZ="Datenbank-Änderung $nr nicht möglich."; MELDUNG="Merker der Migration $nr nicht geschrieben."; return 1; }
    schritt "migration $nr" info "wird eingespielt"
    aus="$(dc exec -T postgres psql -X -q -v ON_ERROR_STOP=1 -U ally -d ally -1 -f - < "$P/$datei" 2>&1)"; rc=$?
    if [ "$rc" -eq 0 ]; then
      MIG_EINGESPIELT+=("$nr|$rb"); GEAENDERT=1; eingespielt=$((eingespielt + 1))
      printf 'ok %s\n' "$nr" >> "$SICH/migrationen.txt" || log "Lauf $LAUF: Merker ok $nr nicht geschrieben (Probe beim Zurücksetzen)"
      w="$(sql -f - < "$P/$wq" 2>/dev/null | tail -n 1)" || w=""
      if [ -n "$wn" ] && [ "$w" != "$wn" ]; then schritt "migration $nr" ok "eingespielt (Wächter weicht vom Bau ab, nur Hinweis)"; else schritt "migration $nr" ok "eingespielt"; fi
    elif schon_drin "$nr" "$aus" "$rc"; then
      ueber=$((ueber + 1)); schritt "migration $nr" uebersprungen "schon eingespielt"
    else
      KURZ="Datenbank-Änderung $nr nicht möglich."; MELDUNG="Migration $nr: $(printf '%s' "$aus" | sauber)"; schritt "migration $nr" fehler "$(printf '%s' "$aus" | sauber)"; return 1
    fi
  done
  MIG_TEXT="$eingespielt eingespielt, $ueber schon vorhanden"
}
workflows() {
  local plan an aus neu ent n ist
  rm -rf "$ZIEL/import/update-$LAUF-alle" "$ZIEL/import/update-$LAUF-neu"
  python3 -I "$P/server/installation/hilfe.py" workflows "$P" "$ZU" "$ZIEL/import/update-$LAUF-alle" >/dev/null 2>>"$PROTOKOLL" \
    || { MELDUNG="Workflows des Pakets nicht vorbereitet (Installationswerte?)."; return 1; }
  rm -f "$ZIEL/import/aktiv.txt"
  plan="$(hilfe auswahl "$P" "$ZU" "$(zettel_vertraut && echo "$ZIEL/fassung.json" || echo -)" "$ZIEL/import/update-$LAUF-alle" "$ZIEL/import/update-$LAUF-neu" "$SICH/aktiv.json" 2>&1)" \
    || { MELDUNG="$plan"; return 1; }
  rm -rf "$ZIEL/import/update-$LAUF-alle"
  an="$(sed -n 's/^an=//p' <<< "$plan")"; aus="$(sed -n 's/^aus=//p' <<< "$plan")"; neu="$(sed -n 's/^neu=//p' <<< "$plan")"
  ent="$(sed -n 's/^entfernt=//p' <<< "$plan")"; n="$(sed -n 's/^import=//p' <<< "$plan")"
  WF_NEU="$neu"; WF_IDS="$(printf '%s,%s' "$an" "$aus" | sed 's/^,//; s/,$//')"
  # Merker für den Rückweg nach einem harten Abbruch: vor der ersten Änderung an n8n
  printf 'ids=%s\nneu=%s\n' "$WF_IDS" "$WF_NEU" > "$SICH/wf_ids" || { MELDUNG="Merker der Workflows nicht geschrieben."; return 1; }
  WF_BEGONNEN=1; GEAENDERT=1
  if [ "${n:-0}" -gt 0 ]; then
    import_workflows "update-$LAUF-neu" || { rm -rf "$ZIEL/import/update-$LAUF-neu"; MELDUNG="Import der Workflows fehlgeschlagen (n8n import:workflow)."; return 1; }
  fi
  rm -rf "$ZIEL/import/update-$LAUF-neu"
  ist="$(aktiv_setzen "$an" "$aus")" || { MELDUNG="Schaltzustand der Workflows nicht gesetzt."; return 1; }
  [ "$ist" = "$(zaehle "$an")" ] || { MELDUNG="Nur $ist von $(zaehle "$an") Workflows eingeschaltet."; return 1; }
  WF_TEXT="${n:-0} importiert (neu: $(zaehle "$neu")), eingeschaltet: $ist, ausgeschaltet: $(zaehle "$aus")${ent:+, nicht mehr in der Fassung: $(zaehle "$ent")}"
  return 0
}
# Fehler Nr. 47 (Stefan 03.11.2026: gehört zum Basispaket): Erweiterungen für n8n laut n8n-erweiterungen.txt des Pakets (fehlende bzw. andere Version), vor dem
# Neustart von n8n. Ein Paket ohne Liste (Fassung vor Nr. 47): nichts zu tun. Der Rückweg entfernt keine Erweiterung (sie schadet der alten Fassung nicht).
erweiterungen() {
  [ -f "$P/server/installation/n8n-erweiterungen.sh" ] || { ERW_TEXT="keine im Paket"; return 0; }
  if bash "$P/server/installation/n8n-erweiterungen.sh" "$ZIEL" > "$SICH/erweiterungen.txt" 2>>"$PROTOKOLL"; then
    ERW_TEXT="$(tr '\n' ' ' < "$SICH/erweiterungen.txt" | sed 's/ *$//')"; return 0
  fi
  MELDUNG="Erweiterungen für n8n nicht installiert: $(tr '\n' ' ' < "$SICH/erweiterungen.txt" | sed 's/ *$//') (Protokoll $PROTOKOLL)"; return 1
}
webapp() {
  local f="$SICH/webapp.sql"
  hilfe webapp_sql "$P" "$ZU" "$QUELLE" "$Q_SHA" > "$f" 2>"$SICH/webapp.err" || { MELDUNG="$(cat "$SICH/webapp.err")"; return 1; }
  : > "$SICH/webapp"; WEBAPP_BEGONNEN=1; GEAENDERT=1
  sql -f - < "$f" >/dev/null 2>>"$PROTOKOLL" || { MELDUNG="Web-App-Dateien nicht gespeichert."; return 1; }
  rm -f "$f" "$SICH/webapp.err"
}

# Rückweg: Workflows aus der Sicherung, Rückbau der in diesem Lauf eingespielten Migrationen (umgekehrte Reihenfolge), Web-App alt, n8n neu starten.
# Setzt RUECK_TEXT; Rückgabe 1, wenn ein Teil nicht zurückging. Läuft ohne Unterbrechung durch INT/TERM/HUP (siehe ohne_signale).
rueckweg() {
  local ok=0 i nr rb aus plan an zaus d="update-$LAUF-zurueck" id
  RUECK_TEXT=""
  if [ "$WF_BEGONNEN" = 1 ] && [ -n "$WF_IDS" ]; then
    rm -rf "${ZIEL:?}/import/$d"; mkdir -p "$ZIEL/import/$d"
    for id in ${WF_IDS//,/ }; do [ -f "$SICH/workflows/$id.json" ] && cp "$SICH/workflows/$id.json" "$ZIEL/import/$d/"; done
    if [ -n "$(ls -A "$ZIEL/import/$d")" ] && ! import_workflows "$d"; then ok=1; RUECK_TEXT+=" Workflows nicht zurückgespielt."; fi
    rm -rf "${ZIEL:?}/import/$d"
    plan="$(hilfe zurueck_aktiv "$SICH/aktiv.json" "$WF_IDS" 2>>"$PROTOKOLL")"
    an="$(sed -n 's/^an=//p' <<< "$plan")"; zaus="$(sed -n 's/^aus=//p' <<< "$plan")"
    { aus="$(aktiv_setzen "$an" "$zaus")" && [ "$aus" = "$(zaehle "$an")" ]; } || { ok=1; RUECK_TEXT+=" Schaltzustand der Workflows nicht vollständig zurückgesetzt."; }
    schritt "rueckweg workflows" "$([ $ok = 0 ] && echo ok || echo fehler)" "aus der Sicherung, neu angelegte ausgeschaltet: $(zaehle "$WF_NEU")"
  fi
  for ((i = ${#MIG_EINGESPIELT[@]} - 1; i >= 0; i--)); do
    IFS='|' read -r nr rb <<< "${MIG_EINGESPIELT[$i]}"
    if aus="$(dc exec -T postgres psql -X -q -v ON_ERROR_STOP=1 -U ally -d ally -1 -f - < "$P/$rb" 2>&1)"; then
      schritt "rueckbau $nr" ok "zurückgebaut"
    else
      ok=1; RUECK_TEXT+=" Rückbau $nr fehlgeschlagen: $(printf '%s' "$aus" | sauber)."
      schritt "rueckbau $nr" fehler "$(printf '%s' "$aus" | sauber)"
      break
    fi
  done
  if [ "$WEBAPP_BEGONNEN" = 1 ]; then
    if hilfe webapp_zurueck "$SICH/webapp.json" 2>>"$PROTOKOLL" | sql -f - >/dev/null 2>>"$PROTOKOLL"; then schritt "rueckweg webapp" ok "Web-App wie vorher"
    else ok=1; RUECK_TEXT+=" Web-App nicht zurückgesetzt."; schritt "rueckweg webapp" fehler ""; fi
  fi
  # fassung.json wie vor dem Lauf (wird im Lauf nicht geändert; nach einem harten Abbruch zur Sicherheit aus der Sicherung)
  if [ -f "$SICH/fassung.json" ]; then
    { cp "$SICH/fassung.json" "$ZIEL/fassung.json.neu" && chmod 644 "$ZIEL/fassung.json.neu" && mv "$ZIEL/fassung.json.neu" "$ZIEL/fassung.json"; } \
      || { ok=1; RUECK_TEXT+=" fassung.json nicht zurückgesetzt."; }
  elif [ -f "$SICH/fassung.keine" ]; then rm -f "$ZIEL/fassung.json"; fi
  if [ "$WF_BEGONNEN" = 1 ] || [ "$NEUSTART_BEGONNEN" = 1 ]; then
    if n8n_neustart; then schritt "rueckweg neustart" ok "n8n läuft"; else ok=1; RUECK_TEXT+=" $MELDUNG"; schritt "rueckweg neustart" fehler "$MELDUNG"; fi
  fi
  return $ok
}
ohne_signale() { trap '' INT TERM HUP; }
mit_signalen() { trap 'exit 1' INT TERM HUP; }

fehlschlag() {  # fehlschlag <kurz (verständlich)> <detail (Rohtext)>: Rückweg (wenn schon etwas geändert wurde) und Ende; SIGTERM wartet, bis alles fertig ist
  local kurz="$1" detail="${2:-}"
  ohne_signale
  if [ "$GEAENDERT" = 1 ]; then
    if rueckweg; then ende zurueckgenommen "$kurz Alles ist zurückgenommen." f "$detail"
    else ende fehler "$kurz Zurücknehmen nicht vollständig; der Anbieter ist informiert." t "$detail Rückweg:$RUECK_TEXT"; fi
  else
    ende fehler "$kurz Nichts geändert." f "$detail"
  fi
  LAUF_OFFEN=""
  mit_signalen
}

# Hart abgebrochenen Lauf zurücksetzen (Auftrag zuruecksetzen|lauf|ordner): Ordner nur $U/sicherung/<lauf>. Migrationen laut Merker migrationen.txt und
# ally_updates.schritte (ok; begonnen bzw. „wird eingespielt“ und laut Probe drin) rückwärts, Workflows und Web-App nach den Merkern aus der Sicherung dieses Laufs,
# fassung.json aus der Sicherung, n8n neu starten. Fehlt migrationen.txt in einer gemeldeten Sicherung, werden alle Migrationen des Pakets geprobt und nur gemeldet
# (Stand prüfen, Sperre bleibt). Ergebnis an ally_update_host_zurueckgesetzt.
zuruecksetzen() {
  local ordner nr datei rb ok=t text schritte merk="" aus rc r drin="" ohne_merker=0
  IFS='|' read -r _ LAUF ordner <<< "$1"
  [[ "$LAUF" =~ ^[0-9]+$ ]] || { log "Auftrag ungültig: $1"; return 0; }
  log "Lauf $LAUF: abgebrochenen Lauf zurücksetzen (Sicherung $ordner)"
  ohne_signale
  # Ordner nicht gemeldet (Schritt „sichern“ nicht gespeichert)? Die Merkerdatei entsteht am Ende der Sicherung, vor jeder Änderung: liegt sie vor, gilt der Ordner.
  [ "$ordner" = - ] && [ -f "$U/sicherung/$LAUF/migrationen.txt" ] && ordner="$U/sicherung/$LAUF"
  text="Vor dem Abbruch war noch nichts geändert."
  if [ "$ordner" != - ] && [ "$ordner" != "$U/sicherung/$LAUF" ]; then ok=f; text="Ordner der Sicherung ungültig (erwartet $U/sicherung/$LAUF); nichts zurückgesetzt."
  elif [ "$ordner" != - ] && [ ! -d "$ordner" ]; then ok=f; text="Sicherung $ordner fehlt."
  elif [ "$ordner" != - ]; then
    SICH="$ordner"; P="$SICH/paket"
    ZU="$(printf '%s\n' "SELECT zu_fassung FROM ally_updates WHERE id = :lauf;" | sql -v lauf="$LAUF" -f - 2>>"$PROTOKOLL")" || ZU=""
    schritte="$(printf '%s\n' "SELECT string_agg((s->>'schritt') || '|' || (s->>'ergebnis'), E'\n' ORDER BY n) FROM ally_updates u, jsonb_array_elements(u.schritte) WITH ORDINALITY AS x(s, n) WHERE u.id = :lauf;" \
      | sql -v lauf="$LAUF" -f - 2>>"$PROTOKOLL")" || schritte=""
    if [ -f "$SICH/migrationen.txt" ]; then merk="$(cat "$SICH/migrationen.txt")"; else ohne_merker=1; fi
    if ! MIGS="$(hilfe migrationen "$P" "$ZU" 2>&1)"; then
      ok=f; text="Paket des Laufs in der Sicherung nicht lesbar: $MIGS"
    else
      while IFS='|' read -r nr datei rb _; do
        [ -n "$nr" ] || continue
        if grep -qxF "ok $nr" <<< "$merk" || grep -qxF "migration $nr|ok" <<< "$schritte"; then MIG_EINGESPIELT+=("$nr|$rb")
        elif [ "$ohne_merker" = 1 ] || grep -qxF "begonnen $nr" <<< "$merk" || grep -qxF "migration $nr|info" <<< "$schritte"; then
          aus="$(probe_migration "$datei")"; rc=$?
          if schon_drin "$nr" "$aus" "$rc"; then
            if [ "$ohne_merker" = 1 ]; then drin+=" $nr"; else MIG_EINGESPIELT+=("$nr|$rb"); fi
          fi
        fi
      done <<< "$MIGS"
      if [ -f "$SICH/wf_ids" ]; then WF_BEGONNEN=1; WF_IDS="$(sed -n 's/^ids=//p' "$SICH/wf_ids")"; WF_NEU="$(sed -n 's/^neu=//p' "$SICH/wf_ids")"; fi
      [ -f "$SICH/webapp" ] && WEBAPP_BEGONNEN=1
      [ -f "$SICH/neustart" ] && NEUSTART_BEGONNEN=1
      if rueckweg; then text="Zurückgesetzt: Migrationen ${#MIG_EINGESPIELT[@]}, Workflows $([ "$WF_BEGONNEN" = 1 ] && echo ja || echo nein), Web-App $([ "$WEBAPP_BEGONNEN" = 1 ] && echo ja || echo nein)."
      else ok=f; text="Zurücksetzen unvollständig:$RUECK_TEXT"; fi
      if [ "$ohne_merker" = 1 ]; then
        ok=f; text="Merker der Migrationen fehlt in der Sicherung; nur sicher erkannte Schritte zurückgesetzt. Stand prüfen: laut Probe eingespielt:${drin:- keine}. $text"
      fi
    fi
  fi
  r="$(printf '%s\n' "SELECT ally_update_host_zurueckgesetzt(:lauf, :'ok'::boolean, :'t');" | sql -v lauf="$LAUF" -v ok="$ok" -v t="$text" -f - 2>>"$PROTOKOLL")" || r="nicht gespeichert"
  log "Lauf $LAUF: zurückgesetzt=$ok ($r) $text"
  mit_signalen
  return 0
}

# shellcheck disable=SC2329  # Aufruf über trap
aufraeumen() {
  T=""
  if [ -n "$LAUF_OFFEN" ]; then log "Lauf $LAUF: abgebrochen"; fehlschlag "Das Update wurde abgebrochen." "Abgebrochen: Das Update-Programm wurde während des Laufs beendet (Signal)."; fi
  [ -n "$ARBEIT" ] && rm -rf -- "$ARBEIT"
  rm -rf "${ZIEL:?}/import/update-"* 2>/dev/null || true
  # Sicherungen: die letzten 3 Läufe bleiben (ein hart abgebrochener Lauf wird schon beim nächsten Aufruf zurückgesetzt)
  find "$U/sicherung" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null | grep -E '^[0-9]+$' | sort -n | head -n -3 | while read -r d; do rm -rf -- "${U:?}/sicherung/$d"; done
}
trap aufraeumen EXIT
mit_signalen

ende_ok() {  # Ende eines erfolgreichen Updates, danach fassung.json; scheitert das Ende dreimal, Merker update/ende-offen (nächster Lauf holt es nach, kein Abbruch)
  local i
  for i in 1 2 3; do
    if ende ok "$1" f ""; then
      hilfe fassung_schreiben "$P/fassungen/$ZU.json" "$ZU_COMMIT" "$ZIEL/fassung.json" 2>>"$PROTOKOLL" || log "Lauf $LAUF: fassung.json nicht ersetzt"
      return 0
    fi
    sleep "${ALLY_WARTEN:-2}"
  done
  cp "$P/fassungen/$ZU.json" "$U/ende-offen.zettel" 2>>"$PROTOKOLL" || log "Lauf $LAUF: Zettel für ende-offen nicht kopiert"
  printf '%s\n%s\n%s\n' "$LAUF" "$1" "$ZU_COMMIT" > "$U/ende-offen"
  log "Lauf $LAUF: Ende nicht gespeichert, Merker update/ende-offen"
  return 1
}

aktualisieren() {
  IFS='|' read -r _ LAUF ZU ZU_COMMIT Q_SHA ART <<< "$1"
  [[ "$LAUF" =~ ^[0-9]+$ ]] && [[ "$ZU" =~ ^[0-9]{1,3}\.[0-9]{1,3}$ ]] && [[ "$ZU_COMMIT" =~ ^[0-9a-f]{7,40}$ ]] && [[ "$Q_SHA" =~ ^[0-9a-f]{40}$ ]] \
    || { log "Auftrag ungültig: $1"; return 0; }
  LAUF_OFFEN="$LAUF"; SICH="$U/sicherung/$LAUF"; P="$SICH/paket"
  VON="$(printf '%s\n' "SELECT coalesce(ally_fassung_aktuell(), '');" | sql -f - 2>>"$PROTOKOLL")" || VON=""
  VON_COMMIT="$(printf '%s\n' "SELECT coalesce((SELECT git_commit FROM ally_fassung WHERE nummer = ally_fassung_aktuell()), '');" | sql -f - 2>>"$PROTOKOLL")" || VON_COMMIT=""
  log "Lauf $LAUF: ${ART:-update} $VON -> $ZU ($ZU_COMMIT, Paket $Q_SHA) beginnt"
  MELDUNG=""; KURZ=""
  # Art des Auftrags (ally_update_stand.auftrag_art): bisher wird nur „update“ ausgeführt. Vorgesehen (Konzept folgt): modul_installieren/modul_entfernen =
  # Workflows einer Teilmenge aus dem Zettel importieren bzw. archivieren, mit derselben Sperre (flock, ally_updates_ein_lauf), Sicherung und demselben Rückweg.
  if [ "${ART:-update}" != update ]; then fehlschlag "Diese Art von Auftrag ist noch nicht möglich." "Art „$ART“ wird nicht ausgeführt."; return 0; fi
  platz || { schritt platz fehler "$MELDUNG"; fehlschlag "Zu wenig Platz auf dem Server für das Update." "$MELDUNG"; return 0; }
  laden || { schritt laden fehler "$MELDUNG"; fehlschlag "Das Paket ließ sich nicht laden (GitHub-Zugang oder Netz)." "$MELDUNG"; return 0; }
  schritt laden ok "Paket $QUELLE@${Q_SHA:0:12}"
  pruefen || { schritt pruefen fehler "$MELDUNG"; fehlschlag "Das Paket ist nicht in Ordnung. Bitte den Anbieter informieren." "$MELDUNG"; return 0; }
  schritt pruefen ok "$PRUEF_TEXT"
  sichern || { schritt sichern fehler "$MELDUNG"; fehlschlag "Die Sicherung vor dem Update war nicht möglich." "$MELDUNG"; return 0; }
  schritt sichern ok "$SICH"; schritt sicherung info "$SICH_TEXT"
  migrationen || { fehlschlag "$KURZ" "$MELDUNG"; return 0; }
  schritt migrationen ok "$MIG_TEXT"
  workflows || { schritt workflows fehler "$MELDUNG"; fehlschlag "Die Abläufe ließen sich nicht einspielen." "$MELDUNG"; return 0; }
  schritt workflows ok "$WF_TEXT"
  erweiterungen || { schritt erweiterungen fehler "$MELDUNG"; fehlschlag "Die Erweiterungen für n8n ließen sich nicht installieren." "$MELDUNG"; return 0; }
  schritt erweiterungen ok "$ERW_TEXT"
  : > "$SICH/neustart"; NEUSTART_BEGONNEN=1
  n8n_neustart || { schritt neustart fehler "$MELDUNG"; fehlschlag "n8n ließ sich nicht neu starten." "$MELDUNG"; return 0; }
  schritt neustart ok "n8n läuft"
  webapp || { schritt webapp fehler "$MELDUNG"; fehlschlag "Die Oberfläche ließ sich nicht aktualisieren." "$MELDUNG"; return 0; }
  schritt webapp ok "Web-App aus dem Paket ($QUELLE@${Q_SHA:0:12})"
  # ab hier gilt das Update als eingespielt (auch wenn nur der Merker ende-offen steht)
  ohne_signale
  ende_ok "Fassung $ZU eingespielt. Migrationen: $MIG_TEXT. Workflows: $WF_TEXT."
  LAUF_OFFEN=""
  mit_signalen
  # Nach dem Update: Paket dieser Installation, Programme auf dem Server (nur wenn geändert; Fehler hier ändern nichts am Ergebnis)
  if rm -rf "${PAKET_ORT:?}.alt" && { [ ! -d "$PAKET_ORT" ] || mv "$PAKET_ORT" "$PAKET_ORT.alt"; } && cp -a "$P" "$PAKET_ORT"; then rm -rf "${PAKET_ORT:?}.alt"
  else log "Lauf $LAUF: Paket nicht nach $PAKET_ORT übernommen"; fi
  P="$PAKET_ORT"
  if [ -f "$P/server/installation/sicherung/ally-sicherung.sh" ] && ! cmp -s "$P/server/installation/sicherung/ally-sicherung.sh" "$ZIEL/ally-sicherung.sh"; then
    bash "$P/server/installation/sicherung/einrichten.sh" >>"$PROTOKOLL" 2>&1 || log "Lauf $LAUF: Backup-Programm nicht neu eingerichtet"
  fi
  if [ -f "$P/server/installation/update/ally-update.sh" ] && { ! cmp -s "$P/server/installation/update/ally-update.sh" "$ZIEL/ally-update.sh" \
       || ! cmp -s "$P/server/installation/update/ally-update-hilfe.py" "$ZIEL/ally-update-hilfe.py"; }; then
    ALLY_UPDATE_OHNE_LAUF=1 bash "$P/server/installation/update/einrichten.sh" >>"$PROTOKOLL" 2>&1 || log "Lauf $LAUF: Update-Programm nicht neu eingerichtet"
  fi
  return 0
}

case "$AUFTRAG" in
  suchen) suchen ;;
  zuruecksetzen\|*) zuruecksetzen "$AUFTRAG" ;;
  aktualisieren\|*) aktualisieren "$AUFTRAG" ;;
  *) log "Unbekannter Auftrag: $AUFTRAG" ;;
esac
exit 0
