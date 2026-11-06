-- Migration 211 (Updates-Seite, Stefan 06.11.2026): Seite Einstellungen › System › Updates nach Stefans freigegebenem Bild.
-- a) ally_update_ui liefert die Daten der neuen Seite: installiert (eingespielt am), neu verfügbar mit Neuerungen und Frist, zuletzt gesucht, laufendes oder
--    vorgemerktes Update mit Fortschritt in fünf Abschnitten (ally_update_phasen), Hinweis nur, wenn sich das Update-Programm seit über 10 Minuten nicht meldet,
--    Verlauf mit Einzelheiten in einer Zeile (ohne Pfade auf dem Server).
-- b) „Update suchen“ sucht sofort über n8n (Fehler Nr. 53): ally_update_ui_aktion gibt die Quelle an ALLY 20, das Ergebnis speichert ally_update_suche_ende.
-- c) Das Update-Programm prüft vorgemerkte Aufträge jede Minute; beim Start eines Updates merkt die Datenbank den Stand vorher (ally_update_host_plan).
-- Wächter vorher: Funktionen wie nach 210, keine Teile von 211. Läuft als Ganzes in der Transaktion des Aufrufs (psql -1). Rückbau: rueckbau211.sql.
DO $m$
BEGIN
  IF (SELECT md5(string_agg(p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')|' || pg_get_function_result(p.oid) || '|' || md5(p.prosrc), E'\n' ORDER BY p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')' COLLATE "C")) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname::text = 'public' COLLATE "C" AND p.proname::text COLLATE "C" = ANY (ARRAY['ally_update_ui', 'ally_update_ui_aktion', 'ally_update_host_plan', 'ally_update_zeit', 'ally_update_phasen', 'ally_update_suche_ende'])) IS NOT DISTINCT FROM 'f96bc1ec68a6e0e95f790e26ed31c734' THEN RAISE EXCEPTION 'Migration 211: schon eingespielt, nichts geändert'; END IF;
  IF (SELECT md5(string_agg(p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')|' || pg_get_function_result(p.oid) || '|' || md5(p.prosrc), E'\n' ORDER BY p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')' COLLATE "C")) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname::text = 'public' COLLATE "C" AND p.proname::text COLLATE "C" = ANY (ARRAY['ally_update_ui', 'ally_update_ui_aktion', 'ally_update_host_plan', 'ally_update_zeit', 'ally_update_phasen', 'ally_update_suche_ende'])) IS DISTINCT FROM '03e9aa88d94f97485889b72c9034d7fb' THEN RAISE EXCEPTION 'Migration 211: Funktionen nicht im erwarteten Stand, nichts geändert'; END IF;
END $m$;
CREATE OR REPLACE FUNCTION public.ally_update_zeit(p_zeit timestamp with time zone, p_art text)
 RETURNS text
 LANGUAGE sql
 STABLE
AS $function$
  -- Migration 211 (Updates-Seite nach Stefans Bild): Zeit für die Seite Updates (deutsche Zeit, ohne führende Nullen bei Tag und Monat):
  -- datum_zeit „6.11.2026, 15:01“, uhr „17:10“ (heute) bzw. „5.11., 17:10“ (anderer Tag), datum „6.12.2026“
  SELECT CASE WHEN p_zeit IS NULL THEN NULL
    WHEN p_art = 'uhr' THEN CASE WHEN (p_zeit AT TIME ZONE 'Europe/Berlin')::date = (now() AT TIME ZONE 'Europe/Berlin')::date
                                 THEN to_char(p_zeit AT TIME ZONE 'Europe/Berlin', 'HH24:MI') ELSE to_char(p_zeit AT TIME ZONE 'Europe/Berlin', 'FMDD.FMMM., HH24:MI') END
    WHEN p_art = 'datum' THEN to_char(p_zeit AT TIME ZONE 'Europe/Berlin', 'FMDD.FMMM.YYYY')
    ELSE to_char(p_zeit AT TIME ZONE 'Europe/Berlin', 'FMDD.FMMM.YYYY, HH24:MI') END
$function$;
CREATE OR REPLACE FUNCTION public.ally_update_phasen(p_schritte jsonb, p_status text)
 RETURNS jsonb
 LANGUAGE sql
 IMMUTABLE
