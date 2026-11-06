-- Migration 201 (Sicherung auf die NAS, Stefan 03.11.2026): Seite Einstellungen › System › Sicherung und Sicherungsprogramm auf dem Server
-- (server/installation/sicherung/ally-sicherung.sh, alle 5 Minuten; restic über SFTP, verschlüsselt mit dem Wiederherstellungs-Kennwort). Zwei unabhängige Ziele:
-- anbieter (nur Superadmin, für Kunden unsichtbar) und kunde (Admin der Installation, optional). Neu: Tabellen ally_sicherung_ziele, ally_sicherung_server,
-- ally_sicherung_laeufe (leer; ohne Zeile gilt die Voreinstellung täglich 02:15, 7/4/6 Stände, auf dem Server 7 Tage); Funktionen ally_sicherung_standard, ally_sicherung_ziel, ally_sicherung_zeit, ally_sicherung_termin, ally_sicherung_ziel_ui, ally_sicherung_ui, ally_sicherung_ui_aktion, ally_sicherung_host_plan, ally_sicherung_host_ziel, ally_sicherung_kunde_inhalt, ally_sicherung_host_kennwort, ally_sicherung_host_hostschluessel, ally_sicherung_host_ende.
-- Keine geänderte Funktion, keine Datenänderung. Aktionen si_* über ALLY 20 „Aktion ausführen“ (ally_sicherung_ui_aktion), Seite über ALLY 23.
-- Wächter: Tabellen und Funktionen noch nicht vorhanden, benötigte Funktionen und die Benachrichtigungsart systemfehler vorhanden; nachher Schema und Funktionen wie gebaut,
-- neue Tabellen leer. Nur als Ganzes in einer Transaktion. Rückbau: rueckbau201.sql.
DO $m$
BEGIN
  IF (SELECT count(*) FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname::text = 'public' COLLATE "C" AND c.relkind = 'r' AND c.relname::text COLLATE "C" = ANY (ARRAY['ally_sicherung_laeufe', 'ally_sicherung_server', 'ally_sicherung_ziele'])) = 3 AND (SELECT md5(string_agg(p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')|' || pg_get_function_result(p.oid) || '|' || md5(p.prosrc), E'\n' ORDER BY p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')' COLLATE "C")) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname::text = 'public' COLLATE "C" AND p.proname::text COLLATE "C" LIKE 'ally\_sicherung\_%') IS NOT DISTINCT FROM 'a5836893209fb77c3dbdca628a473ac1' AND (SELECT md5(string_agg(z, E'\n' ORDER BY z COLLATE "C")) FROM (WITH t AS (SELECT c.oid, c.relname::text AS tab FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname::text = 'public' COLLATE "C" AND c.relkind::text = ANY (ARRAY['r', 'p']) AND c.relname::text = ANY (ARRAY['ally_sicherung_laeufe', 'ally_sicherung_server', 'ally_sicherung_ziele'])) SELECT 'S|' || t.tab || '|' || a.attname::text || '|' || format_type(a.atttypid, a.atttypmod) || '|' || CASE WHEN a.attnotnull THEN 'NN' ELSE '-' END || '|' || coalesce(pg_get_expr(d.adbin, d.adrelid), '') || '|' || a.attidentity::text || a.attgenerated::text AS z FROM t JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum > 0 AND NOT a.attisdropped LEFT JOIN pg_attrdef d ON d.adrelid = t.oid AND d.adnum = a.attnum UNION ALL SELECT 'C|' || t.tab || '|' || co.conname::text || '|' || co.contype::text || '|' || pg_get_constraintdef(co.oid) FROM t JOIN pg_constraint co ON co.conrelid = t.oid UNION ALL SELECT 'I|' || t.tab || '|' || ic.relname::text || '|' || pg_get_indexdef(i.indexrelid) FROM t JOIN pg_index i ON i.indrelid = t.oid JOIN pg_class ic ON ic.oid = i.indexrelid UNION ALL SELECT 'T|' || t.tab || '|' || tg.tgname::text || '|' || pg_get_triggerdef(tg.oid) || '|' || tg.tgenabled::text FROM t JOIN pg_trigger tg ON tg.tgrelid = t.oid AND NOT tg.tgisinternal) x) IS NOT DISTINCT FROM '4d61775f5a8485822c7ff5c30815f9a1'
    THEN RAISE EXCEPTION 'Migration 201: schon eingespielt, nichts geändert'; END IF;
  IF (SELECT count(*) FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname::text = 'public' COLLATE "C" AND c.relkind = 'r' AND c.relname::text COLLATE "C" = ANY (ARRAY['ally_sicherung_laeufe', 'ally_sicherung_server', 'ally_sicherung_ziele'])) <> 0 THEN RAISE EXCEPTION 'Migration 201: Tabellen ally_sicherung_* schon vorhanden (unbekannter Stand), nichts geändert'; END IF;
  IF (SELECT md5(string_agg(p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')|' || pg_get_function_result(p.oid) || '|' || md5(p.prosrc), E'\n' ORDER BY p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')' COLLATE "C")) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname::text = 'public' COLLATE "C" AND p.proname::text COLLATE "C" LIKE 'ally\_sicherung\_%') IS NOT NULL THEN RAISE EXCEPTION 'Migration 201: Funktionen ally_sicherung_* schon vorhanden (unbekannter Stand), nichts geändert'; END IF;
  IF (SELECT count(*) FROM unnest(ARRAY['ally_ui_sitzung(text)', 'ally_ui_csrf(text)', 'ally_web_meldung(text,text,text,jsonb)', 'ally_ui_zustand_merken(text,text,jsonb)', 'ally_hat_recht(text,text)', 'ally_verschluesseln(text)', 'ally_entschluesseln(bytea)', 'ally_schluessel_roh()', 'ally_benachrichtigen(text,text,text,text,jsonb,text,text,boolean)']) f WHERE to_regprocedure(f) IS NULL) <> 0 THEN RAISE EXCEPTION 'Migration 201: eine benötigte Funktion fehlt, nichts geändert'; END IF;
  IF (SELECT count(*) FROM ally_benachrichtigung_arten x WHERE x.schluessel = 'systemfehler') <> 1 THEN RAISE EXCEPTION 'Migration 201: Benachrichtigungsart systemfehler fehlt, nichts geändert'; END IF;
