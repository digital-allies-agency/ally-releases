-- Rückbau 208: Rechte, Seiten, Paket, Benachrichtigungsart und Schalter wie vor 208, talents_ki_einstellungen_aktion wörtlich wie vorher (werkzeuge/m208/vorher/),
-- neue Funktionen entfernen. Ohne Datenverlust: die Tabellen von 208 bleiben mit allen Briefings, Ergebnissen und Läufen als …_rb208 stehen; die alten Tabellen
-- talents_briefings* hat 208 nicht verändert. Vorher die Abläufe ALLY 1, 4, 20, 22, 23, 24, 33, 34, 38 auf den Stand vor 208 zurücksetzen (werkzeuge/sammel208/vorher/)
-- und den Ablauf „TALENTS Wochen-Briefing“ wieder aktivieren (208 liefert ihn nicht mehr aus, live archiviert); der Merker briefing_standard entfällt.
-- Nur auf dem Stand von 208. Läuft als Ganzes in der Transaktion des Aufrufs (psql -1).
DO $m$
BEGIN
  IF (SELECT md5(string_agg(p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')|' || pg_get_function_result(p.oid) || '|' || md5(p.prosrc), E'\n' ORDER BY p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')' COLLATE "C")) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname::text = 'public' COLLATE "C" AND p.proname::text COLLATE "C" = ANY (ARRAY['talents_ki_einstellungen_aktion', 'briefing_periode', 'briefing_zeitplan_text', 'briefing_darf', 'briefing_talents_fuer', 'briefing_talents_waise', 'briefing_manager', 'briefing_empfaenger_alle', 'briefing_empfaenger', 'briefing_naechster', 'briefing_sichtbar', 'briefing_bausteine_fuer', 'briefing_ergebnis_lesbar', 'briefing_kopf', 'briefing_standard_anlegen', 'briefing_bs_termine', 'briefing_bs_kunden_mails', 'briefing_bs_geschaeft_mails', 'briefing_bs_talents_zahlen', 'briefing_bs_talents_ki', 'briefing_bs_talents_ki_fertig', 'briefing_bs_talents_aufgaben', 'briefing_mail_standard', 'briefing_mail_platzhalter', 'briefing_mail_normal', 'briefing_html_text', 'briefing_absender', 'briefing_mail_bauen', 'briefing_faellig', 'briefing_ergebnis_bauen', 'briefing_abschluss', 'briefing_web', 'briefing_ui_aktion', 'briefing_meldung', 'briefing_kachel', 'briefing_talent_ui', 'briefing_start_stand', 'briefing_chat'])) IS NOT DISTINCT FROM '59b08691617ea4599c2307d7a183a10f' THEN RAISE EXCEPTION 'Rückbau 208: schon zurückgebaut, nichts geändert'; END IF;
  IF (SELECT md5(string_agg(p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')|' || pg_get_function_result(p.oid) || '|' || md5(p.prosrc), E'\n' ORDER BY p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')' COLLATE "C")) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname::text = 'public' COLLATE "C" AND p.proname::text COLLATE "C" = ANY (ARRAY['talents_ki_einstellungen_aktion', 'briefing_periode', 'briefing_zeitplan_text', 'briefing_darf', 'briefing_talents_fuer', 'briefing_talents_waise', 'briefing_manager', 'briefing_empfaenger_alle', 'briefing_empfaenger', 'briefing_naechster', 'briefing_sichtbar', 'briefing_bausteine_fuer', 'briefing_ergebnis_lesbar', 'briefing_kopf', 'briefing_standard_anlegen', 'briefing_bs_termine', 'briefing_bs_kunden_mails', 'briefing_bs_geschaeft_mails', 'briefing_bs_talents_zahlen', 'briefing_bs_talents_ki', 'briefing_bs_talents_ki_fertig', 'briefing_bs_talents_aufgaben', 'briefing_mail_standard', 'briefing_mail_platzhalter', 'briefing_mail_normal', 'briefing_html_text', 'briefing_absender', 'briefing_mail_bauen', 'briefing_faellig', 'briefing_ergebnis_bauen', 'briefing_abschluss', 'briefing_web', 'briefing_ui_aktion', 'briefing_meldung', 'briefing_kachel', 'briefing_talent_ui', 'briefing_start_stand', 'briefing_chat'])) IS DISTINCT FROM '7c02d8684853ff5d7fa12f82af3a2b5f' THEN RAISE EXCEPTION 'Rückbau 208: nicht im Stand von 208, nichts geändert'; END IF;
