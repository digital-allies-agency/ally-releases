-- Migration 210 (Stefan 06.11.2026 „Name“): Objekte in Adressen mit ihrem Namen als Kennung statt der Nummer, z. B. /talent-profil/mia-muster (Talent: Künstlername,
-- sonst Name – wie im Kopf des Profils), /kampagnen/sommer-2026, /briefing/taegliches-briefing, /einstellungen/team-und-rollen/personen/anna-anwender,
-- /mein-bereich/ordner/vertraege, /briefing/taegliches-briefing/2026-11-06 (Ergebnis als Datum), /planer/termin/teammeeting, /benachrichtigungen/ergebnis/<Titel>.
-- Intern bleibt alles bei den Nummern. Links, die Web-App, Baukasten und Abläufe bauen, tragen direkt die Kennung (Karte der Kennungen: ally_ui_kennungen_karte).
-- a) Tabellen ally_ui_kennung_arten (Objektarten) und ally_ui_kennungen (Kennungen mit Verlauf). Kennung: klein, ä → ae, ö → oe, ü → ue, ß → ss, andere Zeichen → -,
--    eindeutig je Objektart (bei gleichem Namen -2, -3 …), nie nur Ziffern und nie ein fester Teil einer Adresse (z. B. neu, papierkorb).
-- b) Bei neuem Namen neue Kennung; frühere bleiben reserviert und führen dauerhaft (301, ALLY 20) zur aktuellen. Kennungen gelöschter Objekte und solcher im
--    Papierkorb bleiben reserviert. Ohne Recht auf das Objekt verhält sich eine Kennung wie eine unbekannte (ally_ui_kennungen).
-- c) ally_ui_pfad setzt die Kennung statt der Nummer in Adressen (Links in Mails, Chat, Seiten); alte Adressen mit Nummer (auch /ki-analysen/<Nummer>)
--    leitet ALLY 20 auf die Kennung um.
-- Wirkt nur mit Adressen als Pfad (Merker adressen_pfade, Migration 209); sonst bleiben Adressen wie bisher.
-- Wächter vorher: Funktionen wie nach 209, keine Teile von 210, keine Sicherung aus Rückbau 210. Läuft als Ganzes in der Transaktion des Aufrufs (psql -1).
-- Rückbau: rueckbau210.sql.
DO $m$
BEGIN
  IF (SELECT md5(string_agg(p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')|' || pg_get_function_result(p.oid) || '|' || md5(p.prosrc), E'\n' ORDER BY p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')' COLLATE "C")) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname::text = 'public' COLLATE "C" AND p.proname::text COLLATE "C" = ANY (ARRAY['ally_ui_pfad', 'ally_ui_kennung_text', 'ally_ui_kn_talent', 'ally_ui_kn_talent_darf', 'ally_ui_kn_kampagne', 'ally_ui_kn_kampagne_darf', 'ally_ui_kn_briefing', 'ally_ui_kn_briefing_darf', 'ally_ui_kn_ergebnis', 'ally_ui_kn_ergebnis_bereich', 'ally_ui_kn_ergebnis_darf', 'ally_ui_kn_person', 'ally_ui_kn_person_darf', 'ally_ui_kn_ordner', 'ally_ui_kn_ordner_darf', 'ally_ui_kn_termin', 'ally_ui_kn_termin_darf', 'ally_ui_kn_benachrichtigung', 'ally_ui_kn_benachrichtigung_bereich', 'ally_ui_kn_benachrichtigung_darf', 'ally_ui_kennung_person', 'ally_ui_kennung', 'ally_ui_kennung_person_teil', 'ally_ui_kennung_personen', 'ally_ui_kennung_fuer', 'ally_ui_kennung_pflegen', 'ally_ui_kennung_ausloeser', 'ally_ui_pfad_bauen', 'ally_ui_kennungen', 'ally_ui_kennungen_karte'])) IS NOT DISTINCT FROM '1103966ca87c6ed8c9a4bfef7019b9f1' THEN RAISE EXCEPTION 'Migration 210: schon eingespielt, nichts geändert'; END IF;
  IF (SELECT md5(string_agg(p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')|' || pg_get_function_result(p.oid) || '|' || md5(p.prosrc), E'\n' ORDER BY p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')' COLLATE "C")) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname::text = 'public' COLLATE "C" AND p.proname::text COLLATE "C" = ANY (ARRAY['ally_ui_pfad', 'ally_ui_kennung_text', 'ally_ui_kn_talent', 'ally_ui_kn_talent_darf', 'ally_ui_kn_kampagne', 'ally_ui_kn_kampagne_darf', 'ally_ui_kn_briefing', 'ally_ui_kn_briefing_darf', 'ally_ui_kn_ergebnis', 'ally_ui_kn_ergebnis_bereich', 'ally_ui_kn_ergebnis_darf', 'ally_ui_kn_person', 'ally_ui_kn_person_darf', 'ally_ui_kn_ordner', 'ally_ui_kn_ordner_darf', 'ally_ui_kn_termin', 'ally_ui_kn_termin_darf', 'ally_ui_kn_benachrichtigung', 'ally_ui_kn_benachrichtigung_bereich', 'ally_ui_kn_benachrichtigung_darf', 'ally_ui_kennung_person', 'ally_ui_kennung', 'ally_ui_kennung_person_teil', 'ally_ui_kennung_personen', 'ally_ui_kennung_fuer', 'ally_ui_kennung_pflegen', 'ally_ui_kennung_ausloeser', 'ally_ui_pfad_bauen', 'ally_ui_kennungen', 'ally_ui_kennungen_karte'])) IS DISTINCT FROM 'ff22670c942e01e9277613040195a42c' THEN RAISE EXCEPTION 'Migration 210: Funktionen nicht im erwarteten Stand, nichts geändert'; END IF;
  IF to_regclass('public.ally_ui_kennung_arten') IS NOT NULL OR to_regclass('public.ally_ui_kennung_arten_rb210') IS NOT NULL OR to_regclass('public.ally_ui_kennungen') IS NOT NULL OR to_regclass('public.ally_ui_kennungen_rb210') IS NOT NULL THEN RAISE EXCEPTION 'Migration 210: Tabellen von 210 oder eine Sicherung aus Rückbau 210 gibt es schon, nichts geändert'; END IF;