END $m$;
CREATE TABLE public.ally_sicherung_ziele (
  art text NOT NULL,
  plan_an boolean NOT NULL DEFAULT false,
  haeufigkeit text NOT NULL DEFAULT 'taeglich',
  uhrzeit time without time zone NOT NULL DEFAULT '02:15:00',
  wochentag smallint NOT NULL DEFAULT 7,
  behalten_taeglich integer NOT NULL DEFAULT 7,
  behalten_woechentlich integer NOT NULL DEFAULT 4,
  behalten_monatlich integer NOT NULL DEFAULT 6,
  lokal_tage integer NOT NULL DEFAULT 7,
  sftp_host text,
  sftp_port integer NOT NULL DEFAULT 22,
  sftp_benutzer text,
  sftp_ordner text,
  kennwort bytea,
  kennwort_am timestamp with time zone,
  repo text,
  hostschluessel text,
  hostschluessel_fp text,
  hostschluessel_am timestamp with time zone,
  auftrag text,
  auftrag_am timestamp with time zone,
  auftrag_von text,
  geaendert_am timestamp with time zone NOT NULL DEFAULT now(),
  geaendert_von text,
  CONSTRAINT ally_sicherung_ziele_pkey PRIMARY KEY (art),
  CONSTRAINT ally_sicherung_ziele_art_check CHECK (art IN ('anbieter', 'kunde')),
  CONSTRAINT ally_sicherung_ziele_haeufigkeit_check CHECK (haeufigkeit IN ('taeglich', '6h', '12h', 'woechentlich')),
  CONSTRAINT ally_sicherung_ziele_wochentag_check CHECK (wochentag BETWEEN 1 AND 7),
  CONSTRAINT ally_sicherung_ziele_behalten_check CHECK (behalten_taeglich BETWEEN 0 AND 366 AND behalten_woechentlich BETWEEN 0 AND 520 AND behalten_monatlich BETWEEN 0 AND 240
    AND behalten_taeglich + behalten_woechentlich + behalten_monatlich >= 1),
  CONSTRAINT ally_sicherung_ziele_lokal_tage_check CHECK (lokal_tage BETWEEN 1 AND 90),
  CONSTRAINT ally_sicherung_ziele_sftp_port_check CHECK (sftp_port BETWEEN 1 AND 65535),
  CONSTRAINT ally_sicherung_ziele_auftrag_check CHECK (auftrag IS NULL OR auftrag IN ('sichern', 'pruefen')),
  CONSTRAINT ally_sicherung_ziele_kennwort_check CHECK ((kennwort IS NULL) = (repo IS NULL))
);
COMMENT ON TABLE public.ally_sicherung_ziele IS 'Migration 201 (Sicherung auf die NAS, Stefan 03.11.2026): je Ziel (anbieter = nur Superadmin, kunde = Admin der Installation) Zeitplan, Aufbewahrung, SFTP-Ziel, Wiederherstellungs-Kennwort (nur verschlüsselt, ally_verschluesseln; repo = Ordner des Repositorys zu diesem Kennwort), gelernter Hostschlüssel und offener Auftrag für das Sicherungsprogramm. Ohne Zeile gilt ally_sicherung_standard.';
CREATE TABLE public.ally_sicherung_server (
  id integer NOT NULL,
  ssh_schluessel_anbieter text,
  ssh_schluessel_kunde text,
  gemeldet_am timestamp with time zone,
  fassung text,
  platz_frei_bytes bigint,
  platz_gesamt_bytes bigint,
  lokal_belegt_bytes bigint,
  lokal_staende integer,
  CONSTRAINT ally_sicherung_server_pkey PRIMARY KEY (id),
  CONSTRAINT ally_sicherung_server_id_check CHECK (id = 1)
);
COMMENT ON TABLE public.ally_sicherung_server IS 'Migration 201: Meldung des Sicherungsprogramms auf dem Server (Einzelzeile id = 1): öffentlicher SSH-Schlüssel je Ziel (eigenes Schlüsselpaar für anbieter und kunde; der geheime Teil bleibt unter /opt/ally/sicherung/ssh/<ziel>), letzte Meldung, Platz auf dem Server, lokale Kopien.';
CREATE TABLE public.ally_sicherung_laeufe (
  id bigint GENERATED ALWAYS AS IDENTITY,
  art text NOT NULL,
  anlass text NOT NULL,
  von text,
  begonnen_am timestamp with time zone NOT NULL DEFAULT now(),
  beendet_am timestamp with time zone,
  ergebnis text NOT NULL DEFAULT 'laeuft',
  groesse_bytes bigint,
  belegt_bytes bigint,
  staende integer,
  meldung text,
  CONSTRAINT ally_sicherung_laeufe_pkey PRIMARY KEY (id),
  CONSTRAINT ally_sicherung_laeufe_art_check CHECK (art IN ('anbieter', 'kunde')),
  CONSTRAINT ally_sicherung_laeufe_anlass_check CHECK (anlass IN ('plan', 'hand', 'pruefen')),
  CONSTRAINT ally_sicherung_laeufe_ergebnis_check CHECK (ergebnis IN ('laeuft', 'ok', 'warnung', 'fehler', 'nur_lokal'))
);
CREATE INDEX ally_sicherung_laeufe_art_idx ON public.ally_sicherung_laeufe USING btree (art, begonnen_am DESC);
COMMENT ON TABLE public.ally_sicherung_laeufe IS 'Migration 201: Läufe des Sicherungsprogramms je Ziel (Zeitplan, Jetzt sichern, Verbindung prüfen) mit Ergebnis, Größe, belegtem Platz auf dem Ziel und Meldung; je Ziel die letzten 200.';
CREATE OR REPLACE FUNCTION public.ally_sicherung_standard(p_art text)
 RETURNS ally_sicherung_ziele
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
DECLARE
  z ally_sicherung_ziele;
