-- CREATE DATABASE
CREATE DATABASE banking_db;

-- CREATE TABLE users, transaction, cards
CREATE TABLE users (
    id INT PRIMARY KEY,
    current_age INT,
	retirement_age INT,
	birth_year INT,
	birth_month INT CHECK (birth_month BETWEEN 1 AND 12),
	gender VARCHAR(20),
	address TEXT,
	latitude DECIMAL(9,6),
	longitude DECIMAL(9,6),
	per_capita_income INT,
	yearly_income INT,
	total_debt INT,
	credit_score INT, 
	num_credit_cards INT
);


select * from cards;

CREATE TABLE cards (
    id INT PRIMARY KEY,
    client_id INT REFERENCES users(id),
    card_brand VARCHAR(50),
    card_type VARCHAR(50),
    card_number VARCHAR(30),
    expires VARCHAR(7) CHECK (expires ~ '^(0[1-9]|1[0-2])/[0-9]{4}$') ,
    cvv VARCHAR(10),
    has_chip BOOLEAN,
    num_cards_issued INT,
    credit_limit NUMERIC,
    acct_open_date VARCHAR(7) CHECK (acct_open_date ~ '^(0[1-9]|1[0-2])/[0-9]{4}$'), 
    year_pin_last_changed INT,
    card_on_dark_web BOOLEAN
);

CREATE TABLE transactions (
    id BIGINT PRIMARY KEY,
    date TIMESTAMP,
    client_id INT REFERENCES users(id),
    card_id INT REFERENCES cards(id),
    amount NUMERIC,
    use_chip VARCHAR(50),
    merchant_id INT,
    merchant_city VARCHAR(100),
    merchant_state VARCHAR(50),
    zip VARCHAR(20),
    mcc INT,
    errors VARCHAR(255)
);

-- add data from csv
COPY users FROM 'D:\DATA ANALYST\Technical Test\users_data.csv' DELIMITER ',' CSV HEADER;
COPY cards FROM 'D:\DATA ANALYST\Technical Test\cards_data.csv' DELIMITER ',' CSV HEADER;
COPY transactions FROM 'D:\DATA ANALYST\Technical Test\transactions_data.csv' DELIMITER ',' CSV HEADER;


-- COUNT DATA
SELECT 'users' src, COUNT(*) FROM users
UNION ALL
SELECT 'cards', COUNT(*) FROM cards
UNION ALL
SELECT 'txns', COUNT(*) FROM transactions;

-- KPI & INSIGHT --

-- KPI
-- Total Users
SELECT COUNT(*) AS total_users
FROM users;

-- Total Transactions Value
SELECT SUM(amount) AS total_transactions_value
FROM transactions;

-- Avg Credit Score
SELECT AVG(credit_score) AS avg_credit_score
FROM users;

-- Error Rate (%)
SELECT 
    (COUNT(CASE WHEN errors IS NOT NULL AND errors <> '' THEN 1 END) * 100.0) / COUNT(*) AS error_rate
FROM transactions;


-- User Profiling

-- 1. Gender Distribution
SELECT gender, COUNT(*) AS total_users
FROM users
GROUP BY gender
ORDER BY total_users DESC;

-- 2. Age Distribution
SELECT current_age, COUNT(*) AS total_users
FROM users
GROUP BY current_age
ORDER BY current_age;

-- 3. Group Age User
WITH age_groups AS (
    SELECT
        CASE 
            WHEN current_age < 25 THEN '<25'
            WHEN current_age BETWEEN 25 AND 34 THEN '25-34'
            WHEN current_age BETWEEN 35 AND 44 THEN '35-44'
            WHEN current_age BETWEEN 45 AND 54 THEN '45-54'
            WHEN current_age BETWEEN 55 AND 64 THEN '55-64'
            ELSE '65+'
        END AS age_group
    FROM users
)
SELECT
    age_group,
    COUNT(*) AS total_users
FROM age_groups
GROUP BY age_group
ORDER BY 
    CASE age_group
        WHEN '<25' THEN 1
        WHEN '25-34' THEN 2
        WHEN '35-44' THEN 3
        WHEN '45-54' THEN 4
        WHEN '55-64' THEN 5
        ELSE 6
    END;



-- Card Insight
-- 1. Card Brand & Type Distribution 
SELECT card_brand, card_type, COUNT(*) AS total_cards
FROM cards
GROUP BY card_brand, card_type
ORDER BY total_cards DESC;

-- 2. % Has Chip
SELECT 
    CASE WHEN has_chip = TRUE THEN 'With Chip' ELSE 'Without Chip' END AS chip_status,
    COUNT(*) AS total_cards,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM cards), 2) AS pct_cards
FROM cards
GROUP BY chip_status
ORDER BY total_cards DESC;


-- Transactions Analysis
-- 1. Transactions Month Trend by Amount
SELECT 
    DATE_TRUNC('month', date) AS month,
    COUNT(*) AS txn_count,
    SUM(amount) AS total_amount
FROM transactions
GROUP BY month
ORDER BY month;

-- 2. Merchant Performance by State
SELECT merchant_state,
       COUNT(*) AS txn_count,
       SUM(amount) AS total_amount,
       ROUND(AVG(amount),2) AS avg_amount
FROM transactions
WHERE merchant_state IS NOT NULL AND merchant_state <> ''
GROUP BY merchant_state
ORDER BY total_amount DESC;


-- Error Analysis
-- Transaction Error per Type
SELECT errors AS error_type,
       COUNT(*) AS total_errors,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM transactions), 2) AS pct_of_total_txn
FROM transactions
WHERE errors IS NOT NULL AND errors <> ''
GROUP BY errors
ORDER BY total_errors DESC;
