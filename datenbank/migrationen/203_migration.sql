-- Migration 203 (Update-Knopf, Entscheidungen Stefan 31.10.2026): Seite Einstellungen › System › Updates (nur Admin und Superadmin), Aufträge „Update suchen“ und „Jetzt aktualisieren“
-- für das Update-Programm auf dem Server (server/installation/update/ally-update.sh, alle 5 Minuten), verfügbare Fassung mit Frist (Einstellung update_frist_tage,
-- Standard 30), Benachrichtigungsart „Update verfügbar“. Neu: Tabelle ally_update_stand (leer), Funktionen ally_update_nummer, ally_update_stand_zeile, ally_update_installiert, ally_update_offen, ally_update_frist, ally_update_empfaenger, ally_update_ui, ally_update_ui_aktion, ally_update_host_plan, ally_update_host_verfuegbar, ally_update_host_schritt, ally_update_host_ende, ally_update_host_zurueckgesetzt.
-- Protokoll je Lauf in ally_updates (Migration 188, unverändert). Keine geänderte Funktion; Datenänderung nur: neue Benachrichtigungsart update_verfuegbar.
-- Aktionen up_* über ALLY 20 „Aktion ausführen“ (ally_update_ui_aktion), Seite über ALLY 23 (ally_update_ui).
-- Wächter: Tabelle, Funktionen und Art noch nicht vorhanden, benötigte Funktionen und Arten vorhanden, Aufbau von ally_updates, ally_fassung und der
-- Benachrichtigungen wie erwartet; nachher Schema, Funktionen und Art wie gebaut, neue Tabelle leer. Läuft als Ganzes in der Transaktion des Aufrufs (psql -1).
-- Rückbau: rueckbau203.sql.
DO $m$
BEGIN
  IF (SELECT count(*) FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname::text = 'public' COLLATE "C" AND c.relkind = 'r' AND c.relname::text COLLATE "C" = 'ally_update_stand') = 1 AND (SELECT md5(string_agg(p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')|' || pg_get_function_result(p.oid) || '|' || md5(p.prosrc), E'\n' ORDER BY p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')' COLLATE "C")) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname::text = 'public' COLLATE "C" AND p.proname::text COLLATE "C" = ANY (ARRAY['ally_update_nummer', 'ally_update_stand_zeile', 'ally_update_installiert', 'ally_update_offen', 'ally_update_frist', 'ally_update_empfaenger', 'ally_update_ui', 'ally_update_ui_aktion', 'ally_update_host_plan', 'ally_update_host_verfuegbar', 'ally_update_host_schritt', 'ally_update_host_ende', 'ally_update_host_zurueckgesetzt'])) IS NOT DISTINCT FROM '135ac6b7a33661d8a5c4a6086ab587f1' AND (SELECT md5(string_agg(z, E'\n' ORDER BY z COLLATE "C")) FROM (WITH t AS (SELECT c.oid, c.relname::text AS tab FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname::text = 'public' COLLATE "C" AND c.relkind::text = ANY (ARRAY['r', 'p']) AND c.relname::text = ANY (ARRAY['ally_update_stand'])) SELECT 'S|' || t.tab || '|' || a.attname::text || '|' || format_type(a.atttypid, a.atttypmod) || '|' || CASE WHEN a.attnotnull THEN 'NN' ELSE '-' END || '|' || coalesce(pg_get_expr(d.adbin, d.adrelid), '') || '|' || a.attidentity::text || a.attgenerated::text AS z FROM t JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum > 0 AND NOT a.attisdropped LEFT JOIN pg_attrdef d ON d.adrelid = t.oid AND d.adnum = a.attnum UNION ALL SELECT 'C|' || t.tab || '|' || co.conname::text || '|' || co.contype::text || '|' || pg_get_constraintdef(co.oid) FROM t JOIN pg_constraint co ON co.conrelid = t.oid UNION ALL SELECT 'I|' || t.tab || '|' || ic.relname::text || '|' || pg_get_indexdef(i.indexrelid) FROM t JOIN pg_index i ON i.indrelid = t.oid JOIN pg_class ic ON ic.oid = i.indexrelid UNION ALL SELECT 'T|' || t.tab || '|' || tg.tgname::text || '|' || pg_get_triggerdef(tg.oid) || '|' || tg.tgenabled::text FROM t JOIN pg_trigger tg ON tg.tgrelid = t.oid AND NOT tg.tgisinternal) x) IS NOT DISTINCT FROM '262cae808bacef79d2fc48bd44ca308d' AND (SELECT count(*) FROM ally_benachrichtigung_arten x WHERE x.schluessel COLLATE "C" = 'update_verfuegbar') = 1
    THEN RAISE EXCEPTION 'Migration 203: schon eingespielt, nichts geändert'; END IF;
  IF (SELECT count(*) FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname::text = 'public' COLLATE "C" AND c.relname::text COLLATE "C" = ANY (ARRAY['ally_update_stand_rb203', 'ally_benachrichtigungen_rb203', 'ally_benachrichtigung_schalter_rb203'])) <> 0 THEN RAISE EXCEPTION 'Migration 203: Sicherungstabellen aus Rückbau 203 vorhanden (ally_update_stand_rb203 u. a.), erst klären, nichts geändert'; END IF;
  IF (SELECT count(*) FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname::text = 'public' COLLATE "C" AND c.relkind = 'r' AND c.relname::text COLLATE "C" = 'ally_update_stand') <> 0 THEN RAISE EXCEPTION 'Migration 203: Tabelle ally_update_stand schon vorhanden (unbekannter Stand), nichts geändert'; END IF;
  IF (SELECT md5(string_agg(p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')|' || pg_get_function_result(p.oid) || '|' || md5(p.prosrc), E'\n' ORDER BY p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')' COLLATE "C")) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname::text = 'public' COLLATE "C" AND p.proname::text COLLATE "C" = ANY (ARRAY['ally_update_nummer', 'ally_update_stand_zeile', 'ally_update_installiert', 'ally_update_offen', 'ally_update_frist', 'ally_update_empfaenger', 'ally_update_ui', 'ally_update_ui_aktion', 'ally_update_host_plan', 'ally_update_host_verfuegbar', 'ally_update_host_schritt', 'ally_update_host_ende', 'ally_update_host_zurueckgesetzt'])) IS NOT NULL THEN RAISE EXCEPTION 'Migration 203: Funktionen des Update-Knopfs schon vorhanden (unbekannter Stand), nichts geändert'; END IF;
  IF (SELECT count(*) FROM ally_benachrichtigung_arten x WHERE x.schluessel COLLATE "C" = 'update_verfuegbar') <> 0 THEN RAISE EXCEPTION 'Migration 203: Benachrichtigungsart update_verfuegbar schon vorhanden (unbekannter Stand), nichts geändert'; END IF;
  IF (SELECT count(*) FROM unnest(ARRAY['ally_ui_sitzung(text)', 'ally_ui_csrf(text)', 'ally_web_meldung(text,text,text,jsonb)', 'ally_ui_zustand_merken(text,text,jsonb)', 'ally_hat_recht(text,text)', 'ally_benachrichtigen(text,text,text,text,jsonb,text,text,boolean)', 'ally_darf_aktualisieren(text)', 'ally_fassung_aktuell()', 'ally_sicherung_zeit(timestamp with time zone)', 'ally_einstellung(text)']) f WHERE to_regprocedure(f) IS NULL) <> 0 THEN RAISE EXCEPTION 'Migration 203: eine benötigte Funktion fehlt (Migration 188 oder 201?), nichts geändert'; END IF;
  IF (SELECT count(*) FROM ally_benachrichtigung_arten x WHERE x.schluessel COLLATE "C" = ANY (ARRAY['systemfehler', 'mitteilung'])) <> 2 THEN RAISE EXCEPTION 'Migration 203: Benachrichtigungsart systemfehler oder mitteilung fehlt, nichts geändert'; END IF;
  IF (SELECT md5(string_agg(z, E'\n' ORDER BY z COLLATE "C")) FROM (WITH t AS (SELECT c.oid, c.relname::text AS tab FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname::text = 'public' COLLATE "C" AND c.relkind::text = ANY (ARRAY['r', 'p']) AND c.relname::text = ANY (ARRAY['ally_benachrichtigung_arten', 'ally_benachrichtigung_schalter', 'ally_benachrichtigungen', 'ally_fassung', 'ally_updates'])) SELECT 'S|' || t.tab || '|' || a.attname::text || '|' || format_type(a.atttypid, a.atttypmod) || '|' || CASE WHEN a.attnotnull THEN 'NN' ELSE '-' END || '|' || coalesce(pg_get_expr(d.adbin, d.adrelid), '') || '|' || a.attidentity::text || a.attgenerated::text AS z FROM t JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum > 0 AND NOT a.attisdropped LEFT JOIN pg_attrdef d ON d.adrelid = t.oid AND d.adnum = a.attnum UNION ALL SELECT 'C|' || t.tab || '|' || co.conname::text || '|' || co.contype::text || '|' || pg_get_constraintdef(co.oid) FROM t JOIN pg_constraint co ON co.conrelid = t.oid UNION ALL SELECT 'I|' || t.tab || '|' || ic.relname::text || '|' || pg_get_indexdef(i.indexrelid) FROM t JOIN pg_index i ON i.indrelid = t.oid JOIN pg_class ic ON ic.oid = i.indexrelid UNION ALL SELECT 'T|' || t.tab || '|' || tg.tgname::text || '|' || pg_get_triggerdef(tg.oid) || '|' || tg.tgenabled::text FROM t JOIN pg_trigger tg ON tg.tgrelid = t.oid AND NOT tg.tgisinternal) x) IS DISTINCT FROM 'add36aa8555c88a433c3f752f661864a' THEN RAISE EXCEPTION 'Migration 203: Aufbau von ally_updates, ally_fassung oder der Benachrichtigungen weicht ab, nichts geändert'; END IF;