BEGIN
  -- Migration 201 (Sicherung auf die NAS, Stefan 03.11.2026): Voreinstellung eines Ziels ohne gespeicherte Zeile. Anbieter-Ziel: Zeitplan an, täglich 02:15,
  -- 7 tägliche, 4 wöchentliche, 6 monatliche Stände, auf dem Server 7 Tage; ohne Ziel sichert der Server nur lokal. Kunden-Ziel: gleiche Werte, Zeitplan aus.
  z.art := p_art; z.plan_an := p_art = 'anbieter'; z.haeufigkeit := 'taeglich'; z.uhrzeit := time '02:15'; z.wochentag := 7;
  z.behalten_taeglich := 7; z.behalten_woechentlich := 4; z.behalten_monatlich := 6; z.lokal_tage := 7; z.sftp_port := 22;
  RETURN z;
END $function$;
CREATE OR REPLACE FUNCTION public.ally_sicherung_ziel(p_art text)
 RETURNS ally_sicherung_ziele
 LANGUAGE sql
 STABLE
AS $function$
  -- Migration 201: gespeichertes Ziel (anbieter | kunde) oder die Voreinstellung (ally_sicherung_standard)
  SELECT coalesce((SELECT z FROM ally_sicherung_ziele z WHERE z.art = p_art), ally_sicherung_standard(p_art))
