-- Rückbau 200: geänderte Funktionen wörtlich wie vorher (werkzeuge/m200/vorher/), neue Funktionen entfernt, Spalte sichtbar_fuer_talent entfernt.
-- Nur auf dem Stand von 200. Nur als Ganzes in einer Transaktion.
-- Keine Daten gehen verloren: gesetzte Freigaben (true) kommen vorher in die Sicherungstabelle public.talent_freigaben_rb200 (Art, Eintrag, Talent, Zeitpunkt).
-- Bleibt bewusst: die Sicherungstabelle selbst (für ein erneutes Einspielen von Hand).
DO $m$
BEGIN
  IF (SELECT md5(string_agg(p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')|' || pg_get_function_result(p.oid) || '|' || md5(p.prosrc), E'\n' ORDER BY p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')' COLLATE "C")) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname::text = 'public' COLLATE "C" AND p.proname::text COLLATE "C" = ANY (ARRAY['talent_bericht_selbst_datei', 'talent_bericht_teilbar', 'talent_chat_kontext', 'talent_freigaben_ui', 'talent_fuer_talent_setzen', 'talent_mediakit_fuer_talent', 'talent_ui_daten', 'talent_ui_kacheln', 'talent_ui_link_oeffnen', 'talent_zugang_ui_aktion', 'talents_mediakit_abgelegt', 'talents_mediakit_selbst_datei', 'talents_mediakit_selbst_ui', 'talents_mediakit_ui_aktion'])) IS NOT DISTINCT FROM 'b7786ad69f19b58a955b380f04fa7271' AND (SELECT md5(string_agg(z, E'\n' ORDER BY z COLLATE "C")) FROM (WITH t AS (SELECT c.oid, c.relname::text AS tab FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname::text = 'public' COLLATE "C" AND c.relkind::text = ANY (ARRAY['r', 'p']) AND c.relname::text = ANY (ARRAY['talent_berichte', 'talent_kampagne_talents', 'talent_konzepte', 'talent_mediakits', 'talent_notizen'])) SELECT 'S|' || t.tab || '|' || a.attname::text || '|' || format_type(a.atttypid, a.atttypmod) || '|' || CASE WHEN a.attnotnull THEN 'NN' ELSE '-' END || '|' || coalesce(pg_get_expr(d.adbin, d.adrelid), '') || '|' || a.attidentity::text || a.attgenerated::text AS z FROM t JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum > 0 AND NOT a.attisdropped LEFT JOIN pg_attrdef d ON d.adrelid = t.oid AND d.adnum = a.attnum UNION ALL SELECT 'C|' || t.tab || '|' || co.conname::text || '|' || co.contype::text || '|' || pg_get_constraintdef(co.oid) FROM t JOIN pg_constraint co ON co.conrelid = t.oid UNION ALL SELECT 'I|' || t.tab || '|' || ic.relname::text || '|' || pg_get_indexdef(i.indexrelid) FROM t JOIN pg_index i ON i.indrelid = t.oid JOIN pg_class ic ON ic.oid = i.indexrelid UNION ALL SELECT 'T|' || t.tab || '|' || tg.tgname::text || '|' || pg_get_triggerdef(tg.oid) || '|' || tg.tgenabled::text FROM t JOIN pg_trigger tg ON tg.tgrelid = t.oid AND NOT tg.tgisinternal) x) IS NOT DISTINCT FROM '27fe92d8853bbf28193f7a97d993f0d9'
    THEN RAISE EXCEPTION 'Rückbau 200: schon zurückgebaut, nichts geändert'; END IF;
  IF (SELECT md5(string_agg(p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')|' || pg_get_function_result(p.oid) || '|' || md5(p.prosrc), E'\n' ORDER BY p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')' COLLATE "C")) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname::text = 'public' COLLATE "C" AND p.proname::text COLLATE "C" = ANY (ARRAY['talent_bericht_selbst_datei', 'talent_bericht_teilbar', 'talent_chat_kontext', 'talent_freigaben_ui', 'talent_fuer_talent_setzen', 'talent_mediakit_fuer_talent', 'talent_ui_daten', 'talent_ui_kacheln', 'talent_ui_link_oeffnen', 'talent_zugang_ui_aktion', 'talents_mediakit_abgelegt', 'talents_mediakit_selbst_datei', 'talents_mediakit_selbst_ui', 'talents_mediakit_ui_aktion'])) IS DISTINCT FROM '325ea87aee73eb7b22246d67bc2fe486' OR (SELECT md5(string_agg(z, E'\n' ORDER BY z COLLATE "C")) FROM (WITH t AS (SELECT c.oid, c.relname::text AS tab FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname::text = 'public' COLLATE "C" AND c.relkind::text = ANY (ARRAY['r', 'p']) AND c.relname::text = ANY (ARRAY['talent_berichte', 'talent_kampagne_talents', 'talent_konzepte', 'talent_mediakits', 'talent_notizen'])) SELECT 'S|' || t.tab || '|' || a.attname::text || '|' || format_type(a.atttypid, a.atttypmod) || '|' || CASE WHEN a.attnotnull THEN 'NN' ELSE '-' END || '|' || coalesce(pg_get_expr(d.adbin, d.adrelid), '') || '|' || a.attidentity::text || a.attgenerated::text AS z FROM t JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum > 0 AND NOT a.attisdropped LEFT JOIN pg_attrdef d ON d.adrelid = t.oid AND d.adnum = a.attnum UNION ALL SELECT 'C|' || t.tab || '|' || co.conname::text || '|' || co.contype::text || '|' || pg_get_constraintdef(co.oid) FROM t JOIN pg_constraint co ON co.conrelid = t.oid UNION ALL SELECT 'I|' || t.tab || '|' || ic.relname::text || '|' || pg_get_indexdef(i.indexrelid) FROM t JOIN pg_index i ON i.indrelid = t.oid JOIN pg_class ic ON ic.oid = i.indexrelid UNION ALL SELECT 'T|' || t.tab || '|' || tg.tgname::text || '|' || pg_get_triggerdef(tg.oid) || '|' || tg.tgenabled::text FROM t JOIN pg_trigger tg ON tg.tgrelid = t.oid AND NOT tg.tgisinternal) x) IS DISTINCT FROM '02494f012928d87c40f1ff31e60284ce' THEN RAISE EXCEPTION 'Rückbau 200: nicht im Stand von 200, nichts geändert'; END IF;
  PERFORM set_config('m200.daten', (SELECT md5(string_agg(z, E'\n' ORDER BY z COLLATE "C")) FROM (SELECT 'talent_berichte|' || coalesce(md5(string_agg((to_jsonb(x) - 'sichtbar_fuer_talent')::text, E'\n' ORDER BY (to_jsonb(x) - 'sichtbar_fuer_talent')::text COLLATE "C")), '-') AS z FROM public.talent_berichte x UNION ALL SELECT 'talent_kampagne_talents|' || coalesce(md5(string_agg((to_jsonb(x) - 'sichtbar_fuer_talent')::text, E'\n' ORDER BY (to_jsonb(x) - 'sichtbar_fuer_talent')::text COLLATE "C")), '-') AS z FROM public.talent_kampagne_talents x UNION ALL SELECT 'talent_konzepte|' || coalesce(md5(string_agg((to_jsonb(x) - 'sichtbar_fuer_talent')::text, E'\n' ORDER BY (to_jsonb(x) - 'sichtbar_fuer_talent')::text COLLATE "C")), '-') AS z FROM public.talent_konzepte x UNION ALL SELECT 'talent_mediakits|' || coalesce(md5(string_agg((to_jsonb(x) - 'sichtbar_fuer_talent')::text, E'\n' ORDER BY (to_jsonb(x) - 'sichtbar_fuer_talent')::text COLLATE "C")), '-') AS z FROM public.talent_mediakits x UNION ALL SELECT 'talent_notizen|' || coalesce(md5(string_agg((to_jsonb(x) - 'sichtbar_fuer_talent')::text, E'\n' ORDER BY (to_jsonb(x) - 'sichtbar_fuer_talent')::text COLLATE "C")), '-') AS z FROM public.talent_notizen x) y), true);
  PERFORM set_config('m200.frei', (SELECT coalesce(md5(string_agg(f.art || '|' || f.eintrag || '|' || coalesce(f.talent_id::text, ''), E'\n' ORDER BY f.art || '|' || f.eintrag || '|' || coalesce(f.talent_id::text, '') COLLATE "C")), '-') FROM (SELECT 'bericht'::text AS art, x.id::text AS eintrag, NULL::integer AS talent_id FROM public.talent_berichte x WHERE x.sichtbar_fuer_talent UNION ALL SELECT 'kampagne', x.kampagne_id::text, x.talent_id FROM public.talent_kampagne_talents x WHERE x.sichtbar_fuer_talent UNION ALL SELECT 'konzept', x.id::text, x.talent_id FROM public.talent_konzepte x WHERE x.sichtbar_fuer_talent UNION ALL SELECT 'mediakit', x.talent_id::text, x.talent_id FROM public.talent_mediakits x WHERE x.sichtbar_fuer_talent UNION ALL SELECT 'notiz', x.id::text, x.talent_id FROM public.talent_notizen x WHERE x.sichtbar_fuer_talent) f), true);
