-- =====================================================================
-- DATASET DI TEST — AZIENDA ENERGETICA ALFA S.P.A.
-- Da eseguire DOPO: creazione_schema.sql, popolamento_dati.sql,
-- popolamento_dati_misure.sql, viste.sql, trigger.sql.
--
-- Scenario: soggetto NIS essenziale nel settore della distribuzione
-- elettrica, usato anche come caso d'uso nella tesi (§6). Copre tutte
-- le macro-aree: anagrafica, asset/servizio (via viste ISA), fornitore
-- con dipendenza, governance con attestazione, incidente completo con
-- notifiche, due InvioACN in momenti diversi per dimostrare la
-- ricostruzione point-in-time.
--
-- Solo INSERT/UPDATE semplici, nessun blocco PL/SQL: ogni riferimento
-- a una riga già inserita è risolto con una sotto-query su un
-- attributo univoco (codice fiscale, nome, data), non su id numerici.
-- Le date di InvioACN usano SYSTIMESTAMP (non date fisse nel passato),
-- per restare sempre coerenti con il momento reale di esecuzione.
-- =====================================================================

--
-- Solo INSERT/UPDATE semplici, nessun blocco PL/SQL: ogni riferimento
-- a una riga già inserita è risolto con una sotto-query su un
-- attributo univoco (codice fiscale, nome, data), non su id numerici.
-- Le date di InvioACN usano SYSTIMESTAMP (non date fisse nel passato),
-- per restare sempre coerenti con il momento reale di esecuzione.
-- =====================================================================

-- PARTE B — Popolamento dati applicativi (solo INSERT/UPDATE semplici,
-- nessun blocco PL/SQL: ogni riferimento a una riga inserita in
-- precedenza è risolto con una sotto-query su un attributo univoco
-- (codice fiscale, nome, codice), non con variabili incatenate).
-- ---------------------------------------------------------------------

-- === Anagrafica ===
INSERT INTO SoggettoNIS (codice_fiscale, denominazione, indirizzo_sede_legale,
                          pec, email_funzionale, telefono, fatturato, bilancio,
                          n_dipendenti, tipo_soggetto_id)
VALUES ('01234567890', 'Azienda Energetica Alfa S.p.A.', 'Via Roma 10, Milano',
        'alfa@pec.it', 'sicurezza@alfa.it', '0212345678', 50000000, 12000000,
        250, (SELECT id FROM TipoSoggettoNIS WHERE codice = 'ESSENZIALE'));

INSERT INTO PuntoDiContatto (soggetto_nis_id, nome, ruolo, email, telefono)
VALUES ((SELECT id FROM SoggettoNIS WHERE codice_fiscale = '01234567890'),
        'Mario Rossi', 'REFERENTE_CSIRT', 'mario.rossi@alfa.it', '3331234567');

INSERT INTO OrganoAmministrazione (soggetto_nis_id, nome, ruolo)
VALUES ((SELECT id FROM SoggettoNIS WHERE codice_fiscale = '01234567890'),
        'Giulia Bianchi', 'Amministratore Delegato');

INSERT INTO DominioInternet (soggetto_nis_id, nome_dominio)
VALUES ((SELECT id FROM SoggettoNIS WHERE codice_fiscale = '01234567890'),
        'alfaenergia.it');

INSERT INTO IndirizzoIPPubblico (soggetto_nis_id, indirizzo)
VALUES ((SELECT id FROM SoggettoNIS WHERE codice_fiscale = '01234567890'),
        '203.0.113.10');

INSERT INTO AccordoCondivisioneInformazioni (soggetto_nis_id, controparte, descrizione, data_stipula)
VALUES ((SELECT id FROM SoggettoNIS WHERE codice_fiscale = '01234567890'),
        'CERTFin - CERT di settore Finanziario',
        'Scambio reciproco di indicatori di compromissione su base volontaria ex art. 26 c.1',
        DATE '2025-03-15');


-- === Asset e Servizi (tramite le viste, non le tabelle) ===
INSERT INTO AssetCompleto (nome, soggetto_nis_id, tipo_asset, rilevante)
VALUES ('Server applicativo primario',
        (SELECT id FROM SoggettoNIS WHERE codice_fiscale = '01234567890'),
        'HARDWARE', 1);

