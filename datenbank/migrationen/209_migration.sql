-- Migration 209 (Fehler 46, Stefan 06.11.2026): Adressen der Oberfläche ohne ?seite= – Seite und Objekt stehen im Pfad (z. B. /briefing/12, /einstellungen/team-und-rollen/personen/7).
-- a) Tabelle ally_ui_pfade (Zuordnung Seite ↔ Pfad an einer Stelle; Seitenschlüssel bleiben intern unverändert) mit den Mustern des Installationspakets.
-- b) neue Funktionen ally_ui_pfad, ally_ui_ort, ally_ui_link, ally_ui_pfade_liste, ally_ui_abfrage, ally_ui_pfad_teil, ally_ui_pfad_lesen;
--    ally_ui_filter mit Tabelle ally_ui_filter: Filter, Ansicht, Zeitraum und Blattseite je Person und Seite gemerkt (ein geteilter Link öffnet mit den eigenen).
-- c) Links in Mails (E-Mail bestätigen, Passwort, Zugang), im Zugangslink des Talents, in Chat-Nachrichten (Warnungen) und der Rückweg nach „Verbinden“ ohne ?seite=
--    (auf der eigenen Adresse der Oberfläche; unter /webhook/app bleibt die bisherige Form); Verbinden-Link: Parameter unternehmen statt seite.
-- Erst mit dem Merker adressen_pfade = an (setzen nur die Neuinstallation und der traefik-Befehl nach erfolgreicher Prüfung) gelten Pfade und leitet ALLY 20 alte
-- Adressen mit ?seite= dauerhaft (301) auf den Pfad um; ohne Merker (z. B. Update ohne traefik-Befehl) bleibt alles wie bisher.
-- Wächter vorher: Funktionen wie nach 208, keine Teile von 209, keine Sicherung aus Rückbau 209. Läuft als Ganzes in der Transaktion des Aufrufs (psql -1).
-- Rückbau: rueckbau209.sql.
DO $m$
BEGIN
  IF (SELECT md5(string_agg(p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')|' || pg_get_function_result(p.oid) || '|' || md5(p.prosrc), E'\n' ORDER BY p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')' COLLATE "C")) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname::text = 'public' COLLATE "C" AND p.proname::text COLLATE "C" = ANY (ARRAY['ally_systemnachricht_inhalt', 'talent_zugang_ui', 'talents_warnungen', 'talent_einladung_rueckweg', 'ally_ui_verbindung_link', 'ally_ui_pfad_teil', 'ally_ui_pfad_lesen', 'ally_ui_pfad', 'ally_ui_ort', 'ally_ui_abfrage', 'ally_ui_pfade_an', 'ally_ui_link', 'ally_ui_pfade_liste', 'ally_ui_filter'])) IS NOT DISTINCT FROM '20374df52ea8d161140fce5a70fe7ddc' THEN RAISE EXCEPTION 'Migration 209: schon eingespielt, nichts geändert'; END IF;
  IF (SELECT md5(string_agg(p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')|' || pg_get_function_result(p.oid) || '|' || md5(p.prosrc), E'\n' ORDER BY p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')' COLLATE "C")) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname::text = 'public' COLLATE "C" AND p.proname::text COLLATE "C" = ANY (ARRAY['ally_systemnachricht_inhalt', 'talent_zugang_ui', 'talents_warnungen', 'talent_einladung_rueckweg', 'ally_ui_verbindung_link', 'ally_ui_pfad_teil', 'ally_ui_pfad_lesen', 'ally_ui_pfad', 'ally_ui_ort', 'ally_ui_abfrage', 'ally_ui_pfade_an', 'ally_ui_link', 'ally_ui_pfade_liste', 'ally_ui_filter'])) IS DISTINCT FROM '871ff73c8c022d9329be0414da07d50d' THEN RAISE EXCEPTION 'Migration 209: Funktionen nicht im erwarteten Stand, nichts geändert'; END IF;
  IF to_regclass('public.ally_ui_pfade') IS NOT NULL OR to_regclass('public.ally_ui_pfade_rb209') IS NOT NULL OR to_regclass('public.ally_ui_filter') IS NOT NULL OR to_regclass('public.ally_ui_filter_rb209') IS NOT NULL THEN RAISE EXCEPTION 'Migration 209: Tabellen von 209 oder eine Sicherung aus Rückbau 209 gibt es schon, nichts geändert'; END IF;
END $m$;
-- Migration 209 (Fehler Nr. 46, Stefan 06.11.2026 „ich möchte nirgendwo in einer url so etwas sehen ?seite=…“): Zuordnung Seite ↔ Adresse an einer Stelle.
-- Je Zeile ein Muster: feste Teile (sichtbarer Seitenname klein, Umlaute ae/oe/ue/ss, Leerzeichen als Bindestrich) und Platzhalter {name} für die Kennung eines
-- Objekts (Parameter name). feste = Parameter, die das Muster festlegt (z. B. bereich der Einstellungen). rest = übrige Parameter als Abfrage anhängen (nur für
-- Endpunkte ohne eigene Seite: Herunterladen, Link). Filter, Ansicht und Blättern stehen nie in der Adresse. Seitenschlüssel bleiben intern unverändert.
-- Bei mehreren passenden Mustern gilt das mit den meisten festen Teilen bzw. Parametern, danach sortierung. Seiten ohne Zeile: /<Seitenschlüssel>.
-- Pfade, die der Webserver (traefik) für Ally freihält, beginnen nie ein Muster.
CREATE TABLE public.ally_ui_pfade (
  muster text PRIMARY KEY CHECK (length(muster) <= 200 AND (muster = '/' OR muster ~ '^(/([a-z0-9][a-z0-9-]{0,59}|\{[a-z0-9_]{1,30}\}))+$')
    AND muster !~ '^/(aktion|datei|manifest|symbol|kalender|stil|skript|logo|neu|api|mediakit|webhook)(/|$)' AND muster !~ '^/\{'),
  seite text NOT NULL CHECK (seite ~ '^[a-z0-9-]{1,40}$'),
  feste jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(feste) = 'object'),
  rest boolean NOT NULL DEFAULT false,
  sortierung integer NOT NULL DEFAULT 50,
  herkunft text NOT NULL DEFAULT 'm209'
);
CREATE INDEX ally_ui_pfade_seite ON public.ally_ui_pfade (seite);
COMMENT ON TABLE public.ally_ui_pfade IS 'Migration 209 (Fehler 46): Adresse je Seite und Objekt (ally_ui_pfad, ally_ui_ort, ally_ui_pfade_liste für Web-App und Abläufe).';

