-- ============================================================
-- Doctor Lab Test Reports DB
-- Sample Data: Realistic test dataset
-- ============================================================

-- PATIENTS
INSERT INTO patient (first_name, last_name, date_of_birth, gender, phone, email, blood_group, address, emergency_contact)
VALUES
  ('Aarav',    'Sharma',    '1990-04-15', 'M', '9810012345', 'aarav.sharma@email.com',   'B+',  'Rohini, Delhi',        '9810012340'),
  ('Priya',    'Mehta',     '1985-11-22', 'F', '9821023456', 'priya.mehta@email.com',    'A+',  'Dwarka, Delhi',        '9821023450'),
  ('Rahul',    'Verma',     '2000-07-08', 'M', '9832034567', 'rahul.verma@email.com',    'O+',  'Pitampura, Delhi',     '9832034560'),
  ('Sneha',    'Gupta',     '1975-03-30', 'F', '9843045678', 'sneha.gupta@email.com',    'AB+', 'Janakpuri, Delhi',     '9843045670'),
  ('Vikram',   'Singh',     '1968-09-12', 'M', '9854056789', NULL,                       'B-',  'Shahdara, Delhi',      '9854056780'),
  ('Ananya',   'Kapoor',    '1995-01-25', 'F', '9865067890', 'ananya.k@email.com',       'A-',  'Lajpat Nagar, Delhi',  '9865067880'),
  ('Mohit',    'Joshi',     '1982-06-17', 'M', '9876078901', 'mohit.joshi@email.com',    'O-',  'Vasant Kunj, Delhi',   '9876078900'),
  ('Divya',    'Agarwal',   '1998-12-05', 'F', '9887089012', 'divya.a@email.com',        'B+',  'Connaught Place, Delhi','9887089010'),
  ('Arjun',    'Patel',     '1955-08-19', 'M', '9898090123', NULL,                       'A+',  'Karol Bagh, Delhi',    '9898090120'),
  ('Ritu',     'Choudhary', '1992-02-14', 'F', '9909101234', 'ritu.c@email.com',         'AB-', 'Saket, Delhi',         '9909101230');

-- DEPARTMENTS
INSERT INTO department (dept_name, location, contact_ext)
VALUES
  ('Pathology',    'Block A, Floor 1',  '101'),
  ('Radiology',    'Block B, Floor 2',  '201'),
  ('Cardiology',   'Block C, Floor 3',  '301'),
  ('Neurology',    'Block D, Floor 2',  '401'),
  ('General Medicine', 'Block A, Floor 0', '501');

-- DOCTORS
INSERT INTO doctor (first_name, last_name, specialization, license_number, dept_id, phone, email)
VALUES
  ('Rajesh',   'Kumar',    'Pathologist',        'MCI-PAT-2001-789', 1, '9111100001', 'dr.rajesh@hospital.in'),
  ('Sunita',   'Sharma',   'Radiologist',        'MCI-RAD-2005-456', 2, '9111100002', 'dr.sunita@hospital.in'),
  ('Anil',     'Kapoor',   'Cardiologist',       'MCI-CAR-1998-123', 3, '9111100003', 'dr.anil@hospital.in'),
  ('Meena',    'Iyer',     'Neurologist',        'MCI-NEU-2010-321', 4, '9111100004', 'dr.meena@hospital.in'),
  ('Sanjay',   'Gupta',    'General Physician',  'MCI-GEN-2003-654', 5, '9111100005', 'dr.sanjay@hospital.in');

-- Update department heads
UPDATE department SET head_doctor_id = 1 WHERE dept_id = 1;
UPDATE department SET head_doctor_id = 2 WHERE dept_id = 2;
UPDATE department SET head_doctor_id = 3 WHERE dept_id = 3;
UPDATE department SET head_doctor_id = 4 WHERE dept_id = 4;
UPDATE department SET head_doctor_id = 5 WHERE dept_id = 5;

