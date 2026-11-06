-- Migration 208 (eine Funktion „Briefing“, Stefan 06.11.2026): Morgen-Briefing und KI-Analysen werden die Funktion „Briefing“ im Basispaket (Seite Kommunikation › Briefing, ALLY 33; Ablauf ALLY 4).
-- a) Tabellen: briefing_bausteine (Register: Pakete melden Inhalte an, art sql/ki/ablauf), briefings (mehrere je Person: Name, Rhythmus, Uhrzeit, an/aus, Empfänger,
--    Zustellung Chat/Glocke/Mail, Papierkorb), briefing_inhalte, briefing_teilen, briefing_ergebnisse (Verlauf mit Kopf), briefing_laeufe (einmal je Zeitraum, Fehlversuche),
--    briefing_jetzt (Auftrag aus dem Chat), briefing_m208_sicherung (Stand vorher für den Rückbau).
-- b) neue Funktionen briefing_* (Fälligkeit, Bausteine, Ergebnis, Abschluss, Seite, Aktionen br_*, Chat, Kacheln); talents_ki_einstellungen_aktion ohne Tag/Uhrzeit.
-- c) Daten: Recht morgen_briefing heißt briefing (Rollen und Ausnahmen übernommen), neu briefing_andere (Vorlage Management), Seite „Briefing“ ohne Eintrag unter
--    Einstellungen › Funktionen, Seite KI-Analysen führt zur Seite Briefing; Übernahme Morgen-Briefing und KI-Analysen samt Ergebnissen, Teilen und letztem Versand;
--    Schalter morgen_briefing und talents_briefing entfallen (gesichert). Alte Tabellen talents_briefings* bleiben unverändert.
-- Wächter vorher: Funktionen wie nach 207, keine Teile von 208, keine Sicherung aus Rückbau 208. Läuft als Ganzes in der Transaktion des Aufrufs (psql -1). Rückbau: rueckbau208.sql.
DO $m$
BEGIN
  IF (SELECT md5(string_agg(p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')|' || pg_get_function_result(p.oid) || '|' || md5(p.prosrc), E'\n' ORDER BY p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')' COLLATE "C")) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname::text = 'public' COLLATE "C" AND p.proname::text COLLATE "C" = ANY (ARRAY['talents_ki_einstellungen_aktion', 'briefing_periode', 'briefing_zeitplan_text', 'briefing_darf', 'briefing_talents_fuer', 'briefing_talents_waise', 'briefing_manager', 'briefing_empfaenger_alle', 'briefing_empfaenger', 'briefing_naechster', 'briefing_sichtbar', 'briefing_bausteine_fuer', 'briefing_ergebnis_lesbar', 'briefing_kopf', 'briefing_standard_anlegen', 'briefing_bs_termine', 'briefing_bs_kunden_mails', 'briefing_bs_geschaeft_mails', 'briefing_bs_talents_zahlen', 'briefing_bs_talents_ki', 'briefing_bs_talents_ki_fertig', 'briefing_bs_talents_aufgaben', 'briefing_mail_standard', 'briefing_mail_platzhalter', 'briefing_mail_normal', 'briefing_html_text', 'briefing_absender', 'briefing_mail_bauen', 'briefing_faellig', 'briefing_ergebnis_bauen', 'briefing_abschluss', 'briefing_web', 'briefing_ui_aktion', 'briefing_meldung', 'briefing_kachel', 'briefing_talent_ui', 'briefing_start_stand', 'briefing_chat'])) IS NOT DISTINCT FROM '7c02d8684853ff5d7fa12f82af3a2b5f' THEN RAISE EXCEPTION 'Migration 208: schon eingespielt, nichts geändert'; END IF;
  IF (SELECT md5(string_agg(p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')|' || pg_get_function_result(p.oid) || '|' || md5(p.prosrc), E'\n' ORDER BY p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')' COLLATE "C")) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname::text = 'public' COLLATE "C" AND p.proname::text COLLATE "C" = ANY (ARRAY['talents_ki_einstellungen_aktion', 'briefing_periode', 'briefing_zeitplan_text', 'briefing_darf', 'briefing_talents_fuer', 'briefing_talents_waise', 'briefing_manager', 'briefing_empfaenger_alle', 'briefing_empfaenger', 'briefing_naechster', 'briefing_sichtbar', 'briefing_bausteine_fuer', 'briefing_ergebnis_lesbar', 'briefing_kopf', 'briefing_standard_anlegen', 'briefing_bs_termine', 'briefing_bs_kunden_mails', 'briefing_bs_geschaeft_mails', 'briefing_bs_talents_zahlen', 'briefing_bs_talents_ki', 'briefing_bs_talents_ki_fertig', 'briefing_bs_talents_aufgaben', 'briefing_mail_standard', 'briefing_mail_platzhalter', 'briefing_mail_normal', 'briefing_html_text', 'briefing_absender', 'briefing_mail_bauen', 'briefing_faellig', 'briefing_ergebnis_bauen', 'briefing_abschluss', 'briefing_web', 'briefing_ui_aktion', 'briefing_meldung', 'briefing_kachel', 'briefing_talent_ui', 'briefing_start_stand', 'briefing_chat'])) IS DISTINCT FROM '59b08691617ea4599c2307d7a183a10f' THEN RAISE EXCEPTION 'Migration 208: Funktionen nicht im erwarteten Stand, nichts geändert'; END IF;
  IF to_regclass('public.briefing_bausteine') IS NOT NULL OR to_regclass('public.briefing_bausteine_rb208') IS NOT NULL OR to_regclass('public.briefings') IS NOT NULL OR to_regclass('public.briefings_rb208') IS NOT NULL OR to_regclass('public.briefing_inhalte') IS NOT NULL OR to_regclass('public.briefing_inhalte_rb208') IS NOT NULL OR to_regclass('public.briefing_teilen') IS NOT NULL OR to_regclass('public.briefing_teilen_rb208') IS NOT NULL OR to_regclass('public.briefing_abbestellt') IS NOT NULL OR to_regclass('public.briefing_abbestellt_rb208') IS NOT NULL OR to_regclass('public.briefing_ergebnisse') IS NOT NULL OR to_regclass('public.briefing_ergebnisse_rb208') IS NOT NULL OR to_regclass('public.briefing_laeufe') IS NOT NULL OR to_regclass('public.briefing_laeufe_rb208') IS NOT NULL OR to_regclass('public.briefing_jetzt') IS NOT NULL OR to_regclass('public.briefing_jetzt_rb208') IS NOT NULL OR to_regclass('public.briefing_m208_sicherung') IS NOT NULL OR to_regclass('public.briefing_m208_sicherung_rb208') IS NOT NULL THEN RAISE EXCEPTION 'Migration 208: Tabellen von 208 oder eine Sicherung aus Rückbau 208 gibt es schon, nichts geändert'; END IF;
END $m$;
-- Migration 208 (eine Funktion „Briefing“, Stefan 06.11.2026): Tabellen. Zusatzpakete melden ihre Inhalte als Bausteine an (briefing_bausteine, Vorbild kalender_quellen).
CREATE TABLE public.briefing_bausteine (
  schluessel text PRIMARY KEY CHECK (schluessel ~ '^[a-z][a-z0-9_]{0,39}$'),
  name text NOT NULL CHECK (btrim(name) <> '' AND length(name) <= 80),
  beschreibung text NOT NULL DEFAULT '' CHECK (length(beschreibung) <= 300),
  gruppe text NOT NULL CHECK (btrim(gruppe) <> '' AND length(gruppe) <= 60),
  modul text REFERENCES public.plattform_module(schluessel) ON UPDATE CASCADE,
  recht text REFERENCES public.ally_rechte(schluessel) ON UPDATE CASCADE ON DELETE SET NULL,
  -- art: sql = Daten aus der Datenbankfunktion lesen(person text, optionen jsonb, heute date) → jsonb; ki = wie sql (Anfrage an die KI), danach fertig(ki_text text, daten jsonb) → jsonb;
  -- ablauf = Daten aus einem Unterablauf (n8n, Kennung in ablauf; Eingabe person, briefing_id, schluessel, optionen; Ausgabe zeilen)
  art text NOT NULL DEFAULT 'sql' CHECK (art IN ('sql', 'ki', 'ablauf')),
  lesen text CHECK (lesen ~ '^[a-z_][a-z0-9_]{0,62}$'),
  fertig text CHECK (fertig ~ '^[a-z_][a-z0-9_]{0,62}$'),
  ablauf text CHECK (ablauf ~ '^[A-Za-z0-9]{1,40}$'),
  google boolean NOT NULL DEFAULT false,
  ki boolean NOT NULL DEFAULT false,
  persoenlich boolean NOT NULL DEFAULT false,
  -- Talents als Empfänger (Personen talent:<Nummer>): der Baustein läuft für sie nur mit einem dieser Rechte (NULL = nie für Talents; Prüfung M3)
  rechte_talent text[],
  optionen jsonb NOT NULL DEFAULT '[]'::jsonb CHECK (jsonb_typeof(optionen) = 'array'),
  standard boolean NOT NULL DEFAULT false,
  reihenfolge integer NOT NULL DEFAULT 100,
  CHECK (art <> 'sql' OR lesen IS NOT NULL),
  CHECK (art <> 'ki' OR (lesen IS NOT NULL AND fertig IS NOT NULL)),
  CHECK (art <> 'ablauf' OR ablauf IS NOT NULL)
);

CREATE TABLE public.briefings (
  id integer GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
  person text NOT NULL REFERENCES public.ally_personen(matrix_user_id) ON UPDATE CASCADE ON DELETE CASCADE,
  name text NOT NULL CHECK (btrim(name) <> '' AND length(name) <= 80),
  an boolean NOT NULL DEFAULT true,
  rhythmus text NOT NULL DEFAULT 'tag' CHECK (rhythmus IN ('tag', 'woche', 'monat', 'hand')),
  tag smallint NOT NULL DEFAULT 1 CHECK (tag BETWEEN 1 AND 28 AND (rhythmus <> 'woche' OR tag <= 7)),
  uhrzeit text NOT NULL DEFAULT '05:00' CHECK (uhrzeit ~ '^([01][0-9]|2[0-3]):(00|15|30|45)$'),
  -- Empfänger: feste Personen (auf der Seite höchstens 50; Grenze der Tabelle 500, damit die Übernahme großer KI-Analysen nicht abbricht, Prüfung N4)
  empfaenger text[] NOT NULL DEFAULT '{}' CHECK (cardinality(empfaenger) <= 500),
  -- dazu „Alle Manager/innen der Talents“ (Stefan 06.11.2026): beim Lauf die zuständigen Personen der Talents des Briefings (briefing_manager), neue automatisch
  manager boolean NOT NULL DEFAULT false,
  -- Kreis der Manager/innen: briefing = Zuständige der Talents dieses Briefings; alle = Zuständige aller aktiven Talents (wie bisher „Zuständige“ der KI-Analysen,
  -- jede Person mit ihren eigenen Talents; Talents ohne Zuständige: Admins wie bisher)
  manager_kreis text NOT NULL DEFAULT 'briefing' CHECK (manager_kreis IN ('briefing', 'alle')),
  -- „An mich“ (Stefan 06.11.2026: „wer das Briefing bekommt, entscheidet, wer es anlegt“): die Person, der es gehört, bekommt es nur mit Häkchen (neu: an)
  an_mich boolean NOT NULL DEFAULT true,
  chat boolean NOT NULL DEFAULT false,
  glocke boolean NOT NULL DEFAULT false,
  mail boolean NOT NULL DEFAULT false,
  -- Mail je Briefing (Stefan 06.11.2026 „je Briefing einstellbar“, wie bei den KI-Analysen, Migration 180/204): Absender-Postfach (NULL = Absender für
  -- Systemnachrichten), Betreff und Text vor dem Briefing (NULL = Standard), Signatur (aus, eigene oder die des Absenders), KI-Hinweis
  absender text CHECK (absender IS NULL OR (absender = lower(btrim(absender)) AND length(absender) <= 300)),
  mail_betreff text CHECK (mail_betreff IS NULL OR length(mail_betreff) <= 200),
  mail_html text CHECK (mail_html IS NULL OR length(mail_html) <= 20000),
  signatur_an boolean NOT NULL DEFAULT true,
  signatur_html text CHECK (signatur_html IS NULL OR length(signatur_html) <= 20000),
  ki_hinweis boolean NOT NULL DEFAULT false,
  -- von einer Test-Person angelegt bzw. aus einer KI-Analyse mit Kennzeichen testdaten (Migration 180): Mail nur im Testmodus, es geht nie eine Mail raus
  testdaten boolean NOT NULL DEFAULT false,
  standard boolean NOT NULL DEFAULT false,
  -- herkunft ki_analyse_person: KI-Analyse ohne anlegende Person (Standard-Analyse); jede Person, die sie bekam, hat ein eigenes Briefing (Stefan 06.11.2026)
  herkunft text CHECK (herkunft IN ('morgen_briefing', 'ki_analyse', 'ki_analyse_person')),
  alt_id integer,
  erstellt_am timestamptz NOT NULL DEFAULT now(),
  erstellt_von text,
  geaendert_am timestamptz NOT NULL DEFAULT now(),
  geaendert_von text,
  geloescht_am timestamptz,
  geloescht_von text
);
CREATE UNIQUE INDEX briefings_ein_standard ON public.briefings (person) WHERE standard;
CREATE INDEX briefings_person ON public.briefings (person);
CREATE INDEX briefings_alt ON public.briefings (alt_id) WHERE alt_id IS NOT NULL;

CREATE TABLE public.briefing_inhalte (
  briefing_id integer NOT NULL REFERENCES public.briefings(id) ON DELETE CASCADE,
  baustein text NOT NULL REFERENCES public.briefing_bausteine(schluessel) ON UPDATE CASCADE ON DELETE CASCADE,
  optionen jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(optionen) = 'object' AND octet_length(optionen::text) <= 4000),
  PRIMARY KEY (briefing_id, baustein)
);

CREATE TABLE public.briefing_teilen (
  briefing_id integer NOT NULL REFERENCES public.briefings(id) ON DELETE CASCADE,
  person text NOT NULL REFERENCES public.ally_personen(matrix_user_id) ON UPDATE CASCADE ON DELETE CASCADE,
  geteilt_am timestamptz NOT NULL DEFAULT now(),
  geteilt_von text,
  PRIMARY KEY (briefing_id, person)
);

-- Abbestellt (Stefan 06.11.2026): Empfänger, die ein Briefing einer anderen Person nicht mehr bekommen wollen (kein Ergebnis, kein Chat, keine Glocke, keine Mail);
-- „Wieder bestellen“ entfernt die Zeile. Die Person, der das Briefing gehört, sieht in der Kachel Empfänger, wer abbestellt hat.
CREATE TABLE public.briefing_abbestellt (
  briefing_id integer NOT NULL REFERENCES public.briefings(id) ON DELETE CASCADE,
  person text NOT NULL,
  am timestamptz NOT NULL DEFAULT now(),
  herkunft text CHECK (herkunft IN ('person', 'uebernahme')),
  PRIMARY KEY (briefing_id, person)
);

CREATE TABLE public.briefing_ergebnisse (
  id bigint GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
  briefing_id integer NOT NULL REFERENCES public.briefings(id) ON DELETE CASCADE,
  person text NOT NULL,
  erstellt_am timestamptz NOT NULL DEFAULT now(),
  erstellt_von text,
  nach_zeitplan boolean NOT NULL DEFAULT false,
  periode text CHECK (periode IS NULL OR periode ~ '^(T[0-9]{4}-[0-9]{2}-[0-9]{2}|W[0-9]{4}-[0-9]{2}|M[0-9]{4}-[0-9]{2})$'),
  inhalte text[] NOT NULL DEFAULT '{}',
  zeitraum jsonb,
  talents jsonb CHECK (talents IS NULL OR (jsonb_typeof(talents) = 'array' AND jsonb_array_length(talents) <= 500)),
  stand_zahlen timestamptz,
  zustellung jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(zustellung) = 'object'),
  zugestellt text CHECK (zugestellt IS NULL OR length(zugestellt) <= 600),
  ki boolean,
  text text NOT NULL CHECK (length(text) <= 60000),
  html text CHECK (html IS NULL OR length(html) <= 120000),
  versuche smallint NOT NULL DEFAULT 1,
  uebernommen boolean NOT NULL DEFAULT false,
  alt_id bigint UNIQUE
);
CREATE UNIQUE INDEX briefing_ergebnisse_zeitplan ON public.briefing_ergebnisse (briefing_id, person, periode) WHERE nach_zeitplan;
CREATE INDEX briefing_ergebnisse_briefing ON public.briefing_ergebnisse (briefing_id, erstellt_am DESC);
CREATE INDEX briefing_ergebnisse_person ON public.briefing_ergebnisse (person, erstellt_am DESC);

-- Läufe nach Zeitplan je Briefing, Person und Zeitraum (einmal je Zeitraum; Fehlversuche höchstens 3, dann erst im nächsten Zeitraum).
-- status laeuft (Prüfung N6): briefing_faellig vergibt den Lauf, bevor ALLY 4 ihn erstellt; ein zweiter Lauf, der sich überschneidet, nimmt ihn nicht noch einmal.
-- Nach 30 Minuten ohne Abschluss gilt er als abgebrochen und zählt als Versuch.
CREATE TABLE public.briefing_laeufe (
  briefing_id integer NOT NULL REFERENCES public.briefings(id) ON DELETE CASCADE,
  person text NOT NULL,
  periode text NOT NULL CHECK (periode ~ '^(T[0-9]{4}-[0-9]{2}-[0-9]{2}|W[0-9]{4}-[0-9]{2}|M[0-9]{4}-[0-9]{2})$'),
  status text NOT NULL CHECK (status IN ('ok', 'fehler', 'laeuft')),
  versuche smallint NOT NULL DEFAULT 1,
  geaendert_am timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (briefing_id, person, periode)
);

-- „Briefing jetzt“ aus dem Chat: ALLY 4 nimmt den Auftrag beim nächsten Lauf (alle 15 Minuten) mit
CREATE TABLE public.briefing_jetzt (
  briefing_id integer NOT NULL REFERENCES public.briefings(id) ON DELETE CASCADE,
  person text NOT NULL,
  angefordert_am timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (briefing_id, person)
);

-- Rückbau ohne Datenverlust: Zeilen, die 208 ändert oder entfernt (Rechte, Seiten, Pakete, Schalter), im Stand vorher
CREATE TABLE public.briefing_m208_sicherung (
  art text NOT NULL,
  schluessel text NOT NULL,
  daten jsonb NOT NULL,
  PRIMARY KEY (art, schluessel)
);
CREATE OR REPLACE FUNCTION public.briefing_periode(p_rhythmus text, p_heute date)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
AS $function$
  -- Migration 208 (Briefing): Zeitraum eines Laufs nach Zeitplan wie bei den KI-Analysen (Migration 180): T = Tag, W = Kalenderwoche, M = Monat; „nur von Hand“ = NULL
  SELECT CASE p_rhythmus WHEN 'tag' THEN 'T' || to_char(p_heute, 'YYYY-MM-DD') WHEN 'woche' THEN 'W' || to_char(p_heute, 'IYYY-IW')
    WHEN 'monat' THEN 'M' || to_char(p_heute, 'YYYY-MM') END
