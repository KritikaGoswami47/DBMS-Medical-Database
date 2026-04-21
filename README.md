# DBMS-Medical-Database
# Doctor Lab Test Reports DB

### PostgreSQL · Web Dashboard · Privacy-First Design · DBMS CIC-210 | MAIT Delhi

---

## Overview

This project implements a **complete Doctor Lab Test Reports Database System** with a fully functional web dashboard. It models a real-world diagnostic lab pipeline covering the full lifecycle of a lab report — from doctor prescription to patient delivery — with a strong focus on **privacy, schema standardization, and data integrity**.

> **Domain Assignment:** Doctor Lab Test Reports DB  
> **Focus Variation:** Privacy + Schema Standardization  
> **Subject:** Database Management System (CIC-210) | Semester 4 | MAIT Delhi  
> **Faculty:** Dr. Shallu Bashambu, Dr. Vasudha Bahl, Ajay Kumar Kaushik

---

## What Makes This Project Stand Out

Most DBMS projects stop at tables and basic queries. This system goes further:

**Privacy-enforced architecture** — reports are hidden until doctor-verified and released  
**Trigger-based audit system** — every data change and access is logged immutably  
**HIPAA-style access log** — role + timestamp + IP for every report access  
**Full normalization** through BCNF with documented rationale  
**Stored procedures** for business-critical operations  
**Interactive web dashboard** with filterable reports and critical alert views  
**ACID transaction demonstrations** with savepoints and rollback scenarios  
**B+ Tree indexing strategy** with analytical justification  

---

## System Architecture

```
Doctor Prescription
        ↓
   Test Order (+ Priority: Normal / Urgent / STAT)
        ↓
   Lab Technician Processes Sample
        ↓
   Lab Report Created (Unreleased)
        ↓
   Doctor Verifies Report ── Trigger: stamp verified_at
        ↓
   Doctor Releases to Patient ── Trigger: enforce verification first
        ↓
   Patient Accesses Report ── Access Log Entry Auto-created
        ↓
   Audit Log captures all changes (JSONB diffs)
```

---

## Core Tables (9 Relations)

| Table | Description | Key Constraint |
|---|---|---|
| `patient` | Patient personal info | phone UNIQUE, blood_group CHECK |
| `doctor` | Doctor profiles | license_number UNIQUE |
| `department` | Hospital departments | head_doctor FK |
| `lab_test` | Master catalog of tests | category CHECK enum |
| `lab` | Lab facility info | NABL accreditation |
| `lab_technician` | Technician registry | license UNIQUE |
| `test_order` | Doctor orders test for patient | priority CHECK: Normal/Urgent/STAT |
| `lab_report` | Actual result document | **is_released only after is_verified** |
| `report_parameter` | Individual result values | flag CHECK: H/L/HH/LL/N |
| `access_log` | Immutable access audit trail | role CHECK enum |
| `audit_log` | Schema-level JSONB change log | trigger-populated |

---

## Tech Stack

| Component | Technology |
|---|---|
| Database | PostgreSQL (v14+) |
| Interface | pgAdmin 4 / psql |
| Language | SQL + PL/pgSQL |
| Web Frontend | HTML5, CSS3, Vanilla JS |
| Fonts | IBM Plex Mono, Fraunces, Inter |

---

## Project Structure

```
doctor_lab_reports/
│
├── sql/
│   ├── schema.sql          # All 11 table definitions + constraints + indexes
│   ├── data.sql            # Realistic sample dataset (10 patients, 13 reports)
│   ├── triggers.sql        # 6 triggers: audit, privacy, sync, propagation
│   ├── views.sql           # 6 views: patient portal, doctor dashboard, alerts
│   ├── procedures.sql      # Stored functions + procedures with validation
│   ├── queries.sql         # 12+ analytical queries with RA translations
│   ├── transactions.sql    # ACID demonstrations with savepoints
│   └── indexes.sql         # B+ Tree strategy with analytical justification
│
├── web/
│   ├── index.html          # Main dashboard (8 views, fully navigable)
│   ├── css/style.css       # Dark theme medical UI
│   └── js/app.js           # Navigation, filter, search logic
│
└── README.md
```

---

## How to Run

### Database Setup