-- APPOINTMENTS
INSERT INTO appointment (patient_id, doctor_id, appointment_date, appointment_time, status, reason)
VALUES
  (1, 5, '2026-01-10', '09:00', 'Completed', 'Fever and fatigue for 5 days'),
  (2, 5, '2026-01-10', '09:30', 'Completed', 'Routine check-up'),
  (3, 3, '2026-01-11', '10:00', 'Completed', 'Chest pain'),
  (4, 5, '2026-01-12', '11:00', 'Completed', 'Diabetes management'),
  (5, 4, '2026-01-13', '14:00', 'Completed', 'Recurrent headaches'),
  (6, 5, '2026-01-14', '09:00', 'Completed', 'Annual blood work'),
  (7, 3, '2026-01-15', '10:30', 'Completed', 'Palpitations'),
  (8, 5, '2026-01-16', '11:30', 'Completed', 'Thyroid check'),
  (9, 4, '2026-01-17', '14:30', 'Completed', 'Dizziness and memory issues'),
  (10,5, '2026-01-18', '09:00', 'Completed', 'Fatigue and weight gain');

-- PRESCRIPTIONS
INSERT INTO prescription (appointment_id, doctor_id, patient_id, prescribed_on, diagnosis, notes)
VALUES
  (1, 5, 1,  '2026-01-10', 'Suspected typhoid – lab confirmation required', 'Avoid spicy food'),
  (2, 5, 2,  '2026-01-10', 'Routine wellness screening',                    'Annual check'),
  (3, 3, 3,  '2026-01-11', 'Possible angina – ECG and lipid profile needed','Monitor BP'),
  (4, 5, 4,  '2026-01-12', 'Type 2 Diabetes – HbA1c monitoring',            'Diet control'),
  (5, 4, 5,  '2026-01-13', 'Migraine – imaging if persistent',              NULL),
  (6, 5, 6,  '2026-01-14', 'Routine annual screening',                      NULL),
  (7, 3, 7,  '2026-01-15', 'Atrial fibrillation suspected',                 'Urgent ECG'),
  (8, 5, 8,  '2026-01-16', 'Hypothyroidism – TSH trending up',              'Recheck in 3 months'),
  (9, 4, 9,  '2026-01-17', 'Cognitive decline screening',                   NULL),
  (10,5, 10, '2026-01-18', 'Hypothyroidism + anemia suspected',             NULL);

-- LABs
INSERT INTO lab (lab_name, location, accreditation, contact_phone)
VALUES
  ('Central Diagnostics Lab',  'Block A, Ground Floor', 'NABL Accredited', '011-23456789'),
  ('MRI & Imaging Center',     'Block B, Ground Floor', 'NABL Accredited', '011-23456790'),
  ('Cardio Diagnostics Unit',  'Block C, Level 1',      'ISO 15189',       '011-23456791');

-- LAB TECHNICIANS
INSERT INTO lab_technician (first_name, last_name, lab_id, qualification, license_number, phone, email)
VALUES
  ('Pooja',   'Singh',    1, 'DMLT, B.Sc MLT', 'DMLT-DEL-2015-001', '9700001111', 'pooja.s@lab.in'),
  ('Deepak',  'Rao',      1, 'B.Sc MLT',       'DMLT-DEL-2018-002', '9700002222', 'deepak.r@lab.in'),
  ('Simran',  'Kaur',     2, 'B.Sc Radiology', 'RAD-DEL-2016-003',  '9700003333', 'simran.k@lab.in'),
  ('Tarun',   'Mehra',    3, 'DMLT, ECG Tech', 'DMLT-DEL-2019-004', '9700004444', 'tarun.m@lab.in');

-- LAB TEST CATALOG
INSERT INTO lab_test (test_name, test_code, category, sample_type, normal_range, unit, turnaround_hours, price)
VALUES
  ('Complete Blood Count',        'CBC-001',  'Hematology',    'Blood',   'WBC: 4-11 K/uL, RBC: 4.5-5.9 M/uL', 'K/uL', 4,  350.00),
  ('Widal Test',                  'WID-001',  'Serology',      'Blood',   'Negative',                            NULL,   24, 250.00),
  ('Lipid Profile',               'LIP-001',  'Biochemistry',  'Blood',   'Total Cholesterol < 200 mg/dL',       'mg/dL',12, 600.00),
  ('HbA1c',                       'HBA-001',  'Biochemistry',  'Blood',   '4.0 – 5.6%',                         '%',    6,  450.00),
  ('Thyroid Stimulating Hormone', 'TSH-001',  'Biochemistry',  'Blood',   '0.4 – 4.0 mIU/L',                    'mIU/L',8,  550.00),
  ('ECG 12-Lead',                 'ECG-001',  'Other',         'N/A',     'Normal sinus rhythm',                 NULL,   1,  300.00),
  ('MRI Brain',                   'MRI-001',  'Radiology',     'N/A',     'No lesion or mass',                   NULL,   48, 4500.00),
  ('Urine Routine Examination',   'URE-001',  'Urine',         'Urine',   'pH 4.6-8.0, No RBC/Pus',             NULL,   4,  150.00),
  ('Liver Function Test',         'LFT-001',  'Biochemistry',  'Blood',   'ALT: 7-56 U/L, AST: 10-40 U/L',      'U/L',  8,  700.00),
  ('Troponin I',                  'TRP-001',  'Immunology',    'Blood',   '< 0.04 ng/mL',                        'ng/mL',2,  800.00);

