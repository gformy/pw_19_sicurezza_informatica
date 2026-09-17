# pw_19_sicurezza_informatica
Project Work 19 sulla sicurezza informatica con specifica del decreto NIS e ACN 


Struttura del repository:

├── creazione_utente.sql              -- crea utente/schema di test (da SYSTEM)

├── creazione_schema.sql              -- DDL: 47 tabelle, sequenza, indici

├── popolamento_dati.sql              -- dati di lookup normativi (base)

├── viste.sql                         -- 10 viste + 2 trigger pattern ISA

├── trigger.sql                       -- 9 trigger storicizzazione + 3 blocco DELETE

├── estrazioni.sql                    -- 4 query di estrazione per il profilo ACN

├── procedura_estrazione_csv.sql      -- DIRECTORY + funzione + 5 procedure export CSV

├── lancio_procedura_estrazione_excel.sql  -- blocco PL/SQL di lancio dell'export

├── data dictionary/
│   └── data_dictionary.md            -- ogni tabella e campo, con vincoli e note

├── Schema E-R/
│   └── ER_diagram_NIS2_ACN.png       -- diagramma entità-relazione completo

├── query test/
│   ├── test_popolamento_dati_misure.sql   -- misure di sicurezza (Allegati 1/2)
│   ├── test_dataset_azienda.sql           -- dataset simulato completo
│   └── test_trigger_storicizzazione.sql   -- test isolato dei 9 trigger

└── export excel da test effettuati/
    ├── asset_soggetto_1.csv
    ├── servizi_soggetto_1.csv
    ├── dipendenze_soggetto_1.csv
    └── punti_contatto_soggetto_1.csv


Questo file si concentra sull'uso operativo del database: cosa eseguire, in che ordine, come funziona, cosa è andato storto e come è stato risolto.

Per le specifiche delle tabelle si riporta: 
data dictionary/data_dictionary.md

Per la presa visione dello schema della Banca Dati si riporta:
Schema E-R/ER_diagram_NIS2_ACN.png

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Ordine di esecuzione
1.  creazione_utente.sql (da SYSTEM)
2.  creazione_schema.sql
3.  popolamento_dati.sql
4.  query test/test_popolamento_dati_misure.sql 
    (completa i dati normativi: misure di sicurezza, requisiti, codici CPV — necessario solo se si vuole testare anche StatoAdempimentoRequisito)
5.  viste.sql
6.  trigger.sql
7.  procedura_estrazione_csv.sql 

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Tabelle già popolate — NON toccare a mano

Da popolamento_dati.sql: 
-   TipoSoggettoNIS, 
-   RegistroTabelle, 
-   TipoIncidente, 
-   IncidenteApplicabilita, 
-   CategoriaIncidente, 
-   TipoDocumentoGovernance, 
-  DocumentoGovernanceApplicabilita.
in fase di creazione della struttura d'insieme

e da query test/test_popolamento_dati_misure.sql: 
-   MisuraSicurezza, 
-   RequisitoMisura, 
-   MisuraApplicabilita, 
-   CodiceCPV (sottoinsieme rappresentativo di 5 misure, non l'elenco completo dei 116 requisiti dell'Allegato 2).
in fase preliminare del test

Sono dati normativi: vengono popolati dati che rimangono invariati fino al sorgere di nuova normativa
come si nota ci sono due popolamenti suddivisi in due fasi distinte, perchè?
    -   popolamento_dati.sql rimarranno invariati per tutto l'insieme della struttura
    -   test_popolamento_dati_misure.sql rimangono invariati per l'Anno di studio poichè è possibile una variazione della normativa e di conseguenza un'eliminazione o modifica di essi. 
    Per tanto se non variano rimangono quelli altrimenti si devono variare.

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Tabelle da riempire a mano — dati applicativi

Ordine di dipendenza (si veda query test/test_dataset_azienda.sql come esempio completo già funzionante):

Anagrafica: 

-   SoggettoNIS, 
-   PuntoDiContatto, 
-   OrganoAmministrazione, 
-   ImpresaCollegata, 
-   DominioInternet, 
-   IndirizzoIPPubblico, 
-   AccordoCondivisioneInformazioni

Asset e servizi: 

tramite AssetCompleto / ServizioCompleto (le VISTE, non le tabelle — vedi §3), 
-   AssetServizio, 
-   ServizioStatoMembro

Fornitori: 
-   Fornitore, 
-   FornitoreCPV, 
-   Dipendenza

Governance: 

-   PersonaleGovernance, 
-   DocumentoGovernance, 
-   DocumentoGovernanceElementoCritico, 
-   StatoAdempimentoRequisito

Incidenti (opzionale): 

-   Incidente, 
-   IncidenteElementoCritico, 
-   IndicatoreCompromissione, 
-   TimelineEvento, 
-   AttivitaRisposta, 
-   NotificaIncidente

Invio: InvioACN, sempre con SYSTIMESTAMP o comunque una data successiva alla creazione dei dati sopra 

Le tabelle *Storico non vanno mai riempite a mano: le popolano automaticamente i trigger ad ogni UPDATE.

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Asset e Servizio si inseriscono tramite VISTA, non tabella sql

-   SBAGLIATO (l'id non sarebbe sincronizzato)
INSERT INTO Asset (id, tipo_asset, rilevante) VALUES (1, 'HARDWARE', 1);

-    CORRETTO
INSERT INTO AssetCompleto (nome, soggetto_nis_id, tipo_asset, rilevante)
VALUES ('Server applicativo', 1, 'HARDWARE', 1);

Il trigger INSTEAD OF INSERT (in viste.sql) crea da solo sia la riga in ElementoCritico sia quella nella sottoclasse. Stesso discorso per ServizioCompleto.

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Cadenza di aggiornamento (ciclo di compliance ACN)
Periodo	Tipo di InvioACN	Cosa si aggiorna
Gennaio–Febbraio	REGISTRAZIONE	Prima anagrafica completa (solo soggetti nuovi)
Aprile–Maggio	    AGGIORNAMENTO_ANNUALE	Anagrafica, asset, servizi, fornitori, governance
Durante l'anno	    AGGIORNAMENTO_CONTINUO	Variazioni intermedie
Maggio–Giugno	    CATEGORIZZAZIONE	Categoria di rilevanza dei servizi

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Come funzionano i 14 trigger

-   2 di creazione (INSTEAD OF INSERT, in viste.sql) — su AssetCompleto/ServizioCompleto, creano padre (ElementoCritico) e figlio (Asset/Servizio) da un solo INSERT sulla vista.

-   3 di blocco (BEFORE DELETE, in trigger.sql) — su ElementoCritico/Asset/Servizio, respingono ogni DELETE. 
    Per dismettere un elemento:
        UPDATE ElementoCritico SET stato = 'DISMESSO' WHERE id = :id;

-   9 di storicizzazione (BEFORE UPDATE, in trigger.sql) 
    ad ogni modifica reale, registrano un evento in LogEstrazione, chiudono la versione precedente in *Storico, salvano lo snapshot.

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Estrazione dati: query, viste AS OF, export CSV

-   estrazioni.sql 
    4 query filtrate per azienda (asset critici, servizi erogati, dipendenze da fornitori, punti di contatto) più le varianti "AS OF" sulle viste ProfiloACN_* (in viste.sql), che ricostruiscono lo stato dichiarato in corrispondenza di un invio specifico.

-   procedura_estrazione_csv.sql + lancio_procedura_estrazione_excel.sql
     generano gli stessi estratti come file .csv reali, via UTL_FILE. 
     Esempi già prodotti in export excel da test effettuati.
