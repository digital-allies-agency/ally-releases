#!/usr/bin/env python3
# Ally – Hilfsschritte des Update-Programms (server/installation/update/ally-update.sh, Migration 203). Nur Standardbibliothek. Liest den Beipackzettel
# fassungen/<fassung>.json eines entpackten Pakets und fassungen/freigegeben.json; gibt nie Geheimnisse aus. Bei einem Fehler: Meldung auf stderr, Rückgabe 1.
#
#   neueste      <freigegeben.json>                                  neueste freigegebene Fassung: fassung|commit|datum|neu
#   pruefen      <paket> <fassung> <commit> <installiert>            Freigabe und Reihenfolge prüfen; Ausgabe: n8n-Mindestversion
#   migrationen  <paket> <fassung>                                   je Migration nr|datei|rueckbau|waechter|waechter_nachher (sha256 von Datei, Rückbau, Erwartung geprüft)
#   auswahl      <paket> <fassung> <installierter-zettel|-> <alle-dir> <ziel-dir> <aktiv.json>
#                                                                    zu importierende Workflows nach <ziel-dir>; Ausgabe Zeilen an=<ids>, aus=<ids>, neu=<ids>, import=<n>, entfernt=<ids>
#   zettel_migrationen <zettel>                                      Nummern der Migrationen eines Beipackzettels (je Zeile)
#   fassung_schreiben <zettel> <commit> <ziel>                       fassung.json mit eingespielt_commit schreiben (atomar)
#   fassung_vertraut  <fassung.json> <nummer> <commit>               Rückgabe 0, wenn fassung.json zu ally_fassung passt
#   version_ok   <ist> <mindestens>                                  Rückgabe 0, wenn ist >= mindestens (z. B. 2.42.7)
#   webapp_sql   <paket> <fassung> <repo> <commit>                   SQL (stdout) für ally_webapp_dateien aus dem Paket (wie ALLY 42 mit ref = Commit: Plausibilität, FNV-Fassung)
#   webapp_zurueck <webapp.json>                                     SQL (stdout), das die gesicherten Zeilen von ally_webapp_dateien wiederherstellt
#   zurueck_aktiv <aktiv.json> <ids>                                 Ausgabe an=<ids>, aus=<ids>: Schaltzustand vor dem Update für diese Workflows
import hashlib, json, os, re, sys

NUMMER = re.compile(r'^[0-9]{1,3}[.][0-9]{1,3}$')
COMMIT = re.compile(r'^[0-9a-f]{7,40}$')
WF_ID = re.compile(r'^[A-Za-z0-9]{1,40}$')


def fehler(t):
    sys.stderr.write(t + '\n')
    raise SystemExit(1)


def nummer(n):
    if not isinstance(n, str) or not NUMMER.match(n):
        return None
    a, b = n.split('.')
    return (int(a), int(b))


def sha256(p):
    h = hashlib.sha256()
    with open(p, 'rb') as f:
        for b in iter(lambda: f.read(1 << 20), b''):
            h.update(b)
    return h.hexdigest()


def lies(p):
    with open(p, encoding='utf-8') as f:
        return json.load(f)


def freigaben(p):
    try:
        f = lies(p).get('fassungen')
    except (OSError, ValueError, AttributeError):
        fehler('Liste der freigegebenen Fassungen nicht lesbar.')
    if not isinstance(f, list):
        fehler('Liste der freigegebenen Fassungen nicht lesbar.')
    return [x for x in f if isinstance(x, dict) and nummer(x.get('fassung')) and COMMIT.match(str(x.get('commit') or ''))]


def neueste(datei):
    f = freigaben(datei)
    if not f:
        fehler('In der Liste der freigegebenen Fassungen steht keine Fassung.')
    # höchste Nummer; bei gleicher Nummer der letzte Eintrag (Neufreigabe)
    best = max(enumerate(f), key=lambda e: (nummer(e[1]['fassung']), e[0]))[1]
    datum = str(best.get('datum') or '')
    datum = datum if re.match(r'^[0-9]{4}-[0-9]{2}-[0-9]{2}$', datum) else ''
    neu = re.sub(r'[\x00-\x1f\x7f|]+', ' ', str(best.get('neu') or '')).strip()[:1000]
    print('%s|%s|%s|%s' % (best['fassung'], best['commit'], datum, neu))


