-- Migration 206 (mehrere Rollen je Person, Stefan 04.11.2026): Eine Person kann mehrere Rollen haben, ihre Rechte sind die Summe der Rollen.
-- a) ally_person_rollen (weitere Rollen; die erste bleibt in ally_personen.rolle). b) ally_recht_roh und ally_person_rechte_basis zählen die weiteren Rollen mit.
-- c) Vorlagen des Basispakets Anwender und Mitarbeiter (Admin gibt es genau einmal). d) person_rollen und person_einladen über ally_rollen_person_ui_aktion
--    (ALLY 20 „Aktion ausführen“ vor ally_ui_aktion, das unverändert bleibt: sein Text enthält ausgeschlossene Themen, Regel fassung_bauen).
-- e) Anzeige (ally_rollen_ui, ally_rolle_ui_aktion, ally_ui_rahmen); ally_person_rolle_anwenden entfernt weitere Rollen bei Admin; die Einladung übernimmt sie.
-- Datenänderung: zwei neue Zeilen in ally_rollen (anwender, mitarbeiter) und ihre Rechte in ally_rollen_rechte; vorhandene Personen und Rollen unverändert.
-- Wächter vorher: Funktionen wie nach 205, Tabelle ally_person_rollen und die Rollen-Schlüssel anwender/mitarbeiter gibt es nicht, keine Sicherung aus Rückbau 206.
-- Läuft als Ganzes in der Transaktion des Aufrufs (psql -1). Rückbau: rueckbau206.sql.
DO $m$
BEGIN
  IF (SELECT md5(string_agg(p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')|' || pg_get_function_result(p.oid) || '|' || md5(p.prosrc), E'\n' ORDER BY p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')' COLLATE "C")) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname::text = 'public' COLLATE "C" AND p.proname::text COLLATE "C" = ANY (ARRAY['ally_recht_roh', 'ally_person_rechte_basis', 'ally_rollen_ui', 'ally_rolle_ui_aktion', 'ally_ui_rahmen', 'ally_person_anlegen_abschliessen', 'ally_person_rolle_anwenden', 'ally_person_rolle_abgleichen', 'ally_rolle_papierkorb', 'ally_testdaten_entfernen', 'ally_sicherung_kunde_inhalt', 'ally_person_rollen_liste', 'ally_person_rollen_setzen', 'ally_rollen_person_ui_aktion'])) IS NOT DISTINCT FROM 'd345929df378e0dd6b6cc5ea23fe8399' AND (SELECT md5(string_agg(z, E'\n' ORDER BY z COLLATE "C")) FROM (WITH t AS (SELECT c.oid, c.relname::text AS tab FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname::text = 'public' COLLATE "C" AND c.relkind::text = ANY (ARRAY['r', 'p']) AND c.relname::text = ANY (ARRAY['ally_person_rollen'])) SELECT 'S|' || t.tab || '|' || a.attname::text || '|' || format_type(a.atttypid, a.atttypmod) || '|' || CASE WHEN a.attnotnull THEN 'NN' ELSE '-' END || '|' || coalesce(pg_get_expr(d.adbin, d.adrelid), '') || '|' || a.attidentity::text || a.attgenerated::text AS z FROM t JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum > 0 AND NOT a.attisdropped LEFT JOIN pg_attrdef d ON d.adrelid = t.oid AND d.adnum = a.attnum UNION ALL SELECT 'C|' || t.tab || '|' || co.conname::text || '|' || co.contype::text || '|' || pg_get_constraintdef(co.oid) FROM t JOIN pg_constraint co ON co.conrelid = t.oid UNION ALL SELECT 'I|' || t.tab || '|' || ic.relname::text || '|' || pg_get_indexdef(i.indexrelid) FROM t JOIN pg_index i ON i.indrelid = t.oid JOIN pg_class ic ON ic.oid = i.indexrelid UNION ALL SELECT 'T|' || t.tab || '|' || tg.tgname::text || '|' || pg_get_triggerdef(tg.oid) || '|' || tg.tgenabled::text FROM t JOIN pg_trigger tg ON tg.tgrelid = t.oid AND NOT tg.tgisinternal) x) IS NOT DISTINCT FROM '5790c6d4d8a37a9386ce025fd0ec1096'
    THEN RAISE EXCEPTION 'Migration 206: schon eingespielt, nichts geändert'; END IF;
  IF (SELECT count(*) FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname::text = 'public' COLLATE "C" AND c.relname::text COLLATE "C" = ANY (ARRAY['ally_person_rollen_rb206', 'ally_rollen_vorlagen_rb206', 'ally_personen_rolle_rb206', 'ally_speicherort_rechte_rb206'])) <> 0 THEN RAISE EXCEPTION 'Migration 206: Sicherungstabellen aus Rückbau 206 vorhanden, erst klären, nichts geändert'; END IF;
  IF (SELECT md5(string_agg(z, E'\n' ORDER BY z COLLATE "C")) FROM (WITH t AS (SELECT c.oid, c.relname::text AS tab FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname::text = 'public' COLLATE "C" AND c.relkind::text = ANY (ARRAY['r', 'p']) AND c.relname::text = ANY (ARRAY['ally_person_rollen'])) SELECT 'S|' || t.tab || '|' || a.attname::text || '|' || format_type(a.atttypid, a.atttypmod) || '|' || CASE WHEN a.attnotnull THEN 'NN' ELSE '-' END || '|' || coalesce(pg_get_expr(d.adbin, d.adrelid), '') || '|' || a.attidentity::text || a.attgenerated::text AS z FROM t JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum > 0 AND NOT a.attisdropped LEFT JOIN pg_attrdef d ON d.adrelid = t.oid AND d.adnum = a.attnum UNION ALL SELECT 'C|' || t.tab || '|' || co.conname::text || '|' || co.contype::text || '|' || pg_get_constraintdef(co.oid) FROM t JOIN pg_constraint co ON co.conrelid = t.oid UNION ALL SELECT 'I|' || t.tab || '|' || ic.relname::text || '|' || pg_get_indexdef(i.indexrelid) FROM t JOIN pg_index i ON i.indrelid = t.oid JOIN pg_class ic ON ic.oid = i.indexrelid UNION ALL SELECT 'T|' || t.tab || '|' || tg.tgname::text || '|' || pg_get_triggerdef(tg.oid) || '|' || tg.tgenabled::text FROM t JOIN pg_trigger tg ON tg.tgrelid = t.oid AND NOT tg.tgisinternal) x) IS NOT NULL THEN RAISE EXCEPTION 'Migration 206: Tabelle ally_person_rollen gibt es schon, nichts geändert'; END IF;
  IF EXISTS (SELECT 1 FROM public.ally_rollen r WHERE r.schluessel = ANY (ARRAY['anwender', 'mitarbeiter']) OR lower(btrim(r.name)) = ANY (ARRAY['anwender', 'mitarbeiter']))
    THEN RAISE EXCEPTION 'Migration 206: eine Rolle Anwender oder Mitarbeiter (Schlüssel oder Name) gibt es schon, nichts geändert'; END IF;
  IF (SELECT md5(string_agg(p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')|' || pg_get_function_result(p.oid) || '|' || md5(p.prosrc), E'\n' ORDER BY p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')' COLLATE "C")) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname::text = 'public' COLLATE "C" AND p.proname::text COLLATE "C" = ANY (ARRAY['ally_recht_roh', 'ally_person_rechte_basis', 'ally_rollen_ui', 'ally_rolle_ui_aktion', 'ally_ui_rahmen', 'ally_person_anlegen_abschliessen', 'ally_person_rolle_anwenden', 'ally_person_rolle_abgleichen', 'ally_rolle_papierkorb', 'ally_testdaten_entfernen', 'ally_sicherung_kunde_inhalt', 'ally_person_rollen_liste', 'ally_person_rollen_setzen', 'ally_rollen_person_ui_aktion'])) IS DISTINCT FROM 'aa9e8cf4d994153cc661bb2ea47a57f7' THEN RAISE EXCEPTION 'Migration 206: Funktionen der Rollen und Rechte nicht im erwarteten Stand, nichts geändert'; END IF;
END $m$;
CREATE TABLE public.ally_person_rollen (
  person text NOT NULL REFERENCES public.ally_personen (matrix_user_id) ON UPDATE CASCADE ON DELETE CASCADE,
  rolle text NOT NULL REFERENCES public.ally_rollen (schluessel) ON UPDATE CASCADE,
  erstellt_am timestamp with time zone NOT NULL DEFAULT now(),
  erstellt_von text,
  PRIMARY KEY (person, rolle)
);
CREATE INDEX ally_person_rollen_rolle_idx ON public.ally_person_rollen (rolle);
COMMENT ON TABLE public.ally_person_rollen IS 'Migration 206 (mehrere Rollen je Person, Stefan 04.11.2026): weitere Rollen einer Person (die erste steht in ally_personen.rolle). Rechte = Summe aller Rollen (ally_recht_roh). Nie neben Admin oder einer Rolle der Art talent; setzen nur über ally_person_rollen_setzen bzw. die Einladung.';
INSERT INTO public.ally_rollen (schluessel, name, beschreibung, sortierung, fuer_personen, art, paket, vorlage, standard)
VALUES ('anwender', 'Anwender', 'Nutzt Kalender, Assistent, Mail-Assistent und Morgen-Briefing.', 20, true, 'eigen', NULL, 'anwender', '{"kalender": null, "fragen": null, "mail_assistent": null, "morgen_briefing": null}'::jsonb),
       ('mitarbeiter', 'Mitarbeiter', 'Wie Anwender, dazu eigene Postfächer anlegen, Ordner teilen, gemeinsame Postfächer und Absender-Regeln verwalten.', 30, true, 'eigen', NULL, 'mitarbeiter', '{"kalender": null, "fragen": null, "mail_assistent": null, "morgen_briefing": null, "postfaecher_eigene": null, "speicherort_eigen": null, "postfaecher": null, "absender_regeln": null}'::jsonb);
DO $m$ BEGIN PERFORM public.ally_rolle_auf_standard(x, NULL) FROM unnest(ARRAY['anwender', 'mitarbeiter']) x; END $m$;
CREATE OR REPLACE FUNCTION public.ally_person_rollen_liste(p_user text)
 RETURNS text[]
 LANGUAGE sql
 STABLE
AS $function$
  -- Migration 206 (mehrere Rollen je Person, Stefan 04.11.2026): alle Rollen einer Person (Rolle in ally_personen.rolle und weitere in ally_person_rollen),
  -- aktive vor archivierten, dann nach der Sortierung der Rollen und dem Namen (wie ally_person_rollen_setzen); leer = ohne Rolle.
  SELECT coalesce(array_agg(r.schluessel ORDER BY r.archiviert_am IS NOT NULL, r.sortierung, lower(r.name), r.schluessel COLLATE "C"), '{}')
  FROM ally_rollen r
  WHERE r.schluessel = (SELECT p.rolle FROM ally_personen p WHERE p.matrix_user_id = p_user)
     OR EXISTS (SELECT 1 FROM ally_person_rollen x WHERE x.person = p_user AND x.rolle = r.schluessel)
