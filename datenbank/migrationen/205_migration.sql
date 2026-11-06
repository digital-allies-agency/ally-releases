-- Migration 205 (interner Kalender, Stefan 04.11.2026): Die Seite Kommunikation › Kalender gehört zum Basispaket; in ihr landet alles, was zum internen
-- Kalender gehört, auch aus anderen Paketen, und neue Pakete binden sich an diese Kalenderfunktion an (Möglichkeit B, keine Kopien).
-- a) kalender_termine (eigene Termine, Papierkorb) und kalender_termin_personen (Eingeladene); sehen, ändern und Papierkorb: wer ihn angelegt hat, für wen er ist,
--    wer eingeladen ist (kalender_termin_sichtbar).
-- b) kalender_quellen mit der Quelle des Social-Media-Pakets (talents_kalender_eintraege, talents_kalender_aendern); kalender_eintraege liest alles zusammen.
-- c) kalender_web_seite, kalender_web_aktion und kalender_ui_aktion (kt_*, ALLY 20 „Aktion ausführen“ vor ally_ui_aktion) für die Seite Kalender (ALLY 29, ALLY 20).
--    ally_ui_aktion bleibt unverändert (sein Text enthält ausgeschlossene Themen, Regel fassung_bauen).
-- d) ally_kalender_ics: das Kalender-Abo der Personen liest über kalender_eintraege; das Abo der Talents bleibt, wie es ist.
-- Datenänderung: keine an vorhandenen Daten (neue Tabellen; eine Zeile in der neuen Tabelle kalender_quellen). Wächter vorher: Funktionen wie nach 204,
-- die neuen Tabellen und die Sicherungstabellen aus Rückbau 205 gibt es nicht. Läuft als Ganzes in der Transaktion des Aufrufs (psql -1). Rückbau: rueckbau205.sql.
DO $m$
BEGIN
  IF (SELECT md5(string_agg(p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')|' || pg_get_function_result(p.oid) || '|' || md5(p.prosrc), E'\n' ORDER BY p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')' COLLATE "C")) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname::text = 'public' COLLATE "C" AND p.proname::text COLLATE "C" = ANY (ARRAY['ally_kalender_ics', 'kalender_person_waehlbar', 'kalender_termin_sichtbar', 'kalender_zeit_lesen', 'kalender_termin_eintrag', 'kalender_eintraege', 'kalender_web_seite', 'kalender_web_aktion', 'kalender_ui_aktion', 'talents_kalender_eintraege', 'talents_kalender_aendern'])) IS NOT DISTINCT FROM '2ed562ddf5beef8407cd01c517b68a88' AND (SELECT md5(string_agg(z, E'\n' ORDER BY z COLLATE "C")) FROM (WITH t AS (SELECT c.oid, c.relname::text AS tab FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname::text = 'public' COLLATE "C" AND c.relkind::text = ANY (ARRAY['r', 'p']) AND c.relname::text = ANY (ARRAY['kalender_termine', 'kalender_termin_personen', 'kalender_quellen'])) SELECT 'S|' || t.tab || '|' || a.attname::text || '|' || format_type(a.atttypid, a.atttypmod) || '|' || CASE WHEN a.attnotnull THEN 'NN' ELSE '-' END || '|' || coalesce(pg_get_expr(d.adbin, d.adrelid), '') || '|' || a.attidentity::text || a.attgenerated::text AS z FROM t JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum > 0 AND NOT a.attisdropped LEFT JOIN pg_attrdef d ON d.adrelid = t.oid AND d.adnum = a.attnum UNION ALL SELECT 'C|' || t.tab || '|' || co.conname::text || '|' || co.contype::text || '|' || pg_get_constraintdef(co.oid) FROM t JOIN pg_constraint co ON co.conrelid = t.oid UNION ALL SELECT 'I|' || t.tab || '|' || ic.relname::text || '|' || pg_get_indexdef(i.indexrelid) FROM t JOIN pg_index i ON i.indrelid = t.oid JOIN pg_class ic ON ic.oid = i.indexrelid UNION ALL SELECT 'T|' || t.tab || '|' || tg.tgname::text || '|' || pg_get_triggerdef(tg.oid) || '|' || tg.tgenabled::text FROM t JOIN pg_trigger tg ON tg.tgrelid = t.oid AND NOT tg.tgisinternal) x) IS NOT DISTINCT FROM '22d524eb9633e7b5970679a1b37960c1'
    THEN RAISE EXCEPTION 'Migration 205: schon eingespielt, nichts geändert'; END IF;
  IF (SELECT count(*) FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname::text = 'public' COLLATE "C" AND c.relname::text COLLATE "C" = ANY (ARRAY['kalender_termine_rb205', 'kalender_termin_personen_rb205', 'kalender_quellen_rb205'])) <> 0 THEN RAISE EXCEPTION 'Migration 205: Sicherungstabellen aus Rückbau 205 vorhanden, erst klären, nichts geändert'; END IF;
  IF (SELECT md5(string_agg(z, E'\n' ORDER BY z COLLATE "C")) FROM (WITH t AS (SELECT c.oid, c.relname::text AS tab FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname::text = 'public' COLLATE "C" AND c.relkind::text = ANY (ARRAY['r', 'p']) AND c.relname::text = ANY (ARRAY['kalender_termine', 'kalender_termin_personen', 'kalender_quellen'])) SELECT 'S|' || t.tab || '|' || a.attname::text || '|' || format_type(a.atttypid, a.atttypmod) || '|' || CASE WHEN a.attnotnull THEN 'NN' ELSE '-' END || '|' || coalesce(pg_get_expr(d.adbin, d.adrelid), '') || '|' || a.attidentity::text || a.attgenerated::text AS z FROM t JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum > 0 AND NOT a.attisdropped LEFT JOIN pg_attrdef d ON d.adrelid = t.oid AND d.adnum = a.attnum UNION ALL SELECT 'C|' || t.tab || '|' || co.conname::text || '|' || co.contype::text || '|' || pg_get_constraintdef(co.oid) FROM t JOIN pg_constraint co ON co.conrelid = t.oid UNION ALL SELECT 'I|' || t.tab || '|' || ic.relname::text || '|' || pg_get_indexdef(i.indexrelid) FROM t JOIN pg_index i ON i.indrelid = t.oid JOIN pg_class ic ON ic.oid = i.indexrelid UNION ALL SELECT 'T|' || t.tab || '|' || tg.tgname::text || '|' || pg_get_triggerdef(tg.oid) || '|' || tg.tgenabled::text FROM t JOIN pg_trigger tg ON tg.tgrelid = t.oid AND NOT tg.tgisinternal) x) IS NOT NULL THEN RAISE EXCEPTION 'Migration 205: Tabellen des internen Kalenders gibt es schon, nichts geändert'; END IF;
  IF (SELECT md5(string_agg(p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')|' || pg_get_function_result(p.oid) || '|' || md5(p.prosrc), E'\n' ORDER BY p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')' COLLATE "C")) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname::text = 'public' COLLATE "C" AND p.proname::text COLLATE "C" = ANY (ARRAY['ally_kalender_ics', 'kalender_person_waehlbar', 'kalender_termin_sichtbar', 'kalender_zeit_lesen', 'kalender_termin_eintrag', 'kalender_eintraege', 'kalender_web_seite', 'kalender_web_aktion', 'kalender_ui_aktion', 'talents_kalender_eintraege', 'talents_kalender_aendern'])) IS DISTINCT FROM '8beb9b7b809dba545a7b0a6e2569039c' THEN RAISE EXCEPTION 'Migration 205: Funktionen der Oberfläche und des Kalender-Abos nicht im erwarteten Stand, nichts geändert'; END IF;
