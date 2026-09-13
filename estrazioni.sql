

-- ---------------------------------------------------------------------
-- 1) Asset critici
-- ---------------------------------------------------------------------
SELECT
    ec.nome              AS nome_asset,
    a.tipo_asset,
    CASE a.rilevante WHEN 1 THEN 'SI' ELSE 'NO' END AS rilevante,
    ec.stato,
    ec.data_inizio_validita
FROM ElementoCritico ec
JOIN Asset a ON a.id = ec.id
WHERE ec.soggetto_nis_id = :soggetto_id
ORDER BY ec.nome;


-- ---------------------------------------------------------------------
-- 2) Servizi erogati
-- ---------------------------------------------------------------------
SELECT
    ec.nome              AS nome_servizio,
    s.descrizione,
    s.categoria_rilevanza,
    ec.stato,
    LISTAGG(sm.stato_membro, ', ') WITHIN GROUP (ORDER BY sm.stato_membro) AS stati_membro_offerta
FROM ElementoCritico ec
JOIN Servizio s ON s.id = ec.id
LEFT JOIN ServizioStatoMembro sm ON sm.servizio_id = s.id
WHERE ec.soggetto_nis_id = :soggetto_id
GROUP BY ec.nome, s.descrizione, s.categoria_rilevanza, ec.stato
ORDER BY ec.nome;


-- ---------------------------------------------------------------------
-- 3) Dipendenze da terze parti (fornitori rilevanti)
-- ---------------------------------------------------------------------
SELECT
    f.denominazione       AS fornitore,
    f.codice_fiscale,
    f.paese_sede_legale,
    ec.nome               AS elemento_dipendente,
    ec.tipo               AS tipo_elemento,
    d.criterio_rilevanza,
    d.tipologia_fornitura,
    d.referente_contatto,
    d.stato
FROM Dipendenza d
JOIN Fornitore f ON f.id = d.fornitore_id
JOIN ElementoCritico ec ON ec.id = d.elemento_critico_id
WHERE ec.soggetto_nis_id = :soggetto_id
ORDER BY f.denominazione;


-- ---------------------------------------------------------------------
-- 4) Punti di contatto
-- ---------------------------------------------------------------------
SELECT
    pc.nome,
    pc.ruolo,
    pc.email,
    pc.telefono,
    pc.delega
FROM PuntoDiContatto pc
WHERE pc.soggetto_nis_id = :soggetto_id
ORDER BY pc.ruolo;


-- =====================================================================
-- Varianti "AS OF" — stessa estrazione, riferita a un invio storico
-- (riusano le viste del Blocco 7/8: nessuna nuova query da scrivere,
-- solo un filtro diverso sulla stessa infrastruttura)
-- =====================================================================

-- Asset/servizi dichiarati in un invio specifico
SELECT nome, tipo, stato_al_momento_invio
FROM ProfiloACN_ElementiCritici_AsOf
WHERE invio_id = :id_invio_di_interesse
ORDER BY nome;

-- Fornitori rilevanti dichiarati in un invio specifico
SELECT denominazione, criterio_rilevanza, tipologia_fornitura, stato_al_momento_invio
FROM ProfiloACN_FornitoriRilevanti_AsOf
WHERE invio_id = :id_invio_di_interesse
ORDER BY denominazione;