-- Migration 202 (Fehlerliste Installation Nr. 42, Stefan 03.11.2026 16:53: „zudem soll sie backups heißen und nicht sicherungen“):
-- Sichtbare Texte der Seite Backups heißen Backup statt Sicherung (ally_sicherung_ui_aktion, ally_sicherung_host_ende, ally_sicherung_host_plan).
-- Interne Namen bleiben. Keine Tabellen- und keine Datenänderung (Schema-Wächter vorher = nachher). Nur als Ganzes in einer Transaktion. Rückbau: rueckbau202.sql.
DO $m$
BEGIN
  IF (SELECT md5(string_agg(p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')|' || pg_get_function_result(p.oid) || '|' || md5(p.prosrc), E'\n' ORDER BY p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')' COLLATE "C")) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname::text = 'public' COLLATE "C" AND p.proname::text COLLATE "C" = ANY (ARRAY['ally_sicherung_host_ende', 'ally_sicherung_host_plan', 'ally_sicherung_ui_aktion'])) IS NOT DISTINCT FROM 'dad7c09e1689db9057959af41fe31159' AND (SELECT md5(string_agg(z, E'\n' ORDER BY z COLLATE "C")) FROM (WITH t AS (SELECT c.oid, c.relname::text AS tab FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname::text = 'public' COLLATE "C" AND c.relkind::text = ANY (ARRAY['r', 'p']) AND c.relname::text = ANY (ARRAY['ally_sicherung_laeufe', 'ally_sicherung_server', 'ally_sicherung_ziele'])) SELECT 'S|' || t.tab || '|' || a.attname::text || '|' || format_type(a.atttypid, a.atttypmod) || '|' || CASE WHEN a.attnotnull THEN 'NN' ELSE '-' END || '|' || coalesce(pg_get_expr(d.adbin, d.adrelid), '') || '|' || a.attidentity::text || a.attgenerated::text AS z FROM t JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum > 0 AND NOT a.attisdropped LEFT JOIN pg_attrdef d ON d.adrelid = t.oid AND d.adnum = a.attnum UNION ALL SELECT 'C|' || t.tab || '|' || co.conname::text || '|' || co.contype::text || '|' || pg_get_constraintdef(co.oid) FROM t JOIN pg_constraint co ON co.conrelid = t.oid UNION ALL SELECT 'I|' || t.tab || '|' || ic.relname::text || '|' || pg_get_indexdef(i.indexrelid) FROM t JOIN pg_index i ON i.indrelid = t.oid JOIN pg_class ic ON ic.oid = i.indexrelid UNION ALL SELECT 'T|' || t.tab || '|' || tg.tgname::text || '|' || pg_get_triggerdef(tg.oid) || '|' || tg.tgenabled::text FROM t JOIN pg_trigger tg ON tg.tgrelid = t.oid AND NOT tg.tgisinternal) x) IS NOT DISTINCT FROM '4d61775f5a8485822c7ff5c30815f9a1'
    THEN RAISE EXCEPTION 'Migration 202: schon eingespielt, nichts geändert'; END IF;
  IF (SELECT md5(string_agg(p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')|' || pg_get_function_result(p.oid) || '|' || md5(p.prosrc), E'\n' ORDER BY p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')' COLLATE "C")) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname::text = 'public' COLLATE "C" AND p.proname::text COLLATE "C" = ANY (ARRAY['ally_sicherung_host_ende', 'ally_sicherung_host_plan', 'ally_sicherung_ui_aktion'])) IS DISTINCT FROM 'bef837eaaed1bb416cdf1c1c21d6eb75' THEN RAISE EXCEPTION 'Migration 202: Funktionen der Seite Backups nicht im erwarteten Stand (Migration 201 fehlt?), nichts geändert'; END IF;
  IF (SELECT md5(string_agg(z, E'\n' ORDER BY z COLLATE "C")) FROM (WITH t AS (SELECT c.oid, c.relname::text AS tab FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname::text = 'public' COLLATE "C" AND c.relkind::text = ANY (ARRAY['r', 'p']) AND c.relname::text = ANY (ARRAY['ally_sicherung_laeufe', 'ally_sicherung_server', 'ally_sicherung_ziele'])) SELECT 'S|' || t.tab || '|' || a.attname::text || '|' || format_type(a.atttypid, a.atttypmod) || '|' || CASE WHEN a.attnotnull THEN 'NN' ELSE '-' END || '|' || coalesce(pg_get_expr(d.adbin, d.adrelid), '') || '|' || a.attidentity::text || a.attgenerated::text AS z FROM t JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum > 0 AND NOT a.attisdropped LEFT JOIN pg_attrdef d ON d.adrelid = t.oid AND d.adnum = a.attnum UNION ALL SELECT 'C|' || t.tab || '|' || co.conname::text || '|' || co.contype::text || '|' || pg_get_constraintdef(co.oid) FROM t JOIN pg_constraint co ON co.conrelid = t.oid UNION ALL SELECT 'I|' || t.tab || '|' || ic.relname::text || '|' || pg_get_indexdef(i.indexrelid) FROM t JOIN pg_index i ON i.indrelid = t.oid JOIN pg_class ic ON ic.oid = i.indexrelid UNION ALL SELECT 'T|' || t.tab || '|' || tg.tgname::text || '|' || pg_get_triggerdef(tg.oid) || '|' || tg.tgenabled::text FROM t JOIN pg_trigger tg ON tg.tgrelid = t.oid AND NOT tg.tgisinternal) x) IS DISTINCT FROM '4d61775f5a8485822c7ff5c30815f9a1' THEN RAISE EXCEPTION 'Migration 202: Schema der Tabellen ally_sicherung_* weicht ab, nichts geändert'; END IF;
