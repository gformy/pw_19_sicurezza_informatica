-- =====================================================================
-- POPOLAMENTO DATI NORMATIVI — MISURE DI SICUREZZA (Allegati 1/2)
-- Completa popolamento_dati.sql con le tabelle non incluse lì:
-- MisuraSicurezza, RequisitoMisura, MisuraApplicabilita, CodiceCPV.
--
-- Da eseguire UNA SOLA VOLTA dopo popolamento_dati.sql (dato normativo,
-- non applicativo — non va mai duplicato per ogni azienda di test).
-- Contiene un sottoinsieme rappresentativo (5 misure), non l'elenco
-- completo dei 116 requisiti dell'Allegato 2.
-- =====================================================================

-- PARTE A — Completamento tabelle normative non ancora popolate
-- Sottoinsieme rappresentativo (non l'elenco completo dei 116
-- requisiti dell'Allegato 2), sufficiente per un test funzionale.
-- ---------------------------------------------------------------------

INSERT INTO MisuraSicurezza (codice, categoria, descrizione) VALUES
    ('GV.SC-04', 'Gestione del rischio della catena di approvvigionamento',
     'È mantenuto un inventario aggiornato dei fornitori con potenziale impatto sulla sicurezza');
INSERT INTO MisuraSicurezza (codice, categoria, descrizione) VALUES
    ('ID.AM-01', 'Gestione degli asset',
     'È mantenuto un inventario aggiornato degli apparati fisici (hardware)');
INSERT INTO MisuraSicurezza (codice, categoria, descrizione) VALUES
    ('ID.AM-04', 'Gestione degli asset',
     'È mantenuto un inventario aggiornato dei servizi informatici erogati dai fornitori');
INSERT INTO MisuraSicurezza (codice, categoria, descrizione) VALUES
    ('GV.OC-4', 'Contesto organizzativo',
     'È mantenuto un elenco aggiornato dei sistemi informativi e di rete rilevanti');
INSERT INTO MisuraSicurezza (codice, categoria, descrizione) VALUES
    ('RS.MA-01', 'Gestione della risposta agli incidenti',
     'È definito, documentato e approvato un piano di risposta agli incidenti');

INSERT INTO RequisitoMisura (codice, misura_id, numero_punto, testo)
SELECT 'GV.SC-04.1', id, 1,
       'È mantenuto un inventario aggiornato dei fornitori, comprensivo di estremi di contatto del referente e tipologia di fornitura'
FROM MisuraSicurezza WHERE codice = 'GV.SC-04';

INSERT INTO RequisitoMisura (codice, misura_id, numero_punto, testo)
SELECT 'ID.AM-01.1', id, 1,
       'È mantenuto un inventario aggiornato degli apparati fisici che compongono i sistemi informativi e di rete'
FROM MisuraSicurezza WHERE codice = 'ID.AM-01';

INSERT INTO RequisitoMisura (codice, misura_id, numero_punto, testo)
SELECT 'ID.AM-04.1', id, 1,
       'È mantenuto un inventario aggiornato dei servizi informatici erogati dai fornitori, ivi inclusi i servizi cloud'
FROM MisuraSicurezza WHERE codice = 'ID.AM-04';

INSERT INTO RequisitoMisura (codice, misura_id, numero_punto, testo)
SELECT 'GV.OC-4.1', id, 1,
       'È mantenuto un elenco aggiornato dei sistemi informativi e di rete rilevanti'
FROM MisuraSicurezza WHERE codice = 'GV.OC-4';

INSERT INTO RequisitoMisura (codice, misura_id, numero_punto, testo)
SELECT 'RS.MA-01.1', id, 1,
       'È definito, documentato e approvato dagli organi di amministrazione un piano di risposta agli incidenti'
FROM MisuraSicurezza WHERE codice = 'RS.MA-01';

-- Applicabilità: tutti e cinque i requisiti scelti si applicano sia a
-- essenziali che importanti (nessuno di questi è tra i pochi requisiti
-- esclusivi degli Allegati 2, come ID.AM-03 o PR.PS-01)
INSERT INTO MisuraApplicabilita (requisito_id, tipo_soggetto_id)
SELECT rm.id, ts.id FROM RequisitoMisura rm CROSS JOIN TipoSoggettoNIS ts;

INSERT INTO CodiceCPV (codice, descrizione) VALUES
    ('72000000', 'Servizi IT: consulenza, sviluppo di software, Internet e supporto');
INSERT INTO CodiceCPV (codice, descrizione) VALUES
    ('65310000', 'Distribuzione di energia elettrica');


-- ---------------------------------------------------------------------