END $m$;
CREATE TABLE public.kalender_termine (
  id bigint GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
  titel text NOT NULL,
  ganztags boolean NOT NULL DEFAULT false,
  beginn timestamp with time zone NOT NULL,
  ende timestamp with time zone NOT NULL,
  ort text,
  notiz text,
  fuer text NOT NULL,
  erstellt_von text NOT NULL,
  erstellt_am timestamp with time zone NOT NULL DEFAULT now(),
  geaendert_von text,
  geaendert_am timestamp with time zone,
  geloescht_von text,
  geloescht_am timestamp with time zone,
  ics_sequenz integer NOT NULL DEFAULT 0,
  CONSTRAINT kalender_termine_titel_check CHECK (btrim(titel) <> '' AND length(titel) <= 200),
  CONSTRAINT kalender_termine_ort_check CHECK (ort IS NULL OR length(ort) <= 200),
  CONSTRAINT kalender_termine_notiz_check CHECK (notiz IS NULL OR length(notiz) <= 2000),
  CONSTRAINT kalender_termine_zeitraum CHECK (ende >= beginn),
  CONSTRAINT kalender_termine_papierkorb CHECK ((geloescht_am IS NULL) = (geloescht_von IS NULL))
);
CREATE INDEX kalender_termine_beginn_idx ON public.kalender_termine (beginn) WHERE geloescht_am IS NULL;
CREATE INDEX kalender_termine_fuer_idx ON public.kalender_termine (fuer);
CREATE INDEX kalender_termine_erstellt_von_idx ON public.kalender_termine (erstellt_von);
COMMENT ON TABLE public.kalender_termine IS 'Migration 205 (interner Kalender, Stefan 04.11.2026): eigene Termine des internen Kalenders (Seite Kommunikation › Kalender, Basispaket). Sehen, ändern und in den Papierkorb legen: wer ihn angelegt hat (erstellt_von), für wen er ist (fuer) und die Eingeladenen (kalender_termin_personen). Ganztägig: beginn und ende 00:00 Berliner Zeit, ende = Tag nach dem letzten Tag. Papierkorb: geloescht_am/geloescht_von (Regel E13). ics_sequenz für das Kalender-Abo.';
CREATE TABLE public.kalender_termin_personen (
  termin_id bigint NOT NULL REFERENCES public.kalender_termine (id) ON DELETE CASCADE,
  person text NOT NULL,
  PRIMARY KEY (termin_id, person)
);
CREATE INDEX kalender_termin_personen_person_idx ON public.kalender_termin_personen (person);
COMMENT ON TABLE public.kalender_termin_personen IS 'Migration 205 (interner Kalender, Stefan 04.11.2026): eingeladene Personen eines internen Termins (matrix_user_id), ohne die Person, für die er ist.';
CREATE TABLE public.kalender_quellen (
  schluessel text PRIMARY KEY,
  name text NOT NULL,
  modul text,
  lesen text NOT NULL,
  aendern text,
  reihenfolge integer NOT NULL DEFAULT 100,
  CONSTRAINT kalender_quellen_schluessel_check CHECK (schluessel ~ '^[a-z]{1,30}$'),
  CONSTRAINT kalender_quellen_lesen_check CHECK (lesen ~ '^[a-z_][a-z0-9_]{0,62}$'),
  CONSTRAINT kalender_quellen_aendern_check CHECK (aendern IS NULL OR aendern ~ '^[a-z_][a-z0-9_]{0,62}$')
);
COMMENT ON TABLE public.kalender_quellen IS 'Migration 205 (interner Kalender, Stefan 04.11.2026): Kalenderquellen der Pakete (Möglichkeit B). lesen(person text, von date, bis date, ics boolean) → jsonb-Liste der Einträge; aendern(token text, eintrag text, daten jsonb) → jsonb, setzt die Meldung selbst. modul: nur wenn plattform_modul_an(modul). Jedes Paket trägt seine Zeile mit seiner Migration ein.';
INSERT INTO public.kalender_quellen (schluessel, name, modul, lesen, aendern, reihenfolge)
VALUES ('talents', 'Social-Media Management', 'talents', 'talents_kalender_eintraege', 'talents_kalender_aendern', 10);
CREATE OR REPLACE FUNCTION public.kalender_person_waehlbar(p_person text)
 RETURNS boolean
 LANGUAGE sql
 STABLE
AS $function$
  -- Migration 205 (interner Kalender, Stefan 04.11.2026): Person, die im internen Kalender als „für“ oder eingeladen gewählt werden kann:
  -- aktiv, keine Testdaten, keine Talent-Person und darf die Seite Kalender sehen.
  SELECT coalesce(EXISTS (SELECT 1 FROM ally_personen p WHERE p.matrix_user_id = p_person AND p.aktiv AND NOT coalesce(p.testdaten, false))
    AND NOT ally_person_ist_talent(p_person) AND ally_ui_funktion_erlaubt(p_person, NULL, 'kalender'), false)
$function$;
CREATE OR REPLACE FUNCTION public.kalender_termin_sichtbar(p_person text, p_id bigint)
 RETURNS boolean
 LANGUAGE sql
 STABLE
AS $function$
  -- Migration 205 (interner Kalender, Stefan 04.11.2026, 08:40): Einen internen Termin sehen die Person, die ihn angelegt hat, die Person, für die er ist,
  -- und die eingeladenen Personen; ändern und in den Papierkorb legen dürfen alle, die ihn sehen (09:05). Gilt auch im Papierkorb.
  SELECT coalesce(p_person IS NOT NULL AND EXISTS (SELECT 1 FROM kalender_termine t WHERE t.id = p_id
    AND (t.erstellt_von = p_person OR t.fuer = p_person OR EXISTS (SELECT 1 FROM kalender_termin_personen x WHERE x.termin_id = t.id AND x.person = p_person))), false)
$function$;
CREATE OR REPLACE FUNCTION public.kalender_zeit_lesen(p text)
 RETURNS timestamp with time zone
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
  x text := btrim(coalesce(p, ''));
BEGIN
  -- Migration 205 (interner Kalender): Zeitpunkt aus dem Formular (ALLY 20 schickt ISO mit Zeitzone; ohne Zeitzone gilt Berliner Zeit, ein reines Datum ist
  -- 00:00 Berliner Zeit). Ungültig = NULL. Nur Jahre 2000 … 2100.
  IF x ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN
    IF to_char(to_date(x, 'YYYY-MM-DD'), 'YYYY-MM-DD') <> x THEN RETURN NULL; END IF;
    RETURN CASE WHEN left(x, 4)::integer BETWEEN 2000 AND 2100 THEN x::date::timestamp AT TIME ZONE 'Europe/Berlin' END;
  ELSIF x ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[T ][0-9]{2}:[0-9]{2}(:[0-9]{2})?$' THEN
    RETURN CASE WHEN left(x, 4)::integer BETWEEN 2000 AND 2100 THEN x::timestamp AT TIME ZONE 'Europe/Berlin' END;
  ELSIF x ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[T ][0-9]{2}:[0-9]{2}(:[0-9]{2}([.][0-9]{1,6})?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)$' THEN
    RETURN CASE WHEN left(x, 4)::integer BETWEEN 2000 AND 2100 THEN x::timestamptz END;
  END IF;
  RETURN NULL;
EXCEPTION WHEN OTHERS THEN
  RETURN NULL;
