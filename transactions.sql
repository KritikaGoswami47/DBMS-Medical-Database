-- ============================================================
-- Doctor Lab Test Reports DB
-- Transactions: ACID Property Demonstrations
-- ============================================================

-- ============================================================
-- TRANSACTION 1: Complete lab test workflow
-- Atomicity: Either the full test result is recorded, or nothing
-- ============================================================
BEGIN;

-- Step 1: Create the lab report
INSERT INTO lab_report (order_id, tech_id, report_date, result_summary, is_abnormal, is_critical)
VALUES (
    (SELECT order_id FROM test_order WHERE patient_id=3 AND test_id=1 LIMIT 1),
    1,
    CURRENT_DATE,
    'WBC: 7.2 K/uL, RBC: 4.8 M/uL – All within normal limits.',
    FALSE, FALSE
);

-- Step 2: Add individual parameters
INSERT INTO report_parameter (report_id, parameter_name, observed_value, normal_range, unit, is_abnormal)
VALUES
    (currval('lab_report_report_id_seq'), 'WBC',        '7.2', '4.0 – 11.0', 'K/uL', FALSE),
    (currval('lab_report_report_id_seq'), 'RBC',        '4.8', '4.5 – 5.9',  'M/uL', FALSE),
    (currval('lab_report_report_id_seq'), 'Hemoglobin', '14.2','13.5 – 17.5','g/dL', FALSE);

-- Step 3: Log access
INSERT INTO access_log (report_id, accessed_by_role, accessed_by_id, access_type, ip_address)
VALUES (currval('lab_report_report_id_seq'), 'Technician', 1, 'Edit', '192.168.1.20');

COMMIT;
-- If any step fails, entire transaction rolls back (Atomicity)

-- ============================================================
-- TRANSACTION 2: Doctor verifies and releases report
-- Isolation: Concurrent reads won't see partial state
-- ============================================================
BEGIN;

-- Verify the report (doctor approval)
UPDATE lab_report
SET is_verified = TRUE,
    verified_by = 1,           -- Dr. Rajesh Kumar (Pathologist)
    verified_at = NOW()
WHERE report_id = 1;

-- Release to patient (only after verification – trigger enforces this)
UPDATE lab_report
SET is_released = TRUE,
    released_at = NOW()
WHERE report_id = 1;

-- Log the doctor's access
INSERT INTO access_log (report_id, accessed_by_role, accessed_by_id, access_type, ip_address)
VALUES (1, 'Doctor', 1, 'Edit', '192.168.1.10');

COMMIT;

-- ============================================================
-- TRANSACTION 3: ROLLBACK demonstration
-- Consistency: Invalid data is never committed
-- ============================================================
BEGIN;

-- Attempt to release an unverified report (will be caught by trigger)
-- Trigger fn_enforce_release_policy will RAISE EXCEPTION
UPDATE lab_report
SET is_released = TRUE
WHERE report_id = (SELECT report_id FROM lab_report WHERE is_verified = FALSE LIMIT 1);

-- If trigger raises exception, this ROLLBACK executes
ROLLBACK;
-- Result: Database remains in consistent state

-- ============================================================
-- TRANSACTION 4: Concurrency scenario (Dirty Read prevention)
-- Two technicians shouldn't update same order simultaneously
-- ============================================================

-- Session A: Technician begins entering results
BEGIN;
UPDATE test_order SET status = 'Processing' WHERE order_id = 3;
-- (Session B trying to read order_id=3 gets OLD value due to Isolation)
-- ...processing...
UPDATE test_order SET status = 'Completed' WHERE order_id = 3;
COMMIT;
-- Session B now sees the committed 'Completed' state (no dirty read)

-- ============================================================
-- SAVEPOINT demonstration (Partial rollback)
-- ============================================================
BEGIN;

INSERT INTO access_log (report_id, accessed_by_role, accessed_by_id, access_type, ip_address)
VALUES (5, 'Doctor', 2, 'View', '192.168.1.11');

SAVEPOINT after_access_log;

-- Try a risky operation
UPDATE lab_report SET is_critical = TRUE WHERE report_id = 5;

-- Decide to undo just the update, keep the access log entry
ROLLBACK TO SAVEPOINT after_access_log;

COMMIT; -- Access log insert is committed, update is not
