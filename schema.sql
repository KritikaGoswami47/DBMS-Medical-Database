-- ============================================================
-- Doctor Lab Test Reports DB
-- Schema: Table Definitions + Constraints
-- Domain Focus: Privacy + Schema Standardization
-- Subject: DBMS CIC-210 | MAIT Delhi
-- ============================================================

-- Drop existing tables (in reverse dependency order)
DROP TABLE IF EXISTS audit_log CASCADE;
DROP TABLE IF EXISTS access_log CASCADE;
DROP TABLE IF EXISTS report_parameter CASCADE;
DROP TABLE IF EXISTS lab_report CASCADE;
DROP TABLE IF EXISTS test_order CASCADE;
DROP TABLE IF EXISTS lab_test CASCADE;
DROP TABLE IF EXISTS lab_technician CASCADE;
DROP TABLE IF EXISTS lab CASCADE;
DROP TABLE IF EXISTS prescription CASCADE;
DROP TABLE IF EXISTS appointment CASCADE;
DROP TABLE IF EXISTS doctor CASCADE;
DROP TABLE IF EXISTS department CASCADE;
DROP TABLE IF EXISTS patient CASCADE;

-- ============================================================
-- PATIENT
-- ============================================================
CREATE TABLE patient (
    patient_id      SERIAL PRIMARY KEY,
    first_name      VARCHAR(50)  NOT NULL,
    last_name       VARCHAR(50)  NOT NULL,
    date_of_birth   DATE         NOT NULL,
    gender          CHAR(1)      NOT NULL CHECK (gender IN ('M', 'F', 'O')),
    phone           VARCHAR(15)  UNIQUE NOT NULL,
    email           VARCHAR(100) UNIQUE,
    blood_group     VARCHAR(5)   CHECK (blood_group IN ('A+','A-','B+','B-','AB+','AB-','O+','O-')),
    address         TEXT,
    emergency_contact VARCHAR(15),
    is_active       BOOLEAN      DEFAULT TRUE,
    created_at      TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_patient_phone CHECK (phone ~ '^[0-9]{10,15}$')
);

COMMENT ON TABLE patient IS 'Stores patient personal info with privacy constraints';
COMMENT ON COLUMN patient.phone IS 'Encrypted at application level; stored as hash for lookup';

-- ============================================================
-- DEPARTMENT
-- ============================================================
CREATE TABLE department (
    dept_id     SERIAL PRIMARY KEY,
    dept_name   VARCHAR(100) NOT NULL UNIQUE,
    head_doctor_id INT,               -- FK added after doctor table
    location    VARCHAR(50),
    contact_ext VARCHAR(10)
);

-- ============================================================
-- DOCTOR
-- ============================================================
CREATE TABLE doctor (
    doctor_id       SERIAL PRIMARY KEY,
    first_name      VARCHAR(50)  NOT NULL,
    last_name       VARCHAR(50)  NOT NULL,
    specialization  VARCHAR(100) NOT NULL,
    license_number  VARCHAR(30)  UNIQUE NOT NULL,
    dept_id         INT          REFERENCES department(dept_id) ON DELETE SET NULL,
    phone           VARCHAR(15)  NOT NULL,
    email           VARCHAR(100) UNIQUE NOT NULL,
    is_active       BOOLEAN      DEFAULT TRUE,
    created_at      TIMESTAMP    DEFAULT CURRENT_TIMESTAMP
);

-- Now add the FK from department to doctor
ALTER TABLE department
    ADD CONSTRAINT fk_head_doctor
    FOREIGN KEY (head_doctor_id) REFERENCES doctor(doctor_id) ON DELETE SET NULL;

-- ============================================================
-- APPOINTMENT
-- ============================================================
CREATE TABLE appointment (
    appointment_id  SERIAL PRIMARY KEY,
    patient_id      INT NOT NULL REFERENCES patient(patient_id) ON DELETE CASCADE,
    doctor_id       INT NOT NULL REFERENCES doctor(doctor_id) ON DELETE RESTRICT,
    appointment_date DATE        NOT NULL,
    appointment_time TIME        NOT NULL,
    status          VARCHAR(20)  NOT NULL DEFAULT 'Scheduled'
                    CHECK (status IN ('Scheduled','Completed','Cancelled','No-Show')),
    reason          TEXT,
    notes           TEXT,
    created_at      TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_appointment UNIQUE (doctor_id, appointment_date, appointment_time)
);

