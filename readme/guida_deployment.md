Guida al deployment — Schema DB NIS2/ACN

Istruzioni complete per installare Oracle Database, collegarsi con un client SQL e distribuire lo schema, dalla macchina vuota fino ai test funzionali. 
Due percorsi paralleli: 
-   macOS (via Docker, il setup effettivamente usato per lo sviluppo e la validazione di questo progetto)  
-   Windows (via Oracle Database XE nativo, senza Docker).


PERCORSO A — macOS (Oracle in Docker)

A.1 — Prerequisiti

Docker su Mac non gira nativamente (il kernel Linux dei container non esiste su macOS): serve Docker Desktop, che fornisce una piccola macchina virtuale Linux dietro le quinte in modo trasparente.

Scaricare Docker Desktop da https://www.docker.com/products/docker-desktop/ (build corretta per la propria architettura: Apple Silicon o Intel).


A.2 — Creazione dell'istanza Oracle

Dal Terminale:

`bash`
docker pull gvenzl/oracle-xe:21-slim-faststart

Avvio del container (nome oracle21xe, porta 1521 esposta sull'host, password amministrativa da impostare):

`bash`
docker run -d \
  --name oracle21xe \
  -p 1521:1521 \
  -e ORACLE_PASSWORD=CambiaQuestaPassword123 \
  gvenzl/oracle-xe:21-slim-faststart

Il primo avvio richiede alcuni minuti (inizializzazione del database). 

Verificare che sia pronto:

`bash`
docker logs -f oracle21xe

Attendere il messaggio 
## DATABASE IS READY TO USE! 
(poi Ctrl+C per uscire dal log, il container resta in esecuzione). Verifica finale:

`bash`
docker ps

## Deve comparire oracle21xe con stato Up.


A.3 — Installazione del client SQL (DBeaver)

Scaricare DBeaver Community da https://dbeaver.io/download/ (build macOS).
Installare trascinando in Applicazioni, avviare.
Nuova connessione → Oracle → parametri:
`Host` : localhost
`Porta`: 1521
`Nome database` / `Servizio`: XEPDB1 (pluggable database di default dell'immagine gvenzl/oracle-xe)
`Utente`: system
`Password`: quella impostata in ORACLE_PASSWORD (CambiaQuestaPassword123)
`Ruolo`: SYSDBA (o AS SYSDBA a seconda della versione di DBeaver)

## "Test Connection" → deve avere successo. 
Al primo utilizzo, DBeaver scarica automaticamente il driver JDBC Oracle: confermare il download.


A.4 — Creazione dello schema applicativo

Connessi come system (o SYSTEM), eseguire nell'ordine gli script del repository (vedi README.md per il dettaglio di ciascuno):

## creazione_utente.sql

A questo punto disconnettersi e creare una nuova connessione in DBeaver, questa volta con utente nis2_test e la password scelta in creazione_utente.sql — tutti gli script successivi vanno eseguiti da questa connessione, non più come system:

## creazione_schema.sql
## popolamento_dati.sql
## query test/test_popolamento_dati_misure.sql
## viste.sql
## trigger.sql
## procedura_estrazione_csv.sql


A.5 — Popolamento con dati di test e validazione funzionale
## query test/test_dataset_azienda.sql
## query test/test_trigger_storicizzazione.sql

Verifica dei trigger di storicizzazione, blocco cancellazione, e ricostruzione point-in-time: eseguire le query dimostrative incluse in test_dataset_azienda.sql (Parte C) e confrontare l'esito atteso documentato nei commenti del file.


A.6 — Export CSV (specifico per Docker)

UTL_FILE scrive dentro il container, non sul Mac. Prima di eseguire procedura_estrazione_csv.sql, creare la cartella di destinazione nel container:

`bash`
docker exec oracle21xe mkdir -p /tmp/export_nis2

La DIRECTORY Oracle va creata puntando a quel percorso Linux (non un percorso Windows), da utente con privilegi elevati:

`sql`
CREATE OR REPLACE DIRECTORY export_dir AS '/tmp/export_nis2';
GRANT READ, WRITE ON DIRECTORY export_dir TO nis2_test;

Dopo aver lanciato lancio_procedura_estrazione_excel.sql, recuperare i file generati copiandoli sul Mac:

`bash`
docker cp oracle21xe:/tmp/export_nis2 ~/Desktop/export_nis2

I 4 CSV compaiono sulla Scrivania, apribili direttamente in Excel.


A.7 — Arresto/ripresa dell'ambiente

`bash`

## docker stop oracle21xe     # ferma il container, i dati restano salvati
## docker start oracle21xe    # lo riavvia da dove era rimasto
## docker rm -f oracle21xe    # lo elimina definitivamente (dati persi)




PERCORSO B — Windows (Oracle Database XE nativo, senza Docker)

Su Windows Oracle fornisce un installer nativo: non serve un motore di containerizzazione.

B.1 — Download e installazione di Oracle Database XE

Creare un account gratuito su https://www.oracle.com se non già presente (richiesto per il download).
Scaricare `Oracle Database 21c Express Edition (XE)` for Windows x64 da https://www.oracle.com/database/technologies/xe-downloads.html.
Estrarre lo zip ed eseguire setup.exe come amministratore.
Durante l'installazione: confermare il percorso di destinazione, impostare la password amministrativa (utenti SYS e SYSTEM condividono questa password — annotarla, servirà a ogni connessione amministrativa).
Al termine, l'installer avvia automaticamente i servizi Windows necessari (`OracleServiceXE`, `OracleXETNSListener`).

B.2 — Verifica dell'installazione

Da Servizi di Windows (services.msc): verificare che OracleServiceXE e OracleXETNSListener risultino In esecuzione. Se non lo sono, avviarli manualmente da lì.

In alternativa, da Prompt dei comandi:

cmd
sqlplus system/PasswordScelta@localhost:1521/XEPDB1

Se si ottiene il prompt SQL>, l'istanza è raggiungibile.


B.3 — Installazione del client SQL

Su Windows lo strumento più naturale è `Oracle SQL Developer`, il client ufficiale e gratuito di Oracle — non richiede il download separato di un driver JDBC come DBeaver, ed è pensato apposta per questo scenario.

Scaricare `Oracle SQL Developer` da https://www.oracle.com/database/sqldeveloper/technologies/download/ (richiede lo stesso account Oracle usato per il download di XE).
Estrarre lo zip in una cartella a piacere ed eseguire sqldeveloper.exe (non serve installazione vera e propria, è un eseguibile portabile; richiede una JDK installata, che l'assistente guidato rileva o chiede di indicare al primo avvio).
Nuova connessione → parametri:
Nome connessione: a piacere
Utente: system
Password: quella impostata in fase di installazione di Oracle XE
Hostname: localhost
Porta: 1521
Nome servizio (SID): XEPDB1
## "Test" → deve avere successo, poi "Connect".

In alternativa resta valido anche DBeaver Community (https://dbeaver.io/download/), con parametri di connessione identici — utile se si preferisce uno strumento multipiattaforma uguale a quello usato nel Percorso A (macOS).

Attenzione se si usa SQL Developer: gli script di questo repository non contengono il separatore / di fine blocco PL/SQL, rimosso perché DBeaver lo interpretava come istruzione a sé stante (vedi ERRORI_RISOLTI.md). SQL Developer, nella modalità "Esegui script" (F5), tende invece ad aspettarselo per separare correttamente blocchi PL/SQL successivi, in modo simile a SQL*Plus 
    
     comportamento non verificato direttamente in fase di sviluppo di questo progetto (sviluppato e validato su macOS con DBeaver). Se l'esecuzione di un intero file con F5 desse errori di parsing, eseguire i blocchi uno alla volta con "Esegui istruzione" (Ctrl+Invio), che riconosce comunque un trigger/procedura/blocco anonimo come unità singola senza bisogno del separatore.


B.4 — Creazione dello schema applicativo

Stessa sequenza del Percorso A, identica indipendentemente dal sistema operativo: 
creazione_utente.sql (da system), poi tutti gli altri script da una nuova connessione come nis2_test.


B.5 — Popolamento con dati di test e validazione funzionale

Identico al Percorso A: test_dataset_azienda.sql e test_trigger_storicizzazione.sql.


B.6 — Export CSV (più semplice: nessun container di mezzo)

Su Windows la cartella indicata nella `DIRECTORY è già quella reale sul filesystem` — nessun passaggio di copia aggiuntivo. 
Creare prima la cartella (es. da Esplora File o da Prompt: mkdir C:\export_nis2), poi:

sql
CREATE OR REPLACE DIRECTORY export_dir AS 'C:\export_nis2';
GRANT READ, WRITE ON DIRECTORY export_dir TO nis2_test;

Dopo lancio_procedura_estrazione_excel.sql, i 4 CSV compaiono direttamente in C:\export_nis2, apribili in Excel senza alcun passaggio intermedio.

B.7 — Arresto/ripresa dell'ambiente

Da services.msc: fermare/avviare OracleServiceXE. I dati restano salvati sul disco tra un arresto e l'avvio successivo, come un normale servizio Windows.

Nota di validazione

Solo il Percorso A (macOS/Docker) è stato effettivamente seguito e validato nel corso dello sviluppo di questo progetto: è l'ambiente reale su cui lo schema è stato creato, popolato e testato. Il processo ha fatto emergere una serie di problemi reali di compatibilità e configurazione — non solo di sintassi SQL — risolti uno per uno e documentati in ERRORI_RISOLTI.md

Il Percorso B (Windows/Oracle XE nativo) è documentato secondo la procedura ufficiale Oracle e non è stato eseguito passo-passo su una macchina Windows: è incluso per completezza, ma non ha la stessa copertura di test del Percorso A. La nota su SQL Developer e il `separatore /`  è una previsione tecnica motivata, non una verifica diretta.