END $m$;
-- Migration 210 (Stefan 06.11.2026 „Name“): Objekte in Adressen mit ihrem Namen als Kennung (z. B. /talent-profil/mia-muster, /kampagnen/sommer-2026,
-- /briefing/taegliches-briefing, /briefing/taegliches-briefing/2026-11-06, /planer/termin/teammeeting, /einstellungen/team-und-rollen/personen/anna-anwender).
-- Intern bleibt alles bei den Nummern.
-- Objektarten: welcher Parameter welcher Seite eine Kennung bekommt, woher der Name kommt (Funktion name(objekt) → text) und wer die Objekte sehen darf
-- (Funktion darf(person, objekte text[]) → die sichtbaren Objekte, als Menge geprüft; ohne Recht verhält sich eine Kennung wie eine unbekannte).
-- Zusatzpakete melden weitere Arten an.
CREATE TABLE public.ally_ui_kennung_arten (
  art text PRIMARY KEY CHECK (art ~ '^[a-z][a-z0-9_]{0,39}$'),
  seite text NOT NULL CHECK (seite ~ '^[a-z0-9-]{1,40}$'),
  parameter text NOT NULL CHECK (parameter ~ '^[a-z][a-z0-9_]{0,29}$'),
  name_funktion text NOT NULL CHECK (name_funktion ~ '^[a-z_][a-z0-9_]{0,62}$'),
  darf_funktion text NOT NULL CHECK (darf_funktion ~ '^[a-z_][a-z0-9_]{0,62}$'),
  ersatz text NOT NULL CHECK (ersatz ~ '^[a-z][a-z0-9-]{0,19}$'),
  -- Kennung nur innerhalb eines Bereichs eindeutig (bereich_funktion(objekt) → text): Nummer eines anderen Objekts der Seite (bereich_parameter, z. B. Briefing
  -- eines Ergebnisses), dazu mit bereich_person „|“ und die Person, für die das Objekt ist (so verrät ein -2 nichts über Einträge anderer)
  bereich_parameter text CHECK (bereich_parameter ~ '^[a-z][a-z0-9_]{0,29}$'),
  bereich_funktion text CHECK (bereich_funktion ~ '^[a-z_][a-z0-9_]{0,62}$'),
  bereich_person boolean NOT NULL DEFAULT false,
  -- Wert für die Seite bei unbekannter Kennung oder ohne Recht ('0'); NULL = Wert bleibt (Parameter mit fremden Kennungen, z. B. Termine anderer Kalender)
  unbekannt text DEFAULT '0',
  UNIQUE (seite, parameter),
  CHECK (bereich_funktion IS NOT NULL OR (bereich_parameter IS NULL AND NOT bereich_person))
);
-- Kennungen je Art (und Bereich): eindeutig (bei gleichem Namen -2, -3 …), auch frühere bleiben reserviert und führen per 301 zur aktuellen; je Objekt genau eine aktuelle.
-- Kennungen gelöschter Objekte bleiben reserviert.
CREATE TABLE public.ally_ui_kennungen (
  art text NOT NULL REFERENCES public.ally_ui_kennung_arten(art) ON UPDATE CASCADE ON DELETE CASCADE,
  kennung text NOT NULL CHECK (kennung ~ '^[a-z0-9]([a-z0-9-]{0,68}[a-z0-9])?$'),
  objekt text NOT NULL CHECK (length(objekt) BETWEEN 1 AND 200),
  bereich text NOT NULL DEFAULT '' CHECK (length(bereich) <= 200),
  basis text NOT NULL,
  aktuell boolean NOT NULL DEFAULT false,
  erstellt_am timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (art, bereich, kennung)
);
CREATE UNIQUE INDEX ally_ui_kennungen_aktuell ON public.ally_ui_kennungen (art, objekt) WHERE aktuell;
CREATE INDEX ally_ui_kennungen_objekt ON public.ally_ui_kennungen (art, objekt);
COMMENT ON TABLE public.ally_ui_kennungen IS 'Migration 210: lesbare Kennungen der Objekte in Adressen (ally_ui_kennung_pflegen, ally_ui_kennungen).';
CREATE OR REPLACE FUNCTION public.ally_ui_kennung_text(p_name text, p_ersatz text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
AS $function$
  -- Migration 210 (Stefan 06.11.2026 „Name“): lesbare Kennung aus einem Namen – klein, ä/ö/ü/ß → ae/oe/ue/ss, weitere Akzente ohne Zeichen, alles andere → Bindestrich,
  -- höchstens 60 Zeichen. Leer → Ersatz der Objektart; nur Ziffern oder ein Buchstabe mit
  -- Bindestrich vorn (Form der Kennungen anderer Quellen, z. B. Termine i-12, a-3, q-…) → Ersatz davor: eine Kennung ist nie eine Nummer oder eine fremde Kennung.
  -- Unabhängig von der Sortierung der Datenbank (Umlaute und Akzente vor lower() ersetzt).
  WITH a AS (SELECT lower(translate(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(coalesce(p_name, ''),
           'ä', 'ae'), 'ö', 'oe'), 'ü', 'ue'), 'Ä', 'ae'), 'Ö', 'oe'), 'Ü', 'ue'), 'ß', 'ss'), 'ẞ', 'ss'), 'æ', 'ae'), 'Æ', 'ae'), 'œ', 'oe'),
           'àáâãåāăąÀÁÂÃÅĀĂĄçćčÇĆČďđĎĐèéêëēėęěÈÉÊËĒĖĘĚìíîïīįÌÍÎÏĪĮłŁñńňÑŃŇòóôõøōőÒÓÔÕØŌŐŕřŔŘśšşŚŠŞțťȚŤùúûūůűųÙÚÛŪŮŰŲýÿÝŸźżžŹŻŽ', 'aaaaaaaaaaaaaaaaccccccddddeeeeeeeeeeeeeeeeiiiiiiiiiiiillnnnnnnoooooooooooooorrrrssssssttttuuuuuuuuuuuuuuyyyyzzzzzz')) AS s),
  b AS (SELECT btrim(left(btrim(regexp_replace(a.s, '[^a-z0-9]+', '-', 'g'), '-'), 60), '-') AS s FROM a)
  SELECT CASE WHEN b.s = '' THEN p_ersatz WHEN b.s ~ '^[0-9]+$' OR b.s ~ '^[a-z]-' THEN p_ersatz || '-' || b.s ELSE b.s END FROM b
$function$;
CREATE OR REPLACE FUNCTION public.ally_ui_kn_talent(p_objekt text)
 RETURNS text
 LANGUAGE sql
 STABLE
AS $function$
  -- Migration 210: Name eines Talents für die Adresse wie im Kopf des Profils (Künstlername, sonst Name)
  SELECT public.talent_anzeigename(p_objekt::integer) WHERE p_objekt ~ '^[0-9]{1,9}$'
$function$;
CREATE OR REPLACE FUNCTION public.ally_ui_kn_talent_darf(p_person text, p_objekte text[])
 RETURNS SETOF text
 LANGUAGE sql
 STABLE
AS $function$
  -- Migration 210: welche der Talents die Person sieht (wie talent_sichtbar, als Menge: Reichweite „Talents ansehen“ einmal je Aufruf)
  WITH z AS MATERIALIZED (SELECT public.talents_zugriff(p_person) AS z)
  SELECT t.id::text FROM public.talents t, z
  WHERE t.id IN (SELECT o::integer FROM unnest(p_objekte) o WHERE o ~ '^[0-9]{1,9}$')
    AND (z.z = 'alle' OR (z.z = 'eigene' AND EXISTS (SELECT 1 FROM public.talent_personen tp WHERE tp.talent_id = t.id AND tp.matrix_user_id = p_person)))
$function$;
CREATE OR REPLACE FUNCTION public.ally_ui_kn_kampagne(p_objekt text)
 RETURNS text
 LANGUAGE sql
 STABLE
AS $function$
  -- Migration 210: Name einer Kampagne für die Adresse
  SELECT k.name FROM public.talent_kampagnen k WHERE p_objekt ~ '^[0-9]{1,9}$' AND k.id = p_objekt::integer
$function$;
CREATE OR REPLACE FUNCTION public.ally_ui_kn_kampagne_darf(p_person text, p_objekte text[])
 RETURNS SETOF text
 LANGUAGE sql
 STABLE
AS $function$
  -- Migration 210: welche der Kampagnen die Person sieht (wie talents_planung_recht, als Menge)
  WITH z AS MATERIALIZED (SELECT public.talents_zugriff(p_person) AS z)
  SELECT k.id::text FROM public.talent_kampagnen k, z
  WHERE k.id IN (SELECT o::integer FROM unnest(p_objekte) o WHERE o ~ '^[0-9]{1,9}$') AND z.z IS NOT NULL
    AND (z.z = 'alle' OR k.zustaendig = p_person OR EXISTS (SELECT 1 FROM public.talent_kampagne_talents kt JOIN public.talent_personen tp ON tp.talent_id = kt.talent_id
                                                          WHERE kt.kampagne_id = k.id AND tp.matrix_user_id = p_person))
$function$;
CREATE OR REPLACE FUNCTION public.ally_ui_kn_briefing(p_objekt text)
 RETURNS text
 LANGUAGE sql
 STABLE
AS $function$
  -- Migration 210: Name eines Briefings für die Adresse
  SELECT b.name FROM public.briefings b WHERE p_objekt ~ '^[0-9]{1,9}$' AND b.id = p_objekt::integer
$function$;
CREATE OR REPLACE FUNCTION public.ally_ui_kn_briefing_darf(p_person text, p_objekte text[])
 RETURNS SETOF text
 LANGUAGE sql
 STABLE