-- ============================================================
-- PRESCRIPTION
-- ============================================================
CREATE TABLE prescription (
    prescription_id SERIAL PRIMARY KEY,
    appointment_id  INT NOT NULL REFERENCES appointment(appointment_id) ON DELETE CASCADE,
    doctor_id       INT NOT NULL REFERENCES doctor(doctor_id),
    patient_id      INT NOT NULL REFERENCES patient(patient_id),
    prescribed_on   DATE NOT NULL DEFAULT CURRENT_DATE,
    diagnosis       TEXT NOT NULL,
    notes           TEXT
);

-- ============================================================
-- LAB
-- ============================================================
CREATE TABLE lab (
    lab_id          SERIAL PRIMARY KEY,
    lab_name        VARCHAR(100) NOT NULL UNIQUE,
    location        VARCHAR(100) NOT NULL,
    accreditation   VARCHAR(50),
    contact_phone   VARCHAR(15),
    is_active       BOOLEAN DEFAULT TRUE
);

-- ============================================================
-- LAB TECHNICIAN
-- ============================================================
CREATE TABLE lab_technician (
    tech_id         SERIAL PRIMARY KEY,
    first_name      VARCHAR(50)  NOT NULL,
    last_name       VARCHAR(50)  NOT NULL,
    lab_id          INT          NOT NULL REFERENCES lab(lab_id) ON DELETE RESTRICT,
    qualification   VARCHAR(100),
    license_number  VARCHAR(30)  UNIQUE,
    phone           VARCHAR(15)  NOT NULL,
    email           VARCHAR(100) UNIQUE,
    is_active       BOOLEAN      DEFAULT TRUE
);

-- ============================================================
-- LAB TEST (Master catalog of available tests)
-- ============================================================
CREATE TABLE lab_test (
    test_id         SERIAL PRIMARY KEY,
    test_name       VARCHAR(150) NOT NULL UNIQUE,
    test_code       VARCHAR(20)  NOT NULL UNIQUE,
    category        VARCHAR(50)  NOT NULL
                    CHECK (category IN (
                        'Hematology','Biochemistry','Microbiology',
                        'Radiology','Pathology','Immunology','Serology','Urine','Other'
                    )),
    sample_type     VARCHAR(50)  NOT NULL,   -- Blood, Urine, Tissue, etc.
    normal_range    TEXT,                    -- e.g. "70-100 mg/dL"
    unit            VARCHAR(20),             -- e.g. "mg/dL"
    turnaround_hours INT DEFAULT 24 CHECK (turnaround_hours > 0),
    price           NUMERIC(10,2) NOT NULL CHECK (price >= 0),
    description     TEXT
);

-- ============================================================
-- TEST ORDER (Doctor orders test for patient)
-- ============================================================
CREATE TABLE test_order (
    order_id        SERIAL PRIMARY KEY,
    prescription_id INT REFERENCES prescription(prescription_id) ON DELETE SET NULL,
    patient_id      INT NOT NULL REFERENCES patient(patient_id) ON DELETE CASCADE,
    doctor_id       INT NOT NULL REFERENCES doctor(doctor_id),
    lab_id          INT NOT NULL REFERENCES lab(lab_id),
    test_id         INT NOT NULL REFERENCES lab_test(test_id),
    ordered_on      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    priority        VARCHAR(10)  NOT NULL DEFAULT 'Normal'
                    CHECK (priority IN ('Normal','Urgent','STAT')),
    status          VARCHAR(20)  NOT NULL DEFAULT 'Ordered'
                    CHECK (status IN ('Ordered','Sample Collected','Processing','Completed','Cancelled')),
    collection_time TIMESTAMP,
    notes           TEXT
);

