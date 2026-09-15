# Errori reali incontrati e come sono stati risolti

Diario tecnico di validazione: ogni errore qui elencato è stato
effettivamente riscontrato durante l'esecuzione dello schema su
un'istanza Oracle reale (non solo previsto in astratto), con causa e
soluzione verificate.

---

## `PLS-00204`, poi `ORA-04098` al primo UPDATE

`DECODE` è una funzione SQL, non utilizzabile in una condizione `IF` di
puro PL/SQL. Presente nei 9 trigger di storicizzazione. Non emerge al
`CREATE TRIGGER` (il trigger compila comunque, restando però invalido),
solo al primo uso reale — da qui l'errore generico `ORA-04098` al primo
`UPDATE`, con la causa specifica visibile solo interrogando
`ALL_ERRORS`.

**Soluzione**: spostare il confronto in un'istruzione SQL vera:
```sql
SELECT DECODE(:OLD.col, :NEW.col, 0, 1) INTO v_cambiato FROM DUAL;
IF v_cambiato > 0 THEN ...
```

## `ORA-01861` — valore non conforme al formato

Una data scritta come stringa semplice (`'2025-04-30'`) assegnata a una
colonna `DATE` dipende dal formato NLS della sessione, non affidabile.

**Soluzione**: letterale ANSI esplicito, indipendente dal locale:
`DATE '2025-04-30'`.

## `ORA-00900` — istruzione SQL non valida

Il separatore `/` di fine blocco PL/SQL non è
riconosciuto da DBeaver come delimitatore: viene inviato al database
come istruzione a sé stante, non valida.

**Soluzione**: rimosso ovunque. DBeaver riconosce comunque un
trigger/procedura come istruzione unica grazie al `;` dopo `END`.

## `ORA-00918` — colonna ambiguamente definita

In un `JOIN` tra due tabelle che hanno entrambe una colonna `id` (es.
`DocumentoGovernanceElementoCritico` e `DocumentoGovernance`), riferirsi
a `id` senza alias è ambiguo per il motore.

**Soluzione**: qualificare sempre la colonna con l'alias (es. `dgec.id`).

## `PLS-00103` — trovato il simbolo "SELECT"

Una sotto-query `(SELECT ...)` non può essere passata come argomento
diretto a una chiamata di procedura dentro un blocco PL/SQL: è un
costrutto valido solo dentro istruzioni SQL vere.

**Soluzione**:
```sql
DECLARE
    v_id NUMBER;
BEGIN
    SELECT id INTO v_id FROM Tabella WHERE condizione;
    nome_procedura(v_id);
END;
```

## `ORA-29283` — operazione file non valida: percorso inesistente

Con Oracle eseguito in un container Docker, `UTL_FILE` scrive dentro il
filesystem **del container**, non dell'host. `CREATE DIRECTORY` non
verifica che il percorso esista realmente al momento della creazione —
l'oggetto viene creato comunque, l'errore emerge solo al primo
tentativo di scrittura.

**Soluzione**: creare la cartella nel container prima di lanciare
l'export (`docker exec <container> mkdir -p /percorso`), verificando
che il percorso nella `DIRECTORY` Oracle corrisponda esattamente
(`SELECT directory_path FROM ALL_DIRECTORIES ...`).

## Trappola logica (nessun errore, risultato vuoto)

Un `InvioACN` inserito con una data fissa nel passato (es.
`TIMESTAMP '2025-05-15 ...'`), se i dati a cui si riferisce sono creati
con `SYSTIMESTAMP` in un momento successivo (es. eseguendo lo script
"oggi"), produce zero righe nelle viste AS OF — comportamento corretto,
non un bug: quei dati "non esistevano ancora" a quella data secondo il
database.

**Soluzione**: usare sempre `SYSTIMESTAMP` per gli `InvioACN` negli
scenari di test pensati per essere eseguiti "adesso", non date fisse
scelte a tavolino.