END $m$;
CREATE TABLE public.ally_update_stand (
  id integer NOT NULL DEFAULT 1,
  verfuegbar text,
  verfuegbar_commit text,
  verfuegbar_datum date,
  verfuegbar_neu text,
  verfuegbar_quelle text,
  verfuegbar_seit timestamp with time zone,
  frist_gemeldet_am timestamp with time zone,
  gesucht_am timestamp with time zone,
  such_fehler text,
  auftrag text,
  auftrag_art text,
  auftrag_am timestamp with time zone,
  auftrag_von text,
  programm_am timestamp with time zone,
  programm_fassung text,
  abgebrochen_lauf bigint,
  abgebrochen_stand text,
  abgebrochen_ordner text,
  geaendert_am timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT ally_update_stand_pkey PRIMARY KEY (id),
  CONSTRAINT ally_update_stand_id_check CHECK (id = 1),
  CONSTRAINT ally_update_stand_verfuegbar_check CHECK ((verfuegbar IS NULL OR verfuegbar ~ '^[0-9]{1,3}[.][0-9]{1,3}$')
    AND (verfuegbar_commit IS NULL OR verfuegbar_commit ~ '^[0-9a-f]{7,40}$') AND (verfuegbar_quelle IS NULL OR verfuegbar_quelle ~ '^[0-9a-f]{40}$')
    AND (verfuegbar IS NULL) = (verfuegbar_seit IS NULL)),
  CONSTRAINT ally_update_stand_abgebrochen_check CHECK ((abgebrochen_stand IS NULL OR abgebrochen_stand IN ('zuruecksetzen', 'pruefen'))
    AND (abgebrochen_lauf IS NULL) = (abgebrochen_stand IS NULL) AND (abgebrochen_ordner IS NULL OR abgebrochen_ordner ~ '^/[A-Za-z0-9._/-]{1,200}$')),
  CONSTRAINT ally_update_stand_texte_check CHECK (length(verfuegbar_neu) <= 1000 AND length(such_fehler) <= 1000 AND length(programm_fassung) <= 40),
  CONSTRAINT ally_update_stand_auftrag_check CHECK ((auftrag IS NULL OR auftrag IN ('suchen', 'aktualisieren')) AND (auftrag IS NULL) = (auftrag_am IS NULL)
    AND (auftrag_art IS NULL OR auftrag_art IN ('update', 'modul_installieren', 'modul_entfernen')) AND (auftrag_art IS NOT NULL) = (auftrag IS NOT DISTINCT FROM 'aktualisieren'))
);
COMMENT ON TABLE public.ally_update_stand IS 'Migration 203 (Update-Knopf): Einzelzeile id = 1. Neueste freigegebene Fassung laut Auslieferungs-Repo (Nummer, Freigabe-Commit, Datum, Text „neu“, Commit des Auslieferungs-Repos = Stand des Pakets) mit Beginn der Frist, letzte Suche, offener Auftrag (suchen, aktualisieren mit Art update; vorgesehen: modul_installieren, modul_entfernen) für das Update-Programm auf dem Server und dessen letzte Meldung; nach einem hart abgebrochenen Lauf dessen Nummer und Zustand (zuruecksetzen, pruefen = Sperre für Updates) mit dem Ordner der Sicherung. Ohne Zeile: nichts gesucht.';
CREATE OR REPLACE FUNCTION public.ally_update_nummer(p_nummer text)
 RETURNS integer[]
 LANGUAGE sql
 IMMUTABLE
