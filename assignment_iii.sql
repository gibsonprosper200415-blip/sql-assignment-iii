
-- Parent table 1: suppliers
CREATE TABLE suppliers (
    supplier_id   INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    supplier_name VARCHAR(100) NOT NULL,
    phone         VARCHAR(15)  NOT NULL UNIQUE,
    city          VARCHAR(50)  NOT NULL
);

-- Parent table 2: customers
CREATE TABLE customers (
    customer_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name   VARCHAR(100) NOT NULL,
    phone       VARCHAR(15)  NOT NULL UNIQUE,
    district    VARCHAR(50)  NOT NULL
);

-- Child of suppliers: medicines
CREATE TABLE medicines (
    medicine_id   INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    medicine_name VARCHAR(100)  NOT NULL,
    category      VARCHAR(50)   NOT NULL,
    unit_price    NUMERIC(10,2) NOT NULL CHECK (unit_price >= 0),
    stock_qty     INT           NOT NULL DEFAULT 0 CHECK (stock_qty >= 0),
    expiry_date   DATE          NOT NULL,
    supplier_id   INT           NOT NULL,
    CONSTRAINT fk_medicines_supplier
        FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id)
);

-- Child of customers and medicines: sales
CREATE TABLE sales (
    sale_id     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id INT  NOT NULL,
    medicine_id INT  NOT NULL,
    quantity    INT  NOT NULL CHECK (quantity > 0),
    sale_date   DATE NOT NULL DEFAULT CURRENT_DATE,
    CONSTRAINT fk_sales_customer
        FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    CONSTRAINT fk_sales_medicine
        FOREIGN KEY (medicine_id) REFERENCES medicines(medicine_id)
);

-- ---------------------------------------------------------------------
-- ERD STEP (do it NOW, before Section 7 / ALTER TABLE):
-- pgAdmin 4 -> right-click the database -> "ERD For Database"
-- -> Download image -> save as erd.png
-- ---------------------------------------------------------------------


-- =====================================================================
-- SECTION 3: INITIAL DATA INSERTION (at least 5 records per table)
-- Primary keys are NOT inserted (auto-generated).
-- Parent tables first, then child tables.
-- =====================================================================

INSERT INTO suppliers (supplier_name, phone, city) VALUES
('MediPlus Rwanda Ltd',     '0788100001', 'Kigali'),
('HealthCare Distributors', '0788100002', 'Huye'),
('PharmaLink Africa',       '0788100003', 'Musanze'),
('Great Lakes Pharma',      '0788100004', 'Rubavu'),
('Unity Medical Supplies',  '0788100005', 'Kigali');

INSERT INTO customers (full_name, phone, district) VALUES
('Jean Habimana',  '0788200001', 'Gasabo'),
('Alice Mukamana', '0788200002', 'Kicukiro'),
('Eric Niyonzima', '0788200003', 'Nyarugenge'),
('Grace Uwase',    '0788200004', 'Gasabo'),
('David Uwimana',  '0788200005', 'Huye');

INSERT INTO medicines (medicine_name, category, unit_price, stock_qty, expiry_date, supplier_id) VALUES
('Paracetamol 500mg',     'Painkiller',    200.00, 500, '2027-08-31', 1),
('Amoxicillin 250mg',     'Antibiotic',    600.00, 300, '2027-05-30', 2),
('Ibuprofen 400mg',       'Painkiller',    350.00, 250, '2027-11-30', 1),
('Cetirizine 10mg',       'Antihistamine', 250.00,  40, '2027-03-31', 3),
('Oral Rehydration Salts','Rehydration',   150.00, 400, '2028-01-31', 4);

INSERT INTO sales (customer_id, medicine_id, quantity, sale_date) VALUES
(1, 1, 10, '2026-10-01'),
(2, 2,  2, '2026-10-02'),
(3, 3,  5, '2026-10-03'),
(1, 4,  1, '2026-10-04'),
(4, 5,  6, '2026-10-05'),
(2, 1,  3, '2026-10-06');

-- Verification: every table has at least 5 records
SELECT 'suppliers' AS table_name, COUNT(*) AS total_rows FROM suppliers
UNION ALL
SELECT 'customers', COUNT(*) FROM customers
UNION ALL
SELECT 'medicines', COUNT(*) FROM medicines
UNION ALL
SELECT 'sales', COUNT(*) FROM sales;

-- Verification: auto-generated keys and foreign keys work
SELECT * FROM suppliers;
SELECT * FROM customers;
SELECT * FROM medicines;
SELECT * FROM sales;


-- =====================================================================
-- SECTION 4: SELECT TASKS
-- =====================================================================

-- Q1.1 Basic data retrieval
-- Objective: display the name, category and price of every medicine.
SELECT medicine_name, category, unit_price
FROM medicines;

-- Q1.2 Conditional data retrieval
-- Objective: find medicines that are running low (stock below 100).
SELECT medicine_name, stock_qty
FROM medicines
WHERE stock_qty < 100;

-- Q1.3 Sorted data retrieval
-- Objective: list medicines from the most expensive to the cheapest.
SELECT medicine_name, unit_price
FROM medicines
ORDER BY unit_price DESC;


-- =====================================================================
-- SECTION 5: JOIN TASKS
-- =====================================================================

-- Q2.1 INNER JOIN
-- Objective: show each medicine with the supplier that provides it.
SELECT m.medicine_name, s.supplier_name, s.city
FROM medicines m
INNER JOIN suppliers s ON m.supplier_id = s.supplier_id;

-- Q2.2 LEFT JOIN
-- Objective: list ALL customers, including those who have not bought anything.
SELECT c.customer_id, c.full_name, s.sale_id, s.quantity
FROM customers c
LEFT JOIN sales s ON c.customer_id = s.customer_id
ORDER BY c.customer_id, s.sale_id;