$function$;
CREATE OR REPLACE FUNCTION public.ally_person_rollen_setzen(p_sitzung text, p_person text, p_rollen jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
  s record; u text; ziel text := btrim(coalesce(p_person, '')); nm text; alt text[]; ro text[]; haupt text; weitere text[]; bisher text;
BEGIN
  -- Migration 206 (mehrere Rollen je Person, Stefan 04.11.2026, „2. b“): Rollen einer Person setzen (Fenster der Person). Nur Admins.
  -- Die Rechte sind die Summe der Rollen (ally_recht_roh). Admin steht allein („Admin ist Admin“), die Rolle Talent nur im Talent-Profil und nie mit anderen.
  -- Die erste Rolle (Sortierung, Name) steht in ally_personen.rolle (über ally_person_rolle_anwenden, wie bisher), die weiteren in ally_person_rollen.
  -- Erlaubt sind aktive Rollen für Personen; eine archivierte Rolle, die die Person schon hat, darf bleiben. Leere Liste = ohne Rolle.
  SELECT * INTO s FROM ally_web_sitzung_pruefen(p_sitzung);
  IF NOT FOUND OR s.muss_pw_setzen THEN
    RETURN jsonb_build_object('ok', false, 'angemeldet', FOUND, 'fehler', 'Bitte neu anmelden.');
  END IF;
  u := s.matrix_user_id;
  IF NOT ally_hat_recht(u, 'admin') THEN
    RETURN jsonb_build_object('ok', false, 'fehler', 'Rollen vergibt eine Person mit der Rolle Admin.');
  END IF;
  IF jsonb_typeof(p_rollen) IS DISTINCT FROM 'array' OR jsonb_array_length(p_rollen) > 20
     OR EXISTS (SELECT 1 FROM jsonb_array_elements(p_rollen) x WHERE jsonb_typeof(x) <> 'string') THEN
    RETURN jsonb_build_object('ok', false, 'fehler', 'Die Angaben konnten nicht verarbeitet werden. Bitte die Seite neu laden.');
  END IF;
  ro := ARRAY(SELECT DISTINCT lower(btrim(x)) FROM jsonb_array_elements_text(p_rollen) x WHERE btrim(x) <> '');
  SELECT p.name, p.rolle INTO nm, bisher FROM ally_personen p WHERE p.matrix_user_id = ziel AND p.aktiv;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'fehler', 'Unbekannte oder deaktivierte Person.');
  END IF;
  alt := ally_person_rollen_liste(ziel);
  IF ally_person_ist_talent(ziel) OR ally_rolle_ist_talent(bisher) THEN
    RETURN jsonb_build_object('ok', false, 'fehler', 'Den Zugang und die Rolle eines Talents änderst du im Talent-Profil.');
  ELSIF EXISTS (SELECT 1 FROM unnest(ro) x WHERE NOT EXISTS (SELECT 1 FROM ally_rollen r WHERE r.schluessel = x AND r.fuer_personen
                  AND (r.art = 'admin' OR (r.art = 'eigen' AND (r.archiviert_am IS NULL OR x = ANY (alt)))))) THEN
    RETURN jsonb_build_object('ok', false, 'fehler', 'Eine der Rollen gibt es nicht oder sie ist archiviert. Bitte die Seite neu laden.');
  ELSIF 'admin' = ANY (ro) AND cardinality(ro) > 1 THEN
    RETURN jsonb_build_object('ok', false, 'fehler', 'Admin darf alles und steht allein. Bitte nur Admin wählen oder Admin abwählen.');
  ELSIF ally_person_superadmin(ziel) AND NOT ally_hat_recht(u, 'superadmin') THEN
    RETURN jsonb_build_object('ok', false, 'fehler', 'Diese Person ist Superadmin. Änderungen an ihr nehmen nur Superadmins vor.');
  ELSIF ally_person_superadmin(ziel) AND ro IS DISTINCT FROM ARRAY['admin'] THEN
    RETURN jsonb_build_object('ok', false, 'fehler', 'Superadmins haben immer die Rolle Admin.');
  ELSIF ziel = u AND NOT ('admin' = ANY (ro)) THEN
    RETURN jsonb_build_object('ok', false, 'fehler', 'Du kannst dir die Rolle Admin nicht selbst entziehen.');
  END IF;
  -- Reihenfolge: aktive Rollen vor archivierten, dann Sortierung und Name; die erste ist die Rolle in ally_personen
  ro := ARRAY(SELECT r.schluessel FROM ally_rollen r WHERE r.schluessel = ANY (ro)
              ORDER BY r.archiviert_am IS NOT NULL, r.sortierung, lower(r.name), r.schluessel COLLATE "C");
  haupt := ro[1];
  weitere := coalesce(ro[2:], '{}');
  IF haupt IS DISTINCT FROM bisher AND EXISTS (SELECT 1 FROM ally_rollen r WHERE r.schluessel = haupt AND r.archiviert_am IS NOT NULL) THEN
    -- eine archivierte Rolle, die die Person schon hatte, rückt nach vorn (ally_person_rolle_anwenden nimmt nur aktive)
    UPDATE ally_personen SET rolle = haupt, geaendert_am = now() WHERE matrix_user_id = ziel;
    DELETE FROM ally_nutzer_rechte WHERE matrix_user_id = ziel AND recht = 'admin';
  ELSIF haupt IS DISTINCT FROM bisher THEN
    PERFORM ally_person_rolle_anwenden(ziel, haupt, '{}');
  END IF;
  DELETE FROM ally_person_rollen x WHERE x.person = ziel AND NOT (x.rolle = ANY (weitere));
  INSERT INTO ally_person_rollen (person, rolle, erstellt_von) SELECT ziel, y, u FROM unnest(weitere) y ON CONFLICT DO NOTHING;
  RETURN jsonb_build_object('ok', true, 'meldung',
    CASE WHEN cardinality(ro) = 0 THEN 'Rolle von ' || nm || ': ohne Rolle.'
         WHEN cardinality(ro) = 1 THEN 'Rolle von ' || nm || ': ' || (SELECT r.name FROM ally_rollen r WHERE r.schluessel = haupt) || '.'
         ELSE 'Rollen von ' || nm || ': ' || (SELECT string_agg(r.name, ', ' ORDER BY array_position(ro, r.schluessel)) FROM ally_rollen r WHERE r.schluessel = ANY (ro)) || '.' END
    || CASE WHEN haupt IS DISTINCT FROM 'admin' AND EXISTS (SELECT 1 FROM ally_person_rechte r WHERE r.person = ziel) THEN ' Eigene Rechte gelten weiter.' ELSE '' END);
END $function$;
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
CREATE OR REPLACE FUNCTION public.ally_recht_roh(p_user text, p_recht text)
 RETURNS text
 LANGUAGE sql
 STABLE
AS $function$
  -- Reichweite eines Rechts aus der Rolle der Person (nicht archiviert) und aus einzeln vergebenen Rechten der alten Oberfläche (Migration 64).
  -- Ohne Admin/Superadmin, ohne Paketprüfung und ohne die Regeln der Talent-Rechte (das macht ally_recht_reichweite).
  -- Einzeln vergeben: „Talents verwalten“ wirkt wie bisher für alle Talents (und sehen alle), „Talents ansehen“ nur für zugeordnete; sonst ohne Reichweite.
  -- Migration 155 (G4): eigene Rechte je Account aus ally_person_rechte – plus zählt wie ein Recht der Rolle (ohne Reichweite = alle), minus nimmt das Recht weg
  -- (auch wenn die Rolle es hat). Reichweite 'selbst' (nur eigene Daten eines Talents) gilt nur, wenn keine Quelle 'zugeordnet' oder 'alle' liefert.
  -- Rollen der Art 'talent' zählen wie eigene Rollen.
  -- Migration 206 (mehrere Rollen je Person, Stefan 04.11.2026): dazu die weiteren Rollen der Person (ally_person_rollen); Rechte = Summe aller Rollen.
  -- Migration 167 (Bauplan B6): einzeln vergebene Rechte der alten Oberfläche (ally_nutzer_rechte) zählen nicht mehr (F13); sie stehen als eigene Rechte (plus)
  -- in ally_person_rechte (ally_einzelrecht_uebernehmen). In ally_nutzer_rechte bleiben nur admin und superadmin.
  SELECT CASE WHEN EXISTS (SELECT 1 FROM ally_person_rechte m WHERE m.person = p_user AND m.recht = p_recht AND m.wirkung = 'minus') THEN NULL
              WHEN max(ally_recht_stufe(x.r)) = 2 THEN 'alle'
              WHEN max(ally_recht_stufe(x.r)) = 1 THEN 'zugeordnet'
              WHEN bool_or(x.r = 'selbst') THEN 'selbst' END
  FROM (
    SELECT coalesce(rr.reichweite, 'alle') AS r
    FROM ally_personen p
    JOIN ally_rollen ro ON ro.schluessel = p.rolle AND ro.art IN ('eigen', 'talent') AND ro.archiviert_am IS NULL
    JOIN ally_rollen_rechte rr ON rr.rolle = ro.schluessel AND rr.recht = p_recht
    WHERE p.matrix_user_id = p_user AND p.aktiv
    UNION ALL
    SELECT coalesce(rr.reichweite, 'alle')
    FROM ally_person_rollen x JOIN ally_personen p ON p.matrix_user_id = x.person AND p.aktiv
    JOIN ally_rollen ro ON ro.schluessel = x.rolle AND ro.art = 'eigen' AND ro.archiviert_am IS NULL
    JOIN ally_rollen_rechte rr ON rr.rolle = ro.schluessel AND rr.recht = p_recht
    WHERE x.person = p_user
    UNION ALL
    SELECT coalesce(pr.reichweite, 'alle')
    FROM ally_person_rechte pr JOIN ally_personen p ON p.matrix_user_id = pr.person AND p.aktiv
    WHERE pr.person = p_user AND pr.recht = p_recht AND pr.wirkung = 'plus'
  ) x
$function$;
CREATE OR REPLACE FUNCTION public.ally_person_rechte_basis(p_user text)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
AS $function$
  -- Migration 166 (Bauplan B5d, G4): {recht: 'alle' | 'zugeordnet' | 'selbst'}; ally_recht_roh = diese Basis, dazu plus (Maximum), minus nimmt das Recht ganz.
  -- Migration 167 (Bauplan B6): ohne einzeln vergebene Rechte der alten Oberfläche (F13); die Basis ist die Rolle.
  -- Migration 206 (mehrere Rollen je Person, Stefan 04.11.2026): die Basis sind alle Rollen der Person (auch ally_person_rollen).
  SELECT coalesce(jsonb_object_agg(x.recht, x.r), '{}'::jsonb) FROM (
    SELECT q.recht, CASE WHEN max(ally_recht_stufe(q.r)) = 2 THEN 'alle' WHEN max(ally_recht_stufe(q.r)) = 1 THEN 'zugeordnet' WHEN bool_or(q.r = 'selbst') THEN 'selbst' END AS r
    FROM (
      SELECT rr.recht, coalesce(rr.reichweite, 'alle') AS r
      FROM ally_personen p
      JOIN ally_rollen ro ON ro.schluessel = p.rolle AND ro.art IN ('eigen', 'talent') AND ro.archiviert_am IS NULL
      JOIN ally_rollen_rechte rr ON rr.rolle = ro.schluessel
      WHERE p.matrix_user_id = p_user AND p.aktiv
      UNION ALL
      SELECT rr.recht, coalesce(rr.reichweite, 'alle')
      FROM ally_person_rollen x JOIN ally_personen p ON p.matrix_user_id = x.person AND p.aktiv
      JOIN ally_rollen ro ON ro.schluessel = x.rolle AND ro.art = 'eigen' AND ro.archiviert_am IS NULL
      JOIN ally_rollen_rechte rr ON rr.rolle = ro.schluessel
      WHERE x.person = p_user
    ) q GROUP BY q.recht) x
  WHERE x.r IS NOT NULL
$function$;
CREATE OR REPLACE FUNCTION public.ally_rollen_ui(p_token text)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
  s record;