AS $function$
  -- Migration 203 (Update-Knopf): Fassungsnummer wie 1.10 als Zahlenpaar zum Vergleichen (1.10 ist neuer als 1.9); ungültig = NULL.
  SELECT CASE WHEN p_nummer ~ '^[0-9]{1,3}[.][0-9]{1,3}$' THEN ARRAY[split_part(p_nummer, '.', 1)::integer, split_part(p_nummer, '.', 2)::integer] END
$function$;
CREATE OR REPLACE FUNCTION public.ally_update_stand_zeile()
 RETURNS ally_update_stand
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
  z ally_update_stand;
BEGIN
  -- Migration 203 (Update-Knopf): Einzelzeile id = 1 der Tabelle ally_update_stand; ohne Zeile ein leerer Stand (nichts gesucht, nichts verfügbar).
  SELECT * INTO z FROM ally_update_stand x WHERE x.id = 1;
  IF NOT FOUND THEN z.id := 1; END IF;
  RETURN z;
END $function$;
CREATE OR REPLACE FUNCTION public.ally_update_installiert()
 RETURNS ally_fassung
 LANGUAGE sql
 STABLE
AS $function$
  -- Migration 203 (Update-Knopf): eingespielte Fassung mit Commit und Zeitpunkt (dieselbe Zeile wie ally_fassung_aktuell); ohne Eintrag NULL.
  SELECT f.* FROM ally_fassung f ORDER BY f.eingespielt_am DESC, f.nummer COLLATE "C" DESC LIMIT 1
