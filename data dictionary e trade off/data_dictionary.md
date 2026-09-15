Data Dictionary

Schema DB NIS2/ACN — Progetto Work "Progettare e realizzare una base dati relazionale per catalogare asset, servizi, dipendenze e responsabilità utili alla compilazione dei profili richiesti dall'ACN nell'ambito della NIS2"


Convenzioni utilizzate
PK = chiave primaria. FK = chiave esterna. PK/FK = chiave primaria che è anche chiave esterna (class-table inheritance ISA di ElementoCritico, o chiave composta di una tabella ponte N:N).
Pattern A (storicizzazione leggera): dati normativi/esterni, raramente modificati (es. RequisitoMisura, TipoIncidente) — semplice validità da/a sulla stessa riga, nessuna tabella *Storico dedicata.
Pattern B (storicizzazione piena): dati operativi/interni dichiarati periodicamente ad ACN. Ogni tabella soggetta a Pattern B ha una tabella gemella *Storico, alimentata da un trigger BEFORE UPDATE che, ad ogni modifica osservabile, chiude la versione corrente (valido_a) e inserisce una nuova riga storica collegata a un evento di LogEstrazione.
ISA (generalizzazione a chiave primaria condivisa): ElementoCritico è la superclasse di Asset e Servizio. Le tre tabelle condividono lo stesso valore di id (sequenza seq_elemento_critico), risolvendo per costruzione il problema delle due FK nullable alternative.
Opzione B (tabelle di applicabilità): per ogni dominio chiuso normativo (misure, tipi di incidente, tipi di documento) l'applicabilità a soggetti essenziali/importanti è modellata con una bridge table dedicata a FK reali (es. MisuraApplicabilita), non con una tabella di registro polimorfica.


Tabelle trasversali

Lookup di sistema, registro di audit e tracciamento degli invii al portale ACN. Non appartengono a una singola macro-area concettuale ma sono referenziate da più aree.


TipoSoggettoNIS
Campo	        Tipo	        Vincoli	Note
id	            NUMBER(5)	    PK	Identificativo (1=ESSENZIALE, 2=IMPORTANTE)
codice	        VARCHAR2(20)	NOT NULL, UNIQUE, CHECK IN ('ESSENZIALE','IMPORTANTE')	Codice testuale del tipo
descrizione	    VARCHAR2(255)	Descrizione estesa

RegistroTabelle
Campo	        Tipo	        Vincoli	Note
id	            NUMBER(5)	    PK	Identificativo
nome_tabella    VARCHAR2(100)	NOT NULL, UNIQUE	Nome della tabella loggabile

LogEstrazione
Campo	                Tipo	            Vincoli	Note
id	                    NUMBER              PK	Identificativo
registro_tabella_id	    NUMBER(5)	        NOT NULL, FK → RegistroTabelle	Tabella d'origine dell'evento
record_id	            NUMBER(19)	        NOT NULL	Riferimento debole (non FK) al record d'origine
utente	                VARCHAR2(100)	    NOT NULL	Utente DB che ha generato l'evento
data_ora	            TIMESTAMP	        DEFAULT SYSTIMESTAMP, NOT NULL	Momento dell'evento
tipo_operazione	        VARCHAR2(30)	    NOT NULL, CHECK IN Tipologia dell'evento
snapshot_dati	        CLOB	            Copia opzionale dei dati al momento del log

InvioACN
Campo	                Tipo	            Vincoli	Note
id	                    NUMBER              PK	Identificativo
soggetto_nis_id	        NUMBER(19)	        NOT NULL, FK → SoggettoNIS	Soggetto che ha effettuato l'invio
tipo_invio	            VARCHAR2(25)	    NOT NULL, CHECK IN Fase del ciclo di compliance ACN
data_invio	            TIMESTAMP	        DEFAULT SYSTIMESTAMP, NOT NULL	Data/ora dell'invio
periodo_riferimento	    NUMBER(10)	        NOT NULL	Anno di riferimento



Area A   Anagrafica Soggetto NIS

Dati identificativi del soggetto NIS e delle sue strutture di contatto/governance, così come richiesti in fase di registrazione (art. 11) e aggiornamento annuale (art. 16) sulla piattaforma ACN. SoggettoNIS è la radice dell'intero schema.


