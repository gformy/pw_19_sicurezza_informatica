-- Blocco del DELETE fisico. RAISE_APPLICATION_ERROR è l'equivalente
-- Oracle di RAISE EXCEPTION; il codice (-20001) è nell'intervallo
-- riservato agli errori applicativi definiti dall'utente.

CREATE OR REPLACE TRIGGER trg_blocca_delete_elementocritico
BEFORE DELETE ON ElementoCritico
FOR EACH ROW
BEGIN
    RAISE_APPLICATION_ERROR(-20001,
        'DELETE non consentito su ElementoCritico: usare UPDATE stato=''DISMESSO'' per preservare lo storico');
END;

CREATE OR REPLACE TRIGGER trg_blocca_delete_asset
BEFORE DELETE ON Asset
FOR EACH ROW
BEGIN
    RAISE_APPLICATION_ERROR(-20001,
        'DELETE non consentito su Asset: usare UPDATE stato=''DISMESSO'' su ElementoCritico per preservare lo storico');
END;

CREATE OR REPLACE TRIGGER trg_blocca_delete_servizio
BEFORE DELETE ON Servizio
FOR EACH ROW
BEGIN
    RAISE_APPLICATION_ERROR(-20001,
        'DELETE non consentito su Servizio: usare UPDATE stato=''DISMESSO'' su ElementoCritico per preservare lo storico');
END;


-- 1) SoggettoNIS
CREATE OR REPLACE TRIGGER trg_storico_soggettonis
BEFORE UPDATE ON SoggettoNIS
FOR EACH ROW
DECLARE
    v_log_id NUMBER;
    v_versione NUMBER;
    v_valido_da TIMESTAMP;
    v_cambiato NUMBER;
BEGIN
    SELECT DECODE(:OLD.denominazione, :NEW.denominazione, 0, 1)
           + DECODE(:OLD.indirizzo_sede_legale, :NEW.indirizzo_sede_legale, 0, 1)
           + DECODE(:OLD.pec, :NEW.pec, 0, 1)
           + DECODE(:OLD.email_funzionale, :NEW.email_funzionale, 0, 1)
           + DECODE(:OLD.telefono, :NEW.telefono, 0, 1)
           + DECODE(:OLD.fatturato, :NEW.fatturato, 0, 1)
           + DECODE(:OLD.bilancio, :NEW.bilancio, 0, 1)
           + DECODE(:OLD.n_dipendenti, :NEW.n_dipendenti, 0, 1)
           + DECODE(:OLD.tipo_soggetto_id, :NEW.tipo_soggetto_id, 0, 1)
    INTO v_cambiato FROM DUAL;

    IF v_cambiato > 0 THEN
        INSERT INTO LogEstrazione (registro_tabella_id, record_id, utente, tipo_operazione)
        VALUES ((SELECT id FROM RegistroTabelle WHERE nome_tabella = 'SoggettoNIS'),
                :OLD.id, USER, 'MODIFICA')
        RETURNING id INTO v_log_id;

        SELECT NVL(MAX(versione), 0) + 1 INTO v_versione
        FROM SoggettoNISStorico WHERE soggetto_nis_id = :OLD.id;

        -- corregge il bug individuato in fase di conversione (vedi nota
        -- a inizio Blocco 8): valido_da è la fine della versione
        -- precedente, non sempre la data di creazione originale
        SELECT NVL(MAX(valido_a), :OLD.data_creazione) INTO v_valido_da
        FROM SoggettoNISStorico WHERE soggetto_nis_id = :OLD.id;

        UPDATE SoggettoNISStorico SET valido_a = SYSTIMESTAMP
        WHERE soggetto_nis_id = :OLD.id AND valido_a IS NULL;

        INSERT INTO SoggettoNISStorico
            (soggetto_nis_id, versione, denominazione, indirizzo_sede_legale, pec,
             email_funzionale, telefono, fatturato, bilancio, n_dipendenti,
             tipo_soggetto_id, valido_da, valido_a, log_estrazione_id)
        VALUES
            (:OLD.id, v_versione, :OLD.denominazione, :OLD.indirizzo_sede_legale, :OLD.pec,
             :OLD.email_funzionale, :OLD.telefono, :OLD.fatturato, :OLD.bilancio, :OLD.n_dipendenti,
             :OLD.tipo_soggetto_id, v_valido_da, SYSTIMESTAMP, v_log_id);
    END IF;
