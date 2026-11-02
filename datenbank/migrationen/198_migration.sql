-- Migration 198 (Fehlerliste Installation, Stefan 02.11.2026), vier Punkte:
-- Nr. 23 Typ public.talents_zahlen_zeile anlegen, falls er fehlt (wie 138_migration.sql; der Grundstand übernimmt kein CREATE TYPE); ist er da, müssen seine
--        Spalten genau stimmen, sonst Abbruch.
-- Nr. 10 Folge public.postfach_nr_seq: eigene Postfach-Nummern beginnen bei 11; wäre der nächste Wert kleiner, setval(…, greatest(10, höchste vergebene
--        Nummer), true), sonst bleibt sie.
-- Nr. 19 ally_web_cd_datei: ohne gespeicherte Schrift und Farben kein Abbruch mehr; beim Speichern der Datei zuerst die Standardzeile in ally_cd
--        (wie Workflow CD 1 ohne CD), Meldung mit Zusatz „Für Schrift und Farben gelten die Standardwerte.“
-- Nr. 24 Absender für Systemnachrichten über ein vorhandenes Postfach: dessen Versand statt eigener SMTP-Angaben und der Zugangsdaten der Installation
--        (ally_systemnachricht_ui_aktion, ally_systemnachricht_absender_stand, ally_systemnachrichten_holen mit art, platz, workflow_id). 'eigen' unverändert.
-- Keine Tabellenänderung (Schema-Wächter vorher = nachher). Nur als Ganzes in einer Transaktion. Keine Workflow-Änderung. Rückbau: rueckbau198.sql.

DO $m$
BEGIN
  IF (SELECT md5(string_agg(p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')|' || pg_get_function_result(p.oid) || '|' || md5(p.prosrc), E'\n' ORDER BY p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')' COLLATE "C")) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname::text = 'public' COLLATE "C" AND p.proname::text COLLATE "C" = ANY (ARRAY['ally_systemnachricht_absender_stand', 'ally_systemnachricht_ui_aktion', 'ally_systemnachrichten_holen', 'ally_web_cd_datei'])) IS NOT DISTINCT FROM '15d2e650b6d5f2498cff4cf64e77b699' AND (SELECT md5(string_agg(z, E'\n' ORDER BY z COLLATE "C")) FROM (WITH t AS (SELECT c.oid, c.relname::text AS tab FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname::text = 'public' COLLATE "C" AND c.relkind::text = ANY (ARRAY['r', 'p']) AND c.relname::text = ANY (ARRAY['ally_cd', 'ally_cd_dateien', 'ally_postfaecher', 'ally_systemnachricht_absender', 'ally_systemnachrichten', 'postfach_plaetze'])) SELECT 'S|' || t.tab || '|' || a.attname::text || '|' || format_type(a.atttypid, a.atttypmod) || '|' || CASE WHEN a.attnotnull THEN 'NN' ELSE '-' END || '|' || coalesce(pg_get_expr(d.adbin, d.adrelid), '') || '|' || a.attidentity::text || a.attgenerated::text AS z FROM t JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum > 0 AND NOT a.attisdropped LEFT JOIN pg_attrdef d ON d.adrelid = t.oid AND d.adnum = a.attnum UNION ALL SELECT 'C|' || t.tab || '|' || co.conname::text || '|' || co.contype::text || '|' || pg_get_constraintdef(co.oid) FROM t JOIN pg_constraint co ON co.conrelid = t.oid UNION ALL SELECT 'I|' || t.tab || '|' || ic.relname::text || '|' || pg_get_indexdef(i.indexrelid) FROM t JOIN pg_index i ON i.indrelid = t.oid JOIN pg_class ic ON ic.oid = i.indexrelid UNION ALL SELECT 'T|' || t.tab || '|' || tg.tgname::text || '|' || pg_get_triggerdef(tg.oid) || '|' || tg.tgenabled::text FROM t JOIN pg_trigger tg ON tg.tgrelid = t.oid AND NOT tg.tgisinternal) x) IS NOT DISTINCT FROM '5efb012d7cceec0633a66d912a2233ca'
    THEN RAISE EXCEPTION 'Migration 198: schon eingespielt, nichts geändert'; END IF;
  IF (SELECT md5(string_agg(p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')|' || pg_get_function_result(p.oid) || '|' || md5(p.prosrc), E'\n' ORDER BY p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')' COLLATE "C")) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname::text = 'public' COLLATE "C" AND p.proname::text COLLATE "C" = ANY (ARRAY['ally_systemnachricht_absender_stand', 'ally_systemnachricht_ui_aktion', 'ally_systemnachrichten_holen', 'ally_web_cd_datei'])) IS DISTINCT FROM '9b4d832570b5cd7fde54ec758b32daee' THEN RAISE EXCEPTION 'Migration 198: Funktionen ally_web_cd_datei/ally_systemnachricht_*/ally_systemnachrichten_holen nicht im erwarteten Stand, nichts geändert'; END IF;
  IF (SELECT md5(string_agg(z, E'\n' ORDER BY z COLLATE "C")) FROM (WITH t AS (SELECT c.oid, c.relname::text AS tab FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname::text = 'public' COLLATE "C" AND c.relkind::text = ANY (ARRAY['r', 'p']) AND c.relname::text = ANY (ARRAY['ally_cd', 'ally_cd_dateien', 'ally_postfaecher', 'ally_systemnachricht_absender', 'ally_systemnachrichten', 'postfach_plaetze'])) SELECT 'S|' || t.tab || '|' || a.attname::text || '|' || format_type(a.atttypid, a.atttypmod) || '|' || CASE WHEN a.attnotnull THEN 'NN' ELSE '-' END || '|' || coalesce(pg_get_expr(d.adbin, d.adrelid), '') || '|' || a.attidentity::text || a.attgenerated::text AS z FROM t JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum > 0 AND NOT a.attisdropped LEFT JOIN pg_attrdef d ON d.adrelid = t.oid AND d.adnum = a.attnum UNION ALL SELECT 'C|' || t.tab || '|' || co.conname::text || '|' || co.contype::text || '|' || pg_get_constraintdef(co.oid) FROM t JOIN pg_constraint co ON co.conrelid = t.oid UNION ALL SELECT 'I|' || t.tab || '|' || ic.relname::text || '|' || pg_get_indexdef(i.indexrelid) FROM t JOIN pg_index i ON i.indrelid = t.oid JOIN pg_class ic ON ic.oid = i.indexrelid UNION ALL SELECT 'T|' || t.tab || '|' || tg.tgname::text || '|' || pg_get_triggerdef(tg.oid) || '|' || tg.tgenabled::text FROM t JOIN pg_trigger tg ON tg.tgrelid = t.oid AND NOT tg.tgisinternal) x) IS DISTINCT FROM '5efb012d7cceec0633a66d912a2233ca' THEN RAISE EXCEPTION 'Migration 198: Schema von ally_cd/ally_cd_dateien/ally_postfaecher/ally_systemnachricht_absender/ally_systemnachrichten/postfach_plaetze weicht vom Live-Stand ab, nichts geändert'; END IF;
  IF EXISTS (SELECT 1 FROM pg_type t JOIN pg_namespace n ON n.oid = t.typnamespace WHERE n.nspname::text = 'public' COLLATE "C" AND t.typname::text = 'talents_zahlen_zeile' COLLATE "C") AND (SELECT string_agg(a.attname::text || ' ' || format_type(a.atttypid, a.atttypmod), ', ' ORDER BY a.attnum) FROM pg_type t JOIN pg_namespace n ON n.oid = t.typnamespace JOIN pg_class c ON c.oid = t.typrelid AND c.relkind = 'c' JOIN pg_attribute a ON a.attrelid = t.typrelid AND a.attnum > 0 AND NOT a.attisdropped WHERE n.nspname::text = 'public' COLLATE "C" AND t.typname::text = 'talents_zahlen_zeile' COLLATE "C" AND t.typtype = 'c') IS DISTINCT FROM 'reichweite numeric, aufrufe numeric, interaktionen numeric, tage integer, follower numeric, follower_zuwachs numeric, manuell_anzahl integer, manuell_text text, doppelt_offen integer'
    THEN RAISE EXCEPTION 'Migration 198: Typ talents_zahlen_zeile vorhanden, aber mit anderen Spalten, nichts geändert'; END IF;
  IF NOT (to_regclass('public.postfach_nr_seq') IS NOT NULL AND EXISTS (SELECT 1 FROM pg_sequence q WHERE q.seqrelid = to_regclass('public.postfach_nr_seq') AND q.seqincrement = 1 AND q.seqmin <= 10 AND q.seqmax >= 11)) THEN RAISE EXCEPTION 'Migration 198: Folge postfach_nr_seq nicht wie erwartet, nichts geändert'; END IF;