INSERT INTO public.ally_ui_pfade (muster, seite, feste, rest, sortierung) VALUES
  ('/', 'start', '{}', false, 10),
  ('/anordnen', 'start', '{"anordnen": "1"}', false, 10),
  -- Kommunikation
  ('/briefing', 'morgen-briefing', '{}', false, 10),
  ('/briefing/neu', 'morgen-briefing', '{"neu": "1"}', false, 10),
  ('/briefing/papierkorb', 'morgen-briefing', '{"papierkorb": "1"}', false, 10),
  ('/briefing/{briefing}', 'morgen-briefing', '{}', false, 20),
  ('/briefing/{briefing}/ergebnis/{ergebnis}', 'morgen-briefing', '{}', false, 20),
  ('/ki-analysen', 'briefings', '{}', false, 10),
  ('/ki-analysen/{briefing}', 'briefings', '{}', false, 20),
  ('/ki-analysen/{briefing}/ergebnis/{ergebnis}', 'briefings', '{}', false, 20),
  ('/system-mails', 'system-mails', '{}', false, 10),
  ('/mail-assistent', 'mail-assistent', '{}', false, 10),
  ('/planer', 'kalender', '{}', false, 10),
  ('/planer/termin/{termin}', 'kalender', '{}', false, 20),
  ('/fragen', 'fragen', '{}', false, 10),
  ('/benachrichtigungen', 'benachrichtigungen', '{}', false, 10),
  ('/benachrichtigungen/ergebnis/{er}', 'benachrichtigungen', '{}', false, 20),
  ('/ki-verbrauch', 'ki-verbrauch', '{}', false, 10),
  -- Social-Media Management
  ('/dashboard', 'talents', '{}', false, 10),
  ('/dashboard/papierkorb', 'talents', '{"papierkorb": "1"}', false, 10),
  ('/talent-profil/{id}', 'talent', '{}', false, 20),
  ('/kampagnen', 'kampagnen', '{}', false, 10),
  ('/kampagnen/papierkorb', 'kampagnen', '{"papierkorb": "1"}', false, 10),
  ('/kampagnen/{kampagne}', 'kampagnen', '{}', false, 20),
  ('/reports', 'talent-reports', '{}', false, 10),
  ('/reports/papierkorb', 'talent-reports', '{"papierkorb": "1"}', false, 10),
  ('/mein-bereich', 'talent-bereich', '{}', false, 10),
  ('/mein-bereich/ordner/{to}', 'talent-bereich', '{}', false, 20),
  -- Einstellungen (Bereiche mit ihrem Namen in der Leiste; weitere Bereiche als /einstellungen/<bereich>)
  ('/einstellungen', 'einstellungen', '{}', false, 10),
  ('/einstellungen/{bereich}', 'einstellungen', '{}', false, 90),
  ('/einstellungen/profil', 'einstellungen', '{"bereich": "profil"}', false, 10),
  ('/einstellungen/profil/e-mail-bestaetigen/{em}', 'einstellungen', '{"bereich": "profil"}', false, 20),
  ('/einstellungen/startseite', 'einstellungen', '{"bereich": "startseite"}', false, 10),
  ('/einstellungen/benachrichtigungen', 'einstellungen', '{"bereich": "benachrichtigungen"}', false, 10),
  ('/einstellungen/mein-kalender', 'einstellungen', '{"bereich": "kalender"}', false, 10),
  ('/einstellungen/unternehmen-und-design', 'einstellungen', '{"bereich": "unternehmen"}', false, 10),
  ('/einstellungen/team-und-rollen', 'einstellungen', '{"bereich": "team"}', false, 10),
  ('/einstellungen/team-und-rollen/personen/{person}', 'einstellungen', '{"bereich": "team"}', false, 20),
  ('/einstellungen/team-und-rollen/rollen/{rolle}', 'einstellungen', '{"bereich": "team"}', false, 20),
  ('/einstellungen/speicherorte', 'einstellungen', '{"bereich": "speicherorte"}', false, 10),
  ('/einstellungen/postfaecher', 'einstellungen', '{"bereich": "postfaecher"}', false, 10),
  ('/einstellungen/postfaecher/{postfach}', 'einstellungen', '{"bereich": "postfaecher"}', false, 20),
  ('/einstellungen/meine-postfaecher', 'einstellungen', '{"bereich": "meine-postfaecher"}', false, 10),
  ('/einstellungen/meine-postfaecher/{postfach}', 'einstellungen', '{"bereich": "meine-postfaecher"}', false, 20),
  ('/einstellungen/absender-regeln', 'einstellungen', '{"bereich": "regeln"}', false, 10),
  ('/einstellungen/ki-und-budget', 'einstellungen', '{"bereich": "ki"}', false, 10),
  ('/einstellungen/pakete', 'einstellungen', '{"bereich": "pakete"}', false, 10),
  ('/einstellungen/plattform-apps', 'einstellungen', '{"bereich": "plattform-apps"}', false, 10),
  ('/einstellungen/adressen', 'einstellungen', '{"bereich": "adressen"}', false, 10),
  ('/einstellungen/testdaten', 'einstellungen', '{"bereich": "testdaten"}', false, 10),
  ('/einstellungen/sicherung', 'einstellungen', '{"bereich": "sicherung"}', false, 10),
  ('/einstellungen/updates', 'einstellungen', '{"bereich": "updates"}', false, 10),
  ('/einstellungen/superadmin', 'einstellungen', '{"bereich": "superadmin"}', false, 10),
  ('/einstellungen/verbindungen', 'einstellungen', '{"bereich": "verbindungen"}', false, 10),
  ('/einstellungen/mail-assistent', 'einstellungen', '{"bereich": "mail-assistent"}', false, 10),
  ('/einstellungen/fragen', 'einstellungen', '{"bereich": "fragen"}', false, 10),
  ('/einstellungen/briefing', 'einstellungen', '{"bereich": "morgen-briefing"}', false, 10),
  ('/einstellungen/system-mails', 'einstellungen', '{"bereich": "system-mails"}', false, 10),
  ('/einstellungen/social-media-management', 'einstellungen', '{"bereich": "talents"}', false, 10),
  ('/einstellungen/kampagnen', 'einstellungen', '{"bereich": "kampagnen"}', false, 10),
  ('/einstellungen/reports', 'einstellungen', '{"bereich": "talent-reports"}', false, 10),
  -- Anmeldung
  ('/passwort-neu/{code}', 'passwort-neu', '{}', false, 20),
  ('/passwort-vergessen', 'passwort-vergessen', '{}', false, 10),
  -- Endpunkte ohne eigene Seite (Herunterladen über Ally, geprüfte Links): übrige Parameter als Abfrage
  ('/herunterladen/be/{be}', 'datei', '{}', true, 20),
  ('/herunterladen/er/{er}', 'datei', '{}', true, 20),
  ('/herunterladen/kl/{kl}', 'datei', '{}', true, 20),
  ('/herunterladen/mt/{mt}', 'datei', '{}', true, 20),
  ('/herunterladen/o/{o}', 'datei', '{}', true, 20),
  ('/herunterladen/sb/{sb}', 'datei', '{}', true, 20),
  ('/herunterladen/tr/{tr}', 'datei', '{}', true, 20),
  ('/herunterladen/ta/{ta}', 'datei', '{}', true, 20),
  ('/herunterladen/tx/{tx}', 'datei', '{}', true, 20),
  ('/herunterladen/mb/{mb}', 'datei', '{}', true, 20),
  ('/link/{art}', 'link', '{}', true, 20);

