-- Rückbau 207: Funktionen wörtlich wie vorher (werkzeuge/m207/vorher/), ally_person_speichern, kalender_ansicht und marketing_posten_ui_aktion entfernen.
-- Vorher die Abläufe Oberfläche-Eingang, Einstellungen, Kalender und Marketing auf den Stand vor 207 zurücksetzen. Gemerkte Kalenderansichten (ally_ui_zustand „kalender.ansicht“) bleiben und stören nicht. Keine Daten betroffen. Nur auf dem Stand von 207. Läuft als Ganzes in der Transaktion des Aufrufs (psql -1).
DO $m$
BEGIN
  IF (SELECT md5(string_agg(p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')|' || pg_get_function_result(p.oid) || '|' || md5(p.prosrc), E'\n' ORDER BY p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')' COLLATE "C")) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname::text = 'public' COLLATE "C" AND p.proname::text COLLATE "C" = ANY (ARRAY['ally_rollen_person_ui_aktion', 'kalender_web_aktion', 'ally_person_speichern', 'kalender_ansicht', 'marketing_posten_ui_aktion'])) IS NOT DISTINCT FROM '85618fab0c075b83fbf3ec4c0a23e0f9' THEN RAISE EXCEPTION 'Rückbau 207: schon zurückgebaut, nichts geändert'; END IF;
  IF (SELECT md5(string_agg(p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')|' || pg_get_function_result(p.oid) || '|' || md5(p.prosrc), E'\n' ORDER BY p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')' COLLATE "C")) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname::text = 'public' COLLATE "C" AND p.proname::text COLLATE "C" = ANY (ARRAY['ally_rollen_person_ui_aktion', 'kalender_web_aktion', 'ally_person_speichern', 'kalender_ansicht', 'marketing_posten_ui_aktion'])) IS DISTINCT FROM '1a0f4afde12023790f7d2ce55bc61876' THEN RAISE EXCEPTION 'Rückbau 207: nicht im Stand von 207, nichts geändert'; END IF;