END $m$;

-- Nr. 23: nur wenn der Typ fehlt (Definition und Kommentar wörtlich aus 138_migration.sql)
DO $m$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type t JOIN pg_namespace n ON n.oid = t.typnamespace WHERE n.nspname::text = 'public' COLLATE "C" AND t.typname::text = 'talents_zahlen_zeile' COLLATE "C") THEN
    CREATE TYPE public.talents_zahlen_zeile AS (reichweite numeric, aufrufe numeric, interaktionen numeric, tage integer, follower numeric,
      follower_zuwachs numeric, manuell_anzahl integer, manuell_text text, doppelt_offen integer);
    COMMENT ON TYPE public.talents_zahlen_zeile IS 'Migration 138: eine Zeile von talents_zahlen (gleiche Spalten und Typen), für Werte aus talents_zahlen_vorrat';
  END IF;
END $m$;

-- Nr. 10: nur wenn der nächste Wert kleiner als 11 wäre; nie unter einer schon vergebenen Nummer (höchste Nummer in postfach_plaetze). setval allein bliebe bei einem Abbruch (und in probe198) stehen, weil Folgen nicht
-- transaktional sind; nach ALTER SEQUENCE … RESTART in derselben Transaktion gehört die Änderung zu ihr und wird bei einem Abbruch mit zurückgenommen.
DO $m$
BEGIN
  IF (SELECT CASE WHEN s.is_called THEN s.last_value + q.seqincrement ELSE s.last_value END FROM public.postfach_nr_seq s, pg_sequence q WHERE q.seqrelid = 'public.postfach_nr_seq'::regclass) < 11 THEN
    ALTER SEQUENCE public.postfach_nr_seq RESTART;
    PERFORM setval('public.postfach_nr_seq', greatest(10, coalesce((SELECT max(p.platz) FROM public.postfach_plaetze p), 0)), true);
  END IF;
END $m$;

CREATE OR REPLACE FUNCTION public.ally_systemnachricht_absender_stand()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
  a ally_systemnachricht_absender%ROWTYPE; adr text; cred text; cred_ok boolean; aus boolean;
  platz_gleich boolean; platz_ok boolean;  -- Migration 198 (Fehler Nr. 24, Stefan 02.11.2026): Versand des Postfachs unverändert und eingerichtet
