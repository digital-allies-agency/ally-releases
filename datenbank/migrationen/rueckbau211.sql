-- Rückbau 211: Funktionen wörtlich wie vor 211 (werkzeuge/m211/vorher/), neue Funktionen entfernen. Keine Daten betroffen. Danach die Abläufe ALLY 20 und 23
-- auf den Stand vor 211 zurücksetzen (werkzeuge/sammel211/vorher/) und die Web-App der Fassung davor einspielen.
-- Nur auf dem Stand von 211. Läuft als Ganzes in der Transaktion des Aufrufs (psql -1).
DO $m$
BEGIN
  IF (SELECT md5(string_agg(p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')|' || pg_get_function_result(p.oid) || '|' || md5(p.prosrc), E'\n' ORDER BY p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')' COLLATE "C")) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname::text = 'public' COLLATE "C" AND p.proname::text COLLATE "C" = ANY (ARRAY['ally_update_ui', 'ally_update_ui_aktion', 'ally_update_host_plan', 'ally_update_zeit', 'ally_update_phasen', 'ally_update_suche_ende'])) IS NOT DISTINCT FROM '03e9aa88d94f97485889b72c9034d7fb' THEN RAISE EXCEPTION 'Rückbau 211: schon zurückgebaut, nichts geändert'; END IF;
  IF (SELECT md5(string_agg(p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')|' || pg_get_function_result(p.oid) || '|' || md5(p.prosrc), E'\n' ORDER BY p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')' COLLATE "C")) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname::text = 'public' COLLATE "C" AND p.proname::text COLLATE "C" = ANY (ARRAY['ally_update_ui', 'ally_update_ui_aktion', 'ally_update_host_plan', 'ally_update_zeit', 'ally_update_phasen', 'ally_update_suche_ende'])) IS DISTINCT FROM 'f96bc1ec68a6e0e95f790e26ed31c734' THEN RAISE EXCEPTION 'Rückbau 211: nicht im Stand von 211, nichts geändert'; END IF;