END $m$;
-- Rückbau 208: Rechte, Seiten, Paket, Benachrichtigungsart und Schalter wie vorher (aus briefing_m208_sicherung); was nur 208 kennt, bleibt erhalten:
-- Briefings, Inhalte, Teilen, Ergebnisse, Läufe und Aufträge als Tabellen …_rb208, Rechte „Briefings für andere“ als Zeilen in briefing_m208_sicherung_rb208.
INSERT INTO public.briefing_m208_sicherung (art, schluessel, daten)
SELECT 'rb_rolle_recht', rr.rolle || '|' || rr.recht, to_jsonb(rr) FROM public.ally_rollen_rechte rr WHERE rr.recht = 'briefing_andere'
UNION ALL SELECT 'rb_person_recht', pr.person || '|' || pr.recht, to_jsonb(pr) FROM public.ally_person_rechte pr WHERE pr.recht = 'briefing_andere'
ON CONFLICT (art, schluessel) DO UPDATE SET daten = EXCLUDED.daten;
INSERT INTO public.ally_rechte SELECT (jsonb_populate_record(NULL::public.ally_rechte, x.daten)).* FROM public.briefing_m208_sicherung x WHERE x.art = 'recht' AND x.schluessel = 'morgen_briefing';
UPDATE public.ally_rechte z SET name = q.name, beschreibung = q.beschreibung, katalog_name = q.katalog_name, katalog_text = q.katalog_text
FROM (SELECT (jsonb_populate_record(NULL::public.ally_rechte, x.daten)).* FROM public.briefing_m208_sicherung x WHERE x.art = 'recht' AND x.schluessel = 'briefings') q
WHERE z.schluessel = 'briefings';
-- von 208 dazugegebene Rechte wieder weg, danach „Briefing“ wieder „Morgen-Briefing“ (auch Rechte, die nach 208 vergeben wurden)
DELETE FROM public.ally_rollen_rechte rr USING public.briefing_m208_sicherung x WHERE x.art = 'rolle_dazu' AND rr.rolle = x.daten->>'rolle' AND rr.recht = x.daten->>'recht';
DELETE FROM public.ally_person_rechte pr USING public.briefing_m208_sicherung x WHERE x.art = 'person_dazu' AND pr.person = x.daten->>'person' AND pr.recht = 'briefing';
DELETE FROM public.ally_rollen_rechte WHERE recht = 'briefing_andere';
DELETE FROM public.ally_person_rechte WHERE recht = 'briefing_andere';
UPDATE public.ally_rollen_rechte SET recht = 'morgen_briefing' WHERE recht = 'briefing';
UPDATE public.ally_person_rechte SET recht = 'morgen_briefing' WHERE recht = 'briefing';
UPDATE public.ally_rollen ro SET rechte = array_replace(array_remove(ro.rechte, 'briefing_andere'), 'briefing', 'morgen_briefing') WHERE ro.rechte && ARRAY['briefing', 'briefing_andere'];
UPDATE public.ally_rollen ro SET standard = CASE WHEN x.daten->'standard' ? 'morgen_briefing' AND ro.standard ? 'briefing'
                                                 THEN (ro.standard - 'briefing' - 'briefing_andere') || jsonb_build_object('morgen_briefing', ro.standard->'briefing')
                                                 ELSE ro.standard - 'briefing' - 'briefing_andere' END