AS $function$
  -- Migration 210: welche der Briefings die Person sieht – wie briefing_sichtbar (Person, der es gehört; geteilt; Empfänger nach briefing_empfaenger_alle), aber als
  -- Menge: Angaben je Person, der ein Briefing gehört, einmal; die Talents der Person (für „Alle Manager/innen der Talents“) einmal vorberechnet.
  WITH ich AS MATERIALIZED (
    SELECT public.briefing_darf(p_person) AS darf,
      EXISTS (SELECT 1 FROM public.ally_personen p WHERE p.matrix_user_id = p_person AND p.aktiv) AS aktiv,
      (EXISTS (SELECT 1 FROM public.ally_personen p WHERE p.matrix_user_id = p_person AND p.aktiv AND NOT p.testdaten) AND NOT public.ally_person_ist_talent(p_person)) AS person_ok,
      public.talents_zugriff(p_person) IS NOT NULL AS zugriff,
      CASE WHEN coalesce(public.ally_hat_recht(p_person, 'admin'), false) THEN cardinality(public.briefing_talents_waise()) > 0 ELSE false END AS admin_waise,
      ARRAY(SELECT t.id FROM public.talent_personen tp JOIN public.talents t ON t.id = tp.talent_id AND t.status = 'aktiv' AND NOT t.testdaten
            WHERE tp.matrix_user_id = p_person) AS meine),
  b AS MATERIALIZED (SELECT x.* FROM public.briefings x WHERE x.id IN (SELECT o::integer FROM unnest(p_objekte) o WHERE o ~ '^[0-9]{1,9}$')),
  ow AS MATERIALIZED (SELECT o.person, public.briefing_darf(o.person) AS darf, coalesce(public.ally_hat_recht(o.person, 'briefing_andere'), false) AS andere,
           public.talents_zugriff(o.person) AS zugriff, public.ally_person_ist_talent(o.person) AS ist_talent,
           (SELECT p.talent_id FROM public.ally_personen p WHERE p.matrix_user_id = o.person AND p.aktiv) AS talent_id
         -- nur Personen, deren Briefings die Person als Empfänger bekommen könnte (die Angaben je Person kosten je ein paar Millisekunden)
         FROM (SELECT DISTINCT b.person FROM b WHERE b.person <> p_person AND b.geloescht_am IS NULL AND (p_person = ANY (b.empfaenger) OR b.manager)) o)
  SELECT b.id::text FROM b LEFT JOIN ow ON ow.person = b.person CROSS JOIN ich
  WHERE ich.darf AND (b.person = p_person OR (b.geloescht_am IS NULL AND (
    EXISTS (SELECT 1 FROM public.briefing_teilen t WHERE t.briefing_id = b.id AND t.person = p_person)
    -- feste Empfänger (nur mit „Briefings für andere“ der Person, der es gehört)
    OR (coalesce(ow.darf AND ow.andere, false) AND ich.aktiv AND p_person = ANY (b.empfaenger))
    -- „Alle Manager/innen der Talents“ (briefing_manager)
    OR (coalesce(ow.darf AND ow.andere, false) AND b.manager AND ich.person_ok
        AND EXISTS (SELECT 1 FROM public.briefing_inhalte bi JOIN public.briefing_bausteine bz ON bz.schluessel = bi.baustein AND bz.modul = 'talents' WHERE bi.briefing_id = b.id)
        AND ((b.manager_kreis = 'alle' AND ((ich.zugriff AND cardinality(ich.meine) > 0) OR ich.admin_waise))
          OR (b.manager_kreis = 'briefing' AND ich.zugriff AND EXISTS (SELECT 1 FROM unnest(ich.meine) m(id)
                WHERE CASE WHEN ow.ist_talent THEN m.id = ow.talent_id
                           ELSE ow.zugriff IS NOT NULL AND (EXISTS (SELECT 1 FROM public.talent_personen tp WHERE tp.talent_id = m.id AND tp.matrix_user_id = b.person)
                             OR (m.id::text IN (SELECT jsonb_array_elements_text(CASE WHEN jsonb_typeof(bi.optionen->'talents') = 'array' THEN bi.optionen->'talents' ELSE '[]'::jsonb END)
                                                FROM public.briefing_inhalte bi WHERE bi.briefing_id = b.id)
                                 AND (ow.zugriff = 'alle' OR EXISTS (SELECT 1 FROM public.talent_personen tp WHERE tp.talent_id = m.id AND tp.matrix_user_id = b.person)))) END)))))))
$function$;
CREATE OR REPLACE FUNCTION public.ally_ui_kn_ergebnis(p_objekt text)
 RETURNS text
 LANGUAGE sql
 STABLE
AS $function$
  -- Migration 210: Ergebnis eines Briefings in der Adresse als Datum (JJJJ-MM-TT, deutsche Zeit); mehrere am selben Tag: -2, -3 … (Kennung je Briefing)
  SELECT to_char(r.erstellt_am AT TIME ZONE 'Europe/Berlin', 'YYYY-MM-DD') FROM public.briefing_ergebnisse r WHERE p_objekt ~ '^[0-9]{1,12}$' AND r.id = p_objekt::bigint
$function$;
CREATE OR REPLACE FUNCTION public.ally_ui_kn_ergebnis_bereich(p_objekt text)
 RETURNS text
 LANGUAGE sql
 STABLE
AS $function$
  -- Migration 210: Kennungen der Ergebnisse gelten je Briefing und Person, für die es erstellt wurde (Nummer des Briefings | Person) – ein -2 verrät nichts über
  -- Ergebnisse anderer
  SELECT r.briefing_id::text || '|' || r.person FROM public.briefing_ergebnisse r WHERE p_objekt ~ '^[0-9]{1,12}$' AND r.id = p_objekt::bigint
$function$;
CREATE OR REPLACE FUNCTION public.ally_ui_kn_ergebnis_darf(p_person text, p_objekte text[])
 RETURNS SETOF text
 LANGUAGE sql
 STABLE
AS $function$
  -- Migration 210: welche der Ergebnisse die Person lesen darf – wie briefing_ergebnis_lesbar und Briefing sichtbar, als Menge
  WITH r AS MATERIALIZED (SELECT x.* FROM public.briefing_ergebnisse x WHERE x.id IN (SELECT o::bigint FROM unnest(p_objekte) o WHERE o ~ '^[0-9]{1,12}$')),
  sb AS MATERIALIZED (SELECT s::integer AS id FROM public.ally_ui_kn_briefing_darf(p_person, ARRAY(SELECT DISTINCT r.briefing_id::text FROM r)) s),
  z AS MATERIALIZED (SELECT public.talents_zugriff(p_person) AS z, public.briefing_darf(p_person) AS darf)
  SELECT r.id::text FROM r JOIN sb ON sb.id = r.briefing_id JOIN public.briefings b ON b.id = r.briefing_id CROSS JOIN z
  WHERE z.darf AND (r.person = p_person OR (b.person = p_person AND NOT r.uebernommen
    AND NOT EXISTS (SELECT 1 FROM public.briefing_bausteine x WHERE x.schluessel = ANY (r.inhalte) AND x.persoenlich)
    AND NOT EXISTS (SELECT 1 FROM jsonb_array_elements(coalesce(r.talents, '[]'::jsonb)) t
                    WHERE NOT ((t->>'id') ~ '^[0-9]{1,9}$' AND EXISTS (SELECT 1 FROM public.talents tt WHERE tt.id = (t->>'id')::integer
                      AND (z.z = 'alle' OR (z.z = 'eigene' AND EXISTS (SELECT 1 FROM public.talent_personen tp WHERE tp.talent_id = tt.id AND tp.matrix_user_id = p_person))))))))
$function$;
CREATE OR REPLACE FUNCTION public.ally_ui_kn_person(p_objekt text)
 RETURNS text
 LANGUAGE sql
 STABLE
AS $function$
  -- Migration 210: Name einer Person (Einstellungen › Team und Rollen › Personen)
  SELECT p.name FROM public.ally_personen p WHERE p.matrix_user_id = p_objekt AND NOT public.ally_person_ist_talent(p.matrix_user_id)
$function$;
CREATE OR REPLACE FUNCTION public.ally_ui_kn_person_darf(p_person text, p_objekte text[])
 RETURNS SETOF text
 LANGUAGE sql
 STABLE
AS $function$
  -- Migration 210: Personen sehen nur Admins (wie die Liste unter Team und Rollen)
  SELECT p.matrix_user_id FROM public.ally_personen p WHERE p.matrix_user_id = ANY (p_objekte) AND coalesce(public.ally_hat_recht(p_person, 'admin'), false)
