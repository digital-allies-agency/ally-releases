-- Migration 197 (Plan 64, Stefan 01.11.2026 „Wieso beziehen alle Bereiche, die einen Firmennamen usw. nutzen, nicht diese eine Quelle?!“):
-- eine Quelle für Firmenname, Logo und Farben = das eigene Unternehmen auf der Seite Einstellungen › Firmendaten und Design (ally_firma.unternehmen_id).
-- Geändert: eigenes_unternehmen() (nur das verknüpfte Unternehmen, kein Rückfall auf ally_firma), ally_web_aktion 'unternehmen' (ohne eigenes Unternehmen wird
-- das erste angelegte oder gespeicherte das eigene). Neu: eigenes_unternehmen_festlegen(integer). ally_firma.name ohne NOT NULL.
-- Daten: Angaben aus ally_firma gehen in das verknüpfte Unternehmen, soweit dort leer (ohne Verknüpfung: Unternehmen gleichen Namens verknüpfen oder anlegen);
-- danach führt ally_firma keine eigenen Firmendaten mehr. Die Ausgabe von eigenes_unternehmen() bleibt gleich, sonst Abbruch.
-- Nur als Ganzes in einer Transaktion. Keine Workflow-Änderung. Rückbau: rueckbau197.sql.

DO $m$
BEGIN
  IF (SELECT md5(string_agg(p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')|' || pg_get_function_result(p.oid) || '|' || md5(p.prosrc), E'\n' ORDER BY p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')' COLLATE "C")) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname::text = 'public' COLLATE "C" AND p.proname::text COLLATE "C" = ANY (ARRAY['ally_web_aktion', 'eigenes_unternehmen', 'eigenes_unternehmen_festlegen'])) IS NOT DISTINCT FROM 'ea90ee74fbead6e9b328308cc0cc0d65' AND (SELECT md5(string_agg(z, E'\n' ORDER BY z COLLATE "C")) FROM (WITH t AS (SELECT c.oid, c.relname::text AS tab FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname::text = 'public' COLLATE "C" AND c.relkind::text = ANY (ARRAY['r', 'p']) AND c.relname::text = ANY (ARRAY['ally_firma', 'ally_unternehmen'])) SELECT 'S|' || t.tab || '|' || a.attname::text || '|' || format_type(a.atttypid, a.atttypmod) || '|' || CASE WHEN a.attnotnull THEN 'NN' ELSE '-' END || '|' || coalesce(pg_get_expr(d.adbin, d.adrelid), '') || '|' || a.attidentity::text || a.attgenerated::text AS z FROM t JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum > 0 AND NOT a.attisdropped LEFT JOIN pg_attrdef d ON d.adrelid = t.oid AND d.adnum = a.attnum UNION ALL SELECT 'C|' || t.tab || '|' || co.conname::text || '|' || co.contype::text || '|' || pg_get_constraintdef(co.oid) FROM t JOIN pg_constraint co ON co.conrelid = t.oid UNION ALL SELECT 'I|' || t.tab || '|' || ic.relname::text || '|' || pg_get_indexdef(i.indexrelid) FROM t JOIN pg_index i ON i.indrelid = t.oid JOIN pg_class ic ON ic.oid = i.indexrelid UNION ALL SELECT 'T|' || t.tab || '|' || tg.tgname::text || '|' || pg_get_triggerdef(tg.oid) || '|' || tg.tgenabled::text FROM t JOIN pg_trigger tg ON tg.tgrelid = t.oid AND NOT tg.tgisinternal) x) IS NOT DISTINCT FROM 'd47864c6fec2fc5a2d3031ab71590cc9'
    THEN RAISE EXCEPTION 'Migration 197: schon eingespielt, nichts geändert'; END IF;
  IF (SELECT md5(string_agg(p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')|' || pg_get_function_result(p.oid) || '|' || md5(p.prosrc), E'\n' ORDER BY p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')' COLLATE "C")) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname::text = 'public' COLLATE "C" AND p.proname::text COLLATE "C" = ANY (ARRAY['ally_web_aktion', 'eigenes_unternehmen', 'eigenes_unternehmen_festlegen'])) IS DISTINCT FROM 'a66d8df36e3e5cc011bd65942a47687f' THEN RAISE EXCEPTION 'Migration 197: Funktionen eigenes_unternehmen/ally_web_aktion nicht im erwarteten Stand, nichts geändert'; END IF;
  IF (SELECT md5(string_agg(z, E'\n' ORDER BY z COLLATE "C")) FROM (WITH t AS (SELECT c.oid, c.relname::text AS tab FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname::text = 'public' COLLATE "C" AND c.relkind::text = ANY (ARRAY['r', 'p']) AND c.relname::text = ANY (ARRAY['ally_firma', 'ally_unternehmen'])) SELECT 'S|' || t.tab || '|' || a.attname::text || '|' || format_type(a.atttypid, a.atttypmod) || '|' || CASE WHEN a.attnotnull THEN 'NN' ELSE '-' END || '|' || coalesce(pg_get_expr(d.adbin, d.adrelid), '') || '|' || a.attidentity::text || a.attgenerated::text AS z FROM t JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum > 0 AND NOT a.attisdropped LEFT JOIN pg_attrdef d ON d.adrelid = t.oid AND d.adnum = a.attnum UNION ALL SELECT 'C|' || t.tab || '|' || co.conname::text || '|' || co.contype::text || '|' || pg_get_constraintdef(co.oid) FROM t JOIN pg_constraint co ON co.conrelid = t.oid UNION ALL SELECT 'I|' || t.tab || '|' || ic.relname::text || '|' || pg_get_indexdef(i.indexrelid) FROM t JOIN pg_index i ON i.indrelid = t.oid JOIN pg_class ic ON ic.oid = i.indexrelid UNION ALL SELECT 'T|' || t.tab || '|' || tg.tgname::text || '|' || pg_get_triggerdef(tg.oid) || '|' || tg.tgenabled::text FROM t JOIN pg_trigger tg ON tg.tgrelid = t.oid AND NOT tg.tgisinternal) x) IS DISTINCT FROM '5be27776893dd24d31833bf6b433a62f' THEN RAISE EXCEPTION 'Migration 197: Schema von ally_firma/ally_unternehmen weicht vom Live-Stand ab, nichts geändert'; END IF;
  PERFORM set_config('m197.vorher', coalesce(eigenes_unternehmen()::text, ''), true);
END $m$;
ALTER TABLE public.ally_firma ALTER COLUMN name DROP NOT NULL;