-- TEST ORDERS
INSERT INTO test_order (prescription_id, patient_id, doctor_id, lab_id, test_id, ordered_on, priority, status, collection_time)
VALUES
  (1, 1, 5, 1, 1, '2026-01-10 10:00', 'Normal', 'Completed', '2026-01-10 11:00'),
  (1, 1, 5, 1, 2, '2026-01-10 10:00', 'Normal', 'Completed', '2026-01-10 11:00'),
  (2, 2, 5, 1, 3, '2026-01-10 10:30', 'Normal', 'Completed', '2026-01-10 11:30'),
  (3, 3, 3, 3, 6, '2026-01-11 10:30', 'Urgent', 'Completed', '2026-01-11 11:00'),
  (3, 3, 3, 1, 3, '2026-01-11 10:30', 'Urgent', 'Completed', '2026-01-11 11:00'),
  (4, 4, 5, 1, 4, '2026-01-12 11:30', 'Normal', 'Completed', '2026-01-12 12:00'),
  (5, 5, 4, 2, 7, '2026-01-13 14:30', 'Normal', 'Completed', '2026-01-13 15:00'),
  (6, 6, 5, 1, 1, '2026-01-14 09:30', 'Normal', 'Completed', '2026-01-14 10:00'),
  (7, 7, 3, 3, 10,'2026-01-15 11:00', 'STAT',   'Completed', '2026-01-15 11:10'),
  (8, 8, 5, 1, 5, '2026-01-16 12:00', 'Normal', 'Completed', '2026-01-16 12:30'),
  (9, 9, 4, 2, 7, '2026-01-17 15:00', 'Normal', 'Completed', '2026-01-17 15:30'),
  (10,10,5, 1, 5, '2026-01-18 09:30', 'Normal', 'Completed', '2026-01-18 10:00'),
  (10,10,5, 1, 1, '2026-01-18 09:30', 'Normal', 'Completed', '2026-01-18 10:00');

-- LAB REPORTS
INSERT INTO lab_report (order_id, tech_id, verified_by, report_date, result_summary, is_abnormal, is_critical, is_verified, verified_at, is_released, released_at, remarks)
VALUES
  (1, 1, 1, '2026-01-10', 'WBC elevated at 13.2 K/uL. RBC normal. Neutrophilia noted.',     TRUE,  FALSE, TRUE, '2026-01-10 16:00', TRUE, '2026-01-10 17:00', 'Consistent with bacterial infection'),
  (2, 1, 1, '2026-01-11', 'Widal O 1:160 positive. Typhoid fever likely.',                  TRUE,  FALSE, TRUE, '2026-01-11 10:00', TRUE, '2026-01-11 11:00', 'Clinical correlation advised'),
  (3, 2, 1, '2026-01-10', 'Total Cholesterol 235 mg/dL (HIGH). LDL 155 mg/dL.',            TRUE,  FALSE, TRUE, '2026-01-10 18:00', TRUE, '2026-01-10 19:00', 'Dietary modification recommended'),
  (4, 4, 3, '2026-01-11', 'ECG shows irregular rhythm. AF pattern identified.',             TRUE,  TRUE,  TRUE, '2026-01-11 12:00', TRUE, '2026-01-11 12:30', 'URGENT: Refer cardiologist immediately'),
  (5, 2, 1, '2026-01-11', 'Total Cholesterol 189 mg/dL. LDL 110 mg/dL. Within range.',    FALSE, FALSE, TRUE, '2026-01-11 18:00', TRUE, '2026-01-11 19:00', 'Normal lipid profile'),
  (6, 1, 1, '2026-01-12', 'HbA1c 8.2% – above target. Poor glycemic control.',            TRUE,  FALSE, TRUE, '2026-01-12 16:00', TRUE, '2026-01-12 17:00', 'Medication review recommended'),
  (7, 3, 2, '2026-01-14', 'MRI Brain: No acute lesion. Mild white matter changes noted.', FALSE, FALSE, TRUE, '2026-01-14 15:00', TRUE, '2026-01-14 16:00', 'Age-related changes, no acute pathology'),
  (8, 1, 1, '2026-01-14', 'All parameters within normal limits.',                          FALSE, FALSE, TRUE, '2026-01-14 14:00', TRUE, '2026-01-14 15:00', 'Healthy profile'),
  (9, 4, 3, '2026-01-15', 'Troponin I: 0.89 ng/mL – CRITICALLY HIGH.',                   TRUE,  TRUE,  TRUE, '2026-01-15 12:00', TRUE, '2026-01-15 12:15', 'CRITICAL: Possible MI. Immediate intervention required'),
  (10,1, 1, '2026-01-16', 'TSH 6.8 mIU/L – elevated. Hypothyroidism indicated.',         TRUE,  FALSE, TRUE, '2026-01-16 17:00', TRUE, '2026-01-16 18:00', 'Dose adjustment advised'),
  (11,3, 2, '2026-01-18', 'MRI Brain: Cortical atrophy pattern suggestive of early MCI.', TRUE,  FALSE, TRUE, '2026-01-18 16:00', TRUE, '2026-01-18 17:00', 'Neurology follow-up in 3 months'),
  (12,1, 1, '2026-01-18', 'TSH 7.2 mIU/L. T3 low. Hypothyroidism confirmed.',            TRUE,  FALSE, TRUE, '2026-01-18 16:00', TRUE, '2026-01-18 17:00', 'Start levothyroxine'),
  (13,2, 1, '2026-01-18', 'Hb 9.2 g/dL – low. MCV low. Iron deficiency anemia.',         TRUE,  FALSE, TRUE, '2026-01-18 17:00', TRUE, '2026-01-18 18:00', 'Iron supplementation needed');

