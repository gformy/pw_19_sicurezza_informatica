-- =====================================================================
-- 06 — EXPORT CSV SU FILE LOCALE (UTL_FILE)
--
-- PREREQUISITO: UTL_FILE scrive sul FILE SYSTEM DEL SERVER ORACLE,
-- non sul client (DBeaver). Se l'istanza di test gira in locale sulla
-- stessa macchina, il percorso indicato nella DIRECTORY sottostante
-- è semplicemente una cartella del proprio PC; se l'istanza fosse
-- remota, il file comparirebbe sul server e non sul client - non è
-- il caso qui, ma va tenuto presente.
-- =====================================================================

-- ---------------------------------------------------------------------
-- Directory Oracle: un oggetto che fa da alias a un percorso reale del
-- file system. Il percorso va adattato al proprio ambiente prima di
-- eseguire (qui un esempio per Windows; su Linux/Mac usare ad es.
-- '/home/utente/export_nis2').
-- Va creata da un utente con privilegio CREATE ANY DIRECTORY
-- (tipicamente SYSTEM), non dall'utente applicativo nis2_test.
-- ---------------------------------------------------------------------
CREATE OR REPLACE DIRECTORY export_dir AS 'C:\export_nis2';

GRANT READ, WRITE ON DIRECTORY export_dir TO nis2_test;


-- ---------------------------------------------------------------------
-- Funzione di appoggio: mette tra virgolette un campo testuale e
-- raddoppia eventuali virgolette interne, secondo lo standard CSV -
-- necessaria perché descrizioni, note e nomi possono contenere virgole.
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_csv_quote(p_valore VARCHAR2) RETURN VARCHAR2 IS
BEGIN
    IF p_valore IS NULL THEN
        RETURN '';
    END IF;
    RETURN '"' || REPLACE(p_valore, '"', '""') || '"';
END;


-- ---------------------------------------------------------------------
-- 1) Esportazione Asset critici
-- ---------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_esporta_asset_csv(p_soggetto_id NUMBER) IS
    v_file  UTL_FILE.FILE_TYPE;
    v_nome_file VARCHAR2(100) := 'asset_soggetto_' || p_soggetto_id || '.csv';
BEGIN
    v_file := UTL_FILE.FOPEN('EXPORT_DIR', v_nome_file, 'W');

    UTL_FILE.PUT_LINE(v_file, 'nome_asset,tipo_asset,rilevante,stato,data_inizio_validita');

    FOR r IN (
        SELECT ec.nome, a.tipo_asset,
               CASE a.rilevante WHEN 1 THEN 'SI' ELSE 'NO' END AS rilevante,
               ec.stato, ec.data_inizio_validita
        FROM ElementoCritico ec
        JOIN Asset a ON a.id = ec.id
        WHERE ec.soggetto_nis_id = p_soggetto_id
        ORDER BY ec.nome
    ) LOOP
        UTL_FILE.PUT_LINE(v_file,
            fn_csv_quote(r.nome) || ',' ||
            fn_csv_quote(r.tipo_asset) || ',' ||
            r.rilevante || ',' ||
            fn_csv_quote(r.stato) || ',' ||
            TO_CHAR(r.data_inizio_validita, 'YYYY-MM-DD HH24:MI:SS')
        );
    END LOOP;

    UTL_FILE.FCLOSE(v_file);
EXCEPTION
    WHEN OTHERS THEN
        IF UTL_FILE.IS_OPEN(v_file) THEN
            UTL_FILE.FCLOSE(v_file);
        END IF;
        RAISE;
END;


-- ---------------------------------------------------------------------
-- 2) Esportazione Servizi erogati
-- ---------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_esporta_servizi_csv(p_soggetto_id NUMBER) IS
    v_file  UTL_FILE.FILE_TYPE;
    v_nome_file VARCHAR2(100) := 'servizi_soggetto_' || p_soggetto_id || '.csv';
BEGIN
    v_file := UTL_FILE.FOPEN('EXPORT_DIR', v_nome_file, 'W');

    UTL_FILE.PUT_LINE(v_file, 'nome_servizio,descrizione,categoria_rilevanza,stato,stati_membro_offerta');

    FOR r IN (
        SELECT ec.nome, s.descrizione, s.categoria_rilevanza, ec.stato,
               (SELECT LISTAGG(sm.stato_membro, '; ') WITHIN GROUP (ORDER BY sm.stato_membro)
                FROM ServizioStatoMembro sm WHERE sm.servizio_id = s.id) AS stati_membro
        FROM ElementoCritico ec
        JOIN Servizio s ON s.id = ec.id
        WHERE ec.soggetto_nis_id = p_soggetto_id
        ORDER BY ec.nome
    ) LOOP
        UTL_FILE.PUT_LINE(v_file,
            fn_csv_quote(r.nome) || ',' ||
            fn_csv_quote(r.descrizione) || ',' ||
            fn_csv_quote(r.categoria_rilevanza) || ',' ||
            fn_csv_quote(r.stato) || ',' ||
            fn_csv_quote(r.stati_membro)
        );
    END LOOP;

    UTL_FILE.FCLOSE(v_file);