INSERT INTO ServizioCompleto (nome, soggetto_nis_id, descrizione, categoria_rilevanza)
VALUES ('Erogazione energia elettrica - rete distribuzione Nord',
        (SELECT id FROM SoggettoNIS WHERE codice_fiscale = '01234567890'),
        'Servizio di distribuzione energia elettrica per l''area metropolitana Nord', NULL);

INSERT INTO AssetServizio (asset_id, servizio_id)
VALUES (
    (SELECT id FROM ElementoCritico WHERE nome = 'Server applicativo primario'
        AND soggetto_nis_id = (SELECT id FROM SoggettoNIS WHERE codice_fiscale = '01234567890')),
    (SELECT id FROM ElementoCritico WHERE nome = 'Erogazione energia elettrica - rete distribuzione Nord'
        AND soggetto_nis_id = (SELECT id FROM SoggettoNIS WHERE codice_fiscale = '01234567890'))
);

INSERT INTO ServizioStatoMembro (servizio_id, stato_membro)
VALUES (
    (SELECT id FROM ElementoCritico WHERE nome = 'Erogazione energia elettrica - rete distribuzione Nord'
        AND soggetto_nis_id = (SELECT id FROM SoggettoNIS WHERE codice_fiscale = '01234567890')),
    'IT'
);


-- === Fornitori e dipendenze ===
INSERT INTO Fornitore (denominazione, codice_fiscale, paese_sede_legale)
VALUES ('CloudProvider Italia S.r.l.', '09876543210', 'IT');

INSERT INTO FornitoreCPV (fornitore_id, cpv_id)
VALUES (
    (SELECT id FROM Fornitore WHERE codice_fiscale = '09876543210'),
    (SELECT id FROM CodiceCPV WHERE codice = '72000000')
);

INSERT INTO Dipendenza (fornitore_id, elemento_critico_id, criterio_rilevanza,
                         tipologia_fornitura, referente_contatto)
VALUES (
    (SELECT id FROM Fornitore WHERE codice_fiscale = '09876543210'),
    (SELECT id FROM ElementoCritico WHERE nome = 'Erogazione energia elettrica - rete distribuzione Nord'
        AND soggetto_nis_id = (SELECT id FROM SoggettoNIS WHERE codice_fiscale = '01234567890')),
    'NON_FUNGIBILE', 'Piattaforma di monitoraggio rete elettrica', 'assistenza@cloudprovider.it'
);


-- === Governance ===
INSERT INTO PersonaleGovernance (nome, ruolo, soggetto_nis_id, punto_contatto_id)
VALUES ('Mario Rossi', 'Membro organizzazione sicurezza',
        (SELECT id FROM SoggettoNIS WHERE codice_fiscale = '01234567890'),
        (SELECT id FROM PuntoDiContatto WHERE nome = 'Mario Rossi' AND ruolo = 'REFERENTE_CSIRT'
            AND soggetto_nis_id = (SELECT id FROM SoggettoNIS WHERE codice_fiscale = '01234567890')));

INSERT INTO DocumentoGovernance (soggetto_nis_id, tipo_documento_id, data_approvazione,
                                  approvato_da, data_ultimo_riesame, versione)
VALUES (
    (SELECT id FROM SoggettoNIS WHERE codice_fiscale = '01234567890'),
    (SELECT id FROM TipoDocumentoGovernance WHERE codice = 'RS.MA-01'),
    DATE '2025-05-01',
    (SELECT id FROM OrganoAmministrazione WHERE nome = 'Giulia Bianchi'
        AND soggetto_nis_id = (SELECT id FROM SoggettoNIS WHERE codice_fiscale = '01234567890')),
    DATE '2025-05-01', 'v1.0'
);

INSERT INTO DocumentoGovernanceElementoCritico (documento_id, elemento_critico_id)
VALUES (
    (SELECT id FROM DocumentoGovernance
        WHERE soggetto_nis_id = (SELECT id FROM SoggettoNIS WHERE codice_fiscale = '01234567890')
        AND tipo_documento_id = (SELECT id FROM TipoDocumentoGovernance WHERE codice = 'RS.MA-01')),
    (SELECT id FROM ElementoCritico WHERE nome = 'Erogazione energia elettrica - rete distribuzione Nord'
        AND soggetto_nis_id = (SELECT id FROM SoggettoNIS WHERE codice_fiscale = '01234567890'))
);

