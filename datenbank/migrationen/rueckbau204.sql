-- Rückbau 204 (Fehler Nr. 47): Funktionen wörtlich wie vorher (werkzeuge/m204/vorher/), die vier neuen Funktionen und die Spalten empfang_* von
-- postfach_plaetze entfernen. Vorher ALLY 9, ALLY 23, MAIL 6, SYS 9, TALENTS Mail-Entwürfe und die Web-App auf den Stand vor 204 zurücksetzen.
-- Keine Daten gehen verloren: Zeilen mit einem Wert in empfang_* kommen vorher in die Sicherungstabelle postfach_plaetze_rb204 (platz, empfang_workflow_id, empfang_*).
-- Nur auf dem Stand von 204. Läuft als Ganzes in der Transaktion des Aufrufs (psql -1).
DO $m$
BEGIN
  IF (SELECT md5(string_agg(p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')|' || pg_get_function_result(p.oid) || '|' || md5(p.prosrc), E'\n' ORDER BY p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')' COLLATE "C")) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname::text = 'public' COLLATE "C" AND p.proname::text COLLATE "C" = ANY (ARRAY['ally_systemnachrichten_holen', 'postfach_zugang_abschliessen', 'talent_einladung_versand_auftrag', 'webapp_meine_postfaecher_web', 'webapp_postfach_web', 'talents_briefing_mail', 'postfach_empfang_abgleich', 'postfach_empfang_einschalten_vormerken', 'postfach_empfang_einschalt_auftraege', 'postfach_empfang_web'])) IS NOT DISTINCT FROM 'ccc574e37971403fd8f05fc7667aaf9f' AND (SELECT md5(string_agg(z, E'\n' ORDER BY z COLLATE "C")) FROM (WITH t AS (SELECT c.oid, c.relname::text AS tab FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname::text = 'public' COLLATE "C" AND c.relkind::text = ANY (ARRAY['r', 'p']) AND c.relname::text = ANY (ARRAY['postfach_plaetze'])) SELECT 'S|' || t.tab || '|' || a.attname::text || '|' || format_type(a.atttypid, a.atttypmod) || '|' || CASE WHEN a.attnotnull THEN 'NN' ELSE '-' END || '|' || coalesce(pg_get_expr(d.adbin, d.adrelid), '') || '|' || a.attidentity::text || a.attgenerated::text AS z FROM t JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum > 0 AND NOT a.attisdropped LEFT JOIN pg_attrdef d ON d.adrelid = t.oid AND d.adnum = a.attnum UNION ALL SELECT 'C|' || t.tab || '|' || co.conname::text || '|' || co.contype::text || '|' || pg_get_constraintdef(co.oid) FROM t JOIN pg_constraint co ON co.conrelid = t.oid UNION ALL SELECT 'I|' || t.tab || '|' || ic.relname::text || '|' || pg_get_indexdef(i.indexrelid) FROM t JOIN pg_index i ON i.indrelid = t.oid JOIN pg_class ic ON ic.oid = i.indexrelid UNION ALL SELECT 'T|' || t.tab || '|' || tg.tgname::text || '|' || pg_get_triggerdef(tg.oid) || '|' || tg.tgenabled::text FROM t JOIN pg_trigger tg ON tg.tgrelid = t.oid AND NOT tg.tgisinternal) x) IS NOT DISTINCT FROM 'd547ffaa00d757822dc758bfe5e1684c'
    THEN RAISE EXCEPTION 'Rückbau 204: schon zurückgebaut, nichts geändert'; END IF;
  IF (SELECT md5(string_agg(p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')|' || pg_get_function_result(p.oid) || '|' || md5(p.prosrc), E'\n' ORDER BY p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')' COLLATE "C")) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname::text = 'public' COLLATE "C" AND p.proname::text COLLATE "C" = ANY (ARRAY['ally_systemnachrichten_holen', 'postfach_zugang_abschliessen', 'talent_einladung_versand_auftrag', 'webapp_meine_postfaecher_web', 'webapp_postfach_web', 'talents_briefing_mail', 'postfach_empfang_abgleich', 'postfach_empfang_einschalten_vormerken', 'postfach_empfang_einschalt_auftraege', 'postfach_empfang_web'])) IS DISTINCT FROM '353d503f7d8d3468ef0d5e22063f1361' OR (SELECT md5(string_agg(z, E'\n' ORDER BY z COLLATE "C")) FROM (WITH t AS (SELECT c.oid, c.relname::text AS tab FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname::text = 'public' COLLATE "C" AND c.relkind::text = ANY (ARRAY['r', 'p']) AND c.relname::text = ANY (ARRAY['postfach_plaetze'])) SELECT 'S|' || t.tab || '|' || a.attname::text || '|' || format_type(a.atttypid, a.atttypmod) || '|' || CASE WHEN a.attnotnull THEN 'NN' ELSE '-' END || '|' || coalesce(pg_get_expr(d.adbin, d.adrelid), '') || '|' || a.attidentity::text || a.attgenerated::text AS z FROM t JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum > 0 AND NOT a.attisdropped LEFT JOIN pg_attrdef d ON d.adrelid = t.oid AND d.adnum = a.attnum UNION ALL SELECT 'C|' || t.tab || '|' || co.conname::text || '|' || co.contype::text || '|' || pg_get_constraintdef(co.oid) FROM t JOIN pg_constraint co ON co.conrelid = t.oid UNION ALL SELECT 'I|' || t.tab || '|' || ic.relname::text || '|' || pg_get_indexdef(i.indexrelid) FROM t JOIN pg_index i ON i.indrelid = t.oid JOIN pg_class ic ON ic.oid = i.indexrelid UNION ALL SELECT 'T|' || t.tab || '|' || tg.tgname::text || '|' || pg_get_triggerdef(tg.oid) || '|' || tg.tgenabled::text FROM t JOIN pg_trigger tg ON tg.tgrelid = t.oid AND NOT tg.tgisinternal) x) IS DISTINCT FROM 'b0014968ba617193f2533bf5e9f277b0' THEN RAISE EXCEPTION 'Rückbau 204: nicht im Stand von 204, nichts geändert'; END IF;
  IF (SELECT count(*) FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname::text = 'public' COLLATE "C" AND c.relname::text COLLATE "C" = 'postfach_plaetze_rb204') <> 0 THEN RAISE EXCEPTION 'Rückbau 204: Sicherungstabelle postfach_plaetze_rb204 schon vorhanden, nichts geändert'; END IF;
  PERFORM set_config('m204.inhalt', (SELECT coalesce(md5(string_agg(to_jsonb(x)::text, E'\n' ORDER BY to_jsonb(x)::text COLLATE "C")), '-') FROM (SELECT platz, empfang_workflow_id, empfang_aktiv, empfang_grund, empfang_stand, empfang_einschalten FROM public.postfach_plaetze WHERE empfang_aktiv IS NOT NULL OR empfang_grund IS NOT NULL OR empfang_stand IS NOT NULL OR empfang_einschalten IS NOT NULL) x), true);