AS $function$
  -- Migration 211 (Updates-Seite, Bild 2): Fortschritt eines Updates aus den Schritten des Update-Programms (ally_updates.schritte) in fünf Abschnitten:
  -- Sicherung (platz, laden, pruefen, sichern), Datenbank (migration …, migrationen), Abläufe (workflows, erweiterungen, neustart), Oberfläche (webapp),
  -- Prüfung (Abschluss). Stand je Abschnitt: ok, aktiv, fehler, offen; fortschritt in Prozent (je erledigtem Abschnitt 20, der laufende 10).
  -- p_status vorgemerkt: alle offen, 0 %.
  WITH s AS (SELECT coalesce(jsonb_agg(x), '[]'::jsonb) AS a FROM jsonb_array_elements(CASE WHEN jsonb_typeof(p_schritte) = 'array' THEN p_schritte ELSE '[]'::jsonb END) x
             WHERE jsonb_typeof(x) = 'object'),
  f AS (SELECT
    EXISTS (SELECT 1 FROM jsonb_array_elements(s.a) x WHERE x->>'schritt' = 'sichern' AND x->>'ergebnis' = 'ok') AS e1,
    EXISTS (SELECT 1 FROM jsonb_array_elements(s.a) x WHERE x->>'schritt' = 'migrationen' AND x->>'ergebnis' = 'ok') AS e2,
    EXISTS (SELECT 1 FROM jsonb_array_elements(s.a) x WHERE x->>'schritt' = 'neustart' AND x->>'ergebnis' = 'ok') AS e3,
    EXISTS (SELECT 1 FROM jsonb_array_elements(s.a) x WHERE x->>'schritt' = 'webapp' AND x->>'ergebnis' = 'ok') AS e4,
    EXISTS (SELECT 1 FROM jsonb_array_elements(s.a) x WHERE x->>'ergebnis' = 'fehler') AS fe
    FROM s),
  p AS (SELECT n, name, CASE n WHEN 1 THEN f.e1 WHEN 2 THEN f.e2 WHEN 3 THEN f.e3 WHEN 4 THEN f.e4 ELSE p_status = 'ok' END AS fertig,
          CASE n WHEN 1 THEN true WHEN 2 THEN f.e1 WHEN 3 THEN f.e2 WHEN 4 THEN f.e3 ELSE f.e4 END AS begonnen, f.fe
        FROM f CROSS JOIN (VALUES (1, 'Sicherung'), (2, 'Datenbank'), (3, 'Abläufe'), (4, 'Oberfläche'), (5, 'Prüfung')) v(n, name))
  SELECT jsonb_build_object(
    'schritte', (SELECT jsonb_agg(jsonb_build_object('name', p.name, 'stand',
        CASE WHEN p_status = 'vorgemerkt' THEN 'offen' WHEN p.fertig THEN 'ok' WHEN p.begonnen AND p.fe THEN 'fehler' WHEN p.begonnen THEN 'aktiv' ELSE 'offen' END) ORDER BY p.n) FROM p),
    'fortschritt', CASE WHEN p_status = 'vorgemerkt' THEN 0 ELSE least(100, (SELECT 20 * count(*) FILTER (WHERE p.fertig) + 10 * count(*) FILTER (WHERE p.begonnen AND NOT p.fertig AND NOT p.fe) FROM p))::integer END)
$function$;
CREATE OR REPLACE FUNCTION public.ally_update_suche_ende(p_token text, p_sha text, p_liste text, p_fehler text)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE
  s record; j jsonb; e record; fehler text; r text; m text;