END $m$;
CREATE TABLE IF NOT EXISTS public.talent_freigaben_rb200 (art text NOT NULL, eintrag text NOT NULL, talent_id integer, gesichert_am timestamptz NOT NULL DEFAULT now());
COMMENT ON TABLE public.talent_freigaben_rb200 IS 'Rückbau 200: Freigaben je Eintrag (sichtbar_fuer_talent = true) vor dem Entfernen der Spalte';
INSERT INTO public.talent_freigaben_rb200 (art, eintrag, talent_id) SELECT f.art, f.eintrag, f.talent_id FROM (SELECT 'bericht'::text AS art, x.id::text AS eintrag, NULL::integer AS talent_id FROM public.talent_berichte x WHERE x.sichtbar_fuer_talent UNION ALL SELECT 'kampagne', x.kampagne_id::text, x.talent_id FROM public.talent_kampagne_talents x WHERE x.sichtbar_fuer_talent UNION ALL SELECT 'konzept', x.id::text, x.talent_id FROM public.talent_konzepte x WHERE x.sichtbar_fuer_talent UNION ALL SELECT 'mediakit', x.talent_id::text, x.talent_id FROM public.talent_mediakits x WHERE x.sichtbar_fuer_talent UNION ALL SELECT 'notiz', x.id::text, x.talent_id FROM public.talent_notizen x WHERE x.sichtbar_fuer_talent) f;
DO $m$
BEGIN
  IF current_setting('m200.frei') IS DISTINCT FROM (SELECT coalesce(md5(string_agg(r.art || '|' || r.eintrag || '|' || coalesce(r.talent_id::text, ''), E'\n' ORDER BY r.art || '|' || r.eintrag || '|' || coalesce(r.talent_id::text, '') COLLATE "C")), '-') FROM public.talent_freigaben_rb200 r WHERE r.gesichert_am = now()) THEN RAISE EXCEPTION 'Rückbau 200: Sicherung der Freigaben unvollständig, nichts geändert'; END IF;
END $m$;
ALTER TABLE public.talent_berichte DROP COLUMN sichtbar_fuer_talent;
ALTER TABLE public.talent_kampagne_talents DROP COLUMN sichtbar_fuer_talent;
ALTER TABLE public.talent_konzepte DROP COLUMN sichtbar_fuer_talent;
ALTER TABLE public.talent_mediakits DROP COLUMN sichtbar_fuer_talent;
ALTER TABLE public.talent_notizen DROP COLUMN sichtbar_fuer_talent;
CREATE OR REPLACE FUNCTION public.talent_chat_kontext(p_talent_id integer)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
  sicht jsonb := talent_bereich_sicht(p_talent_id); b talent_bereich%ROWTYPE; pl jsonb; res jsonb; zr jsonb; kids integer[]; zz record; ok boolean;
BEGIN
  -- Daten eines Talents für den Talent-Chat (BA9): dieselben Inhalte wie im Talent-Bereich (talent_ui_daten), nur was die zuständige Person freigegeben hat,
  -- ohne Honorare, Budgets, Links und interne Kennungen (talent_chat_ohne_betraege). Aufruf nur aus talent_chat_eingang mit der Talent-ID aus dem Absender.
  SELECT * INTO b FROM talent_bereich x WHERE x.talent_id = p_talent_id;
  pl := talent_selbst_planung(p_talent_id, false);
  ok := coalesce((pl->>'ok')::boolean, false);
  res := jsonb_build_object('name', talent_anzeigename(p_talent_id), 'agentur', nullif(btrim(coalesce(eigenes_unternehmen()->>'name', '')), ''),
    'ansprechpersonen', (SELECT coalesce(jsonb_agg(p.name ORDER BY lower(p.name), p.matrix_user_id), '[]'::jsonb) FROM talent_personen tp
                         JOIN ally_personen p ON p.matrix_user_id = tp.matrix_user_id AND p.aktiv WHERE tp.talent_id = p_talent_id),
    'heute', to_char(now() AT TIME ZONE 'Europe/Berlin', 'DD.MM.YYYY'));
  IF (sicht->>'briefing')::boolean THEN
    res := res || jsonb_build_object('briefing', nullif(btrim(coalesce(b.briefing, '')), ''), 'briefing_stand', CASE WHEN b.briefing_am IS NOT NULL THEN talents_datum(b.briefing_am) END);
  END IF;
  IF (sicht->>'aufgaben')::boolean AND ok THEN
    res := res || jsonb_build_object('aufgaben', (SELECT coalesce(jsonb_agg(a), '[]'::jsonb) FROM jsonb_array_elements(pl->'aufgaben') a WHERE a->>'art' IN ('aufgabe', 'review')),
      'deliverables', pl->'deliverables');
  END IF;
  IF (sicht->>'termine')::boolean AND ok THEN
    res := res || jsonb_build_object('termine', pl->'termine',
      'erinnerungen', (SELECT coalesce(jsonb_agg(a), '[]'::jsonb) FROM jsonb_array_elements(pl->'aufgaben') a WHERE a->>'art' = 'erinnerung'));
  END IF;
  IF (sicht->>'kampagnen')::boolean AND ok THEN
    res := res || jsonb_build_object('kampagnen', pl->'kampagnen');
  END IF;
  IF (sicht->>'dateien')::boolean THEN
    res := res || jsonb_build_object('dateien_im_talent_bereich', CASE WHEN ok THEN (SELECT coalesce(jsonb_agg(jsonb_build_object('titel', l.titel, 'kampagne', k.marke || ' – ' || k.name,
        'dienst', talents_planung_dienst_text(l.dienst)) ORDER BY k.von, k.id, l.id), '[]'::jsonb)
      FROM talent_kampagne_links l JOIN talent_kampagnen k ON k.id = l.kampagne_id
      WHERE (k.id)::text IN (SELECT x->>'id' FROM jsonb_array_elements(pl->'kampagnen') x)) END,
      'geteilte_ordner', (SELECT coalesce(jsonb_agg(o.name ORDER BY lower(o.name), o.id), '[]'::jsonb) FROM talent_ordner o
        WHERE o.talent_id = p_talent_id AND o.beendet_am IS NULL AND o.speicherort = 'eigen'));
  END IF;
  IF (sicht->>'zahlen')::boolean THEN
    zr := talents_zeitraum('{}'::jsonb, '28tage', false);
    kids := ARRAY(SELECT k.id FROM talent_kanaele k WHERE k.talent_id = p_talent_id AND k.status IN ('verbunden', 'abgelaufen') AND NOT meta_loeschung_offen(k.id));
    SELECT * INTO zz FROM talents_zahlen(kids, (zr->>'von')::date, (zr->>'bis')::date, ARRAY[p_talent_id], '', true);
    res := res || jsonb_build_object('zahlen', jsonb_build_object('zeitraum', zr->>'text', 'verbundene_accounts', cardinality(kids),
      'follower', talents_wert(zz.follower)->>'text', 'reichweite', talents_wert(zz.reichweite)->>'text', 'aufrufe', talents_wert(zz.aufrufe)->>'text',
      'interaktionen', talents_wert(zz.interaktionen)->>'text', 'werte_aus_screenshots', coalesce(zz.manuell_anzahl, 0)));
  END IF;
  IF (sicht->>'accounts')::boolean THEN
    res := res || jsonb_build_object('accounts', (SELECT coalesce(jsonb_agg(jsonb_build_object('plattform', talents_plattform_name(k.plattform),
        'konto', nullif(btrim(coalesce(k.extern_name, '')), ''), 'status', k.status,
        'tage_bis_ablauf', CASE WHEN k.status = 'verbunden' AND k.gueltig_bis IS NOT NULL THEN greatest(0, (k.gueltig_bis::date - talents_heute())) END) ORDER BY k.plattform, k.id), '[]'::jsonb)
      FROM talent_kanaele k WHERE k.talent_id = p_talent_id AND k.status IN ('verbunden', 'abgelaufen') AND NOT meta_loeschung_offen(k.id)));
  END IF;
  RETURN talent_chat_ohne_betraege(res);