END $m$;
CREATE TABLE public.postfach_plaetze_rb204 AS SELECT platz, empfang_workflow_id, empfang_aktiv, empfang_grund, empfang_stand, empfang_einschalten FROM public.postfach_plaetze WHERE empfang_aktiv IS NOT NULL OR empfang_grund IS NOT NULL OR empfang_stand IS NOT NULL OR empfang_einschalten IS NOT NULL;
DO $m$
BEGIN
  IF current_setting('m204.inhalt') IS DISTINCT FROM (SELECT coalesce(md5(string_agg(to_jsonb(x)::text, E'\n' ORDER BY to_jsonb(x)::text COLLATE "C")), '-') FROM (SELECT * FROM public.postfach_plaetze_rb204) x) THEN RAISE EXCEPTION 'Rückbau 204: Sicherung der Daten unvollständig, nichts geändert'; END IF;
END $m$;
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
CREATE OR REPLACE FUNCTION public.postfach_zugang_abschliessen(p_token text, p_aktion text, p_platz integer, p_daten jsonb, p_vorher jsonb, p_api jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
  d jsonb := coalesce(p_daten, '{}'::jsonb);
  v jsonb := coalesce(p_vorher, '{}'::jsonb);
  a jsonb := coalesce(p_api, '{}'::jsonb);
  an jsonb := coalesce(p_api->'anlegen', '{}'::jsonb);  -- Migration 173 (Schritt P, P3): Ergebnis des Anlegens in n8n
  grund text;  -- Nachprüfung M173 M1
  u text;
  pl postfach_plaetze;
  adr text := v->>'adresse';
  lp text;
  v_schalter text;
  ok boolean := (a->>'test_status') = 'OK';
  meldung text := left(coalesce(a->>'test_meldung', ''), 300);
  ein text := '';
  txt text;
  art text := 'ok';
  -- Migration 88 (Stefan 22.10.2026, 16:55): Ergebnis je Postfach „Lesen ok / Versand ok“ (Versand mit derselben Eingabe, ALLY 9)
  vok boolean := coalesce(a->>'versand_patch_status', '') = '200' AND coalesce(a->>'versand_test_status', '') = 'OK';
  vm text := left(btrim(regexp_replace(coalesce(nullif(a->>'versand_patch_meldung', ''), nullif(a->>'versand_test_meldung', ''), ''), '\s+', ' ', 'g')), 250);
  vs text;
  v_erl boolean;
  lesen text;
BEGIN
  -- Migration 90: Rechte je Postfach (persönlich: nur die Person, der es gehört; Entfernen auch Admins; gemeinsam: „Gemeinsame Postfächer verwalten“)
  u := (SELECT x.matrix_user_id FROM ally_web_sitzung_pruefen(p_token) x WHERE NOT x.muss_pw_setzen);
  IF u IS NULL THEN RETURN jsonb_build_object('ok', false, 'angemeldet', false); END IF;
  SELECT * INTO pl FROM postfach_plaetze WHERE platz = p_platz;
  IF (v->>'ok') IS DISTINCT FROM 'true' OR postfach_zugang_recht_fehler(u, p_aktion, pl.adresse, coalesce(v->>'art', 'gemeinsam'), adr) IS NOT NULL THEN
    PERFORM ally_web_meldung(p_token, coalesce(postfach_zugang_recht_fehler(u, p_aktion, pl.adresse, coalesce(v->>'art', 'gemeinsam'), adr), 'Die Anfrage wurde abgelehnt. Bitte die Seite neu laden.'), 'fehler', NULL);
    RETURN jsonb_build_object('ok', false, 'angemeldet', true);
  END IF;
  IF (v->>'live')::boolean THEN
    ein := CASE
      WHEN a->>'schalt_status' = 'ein' THEN ' Der Empfang ist eingeschaltet.'
      WHEN a->>'schalt_status' = 'aus' THEN ' Der Empfang für dieses Postfach ist ausgeschaltet.'
      WHEN a->>'schalt_status' = 'fehler' THEN ' Der Empfang konnte nicht umgeschaltet werden: ' || left(coalesce(a->>'schalt_meldung', ''), 200)
      ELSE '' END;
  ELSE
    ein := ' Der Empfang wird bei der Umstellung auf die Postfach-Plätze eingeschaltet.';
  END IF;

  -- Migration 173 (Schritt P, P3): neues Postfach mit eigenem Workflow (v.anlegen). ALLY 9 hat Zugangsdaten und Workflow angelegt (api.anlegen).
  -- Fehlt ein Teil, hat ALLY 9 die übrigen wieder gelöscht; was dabei übrig blieb, steht als unvollstaendig in der Liste (MAIL 5 räumt nach).
  IF p_aktion = 'zugang_speichern' AND (v->>'anlegen')::boolean IS TRUE THEN
    -- Nur die reservierte Nummer dieser Anfrage (Kennung aus vorbereiten), unter Sperre. Nachprüfung M173 M1: zuerst alle in n8n angelegten Teile an der
    -- Nummer festhalten (postfach_reservierung_teile; hat MAIL 5 die Reservierung nach über einer Stunde schon aufgeräumt, entsteht sie als unvollstaendig).
    -- Danach scheitert abschliessen nicht mehr: ist das Anlegen nicht fertig, zu spät oder die Adresse inzwischen vergeben, bleiben die Teile mit ihren IDs als
    -- unvollstaendig stehen (MAIL 5 räumt nach); jeder andere Fehler endet genauso (Ausnahmeblock am Ende).
    IF (v->>'platz') IS DISTINCT FROM p_platz::text OR coalesce(v->>'anfrage', '') = '' THEN
      PERFORM ally_web_meldung(p_token, 'Die Anfrage wurde abgelehnt. Bitte die Seite neu laden.', 'fehler', NULL);
      RETURN jsonb_build_object('ok', false, 'angemeldet', true, 'abgelehnt', true);
    END IF;
    PERFORM postfach_reservierung_teile(p_platz, v->>'anfrage', an);
    SELECT * INTO pl FROM postfach_plaetze WHERE platz = p_platz FOR UPDATE;
    IF NOT FOUND OR pl.weg IS DISTINCT FROM 'eigen' OR pl.adresse IS NOT NULL
       OR NOT (pl.anfrage IS NOT DISTINCT FROM v->>'anfrage' OR (pl.anfrage IS NULL AND pl.stand = 'unvollstaendig')) THEN
      PERFORM ally_web_meldung(p_token, 'Die Anfrage wurde abgelehnt. Bitte die Seite neu laden.', 'fehler', NULL);
      RETURN jsonb_build_object('ok', false, 'angemeldet', true, 'abgelehnt', true);
    END IF;
    grund := CASE WHEN pl.stand IS DISTINCT FROM 'reserviert' THEN 'Die Anfrage hat zu lange gedauert. Bitte erneut versuchen.'
      WHEN coalesce(an->>'fertig', '') <> 'ja' THEN left(coalesce(nullif(an->>'meldung', ''), 'unbekannter Fehler'), 200)
      WHEN pl.credential_id IS NULL OR pl.empfang_workflow_id IS NULL THEN 'unbekannter Fehler'
      WHEN EXISTS (SELECT 1 FROM postfach_plaetze q WHERE lower(q.adresse) = lower(adr) AND q.platz <> p_platz)
        OR EXISTS (SELECT 1 FROM ally_postfaecher x WHERE x.schalter = postfach_schalter(adr) AND x.adresse <> adr) THEN 'Dieses Postfach ist inzwischen schon eingerichtet.'
    END;
    IF grund IS NOT NULL THEN
      UPDATE postfach_plaetze SET stand = 'unvollstaendig', geaendert_am = now(),
        credential_id = CASE WHEN coalesce(an->>'imap_weg', '') = 'ja' THEN NULL ELSE credential_id END,
        smtp_credential_id = CASE WHEN coalesce(an->>'smtp_weg', '') = 'ja' THEN NULL ELSE smtp_credential_id END,
        empfang_workflow_id = CASE WHEN coalesce(an->>'wf_weg', '') = 'ja' THEN NULL ELSE empfang_workflow_id END,
        anfrage = NULL, anfrage_am = NULL, anfrage_adresse = NULL
      WHERE platz = p_platz;
      DELETE FROM postfach_plaetze WHERE platz = p_platz AND credential_id IS NULL AND smtp_credential_id IS NULL AND empfang_workflow_id IS NULL;
      PERFORM ally_web_meldung(p_token, 'Das Postfach konnte nicht angelegt werden: ' || grund
        || CASE WHEN FOUND THEN '' ELSE CASE WHEN grund ~ '[.!?]$' THEN '' ELSE '.' END || ' Die schon angelegten Teile entfernt ' || produkt_name() || ' automatisch.' END, 'fehler', NULL);
      RETURN jsonb_build_object('ok', false, 'angemeldet', true, 'abgelehnt', pl.stand IS DISTINCT FROM 'reserviert');
    END IF;
    UPDATE postfach_plaetze SET stand = 'aktiv', reserviert_am = NULL, anfrage = NULL, anfrage_am = NULL, anfrage_adresse = NULL, geaendert_am = now() WHERE platz = p_platz;
    SELECT * INTO pl FROM postfach_plaetze WHERE platz = p_platz;
  END IF;

  -- Migration 170 (Schritt P): Prüfung M170 S1 und Nachprüfung M1. Unter Sperre (Vertrag, dann Platz) neu lesen: Gehört der Platz nicht mehr
  -- zu dieser Anfrage (Kennung aus vorbereiten) oder ist er inzwischen belegt, mit eigener Meldung ablehnen, ohne zurueck: ALLY 9 fasst nichts an.
  -- Ist die Höchstzahl erreicht (zwei gleichzeitige „Postfach hinzufügen“ auf verschiedenen Plätzen), nichts ändern und zurueck mit der Kennung:
  -- ALLY 9 setzt den Zugang dieses Platzes zurück, postfach_zugang_zurueck gibt den Platz danach frei. Sonst wird die Kennung hier gelöscht.
  IF p_aktion = 'zugang_speichern' AND (v->>'neu')::boolean IS TRUE AND (v->>'anlegen')::boolean IS NOT TRUE THEN  -- Migration 173 (Schritt P, P3): eigene Nummer ist schon reserviert
    PERFORM 1 FROM plattform_vertrag WHERE id = 1 FOR UPDATE;
    SELECT * INTO pl FROM postfach_plaetze WHERE platz = p_platz FOR UPDATE;
    IF pl.adresse IS NOT NULL OR pl.anfrage IS NULL OR pl.anfrage IS DISTINCT FROM v->>'anfrage' THEN
      PERFORM ally_web_meldung(p_token, 'Das Postfach gehört inzwischen zu einer anderen Anfrage. Bitte die Seite neu laden und den Zugang des Postfachs Nr. ' || p_platz || ' prüfen.', 'fehler', NULL);
      RETURN jsonb_build_object('ok', false, 'angemeldet', true, 'abgelehnt', true);
    END IF;
    IF postfach_hoechstzahl_erreicht() THEN
      UPDATE postfach_plaetze SET anfrage_am = now() WHERE platz = p_platz;
      PERFORM ally_web_meldung(p_token, 'Die Höchstzahl an Postfächern ist erreicht. Für ein neues Postfach muss ein anderes entfernt werden.', 'fehler', NULL);
      RETURN jsonb_build_object('ok', false, 'angemeldet', true, 'zurueck', true, 'anfrage', pl.anfrage);
    END IF;
    UPDATE postfach_plaetze SET anfrage = NULL, anfrage_am = NULL WHERE platz = p_platz;
  END IF;

  IF p_aktion = 'zugang_speichern' THEN
    IF coalesce(a->>'patch_status', '') <> '200' THEN
      txt := 'Die Zugangsdaten konnten nicht gespeichert werden: ' || left(coalesce(a->>'patch_meldung', 'unbekannter Fehler'), 200); art := 'fehler';
    ELSE
      IF (v->>'neu')::boolean THEN
        v_schalter := postfach_schalter(adr);
        -- Migration 90: Art und Person (persönlich); ein früher eingebundenes Postfach kommt nur auf dieselbe Art zurück (postfach_zugang_recht_fehler)
        INSERT INTO ally_postfaecher (adresse, name, aktiv, schalter, entwurf_ordner, sortierung, art, eigentuemer)
        VALUES (adr, coalesce(nullif(trim(d->>'name'), ''), adr), true, v_schalter, 'Entwürfe', 10 * p_platz,
                CASE WHEN v->>'art' = 'persoenlich' THEN 'persoenlich' ELSE 'gemeinsam' END, CASE WHEN v->>'art' = 'persoenlich' THEN u END)
        ON CONFLICT (adresse) DO UPDATE SET aktiv = true, geaendert_am = now();
        INSERT INTO ally_funktionen (schluessel, name, beschreibung, aktiv, modul, sortierung)
        VALUES (v_schalter, 'Entwürfe für ' || adr, 'Fragt bei Mails der Kundschaft und konkreten Anfragen an ' || adr || ', ob ' || produkt_name() || ' einen Antwortentwurf vorbereiten soll.', false, 'mail_entwuerfe', 29 + p_platz)
        ON CONFLICT (schluessel) DO NOTHING;
        -- Migration 88: neues Postfach – Versand aus, bis er einmal erfolgreich geprüft wurde (alte Versand-Angaben des Platzes nie übernehmen)
        UPDATE postfach_plaetze SET adresse = adr, belege_erfassen = true, smtp_host = NULL, smtp_port = NULL, smtp_benutzer = NULL, versand_eingerichtet = false,
          versand_geprueft_am = NULL, versand_pruef_ergebnis = NULL, versand_erlaubt = NULL WHERE platz = p_platz;
        -- Migration 173 (Schritt P, P3): Recht „gemeinsames Postfach Nr. n sehen“ (Schlüssel als Zahlwort) für ein neues gemeinsames Postfach mit eigener Nummer
        IF pl.weg = 'eigen' AND v->>'art' IS DISTINCT FROM 'persoenlich' THEN
          INSERT INTO ally_rechte (schluessel, name, beschreibung, sortierung, modul, katalog_gruppe, katalog_name, katalog_text, katalog_sortierung, reichweite, je_person, nur_selbst)
          VALUES (ally_postfach_recht(p_platz), 'Gemeinsames Postfach Nr. ' || p_platz, 'Das gemeinsame Postfach Nr. ' || p_platz || ' sehen (Mails, Entwürfe, Hinweise, Briefing).',
                  22, NULL, 'Gemeinsame Postfächer', 'Nr. ' || p_platz, '', 230 + p_platz, false, true, false)
          ON CONFLICT (schluessel) DO NOTHING;
        END IF;
      END IF;
      UPDATE postfach_plaetze SET imap_host = v->>'host', imap_port = (v->>'port')::int, imap_benutzer = v->>'benutzer', imap_ssl = (v->>'ssl')::boolean,
        letzte_pruefung = now(), pruef_ergebnis = CASE WHEN ok THEN 'ok' ELSE nullif(meldung, '') END, eingerichtet = ok, geaendert_am = now()
      WHERE platz = p_platz;
      IF (v->>'smtp')::boolean IS TRUE AND coalesce(a->>'versand_patch_status', '') = '200' THEN
        UPDATE postfach_plaetze SET smtp_host = lower(left(v->>'smtp_host', 253)), smtp_port = CASE WHEN v->>'smtp_port' IN ('465', '587') THEN (v->>'smtp_port')::integer END,
          smtp_benutzer = left(v->>'smtp_benutzer', 200), versand_eingerichtet = vok, versand_geprueft_am = now(),
          versand_pruef_ergebnis = CASE WHEN vok THEN 'ok' ELSE coalesce(nullif(vm, ''), 'keine Antwort') END,
          versand_erlaubt = CASE WHEN vok THEN coalesce(versand_erlaubt, true) ELSE versand_erlaubt END
        WHERE platz = p_platz RETURNING versand_erlaubt INTO v_erl;
        vs := CASE WHEN vok THEN 'Versand ok' ELSE 'Versand fehlgeschlagen (' || coalesce(nullif(vm, ''), 'keine Antwort') || ')' END;
      ELSIF (v->>'smtp')::boolean IS TRUE THEN
        vs := 'Versand nicht gespeichert (' || coalesce(nullif(vm, ''), 'keine Antwort') || ')'; vok := false;
      ELSE
        vs := 'Versand für dieses Postfach nicht verfügbar'; vok := NULL;
      END IF;
      lesen := CASE WHEN ok THEN 'Lesen ok' ELSE 'Lesen fehlgeschlagen (' || coalesce(nullif(meldung, ''), 'keine Antwort') || ')' END;
      txt := 'Zugang für ' || adr || ' gespeichert und geprüft: ' || lesen || ' / ' || vs || '.'
        || CASE WHEN NOT ok THEN ' Bitte Server, Port, Anmeldename und Passwort prüfen.' ELSE '' END
        || CASE WHEN vok IS FALSE THEN ' Braucht der Versand andere Daten, bitte unter „Andere Daten für den Versand“ eintragen.' ELSE '' END
        || CASE WHEN vok AND v_erl IS FALSE THEN ' Der Versand bleibt ausgeschaltet, bis du „Versand erlauben“ einschaltest.' ELSE '' END
        || ein;
      IF NOT ok OR vok IS FALSE THEN art := 'fehler'; END IF;
    END IF;

  ELSIF p_aktion = 'zugang_pruefen' THEN
    UPDATE postfach_plaetze SET letzte_pruefung = now(), pruef_ergebnis = CASE WHEN ok THEN 'ok' ELSE nullif(meldung, '') END, eingerichtet = ok, geaendert_am = now()
    WHERE platz = p_platz;
    IF (v->>'smtp_pruefen')::boolean IS TRUE THEN
      vok := coalesce(a->>'versand_test_status', '') = 'OK';  -- beim Prüfen wird nichts gesetzt, nur geprüft
      UPDATE postfach_plaetze SET versand_eingerichtet = vok AND smtp_host IS NOT NULL, versand_geprueft_am = now(),
        versand_pruef_ergebnis = CASE WHEN vok THEN 'ok' ELSE coalesce(nullif(vm, ''), 'keine Antwort') END,
        versand_erlaubt = CASE WHEN vok THEN coalesce(versand_erlaubt, true) ELSE versand_erlaubt END
      WHERE platz = p_platz;
      vs := CASE WHEN vok THEN 'Versand ok' ELSE 'Versand fehlgeschlagen (' || coalesce(nullif(vm, ''), 'keine Antwort') || ')' END;
    ELSE
      vs := 'Versand noch nicht eingerichtet („Zugang erneut bestätigen“)'; vok := NULL;
    END IF;
    lesen := CASE WHEN ok THEN 'Lesen ok' ELSE 'Lesen fehlgeschlagen (' || coalesce(nullif(meldung, ''), 'keine Antwort') || ')' END;
    txt := 'Zugang für ' || pl.adresse || ' geprüft: ' || lesen || ' / ' || vs || '.';
    IF NOT ok OR vok IS FALSE THEN art := 'fehler'; END IF;

  ELSIF p_aktion = 'platz_freigeben' THEN
    IF coalesce(a->>'schalt_status', '') = 'fehler' OR coalesce(a->>'patch_status', '') <> '200' THEN
      txt := 'Das Postfach konnte nicht entfernt werden: ' || left(coalesce(a->>'schalt_meldung', a->>'patch_meldung', 'unbekannter Fehler'), 200); art := 'fehler';
    ELSE
      UPDATE ally_postfaecher SET aktiv = false, geaendert_am = now() WHERE adresse = pl.adresse;
      -- Migration 90: Häkchen „gemeinsames Postfach auf diesem Platz sehen“ entfernen, damit ein späteres Postfach auf dem Platz niemandem ungefragt sichtbar wird
      IF (SELECT x.art FROM ally_postfaecher x WHERE x.adresse = pl.adresse) = 'gemeinsam' THEN
        DELETE FROM ally_rollen_rechte WHERE recht = ally_postfach_recht(p_platz);
        DELETE FROM ally_nutzer_rechte WHERE recht = ally_postfach_recht(p_platz);
        -- Migration 167 (Bauplan B6): Prüfung M2, auch eigene Rechte (plus und minus) auf den Platz
        DELETE FROM ally_person_rechte WHERE recht = ally_postfach_recht(p_platz);
      END IF;
      UPDATE postfach_plaetze SET adresse = NULL, eingerichtet = false, belege_erfassen = true, imap_host = NULL, imap_port = NULL, imap_benutzer = NULL, imap_ssl = NULL,
        letzte_pruefung = NULL, pruef_ergebnis = NULL, geaendert_am = now(),
        -- Migration 88: Versand des Platzes zurücksetzen (ein späteres Postfach auf dem Platz sendet nie mit alten Angaben)
        smtp_host = NULL, smtp_port = NULL, smtp_benutzer = NULL, versand_eingerichtet = false, versand_geprueft_am = NULL, versand_pruef_ergebnis = NULL, versand_erlaubt = NULL
      WHERE platz = p_platz;
      -- Migration 173 (Schritt P, P3): eigenes Postfach: Recht im Katalog weg; ALLY 9 hat Workflow und Zugangsdaten gelöscht (api.loeschen). Ist alles weg, verschwindet die
      -- Zeile, sonst bleibt sie als unvollstaendig mit den übrigen IDs (MAIL 5 räumt nach).
      IF pl.weg = 'eigen' THEN
        DELETE FROM ally_rechte WHERE schluessel = ally_postfach_recht(p_platz);
        UPDATE postfach_plaetze SET stand = 'unvollstaendig',
          empfang_workflow_id = CASE WHEN coalesce(a->'loeschen'->>'wf_status', '') IN ('200', '404') THEN NULL ELSE empfang_workflow_id END,
          credential_id = CASE WHEN coalesce(a->'loeschen'->>'imap_status', '') IN ('200', '404') THEN NULL ELSE credential_id END,
          smtp_credential_id = CASE WHEN smtp_credential_id IS NULL OR coalesce(a->'loeschen'->>'smtp_status', '') IN ('200', '404') THEN NULL ELSE smtp_credential_id END
        WHERE platz = p_platz;
        DELETE FROM postfach_plaetze WHERE platz = p_platz AND empfang_workflow_id IS NULL AND credential_id IS NULL AND smtp_credential_id IS NULL;
      END IF;
      txt := 'Postfach ' || pl.adresse || ' entfernt. Es ist jetzt pausiert, Einstellungen und Verlauf bleiben gespeichert.';
      -- Nachprüfung M173 H2: ALLY 9 löscht nur einen Workflow namens „MAIL Postfach Nr. n“; sonst bleibt er unangetastet und als unvollstaendig vermerkt
      IF pl.weg = 'eigen' AND a->'loeschen'->>'wf_status' = 'name falsch' THEN
        txt := txt || ' Der Workflow wurde nicht ausgeschaltet und nicht gelöscht, weil er nicht „MAIL Postfach Nr. ' || p_platz || '“ heißt. '
          || 'Er ist als unvollständig vermerkt, bitte in n8n prüfen.'; art := 'fehler';
      END IF;
    END IF;
  ELSE
    txt := 'Unbekannte Aktion.'; art := 'fehler';
  END IF;

  PERFORM ally_web_meldung(p_token, txt, art, NULL);
  RETURN jsonb_build_object('ok', art = 'ok', 'angemeldet', true);
EXCEPTION WHEN OTHERS THEN
  -- Migration 173 (Schritt P, P3): Nachprüfung M173 M1. Ein neues Postfach endet nach dem Anlegen in n8n nie mit einem Fehler: alles oben ist zurückgenommen, die angelegten
  -- Teile bleiben mit ihren IDs als unvollstaendig stehen (MAIL 5 räumt nach), die Meldung sagt es. Alle anderen Fälle wie bisher (Fehler weitergeben).
  IF p_aktion = 'zugang_speichern' AND v->>'anlegen' = 'true' AND v->>'platz' = p_platz::text AND coalesce(v->>'anfrage', '') <> '' THEN
    PERFORM postfach_reservierung_teile(p_platz, v->>'anfrage', an);
    UPDATE postfach_plaetze SET stand = 'unvollstaendig', anfrage = NULL, anfrage_am = NULL, anfrage_adresse = NULL, geaendert_am = now()
    WHERE platz = p_platz AND weg = 'eigen' AND adresse IS NULL AND (anfrage = v->>'anfrage' OR (anfrage IS NULL AND stand = 'unvollstaendig'));
    DELETE FROM postfach_plaetze WHERE platz = p_platz AND weg = 'eigen' AND adresse IS NULL AND stand = 'unvollstaendig'
      AND credential_id IS NULL AND smtp_credential_id IS NULL AND empfang_workflow_id IS NULL;
    PERFORM ally_web_meldung(p_token, 'Das Postfach konnte nicht angelegt werden (unerwarteter Fehler). Bitte erneut versuchen.'
      || CASE WHEN EXISTS (SELECT 1 FROM postfach_plaetze WHERE platz = p_platz AND stand = 'unvollstaendig') THEN ' Die schon angelegten Teile entfernt ' || produkt_name() || ' automatisch.' ELSE '' END, 'fehler', NULL);
    RETURN jsonb_build_object('ok', false, 'angemeldet', true);
  END IF;
  RAISE;
END $function$;
CREATE OR REPLACE FUNCTION public.talent_einladung_versand_auftrag(p_id integer)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
  m talent_mail_entwuerfe%ROWTYPE; g text; v_an text; ml jsonb; pl postfach_plaetze%ROWTYPE;
BEGIN
  -- Migration 192: eine vorgemerkte Einladung (talent_mail_entwuerfe, versand senden) für TALENTS Mail-Entwürfe übernehmen. Alles wird erneut geprüft (Person, Recht,
  -- Talent, Link, Postfach, Empfänger); erst hier entsteht die Mail mit Link (nicht gespeichert). Passt etwas nicht: „verfallen“ mit Grund und Benachrichtigung.
  -- Ergebnis: Liste mit einem Auftrag (laeuft) oder leer. Platz und Workflow nur aus postfach_plaetze.
  SELECT * INTO m FROM talent_mail_entwuerfe x WHERE x.id = p_id AND x.versand = 'senden' AND x.status = 'offen';
  IF m.id IS NULL THEN RETURN '[]'::jsonb; END IF;
  g := talent_einladung_versandfehler(m.einladung_id, m.talent_id, m.erstellt_von);
  IF g IS NULL THEN g := talent_postfach_sendefehler(m.erstellt_von, m.postfach); END IF;
  IF g IS NULL THEN
    v_an := (SELECT lower(btrim(coalesce(t.email, ''))) FROM talents t WHERE t.id = m.talent_id);
    IF NOT ally_mail_gueltig(v_an) THEN g := 'Keine gültige E-Mail-Adresse hinterlegt.';
    ELSIF v_an IS DISTINCT FROM m.an THEN g := 'Die E-Mail-Adresse des Talents hat sich geändert. Bitte neu senden.'; END IF;
  END IF;
  IF g IS NULL THEN
    ml := talent_einladung_mail(m.einladung_id, 'postfach', m.erstellt_von, m.postfach, true);
    IF NOT coalesce((ml->>'ok')::boolean, false) THEN g := coalesce(ml->>'fehler', 'Die Mail konnte nicht gebaut werden.'); END IF;
  END IF;
  IF g IS NULL THEN
    SELECT * INTO pl FROM postfach_plaetze x WHERE lower(btrim(x.adresse)) = m.postfach;
    IF pl.platz IS NULL THEN g := 'Das Postfach ' || m.postfach || ' ist noch nicht vollständig eingerichtet.'; END IF;
  END IF;
  IF g IS NOT NULL THEN
    UPDATE talent_mail_entwuerfe SET status = 'verfallen', fehler = left(g, 300) WHERE id = m.id;
    PERFORM talent_einladung_fehler_melden('postfach', m.id);
    RETURN '[]'::jsonb;
  END IF;
  UPDATE talent_mail_entwuerfe SET status = 'laeuft', versuche = versuche + 1, gestartet_am = now() WHERE id = m.id;
  RETURN jsonb_build_array(jsonb_build_object('id', m.id, 'versand', 'senden', 'postfach', m.postfach, 'an', v_an, 'nr', pl.platz, 'workflow_id', pl.empfang_workflow_id,
    'von', m.postfach, 'von_name', ml->>'von_name', 'betreff', ml->>'betreff', 'text', ml->>'text', 'html', ml->>'html'));
END $function$;
CREATE OR REPLACE FUNCTION public.webapp_meine_postfaecher_web(p_token text)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
  s record; w jsonb; pfe boolean; pv jsonb; li jsonb;
BEGIN
  SELECT * INTO s FROM ally_ui_sitzung(p_token) y WHERE NOT y.muss_pw_setzen;
  IF NOT FOUND OR s.person IS NULL THEN RETURN jsonb_build_object('ok', false); END IF;
  pfe := coalesce(ally_hat_recht(s.person, 'postfaecher_eigene'), false);
  w := coalesce(ally_web_daten(s.person), '{}'::jsonb);
  pv := coalesce(postfach_versand_web(p_token)->'plaetze', '[]'::jsonb);
  SELECT coalesce(jsonb_agg(jsonb_build_object('platz', p->'platz', 'adresse', p->'adresse', 'name', p->'name', 'aktiv', p->'aktiv',
      'lesen', p->'zugang'->'ergebnis', 'geprueft', p->'zugang'->'geprueft',
      'versand', (SELECT jsonb_build_object('bereit', v->'bereit', 'eingerichtet', v->'eingerichtet', 'erlaubt', v->'erlaubt', 'host', v->'host')
                  FROM jsonb_array_elements(pv) v WHERE lower(v->>'adresse') = lower(p->>'adresse') LIMIT 1))
      ORDER BY lower(p->>'adresse')), '[]'::jsonb)
    INTO li FROM jsonb_array_elements(coalesce(w->'postfaecher', '[]'::jsonb)) p
   WHERE p->>'art' = 'persoenlich' AND coalesce((p->>'eigen')::boolean, false) AND (p->>'platz') ~ '^[0-9]{1,9}$';  -- Migration 173 (Schritt P, P3): Nummer ohne Grenze
  RETURN jsonb_build_object('ok', true, 'recht', pfe, 'live', coalesce((w->>'plaetze_live')::boolean, false),
    'frei', CASE WHEN pfe THEN coalesce(w->'plaetze_frei', '[]'::jsonb) END, 'liste', li,
    -- Migration 170 (Schritt P): Kennzeichen Höchstzahl erreicht
    'hoechstzahl_erreicht', CASE WHEN pfe THEN w->'postfaecher_hoechstzahl_erreicht' END);
END $function$;
CREATE OR REPLACE FUNCTION public.webapp_postfach_web(p_token text, p_adresse text)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
  s record; w jsonb; p jsonb; v jsonb; adm boolean; pfr boolean; rs jsonb; pl int;
BEGIN
  SELECT * INTO s FROM ally_ui_sitzung(p_token) y WHERE NOT y.muss_pw_setzen;
  IF NOT FOUND OR s.person IS NULL OR coalesce(p_adresse, '') = '' THEN RETURN jsonb_build_object('ok', false); END IF;
  adm := coalesce(ally_hat_recht(s.person, 'admin'), false);
  pfr := coalesce(ally_hat_recht(s.person, 'postfaecher'), false);
  w := coalesce(ally_web_daten(s.person), '{}'::jsonb);
  SELECT x INTO p FROM jsonb_array_elements(coalesce(w->'postfaecher', '[]'::jsonb)) x
   WHERE lower(x->>'adresse') = lower(p_adresse) AND (x->>'platz') ~ '^[0-9]{1,9}$'
     AND ((x->>'art' = 'gemeinsam' AND coalesce((x->>'verwalten')::boolean, false)) OR (x->>'art' = 'persoenlich' AND coalesce((x->>'eigen')::boolean, false)))
   LIMIT 1;
  IF p IS NULL THEN RETURN jsonb_build_object('ok', false, 'fehlt', true); END IF;
  pl := (p->>'platz')::int;
  SELECT x INTO v FROM jsonb_array_elements(coalesce(postfach_versand_web(p_token)->'plaetze', '[]'::jsonb)) x WHERE lower(x->>'adresse') = lower(p->>'adresse') LIMIT 1;
  IF p->>'art' = 'gemeinsam' AND pfr THEN
    SELECT coalesce(jsonb_agg(ro.name ORDER BY lower(ro.name)), '[]'::jsonb) INTO rs
      FROM ally_rollen_rechte rr JOIN ally_rollen ro ON ro.schluessel = rr.rolle AND ro.art = 'eigen' AND ro.archiviert_am IS NULL
     WHERE rr.recht = ally_postfach_recht(pl);
  END IF;
  RETURN jsonb_build_object('ok', true, 'admin', adm, 'live', coalesce((w->>'plaetze_live')::boolean, false),
    'postfach', jsonb_build_object('platz', pl, 'art', p->'art', 'adresse', p->'adresse', 'name', p->'name', 'aktiv', p->'aktiv', 'belege_erfassen', p->'belege_erfassen',
      'unternehmen_id', p->'unternehmen_id', 'schrift', p->'schrift', 'schrift_groesse', p->'schrift_groesse', 'signatur_html', p->'signatur_html',
      'entwurf_ordner', p->'entwurf_ordner', 'angebot_bei', p->'angebot_bei', 'eigene_einordnung', p->'eigene_einordnung', 'einordnung', p->'einordnung',
      'personen', jsonb_array_length(coalesce(p->'personen', '[]'::jsonb)),
      'zugang', jsonb_build_object('host', p->'zugang'->'host', 'port', p->'zugang'->'port', 'benutzer', p->'zugang'->'benutzer', 'ssl', p->'zugang'->'ssl',
        'ordner', p->'zugang'->'ordner', 'ergebnis', p->'zugang'->'ergebnis', 'geprueft', p->'zugang'->'geprueft')),
    'versand', CASE WHEN v IS NULL THEN NULL ELSE jsonb_build_object('bereit', v->'bereit', 'eingerichtet', v->'eingerichtet', 'erlaubt', v->'erlaubt', 'host', v->'host', 'port', v->'port',
      'benutzer', v->'benutzer', 'imap_benutzer', v->'imap_benutzer', 'anders', v->'anders', 'abgeleitet_host', v->'abgeleitet_host', 'ergebnis', v->'ergebnis',
      'geprueft', v->'geprueft', 'berichte', v->'berichte') END,
    'unternehmen', (SELECT coalesce(jsonb_agg(jsonb_build_object('id', u->'id', 'name', u->'name')), '[]'::jsonb) FROM jsonb_array_elements(coalesce(w->'unternehmen', '[]'::jsonb)) u),
    'schriften', coalesce(w->'mail_schriften', '[]'::jsonb),
    'kategorien', coalesce(w->'mail_kategorien', '{}'::jsonb),
    'rollen', rs);
END $function$;
CREATE OR REPLACE FUNCTION public.talents_briefing_mail(p_person jsonb, p_inhalt jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE b talents_briefings%ROWTYPE; a jsonb; an text; test boolean; m jsonb; wer text;
BEGIN
  -- Migration 180: Mail für eine Person aus talents_briefing_faellig (p_person) mit ihrem Briefing (p_inhalt). senden = es geht eine Mail raus; test = Testmodus
  -- (Briefing einer Test-Person oder Empfänger ist eine Test-Person, wie Testdaten bei den Verkaufsberichten): nichts versendet, nur „würde senden“.
  -- Ohne Mail für diese Person (Versand nur Chat oder keine Mail-Adresse): mail = false.
  SELECT * INTO b FROM talents_briefings x WHERE x.id = CASE WHEN coalesce(p_person->>'briefing_id', '') ~ '^[0-9]{1,9}$' THEN (p_person->>'briefing_id')::integer END;
  IF NOT FOUND OR coalesce((p_person->'versand'->>'mail')::boolean, false) IS NOT TRUE THEN RETURN jsonb_build_object('mail', false); END IF;
  an := talents_briefing_mail_adresse(p_person->>'user_id');
  IF an IS NULL THEN RETURN jsonb_build_object('mail', false); END IF;
  test := b.testdaten OR ally_person_ist_testdaten(p_person->>'user_id');
  a := talents_briefing_absender(b.id);
  IF NOT coalesce((a->>'bereit')::boolean, false) THEN
    RETURN jsonb_build_object('mail', true, 'senden', false, 'test', test, 'an', an, 'grund', a->>'fehlt');
  END IF;
  -- {Name} in der Signatur: wer „Jetzt erstellen“ ausgelöst hat, sonst wer das Briefing zuletzt gespeichert bzw. angelegt hat
  wer := coalesce(nullif(p_person->>'ausloeser', ''), b.geaendert_von, b.erstellt_von);
  m := talents_briefing_mail_bauen(b, jsonb_build_object('Titel', b.name, 'Zeitraum', coalesce(p_person->>'zeitraum_text', ''), 'Kalenderwoche', coalesce(p_person->>'kw', '')),
                                   a->>'adresse', wer, p_inhalt);
  RETURN m || jsonb_build_object('mail', true, 'senden', NOT test, 'test', test, 'an', an, 'von', a->>'adresse', 'von_name', a->>'name', 'weg', a->>'weg',
    'nr', CASE WHEN a->>'weg' = 'eigen' THEN (a->>'nr')::integer END, 'workflow_id', CASE WHEN a->>'weg' = 'eigen' THEN a->>'workflow_id' END);
END $function$;
DROP FUNCTION public.postfach_empfang_web(p_user text, p_adresse text);
DROP FUNCTION public.postfach_empfang_einschalt_auftraege(p_max integer);
DROP FUNCTION public.postfach_empfang_einschalten_vormerken(p_platz integer);
DROP FUNCTION public.postfach_empfang_abgleich(p_stand jsonb);
ALTER TABLE public.postfach_plaetze DROP CONSTRAINT postfach_plaetze_empfang_check,
  DROP COLUMN empfang_aktiv, DROP COLUMN empfang_grund, DROP COLUMN empfang_stand, DROP COLUMN empfang_einschalten;
DO $m$
BEGIN
  IF (SELECT md5(string_agg(p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')|' || pg_get_function_result(p.oid) || '|' || md5(p.prosrc), E'\n' ORDER BY p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')' COLLATE "C")) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname::text = 'public' COLLATE "C" AND p.proname::text COLLATE "C" = ANY (ARRAY['ally_systemnachrichten_holen', 'postfach_zugang_abschliessen', 'talent_einladung_versand_auftrag', 'webapp_meine_postfaecher_web', 'webapp_postfach_web', 'talents_briefing_mail', 'postfach_empfang_abgleich', 'postfach_empfang_einschalten_vormerken', 'postfach_empfang_einschalt_auftraege', 'postfach_empfang_web'])) IS DISTINCT FROM 'ccc574e37971403fd8f05fc7667aaf9f' THEN RAISE EXCEPTION 'Rückbau 204: Funktionen nicht wie vorher'; END IF;
  IF (SELECT md5(string_agg(z, E'\n' ORDER BY z COLLATE "C")) FROM (WITH t AS (SELECT c.oid, c.relname::text AS tab FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname::text = 'public' COLLATE "C" AND c.relkind::text = ANY (ARRAY['r', 'p']) AND c.relname::text = ANY (ARRAY['postfach_plaetze'])) SELECT 'S|' || t.tab || '|' || a.attname::text || '|' || format_type(a.atttypid, a.atttypmod) || '|' || CASE WHEN a.attnotnull THEN 'NN' ELSE '-' END || '|' || coalesce(pg_get_expr(d.adbin, d.adrelid), '') || '|' || a.attidentity::text || a.attgenerated::text AS z FROM t JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum > 0 AND NOT a.attisdropped LEFT JOIN pg_attrdef d ON d.adrelid = t.oid AND d.adnum = a.attnum UNION ALL SELECT 'C|' || t.tab || '|' || co.conname::text || '|' || co.contype::text || '|' || pg_get_constraintdef(co.oid) FROM t JOIN pg_constraint co ON co.conrelid = t.oid UNION ALL SELECT 'I|' || t.tab || '|' || ic.relname::text || '|' || pg_get_indexdef(i.indexrelid) FROM t JOIN pg_index i ON i.indrelid = t.oid JOIN pg_class ic ON ic.oid = i.indexrelid UNION ALL SELECT 'T|' || t.tab || '|' || tg.tgname::text || '|' || pg_get_triggerdef(tg.oid) || '|' || tg.tgenabled::text FROM t JOIN pg_trigger tg ON tg.tgrelid = t.oid AND NOT tg.tgisinternal) x) IS DISTINCT FROM 'd547ffaa00d757822dc758bfe5e1684c' THEN RAISE EXCEPTION 'Rückbau 204: Aufbau von postfach_plaetze nicht wie vorher'; END IF;
  IF (SELECT count(*) FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname::text = 'public' COLLATE "C" AND c.relname::text COLLATE "C" = 'postfach_plaetze_rb204') <> 1 THEN RAISE EXCEPTION 'Rückbau 204: Sicherungstabelle fehlt'; END IF;
END $m$;