SoggettoNIS
Campo	                Tipo	            Vincoli	Note
id	                    NUMBER              PK	Identificativo
codice_fiscale	        VARCHAR2(16)	    NOT NULL, UNIQUE	Codice fiscale del soggetto
denominazione	        VARCHAR2(255)	    NOT NULL	Ragione sociale/denominazione
indirizzo_sede_legale	VARCHAR2(255)	    NOT NULL	Sede legale
pec	                    VARCHAR2(255)	    NOT NULL	Domicilio digitale (PEC)
email_funzionale	    VARCHAR2(255)	    nullable	Email ordinaria funzionale
telefono	            VARCHAR2(30)	    nullable	Recapito telefonico
fatturato	            NUMERIC(15,2)	    nullable	Nullable: la PA ne è esente
bilancio	            NUMERIC(15,2)	    nullable	Nullable: la PA ne è esente
n_dipendenti	        NUMBER(10)	        nullable	Numero dipendenti
tipo_soggetto_id	    NUMBER(5)	        NOT NULL, FK → TipoSoggettoNIS	Essenziale/Importante
data_creazione	        TIMESTAMP	        DEFAULT SYSTIMESTAMP, NOT NULL	Data di censimento del record


SoggettoNISStorico
Campo	                Tipo	            Vincoli	Note
id	                    NUMBER              PK	Identificativo
soggetto_nis_id	        NUMBER(19)	        NOT NULL, FK → SoggettoNIS	Soggetto a cui si riferisce la versione
versione	            NUMBER(10)	        NOT NULL	Numero progressivo di versione
tipo_soggetto_id	    NUMBER(5)	        NOT NULL, FK → TipoSoggettoNIS	Snapshot del tipo soggetto
valido_da	            TIMESTAMP	        NOT NULL	Inizio validità della versione
valido_a	            TIMESTAMP	        nullable (NULL = versione corrente)	Fine validità della versione
log_estrazione_id	    NUMBER(19)	        NOT NULL, FK → LogEstrazione	Evento di audit che ha generato la versione



ImpresaCollegata
Campo	                Tipo	            Vincoli	Note
id	                    NUMBER          	PK	Identificativo
soggetto_nis_id	        NUMBER(19)	        NOT NULL, FK → SoggettoNIS	Soggetto NIS di riferimento
ragione_sociale	        VARCHAR2(255)	    NOT NULL	Ragione sociale dell'impresa collegata
codice_fiscale	        VARCHAR2(16)	    NOT NULL	Codice fiscale dell'impresa collegata
parametro_collegamento	VARCHAR2(255)	    nullable	Natura del collegamento (es. quota di partecipazione)


PuntoDiContatto
Campo	                Tipo	            Vincoli	Note
id	                    NUMBER          	PK	Identificativo
soggetto_nis_id	        NUMBER(19)	        NOT NULL, FK → SoggettoNIS	Soggetto NIS di riferimento
nome	                VARCHAR2(255)	    NOT NULL	Nominativo
ruolo	                VARCHAR2(30)	    NOT NULL, CHECK IN Ruolo del contatto
email	                VARCHAR2(255)	    nullable	Email
telefono	            VARCHAR2(30)	    nullable	Telefono
delega	                VARCHAR2(255)	    nullable	Estremi della delega del rappresentante legale


OrganoAmministrazione
Campo	                Tipo	            Vincoli	Note
id	                    NUMBER              PK	Identificativo
soggetto_nis_id	        NUMBER(19)	        NOT NULL, FK → SoggettoNIS	Soggetto NIS di riferimento
nome	                VARCHAR2(255)	    NOT NULL	Nominativo
ruolo	                VARCHAR2(100)	    NOT NULL	Es. "Amministratore Delegato", "Consigliere"


DominioInternet
Campo	                Tipo	            Vincoli	Note
id	                    NUMBER              PK	Identificativo
soggetto_nis_id     	NUMBER(19)	        NOT NULL, FK → SoggettoNIS	Soggetto NIS di riferimento
nome_dominio	        VARCHAR2(255)	NOT NULL	Nome a dominio


IndirizzoIPPubblico
Campo	                Tipo	            Vincoli	Note
id	                    NUMBER          	PK	Identificativo
soggetto_nis_id	        NUMBER(19)	        NOT NULL, FK → SoggettoNIS	Soggetto NIS di riferimento
indirizzo	            VARCHAR2(45)	    NOT NULL	Indirizzo IP (formato testuale, compatibile IPv4/IPv6)


