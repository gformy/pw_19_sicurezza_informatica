

CREATE OR REPLACE VIEW SoggettoNIS_Versioni AS
SELECT soggetto_nis_id, versione, denominazione, indirizzo_sede_legale, pec,
       email_funzionale, telefono, fatturato, bilancio, n_dipendenti, valido_da, valido_a
FROM SoggettoNISStorico
UNION ALL
SELECT s.id, NVL((SELECT MAX(versione)+1 FROM SoggettoNISStorico WHERE soggetto_nis_id = s.id), 1),
       s.denominazione, s.indirizzo_sede_legale, s.pec, s.email_funzionale, s.telefono,
       s.fatturato, s.bilancio, s.n_dipendenti,
       NVL((SELECT MAX(valido_a) FROM SoggettoNISStorico WHERE soggetto_nis_id = s.id), s.data_creazione),
       NULL
FROM SoggettoNIS s;

CREATE OR REPLACE VIEW ElementoCritico_Versioni AS
SELECT elemento_critico_id, versione, nome, soggetto_nis_id, stato, valido_da, valido_a
FROM ElementoCriticoStorico
UNION ALL
SELECT ec.id, NVL((SELECT MAX(versione)+1 FROM ElementoCriticoStorico WHERE elemento_critico_id = ec.id), 1),
       ec.nome, ec.soggetto_nis_id, ec.stato,
       NVL((SELECT MAX(valido_a) FROM ElementoCriticoStorico WHERE elemento_critico_id = ec.id), ec.data_inizio_validita),
       NULL
FROM ElementoCritico ec;

CREATE OR REPLACE VIEW Dipendenza_Versioni AS
SELECT dipendenza_id, versione, criterio_rilevanza, tipologia_fornitura, stato, valido_da, valido_a
FROM DipendenzaStorico
UNION ALL
SELECT d.id, NVL((SELECT MAX(versione)+1 FROM DipendenzaStorico WHERE dipendenza_id = d.id), 1),
       d.criterio_rilevanza, d.tipologia_fornitura, d.stato,
       NVL((SELECT MAX(valido_a) FROM DipendenzaStorico WHERE dipendenza_id = d.id), TIMESTAMP '0001-01-01 00:00:00'),
       NULL
FROM Dipendenza d;

CREATE OR REPLACE VIEW StatoAdempimentoRequisito_Versioni AS
SELECT stato_adempimento_id, versione, stato, data_valutazione, valido_da, valido_a
FROM StatoAdempimentoRequisitoStorico
UNION ALL
SELECT sar.id, NVL((SELECT MAX(versione)+1 FROM StatoAdempimentoRequisitoStorico WHERE stato_adempimento_id = sar.id), 1),
       sar.stato, sar.data_valutazione,
       NVL((SELECT MAX(valido_a) FROM StatoAdempimentoRequisitoStorico WHERE stato_adempimento_id = sar.id), TIMESTAMP '0001-01-01 00:00:00'),
       NULL
FROM StatoAdempimentoRequisito sar;