END;

-- 2) ElementoCritico
CREATE OR REPLACE TRIGGER trg_storico_elementocritico
BEFORE UPDATE ON ElementoCritico
FOR EACH ROW
DECLARE
    v_log_id NUMBER;
    v_versione NUMBER;
    v_valido_da TIMESTAMP;
    v_cambiato NUMBER;
BEGIN
    SELECT DECODE(:OLD.nome, :NEW.nome, 0, 1)
           + DECODE(:OLD.soggetto_nis_id, :NEW.soggetto_nis_id, 0, 1)
           + DECODE(:OLD.stato, :NEW.stato, 0, 1)
    INTO v_cambiato FROM DUAL;

    IF v_cambiato > 0 THEN
        INSERT INTO LogEstrazione (registro_tabella_id, record_id, utente, tipo_operazione)
        VALUES ((SELECT id FROM RegistroTabelle WHERE nome_tabella = 'ElementoCritico'),
                :OLD.id, USER, 'MODIFICA')
        RETURNING id INTO v_log_id;

        SELECT NVL(MAX(versione), 0) + 1 INTO v_versione
        FROM ElementoCriticoStorico WHERE elemento_critico_id = :OLD.id;

        SELECT NVL(MAX(valido_a), :OLD.data_inizio_validita) INTO v_valido_da
        FROM ElementoCriticoStorico WHERE elemento_critico_id = :OLD.id;

        UPDATE ElementoCriticoStorico SET valido_a = SYSTIMESTAMP
        WHERE elemento_critico_id = :OLD.id AND valido_a IS NULL;

        INSERT INTO ElementoCriticoStorico
            (elemento_critico_id, versione, nome, soggetto_nis_id, stato, valido_da, valido_a, log_estrazione_id)
        VALUES
            (:OLD.id, v_versione, :OLD.nome, :OLD.soggetto_nis_id, :OLD.stato, v_valido_da, SYSTIMESTAMP, v_log_id);
    END IF;
END;

-- 3) Fornitore
CREATE OR REPLACE TRIGGER trg_storico_fornitore
BEFORE UPDATE ON Fornitore
FOR EACH ROW
DECLARE
    v_log_id NUMBER;
    v_versione NUMBER;
    v_valido_da TIMESTAMP;
    v_cambiato NUMBER;
BEGIN
    SELECT DECODE(:OLD.denominazione, :NEW.denominazione, 0, 1)
           + DECODE(:OLD.paese_sede_legale, :NEW.paese_sede_legale, 0, 1)
    INTO v_cambiato FROM DUAL;

    IF v_cambiato > 0 THEN
        INSERT INTO LogEstrazione (registro_tabella_id, record_id, utente, tipo_operazione)
        VALUES ((SELECT id FROM RegistroTabelle WHERE nome_tabella = 'Fornitore'),
                :OLD.id, USER, 'MODIFICA')
        RETURNING id INTO v_log_id;

        SELECT NVL(MAX(versione), 0) + 1 INTO v_versione
        FROM FornitoreStorico WHERE fornitore_id = :OLD.id;

        SELECT NVL(MAX(valido_a), TIMESTAMP '0001-01-01 00:00:00') INTO v_valido_da
        FROM FornitoreStorico WHERE fornitore_id = :OLD.id;

        UPDATE FornitoreStorico SET valido_a = SYSTIMESTAMP
        WHERE fornitore_id = :OLD.id AND valido_a IS NULL;

        INSERT INTO FornitoreStorico
            (fornitore_id, versione, denominazione, paese_sede_legale, valido_da, valido_a, log_estrazione_id)
        VALUES
            (:OLD.id, v_versione, :OLD.denominazione, :OLD.paese_sede_legale, v_valido_da, SYSTIMESTAMP, v_log_id);
    END IF;