AccordoCondivisioneInformazioni
Campo	                Tipo	            Vincoli	Note
id	                    NUMBER (IDENTITY)	PK	Identificativo
soggetto_nis_id	        NUMBER(19)	        NOT NULL, FK → SoggettoNIS	Soggetto NIS titolare dell'accordo
controparte_soggetto_id	NUMBER(19)	        nullable, FK → SoggettoNIS	Controparte, se censita come soggetto NIS
controparte	            VARCHAR2(255)	    NOT NULL	Etichetta/nome della controparte (sempre valorizzato)
descrizione	            VARCHAR2(500)	    nullable	Descrizione dell'accordo
data_stipula	        DATE	            nullable	Data di stipula
stato	                VARCHAR2(10)	    DEFAULT 'ATTIVO', NOT NULL, CHECK IN Stato corrente dell'accordo


AccordoCondivisioneInformazioniStorico
Campo	                Tipo	            Vincoli	Note
id	                    NUMBER          	PK	Identificativo
accordo_id	            NUMBER(19)	        NOT NULL, FK → AccordoCondivisioneInformazioni	Accordo di riferimento
versione	            NUMBER(10)	        NOT NULL	Numero progressivo di versione
controparte	            VARCHAR2(255)	    NOT NULL	Snapshot
descrizione	            VARCHAR2(500)	    nullable	Snapshot
stato	                VARCHAR2(10)	    NOT NULL	Snapshot
valido_da	            TIMESTAMP	        NOT NULL	Inizio validità versione
valido_a	            TIMESTAMP	        nullable (NULL = corrente)	Fine validità versione
log_estrazione_id	    NUMBER(19)	        NOT NULL, FK → LogEstrazione	Evento di audit



Area B/C — Elemento Critico (ISA Asset / Servizio)


ElementoCritico
Campo	                Tipo	            Vincoli	Note
id	                    NUMBER(19)	        PK, DEFAULT seq_elemento_critico.NEXTVAL
tipo	                VARCHAR2(10)	    NOT NULL, CHECK IN ('ASSET','SERVIZIO')	Discriminante di sottoclasse
nome	                VARCHAR2(255)	    NOT NULL	Nome dell'elemento critico
soggetto_nis_id	        NUMBER(19)	        NOT NULL, FK → SoggettoNIS	Soggetto titolare
stato	                VARCHAR2(10)	    DEFAULT 'ATTIVO', NOT NULL, CHECK IN ('ATTIVO','DISMESSO')	Stato corrente
data_inizio_validita	TIMESTAMP	        DEFAULT SYSTIMESTAMP, NOT NULL	Inizio validità
data_fine_validita	    TIMESTAMP	        nullable (NULL = attivo)	Fine validità


ElementoCriticoStorico
Campo	                Tipo	            Vincoli	Note
id	                    NUMBER              PK	Identificativo
elemento_critico_id	    NUMBER(19)	        NOT NULL, FK → ElementoCritico	Elemento di riferimento
versione	            NUMBER(10)	        NOT NULL	Numero progressivo di versione
nome	                VARCHAR2(255)	    NOT NULL	Snapshot
soggetto_nis_id     	NUMBER(19)	        NOT NULL, FK → SoggettoNIS	Snapshot
stato	                VARCHAR2(10)	    NOT NULL	Snapshot
valido_da	            TIMESTAMP	        NOT NULL	Inizio validità versione
valido_a	            TIMESTAMP	        nullable (NULL = corrente)	Fine validità versione
log_estrazione_id	    NUMBER(19)	        NOT NULL, FK → LogEstrazione	Evento di audit


Asset
Campo	                Tipo	            Vincoli	Note
id	                    NUMBER(19)	        PK, FK → ElementoCritico	Chiave primaria condivisa con la superclasse
tipo_asset	            VARCHAR2(20)	    NOT NULL, CHECK IN	Tipologia dell'asset
rilevante	            NUMBER(1)	        DEFAULT 0, NOT NULL, CHECK IN (0,1)	


Servizio
Campo	                Tipo	            Vincoli	Note
id	                    NUMBER(19)	        PK, FK → ElementoCritico	Chiave primaria condivisa con la superclasse
descrizione	            VARCHAR2(500)	    nullable	Descrizione del servizio
categoria_rilevanza	    VARCHAR2(50)	    nullable	Nullable