def zettel(paket, fassung):
    p = os.path.join(paket, 'fassungen', fassung + '.json')
    if not os.path.isfile(p):
        fehler('Beipackzettel der Fassung %s fehlt im Paket.' % fassung)
    z = lies(p)
    if z.get('fassung') != fassung:
        fehler('Beipackzettel passt nicht zur Fassung %s.' % fassung)
    return z


def pruefen(paket, fassung, commit, installiert):
    f = freigaben(os.path.join(paket, 'fassungen', 'freigegeben.json'))
    if not any(x['fassung'] == fassung and x['commit'] == commit for x in f):
        fehler('Fassung %s (Commit %s) ist in diesem Paket nicht freigegeben.' % (fassung, commit[:7]))
    # genau der Eintrag, der bei der Suche gelesen wurde, ist der neueste im geladenen Paket
    best = max(enumerate(f), key=lambda e: (nummer(e[1]['fassung']), e[0]))[1]
    if (best['fassung'], best['commit']) != (fassung, commit):
        fehler('Im Paket ist nicht Fassung %s (Commit %s) die neueste Freigabe, sondern %s (%s).' % (fassung, commit[:7], best['fassung'], best['commit'][:7]))
    z = zettel(paket, fassung)
    # Programme auf dem Server (Zettel „installation“; hilfe.py pruefen prüft sie nicht): nach dem Update ruft das Programm ihre Einrichtung auf.
    # hilfe.py des Pakets läuft nur, wenn es dort mit sha256 steht.
    if 'server/installation/hilfe.py' not in [d.get('datei') for d in z.get('installation', [])]:
        fehler('server/installation/hilfe.py steht nicht im Beipackzettel (installation).')
    for d in z.get('installation', []):
        p = os.path.join(paket, d.get('datei') or '')
        if not d.get('datei') or not os.path.isfile(p) or sha256(p) != d.get('sha256'):
            fehler('Datei %s fehlt im Paket oder Prüfsumme falsch.' % (d.get('datei') or '?'))
    if z.get('status') != 'bereit':
        fehler('Fassung %s ist nicht zum Einspielen freigegeben (Status %s).' % (fassung, z.get('status')))
    zu, ist, vor = nummer(fassung), nummer(installiert), nummer(z.get('vorherige') or '')
    if ist and zu < ist:
        fehler('Eingespielt ist schon Fassung %s; Fassung %s ist älter.' % (installiert, fassung))
    # Ein Paket enthält nur die Migrationen seit der vorherigen Fassung: wer weiter zurückliegt, braucht erst die Fassungen dazwischen.
    if ist and zu != ist and vor and ist < vor:
        fehler('Fassung %s setzt Fassung %s voraus; eingespielt ist %s. Bitte den Anbieter informieren.' % (fassung, z.get('vorherige'), installiert))
    if ist and zu != ist and not vor:
        fehler('Fassung %s ist eine Grundfassung für Neu-Installationen und kein Update.' % fassung)
    print(str(z.get('n8n_mindestversion') or ''))


def migrationen(paket, fassung):
    for m in zettel(paket, fassung).get('migrationen', []):
        e = m.get('erwartung') or {}
        for datei, soll in ((m.get('datei'), m.get('sha256')), (m.get('rueckbau'), m.get('rueckbau_sha256')), (e.get('werte'), e.get('werte_sha256')),
                            (e.get('waechter_abfrage'), e.get('waechter_sha256'))):
            if not datei or not soll or not os.path.isfile(os.path.join(paket, datei)) or sha256(os.path.join(paket, datei)) != soll:
                fehler('Migration %s: Datei fehlt oder Prüfsumme falsch (%s).' % (m.get('nr'), datei or 'Rückbau oder Erwartung'))
        nach = lies(os.path.join(paket, e['werte'])).get('waechter_nachher') or ''
        print('%s|%s|%s|%s|%s' % (m['nr'], m['datei'], m['rueckbau'], e['waechter_abfrage'], str(nach).replace('\n', ' ')))