-- attestazione di adempimento sul requisito fornitori, con evidenza
-- implicita (l'inventario stesso in Fornitore/Dipendenza appena creato)
INSERT INTO StatoAdempimentoRequisito (requisito_id, soggetto_nis_id, stato,
                                        responsabile_id, note)
VALUES (
    (SELECT id FROM RequisitoMisura WHERE codice = 'GV.SC-04.1'),
    (SELECT id FROM SoggettoNIS WHERE codice_fiscale = '01234567890'),
    'ATTUATO',
    (SELECT id FROM PersonaleGovernance WHERE nome = 'Mario Rossi'
        AND soggetto_nis_id = (SELECT id FROM SoggettoNIS WHERE codice_fiscale = '01234567890')),
    'Inventario fornitori mantenuto nelle tabelle Fornitore e Dipendenza, verificato annualmente'
);


-- === Incidente ===
INSERT INTO Incidente (tipo_incidente_id, soggetto_nis_id, categoria_id,
                        data_evidenza, gravita, root_cause)
VALUES (
    (SELECT id FROM TipoIncidente WHERE codice = 'IS-3'),
    (SELECT id FROM SoggettoNIS WHERE codice_fiscale = '01234567890'),
    (SELECT id FROM CategoriaIncidente WHERE nome = 'DDOS'),
    TIMESTAMP '2025-09-10 08:30:00', 'ALTA',
    'Sovraccarico infrastruttura di monitoraggio per attacco DDoS'
);

INSERT INTO IncidenteElementoCritico (incidente_id, elemento_critico_id)
VALUES (
    (SELECT id FROM Incidente
        WHERE soggetto_nis_id = (SELECT id FROM SoggettoNIS WHERE codice_fiscale = '01234567890')
        AND data_evidenza = TIMESTAMP '2025-09-10 08:30:00'),
    (SELECT id FROM ElementoCritico WHERE nome = 'Erogazione energia elettrica - rete distribuzione Nord'
        AND soggetto_nis_id = (SELECT id FROM SoggettoNIS WHERE codice_fiscale = '01234567890'))
);

INSERT INTO IndicatoreCompromissione (incidente_id, tipo, valore)
VALUES (
    (SELECT id FROM Incidente
        WHERE soggetto_nis_id = (SELECT id FROM SoggettoNIS WHERE codice_fiscale = '01234567890')
        AND data_evidenza = TIMESTAMP '2025-09-10 08:30:00'),
    'IP', '198.51.100.23'
);

INSERT INTO TimelineEvento (incidente_id, data_ora, descrizione, fase)
VALUES (
    (SELECT id FROM Incidente
        WHERE soggetto_nis_id = (SELECT id FROM SoggettoNIS WHERE codice_fiscale = '01234567890')
        AND data_evidenza = TIMESTAMP '2025-09-10 08:30:00'),
    TIMESTAMP '2025-09-10 08:30:00', 'Rilevato picco anomalo di traffico in ingresso', 'RILEVAMENTO'
);

INSERT INTO TimelineEvento (incidente_id, data_ora, descrizione, fase)
VALUES (
    (SELECT id FROM Incidente
        WHERE soggetto_nis_id = (SELECT id FROM SoggettoNIS WHERE codice_fiscale = '01234567890')
        AND data_evidenza = TIMESTAMP '2025-09-10 08:30:00'),
    TIMESTAMP '2025-09-10 09:15:00', 'Avviata analisi del traffico e isolamento preventivo', 'CONTENIMENTO'
);

INSERT INTO AttivitaRisposta (incidente_id, fase, descrizione, motivazione,
                               struttura_coinvolta_id, esito)
VALUES (
    (SELECT id FROM Incidente
        WHERE soggetto_nis_id = (SELECT id FROM SoggettoNIS WHERE codice_fiscale = '01234567890')
        AND data_evidenza = TIMESTAMP '2025-09-10 08:30:00'),
    'CONTENIMENTO', 'Isolamento del sistema di monitoraggio dalla rete esterna',
    'Prevenire la propagazione dell''attacco',
    (SELECT id FROM PersonaleGovernance WHERE nome = 'Mario Rossi'
        AND soggetto_nis_id = (SELECT id FROM SoggettoNIS WHERE codice_fiscale = '01234567890')),
    'Traffico anomalo azzerato entro 40 minuti'
);

INSERT INTO NotificaIncidente (incidente_id, tipo, data_trasmissione, contenuto)
VALUES (
    (SELECT id FROM Incidente
        WHERE soggetto_nis_id = (SELECT id FROM SoggettoNIS WHERE codice_fiscale = '01234567890')
        AND data_evidenza = TIMESTAMP '2025-09-10 08:30:00'),
    'PRE_NOTIFICA', TIMESTAMP '2025-09-10 12:00:00',
    'Possibile attacco DDoS in corso sul servizio di monitoraggio rete elettrica'
);

INSERT INTO NotificaIncidente (incidente_id, tipo, data_trasmissione, contenuto)
VALUES (
    (SELECT id FROM Incidente
        WHERE soggetto_nis_id = (SELECT id FROM SoggettoNIS WHERE codice_fiscale = '01234567890')
        AND data_evidenza = TIMESTAMP '2025-09-10 08:30:00'),
    'NOTIFICA', TIMESTAMP '2025-09-11 10:00:00',
    'Conferma attacco DDoS: traffico anomalo contenuto entro 40 minuti dal rilevamento, nessun impatto sui livelli di servizio oltre la soglia SL definita'
);


-- === Primo invio ACN (aggiornamento annuale) ===
INSERT INTO InvioACN (soggetto_nis_id, tipo_invio, data_invio, periodo_riferimento)
VALUES (
    (SELECT id FROM SoggettoNIS WHERE codice_fiscale = '01234567890'),
    'AGGIORNAMENTO_ANNUALE', SYSTIMESTAMP, EXTRACT(YEAR FROM SYSTIMESTAMP)
);


-- === Alcune settimane dopo: variazioni che dimostrano la storicizzazione ===

-- 1) aggiornamento del fatturato dichiarato dal soggetto
UPDATE SoggettoNIS SET fatturato = 55000000 WHERE codice_fiscale = '01234567890';