ServizioStatoMembro
Campo	                Tipo	            Vincoli	Note
servizio_id	            NUMBER(19)	        PK (parte), FK → Servizio	Servizio di riferimento
stato_membro	        CHAR(2)	            PK (parte), NOT NULL	Codice ISO 3166-1 alpha-2


AssetServizio
Campo	                Tipo	            Vincoli	Note
id	                    NUMBER (IDENTITY)	PK	Identificativo
asset_id	            NUMBER(19)	NOT NULL, FK → Asset	Asset coinvolto
servizio_id         	NUMBER(19)	NOT NULL, FK → Servizio	Servizio coinvolto
stato	                VARCHAR2(10)	DEFAULT 'ATTIVA', NOT NULL, CHECK IN ('ATTIVA','CESSATA')


AssetServizioStorico
Campo	                Tipo	            Vincoli	Note
id	                    NUMBER (IDENTITY)	PK	Identificativo
asset_servizio_id	    NUMBER(19)	        NOT NULL, FK → AssetServizio	Relazione di riferimento
versione	            NUMBER(10)	NOT NULL	Numero progressivo di versione
stato	                VARCHAR2(10)	NOT NULL	Snapshot
valido_da           	TIMESTAMP	NOT NULL	Inizio validità versione
valido_a	            TIMESTAMP	nullable (NULL = corrente)	Fine validità versione
log_estrazione_id      	NUMBER(19)	NOT NULL, FK → LogEstrazione	Evento di audit



Area D — Fornitori e Dipendenze

Fornitori rilevanti NIS ai sensi dell'art. 18 D.Lgs. 138/2024 e loro dipendenze verso gli elementi critici del soggetto.

Fornitore
Campo	                Tipo	            Vincoli	Note
id	                    NUMBER          	PK	Identificativo
denominazione	        VARCHAR2(255)	    NOT NULL	Denominazione del fornitore
codice_fiscale	        VARCHAR2(16)	    NOT NULL, UNIQUE	Codice fiscale
paese_sede_legale	    CHAR(2)	            NOT NULL	Codice ISO 3166-1 alpha-2 del paese della sede legale


FornitoreStorico
Campo	                Tipo	            Vincoli	Note
id	                    NUMBER          	PK	Identificativo
fornitore_id	        NUMBER(19)	        NOT NULL, FK → Fornitore	Fornitore di riferimento
versione	            NUMBER(10)	        NOT NULL	Numero progressivo di versione
denominazione	        VARCHAR2(255)	    NOT NULL	Snapshot
paese_sede_legale	    CHAR(2)         	NOT NULL	Snapshot
valido_da	            TIMESTAMP	        NOT NULL	Inizio validità versione
valido_a	            TIMESTAMP	        nullable (NULL = corrente)	Fine validità versione
log_estrazione_id	    NUMBER(19)	NOT NULL, FK → LogEstrazione	Evento di audit


CodiceCPV
Campo	                Tipo	            Vincoli	Note
id	                    NUMBER          	PK	Identificativo
codice	                VARCHAR2(10)	    NOT NULL, UNIQUE	Codice CPV
descrizione	            VARCHAR2(255)	    NOT NULL	Descrizione della categoria merceologica


FornitoreCPV
Campo	                Tipo	            Vincoli	Note
fornitore_id	        NUMBER(19)	        PK (parte), FK → Fornitore	Fornitore
cpv_id	                NUMBER(19)	        PK (parte), FK → CodiceCPV	Codice CPV


Dipendenza
Campo	                Tipo	            Vincoli	Note
id	                    NUMBER          	PK	Identificativo
fornitore_id	        NUMBER(19)	        NOT NULL, FK → Fornitore	Fornitore
elemento_critico_id	    NUMBER(19)      	NOT NULL, FK → ElementoCritico	Asset o servizio dipendente
criterio_rilevanza	    VARCHAR2(20)    	NOT NULL, CHECK IN ('ICT','NON_FUNGIBILE')	Criterio di rilevanza ex art. 18
tipologia_fornitura	    VARCHAR2(255)	    nullable	Descrizione della fornitura
referente_contatto	    VARCHAR2(255)	    nullable	Referente per la fornitura
stato	                VARCHAR2(10)	    DEFAULT 'ATTIVA', NOT NULL, CHECK IN ('ATTIVA','CESSATA')	Stato del legame