$function$;
CREATE OR REPLACE FUNCTION public.briefing_zeitplan_text(p_an boolean, p_rhythmus text, p_tag integer, p_uhrzeit text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
AS $function$
  -- Migration 208 (Briefing): Zeitplan in Worten; ausgeschaltet heißt „Aus“ (ohne Uhrzeit, damit nie „aus“ und eine Uhrzeit zugleich erscheinen)
  SELECT CASE WHEN NOT coalesce(p_an, false) THEN 'Aus'
    WHEN p_rhythmus = 'woche' THEN 'Wöchentlich, ' || (ARRAY['montags', 'dienstags', 'mittwochs', 'donnerstags', 'freitags', 'samstags', 'sonntags'])[least(greatest(p_tag, 1), 7)] || ' um ' || p_uhrzeit || ' Uhr'
    WHEN p_rhythmus = 'tag' THEN 'Täglich um ' || p_uhrzeit || ' Uhr'
    WHEN p_rhythmus = 'monat' THEN 'Monatlich am ' || p_tag || '. um ' || p_uhrzeit || ' Uhr'
    ELSE 'Nur von Hand' END
$function$;
CREATE OR REPLACE FUNCTION public.briefing_darf(p_person text)
 RETURNS boolean
 LANGUAGE sql
 STABLE
AS $function$
  -- Migration 208 (Briefing): Seite Briefing nutzen (Paket an, Seite an, Recht „Briefing“; ally_ui_funktion_erlaubt wie jede Seite); Test-Personen nie nach Zeitplan (siehe briefing_faellig)
  SELECT coalesce(public.ally_ui_funktion_erlaubt(p_person, NULL, 'morgen-briefing'), false)
$function$;
CREATE OR REPLACE FUNCTION public.briefing_talents_fuer(p_person text, p_optionen jsonb)
 RETURNS integer[]
 LANGUAGE sql
 STABLE
AS $function$
  -- Migration 208 (Briefing): Talents eines Social-Media-Bausteins für eine Person. Personen: die eigenen (zuständig) und dazu die in den Optionen gewählten,
  -- soweit die Person sie sieht (wie bei den KI-Analysen). Ein Talent als Empfänger: nur das eigene. Nur aktive, keine Test-Talents.
  SELECT coalesce(array_agg(DISTINCT t.id ORDER BY t.id), '{}') FROM public.talents t
  WHERE t.status = 'aktiv' AND NOT public.talents_ist_testdaten(t.id)
    AND CASE WHEN public.ally_person_ist_talent(p_person) THEN t.id = (SELECT p.talent_id FROM public.ally_personen p WHERE p.matrix_user_id = p_person AND p.aktiv)
             ELSE public.talents_zugriff(p_person) IS NOT NULL
               AND (EXISTS (SELECT 1 FROM public.talent_personen tp WHERE tp.talent_id = t.id AND tp.matrix_user_id = p_person)
                    OR (t.id::text IN (SELECT jsonb_array_elements_text(CASE WHEN jsonb_typeof(p_optionen->'talents') = 'array' THEN p_optionen->'talents' ELSE '[]'::jsonb END))
                        AND coalesce(public.talent_sichtbar(p_person, t.id), false))) END
$function$;
CREATE OR REPLACE FUNCTION public.briefing_talents_waise()
 RETURNS integer[]
 LANGUAGE sql
 STABLE
AS $function$
  -- Migration 208 (Briefing): aktive Talents (keine Test-Talents) ohne zuständige Person, die ein Briefing bekommen kann (aktiv, keine Test-Person, kein Talent,
  -- Zugriff auf Talents). Kreis „alle“ der Manager/innen: diese Talents bekommen wie bisher die Admins (talents_briefing_zustaendige), auch in ihrem Ergebnis.
  SELECT coalesce(array_agg(t.id ORDER BY t.id), '{}') FROM public.talents t
  WHERE t.status = 'aktiv' AND NOT public.talents_ist_testdaten(t.id)
    AND NOT EXISTS (SELECT 1 FROM public.talent_personen tp JOIN public.ally_personen p ON p.matrix_user_id = tp.matrix_user_id AND p.aktiv AND NOT p.testdaten
                    WHERE tp.talent_id = t.id AND NOT public.ally_person_ist_talent(p.matrix_user_id) AND public.talents_zugriff(p.matrix_user_id) IS NOT NULL)
$function$;
CREATE OR REPLACE FUNCTION public.briefing_manager(p_id integer)
 RETURNS SETOF text
 LANGUAGE sql
 STABLE
AS $function$
  -- Migration 208 (Briefing, Stefan 06.11.2026): Empfänger „Alle Manager/innen der Talents“ – beim Lauf die zuständigen Personen (talent_personen) der Talents:
  -- Kreis briefing = die in den Inhalten gewählten Talents und die eigenen Talents der Person, der das Briefing gehört (wie „Zahlen der Talents“, briefing_talents_fuer);
  -- Kreis alle = alle aktiven Talents (wie bisher „Zuständige“ der KI-Analysen; für Talents ohne zuständige Person die Admins, wie talents_briefing_zustaendige).
  -- Jede Person bekommt im Ergebnis ihre eigenen Talents (und die gewählten, soweit sie sie sieht). Nur mit Inhalten des Social-Media-Pakets; nur aktive Personen
  -- mit Zugriff auf Talents, keine Test-Personen, keine Talents.
  WITH b AS (SELECT x.* FROM public.briefings x WHERE x.id = p_id AND x.manager AND x.geloescht_am IS NULL
               AND EXISTS (SELECT 1 FROM public.briefing_inhalte bi JOIN public.briefing_bausteine bz ON bz.schluessel = bi.baustein AND bz.modul = 'talents' WHERE bi.briefing_id = x.id)),
  t AS (SELECT u.id FROM b CROSS JOIN LATERAL unnest(public.briefing_talents_fuer(b.person, jsonb_build_object('talents', (
          SELECT coalesce(jsonb_agg(DISTINCT x), '[]'::jsonb) FROM public.briefing_inhalte bi
          CROSS JOIN LATERAL jsonb_array_elements_text(CASE WHEN jsonb_typeof(bi.optionen->'talents') = 'array' THEN bi.optionen->'talents' ELSE '[]'::jsonb END) x
          WHERE bi.briefing_id = b.id)))) u(id) WHERE b.manager_kreis = 'briefing'
        UNION SELECT tt.id FROM b JOIN public.talents tt ON b.manager_kreis = 'alle' AND tt.status = 'aktiv' AND NOT public.talents_ist_testdaten(tt.id)),
  z AS (SELECT tp.talent_id, p.matrix_user_id AS u FROM t JOIN public.talent_personen tp ON tp.talent_id = t.id
          JOIN public.ally_personen p ON p.matrix_user_id = tp.matrix_user_id AND p.aktiv AND NOT p.testdaten
        WHERE NOT public.ally_person_ist_talent(p.matrix_user_id) AND public.talents_zugriff(p.matrix_user_id) IS NOT NULL)
  SELECT DISTINCT z.u FROM z
  UNION
  SELECT p.matrix_user_id FROM b JOIN public.ally_personen p ON b.manager_kreis = 'alle' AND p.aktiv AND NOT p.testdaten
  WHERE cardinality(public.briefing_talents_waise()) > 0
    AND coalesce(public.ally_hat_recht(p.matrix_user_id, 'admin'), false) AND NOT public.ally_person_ist_talent(p.matrix_user_id)
$function$;
CREATE OR REPLACE FUNCTION public.briefing_empfaenger_alle(p_id integer)
 RETURNS TABLE(person text, eigen boolean, manager boolean, abbestellt boolean)
 LANGUAGE sql
 STABLE
AS $function$
  -- Migration 208 (Briefing): alle Empfänger eines Briefings mit Kennzeichen – die Person, der es gehört (mit „An mich“, solange sie die Seite Briefing nutzen darf),
  -- die festen Empfänger und „Alle Manager/innen der Talents“ (briefing_manager), andere Personen nur, solange sie das Recht „Briefings für andere“ hat, nur aktive.
  -- abbestellt (Stefan 06.11.2026): hat das Briefing abbestellt und bekommt es nicht (briefing_empfaenger lässt sie weg). Im Papierkorb niemand.
  -- Die Person, der es gehört, nur mit „An mich“ (Stefan 06.11.2026: „wer das Briefing bekommt, entscheidet, wer es anlegt“).
  WITH b AS (SELECT x.* FROM public.briefings x WHERE x.id = p_id AND x.geloescht_am IS NULL AND public.briefing_darf(x.person)),
  a AS (SELECT p.matrix_user_id AS person, false AS manager FROM b CROSS JOIN LATERAL unnest(b.empfaenger) e(x)
          JOIN public.ally_personen p ON p.matrix_user_id = e.x AND p.aktiv
        WHERE e.x <> b.person AND coalesce(public.ally_hat_recht(b.person, 'briefing_andere'), false)
        UNION ALL
        SELECT m.m, true FROM b CROSS JOIN LATERAL public.briefing_manager(b.id) m(m)
        WHERE m.m <> b.person AND coalesce(public.ally_hat_recht(b.person, 'briefing_andere'), false))
  SELECT b.person, true, false, false FROM b WHERE b.an_mich
  UNION ALL
  SELECT a.person, false, bool_and(a.manager), EXISTS (SELECT 1 FROM public.briefing_abbestellt x WHERE x.briefing_id = p_id AND x.person = a.person)
  FROM a GROUP BY a.person
$function$;
CREATE OR REPLACE FUNCTION public.briefing_empfaenger(p_id integer)
 RETURNS TABLE(person text, eigen boolean)
 LANGUAGE sql
 STABLE
AS $function$
  -- Migration 208 (Briefing): wer ein Briefing bekommt. Die Person, der es gehört, mit „An mich“ (solange sie die Seite Briefing nutzen darf); andere Personen
  -- (auch Talents; feste Empfänger und „Alle Manager/innen der Talents“) nur, solange sie das Recht „Briefings für andere“ hat, nur aktive und nicht abbestellte
  -- (briefing_empfaenger_alle). Im Papierkorb niemand.
  SELECT e.person, e.eigen FROM public.briefing_empfaenger_alle(p_id) e WHERE NOT e.abbestellt
$function$;
CREATE OR REPLACE FUNCTION public.briefing_naechster(p_id integer)
 RETURNS text
 LANGUAGE sql
 STABLE
AS $function$
  -- Migration 208 (Briefing): nächster Termin nach Zeitplan („Mo, 3.11.2026, 05:00“), NULL wenn aus, nur von Hand oder im Papierkorb. Ist der Zeitraum
  -- heute schon erledigt (briefing_laeufe ok), zählt erst der nächste.
  SELECT (ARRAY['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'])[extract(isodow FROM d)::integer] || ', ' || to_char(d, 'FMDD.FMMM.YYYY') || ', ' || b.uhrzeit
  FROM public.briefings b
  CROSS JOIN LATERAL (SELECT (now() AT TIME ZONE 'Europe/Berlin')::date AS h) hh
  CROSS JOIN LATERAL (SELECT min(hh.h + k) AS d FROM generate_series(0, 62) k
    WHERE CASE b.rhythmus WHEN 'tag' THEN true WHEN 'woche' THEN extract(isodow FROM hh.h + k)::integer = b.tag
                          WHEN 'monat' THEN extract(day FROM hh.h + k)::integer = b.tag ELSE false END
      AND (k > 0 OR ((now() AT TIME ZONE 'Europe/Berlin')::time < b.uhrzeit::time
                     AND NOT EXISTS (SELECT 1 FROM public.briefing_laeufe l WHERE l.briefing_id = b.id AND l.person = b.person
                                     AND l.periode = public.briefing_periode(b.rhythmus, hh.h) AND l.status = 'ok')))) x
  WHERE b.id = p_id AND b.an AND b.rhythmus IN ('tag', 'woche', 'monat') AND b.geloescht_am IS NULL
$function$;
CREATE OR REPLACE FUNCTION public.briefing_sichtbar(p_person text, p_id integer)
 RETURNS boolean
 LANGUAGE sql
 STABLE
AS $function$
  -- Migration 208 (Briefing): ein Briefing sehen die Person, der es gehört, ihre Empfänger und die Personen, mit denen es geteilt ist (alle mit der Seite Briefing)
  -- (Empfänger auch, wenn sie es abbestellt haben: so können sie es wieder bestellen)
  SELECT public.briefing_darf(p_person) AND EXISTS (SELECT 1 FROM public.briefings b WHERE b.id = p_id AND (b.person = p_person
    OR (b.geloescht_am IS NULL AND EXISTS (SELECT 1 FROM public.briefing_teilen t WHERE t.briefing_id = b.id AND t.person = p_person))
    OR (b.geloescht_am IS NULL AND EXISTS (SELECT 1 FROM public.briefing_empfaenger_alle(b.id) e WHERE e.person = p_person))))
$function$;
CREATE OR REPLACE FUNCTION public.briefing_bausteine_fuer(p_person text)
 RETURNS SETOF public.briefing_bausteine
 LANGUAGE sql
 STABLE
AS $function$
  -- Migration 208 (Briefing): Bausteine, die eine Person wählen kann bzw. die für sie laufen: Paket des Bausteins an und das nötige Recht. Ein Talent als Empfänger
  -- (Person talent:<Nummer>): nur Bausteine mit rechte_talent und einem dieser Rechte (Prüfung M3: briefing_faellig prüft je Empfänger).
  SELECT x.* FROM public.briefing_bausteine x
  WHERE (x.modul IS NULL OR coalesce(public.plattform_modul_an(x.modul), false))
    AND CASE WHEN public.ally_person_ist_talent(p_person)
             THEN x.rechte_talent IS NOT NULL AND EXISTS (SELECT 1 FROM unnest(x.rechte_talent) r WHERE coalesce(public.ally_hat_recht(p_person, r), false))
             ELSE x.recht IS NULL OR coalesce(public.ally_hat_recht(p_person, x.recht), false) END
  ORDER BY x.reihenfolge, x.schluessel COLLATE "C"
$function$;
CREATE OR REPLACE FUNCTION public.briefing_ergebnis_lesbar(p_person text, p_ergebnis bigint)
 RETURNS boolean
 LANGUAGE sql
 STABLE
AS $function$
  -- Migration 208 (Briefing): ein Ergebnis lesen darf die Person, für die es erstellt wurde. Die Person, der das Briefing gehört, liest auch die Ergebnisse
  -- anderer, wenn keiner der Inhalte persönlich ist (Mails, Termine) und sie alle Talents des Ergebnisses sieht. Übernommene Ergebnisse nur die Person selbst.
  SELECT EXISTS (SELECT 1 FROM public.briefing_ergebnisse r JOIN public.briefings b ON b.id = r.briefing_id
    WHERE r.id = p_ergebnis AND public.briefing_darf(p_person)
      AND (r.person = p_person OR (b.person = p_person AND NOT r.uebernommen
        AND NOT EXISTS (SELECT 1 FROM public.briefing_bausteine x WHERE x.schluessel = ANY (r.inhalte) AND x.persoenlich)
        AND NOT EXISTS (SELECT 1 FROM jsonb_array_elements(coalesce(r.talents, '[]'::jsonb)) t
                        WHERE NOT ((t->>'id') ~ '^[0-9]{1,9}$' AND coalesce(public.talent_sichtbar(p_person, (t->>'id')::integer), false))))))
$function$;
CREATE OR REPLACE FUNCTION public.briefing_kopf(p_ergebnis bigint)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
AS $function$
  -- Migration 208 (Briefing): Kopf eines Ergebnisses in Worten wie bei den KI-Analysen (Migration 180): erstellt am, erstellt von (Person oder nach Zeitplan),
  -- Zeitraum der Daten (nur mit Zahlen der Talents), Talents, Stand der Zahlen, Zugestellt, KI (nur mit KI-Einordnung).
  SELECT jsonb_build_object('id', r.id, 'briefing_id', r.briefing_id, 'person', r.person,
    'fuer', coalesce((SELECT p.name FROM public.ally_personen p WHERE p.matrix_user_id = r.person), r.person),
    'erstellt_am', public.arbeit_zeit(r.erstellt_am),
    'erstellt_von', CASE WHEN r.uebernommen AND r.erstellt_von IS NULL AND NOT r.nach_zeitplan THEN 'nicht erfasst (vor der Umstellung)' WHEN r.nach_zeitplan THEN 'automatisch nach Zeitplan'
                         ELSE coalesce((SELECT p.name FROM public.ally_personen p WHERE p.matrix_user_id = r.erstellt_von), r.erstellt_von, 'unbekannt') END,
    'zeitraum', CASE WHEN jsonb_typeof(r.zeitraum) = 'object' AND r.zeitraum ? 'text' THEN (r.zeitraum->>'text') || coalesce(' verglichen mit ' || (r.zeitraum->>'vergleich_text'), '') END,
    'talents', CASE WHEN r.talents IS NULL THEN NULL WHEN jsonb_array_length(r.talents) = 0 THEN 'keine'
                    ELSE (SELECT string_agg(x->>'name' || CASE WHEN coalesce((x->>'zahlen')::boolean, true) THEN '' ELSE ' (ohne Zahlen)' END, ', ' ORDER BY y.n)
                          FROM jsonb_array_elements(r.talents) WITH ORDINALITY y(x, n)) END,
    'stand_zahlen', CASE WHEN r.talents IS NULL THEN NULL WHEN r.stand_zahlen IS NULL THEN 'noch kein Abruf' ELSE 'letzter Abruf ' || public.arbeit_zeit(r.stand_zahlen) END,
    'zugestellt', coalesce(r.zugestellt, 'auf der Seite'),
    'ki', CASE WHEN r.ki IS NULL THEN NULL WHEN r.ki THEN 'Einordnung gelungen' ELSE 'Einordnung fehlt diesmal' END,
    'ki_ok', r.ki, 'zustell_warn', coalesce(r.zugestellt ~ '(fehlgeschlagen|nicht möglich|nicht versendet|nicht angelegt)', false))
  FROM public.briefing_ergebnisse r WHERE r.id = p_ergebnis
$function$;
CREATE OR REPLACE FUNCTION public.briefing_standard_anlegen(p_person text)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
DECLARE bid integer;
BEGIN
  -- Migration 208 (Briefing): Standard für jede Person, die die Seite Briefing nutzen darf: ein „Tägliches Briefing“ (05:00, an, Chat und Glocke, Bausteine mit
  -- standard). Nur einmal je Person (Merker briefing_standard in ally_nutzer_einstellungen): wer es löscht, bekommt es nicht wieder. Test-Personen bekommen keins.
  IF p_person IS NULL OR NOT public.briefing_darf(p_person) OR public.ally_person_ist_testdaten(p_person)
     OR EXISTS (SELECT 1 FROM public.ally_nutzer_einstellungen e WHERE e.matrix_user_id = p_person AND e.schluessel = 'briefing_standard') THEN
    RETURN NULL;
  END IF;
  INSERT INTO public.ally_nutzer_einstellungen (matrix_user_id, schluessel, wert) VALUES (p_person, 'briefing_standard', 'angelegt')
  ON CONFLICT (matrix_user_id, schluessel) DO NOTHING;
  IF EXISTS (SELECT 1 FROM public.briefings b WHERE b.person = p_person AND b.standard) THEN RETURN NULL; END IF;
  INSERT INTO public.briefings (person, name, an, rhythmus, tag, uhrzeit, chat, glocke, standard, erstellt_von, geaendert_von)
  VALUES (p_person, 'Tägliches Briefing', true, 'tag', 1, '05:00', true, true, true, NULL, NULL) RETURNING id INTO bid;
  INSERT INTO public.briefing_inhalte (briefing_id, baustein, optionen)
  SELECT bid, x.schluessel, '{}'::jsonb FROM public.briefing_bausteine_fuer(p_person) x WHERE x.standard;
  RETURN bid;
END $function$;
CREATE OR REPLACE FUNCTION public.briefing_bs_termine(p_person text, p_optionen jsonb, p_heute date)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE k jsonb; z jsonb;
BEGIN
  -- Migration 208 (Briefing), Baustein „Termine“ (Basispaket): Einträge des Tages aus dem internen Kalender und allen angemeldeten Kalenderquellen
  -- (kalender_eintraege, Migration 205/207; eigene interne Termine nur mit dem Recht „Kalender“). Den Google-Kalender der Person liest ALLY 4 („Termine (Google)“,
  -- Kennung kalender_id) und fügt ihn beim Zusammenstellen ein (briefing_ergebnis_bauen). eintraege: sort (Sortierschlüssel), t (Zeile).
  k := public.kalender_eintraege(p_person, p_heute, p_heute, false);
  SELECT coalesce(jsonb_agg(jsonb_build_object('sort', CASE WHEN coalesce((e->>'ganztags')::boolean, false) THEN '00:00' ELSE coalesce(e->>'von', '00:00') END,
      't', CASE WHEN coalesce((e->>'ganztags')::boolean, false) OR coalesce(e->>'von', '') = '' THEN 'ganztägig' ELSE (e->>'von') || coalesce('–' || nullif(e->>'bis', ''), '') END
        || ' · ' || coalesce(nullif(btrim(e->>'titel'), ''), '(ohne Titel)') || coalesce(' · ' || nullif(btrim(e->>'ort'), ''), '')
        || coalesce(' (' || nullif(btrim(e->>'art_text'), '') || ')', '')) ORDER BY e->>'von' COLLATE "C"), '[]'::jsonb) INTO z
  FROM jsonb_array_elements(coalesce(k->'eintraege', '[]'::jsonb)) e;
  RETURN jsonb_build_object('eintraege', z, 'leer', 'Keine Termine', 'kalender_id', nullif(btrim(coalesce(public.ally_nutzer_wert(p_person, 'kalender_id'), '')), ''));
END $function$;
CREATE OR REPLACE FUNCTION public.briefing_bs_kunden_mails(p_person text, p_optionen jsonb, p_heute date)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
AS $function$
  -- Migration 208 (Briefing), Baustein „Mails von Kunden und Fristen (24 h)“ (Basispaket), wie bisher im Morgen-Briefing (ALLY 4): Mails der Kundschaft und
  -- zeitkritische Mails der letzten 24 Stunden aus Postfächern, für die die Person zuständig ist und die aktiv sind; je Absender und Betreff einmal.
  SELECT jsonb_build_object('leer', 'Keine Mails der Kundschaft oder Fristen', 'zeilen', coalesce(jsonb_agg(z ORDER BY m.created_at, n), '[]'::jsonb))
  FROM (SELECT DISTINCT ON (l.sender, l.subject) l.* FROM public.mail_klassifizierung_log l
        WHERE l.created_at > now() - interval '24 hours'
          AND (l.kategorie_key = 'kunde' OR (l.zeitkritisch = true AND l.kategorie_key NOT IN ('spam', 'geschaeft')))
          AND public.ally_postfach_zustaendig(p_person, l.postfach) AND public.ally_postfach_aktiv(l.postfach)
        ORDER BY l.sender, l.subject, l.created_at DESC) m
  CROSS JOIN LATERAL (VALUES (1, jsonb_build_object('t', CASE WHEN m.zeitkritisch THEN 'Frist · ' ELSE '' END || coalesce(nullif(m.sender, ''), '?'))),
                             (2, jsonb_build_object('t', coalesce(nullif(m.subject, ''), '(ohne Betreff)'), 'k', true))) v(n, z)
$function$;
CREATE OR REPLACE FUNCTION public.briefing_bs_geschaeft_mails(p_person text, p_optionen jsonb, p_heute date)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
AS $function$
  -- Migration 208 (Briefing), Baustein „Geschäftliche Mails (24 h)“ (Basispaket), wie bisher im Morgen-Briefing: Kategorie geschäftlich der letzten 24 Stunden,
  -- zuständige und aktive Postfächer, je Absender und Betreff einmal.
  SELECT jsonb_build_object('leer', 'Keine geschäftlichen Mails', 'zeilen', coalesce(jsonb_agg(z ORDER BY m.created_at, n), '[]'::jsonb))
  FROM (SELECT DISTINCT ON (l.sender, l.subject) l.* FROM public.mail_klassifizierung_log l
        WHERE l.created_at > now() - interval '24 hours' AND l.kategorie_key = 'geschaeft'
          AND public.ally_postfach_zustaendig(p_person, l.postfach) AND public.ally_postfach_aktiv(l.postfach)
        ORDER BY l.sender, l.subject, l.created_at DESC) m
  CROSS JOIN LATERAL (VALUES (1, jsonb_build_object('t', CASE WHEN m.zeitkritisch THEN 'Frist · ' ELSE '' END || coalesce(nullif(m.sender, ''), '?')
                                                         || CASE WHEN m.hat_anhang THEN ' (mit Anhang)' ELSE '' END)),
                             (2, jsonb_build_object('t', coalesce(nullif(m.subject, ''), '(ohne Betreff)'), 'k', true))) v(n, z)
$function$;
CREATE OR REPLACE FUNCTION public.briefing_bs_talents_zahlen(p_person text, p_optionen jsonb, p_heute date)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
  z jsonb; daten jsonb; ids integer[]; zeilen jsonb := '[]'::jsonb; t jsonb; n integer;
  art text := CASE WHEN p_optionen->>'zeitraum' IN ('letzte_7_tage', 'letzte_30_tage', 'vormonat') THEN p_optionen->>'zeitraum' ELSE 'letzte_7_tage' END;
BEGIN
  -- Migration 208 (Briefing), Baustein „Zahlen der Talents mit Vergleich“ (Social-Media-Paket): Zahlen je Talent im Zeitraum (letzte 7 bzw. 30 Tage oder Vormonat,
  -- talents_briefing_zeitraum aus Migration 180) verglichen mit dem Zeitraum davor (talents_briefing_talent). Höchstens 10 Talents im Text, im Kopf alle.
  -- Ein Talent als Empfänger nur mit dem Recht „Zahlen der letzten 28 Tage“.
  IF public.ally_person_ist_talent(p_person) AND NOT coalesce(public.ally_hat_recht(p_person, 'talent_zahlen'), false) THEN
    RETURN jsonb_build_object('zeilen', '[]'::jsonb, 'leer', 'Keine Zahlen');
  END IF;
  z := public.talents_briefing_zeitraum(art, p_heute);
  ids := public.briefing_talents_fuer(p_person, p_optionen);
  SELECT coalesce(jsonb_agg(d ORDER BY abs(coalesce((d->'veraenderung_reichweite'->>'prozent')::numeric, 0)) DESC, d->>'name' COLLATE "C"), '[]'::jsonb) INTO daten
  FROM unnest(ids) tid
  CROSS JOIN LATERAL public.talents_briefing_talent(tid, (z->>'von')::date, (z->>'bis')::date, (z->>'vergleich_von')::date, (z->>'vergleich_bis')::date) d;
  n := 0;
  FOR t IN SELECT y FROM jsonb_array_elements(daten) y LOOP
    n := n + 1;
    EXIT WHEN n > 10;
    zeilen := zeilen || jsonb_build_object('t', CASE WHEN coalesce((t->'woche'->>'tage_mit_zahlen')::integer, 0) = 0 THEN (t->>'name') || ': keine Zahlen im Zeitraum'
      ELSE (t->>'name') || ': Reichweite ' || coalesce(public.talents_zahl_text((t->'woche'->>'reichweite')::numeric), '–')
        || CASE WHEN t->'veraenderung_reichweite'->>'prozent' IS NOT NULL THEN ' (' || (t->'veraenderung_reichweite'->>'text') || ')' ELSE '' END
        || ', Interaktionen ' || coalesce(public.talents_zahl_text((t->'woche'->>'interaktionen')::numeric), '–')
        || CASE WHEN t->'veraenderung_interaktionen'->>'prozent' IS NOT NULL THEN ' (' || (t->'veraenderung_interaktionen'->>'text') || ')' ELSE '' END
        || CASE WHEN t->'woche'->>'follower_zuwachs' IS NOT NULL THEN ', Follower ' || public.talents_vorzeichen_text((t->'woche'->>'follower_zuwachs')::numeric) ELSE '' END
        || ', ' || coalesce(t->'woche'->>'beitraege', '0') || CASE WHEN (t->'woche'->>'beitraege') = '1' THEN ' Beitrag' ELSE ' Beiträge' END END);
  END LOOP;
  IF jsonb_array_length(daten) > 10 THEN zeilen := zeilen || jsonb_build_object('t', 'und ' || (jsonb_array_length(daten) - 10) || ' weitere Talents'); END IF;
  RETURN jsonb_build_object('titel', 'Zahlen der Talents (' || (z->>'text') || ', verglichen mit ' || (z->>'vergleich_text') || ')',
    'zeilen', zeilen, 'leer', 'Keine Talents',
    'daten', (SELECT coalesce(jsonb_agg(x), '[]'::jsonb) FROM jsonb_array_elements(daten) WITH ORDINALITY y(x, k) WHERE y.k <= 10),
    'kopf', jsonb_build_object('zeitraum', z,
      'talents', (SELECT coalesce(jsonb_agg(jsonb_build_object('id', (x->>'talent_id')::integer, 'name', x->>'name',
          'zahlen', coalesce((x->'woche'->>'tage_mit_zahlen')::integer, 0) > 0) ORDER BY x->>'name' COLLATE "C"), '[]'::jsonb) FROM jsonb_array_elements(daten) x),
      'stand_zahlen', (SELECT max(k.letzter_abruf) FROM public.talent_kanaele k WHERE k.talent_id = ANY (ids))));
END $function$;
CREATE OR REPLACE FUNCTION public.briefing_bs_talents_ki(p_person text, p_optionen jsonb, p_heute date)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE d jsonb; m text := public.ki_modell('einfach'); tal boolean := public.ally_person_ist_talent(p_person);
BEGIN
  -- Migration 208 (Briefing), Baustein „KI-Einordnung“ (Social-Media-Paket, einziger Baustein mit KI-Kosten): Anfrage an die KI zu denselben Talents und demselben
  -- Zeitraum wie „Zahlen der Talents“ (Optionen von dort, briefing_faellig gibt sie mit), Regeln und Format wie die KI-Analyse (Migration 180).
  -- ki = NULL ohne Talents, bei gesperrter KI oder ohne Modell (dann schreibt briefing_bs_talents_ki_fertig „nicht verfügbar“).
  -- Ein Talent als Empfänger (Prüfung N7): die Daten ohne interne Hinweise der Agentur (Warnungen, Abweichung vom Konzept, Überarbeitungsvorschlag, Kampagnen),
  -- die KI schreibt das Talent direkt an und nennt nur seine eigenen Zahlen.
  d := public.briefing_bs_talents_zahlen(p_person, p_optionen, p_heute);
  IF jsonb_array_length(coalesce(d->'daten', '[]'::jsonb)) = 0 THEN RETURN jsonb_build_object('daten', '[]'::jsonb, 'ki', NULL, 'leer', 'Keine Talents'); END IF;
  IF tal THEN
    d := jsonb_set(d, '{daten}', (SELECT coalesce(jsonb_agg(y - 'warnungen' - 'ueberarbeitung_bereit' - 'ziele_abweichend' - 'kampagnen'), '[]'::jsonb) FROM jsonb_array_elements(d->'daten') y));
  END IF;
  RETURN jsonb_build_object('daten', d->'daten', 'kopf', d->'kopf',
    'ki', CASE WHEN NOT public.ki_gesperrt() AND m IS NOT NULL THEN jsonb_build_object('modell', m,
      'system', CASE WHEN tal THEN 'Du schreibst für ein Talent (Creator) eine kurze Einordnung seiner eigenen Zahlen (' || (d->'kopf'->'zeitraum'->>'name') || ', verglichen mit dem Zeitraum davor). '
        || 'Sprich das Talent mit du an. Nenne nur Werte aus den DATEN. Keine internen Hinweise der Agentur: nichts über Verträge, Vergütung, Konzepte, Kampagnenziele, Bewertungen oder andere Talents.'
        || E'\n\nAufgabe:\n- "auffaellig": höchstens 4 Punkte, was sich im Zeitraum bewegt hat (nur mit Werten aus den DATEN).\n'
        || E'- "kuemmern": höchstens 3 freundliche, konkrete Anregungen für die nächsten Beiträge.\n'
        || E'- Jeder Punkt ist ein Satz mit höchstens 25 Wörtern.\n'
        || 'Format: {"auffaellig":["…"],"kuemmern":["…"]}'
      ELSE 'Du schreibst für eine Person in einer Agentur eine Einordnung der Zahlen ihrer Talents (' || (d->'kopf'->'zeitraum'->>'name') || ', verglichen mit dem Zeitraum davor). '
        || public.talents_ki_regeln()
        || E'\n\nAufgabe:\n- "auffaellig": höchstens 4 Punkte, was sich im Zeitraum bewegt hat oder auffällt (nur mit Werten aus den DATEN).\n'
        || E'- "kuemmern": höchstens 3 konkrete Punkte, worum sich die Person als Nächstes kümmern sollte.\n'
        || E'- Jeder Punkt ist ein Satz mit höchstens 25 Wörtern und beginnt mit dem Namen des Talents.\n'
        || 'Format: {"auffaellig":["…"],"kuemmern":["…"]}' END,
      'nachricht', 'DATEN (Zeitraum ' || (d->'kopf'->'zeitraum'->>'text') || ', Vergleich mit ' || (d->'kopf'->'zeitraum'->>'vergleich_text')
        || '; „woche“ = Zahlen im Zeitraum, „vorwoche“ = Zahlen im Vergleichszeitraum): ' || (d->'daten')::text) END);
END $function$;
CREATE OR REPLACE FUNCTION public.briefing_bs_talents_ki_fertig(p_ki_text text, p_daten jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE j jsonb := public.talents_ki_json(coalesce(p_ki_text, '')); t jsonb; x text; auff jsonb := '[]'::jsonb; kuem jsonb := '[]'::jsonb; ok boolean;
  D jsonb := CASE WHEN jsonb_typeof(p_daten) = 'array' THEN p_daten ELSE '[]'::jsonb END;
BEGIN
  -- Migration 208 (Briefing): Text der KI-Einordnung wie talents_briefing_text (Migration 180): KI-Punkte nur ohne fremde Zahlen; Warnungen und Abweichungen vom
  -- Konzept immer unter „Worum du dich kümmern solltest“; ohne KI der Hinweis, dass die Einordnung fehlt.
  ok := j IS NOT NULL;
  IF ok THEN
    FOR x IN SELECT jsonb_array_elements_text(CASE WHEN jsonb_typeof(j->'auffaellig') = 'array' THEN j->'auffaellig' ELSE '[]'::jsonb END) LIMIT 4 LOOP
      IF public.talents_ki_kurz(x, 300) IS NOT NULL AND jsonb_array_length(public.talents_ki_zahlen_pruefen(x, D)) = 0 THEN auff := auff || jsonb_build_object('t', public.talents_ki_kurz(x, 300)); END IF;
    END LOOP;
    FOR x IN SELECT jsonb_array_elements_text(CASE WHEN jsonb_typeof(j->'kuemmern') = 'array' THEN j->'kuemmern' ELSE '[]'::jsonb END) LIMIT 3 LOOP
      IF public.talents_ki_kurz(x, 300) IS NOT NULL AND jsonb_array_length(public.talents_ki_zahlen_pruefen(x, D)) = 0 THEN kuem := kuem || jsonb_build_object('t', public.talents_ki_kurz(x, 300)); END IF;
    END LOOP;
  END IF;
  FOR t IN SELECT y FROM jsonb_array_elements(D) y LOOP
    FOR x IN SELECT jsonb_array_elements_text(coalesce(t->'warnungen', '[]'::jsonb)) LOOP kuem := kuem || jsonb_build_object('t', (t->>'name') || ': ' || x); END LOOP;
    IF coalesce((t->>'ueberarbeitung_bereit')::boolean, false) THEN
      kuem := kuem || jsonb_build_object('t', (t->>'name') || ': Die Zahlen weichen deutlich vom Konzept ab. Ein Überarbeitungsvorschlag liegt vor.');
    ELSIF jsonb_array_length(coalesce(t->'ziele_abweichend', '[]'::jsonb)) > 0 THEN
      kuem := kuem || jsonb_build_object('t', (t->>'name') || ': Die Zahlen weichen deutlich vom Konzept ab (' || (t->'ziele_abweichend'->0->>'ziel') || ' ' || (t->'ziele_abweichend'->0->>'stand') || ').');
    END IF;
  END LOOP;
  IF jsonb_array_length(auff) = 0 THEN auff := jsonb_build_array(jsonb_build_object('t', CASE WHEN ok THEN 'Nichts Besonderes.' ELSE 'Die Einordnung durch die KI ist diesmal nicht verfügbar.' END)); END IF;
  IF jsonb_array_length(kuem) = 0 THEN kuem := jsonb_build_array(jsonb_build_object('t', 'Nichts Dringendes.')); END IF;
  RETURN jsonb_build_object('ki', ok, 'abschnitte', jsonb_build_array(jsonb_build_object('titel', 'Was auffällt', 'zeilen', auff),
    jsonb_build_object('titel', 'Worum du dich kümmern solltest', 'zeilen', kuem)));
END $function$;
CREATE OR REPLACE FUNCTION public.briefing_bs_talents_aufgaben(p_person text, p_optionen jsonb, p_heute date)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE e jsonb; z jsonb := '[]'::jsonb; tid integer;
BEGIN
  -- Migration 208 (Briefing), Baustein „Offene Aufgaben und Termine der Talents“ (Social-Media-Paket): offene Aufgaben, Reviews, Termine und Erinnerungen
  -- (überfällig bis 30 Tage zurück und die nächsten 7 Tage) und Deadlines der Deliverables der nächsten 7 Tage aus der Kalenderquelle des Pakets
  -- (talents_kalender_eintraege, Migration 205; dieselben Regeln wie im Kalender). Ein Talent als Empfänger: eigene offene Einträge, die im Talent-Bereich stehen.
  -- Vorerst bis zum künftigen „Planer“.
  IF public.ally_person_ist_talent(p_person) THEN
    SELECT p.talent_id INTO tid FROM public.ally_personen p WHERE p.matrix_user_id = p_person AND p.aktiv;
    IF tid IS NULL OR NOT (coalesce(public.ally_hat_recht(p_person, 'talent_aufgaben'), false) OR coalesce(public.ally_hat_recht(p_person, 'talent_termine'), false)) THEN
      RETURN jsonb_build_object('zeilen', '[]'::jsonb, 'leer', 'Keine offenen Aufgaben');
    END IF;
    SELECT coalesce(jsonb_agg(jsonb_build_object('t', to_char(coalesce(a.beginn, a.faellig_am) AT TIME ZONE 'Europe/Berlin', 'DD.MM.')
        || CASE WHEN (coalesce(a.beginn, a.faellig_am) AT TIME ZONE 'Europe/Berlin')::date < p_heute THEN ' (überfällig)' ELSE '' END
        || ' · ' || CASE a.art WHEN 'termin' THEN 'Termin' WHEN 'review' THEN 'Review' WHEN 'erinnerung' THEN 'Erinnerung' ELSE 'Aufgabe' END || ' · ' || a.titel)
        ORDER BY coalesce(a.beginn, a.faellig_am), a.id), '[]'::jsonb) INTO z
    FROM (SELECT * FROM public.talent_aufgaben a0 WHERE a0.talent_id = tid AND a0.status = 'offen' AND 'bereich' = ANY (a0.kanaele)
          AND coalesce(a0.beginn, a0.faellig_am) IS NOT NULL
          AND (coalesce(a0.beginn, a0.faellig_am) AT TIME ZONE 'Europe/Berlin')::date BETWEEN p_heute - 30 AND p_heute + 7
          ORDER BY coalesce(a0.beginn, a0.faellig_am), a0.id LIMIT 30) a;
    RETURN jsonb_build_object('zeilen', z, 'leer', 'Keine offenen Aufgaben');
  END IF;
  FOR e IN SELECT y FROM jsonb_array_elements(public.talents_kalender_eintraege(p_person, p_heute - 30, p_heute + 7, false)) y
           WHERE (y->>'id' ~ '^a-' AND y->>'status_text' = 'Offen') OR (y->>'id' ~ '^d-' AND (y->>'tag')::date >= p_heute AND coalesce(y->>'status_text', '') NOT IN ('veröffentlicht', 'abgerechnet'))
           ORDER BY y->>'tag' COLLATE "C", coalesce(y->>'von', '') COLLATE "C", y->>'id' COLLATE "C" LIMIT 30 LOOP
    z := z || jsonb_build_object('t', to_char((e->>'tag')::date, 'DD.MM.') || CASE WHEN (e->>'tag')::date < p_heute THEN ' (überfällig)' ELSE '' END
      || ' · ' || coalesce(e->>'art_text', '') || ' · ' || coalesce(e->>'titel', '') || coalesce(' · ' || nullif(e->>'kontext', ''), ''));
  END LOOP;
  RETURN jsonb_build_object('zeilen', z, 'leer', 'Keine offenen Aufgaben');
END $function$;
CREATE OR REPLACE FUNCTION public.briefing_mail_standard()
 RETURNS jsonb
 LANGUAGE sql
 IMMUTABLE
AS $function$
  -- Migration 208 (Briefing): Standard für Betreff und Text der Mail (gilt, solange kein eigener Text gespeichert ist); das Briefing steht unter dem Text,
  -- danach Signatur und KI-Hinweis (wie bei den KI-Analysen, Migration 180). Platzhalter: briefing_mail_platzhalter.
  SELECT jsonb_build_object('betreff', 'Briefing „{Titel}“ vom {Datum}', 'html', '<p>Hallo,</p><p>hier ist dein Briefing „{Titel}“ vom {Datum}.</p>')
$function$;
CREATE OR REPLACE FUNCTION public.briefing_mail_platzhalter()
 RETURNS jsonb
 LANGUAGE sql
 IMMUTABLE
AS $function$
  -- Migration 208 (Briefing): Platzhalter für Betreff und Text der Mail (Zeitraum und Kalenderwoche wie bei den KI-Analysen, damit übernommene Texte gleich bleiben)
  SELECT '[{"k": "Titel", "info": "Name des Briefings"}, {"k": "Datum", "info": "Tag, an dem das Briefing entsteht"},
           {"k": "Zeitraum", "info": "Zeitraum der Zahlen der Talents (leer ohne Zahlen)"}, {"k": "Kalenderwoche", "info": "Kalenderwoche, in der das Briefing entsteht"}]'::jsonb
$function$;
CREATE OR REPLACE FUNCTION public.briefing_mail_normal(p_wert text, p_art text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
AS $function$
  -- Migration 208 (Briefing): Betreff bzw. Text zum Speichern; leer oder gleich dem Standard = NULL (dann gilt weiter der Standard)
  SELECT CASE WHEN w = '' OR w = public.briefing_mail_standard()->>p_art THEN NULL ELSE w END
  FROM (SELECT CASE WHEN p_art = 'betreff' THEN btrim(regexp_replace(coalesce(p_wert, ''), '[\r\n\t]+', ' ', 'g')) ELSE btrim(coalesce(p_wert, '')) END AS w) q
$function$;
CREATE OR REPLACE FUNCTION public.briefing_html_text(p_html text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
AS $function$
  -- Migration 208 (Briefing): Textfassung eines HTML-Texts für die Mail (Zeilenumbrüche bei br, p, div und li; Tags weg; die üblichen Zeichen-Entitäten zurück)
  SELECT btrim(replace(replace(replace(replace(replace(replace(
    regexp_replace(regexp_replace(regexp_replace(regexp_replace(coalesce(p_html, ''), '<br\s*/?>', E'\n', 'gi'), '</(p|div|li|h[1-6])>', E'\n', 'gi'), '<[^>]*>', '', 'g'), E'\n{3,}', E'\n\n', 'g'),
    '&nbsp;', ' '), '&lt;', '<'), '&gt;', '>'), '&quot;', '"'), '&#39;', ''''), '&amp;', '&'), E' \n')
$function$;
CREATE OR REPLACE FUNCTION public.briefing_absender(p_id integer)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE b public.briefings%ROWTYPE; st jsonb := public.ally_systemnachricht_absender_stand(); pl public.postfach_plaetze%ROWTYPE; ort text;
BEGIN
  -- Migration 208 (Briefing): Absender der Mail eines Briefings wie bei den KI-Analysen (talents_briefing_absender, Migration 180/204): gewähltes Postfach (eigener Ablauf,
  -- Versand eingerichtet und erlaubt; gesendet wird über einen eingebetteten Ablauf mit seinem Versand-Zugang), ohne Wahl der Absender für Systemnachrichten.
  -- fehlt = was fehlt und wo man es einrichtet.
  SELECT * INTO b FROM public.briefings x WHERE x.id = p_id;
  IF NOT FOUND THEN RETURN jsonb_build_object('bereit', false, 'fehlt', 'Dieses Briefing gibt es nicht.'); END IF;
  IF b.absender IS NOT NULL THEN
    SELECT * INTO pl FROM public.postfach_plaetze p WHERE lower(p.adresse) = b.absender AND p.weg = 'eigen' AND p.stand = 'aktiv' AND p.empfang_workflow_id IS NOT NULL;
    ort := 'Einstellungen › ' || CASE WHEN EXISTS (SELECT 1 FROM public.ally_postfaecher x WHERE x.adresse = b.absender AND x.art = 'persoenlich') THEN 'Meine Postfächer' ELSE 'Gemeinsame Postfächer' END
           || ' › ' || b.absender || ', Abschnitt „Zugang und Versand“';
    IF pl.platz IS NULL THEN
      RETURN jsonb_build_object('bereit', false, 'gewaehlt', b.absender, 'fehlt', 'Das Postfach ' || b.absender || ' kann keine Briefings senden. Bitte ein anderes Absender-Postfach wählen.');
    ELSIF pl.versand_eingerichtet AND NOT coalesce(pl.versand_erlaubt, false) THEN
      RETURN jsonb_build_object('bereit', false, 'gewaehlt', b.absender, 'fehlt', 'Für das Postfach ' || b.absender || ' ist der Versand ausgeschaltet. Einschalten unter ' || ort || ' („Versand erlauben“).');
    ELSIF NOT coalesce(pl.versand_eingerichtet AND pl.versand_erlaubt AND pl.smtp_credential_id IS NOT NULL, false) THEN
      RETURN jsonb_build_object('bereit', false, 'gewaehlt', b.absender, 'fehlt', 'Das Postfach ' || b.absender || ' kann noch nicht senden. Einrichten unter ' || ort || '.');
    END IF;
    RETURN jsonb_build_object('bereit', true, 'weg', 'eigen', 'nr', pl.platz, 'workflow_id', pl.empfang_workflow_id, 'adresse', b.absender,
      'smtp_credential_id', CASE WHEN pl.smtp_credential_id ~ '^[A-Za-z0-9]{8,40}$' THEN pl.smtp_credential_id END,
      'name', coalesce((SELECT nullif(btrim(f.name), '') FROM public.ally_postfaecher f WHERE f.adresse = b.absender), b.absender));
  END IF;
  IF coalesce((st->>'aktiv')::boolean, false) THEN
    RETURN jsonb_build_object('bereit', true, 'weg', 'system', 'adresse', lower(st->>'adresse'));
  END IF;
  RETURN jsonb_build_object('bereit', false, 'fehlt', 'Es ist kein Absender-Postfach gewählt und kein Absender für Systemnachrichten eingerichtet. Wählen in der Kachel „Zustellung“.');
END $function$;
CREATE OR REPLACE FUNCTION public.briefing_mail_bauen(p_id integer, p_person text, p_an text, p_wer text, p_html text, p_text text, p_werte jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
  b public.briefings%ROWTYPE; a jsonb; std jsonb := public.briefing_mail_standard(); tb text; th text; k text; v text; sh text; st text; nm text; test boolean;
BEGIN
  -- Migration 208 (Briefing, Stefan 06.11.2026 „je Briefing einstellbar“): fertige Mail wie bei den KI-Analysen (Migration 180): Betreff und Text (eigener oder Standard,
  -- Platzhalter eingesetzt, im HTML maskiert), darunter das Briefing des Empfängers, Signatur (eigene des Briefings, sonst die des Absender-Postfachs; {Name} =
  -- „Name in der Signatur“ bzw. Vorname von p_wer), KI-Hinweis. Absender aus briefing_absender (Postfach mit Versand-Zugang oder Absender für Systemnachrichten).
  -- senden = es geht eine Mail raus; test = Testdaten (nichts versendet). Ohne Adresse oder Absender: senden = false mit grund.
  SELECT * INTO b FROM public.briefings x WHERE x.id = p_id;
  IF NOT FOUND THEN RETURN jsonb_build_object('senden', false, 'gewaehlt', true, 'grund', 'Briefing fehlt'); END IF;
  IF coalesce(p_an, '') = '' THEN RETURN jsonb_build_object('senden', false, 'gewaehlt', true, 'grund', 'keine Mail-Adresse'); END IF;
  a := public.briefing_absender(b.id);
  IF NOT coalesce((a->>'bereit')::boolean, false) THEN RETURN jsonb_build_object('senden', false, 'gewaehlt', true, 'an', p_an, 'grund', a->>'fehlt'); END IF;
  -- Testmodus (Prüfung M2): Empfänger oder Besitzerin ist Test-Person oder das Briefing trägt das Kennzeichen testdaten (aus der KI-Analyse übernommen)
  test := public.ally_person_ist_testdaten(p_person) OR b.testdaten OR public.ally_person_ist_testdaten(b.person);
  nm := coalesce(nullif(btrim(public.ally_nutzer_wert(p_wer, 'signatur_name')), ''),
                 (SELECT nullif(split_part(btrim(coalesce(p.name, '')), ' ', 1), '') FROM public.ally_personen p WHERE p.matrix_user_id = p_wer), '');
  tb := coalesce(nullif(btrim(b.mail_betreff), ''), std->>'betreff');
  th := coalesce(nullif(btrim(b.mail_html), ''), std->>'html');
  FOR k IN SELECT x->>'k' FROM jsonb_array_elements(public.briefing_mail_platzhalter()) x LOOP
    v := coalesce(p_werte->>k, '');
    tb := replace(tb, '{' || k || '}', v);
    th := replace(th, '{' || k || '}', public.ally_html(v));
  END LOOP;
  tb := left(btrim(regexp_replace(tb, '[\r\n\t]+', ' ', 'g')), 200);
  IF b.signatur_an AND nullif(btrim(coalesce(b.signatur_html, '')), '') IS NOT NULL THEN
    sh := replace(btrim(b.signatur_html), '{Name}', public.ally_html(nm)); st := NULL;
  ELSIF b.signatur_an THEN
    SELECT nullif(btrim(p.signatur_html), ''), nullif(btrim(p.signatur_text), '') INTO sh, st FROM public.ally_postfaecher p WHERE lower(p.adresse) = lower(btrim(a->>'adresse')) LIMIT 1;
    sh := replace(sh, '{Name}', public.ally_html(nm)); st := replace(st, '{Name}', nm);
  END IF;
  RETURN jsonb_build_object('senden', NOT test, 'test', test, 'gewaehlt', true, 'an', p_an, 'von', a->>'adresse', 'weg', a->>'weg', 'betreff', tb,
    'nr', CASE WHEN a->>'weg' = 'eigen' THEN (a->>'nr')::integer END, 'workflow_id', a->>'workflow_id', 'smtp_credential_id', a->>'smtp_credential_id',
    'html', '<div style="font-family:Helvetica,Arial,sans-serif;font-size:14px;line-height:1.5;color:#1F2933">' || th
            || '<div style="margin-top:12px">' || coalesce(p_html, '') || '</div>'
            || CASE WHEN sh IS NOT NULL THEN '<div style="margin-top:16px">' || sh || '</div>' ELSE '' END
            || CASE WHEN b.ki_hinweis THEN '<p style="margin:16px 0 0">Erstellt mit KI-Unterstützung.</p>' ELSE '' END || '</div>',
    'text', public.briefing_html_text(th) || E'\n\n' || coalesce(p_text, '')
            || CASE WHEN sh IS NOT NULL OR st IS NOT NULL THEN E'\n\n' || coalesce(st, public.briefing_html_text(sh)) ELSE '' END
            || CASE WHEN b.ki_hinweis THEN E'\n\nErstellt mit KI-Unterstützung.' ELSE '' END);
END $function$;
CREATE OR REPLACE FUNCTION public.briefing_faellig(p_test boolean DEFAULT false, p_nur text DEFAULT ''::text)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
  heute date := (now() AT TIME ZONE 'Europe/Berlin')::date;
  jetzt time := (now() AT TIME ZONE 'Europe/Berlin')::time;
  nur text := btrim(coalesce(p_nur, ''));
  nur_u text := split_part(btrim(coalesce(p_nur, '')), '#', 1);
  nur_b integer := CASE WHEN btrim(coalesce(p_nur, '')) ~ '#[0-9]{1,9}$' THEN substring(btrim(p_nur) from '#([0-9]{1,9})$')::integer END;
  chat_sm boolean := btrim(coalesce(p_nur, '')) ~ '#chat$';
  plan boolean := NOT coalesce(p_test, false) AND btrim(coalesce(p_nur, '')) = '';
  br record; e record; i record; x jsonb; bs jsonb; auftraege jsonb := '[]'::jsonb; a jsonb; per text; opt jsonb;
  ki jsonb; kib text; kopf jsonb; abl jsonb; kal text; room text; adr text; sys_ok boolean := coalesce((public.ally_systemnachricht_absender_stand()->>'aktiv')::boolean, false);
  jetzt_auftraege text[] := '{}'; n integer := 0; zp boolean; zp_e boolean; jh boolean; geholt integer; ohne_google boolean;
BEGIN
  -- Migration 208 (Briefing, Stefan 06.11.2026): Aufträge für ALLY 4 „Briefing ausführen“ – je Briefing und Empfänger ein Auftrag mit den Daten der Bausteine
  -- (briefing_bausteine; nur Bausteine, deren Paket an ist und für die die Person, der das Briefing gehört, und der jeweilige Empfänger das Recht haben – Prüfung M3),
  -- der Anfrage an die KI (nur Baustein mit art ki), den Unterabläufen (art ablauf), der Kennung des Google-Kalenders (Baustein mit google) und der Zustellung.
  --   p_test = Testlauf: alle eingeschalteten Briefings mit Zeitplan, ohne Zeitprüfung (ALLY 4 sendet und merkt nichts). Ohne KI-Anfrage und ohne Google-Kalender
  --     (Prüfung N5: keine KI-Kosten, keine Abrufe); das Ergebnis sagt das.
  -- Überschneidende Läufe (Prüfung N6): nach Zeitplan vergibt briefing_faellig je Briefing, Empfänger und Zeitraum den Lauf (briefing_laeufe status laeuft), bevor ALLY 4
  --   ihn erstellt; ein zweiter Lauf nimmt ihn nicht noch einmal. Nach 30 Minuten ohne Abschluss gilt er als abgebrochen (zählt als Versuch).
  --   p_nur = '' (Zeitplan, alle 15 Minuten): fällig ab der Uhrzeit am passenden Tag, einmal je Zeitraum (briefing_laeufe); nach einem Fehlversuch beim nächsten Lauf
  --     wieder, höchstens 3 Versuche je Zeitraum. Dazu Aufträge „Briefing jetzt“ aus dem Chat (briefing_jetzt). Standard-Briefings legt der Lauf bei Bedarf an.
  --   p_nur = Person#Nummer („Jetzt erstellen“ auf der Seite): dieses Briefing nur für diese Person; Chat, Glocke und Mail nur, wenn sie es bekommt und es so eingestellt ist.
  --   p_nur = Person#chat (Chat-Werkzeug „KI-Analyse jetzt“, früher TALENTS Wochen-Briefing): ihre Briefings mit Bausteinen des Social-Media-Pakets, nur auf der Seite,
  --     höchstens einmal in 3 Minuten. p_nur = Person: ihr Standard-Briefing (sonst ihr einziges) wie eingestellt.
  -- Test-Personen bekommen nach Zeitplan nichts (Testdaten lösen keine Briefings aus); „Jetzt erstellen“ für sie nur auf der Seite.
  IF nur = '-' THEN RETURN jsonb_build_object('ok', true, 'auftraege', '[]'::jsonb, 'antwort', ''); END IF;
  IF plan THEN
    PERFORM public.briefing_standard_anlegen(p.matrix_user_id) FROM public.ally_personen p
    WHERE p.aktiv AND NOT p.testdaten AND NOT EXISTS (SELECT 1 FROM public.ally_nutzer_einstellungen s WHERE s.matrix_user_id = p.matrix_user_id AND s.schluessel = 'briefing_standard');
    -- Aufträge aus dem Chat: einmal mitnehmen (nicht nach Zeitplan) und entfernen
    WITH w AS (DELETE FROM public.briefing_jetzt j WHERE j.angefordert_am > now() - interval '1 day' RETURNING j.briefing_id, j.person) SELECT coalesce(array_agg(w.briefing_id || ':' || w.person), '{}') INTO jetzt_auftraege FROM w;
    DELETE FROM public.briefing_jetzt;
  END IF;
  FOR br IN SELECT b.* FROM public.briefings b
            WHERE b.geloescht_am IS NULL
              AND CASE WHEN p_test THEN b.an AND b.rhythmus <> 'hand'
                       WHEN nur_b IS NOT NULL THEN b.id = nur_b
                       WHEN chat_sm THEN EXISTS (SELECT 1 FROM public.briefing_inhalte bi JOIN public.briefing_bausteine bz ON bz.schluessel = bi.baustein AND bz.modul = 'talents'
                                                 WHERE bi.briefing_id = b.id)
                       WHEN nur <> '' THEN b.person = nur_u AND (b.standard OR NOT EXISTS (SELECT 1 FROM public.briefings b2 WHERE b2.person = nur_u AND b2.standard AND b2.geloescht_am IS NULL))
                       ELSE (b.an AND b.rhythmus <> 'hand' AND jetzt >= b.uhrzeit::time
                             AND CASE b.rhythmus WHEN 'tag' THEN true WHEN 'woche' THEN extract(isodow FROM heute)::integer = b.tag ELSE extract(day FROM heute)::integer = b.tag END)
                            OR EXISTS (SELECT 1 FROM unnest(jetzt_auftraege) j WHERE split_part(j, ':', 1) = b.id::text) END
            ORDER BY b.id LOOP
    CONTINUE WHEN NOT p_test AND public.ally_person_ist_testdaten(br.person) AND nur = '';
    per := public.briefing_periode(br.rhythmus, heute);
    -- nach Zeitplan fällig (Tag und Uhrzeit erreicht) oder nur als Auftrag aus dem Chat
    zp := plan AND br.an AND br.rhythmus <> 'hand' AND jetzt >= br.uhrzeit::time
          AND CASE br.rhythmus WHEN 'tag' THEN true WHEN 'woche' THEN extract(isodow FROM heute)::integer = br.tag ELSE extract(day FROM heute)::integer = br.tag END;
    FOR e IN SELECT q.person, q.eigen, true AS empf FROM public.briefing_empfaenger(br.id) q
             WHERE (nur = '' OR q.person = nur_u) AND NOT (chat_sm AND q.person IS DISTINCT FROM nur_u)
             UNION ALL
             -- „Jetzt erstellen“ einer Person, die das Briefing sieht, ohne es zu bekommen (geteilt): nur auf der Seite
             SELECT nur_u, false, false WHERE nur <> '' AND (nur_b IS NOT NULL OR chat_sm)
               AND NOT EXISTS (SELECT 1 FROM public.briefing_empfaenger(br.id) q2 WHERE q2.person = nur_u) AND public.briefing_sichtbar(nur_u, br.id)
             ORDER BY 1 LOOP
      -- nach Zeitplan: einmal je Zeitraum; nach Fehlversuchen höchstens 3 Versuche (auch wenn ein Lauf abbrach, bevor er sich merken konnte)
      IF plan THEN
        CONTINUE WHEN public.ally_person_ist_testdaten(e.person);
        jh := (br.id || ':' || e.person) = ANY (jetzt_auftraege);
        IF zp AND (EXISTS (SELECT 1 FROM public.briefing_laeufe l WHERE l.briefing_id = br.id AND l.person = e.person AND l.periode = per
                           AND (l.status = 'ok' OR l.versuche >= 3 OR (l.status = 'laeuft' AND l.geaendert_am > now() - interval '30 minutes')))
                   OR EXISTS (SELECT 1 FROM public.briefing_ergebnisse r WHERE r.briefing_id = br.id AND r.person = e.person AND r.nach_zeitplan AND r.periode = per AND r.versuche >= 3)) THEN
          zp_e := false;
        ELSE
          zp_e := zp;
        END IF;
        CONTINUE WHEN NOT zp_e AND NOT jh;
      ELSE
        zp_e := false;
      END IF;
      CONTINUE WHEN chat_sm AND EXISTS (SELECT 1 FROM public.briefing_ergebnisse r WHERE r.briefing_id = br.id AND r.person = e.person AND r.erstellt_von = e.person
                                        AND r.erstellt_am > now() - interval '3 minutes');
      bs := '[]'::jsonb; ki := NULL; kib := NULL; kopf := NULL; abl := '[]'::jsonb; kal := NULL; ohne_google := false;
      -- Bausteine: Paket an, Recht bei der Person, der das Briefing gehört, und beim Empfänger (sonst fehlt der Baustein für diesen Empfänger)
      FOR i IN SELECT x0.*, bi.optionen AS gewaehlt FROM public.briefing_inhalte bi JOIN public.briefing_bausteine_fuer(br.person) x0 ON x0.schluessel = bi.baustein
               WHERE bi.briefing_id = br.id AND EXISTS (SELECT 1 FROM public.briefing_bausteine_fuer(e.person) y0 WHERE y0.schluessel = bi.baustein)
               ORDER BY x0.reihenfolge, x0.schluessel COLLATE "C" LOOP
        -- Optionen: die des Bausteins, ergänzt um die der übrigen Bausteine desselben Pakets (KI-Einordnung nimmt Talents und Zeitraum von „Zahlen der Talents“)
        opt := coalesce((SELECT jsonb_object_agg(k, v) FROM public.briefing_inhalte b3 JOIN public.briefing_bausteine x3 ON x3.schluessel = b3.baustein
                         CROSS JOIN LATERAL jsonb_each(b3.optionen) o(k, v)
                         WHERE b3.briefing_id = br.id AND x3.modul IS NOT DISTINCT FROM i.modul AND x3.schluessel <> i.schluessel), '{}'::jsonb) || i.gewaehlt;
        -- Kreis „alle“ der Manager/innen: Admins (Rückfall) bekommen wie bisher auch die Talents ohne zuständige Person
        IF br.manager AND br.manager_kreis = 'alle' AND e.empf AND coalesce(public.ally_hat_recht(e.person, 'admin'), false) AND NOT public.ally_person_ist_talent(e.person)
           AND cardinality(public.briefing_talents_waise()) > 0 THEN
          opt := opt || jsonb_build_object('talents', (SELECT coalesce(jsonb_agg(DISTINCT q.tw ORDER BY q.tw), '[]'::jsonb) FROM (
            SELECT jsonb_array_elements_text(CASE WHEN jsonb_typeof(opt->'talents') = 'array' THEN opt->'talents' ELSE '[]'::jsonb END) AS tw
            UNION SELECT w0::text FROM unnest(public.briefing_talents_waise()) w0) q));
        END IF;
        IF i.art = 'ablauf' THEN
          abl := abl || jsonb_build_object('schluessel', i.schluessel, 'workflow_id', i.ablauf, 'optionen', opt::text);
          bs := bs || jsonb_build_object('schluessel', i.schluessel, 'name', i.name, 'art', 'ablauf', 'persoenlich', i.persoenlich);
          CONTINUE;
        END IF;
        BEGIN
          IF to_regprocedure(format('public.%I(text,jsonb,date)', i.lesen)) IS NULL THEN RAISE EXCEPTION 'Lesefunktion des Bausteins fehlt'; END IF;
          EXECUTE format('SELECT public.%I($1, $2, $3)', i.lesen) INTO x USING e.person, opt, heute;
          IF jsonb_typeof(x) IS DISTINCT FROM 'object' THEN RAISE EXCEPTION 'Baustein liefert kein Objekt'; END IF;
        EXCEPTION WHEN OTHERS THEN
          x := jsonb_build_object('zeilen', jsonb_build_array(jsonb_build_object('t', 'Konnte gerade nicht gelesen werden.')), 'fehler', left(SQLERRM, 200));
        END;
        IF i.art = 'ki' THEN
          IF kib IS NULL THEN kib := i.schluessel; ki := CASE WHEN jsonb_typeof(x->'ki') = 'object' AND NOT coalesce(p_test, false) THEN x->'ki' END; END IF;
          x := x - 'ki';
        END IF;
        IF i.google AND coalesce(x->>'kalender_id', '') <> '' THEN
          IF coalesce(p_test, false) THEN ohne_google := true; ELSE kal := x->>'kalender_id'; END IF;
        END IF;
        IF kopf IS NULL AND jsonb_typeof(x->'kopf') = 'object' THEN kopf := x->'kopf'; END IF;
        bs := bs || (x - 'kopf' || jsonb_build_object('schluessel', i.schluessel, 'name', i.name, 'art', i.art, 'fertig', i.fertig, 'google', i.google, 'persoenlich', i.persoenlich));
      END LOOP;
      -- Prüfung M-2: ohne einen Inhalt, für den der Empfänger das Recht hat, kein Briefing (kein leeres Ergebnis, kein Chat, keine Glocke, keine Mail); nur „Jetzt erstellen“
      -- der Person selbst ergibt auf der Seite ein Ergebnis „keine Inhalte“
      CONTINUE WHEN jsonb_array_length(bs) = 0 AND NOT (nur_b IS NOT NULL AND e.person = nur_u);
      -- Lauf vergeben (ein gleichzeitiger zweiter Lauf wartet auf die Zeile und nimmt ihn danach nicht mehr)
      IF zp_e THEN
        INSERT INTO public.briefing_laeufe AS l (briefing_id, person, periode, status, versuche) VALUES (br.id, e.person, per, 'laeuft', 0)
        ON CONFLICT (briefing_id, person, periode) DO UPDATE SET status = 'laeuft', geaendert_am = now(),
          versuche = l.versuche + CASE WHEN l.status = 'laeuft' THEN 1 ELSE 0 END
        WHERE l.versuche < 3 AND (l.status = 'fehler' OR (l.status = 'laeuft' AND l.geaendert_am <= now() - interval '30 minutes'));
        GET DIAGNOSTICS geholt = ROW_COUNT;
        IF geholt = 0 THEN zp_e := false; CONTINUE WHEN NOT jh; END IF;
      END IF;
      SELECT r.room_id INTO room FROM public.matrix_direct_rooms r WHERE r.matrix_user_id = e.person AND coalesce(r.room_id, '') <> '' ORDER BY r.room_id COLLATE "C" LIMIT 1;
      adr := public.talents_briefing_mail_adresse(e.person);
      n := n + 1;
      a := jsonb_build_object('kennung', 'b' || br.id || ':' || e.person, 'briefing_id', br.id, 'name', br.name, 'person', e.person, 'user_id', e.person, 'room_id', room,
        'eigen', e.eigen, 'empfaenger', e.empf, 'test', coalesce(p_test, false), 'ohne_google', ohne_google,
        'nach_zeitplan', zp_e, 'periode', CASE WHEN zp_e THEN per END,
        'ausloeser', CASE WHEN nur <> '' THEN nur_u WHEN NOT zp_e THEN e.person END,
        'kalender_id', kal, 'bausteine', bs, 'ki', ki, 'ki_baustein', kib, 'ablauf', abl, 'kopf', kopf,
        'inhalte', (SELECT coalesce(jsonb_agg(y->>'schluessel'), '[]'::jsonb) FROM jsonb_array_elements(bs) y),
        -- Zustellung: immer auf der Seite; Chat, Glocke, Mail nur für Empfänger, wie eingestellt und soweit möglich (Chat mit Direktraum, Mail mit Adresse und
        -- eingerichtetem Absender für Systemnachrichten); Chat-Werkzeug „KI-Analyse jetzt“ nur auf der Seite
        'kanaele', jsonb_build_object('chat', e.empf AND NOT chat_sm AND br.chat AND jsonb_array_length(bs) > 0, 'chat_moeglich', room IS NOT NULL,
          'glocke', e.empf AND NOT chat_sm AND br.glocke AND jsonb_array_length(bs) > 0,
          'mail', e.empf AND NOT chat_sm AND br.mail AND jsonb_array_length(bs) > 0, 'mail_an', adr, 'mail_absender', sys_ok));
      auftraege := auftraege || a;
    END LOOP;
  END LOOP;
  RETURN jsonb_build_object('ok', true, 'auftraege', auftraege,
    'antwort', CASE WHEN nur = '' THEN '' WHEN n = 0 THEN 'Kein Briefing erstellt.' WHEN n = 1 THEN '1 Briefing wird erstellt. Es steht danach in Ally auf der Seite Briefing.'
                    ELSE n || ' Briefings werden erstellt. Sie stehen danach in Ally auf der Seite Briefing.' END);
END $function$;
CREATE OR REPLACE FUNCTION public.briefing_ergebnis_bauen(p_auftrag jsonb, p_google jsonb, p_ki_text text, p_ablauf jsonb, p_test boolean)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
  A jsonb := CASE WHEN jsonb_typeof(p_auftrag) = 'object' THEN p_auftrag ELSE '{}'::jsonb END;
  G jsonb := CASE WHEN jsonb_typeof(p_google) = 'object' THEN p_google ELSE '{}'::jsonb END;
  ABL jsonb := CASE WHEN jsonb_typeof(p_ablauf) = 'array' THEN p_ablauf ELSE '[]'::jsonb END;
  K jsonb := CASE WHEN jsonb_typeof(A->'kanaele') = 'object' THEN A->'kanaele' ELSE '{}'::jsonb END;
  b public.briefings%ROWTYPE; x jsonb; ab jsonb := '[]'::jsonb; nichts text[] := '{}'; z jsonb; f jsonb; s jsonb; y jsonb;
  txt text; html text; esc_t text; ki_ok boolean; rid bigint; alt jsonb := '{}'::jsonb; test boolean := coalesce(p_test, false);
  heute date := (now() AT TIME ZONE 'Europe/Berlin')::date; wer text := A->>'person'; tl text; m jsonb := jsonb_build_object('senden', false);
BEGIN
  -- Migration 208 (Briefing): Text und HTML eines Auftrags aus briefing_faellig (Bausteine in ihrer Reihenfolge; Termine mit dem Google-Kalender aus ALLY 4
  -- p_google = { eintraege: [{sort, t}], fehler }; KI-Einordnung aus p_ki_text; Bausteine aus Unterabläufen aus p_ablauf = [{schluessel, zeilen, fehler}]).
  -- Leere Bausteine stehen gesammelt unter „Sonst nichts offen“ (wie im Morgen-Briefing). Speichert das Ergebnis (immer auf der Seite lesbar), außer im Testlauf;
  -- nach Zeitplan einmal je Zeitraum (ein zweiter Versuch ersetzt Text und HTML). Liefert, was ALLY 4 danach zustellt: Chat, Mail (fertig gebaut), Glocke
  -- (legt briefing_abschluss an). Bei einem zweiten Versuch nur die Wege, die beim ersten nicht geklappt haben.
  SELECT * INTO b FROM public.briefings x0 WHERE x0.id = CASE WHEN coalesce(A->>'briefing_id', '') ~ '^[0-9]{1,9}$' THEN (A->>'briefing_id')::integer END;
  IF NOT FOUND OR coalesce(wer, '') = '' THEN RETURN jsonb_build_object('ok', false, 'fehler', 'Briefing oder Person fehlt.'); END IF;
  FOR x IN SELECT y0 FROM jsonb_array_elements(CASE WHEN jsonb_typeof(A->'bausteine') = 'array' THEN A->'bausteine' ELSE '[]'::jsonb END) y0 LOOP
    tl := coalesce(nullif(x->>'titel', ''), x->>'name', 'Inhalt');
    IF x->>'art' = 'ki' AND coalesce((A->>'test')::boolean, false) THEN
      -- Testlauf (Prüfung N5): keine Anfrage an die KI, keine Kosten
      ab := ab || jsonb_build_object('titel', tl, 'zeilen', jsonb_build_array(jsonb_build_object('t', 'Im Testlauf ohne KI-Einordnung (keine KI-Kosten).')));
      CONTINUE;
    END IF;
    IF x->>'art' = 'ki' THEN
      BEGIN
        IF to_regprocedure(format('public.%I(text,jsonb)', x->>'fertig')) IS NULL THEN RAISE EXCEPTION 'Funktion fehlt'; END IF;
        EXECUTE format('SELECT public.%I($1, $2)', x->>'fertig') INTO f USING coalesce(p_ki_text, ''), coalesce(x->'daten', '[]'::jsonb);
      EXCEPTION WHEN OTHERS THEN
        f := jsonb_build_object('ki', false, 'abschnitte', jsonb_build_array(jsonb_build_object('titel', tl, 'zeilen', jsonb_build_array(jsonb_build_object('t', 'Konnte gerade nicht erstellt werden.')))));
      END;
      IF jsonb_array_length(coalesce(x->'daten', '[]'::jsonb)) = 0 THEN nichts := nichts || coalesce(x->>'leer', 'Keine Talents'); CONTINUE; END IF;
      ki_ok := coalesce((f->>'ki')::boolean, false);
      FOR s IN SELECT y0 FROM jsonb_array_elements(coalesce(f->'abschnitte', '[]'::jsonb)) y0 LOOP ab := ab || s; END LOOP;
      CONTINUE;
    END IF;
    IF x->>'art' = 'ablauf' THEN
      y := (SELECT y0 FROM jsonb_array_elements(ABL) y0 WHERE y0->>'schluessel' = x->>'schluessel' LIMIT 1);
      z := CASE WHEN y IS NULL OR coalesce(y->>'fehler', '') <> '' THEN jsonb_build_array(jsonb_build_object('t', 'Konnte gerade nicht gelesen werden.'))
                ELSE (SELECT coalesce(jsonb_agg(CASE WHEN jsonb_typeof(q) = 'object' THEN jsonb_build_object('t', left(q->>'t', 500), 'k', coalesce((q->>'k')::boolean, false))
                                                     ELSE jsonb_build_object('t', left(q #>> '{}', 500)) END), '[]'::jsonb)
                      FROM jsonb_array_elements(CASE WHEN jsonb_typeof(y->'zeilen') = 'array' THEN y->'zeilen' ELSE '[]'::jsonb END) q) END;
    ELSIF coalesce((x->>'google')::boolean, false) OR x ? 'eintraege' THEN
      -- Termine: intern und Kalenderquellen, dazu der Google-Kalender (nach Uhrzeit sortiert)
      z := (SELECT coalesce(jsonb_agg(jsonb_build_object('t', q->>'t') ORDER BY q->>'sort' COLLATE "C", q->>'t' COLLATE "C"), '[]'::jsonb)
            FROM jsonb_array_elements(coalesce(x->'eintraege', '[]'::jsonb) || CASE WHEN jsonb_typeof(G->'eintraege') = 'array' AND coalesce(A->>'kalender_id', '') <> '' THEN G->'eintraege' ELSE '[]'::jsonb END) q);
      IF coalesce(A->>'kalender_id', '') <> '' AND coalesce((G->>'fehler')::boolean, false) THEN z := z || jsonb_build_object('t', 'Der Google-Kalender war nicht abrufbar.'); END IF;
      IF coalesce((A->>'ohne_google')::boolean, false) THEN z := z || jsonb_build_object('t', 'Im Testlauf ohne Google-Kalender.'); END IF;
    ELSE
      z := CASE WHEN jsonb_typeof(x->'zeilen') = 'array' THEN x->'zeilen' ELSE '[]'::jsonb END;
    END IF;
    IF jsonb_array_length(z) = 0 THEN nichts := nichts || coalesce(nullif(x->>'leer', ''), 'Nichts zu ' || coalesce(x->>'name', 'diesem Inhalt')); CONTINUE; END IF;
    ab := ab || jsonb_build_object('titel', tl, 'zeilen', z);
  END LOOP;
  -- Prüfung M-2: ohne Inhalte (nur bei „Jetzt erstellen“ der Person selbst) steht das im Ergebnis
  IF jsonb_array_length(CASE WHEN jsonb_typeof(A->'bausteine') = 'array' THEN A->'bausteine' ELSE '[]'::jsonb END) = 0 THEN
    ab := ab || jsonb_build_object('titel', 'Keine Inhalte', 'zeilen', jsonb_build_array(jsonb_build_object('t', 'Für dich steht in diesem Briefing gerade kein Inhalt zur Verfügung.')));
  END IF;
  IF cardinality(nichts) > 0 THEN ab := ab || jsonb_build_object('titel', 'Sonst nichts offen', 'zeilen', (SELECT jsonb_agg(jsonb_build_object('t', q)) FROM unnest(nichts) q)); END IF;
  -- Aufbau wie im Morgen-Briefing: Kopf (Name des Briefings, Datum), Abschnitte mit Leerzeile dazwischen, keine Aufzählungszeichen
  esc_t := (ARRAY['Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag', 'Sonntag'])[extract(isodow FROM heute)::integer] || ', ' || to_char(heute, 'FMDD.FMMM.YYYY');
  txt := b.name || E'\n' || esc_t; html := '<strong>' || public.ally_html(b.name) || '</strong><br>' || public.ally_html(esc_t);
  FOR s IN SELECT y0 FROM jsonb_array_elements(ab) y0 LOOP
    txt := txt || E'\n\n' || (s->>'titel') || E':\n' || (SELECT string_agg(q->>'t', E'\n' ORDER BY n) FROM jsonb_array_elements(s->'zeilen') WITH ORDINALITY w(q, n));
    html := html || '<br><br><strong>' || public.ally_html(s->>'titel') || ':</strong><br>'
      || (SELECT string_agg(CASE WHEN coalesce((q->>'k')::boolean, false) THEN '<em>' || public.ally_html(q->>'t') || '</em>' ELSE public.ally_html(q->>'t') END, '<br>' ORDER BY n)
          FROM jsonb_array_elements(s->'zeilen') WITH ORDINALITY w(q, n));
  END LOOP;
  txt := left(txt, 60000); html := left(html, 120000);
  -- Mail je Briefing (Stefan 06.11.2026): Absender-Postfach oder Absender für Systemnachrichten, Betreff, Text, Signatur, KI-Hinweis (briefing_mail_bauen)
  IF coalesce((K->>'mail')::boolean, false) THEN
    m := public.briefing_mail_bauen(b.id, wer, K->>'mail_an', coalesce(nullif(A->>'ausloeser', ''), b.geaendert_von, b.person), html, txt,
      jsonb_build_object('Titel', b.name, 'Datum', to_char(heute, 'FMDD.FMMM.YYYY'), 'Zeitraum', coalesce(A->'kopf'->'zeitraum'->>'text', ''), 'Kalenderwoche', to_char(heute, 'IW')));
  END IF;
  IF test THEN
    RETURN jsonb_build_object('ok', true, 'test', true, 'ergebnis_id', NULL, 'user_id', wer, 'room_id', A->>'room_id', 'text', txt, 'html', html, 'ki', ki_ok,
      'chat', coalesce((K->>'chat')::boolean, false) AND coalesce((K->>'chat_moeglich')::boolean, false), 'mail', m, 'glocke', coalesce((K->>'glocke')::boolean, false));
  END IF;
  IF coalesce((A->>'nach_zeitplan')::boolean, false) AND coalesce(A->>'periode', '') <> '' THEN
    SELECT r.zustellung INTO alt FROM public.briefing_ergebnisse r WHERE r.briefing_id = b.id AND r.person = wer AND r.nach_zeitplan AND r.periode = A->>'periode';
    alt := coalesce(alt, '{}'::jsonb);
    INSERT INTO public.briefing_ergebnisse (briefing_id, person, erstellt_von, nach_zeitplan, periode, inhalte, zeitraum, talents, stand_zahlen, zustellung, zugestellt, ki, text, html)
    VALUES (b.id, wer, NULL, true, A->>'periode', ARRAY(SELECT jsonb_array_elements_text(coalesce(A->'inhalte', '[]'::jsonb))), A->'kopf'->'zeitraum', A->'kopf'->'talents',
      nullif(A->'kopf'->>'stand_zahlen', '')::timestamptz, '{}'::jsonb, 'wird zugestellt', ki_ok, txt, html)
    ON CONFLICT (briefing_id, person, periode) WHERE nach_zeitplan DO UPDATE SET text = EXCLUDED.text, html = EXCLUDED.html, ki = EXCLUDED.ki, talents = EXCLUDED.talents,
      zeitraum = EXCLUDED.zeitraum, stand_zahlen = EXCLUDED.stand_zahlen, versuche = public.briefing_ergebnisse.versuche + 1
    RETURNING id INTO rid;
  ELSE
    INSERT INTO public.briefing_ergebnisse (briefing_id, person, erstellt_von, nach_zeitplan, inhalte, zeitraum, talents, stand_zahlen, zustellung, zugestellt, ki, text, html)
    VALUES (b.id, wer, nullif(A->>'ausloeser', ''), false, ARRAY(SELECT jsonb_array_elements_text(coalesce(A->'inhalte', '[]'::jsonb))), A->'kopf'->'zeitraum', A->'kopf'->'talents',
      nullif(A->'kopf'->>'stand_zahlen', '')::timestamptz, '{}'::jsonb, 'wird zugestellt', ki_ok, txt, html)
    RETURNING id INTO rid;
  END IF;
  RETURN jsonb_build_object('ok', true, 'test', false, 'ergebnis_id', rid, 'user_id', wer, 'room_id', A->>'room_id', 'text', txt, 'html', html, 'ki', ki_ok,
    'nach_zeitplan', coalesce((A->>'nach_zeitplan')::boolean, false), 'periode', A->>'periode',
    'chat', coalesce((K->>'chat')::boolean, false) AND coalesce((K->>'chat_moeglich')::boolean, false) AND coalesce(alt->>'chat', '') <> 'ok',
    'chat_gewaehlt', coalesce((K->>'chat')::boolean, false),
    'mail', CASE WHEN coalesce(alt->>'mail', '') = 'ok' THEN jsonb_build_object('senden', false, 'gewaehlt', true, 'schon', true) ELSE m END,
    'glocke', coalesce((K->>'glocke')::boolean, false));
END $function$;
CREATE OR REPLACE FUNCTION public.briefing_abschluss(p_ergebnis bigint, p_e jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
  E jsonb := CASE WHEN jsonb_typeof(p_e) = 'object' THEN p_e ELSE '{}'::jsonb END;
  r public.briefing_ergebnisse%ROWTYPE; b public.briefings%ROWTYPE; zu jsonb; g jsonb; teile text[] := ARRAY['auf der Seite']; nm text; fehler boolean := false; talent boolean;
BEGIN
  -- Migration 208 (Briefing): Abschluss je Ergebnis (ALLY 4 „Abschluss“ nach Chat und Mail). Zustellung je Weg merken (ok/fehler; was einmal geklappt hat, bleibt ok),
  -- Glocke anlegen (je Ergebnis genau einmal, ref briefing:<Nummer>), „Zugestellt“ in Worten. Nach Zeitplan: Lauf des Zeitraums merken – ok, wenn kein gewählter Weg
  -- fehlgeschlagen ist; sonst Fehlversuch (ALLY 4 versucht es beim nächsten Lauf wieder, höchstens 3 Versuche je Zeitraum, wie bisher beim Morgen-Briefing).
  SELECT * INTO r FROM public.briefing_ergebnisse x WHERE x.id = p_ergebnis FOR UPDATE;
  IF NOT FOUND THEN RETURN jsonb_build_object('ok', false, 'fehler', 'Ergebnis fehlt.'); END IF;
  SELECT * INTO b FROM public.briefings x WHERE x.id = r.briefing_id;
  zu := r.zustellung;
  nm := coalesce((SELECT p.name FROM public.ally_personen p WHERE p.matrix_user_id = r.person), r.person);
  talent := public.ally_person_ist_talent(r.person);
  IF coalesce((E->'chat'->>'gewaehlt')::boolean, false) THEN
    IF coalesce((E->'chat'->>'versucht')::boolean, false) THEN
      zu := zu || jsonb_build_object('chat', CASE WHEN coalesce((E->'chat'->>'ok')::boolean, false) OR zu->>'chat' = 'ok' THEN 'ok' ELSE 'fehler' END);
      fehler := fehler OR zu->>'chat' = 'fehler';
    ELSIF coalesce(zu->>'chat', '') <> 'ok' THEN
      zu := zu || jsonb_build_object('chat', 'kein_chat');
    END IF;
  END IF;
  IF coalesce((E->'mail'->>'gewaehlt')::boolean, false) AND coalesce(zu->>'mail', '') <> 'ok' THEN
    zu := zu || jsonb_build_object('mail', CASE WHEN coalesce((E->'mail'->>'test')::boolean, false) THEN 'test'
                                                WHEN coalesce((E->'mail'->>'versucht')::boolean, false) THEN CASE WHEN coalesce((E->'mail'->>'ok')::boolean, false) THEN 'ok' ELSE 'fehler' END
                                                ELSE 'nicht_moeglich' END,
      'mail_an', E->'mail'->>'an', 'mail_grund', left(coalesce(nullif(E->'mail'->>'fehler', ''), E->'mail'->>'grund', ''), 200));
    fehler := fehler OR zu->>'mail' = 'fehler';
  END IF;
  IF coalesce((E->>'glocke')::boolean, false) AND coalesce(zu->>'glocke', '') <> 'ok' THEN
    g := public.ally_benachrichtigen(r.person, 'morgen_briefing', 'Briefing „' || b.name || '“', split_part(r.text, E'\n', 2),
      CASE WHEN talent THEN jsonb_build_object('seite', 'talent-bereich')
           ELSE jsonb_build_object('seite', 'morgen-briefing', 'parameter', jsonb_build_object('briefing', b.id::text, 'ergebnis', r.id::text)) END,
      'briefing:' || r.id, 'ALLY 4', false);
    zu := zu || jsonb_build_object('glocke', CASE WHEN coalesce((g->>'ok')::boolean, false) THEN 'ok' ELSE 'fehler' END);
  END IF;
  -- Zugestellt in Worten (Kopf des Ergebnisses, wie bei den KI-Analysen)
  IF zu ? 'chat' THEN teile := teile || CASE zu->>'chat' WHEN 'ok' THEN 'Chat an ' || nm WHEN 'kein_chat' THEN 'Chat nicht möglich (kein Chat eingerichtet)' ELSE 'Chat fehlgeschlagen' END; END IF;
  IF zu ? 'glocke' THEN teile := teile || CASE zu->>'glocke' WHEN 'ok' THEN 'Glocke' ELSE 'Glocke nicht angelegt' END; END IF;
  IF zu ? 'mail' THEN teile := teile || CASE zu->>'mail' WHEN 'ok' THEN 'Mail an ' || coalesce(zu->>'mail_an', '')
    WHEN 'test' THEN 'Mail an ' || coalesce(zu->>'mail_an', '') || ' im Testmodus, nicht versendet (Testdaten)'
    WHEN 'fehler' THEN 'Mail fehlgeschlagen' || coalesce(' (' || nullif(zu->>'mail_grund', '') || ')', '')
    ELSE 'Mail nicht möglich' || coalesce(' (' || nullif(zu->>'mail_grund', '') || ')', '') END; END IF;
  UPDATE public.briefing_ergebnisse SET zustellung = zu, zugestellt = left(array_to_string(teile, ', '), 600) WHERE id = r.id;
  IF r.nach_zeitplan AND r.periode IS NOT NULL THEN
    INSERT INTO public.briefing_laeufe (briefing_id, person, periode, status, versuche) VALUES (r.briefing_id, r.person, r.periode, CASE WHEN fehler THEN 'fehler' ELSE 'ok' END, 1)
    ON CONFLICT (briefing_id, person, periode) DO UPDATE SET status = EXCLUDED.status,
      versuche = public.briefing_laeufe.versuche + CASE WHEN EXCLUDED.status = 'fehler' THEN 1 ELSE 0 END, geaendert_am = now();
  END IF;
  RETURN jsonb_build_object('ok', true, 'ergebnis_id', r.id, 'zugestellt', array_to_string(teile, ', '), 'fehlversuch', fehler);
END $function$;
CREATE OR REPLACE FUNCTION public.briefing_web(p_token text, p_param jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
  s record; b public.briefings%ROWTYPE; bid integer; eid bigint; aus jsonb; darf boolean; andere boolean;
  P jsonb := CASE WHEN jsonb_typeof(p_param) = 'object' THEN p_param ELSE '{}'::jsonb END;
BEGIN
  -- Migration 208 (Briefing, Stefan 06.11.2026): Daten der Seite Kommunikation › Briefing (ALLY 33). Liste „Meine Briefings“ und darunter die Briefings, die andere
  -- an mich zustellen oder mit mir teilen; Seite eines Briefings (briefing=<Nummer>, ergebnis=<Nummer>) mit Zeitplan, Inhalten (Bausteine nach Paket), Empfängern
  -- (nur mit dem Recht „Briefings für andere“), Zustellung, Teilen und Verlauf; Papierkorb (papierkorb=1). Alte Aufrufe der Seite KI-Analysen (alt_briefing,
  -- alt_ergebnis = Nummern aus talents_briefings) führen zum übernommenen Briefing. Ändern, teilen und löschen nur die Person, der das Briefing gehört.
  SELECT * INTO s FROM public.ally_ui_sitzung(p_token) y WHERE NOT y.muss_pw_setzen;
  IF NOT FOUND THEN RETURN jsonb_build_object('ok', false, 'fehler', 'Bitte neu anmelden.'); END IF;
  IF NOT public.briefing_darf(s.person) THEN RETURN jsonb_build_object('ok', false, 'fehler', 'Briefings sind für dich nicht freigeschaltet.'); END IF;
  PERFORM public.briefing_standard_anlegen(s.person);
  andere := coalesce(public.ally_hat_recht(s.person, 'briefing_andere'), false);
  aus := jsonb_build_object('ok', true, 'ich', s.person, 'darf_andere', andere,
    'mail_absender', coalesce((public.ally_systemnachricht_absender_stand()->>'aktiv')::boolean, false),
    'zeitraeume', '[{"wert": "letzte_7_tage", "text": "Letzte 7 Tage"}, {"wert": "letzte_30_tage", "text": "Letzte 30 Tage"}, {"wert": "vormonat", "text": "Vormonat"}]'::jsonb);
  bid := CASE WHEN coalesce(P->>'briefing', '') ~ '^[0-9]{1,9}$' THEN (P->>'briefing')::integer END;
  eid := CASE WHEN coalesce(P->>'ergebnis', '') ~ '^[0-9]{1,12}$' THEN (P->>'ergebnis')::bigint END;
  IF bid IS NULL AND coalesce(P->>'alt_briefing', '') ~ '^[0-9]{1,9}$' THEN
    -- eine KI-Analyse ohne anlegende Person ist je Empfänger ein eigenes Briefing: das eigene zuerst, sonst eines, das die Person sieht
    SELECT x.id INTO bid FROM public.briefings x WHERE x.alt_id = (P->>'alt_briefing')::integer
    ORDER BY (x.person = s.person) DESC, public.briefing_sichtbar(s.person, x.id) DESC, x.id LIMIT 1;
    IF bid IS NULL THEN bid := 0; END IF;
    IF coalesce(P->>'alt_ergebnis', '') ~ '^[0-9]{1,12}$' THEN SELECT x.id INTO eid FROM public.briefing_ergebnisse x WHERE x.alt_id = (P->>'alt_ergebnis')::bigint; END IF;
  END IF;

  IF bid IS NOT NULL THEN
    SELECT * INTO b FROM public.briefings x WHERE x.id = bid;
    IF NOT FOUND OR NOT public.briefing_sichtbar(s.person, bid) THEN RETURN aus || jsonb_build_object('briefing_fehlt', true); END IF;
    darf := b.person = s.person;
    IF eid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM public.briefing_ergebnisse r WHERE r.id = eid AND r.briefing_id = b.id AND public.briefing_ergebnis_lesbar(s.person, r.id)) THEN eid := NULL; END IF;
    IF eid IS NULL THEN
      SELECT r.id INTO eid FROM public.briefing_ergebnisse r WHERE r.briefing_id = b.id AND public.briefing_ergebnis_lesbar(s.person, r.id)
      ORDER BY (r.person = s.person) DESC, r.erstellt_am DESC, r.id DESC LIMIT 1;
    END IF;
    aus := aus || jsonb_build_object('briefing', jsonb_build_object(
      'id', b.id, 'name', b.name, 'an', b.an, 'rhythmus', b.rhythmus, 'tag', b.tag, 'uhrzeit', b.uhrzeit, 'standard', b.standard,
      'zeitplan', public.briefing_zeitplan_text(b.an, b.rhythmus, b.tag, b.uhrzeit), 'naechster', public.briefing_naechster(b.id),
      'geloescht', b.geloescht_am IS NOT NULL, 'darf_aendern', darf, 'eigen', darf,
      'von', (SELECT p.name FROM public.ally_personen p WHERE p.matrix_user_id = b.person),
      'chat', b.chat, 'glocke', b.glocke, 'mail', b.mail,
      -- Mail je Briefing (Stefan 06.11.2026): Absender, Betreff, Text, Signatur, KI-Hinweis wie bei den KI-Analysen; Stand des Absenders, wenn Mail an
      'absender', b.absender, 'mail_betreff', b.mail_betreff, 'mail_html', b.mail_html, 'signatur_an', b.signatur_an, 'signatur_html', b.signatur_html, 'ki_hinweis', b.ki_hinweis,
      'mail_standard', public.briefing_mail_standard(), 'platzhalter', public.briefing_mail_platzhalter(),
      'absender_stand', CASE WHEN b.mail THEN public.briefing_absender(b.id) END,
      'chat_moeglich', EXISTS (SELECT 1 FROM public.matrix_direct_rooms r WHERE r.matrix_user_id = s.person AND coalesce(r.room_id, '') <> ''),
      'mail_adresse', public.talents_briefing_mail_adresse(s.person),
      -- Inhalte: Bausteine, die die Person wählen kann, mit Wahl und Optionen; gewählte, die sie nicht mehr wählen kann, stehen als „nicht verfügbar“ dabei
      'bausteine', (SELECT coalesce(jsonb_agg(jsonb_build_object('schluessel', x.schluessel, 'name', x.name, 'beschreibung', x.beschreibung, 'gruppe', x.gruppe,
          'ki', x.ki, 'optionen', x.optionen, 'gewaehlt', bi.baustein IS NOT NULL, 'werte', coalesce(bi.optionen, '{}'::jsonb), 'verfuegbar', true)
          ORDER BY x.reihenfolge, x.schluessel COLLATE "C"), '[]'::jsonb)
        FROM public.briefing_bausteine_fuer(b.person) x LEFT JOIN public.briefing_inhalte bi ON bi.briefing_id = b.id AND bi.baustein = x.schluessel),
      'inhalte_namen', (SELECT coalesce(jsonb_agg(x.name ORDER BY x.reihenfolge, x.schluessel COLLATE "C"), '[]'::jsonb)
        FROM public.briefing_inhalte bi JOIN public.briefing_bausteine_fuer(b.person) x ON x.schluessel = bi.baustein WHERE bi.briefing_id = b.id),
      'empfaenger', to_jsonb(b.empfaenger), 'manager', b.manager, 'manager_kreis', b.manager_kreis, 'an_mich', b.an_mich,
      'manager_moeglich', EXISTS (SELECT 1 FROM public.briefing_bausteine_fuer(b.person) x WHERE x.modul = 'talents'),
      -- Empfänger mit Kennzeichen: über „Alle Manager/innen der Talents“, abbestellt (Stefan 06.11.2026: die Besitzerin sieht, wer abbestellt hat)
      'empfaenger_liste', (SELECT coalesce(jsonb_agg(jsonb_build_object('person', e.person, 'name', coalesce(p.name, e.person), 'eigen', e.eigen,
          'talent', public.ally_person_ist_talent(e.person), 'manager', e.manager, 'abbestellt', e.abbestellt) ORDER BY e.eigen DESC, e.abbestellt, coalesce(p.name, e.person) COLLATE "C"), '[]'::jsonb)
        -- Prüfung N-a: wer abbestellt hat, sieht nur die Person, der das Briefing gehört
        FROM public.briefing_empfaenger_alle(b.id) e LEFT JOIN public.ally_personen p ON p.matrix_user_id = e.person WHERE b.person = s.person OR NOT e.abbestellt),
      'ich_empfaenger', EXISTS (SELECT 1 FROM public.briefing_empfaenger(b.id) e WHERE e.person = s.person),
      'ich_abbestellt', EXISTS (SELECT 1 FROM public.briefing_empfaenger_alle(b.id) e WHERE e.person = s.person AND e.abbestellt),
      'darf_erstellen', b.geloescht_am IS NULL,
      'teilen', (SELECT coalesce(jsonb_agg(jsonb_build_object('person', t.person, 'name', coalesce(p.name, t.person), 'am', public.arbeit_zeit(t.geteilt_am),
          'von', (SELECT v.name FROM public.ally_personen v WHERE v.matrix_user_id = t.geteilt_von)) ORDER BY coalesce(p.name, t.person) COLLATE "C"), '[]'::jsonb)
        FROM public.briefing_teilen t LEFT JOIN public.ally_personen p ON p.matrix_user_id = t.person WHERE t.briefing_id = b.id),
      'ergebnisse', (SELECT coalesce(jsonb_agg(public.briefing_kopf(r.id) ORDER BY r.erstellt_am DESC, r.id DESC), '[]'::jsonb)
        FROM (SELECT r0.* FROM public.briefing_ergebnisse r0 WHERE r0.briefing_id = b.id AND public.briefing_ergebnis_lesbar(s.person, r0.id)
              ORDER BY r0.erstellt_am DESC, r0.id DESC LIMIT 50) r),
      'ergebnisse_anzahl', (SELECT count(*) FROM public.briefing_ergebnisse r0 WHERE r0.briefing_id = b.id AND public.briefing_ergebnis_lesbar(s.person, r0.id)),
      'ergebnis', (SELECT public.briefing_kopf(r.id) || jsonb_build_object('text', r.text) FROM public.briefing_ergebnisse r WHERE r.id = eid)));
    IF darf THEN
      aus := aus || jsonb_build_object(
        'auswahl_talents', (SELECT coalesce(jsonb_agg(jsonb_build_object('wert', t.id::text, 'text', public.talent_anzeigename(t.id)) ORDER BY public.talent_anzeigename(t.id) COLLATE "C", t.id), '[]'::jsonb)
          FROM public.talents t WHERE t.status = 'aktiv' AND NOT public.talents_ist_testdaten(t.id) AND coalesce(public.talent_sichtbar(s.person, t.id), false)
            AND NOT EXISTS (SELECT 1 FROM public.talent_personen tp WHERE tp.talent_id = t.id AND tp.matrix_user_id = s.person)),
        'eigene_talents', (SELECT coalesce(jsonb_agg(public.talent_anzeigename(t.id) ORDER BY public.talent_anzeigename(t.id) COLLATE "C"), '[]'::jsonb) FROM public.talents t
          WHERE t.status = 'aktiv' AND NOT public.talents_ist_testdaten(t.id) AND EXISTS (SELECT 1 FROM public.talent_personen tp WHERE tp.talent_id = t.id AND tp.matrix_user_id = s.person)),
        -- Empfänger: aktive Personen (auch Talents), keine Test-Personen; schon gewählte bleiben wählbar
        'auswahl_empfaenger', (SELECT coalesce(jsonb_agg(jsonb_build_object('wert', p.matrix_user_id, 'text', p.name || CASE WHEN public.ally_person_ist_talent(p.matrix_user_id) THEN ' (Talent)' ELSE '' END)
            ORDER BY p.name COLLATE "C", p.matrix_user_id COLLATE "C"), '[]'::jsonb)
          FROM public.ally_personen p WHERE p.matrix_user_id <> s.person AND ((p.aktiv AND NOT p.testdaten) OR p.matrix_user_id = ANY (b.empfaenger))),
        -- Absender: Postfächer mit eigenem Ablauf, die die Person als Absender wählen darf (wie bei den KI-Analysen), ein schon gespeicherter bleibt sichtbar
        'auswahl_absender', public.talents_briefing_postfaecher(s.person)
          || coalesce((SELECT jsonb_agg(jsonb_build_object('adresse', b.absender, 'name', coalesce(nullif(btrim(f.name), ''), b.absender), 'versand', false, 'gesperrt', false, 'anders', true))
                       FROM (SELECT 1) q LEFT JOIN public.ally_postfaecher f ON f.adresse = b.absender
                       WHERE b.absender IS NOT NULL AND NOT public.talents_briefing_postfaecher(s.person) @> jsonb_build_array(jsonb_build_object('adresse', b.absender))), '[]'::jsonb),
        'system_absender', (SELECT CASE WHEN coalesce((a.s->>'aktiv')::boolean, false) THEN jsonb_build_object('adresse', lower(a.s->>'adresse'),
            'signatur', (SELECT nullif(btrim(coalesce(f.signatur_html, '')), '') FROM public.ally_postfaecher f WHERE f.adresse = lower(a.s->>'adresse'))) END
          FROM (SELECT public.ally_systemnachricht_absender_stand() AS s) a),
        -- Teilen: aktive Personen mit der Seite Briefing, nicht die eigene, noch nicht geteilt
        'auswahl_teilen', (SELECT coalesce(jsonb_agg(jsonb_build_object('wert', p.matrix_user_id, 'text', p.name) ORDER BY p.name COLLATE "C", p.matrix_user_id COLLATE "C"), '[]'::jsonb)
          FROM public.ally_personen p WHERE p.aktiv AND NOT p.testdaten AND p.matrix_user_id <> s.person AND public.briefing_darf(p.matrix_user_id)
            AND NOT EXISTS (SELECT 1 FROM public.briefing_teilen t WHERE t.briefing_id = b.id AND t.person = p.matrix_user_id)));
    END IF;
    RETURN aus;
  END IF;

  IF coalesce(P->>'papierkorb', '') = '1' THEN
    RETURN aus || jsonb_build_object('papierkorb', (SELECT coalesce(jsonb_agg(jsonb_build_object('id', b2.id, 'name', b2.name, 'geloescht', public.arbeit_zeit(b2.geloescht_am),
        'ergebnisse', (SELECT count(*) FROM public.briefing_ergebnisse r WHERE r.briefing_id = b2.id),
        'von', (SELECT p.name FROM public.ally_personen p WHERE p.matrix_user_id = b2.geloescht_von)) ORDER BY b2.geloescht_am DESC, b2.id DESC), '[]'::jsonb)
      FROM public.briefings b2 WHERE b2.person = s.person AND b2.geloescht_am IS NOT NULL));
  END IF;

  RETURN aus || jsonb_build_object(
    'meine', (SELECT coalesce(jsonb_agg(jsonb_build_object('id', b2.id, 'name', b2.name, 'standard', b2.standard,
        'zeitplan', public.briefing_zeitplan_text(b2.an, b2.rhythmus, b2.tag, b2.uhrzeit), 'naechster', public.briefing_naechster(b2.id),
        'inhalte', (SELECT count(*) FROM public.briefing_inhalte bi JOIN public.briefing_bausteine_fuer(b2.person) x ON x.schluessel = bi.baustein WHERE bi.briefing_id = b2.id),
        'empfaenger', (SELECT count(*) FROM public.briefing_empfaenger(b2.id)), 'an_mich', b2.an_mich,
        'letzter', (SELECT public.arbeit_zeit(max(r.erstellt_am)) FROM public.briefing_ergebnisse r WHERE r.briefing_id = b2.id))
        ORDER BY b2.standard DESC, lower(b2.name) COLLATE "C", b2.id), '[]'::jsonb)
      FROM public.briefings b2 WHERE b2.person = s.person AND b2.geloescht_am IS NULL),
    'andere', (SELECT coalesce(jsonb_agg(jsonb_build_object('id', b2.id, 'name', b2.name,
        'von', (SELECT p.name FROM public.ally_personen p WHERE p.matrix_user_id = b2.person),
        'wie', CASE WHEN e2.abbestellt THEN 'abbestellt' WHEN e2.person IS NOT NULL THEN 'an dich' ELSE 'mit dir geteilt' END,
        -- Abbestellen (Stefan 06.11.2026): nur, wer es als Empfänger bekommt bzw. abbestellt hat
        'empfaenger', e2.person IS NOT NULL, 'abbestellt', coalesce(e2.abbestellt, false),
        'zeitplan', public.briefing_zeitplan_text(b2.an, b2.rhythmus, b2.tag, b2.uhrzeit),
        'letzter', (SELECT public.arbeit_zeit(max(r.erstellt_am)) FROM public.briefing_ergebnisse r WHERE r.briefing_id = b2.id AND r.person = s.person))
        ORDER BY lower(b2.name) COLLATE "C", b2.id), '[]'::jsonb)
      FROM public.briefings b2 LEFT JOIN LATERAL (SELECT e.person, e.abbestellt FROM public.briefing_empfaenger_alle(b2.id) e WHERE e.person = s.person) e2 ON true
      WHERE b2.person <> s.person AND b2.geloescht_am IS NULL AND public.briefing_sichtbar(s.person, b2.id)),
    'papierkorb_anzahl', (SELECT count(*) FROM public.briefings b2 WHERE b2.person = s.person AND b2.geloescht_am IS NOT NULL));
END $function$;
CREATE OR REPLACE FUNCTION public.briefing_ui_aktion(p_token text, p_csrf text, p_aktion text, p_daten jsonb, p_zustand jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
  s record; e jsonb; b public.briefings%ROWTYPE; bid integer; nm text; rh text; tg smallint; uz text; tl text; emp text[]; wer text; st timestamptz; n integer; k text; o jsonb; v jsonb;
  d jsonb := CASE WHEN jsonb_typeof(p_daten) = 'object' THEN p_daten ELSE '{}'::jsonb END;
  nein jsonb := '{"ok": false, "angemeldet": true}'::jsonb;
  ja jsonb := '{"ok": true, "angemeldet": true}'::jsonb;
BEGIN
  -- Migration 208 (Briefing, Stefan 06.11.2026): Aktionen der Seite Briefing (br_*; ALLY 20 „Aktion ausführen“, NULL bei allen anderen Aktionen).
  -- br_anlegen (Name und Zeitplan; Inhalte wie das Standard-Briefing, Zustellung Glocke), br_speichern (je Kachel teil = zeitplan, inhalte, empfaenger, zustellung;
  -- je Kachel ein Knopf), br_umbenennen, br_jetzt (Ergebnis für mich, ALLY 4 über weiter = start), br_papierkorb, br_wiederherstellen, br_endgueltig,
  -- br_papierkorb_leeren, br_teilen, br_teilen_entfernen. Ändern, teilen, löschen nur die Person, der das Briefing gehört; „Jetzt erstellen“ jede Person, die es sieht.
  -- br_abbestellen, br_bestellen (Stefan 06.11.2026): Empfänger bestellen ein Briefing einer anderen Person ab bzw. wieder.
  -- Prüfung N1: Aktionen der früheren Seite KI-Analysen (bf_*, zum Beispiel aus einer noch offenen alten Seite) ändern die alten Tabellen nicht mehr; sie führen
  -- mit einem Hinweis zum übernommenen Briefing (alte Nummer über alt_id).
  IF coalesce(p_aktion, '') !~ '^b[rf]_[a-z_]{1,30}$' THEN RETURN NULL; END IF;
  SELECT * INTO s FROM public.ally_ui_sitzung(p_token);
  IF NOT FOUND THEN RETURN '{"ok": false, "angemeldet": false}'::jsonb; END IF;
  IF coalesce(p_csrf, '') <> public.ally_ui_csrf(s.token_hash) THEN
    RETURN coalesce(public.ally_web_meldung(p_token, 'Die Anfrage wurde abgelehnt. Bitte die Seite neu laden.', 'fehler', NULL), '{}'::jsonb) || '{"ok": false, "angemeldet": true, "ungueltig": true}'::jsonb;
  END IF;
  IF s.muss_pw_setzen THEN RETURN '{"ok": false, "angemeldet": true, "muss_pw_setzen": true}'::jsonb; END IF;
  IF jsonb_typeof(p_zustand->'z') = 'array' THEN
    FOR e IN SELECT y FROM jsonb_array_elements(p_zustand->'z') y LIMIT 40 LOOP
      IF jsonb_typeof(e) = 'object' AND jsonb_typeof(e->'offen') = 'boolean' THEN PERFORM public.ally_ui_zustand_merken(s.person, e->>'k', jsonb_build_object('offen', e->'offen')); END IF;
    END LOOP;
  END IF;
  IF NOT public.briefing_darf(s.person) THEN PERFORM public.ally_web_meldung(p_token, 'Briefings sind für dich nicht freigeschaltet.', 'fehler', NULL); RETURN nein; END IF;

  IF p_aktion ~ '^bf_' THEN
    SELECT x.id INTO bid FROM public.briefings x WHERE x.alt_id = CASE WHEN coalesce(d->>'briefing_id', '') ~ '^[0-9]{1,9}$' THEN (d->>'briefing_id')::integer END
      AND public.briefing_sichtbar(s.person, x.id) ORDER BY (x.person = s.person) DESC, x.id LIMIT 1;
    PERFORM public.ally_web_meldung(p_token, 'Die KI-Analysen sind jetzt Briefings. Nichts geändert – bitte hier auf der Seite Briefing weitermachen.', 'fehler', NULL);
    RETURN nein || CASE WHEN bid IS NOT NULL THEN jsonb_build_object('br_ziel', 'briefing=' || bid) ELSE jsonb_build_object('br_ziel', 'liste') END;
  END IF;

  IF p_aktion = 'br_papierkorb_leeren' THEN
    SELECT count(*) INTO n FROM public.briefings x WHERE x.person = s.person AND x.geloescht_am IS NOT NULL;
    DELETE FROM public.briefings x WHERE x.person = s.person AND x.geloescht_am IS NOT NULL;
    PERFORM public.ally_web_meldung(p_token, CASE WHEN n = 0 THEN 'Der Papierkorb ist schon leer.' WHEN n = 1 THEN '1 Briefing endgültig gelöscht, mit allen Ergebnissen.'
      ELSE n || ' Briefings endgültig gelöscht, mit allen Ergebnissen.' END, 'ok', NULL);
    RETURN ja;
  END IF;

  -- Zeitplan prüfen (Neues Briefing und Kachel „Zeitplan“): Rhythmus, Wochentag bzw. Tag im Monat, Uhrzeit im 15-Minuten-Takt (abgerundet wie im Chat)
  IF p_aktion IN ('br_anlegen', 'br_speichern') AND (p_aktion = 'br_anlegen' OR d->>'teil' = 'zeitplan') THEN
    rh := coalesce(d->>'rhythmus', '');
    IF rh NOT IN ('tag', 'woche', 'monat', 'hand') THEN PERFORM public.ally_web_meldung(p_token, 'Bitte einen Rhythmus wählen.', 'fehler', NULL); RETURN nein; END IF;
    tg := CASE WHEN rh = 'woche' AND coalesce(d->>'tag', '') ~ '^[1-7]$' THEN (d->>'tag')::smallint
               WHEN rh = 'monat' AND coalesce(d->>'monatstag', '') ~ '^([1-9]|1[0-9]|2[0-8])$' THEN (d->>'monatstag')::smallint
               WHEN rh IN ('tag', 'hand') THEN 1 END;
    IF tg IS NULL THEN PERFORM public.ally_web_meldung(p_token, CASE WHEN rh = 'woche' THEN 'Bitte einen Wochentag wählen.' ELSE 'Bitte einen Tag im Monat wählen (1 bis 28).' END, 'fehler', NULL); RETURN nein; END IF;
    uz := left(btrim(coalesce(d->>'uhrzeit', '')), 5);
    IF uz = '' AND rh = 'hand' THEN uz := '05:00'; END IF;
    IF uz !~ '^([01][0-9]|2[0-3]):[0-5][0-9]$' THEN PERFORM public.ally_web_meldung(p_token, 'Bitte eine Uhrzeit wie 05:00 wählen.', 'fehler', NULL); RETURN nein; END IF;
    uz := left(uz, 3) || lpad(((substr(uz, 4, 2)::integer / 15) * 15)::text, 2, '0');
  END IF;

  IF p_aktion = 'br_anlegen' THEN
    nm := btrim(regexp_replace(coalesce(d->>'name', ''), '\s+', ' ', 'g'));
    IF nm = '' OR length(nm) > 80 THEN PERFORM public.ally_web_meldung(p_token, 'Bitte einen Namen mit höchstens 80 Zeichen eingeben.', 'fehler', NULL); RETURN nein; END IF;
    INSERT INTO public.briefings (person, name, an, rhythmus, tag, uhrzeit, chat, glocke, mail, testdaten, erstellt_von, geaendert_von)
    VALUES (s.person, nm, true, rh, tg, uz, false, true, false, public.ally_person_ist_testdaten(s.person), s.person, s.person) RETURNING id INTO bid;
    INSERT INTO public.briefing_inhalte (briefing_id, baustein) SELECT bid, x.schluessel FROM public.briefing_bausteine_fuer(s.person) x WHERE x.standard;
    PERFORM public.ally_web_meldung(p_token, 'Briefing „' || nm || '“ angelegt. Inhalte, Empfänger und Zustellung stellst du in den Kacheln ein.', 'ok', NULL);
    RETURN ja || jsonb_build_object('br_ziel', 'briefing=' || bid);
  END IF;

  bid := CASE WHEN coalesce(d->>'briefing_id', '') ~ '^[0-9]{1,9}$' THEN (d->>'briefing_id')::integer END;
  SELECT * INTO b FROM public.briefings x WHERE x.id = bid FOR UPDATE;
  IF NOT FOUND OR NOT public.briefing_sichtbar(s.person, b.id) THEN
    PERFORM public.ally_web_meldung(p_token, 'Dieses Briefing gibt es nicht mehr oder es ist nicht mit dir geteilt.', 'fehler', NULL); RETURN nein;
  END IF;

  IF p_aktion = 'br_jetzt' THEN
    IF b.geloescht_am IS NOT NULL THEN PERFORM public.ally_web_meldung(p_token, 'Das Briefing liegt im Papierkorb.', 'fehler', NULL); RETURN nein; END IF;
    -- läuft gerade (gestartet, noch kein Ergebnis): kein zweiter Start
    SELECT y.geaendert_am INTO st FROM public.ally_nutzer_einstellungen y WHERE y.matrix_user_id = s.person AND y.schluessel = 'web_start_briefing';
    IF st > now() - interval '2 minutes' AND NOT EXISTS (SELECT 1 FROM public.briefing_ergebnisse r WHERE r.erstellt_von = s.person AND r.erstellt_am >= st) THEN
      PERFORM public.ally_web_meldung(p_token, 'Gerade erstellt Ally schon ein Briefing für dich. Bitte einen Moment warten und die Seite neu laden.', 'fehler', NULL); RETURN nein;
    END IF;
    INSERT INTO public.ally_nutzer_einstellungen (matrix_user_id, schluessel, wert, geaendert_am) VALUES (s.person, 'web_start_briefing', b.id::text, now())
    ON CONFLICT (matrix_user_id, schluessel) DO UPDATE SET wert = EXCLUDED.wert, geaendert_am = now();
    RETURN ja || jsonb_build_object('weiter', 'start', 'r', jsonb_build_object('was', 'briefing', 'nutzer', s.person || '#' || b.id), 'br_ziel', 'briefing=' || b.id);
  END IF;

  -- Abbestellen und wieder bestellen (Stefan 06.11.2026): nur Empfänger eines Briefings einer anderen Person
  IF p_aktion IN ('br_abbestellen', 'br_bestellen') THEN
    IF b.person = s.person OR NOT EXISTS (SELECT 1 FROM public.briefing_empfaenger_alle(b.id) e WHERE e.person = s.person AND NOT e.eigen) THEN
      PERFORM public.ally_web_meldung(p_token, 'Abbestellen kann nur, wer das Briefing einer anderen Person bekommt.', 'fehler', NULL); RETURN nein;
    END IF;
    IF p_aktion = 'br_abbestellen' THEN
      INSERT INTO public.briefing_abbestellt (briefing_id, person, herkunft) VALUES (b.id, s.person, 'person') ON CONFLICT DO NOTHING;
      PERFORM public.ally_web_meldung(p_token, 'Abbestellt: „' || b.name || '“ bekommst du nicht mehr (kein Chat, keine Glocke, keine Mail). Du kannst es jederzeit wieder bestellen.', 'ok', NULL);
    ELSE
      DELETE FROM public.briefing_abbestellt x WHERE x.briefing_id = b.id AND x.person = s.person;
      PERFORM public.ally_web_meldung(p_token, 'Wieder bestellt: Du bekommst „' || b.name || '“ wieder.', 'ok', NULL);
    END IF;
    RETURN ja;
  END IF;

  IF b.person <> s.person THEN
    PERFORM public.ally_web_meldung(p_token, 'Ändern kann dieses Briefing nur die Person, der es gehört.', 'fehler', NULL); RETURN nein;
  END IF;

  IF p_aktion IN ('br_wiederherstellen', 'br_endgueltig') THEN
    IF b.geloescht_am IS NULL THEN PERFORM public.ally_web_meldung(p_token, 'Das Briefing liegt nicht im Papierkorb.', 'fehler', NULL); RETURN nein; END IF;
    IF p_aktion = 'br_wiederherstellen' THEN
      UPDATE public.briefings SET geloescht_am = NULL, geloescht_von = NULL, geaendert_am = now(), geaendert_von = s.person WHERE id = b.id;
      PERFORM public.ally_web_meldung(p_token, 'Briefing „' || b.name || '“ wiederhergestellt.', 'ok', NULL);
    ELSE
      DELETE FROM public.briefings WHERE id = b.id;
      PERFORM public.ally_web_meldung(p_token, 'Briefing „' || b.name || '“ endgültig gelöscht, mit allen Ergebnissen.', 'ok', NULL);
    END IF;
    RETURN ja;
  END IF;
  IF b.geloescht_am IS NOT NULL THEN PERFORM public.ally_web_meldung(p_token, 'Das Briefing liegt im Papierkorb. Zuerst wiederherstellen.', 'fehler', NULL); RETURN nein; END IF;

  IF p_aktion = 'br_papierkorb' THEN
    UPDATE public.briefings SET geloescht_am = now(), geloescht_von = s.person WHERE id = b.id;
    PERFORM public.ally_web_meldung(p_token, 'Briefing „' || b.name || '“ liegt im Papierkorb. Ally erstellt es nicht mehr. Im Papierkorb kannst du es wiederherstellen oder endgültig löschen.', 'ok', NULL);
    RETURN ja;
  END IF;

  IF p_aktion = 'br_umbenennen' THEN
    nm := btrim(regexp_replace(coalesce(d->>'name', ''), '\s+', ' ', 'g'));
    IF nm = '' OR length(nm) > 80 THEN PERFORM public.ally_web_meldung(p_token, 'Bitte einen Namen mit höchstens 80 Zeichen eingeben.', 'fehler', NULL); RETURN nein; END IF;
    UPDATE public.briefings SET name = nm, geaendert_am = now(), geaendert_von = s.person WHERE id = b.id;
    PERFORM public.ally_web_meldung(p_token, 'Umbenannt in „' || nm || '“.', 'ok', NULL);
    RETURN ja;
  END IF;

  IF p_aktion IN ('br_teilen', 'br_teilen_entfernen') THEN
    wer := btrim(coalesce(d->>'person', ''));
    SELECT p.name INTO nm FROM public.ally_personen p WHERE p.matrix_user_id = wer;
    IF p_aktion = 'br_teilen_entfernen' THEN
      DELETE FROM public.briefing_teilen t WHERE t.briefing_id = b.id AND t.person = wer;
      IF NOT FOUND THEN PERFORM public.ally_web_meldung(p_token, 'Mit dieser Person ist das Briefing nicht mehr geteilt.', 'fehler', NULL); RETURN nein; END IF;
      PERFORM public.ally_web_meldung(p_token, 'Nicht mehr geteilt mit ' || coalesce(nm, wer) || '.', 'ok', NULL);
      RETURN ja;
    END IF;
    IF wer = '' THEN PERFORM public.ally_web_meldung(p_token, 'Bitte eine Person wählen.', 'fehler', NULL); RETURN nein; END IF;
    IF wer = s.person OR NOT EXISTS (SELECT 1 FROM public.ally_personen p WHERE p.matrix_user_id = wer AND p.aktiv AND NOT p.testdaten) OR NOT public.briefing_darf(wer) THEN
      PERFORM public.ally_web_meldung(p_token, 'Teilen geht nur mit aktiven Personen, die die Seite Briefing nutzen dürfen.', 'fehler', NULL); RETURN nein;
    END IF;
    INSERT INTO public.briefing_teilen (briefing_id, person, geteilt_von) VALUES (b.id, wer, s.person) ON CONFLICT DO NOTHING;
    IF NOT FOUND THEN PERFORM public.ally_web_meldung(p_token, 'Das Briefing ist schon mit ' || coalesce(nm, wer) || ' geteilt.', 'fehler', NULL); RETURN nein; END IF;
    PERFORM public.ally_web_meldung(p_token, 'Geteilt mit ' || coalesce(nm, wer) || ': sieht „' || b.name || '“ jetzt unter Briefing, ändern kannst nur du.', 'ok', NULL);
    RETURN ja;
  END IF;

  IF p_aktion <> 'br_speichern' THEN RETURN nein; END IF;
  tl := coalesce(d->>'teil', '');
  IF tl = 'zeitplan' THEN
    UPDATE public.briefings SET an = coalesce(d->>'an', '') = '1', rhythmus = rh, tag = tg, uhrzeit = uz, geaendert_am = now(), geaendert_von = s.person WHERE id = b.id;
    SELECT * INTO b FROM public.briefings x WHERE x.id = b.id;
    PERFORM public.ally_web_meldung(p_token, 'Gespeichert. ' || CASE WHEN NOT b.an THEN 'Das Briefing ist aus; „Jetzt erstellen“ geht weiter.'
      WHEN b.rhythmus = 'hand' THEN 'Das Briefing entsteht nur mit „Jetzt erstellen“.' ELSE 'Nächstes Briefing: ' || coalesce(public.briefing_naechster(b.id), '–') || '.' END, 'ok', NULL);
    RETURN ja;
  ELSIF tl = 'inhalte' THEN
    IF jsonb_typeof(d->'bausteine') IS DISTINCT FROM 'object' THEN PERFORM public.ally_web_meldung(p_token, 'Die Angaben sind unvollständig. Bitte die Seite neu laden.', 'fehler', NULL); RETURN nein; END IF;
    IF EXISTS (SELECT 1 FROM jsonb_object_keys(d->'bausteine') k0 WHERE NOT EXISTS (SELECT 1 FROM public.briefing_bausteine_fuer(s.person) x WHERE x.schluessel = k0)) THEN
      PERFORM public.ally_web_meldung(p_token, 'Ein gewählter Inhalt steht dir nicht zur Verfügung. Bitte die Seite neu laden.', 'fehler', NULL); RETURN nein;
    END IF;
    -- nur Inhalte, die die Person wählen kann, werden neu gesetzt; gewählte aus nicht mehr verfügbaren Paketen bleiben unverändert stehen
    DELETE FROM public.briefing_inhalte bi WHERE bi.briefing_id = b.id AND EXISTS (SELECT 1 FROM public.briefing_bausteine_fuer(s.person) x WHERE x.schluessel = bi.baustein);
    FOR k, v IN SELECT * FROM jsonb_each(d->'bausteine') LOOP
      o := '{}'::jsonb;
      FOR e IN SELECT y FROM jsonb_array_elements((SELECT x.optionen FROM public.briefing_bausteine x WHERE x.schluessel = k)) y LOOP
        IF e->>'art' = 'talents' AND jsonb_typeof(v->(e->>'name')) = 'array' THEN
          o := o || jsonb_build_object(e->>'name', (SELECT coalesce(jsonb_agg(t.id::text ORDER BY t.id), '[]'::jsonb) FROM public.talents t
            WHERE t.id::text IN (SELECT jsonb_array_elements_text(v->(e->>'name'))) AND coalesce(public.talent_sichtbar(s.person, t.id), false)));
        ELSIF e->>'art' = 'zeitraum' AND v->>(e->>'name') IN ('letzte_7_tage', 'letzte_30_tage', 'vormonat') THEN
          o := o || jsonb_build_object(e->>'name', v->>(e->>'name'));
        END IF;
      END LOOP;
      INSERT INTO public.briefing_inhalte (briefing_id, baustein, optionen) VALUES (b.id, k, o);
    END LOOP;
    UPDATE public.briefings SET geaendert_am = now(), geaendert_von = s.person WHERE id = b.id;
    SELECT count(*) INTO n FROM public.briefing_inhalte bi WHERE bi.briefing_id = b.id;
    PERFORM public.ally_web_meldung(p_token, 'Gespeichert. ' || CASE WHEN n = 0 THEN 'Das Briefing hat keine Inhalte; Ally stellt es dann nicht zu.' WHEN n = 1 THEN '1 Inhalt gewählt.' ELSE n || ' Inhalte gewählt.' END, 'ok', NULL);
    RETURN ja;
  ELSIF tl = 'empfaenger' THEN
    -- feste Empfänger und „Alle Manager/innen der Talents“ nur, wenn das Formular sie schickt (sonst bleiben sie); „An mich“ (Stefan 06.11.2026) für jede Person
    IF d ? 'empfaenger' THEN
      SELECT coalesce(array_agg(DISTINCT x0 COLLATE "C" ORDER BY x0 COLLATE "C"), '{}') INTO emp FROM jsonb_array_elements_text(CASE WHEN jsonb_typeof(d->'empfaenger') = 'array' THEN d->'empfaenger' ELSE '[]'::jsonb END) x0
        WHERE x0 <> s.person;
    ELSE
      emp := b.empfaenger;
    END IF;
    IF ((d ? 'empfaenger' AND cardinality(emp) > 0 AND emp IS DISTINCT FROM b.empfaenger) OR (coalesce(d->>'manager', '') = '1' AND NOT b.manager))
       AND NOT coalesce(public.ally_hat_recht(s.person, 'briefing_andere'), false) THEN
      PERFORM public.ally_web_meldung(p_token, 'Briefings an andere schicken darf nur eine Person mit dem Recht „Briefings für andere“.', 'fehler', NULL); RETURN nein;
    END IF;
    IF EXISTS (SELECT 1 FROM unnest(emp) x0 WHERE x0 <> ALL (b.empfaenger) AND NOT EXISTS (SELECT 1 FROM public.ally_personen p WHERE p.matrix_user_id = x0 AND p.aktiv AND NOT p.testdaten)) THEN
      PERFORM public.ally_web_meldung(p_token, 'Eine gewählte Person lässt sich nicht als Empfänger wählen. Bitte die Seite neu laden.', 'fehler', NULL); RETURN nein;
    END IF;
    -- höchstens 50 (Prüfung N4: übernommene KI-Analysen mit mehr Empfängern lassen sich speichern, solange es nicht mehr werden)
    IF cardinality(emp) > greatest(50, cardinality(b.empfaenger)) THEN PERFORM public.ally_web_meldung(p_token, 'Höchstens 50 Empfänger.', 'fehler', NULL); RETURN nein; END IF;
    UPDATE public.briefings SET empfaenger = emp,
      manager = CASE WHEN d ? 'manager' THEN d->>'manager' = '1' ELSE manager END,
      manager_kreis = CASE WHEN d ? 'manager' THEN CASE WHEN d->>'manager_kreis' = 'alle' THEN 'alle' ELSE 'briefing' END ELSE manager_kreis END,
      an_mich = CASE WHEN d ? 'an_mich' THEN d->>'an_mich' = '1' ELSE an_mich END,
      geaendert_am = now(), geaendert_von = s.person WHERE id = b.id;
    SELECT count(*) INTO n FROM public.briefing_empfaenger(b.id);
    PERFORM public.ally_web_meldung(p_token, 'Gespeichert. ' || CASE WHEN n = 0 THEN 'Das Briefing bekommt gerade niemand; „Jetzt erstellen“ geht weiter.'
      WHEN n = 1 AND EXISTS (SELECT 1 FROM public.briefing_empfaenger(b.id) e WHERE e.eigen) THEN 'Das Briefing bekommst nur du.'
      WHEN n = 1 THEN 'Das Briefing bekommt 1 Person.' ELSE 'Das Briefing bekommen ' || n || ' Personen.' END, 'ok', NULL);
    RETURN ja;
  ELSIF tl = 'zustellung' THEN
    -- Mail je Briefing (Stefan 06.11.2026, wie bei den KI-Analysen, Migration 180): Absender nur Postfächer mit eigenem Ablauf, die die Person wählen darf
    -- (ein schon gespeicherter bleibt), sonst der Absender für Systemnachrichten; Betreff und Text leer oder wie der Standard = Standard; Signatur aus, eigene
    -- oder die des Absenders; KI-Hinweis. Ohne Häkchen Mail bleiben die Mail-Angaben gespeichert.
    IF coalesce(d->>'mail', '') = '1' AND d ? 'absender' THEN
      wer := nullif(lower(btrim(coalesce(d->>'absender', ''))), '');
      IF wer IS NOT NULL AND wer IS DISTINCT FROM b.absender AND NOT public.talents_briefing_postfaecher(s.person) @> jsonb_build_array(jsonb_build_object('adresse', wer)) THEN
        PERFORM public.ally_web_meldung(p_token, CASE WHEN EXISTS (SELECT 1 FROM public.ally_postfaecher f WHERE f.adresse = wer) AND NOT public.ally_postfach_absender_darf(s.person, wer)
            THEN 'Dieses Postfach ist das persönliche Postfach einer anderen Person. Bitte ein anderes Absender-Postfach wählen.'
            ELSE 'Dieses Postfach kann keine Briefings senden. Bitte ein anderes Absender-Postfach wählen.' END, 'fehler', NULL);
        RETURN nein;
      END IF;
      IF wer IS NULL AND NOT coalesce((public.ally_systemnachricht_absender_stand()->>'aktiv')::boolean, false) THEN
        PERFORM public.ally_web_meldung(p_token, 'Bitte ein Absender-Postfach wählen (ein Absender für Systemnachrichten ist nicht eingerichtet).', 'fehler', NULL); RETURN nein;
      END IF;
      IF coalesce(nullif(d->>'signatur', ''), 'postfach') NOT IN ('postfach', 'eigen', 'keine') THEN
        PERFORM public.ally_web_meldung(p_token, 'Die Angaben sind unvollständig. Bitte die Seite neu laden.', 'fehler', NULL); RETURN nein;
      END IF;
      IF length(coalesce(d->>'mail_betreff', '')) > 200 OR length(coalesce(d->>'mail_html', '')) > 20000 OR length(coalesce(d->>'signatur_html', '')) > 20000 THEN
        PERFORM public.ally_web_meldung(p_token, 'Betreff oder Text ist zu lang (Betreff höchstens 200 Zeichen).', 'fehler', NULL); RETURN nein;
      END IF;
      UPDATE public.briefings SET absender = wer, mail_betreff = public.briefing_mail_normal(d->>'mail_betreff', 'betreff'), mail_html = public.briefing_mail_normal(d->>'mail_html', 'html'),
        signatur_an = coalesce(nullif(d->>'signatur', ''), 'postfach') <> 'keine',
        signatur_html = CASE WHEN d->>'signatur' = 'eigen' THEN nullif(btrim(coalesce(d->>'signatur_html', '')), '') END, ki_hinweis = coalesce(d->>'ki_hinweis', '') = '1'
      WHERE id = b.id;
    END IF;
    UPDATE public.briefings SET chat = coalesce(d->>'chat', '') = '1', glocke = coalesce(d->>'glocke', '') = '1', mail = coalesce(d->>'mail', '') = '1',
      geaendert_am = now(), geaendert_von = s.person WHERE id = b.id;
    PERFORM public.ally_web_meldung(p_token, 'Gespeichert. Das Ergebnis steht immer auf dieser Seite'
      || CASE WHEN coalesce(d->>'chat', '') = '1' OR coalesce(d->>'glocke', '') = '1' OR coalesce(d->>'mail', '') = '1' THEN ', dazu '
           || array_to_string(ARRAY[CASE WHEN coalesce(d->>'chat', '') = '1' THEN 'im Chat' END, CASE WHEN coalesce(d->>'glocke', '') = '1' THEN 'in der Glocke' END,
                                    CASE WHEN coalesce(d->>'mail', '') = '1' THEN 'per Mail' END], ', ') ELSE '' END || '.'
      || CASE WHEN coalesce(d->>'mail', '') = '1' AND NOT coalesce((public.briefing_absender(b.id)->>'bereit')::boolean, false)
              THEN ' Mails gehen noch nicht raus: ' || coalesce(public.briefing_absender(b.id)->>'fehlt', '') ELSE '' END, 'ok', NULL);
    RETURN ja;
  END IF;
  PERFORM public.ally_web_meldung(p_token, 'Die Angaben sind unvollständig. Bitte die Seite neu laden.', 'fehler', NULL);
  RETURN nein;
END $function$;
CREATE OR REPLACE FUNCTION public.briefing_meldung(p_token text, p_nutzer text)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
  s record; u text := split_part(btrim(coalesce(p_nutzer, '')), '#', 1); bid integer; ab timestamptz; r record; m text;
BEGIN
  -- Migration 208 (Briefing): Meldung nach „Jetzt erstellen“ (ALLY 20 wartet auf ALLY 4 „Briefing ausführen“): was entstanden ist und wie es zugestellt wurde
  SELECT * INTO s FROM public.ally_ui_sitzung(p_token) y WHERE NOT y.muss_pw_setzen;
  IF NOT FOUND OR s.person IS DISTINCT FROM u THEN RETURN jsonb_build_object('ok', false); END IF;
  bid := CASE WHEN p_nutzer ~ '#[0-9]{1,9}$' THEN substring(p_nutzer from '#([0-9]{1,9})$')::integer END;
  ab := coalesce((SELECT x.geaendert_am FROM public.ally_nutzer_einstellungen x WHERE x.matrix_user_id = u AND x.schluessel = 'web_start_briefing'), now() - interval '10 minutes');
  SELECT e.*, b.name INTO r FROM public.briefing_ergebnisse e JOIN public.briefings b ON b.id = e.briefing_id
  WHERE e.erstellt_von = u AND NOT e.nach_zeitplan AND e.erstellt_am >= ab AND (bid IS NULL OR e.briefing_id = bid) ORDER BY e.id DESC LIMIT 1;
  IF NOT FOUND THEN
    PERFORM public.ally_web_meldung(p_token, 'Das Briefing wurde nicht erstellt. Bitte noch einmal versuchen. Bleibt es dabei, steht der Grund unter Benachrichtigungen › Systemfehler.', 'fehler', NULL);
    RETURN jsonb_build_object('ok', false);
  END IF;
  m := 'Briefing „' || r.name || '“ erstellt. Zugestellt: ' || coalesce(r.zugestellt, 'auf der Seite') || '.'
       || CASE WHEN r.ki IS FALSE THEN ' Die Einordnung durch die KI fehlt diesmal.' ELSE '' END;
  PERFORM public.ally_web_meldung(p_token, m, 'ok', NULL);
  RETURN jsonb_build_object('ok', true, 'ergebnis_id', r.id);
END $function$;
CREATE OR REPLACE FUNCTION public.briefing_kachel(p_token text)
 RETURNS jsonb
 LANGUAGE sql
AS $function$
  -- Migration 208 (Briefing): Kachel „Briefings“ im Social-Media-Dashboard (ALLY 24, früher „KI-Analysen“): die Briefings der Person mit Inhalten des
  -- Social-Media-Pakets (eigene und solche, die sie bekommt oder die mit ihr geteilt sind), höchstens fünf, mit dem letzten Ergebnis; Link zur Seite Briefing.
  SELECT CASE WHEN s.person IS NULL THEN jsonb_build_object('ok', false) ELSE jsonb_build_object('ok', true,
    'seite', public.briefing_darf(s.person),
    'liste', CASE WHEN public.briefing_darf(s.person) THEN coalesce((SELECT jsonb_agg(jsonb_build_object('id', q.id, 'name', q.name, 'eigen', q.person = s.person,
        'zeitplan', public.briefing_zeitplan_text(q.an, q.rhythmus, q.tag, q.uhrzeit), 'letzter', public.arbeit_zeit(q.letzt), 'ergebnis_id', q.eid) ORDER BY q.letzt DESC NULLS LAST, lower(q.name) COLLATE "C", q.id)
      FROM (SELECT b.*, (SELECT max(r.erstellt_am) FROM public.briefing_ergebnisse r WHERE r.briefing_id = b.id AND r.person = s.person) AS letzt,
                   (SELECT r.id FROM public.briefing_ergebnisse r WHERE r.briefing_id = b.id AND r.person = s.person ORDER BY r.erstellt_am DESC, r.id DESC LIMIT 1) AS eid
            FROM public.briefings b WHERE b.geloescht_am IS NULL AND public.briefing_sichtbar(s.person, b.id)
              AND EXISTS (SELECT 1 FROM public.briefing_inhalte bi JOIN public.briefing_bausteine x ON x.schluessel = bi.baustein AND x.modul = 'talents' WHERE bi.briefing_id = b.id)
            ORDER BY letzt DESC NULLS LAST, b.id LIMIT 5) q), '[]'::jsonb) ELSE '[]'::jsonb END) END
  FROM (SELECT 1) x0 LEFT JOIN LATERAL (SELECT * FROM public.ally_ui_sitzung(p_token) y WHERE NOT y.muss_pw_setzen) s ON true
$function$;
CREATE OR REPLACE FUNCTION public.briefing_talent_ui(p_token text)
 RETURNS jsonb
 LANGUAGE sql
AS $function$
  -- Migration 208 (Briefing): Talent-Bereich (ALLY 38) „Dein Briefing“ – die letzten fünf Ergebnisse von Briefings, die an das Talent gehen (Recht „Briefing sehen“),
  -- Person nur aus der Sitzung
  SELECT CASE WHEN s.person IS NULL OR NOT public.ally_person_ist_talent(s.person) OR NOT coalesce(public.ally_hat_recht(s.person, 'talent_briefing'), false)
    THEN jsonb_build_object('ok', false, 'liste', '[]'::jsonb)
    ELSE jsonb_build_object('ok', true, 'liste', coalesce((SELECT jsonb_agg(jsonb_build_object('id', r.id, 'name', b.name, 'am', public.arbeit_zeit(r.erstellt_am), 'text', r.text)
        ORDER BY r.erstellt_am DESC, r.id DESC)
      FROM (SELECT r0.* FROM public.briefing_ergebnisse r0 WHERE r0.person = s.person ORDER BY r0.erstellt_am DESC, r0.id DESC LIMIT 5) r
      JOIN public.briefings b ON b.id = r.briefing_id AND b.geloescht_am IS NULL), '[]'::jsonb)) END
  -- Talent-Sitzung wie im Talent-Bereich (talent_web_sitzung: Person aktiv, Zugang aktiv, Talent aktiv, Paket gebucht); Person = Talent-Person der Sitzung
  FROM (SELECT 1) x0 LEFT JOIN LATERAL (SELECT w.matrix_user_id AS person FROM public.talent_web_sitzung(p_token) t JOIN public.ally_web_sitzungen w ON w.token_hash = t.token_hash) s ON true
$function$;
CREATE OR REPLACE FUNCTION public.briefing_start_stand(p_token text)
 RETURNS jsonb
 LANGUAGE sql
AS $function$
  -- Migration 208 (Briefing): Stand der Kachel „Briefing“ auf der Startseite (ALLY 22): wie viele eigene Briefings eingeschaltet sind und wann das nächste kommt
  -- (statt „aus“ und „heute geschickt“ aus dem alten Schalter, siehe Bericht zu Stefans Beobachtung)
  SELECT CASE WHEN s.person IS NULL OR NOT public.briefing_darf(s.person) THEN NULL ELSE jsonb_build_object(
    'anzahl', (SELECT count(*) FROM public.briefings b WHERE b.person = s.person AND b.geloescht_am IS NULL),
    'an', (SELECT count(*) FROM public.briefings b WHERE b.person = s.person AND b.geloescht_am IS NULL AND b.an AND b.rhythmus <> 'hand'),
    'naechster', (SELECT n FROM (SELECT public.briefing_naechster(b.id) AS n, b.id FROM public.briefings b WHERE b.person = s.person AND b.geloescht_am IS NULL) q
                  WHERE n IS NOT NULL ORDER BY to_date(split_part(n, ', ', 2), 'DD.MM.YYYY'), split_part(n, ', ', 3) COLLATE "C" LIMIT 1)) END
  FROM (SELECT 1) x0 LEFT JOIN LATERAL (SELECT * FROM public.ally_ui_sitzung(p_token) y WHERE NOT y.muss_pw_setzen) s ON true
$function$;
CREATE OR REPLACE FUNCTION public.briefing_chat(p_person text, p_aktion text, p_uhrzeit text, p_briefing text)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
  n integer; b public.briefings%ROWTYPE; uz text := btrim(coalesce(p_uhrzeit, '')); wahl text := btrim(coalesce(p_briefing, '')); liste jsonb;
  heute text := 'T' || to_char(now() AT TIME ZONE 'Europe/Berlin', 'YYYY-MM-DD');
BEGIN
  -- Migration 208 (Briefing): Chat-Werkzeug „Briefing“ (ALLY 1, Knoten 6_38_tool_briefing_uhrzeit). aktion = anzeigen, uhrzeit (Uhrzeit ändern, 15-Minuten-Raster,
  -- abgerundet) oder jetzt (Briefing beim nächsten Lauf, spätestens in 15 Minuten, wie eingestellt zustellen). Bei genau einem eigenen Briefing direkt, bei mehreren
  -- nur mit briefing = Name oder Nummer; sonst kommt die Liste zurück, und Ally fragt nach, welches gemeint ist.
  IF NOT public.briefing_darf(p_person) THEN RETURN jsonb_build_object('ok', false, 'fehler', 'Briefings sind für dich nicht freigeschaltet.'); END IF;
  PERFORM public.briefing_standard_anlegen(p_person);
  SELECT coalesce(jsonb_agg(jsonb_build_object('nummer', x.id, 'name', x.name, 'zeitplan', public.briefing_zeitplan_text(x.an, x.rhythmus, x.tag, x.uhrzeit)) ORDER BY x.standard DESC, lower(x.name) COLLATE "C", x.id), '[]'::jsonb),
         count(*) INTO liste, n
  FROM public.briefings x WHERE x.person = p_person AND x.geloescht_am IS NULL;
  IF n = 0 THEN RETURN jsonb_build_object('ok', false, 'fehler', 'Du hast kein Briefing. Anlegen kannst du es in Ally unter Kommunikation › Briefing.'); END IF;
  IF coalesce(p_aktion, '') NOT IN ('uhrzeit', 'jetzt') THEN RETURN jsonb_build_object('ok', true, 'briefings', liste); END IF;
  IF wahl = '' AND n = 1 THEN
    SELECT * INTO b FROM public.briefings x WHERE x.person = p_person AND x.geloescht_am IS NULL;
  ELSIF wahl <> '' THEN
    SELECT * INTO b FROM public.briefings x WHERE x.person = p_person AND x.geloescht_am IS NULL AND (x.id::text = wahl OR lower(x.name) = lower(wahl))
    ORDER BY (x.id::text = wahl) DESC, x.id LIMIT 1;
    IF NOT FOUND THEN
      SELECT * INTO b FROM public.briefings x WHERE x.person = p_person AND x.geloescht_am IS NULL AND strpos(lower(x.name), lower(wahl)) > 0
        AND (SELECT count(*) FROM public.briefings y WHERE y.person = p_person AND y.geloescht_am IS NULL AND strpos(lower(y.name), lower(wahl)) > 0) = 1;
    END IF;
  END IF;
  IF b.id IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'nachfragen', true, 'briefings', liste,
      'hinweis', 'Es gibt mehrere Briefings. Frag nach, welches gemeint ist, und nenne dann seinen Namen oder seine Nummer im Feld briefing.');
  END IF;
  IF p_aktion = 'jetzt' AND NOT b.an_mich THEN
    -- Stefan 06.11.2026: wer das Briefing bekommt, entscheidet die Besitzerin per „An mich“ – ohne Häkchen kein Auftrag, ehrliche Antwort
    RETURN jsonb_build_object('ok', false, 'briefing', b.name, 'jetzt', false,
      'hinweis', 'Das Briefing „' || b.name || '“ geht nicht an dich selbst (in der Kachel Empfänger ist „An mich“ aus). Einschalten kannst du es in Ally unter '
        || 'Kommunikation › Briefing › „' || b.name || '“ › Empfänger › „An mich“; „Jetzt erstellen“ auf der Seite geht auch ohne.');
  END IF;
  IF p_aktion = 'jetzt' THEN
    INSERT INTO public.briefing_jetzt (briefing_id, person) VALUES (b.id, p_person) ON CONFLICT (briefing_id, person) DO UPDATE SET angefordert_am = now();
    RETURN jsonb_build_object('ok', true, 'briefing', b.name, 'jetzt', true,
      'hinweis', 'Das Briefing „' || b.name || '“ kommt in den nächsten Minuten (spätestens in 15 Minuten)'
        || CASE WHEN b.chat THEN ' hier im Chat' ELSE '' END || ' und steht danach in Ally auf der Seite Briefing.');
  END IF;
  IF uz !~ '^([01]?[0-9]|2[0-3]):[0-5][0-9]$' THEN
    RETURN jsonb_build_object('ok', false, 'ungueltige_eingabe', true, 'briefing', b.name, 'uhrzeit', b.uhrzeit, 'hinweis', 'Bitte eine Uhrzeit im Format HH:MM nennen.');
  END IF;
  uz := lpad(split_part(uz, ':', 1), 2, '0') || ':' || lpad(((split_part(uz, ':', 2)::integer / 15) * 15)::text, 2, '0');
  UPDATE public.briefings SET uhrzeit = uz, geaendert_am = now(), geaendert_von = p_person WHERE id = b.id;
  RETURN jsonb_build_object('ok', true, 'briefing', b.name, 'uhrzeit', uz, 'geaendert', true, 'an', b.an, 'rhythmus', b.rhythmus,
    'heute_schon_verschickt', b.rhythmus = 'tag' AND EXISTS (SELECT 1 FROM public.briefing_laeufe l WHERE l.briefing_id = b.id AND l.person = p_person AND l.periode = heute AND l.status = 'ok'),
    'zeitplan', public.briefing_zeitplan_text(b.an, b.rhythmus, b.tag, uz));
END $function$;
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
  -- Migration 208 (eine Funktion „Briefing“, Stefan 06.11.2026): Tag und Uhrzeit der KI-Analyse entfallen hier; jedes Briefing stellt man auf der Seite Briefing ein.
  IF coalesce(d->>'abweichung_prozent', '') !~ '^[0-9]{1,3}$' OR (d->>'abweichung_prozent')::integer NOT BETWEEN 10 AND 90 THEN
    RETURN jsonb_build_object('ok', false, 'angemeldet', true, 'fehler', 'Die Schwelle für „deutlich abweichend“ muss zwischen 10 und 90 Prozent liegen.');
  END IF;
  IF coalesce(d->>'marken_anzahl', '') !~ '^[0-9]{1,2}$' OR (d->>'marken_anzahl')::integer NOT BETWEEN 1 AND 12 THEN
    RETURN jsonb_build_object('ok', false, 'angemeldet', true, 'fehler', 'Treffer je Marken-Suche: 1 bis 12.');
  END IF;
  IF coalesce(d->>'marken_websuchen', '') !~ '^[0-9]{1,2}$' OR (d->>'marken_websuchen')::integer NOT BETWEEN 1 AND 10 THEN
    RETURN jsonb_build_object('ok', false, 'angemeldet', true, 'fehler', 'Websuchen je Marken-Suche: 1 bis 10.');
  END IF;
  PERFORM ally_einstellung_setzen('talents_konzept_abweichung_prozent', ((d->>'abweichung_prozent')::integer)::text, u);
  PERFORM ally_einstellung_setzen('talents_markensuche_anzahl', ((d->>'marken_anzahl')::integer)::text, u);
  PERFORM ally_einstellung_setzen('talents_markensuche_websuchen', ((d->>'marken_websuchen')::integer)::text, u);
  RETURN jsonb_build_object('ok', true, 'angemeldet', true, 'meldung', 'Einstellungen gespeichert.');
END $function$;
-- Migration 208: Register, Rechte, Seiten und Übernahme ohne Datenverlust (alte Tabellen talents_briefings* bleiben unverändert stehen).
-- 1. Bausteine der ausgelieferten Pakete (Basispaket: modul NULL; Social-Media-Paket: modul talents, Recht „Briefing: Social Media“ = bisher „KI-Analysen“)
--    rechte_talent: für Talents als Empfänger nur mit diesen Rechten (Talent-Bereich). persoenlich: Daten aus der Sicht des Empfängers (eigene Mails, Termine,
--    sichtbare Talents) – solche Ergebnisse liest nur der Empfänger selbst (Prüfung H1: auch „Offene Aufgaben der Talents“).
INSERT INTO public.briefing_bausteine (schluessel, name, beschreibung, gruppe, modul, recht, rechte_talent, art, lesen, fertig, google, ki, persoenlich, optionen, standard, reihenfolge) VALUES
  ('termine', 'Termine', 'Termine des Tages aus dem Kalender in Ally und, falls hinterlegt, aus deinem Google-Kalender.', 'Kommunikation', NULL, NULL, NULL, 'sql', 'briefing_bs_termine', NULL, true, false, true, '[]', true, 10),
  ('kunden_mails', 'Mails von Kunden und Fristen (24 h)', 'Mails der Kundschaft und Mails mit Frist der letzten 24 Stunden aus deinen Postfächern.', 'Kommunikation', NULL, NULL, NULL, 'sql', 'briefing_bs_kunden_mails', NULL, false, false, true, '[]', true, 20),
  ('geschaeft_mails', 'Geschäftliche Mails (24 h)', 'Geschäftliche Mails (zum Beispiel Bank, Verträge, Behörden) der letzten 24 Stunden aus deinen Postfächern.', 'Kommunikation', NULL, NULL, NULL, 'sql', 'briefing_bs_geschaeft_mails', NULL, false, false, true, '[]', true, 30),
  ('talents_zahlen', 'Zahlen der Talents mit Vergleich', 'Reichweite, Interaktionen, Follower und Beiträge je Talent im gewählten Zeitraum, verglichen mit dem Zeitraum davor. Deine eigenen Talents sind immer dabei.', 'Social-Media Management', 'talents', 'briefings', ARRAY['talent_zahlen'], 'sql', 'briefing_bs_talents_zahlen', NULL, false, false, false,
     '[{"name": "talents", "art": "talents", "label": "Weitere Talents"}, {"name": "zeitraum", "art": "zeitraum", "label": "Zeitraum"}]', false, 110),
  ('talents_ki', 'KI-Einordnung', 'Die KI ordnet die Zahlen der Talents ein: was auffällt und worum du dich kümmern solltest (Talents und Zeitraum wie bei den Zahlen). Verursacht KI-Kosten.', 'Social-Media Management', 'talents', 'briefings', ARRAY['talent_zahlen'], 'ki', 'briefing_bs_talents_ki', 'briefing_bs_talents_ki_fertig', false, true, false, '[]', false, 120),
  ('talents_aufgaben', 'Offene Aufgaben und Termine der Talents', 'Offene Aufgaben, Reviews, Termine und Erinnerungen der Talents (überfällig und die nächsten 7 Tage) und anstehende Deadlines.', 'Social-Media Management', 'talents', 'briefings', ARRAY['talent_aufgaben', 'talent_termine'], 'sql', 'briefing_bs_talents_aufgaben', NULL, false, false, true, '[]', false, 130);

-- 2. Sicherung für den Rückbau (Stand vorher)
INSERT INTO public.briefing_m208_sicherung (art, schluessel, daten)
SELECT 'recht', x.schluessel, to_jsonb(x) FROM public.ally_rechte x WHERE x.schluessel IN ('morgen_briefing', 'briefings')
UNION ALL SELECT 'ui_funktion', x.schluessel, to_jsonb(x) FROM public.ally_ui_funktionen x WHERE x.schluessel IN ('morgen-briefing', 'briefings')
UNION ALL SELECT 'modul', x.schluessel, to_jsonb(x) FROM public.plattform_module x WHERE x.schluessel = 'morgen_briefing'
UNION ALL SELECT 'benachrichtigung_art', x.schluessel, to_jsonb(x) FROM public.ally_benachrichtigung_arten x WHERE x.schluessel = 'morgen_briefing'
UNION ALL SELECT 'funktion', x.schluessel, to_jsonb(x) FROM public.ally_funktionen x WHERE x.schluessel IN ('morgen_briefing', 'talents_briefing')
UNION ALL SELECT 'nutzer_funktion', x.matrix_user_id || '|' || x.schluessel, to_jsonb(x) FROM public.ally_nutzer_funktionen x WHERE x.schluessel IN ('morgen_briefing', 'talents_briefing')
UNION ALL SELECT 'rolle', x.schluessel, jsonb_build_object('rechte', to_jsonb(x.rechte), 'standard', x.standard) FROM public.ally_rollen x
  WHERE 'morgen_briefing' = ANY (x.rechte) OR coalesce(x.standard ? 'morgen_briefing', false) OR x.vorlage = 'management';

-- 3. Rechte: „Morgen-Briefing“ heißt „Briefing“ (Schlüssel briefing, Rollen und Ausnahmen übernommen); neu „Briefings für andere“ (Vorlagen Admin über admin,
--    Management ausdrücklich; Anwender und Mitarbeiter nicht). Wer das bisherige Recht „KI-Analysen“ hat, bekommt „Briefing“ dazu (die KI-Analysen stehen jetzt dort).
INSERT INTO public.ally_rechte (schluessel, name, beschreibung, sortierung, modul, katalog_gruppe, katalog_name, katalog_text, katalog_sortierung, reichweite, je_person, nur_selbst) VALUES
  ('briefing', 'Briefing', 'Seite Briefing nutzen: eigene Briefings anlegen, einstellen und lesen.', 63, 'morgen_briefing', 'Kommunikation', 'Briefing',
   'Seite Briefing nutzen: eigene Briefings anlegen, einstellen und lesen.', 140, false, false, false),
  ('briefing_andere', 'Briefings für andere', 'Briefings auch an andere Personen und an Talents zustellen.', 64, 'morgen_briefing', 'Kommunikation', 'Briefings für andere',
   'Briefings auch an andere Personen und an Talents zustellen (Empfänger wählen).', 141, false, false, false);
UPDATE public.ally_rechte SET name = 'Briefing: Social Media', katalog_name = 'Briefing: Social Media',
  beschreibung = 'Inhalte des Social-Media-Pakets (Zahlen der Talents, KI-Einordnung, offene Aufgaben) ins Briefing aufnehmen.',
  katalog_text = 'Inhalte des Social-Media-Pakets ins Briefing aufnehmen: Zahlen der Talents mit Vergleich, KI-Einordnung, offene Aufgaben und Termine der Talents.'
WHERE schluessel = 'briefings';
INSERT INTO public.briefing_m208_sicherung (art, schluessel, daten)
SELECT 'rolle_dazu', x.rolle || '|' || x.recht, jsonb_build_object('rolle', x.rolle, 'recht', x.recht) FROM (
  SELECT rr.rolle, 'briefing' AS recht FROM public.ally_rollen_rechte rr WHERE rr.recht = 'briefings'
    AND NOT EXISTS (SELECT 1 FROM public.ally_rollen_rechte r2 WHERE r2.rolle = rr.rolle AND r2.recht = 'morgen_briefing')
  UNION SELECT ro.schluessel, 'briefing' FROM public.ally_rollen ro WHERE ro.vorlage = 'management' AND ro.art = 'eigen'
    AND NOT EXISTS (SELECT 1 FROM public.ally_rollen_rechte r2 WHERE r2.rolle = ro.schluessel AND r2.recht = 'morgen_briefing')
  UNION SELECT ro.schluessel, 'briefing_andere' FROM public.ally_rollen ro WHERE ro.vorlage = 'management' AND ro.art = 'eigen') x
UNION ALL
SELECT 'person_dazu', pr.person, jsonb_build_object('person', pr.person, 'recht', 'briefing') FROM public.ally_person_rechte pr
WHERE pr.recht = 'briefings' AND pr.wirkung = 'plus' AND NOT EXISTS (SELECT 1 FROM public.ally_person_rechte p2 WHERE p2.person = pr.person AND p2.recht = 'morgen_briefing');
UPDATE public.ally_rollen_rechte SET recht = 'briefing' WHERE recht = 'morgen_briefing';
UPDATE public.ally_person_rechte SET recht = 'briefing' WHERE recht = 'morgen_briefing';
INSERT INTO public.ally_rollen_rechte (rolle, recht, reichweite) SELECT x.daten->>'rolle', x.daten->>'recht', NULL FROM public.briefing_m208_sicherung x WHERE x.art = 'rolle_dazu'
ON CONFLICT (rolle, recht) DO NOTHING;
INSERT INTO public.ally_person_rechte (person, recht, wirkung) SELECT x.daten->>'person', 'briefing', 'plus' FROM public.briefing_m208_sicherung x WHERE x.art = 'person_dazu'
ON CONFLICT (person, recht) DO NOTHING;
UPDATE public.ally_rollen SET rechte = array_replace(rechte, 'morgen_briefing', 'briefing') WHERE 'morgen_briefing' = ANY (rechte);
UPDATE public.ally_rollen SET standard = (standard - 'morgen_briefing') || jsonb_build_object('briefing', standard->'morgen_briefing') WHERE standard ? 'morgen_briefing';
UPDATE public.ally_rollen SET standard = coalesce(standard, '{}'::jsonb) || '{"briefing": null, "briefing_andere": null}'::jsonb WHERE vorlage = 'management' AND art = 'eigen';
UPDATE public.ally_rollen SET beschreibung = replace(beschreibung, 'Morgen-Briefing', 'Briefing') WHERE vorlage IN ('anwender', 'mitarbeiter') AND beschreibung LIKE '%Morgen-Briefing%';

-- 4. Seiten: Kommunikation › „Briefing“ (Seite morgen-briefing, ALLY 33, Recht briefing, ohne Eintrag unter Einstellungen › Funktionen); der alte Aufruf
--    der Seite KI-Analysen (briefings) führt zur Seite Briefing (ALLY 33 zeigt dort dieselbe Seite)
UPDATE public.ally_ui_funktionen SET recht = 'briefing', name = 'Briefing', beschreibung = 'Briefings nach Zeitplan oder sofort: Termine, wichtige Mails und Inhalte weiterer Bereiche.',
  einstellungen_ziel = NULL WHERE schluessel = 'morgen-briefing';
UPDATE public.ally_ui_funktionen SET name = 'Briefing', recht = 'briefing', modul = 'morgen_briefing', leiste_aktiv = 'morgen-briefing',
  workflow_id = (SELECT f.workflow_id FROM public.ally_ui_funktionen f WHERE f.schluessel = 'morgen-briefing') WHERE schluessel = 'briefings';
DELETE FROM public.ally_rechte WHERE schluessel = 'morgen_briefing';
UPDATE public.plattform_module SET name = 'Briefing', beschreibung = 'Briefings nach Zeitplan oder sofort: Termine, wichtige Mails und Inhalte weiterer Pakete, auf der Seite, im Chat, in der Glocke oder per Mail.'
WHERE schluessel = 'morgen_briefing';
UPDATE public.ally_benachrichtigung_arten SET name = 'Briefing', beschreibung = 'Ein Briefing ist fertig.' WHERE schluessel = 'morgen_briefing';

-- 5. Übernahme Morgen-Briefing: jede Person mit eingeschaltetem Morgen-Briefing oder mit dem Recht bekommt das „Tägliche Briefing“ (an wie bisher, gleiche Uhrzeit
--    im 15-Minuten-Raster, Inhalte wie heute, Zustellung Chat und Glocke). Der letzte Versand und Fehlversuche gelten als Lauf des Tages (kein doppelter Versand).
INSERT INTO public.briefings (person, name, an, rhythmus, tag, uhrzeit, chat, glocke, mail, standard, herkunft)
SELECT p.matrix_user_id, 'Tägliches Briefing', public.ally_funktion_an(p.matrix_user_id, 'morgen_briefing'), 'tag', 1,
  CASE WHEN coalesce(public.ally_nutzer_wert(p.matrix_user_id, 'briefing_uhrzeit'), '') ~ '^([01]?[0-9]|2[0-3]):[0-5][0-9]$'
       THEN lpad(split_part(public.ally_nutzer_wert(p.matrix_user_id, 'briefing_uhrzeit'), ':', 1), 2, '0') || ':'
            || lpad(((split_part(public.ally_nutzer_wert(p.matrix_user_id, 'briefing_uhrzeit'), ':', 2)::integer / 15) * 15)::text, 2, '0')
       ELSE '05:00' END,
  true, true, false, true, 'morgen_briefing'
FROM public.ally_personen p
-- nur Personen mit dem Recht „Briefing“ (Prüfung N-b), keine Talents
WHERE p.aktiv AND NOT p.testdaten AND public.briefing_darf(p.matrix_user_id) AND NOT public.ally_person_ist_talent(p.matrix_user_id);
INSERT INTO public.briefing_inhalte (briefing_id, baustein) SELECT b.id, x.schluessel FROM public.briefings b CROSS JOIN public.briefing_bausteine x
WHERE b.herkunft = 'morgen_briefing' AND x.standard AND x.modul IS NULL;
INSERT INTO public.ally_nutzer_einstellungen (matrix_user_id, schluessel, wert) SELECT b.person, 'briefing_standard', 'angelegt' FROM public.briefings b WHERE b.herkunft = 'morgen_briefing'
ON CONFLICT (matrix_user_id, schluessel) DO NOTHING;
INSERT INTO public.briefing_laeufe (briefing_id, person, periode, status, versuche)
SELECT b.id, b.person, 'T' || e.wert, 'ok', 1 FROM public.briefings b JOIN public.ally_nutzer_einstellungen e ON e.matrix_user_id = b.person AND e.schluessel = 'briefing_letzter_versand'
WHERE b.herkunft = 'morgen_briefing' AND e.wert ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
ON CONFLICT DO NOTHING;
INSERT INTO public.briefing_laeufe (briefing_id, person, periode, status, versuche)
SELECT b.id, b.person, 'T' || split_part(e.wert, ':', 1), 'fehler', least(greatest(split_part(e.wert, ':', 2)::integer, 1), 3)
FROM public.briefings b JOIN public.ally_nutzer_einstellungen e ON e.matrix_user_id = b.person AND e.schluessel = 'briefing_fehlversuche'
WHERE b.herkunft = 'morgen_briefing' AND e.wert ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}:[0-9]{1,6}$'
ON CONFLICT DO NOTHING;

-- 6. Übernahme KI-Analysen (talents_briefings): jede wird ein Briefing mit den Bausteinen „Zahlen der Talents“ (Talents und Zeitraum übernommen) und
--    „KI-Einordnung“; Zeitplan (aus = nur von Hand, Uhrzeit im 15-Minuten-Raster), Zustellung (Glocke immer wie bisher, dazu Chat bzw. Mail mit Absender, Betreff,
--    Text, Signatur, KI-Hinweis und Kennzeichen testdaten wie gespeichert), Papierkorb; Ergebnisse mit Kopf und Text übernommen, Läufe gemerkt.
--    a) mit anlegender Person: ein Briefing dieser Person (mit Teilen). Empfänger: die gewählten Personen fest (höchstens 500); „Zuständige“ wird „Alle Manager/innen
--       der Talents“ mit dem Kreis „alle aktiven Talents“ (Stefan 06.11.2026; wie bisher: Zuständige aller aktiven Talents, jede Person mit ihren eigenen Talents).
--       Wer den Schalter „Talents: KI-Analysen“ aus hatte, gilt als abbestellt (so bleibt die Wahl sichtbar). „An mich“ nur, wenn die Person sie bisher bekam
--       (heute im Kreis der Analyse oder mit eigenen Ergebnissen).
--       Fehlt ihr das Recht „Briefings für andere“, bekommt sie es als persönliche Ausnahme (sonst fielen die Empfänger still weg).
--    b) ohne anlegende Person (Standard-Analyse, Stefan 06.11.2026: die KI-Analyse ist ein Inhalt im Briefing der Person): jede Person, die sie bisher bekam
--       (talents_briefing_empfaenger: Zuständige mit eingeschaltetem Schalter, Rückfall auf Admins wie bisher), bekommt ein eigenes Briefing mit demselben Namen,
--       Inhalten, Zeitplan und derselben Zustellung; bekannte Personen, die früher Ergebnisse bekamen, heute aber nicht mehr, bekommen es ausgeschaltet (Verlauf bleibt
--       lesbar). Bisherige Ergebnisse und Läufe gehören zum Briefing der jeweiligen Person. Kein Briefing ohne echte Person, die es besitzt.
CREATE TEMP TABLE m208_ki ON COMMIT DROP AS
SELECT t.id AS alt_id, w.matrix_user_id AS person, true AS besitzer, true AS an,
  -- bisher Empfängerin: heute im Kreis der Analyse oder mit eigenen Ergebnissen (im Papierkorb: an)
  t.geloescht_am IS NOT NULL OR EXISTS (SELECT 1 FROM public.talents_briefing_empfaenger(t.id) e WHERE e.user_id = w.matrix_user_id)
    OR EXISTS (SELECT 1 FROM public.talents_briefing_ergebnisse r WHERE r.briefing_id = t.id AND r.person = w.matrix_user_id) AS an_mich
FROM public.talents_briefings t JOIN public.ally_personen w ON w.matrix_user_id = t.erstellt_von
WHERE t.art = 'manager'
UNION ALL
SELECT t.id, p.matrix_user_id, false, bool_or(q.aktuell), true
FROM public.talents_briefings t
CROSS JOIN LATERAL (SELECT e.user_id AS u, true AS aktuell FROM public.talents_briefing_empfaenger(t.id) e
                    UNION ALL SELECT r.person, false FROM public.talents_briefing_ergebnisse r WHERE r.briefing_id = t.id) q
JOIN public.ally_personen p ON p.matrix_user_id = q.u AND NOT public.ally_person_ist_talent(p.matrix_user_id)
WHERE t.art = 'manager' AND NOT EXISTS (SELECT 1 FROM public.ally_personen w WHERE w.matrix_user_id = t.erstellt_von)
GROUP BY t.id, p.matrix_user_id;
INSERT INTO public.briefings (person, name, an, rhythmus, tag, uhrzeit, empfaenger, manager, manager_kreis, an_mich, chat, glocke, mail, absender, mail_betreff, mail_html, signatur_an, signatur_html, ki_hinweis,
  testdaten, herkunft, alt_id, erstellt_am, erstellt_von, geaendert_am, geaendert_von, geloescht_am, geloescht_von)
SELECT k.person, t.name, k.an, CASE t.intervall WHEN 'aus' THEN 'hand' ELSE t.intervall END, CASE WHEN t.intervall = 'woche' THEN least(t.tag, 7) ELSE t.tag END,
  left(t.uhrzeit, 3) || lpad(((substr(t.uhrzeit, 4, 2)::integer / 15) * 15)::text, 2, '0'),
  CASE WHEN k.besitzer THEN (ARRAY(SELECT DISTINCT x COLLATE "C" FROM unnest(t.personen) x WHERE x <> k.person AND EXISTS (SELECT 1 FROM public.ally_personen p WHERE p.matrix_user_id = x)
                                   ORDER BY 1))[1:500]
       ELSE '{}' END,
  k.besitzer AND t.empfaenger = 'zustaendige', CASE WHEN k.besitzer AND t.empfaenger = 'zustaendige' THEN 'alle' ELSE 'briefing' END, k.an_mich,
  t.versand = 'chat', true, t.versand = 'mail', t.absender, t.mail_betreff, t.mail_html, t.signatur_an, t.signatur_html, t.ki_hinweis, coalesce(t.testdaten, false),
  CASE WHEN k.besitzer THEN 'ki_analyse' ELSE 'ki_analyse_person' END, t.id, t.erstellt_am, t.erstellt_von, t.geaendert_am, t.geaendert_von, t.geloescht_am, t.geloescht_von
FROM m208_ki k JOIN public.talents_briefings t ON t.id = k.alt_id
ORDER BY t.id, k.person;
INSERT INTO public.briefing_inhalte (briefing_id, baustein, optionen)
SELECT b.id, 'talents_zahlen', jsonb_build_object('talents', (SELECT coalesce(jsonb_agg(x::text ORDER BY x), '[]'::jsonb) FROM unnest(t.talents) x), 'zeitraum', t.zeitraum)
FROM public.briefings b JOIN public.talents_briefings t ON t.id = b.alt_id
UNION ALL SELECT b.id, 'talents_ki', '{}'::jsonb FROM public.briefings b WHERE b.alt_id IS NOT NULL;
INSERT INTO public.briefing_abbestellt (briefing_id, person, herkunft)
SELECT DISTINCT b.id, e.x, 'uebernahme' FROM public.briefings b
CROSS JOIN LATERAL (SELECT unnest(b.empfaenger) UNION SELECT public.briefing_manager(b.id)) e(x)
WHERE b.herkunft = 'ki_analyse' AND NOT public.ally_person_ist_talent(e.x) AND NOT coalesce(public.ally_funktion_an(e.x, 'talents_briefing'), false);
INSERT INTO public.ally_person_rechte (person, recht, wirkung)
SELECT DISTINCT b.person, 'briefing_andere', 'plus' FROM public.briefings b
WHERE b.herkunft = 'ki_analyse' AND b.geloescht_am IS NULL AND (cardinality(b.empfaenger) > 0 OR b.manager) AND NOT coalesce(public.ally_hat_recht(b.person, 'briefing_andere'), false)
ON CONFLICT DO NOTHING;
INSERT INTO public.briefing_teilen (briefing_id, person, geteilt_am, geteilt_von)
SELECT b.id, f.person, f.freigegeben_am, f.freigegeben_von FROM public.briefings b JOIN public.talents_briefing_freigaben f ON f.briefing_id = b.alt_id
WHERE b.herkunft = 'ki_analyse' AND f.person <> b.person;
INSERT INTO public.briefing_ergebnisse (briefing_id, person, erstellt_am, erstellt_von, nach_zeitplan, periode, inhalte, zeitraum, talents, stand_zahlen, zustellung, zugestellt, ki, text, html,
  uebernommen, alt_id)
SELECT b.id, r.person, r.erstellt_am, r.erstellt_von, r.nach_zeitplan, r.periode, ARRAY['talents_zahlen', 'talents_ki'],
  CASE WHEN r.von IS NOT NULL THEN jsonb_build_object(
    'text', to_char(r.von, CASE WHEN extract(year FROM r.von) = extract(year FROM r.bis) THEN 'DD.MM.' ELSE 'DD.MM.YYYY' END) || ' bis ' || to_char(r.bis, 'DD.MM.YYYY'),
    'vergleich_text', to_char(r.vergleich_von, CASE WHEN extract(year FROM r.vergleich_von) = extract(year FROM r.vergleich_bis) THEN 'DD.MM.' ELSE 'DD.MM.YYYY' END) || ' bis ' || to_char(r.vergleich_bis, 'DD.MM.YYYY'),
    'art', r.zeitraum) END,
  r.talents, r.stand_zahlen, '{}'::jsonb, coalesce(r.zugestellt, 'nur in Ally'), r.ki, left(r.text, 60000), left(r.html, 120000), r.uebernommen, r.id
FROM public.talents_briefing_ergebnisse r JOIN public.briefings b ON b.alt_id = r.briefing_id AND (b.herkunft = 'ki_analyse' OR b.person = r.person)
ORDER BY r.id;
INSERT INTO public.briefing_laeufe (briefing_id, person, periode, status, versuche)
SELECT DISTINCT b.id, r.person, r.periode, 'ok', 1 FROM public.talents_briefing_ergebnisse r JOIN public.briefings b ON b.alt_id = r.briefing_id AND (b.herkunft = 'ki_analyse' OR b.person = r.person)
WHERE r.nach_zeitplan AND r.periode IS NOT NULL
UNION SELECT b.id, l.person, 'W' || l.woche, 'ok', 1 FROM public.talents_briefing_laeufe l JOIN public.briefings b ON b.alt_id = l.briefing_id AND (b.herkunft = 'ki_analyse' OR b.person = l.person)
UNION SELECT b.id, e.matrix_user_id, 'W' || e.wert, 'ok', 1 FROM public.ally_nutzer_einstellungen e JOIN public.talents_briefings t ON t.standard
  JOIN public.briefings b ON b.alt_id = t.id AND (b.herkunft = 'ki_analyse' OR b.person = e.matrix_user_id) WHERE e.schluessel = 'talents_briefing_letzter_versand' AND e.wert ~ '^[0-9]{4}-[0-9]{2}$'
ON CONFLICT DO NOTHING;
SELECT setval(pg_get_serial_sequence('public.briefings', 'id'), greatest((SELECT max(id) FROM public.briefings), 1));

-- 7. Die Schalter „Morgen-Briefing“ und „Talents: KI-Analysen“ entfallen (ein- und ausgeschaltet wird je Briefing auf der Seite Briefing); gesichert für den Rückbau
DELETE FROM public.ally_nutzer_funktionen WHERE schluessel IN ('morgen_briefing', 'talents_briefing');
DELETE FROM public.ally_funktionen WHERE schluessel IN ('morgen_briefing', 'talents_briefing');
DO $m$
BEGIN
  IF (SELECT md5(string_agg(p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')|' || pg_get_function_result(p.oid) || '|' || md5(p.prosrc), E'\n' ORDER BY p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')' COLLATE "C")) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname::text = 'public' COLLATE "C" AND p.proname::text COLLATE "C" = ANY (ARRAY['talents_ki_einstellungen_aktion', 'briefing_periode', 'briefing_zeitplan_text', 'briefing_darf', 'briefing_talents_fuer', 'briefing_talents_waise', 'briefing_manager', 'briefing_empfaenger_alle', 'briefing_empfaenger', 'briefing_naechster', 'briefing_sichtbar', 'briefing_bausteine_fuer', 'briefing_ergebnis_lesbar', 'briefing_kopf', 'briefing_standard_anlegen', 'briefing_bs_termine', 'briefing_bs_kunden_mails', 'briefing_bs_geschaeft_mails', 'briefing_bs_talents_zahlen', 'briefing_bs_talents_ki', 'briefing_bs_talents_ki_fertig', 'briefing_bs_talents_aufgaben', 'briefing_mail_standard', 'briefing_mail_platzhalter', 'briefing_mail_normal', 'briefing_html_text', 'briefing_absender', 'briefing_mail_bauen', 'briefing_faellig', 'briefing_ergebnis_bauen', 'briefing_abschluss', 'briefing_web', 'briefing_ui_aktion', 'briefing_meldung', 'briefing_kachel', 'briefing_talent_ui', 'briefing_start_stand', 'briefing_chat'])) IS DISTINCT FROM '7c02d8684853ff5d7fa12f82af3a2b5f' THEN RAISE EXCEPTION 'Migration 208: Funktionen nicht wie gebaut'; END IF;
END $m$;