-- 2) un secondo asset, poi dismesso, per dimostrare il blocco del DELETE
-- e la corretta transizione di stato
INSERT INTO AssetCompleto (nome, soggetto_nis_id, tipo_asset, rilevante)
VALUES ('Vecchio switch di rete',
        (SELECT id FROM SoggettoNIS WHERE codice_fiscale = '01234567890'),
        'HARDWARE', 0);

UPDATE ElementoCritico SET stato = 'DISMESSO'
WHERE nome = 'Vecchio switch di rete'
  AND soggetto_nis_id = (SELECT id FROM SoggettoNIS WHERE codice_fiscale = '01234567890');

-- 3) aggiornamento della dipendenza: il criterio di rilevanza viene rivisto
UPDATE Dipendenza SET criterio_rilevanza = 'ICT'
WHERE fornitore_id = (SELECT id FROM Fornitore WHERE codice_fiscale = '09876543210')
  AND elemento_critico_id = (
      SELECT id FROM ElementoCritico WHERE nome = 'Erogazione energia elettrica - rete distribuzione Nord'
        AND soggetto_nis_id = (SELECT id FROM SoggettoNIS WHERE codice_fiscale = '01234567890')
  );

-- === Secondo invio ACN (aggiornamento continuo), dopo le modifiche ===
INSERT INTO InvioACN (soggetto_nis_id, tipo_invio, data_invio, periodo_riferimento)
VALUES (
    (SELECT id FROM SoggettoNIS WHERE codice_fiscale = '01234567890'),
    'AGGIORNAMENTO_CONTINUO', SYSTIMESTAMP, EXTRACT(YEAR FROM SYSTIMESTAMP)
);