$function$;
CREATE OR REPLACE FUNCTION public.ally_ui_kn_ordner(p_objekt text)
 RETURNS text
 LANGUAGE sql
 STABLE
AS $function$
  -- Migration 210: Name eines freigegebenen Ordners im Talent-Bereich
  SELECT o.name FROM public.talent_ordner o WHERE p_objekt ~ '^[0-9]{1,12}$' AND o.id = p_objekt::bigint
$function$;
CREATE OR REPLACE FUNCTION public.ally_ui_kn_ordner_darf(p_person text, p_objekte text[])
 RETURNS SETOF text
 LANGUAGE sql
 STABLE
AS $function$
  -- Migration 210: Ordner sieht nur das Talent, dem er freigegeben ist, solange die Freigabe nicht beendet ist
  SELECT o.id::text FROM public.talent_ordner o JOIN public.ally_personen p ON p.talent_id = o.talent_id AND p.matrix_user_id = p_person AND p.aktiv
  WHERE o.id IN (SELECT x::bigint FROM unnest(p_objekte) x WHERE x ~ '^[0-9]{1,12}$') AND o.beendet_am IS NULL
$function$;
CREATE OR REPLACE FUNCTION public.ally_ui_kn_termin(p_objekt text)
 RETURNS text
 LANGUAGE sql
 STABLE
AS $function$
  -- Migration 210: Titel eines Termins des Kalenders von Ally (Kennung i-<Nummer>); Termine anderer Kalender behalten ihre Kennung
  SELECT t.titel FROM public.kalender_termine t WHERE p_objekt ~ '^i-[0-9]{1,15}$' AND t.id = substr(p_objekt, 3)::bigint
$function$;
CREATE OR REPLACE FUNCTION public.ally_ui_kn_termin_darf(p_person text, p_objekte text[])
 RETURNS SETOF text
 LANGUAGE sql
 STABLE
AS $function$
  -- Migration 210: Termine sichtbar wie im Kalender (kalender_termin_sichtbar: angelegt, für die Person oder eingeladen)
  SELECT 'i-' || t.id FROM public.kalender_termine t
  WHERE t.id IN (SELECT substr(x, 3)::bigint FROM unnest(p_objekte) x WHERE x ~ '^i-[0-9]{1,15}$') AND p_person IS NOT NULL
    AND (t.erstellt_von = p_person OR t.fuer = p_person OR EXISTS (SELECT 1 FROM public.kalender_termin_personen x WHERE x.termin_id = t.id AND x.person = p_person))
$function$;
CREATE OR REPLACE FUNCTION public.ally_ui_kn_benachrichtigung(p_objekt text)
 RETURNS text
 LANGUAGE sql
 STABLE
AS $function$
  -- Migration 210: Titel eines Ergebnisses unter Benachrichtigungen (/benachrichtigungen/ergebnis/<Kennung>)
  SELECT e.titel FROM public.ally_ergebnisse e WHERE p_objekt ~ '^[0-9]{1,12}$' AND e.id = p_objekt::bigint
$function$;
CREATE OR REPLACE FUNCTION public.ally_ui_kn_benachrichtigung_bereich(p_objekt text)
 RETURNS text
 LANGUAGE sql
 STABLE
AS $function$
  -- Migration 210: Kennungen der Ergebnisse unter Benachrichtigungen gelten je Person (| Person) – ein -2 verrät nichts über Einträge anderer
  SELECT '|' || e.person FROM public.ally_ergebnisse e WHERE p_objekt ~ '^[0-9]{1,12}$' AND e.id = p_objekt::bigint
$function$;
CREATE OR REPLACE FUNCTION public.ally_ui_kn_benachrichtigung_darf(p_person text, p_objekte text[])
 RETURNS SETOF text
 LANGUAGE sql
 STABLE
AS $function$
  -- Migration 210: Ergebnisse unter Benachrichtigungen sieht nur die Person, für die sie erstellt wurden
  SELECT e.id::text FROM public.ally_ergebnisse e WHERE e.id IN (SELECT x::bigint FROM unnest(p_objekte) x WHERE x ~ '^[0-9]{1,12}$') AND e.person = p_person
$function$;
CREATE OR REPLACE FUNCTION public.ally_ui_kennung_person(p_token text)
 RETURNS text
 LANGUAGE sql
 STABLE
AS $function$
  -- Migration 210: wer fragt (für die Rechte auf Objekte mit Kennung): Person der Sitzung, bei Talents (eigene Art der Sitzung) die Talent-Person
  SELECT coalesce((SELECT y.person FROM public.ally_ui_sitzung(p_token) y WHERE NOT y.muss_pw_setzen LIMIT 1),
                  (SELECT w.matrix_user_id FROM public.talent_web_sitzung(p_token) t JOIN public.ally_web_sitzungen w ON w.token_hash = t.token_hash LIMIT 1))
$function$;
CREATE OR REPLACE FUNCTION public.ally_ui_kennung(p_art text, p_objekt text)
 RETURNS text
 LANGUAGE sql
 STABLE
AS $function$
  -- Migration 210: aktuelle Kennung eines Objekts (nur lesen; angelegt und nachgeführt von ally_ui_kennung_pflegen); NULL, wenn es noch keine gibt
  SELECT k.kennung FROM public.ally_ui_kennungen k WHERE k.art = p_art AND k.objekt = p_objekt AND k.aktuell
$function$;
CREATE OR REPLACE FUNCTION public.ally_ui_kennung_person_teil(p_person text)
 RETURNS text
 LANGUAGE sql
 STABLE
AS $function$
  -- Migration 210: Teil „_<…>“ für Einträge anderer Personen (Ergebnisse): die Kennung der Person, bei Talent-Personen „t-“ und die Kennung ihres Talents (der Name,
  -- den die Person, der das Briefing gehört, ohnehin als Empfänger sieht). Eigener Namensraum: keine Kennung beginnt mit Buchstabe und Bindestrich
  -- (ally_ui_kennung_text), daher kann „t-…“ nie die Kennung einer Person sein. NULL, wenn es keine gibt.
  SELECT coalesce(
    (SELECT k.kennung FROM public.ally_ui_kennungen k WHERE k.art = 'person' AND k.objekt = p_person AND k.aktuell),
    (SELECT 't-' || k.kennung FROM public.ally_personen p JOIN public.ally_ui_kennungen k ON k.art = 'talent' AND k.objekt = p.talent_id::text AND k.aktuell
     WHERE p.matrix_user_id = p_person AND p.talent_id IS NOT NULL AND public.ally_person_ist_talent(p.matrix_user_id)))
$function$;
CREATE OR REPLACE FUNCTION public.ally_ui_kennung_personen(p_teil text)
 RETURNS SETOF text
 LANGUAGE sql
 STABLE
AS $function$
  -- Migration 210: Personen zum Teil „_<…>“ (auch frühere Kennungen): „t-<Kennung eines Talents>“ = Talent-Personen dieses Talents, sonst die Person mit dieser Kennung
  SELECT k.objekt FROM public.ally_ui_kennungen k WHERE p_teil !~ '^t-' AND k.art = 'person' AND k.bereich = '' AND k.kennung = p_teil
  UNION
  SELECT p.matrix_user_id FROM public.ally_ui_kennungen k JOIN public.ally_personen p ON p.talent_id::text = k.objekt
  WHERE p_teil ~ '^t-' AND k.art = 'talent' AND k.bereich = '' AND k.kennung = substr(p_teil, 3) AND public.ally_person_ist_talent(p.matrix_user_id)
$function$;
CREATE OR REPLACE FUNCTION public.ally_ui_kennung_fuer(p_art text, p_objekt text, p_wer text)
 RETURNS text
 LANGUAGE sql
 STABLE