$function$;
CREATE OR REPLACE FUNCTION public.ally_update_offen()
 RETURNS boolean
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
  z ally_update_stand := ally_update_stand_zeile();
  f ally_fassung := ally_update_installiert();
  v integer[] := ally_update_nummer(z.verfuegbar);
  i integer[] := ally_update_nummer(f.nummer);
BEGIN
  -- Migration 203 (Update-Knopf): Gibt es eine neuere freigegebene Fassung als die eingespielte? Neuer heißt: höhere Nummer, oder gleiche Nummer mit
  -- anderem Freigabe-Commit (eine Fassung kann mit Fehlerbehebungen neu freigegeben werden). Ist bei der eingespielten Fassung kein Commit
  -- eingetragen (Installation vor Migration 203), gilt die gleiche Nummer als offen. Ein kurzer Commit (7 bis 39 Zeichen) zählt als Anfang des langen.
  IF v IS NULL THEN RETURN false; END IF;
  IF i IS NULL THEN RETURN true; END IF;
  IF v > i THEN RETURN true; END IF;
  IF v < i THEN RETURN false; END IF;
  RETURN f.git_commit IS NULL OR z.verfuegbar_commit IS NULL
    OR left(z.verfuegbar_commit, least(length(f.git_commit), length(z.verfuegbar_commit))) COLLATE "C"
       <> left(f.git_commit, least(length(f.git_commit), length(z.verfuegbar_commit))) COLLATE "C";
END $function$;
CREATE OR REPLACE FUNCTION public.ally_update_frist()
 RETURNS timestamp with time zone
 LANGUAGE sql
 STABLE
AS $function$
  -- Migration 203 (Update-Knopf, Entscheidung Stefan 31.10.2026: Frist 30 Tage, danach aktualisiert der Anbieter als Superadmin): Ende der Frist für die verfügbare
  -- Fassung = seit wann sie angezeigt wird + Tage aus der Einstellung update_frist_tage (Standard 30). NULL, wenn keine neuere Fassung offen ist.
  SELECT CASE WHEN ally_update_offen() THEN z.verfuegbar_seit
    + CASE WHEN coalesce(ally_einstellung('update_frist_tage'), '') ~ '^[0-9]{1,3}$' THEN ally_einstellung('update_frist_tage')::integer ELSE 30 END * interval '1 day' END
  FROM (SELECT (ally_update_stand_zeile()).*) z
$function$;
CREATE OR REPLACE FUNCTION public.ally_update_empfaenger(p_nur_superadmin boolean)
 RETURNS SETOF text
 LANGUAGE sql
 STABLE
AS $function$
  -- Migration 203 (Update-Knopf): Empfänger von Meldungen zu Updates: aktive Superadmins, ohne p_nur_superadmin auch die Admins.
  SELECT x.matrix_user_id FROM ally_personen x
  WHERE x.aktiv AND (coalesce(ally_hat_recht(x.matrix_user_id, 'superadmin'), false)
    OR (NOT coalesce(p_nur_superadmin, false) AND coalesce(ally_hat_recht(x.matrix_user_id, 'admin'), false)))
  ORDER BY x.matrix_user_id COLLATE "C"
$function$;
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
CREATE OR REPLACE FUNCTION public.ally_update_host_verfuegbar(p_fassung text, p_commit text, p_datum text, p_neu text, p_quelle text, p_fehler text)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE
  z ally_update_stand; neu boolean; dt date; p text;
  sauber text := nullif(left(btrim(regexp_replace(coalesce(p_neu, ''), '[[:cntrl:]]+', ' ', 'g')), 1000), '');