BEGIN
  -- Einstellungen › Team und Rollen (ALLY 23, Migration 64): Rollen (Admin fest, die übrigen legt der Admin an), Rechte-Katalog der gebuchten Pakete,
  -- wirksame Rechte je Person. Nur für Admins.
  -- Migration 156 (G2): auch die Rolle Talent (Art talent); je Rolle Paket, Vorlage, ob es einen Standard gibt und ob die Rechte ihm entsprechen;
  -- im Katalog je Recht nur_selbst (Recht gilt nur für die eigenen Daten eines Talents).
  -- Migration 206 (mehrere Rollen je Person, Stefan 04.11.2026): Personen je Rolle auch mit weiteren Rollen; je Person alle Rollen (rollen, erste zuerst).
  SELECT * INTO s FROM ally_ui_sitzung(p_token);
  IF NOT FOUND OR s.muss_pw_setzen THEN RETURN jsonb_build_object('ok', false, 'angemeldet', FOUND); END IF;
  IF NOT ally_hat_recht(s.person, 'admin') THEN RETURN jsonb_build_object('ok', true, 'darf', false); END IF;
  RETURN jsonb_build_object('ok', true, 'darf', true,
    'rollen', (SELECT coalesce(jsonb_agg(jsonb_build_object('schluessel', ro.schluessel, 'name', ro.name, 'beschreibung', ro.beschreibung, 'art', ro.art,
        'paket', ro.paket, 'vorlage', ro.vorlage, 'standard', ro.standard IS NOT NULL,
        'wie_standard', CASE WHEN ro.standard IS NOT NULL THEN coalesce((SELECT jsonb_object_agg(rr.recht, rr.reichweite) FROM ally_rollen_rechte rr WHERE rr.rolle = ro.schluessel), '{}'::jsonb) = ro.standard END,
        'archiviert', ro.archiviert_am IS NOT NULL, 'archiviert_am', CASE WHEN ro.archiviert_am IS NOT NULL THEN talents_datum(ro.archiviert_am) END,
        'kurz', ally_rolle_text(ro.schluessel),
        'personen', (SELECT coalesce(jsonb_agg(jsonb_build_object('id', p.matrix_user_id, 'name', p.name, 'aktiv', p.aktiv) ORDER BY p.aktiv DESC, lower(p.name)), '[]'::jsonb)
                     FROM ally_personen p WHERE p.rolle = ro.schluessel OR EXISTS (SELECT 1 FROM ally_person_rollen x WHERE x.person = p.matrix_user_id AND x.rolle = ro.schluessel)),
        'rechte', (SELECT coalesce(jsonb_object_agg(rr.recht, coalesce(rr.reichweite, 'ja')), '{}'::jsonb) FROM ally_rollen_rechte rr WHERE rr.rolle = ro.schluessel))
      ORDER BY ro.art <> 'admin', ro.archiviert_am IS NOT NULL, lower(ro.name)), '[]'::jsonb)
      FROM ally_rollen ro WHERE ro.art IN ('admin', 'eigen', 'talent')),
    'katalog', (SELECT coalesce(jsonb_agg(jsonb_build_object('gruppe', g.gruppe, 'rechte', g.rechte) ORDER BY g.o), '[]'::jsonb) FROM (
        SELECT z.katalog_gruppe AS gruppe, min(z.katalog_sortierung) AS o,
          jsonb_agg(jsonb_build_object('schluessel', z.schluessel,
            -- Migration 90: Gruppe „Gemeinsame Postfächer“ = ein Häkchen je belegtem gemeinsamem Platz, beschriftet mit der Adresse
            -- Migration 167 (Bauplan B6): „Ordner freigeben: <Bezeichnung des Speicherorts>“ (T3)
            'name', coalesce(ally_postfach_platz_adresse(ally_postfach_platz_recht(z.schluessel)), CASE WHEN z.schluessel = 'speicherort_eigen' THEN ally_recht_name(z.schluessel) END,
              coalesce(z.katalog_name, z.name)),
            'text', CASE WHEN ally_postfach_platz_recht(z.schluessel) IS NOT NULL THEN coalesce((SELECT nullif(btrim(p.name), '') FROM ally_postfaecher p
              WHERE p.adresse = ally_postfach_platz_adresse(ally_postfach_platz_recht(z.schluessel)) AND lower(btrim(p.name)) <> p.adresse), '') ELSE coalesce(z.katalog_text, '') END,
            'reichweite', z.reichweite AND z.schluessel <> 'verkaufsberichte', 'nur_selbst', z.nur_selbst, 'reichweite_text', CASE WHEN z.reichweite THEN ally_reichweite_text(z.schluessel) END)
            ORDER BY z.katalog_sortierung, z.schluessel) AS rechte
        FROM ally_rechte z WHERE z.katalog_gruppe IS NOT NULL AND z.schluessel NOT IN ('admin', 'superadmin') AND (z.modul IS NULL OR plattform_modul_an(z.modul))
          AND (ally_postfach_platz_recht(z.schluessel) IS NULL OR ally_postfach_platz_adresse(ally_postfach_platz_recht(z.schluessel)) IS NOT NULL)
          AND (z.schluessel <> 'speicherort_eigen' OR coalesce((ally_speicherort_eigen()->>'eingerichtet')::boolean, false))  -- Migration 167 (Bauplan B6): T3, nur mit eingebundenem eigenem Speicherort
        GROUP BY z.katalog_gruppe) g),
    'personen', (SELECT coalesce(jsonb_agg(jsonb_build_object('id', p.matrix_user_id,
        'rollen', (SELECT coalesce(jsonb_agg(jsonb_build_object('schluessel', r2.schluessel, 'name', r2.name, 'art', r2.art, 'archiviert', r2.archiviert_am IS NOT NULL)
                     ORDER BY array_position(ally_person_rollen_liste(p.matrix_user_id), r2.schluessel)), '[]'::jsonb)
                   FROM ally_rollen r2 WHERE r2.schluessel = ANY (ally_person_rollen_liste(p.matrix_user_id))),
        'rolle_archiviert', EXISTS (SELECT 1 FROM ally_rollen ro WHERE ro.schluessel = p.rolle AND ro.archiviert_am IS NOT NULL),
        'wirksam', CASE WHEN p.aktiv AND ally_hat_recht(p.matrix_user_id, 'admin') THEN '[]'::jsonb ELSE
          (SELECT coalesce(jsonb_agg(ally_recht_name(z.schluessel) || CASE WHEN z.reichweite THEN ' (' || CASE ally_recht_reichweite(p.matrix_user_id, z.schluessel) WHEN 'alle' THEN 'alle' ELSE ally_reichweite_text(z.schluessel) END || ')' ELSE '' END
                    ORDER BY z.katalog_sortierung, z.schluessel), '[]'::jsonb)
           FROM ally_rechte z WHERE z.katalog_gruppe IS NOT NULL AND z.schluessel NOT IN ('admin', 'superadmin') AND ally_recht_reichweite(p.matrix_user_id, z.schluessel) IS NOT NULL) END,
        'speicherort', ally_speicherort_darf(p.matrix_user_id, 'eigen'),
        -- Migration 166 (Bauplan B5d): je Team-Person die Rechte wie gerechnet (ally_recht_roh) und ohne eigene Rechte (Basis) für „Eigene Rechte“ im Person-Fenster;
        -- nicht für Talents (Talent-Profil) und nicht für Admins (haben alle Rechte), wie ally_person_eigene_rechte_setzen
        -- Migration 167 (Bauplan B6): Prüfbericht M166 N6: nicht bei einer Rolle der Art talent
        'rechte', CASE WHEN NOT ally_person_ist_talent(p.matrix_user_id) AND NOT ally_rolle_ist_talent(p.rolle) AND coalesce(p.rolle, '') <> 'admin'
            AND NOT EXISTS (SELECT 1 FROM ally_nutzer_rechte n WHERE n.matrix_user_id = p.matrix_user_id AND n.recht IN ('admin', 'superadmin'))
          THEN (SELECT coalesce(jsonb_object_agg(k.k, k.r) FILTER (WHERE k.r IS NOT NULL), '{}'::jsonb)
          FROM (SELECT x.k, ally_recht_roh(p.matrix_user_id, x.k) AS r FROM ally_person_rechte_katalog() AS x(k)) k) END,
        'basis', CASE WHEN NOT ally_person_ist_talent(p.matrix_user_id) AND NOT ally_rolle_ist_talent(p.rolle) AND coalesce(p.rolle, '') <> 'admin'
            AND NOT EXISTS (SELECT 1 FROM ally_nutzer_rechte n WHERE n.matrix_user_id = p.matrix_user_id AND n.recht IN ('admin', 'superadmin'))
          THEN ally_person_rechte_basis(p.matrix_user_id) END) ORDER BY p.id), '[]'::jsonb)
      FROM ally_personen p));
