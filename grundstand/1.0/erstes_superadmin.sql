-- B7a-Schritt „erstes_superadmin“ (Konzept Installation und Updates C.2/D.6): allerletzter Schritt einer Neu-Installation, nach schema_vor, startwerte,
-- schema_nach, den Migrationen der Fassung und fassung_eintragen. Legt genau eine erste Person an: Rolle Admin, Recht Admin und Superadmin, Eintrag in der
-- Liste superadmin_personen. Die Liste ändert sonst nur eine Migration: Wie dort wird der Schutz-Trigger ally_einstellungen_superadmin_liste nur für
-- diesen einen Eintrag abgeschaltet (Plan 16, Migration 168).
--
-- Aufruf (Installationsskript; Werte nur als Parameter, nie in dieser Datei):
--   psql -X -v name='Vorname Nachname' -v email='vorname@firma.de' -v chat_kennung='@vorname:chat' -f erstes_superadmin.sql
--   name          Anzeigename der Person
--   email         Anmeldung an der Oberfläche (E-Mail-Adresse)
--   chat_kennung  Chat-ID der Person (@kennung:chat); nur die Kennung – ein Chat-Konto legt das Installationsskript nicht an (später in Ally)
-- Plan 56d (Nachprüfung N1/N2): Prüfen, Anlegen und Nachprüfen laufen in einem einzigen Befehl (eine Transaktion): Bricht etwas ab, bleibt nichts zurück
-- (keine leere Liste, Schutz-Trigger an) und ein neuer Lauf ist möglich. „ok“ kommt erst nach bestandener Prüfung. Der Einmal-Code entsteht im Server
-- (gen_random_bytes), steht nie im SQL-Text oder in einer Fehlermeldung; gespeichert ist nur seine Prüfsumme (ally_web_hash, wie bei Einladungen).
-- Ergebnis (letzte Zeile, genau einmal): erstes_superadmin|ok|<chat_kennung>|<link>
--   link = <Adresse der Oberfläche>?seite=passwort-neu&code=<code>: Passwort festlegen wie mit dem Zugangslink einer Einladung (7 Tage, nur einmal).
--   Ist die Adresse der Oberfläche (oberflaeche_adresse) noch nicht eingerichtet, beginnt der Link mit „?seite=…“; das Installationsskript setzt seine
--   Adresse davor. Den Link nur dem Installierenden zeigen, nicht protokollieren.
-- Ein zweiter Lauf bricht ab, ohne etwas zu ändern (es gibt dann schon eine Person, ein Admin-/Superadmin-Recht oder die Liste).

\set ON_ERROR_STOP on
\if :{?name}
\else
DO $f$ BEGIN RAISE EXCEPTION 'erstes_superadmin: Parameter name fehlt (-v name=…).'; END $f$;
\endif
\if :{?email}
\else
DO $f$ BEGIN RAISE EXCEPTION 'erstes_superadmin: Parameter email fehlt (-v email=…).'; END $f$;
\endif
\if :{?chat_kennung}
\else
DO $f$ BEGIN RAISE EXCEPTION 'erstes_superadmin: Parameter chat_kennung fehlt (-v chat_kennung=…).'; END $f$;
\endif

SELECT set_config('ally.erstes_name', btrim(:'name'), false) AS w1, set_config('ally.erstes_email', lower(btrim(:'email')), false) AS w2,
       set_config('ally.erstes_kennung', btrim(:'chat_kennung'), false) AS w3, set_config('ally.erstes_code', '', false) AS w4 \gset erstes_

-- Ein Befehl: Wächter, Liste, Person, Rechte, Einmal-Code, Prüfung. Jeder Fehler nimmt alles zurück.
DO $s$
DECLARE
  n text := current_setting('ally.erstes_name');
  e text := current_setting('ally.erstes_email');
  k text := current_setting('ally.erstes_kennung');
  tok text;
