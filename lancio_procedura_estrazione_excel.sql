-- =====================================================================
-- PREREQUISITI (da verificare prima di eseguire questo file):
-- 1) procedura_estrazione_csv.sql deve essere già stato eseguito come
--    nis2_test (crea la funzione fn_csv_quote e le 5 procedure).
-- 2) La DIRECTORY export_dir deve esistere e puntare a una cartella
--    REALMENTE PRESENTE sul tuo PC (creala prima se non c'è). Va creata
--    da un utente con privilegi elevati (SYSTEM), non da nis2_test:
--    
--    Comando per assegnare o cambiare la directory export_dir:
--
--    CREATE OR REPLACE DIRECTORY export_dir AS 'C:\export_nis2';
--    GRANT READ, WRITE ON DIRECTORY export_dir TO nis2_test;
--
-- NOTA: una sotto-query (SELECT ...) non può essere passata come
-- argomento diretto a una procedura in un blocco PL/SQL: è un
-- costrutto valido solo dentro istruzioni SQL vere. Va prima
-- assegnata a una variabile con SELECT ... INTO.
-- =====================================================================

DECLARE
    v_soggetto_id NUMBER;
BEGIN
    SELECT id INTO v_soggetto_id
    FROM SoggettoNIS WHERE codice_fiscale = '01234567890';

    sp_esporta_profilo_completo_csv(v_soggetto_id);
END;


-- ---------------------------------------------------------------------
-- Dopo l'esecuzione, controlla la cartella indicata nella DIRECTORY:
-- dovresti trovare 4 file:
--   asset_soggetto_<id>.csv
--   servizi_soggetto_<id>.csv
--   dipendenze_soggetto_<id>.csv
--   punti_contatto_soggetto_<id>.csv
-- apribili direttamente con doppio click in Excel.
--
-- Se si preferisce lanciare le esportazioni una alla volta invece che
-- tutte insieme (utile per isolare un eventuale errore), usa:
-- ---------------------------------------------------------------------

-- DECLARE
--     v_soggetto_id NUMBER;
-- BEGIN
--     SELECT id INTO v_soggetto_id FROM SoggettoNIS WHERE codice_fiscale = '01234567890';
--     sp_esporta_asset_csv(v_soggetto_id);
-- END;

-- DECLARE
--     v_soggetto_id NUMBER;
-- BEGIN
--     SELECT id INTO v_soggetto_id FROM SoggettoNIS WHERE codice_fiscale = '01234567890';
--     sp_esporta_servizi_csv(v_soggetto_id);
-- END;

-- DECLARE
--     v_soggetto_id NUMBER;
-- BEGIN
--     SELECT id INTO v_soggetto_id FROM SoggettoNIS WHERE codice_fiscale = '01234567890';
--     sp_esporta_dipendenze_csv(v_soggetto_id);
-- END;

-- DECLARE
--     v_soggetto_id NUMBER;
-- BEGIN
--     SELECT id INTO v_soggetto_id FROM SoggettoNIS WHERE codice_fiscale = '01234567890';
--     sp_esporta_puntidicontatto_csv(v_soggetto_id);
-- END;