CREATE FUNCTION public.eigenes_unternehmen_festlegen(p_unternehmen_id integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE n integer;
BEGIN
  -- Migration 197 (Plan 64, Stefan 01.11.2026, eine Quelle): ist noch kein eigenes Unternehmen verknüpft (neue Installation), wird das eben auf der Seite
  -- Einstellungen › Firmendaten und Design angelegte oder gespeicherte Unternehmen das eigene (ally_firma.unternehmen_id). Ein schon verknüpftes bleibt.
  -- true = jetzt verknüpft. Nur aus ally_web_aktion 'unternehmen' (Admin geprüft).
  IF p_unternehmen_id IS NULL OR NOT EXISTS (SELECT 1 FROM ally_unternehmen x WHERE x.id = p_unternehmen_id AND x.geloescht_am IS NULL) THEN RETURN false; END IF;
  INSERT INTO ally_firma (id, unternehmen_id) VALUES (1, p_unternehmen_id)
  ON CONFLICT (id) DO UPDATE SET unternehmen_id = EXCLUDED.unternehmen_id, geaendert_am = now() WHERE ally_firma.unternehmen_id IS NULL;
  GET DIAGNOSTICS n = ROW_COUNT;
  RETURN n > 0;
END $function$;

-- Daten: ohne Verknüpfung, aber mit Firmenname in ally_firma (ältere Installationen) das Unternehmen gleichen Namens verknüpfen oder anlegen;
-- danach leere Angaben des verknüpften Unternehmens aus ally_firma übernehmen und ally_firma ohne eigene Firmendaten (nur noch die Verknüpfung).
INSERT INTO public.ally_unternehmen (name, inhaber, ort, website)
SELECT btrim(f.name), nullif(btrim(f.inhaber), ''), nullif(btrim(f.ort), ''), nullif(btrim(f.website), '')
FROM public.ally_firma f
WHERE f.unternehmen_id IS NULL AND btrim(coalesce(f.name, '')) <> ''
  AND NOT EXISTS (SELECT 1 FROM public.ally_unternehmen x WHERE lower(btrim(x.name)) = lower(btrim(f.name)));
UPDATE public.ally_firma f SET unternehmen_id = (SELECT max(x.id) FROM public.ally_unternehmen x WHERE lower(btrim(x.name)) = lower(btrim(f.name)) AND x.geloescht_am IS NULL)
WHERE f.unternehmen_id IS NULL AND btrim(coalesce(f.name, '')) <> ''
  AND EXISTS (SELECT 1 FROM public.ally_unternehmen x WHERE lower(btrim(x.name)) = lower(btrim(f.name)) AND x.geloescht_am IS NULL);
UPDATE public.ally_unternehmen x SET
  name = CASE WHEN btrim(x.name) = '' AND btrim(coalesce(f.name, '')) <> '' THEN f.name ELSE x.name END,
  inhaber = coalesce(x.inhaber, f.inhaber), ort = coalesce(x.ort, f.ort), website = coalesce(x.website, f.website)
FROM public.ally_firma f
WHERE f.unternehmen_id = x.id
  AND ((btrim(x.name) = '' AND btrim(coalesce(f.name, '')) <> '') OR (x.inhaber IS NULL AND f.inhaber IS NOT NULL)
       OR (x.ort IS NULL AND f.ort IS NOT NULL) OR (x.website IS NULL AND f.website IS NOT NULL));
UPDATE public.ally_firma SET name = NULL, inhaber = NULL, ort = NULL, website = NULL
WHERE unternehmen_id IS NOT NULL AND (name IS NOT NULL OR inhaber IS NOT NULL OR ort IS NOT NULL OR website IS NOT NULL);
CREATE OR REPLACE FUNCTION public.ally_web_aktion(p_token text, p_aktion text, p_daten jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
  s record;
  d jsonb := coalesce(p_daten, '{}'::jsonb);
  u text;
  m text := NULL;
  fehler text := NULL;
  k text;
  v text;
  n integer;
  code text;
  ziel text;
  pw text;
  f record;
  neue_rechte text[];
  em text;
  sa_alt boolean;
  sa_neu boolean;
  grenze text;
BEGIN
  SELECT * INTO s FROM ally_web_sitzung_pruefen(p_token);
  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'angemeldet', false);
  END IF;
  u := s.matrix_user_id;

  IF p_aktion = 'abmelden' THEN
    DELETE FROM ally_web_sitzungen WHERE token_hash = s.token_hash;
    RETURN jsonb_build_object('ok', true, 'abmelden', true);
  END IF;

  -- Nach Anmeldung mit Startcode ist nur das Setzen eines Passworts erlaubt
  IF s.muss_pw_setzen AND p_aktion <> 'passwort_setzen' THEN
    RETURN jsonb_build_object('ok', false, 'angemeldet', true);
  END IF;

  IF p_aktion = 'passwort_setzen' THEN
    -- Nach der Anmeldung mit Startcode: eigenes Passwort festlegen
    pw := coalesce(d->>'neu', '');
    IF pw !~ '^[0-9a-f]{64}$' THEN
      fehler := 'Das Passwort konnte nicht verarbeitet werden. Bitte die Seite neu laden.';
    ELSIF coalesce(d->>'laenge', '0') !~ '^[0-9]+$' OR (d->>'laenge')::int < 10 THEN
      fehler := 'Das neue Passwort muss mindestens 10 Zeichen lang sein.';
    ELSIF pw <> coalesce(d->>'wiederholung', '') THEN
      fehler := 'Die beiden neuen Passwörter stimmen nicht überein.';
    ELSE
      UPDATE ally_personen SET pw_hash = crypt(pw, gen_salt('bf', 12)), pw_alt_name = NULL,
        benutzername = CASE WHEN email IS NOT NULL THEN NULL ELSE benutzername END,
        startcode_hash = NULL, startcode_bis = NULL, geaendert_am = now() WHERE matrix_user_id = u;
      DELETE FROM ally_web_sitzungen WHERE matrix_user_id = u AND token_hash <> s.token_hash;
      UPDATE ally_web_sitzungen SET muss_pw_setzen = false, ablauf = now() + interval '30 days' WHERE token_hash = s.token_hash;
      m := 'Passwort gespeichert. Ab jetzt meldest du dich mit deiner E-Mail-Adresse und diesem Passwort an.';
    END IF;

  ELSIF p_aktion = 'profil' THEN
    -- Mein Profil: Name, E-Mail-Adresse, Passwort. Bisheriges Passwort nur nötig, wenn sich E-Mail oder Passwort ändern.
    k := trim(coalesce(d->>'name', ''));
    em := lower(trim(coalesce(d->>'email', '')));
    pw := coalesce(d->>'neu', '');
    IF k = '' THEN
      fehler := 'Bitte deinen Namen angeben.';
    ELSIF em !~ '^[^@[:space:]]+@[^@[:space:]]+[.][^@[:space:]]+$' THEN
      fehler := 'Bitte eine gültige E-Mail-Adresse angeben.';
    ELSIF EXISTS (SELECT 1 FROM ally_personen WHERE email = em AND matrix_user_id <> u) THEN
      fehler := 'Diese E-Mail-Adresse gehört schon zu einer anderen Person.';
    ELSIF (pw <> '' OR em IS DISTINCT FROM (SELECT email FROM ally_personen WHERE matrix_user_id = u))
          AND NOT EXISTS (SELECT 1 FROM ally_personen z WHERE z.matrix_user_id = u AND z.pw_hash IS NOT NULL AND z.pw_hash = crypt(coalesce(d->>'alt', ''), z.pw_hash)) THEN
      fehler := 'Das bisherige Passwort stimmt nicht.';
    ELSIF pw <> '' AND pw !~ '^[0-9a-f]{64}$' THEN
      fehler := 'Das Passwort konnte nicht verarbeitet werden. Bitte die Seite neu laden.';
    ELSIF pw <> '' AND (coalesce(d->>'laenge', '0') !~ '^[0-9]+$' OR (d->>'laenge')::int < 10) THEN
      fehler := 'Das neue Passwort muss mindestens 10 Zeichen lang sein.';
    ELSIF pw <> '' AND pw <> coalesce(d->>'wiederholung', '') THEN
      fehler := 'Die beiden neuen Passwörter stimmen nicht überein.';
    ELSE
      UPDATE ally_personen SET name = k, email = em,
        pw_hash = CASE WHEN pw <> '' THEN crypt(pw, gen_salt('bf', 12)) ELSE pw_hash END,
        pw_alt_name = CASE WHEN pw <> '' THEN NULL ELSE pw_alt_name END,
        benutzername = CASE WHEN pw <> '' OR pw_alt_name IS NULL THEN NULL ELSE benutzername END,
        geaendert_am = now()
      WHERE matrix_user_id = u;
      IF pw <> '' THEN
        DELETE FROM ally_web_sitzungen WHERE matrix_user_id = u AND token_hash <> s.token_hash;
      END IF;
      m := 'Profil gespeichert.' || CASE WHEN pw <> '' THEN ' Das neue Passwort gilt ab sofort, andere Anmeldungen wurden beendet.' ELSE '' END;
    END IF;

  ELSIF p_aktion = 'funktionen' THEN
    FOR f IN
      SELECT fx.schluessel FROM ally_funktionen fx
      WHERE (fx.schluessel <> 'systemfehler_meldung' OR ally_hat_recht(u, 'admin'))
         AND (fx.schluessel NOT LIKE 'mail_rueckfrage_%'
         OR EXISTS (SELECT 1 FROM ally_postfaecher p WHERE p.schalter = fx.schluessel AND ally_postfach_zustaendig(u, p.adresse)))
    LOOP
      IF d ? ('sichtbar__' || f.schluessel) THEN
        INSERT INTO ally_nutzer_funktionen (matrix_user_id, schluessel, aktiv) VALUES (u, f.schluessel, d ? ('an__' || f.schluessel))
        ON CONFLICT (matrix_user_id, schluessel) DO UPDATE SET aktiv = EXCLUDED.aktiv, geaendert_am = now()
        WHERE ally_nutzer_funktionen.aktiv IS DISTINCT FROM EXCLUDED.aktiv;
      END IF;
    END LOOP;
    m := 'Funktionen gespeichert.';

  ELSIF p_aktion = 'einstellungen' THEN
    -- Marketing-Felder sind optional: sie stehen seit 15.10.2026 auf der eigenen Seite "Marketing" (Aktion marketing)
    IF ally_web_uhrzeit(d->>'briefing_uhrzeit') IS NULL OR (d ? 'marketing_uhrzeit' AND ally_web_uhrzeit(d->>'marketing_uhrzeit') IS NULL) THEN
      fehler := 'Bitte die Uhrzeiten im Format HH:MM angeben.';
    ELSIF d ? 'marketing_tag' AND coalesce(d->>'marketing_tag', '') !~ '^[1-7]$' THEN
      fehler := 'Bitte einen Wochentag wählen.';
    ELSIF coalesce(d->>'standard_postfach', '') <> '' AND NOT ally_postfach_zustaendig(u, d->>'standard_postfach') THEN
      fehler := 'Als Standard-Postfach geht nur ein Postfach, das du siehst.';
    ELSIF trim(coalesce(d->>'absender_name', '')) = '' OR trim(coalesce(d->>'signatur_name', '')) = '' THEN
      fehler := 'Absendername und Name in der Signatur dürfen nicht leer sein.';
    ELSE
      PERFORM ally_web_wert_setzen(u, 'briefing_uhrzeit', ally_web_uhrzeit(d->>'briefing_uhrzeit'));
      IF d ? 'marketing_uhrzeit' THEN PERFORM ally_web_wert_setzen(u, 'marketing_uhrzeit', ally_web_uhrzeit(d->>'marketing_uhrzeit')); END IF;
      IF d ? 'marketing_tag' THEN PERFORM ally_web_wert_setzen(u, 'marketing_tag', d->>'marketing_tag'); END IF;
      PERFORM ally_web_wert_setzen(u, 'kalender_id', trim(coalesce(d->>'kalender_id', '')));
      PERFORM ally_web_wert_setzen(u, 'standard_postfach', lower(trim(coalesce(d->>'standard_postfach', ''))));
      IF d ? 'marketing_profil' THEN PERFORM ally_web_wert_setzen(u, 'marketing_profil', trim(coalesce(d->>'marketing_profil', ''))); END IF;
      PERFORM ally_web_wert_setzen(u, 'absender_name', trim(d->>'absender_name'));
      PERFORM ally_web_wert_setzen(u, 'signatur_name', trim(d->>'signatur_name'));
      m := 'Einstellungen gespeichert.';
    END IF;

  ELSIF p_aktion = 'postfach' THEN
    ziel := lower(trim(coalesce(d->>'adresse', '')));
    -- Migration 90: persönliche Postfächer stellt nur die Person ein, der sie gehören; gemeinsame wer „Gemeinsame Postfächer verwalten“ hat
    IF NOT EXISTS (SELECT 1 FROM ally_postfaecher WHERE adresse = ziel) THEN
      fehler := 'Unbekanntes Postfach.';
    ELSIF NOT ally_postfach_verwalten_darf(u, ziel) THEN
      fehler := CASE WHEN (SELECT x.art FROM ally_postfaecher x WHERE x.adresse = ziel) = 'persoenlich'
        THEN 'Dieses Postfach gehört einer anderen Person. Einstellen kann es nur sie.'
        ELSE 'Dafür fehlt dir das Recht „Gemeinsame Postfächer verwalten“.' END;
    ELSIF trim(coalesce(d->>'entwurf_ordner', '')) = '' THEN
      fehler := 'Bitte einen Entwurfsordner wählen.';
    ELSIF EXISTS (SELECT 1 FROM postfach_plaetze pp WHERE pp.adresse = ziel AND jsonb_typeof(pp.ordner) = 'array'
                  AND jsonb_array_length(pp.ordner) > 0 AND NOT (pp.ordner ? trim(d->>'entwurf_ordner'))) THEN
      fehler := 'Diesen Entwurfsordner gibt es im Postfach nicht. Bitte aus der Liste wählen oder die Ordner neu einlesen.';
    ELSIF d ? 'einordnung_sichtbar' AND NOT (d ? 'gemeinsam') AND EXISTS (
          SELECT 1 FROM jsonb_each_text(CASE WHEN jsonb_typeof(d->'einordnung') = 'object' THEN d->'einordnung' ELSE '{}'::jsonb END) e
          WHERE e.key IN ('kunde', 'geschaeft', 'spam', 'system_report')
            AND NOT (e.value IN ('nichts', 'hinweis') OR (e.value LIKE 'ordner:_%' AND NOT EXISTS (SELECT 1 FROM postfach_plaetze pp WHERE pp.adresse = ziel
              AND jsonb_typeof(pp.ordner) = 'array' AND jsonb_array_length(pp.ordner) > 0 AND NOT (pp.ordner ? substr(e.value, 8)))))) THEN
      fehler := 'Bei der Einordnung ist ein Ordner gewählt, den es im Postfach nicht gibt. Bitte aus der Liste wählen oder die Ordner neu einlesen.';
    ELSIF d ? 'unternehmen_sichtbar' AND coalesce(d->>'unternehmen_id', '') <> ''
          AND NOT EXISTS (SELECT 1 FROM ally_unternehmen WHERE id::text = d->>'unternehmen_id' AND geloescht_am IS NULL) THEN
      fehler := 'Unbekanntes Unternehmen.';
    ELSE
      UPDATE ally_postfaecher SET
        unternehmen_id = CASE WHEN d ? 'unternehmen_sichtbar' THEN nullif(d->>'unternehmen_id', '')::int ELSE unternehmen_id END,
        name = coalesce(nullif(trim(d->>'name'), ''), name),
        aktiv = d ? 'aktiv',
        entwurf_ordner = trim(d->>'entwurf_ordner'),
        signatur_html = nullif(trim(coalesce(d->>'signatur_html', '')), ''),
        signatur_text = nullif(trim(coalesce(d->>'signatur_text', '')), ''),
        schrift = coalesce((SELECT ms.schluessel FROM mail_schriften ms WHERE ms.schluessel = d->>'schrift'), schrift),
        angebot_bei = CASE WHEN d ? 'angebot_sichtbar' THEN ARRAY(SELECT DISTINCT x FROM jsonb_array_elements_text(CASE WHEN jsonb_typeof(d->'angebot') = 'array' THEN d->'angebot' ELSE '[]'::jsonb END) x
          WHERE x IN ('kunde', 'geschaeft', 'antwort')) ELSE angebot_bei END,
        eigene_einordnung = CASE WHEN d ? 'einordnung_sichtbar' THEN NOT (d ? 'gemeinsam') ELSE eigene_einordnung END,
        einordnung = CASE WHEN d ? 'einordnung_sichtbar' AND NOT (d ? 'gemeinsam') THEN (SELECT coalesce(jsonb_object_agg(e.key, e.value), '{}'::jsonb)
          FROM jsonb_each_text(CASE WHEN jsonb_typeof(d->'einordnung') = 'object' THEN d->'einordnung' ELSE '{}'::jsonb END) e
          WHERE e.key IN ('kunde', 'geschaeft', 'spam', 'system_report') AND (e.value IN ('nichts', 'hinweis') OR e.value LIKE 'ordner:_%')) ELSE einordnung END,
        schrift_groesse = CASE WHEN coalesce(d->>'schrift_groesse', '') ~ '^[0-9]{1,2}$' AND (d->>'schrift_groesse')::int BETWEEN 10 AND 20 THEN (d->>'schrift_groesse')::int ELSE schrift_groesse END,
        geaendert_am = now()
      WHERE adresse = ziel;
      UPDATE postfach_plaetze SET belege_erfassen = (d ? 'belege'), geaendert_am = now()
      WHERE adresse = ziel AND d ? 'belege_sichtbar' AND belege_erfassen IS DISTINCT FROM (d ? 'belege');
      -- Migration 90: keine Zuständigen je Postfach mehr (Sichtbarkeit gemeinsamer Postfächer steht in der Rolle)
      m := 'Postfach ' || ziel || ' gespeichert' || CASE WHEN d ? 'aktiv' THEN '.' ELSE ' (pausiert).' END;
    END IF;

  ELSIF p_aktion = 'regel_neu' THEN
    -- Absender-Regel, auf Wunsch nur für ein Postfach (gleiche Funktion wie im Chat)
    v := mail_regel_speichern(u, d->>'muster', d->>'kategorie', d->>'notiz', d->>'postfach', 'web')::text;
    IF (v::jsonb->>'ok')::boolean THEN m := v::jsonb->>'meldung'; ELSE fehler := v::jsonb->>'meldung'; END IF;

  ELSIF p_aktion = 'regel_loeschen' THEN
    v := mail_regel_loeschen(u, d->>'muster', coalesce(nullif(d->>'postfach', ''), 'alle'))::text;
    IF (v::jsonb->>'ok')::boolean THEN m := v::jsonb->>'meldung'; ELSE fehler := v::jsonb->>'meldung'; END IF;

  ELSIF p_aktion IN ('regel_wiederherstellen', 'regel_endgueltig', 'regel_papierkorb_leeren') THEN
    -- Migration 128: Papierkorb der Absender-Regeln (E13)
    v := mail_regel_papierkorb(u, p_aktion, CASE WHEN p_aktion = 'regel_papierkorb_leeren' THEN d->>'ids' ELSE d->>'id' END)::text;
    IF (v::jsonb->>'ok')::boolean THEN m := v::jsonb->>'meldung'; ELSE fehler := v::jsonb->>'meldung'; END IF;

  ELSIF p_aktion = 'unternehmen' THEN
    -- Unternehmen anlegen oder ändern (nur Admins); Postfächer werden einem Unternehmen zugeordnet
    k := left(trim(coalesce(d->>'name', '')), 120);
    v := coalesce(d->>'id', '');
    IF NOT ally_hat_recht(u, 'admin') THEN
      fehler := 'Unternehmensdaten ändern Admins.';
    ELSIF k = '' THEN
      fehler := 'Bitte den Namen des Unternehmens angeben.';
    ELSIF v <> '' AND NOT EXISTS (SELECT 1 FROM ally_unternehmen WHERE id::text = v AND geloescht_am IS NULL) THEN
      fehler := 'Unbekanntes Unternehmen.';
    ELSIF EXISTS (SELECT 1 FROM ally_unternehmen WHERE lower(trim(name)) = lower(k) AND id::text <> v AND geloescht_am IS NULL) THEN
      fehler := 'Ein Unternehmen mit diesem Namen gibt es schon.';
    ELSIF EXISTS (SELECT 1 FROM ally_unternehmen WHERE lower(trim(name)) = lower(k) AND id::text <> v) THEN
      fehler := 'Ein Unternehmen mit diesem Namen liegt im Papierkorb. Bitte dort wiederherstellen oder endgültig löschen.';
    ELSIF trim(coalesce(d->>'website', '')) <> '' AND trim(d->>'website') !~* '^(https?://)?[a-z0-9.-]+[.][a-z]{2,}(/[^[:space:]]*)?$' THEN
      fehler := 'Bitte die Website als Adresse angeben, z. B. www.beispiel.de.';
    ELSIF v = '' THEN
      INSERT INTO ally_unternehmen (name, inhaber, ort, website, leistungen)
      VALUES (k, nullif(left(trim(coalesce(d->>'inhaber', '')), 120), ''), nullif(left(trim(coalesce(d->>'ort', '')), 120), ''),
              nullif(left(trim(coalesce(d->>'website', '')), 200), ''), nullif(left(trim(coalesce(d->>'leistungen', '')), 2000), ''));
      m := 'Unternehmen ' || k || ' angelegt. Jetzt bei den Postfächern zuordnen.';
      -- Migration 197 (Plan 64, Stefan 01.11.2026, eine Quelle): ohne eigenes Unternehmen wird das erste angelegte das eigene
      IF eigenes_unternehmen_festlegen((SELECT max(ux.id) FROM ally_unternehmen ux WHERE lower(trim(ux.name)) = lower(k) AND ux.geloescht_am IS NULL)) THEN
        m := 'Unternehmen ' || k || ' angelegt und als eigenes Unternehmen festgelegt. Name, Logo und Farben gelten überall, z. B. auf der Anmeldeseite, in Mails und in Einladungen.';
      END IF;
    ELSE
      UPDATE ally_unternehmen SET name = k,
        inhaber = nullif(left(trim(coalesce(d->>'inhaber', '')), 120), ''), ort = nullif(left(trim(coalesce(d->>'ort', '')), 120), ''),
        website = nullif(left(trim(coalesce(d->>'website', '')), 200), ''), leistungen = nullif(left(trim(coalesce(d->>'leistungen', '')), 2000), ''),
        geaendert_am = now()
      WHERE id::text = v;
      m := 'Unternehmen ' || k || ' gespeichert.';
      IF eigenes_unternehmen_festlegen(v::int) THEN
        m := 'Unternehmen ' || k || ' gespeichert und als eigenes Unternehmen festgelegt. Name, Logo und Farben gelten überall, z. B. auf der Anmeldeseite, in Mails und in Einladungen.';
      END IF;
    END IF;

  ELSIF p_aktion = 'unternehmen_loeschen' THEN
    v := coalesce(d->>'id', '');
    IF NOT ally_hat_recht(u, 'admin') THEN
      fehler := 'Unternehmensdaten ändern Admins.';
    ELSIF NOT EXISTS (SELECT 1 FROM ally_unternehmen WHERE id::text = v AND geloescht_am IS NULL) THEN
      fehler := 'Unbekanntes Unternehmen.';
    ELSIF EXISTS (SELECT 1 FROM ally_firma firma_x WHERE firma_x.unternehmen_id::text = v) THEN
      fehler := 'Das ist dein eigenes Unternehmen. Belege, Marketing und ' || produkt_name() || ' nutzen diese Angaben, deshalb lässt es sich nicht löschen.';
    ELSIF EXISTS (SELECT 1 FROM ally_postfaecher WHERE unternehmen_id::text = v) THEN
      fehler := 'Dieses Unternehmen ist noch einem Postfach zugeordnet. Bitte dort zuerst ein anderes Unternehmen wählen.';
    ELSE
      -- Migration 129: in den Papierkorb (Corporate Design und Hintergründe bleiben bis zum endgültigen Löschen)
      UPDATE ally_unternehmen SET geloescht_am = now(), geloescht_von = u WHERE id::text = v RETURNING name INTO k;
      m := 'Unternehmen ' || k || ' liegt jetzt im Papierkorb. Dort kannst du es wiederherstellen oder endgültig löschen.';
    END IF;

  ELSIF p_aktion LIKE 'person_%' AND NOT ally_hat_recht(u, 'admin') THEN
    fehler := 'Personen und Rechte verwaltet nur eine Person mit der Rolle Admin.';

  -- Superadmin-Schutz (Stefan 18.10.2026): An einer Person mit Recht Superadmin ändert nur ein Superadmin etwas
  ELSIF p_aktion LIKE 'person_%' AND p_aktion <> 'person_neu' AND ally_person_superadmin(coalesce(d->>'id', '')) AND NOT ally_hat_recht(u, 'superadmin') THEN
    fehler := 'Diese Person ist Superadmin. Änderungen an ihr nehmen nur Superadmins vor.';

  ELSIF p_aktion = 'person_neu' THEN
    v := trim(coalesce(d->>'id', ''));
    k := trim(coalesce(d->>'name', ''));
    IF v !~ '^@[a-z0-9._=/+\-]+:[a-z0-9.\-]+\.[a-z]{2,}$' THEN
      fehler := 'Bitte die Chat-Adresse vollständig angeben, z. B. @anna:' || split_part(u, ':', 2) || '.';
    ELSIF k = '' THEN
      fehler := 'Bitte einen Namen angeben.';
    ELSIF EXISTS (SELECT 1 FROM ally_personen WHERE matrix_user_id = v) THEN
      fehler := 'Diese Person gibt es schon.';
    ELSIF coalesce(trim(d->>'email'), '') <> '' AND lower(trim(d->>'email')) !~ '^[^@[:space:]]+@[^@[:space:]]+[.][^@[:space:]]+$' THEN
      fehler := 'Bitte eine gültige E-Mail-Adresse angeben.';
    ELSIF coalesce(trim(d->>'email'), '') <> '' AND EXISTS (SELECT 1 FROM ally_personen WHERE email = lower(trim(d->>'email'))) THEN
      fehler := 'Diese E-Mail-Adresse gehört schon zu einer anderen Person.';
    ELSE
      em := nullif(lower(trim(coalesce(d->>'email', ''))), '');
      INSERT INTO ally_personen (matrix_user_id, name, email, aktiv) VALUES (v, k, em, true);
      m := k || ' angelegt. Jetzt Rechte setzen und einen Zugang mit Startcode erzeugen.';
    END IF;

  ELSIF p_aktion IN ('person_zugang', 'person_sperren', 'person_freigeben', 'person_rechte', 'person_ally', 'person_daten') THEN
    ziel := coalesce(d->>'id', '');
    IF NOT EXISTS (SELECT 1 FROM ally_personen WHERE matrix_user_id = ziel) THEN
      fehler := 'Unbekannte Person.';
    -- Migration 158 (Bauplan B3a): Talent-Personen ändert man im Talent-Profil.
    ELSIF ally_person_ist_talent(ziel) THEN
      fehler := 'Den Zugang eines Talents änderst du im Talent-Profil.';

    ELSIF p_aktion = 'person_rechte' THEN
      -- Superadmin (Stefan 18.10.2026): wird getrennt behandelt; vergeben oder entziehen darf es nur ein Superadmin, sonst bleibt der bisherige Stand
      SELECT coalesce(array_agg(r.schluessel), '{}') INTO neue_rechte FROM ally_rechte r WHERE d ? ('recht__' || r.schluessel) AND (r.modul IS NULL OR plattform_modul_an(r.modul))
        AND r.schluessel = 'admin';  -- Migration 167 (Bauplan B6): F13, hier nur noch admin (superadmin getrennt); alle übrigen Rechte in der Rolle oder unter „Eigene Rechte“
      sa_alt := ally_person_superadmin(ziel);
      -- Migration 167 (Bauplan B6): Prüfung M1, ohne Kennung recht__superadmin_feld (Häkchen „Superadmin“ im Formular) bleibt der bisherige Stand
      sa_neu := CASE WHEN ally_hat_recht(u, 'superadmin') AND d ? 'recht__superadmin_feld' THEN d ? 'recht__superadmin' ELSE sa_alt END;
      IF d ? 'recht__superadmin' AND NOT sa_alt AND NOT ally_hat_recht(u, 'superadmin') THEN
        fehler := 'Das Recht Superadmin vergeben nur Superadmins.';
      -- Migration 168 (Bauplan B7): G1, Superadmin nur für Personen aus der Liste superadmin_personen
      ELSIF sa_neu AND NOT sa_alt AND NOT ally_superadmin_erlaubt(ziel) THEN
        fehler := 'Das Recht Superadmin lässt sich hier nicht vergeben.';
      ELSIF ziel = u AND NOT ('admin' = ANY (neue_rechte)) THEN
        fehler := 'Du kannst dir das Admin-Recht nicht selbst entziehen.';
      ELSIF sa_alt AND NOT sa_neu AND NOT EXISTS (SELECT 1 FROM ally_nutzer_rechte x WHERE x.recht = 'superadmin' AND x.matrix_user_id <> ziel) THEN
        fehler := 'Der letzte Superadmin kann das Recht Superadmin nicht abgeben. Bitte zuerst einer anderen Person das Recht Superadmin geben.';
      ELSE
        -- Rechte nicht gebuchter Pakete bleiben erhalten (auf der Seite nicht sichtbar)
        DELETE FROM ally_nutzer_rechte WHERE matrix_user_id = ziel AND recht = 'admin' AND NOT (recht = ANY (neue_rechte));
        INSERT INTO ally_nutzer_rechte (matrix_user_id, recht) SELECT ziel, x FROM unnest(neue_rechte) AS x ON CONFLICT DO NOTHING;
        IF sa_neu AND NOT sa_alt THEN
          INSERT INTO ally_nutzer_rechte (matrix_user_id, recht) VALUES (ziel, 'superadmin') ON CONFLICT DO NOTHING;
        ELSIF sa_alt AND NOT sa_neu THEN
          DELETE FROM ally_nutzer_rechte WHERE matrix_user_id = ziel AND recht = 'superadmin';
        END IF;
        m := 'Rechte von ' || (SELECT name FROM ally_personen WHERE matrix_user_id = ziel) || ' gespeichert.'
          || CASE WHEN EXISTS (SELECT 1 FROM jsonb_object_keys(d) AS kq(feld) WHERE kq.feld LIKE 'recht\_\_%' AND kq.feld NOT IN ('recht__admin', 'recht__superadmin', 'recht__superadmin_feld'))
             THEN ' Weitere Rechte stehen in der Rolle oder unter „Eigene Rechte“ (Einstellungen › Team und Rollen).' ELSE '' END;
      END IF;

    ELSIF p_aktion = 'person_ally' THEN
      IF ziel = u THEN
        fehler := 'Du kannst dich nicht selbst deaktivieren.';
      -- Migration 172 (B8b, Fixieren): ist das Admin-Recht der Person fixiert, deaktiviert sie nur ein Superadmin
      ELSIF d->>'aktiv' IS DISTINCT FROM '1' AND ally_fix_person_geschuetzt(ziel, u) THEN
        fehler := 'Das Admin-Recht von ' || (SELECT name FROM ally_personen WHERE matrix_user_id = ziel) || ' ist fixiert. Deaktivieren kann sie nur ein Superadmin.';
      ELSE
        UPDATE ally_personen SET aktiv = (d->>'aktiv' = '1'), geaendert_am = now() WHERE matrix_user_id = ziel;
        IF d->>'aktiv' <> '1' THEN DELETE FROM ally_web_sitzungen WHERE matrix_user_id = ziel; END IF;
        m := CASE WHEN d->>'aktiv' = '1' THEN 'Person wieder aktiv: Chat und Oberfläche sind freigeschaltet.' ELSE 'Person deaktiviert: kein Chat mit ' || produkt_name() || ' und keine Anmeldung mehr. Rechte und Zuordnungen als Manager/in bleiben gespeichert.' END;
      END IF;

    ELSIF NOT EXISTS (SELECT 1 FROM ally_nutzer WHERE matrix_user_id = ziel) THEN
      fehler := 'Die Person ist deaktiviert. Bitte zuerst wieder aktivieren.';

    ELSIF p_aktion = 'person_daten' THEN
      -- Name und E-Mail-Adresse einer Person ändern (Admin); das Passwort bleibt gültig
      k := trim(coalesce(d->>'name', ''));
      em := nullif(lower(trim(coalesce(d->>'email', ''))), '');
      IF k = '' THEN
        fehler := 'Bitte einen Namen angeben.';
      ELSIF em IS NULL AND (SELECT pw_hash IS NOT NULL OR startcode_hash IS NOT NULL FROM ally_personen WHERE matrix_user_id = ziel) THEN
        fehler := 'Wer einen Zugang hat, braucht eine E-Mail-Adresse. Damit meldet sich die Person an.';
      ELSIF em IS NOT NULL AND em !~ '^[^@[:space:]]+@[^@[:space:]]+[.][^@[:space:]]+$' THEN
        fehler := 'Bitte eine gültige E-Mail-Adresse angeben.';
      ELSIF em IS NOT NULL AND EXISTS (SELECT 1 FROM ally_personen WHERE email = em AND matrix_user_id <> ziel) THEN
        fehler := 'Diese E-Mail-Adresse gehört schon zu einer anderen Person.';
      ELSE
        UPDATE ally_personen SET name = k, email = em, geaendert_am = now() WHERE matrix_user_id = ziel;
        m := 'Angaben von ' || k || ' gespeichert.';
      END IF;

    ELSIF p_aktion = 'person_zugang' THEN
      -- Startcode erzeugen: Anmeldung mit der E-Mail-Adresse der Person und dem Startcode
      em := (SELECT email FROM ally_personen WHERE matrix_user_id = ziel);
      IF em IS NULL THEN
        fehler := 'Bitte zuerst eine E-Mail-Adresse für ' || (SELECT name FROM ally_personen WHERE matrix_user_id = ziel) || ' eintragen. Damit meldet sich die Person an.';
      ELSE
        code := ally_web_startcode();
        UPDATE ally_personen SET
          pw_hash = CASE WHEN matrix_user_id = u THEN pw_hash ELSE NULL END,
          pw_alt_name = CASE WHEN matrix_user_id = u THEN pw_alt_name ELSE NULL END,
          startcode_hash = crypt(ally_web_hash('ally-code:' || replace(code, '-', '')), gen_salt('bf', 10)), startcode_bis = now() + interval '7 days',
          fehlversuche = 0, gesperrt_bis = NULL, geaendert_am = now()
        WHERE matrix_user_id = ziel;
        IF ziel <> u THEN
          DELETE FROM ally_web_sitzungen WHERE matrix_user_id = ziel;
        END IF;
        m := 'Startcode für ' || (SELECT name FROM ally_personen WHERE matrix_user_id = ziel) || ': ' || code ||
             '. Anmeldung mit ' || em || ' und diesem Startcode als Passwort. Gültig 7 Tage, nur einmal verwendbar. Er wird nur jetzt angezeigt.';
      END IF;

    ELSE
      IF ziel = u THEN
        fehler := 'Du kannst deinen eigenen Zugang nicht sperren.';
      -- Migration 172 (B8b, Fixieren): ist das Admin-Recht der Person fixiert, sperrt ihren Zugang nur ein Superadmin
      ELSIF p_aktion = 'person_sperren' AND ally_fix_person_geschuetzt(ziel, u) THEN
        fehler := 'Das Admin-Recht von ' || (SELECT name FROM ally_personen WHERE matrix_user_id = ziel) || ' ist fixiert. Den Zugang sperren kann nur ein Superadmin.';
      ELSIF NOT EXISTS (SELECT 1 FROM ally_personen WHERE matrix_user_id = ziel AND (pw_hash IS NOT NULL OR startcode_hash IS NOT NULL)) THEN
        fehler := 'Die Person hat noch keinen Zugang.';
      ELSE
        UPDATE ally_personen SET zugang_aktiv = (p_aktion = 'person_freigeben'), geaendert_am = now() WHERE matrix_user_id = ziel;
        IF p_aktion = 'person_sperren' THEN DELETE FROM ally_web_sitzungen WHERE matrix_user_id = ziel; END IF;
        m := 'Zugang zur Oberfläche ' || CASE WHEN p_aktion = 'person_sperren' THEN 'gesperrt. Der Chat mit ' || produkt_name() || ' bleibt möglich.' ELSE 'freigeschaltet.' END;
      END IF;
    END IF;

  ELSIF p_aktion = 'cd' THEN
    -- Corporate Design eines Unternehmens: Schrift und Grundfarben (nur Admins)
    v := coalesce(d->>'id', '');
    k := trim(coalesce(d->>'schrift', ''));
    IF NOT ally_hat_recht(u, 'admin') THEN
      fehler := 'Unternehmensdaten ändern Admins.';
    ELSIF NOT plattform_cd_gebraucht() THEN
      fehler := 'Das Corporate Design wird erst mit einem Paket gebraucht, das Berichte oder Grafiken erstellt.';
    ELSIF NOT EXISTS (SELECT 1 FROM ally_unternehmen WHERE id::text = v AND geloescht_am IS NULL) THEN
      fehler := 'Unbekanntes Unternehmen.';
    ELSIF k !~ '^[A-Za-z0-9 ]{1,60}$' THEN
      fehler := 'Bitte die Schrift so angeben, wie sie bei Google Fonts heißt, z. B. Raleway oder Open Sans.';
    ELSIF EXISTS (SELECT 1 FROM unnest(ARRAY['farbe_dunkel', 'farbe_text_auf_dunkel', 'farbe_akzent', 'farbe_akzent_dunkel', 'farbe_hell', 'farbe_grau', 'farbe_warnung']) AS fx(x)
                  WHERE upper(coalesce(d->>fx.x, '')) !~ '^#[0-9A-F]{6}$') THEN
      fehler := 'Bitte alle Farben im Format #RRGGBB angeben, z. B. #171D23.';
    ELSE
      INSERT INTO ally_cd (unternehmen_id, schrift, farbe_dunkel, farbe_text_auf_dunkel, farbe_akzent, farbe_akzent_dunkel, farbe_hell, farbe_grau, farbe_warnung)
      VALUES (v::int, k, upper(d->>'farbe_dunkel'), upper(d->>'farbe_text_auf_dunkel'), upper(d->>'farbe_akzent'), upper(d->>'farbe_akzent_dunkel'),
              upper(d->>'farbe_hell'), upper(d->>'farbe_grau'), upper(d->>'farbe_warnung'))
      ON CONFLICT (unternehmen_id) DO UPDATE SET schrift = EXCLUDED.schrift, farbe_dunkel = EXCLUDED.farbe_dunkel,
        farbe_text_auf_dunkel = EXCLUDED.farbe_text_auf_dunkel, farbe_akzent = EXCLUDED.farbe_akzent, farbe_akzent_dunkel = EXCLUDED.farbe_akzent_dunkel,
        farbe_hell = EXCLUDED.farbe_hell, farbe_grau = EXCLUDED.farbe_grau, farbe_warnung = EXCLUDED.farbe_warnung, geaendert_am = now();
      m := 'Corporate Design von ' || (SELECT name FROM ally_unternehmen WHERE id::text = v) || ' gespeichert.';
    END IF;

  ELSIF p_aktion = 'cd_datei_loeschen' THEN
    -- Nur das Logo für helle Flächen ist freiwillig; die anderen Dateien lassen sich nur ersetzen
    v := coalesce(d->>'id', '');
    IF NOT ally_hat_recht(u, 'admin') THEN
      fehler := 'Unternehmensdaten ändern Admins.';
    ELSIF NOT plattform_cd_gebraucht() THEN
      fehler := 'Das Corporate Design wird erst mit einem Paket gebraucht, das Berichte oder Grafiken erstellt.';
    ELSIF EXISTS (SELECT 1 FROM ally_unternehmen ux WHERE ux.id::text = v AND ux.geloescht_am IS NOT NULL) THEN
      fehler := 'Das Unternehmen liegt im Papierkorb. Seine Dateien gehen erst beim endgültigen Löschen mit.';
    ELSIF coalesce(d->>'art', '') <> 'logo_fuer_hell' THEN
      fehler := 'Diese Datei wird gebraucht. Du kannst sie durch eine neue ersetzen, aber nicht entfernen.';
    ELSE
      DELETE FROM ally_cd_dateien WHERE unternehmen_id::text = v AND art = 'logo_fuer_hell';
      GET DIAGNOSTICS n = ROW_COUNT;
      IF n = 0 THEN fehler := 'Datei nicht gefunden.'; ELSE m := 'Logo für helle Flächen entfernt.'; END IF;
    END IF;

  ELSIF p_aktion = 'marketing' THEN
    -- Seite "Marketing": Wochentag und Uhrzeit der Themenvorschläge, Marketing-Profil (gilt nur für die Person selbst)
    IF NOT plattform_modul_an('marketing') THEN
      fehler := 'Das Paket Marketing ist nicht gebucht.';
    ELSIF ally_web_uhrzeit(d->>'marketing_uhrzeit') IS NULL THEN
      fehler := 'Bitte die Uhrzeit im Format HH:MM angeben.';
    ELSIF coalesce(d->>'marketing_tag', '') !~ '^[1-7]$' THEN
      fehler := 'Bitte einen Wochentag wählen.';
    ELSE
      PERFORM ally_web_wert_setzen(u, 'marketing_tag', d->>'marketing_tag');
      PERFORM ally_web_wert_setzen(u, 'marketing_uhrzeit', ally_web_uhrzeit(d->>'marketing_uhrzeit'));
      PERFORM ally_web_wert_setzen(u, 'marketing_profil', trim(coalesce(d->>'marketing_profil', '')));
      m := 'Marketing-Einstellungen gespeichert.';
    END IF;

  ELSIF p_aktion = 'cd_gestaltung' THEN
    -- Gestaltung der Marketing-Grafiken eines Unternehmens: Folienstile, Akzente, Icons (nur Admins)
    v := coalesce(d->>'id', '');
    IF NOT ally_hat_recht(u, 'admin') THEN
      fehler := 'Unternehmensdaten ändern Admins.';
    ELSIF NOT plattform_modul_an('marketing') THEN
      fehler := 'Das Paket Marketing ist nicht gebucht.';
    ELSIF NOT EXISTS (SELECT 1 FROM ally_cd cx JOIN ally_unternehmen ux ON ux.id = cx.unternehmen_id WHERE cx.unternehmen_id::text = v AND ux.geloescht_am IS NULL) THEN
      fehler := 'Bitte zuerst Schrift und Farben für dieses Unternehmen speichern.';
    ELSIF coalesce(jsonb_typeof(d->'stile'), '') <> 'array'
          OR (NOT EXISTS (SELECT 1 FROM jsonb_array_elements_text(d->'stile') AS st(x) WHERE st.x IN ('dunkel', 'hell', 'akzent'))
              AND NOT EXISTS (SELECT 1 FROM marketing_hintergruende hx WHERE hx.unternehmen_id::text = v)) THEN
      fehler := 'Bitte mindestens einen Folienstil auswählen oder einen eigenen Hintergrund hochladen.';
    ELSE
      UPDATE ally_cd SET
        stile = ARRAY(SELECT st.x FROM unnest(ARRAY['dunkel', 'hell', 'akzent']) WITH ORDINALITY AS st(x, nr) WHERE d->'stile' ? st.x ORDER BY st.nr),
        deko_punkte = d ? 'punkte', deko_boegen = d ? 'boegen', deko_icon = d ? 'gross_icon', icons_an = d ? 'icons',
        icons_aus = CASE WHEN coalesce(jsonb_typeof(d->'icons_liste'), '') = 'array'
                         THEN ARRAY(SELECT ic.name FROM ally_icons ic WHERE NOT (d->'icons_liste' ? ic.name) ORDER BY ic.name) ELSE icons_aus END,
        geaendert_am = now()
      WHERE unternehmen_id::text = v;
      m := 'Gestaltung der Marketing-Grafiken von ' || (SELECT name FROM ally_unternehmen WHERE id::text = v) || ' gespeichert.';
    END IF;

  ELSIF p_aktion = 'hintergrund_loeschen' THEN
    -- Eigenen Hintergrund der Marketing-Grafiken entfernen (Recht „Postfächer verwalten“); ohne Hintergrund und ohne Folienstil gelten wieder alle Stile
    v := coalesce(d->>'bild', '');
    IF NOT ally_hat_recht(u, 'admin') THEN
      fehler := 'Unternehmensdaten ändern Admins.';
    ELSIF v !~ '^[0-9]{1,9}$' THEN
      fehler := 'Hintergrund nicht gefunden.';
    ELSIF EXISTS (SELECT 1 FROM marketing_hintergruende hx JOIN ally_unternehmen ux ON ux.id = hx.unternehmen_id WHERE hx.id = v::int AND ux.geloescht_am IS NOT NULL) THEN
      fehler := 'Das Unternehmen liegt im Papierkorb. Seine Dateien gehen erst beim endgültigen Löschen mit.';
    ELSE
      DELETE FROM marketing_hintergruende WHERE id = v::int RETURNING unternehmen_id::text INTO k;
      IF k IS NULL THEN
        fehler := 'Hintergrund nicht gefunden.';
      ELSE
        UPDATE ally_cd SET stile = ARRAY['dunkel', 'hell', 'akzent'], geaendert_am = now()
        WHERE unternehmen_id::text = k AND cardinality(stile) = 0 AND NOT EXISTS (SELECT 1 FROM marketing_hintergruende hx WHERE hx.unternehmen_id::text = k);
        m := 'Hintergrund entfernt.';
      END IF;
    END IF;

  ELSIF p_aktion = 'startseite' THEN
    -- Reihenfolge und Sichtbarkeit der Kacheln auf der Startseite (gilt nur für die Person selbst; "Einstellungen" bleibt immer sichtbar)
    IF coalesce(jsonb_typeof(d->'reihenfolge'), '') <> 'array' OR coalesce(jsonb_typeof(d->'aus'), '') <> 'array' THEN
      fehler := 'Die Startseite konnte nicht gespeichert werden. Bitte die Seite neu laden.';
    ELSIF jsonb_array_length(d->'reihenfolge') > 20 OR jsonb_array_length(d->'aus') > 20
          OR EXISTS (SELECT 1 FROM jsonb_array_elements(d->'reihenfolge') AS ka(x) WHERE jsonb_typeof(ka.x) <> 'string' OR ka.x #>> '{}' !~ '^[a-z_]{1,30}$')
          OR EXISTS (SELECT 1 FROM jsonb_array_elements(d->'aus') AS ka(x) WHERE jsonb_typeof(ka.x) <> 'string' OR ka.x #>> '{}' !~ '^[a-z_]{1,30}$' OR ka.x #>> '{}' = 'einstellungen') THEN
      fehler := 'Die Startseite konnte nicht gespeichert werden. Bitte die Seite neu laden.';
    ELSE
      PERFORM ally_web_wert_setzen(u, 'kacheln', jsonb_build_object('reihenfolge', d->'reihenfolge', 'aus', d->'aus')::text);
      m := 'Startseite gespeichert.';
    END IF;

  ELSIF p_aktion = 'ki_hinweis' THEN
    -- KI-Hinweis "Erstellt mit KI-Unterstützung." in Mail-Entwürfen bzw. Marketing-Texten, gilt für alle (Stefan 17.10.2026). Ändern nur Admins.
    v := coalesce(d->>'art', '');
    IF NOT ally_hat_recht(u, 'admin') THEN
      fehler := 'Den KI-Hinweis ändern Admins.';
    ELSIF v NOT IN ('mail', 'marketing', 'system') THEN  -- Migration 96: auch Systemnachrichten (ohne Paket)
      fehler := 'Unbekannte Aktion.';
    ELSIF v <> 'system' AND NOT plattform_modul_an(CASE WHEN v = 'mail' THEN 'mail_entwuerfe' ELSE 'marketing' END) THEN
      fehler := 'Dieses Paket ist nicht gebucht.';
    ELSE
      INSERT INTO ally_einstellungen (schluessel, wert, geaendert_am) VALUES ('ki_hinweis_' || v, CASE WHEN d ? 'an' THEN 'an' ELSE 'aus' END, now())
      ON CONFLICT (schluessel) DO UPDATE SET wert = EXCLUDED.wert, geaendert_am = now();
      m := 'KI-Hinweis ' || CASE WHEN v = 'mail' THEN 'in Mail-Entwürfen ' WHEN v = 'system' THEN 'in Systemnachrichten ' ELSE 'in Marketing-Texten ' END || CASE WHEN d ? 'an' THEN 'eingeschaltet.' ELSE 'ausgeschaltet.' END;
    END IF;

  ELSIF p_aktion = 'paket_fuer_mich' THEN
    -- Seite eines Pakets, Teil "Für mich": Schalter der Funktionen dieses Pakets und persönliche Werte (gilt nur für die Person selbst).
    -- "grundpaket" steht für die Benachrichtigungen des Grundpakets (Einstellungen).
    v := coalesce(d->>'paket', '');
    IF NOT (v = 'grundpaket' OR (EXISTS (SELECT 1 FROM plattform_module WHERE schluessel = v) AND plattform_modul_an(v))) THEN
      fehler := 'Dieses Paket ist nicht gebucht.';
    ELSIF (d ? 'briefing_uhrzeit' AND ally_web_uhrzeit(d->>'briefing_uhrzeit') IS NULL) OR (d ? 'marketing_uhrzeit' AND ally_web_uhrzeit(d->>'marketing_uhrzeit') IS NULL) THEN
      fehler := 'Bitte die Uhrzeit im Format HH:MM angeben.';
    ELSIF d ? 'marketing_tag' AND coalesce(d->>'marketing_tag', '') !~ '^[1-7]$' THEN
      fehler := 'Bitte einen Wochentag wählen.';
    ELSIF coalesce(d->>'standard_postfach', '') <> '' AND NOT ally_postfach_zustaendig(u, d->>'standard_postfach') THEN
      fehler := 'Als Standard-Postfach geht nur ein Postfach, das du siehst.';
    ELSIF d ? 'marketing_anzahl' AND coalesce(d->>'marketing_anzahl', '') !~ '^[1-5]$' THEN
      fehler := 'Bitte als Anzahl der Vorschläge 1 bis 5 wählen.';
    ELSIF d ? 'marketing_ansprache' AND coalesce(d->>'marketing_ansprache', '') NOT IN ('du', 'sie') THEN
      fehler := 'Bitte als Ansprache Du oder Sie wählen.';
    ELSIF (d ? 'absender_name' AND trim(coalesce(d->>'absender_name', '')) = '') OR (d ? 'signatur_name' AND trim(coalesce(d->>'signatur_name', '')) = '') THEN
      fehler := 'Absendername und Name in der Signatur dürfen nicht leer sein.';
    ELSE
      FOR f IN
        SELECT fx.schluessel FROM ally_funktionen fx
        WHERE CASE WHEN v = 'grundpaket' THEN fx.modul IS NULL OR fx.modul IN (SELECT pm.schluessel FROM plattform_module pm WHERE pm.grundpaket) ELSE fx.modul = v END
          AND (fx.schluessel <> 'systemfehler_meldung' OR ally_hat_recht(u, 'admin'))
          AND (fx.schluessel NOT LIKE 'mail_rueckfrage_%'
           OR EXISTS (SELECT 1 FROM ally_postfaecher p WHERE p.schalter = fx.schluessel AND ally_postfach_zustaendig(u, p.adresse)))
      LOOP
        IF d ? ('sichtbar__' || f.schluessel) THEN
          INSERT INTO ally_nutzer_funktionen (matrix_user_id, schluessel, aktiv) VALUES (u, f.schluessel, d ? ('an__' || f.schluessel))
          ON CONFLICT (matrix_user_id, schluessel) DO UPDATE SET aktiv = EXCLUDED.aktiv, geaendert_am = now()
          WHERE ally_nutzer_funktionen.aktiv IS DISTINCT FROM EXCLUDED.aktiv;
        END IF;
      END LOOP;
      IF d ? 'briefing_uhrzeit' THEN PERFORM ally_web_wert_setzen(u, 'briefing_uhrzeit', ally_web_uhrzeit(d->>'briefing_uhrzeit')); END IF;
      IF d ? 'kalender_id' THEN PERFORM ally_web_wert_setzen(u, 'kalender_id', trim(coalesce(d->>'kalender_id', ''))); END IF;
      IF d ? 'standard_postfach' THEN PERFORM ally_web_wert_setzen(u, 'standard_postfach', lower(trim(coalesce(d->>'standard_postfach', '')))); END IF;
      IF d ? 'absender_name' THEN PERFORM ally_web_wert_setzen(u, 'absender_name', trim(d->>'absender_name')); END IF;
      IF d ? 'signatur_name' THEN PERFORM ally_web_wert_setzen(u, 'signatur_name', trim(d->>'signatur_name')); END IF;
      IF d ? 'marketing_tag' THEN PERFORM ally_web_wert_setzen(u, 'marketing_tag', d->>'marketing_tag'); END IF;
      IF d ? 'marketing_uhrzeit' THEN PERFORM ally_web_wert_setzen(u, 'marketing_uhrzeit', ally_web_uhrzeit(d->>'marketing_uhrzeit')); END IF;
      IF d ? 'marketing_profil' THEN PERFORM ally_web_wert_setzen(u, 'marketing_profil', trim(coalesce(d->>'marketing_profil', ''))); END IF;
      IF d ? 'marketing_anzahl' THEN PERFORM ally_web_wert_setzen(u, 'marketing_anzahl', d->>'marketing_anzahl'); END IF;
      IF d ? 'marketing_ansprache' THEN PERFORM ally_web_wert_setzen(u, 'marketing_ansprache', d->>'marketing_ansprache'); END IF;
      FOREACH k IN ARRAY ARRAY['marketing_themenfelder', 'marketing_zielgruppe', 'marketing_stil', 'marketing_nogos'] LOOP
        IF d ? k THEN PERFORM ally_web_wert_setzen(u, k, left(trim(coalesce(d->>k, '')), 2000)); END IF;
      END LOOP;
      m := CASE WHEN v = 'grundpaket' THEN 'Benachrichtigungen gespeichert.'
                ELSE 'Einstellungen für ' || (SELECT name FROM plattform_module WHERE schluessel = v) || ' gespeichert.' END;
    END IF;

  ELSE
    fehler := 'Unbekannte Aktion.';
  END IF;

  UPDATE ally_web_sitzungen SET flash = coalesce(fehler, m), flash_art = CASE WHEN fehler IS NULL THEN 'ok' ELSE 'fehler' END
  WHERE token_hash = s.token_hash;
  RETURN jsonb_build_object('ok', fehler IS NULL, 'angemeldet', true);
  -- Migration 172 (B8b, Fixieren): ein fixierter Wert (SQLSTATE AT002) wird zur Meldung, die Änderungen dieser Aktion sind zurückgenommen
EXCEPTION WHEN SQLSTATE 'AT002' THEN
  RETURN ally_fix_meldung(p_token, SQLERRM);
END $function$;
CREATE OR REPLACE FUNCTION public.eigenes_unternehmen()
 RETURNS jsonb
 LANGUAGE sql
 STABLE
AS $function$
  -- Migration 197 (Plan 64, Stefan 01.11.2026, eine Quelle): nur das eigene Unternehmen der Seite Einstellungen › Firmendaten und Design
  -- (ally_firma.unternehmen_id), kein Rückfall auf Angaben in ally_firma. Ohne verknüpftes Unternehmen NULL (neue Installation bis zum Anlegen).
  SELECT jsonb_build_object('name', n.name, 'inhaber', n.inhaber, 'ort', n.ort, 'website', n.website, 'leistungen', n.leistungen,
    'kurz', n.name || coalesce(' in ' || n.ort, '') || coalesce(' (Inhaberschaft: ' || n.inhaber || ')', ''),
    'text', n.name || coalesce(' in ' || n.ort, '') || coalesce(' (Inhaberschaft: ' || n.inhaber || ')', '')
      || coalesce('. Leistungen: ' || n.leistungen, '') || coalesce('. Website: ' || n.website, ''))
  FROM (
    SELECT nullif(trim(x.name), '') AS name,
      nullif(trim(x.inhaber), '') AS inhaber,
      nullif(trim(x.ort), '') AS ort,
      nullif(trim(x.website), '') AS website,
      nullif(trim(x.leistungen), '') AS leistungen
    FROM ally_firma f JOIN ally_unternehmen x ON x.id = f.unternehmen_id
    ORDER BY f.id LIMIT 1) n
$function$;
DO $m$
BEGIN
  IF (SELECT md5(string_agg(z, E'\n' ORDER BY z COLLATE "C")) FROM (WITH t AS (SELECT c.oid, c.relname::text AS tab FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname::text = 'public' COLLATE "C" AND c.relkind::text = ANY (ARRAY['r', 'p']) AND c.relname::text = ANY (ARRAY['ally_firma', 'ally_unternehmen'])) SELECT 'S|' || t.tab || '|' || a.attname::text || '|' || format_type(a.atttypid, a.atttypmod) || '|' || CASE WHEN a.attnotnull THEN 'NN' ELSE '-' END || '|' || coalesce(pg_get_expr(d.adbin, d.adrelid), '') || '|' || a.attidentity::text || a.attgenerated::text AS z FROM t JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum > 0 AND NOT a.attisdropped LEFT JOIN pg_attrdef d ON d.adrelid = t.oid AND d.adnum = a.attnum UNION ALL SELECT 'C|' || t.tab || '|' || co.conname::text || '|' || co.contype::text || '|' || pg_get_constraintdef(co.oid) FROM t JOIN pg_constraint co ON co.conrelid = t.oid UNION ALL SELECT 'I|' || t.tab || '|' || ic.relname::text || '|' || pg_get_indexdef(i.indexrelid) FROM t JOIN pg_index i ON i.indrelid = t.oid JOIN pg_class ic ON ic.oid = i.indexrelid UNION ALL SELECT 'T|' || t.tab || '|' || tg.tgname::text || '|' || pg_get_triggerdef(tg.oid) || '|' || tg.tgenabled::text FROM t JOIN pg_trigger tg ON tg.tgrelid = t.oid AND NOT tg.tgisinternal) x) IS DISTINCT FROM 'd47864c6fec2fc5a2d3031ab71590cc9' THEN RAISE EXCEPTION 'Migration 197: Schema nicht wie gebaut'; END IF;
  IF (SELECT md5(string_agg(p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')|' || pg_get_function_result(p.oid) || '|' || md5(p.prosrc), E'\n' ORDER BY p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')' COLLATE "C")) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname::text = 'public' COLLATE "C" AND p.proname::text COLLATE "C" = ANY (ARRAY['ally_web_aktion', 'eigenes_unternehmen', 'eigenes_unternehmen_festlegen'])) IS DISTINCT FROM 'ea90ee74fbead6e9b328308cc0cc0d65' THEN RAISE EXCEPTION 'Migration 197: Funktionen nicht wie gebaut'; END IF;
  IF current_setting('m197.vorher') IS DISTINCT FROM coalesce(eigenes_unternehmen()::text, '') THEN RAISE EXCEPTION 'Migration 197: Angaben des eigenen Unternehmens hätten sich geändert, nichts geändert'; END IF;
END $m$;
