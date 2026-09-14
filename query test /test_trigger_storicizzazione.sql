-- =====================================================================
-- 08 — TEST ISOLATO DEI 9 TRIGGER DI STORICIZZAZIONE
-- Da eseguire DOPO gli script 02, 03, 04.
--
-- Dataset indipendente dal file 07 (codice fiscale diverso: 99999999999),
-- per non entrare in conflitto con dati parziali già presenti in caso
-- di esecuzioni precedenti interrotte.
--
-- Struttura: per ciascun trigger, un blocco separato con
--   (a) creazione della riga minima necessaria
--   (b) UPDATE che dovrebbe attivare il trigger
--   (c) SELECT di verifica che mostra la riga storicizzata
-- Eseguire un blocco alla volta, verificando l'esito di ciascuno prima
-- di passare al successivo: se un trigger fallisce, ORA-04098 indicherà
-- con precisione quale, senza dover risalire da un errore generico.
-- =====================================================================


-- ---------------------------------------------------------------------
-- Setup comune: azienda di test dedicata a questo file
-- ---------------------------------------------------------------------
INSERT INTO SoggettoNIS (codice_fiscale, denominazione, indirizzo_sede_legale,
                          pec, tipo_soggetto_id)
VALUES ('99999999999', 'Azienda Test Trigger S.r.l.', 'Via Test 1, Roma',
        'test@pec.it', (SELECT id FROM TipoSoggettoNIS WHERE codice = 'IMPORTANTE'));


-- =======================================================================
-- TRIGGER 1/9 — trg_storico_soggettonis (quello che ha dato errore prima)
-- =======================================================================
UPDATE SoggettoNIS SET fatturato = 1000000
WHERE codice_fiscale = '99999999999';

-- Verifica: deve restituire 1 riga (la versione precedente, con fatturato NULL)
SELECT versione, fatturato, valido_da, valido_a
FROM SoggettoNISStorico
WHERE soggetto_nis_id = (SELECT id FROM SoggettoNIS WHERE codice_fiscale = '99999999999');


-- =======================================================================
-- TRIGGER 2/9 — trg_storico_elementocritico
-- =======================================================================
INSERT INTO AssetCompleto (nome, soggetto_nis_id, tipo_asset, rilevante)
VALUES ('Asset di prova', (SELECT id FROM SoggettoNIS WHERE codice_fiscale = '99999999999'),
        'HARDWARE', 0);

UPDATE ElementoCritico SET stato = 'DISMESSO'
WHERE nome = 'Asset di prova'
  AND soggetto_nis_id = (SELECT id FROM SoggettoNIS WHERE codice_fiscale = '99999999999');

-- Verifica: 1 riga, stato = 'ATTIVO' (la versione precedente alla dismissione)
SELECT versione, stato, valido_da, valido_a
FROM ElementoCriticoStorico
WHERE elemento_critico_id = (
    SELECT id FROM ElementoCritico WHERE nome = 'Asset di prova'
      AND soggetto_nis_id = (SELECT id FROM SoggettoNIS WHERE codice_fiscale = '99999999999')
);


-- =======================================================================
-- TRIGGER 3/9 — trg_storico_fornitore
-- =======================================================================
INSERT INTO Fornitore (denominazione, codice_fiscale, paese_sede_legale)
VALUES ('Fornitore di prova', '88888888888', 'IT');

UPDATE Fornitore SET denominazione = 'Fornitore di prova (rinominato)'
WHERE codice_fiscale = '88888888888';

-- Verifica: 1 riga, con la denominazione precedente
SELECT versione, denominazione, valido_da, valido_a
FROM FornitoreStorico
WHERE fornitore_id = (SELECT id FROM Fornitore WHERE codice_fiscale = '88888888888');


-- =======================================================================
-- TRIGGER 4/9 — trg_storico_documentogovernance
-- =======================================================================
INSERT INTO OrganoAmministrazione (soggetto_nis_id, nome, ruolo)
VALUES ((SELECT id FROM SoggettoNIS WHERE codice_fiscale = '99999999999'),
        'Amministratore di Prova', 'Amministratore Unico');