END;

-- 4) DocumentoGovernance
CREATE OR REPLACE TRIGGER trg_storico_documentogovernance
BEFORE UPDATE ON DocumentoGovernance
FOR EACH ROW
DECLARE
    v_log_id NUMBER;
    v_versione NUMBER;
    v_valido_da TIMESTAMP;
    v_cambiato NUMBER;
BEGIN
    SELECT DECODE(:OLD.data_approvazione, :NEW.data_approvazione, 0, 1)
           + DECODE(:OLD.approvato_da, :NEW.approvato_da, 0, 1)
           + DECODE(:OLD.data_ultimo_riesame, :NEW.data_ultimo_riesame, 0, 1)
    INTO v_cambiato FROM DUAL;

    IF v_cambiato > 0 THEN
        INSERT INTO LogEstrazione (registro_tabella_id, record_id, utente, tipo_operazione)
        VALUES ((SELECT id FROM RegistroTabelle WHERE nome_tabella = 'DocumentoGovernance'),
                :OLD.id, USER, 'MODIFICA')
        RETURNING id INTO v_log_id;

        SELECT NVL(MAX(versione), 0) + 1 INTO v_versione
        FROM DocumentoGovernanceStorico WHERE documento_id = :OLD.id;

        SELECT NVL(MAX(valido_a), TIMESTAMP '0001-01-01 00:00:00') INTO v_valido_da
        FROM DocumentoGovernanceStorico WHERE documento_id = :OLD.id;

        UPDATE DocumentoGovernanceStorico SET valido_a = SYSTIMESTAMP
        WHERE documento_id = :OLD.id AND valido_a IS NULL;

        INSERT INTO DocumentoGovernanceStorico
            (documento_id, versione, data_approvazione, approvato_da, data_ultimo_riesame, valido_da, valido_a, log_estrazione_id)
        VALUES
            (:OLD.id, v_versione, :OLD.data_approvazione, :OLD.approvato_da, :OLD.data_ultimo_riesame, v_valido_da, SYSTIMESTAMP, v_log_id);
    END IF;
END;

-- 5) StatoAdempimentoRequisito
CREATE OR REPLACE TRIGGER trg_storico_statoadempimento
BEFORE UPDATE ON StatoAdempimentoRequisito
FOR EACH ROW
DECLARE
    v_log_id NUMBER;
    v_versione NUMBER;
    v_valido_da TIMESTAMP;
    v_cambiato NUMBER;
BEGIN
    SELECT DECODE(:OLD.stato, :NEW.stato, 0, 1)
           + DECODE(:OLD.responsabile_id, :NEW.responsabile_id, 0, 1)
           + DECODE(:OLD.documento_evidenza_id, :NEW.documento_evidenza_id, 0, 1)
           + DECODE(:OLD.note, :NEW.note, 0, 1)
    INTO v_cambiato FROM DUAL;

    IF v_cambiato > 0 THEN
        INSERT INTO LogEstrazione (registro_tabella_id, record_id, utente, tipo_operazione)
        VALUES ((SELECT id FROM RegistroTabelle WHERE nome_tabella = 'StatoAdempimentoRequisito'),
                :OLD.id, USER, 'MODIFICA')
        RETURNING id INTO v_log_id;

        SELECT NVL(MAX(versione), 0) + 1 INTO v_versione
        FROM StatoAdempimentoRequisitoStorico WHERE stato_adempimento_id = :OLD.id;

        SELECT NVL(MAX(valido_a), TIMESTAMP '0001-01-01 00:00:00') INTO v_valido_da
        FROM StatoAdempimentoRequisitoStorico WHERE stato_adempimento_id = :OLD.id;

        UPDATE StatoAdempimentoRequisitoStorico SET valido_a = SYSTIMESTAMP
        WHERE stato_adempimento_id = :OLD.id AND valido_a IS NULL;

        INSERT INTO StatoAdempimentoRequisitoStorico
            (stato_adempimento_id, versione, stato, data_valutazione, responsabile_id,
             documento_evidenza_id, note, valido_da, valido_a, log_estrazione_id)
        VALUES
            (:OLD.id, v_versione, :OLD.stato, :OLD.data_valutazione, :OLD.responsabile_id,
             :OLD.documento_evidenza_id, :OLD.note, v_valido_da, SYSTIMESTAMP, v_log_id);
    END IF;