def auswahl(paket, fassung, alt, alle, ziel, aktiv_datei):
    z = zettel(paket, fassung)
    neu_sha = {w['id']: w['sha256'] for w in z['workflows']}
    alt_sha = {}
    if alt != '-' and os.path.isfile(alt):
        try:
            alt_sha = {w['id']: w['sha256'] for w in lies(alt).get('workflows', [])}
        except (ValueError, KeyError, TypeError):
            alt_sha = {}
    vorher = {x['id']: x for x in lies(aktiv_datei) or []}
    os.makedirs(ziel, exist_ok=True)
    an, aus, neu, n = [], [], [], 0
    for w in z['workflows']:
        i = w['id']
        if not WF_ID.match(i):
            fehler('Ungültige Workflow-ID im Beipackzettel.')
        # gleich wie in der eingespielten Fassung und in n8n vorhanden: nicht anfassen
        if alt_sha.get(i) == neu_sha[i] and i in vorher:
            continue
        q = os.path.join(alle, os.path.basename(w['datei']))
        if not os.path.isfile(q):
            fehler('Workflow %s fehlt im Paket.' % w['datei'])
        with open(q, 'rb') as a, open(os.path.join(ziel, os.path.basename(w['datei'])), 'wb') as b:
            b.write(a.read())
        n += 1
        if i in vorher:
            (an if vorher[i].get('active') is True else aus).append(i)   # Schaltzustand dieser Installation bleibt
        else:
            neu.append(i)
            (an if w.get('aktiv_standard') is True else aus).append(i)
    # nicht mehr in der Fassung (nur was die eingespielte Fassung geliefert hat und in n8n noch an ist): ausschalten
    entfernt = [i for i in alt_sha if i not in neu_sha and WF_ID.match(i) and vorher.get(i, {}).get('active') is True]
    aus += entfernt
    print('an=' + ','.join(an))
    print('aus=' + ','.join(aus))
    print('neu=' + ','.join(neu))
    print('entfernt=' + ','.join(entfernt))
    print('import=%d' % n)


def zettel_migrationen(datei):
    # Nummern der Migrationen im Beipackzettel dieser Installation (/opt/ally/fassung.json): gelten als eingespielt
    try:
        for m in lies(datei).get('migrationen', []):
            if re.match(r'^[0-9]{1,4}[a-z]?$', str(m.get('nr', ''))):
                print(m['nr'])
    except (OSError, ValueError, AttributeError):
        pass


def fassung_schreiben(zettel_datei, commit, ziel):
    # /opt/ally/fassung.json = Beipackzettel der eingespielten Fassung mit dem Freigabe-Commit (eingespielt_commit); erst nach dem gespeicherten Ende schreiben
    z = lies(zettel_datei)
    if not COMMIT.match(commit or ''):
        fehler('Commit ungültig.')
    z['eingespielt_commit'] = commit
    neu = ziel + '.neu'
    with open(neu, 'w', encoding='utf-8') as f:
        json.dump(z, f, ensure_ascii=False)
    os.chmod(neu, 0o644)
    os.replace(neu, ziel)


def fassung_vertraut(datei, nummer_db, commit_db):
    # Rückgabe 0 nur, wenn fassung.json zur Datenbank passt (Nummer = ally_fassung_aktuell, eingespielt_commit = git_commit); sonst wird geprobt
    try:
        z = lies(datei)
    except (OSError, ValueError):
        raise SystemExit(1)
    c, d = str(z.get('eingespielt_commit') or ''), commit_db or ''
    n = min(len(c), len(d))
    if z.get('fassung') != nummer_db or n < 7 or c[:n] != d[:n]:
        raise SystemExit(1)


def version_ok(ist, mind):
    t = lambda v: tuple(int(x) for x in re.findall(r'[0-9]+', v)[:3])
    if not mind:
        return
    if not re.match(r'^[0-9]+\.[0-9]+\.[0-9]+', ist or ''):
        fehler('n8n-Version nicht lesbar.')
    if t(ist) < t(mind):
        fehler('Fassung braucht n8n %s, auf dem Server läuft %s. Bitte den Anbieter informieren.' % (mind, ist))


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
    return "'" + str(s).replace("'", "''") + "'"


