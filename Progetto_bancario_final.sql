-- ======================================================
-- Analisi di un sistema bancario
-- Creazione di una tabella denormalizzata che contenga indicatori comportamentali sul cliente, calcolati sulla base delle transazioni e del possesso prodotti.
-- ======================================================

/*
Età del cliente
*/

CREATE TEMPORARY TABLE IF NOT EXISTS tmp_eta AS
SELECT 
    c.id_cliente, 
    TIMESTAMPDIFF(YEAR, c.data_nascita, CURDATE()) AS eta -- TIMESTAMPDIFF calcola la differenza tra due date, data di nascita e data corrente.
FROM 
    cliente c; -- tabella da dove prendere i dati, alias c.

select * from tmp_eta;

/* 
Numero e Importo di Transazioni in Uscita e in Entrata
*/

CREATE TEMPORARY TABLE IF NOT EXISTS tmp_transazioni AS
SELECT 
    co.id_cliente,
    SUM(CASE WHEN tt.segno = '-' THEN 1 ELSE 0 END) AS num_trans_uscita, -- aggiunge un 1 quando il segno è -, e somma il tutto per avere il totale.
    SUM(CASE WHEN tt.segno = '+' THEN 1 ELSE 0 END) AS num_trans_entrata,
    SUM(CASE WHEN tt.segno = '-' THEN t.importo ELSE 0 END) AS imp_trans_uscita,
    SUM(CASE WHEN tt.segno = '+' THEN t.importo ELSE 0 END) AS imp_trans_entrata
FROM 
    transazioni t -- tabella da cui prende i dati
JOIN 
    conto co ON t.id_conto = co.id_conto -- join con la tabella conto per associare ogni transazione al relativo cliente tramite id del conto.
JOIN 
    tipo_transazione tt ON t.id_tipo_trans = tt.id_tipo_transazione -- join con tabella tipo_transazione per determinare il segno di ogni transazione.
GROUP BY 1; -- raggruppa i risultati per id_cliente.

select * from tmp_transazioni;

/*
Numero Totale di Conti Posseduti
*/

CREATE TEMPORARY TABLE IF NOT EXISTS tmp_num_conti AS
SELECT 
    id_cliente, 
    COUNT(*) AS num_conti_totali -- conta il numero di conti totali e raggruppa.
FROM 
    conto
GROUP BY 1;

select * from tmp_num_conti;

/*
Numero di conti posseduti per tipologia
*/

-- Tabella temporanea che riassume, per ogni cliente, quanti conti ha in ciascuna tipologia specificata (Conto Base, Conto Business, Conto Privati, e Conto Famiglie), oltre al numero totale di conti. 

CREATE TEMPORARY TABLE temp_num_conti_per_tipologia AS
SELECT 
    c.id_cliente,
    SUM(CASE WHEN tc.desc_tipo_conto = 'Conto Base' THEN 1 ELSE 0 END) AS Conto_Base, -- calcola il numero di conti per tipologia, aggiunge 1 se la tipologia è quella specificata. Altrimenti 0.
    SUM(CASE WHEN tc.desc_tipo_conto = 'Conto Business' THEN 1 ELSE 0 END) AS Conto_Business,
    SUM(CASE WHEN tc.desc_tipo_conto = 'Conto Privati' THEN 1 ELSE 0 END) AS Conto_Privati,
    SUM(CASE WHEN tc.desc_tipo_conto = 'Conto Famiglie' THEN 1 ELSE 0 END) AS Conto_Famiglie,
    COUNT(co.id_conto) AS numero_conti_totali 
FROM cliente c -- fonte dei dati
JOIN conto co ON c.id_cliente = co.id_cliente -- unisce la tabella conto basandosi sull'id cliente, collegando così ogni conto al relativo cliente.
JOIN tipo_conto tc ON co.id_tipo_conto = tc.id_tipo_conto -- unisce tipo_conto alla query per poter determinare la tipologia di ogni conto basandosi su id_tipo_conto.
GROUP BY 1;

select * from temp_num_conti_per_tipologia;

/*
Numero di transazioni in uscita per tipologia di conto
*/