BEGIN
  -- Migration 203 (Update-Knopf): Ergebnis der Suche des Update-Programms. p_fehler gesetzt: Suche gescheitert (Meldung speichern, Verfügbares bleibt).
  -- Sonst die neueste freigegebene Fassung laut fassungen/freigegeben.json des Auslieferungs-Repos: Nummer, Freigabe-Commit, Datum, kurzer Text „neu“ (optional)
  -- und der Commit des Auslieferungs-Repos, in dem sie gelesen wurde (Stand des Pakets). Neue Nummer oder neuer Commit: Frist beginnt neu. Ist sie neuer als die
  -- eingespielte (ally_update_offen), eine Benachrichtigung „Update verfügbar“ an Admins und Superadmins (einmal je Fassung und Commit). Ergebnis ok|offen, ok|aktuell, ok|fehler.
  INSERT INTO ally_update_stand (id) VALUES (1) ON CONFLICT (id) DO NOTHING;
  SELECT * INTO z FROM ally_update_stand x WHERE x.id = 1 FOR UPDATE;
  IF nullif(btrim(coalesce(p_fehler, '')), '') IS NOT NULL THEN
    UPDATE ally_update_stand x SET gesucht_am = now(), such_fehler = left(btrim(regexp_replace(p_fehler, '[[:cntrl:]]+', ' ', 'g')), 1000), geaendert_am = now() WHERE x.id = 1;
    RETURN 'ok|fehler';
  END IF;
  IF coalesce(p_fassung, '') !~ '^[0-9]{1,3}[.][0-9]{1,3}$' OR coalesce(p_commit, '') !~ '^[0-9a-f]{7,40}$' OR coalesce(p_quelle, '') !~ '^[0-9a-f]{40}$' THEN
    RETURN 'Angaben ungültig';
  END IF;
  IF coalesce(p_datum, '') ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN
    BEGIN dt := to_date(p_datum, 'YYYY-MM-DD'); EXCEPTION WHEN OTHERS THEN dt := NULL; END;
  END IF;
  neu := z.verfuegbar COLLATE "C" IS DISTINCT FROM p_fassung OR z.verfuegbar_commit COLLATE "C" IS DISTINCT FROM p_commit;
  UPDATE ally_update_stand x SET verfuegbar = p_fassung, verfuegbar_commit = p_commit, verfuegbar_datum = dt, verfuegbar_neu = sauber, verfuegbar_quelle = p_quelle,
    verfuegbar_seit = CASE WHEN neu OR x.verfuegbar_seit IS NULL THEN now() ELSE x.verfuegbar_seit END,
    frist_gemeldet_am = CASE WHEN neu THEN NULL ELSE x.frist_gemeldet_am END,
    gesucht_am = now(), such_fehler = NULL, geaendert_am = now()
  WHERE x.id = 1;
  IF NOT ally_update_offen() THEN RETURN 'ok|aktuell'; END IF;
  FOR p IN SELECT ally_update_empfaenger(false) LOOP
    PERFORM ally_benachrichtigen(p, 'update_verfuegbar', 'Update verfügbar: Fassung ' || p_fassung,
      'Eine neue Fassung ist freigegeben.' || coalesce(' ' || sauber, '') || ' Einspielen unter Einstellungen › System › Updates, bis spätestens '
        || to_char(ally_update_frist() AT TIME ZONE 'Europe/Berlin', 'DD.MM.YYYY') || '.',
      jsonb_build_object('seite', 'einstellungen', 'parameter', jsonb_build_object('bereich', 'updates')), 'update:' || p_fassung || ':' || left(p_commit, 12), 'Updates', false);
  END LOOP;
  RETURN 'ok|offen';
END $function$;
CREATE OR REPLACE FUNCTION public.ally_update_host_schritt(p_lauf bigint, p_schritt text, p_ergebnis text, p_text text)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
BEGIN
  -- Migration 203 (Update-Knopf): Schritt eines laufenden Updates ins Protokoll (ally_updates.schritte): Name, Ergebnis (ok, fehler, uebersprungen, info), Text, Uhrzeit.
  -- Schritt „sichern“ mit ok: p_text = Ordner der Sicherung auf dem Server (ally_updates.sicherungen.ordner). Höchstens 200 Schritte je Lauf (darüber Ergebnis „Grenze von 200 Schritten erreicht“; das Programm hat eigene Merker).
  IF coalesce(p_schritt, '') !~ '^[a-z0-9_. -]{1,40}$' OR coalesce(p_ergebnis, '') COLLATE "C" NOT IN ('ok', 'fehler', 'uebersprungen', 'info') THEN RETURN 'Angaben ungültig'; END IF;
  IF EXISTS (SELECT 1 FROM ally_updates x WHERE x.id = p_lauf AND x.status COLLATE "C" = 'laeuft' AND jsonb_array_length(x.schritte) >= 200) THEN
    RETURN 'Grenze von 200 Schritten erreicht';
  END IF;
  UPDATE ally_updates x SET schritte = x.schritte || jsonb_build_array(jsonb_build_object('schritt', p_schritt, 'ergebnis', p_ergebnis,
      'text', nullif(left(btrim(regexp_replace(coalesce(p_text, ''), '[[:cntrl:]]+', ' ', 'g')), 1000), ''), 'zeit', to_char(now() AT TIME ZONE 'Europe/Berlin', 'HH24:MI:SS'))),
    sicherungen = CASE WHEN p_schritt COLLATE "C" = 'sichern' AND p_ergebnis COLLATE "C" = 'ok' AND coalesce(p_text, '') ~ '^/[A-Za-z0-9._/-]{1,200}$'
      THEN x.sicherungen || jsonb_build_object('ordner', p_text) ELSE x.sicherungen END
  WHERE x.id = p_lauf AND x.status COLLATE "C" = 'laeuft' AND jsonb_array_length(x.schritte) < 200;
  IF NOT FOUND THEN RETURN 'kein laufender Lauf'; END IF;
  RETURN 'ok';