DipendenzaStorico
Campo	                Tipo	            Vincoli	Note
id	                    NUMBER             	PK	Identificativo
dipendenza_id	        NUMBER(19)	        NOT NULL, FK → Dipendenza	Dipendenza di riferimento
versione	            NUMBER(10)	        NOT NULL	Numero progressivo di versione
criterio_rilevanza	    VARCHAR2(20)	    NOT NULL	Snapshot
tipologia_fornitura	    VARCHAR2(255)	    nullable	Snapshot
referente_contatto	    VARCHAR2(255)	    nullable	Snapshot
stato	                VARCHAR2(10)	    NOT NULL	Snapshot
valido_da	            TIMESTAMP	        NOT NULL	Inizio validità versione
valido_a	            TIMESTAMP	        nullable (NULL = corrente)	Fine validità versione
log_estrazione_id      	NUMBER(19)	        NOT NULL, FK → LogEstrazione	Evento di audit



Area E — Incidenti

Processo di gestione degli incidenti di sicurezza: tipologie/soglie normative, ciclo di notifica ad ACN, indicatori di compromissione, timeline e attività di risposta.


TipoIncidente
Campo	                Tipo	            Vincoli	Note
id	                    NUMBER          	PK	Identificativo
codice	                VARCHAR2(10)	    NOT NULL	Codice tipologia (es. 'IS-1')
descrizione	            VARCHAR2(500)	    NOT NULL	Descrizione della tipologia
versione_determinazione	VARCHAR2(50)	    DEFAULT '164179/2025', NOT NULL	Determinazione ACN di riferimento
data_inizio_validita	DATE	            DEFAULT 2025-04-30, NOT NULL	Inizio validità normativa
data_fine_validita	    DATE	            nullable (NULL = in vigore)	Fine validità normativa


IncidenteApplicabilita
Campo	                Tipo	            Vincoli	Note
tipo_incidente_id	    NUMBER(19)	        PK (parte), FK → TipoIncidente	Tipologia di incidente
tipo_soggetto_id	    NUMBER(5)	        PK (parte), FK → TipoSoggettoNIS	Tipo di soggetto a cui si applica


CategoriaIncidente
Campo	                Tipo	            Vincoli	Note
id	                    NUMBER (IDENTITY)	PK	Identificativo
nome	                VARCHAR2(50)	NOT NULL, UNIQUE	


Incidente
Campo	                Tipo	            Vincoli	Note
id	                    NUMBER          	PK	Identificativo
tipo_incidente_id	    NUMBER(19)	        NOT NULL, FK → TipoIncidente	Tipologia normativa
soggetto_nis_id	        NUMBER(19)	        NOT NULL, FK → SoggettoNIS	Soggetto coinvolto
categoria_id	        NUMBER(19)	        nullable, FK → CategoriaIncidente	Categoria operativa 
data_evidenza	        TIMESTAMP	        NOT NULL	Momento di rilevazione
gravita	                VARCHAR2(20)	    nullable, CHECK IN ('BASSA','MEDIA','ALTA','CRITICA')	Gravità stimata
root_cause	            VARCHAR2(500)	    nullable	Causa originaria, spesso nota solo a posteriori


IncidenteElementoCritico
Campo	                Tipo	            Vincoli	Note
incidente_id	        NUMBER(19)	        PK (parte), FK → Incidente	Incidente
elemento_critico_id	    NUMBER(19)	        PK (parte), FK → ElementoCritico	Elemento coinvolto


NotificaIncidente
Campo	                Tipo	            Vincoli	Note
id	                    NUMBER              PK	Identificativo
incidente_id	        NUMBER(19)	        NOT NULL, FK → Incidente	Incidente di riferimento
tipo	                VARCHAR2(25)	    NOT NULL, CHECK IN Tipo di comunicazione
data_trasmissione	    TIMESTAMP	        NOT NULL	Data/ora di trasmissione
contenuto	            CLOB	            nullable	Testo della comunicazione


IndicatoreCompromissione
Campo	                Tipo	            Vincoli	Note
id	                    NUMBER              PK	Identificativo
incidente_id	        NUMBER(19)	        NOT NULL, FK → Incidente	Incidente di riferimento
tipo	                VARCHAR2(20)	    NOT NULL	Tipologia dell'indicatore
valore	                VARCHAR2(500)	    NOT NULL	Valore dell'indicatore
data_rilevazione	    TIMESTAMP	        DEFAULT SYSTIMESTAMP, NOT NULL	Momento di rilevazione


