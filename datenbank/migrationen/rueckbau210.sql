-- Rückbau 210: Auslöser der Kennungen entfernen, gemerkte Filter wieder an der Adresse mit Nummer, ally_ui_pfad wörtlich wie vor 210 (werkzeuge/m210/vorher/), neue Funktionen und das Muster /briefing/<Briefing>/<Ergebnis> entfernen. Ohne Datenverlust:
-- die Tabellen ally_ui_kennung_arten und ally_ui_kennungen bleiben als …_rb210 stehen. Danach den Ablauf ALLY 20 auf den Stand vor 210 zurücksetzen
-- (werkzeuge/sammel210/vorher/) und die Web-App der Fassung davor einspielen. Adressen haben dann wieder Nummern; Links mit Kennung führen nicht mehr zum Objekt.
-- Nur auf dem Stand von 210. Läuft als Ganzes in der Transaktion des Aufrufs (psql -1).
DO $m$
BEGIN
  IF (SELECT md5(string_agg(p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')|' || pg_get_function_result(p.oid) || '|' || md5(p.prosrc), E'\n' ORDER BY p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')' COLLATE "C")) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname::text = 'public' COLLATE "C" AND p.proname::text COLLATE "C" = ANY (ARRAY['ally_ui_pfad', 'ally_ui_kennung_text', 'ally_ui_kn_talent', 'ally_ui_kn_talent_darf', 'ally_ui_kn_kampagne', 'ally_ui_kn_kampagne_darf', 'ally_ui_kn_briefing', 'ally_ui_kn_briefing_darf', 'ally_ui_kn_ergebnis', 'ally_ui_kn_ergebnis_bereich', 'ally_ui_kn_ergebnis_darf', 'ally_ui_kn_person', 'ally_ui_kn_person_darf', 'ally_ui_kn_ordner', 'ally_ui_kn_ordner_darf', 'ally_ui_kn_termin', 'ally_ui_kn_termin_darf', 'ally_ui_kn_benachrichtigung', 'ally_ui_kn_benachrichtigung_bereich', 'ally_ui_kn_benachrichtigung_darf', 'ally_ui_kennung_person', 'ally_ui_kennung', 'ally_ui_kennung_person_teil', 'ally_ui_kennung_personen', 'ally_ui_kennung_fuer', 'ally_ui_kennung_pflegen', 'ally_ui_kennung_ausloeser', 'ally_ui_pfad_bauen', 'ally_ui_kennungen', 'ally_ui_kennungen_karte'])) IS NOT DISTINCT FROM 'ff22670c942e01e9277613040195a42c' THEN RAISE EXCEPTION 'Rückbau 210: schon zurückgebaut, nichts geändert'; END IF;
  IF (SELECT md5(string_agg(p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')|' || pg_get_function_result(p.oid) || '|' || md5(p.prosrc), E'\n' ORDER BY p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')' COLLATE "C")) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname::text = 'public' COLLATE "C" AND p.proname::text COLLATE "C" = ANY (ARRAY['ally_ui_pfad', 'ally_ui_kennung_text', 'ally_ui_kn_talent', 'ally_ui_kn_talent_darf', 'ally_ui_kn_kampagne', 'ally_ui_kn_kampagne_darf', 'ally_ui_kn_briefing', 'ally_ui_kn_briefing_darf', 'ally_ui_kn_ergebnis', 'ally_ui_kn_ergebnis_bereich', 'ally_ui_kn_ergebnis_darf', 'ally_ui_kn_person', 'ally_ui_kn_person_darf', 'ally_ui_kn_ordner', 'ally_ui_kn_ordner_darf', 'ally_ui_kn_termin', 'ally_ui_kn_termin_darf', 'ally_ui_kn_benachrichtigung', 'ally_ui_kn_benachrichtigung_bereich', 'ally_ui_kn_benachrichtigung_darf', 'ally_ui_kennung_person', 'ally_ui_kennung', 'ally_ui_kennung_person_teil', 'ally_ui_kennung_personen', 'ally_ui_kennung_fuer', 'ally_ui_kennung_pflegen', 'ally_ui_kennung_ausloeser', 'ally_ui_pfad_bauen', 'ally_ui_kennungen', 'ally_ui_kennungen_karte'])) IS DISTINCT FROM '1103966ca87c6ed8c9a4bfef7019b9f1' THEN RAISE EXCEPTION 'Rückbau 210: nicht im Stand von 210, nichts geändert'; END IF;