def webapp_sql(paket, fassung, repo, ref):
    z = zettel(paket, fassung)
    sql = ['BEGIN;']
    for w in z['webapp']:
        p = os.path.join(paket, w['datei'])
        if not os.path.isfile(p) or sha256(p) != w['sha256']:
            fehler('Web-App-Datei %s fehlt oder Prüfsumme falsch.' % w['datei'])
        t = open(p, encoding='utf-8').read()
        name = os.path.basename(w['datei'])
        if (name == 'app.js' and len(t) <= 10000) or len(t) <= 1000 or t.lstrip().startswith('<'):
            fehler('Web-App-Datei %s unplausibel.' % name)
        sql.append("INSERT INTO public.ally_webapp_dateien (name, inhalt, fassung, bytes, quelle, geaendert_am) VALUES (%s, %s, %s, %d, %s, now()) "
                   "ON CONFLICT (name) DO UPDATE SET inhalt = EXCLUDED.inhalt, fassung = EXCLUDED.fassung, bytes = EXCLUDED.bytes, quelle = EXCLUDED.quelle, geaendert_am = now();"
                   % (q(name), q(t), q(fnv(t)), len(t.encode('utf-8')), q(repo + '/' + os.path.dirname(w['datei']) + '@' + ref)))
    sql.append('COMMIT;')
    sys.stdout.write('\n'.join(sql) + '\n')


def webapp_zurueck(datei):
    zeilen = lies(datei) or []
    sql = ['BEGIN;']
    for r in zeilen:
        sql.append("INSERT INTO public.ally_webapp_dateien (name, inhalt, fassung, bytes, quelle, geaendert_am) VALUES (%s, %s, %s, %d, %s, %s) "
                   "ON CONFLICT (name) DO UPDATE SET inhalt = EXCLUDED.inhalt, fassung = EXCLUDED.fassung, bytes = EXCLUDED.bytes, quelle = EXCLUDED.quelle, geaendert_am = EXCLUDED.geaendert_am;"
                   % (q(r['name']), q(r['inhalt']), q(r['fassung']), int(r['bytes']), 'NULL' if r.get('quelle') is None else q(r['quelle']), q(r['geaendert_am'])))
    namen = [q(r['name']) for r in zeilen]
    sql.append('DELETE FROM public.ally_webapp_dateien WHERE name NOT IN (%s);' % (', '.join(namen) if namen else "''"))
    sql.append('COMMIT;')
    sys.stdout.write('\n'.join(sql) + '\n')


def zurueck_aktiv(datei, ids):
    vorher = {x['id']: x for x in lies(datei) or []}
    an = [i for i in ids.split(',') if i and vorher.get(i, {}).get('active') is True]
    aus = [i for i in ids.split(',') if i and i not in an]
    print('an=' + ','.join(an))
    print('aus=' + ','.join(aus))


if __name__ == '__main__':
    a = sys.argv[1:]
    befehle = {'neueste': (1, lambda: neueste(a[1])), 'pruefen': (4, lambda: pruefen(*a[1:5])), 'migrationen': (2, lambda: migrationen(*a[1:3])),
               'auswahl': (6, lambda: auswahl(*a[1:7])), 'version_ok': (2, lambda: version_ok(*a[1:3])), 'webapp_sql': (4, lambda: webapp_sql(*a[1:5])),
               'webapp_zurueck': (1, lambda: webapp_zurueck(a[1])), 'zettel_migrationen': (1, lambda: zettel_migrationen(a[1])),
               'fassung_schreiben': (3, lambda: fassung_schreiben(*a[1:4])), 'fassung_vertraut': (3, lambda: fassung_vertraut(*a[1:4])), 'zurueck_aktiv': (2, lambda: zurueck_aktiv(*a[1:3]))}
    if not a or a[0] not in befehle or len(a) - 1 != befehle[a[0]][0]:
        fehler('Aufruf: ally-update-hilfe.py ' + '|'.join(befehle))
    befehle[a[0]][1]()