END $function$;
CREATE OR REPLACE FUNCTION public.ally_update_host_ende(p_lauf bigint, p_status text, p_ergebnis text, p_unvollstaendig boolean, p_detail text)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE
  u ally_updates; p text; t text; c text; d text := nullif(left(btrim(regexp_replace(coalesce(p_detail, ''), '[[:cntrl:]]+', ' ', 'g')), 2000), '');
  ziel jsonb := jsonb_build_object('seite', 'einstellungen', 'parameter', jsonb_build_object('bereich', 'updates'));
BEGIN
  -- Migration 203 (Update-Knopf): Ende eines Updates. ok: neue Fassung mit Freigabe-Commit in ally_fassung (gilt ab jetzt), Mitteilung an die Person, die gedrückt hat.
  -- zurueckgenommen (Rückweg vollständig) oder fehler (vor jeder Änderung gescheitert; mit p_unvollstaendig: Rückweg unvollständig): Fassung bleibt, Meldung
  -- „Systemfehler“ an Admins und Superadmins mit dem Grund. Ergebnistext (verständlich) ohne Steuerzeichen, gekürzt; p_detail = Rohtext (z. B. psql-Fehler,
  -- Ordner der Sicherung) nur in sicherungen.detail und in den Meldungen an Superadmins.
  IF p_status IS NULL OR p_status COLLATE "C" NOT IN ('ok', 'fehler', 'zurueckgenommen') THEN RETURN 'Ergebnis ungültig'; END IF;
  UPDATE ally_updates x SET status = p_status, beendet_am = now(),
    ergebnis = nullif(left(btrim(regexp_replace(coalesce(p_ergebnis, ''), '[[:cntrl:]]+', ' ', 'g')), 4000), ''),
    sicherungen = CASE WHEN d IS NOT NULL THEN x.sicherungen || jsonb_build_object('detail', d) ELSE x.sicherungen END
  WHERE x.id = p_lauf AND x.status COLLATE "C" = 'laeuft'
  RETURNING * INTO u;
  IF NOT FOUND THEN RETURN 'kein laufender Lauf'; END IF;
  IF p_status COLLATE "C" = 'ok' THEN
    c := CASE WHEN coalesce(u.sicherungen->>'zu_commit', '') ~ '^[0-9a-f]{7,40}$' THEN u.sicherungen->>'zu_commit' END;
    INSERT INTO ally_fassung (nummer, git_commit, eingespielt_von) VALUES (u.zu_fassung, c, u.person)
    ON CONFLICT (nummer) DO UPDATE SET git_commit = EXCLUDED.git_commit, eingespielt_am = now(), eingespielt_von = EXCLUDED.eingespielt_von;
    PERFORM ally_benachrichtigen(u.person, 'mitteilung', 'Update eingespielt: Fassung ' || u.zu_fassung,
      'Das Update auf Fassung ' || u.zu_fassung || ' ist eingespielt. Bitte die Seite neu laden.', ziel, 'update-lauf:' || u.id, 'Updates', false);
  ELSE
    t := CASE WHEN coalesce(p_unvollstaendig, false)
      THEN 'Das Update auf Fassung ' || u.zu_fassung || ' ist fehlgeschlagen und ließ sich nicht vollständig zurücknehmen. Bitte sofort den Anbieter informieren.'
      ELSE 'Das Update auf Fassung ' || u.zu_fassung || ' war nicht möglich. Alles läuft unverändert weiter.' END || coalesce(' Grund: ' || u.ergebnis, '');
    -- Admins nur der verständliche Grund; Superadmins zusätzlich Einzelheiten und Ordner der Sicherung
    FOR p IN SELECT ally_update_empfaenger(false) LOOP
      PERFORM ally_benachrichtigen(p, 'systemfehler', CASE WHEN coalesce(p_unvollstaendig, false) THEN 'Update fehlgeschlagen' ELSE 'Update nicht möglich' END,
        t || CASE WHEN coalesce(ally_hat_recht(p, 'superadmin'), false) THEN coalesce(' Einzelheiten: ' || d, '') || coalesce(' Sicherung: ' || (u.sicherungen->>'ordner'), '') ELSE '' END,
        ziel, 'update-lauf:' || u.id, 'Updates', false);
    END LOOP;
  END IF;
  RETURN 'ok';