AS $function$
  -- Migration 210: Kennung eines Objekts in der Adresse für die Person, die fragt. Bei Arten mit Bereich je Person (Ergebnisse) ist die Kennung nur unter den
  -- Einträgen dieser Person eindeutig: Einträge anderer (z. B. die Person, der ein Briefing gehört, liest das Ergebnis eines Empfängers) bekommen „_“ und die
  -- Kennung der Person dazu (2026-11-06_anna-anwender; Talent-Empfänger: Kennung des Talents). Ohne solche Kennung: NULL (die Nummer bleibt).
  -- p_wer NULL (keine fragende Person, z. B. Links in Mails): immer mit „_“ – so ist die Adresse für jede Person eindeutig.
  SELECT CASE WHEN NOT a.bereich_person OR split_part(k.bereich, '|', 2) = p_wer THEN k.kennung
              ELSE k.kennung || '_' || public.ally_ui_kennung_person_teil(split_part(k.bereich, '|', 2)) END
  FROM public.ally_ui_kennungen k JOIN public.ally_ui_kennung_arten a ON a.art = k.art
  WHERE k.art = p_art AND k.objekt = p_objekt AND k.aktuell
$function$;
CREATE OR REPLACE FUNCTION public.ally_ui_kennung_pflegen(p_art text, p_objekt text)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE a public.ally_ui_kennung_arten%ROWTYPE; nm text; b text; k text; br text := ''; jetzt public.ally_ui_kennungen%ROWTYPE; n integer := 1;
BEGIN
  -- Migration 210 (Stefan 06.11.2026 „Name“): Kennung eines Objekts aus seinem aktuellen Namen. Gleicher Name wie bisher → bisherige Kennung. Neuer Name → neue
  -- Kennung (bei Gleichheit innerhalb der Art bzw. des Bereichs -2, -3 …), die bisherige bleibt reserviert und führt zur neuen; hieß das Objekt früher schon so,
  -- gilt seine frühere Kennung wieder. Gibt es das Objekt nicht (mehr), bleibt die letzte Kennung stehen. Liefert die aktuelle Kennung.
  SELECT * INTO a FROM public.ally_ui_kennung_arten x WHERE x.art = p_art;
  IF NOT FOUND OR coalesce(p_objekt, '') = '' THEN RETURN NULL; END IF;
  SELECT * INTO jetzt FROM public.ally_ui_kennungen x WHERE x.art = p_art AND x.objekt = p_objekt AND x.aktuell;
  IF to_regprocedure(format('public.%I(text)', a.name_funktion)) IS NULL THEN RETURN jetzt.kennung; END IF;
  EXECUTE format('SELECT public.%I($1)', a.name_funktion) INTO nm USING p_objekt;
  IF nm IS NULL THEN RETURN jetzt.kennung; END IF;
  IF a.bereich_funktion IS NOT NULL THEN
    IF to_regprocedure(format('public.%I(text)', a.bereich_funktion)) IS NULL THEN RETURN jetzt.kennung; END IF;
    EXECUTE format('SELECT public.%I($1)', a.bereich_funktion) INTO br USING p_objekt;
    IF br IS NULL THEN RETURN jetzt.kennung; END IF;
  END IF;
  b := public.ally_ui_kennung_text(nm, a.ersatz);
  IF jetzt.basis = b AND jetzt.bereich = br THEN RETURN jetzt.kennung; END IF;
  SELECT x.kennung INTO k FROM public.ally_ui_kennungen x WHERE x.art = p_art AND x.bereich = br AND x.objekt = p_objekt AND x.basis = b
  ORDER BY x.erstellt_am DESC, x.kennung COLLATE "C" LIMIT 1;
  IF k IS NULL THEN
    k := b;
    LOOP
      -- feste Teile der Adressen (z. B. neu, papierkorb, ergebnis) und freigehaltene Pfade sind keine Kennung: /briefing/neu bleibt „neues Briefing“
      IF k NOT IN ('start', 'unbekannt', 'aktion', 'datei', 'manifest', 'symbol', 'kalender', 'stil', 'skript', 'logo', 'neu', 'api', 'mediakit', 'webhook')
         AND NOT EXISTS (SELECT 1 FROM public.ally_ui_pfade p, unnest(string_to_array(substr(p.muster, 2), '/')) t(teil) WHERE t.teil = k) THEN
        -- Sperre nur für diese Kennung (Art, Bereich, Kennung) bis zum Ende der Transaktion: wer dieselbe Kennung gleichzeitig anlegt, wartet und sieht danach
        -- (eigene Abfrage, neuer Stand) die vergebene Kennung und nimmt die nächste; andere Namen warten nicht
        PERFORM pg_advisory_xact_lock(hashtext('ally_ui_kennung:' || p_art || '|' || br || '|' || k));
        EXIT WHEN NOT EXISTS (SELECT 1 FROM public.ally_ui_kennungen x WHERE x.art = p_art AND x.bereich = br AND x.kennung = k);
      END IF;
      n := n + 1; k := btrim(left(b, 60), '-') || '-' || n;
    END LOOP;
    INSERT INTO public.ally_ui_kennungen (art, bereich, kennung, objekt, basis, aktuell) VALUES (p_art, br, k, p_objekt, b, false);
  END IF;
  UPDATE public.ally_ui_kennungen x SET aktuell = false WHERE x.art = p_art AND x.objekt = p_objekt AND x.aktuell AND (x.kennung <> k OR x.bereich <> br);
  UPDATE public.ally_ui_kennungen x SET aktuell = true WHERE x.art = p_art AND x.bereich = br AND x.kennung = k AND NOT x.aktuell;
  RETURN k;
END $function$;
CREATE OR REPLACE FUNCTION public.ally_ui_kennung_ausloeser()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  -- Migration 210: Kennung beim Anlegen und bei geändertem Namen nachführen (TG_ARGV[0] = Art, TG_ARGV[1] = Spalte mit der Nummer bzw. Kennung des Objekts,
  -- TG_ARGV[2] = Vorsatz der Kennung, z. B. i- bei Terminen).
  -- Ein Fehler hier hält das Speichern nie auf: die Kennung wird dann beim nächsten Aufruf der Seite nachgeführt (ally_ui_kennungen).
  BEGIN
    PERFORM public.ally_ui_kennung_pflegen(TG_ARGV[0], coalesce(TG_ARGV[2], '') || (to_jsonb(NEW) ->> TG_ARGV[1]));
  EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'Kennung für % nicht nachgeführt: %', TG_ARGV[0], SQLERRM;
  END;
  RETURN NULL;