END $function$;
CREATE OR REPLACE FUNCTION public.kalender_termin_eintrag(p_id bigint, p_ics boolean)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
AS $function$
  -- Migration 205 (interner Kalender): ein interner Termin in der gemeinsamen Form der Kalender-Einträge (wie die Kalenderquellen der Pakete), Zeiten in Berliner Zeit.
  -- tag = erster Tag, bis_tag = letzter Tag (ganztägig: ende ist der Tag nach dem letzten Tag, 00:00); start/ende für die Formularfelder (JJJJ-MM-TTTHH:MM).
  -- Mit p_ics zusätzlich das VEVENT für das Kalender-Abo (UID termin-<id>, SEQUENCE aus ics_sequenz).
  SELECT jsonb_build_object('quelle', 'intern', 'id', 'i-' || t.id, 'art', 'termin', 'art_text', 'Termin', 'titel', t.titel, 'ganztags', t.ganztags,
      'tag', to_char(b.tag, 'YYYY-MM-DD'), 'bis_tag', to_char(b.bis_tag, 'YYYY-MM-DD'),
      'von', CASE WHEN NOT t.ganztags THEN to_char(t.beginn AT TIME ZONE 'Europe/Berlin', 'HH24:MI') END,
      'bis', CASE WHEN NOT t.ganztags THEN to_char(t.ende AT TIME ZONE 'Europe/Berlin', 'HH24:MI') END,
      'start', to_char(t.beginn AT TIME ZONE 'Europe/Berlin', 'YYYY-MM-DD"T"HH24:MI'), 'ende', to_char(t.ende AT TIME ZONE 'Europe/Berlin', 'YYYY-MM-DD"T"HH24:MI'),
      'ort', coalesce(t.ort, ''), 'notiz', coalesce(t.notiz, ''),
      'fuer', t.fuer, 'fuer_name', coalesce((SELECT p.name FROM ally_personen p WHERE p.matrix_user_id = t.fuer), t.fuer),
      'eingeladen', coalesce((SELECT jsonb_agg(x.person ORDER BY x.person COLLATE "C") FROM kalender_termin_personen x WHERE x.termin_id = t.id), '[]'::jsonb),
      'eingeladen_namen', coalesce((SELECT jsonb_agg(coalesce(p.name, x.person) ORDER BY coalesce(p.name, x.person), x.person COLLATE "C")
        FROM kalender_termin_personen x LEFT JOIN ally_personen p ON p.matrix_user_id = x.person WHERE x.termin_id = t.id), '[]'::jsonb),
      'erstellt_von', t.erstellt_von, 'erstellt_von_name', coalesce((SELECT p.name FROM ally_personen p WHERE p.matrix_user_id = t.erstellt_von), t.erstellt_von),
      'erstellt_am', to_char(t.erstellt_am AT TIME ZONE 'Europe/Berlin', 'DD.MM.YYYY HH24:MI'),
      'geaendert_am', to_char(t.geaendert_am AT TIME ZONE 'Europe/Berlin', 'DD.MM.YYYY HH24:MI'),
      'geaendert_von_name', coalesce((SELECT p.name FROM ally_personen p WHERE p.matrix_user_id = t.geaendert_von), t.geaendert_von),
      'geloescht', t.geloescht_am IS NOT NULL, 'geloescht_am', to_char(t.geloescht_am AT TIME ZONE 'Europe/Berlin', 'DD.MM.YYYY HH24:MI'),
      'geloescht_von_name', coalesce((SELECT p.name FROM ally_personen p WHERE p.matrix_user_id = t.geloescht_von), t.geloescht_von),
      'aenderbar', t.geloescht_am IS NULL)
    || CASE WHEN p_ics THEN jsonb_build_object('ics', ally_ics_ereignis('termin-' || t.id || '@' || ally_ics_domain(), t.ics_sequenz, t.beginn, t.ende, t.ganztags,
         b.tag, b.bis_tag, t.titel, t.notiz, t.ort, false, now())) ELSE '{}'::jsonb END
  FROM kalender_termine t
  CROSS JOIN LATERAL (SELECT (t.beginn AT TIME ZONE 'Europe/Berlin')::date AS tag,
    greatest(CASE WHEN t.ganztags THEN (t.ende AT TIME ZONE 'Europe/Berlin')::date - 1 ELSE (t.ende AT TIME ZONE 'Europe/Berlin')::date END,
             (t.beginn AT TIME ZONE 'Europe/Berlin')::date) AS bis_tag) b
  WHERE t.id = p_id
$function$;
CREATE OR REPLACE FUNCTION public.kalender_eintraege(p_person text, p_von date, p_bis date, p_ics boolean DEFAULT false)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
  e jsonb := '[]'::jsonb; f jsonb := '[]'::jsonb; q record; x jsonb;
  v_von timestamptz; v_bis timestamptz; recht boolean;
BEGIN
  -- Migration 205 (interner Kalender, Stefan 04.11.2026, Möglichkeit B): die eine Stelle für alle Kalender-Einträge einer Person im Zeitraum p_von … p_bis
  -- (Tage, Berliner Zeit). Eigene interne Termine (kalender_termine, nicht im Papierkorb, sichtbar nach kalender_termin_sichtbar) und die Einträge jeder
  -- angemeldeten Kalenderquelle eines Pakets (kalender_quellen, nur wenn das Paket an ist), ohne Kopien. Die Seite Kalender (kalender_web_seite) und das
  -- Kalender-Abo (ally_kalender_ics, p_ics = VEVENT je Eintrag) lesen hier. Eine Quelle, die scheitert, fehlt nur selbst (Eintrag in „fehler“).
  -- Vertrag einer Quelle: lesen(person text, von date, bis date, ics boolean) liefert eine Liste von Einträgen mit id (a-z, 0-9, -), art, art_text, titel,
  -- ganztags, tag, bis_tag, von, bis, ort, notiz, kontext, status_text, ziel, ziel_text, aenderbar, felder (Formularfelder für aendern) und bei ics das VEVENT.
  IF p_person IS NULL OR p_von IS NULL OR p_bis IS NULL OR p_bis < p_von OR p_bis - p_von > 800 THEN
    RETURN jsonb_build_object('eintraege', '[]'::jsonb, 'fehler', '[]'::jsonb);
  END IF;
  v_von := p_von::timestamp AT TIME ZONE 'Europe/Berlin';
  v_bis := (p_bis + 1)::timestamp AT TIME ZONE 'Europe/Berlin';
  -- Prüfung 205 (L6): eigene interne Termine nur mit dem Recht „Kalender“ (auch im Kalender-Abo)
  recht := coalesce(ally_ui_funktion_erlaubt(p_person, NULL, 'kalender'), false);
  SELECT coalesce(jsonb_agg(kalender_termin_eintrag(t.id, p_ics) ORDER BY t.beginn, t.id), '[]'::jsonb) INTO e
  FROM (SELECT t.id, t.beginn FROM kalender_termine t
        WHERE recht AND t.geloescht_am IS NULL AND t.beginn < v_bis AND (t.ende > v_von OR t.beginn >= v_von)
          AND (t.erstellt_von = p_person OR t.fuer = p_person OR EXISTS (SELECT 1 FROM kalender_termin_personen x WHERE x.termin_id = t.id AND x.person = p_person))
        ORDER BY t.beginn, t.id LIMIT 1000) t;
  FOR q IN SELECT k.schluessel, k.name, k.modul, k.lesen FROM kalender_quellen k ORDER BY k.reihenfolge, k.schluessel COLLATE "C" LOOP
    CONTINUE WHEN q.modul IS NOT NULL AND NOT coalesce(plattform_modul_an(q.modul), false);
    BEGIN
      IF q.lesen !~ '^[a-z_][a-z0-9_]{0,62}$' OR to_regprocedure(format('public.%I(text,date,date,boolean)', q.lesen)) IS NULL THEN
        RAISE EXCEPTION 'Lesefunktion der Kalenderquelle fehlt';
      END IF;
      EXECUTE format('SELECT public.%I($1, $2, $3, $4)', q.lesen) INTO x USING p_person, p_von, p_bis, p_ics;
      IF jsonb_typeof(x) IS DISTINCT FROM 'array' THEN RAISE EXCEPTION 'Kalenderquelle liefert keine Liste'; END IF;
      e := e || coalesce((SELECT jsonb_agg(y || jsonb_build_object('quelle', q.schluessel, 'quelle_name', q.name, 'eintrag', y->>'id',
                                                                   'id', 'q-' || q.schluessel || '-' || (y->>'id')))
                          FROM jsonb_array_elements(x) y WHERE jsonb_typeof(y) = 'object' AND coalesce(y->>'id', '') ~ '^[a-z0-9-]{1,40}$'), '[]'::jsonb);
    EXCEPTION WHEN OTHERS THEN
      f := f || jsonb_build_object('quelle', q.schluessel, 'name', q.name, 'technik', left(SQLERRM, 300));
    END;
  END LOOP;
  SELECT coalesce(jsonb_agg(y ORDER BY y->>'tag' COLLATE "C", coalesce((y->>'ganztags')::boolean, false) DESC, coalesce(y->>'von', '') COLLATE "C",
                            lower(coalesce(y->>'titel', '')), y->>'id' COLLATE "C"), '[]'::jsonb) INTO e
  FROM jsonb_array_elements(e) y;
  RETURN jsonb_build_object('eintraege', e, 'fehler', f);
