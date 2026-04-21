-- ============================================================
-- Doctor Lab Test Reports DB
-- Views: Logical abstraction for reporting and role-based access
-- ============================================================

-- ============================================================
-- VIEW 1: Patient report summary (safe public-facing view)
-- Excludes internal metadata and PDF paths (privacy)
-- ============================================================
CREATE OR REPLACE VIEW vw_patient_report_summary AS
SELECT
    lr.report_id,
    p.patient_id,
    CONCAT(p.first_name, ' ', p.last_name)  AS patient_name,
    p.blood_group,
    lt.test_name,
    lt.test_code,
    lt.category                              AS test_category,
    CONCAT(d.first_name, ' ', d.last_name)  AS ordered_by_doctor,
    d.specialization,
    lab.lab_name,
    to_.ordered_on,
    to_.priority,
    lr.report_date,
    lr.result_summary,
    lr.is_abnormal,
    lr.is_critical,
    lr.is_verified,
    lr.is_released,
    lr.remarks
FROM lab_report lr
JOIN test_order to_     ON lr.order_id     = to_.order_id
JOIN patient p          ON to_.patient_id  = p.patient_id
JOIN lab_test lt        ON to_.test_id     = lt.test_id
JOIN doctor d           ON to_.doctor_id   = d.doctor_id
JOIN lab lab            ON to_.lab_id      = lab.lab_id
WHERE lr.is_released = TRUE;   -- patients only see released reports

COMMENT ON VIEW vw_patient_report_summary IS 'Privacy-safe view for patient portal: excludes unverified/unreleased reports';

-- ============================================================
-- VIEW 2: Doctor dashboard – all reports (including unreleased)
-- ============================================================
CREATE OR REPLACE VIEW vw_doctor_report_dashboard AS
SELECT
    lr.report_id,
    CONCAT(p.first_name, ' ', p.last_name)  AS patient_name,
    p.patient_id,
    lt.test_name,
    lt.category,
    to_.priority,
    to_.ordered_on,
    lr.report_date,
    lr.result_summary,
    lr.is_abnormal,
    lr.is_critical,
    lr.is_verified,
    lr.is_released,
    CONCAT(tech.first_name, ' ', tech.last_name) AS technician,
    lr.remarks
FROM lab_report lr
JOIN test_order to_          ON lr.order_id   = to_.order_id
JOIN patient p               ON to_.patient_id = p.patient_id
JOIN lab_test lt             ON to_.test_id    = lt.test_id
LEFT JOIN lab_technician tech ON lr.tech_id    = tech.tech_id;

-- ============================================================
-- VIEW 3: Critical & abnormal reports (alert dashboard)
-- ============================================================
CREATE OR REPLACE VIEW vw_critical_alerts AS
SELECT
    lr.report_id,
    CONCAT(p.first_name, ' ', p.last_name)  AS patient_name,
    p.emergency_contact,
    lt.test_name,
    to_.priority,
    lr.report_date,
    lr.result_summary,
    lr.is_critical,
    lr.is_abnormal,
    CONCAT(d.first_name, ' ', d.last_name)  AS ordering_doctor,
    d.email                                 AS doctor_email
FROM lab_report lr
JOIN test_order to_  ON lr.order_id    = to_.order_id
JOIN patient p       ON to_.patient_id = p.patient_id
JOIN lab_test lt     ON to_.test_id    = lt.test_id
JOIN doctor d        ON to_.doctor_id  = d.doctor_id
WHERE lr.is_critical = TRUE OR lr.is_abnormal = TRUE
ORDER BY lr.is_critical DESC, lr.report_date DESC;

-- ============================================================
-- VIEW 4: Lab workload summary
-- ============================================================
CREATE OR REPLACE VIEW vw_lab_workload AS
SELECT
    lab.lab_id,
    lab.lab_name,
    COUNT(to_.order_id)                                  AS total_orders,
    SUM(CASE WHEN to_.status = 'Completed'  THEN 1 ELSE 0 END) AS completed,
    SUM(CASE WHEN to_.status = 'Processing' THEN 1 ELSE 0 END) AS in_process,
    SUM(CASE WHEN to_.status = 'Ordered'    THEN 1 ELSE 0 END) AS pending,
    SUM(CASE WHEN to_.priority = 'STAT'     THEN 1 ELSE 0 END) AS stat_orders
FROM lab
LEFT JOIN test_order to_ ON lab.lab_id = to_.lab_id
GROUP BY lab.lab_id, lab.lab_name;

-- ============================================================
-- VIEW 5: Test frequency analysis (management analytics)
-- ============================================================
CREATE OR REPLACE VIEW vw_test_frequency AS
SELECT
    lt.test_name,
    lt.category,
    lt.price,
    COUNT(to_.order_id)                              AS times_ordered,
    SUM(CASE WHEN lr.is_abnormal THEN 1 ELSE 0 END) AS abnormal_count,
    ROUND(
        100.0 * SUM(CASE WHEN lr.is_abnormal THEN 1 ELSE 0 END)
        / NULLIF(COUNT(lr.report_id), 0), 2
    )                                                AS abnormal_rate_pct
FROM lab_test lt
LEFT JOIN test_order to_  ON lt.test_id     = to_.test_id
LEFT JOIN lab_report lr   ON to_.order_id   = lr.order_id
GROUP BY lt.test_id, lt.test_name, lt.category, lt.price
ORDER BY times_ordered DESC;

-- ============================================================
-- VIEW 6: Pending verification queue (for pathologist)
-- ============================================================
CREATE OR REPLACE VIEW vw_pending_verification AS
SELECT
    lr.report_id,
    CONCAT(p.first_name, ' ', p.last_name)  AS patient_name,
    lt.test_name,
    to_.priority,
    to_.ordered_on,
    lr.report_date,
    lr.result_summary,
    CONCAT(tech.first_name, ' ', tech.last_name) AS prepared_by
FROM lab_report lr
JOIN test_order to_           ON lr.order_id   = to_.order_id
JOIN patient p                ON to_.patient_id = p.patient_id
JOIN lab_test lt              ON to_.test_id    = lt.test_id
LEFT JOIN lab_technician tech  ON lr.tech_id    = tech.tech_id
WHERE lr.is_verified = FALSE
ORDER BY to_.priority DESC, lr.report_date ASC;