TimelineEvento
Campo	                Tipo	            Vincoli	Note
id	                    NUMBER          	PK	Identificativo
incidente_id	        NUMBER(19)	        NOT NULL, FK → Incidente	Incidente di riferimento
data_ora	            TIMESTAMP	        NOT NULL	Momento dell'evento
descrizione	            VARCHAR2(500)	    NOT NULL	Descrizione dell'evento
fase	                VARCHAR2(20)	    NOT NULL Fase del processo


AttivitaRisposta
Campo	                Tipo                Vincoli	Note
id	                    NUMBER          	PK	Identificativo
incidente_id	        NUMBER(19)	        NOT NULL, FK → Incidente	Incidente di riferimento
fase	                VARCHAR2(20)	    NOT NULL 	Fase dell'attività
descrizione	            VARCHAR2(500)	    NOT NULL	Descrizione dell'attività
motivazione	            VARCHAR2(500)	    nullable	Motivazione della scelta
struttura_coinvolta_id	NUMBER(19)	        nullable, FK → PersonaleGovernance	
esito	                VARCHAR2(255)	    nullable	Esito dell'attività
data_esecuzione	        TIMESTAMP	        DEFAULT SYSTIMESTAMP, NOT NULL	Momento di esecuzione



Area F — Governance

Personale di governance, documenti (piani, politiche) e stato di attuazione delle misure di sicurezza previste dalla Determinazione ACN 164179/2025.


PersonaleGovernance
Campo	                Tipo	            Vincoli	Note
id	                    NUMBER          	PK	Identificativo
nome	                VARCHAR2(255)	    NOT NULL	Nominativo
ruolo	                VARCHAR2(100)	    NOT NULL	Es. "Amministratore di sistema"
soggetto_nis_id     	NUMBER(19)	        NOT NULL, FK → SoggettoNIS	Soggetto di appartenenza
punto_contatto_id	    NUMBER(19)	        nullable, FK → PuntoDiContatto	Collegamento opzionale al punto di contatto


TipoDocumentoGovernance
Campo	                Tipo	            Vincoli	Note
id	                    NUMBER              PK	Identificativo
codice	                VARCHAR2(20)	    NOT NULL, UNIQUE	Es. 'GV.RM-03', 'RS.MA-01'
nome	                VARCHAR2(255)	    NOT NULL	Nome del documento (es. "Piano di gestione dei rischi")
ambito_politica	        VARCHAR2(10)	    nullable	Lettera d'ambito politica ('a'..'p')


DocumentoGovernanceApplicabilita
Campo	                Tipo            	Vincoli	Note
tipo_documento_id	    NUMBER(19)	        PK (parte), FK → TipoDocumentoGovernance	Tipo di documento
tipo_soggetto_id	    NUMBER(5)	        PK (parte), FK → TipoSoggettoNIS	Tipo di soggetto a cui si applica


DocumentoGovernance
Campo	                Tipo	            Vincoli	Note
id	                    NUMBER          	PK	Identificativo
soggetto_nis_id	        NUMBER(19)	        NOT NULL, FK → SoggettoNIS	Soggetto titolare
tipo_documento_id	    NUMBER(19)	        NOT NULL, FK → TipoDocumentoGovernance	Tipologia del documento
data_approvazione	    DATE	            nullable	Data di approvazione
approvato_da	        NUMBER(19)	        nullable, FK → OrganoAmministrazione	Organo che ha approvato
data_ultimo_riesame	    DATE	            nullable	Data dell'ultimo riesame
versione	            VARCHAR2(20)    	nullable	Versione documentale (etichetta libera)


DocumentoGovernanceStorico
Campo	                Tipo	            Vincoli	Note
id	                    NUMBER              PK	Identificativo
documento_id        	NUMBER(19)	        NOT NULL, FK → DocumentoGovernance	Documento di riferimento
versione            	NUMBER(10)	        NOT NULL	Numero progressivo di versione
valido_da	            TIMESTAMP	        NOT NULL	Inizio validità versione
valido_a	            TIMESTAMP	        nullable (NULL = corrente)	Fine validità versione
log_estrazione_id	    NUMBER(19)	        NOT NULL, FK → LogEstrazione	Evento di audit