BEGIN
  -- Stand des Absender-Postfachs für Systemnachrichten (BA8). aktiv = eingestellt, Verbindung geprüft, Zugang für den Versand vorhanden und
  -- (bei einem Postfach-Platz) die Adresse des Platzes unverändert. Sonst wird nichts versendet und Links stehen zum Kopieren bereit (wie bisher).
  cred := btrim(coalesce(ally_einstellung('systemnachrichten_credential_id'), ''));
  cred_ok := cred ~ '^[A-Za-z0-9]{8,40}$';
  SELECT * INTO a FROM ally_systemnachricht_absender x WHERE x.id;
  IF NOT FOUND THEN RETURN jsonb_build_object('vorhanden', false, 'aktiv', false, 'credential_bereit', cred_ok); END IF;
  adr := CASE WHEN a.art = 'platz' THEN (SELECT lower(btrim(p.adresse)) FROM postfach_plaetze p WHERE p.platz = a.platz) ELSE a.adresse END;
  -- Migration 88 (Stefan 22.10.2026, 16:56): ist für das Postfach mit dieser Adresse „Versand erlauben“ ausgeschaltet, sendet Ally auch keine Systemnachrichten darüber
  aus := EXISTS (SELECT 1 FROM postfach_plaetze p WHERE lower(p.adresse) = lower(a.adresse) AND p.versand_erlaubt IS FALSE);
  -- Migration 198 (Fehler Nr. 24, Stefan 02.11.2026): bei einem Postfach geht der Versand über dessen SMTP-Zugang und Empfangs-Workflow
  -- (Postfach-Einrichtung), nicht über die Zugangsdaten der Installation. platz_gleich: SMTP-Server, Port, Anmeldename und Prüfzeitpunkt des Postfachs
  -- noch wie beim Speichern (sonst „Postfach geändert“, kein Versand über einen inzwischen anderen Server); platz_ok: dazu Versand eingerichtet, beide Kennungen gültig.
  platz_gleich := a.art = 'platz' AND EXISTS (SELECT 1 FROM postfach_plaetze p WHERE p.platz = a.platz AND p.smtp_host = a.smtp_host AND p.smtp_port = a.smtp_port
    AND p.smtp_benutzer = a.smtp_benutzer AND p.versand_geprueft_am IS NOT DISTINCT FROM a.geprueft_am);
  platz_ok := platz_gleich AND EXISTS (SELECT 1 FROM postfach_plaetze p WHERE p.platz = a.platz AND p.versand_eingerichtet
    AND coalesce(p.smtp_credential_id, '') ~ '^[A-Za-z0-9]{8,40}$' AND coalesce(p.empfang_workflow_id, '') ~ '^[A-Za-z0-9]{8,40}$');
  RETURN jsonb_build_object('vorhanden', true, 'art', a.art, 'platz', a.platz, 'adresse', a.adresse, 'platz_adresse', CASE WHEN a.art = 'platz' THEN adr END,
    'name', a.name, 'smtp_host', a.smtp_host, 'smtp_port', a.smtp_port, 'smtp_benutzer', a.smtp_benutzer, 'eingerichtet', a.eingerichtet,
    'geprueft', CASE WHEN a.geprueft_am IS NOT NULL THEN talents_zeit(a.geprueft_am) END, 'pruef_ergebnis', a.pruef_ergebnis,
    'credential_bereit', cred_ok, 'credential_id', CASE WHEN cred_ok THEN cred END,
    -- Migration 198 (Fehler Nr. 24, Stefan 02.11.2026): geändert auch bei anderem SMTP-Zugang oder Prüfzeitpunkt des Postfachs
    'platz_geaendert', a.art = 'platz' AND (adr IS DISTINCT FROM a.adresse OR NOT platz_gleich), 'versand_aus', aus,
    -- Migration 198 (Fehler Nr. 24, Stefan 02.11.2026): bei art platz statt cred_ok platz_ok (art eigen unverändert)
    'aktiv', a.eingerichtet AND (a.art = 'platz' OR cred_ok) AND ally_mail_gueltig(a.adresse) AND (a.art = 'eigen' OR (adr = a.adresse AND platz_ok)) AND NOT aus);