-- REPORT PARAMETERS (detailed values per report)
INSERT INTO report_parameter (report_id, parameter_name, observed_value, normal_range, unit, is_abnormal, flag)
VALUES
  (1, 'WBC',       '13.2',  '4.0 – 11.0',   'K/uL',  TRUE,  'H'),
  (1, 'RBC',       '5.1',   '4.5 – 5.9',    'M/uL',  FALSE, 'N'),
  (1, 'Hemoglobin','14.8',  '13.5 – 17.5',  'g/dL',  FALSE, 'N'),
  (1, 'Neutrophils','78',   '40 – 70',       '%',     TRUE,  'H'),
  (6, 'HbA1c',    '8.2',   '4.0 – 5.6',    '%',     TRUE,  'HH'),
  (9, 'Troponin I','0.89', '< 0.04',        'ng/mL', TRUE,  'HH'),
  (10,'TSH',      '6.8',   '0.4 – 4.0',    'mIU/L', TRUE,  'H'),
  (12,'TSH',      '7.2',   '0.4 – 4.0',    'mIU/L', TRUE,  'H'),
  (12,'T3',       '0.7',   '0.8 – 2.0',    'nmol/L',TRUE,  'L'),
  (13,'Hemoglobin','9.2',  '12.0 – 16.0',  'g/dL',  TRUE,  'L'),
  (13,'MCV',      '71',    '80 – 100',      'fL',    TRUE,  'L'),
  (3, 'Total Cholesterol','235','< 200',    'mg/dL', TRUE,  'H'),
  (3, 'LDL',      '155',   '< 130',         'mg/dL', TRUE,  'H'),
  (3, 'HDL',      '38',    '> 40',          'mg/dL', TRUE,  'L');

-- ACCESS LOGS (privacy audit trail)
INSERT INTO access_log (report_id, accessed_by_role, accessed_by_id, access_type, ip_address)
VALUES
  (1, 'Doctor',     5, 'View',     '192.168.1.10'),
  (1, 'Technician', 1, 'Edit',     '192.168.1.20'),
  (1, 'Patient',    1, 'View',     '103.24.55.12'),
  (4, 'Doctor',     3, 'View',     '192.168.1.10'),
  (4, 'Doctor',     3, 'Download', '192.168.1.10'),
  (9, 'Doctor',     3, 'View',     '192.168.1.10'),
  (9, 'Admin',      1, 'View',     '192.168.1.1'),
  (2, 'Patient',    1, 'View',     '103.24.55.12'),
  (6, 'Doctor',     5, 'View',     '192.168.1.10'),
  (6, 'Patient',    4, 'View',     '110.33.22.45');