$function$;
CREATE OR REPLACE FUNCTION public.ally_sicherung_zeit(p_zeit timestamp with time zone)
 RETURNS text
 LANGUAGE sql
 STABLE
AS $function$
  -- Migration 201: Zeitpunkt für die Seite Sicherung (Berliner Zeit)
  SELECT to_char(p_zeit AT TIME ZONE 'Europe/Berlin', 'DD.MM.YYYY, HH24:MI')
$function$;
CREATE OR REPLACE FUNCTION public.ally_sicherung_termin(p_ziel ally_sicherung_ziele, p_zeit timestamp with time zone, p_naechster boolean)
 RETURNS timestamp with time zone
 LANGUAGE sql
 STABLE
AS $function$
  -- Migration 201: Termine des Zeitplans in Berliner Zeit (täglich zur Uhrzeit; alle 6 bzw. 12 Stunden ab der Uhrzeit; wöchentlich am Wochentag 1 = Montag … 7 = Sonntag
  -- zur Uhrzeit). p_naechster: erster Termin nach p_zeit, sonst letzter Termin bis einschließlich p_zeit. NULL ohne Termin (Zeitplan aus) oder ohne Zeitpunkt.
  SELECT CASE WHEN p_naechster THEN min(x.t) FILTER (WHERE x.t > p_zeit) ELSE max(x.t) FILTER (WHERE x.t <= p_zeit) END
  FROM (SELECT ((d.tag::date + p_ziel.uhrzeit) + k.n * CASE p_ziel.haeufigkeit WHEN '6h' THEN interval '6 hours' WHEN '12h' THEN interval '12 hours' ELSE interval '0 hours' END)
               AT TIME ZONE 'Europe/Berlin' AS t
        FROM generate_series(((p_zeit AT TIME ZONE 'Europe/Berlin')::date - 9)::timestamp, ((p_zeit AT TIME ZONE 'Europe/Berlin')::date + 9)::timestamp, interval '1 day') d(tag)
        CROSS JOIN generate_series(0, CASE p_ziel.haeufigkeit WHEN '6h' THEN 3 WHEN '12h' THEN 1 ELSE 0 END) k(n)
        WHERE p_ziel.plan_an AND p_zeit IS NOT NULL
          AND (p_ziel.haeufigkeit IS DISTINCT FROM 'woechentlich' OR extract(isodow FROM d.tag)::integer = p_ziel.wochentag)) x
$function$;
CREATE OR REPLACE FUNCTION public.ally_sicherung_ziel_ui(p_art text)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
  z ally_sicherung_ziele := ally_sicherung_ziel(p_art);
  l ally_sicherung_laeufe;
  o ally_sicherung_laeufe;
  laeuft boolean;
  sk text;