END $function$;
CREATE OR REPLACE FUNCTION public.ally_systemnachricht_ui_aktion(p_token text, p_aktion text, p_daten jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
  s record;
  d jsonb := CASE WHEN jsonb_typeof(p_daten) = 'object' THEN p_daten ELSE '{}'::jsonb END;
  adm boolean; m text := NULL; fehler text := NULL; r jsonb := NULL; weiter text := NULL;
  q text; pl integer; adr text; nm text; host text; port integer; ben text; cred text; tok text; p ally_personen%ROWTYPE; n integer; x jsonb;
  pp postfach_plaetze%ROWTYPE;  -- Migration 198 (Fehler Nr. 24, Stefan 02.11.2026): Zeile des gewählten Postfachs (Absender über dessen Versand)
BEGIN
  -- Aktionen der Oberfläche (über ally_ui_aktion, BA8): Absender-Postfach für Systemnachrichten (sy_*, nur Admin) und eigenes Kalender-Abo (ka_*).
  -- sy_absender_speichern/pruefen/entfernen: weiter = versand -> ALLY 20 ruft ALLY 39 (Zugangsdaten „Systemnachrichten – Versand (SMTP)“ setzen, prüfen, leeren);
  -- das Ergebnis trägt ally_systemnachricht_absender_abschliessen ein. Das Passwort kommt nie in die Datenbank (hier nur seine Länge).
  SELECT * INTO s FROM ally_ui_sitzung(p_token);
  IF NOT FOUND OR s.muss_pw_setzen THEN RETURN jsonb_build_object('ok', false, 'angemeldet', false); END IF;
  adm := coalesce(ally_hat_recht(s.person, 'admin'), false);
  cred := btrim(coalesce(ally_einstellung('systemnachrichten_credential_id'), ''));
  IF p_aktion LIKE 'sy\_%' AND NOT adm THEN
    fehler := 'Das darf eine Person mit der Rolle Admin.';

  ELSIF p_aktion = 'sy_absender_speichern' THEN
    q := btrim(coalesce(d->>'quelle', ''));
    pl := CASE WHEN q ~ '^platz:[1-9][0-9]{0,8}$' THEN substr(q, 7)::integer END;  -- Migration 173 (Schritt P, P3): Postfach-Nummer ohne Grenze
    adr := CASE WHEN pl IS NOT NULL THEN (SELECT lower(btrim(y.adresse)) FROM postfach_plaetze y WHERE y.platz = pl) ELSE lower(btrim(coalesce(d->>'adresse', ''))) END;
    nm := btrim(regexp_replace(coalesce(d->>'name', ''), '\s+', ' ', 'g'));
    host := lower(btrim(coalesce(d->>'smtp_host', '')));
    port := CASE WHEN coalesce(d->>'smtp_port', '') IN ('465', '587') THEN (d->>'smtp_port')::integer END;
    ben := btrim(coalesce(d->>'smtp_benutzer', ''));
    -- Migration 198 (Fehler Nr. 24, Stefan 02.11.2026): über ein vorhandenes Postfach (quelle platz:<n>) ohne die Zugangsdaten der Installation
    IF pl IS NULL AND cred !~ '^[A-Za-z0-9]{8,40}$' THEN
      fehler := 'Der Versand ist in dieser Installation noch nicht eingerichtet (Zugangsdaten für den Versand fehlen).';
    ELSIF q <> 'eigen' AND pl IS NULL THEN
      fehler := 'Bitte ein Postfach wählen.';
    ELSIF pl IS NOT NULL AND adr IS NULL THEN
      fehler := 'Dieses Postfach ist nicht eingerichtet.';
    -- Migration 90: Systemnachrichten nur über gemeinsame Postfächer
    ELSIF pl IS NOT NULL AND (SELECT x.art FROM ally_postfaecher x WHERE x.adresse = adr) = 'persoenlich' THEN
      fehler := 'Für Systemnachrichten geht nur ein gemeinsames Postfach.';
    ELSIF NOT ally_mail_gueltig(adr) THEN
      fehler := 'Bitte die Mailadresse des Postfachs angeben.';
    ELSIF nm = '' OR length(nm) > 80 OR nm ~ '[<>"\\,;:()]' THEN
      fehler := 'Bitte einen Absendernamen angeben (höchstens 80 Zeichen, ohne < > " , ; : ( )).';
    ELSIF EXISTS (SELECT 1 FROM ally_personen y WHERE lower(btrim(y.name)) = lower(nm)) THEN
      fehler := 'Als Absendername bitte den Namen der Organisation verwenden, nicht den Namen einer Person.';
    -- Migration 198 (Fehler Nr. 24, Stefan 02.11.2026): über ein vorhandenes Postfach gehen Systemnachrichten über dessen Versand (SMTP-Zugang
    -- und Empfangs-Workflow aus der Postfach-Einrichtung); keine eigenen SMTP-Angaben, kein Passwort, kein Aufruf von ALLY 39. Der Versand des Postfachs
    -- muss eingerichtet und erlaubt sein und zu den Regeln von ally_systemnachricht_absender passen. Geprüft wird über eine Testnachricht.
    ELSIF pl IS NOT NULL THEN
      SELECT * INTO pp FROM postfach_plaetze y WHERE y.platz = pl;
      IF NOT coalesce(pp.adresse IS NOT NULL AND pp.versand_eingerichtet AND pp.versand_erlaubt IS NOT FALSE
          AND pp.smtp_credential_id ~ '^[A-Za-z0-9]{8,40}$' AND pp.empfang_workflow_id ~ '^[A-Za-z0-9]{8,40}$'
          AND length(pp.smtp_host) <= 253 AND pp.smtp_host ~ '^[a-z0-9]([a-z0-9-]*[a-z0-9])?(\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)+$'
          AND pp.smtp_port IN (465, 587) AND btrim(pp.smtp_benutzer) <> '' AND length(pp.smtp_benutzer) <= 200 AND pp.smtp_benutzer !~ '[\r\n\t]', false) THEN
        fehler := 'Für dieses Postfach ist der Versand nicht eingerichtet oder ausgeschaltet. Bitte erst den Versand des Postfachs bestätigen.';
      ELSE
        INSERT INTO ally_systemnachricht_absender (id, art, platz, adresse, name, smtp_host, smtp_port, smtp_benutzer, eingerichtet, geprueft_am, pruef_ergebnis, geaendert_am, geaendert_von)
        VALUES (true, 'platz', pl, adr, nm, pp.smtp_host, pp.smtp_port, pp.smtp_benutzer, true, pp.versand_geprueft_am, left(pp.versand_pruef_ergebnis, 300), now(), s.person)
        ON CONFLICT (id) DO UPDATE SET art = EXCLUDED.art, platz = EXCLUDED.platz, adresse = EXCLUDED.adresse, name = EXCLUDED.name, smtp_host = EXCLUDED.smtp_host,
          smtp_port = EXCLUDED.smtp_port, smtp_benutzer = EXCLUDED.smtp_benutzer, eingerichtet = EXCLUDED.eingerichtet, geprueft_am = EXCLUDED.geprueft_am,
          pruef_ergebnis = EXCLUDED.pruef_ergebnis, geaendert_am = now(), geaendert_von = s.person;
        m := 'Absender gespeichert. Systemnachrichten gehen über den Versand von ' || adr || '. Zum Prüfen eine Testnachricht an dich senden.';
      END IF;
    ELSIF length(host) > 253 OR host !~ '^[a-z0-9]([a-z0-9-]*[a-z0-9])?(\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)+$' THEN
      fehler := 'Bitte den Postausgangsserver (SMTP) angeben, z. B. smtp.beispiel.de.';
    ELSIF adresse_gesperrt(host) THEN
      fehler := 'Dieser Server ist nicht erlaubt.';
    ELSIF port IS NULL THEN
      fehler := 'Bitte Port 465 (SSL/TLS) oder 587 (STARTTLS) wählen.';
    ELSIF ben = '' OR length(ben) > 200 OR ben ~ '[\r\n\t]' THEN
      fehler := 'Bitte den Anmeldenamen angeben (meist die Mailadresse).';
    ELSIF coalesce(d->>'passwort_laenge', '0') !~ '^[0-9]{1,4}$' OR (d->>'passwort_laenge')::integer < 1 THEN
      fehler := 'Bitte das Passwort des Postfachs angeben.';
    ELSE
      INSERT INTO ally_systemnachricht_absender (id, art, platz, adresse, name, smtp_host, smtp_port, smtp_benutzer, eingerichtet, geprueft_am, pruef_ergebnis, geaendert_am, geaendert_von)
      VALUES (true, CASE WHEN pl IS NULL THEN 'eigen' ELSE 'platz' END, pl, adr, nm, host, port, ben, false, NULL, NULL, now(), s.person)
      ON CONFLICT (id) DO UPDATE SET art = EXCLUDED.art, platz = EXCLUDED.platz, adresse = EXCLUDED.adresse, name = EXCLUDED.name, smtp_host = EXCLUDED.smtp_host,
        smtp_port = EXCLUDED.smtp_port, smtp_benutzer = EXCLUDED.smtp_benutzer, eingerichtet = false, geprueft_am = NULL, pruef_ergebnis = NULL,
        geaendert_am = now(), geaendert_von = s.person;
      weiter := 'versand';
      r := jsonb_build_object('modus', 'speichern', 'credential_id', cred, 'host', host, 'port', port, 'secure', port = 465, 'benutzer', ben);
    END IF;

  ELSIF p_aktion = 'sy_absender_pruefen' THEN
    IF NOT EXISTS (SELECT 1 FROM ally_systemnachricht_absender) THEN
      fehler := 'Es ist noch kein Absender-Postfach eingestellt.';
    -- Migration 198 (Fehler Nr. 24, Stefan 02.11.2026): Absender über ein vorhandenes Postfach: kein Aufruf von ALLY 39, Prüfen über eine Testnachricht
    ELSIF EXISTS (SELECT 1 FROM ally_systemnachricht_absender y WHERE y.art = 'platz') THEN
      m := 'Systemnachrichten gehen über den Versand von ' || (SELECT y.adresse FROM ally_systemnachricht_absender y WHERE y.art = 'platz')
        || '. Zum Prüfen eine Testnachricht an dich senden.';
    ELSIF cred !~ '^[A-Za-z0-9]{8,40}$' THEN
      fehler := 'Der Versand ist in dieser Installation noch nicht eingerichtet (Zugangsdaten für den Versand fehlen).';
    ELSE
      weiter := 'versand';
      r := jsonb_build_object('modus', 'pruefen', 'credential_id', cred);
    END IF;

  ELSIF p_aktion = 'sy_absender_entfernen' THEN
    DELETE FROM ally_systemnachricht_absender;
    GET DIAGNOSTICS n = ROW_COUNT;
    IF n = 0 THEN
      fehler := 'Es ist kein Absender-Postfach eingestellt.';
    ELSIF cred ~ '^[A-Za-z0-9]{8,40}$' THEN
      weiter := 'versand';
      r := jsonb_build_object('modus', 'leeren', 'credential_id', cred);
    ELSE
      m := 'Absender-Postfach entfernt. Es werden keine Systemnachrichten mehr per Mail versendet; Links stehen wieder zum Kopieren bereit.';
    END IF;

  ELSIF p_aktion = 'sy_testnachricht' THEN
    SELECT * INTO p FROM ally_personen y WHERE y.matrix_user_id = s.person;
    IF NOT ally_systemnachricht_aktiv() THEN
      fehler := 'Erst ein Absender-Postfach einstellen und die Verbindung prüfen.';
    ELSIF NOT ally_mail_gueltig(lower(btrim(coalesce(p.email, '')))) THEN
      fehler := 'Für dich ist keine gültige E-Mail-Adresse hinterlegt.';
    ELSIF (SELECT count(*) FROM ally_systemnachrichten y WHERE y.art = 'test' AND y.erstellt_am > now() - interval '1 hour') >= 3 THEN
      fehler := 'Höchstens drei Testnachrichten je Stunde. Bitte später noch einmal versuchen.';
    ELSE
      INSERT INTO ally_systemnachrichten (art, ref, person, gueltig_bis, erstellt_von)
      VALUES ('test', 'test:' || p.id || ':' || encode(gen_random_bytes(8), 'hex'), s.person, now() + interval '1 hour', s.person);
      m := 'Testnachricht an ' || lower(btrim(p.email)) || ' vorgemerkt. Sie geht in etwa einer Minute raus; der Stand steht in der Liste „Letzte Systemnachrichten“.';
    END IF;

  ELSIF p_aktion = 'sy_person_zugang' THEN
    SELECT * INTO p FROM ally_personen y WHERE y.matrix_user_id = coalesce(d->>'id', '') FOR UPDATE;
    IF NOT ally_systemnachricht_aktiv() THEN
      fehler := 'Es ist kein Absender-Postfach eingestellt. Bitte den Startcode nutzen.';
    ELSIF NOT ally_verschluesselung_bereit() OR talent_ui_adresse() IS NULL THEN
      fehler := 'Der Zugangslink kann gerade nicht erstellt werden (Verschlüsselung oder öffentliche Adresse nicht eingerichtet).';
    ELSIF p.id IS NULL OR NOT p.aktiv THEN
      fehler := 'Unbekannte Person.';
    ELSIF ally_person_ist_talent(p.matrix_user_id) THEN  -- Migration 158 (Bauplan B3a): Talent-Personen ändert man im Talent-Profil.
      fehler := 'Den Zugang eines Talents änderst du im Talent-Profil.';
    -- Migration 168 (Bauplan B7): Testdaten lösen keine Mails aus
    ELSIF coalesce(ally_person_ist_testdaten(p.matrix_user_id), false) THEN
      fehler := 'Testdaten lösen keine Mails aus. Bitte den Startcode nutzen.';
    ELSIF NOT p.zugang_aktiv THEN
      fehler := 'Der Zugang dieser Person ist gesperrt. Bitte ihn zuerst freischalten.';
    ELSIF NOT ally_mail_gueltig(lower(btrim(coalesce(p.email, '')))) THEN
      fehler := 'Bitte zuerst eine gültige E-Mail-Adresse für ' || p.name || ' eintragen.';
    ELSIF ally_person_superadmin(p.matrix_user_id) AND NOT coalesce(ally_hat_recht(s.person, 'superadmin'), false) THEN
      fehler := 'Diese Person ändert nur eine Person mit Superadmin-Recht.';
    ELSIF p.ruecksetz_bis IS NOT NULL AND p.ruecksetz_bis > now() + interval '6 days 23 hours' THEN
      fehler := 'Der Zugangslink wurde gerade erst gesendet. Bitte in einer Stunde noch einmal versuchen.';
    ELSE
      tok := encode(gen_random_bytes(32), 'hex');
      UPDATE ally_personen SET ruecksetz_hash = ally_web_hash(tok), ruecksetz_bis = now() + interval '7 days', geaendert_am = now() WHERE id = p.id;
      INSERT INTO ally_systemnachrichten (art, ref, person, geheim, gueltig_bis, erstellt_von)
      VALUES ('zugang_person', 'zugang_person:' || p.id || ':' || left(ally_web_hash(tok), 16), p.matrix_user_id, ally_verschluesseln(tok), now() + interval '1 day', s.person);
      m := 'Zugangslink für ' || p.name || ' an ' || lower(btrim(p.email)) || ' vorgemerkt (gültig 7 Tage, nur einmal). Die Mail geht in etwa einer Minute raus.';
    END IF;

  ELSIF p_aktion = 'ka_abo_neu' THEN
    x := ally_kalender_abo_neu(s.person, NULL, s.person);
    IF coalesce((x->>'ok')::boolean, false) THEN
      m := 'Abo-Adresse erstellt. Eine bisherige Adresse gilt nicht mehr; bitte in der Kalender-App die neue Adresse eintragen.';
    ELSE
      fehler := coalesce(x->>'fehler', 'Die Abo-Adresse konnte nicht erstellt werden.');
    END IF;

  ELSIF p_aktion = 'ka_abo_widerrufen' THEN
    UPDATE ally_kalender_abos SET widerrufen_am = now(), widerrufen_von = s.person WHERE person = s.person AND widerrufen_am IS NULL;
    GET DIAGNOSTICS n = ROW_COUNT;
    IF n = 0 THEN fehler := 'Es gibt kein Kalender-Abo.'; ELSE m := 'Kalender-Abo beendet. Die Adresse gilt nicht mehr.'; END IF;

  ELSE
    fehler := 'Diese Aktion gibt es hier nicht.';
  END IF;
  IF coalesce(fehler, m) IS NOT NULL THEN
    PERFORM ally_web_meldung(p_token, coalesce(fehler, m), CASE WHEN fehler IS NULL THEN 'ok' ELSE 'fehler' END, NULL);
  END IF;
  RETURN jsonb_build_object('ok', fehler IS NULL, 'weiter', CASE WHEN fehler IS NULL THEN weiter END, 'r', CASE WHEN fehler IS NULL THEN r END);
END $function$;
CREATE OR REPLACE FUNCTION public.ally_systemnachrichten_holen(p_jetzt timestamp with time zone DEFAULT now(), p_max integer DEFAULT 10)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
  st jsonb; vb jsonb; q ally_systemnachrichten%ROWTYPE; v_an text; v_tok text; v_grund text; inh jsonb; res jsonb := '[]'::jsonb; frei integer; n_h integer;
BEGIN
  -- Versand der Systemnachrichten (SYS 9, jede Minute): Vormerkungen pflegen, dann höchstens p_max (bis 20) wartende Nachrichten übernehmen („in_arbeit“).
  -- Nur mit aktivem Absender-Postfach. Empfänger nur aus der Datenbank. Drosselung: höchstens 60 je Stunde insgesamt, 5 je Stunde und 20 je Tag an dieselbe Adresse
  -- (darüber bleibt die Nachricht wartend, bis sie verfällt). Links nur, solange sie noch gelten; Aufgaben nur in der aktuellen Fassung.
  vb := ally_systemnachrichten_vorbereiten(p_jetzt);
  -- Datensparsamkeit: nach 90 Tagen Empfänger und Betreff entfernen (die Zeile bleibt als Nachweis)
  UPDATE ally_systemnachrichten SET an = NULL, betreff = NULL WHERE erledigt_am < p_jetzt - interval '90 days' AND (an IS NOT NULL OR betreff IS NOT NULL);
  st := ally_systemnachricht_absender_stand();
  IF NOT coalesce((st->>'aktiv')::boolean, false) THEN
    RETURN jsonb_build_object('aktiv', false, 'vorbereitet', vb, 'nachrichten', '[]'::jsonb);
  END IF;
  SELECT count(*) INTO n_h FROM ally_systemnachrichten x WHERE x.in_arbeit_seit > p_jetzt - interval '1 hour';
  frei := least(greatest(coalesce(p_max, 10), 0), 20, 60 - n_h);
  FOR q IN SELECT x.* FROM ally_systemnachrichten x WHERE x.status = 'wartet' AND x.gueltig_bis >= p_jetzt ORDER BY x.id LIMIT 100 FOR UPDATE SKIP LOCKED LOOP
    EXIT WHEN frei <= 0;
    v_grund := NULL; v_an := NULL; v_tok := NULL;
    IF q.art = 'email_aendern' THEN
      -- Migration 70: Bestätigungslink an die NEUE Adresse (nur solange die Änderung offen ist)
      SELECT lower(btrim(e.neue_email)) INTO v_an FROM ally_email_aenderungen e JOIN ally_personen y ON y.matrix_user_id = e.person AND y.aktiv AND y.zugang_aktiv
      WHERE e.person = q.person AND e.status = 'offen' AND e.gueltig_bis > p_jetzt ORDER BY e.id DESC LIMIT 1;
    ELSIF q.person IS NOT NULL THEN
      SELECT lower(btrim(y.email)) INTO v_an FROM ally_personen y WHERE y.matrix_user_id = q.person AND y.aktiv AND (q.art = 'test' OR y.zugang_aktiv);
    ELSIF q.art = 'einladung' THEN   -- Migration 192: Einladung an die E-Mail des Talents (nicht talent_zugaenge), nur aktiv und ohne Testdaten
      SELECT lower(btrim(t.email)) INTO v_an FROM talents t WHERE t.id = q.talent_id AND t.status = 'aktiv' AND NOT coalesce(t.testdaten, false);
    ELSIF q.art = 'aufgabe' THEN
      SELECT coalesce((SELECT z.email FROM talent_zugaenge z WHERE z.talent_id = t.id AND z.aktiv), lower(btrim(t.email))) INTO v_an
      FROM talents t WHERE t.id = q.talent_id AND t.status = 'aktiv';
    ELSE
      SELECT z.email INTO v_an FROM talent_zugaenge z JOIN talents t ON t.id = z.talent_id AND t.status = 'aktiv' WHERE z.talent_id = q.talent_id AND z.aktiv;
    END IF;
    IF NOT ally_mail_gueltig(v_an) THEN
      v_grund := 'Keine gültige E-Mail-Adresse hinterlegt.';
    ELSIF q.art IN ('zugang_talent', 'zugang_person', 'passwort', 'email_aendern') THEN
      BEGIN
        v_tok := ally_entschluesseln(q.geheim);
      EXCEPTION WHEN OTHERS THEN
        v_tok := NULL;
      END;
      IF coalesce(v_tok, '') !~ '^[0-9a-f]{64}$' THEN
        v_grund := 'Der Link ist nicht lesbar.';
      ELSIF q.art = 'email_aendern' AND NOT EXISTS (SELECT 1 FROM ally_email_aenderungen e WHERE e.person = q.person AND e.code_hash = ally_web_hash(v_tok)
          AND e.status = 'offen' AND e.gueltig_bis > p_jetzt) THEN
        v_grund := 'Der Link gilt nicht mehr (inzwischen ersetzt, verworfen oder benutzt).';
      ELSIF q.art <> 'email_aendern' AND q.person IS NOT NULL AND NOT EXISTS (SELECT 1 FROM ally_personen y WHERE y.matrix_user_id = q.person AND y.ruecksetz_hash = ally_web_hash(v_tok) AND y.ruecksetz_bis > p_jetzt) THEN
        v_grund := 'Der Link gilt nicht mehr (inzwischen ersetzt oder benutzt).';
      ELSIF q.talent_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM talent_zugaenge z WHERE z.talent_id = q.talent_id AND z.einladung_hash = ally_web_hash(v_tok) AND z.einladung_bis > p_jetzt) THEN
        v_grund := 'Der Link gilt nicht mehr (inzwischen ersetzt oder benutzt).';
      END IF;
    ELSIF q.art = 'einladung' AND talent_einladung_versandfehler(q.einladung_id, q.talent_id, q.erstellt_von) IS NOT NULL THEN   -- Migration 192
      v_grund := talent_einladung_versandfehler(q.einladung_id, q.talent_id, q.erstellt_von);
    ELSIF q.art = 'aufgabe' AND NOT EXISTS (SELECT 1 FROM talent_aufgaben t WHERE t.id = q.aufgabe_id AND t.ics_sequenz = q.aufgabe_sequenz AND t.mail_status = 'offen' AND 'mail' = ANY (t.kanaele)) THEN
      v_grund := 'Inzwischen geändert; es gilt die neuere Fassung.';
    END IF;
    IF v_grund IS NULL THEN
      -- Drosselung je Adresse
      IF (SELECT count(*) FROM ally_systemnachrichten x WHERE x.an = v_an AND x.in_arbeit_seit > p_jetzt - interval '1 hour') >= 5
         OR (SELECT count(*) FROM ally_systemnachrichten x WHERE x.an = v_an AND x.in_arbeit_seit > p_jetzt - interval '1 day') >= 20 THEN
        CONTINUE;
      END IF;
      inh := ally_systemnachricht_inhalt(q.id, v_tok, st);
      IF inh IS NULL THEN v_grund := CASE WHEN q.art = 'einladung' THEN coalesce(talent_einladung_mail(q.einladung_id, 'system', q.erstellt_von, NULL, true)->>'fehler', 'Der Inhalt ist nicht verfügbar.')
                                          ELSE 'Der Inhalt ist nicht verfügbar.' END; END IF;   -- Migration 192
    END IF;
    IF v_grund IS NOT NULL THEN
      UPDATE ally_systemnachrichten SET status = 'verfallen', grund = v_grund, geheim = NULL, erledigt_am = p_jetzt WHERE id = q.id;
      IF q.art = 'einladung' THEN PERFORM talent_einladung_fehler_melden('system', q.id); END IF;   -- Migration 192
      IF q.art = 'aufgabe' THEN
        UPDATE talent_aufgaben SET mail_status = 'fehler' WHERE id = q.aufgabe_id AND ics_sequenz = q.aufgabe_sequenz AND mail_status = 'offen';
      END IF;
      CONTINUE;
    END IF;
    UPDATE ally_systemnachrichten SET status = 'in_arbeit', in_arbeit_seit = p_jetzt, versuche = versuche + 1, an = v_an, betreff = inh->>'betreff',
      absender = CASE WHEN q.art = 'einladung' THEN lower(btrim(st->>'adresse')) ELSE absender END WHERE id = q.id;   -- Migration 192: Absender im Protokoll
    res := res || jsonb_build_array(jsonb_build_object('id', q.id, 'an', v_an) || inh);
    frei := frei - 1;
  END LOOP;
  -- Migration 198 (Fehler Nr. 24, Stefan 02.11.2026): dazu art, platz und workflow_id (Empfangs-Workflow des Postfachs, nur bei art platz);
  -- credential_id (Zugangsdaten der Installation) nur noch bei art eigen, bei art platz NULL (eine ältere SYS 9 bricht dann ab, statt über die Zugangsdaten
  -- der Installation zu senden)
  RETURN jsonb_build_object('aktiv', true, 'credential_id', CASE WHEN st->>'art' = 'eigen' THEN st->>'credential_id' END, 'von_adresse', st->>'adresse', 'von_name', st->>'name', 'vorbereitet', vb, 'nachrichten', res,
    'art', st->>'art', 'platz', st->'platz',
    'workflow_id', CASE WHEN st->>'art' = 'platz' THEN (SELECT p.empfang_workflow_id FROM postfach_plaetze p WHERE p.platz = (st->>'platz')::integer) END);