END $function$;
CREATE OR REPLACE FUNCTION public.ally_update_host_zurueckgesetzt(p_lauf bigint, p_ok boolean, p_text text)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE
  z ally_update_stand; u ally_updates; p text;
  d text := nullif(left(btrim(regexp_replace(coalesce(p_text, ''), '[[:cntrl:]]+', ' ', 'g')), 2000), '');
  ziel jsonb := jsonb_build_object('seite', 'einstellungen', 'parameter', jsonb_build_object('bereich', 'updates'));
BEGIN
  -- Migration 203 (Update-Knopf): Ergebnis des Zurücksetzens eines hart abgebrochenen Laufs (ally_update_host_plan: zuruecksetzen). ok: Sperre aufheben, Lauf gilt als
  -- zurückgenommen. Nicht ok: Sperre bleibt (abgebrochen_stand pruefen), der Anbieter prüft den Stand und hebt die Sperre auf (up_freigeben). Meldung an die Superadmins.
  SELECT * INTO z FROM ally_update_stand x WHERE x.id = 1 FOR UPDATE;
  IF NOT FOUND OR z.abgebrochen_lauf IS DISTINCT FROM p_lauf OR z.abgebrochen_stand COLLATE "C" IS DISTINCT FROM 'zuruecksetzen' THEN RETURN 'kein abgebrochener Lauf'; END IF;
  SELECT * INTO u FROM ally_updates x WHERE x.id = p_lauf;
  IF coalesce(p_ok, false) THEN
    UPDATE ally_update_stand x SET abgebrochen_lauf = NULL, abgebrochen_stand = NULL, abgebrochen_ordner = NULL, geaendert_am = now() WHERE x.id = 1;
    UPDATE ally_updates x SET status = 'zurueckgenommen', ergebnis = 'Das Update wurde abgebrochen. Der Stand ist zurückgesetzt, alles läuft wie vorher.',
      sicherungen = CASE WHEN d IS NOT NULL THEN x.sicherungen || jsonb_build_object('detail', d) ELSE x.sicherungen END WHERE x.id = p_lauf;
  ELSE
    UPDATE ally_update_stand x SET abgebrochen_stand = 'pruefen', geaendert_am = now() WHERE x.id = 1;
    UPDATE ally_updates x SET ergebnis = 'Das Update wurde abgebrochen. Zurücksetzen nicht vollständig, der Anbieter prüft den Stand.',
      sicherungen = CASE WHEN d IS NOT NULL THEN x.sicherungen || jsonb_build_object('detail', d) ELSE x.sicherungen END WHERE x.id = p_lauf;
  END IF;
  FOR p IN SELECT ally_update_empfaenger(true) LOOP
    PERFORM ally_benachrichtigen(p, 'systemfehler', CASE WHEN coalesce(p_ok, false) THEN 'Abgebrochenes Update zurückgesetzt' ELSE 'Update: Stand prüfen' END,
      CASE WHEN coalesce(p_ok, false) THEN 'Das abgebrochene Update auf Fassung ' || coalesce(u.zu_fassung, '?') || ' ist zurückgesetzt. Updates sind wieder möglich.'
        ELSE 'Das abgebrochene Update auf Fassung ' || coalesce(u.zu_fassung, '?') || ' ließ sich nicht vollständig zurücksetzen. Updates bleiben gesperrt, bis der Stand geprüft ist.'
          || coalesce(' Einzelheiten: ' || d, '') || coalesce(' Sicherung: ' || z.abgebrochen_ordner, '') END,
      ziel, 'update-zurueck:' || p_lauf, 'Updates', false);
  END LOOP;
  RETURN 'ok';