BEGIN
  -- Migration 201: Angaben eines Ziels für die Seite Sicherung (ohne Rechteprüfung; nur aus ally_sicherung_ui). Das Wiederherstellungs-Kennwort nie, nur ob es gesetzt ist.
  -- letzte = letzter beendeter Lauf (Sichern, nicht Prüfen); belegt/staende aus der letzten erfolgreichen Sicherung (auch mit Warnung); verlauf = letzte 30 Läufe (auch Prüfen).
  SELECT * INTO l FROM ally_sicherung_laeufe x WHERE x.art = p_art AND x.anlass <> 'pruefen' AND x.ergebnis <> 'laeuft' ORDER BY x.begonnen_am DESC, x.id DESC LIMIT 1;
  SELECT * INTO o FROM ally_sicherung_laeufe x WHERE x.art = p_art AND x.ergebnis IN ('ok', 'warnung') AND x.anlass <> 'pruefen' ORDER BY x.begonnen_am DESC, x.id DESC LIMIT 1;
  -- öffentlicher SSH-Schlüssel dieses Ziels (je Ziel ein eigenes Schlüsselpaar; der Admin sieht nie den des Anbieter-Ziels)
  sk := (SELECT CASE WHEN p_art = 'anbieter' THEN x.ssh_schluessel_anbieter ELSE x.ssh_schluessel_kunde END FROM ally_sicherung_server x WHERE x.id = 1);
  laeuft := EXISTS (SELECT 1 FROM ally_sicherung_laeufe x WHERE x.art = p_art AND x.ergebnis = 'laeuft');
  RETURN jsonb_build_object('art', p_art, 'plan_an', z.plan_an, 'haeufigkeit', z.haeufigkeit, 'uhrzeit', to_char(z.uhrzeit, 'HH24:MI'), 'wochentag', z.wochentag,
    'behalten_taeglich', z.behalten_taeglich, 'behalten_woechentlich', z.behalten_woechentlich, 'behalten_monatlich', z.behalten_monatlich,
    'lokal_tage', CASE WHEN p_art = 'anbieter' THEN z.lokal_tage END,
    'sftp_host', z.sftp_host, 'sftp_port', z.sftp_port, 'sftp_benutzer', z.sftp_benutzer, 'sftp_ordner', z.sftp_ordner,
    'eingerichtet', z.sftp_host IS NOT NULL AND z.sftp_benutzer IS NOT NULL AND z.sftp_ordner IS NOT NULL,
    'kennwort_gesetzt', z.kennwort IS NOT NULL, 'kennwort_am', ally_sicherung_zeit(z.kennwort_am), 'repo', z.repo,
    'hostschluessel_fp', z.hostschluessel_fp, 'hostschluessel_am', ally_sicherung_zeit(z.hostschluessel_am),
    'auftrag', z.auftrag, 'laeuft', laeuft, 'schluessel', sk,
    'naechste', ally_sicherung_zeit(ally_sicherung_termin(z, now(), true)),
    'letzte', CASE WHEN l.id IS NOT NULL THEN jsonb_build_object('zeit', ally_sicherung_zeit(l.begonnen_am), 'ergebnis', l.ergebnis, 'groesse', l.groesse_bytes,
      'dauer', CASE WHEN l.beendet_am IS NOT NULL THEN greatest(0, round(extract(epoch FROM l.beendet_am - l.begonnen_am)))::bigint END, 'meldung', l.meldung) END,
    'belegt', o.belegt_bytes, 'staende', o.staende, 'belegt_stand', ally_sicherung_zeit(o.beendet_am),
    'verlauf', (SELECT coalesce(jsonb_agg(jsonb_build_object('id', v.id, 'zeit', ally_sicherung_zeit(v.begonnen_am), 'anlass', v.anlass, 'ergebnis', v.ergebnis,
        'groesse', v.groesse_bytes, 'dauer', CASE WHEN v.beendet_am IS NOT NULL THEN greatest(0, round(extract(epoch FROM v.beendet_am - v.begonnen_am)))::bigint END,
        'meldung', v.meldung) ORDER BY v.begonnen_am DESC, v.id DESC), '[]'::jsonb)
      FROM (SELECT * FROM ally_sicherung_laeufe x WHERE x.art = p_art ORDER BY x.begonnen_am DESC, x.id DESC LIMIT 30) v));
END $function$;
CREATE OR REPLACE FUNCTION public.ally_sicherung_ui(p_token text)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
  s record;
  sa boolean; adm boolean;
  sv ally_sicherung_server;
BEGIN
  -- Migration 201 (Sicherung auf die NAS, Stefan 03.11.2026): Daten der Seite Einstellungen › System › Sicherung (ALLY 23 „Sicherung laden“).
  -- Admin: eigenes Ziel (kunde) mit dem öffentlichen Schlüssel dieses Ziels (ally_sicherung_ziel_ui), Stand des Sicherungsprogramms. Superadmin zusätzlich das Anbieter-Ziel (anbieter) und den Platz
  -- auf dem Server. Für alle anderen und ohne Sitzung NULL. Das Anbieter-Ziel bekommen nur Superadmins (für Kunden unsichtbar, auch keine Hinweise).
  SELECT * INTO s FROM ally_ui_sitzung(p_token);
  IF NOT FOUND OR s.muss_pw_setzen THEN RETURN NULL; END IF;
  sa := coalesce(ally_hat_recht(s.person, 'superadmin'), false);
  adm := coalesce(ally_hat_recht(s.person, 'admin'), false);
  IF NOT sa AND NOT adm THEN RETURN NULL; END IF;
  SELECT * INTO sv FROM ally_sicherung_server x WHERE x.id = 1;
  RETURN jsonb_build_object('ok', true, 'sa', sa, 'admin', adm,
    'programm', jsonb_build_object('gemeldet', ally_sicherung_zeit(sv.gemeldet_am), 'aktiv', coalesce(sv.gemeldet_am > now() - interval '15 minutes', false), 'fassung', sv.fassung),
    'server', CASE WHEN sa THEN jsonb_build_object('frei', sv.platz_frei_bytes, 'gesamt', sv.platz_gesamt_bytes, 'lokal_belegt', sv.lokal_belegt_bytes,
      'lokal_staende', sv.lokal_staende) END,
    'ziele', CASE WHEN sa THEN jsonb_build_array(ally_sicherung_ziel_ui('anbieter')) ELSE '[]'::jsonb END
      || CASE WHEN adm THEN jsonb_build_array(ally_sicherung_ziel_ui('kunde')) ELSE '[]'::jsonb END);