-- Q2.3 Multi-table JOIN (4 tables)
-- Objective: sales report with customer, medicine, supplier and total amount.
SELECT s.sale_id,
       c.full_name     AS customer,
       m.medicine_name AS medicine,
       sp.supplier_name AS supplier,
       s.quantity,
       s.quantity * m.unit_price AS total_amount
FROM sales s
JOIN customers c  ON s.customer_id = c.customer_id
JOIN medicines m  ON s.medicine_id = m.medicine_id
JOIN suppliers sp ON m.supplier_id = sp.supplier_id
ORDER BY s.sale_id;


-- =====================================================================
-- SECTION 6: UPDATE TASKS AND VERIFICATION
-- Always identify the target rows first, update with WHERE, then verify.
-- =====================================================================

-- Q3.1 Update one record
-- Objective: after selling stock, set Paracetamol stock to 450.
SELECT medicine_id, medicine_name, stock_qty FROM medicines WHERE medicine_id = 1;   -- before

UPDATE medicines
SET stock_qty = 450
WHERE medicine_id = 1;

SELECT medicine_id, medicine_name, stock_qty FROM medicines WHERE medicine_id = 1;   -- after

-- Q3.2 Update multiple records
-- Objective: raise the price of every Painkiller by 10%.
SELECT medicine_id, medicine_name, unit_price FROM medicines WHERE category = 'Painkiller';  -- before

UPDATE medicines
SET unit_price = ROUND(unit_price * 1.10, 2)
WHERE category = 'Painkiller';

SELECT medicine_id, medicine_name, unit_price FROM medicines WHERE category = 'Painkiller';  -- after

-- Q3.3 Conditional update (business rule)
-- Rule: medicines that expire before 30 June 2027 and are still in stock get a 20% discount.
SELECT medicine_id, medicine_name, expiry_date, stock_qty, unit_price
FROM medicines
WHERE expiry_date < DATE '2027-06-30' AND stock_qty > 0;                            -- before

UPDATE medicines
SET unit_price = ROUND(unit_price * 0.80, 2)
WHERE expiry_date < DATE '2027-06-30' AND stock_qty > 0;

SELECT medicine_id, medicine_name, expiry_date, stock_qty, unit_price
FROM medicines
WHERE expiry_date < DATE '2027-06-30' AND stock_qty > 0;                            -- after


-- =====================================================================
-- SECTION 7: ALTER TABLE TASKS AND VERIFICATION
-- (The ERD must already be saved as erd.png before this section.)
-- =====================================================================

-- Q4.1 Rename a column
-- Objective: rename customers.district to home_district (clearer meaning).
ALTER TABLE customers
RENAME COLUMN district TO home_district;

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'customers';

SELECT full_name, home_district FROM customers;   -- data still accessible

-- Q4.2 Change a column's data type
-- Objective: change medicines.stock_qty from INT to BIGINT (safe widening, no data loss).
ALTER TABLE medicines
ALTER COLUMN stock_qty TYPE BIGINT USING stock_qty::BIGINT;

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'medicines' AND column_name = 'stock_qty';

SELECT medicine_name, stock_qty FROM medicines;   -- existing values unchanged

-- Q4.3 Add a column
-- Objective: store the manufacturer of each medicine.
ALTER TABLE medicines
ADD COLUMN manufacturer VARCHAR(100) DEFAULT 'Unknown';

SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_name = 'medicines'
ORDER BY ordinal_position;

SELECT medicine_id, medicine_name, manufacturer FROM medicines;


-- =====================================================================
-- SECTION 8: ADDITIONAL INSERT TASKS AND VERIFICATION
-- =====================================================================

-- Q5.1 Insert a single record
-- Objective: register a new supplier.
INSERT INTO suppliers (supplier_name, phone, city)
VALUES ('BioCare Pharma', '0788100006', 'Kigali');

SELECT * FROM suppliers WHERE supplier_name = 'BioCare Pharma';

-- Q5.2 Insert multiple records
-- Objective: add three new medicines in one statement.
INSERT INTO medicines (medicine_name, category, unit_price, stock_qty, expiry_date, supplier_id) VALUES
('Metronidazole 250mg', 'Antibiotic',  450.00, 200, '2028-02-28', 2),
('Vitamin C 500mg',     'Vitamin',     100.00, 600, '2028-06-30', 5),
('Salbutamol Inhaler',  'Respiratory', 3500.00, 60, '2027-12-31', 3);

SELECT medicine_id, medicine_name, category, unit_price, stock_qty
FROM medicines
ORDER BY medicine_id;

-- Q5.3 Insert a related record (child table, valid foreign keys)
-- Objective: record a sale for customer 5 (David Uwimana) buying medicine 2 (Amoxicillin).
INSERT INTO sales (customer_id, medicine_id, quantity, sale_date)
VALUES (5, 2, 1, '2026-10-25');

SELECT s.sale_id, c.full_name, m.medicine_name, s.quantity, s.sale_date
FROM sales s
JOIN customers c ON s.customer_id = c.customer_id
JOIN medicines m ON s.medicine_id = m.medicine_id
WHERE s.sale_id = (SELECT MAX(sale_id) FROM sales);

-- Constraint demonstration (this SHOULD FAIL; useful to explain in the quiz):
-- INSERT INTO sales (customer_id, medicine_id, quantity) VALUES (99, 1, 2);
--   -> ERROR: foreign key violation, customer 99 does not exist.
-- INSERT INTO sales (customer_id, medicine_id, quantity) VALUES (1, 1, 0);
--   -> ERROR: check constraint violated, quantity must be greater than 0.

-- =====================================================================
-- END OF FILE
-- =====================================================================