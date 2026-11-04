-- Rückbau 205 (interner Kalender): Funktionen wörtlich wie vorher (werkzeuge/m205/vorher/), die neuen Funktionen und die Tabellen kalender_termine,
-- kalender_termin_personen und kalender_quellen entfernen. Vorher ALLY 29 und ALLY 20 (und die Web-App, falls geändert) auf den Stand vor 205 zurücksetzen.
-- Keine Daten gehen verloren: der Inhalt der drei Tabellen kommt vorher in die Sicherungstabellen kalender_termine_rb205, kalender_termin_personen_rb205
-- und kalender_quellen_rb205. Nur auf dem Stand von 205. Läuft als Ganzes in der Transaktion des Aufrufs (psql -1).
DO $m$
BEGIN
  IF (SELECT md5(string_agg(p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')|' || pg_get_function_result(p.oid) || '|' || md5(p.prosrc), E'\n' ORDER BY p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')' COLLATE "C")) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname::text = 'public' COLLATE "C" AND p.proname::text COLLATE "C" = ANY (ARRAY['ally_kalender_ics', 'kalender_person_waehlbar', 'kalender_termin_sichtbar', 'kalender_zeit_lesen', 'kalender_termin_eintrag', 'kalender_eintraege', 'kalender_web_seite', 'kalender_web_aktion', 'kalender_ui_aktion', 'talents_kalender_eintraege', 'talents_kalender_aendern'])) IS NOT DISTINCT FROM '8beb9b7b809dba545a7b0a6e2569039c' AND (SELECT md5(string_agg(z, E'\n' ORDER BY z COLLATE "C")) FROM (WITH t AS (SELECT c.oid, c.relname::text AS tab FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname::text = 'public' COLLATE "C" AND c.relkind::text = ANY (ARRAY['r', 'p']) AND c.relname::text = ANY (ARRAY['kalender_termine', 'kalender_termin_personen', 'kalender_quellen'])) SELECT 'S|' || t.tab || '|' || a.attname::text || '|' || format_type(a.atttypid, a.atttypmod) || '|' || CASE WHEN a.attnotnull THEN 'NN' ELSE '-' END || '|' || coalesce(pg_get_expr(d.adbin, d.adrelid), '') || '|' || a.attidentity::text || a.attgenerated::text AS z FROM t JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum > 0 AND NOT a.attisdropped LEFT JOIN pg_attrdef d ON d.adrelid = t.oid AND d.adnum = a.attnum UNION ALL SELECT 'C|' || t.tab || '|' || co.conname::text || '|' || co.contype::text || '|' || pg_get_constraintdef(co.oid) FROM t JOIN pg_constraint co ON co.conrelid = t.oid UNION ALL SELECT 'I|' || t.tab || '|' || ic.relname::text || '|' || pg_get_indexdef(i.indexrelid) FROM t JOIN pg_index i ON i.indrelid = t.oid JOIN pg_class ic ON ic.oid = i.indexrelid UNION ALL SELECT 'T|' || t.tab || '|' || tg.tgname::text || '|' || pg_get_triggerdef(tg.oid) || '|' || tg.tgenabled::text FROM t JOIN pg_trigger tg ON tg.tgrelid = t.oid AND NOT tg.tgisinternal) x) IS NULL
    THEN RAISE EXCEPTION 'Rückbau 205: schon zurückgebaut, nichts geändert'; END IF;
  IF (SELECT md5(string_agg(p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')|' || pg_get_function_result(p.oid) || '|' || md5(p.prosrc), E'\n' ORDER BY p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')' COLLATE "C")) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname::text = 'public' COLLATE "C" AND p.proname::text COLLATE "C" = ANY (ARRAY['ally_kalender_ics', 'kalender_person_waehlbar', 'kalender_termin_sichtbar', 'kalender_zeit_lesen', 'kalender_termin_eintrag', 'kalender_eintraege', 'kalender_web_seite', 'kalender_web_aktion', 'kalender_ui_aktion', 'talents_kalender_eintraege', 'talents_kalender_aendern'])) IS DISTINCT FROM '2ed562ddf5beef8407cd01c517b68a88' OR (SELECT md5(string_agg(z, E'\n' ORDER BY z COLLATE "C")) FROM (WITH t AS (SELECT c.oid, c.relname::text AS tab FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname::text = 'public' COLLATE "C" AND c.relkind::text = ANY (ARRAY['r', 'p']) AND c.relname::text = ANY (ARRAY['kalender_termine', 'kalender_termin_personen', 'kalender_quellen'])) SELECT 'S|' || t.tab || '|' || a.attname::text || '|' || format_type(a.atttypid, a.atttypmod) || '|' || CASE WHEN a.attnotnull THEN 'NN' ELSE '-' END || '|' || coalesce(pg_get_expr(d.adbin, d.adrelid), '') || '|' || a.attidentity::text || a.attgenerated::text AS z FROM t JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum > 0 AND NOT a.attisdropped LEFT JOIN pg_attrdef d ON d.adrelid = t.oid AND d.adnum = a.attnum UNION ALL SELECT 'C|' || t.tab || '|' || co.conname::text || '|' || co.contype::text || '|' || pg_get_constraintdef(co.oid) FROM t JOIN pg_constraint co ON co.conrelid = t.oid UNION ALL SELECT 'I|' || t.tab || '|' || ic.relname::text || '|' || pg_get_indexdef(i.indexrelid) FROM t JOIN pg_index i ON i.indrelid = t.oid JOIN pg_class ic ON ic.oid = i.indexrelid UNION ALL SELECT 'T|' || t.tab || '|' || tg.tgname::text || '|' || pg_get_triggerdef(tg.oid) || '|' || tg.tgenabled::text FROM t JOIN pg_trigger tg ON tg.tgrelid = t.oid AND NOT tg.tgisinternal) x) IS DISTINCT FROM '22d524eb9633e7b5970679a1b37960c1' THEN RAISE EXCEPTION 'Rückbau 205: nicht im Stand von 205, nichts geändert'; END IF;
  IF (SELECT count(*) FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname::text = 'public' COLLATE "C" AND c.relname::text COLLATE "C" = ANY (ARRAY['kalender_termine_rb205', 'kalender_termin_personen_rb205', 'kalender_quellen_rb205'])) <> 0 THEN RAISE EXCEPTION 'Rückbau 205: Sicherungstabellen schon vorhanden, nichts geändert'; END IF;
  PERFORM set_config('m205.kalender_termine', (SELECT coalesce(md5(string_agg(to_jsonb(x)::text, E'\n' ORDER BY to_jsonb(x)::text COLLATE "C")), '-') FROM (SELECT * FROM public.kalender_termine) x), true);
  PERFORM set_config('m205.kalender_termin_personen', (SELECT coalesce(md5(string_agg(to_jsonb(x)::text, E'\n' ORDER BY to_jsonb(x)::text COLLATE "C")), '-') FROM (SELECT * FROM public.kalender_termin_personen) x), true);
  PERFORM set_config('m205.kalender_quellen', (SELECT coalesce(md5(string_agg(to_jsonb(x)::text, E'\n' ORDER BY to_jsonb(x)::text COLLATE "C")), '-') FROM (SELECT * FROM public.kalender_quellen) x), true);