-- ============================================================
-- LAB REPORT (The actual result document)
-- ============================================================
CREATE TABLE lab_report (
    report_id       SERIAL PRIMARY KEY,
    order_id        INT          NOT NULL UNIQUE REFERENCES test_order(order_id) ON DELETE CASCADE,
    tech_id         INT          REFERENCES lab_technician(tech_id) ON DELETE SET NULL,
    verified_by     INT          REFERENCES doctor(doctor_id) ON DELETE SET NULL,
    report_date     DATE         NOT NULL DEFAULT CURRENT_DATE,
    result_summary  TEXT         NOT NULL,
    is_abnormal     BOOLEAN      DEFAULT FALSE,
    is_critical     BOOLEAN      DEFAULT FALSE,
    is_verified     BOOLEAN      DEFAULT FALSE,
    verified_at     TIMESTAMP,
    report_pdf_path TEXT,                       -- path to stored PDF
    is_released     BOOLEAN      DEFAULT FALSE, -- visible to patient only after release
    released_at     TIMESTAMP,
    remarks         TEXT,
    created_at      TIMESTAMP    DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON COLUMN lab_report.is_released IS 'Privacy control: patient cannot view until doctor releases';
COMMENT ON COLUMN lab_report.report_pdf_path IS 'Encrypted file path; access controlled by role';

-- ============================================================
-- REPORT PARAMETER (individual test result values)
-- ============================================================
CREATE TABLE report_parameter (
    param_id        SERIAL PRIMARY KEY,
    report_id       INT          NOT NULL REFERENCES lab_report(report_id) ON DELETE CASCADE,
    parameter_name  VARCHAR(100) NOT NULL,
    observed_value  VARCHAR(50)  NOT NULL,
    normal_range    VARCHAR(50),
    unit            VARCHAR(20),
    is_abnormal     BOOLEAN      DEFAULT FALSE,
    flag            VARCHAR(10)  CHECK (flag IN ('H','L','HH','LL','N', NULL)),
    CONSTRAINT uq_param_per_report UNIQUE (report_id, parameter_name)
);

-- ============================================================
-- ACCESS LOG (Who accessed which report - Privacy critical)
-- ============================================================
CREATE TABLE access_log (
    log_id          SERIAL PRIMARY KEY,
    report_id       INT          NOT NULL REFERENCES lab_report(report_id),
    accessed_by_role VARCHAR(20) NOT NULL CHECK (accessed_by_role IN ('Doctor','Technician','Patient','Admin')),
    accessed_by_id  INT          NOT NULL,
    accessed_at     TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    access_type     VARCHAR(20)  NOT NULL CHECK (access_type IN ('View','Download','Print','Edit')),
    ip_address      VARCHAR(45)
);

COMMENT ON TABLE access_log IS 'Immutable audit trail of all report accesses for HIPAA-style compliance';

-- ============================================================
-- AUDIT LOG (Schema changes / status changes)
-- ============================================================
CREATE TABLE audit_log (
    audit_id        SERIAL PRIMARY KEY,
    table_name      VARCHAR(50)  NOT NULL,
    record_id       INT          NOT NULL,
    action          VARCHAR(10)  NOT NULL CHECK (action IN ('INSERT','UPDATE','DELETE')),
    old_values      JSONB,
    new_values      JSONB,
    changed_by      VARCHAR(100),
    changed_at      TIMESTAMP    DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE audit_log IS 'Trigger-populated audit trail for data integrity and forensic tracing';

-- ============================================================
-- INDEXES for performance
-- ============================================================
CREATE INDEX idx_test_order_patient  ON test_order(patient_id);
CREATE INDEX idx_test_order_doctor   ON test_order(doctor_id);
CREATE INDEX idx_test_order_status   ON test_order(status);
CREATE INDEX idx_lab_report_date     ON lab_report(report_date);
CREATE INDEX idx_lab_report_abnormal ON lab_report(is_abnormal) WHERE is_abnormal = TRUE;
CREATE INDEX idx_access_log_report   ON access_log(report_id);
CREATE INDEX idx_audit_table_record  ON audit_log(table_name, record_id);
CREATE INDEX idx_patient_name        ON patient(last_name, first_name);
CREATE INDEX idx_appointment_date    ON appointment(appointment_date);
