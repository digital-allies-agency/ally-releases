-- Rückbau 209: Funktionen wörtlich wie vor 209 (werkzeuge/m209/vorher/), neue Funktionen entfernen. Ohne Datenverlust: die Tabellen ally_ui_pfade und ally_ui_filter
-- bleiben als …_rb209 stehen. Vorher den Merker adressen_pfade ausschalten und die Regel des Webservers
-- für Seiten als Pfad („oberflaeche-seiten“) entfernen, dann die Abläufe ALLY 16, 20, 21, 24, 36 auf den Stand vor 209 zurücksetzen
-- (werkzeuge/sammel209/vorher/) und die Web-App der Fassung davor einspielen.
-- Nur auf dem Stand von 209. Läuft als Ganzes in der Transaktion des Aufrufs (psql -1).
DO $m$
BEGIN
  IF (SELECT md5(string_agg(p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')|' || pg_get_function_result(p.oid) || '|' || md5(p.prosrc), E'\n' ORDER BY p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')' COLLATE "C")) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname::text = 'public' COLLATE "C" AND p.proname::text COLLATE "C" = ANY (ARRAY['ally_systemnachricht_inhalt', 'talent_zugang_ui', 'talents_warnungen', 'talent_einladung_rueckweg', 'ally_ui_verbindung_link', 'ally_ui_pfad_teil', 'ally_ui_pfad_lesen', 'ally_ui_pfad', 'ally_ui_ort', 'ally_ui_abfrage', 'ally_ui_pfade_an', 'ally_ui_link', 'ally_ui_pfade_liste', 'ally_ui_filter'])) IS NOT DISTINCT FROM '871ff73c8c022d9329be0414da07d50d' THEN RAISE EXCEPTION 'Rückbau 209: schon zurückgebaut, nichts geändert'; END IF;
  IF (SELECT md5(string_agg(p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')|' || pg_get_function_result(p.oid) || '|' || md5(p.prosrc), E'\n' ORDER BY p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')' COLLATE "C")) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname::text = 'public' COLLATE "C" AND p.proname::text COLLATE "C" = ANY (ARRAY['ally_systemnachricht_inhalt', 'talent_zugang_ui', 'talents_warnungen', 'talent_einladung_rueckweg', 'ally_ui_verbindung_link', 'ally_ui_pfad_teil', 'ally_ui_pfad_lesen', 'ally_ui_pfad', 'ally_ui_ort', 'ally_ui_abfrage', 'ally_ui_pfade_an', 'ally_ui_link', 'ally_ui_pfade_liste', 'ally_ui_filter'])) IS DISTINCT FROM '20374df52ea8d161140fce5a70fe7ddc' THEN RAISE EXCEPTION 'Rückbau 209: nicht im Stand von 209, nichts geändert'; END IF;
END $m$;
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
    link := basis || '?seite=einstellungen&bereich=profil&em=' || p_tok;
  ELSIF q.art IN ('zugang_talent', 'zugang_person', 'passwort') THEN
    IF basis IS NULL OR coalesce(p_tok, '') !~ '^[0-9a-f]{64}$' THEN RETURN NULL; END IF;
    link := basis || '?seite=passwort-neu&code=' || p_tok;
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
      lk := CASE WHEN lk ~ '^[0-9a-f]{64}$' THEN talent_ui_adresse() || '?seite=passwort-neu&code=' || lk END;
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
        || coalesce(talent_ui_adresse() || '?seite=talent&id=' || tt.id, talents_seite_adresse('ansicht=einstellungen&bereich=talents&talent=' || tt.id)) || ' (Aktionen › Export (ZIP)). Soll das Talent bleiben, dort unter Aktionen › Wiederherstellen wählen.',
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
  RETURN substring(coalesce(ally_oberflaeche_intern(), '') FROM '^https://[^/]+(/[A-Za-z0-9/_-]*)$') || '?seite=talent-bereich';
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
    WHEN 'lis' THEN '/linkedin-verbinden?seite=1'
    WHEN 'ig' THEN '?ansicht=marketing#instagram'
    WHEN 'pf' THEN '?ansicht=einstellungen&bereich=postfaecher'
    WHEN 'ki' THEN '?ansicht=einstellungen&bereich=ki#ki-zugang'
    ELSE '?ansicht=einstellungen&bereich=superadmin' || CASE WHEN coalesce(p_id, '') ~ '^[a-z]{2,20}$' THEN '&sa=' || p_id ELSE '' END END;
  RETURN jsonb_build_object('ok', true, 'url', ziel, 'ally8', true);
END $function$;
DROP FUNCTION public.ally_ui_filter(p_token text, p_seite text, p_parameter jsonb, p_ausdruecklich boolean);
DROP FUNCTION public.ally_ui_pfade_liste();
DROP FUNCTION public.ally_ui_link(p_seite text, p_parameter jsonb);
DROP FUNCTION public.ally_ui_pfade_an();
DROP FUNCTION public.ally_ui_abfrage(p_seite text, p_parameter jsonb);
DROP FUNCTION public.ally_ui_ort(p_pfad text);
DROP FUNCTION public.ally_ui_pfad(p_seite text, p_parameter jsonb);
DROP FUNCTION public.ally_ui_pfad_lesen(p_teil text);
DROP FUNCTION public.ally_ui_pfad_teil(p_wert text);
ALTER TABLE public.ally_ui_pfade RENAME TO ally_ui_pfade_rb209;
ALTER TABLE public.ally_ui_filter RENAME TO ally_ui_filter_rb209;
ALTER INDEX public.ally_ui_filter_pkey RENAME TO ally_ui_filter_pkey_rb209;
ALTER INDEX public.ally_ui_pfade_pkey RENAME TO ally_ui_pfade_pkey_rb209;
ALTER INDEX public.ally_ui_pfade_seite RENAME TO ally_ui_pfade_seite_rb209;
DO $m$
BEGIN
  IF (SELECT md5(string_agg(p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')|' || pg_get_function_result(p.oid) || '|' || md5(p.prosrc), E'\n' ORDER BY p.proname::text || '(' || pg_get_function_identity_arguments(p.oid) || ')' COLLATE "C")) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname::text = 'public' COLLATE "C" AND p.proname::text COLLATE "C" = ANY (ARRAY['ally_systemnachricht_inhalt', 'talent_zugang_ui', 'talents_warnungen', 'talent_einladung_rueckweg', 'ally_ui_verbindung_link', 'ally_ui_pfad_teil', 'ally_ui_pfad_lesen', 'ally_ui_pfad', 'ally_ui_ort', 'ally_ui_abfrage', 'ally_ui_pfade_an', 'ally_ui_link', 'ally_ui_pfade_liste', 'ally_ui_filter'])) IS DISTINCT FROM '871ff73c8c022d9329be0414da07d50d' THEN RAISE EXCEPTION 'Rückbau 209: Funktionen nicht wie vorher'; END IF;
END $m$;