-- Gemerkte Filter je Person und Seite (Stefan 06.11.2026: „Filter merkt sich Ally je Person; ein geteilter Link öffnet mit den eigenen Filtern“): Filter, Ansicht,
-- Zeitraum und Blattseite stehen nicht in der Adresse. Je Person und Adresse ohne Abfrage (Seite und Objekt, z. B. /talent-profil/33) höchstens 1000 Byte;
-- je Person höchstens 200 Einträge (die ältesten fallen weg). Nur erlaubte Namen und Werte (ally_ui_filter). Klappzustand und Sortierung (ally_ui_zustand) und die
-- Ansicht des Kalenders (kalender_ansicht) merkt Ally wie bisher.
CREATE TABLE public.ally_ui_filter (
  person text NOT NULL,
  kennung text NOT NULL CHECK (length(kennung) BETWEEN 1 AND 300 AND left(kennung, 1) = '/'),
  seite text NOT NULL CHECK (seite ~ '^[a-z0-9-]{1,40}$'),
  werte jsonb NOT NULL CHECK (jsonb_typeof(werte) = 'object' AND octet_length(werte::text) <= 1000),
  geaendert_am timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (person, kennung)
);
COMMENT ON TABLE public.ally_ui_filter IS 'Migration 209 (Fehler 46): gemerkte Filter je Person und Seite (ally_ui_filter); nicht in der Adresse.';
CREATE OR REPLACE FUNCTION public.ally_ui_pfad_teil(p_wert text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
AS $function$
  -- Migration 209 (Fehler 46): ein Teil einer Adresse (Kennung eines Objekts), Prozent-kodiert wie encodeURIComponent; @ und : bleiben lesbar
  -- (erlaubt in Pfaden, z. B. Postfach team@firma.de oder Person @anna:chat). Gleiche Regel in der Web-App (webapp/src/pfade.ts) und in den Abläufen.
  SELECT coalesce(string_agg(CASE WHEN t.z ~ '^[A-Za-z0-9._~!*''()@:-]$' THEN t.z
    ELSE (SELECT string_agg('%' || upper(lpad(to_hex(get_byte(convert_to(t.z, 'UTF8'), i)), 2, '0')), '' ORDER BY i)
          FROM generate_series(0, octet_length(convert_to(t.z, 'UTF8')) - 1) i) END, '' ORDER BY t.n), '')
  FROM regexp_split_to_table(coalesce(p_wert, ''), '') WITH ORDINALITY t(z, n)
  WHERE t.z <> ''
$function$;
CREATE OR REPLACE FUNCTION public.ally_ui_pfad_lesen(p_teil text)
 RETURNS text
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
DECLARE b bytea := ''::bytea; m text[];
BEGIN
  -- Migration 209 (Fehler 46): Prozent-Kodierung eines Adressteils auflösen (UTF-8); ungültig = NULL
  FOR m IN SELECT x FROM regexp_matches(coalesce(p_teil, ''), '%[0-9A-Fa-f]{2}|[^%]+|%', 'g') x LOOP
    IF m[1] ~ '^%[0-9A-Fa-f]{2}$' THEN b := b || decode(substr(m[1], 2), 'hex');
    ELSIF m[1] = '%' THEN RETURN NULL;
    ELSE b := b || convert_to(m[1], 'UTF8'); END IF;
  END LOOP;
  RETURN convert_from(b, 'UTF8');
EXCEPTION WHEN OTHERS THEN
  RETURN NULL;
END $function$;
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
CREATE OR REPLACE FUNCTION public.ally_ui_ort(p_pfad text)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
  pf text := split_part(split_part(coalesce(p_pfad, ''), '?', 1), '#', 1); t text[]; r record; mt text[]; par jsonb; bl integer := -1; nl integer; ok boolean;
  bseite text; bpar jsonb; i integer; w text;
BEGIN
  -- Migration 209 (Fehler 46, Stefan 06.11.2026): Seite und Parameter zu einer Adresse (Pfad ab /) aus ally_ui_pfade. Es zählt das passende Muster mit den meisten
  -- festen Teilen (bei Gleichstand sortierung). Ein einzelner Teil ohne Muster gilt als Seitenschlüssel (Seiten von Zusatzpaketen), sonst seite unbekannt.
  IF pf = '' OR pf = '/' THEN RETURN jsonb_build_object('seite', 'start', 'parameter', '{}'::jsonb); END IF;
  IF left(pf, 1) <> '/' OR length(pf) > 1000 OR pf ~ '//' THEN RETURN jsonb_build_object('seite', 'unbekannt', 'parameter', '{}'::jsonb); END IF;
  pf := regexp_replace(pf, '/$', '');
  t := string_to_array(substr(pf, 2), '/');
  -- Pfade, die der Webserver für Ally freihält, sind nie eine Seite (Prüfung N-e)
  IF t[1] IN ('aktion', 'datei', 'manifest', 'symbol', 'kalender', 'stil', 'skript', 'logo', 'neu', 'api', 'mediakit', 'webhook') THEN
    RETURN jsonb_build_object('seite', 'unbekannt', 'parameter', '{}'::jsonb);
  END IF;
  FOR i IN 1 .. cardinality(t) LOOP
    t[i] := public.ally_ui_pfad_lesen(t[i]);
    IF t[i] IS NULL OR t[i] = '' OR t[i] ~ '[\x01-\x1f\x7f]' OR length(t[i]) > 200 THEN RETURN jsonb_build_object('seite', 'unbekannt', 'parameter', '{}'::jsonb); END IF;
  END LOOP;
  FOR r IN SELECT x.* FROM public.ally_ui_pfade x WHERE x.muster <> '/' ORDER BY x.sortierung, x.muster COLLATE "C" LOOP
    mt := string_to_array(substr(r.muster, 2), '/');
    CONTINUE WHEN cardinality(mt) <> cardinality(t);
    ok := true; par := r.feste; nl := 0;
    FOR i IN 1 .. cardinality(mt) LOOP
      IF mt[i] ~ '^\{[a-z0-9_]+\}$' THEN par := par || jsonb_build_object(substr(mt[i], 2, length(mt[i]) - 2), t[i]);
      ELSIF mt[i] = t[i] THEN nl := nl + 1;
      ELSE ok := false; EXIT; END IF;
    END LOOP;
    IF ok AND nl > bl THEN bl := nl; bseite := r.seite; bpar := par; END IF;
  END LOOP;
  IF bseite IS NOT NULL THEN RETURN jsonb_build_object('seite', bseite, 'parameter', bpar); END IF;
  IF cardinality(t) = 1 AND t[1] ~ '^[a-z0-9-]{1,40}$' AND t[1] NOT IN ('start', 'unbekannt') THEN RETURN jsonb_build_object('seite', t[1], 'parameter', '{}'::jsonb); END IF;
  RETURN jsonb_build_object('seite', 'unbekannt', 'parameter', '{}'::jsonb);
END $function$;
CREATE OR REPLACE FUNCTION public.ally_ui_abfrage(p_seite text, p_parameter jsonb)
 RETURNS text
 LANGUAGE sql
 STABLE
AS $function$
  -- Migration 209 (Fehler 46): bisherige Form der Adresse (Abfrage mit Seitenschlüssel) – nur noch für Installationen ohne eigene Adresse der Oberfläche
  -- (unter /webhook/app gibt es keine Pfade).
  SELECT coalesce('?' || nullif(concat_ws('&', CASE WHEN coalesce(p_seite, 'start') <> 'start' THEN 'seite=' || public.ally_ui_pfad_teil(p_seite) END,
    (SELECT string_agg(public.ally_ui_pfad_teil(e.key) || '=' || public.ally_ui_pfad_teil(e.value #>> '{}'), '&' ORDER BY e.key COLLATE "C")
     FROM jsonb_each(CASE WHEN jsonb_typeof(p_parameter) = 'object' THEN p_parameter ELSE '{}'::jsonb END) e
     WHERE jsonb_typeof(e.value) IN ('string', 'number', 'boolean') AND (e.value #>> '{}') <> '')), ''), '')
$function$;
CREATE OR REPLACE FUNCTION public.ally_ui_pfade_an()
 RETURNS boolean
 LANGUAGE sql
 STABLE
AS $function$
  -- Migration 209 (Fehler 46; Prüfung H-1): Adressen als Pfad nur, wenn der Webserver die Regel dafür hat. Den Merker (Einstellung adressen_pfade = an) setzen nur
  -- die Neuinstallation (installieren.sh, docker-compose.yml mit Regel) und die traefik-Befehle nach erfolgreicher Prüfung; --zurueck schaltet ihn aus.
  -- Ohne Merker (z. B. nach einem Update ohne traefik-Befehl) bleibt alles wie bisher mit ?seite= (keine Umleitung, Links in Mails wie bisher).
  SELECT coalesce(public.ally_einstellung('adressen_pfade'), 'aus') = 'an' AND public.ally_oberflaeche_adresse() IS NOT NULL
$function$;
CREATE OR REPLACE FUNCTION public.ally_ui_link(p_seite text, p_parameter jsonb)
 RETURNS text
 LANGUAGE sql
 STABLE
AS $function$
  -- Migration 209 (Fehler 46, Stefan 06.11.2026): vollständige Adresse einer Seite für Mails, Chat-Nachrichten und Zugangslinks: auf der eigenen Adresse der
  -- Oberfläche als Pfad (ohne ?seite=), sonst wie bisher unter /webhook/app (dort gibt es keine Pfade). NULL, wenn keine Adresse eingerichtet ist.
  -- Ohne Merker adressen_pfade (ally_ui_pfade_an) wie bisher: Adresse der Oberfläche (eigene oder unter /webhook/app) mit ?seite=.
  SELECT CASE WHEN public.ally_ui_pfade_an() THEN public.ally_oberflaeche_adresse() || public.ally_ui_pfad(p_seite, p_parameter)
              WHEN public.talent_ui_adresse() IS NOT NULL THEN public.talent_ui_adresse() || public.ally_ui_abfrage(p_seite, p_parameter) END
$function$;
CREATE OR REPLACE FUNCTION public.ally_ui_pfade_liste()
 RETURNS jsonb
 LANGUAGE sql
 STABLE
AS $function$
  -- Migration 209 (Fehler 46): die Zuordnung für Web-App und Abläufe (ALLY 20 gibt sie der Hülle der Web-App und dem Baukasten mit):
  -- m = Muster, s = Seitenschlüssel, f = feste Parameter, r = übrige Parameter als Abfrage; geordnet wie in ally_ui_pfad.
  SELECT coalesce(jsonb_agg(jsonb_build_object('m', x.muster, 's', x.seite, 'f', x.feste, 'r', x.rest) ORDER BY x.sortierung, x.muster COLLATE "C"), '[]'::jsonb)
  FROM public.ally_ui_pfade x
$function$;
CREATE OR REPLACE FUNCTION public.ally_ui_filter(p_token text, p_seite text, p_parameter jsonb, p_ausdruecklich boolean)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
  s record; kenn text; F jsonb := '{}'::jsonb; e record; frei text[]; gemerkt jsonb; n integer;
  P jsonb := CASE WHEN jsonb_typeof(p_parameter) = 'object' THEN p_parameter ELSE '{}'::jsonb END;
BEGIN
  -- Migration 209 (Fehler 46, Stefan 06.11.2026 „Filter merkt sich Ally je Person; ein geteilter Link öffnet mit den eigenen Filtern“): Filter, Ansicht, Zeitraum und
  -- Blattseite (p = Tabelle:Seite) einer Seite je Person und Adresse (Seite und Objekt). ALLY 20 ruft sie bei jedem Laden einer Seite auf der eigenen Adresse auf:
  --   hat die Person die Filter ausdrücklich gesetzt (p_ausdruecklich: Filterwechsel in der Web-App, auch „alles zurück“; nur von derselben Oberfläche, Prüfung N-c),
  --   werden sie gemerkt (leer = Merker weg); stehen Filter in der Anfrage (z. B. ein Link mit Filter), gelten sie, ohne gemerkt zu werden; sonst kommen die
  --   gemerkten Filter zurück (ALLY 20 setzt sie ein).
  -- Nur erlaubte Namen (keine Kennungen der Seite, keine Fenster oder Aktionen) und einfache Werte; Klappzustand, Sortierung und Kalenderansicht nicht (eigener Weg).
  SELECT * INTO s FROM public.ally_ui_sitzung(p_token) y WHERE NOT y.muss_pw_setzen;
  IF NOT FOUND OR coalesce(p_seite, '') !~ '^[a-z0-9-]{1,40}$' OR p_seite IN ('unbekannt', 'datei', 'link', 'passwort-neu', 'passwort-vergessen') THEN RETURN '{}'::jsonb; END IF;
  -- Parameter, die die Adresse aufnimmt (Kennung des Objekts, feste Parameter), sind keine Filter
  frei := ARRAY(SELECT DISTINCT m[1] FROM public.ally_ui_pfade x CROSS JOIN LATERAL regexp_matches(x.muster, '\{([a-z0-9_]+)\}', 'g') m WHERE x.seite = p_seite
                UNION SELECT DISTINCT k FROM public.ally_ui_pfade x CROSS JOIN LATERAL jsonb_object_keys(x.feste) k WHERE x.seite = p_seite);
  FOR e IN SELECT j.key, j.value #>> '{}' AS w FROM jsonb_each(P) j WHERE jsonb_typeof(j.value) IN ('string', 'number') ORDER BY j.key COLLATE "C" LOOP
    CONTINUE WHEN e.key = ANY (frei) OR (p_seite = 'kalender' AND e.key IN ('ansicht', 'datum'));
    IF e.key = 'p' AND e.w ~ '^[a-z0-9-]{1,40}:[0-9]{1,5}$' THEN F := F || jsonb_build_object('p', e.w);
    ELSIF e.key IN ('status', 'w', 'm', 'blatt', 'zeitraum', 'tage', 'ansicht', 'quelle', 'archiv', 'filter', 'kampagne', 'talent') AND e.w ~ '^[A-Za-z0-9_.:,-]{1,60}$' THEN
      F := F || jsonb_build_object(e.key, e.w);
    END IF;
  END LOOP;
  kenn := left(public.ally_ui_pfad(p_seite, P - ARRAY(SELECT jsonb_object_keys(F))), 300);
  IF NOT coalesce(p_ausdruecklich, false) AND F <> '{}'::jsonb THEN RETURN '{}'::jsonb; END IF;
  IF coalesce(p_ausdruecklich, false) THEN
    IF F = '{}'::jsonb THEN
      DELETE FROM public.ally_ui_filter x WHERE x.person = s.person AND x.kennung = kenn;
    ELSIF octet_length(F::text) <= 1000 THEN
      INSERT INTO public.ally_ui_filter AS x (person, kennung, seite, werte) VALUES (s.person, kenn, p_seite, F)
      ON CONFLICT (person, kennung) DO UPDATE SET werte = EXCLUDED.werte, seite = EXCLUDED.seite, geaendert_am = now()
      WHERE x.werte IS DISTINCT FROM EXCLUDED.werte;
      SELECT count(*) INTO n FROM public.ally_ui_filter x WHERE x.person = s.person;
      IF n > 200 THEN
        DELETE FROM public.ally_ui_filter x WHERE x.person = s.person AND x.kennung IN (
          SELECT y.kennung FROM public.ally_ui_filter y WHERE y.person = s.person ORDER BY y.geaendert_am, y.kennung COLLATE "C" LIMIT n - 200);
      END IF;
    END IF;
    RETURN '{}'::jsonb;
  END IF;
  SELECT x.werte INTO gemerkt FROM public.ally_ui_filter x WHERE x.person = s.person AND x.kennung = kenn;
  -- beim Lesen noch einmal prüfen (Regeln können sich geändert haben)
  RETURN coalesce((SELECT jsonb_object_agg(j.key, j.value) FROM jsonb_each(coalesce(gemerkt, '{}'::jsonb)) j
                   WHERE jsonb_typeof(j.value) = 'string' AND NOT j.key = ANY (frei)
                     AND ((j.key = 'p' AND (j.value #>> '{}') ~ '^[a-z0-9-]{1,40}:[0-9]{1,5}$')
                          OR (j.key IN ('status', 'w', 'm', 'blatt', 'zeitraum', 'tage', 'ansicht', 'quelle', 'archiv', 'filter', 'kampagne', 'talent')
                              AND (j.value #>> '{}') ~ '^[A-Za-z0-9_.:,-]{1,60}$' AND NOT (p_seite = 'kalender' AND j.key = 'ansicht')))), '{}'::jsonb);
END $function$;
CREATE OR REPLACE FUNCTION public.ally_systemnachricht_inhalt(p_id bigint, p_tok text, p_stand jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
  q ally_systemnachrichten%ROWTYPE; a talent_aufgaben%ROWTYPE; cd jsonb; f jsonb; m jsonb;   -- Migration 192: m
  basis text := talent_ui_adresse(); produkt text := produkt_name(); firma text; absender text := coalesce(p_stand->>'name', ''); adr text := coalesce(p_stand->>'adresse', '');
  name text; betreff text; vor text[] := '{}'; details text[] := '{}'; nach text[] := '{}'; knopf text; link text; ics text; bis timestamptz;
  dunkel text; hell text; schrift text; txt text; html text; mit_bereich boolean;
  ki boolean := coalesce(ally_einstellung('ki_hinweis_system'), 'aus') = 'an';  -- Migration 96: KI-Hinweis (Einstellung, Standard aus)
BEGIN
  -- Inhalt einer Systemnachricht (BA8): Betreff, Text, HTML im Corporate Design (Farben aus cd_daten), bei Terminen eine .ics-Datei. Neutral und genderneutral,
  -- Absendername aus den Einstellungen, nie im Namen einer Person. Links mit Geheimcode nur hier (aus dem entschlüsselten Code); NULL = nicht (mehr) sendbar.
  SELECT * INTO q FROM ally_systemnachrichten x WHERE x.id = p_id;
  IF q.id IS NULL OR absender = '' THEN RETURN NULL; END IF;
  -- Migration 192: Einladung zum Verbinden der Accounts (talent_einladung_mail, Systemweg: CD mit Logo, Knopf „Accounts verbinden“, Textteil, Fußzeile)
  IF q.art = 'einladung' THEN
    m := talent_einladung_mail(q.einladung_id, 'system', q.erstellt_von, NULL, true);
    IF NOT coalesce((m->>'ok')::boolean, false) THEN RETURN NULL; END IF;
    RETURN jsonb_build_object('betreff', m->>'betreff', 'text', m->>'text', 'html', m->>'html', 'ics', NULL, 'ics_name', NULL);
  END IF;
  firma := coalesce(nullif(btrim(coalesce(eigenes_unternehmen()->>'name', '')), ''), produkt);
  name := CASE WHEN q.person IS NOT NULL THEN (SELECT y.name FROM ally_personen y WHERE y.matrix_user_id = q.person)
               ELSE coalesce(talent_anzeigename(q.talent_id), talent_listenname(q.talent_id)) END;
  IF q.art = 'email_aendern' THEN
    -- Migration 70: Bestätigung im Profil der neuen Oberfläche (nur mit der eigenen Anmeldung)
    IF basis IS NULL OR coalesce(p_tok, '') !~ '^[0-9a-f]{64}$' THEN RETURN NULL; END IF;
    -- Migration 209 (Fehler 46, Stefan 06.11.2026): Adresse als Pfad (ally_ui_link: auf der eigenen Adresse der Oberfläche ohne Seitenschlüssel in der Abfrage)
    link := public.ally_ui_link('einstellungen', jsonb_build_object('bereich', 'profil', 'em', p_tok));
  ELSIF q.art IN ('zugang_talent', 'zugang_person', 'passwort') THEN
    IF basis IS NULL OR coalesce(p_tok, '') !~ '^[0-9a-f]{64}$' THEN RETURN NULL; END IF;
    link := public.ally_ui_link('passwort-neu', jsonb_build_object('code', p_tok));   -- Migration 209 (Fehler 46, Stefan 06.11.2026)
  END IF;
  IF q.art = 'test' THEN
    betreff := 'Testnachricht von ' || produkt;
    vor := ARRAY['diese Testnachricht zeigt, dass ' || produkt || ' Systemnachrichten über das Absender-Postfach ' || adr || ' versenden kann. Du musst nichts weiter tun.'];
  ELSIF q.art = 'zugang_talent' THEN
    SELECT z.einladung_bis INTO bis FROM talent_zugaenge z WHERE z.talent_id = q.talent_id;
    betreff := 'Dein Zugang bei ' || firma;
    vor := ARRAY['für dich ist ein eigener Bereich bei ' || firma || ' eingerichtet. Dort siehst du deine Aufgaben, Termine und Kampagnen und verbindest deine Accounts selbst.',
                 'Über den folgenden Link legst du dein Passwort fest. Der Link gilt bis ' || coalesce(talents_zeit(bis), '–') || ' und nur einmal.'];
    nach := ARRAY['Danach meldest du dich mit dieser E-Mail-Adresse und deinem Passwort hier an: ' || basis];
    knopf := 'Passwort festlegen';
  ELSIF q.art = 'zugang_person' THEN
    betreff := 'Dein Zugang zu ' || produkt;
    vor := ARRAY['für dich ist ein Zugang zu ' || produkt || ' bei ' || firma || ' eingerichtet.',
                 'Über den folgenden Link legst du dein Passwort fest. Der Link gilt sieben Tage und nur einmal.'];
    nach := ARRAY['Danach meldest du dich mit dieser E-Mail-Adresse und deinem Passwort hier an: ' || basis];
    knopf := 'Passwort festlegen';
  ELSIF q.art = 'email_aendern' THEN
    betreff := 'Neue E-Mail-Adresse für ' || produkt || ' bestätigen';
    vor := ARRAY['jemand, vermutlich du, möchte diese E-Mail-Adresse für die Anmeldung bei ' || produkt || ' verwenden. Über den folgenden Link bestätigst du das; '
      || 'dafür meldest du dich wie bisher an. Der Link gilt 24 Stunden und nur einmal.'];
    nach := ARRAY['Wenn du das nicht angefordert hast, kannst du diese Mail ignorieren. Es ändert sich dann nichts.'];
    knopf := 'E-Mail-Adresse bestätigen';
  ELSIF q.art = 'passwort' THEN
    betreff := 'Neues Passwort für ' || produkt;
    vor := ARRAY['jemand, vermutlich du, möchte ein neues Passwort für ' || produkt || ' festlegen. Über den folgenden Link geht das. Der Link gilt eine Stunde und nur einmal.'];
    nach := ARRAY['Wenn du das nicht angefordert hast, kannst du diese Mail ignorieren. Dein bisheriges Passwort bleibt dann gültig.'];
    knopf := 'Neues Passwort festlegen';
  ELSIF q.art = 'aufgabe' THEN
    SELECT * INTO a FROM talent_aufgaben x WHERE x.id = q.aufgabe_id;
    IF a.id IS NULL THEN RETURN NULL; END IF;
    mit_bereich := basis IS NOT NULL AND EXISTS (SELECT 1 FROM talent_zugaenge z WHERE z.talent_id = a.talent_id AND z.aktiv AND z.pw_hash IS NOT NULL);
    betreff := CASE WHEN a.status = 'abgesagt' THEN talents_planung_art_text(a.art) || ' abgesagt: '
                    WHEN a.art = 'erinnerung' THEN 'Erinnerung: '
                    WHEN a.art = 'termin' THEN CASE WHEN q.aufgabe_sequenz > 0 THEN 'Termin geändert: ' ELSE 'Neuer Termin: ' END
                    WHEN a.art = 'review' THEN CASE WHEN q.aufgabe_sequenz > 0 THEN 'Review geändert: ' ELSE 'Review zu Content: ' END
                    ELSE CASE WHEN q.aufgabe_sequenz > 0 THEN 'Aufgabe geändert: ' ELSE 'Neue Aufgabe: ' END END || a.titel;
    vor := ARRAY[CASE WHEN a.status = 'abgesagt' THEN 'dieser Eintrag ist abgesagt:' WHEN a.art = 'erinnerung' THEN 'eine Erinnerung von ' || firma || ':'
                      WHEN q.aufgabe_sequenz > 0 THEN 'ein Eintrag für dich wurde geändert:' ELSE 'es gibt einen neuen Eintrag für dich:' END];
    details := array_remove(ARRAY['Was: ' || a.titel,
      CASE WHEN coalesce(a.beginn, a.faellig_am) IS NOT NULL THEN CASE WHEN a.art IN ('aufgabe', 'review') THEN 'Bis: ' ELSE 'Wann: ' END
        || talents_planung_zeit_text(coalesce(a.beginn, a.faellig_am), a.ganztags)
        || CASE WHEN a.art = 'termin' AND a.ende IS NOT NULL THEN ' bis ' || talents_planung_zeit_text(a.ende, a.ganztags) ELSE '' END END,
      CASE WHEN a.ort IS NOT NULL THEN 'Ort: ' || a.ort END,
      (SELECT 'Kampagne: ' || k.marke || ' – ' || k.name FROM talent_kampagnen k WHERE k.id = a.kampagne_id),
      (SELECT 'Deliverable: ' || talents_planung_deliverable_name(d.format, d.anzahl, d.titel) FROM talent_deliverables d WHERE d.id = a.deliverable_id)], NULL);
    nach := array_remove(ARRAY[nullif(btrim(a.text), ''),
      CASE WHEN a.art = 'termin' AND a.status <> 'abgesagt' THEN 'Im Anhang steht der Termin als Kalenderdatei (.ics) zum Übernehmen in deinen Kalender.' END,
      CASE WHEN mit_bereich THEN 'Mehr dazu in deinem Bereich: ' || basis END], NULL);
    IF a.art = 'termin' THEN
      ics := ally_ics_datei(ally_ics_aufgabe(a.id, false));
    END IF;
  ELSE
    RETURN NULL;
  END IF;
  -- Text
  txt := 'Hallo' || coalesce(' ' || nullif(btrim(name), ''), '') || ',' || E'\n\n' || array_to_string(vor, E'\n\n')
    || CASE WHEN cardinality(details) > 0 THEN E'\n\n' || array_to_string(details, E'\n') ELSE '' END
    || CASE WHEN link IS NOT NULL THEN E'\n\n' || link ELSE '' END
    || CASE WHEN cardinality(nach) > 0 THEN E'\n\n' || array_to_string(nach, E'\n\n') ELSE '' END
    || E'\n\nViele Grüße\n' || absender || CASE WHEN ki THEN E'\n\nErstellt mit KI-Unterstützung.' ELSE '' END || E'\n\n--\nDiese Nachricht wurde automatisch versendet.';
  -- HTML im Corporate Design (Farben und Schrift aus cd_daten, sonst neutral)
  cd := cd_daten(NULL); f := coalesce(cd->'farben', '{}'::jsonb);
  dunkel := CASE WHEN coalesce(f->>'farbe_dunkel', '') ~ '^#[0-9A-Fa-f]{6}$' THEN f->>'farbe_dunkel' ELSE '#1F2933' END;
  hell := CASE WHEN coalesce(f->>'farbe_text_auf_dunkel', '') ~ '^#[0-9A-Fa-f]{6}$' THEN f->>'farbe_text_auf_dunkel' ELSE '#FFFFFF' END;
  schrift := CASE WHEN coalesce(cd->>'schrift', '') ~ '^[A-Za-z0-9 ]{1,60}$' THEN '''' || (cd->>'schrift') || ''',' ELSE '' END;
  html := '<!doctype html><html lang="de"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>' || ally_html(betreff) || '</title></head>'
    || '<body style="margin:0;padding:24px 12px;background:#F4F5F7;font-family:' || schrift || 'Arial,Helvetica,sans-serif;color:#1F2933">'
    || '<div style="max-width:560px;margin:0 auto;background:#FFFFFF;border:1px solid #E1E4E8;border-radius:10px;overflow:hidden">'
    || '<div style="background:' || dunkel || ';color:' || hell || ';padding:14px 20px;font-size:18px;font-weight:700">' || ally_html(firma) || '</div>'
    || '<div style="padding:20px;font-size:15px;line-height:1.5">'
    || '<p style="margin:0 0 14px">Hallo' || coalesce(' ' || ally_html(nullif(btrim(name), '')), '') || ',</p>'
    || coalesce((SELECT string_agg('<p style="margin:0 0 14px">' || replace(ally_html(x), E'\n', '<br>') || '</p>', '' ORDER BY o) FROM unnest(vor) WITH ORDINALITY AS u(x, o)), '')
    || CASE WHEN cardinality(details) > 0 THEN '<p style="margin:0 0 14px">' || array_to_string(ARRAY(SELECT ally_html(x) FROM unnest(details) x), '<br>') || '</p>' ELSE '' END
    || CASE WHEN link IS NOT NULL THEN '<p style="margin:18px 0"><a href="' || ally_html(link) || '" style="display:inline-block;background:' || dunkel || ';color:' || hell
         || ';text-decoration:none;padding:12px 18px;border-radius:8px;font-weight:600">' || ally_html(knopf) || '</a></p>'
         || '<p style="margin:0 0 14px;font-size:13px;color:#5B6470;word-break:break-all">Falls der Knopf nicht funktioniert, diesen Link öffnen:<br>' || ally_html(link) || '</p>' ELSE '' END
    || coalesce((SELECT string_agg('<p style="margin:0 0 14px">' || replace(ally_html(x), E'\n', '<br>') || '</p>', '' ORDER BY o) FROM unnest(nach) WITH ORDINALITY AS u(x, o)), '')
    || '<p style="margin:18px 0 0">Viele Grüße<br>' || ally_html(absender) || '</p>'
    || CASE WHEN ki THEN '<p style="margin:14px 0 0">Erstellt mit KI-Unterstützung.</p>' ELSE '' END || '</div></div>'
    || '<p style="max-width:560px;margin:12px auto 0;font-size:12px;color:#5B6470">Diese Nachricht wurde automatisch versendet.</p></body></html>';
  RETURN jsonb_build_object('betreff', left(regexp_replace(betreff, '[\r\n\t]+', ' ', 'g'), 200), 'text', txt, 'html', html, 'ics', ics,
    'ics_name', CASE WHEN ics IS NOT NULL THEN 'termin.ics' END);
END $function$;
CREATE OR REPLACE FUNCTION public.talent_zugang_ui(p_token text, p_talent_id integer)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
  s record; z talent_zugaenge%ROWTYPE; b talent_bereich%ROWTYPE; lk text; st text;
BEGIN
  -- Abschnitt „Talent-Bereich“ im Talent-Profil (ALLY 25, BA7): Zugang des Talents, Zugangslink zum Kopieren (kein Mailversand), Briefing, Sichtbarkeit.
  -- Nur für Admin und die zuständige Person aus dem Management; sonst darf = false (Abschnitt fehlt).
  -- BA8 (Migration 63): mail_aktiv (Absender-Postfach eingestellt: Zugangslink geht zusätzlich per Mail), kalender (Abo des Talents: seit, letzter Abruf; ohne Adresse).
  SELECT * INTO s FROM ally_ui_sitzung(p_token);
  IF NOT FOUND OR s.muss_pw_setzen THEN RETURN jsonb_build_object('ok', false, 'angemeldet', false); END IF;
  IF p_talent_id IS NULL OR NOT talent_zugang_darf(s.person, p_talent_id) THEN RETURN jsonb_build_object('ok', true, 'darf', false); END IF;
  SELECT * INTO z FROM talent_zugaenge x WHERE x.talent_id = p_talent_id;
  SELECT * INTO b FROM talent_bereich x WHERE x.talent_id = p_talent_id;
  IF z.id IS NOT NULL AND z.einladung_verschluesselt IS NOT NULL AND z.einladung_bis > now() AND ally_verschluesselung_bereit() AND talent_ui_adresse() IS NOT NULL THEN
    BEGIN
      lk := ally_entschluesseln(z.einladung_verschluesselt);
      -- Migration 209 (Fehler 46, Stefan 06.11.2026): Zugangslink als Pfad (ally_ui_link)
      lk := CASE WHEN lk ~ '^[0-9a-f]{64}$' THEN public.ally_ui_link('passwort-neu', jsonb_build_object('code', lk)) END;
    EXCEPTION WHEN OTHERS THEN lk := NULL;
    END;
  END IF;
  st := CASE WHEN z.id IS NULL THEN 'keiner' WHEN NOT z.aktiv THEN 'gesperrt'
             WHEN z.pw_hash IS NULL AND z.einladung_bis > now() THEN 'eingeladen' WHEN z.pw_hash IS NULL THEN 'abgelaufen' ELSE 'aktiv' END;
  RETURN jsonb_build_object('ok', true, 'darf', true,
    'zugang', jsonb_build_object('status', st, 'email', z.email, 'link', lk, 'link_bis', CASE WHEN z.einladung_bis > now() THEN talents_zeit(z.einladung_bis) END,
      'eingerichtet_am', CASE WHEN z.id IS NOT NULL THEN talents_datum(z.erstellt_am) END, 'letzte_anmeldung', CASE WHEN z.letzte_anmeldung IS NOT NULL THEN talents_zeit(z.letzte_anmeldung) END,
      'chat_benutzer', z.matrix_user_id),
    'email_vorschlag', (SELECT t.email FROM talents t WHERE t.id = p_talent_id),
    'briefing', coalesce(b.briefing, ''), 'briefing_am', CASE WHEN b.briefing_am IS NOT NULL THEN talents_zeit(b.briefing_am) END,
    'sicht', talent_bereich_sicht(p_talent_id),
    -- Migration 163 (Bauplan B5b): Rolle und Ausnahmen (F5–F7, G12)
    'ausnahmen', talent_ausnahmen_ui(p_talent_id),
    -- Migration 168 (Bauplan B7): für Test-Talents nie (Testdaten lösen keine Mails aus)
    'mail_aktiv', ally_systemnachricht_aktiv() AND NOT coalesce(talents_ist_testdaten(p_talent_id), false),
    'kalender', (SELECT jsonb_build_object('aktiv', true, 'seit', talents_zeit(k.erstellt_am), 'letzter_abruf', CASE WHEN k.letzter_abruf IS NOT NULL THEN talents_zeit(k.letzter_abruf) END)
                 FROM ally_kalender_abos k WHERE k.talent_id = p_talent_id AND k.widerrufen_am IS NULL ORDER BY k.id DESC LIMIT 1));
END $function$;
CREATE OR REPLACE FUNCTION public.talents_warnungen()
 RETURNS jsonb
 LANGUAGE sql
 STABLE
AS $function$
  WITH k AS (
    SELECT k.*, t.status AS t_status, coalesce(talent_anzeigename(k.talent_id), '@' || nullif(ltrim(btrim(k.extern_name), '@'), ''), 'Talent Nr. ' || k.talent_id) AS anz, talents_kanal_text(k.plattform, k.extern_name) AS kt
    FROM talent_kanaele k JOIN talents t ON t.id = k.talent_id
    WHERE t.status = 'aktiv' AND plattform_modul_an('talents')),
  w AS (
    SELECT k.id AS kanal_id, k.talent_id, 'ablauf_bald' AS art, 'talents_verbindung' AS schalter,
      'ablauf_bald:' || to_char(k.gueltig_bis AT TIME ZONE 'Europe/Berlin', 'YYYYMMDD') AS ereignis,
      'Talents: Verbindung läuft bald ab' AS titel,
      'Die Verbindung von ' || k.anz || ' zu ' || k.kt || ' läuft am ' || talents_datum(k.gueltig_bis) || ' ab. Danach kann ' || produkt_name()
        || ' für diesen Kanal keine neuen Zahlen mehr abrufen. Im Talent-Profil kannst du über das Zahnrad unter „Accounts und Verbindungen“ in ' || produkt_name()
        || ' einen neuen Einladungslink erzeugen und an ' || k.anz || ' schicken; mit der neuen Anmeldung gilt die Verbindung wieder für '
        || CASE WHEN k.plattform = 'tiktok' THEN 'etwa ein Jahr' ELSE 'etwa 60 Tage' END || '.' AS text,
      1 AS rang, NULL::integer AS kampagne_id
    FROM k WHERE k.status = 'verbunden' AND k.gueltig_bis > now() AND k.gueltig_bis <= now() + interval '7 days'
    UNION ALL
    SELECT k.id, k.talent_id, 'abgelaufen', 'talents_verbindung',
      'abgelaufen:' || to_char(coalesce(k.verbunden_am, k.erstellt_am) AT TIME ZONE 'UTC', 'YYYYMMDDHH24MISS'),
      'Talents: Verbindung abgelaufen',
      'Die Verbindung von ' || k.anz || ' zu ' || k.kt || ' ist abgelaufen oder wurde aufgehoben'
        || CASE WHEN k.gueltig_bis IS NOT NULL AND k.gueltig_bis <= now() THEN ' (gültig bis ' || talents_datum(k.gueltig_bis) || ')' ELSE '' END
        || '. ' || produkt_name() || ' ruft für diesen Kanal keine neuen Zahlen mehr ab; die bisher gespeicherten Zahlen bleiben erhalten. '
        || 'Im Talent-Profil kannst du über das Zahnrad unter „Accounts und Verbindungen“ in ' || produkt_name() || ' einen neuen Einladungslink erzeugen und an ' || k.anz || ' schicken.',
      0, NULL
    FROM k WHERE k.status = 'abgelaufen'
    UNION ALL
    SELECT k.id, k.talent_id, 'einbruch', 'talents_einbruch',
      'einbruch:' || to_char(talents_heute(), 'IYYY') || 'w' || to_char(talents_heute(), 'IW'),
      'Talents: starker Einbruch',
      'Starker Einbruch bei ' || k.anz || ' auf ' || k.kt || ' (' || to_char((e.x->>'von')::date, 'DD.MM.YYYY') || ' bis ' || to_char((e.x->>'bis')::date, 'DD.MM.YYYY') || '): '
        || concat_ws(' ',
             CASE WHEN (e.x->'reichweite'->>'einbruch')::boolean THEN 'Die Reichweite lag im Schnitt bei ' || talents_zahl_text((e.x->'reichweite'->>'schnitt_7')::numeric)
               || ' pro Tag, ' || (e.x->'reichweite'->>'minus_prozent') || ' % unter dem Schnitt der 4 Wochen davor (' || talents_zahl_text((e.x->'reichweite'->>'schnitt_28')::numeric) || ' pro Tag).' END,
             CASE WHEN (e.x->'interaktionen'->>'einbruch')::boolean THEN 'Die Interaktionen lagen im Schnitt bei ' || talents_zahl_text((e.x->'interaktionen'->>'schnitt_7')::numeric)
               || ' pro Tag, ' || (e.x->'interaktionen'->>'minus_prozent') || ' % unter dem Schnitt der 4 Wochen davor (' || talents_zahl_text((e.x->'interaktionen'->>'schnitt_28')::numeric) || ' pro Tag).' END)
        || ' Abschalten lässt sich diese Warnung in ' || produkt_name() || ' unter Einstellungen › Mein Konto › Benachrichtigungen.',
      2, NULL
    FROM k CROSS JOIN LATERAL (SELECT talents_einbruch(k.id) AS x) e
    WHERE k.status = 'verbunden' AND (e.x->>'einbruch')::boolean
    UNION ALL
    -- Kampagnenbeitrag fehlt: Kampagne läuft und endet in höchstens N Tagen, Talent ohne zugeordneten oder vorgeschlagenen Beitrag (Stefan 18.10.2026)
    SELECT NULL::integer, kt.talent_id, 'kampagne_fehlt', 'talents_kampagne', 'kampagne_fehlt:k' || ka.id || 't' || kt.talent_id,
      'Talents: Kampagnenbeitrag fehlt',
      'Für die Kampagne „' || ka.name || '“ (' || ka.marke || ', ' || to_char(ka.von, 'DD.MM.YYYY') || ' bis ' || to_char(ka.bis, 'DD.MM.YYYY') || ') ist bei '
        || coalesce(talent_anzeigename(kt.talent_id), 'Talent Nr. ' || kt.talent_id) || ' noch kein Beitrag zugeordnet. Unter Talents › Kampagnen kannst du in '
        || produkt_name() || ' Vorschläge bestätigen oder den Beitrag selbst zuordnen. Abschalten lässt sich diese Warnung in ' || produkt_name()
        || ' unter Einstellungen › Mein Konto › Benachrichtigungen.',
      3, ka.id
    FROM talent_kampagnen ka JOIN talent_kampagne_talents kt ON kt.kampagne_id = ka.id JOIN talents tt ON tt.id = kt.talent_id
    WHERE tt.status = 'aktiv' AND plattform_modul_an('talents') AND ka.von <= talents_heute() AND ka.bis >= talents_heute()
      AND talents_heute() >= ka.bis - talents_einstellung_zahl('talents_kampagne_warnung_tage', 0, 60, 3)
      AND NOT EXISTS (SELECT 1 FROM talent_kampagne_beitraege kb JOIN talent_beitraege b ON b.id = kb.beitrag_id JOIN talent_kanaele c ON c.id = b.kanal_id
                      WHERE kb.kampagne_id = ka.id AND kb.status IN ('bestaetigt', 'vorschlag') AND c.talent_id = kt.talent_id)
      -- Talents mit Deliverables in dieser Kampagne: dafür gelten die Erinnerungsregeln (Migration 61), keine zweite Meldung
      AND NOT EXISTS (SELECT 1 FROM talent_deliverables dl WHERE dl.kampagne_id = ka.id AND dl.talent_id = kt.talent_id)
    UNION ALL
    -- Löschfrist: Ankündigung an die Admins (ohne Schalter) vor dem endgültigen Löschen archivierter Talents (Stefan 18.10.2026)
    SELECT NULL::integer, tt.id, 'loeschfrist', NULL, talents_loesch_ereignis(tt.id), 'Talents: Daten werden bald gelöscht',
      'Die Daten von ' || coalesce(talent_anzeigename(tt.id), 'Talent Nr. ' || tt.id) || ' (in den Papierkorb gelegt am ' || talents_datum(tt.archiviert_am)
        || ') werden nach der Löschfrist der Agentur am ' || talents_datum(talents_loesch_termin(tt.id)) || ' endgültig gelöscht, mit allen gespeicherten Zahlen, '
        || 'Beiträgen, Notizen und Kampagnen-Zuordnungen. Wer sie aufbewahren muss, exportiert sie vorher: '
        || coalesce(public.ally_ui_link('talent', jsonb_build_object('id', tt.id::text)) /* Migration 209 (Fehler 46, Stefan 06.11.2026): Link als Pfad */, talents_seite_adresse('ansicht=einstellungen&bereich=talents&talent=' || tt.id)) || ' (Aktionen › Export (ZIP)). Soll das Talent bleiben, dort unter Aktionen › Wiederherstellen wählen.',
      4, NULL
    FROM talents tt WHERE tt.status = 'archiviert' AND plattform_modul_an('talents') AND talents_loesch_termin(tt.id) IS NOT NULL
      AND now() >= talents_loesch_termin(tt.id) - make_interval(days => talents_einstellung_zahl('talents_loeschwarnung_tage', 1, 90, 14))
    UNION ALL
    -- YouTube ohne bestätigte Berechtigung: sofort Ankündigung an die Admins (ohne Schalter), Löschung der YouTube-Daten am Tag 30 (Stefan 18.10.2026)
    SELECT y.kanal_id, y.talent_id, 'youtube_berechtigung', NULL, 'youtube_berechtigung:k' || y.kanal_id || 'd' || to_char(talents_tag(y.basis), 'YYYYMMDD'),
      'Talents: YouTube-Daten werden gelöscht',
      'Der YouTube-Kanal ' || coalesce(nullif(btrim(ky.extern_name), ''), 'Nr. ' || y.kanal_id) || ' von ' || coalesce(talent_anzeigename(y.talent_id), 'Talent Nr. ' || y.talent_id)
        || ' hat keine bestätigte Berechtigung mehr (' || CASE y.status WHEN 'getrennt' THEN 'Verbindung getrennt' WHEN 'abgelaufen' THEN 'Verbindung abgelaufen'
             ELSE 'zuletzt bestätigt am ' || talents_datum(y.basis) END || '). Nach den YouTube-Richtlinien löscht ' || produkt_name() || ' am '
        || to_char(y.loeschen_am, 'DD.MM.YYYY') || ' die gespeicherten YouTube-Zahlen, Videos und Zuschauer-Angaben dieses Kanals, wenn der Kanal bis dahin nicht neu verbunden ist. '
        || 'Neu verbinden: im Talent-Profil über das Zahnrad unter „Accounts und Verbindungen“ einen neuen Einladungslink erzeugen und an das Talent schicken. Diese Löschung ist eine Pflicht und lässt sich nicht abschalten.',
      5, NULL
    FROM talents_youtube_unbestaetigt() y JOIN talent_kanaele ky ON ky.id = y.kanal_id WHERE y.loeschen_am > talents_heute()),
  f AS (
    SELECT w.*, CASE WHEN w.art IN ('loeschfrist', 'youtube_berechtigung') THEN talents_admin_empfaenger() ELSE talents_warnung_empfaenger(w.talent_id, w.schalter) END AS empfaenger FROM w
    WHERE NOT talents_ist_testdaten(w.talent_id)  -- Testdaten (Migration 79)
      AND NOT EXISTS (SELECT 1 FROM talent_meldungen m WHERE m.kanal_id = w.kanal_id AND m.ereignis = w.ereignis)
      AND NOT EXISTS (SELECT 1 FROM talent_meldungen_talent mt WHERE w.kanal_id IS NULL AND mt.talent_id = w.talent_id AND mt.ereignis = w.ereignis))
  SELECT jsonb_build_object('ok', true, 'anzahl', count(*) FILTER (WHERE jsonb_array_length(f.empfaenger) > 0),
    'warnungen', coalesce(jsonb_agg(jsonb_build_object('kanal_id', f.kanal_id, 'talent_id', f.talent_id, 'art', f.art, 'ereignis', f.ereignis,
        'titel', f.titel, 'text', f.text, 'empfaenger', f.empfaenger, 'kampagne_id', f.kampagne_id) ORDER BY f.rang, f.kanal_id, f.talent_id, f.kampagne_id) FILTER (WHERE jsonb_array_length(f.empfaenger) > 0), '[]'::jsonb))
  FROM f
$function$;
CREATE OR REPLACE FUNCTION public.talent_einladung_rueckweg(p_ziel text)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE
  m text[]; e text; pl text; h text; ei talent_einladungen%ROWTYPE; z talent_zugaenge%ROWTYPE; txt text; ok boolean;
BEGIN
  -- Rückweg nach „Verbinden“ (ALLY 16, BA8): Kam das Talent aus seinem Bereich (tb_verbinden, Merker in talent_einladung_rueckwege, 2 Stunden gültig)
  -- und hat es einen aktiven Zugang, geht es zurück in den Talent-Bereich; das Ergebnis steht dort als Meldung (in jeder offenen Sitzung des Talents).
  -- Sonst NULL: ALLY 16 leitet wie bisher auf die Einladungsseite. Eingabe ist das bisherige Ziel von ALLY 16 (Einladungsseite mit Ergebniscode).
  m := regexp_match(CASE WHEN left(coalesce(p_ziel, ''), length(ally_webhook_aussen()) + 1) = ally_webhook_aussen() || '/' THEN '/webhook/web' || substr(p_ziel, length(ally_webhook_aussen()) + 1) ELSE coalesce(p_ziel, '') END, '^/webhook/web/einladung\?t=([0-9a-f]{64})&e=([a-z]{1,20})(?:&p=([a-z]{1,20}))?(?:&h=([a-z-]{1,100}))?$');
  IF m IS NULL THEN RETURN NULL; END IF;
  e := m[2]; pl := m[3]; h := coalesce(m[4], '');
  SELECT i.* INTO ei FROM talent_einladungen i JOIN talent_einladung_rueckwege r ON r.einladung_id = i.id AND r.bis > now() WHERE i.token_hash = ally_web_hash(m[1]);
  -- Migration 74 (BA11): Pfad immer von der bisherigen Adresse auf dem n8n-Host (ALLY 16 läuft dort; traefik leitet /webhook/app auf die eigene Adresse weiter)
  IF ei.id IS NULL OR ally_oberflaeche_intern() IS NULL THEN RETURN NULL; END IF;
  SELECT x.* INTO z FROM talent_zugaenge x JOIN talents t ON t.id = x.talent_id AND t.status = 'aktiv' WHERE x.talent_id = ei.talent_id AND x.aktiv AND x.pw_hash IS NOT NULL;
  IF z.id IS NULL THEN RETURN NULL; END IF;
  DELETE FROM talent_einladung_rueckwege WHERE einladung_id = ei.id;
  ok := e = 'ok';
  txt := CASE WHEN ok THEN coalesce(talents_plattform_name(pl), 'Der Account') || ' ist verbunden.'
                || CASE WHEN h ~ '(^|-)konten(-|$)' THEN ' Es wurden mehrere Accounts verbunden.' ELSE '' END
                || CASE WHEN h ~ '(^|-)doppelt(-|$)' THEN ' Ein Account ist schon bei einem anderen Talent verbunden und wurde nicht übernommen.' ELSE '' END
              WHEN e = 'abgebrochen' THEN 'Die Verbindung mit ' || coalesce(talents_plattform_name(pl), 'der Plattform') || ' wurde abgebrochen.'
              WHEN e = 'doppelt' THEN 'Dieser Account ist schon bei einem anderen Talent verbunden. Bitte bei deinem Manager oder deiner Managerin nachfragen.'
              ELSE 'Die Verbindung mit ' || coalesce(talents_plattform_name(pl), 'der Plattform') || ' konnte nicht hergestellt werden. Bitte erneut versuchen oder bei deinem Manager oder deiner Managerin nachfragen.' END;
  -- Migration 160 (Bauplan B4a): Meldung in den Talent-Feldern der Sitzungen der Talent-Person.
  UPDATE ally_web_sitzungen SET talent_flash = left(txt, 500), talent_flash_art = CASE WHEN ok THEN 'ok' ELSE 'fehler' END WHERE matrix_user_id = 'talent:' || z.talent_id AND ablauf > now();
  -- Migration 209 (Fehler 46, Stefan 06.11.2026): mit Pfaden (Merker adressen_pfade) direkt auf die eigene Adresse als Pfad, sonst wie bisher auf dem n8n-Host
  IF public.ally_ui_pfade_an() THEN RETURN public.ally_oberflaeche_adresse() || public.ally_ui_pfad('talent-bereich', '{}'::jsonb); END IF;
  RETURN substring(coalesce(ally_oberflaeche_intern(), '') FROM '^https://[^/]+(/[A-Za-z0-9/_-]*)$') || public.ally_ui_abfrage('talent-bereich', '{}'::jsonb);
END $function$;
CREATE OR REPLACE FUNCTION public.ally_ui_verbindung_link(p_token text, p_art text, p_id text)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
  s record; basis text := ally_oberflaeche_webhook(); ziel text;  -- Migration 74 (BA11): gleicher Host wie die Oberfläche (Cookie ally_sitzung gilt je Host)
BEGIN
  IF p_art IS NULL OR p_art NOT IN ('li', 'lis', 'ig', 'pf', 'ki', 'sa') THEN RETURN NULL; END IF;
  SELECT * INTO s FROM ally_ui_sitzung(p_token);
  IF NOT FOUND OR s.muss_pw_setzen OR basis !~ '^https://[A-Za-z0-9.-]{3,253}(:[0-9]{1,5})?(/[A-Za-z0-9._~-]+)*/webhook$' THEN
    RETURN jsonb_build_object('ok', false);
  END IF;
  ziel := basis || '/web' || CASE p_art
    WHEN 'li' THEN '/linkedin-verbinden'
    WHEN 'lis' THEN '/linkedin-verbinden?unternehmen=1'   -- Migration 209 (Fehler 46, Stefan 06.11.2026): Parameter heißt unternehmen (nicht mehr seite)
    WHEN 'ig' THEN '?ansicht=marketing#instagram'
    WHEN 'pf' THEN '?ansicht=einstellungen&bereich=postfaecher'
    WHEN 'ki' THEN '?ansicht=einstellungen&bereich=ki#ki-zugang'
    ELSE '?ansicht=einstellungen&bereich=superadmin' || CASE WHEN coalesce(p_id, '') ~ '^[a-z]{2,20}$' THEN '&sa=' || p_id ELSE '' END END;
  RETURN jsonb_build_object('ok', true, 'url', ziel, 'ally8', true);
END $function$;
DO $m$
BEGIN
  IF (SELECT md5(string_agg(p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')|' || pg_get_function_result(p.oid) || '|' || md5(p.prosrc), E'\n' ORDER BY p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')' COLLATE "C")) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname::text = 'public' COLLATE "C" AND p.proname::text COLLATE "C" = ANY (ARRAY['ally_systemnachricht_inhalt', 'talent_zugang_ui', 'talents_warnungen', 'talent_einladung_rueckweg', 'ally_ui_verbindung_link', 'ally_ui_pfad_teil', 'ally_ui_pfad_lesen', 'ally_ui_pfad', 'ally_ui_ort', 'ally_ui_abfrage', 'ally_ui_pfade_an', 'ally_ui_link', 'ally_ui_pfade_liste', 'ally_ui_filter'])) IS DISTINCT FROM '20374df52ea8d161140fce5a70fe7ddc' THEN RAISE EXCEPTION 'Migration 209: Funktionen nicht wie gebaut'; END IF;
END $m$;