-- ---------------------------------------------------------------------
-- PARTE C — Query dimostrative
-- Da eseguire dopo il blocco sopra, per verificare visivamente che
-- tutto funzioni come descritto nel README e in tesi.
-- ---------------------------------------------------------------------

-- 1) Verifica generalizzazione ISA: stessa struttura per Asset e Servizio
SELECT ec.tipo, ec.nome, ec.stato
FROM ElementoCritico ec
JOIN SoggettoNIS sn ON sn.id = ec.soggetto_nis_id
WHERE sn.codice_fiscale = '01234567890'
ORDER BY ec.tipo, ec.nome;

-- 2) Verifica storicizzazione: il fatturato del soggetto ha due versioni
-- (una chiusa in SoggettoNISStorico, una corrente in SoggettoNIS)
SELECT versione, fatturato, valido_da, valido_a FROM SoggettoNISStorico
WHERE soggetto_nis_id = (SELECT id FROM SoggettoNIS WHERE codice_fiscale = '01234567890')
UNION ALL
SELECT NULL, fatturato, NULL, NULL FROM SoggettoNIS WHERE codice_fiscale = '01234567890';

-- 3) Ricostruzione point-in-time: confronto tra i due invii
SELECT invio_id, denominazione, fatturato
FROM ProfiloACN_Anagrafica_AsOf sn
JOIN SoggettoNIS s ON s.id = sn.soggetto_nis_id
WHERE s.codice_fiscale = '01234567890'
ORDER BY invio_id;

-- 4) Elementi critici attivi al momento del PRIMO invio (prima della dismissione)
SELECT invio_id, nome, tipo, stato_al_momento_invio
FROM ProfiloACN_ElementiCritici_AsOf ec
JOIN SoggettoNIS s ON s.id = ec.soggetto_nis_id
WHERE s.codice_fiscale = '01234567890'
ORDER BY invio_id, nome;

-- 5) Verifica blocco DELETE (deve fallire con errore esplicito)
-- DELETE FROM ElementoCritico WHERE nome = 'Vecchio switch di rete';

-- 6) Timeline e notifiche dell'incidente
SELECT te.data_ora, te.fase, te.descrizione
FROM TimelineEvento te
JOIN Incidente i ON i.id = te.incidente_id
JOIN SoggettoNIS s ON s.id = i.soggetto_nis_id
WHERE s.codice_fiscale = '01234567890'
ORDER BY te.data_ora;

SELECT ni.tipo, ni.data_trasmissione, ni.contenuto
FROM NotificaIncidente ni
JOIN Incidente i ON i.id = ni.incidente_id
JOIN SoggettoNIS s ON s.id = i.soggetto_nis_id
WHERE s.codice_fiscale = '01234567890'
ORDER BY ni.data_trasmissione;

-- 7) Verifica finale: conteggio complessivo delle tabelle popolate
-- per il soggetto di test, utile come controllo rapido che tutte le
-- macro-aree abbiano dati collegati correttamente
SELECT 'Elementi critici' AS macro_area, COUNT(*) AS n_righe
FROM ElementoCritico ec JOIN SoggettoNIS s ON s.id = ec.soggetto_nis_id
WHERE s.codice_fiscale = '01234567890'
UNION ALL
SELECT 'Dipendenze da fornitori', COUNT(*)
FROM Dipendenza d
JOIN ElementoCritico ec ON ec.id = d.elemento_critico_id
JOIN SoggettoNIS s ON s.id = ec.soggetto_nis_id
WHERE s.codice_fiscale = '01234567890'
UNION ALL
SELECT 'Documenti di governance', COUNT(*)
FROM DocumentoGovernance dg JOIN SoggettoNIS s ON s.id = dg.soggetto_nis_id
WHERE s.codice_fiscale = '01234567890'
UNION ALL
SELECT 'Incidenti', COUNT(*)
FROM Incidente i JOIN SoggettoNIS s ON s.id = i.soggetto_nis_id
WHERE s.codice_fiscale = '01234567890'
UNION ALL
SELECT 'Invii ad ACN', COUNT(*)
FROM InvioACN inv JOIN SoggettoNIS s ON s.id = inv.soggetto_nis_id
WHERE s.codice_fiscale = '01234567890';