END $m$;
CREATE OR REPLACE FUNCTION public.ally_sicherung_host_ende(p_lauf bigint, p_ergebnis text, p_groesse bigint, p_belegt bigint, p_staende integer, p_meldung text)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
-- Migration 202 (Fehler Nr. 42, Stefan 03.11.2026): Backup statt Sicherung
DECLARE
  l ally_sicherung_laeufe; p record; t text;
BEGIN
  -- Migration 201: Ergebnis eines Laufs des Sicherungsprogramms (ok, warnung = gesichert, aber einzelne Dateien nicht lesbar, fehler, nur_lokal = ohne eingetragenes Ziel nur auf dem Server gesichert). Größe der Sicherung,
  -- belegter Platz auf dem Ziel und Zahl der Stände (restic stats/snapshots), Meldung (ohne Steuerzeichen, gekürzt). Bei einem Fehler oder einer Warnung einer Sicherung (nicht einer Prüfung)
  -- eine Benachrichtigung „Systemfehler“ (ally_benachrichtigen) an die Superadmins (Anbieter-Ziel) bzw. die Admins (Kunden-Ziel). Behält je Ziel die letzten 200 Läufe.
  IF p_ergebnis IS NULL OR p_ergebnis NOT IN ('ok', 'warnung', 'fehler', 'nur_lokal') THEN RETURN 'Ergebnis ungültig'; END IF;
  UPDATE ally_sicherung_laeufe x SET ergebnis = p_ergebnis, beendet_am = now(), groesse_bytes = CASE WHEN p_groesse >= 0 THEN p_groesse END,
    belegt_bytes = CASE WHEN p_belegt >= 0 THEN p_belegt END, staende = CASE WHEN p_staende >= 0 THEN p_staende END,
    meldung = nullif(left(btrim(regexp_replace(coalesce(p_meldung, ''), '[[:cntrl:]]+', ' ', 'g')), 1000), '')
  WHERE x.id = p_lauf AND x.ergebnis = 'laeuft'
  RETURNING * INTO l;
  IF NOT FOUND THEN RETURN 'kein laufender Auftrag'; END IF;
  IF l.ergebnis IN ('fehler', 'warnung') AND l.anlass <> 'pruefen' THEN
    t := 'Das Backup vom ' || ally_sicherung_zeit(l.begonnen_am) || ' Uhr ' || CASE WHEN l.ergebnis = 'warnung' THEN 'ist mit einer Warnung beendet' ELSE 'ist fehlgeschlagen' END
      || coalesce(': ' || l.meldung, '.');
    FOR p IN SELECT x.matrix_user_id FROM ally_personen x WHERE x.aktiv
               AND coalesce(ally_hat_recht(x.matrix_user_id, CASE WHEN l.art = 'anbieter' THEN 'superadmin' ELSE 'admin' END), false) LOOP
      PERFORM ally_benachrichtigen(p.matrix_user_id, 'systemfehler', CASE WHEN l.ergebnis = 'warnung' THEN 'Backup mit Warnung' ELSE 'Backup fehlgeschlagen' END, t,
        jsonb_build_object('seite', 'einstellungen', 'parameter', jsonb_build_object('bereich', 'sicherung')), 'sicherung:' || l.id, 'Backups', false);
    END LOOP;
  END IF;
  DELETE FROM ally_sicherung_laeufe x WHERE x.art = l.art AND x.id NOT IN (SELECT y.id FROM ally_sicherung_laeufe y WHERE y.art = l.art ORDER BY y.begonnen_am DESC, y.id DESC LIMIT 200);
  RETURN 'ok';