END;

-- 6) AccordoCondivisioneInformazioni
CREATE OR REPLACE TRIGGER trg_storico_accordo
BEFORE UPDATE ON AccordoCondivisioneInformazioni
FOR EACH ROW
DECLARE
    v_log_id NUMBER;
    v_versione NUMBER;
    v_valido_da TIMESTAMP;
    v_cambiato NUMBER;
BEGIN
    SELECT DECODE(:OLD.controparte, :NEW.controparte, 0, 1)
           + DECODE(:OLD.descrizione, :NEW.descrizione, 0, 1)
           + DECODE(:OLD.stato, :NEW.stato, 0, 1)
    INTO v_cambiato FROM DUAL;

    IF v_cambiato > 0 THEN
        INSERT INTO LogEstrazione (registro_tabella_id, record_id, utente, tipo_operazione)
        VALUES ((SELECT id FROM RegistroTabelle WHERE nome_tabella = 'AccordoCondivisioneInformazioni'),
                :OLD.id, USER, 'MODIFICA')
        RETURNING id INTO v_log_id;

        SELECT NVL(MAX(versione), 0) + 1 INTO v_versione
        FROM AccordoCondivisioneInformazioniStorico WHERE accordo_id = :OLD.id;

        SELECT NVL(MAX(valido_a), TIMESTAMP '0001-01-01 00:00:00') INTO v_valido_da
        FROM AccordoCondivisioneInformazioniStorico WHERE accordo_id = :OLD.id;

        UPDATE AccordoCondivisioneInformazioniStorico SET valido_a = SYSTIMESTAMP
        WHERE accordo_id = :OLD.id AND valido_a IS NULL;

        INSERT INTO AccordoCondivisioneInformazioniStorico
            (accordo_id, versione, controparte, descrizione, stato, valido_da, valido_a, log_estrazione_id)
        VALUES
            (:OLD.id, v_versione, :OLD.controparte, :OLD.descrizione, :OLD.stato, v_valido_da, SYSTIMESTAMP, v_log_id);
    END IF;
END;

-- 7) Dipendenza
CREATE OR REPLACE TRIGGER trg_storico_dipendenza
BEFORE UPDATE ON Dipendenza
FOR EACH ROW
DECLARE
    v_log_id NUMBER;
    v_versione NUMBER;
    v_valido_da TIMESTAMP;
    v_cambiato NUMBER;
BEGIN
    SELECT DECODE(:OLD.criterio_rilevanza, :NEW.criterio_rilevanza, 0, 1)
           + DECODE(:OLD.tipologia_fornitura, :NEW.tipologia_fornitura, 0, 1)
           + DECODE(:OLD.referente_contatto, :NEW.referente_contatto, 0, 1)
           + DECODE(:OLD.stato, :NEW.stato, 0, 1)
    INTO v_cambiato FROM DUAL;

    IF v_cambiato > 0 THEN
        INSERT INTO LogEstrazione (registro_tabella_id, record_id, utente, tipo_operazione)
        VALUES ((SELECT id FROM RegistroTabelle WHERE nome_tabella = 'Dipendenza'),
                :OLD.id, USER, 'MODIFICA')
        RETURNING id INTO v_log_id;

        SELECT NVL(MAX(versione), 0) + 1 INTO v_versione
        FROM DipendenzaStorico WHERE dipendenza_id = :OLD.id;

        SELECT NVL(MAX(valido_a), TIMESTAMP '0001-01-01 00:00:00') INTO v_valido_da
        FROM DipendenzaStorico WHERE dipendenza_id = :OLD.id;

        UPDATE DipendenzaStorico SET valido_a = SYSTIMESTAMP
        WHERE dipendenza_id = :OLD.id AND valido_a IS NULL;

        INSERT INTO DipendenzaStorico
            (dipendenza_id, versione, criterio_rilevanza, tipologia_fornitura, referente_contatto, stato, valido_da, valido_a, log_estrazione_id)
        VALUES
            (:OLD.id, v_versione, :OLD.criterio_rilevanza, :OLD.tipologia_fornitura, :OLD.referente_contatto, :OLD.stato, v_valido_da, SYSTIMESTAMP, v_log_id);
    END IF;