INSERT INTO DocumentoGovernance (soggetto_nis_id, tipo_documento_id, data_approvazione, approvato_da)
VALUES (
    (SELECT id FROM SoggettoNIS WHERE codice_fiscale = '99999999999'),
    (SELECT id FROM TipoDocumentoGovernance WHERE codice = 'GV.RM-03'),
    DATE '2025-01-10',
    (SELECT id FROM OrganoAmministrazione WHERE nome = 'Amministratore di Prova'
        AND soggetto_nis_id = (SELECT id FROM SoggettoNIS WHERE codice_fiscale = '99999999999'))
);

UPDATE DocumentoGovernance SET data_ultimo_riesame = DATE '2025-06-10'
WHERE soggetto_nis_id = (SELECT id FROM SoggettoNIS WHERE codice_fiscale = '99999999999')
  AND tipo_documento_id = (SELECT id FROM TipoDocumentoGovernance WHERE codice = 'GV.RM-03');

-- Verifica: 1 riga, con data_ultimo_riesame NULL (valore precedente)
SELECT versione, data_ultimo_riesame, valido_da, valido_a
FROM DocumentoGovernanceStorico
WHERE documento_id = (
    SELECT id FROM DocumentoGovernance
    WHERE soggetto_nis_id = (SELECT id FROM SoggettoNIS WHERE codice_fiscale = '99999999999')
      AND tipo_documento_id = (SELECT id FROM TipoDocumentoGovernance WHERE codice = 'GV.RM-03')
);


-- =======================================================================
-- TRIGGER 5/9 — trg_storico_statoadempimento
-- PREREQUISITO: richiede che RequisitoMisura contenga almeno una riga.
-- Se non è ancora stato eseguito FINALE_07 (Parte A), scommentare le
-- due INSERT seguenti per crearne una minima qui:
-- =======================================================================
-- INSERT INTO MisuraSicurezza (codice, categoria, descrizione)
-- VALUES ('TEST-01', 'Categoria di prova', 'Misura di prova per test trigger');
-- INSERT INTO RequisitoMisura (codice, misura_id, numero_punto, testo)
-- SELECT 'TEST-01.1', id, 1, 'Requisito di prova' FROM MisuraSicurezza WHERE codice = 'TEST-01';

INSERT INTO StatoAdempimentoRequisito (requisito_id, soggetto_nis_id, stato)
VALUES (
    (SELECT id FROM RequisitoMisura WHERE ROWNUM = 1),  -- il primo requisito disponibile
    (SELECT id FROM SoggettoNIS WHERE codice_fiscale = '99999999999'),
    'NON_ATTUATO'
);

UPDATE StatoAdempimentoRequisito SET stato = 'ATTUATO'
WHERE soggetto_nis_id = (SELECT id FROM SoggettoNIS WHERE codice_fiscale = '99999999999')
  AND requisito_id = (SELECT id FROM RequisitoMisura WHERE ROWNUM = 1);

-- Verifica: 1 riga, con stato = 'NON_ATTUATO' (valore precedente)
SELECT versione, stato, valido_da, valido_a
FROM StatoAdempimentoRequisitoStorico
WHERE stato_adempimento_id = (
    SELECT id FROM StatoAdempimentoRequisito
    WHERE soggetto_nis_id = (SELECT id FROM SoggettoNIS WHERE codice_fiscale = '99999999999')
);


-- =======================================================================
-- TRIGGER 6/9 — trg_storico_accordo
-- =======================================================================
INSERT INTO AccordoCondivisioneInformazioni (soggetto_nis_id, controparte, descrizione)
VALUES ((SELECT id FROM SoggettoNIS WHERE codice_fiscale = '99999999999'),
        'Controparte di prova', 'Descrizione iniziale');

UPDATE AccordoCondivisioneInformazioni SET descrizione = 'Descrizione aggiornata'
WHERE soggetto_nis_id = (SELECT id FROM SoggettoNIS WHERE codice_fiscale = '99999999999')
  AND controparte = 'Controparte di prova';

-- Verifica: 1 riga, con la descrizione precedente
SELECT versione, descrizione, valido_da, valido_a
FROM AccordoCondivisioneInformazioniStorico
WHERE accordo_id = (
    SELECT id FROM AccordoCondivisioneInformazioni
    WHERE soggetto_nis_id = (SELECT id FROM SoggettoNIS WHERE codice_fiscale = '99999999999')
      AND controparte = 'Controparte di prova'
);