END $function$;
CREATE OR REPLACE FUNCTION public.talent_ui_daten(p_token text)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
  s record; sicht jsonb; pl jsonb; zr jsonb; kids integer[]; zz record; b talent_bereich%ROWTYPE; res jsonb; firma text;
BEGIN
  -- Daten der Talent-Ansicht (BA7, ALLY 38). Talent-ID nur aus der Sitzung. Nur Daten dieses Talents, nur was das Management freigegeben hat,
  -- keine Honorare und Budgets, Zahlen ohne Vergleich mit anderen Talents. Ohne Talent-Sitzung: ok = false (wie abgelaufen).
  SELECT * INTO s FROM talent_web_sitzung(p_token);
  IF NOT FOUND THEN RETURN jsonb_build_object('ok', false, 'angemeldet', false); END IF;
  sicht := talent_bereich_sicht(s.talent_id);
  SELECT * INTO b FROM talent_bereich x WHERE x.talent_id = s.talent_id;
  pl := talent_selbst_planung(s.talent_id, false);
  firma := nullif(btrim(coalesce(eigenes_unternehmen()->>'name', '')), '');
  res := jsonb_build_object('ok', true, 'angemeldet', true, 'name', coalesce(talent_anzeigename(s.talent_id), s.name), 'firma', firma, 'sicht', sicht,
    'ansprechpersonen', (SELECT coalesce(jsonb_agg(p.name ORDER BY lower(p.name), p.matrix_user_id), '[]'::jsonb) FROM talent_personen tp
                         JOIN ally_personen p ON p.matrix_user_id = tp.matrix_user_id AND p.aktiv WHERE tp.talent_id = s.talent_id),
    'chat_benutzer', s.matrix_user_id);
  IF (sicht->>'briefing')::boolean THEN
    res := res || jsonb_build_object('briefing', jsonb_build_object('text', nullif(btrim(coalesce(b.briefing, '')), ''), 'am', CASE WHEN b.briefing_am IS NOT NULL THEN talents_datum(b.briefing_am) END));
  END IF;
  IF (sicht->>'aufgaben')::boolean AND coalesce((pl->>'ok')::boolean, false) THEN
    res := res || jsonb_build_object('aufgaben', (SELECT coalesce(jsonb_agg(a), '[]'::jsonb) FROM jsonb_array_elements(pl->'aufgaben') a WHERE a->>'art' IN ('aufgabe', 'review')),
      -- Deliverables mit der Nummer der letzten Version (Link öffnen über die Seite „link“), ohne den Link selbst
      'deliverables', (SELECT coalesce(jsonb_agg((x.d #- '{letzte_version,link}') || jsonb_build_object('version_id',
          (SELECT v.id FROM talent_deliverable_versionen v WHERE v.deliverable_id = (x.d->>'id')::bigint ORDER BY v.version DESC LIMIT 1)) ORDER BY x.o), '[]'::jsonb)
        FROM jsonb_array_elements(pl->'deliverables') WITH ORDINALITY AS x(d, o)));
  END IF;
  IF (sicht->>'termine')::boolean AND coalesce((pl->>'ok')::boolean, false) THEN
    res := res || jsonb_build_object('termine', pl->'termine',
      'erinnerungen', (SELECT coalesce(jsonb_agg(a), '[]'::jsonb) FROM jsonb_array_elements(pl->'aufgaben') a WHERE a->>'art' = 'erinnerung'));
  END IF;
  IF (sicht->>'kampagnen')::boolean AND coalesce((pl->>'ok')::boolean, false) THEN
    res := res || jsonb_build_object('kampagnen', (SELECT coalesce(jsonb_agg(k - 'links'), '[]'::jsonb) FROM jsonb_array_elements(pl->'kampagnen') k));
  END IF;
  IF (sicht->>'dateien')::boolean AND coalesce((pl->>'ok')::boolean, false) THEN
    -- Dateien der Kampagnen (Links beim Cloud-Dienst), nur Kampagnen, in denen das Talent sichtbare Deliverables hat; geöffnet über die Seite „link“
    res := res || jsonb_build_object('dateien', (SELECT coalesce(jsonb_agg(jsonb_build_object('id', l.id, 'titel', l.titel, 'kampagne', k.marke || ' – ' || k.name,
        'dienst_text', talents_planung_dienst_text(l.dienst)) ORDER BY k.von, k.id, l.id), '[]'::jsonb)
      FROM talent_kampagne_links l JOIN talent_kampagnen k ON k.id = l.kampagne_id
      WHERE (k.id)::text IN (SELECT x->>'id' FROM jsonb_array_elements(pl->'kampagnen') x)));
  END IF;
  IF (sicht->>'zahlen')::boolean THEN
    zr := talents_zeitraum('{}'::jsonb, '28tage', false);
    kids := ARRAY(SELECT k.id FROM talent_kanaele k WHERE k.talent_id = s.talent_id AND k.status IN ('verbunden', 'abgelaufen') AND NOT meta_loeschung_offen(k.id));
    -- Migration 65: bestätigte manuelle Werte des eigenen Talents zählen mit (ohne Doppelzählung; Talent-ID nur aus der Sitzung)
    SELECT * INTO zz FROM talents_zahlen(kids, (zr->>'von')::date, (zr->>'bis')::date, ARRAY[s.talent_id], '', true);
    res := res || jsonb_build_object('zahlen', jsonb_build_object('zeitraum', zr->>'text', 'konten', cardinality(kids), 'manuell', coalesce(zz.manuell_anzahl, 0),
      'follower', talents_wert(zz.follower), 'reichweite', talents_wert(zz.reichweite), 'aufrufe', talents_wert(zz.aufrufe), 'interaktionen', talents_wert(zz.interaktionen)));
  END IF;
  IF (sicht->>'accounts')::boolean THEN
    res := res || jsonb_build_object('accounts', (SELECT coalesce(jsonb_agg(jsonb_build_object('plattform', p.pl, 'name', talents_plattform_name(p.pl),
        'bereit', talent_plattform_bereit(p.pl),
        'hinweise', (SELECT coalesce(jsonb_agg(talents_weg_hinweis(p.pl, w) ORDER BY n), '[]'::jsonb) FROM unnest(talent_wege(p.pl)) WITH ORDINALITY AS x(w, n)
                     WHERE talents_weg_hinweis(p.pl, w) IS NOT NULL),
        'konten', (SELECT coalesce(jsonb_agg(jsonb_build_object('kanal_id', k.id, 'text', CASE WHEN nullif(btrim(coalesce(k.extern_name, '')), '') IS NOT NULL
              THEN talents_konto_text(k.plattform, k.extern_name, NULL) ELSE talents_plattform_name(k.plattform) END,
            'status', k.status,
            'tage', CASE WHEN k.status = 'verbunden' AND k.gueltig_bis IS NOT NULL THEN greatest(0, (k.gueltig_bis::date - talents_heute())) END,
            'weg_text', CASE WHEN k.plattform = 'instagram' THEN CASE k.anmeldeweg WHEN 'facebook' THEN 'über Facebook' WHEN 'instagram' THEN 'direkt über Instagram' END END)
          ORDER BY k.status = 'verbunden' DESC, k.id), '[]'::jsonb)
          FROM talent_kanaele k WHERE k.talent_id = s.talent_id AND k.plattform = p.pl AND k.status IN ('verbunden', 'abgelaufen') AND NOT meta_loeschung_offen(k.id)))
        ORDER BY p.o), '[]'::jsonb)
      FROM unnest(talents_plattformen()) WITH ORDINALITY AS p(pl, o)),
      'zahlen_upload', CASE WHEN coalesce((sicht->>'upload')::boolean, false) THEN jsonb_build_object('in_pruefung', (SELECT count(*) FROM talent_manuell_vorschlaege v WHERE v.talent_id = s.talent_id AND v.erstellt_von IS NULL
         AND v.quelle = 'hochladen' AND v.status IN ('auslesen', 'offen') AND v.quelle_text LIKE 'Vom Talent%'),
        'ki_bereit', NOT ki_gesperrt()) END);
  END IF;
  RETURN res;