END;

-- 8) AssetServizio
CREATE OR REPLACE TRIGGER trg_storico_assetservizio
BEFORE UPDATE ON AssetServizio
FOR EACH ROW
DECLARE
    v_log_id NUMBER;
    v_versione NUMBER;
    v_valido_da TIMESTAMP;
    v_cambiato NUMBER;
BEGIN
    SELECT DECODE(:OLD.stato, :NEW.stato, 0, 1)
    INTO v_cambiato FROM DUAL;

    IF v_cambiato > 0 THEN
        INSERT INTO LogEstrazione (registro_tabella_id, record_id, utente, tipo_operazione)
        VALUES ((SELECT id FROM RegistroTabelle WHERE nome_tabella = 'AssetServizio'),
                :OLD.id, USER, 'MODIFICA')
        RETURNING id INTO v_log_id;

        SELECT NVL(MAX(versione), 0) + 1 INTO v_versione
        FROM AssetServizioStorico WHERE asset_servizio_id = :OLD.id;

        SELECT NVL(MAX(valido_a), TIMESTAMP '0001-01-01 00:00:00') INTO v_valido_da
        FROM AssetServizioStorico WHERE asset_servizio_id = :OLD.id;

        UPDATE AssetServizioStorico SET valido_a = SYSTIMESTAMP
        WHERE asset_servizio_id = :OLD.id AND valido_a IS NULL;

        INSERT INTO AssetServizioStorico
            (asset_servizio_id, versione, stato, valido_da, valido_a, log_estrazione_id)
        VALUES
            (:OLD.id, v_versione, :OLD.stato, v_valido_da, SYSTIMESTAMP, v_log_id);
    END IF;
END;

-- 9) DocumentoGovernanceElementoCritico
CREATE OR REPLACE TRIGGER trg_storico_documentogovernanceelementocritico
BEFORE UPDATE ON DocumentoGovernanceElementoCritico
FOR EACH ROW
DECLARE
    v_log_id NUMBER;
    v_versione NUMBER;
    v_valido_da TIMESTAMP;
    v_cambiato NUMBER;
BEGIN
    SELECT DECODE(:OLD.stato, :NEW.stato, 0, 1)
    INTO v_cambiato FROM DUAL;

    IF v_cambiato > 0 THEN
        INSERT INTO LogEstrazione (registro_tabella_id, record_id, utente, tipo_operazione)
        VALUES ((SELECT id FROM RegistroTabelle WHERE nome_tabella = 'DocumentoGovernanceElementoCritico'),
                :OLD.id, USER, 'MODIFICA')
        RETURNING id INTO v_log_id;

        SELECT NVL(MAX(versione), 0) + 1 INTO v_versione
        FROM DocumentoGovernanceElementoCriticoStorico WHERE documento_elemento_id = :OLD.id;

        SELECT NVL(MAX(valido_a), TIMESTAMP '0001-01-01 00:00:00') INTO v_valido_da
        FROM DocumentoGovernanceElementoCriticoStorico WHERE documento_elemento_id = :OLD.id;

        UPDATE DocumentoGovernanceElementoCriticoStorico SET valido_a = SYSTIMESTAMP
        WHERE documento_elemento_id = :OLD.id AND valido_a IS NULL;

        INSERT INTO DocumentoGovernanceElementoCriticoStorico
            (documento_elemento_id, versione, stato, valido_da, valido_a, log_estrazione_id)
        VALUES
            (:OLD.id, v_versione, :OLD.stato, v_valido_da, SYSTIMESTAMP, v_log_id);
    END IF;
END;