END $m$;
CREATE OR REPLACE FUNCTION public.ally_rollen_person_ui_aktion(p_sitzung text, p_csrf text, p_aktion text, p_daten jsonb, p_zustand jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
  s record; e jsonb; r jsonb; d jsonb := CASE WHEN jsonb_typeof(p_daten) = 'object' THEN p_daten ELSE '{}'::jsonb END;
  ro text[]; haupt text; weitere text[];
BEGIN
  -- Migration 206 (mehrere Rollen je Person, Stefan 04.11.2026): Aktionen person_rollen (Fenster der Person) und person_einladen (Person einladen mit einer oder
  -- mehreren Rollen) aus ALLY 20 „Aktion ausführen“ vor ally_ui_aktion (NULL = nicht zuständig). Sitzung, Schutzwert und Klappzustände wie ally_ui_aktion.
  -- person_einladen: wie person_vormerken über ally_person_vormerken mit der ersten Rolle, die weiteren stehen im Auftrag (daten.rollen) und kommen beim
  -- Anlegen dazu (ally_person_anlegen_abschliessen); danach weiter = chat (ALLY 18) wie bisher.
  -- Prüfung 1 (L3): die bisherige Aktion person_rolle (eine Rolle) setzt jetzt alle Rollen auf genau diese eine (keine weiteren Rollen bleiben stehen).
  IF coalesce(p_aktion, '') NOT IN ('person_rollen', 'person_einladen', 'person_rolle') THEN RETURN NULL; END IF;
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
  IF p_aktion IN ('person_rollen', 'person_rolle') THEN
    r := ally_person_rollen_setzen(p_sitzung, d->>'person', CASE WHEN p_aktion = 'person_rolle' THEN (CASE WHEN nullif(btrim(coalesce(d->>'rolle', '')), '') IS NULL THEN '[]'::jsonb ELSE jsonb_build_array(btrim(d->>'rolle')) END)
      WHEN jsonb_typeof(d->'rollen') = 'array' THEN d->'rollen' ELSE '[]'::jsonb END);
    PERFORM ally_web_meldung(p_sitzung, CASE WHEN coalesce((r->>'ok')::boolean, false) THEN r->>'meldung' ELSE coalesce(r->>'fehler', 'Die Rollen konnten nicht gespeichert werden.') END,
      CASE WHEN coalesce((r->>'ok')::boolean, false) THEN 'ok' ELSE 'fehler' END, NULL);
    RETURN jsonb_build_object('ok', coalesce((r->>'ok')::boolean, false), 'angemeldet', true, 'fertig', false, 'weiter', NULL, 'r', NULL);
  END IF;
  -- person_einladen: Rollen prüfen wie ally_person_rollen_setzen (nur aktive; Admin allein; keine Talent-Rolle), dann einladen
  IF jsonb_typeof(d->'rollen') IS DISTINCT FROM 'array' OR jsonb_array_length(d->'rollen') > 20
     OR EXISTS (SELECT 1 FROM jsonb_array_elements(d->'rollen') x WHERE jsonb_typeof(x) <> 'string') THEN
    r := jsonb_build_object('ok', false, 'fehler', 'Die Angaben konnten nicht verarbeitet werden. Bitte die Seite neu laden.');
  ELSE
    ro := ARRAY(SELECT DISTINCT lower(btrim(x)) FROM jsonb_array_elements_text(d->'rollen') x WHERE btrim(x) <> '');
    IF EXISTS (SELECT 1 FROM unnest(ro) x WHERE NOT EXISTS (SELECT 1 FROM ally_rollen q WHERE q.schluessel = x AND q.fuer_personen
                 AND (q.art = 'admin' OR (q.art = 'eigen' AND q.archiviert_am IS NULL)))) THEN
      r := jsonb_build_object('ok', false, 'fehler', 'Eine der Rollen gibt es nicht oder sie ist archiviert. Bitte die Seite neu laden.');
    ELSIF 'admin' = ANY (ro) AND cardinality(ro) > 1 THEN
      r := jsonb_build_object('ok', false, 'fehler', 'Admin darf alles und steht allein. Bitte nur Admin wählen oder Admin abwählen.');
    ELSE
      ro := ARRAY(SELECT q.schluessel FROM ally_rollen q WHERE q.schluessel = ANY (ro) ORDER BY q.sortierung, lower(q.name), q.schluessel COLLATE "C");
      haupt := ro[1]; weitere := coalesce(ro[2:], '{}');
      r := ally_person_vormerken(p_sitzung, d->>'name', d->>'email', coalesce(haupt, ''),
             CASE WHEN jsonb_typeof(d->'funktionen') = 'array' THEN d->'funktionen' ELSE '[]'::jsonb END,
             CASE WHEN jsonb_typeof(d->'talents') = 'array' THEN d->'talents' ELSE '[]'::jsonb END,
             CASE WHEN jsonb_typeof(d->'postfaecher') = 'array' THEN d->'postfaecher' ELSE '[]'::jsonb END);
      IF coalesce((r->>'ok')::boolean, false) AND cardinality(weitere) > 0 THEN
        UPDATE ally_chat_auftraege SET daten = daten || jsonb_build_object('rollen', to_jsonb(weitere))
        WHERE id = (r->>'auftrag_id')::bigint AND art = 'anlegen' AND status = 'offen';
      END IF;
    END IF;
  END IF;
  IF coalesce((r->>'ok')::boolean, false) THEN
    PERFORM ally_web_meldung(p_sitzung, r->>'meldung', 'ok', NULL);
    RETURN jsonb_build_object('ok', true, 'angemeldet', true, 'fertig', false, 'weiter', 'chat', 'r', r);
  END IF;
  PERFORM ally_web_meldung(p_sitzung, coalesce(r->>'fehler', 'Die Person konnte nicht eingeladen werden.'), 'fehler', NULL);
  RETURN jsonb_build_object('ok', false, 'angemeldet', true, 'fertig', false, 'weiter', NULL, 'r', NULL);
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
DROP FUNCTION public.marketing_posten_ui_aktion(p_sitzung text, p_csrf text, p_aktion text, p_daten jsonb, p_zustand jsonb);
DROP FUNCTION public.kalender_ansicht(p_person text, p_daten jsonb);
DROP FUNCTION public.ally_person_speichern(p_sitzung text, p_person text, p_daten jsonb);
DO $m$
BEGIN
  IF (SELECT md5(string_agg(p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')|' || pg_get_function_result(p.oid) || '|' || md5(p.prosrc), E'\n' ORDER BY p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')' COLLATE "C")) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname::text = 'public' COLLATE "C" AND p.proname::text COLLATE "C" = ANY (ARRAY['ally_rollen_person_ui_aktion', 'kalender_web_aktion', 'ally_person_speichern', 'kalender_ansicht', 'marketing_posten_ui_aktion'])) IS DISTINCT FROM '85618fab0c075b83fbf3ec4c0a23e0f9' THEN RAISE EXCEPTION 'Rückbau 207: Funktionen nicht wie vorher'; END IF;
END $m$;