END $function$;
CREATE OR REPLACE FUNCTION public.ally_sicherung_host_plan(p_meldung jsonb)
 RETURNS SETOF text
 LANGUAGE plpgsql
AS $function$
-- Migration 202 (Fehler Nr. 42, Stefan 03.11.2026): Backup statt Sicherung
DECLARE
  q jsonb := CASE WHEN jsonb_typeof(p_meldung) = 'object' THEN p_meldung ELSE '{}'::jsonb END;
  a text; z ally_sicherung_ziele; an text; nr bigint;
  zahl text := '^[0-9]{1,18}$';
BEGIN
  -- Migration 201 (Sicherung auf die NAS, Stefan 03.11.2026): Aufruf des Sicherungsprogramms auf dem Server (server/installation/sicherung/ally-sicherung.sh, alle 5 Minuten,
  -- nur eine Instanz zugleich). Meldung des Servers (schluessel_anbieter/schluessel_kunde = öffentlicher SSH-Schlüssel ed25519 je Ziel, frei/gesamt = Platz auf dem Server in Byte, lokal_belegt/lokal_staende =
  -- lokale Kopien, fassung) speichern; Läufe, die noch als „läuft“ stehen, gelten als abgebrochen (das Programm läuft nie doppelt). Dann je Ziel höchstens einen Auftrag
  -- übernehmen: „Verbindung prüfen“, „Jetzt sichern“ oder einen fälligen Termin des Zeitplans (ein verpasster Termin wird einmal nachgeholt). Anbieter-Ziel nach Plan auch
  -- ohne eingetragenes Ziel (dann nur auf dem Server); Kunden-Ziel nach Plan nur mit Ziel und Kennwort. Ergebnis je Auftrag eine Zeile „lauf|art|anlass“.
  INSERT INTO ally_sicherung_server AS x (id, ssh_schluessel_anbieter, ssh_schluessel_kunde, gemeldet_am, fassung, platz_frei_bytes, platz_gesamt_bytes, lokal_belegt_bytes, lokal_staende)
  VALUES (1, CASE WHEN coalesce(q->>'schluessel_anbieter', '') ~ '^ssh-ed25519 [A-Za-z0-9+/]{40,120}={0,2}( [A-Za-z0-9@._-]{1,80})?$' THEN q->>'schluessel_anbieter' END,
    CASE WHEN coalesce(q->>'schluessel_kunde', '') ~ '^ssh-ed25519 [A-Za-z0-9+/]{40,120}={0,2}( [A-Za-z0-9@._-]{1,80})?$' THEN q->>'schluessel_kunde' END, now(),
    nullif(left(regexp_replace(coalesce(q->>'fassung', ''), '[^A-Za-z0-9._-]', '', 'g'), 40), ''),
    CASE WHEN coalesce(q->>'frei', '') ~ zahl THEN (q->>'frei')::bigint END, CASE WHEN coalesce(q->>'gesamt', '') ~ zahl THEN (q->>'gesamt')::bigint END,
    CASE WHEN coalesce(q->>'lokal_belegt', '') ~ zahl THEN (q->>'lokal_belegt')::bigint END, CASE WHEN coalesce(q->>'lokal_staende', '') ~ '^[0-9]{1,6}$' THEN (q->>'lokal_staende')::integer END)
  ON CONFLICT (id) DO UPDATE SET ssh_schluessel_anbieter = coalesce(EXCLUDED.ssh_schluessel_anbieter, x.ssh_schluessel_anbieter),
    ssh_schluessel_kunde = coalesce(EXCLUDED.ssh_schluessel_kunde, x.ssh_schluessel_kunde), gemeldet_am = EXCLUDED.gemeldet_am, fassung = EXCLUDED.fassung,
    platz_frei_bytes = EXCLUDED.platz_frei_bytes, platz_gesamt_bytes = EXCLUDED.platz_gesamt_bytes, lokal_belegt_bytes = EXCLUDED.lokal_belegt_bytes, lokal_staende = EXCLUDED.lokal_staende;
  UPDATE ally_sicherung_laeufe x SET ergebnis = 'fehler', beendet_am = now(), meldung = 'Abgebrochen: Das Backup-Programm wurde vor dem Ende beendet (z. B. Neustart des Servers).'
  WHERE x.ergebnis = 'laeuft';
  FOREACH a IN ARRAY ARRAY['anbieter', 'kunde'] LOOP
    PERFORM 1 FROM ally_sicherung_ziele x WHERE x.art = a FOR UPDATE;
    z := ally_sicherung_ziel(a);
    an := CASE WHEN z.auftrag = 'pruefen' THEN 'pruefen' WHEN z.auftrag = 'sichern' THEN 'hand'
      WHEN z.plan_an AND (a = 'anbieter' OR (z.sftp_host IS NOT NULL AND z.sftp_benutzer IS NOT NULL AND z.sftp_ordner IS NOT NULL AND z.kennwort IS NOT NULL))
        AND ally_sicherung_termin(z, now(), false) > coalesce((SELECT max(x.begonnen_am) FROM ally_sicherung_laeufe x WHERE x.art = a AND x.anlass = 'plan'), '-infinity'::timestamptz)
        THEN 'plan' END;
    CONTINUE WHEN an IS NULL;
    INSERT INTO ally_sicherung_laeufe (art, anlass, von) VALUES (a, an, CASE WHEN an <> 'plan' THEN z.auftrag_von END) RETURNING id INTO nr;
    IF z.auftrag IS NOT NULL THEN
      UPDATE ally_sicherung_ziele x SET auftrag = NULL, auftrag_am = NULL, auftrag_von = NULL WHERE x.art = a;
    END IF;
    RETURN NEXT nr::text || '|' || a || '|' || an;
  END LOOP;
  RETURN;