END $m$;
CREATE TABLE public.kalender_termine_rb205 AS SELECT * FROM public.kalender_termine;
CREATE TABLE public.kalender_termin_personen_rb205 AS SELECT * FROM public.kalender_termin_personen;
CREATE TABLE public.kalender_quellen_rb205 AS SELECT * FROM public.kalender_quellen;
DO $m$
BEGIN
  IF current_setting('m205.kalender_termine') IS DISTINCT FROM (SELECT coalesce(md5(string_agg(to_jsonb(x)::text, E'\n' ORDER BY to_jsonb(x)::text COLLATE "C")), '-') FROM (SELECT * FROM public.kalender_termine_rb205) x) THEN RAISE EXCEPTION 'Rückbau 205: Sicherung von kalender_termine unvollständig, nichts geändert'; END IF;
  IF current_setting('m205.kalender_termin_personen') IS DISTINCT FROM (SELECT coalesce(md5(string_agg(to_jsonb(x)::text, E'\n' ORDER BY to_jsonb(x)::text COLLATE "C")), '-') FROM (SELECT * FROM public.kalender_termin_personen_rb205) x) THEN RAISE EXCEPTION 'Rückbau 205: Sicherung von kalender_termin_personen unvollständig, nichts geändert'; END IF;
  IF current_setting('m205.kalender_quellen') IS DISTINCT FROM (SELECT coalesce(md5(string_agg(to_jsonb(x)::text, E'\n' ORDER BY to_jsonb(x)::text COLLATE "C")), '-') FROM (SELECT * FROM public.kalender_quellen_rb205) x) THEN RAISE EXCEPTION 'Rückbau 205: Sicherung von kalender_quellen unvollständig, nichts geändert'; END IF;