END $function$;
CREATE OR REPLACE FUNCTION public.ally_ui_pfad_bauen(p_seite text, p_parameter jsonb, p_umsetzen boolean)
 RETURNS text
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
  r record; ka record; bm text; bf jsonb; brest boolean; bs integer := -1; sc integer; ph text[]; aus text; k text; rest text := '';
  P jsonb := coalesce((SELECT jsonb_object_agg(e.key, e.value #>> '{}') FROM jsonb_each(CASE WHEN jsonb_typeof(p_parameter) = 'object' THEN p_parameter ELSE '{}'::jsonb END) e
                       WHERE jsonb_typeof(e.value) IN ('string', 'number', 'boolean') AND (e.value #>> '{}') <> ''), '{}'::jsonb);
BEGIN
  -- Migration 210: Inhalt von ally_ui_pfad (Migration 209); mit p_umsetzen steht für die Nummer eines Objekts mit Kennung (ally_ui_kennung_arten) dessen aktuelle
  -- Kennung in der Adresse (Stefan 06.11.2026 „Name“), Objekte ohne Kennung behalten die Nummer.
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
    IF p_umsetzen THEN
      SELECT x.art, x.bereich_person INTO ka FROM public.ally_ui_kennung_arten x WHERE x.seite = p_seite AND x.parameter = k;
      -- Einträge je Person (Ergebnisse): wie die Karte für die handelnde Person (ally.handelnd aus der Sitzung); ohne sie immer mit „_<Person>“ (eindeutig für alle)
      IF FOUND THEN P := P || jsonb_build_object(k, coalesce(CASE WHEN ka.bereich_person THEN public.ally_ui_kennung_fuer(ka.art, P->>k, nullif(current_setting('ally.handelnd', true), ''))
                                                               ELSE public.ally_ui_kennung(ka.art, P->>k) END, P->>k)); END IF;
    END IF;
    aus := replace(aus, '{' || k || '}', public.ally_ui_pfad_teil(P->>k));
  END LOOP;
  IF brest THEN
    SELECT coalesce(string_agg(public.ally_ui_pfad_teil(e.key) || '=' || public.ally_ui_pfad_teil(e.value), '&' ORDER BY e.key COLLATE "C"), '') INTO rest
    FROM jsonb_each_text(P) e WHERE NOT bf ? e.key AND position('{' || e.key || '}' IN bm) = 0;
    IF rest <> '' THEN aus := aus || '?' || rest; END IF;
  END IF;
  RETURN aus;
END $function$;
CREATE OR REPLACE FUNCTION public.ally_ui_kennungen(p_token text, p_seite text, p_parameter jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
  wer text := public.ally_ui_kennung_person(p_token); a record; v text; kt text; o text; k text; ok boolean; nm text; bw text; br text; bo text; bid integer; eid bigint;
  P jsonb := CASE WHEN jsonb_typeof(p_parameter) = 'object' THEN p_parameter ELSE '{}'::jsonb END; Q jsonb;
  ersetzt jsonb := '{}'::jsonb; adr jsonb; um boolean := false;
BEGIN
  -- Migration 210 (Stefan 06.11.2026 „Name“): Kennungen in Adresse und Anfrage (ALLY 20 „Adresse lesen“). Je Parameter einer Objektart der Seite:
  --   Kennung (auch eine frühere) eines Objekts, das die Person sehen darf → Nummer für die Seite, aktuelle Kennung für die Adresse;
  --   Kennung ohne Recht oder unbekannt → wie ein unbekanntes Objekt (Nummer 0; bei Arten mit fremden Kennungen bleibt der Wert), Adresse unverändert;
  --   Nummer (alte Adresse) → bleibt; darf die Person das Objekt sehen, kommt seine Kennung in die Adresse, sonst bleibt alles unverändert.
  -- Kennungen mit Bereich: im Objekt des Bereichsparameters (zuerst aufgelöst) und/oder je Person (Einträge anderer: <Kennung>_<Kennung der Person>).
  -- Alte Adressen der Seite KI-Analysen (/ki-analysen/<alte Nummer>) führen auf das übernommene Briefing (wie briefing_web: das eigene zuerst).
  -- Liefert ersetzt (Parameter, die für die Seite anders gelten), adresse (Pfad ohne Filter) und umleiten (true: Adresse mit aktueller Kennung ist eine andere).
  IF p_seite = 'briefings' AND wer IS NOT NULL AND coalesce(P->>'briefing', '') ~ '^[0-9]{1,9}$' THEN
    SELECT x.id INTO bid FROM public.briefings x WHERE x.alt_id = (P->>'briefing')::integer AND coalesce(public.briefing_sichtbar(wer, x.id), false)
    ORDER BY (x.person = wer) DESC, x.id LIMIT 1;
    IF bid IS NOT NULL THEN
      Q := jsonb_build_object('briefing', coalesce(public.ally_ui_kennung('briefing', bid::text), bid::text));
      IF coalesce(P->>'ergebnis', '') ~ '^[0-9]{1,12}$' THEN
        SELECT r.id INTO eid FROM public.briefing_ergebnisse r WHERE r.alt_id = (P->>'ergebnis')::bigint AND r.briefing_id = bid AND coalesce(public.briefing_ergebnis_lesbar(wer, r.id), false)
        ORDER BY r.id LIMIT 1;
        IF eid IS NOT NULL THEN Q := Q || jsonb_build_object('ergebnis', coalesce(public.ally_ui_kennung_fuer('ergebnis', eid::text, wer), eid::text)); END IF;
      END IF;
      RETURN jsonb_build_object('ersetzt', '{}'::jsonb, 'adresse', public.ally_ui_pfad_bauen('morgen-briefing', Q, false), 'umleiten', true);
    END IF;
  END IF;
  adr := P;
  FOR a IN SELECT x.* FROM public.ally_ui_kennung_arten x WHERE x.seite = coalesce(p_seite, '') ORDER BY (x.bereich_parameter IS NOT NULL), x.art COLLATE "C" LOOP
    CONTINUE WHEN NOT P ? a.parameter OR jsonb_typeof(P->a.parameter) NOT IN ('string', 'number');
    v := P->>a.parameter;
    CONTINUE WHEN v = '' OR length(v) > 200;
    -- Bereich, in dem die Kennung gilt
    bw := CASE WHEN a.bereich_parameter IS NULL THEN '' ELSE coalesce((P || ersetzt)->>a.bereich_parameter, '') END;
    kt := v; br := bw; o := NULL;
    IF a.bereich_person THEN
      IF position('_' IN v) > 0 THEN
        -- Eintrag einer anderen Person: <Kennung>_<Kennung der Person bzw. ihres Talents>
        kt := split_part(v, '_', 1);
        -- nur, wenn genau ein solcher Eintrag existiert, den die Person lesen darf (sonst wie unbekannt)
        IF wer IS NOT NULL AND to_regprocedure(format('public.%I(text,text[])', a.darf_funktion)) IS NOT NULL THEN
          EXECUTE format('SELECT min(d) FROM public.%I($1, ARRAY(SELECT x.objekt FROM public.ally_ui_kennungen x WHERE x.art = $2 AND x.kennung = $3
                            AND x.bereich IN (SELECT $4 || ''|'' || pp FROM public.ally_ui_kennung_personen($5) pp))) d HAVING count(*) = 1', a.darf_funktion)
            INTO o USING wer, a.art, kt, bw, split_part(v, '_', 2);
        END IF;
      ELSE
        SELECT x.objekt INTO o FROM public.ally_ui_kennungen x WHERE x.art = a.art AND x.bereich = bw || '|' || coalesce(wer, '') AND x.kennung = kt;
        -- ohne „_“ und nicht unter den eigenen Einträgen: der einzige Eintrag dieser Kennung im Bereich, den die Person lesen darf (z. B. Link einer anderen Person)
        IF o IS NULL AND wer IS NOT NULL AND to_regprocedure(format('public.%I(text,text[])', a.darf_funktion)) IS NOT NULL THEN
          EXECUTE format('SELECT min(d) FROM public.%I($1, ARRAY(SELECT x.objekt FROM public.ally_ui_kennungen x WHERE x.art = $2 AND x.kennung = $3 AND x.bereich LIKE $4)) d HAVING count(*) = 1',
                         a.darf_funktion) INTO o USING wer, a.art, kt, bw || '|%';
        END IF;
      END IF;
    ELSE
      SELECT x.objekt INTO o FROM public.ally_ui_kennungen x WHERE x.art = a.art AND x.bereich = br AND x.kennung = kt;
    END IF;
    IF o IS NULL THEN
      o := NULL; nm := NULL;
      IF to_regprocedure(format('public.%I(text)', a.name_funktion)) IS NOT NULL THEN EXECUTE format('SELECT public.%I($1)', a.name_funktion) INTO nm USING v; END IF;
      IF nm IS NULL THEN
        -- weder Kennung noch vorhandenes Objekt: wie eine unbekannte Kennung (Nummern und andere Werte unverändert, die Seite prüft sie wie bisher)
        IF a.unbekannt IS NOT NULL AND v !~ '^[0-9]+$' AND v ~ '^[a-z0-9]([a-z0-9_-]*[a-z0-9])?$' THEN ersetzt := ersetzt || jsonb_build_object(a.parameter, a.unbekannt); END IF;
        CONTINUE;
      END IF;
      IF a.bereich_parameter IS NOT NULL THEN
        bo := NULL;
        IF to_regprocedure(format('public.%I(text)', a.bereich_funktion)) IS NOT NULL THEN EXECUTE format('SELECT public.%I($1)', a.bereich_funktion) INTO bo USING v; END IF;
        CONTINUE WHEN split_part(coalesce(bo, ''), '|', 1) IS DISTINCT FROM bw;   -- Nummer gehört nicht zum Objekt des Bereichs: unverändert
      END IF;
    END IF;
    ok := false;
    IF wer IS NOT NULL AND to_regprocedure(format('public.%I(text,text[])', a.darf_funktion)) IS NOT NULL THEN
      EXECUTE format('SELECT EXISTS (SELECT 1 FROM public.%I($1, ARRAY[$2]))', a.darf_funktion) INTO ok USING wer, coalesce(o, v);
    END IF;
    IF o IS NOT NULL THEN
      -- angefragt mit Kennung
      IF NOT ok THEN
        IF a.unbekannt IS NOT NULL THEN ersetzt := ersetzt || jsonb_build_object(a.parameter, a.unbekannt); END IF;
        CONTINUE;
      END IF;
      ersetzt := ersetzt || jsonb_build_object(a.parameter, o);
    ELSIF NOT ok THEN
      CONTINUE;   -- Nummer ohne Recht: unverändert (die Seite antwortet wie bisher)
    END IF;
    PERFORM public.ally_ui_kennung_pflegen(a.art, coalesce(o, v));
    k := coalesce(public.ally_ui_kennung_fuer(a.art, coalesce(o, v), wer), v);
    IF k IS DISTINCT FROM v THEN adr := adr || jsonb_build_object(a.parameter, k); um := true; END IF;
  END LOOP;
  RETURN jsonb_build_object('ersetzt', ersetzt, 'adresse', public.ally_ui_pfad_bauen(p_seite, adr, false), 'umleiten', um);
END $function$;
CREATE OR REPLACE FUNCTION public.ally_ui_kennungen_karte(p_token text, p_json jsonb, p_nummern jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
  wer text; a record; aus jsonb := '[]'::jsonb; t jsonb; zs text[]; zp jsonb[]; o text[]; bw text[];
BEGIN
  -- Migration 210 (Stefan 06.11.2026 „Nummern sollen nirgends sichtbar sein“; Prüfung H-1): Kennungen der Objekte, die eine Seite oder Aktion verlinkt – für Links,
  -- die Web-App, Baukasten (ALLY 21) und Abläufe selbst bauen. Einträge [Seite, Parameter, Nummer, Kennung] bzw. mit Bereichsparameter [… , Bereichsparameter,
  -- Bereichsnummer]. Verlinkt sind: jedes {seite, parameter} in p_json (Ziele der Seite, Rahmen, die angefragte Seite selbst) und die Nummern in p_nummern
  -- ({"<Seite>": [Nummern]}, "*" = jede Seite; Daten der selbst gebauten Seiten, Ergebnis einer Aktion). Keine Liste aller Objekte. Nur Objekte, die die Person sehen
  -- darf – geprüft als Menge je Art (eine Abfrage je Art, nicht je Objekt). Nicht STABLE: nach einer Aktion sieht die Karte die neuen Objekte derselben Abfrage.
  IF jsonb_typeof(p_json) NOT IN ('object', 'array') AND jsonb_typeof(p_nummern) IS DISTINCT FROM 'object' THEN RETURN '[]'::jsonb; END IF;
  wer := public.ally_ui_kennung_person(p_token);
  IF wer IS NULL THEN RETURN '[]'::jsonb; END IF;
  IF jsonb_typeof(p_json) IN ('object', 'array') THEN
    SELECT array_agg(x->>'seite'), array_agg(x->'parameter') INTO zs, zp FROM (SELECT x FROM jsonb_path_query(p_json, 'strict $.**') x
      WHERE jsonb_typeof(x) = 'object' AND jsonb_typeof(x->'seite') = 'string' AND jsonb_typeof(x->'parameter') = 'object' LIMIT 10000) y;
  END IF;
  FOR a IN SELECT y.* FROM public.ally_ui_kennung_arten y WHERE y.seite = ANY (coalesce(zs, '{}'))
             OR (y.bereich_parameter IS NULL AND jsonb_typeof(p_nummern) = 'object' AND (p_nummern ? y.seite OR p_nummern ? '*')) ORDER BY y.art COLLATE "C" LOOP
    CONTINUE WHEN to_regprocedure(format('public.%I(text,text[])', a.darf_funktion)) IS NULL;
    -- Kandidaten der Art: Nummer und (bei Bereichsparameter) die Nummer des Objekts, zu dem sie verlinkt ist
    SELECT array_agg(c.o), array_agg(c.b) INTO o, bw FROM (
      SELECT DISTINCT u.p->>a.parameter AS o, CASE WHEN a.bereich_parameter IS NOT NULL THEN coalesce(u.p->>a.bereich_parameter, '') END AS b
      FROM unnest(coalesce(zs, '{}'), coalesce(zp, '{}')) u(s, p) WHERE u.s = a.seite AND jsonb_typeof(u.p->a.parameter) IN ('string', 'number') AND length(u.p->>a.parameter) BETWEEN 1 AND 200
      UNION
      SELECT n.n, NULL FROM jsonb_each(CASE WHEN a.bereich_parameter IS NULL AND jsonb_typeof(p_nummern) = 'object' THEN p_nummern ELSE '{}'::jsonb END) e
      CROSS JOIN LATERAL jsonb_array_elements_text(CASE WHEN jsonb_typeof(e.value) = 'array' THEN e.value ELSE '[]'::jsonb END) n(n)
      WHERE (e.key = a.seite OR e.key = '*') AND n.n ~ '^[0-9]{1,18}$') c;
    CONTINUE WHEN o IS NULL;
    -- sichtbare Objekte (eine Abfrage für die Art) und ihre Kennung; Ergebnisse anderer Personen mit „_“ und deren Kennung (ally_ui_kennung_fuer)
    EXECUTE format($q$
      SELECT coalesce(jsonb_agg(CASE WHEN c.b IS NULL THEN jsonb_build_array(%1$L::text, %2$L::text, c.o, x.kn) ELSE jsonb_build_array(%1$L::text, %2$L::text, c.o, x.kn, %3$L::text, c.b) END), '[]'::jsonb)
      FROM unnest($2::text[], $3::text[]) c(o, b)
      JOIN (SELECT DISTINCT s FROM public.%4$I($1, $2::text[]) s) d ON d.s = c.o
      JOIN public.ally_ui_kennungen k ON k.art = %5$L AND k.objekt = c.o AND k.aktuell
      CROSS JOIN LATERAL (SELECT CASE WHEN NOT %6$L::boolean OR split_part(k.bereich, '|', 2) = $1 THEN k.kennung
                                      ELSE k.kennung || '_' || public.ally_ui_kennung_person_teil(split_part(k.bereich, '|', 2)) END AS kn) x
      WHERE x.kn IS NOT NULL AND (c.b IS NULL OR split_part(k.bereich, '|', 1) = c.b)$q$,
      a.seite, a.parameter, a.bereich_parameter, a.darf_funktion, a.art, a.bereich_person) INTO t USING wer, o, bw;
    aus := aus || t;
  END LOOP;
  RETURN aus;
END $function$;
CREATE OR REPLACE FUNCTION public.ally_ui_pfad(p_seite text, p_parameter jsonb)
 RETURNS text
 LANGUAGE sql
 STABLE
AS $function$
  -- Migration 209 (Fehler 46): Adresse (Pfad ab /) einer Seite mit ihren Parametern aus ally_ui_pfade. Migration 210 (Stefan 06.11.2026 „Name“): Objekte mit
  -- Kennung erscheinen mit ihrer aktuellen Kennung statt der Nummer (ally_ui_pfad_bauen).
  SELECT public.ally_ui_pfad_bauen(p_seite, p_parameter, true)
$function$;
-- Ergebnis eines Briefings als Datum direkt unter dem Briefing (/briefing/<Kennung>/<Datum>); die Adressen mit /ergebnis/ (Migration 209) gelten weiter und
-- führen per 301 hierher (bei gleich vielen Teilen gilt das Muster mit kleinerer sortierung)
INSERT INTO public.ally_ui_pfade (muster, seite, feste, rest, sortierung, herkunft) VALUES ('/briefing/{briefing}/{ergebnis}', 'morgen-briefing', '{}', false, 19, 'm210');
-- Objektarten mit Kennung im Installationspaket (Seite und Parameter wie in ally_ui_pfade; Name und Recht über die Funktionen ally_ui_kn_*)
INSERT INTO public.ally_ui_kennung_arten (art, seite, parameter, name_funktion, darf_funktion, ersatz, bereich_parameter, bereich_funktion, bereich_person, unbekannt) VALUES
  ('talent', 'talent', 'id', 'ally_ui_kn_talent', 'ally_ui_kn_talent_darf', 'talent', NULL, NULL, false, '0'),
  ('kampagne', 'kampagnen', 'kampagne', 'ally_ui_kn_kampagne', 'ally_ui_kn_kampagne_darf', 'kampagne', NULL, NULL, false, '0'),
  ('briefing', 'morgen-briefing', 'briefing', 'ally_ui_kn_briefing', 'ally_ui_kn_briefing_darf', 'briefing', NULL, NULL, false, '0'),
  ('ergebnis', 'morgen-briefing', 'ergebnis', 'ally_ui_kn_ergebnis', 'ally_ui_kn_ergebnis_darf', 'ergebnis', 'briefing', 'ally_ui_kn_ergebnis_bereich', true, '0'),
  ('person', 'einstellungen', 'person', 'ally_ui_kn_person', 'ally_ui_kn_person_darf', 'person', NULL, NULL, false, '0'),
  ('ordner', 'talent-bereich', 'to', 'ally_ui_kn_ordner', 'ally_ui_kn_ordner_darf', 'ordner', NULL, NULL, false, '0'),
  ('termin', 'kalender', 'termin', 'ally_ui_kn_termin', 'ally_ui_kn_termin_darf', 'termin', NULL, NULL, false, NULL),
  ('benachrichtigung', 'benachrichtigungen', 'er', 'ally_ui_kn_benachrichtigung', 'ally_ui_kn_benachrichtigung_darf', 'ergebnis', NULL, 'ally_ui_kn_benachrichtigung_bereich', true, '0');
-- Kennungen beim Anlegen und Umbenennen nachführen
CREATE TRIGGER ally_ui_kennung AFTER INSERT OR UPDATE OF name, kuenstlername ON public.talents FOR EACH ROW EXECUTE FUNCTION public.ally_ui_kennung_ausloeser('talent', 'id');
CREATE TRIGGER ally_ui_kennung AFTER INSERT OR UPDATE OF name ON public.talent_kampagnen FOR EACH ROW EXECUTE FUNCTION public.ally_ui_kennung_ausloeser('kampagne', 'id');
CREATE TRIGGER ally_ui_kennung AFTER INSERT OR UPDATE OF name ON public.briefings FOR EACH ROW EXECUTE FUNCTION public.ally_ui_kennung_ausloeser('briefing', 'id');
CREATE TRIGGER ally_ui_kennung AFTER INSERT OR UPDATE OF name ON public.ally_personen FOR EACH ROW EXECUTE FUNCTION public.ally_ui_kennung_ausloeser('person', 'matrix_user_id');
CREATE TRIGGER ally_ui_kennung AFTER INSERT OR UPDATE OF name ON public.talent_ordner FOR EACH ROW EXECUTE FUNCTION public.ally_ui_kennung_ausloeser('ordner', 'id');
CREATE TRIGGER ally_ui_kennung AFTER INSERT OR UPDATE OF erstellt_am, briefing_id ON public.briefing_ergebnisse FOR EACH ROW EXECUTE FUNCTION public.ally_ui_kennung_ausloeser('ergebnis', 'id');
CREATE TRIGGER ally_ui_kennung AFTER INSERT OR UPDATE OF titel ON public.kalender_termine FOR EACH ROW EXECUTE FUNCTION public.ally_ui_kennung_ausloeser('termin', 'id', 'i-');
CREATE TRIGGER ally_ui_kennung AFTER INSERT OR UPDATE OF titel ON public.ally_ergebnisse FOR EACH ROW EXECUTE FUNCTION public.ally_ui_kennung_ausloeser('benachrichtigung', 'id');
-- Kennungen für alle vorhandenen Objekte (auch im Papierkorb: ihre Kennung bleibt reserviert); bei gleichem Namen erhält das ältere Objekt die Kennung ohne Zusatz
DO $m$
BEGIN
  PERFORM count(public.ally_ui_kennung_pflegen('talent', t.id::text) ORDER BY t.id) FROM public.talents t;
  PERFORM count(public.ally_ui_kennung_pflegen('kampagne', k.id::text) ORDER BY k.id) FROM public.talent_kampagnen k;
  PERFORM count(public.ally_ui_kennung_pflegen('briefing', b.id::text) ORDER BY b.id) FROM public.briefings b;
  PERFORM count(public.ally_ui_kennung_pflegen('person', p.matrix_user_id) ORDER BY p.id) FROM public.ally_personen p;
  PERFORM count(public.ally_ui_kennung_pflegen('ordner', o.id::text) ORDER BY o.id) FROM public.talent_ordner o;
  PERFORM count(public.ally_ui_kennung_pflegen('ergebnis', r.id::text) ORDER BY r.id) FROM public.briefing_ergebnisse r;
  PERFORM count(public.ally_ui_kennung_pflegen('termin', 'i-' || t.id) ORDER BY t.id) FROM public.kalender_termine t;
  PERFORM count(public.ally_ui_kennung_pflegen('benachrichtigung', e.id::text) ORDER BY e.id) FROM public.ally_ergebnisse e;
END $m$;
-- Gemerkte Filter (Migration 209) hängen an der Adresse: auf die Adresse mit Kennung umstellen, damit sie weiter gelten
DO $m$
DECLARE f record; o jsonb; neu text;
BEGIN
  FOR f IN SELECT x.person, x.kennung, x.seite FROM public.ally_ui_filter x ORDER BY x.person COLLATE "C", x.kennung COLLATE "C" LOOP
    -- Adresse wie zur Laufzeit für diese Person (ally_ui_pfad nimmt die handelnde Person für Einträge je Person)
    PERFORM set_config('ally.handelnd', f.person, true);
    o := public.ally_ui_ort(f.kennung);
    CONTINUE WHEN o->>'seite' IS DISTINCT FROM f.seite;
    neu := left(public.ally_ui_pfad(f.seite, o->'parameter'), 300);
    CONTINUE WHEN neu = f.kennung OR EXISTS (SELECT 1 FROM public.ally_ui_filter y WHERE y.person = f.person AND y.kennung = neu);
    UPDATE public.ally_ui_filter x SET kennung = neu WHERE x.person = f.person AND x.kennung = f.kennung;
  END LOOP;
  PERFORM set_config('ally.handelnd', '', true);
END $m$;
DO $m$
BEGIN
  IF (SELECT md5(string_agg(p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')|' || pg_get_function_result(p.oid) || '|' || md5(p.prosrc), E'\n' ORDER BY p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')' COLLATE "C")) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname::text = 'public' COLLATE "C" AND p.proname::text COLLATE "C" = ANY (ARRAY['ally_ui_pfad', 'ally_ui_kennung_text', 'ally_ui_kn_talent', 'ally_ui_kn_talent_darf', 'ally_ui_kn_kampagne', 'ally_ui_kn_kampagne_darf', 'ally_ui_kn_briefing', 'ally_ui_kn_briefing_darf', 'ally_ui_kn_ergebnis', 'ally_ui_kn_ergebnis_bereich', 'ally_ui_kn_ergebnis_darf', 'ally_ui_kn_person', 'ally_ui_kn_person_darf', 'ally_ui_kn_ordner', 'ally_ui_kn_ordner_darf', 'ally_ui_kn_termin', 'ally_ui_kn_termin_darf', 'ally_ui_kn_benachrichtigung', 'ally_ui_kn_benachrichtigung_bereich', 'ally_ui_kn_benachrichtigung_darf', 'ally_ui_kennung_person', 'ally_ui_kennung', 'ally_ui_kennung_person_teil', 'ally_ui_kennung_personen', 'ally_ui_kennung_fuer', 'ally_ui_kennung_pflegen', 'ally_ui_kennung_ausloeser', 'ally_ui_pfad_bauen', 'ally_ui_kennungen', 'ally_ui_kennungen_karte'])) IS DISTINCT FROM '1103966ca87c6ed8c9a4bfef7019b9f1' THEN RAISE EXCEPTION 'Migration 210: Funktionen nicht wie gebaut'; END IF;
END $m$;