END $function$;
CREATE OR REPLACE FUNCTION public.kalender_web_seite(p_token text, p jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
  s record; u text; d jsonb := CASE WHEN jsonb_typeof(p) = 'object' THEN p ELSE '{}'::jsonb END;
  von date; tage integer; q text; x jsonb; e jsonb; pk jsonb := '[]'::jsonb; gew jsonb; tid text;
BEGIN
  -- Migration 205 (interner Kalender, Stefan 04.11.2026): Daten der Seite Kommunikation › Kalender (ALLY 29 „Daten laden“) ohne den Google Kalender
  -- (der kommt weiter über arbeit_web_seite 'kalender' und ALLY 13). Filter wie bisher: ab (JJJJ-MM-TT, sonst heute), Zeitraum 1 … 62 Tage, Suchbegriff
  -- (Titel, Ort, Notiz, Bezug). Einträge aus kalender_eintraege; papierkorb = '1' liefert die eigenen sichtbaren Termine im Papierkorb; termin = 'i-<id>'
  -- liefert diesen Termin auch außerhalb des Zeitraums (gewaehlt). personen = wählbare Personen für „für“ und „eingeladen“ (kalender_person_waehlbar).
  SELECT * INTO s FROM ally_ui_sitzung(p_token) y WHERE NOT y.muss_pw_setzen;
  IF s.person IS NULL THEN RETURN jsonb_build_object('ok', false, 'angemeldet', false); END IF;
  u := s.person;
  IF NOT coalesce(ally_ui_funktion_erlaubt(u, NULL, 'kalender'), false) THEN RETURN jsonb_build_object('ok', false, 'angemeldet', true, 'erlaubt', false); END IF;
  BEGIN
    von := CASE WHEN coalesce(d->>'von', '') ~ '^20[0-9]{2}-[01][0-9]-[0-3][0-9]$' THEN to_date(d->>'von', 'YYYY-MM-DD') END;
    IF to_char(von, 'YYYY-MM-DD') IS DISTINCT FROM d->>'von' THEN von := NULL; END IF;
  EXCEPTION WHEN OTHERS THEN von := NULL;
  END;
  von := coalesce(von, (now() AT TIME ZONE 'Europe/Berlin')::date);
  tage := CASE WHEN coalesce(d->>'tage', '') ~ '^[0-9]{1,2}$' THEN least(greatest((d->>'tage')::integer, 1), 62) ELSE 14 END;
  q := left(btrim(regexp_replace(coalesce(d->>'q', ''), '[[:cntrl:]]', ' ', 'g')), 100);
  x := kalender_eintraege(u, von, von + tage - 1, false);
  e := x->'eintraege';
  IF q <> '' THEN
    SELECT coalesce(jsonb_agg(y ORDER BY o), '[]'::jsonb) INTO e FROM jsonb_array_elements(e) WITH ORDINALITY z(y, o)
    WHERE strpos(lower(concat_ws(' ', y->>'titel', y->>'ort', y->>'notiz', y->>'kontext')), lower(q)) > 0;
  END IF;
  IF d->>'papierkorb' = '1' THEN
    SELECT coalesce(jsonb_agg(kalender_termin_eintrag(t.id, false) ORDER BY t.geloescht_am DESC, t.id DESC), '[]'::jsonb) INTO pk
    FROM (SELECT t.id, t.geloescht_am FROM kalender_termine t WHERE t.geloescht_am IS NOT NULL AND kalender_termin_sichtbar(u, t.id)
          ORDER BY t.geloescht_am DESC, t.id DESC LIMIT 200) t;
  END IF;
  tid := coalesce(d->>'termin', '');
  IF tid ~ '^i-[0-9]{1,15}$' AND kalender_termin_sichtbar(u, substr(tid, 3)::bigint) THEN gew := kalender_termin_eintrag(substr(tid, 3)::bigint, false); END IF;
  RETURN jsonb_build_object('ok', true, 'angemeldet', true, 'ich', u, 'von', to_char(von, 'YYYY-MM-DD'), 'tage', tage, 'q', q,
    'eintraege', e, 'fehler', x->'fehler', 'papierkorb', pk, 'gewaehlt', gew,
    'personen', coalesce((SELECT jsonb_agg(jsonb_build_object('wert', p2.matrix_user_id, 'text', coalesce(nullif(btrim(p2.name), ''), p2.matrix_user_id))
                                           ORDER BY lower(coalesce(p2.name, '')), p2.matrix_user_id COLLATE "C")
                          FROM ally_personen p2 WHERE p2.aktiv AND kalender_person_waehlbar(p2.matrix_user_id)), '[]'::jsonb));
END $function$;
CREATE OR REPLACE FUNCTION public.kalender_web_aktion(p_token text, p_aktion text, p_daten jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
  s record; u text; d jsonb := CASE WHEN jsonb_typeof(p_daten) = 'object' THEN p_daten ELSE '{}'::jsonb END;
  fehler text; m text; t kalender_termine%ROWTYPE; q kalender_quellen%ROWTYPE; r jsonb;
  ganz boolean; z1 timestamptz; z2 timestamptz; ti text; ort_ text; no text; fu text; ein text[]; n integer; ids bigint[]; neu_id bigint;
BEGIN
  -- Migration 205 (interner Kalender, Stefan 04.11.2026): Aktionen der Seite Kalender (kt_*, von kalender_ui_aktion nach Sitzung und Schutzwert); setzt die Meldung selbst.
  -- kt_neu: Feld „Kalender“ = google geht wie termin_neu an arbeit_web_aktion (Google Kalender über ALLY 37, Stefan 09:05 „Auswahl im Formular“), sonst
  --   interner Termin; kt_aendern: interner Termin. Felder: titel, ganztaegig, start/ende (ganztägig: Tage, ende = Tag nach dem letzten Tag, wie ALLY 20 sie
  --   schickt), ort, beschreibung, fuer (Standard: ich), eingeladen (Liste; fehlt der Schlüssel beim Ändern, bleiben die Eingeladenen).
  -- kt_papierkorb, kt_wiederherstellen, kt_endgueltig (id), kt_papierkorb_leeren (ids = Termine, die beim Öffnen der Warnung im Papierkorb lagen; Regel E13).
  --   Ändern und Papierkorb dürfen alle, die den Termin sehen (Stefan 09:05).
  -- kt_quelle_aendern (quelle, eintrag, Felder der Quelle): Eintrag eines Pakets über die Ändern-Funktion seiner Kalenderquelle; die prüft die Rechte des Pakets
  --   und setzt die Meldung selbst.
  SELECT * INTO s FROM ally_ui_sitzung(p_token) y WHERE NOT y.muss_pw_setzen;
  IF s.person IS NULL THEN RETURN jsonb_build_object('ok', false, 'angemeldet', false); END IF;
  u := s.person;
  IF NOT coalesce(ally_ui_funktion_erlaubt(u, NULL, 'kalender'), false) THEN
    fehler := 'Den Kalender darfst du nicht nutzen.';
  ELSIF p_aktion = 'kt_neu' AND d->>'kalender' = 'google' THEN
    RETURN arbeit_web_aktion(p_token, 'termin_neu', d - 'kalender' - 'fuer' - 'eingeladen' - 'id');
  ELSIF p_aktion IN ('kt_neu', 'kt_aendern') THEN
    IF p_aktion = 'kt_aendern' THEN
      IF coalesce(d->>'id', '') ~ '^[0-9]{1,15}$' THEN SELECT * INTO t FROM kalender_termine x WHERE x.id = (d->>'id')::bigint FOR UPDATE; END IF;
    END IF;
    ganz := coalesce(d->>'ganztaegig', '') = '1';
    ti := btrim(regexp_replace(coalesce(d->>'titel', ''), '[[:cntrl:]]', ' ', 'g'));
    ort_ := nullif(btrim(regexp_replace(coalesce(d->>'ort', ''), '[[:cntrl:]]', ' ', 'g')), '');
    no := CASE WHEN d ? 'beschreibung' THEN nullif(btrim(coalesce(d->>'beschreibung', '')), '') ELSE t.notiz END;
    z1 := kalender_zeit_lesen(d->>'start');
    z2 := kalender_zeit_lesen(d->>'ende');
    IF ganz THEN
      -- ganztägig: nur die Tage zählen (00:00 Berliner Zeit), ohne Ende ein Tag
      z1 := CASE WHEN z1 IS NOT NULL THEN (z1 AT TIME ZONE 'Europe/Berlin')::date::timestamp AT TIME ZONE 'Europe/Berlin' END;
      z2 := CASE WHEN nullif(btrim(coalesce(d->>'ende', '')), '') IS NULL AND z1 IS NOT NULL THEN ((z1 AT TIME ZONE 'Europe/Berlin')::date + 1)::timestamp AT TIME ZONE 'Europe/Berlin'
                 WHEN z2 IS NOT NULL THEN (z2 AT TIME ZONE 'Europe/Berlin')::date::timestamp AT TIME ZONE 'Europe/Berlin' END;
    END IF;
    fu := CASE WHEN nullif(btrim(coalesce(d->>'fuer', '')), '') IS NOT NULL THEN btrim(d->>'fuer') WHEN p_aktion = 'kt_neu' THEN u ELSE t.fuer END;
    IF d ? 'eingeladen' THEN
      ein := ARRAY(SELECT DISTINCT btrim(y) FROM jsonb_array_elements_text(CASE WHEN jsonb_typeof(d->'eingeladen') = 'array' THEN d->'eingeladen'
                                                                               WHEN jsonb_typeof(d->'eingeladen') = 'string' AND d->>'eingeladen' <> '' THEN jsonb_build_array(d->>'eingeladen')
                                                                               ELSE '[]'::jsonb END) y WHERE btrim(y) <> '' ORDER BY 1);
    ELSIF p_aktion = 'kt_aendern' THEN
      ein := ARRAY(SELECT x.person FROM kalender_termin_personen x WHERE x.termin_id = t.id ORDER BY 1);
    ELSE
      ein := '{}';
    END IF;
    ein := array_remove(ein, fu);
    IF p_aktion = 'kt_aendern' AND (t.id IS NULL OR t.geloescht_am IS NOT NULL OR NOT kalender_termin_sichtbar(u, t.id)) THEN
      fehler := 'Diesen Termin gibt es nicht mehr oder er liegt im Papierkorb. Bitte die Seite neu laden.';
    ELSIF ti = '' OR length(ti) > 200 THEN
      fehler := 'Bitte einen Titel angeben (höchstens 200 Zeichen).';
    ELSIF z1 IS NULL OR z2 IS NULL THEN
      fehler := CASE WHEN ganz THEN 'Bitte den ersten und den letzten Tag angeben.' ELSE 'Bitte Beginn und Ende angeben (Datum und Uhrzeit).' END;
    ELSIF (ganz AND z2 <= z1) OR z2 < z1 THEN
      fehler := 'Das Ende liegt vor dem Beginn.';
    ELSIF z2 - z1 > interval '400 days' THEN
      fehler := 'Ein Termin darf höchstens 400 Tage dauern.';
    ELSIF length(coalesce(ort_, '')) > 200 OR length(coalesce(no, '')) > 2000 THEN
      fehler := 'Ort höchstens 200, Notiz höchstens 2.000 Zeichen.';
    ELSIF fu IS DISTINCT FROM t.fuer AND NOT kalender_person_waehlbar(fu) THEN
      fehler := 'Für diese Person lässt sich kein Termin eintragen.';
    ELSIF cardinality(ein) > 50 THEN
      fehler := 'Höchstens 50 eingeladene Personen.';
    ELSIF EXISTS (SELECT 1 FROM unnest(ein) y WHERE NOT kalender_person_waehlbar(y)
                    AND NOT EXISTS (SELECT 1 FROM kalender_termin_personen x WHERE x.termin_id = t.id AND x.person = y)) THEN
      fehler := 'Unter den Eingeladenen ist eine Person, die keinen Termin bekommen kann.';
    ELSIF p_aktion = 'kt_neu' THEN
      INSERT INTO kalender_termine (titel, ganztags, beginn, ende, ort, notiz, fuer, erstellt_von)
      VALUES (ti, ganz, z1, z2, ort_, no, fu, u) RETURNING id INTO neu_id;
      INSERT INTO kalender_termin_personen (termin_id, person) SELECT neu_id, y FROM unnest(ein) y;
      m := 'Termin „' || ti || '“ angelegt.';
    ELSE
      UPDATE kalender_termine SET titel = ti, ganztags = ganz, beginn = z1, ende = z2, ort = ort_, notiz = no, fuer = fu,
        geaendert_von = u, geaendert_am = now(), ics_sequenz = ics_sequenz + 1
      WHERE id = t.id;
      DELETE FROM kalender_termin_personen x WHERE x.termin_id = t.id AND NOT (x.person = ANY (ein));
      INSERT INTO kalender_termin_personen (termin_id, person) SELECT t.id, y FROM unnest(ein) y ON CONFLICT DO NOTHING;
      m := 'Termin gespeichert.';
    END IF;
  ELSIF p_aktion IN ('kt_papierkorb', 'kt_wiederherstellen', 'kt_endgueltig') THEN
    IF coalesce(d->>'id', '') ~ '^[0-9]{1,15}$' THEN SELECT * INTO t FROM kalender_termine x WHERE x.id = (d->>'id')::bigint FOR UPDATE; END IF;
    IF t.id IS NULL OR NOT kalender_termin_sichtbar(u, t.id) THEN
      fehler := 'Diesen Termin gibt es nicht mehr. Bitte die Seite neu laden.';
    ELSIF p_aktion = 'kt_papierkorb' AND t.geloescht_am IS NOT NULL THEN
      fehler := 'Der Termin liegt schon im Papierkorb.';
    ELSIF p_aktion <> 'kt_papierkorb' AND t.geloescht_am IS NULL THEN
      fehler := 'Der Termin liegt nicht im Papierkorb. Bitte die Seite neu laden.';
    ELSIF p_aktion = 'kt_papierkorb' THEN
      UPDATE kalender_termine SET geloescht_am = now(), geloescht_von = u, ics_sequenz = ics_sequenz + 1 WHERE id = t.id;
      m := 'Termin „' || t.titel || '“ liegt im Papierkorb.';
    ELSIF p_aktion = 'kt_wiederherstellen' THEN
      UPDATE kalender_termine SET geloescht_am = NULL, geloescht_von = NULL, ics_sequenz = ics_sequenz + 1 WHERE id = t.id;
      m := 'Termin „' || t.titel || '“ wiederhergestellt.';
    ELSE
      DELETE FROM kalender_termine WHERE id = t.id;
      m := 'Termin „' || t.titel || '“ endgültig gelöscht.';
    END IF;
  ELSIF p_aktion = 'kt_papierkorb_leeren' THEN
    IF coalesce(d->>'ids', '') !~ '^[0-9]{1,15}(,[0-9]{1,15}){0,199}$' THEN
      fehler := 'Der Papierkorb ist leer. Bitte die Seite neu laden.';
    ELSE
      ids := string_to_array(d->>'ids', ',')::bigint[];
      DELETE FROM kalender_termine t2 WHERE t2.id = ANY (ids) AND t2.geloescht_am IS NOT NULL AND kalender_termin_sichtbar(u, t2.id);
      GET DIAGNOSTICS n = ROW_COUNT;
      m := CASE WHEN n = 0 THEN 'Nichts gelöscht: Die Termine liegen nicht mehr im Papierkorb.' WHEN n = 1 THEN '1 Termin endgültig gelöscht.'
                ELSE n || ' Termine endgültig gelöscht.' END;
    END IF;
  ELSIF p_aktion = 'kt_quelle_aendern' THEN
    SELECT * INTO q FROM kalender_quellen k WHERE k.schluessel = coalesce(d->>'quelle', '');
    IF q.schluessel IS NULL OR q.aendern IS NULL OR (q.modul IS NOT NULL AND NOT coalesce(plattform_modul_an(q.modul), false))
       OR q.aendern !~ '^[a-z_][a-z0-9_]{0,62}$' OR to_regprocedure(format('public.%I(text,text,jsonb)', q.aendern)) IS NULL THEN
      fehler := 'Dieser Eintrag lässt sich im Kalender nicht ändern.';
    ELSIF coalesce(d->>'eintrag', '') !~ '^[a-z0-9-]{1,40}$' THEN
      fehler := 'Unbekannter Eintrag. Bitte die Seite neu laden.';
    ELSE
      -- Prüfung 205 (L5): scheitert die Ändern-Funktion einer Quelle, bleibt nichts geändert und es kommt eine Meldung statt eines Fehlers der Anfrage
      BEGIN
        EXECUTE format('SELECT public.%I($1, $2, $3)', q.aendern) INTO r USING p_token, d->>'eintrag', d - 'quelle' - 'eintrag';
        RETURN coalesce(r, jsonb_build_object('ok', true));
      EXCEPTION WHEN OTHERS THEN
        fehler := 'Das hat nicht geklappt, nichts geändert. Bitte später noch einmal versuchen.';
      END;
    END IF;
  ELSE
    fehler := 'Diese Aktion gibt es im Kalender nicht.';
  END IF;
  PERFORM ally_web_meldung(p_token, coalesce(fehler, m), CASE WHEN fehler IS NULL THEN 'ok' ELSE 'fehler' END, NULL);
  RETURN jsonb_build_object('ok', fehler IS NULL);
END $function$;
CREATE OR REPLACE FUNCTION public.kalender_ui_aktion(p_sitzung text, p_csrf text, p_aktion text, p_daten jsonb, p_zustand jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
  s record; e jsonb; r jsonb;
BEGIN
  -- Migration 205 (interner Kalender, Stefan 04.11.2026): Aktionen der Seite Kalender (kt_*) aus ALLY 20 „Aktion ausführen“ (vor ally_ui_aktion; NULL = nicht
  -- zuständig). Sitzung, Schutzwert und Klappzustände wie ally_ui_aktion, dann kalender_web_aktion (prüft die Rechte und setzt die Meldung selbst).
  -- „Neuer Termin“ im Google Kalender: weiter = arbeit mit den Angaben von arbeit_web_aktion (ALLY 37), wie termin_neu über ally_ui_aktion.
  IF coalesce(p_aktion, '') !~ '^kt_[a-z_]{1,30}$' THEN RETURN NULL; END IF;
  SELECT * INTO s FROM ally_ui_sitzung(p_sitzung);
  IF s.token_hash IS NULL THEN RETURN jsonb_build_object('ok', false, 'angemeldet', false); END IF;
  IF coalesce(p_csrf, '') <> ally_ui_csrf(s.token_hash) THEN
    PERFORM ally_web_meldung(p_sitzung, 'Die Anfrage wurde abgelehnt. Bitte die Seite neu laden.', 'fehler', NULL);
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
  r := kalender_web_aktion(p_sitzung, p_aktion, p_daten);
  IF coalesce(r->>'weiter', '') <> '' THEN
    RETURN jsonb_build_object('ok', coalesce((r->>'ok')::boolean, true), 'angemeldet', true, 'fertig', false, 'weiter', 'arbeit',
      'r', r || jsonb_build_object('produkt_name', coalesce(produkt_name(), '')));
  END IF;
  RETURN jsonb_build_object('ok', coalesce((r->>'ok')::boolean, true), 'angemeldet', coalesce((r->>'angemeldet')::boolean, true), 'fertig', false, 'weiter', NULL, 'r', NULL);
END $function$;
CREATE OR REPLACE FUNCTION public.talents_kalender_eintraege(p_person text, p_von date, p_bis date, p_ics boolean)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
  a jsonb; dl jsonb; ka jsonb;
BEGIN
  -- Migration 205 (interner Kalender, Stefan 04.11.2026): Kalenderquelle des Pakets Social-Media Management (kalender_quellen 'talents'), gelesen von
  -- kalender_eintraege für die Seite Kalender und das Kalender-Abo. Wer sieht was (Stefan 08:40): die Person, die den Eintrag angelegt hat, und die Person,
  -- für die er ist; für ein Talent (auch vom System angelegt) sehen ihn seine Manager/innen. Dazu gilt das Recht „Talents ansehen“ (talent_sichtbar).
  --   Aufgaben, Termine, Reviews und Erinnerungen (talent_aufgaben) aktiver Talents: Manager/in des Talents oder angelegt von der Person.
  --   Deadline und Veröffentlichung der Deliverables nicht abgebrochener Kampagnen: Manager/in des Talents, zuständig für die Kampagne oder angelegt von der Person.
  --   Zeitraum der Kampagne (nicht abgebrochen): zuständig, angelegt von der Person oder Manager/in eines Talents der Kampagne (talents_planung_recht).
  -- Ändern im Kalender (felder, aenderbar): Datum und Uhrzeit der Aufgaben/Termine und die Tage der Deliverables nach den Rechten des Pakets
  -- (talents_kalender_aendern); der Zeitraum einer Kampagne nur auf der Seite der Kampagne. VEVENTs (p_ics) wie bisher im Kalender-Abo.
  IF talents_zugriff(p_person) IS NULL OR NOT EXISTS (SELECT 1 FROM ally_personen p WHERE p.matrix_user_id = p_person AND p.aktiv) THEN RETURN '[]'::jsonb; END IF;

  SELECT coalesce(jsonb_agg(jsonb_build_object('id', 'a-' || x.id, 'art', x.art,
      'art_text', CASE x.art WHEN 'termin' THEN 'Termin' WHEN 'review' THEN 'Review' WHEN 'erinnerung' THEN 'Erinnerung' ELSE 'Aufgabe' END,
      'titel', x.titel, 'ganztags', x.gz, 'tag', to_char(x.tag, 'YYYY-MM-DD'), 'bis_tag', to_char(greatest(x.bis_tag, x.tag), 'YYYY-MM-DD'),
      'von', CASE WHEN NOT x.gz THEN to_char(x.z1 AT TIME ZONE 'Europe/Berlin', 'HH24:MI') END,
      'bis', CASE WHEN NOT x.gz AND x.art = 'termin' AND x.ende IS NOT NULL THEN to_char(x.ende AT TIME ZONE 'Europe/Berlin', 'HH24:MI') END,
      'ort', coalesce(x.ort, ''), 'notiz', left(coalesce(x.text, ''), 1000),
      'kontext', concat_ws(' · ', coalesce(talent_listenname(x.talent_id), 'Talent'), (SELECT k.marke || ' – ' || k.name FROM talent_kampagnen k WHERE k.id = x.kampagne_id)),
      'status_text', CASE x.status WHEN 'erledigt' THEN 'Erledigt' WHEN 'abgesagt' THEN 'Abgesagt' ELSE 'Offen' END,
      'ziel', jsonb_build_object('seite', 'talent', 'parameter', jsonb_build_object('id', x.talent_id::text, 'f', 'a-' || x.id), 'anker', 'a-aufgaben'),
      'ziel_text', 'Im Talent-Profil öffnen',
      'aenderbar', x.darf,
      'felder', CASE WHEN NOT x.darf THEN '[]'::jsonb
                     WHEN x.art = 'termin' AND x.gz THEN jsonb_build_array(
                       jsonb_build_object('typ', 'datum', 'name', 'wann', 'label', 'Erster Tag', 'wert', to_char(x.tag, 'YYYY-MM-DD')),
                       -- Prüfung 205 (M2): ohne gespeichertes Ende bleibt das Feld leer (sonst gälte unverändertes Speichern als Änderung)
                       jsonb_build_object('typ', 'datum', 'name', 'ende', 'label', 'Letzter Tag', 'wert', CASE WHEN x.ende IS NULL THEN '' ELSE to_char(greatest(x.bis_tag, x.tag), 'YYYY-MM-DD') END))
                     WHEN x.art = 'termin' THEN jsonb_build_array(
                       jsonb_build_object('typ', 'datum_zeit', 'name', 'wann', 'label', 'Beginn', 'wert', to_char(x.z1 AT TIME ZONE 'Europe/Berlin', 'YYYY-MM-DD"T"HH24:MI')),
                       jsonb_build_object('typ', 'datum_zeit', 'name', 'ende', 'label', 'Ende', 'wert', coalesce(to_char(x.ende AT TIME ZONE 'Europe/Berlin', 'YYYY-MM-DD"T"HH24:MI'), '')))
                     ELSE jsonb_build_array(jsonb_build_object('typ', 'datum_zeit', 'name', 'wann', 'label', 'Fällig am',
                       'wert', to_char(x.z1 AT TIME ZONE 'Europe/Berlin', 'YYYY-MM-DD"T"HH24:MI'))) END)
    || CASE WHEN p_ics THEN jsonb_build_object('ics', coalesce(ally_ics_aufgabe(x.id, true), '')) ELSE '{}'::jsonb END
    ORDER BY x.z1, x.id), '[]'::jsonb) INTO a
  FROM (SELECT t.id, t.art, t.titel, t.text, t.ort, t.status, t.talent_id, t.kampagne_id, t.ende, coalesce(t.beginn, t.faellig_am) AS z1,
               t.art = 'termin' AND t.ganztags AS gz,
               (coalesce(t.beginn, t.faellig_am) AT TIME ZONE 'Europe/Berlin')::date AS tag,
               (coalesce(t.ende, t.beginn, t.faellig_am) AT TIME ZONE 'Europe/Berlin')::date AS bis_tag,
               CASE WHEN t.kampagne_id IS NULL THEN coalesce(talent_verwaltbar(p_person, t.talent_id), false)
                    ELSE coalesce(talents_planung_talent_verwaltbar(p_person, t.kampagne_id, t.talent_id), false) END AS darf
        FROM talent_aufgaben t JOIN talents tt ON tt.id = t.talent_id AND tt.status = 'aktiv'
        WHERE coalesce(t.beginn, t.faellig_am) IS NOT NULL
          AND (coalesce(t.beginn, t.faellig_am) AT TIME ZONE 'Europe/Berlin')::date <= p_bis
          AND (coalesce(t.ende, t.beginn, t.faellig_am) AT TIME ZONE 'Europe/Berlin')::date >= p_von
          AND (EXISTS (SELECT 1 FROM talent_personen tp WHERE tp.talent_id = t.talent_id AND tp.matrix_user_id = p_person) OR t.erstellt_von = p_person)
          AND coalesce(talent_sichtbar(p_person, t.talent_id), false)
        ORDER BY coalesce(t.beginn, t.faellig_am), t.id LIMIT 600) x;

  SELECT coalesce(jsonb_agg(jsonb_build_object('id', CASE WHEN x.was = 'deadline' THEN 'd-' ELSE 'v-' END || x.id, 'art', x.was,
      'art_text', CASE WHEN x.was = 'deadline' THEN 'Deadline' ELSE 'Veröffentlichung' END,
      'titel', talents_planung_deliverable_name(x.format, x.anzahl, x.titel), 'ganztags', true, 'tag', to_char(x.tag, 'YYYY-MM-DD'), 'bis_tag', to_char(x.tag, 'YYYY-MM-DD'),
      'ort', '', 'notiz', '',
      'kontext', concat_ws(' · ', coalesce(talent_listenname(x.talent_id), 'Talent'), x.marke || ' – ' || x.kname),
      'status_text', talents_planung_status_text(x.status),
      'ziel', jsonb_build_object('seite', 'kampagnen', 'parameter', jsonb_build_object('kampagne', x.kampagne_id::text), 'anker', 'a-deliverables'),
      'ziel_text', 'Kampagne öffnen',
      'aenderbar', x.darf,
      'felder', CASE WHEN NOT x.darf THEN '[]'::jsonb
                     ELSE jsonb_build_array(jsonb_build_object('typ', 'datum', 'name', CASE WHEN x.was = 'deadline' THEN 'deadline' ELSE 'veroeffentlichen_am' END,
                       'label', CASE WHEN x.was = 'deadline' THEN 'Deadline' ELSE 'Veröffentlichung' END, 'wert', to_char(x.tag, 'YYYY-MM-DD'))) END)
    || CASE WHEN p_ics THEN jsonb_build_object('ics', coalesce(ally_ics_deliverable(x.id, x.was, true), '')) ELSE '{}'::jsonb END
    ORDER BY x.tag, x.id, x.was), '[]'::jsonb) INTO dl
  FROM (SELECT d.id, w.was, d.format, d.anzahl, d.titel, d.status, d.talent_id, d.kampagne_id, k.marke, k.name AS kname,
               CASE WHEN w.was = 'deadline' THEN d.deadline ELSE d.veroeffentlichen_am END AS tag,
               coalesce(talents_planung_talent_verwaltbar(p_person, d.kampagne_id, d.talent_id), false) AS darf
        FROM talent_deliverables d JOIN talent_kampagnen k ON k.id = d.kampagne_id AND k.abgebrochen_am IS NULL
        JOIN talents tt ON tt.id = d.talent_id AND tt.status = 'aktiv'
        CROSS JOIN (VALUES ('deadline'), ('veroeffentlichung')) AS w(was)
        WHERE (CASE WHEN w.was = 'deadline' THEN d.deadline ELSE d.veroeffentlichen_am END) BETWEEN p_von AND p_bis
          AND (EXISTS (SELECT 1 FROM talent_personen tp WHERE tp.talent_id = d.talent_id AND tp.matrix_user_id = p_person)
               OR ((k.zustaendig = p_person OR d.erstellt_von = p_person) AND coalesce(talent_sichtbar(p_person, d.talent_id), false)))
        ORDER BY tag, d.id, w.was LIMIT 400) x;

  SELECT coalesce(jsonb_agg(jsonb_build_object('id', 'k-' || x.id, 'art', 'kampagne', 'art_text', 'Kampagne', 'titel', x.marke || ' – ' || x.name,
      'ganztags', true, 'tag', to_char(x.von, 'YYYY-MM-DD'), 'bis_tag', to_char(greatest(coalesce(x.bis, x.von), x.von), 'YYYY-MM-DD'),
      'ort', '', 'notiz', '',
      'kontext', coalesce((SELECT string_agg(coalesce(talent_listenname(kt.talent_id), 'Talent'), ', ' ORDER BY coalesce(talent_listenname(kt.talent_id), ''))
                           FROM talent_kampagne_talents kt JOIN talents tt ON tt.id = kt.talent_id AND tt.status = 'aktiv'
                           WHERE kt.kampagne_id = x.id AND coalesce(talent_sichtbar(p_person, kt.talent_id), false)), ''),
      'status_text', '', 'ziel', jsonb_build_object('seite', 'kampagnen', 'parameter', jsonb_build_object('kampagne', x.id::text)),
      'ziel_text', 'Kampagne öffnen', 'aenderbar', false, 'felder', '[]'::jsonb,
      'hinweis', 'Den Zeitraum änderst du auf der Seite der Kampagne.')
    -- Prüfung 205 (L8): SEQUENCE aus dem Zeitpunkt der letzten Änderung (Minuten seit 2026), damit Kalender-Apps einen geänderten Zeitraum übernehmen
    || CASE WHEN p_ics THEN jsonb_build_object('ics', ally_ics_ereignis('kampagne-' || x.id || '@' || ally_ics_domain(), x.seq, NULL, NULL, true, x.von,
         greatest(coalesce(x.bis, x.von), x.von), 'Kampagne: ' || x.marke || ' – ' || x.name, NULL, NULL, false, now())) ELSE '{}'::jsonb END
    ORDER BY x.von, x.id), '[]'::jsonb) INTO ka
  FROM (SELECT k.id, k.marke, k.name, k.von, k.bis,
               greatest(0, floor((extract(epoch FROM coalesce(k.geaendert_am, k.erstellt_am, now())) - 1767225600) / 60))::integer AS seq
        FROM talent_kampagnen k
        WHERE k.abgebrochen_am IS NULL AND k.von IS NOT NULL AND k.von <= p_bis AND coalesce(k.bis, k.von) >= p_von
          AND (k.zustaendig = p_person OR k.erstellt_von = p_person
               OR EXISTS (SELECT 1 FROM talent_kampagne_talents kt JOIN talent_personen tp ON tp.talent_id = kt.talent_id AND tp.matrix_user_id = p_person
                          JOIN talents tt ON tt.id = kt.talent_id AND tt.status = 'aktiv' WHERE kt.kampagne_id = k.id))
          AND talents_planung_recht(p_person, k.id) IS NOT NULL
        ORDER BY k.von, k.id LIMIT 200) x;

  RETURN a || dl || ka;
END $function$;
CREATE OR REPLACE FUNCTION public.talents_kalender_aendern(p_token text, p_eintrag text, p_daten jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
  d jsonb := CASE WHEN jsonb_typeof(p_daten) = 'object' THEN p_daten ELSE '{}'::jsonb END;
  a talent_aufgaben%ROWTYPE; dl talent_deliverables%ROWTYPE; x jsonb; z1 timestamptz; z2 timestamptz; nr bigint; u text; gz boolean; gleich_w boolean; gleich_e boolean;
BEGIN
  -- Migration 205 (interner Kalender, Stefan 04.11.2026): Ändern-Funktion der Kalenderquelle 'talents' (kalender_web_aktion, Aktion kt_quelle_aendern).
  -- Geht über die vorhandenen Aktionen des Pakets, damit Rechte, Prüfungen und Benachrichtigungen dieselben sind wie im Talent-Profil und in der Kampagne:
  --   a-<id>: kp_aufgabe_aendern nur mit wann/ende; d-<id>: kp_deliverable_aendern nur mit deadline; v-<id>: nur mit veroeffentlichen_am.
  -- Ohne Änderung ruft sie nichts auf (sonst gingen z. B. Mails an das Talent erneut raus). Der Zeitraum einer Kampagne (k-<id>) nur auf der Seite der Kampagne.
  -- Prüfung 205 (M3): zuerst das Recht wie die Spalte aenderbar der Quelle (verwaltbar und sichtbar); ohne Recht dieselbe Meldung wie für einen
  -- fehlenden Eintrag, damit sich über Vergleiche nichts über fremde Einträge erfahren lässt.
  u := (SELECT y.person FROM ally_ui_sitzung(p_token) y WHERE NOT y.muss_pw_setzen);
  IF coalesce(p_eintrag, '') ~ '^a-[0-9]{1,15}$' THEN
    nr := substr(p_eintrag, 3)::bigint;
    SELECT * INTO a FROM talent_aufgaben t WHERE t.id = nr;
    IF a.id IS NULL OR u IS NULL OR NOT coalesce(talent_sichtbar(u, a.talent_id), false)
       OR NOT (CASE WHEN a.kampagne_id IS NULL THEN coalesce(talent_verwaltbar(u, a.talent_id), false)
                    ELSE coalesce(talents_planung_talent_verwaltbar(u, a.kampagne_id, a.talent_id), false) END) THEN
      PERFORM ally_web_meldung(p_token, 'Diesen Eintrag gibt es nicht mehr. Bitte die Seite neu laden.', 'fehler', NULL);
      RETURN jsonb_build_object('ok', false);
    END IF;
    x := (SELECT coalesce(jsonb_object_agg(e.key, e.value), '{}'::jsonb) FROM jsonb_each(d) e WHERE e.key IN ('wann', 'ende') AND (a.art = 'termin' OR e.key = 'wann'));
    z1 := talents_planung_zeit_lesen(x->>'wann');
    z2 := talents_planung_zeit_lesen(x->>'ende');
    -- Nachprüfung 205 (M2): ganztägig nur die Tage vergleichen (die Felder sind Tage, gespeichert sein kann eine Uhrzeit), sonst auf die Minute genau
    gz := a.art = 'termin' AND a.ganztags;
    gleich_w := NOT x ? 'wann' OR (CASE WHEN gz THEN (z1 AT TIME ZONE 'Europe/Berlin')::date IS NOT DISTINCT FROM (coalesce(a.beginn, a.faellig_am) AT TIME ZONE 'Europe/Berlin')::date
                                        ELSE date_trunc('minute', z1) IS NOT DISTINCT FROM date_trunc('minute', coalesce(a.beginn, a.faellig_am)) END);
    gleich_e := NOT x ? 'ende' OR ((nullif(btrim(coalesce(x->>'ende', '')), '') IS NULL) = (a.ende IS NULL)
                                  AND (CASE WHEN gz THEN (z2 AT TIME ZONE 'Europe/Berlin')::date IS NOT DISTINCT FROM (a.ende AT TIME ZONE 'Europe/Berlin')::date
                                            ELSE date_trunc('minute', z2) IS NOT DISTINCT FROM date_trunc('minute', a.ende) END));
    IF x = '{}'::jsonb OR (gleich_w AND gleich_e) THEN
      PERFORM ally_web_meldung(p_token, 'Nichts geändert.', 'ok', NULL);
      RETURN jsonb_build_object('ok', true);
    END IF;
    RETURN talents_planung_ui_aktion(p_token, 'kp_aufgabe_aendern', jsonb_build_object('id', nr::text) || x);
  ELSIF coalesce(p_eintrag, '') ~ '^[dv]-[0-9]{1,15}$' THEN
    nr := substr(p_eintrag, 3)::bigint;
    SELECT * INTO dl FROM talent_deliverables t WHERE t.id = nr;
    x := CASE WHEN left(p_eintrag, 1) = 'd' AND d ? 'deadline' THEN jsonb_build_object('deadline', d->'deadline')
              WHEN left(p_eintrag, 1) = 'v' AND d ? 'veroeffentlichen_am' THEN jsonb_build_object('veroeffentlichen_am', d->'veroeffentlichen_am') END;
    IF dl.id IS NULL OR x IS NULL OR u IS NULL OR NOT coalesce(talent_sichtbar(u, dl.talent_id), false)
       OR NOT coalesce(talents_planung_talent_verwaltbar(u, dl.kampagne_id, dl.talent_id), false) THEN
      PERFORM ally_web_meldung(p_token, 'Diesen Eintrag gibt es nicht mehr. Bitte die Seite neu laden.', 'fehler', NULL);
      RETURN jsonb_build_object('ok', false);
    ELSIF (talents_datum_lesen(coalesce(x->>'deadline', x->>'veroeffentlichen_am')) IS NOT DISTINCT FROM
           (CASE WHEN left(p_eintrag, 1) = 'd' THEN dl.deadline ELSE dl.veroeffentlichen_am END))
          AND (nullif(btrim(coalesce(x->>'deadline', x->>'veroeffentlichen_am', '')), '') IS NULL)
              = ((CASE WHEN left(p_eintrag, 1) = 'd' THEN dl.deadline ELSE dl.veroeffentlichen_am END) IS NULL) THEN
      PERFORM ally_web_meldung(p_token, 'Nichts geändert.', 'ok', NULL);
      RETURN jsonb_build_object('ok', true);
    END IF;
    RETURN talents_planung_ui_aktion(p_token, 'kp_deliverable_aendern', jsonb_build_object('id', nr::text) || x);
  END IF;
  PERFORM ally_web_meldung(p_token, 'Diesen Eintrag änderst du auf der Seite des Pakets (Link „Öffnen“).', 'fehler', NULL);
  RETURN jsonb_build_object('ok', false);
END $function$;
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
  -- Migration 205 (interner Kalender, Stefan 04.11.2026): Person über kalender_eintraege (eigene interne Termine und die Kalenderquellen der Pakete).
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
    -- Migration 205 (interner Kalender, Stefan 04.11.2026): dieselbe Stelle wie die Seite Kalender (kalender_eintraege): eigene interne Termine und die Einträge
    -- der Kalenderquellen der Pakete (Social-Media Management: Aufgaben, Termine, Deadlines, Veröffentlichungen, Zeitraum der Kampagnen), höchstens 2.000.
    -- Prüfung 205 (L4): antwortet eine Quelle nicht, scheitert der Abruf (die Kalender-App behält ihren Stand), statt Einträge still wegzulassen.
    sicht := kalender_eintraege(a.person, d_von, d_bis, true);
    IF jsonb_array_length(coalesce(sicht->'fehler', '[]'::jsonb)) > 0 THEN RAISE EXCEPTION 'Kalender-Abo: eine Kalenderquelle hat nicht geantwortet'; END IF;
    FOR rec IN SELECT y->>'ics' AS ics FROM jsonb_array_elements(sicht->'eintraege') y LIMIT 2000 LOOP
      ev := ev || coalesce(rec.ics, ''); n := n + 1;
    END LOOP;
  END IF;
  UPDATE ally_kalender_abos SET letzter_abruf = now(), abrufe = abrufe + 1 WHERE id = a.id;
  RETURN ally_ics_kalender(name, ev);
END $function$;
DO $m$
BEGIN
  IF (SELECT md5(string_agg(z, E'\n' ORDER BY z COLLATE "C")) FROM (WITH t AS (SELECT c.oid, c.relname::text AS tab FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname::text = 'public' COLLATE "C" AND c.relkind::text = ANY (ARRAY['r', 'p']) AND c.relname::text = ANY (ARRAY['kalender_termine', 'kalender_termin_personen', 'kalender_quellen'])) SELECT 'S|' || t.tab || '|' || a.attname::text || '|' || format_type(a.atttypid, a.atttypmod) || '|' || CASE WHEN a.attnotnull THEN 'NN' ELSE '-' END || '|' || coalesce(pg_get_expr(d.adbin, d.adrelid), '') || '|' || a.attidentity::text || a.attgenerated::text AS z FROM t JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum > 0 AND NOT a.attisdropped LEFT JOIN pg_attrdef d ON d.adrelid = t.oid AND d.adnum = a.attnum UNION ALL SELECT 'C|' || t.tab || '|' || co.conname::text || '|' || co.contype::text || '|' || pg_get_constraintdef(co.oid) FROM t JOIN pg_constraint co ON co.conrelid = t.oid UNION ALL SELECT 'I|' || t.tab || '|' || ic.relname::text || '|' || pg_get_indexdef(i.indexrelid) FROM t JOIN pg_index i ON i.indrelid = t.oid JOIN pg_class ic ON ic.oid = i.indexrelid UNION ALL SELECT 'T|' || t.tab || '|' || tg.tgname::text || '|' || pg_get_triggerdef(tg.oid) || '|' || tg.tgenabled::text FROM t JOIN pg_trigger tg ON tg.tgrelid = t.oid AND NOT tg.tgisinternal) x) IS DISTINCT FROM '22d524eb9633e7b5970679a1b37960c1' THEN RAISE EXCEPTION 'Migration 205: Tabellen des internen Kalenders nicht wie gebaut'; END IF;
  IF (SELECT md5(string_agg(p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')|' || pg_get_function_result(p.oid) || '|' || md5(p.prosrc), E'\n' ORDER BY p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')' COLLATE "C")) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname::text = 'public' COLLATE "C" AND p.proname::text COLLATE "C" = ANY (ARRAY['ally_kalender_ics', 'kalender_person_waehlbar', 'kalender_termin_sichtbar', 'kalender_zeit_lesen', 'kalender_termin_eintrag', 'kalender_eintraege', 'kalender_web_seite', 'kalender_web_aktion', 'kalender_ui_aktion', 'talents_kalender_eintraege', 'talents_kalender_aendern'])) IS DISTINCT FROM '2ed562ddf5beef8407cd01c517b68a88' THEN RAISE EXCEPTION 'Migration 205: Funktionen nicht wie gebaut'; END IF;
  IF (SELECT count(*) FROM public.kalender_quellen) <> 1 THEN RAISE EXCEPTION 'Migration 205: Kalenderquelle nicht eingetragen'; END IF;
END $m$;