END $function$;
CREATE OR REPLACE FUNCTION public.ally_web_cd_datei(p_token text, p_daten jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
  s record;
  d jsonb := coalesce(p_daten, '{}'::jsonb);
  v text := coalesce(d->>'id', '');
  w_art text := coalesce(d->>'art', '');
  b64 text := coalesce(d->>'b64', '');
  roh bytea;
  txt text;
  w_mime text;
  fehler text := NULL;
  m text := NULL;
  std integer := 0;  -- Migration 198 (Fehler Nr. 19, Stefan 02.11.2026): 1 = Standardzeile in ally_cd eben angelegt
  namen jsonb := '{"logo_fuer_dunkel": "Logo für dunkle Flächen", "logo_fuer_hell": "Logo für helle Flächen", "bildmarke_fuer_dunkel": "Bildmarke für dunkle Flächen", "bildmarke_fuer_hell": "Bildmarke für helle Flächen"}'::jsonb;
BEGIN
  SELECT * INTO s FROM ally_web_sitzung_pruefen(p_token);
  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'angemeldet', false);
  END IF;
  IF s.muss_pw_setzen THEN
    RETURN jsonb_build_object('ok', false, 'angemeldet', true);
  END IF;
  IF NOT ally_hat_recht(s.matrix_user_id, 'admin') THEN
    fehler := 'Unternehmensdaten ändern Admins.';
  ELSIF NOT plattform_cd_gebraucht() THEN
    fehler := 'Das Corporate Design wird erst mit einem Paket gebraucht, das Berichte oder Grafiken erstellt.';
  ELSIF NOT EXISTS (SELECT 1 FROM ally_unternehmen WHERE id::text = v AND geloescht_am IS NULL) THEN
    fehler := 'Unbekanntes Unternehmen.';
  -- Migration 198 (Fehler Nr. 19, Stefan 02.11.2026): ohne gespeicherte Schrift und Farben kein Abbruch mehr (vorher die Bitte, zuerst Schrift
  -- und Farben zu speichern); beim Speichern der Datei gelten dann die Standardwerte (unten).
  ELSIF NOT namen ? w_art THEN
    fehler := 'Unbekannte Datei.';
  ELSIF b64 = '' THEN
    fehler := 'Bitte eine Datei auswählen.';
  ELSIF b64 !~ '^[A-Za-z0-9+/]+={0,2}$' THEN
    fehler := 'Die Datei konnte nicht gelesen werden.';
  ELSE
    roh := decode(b64, 'base64');
    IF length(roh) > 512000 THEN
      fehler := 'Die Datei ist zu groß. Erlaubt sind höchstens 500 KB.';
    ELSIF substring(roh FROM 1 FOR 8) = '\x89504e470d0a1a0a'::bytea THEN
      w_mime := 'image/png';
    ELSE
      BEGIN
        txt := convert_from(roh, 'UTF8');
      EXCEPTION WHEN others THEN
        txt := NULL;
      END;
      IF txt IS NULL OR txt !~* '<svg[[:space:]>]' THEN
        fehler := 'Bitte eine SVG- oder PNG-Datei hochladen.';
      ELSIF txt ~* '<script|javascript:|<foreignobject|<iframe|<embed|<object|[[:space:]"''/]on[a-z]+[[:space:]]*=' THEN
        fehler := 'Diese SVG-Datei enthält Skripte oder eingebettete Inhalte und wird deshalb nicht angenommen. Bitte die Datei ohne Skripte exportieren.';
      ELSE
        w_mime := 'image/svg+xml';
      END IF;
    END IF;
  END IF;
  IF fehler IS NULL THEN
    -- Migration 198 (Fehler Nr. 19, Stefan 02.11.2026): noch keine Schrift und Farben für dieses Unternehmen: zuerst die Standardwerte (wie Workflow CD 1 ohne CD)
    INSERT INTO ally_cd (unternehmen_id, schrift, farbe_dunkel, farbe_text_auf_dunkel, farbe_akzent, farbe_akzent_dunkel, farbe_hell, farbe_grau, farbe_warnung)
    VALUES (v::int, 'Inter', '#1F2933', '#FFFFFF', '#52606D', '#323F4B', '#F5F7FA', '#9AA5B1', '#B54708')
    ON CONFLICT (unternehmen_id) DO NOTHING;
    GET DIAGNOSTICS std = ROW_COUNT;
    INSERT INTO ally_cd_dateien (unternehmen_id, art, mime, daten, dateiname, groesse)
    VALUES (v::int, w_art, w_mime, b64, coalesce(nullif(left(regexp_replace(coalesce(d->>'name', ''), '[^[:alnum:] ._()-]', '', 'g'), 120), ''), w_art), length(roh))
    ON CONFLICT (unternehmen_id, art) DO UPDATE SET mime = EXCLUDED.mime, daten = EXCLUDED.daten, dateiname = EXCLUDED.dateiname,
      groesse = EXCLUDED.groesse, geaendert_am = now();
    m := (namen->>w_art) || ' für ' || (SELECT name FROM ally_unternehmen WHERE id::text = v) || ' gespeichert.';
    IF std > 0 THEN m := m || ' Für Schrift und Farben gelten die Standardwerte.'; END IF;  -- Migration 198 (Fehler Nr. 19, Stefan 02.11.2026): Hinweis auf die Standardwerte
  END IF;
  UPDATE ally_web_sitzungen SET flash = coalesce(fehler, m), flash_art = CASE WHEN fehler IS NULL THEN 'ok' ELSE 'fehler' END
  WHERE token_hash = s.token_hash;
  RETURN jsonb_build_object('ok', fehler IS NULL, 'angemeldet', true);