EXCEPTION
    WHEN OTHERS THEN
        IF UTL_FILE.IS_OPEN(v_file) THEN
            UTL_FILE.FCLOSE(v_file);
        END IF;
        RAISE;
END;


-- ---------------------------------------------------------------------
-- 3) Esportazione Dipendenze da terze parti (fornitori rilevanti)
-- ---------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_esporta_dipendenze_csv(p_soggetto_id NUMBER) IS
    v_file  UTL_FILE.FILE_TYPE;
    v_nome_file VARCHAR2(100) := 'dipendenze_soggetto_' || p_soggetto_id || '.csv';
BEGIN
    v_file := UTL_FILE.FOPEN('EXPORT_DIR', v_nome_file, 'W');

    UTL_FILE.PUT_LINE(v_file,
        'fornitore,codice_fiscale,paese_sede_legale,elemento_dipendente,tipo_elemento,criterio_rilevanza,tipologia_fornitura,referente_contatto,stato');

    FOR r IN (
        SELECT f.denominazione, f.codice_fiscale, f.paese_sede_legale,
               ec.nome AS elemento_dipendente, ec.tipo AS tipo_elemento,
               d.criterio_rilevanza, d.tipologia_fornitura, d.referente_contatto, d.stato
        FROM Dipendenza d
        JOIN Fornitore f ON f.id = d.fornitore_id
        JOIN ElementoCritico ec ON ec.id = d.elemento_critico_id
        WHERE ec.soggetto_nis_id = p_soggetto_id
        ORDER BY f.denominazione
    ) LOOP
        UTL_FILE.PUT_LINE(v_file,
            fn_csv_quote(r.denominazione) || ',' ||
            fn_csv_quote(r.codice_fiscale) || ',' ||
            fn_csv_quote(r.paese_sede_legale) || ',' ||
            fn_csv_quote(r.elemento_dipendente) || ',' ||
            fn_csv_quote(r.tipo_elemento) || ',' ||
            fn_csv_quote(r.criterio_rilevanza) || ',' ||
            fn_csv_quote(r.tipologia_fornitura) || ',' ||
            fn_csv_quote(r.referente_contatto) || ',' ||
            fn_csv_quote(r.stato)
        );
    END LOOP;

    UTL_FILE.FCLOSE(v_file);
EXCEPTION
    WHEN OTHERS THEN
        IF UTL_FILE.IS_OPEN(v_file) THEN
            UTL_FILE.FCLOSE(v_file);
        END IF;
        RAISE;
END;


-- ---------------------------------------------------------------------
-- 4) Esportazione Punti di contatto
-- ---------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_esporta_puntidicontatto_csv(p_soggetto_id NUMBER) IS
    v_file  UTL_FILE.FILE_TYPE;
    v_nome_file VARCHAR2(100) := 'punti_contatto_soggetto_' || p_soggetto_id || '.csv';
BEGIN
    v_file := UTL_FILE.FOPEN('EXPORT_DIR', v_nome_file, 'W');

    UTL_FILE.PUT_LINE(v_file, 'nome,ruolo,email,telefono,delega');

    FOR r IN (
        SELECT pc.nome, pc.ruolo, pc.email, pc.telefono, pc.delega
        FROM PuntoDiContatto pc
        WHERE pc.soggetto_nis_id = p_soggetto_id
        ORDER BY pc.ruolo
    ) LOOP
        UTL_FILE.PUT_LINE(v_file,
            fn_csv_quote(r.nome) || ',' ||
            fn_csv_quote(r.ruolo) || ',' ||
            fn_csv_quote(r.email) || ',' ||
            fn_csv_quote(r.telefono) || ',' ||
            fn_csv_quote(r.delega)
        );
    END LOOP;

    UTL_FILE.FCLOSE(v_file);
EXCEPTION
    WHEN OTHERS THEN
        IF UTL_FILE.IS_OPEN(v_file) THEN
            UTL_FILE.FCLOSE(v_file);
        END IF;
        RAISE;
END;


-- ---------------------------------------------------------------------
-- 5) Procedura "regia": esegue tutte e quattro le esportazioni in
-- un'unica chiamata, per l'azienda indicata.
-- ---------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_esporta_profilo_completo_csv(p_soggetto_id NUMBER) IS
BEGIN
    sp_esporta_asset_csv(p_soggetto_id);
    sp_esporta_servizi_csv(p_soggetto_id);
    sp_esporta_dipendenze_csv(p_soggetto_id);
    sp_esporta_puntidicontatto_csv(p_soggetto_id);
END;

-- Esempio di chiamata (da eseguire come blocco anonimo in DBeaver):
-- BEGIN
--     sp_esporta_profilo_completo_csv(1);
-- END;