BEGIN
  -- Migration 211 (Fehler Nr. 53, Entscheidung Stefan 03.11.2026: „Update suchen“ sucht sofort über n8n, eingespielt wird weiter über das Programm auf dem Server):
  -- Ergebnis der Suche aus ALLY 20 (Knöpfe „Update suchen“: Stand des Zweigs main des Auslieferungs-Repos und fassungen/freigegeben.json zu diesem Stand,
  -- gelesen mit dem GitHub-Zugang in n8n). Nur Admin und Superadmin. Neueste Fassung wie das Update-Programm (höchste Nummer, bei gleicher Nummer der letzte
  -- Eintrag), gespeichert über ally_update_host_verfuegbar (Frist, Benachrichtigung „Update verfügbar“); Meldung auf der Seite. Ergebnis wie ally_update_host_verfuegbar.
  SELECT * INTO s FROM ally_ui_sitzung(p_token);
  IF NOT FOUND OR s.muss_pw_setzen THEN RETURN 'keine Sitzung'; END IF;
  IF NOT coalesce(ally_hat_recht(s.person, 'admin'), false) AND NOT coalesce(ally_hat_recht(s.person, 'superadmin'), false) THEN RETURN 'kein Recht'; END IF;
  IF nullif(btrim(coalesce(p_fehler, '')), '') IS NOT NULL OR coalesce(p_sha, '') !~ '^[0-9a-f]{40}$' THEN
    fehler := 'Das Auslieferungs-Repo ist nicht erreichbar (GitHub-Zugang oder Netz prüfen).';
  ELSE
    BEGIN j := p_liste::jsonb; EXCEPTION WHEN OTHERS THEN j := NULL; END;
    SELECT x.f, x.c, x.d, x.n INTO e FROM (
      SELECT v->>'fassung' AS f, v->>'commit' AS c, CASE WHEN v->>'datum' ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN v->>'datum' END AS d,
        nullif(left(btrim(regexp_replace(coalesce(v->>'neu', ''), '[[:cntrl:][:space:]|]+', ' ', 'g')), 1000), '') AS n, i
      FROM jsonb_array_elements(CASE WHEN jsonb_typeof(j->'fassungen') = 'array' THEN j->'fassungen' ELSE '[]'::jsonb END) WITH ORDINALITY a(v, i)
      WHERE jsonb_typeof(v) = 'object' AND coalesce(v->>'fassung', '') ~ '^[0-9]{1,3}[.][0-9]{1,3}$' AND coalesce(v->>'commit', '') ~ '^[0-9a-f]{7,40}$') x
    ORDER BY split_part(x.f, '.', 1)::integer DESC, split_part(x.f, '.', 2)::integer DESC, x.i DESC LIMIT 1;
    IF NOT FOUND THEN fehler := CASE WHEN j IS NULL THEN 'Die Liste der freigegebenen Fassungen ist nicht lesbar.' ELSE 'In der Liste der freigegebenen Fassungen steht keine Fassung.' END; END IF;
  END IF;
  IF fehler IS NOT NULL THEN
    r := ally_update_host_verfuegbar(NULL, NULL, NULL, NULL, NULL, fehler);
    m := 'Die Suche nach Updates ist fehlgeschlagen: ' || fehler;
  ELSE
    r := ally_update_host_verfuegbar(e.f, e.c, e.d, e.n, p_sha, NULL);
    m := CASE r WHEN 'ok|offen' THEN 'Fassung ' || e.f || ' ist verfügbar.' WHEN 'ok|aktuell' THEN 'Keine neuere Fassung. Eingespielt ist Fassung ' || coalesce(ally_fassung_aktuell(), e.f) || '.'
                ELSE 'Die Suche nach Updates ist fehlgeschlagen: ' || r END;
  END IF;
  -- eine noch vorgemerkte Suche für das Programm auf dem Server ist damit erledigt
  UPDATE ally_update_stand x SET auftrag = NULL, auftrag_art = NULL, auftrag_am = NULL, auftrag_von = NULL WHERE x.id = 1 AND x.auftrag COLLATE "C" = 'suchen';
  PERFORM ally_web_meldung(p_token, m, CASE WHEN fehler IS NULL AND r LIKE 'ok|%' THEN 'ok' ELSE 'fehler' END, NULL);
  RETURN r;
END $function$;
CREATE OR REPLACE FUNCTION public.ally_update_ui(p_token text)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
  s record;
  sa boolean; adm boolean;
  z ally_update_stand := ally_update_stand_zeile();
  f ally_fassung := ally_update_installiert();
  l ally_updates;
  offen boolean := ally_update_offen();
  fr timestamp with time zone := ally_update_frist();
  dauer integer;