-- =======================================================================
-- TRIGGER 7/9 — trg_storico_dipendenza
-- =======================================================================
INSERT INTO Dipendenza (fornitore_id, elemento_critico_id, criterio_rilevanza)
VALUES (
    (SELECT id FROM Fornitore WHERE codice_fiscale = '88888888888'),
    (SELECT id FROM ElementoCritico WHERE nome = 'Asset di prova'
        AND soggetto_nis_id = (SELECT id FROM SoggettoNIS WHERE codice_fiscale = '99999999999')),
    'ICT'
);

UPDATE Dipendenza SET criterio_rilevanza = 'NON_FUNGIBILE'
WHERE fornitore_id = (SELECT id FROM Fornitore WHERE codice_fiscale = '88888888888')
  AND elemento_critico_id = (
      SELECT id FROM ElementoCritico WHERE nome = 'Asset di prova'
        AND soggetto_nis_id = (SELECT id FROM SoggettoNIS WHERE codice_fiscale = '99999999999')
  );

-- Verifica: 1 riga, con criterio_rilevanza = 'ICT' (valore precedente)
SELECT versione, criterio_rilevanza, valido_da, valido_a
FROM DipendenzaStorico
WHERE dipendenza_id = (
    SELECT id FROM Dipendenza
    WHERE fornitore_id = (SELECT id FROM Fornitore WHERE codice_fiscale = '88888888888')
);


-- =======================================================================
-- TRIGGER 8/9 — trg_storico_assetservizio
-- =======================================================================
INSERT INTO ServizioCompleto (nome, soggetto_nis_id, descrizione)
VALUES ('Servizio di prova', (SELECT id FROM SoggettoNIS WHERE codice_fiscale = '99999999999'),
        'Servizio creato per il test');

INSERT INTO AssetServizio (asset_id, servizio_id)
VALUES (
    (SELECT id FROM ElementoCritico WHERE nome = 'Asset di prova'
        AND soggetto_nis_id = (SELECT id FROM SoggettoNIS WHERE codice_fiscale = '99999999999')),
    (SELECT id FROM ElementoCritico WHERE nome = 'Servizio di prova'
        AND soggetto_nis_id = (SELECT id FROM SoggettoNIS WHERE codice_fiscale = '99999999999'))
);

UPDATE AssetServizio SET stato = 'CESSATA'
WHERE asset_id = (SELECT id FROM ElementoCritico WHERE nome = 'Asset di prova'
    AND soggetto_nis_id = (SELECT id FROM SoggettoNIS WHERE codice_fiscale = '99999999999'));

-- Verifica: 1 riga, con stato = 'ATTIVA' (valore precedente)
SELECT versione, stato, valido_da, valido_a
FROM AssetServizioStorico
WHERE asset_servizio_id = (
    SELECT id FROM AssetServizio
    WHERE asset_id = (SELECT id FROM ElementoCritico WHERE nome = 'Asset di prova'
        AND soggetto_nis_id = (SELECT id FROM SoggettoNIS WHERE codice_fiscale = '99999999999'))
);


-- =======================================================================
-- TRIGGER 9/9 — trg_storico_documentogovernanceelementocritico
-- =======================================================================
INSERT INTO DocumentoGovernanceElementoCritico (documento_id, elemento_critico_id)
VALUES (
    (SELECT id FROM DocumentoGovernance
        WHERE soggetto_nis_id = (SELECT id FROM SoggettoNIS WHERE codice_fiscale = '99999999999')
        AND tipo_documento_id = (SELECT id FROM TipoDocumentoGovernance WHERE codice = 'GV.RM-03')),
    (SELECT id FROM ElementoCritico WHERE nome = 'Servizio di prova'
        AND soggetto_nis_id = (SELECT id FROM SoggettoNIS WHERE codice_fiscale = '99999999999'))
);

UPDATE DocumentoGovernanceElementoCritico SET stato = 'CESSATA'
WHERE documento_id = (
    SELECT id FROM DocumentoGovernance
    WHERE soggetto_nis_id = (SELECT id FROM SoggettoNIS WHERE codice_fiscale = '99999999999')
      AND tipo_documento_id = (SELECT id FROM TipoDocumentoGovernance WHERE codice = 'GV.RM-03')
)
AND elemento_critico_id = (
    SELECT id FROM ElementoCritico WHERE nome = 'Servizio di prova'
        AND soggetto_nis_id = (SELECT id FROM SoggettoNIS WHERE codice_fiscale = '99999999999')
);

