#!/usr/bin/env python3
# Hilfsschritte für installieren.sh (Installationspaket, Konzept Installation und Updates C.8). Nur Standardbibliothek.
# Liest den Beipackzettel fassungen/<fassung>.json im entpackten Paket. Werte dieser Installation kommen aus Umgebungsvariablen,
# nie aus Dateien des Pakets; Geheimnisse werden nie ausgegeben.
#
#   hilfe.py pruefen       <paket> <fassung>             sha256 aller Dateien des Zettels; Status „bereit“
#   hilfe.py zugangsdaten  <paket> <fassung> <ziel.json>  Zugangsdaten mit den Standardnamen und IDs der Workflows (leer bis auf interne Dienste)
#   hilfe.py workflows     <paket> <fassung> <ziel-dir>   Workflows mit ersetzten Platzhaltern + <ziel-dir>/../aktiv.txt (IDs mit Standard an)
#   hilfe.py einstellungen <paket> <fassung> <ziel.sql>   Einstellungen, Firma und Web-App-Dateien als SQL (eine Transaktion)
import hashlib, json, os, sys


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


def pruefen(paket, fassung):
    z = zettel(paket, fassung)
    if z.get('status') != 'bereit':
        raise SystemExit('Fassung %s ist nicht „bereit“ (Status %s)' % (fassung, z.get('status')))
    fehler = [d for d, s in dateien(z) if not os.path.isfile(os.path.join(paket, d)) or sha256(os.path.join(paket, d)) != s]
    if fehler:
        raise SystemExit('Prüfsumme falsch oder Datei fehlt (%d): %s' % (len(fehler), ', '.join(fehler[:5])))
    if z.get('migrationen'):
        raise SystemExit('Diese Fassung enthält Migrationen; das Installationsskript kennt nur Grundstand-Fassungen ohne Migrationen.')
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
        # Vorbelegt ohne Wert (Handgriff 1 nach der Installation): Kopfzeilen-Name, Wert trägt der Installierende ein
        ('httpHeaderAuth', 'n8n API'): {'name': 'X-N8N-API-KEY', 'value': ''},
        ('httpHeaderAuth', 'GitHub'): {'name': 'Authorization', 'value': ''},
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
        'n8n_oeffentlich': 'https://' + e['N8N_HOST'],
        'chat_server_name': e['CHAT_HOST'],
        'chat_admin_adresse': 'http://synapse:8008',
        'webapp_repo': e['UPDATE_QUELLE'],
        'update_quelle': e['UPDATE_QUELLE'],
        'ki_credential_id': ids.get('KI-Zugang (Anthropic)', ''),
        'systemnachrichten_credential_id': ids.get('Systemnachrichten – Versand (SMTP)', ''),
        'papierkram_credential_id': ids.get('Papierkram API', ''),
    }
    sql = ['BEGIN;']
    for k, v in werte.items():
        sql.append("INSERT INTO public.ally_einstellungen (schluessel, wert, geaendert_am, geaendert_von) VALUES (%s, %s, now(), 'Installation') "
                   "ON CONFLICT (schluessel) DO UPDATE SET wert = EXCLUDED.wert, geaendert_am = now(), geaendert_von = 'Installation';" % (q(k), q(v)))
    sql.append("INSERT INTO public.ally_firma (id, name) VALUES (1, %s);" % q(e['FIRMA']))
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


if __name__ == '__main__':
    if len(sys.argv) < 4:
        raise SystemExit('Aufruf: hilfe.py pruefen|zugangsdaten|workflows|einstellungen <paket> <fassung> [ziel]')
    befehl, paket, fassung = sys.argv[1:4]
    {'pruefen': lambda: pruefen(paket, fassung), 'zugangsdaten': lambda: zugangsdaten(paket, fassung, sys.argv[4]),
     'workflows': lambda: workflows(paket, fassung, sys.argv[4]), 'einstellungen': lambda: einstellungen(paket, fassung, sys.argv[4])}[befehl]()