END $function$;
INSERT INTO public.ally_benachrichtigung_arten (schluessel, name, beschreibung, seite, standard_glocke, sortierung)
VALUES ('update_verfuegbar', 'Update verfügbar', 'Eine neue Fassung ist freigegeben, oder die Frist für das Update ist abgelaufen.', 'einstellungen', true, 11);
DO $m$
BEGIN
  IF (SELECT count(*) FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname::text = 'public' COLLATE "C" AND c.relkind = 'r' AND c.relname::text COLLATE "C" = 'ally_update_stand') <> 1 OR (SELECT md5(string_agg(z, E'\n' ORDER BY z COLLATE "C")) FROM (WITH t AS (SELECT c.oid, c.relname::text AS tab FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname::text = 'public' COLLATE "C" AND c.relkind::text = ANY (ARRAY['r', 'p']) AND c.relname::text = ANY (ARRAY['ally_update_stand'])) SELECT 'S|' || t.tab || '|' || a.attname::text || '|' || format_type(a.atttypid, a.atttypmod) || '|' || CASE WHEN a.attnotnull THEN 'NN' ELSE '-' END || '|' || coalesce(pg_get_expr(d.adbin, d.adrelid), '') || '|' || a.attidentity::text || a.attgenerated::text AS z FROM t JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum > 0 AND NOT a.attisdropped LEFT JOIN pg_attrdef d ON d.adrelid = t.oid AND d.adnum = a.attnum UNION ALL SELECT 'C|' || t.tab || '|' || co.conname::text || '|' || co.contype::text || '|' || pg_get_constraintdef(co.oid) FROM t JOIN pg_constraint co ON co.conrelid = t.oid UNION ALL SELECT 'I|' || t.tab || '|' || ic.relname::text || '|' || pg_get_indexdef(i.indexrelid) FROM t JOIN pg_index i ON i.indrelid = t.oid JOIN pg_class ic ON ic.oid = i.indexrelid UNION ALL SELECT 'T|' || t.tab || '|' || tg.tgname::text || '|' || pg_get_triggerdef(tg.oid) || '|' || tg.tgenabled::text FROM t JOIN pg_trigger tg ON tg.tgrelid = t.oid AND NOT tg.tgisinternal) x) IS DISTINCT FROM '262cae808bacef79d2fc48bd44ca308d' THEN RAISE EXCEPTION 'Migration 203: Tabelle ally_update_stand nicht wie gebaut'; END IF;
  IF (SELECT md5(string_agg(p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')|' || pg_get_function_result(p.oid) || '|' || md5(p.prosrc), E'\n' ORDER BY p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')' COLLATE "C")) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname::text = 'public' COLLATE "C" AND p.proname::text COLLATE "C" = ANY (ARRAY['ally_update_nummer', 'ally_update_stand_zeile', 'ally_update_installiert', 'ally_update_offen', 'ally_update_frist', 'ally_update_empfaenger', 'ally_update_ui', 'ally_update_ui_aktion', 'ally_update_host_plan', 'ally_update_host_verfuegbar', 'ally_update_host_schritt', 'ally_update_host_ende', 'ally_update_host_zurueckgesetzt'])) IS DISTINCT FROM '135ac6b7a33661d8a5c4a6086ab587f1' THEN RAISE EXCEPTION 'Migration 203: Funktionen des Update-Knopfs nicht wie gebaut'; END IF;
  IF (SELECT to_jsonb(x)::text FROM ally_benachrichtigung_arten x WHERE x.schluessel COLLATE "C" = 'update_verfuegbar') IS DISTINCT FROM '{"name": "Update verfügbar", "seite": "einstellungen", "schluessel": "update_verfuegbar", "sortierung": 11, "beschreibung": "Eine neue Fassung ist freigegeben, oder die Frist für das Update ist abgelaufen.", "standard_glocke": true}' THEN RAISE EXCEPTION 'Migration 203: Benachrichtigungsart update_verfuegbar nicht wie gebaut'; END IF;
  IF (SELECT count(*) FROM public.ally_update_stand) <> 0 THEN RAISE EXCEPTION 'Migration 203: neue Tabelle nicht leer'; END IF;
  IF (SELECT md5(string_agg(z, E'\n' ORDER BY z COLLATE "C")) FROM (WITH t AS (SELECT c.oid, c.relname::text AS tab FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname::text = 'public' COLLATE "C" AND c.relkind::text = ANY (ARRAY['r', 'p']) AND c.relname::text = ANY (ARRAY['ally_benachrichtigung_arten', 'ally_benachrichtigung_schalter', 'ally_benachrichtigungen', 'ally_fassung', 'ally_updates'])) SELECT 'S|' || t.tab || '|' || a.attname::text || '|' || format_type(a.atttypid, a.atttypmod) || '|' || CASE WHEN a.attnotnull THEN 'NN' ELSE '-' END || '|' || coalesce(pg_get_expr(d.adbin, d.adrelid), '') || '|' || a.attidentity::text || a.attgenerated::text AS z FROM t JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum > 0 AND NOT a.attisdropped LEFT JOIN pg_attrdef d ON d.adrelid = t.oid AND d.adnum = a.attnum UNION ALL SELECT 'C|' || t.tab || '|' || co.conname::text || '|' || co.contype::text || '|' || pg_get_constraintdef(co.oid) FROM t JOIN pg_constraint co ON co.conrelid = t.oid UNION ALL SELECT 'I|' || t.tab || '|' || ic.relname::text || '|' || pg_get_indexdef(i.indexrelid) FROM t JOIN pg_index i ON i.indrelid = t.oid JOIN pg_class ic ON ic.oid = i.indexrelid UNION ALL SELECT 'T|' || t.tab || '|' || tg.tgname::text || '|' || pg_get_triggerdef(tg.oid) || '|' || tg.tgenabled::text FROM t JOIN pg_trigger tg ON tg.tgrelid = t.oid AND NOT tg.tgisinternal) x) IS DISTINCT FROM 'add36aa8555c88a433c3f752f661864a' THEN RAISE EXCEPTION 'Migration 203: Aufbau von ally_updates, ally_fassung oder der Benachrichtigungen geändert'; END IF;
END $m$;