CREATE TEMPORARY TABLE temp_trans_uscita_per_tipologia AS
SELECT 
    c.id_cliente,
	SUM(CASE WHEN tt.id_tipo_transazione = '3' THEN 1 ELSE 0 END) AS Acquisto_su_Amazon, -- conteggio condizionale per tipologia di uscita. Se corrisponde, incrementa il conteggio.
    SUM(CASE WHEN tt.id_tipo_transazione = '4' THEN 1 ELSE 0 END) AS Rata_mutuo,
    SUM(CASE WHEN tt.id_tipo_transazione = '5' THEN 1 ELSE 0 END) AS Hotel,
    SUM(CASE WHEN tt.id_tipo_transazione = '6' THEN 1 ELSE 0 END) AS Biglietto_aereo,
    SUM(CASE WHEN tt.id_tipo_transazione = '7' THEN 1 ELSE 0 END) AS Supermercato
FROM cliente c -- fonte dei dati
JOIN conto co ON c.id_cliente = co.id_cliente  -- unisce la tabella conto basandosi sull'id cliente, collegando così ogni conto al relativo cliente.
JOIN tipo_conto tc ON co.id_tipo_conto = tc.id_tipo_conto -- unisce tipo_conto alla query per poter determinare la tipologia di ogni conto basandosi su id_tipo_conto.
JOIN transazioni t ON co.id_conto = t.id_conto  -- unisce la tabella transazioni per accedere a tutte le transazione effettuate dai conti dei clienti.
JOIN tipo_transazione tt ON t.id_tipo_trans = tt.id_tipo_transazione AND tt.segno = '-' -- join con tipo_transazione per filtrare solo le transazioni con il segno meno.
GROUP BY 1;

select * from temp_trans_uscita_per_tipologia;

/*
Numero di transazioni in entrata per tipologia di conto
*/

CREATE TEMPORARY TABLE temp_trans_entrata_per_tipologia AS
SELECT 
    c.id_cliente,
	SUM(CASE WHEN tt.id_tipo_transazione = '0' THEN 1 ELSE 0 END) AS Stipendio, -- conteggio condizionale per tipologia di entrata. Se corrisponde, incrementa il conteggio.
    SUM(CASE WHEN tt.id_tipo_transazione = '1' THEN 1 ELSE 0 END) AS Pensione,
    SUM(CASE WHEN tt.id_tipo_transazione = '2' THEN 1 ELSE 0 END) AS Dividendi
FROM cliente c -- fonte dei dati
JOIN conto co ON c.id_cliente = co.id_cliente -- unisce la tabella conto basandosi sull'id cliente, collegando così ogni conto al relativo cliente.
JOIN tipo_conto tc ON co.id_tipo_conto = tc.id_tipo_conto -- unisce tipo_conto alla query per poter determinare la tipologia di ogni conto basandosi su id_tipo_conto.
JOIN transazioni t ON co.id_conto = t.id_conto -- unisce la tabella transazioni per accedere a tutte le transazione effettuate dai conti dei clienti.
JOIN tipo_transazione tt ON t.id_tipo_trans = tt.id_tipo_transazione AND tt.segno = '+' -- join con tipo_transazione per filtrare solo le transazioni con il segno più.
GROUP BY c.id_cliente;

select * from temp_trans_entrata_per_tipologia;

/*
-- Importo transato in uscita per tipologia di conto
*/

CREATE TEMPORARY TABLE temp_importo_uscita_per_tipologia AS
SELECT 
    co.id_cliente, 
    SUM(CASE WHEN tc.desc_tipo_conto = 'Conto Base' THEN t.importo ELSE 0 END) AS importo_totale_uscita_conto_base, -- conteggio condizionale per importo di uscita dal conto. Se corrisponde, somma le uscite.
    SUM(CASE WHEN tc.desc_tipo_conto = 'Conto Business' THEN t.importo ELSE 0 END) AS importo_totale_uscita_conto_business,
    SUM(CASE WHEN tc.desc_tipo_conto = 'Conto Privati' THEN t.importo ELSE 0 END) AS importo_totale_uscita_conto_privati,
    SUM(CASE WHEN tc.desc_tipo_conto = 'Conto Famiglie' THEN t.importo ELSE 0 END) AS importo_totale_uscita_conto_famiglie
