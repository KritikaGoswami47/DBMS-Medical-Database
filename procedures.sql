-- ============================================================
-- Doctor Lab Test Reports DB
-- Stored Procedures & Functions
-- ============================================================

-- ============================================================
-- FUNCTION 1: Get full patient report history
-- ============================================================
CREATE OR REPLACE FUNCTION fn_patient_report_history(p_patient_id INT)
RETURNS TABLE (
    report_id       INT,
    test_name       VARCHAR,
    category        VARCHAR,
    report_date     DATE,
    result_summary  TEXT,
    is_abnormal     BOOLEAN,
    is_critical     BOOLEAN,
    is_released     BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        lr.report_id,
        lt.test_name,
        lt.category,
        lr.report_date,
        lr.result_summary,
        lr.is_abnormal,
        lr.is_critical,
        lr.is_released
    FROM lab_report lr
    JOIN test_order to_ ON lr.order_id    = to_.order_id
    JOIN lab_test lt    ON to_.test_id    = lt.test_id
    WHERE to_.patient_id = p_patient_id
    ORDER BY lr.report_date DESC;
END;
$$ LANGUAGE plpgsql;

-- Usage: SELECT * FROM fn_patient_report_history(1);

-- ============================================================
-- PROCEDURE 2: Create complete test order (with validation)
-- ============================================================
CREATE OR REPLACE PROCEDURE sp_create_test_order(
    p_patient_id     INT,
    p_doctor_id      INT,
    p_lab_id         INT,
    p_test_id        INT,
    p_priority       VARCHAR DEFAULT 'Normal',
    p_prescription_id INT DEFAULT NULL
) AS $$
DECLARE
    v_patient_active  BOOLEAN;
    v_doctor_active   BOOLEAN;
    v_lab_active      BOOLEAN;
BEGIN
    -- Validate patient exists and is active
    SELECT is_active INTO v_patient_active FROM patient WHERE patient_id = p_patient_id;
    IF v_patient_active IS NULL OR v_patient_active = FALSE THEN
        RAISE EXCEPTION 'Patient % not found or inactive.', p_patient_id;
    END IF;

    -- Validate doctor
    SELECT is_active INTO v_doctor_active FROM doctor WHERE doctor_id = p_doctor_id;
    IF v_doctor_active IS NULL OR v_doctor_active = FALSE THEN
        RAISE EXCEPTION 'Doctor % not found or inactive.', p_doctor_id;
    END IF;

    -- Validate lab
    SELECT is_active INTO v_lab_active FROM lab WHERE lab_id = p_lab_id;
    IF v_lab_active IS NULL OR v_lab_active = FALSE THEN
        RAISE EXCEPTION 'Lab % not found or inactive.', p_lab_id;
    END IF;

    -- Insert the order
    INSERT INTO test_order (patient_id, doctor_id, lab_id, test_id, priority, prescription_id, ordered_on)
    VALUES (p_patient_id, p_doctor_id, p_lab_id, p_test_id, p_priority, p_prescription_id, NOW());

    RAISE NOTICE 'Test order created successfully for patient % with priority %.', p_patient_id, p_priority;
END;
$$ LANGUAGE plpgsql;

-- Usage: CALL sp_create_test_order(1, 5, 1, 3, 'Urgent');

-- ============================================================
-- PROCEDURE 3: Verify and release report atomically
-- ============================================================
CREATE OR REPLACE PROCEDURE sp_verify_and_release_report(
    p_report_id     INT,
    p_verifier_id   INT
) AS $$
DECLARE
    v_is_verified BOOLEAN;
BEGIN
    -- Check current state
    SELECT is_verified INTO v_is_verified FROM lab_report WHERE report_id = p_report_id;

    IF v_is_verified IS NULL THEN
        RAISE EXCEPTION 'Report % does not exist.', p_report_id;
    END IF;

    -- Verify first
    UPDATE lab_report
    SET is_verified = TRUE,
        verified_by = p_verifier_id,
        verified_at = NOW()
    WHERE report_id = p_report_id;

    -- Then release (trigger will prevent release if not verified)
    UPDATE lab_report
    SET is_released = TRUE,
        released_at = NOW()
    WHERE report_id = p_report_id;

    -- Log the action
    INSERT INTO access_log (report_id, accessed_by_role, accessed_by_id, access_type)
    VALUES (p_report_id, 'Doctor', p_verifier_id, 'Edit');

    RAISE NOTICE 'Report % has been verified by doctor % and released to patient.', p_report_id, p_verifier_id;
END;
$$ LANGUAGE plpgsql;

-- Usage: CALL sp_verify_and_release_report(3, 1);

-- ============================================================
-- FUNCTION 4: Abnormality rate per doctor (quality metric)
-- ============================================================
CREATE OR REPLACE FUNCTION fn_doctor_abnormality_rate()
RETURNS TABLE (
    doctor_name     TEXT,
    specialization  VARCHAR,
    total_reports   BIGINT,
    abnormal_count  BIGINT,
    abnormal_rate   NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        CONCAT(d.first_name, ' ', d.last_name)::TEXT AS doctor_name,
        d.specialization,
        COUNT(lr.report_id)                          AS total_reports,
        SUM(CASE WHEN lr.is_abnormal THEN 1 ELSE 0 END) AS abnormal_count,
        ROUND(
            100.0 * SUM(CASE WHEN lr.is_abnormal THEN 1 ELSE 0 END)
            / NULLIF(COUNT(lr.report_id), 0), 2
        )                                            AS abnormal_rate
    FROM doctor d
    JOIN test_order to_ ON d.doctor_id  = to_.doctor_id
    JOIN lab_report lr  ON to_.order_id = lr.order_id
    GROUP BY d.doctor_id, d.first_name, d.last_name, d.specialization
    ORDER BY abnormal_rate DESC;
END;
$$ LANGUAGE plpgsql;

-- Usage: SELECT * FROM fn_doctor_abnormality_rate();
