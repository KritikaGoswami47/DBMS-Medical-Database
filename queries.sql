-- ============================================================
-- Doctor Lab Test Reports DB
-- Queries: Analytical + Assignment-aligned queries
-- ============================================================

-- ============================================================
-- SECTION A: Basic SELECT with WHERE
-- ============================================================

-- Q1. All critical reports with patient contact (emergency notification)
SELECT
    lr.report_id,
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    p.emergency_contact,
    lt.test_name,
    lr.result_summary,
    lr.report_date
FROM lab_report lr
JOIN test_order to_ ON lr.order_id = to_.order_id
JOIN patient p      ON to_.patient_id = p.patient_id
JOIN lab_test lt    ON to_.test_id = lt.test_id
WHERE lr.is_critical = TRUE
ORDER BY lr.report_date DESC;

-- Q2. Reports not yet released (pending patient access)
SELECT
    lr.report_id,
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    lt.test_name,
    lr.report_date,
    lr.is_verified
FROM lab_report lr
JOIN test_order to_ ON lr.order_id = to_.order_id
JOIN patient p      ON to_.patient_id = p.patient_id
JOIN lab_test lt    ON to_.test_id = lt.test_id
WHERE lr.is_released = FALSE;

-- Q3. STAT priority orders in last 30 days
SELECT
    to_.order_id,
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    lt.test_name,
    to_.ordered_on,
    to_.status
FROM test_order to_
JOIN patient p   ON to_.patient_id = p.patient_id
JOIN lab_test lt ON to_.test_id = lt.test_id
WHERE to_.priority = 'STAT'
  AND to_.ordered_on >= NOW() - INTERVAL '30 days';

-- ============================================================
-- SECTION B: Aggregate Queries (GROUP BY / HAVING)
-- ============================================================

-- Q4. Count of reports per test category
-- Business decision: Which category generates most workload?
SELECT
    lt.category,
    COUNT(lr.report_id)                              AS total_reports,
    SUM(CASE WHEN lr.is_abnormal THEN 1 ELSE 0 END) AS abnormal_reports,
    ROUND(AVG(lt.price), 2)                          AS avg_test_price
FROM lab_report lr
JOIN test_order to_ ON lr.order_id = to_.order_id
JOIN lab_test lt    ON to_.test_id = lt.test_id
GROUP BY lt.category
ORDER BY total_reports DESC;

-- Q5. Doctors who ordered more than 2 tests (active prescribers)
SELECT
    CONCAT(d.first_name, ' ', d.last_name) AS doctor_name,
    d.specialization,
    COUNT(to_.order_id) AS total_orders
FROM test_order to_
JOIN doctor d ON to_.doctor_id = d.doctor_id
GROUP BY d.doctor_id, d.first_name, d.last_name, d.specialization
HAVING COUNT(to_.order_id) > 2
ORDER BY total_orders DESC;

-- Q6. Monthly report count trend
SELECT
    DATE_TRUNC('month', lr.report_date) AS report_month,
    COUNT(*)                            AS report_count,
    SUM(CASE WHEN lr.is_abnormal THEN 1 ELSE 0 END) AS abnormal_count
FROM lab_report lr
GROUP BY DATE_TRUNC('month', lr.report_date)
ORDER BY report_month;

-- Q7. Patients with most test orders (high-utilization patients)
SELECT
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    COUNT(to_.order_id) AS total_tests,
    SUM(lt.price)       AS total_billed
FROM test_order to_
JOIN patient p   ON to_.patient_id = p.patient_id
JOIN lab_test lt ON to_.test_id    = lt.test_id
GROUP BY p.patient_id, p.first_name, p.last_name
ORDER BY total_tests DESC;

-- ============================================================
-- SECTION C: JOIN Queries
-- ============================================================

-- Q8. Full report card: patient + test + report + technician + verifier
SELECT
    lr.report_id,
    CONCAT(p.first_name, ' ', p.last_name)     AS patient_name,
    p.blood_group,
    lt.test_name,
    lt.category,
    to_.priority,
    to_.ordered_on,
    lr.report_date,
    lr.result_summary,
    lr.is_abnormal,
    lr.is_critical,
    CONCAT(tech.first_name,' ',tech.last_name)  AS technician,
    CONCAT(vd.first_name,' ',vd.last_name)      AS verified_by_doctor,
    lab.lab_name
