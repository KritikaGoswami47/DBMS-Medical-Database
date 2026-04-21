-- ============================================================
-- Doctor Lab Test Reports DB
-- Triggers: Audit + Privacy Enforcement + Business Rules
-- ============================================================

-- ============================================================
-- TRIGGER 1: Audit log for lab_report changes
-- Captures who changed what for HIPAA-style compliance
-- ============================================================
CREATE OR REPLACE FUNCTION fn_audit_lab_report()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        INSERT INTO audit_log (table_name, record_id, action, old_values, new_values, changed_by, changed_at)
        VALUES (
            'lab_report',
            OLD.report_id,
            'UPDATE',
            to_jsonb(OLD),
            to_jsonb(NEW),
            current_user,
            NOW()
        );
    ELSIF TG_OP = 'INSERT' THEN
        INSERT INTO audit_log (table_name, record_id, action, new_values, changed_by, changed_at)
        VALUES (
            'lab_report',
            NEW.report_id,
            'INSERT',
            to_jsonb(NEW),
            current_user,
            NOW()
        );
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO audit_log (table_name, record_id, action, old_values, changed_by, changed_at)
        VALUES (
            'lab_report',
            OLD.report_id,
            'DELETE',
            to_jsonb(OLD),
            current_user,
            NOW()
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_audit_lab_report
AFTER INSERT OR UPDATE OR DELETE ON lab_report
FOR EACH ROW EXECUTE FUNCTION fn_audit_lab_report();

-- ============================================================
-- TRIGGER 2: Auto-stamp verified_at when is_verified = TRUE
-- ============================================================
CREATE OR REPLACE FUNCTION fn_stamp_verification()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_verified = TRUE AND OLD.is_verified = FALSE THEN
        NEW.verified_at := NOW();
    END IF;
    IF NEW.is_released = TRUE AND OLD.is_released = FALSE THEN
        NEW.released_at := NOW();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_stamp_verification
BEFORE UPDATE ON lab_report
FOR EACH ROW EXECUTE FUNCTION fn_stamp_verification();

-- ============================================================
-- TRIGGER 3: Prevent releasing unverified reports
-- Privacy constraint: A report cannot be released to patient
-- unless it has been verified by a doctor first
-- ============================================================
CREATE OR REPLACE FUNCTION fn_enforce_release_policy()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_released = TRUE AND NEW.is_verified = FALSE THEN
        RAISE EXCEPTION 'POLICY VIOLATION: Cannot release report % to patient before doctor verification.', NEW.report_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_enforce_release_policy
BEFORE UPDATE ON lab_report
FOR EACH ROW EXECUTE FUNCTION fn_enforce_release_policy();

-- ============================================================
-- TRIGGER 4: Auto-update test_order status when report is created
-- ============================================================
CREATE OR REPLACE FUNCTION fn_sync_order_status()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE test_order
        SET status = 'Completed'
        WHERE order_id = NEW.order_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sync_order_status
AFTER INSERT ON lab_report
FOR EACH ROW EXECUTE FUNCTION fn_sync_order_status();

-- ============================================================
-- TRIGGER 5: Mark report as abnormal if any parameter is abnormal
-- ============================================================
CREATE OR REPLACE FUNCTION fn_propagate_abnormal()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_abnormal = TRUE THEN
        UPDATE lab_report
        SET is_abnormal = TRUE
        WHERE report_id = NEW.report_id AND is_abnormal = FALSE;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_propagate_abnormal
AFTER INSERT OR UPDATE ON report_parameter
FOR EACH ROW EXECUTE FUNCTION fn_propagate_abnormal();

-- ============================================================
-- TRIGGER 6: Audit test_order status changes
-- ============================================================
CREATE OR REPLACE FUNCTION fn_audit_test_order()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        INSERT INTO audit_log (table_name, record_id, action, old_values, new_values, changed_by)
        VALUES (
            'test_order',
            NEW.order_id,
            'UPDATE',
            jsonb_build_object('status', OLD.status),
            jsonb_build_object('status', NEW.status),
            current_user
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_audit_test_order
AFTER UPDATE ON test_order
FOR EACH ROW EXECUTE FUNCTION fn_audit_test_order();