END $function$;
CREATE OR REPLACE FUNCTION public.talent_ui_link_oeffnen(p_token text, p_art text, p_id text)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
  s record; lk text; pl jsonb; sicht jsonb;
BEGIN
  -- Link öffnen in der Talent-Ansicht (BA7, ALLY 20 Seite „link“): NULL ohne Talent-Sitzung (dann gilt talents_planung_link_oeffnen).
  -- kl = Datei einer eigenen Kampagne (mit sichtbaren Deliverables), v = eigener eingereichter Entwurf. Nur https-Links aus der Datenbank.
  SELECT * INTO s FROM talent_web_sitzung(p_token);
  IF NOT FOUND THEN RETURN NULL; END IF;
  IF coalesce(p_id, '') !~ '^[0-9]{1,15}$' THEN RETURN jsonb_build_object('ok', false); END IF;
  sicht := talent_bereich_sicht(s.talent_id);
  IF p_art = 'kl' AND (sicht->>'dateien')::boolean THEN
    pl := talent_selbst_planung(s.talent_id, false);
    SELECT l.link INTO lk FROM talent_kampagne_links l WHERE l.id = p_id::bigint
      AND (l.kampagne_id)::text IN (SELECT x->>'id' FROM jsonb_array_elements(CASE WHEN (pl->>'ok')::boolean THEN pl->'kampagnen' ELSE '[]'::jsonb END) x);
  ELSIF p_art = 'v' AND (sicht->>'aufgaben')::boolean THEN
    SELECT v.link INTO lk FROM talent_deliverable_versionen v JOIN talent_deliverables d ON d.id = v.deliverable_id
    WHERE v.id = p_id::bigint AND d.talent_id = s.talent_id AND d.sichtbar_fuer_talent;
  END IF;
  lk := talents_planung_link(lk);
  RETURN jsonb_build_object('ok', lk IS NOT NULL, 'url', lk);