END $m$;
CREATE OR REPLACE FUNCTION public.ally_kalender_ics(p_token text)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE
  a ally_kalender_abos%ROWTYPE; sicht jsonb; ev text := ''; name text; firma text; d_von date := talents_heute() - 60; d_bis date := talents_heute() + 400; n integer := 0; rec record;
BEGIN
  -- Kalender-Abo (ALLY 19, GET app/kalender?t=<Code>): NULL = unbekannt, widerrufen oder nicht mehr berechtigt (Antwort 404).
  -- Talent: nur eigene Einträge mit Kanal „Kalender des Talents“ (Termine/Erinnerungen bei „Termine“ sichtbar, Aufgaben/Reviews bei „Aufgaben“ sichtbar)
  -- und Deadlines eigener, für das Talent sichtbarer Deliverables. Person: Aufgaben, Termine und Deadlines der Talents, für die sie zuständig ist,
  -- und der Kampagnen, für die sie zuständig ist (nur Talents, die sie sehen darf). Keine Honorare, Budgets oder Notizen. Zeitraum 60 Tage zurück bis 400 Tage voraus.
  IF coalesce(p_token, '') !~ '^[0-9a-f]{64}$' THEN RETURN NULL; END IF;
  SELECT * INTO a FROM ally_kalender_abos x WHERE x.token_hash = ally_web_hash(p_token) AND x.widerrufen_am IS NULL;
  IF NOT FOUND THEN RETURN NULL; END IF;
  firma := coalesce(nullif(btrim(coalesce(eigenes_unternehmen()->>'name', '')), ''), produkt_name());
  IF a.talent_id IS NOT NULL THEN
    IF NOT plattform_modul_an('talents') OR NOT EXISTS (SELECT 1 FROM talents t WHERE t.id = a.talent_id AND t.status = 'aktiv')
       OR NOT EXISTS (SELECT 1 FROM talent_zugaenge z WHERE z.talent_id = a.talent_id AND z.aktiv) THEN
      RETURN NULL;
    END IF;
    sicht := talent_bereich_sicht(a.talent_id);
    name := firma || ' – Termine und Deadlines';
    FOR rec IN SELECT t.id FROM talent_aufgaben t
             WHERE t.talent_id = a.talent_id AND 'kalender' = ANY (t.kanaele) AND coalesce(t.beginn, t.faellig_am) IS NOT NULL
               AND (coalesce(t.beginn, t.faellig_am) AT TIME ZONE 'Europe/Berlin')::date BETWEEN d_von AND d_bis
               AND ((t.art IN ('termin', 'erinnerung') AND (sicht->>'termine')::boolean) OR (t.art IN ('aufgabe', 'review') AND (sicht->>'aufgaben')::boolean))
             ORDER BY coalesce(t.beginn, t.faellig_am), t.id LIMIT 600 LOOP
      ev := ev || coalesce(ally_ics_aufgabe(rec.id, false), ''); n := n + 1;
    END LOOP;
    IF (sicht->>'aufgaben')::boolean THEN
      FOR rec IN SELECT d.id, w.was FROM talent_deliverables d JOIN talent_kampagnen k ON k.id = d.kampagne_id AND k.abgebrochen_am IS NULL
               CROSS JOIN (VALUES ('deadline'), ('veroeffentlichung')) AS w(was)
               WHERE d.talent_id = a.talent_id AND d.sichtbar_fuer_talent
                 AND (CASE WHEN w.was = 'deadline' THEN d.deadline ELSE d.veroeffentlichen_am END) BETWEEN d_von AND d_bis
               ORDER BY d.deadline, d.id, w.was LIMIT 400 LOOP
        ev := ev || coalesce(ally_ics_deliverable(rec.id, rec.was, false), ''); n := n + 1;
      END LOOP;
    END IF;
  ELSE
    IF NOT EXISTS (SELECT 1 FROM ally_personen p WHERE p.matrix_user_id = a.person AND p.aktiv AND p.zugang_aktiv) THEN RETURN NULL; END IF;
    name := produkt_name() || ' – meine Termine und Deadlines';
    IF plattform_modul_an('talents') THEN
      FOR rec IN SELECT t.id FROM talent_aufgaben t JOIN talents tt ON tt.id = t.talent_id AND tt.status = 'aktiv'
               WHERE EXISTS (SELECT 1 FROM talent_personen tp WHERE tp.talent_id = t.talent_id AND tp.matrix_user_id = a.person)
                 AND coalesce(t.beginn, t.faellig_am) IS NOT NULL AND (coalesce(t.beginn, t.faellig_am) AT TIME ZONE 'Europe/Berlin')::date BETWEEN d_von AND d_bis
               ORDER BY coalesce(t.beginn, t.faellig_am), t.id LIMIT 600 LOOP
        ev := ev || coalesce(ally_ics_aufgabe(rec.id, true), ''); n := n + 1;
      END LOOP;
      FOR rec IN SELECT DISTINCT d.id, w.was, d.deadline FROM talent_deliverables d JOIN talent_kampagnen k ON k.id = d.kampagne_id AND k.abgebrochen_am IS NULL
               JOIN talents tt ON tt.id = d.talent_id AND tt.status = 'aktiv'
               CROSS JOIN (VALUES ('deadline'), ('veroeffentlichung')) AS w(was)
               WHERE (EXISTS (SELECT 1 FROM talent_personen tp WHERE tp.talent_id = d.talent_id AND tp.matrix_user_id = a.person)
                      OR (k.zustaendig = a.person AND coalesce(talent_sichtbar(a.person, d.talent_id), false)))
                 AND (CASE WHEN w.was = 'deadline' THEN d.deadline ELSE d.veroeffentlichen_am END) BETWEEN d_von AND d_bis
               ORDER BY d.deadline, d.id, w.was LIMIT 400 LOOP
        ev := ev || coalesce(ally_ics_deliverable(rec.id, rec.was, true), ''); n := n + 1;
      END LOOP;
    END IF;
  END IF;
  UPDATE ally_kalender_abos SET letzter_abruf = now(), abrufe = abrufe + 1 WHERE id = a.id;
  RETURN ally_ics_kalender(name, ev);