END $m$;
DO $m$
DECLARE r record;
BEGIN
  -- alle Auslöser der Kennungen (auch die von Zusatzpaketen oder der Hauptinstallation angelegten)
  FOR r IN SELECT t.tgname, c.relname FROM pg_trigger t JOIN pg_class c ON c.oid = t.tgrelid JOIN pg_namespace s ON s.oid = c.relnamespace
           WHERE s.nspname = 'public' AND t.tgfoid = 'public.ally_ui_kennung_ausloeser()'::regprocedure ORDER BY c.relname COLLATE "C", t.tgname COLLATE "C" LOOP
    EXECUTE format('DROP TRIGGER %I ON public.%I', r.tgname, r.relname);
  END LOOP;
END $m$;
DO $m$
DECLARE f record; o jsonb; P jsonb; a record; ob text; v text; kt text; bw text; br text; neu text; z jsonb := '[]'::jsonb; e jsonb;
BEGIN
  -- gemerkte Filter wieder an der Adresse mit Nummer (wie vor 210); Kennungen mit Bereich im Bereich des Objekts (Briefing) und der Person des Filters.
  -- Erst alle Adressen lesen (mit dem Muster von 210), dann das Muster /briefing/{briefing}/{ergebnis} entfernen, dann die Adressen wie vor 210 bauen.
  FOR f IN SELECT x.person, x.kennung, x.seite FROM public.ally_ui_filter x ORDER BY x.person COLLATE "C", x.kennung COLLATE "C" LOOP
    o := public.ally_ui_ort(f.kennung);
    CONTINUE WHEN o->>'seite' IS DISTINCT FROM f.seite;
    P := o->'parameter';
    FOR a IN SELECT y.* FROM public.ally_ui_kennung_arten y WHERE y.seite = f.seite AND P ? y.parameter ORDER BY (y.bereich_parameter IS NOT NULL), y.art COLLATE "C" LOOP
      v := P->>a.parameter; kt := v; ob := NULL;
      bw := CASE WHEN a.bereich_parameter IS NULL THEN '' ELSE coalesce(P->>a.bereich_parameter, '') END;
      IF a.bereich_person AND position('_' IN v) > 0 THEN
        kt := split_part(v, '_', 1);
        br := bw || '|' || coalesce((SELECT min(pp) FROM public.ally_ui_kennung_personen(split_part(v, '_', 2)) pp
                                     WHERE EXISTS (SELECT 1 FROM public.ally_ui_kennungen k WHERE k.art = a.art AND k.bereich = bw || '|' || pp AND k.kennung = split_part(v, '_', 1))), '');
      ELSIF a.bereich_person THEN
        br := bw || '|' || f.person;
      ELSE
        br := bw;
      END IF;
      SELECT k.objekt INTO ob FROM public.ally_ui_kennungen k WHERE k.art = a.art AND k.bereich = br AND k.kennung = kt;
      IF ob IS NULL AND a.bereich_person THEN
        SELECT min(k.objekt) INTO ob FROM public.ally_ui_kennungen k WHERE k.art = a.art AND k.bereich LIKE bw || '|%' AND k.kennung = kt HAVING count(*) = 1;
      END IF;
      IF ob IS NOT NULL THEN P := P || jsonb_build_object(a.parameter, ob); END IF;
    END LOOP;
    z := z || jsonb_build_array(jsonb_build_object('person', f.person, 'kennung', f.kennung, 'seite', f.seite, 'p', P));
  END LOOP;
  DELETE FROM public.ally_ui_pfade WHERE herkunft = 'm210';
  FOR e IN SELECT x FROM jsonb_array_elements(z) x LOOP
    neu := left(public.ally_ui_pfad_bauen(e->>'seite', e->'p', false), 300);
    CONTINUE WHEN neu = e->>'kennung' OR EXISTS (SELECT 1 FROM public.ally_ui_filter y WHERE y.person = e->>'person' AND y.kennung = neu);
    UPDATE public.ally_ui_filter x SET kennung = neu WHERE x.person = e->>'person' AND x.kennung = e->>'kennung';
  END LOOP;