END $function$;
CREATE OR REPLACE FUNCTION public.talent_zugang_ui_aktion(p_token text, p_aktion text, p_daten jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
  s record;
  d jsonb := CASE WHEN jsonb_typeof(p_daten) = 'object' THEN p_daten ELSE '{}'::jsonb END;
  tid integer; z talent_zugaenge%ROWTYPE; em text; tok text; bis timestamptz; m text := NULL; fehler text := NULL; br text; tname text; n integer; pu text;
  nro text; soll jsonb; alt_b text := coalesce(current_setting('ally.talent_bruecke', true), '');
BEGIN
  -- Zugang und Talent-Bereich verwalten (BA7, über ally_ui_aktion tz_*): Admin oder zuständige Person aus dem Management.
  -- tz_einladen (talent_id, email): Zugang anlegen oder neuen Zugangslink erstellen (Link nur in der Oberfläche zum Kopieren; es wird keine Mail verschickt),
  -- tz_sperren / tz_freigeben (talent_id), tz_sicht (talent_id, zeige_*), tz_briefing (talent_id, briefing). Meldung setzt die Funktion selbst.
  -- BA8 (Migration 63): Mit eingestelltem Absender-Postfach geht der Zugangslink zusätzlich per Mail an das Talent (Vormerkung, Versand SYS 9);
  -- tz_link_senden (gültigen Link erneut per Mail), tz_kalender_widerrufen (Kalender-Abo des Talents beenden).
  -- Migration 64: Recht „Talent-Zugang und Talent-Bereich einstellen“ (talent_zugang_darf); tz_sicht mit zeige_upload (fehlt das Feld, bleibt der Wert).
  SELECT * INTO s FROM ally_ui_sitzung(p_token);
  IF NOT FOUND OR s.muss_pw_setzen THEN RETURN jsonb_build_object('ok', false, 'angemeldet', false); END IF;
  -- Migration 65 (Stefan 20.10.2026): doppelte Daten entscheiden (tz_dd_automatisch, tz_dd_manuell; talent_id, doppelt_id). Rechte und Meldung: talents_doppelt_entscheiden
  IF p_aktion IN ('tz_dd_automatisch', 'tz_dd_manuell') THEN RETURN talents_doppelt_entscheiden(p_token, p_aktion, d); END IF;
  tid := CASE WHEN coalesce(d->>'talent_id', '') ~ '^[0-9]{1,9}$' THEN (d->>'talent_id')::integer END;
  IF tid IS NULL OR NOT talent_zugang_darf(s.person, tid) THEN
    fehler := 'Das darf, wer für dieses Talent das Recht „Talent-Zugang und Talent-Bereich einstellen“ hat.';
  ELSE
    tname := coalesce(talent_listenname(tid), 'Talent');
    SELECT * INTO z FROM talent_zugaenge x WHERE x.talent_id = tid FOR UPDATE;
    IF p_aktion = 'tz_einladen' THEN
      em := lower(btrim(coalesce(d->>'email', '')));
      IF NOT EXISTS (SELECT 1 FROM talents t WHERE t.id = tid AND t.status = 'aktiv') THEN
        fehler := 'Talents im Papierkorb bekommen keinen Zugang.';
      ELSIF z.id IS NOT NULL AND NOT z.aktiv THEN
        fehler := 'Der Zugang ist gesperrt. Bitte ihn zuerst freischalten.';
      ELSIF em !~ '^[^[:space:]@]{1,200}@[^[:space:]@]{1,200}\.[^[:space:]@.]{1,63}$' OR length(em) > 254 THEN
        fehler := 'Bitte eine gültige E-Mail-Adresse angeben.';
      ELSIF NOT talent_zugang_email_frei(em, z.id) THEN
        fehler := 'Diese E-Mail-Adresse wird schon für einen anderen Zugang genutzt.';
      -- Migration 165 (Bauplan B5c): Beim Einrichten des Zugangs ist die vorgemerkte Rolle änderbar (Stefan G10; nur aktive Rollen der Art talent).
      ELSIF z.id IS NULL AND nullif(btrim(coalesce(d->>'rolle', '')), '') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM ally_rollen r WHERE r.schluessel = btrim(d->>'rolle') AND r.art = 'talent' AND r.archiviert_am IS NULL) THEN
        fehler := 'Diese Rolle gibt es nicht oder sie ist archiviert. Bitte eine andere wählen.';
      ELSIF NOT ally_verschluesselung_bereit() OR talent_ui_adresse() IS NULL THEN
        fehler := 'Der Zugangslink kann gerade nicht erstellt werden (Verschlüsselung oder öffentliche Adresse nicht eingerichtet).';
      ELSE
        tok := encode(gen_random_bytes(32), 'hex');
        bis := now() + make_interval(days => talents_einladung_tage());
        IF z.id IS NULL THEN
          IF nullif(btrim(coalesce(d->>'rolle', '')), '') IS NOT NULL THEN
            UPDATE talents SET rolle = btrim(d->>'rolle'), geaendert_am = now(), geaendert_von = s.person WHERE id = tid AND rolle IS DISTINCT FROM btrim(d->>'rolle');
          END IF;
          INSERT INTO talent_zugaenge (talent_id, email, einladung_hash, einladung_verschluesselt, einladung_bis, erstellt_von, geaendert_von)
          VALUES (tid, em, ally_web_hash(tok), ally_verschluesseln(tok), bis, s.person, s.person);
        ELSE
          -- Migration 159 (Bauplan B3b): die E-Mail-Adresse steht an der Person (die Brücke schreibt sie in den Zugang); der Link bleibt am Zugang.
          IF z.email IS DISTINCT FROM em THEN PERFORM talent_person_aendern(tid, jsonb_build_object('email', em)); END IF;
          UPDATE talent_zugaenge SET einladung_hash = ally_web_hash(tok), einladung_verschluesselt = ally_verschluesseln(tok), einladung_bis = bis,
            geaendert_am = now(), geaendert_von = s.person WHERE id = z.id;
        END IF;
        -- Migration 168 (Bauplan B7): Test-Talents bekommen keine Mail, der Link steht nur zum Kopieren
        IF ally_systemnachricht_aktiv() AND NOT coalesce(talents_ist_testdaten(tid), false) THEN
          SELECT * INTO z FROM talent_zugaenge x WHERE x.talent_id = tid;
          INSERT INTO ally_systemnachrichten (art, ref, talent_id, geheim, gueltig_bis, erstellt_von)
          VALUES ('zugang_talent', 'zugang_talent:' || z.id || ':' || left(ally_web_hash(tok), 16), tid, ally_verschluesseln(tok), least(bis, now() + interval '1 day'), s.person)
          ON CONFLICT (ref) DO NOTHING;
          m := 'Zugangslink für ' || tname || ' erstellt (gültig bis ' || talents_zeit(bis) || ') und per Mail an ' || em || ' vorgemerkt; die Mail geht in etwa einer Minute raus. Er steht außerdem im Abschnitt „Talent-Bereich“ zum Kopieren.';
        ELSE
          m := 'Zugangslink für ' || tname || ' erstellt (gültig bis ' || talents_zeit(bis) || '). Er steht im Abschnitt „Talent-Bereich“ zum Kopieren; bitte selbst an das Talent weitergeben.';
        END IF;
      END IF;
    ELSIF p_aktion IN ('tz_sperren', 'tz_freigeben') THEN
      IF z.id IS NULL THEN
        fehler := 'Für dieses Talent gibt es noch keinen Zugang.';
      ELSIF p_aktion = 'tz_sperren' THEN
        -- Migration 159 (Bauplan B3b): „Zugang aktiv“ steht an der Person (die Brücke schreibt ihn in den Zugang).
        PERFORM talent_person_aendern(tid, jsonb_build_object('zugang_aktiv', false));
        UPDATE talent_zugaenge SET geaendert_am = now(), geaendert_von = s.person WHERE id = z.id;
        -- Migration 160 (Bauplan B4a): Sitzungen der Talent-Person enden.
        DELETE FROM ally_web_sitzungen WHERE matrix_user_id = 'talent:' || tid;
        m := 'Zugang von ' || tname || ' gesperrt. Offene Sitzungen sind beendet.';
      ELSE
        PERFORM talent_person_aendern(tid, jsonb_build_object('zugang_aktiv', true, 'fehlversuche', 0, 'gesperrt_bis', NULL::timestamptz));
        UPDATE talent_zugaenge SET geaendert_am = now(), geaendert_von = s.person WHERE id = z.id;
        m := 'Zugang von ' || tname || ' freigeschaltet.';
      END IF;
    ELSIF p_aktion = 'tz_sicht' THEN
      -- Migration 162 (Bauplan B5a): Hat das Talent eine Talent-Person, schreibt das Formular ihre Ausnahmen zur Rolle (eine Quelle, F6).
      -- Die Schalter bleiben nur die Vorgabe für ein Talent ohne Person (beim Anlegen der Person übernimmt sie talent_person_rechte_abgleichen).
      SELECT p.matrix_user_id INTO pu FROM ally_personen p WHERE p.talent_id = tid AND ally_person_ist_talent(p.matrix_user_id);
      IF pu IS NOT NULL THEN
        -- Migration 163 (Bauplan B5b): Rolle und Ausnahmen (F5–F7). Eine geänderte Rolle wird allein gespeichert (nur Rollen der Art talent; die Ausnahmen
        -- bleiben und gelten zur neuen Rolle). Sonst werden die Häkchen zu Ausnahmen; fehlt ein Häkchen im Formular (Hochladen, Ally-Chat), bleibt der Stand.
        -- Ally-Chat ist eine Erlaubnis (Stefan G12): Solange der Chat an ist, lässt sie sich nicht wegnehmen. „Eigenes Profil“ kommt immer aus der Rolle.
        nro := nullif(btrim(coalesce(d->>'rolle', '')), '');
        IF nro IS NOT DISTINCT FROM (SELECT p.rolle FROM ally_personen p WHERE p.matrix_user_id = pu) THEN nro := NULL; END IF;
        SELECT jsonb_object_agg(x.recht, CASE WHEN d ? x.feld THEN coalesce(d->>x.feld, '') = '1' ELSE talent_person_hat(pu, x.recht) END) INTO soll
        FROM (VALUES ('zeige_briefing', 'talent_briefing'), ('zeige_aufgaben', 'talent_aufgaben'), ('zeige_termine', 'talent_termine'), ('zeige_zahlen', 'talent_zahlen'), ('zeige_accounts', 'talent_accounts'), ('zeige_upload', 'talent_upload'), ('zeige_kampagnen', 'talent_kampagnen'), ('zeige_dateien', 'talent_dateien'), ('zeige_chat', 'talent_chat')) x(feld, recht);
        IF nro IS NOT NULL AND NOT EXISTS (SELECT 1 FROM ally_rollen r WHERE r.schluessel = nro AND r.art = 'talent' AND r.archiviert_am IS NULL) THEN
          fehler := 'Diese Rolle gibt es nicht oder sie ist archiviert. Bitte eine andere wählen.';
        ELSIF coalesce((SELECT c.chat_an FROM talent_chat c WHERE c.talent_id = tid), false)
          AND (CASE WHEN nro IS NOT NULL THEN NOT EXISTS (SELECT 1 FROM ally_rollen_rechte rr WHERE rr.rolle = nro AND rr.recht = 'talent_chat')
                     AND NOT EXISTS (SELECT 1 FROM ally_person_rechte x WHERE x.person = pu AND x.recht = 'talent_chat' AND x.wirkung = 'plus')
                   ELSE NOT (soll->>'talent_chat')::boolean END) THEN
          fehler := 'Der Ally-Chat ist für ' || tname || ' eingeschaltet. Bitte ihn zuerst unten unter „Ally-Chat“ ausschalten.';
        ELSIF nro IS NOT NULL THEN
          PERFORM set_config('ally.talent_bruecke', 'an', true);
          UPDATE ally_personen p SET rolle = nro, geaendert_am = now() WHERE p.matrix_user_id = pu;
          PERFORM set_config('ally.talent_bruecke', alt_b, true);
        ELSE
          PERFORM ally_person_ausnahme_setzen(pu, e.key, e.value::boolean, s.person) FROM jsonb_each_text(soll) e;
        END IF;
      ELSE
      -- Migration 165 (Bauplan B5c): ohne Zugang sind Häkchen für Rechte, die die vorgemerkte Rolle nicht hat, gesperrt (nur Anzeige, Prüfbericht M165 M1).
      -- Ihre Schalter bleiben, wie sie sind (ohne Zeile: an); sonst entstünden beim Einrichten des Zugangs mit einer anderen Rolle stille minus.
      SELECT d || coalesce(jsonb_object_agg(x.feld, CASE WHEN coalesce((to_jsonb(b) ->> x.feld)::boolean, true) THEN '1' ELSE '' END), '{}'::jsonb) INTO d
      FROM (VALUES ('zeige_briefing', 'talent_briefing'), ('zeige_aufgaben', 'talent_aufgaben'), ('zeige_termine', 'talent_termine'), ('zeige_zahlen', 'talent_zahlen'),
                   ('zeige_accounts', 'talent_accounts'), ('zeige_upload', 'talent_upload'), ('zeige_kampagnen', 'talent_kampagnen'), ('zeige_dateien', 'talent_dateien')) x(feld, recht)
      LEFT JOIN talent_bereich b ON b.talent_id = tid
      WHERE NOT EXISTS (SELECT 1 FROM ally_rollen r JOIN ally_rollen_rechte rr ON rr.rolle = r.schluessel AND rr.recht = x.recht
                        WHERE r.schluessel = talent_rolle_vorgabe(tid) AND r.archiviert_am IS NULL);
      INSERT INTO talent_bereich (talent_id, zeige_briefing, zeige_aufgaben, zeige_termine, zeige_zahlen, zeige_accounts, zeige_kampagnen, zeige_dateien, zeige_upload, geaendert_von)
      VALUES (tid, coalesce(d->>'zeige_briefing', '') = '1', coalesce(d->>'zeige_aufgaben', '') = '1', coalesce(d->>'zeige_termine', '') = '1', coalesce(d->>'zeige_zahlen', '') = '1', coalesce(d->>'zeige_accounts', '') = '1',
              coalesce(d->>'zeige_kampagnen', '') = '1', coalesce(d->>'zeige_dateien', '') = '1', CASE WHEN d ? 'zeige_upload' THEN coalesce(d->>'zeige_upload', '') = '1' ELSE true END, s.person)
      ON CONFLICT (talent_id) DO UPDATE SET zeige_briefing = EXCLUDED.zeige_briefing, zeige_aufgaben = EXCLUDED.zeige_aufgaben, zeige_termine = EXCLUDED.zeige_termine,
        zeige_zahlen = EXCLUDED.zeige_zahlen, zeige_accounts = EXCLUDED.zeige_accounts, zeige_kampagnen = EXCLUDED.zeige_kampagnen, zeige_dateien = EXCLUDED.zeige_dateien,
        zeige_upload = CASE WHEN d ? 'zeige_upload' THEN EXCLUDED.zeige_upload ELSE talent_bereich.zeige_upload END,
        geaendert_am = now(), geaendert_von = s.person;
      END IF;
      m := CASE WHEN nro IS NOT NULL THEN 'Rolle gespeichert. Die Ausnahmen gelten weiter für dieses Talent.' ELSE 'Gespeichert: Rolle und Ausnahmen.' END;
    ELSIF p_aktion = 'tz_link_senden' THEN
      IF NOT ally_systemnachricht_aktiv() THEN
        fehler := 'Es ist kein Absender-Postfach eingestellt. Bitte den Link kopieren und selbst weitergeben.';
      -- Migration 168 (Bauplan B7): Testdaten lösen keine Mails aus
      ELSIF coalesce(talents_ist_testdaten(tid), false) THEN
        fehler := 'Testdaten lösen keine Mails aus. Bitte den Link kopieren und selbst weitergeben.';
      ELSIF z.id IS NULL OR NOT z.aktiv OR z.einladung_verschluesselt IS NULL OR z.einladung_bis IS NULL OR z.einladung_bis <= now() THEN
        fehler := 'Es gibt keinen gültigen Zugangslink. Bitte einen neuen erstellen.';
      ELSIF EXISTS (SELECT 1 FROM ally_systemnachrichten x WHERE x.art = 'zugang_talent' AND x.talent_id = tid AND x.erstellt_am > now() - interval '10 minutes') THEN
        fehler := 'Der Zugangslink wurde gerade erst gesendet. Bitte in zehn Minuten noch einmal versuchen.';
      ELSE
        BEGIN
          tok := ally_entschluesseln(z.einladung_verschluesselt);
        EXCEPTION WHEN OTHERS THEN
          tok := NULL;
        END;
        IF coalesce(tok, '') !~ '^[0-9a-f]{64}$' OR z.einladung_hash IS DISTINCT FROM ally_web_hash(tok) THEN
          fehler := 'Es gibt keinen gültigen Zugangslink. Bitte einen neuen erstellen.';
        ELSE
          INSERT INTO ally_systemnachrichten (art, ref, talent_id, geheim, gueltig_bis, erstellt_von)
          VALUES ('zugang_talent', 'zugang_talent:' || z.id || ':' || left(ally_web_hash(tok), 16) || ':' || encode(gen_random_bytes(8), 'hex'), tid,
            ally_verschluesseln(tok), least(z.einladung_bis, now() + interval '1 day'), s.person);
          m := 'Zugangslink für ' || tname || ' per Mail an ' || z.email || ' vorgemerkt; die Mail geht in etwa einer Minute raus.';
        END IF;
      END IF;
    ELSIF p_aktion = 'tz_kalender_widerrufen' THEN
      UPDATE ally_kalender_abos SET widerrufen_am = now(), widerrufen_von = s.person WHERE talent_id = tid AND widerrufen_am IS NULL;
      GET DIAGNOSTICS n = ROW_COUNT;
      IF n = 0 THEN fehler := 'Für dieses Talent gibt es kein Kalender-Abo.'; ELSE m := 'Kalender-Abo von ' || tname || ' beendet. Die Adresse gilt nicht mehr.'; END IF;
    ELSIF p_aktion = 'tz_briefing' THEN
      br := btrim(replace(coalesce(d->>'briefing', ''), E'\r', ''));
      IF length(br) > 4000 THEN
        fehler := 'Das Briefing hat höchstens 4.000 Zeichen.';
      ELSE
        INSERT INTO talent_bereich (talent_id, briefing, briefing_am, briefing_von, geaendert_von) VALUES (tid, br, now(), s.person, s.person)
        ON CONFLICT (talent_id) DO UPDATE SET briefing = EXCLUDED.briefing, briefing_am = now(), briefing_von = s.person, geaendert_am = now(), geaendert_von = s.person;
        IF br <> '' THEN
          PERFORM talents_benachrichtigen_talent(tid, 'mitteilung', 'Dein Briefing ist aktualisiert', '', 'briefing:' || floor(extract(epoch FROM now()))::bigint);
        END IF;
        m := CASE WHEN br = '' THEN 'Briefing entfernt.' ELSE 'Briefing gespeichert.' END;
      END IF;
    ELSE
      fehler := 'Diese Aktion gibt es hier nicht.';
    END IF;
  END IF;
  PERFORM ally_web_meldung(p_token, coalesce(fehler, m), CASE WHEN fehler IS NULL THEN 'ok' ELSE 'fehler' END, NULL);
  RETURN jsonb_build_object('ok', fehler IS NULL);