END $function$;
DROP FUNCTION public.talents_kalender_aendern(p_token text, p_eintrag text, p_daten jsonb);
DROP FUNCTION public.talents_kalender_eintraege(p_person text, p_von date, p_bis date, p_ics boolean);
DROP FUNCTION public.kalender_ui_aktion(p_sitzung text, p_csrf text, p_aktion text, p_daten jsonb, p_zustand jsonb);
DROP FUNCTION public.kalender_web_aktion(p_token text, p_aktion text, p_daten jsonb);
DROP FUNCTION public.kalender_web_seite(p_token text, p jsonb);
DROP FUNCTION public.kalender_eintraege(p_person text, p_von date, p_bis date, p_ics boolean);
DROP FUNCTION public.kalender_termin_eintrag(p_id bigint, p_ics boolean);
DROP FUNCTION public.kalender_zeit_lesen(p text);
DROP FUNCTION public.kalender_termin_sichtbar(p_person text, p_id bigint);
DROP FUNCTION public.kalender_person_waehlbar(p_person text);
DROP TABLE public.kalender_termin_personen;
DROP TABLE public.kalender_termine;
DROP TABLE public.kalender_quellen;
DO $m$
BEGIN
  IF (SELECT md5(string_agg(p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')|' || pg_get_function_result(p.oid) || '|' || md5(p.prosrc), E'\n' ORDER BY p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')' COLLATE "C")) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname::text = 'public' COLLATE "C" AND p.proname::text COLLATE "C" = ANY (ARRAY['ally_kalender_ics', 'kalender_person_waehlbar', 'kalender_termin_sichtbar', 'kalender_zeit_lesen', 'kalender_termin_eintrag', 'kalender_eintraege', 'kalender_web_seite', 'kalender_web_aktion', 'kalender_ui_aktion', 'talents_kalender_eintraege', 'talents_kalender_aendern'])) IS DISTINCT FROM '8beb9b7b809dba545a7b0a6e2569039c' THEN RAISE EXCEPTION 'Rückbau 205: Funktionen nicht wie vorher'; END IF;
  IF (SELECT md5(string_agg(z, E'\n' ORDER BY z COLLATE "C")) FROM (WITH t AS (SELECT c.oid, c.relname::text AS tab FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname::text = 'public' COLLATE "C" AND c.relkind::text = ANY (ARRAY['r', 'p']) AND c.relname::text = ANY (ARRAY['kalender_termine', 'kalender_termin_personen', 'kalender_quellen'])) SELECT 'S|' || t.tab || '|' || a.attname::text || '|' || format_type(a.atttypid, a.atttypmod) || '|' || CASE WHEN a.attnotnull THEN 'NN' ELSE '-' END || '|' || coalesce(pg_get_expr(d.adbin, d.adrelid), '') || '|' || a.attidentity::text || a.attgenerated::text AS z FROM t JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum > 0 AND NOT a.attisdropped LEFT JOIN pg_attrdef d ON d.adrelid = t.oid AND d.adnum = a.attnum UNION ALL SELECT 'C|' || t.tab || '|' || co.conname::text || '|' || co.contype::text || '|' || pg_get_constraintdef(co.oid) FROM t JOIN pg_constraint co ON co.conrelid = t.oid UNION ALL SELECT 'I|' || t.tab || '|' || ic.relname::text || '|' || pg_get_indexdef(i.indexrelid) FROM t JOIN pg_index i ON i.indrelid = t.oid JOIN pg_class ic ON ic.oid = i.indexrelid UNION ALL SELECT 'T|' || t.tab || '|' || tg.tgname::text || '|' || pg_get_triggerdef(tg.oid) || '|' || tg.tgenabled::text FROM t JOIN pg_trigger tg ON tg.tgrelid = t.oid AND NOT tg.tgisinternal) x) IS NOT NULL THEN RAISE EXCEPTION 'Rückbau 205: Tabellen des internen Kalenders noch vorhanden'; END IF;
  IF (SELECT count(*) FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname::text = 'public' COLLATE "C" AND c.relname::text COLLATE "C" = ANY (ARRAY['kalender_termine_rb205', 'kalender_termin_personen_rb205', 'kalender_quellen_rb205'])) <> 3 THEN RAISE EXCEPTION 'Rückbau 205: Sicherungstabellen fehlen'; END IF;
END $m$;