FROM public.briefing_m208_sicherung x WHERE x.art = 'rolle' AND x.schluessel = ro.schluessel AND ro.standard IS NOT NULL;
UPDATE public.ally_rollen ro SET standard = (ro.standard - 'briefing') || jsonb_build_object('morgen_briefing', ro.standard->'briefing')
WHERE ro.standard ? 'briefing' AND NOT EXISTS (SELECT 1 FROM public.briefing_m208_sicherung x WHERE x.art = 'rolle' AND x.schluessel = ro.schluessel);
UPDATE public.ally_rollen ro SET standard = ro.standard - 'briefing_andere' WHERE ro.standard ? 'briefing_andere';
UPDATE public.ally_rollen SET beschreibung = replace(beschreibung, 'Briefing.', 'Morgen-Briefing.') WHERE vorlage IN ('anwender', 'mitarbeiter') AND beschreibung LIKE '%und Briefing.%';
-- Seiten, Paket, Benachrichtigungsart wie vorher
UPDATE public.ally_ui_funktionen f SET name = q.name, beschreibung = q.beschreibung, recht = q.recht, modul = q.modul, workflow_id = q.workflow_id,
  einstellungen_ziel = q.einstellungen_ziel, leiste_aktiv = q.leiste_aktiv
FROM (SELECT (jsonb_populate_record(NULL::public.ally_ui_funktionen, x.daten)).* FROM public.briefing_m208_sicherung x WHERE x.art = 'ui_funktion') q WHERE f.schluessel = q.schluessel;
DELETE FROM public.ally_rechte WHERE schluessel IN ('briefing', 'briefing_andere');
UPDATE public.plattform_module m SET name = q.name, beschreibung = q.beschreibung
FROM (SELECT (jsonb_populate_record(NULL::public.plattform_module, x.daten)).* FROM public.briefing_m208_sicherung x WHERE x.art = 'modul') q WHERE m.schluessel = q.schluessel;
UPDATE public.ally_benachrichtigung_arten a SET name = q.name, beschreibung = q.beschreibung
FROM (SELECT (jsonb_populate_record(NULL::public.ally_benachrichtigung_arten, x.daten)).* FROM public.briefing_m208_sicherung x WHERE x.art = 'benachrichtigung_art') q WHERE a.schluessel = q.schluessel;
-- Schalter „Morgen-Briefing“ und „Talents: KI-Analysen“ wie vorher
INSERT INTO public.ally_funktionen SELECT (jsonb_populate_record(NULL::public.ally_funktionen, x.daten)).* FROM public.briefing_m208_sicherung x WHERE x.art = 'funktion'
ON CONFLICT (schluessel) DO NOTHING;
-- Merker „Standard-Briefing angelegt“ gibt es nur mit 208 (Prüfung N2)
DELETE FROM public.ally_nutzer_einstellungen WHERE schluessel = 'briefing_standard';
INSERT INTO public.ally_nutzer_funktionen SELECT (jsonb_populate_record(NULL::public.ally_nutzer_funktionen, x.daten)).* FROM public.briefing_m208_sicherung x WHERE x.art = 'nutzer_funktion'
ON CONFLICT (matrix_user_id, schluessel) DO NOTHING;
CREATE OR REPLACE FUNCTION public.talents_ki_einstellungen_aktion(p_token text, p_daten jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
  d jsonb := CASE WHEN jsonb_typeof(p_daten) = 'object' THEN p_daten ELSE '{}'::jsonb END;
  s jsonb := talents_ki_sitzung(p_token);
  u text;
BEGIN
  IF NOT coalesce((s->>'ok')::boolean, false) THEN
    RETURN s;
  END IF;
  IF NOT coalesce((s->>'admin')::boolean, false) THEN
    RETURN jsonb_build_object('ok', false, 'angemeldet', true, 'fehler', 'Diese Einstellungen dürfen nur Admins ändern.');
  END IF;
  u := s->>'u';
  -- Migration 180 (KI-Analyse): Tag und Uhrzeit nur, solange die Standard-Analyse wöchentlich läuft (sonst stellt man sie auf ihrer Seite ein)
  IF EXISTS (SELECT 1 FROM talents_briefings x WHERE x.standard AND x.geloescht_am IS NULL AND x.intervall = 'woche') AND coalesce(d->>'briefing_tag', '') !~ '^[1-7]$' THEN
    RETURN jsonb_build_object('ok', false, 'angemeldet', true, 'fehler', 'Bitte einen Wochentag für die Wochenanalyse wählen.');
  END IF;
  IF EXISTS (SELECT 1 FROM talents_briefings x WHERE x.standard AND x.geloescht_am IS NULL AND x.intervall = 'woche')
     AND coalesce(d->>'briefing_uhrzeit', '') !~ '^([01][0-9]|2[0-3]):[0-5][0-9]$' THEN
    RETURN jsonb_build_object('ok', false, 'angemeldet', true, 'fehler', 'Bitte die Uhrzeit als SS:MM angeben, z. B. 08:00.');
  END IF;
  IF coalesce(d->>'abweichung_prozent', '') !~ '^[0-9]{1,3}$' OR (d->>'abweichung_prozent')::integer NOT BETWEEN 10 AND 90 THEN
    RETURN jsonb_build_object('ok', false, 'angemeldet', true, 'fehler', 'Die Schwelle für „deutlich abweichend“ muss zwischen 10 und 90 Prozent liegen.');
  END IF;
  IF coalesce(d->>'marken_anzahl', '') !~ '^[0-9]{1,2}$' OR (d->>'marken_anzahl')::integer NOT BETWEEN 1 AND 12 THEN
    RETURN jsonb_build_object('ok', false, 'angemeldet', true, 'fehler', 'Treffer je Marken-Suche: 1 bis 12.');
  END IF;
  IF coalesce(d->>'marken_websuchen', '') !~ '^[0-9]{1,2}$' OR (d->>'marken_websuchen')::integer NOT BETWEEN 1 AND 10 THEN
    RETURN jsonb_build_object('ok', false, 'angemeldet', true, 'fehler', 'Websuchen je Marken-Suche: 1 bis 10.');
  END IF;
  -- Migration 175 (B10a, Briefing): Tag und Uhrzeit stehen im Briefing für Manager/innen (fixiert wie bisher über den Trigger, Einstellung talents_ki)
  -- Migration 180: nur die Standard-Analyse; gibt es sie nicht mehr (gelöscht), legt diese Einstellung keine neue an (Stefan 30.10.2026)
  UPDATE talents_briefings b SET tag = CASE WHEN coalesce(d->>'briefing_tag', '') ~ '^[1-7]$' THEN (d->>'briefing_tag')::smallint END, uhrzeit = d->>'briefing_uhrzeit',
    geaendert_am = now(), geaendert_von = u
    WHERE b.standard AND b.geloescht_am IS NULL AND b.intervall = 'woche' AND coalesce(d->>'briefing_tag', '') ~ '^[1-7]$'
      AND coalesce(d->>'briefing_uhrzeit', '') ~ '^([01][0-9]|2[0-3]):[0-5][0-9]$';
  PERFORM ally_einstellung_setzen('talents_konzept_abweichung_prozent', ((d->>'abweichung_prozent')::integer)::text, u);
  PERFORM ally_einstellung_setzen('talents_markensuche_anzahl', ((d->>'marken_anzahl')::integer)::text, u);
  PERFORM ally_einstellung_setzen('talents_markensuche_websuchen', ((d->>'marken_websuchen')::integer)::text, u);
  RETURN jsonb_build_object('ok', true, 'angemeldet', true, 'meldung', 'Einstellungen gespeichert.');
END $function$;
DROP FUNCTION public.briefing_chat(p_person text, p_aktion text, p_uhrzeit text, p_briefing text);
DROP FUNCTION public.briefing_start_stand(p_token text);
DROP FUNCTION public.briefing_talent_ui(p_token text);
DROP FUNCTION public.briefing_kachel(p_token text);
DROP FUNCTION public.briefing_meldung(p_token text, p_nutzer text);
DROP FUNCTION public.briefing_ui_aktion(p_token text, p_csrf text, p_aktion text, p_daten jsonb, p_zustand jsonb);
DROP FUNCTION public.briefing_web(p_token text, p_param jsonb);
DROP FUNCTION public.briefing_abschluss(p_ergebnis bigint, p_e jsonb);
DROP FUNCTION public.briefing_ergebnis_bauen(p_auftrag jsonb, p_google jsonb, p_ki_text text, p_ablauf jsonb, p_test boolean);
DROP FUNCTION public.briefing_faellig(p_test boolean, p_nur text);
DROP FUNCTION public.briefing_mail_bauen(p_id integer, p_person text, p_an text, p_wer text, p_html text, p_text text, p_werte jsonb);
DROP FUNCTION public.briefing_absender(p_id integer);
DROP FUNCTION public.briefing_html_text(p_html text);
DROP FUNCTION public.briefing_mail_normal(p_wert text, p_art text);
DROP FUNCTION public.briefing_mail_platzhalter();
DROP FUNCTION public.briefing_mail_standard();
DROP FUNCTION public.briefing_bs_talents_aufgaben(p_person text, p_optionen jsonb, p_heute date);
DROP FUNCTION public.briefing_bs_talents_ki_fertig(p_ki_text text, p_daten jsonb);
DROP FUNCTION public.briefing_bs_talents_ki(p_person text, p_optionen jsonb, p_heute date);
DROP FUNCTION public.briefing_bs_talents_zahlen(p_person text, p_optionen jsonb, p_heute date);
DROP FUNCTION public.briefing_bs_geschaeft_mails(p_person text, p_optionen jsonb, p_heute date);
DROP FUNCTION public.briefing_bs_kunden_mails(p_person text, p_optionen jsonb, p_heute date);
DROP FUNCTION public.briefing_bs_termine(p_person text, p_optionen jsonb, p_heute date);
DROP FUNCTION public.briefing_standard_anlegen(p_person text);
DROP FUNCTION public.briefing_kopf(p_ergebnis bigint);
DROP FUNCTION public.briefing_ergebnis_lesbar(p_person text, p_ergebnis bigint);
DROP FUNCTION public.briefing_bausteine_fuer(p_person text);
DROP FUNCTION public.briefing_sichtbar(p_person text, p_id integer);
DROP FUNCTION public.briefing_naechster(p_id integer);
DROP FUNCTION public.briefing_empfaenger(p_id integer);
DROP FUNCTION public.briefing_empfaenger_alle(p_id integer);
DROP FUNCTION public.briefing_manager(p_id integer);
DROP FUNCTION public.briefing_talents_waise();
DROP FUNCTION public.briefing_talents_fuer(p_person text, p_optionen jsonb);
DROP FUNCTION public.briefing_darf(p_person text);
DROP FUNCTION public.briefing_zeitplan_text(p_an boolean, p_rhythmus text, p_tag integer, p_uhrzeit text);
DROP FUNCTION public.briefing_periode(p_rhythmus text, p_heute date);
ALTER TABLE public.briefing_bausteine RENAME TO briefing_bausteine_rb208;
ALTER TABLE public.briefings RENAME TO briefings_rb208;
ALTER TABLE public.briefing_inhalte RENAME TO briefing_inhalte_rb208;
ALTER TABLE public.briefing_teilen RENAME TO briefing_teilen_rb208;
ALTER TABLE public.briefing_abbestellt RENAME TO briefing_abbestellt_rb208;
ALTER TABLE public.briefing_ergebnisse RENAME TO briefing_ergebnisse_rb208;
ALTER TABLE public.briefing_laeufe RENAME TO briefing_laeufe_rb208;
ALTER TABLE public.briefing_jetzt RENAME TO briefing_jetzt_rb208;
ALTER TABLE public.briefing_m208_sicherung RENAME TO briefing_m208_sicherung_rb208;
ALTER SEQUENCE public.briefing_ergebnisse_id_seq RENAME TO briefing_ergebnisse_id_seq_rb208;
ALTER SEQUENCE public.briefings_id_seq RENAME TO briefings_id_seq_rb208;
ALTER INDEX public.briefing_abbestellt_pkey RENAME TO briefing_abbestellt_pkey_rb208;
ALTER INDEX public.briefing_bausteine_pkey RENAME TO briefing_bausteine_pkey_rb208;
ALTER INDEX public.briefing_ergebnisse_alt_id_key RENAME TO briefing_ergebnisse_alt_id_key_rb208;
ALTER INDEX public.briefing_ergebnisse_briefing RENAME TO briefing_ergebnisse_briefing_rb208;
ALTER INDEX public.briefing_ergebnisse_person RENAME TO briefing_ergebnisse_person_rb208;
ALTER INDEX public.briefing_ergebnisse_pkey RENAME TO briefing_ergebnisse_pkey_rb208;
ALTER INDEX public.briefing_ergebnisse_zeitplan RENAME TO briefing_ergebnisse_zeitplan_rb208;
ALTER INDEX public.briefing_inhalte_pkey RENAME TO briefing_inhalte_pkey_rb208;
ALTER INDEX public.briefing_jetzt_pkey RENAME TO briefing_jetzt_pkey_rb208;
ALTER INDEX public.briefing_laeufe_pkey RENAME TO briefing_laeufe_pkey_rb208;
ALTER INDEX public.briefing_m208_sicherung_pkey RENAME TO briefing_m208_sicherung_pkey_rb208;
ALTER INDEX public.briefing_teilen_pkey RENAME TO briefing_teilen_pkey_rb208;
ALTER INDEX public.briefings_alt RENAME TO briefings_alt_rb208;
ALTER INDEX public.briefings_ein_standard RENAME TO briefings_ein_standard_rb208;
ALTER INDEX public.briefings_person RENAME TO briefings_person_rb208;
ALTER INDEX public.briefings_pkey RENAME TO briefings_pkey_rb208;
DO $m$
BEGIN
  IF (SELECT md5(string_agg(p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')|' || pg_get_function_result(p.oid) || '|' || md5(p.prosrc), E'\n' ORDER BY p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')' COLLATE "C")) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname::text = 'public' COLLATE "C" AND p.proname::text COLLATE "C" = ANY (ARRAY['talents_ki_einstellungen_aktion', 'briefing_periode', 'briefing_zeitplan_text', 'briefing_darf', 'briefing_talents_fuer', 'briefing_talents_waise', 'briefing_manager', 'briefing_empfaenger_alle', 'briefing_empfaenger', 'briefing_naechster', 'briefing_sichtbar', 'briefing_bausteine_fuer', 'briefing_ergebnis_lesbar', 'briefing_kopf', 'briefing_standard_anlegen', 'briefing_bs_termine', 'briefing_bs_kunden_mails', 'briefing_bs_geschaeft_mails', 'briefing_bs_talents_zahlen', 'briefing_bs_talents_ki', 'briefing_bs_talents_ki_fertig', 'briefing_bs_talents_aufgaben', 'briefing_mail_standard', 'briefing_mail_platzhalter', 'briefing_mail_normal', 'briefing_html_text', 'briefing_absender', 'briefing_mail_bauen', 'briefing_faellig', 'briefing_ergebnis_bauen', 'briefing_abschluss', 'briefing_web', 'briefing_ui_aktion', 'briefing_meldung', 'briefing_kachel', 'briefing_talent_ui', 'briefing_start_stand', 'briefing_chat'])) IS DISTINCT FROM '59b08691617ea4599c2307d7a183a10f' THEN RAISE EXCEPTION 'Rückbau 208: Funktionen nicht wie vorher'; END IF;
END $m$;