BEGIN
  -- Wächter: Grundstand und Fassung da, Installation ohne Personen und Superadmin, Werte gültig
  IF to_regclass('public.ally_personen') IS NULL OR to_regprocedure('public.ally_fassung_aktuell()') IS NULL OR ally_fassung_aktuell() IS NULL THEN
    RAISE EXCEPTION 'erstes_superadmin: Grundstand oder Fassung fehlt (zuerst Grundstand, Migrationen und fassung_eintragen).';
  END IF;
  IF (SELECT count(*) FROM pg_trigger g WHERE NOT g.tgisinternal AND g.tgenabled <> 'D' AND (g.tgname::text COLLATE "C", g.tgrelid::regclass::text COLLATE "C")
        IN (('ally_einstellungen_superadmin_liste', 'ally_einstellungen'), ('ally_nutzer_rechte_superadmin_liste', 'ally_nutzer_rechte'))) <> 2 THEN
    RAISE EXCEPTION 'erstes_superadmin: Schutz der Superadmin-Liste fehlt oder ist abgeschaltet.';
  END IF;
  IF EXISTS (SELECT 1 FROM ally_einstellungen WHERE schluessel = 'superadmin_personen' COLLATE "C")
     OR EXISTS (SELECT 1 FROM ally_nutzer_rechte WHERE recht IN ('admin', 'superadmin'))
     OR EXISTS (SELECT 1 FROM ally_personen) THEN
    RAISE EXCEPTION 'erstes_superadmin: Diese Installation hat schon Personen oder einen Superadmin. Der Schritt läuft nur einmal, auf einer neuen Installation.';
  END IF;
  IF n = '' OR length(n) > 200 THEN
    RAISE EXCEPTION 'erstes_superadmin: Bitte einen Namen angeben.';
  END IF;
  IF e !~ '^[^@[:space:]]+@[^@[:space:]]+[.][^@[:space:]]+$' THEN
    RAISE EXCEPTION 'erstes_superadmin: Bitte eine gültige E-Mail-Adresse angeben.';
  END IF;
  IF k !~ '^@[a-z0-9._=/+-]+:[^[:space:],]+$' THEN
    RAISE EXCEPTION 'erstes_superadmin: Chat-Kennung in der Form @kennung:server angeben (Kleinbuchstaben, ohne Komma).';
  END IF;

  -- Liste superadmin_personen: nur hier, mit abgeschaltetem Schutz (Muster Migration 168), danach sofort wieder an
  ALTER TABLE public.ally_einstellungen DISABLE TRIGGER ally_einstellungen_superadmin_liste;
  INSERT INTO public.ally_einstellungen (schluessel, wert, geaendert_am, geaendert_von) VALUES ('superadmin_personen', k, now(), 'Installation');
  ALTER TABLE public.ally_einstellungen ENABLE TRIGGER ally_einstellungen_superadmin_liste;

  -- Person mit Rolle Admin (setzt das Recht admin), dann das Recht superadmin (Trigger ally_nutzer_rechte_superadmin_liste prüft die Liste)
  INSERT INTO public.ally_personen (matrix_user_id, name, email, aktiv, rolle) VALUES (k, n, e, true, 'admin');
  PERFORM public.ally_person_rolle_anwenden(k, 'admin', '{}'::text[]);
  INSERT INTO public.ally_nutzer_rechte (matrix_user_id, recht) VALUES (k, 'superadmin');

  -- Passwort festlegen wie bei einer Einladung (sy_person_zugang): Einmal-Code im Server, gespeichert nur als Prüfsumme, gültig 7 Tage
  tok := encode(gen_random_bytes(32), 'hex');
  UPDATE public.ally_personen SET ruecksetz_hash = public.ally_web_hash(tok), ruecksetz_bis = now() + interval '7 days', geaendert_am = now() WHERE matrix_user_id = k;

  -- Prüfung: genau diese eine Person ist Admin und Superadmin, Liste = sie, Schutz wieder an, Code gültig
  IF (SELECT count(*) FROM ally_personen) <> 1 OR NOT ally_hat_recht(k, 'superadmin') OR NOT ally_hat_recht(k, 'admin')
     OR (SELECT string_agg(matrix_user_id || ':' || recht, ',' ORDER BY recht) FROM ally_nutzer_rechte) IS DISTINCT FROM k || ':admin,' || k || ':superadmin'
     OR ally_einstellung('superadmin_personen') IS DISTINCT FROM k OR NOT ally_superadmin_erlaubt(k)
     OR NOT EXISTS (SELECT 1 FROM ally_nutzer WHERE matrix_user_id = k)
     OR (SELECT g.tgenabled FROM pg_trigger g WHERE g.tgname = 'ally_einstellungen_superadmin_liste' AND g.tgrelid = 'public.ally_einstellungen'::regclass) = 'D'
     OR NOT coalesce((ally_web_code_pruefen(tok)->>'gueltig')::boolean, false) THEN
    RAISE EXCEPTION 'erstes_superadmin: Prüfung nach dem Anlegen fehlgeschlagen.';
  END IF;
  PERFORM set_config('ally.erstes_code', tok, false);
END $s$;

-- Ausgabe genau einmal, erst nach bestandener Prüfung; danach den Code aus der Sitzung entfernen
SELECT 'erstes_superadmin', 'ok', current_setting('ally.erstes_kennung'),
       coalesce(public.talent_ui_adresse(), '') || '?seite=passwort-neu&code=' || current_setting('ally.erstes_code');
SELECT set_config('ally.erstes_code', '', false) AS w5 \gset erstes_