DocumentoGovernanceElementoCritico
Campo	                Tipo            	Vincoli	Note
id	                    NUMBER              PK	Identificativo
documento_id	        NUMBER(19)	        NOT NULL, FK → DocumentoGovernance	Documento
elemento_critico_id	    NUMBER(19)      	NOT NULL, FK → ElementoCritico	Elemento coperto
stato	                VARCHAR2(10)	    DEFAULT 'ATTIVA', NOT NULL, CHECK IN ('ATTIVA','CESSATA')	Stato del legame


DocumentoGovernanceElementoCriticoStorico
Campo	                Tipo	            Vincoli	Note
id                      NUMBER              PK	Identificativo
documento_elemento_id	NUMBER(19)	        NOT NULL, FK → DocumentoGovernanceElementoCritico	Relazione di riferimento
versione	            NUMBER(10)	        NOT NULL	Numero progressivo di versione
stato	                VARCHAR2(10)	    NOT NULL	Snapshot
valido_da	            TIMESTAMP	        NOT NULL	Inizio validità versione
valido_a	            TIMESTAMP	        nullable (NULL = corrente)	Fine validità versione
log_estrazione_id	    NUMBER(19)	        NOT NULL, FK → LogEstrazione	Evento di audit


MisuraSicurezza
Campo	                Tipo	            Vincoli	Note
id	                    NUMBER              PK	Identificativo
codice	                VARCHAR2(20)	    NOT NULL, UNIQUE	Codice misura (es. 'GV.SC-04')
categoria	            VARCHAR2(100)	    NOT NULL	Es. "Gestione del rischio della catena di approvvigionamento"
descrizione	            VARCHAR2(500)	    NOT NULL	Descrizione della misura


RequisitoMisura
Campo	                Tipo	            Vincoli	Note
id	                    NUMBER              PK	Identificativo
codice	                VARCHAR2(30)	    NOT NULL	Codice del requisito, stabile nel tempo
misura_id	            NUMBER(19)	        NOT NULL, FK → MisuraSicurezza	Misura di appartenenza
numero_punto	        NUMBER(10)      	NOT NULL	Numero del punto nella misura
testo	                VARCHAR2(1000)  	NOT NULL	Testo del requisito
versione_determinazione	VARCHAR2(50)	    DEFAULT '164179/2025', NOT NULL	Determinazione ACN di riferimento
data_inizio_validita	DATE                DEFAULT 2025-04-30, NOT NULL	Inizio validità normativa
data_fine_validita	    DATE	            nullable (NULL = in vigore)	Fine validità normativa


MisuraApplicabilita
Campo	                Tipo	            Vincoli	Note
requisito_id	        NUMBER(19)	        PK (parte), FK → RequisitoMisura	Requisito
tipo_soggetto_id	    NUMBER(5)	        PK (parte), FK → TipoSoggettoNIS	Tipo di soggetto a cui si applica


StatoAdempimentoRequisito
Campo	                Tipo	            Vincoli	Note
id	                    NUMBER          	PK	Identificativo
requisito_id	        NUMBER(19)	        NOT NULL, FK → RequisitoMisura	Requisito valutato
soggetto_nis_id	        NUMBER(19)	        NOT NULL, FK → SoggettoNIS	Soggetto valutato
stato	                VARCHAR2(25)	    NOT NULL Stato di attuazione
data_valutazione	    DATE	            DEFAULT CURRENT_DATE, NOT NULL	Data della valutazione
responsabile_id	        NUMBER(19)	        nullable, FK → PersonaleGovernance	Responsabile della valutazione
documento_evidenza_id	NUMBER(19)	        nullable, FK → DocumentoGovernance	Documento a evidenza dell'attuazione
note	                VARCHAR2(1000)	    nullable	Note libere


StatoAdempimentoRequisitoStorico
Campo	                Tipo            	Vincoli	Note
id	                    NUMBER              PK	Identificativo
stato_adempimento_id	NUMBER(19)	        NOT NULL, FK → StatoAdempimentoRequisito	Attestazione di riferimento
versione	            NUMBER(10)	        NOT NULL	Numero progressivo di versione
stato	                VARCHAR2(25)    	NOT NULL	Snapshot
data_valutazione	    DATE	            NOT NULL	
valido_da	            TIMESTAMP	        NOT NULL	Inizio validità versione
valido_a	            TIMESTAMP	        nullable (NULL = corrente)	Fine validità versione
log_estrazione_id   	NUMBER(19)      	NOT NULL, FK → LogEstrazione	Evento di audit