END $m$;
CREATE OR REPLACE FUNCTION public.ally_ui_pfad(p_seite text, p_parameter jsonb)
 RETURNS text
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
  r record; bm text; bf jsonb; brest boolean; bs integer := -1; sc integer; ph text[]; aus text; k text; rest text := '';
  P jsonb := coalesce((SELECT jsonb_object_agg(e.key, e.value #>> '{}') FROM jsonb_each(CASE WHEN jsonb_typeof(p_parameter) = 'object' THEN p_parameter ELSE '{}'::jsonb END) e
                       WHERE jsonb_typeof(e.value) IN ('string', 'number', 'boolean') AND (e.value #>> '{}') <> ''), '{}'::jsonb);
BEGIN
  -- Migration 209 (Fehler 46, Stefan 06.11.2026): Adresse (Pfad ab /) einer Seite mit ihren Parametern aus ally_ui_pfade. Es zählt das passende Muster mit den
  -- meisten festen Parametern und Kennungen (bei Gleichstand sortierung); Parameter, die kein Muster aufnimmt (Filter, Ansicht, Blättern), fallen weg – außer bei
  -- Mustern mit rest (Herunterladen, Link). Ohne Muster: /<Seitenschlüssel> (Seiten von Zusatzpaketen), Startseite und freizuhaltende Pfade: /.
  FOR r IN SELECT x.* FROM public.ally_ui_pfade x WHERE x.seite = p_seite ORDER BY x.sortierung, x.muster COLLATE "C" LOOP
    CONTINUE WHEN EXISTS (SELECT 1 FROM jsonb_each_text(r.feste) f WHERE (P->>f.key) IS DISTINCT FROM f.value);
    ph := ARRAY(SELECT m[1] FROM regexp_matches(r.muster, '\{([a-z0-9_]+)\}', 'g') m);
    CONTINUE WHEN EXISTS (SELECT 1 FROM unnest(ph) k0 WHERE coalesce(P->>k0, '') !~ '^[^/\x01-\x1f\x7f]{1,200}$');
    sc := (SELECT count(*) FROM jsonb_object_keys(r.feste)) + cardinality(ph);
    IF sc > bs THEN bs := sc; bm := r.muster; bf := r.feste; brest := r.rest; END IF;
  END LOOP;
  IF bm IS NULL THEN
    RETURN CASE WHEN coalesce(p_seite, '') ~ '^[a-z0-9-]{1,40}$' AND p_seite NOT IN ('start', 'unbekannt', 'aktion', 'datei', 'manifest', 'symbol', 'kalender', 'stil', 'skript',
                                                                                    'logo', 'neu', 'api', 'mediakit', 'webhook') THEN '/' || p_seite ELSE '/' END;
  END IF;
  aus := bm;
  FOREACH k IN ARRAY ARRAY(SELECT m[1] FROM regexp_matches(bm, '\{([a-z0-9_]+)\}', 'g') m) LOOP
    aus := replace(aus, '{' || k || '}', public.ally_ui_pfad_teil(P->>k));
  END LOOP;
  IF brest THEN
    SELECT coalesce(string_agg(public.ally_ui_pfad_teil(e.key) || '=' || public.ally_ui_pfad_teil(e.value), '&' ORDER BY e.key COLLATE "C"), '') INTO rest
    FROM jsonb_each_text(P) e WHERE NOT bf ? e.key AND position('{' || e.key || '}' IN bm) = 0;
    IF rest <> '' THEN aus := aus || '?' || rest; END IF;
  END IF;
  RETURN aus;
END $function$;
DROP FUNCTION public.ally_ui_kennungen_karte(p_token text, p_json jsonb, p_nummern jsonb);
DROP FUNCTION public.ally_ui_kennungen(p_token text, p_seite text, p_parameter jsonb);
DROP FUNCTION public.ally_ui_pfad_bauen(p_seite text, p_parameter jsonb, p_umsetzen boolean);
DROP FUNCTION public.ally_ui_kennung_ausloeser();
DROP FUNCTION public.ally_ui_kennung_pflegen(p_art text, p_objekt text);
DROP FUNCTION public.ally_ui_kennung_fuer(p_art text, p_objekt text, p_wer text);
DROP FUNCTION public.ally_ui_kennung_personen(p_teil text);
DROP FUNCTION public.ally_ui_kennung_person_teil(p_person text);
DROP FUNCTION public.ally_ui_kennung(p_art text, p_objekt text);
DROP FUNCTION public.ally_ui_kennung_person(p_token text);
DROP FUNCTION public.ally_ui_kn_benachrichtigung_darf(p_person text, p_objekte text[]);
DROP FUNCTION public.ally_ui_kn_benachrichtigung_bereich(p_objekt text);
DROP FUNCTION public.ally_ui_kn_benachrichtigung(p_objekt text);
DROP FUNCTION public.ally_ui_kn_termin_darf(p_person text, p_objekte text[]);
DROP FUNCTION public.ally_ui_kn_termin(p_objekt text);
DROP FUNCTION public.ally_ui_kn_ordner_darf(p_person text, p_objekte text[]);
DROP FUNCTION public.ally_ui_kn_ordner(p_objekt text);
DROP FUNCTION public.ally_ui_kn_person_darf(p_person text, p_objekte text[]);
DROP FUNCTION public.ally_ui_kn_person(p_objekt text);
DROP FUNCTION public.ally_ui_kn_ergebnis_darf(p_person text, p_objekte text[]);
DROP FUNCTION public.ally_ui_kn_ergebnis_bereich(p_objekt text);
DROP FUNCTION public.ally_ui_kn_ergebnis(p_objekt text);
DROP FUNCTION public.ally_ui_kn_briefing_darf(p_person text, p_objekte text[]);
DROP FUNCTION public.ally_ui_kn_briefing(p_objekt text);
DROP FUNCTION public.ally_ui_kn_kampagne_darf(p_person text, p_objekte text[]);
DROP FUNCTION public.ally_ui_kn_kampagne(p_objekt text);
DROP FUNCTION public.ally_ui_kn_talent_darf(p_person text, p_objekte text[]);
DROP FUNCTION public.ally_ui_kn_talent(p_objekt text);
DROP FUNCTION public.ally_ui_kennung_text(p_name text, p_ersatz text);
ALTER TABLE public.ally_ui_kennung_arten RENAME TO ally_ui_kennung_arten_rb210;
ALTER TABLE public.ally_ui_kennungen RENAME TO ally_ui_kennungen_rb210;
ALTER INDEX public.ally_ui_kennung_arten_pkey RENAME TO ally_ui_kennung_arten_pkey_rb210;
ALTER INDEX public.ally_ui_kennung_arten_seite_parameter_key RENAME TO ally_ui_kennung_arten_seite_parameter_key_rb210;
ALTER INDEX public.ally_ui_kennungen_aktuell RENAME TO ally_ui_kennungen_aktuell_rb210;
ALTER INDEX public.ally_ui_kennungen_objekt RENAME TO ally_ui_kennungen_objekt_rb210;
ALTER INDEX public.ally_ui_kennungen_pkey RENAME TO ally_ui_kennungen_pkey_rb210;
DO $m$
BEGIN
  IF (SELECT md5(string_agg(p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')|' || pg_get_function_result(p.oid) || '|' || md5(p.prosrc), E'\n' ORDER BY p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')' COLLATE "C")) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname::text = 'public' COLLATE "C" AND p.proname::text COLLATE "C" = ANY (ARRAY['ally_ui_pfad', 'ally_ui_kennung_text', 'ally_ui_kn_talent', 'ally_ui_kn_talent_darf', 'ally_ui_kn_kampagne', 'ally_ui_kn_kampagne_darf', 'ally_ui_kn_briefing', 'ally_ui_kn_briefing_darf', 'ally_ui_kn_ergebnis', 'ally_ui_kn_ergebnis_bereich', 'ally_ui_kn_ergebnis_darf', 'ally_ui_kn_person', 'ally_ui_kn_person_darf', 'ally_ui_kn_ordner', 'ally_ui_kn_ordner_darf', 'ally_ui_kn_termin', 'ally_ui_kn_termin_darf', 'ally_ui_kn_benachrichtigung', 'ally_ui_kn_benachrichtigung_bereich', 'ally_ui_kn_benachrichtigung_darf', 'ally_ui_kennung_person', 'ally_ui_kennung', 'ally_ui_kennung_person_teil', 'ally_ui_kennung_personen', 'ally_ui_kennung_fuer', 'ally_ui_kennung_pflegen', 'ally_ui_kennung_ausloeser', 'ally_ui_pfad_bauen', 'ally_ui_kennungen', 'ally_ui_kennungen_karte'])) IS DISTINCT FROM 'ff22670c942e01e9277613040195a42c' THEN RAISE EXCEPTION 'Rückbau 210: Funktionen nicht wie vorher'; END IF;
END $m$;
