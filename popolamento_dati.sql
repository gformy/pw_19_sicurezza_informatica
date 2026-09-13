

-- --- TipoSoggettoNIS (2 righe) ---
INSERT INTO TipoSoggettoNIS (id, codice, descrizione) VALUES (1, 'ESSENZIALE', 'Soggetto NIS essenziale ai sensi del D.Lgs. 138/2024');
INSERT INTO TipoSoggettoNIS (id, codice, descrizione) VALUES (2, 'IMPORTANTE', 'Soggetto NIS importante ai sensi del D.Lgs. 138/2024');

-- --- RegistroTabelle (9 righe) ---
INSERT INTO RegistroTabelle (id, nome_tabella) VALUES (1, 'SoggettoNIS');
INSERT INTO RegistroTabelle (id, nome_tabella) VALUES (2, 'ElementoCritico');
INSERT INTO RegistroTabelle (id, nome_tabella) VALUES (3, 'Fornitore');
INSERT INTO RegistroTabelle (id, nome_tabella) VALUES (4, 'DocumentoGovernance');
INSERT INTO RegistroTabelle (id, nome_tabella) VALUES (5, 'StatoAdempimentoRequisito');
INSERT INTO RegistroTabelle (id, nome_tabella) VALUES (6, 'AccordoCondivisioneInformazioni');
INSERT INTO RegistroTabelle (id, nome_tabella) VALUES (7, 'Dipendenza');
INSERT INTO RegistroTabelle (id, nome_tabella) VALUES (8, 'AssetServizio');
INSERT INTO RegistroTabelle (id, nome_tabella) VALUES (9, 'DocumentoGovernanceElementoCritico');

-- --- TipoIncidente (4 righe, Allegati 3/4) ---
INSERT INTO TipoIncidente (codice, descrizione) VALUES ('IS-1', 'Perdita di riservatezza, verso l''esterno, di dati digitali di proprietà o sui quali si esercita il controllo, anche parziale (Allegati 3 e 4)');
INSERT INTO TipoIncidente (codice, descrizione) VALUES ('IS-2', 'Perdita di integrità, con impatto verso l''esterno, di dati digitali di proprietà o sui quali si esercita il controllo, anche parziale (Allegati 3 e 4)');
INSERT INTO TipoIncidente (codice, descrizione) VALUES ('IS-3', 'Violazione dei livelli di servizio attesi (SL) di servizi e/o attività, ai sensi della misura DE.CM-01 (Allegati 3 e 4)');
INSERT INTO TipoIncidente (codice, descrizione) VALUES ('IS-4', 'Accesso non autorizzato o con abuso di privilegi a dati digitali di proprietà o sui quali si esercita il controllo, anche parziale (solo Allegato 4 - soggetti essenziali)');

-- --- IncidenteApplicabilita: ora TipoIncidente e TipoSoggettoNIS esistono già ---
-- IS-1, IS-2, IS-3 -> entrambi i tipi di soggetto
INSERT INTO IncidenteApplicabilita (tipo_incidente_id, tipo_soggetto_id)
SELECT ti.id, ts.id
FROM TipoIncidente ti CROSS JOIN TipoSoggettoNIS ts
WHERE ti.codice IN ('IS-1', 'IS-2', 'IS-3');

-- IS-4 -> solo essenziali
INSERT INTO IncidenteApplicabilita (tipo_incidente_id, tipo_soggetto_id)
SELECT ti.id, ts.id
FROM TipoIncidente ti, TipoSoggettoNIS ts
WHERE ti.codice = 'IS-4' AND ts.codice = 'ESSENZIALE';

-- --- CategoriaIncidente (7 righe) ---
INSERT INTO CategoriaIncidente (nome) VALUES ('RANSOMWARE');
INSERT INTO CategoriaIncidente (nome) VALUES ('DDOS');
INSERT INTO CategoriaIncidente (nome) VALUES ('PHISHING');
INSERT INTO CategoriaIncidente (nome) VALUES ('DATA_BREACH');
INSERT INTO CategoriaIncidente (nome) VALUES ('MALWARE');
INSERT INTO CategoriaIncidente (nome) VALUES ('ACCESSO_NON_AUTORIZZATO');
INSERT INTO CategoriaIncidente (nome) VALUES ('ALTRO');

-- --- TipoDocumentoGovernance (9 righe) ---
INSERT INTO TipoDocumentoGovernance (codice, nome) VALUES ('GV.RM-03', 'Piano di gestione dei rischi per la sicurezza informatica');
INSERT INTO TipoDocumentoGovernance (codice, nome) VALUES ('ID.RA-06', 'Piano di trattamento del rischio');
INSERT INTO TipoDocumentoGovernance (codice, nome) VALUES ('ID.RA-08', 'Piano di gestione delle vulnerabilità');
INSERT INTO TipoDocumentoGovernance (codice, nome) VALUES ('ID.IM-04-continuita', 'Piano di continuità operativa');
INSERT INTO TipoDocumentoGovernance (codice, nome) VALUES ('ID.IM-04-ripristino', 'Piano di ripristino in caso di disastro');
INSERT INTO TipoDocumentoGovernance (codice, nome) VALUES ('ID.IM-04-crisi', 'Piano per la gestione delle crisi');
INSERT INTO TipoDocumentoGovernance (codice, nome) VALUES ('PR.AT-01', 'Piano di formazione in materia di sicurezza informatica');
INSERT INTO TipoDocumentoGovernance (codice, nome) VALUES ('RS.MA-01', 'Piano di risposta agli incidenti');
INSERT INTO TipoDocumentoGovernance (codice, nome) VALUES ('ID.IM-01', 'Piano di adeguamento');

-- --- DocumentoGovernanceApplicabilita: ora entrambe le tabelle sorgente sono complete ---
INSERT INTO DocumentoGovernanceApplicabilita (tipo_documento_id, tipo_soggetto_id)
SELECT td.id, ts.id FROM TipoDocumentoGovernance td CROSS JOIN TipoSoggettoNIS ts;