BEGIN
  -- Migration 203 (Update-Knopf, Entscheidung Stefan 31.10.2026: nur Admin und Superadmin, fest): Daten der Seite Einstellungen › System › Updates
  -- (ALLY 23 „Update laden“). Für alle anderen und ohne Sitzung NULL. darf = Knopf „Jetzt aktualisieren“ erlaubt (ally_darf_aktualisieren).
  -- Migration 211 (Stefan: neue Seite nach freigegebenem Bild): installiert (Fassung, eingespielt am), verfügbar (Fassung, Neuerungen, Stand nur bei gleicher Nummer),
  -- Frist (Datum), zuletzt gesucht (Uhrzeit), lauf = laufendes oder vorgemerktes Update mit Abschnitten und Fortschritt (ally_update_phasen), Person und Beginn,
  -- dauer_meist (übliche Dauer aus den letzten Läufen), programm_still = Update-Programm meldet sich seit über 10 Minuten nicht (nur dann ein Hinweis),
  -- abgebrochen (Sperre), Verlauf der letzten 30 Läufe mit Stand bei gleicher Nummer (von_commit seit Migration 211 beim Start gemerkt) und Einzelheiten in einer Zeile (ohne Pfade auf dem Server);
  -- Rohtext der Fehler (detail) nur für Superadmins, ohne Serverpfade (…).
  SELECT * INTO s FROM ally_ui_sitzung(p_token);
  IF NOT FOUND OR s.muss_pw_setzen THEN RETURN NULL; END IF;
  sa := coalesce(ally_hat_recht(s.person, 'superadmin'), false);
  adm := coalesce(ally_hat_recht(s.person, 'admin'), false);
  IF NOT sa AND NOT adm THEN RETURN NULL; END IF;
  SELECT * INTO l FROM ally_updates u WHERE u.status COLLATE "C" = 'laeuft' ORDER BY u.id DESC LIMIT 1;
  SELECT round(avg(extract(epoch FROM x.beendet_am - x.gestartet_am)))::integer INTO dauer
  FROM (SELECT * FROM ally_updates y WHERE y.status COLLATE "C" = 'ok' AND y.beendet_am IS NOT NULL ORDER BY y.id DESC LIMIT 5) x;
  RETURN jsonb_build_object('ok', true, 'sa', sa, 'admin', adm, 'darf', coalesce(ally_darf_aktualisieren(s.person), false),
    'installiert', CASE WHEN f.nummer IS NOT NULL THEN jsonb_build_object('nummer', f.nummer, 'stand', left(f.git_commit, 7), 'am', ally_update_zeit(f.eingespielt_am, 'datum_zeit')) END,
    'offen', offen,
    'verfuegbar', CASE WHEN offen AND z.verfuegbar IS NOT NULL THEN jsonb_build_object('nummer', z.verfuegbar, 'commit', z.verfuegbar_commit, 'neu', z.verfuegbar_neu,
      -- gleiche Nummer, anderer Stand (Neufreigabe): Stand kurz in Klammern
      'stand', CASE WHEN z.verfuegbar COLLATE "C" = f.nummer THEN left(z.verfuegbar_commit, 7) END) END,
    'frist', CASE WHEN offen AND fr IS NOT NULL THEN jsonb_build_object('bis', ally_update_zeit(fr, 'datum'), 'abgelaufen', fr <= now()) END,
    'gesucht', ally_update_zeit(z.gesucht_am, 'uhr'), 'such_fehler', z.such_fehler,
    'lauf', CASE WHEN l.id IS NOT NULL THEN jsonb_build_object('art', 'laeuft', 'zu', l.zu_fassung, 'seit', ally_update_zeit(l.gestartet_am, 'uhr'),
                   'person', (SELECT p.name FROM ally_personen p WHERE p.matrix_user_id = l.person)) || ally_update_phasen(l.schritte, 'laeuft')
                 WHEN z.auftrag COLLATE "C" = 'aktualisieren' THEN jsonb_build_object('art', 'vorgemerkt', 'zu', z.verfuegbar, 'seit', ally_update_zeit(z.auftrag_am, 'uhr'),
                   'person', (SELECT p.name FROM ally_personen p WHERE p.matrix_user_id = z.auftrag_von)) || ally_update_phasen('[]'::jsonb, 'vorgemerkt') END,
    'dauer_meist', dauer,
    'programm_still', CASE WHEN z.programm_am IS NOT NULL AND z.programm_am < now() - interval '10 minutes' THEN ally_update_zeit(z.programm_am, 'uhr') END,
    'abgebrochen', CASE WHEN z.abgebrochen_lauf IS NOT NULL THEN jsonb_build_object('lauf', z.abgebrochen_lauf, 'stand', z.abgebrochen_stand) END,
    'verlauf', (SELECT coalesce(jsonb_agg(jsonb_build_object('id', v.id, 'zeit', ally_update_zeit(v.gestartet_am, 'datum_zeit'), 'von', v.von_fassung, 'zu', v.zu_fassung,
        'von_stand', CASE WHEN v.von_fassung COLLATE "C" = v.zu_fassung THEN left(v.sicherungen->>'von_commit', 7) END,
        'zu_stand', CASE WHEN v.von_fassung COLLATE "C" = v.zu_fassung THEN left(v.sicherungen->>'zu_commit', 7) END,
        'person', coalesce(p.name, v.person), 'status', v.status,
        'dauer', CASE WHEN v.beendet_am IS NOT NULL THEN greatest(0, round(extract(epoch FROM v.beendet_am - v.gestartet_am)))::bigint END,
        'einzelheiten', CASE WHEN v.status COLLATE "C" = 'ok' THEN concat_ws(' · ',
            (SELECT CASE WHEN count(*) = 1 THEN 'Datenbank: 1 Änderung eingespielt' WHEN count(*) > 1 THEN 'Datenbank: ' || count(*) || ' Änderungen eingespielt' ELSE 'Datenbank: keine Änderung' END
             FROM jsonb_array_elements(v.schritte) x WHERE x->>'schritt' LIKE 'migration %' AND x->>'ergebnis' = 'ok'),
            (SELECT 'Abläufe: ' || substring(x->>'text' FROM '^([0-9]+) importiert') || ' aktualisiert' FROM jsonb_array_elements(v.schritte) x
             WHERE x->>'schritt' = 'workflows' AND x->>'ergebnis' = 'ok' AND x->>'text' ~ '^[0-9]+ importiert' LIMIT 1),
            CASE WHEN EXISTS (SELECT 1 FROM jsonb_array_elements(v.schritte) x WHERE x->>'schritt' = 'webapp' AND x->>'ergebnis' = 'ok') THEN 'Oberfläche aktualisiert' END,
            CASE WHEN EXISTS (SELECT 1 FROM jsonb_array_elements(v.schritte) x WHERE x->>'schritt' = 'sichern' AND x->>'ergebnis' = 'ok') THEN 'Sicherung vorher angelegt (Nr. ' || v.id || ')' END)
          ELSE concat_ws(' · ', v.ergebnis, CASE WHEN sa THEN 'Einzelheiten: ' || regexp_replace(v.sicherungen->>'detail', '(^|[[:space:]:=("''])/[^[:space:]]+', '\1…', 'g') END) END)
        ORDER BY v.gestartet_am DESC, v.id DESC), '[]'::jsonb)
      FROM (SELECT x.* FROM ally_updates x WHERE x.status COLLATE "C" <> 'laeuft' ORDER BY x.gestartet_am DESC, x.id DESC LIMIT 30) v
      LEFT JOIN ally_personen p ON p.matrix_user_id = v.person));
