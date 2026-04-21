-- ============================================================
-- Doctor Lab Test Reports DB
-- Indexing Strategy: Performance Optimization
-- ============================================================

-- ============================================================
-- RATIONALE: Index selection based on query patterns
-- ============================================================

-- FREQUENTLY SEARCHED: patient_id in test_order
-- Many queries filter by patient; B+ Tree index optimal for equality + range
CREATE INDEX IF NOT EXISTS idx_test_order_patient_id
    ON test_order(patient_id);
COMMENT ON INDEX idx_test_order_patient_id IS 'Supports patient history queries; B+ Tree allows range scans on ordered_on too';

-- FREQUENTLY SEARCHED: is_critical and is_abnormal flags
-- Partial index (only indexes TRUE rows) → small, fast for alert queries
CREATE INDEX IF NOT EXISTS idx_lab_report_critical
    ON lab_report(report_id)
    WHERE is_critical = TRUE;

CREATE INDEX IF NOT EXISTS idx_lab_report_abnormal
    ON lab_report(report_id)
    WHERE is_abnormal = TRUE;

-- FREQUENTLY SEARCHED: unreleased reports (pending queue)
CREATE INDEX IF NOT EXISTS idx_lab_report_unreleased
    ON lab_report(report_date)
    WHERE is_released = FALSE;

-- FREQUENTLY SEARCHED: test_order by status (workload queries)
CREATE INDEX IF NOT EXISTS idx_test_order_status
    ON test_order(status);

-- FREQUENTLY SEARCHED: lab_report by date range
CREATE INDEX IF NOT EXISTS idx_lab_report_date
    ON lab_report(report_date DESC);

-- FREQUENTLY SEARCHED: patient name lookup
CREATE INDEX IF NOT EXISTS idx_patient_name
    ON patient(last_name VARCHAR_PATTERN_OPS, first_name VARCHAR_PATTERN_OPS);

-- FREQUENTLY SEARCHED: access_log by report_id (audit queries)
CREATE INDEX IF NOT EXISTS idx_access_log_report_id
    ON access_log(report_id, accessed_at DESC);

-- FREQUENTLY SEARCHED: doctor lookup by specialization
CREATE INDEX IF NOT EXISTS idx_doctor_specialization
    ON doctor(specialization);

-- COMPOSITE INDEX: test_order(patient_id, test_id) for patient test history joins
CREATE INDEX IF NOT EXISTS idx_test_order_patient_test
    ON test_order(patient_id, test_id);

-- ============================================================
-- INDEX ANALYSIS NOTES (for assignment write-up)
-- ============================================================
-- Q: Why B+ Tree over B-Tree?
-- A: B+ Tree stores all data in leaf nodes and links them → range queries on
--    report_date or ordered_on are O(log n) + sequential scan on leaves.
--    B-Tree stores data at internal nodes too → no linked leaves → range
--    queries require backtracking. For a date-range-heavy query like
--    "reports between Jan 1 and Jan 31", B+ Tree is strictly superior.
--
-- Q: Why partial indexes on is_critical/is_abnormal?
-- A: Critical reports are rare (~5-10%). A partial index only covers
--    those rows → tiny index → fits in cache → sub-millisecond lookup.
--    A full index on a BOOLEAN column in a large table is wasteful.
--
-- Q: What if we over-index?
-- A: Every INSERT/UPDATE/DELETE must update all indexes. If we index every
--    column, write performance degrades severely. For a lab system with
--    frequent inserts (new reports daily), this is unacceptable.
--    We index only frequently filtered columns.