END $function$;
DO $m$
BEGIN
  IF (SELECT md5(string_agg(z, E'\n' ORDER BY z COLLATE "C")) FROM (WITH t AS (SELECT c.oid, c.relname::text AS tab FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname::text = 'public' COLLATE "C" AND c.relkind::text = ANY (ARRAY['r', 'p']) AND c.relname::text = ANY (ARRAY['ally_cd', 'ally_cd_dateien', 'ally_postfaecher', 'ally_systemnachricht_absender', 'ally_systemnachrichten', 'postfach_plaetze'])) SELECT 'S|' || t.tab || '|' || a.attname::text || '|' || format_type(a.atttypid, a.atttypmod) || '|' || CASE WHEN a.attnotnull THEN 'NN' ELSE '-' END || '|' || coalesce(pg_get_expr(d.adbin, d.adrelid), '') || '|' || a.attidentity::text || a.attgenerated::text AS z FROM t JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum > 0 AND NOT a.attisdropped LEFT JOIN pg_attrdef d ON d.adrelid = t.oid AND d.adnum = a.attnum UNION ALL SELECT 'C|' || t.tab || '|' || co.conname::text || '|' || co.contype::text || '|' || pg_get_constraintdef(co.oid) FROM t JOIN pg_constraint co ON co.conrelid = t.oid UNION ALL SELECT 'I|' || t.tab || '|' || ic.relname::text || '|' || pg_get_indexdef(i.indexrelid) FROM t JOIN pg_index i ON i.indrelid = t.oid JOIN pg_class ic ON ic.oid = i.indexrelid UNION ALL SELECT 'T|' || t.tab || '|' || tg.tgname::text || '|' || pg_get_triggerdef(tg.oid) || '|' || tg.tgenabled::text FROM t JOIN pg_trigger tg ON tg.tgrelid = t.oid AND NOT tg.tgisinternal) x) IS DISTINCT FROM '5efb012d7cceec0633a66d912a2233ca' THEN RAISE EXCEPTION 'Migration 198: Schema nicht wie gebaut'; END IF;
  IF (SELECT md5(string_agg(p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')|' || pg_get_function_result(p.oid) || '|' || md5(p.prosrc), E'\n' ORDER BY p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')' COLLATE "C")) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname::text = 'public' COLLATE "C" AND p.proname::text COLLATE "C" = ANY (ARRAY['ally_systemnachricht_absender_stand', 'ally_systemnachricht_ui_aktion', 'ally_systemnachrichten_holen', 'ally_web_cd_datei'])) IS DISTINCT FROM '15d2e650b6d5f2498cff4cf64e77b699' THEN RAISE EXCEPTION 'Migration 198: Funktionen nicht wie gebaut'; END IF;
  IF (SELECT string_agg(a.attname::text || ' ' || format_type(a.atttypid, a.atttypmod), ', ' ORDER BY a.attnum) FROM pg_type t JOIN pg_namespace n ON n.oid = t.typnamespace JOIN pg_class c ON c.oid = t.typrelid AND c.relkind = 'c' JOIN pg_attribute a ON a.attrelid = t.typrelid AND a.attnum > 0 AND NOT a.attisdropped WHERE n.nspname::text = 'public' COLLATE "C" AND t.typname::text = 'talents_zahlen_zeile' COLLATE "C" AND t.typtype = 'c') IS DISTINCT FROM 'reichweite numeric, aufrufe numeric, interaktionen numeric, tage integer, follower numeric, follower_zuwachs numeric, manuell_anzahl integer, manuell_text text, doppelt_offen integer' THEN RAISE EXCEPTION 'Migration 198: Typ talents_zahlen_zeile nicht wie gebaut'; END IF;
  IF (SELECT CASE WHEN s.is_called THEN s.last_value + q.seqincrement ELSE s.last_value END FROM public.postfach_nr_seq s, pg_sequence q WHERE q.seqrelid = 'public.postfach_nr_seq'::regclass) < 11 THEN RAISE EXCEPTION 'Migration 198: Folge postfach_nr_seq nicht wie gebaut'; END IF;
END $m$;