END $function$;
CREATE OR REPLACE FUNCTION public.ally_sicherung_ui_aktion(p_token text, p_csrf text, p_aktion text, p_daten jsonb, p_zustand jsonb, p_geheim jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
-- Migration 202 (Fehler Nr. 42, Stefan 03.11.2026): Backup statt Sicherung
DECLARE
  d jsonb := CASE WHEN jsonb_typeof(p_daten) = 'object' THEN p_daten ELSE '{}'::jsonb END;
  g jsonb := CASE WHEN jsonb_typeof(p_geheim) = 'object' THEN p_geheim ELSE '{}'::jsonb END;
  s record; e jsonb;
  a text := coalesce(d->>'art', '');
  z ally_sicherung_ziele;
  fehler text := NULL; m text := NULL;
  t text; n1 integer; n2 integer; n3 integer; n4 integer; pw text; h text; b text; o text; pt integer;
  aktiv boolean;
BEGIN
  -- Migration 201 (Sicherung auf die NAS, Stefan 03.11.2026): Aktionen der Seite Einstellungen › System › Sicherung (si_*). NULL bei allen anderen Aktionen und ohne
  -- Personen-Sitzung (ALLY 20 „Aktion ausführen“, Kette coalesce). Sitzung, Schutzwert und Passwort-Pflicht wie ally_ui_oberflaeche_aktion; setzt die Meldung selbst.
  -- Rechte: Anbieter-Ziel (art anbieter) nur Superadmins, Kunden-Ziel (art kunde) Admins. si_plan (plan_an, haeufigkeit, uhrzeit, wochentag), si_aufbewahrung
  -- (behalten_taeglich, _woechentlich, _monatlich; lokal_tage nur anbieter), si_ziel (sftp_host, sftp_port, sftp_benutzer, sftp_ordner; alle leer = Ziel entfernen),
  -- si_kennwort (Wiederherstellungs-Kennwort aus p_geheim kennwort/kennwort2, nie aus p_daten; nur setzen; Ersetzen nur mit ersetzen = 1, neues Kennwort = neues
  -- Repository), si_pruefen und si_jetzt (Auftrag für das Sicherungsprogramm auf dem Server), si_hostschluessel_neu (gespeicherten Hostschlüssel vergessen).
  IF p_aktion IS NULL OR p_aktion !~ '^si_[a-z_]{1,30}$' THEN RETURN NULL; END IF;
  SELECT * INTO s FROM ally_ui_sitzung(p_token);
  IF NOT FOUND THEN RETURN NULL; END IF;
  IF coalesce(p_csrf, '') <> ally_ui_csrf(s.token_hash) THEN
    PERFORM ally_web_meldung(p_token, 'Die Anfrage wurde abgelehnt. Bitte die Seite neu laden.', 'fehler', NULL);
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

  IF a = 'anbieter' AND NOT coalesce(ally_hat_recht(s.person, 'superadmin'), false) OR a NOT IN ('anbieter', 'kunde') THEN
    fehler := 'Diese Aktion gibt es nicht.';
  ELSIF a = 'kunde' AND NOT coalesce(ally_hat_recht(s.person, 'admin'), false) THEN
    fehler := 'Backups richtet eine Person mit der Rolle Admin ein.';
  ELSE
    PERFORM 1 FROM ally_sicherung_ziele x WHERE x.art = a FOR UPDATE;
    z := ally_sicherung_ziel(a);
    aktiv := coalesce((SELECT x.gemeldet_am > now() - interval '15 minutes' FROM ally_sicherung_server x WHERE x.id = 1), false);
    IF p_aktion = 'si_plan' THEN
      t := btrim(coalesce(d->>'uhrzeit', ''));
      IF coalesce(d->>'haeufigkeit', '') NOT IN ('taeglich', '6h', '12h', 'woechentlich') THEN fehler := 'Bitte die Häufigkeit wählen.';
      ELSIF t !~ '^([01]?[0-9]|2[0-3]):[0-5][0-9](:[0-5][0-9])?$' THEN fehler := 'Bitte eine Uhrzeit wie 02:15 eintragen.';
      ELSIF d->>'haeufigkeit' = 'woechentlich' AND coalesce(d->>'wochentag', '') !~ '^[1-7]$' THEN fehler := 'Bitte den Wochentag wählen.';
      ELSE
        z.plan_an := coalesce(d->>'plan_an', '') = '1'; z.haeufigkeit := d->>'haeufigkeit'; z.uhrzeit := date_trunc('minute', t::time);
        IF coalesce(d->>'wochentag', '') ~ '^[1-7]$' THEN z.wochentag := (d->>'wochentag')::smallint; END IF;
        m := CASE WHEN z.plan_an THEN 'Zeitplan gespeichert. Nächstes Backup: ' || coalesce(ally_sicherung_zeit(ally_sicherung_termin(z, now(), true)), '–') || ' Uhr.'
                  ELSE 'Zeitplan gespeichert. Automatisches Backup ist aus.' END;
      END IF;
    ELSIF p_aktion = 'si_aufbewahrung' THEN
      n1 := CASE WHEN coalesce(d->>'behalten_taeglich', '') ~ '^[0-9]{1,3}$' THEN (d->>'behalten_taeglich')::integer END;
      n2 := CASE WHEN coalesce(d->>'behalten_woechentlich', '') ~ '^[0-9]{1,3}$' THEN (d->>'behalten_woechentlich')::integer END;
      n3 := CASE WHEN coalesce(d->>'behalten_monatlich', '') ~ '^[0-9]{1,3}$' THEN (d->>'behalten_monatlich')::integer END;
      n4 := CASE WHEN a = 'kunde' THEN z.lokal_tage WHEN coalesce(d->>'lokal_tage', '') ~ '^[0-9]{1,2}$' THEN (d->>'lokal_tage')::integer END;
      IF n1 IS NULL OR n2 IS NULL OR n3 IS NULL OR n1 > 366 OR n2 > 520 OR n3 > 240 THEN fehler := 'Bitte die Anzahl der Stände als Zahl eintragen (täglich bis 366, wöchentlich bis 520, monatlich bis 240).';
      ELSIF n1 + n2 + n3 < 1 THEN fehler := 'Mindestens ein Stand muss erhalten bleiben.';
      ELSIF n4 IS NULL OR n4 < 1 OR n4 > 90 THEN fehler := 'Bitte die Tage auf dem Server als Zahl von 1 bis 90 eintragen.';
      ELSE
        z.behalten_taeglich := n1; z.behalten_woechentlich := n2; z.behalten_monatlich := n3; z.lokal_tage := n4;
        m := 'Aufbewahrung gespeichert. Sie gilt ab dem nächsten Backup.';
      END IF;
    ELSIF p_aktion = 'si_ziel' THEN
      h := lower(btrim(coalesce(d->>'sftp_host', ''))); b := btrim(coalesce(d->>'sftp_benutzer', '')); o := btrim(coalesce(d->>'sftp_ordner', ''));
      t := btrim(coalesce(d->>'sftp_port', ''));
      pt := CASE WHEN t = '' THEN 22 WHEN t ~ '^[0-9]{1,5}$' AND t::integer BETWEEN 1 AND 65535 THEN t::integer END;
      IF h = '' AND b = '' AND o = '' THEN
        z.sftp_host := NULL; z.sftp_benutzer := NULL; z.sftp_ordner := NULL; z.sftp_port := 22;
        z.hostschluessel := NULL; z.hostschluessel_fp := NULL; z.hostschluessel_am := NULL; z.auftrag := NULL; z.auftrag_am := NULL; z.auftrag_von := NULL;
        m := 'Ziel entfernt. Gesicherte Stände auf dem Ziel bleiben dort erhalten.';
      ELSIF h !~ '^[a-z0-9]([a-z0-9.-]{0,251}[a-z0-9])?$' THEN fehler := 'Bitte die Adresse ohne Protokoll eintragen, z. B. nas.firma.de.';
      ELSIF pt IS NULL THEN fehler := 'Der Port ist eine Zahl von 1 bis 65535.';
      ELSIF b !~ '^[A-Za-z0-9_][A-Za-z0-9._-]{0,63}$' THEN fehler := 'Der Benutzername beginnt mit einem Buchstaben, einer Ziffer oder _ und enthält nur Buchstaben, Ziffern, Punkt, Bindestrich und Unterstrich.';
      ELSIF o !~ '^/?[A-Za-z0-9._-]+(/[A-Za-z0-9._-]+)*/?$' OR length(o) > 200 OR o ~ '(^|/)\.\.?(/|$)' THEN
        fehler := 'Der Ordner darf nur Buchstaben, Ziffern, Punkt, Bindestrich, Unterstrich und / enthalten, z. B. /Backup/ally.';
      ELSE
        IF h IS DISTINCT FROM z.sftp_host OR pt IS DISTINCT FROM z.sftp_port THEN
          z.hostschluessel := NULL; z.hostschluessel_fp := NULL; z.hostschluessel_am := NULL;
        END IF;
        z.sftp_host := h; z.sftp_port := pt; z.sftp_benutzer := b; z.sftp_ordner := regexp_replace(o, '(.)/$', '\1');
        m := 'Ziel gespeichert.' || CASE WHEN z.hostschluessel IS NULL THEN ' Bitte jetzt „Verbindung prüfen“.' ELSE '' END;
      END IF;
    ELSIF p_aktion = 'si_kennwort' THEN
      pw := coalesce(g->>'kennwort', '');
      IF coalesce(length(ally_schluessel_roh()), 0) < 32 THEN fehler := 'Die Verschlüsselung der Installation ist nicht eingerichtet. Ohne sie lässt sich kein Kennwort speichern.';
      ELSIF z.kennwort IS NOT NULL AND coalesce(d->>'ersetzen', '') <> '1' THEN fehler := 'Ein Wiederherstellungs-Kennwort ist schon gesetzt. Zum Ersetzen bitte die Rückfrage bestätigen.';
      ELSIF pw = '' THEN fehler := 'Bitte das Wiederherstellungs-Kennwort eintragen.';
      ELSIF pw IS DISTINCT FROM coalesce(g->>'kennwort2', '') THEN fehler := 'Die beiden Eingaben stimmen nicht überein.';
      ELSIF length(pw) < 12 OR length(pw) > 200 THEN fehler := 'Das Kennwort braucht 12 bis 200 Zeichen.';
      ELSIF pw <> btrim(pw) OR pw ~ '[[:cntrl:]]' THEN fehler := 'Das Kennwort darf nicht mit einem Leerzeichen beginnen oder enden.';
      ELSE
        m := CASE WHEN z.kennwort IS NULL THEN 'Wiederherstellungs-Kennwort gesetzt. Bitte im Passwort-Manager ablegen: Ohne dieses Kennwort ist keine Wiederherstellung möglich.'
                  ELSE 'Wiederherstellungs-Kennwort ersetzt. Das nächste Backup legt auf dem Ziel ein neues Repository an; das bisherige bleibt dort und ist nur mit dem alten Kennwort lesbar.' END;
        z.kennwort := ally_verschluesseln(pw); z.kennwort_am := now(); z.repo := 'ally-' || to_char(clock_timestamp() AT TIME ZONE 'UTC', 'YYYYMMDD-HH24MISS');
      END IF;
    ELSIF p_aktion IN ('si_pruefen', 'si_jetzt') THEN
      IF z.auftrag IS NOT NULL OR EXISTS (SELECT 1 FROM ally_sicherung_laeufe x WHERE x.art = a AND x.ergebnis = 'laeuft') THEN
        fehler := 'Gerade läuft schon ein Backup oder eine Prüfung. Bitte warten, bis das Ergebnis im Verlauf steht.';
      ELSIF (p_aktion = 'si_pruefen' OR a = 'kunde') AND (z.sftp_host IS NULL OR z.sftp_benutzer IS NULL OR z.sftp_ordner IS NULL) THEN
        fehler := 'Bitte zuerst das Ziel eintragen.';
      ELSIF p_aktion = 'si_jetzt' AND z.sftp_host IS NOT NULL AND z.kennwort IS NULL THEN
        fehler := 'Bitte zuerst das Wiederherstellungs-Kennwort setzen.';
      ELSE
        z.auftrag := CASE WHEN p_aktion = 'si_pruefen' THEN 'pruefen' ELSE 'sichern' END; z.auftrag_am := now(); z.auftrag_von := s.person;
        m := CASE WHEN p_aktion = 'si_pruefen' THEN 'Die Verbindung wird in den nächsten 5 Minuten geprüft. Das Ergebnis steht dann im Verlauf.'
                  ELSE 'Das Backup startet in den nächsten 5 Minuten. Das Ergebnis steht dann im Verlauf.' END
          || CASE WHEN NOT aktiv THEN ' Das Backup-Programm auf dem Server meldet sich zurzeit nicht.' ELSE '' END;
      END IF;
    ELSIF p_aktion = 'si_hostschluessel_neu' THEN
      IF z.hostschluessel IS NULL THEN fehler := 'Es ist kein Hostschlüssel gespeichert.';
      ELSE
        z.hostschluessel := NULL; z.hostschluessel_fp := NULL; z.hostschluessel_am := NULL;
        m := 'Hostschlüssel vergessen. „Verbindung prüfen“ übernimmt den aktuellen Schlüssel der NAS.';
      END IF;
    ELSE
      fehler := 'Diese Aktion gibt es nicht.';
    END IF;
    IF fehler IS NULL THEN
      z.geaendert_am := now(); z.geaendert_von := s.person;
      DELETE FROM ally_sicherung_ziele x WHERE x.art = a;
      INSERT INTO ally_sicherung_ziele SELECT (z).*;
    END IF;
  END IF;
  PERFORM ally_web_meldung(p_token, coalesce(fehler, m), CASE WHEN fehler IS NULL THEN 'ok' ELSE 'fehler' END, NULL);
  RETURN jsonb_build_object('ok', fehler IS NULL, 'angemeldet', true);
END $function$;
DO $m$
BEGIN
  IF (SELECT md5(string_agg(z, E'\n' ORDER BY z COLLATE "C")) FROM (WITH t AS (SELECT c.oid, c.relname::text AS tab FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname::text = 'public' COLLATE "C" AND c.relkind::text = ANY (ARRAY['r', 'p']) AND c.relname::text = ANY (ARRAY['ally_sicherung_laeufe', 'ally_sicherung_server', 'ally_sicherung_ziele'])) SELECT 'S|' || t.tab || '|' || a.attname::text || '|' || format_type(a.atttypid, a.atttypmod) || '|' || CASE WHEN a.attnotnull THEN 'NN' ELSE '-' END || '|' || coalesce(pg_get_expr(d.adbin, d.adrelid), '') || '|' || a.attidentity::text || a.attgenerated::text AS z FROM t JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum > 0 AND NOT a.attisdropped LEFT JOIN pg_attrdef d ON d.adrelid = t.oid AND d.adnum = a.attnum UNION ALL SELECT 'C|' || t.tab || '|' || co.conname::text || '|' || co.contype::text || '|' || pg_get_constraintdef(co.oid) FROM t JOIN pg_constraint co ON co.conrelid = t.oid UNION ALL SELECT 'I|' || t.tab || '|' || ic.relname::text || '|' || pg_get_indexdef(i.indexrelid) FROM t JOIN pg_index i ON i.indrelid = t.oid JOIN pg_class ic ON ic.oid = i.indexrelid UNION ALL SELECT 'T|' || t.tab || '|' || tg.tgname::text || '|' || pg_get_triggerdef(tg.oid) || '|' || tg.tgenabled::text FROM t JOIN pg_trigger tg ON tg.tgrelid = t.oid AND NOT tg.tgisinternal) x) IS DISTINCT FROM '4d61775f5a8485822c7ff5c30815f9a1' THEN RAISE EXCEPTION 'Migration 202: Schema nicht wie gebaut'; END IF;
  IF (SELECT md5(string_agg(p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')|' || pg_get_function_result(p.oid) || '|' || md5(p.prosrc), E'\n' ORDER BY p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')' COLLATE "C")) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname::text = 'public' COLLATE "C" AND p.proname::text COLLATE "C" = ANY (ARRAY['ally_sicherung_host_ende', 'ally_sicherung_host_plan', 'ally_sicherung_ui_aktion'])) IS DISTINCT FROM 'dad7c09e1689db9057959af41fe31159' THEN RAISE EXCEPTION 'Migration 202: Funktionen nicht wie gebaut'; END IF;
END $m$;