-- Verifica: 1 riga, con stato = 'ATTIVA' (valore precedente)
SELECT versione, stato, valido_da, valido_a
FROM DocumentoGovernanceElementoCriticoStorico
WHERE documento_elemento_id = (
    SELECT id FROM DocumentoGovernanceElementoCritico
    WHERE documento_id = (
        SELECT id FROM DocumentoGovernance
        WHERE soggetto_nis_id = (SELECT id FROM SoggettoNIS WHERE codice_fiscale = '99999999999')
          AND tipo_documento_id = (SELECT id FROM TipoDocumentoGovernance WHERE codice = 'GV.RM-03')
    )
);


-- =======================================================================
-- RIEPILOGO FINALE: conta quante tabelle *Storico hanno righe per
-- questo soggetto di test. Atteso: 9 su 9 con almeno 1 riga.
-- =======================================================================
SELECT 'SoggettoNISStorico' AS tabella, COUNT(*) AS righe FROM SoggettoNISStorico
WHERE soggetto_nis_id = (SELECT id FROM SoggettoNIS WHERE codice_fiscale = '99999999999')
UNION ALL
SELECT 'ElementoCriticoStorico', COUNT(*) FROM ElementoCriticoStorico
WHERE elemento_critico_id IN (SELECT id FROM ElementoCritico
    WHERE soggetto_nis_id = (SELECT id FROM SoggettoNIS WHERE codice_fiscale = '99999999999'))
UNION ALL
SELECT 'FornitoreStorico', COUNT(*) FROM FornitoreStorico
WHERE fornitore_id = (SELECT id FROM Fornitore WHERE codice_fiscale = '88888888888')
UNION ALL
SELECT 'DocumentoGovernanceStorico', COUNT(*) FROM DocumentoGovernanceStorico
WHERE documento_id IN (SELECT id FROM DocumentoGovernance
    WHERE soggetto_nis_id = (SELECT id FROM SoggettoNIS WHERE codice_fiscale = '99999999999'))
UNION ALL
SELECT 'StatoAdempimentoRequisitoStorico', COUNT(*) FROM StatoAdempimentoRequisitoStorico
WHERE stato_adempimento_id IN (SELECT id FROM StatoAdempimentoRequisito
    WHERE soggetto_nis_id = (SELECT id FROM SoggettoNIS WHERE codice_fiscale = '99999999999'))
UNION ALL
SELECT 'AccordoCondivisioneInformazioniStorico', COUNT(*) FROM AccordoCondivisioneInformazioniStorico
WHERE accordo_id IN (SELECT id FROM AccordoCondivisioneInformazioni
    WHERE soggetto_nis_id = (SELECT id FROM SoggettoNIS WHERE codice_fiscale = '99999999999'))
UNION ALL
SELECT 'DipendenzaStorico', COUNT(*) FROM DipendenzaStorico
WHERE dipendenza_id IN (SELECT id FROM Dipendenza
    WHERE fornitore_id = (SELECT id FROM Fornitore WHERE codice_fiscale = '88888888888'))
UNION ALL
SELECT 'AssetServizioStorico', COUNT(*) FROM AssetServizioStorico
WHERE asset_servizio_id IN (SELECT id FROM AssetServizio
    WHERE asset_id = (SELECT id FROM ElementoCritico WHERE nome = 'Asset di prova'
        AND soggetto_nis_id = (SELECT id FROM SoggettoNIS WHERE codice_fiscale = '99999999999')))
UNION ALL
SELECT 'DocumentoGovernanceElementoCriticoStorico', COUNT(*) FROM DocumentoGovernanceElementoCriticoStorico
WHERE documento_elemento_id IN (SELECT dgec.id FROM DocumentoGovernanceElementoCritico dgec
    JOIN DocumentoGovernance dg ON dg.id = dgec.documento_id
    WHERE dg.soggetto_nis_id = (SELECT id FROM SoggettoNIS WHERE codice_fiscale = '99999999999'));