END $function$;
CREATE OR REPLACE FUNCTION public.ally_update_ui_aktion(p_token text, p_csrf text, p_aktion text, p_daten jsonb, p_zustand jsonb, p_geheim jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
  d jsonb := CASE WHEN jsonb_typeof(p_daten) = 'object' THEN p_daten ELSE '{}'::jsonb END;
  s record; e jsonb;
  z ally_update_stand;
  fehler text := NULL; m text := NULL;
  aktiv boolean; laeuft boolean;
  hinweis text := '';
BEGIN
  -- Migration 203 (Update-Knopf, Entscheidung Stefan 31.10.2026): Aktionen der Seite Einstellungen › System › Updates (up_*). NULL bei allen anderen Aktionen und
  -- ohne Personen-Sitzung (ALLY 20 „Aktion ausführen“, Kette coalesce). Sitzung, Schutzwert und Passwort-Pflicht wie ally_sicherung_ui_aktion; setzt die Meldung selbst.
  -- Nur Admin und Superadmin (fest). up_suchen: Auftrag „Update suchen“ für das Update-Programm auf dem Server. up_jetzt: Auftrag „Jetzt aktualisieren“ für die
  -- angezeigte Fassung (fassung, commit aus der Seite; passt sie nicht mehr zur verfügbaren, wird nichts vorgemerkt). Das Programm übernimmt Aufträge alle 5 Minuten.
  -- Migration 211 (Updates-Seite, Stefan 06.11.2026): up_suchen sucht sofort über n8n (Fehler Nr. 53): weiter = update_suchen mit der Quelle (ALLY 20 liest den Stand bei GitHub und ruft
  -- ally_update_suche_ende; die Meldung setzt dann diese). Das Programm prüft Aufträge jede Minute; Hinweis erst nach 10 Minuten ohne Meldung.
  -- up_freigeben (nur Superadmin, der aktualisieren darf): Sperre nach einem abgebrochenen Update aufheben, wenn der Stand geprüft ist (abgebrochen_stand pruefen)
  -- oder wenn „zuruecksetzen“ hängt, weil sich das Programm seit über 30 Minuten nicht gemeldet hat.
  -- Art des Auftrags: update (hier). Vorgesehen für später (Pakete im Webinterface, Konzept folgt): modul_installieren, modul_entfernen mit derselben Sperre und demselben Rückweg.
  IF p_aktion IS NULL OR p_aktion !~ '^up_[a-z_]{1,30}$' THEN RETURN NULL; END IF;
  SELECT * INTO s FROM ally_ui_sitzung(p_token);
  IF NOT FOUND THEN RETURN NULL; END IF;
  IF coalesce(p_csrf, '') <> ally_ui_csrf(s.token_hash) THEN
    PERFORM ally_web_meldung(p_token, 'Die Anfrage wurde abgelehnt. Bitte die Seite neu laden.', 'fehler', NULL);
    RETURN jsonb_build_object('ok', false, 'angemeldet', true, 'ungueltig', true);
  END IF;
  IF s.muss_pw_setzen THEN RETURN jsonb_build_object('ok', false, 'angemeldet', true, 'muss_pw_setzen', true); END IF;
  IF jsonb_typeof(p_zustand->'z') = 'array' THEN
    FOR e IN SELECT x FROM jsonb_array_elements(p_zustand->'z') x LIMIT 40 LOOP
      IF jsonb_typeof(e) = 'object' AND jsonb_typeof(e->'offen') = 'boolean' THEN
        PERFORM ally_ui_zustand_merken(s.person, e->>'k', jsonb_build_object('offen', e->'offen'));
      END IF;
    END LOOP;
  END IF;

  IF NOT coalesce(ally_hat_recht(s.person, 'admin'), false) AND NOT coalesce(ally_hat_recht(s.person, 'superadmin'), false) THEN
    fehler := 'Updates spielen nur Admin und Superadmin ein.';
  ELSE
    INSERT INTO ally_update_stand (id) VALUES (1) ON CONFLICT (id) DO NOTHING;
    SELECT * INTO z FROM ally_update_stand x WHERE x.id = 1 FOR UPDATE;
    aktiv := z.programm_am IS NULL OR z.programm_am > now() - interval '10 minutes';   -- Migration 211 (Updates-Seite, Stefan 06.11.2026)
    IF NOT aktiv THEN hinweis := ' Das Update-Programm auf dem Server meldet sich zurzeit nicht.'; END IF;
    laeuft := EXISTS (SELECT 1 FROM ally_updates u WHERE u.status COLLATE "C" = 'laeuft');
    IF p_aktion COLLATE "C" = 'up_suchen' THEN
      IF laeuft OR z.auftrag COLLATE "C" = 'aktualisieren' THEN
        fehler := 'Gerade läuft ein Update oder es ist vorgemerkt. Bitte warten, bis das Ergebnis im Verlauf steht.';
      ELSIF coalesce(ally_einstellung('update_quelle'), '') !~ '^[A-Za-z0-9_.-]{1,100}/[A-Za-z0-9_.-]{1,100}$' OR ally_einstellung('update_quelle') ~ '(^|/)[.]{1,2}(/|$)' THEN
        fehler := 'Die Einstellung update_quelle fehlt oder ist ungültig (Form inhaber/repo).';
      ELSE
        -- Migration 211 (Updates-Seite, Stefan 06.11.2026): sofort über n8n (ALLY 20 „Update: Stand holen“, „Update: Liste holen“, „Update-Suche speichern“)
        RETURN jsonb_build_object('ok', true, 'angemeldet', true, 'weiter', 'update_suchen', 'r', jsonb_build_object('quelle', ally_einstellung('update_quelle')));
      END IF;
    ELSIF p_aktion COLLATE "C" = 'up_jetzt' THEN
      IF NOT coalesce(ally_darf_aktualisieren(s.person), false) THEN
        fehler := 'Mit einer Test-Person ist kein Update möglich.';
      ELSIF z.abgebrochen_stand COLLATE "C" = 'zuruecksetzen' THEN
        fehler := 'Ein abgebrochenes Update wird gerade zurückgesetzt. Bitte warten, bis das Ergebnis im Verlauf steht.';
      ELSIF z.abgebrochen_stand COLLATE "C" = 'pruefen' THEN
        fehler := 'Nach einem abgebrochenen Update prüft der Anbieter erst den Stand. Bis dahin sind keine Updates möglich.';
      ELSIF laeuft OR z.auftrag COLLATE "C" = 'aktualisieren' THEN
        fehler := 'Gerade läuft schon ein Update oder es ist vorgemerkt. Bitte warten, bis das Ergebnis im Verlauf steht.';
      ELSIF NOT ally_update_offen() THEN
        fehler := 'Es gibt keine neuere Fassung.';
      ELSIF coalesce(d->>'fassung', '') COLLATE "C" IS DISTINCT FROM z.verfuegbar OR coalesce(d->>'commit', '') COLLATE "C" IS DISTINCT FROM z.verfuegbar_commit THEN
        fehler := 'Inzwischen gibt es eine andere Fassung. Bitte die Seite neu laden.';
      ELSE
        UPDATE ally_update_stand x SET auftrag = 'aktualisieren', auftrag_art = 'update', auftrag_am = now(), auftrag_von = s.person, geaendert_am = now() WHERE x.id = 1;
        m := 'Das Update auf Fassung ' || z.verfuegbar || ' startet in Kürze (das Update-Programm prüft jede Minute). Während des Updates ist die Oberfläche wenige Minuten nicht nutzbar. Das Ergebnis steht im Verlauf.' || hinweis;
      END IF;
    ELSIF p_aktion COLLATE "C" = 'up_freigeben' AND coalesce(ally_hat_recht(s.person, 'superadmin'), false) AND coalesce(ally_darf_aktualisieren(s.person), false) THEN
      IF z.abgebrochen_stand IS NULL THEN
        fehler := 'Es gibt keine Sperre nach einem abgebrochenen Update.';
      ELSIF z.abgebrochen_stand COLLATE "C" = 'zuruecksetzen' AND coalesce(z.programm_am > now() - interval '30 minutes', false) THEN
        fehler := 'Das Update-Programm setzt den Stand gerade zurück. Bitte warten, bis das Ergebnis im Verlauf steht.';
      ELSE
        -- hängendes „zuruecksetzen“: Das Zurücksetzen entfällt; der Verlauf sagt das (das nächste Update erkennt den Stand per Probe)
        IF z.abgebrochen_stand COLLATE "C" = 'zuruecksetzen' THEN
          UPDATE ally_updates x SET ergebnis = 'Das Update wurde abgebrochen. Sperre aufgehoben, ohne Zurücksetzen.' WHERE x.id = z.abgebrochen_lauf;
        END IF;
        UPDATE ally_update_stand x SET abgebrochen_lauf = NULL, abgebrochen_stand = NULL, abgebrochen_ordner = NULL, geaendert_am = now() WHERE x.id = 1;
        m := 'Sperre aufgehoben. Updates sind wieder möglich.';
      END IF;
    ELSE
      fehler := 'Diese Aktion gibt es nicht.';
    END IF;
  END IF;
  PERFORM ally_web_meldung(p_token, coalesce(fehler, m), CASE WHEN fehler IS NULL THEN 'ok' ELSE 'fehler' END, NULL);
  RETURN jsonb_build_object('ok', fehler IS NULL, 'angemeldet', true);
END $function$;
CREATE OR REPLACE FUNCTION public.ally_update_host_plan(p_meldung jsonb)
 RETURNS SETOF text
 LANGUAGE plpgsql
AS $function$
DECLARE
  q jsonb := CASE WHEN jsonb_typeof(p_meldung) = 'object' THEN p_meldung ELSE '{}'::jsonb END;
  z ally_update_stand; u ally_updates; nr bigint; p text;
  ziel jsonb := jsonb_build_object('seite', 'einstellungen', 'parameter', jsonb_build_object('bereich', 'updates'));
BEGIN
  -- Migration 203 (Update-Knopf): Aufruf des Update-Programms auf dem Server (server/installation/update/ally-update.sh, alle 5 Minuten, nur eine Instanz zugleich).
  -- Migration 211 (Updates-Seite, Stefan 06.11.2026): Programm jede Minute; beim Start eines Updates der Stand vorher (von_commit) in sicherungen (Verlauf zeigt ihn bei gleicher Nummer).
  -- Meldung speichern (programm = Stand des Programms). Läufe, die noch als „läuft“ stehen, gelten als abgebrochen (das Programm läuft nie doppelt); Meldung an
  -- den Superadmins; der Stand wird gesperrt (abgebrochen_*), und der nächste Auftrag ist „zuruecksetzen|lauf|ordner“ (Programm setzt den Lauf zurück,
  -- ally_update_host_zurueckgesetzt). Frist abgelaufen: einmal Meldung an die Superadmins. Dann höchstens ein Auftrag: „aktualisieren|lauf|fassung|commit|quelle|art“ für
  -- „Jetzt aktualisieren“ (art update: nur wenn die Fassung noch offen ist und die Person noch darf; legt den Lauf in ally_updates an, art in sicherungen;
  -- andere Arten wie modul_installieren/modul_entfernen sind vorgesehen, das Programm führt bisher nur update aus) oder „suchen“ für „Update suchen“
  -- und einmal am Tag (gesucht_am wird dabei gesetzt, damit ein abgebrochenes Suchen nicht alle 5 Minuten wiederkommt).
  INSERT INTO ally_update_stand (id) VALUES (1) ON CONFLICT (id) DO NOTHING;
  UPDATE ally_update_stand x SET programm_am = now(),
    programm_fassung = nullif(left(regexp_replace(coalesce(q->>'programm', ''), '[^A-Za-z0-9._-]', '', 'g'), 40), '') WHERE x.id = 1;
  FOR u IN UPDATE ally_updates x SET status = 'fehler', beendet_am = now(),
      ergebnis = 'Das Update wurde abgebrochen (z. B. Neustart des Servers). Der Stand wird zurückgesetzt.'
    WHERE x.status COLLATE "C" = 'laeuft' RETURNING * LOOP
    UPDATE ally_update_stand x SET abgebrochen_lauf = u.id, abgebrochen_stand = 'zuruecksetzen',
      abgebrochen_ordner = CASE WHEN coalesce(u.sicherungen->>'ordner', '') ~ '^/[A-Za-z0-9._/-]{1,200}$' THEN u.sicherungen->>'ordner' END, geaendert_am = now() WHERE x.id = 1;
    FOR p IN SELECT ally_update_empfaenger(true) LOOP
      PERFORM ally_benachrichtigen(p, 'systemfehler', 'Update abgebrochen', 'Das Update auf Fassung ' || u.zu_fassung
        || ' wurde abgebrochen. Weitere Updates sind gesperrt, bis das Update-Programm den Stand zurückgesetzt hat.', ziel, 'update-lauf:' || u.id, 'Updates', false);
    END LOOP;
  END LOOP;
  SELECT * INTO z FROM ally_update_stand x WHERE x.id = 1 FOR UPDATE;
  -- Hart abgebrochener Lauf: zuerst zurücksetzen (Programm: zuruecksetzen|lauf|ordner), sonst nichts; bei „pruefen“ keine Updates, Suche weiter möglich
  IF z.abgebrochen_stand COLLATE "C" = 'zuruecksetzen' THEN
    RETURN NEXT 'zuruecksetzen|' || z.abgebrochen_lauf || '|' || coalesce(z.abgebrochen_ordner, '-');
    RETURN;
  END IF;
  IF z.abgebrochen_stand COLLATE "C" = 'pruefen' AND z.auftrag COLLATE "C" = 'aktualisieren' THEN
    UPDATE ally_update_stand x SET auftrag = NULL, auftrag_art = NULL, auftrag_am = NULL, auftrag_von = NULL WHERE x.id = 1;
    z.auftrag := NULL;
  END IF;
  IF z.frist_gemeldet_am IS NULL AND ally_update_frist() <= now() THEN
    FOR p IN SELECT ally_update_empfaenger(true) LOOP
      PERFORM ally_benachrichtigen(p, 'update_verfuegbar', 'Update-Frist abgelaufen: Fassung ' || z.verfuegbar,
        'Fassung ' || z.verfuegbar || ' ist seit ' || ally_sicherung_zeit(z.verfuegbar_seit) || ' Uhr verfügbar und noch nicht eingespielt. Die Frist ist abgelaufen; bitte das Update einspielen.',
        ziel, 'update-frist:' || z.verfuegbar || ':' || left(z.verfuegbar_commit, 12), 'Updates', false);
    END LOOP;
    UPDATE ally_update_stand x SET frist_gemeldet_am = now() WHERE x.id = 1;
  END IF;
  IF z.auftrag COLLATE "C" = 'aktualisieren' THEN
    UPDATE ally_update_stand x SET auftrag = NULL, auftrag_art = NULL, auftrag_am = NULL, auftrag_von = NULL WHERE x.id = 1;
    IF ally_update_offen() AND coalesce(ally_darf_aktualisieren(z.auftrag_von), false) AND z.verfuegbar_quelle IS NOT NULL THEN
      INSERT INTO ally_updates (von_fassung, zu_fassung, person, sicherungen)
      VALUES (ally_fassung_aktuell(), z.verfuegbar, z.auftrag_von, jsonb_build_object('art', z.auftrag_art, 'zu_commit', z.verfuegbar_commit, 'quelle', z.verfuegbar_quelle,
        'von_commit', (SELECT g.git_commit FROM ally_fassung g WHERE g.nummer = ally_fassung_aktuell())))
      RETURNING id INTO nr;
      RETURN NEXT 'aktualisieren|' || nr || '|' || z.verfuegbar || '|' || z.verfuegbar_commit || '|' || z.verfuegbar_quelle || '|' || z.auftrag_art;
      RETURN;
    END IF;
  END IF;
  IF z.auftrag COLLATE "C" = 'suchen' OR z.gesucht_am IS NULL OR z.gesucht_am <= now() - interval '1 day' THEN
    UPDATE ally_update_stand x SET gesucht_am = now(), auftrag = NULL, auftrag_art = NULL, auftrag_am = NULL, auftrag_von = NULL WHERE x.id = 1 AND (x.auftrag IS NULL OR x.auftrag COLLATE "C" = 'suchen');
    RETURN NEXT 'suchen';
  END IF;
  RETURN;
END $function$;
DO $m$
BEGIN
  IF (SELECT md5(string_agg(p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')|' || pg_get_function_result(p.oid) || '|' || md5(p.prosrc), E'\n' ORDER BY p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')' COLLATE "C")) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname::text = 'public' COLLATE "C" AND p.proname::text COLLATE "C" = ANY (ARRAY['ally_update_ui', 'ally_update_ui_aktion', 'ally_update_host_plan', 'ally_update_zeit', 'ally_update_phasen', 'ally_update_suche_ende'])) IS DISTINCT FROM 'f96bc1ec68a6e0e95f790e26ed31c734' THEN RAISE EXCEPTION 'Migration 211: Funktionen nicht wie gebaut'; END IF;
END $m$;