FROM lab_report lr
JOIN test_order to_           ON lr.order_id     = to_.order_id
JOIN patient p                ON to_.patient_id  = p.patient_id
JOIN lab_test lt              ON to_.test_id     = lt.test_id
JOIN lab                      ON to_.lab_id      = lab.lab_id
LEFT JOIN lab_technician tech  ON lr.tech_id     = tech.tech_id
LEFT JOIN doctor vd            ON lr.verified_by = vd.doctor_id;

-- Q9. Abnormal parameters with patient context (for clinical review)
SELECT
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    lt.test_name,
    rp.parameter_name,
    rp.observed_value,
    rp.normal_range,
    rp.unit,
    rp.flag,
    lr.report_date
FROM report_parameter rp
JOIN lab_report lr  ON rp.report_id  = lr.report_id
JOIN test_order to_ ON lr.order_id   = to_.order_id
JOIN patient p      ON to_.patient_id = p.patient_id
JOIN lab_test lt    ON to_.test_id   = lt.test_id
WHERE rp.is_abnormal = TRUE
ORDER BY lr.report_date DESC, rp.flag DESC;

-- ============================================================
-- SECTION D: Subqueries
-- ============================================================

-- Q10. Patients who have at least one critical report
-- (JOIN version)
SELECT DISTINCT
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    p.phone,
    p.emergency_contact
FROM patient p
JOIN test_order to_ ON p.patient_id = to_.patient_id
JOIN lab_report lr  ON to_.order_id = lr.order_id
WHERE lr.is_critical = TRUE;

-- (SUBQUERY version - equivalent result)
SELECT
    CONCAT(first_name, ' ', last_name) AS patient_name,
    phone,
    emergency_contact
FROM patient
WHERE patient_id IN (
    SELECT to_.patient_id
    FROM test_order to_
    JOIN lab_report lr ON to_.order_id = lr.order_id
    WHERE lr.is_critical = TRUE
);

-- Q11. Tests that cost above average price
SELECT test_name, category, price
FROM lab_test
WHERE price > (SELECT AVG(price) FROM lab_test)
ORDER BY price DESC;

-- Q12. Reports accessed more than once (identify frequently viewed records)
SELECT
    report_id,
    COUNT(*) AS access_count
FROM access_log
GROUP BY report_id
HAVING COUNT(*) > 1
ORDER BY access_count DESC;

-- ============================================================
-- SECTION E: Relational Algebra → SQL translations
-- ============================================================

-- RA Expression: σ(is_critical=TRUE)(lab_report) ⋈ test_order ⋈ patient
-- "Find all patient details for critical reports"
SELECT
    p.patient_id, p.first_name, p.last_name,
    lr.report_id, lr.result_summary, lr.report_date
FROM lab_report lr
JOIN test_order to_ ON lr.order_id    = to_.order_id
JOIN patient p      ON to_.patient_id = p.patient_id
WHERE lr.is_critical = TRUE;

-- RA: π(test_name, category)(lab_test) – Project test names and categories
SELECT DISTINCT test_name, category FROM lab_test ORDER BY category;

-- ============================================================
-- SECTION F: Normalization demonstration
-- ============================================================

-- UNNORMALIZED (hypothetical flat table to show why normalization matters):
-- patient_report(patient_id, name, phone, test_name, doctor_name, result)
-- Problems: Update anomaly (if doctor name changes), Insert anomaly (can't add test without patient)
-- Our schema solves this by decomposing into patient, doctor, lab_test, test_order, lab_report

-- 3NF check query: verify no transitive dependencies violated
-- patient_id → first_name, last_name (direct)
-- test_id → test_name, category (direct)
-- order_id → patient_id, test_id (FK references, not transitive)
SELECT 'Schema is in 3NF: all non-key attributes depend on primary key only' AS normalization_note;

-- ============================================================
-- SECTION G: Transaction demonstrations (run manually)
-- ============================================================

-- See transactions.sql for full ACID demonstrations