-- ---------------------------------------------------------------------
-- Viste "AS OF" — ricostruzione del profilo dichiarato ad ACN a un
-- dato momento (join con InvioACN sull'intervallo di validità)
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW ProfiloACN_ElementiCritici_AsOf AS
SELECT i.id AS invio_id, i.soggetto_nis_id, i.data_invio,
       ecv.elemento_critico_id, ecv.nome, ec.tipo, ecv.stato AS stato_al_momento_invio
FROM InvioACN i
JOIN ElementoCritico_Versioni ecv
    ON ecv.soggetto_nis_id = i.soggetto_nis_id
    AND ecv.valido_da <= i.data_invio
    AND (ecv.valido_a IS NULL OR ecv.valido_a > i.data_invio)
JOIN ElementoCritico ec ON ec.id = ecv.elemento_critico_id;

CREATE OR REPLACE VIEW ProfiloACN_FornitoriRilevanti_AsOf AS
SELECT i.id AS invio_id, i.soggetto_nis_id, i.data_invio,
       f.denominazione, dv.criterio_rilevanza, dv.tipologia_fornitura, dv.stato AS stato_al_momento_invio
FROM InvioACN i
JOIN Dipendenza d ON 1 = 1
JOIN Dipendenza_Versioni dv
    ON dv.dipendenza_id = d.id
    AND dv.valido_da <= i.data_invio
    AND (dv.valido_a IS NULL OR dv.valido_a > i.data_invio)
JOIN ElementoCritico ec ON ec.id = d.elemento_critico_id AND ec.soggetto_nis_id = i.soggetto_nis_id
JOIN Fornitore f ON f.id = d.fornitore_id;

CREATE OR REPLACE VIEW ProfiloACN_Adempimento_AsOf AS
SELECT i.id AS invio_id, i.soggetto_nis_id, i.data_invio,
       rm.codice AS requisito, sav.stato AS stato_al_momento_invio, sav.data_valutazione
FROM InvioACN i
JOIN StatoAdempimentoRequisito sar ON sar.soggetto_nis_id = i.soggetto_nis_id
JOIN StatoAdempimentoRequisito_Versioni sav
    ON sav.stato_adempimento_id = sar.id
    AND sav.valido_da <= i.data_invio
    AND (sav.valido_a IS NULL OR sav.valido_a > i.data_invio)
JOIN RequisitoMisura rm ON rm.id = sar.requisito_id;

CREATE OR REPLACE VIEW ProfiloACN_Anagrafica_AsOf AS
SELECT i.id AS invio_id, i.soggetto_nis_id, i.data_invio,
       snv.denominazione, snv.indirizzo_sede_legale, snv.pec, snv.fatturato, snv.n_dipendenti
FROM InvioACN i
JOIN SoggettoNIS_Versioni snv
    ON snv.soggetto_nis_id = i.soggetto_nis_id
    AND snv.valido_da <= i.data_invio
    AND (snv.valido_a IS NULL OR snv.valido_a > i.data_invio);


CREATE OR REPLACE VIEW AssetCompleto AS
SELECT a.id, ec.nome, ec.soggetto_nis_id, ec.stato, ec.data_inizio_validita, ec.data_fine_validita,
       a.tipo_asset, a.rilevante
FROM Asset a
JOIN ElementoCritico ec ON ec.id = a.id;

CREATE OR REPLACE TRIGGER trg_insert_asset_completo
INSTEAD OF INSERT ON AssetCompleto
FOR EACH ROW
DECLARE
    v_id ElementoCritico.id%TYPE;
BEGIN
    INSERT INTO ElementoCritico (tipo, nome, soggetto_nis_id)
    VALUES ('ASSET', :NEW.nome, :NEW.soggetto_nis_id)
    RETURNING id INTO v_id;

    INSERT INTO Asset (id, tipo_asset, rilevante)
    VALUES (v_id, :NEW.tipo_asset, NVL(:NEW.rilevante, 0));
END;

CREATE OR REPLACE VIEW ServizioCompleto AS
SELECT s.id, ec.nome, ec.soggetto_nis_id, ec.stato, ec.data_inizio_validita, ec.data_fine_validita,
       s.descrizione, s.categoria_rilevanza
FROM Servizio s
JOIN ElementoCritico ec ON ec.id = s.id;

CREATE OR REPLACE TRIGGER trg_insert_servizio_completo
INSTEAD OF INSERT ON ServizioCompleto
FOR EACH ROW
DECLARE
    v_id ElementoCritico.id%TYPE;
BEGIN
    INSERT INTO ElementoCritico (tipo, nome, soggetto_nis_id)
    VALUES ('SERVIZIO', :NEW.nome, :NEW.soggetto_nis_id)
    RETURNING id INTO v_id;

    INSERT INTO Servizio (id, descrizione, categoria_rilevanza)
    VALUES (v_id, :NEW.descrizione, :NEW.categoria_rilevanza);
END;