```bash
# 1. Create the database
psql -U postgres -c "CREATE DATABASE doctor_lab_db;"

# 2. Execute SQL files IN ORDER
psql -U postgres -d doctor_lab_db -f sql/schema.sql
psql -U postgres -d doctor_lab_db -f sql/data.sql
psql -U postgres -d doctor_lab_db -f sql/triggers.sql
psql -U postgres -d doctor_lab_db -f sql/views.sql
psql -U postgres -d doctor_lab_db -f sql/procedures.sql
psql -U postgres -d doctor_lab_db -f sql/indexes.sql
```

### Web Dashboard

```bash
# Just open in browser — no server needed
open web/index.html
# or double-click index.html
```

---

## Privacy Architecture

The critical privacy constraint in this system:

```sql
-- Trigger prevents release before verification
CREATE OR REPLACE FUNCTION fn_enforce_release_policy()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_released = TRUE AND NEW.is_verified = FALSE THEN
        RAISE EXCEPTION 'POLICY VIOLATION: Cannot release report to patient before verification.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

This means even if someone tries to force `is_released = TRUE` via a direct SQL UPDATE, the trigger blocks it unless `is_verified` is already `TRUE`. The database enforces privacy — not just the application layer.

---

## Sample Analytical Queries

### Critical Reports with Emergency Contacts
```sql
SELECT lr.report_id, CONCAT(p.first_name,' ',p.last_name) AS patient,
       p.emergency_contact, lt.test_name, lr.result_summary
FROM lab_report lr
JOIN test_order to_ ON lr.order_id = to_.order_id
JOIN patient p ON to_.patient_id = p.patient_id
JOIN lab_test lt ON to_.test_id = lt.test_id
WHERE lr.is_critical = TRUE;
```

### Abnormality Rate per Test Category
```sql
SELECT lt.category,
       COUNT(lr.report_id) AS total,
       SUM(CASE WHEN lr.is_abnormal THEN 1 ELSE 0 END) AS abnormal,
       ROUND(AVG(lt.price), 2) AS avg_price
FROM lab_report lr
JOIN test_order to_ ON lr.order_id = to_.order_id
JOIN lab_test lt ON to_.test_id = lt.test_id
GROUP BY lt.category ORDER BY total DESC;
```

---

## Advanced DBMS Concepts Covered

-  **Relational Modeling** — 3NF / BCNF with documented FDs and anomalies
-  **Enhanced ER** — Weak entity (report_parameter), Specialization (lab_technician types)
-  **Triggers** — 6 triggers for audit, privacy enforcement, status sync
-  **Views** — Role-based abstraction (patient portal vs doctor dashboard)
-  **Stored Procedures** — Validated business operations (PL/pgSQL)
-  **Indexing** — Partial B+ Tree indexes with performance justification
-  **Transactions** — ACID demonstrations with savepoints and rollback
-  **Concurrency** — Isolation level discussion, dirty read prevention
-  **Relational Algebra** — σ, π, ⋈ operators mapped to SQL

---

## Advanced DBMS Concepts (Unit 4)

### Object-Oriented DBMS Motivation
The `lab_report` entity has behavior (verify, release, flag-as-critical) that naturally belongs with the data. In an OODBMS, the report object would encapsulate these methods. PostgreSQL's support for JSONB (`old_values`, `new_values` in `audit_log`) and custom types partially bridges this gap.

### Distributed DBMS Motivation
A hospital chain with branches across Delhi would benefit from a distributed DBMS where each branch holds its own patient data (data locality, latency) while a central node runs analytics (test frequency, abnormality rates). The `lab` table already models this separation.

### Centralized vs Distributed Trade-off
| Factor | Centralized | Distributed |
|---|---|---|
| Consistency | Easy (single source) | Hard (CAP theorem) |
| Latency | Higher for remote branches | Lower locally |
| Fault Tolerance | Single point of failure | Resilient |
| Privacy Compliance | Easier to audit | Harder across jurisdictions |

For a privacy-critical medical system, centralized with replicated read-only nodes is the preferred architecture.

---

## Author

**Kritika Goswami** | Enrollment: 36614803124  
Maharaja Agrasen Institute of Technology, Delhi  
Department of Information Technology | Semester 4

---

## Disclaimer

This project is developed for academic purposes to demonstrate advanced DBMS concepts in a real-world-inspired medical scenario. All patient data is entirely fictional.