END $m$;
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
BEGIN
  -- Migration 203 (Update-Knopf, Entscheidung Stefan 31.10.2026: nur Admin und Superadmin, fest): Daten der Seite Einstellungen › System › Updates
  -- (ALLY 23 „Update laden“). Eingespielte Fassung, verfügbare Fassung mit Frist, letzte Suche, offener Auftrag, laufendes Update, Stand des Update-Programms
  -- auf dem Server und die letzten 30 Läufe. darf = Knopf „Jetzt aktualisieren“ erlaubt (ally_darf_aktualisieren). Für alle anderen und ohne Sitzung NULL.
  -- abgebrochen = hart abgebrochener Lauf (zuruecksetzen: das Programm setzt den Stand zurück; pruefen: Sperre, der Anbieter prüft). Ordner der Sicherung und
  -- Rohtext der Fehler (detail) nur für Superadmins.
  SELECT * INTO s FROM ally_ui_sitzung(p_token);
  IF NOT FOUND OR s.muss_pw_setzen THEN RETURN NULL; END IF;
  sa := coalesce(ally_hat_recht(s.person, 'superadmin'), false);
  adm := coalesce(ally_hat_recht(s.person, 'admin'), false);
  IF NOT sa AND NOT adm THEN RETURN NULL; END IF;
  SELECT * INTO l FROM ally_updates u WHERE u.status COLLATE "C" = 'laeuft' ORDER BY u.id DESC LIMIT 1;
  RETURN jsonb_build_object('ok', true, 'sa', sa, 'admin', adm, 'darf', coalesce(ally_darf_aktualisieren(s.person), false),
    'installiert', CASE WHEN f.nummer IS NOT NULL THEN jsonb_build_object('nummer', f.nummer, 'commit', left(f.git_commit, 7), 'am', ally_sicherung_zeit(f.eingespielt_am)) END,
    'verfuegbar', CASE WHEN z.verfuegbar IS NOT NULL THEN jsonb_build_object('nummer', z.verfuegbar, 'commit', z.verfuegbar_commit, 'kurz', left(z.verfuegbar_commit, 7),
      'datum', to_char(z.verfuegbar_datum, 'DD.MM.YYYY'), 'neu', z.verfuegbar_neu, 'seit', ally_sicherung_zeit(z.verfuegbar_seit)) END,
    'offen', offen,
    'frist', CASE WHEN fr IS NOT NULL THEN jsonb_build_object('bis', to_char(fr AT TIME ZONE 'Europe/Berlin', 'DD.MM.YYYY'),
      'tage', greatest(0, ceil(extract(epoch FROM fr - now()) / 86400))::integer, 'abgelaufen', fr <= now()) END,
    'gesucht', ally_sicherung_zeit(z.gesucht_am), 'such_fehler', z.such_fehler,
    'auftrag', z.auftrag, 'auftrag_am', ally_sicherung_zeit(z.auftrag_am),
    'laeuft', CASE WHEN l.id IS NOT NULL THEN jsonb_build_object('seit', ally_sicherung_zeit(l.gestartet_am), 'zu', l.zu_fassung) END,
    'abgebrochen', CASE WHEN z.abgebrochen_lauf IS NOT NULL THEN jsonb_build_object('lauf', z.abgebrochen_lauf, 'stand', z.abgebrochen_stand,
      'ordner', CASE WHEN sa THEN z.abgebrochen_ordner END) END,
    'programm', jsonb_build_object('gemeldet', ally_sicherung_zeit(z.programm_am), 'aktiv', coalesce(z.programm_am > now() - interval '15 minutes', false)),
    'verlauf', (SELECT coalesce(jsonb_agg(jsonb_build_object('id', v.id, 'zeit', ally_sicherung_zeit(v.gestartet_am), 'von', v.von_fassung, 'zu', v.zu_fassung,
        'person', coalesce(p.name, v.person), 'status', v.status, 'meldung', v.ergebnis,
        'dauer', CASE WHEN v.beendet_am IS NOT NULL THEN greatest(0, round(extract(epoch FROM v.beendet_am - v.gestartet_am)))::bigint END,
        'ordner', CASE WHEN sa THEN v.sicherungen->>'ordner' END, 'detail', CASE WHEN sa THEN v.sicherungen->>'detail' END) ORDER BY v.gestartet_am DESC, v.id DESC), '[]'::jsonb)
      FROM (SELECT * FROM ally_updates x ORDER BY x.gestartet_am DESC, x.id DESC LIMIT 30) v LEFT JOIN ally_personen p ON p.matrix_user_id = v.person));
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
    aktiv := coalesce(z.programm_am > now() - interval '15 minutes', false);
    IF NOT aktiv THEN hinweis := ' Das Update-Programm auf dem Server meldet sich zurzeit nicht.'; END IF;
    laeuft := EXISTS (SELECT 1 FROM ally_updates u WHERE u.status COLLATE "C" = 'laeuft');
    IF p_aktion COLLATE "C" = 'up_suchen' THEN
      IF laeuft OR z.auftrag COLLATE "C" = 'aktualisieren' THEN
        fehler := 'Gerade läuft ein Update oder es ist vorgemerkt. Bitte warten, bis das Ergebnis im Verlauf steht.';
      ELSIF z.auftrag COLLATE "C" = 'suchen' THEN
        fehler := 'Die Suche ist schon vorgemerkt.';
      ELSE
        UPDATE ally_update_stand x SET auftrag = 'suchen', auftrag_art = NULL, auftrag_am = now(), auftrag_von = s.person, geaendert_am = now() WHERE x.id = 1;
        m := 'Die Suche nach Updates startet in den nächsten 5 Minuten.' || hinweis;
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
        m := 'Das Update auf Fassung ' || z.verfuegbar || ' startet in den nächsten 5 Minuten. Während des Updates ist die Oberfläche wenige Minuten nicht nutzbar. Das Ergebnis steht im Verlauf.' || hinweis;
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
      VALUES (ally_fassung_aktuell(), z.verfuegbar, z.auftrag_von, jsonb_build_object('art', z.auftrag_art, 'zu_commit', z.verfuegbar_commit, 'quelle', z.verfuegbar_quelle))
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
DROP FUNCTION public.ally_update_suche_ende(p_token text, p_sha text, p_liste text, p_fehler text);
DROP FUNCTION public.ally_update_phasen(p_schritte jsonb, p_status text);
DROP FUNCTION public.ally_update_zeit(p_zeit timestamp with time zone, p_art text);
DO $m$
BEGIN
  IF (SELECT md5(string_agg(p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')|' || pg_get_function_result(p.oid) || '|' || md5(p.prosrc), E'\n' ORDER BY p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')' COLLATE "C")) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname::text = 'public' COLLATE "C" AND p.proname::text COLLATE "C" = ANY (ARRAY['ally_update_ui', 'ally_update_ui_aktion', 'ally_update_host_plan', 'ally_update_zeit', 'ally_update_phasen', 'ally_update_suche_ende'])) IS DISTINCT FROM '03e9aa88d94f97485889b72c9034d7fb' THEN RAISE EXCEPTION 'Rückbau 211: Funktionen nicht wie vorher'; END IF;
END $m$;