FROM 
    transazioni t -- fonte dei dati
JOIN 
    conto co ON t.id_conto = co.id_conto -- unisce la tabella conto basandosi sull'id conto, collegando così ogni conto al rispettivo id.
JOIN 
    tipo_conto tc ON co.id_tipo_conto = tc.id_tipo_conto 
JOIN 
    tipo_transazione tt ON t.id_tipo_trans = tt.id_tipo_transazione
WHERE 
    tt.segno = '-'
GROUP BY 
    co.id_cliente;

/*
-- Importo transato in entrata per tipologia di conto
*/

CREATE TEMPORARY TABLE temp_importo_entrata_per_tipologia AS
SELECT 
    co.id_cliente, 
    SUM(CASE WHEN tc.desc_tipo_conto = 'Conto Base' THEN t.importo ELSE 0 END) AS importo_totale_entrata_conto_base, -- conteggio condizionale per importo di uscita dal conto. Se corrisponde, somma le entrate.
    SUM(CASE WHEN tc.desc_tipo_conto = 'Conto Business' THEN t.importo ELSE 0 END) AS importo_totale_entrata_conto_business,
    SUM(CASE WHEN tc.desc_tipo_conto = 'Conto Privati' THEN t.importo ELSE 0 END) AS importo_totale_entrata_conto_privati,
    SUM(CASE WHEN tc.desc_tipo_conto = 'Conto Famiglie' THEN t.importo ELSE 0 END) AS importo_totale_entrata_conto_famiglie
FROM 
    transazioni t -- fonte dei dati
JOIN 
    conto co ON t.id_conto = co.id_conto
JOIN 
    tipo_conto tc ON co.id_tipo_conto = tc.id_tipo_conto
JOIN 
    tipo_transazione tt ON t.id_tipo_trans = tt.id_tipo_transazione
WHERE 
    tt.segno = '+'
GROUP BY 
    co.id_cliente;

/*
Creazione tabella finale, chiamata features_ml.
*/


CREATE TABLE features_ml AS
SELECT
    e.id_cliente,
    e.eta,
    t.num_trans_uscita,
    t.num_trans_entrata,
    t.imp_trans_uscita,
    t.imp_trans_entrata,
    nc.num_conti_totali,
    ct.Conto_Base,
    ct.Conto_Business,
    ct.Conto_Privati,
    ct.Conto_Famiglie,
    tu.Acquisto_su_Amazon,
    tu.Rata_mutuo,
    tu.Hotel,
    tu.Biglietto_aereo,
    tu.Supermercato,
    te.Stipendio,
    te.Pensione,
    te.Dividendi,
    iu.importo_totale_uscita_conto_base,
    iu.importo_totale_uscita_conto_business,
    iu.importo_totale_uscita_conto_privati,
    iu.importo_totale_uscita_conto_famiglie,
    ie.importo_totale_entrata_conto_base,
    ie.importo_totale_entrata_conto_business,
    ie.importo_totale_entrata_conto_privati,
    ie.importo_totale_entrata_conto_famiglie
FROM 
    tmp_eta e
LEFT JOIN 
    tmp_transazioni t ON e.id_cliente = t.id_cliente
LEFT JOIN 
    tmp_num_conti nc ON e.id_cliente = nc.id_cliente
LEFT JOIN 
    temp_num_conti_per_tipologia ct ON e.id_cliente = ct.id_cliente
LEFT JOIN 
    temp_trans_uscita_per_tipologia tu ON e.id_cliente = tu.id_cliente
LEFT JOIN 
    temp_trans_entrata_per_tipologia te ON e.id_cliente = te.id_cliente
LEFT JOIN 
    temp_importo_uscita_per_tipologia iu ON e.id_cliente = iu.id_cliente
LEFT JOIN 
    temp_importo_entrata_per_tipologia ie ON e.id_cliente = ie.id_cliente;

-- Visualizza la tabella denormalizzata
SELECT * FROM features_ml;


