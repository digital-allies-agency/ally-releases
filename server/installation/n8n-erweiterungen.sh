#!/usr/bin/env bash
# Ally – Erweiterungen (Community-Pakete) für n8n aus n8n-erweiterungen.txt installieren (Fehler Nr. 47, Stefan 03.11.2026: gehört zum Basispaket).
# Aufruf: bash n8n-erweiterungen.sh <ziel, z. B. /opt/ally>   (von installieren.sh vor dem ersten Start von n8n und von ally-update.sh vor dem Neustart von n8n)
# Läuft in einem eigenen, kurzlebigen n8n-Container (docker compose run, höchstens 15 Minuten) mit dem Daten-Ordner von n8n; n8n selbst darf dabei laufen oder aus sein.
# Installiert wird nur, was fehlt oder in anderer Version da ist, in den Ordner ~/.n8n/nodes (manuelle Installation laut n8n-Dokumentation, wird beim Start
# von n8n geladen). Prüfung 2 (03.11.2026):
#   - npm läuft ohne Installationsskripte der Pakete (--ignore-scripts, wie n8n selbst) und ohne die Umgebung des Dienstes (env -i: kein Schlüssel von n8n,
#     kein Datenbank-Passwort), ohne Lockdatei (--package-lock=false, wie n8n).
#   - Nichts darf verschwinden: der Ordner nodes wird vor npm nach nodes.vor-update kopiert; verglichen werden die Pakete aus package.json und alle n8n-nodes-*
#     in node_modules (npm entfernt Pakete, die nicht in package.json stehen). Fehlt danach eines, scheitert npm oder stimmt die Version nicht, kommt der Ordner
#     wie vorher zurück und das Skript bricht mit Meldung ab. npm höchstens 10 Minuten (timeout im Container, falls vorhanden), der ganze Lauf höchstens 15.
#   - Proxy-Angaben (HTTP_PROXY, HTTPS_PROXY, NO_PROXY) gehen an npm weiter, wenn der Dienst sie hat.
# --legacy-peer-deps: n8n-workflow bringt n8n selbst mit (ohne die Option holt npm es samt isolated-vm, das auf dem Server Python und Compiler bräuchte).
# Wirkt erst nach einem (Neu-)Start von n8n. Ausgabe (stdout): je Paket „ok   name@version vorhanden“, „neu  name@version installiert“ oder „FEHL …“;
# Rückgabe ≠ 0, wenn ein Paket danach nicht in der Version da ist, ein anderes verschwunden ist oder die Liste ungültig ist.
set -Eeuo pipefail
set -f
ZIEL="${1:?Ziel fehlt}"
LISTE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/n8n-erweiterungen.txt"
[ -f "$LISTE" ] || { echo "FEHL Liste $LISTE fehlt"; exit 1; }
PAKETE="$({ grep -vE '^[[:space:]]*(#|$)' "$LISTE" || true; } | tr -d '\r' | tr '\n' ' ')"
for p in $PAKETE; do
  [[ "$p" =~ ^(@[a-z0-9][a-z0-9._-]*/)?n8n-nodes-[a-z0-9][a-z0-9._-]*@[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "FEHL ungültiger Eintrag in n8n-erweiterungen.txt: $p"; exit 1; }
done
[ -n "${PAKETE// /}" ] || { echo "ok   keine Erweiterungen nötig"; exit 0; }
cd "$ZIEL"
# shellcheck disable=SC2016  # $-Ausdrücke werden im Container ausgewertet
timeout 900 docker compose run --rm -T --no-deps --label traefik.enable=false --entrypoint sh -e ALLY_PAKETE="$PAKETE" n8n -c '
set -eu
set -f
mkdir -p "$HOME/.n8n/nodes"; cd "$HOME/.n8n/nodes"
[ -f package.json ] || printf "{\n  \"name\": \"installed-nodes\",\n  \"private\": true\n}\n" > package.json
ver() { node -e "try { process.stdout.write(require(process.cwd() + \"/node_modules/\" + process.argv[1] + \"/package.json\").version) } catch (e) {}" "$1"; }
# geschützt: Pakete, die in package.json stehen (z. B. über die n8n-Oberfläche installiert), und alle n8n-nodes-* in node_modules (auch von Hand abgelegte);
# Abhängigkeiten, die npm beim Versionswechsel zu Recht entfernt, zählen nicht (Prüfung 3)
liste() { node -e "const fs = require(\"fs\"), d = \"node_modules\"; const o = new Set();
  try { for (const n of Object.keys(JSON.parse(fs.readFileSync(\"package.json\", \"utf8\")).dependencies || {})) if (fs.existsSync(d + \"/\" + n)) o.add(n); } catch (e) {}
  const knoten = n => /^(@[^/]+\\/)?n8n-nodes-/.test(n);
  if (fs.existsSync(d)) for (const n of fs.readdirSync(d)) { if (n.startsWith(\".\")) continue;
    if (n.startsWith(\"@\")) { for (const m of fs.readdirSync(d + \"/\" + n)) if (knoten(n + \"/\" + m)) o.add(n + \"/\" + m); } else if (knoten(n)) o.add(n); }
  process.stdout.write([...o].sort().join(\"\\n\"))"; }
zurueck() { cd ..; rm -rf nodes; mv nodes.vor-update nodes; cd nodes; }
T=""; command -v timeout >/dev/null 2>&1 && T="timeout 600"
fehl=0
for p in $ALLY_PAKETE; do
  name="${p%@*}"; soll="${p##*@}"
  if [ "$(ver "$name")" = "$soll" ]; then echo "ok   $p vorhanden"; continue; fi
  vorher="$(liste)"
  rm -rf ../nodes.vor-update && cp -a . ../nodes.vor-update
  env -i HOME="$HOME" PATH="$PATH" HTTP_PROXY="${HTTP_PROXY:-}" HTTPS_PROXY="${HTTPS_PROXY:-}" NO_PROXY="${NO_PROXY:-}" $T npm install --legacy-peer-deps --save-exact --ignore-scripts --package-lock=false --no-audit --no-fund --loglevel=error "$p" >&2 || true
  nachher="$(liste)"
  weg="$(printf "%s\n" "$vorher" | while IFS= read -r x; do [ -z "$x" ] || printf "%s\n" "$nachher" | grep -qxF "$x" || printf "%s " "$x"; done)"
  if [ -n "$weg" ]; then zurueck; echo "FEHL $p: npm hätte andere Pakete entfernt ($weg); Ordner wie vorher, nichts installiert"; fehl=1; break; fi
  if [ "$(ver "$name")" != "$soll" ]; then zurueck; echo "FEHL $p nicht installiert; Ordner wie vorher"; fehl=1; break; fi
  rm -rf ../nodes.vor-update; echo "neu  $p installiert"
done
exit $fehl
' </dev/null
