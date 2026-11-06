-- Ally Grundstand (Bauschritt 3, D.3), erzeugt von werkzeuge/d3_grundstand.py aus SYS-2-Lesung (Ausführungen in lesung.json).
-- Reihenfolge: schema_vor.sql, startwerte.sql, schema_nach.sql.
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET search_path = public;
ALTER TABLE ONLY public.ally_assistent_verlauf ADD CONSTRAINT ally_assistent_verlauf_person_fkey FOREIGN KEY (person) REFERENCES ally_personen(matrix_user_id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY public.ally_benachrichtigung_schalter ADD CONSTRAINT ally_benachrichtigung_schalter_art_fkey FOREIGN KEY (art) REFERENCES ally_benachrichtigung_arten(schluessel) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY public.ally_benachrichtigung_schalter ADD CONSTRAINT ally_benachrichtigung_schalter_person_fkey FOREIGN KEY (person) REFERENCES ally_personen(matrix_user_id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY public.ally_benachrichtigungen ADD CONSTRAINT ally_benachrichtigungen_art_fkey FOREIGN KEY (art) REFERENCES ally_benachrichtigung_arten(schluessel) ON UPDATE CASCADE;

ALTER TABLE ONLY public.ally_benachrichtigungen ADD CONSTRAINT ally_benachrichtigungen_person_fkey FOREIGN KEY (person) REFERENCES ally_personen(matrix_user_id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY public.ally_benachrichtigungen ADD CONSTRAINT ally_benachrichtigungen_talent_fkey FOREIGN KEY (talent_id) REFERENCES talents(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.ally_cd ADD CONSTRAINT ally_cd_unternehmen_id_fkey FOREIGN KEY (unternehmen_id) REFERENCES ally_unternehmen(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.ally_cd_dateien ADD CONSTRAINT ally_cd_dateien_unternehmen_id_fkey FOREIGN KEY (unternehmen_id) REFERENCES ally_unternehmen(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.ally_email_aenderungen ADD CONSTRAINT ally_email_aenderungen_person_fkey FOREIGN KEY (person) REFERENCES ally_personen(matrix_user_id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY public.ally_ergebnisse ADD CONSTRAINT ally_ergebnisse_person_fkey FOREIGN KEY (person) REFERENCES ally_personen(matrix_user_id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY public.ally_firma ADD CONSTRAINT ally_firma_unternehmen_id_fkey FOREIGN KEY (unternehmen_id) REFERENCES ally_unternehmen(id);

ALTER TABLE ONLY public.ally_fixierung ADD CONSTRAINT ally_fixierung_einstellung_fkey FOREIGN KEY (einstellung) REFERENCES ally_fix_einstellungen(einstellung) ON DELETE CASCADE;

ALTER TABLE ONLY public.ally_funktionen ADD CONSTRAINT ally_funktionen_modul_fkey FOREIGN KEY (modul) REFERENCES plattform_module(schluessel);

ALTER TABLE ONLY public.ally_kalender_abos ADD CONSTRAINT ally_kalender_abos_person_fkey FOREIGN KEY (person) REFERENCES ally_personen(matrix_user_id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY public.ally_kalender_abos ADD CONSTRAINT ally_kalender_abos_talent_id_fkey FOREIGN KEY (talent_id) REFERENCES talents(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.ally_kalender_verbindungen ADD CONSTRAINT ally_kalender_verbindungen_person_fkey FOREIGN KEY (person) REFERENCES ally_personen(matrix_user_id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY public.ally_nutzer_rechte ADD CONSTRAINT ally_nutzer_rechte_recht_fkey FOREIGN KEY (recht) REFERENCES ally_rechte(schluessel) ON DELETE CASCADE;

ALTER TABLE ONLY public.ally_person_rechte ADD CONSTRAINT ally_person_rechte_person_fkey FOREIGN KEY (person) REFERENCES ally_personen(matrix_user_id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY public.ally_person_rechte ADD CONSTRAINT ally_person_rechte_recht_fkey FOREIGN KEY (recht) REFERENCES ally_rechte(schluessel) ON DELETE CASCADE;

ALTER TABLE ONLY public.ally_person_startseite ADD CONSTRAINT ally_person_startseite_person_fkey FOREIGN KEY (person) REFERENCES ally_personen(matrix_user_id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY public.ally_person_startseite ADD CONSTRAINT ally_person_startseite_seite_fkey FOREIGN KEY (seite) REFERENCES ally_ui_funktionen(schluessel) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY public.ally_personen ADD CONSTRAINT ally_personen_rolle_fkey FOREIGN KEY (rolle) REFERENCES ally_rollen(schluessel) ON UPDATE CASCADE;

ALTER TABLE ONLY public.ally_personen ADD CONSTRAINT ally_personen_talent_id_fkey FOREIGN KEY (talent_id) REFERENCES talents(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.ally_postfaecher ADD CONSTRAINT ally_postfaecher_schrift_fkey FOREIGN KEY (schrift) REFERENCES mail_schriften(schluessel);

ALTER TABLE ONLY public.ally_postfaecher ADD CONSTRAINT ally_postfaecher_unternehmen_id_fkey FOREIGN KEY (unternehmen_id) REFERENCES ally_unternehmen(id);

ALTER TABLE ONLY public.ally_rollen ADD CONSTRAINT ally_rollen_paket_fkey FOREIGN KEY (paket) REFERENCES plattform_module(schluessel) ON UPDATE CASCADE;

ALTER TABLE ONLY public.ally_rollen_rechte ADD CONSTRAINT ally_rollen_rechte_recht_fkey FOREIGN KEY (recht) REFERENCES ally_rechte(schluessel) ON DELETE CASCADE;

ALTER TABLE ONLY public.ally_rollen_rechte ADD CONSTRAINT ally_rollen_rechte_rolle_fkey FOREIGN KEY (rolle) REFERENCES ally_rollen(schluessel) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY public.ally_speicherort_rechte ADD CONSTRAINT ally_speicherort_rechte_person_fkey FOREIGN KEY (person) REFERENCES ally_personen(matrix_user_id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY public.ally_speicherort_rechte ADD CONSTRAINT ally_speicherort_rechte_rolle_fkey FOREIGN KEY (rolle) REFERENCES ally_rollen(schluessel) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY public.ally_systemnachrichten ADD CONSTRAINT ally_systemnachrichten_aufgabe_id_fkey FOREIGN KEY (aufgabe_id) REFERENCES talent_aufgaben(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.ally_systemnachrichten ADD CONSTRAINT ally_systemnachrichten_person_fkey FOREIGN KEY (person) REFERENCES ally_personen(matrix_user_id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY public.ally_systemnachrichten ADD CONSTRAINT ally_systemnachrichten_talent_id_fkey FOREIGN KEY (talent_id) REFERENCES talents(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.ally_ui_eigene_gruppen ADD CONSTRAINT ally_ui_eigene_gruppen_person_fkey FOREIGN KEY (person) REFERENCES ally_personen(matrix_user_id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY public.ally_ui_funktion_schalter ADD CONSTRAINT ally_ui_funktion_schalter_schluessel_fkey FOREIGN KEY (schluessel) REFERENCES ally_ui_funktionen(schluessel) ON DELETE CASCADE;

ALTER TABLE ONLY public.ally_ui_funktionen ADD CONSTRAINT ally_ui_funktionen_gruppe_fkey FOREIGN KEY (gruppe) REFERENCES ally_ui_gruppen(schluessel);

ALTER TABLE ONLY public.ally_ui_funktionen ADD CONSTRAINT ally_ui_funktionen_leiste_aktiv_fkey FOREIGN KEY (leiste_aktiv) REFERENCES ally_ui_funktionen(schluessel);

ALTER TABLE ONLY public.ally_ui_funktionen ADD CONSTRAINT ally_ui_funktionen_modul_fkey FOREIGN KEY (modul) REFERENCES plattform_module(schluessel);

ALTER TABLE ONLY public.ally_ui_funktionen ADD CONSTRAINT ally_ui_funktionen_recht_fkey FOREIGN KEY (recht) REFERENCES ally_rechte(schluessel);

ALTER TABLE ONLY public.ally_ui_zustand ADD CONSTRAINT ally_ui_zustand_person_fkey FOREIGN KEY (person) REFERENCES ally_personen(matrix_user_id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY public.beleg_verarbeitung ADD CONSTRAINT beleg_verarbeitung_datei_bereich_fkey FOREIGN KEY (datei_bereich) REFERENCES ablage_bereiche(bereich);

ALTER TABLE ONLY public.ki_verbrauch ADD CONSTRAINT ki_verbrauch_talent_id_fkey FOREIGN KEY (talent_id) REFERENCES talents(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.klaerungsfaelle ADD CONSTRAINT klaerungsfaelle_beleg_verarbeitung_id_fkey FOREIGN KEY (beleg_verarbeitung_id) REFERENCES beleg_verarbeitung(id);

ALTER TABLE ONLY public.marketing_hintergruende ADD CONSTRAINT marketing_hintergruende_unternehmen_id_fkey FOREIGN KEY (unternehmen_id) REFERENCES ally_unternehmen(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.marketing_posts ADD CONSTRAINT marketing_posts_thema_id_fkey FOREIGN KEY (thema_id) REFERENCES marketing_themen(id);

ALTER TABLE ONLY public.monatsberichte_verlauf ADD CONSTRAINT monatsberichte_verlauf_bericht_id_fkey FOREIGN KEY (bericht_id) REFERENCES monatsberichte(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.postfach_empfang_beobachtung ADD CONSTRAINT postfach_empfang_beobachtung_platz_fkey FOREIGN KEY (platz) REFERENCES postfach_plaetze(platz) ON DELETE CASCADE;

ALTER TABLE ONLY public.postfach_empfang_neustart ADD CONSTRAINT postfach_empfang_neustart_platz_fkey FOREIGN KEY (platz) REFERENCES postfach_plaetze(platz) ON DELETE CASCADE;

ALTER TABLE ONLY public.postfach_empfang_stoerung ADD CONSTRAINT postfach_empfang_stoerung_platz_fkey FOREIGN KEY (platz) REFERENCES postfach_plaetze(platz) ON DELETE CASCADE;

ALTER TABLE ONLY public.postfach_plaetze ADD CONSTRAINT postfach_plaetze_adresse_fkey FOREIGN KEY (adresse) REFERENCES ally_postfaecher(adresse) ON UPDATE CASCADE ON DELETE SET NULL;

ALTER TABLE ONLY public.shopify_berichte ADD CONSTRAINT shopify_berichte_shop_id_fkey FOREIGN KEY (shop_id) REFERENCES shopify_shops(id);

ALTER TABLE ONLY public.shopify_laeufe ADD CONSTRAINT shopify_laeufe_bericht_id_fkey FOREIGN KEY (bericht_id) REFERENCES shopify_berichte(id);

ALTER TABLE ONLY public.shopify_lauf_dateien ADD CONSTRAINT shopify_lauf_dateien_lauf_id_fkey FOREIGN KEY (lauf_id) REFERENCES shopify_laeufe(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.shopify_oauth_state ADD CONSTRAINT shopify_oauth_state_shop_id_fkey FOREIGN KEY (shop_id) REFERENCES shopify_shops(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.shopify_produkte ADD CONSTRAINT shopify_produkte_shop_id_fkey FOREIGN KEY (shop_id) REFERENCES shopify_shops(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.speicher_ordner_protokoll ADD CONSTRAINT speicher_ordner_protokoll_person_fkey FOREIGN KEY (person) REFERENCES ally_personen(matrix_user_id) ON UPDATE CASCADE ON DELETE SET NULL;

ALTER TABLE ONLY public.speicher_ordner_protokoll ADD CONSTRAINT speicher_ordner_protokoll_talent_id_fkey FOREIGN KEY (talent_id) REFERENCES talents(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.speicher_ordner_protokoll ADD CONSTRAINT speicher_ordner_protokoll_talent_ordner_id_fkey FOREIGN KEY (talent_ordner_id) REFERENCES talent_ordner(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.sync_mapping ADD CONSTRAINT sync_mapping_parent_mapping_id_fkey FOREIGN KEY (parent_mapping_id) REFERENCES sync_mapping(id);

ALTER TABLE ONLY public.talent_ablage_dateien ADD CONSTRAINT talent_ablage_dateien_talent_id_fkey FOREIGN KEY (talent_id) REFERENCES talents(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.talent_abruf_versuche ADD CONSTRAINT talent_abruf_versuche_kanal_id_fkey FOREIGN KEY (kanal_id) REFERENCES talent_kanaele(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.talent_anmeldungen ADD CONSTRAINT talent_anmeldungen_einladung_id_fkey FOREIGN KEY (einladung_id) REFERENCES talent_einladungen(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.talent_aufgaben ADD CONSTRAINT talent_aufgaben_deliverable_id_fkey FOREIGN KEY (deliverable_id) REFERENCES talent_deliverables(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.talent_aufgaben ADD CONSTRAINT talent_aufgaben_deliverable_talent FOREIGN KEY (deliverable_id, talent_id) REFERENCES talent_deliverables(id, talent_id);

ALTER TABLE ONLY public.talent_aufgaben ADD CONSTRAINT talent_aufgaben_kampagne_id_fkey FOREIGN KEY (kampagne_id) REFERENCES talent_kampagnen(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.talent_aufgaben ADD CONSTRAINT talent_aufgaben_kampagne_talent FOREIGN KEY (kampagne_id, talent_id) REFERENCES talent_kampagne_talents(kampagne_id, talent_id);

ALTER TABLE ONLY public.talent_aufgaben ADD CONSTRAINT talent_aufgaben_regel_id_fkey FOREIGN KEY (regel_id) REFERENCES talent_erinnerungsregeln(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.talent_aufgaben ADD CONSTRAINT talent_aufgaben_talent_id_fkey FOREIGN KEY (talent_id) REFERENCES talents(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.talent_aufgaben ADD CONSTRAINT talent_aufgaben_version_id_fkey FOREIGN KEY (version_id) REFERENCES talent_deliverable_versionen(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.talent_beitraege ADD CONSTRAINT talent_beitraege_kanal_id_fkey FOREIGN KEY (kanal_id) REFERENCES talent_kanaele(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.talent_beitrag_bilder ADD CONSTRAINT talent_beitrag_bilder_beitrag_id_fkey FOREIGN KEY (beitrag_id) REFERENCES talent_beitraege(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.talent_beitrag_tage ADD CONSTRAINT talent_beitrag_tage_beitrag_id_fkey FOREIGN KEY (beitrag_id) REFERENCES talent_beitraege(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.talent_bereich ADD CONSTRAINT talent_bereich_talent_id_fkey FOREIGN KEY (talent_id) REFERENCES talents(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.talent_bericht_vorlagen ADD CONSTRAINT talent_bericht_vorlagen_erstellt_von_fkey FOREIGN KEY (erstellt_von) REFERENCES ally_personen(matrix_user_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.talent_berichte ADD CONSTRAINT talent_berichte_vorlage_id_fkey FOREIGN KEY (vorlage_id) REFERENCES talent_bericht_vorlagen(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.talent_chat ADD CONSTRAINT talent_chat_talent_id_fkey FOREIGN KEY (talent_id) REFERENCES talents(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.talent_chat_verlauf ADD CONSTRAINT talent_chat_verlauf_talent_id_fkey FOREIGN KEY (talent_id) REFERENCES talents(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.talent_deliverable_versionen ADD CONSTRAINT talent_deliverable_versionen_deliverable_id_fkey FOREIGN KEY (deliverable_id) REFERENCES talent_deliverables(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.talent_deliverables ADD CONSTRAINT talent_deliverables_beitrag_id_fkey FOREIGN KEY (beitrag_id) REFERENCES talent_beitraege(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.talent_deliverables ADD CONSTRAINT talent_deliverables_kampagne_id_fkey FOREIGN KEY (kampagne_id) REFERENCES talent_kampagnen(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.talent_deliverables ADD CONSTRAINT talent_deliverables_kampagne_talent FOREIGN KEY (kampagne_id, talent_id) REFERENCES talent_kampagne_talents(kampagne_id, talent_id);

ALTER TABLE ONLY public.talent_deliverables ADD CONSTRAINT talent_deliverables_talent_id_fkey FOREIGN KEY (talent_id) REFERENCES talents(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.talent_doppelt_entscheidungen ADD CONSTRAINT talent_doppelt_entscheidungen_manuell_id_fkey FOREIGN KEY (manuell_id) REFERENCES talent_manuell_werte(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.talent_doppelt_entscheidungen ADD CONSTRAINT talent_doppelt_entscheidungen_talent_id_fkey FOREIGN KEY (talent_id) REFERENCES talents(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.talent_doppelt_meldungen ADD CONSTRAINT talent_doppelt_meldungen_manuell_id_fkey FOREIGN KEY (manuell_id) REFERENCES talent_manuell_werte(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.talent_doppelt_verlauf ADD CONSTRAINT talent_doppelt_verlauf_talent_id_fkey FOREIGN KEY (talent_id) REFERENCES talents(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.talent_einladung_rueckwege ADD CONSTRAINT talent_einladung_rueckwege_einladung_id_fkey FOREIGN KEY (einladung_id) REFERENCES talent_einladungen(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.talent_einladungen ADD CONSTRAINT talent_einladungen_talent_id_fkey FOREIGN KEY (talent_id) REFERENCES talents(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.talent_erinnerungen_lauf ADD CONSTRAINT talent_erinnerungen_lauf_aufgabe_id_fkey FOREIGN KEY (aufgabe_id) REFERENCES talent_aufgaben(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.talent_erinnerungen_lauf ADD CONSTRAINT talent_erinnerungen_lauf_deliverable_id_fkey FOREIGN KEY (deliverable_id) REFERENCES talent_deliverables(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.talent_erinnerungen_lauf ADD CONSTRAINT talent_erinnerungen_lauf_regel_id_fkey FOREIGN KEY (regel_id) REFERENCES talent_erinnerungsregeln(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.talent_erinnerungsregeln ADD CONSTRAINT talent_erinnerungsregeln_kampagne_id_fkey FOREIGN KEY (kampagne_id) REFERENCES talent_kampagnen(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.talent_kampagne_beitraege ADD CONSTRAINT talent_kampagne_beitraege_beitrag_id_fkey FOREIGN KEY (beitrag_id) REFERENCES talent_beitraege(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.talent_kampagne_beitraege ADD CONSTRAINT talent_kampagne_beitraege_kampagne_id_fkey FOREIGN KEY (kampagne_id) REFERENCES talent_kampagnen(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.talent_kampagne_links ADD CONSTRAINT talent_kampagne_links_kampagne_id_fkey FOREIGN KEY (kampagne_id) REFERENCES talent_kampagnen(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.talent_kampagne_talents ADD CONSTRAINT talent_kampagne_talents_kampagne_id_fkey FOREIGN KEY (kampagne_id) REFERENCES talent_kampagnen(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.talent_kampagne_talents ADD CONSTRAINT talent_kampagne_talents_talent_id_fkey FOREIGN KEY (talent_id) REFERENCES talents(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.talent_kampagnen ADD CONSTRAINT talent_kampagnen_zustaendig_fkey FOREIGN KEY (zustaendig) REFERENCES ally_personen(matrix_user_id) ON UPDATE CASCADE ON DELETE SET NULL;

ALTER TABLE ONLY public.talent_kanaele ADD CONSTRAINT talent_kanaele_talent_id_fkey FOREIGN KEY (talent_id) REFERENCES talents(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.talent_kanal_tage ADD CONSTRAINT talent_kanal_tage_kanal_id_fkey FOREIGN KEY (kanal_id) REFERENCES talent_kanaele(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.talent_ki_auftraege ADD CONSTRAINT talent_ki_auftraege_talent_id_fkey FOREIGN KEY (talent_id) REFERENCES talents(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.talent_ki_auswertungen ADD CONSTRAINT talent_ki_auswertungen_talent_id_fkey FOREIGN KEY (talent_id) REFERENCES talents(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.talent_ki_texte ADD CONSTRAINT talent_ki_texte_talent_id_fkey FOREIGN KEY (talent_id) REFERENCES talents(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.talent_ki_themen ADD CONSTRAINT talent_ki_themen_beitrag_id_fkey FOREIGN KEY (beitrag_id) REFERENCES talent_beitraege(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.talent_konzept_angaben ADD CONSTRAINT talent_konzept_angaben_talent_id_fkey FOREIGN KEY (talent_id) REFERENCES talents(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.talent_konzept_ziele ADD CONSTRAINT talent_konzept_ziele_konzept_id_fkey FOREIGN KEY (konzept_id) REFERENCES talent_konzepte(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.talent_konzept_ziele ADD CONSTRAINT talent_konzept_ziele_talent_id_fkey FOREIGN KEY (talent_id) REFERENCES talents(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.talent_konzepte ADD CONSTRAINT talent_konzepte_talent_id_fkey FOREIGN KEY (talent_id) REFERENCES talents(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.talent_loesch_ankuendigungen ADD CONSTRAINT talent_loesch_ankuendigungen_talent_id_fkey FOREIGN KEY (talent_id) REFERENCES talents(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.talent_mail_entwuerfe ADD CONSTRAINT talent_mail_entwuerfe_talent_id_fkey FOREIGN KEY (talent_id) REFERENCES talents(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.talent_mail_zuordnung ADD CONSTRAINT talent_mail_zuordnung_talent_id_fkey FOREIGN KEY (talent_id) REFERENCES talents(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.talent_manuell_vorschlaege ADD CONSTRAINT talent_manuell_vorschlaege_talent_id_fkey FOREIGN KEY (talent_id) REFERENCES talents(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.talent_manuell_werte ADD CONSTRAINT talent_manuell_werte_talent_id_fkey FOREIGN KEY (talent_id) REFERENCES talents(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.talent_manuell_werte ADD CONSTRAINT talent_manuell_werte_vorschlag_id_fkey FOREIGN KEY (vorschlag_id) REFERENCES talent_manuell_vorschlaege(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.talent_markensuche_kriterien ADD CONSTRAINT talent_markensuche_kriterien_talent_id_fkey FOREIGN KEY (talent_id) REFERENCES talents(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.talent_markensuche_laeufe ADD CONSTRAINT talent_markensuche_laeufe_talent_id_fkey FOREIGN KEY (talent_id) REFERENCES talents(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.talent_markensuche_treffer ADD CONSTRAINT talent_markensuche_treffer_lauf_id_fkey FOREIGN KEY (lauf_id) REFERENCES talent_markensuche_laeufe(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.talent_markensuche_treffer ADD CONSTRAINT talent_markensuche_treffer_talent_id_fkey FOREIGN KEY (talent_id) REFERENCES talents(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.talent_mediakits ADD CONSTRAINT talent_mediakits_datei_id_fkey FOREIGN KEY (datei_id) REFERENCES talent_ablage_dateien(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.talent_mediakits ADD CONSTRAINT talent_mediakits_talent_id_fkey FOREIGN KEY (talent_id) REFERENCES talents(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.talent_meldungen ADD CONSTRAINT talent_meldungen_kanal_id_fkey FOREIGN KEY (kanal_id) REFERENCES talent_kanaele(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.talent_meldungen_talent ADD CONSTRAINT talent_meldungen_talent_talent_id_fkey FOREIGN KEY (talent_id) REFERENCES talents(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.talent_notizen ADD CONSTRAINT talent_notizen_talent_id_fkey FOREIGN KEY (talent_id) REFERENCES talents(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.talent_ordner ADD CONSTRAINT talent_ordner_talent_id_fkey FOREIGN KEY (talent_id) REFERENCES talents(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.talent_personen ADD CONSTRAINT talent_personen_matrix_user_id_fkey FOREIGN KEY (matrix_user_id) REFERENCES ally_personen(matrix_user_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.talent_personen ADD CONSTRAINT talent_personen_talent_id_fkey FOREIGN KEY (talent_id) REFERENCES talents(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.talent_profil_papierkorb ADD CONSTRAINT talent_profil_papierkorb_talent_id_fkey FOREIGN KEY (talent_id) REFERENCES talents(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.talent_sofortabrufe ADD CONSTRAINT talent_sofortabrufe_talent_id_fkey FOREIGN KEY (talent_id) REFERENCES talents(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.talent_ui_zustand ADD CONSTRAINT talent_ui_zustand_zugang_id_fkey FOREIGN KEY (zugang_id) REFERENCES talent_zugaenge(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.talent_web_sitzungen ADD CONSTRAINT talent_web_sitzungen_zugang_id_fkey FOREIGN KEY (zugang_id) REFERENCES talent_zugaenge(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.talent_zielgruppen ADD CONSTRAINT talent_zielgruppen_kanal_id_fkey FOREIGN KEY (kanal_id) REFERENCES talent_kanaele(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.talent_zugaenge ADD CONSTRAINT talent_zugaenge_talent_id_fkey FOREIGN KEY (talent_id) REFERENCES talents(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.talents ADD CONSTRAINT talents_rolle_fkey FOREIGN KEY (rolle) REFERENCES ally_rollen(schluessel) ON UPDATE CASCADE ON DELETE SET NULL;

ALTER TABLE ONLY public.talents_briefing_ergebnisse ADD CONSTRAINT talents_briefing_ergebnisse_briefing_id_fkey FOREIGN KEY (briefing_id) REFERENCES talents_briefings(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.talents_briefing_freigaben ADD CONSTRAINT talents_briefing_freigaben_briefing_id_fkey FOREIGN KEY (briefing_id) REFERENCES talents_briefings(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.talents_briefing_freigaben ADD CONSTRAINT talents_briefing_freigaben_person_fkey FOREIGN KEY (person) REFERENCES ally_personen(matrix_user_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.talents_briefing_laeufe ADD CONSTRAINT talents_briefing_laeufe_briefing_id_fkey FOREIGN KEY (briefing_id) REFERENCES talents_briefings(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.talents_meine_liste ADD CONSTRAINT talents_meine_liste_person_fkey FOREIGN KEY (person) REFERENCES ally_personen(matrix_user_id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY public.talents_meine_liste ADD CONSTRAINT talents_meine_liste_talent_id_fkey FOREIGN KEY (talent_id) REFERENCES talents(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.talents_zahlen_vorrat ADD CONSTRAINT talents_zahlen_vorrat_talent_id_fkey FOREIGN KEY (talent_id) REFERENCES talents(id) ON DELETE CASCADE;

CREATE TRIGGER ally_einstellungen_fix BEFORE INSERT OR DELETE OR UPDATE ON public.ally_einstellungen FOR EACH ROW EXECUTE FUNCTION ally_fix_einstellungen_trigger();

CREATE TRIGGER ally_einstellungen_superadmin_liste BEFORE INSERT OR DELETE OR UPDATE ON public.ally_einstellungen FOR EACH ROW EXECUTE FUNCTION ally_superadmin_liste_schutz();

CREATE TRIGGER ally_nutzer_rechte_fix BEFORE INSERT OR DELETE OR UPDATE ON public.ally_nutzer_rechte FOR EACH ROW EXECUTE FUNCTION ally_fix_rechte_trigger();

CREATE TRIGGER ally_nutzer_rechte_rolle AFTER INSERT OR DELETE OR UPDATE ON public.ally_nutzer_rechte FOR EACH ROW EXECUTE FUNCTION ally_nutzer_rechte_rolle();

CREATE TRIGGER ally_nutzer_rechte_superadmin_liste BEFORE INSERT OR UPDATE ON public.ally_nutzer_rechte FOR EACH ROW EXECUTE FUNCTION ally_superadmin_liste_schutz();

CREATE TRIGGER ally_nutzer_rechte_superadmin_schutz BEFORE DELETE OR UPDATE ON public.ally_nutzer_rechte FOR EACH ROW EXECUTE FUNCTION ally_superadmin_schutz();

CREATE TRIGGER ally_testdaten_trennung BEFORE INSERT OR UPDATE ON public.ally_nutzer_rechte FOR EACH ROW EXECUTE FUNCTION ally_testdaten_trennung();

CREATE TRIGGER talent_rechte_schutz BEFORE INSERT OR UPDATE ON public.ally_nutzer_rechte FOR EACH ROW EXECUTE FUNCTION talent_rechte_schutz();

CREATE TRIGGER ally_person_rechte_aktualisieren_schutz BEFORE INSERT OR UPDATE OF recht ON public.ally_person_rechte FOR EACH ROW EXECUTE FUNCTION ally_aktualisieren_schutz();

CREATE TRIGGER ally_person_rechte_reichweite_passt BEFORE INSERT OR UPDATE OF recht, reichweite, wirkung ON public.ally_person_rechte FOR EACH ROW EXECUTE FUNCTION ally_reichweite_passt();

CREATE CONSTRAINT TRIGGER talent_chat_erlaubnis_schutz AFTER INSERT OR DELETE OR UPDATE ON public.ally_person_rechte DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION talent_chat_erlaubnis_schutz();

CREATE TRIGGER talent_rechte_schutz BEFORE INSERT OR UPDATE ON public.ally_person_rechte FOR EACH ROW EXECUTE FUNCTION talent_rechte_schutz();

CREATE TRIGGER ally_personen_kennung AFTER INSERT ON public.ally_personen FOR EACH ROW EXECUTE FUNCTION ally_personen_kennung_merken();

CREATE TRIGGER ally_personen_sitzungen_weg AFTER DELETE ON public.ally_personen FOR EACH ROW EXECUTE FUNCTION ally_personen_sitzungen_weg();

CREATE CONSTRAINT TRIGGER talent_chat_erlaubnis_schutz AFTER INSERT OR UPDATE OF rolle, talent_id ON public.ally_personen DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION talent_chat_erlaubnis_schutz();

CREATE TRIGGER talent_chat_kennung_pruefen BEFORE INSERT OR UPDATE OF matrix_user_id ON public.ally_personen FOR EACH ROW EXECUTE FUNCTION talent_chat_kennung_pruefen();

CREATE TRIGGER talent_person_bruecke AFTER UPDATE OF email, pw_hash, zugang_aktiv, letzte_anmeldung, fehlversuche, gesperrt_bis ON public.ally_personen FOR EACH ROW EXECUTE FUNCTION talent_person_bruecke();

CREATE TRIGGER talent_person_schutz BEFORE INSERT OR DELETE OR UPDATE ON public.ally_personen FOR EACH ROW EXECUTE FUNCTION talent_person_schutz();

CREATE TRIGGER ally_rechte_schutz BEFORE UPDATE ON public.ally_rechte FOR EACH ROW EXECUTE FUNCTION ally_rechte_schutz();

CREATE CONSTRAINT TRIGGER talent_chat_erlaubnis_schutz AFTER UPDATE OF schluessel, art, archiviert_am ON public.ally_rollen DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION talent_chat_erlaubnis_schutz();

CREATE TRIGGER talent_rollen_art_schutz BEFORE UPDATE OF art ON public.ally_rollen FOR EACH ROW EXECUTE FUNCTION talent_rollen_art_schutz();

CREATE CONSTRAINT TRIGGER talent_rollen_profil_pflicht AFTER INSERT ON public.ally_rollen DEFERRABLE INITIALLY DEFERRED FOR EACH ROW WHEN ((new.art = 'talent'::text)) EXECUTE FUNCTION talent_rollen_art_schutz();

CREATE TRIGGER ally_rollen_rechte_aktualisieren_schutz BEFORE INSERT OR UPDATE OF recht ON public.ally_rollen_rechte FOR EACH ROW EXECUTE FUNCTION ally_aktualisieren_schutz();

CREATE TRIGGER ally_rollen_rechte_reichweite_passt BEFORE INSERT OR UPDATE OF recht, reichweite ON public.ally_rollen_rechte FOR EACH ROW EXECUTE FUNCTION ally_reichweite_passt();

CREATE CONSTRAINT TRIGGER talent_chat_erlaubnis_schutz AFTER DELETE OR UPDATE ON public.ally_rollen_rechte DEFERRABLE INITIALLY DEFERRED FOR EACH ROW WHEN ((old.recht = 'talent_chat'::text)) EXECUTE FUNCTION talent_chat_erlaubnis_schutz();

CREATE TRIGGER talent_rechte_schutz BEFORE INSERT OR UPDATE ON public.ally_rollen_rechte FOR EACH ROW EXECUTE FUNCTION talent_rechte_schutz();

CREATE TRIGGER talent_rollen_profil_schutz BEFORE DELETE OR UPDATE ON public.ally_rollen_rechte FOR EACH ROW EXECUTE FUNCTION talent_rollen_profil_schutz();

CREATE TRIGGER talent_rechte_schutz BEFORE INSERT OR UPDATE ON public.ally_speicherort_rechte FOR EACH ROW EXECUTE FUNCTION talent_rechte_schutz();

CREATE TRIGGER ally_systemnachrichten_testdaten BEFORE INSERT OR UPDATE ON public.ally_systemnachrichten FOR EACH ROW EXECUTE FUNCTION ally_systemnachricht_testdaten_schutz();

CREATE TRIGGER ally_ui_funktion_schalter_fix BEFORE INSERT OR DELETE OR UPDATE ON public.ally_ui_funktion_schalter FOR EACH ROW EXECUTE FUNCTION ally_fix_schalter_trigger();

CREATE TRIGGER ki_verbrauch_ohne_preis AFTER INSERT ON public.ki_verbrauch FOR EACH ROW WHEN ((new.kosten_usd IS NULL)) EXECUTE FUNCTION ki_verbrauch_ohne_preis_trigger();

CREATE TRIGGER plattform_vertrag_fix BEFORE UPDATE ON public.plattform_vertrag FOR EACH ROW EXECUTE FUNCTION ally_fix_vertrag_trigger();

CREATE TRIGGER talent_daten_bruecke AFTER INSERT ON public.talent_bereich FOR EACH ROW EXECUTE FUNCTION talent_daten_bruecke();

CREATE TRIGGER ally_testdaten_trennung BEFORE INSERT ON public.talent_berichte FOR EACH ROW EXECUTE FUNCTION ally_testdaten_trennung();

CREATE CONSTRAINT TRIGGER talent_chat_erlaubnis_schutz AFTER INSERT OR UPDATE OF chat_an ON public.talent_chat DEFERRABLE INITIALLY DEFERRED FOR EACH ROW WHEN (new.chat_an) EXECUTE FUNCTION talent_chat_erlaubnis_schutz();

CREATE TRIGGER ally_testdaten_trennung BEFORE INSERT OR UPDATE ON public.talent_kampagne_talents FOR EACH ROW EXECUTE FUNCTION ally_testdaten_trennung();

CREATE TRIGGER ally_testdaten_trennung BEFORE INSERT OR UPDATE ON public.talent_kampagnen FOR EACH ROW EXECUTE FUNCTION ally_testdaten_trennung();

CREATE TRIGGER talent_kanal_tage_doppelt_akt AFTER UPDATE ON public.talent_kanal_tage REFERENCING NEW TABLE AS neu FOR EACH STATEMENT EXECUTE FUNCTION talents_doppelt_nach_abruf();

CREATE TRIGGER talent_kanal_tage_doppelt_neu AFTER INSERT ON public.talent_kanal_tage REFERENCING NEW TABLE AS neu FOR EACH STATEMENT EXECUTE FUNCTION talents_doppelt_nach_abruf();

CREATE TRIGGER talent_manuell_werte_doppelt AFTER INSERT OR UPDATE ON public.talent_manuell_werte FOR EACH ROW EXECUTE FUNCTION talents_doppelt_nach_wert();

CREATE TRIGGER ally_testdaten_trennung BEFORE INSERT OR UPDATE ON public.talent_personen FOR EACH ROW EXECUTE FUNCTION ally_testdaten_trennung();

CREATE TRIGGER talent_rechte_schutz BEFORE INSERT OR UPDATE ON public.talent_personen FOR EACH ROW EXECUTE FUNCTION talent_rechte_schutz();

CREATE TRIGGER talents_meine_liste_zustaendig AFTER INSERT ON public.talent_personen FOR EACH ROW EXECUTE FUNCTION talents_meine_liste_zustaendig();

CREATE TRIGGER talent_chat_kennung_pruefen BEFORE INSERT OR UPDATE OF matrix_user_id ON public.talent_zugaenge FOR EACH ROW EXECUTE FUNCTION talent_chat_kennung_pruefen();

CREATE TRIGGER talent_zugang_bruecke AFTER INSERT OR DELETE OR UPDATE ON public.talent_zugaenge FOR EACH ROW EXECUTE FUNCTION talent_zugang_bruecke();

CREATE TRIGGER ally_testdaten_trennung BEFORE INSERT ON public.talents FOR EACH ROW EXECUTE FUNCTION ally_testdaten_trennung();

CREATE TRIGGER talent_daten_bruecke AFTER UPDATE OF name, kuenstlername, status ON public.talents FOR EACH ROW EXECUTE FUNCTION talent_daten_bruecke();

CREATE TRIGGER talents_kampagnen_pk_talent_weg AFTER DELETE ON public.talents FOR EACH ROW EXECUTE FUNCTION talents_kampagnen_pk_talent_weg();

CREATE TRIGGER talents_zahlen_vorrat_summe_weg AFTER DELETE ON public.talents FOR EACH STATEMENT EXECUTE FUNCTION talents_zahlen_vorrat_summe_weg();

CREATE TRIGGER talents_briefings_fix BEFORE INSERT OR DELETE OR UPDATE ON public.talents_briefings FOR EACH ROW EXECUTE FUNCTION talents_briefing_fix_trigger();

ALTER SEQUENCE public.ally_assistent_verlauf_id_seq OWNED BY public.ally_assistent_verlauf.id;

ALTER SEQUENCE public.ally_benachrichtigungen_id_seq OWNED BY public.ally_benachrichtigungen.id;

ALTER SEQUENCE public.ally_chat_auftraege_id_seq OWNED BY public.ally_chat_auftraege.id;

ALTER SEQUENCE public.ally_email_aenderungen_id_seq OWNED BY public.ally_email_aenderungen.id;

ALTER SEQUENCE public.ally_ergebnisse_id_seq OWNED BY public.ally_ergebnisse.id;

ALTER SEQUENCE public.ally_kalender_abos_id_seq OWNED BY public.ally_kalender_abos.id;

ALTER SEQUENCE public.ally_personen_id_seq OWNED BY public.ally_personen.id;

ALTER SEQUENCE public.ally_speicherort_rechte_id_seq OWNED BY public.ally_speicherort_rechte.id;

ALTER SEQUENCE public.ally_systemnachrichten_id_seq OWNED BY public.ally_systemnachrichten.id;

ALTER SEQUENCE public.ally_unternehmen_id_seq OWNED BY public.ally_unternehmen.id;

ALTER SEQUENCE public.beleg_verarbeitung_id_seq OWNED BY public.beleg_verarbeitung.id;

ALTER SEQUENCE public.ki_verbrauch_id_seq OWNED BY public.ki_verbrauch.id;

ALTER SEQUENCE public.klaerungsfaelle_id_seq OWNED BY public.klaerungsfaelle.id;

ALTER SEQUENCE public.lieferanten_aliases_id_seq OWNED BY public.lieferanten_aliases.id;

ALTER SEQUENCE public.lieferanten_kategorie_mapping_id_seq OWNED BY public.lieferanten_kategorie_mapping.id;

ALTER SEQUENCE public.mail_absender_regeln_id_seq OWNED BY public.mail_absender_regeln.id;

ALTER SEQUENCE public.mail_absender_regeln_papierkorb_id_seq OWNED BY public.mail_absender_regeln_papierkorb.id;

ALTER SEQUENCE public.mail_kategorien_id_seq OWNED BY public.mail_kategorien.id;

ALTER SEQUENCE public.mail_klassifizierung_log_id_seq OWNED BY public.mail_klassifizierung_log.id;

ALTER SEQUENCE public.mail_rueckfragen_id_seq OWNED BY public.mail_rueckfragen.id;

ALTER SEQUENCE public.marketing_hintergruende_id_seq OWNED BY public.marketing_hintergruende.id;

ALTER SEQUENCE public.marketing_papierkorb_id_seq OWNED BY public.marketing_papierkorb.id;

ALTER SEQUENCE public.marketing_posts_id_seq OWNED BY public.marketing_posts.id;

ALTER SEQUENCE public.marketing_themen_id_seq OWNED BY public.marketing_themen.id;

ALTER SEQUENCE public.meta_rueckmeldungen_id_seq OWNED BY public.meta_rueckmeldungen.id;

ALTER SEQUENCE public.n8n_chat_histories_id_seq OWNED BY public.n8n_chat_histories.id;

ALTER SEQUENCE public.postfach_empfang_neustart_id_seq OWNED BY public.postfach_empfang_neustart.id;

ALTER SEQUENCE public.postfach_empfang_stoerung_id_seq OWNED BY public.postfach_empfang_stoerung.id;

ALTER SEQUENCE public.shopify_berichte_id_seq OWNED BY public.shopify_berichte.id;

ALTER SEQUENCE public.shopify_laeufe_id_seq OWNED BY public.shopify_laeufe.id;

ALTER SEQUENCE public.shopify_lauf_dateien_id_seq OWNED BY public.shopify_lauf_dateien.id;

ALTER SEQUENCE public.shopify_loeschauftraege_id_seq OWNED BY public.shopify_loeschauftraege.id;

ALTER SEQUENCE public.shopify_shops_id_seq OWNED BY public.shopify_shops.id;

ALTER SEQUENCE public.speicher_ordner_protokoll_id_seq OWNED BY public.speicher_ordner_protokoll.id;

ALTER SEQUENCE public.sync_mapping_id_seq OWNED BY public.sync_mapping.id;

ALTER SEQUENCE public.talent_ablage_dateien_id_seq OWNED BY public.talent_ablage_dateien.id;

ALTER SEQUENCE public.talent_aufgaben_id_seq OWNED BY public.talent_aufgaben.id;

ALTER SEQUENCE public.talent_beitraege_id_seq OWNED BY public.talent_beitraege.id;

ALTER SEQUENCE public.talent_bericht_vorlagen_id_seq OWNED BY public.talent_bericht_vorlagen.id;

ALTER SEQUENCE public.talent_berichte_id_seq OWNED BY public.talent_berichte.id;

ALTER SEQUENCE public.talent_chat_verlauf_id_seq OWNED BY public.talent_chat_verlauf.id;

ALTER SEQUENCE public.talent_deliverable_versionen_id_seq OWNED BY public.talent_deliverable_versionen.id;

ALTER SEQUENCE public.talent_deliverables_id_seq OWNED BY public.talent_deliverables.id;

ALTER SEQUENCE public.talent_doppelt_verlauf_id_seq OWNED BY public.talent_doppelt_verlauf.id;

ALTER SEQUENCE public.talent_einladungen_id_seq OWNED BY public.talent_einladungen.id;

ALTER SEQUENCE public.talent_erinnerungen_lauf_id_seq OWNED BY public.talent_erinnerungen_lauf.id;

ALTER SEQUENCE public.talent_erinnerungsregeln_id_seq OWNED BY public.talent_erinnerungsregeln.id;

ALTER SEQUENCE public.talent_importe_id_seq OWNED BY public.talent_importe.id;

ALTER SEQUENCE public.talent_kampagne_links_id_seq OWNED BY public.talent_kampagne_links.id;

ALTER SEQUENCE public.talent_kampagnen_id_seq OWNED BY public.talent_kampagnen.id;

ALTER SEQUENCE public.talent_kampagnen_papierkorb_id_seq OWNED BY public.talent_kampagnen_papierkorb.id;

ALTER SEQUENCE public.talent_kanaele_id_seq OWNED BY public.talent_kanaele.id;

ALTER SEQUENCE public.talent_ki_anfragen_id_seq OWNED BY public.talent_ki_anfragen.id;

ALTER SEQUENCE public.talent_ki_auftraege_id_seq OWNED BY public.talent_ki_auftraege.id;

ALTER SEQUENCE public.talent_ki_auswertungen_id_seq OWNED BY public.talent_ki_auswertungen.id;

ALTER SEQUENCE public.talent_ki_texte_id_seq OWNED BY public.talent_ki_texte.id;

ALTER SEQUENCE public.talent_konzept_ziele_id_seq OWNED BY public.talent_konzept_ziele.id;

ALTER SEQUENCE public.talent_konzepte_id_seq OWNED BY public.talent_konzepte.id;

ALTER SEQUENCE public.talent_loesch_dateien_id_seq OWNED BY public.talent_loesch_dateien.id;

ALTER SEQUENCE public.talent_mail_entwuerfe_id_seq OWNED BY public.talent_mail_entwuerfe.id;

ALTER SEQUENCE public.talent_mail_zuordnung_id_seq OWNED BY public.talent_mail_zuordnung.id;

ALTER SEQUENCE public.talent_manuell_vorschlaege_id_seq OWNED BY public.talent_manuell_vorschlaege.id;

ALTER SEQUENCE public.talent_manuell_werte_id_seq OWNED BY public.talent_manuell_werte.id;

ALTER SEQUENCE public.talent_markensuche_kriterien_id_seq OWNED BY public.talent_markensuche_kriterien.id;

ALTER SEQUENCE public.talent_markensuche_laeufe_id_seq OWNED BY public.talent_markensuche_laeufe.id;

ALTER SEQUENCE public.talent_markensuche_treffer_id_seq OWNED BY public.talent_markensuche_treffer.id;

ALTER SEQUENCE public.talent_notizen_id_seq OWNED BY public.talent_notizen.id;

ALTER SEQUENCE public.talent_ordner_id_seq OWNED BY public.talent_ordner.id;

ALTER SEQUENCE public.talent_profil_papierkorb_id_seq OWNED BY public.talent_profil_papierkorb.id;

ALTER SEQUENCE public.talent_widerrufe_id_seq OWNED BY public.talent_widerrufe.id;

ALTER SEQUENCE public.talent_zugaenge_id_seq OWNED BY public.talent_zugaenge.id;

ALTER SEQUENCE public.talents_id_seq OWNED BY public.talents.id;

COMMENT ON COLUMN public.ablage_einstellung.verbunden_am IS 'Migration 89: Verbindung geprüft und Zugangsdaten gesetzt (Schritt 1); Ordner-Browser möglich, auch bevor umgestellt wird';

COMMENT ON TABLE public.ally_app_symbol IS 'Eigenes App-Symbol der Installation (Stefan 20.10.2026, Migration 60, BA4b): ein PNG, quadratisch, ohne Transparenz, mindestens 512 Pixel. Ohne Zeile nutzt ALLY 20 die Bildmarke aus dem Corporate Design.';

COMMENT ON TABLE public.ally_email_aenderungen IS 'Änderung der eigenen E-Mail-Adresse (Profil, neue Oberfläche): gilt erst nach Bestätigung über den Link an die neue Adresse (Migration 70).';

COMMENT ON TABLE public.ally_fassung IS 'Migration 188 (Konzept Installation und Updates C.1): eingespielte Fassungen dieser Installation; es gilt die zuletzt eingespielte (ally_fassung_aktuell).';

COMMENT ON TABLE public.ally_firma IS 'Stammdaten der Firma dieser Instanz (genau eine Zeile)';

COMMENT ON TABLE public.ally_fix_einstellungen IS 'Migration 172 (B8b): Einstellungen, die der Admin ändern darf und der Superadmin fixieren kann';

COMMENT ON TABLE public.ally_fixierung IS 'Migration 172 (B8b): fixiert (true) oder frei (false) je Einstellung und Eintrag; ohne Zeile frei';

COMMENT ON TABLE public.ally_kalender_abos IS 'Kalender-Abo (ICS) je Person oder Talent (BA8, Migration 63): GET app/kalender?t=<Code> (ALLY 19), nur eigene Termine, Aufgaben und Deadlines; neu erzeugen widerruft die alte Adresse.';

COMMENT ON TABLE public.ally_kalender_verbindungen IS 'Vorbereitet (BA8, Migration 63): Google Kalender je Person (OAuth, Scope calendar.events, Schlüssel verschlüsselt). Noch ohne Ablauf; Einstellung google_kalender_bereit.';

COMMENT ON VIEW public.ally_nutzer_postfaecher IS 'Migration 90: berechnet (ally_postfach_zustaendig), nur lesen. Archiv: ally_nutzer_postfaecher_alt';

COMMENT ON TABLE public.ally_person_rechte IS 'Migration 155 (G4/F6): eigene Rechte je Account zusätzlich zur Rolle. plus = Recht dazu (mit Reichweite), minus = Recht der Rolle fällt weg. Admin/Superadmin nie hier.';

COMMENT ON TABLE public.ally_personen IS 'Eine Zeile je Person: Name, E-Mail, Chat-Adresse, Zugang zur Oberfläche. Rechte, Zuständigkeiten, Schalter und persönliche Werte hängen über matrix_user_id daran.';

COMMENT ON COLUMN public.ally_personen.aktiv IS 'Person aktiv: Chat mit Ally und Anmeldung möglich';

COMMENT ON COLUMN public.ally_personen.benutzername IS 'Nur noch für die Umstellung: bisheriger Anmeldename, wird nach der ersten Anmeldung mit neuem Verfahren geleert';

COMMENT ON COLUMN public.ally_personen.zugang_aktiv IS 'Zugang zur Oberfläche freigegeben';

COMMENT ON COLUMN public.ally_personen.pw_alt_name IS 'Gesetzt, solange das Passwort noch nach altem Verfahren (mit Benutzernamen) gespeichert ist';

COMMENT ON COLUMN public.ally_personen.ruecksetz_hash IS 'Prüfsumme des Links aus der Mail „Passwort vergessen“ (gilt eine Stunde, nur einmal)';

COMMENT ON COLUMN public.ally_personen.talent_id IS 'Migration 155: Talent dieser Person (ein Login für alle, F3). Leer = kein Talent.';

COMMENT ON COLUMN public.ally_postfaecher.art IS 'Migration 90: persoenlich (gehört eigentuemer) oder gemeinsam (gehört der Firma, Sichtbarkeit über die Rolle: Recht postfach_<platz>)';

COMMENT ON COLUMN public.ally_postfaecher.eigentuemer IS 'Migration 90: matrix_user_id der Person, der das persönliche Postfach gehört';

COMMENT ON COLUMN public.ally_rechte.nur_selbst IS 'Migration 155: Recht gilt nur für die eigenen Daten eines Talents (Reichweite selbst).';

COMMENT ON COLUMN public.ally_rollen.vorlage IS 'Migration 155: Schlüssel der Rollen-Vorlage eines Pakets (G2); leer = eigene Rolle (G3).';

COMMENT ON COLUMN public.ally_rollen.standard IS 'Migration 155: Standard-Rechte der Vorlage {recht: reichweite|null} für „Auf Standard zurücksetzen“ (G2).';

COMMENT ON TABLE public.ally_systemnachricht_absender IS 'Absender-Postfach für Systemnachrichten (BA8, Migration 63): Postfach-Platz oder eigenes Postfach, Absendername, SMTP-Server ohne Passwort. Ohne Zeile wird nichts versendet.';

COMMENT ON TABLE public.ally_systemnachrichten IS 'Systemnachrichten per Mail (BA8, Migration 63): Erinnerungen und Termine an Talents, Zugangslinks, Passwort vergessen, Testnachricht. Versand nur über SYS 9, genau einmal (ref), gedrosselt.';

COMMENT ON TABLE public.ally_updates IS 'Migration 188 (Konzept Installation und Updates C.1/C.6): Protokoll je Update-Lauf (Schritte, Sicherungen, Ergebnis); höchstens ein Lauf zugleich (ally_updates_ein_lauf).';

COMMENT ON TABLE public.mail_schriften IS 'Schriften, die in allen gängigen Mailprogrammen funktionieren. stapel = CSS font-family mit Ersatzschriften.';

COMMENT ON TABLE public.marketing_papierkorb IS 'Migration 133: Papierkorb der Marketing-Themen (Bauart A). daten = {thema, posts} als JSON (to_jsonb). Der Ordner im Speicherort bleibt bis zum endgültigen Löschen. Neue NOT-NULL-Spalten in marketing_themen/marketing_posts: Schnappschüsse anpassen (docs/migrationen-regeln.md).';

COMMENT ON COLUMN public.marketing_papierkorb.grund IS 'Migration 133: warum das endgültige Löschen zuletzt nicht ging (Ordner nicht eindeutig erkannt, Fehler im Speicherort …).';

COMMENT ON COLUMN public.marketing_papierkorb.stand IS 'Migration 133: Ergebnis des letzten endgültigen Löschens (gesperrt, nicht_erkannt, fehler), sonst NULL.';

COMMENT ON TABLE public.marketing_pk_loeschauftraege IS 'Migration 133: endgültiges Löschen von Themen mit Ordner (festgehaltene Auswahl, an die Sitzung gebunden, 15 Minuten gültig, einmal verwendbar). frei = in diesem Auftrag freigegebene Einträge (nur diese nimmt der Abschluss als gelöscht an).';

COMMENT ON TABLE public.plattform_vertrag IS 'Vertrag dieser Instanz: Paket, freigeschaltete Module, Personen-Grenze, KI-Budget. Pflegt nur der Plattform-Betreiber.';

COMMENT ON COLUMN public.plattform_vertrag.ki_budget_eur IS 'Monatsbudget für KI in Euro; leer = keine Grenze';

COMMENT ON COLUMN public.plattform_vertrag.usd_eur IS 'Kurs: 1 US-Dollar = x Euro; leer = Kosten nur in Dollar';

COMMENT ON TABLE public.postfach_empfang_beobachtung IS 'Migration 179 (P6): letzte Lückenprüfung je Postfach (nur Zahlen).';

COMMENT ON TABLE public.postfach_empfang_neustart IS 'Migration 182 (P6): Neustarts je Postfach; beim dritten in 24 Stunden meldet MAIL 6 einmal „Empfang gestört“.';

COMMENT ON TABLE public.postfach_empfang_stoerung IS 'Migration 179 (P6): Störungen des Empfangs je Postfach; MAIL 6 startet den Workflow neu (unpublish/publish) und meldet nach 3 Fehlversuchen.';

COMMENT ON COLUMN public.postfach_plaetze.versand_erlaubt IS 'Migration 88: Schalter „Versand erlauben“ (null = noch nie entschieden = aus; true nach erstem erfolgreich geprüftem Versand, bis jemand ausschaltet)';

COMMENT ON COLUMN public.shopify_berichte.intervall IS 'Migration 91: aus (Nur auf Abruf), einmalig, tag, woche, monat, quartal, jahr';

COMMENT ON COLUMN public.shopify_berichte.intervall_tag IS 'woche: 1–7 (Mo–So); monat: 1–28 oder 0 = letzter Tag; quartal: 1–28 (Tag im ersten Monat des Quartals); jahr: 1–31 (mit intervall_monat)';

COMMENT ON COLUMN public.shopify_berichte.mail_betreff IS 'Migration 92: Betreff der Mail mit Platzhaltern ({Berichtsname} …); NULL = Standardbetreff (shopify_mail_standard)';

COMMENT ON COLUMN public.shopify_berichte.mail_html IS 'Migration 92: Text der Mail (einfaches HTML aus dem Editor: p, div, br, b, i, u, a) mit Platzhaltern; NULL = Standardtext';

COMMENT ON COLUMN public.shopify_berichte.signatur_an IS 'Migration 92: Signatur des Absender-Postfachs anhängen';

COMMENT ON COLUMN public.shopify_berichte.signatur_html IS 'Migration 96: eigene Signatur nur für diesen Bericht; leer = Signatur des Absender-Postfachs';

COMMENT ON COLUMN public.shopify_berichte.ki_hinweis IS 'Migration 96: Hinweis „Erstellt mit KI-Unterstützung.“ unter der Signatur der Mail';

COMMENT ON COLUMN public.shopify_berichte.papierkorb_mit_shop IS 'Migration 109: mit seinem Shop in den Papierkorb gegangen (kommt mit dem Shop zurück).';

COMMENT ON COLUMN public.shopify_laeufe.mail IS 'Migration 92: fertige Mail des Laufs (an, von, betreff, html, text, test) – auch im Testmodus („würde senden“)';

COMMENT ON TABLE public.shopify_lauf_dateien IS 'Migration 87: erzeugte Dateien (PDF/CSV) je Lauf eines Verkaufsberichts (nicht bei Partner-Abrufen); Download nur über ALLY 20 (shopify_datei_web). Wird nicht automatisch gelöscht.';

COMMENT ON TABLE public.shopify_loeschauftraege IS 'Migration 109: endgültiges Löschen aus dem Papierkorb (festgehaltene Auswahl, an die Sitzung gebunden, 15 Minuten gültig; nach 30 Tagen aufgeräumt).';

COMMENT ON COLUMN public.talent_ablage_dateien.id IS 'm49';

COMMENT ON COLUMN public.talent_ablage_dienste.dienst IS 'm49';

COMMENT ON COLUMN public.talent_ablage_ordner.dienst IS 'm49';

COMMENT ON TABLE public.talent_abruf_versuche IS 'Migration 195 (Stefan 01.11.2026, Abrufzeiten): letzter Versuch je Kanal und Abruf-Art im Zeitplan-Lauf (gesetzt, wenn die Liste den Kanal ausgibt), Zahl der Versuche am Tag (tag, Europe/Berlin). Nur für Wartezeit, höchstens 3 tägliche Versuche am Tag und die Sperre eines laufenden Zeitplan-Laufs (talents_abrufzeit_faellig, talents_abrufzeit_laeuft); keine Kennzahlen.';

COMMENT ON COLUMN public.talent_beitraege.nicht_mehr_vorhanden_seit IS 'Migration 151: seit wann der Beitrag als nicht mehr vorhanden gilt (in zwei vollständigen Beitragslisten der Plattform mindestens 20 Stunden auseinander nicht enthalten; gelöscht oder nicht mehr sichtbar); NULL = vorhanden';

COMMENT ON COLUMN public.talent_beitraege.fehlt_seit IS 'Migration 151: seit wann der Beitrag in der vollständigen Beitragsliste der Plattform fehlt (erstes Fehlen, noch unbestätigt); NULL = nicht fehlend';

COMMENT ON TABLE public.talent_beitrag_bilder IS 'Migration 193 (Stefan 01.11.2026, „Bild speichern“): Vorschaubild einer Instagram-Story, einmal und dauerhaft gespeichert, solange die Meta-Adresse galt (TALENTS 2). Wie ally_cd_dateien: base64; vor dem Speichern verkleinert (TALENTS 2, längste Seite höchstens 480 px, JPEG), höchstens 150 KB, nur JPEG oder PNG. Gelöscht mit dem Beitrag.';

COMMENT ON TABLE public.talent_bereich IS 'Talent-Bereich je Talent (BA7, Migration 62): Briefing vom Management und Schalter „Sichtbar im Talent-Bereich“. Ohne Zeile gilt: alles sichtbar, kein Briefing.';

COMMENT ON TABLE public.talent_doppelt_entscheidungen IS 'Doppelte Daten (Migration 65): Entscheidung je manuellem Wert (automatisch = manuellen archivieren, manuell = automatischen für den Zeitraum nicht zählen). Später änderbar.';

COMMENT ON TABLE public.talent_doppelt_verlauf IS 'Doppelte Daten (Migration 65): Verlauf je manuellem Wert – erkannt (Hochladen/Abruf), entschieden (Person), geändert.';

COMMENT ON TABLE public.talent_einladung_rueckwege IS 'BA8 (Migration 63): Einladung wurde aus dem Talent-Bereich geöffnet (tb_verbinden); bis zu diesem Zeitpunkt führt ALLY 16 nach dem Verbinden zurück in den Talent-Bereich.';

COMMENT ON TABLE public.talent_kampagnen_papierkorb IS 'Migration 131: Papierkorb der Kampagnen (Bauart A). daten = Zeilen der Tabellen als JSON (to_jsonb, Systemnachrichten ohne geheim). Neue Spalten späterer Migrationen fehlen in alten Schnappschüssen (beim Wiederherstellen NULL): NOT-NULL-Spalten dann hier ergänzen.';

COMMENT ON COLUMN public.talent_kampagnen_papierkorb.talents IS 'Migration 131: Talents der Kampagne beim Löschen (Recht an einer Kampagne im Papierkorb).';

COMMENT ON COLUMN public.talent_ki_anfragen.id IS 'm49';

COMMENT ON COLUMN public.talent_ki_auftraege.id IS 'm49';

COMMENT ON COLUMN public.talent_ki_auswertungen.id IS 'm49';

COMMENT ON COLUMN public.talent_ki_texte.id IS 'm49';

COMMENT ON COLUMN public.talent_ki_themen.beitrag_id IS 'm49';

COMMENT ON COLUMN public.talent_konzept_angaben.talent_id IS 'm49';

COMMENT ON COLUMN public.talent_konzept_ziele.id IS 'm49';

COMMENT ON COLUMN public.talent_konzepte.id IS 'm49';

COMMENT ON TABLE public.talent_loesch_ankuendigungen IS 'Migration 54 (Stefan 19.10.2026): Ankündigung einer Löschung fällig seit (Ersatz, wenn die Chat-Ankündigung nicht zugestellt wird).';

COMMENT ON TABLE public.talent_loesch_dateien IS 'm51: Dateien gelöschter Talents, die im Speicherort entfernt werden (Stefan 18.10.2026)';

COMMENT ON COLUMN public.talent_mail_entwuerfe.id IS 'm49';

COMMENT ON COLUMN public.talent_mail_zuordnung.id IS 'm49';

COMMENT ON COLUMN public.talent_markensuche_kriterien.id IS 'm49';

COMMENT ON COLUMN public.talent_markensuche_laeufe.id IS 'm49';

COMMENT ON COLUMN public.talent_markensuche_treffer.id IS 'm49';

COMMENT ON TABLE public.talent_mediakits IS 'Migration 196 (Stefan 01.11.2026, Konzept Mediakit „Entscheidung“): das selbst gestaltete Mediakit (PDF) je Talent – Datei in der Talents-Ablage (art mediakit, Ordner Mediakits), wer und wann hochgeladen; Link zum Teilen nur als sha256 (link_hash, nie im Klartext), widerrufbar, mit Zahl der Abrufe.';

COMMENT ON TABLE public.talent_profil_papierkorb IS 'Migration 130: Papierkorb der Unterobjekte des Talent-Profils (Bauart A). daten = Zeilen als JSON (to_jsonb, Systemnachrichten ohne geheim). Neue NOT-NULL-Spalten der Quelltabellen brauchen einen Standardwert oder eine Anpassung hier (N2).';

COMMENT ON TABLE public.talent_sofortabrufe IS 'Migration 194 (Stefan 01.11.2026, „Daten jetzt abrufen“): letzter von Hand gestarteter Abruf je Talent (wann, von wem, welche Kanäle). Nur für die Sperre, solange der Abruf läuft (talents_sofortabruf_laeuft); keine Kennzahlen.';

COMMENT ON TABLE public.talent_web_sitzungen IS 'Sitzungen der Rolle Talent (BA7, Migration 62), getrennt von ally_web_sitzungen. Talent-ID immer nur aus der Sitzung.';

COMMENT ON TABLE public.talent_widerrufe IS 'm51: Widerruf von YouTube-/TikTok-Zugängen bei der Plattform nach dem Trennen (Stefan 18.10.2026)';

COMMENT ON TABLE public.talent_zugaenge IS 'Zugang eines Talents zur Oberfläche (BA7, Migration 62). Talents stehen nie in ally_personen. Einladungslink (Hash, verschlüsselt zum erneuten Anzeigen), eigenes Passwort (bcrypt über SHA-256 aus dem Browser).';

COMMENT ON TABLE public.talents_briefing_ergebnisse IS 'Migration 180: Ergebnisse der KI-Analysen je Person mit Kopf und vollem Text; nach_zeitplan mit periode (T = Tag, W = Woche, M = Monat) = einmal je Zeitraum. uebernommen = aus ally_ergebnisse (vor 180, Kopf nicht erfasst).';

COMMENT ON TABLE public.talents_briefing_freigaben IS 'Migration 177 (B10b): Freigabe eines Briefings durch die Person, die es angelegt hat, für weitere Personen (sehen, nicht ändern).';

COMMENT ON TABLE public.talents_briefing_laeufe IS 'Migration 177 (B10b): geplante Briefings, die gesendet wurden (je Briefing, Person und Kalenderwoche); Verlauf auf der Seite des Briefings. Text: ally_ergebnisse.';

COMMENT ON TABLE public.talents_briefings IS 'Briefings (Konzept 15, Migration 175): art manager = Briefing für Manager/innen; zeitraum letzte_7_tage = die 7 Tage vor dem Tag der Erstellung, Vergleich mit den 7 Tagen davor; intervall woche mit tag (1 = Montag) und uhrzeit (Europe/Berlin); empfaenger zustaendige = Manager/innen der Talents mit eingeschaltetem persönlichem Schalter Wochen-Briefing; versand chat. Verlauf: ally_ergebnisse (Art talents_wochen_briefing).';

COMMENT ON COLUMN public.talents_briefings.zeitraum IS 'Migration 180: Zeitraum der Daten: letzte_7_tage, letzte_30_tage, vormonat; verglichen mit dem gleich langen Zeitraum davor (Vormonat: mit dem Monat davor).';

COMMENT ON COLUMN public.talents_briefings.tag IS 'Migration 180: Wochentag 1 bis 7 (wöchentlich) bzw. Tag des Monats 1 bis 28 (monatlich); täglich und nur von Hand ohne Bedeutung.';

COMMENT ON COLUMN public.talents_briefings.empfaenger IS 'Migration 177: zustaendige = Manager/innen der Talents (wie bisher) und dazu die gewählten Personen; personen = nur die gewählten Personen.';

COMMENT ON COLUMN public.talents_briefings.versand IS 'Migration 180: Zustellung der KI-Analyse: ally = nur in Ally (Standard), chat = zusätzlich im Chat, mail = zusätzlich per Mail (jeweils, soweit die Person erreichbar ist).';

COMMENT ON COLUMN public.talents_briefings.standard IS 'Migration 177: das Briefing aus Migration 175 (Tag und Uhrzeit auch unter Einstellungen › KI-Funktionen, fixierbar); nicht löschbar.';

COMMENT ON COLUMN public.talents_briefings.talents IS 'Migration 177: weitere Talents für alle Empfänger (jede Person nur die Talents, die sie sehen darf), zusätzlich zu ihren eigenen.';

COMMENT ON COLUMN public.talents_briefings.absender IS 'Migration 180: Absender-Postfach der Mail (nur Postfächer mit eigenem Ablauf); NULL = Absender für Systemnachrichten.';

COMMENT ON COLUMN public.talents_briefings.mail_betreff IS 'Migration 180: eigener Betreff mit Platzhaltern; NULL = Standard (talents_briefing_mail_standard).';

COMMENT ON COLUMN public.talents_briefings.mail_html IS 'Migration 180: eigener Text vor der KI-Analyse mit Platzhaltern; NULL = Standard.';

COMMENT ON COLUMN public.talents_briefings.signatur_html IS 'Migration 180: eigene Signatur nur für diese KI-Analyse; NULL = Signatur des Absender-Postfachs (wenn signatur_an).';

COMMENT ON COLUMN public.talents_briefings.testdaten IS 'Migration 180: von einer Test-Person angelegt (wie Verkaufsberichte): Mail nur im Testmodus („würde senden“), es geht nie eine Mail raus.';

COMMENT ON TABLE public.talents_meine_liste IS 'Migration 147 (Konzept D): eigene Liste „Meine Talents“ je Person; gibt keine Rechte (Sichtbarkeit: talent_sichtbar).';

COMMENT ON TABLE public.talents_zahlen_vorrat IS 'Migration 138 (Stefan 24.10.2026, 10:38): vorgerechnete talents_zahlen der Startseite. Je aktivem Talent eine Zeile für talents_uebersicht (28 Tage und Vorzeitraum, alle Kanäle, manuelle Daten an) und für talents_kachel (7 und 7 Tage); talent_id NULL = Summe aller aktiven Talents (Übersicht). Gilt nur bei gleichem Zeitraum und gleichem Datenstand (talents_vorrat_staende); sonst wird live gerechnet. Befüllt von talents_zahlen_vorrat_fuellen (TALENTS 2, stündlich nach dem Abruf). Darf jederzeit geleert werden.';

COMMENT ON FUNCTION public.ally_webhook_aussen() IS 'Migration 190 (D.1): /webhook/<Vorsatz> der außen eingetragenen Adressen.';

COMMENT ON FUNCTION public.ally_webhook_praefix_aussen() IS 'Migration 190 (D.1): Vorsatz der außen eingetragenen Webhook-Adressen; Standard web, sonst Einstellung webhook_praefix_aussen.';