END $function$;
CREATE OR REPLACE FUNCTION public.talents_mediakit_abgelegt(p_token text, p_auftrag jsonb, p_ergebnis jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
  s record; t record; c jsonb; person boolean := false; wer text; ok boolean := false; fehler text;
  a jsonb := CASE WHEN jsonb_typeof(p_auftrag) = 'object' THEN p_auftrag ELSE '{}'::jsonb END;
  e jsonb := CASE WHEN jsonb_typeof(p_ergebnis) = 'object' THEN p_ergebnis ELSE '{}'::jsonb END;
  tid integer := CASE WHEN coalesce(a->>'talent_id', '') ~ '^[0-9]{1,9}$' THEN (a->>'talent_id')::integer END;
  did bigint := CASE WHEN coalesce(e->>'datei_id', '') ~ '^[0-9]{1,15}$' THEN (e->>'datei_id')::bigint END;
BEGIN
  -- Migration 196: nach TALENTS Ablage (ALLY 20 „Mediakit eintragen“) die abgelegte Datei als Mediakit des Talents merken und die Meldung setzen.
  -- Prüft noch einmal Sitzung und Recht (wie talents_mediakit_ui_aktion) und dass die Datei eben für dieses Talent als Mediakit abgelegt wurde.
  -- Ein bestehender Link zum Teilen bleibt gültig und zeigt danach die neue Fassung; die vorige Datei bleibt im Speicherort.
  SELECT * INTO s FROM ally_ui_sitzung(p_token);
  IF FOUND THEN
    person := true; c := talents_ansicht_start(p_token); wer := s.person;
    IF tid IS NULL OR NOT coalesce((c->>'ok')::boolean, false) OR NOT coalesce(talent_verwaltbar(c->>'u', tid), false) THEN fehler := 'Das Mediakit dieses Talents ändert nur, wer das Talent verwaltet.'; END IF;
  ELSE
    SELECT * INTO t FROM talent_web_sitzung(p_token);
    IF NOT FOUND THEN RETURN '{"ok": false, "angemeldet": false}'::jsonb; END IF;
    wer := 'talent:' || t.talent_id;
    IF tid IS DISTINCT FROM t.talent_id THEN fehler := 'Das Mediakit konnte nicht gespeichert werden.'; END IF;
  END IF;
  IF fehler IS NULL AND wer IS DISTINCT FROM a->>'von' THEN fehler := 'Das Mediakit konnte nicht gespeichert werden.'; END IF;
  IF fehler IS NULL AND NOT coalesce((e->>'ok')::boolean, false) THEN
    fehler := 'Das Mediakit konnte nicht abgelegt werden: ' || left(coalesce(nullif(e->>'fehler', ''), 'keine Antwort vom Speicherort.'), 300);
  END IF;
  IF fehler IS NULL AND NOT EXISTS (SELECT 1 FROM talent_ablage_dateien x WHERE x.id = did AND x.talent_id = tid AND x.art = 'mediakit' AND x.erstellt_am > now() - interval '15 minutes') THEN
    fehler := 'Das Mediakit konnte nicht gespeichert werden.';
  END IF;
  IF fehler IS NULL THEN
    INSERT INTO talent_mediakits AS m (talent_id, datei_id, hochgeladen_am, hochgeladen_von) VALUES (tid, did, now(), wer)
    ON CONFLICT (talent_id) DO UPDATE SET datei_id = EXCLUDED.datei_id, hochgeladen_am = EXCLUDED.hochgeladen_am, hochgeladen_von = EXCLUDED.hochgeladen_von;
    ok := true;
  END IF;
  IF person THEN PERFORM ally_web_meldung(p_token, coalesce(fehler, 'Mediakit gespeichert.' || CASE WHEN e->>'ort' IS NOT NULL THEN ' Abgelegt im Speicherort ' || left(e->>'ort', 60) || '.' ELSE '' END), CASE WHEN ok THEN 'ok' ELSE 'fehler' END, NULL);
  ELSE PERFORM talent_web_meldung(p_token, coalesce(fehler, 'Dein Mediakit ist gespeichert.'), CASE WHEN ok THEN 'ok' ELSE 'fehler' END); END IF;
  RETURN jsonb_build_object('ok', ok, 'angemeldet', true);
END $function$;
CREATE OR REPLACE FUNCTION public.talents_mediakit_selbst_datei(p_token text, p_datei_id bigint)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE s record; d record;
BEGIN
  -- Migration 196 (Plan 62b): das Talent sieht und lädt im Talent-Bereich sein aktuelles Mediakit (ALLY 20 „Download prüfen“, ta ohne Team-Sitzung).
  -- Talent-ID nur aus der Talent-Sitzung; nur die Datei, die gerade als Mediakit dieses Talents eingetragen ist. Sonst NULL (es passiert nichts).
  SELECT * INTO s FROM talent_web_sitzung(p_token);
  IF NOT FOUND OR p_datei_id IS NULL THEN RETURN NULL; END IF;
  SELECT x.id, x.name, x.mime INTO d FROM talent_mediakits m JOIN talent_ablage_dateien x ON x.id = m.datei_id AND x.talent_id = m.talent_id
  WHERE m.talent_id = s.talent_id AND m.datei_id = p_datei_id;
  IF NOT FOUND THEN RETURN NULL; END IF;
  RETURN jsonb_build_object('ok', true, 'angemeldet', true, 'datei_id', d.id, 'name', d.name, 'mime', coalesce(d.mime, 'application/pdf'));
END $function$;
CREATE OR REPLACE FUNCTION public.talents_mediakit_selbst_ui(p_token text)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE s record;
BEGIN
  -- Migration 196: „Mein Mediakit“ im Talent-Bereich (ALLY 38); Talent-ID nur aus der Talent-Sitzung. Das Talent pflegt sein Mediakit selbst (Stefan 01.11.2026).
  SELECT * INTO s FROM talent_web_sitzung(p_token);
  IF NOT FOUND THEN RETURN NULL; END IF;
  RETURN talents_mediakit_stand(s.talent_id) || jsonb_build_object('ok', true, 'darf', true, 'adresse', talent_ui_adresse() IS NOT NULL);
END $function$;
CREATE OR REPLACE FUNCTION public.talents_mediakit_ui_aktion(p_token text, p_csrf text, p_aktion text, p_daten jsonb, p_zustand jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
  s record; t record; c jsonb; tid integer; wer text; tok text; person boolean := false; text_ text; ton text := 'ok';
  d jsonb := CASE WHEN jsonb_typeof(p_daten) = 'object' THEN p_daten ELSE '{}'::jsonb END;
  typ text; gr bigint; r jsonb;
BEGIN
  -- Migration 196 (Stefan 01.11.2026, Mediakit): mk_hochladen, mk_link, mk_link_weg (ALLY 20 „Aktion ausführen“, vor allen anderen; NULL bei allen anderen Aktionen
  -- und ohne Sitzung). Person: Talent aus dem Formular, Recht „Talent verwalten“ (talent_verwaltbar); Talent: Talent-ID nur aus der Sitzung (Talent-Bereich).
  -- mk_hochladen prüft Art und Größe und gibt den Auftrag an ALLY 20 (weiter = mediakit; ALLY 20 legt die Datei über TALENTS Ablage ab, danach talents_mediakit_abgelegt).
  -- mk_link erzeugt einen neuen Link zum Teilen (der vorige gilt nicht mehr); gespeichert wird nur sha256, die Adresse geht einmal an die Oberfläche (mk_link).
  IF p_aktion IS NULL OR p_aktion NOT IN ('mk_hochladen', 'mk_link', 'mk_link_weg') THEN RETURN NULL; END IF;
  SELECT * INTO s FROM ally_ui_sitzung(p_token);
  IF FOUND THEN
    person := true;
    IF coalesce(p_csrf, '') <> ally_ui_csrf(s.token_hash) THEN
      RETURN coalesce(ally_web_meldung(p_token, 'Die Anfrage wurde abgelehnt. Bitte die Seite neu laden.', 'fehler', NULL), '{}'::jsonb) || '{"ok": false, "angemeldet": true, "ungueltig": true}'::jsonb;
    END IF;
    IF s.muss_pw_setzen THEN RETURN '{"ok": false, "angemeldet": true, "muss_pw_setzen": true}'::jsonb; END IF;
    IF NOT ally_ui_funktion_erlaubt(s.person, s.rolle, 'talent') THEN
      PERFORM ally_web_meldung(p_token, 'Talents sind für dich nicht freigeschaltet.', 'fehler', NULL); RETURN '{"ok": false, "angemeldet": true}'::jsonb;
    END IF;
    c := talents_ansicht_start(p_token);
    tid := CASE WHEN coalesce(d->>'talent_id', '') ~ '^[0-9]{1,9}$' THEN (d->>'talent_id')::integer END;
    IF tid IS NULL OR NOT coalesce((c->>'ok')::boolean, false) OR NOT EXISTS (SELECT 1 FROM talents x WHERE x.id = tid) OR NOT coalesce(talent_verwaltbar(c->>'u', tid), false) THEN
      PERFORM ally_web_meldung(p_token, 'Das Mediakit dieses Talents ändert nur, wer das Talent verwaltet.', 'fehler', NULL); RETURN '{"ok": false, "angemeldet": true}'::jsonb;
    END IF;
    wer := s.person;
  ELSE
    SELECT * INTO t FROM talent_web_sitzung(p_token);
    IF NOT FOUND THEN RETURN NULL; END IF;
    IF coalesce(p_csrf, '') <> ally_ui_csrf(t.token_hash) THEN
      PERFORM talent_web_meldung(p_token, 'Die Anfrage wurde abgelehnt. Bitte die Seite neu laden.', 'fehler');
      RETURN '{"ok": false, "angemeldet": true, "ungueltig": true}'::jsonb;
    END IF;
    tid := t.talent_id; wer := 'talent:' || t.talent_id;
  END IF;

  IF p_aktion = 'mk_hochladen' THEN
    typ := lower(coalesce(d->>'datei_typ', ''));
    gr := CASE WHEN coalesce(d->>'datei_groesse', '') ~ '^[0-9]{1,12}$' THEN (d->>'datei_groesse')::bigint ELSE 0 END;
    IF gr <= 0 THEN text_ := 'Es ist keine Datei angekommen. Bitte erneut hochladen.';
    ELSIF typ <> 'application/pdf' AND lower(coalesce(d->>'datei_name', '')) !~ '\.pdf$' THEN text_ := 'Das Mediakit muss ein PDF sein.';
    ELSIF gr > 15728640 THEN text_ := 'Das PDF ist größer als 15 MB. Bitte eine kleinere Fassung hochladen.';
    ELSIF talents_ist_testdaten(tid) THEN text_ := 'Für Testdaten wird nichts im Speicherort abgelegt.';
    END IF;
    IF text_ IS NOT NULL THEN ton := 'fehler';
    ELSE
      RETURN jsonb_build_object('ok', true, 'angemeldet', true, 'weiter', 'mediakit',
        'r', jsonb_build_object('talent_id', tid, 'von', wer, 'name', 'Mediakit_' || to_char(now() AT TIME ZONE 'Europe/Berlin', 'YYYY-MM-DD_HH24-MI') || '.pdf'));
    END IF;
  ELSIF p_aktion = 'mk_link' THEN
    IF NOT EXISTS (SELECT 1 FROM talent_mediakits m WHERE m.talent_id = tid AND m.datei_id IS NOT NULL) THEN text_ := 'Bitte zuerst ein Mediakit hochladen.'; ton := 'fehler';
    ELSIF talent_ui_adresse() IS NULL THEN text_ := 'Die öffentliche Adresse der Oberfläche ist nicht eingerichtet. Ohne sie gibt es keinen Link zum Teilen.'; ton := 'fehler';
    ELSE
      tok := encode(gen_random_bytes(32), 'hex');
      UPDATE talent_mediakits SET link_hash = ally_web_hash(tok), link_seit = now(), link_von = wer, link_abrufe = 0, link_zuletzt = NULL WHERE talent_id = tid;
      text_ := 'Neuer Link zum Teilen erstellt. Ein früherer Link gilt nicht mehr.';
      r := jsonb_build_object('ok', true, 'angemeldet', true, 'mk_link', talents_mediakit_adresse(tok));
    END IF;
  ELSE
    UPDATE talent_mediakits SET link_hash = NULL, link_seit = NULL, link_von = NULL WHERE talent_id = tid AND link_hash IS NOT NULL;
    text_ := CASE WHEN FOUND THEN 'Der Link zum Teilen gilt nicht mehr.' ELSE 'Es gab keinen aktiven Link zum Teilen.' END;
  END IF;
  IF person THEN PERFORM ally_web_meldung(p_token, text_, ton, NULL); ELSE PERFORM talent_web_meldung(p_token, text_, ton); END IF;
  RETURN coalesce(r, jsonb_build_object('ok', ton = 'ok', 'angemeldet', true));
END $function$;

DROP FUNCTION public.talent_ui_kacheln(p_token text, p_filter jsonb);
DROP FUNCTION public.talent_fuer_talent_setzen(p_token text, p_daten jsonb);
DROP FUNCTION public.talent_freigaben_ui(p_token text, p_talent text);
DROP FUNCTION public.talent_bericht_selbst_datei(p_token text, p_bericht_id text);
DROP FUNCTION public.talent_mediakit_fuer_talent(p_talent_id integer);
DROP FUNCTION public.talent_bericht_teilbar(p_bericht_id bigint, p_talent_id integer);
DO $m$
BEGIN
  IF (SELECT md5(string_agg(p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')|' || pg_get_function_result(p.oid) || '|' || md5(p.prosrc), E'\n' ORDER BY p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')' COLLATE "C")) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname::text = 'public' COLLATE "C" AND p.proname::text COLLATE "C" = ANY (ARRAY['talent_bericht_selbst_datei', 'talent_bericht_teilbar', 'talent_chat_kontext', 'talent_freigaben_ui', 'talent_fuer_talent_setzen', 'talent_mediakit_fuer_talent', 'talent_ui_daten', 'talent_ui_kacheln', 'talent_ui_link_oeffnen', 'talent_zugang_ui_aktion', 'talents_mediakit_abgelegt', 'talents_mediakit_selbst_datei', 'talents_mediakit_selbst_ui', 'talents_mediakit_ui_aktion'])) IS DISTINCT FROM 'b7786ad69f19b58a955b380f04fa7271' THEN RAISE EXCEPTION 'Rückbau 200: Funktionen nicht wie vorher'; END IF;
  IF (SELECT md5(string_agg(z, E'\n' ORDER BY z COLLATE "C")) FROM (WITH t AS (SELECT c.oid, c.relname::text AS tab FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname::text = 'public' COLLATE "C" AND c.relkind::text = ANY (ARRAY['r', 'p']) AND c.relname::text = ANY (ARRAY['talent_berichte', 'talent_kampagne_talents', 'talent_konzepte', 'talent_mediakits', 'talent_notizen'])) SELECT 'S|' || t.tab || '|' || a.attname::text || '|' || format_type(a.atttypid, a.atttypmod) || '|' || CASE WHEN a.attnotnull THEN 'NN' ELSE '-' END || '|' || coalesce(pg_get_expr(d.adbin, d.adrelid), '') || '|' || a.attidentity::text || a.attgenerated::text AS z FROM t JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum > 0 AND NOT a.attisdropped LEFT JOIN pg_attrdef d ON d.adrelid = t.oid AND d.adnum = a.attnum UNION ALL SELECT 'C|' || t.tab || '|' || co.conname::text || '|' || co.contype::text || '|' || pg_get_constraintdef(co.oid) FROM t JOIN pg_constraint co ON co.conrelid = t.oid UNION ALL SELECT 'I|' || t.tab || '|' || ic.relname::text || '|' || pg_get_indexdef(i.indexrelid) FROM t JOIN pg_index i ON i.indrelid = t.oid JOIN pg_class ic ON ic.oid = i.indexrelid UNION ALL SELECT 'T|' || t.tab || '|' || tg.tgname::text || '|' || pg_get_triggerdef(tg.oid) || '|' || tg.tgenabled::text FROM t JOIN pg_trigger tg ON tg.tgrelid = t.oid AND NOT tg.tgisinternal) x) IS DISTINCT FROM '27fe92d8853bbf28193f7a97d993f0d9' THEN RAISE EXCEPTION 'Rückbau 200: Schema nicht wie vorher'; END IF;
  IF (SELECT coalesce(string_agg(c.relname::text || ':' || format_type(a.atttypid, a.atttypmod) || ':' || coalesce(pg_get_expr(d.adbin, d.adrelid), '-') || ':' || CASE WHEN a.attnotnull THEN 'NN' ELSE 'null' END, ',' ORDER BY c.relname::text COLLATE "C"), '-') FROM pg_attribute a JOIN pg_class c ON c.oid = a.attrelid JOIN pg_namespace n ON n.oid = c.relnamespace LEFT JOIN pg_attrdef d ON d.adrelid = a.attrelid AND d.adnum = a.attnum WHERE n.nspname::text = 'public' COLLATE "C" AND c.relkind = 'r' AND a.attname::text = 'sichtbar_fuer_talent' COLLATE "C" AND a.attnum > 0 AND NOT a.attisdropped AND c.relname::text <> 'talent_deliverables' COLLATE "C") IS DISTINCT FROM '-' THEN RAISE EXCEPTION 'Rückbau 200: Freigabe-Spalten nicht entfernt'; END IF;
  IF current_setting('m200.daten') IS DISTINCT FROM (SELECT md5(string_agg(z, E'\n' ORDER BY z COLLATE "C")) FROM (SELECT 'talent_berichte|' || coalesce(md5(string_agg((to_jsonb(x) - 'sichtbar_fuer_talent')::text, E'\n' ORDER BY (to_jsonb(x) - 'sichtbar_fuer_talent')::text COLLATE "C")), '-') AS z FROM public.talent_berichte x UNION ALL SELECT 'talent_kampagne_talents|' || coalesce(md5(string_agg((to_jsonb(x) - 'sichtbar_fuer_talent')::text, E'\n' ORDER BY (to_jsonb(x) - 'sichtbar_fuer_talent')::text COLLATE "C")), '-') AS z FROM public.talent_kampagne_talents x UNION ALL SELECT 'talent_konzepte|' || coalesce(md5(string_agg((to_jsonb(x) - 'sichtbar_fuer_talent')::text, E'\n' ORDER BY (to_jsonb(x) - 'sichtbar_fuer_talent')::text COLLATE "C")), '-') AS z FROM public.talent_konzepte x UNION ALL SELECT 'talent_mediakits|' || coalesce(md5(string_agg((to_jsonb(x) - 'sichtbar_fuer_talent')::text, E'\n' ORDER BY (to_jsonb(x) - 'sichtbar_fuer_talent')::text COLLATE "C")), '-') AS z FROM public.talent_mediakits x UNION ALL SELECT 'talent_notizen|' || coalesce(md5(string_agg((to_jsonb(x) - 'sichtbar_fuer_talent')::text, E'\n' ORDER BY (to_jsonb(x) - 'sichtbar_fuer_talent')::text COLLATE "C")), '-') AS z FROM public.talent_notizen x) y) THEN RAISE EXCEPTION 'Rückbau 200: Daten der Talent-Tabellen anders als erwartet geändert'; END IF;
END $m$;