END $function$;
CREATE OR REPLACE FUNCTION public.ally_rolle_ui_aktion(p_token text, p_aktion text, p_daten jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
  s record;
  d jsonb := CASE WHEN jsonb_typeof(p_daten) = 'object' THEN p_daten ELSE '{}'::jsonb END;
  ro ally_rollen%ROWTYPE;
  k text := lower(btrim(coalesce(d->>'schluessel', '')));
  nm text := btrim(regexp_replace(coalesce(d->>'name', ''), '\s+', ' ', 'g'));
  be text := btrim(coalesce(d->>'beschreibung', ''));
  pr jsonb; m text := NULL; fehler text := NULL; n integer;
  art_neu text := CASE WHEN d->>'art' = 'talent' THEN 'talent' ELSE 'eigen' END;
BEGIN
  -- Rollen verwalten (ALLY 23, Migration 64, ro_*): ro_neu (name, beschreibung, rechte), ro_speichern (schluessel, name, beschreibung, rechte),
  -- ro_archivieren (schluessel; nur ohne aktive Personen), ro_aktivieren (schluessel). Nur Admins. Rollen werden nie gelöscht. Admin ist fest.
  -- Rechte gebuchter Pakete ersetzt das Formular; Rechte nicht gebuchter Pakete bleiben in der Rolle gespeichert. Meldung setzt die Funktion selbst.
  -- Migration 156 (G2): Vorlagen der Pakete (vorlage gesetzt, auch die Rolle Talent) lassen sich ändern (ro_speichern) und auf den Standard zurücksetzen
  -- (ro_standard), aber nicht in den Papierkorb legen. Umbenennen lassen sie sich alle gleich, die Rolle Talent auch wieder zurück auf „Talent“ (Prüfbericht M156 M2);
  -- neue oder andere Rollen bekommen den Namen Talent nie.
  SELECT * INTO s FROM ally_ui_sitzung(p_token);
  IF NOT FOUND OR s.muss_pw_setzen THEN RETURN jsonb_build_object('ok', false, 'angemeldet', false); END IF;
  IF NOT ally_hat_recht(s.person, 'admin') THEN
    fehler := 'Rollen verwaltet eine Person mit der Rolle Admin.';
  ELSIF p_aktion NOT IN ('ro_neu', 'ro_speichern', 'ro_archivieren', 'ro_aktivieren', 'ro_standard') THEN
    fehler := 'Diese Aktion gibt es nicht.';
  -- Migration 165 (Bauplan B5c): ro_neu mit art talent legt eine Rolle für Talents an (nur mit dem Paket Talents).
  ELSIF p_aktion = 'ro_neu' AND art_neu = 'talent' AND NOT plattform_modul_an('talents') THEN
    fehler := 'Rollen für Talents gibt es nur mit dem Paket Talents.';
  ELSE
    IF p_aktion <> 'ro_neu' THEN
      SELECT * INTO ro FROM ally_rollen x WHERE x.schluessel = k FOR UPDATE;
      IF NOT FOUND OR ro.art NOT IN ('eigen', 'talent') THEN
        fehler := CASE WHEN FOUND AND ro.art = 'admin' THEN 'Die Rolle Admin ist fest und lässt sich nicht ändern.' ELSE 'Diese Rolle gibt es nicht. Bitte die Seite neu laden.' END;
      -- Migration 165 (Bauplan B5c): nur Vorlagen (auch die Rolle Talent) bleiben immer; weitere Rollen für Talents lassen sich in den Papierkorb legen.
      ELSIF ro.vorlage IS NOT NULL AND p_aktion IN ('ro_archivieren', 'ro_aktivieren') THEN
        fehler := 'Vorlagen bleiben immer erhalten. Du kannst sie ändern und auf den Standard zurücksetzen.';
      ELSIF p_aktion = 'ro_standard' AND ro.standard IS NULL THEN
        fehler := 'Für diese Rolle gibt es keinen Standard.';
      -- Migration 163 (Bauplan B5b): Ally-Chat ist eine Erlaubnis (Stefan G12); der Standard darf sie Talents mit eingeschaltetem Chat nicht wegnehmen.
      ELSIF p_aktion = 'ro_standard' AND ro.art = 'talent' AND NOT ro.standard ? 'talent_chat' AND EXISTS (SELECT 1 FROM ally_personen p JOIN talent_chat c ON c.talent_id = p.talent_id AND c.chat_an WHERE p.rolle = ro.schluessel AND p.talent_id IS NOT NULL
           AND NOT EXISTS (SELECT 1 FROM ally_person_rechte x WHERE x.person = p.matrix_user_id AND x.recht = 'talent_chat' AND x.wirkung = 'plus')) THEN
        fehler := 'Bei Talents mit dieser Rolle ist der Ally-Chat eingeschaltet. Bitte ihn dort zuerst ausschalten.';
      END IF;
    END IF;
    IF fehler IS NULL AND p_aktion IN ('ro_neu', 'ro_speichern') THEN
      IF nm = '' OR length(nm) > 40 THEN
        fehler := 'Bitte einen Namen mit höchstens 40 Zeichen angeben.';
      ELSIF lower(nm) IN ('admin', 'superadmin', 'talent', 'ohne rolle') AND lower(nm) IS DISTINCT FROM lower(btrim(ro.name))
        AND NOT (coalesce(ro.vorlage, '') = 'talent' AND lower(nm) = 'talent') THEN
        fehler := 'Diesen Namen gibt es schon fest. Bitte einen anderen wählen.';
      ELSIF EXISTS (SELECT 1 FROM ally_rollen x WHERE lower(btrim(x.name)) = lower(nm) AND x.schluessel IS DISTINCT FROM ro.schluessel) THEN
        fehler := 'Eine Rolle mit diesem Namen gibt es schon (auch Rollen im Papierkorb zählen).';
      ELSIF length(be) > 300 THEN
        fehler := 'Die Beschreibung ist zu lang (höchstens 300 Zeichen).';
      ELSE
        pr := ally_rolle_rechte_pruefen(CASE WHEN jsonb_typeof(d->'rechte') = 'object' THEN d->'rechte' ELSE '{}'::jsonb END);
        IF NOT coalesce((pr->>'ok')::boolean, false) THEN fehler := pr->>'fehler';
        -- Migration 158 (Bauplan B3a): die Rolle Talent bekommt nur Rechte aus der Gruppe „Talent-Bereich“ (nur_selbst; Prüfbericht M156).
        ELSIF coalesce(ro.art, art_neu) = 'talent' AND EXISTS (SELECT 1 FROM jsonb_object_keys(pr->'rechte') AS rk(recht) JOIN ally_rechte z ON z.schluessel = rk.recht WHERE NOT z.nur_selbst) THEN
          fehler := 'Eine Rolle für Talents bekommt nur Rechte aus der Gruppe „Talent-Bereich“.';
        -- Migration 162 (Bauplan B5a): „Eigenes Profil“ bleibt in Rollen der Art talent immer an (Prüfbericht M161 N1).
        ELSIF coalesce(ro.art, art_neu) = 'talent' AND plattform_modul_an('talents') AND NOT (pr->'rechte') ? 'talent_profil' THEN
          fehler := 'In einer Rolle für Talents bleibt „Eigenes Profil“ immer an. Ohne dieses Recht sähe kein Talent sein Profil.';
        -- Migration 163 (Bauplan B5b): Ally-Chat ist eine Erlaubnis (Stefan G12); nicht wegnehmen, solange Talents mit dieser Rolle den Chat an haben.
        ELSIF ro.art = 'talent' AND plattform_modul_an('talents') AND NOT (pr->'rechte') ? 'talent_chat' AND EXISTS (SELECT 1 FROM ally_personen p JOIN talent_chat c ON c.talent_id = p.talent_id AND c.chat_an WHERE p.rolle = ro.schluessel AND p.talent_id IS NOT NULL
           AND NOT EXISTS (SELECT 1 FROM ally_person_rechte x WHERE x.person = p.matrix_user_id AND x.recht = 'talent_chat' AND x.wirkung = 'plus')) THEN
          fehler := 'Bei Talents mit dieser Rolle ist der Ally-Chat eingeschaltet. Bitte ihn dort zuerst ausschalten.';
        END IF;
      END IF;
    END IF;
    IF fehler IS NULL THEN
      IF p_aktion = 'ro_neu' THEN
        LOOP
          k := 'r' || nextval('ally_rollen_nr');
          EXIT WHEN NOT EXISTS (SELECT 1 FROM ally_rollen x WHERE x.schluessel = k);
        END LOOP;
        INSERT INTO ally_rollen (schluessel, name, beschreibung, sortierung, rechte, fuer_personen, art, erstellt_von, geaendert_von)
        VALUES (k, nm, be, CASE WHEN art_neu = 'talent' THEN 1000 ELSE 100 END, '{}', art_neu <> 'talent', art_neu, s.person, s.person);
        INSERT INTO ally_rollen_rechte (rolle, recht, reichweite, geaendert_von)
        SELECT k, e.key, e.value #>> '{}', s.person FROM jsonb_each(pr->'rechte') e;
        m := 'Rolle „' || nm || '“ angelegt. ' || CASE WHEN art_neu = 'talent' THEN 'Talents bekommen sie beim Einladen oder im Talent-Profil.'
          ELSE 'Personen bekommen sie unter Team und Rollen › Personen.' END;
      ELSIF p_aktion = 'ro_speichern' THEN
        UPDATE ally_rollen SET name = nm, beschreibung = be, geaendert_am = now(), geaendert_von = s.person WHERE schluessel = ro.schluessel;
        DELETE FROM ally_rollen_rechte rr USING ally_rechte z
        WHERE rr.rolle = ro.schluessel AND z.schluessel = rr.recht AND (z.modul IS NULL OR plattform_modul_an(z.modul)) AND NOT (pr->'rechte') ? rr.recht
          -- Migration 167 (Bauplan B6): T3, ohne eingebundenen Speicherort steht „Ordner freigeben“ nicht im Formular und bleibt erhalten
          AND (rr.recht <> 'speicherort_eigen' OR coalesce((ally_speicherort_eigen()->>'eingerichtet')::boolean, false));
        INSERT INTO ally_rollen_rechte (rolle, recht, reichweite, geaendert_von)
        SELECT ro.schluessel, e.key, e.value #>> '{}', s.person FROM jsonb_each(pr->'rechte') e
        ON CONFLICT (rolle, recht) DO UPDATE SET reichweite = EXCLUDED.reichweite, geaendert_am = now(), geaendert_von = EXCLUDED.geaendert_von
        WHERE ally_rollen_rechte.reichweite IS DISTINCT FROM EXCLUDED.reichweite;
        SELECT count(*) INTO n FROM ally_personen p WHERE (p.rolle = ro.schluessel OR EXISTS (SELECT 1 FROM ally_person_rollen x WHERE x.person = p.matrix_user_id AND x.rolle = ro.schluessel)) AND p.aktiv;  -- Migration 206 (mehrere Rollen je Person, Stefan 04.11.2026)
        m := 'Rolle „' || nm || '“ gespeichert.' || CASE WHEN n > 0 THEN ' Gilt sofort für ' || n || CASE WHEN n = 1 THEN ' Person.' ELSE ' Personen.' END ELSE '' END;
      ELSIF p_aktion = 'ro_standard' THEN
        PERFORM ally_rolle_auf_standard(ro.schluessel, s.person);
        SELECT count(*) INTO n FROM ally_personen p WHERE (p.rolle = ro.schluessel OR EXISTS (SELECT 1 FROM ally_person_rollen x WHERE x.person = p.matrix_user_id AND x.rolle = ro.schluessel)) AND p.aktiv;  -- Migration 206 (mehrere Rollen je Person, Stefan 04.11.2026)
        m := 'Rolle „' || ro.name || '“ auf den Standard zurückgesetzt.' || CASE WHEN n > 0 THEN ' Gilt sofort für ' || n || CASE WHEN n = 1 THEN ' Person.' ELSE ' Personen.' END ELSE '' END;
      ELSIF p_aktion = 'ro_archivieren' THEN
        -- Migration 165 (Bauplan B5c): bei Rollen für Talents zählen auch inaktive Personen (Prüfbericht M165 N1).
        SELECT count(*) INTO n FROM ally_personen p WHERE (p.rolle = ro.schluessel OR EXISTS (SELECT 1 FROM ally_person_rollen x WHERE x.person = p.matrix_user_id AND x.rolle = ro.schluessel)) AND (p.aktiv OR ro.art = 'talent');  -- Migration 206 (mehrere Rollen je Person, Stefan 04.11.2026)
        IF ro.archiviert_am IS NOT NULL THEN
          fehler := 'Die Rolle liegt schon im Papierkorb.';
        ELSIF n > 0 THEN
          fehler := 'Die Rolle „' || ro.name || '“ haben noch ' || n || CASE WHEN n = 1 THEN ' Person' ELSE ' Personen' END || '. Bitte zuerst eine andere Rolle zuweisen.';
        ELSE
          UPDATE ally_rollen SET archiviert_am = now(), archiviert_von = s.person, geaendert_am = now(), geaendert_von = s.person WHERE schluessel = ro.schluessel;
          m := 'Rolle „' || ro.name || '“ liegt jetzt im Papierkorb. Sie lässt sich nicht mehr zuweisen und gibt keine Rechte mehr. Im Papierkorb kannst du sie wiederherstellen oder endgültig löschen.';
        END IF;
      ELSE
        IF ro.archiviert_am IS NULL THEN
          fehler := 'Die Rolle liegt nicht im Papierkorb.';
        ELSE
          UPDATE ally_rollen SET archiviert_am = NULL, archiviert_von = NULL, geaendert_am = now(), geaendert_von = s.person WHERE schluessel = ro.schluessel;
          m := 'Rolle „' || ro.name || '“ wiederhergestellt.';
        END IF;
      END IF;
    END IF;
  END IF;
  PERFORM ally_web_meldung(p_token, coalesce(fehler, m), CASE WHEN fehler IS NULL THEN 'ok' ELSE 'fehler' END, NULL);
  RETURN jsonb_build_object('ok', fehler IS NULL, 'angemeldet', true, 'schluessel', CASE WHEN fehler IS NULL THEN k END);
END $function$;
CREATE OR REPLACE FUNCTION public.ally_ui_rahmen(p_token text, p_seite text)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
  s record;
  fl text; fa text;
  seite text := CASE WHEN coalesce(p_seite, '') ~ '^[a-z0-9-]{1,40}$' THEN p_seite ELSE 'start' END;
  f record;
  erlaubt boolean := false;
  st jsonb; wert text; budget text;
  n_ohne int := 0; teil boolean := false;   -- Migration 189
  ki jsonb := NULL;
  leiste jsonb := NULL;
  zustand jsonb;
  startziel text;
BEGIN
  -- Rahmen einer Seite der neuen Oberfläche (BA3, Glocke BA4): Sitzung, Person, Kopf (KI, Glocke mit den letzten 10 Benachrichtigungen, Zahnrad), linke Leiste gefiltert nach Paket, Recht und Rolle,
  -- Zustände der Person für diese Seite und die Leiste, Ziel-Unterablauf der Seite, Meldung nach einer Aktion (wird dabei gelesen und gelöscht).
  SELECT * INTO s FROM ally_ui_sitzung(p_token);
  IF NOT FOUND THEN
    RETURN jsonb_build_object('angemeldet', false, 'produkt', produkt_name());
  END IF;
  SELECT x.flash, x.flash_art INTO fl, fa FROM ally_web_sitzungen x WHERE x.token_hash = s.token_hash FOR UPDATE;
  UPDATE ally_web_sitzungen x SET letzte_nutzung = now(), flash = NULL, flash_art = NULL WHERE x.token_hash = s.token_hash;
  IF s.muss_pw_setzen THEN
    RETURN jsonb_build_object('angemeldet', true, 'muss_pw_setzen', true, 'produkt', produkt_name(), 'csrf', ally_ui_csrf(s.token_hash),
      'person', jsonb_build_object('name', s.name, 'email', s.email),
      'hinweis', CASE WHEN fl IS NOT NULL THEN jsonb_build_object('text', fl, 'ton', CASE WHEN fa = 'ok' THEN 'ok' ELSE 'warn' END) END);
  END IF;
  -- Migration 161 (Bauplan B4b): Startziel (G6) – wer die Startseite nicht hat und als einzige Seite das eigene Profil (talent-bereich), landet dort.
  IF seite = 'start' THEN
    IF NOT ally_ui_funktion_erlaubt(s.person, s.rolle, 'start') AND ally_ui_funktion_erlaubt(s.person, s.rolle, 'talent-bereich')
       AND NOT EXISTS (SELECT 1 FROM ally_ui_funktionen x WHERE x.schluessel NOT IN ('start', 'talent-bereich') AND ally_ui_funktion_erlaubt(s.person, s.rolle, x.schluessel)) THEN
      seite := 'talent-bereich';
    -- Migration 169 (Startseite): gilt für die Person eine andere Startseite (eigene Wahl oder Vorgabe für alle), steht sie als startziel im Rahmen.
    -- Der Inhalt bleibt die Startseite; die Web-App wechselt beim Aufruf ohne Parameter zur Seite startziel. Ohne Einstellung fehlt der Eintrag.
    ELSE
      startziel := nullif(ally_startseite_ziel(s.person), 'start');
    END IF;
  END IF;
  SELECT * INTO f FROM ally_ui_funktionen x WHERE x.schluessel = seite;
  IF FOUND THEN erlaubt := ally_ui_funktion_erlaubt(s.person, s.rolle, seite); END IF;
  IF ally_ui_funktion_erlaubt(s.person, s.rolle, 'ki-verbrauch') THEN
    st := ki_monat_stand();
    wert := CASE WHEN st->>'verbrauch_eur' IS NOT NULL THEN round((st->>'verbrauch_eur')::numeric)::text || ' €'
                 ELSE round(coalesce((st->>'verbrauch_usd')::numeric, 0))::text || ' US-$' END;
    budget := CASE WHEN st->>'verbrauch_eur' IS NOT NULL AND st->>'budget_eur' IS NOT NULL THEN round((st->>'budget_eur')::numeric)::text || ' €' END;
    -- Migration 189 (Plan 51): nur Buchungen ohne Preis → „unbekannt“ statt 0 €; mit bekannten zusammen: Betrag wie bisher und sichtbarer Zusatz im Text
    -- („· dazu N Aufrufe ohne Preis“ wie die Kostenzeile, kurz „KI ab 37 €“), ausführlich in der Beschreibung (title, Vorlesen)
    n_ohne := coalesce((st->>'ohne_preis')::int, 0);
    IF n_ohne > 0 AND n_ohne >= coalesce((st->>'aufrufe')::int, 0) THEN wert := 'unbekannt'; ELSE teil := n_ohne > 0; END IF;
    ki := jsonb_build_object('sichtbar', true,
      'text', 'KI ' || wert || coalesce(' / ' || budget, '') || CASE WHEN teil THEN ' · dazu ' || n_ohne::text || CASE WHEN n_ohne = 1 THEN ' Aufruf' ELSE ' Aufrufe' END || ' ohne Preis' ELSE '' END,
      'text_kurz', 'KI ' || CASE WHEN teil THEN 'ab ' ELSE '' END || wert,   -- Nachprüfung 189 N-S1: am Handy kurz „KI ab 37 €“ (mindestens so viel)
      'label', 'KI-Verbrauch in diesem Monat: ' || wert || coalesce(' von ' || budget, '')
        || CASE WHEN n_ohne > 0 THEN ' · ' || CASE WHEN wert = 'unbekannt' THEN '' ELSE 'dazu ' END || n_ohne::text || CASE WHEN n_ohne = 1 THEN ' Aufruf' ELSE ' Aufrufe' END
          || ' ohne Preis (Kosten unbekannt)' ELSE '' END,
      'unbekannt', n_ohne, 'ziel', jsonb_build_object('seite', 'ki-verbrauch'));
  END IF;
  -- Migration 161 (Bauplan B4b): Leiste für jede Person nach Recht (nicht mehr nach der Rolle); die Startseite steht nur darin, wenn sie erlaubt ist;
  -- ohne Startseite und ohne Seite in einer Gruppe gibt es keine Leiste.
  BEGIN
    SELECT jsonb_build_object('art', 'funktionen',
             'start', CASE WHEN ally_ui_funktion_erlaubt(s.person, s.rolle, 'start') THEN
               jsonb_build_object('text', (SELECT x.name FROM ally_ui_funktionen x WHERE x.schluessel = 'start'), 'ziel', jsonb_build_object('seite', 'start')) END,
             'gruppen', coalesce(jsonb_agg(jsonb_build_object('id', g.schluessel, 'name', g.name, 'eintraege', e.eintraege) ORDER BY g.sortierung, g.schluessel), '[]'::jsonb))
      INTO leiste
    FROM ally_ui_gruppen g
    CROSS JOIN LATERAL (SELECT jsonb_agg(jsonb_build_object('schluessel', x.schluessel, 'name', ally_ui_name(x.name), 'ziel', jsonb_build_object('seite', x.schluessel))
                          ORDER BY x.sortierung, x.schluessel) AS eintraege
                        FROM ally_ui_funktionen x WHERE x.gruppe = g.schluessel AND x.art = 'funktion' AND ally_ui_funktion_erlaubt(s.person, s.rolle, x.schluessel)) e
    WHERE e.eintraege IS NOT NULL;
    IF leiste->'start' = 'null'::jsonb AND leiste->'gruppen' = '[]'::jsonb THEN leiste := NULL; END IF;
  END;
  SELECT coalesce(jsonb_object_agg(z.schluessel, z.wert), '{}'::jsonb) INTO zustand FROM ally_ui_zustand z
  WHERE z.person = s.person AND (z.schluessel LIKE 'leiste.%' OR split_part(z.schluessel, '.', 1) = seite);
  RETURN jsonb_build_object('angemeldet', true, 'muss_pw_setzen', false, 'produkt', produkt_name(), 'csrf', ally_ui_csrf(s.token_hash),
    'texte', ally_ui_texte(),
    'person', jsonb_build_object('name', s.name, 'email', s.email, 'rolle', s.rolle, 'rolle_text', coalesce((SELECT string_agg(r.name, ', ' ORDER BY array_position(ally_person_rollen_liste(s.person), r.schluessel)) FROM ally_rollen r
      WHERE r.schluessel = ANY (ally_person_rollen_liste(s.person))), nullif(s.rolle, ''), 'Ohne Rolle')),  -- Migration 206 (mehrere Rollen je Person, Stefan 04.11.2026): alle Rollen
    'kopf', jsonb_build_object('ki', ki,
       'glocke', CASE WHEN ally_ui_funktion_erlaubt(s.person, s.rolle, 'benachrichtigungen') THEN ally_benachrichtigungen_glocke(s.person, s.rolle)
         || jsonb_build_object('ziel_alle', jsonb_build_object('seite', 'benachrichtigungen'), 'gelesen_aktion', 'benachrichtigungen_gelesen') END,
       'zahnrad', CASE WHEN ally_ui_funktion_erlaubt(s.person, s.rolle, 'einstellungen') THEN jsonb_build_object('ziel', jsonb_build_object('seite', 'einstellungen')) END),
    'profil_ziel', CASE WHEN ally_ui_funktion_erlaubt(s.person, s.rolle, 'einstellungen') THEN jsonb_build_object('seite', 'einstellungen', 'parameter', jsonb_build_object('bereich', 'profil')) END,
    'leiste', leiste,
    'zustand', zustand,
    'funktion', jsonb_build_object('schluessel', seite, 'erlaubt', erlaubt, 'workflow_id', CASE WHEN erlaubt THEN f.workflow_id END,
       'art', CASE WHEN erlaubt THEN f.art END, 'name', CASE WHEN erlaubt THEN ally_ui_name(f.name) END, 'beschreibung', CASE WHEN erlaubt THEN f.beschreibung END,
       'einstellungen_ziel', CASE WHEN erlaubt THEN f.einstellungen_ziel END, 'leiste_aktiv', CASE WHEN erlaubt THEN f.leiste_aktiv END),
    'hinweis', CASE WHEN fl IS NOT NULL THEN jsonb_build_object('text', fl, 'ton', CASE WHEN fa = 'ok' THEN 'ok' ELSE 'warn' END) END)
    || CASE WHEN startziel IS NOT NULL THEN jsonb_build_object('startziel', startziel) ELSE '{}'::jsonb END;
END $function$;
CREATE OR REPLACE FUNCTION public.ally_person_anlegen_abschliessen(p_auftrag_id bigint, p_ok boolean, p_fehler text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
  a record;
  em text;
  pid integer;
  code text := split_part(coalesce(p_fehler, ''), ':', 1);
  m text;
BEGIN
  -- Person anlegen, Schritt 2 (Stefan 19.10.2026, Migration 56): nach ALLY 18. ok -> Person mit matrix_user_id, Rolle, Funktionen, Talents, Postfächern;
  -- sonst Reservierung freigeben (Auftrag "fehler") und Grund melden. Ist offen, ob der Chat-Benutzer entstanden ist, wird die Kennung gesperrt.
  SELECT * INTO a FROM ally_chat_auftraege WHERE id = p_auftrag_id FOR UPDATE;
  IF NOT FOUND OR a.art <> 'anlegen' OR a.status NOT IN ('offen', 'in_arbeit') THEN
    RETURN jsonb_build_object('ok', false, 'auftrag_id', p_auftrag_id, 'fehler', 'nicht_in_arbeit', 'meldung', 'Der Auftrag ist nicht (mehr) offen.');
  END IF;
  IF coalesce(p_ok, false) AND EXISTS (SELECT 1 FROM ally_personen WHERE matrix_user_id = a.matrix_user_id) THEN
    p_ok := false; code := 'doppelt';
  END IF;
  IF NOT coalesce(p_ok, false) THEN
    IF code NOT IN ('zugang', 'zeitueberschreitung', 'verbindung', 'belegt', 'vorhanden', 'unklar', 'ungueltig', 'doppelt', 'einstellung', 'fremder_server') THEN
      code := 'server';
    END IF;
    IF code IN ('vorhanden', 'unklar', 'doppelt') THEN
      INSERT INTO ally_chat_kennungen (kennung, matrix_user_id, art) VALUES (a.kennung, a.matrix_user_id, 'fremd') ON CONFLICT DO NOTHING;
    END IF;
    m := a.anzeigename || ' wurde nicht angelegt. ' || ally_chat_fehler_text(code);
    UPDATE ally_chat_auftraege SET status = 'fehler', fehler = left(coalesce(nullif(p_fehler, ''), code), 200), meldung = m, erledigt_am = now() WHERE id = a.id;
    RETURN jsonb_build_object('ok', false, 'auftrag_id', a.id, 'art', a.art, 'kennung', a.kennung, 'fehler', code, 'meldung', m);
  END IF;

  em := a.daten->>'email';
  IF em IS NOT NULL AND EXISTS (SELECT 1 FROM ally_personen WHERE email = em) THEN
    em := NULL;
  END IF;
  INSERT INTO ally_personen (matrix_user_id, name, email, aktiv, rolle) VALUES (a.matrix_user_id, a.anzeigename, em, true, a.daten->>'rolle')
  RETURNING id INTO pid;
  INSERT INTO ally_chat_kennungen (kennung, matrix_user_id, art, ref_id) VALUES (a.kennung, a.matrix_user_id, 'person', pid)
  ON CONFLICT (kennung) DO UPDATE SET art = 'person', ref_id = EXCLUDED.ref_id WHERE ally_chat_kennungen.matrix_user_id = EXCLUDED.matrix_user_id;
  PERFORM ally_person_rolle_anwenden(a.matrix_user_id, a.daten->>'rolle',
    ARRAY(SELECT x FROM jsonb_array_elements_text(coalesce(a.daten->'funktionen', '[]'::jsonb)) AS x));
  -- Migration 206 (mehrere Rollen je Person, Stefan 04.11.2026): weitere Rollen aus der Einladung (person_einladen); nur aktive eigene Rollen, nie neben Admin
  INSERT INTO ally_person_rollen (person, rolle, erstellt_von)
  SELECT a.matrix_user_id, x, a.erstellt_von FROM jsonb_array_elements_text(CASE WHEN jsonb_typeof(a.daten->'rollen') = 'array' THEN a.daten->'rollen' ELSE '[]'::jsonb END) AS x
  WHERE EXISTS (SELECT 1 FROM ally_rollen r WHERE r.schluessel = x AND r.art = 'eigen' AND r.archiviert_am IS NULL AND r.fuer_personen)
    AND x IS DISTINCT FROM (SELECT p.rolle FROM ally_personen p WHERE p.matrix_user_id = a.matrix_user_id)
    AND coalesce((SELECT p.rolle FROM ally_personen p WHERE p.matrix_user_id = a.matrix_user_id), '') <> 'admin'
  ON CONFLICT DO NOTHING;
  -- Prüfung 1 (L4): ist die erste Rolle inzwischen archiviert (Person ohne Rolle), rückt die erste weitere nach vorn
  UPDATE ally_personen p SET rolle = w.rolle, geaendert_am = now()
  FROM (SELECT x.rolle FROM ally_person_rollen x JOIN ally_rollen r ON r.schluessel = x.rolle WHERE x.person = a.matrix_user_id
        ORDER BY r.sortierung, lower(r.name), r.schluessel COLLATE "C" LIMIT 1) w
  WHERE p.matrix_user_id = a.matrix_user_id AND p.rolle IS NULL;
  DELETE FROM ally_person_rollen x USING ally_personen p WHERE x.person = a.matrix_user_id AND p.matrix_user_id = x.person AND p.rolle = x.rolle;
  INSERT INTO talent_personen (talent_id, matrix_user_id)
  SELECT x::integer, a.matrix_user_id FROM jsonb_array_elements_text(coalesce(a.daten->'talents', '[]'::jsonb)) AS x
  WHERE EXISTS (SELECT 1 FROM talents t WHERE t.id = x::integer) ON CONFLICT DO NOTHING;
  -- Migration 90: keine Zuständigkeit je Postfach mehr (gemeinsame Postfächer sieht, wer das Recht aus der Rolle hat; persönliche nur die Person selbst)
  m := a.anzeigename || ' angelegt. Chat-Konto: ' || a.matrix_user_id || '. Jetzt einen Zugang mit Startcode erzeugen.'
    || CASE WHEN em IS NULL AND a.daten->>'email' IS NOT NULL THEN ' Die E-Mail-Adresse gehört inzwischen zu einer anderen Person, bitte eine andere eintragen.' ELSE '' END;
  UPDATE ally_chat_auftraege SET status = 'erledigt', fehler = NULL, meldung = m, ref_id = pid, daten = '{}'::jsonb, erledigt_am = now() WHERE id = a.id;
  RETURN jsonb_build_object('ok', true, 'auftrag_id', a.id, 'art', a.art, 'kennung', a.kennung, 'matrix_user_id', a.matrix_user_id, 'person_id', pid, 'meldung', m);
END $function$;
CREATE OR REPLACE FUNCTION public.ally_person_rolle_anwenden(p_user text, p_rolle text, p_funktionen text[])
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
  ro text := nullif(btrim(coalesce(p_rolle, '')), '');
BEGIN
  -- Rolle einer Person setzen (Migration 64): Admin oder eine aktive, vom Admin angelegte Rolle; unbekannt oder archiviert = ohne Rolle.
  -- Die Rechte kommen aus der Rolle (ally_rollen_rechte), sie werden nicht je Person gespeichert. Nur das Recht „admin“ wird für die alte Oberfläche
  -- mitgeführt. Einzeln freigegebene Rechte (p_funktionen, nur Rechte der alten Oberfläche, ohne admin/superadmin) kommen dazu; vorhandene bleiben.
  IF ro IS NOT NULL AND NOT EXISTS (SELECT 1 FROM ally_rollen r WHERE r.schluessel = ro AND r.fuer_personen AND (r.art = 'admin' OR (r.art = 'eigen' AND r.archiviert_am IS NULL))) THEN
    ro := NULL;
  END IF;
  IF ally_person_superadmin(p_user) THEN ro := 'admin'; END IF;
  UPDATE ally_personen SET rolle = ro, geaendert_am = now() WHERE matrix_user_id = p_user AND rolle IS DISTINCT FROM ro;
  IF ro = 'admin' THEN
    INSERT INTO ally_nutzer_rechte (matrix_user_id, recht) VALUES (p_user, 'admin') ON CONFLICT DO NOTHING;
    DELETE FROM ally_person_rollen WHERE person = p_user;  -- Migration 206 (mehrere Rollen je Person, Stefan 04.11.2026): Admin steht allein
  ELSE
    DELETE FROM ally_nutzer_rechte WHERE matrix_user_id = p_user AND recht = 'admin';
  END IF;
  -- Migration 167 (Bauplan B6): F13, einzeln freigegebene Rechte als eigene Rechte (plus) der Person, nicht mehr in ally_nutzer_rechte
  PERFORM ally_einzelrecht_uebernehmen(p_user, x, 'anlegen') FROM unnest(coalesce(p_funktionen, '{}')) AS x WHERE x NOT IN ('admin', 'superadmin');
END $function$;
CREATE OR REPLACE FUNCTION public.ally_person_rolle_abgleichen(p_user text)
 RETURNS void
 LANGUAGE sql
AS $function$
  -- Rolle folgt dem Admin-Recht, wenn es direkt gesetzt wird (alte Oberfläche „Personen und Rechte“, Migration 64): admin/superadmin -> Rolle Admin;
  -- wer das Admin-Recht verliert, ist danach ohne Rolle (der Admin wählt eine neue). Andere Rollen bleiben.
  UPDATE ally_personen p SET rolle = x.neu
  FROM (SELECT CASE WHEN EXISTS (SELECT 1 FROM ally_nutzer_rechte r WHERE r.matrix_user_id = p_user AND r.recht IN ('admin', 'superadmin')) THEN 'admin'
                    WHEN q.rolle = 'admin' THEN NULL ELSE q.rolle END AS neu
        FROM ally_personen q WHERE q.matrix_user_id = p_user) x
  WHERE p.matrix_user_id = p_user AND p.rolle IS DISTINCT FROM x.neu;
  -- Migration 206 (mehrere Rollen je Person, Stefan 04.11.2026), Prüfung 1 (M3): Admin steht allein – wer über das Admin-Recht Admin wird, verliert die weiteren Rollen
  DELETE FROM ally_person_rollen x WHERE x.person = p_user AND EXISTS (SELECT 1 FROM ally_personen q WHERE q.matrix_user_id = p_user AND q.rolle = 'admin')
$function$;
CREATE OR REPLACE FUNCTION public.ally_rolle_papierkorb(p_token text, p_aktion text, p_daten jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
  s record; ro ally_rollen%ROWTYPE;
  d jsonb := CASE WHEN jsonb_typeof(p_daten) = 'object' THEN p_daten ELSE '{}'::jsonb END;
  liste text[]; m text := NULL; fehler text := NULL; n integer := 0; bleibt text[] := '{}';
BEGIN
  -- Migration 129: Papierkorb der Rollen (archivierte Rollen). Endgültig löschen nur ohne zugeordnete Personen (auch deaktivierte). Nur Admins.
  SELECT * INTO s FROM ally_ui_sitzung(p_token);
  IF NOT FOUND OR s.muss_pw_setzen THEN RETURN jsonb_build_object('ok', false, 'angemeldet', false); END IF;
  IF NOT ally_hat_recht(s.person, 'admin') THEN
    fehler := 'Rollen verwaltet eine Person mit der Rolle Admin.';
  ELSIF p_aktion = 'ro_endgueltig' THEN
    SELECT * INTO ro FROM ally_rollen x WHERE x.schluessel = lower(btrim(coalesce(d->>'schluessel', ''))) AND x.art IN ('eigen', 'talent') FOR UPDATE;  -- Migration 165 (Bauplan B5c): auch Rollen für Talents
    IF NOT FOUND OR ro.archiviert_am IS NULL THEN
      fehler := 'Diese Rolle liegt nicht mehr im Papierkorb. Bitte die Seite neu laden.';
    ELSE
      -- Migration 206 (mehrere Rollen je Person, Stefan 04.11.2026), Prüfung 1 (M1): auch weitere Rollen zählen (auch deaktivierte Personen)
      SELECT count(*) INTO n FROM ally_personen p WHERE p.rolle = ro.schluessel OR EXISTS (SELECT 1 FROM ally_person_rollen x WHERE x.person = p.matrix_user_id AND x.rolle = ro.schluessel);
      IF n > 0 THEN
        fehler := 'Die Rolle „' || ro.name || '“ ist noch ' || n || CASE WHEN n = 1 THEN ' Person' ELSE ' Personen' END
          || ' zugeordnet (auch deaktivierte zählen). Bitte zuerst eine andere Rolle geben, dann endgültig löschen.';
      ELSE
        DELETE FROM ally_rollen WHERE schluessel = ro.schluessel;
        m := 'Rolle „' || ro.name || '“ endgültig gelöscht.';
      END IF;
    END IF;
  ELSIF p_aktion = 'ro_papierkorb_leeren' THEN
    IF coalesce(d->>'liste', '') !~ '^[a-z0-9_]{1,40}(,[a-z0-9_]{1,40})*$' OR cardinality(string_to_array(d->>'liste', ',')) > 1000 THEN
      fehler := 'Der Papierkorb hat sich geändert. Bitte die Seite neu laden.';
    ELSE
      liste := string_to_array(d->>'liste', ',');
      SELECT coalesce(array_agg(ro2.name ORDER BY lower(ro2.name)), '{}') INTO bleibt FROM ally_rollen ro2
       WHERE ro2.schluessel = ANY (liste) AND ro2.art IN ('eigen', 'talent') AND ro2.archiviert_am IS NOT NULL AND (EXISTS (SELECT 1 FROM ally_personen p WHERE p.rolle = ro2.schluessel) OR EXISTS (SELECT 1 FROM ally_person_rollen x WHERE x.rolle = ro2.schluessel));
      DELETE FROM ally_rollen ro2 WHERE ro2.schluessel = ANY (liste) AND ro2.art IN ('eigen', 'talent') AND ro2.archiviert_am IS NOT NULL
        AND NOT EXISTS (SELECT 1 FROM ally_personen p WHERE p.rolle = ro2.schluessel) AND NOT EXISTS (SELECT 1 FROM ally_person_rollen x WHERE x.rolle = ro2.schluessel);
      GET DIAGNOSTICS n = ROW_COUNT;
      m := CASE WHEN n = 0 THEN 'Keine Rolle gelöscht.' WHEN n = 1 THEN '1 Rolle endgültig gelöscht.' ELSE n || ' Rollen endgültig gelöscht.' END
        || CASE WHEN cardinality(bleibt) > 0 THEN ' Im Papierkorb bleiben, weil ihnen noch Personen zugeordnet sind: ' || array_to_string(bleibt, ', ') || '.' ELSE '' END;
    END IF;
  ELSE
    fehler := 'Diese Aktion gibt es nicht.';
  END IF;
  PERFORM ally_web_meldung(p_token, coalesce(fehler, m), CASE WHEN fehler IS NULL THEN 'ok' ELSE 'fehler' END, NULL);
  RETURN jsonb_build_object('ok', fehler IS NULL, 'angemeldet', true);
END $function$;
CREATE OR REPLACE FUNCTION public.ally_testdaten_entfernen(p_von text)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
  tp text[]; tt integer[]; n jsonb := '{}'::jsonb; c integer; behalten text[];
BEGIN
  -- Migration 79: alle markierten Testdaten vollständig entfernen. Reihenfolge: Berichte, Kampagnen, Talents (mit allem, was per Fremdschlüssel daran hängt),
  -- Personen (ebenso), Einträge ohne Fremdschlüssel (Sitzungen, Rechte, Einstellungen, Chat-Kennungen), Rollen. Echte Daten bleiben unberührt.
  PERFORM pg_advisory_xact_lock(hashtext('ally_testdaten'));
  tp := ARRAY(SELECT p.matrix_user_id FROM ally_personen p WHERE p.testdaten);
  tt := ARRAY(SELECT t.id FROM talents t WHERE t.testdaten);
  DELETE FROM talent_berichte b WHERE b.testdaten OR (cardinality(b.talent_ids) > 0 AND b.talent_ids <@ tt);
  GET DIAGNOSTICS c = ROW_COUNT; n := n || jsonb_build_object('berichte', c);
  DELETE FROM talent_kampagnen k WHERE k.testdaten;
  GET DIAGNOSTICS c = ROW_COUNT; n := n || jsonb_build_object('kampagnen', c);
  DELETE FROM talent_kampagnen_papierkorb pk WHERE pk.testdaten;  -- Migration 131 (Zählung unverändert)
  DELETE FROM talents t WHERE t.testdaten;
  GET DIAGNOSTICS c = ROW_COUNT; n := n || jsonb_build_object('talents', c);
  DELETE FROM talent_profil_papierkorb x WHERE x.testdaten;  -- Migration 130 (Zählung unverändert)
  -- Migration 81: Tabellen ohne Fremdschlüssel – nur Zeilen der Test-Personen bzw. Test-Talents (echte Zeilen nie)
  DELETE FROM ki_verbrauch x WHERE x.matrix_user_id = ANY (tp);
  GET DIAGNOSTICS c = ROW_COUNT; n := n || jsonb_build_object('ki_verbrauch', c);
  DELETE FROM marketing_posts x WHERE x.matrix_user_id = ANY (tp);
  DELETE FROM marketing_themen x WHERE x.matrix_user_id = ANY (tp);
  DELETE FROM marketing_papierkorb x WHERE x.matrix_user_id = ANY (tp);  -- Migration 133
  DELETE FROM marketing_pk_loeschauftraege x WHERE x.matrix_user_id = ANY (tp);  -- Migration 133
  DELETE FROM matrix_direct_rooms x WHERE x.matrix_user_id = ANY (tp);
  DELETE FROM ally_chat_auftraege x WHERE x.matrix_user_id = ANY (tp);
  DELETE FROM ally_gesendete_nachrichten x WHERE x.matrix_user_id = ANY (tp);
  DELETE FROM talent_importe x WHERE x.erstellt_von = ANY (tp);
  DELETE FROM talent_ki_anfragen x WHERE x.erstellt_von = ANY (tp) OR (cardinality(x.talent_ids) > 0 AND x.talent_ids <@ tt);
  DELETE FROM talent_widerrufe x WHERE x.talent_id = ANY (tt);
  DELETE FROM talent_loesch_dateien x WHERE x.talent_id = ANY (tt);
  DELETE FROM ally_web_sitzungen x WHERE x.matrix_user_id = ANY (tp);
  DELETE FROM ally_nutzer_rechte x WHERE x.matrix_user_id = ANY (tp);
  DELETE FROM ally_nutzer_funktionen x WHERE x.matrix_user_id = ANY (tp);
  DELETE FROM ally_nutzer_einstellungen x WHERE x.matrix_user_id = ANY (tp);
  -- Migration 90: ally_nutzer_postfaecher ist eine berechnete Sicht (Test-Personen sehen nie ein Postfach)
  DELETE FROM ally_chat_kennungen x WHERE x.matrix_user_id = ANY (tp);
  DELETE FROM ally_personen p WHERE p.testdaten;
  GET DIAGNOSTICS c = ROW_COUNT; n := n || jsonb_build_object('personen', c);
  -- Test-Rollen: nur entfernen, wenn keine echte Person sie inzwischen hat; sonst bleibt die Rolle als normale Rolle erhalten
  -- Migration 206 (mehrere Rollen je Person, Stefan 04.11.2026), Prüfung 1 (M2): auch als weitere Rolle einer echten Person (ally_person_rollen; Test-Personen sind oben schon gelöscht, ihre Zeilen mit ihnen)
  behalten := ARRAY(SELECT r.schluessel FROM ally_rollen r WHERE r.testdaten AND (EXISTS (SELECT 1 FROM ally_personen p WHERE p.rolle = r.schluessel)
    OR EXISTS (SELECT 1 FROM ally_person_rollen x WHERE x.rolle = r.schluessel)));
  UPDATE ally_rollen SET testdaten = false WHERE schluessel = ANY (behalten);
  DELETE FROM ally_rollen r WHERE r.testdaten;
  GET DIAGNOSTICS c = ROW_COUNT; n := n || jsonb_build_object('rollen', c, 'rollen_behalten', cardinality(behalten));
  DELETE FROM ally_ui_zustand z WHERE z.schluessel = 'testdaten.ausblenden';
  UPDATE ally_testdaten_stand SET aktiv = false, entfernt_am = now(), entfernt_von = p_von, anzahl = '{}'::jsonb WHERE id = 1;
  RETURN jsonb_build_object('ok', true, 'entfernt', n);
END $function$;
CREATE OR REPLACE FUNCTION public.ally_sicherung_kunde_inhalt(p_lauf bigint)
 RETURNS TABLE(tabelle text, abfrage text, ausgelassen text)
 LANGUAGE sql
 STABLE
AS $function$
  -- Migration 201 (Entscheidung Stefan 03.11.2026 15:04, „b“): Inhalt der Kunden-Sicherung = nur Kundendaten, keine Installation. Nur für einen laufenden Auftrag
  -- des Kunden-Ziels. Je Tabelle die Abfrage für COPY … TO STDOUT (CSV) und die ausgelassenen Spalten.
  -- Tabellen: erzeugt aus der Einteilung B7a (Kundendaten ohne Sicherungs-/Alttabellen, ohne ally_sicherung_*, ohne Sitzungen, OAuth-, Code-, Update- und
  -- Meta-Rückruf-Tabellen; werkzeuge/m201_bauen.py). Spalten: ohne bytea (verschlüsselte Werte), ohne Token/Geheimnis/Passwort/Prüfsumme/Code/Zugangsdaten-Spalten;
  -- KI-Kosten nur als Kundenpreis (kosten_usd * preis_faktor), ohne Einkaufspreis und Faktor des Anbieters. Zeilen: ohne Zeilen von Superadmins (Spalte person bzw.
  -- matrix_user_id; Chat-Sitzungen nach der Chat-ID am Ende der Sitzung, auch mit Präfix wie test:), ohne kurzlebige OAuth-Zustände in den Einstellungen je Person.
  -- Kein Schlüssel der Installation, keine Einstellungen der Installation.
  -- Migration 206 (mehrere Rollen je Person, Stefan 04.11.2026): dazu ally_person_rollen, kalender_termine, kalender_termin_personen.
  WITH k(tab, sitzung, zusatz) AS (VALUES
    ('ally_assistent_verlauf', NULL, NULL),
    ('ally_benachrichtigung_schalter', NULL, NULL),
    ('ally_benachrichtigungen', NULL, NULL),
    ('ally_cd', NULL, NULL),
    ('ally_cd_dateien', NULL, NULL),
    ('ally_chat_bereich', 'sitzung', NULL),
    ('ally_chat_kennungen', NULL, NULL),
    ('ally_ergebnisse', NULL, NULL),
    ('ally_gesendete_nachrichten', NULL, NULL),
    ('ally_kalender_abos', NULL, NULL),
    -- Migration 206 (mehrere Rollen je Person, Stefan 04.11.2026), Prüfung 1 (L1): weitere Rollen (206) und interner Kalender (205); ohne Termine für Superadmins (dieselbe Liste wie die allgemeine Regel),
    -- Eingeladene nur zu gesicherten Terminen
    ('ally_person_rollen', NULL, NULL),
    ('kalender_termin_personen', NULL, 'termin_id IN (SELECT t.id FROM public.kalender_termine t WHERE t.fuer NOT IN (SELECT r.matrix_user_id FROM public.ally_nutzer_rechte r WHERE r.recht = ''superadmin'' UNION SELECT p.matrix_user_id FROM public.ally_personen p WHERE coalesce(public.ally_hat_recht(p.matrix_user_id, ''superadmin''), false) ))'),
    ('kalender_termine', NULL, 'fuer NOT IN (SELECT r.matrix_user_id FROM public.ally_nutzer_rechte r WHERE r.recht = ''superadmin'' UNION SELECT p.matrix_user_id FROM public.ally_personen p WHERE coalesce(public.ally_hat_recht(p.matrix_user_id, ''superadmin''), false))'),
    ('ally_nutzer_einstellungen', NULL, 'schluessel NOT LIKE ''%state'' AND schluessel NOT LIKE ''%verifier'''),
    ('ally_nutzer_funktionen', NULL, NULL),
    ('ally_nutzer_rechte', NULL, NULL),
    ('ally_person_rechte', NULL, NULL),
    ('ally_person_startseite', NULL, NULL),
    ('ally_personen', NULL, NULL),
    ('ally_postfaecher', NULL, NULL),
    ('ally_speicherort_rechte', NULL, NULL),
    ('ally_ui_eigene_gruppen', NULL, NULL),
    ('ally_ui_zustand', NULL, NULL),
    ('ally_unternehmen', NULL, NULL),
    ('beleg_verarbeitung', NULL, NULL),
    ('ki_verbrauch', NULL, NULL),
    ('klaerungsfaelle', NULL, NULL),
    ('lieferanten_aliases', NULL, NULL),
    ('lieferanten_kategorie_mapping', NULL, NULL),
    ('mail_absender_regeln', NULL, NULL),
    ('mail_absender_regeln_papierkorb', NULL, NULL),
    ('mail_klassifizierung_log', NULL, NULL),
    ('mail_nachholen', NULL, NULL),
    ('mail_rueckfragen', NULL, NULL),
    ('marketing_hintergruende', NULL, NULL),
    ('marketing_papierkorb', NULL, NULL),
    ('marketing_pk_loeschauftraege', NULL, NULL),
    ('marketing_posts', NULL, NULL),
    ('marketing_themen', NULL, NULL),
    ('matrix_direct_rooms', NULL, NULL),
    ('matrix_verarbeitete_events', NULL, NULL),
    ('monatsberichte', NULL, NULL),
    ('monatsberichte_verlauf', NULL, NULL),
    ('n8n_chat_histories', 'session_id', NULL),
    ('postfach_empfang_beobachtung', NULL, NULL),
    ('postfach_empfang_neustart', NULL, NULL),
    ('postfach_empfang_stoerung', NULL, NULL),
    ('postfach_plaetze', NULL, NULL),
    ('speicher_ordner_protokoll', NULL, NULL),
    ('sync_mapping', NULL, NULL),
    ('system_meldungen', NULL, NULL),
    ('talent_ablage_dateien', NULL, NULL),
    ('talent_ablage_ordner', NULL, NULL),
    ('talent_abruf_versuche', NULL, NULL),
    ('talent_aufgaben', NULL, NULL),
    ('talent_beitraege', NULL, NULL),
    ('talent_beitrag_bilder', NULL, NULL),
    ('talent_beitrag_tage', NULL, NULL),
    ('talent_bereich', NULL, NULL),
    ('talent_bericht_vorlagen', NULL, NULL),
    ('talent_berichte', NULL, NULL),
    ('talent_chat', NULL, NULL),
    ('talent_chat_verlauf', NULL, NULL),
    ('talent_deliverable_versionen', NULL, NULL),
    ('talent_deliverables', NULL, NULL),
    ('talent_doppelt_entscheidungen', NULL, NULL),
    ('talent_doppelt_meldungen', NULL, NULL),
    ('talent_doppelt_verlauf', NULL, NULL),
    ('talent_einladung_rueckwege', NULL, NULL),
    ('talent_einladungen', NULL, NULL),
    ('talent_erinnerungen_lauf', NULL, NULL),
    ('talent_erinnerungsregeln', NULL, NULL),
    ('talent_importe', NULL, NULL),
    ('talent_kampagne_beitraege', NULL, NULL),
    ('talent_kampagne_links', NULL, NULL),
    ('talent_kampagne_talents', NULL, NULL),
    ('talent_kampagnen', NULL, NULL),
    ('talent_kampagnen_papierkorb', NULL, NULL),
    ('talent_kanaele', NULL, NULL),
    ('talent_kanal_tage', NULL, NULL),
    ('talent_ki_anfragen', NULL, NULL),
    ('talent_ki_auftraege', NULL, NULL),
    ('talent_ki_auswertungen', NULL, NULL),
    ('talent_ki_texte', NULL, NULL),
    ('talent_ki_themen', NULL, NULL),
    ('talent_konzept_angaben', NULL, NULL),
    ('talent_konzept_ziele', NULL, NULL),
    ('talent_konzepte', NULL, NULL),
    ('talent_loesch_ankuendigungen', NULL, NULL),
    ('talent_loesch_dateien', NULL, NULL),
    ('talent_mail_entwuerfe', NULL, NULL),
    ('talent_mail_zuordnung', NULL, NULL),
    ('talent_manuell_vorschlaege', NULL, NULL),
    ('talent_manuell_werte', NULL, NULL),
    ('talent_markensuche_kriterien', NULL, NULL),
    ('talent_markensuche_laeufe', NULL, NULL),
    ('talent_markensuche_treffer', NULL, NULL),
    ('talent_mediakits', NULL, NULL),
    ('talent_meldungen', NULL, NULL),
    ('talent_meldungen_talent', NULL, NULL),
    ('talent_notizen', NULL, NULL),
    ('talent_ordner', NULL, NULL),
    ('talent_personen', NULL, NULL),
    ('talent_profil_papierkorb', NULL, NULL),
    ('talent_sofortabrufe', NULL, NULL),
    ('talent_ui_zustand', NULL, NULL),
    ('talent_widerrufe', NULL, NULL),
    ('talent_zielgruppen', NULL, NULL),
    ('talent_zugaenge', NULL, NULL),
    ('talents', NULL, NULL),
    ('talents_briefing_ergebnisse', NULL, NULL),
    ('talents_briefing_freigaben', NULL, NULL),
    ('talents_briefing_laeufe', NULL, NULL),
    ('talents_meine_liste', NULL, NULL),
    ('talents_zahlen_vorrat', NULL, NULL)),
  s AS (SELECT k.tab, k.sitzung, k.zusatz, a.attname::text AS spalte, a.attnum,
          a.atttypid = 'bytea'::regtype OR a.attname::text ~ '(^|_)(token|secret|geheim|geheimnis|passwort|kennwort|pw|credential)(_|$)|_hash$|^hash$|^code$' OR (k.tab, a.attname::text) IN (('ki_verbrauch', 'preis_faktor'))
            OR CASE WHEN k.tab = 'ki_verbrauch' AND a.attname::text = 'kosten_usd' THEN 'kosten_usd * preis_faktor AS kundenpreis_usd' ELSE NULL END IS NOT NULL AS aus,
          CASE WHEN k.tab = 'ki_verbrauch' AND a.attname::text = 'kosten_usd' THEN 'kosten_usd * preis_faktor AS kundenpreis_usd' ELSE NULL END AS ersatz
        FROM k JOIN pg_class c ON c.relname::text = k.tab AND c.relkind = 'r' JOIN pg_namespace n ON n.oid = c.relnamespace AND n.nspname = 'public'
        JOIN pg_attribute a ON a.attrelid = c.oid AND a.attnum > 0 AND NOT a.attisdropped),
  t AS (SELECT s.tab, max(s.sitzung) AS sitzung, max(s.zusatz) AS zusatz,
          coalesce(max(s.spalte) FILTER (WHERE s.spalte = 'person'), max(s.spalte) FILTER (WHERE s.spalte = 'matrix_user_id')) AS person,
          string_agg(coalesce(s.ersatz, quote_ident(s.spalte)), ', ' ORDER BY s.attnum) FILTER (WHERE NOT s.aus OR s.ersatz IS NOT NULL) AS spalten,
          coalesce(string_agg(s.spalte, ',' ORDER BY s.attnum) FILTER (WHERE s.aus), '') AS ausgelassen
        FROM s GROUP BY s.tab)
  SELECT t.tab,
    'SELECT ' || t.spalten || ' FROM public.' || quote_ident(t.tab) || coalesce(' WHERE ' || nullif(concat_ws(' AND ',
      '(' || quote_ident(t.person) || ' IS NULL OR ' || quote_ident(t.person) || ' NOT IN (SELECT r.matrix_user_id FROM public.ally_nutzer_rechte r WHERE r.recht = ''superadmin'' UNION SELECT p.matrix_user_id FROM public.ally_personen p WHERE coalesce(public.ally_hat_recht(p.matrix_user_id, ''superadmin''), false)))',
      'coalesce(lower(substring(' || quote_ident(t.sitzung) || ' from ''(@[^@[:space:]]+)$'')), '''') NOT IN (SELECT lower(y.matrix_user_id) FROM (SELECT r.matrix_user_id FROM public.ally_nutzer_rechte r WHERE r.recht = ''superadmin'' UNION SELECT p.matrix_user_id FROM public.ally_personen p WHERE coalesce(public.ally_hat_recht(p.matrix_user_id, ''superadmin''), false)) y)',
      '(' || t.zusatz || ')'), ''), ''),
    t.ausgelassen
  FROM t
  WHERE t.spalten IS NOT NULL
    AND EXISTS (SELECT 1 FROM ally_sicherung_laeufe l WHERE l.id = p_lauf AND l.art = 'kunde' AND l.ergebnis = 'laeuft')
  ORDER BY t.tab
$function$;
DO $m$
BEGIN
  IF (SELECT md5(string_agg(z, E'\n' ORDER BY z COLLATE "C")) FROM (WITH t AS (SELECT c.oid, c.relname::text AS tab FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname::text = 'public' COLLATE "C" AND c.relkind::text = ANY (ARRAY['r', 'p']) AND c.relname::text = ANY (ARRAY['ally_person_rollen'])) SELECT 'S|' || t.tab || '|' || a.attname::text || '|' || format_type(a.atttypid, a.atttypmod) || '|' || CASE WHEN a.attnotnull THEN 'NN' ELSE '-' END || '|' || coalesce(pg_get_expr(d.adbin, d.adrelid), '') || '|' || a.attidentity::text || a.attgenerated::text AS z FROM t JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum > 0 AND NOT a.attisdropped LEFT JOIN pg_attrdef d ON d.adrelid = t.oid AND d.adnum = a.attnum UNION ALL SELECT 'C|' || t.tab || '|' || co.conname::text || '|' || co.contype::text || '|' || pg_get_constraintdef(co.oid) FROM t JOIN pg_constraint co ON co.conrelid = t.oid UNION ALL SELECT 'I|' || t.tab || '|' || ic.relname::text || '|' || pg_get_indexdef(i.indexrelid) FROM t JOIN pg_index i ON i.indrelid = t.oid JOIN pg_class ic ON ic.oid = i.indexrelid UNION ALL SELECT 'T|' || t.tab || '|' || tg.tgname::text || '|' || pg_get_triggerdef(tg.oid) || '|' || tg.tgenabled::text FROM t JOIN pg_trigger tg ON tg.tgrelid = t.oid AND NOT tg.tgisinternal) x) IS DISTINCT FROM '5790c6d4d8a37a9386ce025fd0ec1096' THEN RAISE EXCEPTION 'Migration 206: Tabelle ally_person_rollen nicht wie gebaut'; END IF;
  IF (SELECT md5(string_agg(p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')|' || pg_get_function_result(p.oid) || '|' || md5(p.prosrc), E'\n' ORDER BY p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')' COLLATE "C")) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname::text = 'public' COLLATE "C" AND p.proname::text COLLATE "C" = ANY (ARRAY['ally_recht_roh', 'ally_person_rechte_basis', 'ally_rollen_ui', 'ally_rolle_ui_aktion', 'ally_ui_rahmen', 'ally_person_anlegen_abschliessen', 'ally_person_rolle_anwenden', 'ally_person_rolle_abgleichen', 'ally_rolle_papierkorb', 'ally_testdaten_entfernen', 'ally_sicherung_kunde_inhalt', 'ally_person_rollen_liste', 'ally_person_rollen_setzen', 'ally_rollen_person_ui_aktion'])) IS DISTINCT FROM 'd345929df378e0dd6b6cc5ea23fe8399' THEN RAISE EXCEPTION 'Migration 206: Funktionen nicht wie gebaut'; END IF;
  IF (SELECT md5(coalesce(string_agg(z, E'\n' ORDER BY z COLLATE "C"), '')) FROM (SELECT r.schluessel || '|' || r.name || '|' || r.art || '|' || coalesce(r.vorlage, '') || '|' || coalesce(r.standard::text, '') || '|' || coalesce((SELECT string_agg(rr.recht || ':' || coalesce(rr.reichweite, '-'), ',' ORDER BY rr.recht COLLATE "C") FROM public.ally_rollen_rechte rr WHERE rr.rolle = r.schluessel), '') AS z FROM public.ally_rollen r WHERE r.schluessel = ANY (ARRAY['anwender', 'mitarbeiter'])) x) IS DISTINCT FROM 'f1979472b30d925dcd50a89f360b99f4' THEN RAISE EXCEPTION 'Migration 206: Vorlagen Anwender und Mitarbeiter nicht wie gebaut'; END IF;
END $m$;
