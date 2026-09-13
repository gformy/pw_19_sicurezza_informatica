-- =====================================================================
-- 01 — CREAZIONE UTENTE
-- Da eseguire come utente con privilegi amministrativi (es. SYSTEM),
-- connesso al container/pluggable database di test in DBeaver.
--
-- Cambia password e tablespace secondo il tuo ambiente locale prima
-- di eseguire. I privilegi concessi sono quelli minimi necessari per
-- creare tabelle, sequenze, indici, viste e trigger nello schema.
-- =====================================================================

CREATE USER nis2_test IDENTIFIED BY "CambiaQuestaPassword123"
    DEFAULT TABLESPACE users
    TEMPORARY TABLESPACE temp
    QUOTA UNLIMITED ON users;

GRANT CREATE SESSION TO nis2_test;
GRANT CREATE TABLE TO nis2_test;
GRANT CREATE SEQUENCE TO nis2_test;
GRANT CREATE VIEW TO nis2_test;
GRANT CREATE TRIGGER TO nis2_test;
GRANT CREATE PROCEDURE TO nis2_test;

-- A questo punto, in DBeaver, disconnettiti e riconnettiti come
-- nis2_test / Password impostata 