END $function$;
CREATE OR REPLACE FUNCTION public.ally_sicherung_ui_aktion(p_token text, p_csrf text, p_aktion text, p_daten jsonb, p_zustand jsonb, p_geheim jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
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
    fehler := 'Die Sicherung richtet eine Person mit der Rolle Admin ein.';
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
        m := CASE WHEN z.plan_an THEN 'Zeitplan gespeichert. Nächste Sicherung: ' || coalesce(ally_sicherung_zeit(ally_sicherung_termin(z, now(), true)), '–') || ' Uhr.'
                  ELSE 'Zeitplan gespeichert. Automatische Sicherung ist aus.' END;
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
        m := 'Aufbewahrung gespeichert. Sie gilt ab der nächsten Sicherung.';
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
        fehler := 'Der Ordner darf nur Buchstaben, Ziffern, Punkt, Bindestrich, Unterstrich und / enthalten, z. B. /Sicherung/ally.';
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
                  ELSE 'Wiederherstellungs-Kennwort ersetzt. Die nächste Sicherung legt auf dem Ziel ein neues Repository an; das bisherige bleibt dort und ist nur mit dem alten Kennwort lesbar.' END;
        z.kennwort := ally_verschluesseln(pw); z.kennwort_am := now(); z.repo := 'ally-' || to_char(clock_timestamp() AT TIME ZONE 'UTC', 'YYYYMMDD-HH24MISS');
      END IF;
    ELSIF p_aktion IN ('si_pruefen', 'si_jetzt') THEN
      IF z.auftrag IS NOT NULL OR EXISTS (SELECT 1 FROM ally_sicherung_laeufe x WHERE x.art = a AND x.ergebnis = 'laeuft') THEN
        fehler := 'Gerade läuft schon eine Sicherung oder Prüfung. Bitte warten, bis sie im Verlauf steht.';
      ELSIF (p_aktion = 'si_pruefen' OR a = 'kunde') AND (z.sftp_host IS NULL OR z.sftp_benutzer IS NULL OR z.sftp_ordner IS NULL) THEN
        fehler := 'Bitte zuerst das Ziel eintragen.';
      ELSIF p_aktion = 'si_jetzt' AND z.sftp_host IS NOT NULL AND z.kennwort IS NULL THEN
        fehler := 'Bitte zuerst das Wiederherstellungs-Kennwort setzen.';
      ELSE
        z.auftrag := CASE WHEN p_aktion = 'si_pruefen' THEN 'pruefen' ELSE 'sichern' END; z.auftrag_am := now(); z.auftrag_von := s.person;
        m := CASE WHEN p_aktion = 'si_pruefen' THEN 'Die Verbindung wird in den nächsten 5 Minuten geprüft. Das Ergebnis steht dann im Verlauf.'
                  ELSE 'Die Sicherung startet in den nächsten 5 Minuten. Das Ergebnis steht dann im Verlauf.' END
          || CASE WHEN NOT aktiv THEN ' Das Sicherungsprogramm auf dem Server meldet sich zurzeit nicht.' ELSE '' END;
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
CREATE OR REPLACE FUNCTION public.ally_sicherung_host_plan(p_meldung jsonb)
 RETURNS SETOF text
 LANGUAGE plpgsql
AS $function$
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
  UPDATE ally_sicherung_laeufe x SET ergebnis = 'fehler', beendet_am = now(), meldung = 'Abgebrochen: Das Sicherungsprogramm wurde vor dem Ende beendet (z. B. Neustart des Servers).'
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
CREATE OR REPLACE FUNCTION public.ally_sicherung_host_ziel(p_lauf bigint)
 RETURNS text
 LANGUAGE sql
 STABLE
AS $function$
  -- Migration 201: Angaben eines laufenden Auftrags für das Sicherungsprogramm (eine Zeile, Trenner |): art|anlass|eingerichtet (1/0)|adresse|port|benutzer|ordner|
  -- repository|kennwort gesetzt (1/0)|hostschlüssel (known_hosts-Zeile oder leer)|behalten täglich|wöchentlich|monatlich|lokal Tage. Das Kennwort selbst nur über
  -- ally_sicherung_host_kennwort. NULL, wenn der Lauf nicht läuft. Alle Werte sind beim Speichern geprüft (ohne |).
  SELECT l.art || '|' || l.anlass || '|' || CASE WHEN z.sftp_host IS NOT NULL AND z.sftp_benutzer IS NOT NULL AND z.sftp_ordner IS NOT NULL THEN '1' ELSE '0' END
    || '|' || coalesce(z.sftp_host, '') || '|' || z.sftp_port || '|' || coalesce(z.sftp_benutzer, '') || '|' || coalesce(z.sftp_ordner, '') || '|' || coalesce(z.repo, '')
    || '|' || CASE WHEN z.kennwort IS NOT NULL THEN '1' ELSE '0' END || '|' || coalesce(z.hostschluessel, '')
    || '|' || z.behalten_taeglich || '|' || z.behalten_woechentlich || '|' || z.behalten_monatlich || '|' || (SELECT y.lokal_tage FROM ally_sicherung_ziel('anbieter') y)
  FROM ally_sicherung_laeufe l CROSS JOIN LATERAL ally_sicherung_ziel(l.art) z
  WHERE l.id = p_lauf AND l.ergebnis = 'laeuft'
$function$;
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
CREATE OR REPLACE FUNCTION public.ally_sicherung_host_kennwort(p_lauf bigint)
 RETURNS text
 LANGUAGE sql
 STABLE
AS $function$
  -- Migration 201: Wiederherstellungs-Kennwort eines Ziels nur für einen laufenden Auftrag des Sicherungsprogramms (schreibt es in eine Datei mit Rechten 600 nur für
  -- diesen Lauf; nie in Protokolle oder Meldungen). NULL ohne laufenden Auftrag oder ohne Kennwort.
  SELECT ally_entschluesseln(z.kennwort)
  FROM ally_sicherung_laeufe l CROSS JOIN LATERAL ally_sicherung_ziel(l.art) z
  WHERE l.id = p_lauf AND l.ergebnis = 'laeuft' AND z.kennwort IS NOT NULL
$function$;
CREATE OR REPLACE FUNCTION public.ally_sicherung_host_hostschluessel(p_lauf bigint, p_zeile text, p_fp text)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE
  l ally_sicherung_laeufe; z ally_sicherung_ziele; kopf text;
BEGIN
  -- Migration 201: Hostschlüssel der NAS beim ersten „Verbindung prüfen“ speichern (known_hosts-Zeile und Fingerabdruck SHA256). Nur für einen laufenden Prüf-Auftrag,
  -- nur wenn noch keiner gespeichert ist und nur für die eingetragene Adresse und den Port. Danach prüft das Sicherungsprogramm strikt dagegen. Ergebnis ok oder der Grund.
  SELECT * INTO l FROM ally_sicherung_laeufe x WHERE x.id = p_lauf AND x.ergebnis = 'laeuft' AND x.anlass = 'pruefen';
  IF NOT FOUND THEN RETURN 'kein laufender Prüf-Auftrag'; END IF;
  PERFORM 1 FROM ally_sicherung_ziele x WHERE x.art = l.art FOR UPDATE;
  z := ally_sicherung_ziel(l.art);
  IF z.sftp_host IS NULL THEN RETURN 'kein Ziel'; END IF;
  IF z.hostschluessel IS NOT NULL THEN RETURN 'schon gespeichert'; END IF;
  kopf := CASE WHEN z.sftp_port = 22 THEN z.sftp_host ELSE '[' || z.sftp_host || ']:' || z.sftp_port END;
  IF coalesce(p_zeile, '') !~ '^[^ ]+ (ssh-ed25519|ecdsa-sha2-nistp256|ecdsa-sha2-nistp384|ecdsa-sha2-nistp521|ssh-rsa) [A-Za-z0-9+/]{40,}={0,3}$' OR length(p_zeile) > 2000
     OR split_part(p_zeile, ' ', 1) IS DISTINCT FROM kopf THEN RETURN 'Hostschlüssel ungültig'; END IF;
  IF coalesce(p_fp, '') !~ '^SHA256:[A-Za-z0-9+/]{43}$' THEN RETURN 'Fingerabdruck ungültig'; END IF;
  UPDATE ally_sicherung_ziele x SET hostschluessel = p_zeile, hostschluessel_fp = p_fp, hostschluessel_am = now() WHERE x.art = l.art;
  IF NOT FOUND THEN RETURN 'kein Ziel'; END IF;
  RETURN 'ok';
END $function$;
CREATE OR REPLACE FUNCTION public.ally_sicherung_host_ende(p_lauf bigint, p_ergebnis text, p_groesse bigint, p_belegt bigint, p_staende integer, p_meldung text)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
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
    t := 'Die Sicherung vom ' || ally_sicherung_zeit(l.begonnen_am) || ' Uhr ' || CASE WHEN l.ergebnis = 'warnung' THEN 'ist mit einer Warnung beendet' ELSE 'ist fehlgeschlagen' END
      || coalesce(': ' || l.meldung, '.');
    FOR p IN SELECT x.matrix_user_id FROM ally_personen x WHERE x.aktiv
               AND coalesce(ally_hat_recht(x.matrix_user_id, CASE WHEN l.art = 'anbieter' THEN 'superadmin' ELSE 'admin' END), false) LOOP
      PERFORM ally_benachrichtigen(p.matrix_user_id, 'systemfehler', CASE WHEN l.ergebnis = 'warnung' THEN 'Sicherung mit Warnung' ELSE 'Sicherung fehlgeschlagen' END, t,
        jsonb_build_object('seite', 'einstellungen', 'parameter', jsonb_build_object('bereich', 'sicherung')), 'sicherung:' || l.id, 'Sicherung', false);
    END LOOP;
  END IF;
  DELETE FROM ally_sicherung_laeufe x WHERE x.art = l.art AND x.id NOT IN (SELECT y.id FROM ally_sicherung_laeufe y WHERE y.art = l.art ORDER BY y.begonnen_am DESC, y.id DESC LIMIT 200);
  RETURN 'ok';
END $function$;
DO $m$
BEGIN
  IF (SELECT count(*) FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname::text = 'public' COLLATE "C" AND c.relkind = 'r' AND c.relname::text COLLATE "C" = ANY (ARRAY['ally_sicherung_laeufe', 'ally_sicherung_server', 'ally_sicherung_ziele'])) <> 3 OR (SELECT md5(string_agg(z, E'\n' ORDER BY z COLLATE "C")) FROM (WITH t AS (SELECT c.oid, c.relname::text AS tab FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname::text = 'public' COLLATE "C" AND c.relkind::text = ANY (ARRAY['r', 'p']) AND c.relname::text = ANY (ARRAY['ally_sicherung_laeufe', 'ally_sicherung_server', 'ally_sicherung_ziele'])) SELECT 'S|' || t.tab || '|' || a.attname::text || '|' || format_type(a.atttypid, a.atttypmod) || '|' || CASE WHEN a.attnotnull THEN 'NN' ELSE '-' END || '|' || coalesce(pg_get_expr(d.adbin, d.adrelid), '') || '|' || a.attidentity::text || a.attgenerated::text AS z FROM t JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum > 0 AND NOT a.attisdropped LEFT JOIN pg_attrdef d ON d.adrelid = t.oid AND d.adnum = a.attnum UNION ALL SELECT 'C|' || t.tab || '|' || co.conname::text || '|' || co.contype::text || '|' || pg_get_constraintdef(co.oid) FROM t JOIN pg_constraint co ON co.conrelid = t.oid UNION ALL SELECT 'I|' || t.tab || '|' || ic.relname::text || '|' || pg_get_indexdef(i.indexrelid) FROM t JOIN pg_index i ON i.indrelid = t.oid JOIN pg_class ic ON ic.oid = i.indexrelid UNION ALL SELECT 'T|' || t.tab || '|' || tg.tgname::text || '|' || pg_get_triggerdef(tg.oid) || '|' || tg.tgenabled::text FROM t JOIN pg_trigger tg ON tg.tgrelid = t.oid AND NOT tg.tgisinternal) x) IS DISTINCT FROM '4d61775f5a8485822c7ff5c30815f9a1' THEN RAISE EXCEPTION 'Migration 201: Tabellen nicht wie gebaut'; END IF;
  IF (SELECT md5(string_agg(p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')|' || pg_get_function_result(p.oid) || '|' || md5(p.prosrc), E'\n' ORDER BY p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')' COLLATE "C")) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname::text = 'public' COLLATE "C" AND p.proname::text COLLATE "C" LIKE 'ally\_sicherung\_%') IS DISTINCT FROM 'a5836893209fb77c3dbdca628a473ac1' THEN RAISE EXCEPTION 'Migration 201: Funktionen ally_sicherung_* nicht wie gebaut'; END IF;
  IF ((SELECT count(*) FROM public.ally_sicherung_laeufe) + (SELECT count(*) FROM public.ally_sicherung_server) + (SELECT count(*) FROM public.ally_sicherung_ziele)) <> 0 THEN RAISE EXCEPTION 'Migration 201: neue Tabellen nicht leer'; END IF;
END $m$;
