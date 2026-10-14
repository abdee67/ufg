SET session_replication_role = replica;

--
-- PostgreSQL database dump
--

-- \restrict ssESYz91C9a1j74NaL11Vq9AgN9d4JfgnwpP4F82HuTte6lGdDqEyjd0Q8TBtDE

-- Dumped from database version 17.6
-- Dumped by pg_dump version 17.6

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

-- Clean pre-seeded lookup tables so remote dump can insert exact IDs without constraint conflicts
TRUNCATE TABLE
  public.role_permissions,
  public.user_roles,
  public.roles,
  public.permissions,
  public.account_types,
  public.payment_methods,
  public.loan_products,
  public.financial_rule_versions,
  public.financial_rules
CASCADE;

--
-- Data for Name: account_types; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."account_types" ("id", "code", "name", "description", "created_at") VALUES
	('c5fe52ef-3241-4e8f-a7a9-3dc054c21842', 'member_savings', 'Member Savings', 'Member savings funds', '2026-08-26 19:36:24.648374+00'),
	('d12f648a-a75c-4196-ac97-92812258f7c9', 'group_income', 'Group Income', 'Income belonging to the group', '2026-08-26 19:36:24.648374+00'),
	('019967b1-6dcb-42ba-8fbb-d73fd59244ad', 'group_expense', 'Group Expense', 'Operating expenses', '2026-08-26 19:36:24.648374+00'),
	('11569905-36e9-4e55-b4f5-b8ed43a8d71b', 'cash', 'Cash', 'Physical cash', '2026-08-26 19:36:24.648374+00'),
	('00739334-8e75-4348-bba0-c76850766e45', 'bank', 'Bank', 'Group bank account', '2026-08-26 19:36:24.648374+00'),
	('bac92f72-4c91-4d85-ade4-6de75a4e5749', 'wallet', 'Wallet', 'Group wallet', '2026-08-26 19:36:24.648374+00'),
	('9ce46ca4-3f3f-4cc2-9dbd-e037857106fb', 'loan_receivable', 'Loan Receivable', 'Outstanding loan principal', '2026-08-26 19:36:24.648374+00'),
	('579c98c1-ff21-435b-839f-210dd8c4b8a3', 'loan_service_charge_income', 'Loan Service Charge Income', 'Income from loan service charges', '2026-08-26 19:36:24.648374+00'),
	('293b5073-fc80-4592-ab87-cb7b0cf8c2d0', 'penalty_income', 'Penalty Income', 'Income from late penalties', '2026-08-26 19:36:24.648374+00');


--
-- Data for Name: profiles; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."profiles" ("id", "full_name", "phone", "email", "address", "date_of_birth", "status", "created_at", "updated_at", "must_change_password") VALUES
	('64efef4f-1555-4322-80ad-f69e46887516', 'Abdulaz', '+251721777648', 'alaziizz67@gmail.com', 'chas', '2001-01-01', 'active', '2026-09-06 09:40:24.895181+00', '2026-09-26 15:04:23.292959+00', false),
	('a9e748d4-dc2b-4d5b-9571-2e2f2bc78e0d', 'Tariku Admasu', '+251954201924', NULL, 'Addis Ababa', '2001-01-01', 'active', '2026-10-11 13:42:26.762591+00', '2026-10-11 13:44:56.288231+00', false),
	('99c968a2-142f-4329-935d-ef240a5a40f5', 'test1', '0912345678', NULL, 'AA', '2001-01-01', 'active', '2026-09-25 17:25:35.907278+00', '2026-09-25 19:19:55.327999+00', false),
	('a5c1a9c8-6ccd-49c2-a069-2781c83be09d', 'Amanuel Mesay', '+251935356268', 'amanuelmesay806@gmail.com', 'Addis Ababa', '2001-01-01', 'active', '2026-09-06 11:06:34.385622+00', '2026-09-25 20:33:34.552498+00', false),
	('5101cac2-a24e-4342-975a-74df63071328', 'hang', '+251912345677', 'amanuelmesay7@gmail.com', 'Xbox', '2001-01-01', 'active', '2026-09-11 11:10:23.236503+00', '2026-09-25 20:36:40.608824+00', false),
	('3f3e0eb5-aeb1-4999-bd98-18543b01b613', 'dir', '+251911111111', 'dir@gmail.com', NULL, NULL, 'active', '2026-09-22 15:18:53.257292+00', '2026-09-26 12:34:40.931374+00', false),
	('96f15dbd-e885-4f42-8f55-492bd72cd515', 'mcnan6', '+251922222222', 'mcnan6@gmail.com', NULL, NULL, 'active', '2026-09-01 19:40:06.089617+00', '2026-09-26 12:40:14.999588+00', false),
	('8a4f38eb-af53-4d05-8ab1-0e332e022710', 'admin3', '+251933333333', 'admin3@gmail.com', NULL, NULL, 'active', '2026-09-26 12:42:20.192694+00', '2026-09-26 13:27:42.77685+00', false);


--
-- Data for Name: members; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."members" ("id", "profile_id", "member_number", "membership_date", "status", "created_at", "updated_at") VALUES
	('9b5bf983-6cba-40b9-890d-f1af17041ffa', '64efef4f-1555-4322-80ad-f69e46887516', 'MEM-000001', '2026-09-06', 'active', '2026-09-06 09:46:46.985302+00', '2026-09-21 14:00:30.272238+00'),
	('a69eafab-eb8a-435c-8e0c-d3b22fa3b8f9', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', 'MEM-000002', '2026-09-06', 'active', '2026-09-06 11:10:47.715018+00', '2026-09-21 14:00:30.272238+00'),
	('87e01037-3229-4ca7-bc94-b5a109e312a5', '5101cac2-a24e-4342-975a-74df63071328', 'MEM-000003', '2026-09-11', 'active', '2026-09-11 11:13:02.457996+00', '2026-09-21 14:00:30.272238+00'),
	('92e3f6fb-0b10-4ea2-9212-c2b470c6221b', '99c968a2-142f-4329-935d-ef240a5a40f5', 'MEM-000004', '2026-09-25', 'active', '2026-09-25 17:27:16.225866+00', '2026-09-25 17:27:16.225866+00'),
	('80ea84c9-313d-4927-b066-4fcdd6116226', 'a9e748d4-dc2b-4d5b-9571-2e2f2bc78e0d', 'MEM-000005', '2026-10-11', 'active', '2026-10-11 13:46:24.918799+00', '2026-10-11 13:46:24.918799+00');


--
-- Data for Name: accounts; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."accounts" ("id", "account_type_id", "owner_profile_id", "owner_member_id", "currency", "status", "created_at", "updated_at") VALUES
	('cfd12a46-15b7-44aa-9994-168f7f34e52c', 'd12f648a-a75c-4196-ac97-92812258f7c9', NULL, NULL, 'ETB', 'active', '2026-09-04 20:04:00.838906+00', '2026-09-04 20:04:00.838906+00'),
	('106ebef4-6340-4e5f-8147-b863567b5091', '019967b1-6dcb-42ba-8fbb-d73fd59244ad', NULL, NULL, 'ETB', 'active', '2026-09-04 20:04:00.838906+00', '2026-09-04 20:04:00.838906+00'),
	('afb4c4b9-e7f2-464c-9313-9ace85492586', '11569905-36e9-4e55-b4f5-b8ed43a8d71b', NULL, NULL, 'ETB', 'active', '2026-09-04 20:04:00.838906+00', '2026-09-04 20:04:00.838906+00'),
	('fe1846e1-6150-4591-95c0-a9e10ef11993', '00739334-8e75-4348-bba0-c76850766e45', NULL, NULL, 'ETB', 'active', '2026-09-04 20:04:00.838906+00', '2026-09-04 20:04:00.838906+00'),
	('1fe1907a-a24d-48d7-b60e-5e69789c855f', 'bac92f72-4c91-4d85-ade4-6de75a4e5749', NULL, NULL, 'ETB', 'active', '2026-09-04 20:04:00.838906+00', '2026-09-04 20:04:00.838906+00'),
	('0c20575a-d65f-443b-9392-4f3c8238c60b', '9ce46ca4-3f3f-4cc2-9dbd-e037857106fb', NULL, NULL, 'ETB', 'active', '2026-09-04 20:04:00.838906+00', '2026-09-04 20:04:00.838906+00'),
	('6a2c8c14-430b-4de1-bf34-062f4793e4a3', '579c98c1-ff21-435b-839f-210dd8c4b8a3', NULL, NULL, 'ETB', 'active', '2026-09-04 20:04:00.838906+00', '2026-09-04 20:04:00.838906+00'),
	('5e7c51e7-01c5-41d8-972a-4480e1d7474c', '293b5073-fc80-4592-ab87-cb7b0cf8c2d0', NULL, NULL, 'ETB', 'active', '2026-09-04 20:04:00.838906+00', '2026-09-04 20:04:00.838906+00'),
	('c48e0136-daf0-4da1-a806-100e3011a783', 'c5fe52ef-3241-4e8f-a7a9-3dc054c21842', '64efef4f-1555-4322-80ad-f69e46887516', '9b5bf983-6cba-40b9-890d-f1af17041ffa', 'ETB', 'active', '2026-09-06 09:53:38.161399+00', '2026-09-06 09:53:38.161399+00'),
	('1379e70b-a8c3-40ae-98c1-102c7bd42dbd', 'c5fe52ef-3241-4e8f-a7a9-3dc054c21842', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', 'a69eafab-eb8a-435c-8e0c-d3b22fa3b8f9', 'ETB', 'active', '2026-09-06 11:10:47.715018+00', '2026-09-06 11:10:47.715018+00'),
	('374679e3-6777-4242-beee-055c63520435', 'c5fe52ef-3241-4e8f-a7a9-3dc054c21842', '5101cac2-a24e-4342-975a-74df63071328', '87e01037-3229-4ca7-bc94-b5a109e312a5', 'ETB', 'active', '2026-09-11 11:13:02.457996+00', '2026-09-11 11:13:02.457996+00'),
	('9cf4e59d-c245-4c22-b440-689721fac524', 'c5fe52ef-3241-4e8f-a7a9-3dc054c21842', '99c968a2-142f-4329-935d-ef240a5a40f5', '92e3f6fb-0b10-4ea2-9212-c2b470c6221b', 'ETB', 'active', '2026-09-25 17:27:16.225866+00', '2026-09-25 17:27:16.225866+00'),
	('0543be11-14ad-465c-ad9e-927a81187d82', 'c5fe52ef-3241-4e8f-a7a9-3dc054c21842', 'a9e748d4-dc2b-4d5b-9571-2e2f2bc78e0d', '80ea84c9-313d-4927-b066-4fcdd6116226', 'ETB', 'active', '2026-10-11 13:46:24.918799+00', '2026-10-11 13:46:24.918799+00');


--
-- Data for Name: audit_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."audit_logs" ("id", "actor_user_id", "action", "entity_type", "entity_id", "old_data", "new_data", "metadata", "created_at") VALUES
	('25f3a94c-bee0-48ca-98e6-6fa30c347aff', '96f15dbd-e885-4f42-8f55-492bd72cd515', 'ADMIN_BOOTSTRAP', 'user_roles', '96f15dbd-e885-4f42-8f55-492bd72cd515', NULL, '{"role": "admin", "email": "mcnan6@gmail.com"}', NULL, '2026-09-01 19:56:02.267675+00'),
	('54e232ee-aa9d-49f9-a67f-3179b48a5dea', '96f15dbd-e885-4f42-8f55-492bd72cd515', 'MEMBERSHIP_APPLICATION_APPROVED', 'members', 'da6e1b2b-a78c-46d6-bf9d-ce7bfa6f38d3', NULL, '{"profile_id": "c829df17-cd01-4de7-8601-7d7f8254c0cb", "member_number": "MEM-20260901205536067-B03AEDD0", "application_id": "948f7045-4782-4337-a3aa-07ba8b04cc46"}', NULL, '2026-09-01 20:55:36.031408+00'),
	('64acabc6-75eb-4112-879f-05082d44f9aa', '96f15dbd-e885-4f42-8f55-492bd72cd515', 'MEMBERSHIP_APPLICATION_APPROVED', 'members', '2ac1d7c2-ac04-4259-a237-7f63eb8d37bc', NULL, '{"profile_id": "c829df17-cd01-4de7-8601-7d7f8254c0cb", "member_number": "MEM-20260906072530330-D1563D8E", "application_id": "9ddc1650-1667-4771-a2ef-186bf65619d4"}', NULL, '2026-09-06 07:25:30.303102+00'),
	('ac4da95f-5e1b-46ee-965f-48d14f988cf2', NULL, 'MEMBERSHIP_APPLICATION_SUBMITTED', 'membership_application', '948f7045-4782-4337-a3aa-07ba8b04cc46', NULL, '{"applicant_id": "c829df17-cd01-4de7-8601-7d7f8254c0cb", "storage_path": "c829df17-cd01-4de7-8601-7d7f8254c0cb/1788295642221.pdf", "application_number": "MEMAPP-20260901204955591-881B0340"}', NULL, '2026-09-01 20:49:55.555003+00'),
	('d43eacc2-2c9f-4dff-bf1b-e3ce44596511', NULL, 'SAVINGS_PAYMENT_SUBMITTED', 'payments', '1d289e23-ce62-45d5-bb07-8f7506af2cc5', NULL, '{"amount": 200.0, "obligation_id": null, "payment_method": "bank_transfer", "reference_number": "PAY-20260901210140526-F7FF0857"}', NULL, '2026-09-01 21:01:40.506506+00'),
	('4b917347-d6c2-4248-a1e7-8b68fc27b77c', NULL, 'SAVINGS_PAYMENT_SUBMITTED', 'payments', '7d88242d-176e-4046-a1fc-b931c9b7043e', NULL, '{"amount": 2000.0, "obligation_id": null, "payment_method": "wallet", "reference_number": "PAY-20260902065512920-CD269D64"}', NULL, '2026-09-02 06:55:12.845812+00'),
	('58cd6fb5-a6b2-476c-9f6f-56a5f1ee6678', NULL, 'MEMBERSHIP_APPLICATION_SUBMITTED', 'membership_application', '9ddc1650-1667-4771-a2ef-186bf65619d4', NULL, '{"applicant_id": "c829df17-cd01-4de7-8601-7d7f8254c0cb", "storage_path": "c829df17-cd01-4de7-8601-7d7f8254c0cb/1788679331011.pdf", "application_number": "MEMAPP-20260906072219548-0BF80F39"}', NULL, '2026-09-06 07:22:19.514061+00'),
	('28b03931-b6ec-4439-8bb1-96b6c365a384', NULL, 'SAVINGS_PAYMENT_SUBMITTED', 'payments', '2aa23ed2-1307-43fd-abf7-e102788ca3d0', NULL, '{"amount": 2000.0, "obligation_id": null, "payment_method": "wallet", "reference_number": "PAY-20260906072717175-ECF8C63C"}', NULL, '2026-09-06 07:27:17.165949+00'),
	('7548dc20-235f-4374-8724-80533e46f0ca', NULL, 'SAVINGS_PAYMENT_SUBMITTED', 'payments', '9ee928d2-af83-4764-8fd3-ea602f39a35f', NULL, '{"amount": 1000.0, "obligation_id": null, "payment_method": "bank_transfer", "reference_number": "PAY-20260906074753062-19948BC4"}', NULL, '2026-09-06 07:47:53.045657+00'),
	('34576605-379c-4cc2-8ad9-58f0be947fa2', '64efef4f-1555-4322-80ad-f69e46887516', 'MEMBERSHIP_APPLICATION_SUBMITTED', 'membership_application', 'a71beba3-11b3-4c2a-9b25-ec4442762fdc', NULL, '{"applicant_id": "64efef4f-1555-4322-80ad-f69e46887516", "storage_path": "64efef4f-1555-4322-80ad-f69e46887516/1788687542188.pdf", "application_number": "MEMAPP-20260906094137572-93BFA727"}', NULL, '2026-09-06 09:41:37.541233+00'),
	('c80cb191-cf59-40b6-a80f-5802111056a7', '96f15dbd-e885-4f42-8f55-492bd72cd515', 'MEMBERSHIP_APPLICATION_APPROVED', 'members', '9b5bf983-6cba-40b9-890d-f1af17041ffa', NULL, '{"profile_id": "64efef4f-1555-4322-80ad-f69e46887516", "member_number": "MEM-20260906094647028-3C1446AB", "application_id": "a71beba3-11b3-4c2a-9b25-ec4442762fdc"}', NULL, '2026-09-06 09:46:46.985302+00'),
	('75bf5ce9-f98d-4c1e-acc4-d5a848f8dfcd', '64efef4f-1555-4322-80ad-f69e46887516', 'SAVINGS_PAYMENT_SUBMITTED', 'payments', 'fbaccbd0-9228-420b-a5c1-be9fc1e361c0', NULL, '{"amount": 2000.0, "obligation_id": null, "payment_method": "bank_transfer", "reference_number": "PAY-20260906101808006-9E49CFD4"}', NULL, '2026-09-06 10:18:07.987861+00'),
	('ffa4ed60-f41c-4abe-82ba-8a436a48967c', '96f15dbd-e885-4f42-8f55-492bd72cd515', 'SAVINGS_PAYMENT_VERIFIED', 'payment', 'fbaccbd0-9228-420b-a5c1-be9fc1e361c0', '{"status": "pending"}', '{"status": "verified", "transaction_id": "dbab7db5-8470-417d-9c0e-2cd0d34c6bd7", "mandatory_amount": 0.00, "voluntary_amount": 2000.00}', '{"member_id": "9b5bf983-6cba-40b9-890d-f1af17041ffa"}', '2026-09-06 10:19:06.701024+00'),
	('d839383f-6847-4074-94e1-a951f68cc43d', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', 'MEMBERSHIP_APPLICATION_SUBMITTED', 'membership_application', '2c258ebc-0655-4b64-9cfe-b4f2e3ceb91c', NULL, '{"applicant_id": "a5c1a9c8-6ccd-49c2-a069-2781c83be09d", "storage_path": "a5c1a9c8-6ccd-49c2-a069-2781c83be09d/1788692884890.jpg", "application_number": "MEMAPP-20260906110808698-CB86F256"}', NULL, '2026-09-06 11:08:08.662627+00'),
	('38803720-c364-4601-8773-7405b1f5b5d5', '96f15dbd-e885-4f42-8f55-492bd72cd515', 'MEMBERSHIP_APPLICATION_APPROVED', 'members', 'a69eafab-eb8a-435c-8e0c-d3b22fa3b8f9', NULL, '{"profile_id": "a5c1a9c8-6ccd-49c2-a069-2781c83be09d", "member_number": "MEM-20260906111047769-FA2370E0", "application_id": "2c258ebc-0655-4b64-9cfe-b4f2e3ceb91c"}', NULL, '2026-09-06 11:10:47.715018+00'),
	('fef6ecbe-0ca4-4f77-98c1-c5d1a3f89035', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', 'SAVINGS_PAYMENT_SUBMITTED', 'payments', '59147fd5-2507-4596-81e7-a055354c8811', NULL, '{"amount": 2000.0, "obligation_id": null, "payment_method": "wallet", "reference_number": "PAY-20260906111428526-88150C32"}', NULL, '2026-09-06 11:14:28.499468+00'),
	('c94080bb-fc05-4b41-9e0b-24d8bb36c5e2', '96f15dbd-e885-4f42-8f55-492bd72cd515', 'SAVINGS_PAYMENT_VERIFIED', 'payment', '59147fd5-2507-4596-81e7-a055354c8811', '{"status": "pending"}', '{"status": "verified", "transaction_id": "910b7e88-ebc8-4567-b937-6fddf185ca96", "mandatory_amount": 2000.00, "voluntary_amount": 0.00}', '{"member_id": "a69eafab-eb8a-435c-8e0c-d3b22fa3b8f9"}', '2026-09-06 11:16:04.442067+00'),
	('0c8608db-49d3-47ac-a1ce-264c1bedccfa', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', 'SAVINGS_WITHDRAWAL_REQUESTED', 'withdrawal_requests', '5731ca9c-8c4f-40ce-a4ef-85dc1d450da3', NULL, '{"amount": 2000.0, "reason": null, "member_id": "a69eafab-eb8a-435c-8e0c-d3b22fa3b8f9"}', NULL, '2026-09-06 11:16:27.419492+00'),
	('60c1b956-f374-47be-8b6e-3da60b0298cf', '96f15dbd-e885-4f42-8f55-492bd72cd515', 'SAVINGS_WITHDRAWAL_POSTED', 'withdrawal_request', '5731ca9c-8c4f-40ce-a4ef-85dc1d450da3', '{"amount": 2000.00, "status": "pending"}', '{"status": "paid", "transaction_id": "a0358e7e-1631-4ab3-906d-6c70aee63481"}', '{"member_id": "a69eafab-eb8a-435c-8e0c-d3b22fa3b8f9", "secured_before": 0.00, "available_before": 2000.00}', '2026-09-06 11:18:11.868169+00'),
	('40b34d54-a796-46ce-b69d-195b6dcde823', '64efef4f-1555-4322-80ad-f69e46887516', 'LOAN_ELIGIBILITY_EVALUATED', 'loan_application', '4cdea73f-145b-4d6b-8608-e25f6f2613b2', NULL, '{"amount_ok": true, "liquidity": {"overdue_loans": 0, "available_cash": 2000.00, "loanable_funds": 1400.00, "required_reserve": 600.00, "outstanding_loans": 0.00, "reserve_compliant": true, "total_member_savings": 2000.00, "liquidity_reserve_rate": 0.300000}, "max_amount": 20000.00, "evaluated_at": "2026-09-07T14:53:14.168987+00:00", "guarantor_ok": false, "liquidity_ok": false, "active_member": true, "borrower_type": "member", "manual_reviews": ["REPAYMENT_CAPACITY", "LIQUIDITY_AMOUNT_REDUCTION_OR_DELAY"], "no_overdue_loan": true, "requested_amount": 12000.00, "evaluation_run_id": "03a33573-3ca3-460c-84f9-31676fc7b473", "member_saving_months": 0, "current_monthly_contribution_ok": true}', '{"evaluation_run_id": "03a33573-3ca3-460c-84f9-31676fc7b473"}', '2026-09-07 14:53:14.168987+00'),
	('fd0822ef-76c1-4597-be1d-90212dc93edc', '64efef4f-1555-4322-80ad-f69e46887516', 'SAVINGS_PAYMENT_SUBMITTED', 'payments', '109328cc-ed3a-46c8-b087-41fb420d31ee', NULL, '{"amount": 2345.0, "obligation_id": null, "payment_method": "bank_transfer", "reference_number": "PAY-000001"}', NULL, '2026-09-09 13:15:23.000559+00'),
	('7de5abf2-26a9-4723-be25-bc847f6457bc', '96f15dbd-e885-4f42-8f55-492bd72cd515', 'SAVINGS_PAYMENT_VERIFIED', 'payment', '109328cc-ed3a-46c8-b087-41fb420d31ee', '{"status": "pending"}', '{"status": "verified", "transaction_id": "4dc43676-1e54-4e8e-993c-13930d5e1e18", "mandatory_amount": 0.00, "voluntary_amount": 2345.00}', '{"member_id": "9b5bf983-6cba-40b9-890d-f1af17041ffa"}', '2026-09-09 14:21:37.970045+00'),
	('91f50449-e794-43b4-820b-5d5fade93e7f', '64efef4f-1555-4322-80ad-f69e46887516', 'SAVINGS_PAYMENT_SUBMITTED', 'payments', '54b6e21a-046f-4d16-90a5-51f552762ec9', NULL, '{"amount": 2000.0, "obligation_id": null, "payment_method": "bank_transfer", "reference_number": "PAY-000003"}', NULL, '2026-09-09 14:33:26.503427+00'),
	('636909e5-cc74-423e-9f23-bbb77801e427', '96f15dbd-e885-4f42-8f55-492bd72cd515', 'SAVINGS_OBLIGATIONS_GENERATED', 'savings_obligation_batch', NULL, NULL, NULL, '{"due_date": "2026-09-12", "period_year": 2026, "period_month": 9, "created_count": 1, "required_amount": 2000.00}', '2026-09-09 16:14:50.679803+00'),
	('23b394e2-2951-48e8-92df-b3094ae62f68', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', 'SAVINGS_PAYMENT_SUBMITTED', 'payments', 'd6370408-53b4-4721-a77a-9f7ca9752fb6', NULL, '{"amount": 2000.0, "obligation_id": null, "payment_method": "wallet", "reference_number": "PAY-000004"}', NULL, '2026-09-11 10:53:15.493947+00'),
	('e6987af8-229c-418a-9c2c-19d44aed203d', '96f15dbd-e885-4f42-8f55-492bd72cd515', 'SAVINGS_PAYMENT_VERIFIED', 'payment', '54b6e21a-046f-4d16-90a5-51f552762ec9', '{"status": "pending"}', '{"status": "verified", "transaction_id": "35c1df1c-f60f-4316-aec4-13b6d9aeb106", "mandatory_amount": 2000.00, "voluntary_amount": 0.00}', '{"member_id": "9b5bf983-6cba-40b9-890d-f1af17041ffa"}', '2026-09-11 10:55:52.018182+00'),
	('465e81b8-0a4f-4299-b36a-42fa4358709f', '96f15dbd-e885-4f42-8f55-492bd72cd515', 'SAVINGS_PAYMENT_VERIFIED', 'payment', 'd6370408-53b4-4721-a77a-9f7ca9752fb6', '{"status": "pending"}', '{"status": "verified", "transaction_id": "d812c137-313d-4f11-9e29-75d88e3ced85", "mandatory_amount": 0.00, "voluntary_amount": 2000.00}', '{"member_id": "a69eafab-eb8a-435c-8e0c-d3b22fa3b8f9"}', '2026-09-11 10:56:16.342875+00'),
	('8fa88d5d-0429-42b0-b74a-9b32712202ac', '5101cac2-a24e-4342-975a-74df63071328', 'MEMBERSHIP_APPLICATION_SUBMITTED', 'membership_application', '7e785ac0-2fb8-4ed8-a290-ffc17a517fef', NULL, '{"applicant_id": "5101cac2-a24e-4342-975a-74df63071328", "storage_path": "5101cac2-a24e-4342-975a-74df63071328/1789125094859.jpg", "application_number": "MEMAPP-000008"}', NULL, '2026-09-11 11:11:36.886886+00'),
	('c2bf2ab0-d616-47cf-b4d0-70df69fb9b70', '96f15dbd-e885-4f42-8f55-492bd72cd515', 'MEMBERSHIP_APPLICATION_APPROVED', 'members', '87e01037-3229-4ca7-bc94-b5a109e312a5', NULL, '{"profile_id": "5101cac2-a24e-4342-975a-74df63071328", "member_number": "MEM-000009", "application_id": "7e785ac0-2fb8-4ed8-a290-ffc17a517fef"}', NULL, '2026-09-11 11:13:02.457996+00'),
	('0fb70be5-82ac-4ce3-a84c-5dbb93eb2698', '64efef4f-1555-4322-80ad-f69e46887516', 'SAVINGS_PAYMENT_SUBMITTED', 'payments', '4d9da62a-9eb8-43d9-bdb2-f1149488e965', NULL, '{"amount": 2000.0, "obligation_id": null, "payment_method": "bank_transfer", "reference_number": "PAY-000011"}', NULL, '2026-09-19 12:29:55.46122+00'),
	('bdc1eb1f-45ec-472a-b5fe-299e35f232cc', '96f15dbd-e885-4f42-8f55-492bd72cd515', 'SAVINGS_PAYMENT_VERIFIED', 'payment', '4d9da62a-9eb8-43d9-bdb2-f1149488e965', '{"status": "pending"}', '{"status": "verified", "transaction_id": "23eecd03-3c02-4654-a77d-f6603810e25d", "mandatory_amount": 0.00, "voluntary_amount": 2000.00}', '{"member_id": "9b5bf983-6cba-40b9-890d-f1af17041ffa"}', '2026-09-19 12:40:37.989294+00'),
	('963d39a4-b661-4383-b0cc-0c0cc124db6b', '5101cac2-a24e-4342-975a-74df63071328', 'SAVINGS_PAYMENT_SUBMITTED', 'payments', 'dd2e9149-e9a4-4251-b39c-0de7387de25c', NULL, '{"amount": 2000.0, "obligation_id": "7f6a0d71-60c2-41a2-8297-ab0339814082", "payment_method": "bank_transfer", "reference_number": "PAY-000013"}', NULL, '2026-09-19 13:12:24.949084+00'),
	('7dc1908a-858c-4ca1-9a15-8ae090a54d62', '96f15dbd-e885-4f42-8f55-492bd72cd515', 'SAVINGS_PAYMENT_VERIFIED', 'payment', 'dd2e9149-e9a4-4251-b39c-0de7387de25c', '{"status": "pending"}', '{"status": "verified", "transaction_id": "44fa0ffe-6485-4930-b3fa-5d6baeab606a", "mandatory_amount": 2000.00, "voluntary_amount": 0.00}', '{"member_id": "87e01037-3229-4ca7-bc94-b5a109e312a5"}', '2026-09-19 13:15:05.346032+00'),
	('66f04a7b-bb77-4b86-9922-4b7c872136a3', NULL, 'SAVINGS_LATE_OBLIGATIONS_PROCESSED', 'savings_obligations', NULL, NULL, '{"member_id": "87e01037-3229-4ca7-bc94-b5a109e312a5", "as_of_date": "2026-09-19", "penalty_rate": 0.1000, "processed_count": 1}', NULL, '2026-09-19 18:57:59.328849+00'),
	('515d022b-7b28-485d-beca-9049c869c7d5', '64efef4f-1555-4322-80ad-f69e46887516', 'SAVINGS_WITHDRAWAL_REQUESTED', 'withdrawal_requests', 'f07eb52a-53b9-46f3-9d1a-6ace266d765e', NULL, '{"amount": 8345.0, "reason": null, "member_id": "9b5bf983-6cba-40b9-890d-f1af17041ffa"}', NULL, '2026-09-21 12:52:11.060758+00'),
	('62c893e0-9192-4ea2-9e55-e306bd41c25d', '64efef4f-1555-4322-80ad-f69e46887516', 'SAVINGS_WITHDRAWAL_CANCELLED', 'withdrawal_requests', 'f07eb52a-53b9-46f3-9d1a-6ace266d765e', NULL, '{"member_id": "9b5bf983-6cba-40b9-890d-f1af17041ffa"}', NULL, '2026-09-21 12:52:25.145815+00'),
	('8bf14a5d-3387-490c-b52e-a9df737bb02e', '5101cac2-a24e-4342-975a-74df63071328', 'SAVINGS_PAYMENT_SUBMITTED', 'payments', '5466e990-f3e9-47e3-9bf9-cef346bd10ec', NULL, '{"amount": 2200.0, "obligation_id": "7f6a0d71-60c2-41a2-8297-ab0339814082", "payment_method": "wallet", "reference_number": "PAY-20260921-000007"}', NULL, '2026-09-21 14:23:15.504384+00'),
	('379adb72-eb78-45ce-916d-a0ef457061e8', '96f15dbd-e885-4f42-8f55-492bd72cd515', 'SAVINGS_PAYMENT_VERIFIED', 'payment', '5466e990-f3e9-47e3-9bf9-cef346bd10ec', '{"status": "pending"}', '{"status": "verified", "transaction_id": "ac7a7879-9c87-42c6-9f74-8643457075fc", "mandatory_amount": 2000.00, "voluntary_amount": 200.00}', '{"member_id": "87e01037-3229-4ca7-bc94-b5a109e312a5"}', '2026-09-21 15:36:06.095985+00'),
	('d9394ce0-9d99-4686-87da-ce5e75c73125', '96f15dbd-e885-4f42-8f55-492bd72cd515', 'SAVINGS_OBLIGATIONS_GENERATED', 'savings_obligation_batch', NULL, NULL, NULL, '{"due_date": "2026-08-12", "period_year": 2026, "period_month": 8, "created_count": 3, "required_amount": 2000.00}', '2026-09-21 15:43:32.082582+00'),
	('df0bbdbb-b2e0-49c6-97be-ccfff9b38488', NULL, 'SAVINGS_LATE_OBLIGATIONS_PROCESSED', 'savings_obligations', NULL, NULL, '{"member_id": "87e01037-3229-4ca7-bc94-b5a109e312a5", "as_of_date": "2026-09-21", "penalty_rate": 0.1000, "processed_count": 1}', NULL, '2026-09-21 15:50:03.240025+00'),
	('6dca3189-b5b0-4e02-a367-97782be6f769', NULL, 'SAVINGS_LATE_OBLIGATIONS_PROCESSED', 'savings_obligations', NULL, NULL, '{"member_id": "9b5bf983-6cba-40b9-890d-f1af17041ffa", "as_of_date": "2026-09-21", "penalty_rate": 0.1000, "processed_count": 1}', NULL, '2026-09-21 15:58:33.373276+00'),
	('51c6d432-78d9-44d6-bb09-d22dbd07b8c3', NULL, 'SAVINGS_LATE_OBLIGATIONS_PROCESSED', 'savings_obligations', NULL, NULL, '{"member_id": "a69eafab-eb8a-435c-8e0c-d3b22fa3b8f9", "as_of_date": "2026-09-21", "penalty_rate": 0.1000, "processed_count": 1}', NULL, '2026-09-21 16:02:40.739173+00'),
	('5a8c9f8e-169a-4d5c-9421-fbb591f56382', '96f15dbd-e885-4f42-8f55-492bd72cd515', 'SAVINGS_OBLIGATIONS_GENERATED', 'savings_obligation_batch', NULL, NULL, NULL, '{"due_date": "2026-08-12", "period_year": 2026, "period_month": 8, "created_count": 3, "required_amount": 2000.00}', '2026-09-22 12:41:42.792258+00'),
	('9136c627-32bf-4c52-92ad-8fce55b7d697', NULL, 'SAVINGS_LATE_OBLIGATIONS_PROCESSED', 'savings_obligations', NULL, NULL, '{"member_id": "9b5bf983-6cba-40b9-890d-f1af17041ffa", "as_of_date": "2026-09-22", "penalty_rate": 0.1000, "processed_count": 1}', NULL, '2026-09-22 12:42:11.127297+00'),
	('7d1ab36f-7efc-40a5-be42-50c9a1b7da0b', '64efef4f-1555-4322-80ad-f69e46887516', 'SAVINGS_PAYMENT_SUBMITTED', 'payments', '9875ebd6-1669-40a5-9e62-9bcfe2998350', NULL, '{"amount": 2200.0, "obligation_id": "3ee6802f-d7a3-4184-97ef-90ae28f5f916", "payment_method": "wallet", "reference_number": "PAY-20260922-000008"}', NULL, '2026-09-22 12:44:53.399229+00'),
	('cf8c8049-ff55-4a0d-b1cf-90ed43c80535', '96f15dbd-e885-4f42-8f55-492bd72cd515', 'SAVINGS_PAYMENT_VERIFIED', 'payment', '9875ebd6-1669-40a5-9e62-9bcfe2998350', '{"status": "pending"}', '{"status": "verified", "transaction_id": "f2eaeb97-6212-476e-be28-7ea992948639", "mandatory_amount": 2000.00, "voluntary_amount": 0.00, "late_payment_amount": 200.00}', '{"payment_id": "9875ebd6-1669-40a5-9e62-9bcfe2998350", "obligation_id": "3ee6802f-d7a3-4184-97ef-90ae28f5f916", "payment_method": "wallet"}', '2026-09-22 13:06:15.904186+00'),
	('bc015930-ea1d-44b0-a7ad-c81860b0771b', NULL, 'SAVINGS_LATE_OBLIGATIONS_PROCESSED', 'savings_obligations', NULL, NULL, '{"member_id": null, "as_of_date": "2026-09-22", "penalty_rate": 0.1000, "processed_count": 2}', NULL, '2026-09-22 13:08:22.10156+00'),
	('b877e17f-45a9-42a2-9f46-ac2f9d6f3b7f', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', 'SAVINGS_PAYMENT_SUBMITTED', 'payments', '5fdc0d24-755f-45fb-889d-60ac33af196f', NULL, '{"amount": 2200.0, "obligation_id": "6dcf8f9b-14fe-4840-a1dc-fbe3903735bb", "payment_method": "bank_transfer", "reference_number": "PAY-20260922-000009"}', NULL, '2026-09-22 14:22:48.566393+00'),
	('430abef0-9c0a-4cee-ae55-1930a993ec23', '96f15dbd-e885-4f42-8f55-492bd72cd515', 'SAVINGS_PAYMENT_VERIFIED', 'payment', '5fdc0d24-755f-45fb-889d-60ac33af196f', '{"status": "pending"}', '{"status": "verified", "transaction_id": "f33b3c82-b543-409b-b6ad-72ee75bfdac0", "mandatory_amount": 2000.00, "voluntary_amount": 0.00, "late_payment_amount": 200.00, "savings_credit_amount": 2000.00}', '{"payment_id": "5fdc0d24-755f-45fb-889d-60ac33af196f", "obligation_id": "6dcf8f9b-14fe-4840-a1dc-fbe3903735bb", "payment_method": "bank_transfer"}', '2026-09-22 14:26:33.667288+00'),
	('0ec542a0-2901-47f5-b128-a4683035f800', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', 'SAVINGS_WITHDRAWAL_REQUESTED', 'withdrawal_requests', '4e719bc0-05fb-4a60-90e5-03c4177d39df', NULL, '{"amount": 4000.0, "reason": null, "member_id": "a69eafab-eb8a-435c-8e0c-d3b22fa3b8f9"}', NULL, '2026-09-22 15:00:44.345509+00'),
	('55e61746-afb4-40bb-8d75-5b8cc3cefed5', '96f15dbd-e885-4f42-8f55-492bd72cd515', 'SAVINGS_WITHDRAWAL_DELAYED', 'withdrawal_request', '4e719bc0-05fb-4a60-90e5-03c4177d39df', '{"status": "pending"}', '{"reason": "lets wait for some time. cause we are in short of cash", "status": "delayed"}', '{}', '2026-09-22 15:02:37.846583+00'),
	('6f3ef1e5-262c-4099-becc-a50729949450', '96f15dbd-e885-4f42-8f55-492bd72cd515', 'LOAN_APPLICATION_APPROVAL_RECORDED', 'loan_application', '0cdb78af-986a-42d6-81c0-530fdab26a65', NULL, '{"decision": "approved", "approval_count": 1, "approved_amount": 6000.00, "application_status": "under_review"}', '{"liquidity_snapshot": {"overdue_loans": 0, "available_cash": 18945.00, "loanable_funds": 13441.50, "required_reserve": 5503.50, "outstanding_loans": 0.00, "reserve_compliant": true, "total_member_savings": 18345.00, "liquidity_reserve_rate": 0.300000}}', '2026-09-22 15:05:57.088044+00'),
	('69c4c31e-44b1-4c2f-b4ea-64fe4c7f4843', '3f3e0eb5-aeb1-4999-bd98-18543b01b613', 'ADMIN_BOOTSTRAP', 'user_roles', '3f3e0eb5-aeb1-4999-bd98-18543b01b613', NULL, '{"role": "admin", "email": "dir@gmail.com"}', NULL, '2026-09-22 15:20:09.895998+00'),
	('5b866731-0c6a-450b-b8bb-9ae8b864455d', '3f3e0eb5-aeb1-4999-bd98-18543b01b613', 'LOAN_APPLICATION_APPROVAL_RECORDED', 'loan_application', '0cdb78af-986a-42d6-81c0-530fdab26a65', NULL, '{"decision": "approved", "approval_count": 2, "approved_amount": 6000.00, "application_status": "approved"}', '{"liquidity_snapshot": {"overdue_loans": 0, "available_cash": 18945.00, "loanable_funds": 13441.50, "required_reserve": 5503.50, "outstanding_loans": 0.00, "reserve_compliant": true, "total_member_savings": 18345.00, "liquidity_reserve_rate": 0.300000}}', '2026-09-22 15:56:39.947211+00'),
	('78be0766-6ce4-48af-b6dd-e01591c36bd4', '3f3e0eb5-aeb1-4999-bd98-18543b01b613', 'LOAN_DISBURSED', 'loan', '697e0b5c-c35b-4cb4-8039-73442c477157', NULL, '{"loan_id": "697e0b5c-c35b-4cb4-8039-73442c477157", "principal": 6000.00, "term_months": 3, "borrower_type": "member", "application_id": "0cdb78af-986a-42d6-81c0-530fdab26a65", "source_account": "bank", "total_repayment": 6600.00, "service_charge_rate": 0.1000, "service_charge_amount": 600.00}', '{"transaction_id": "700e7d94-d576-4742-bf75-b00a560031f1", "disbursement_id": "4b71948f-5f57-4667-9663-d70e348c5ec9", "liquidity_snapshot": {"overdue_loans": 0, "available_cash": 18945.00, "loanable_funds": 13441.50, "required_reserve": 5503.50, "outstanding_loans": 0.00, "reserve_compliant": true, "total_member_savings": 18345.00, "liquidity_reserve_rate": 0.300000}}', '2026-09-22 16:18:39.308957+00'),
	('490920a0-057c-466b-a4d5-c7b2059d40fd', '96f15dbd-e885-4f42-8f55-492bd72cd515', 'LOAN_APPLICATION_REJECTED', 'loan_application', 'b0a6c37f-7e99-461a-a710-fb4562181f03', '{"id": "b0a6c37f-7e99-461a-a710-fb4562181f03", "status": "submitted", "purpose": "ddxsdd", "hard_cap": 20000.00, "member_id": "9b5bf983-6cba-40b9-890d-f1af17041ffa", "created_at": "2026-09-22T16:27:17.765304+00:00", "updated_at": "2026-09-22T16:27:17.765304+00:00", "approved_at": null, "reviewed_at": null, "term_months": 3, "submitted_at": "2026-09-22T16:27:17.765304+00:00", "approved_amount": null, "loan_product_id": "6f7eb374-83d8-4c9b-80b6-f7ebe9650d7e", "requested_amount": 6000.00, "application_number": "LOANAPP-000003", "eligibility_status": null, "service_charge_rate": 0.1000, "applicant_profile_id": "64efef4f-1555-4322-80ad-f69e46887516", "approved_term_months": null, "eligibility_snapshot": {"term_months": 3, "borrower_type": "member", "total_repayment": 6600.00, "requested_amount": 6000.00, "loan_model_version": "v2", "guarantor_member_id": "a69eafab-eb8a-435c-8e0c-d3b22fa3b8f9", "service_charge_rate": 0.1000, "service_charge_amount": 600.00, "member_max_loan_at_submission": 20000.00, "member_total_savings_at_submission": 10345.00}, "approved_rule_snapshot": null, "eligibility_evaluated_at": null, "approved_service_charge_rate": null}', '{"reason": "you already have an active loan", "status": "rejected"}', '{}', '2026-09-24 13:27:13.843168+00'),
	('9d561a4e-203a-4842-aeb5-90636377e804', '99c968a2-142f-4329-935d-ef240a5a40f5', 'MEMBERSHIP_APPLICATION_SUBMITTED', 'membership_application', 'aab5140b-c41d-4518-9067-d64922ebb003', NULL, '{"applicant_id": "99c968a2-142f-4329-935d-ef240a5a40f5", "storage_path": "99c968a2-142f-4329-935d-ef240a5a40f5/1790356818906.png", "application_number": "MEMAPP-000003"}', NULL, '2026-09-25 17:26:18.291599+00'),
	('8374ce8b-f105-478f-bba0-d7cecae7d2aa', '96f15dbd-e885-4f42-8f55-492bd72cd515', 'MEMBERSHIP_APPLICATION_APPROVED', 'members', '92e3f6fb-0b10-4ea2-9212-c2b470c6221b', NULL, '{"profile_id": "99c968a2-142f-4329-935d-ef240a5a40f5", "member_number": "MEM-000004", "application_id": "aab5140b-c41d-4518-9067-d64922ebb003"}', NULL, '2026-09-25 17:27:16.225866+00'),
	('e1674566-2248-401f-8e90-b8c14da4d9c6', NULL, 'SAVINGS_LATE_OBLIGATIONS_PROCESSED', 'savings_obligations', NULL, NULL, '{"member_id": "92e3f6fb-0b10-4ea2-9212-c2b470c6221b", "as_of_date": "2026-09-25", "penalty_rate": 0.1000, "processed_count": 1}', NULL, '2026-09-25 17:27:23.440589+00'),
	('dc798190-9c97-47ed-b464-bceb63704caf', '8a4f38eb-af53-4d05-8ab1-0e332e022710', 'ADMIN_BOOTSTRAP', 'user_roles', '8a4f38eb-af53-4d05-8ab1-0e332e022710', NULL, '{"role": "admin", "phone": "+251933333333"}', NULL, '2026-09-26 13:27:42.77685+00'),
	('b1274d0e-ec91-4158-817d-2581b6b4cefb', '64efef4f-1555-4322-80ad-f69e46887516', 'LOAN_REPAYMENT_SUBMITTED', 'loan_repayment_submission', '66e80012-ee57-42ca-a95c-dea4eb730168', NULL, '{"amount": 2200.00, "loan_id": "697e0b5c-c35b-4cb4-8039-73442c477157", "borrower_type": "member"}', '{}', '2026-09-26 15:52:15.283211+00'),
	('af86b5f1-ab92-483a-aaf0-b1ead5146df2', '64efef4f-1555-4322-80ad-f69e46887516', 'LOAN_REPAYMENT_SUBMITTED', 'loan_repayment_submission', '1edf7577-115b-4e43-9847-47fb40c75d08', NULL, '{"amount": 2200.00, "loan_id": "697e0b5c-c35b-4cb4-8039-73442c477157", "borrower_type": "member"}', '{}', '2026-09-26 15:57:47.118747+00'),
	('15c6d511-c41f-4d04-bd0c-5a5fdc8ed248', '8a4f38eb-af53-4d05-8ab1-0e332e022710', 'LOAN_REPAYMENT_VERIFIED', 'loan_repayment_submission', '1edf7577-115b-4e43-9847-47fb40c75d08', '{"id": "1edf7577-115b-4e43-9847-47fb40c75d08", "amount": 2200.00, "status": "pending", "loan_id": "697e0b5c-c35b-4cb4-8039-73442c477157", "created_at": "2026-09-26T15:57:47.118747+00:00", "payer_name": "Abdulaz", "payment_id": "5f364a75-76fc-443e-a958-86c8fa5485b2", "updated_at": "2026-09-26T15:57:47.118747+00:00", "payer_phone": "+251721777648", "reversed_at": null, "verified_at": null, "verified_by": null, "submitted_at": "2026-09-26T15:57:47.118747+00:00", "submitted_by": "64efef4f-1555-4322-80ad-f69e46887516", "borrower_type": "member", "rejected_reason": null, "payer_profile_id": "64efef4f-1555-4322-80ad-f69e46887516", "external_reference": null, "payment_proof_path": "loan_payments/64efef4f-1555-4322-80ad-f69e46887516/1790437906704_Screenshot_20260919-103703.png", "payment_method_code": "bank", "posted_transaction_id": null, "reversal_transaction_id": null}', '{"status": "verified", "submission_id": "1edf7577-115b-4e43-9847-47fb40c75d08"}', '{"external_reference": null}', '2026-09-26 16:42:31.29729+00'),
	('7a22b340-5277-4616-9e03-43c9386c48ec', '8a4f38eb-af53-4d05-8ab1-0e332e022710', 'LOAN_REPAYMENT_POSTED', 'loan', '697e0b5c-c35b-4cb4-8039-73442c477157', NULL, '{"base_amount": 2200.00, "total_amount": 2200.00, "submission_id": "1edf7577-115b-4e43-9847-47fb40c75d08", "penalty_amount": 0.00}', '{"transaction_id": "8511fbdd-a716-4570-8b39-3d1ca411f376"}', '2026-09-26 16:51:55.854226+00'),
	('65d66f4a-1cae-4409-aa49-53ef9c608073', '8a4f38eb-af53-4d05-8ab1-0e332e022710', 'LOAN_APPLICATION_REJECTED', 'loan_application', 'e621f41a-2e83-4be1-9e3e-1810c9e9bbfb', '{"id": "e621f41a-2e83-4be1-9e3e-1810c9e9bbfb", "status": "submitted", "purpose": "I needed it\nI needed it", "hard_cap": 20000.00, "member_id": "a69eafab-eb8a-435c-8e0c-d3b22fa3b8f9", "created_at": "2026-09-24T13:25:25.848016+00:00", "updated_at": "2026-09-24T13:25:25.848016+00:00", "approved_at": null, "reviewed_at": null, "term_months": 3, "submitted_at": "2026-09-24T13:25:25.848016+00:00", "approved_amount": null, "loan_product_id": "6f7eb374-83d8-4c9b-80b6-f7ebe9650d7e", "requested_amount": 5407.50, "application_number": "LOANAPP-000004", "eligibility_status": null, "service_charge_rate": 0.1000, "applicant_profile_id": "a5c1a9c8-6ccd-49c2-a069-2781c83be09d", "approved_term_months": null, "eligibility_snapshot": {"term_months": 3, "borrower_type": "member", "total_repayment": 5948.25, "requested_amount": 5407.50, "loan_model_version": "v2", "guarantor_member_id": "9b5bf983-6cba-40b9-890d-f1af17041ffa", "service_charge_rate": 0.1000, "service_charge_amount": 540.75, "member_max_loan_at_submission": 8000.00, "member_total_savings_at_submission": 4000.00}, "approved_rule_snapshot": null, "eligibility_evaluated_at": null, "approved_service_charge_rate": null}', '{"reason": "noooooooooooooo", "status": "rejected"}', '{}', '2026-09-28 13:16:39.754257+00'),
	('5008bd6f-4760-4653-ae97-ebfc06fa54ff', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', 'LOAN_APPLICATION_CANCELLED', 'loan_application', '60c3f83e-74be-49c2-a00a-233096fa8240', NULL, '{"status": "cancelled", "cancelled_by": "applicant", "application_id": "60c3f83e-74be-49c2-a00a-233096fa8240"}', NULL, '2026-09-28 13:42:37.651515+00'),
	('71982796-d2c9-4d9b-9717-ea1b2a9992b0', '8a4f38eb-af53-4d05-8ab1-0e332e022710', 'EXPENSE_CREATED', 'expense', '2179f5d1-1162-40ca-9e2e-a878713e5371', NULL, '{"amount": 1600.00, "status": "pending", "category": "For data", "reference_number": "EXP-20260928-000001"}', '{}', '2026-09-28 16:22:27.13749+00'),
	('9f8a1858-e433-4176-8e95-e3099fa060fd', '96f15dbd-e885-4f42-8f55-492bd72cd515', 'EXPENSE_APPROVED', 'expense', '2179f5d1-1162-40ca-9e2e-a878713e5371', '{"status": "pending"}', '{"status": "approved", "approved_by": "96f15dbd-e885-4f42-8f55-492bd72cd515"}', '{"comment": "I consent"}', '2026-09-28 16:24:36.989799+00'),
	('97465fd3-2c7e-4800-85f0-897b33ba6cf8', '96f15dbd-e885-4f42-8f55-492bd72cd515', 'EXPENSE_PAID', 'expense', '2179f5d1-1162-40ca-9e2e-a878713e5371', '{"status": "approved"}', '{"status": "paid", "transaction_id": "81bed6cf-68fc-4f4c-8452-2bb90e86b135"}', '{"amount": 1600.00, "source_account_id": "fe1846e1-6150-4591-95c0-a9e10ef11993", "source_account_type": "bank", "source_balance_before": 8745.00}', '2026-09-28 16:44:21.403363+00'),
	('54b60976-4861-4c9b-8feb-33c466881aab', '96f15dbd-e885-4f42-8f55-492bd72cd515', 'EXPENSE_CREATED', 'expense', '50add1bc-6234-4bf8-a1ab-7694cc6df5cf', NULL, '{"amount": 1234.00, "status": "pending", "category": "ddccc", "reference_number": "EXP-20260928-000002"}', '{}', '2026-09-28 16:47:52.552178+00'),
	('5e463fa5-0c3e-4999-98cb-a45da1896eea', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', 'LOAN_APPLICATION_CANCELLED', 'loan_application', 'f12c3664-510a-4d1a-93f8-691076167044', NULL, '{"status": "cancelled", "cancelled_by": "applicant", "application_id": "f12c3664-510a-4d1a-93f8-691076167044"}', NULL, '2026-09-30 07:23:27.075879+00'),
	('e309090a-275b-4265-acbe-4970300014a4', '3f3e0eb5-aeb1-4999-bd98-18543b01b613', 'LOAN_APPLICATION_APPROVAL_RECORDED', 'loan_application', '03a1d0ee-7937-44ab-88f8-41143424864c', NULL, '{"decision": "approved", "approval_count": 1, "approved_amount": 4000.00, "application_status": "under_review"}', '{"liquidity_snapshot": {"overdue_loans": 0, "available_cash": 13545.00, "loanable_funds": 8041.50, "required_reserve": 5503.50, "outstanding_loans": 4400.00, "reserve_compliant": true, "total_member_savings": 18345.00, "liquidity_reserve_rate": 0.300000}}', '2026-09-30 07:37:30.781748+00'),
	('f57ade36-863f-4c75-b975-ac8fa82bea97', '96f15dbd-e885-4f42-8f55-492bd72cd515', 'LOAN_APPLICATION_REJECTED', 'loan_application', '03a1d0ee-7937-44ab-88f8-41143424864c', '{"id": "03a1d0ee-7937-44ab-88f8-41143424864c", "status": "under_review", "purpose": "hey the SC", "hard_cap": 20000.00, "member_id": "a69eafab-eb8a-435c-8e0c-d3b22fa3b8f9", "created_at": "2026-09-30T07:28:39.727272+00:00", "updated_at": "2026-09-30T07:37:30.781748+00:00", "approved_at": null, "reviewed_at": null, "term_months": 3, "submitted_at": "2026-09-30T07:28:39.727272+00:00", "approved_amount": 4000.00, "loan_product_id": "6f7eb374-83d8-4c9b-80b6-f7ebe9650d7e", "requested_amount": 4948.01, "application_number": "LOANAPP-000007", "eligibility_status": null, "service_charge_rate": 0.1000, "applicant_profile_id": "a5c1a9c8-6ccd-49c2-a069-2781c83be09d", "approved_term_months": 3, "eligibility_snapshot": {"term_months": 3, "borrower_type": "member", "total_repayment": 5442.81, "requested_amount": 4948.01, "loan_model_version": "v2", "guarantor_member_id": "87e01037-3229-4ca7-bc94-b5a109e312a5", "service_charge_rate": 0.1000, "service_charge_amount": 494.80, "member_max_loan_at_submission": 8000.00, "member_total_savings_at_submission": 4000.00}, "approved_rule_snapshot": {"hard_cap": 20000.00, "product_id": "6f7eb374-83d8-4c9b-80b6-f7ebe9650d7e", "captured_at": "2026-09-30T07:37:30.781748+00:00", "term_months": 3, "approved_amount": 4000.00, "service_charge_rate": 0.1000}, "eligibility_evaluated_at": null, "approved_service_charge_rate": 0.1000}', '{"reason": "you dont deserve this much bro", "status": "rejected"}', '{}', '2026-09-30 07:42:15.803199+00'),
	('fc87ad0a-239c-42a7-b777-116b2b84446a', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', 'SAVINGS_PAYMENT_SUBMITTED', 'payments', '90128ce8-6cf9-4f12-95bb-e8726784195f', NULL, '{"amount": 12400.0, "obligation_id": null, "payment_method": "bank_transfer", "reference_number": "PAY-20260930-000017"}', NULL, '2026-09-30 08:17:13.323569+00'),
	('05154f83-d834-4c8f-8804-73df0383b793', '96f15dbd-e885-4f42-8f55-492bd72cd515', 'SAVINGS_PAYMENT_VERIFIED', 'payment', '90128ce8-6cf9-4f12-95bb-e8726784195f', '{"status": "pending"}', '{"status": "verified", "transaction_id": "196244e5-92dc-4450-aa1a-e33fff633d58", "mandatory_amount": 0.00, "voluntary_amount": 12400.00, "late_payment_amount": 0.00, "savings_credit_amount": 12400.00}', '{"payment_id": "90128ce8-6cf9-4f12-95bb-e8726784195f", "obligation_id": null, "payment_method": "bank_transfer"}', '2026-09-30 08:18:46.015939+00'),
	('d6ebb166-7456-4888-8363-ff2ce0cef7a0', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', 'SAVINGS_PAYMENT_SUBMITTED', 'payments', 'fc3c775c-b1bd-4791-ae85-98bb2dea4246', NULL, '{"amount": 100.0, "obligation_id": null, "payment_method": "bank_transfer", "reference_number": "PAY-20260930-000018"}', NULL, '2026-09-30 08:40:55.575632+00'),
	('37db1d42-4ee7-4f5f-ab94-c7173de1cf33', '96f15dbd-e885-4f42-8f55-492bd72cd515', 'SAVINGS_PAYMENT_VERIFIED', 'payment', 'fc3c775c-b1bd-4791-ae85-98bb2dea4246', '{"status": "pending"}', '{"status": "verified", "transaction_id": "a419bf0e-402d-4835-a411-0a634ac90fcf", "mandatory_amount": 0.00, "voluntary_amount": 100.00, "late_payment_amount": 0.00, "savings_credit_amount": 100.00}', '{"payment_id": "fc3c775c-b1bd-4791-ae85-98bb2dea4246", "obligation_id": null, "payment_method": "bank_transfer"}', '2026-09-30 08:41:15.423581+00'),
	('955b43fa-5b85-4b12-b92c-3143770499cf', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', 'SAVINGS_PAYMENT_SUBMITTED', 'payments', 'c62d9849-de57-4887-9b0d-2c9f26dd8451', NULL, '{"amount": 200.0, "obligation_id": null, "payment_method": "bank_transfer", "reference_number": "PAY-20260930-000019"}', NULL, '2026-09-30 08:46:56.45777+00'),
	('22954185-7816-4e9d-b49d-3bdd10b51cdb', '96f15dbd-e885-4f42-8f55-492bd72cd515', 'SAVINGS_PAYMENT_VERIFIED', 'payment', 'c62d9849-de57-4887-9b0d-2c9f26dd8451', '{"status": "pending"}', '{"status": "verified", "transaction_id": "2a382a5e-f668-4e12-bda5-6ef067f89763", "mandatory_amount": 0.00, "voluntary_amount": 200.00, "late_payment_amount": 0.00, "savings_credit_amount": 200.00}', '{"payment_id": "c62d9849-de57-4887-9b0d-2c9f26dd8451", "obligation_id": null, "payment_method": "bank_transfer"}', '2026-09-30 08:47:55.755996+00'),
	('bd27e6a9-89d8-4bb2-ac3a-77a6a23400ef', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', 'SAVINGS_PAYMENT_SUBMITTED', 'payments', 'a0a448fd-f5b8-41f9-9068-1127464e5efe', NULL, '{"amount": 580.0, "obligation_id": null, "payment_method": "bank_transfer", "reference_number": "PAY-20260930-000020"}', NULL, '2026-09-30 08:49:26.849124+00'),
	('765943e2-00b7-4f28-96dd-a541f10734cd', '96f15dbd-e885-4f42-8f55-492bd72cd515', 'SAVINGS_PAYMENT_VERIFIED', 'payment', 'a0a448fd-f5b8-41f9-9068-1127464e5efe', '{"status": "pending"}', '{"status": "verified", "transaction_id": "65dad621-b951-44e7-8549-3e0591b96cfb", "mandatory_amount": 0.00, "voluntary_amount": 580.00, "late_payment_amount": 0.00, "savings_credit_amount": 580.00}', '{"payment_id": "a0a448fd-f5b8-41f9-9068-1127464e5efe", "obligation_id": null, "payment_method": "bank_transfer"}', '2026-09-30 08:49:48.76956+00'),
	('39acaa93-eaae-4736-94c0-594c372b128a', '3f3e0eb5-aeb1-4999-bd98-18543b01b613', 'SAVINGS_OBLIGATIONS_GENERATED', 'savings_obligation_batch', NULL, NULL, NULL, '{"due_date": "2026-10-12", "period_year": 2026, "period_month": 10, "created_count": 4, "required_amount": 2000.00}', '2026-10-01 15:50:33.833355+00'),
	('64f52fd1-de89-44d2-a626-b069ae95b73c', '64efef4f-1555-4322-80ad-f69e46887516', 'SAVINGS_PAYMENT_SUBMITTED', 'payments', '57f2ec0e-eb9f-4d31-990b-5dd46702af69', NULL, '{"amount": 2000.0, "obligation_id": "58b6cd59-a675-4cac-8205-c3d7c0eb9507", "payment_method": "bank_transfer", "reference_number": "PAY-20261003-000021"}', NULL, '2026-10-03 13:21:50.452275+00'),
	('34c7b517-18f7-4eb8-9322-7b7301d88854', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', 'LOAN_APPLICATION_CANCELLED', 'loan_application', '0fd40d1b-c1f4-4d22-a60c-0bd8ee8d68ab', NULL, '{"status": "cancelled", "cancelled_by": "applicant", "application_id": "0fd40d1b-c1f4-4d22-a60c-0bd8ee8d68ab"}', NULL, '2026-10-03 14:04:19.379102+00'),
	('7b65af91-b601-4512-9976-9399b1530890', '64efef4f-1555-4322-80ad-f69e46887516', 'LOAN_REPAYMENT_SUBMITTED', 'loan_repayment_submission', '7265b741-ecf0-4bff-9bee-66ac8e6c6f48', NULL, '{"amount": 2200.00, "loan_id": "697e0b5c-c35b-4cb4-8039-73442c477157", "borrower_type": "member"}', '{}', '2026-10-03 14:23:22.914562+00'),
	('4bda2481-80bb-4bbf-946a-75938d0137cf', '3f3e0eb5-aeb1-4999-bd98-18543b01b613', 'LOAN_REPAYMENT_VERIFIED', 'loan_repayment_submission', '7265b741-ecf0-4bff-9bee-66ac8e6c6f48', '{"id": "7265b741-ecf0-4bff-9bee-66ac8e6c6f48", "amount": 2200.00, "status": "pending", "loan_id": "697e0b5c-c35b-4cb4-8039-73442c477157", "created_at": "2026-10-03T14:23:22.914562+00:00", "payer_name": "Abdulaz", "payment_id": "deb9ae8b-6df9-421d-8ad9-0bdb7ea90b9e", "updated_at": "2026-10-03T14:23:22.914562+00:00", "payer_phone": "+251721777648", "reversed_at": null, "verified_at": null, "verified_by": null, "submitted_at": "2026-10-03T14:23:22.914562+00:00", "submitted_by": "64efef4f-1555-4322-80ad-f69e46887516", "borrower_type": "member", "rejected_reason": null, "payer_profile_id": "64efef4f-1555-4322-80ad-f69e46887516", "external_reference": null, "payment_proof_path": "loan_payments/64efef4f-1555-4322-80ad-f69e46887516/1791037244135_Screenshot_20261003-171957.png", "payment_method_code": "bank", "posted_transaction_id": null, "reversal_transaction_id": null}', '{"status": "verified", "submission_id": "7265b741-ecf0-4bff-9bee-66ac8e6c6f48"}', '{"external_reference": null}', '2026-10-11 13:11:33.658994+00'),
	('f32d0fff-be51-4b60-bde3-e99dda47ca78', '3f3e0eb5-aeb1-4999-bd98-18543b01b613', 'LOAN_REPAYMENT_POSTED', 'loan', '697e0b5c-c35b-4cb4-8039-73442c477157', NULL, '{"base_amount": 2200.00, "total_amount": 2200.00, "submission_id": "7265b741-ecf0-4bff-9bee-66ac8e6c6f48", "penalty_amount": 0.00}', '{"transaction_id": "a4e82a41-a3a2-4bdb-82c5-ea870f9a2403"}', '2026-10-11 13:11:43.266207+00'),
	('fe1e615d-9cbd-4b82-b13e-dd6b670c0671', 'a9e748d4-dc2b-4d5b-9571-2e2f2bc78e0d', 'MEMBERSHIP_APPLICATION_SUBMITTED', 'membership_application', '0f57a0eb-b419-4c0a-bf6f-2862268dcfb8', NULL, '{"applicant_id": "a9e748d4-dc2b-4d5b-9571-2e2f2bc78e0d", "storage_path": "a9e748d4-dc2b-4d5b-9571-2e2f2bc78e0d/1791726259927.jpg", "application_number": "MEMAPP-000004"}', NULL, '2026-10-11 13:44:56.288231+00'),
	('363b2938-7958-41f7-9df3-7cd2a4307738', '3f3e0eb5-aeb1-4999-bd98-18543b01b613', 'MEMBERSHIP_APPLICATION_APPROVED', 'members', '80ea84c9-313d-4927-b066-4fcdd6116226', NULL, '{"profile_id": "a9e748d4-dc2b-4d5b-9571-2e2f2bc78e0d", "member_number": "MEM-000005", "application_id": "0f57a0eb-b419-4c0a-bf6f-2862268dcfb8"}', NULL, '2026-10-11 13:46:24.918799+00'),
	('79c073e3-868a-4270-84ba-3ea804e34f0a', '3f3e0eb5-aeb1-4999-bd98-18543b01b613', 'SAVINGS_OBLIGATIONS_GENERATED', 'savings_obligation_batch', NULL, NULL, NULL, '{"due_date": "2026-05-12", "period_year": 2026, "period_month": 5, "created_count": 5, "required_amount": 2000.00}', '2026-10-11 13:56:39.042672+00'),
	('b33a6ae9-9687-466d-94e3-4b536c6d5d93', NULL, 'SAVINGS_LATE_OBLIGATIONS_PROCESSED', 'savings_obligations', NULL, NULL, '{"member_id": "80ea84c9-313d-4927-b066-4fcdd6116226", "as_of_date": "2026-10-11", "penalty_rate": 0.1000, "processed_count": 1}', NULL, '2026-10-11 13:56:45.734596+00'),
	('91415e31-058b-427e-addd-4b6afe8810c2', 'a9e748d4-dc2b-4d5b-9571-2e2f2bc78e0d', 'SAVINGS_PAYMENT_SUBMITTED', 'payments', 'f9a97b0a-f9ae-44c5-b7e5-3765f58addc9', NULL, '{"amount": 2200.0, "obligation_id": "61ec8353-9223-473a-9d7a-ac0a2a3aead0", "payment_method": "bank_transfer", "reference_number": "PAY-20261011-000023"}', NULL, '2026-10-11 13:59:45.612154+00'),
	('eb87f770-cd6e-47ac-ac93-d0c05e12a341', '3f3e0eb5-aeb1-4999-bd98-18543b01b613', 'SAVINGS_PAYMENT_VERIFIED', 'payment', 'f9a97b0a-f9ae-44c5-b7e5-3765f58addc9', '{"status": "pending"}', '{"status": "verified", "transaction_id": "0005f65d-4b7c-4307-846c-87f9946e452c", "mandatory_amount": 2000.00, "voluntary_amount": 0.00, "late_payment_amount": 200.00, "savings_credit_amount": 2000.00}', '{"payment_id": "f9a97b0a-f9ae-44c5-b7e5-3765f58addc9", "obligation_id": "61ec8353-9223-473a-9d7a-ac0a2a3aead0", "payment_method": "bank_transfer"}', '2026-10-11 14:00:44.040855+00'),
	('f563c654-285b-427b-810a-0f177c85e39f', NULL, 'SAVINGS_LATE_OBLIGATIONS_PROCESSED', 'savings_obligations', NULL, NULL, '{"member_id": "a69eafab-eb8a-435c-8e0c-d3b22fa3b8f9", "as_of_date": "2026-10-12", "penalty_rate": 0.1000, "processed_count": 1}', NULL, '2026-10-12 12:02:00.082692+00'),
	('722081c1-2416-48bb-a86e-d279da656204', NULL, 'SAVINGS_LATE_OBLIGATIONS_PROCESSED', 'savings_obligations', NULL, NULL, '{"member_id": "9b5bf983-6cba-40b9-890d-f1af17041ffa", "as_of_date": "2026-10-12", "penalty_rate": 0.1000, "processed_count": 1}', NULL, '2026-10-12 19:53:52.037205+00'),
	('a41a30b1-0f19-4182-ba81-dae9e63285cd', NULL, 'SAVINGS_LATE_OBLIGATIONS_PROCESSED', 'savings_obligations', NULL, NULL, '{"member_id": "a69eafab-eb8a-435c-8e0c-d3b22fa3b8f9", "as_of_date": "2026-10-13", "penalty_rate": 0.1000, "processed_count": 1}', NULL, '2026-10-13 05:53:03.385181+00');


--
-- Data for Name: expenses; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."expenses" ("id", "reference_number", "category", "amount", "description", "supporting_document_path", "status", "requested_by", "approved_by", "created_at", "approved_at", "paid_at") VALUES
	('2179f5d1-1162-40ca-9e2e-a878713e5371', 'EXP-20260928-000001', 'For data', 1600.00, 'To build Mobile application', NULL, 'paid', '8a4f38eb-af53-4d05-8ab1-0e332e022710', '96f15dbd-e885-4f42-8f55-492bd72cd515', '2026-09-28 16:22:27.13749+00', '2026-09-28 16:24:36.989799+00', '2026-09-28 16:44:21.403363+00'),
	('50add1bc-6234-4bf8-a1ab-7694cc6df5cf', 'EXP-20260928-000002', 'ddccc', 1234.00, 'jhgfdsa', NULL, 'pending', '96f15dbd-e885-4f42-8f55-492bd72cd515', NULL, '2026-09-28 16:47:52.552178+00', NULL, NULL);


--
-- Data for Name: finance_command_idempotency; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."finance_command_idempotency" ("id", "actor_profile_id", "command_type", "idempotency_key", "target_type", "target_id", "status", "response", "created_at", "completed_at") VALUES
	('0246ade1-847d-4263-ae5e-3c10df6d0794', '8a4f38eb-af53-4d05-8ab1-0e332e022710', 'ADMIN_CREATE_EXPENSE', 'd68cadd6-8c4e-4f57-8f45-6f6d60447004', 'expense', NULL, 'completed', '{"status": "pending", "expense_id": "2179f5d1-1162-40ca-9e2e-a878713e5371", "reference_number": "EXP-20260928-000001"}', '2026-09-28 16:22:27.13749+00', '2026-09-28 16:22:27.13749+00'),
	('185eaa7b-381c-45bf-8c3f-c953f47d230a', '96f15dbd-e885-4f42-8f55-492bd72cd515', 'ADMIN_APPROVE_EXPENSE', 'dc86c711-5a1a-40df-bc88-a85dee26a3be', 'expense', '2179f5d1-1162-40ca-9e2e-a878713e5371', 'completed', '{"status": "approved", "expense_id": "2179f5d1-1162-40ca-9e2e-a878713e5371"}', '2026-09-28 16:24:36.989799+00', '2026-09-28 16:24:36.989799+00'),
	('7a96f881-dc1d-4bb4-ab3d-c0f4d879b7a3', '96f15dbd-e885-4f42-8f55-492bd72cd515', 'ADMIN_PAY_EXPENSE', 'e0c45e33-ee7f-467c-a377-439436287621', 'expense', '2179f5d1-1162-40ca-9e2e-a878713e5371', 'completed', '{"amount": 1600.00, "status": "paid", "expense_id": "2179f5d1-1162-40ca-9e2e-a878713e5371", "transaction_id": "81bed6cf-68fc-4f4c-8452-2bb90e86b135", "source_account_id": "fe1846e1-6150-4591-95c0-a9e10ef11993"}', '2026-09-28 16:44:21.403363+00', '2026-09-28 16:44:21.403363+00'),
	('682e4bd5-cc71-4e2c-903c-6bfa36114f75', '96f15dbd-e885-4f42-8f55-492bd72cd515', 'ADMIN_CREATE_EXPENSE', '5edee786-4137-46d9-a8e0-abd72d7dc620', 'expense', NULL, 'completed', '{"status": "pending", "expense_id": "50add1bc-6234-4bf8-a1ab-7694cc6df5cf", "reference_number": "EXP-20260928-000002"}', '2026-09-28 16:47:52.552178+00', '2026-09-28 16:47:52.552178+00');


--
-- Data for Name: financial_rules; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."financial_rules" ("id", "rule_code", "description", "data_type", "active", "created_at") VALUES
	('aab34ec3-11d0-47b0-aebf-8b3708d56039', 'membership_fee', 'Initial membership fee / first required contribution. Confirm exact treatment before production.', 'numeric', true, '2026-08-26 19:36:24.648374+00'),
	('a2a40b23-02dc-4027-b81f-06898c9eb552', 'monthly_min_saving', 'Minimum monthly saving contribution.', 'numeric', true, '2026-08-26 19:36:24.648374+00'),
	('b5f79f9f-23c1-4d18-8602-c258f724049f', 'saving_due_day', 'Day of month by which the minimum saving is due.', 'integer', true, '2026-08-26 19:36:24.648374+00'),
	('fe86904d-8087-4ab0-886b-592f6a111cdd', 'saving_late_penalty_rate', 'Penalty rate for missing the minimum monthly contribution.', 'numeric', true, '2026-08-26 19:36:24.648374+00'),
	('2dd42b94-3ab1-4a84-9b2d-3d47d4d38b6d', 'member_service_charge_rate', 'One-time member loan service charge.', 'numeric', true, '2026-08-26 19:36:24.648374+00'),
	('ac1f959d-8a32-439f-9bbf-8ca71fdceb6f', 'outsider_service_charge_rate', 'One-time outsider loan service charge.', 'numeric', true, '2026-08-26 19:36:24.648374+00'),
	('3728505c-6a50-43f1-95c9-4e614e99aa84', 'max_loan_amount', 'Maximum initial loan amount.', 'numeric', true, '2026-08-26 19:36:24.648374+00'),
	('8e5eec47-22f6-4554-97ea-01bca3e68a0d', 'default_loan_term_months', 'Standard loan term.', 'integer', true, '2026-08-26 19:36:24.648374+00'),
	('793f53ce-22d5-4204-94d6-32bd961df6b3', 'loan_late_penalty_rate', 'Penalty rate for an overdue loan installment.', 'numeric', true, '2026-08-26 19:36:24.648374+00'),
	('5ff0c5c3-0bcd-4f77-9f1c-8028e2719ba8', 'serious_default_days', 'Days after due date before serious default.', 'integer', true, '2026-08-26 19:36:24.648374+00'),
	('c17b42ef-5357-439f-801a-624cafb45037', 'liquidity_reserve_rate', 'Minimum liquidity reserve.', 'numeric', true, '2026-08-26 19:36:24.648374+00');


--
-- Data for Name: financial_rule_versions; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."financial_rule_versions" ("id", "rule_id", "value_numeric", "value_text", "value_boolean", "value_integer", "effective_from", "effective_to", "status", "approved_by", "approved_at", "change_reason", "created_at") VALUES
	('e5b33e47-7d3a-444d-ac71-f74f9c4346ec', 'aab34ec3-11d0-47b0-aebf-8b3708d56039', 500.000000, NULL, NULL, NULL, '2026-08-26 19:36:24.648374+00', NULL, 'active', NULL, '2026-08-26 19:36:24.648374+00', 'Initial MVP seed from approved Unity Finance rules', '2026-08-26 19:36:24.648374+00'),
	('9a7c611f-6b8f-43b7-950f-425ce10fc106', 'a2a40b23-02dc-4027-b81f-06898c9eb552', 2000.000000, NULL, NULL, NULL, '2026-08-26 19:36:24.648374+00', NULL, 'active', NULL, '2026-08-26 19:36:24.648374+00', 'Initial MVP seed from approved Unity Finance rules', '2026-08-26 19:36:24.648374+00'),
	('37dcb522-1d0a-4a3f-9452-dc0db9bcd8a7', 'b5f79f9f-23c1-4d18-8602-c258f724049f', NULL, NULL, NULL, 12, '2026-08-26 19:36:24.648374+00', NULL, 'active', NULL, '2026-08-26 19:36:24.648374+00', 'Initial MVP seed from approved Unity Finance rules', '2026-08-26 19:36:24.648374+00'),
	('50b1b100-4ab1-476d-80d3-164cbeeca182', 'fe86904d-8087-4ab0-886b-592f6a111cdd', 0.100000, NULL, NULL, NULL, '2026-08-26 19:36:24.648374+00', NULL, 'active', NULL, '2026-08-26 19:36:24.648374+00', 'Initial MVP seed from approved Unity Finance rules', '2026-08-26 19:36:24.648374+00'),
	('4001c1bb-f559-457f-b288-1609384e5b14', '2dd42b94-3ab1-4a84-9b2d-3d47d4d38b6d', 0.100000, NULL, NULL, NULL, '2026-08-26 19:36:24.648374+00', NULL, 'active', NULL, '2026-08-26 19:36:24.648374+00', 'Initial MVP seed from approved Unity Finance rules', '2026-08-26 19:36:24.648374+00'),
	('e045ec08-6b4d-4239-b97a-ee6bf25a2908', 'ac1f959d-8a32-439f-9bbf-8ca71fdceb6f', 0.150000, NULL, NULL, NULL, '2026-08-26 19:36:24.648374+00', NULL, 'active', NULL, '2026-08-26 19:36:24.648374+00', 'Initial MVP seed from approved Unity Finance rules', '2026-08-26 19:36:24.648374+00'),
	('040e8a5d-3147-49d6-bf9c-9473549c60c1', '3728505c-6a50-43f1-95c9-4e614e99aa84', 20000.000000, NULL, NULL, NULL, '2026-08-26 19:36:24.648374+00', NULL, 'active', NULL, '2026-08-26 19:36:24.648374+00', 'Initial MVP seed from approved Unity Finance rules', '2026-08-26 19:36:24.648374+00'),
	('54a40bb3-b5c0-4594-8886-aec238c1654a', '8e5eec47-22f6-4554-97ea-01bca3e68a0d', NULL, NULL, NULL, 3, '2026-08-26 19:36:24.648374+00', NULL, 'active', NULL, '2026-08-26 19:36:24.648374+00', 'Initial MVP seed from approved Unity Finance rules', '2026-08-26 19:36:24.648374+00'),
	('d3809fb1-4484-4811-ad7d-1b78553397ae', '793f53ce-22d5-4204-94d6-32bd961df6b3', 0.050000, NULL, NULL, NULL, '2026-08-26 19:36:24.648374+00', NULL, 'active', NULL, '2026-08-26 19:36:24.648374+00', 'Initial MVP seed from approved Unity Finance rules', '2026-08-26 19:36:24.648374+00'),
	('35fda502-8fef-4df3-b28b-19199ba14a2d', '5ff0c5c3-0bcd-4f77-9f1c-8028e2719ba8', NULL, NULL, NULL, 60, '2026-08-26 19:36:24.648374+00', NULL, 'active', NULL, '2026-08-26 19:36:24.648374+00', 'Initial MVP seed from approved Unity Finance rules', '2026-08-26 19:36:24.648374+00'),
	('ecbf3410-f35f-4544-9b26-4d63fc7a8a28', 'c17b42ef-5357-439f-801a-624cafb45037', 0.300000, NULL, NULL, NULL, '2026-08-26 19:36:24.648374+00', NULL, 'active', NULL, '2026-08-26 19:36:24.648374+00', 'Initial MVP seed from approved Unity Finance rules', '2026-08-26 19:36:24.648374+00');


--
-- Data for Name: loan_products; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."loan_products" ("id", "code", "name", "borrower_type", "service_charge_rate", "max_amount", "term_months", "active", "created_at", "updated_at") VALUES
	('6f7eb374-83d8-4c9b-80b6-f7ebe9650d7e', 'member_loan', 'Member Loan', 'member', 0.1000, 20000.00, 3, true, '2026-08-26 19:36:24.648374+00', '2026-09-07 20:40:42.466463+00'),
	('71fabd42-9a94-4970-9c07-56301ec443a1', 'outsider_loan', 'Outsider Loan', 'outsider', 0.1500, 20000.00, 3, true, '2026-08-26 19:36:24.648374+00', '2026-09-07 20:40:42.466463+00');


--
-- Data for Name: loan_applications; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."loan_applications" ("id", "application_number", "applicant_profile_id", "member_id", "loan_product_id", "requested_amount", "purpose", "eligibility_status", "status", "submitted_at", "created_at", "updated_at", "eligibility_snapshot", "eligibility_evaluated_at", "approved_amount", "approved_at", "reviewed_at", "approved_service_charge_rate", "approved_term_months", "approved_rule_snapshot") VALUES
	('0cdb78af-986a-42d6-81c0-530fdab26a65', 'LOANAPP-000002', '64efef4f-1555-4322-80ad-f69e46887516', '9b5bf983-6cba-40b9-890d-f1af17041ffa', '6f7eb374-83d8-4c9b-80b6-f7ebe9650d7e', 6000.00, 'for holland', NULL, 'approved', '2026-09-17 20:08:06.756683+00', '2026-09-17 20:08:06.756683+00', '2026-09-22 16:18:39.308957+00', '{"term_months": 3, "borrower_type": "member", "total_repayment": 6600.00, "requested_amount": 6000.00, "loan_model_version": "v2", "guarantor_member_id": "a69eafab-eb8a-435c-8e0c-d3b22fa3b8f9", "service_charge_rate": 0.1000, "service_charge_amount": 600.00, "member_max_loan_at_submission": 12690.00, "member_total_savings_at_submission": 6345.00}', NULL, 6000.00, NULL, NULL, 0.1000, 3, '{"hard_cap": 20000.00, "product_id": "6f7eb374-83d8-4c9b-80b6-f7ebe9650d7e", "captured_at": "2026-09-22T15:05:57.088044+00:00", "term_months": 3, "approved_amount": 6000.00, "service_charge_rate": 0.1000}'),
	('b0a6c37f-7e99-461a-a710-fb4562181f03', 'LOANAPP-000003', '64efef4f-1555-4322-80ad-f69e46887516', '9b5bf983-6cba-40b9-890d-f1af17041ffa', '6f7eb374-83d8-4c9b-80b6-f7ebe9650d7e', 6000.00, 'ddxsdd', NULL, 'rejected', '2026-09-22 16:27:17.765304+00', '2026-09-22 16:27:17.765304+00', '2026-09-24 13:27:13.843168+00', '{"term_months": 3, "borrower_type": "member", "total_repayment": 6600.00, "requested_amount": 6000.00, "loan_model_version": "v2", "guarantor_member_id": "a69eafab-eb8a-435c-8e0c-d3b22fa3b8f9", "service_charge_rate": 0.1000, "service_charge_amount": 600.00, "member_max_loan_at_submission": 20000.00, "member_total_savings_at_submission": 10345.00}', NULL, NULL, NULL, NULL, NULL, NULL, NULL),
	('e621f41a-2e83-4be1-9e3e-1810c9e9bbfb', 'LOANAPP-000004', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', 'a69eafab-eb8a-435c-8e0c-d3b22fa3b8f9', '6f7eb374-83d8-4c9b-80b6-f7ebe9650d7e', 5407.50, 'I needed it
I needed it', NULL, 'rejected', '2026-09-24 13:25:25.848016+00', '2026-09-24 13:25:25.848016+00', '2026-09-28 13:16:39.754257+00', '{"term_months": 3, "borrower_type": "member", "total_repayment": 5948.25, "requested_amount": 5407.50, "loan_model_version": "v2", "guarantor_member_id": "9b5bf983-6cba-40b9-890d-f1af17041ffa", "service_charge_rate": 0.1000, "service_charge_amount": 540.75, "member_max_loan_at_submission": 8000.00, "member_total_savings_at_submission": 4000.00}', NULL, NULL, NULL, NULL, NULL, NULL, NULL),
	('60c3f83e-74be-49c2-a00a-233096fa8240', 'LOANAPP-000005', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', 'a69eafab-eb8a-435c-8e0c-d3b22fa3b8f9', '6f7eb374-83d8-4c9b-80b6-f7ebe9650d7e', 6000.00, 'whloohooo', NULL, 'cancelled', '2026-09-28 13:19:18.115008+00', '2026-09-28 13:19:18.115008+00', '2026-09-28 13:42:37.651515+00', '{"term_months": 3, "borrower_type": "member", "total_repayment": 6600.00, "requested_amount": 6000.00, "loan_model_version": "v2", "guarantor_member_id": "87e01037-3229-4ca7-bc94-b5a109e312a5", "service_charge_rate": 0.1000, "service_charge_amount": 600.00, "member_max_loan_at_submission": 8000.00, "member_total_savings_at_submission": 4000.00}', NULL, NULL, NULL, NULL, NULL, NULL, NULL),
	('f12c3664-510a-4d1a-93f8-691076167044', 'LOANAPP-000006', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', 'a69eafab-eb8a-435c-8e0c-d3b22fa3b8f9', '6f7eb374-83d8-4c9b-80b6-f7ebe9650d7e', 6000.00, 'baby eggs', NULL, 'cancelled', '2026-09-28 14:24:11.543628+00', '2026-09-28 14:24:11.543628+00', '2026-09-30 07:23:27.075879+00', '{"term_months": 3, "borrower_type": "member", "total_repayment": 6600.00, "requested_amount": 6000.00, "loan_model_version": "v2", "guarantor_member_id": "87e01037-3229-4ca7-bc94-b5a109e312a5", "service_charge_rate": 0.1000, "service_charge_amount": 600.00, "member_max_loan_at_submission": 8000.00, "member_total_savings_at_submission": 4000.00}', NULL, NULL, NULL, NULL, NULL, NULL, NULL),
	('03a1d0ee-7937-44ab-88f8-41143424864c', 'LOANAPP-000007', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', 'a69eafab-eb8a-435c-8e0c-d3b22fa3b8f9', '6f7eb374-83d8-4c9b-80b6-f7ebe9650d7e', 4948.01, 'hey the SC', NULL, 'rejected', '2026-09-30 07:28:39.727272+00', '2026-09-30 07:28:39.727272+00', '2026-09-30 07:42:15.803199+00', '{"term_months": 3, "borrower_type": "member", "total_repayment": 5442.81, "requested_amount": 4948.01, "loan_model_version": "v2", "guarantor_member_id": "87e01037-3229-4ca7-bc94-b5a109e312a5", "service_charge_rate": 0.1000, "service_charge_amount": 494.80, "member_max_loan_at_submission": 8000.00, "member_total_savings_at_submission": 4000.00}', NULL, 4000.00, NULL, NULL, 0.1000, 3, '{"hard_cap": 20000.00, "product_id": "6f7eb374-83d8-4c9b-80b6-f7ebe9650d7e", "captured_at": "2026-09-30T07:37:30.781748+00:00", "term_months": 3, "approved_amount": 4000.00, "service_charge_rate": 0.1000}'),
	('0fd40d1b-c1f4-4d22-a60c-0bd8ee8d68ab', 'LOANAPP-000008', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', 'a69eafab-eb8a-435c-8e0c-d3b22fa3b8f9', '6f7eb374-83d8-4c9b-80b6-f7ebe9650d7e', 3523.58, 'he SC no SC', NULL, 'cancelled', '2026-09-30 07:50:49.345629+00', '2026-09-30 07:50:49.345629+00', '2026-10-03 14:04:19.379102+00', '{"term_months": 3, "borrower_type": "member", "total_repayment": 3875.94, "requested_amount": 3523.58, "loan_model_version": "v2", "guarantor_member_id": "87e01037-3229-4ca7-bc94-b5a109e312a5", "service_charge_rate": 0.1000, "service_charge_amount": 352.36, "member_max_loan_at_submission": 8000.00, "member_total_savings_at_submission": 4000.00}', NULL, NULL, NULL, NULL, NULL, NULL, NULL);


--
-- Data for Name: outsider_loan_applications; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."outsider_loan_applications" ("id", "application_number", "loan_product_id", "applicant_full_name", "applicant_phone", "applicant_address", "requested_amount", "purpose", "eligibility_status", "status", "eligibility_snapshot", "eligibility_evaluated_at", "approved_amount", "approved_at", "submitted_at", "reviewed_at", "created_at", "updated_at", "approved_service_charge_rate", "approved_term_months", "approved_rule_snapshot") VALUES
	('3c488e6c-15f3-427b-8208-26b4476fcfd6', 'OUTLOANAPP-000001', '71fabd42-9a94-4970-9c07-56301ec443a1', 'wse', '0987654321`', 'asdf', 600.00, '3434', NULL, 'submitted', '{"term_months": 3, "borrower_type": "outsider", "total_repayment": 690.00, "requested_amount": 600.00, "loan_model_version": "v2", "guarantor_member_id": "9b5bf983-6cba-40b9-890d-f1af17041ffa", "service_charge_rate": 0.1500, "service_charge_amount": 90.00, "guarantor_max_loan_at_submission": 4000.00, "guarantor_total_savings_at_submission": 2000.00}', NULL, NULL, NULL, '2026-09-08 08:08:03.922448+00', NULL, '2026-09-08 08:08:03.922448+00', '2026-09-21 14:00:30.272238+00', NULL, NULL, NULL);


--
-- Data for Name: loan_approvals; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."loan_approvals" ("id", "loan_application_id", "approver_profile_id", "decision", "comment", "decided_at", "created_at", "manual_checks", "outsider_loan_application_id") VALUES
	('7fa2c184-1048-4ae4-8110-395da9fc11fc', '0cdb78af-986a-42d6-81c0-530fdab26a65', '96f15dbd-e885-4f42-8f55-492bd72cd515', 'approved', 'better repay on time', '2026-09-22 15:05:57.088044+00', '2026-09-22 15:05:57.088044+00', '{"reviewed_at": "2026-09-22T15:05:57.088044+00:00", "approved_amount": 6000.00, "repayment_capacity_note": "2200 on the first month", "repayment_capacity_confirmed": true}', NULL),
	('68a3cfd4-7c62-40b8-966b-e6cca3cd1423', '0cdb78af-986a-42d6-81c0-530fdab26a65', '3f3e0eb5-aeb1-4999-bd98-18543b01b613', 'approved', 'rfr', '2026-09-22 15:56:39.947211+00', '2026-09-22 15:56:39.947211+00', '{"reviewed_at": "2026-09-22T15:56:39.947211+00:00", "approved_amount": 6000.00, "repayment_capacity_note": "aybejen ayazelken", "repayment_capacity_confirmed": true}', NULL),
	('300de90d-663d-4780-9089-cc7e8eb7a887', 'b0a6c37f-7e99-461a-a710-fb4562181f03', '96f15dbd-e885-4f42-8f55-492bd72cd515', 'rejected', 'you already have an active loan', '2026-09-24 13:27:13.843168+00', '2026-09-24 13:27:13.843168+00', '{}', NULL),
	('4186b089-8536-45c8-a715-951420ac7202', 'e621f41a-2e83-4be1-9e3e-1810c9e9bbfb', '8a4f38eb-af53-4d05-8ab1-0e332e022710', 'rejected', 'noooooooooooooo', '2026-09-28 13:16:39.754257+00', '2026-09-28 13:16:39.754257+00', '{}', NULL),
	('deac437c-5133-4785-be04-da4389784e74', '03a1d0ee-7937-44ab-88f8-41143424864c', '3f3e0eb5-aeb1-4999-bd98-18543b01b613', 'approved', NULL, '2026-09-30 07:37:30.781748+00', '2026-09-30 07:37:30.781748+00', '{"reviewed_at": "2026-09-30T07:37:30.781748+00:00", "approved_amount": 4000.00, "repayment_capacity_note": "have this amount and get outta here", "repayment_capacity_confirmed": true}', NULL),
	('f5f594a5-c349-4b16-83a0-165c72b12cff', '03a1d0ee-7937-44ab-88f8-41143424864c', '96f15dbd-e885-4f42-8f55-492bd72cd515', 'rejected', 'you dont deserve this much bro', '2026-09-30 07:42:15.803199+00', '2026-09-30 07:42:15.803199+00', '{}', NULL);


--
-- Data for Name: loan_command_idempotency; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."loan_command_idempotency" ("id", "actor_profile_id", "command_type", "idempotency_key", "target_type", "target_id", "status", "response", "created_at", "completed_at") VALUES
	('bfb5b6de-0dbd-40c9-95b9-9bd93350dc4c', '96f15dbd-e885-4f42-8f55-492bd72cd515', 'REVIEW_LOAN_APPLICATION', 'fb178fa6-4f29-4e1f-8aa8-7c578f76761a', 'loan_application', '0cdb78af-986a-42d6-81c0-530fdab26a65', 'completed', '{"status": "under_review", "decision": "approved", "borrower_type": "member", "application_id": "0cdb78af-986a-42d6-81c0-530fdab26a65", "approval_count": 1, "approved_amount": 6000.00}', '2026-09-22 15:05:57.088044+00', '2026-09-22 15:05:57.088044+00'),
	('407652ed-3848-4980-bfa9-530d41021406', '3f3e0eb5-aeb1-4999-bd98-18543b01b613', 'REVIEW_LOAN_APPLICATION', '67106afd-5aaa-4aa6-bed9-cfc4ed90aad3', 'loan_application', '0cdb78af-986a-42d6-81c0-530fdab26a65', 'completed', '{"status": "approved", "decision": "approved", "borrower_type": "member", "application_id": "0cdb78af-986a-42d6-81c0-530fdab26a65", "approval_count": 2, "approved_amount": 6000.00}', '2026-09-22 15:56:39.947211+00', '2026-09-22 15:56:39.947211+00'),
	('9fa772d5-c428-4d95-8f04-66e1ba533786', '3f3e0eb5-aeb1-4999-bd98-18543b01b613', 'DISBURSE_LOAN', 'f332d4cb-62ad-4997-80f7-0dcb70b2c5cc', 'loan_application', '0cdb78af-986a-42d6-81c0-530fdab26a65', 'completed', '{"status": "active", "loan_id": "697e0b5c-c35b-4cb4-8039-73442c477157", "principal": 6000.00, "loan_number": "LOAN-000001", "term_months": 3, "maturity_date": "2026-12-22", "transaction_id": "700e7d94-d576-4742-bf75-b00a560031f1", "disbursement_id": "4b71948f-5f57-4667-9663-d70e348c5ec9", "total_repayment": 6600.00, "service_charge_rate": 0.1000, "service_charge_amount": 600.00}', '2026-09-22 16:18:39.308957+00', '2026-09-22 16:18:39.308957+00'),
	('914a1b1e-28d0-46da-9a3c-24a1f0eb97e7', '96f15dbd-e885-4f42-8f55-492bd72cd515', 'REVIEW_LOAN_APPLICATION', '7f9d6eca-66e7-4286-ae13-3cee9d8ae4cb', 'loan_application', 'b0a6c37f-7e99-461a-a710-fb4562181f03', 'completed', '{"status": "rejected", "decision": "rejected", "borrower_type": "member", "application_id": "b0a6c37f-7e99-461a-a710-fb4562181f03"}', '2026-09-24 13:27:13.843168+00', '2026-09-24 13:27:13.843168+00'),
	('b186d9ca-c4f1-4ed0-90a5-9ca3ac6807c7', '64efef4f-1555-4322-80ad-f69e46887516', 'CREATE_LOAN_REPAYMENT_SUBMISSION', 'loan-repayment-64efef4f-1555-4322-80ad-f69e46887516-1790437578617961', 'loan', '697e0b5c-c35b-4cb4-8039-73442c477157', 'completed', '{"amount": 2200.00, "status": "pending", "loan_id": "697e0b5c-c35b-4cb4-8039-73442c477157", "submission_id": "66e80012-ee57-42ca-a95c-dea4eb730168"}', '2026-09-26 15:52:15.283211+00', '2026-09-26 15:52:15.283211+00'),
	('179bf243-ec89-476b-bb4a-9fac12e1c14a', '64efef4f-1555-4322-80ad-f69e46887516', 'CREATE_LOAN_REPAYMENT_SUBMISSION', 'loan-repayment-64efef4f-1555-4322-80ad-f69e46887516-1790437910427384', 'loan', '697e0b5c-c35b-4cb4-8039-73442c477157', 'completed', '{"amount": 2200.00, "status": "pending", "loan_id": "697e0b5c-c35b-4cb4-8039-73442c477157", "submission_id": "1edf7577-115b-4e43-9847-47fb40c75d08"}', '2026-09-26 15:57:47.118747+00', '2026-09-26 15:57:47.118747+00'),
	('072eb672-3fe3-4a32-8f6c-27203801c968', '8a4f38eb-af53-4d05-8ab1-0e332e022710', 'VERIFY_LOAN_REPAYMENT', '6db03839-ee30-4119-bfb2-2d882d757564', 'loan_repayment_submission', '1edf7577-115b-4e43-9847-47fb40c75d08', 'completed', '{"status": "verified", "submission_id": "1edf7577-115b-4e43-9847-47fb40c75d08"}', '2026-09-26 16:42:31.29729+00', '2026-09-26 16:42:31.29729+00'),
	('5aadfb3b-9b5e-4fd4-b442-4f06ef417cd8', '8a4f38eb-af53-4d05-8ab1-0e332e022710', 'POST_LOAN_REPAYMENT', '1243a32f-b186-4592-b409-d3cda89f8a59', 'loan_repayment_submission', '1edf7577-115b-4e43-9847-47fb40c75d08', 'completed', '{"loan_id": "697e0b5c-c35b-4cb4-8039-73442c477157", "base_amount": 2200.00, "total_amount": 2200.00, "submission_id": "1edf7577-115b-4e43-9847-47fb40c75d08", "penalty_amount": 0.00, "transaction_id": "8511fbdd-a716-4570-8b39-3d1ca411f376"}', '2026-09-26 16:51:55.854226+00', '2026-09-26 16:51:55.854226+00'),
	('5f37814c-ea38-4f48-ba0c-3bc56104bb80', '8a4f38eb-af53-4d05-8ab1-0e332e022710', 'REVIEW_LOAN_APPLICATION', 'ee5b032f-887f-41df-b7cc-fd9593547aa6', 'loan_application', 'e621f41a-2e83-4be1-9e3e-1810c9e9bbfb', 'completed', '{"status": "rejected", "decision": "rejected", "borrower_type": "member", "application_id": "e621f41a-2e83-4be1-9e3e-1810c9e9bbfb"}', '2026-09-28 13:16:39.754257+00', '2026-09-28 13:16:39.754257+00'),
	('1277c64b-0ce9-483e-8909-f37e661ce201', '3f3e0eb5-aeb1-4999-bd98-18543b01b613', 'REVIEW_LOAN_APPLICATION', '8ee647d3-9797-4c7f-b248-d9b9c39bff95', 'loan_application', '03a1d0ee-7937-44ab-88f8-41143424864c', 'completed', '{"status": "under_review", "decision": "approved", "borrower_type": "member", "application_id": "03a1d0ee-7937-44ab-88f8-41143424864c", "approval_count": 1, "approved_amount": 4000.00}', '2026-09-30 07:37:30.781748+00', '2026-09-30 07:37:30.781748+00'),
	('4e498b62-d31c-48d1-8012-679dcf718d1a', '96f15dbd-e885-4f42-8f55-492bd72cd515', 'REVIEW_LOAN_APPLICATION', 'e65d8d36-1a7c-4dae-bc10-fd5a2b5ed397', 'loan_application', '03a1d0ee-7937-44ab-88f8-41143424864c', 'completed', '{"status": "rejected", "decision": "rejected", "borrower_type": "member", "application_id": "03a1d0ee-7937-44ab-88f8-41143424864c"}', '2026-09-30 07:42:15.803199+00', '2026-09-30 07:42:15.803199+00'),
	('7b68e38c-e1e6-42b2-bc3d-0c3efd5c867c', '64efef4f-1555-4322-80ad-f69e46887516', 'CREATE_LOAN_REPAYMENT_SUBMISSION', 'loan-repayment-64efef4f-1555-4322-80ad-f69e46887516-1791037246453938', 'loan', '697e0b5c-c35b-4cb4-8039-73442c477157', 'completed', '{"amount": 2200.00, "status": "pending", "loan_id": "697e0b5c-c35b-4cb4-8039-73442c477157", "submission_id": "7265b741-ecf0-4bff-9bee-66ac8e6c6f48"}', '2026-10-03 14:23:22.914562+00', '2026-10-03 14:23:22.914562+00'),
	('c0dc0288-c539-4d6b-8489-c40bc2f7a05d', '3f3e0eb5-aeb1-4999-bd98-18543b01b613', 'VERIFY_LOAN_REPAYMENT', '3027b006-4fd3-4930-b321-3132b0cd7fa5', 'loan_repayment_submission', '7265b741-ecf0-4bff-9bee-66ac8e6c6f48', 'completed', '{"status": "verified", "submission_id": "7265b741-ecf0-4bff-9bee-66ac8e6c6f48"}', '2026-10-11 13:11:33.658994+00', '2026-10-11 13:11:33.658994+00'),
	('3195822f-9f48-4a29-ad7d-16760e25ca1e', '3f3e0eb5-aeb1-4999-bd98-18543b01b613', 'POST_LOAN_REPAYMENT', '837b150b-f3d0-4e36-846d-8b4accf9e40a', 'loan_repayment_submission', '7265b741-ecf0-4bff-9bee-66ac8e6c6f48', 'completed', '{"loan_id": "697e0b5c-c35b-4cb4-8039-73442c477157", "base_amount": 2200.00, "total_amount": 2200.00, "submission_id": "7265b741-ecf0-4bff-9bee-66ac8e6c6f48", "penalty_amount": 0.00, "transaction_id": "a4e82a41-a3a2-4bdb-82c5-ea870f9a2403"}', '2026-10-11 13:11:43.266207+00', '2026-10-11 13:11:43.266207+00');


--
-- Data for Name: loans; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."loans" ("id", "loan_number", "loan_application_id", "borrower_profile_id", "member_id", "principal", "service_charge_rate", "service_charge_amount", "total_repayment", "term_months", "status", "disbursed_at", "maturity_date", "created_at", "updated_at", "outsider_loan_application_id") VALUES
	('697e0b5c-c35b-4cb4-8039-73442c477157', 'LOAN-000001', '0cdb78af-986a-42d6-81c0-530fdab26a65', '64efef4f-1555-4322-80ad-f69e46887516', '9b5bf983-6cba-40b9-890d-f1af17041ffa', 6000.00, 0.1000, 600.00, 6600.00, 3, 'active', '2026-09-22 16:18:39.308957+00', '2026-12-22', '2026-09-22 16:18:39.308957+00', '2026-10-11 13:11:43.266207+00', NULL);


--
-- Data for Name: loan_conflict_declarations; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: loan_installments; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."loan_installments" ("id", "loan_id", "installment_number", "due_date", "principal_amount", "service_charge_amount", "total_due", "paid_amount", "late_penalty_amount", "status", "created_at", "updated_at", "paid_penalty_amount") VALUES
	('a078e1de-c92f-4c99-80b1-12097c4b1515', '697e0b5c-c35b-4cb4-8039-73442c477157', 3, '2026-12-22', 2000.00, 200.00, 2200.00, 0.00, 0.00, 'pending', '2026-09-22 16:18:39.308957+00', '2026-09-22 16:18:39.308957+00', 0.00),
	('33caaa84-eb2d-42f9-b78e-78a5595c0175', '697e0b5c-c35b-4cb4-8039-73442c477157', 1, '2026-10-22', 2000.00, 200.00, 2200.00, 2200.00, 0.00, 'paid', '2026-09-22 16:18:39.308957+00', '2026-09-26 16:51:55.854226+00', 0.00),
	('25524740-b9d7-4e4f-b033-e62180d154a8', '697e0b5c-c35b-4cb4-8039-73442c477157', 2, '2026-11-22', 2000.00, 200.00, 2200.00, 2200.00, 0.00, 'paid', '2026-09-22 16:18:39.308957+00', '2026-10-11 13:11:43.266207+00', 0.00);


--
-- Data for Name: loan_default_events; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: transactions; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."transactions" ("id", "reference_number", "transaction_type", "source_type", "source_id", "profile_id", "member_id", "amount", "currency", "approval_status", "transaction_status", "initiated_by", "approved_by", "approved_at", "description", "reversal_of_transaction_id", "created_at") VALUES
	('dbab7db5-8470-417d-9c0e-2cd0d34c6bd7', 'TXN-20260906-000001', 'savings_contribution', 'payment', 'fbaccbd0-9228-420b-a5c1-be9fc1e361c0', '64efef4f-1555-4322-80ad-f69e46887516', '9b5bf983-6cba-40b9-890d-f1af17041ffa', 2000.00, 'ETB', 'approved', 'posted', '96f15dbd-e885-4f42-8f55-492bd72cd515', '96f15dbd-e885-4f42-8f55-492bd72cd515', '2026-09-06 10:19:06.701024+00', 'Verified savings payment', NULL, '2026-09-06 10:19:06.701024+00'),
	('910b7e88-ebc8-4567-b937-6fddf185ca96', 'TXN-20260906-000002', 'savings_contribution', 'payment', '59147fd5-2507-4596-81e7-a055354c8811', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', 'a69eafab-eb8a-435c-8e0c-d3b22fa3b8f9', 2000.00, 'ETB', 'approved', 'posted', '96f15dbd-e885-4f42-8f55-492bd72cd515', '96f15dbd-e885-4f42-8f55-492bd72cd515', '2026-09-06 11:16:04.442067+00', 'Verified savings payment', NULL, '2026-09-06 11:16:04.442067+00'),
	('a0358e7e-1631-4ab3-906d-6c70aee63481', 'TXN-20260906-000003', 'savings_withdrawal', 'withdrawal_request', '5731ca9c-8c4f-40ce-a4ef-85dc1d450da3', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', 'a69eafab-eb8a-435c-8e0c-d3b22fa3b8f9', 2000.00, 'ETB', 'approved', 'posted', '96f15dbd-e885-4f42-8f55-492bd72cd515', '96f15dbd-e885-4f42-8f55-492bd72cd515', '2026-09-06 11:18:11.868169+00', 'Approved savings withdrawal', NULL, '2026-09-06 11:18:11.868169+00'),
	('4dc43676-1e54-4e8e-993c-13930d5e1e18', 'TXN-20260909-000004', 'savings_contribution', 'payment', '109328cc-ed3a-46c8-b087-41fb420d31ee', '64efef4f-1555-4322-80ad-f69e46887516', '9b5bf983-6cba-40b9-890d-f1af17041ffa', 2345.00, 'ETB', 'approved', 'posted', '96f15dbd-e885-4f42-8f55-492bd72cd515', '96f15dbd-e885-4f42-8f55-492bd72cd515', '2026-09-09 14:21:37.970045+00', 'Verified savings payment', NULL, '2026-09-09 14:21:37.970045+00'),
	('35c1df1c-f60f-4316-aec4-13b6d9aeb106', 'TXN-20260911-000005', 'savings_contribution', 'payment', '54b6e21a-046f-4d16-90a5-51f552762ec9', '64efef4f-1555-4322-80ad-f69e46887516', '9b5bf983-6cba-40b9-890d-f1af17041ffa', 2000.00, 'ETB', 'approved', 'posted', '96f15dbd-e885-4f42-8f55-492bd72cd515', '96f15dbd-e885-4f42-8f55-492bd72cd515', '2026-09-11 10:55:52.018182+00', 'Verified savings payment', NULL, '2026-09-11 10:55:52.018182+00'),
	('d812c137-313d-4f11-9e29-75d88e3ced85', 'TXN-20260911-000006', 'savings_contribution', 'payment', 'd6370408-53b4-4721-a77a-9f7ca9752fb6', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', 'a69eafab-eb8a-435c-8e0c-d3b22fa3b8f9', 2000.00, 'ETB', 'approved', 'posted', '96f15dbd-e885-4f42-8f55-492bd72cd515', '96f15dbd-e885-4f42-8f55-492bd72cd515', '2026-09-11 10:56:16.342875+00', 'Verified savings payment', NULL, '2026-09-11 10:56:16.342875+00'),
	('23eecd03-3c02-4654-a77d-f6603810e25d', 'TXN-20260919-000007', 'savings_contribution', 'payment', '4d9da62a-9eb8-43d9-bdb2-f1149488e965', '64efef4f-1555-4322-80ad-f69e46887516', '9b5bf983-6cba-40b9-890d-f1af17041ffa', 2000.00, 'ETB', 'approved', 'posted', '96f15dbd-e885-4f42-8f55-492bd72cd515', '96f15dbd-e885-4f42-8f55-492bd72cd515', '2026-09-19 12:40:37.989294+00', 'Verified savings payment', NULL, '2026-09-19 12:40:37.989294+00'),
	('44fa0ffe-6485-4930-b3fa-5d6baeab606a', 'TXN-20260919-000008', 'savings_contribution', 'payment', 'dd2e9149-e9a4-4251-b39c-0de7387de25c', '5101cac2-a24e-4342-975a-74df63071328', '87e01037-3229-4ca7-bc94-b5a109e312a5', 2000.00, 'ETB', 'approved', 'posted', '96f15dbd-e885-4f42-8f55-492bd72cd515', '96f15dbd-e885-4f42-8f55-492bd72cd515', '2026-09-19 13:15:05.346032+00', 'Verified savings payment', NULL, '2026-09-19 13:15:05.346032+00'),
	('ac7a7879-9c87-42c6-9f74-8643457075fc', 'TXN-20260921-000010', 'savings_contribution', 'payment', '5466e990-f3e9-47e3-9bf9-cef346bd10ec', '5101cac2-a24e-4342-975a-74df63071328', '87e01037-3229-4ca7-bc94-b5a109e312a5', 2200.00, 'ETB', 'approved', 'posted', '96f15dbd-e885-4f42-8f55-492bd72cd515', '96f15dbd-e885-4f42-8f55-492bd72cd515', '2026-09-21 15:36:06.095985+00', 'Verified savings payment', NULL, '2026-09-21 15:36:06.095985+00'),
	('6b5dba76-2156-4db4-8399-488c3a82c505', 'TXN-20260919-000009', 'savings_late_penalty', 'savings_obligation', '7f6a0d71-60c2-41a2-8297-ab0339814082', '5101cac2-a24e-4342-975a-74df63071328', '87e01037-3229-4ca7-bc94-b5a109e312a5', 200.00, 'ETB', 'approved', 'posted', '96f15dbd-e885-4f42-8f55-492bd72cd515', '96f15dbd-e885-4f42-8f55-492bd72cd515', '2026-09-19 18:57:59.328849+00', 'Late monthly savings contribution penalty (10%)', NULL, '2026-09-19 18:57:59.328849+00'),
	('398ab316-648b-4b95-a030-94a772471f6b', 'TXN-20260922-000014', 'savings_late_penalty', 'savings_obligation', '3ee6802f-d7a3-4184-97ef-90ae28f5f916', '64efef4f-1555-4322-80ad-f69e46887516', '9b5bf983-6cba-40b9-890d-f1af17041ffa', 200.00, 'ETB', 'approved', 'posted', '64efef4f-1555-4322-80ad-f69e46887516', '64efef4f-1555-4322-80ad-f69e46887516', '2026-09-22 12:42:11.127297+00', 'Late monthly savings contribution penalty (10%)', NULL, '2026-09-22 12:42:11.127297+00'),
	('f2eaeb97-6212-476e-be28-7ea992948639', 'TXN-20260922-000015', 'savings_contribution', 'payment', '9875ebd6-1669-40a5-9e62-9bcfe2998350', '64efef4f-1555-4322-80ad-f69e46887516', '9b5bf983-6cba-40b9-890d-f1af17041ffa', 2200.00, 'ETB', 'approved', 'posted', '96f15dbd-e885-4f42-8f55-492bd72cd515', '96f15dbd-e885-4f42-8f55-492bd72cd515', '2026-09-22 13:06:15.904186+00', 'Verified savings payment', NULL, '2026-09-22 13:06:15.904186+00'),
	('65babf8b-1032-4cf7-8438-0b6df3b10cae', 'TXN-20260922-000016', 'savings_late_penalty', 'savings_obligation', '6dcf8f9b-14fe-4840-a1dc-fbe3903735bb', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', 'a69eafab-eb8a-435c-8e0c-d3b22fa3b8f9', 200.00, 'ETB', 'approved', 'posted', '96f15dbd-e885-4f42-8f55-492bd72cd515', '96f15dbd-e885-4f42-8f55-492bd72cd515', '2026-09-22 13:08:22.10156+00', 'Late monthly savings contribution penalty (10%)', NULL, '2026-09-22 13:08:22.10156+00'),
	('2d7c8d68-e239-4282-9995-8240fb46e284', 'TXN-20260922-000017', 'savings_late_penalty', 'savings_obligation', 'bd933bd5-4d08-4d1d-a036-9264fb2b7957', '5101cac2-a24e-4342-975a-74df63071328', '87e01037-3229-4ca7-bc94-b5a109e312a5', 200.00, 'ETB', 'approved', 'posted', '96f15dbd-e885-4f42-8f55-492bd72cd515', '96f15dbd-e885-4f42-8f55-492bd72cd515', '2026-09-22 13:08:22.10156+00', 'Late monthly savings contribution penalty (10%)', NULL, '2026-09-22 13:08:22.10156+00'),
	('f33b3c82-b543-409b-b6ad-72ee75bfdac0', 'TXN-20260922-000018', 'savings_contribution', 'payment', '5fdc0d24-755f-45fb-889d-60ac33af196f', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', 'a69eafab-eb8a-435c-8e0c-d3b22fa3b8f9', 2200.00, 'ETB', 'approved', 'posted', '96f15dbd-e885-4f42-8f55-492bd72cd515', '96f15dbd-e885-4f42-8f55-492bd72cd515', '2026-09-22 14:26:33.667288+00', 'Verified savings payment', NULL, '2026-09-22 14:26:33.667288+00'),
	('700e7d94-d576-4742-bf75-b00a560031f1', 'TXN-20260922-000019', 'loan_disbursement', 'loan', '697e0b5c-c35b-4cb4-8039-73442c477157', '64efef4f-1555-4322-80ad-f69e46887516', '9b5bf983-6cba-40b9-890d-f1af17041ffa', 6600.00, 'ETB', 'approved', 'posted', '3f3e0eb5-aeb1-4999-bd98-18543b01b613', '3f3e0eb5-aeb1-4999-bd98-18543b01b613', '2026-09-22 16:18:39.308957+00', 'lets give it to him', NULL, '2026-09-22 16:18:39.308957+00'),
	('20932336-8fc8-491d-baa1-7bac44b251c3', 'TXN-20260925-000020', 'savings_late_penalty', 'savings_obligation', '202bf602-7ac9-44b4-81a4-e6be83be8102', '99c968a2-142f-4329-935d-ef240a5a40f5', '92e3f6fb-0b10-4ea2-9212-c2b470c6221b', 200.00, 'ETB', 'approved', 'posted', '99c968a2-142f-4329-935d-ef240a5a40f5', '99c968a2-142f-4329-935d-ef240a5a40f5', '2026-09-25 17:27:23.440589+00', 'Late monthly savings contribution penalty (10%)', NULL, '2026-09-25 17:27:23.440589+00'),
	('8511fbdd-a716-4570-8b39-3d1ca411f376', 'TXN-20260926-000022', 'loan_repayment', 'loan_repayment_submission', '1edf7577-115b-4e43-9847-47fb40c75d08', '64efef4f-1555-4322-80ad-f69e46887516', '9b5bf983-6cba-40b9-890d-f1af17041ffa', 2200.00, 'ETB', 'approved', 'posted', '8a4f38eb-af53-4d05-8ab1-0e332e022710', '8a4f38eb-af53-4d05-8ab1-0e332e022710', '2026-09-26 16:51:55.854226+00', 'Loan repayment posting', NULL, '2026-09-26 16:51:55.854226+00'),
	('81bed6cf-68fc-4f4c-8452-2bb90e86b135', 'TXN-20260928-000023', 'expense', 'expense', '2179f5d1-1162-40ca-9e2e-a878713e5371', '8a4f38eb-af53-4d05-8ab1-0e332e022710', NULL, 1600.00, 'ETB', 'approved', 'posted', '96f15dbd-e885-4f42-8f55-492bd72cd515', '96f15dbd-e885-4f42-8f55-492bd72cd515', '2026-09-28 16:44:21.403363+00', 'To build Mobile application', NULL, '2026-09-28 16:44:21.403363+00'),
	('196244e5-92dc-4450-aa1a-e33fff633d58', 'TXN-20260930-000024', 'savings_contribution', 'payment', '90128ce8-6cf9-4f12-95bb-e8726784195f', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', 'a69eafab-eb8a-435c-8e0c-d3b22fa3b8f9', 12400.00, 'ETB', 'approved', 'posted', '96f15dbd-e885-4f42-8f55-492bd72cd515', '96f15dbd-e885-4f42-8f55-492bd72cd515', '2026-09-30 08:18:46.015939+00', 'Verified savings payment', NULL, '2026-09-30 08:18:46.015939+00'),
	('a419bf0e-402d-4835-a411-0a634ac90fcf', 'TXN-20260930-000025', 'savings_contribution', 'payment', 'fc3c775c-b1bd-4791-ae85-98bb2dea4246', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', 'a69eafab-eb8a-435c-8e0c-d3b22fa3b8f9', 100.00, 'ETB', 'approved', 'posted', '96f15dbd-e885-4f42-8f55-492bd72cd515', '96f15dbd-e885-4f42-8f55-492bd72cd515', '2026-09-30 08:41:15.423581+00', 'Verified savings payment', NULL, '2026-09-30 08:41:15.423581+00'),
	('2a382a5e-f668-4e12-bda5-6ef067f89763', 'TXN-20260930-000026', 'savings_contribution', 'payment', 'c62d9849-de57-4887-9b0d-2c9f26dd8451', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', 'a69eafab-eb8a-435c-8e0c-d3b22fa3b8f9', 200.00, 'ETB', 'approved', 'posted', '96f15dbd-e885-4f42-8f55-492bd72cd515', '96f15dbd-e885-4f42-8f55-492bd72cd515', '2026-09-30 08:47:55.755996+00', 'Verified savings payment', NULL, '2026-09-30 08:47:55.755996+00'),
	('65dad621-b951-44e7-8549-3e0591b96cfb', 'TXN-20260930-000027', 'savings_contribution', 'payment', 'a0a448fd-f5b8-41f9-9068-1127464e5efe', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', 'a69eafab-eb8a-435c-8e0c-d3b22fa3b8f9', 580.00, 'ETB', 'approved', 'posted', '96f15dbd-e885-4f42-8f55-492bd72cd515', '96f15dbd-e885-4f42-8f55-492bd72cd515', '2026-09-30 08:49:48.76956+00', 'Verified savings payment', NULL, '2026-09-30 08:49:48.76956+00'),
	('a4e82a41-a3a2-4bdb-82c5-ea870f9a2403', 'TXN-20261011-000028', 'loan_repayment', 'loan_repayment_submission', '7265b741-ecf0-4bff-9bee-66ac8e6c6f48', '64efef4f-1555-4322-80ad-f69e46887516', '9b5bf983-6cba-40b9-890d-f1af17041ffa', 2200.00, 'ETB', 'approved', 'posted', '3f3e0eb5-aeb1-4999-bd98-18543b01b613', '3f3e0eb5-aeb1-4999-bd98-18543b01b613', '2026-10-11 13:11:43.266207+00', 'Loan repayment posting', NULL, '2026-10-11 13:11:43.266207+00'),
	('9527b968-e562-47c0-a30a-61daefc9ed50', 'TXN-20261011-000029', 'savings_late_penalty', 'savings_obligation', '61ec8353-9223-473a-9d7a-ac0a2a3aead0', 'a9e748d4-dc2b-4d5b-9571-2e2f2bc78e0d', '80ea84c9-313d-4927-b066-4fcdd6116226', 200.00, 'ETB', 'approved', 'posted', 'a9e748d4-dc2b-4d5b-9571-2e2f2bc78e0d', 'a9e748d4-dc2b-4d5b-9571-2e2f2bc78e0d', '2026-10-11 13:56:45.734596+00', 'Late monthly savings contribution penalty (10%)', NULL, '2026-10-11 13:56:45.734596+00'),
	('0005f65d-4b7c-4307-846c-87f9946e452c', 'TXN-20261011-000030', 'savings_contribution', 'payment', 'f9a97b0a-f9ae-44c5-b7e5-3765f58addc9', 'a9e748d4-dc2b-4d5b-9571-2e2f2bc78e0d', '80ea84c9-313d-4927-b066-4fcdd6116226', 2200.00, 'ETB', 'approved', 'posted', '3f3e0eb5-aeb1-4999-bd98-18543b01b613', '3f3e0eb5-aeb1-4999-bd98-18543b01b613', '2026-10-11 14:00:44.040855+00', 'Verified savings payment', NULL, '2026-10-11 14:00:44.040855+00'),
	('2071c21d-2864-469c-bd0f-04bf99ab8bd6', 'TXN-20261012-000031', 'savings_late_penalty', 'savings_obligation', '0ddd218f-9b52-49fb-8787-42983eb5ee87', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', 'a69eafab-eb8a-435c-8e0c-d3b22fa3b8f9', 200.00, 'ETB', 'approved', 'posted', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', '2026-10-12 12:02:00.082692+00', 'Late monthly savings contribution penalty (10%)', NULL, '2026-10-12 12:02:00.082692+00'),
	('7a42f117-ab6e-4cdf-91b7-0d561b49e982', 'TXN-20261012-000032', 'savings_late_penalty', 'savings_obligation', '13255960-92ef-49b0-b74b-7fe7debb35f0', '64efef4f-1555-4322-80ad-f69e46887516', '9b5bf983-6cba-40b9-890d-f1af17041ffa', 200.00, 'ETB', 'approved', 'posted', '64efef4f-1555-4322-80ad-f69e46887516', '64efef4f-1555-4322-80ad-f69e46887516', '2026-10-12 19:53:52.037205+00', 'Late monthly savings contribution penalty (10%)', NULL, '2026-10-12 19:53:52.037205+00'),
	('c3e1e0de-cacc-435f-a1ce-9bedde365f8a', 'TXN-20261013-000033', 'savings_late_penalty', 'savings_obligation', 'df608f6a-0dc9-4f0b-a3ef-f9c0efd004d9', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', 'a69eafab-eb8a-435c-8e0c-d3b22fa3b8f9', 200.00, 'ETB', 'approved', 'posted', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', '2026-10-13 05:53:03.385181+00', 'Late monthly savings contribution penalty (10%)', NULL, '2026-10-13 05:53:03.385181+00');


--
-- Data for Name: loan_disbursements; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."loan_disbursements" ("id", "loan_id", "amount", "payment_method_code", "transaction_id", "released_by", "released_at", "notes") VALUES
	('4b71948f-5f57-4667-9663-d70e348c5ec9', '697e0b5c-c35b-4cb4-8039-73442c477157', 6000.00, 'bank', '700e7d94-d576-4742-bf75-b00a560031f1', '3f3e0eb5-aeb1-4999-bd98-18543b01b613', '2026-09-22 16:18:39.308957+00', 'lets give it to him');


--
-- Data for Name: loan_eligibility_checks; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: loan_extension_requests; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: payment_methods; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."payment_methods" ("id", "code", "name", "active", "created_at") VALUES
	('335269f9-ef96-47c9-aca1-2fd320a8671a', 'wallet', 'Wallet', true, '2026-08-26 19:36:24.648374+00'),
	('750cd972-07bc-4502-8175-5f92f3fda938', 'bank_transfer', 'Bank Transfer', true, '2026-08-26 19:36:24.648374+00');


--
-- Data for Name: payments; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."payments" ("id", "payer_profile_id", "payment_method_id", "reference_number", "purpose_type", "purpose_id", "amount", "currency", "status", "payment_proof_path", "external_reference", "submitted_at", "verified_by", "verified_at", "rejection_reason", "created_at", "updated_at") VALUES
	('fbaccbd0-9228-420b-a5c1-be9fc1e361c0', '64efef4f-1555-4322-80ad-f69e46887516', '750cd972-07bc-4502-8175-5f92f3fda938', 'PAY-20260906-000001', 'savings_contribution', NULL, 2000.00, 'ETB', 'verified', NULL, 'vfd', '2026-09-06 10:18:07.987861+00', '96f15dbd-e885-4f42-8f55-492bd72cd515', '2026-09-06 10:19:06.701024+00', NULL, '2026-09-06 10:18:07.987861+00', '2026-09-21 14:00:30.272238+00'),
	('59147fd5-2507-4596-81e7-a055354c8811', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', '335269f9-ef96-47c9-aca1-2fd320a8671a', 'PAY-20260906-000002', 'savings_contribution', NULL, 2000.00, 'ETB', 'verified', NULL, 'ft47888943', '2026-09-06 11:14:28.499468+00', '96f15dbd-e885-4f42-8f55-492bd72cd515', '2026-09-06 11:16:04.442067+00', NULL, '2026-09-06 11:14:28.499468+00', '2026-09-21 14:00:30.272238+00'),
	('109328cc-ed3a-46c8-b087-41fb420d31ee', '64efef4f-1555-4322-80ad-f69e46887516', '750cd972-07bc-4502-8175-5f92f3fda938', 'PAY-20260909-000003', 'savings_contribution', NULL, 2345.00, 'ETB', 'verified', NULL, 'ASXZSXZC', '2026-09-09 13:15:23.000559+00', '96f15dbd-e885-4f42-8f55-492bd72cd515', '2026-09-09 14:21:37.970045+00', NULL, '2026-09-09 13:15:23.000559+00', '2026-09-21 14:00:30.272238+00'),
	('54b6e21a-046f-4d16-90a5-51f552762ec9', '64efef4f-1555-4322-80ad-f69e46887516', '750cd972-07bc-4502-8175-5f92f3fda938', 'PAY-20260909-000004', 'savings_contribution', NULL, 2000.00, 'ETB', 'verified', NULL, 'assss', '2026-09-09 14:33:26.503427+00', '96f15dbd-e885-4f42-8f55-492bd72cd515', '2026-09-11 10:55:52.018182+00', NULL, '2026-09-09 14:33:26.503427+00', '2026-09-21 14:00:30.272238+00'),
	('d6370408-53b4-4721-a77a-9f7ca9752fb6', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', '335269f9-ef96-47c9-aca1-2fd320a8671a', 'PAY-20260911-000005', 'savings_contribution', NULL, 2000.00, 'ETB', 'verified', NULL, 'hsj', '2026-09-11 10:53:15.493947+00', '96f15dbd-e885-4f42-8f55-492bd72cd515', '2026-09-11 10:56:16.342875+00', NULL, '2026-09-11 10:53:15.493947+00', '2026-09-21 14:00:30.272238+00'),
	('4d9da62a-9eb8-43d9-bdb2-f1149488e965', '64efef4f-1555-4322-80ad-f69e46887516', '750cd972-07bc-4502-8175-5f92f3fda938', 'PAY-20260919-000006', 'savings_contribution', NULL, 2000.00, 'ETB', 'verified', NULL, 'asdcxfvde', '2026-09-19 12:29:55.46122+00', '96f15dbd-e885-4f42-8f55-492bd72cd515', '2026-09-19 12:40:37.989294+00', NULL, '2026-09-19 12:29:55.46122+00', '2026-09-21 14:00:30.272238+00'),
	('5466e990-f3e9-47e3-9bf9-cef346bd10ec', '5101cac2-a24e-4342-975a-74df63071328', '335269f9-ef96-47c9-aca1-2fd320a8671a', 'PAY-20260921-000007', 'savings_contribution', '7f6a0d71-60c2-41a2-8297-ab0339814082', 2200.00, 'ETB', 'verified', '5101cac2-a24e-4342-975a-74df63071328/1790000239440.png', '', '2026-09-21 14:23:15.504384+00', '96f15dbd-e885-4f42-8f55-492bd72cd515', '2026-09-21 15:36:06.095985+00', NULL, '2026-09-21 14:23:15.504384+00', '2026-09-21 15:36:06.095985+00'),
	('9875ebd6-1669-40a5-9e62-9bcfe2998350', '64efef4f-1555-4322-80ad-f69e46887516', '335269f9-ef96-47c9-aca1-2fd320a8671a', 'PAY-20260922-000008', 'savings_contribution', '3ee6802f-d7a3-4184-97ef-90ae28f5f916', 2200.00, 'ETB', 'verified', '64efef4f-1555-4322-80ad-f69e46887516/1790080736661.png', '', '2026-09-22 12:44:53.399229+00', '96f15dbd-e885-4f42-8f55-492bd72cd515', '2026-09-22 13:06:15.904186+00', NULL, '2026-09-22 12:44:53.399229+00', '2026-09-22 13:06:15.904186+00'),
	('5fdc0d24-755f-45fb-889d-60ac33af196f', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', '750cd972-07bc-4502-8175-5f92f3fda938', 'PAY-20260922-000009', 'savings_contribution', '6dcf8f9b-14fe-4840-a1dc-fbe3903735bb', 2200.00, 'ETB', 'verified', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d/1790086966353.png', '', '2026-09-22 14:22:48.566393+00', '96f15dbd-e885-4f42-8f55-492bd72cd515', '2026-09-22 14:26:33.667288+00', NULL, '2026-09-22 14:22:48.566393+00', '2026-09-22 14:26:33.667288+00'),
	('479e9215-a556-414c-9478-e6117e60d0be', '64efef4f-1555-4322-80ad-f69e46887516', '750cd972-07bc-4502-8175-5f92f3fda938', 'PAY-20260926-000010', 'loan_repayment', '697e0b5c-c35b-4cb4-8039-73442c477157', 2200.00, 'ETB', 'pending', 'loan_payments/64efef4f-1555-4322-80ad-f69e46887516/1790435286206_Screenshot_20260924-192616.png', '', '2026-09-26 15:14:05.585064+00', NULL, NULL, NULL, '2026-09-26 18:08:08.916014+00', '2026-09-26 15:14:05.585064+00'),
	('636e335b-0bd6-47af-b792-ea4e1707e704', '64efef4f-1555-4322-80ad-f69e46887516', '750cd972-07bc-4502-8175-5f92f3fda938', 'PAY-20260926-000011', 'loan_repayment', '697e0b5c-c35b-4cb4-8039-73442c477157', 2200.00, 'ETB', 'pending', 'loan_payments/64efef4f-1555-4322-80ad-f69e46887516/1790435797659_Screenshot_20260924-192616.png', '', '2026-09-26 15:22:36.628623+00', NULL, NULL, NULL, '2026-09-26 18:16:39.994793+00', '2026-09-26 15:22:36.628623+00'),
	('f0c49844-940c-456b-a5f4-72fccf7dbc8c', '64efef4f-1555-4322-80ad-f69e46887516', '750cd972-07bc-4502-8175-5f92f3fda938', 'PAY-20260926-000012', 'loan_repayment', '697e0b5c-c35b-4cb4-8039-73442c477157', 2200.00, 'ETB', 'pending', 'loan_payments/64efef4f-1555-4322-80ad-f69e46887516/1790436021167_Screenshot_20260924-192616.png', '', '2026-09-26 15:26:19.428522+00', NULL, NULL, NULL, '2026-09-26 18:20:22.768093+00', '2026-09-26 15:26:19.428522+00'),
	('65d679c0-c51f-4d56-b2ec-3b5b9142c131', '64efef4f-1555-4322-80ad-f69e46887516', '750cd972-07bc-4502-8175-5f92f3fda938', 'PAY-20260926-000013', 'loan_repayment', '697e0b5c-c35b-4cb4-8039-73442c477157', 2200.00, 'ETB', 'pending', 'loan_payments/64efef4f-1555-4322-80ad-f69e46887516/1790436508170_Screenshot_20260924-192616.png', NULL, '2026-09-26 15:34:27.979024+00', NULL, NULL, NULL, '2026-09-26 15:34:27.979024+00', '2026-09-26 15:34:27.979024+00'),
	('12e0e40c-d782-4a1b-b0ab-1e9659c5960d', '64efef4f-1555-4322-80ad-f69e46887516', '335269f9-ef96-47c9-aca1-2fd320a8671a', 'PAY-20260926-000014', 'loan_repayment', '697e0b5c-c35b-4cb4-8039-73442c477157', 2200.00, 'ETB', 'pending', 'loan_payments/64efef4f-1555-4322-80ad-f69e46887516/1790437574493_Screenshot_20260924-192616.png', NULL, '2026-09-26 15:52:14.921359+00', NULL, NULL, NULL, '2026-09-26 15:52:14.921359+00', '2026-09-26 15:52:14.921359+00'),
	('342ab08b-31e6-48ae-8185-79e92b88c75d', '64efef4f-1555-4322-80ad-f69e46887516', '750cd972-07bc-4502-8175-5f92f3fda938', 'PAY-20260926-000015', 'loan_repayment', '697e0b5c-c35b-4cb4-8039-73442c477157', 2200.00, 'ETB', 'pending', 'loan_payments/64efef4f-1555-4322-80ad-f69e46887516/1790437609612_Screenshot_20260919-103703.png', NULL, '2026-09-26 15:52:49.004691+00', NULL, NULL, NULL, '2026-09-26 15:52:49.004691+00', '2026-09-26 15:52:49.004691+00'),
	('5f364a75-76fc-443e-a958-86c8fa5485b2', '64efef4f-1555-4322-80ad-f69e46887516', '750cd972-07bc-4502-8175-5f92f3fda938', 'PAY-20260926-000016', 'loan_repayment', '697e0b5c-c35b-4cb4-8039-73442c477157', 2200.00, 'ETB', 'verified', 'loan_payments/64efef4f-1555-4322-80ad-f69e46887516/1790437906704_Screenshot_20260919-103703.png', NULL, '2026-09-26 15:57:46.61777+00', '8a4f38eb-af53-4d05-8ab1-0e332e022710', '2026-09-26 16:42:31.29729+00', NULL, '2026-09-26 15:57:46.61777+00', '2026-09-26 16:42:31.29729+00'),
	('90128ce8-6cf9-4f12-95bb-e8726784195f', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', '750cd972-07bc-4502-8175-5f92f3fda938', 'PAY-20260930-000017', 'savings_contribution', NULL, 12400.00, 'ETB', 'verified', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d/1790756076907.png', '', '2026-09-30 08:17:13.323569+00', '96f15dbd-e885-4f42-8f55-492bd72cd515', '2026-09-30 08:18:46.015939+00', NULL, '2026-09-30 08:17:13.323569+00', '2026-09-30 08:18:46.015939+00'),
	('fc3c775c-b1bd-4791-ae85-98bb2dea4246', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', '750cd972-07bc-4502-8175-5f92f3fda938', 'PAY-20260930-000018', 'savings_contribution', NULL, 100.00, 'ETB', 'verified', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d/1790757498723.png', '', '2026-09-30 08:40:55.575632+00', '96f15dbd-e885-4f42-8f55-492bd72cd515', '2026-09-30 08:41:15.423581+00', NULL, '2026-09-30 08:40:55.575632+00', '2026-09-30 08:41:15.423581+00'),
	('c62d9849-de57-4887-9b0d-2c9f26dd8451', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', '750cd972-07bc-4502-8175-5f92f3fda938', 'PAY-20260930-000019', 'savings_contribution', NULL, 200.00, 'ETB', 'verified', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d/1790757859300.png', '', '2026-09-30 08:46:56.45777+00', '96f15dbd-e885-4f42-8f55-492bd72cd515', '2026-09-30 08:47:55.755996+00', NULL, '2026-09-30 08:46:56.45777+00', '2026-09-30 08:47:55.755996+00'),
	('a0a448fd-f5b8-41f9-9068-1127464e5efe', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', '750cd972-07bc-4502-8175-5f92f3fda938', 'PAY-20260930-000020', 'savings_contribution', NULL, 580.00, 'ETB', 'verified', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d/1790758009286.png', '', '2026-09-30 08:49:26.849124+00', '96f15dbd-e885-4f42-8f55-492bd72cd515', '2026-09-30 08:49:48.76956+00', NULL, '2026-09-30 08:49:26.849124+00', '2026-09-30 08:49:48.76956+00'),
	('57f2ec0e-eb9f-4d31-990b-5dd46702af69', '64efef4f-1555-4322-80ad-f69e46887516', '750cd972-07bc-4502-8175-5f92f3fda938', 'PAY-20261003-000021', 'savings_contribution', '58b6cd59-a675-4cac-8205-c3d7c0eb9507', 2000.00, 'ETB', 'pending', '64efef4f-1555-4322-80ad-f69e46887516/1791033709026.png', '', '2026-10-03 13:21:50.452275+00', NULL, NULL, NULL, '2026-10-03 13:21:50.452275+00', '2026-10-03 13:21:50.452275+00'),
	('deb9ae8b-6df9-421d-8ad9-0bdb7ea90b9e', '64efef4f-1555-4322-80ad-f69e46887516', '750cd972-07bc-4502-8175-5f92f3fda938', 'PAY-20261003-000022', 'loan_repayment', '697e0b5c-c35b-4cb4-8039-73442c477157', 2200.00, 'ETB', 'verified', 'loan_payments/64efef4f-1555-4322-80ad-f69e46887516/1791037244135_Screenshot_20261003-171957.png', NULL, '2026-10-03 14:23:22.457183+00', '3f3e0eb5-aeb1-4999-bd98-18543b01b613', '2026-10-11 13:11:33.658994+00', NULL, '2026-10-03 14:23:22.457183+00', '2026-10-11 13:11:33.658994+00'),
	('f9a97b0a-f9ae-44c5-b7e5-3765f58addc9', 'a9e748d4-dc2b-4d5b-9571-2e2f2bc78e0d', '750cd972-07bc-4502-8175-5f92f3fda938', 'PAY-20261011-000023', 'savings_contribution', '61ec8353-9223-473a-9d7a-ac0a2a3aead0', 2200.00, 'ETB', 'verified', 'a9e748d4-dc2b-4d5b-9571-2e2f2bc78e0d/1791727182516.jpg', '', '2026-10-11 13:59:45.612154+00', '3f3e0eb5-aeb1-4999-bd98-18543b01b613', '2026-10-11 14:00:44.040855+00', NULL, '2026-10-11 13:59:45.612154+00', '2026-10-11 14:00:44.040855+00');


--
-- Data for Name: loan_repayment_submissions; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."loan_repayment_submissions" ("id", "loan_id", "payment_id", "borrower_type", "payer_profile_id", "payer_name", "payer_phone", "amount", "payment_method_code", "external_reference", "payment_proof_path", "status", "submitted_by", "verified_by", "verified_at", "rejected_reason", "posted_transaction_id", "reversed_at", "reversal_transaction_id", "submitted_at", "created_at", "updated_at") VALUES
	('66e80012-ee57-42ca-a95c-dea4eb730168', '697e0b5c-c35b-4cb4-8039-73442c477157', '12e0e40c-d782-4a1b-b0ab-1e9659c5960d', 'member', '64efef4f-1555-4322-80ad-f69e46887516', 'Abdulaz', '+251721777648', 2200.00, 'wallet', NULL, 'loan_payments/64efef4f-1555-4322-80ad-f69e46887516/1790437574493_Screenshot_20260924-192616.png', 'pending', '64efef4f-1555-4322-80ad-f69e46887516', NULL, NULL, NULL, NULL, NULL, NULL, '2026-09-26 15:52:15.283211+00', '2026-09-26 15:52:15.283211+00', '2026-09-26 15:52:15.283211+00'),
	('d1f52f7b-e866-45ad-966d-a88155fdc354', '697e0b5c-c35b-4cb4-8039-73442c477157', '479e9215-a556-414c-9478-e6117e60d0be', 'member', '64efef4f-1555-4322-80ad-f69e46887516', 'Abdulaz', '+251721777648', 2200.00, 'bank', NULL, 'loan_payments/64efef4f-1555-4322-80ad-f69e46887516/1790435286206_Screenshot_20260924-192616.png', 'pending', '64efef4f-1555-4322-80ad-f69e46887516', NULL, NULL, NULL, NULL, NULL, NULL, '2026-09-26 18:08:08.916014+00', '2026-09-26 16:41:26.028362+00', '2026-09-26 16:41:26.028362+00'),
	('8f5dda78-96c4-4f68-8802-44d955bd78ae', '697e0b5c-c35b-4cb4-8039-73442c477157', '636e335b-0bd6-47af-b792-ea4e1707e704', 'member', '64efef4f-1555-4322-80ad-f69e46887516', 'Abdulaz', '+251721777648', 2200.00, 'bank', NULL, 'loan_payments/64efef4f-1555-4322-80ad-f69e46887516/1790435797659_Screenshot_20260924-192616.png', 'pending', '64efef4f-1555-4322-80ad-f69e46887516', NULL, NULL, NULL, NULL, NULL, NULL, '2026-09-26 18:16:39.994793+00', '2026-09-26 16:41:26.028362+00', '2026-09-26 16:41:26.028362+00'),
	('5fbe4d35-2d14-494f-bb53-72324dfaa1f8', '697e0b5c-c35b-4cb4-8039-73442c477157', 'f0c49844-940c-456b-a5f4-72fccf7dbc8c', 'member', '64efef4f-1555-4322-80ad-f69e46887516', 'Abdulaz', '+251721777648', 2200.00, 'bank', NULL, 'loan_payments/64efef4f-1555-4322-80ad-f69e46887516/1790436021167_Screenshot_20260924-192616.png', 'pending', '64efef4f-1555-4322-80ad-f69e46887516', NULL, NULL, NULL, NULL, NULL, NULL, '2026-09-26 18:20:22.768093+00', '2026-09-26 16:41:26.028362+00', '2026-09-26 16:41:26.028362+00'),
	('44c72d99-8beb-4211-8f3c-b37f9235d5b4', '697e0b5c-c35b-4cb4-8039-73442c477157', '65d679c0-c51f-4d56-b2ec-3b5b9142c131', 'member', '64efef4f-1555-4322-80ad-f69e46887516', 'Abdulaz', '+251721777648', 2200.00, 'bank', NULL, 'loan_payments/64efef4f-1555-4322-80ad-f69e46887516/1790436508170_Screenshot_20260924-192616.png', 'pending', '64efef4f-1555-4322-80ad-f69e46887516', NULL, NULL, NULL, NULL, NULL, NULL, '2026-09-26 15:34:27.979024+00', '2026-09-26 16:41:26.028362+00', '2026-09-26 16:41:26.028362+00'),
	('941a326c-8d10-47f5-8ef4-ad5b9bafa870', '697e0b5c-c35b-4cb4-8039-73442c477157', '342ab08b-31e6-48ae-8185-79e92b88c75d', 'member', '64efef4f-1555-4322-80ad-f69e46887516', 'Abdulaz', '+251721777648', 2200.00, 'bank', NULL, 'loan_payments/64efef4f-1555-4322-80ad-f69e46887516/1790437609612_Screenshot_20260919-103703.png', 'pending', '64efef4f-1555-4322-80ad-f69e46887516', NULL, NULL, NULL, NULL, NULL, NULL, '2026-09-26 15:52:49.004691+00', '2026-09-26 16:41:26.028362+00', '2026-09-26 16:41:26.028362+00'),
	('1edf7577-115b-4e43-9847-47fb40c75d08', '697e0b5c-c35b-4cb4-8039-73442c477157', '5f364a75-76fc-443e-a958-86c8fa5485b2', 'member', '64efef4f-1555-4322-80ad-f69e46887516', 'Abdulaz', '+251721777648', 2200.00, 'bank', NULL, 'loan_payments/64efef4f-1555-4322-80ad-f69e46887516/1790437906704_Screenshot_20260919-103703.png', 'posted', '64efef4f-1555-4322-80ad-f69e46887516', '8a4f38eb-af53-4d05-8ab1-0e332e022710', '2026-09-26 16:42:31.29729+00', NULL, '8511fbdd-a716-4570-8b39-3d1ca411f376', NULL, NULL, '2026-09-26 15:57:47.118747+00', '2026-09-26 15:57:47.118747+00', '2026-09-26 16:51:55.854226+00'),
	('7265b741-ecf0-4bff-9bee-66ac8e6c6f48', '697e0b5c-c35b-4cb4-8039-73442c477157', 'deb9ae8b-6df9-421d-8ad9-0bdb7ea90b9e', 'member', '64efef4f-1555-4322-80ad-f69e46887516', 'Abdulaz', '+251721777648', 2200.00, 'bank', NULL, 'loan_payments/64efef4f-1555-4322-80ad-f69e46887516/1791037244135_Screenshot_20261003-171957.png', 'posted', '64efef4f-1555-4322-80ad-f69e46887516', '3f3e0eb5-aeb1-4999-bd98-18543b01b613', '2026-10-11 13:11:33.658994+00', NULL, 'a4e82a41-a3a2-4bdb-82c5-ea870f9a2403', NULL, NULL, '2026-10-03 14:23:22.914562+00', '2026-10-03 14:23:22.914562+00', '2026-10-11 13:11:43.266207+00');


--
-- Data for Name: loan_financial_reversals; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: loan_guarantor_replacement_requests; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: loan_penalties; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: loan_recovery_events; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: loan_repayment_allocations; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."loan_repayment_allocations" ("id", "payment_id", "loan_id", "installment_id", "allocated_base_amount", "allocated_penalty_amount", "transaction_id", "created_at", "repayment_submission_id", "reversed_at", "reversal_transaction_id") VALUES
	('8f9b159a-c308-4f95-9623-93b9cae44a7f', '5f364a75-76fc-443e-a958-86c8fa5485b2', '697e0b5c-c35b-4cb4-8039-73442c477157', '33caaa84-eb2d-42f9-b78e-78a5595c0175', 2200.00, 0.00, '8511fbdd-a716-4570-8b39-3d1ca411f376', '2026-09-26 16:51:55.854226+00', '1edf7577-115b-4e43-9847-47fb40c75d08', NULL, NULL),
	('214704d4-968b-48b7-895f-31a63e06336e', 'deb9ae8b-6df9-421d-8ad9-0bdb7ea90b9e', '697e0b5c-c35b-4cb4-8039-73442c477157', '25524740-b9d7-4e4f-b033-e62180d154a8', 2200.00, 0.00, 'a4e82a41-a3a2-4bdb-82c5-ea870f9a2403', '2026-10-11 13:11:43.266207+00', '7265b741-ecf0-4bff-9bee-66ac8e6c6f48', NULL, NULL);


--
-- Data for Name: member_loan_guarantors; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."member_loan_guarantors" ("id", "loan_application_id", "guarantor_member_id", "requested_amount_snapshot", "service_charge_rate_snapshot", "total_repayment_snapshot", "term_months_snapshot", "status", "requested_at", "responded_at", "rejected_reason", "created_at", "updated_at") VALUES
	('47a2867b-d12d-4407-9371-f5a4c816c539', '0cdb78af-986a-42d6-81c0-530fdab26a65', 'a69eafab-eb8a-435c-8e0c-d3b22fa3b8f9', 6000.00, 0.1000, 6600.00, 3, 'accepted', '2026-09-17 20:08:06.756683+00', '2026-09-19 12:20:41.781721+00', NULL, '2026-09-17 20:08:06.756683+00', '2026-09-19 12:20:41.781721+00'),
	('6a6c6836-85a2-452e-8f8e-051f20c88fa1', 'b0a6c37f-7e99-461a-a710-fb4562181f03', 'a69eafab-eb8a-435c-8e0c-d3b22fa3b8f9', 6000.00, 0.1000, 6600.00, 3, 'released', '2026-09-22 16:27:17.765304+00', '2026-09-24 13:27:13.843168+00', NULL, '2026-09-22 16:27:17.765304+00', '2026-09-24 13:27:13.843168+00'),
	('2092387a-d03c-48ab-b319-8178006d2e0e', 'e621f41a-2e83-4be1-9e3e-1810c9e9bbfb', '9b5bf983-6cba-40b9-890d-f1af17041ffa', 5407.50, 0.1000, 5948.25, 3, 'released', '2026-09-24 13:25:25.848016+00', '2026-09-24 13:36:24.331492+00', NULL, '2026-09-24 13:25:25.848016+00', '2026-09-28 13:16:39.754257+00'),
	('3d2496e9-88f6-46b3-be32-46ad5aaf3604', '60c3f83e-74be-49c2-a00a-233096fa8240', '87e01037-3229-4ca7-bc94-b5a109e312a5', 6000.00, 0.1000, 6600.00, 3, 'released', '2026-09-28 13:19:18.115008+00', '2026-09-28 13:42:37.651515+00', NULL, '2026-09-28 13:19:18.115008+00', '2026-09-28 13:42:37.651515+00'),
	('01910aae-4861-434a-9e0c-6d52e0da8f9f', 'f12c3664-510a-4d1a-93f8-691076167044', '87e01037-3229-4ca7-bc94-b5a109e312a5', 6000.00, 0.1000, 6600.00, 3, 'released', '2026-09-28 14:24:11.543628+00', '2026-09-30 07:18:16.406187+00', NULL, '2026-09-28 14:24:11.543628+00', '2026-09-30 07:23:27.075879+00'),
	('bcdb9c4a-6e02-4ad9-987b-ded3a1455a30', '03a1d0ee-7937-44ab-88f8-41143424864c', '87e01037-3229-4ca7-bc94-b5a109e312a5', 4948.01, 0.1000, 5442.81, 3, 'released', '2026-09-30 07:28:39.727272+00', '2026-09-30 07:34:41.937102+00', NULL, '2026-09-30 07:28:39.727272+00', '2026-09-30 07:42:15.803199+00'),
	('4319181f-9ec4-4b52-8108-35be52621a75', '0fd40d1b-c1f4-4d22-a60c-0bd8ee8d68ab', '87e01037-3229-4ca7-bc94-b5a109e312a5', 3523.58, 0.1000, 3875.94, 3, 'released', '2026-09-30 07:50:49.345629+00', '2026-09-30 08:07:58.35793+00', NULL, '2026-09-30 07:50:49.345629+00', '2026-10-03 14:04:19.379102+00');


--
-- Data for Name: membership_applications; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."membership_applications" ("id", "application_number", "applicant_id", "status", "submitted_at", "reviewed_by", "reviewed_at", "rejection_reason", "created_at", "updated_at") VALUES
	('2c258ebc-0655-4b64-9cfe-b4f2e3ceb91c', 'MEMAPP-000001', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', 'approved', '2026-09-06 11:08:08.662627+00', '96f15dbd-e885-4f42-8f55-492bd72cd515', '2026-09-06 11:10:47.715018+00', NULL, '2026-09-06 11:08:08.662627+00', '2026-09-21 14:00:30.272238+00'),
	('7e785ac0-2fb8-4ed8-a290-ffc17a517fef', 'MEMAPP-000002', '5101cac2-a24e-4342-975a-74df63071328', 'approved', '2026-09-11 11:11:36.886886+00', '96f15dbd-e885-4f42-8f55-492bd72cd515', '2026-09-11 11:13:02.457996+00', NULL, '2026-09-11 11:11:36.886886+00', '2026-09-21 14:00:30.272238+00'),
	('aab5140b-c41d-4518-9067-d64922ebb003', 'MEMAPP-000003', '99c968a2-142f-4329-935d-ef240a5a40f5', 'approved', '2026-09-25 17:26:18.291599+00', '96f15dbd-e885-4f42-8f55-492bd72cd515', '2026-09-25 17:27:16.225866+00', NULL, '2026-09-25 17:26:18.291599+00', '2026-09-25 17:27:16.225866+00'),
	('0f57a0eb-b419-4c0a-bf6f-2862268dcfb8', 'MEMAPP-000004', 'a9e748d4-dc2b-4d5b-9571-2e2f2bc78e0d', 'approved', '2026-10-11 13:44:56.288231+00', '3f3e0eb5-aeb1-4999-bd98-18543b01b613', '2026-10-11 13:46:24.918799+00', NULL, '2026-10-11 13:44:56.288231+00', '2026-10-11 13:46:24.918799+00');


--
-- Data for Name: membership_documents; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."membership_documents" ("id", "application_id", "applicant_id", "storage_path", "file_name", "mime_type", "file_size_bytes", "verification_status", "verified_by", "verified_at", "notes", "created_at", "updated_at") VALUES
	('e989ec3b-9cf4-4ee9-b37c-47575a1dd044', '2c258ebc-0655-4b64-9cfe-b4f2e3ceb91c', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d/1788692884890.jpg', 'CamScanner 06-27-2026 10.35_1.jpg', 'image/jpeg', 663965, 'verified', '96f15dbd-e885-4f42-8f55-492bd72cd515', '2026-09-06 11:10:47.715018+00', NULL, '2026-09-06 11:08:08.662627+00', '2026-09-06 11:10:47.715018+00'),
	('57f629cb-b09e-4162-a251-043498bc9794', '7e785ac0-2fb8-4ed8-a290-ffc17a517fef', '5101cac2-a24e-4342-975a-74df63071328', '5101cac2-a24e-4342-975a-74df63071328/1789125094859.jpg', 'CamScanner 06-27-2026 10.35_1.jpg', 'image/jpeg', 663965, 'verified', '96f15dbd-e885-4f42-8f55-492bd72cd515', '2026-09-11 11:13:02.457996+00', NULL, '2026-09-11 11:11:36.886886+00', '2026-09-11 11:13:02.457996+00'),
	('579778b8-d6f3-4f12-8cd8-ace7e18c86dc', 'aab5140b-c41d-4518-9067-d64922ebb003', '99c968a2-142f-4329-935d-ef240a5a40f5', '99c968a2-142f-4329-935d-ef240a5a40f5/1790356818906.png', 'Screenshot_20260924-192616.png', 'image/png', 77929, 'verified', '96f15dbd-e885-4f42-8f55-492bd72cd515', '2026-09-25 17:27:16.225866+00', NULL, '2026-09-25 17:26:18.291599+00', '2026-09-25 17:27:16.225866+00'),
	('d084faaf-3ac4-474c-b121-dfaaf7a8a1aa', '0f57a0eb-b419-4c0a-bf6f-2862268dcfb8', 'a9e748d4-dc2b-4d5b-9571-2e2f2bc78e0d', 'a9e748d4-dc2b-4d5b-9571-2e2f2bc78e0d/1791726259927.jpg', '20261011_164405.jpg', 'image/jpeg', 6552791, 'verified', '3f3e0eb5-aeb1-4999-bd98-18543b01b613', '2026-10-11 13:46:24.918799+00', NULL, '2026-10-11 13:44:56.288231+00', '2026-10-11 13:46:24.918799+00');


--
-- Data for Name: membership_status_history; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."membership_status_history" ("id", "member_id", "old_status", "new_status", "reason", "changed_by", "created_at") VALUES
	('8d200fdb-0592-47bd-9ac7-3deb18461a4e', 'a69eafab-eb8a-435c-8e0c-d3b22fa3b8f9', NULL, 'active', 'Membership application approved', '96f15dbd-e885-4f42-8f55-492bd72cd515', '2026-09-06 11:10:47.715018+00'),
	('ec100b29-bdca-4d59-843a-b3c9b6c57f25', '87e01037-3229-4ca7-bc94-b5a109e312a5', NULL, 'active', 'Membership application approved', '96f15dbd-e885-4f42-8f55-492bd72cd515', '2026-09-11 11:13:02.457996+00'),
	('b248306e-3613-4051-9b76-51297a94d34f', '92e3f6fb-0b10-4ea2-9212-c2b470c6221b', NULL, 'active', 'Membership application approved', '96f15dbd-e885-4f42-8f55-492bd72cd515', '2026-09-25 17:27:16.225866+00'),
	('faa15dc9-5e9d-4dd0-a34e-1d0c313a325a', '80ea84c9-313d-4927-b066-4fcdd6116226', NULL, 'active', 'Membership application approved', '3f3e0eb5-aeb1-4999-bd98-18543b01b613', '2026-10-11 13:46:24.918799+00');


--
-- Data for Name: notification_devices; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."notification_devices" ("id", "profile_id", "fcm_token", "platform", "app_type", "device_identifier", "app_version", "app_build", "locale", "timezone", "is_active", "last_seen_at", "created_at", "updated_at") VALUES
	('f50bb2d5-4cda-4c27-872e-602a65140f04', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', 'dJzQYVB2ROqVx4WuWQODVs:APA91bEXR1x3gM0D6YG9WZXFFithU7SNjbewiWtTktGTijaAhd7ksatuipxMfBYZP_YuyNlcI6qkJPzJWSPKeB4hhC_T4UT9WE3tCwhSWltrIMFCswSxYvE', 'android', 'member', NULL, NULL, NULL, 'en_US', NULL, false, '2026-09-30 09:08:38.145921+00', '2026-09-30 07:09:29.598781+00', '2026-10-12 12:02:00.750902+00'),
	('70af98a8-503b-4296-93eb-fa0251f9e36e', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', 'eJN_QzDqS1KxYPqt7Suhu4:APA91bGxGyPEEmDjdhu0wDh3OrEmzdN9XraPFj9H_UtBkRwaVa71V5aSnu3DnBmh6xKugQKNwOLR48UK06vF1BDnni6_VqWRs2AufgAnQpE3d2ypVdPaUcg', 'android', 'member', NULL, NULL, NULL, 'en_US', NULL, false, '2026-10-03 10:37:48.94925+00', '2026-10-01 14:34:52.862381+00', '2026-10-12 12:02:00.917645+00'),
	('a9176e60-2693-43a0-a1f2-9f207f7563aa', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', 'f5SME79zQ3yVbnm73rka4o:APA91bH2VLaZjGhOY_26zkmYEmGgJFheuMiHFrupnhWpx0Nra_haT30MQIrXgCbCKL90CtZryshGFmOuMJ5ThDsgeGhmikM2dXCtIt-sM1pYDuIupWHXEy8', 'android', 'member', NULL, NULL, NULL, 'en_US', NULL, false, '2026-09-29 19:28:49.021615+00', '2026-09-29 19:28:49.021615+00', '2026-09-30 07:19:00.64875+00'),
	('3e1289f6-1d0c-4fe4-ba34-4e209ccfe6f2', '64efef4f-1555-4322-80ad-f69e46887516', 'crsXISf3QD6EP6na_OTYgp:APA91bG_vEpyLZLafcFwPnwgcLe-ehACTzRazJfhjDJ_13-Svf2XOmUdLDoAKVV4EbsoBieNXAvgXjOxvXnTyAjjiwC5CSFhlE-GtF4OsISUnpu2KmmaG70', 'android', 'member', NULL, NULL, NULL, 'en_US', NULL, true, '2026-10-12 19:54:10.900614+00', '2026-10-03 13:18:43.938578+00', '2026-10-12 19:54:10.900614+00'),
	('3d6d86cd-69af-488c-aa62-b0860ef4164a', '64efef4f-1555-4322-80ad-f69e46887516', 'e_W57IcaRDW_kdiloFbnFZ:APA91bENZ5prLDJ05HRgITeZBWrfPF9jEnChPhbyvf6PI6svE2AxaPy-JO99j6ZfWLmSNMb4tDUgd1EYK91qVYKH2CkSQjg_9AFe-BZUPYVgpX5SYqOvC2M', 'android', 'member', NULL, NULL, NULL, 'en_US', NULL, true, '2026-10-12 22:22:16.378912+00', '2026-10-12 22:20:08.698657+00', '2026-10-12 22:22:16.378912+00'),
	('bf4b3cd0-4868-4a7c-b6d0-83726a51d054', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', 'cIJ8_NhFTgWH-8u8OlDoiT:APA91bFqQPfmlPNrXORGD-UndF1WP_t4ofOS7qxZKQSaNo6kBkmsvBebZGTFbtOTnPRO4ru9SN29nfmWWv1TRNr01qS6uHJjV6Bzar-cM_N3V-6xAJl7c8I', 'android', 'member', NULL, NULL, NULL, 'en_US', NULL, true, '2026-10-13 05:53:07.416846+00', '2026-10-11 13:05:34.049799+00', '2026-10-13 05:53:07.416846+00'),
	('99d7006f-d938-487f-b46e-b00add6c910b', 'a9e748d4-dc2b-4d5b-9571-2e2f2bc78e0d', 'feItniHxSHyEaRsBF_Z0FP:APA91bGd3_768LIxaNZhOPkxD9IJ5z_I91P9TPz9Dk5W-vm880044XMFTsk7-Se5njFmHjtiD-4-iBc5lcx6uqY33X3LkHqotBPG6QG5q948VJkSEczaxUo', 'android', 'member', NULL, NULL, NULL, 'en_GB', NULL, true, '2026-10-11 13:51:43.25449+00', '2026-10-11 13:42:43.27827+00', '2026-10-11 13:51:43.25449+00');


--
-- Data for Name: notifications; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."notifications" ("id", "recipient_profile_id", "category", "type", "title", "body", "priority", "data", "source_type", "source_id", "dedupe_key", "read_at", "created_at", "expires_at") VALUES
	('e9f5e738-01d3-4fec-8f00-730764c3ccf5', '8a4f38eb-af53-4d05-8ab1-0e332e022710', 'loan', 'loan.application_submitted', 'New loan application', 'Loan application LOANAPP-000008 (3523.58 ETB) is awaiting review.', 'high', '{"member_id": "a69eafab-eb8a-435c-8e0c-d3b22fa3b8f9", "target_type": "loan_application", "borrower_type": "member", "application_id": "0fd40d1b-c1f4-4d22-a60c-0bd8ee8d68ab", "notification_id": "e9f5e738-01d3-4fec-8f00-730764c3ccf5", "requested_amount": 3523.58, "application_number": "LOANAPP-000008"}', 'loan_application', '0fd40d1b-c1f4-4d22-a60c-0bd8ee8d68ab', 'loan_application:submitted:0fd40d1b-c1f4-4d22-a60c-0bd8ee8d68ab', NULL, '2026-09-30 07:50:49.345629+00', NULL),
	('bcc2bc09-1c0e-4876-979f-188be942280e', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', 'loan', 'loan.guarantor_accepted', 'Guarantor accepted', 'Your guarantor has accepted loan application LOANAPP-000006.', 'high', '{"decision": "accepted", "target_type": "loan_application", "application_id": "f12c3664-510a-4d1a-93f8-691076167044", "notification_id": "bcc2bc09-1c0e-4876-979f-188be942280e", "application_number": "LOANAPP-000006", "guarantor_request_id": "01910aae-4861-434a-9e0c-6d52e0da8f9f"}', 'loan_application', 'f12c3664-510a-4d1a-93f8-691076167044', 'guarantor:decision:01910aae-4861-434a-9e0c-6d52e0da8f9f:accepted', '2026-09-30 07:19:45.875065+00', '2026-09-30 07:18:16.406187+00', NULL),
	('86479610-d970-4a46-89ac-a070ccb0c75c', '8a4f38eb-af53-4d05-8ab1-0e332e022710', 'loan', 'loan.application_submitted', 'New loan application', 'Loan application LOANAPP-000007 (4948.01 ETB) is awaiting review.', 'high', '{"member_id": "a69eafab-eb8a-435c-8e0c-d3b22fa3b8f9", "target_type": "loan_application", "borrower_type": "member", "application_id": "03a1d0ee-7937-44ab-88f8-41143424864c", "notification_id": "86479610-d970-4a46-89ac-a070ccb0c75c", "requested_amount": 4948.01, "application_number": "LOANAPP-000007"}', 'loan_application', '03a1d0ee-7937-44ab-88f8-41143424864c', 'loan_application:submitted:03a1d0ee-7937-44ab-88f8-41143424864c', NULL, '2026-09-30 07:28:39.727272+00', NULL),
	('af04aa55-6697-492e-b217-481df68aeb6c', '96f15dbd-e885-4f42-8f55-492bd72cd515', 'loan', 'loan.application_submitted', 'New loan application', 'Loan application LOANAPP-000007 (4948.01 ETB) is awaiting review.', 'high', '{"member_id": "a69eafab-eb8a-435c-8e0c-d3b22fa3b8f9", "target_type": "loan_application", "borrower_type": "member", "application_id": "03a1d0ee-7937-44ab-88f8-41143424864c", "notification_id": "af04aa55-6697-492e-b217-481df68aeb6c", "requested_amount": 4948.01, "application_number": "LOANAPP-000007"}', 'loan_application', '03a1d0ee-7937-44ab-88f8-41143424864c', 'loan_application:submitted:03a1d0ee-7937-44ab-88f8-41143424864c', NULL, '2026-09-30 07:28:39.727272+00', NULL),
	('674fca8c-2ca6-43dd-829e-10c6778acd75', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', 'loan', 'loan.guarantor_accepted', 'Guarantor accepted', 'Your guarantor has accepted loan application LOANAPP-000007.', 'high', '{"decision": "accepted", "target_type": "loan_application", "application_id": "03a1d0ee-7937-44ab-88f8-41143424864c", "notification_id": "674fca8c-2ca6-43dd-829e-10c6778acd75", "application_number": "LOANAPP-000007", "guarantor_request_id": "bcdb9c4a-6e02-4ad9-987b-ded3a1455a30"}', 'loan_application', '03a1d0ee-7937-44ab-88f8-41143424864c', 'guarantor:decision:bcdb9c4a-6e02-4ad9-987b-ded3a1455a30:accepted', '2026-09-30 07:36:19.310015+00', '2026-09-30 07:34:41.937102+00', NULL),
	('adc32970-efe1-4a1f-afe0-0cd0971a5324', '5101cac2-a24e-4342-975a-74df63071328', 'loan', 'loan.guarantor_required', 'Guarantor approval required', 'You have been requested as guarantor for loan application LOANAPP-000007. Open Unity Finance to respond.', 'critical', '{"target_type": "loan_application", "application_id": "03a1d0ee-7937-44ab-88f8-41143424864c", "notification_id": "adc32970-efe1-4a1f-afe0-0cd0971a5324", "application_number": "LOANAPP-000007", "guarantor_request_id": "bcdb9c4a-6e02-4ad9-987b-ded3a1455a30"}', 'loan_application', '03a1d0ee-7937-44ab-88f8-41143424864c', 'guarantor:requested:bcdb9c4a-6e02-4ad9-987b-ded3a1455a30', '2026-09-30 07:34:10.151615+00', '2026-09-30 07:28:39.727272+00', NULL),
	('d27f5332-54cd-4887-9ae4-6afa72175ec4', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', 'loan', 'loan.rejected', 'Loan not approved', 'Loan application LOANAPP-000007 was not approved. Open Unity Finance to review the details.', 'high', '{"decision": "rejected", "target_type": "loan_application", "borrower_type": "member", "application_id": "03a1d0ee-7937-44ab-88f8-41143424864c", "notification_id": "d27f5332-54cd-4887-9ae4-6afa72175ec4", "application_number": "LOANAPP-000007"}', 'loan_application', '03a1d0ee-7937-44ab-88f8-41143424864c', 'loan:decision:03a1d0ee-7937-44ab-88f8-41143424864c:rejected', '2026-09-30 07:42:48.756846+00', '2026-09-30 07:42:15.803199+00', NULL),
	('25069455-9ce3-4d84-8f7c-c866b6196061', '96f15dbd-e885-4f42-8f55-492bd72cd515', 'loan', 'loan.application_submitted', 'New loan application', 'Loan application LOANAPP-000008 (3523.58 ETB) is awaiting review.', 'high', '{"member_id": "a69eafab-eb8a-435c-8e0c-d3b22fa3b8f9", "target_type": "loan_application", "borrower_type": "member", "application_id": "0fd40d1b-c1f4-4d22-a60c-0bd8ee8d68ab", "notification_id": "25069455-9ce3-4d84-8f7c-c866b6196061", "requested_amount": 3523.58, "application_number": "LOANAPP-000008"}', 'loan_application', '0fd40d1b-c1f4-4d22-a60c-0bd8ee8d68ab', 'loan_application:submitted:0fd40d1b-c1f4-4d22-a60c-0bd8ee8d68ab', NULL, '2026-09-30 07:50:49.345629+00', NULL),
	('ad3166ca-8aa4-4c3d-9806-993a205ed914', '3f3e0eb5-aeb1-4999-bd98-18543b01b613', 'loan', 'loan.application_submitted', 'New loan application', 'Loan application LOANAPP-000007 (4948.01 ETB) is awaiting review.', 'high', '{"member_id": "a69eafab-eb8a-435c-8e0c-d3b22fa3b8f9", "target_type": "loan_application", "borrower_type": "member", "application_id": "03a1d0ee-7937-44ab-88f8-41143424864c", "notification_id": "ad3166ca-8aa4-4c3d-9806-993a205ed914", "requested_amount": 4948.01, "application_number": "LOANAPP-000007"}', 'loan_application', '03a1d0ee-7937-44ab-88f8-41143424864c', 'loan_application:submitted:03a1d0ee-7937-44ab-88f8-41143424864c', '2026-10-11 13:14:43.743074+00', '2026-09-30 07:28:39.727272+00', NULL),
	('a808805a-dff9-4f73-b41e-91c19b085c0a', '3f3e0eb5-aeb1-4999-bd98-18543b01b613', 'loan', 'loan.application_submitted', 'New loan application', 'Loan application LOANAPP-000008 (3523.58 ETB) is awaiting review.', 'high', '{"member_id": "a69eafab-eb8a-435c-8e0c-d3b22fa3b8f9", "target_type": "loan_application", "borrower_type": "member", "application_id": "0fd40d1b-c1f4-4d22-a60c-0bd8ee8d68ab", "notification_id": "a808805a-dff9-4f73-b41e-91c19b085c0a", "requested_amount": 3523.58, "application_number": "LOANAPP-000008"}', 'loan_application', '0fd40d1b-c1f4-4d22-a60c-0bd8ee8d68ab', 'loan_application:submitted:0fd40d1b-c1f4-4d22-a60c-0bd8ee8d68ab', '2026-10-11 13:14:43.743074+00', '2026-09-30 07:50:49.345629+00', NULL),
	('51e20728-b136-4aaa-aa61-47464bdb0464', '5101cac2-a24e-4342-975a-74df63071328', 'loan', 'loan.guarantor_required', 'Guarantor approval required', 'You have been requested as guarantor for loan application LOANAPP-000008. Open Unity Finance to respond.', 'critical', '{"target_type": "loan_application", "application_id": "0fd40d1b-c1f4-4d22-a60c-0bd8ee8d68ab", "notification_id": "51e20728-b136-4aaa-aa61-47464bdb0464", "application_number": "LOANAPP-000008", "guarantor_request_id": "4319181f-9ec4-4b52-8108-35be52621a75"}', 'loan_application', '0fd40d1b-c1f4-4d22-a60c-0bd8ee8d68ab', 'guarantor:requested:4319181f-9ec4-4b52-8108-35be52621a75', '2026-09-30 08:01:34.683821+00', '2026-09-30 07:50:49.345629+00', NULL),
	('9fc9b3b8-9d07-46de-87c1-ac77ba877a9a', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', 'transaction', 'transaction.posted', 'Savings contribution posted', 'Transaction TXN-20260930-000024 has been posted to your Unity Finance account. Open the app to review the details.', 'normal', '{"amount": 12400.00, "currency": "ETB", "member_id": "a69eafab-eb8a-435c-8e0c-d3b22fa3b8f9", "profile_id": "a5c1a9c8-6ccd-49c2-a069-2781c83be09d", "target_type": "transaction", "transaction_id": "196244e5-92dc-4450-aa1a-e33fff633d58", "notification_id": "9fc9b3b8-9d07-46de-87c1-ac77ba877a9a", "transaction_type": "savings_contribution", "transaction_reference": "TXN-20260930-000024"}', 'transaction', '196244e5-92dc-4450-aa1a-e33fff633d58', 'transaction:posted:196244e5-92dc-4450-aa1a-e33fff633d58', '2026-10-11 13:16:37.951934+00', '2026-09-30 08:18:46.015939+00', NULL),
	('12fe7d05-a551-48b6-8d5d-6318476afea5', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', 'loan', 'loan.guarantor_accepted', 'Guarantor accepted', 'Your guarantor has accepted loan application LOANAPP-000008.', 'high', '{"decision": "accepted", "target_type": "loan_application", "application_id": "0fd40d1b-c1f4-4d22-a60c-0bd8ee8d68ab", "notification_id": "12fe7d05-a551-48b6-8d5d-6318476afea5", "application_number": "LOANAPP-000008", "guarantor_request_id": "4319181f-9ec4-4b52-8108-35be52621a75"}', 'loan_application', '0fd40d1b-c1f4-4d22-a60c-0bd8ee8d68ab', 'guarantor:decision:4319181f-9ec4-4b52-8108-35be52621a75:accepted', '2026-10-11 13:16:20.650231+00', '2026-09-30 08:07:58.35793+00', NULL),
	('afac0b16-8815-419e-af5f-95b826f4fd74', '8a4f38eb-af53-4d05-8ab1-0e332e022710', 'payment', 'payment.submitted', 'Payment submitted', 'Payment PAY-20260930-000017 of 12400.00 ETB is awaiting verification.', 'normal', '{"amount": 12400.00, "currency": "ETB", "payment_id": "90128ce8-6cf9-4f12-95bb-e8726784195f", "target_type": "payment", "purpose_type": "savings_contribution", "notification_id": "afac0b16-8815-419e-af5f-95b826f4fd74", "payment_reference": "PAY-20260930-000017"}', 'payment', '90128ce8-6cf9-4f12-95bb-e8726784195f', 'payment:submitted:90128ce8-6cf9-4f12-95bb-e8726784195f', NULL, '2026-09-30 08:17:13.323569+00', NULL),
	('a258e185-9b70-463a-a6db-eb865bd88fec', '96f15dbd-e885-4f42-8f55-492bd72cd515', 'payment', 'payment.submitted', 'Payment submitted', 'Payment PAY-20260930-000017 of 12400.00 ETB is awaiting verification.', 'normal', '{"amount": 12400.00, "currency": "ETB", "payment_id": "90128ce8-6cf9-4f12-95bb-e8726784195f", "target_type": "payment", "purpose_type": "savings_contribution", "notification_id": "a258e185-9b70-463a-a6db-eb865bd88fec", "payment_reference": "PAY-20260930-000017"}', 'payment', '90128ce8-6cf9-4f12-95bb-e8726784195f', 'payment:submitted:90128ce8-6cf9-4f12-95bb-e8726784195f', NULL, '2026-09-30 08:17:13.323569+00', NULL),
	('ce984ee4-bda5-4863-a409-ba0749f330af', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', 'transaction', 'transaction.posted', 'Savings contribution posted', 'Transaction TXN-20260930-000025 has been posted to your Unity Finance account. Open the app to review the details.', 'normal', '{"amount": 100.00, "currency": "ETB", "member_id": "a69eafab-eb8a-435c-8e0c-d3b22fa3b8f9", "profile_id": "a5c1a9c8-6ccd-49c2-a069-2781c83be09d", "target_type": "transaction", "transaction_id": "a419bf0e-402d-4835-a411-0a634ac90fcf", "notification_id": "ce984ee4-bda5-4863-a409-ba0749f330af", "transaction_type": "savings_contribution", "transaction_reference": "TXN-20260930-000025"}', 'transaction', 'a419bf0e-402d-4835-a411-0a634ac90fcf', 'transaction:posted:a419bf0e-402d-4835-a411-0a634ac90fcf', '2026-10-11 13:16:28.429109+00', '2026-09-30 08:41:15.423581+00', NULL),
	('564ad434-cff3-404b-a860-e48ad07020b6', '8a4f38eb-af53-4d05-8ab1-0e332e022710', 'payment', 'payment.submitted', 'Payment submitted', 'Payment PAY-20260930-000018 of 100.00 ETB is awaiting verification.', 'normal', '{"amount": 100.00, "currency": "ETB", "payment_id": "fc3c775c-b1bd-4791-ae85-98bb2dea4246", "target_type": "payment", "purpose_type": "savings_contribution", "notification_id": "564ad434-cff3-404b-a860-e48ad07020b6", "payment_reference": "PAY-20260930-000018"}', 'payment', 'fc3c775c-b1bd-4791-ae85-98bb2dea4246', 'payment:submitted:fc3c775c-b1bd-4791-ae85-98bb2dea4246', NULL, '2026-09-30 08:40:55.575632+00', NULL),
	('7b5ac301-9224-457b-a830-de5e307d5fab', '96f15dbd-e885-4f42-8f55-492bd72cd515', 'payment', 'payment.submitted', 'Payment submitted', 'Payment PAY-20260930-000018 of 100.00 ETB is awaiting verification.', 'normal', '{"amount": 100.00, "currency": "ETB", "payment_id": "fc3c775c-b1bd-4791-ae85-98bb2dea4246", "target_type": "payment", "purpose_type": "savings_contribution", "notification_id": "7b5ac301-9224-457b-a830-de5e307d5fab", "payment_reference": "PAY-20260930-000018"}', 'payment', 'fc3c775c-b1bd-4791-ae85-98bb2dea4246', 'payment:submitted:fc3c775c-b1bd-4791-ae85-98bb2dea4246', NULL, '2026-09-30 08:40:55.575632+00', NULL),
	('eec1df94-2021-419b-9399-86fe2fcb0eba', '3f3e0eb5-aeb1-4999-bd98-18543b01b613', 'payment', 'payment.submitted', 'Payment submitted', 'Payment PAY-20260930-000017 of 12400.00 ETB is awaiting verification.', 'normal', '{"amount": 12400.00, "currency": "ETB", "payment_id": "90128ce8-6cf9-4f12-95bb-e8726784195f", "target_type": "payment", "purpose_type": "savings_contribution", "notification_id": "eec1df94-2021-419b-9399-86fe2fcb0eba", "payment_reference": "PAY-20260930-000017"}', 'payment', '90128ce8-6cf9-4f12-95bb-e8726784195f', 'payment:submitted:90128ce8-6cf9-4f12-95bb-e8726784195f', '2026-10-11 13:14:43.743074+00', '2026-09-30 08:17:13.323569+00', NULL),
	('f117e331-dfce-4be0-a514-fe147fcaaef9', '3f3e0eb5-aeb1-4999-bd98-18543b01b613', 'payment', 'payment.submitted', 'Payment submitted', 'Payment PAY-20260930-000018 of 100.00 ETB is awaiting verification.', 'normal', '{"amount": 100.00, "currency": "ETB", "payment_id": "fc3c775c-b1bd-4791-ae85-98bb2dea4246", "target_type": "payment", "purpose_type": "savings_contribution", "notification_id": "f117e331-dfce-4be0-a514-fe147fcaaef9", "payment_reference": "PAY-20260930-000018"}', 'payment', 'fc3c775c-b1bd-4791-ae85-98bb2dea4246', 'payment:submitted:fc3c775c-b1bd-4791-ae85-98bb2dea4246', '2026-10-11 13:14:43.743074+00', '2026-09-30 08:40:55.575632+00', NULL),
	('c53621c9-614f-487c-96b4-9ac49ecd035f', '8a4f38eb-af53-4d05-8ab1-0e332e022710', 'payment', 'payment.submitted', 'Payment submitted', 'Payment PAY-20260930-000019 of 200.00 ETB is awaiting verification.', 'normal', '{"amount": 200.00, "currency": "ETB", "payment_id": "c62d9849-de57-4887-9b0d-2c9f26dd8451", "target_type": "payment", "purpose_type": "savings_contribution", "notification_id": "c53621c9-614f-487c-96b4-9ac49ecd035f", "payment_reference": "PAY-20260930-000019"}', 'payment', 'c62d9849-de57-4887-9b0d-2c9f26dd8451', 'payment:submitted:c62d9849-de57-4887-9b0d-2c9f26dd8451', NULL, '2026-09-30 08:46:56.45777+00', NULL),
	('a1d4f2cd-78e0-4f16-853c-63c37a4d356d', '96f15dbd-e885-4f42-8f55-492bd72cd515', 'payment', 'payment.submitted', 'Payment submitted', 'Payment PAY-20260930-000019 of 200.00 ETB is awaiting verification.', 'normal', '{"amount": 200.00, "currency": "ETB", "payment_id": "c62d9849-de57-4887-9b0d-2c9f26dd8451", "target_type": "payment", "purpose_type": "savings_contribution", "notification_id": "a1d4f2cd-78e0-4f16-853c-63c37a4d356d", "payment_reference": "PAY-20260930-000019"}', 'payment', 'c62d9849-de57-4887-9b0d-2c9f26dd8451', 'payment:submitted:c62d9849-de57-4887-9b0d-2c9f26dd8451', NULL, '2026-09-30 08:46:56.45777+00', NULL),
	('8680a5b8-0028-4a61-bf5b-40b0c325f0f0', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', 'transaction', 'transaction.posted', 'Savings contribution posted', 'Transaction TXN-20260930-000026 has been posted to your Unity Finance account. Open the app to review the details.', 'normal', '{"amount": 200.00, "currency": "ETB", "member_id": "a69eafab-eb8a-435c-8e0c-d3b22fa3b8f9", "profile_id": "a5c1a9c8-6ccd-49c2-a069-2781c83be09d", "target_type": "transaction", "transaction_id": "2a382a5e-f668-4e12-bda5-6ef067f89763", "notification_id": "8680a5b8-0028-4a61-bf5b-40b0c325f0f0", "transaction_type": "savings_contribution", "transaction_reference": "TXN-20260930-000026"}', 'transaction', '2a382a5e-f668-4e12-bda5-6ef067f89763', 'transaction:posted:2a382a5e-f668-4e12-bda5-6ef067f89763', '2026-10-11 13:16:32.630441+00', '2026-09-30 08:47:55.755996+00', NULL),
	('0549a465-eb31-480b-8fb9-c834defcb61f', '8a4f38eb-af53-4d05-8ab1-0e332e022710', 'payment', 'payment.submitted', 'Payment submitted', 'Payment PAY-20260930-000020 of 580.00 ETB is awaiting verification.', 'normal', '{"amount": 580.00, "currency": "ETB", "payment_id": "a0a448fd-f5b8-41f9-9068-1127464e5efe", "target_type": "payment", "purpose_type": "savings_contribution", "notification_id": "0549a465-eb31-480b-8fb9-c834defcb61f", "payment_reference": "PAY-20260930-000020"}', 'payment', 'a0a448fd-f5b8-41f9-9068-1127464e5efe', 'payment:submitted:a0a448fd-f5b8-41f9-9068-1127464e5efe', NULL, '2026-09-30 08:49:26.849124+00', NULL),
	('a28304f4-d3bd-48f0-a090-d3d84f248355', '96f15dbd-e885-4f42-8f55-492bd72cd515', 'payment', 'payment.submitted', 'Payment submitted', 'Payment PAY-20261003-000021 of 2000.00 ETB is awaiting verification.', 'normal', '{"amount": 2000.00, "currency": "ETB", "payment_id": "57f2ec0e-eb9f-4d31-990b-5dd46702af69", "target_type": "payment", "purpose_type": "savings_contribution", "notification_id": "a28304f4-d3bd-48f0-a090-d3d84f248355", "payment_reference": "PAY-20261003-000021"}', 'payment', '57f2ec0e-eb9f-4d31-990b-5dd46702af69', 'payment:submitted:57f2ec0e-eb9f-4d31-990b-5dd46702af69', NULL, '2026-10-03 13:21:50.452275+00', NULL),
	('7e7f37f5-4912-46b4-bf6b-34db99cb4f4e', '96f15dbd-e885-4f42-8f55-492bd72cd515', 'payment', 'payment.submitted', 'Payment submitted', 'Payment PAY-20260930-000020 of 580.00 ETB is awaiting verification.', 'normal', '{"amount": 580.00, "currency": "ETB", "payment_id": "a0a448fd-f5b8-41f9-9068-1127464e5efe", "target_type": "payment", "purpose_type": "savings_contribution", "notification_id": "7e7f37f5-4912-46b4-bf6b-34db99cb4f4e", "payment_reference": "PAY-20260930-000020"}', 'payment', 'a0a448fd-f5b8-41f9-9068-1127464e5efe', 'payment:submitted:a0a448fd-f5b8-41f9-9068-1127464e5efe', '2026-09-30 17:50:40.993814+00', '2026-09-30 08:49:26.849124+00', NULL),
	('d89921d6-3b7d-426d-946c-eb4b68d41e60', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', 'transaction', 'transaction.posted', 'Savings contribution posted', 'Transaction TXN-20260930-000027 has been posted to your Unity Finance account. Open the app to review the details.', 'normal', '{"amount": 580.00, "currency": "ETB", "member_id": "a69eafab-eb8a-435c-8e0c-d3b22fa3b8f9", "profile_id": "a5c1a9c8-6ccd-49c2-a069-2781c83be09d", "target_type": "transaction", "transaction_id": "65dad621-b951-44e7-8549-3e0591b96cfb", "notification_id": "d89921d6-3b7d-426d-946c-eb4b68d41e60", "transaction_type": "savings_contribution", "transaction_reference": "TXN-20260930-000027"}', 'transaction', '65dad621-b951-44e7-8549-3e0591b96cfb', 'transaction:posted:65dad621-b951-44e7-8549-3e0591b96cfb', '2026-10-11 13:16:42.751039+00', '2026-09-30 08:49:48.76956+00', NULL),
	('dc686df5-3bbf-4183-8f30-743e4b03bb7e', '8a4f38eb-af53-4d05-8ab1-0e332e022710', 'payment', 'payment.submitted', 'Payment submitted', 'Payment PAY-20261003-000021 of 2000.00 ETB is awaiting verification.', 'normal', '{"amount": 2000.00, "currency": "ETB", "payment_id": "57f2ec0e-eb9f-4d31-990b-5dd46702af69", "target_type": "payment", "purpose_type": "savings_contribution", "notification_id": "dc686df5-3bbf-4183-8f30-743e4b03bb7e", "payment_reference": "PAY-20261003-000021"}', 'payment', '57f2ec0e-eb9f-4d31-990b-5dd46702af69', 'payment:submitted:57f2ec0e-eb9f-4d31-990b-5dd46702af69', NULL, '2026-10-03 13:21:50.452275+00', NULL),
	('aed2dd0a-ee9d-4387-9e67-06bfad6967b8', '8a4f38eb-af53-4d05-8ab1-0e332e022710', 'payment', 'payment.submitted', 'Payment submitted', 'Payment PAY-20261003-000022 of 2200.00 ETB is awaiting verification.', 'normal', '{"amount": 2200.00, "currency": "ETB", "payment_id": "deb9ae8b-6df9-421d-8ad9-0bdb7ea90b9e", "target_type": "payment", "purpose_type": "loan_repayment", "notification_id": "aed2dd0a-ee9d-4387-9e67-06bfad6967b8", "payment_reference": "PAY-20261003-000022"}', 'payment', 'deb9ae8b-6df9-421d-8ad9-0bdb7ea90b9e', 'payment:submitted:deb9ae8b-6df9-421d-8ad9-0bdb7ea90b9e', NULL, '2026-10-03 14:23:22.457183+00', NULL),
	('30e34fc8-fd06-4981-ba9a-9129de61b0a0', '3f3e0eb5-aeb1-4999-bd98-18543b01b613', 'payment', 'payment.submitted', 'Payment submitted', 'Payment PAY-20260930-000020 of 580.00 ETB is awaiting verification.', 'normal', '{"amount": 580.00, "currency": "ETB", "payment_id": "a0a448fd-f5b8-41f9-9068-1127464e5efe", "target_type": "payment", "purpose_type": "savings_contribution", "notification_id": "30e34fc8-fd06-4981-ba9a-9129de61b0a0", "payment_reference": "PAY-20260930-000020"}', 'payment', 'a0a448fd-f5b8-41f9-9068-1127464e5efe', 'payment:submitted:a0a448fd-f5b8-41f9-9068-1127464e5efe', '2026-10-11 13:14:43.743074+00', '2026-09-30 08:49:26.849124+00', NULL),
	('5f7ef0ac-0abe-4baf-a7b7-489df33e685e', '3f3e0eb5-aeb1-4999-bd98-18543b01b613', 'payment', 'payment.submitted', 'Payment submitted', 'Payment PAY-20261003-000021 of 2000.00 ETB is awaiting verification.', 'normal', '{"amount": 2000.00, "currency": "ETB", "payment_id": "57f2ec0e-eb9f-4d31-990b-5dd46702af69", "target_type": "payment", "purpose_type": "savings_contribution", "notification_id": "5f7ef0ac-0abe-4baf-a7b7-489df33e685e", "payment_reference": "PAY-20261003-000021"}', 'payment', '57f2ec0e-eb9f-4d31-990b-5dd46702af69', 'payment:submitted:57f2ec0e-eb9f-4d31-990b-5dd46702af69', '2026-10-11 13:14:43.743074+00', '2026-10-03 13:21:50.452275+00', NULL),
	('e8c1f920-8c01-4711-b66c-334e498a5ca4', '96f15dbd-e885-4f42-8f55-492bd72cd515', 'payment', 'payment.submitted', 'Payment submitted', 'Payment PAY-20261003-000022 of 2200.00 ETB is awaiting verification.', 'normal', '{"amount": 2200.00, "currency": "ETB", "payment_id": "deb9ae8b-6df9-421d-8ad9-0bdb7ea90b9e", "target_type": "payment", "purpose_type": "loan_repayment", "notification_id": "e8c1f920-8c01-4711-b66c-334e498a5ca4", "payment_reference": "PAY-20261003-000022"}', 'payment', 'deb9ae8b-6df9-421d-8ad9-0bdb7ea90b9e', 'payment:submitted:deb9ae8b-6df9-421d-8ad9-0bdb7ea90b9e', NULL, '2026-10-03 14:23:22.457183+00', NULL),
	('a9c50da6-dd16-4b13-8211-e04a571405ee', '8a4f38eb-af53-4d05-8ab1-0e332e022710', 'payment', 'loan.repayment_submitted', 'Loan repayment submitted', 'A loan repayment submission of 2200.00 ETB is awaiting verification.', 'normal', '{"amount": 2200.00, "loan_id": "697e0b5c-c35b-4cb4-8039-73442c477157", "target_type": "loan_repayment_submission", "borrower_type": "member", "submission_id": "7265b741-ecf0-4bff-9bee-66ac8e6c6f48", "notification_id": "a9c50da6-dd16-4b13-8211-e04a571405ee"}', 'loan_repayment_submission', '7265b741-ecf0-4bff-9bee-66ac8e6c6f48', 'loan_repayment:submitted:7265b741-ecf0-4bff-9bee-66ac8e6c6f48', NULL, '2026-10-03 14:23:22.914562+00', NULL),
	('43efb48d-57e4-4eac-a657-a2c13638741e', '96f15dbd-e885-4f42-8f55-492bd72cd515', 'payment', 'loan.repayment_submitted', 'Loan repayment submitted', 'A loan repayment submission of 2200.00 ETB is awaiting verification.', 'normal', '{"amount": 2200.00, "loan_id": "697e0b5c-c35b-4cb4-8039-73442c477157", "target_type": "loan_repayment_submission", "borrower_type": "member", "submission_id": "7265b741-ecf0-4bff-9bee-66ac8e6c6f48", "notification_id": "43efb48d-57e4-4eac-a657-a2c13638741e"}', 'loan_repayment_submission', '7265b741-ecf0-4bff-9bee-66ac8e6c6f48', 'loan_repayment:submitted:7265b741-ecf0-4bff-9bee-66ac8e6c6f48', NULL, '2026-10-03 14:23:22.914562+00', NULL),
	('9e4f37ce-4492-4ec6-9d12-b2febbd8d9e5', '64efef4f-1555-4322-80ad-f69e46887516', 'transaction', 'transaction.posted', 'Loan repayment posted', 'Transaction TXN-20261011-000028 has been posted to your Unity Finance account. Open the app to review the details.', 'normal', '{"amount": 2200.00, "currency": "ETB", "member_id": "9b5bf983-6cba-40b9-890d-f1af17041ffa", "profile_id": "64efef4f-1555-4322-80ad-f69e46887516", "target_type": "transaction", "transaction_id": "a4e82a41-a3a2-4bdb-82c5-ea870f9a2403", "notification_id": "9e4f37ce-4492-4ec6-9d12-b2febbd8d9e5", "transaction_type": "loan_repayment", "transaction_reference": "TXN-20261011-000028"}', 'transaction', 'a4e82a41-a3a2-4bdb-82c5-ea870f9a2403', 'transaction:posted:a4e82a41-a3a2-4bdb-82c5-ea870f9a2403', NULL, '2026-10-11 13:11:43.266207+00', NULL),
	('77d6e229-f83a-4b35-b1d6-480845a79f93', '3f3e0eb5-aeb1-4999-bd98-18543b01b613', 'payment', 'payment.submitted', 'Payment submitted', 'Payment PAY-20260930-000019 of 200.00 ETB is awaiting verification.', 'normal', '{"amount": 200.00, "currency": "ETB", "payment_id": "c62d9849-de57-4887-9b0d-2c9f26dd8451", "target_type": "payment", "purpose_type": "savings_contribution", "notification_id": "77d6e229-f83a-4b35-b1d6-480845a79f93", "payment_reference": "PAY-20260930-000019"}', 'payment', 'c62d9849-de57-4887-9b0d-2c9f26dd8451', 'payment:submitted:c62d9849-de57-4887-9b0d-2c9f26dd8451', '2026-10-11 13:14:43.743074+00', '2026-09-30 08:46:56.45777+00', NULL),
	('d2a6a8aa-056d-4a4a-a9d7-fe83a54ba34e', '3f3e0eb5-aeb1-4999-bd98-18543b01b613', 'payment', 'payment.submitted', 'Payment submitted', 'Payment PAY-20261003-000022 of 2200.00 ETB is awaiting verification.', 'normal', '{"amount": 2200.00, "currency": "ETB", "payment_id": "deb9ae8b-6df9-421d-8ad9-0bdb7ea90b9e", "target_type": "payment", "purpose_type": "loan_repayment", "notification_id": "d2a6a8aa-056d-4a4a-a9d7-fe83a54ba34e", "payment_reference": "PAY-20261003-000022"}', 'payment', 'deb9ae8b-6df9-421d-8ad9-0bdb7ea90b9e', 'payment:submitted:deb9ae8b-6df9-421d-8ad9-0bdb7ea90b9e', '2026-10-11 13:14:43.743074+00', '2026-10-03 14:23:22.457183+00', NULL),
	('92a75cfe-b16b-4621-a5e0-75af9f166d27', '3f3e0eb5-aeb1-4999-bd98-18543b01b613', 'payment', 'loan.repayment_submitted', 'Loan repayment submitted', 'A loan repayment submission of 2200.00 ETB is awaiting verification.', 'normal', '{"amount": 2200.00, "loan_id": "697e0b5c-c35b-4cb4-8039-73442c477157", "target_type": "loan_repayment_submission", "borrower_type": "member", "submission_id": "7265b741-ecf0-4bff-9bee-66ac8e6c6f48", "notification_id": "92a75cfe-b16b-4621-a5e0-75af9f166d27"}', 'loan_repayment_submission', '7265b741-ecf0-4bff-9bee-66ac8e6c6f48', 'loan_repayment:submitted:7265b741-ecf0-4bff-9bee-66ac8e6c6f48', '2026-10-11 13:14:43.743074+00', '2026-10-03 14:23:22.914562+00', NULL),
	('1ecb27a2-236a-4223-9cbb-1527a4d697a2', 'a9e748d4-dc2b-4d5b-9571-2e2f2bc78e0d', 'transaction', 'transaction.posted', 'Savings penalty posted', 'Transaction TXN-20261011-000029 has been posted to your Unity Finance account. Open the app to review the details.', 'normal', '{"amount": 200.00, "currency": "ETB", "member_id": "80ea84c9-313d-4927-b066-4fcdd6116226", "profile_id": "a9e748d4-dc2b-4d5b-9571-2e2f2bc78e0d", "target_type": "transaction", "transaction_id": "9527b968-e562-47c0-a30a-61daefc9ed50", "notification_id": "1ecb27a2-236a-4223-9cbb-1527a4d697a2", "transaction_type": "savings_late_penalty", "transaction_reference": "TXN-20261011-000029"}', 'transaction', '9527b968-e562-47c0-a30a-61daefc9ed50', 'transaction:posted:9527b968-e562-47c0-a30a-61daefc9ed50', NULL, '2026-10-11 13:56:45.734596+00', NULL),
	('b5c647de-75ab-4998-aa62-e50db7c0dc50', '8a4f38eb-af53-4d05-8ab1-0e332e022710', 'membership', 'membership.application_submitted', 'Membership application submitted', 'A membership application is awaiting review in the admin panel.', 'normal', '{"target_type": "membership_application", "application_id": "0f57a0eb-b419-4c0a-bf6f-2862268dcfb8", "notification_id": "b5c647de-75ab-4998-aa62-e50db7c0dc50"}', 'membership_application', '0f57a0eb-b419-4c0a-bf6f-2862268dcfb8', 'membership:submitted:0f57a0eb-b419-4c0a-bf6f-2862268dcfb8', NULL, '2026-10-11 13:44:56.288231+00', NULL),
	('e2bd1031-8bd2-44b2-bde6-e7a5a4dcafdc', '96f15dbd-e885-4f42-8f55-492bd72cd515', 'membership', 'membership.application_submitted', 'Membership application submitted', 'A membership application is awaiting review in the admin panel.', 'normal', '{"target_type": "membership_application", "application_id": "0f57a0eb-b419-4c0a-bf6f-2862268dcfb8", "notification_id": "e2bd1031-8bd2-44b2-bde6-e7a5a4dcafdc"}', 'membership_application', '0f57a0eb-b419-4c0a-bf6f-2862268dcfb8', 'membership:submitted:0f57a0eb-b419-4c0a-bf6f-2862268dcfb8', NULL, '2026-10-11 13:44:56.288231+00', NULL),
	('04534087-d1cd-4c09-b01e-e5f19f4819bb', 'a9e748d4-dc2b-4d5b-9571-2e2f2bc78e0d', 'membership', 'membership.approved', 'Membership approved', 'Your membership application has been approved. Welcome to Unity Finance Group.', 'high', '{"decision": "approved", "target_type": "membership_application", "application_id": "0f57a0eb-b419-4c0a-bf6f-2862268dcfb8", "notification_id": "04534087-d1cd-4c09-b01e-e5f19f4819bb"}', 'membership_application', '0f57a0eb-b419-4c0a-bf6f-2862268dcfb8', 'membership:decision:0f57a0eb-b419-4c0a-bf6f-2862268dcfb8:approved', NULL, '2026-10-11 13:46:24.918799+00', NULL),
	('b4807209-7f47-4173-ba33-4608853c5ad1', '3f3e0eb5-aeb1-4999-bd98-18543b01b613', 'membership', 'membership.application_submitted', 'Membership application submitted', 'A membership application is awaiting review in the admin panel.', 'normal', '{"target_type": "membership_application", "application_id": "0f57a0eb-b419-4c0a-bf6f-2862268dcfb8", "notification_id": "b4807209-7f47-4173-ba33-4608853c5ad1"}', 'membership_application', '0f57a0eb-b419-4c0a-bf6f-2862268dcfb8', 'membership:submitted:0f57a0eb-b419-4c0a-bf6f-2862268dcfb8', '2026-10-11 13:47:21.629143+00', '2026-10-11 13:44:56.288231+00', NULL),
	('a9240e96-dff5-4e80-b8d1-c5221d17a0ea', '3f3e0eb5-aeb1-4999-bd98-18543b01b613', 'payment', 'payment.submitted', 'Payment submitted', 'Payment PAY-20261011-000023 of 2200.00 ETB is awaiting verification.', 'normal', '{"amount": 2200.00, "currency": "ETB", "payment_id": "f9a97b0a-f9ae-44c5-b7e5-3765f58addc9", "target_type": "payment", "purpose_type": "savings_contribution", "notification_id": "a9240e96-dff5-4e80-b8d1-c5221d17a0ea", "payment_reference": "PAY-20261011-000023"}', 'payment', 'f9a97b0a-f9ae-44c5-b7e5-3765f58addc9', 'payment:submitted:f9a97b0a-f9ae-44c5-b7e5-3765f58addc9', NULL, '2026-10-11 13:59:45.612154+00', NULL),
	('fe9510bc-6476-43ba-9ea3-593b9acc7abb', '8a4f38eb-af53-4d05-8ab1-0e332e022710', 'payment', 'payment.submitted', 'Payment submitted', 'Payment PAY-20261011-000023 of 2200.00 ETB is awaiting verification.', 'normal', '{"amount": 2200.00, "currency": "ETB", "payment_id": "f9a97b0a-f9ae-44c5-b7e5-3765f58addc9", "target_type": "payment", "purpose_type": "savings_contribution", "notification_id": "fe9510bc-6476-43ba-9ea3-593b9acc7abb", "payment_reference": "PAY-20261011-000023"}', 'payment', 'f9a97b0a-f9ae-44c5-b7e5-3765f58addc9', 'payment:submitted:f9a97b0a-f9ae-44c5-b7e5-3765f58addc9', NULL, '2026-10-11 13:59:45.612154+00', NULL),
	('4035673a-9f8a-4638-adaf-b21d85ef0a95', '96f15dbd-e885-4f42-8f55-492bd72cd515', 'payment', 'payment.submitted', 'Payment submitted', 'Payment PAY-20261011-000023 of 2200.00 ETB is awaiting verification.', 'normal', '{"amount": 2200.00, "currency": "ETB", "payment_id": "f9a97b0a-f9ae-44c5-b7e5-3765f58addc9", "target_type": "payment", "purpose_type": "savings_contribution", "notification_id": "4035673a-9f8a-4638-adaf-b21d85ef0a95", "payment_reference": "PAY-20261011-000023"}', 'payment', 'f9a97b0a-f9ae-44c5-b7e5-3765f58addc9', 'payment:submitted:f9a97b0a-f9ae-44c5-b7e5-3765f58addc9', NULL, '2026-10-11 13:59:45.612154+00', NULL),
	('08f96992-cd68-4d49-baa2-7cc8d61186be', 'a9e748d4-dc2b-4d5b-9571-2e2f2bc78e0d', 'transaction', 'transaction.posted', 'Savings contribution posted', 'Transaction TXN-20261011-000030 has been posted to your Unity Finance account. Open the app to review the details.', 'normal', '{"amount": 2200.00, "currency": "ETB", "member_id": "80ea84c9-313d-4927-b066-4fcdd6116226", "profile_id": "a9e748d4-dc2b-4d5b-9571-2e2f2bc78e0d", "target_type": "transaction", "transaction_id": "0005f65d-4b7c-4307-846c-87f9946e452c", "notification_id": "08f96992-cd68-4d49-baa2-7cc8d61186be", "transaction_type": "savings_contribution", "transaction_reference": "TXN-20261011-000030"}', 'transaction', '0005f65d-4b7c-4307-846c-87f9946e452c', 'transaction:posted:0005f65d-4b7c-4307-846c-87f9946e452c', '2026-10-11 14:01:51.350966+00', '2026-10-11 14:00:44.040855+00', NULL),
	('1bcedeb6-70bd-4655-83d1-4cd0d71d74b0', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', 'transaction', 'transaction.posted', 'Savings penalty posted', 'Transaction TXN-20261013-000033 has been posted to your Unity Finance account. Open the app to review the details.', 'normal', '{"amount": 200.00, "currency": "ETB", "member_id": "a69eafab-eb8a-435c-8e0c-d3b22fa3b8f9", "profile_id": "a5c1a9c8-6ccd-49c2-a069-2781c83be09d", "target_type": "transaction", "transaction_id": "c3e1e0de-cacc-435f-a1ce-9bedde365f8a", "notification_id": "1bcedeb6-70bd-4655-83d1-4cd0d71d74b0", "transaction_type": "savings_late_penalty", "transaction_reference": "TXN-20261013-000033"}', 'transaction', 'c3e1e0de-cacc-435f-a1ce-9bedde365f8a', 'transaction:posted:c3e1e0de-cacc-435f-a1ce-9bedde365f8a', NULL, '2026-10-13 05:53:03.385181+00', NULL),
	('aa5d1a04-bcaf-4fd8-8478-6342d233b323', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', 'transaction', 'transaction.posted', 'Savings penalty posted', 'Transaction TXN-20261012-000031 has been posted to your Unity Finance account. Open the app to review the details.', 'normal', '{"amount": 200.00, "currency": "ETB", "member_id": "a69eafab-eb8a-435c-8e0c-d3b22fa3b8f9", "profile_id": "a5c1a9c8-6ccd-49c2-a069-2781c83be09d", "target_type": "transaction", "transaction_id": "2071c21d-2864-469c-bd0f-04bf99ab8bd6", "notification_id": "aa5d1a04-bcaf-4fd8-8478-6342d233b323", "transaction_type": "savings_late_penalty", "transaction_reference": "TXN-20261012-000031"}', 'transaction', '2071c21d-2864-469c-bd0f-04bf99ab8bd6', 'transaction:posted:2071c21d-2864-469c-bd0f-04bf99ab8bd6', '2026-10-12 12:02:12.620482+00', '2026-10-12 12:02:00.082692+00', NULL),
	('9a3bc2d2-e877-407b-aa13-1d210c3a39ce', '64efef4f-1555-4322-80ad-f69e46887516', 'transaction', 'transaction.posted', 'Savings penalty posted', 'Transaction TXN-20261012-000032 has been posted to your Unity Finance account. Open the app to review the details.', 'normal', '{"amount": 200.00, "currency": "ETB", "member_id": "9b5bf983-6cba-40b9-890d-f1af17041ffa", "profile_id": "64efef4f-1555-4322-80ad-f69e46887516", "target_type": "transaction", "transaction_id": "7a42f117-ab6e-4cdf-91b7-0d561b49e982", "notification_id": "9a3bc2d2-e877-407b-aa13-1d210c3a39ce", "transaction_type": "savings_late_penalty", "transaction_reference": "TXN-20261012-000032"}', 'transaction', '7a42f117-ab6e-4cdf-91b7-0d561b49e982', 'transaction:posted:7a42f117-ab6e-4cdf-91b7-0d561b49e982', NULL, '2026-10-12 19:53:52.037205+00', NULL);


--
-- Data for Name: notification_deliveries; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."notification_deliveries" ("id", "notification_id", "device_id", "channel", "status", "attempt_count", "available_at", "lease_until", "provider_message_id", "last_error_code", "last_error_message", "created_at", "sent_at", "updated_at") VALUES
	('0d0dfcd2-a50f-475c-b7b4-a842c87eaedb', 'bcc2bc09-1c0e-4876-979f-188be942280e', 'a9176e60-2693-43a0-a1f2-9f207f7563aa', 'fcm', 'invalid', 1, '2026-09-30 07:18:16.406187+00', NULL, NULL, 'UNREGISTERED', 'NotRegistered', '2026-09-30 07:18:16.406187+00', NULL, '2026-09-30 07:19:00.64875+00'),
	('09bd39b6-3cc0-43ed-ba51-367c417e401d', 'd27f5332-54cd-4887-9ae4-6afa72175ec4', 'f50bb2d5-4cda-4c27-872e-602a65140f04', 'fcm', 'sent', 1, '2026-09-30 07:42:15.803199+00', NULL, 'projects/unity-finance-group-ufg/messages/0:1790754180586325%b229e45fb229e45f', NULL, NULL, '2026-09-30 07:42:15.803199+00', '2026-09-30 07:43:00.601418+00', '2026-09-30 07:43:00.601418+00'),
	('1df9293e-e0b1-45cf-a19c-12fdb90fa97b', '9fc9b3b8-9d07-46de-87c1-ac77ba877a9a', 'f50bb2d5-4cda-4c27-872e-602a65140f04', 'fcm', 'sent', 1, '2026-09-30 08:18:46.015939+00', NULL, 'projects/unity-finance-group-ufg/messages/0:1790756340654286%b229e45fb229e45f', NULL, NULL, '2026-09-30 08:18:46.015939+00', '2026-09-30 08:19:00.686804+00', '2026-09-30 08:19:00.686804+00'),
	('fc41c2a6-81b8-4dfc-ad59-b860864c215a', 'ce984ee4-bda5-4863-a409-ba0749f330af', 'f50bb2d5-4cda-4c27-872e-602a65140f04', 'fcm', 'sent', 1, '2026-09-30 08:41:15.423581+00', NULL, 'projects/unity-finance-group-ufg/messages/0:1790757720863049%b229e45fb229e45f', NULL, NULL, '2026-09-30 08:41:15.423581+00', '2026-09-30 08:42:00.892826+00', '2026-09-30 08:42:00.892826+00'),
	('350d03db-d53d-4425-b21c-b02f56d06674', '8680a5b8-0028-4a61-bf5b-40b0c325f0f0', 'f50bb2d5-4cda-4c27-872e-602a65140f04', 'fcm', 'sent', 1, '2026-09-30 08:47:55.755996+00', NULL, 'projects/unity-finance-group-ufg/messages/0:1790758080650018%b229e45fb229e45f', NULL, NULL, '2026-09-30 08:47:55.755996+00', '2026-09-30 08:48:00.674357+00', '2026-09-30 08:48:00.674357+00'),
	('d4379489-ccb8-4ba0-a05e-bb4828e81711', 'd89921d6-3b7d-426d-946c-eb4b68d41e60', 'f50bb2d5-4cda-4c27-872e-602a65140f04', 'fcm', 'sent', 1, '2026-09-30 08:49:48.76956+00', NULL, 'projects/unity-finance-group-ufg/messages/0:1790758201866429%b229e45fb229e45f', NULL, NULL, '2026-09-30 08:49:48.76956+00', '2026-09-30 08:50:01.896022+00', '2026-09-30 08:50:01.896022+00'),
	('45584017-1301-4179-9bc3-cbc1d7721f07', '9e4f37ce-4492-4ec6-9d12-b2febbd8d9e5', '3e1289f6-1d0c-4fe4-ba34-4e209ccfe6f2', 'fcm', 'sent', 1, '2026-10-11 13:11:43.266207+00', NULL, 'projects/unity-finance-group-ufg/messages/0:1791724320903398%b229e45fb229e45f', NULL, NULL, '2026-10-11 13:11:43.266207+00', '2026-10-11 13:12:00.96848+00', '2026-10-11 13:12:00.96848+00'),
	('0f27278e-0083-418d-8515-e82e0cf07756', '04534087-d1cd-4c09-b01e-e5f19f4819bb', '99d7006f-d938-487f-b46e-b00add6c910b', 'fcm', 'sent', 1, '2026-10-11 13:46:24.918799+00', NULL, 'projects/unity-finance-group-ufg/messages/0:1791726420784551%b229e45fb229e45f', NULL, NULL, '2026-10-11 13:46:24.918799+00', '2026-10-11 13:47:00.805439+00', '2026-10-11 13:47:00.805439+00'),
	('78c75915-3708-4fd0-b8ef-54569c44f75e', '1ecb27a2-236a-4223-9cbb-1527a4d697a2', '99d7006f-d938-487f-b46e-b00add6c910b', 'fcm', 'sent', 1, '2026-10-11 13:56:45.734596+00', NULL, 'projects/unity-finance-group-ufg/messages/0:1791727020653887%b229e45fb229e45f', NULL, NULL, '2026-10-11 13:56:45.734596+00', '2026-10-11 13:57:00.68295+00', '2026-10-11 13:57:00.68295+00'),
	('c3846393-91fd-4e6f-897d-083e2b34f276', '08f96992-cd68-4d49-baa2-7cc8d61186be', '99d7006f-d938-487f-b46e-b00add6c910b', 'fcm', 'sent', 1, '2026-10-11 14:00:44.040855+00', NULL, 'projects/unity-finance-group-ufg/messages/0:1791727260808723%b229e45fb229e45f', NULL, NULL, '2026-10-11 14:00:44.040855+00', '2026-10-11 14:01:00.846914+00', '2026-10-11 14:01:00.846914+00'),
	('94b48d25-8eb8-4e9f-afca-1ae0b7fd0867', 'aa5d1a04-bcaf-4fd8-8478-6342d233b323', 'bf4b3cd0-4868-4a7c-b6d0-83726a51d054', 'fcm', 'sent', 1, '2026-10-12 12:02:00.082692+00', NULL, 'projects/unity-finance-group-ufg/messages/0:1791806520551672%b229e45fb229e45f', NULL, NULL, '2026-10-12 12:02:00.082692+00', '2026-10-12 12:02:00.579614+00', '2026-10-12 12:02:00.579614+00'),
	('48e22cd7-06f7-4f6f-8ed1-a519badc0916', 'aa5d1a04-bcaf-4fd8-8478-6342d233b323', 'f50bb2d5-4cda-4c27-872e-602a65140f04', 'fcm', 'invalid', 1, '2026-10-12 12:02:00.082692+00', NULL, NULL, 'UNREGISTERED', 'NotRegistered', '2026-10-12 12:02:00.082692+00', NULL, '2026-10-12 12:02:00.750902+00'),
	('9ec9b198-cb44-4f64-8bb4-d84bfbe25f52', 'aa5d1a04-bcaf-4fd8-8478-6342d233b323', '70af98a8-503b-4296-93eb-fa0251f9e36e', 'fcm', 'invalid', 1, '2026-10-12 12:02:00.082692+00', NULL, NULL, 'UNREGISTERED', 'NotRegistered', '2026-10-12 12:02:00.082692+00', NULL, '2026-10-12 12:02:00.917645+00'),
	('6cbdb64d-148f-4e5f-ac46-7ee397bc0eda', '9a3bc2d2-e877-407b-aa13-1d210c3a39ce', '3e1289f6-1d0c-4fe4-ba34-4e209ccfe6f2', 'fcm', 'sent', 1, '2026-10-12 19:53:52.037205+00', NULL, 'projects/unity-finance-group-ufg/messages/0:1791834840694706%b229e45fb229e45f', NULL, NULL, '2026-10-12 19:53:52.037205+00', '2026-10-12 19:54:00.733081+00', '2026-10-12 19:54:00.733081+00'),
	('e3cd96e7-2606-48b5-bd28-a62295261417', '1bcedeb6-70bd-4655-83d1-4cd0d71d74b0', 'bf4b3cd0-4868-4a7c-b6d0-83726a51d054', 'fcm', 'sent', 1, '2026-10-13 05:53:03.385181+00', NULL, 'projects/unity-finance-group-ufg/messages/0:1791870841352802%b229e45fb229e45f', NULL, NULL, '2026-10-13 05:53:03.385181+00', '2026-10-13 05:54:01.376208+00', '2026-10-13 05:54:01.376208+00');


--
-- Data for Name: notification_preferences; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."notification_preferences" ("profile_id", "push_enabled", "transaction_push_enabled", "payment_push_enabled", "savings_push_enabled", "loan_push_enabled", "membership_push_enabled", "system_push_enabled", "updated_at") VALUES
	('64efef4f-1555-4322-80ad-f69e46887516', true, true, true, true, true, true, true, '2026-09-29 16:08:06.623504+00'),
	('99c968a2-142f-4329-935d-ef240a5a40f5', true, true, true, true, true, true, true, '2026-09-29 16:08:06.623504+00'),
	('a5c1a9c8-6ccd-49c2-a069-2781c83be09d', true, true, true, true, true, true, true, '2026-09-29 16:08:06.623504+00'),
	('5101cac2-a24e-4342-975a-74df63071328', true, true, true, true, true, true, true, '2026-09-29 16:08:06.623504+00'),
	('3f3e0eb5-aeb1-4999-bd98-18543b01b613', true, true, true, true, true, true, true, '2026-09-29 16:08:06.623504+00'),
	('96f15dbd-e885-4f42-8f55-492bd72cd515', true, true, true, true, true, true, true, '2026-09-29 16:08:06.623504+00'),
	('8a4f38eb-af53-4d05-8ab1-0e332e022710', true, true, true, true, true, true, true, '2026-09-29 16:08:06.623504+00'),
	('a9e748d4-dc2b-4d5b-9571-2e2f2bc78e0d', true, true, true, true, true, true, true, '2026-10-11 13:42:26.762591+00');


--
-- Data for Name: outsider_loan_guarantors; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."outsider_loan_guarantors" ("id", "outsider_loan_application_id", "guarantor_member_id", "requested_amount_snapshot", "service_charge_rate_snapshot", "total_repayment_snapshot", "term_months_snapshot", "guaranteed_max_amount_snapshot", "status", "requested_at", "responded_at", "rejected_reason", "created_at", "updated_at") VALUES
	('8dcffd65-5fa9-4388-b7b0-c5b8e71eca48', '3c488e6c-15f3-427b-8208-26b4476fcfd6', '9b5bf983-6cba-40b9-890d-f1af17041ffa', 600.00, 0.1500, 690.00, 3, 4000.00, 'requested', '2026-09-08 08:08:03.922448+00', NULL, NULL, '2026-09-08 08:08:03.922448+00', '2026-09-08 08:08:03.922448+00');


--
-- Data for Name: payment_verifications; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."payment_verifications" ("id", "payment_id", "verification_type", "status", "verified_by", "external_reference", "evidence", "verified_at", "created_at") VALUES
	('86c1bd0e-4976-41d5-aa75-119fb7ea9ea0', 'fbaccbd0-9228-420b-a5c1-be9fc1e361c0', 'manual', 'verified', '96f15dbd-e885-4f42-8f55-492bd72cd515', 'vfd', '{"admin_action": "admin_verify_savings_payment"}', '2026-09-06 10:19:06.701024+00', '2026-09-06 10:19:06.701024+00'),
	('881f636c-aeea-4ce0-b6bf-bf0836b7ac4f', '59147fd5-2507-4596-81e7-a055354c8811', 'manual', 'verified', '96f15dbd-e885-4f42-8f55-492bd72cd515', 'ft47888943', '{"admin_action": "admin_verify_savings_payment"}', '2026-09-06 11:16:04.442067+00', '2026-09-06 11:16:04.442067+00'),
	('55a893b3-2e57-4a8d-814f-aa004d469b09', '109328cc-ed3a-46c8-b087-41fb420d31ee', 'manual', 'verified', '96f15dbd-e885-4f42-8f55-492bd72cd515', 'ASXZSXZC', '{"admin_action": "admin_verify_savings_payment"}', '2026-09-09 14:21:37.970045+00', '2026-09-09 14:21:37.970045+00'),
	('c84e93a3-fb4f-4dfe-9d83-b2f3d5985a88', '54b6e21a-046f-4d16-90a5-51f552762ec9', 'manual', 'verified', '96f15dbd-e885-4f42-8f55-492bd72cd515', 'assss', '{"admin_action": "admin_verify_savings_payment"}', '2026-09-11 10:55:52.018182+00', '2026-09-11 10:55:52.018182+00'),
	('be856f1b-03f7-4989-96b1-f9da464dce9d', 'd6370408-53b4-4721-a77a-9f7ca9752fb6', 'manual', 'verified', '96f15dbd-e885-4f42-8f55-492bd72cd515', 'hsj', '{"admin_action": "admin_verify_savings_payment"}', '2026-09-11 10:56:16.342875+00', '2026-09-11 10:56:16.342875+00'),
	('c44ad73b-fd63-4519-b22c-612e259a388d', '4d9da62a-9eb8-43d9-bdb2-f1149488e965', 'manual', 'verified', '96f15dbd-e885-4f42-8f55-492bd72cd515', 'asdcxfvde', '{"admin_action": "admin_verify_savings_payment"}', '2026-09-19 12:40:37.989294+00', '2026-09-19 12:40:37.989294+00'),
	('4aec4434-d9a1-4120-a4ad-66751d440475', '5466e990-f3e9-47e3-9bf9-cef346bd10ec', 'manual', 'verified', '96f15dbd-e885-4f42-8f55-492bd72cd515', '', '{"admin_action": "admin_verify_savings_payment"}', '2026-09-21 15:36:06.095985+00', '2026-09-21 15:36:06.095985+00'),
	('c304af01-b228-4458-a049-0c1d9903e014', '9875ebd6-1669-40a5-9e62-9bcfe2998350', 'manual', 'verified', '96f15dbd-e885-4f42-8f55-492bd72cd515', '', '{"admin_action": "admin_verify_savings_payment"}', '2026-09-22 13:06:15.904186+00', '2026-09-22 13:06:15.904186+00'),
	('167d680b-2be3-4ccb-97f5-f80a83386ac0', '5fdc0d24-755f-45fb-889d-60ac33af196f', 'manual', 'verified', '96f15dbd-e885-4f42-8f55-492bd72cd515', '', '{"admin_action": "admin_verify_savings_payment"}', '2026-09-22 14:26:33.667288+00', '2026-09-22 14:26:33.667288+00'),
	('a3371883-8ff6-49c7-ad09-1c9adf79d6dd', '5f364a75-76fc-443e-a958-86c8fa5485b2', 'manual_loan_repayment', 'verified', '8a4f38eb-af53-4d05-8ab1-0e332e022710', NULL, '{"loan_repayment_submission_id": "1edf7577-115b-4e43-9847-47fb40c75d08"}', '2026-09-26 16:42:31.29729+00', '2026-09-26 16:42:31.29729+00'),
	('2ff26987-7621-49e2-ade7-a4153165aa77', '90128ce8-6cf9-4f12-95bb-e8726784195f', 'manual', 'verified', '96f15dbd-e885-4f42-8f55-492bd72cd515', '', '{"admin_action": "admin_verify_savings_payment"}', '2026-09-30 08:18:46.015939+00', '2026-09-30 08:18:46.015939+00'),
	('2e3ae3cb-863f-41f6-9bc7-6211d7124940', 'fc3c775c-b1bd-4791-ae85-98bb2dea4246', 'manual', 'verified', '96f15dbd-e885-4f42-8f55-492bd72cd515', '', '{"admin_action": "admin_verify_savings_payment"}', '2026-09-30 08:41:15.423581+00', '2026-09-30 08:41:15.423581+00'),
	('13813bdc-3c9a-427b-8579-7fe74cdf1312', 'c62d9849-de57-4887-9b0d-2c9f26dd8451', 'manual', 'verified', '96f15dbd-e885-4f42-8f55-492bd72cd515', '', '{"admin_action": "admin_verify_savings_payment"}', '2026-09-30 08:47:55.755996+00', '2026-09-30 08:47:55.755996+00'),
	('d933d1d6-0b2f-48a8-bcc8-48225aef202c', 'a0a448fd-f5b8-41f9-9068-1127464e5efe', 'manual', 'verified', '96f15dbd-e885-4f42-8f55-492bd72cd515', '', '{"admin_action": "admin_verify_savings_payment"}', '2026-09-30 08:49:48.76956+00', '2026-09-30 08:49:48.76956+00'),
	('6a9fd551-5b89-4211-827b-f3d47fa388c2', 'deb9ae8b-6df9-421d-8ad9-0bdb7ea90b9e', 'manual_loan_repayment', 'verified', '3f3e0eb5-aeb1-4999-bd98-18543b01b613', NULL, '{"loan_repayment_submission_id": "7265b741-ecf0-4bff-9bee-66ac8e6c6f48"}', '2026-10-11 13:11:33.658994+00', '2026-10-11 13:11:33.658994+00'),
	('340fb886-2f02-4d0c-b998-4af641630bd0', 'f9a97b0a-f9ae-44c5-b7e5-3765f58addc9', 'manual', 'verified', '3f3e0eb5-aeb1-4999-bd98-18543b01b613', '', '{"admin_action": "admin_verify_savings_payment"}', '2026-10-11 14:00:44.040855+00', '2026-10-11 14:00:44.040855+00');


--
-- Data for Name: permissions; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."permissions" ("id", "code", "name", "description", "created_at") VALUES
	('fd4e4597-651b-4a42-a3e7-f3cb878be8ad', 'profile.read_own', 'Read own profile', 'Read own profile', '2026-08-26 19:36:24.648374+00'),
	('10ad3ada-2692-402f-880c-08bad0887e46', 'profile.update_own', 'Update own profile', 'Update own profile', '2026-08-26 19:36:24.648374+00'),
	('65f5c1a7-0cc5-45ba-9c2f-131d23c5f3c7', 'membership.apply', 'Apply for membership', 'Submit membership application', '2026-08-26 19:36:24.648374+00'),
	('53ad5026-0a17-44c8-9835-0dcf65ea88f6', 'membership.read', 'Read membership', 'Read membership records', '2026-08-26 19:36:24.648374+00'),
	('b1c0c994-b47f-4c78-aab7-64acea172d7c', 'membership.approve', 'Approve membership', 'Approve or reject membership applications', '2026-08-26 19:36:24.648374+00'),
	('c99a6aa1-a4ee-454e-a225-0d4f57941932', 'savings.read_own', 'Read own savings', 'Read own savings data', '2026-08-26 19:36:24.648374+00'),
	('21458a7e-d9cd-4998-91f0-5c5f8075de28', 'savings.contribute', 'Contribute savings', 'Submit savings payment', '2026-08-26 19:36:24.648374+00'),
	('e7f0f766-a1a1-4ce7-80be-0f38ae2700de', 'savings.withdraw.request', 'Request withdrawal', 'Request savings withdrawal', '2026-08-26 19:36:24.648374+00'),
	('0d1981b2-facf-49df-803e-14de6187dd96', 'savings.withdraw.approve', 'Approve withdrawal', 'Approve savings withdrawal', '2026-08-26 19:36:24.648374+00'),
	('bc61bc03-4da8-4b2d-b325-acdcd6542648', 'payment.create', 'Create payment', 'Create payment request', '2026-08-26 19:36:24.648374+00'),
	('526ddb63-9448-41ef-820c-53efce8049da', 'payment.verify', 'Verify payment', 'Verify manual payments', '2026-08-26 19:36:24.648374+00'),
	('c3949937-4900-4bc2-8942-98aaddba8eca', 'loan.apply', 'Apply for loan', 'Create loan application', '2026-08-26 19:36:24.648374+00'),
	('e016bf2a-6d00-4419-9abc-428ca00d44a0', 'loan.read', 'Read loans', 'Read permitted loan data', '2026-08-26 19:36:24.648374+00'),
	('3f8cc74e-cb9b-4e6e-a0bb-7cf03742aad2', 'loan.review', 'Review loan', 'Review loan application', '2026-08-26 19:36:24.648374+00'),
	('1f710976-54a1-4eec-b535-01a794ae504d', 'loan.approve', 'Approve loan', 'Approve loan application', '2026-08-26 19:36:24.648374+00'),
	('dfa0d52f-1c6a-47c8-813b-f65c4c268025', 'loan.disburse', 'Disburse loan', 'Release approved loan', '2026-08-26 19:36:24.648374+00'),
	('76cdc19e-b4ec-467e-af8c-0039611034a4', 'loan.repay', 'Repay loan', 'Record loan repayment', '2026-08-26 19:36:24.648374+00'),
	('a8ecbdd4-1f8a-4409-a770-f2ac0e11070d', 'guarantor.respond', 'Respond as guarantor', 'Accept or reject guarantee request', '2026-08-26 19:36:24.648374+00'),
	('ce0c29a5-0b6b-4adf-b5b4-e14a4c42f49c', 'ledger.read', 'Read ledger', 'Read ledger/transaction data', '2026-08-26 19:36:24.648374+00'),
	('beaf6982-1435-4bf6-9587-1c9bac2d6632', 'ledger.reverse', 'Reverse transaction', 'Create reversal/correction', '2026-08-26 19:36:24.648374+00'),
	('88587afe-9b24-412f-ba8b-faabb59b90c0', 'expense.create', 'Create expense', 'Create expense request', '2026-08-26 19:36:24.648374+00'),
	('51d50b18-220b-4d67-ac65-d7365490bcdc', 'expense.approve', 'Approve expense', 'Approve expense', '2026-08-26 19:36:24.648374+00'),
	('e67bf5c5-7601-402b-a5b4-ccbe06588020', 'reports.read', 'Read reports', 'Read management reports', '2026-08-26 19:36:24.648374+00'),
	('32c0a0f7-00e5-4f17-9458-6f558960dfcf', 'audit.read', 'Read audit logs', 'Read audit history', '2026-08-26 19:36:24.648374+00'),
	('650ef5ce-fc46-4dc0-87e9-11a410324310', 'rules.read', 'Read financial rules', 'Read active business rules', '2026-08-26 19:36:24.648374+00'),
	('1bd2f3ae-4440-4536-bdc4-f43e84e7cccf', 'rules.change', 'Change financial rules', 'Approve/activate rule changes', '2026-08-26 19:36:24.648374+00'),
	('c07005d6-35c3-4dab-b188-1706b1644564', 'rbac.manage', 'Manage RBAC', 'Assign roles and permissions', '2026-08-26 19:36:24.648374+00'),
	('6adbc29b-482f-405b-9349-1497d36a2549', 'payment.view', 'View Payments', 'View administrative payment records', '2026-09-28 16:15:17.412474+00'),
	('69c61b47-e034-443a-8344-92abe780fc13', 'payment.reject', 'Reject Payment', 'Reject pending administrative payments', '2026-09-28 16:15:17.412474+00'),
	('6348c191-3271-491e-ad32-1882c8974083', 'expense.view', 'View Expenses', 'View expense records', '2026-09-28 16:15:17.412474+00'),
	('fa5aaad1-1c4e-4a65-92cd-f5292b132e3d', 'expense.pay', 'Pay Expense', 'Release approved expense funds', '2026-09-28 16:15:17.412474+00'),
	('7adea5b7-0f07-455b-b65f-dbffe587be53', 'expense.reverse', 'Reverse Expense', 'Reverse a posted expense transaction', '2026-09-28 16:15:17.412474+00');


--
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."roles" ("id", "code", "name", "description", "created_at") VALUES
	('b5ea1487-a958-4075-a707-ac1de6c50ff3', 'non_member', 'Non Member', 'Registered user who is not a member', '2026-08-26 19:36:24.648374+00'),
	('e690e417-ca16-4cfa-9ed2-e0af1cff2c9a', 'member', 'Member', 'Active Unity Finance member', '2026-08-26 19:36:24.648374+00'),
	('cb6135d8-8402-4bdc-86ff-41617a33f24b', 'admin', 'Admin', 'Administrative operator', '2026-08-26 19:36:24.648374+00'),
	('f113511f-23b1-4a4c-836b-627f68bce29f', 'super_admin', 'Super Admin', 'Full system administrator', '2026-08-26 19:36:24.648374+00');


--
-- Data for Name: role_permissions; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."role_permissions" ("role_id", "permission_id", "created_at") VALUES
	('cb6135d8-8402-4bdc-86ff-41617a33f24b', 'fd4e4597-651b-4a42-a3e7-f3cb878be8ad', '2026-08-26 19:36:24.648374+00'),
	('f113511f-23b1-4a4c-836b-627f68bce29f', 'fd4e4597-651b-4a42-a3e7-f3cb878be8ad', '2026-08-26 19:36:24.648374+00'),
	('cb6135d8-8402-4bdc-86ff-41617a33f24b', '10ad3ada-2692-402f-880c-08bad0887e46', '2026-08-26 19:36:24.648374+00'),
	('f113511f-23b1-4a4c-836b-627f68bce29f', '10ad3ada-2692-402f-880c-08bad0887e46', '2026-08-26 19:36:24.648374+00'),
	('cb6135d8-8402-4bdc-86ff-41617a33f24b', '65f5c1a7-0cc5-45ba-9c2f-131d23c5f3c7', '2026-08-26 19:36:24.648374+00'),
	('f113511f-23b1-4a4c-836b-627f68bce29f', '65f5c1a7-0cc5-45ba-9c2f-131d23c5f3c7', '2026-08-26 19:36:24.648374+00'),
	('cb6135d8-8402-4bdc-86ff-41617a33f24b', '53ad5026-0a17-44c8-9835-0dcf65ea88f6', '2026-08-26 19:36:24.648374+00'),
	('f113511f-23b1-4a4c-836b-627f68bce29f', '53ad5026-0a17-44c8-9835-0dcf65ea88f6', '2026-08-26 19:36:24.648374+00'),
	('cb6135d8-8402-4bdc-86ff-41617a33f24b', 'b1c0c994-b47f-4c78-aab7-64acea172d7c', '2026-08-26 19:36:24.648374+00'),
	('f113511f-23b1-4a4c-836b-627f68bce29f', 'b1c0c994-b47f-4c78-aab7-64acea172d7c', '2026-08-26 19:36:24.648374+00'),
	('cb6135d8-8402-4bdc-86ff-41617a33f24b', 'c99a6aa1-a4ee-454e-a225-0d4f57941932', '2026-08-26 19:36:24.648374+00'),
	('f113511f-23b1-4a4c-836b-627f68bce29f', 'c99a6aa1-a4ee-454e-a225-0d4f57941932', '2026-08-26 19:36:24.648374+00'),
	('cb6135d8-8402-4bdc-86ff-41617a33f24b', '21458a7e-d9cd-4998-91f0-5c5f8075de28', '2026-08-26 19:36:24.648374+00'),
	('f113511f-23b1-4a4c-836b-627f68bce29f', '21458a7e-d9cd-4998-91f0-5c5f8075de28', '2026-08-26 19:36:24.648374+00'),
	('cb6135d8-8402-4bdc-86ff-41617a33f24b', 'e7f0f766-a1a1-4ce7-80be-0f38ae2700de', '2026-08-26 19:36:24.648374+00'),
	('f113511f-23b1-4a4c-836b-627f68bce29f', 'e7f0f766-a1a1-4ce7-80be-0f38ae2700de', '2026-08-26 19:36:24.648374+00'),
	('cb6135d8-8402-4bdc-86ff-41617a33f24b', '0d1981b2-facf-49df-803e-14de6187dd96', '2026-08-26 19:36:24.648374+00'),
	('f113511f-23b1-4a4c-836b-627f68bce29f', '0d1981b2-facf-49df-803e-14de6187dd96', '2026-08-26 19:36:24.648374+00'),
	('cb6135d8-8402-4bdc-86ff-41617a33f24b', 'bc61bc03-4da8-4b2d-b325-acdcd6542648', '2026-08-26 19:36:24.648374+00'),
	('f113511f-23b1-4a4c-836b-627f68bce29f', 'bc61bc03-4da8-4b2d-b325-acdcd6542648', '2026-08-26 19:36:24.648374+00'),
	('cb6135d8-8402-4bdc-86ff-41617a33f24b', '526ddb63-9448-41ef-820c-53efce8049da', '2026-08-26 19:36:24.648374+00'),
	('f113511f-23b1-4a4c-836b-627f68bce29f', '526ddb63-9448-41ef-820c-53efce8049da', '2026-08-26 19:36:24.648374+00'),
	('cb6135d8-8402-4bdc-86ff-41617a33f24b', 'c3949937-4900-4bc2-8942-98aaddba8eca', '2026-08-26 19:36:24.648374+00'),
	('f113511f-23b1-4a4c-836b-627f68bce29f', 'c3949937-4900-4bc2-8942-98aaddba8eca', '2026-08-26 19:36:24.648374+00'),
	('cb6135d8-8402-4bdc-86ff-41617a33f24b', 'e016bf2a-6d00-4419-9abc-428ca00d44a0', '2026-08-26 19:36:24.648374+00'),
	('f113511f-23b1-4a4c-836b-627f68bce29f', 'e016bf2a-6d00-4419-9abc-428ca00d44a0', '2026-08-26 19:36:24.648374+00'),
	('cb6135d8-8402-4bdc-86ff-41617a33f24b', '3f8cc74e-cb9b-4e6e-a0bb-7cf03742aad2', '2026-08-26 19:36:24.648374+00'),
	('f113511f-23b1-4a4c-836b-627f68bce29f', '3f8cc74e-cb9b-4e6e-a0bb-7cf03742aad2', '2026-08-26 19:36:24.648374+00'),
	('cb6135d8-8402-4bdc-86ff-41617a33f24b', '1f710976-54a1-4eec-b535-01a794ae504d', '2026-08-26 19:36:24.648374+00'),
	('f113511f-23b1-4a4c-836b-627f68bce29f', '1f710976-54a1-4eec-b535-01a794ae504d', '2026-08-26 19:36:24.648374+00'),
	('cb6135d8-8402-4bdc-86ff-41617a33f24b', 'dfa0d52f-1c6a-47c8-813b-f65c4c268025', '2026-08-26 19:36:24.648374+00'),
	('f113511f-23b1-4a4c-836b-627f68bce29f', 'dfa0d52f-1c6a-47c8-813b-f65c4c268025', '2026-08-26 19:36:24.648374+00'),
	('cb6135d8-8402-4bdc-86ff-41617a33f24b', '76cdc19e-b4ec-467e-af8c-0039611034a4', '2026-08-26 19:36:24.648374+00'),
	('f113511f-23b1-4a4c-836b-627f68bce29f', '76cdc19e-b4ec-467e-af8c-0039611034a4', '2026-08-26 19:36:24.648374+00'),
	('cb6135d8-8402-4bdc-86ff-41617a33f24b', 'a8ecbdd4-1f8a-4409-a770-f2ac0e11070d', '2026-08-26 19:36:24.648374+00'),
	('f113511f-23b1-4a4c-836b-627f68bce29f', 'a8ecbdd4-1f8a-4409-a770-f2ac0e11070d', '2026-08-26 19:36:24.648374+00'),
	('cb6135d8-8402-4bdc-86ff-41617a33f24b', 'ce0c29a5-0b6b-4adf-b5b4-e14a4c42f49c', '2026-08-26 19:36:24.648374+00'),
	('f113511f-23b1-4a4c-836b-627f68bce29f', 'ce0c29a5-0b6b-4adf-b5b4-e14a4c42f49c', '2026-08-26 19:36:24.648374+00'),
	('cb6135d8-8402-4bdc-86ff-41617a33f24b', 'beaf6982-1435-4bf6-9587-1c9bac2d6632', '2026-08-26 19:36:24.648374+00'),
	('f113511f-23b1-4a4c-836b-627f68bce29f', 'beaf6982-1435-4bf6-9587-1c9bac2d6632', '2026-08-26 19:36:24.648374+00'),
	('cb6135d8-8402-4bdc-86ff-41617a33f24b', '88587afe-9b24-412f-ba8b-faabb59b90c0', '2026-08-26 19:36:24.648374+00'),
	('f113511f-23b1-4a4c-836b-627f68bce29f', '88587afe-9b24-412f-ba8b-faabb59b90c0', '2026-08-26 19:36:24.648374+00'),
	('cb6135d8-8402-4bdc-86ff-41617a33f24b', '51d50b18-220b-4d67-ac65-d7365490bcdc', '2026-08-26 19:36:24.648374+00'),
	('f113511f-23b1-4a4c-836b-627f68bce29f', '51d50b18-220b-4d67-ac65-d7365490bcdc', '2026-08-26 19:36:24.648374+00'),
	('cb6135d8-8402-4bdc-86ff-41617a33f24b', 'e67bf5c5-7601-402b-a5b4-ccbe06588020', '2026-08-26 19:36:24.648374+00'),
	('f113511f-23b1-4a4c-836b-627f68bce29f', 'e67bf5c5-7601-402b-a5b4-ccbe06588020', '2026-08-26 19:36:24.648374+00'),
	('cb6135d8-8402-4bdc-86ff-41617a33f24b', '32c0a0f7-00e5-4f17-9458-6f558960dfcf', '2026-08-26 19:36:24.648374+00'),
	('f113511f-23b1-4a4c-836b-627f68bce29f', '32c0a0f7-00e5-4f17-9458-6f558960dfcf', '2026-08-26 19:36:24.648374+00'),
	('cb6135d8-8402-4bdc-86ff-41617a33f24b', '650ef5ce-fc46-4dc0-87e9-11a410324310', '2026-08-26 19:36:24.648374+00'),
	('f113511f-23b1-4a4c-836b-627f68bce29f', '650ef5ce-fc46-4dc0-87e9-11a410324310', '2026-08-26 19:36:24.648374+00'),
	('cb6135d8-8402-4bdc-86ff-41617a33f24b', '1bd2f3ae-4440-4536-bdc4-f43e84e7cccf', '2026-08-26 19:36:24.648374+00'),
	('f113511f-23b1-4a4c-836b-627f68bce29f', '1bd2f3ae-4440-4536-bdc4-f43e84e7cccf', '2026-08-26 19:36:24.648374+00'),
	('cb6135d8-8402-4bdc-86ff-41617a33f24b', 'c07005d6-35c3-4dab-b188-1706b1644564', '2026-08-26 19:36:24.648374+00'),
	('f113511f-23b1-4a4c-836b-627f68bce29f', 'c07005d6-35c3-4dab-b188-1706b1644564', '2026-08-26 19:36:24.648374+00'),
	('b5ea1487-a958-4075-a707-ac1de6c50ff3', 'fd4e4597-651b-4a42-a3e7-f3cb878be8ad', '2026-08-26 19:36:24.648374+00'),
	('e690e417-ca16-4cfa-9ed2-e0af1cff2c9a', 'fd4e4597-651b-4a42-a3e7-f3cb878be8ad', '2026-08-26 19:36:24.648374+00'),
	('b5ea1487-a958-4075-a707-ac1de6c50ff3', '10ad3ada-2692-402f-880c-08bad0887e46', '2026-08-26 19:36:24.648374+00'),
	('e690e417-ca16-4cfa-9ed2-e0af1cff2c9a', '10ad3ada-2692-402f-880c-08bad0887e46', '2026-08-26 19:36:24.648374+00'),
	('b5ea1487-a958-4075-a707-ac1de6c50ff3', '65f5c1a7-0cc5-45ba-9c2f-131d23c5f3c7', '2026-08-26 19:36:24.648374+00'),
	('e690e417-ca16-4cfa-9ed2-e0af1cff2c9a', '65f5c1a7-0cc5-45ba-9c2f-131d23c5f3c7', '2026-08-26 19:36:24.648374+00'),
	('b5ea1487-a958-4075-a707-ac1de6c50ff3', 'c99a6aa1-a4ee-454e-a225-0d4f57941932', '2026-08-26 19:36:24.648374+00'),
	('e690e417-ca16-4cfa-9ed2-e0af1cff2c9a', 'c99a6aa1-a4ee-454e-a225-0d4f57941932', '2026-08-26 19:36:24.648374+00'),
	('b5ea1487-a958-4075-a707-ac1de6c50ff3', '21458a7e-d9cd-4998-91f0-5c5f8075de28', '2026-08-26 19:36:24.648374+00'),
	('e690e417-ca16-4cfa-9ed2-e0af1cff2c9a', '21458a7e-d9cd-4998-91f0-5c5f8075de28', '2026-08-26 19:36:24.648374+00'),
	('b5ea1487-a958-4075-a707-ac1de6c50ff3', 'e7f0f766-a1a1-4ce7-80be-0f38ae2700de', '2026-08-26 19:36:24.648374+00'),
	('e690e417-ca16-4cfa-9ed2-e0af1cff2c9a', 'e7f0f766-a1a1-4ce7-80be-0f38ae2700de', '2026-08-26 19:36:24.648374+00'),
	('b5ea1487-a958-4075-a707-ac1de6c50ff3', 'bc61bc03-4da8-4b2d-b325-acdcd6542648', '2026-08-26 19:36:24.648374+00'),
	('e690e417-ca16-4cfa-9ed2-e0af1cff2c9a', 'bc61bc03-4da8-4b2d-b325-acdcd6542648', '2026-08-26 19:36:24.648374+00'),
	('b5ea1487-a958-4075-a707-ac1de6c50ff3', 'c3949937-4900-4bc2-8942-98aaddba8eca', '2026-08-26 19:36:24.648374+00'),
	('e690e417-ca16-4cfa-9ed2-e0af1cff2c9a', 'c3949937-4900-4bc2-8942-98aaddba8eca', '2026-08-26 19:36:24.648374+00'),
	('b5ea1487-a958-4075-a707-ac1de6c50ff3', 'e016bf2a-6d00-4419-9abc-428ca00d44a0', '2026-08-26 19:36:24.648374+00'),
	('e690e417-ca16-4cfa-9ed2-e0af1cff2c9a', 'e016bf2a-6d00-4419-9abc-428ca00d44a0', '2026-08-26 19:36:24.648374+00'),
	('b5ea1487-a958-4075-a707-ac1de6c50ff3', '76cdc19e-b4ec-467e-af8c-0039611034a4', '2026-08-26 19:36:24.648374+00'),
	('e690e417-ca16-4cfa-9ed2-e0af1cff2c9a', '76cdc19e-b4ec-467e-af8c-0039611034a4', '2026-08-26 19:36:24.648374+00'),
	('b5ea1487-a958-4075-a707-ac1de6c50ff3', 'a8ecbdd4-1f8a-4409-a770-f2ac0e11070d', '2026-08-26 19:36:24.648374+00'),
	('e690e417-ca16-4cfa-9ed2-e0af1cff2c9a', 'a8ecbdd4-1f8a-4409-a770-f2ac0e11070d', '2026-08-26 19:36:24.648374+00'),
	('b5ea1487-a958-4075-a707-ac1de6c50ff3', '650ef5ce-fc46-4dc0-87e9-11a410324310', '2026-08-26 19:36:24.648374+00'),
	('e690e417-ca16-4cfa-9ed2-e0af1cff2c9a', '650ef5ce-fc46-4dc0-87e9-11a410324310', '2026-08-26 19:36:24.648374+00'),
	('cb6135d8-8402-4bdc-86ff-41617a33f24b', '6adbc29b-482f-405b-9349-1497d36a2549', '2026-09-28 16:15:17.412474+00'),
	('f113511f-23b1-4a4c-836b-627f68bce29f', '6adbc29b-482f-405b-9349-1497d36a2549', '2026-09-28 16:15:17.412474+00'),
	('cb6135d8-8402-4bdc-86ff-41617a33f24b', '69c61b47-e034-443a-8344-92abe780fc13', '2026-09-28 16:15:17.412474+00'),
	('f113511f-23b1-4a4c-836b-627f68bce29f', '69c61b47-e034-443a-8344-92abe780fc13', '2026-09-28 16:15:17.412474+00'),
	('cb6135d8-8402-4bdc-86ff-41617a33f24b', '6348c191-3271-491e-ad32-1882c8974083', '2026-09-28 16:15:17.412474+00'),
	('f113511f-23b1-4a4c-836b-627f68bce29f', '6348c191-3271-491e-ad32-1882c8974083', '2026-09-28 16:15:17.412474+00'),
	('cb6135d8-8402-4bdc-86ff-41617a33f24b', 'fa5aaad1-1c4e-4a65-92cd-f5292b132e3d', '2026-09-28 16:15:17.412474+00'),
	('f113511f-23b1-4a4c-836b-627f68bce29f', 'fa5aaad1-1c4e-4a65-92cd-f5292b132e3d', '2026-09-28 16:15:17.412474+00'),
	('cb6135d8-8402-4bdc-86ff-41617a33f24b', '7adea5b7-0f07-455b-b65f-dbffe587be53', '2026-09-28 16:15:17.412474+00'),
	('f113511f-23b1-4a4c-836b-627f68bce29f', '7adea5b7-0f07-455b-b65f-dbffe587be53', '2026-09-28 16:15:17.412474+00');


--
-- Data for Name: savings_accounts; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."savings_accounts" ("id", "member_id", "account_id", "status", "created_at") VALUES
	('7b1a7e16-ccf6-4067-8050-b15c800b1965', '9b5bf983-6cba-40b9-890d-f1af17041ffa', 'c48e0136-daf0-4da1-a806-100e3011a783', 'active', '2026-09-06 09:53:38.161399+00'),
	('b4acf584-9a22-4dd7-9f07-aa04d1103106', 'a69eafab-eb8a-435c-8e0c-d3b22fa3b8f9', '1379e70b-a8c3-40ae-98c1-102c7bd42dbd', 'active', '2026-09-06 11:10:47.715018+00'),
	('f94de3a9-4f21-4da8-b21d-4f815a10391e', '87e01037-3229-4ca7-bc94-b5a109e312a5', '374679e3-6777-4242-beee-055c63520435', 'active', '2026-09-11 11:13:02.457996+00'),
	('5925dc3d-cd70-4bd7-8d86-81706b926c06', '92e3f6fb-0b10-4ea2-9212-c2b470c6221b', '9cf4e59d-c245-4c22-b440-689721fac524', 'active', '2026-09-25 17:27:16.225866+00'),
	('6e7f94e1-2a55-49b5-b6ee-f637b5500404', '80ea84c9-313d-4927-b066-4fcdd6116226', '0543be11-14ad-465c-ad9e-927a81187d82', 'active', '2026-10-11 13:46:24.918799+00');


--
-- Data for Name: savings_obligations; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."savings_obligations" ("id", "member_id", "period_year", "period_month", "required_amount", "due_date", "paid_amount", "late_penalty_amount", "status", "created_at", "updated_at") VALUES
	('3b374258-03ca-4a32-b831-2f0759898b8c', 'a69eafab-eb8a-435c-8e0c-d3b22fa3b8f9', 2026, 9, 2000.00, '2026-09-12', 2000.00, 0.00, 'paid', '2026-09-06 11:10:47.715018+00', '2026-09-06 11:16:04.442067+00'),
	('3605b521-948e-47f2-8e8f-5115cbd881af', '9b5bf983-6cba-40b9-890d-f1af17041ffa', 2026, 9, 2000.00, '2026-09-12', 2000.00, 0.00, 'paid', '2026-09-09 16:14:50.679803+00', '2026-09-11 10:55:52.018182+00'),
	('bd933bd5-4d08-4d1d-a036-9264fb2b7957', '87e01037-3229-4ca7-bc94-b5a109e312a5', 2026, 8, 2000.00, '2026-08-12', 0.00, 200.00, 'late', '2026-09-22 12:41:42.792258+00', '2026-09-22 13:08:22.10156+00'),
	('7f6a0d71-60c2-41a2-8297-ab0339814082', '87e01037-3229-4ca7-bc94-b5a109e312a5', 2026, 9, 2000.00, '2026-09-12', 2000.00, 0.00, 'paid', '2026-09-11 11:13:02.457996+00', '2026-09-22 13:47:11.081479+00'),
	('3ee6802f-d7a3-4184-97ef-90ae28f5f916', '9b5bf983-6cba-40b9-890d-f1af17041ffa', 2026, 8, 2000.00, '2026-08-12', 2000.00, 0.00, 'paid', '2026-09-22 12:41:42.792258+00', '2026-09-22 13:47:11.081479+00'),
	('6dcf8f9b-14fe-4840-a1dc-fbe3903735bb', 'a69eafab-eb8a-435c-8e0c-d3b22fa3b8f9', 2026, 8, 2000.00, '2026-08-12', 2000.00, 0.00, 'paid', '2026-09-22 12:41:42.792258+00', '2026-09-22 14:26:33.667288+00'),
	('202bf602-7ac9-44b4-81a4-e6be83be8102', '92e3f6fb-0b10-4ea2-9212-c2b470c6221b', 2026, 9, 2000.00, '2026-09-12', 0.00, 200.00, 'late', '2026-09-25 17:27:16.225866+00', '2026-09-25 17:27:23.440589+00'),
	('58b6cd59-a675-4cac-8205-c3d7c0eb9507', '9b5bf983-6cba-40b9-890d-f1af17041ffa', 2026, 10, 2000.00, '2026-10-12', 0.00, 0.00, 'pending', '2026-10-01 15:50:33.833355+00', '2026-10-01 15:50:33.833355+00'),
	('6aba4a21-7025-4048-832f-acc06b0e0291', '87e01037-3229-4ca7-bc94-b5a109e312a5', 2026, 10, 2000.00, '2026-10-12', 0.00, 0.00, 'pending', '2026-10-01 15:50:33.833355+00', '2026-10-01 15:50:33.833355+00'),
	('12bf80a3-3ec6-464c-a1a5-9bcfc2063adf', '92e3f6fb-0b10-4ea2-9212-c2b470c6221b', 2026, 10, 2000.00, '2026-10-12', 0.00, 0.00, 'pending', '2026-10-01 15:50:33.833355+00', '2026-10-01 15:50:33.833355+00'),
	('d9259fec-128c-4338-9809-45e98a2465ee', '80ea84c9-313d-4927-b066-4fcdd6116226', 2026, 10, 2000.00, '2026-10-12', 0.00, 0.00, 'pending', '2026-10-11 13:46:24.918799+00', '2026-10-11 13:46:24.918799+00'),
	('676f0ff9-04b1-4a4d-9cd3-c7a98b1d56f7', '87e01037-3229-4ca7-bc94-b5a109e312a5', 2026, 5, 2000.00, '2026-05-12', 0.00, 0.00, 'pending', '2026-10-11 13:56:39.042672+00', '2026-10-11 13:56:39.042672+00'),
	('031dfbf3-07d7-4920-be6a-2d09c5ca83c9', '92e3f6fb-0b10-4ea2-9212-c2b470c6221b', 2026, 5, 2000.00, '2026-05-12', 0.00, 0.00, 'pending', '2026-10-11 13:56:39.042672+00', '2026-10-11 13:56:39.042672+00'),
	('61ec8353-9223-473a-9d7a-ac0a2a3aead0', '80ea84c9-313d-4927-b066-4fcdd6116226', 2026, 5, 2000.00, '2026-05-12', 2000.00, 0.00, 'paid', '2026-10-11 13:56:39.042672+00', '2026-10-11 14:00:44.040855+00'),
	('0ddd218f-9b52-49fb-8787-42983eb5ee87', 'a69eafab-eb8a-435c-8e0c-d3b22fa3b8f9', 2026, 5, 2000.00, '2026-05-12', 0.00, 200.00, 'late', '2026-10-11 13:56:39.042672+00', '2026-10-12 12:02:00.082692+00'),
	('13255960-92ef-49b0-b74b-7fe7debb35f0', '9b5bf983-6cba-40b9-890d-f1af17041ffa', 2026, 5, 2000.00, '2026-05-12', 0.00, 200.00, 'late', '2026-10-11 13:56:39.042672+00', '2026-10-12 19:53:52.037205+00'),
	('df608f6a-0dc9-4f0b-a3ef-f9c0efd004d9', 'a69eafab-eb8a-435c-8e0c-d3b22fa3b8f9', 2026, 10, 2000.00, '2026-10-12', 0.00, 200.00, 'late', '2026-10-01 15:50:33.833355+00', '2026-10-13 05:53:03.385181+00');


--
-- Data for Name: savings_contributions; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."savings_contributions" ("id", "member_id", "savings_account_id", "obligation_id", "amount", "payment_id", "transaction_id", "contribution_type", "created_at") VALUES
	('bbbc1ecd-1bb0-41c6-8503-c6d43193225b', '9b5bf983-6cba-40b9-890d-f1af17041ffa', '7b1a7e16-ccf6-4067-8050-b15c800b1965', NULL, 2000.00, 'fbaccbd0-9228-420b-a5c1-be9fc1e361c0', 'dbab7db5-8470-417d-9c0e-2cd0d34c6bd7', 'voluntary', '2026-09-06 10:19:06.701024+00'),
	('44d79aa6-15ab-442e-88ce-cae08139d670', 'a69eafab-eb8a-435c-8e0c-d3b22fa3b8f9', 'b4acf584-9a22-4dd7-9f07-aa04d1103106', '3b374258-03ca-4a32-b831-2f0759898b8c', 2000.00, '59147fd5-2507-4596-81e7-a055354c8811', '910b7e88-ebc8-4567-b937-6fddf185ca96', 'mandatory', '2026-09-06 11:16:04.442067+00'),
	('d51f8b61-275f-4fda-9534-ea6a313f340c', '9b5bf983-6cba-40b9-890d-f1af17041ffa', '7b1a7e16-ccf6-4067-8050-b15c800b1965', NULL, 2345.00, '109328cc-ed3a-46c8-b087-41fb420d31ee', '4dc43676-1e54-4e8e-993c-13930d5e1e18', 'voluntary', '2026-09-09 14:21:37.970045+00'),
	('ca13080e-5e6b-446e-a7c1-0655aecf29cf', '9b5bf983-6cba-40b9-890d-f1af17041ffa', '7b1a7e16-ccf6-4067-8050-b15c800b1965', '3605b521-948e-47f2-8e8f-5115cbd881af', 2000.00, '54b6e21a-046f-4d16-90a5-51f552762ec9', '35c1df1c-f60f-4316-aec4-13b6d9aeb106', 'mandatory', '2026-09-11 10:55:52.018182+00'),
	('5f66e532-d631-4119-b8e1-bf88877a8a6c', 'a69eafab-eb8a-435c-8e0c-d3b22fa3b8f9', 'b4acf584-9a22-4dd7-9f07-aa04d1103106', NULL, 2000.00, 'd6370408-53b4-4721-a77a-9f7ca9752fb6', 'd812c137-313d-4f11-9e29-75d88e3ced85', 'voluntary', '2026-09-11 10:56:16.342875+00'),
	('3e6d5473-0de2-473b-889b-be2c0037c2a3', '9b5bf983-6cba-40b9-890d-f1af17041ffa', '7b1a7e16-ccf6-4067-8050-b15c800b1965', NULL, 2000.00, '4d9da62a-9eb8-43d9-bdb2-f1149488e965', '23eecd03-3c02-4654-a77d-f6603810e25d', 'voluntary', '2026-09-19 12:40:37.989294+00'),
	('7c7f8f97-066a-44da-8899-d86486ab54ca', '87e01037-3229-4ca7-bc94-b5a109e312a5', 'f94de3a9-4f21-4da8-b21d-4f815a10391e', '7f6a0d71-60c2-41a2-8297-ab0339814082', 2000.00, '5466e990-f3e9-47e3-9bf9-cef346bd10ec', 'ac7a7879-9c87-42c6-9f74-8643457075fc', 'mandatory', '2026-09-21 15:36:06.095985+00'),
	('4c5066aa-ad5b-4271-9eb2-157bd426ca7e', '87e01037-3229-4ca7-bc94-b5a109e312a5', 'f94de3a9-4f21-4da8-b21d-4f815a10391e', '7f6a0d71-60c2-41a2-8297-ab0339814082', 200.00, '5466e990-f3e9-47e3-9bf9-cef346bd10ec', 'ac7a7879-9c87-42c6-9f74-8643457075fc', 'late_payment', '2026-09-21 15:36:06.095985+00'),
	('fa3f1d83-34fb-4ea4-89b9-6c0fe69091eb', '9b5bf983-6cba-40b9-890d-f1af17041ffa', '7b1a7e16-ccf6-4067-8050-b15c800b1965', '3ee6802f-d7a3-4184-97ef-90ae28f5f916', 2000.00, '9875ebd6-1669-40a5-9e62-9bcfe2998350', 'f2eaeb97-6212-476e-be28-7ea992948639', 'mandatory', '2026-09-22 13:06:15.904186+00'),
	('c80ea07e-2ba3-464f-b57f-390bbbda9572', '9b5bf983-6cba-40b9-890d-f1af17041ffa', '7b1a7e16-ccf6-4067-8050-b15c800b1965', '3ee6802f-d7a3-4184-97ef-90ae28f5f916', 200.00, '9875ebd6-1669-40a5-9e62-9bcfe2998350', 'f2eaeb97-6212-476e-be28-7ea992948639', 'late_payment', '2026-09-22 13:06:15.904186+00'),
	('a5a990f5-5402-47ae-a7a9-f9f922febbc8', 'a69eafab-eb8a-435c-8e0c-d3b22fa3b8f9', 'b4acf584-9a22-4dd7-9f07-aa04d1103106', '6dcf8f9b-14fe-4840-a1dc-fbe3903735bb', 2000.00, '5fdc0d24-755f-45fb-889d-60ac33af196f', 'f33b3c82-b543-409b-b6ad-72ee75bfdac0', 'mandatory', '2026-09-22 14:26:33.667288+00'),
	('7901e5fe-b33c-42ee-938c-bcfc7dc9fd83', 'a69eafab-eb8a-435c-8e0c-d3b22fa3b8f9', 'b4acf584-9a22-4dd7-9f07-aa04d1103106', '6dcf8f9b-14fe-4840-a1dc-fbe3903735bb', 200.00, '5fdc0d24-755f-45fb-889d-60ac33af196f', 'f33b3c82-b543-409b-b6ad-72ee75bfdac0', 'late_payment', '2026-09-22 14:26:33.667288+00'),
	('f2ce9859-376d-4c06-a525-42a9de9d1018', 'a69eafab-eb8a-435c-8e0c-d3b22fa3b8f9', 'b4acf584-9a22-4dd7-9f07-aa04d1103106', NULL, 12400.00, '90128ce8-6cf9-4f12-95bb-e8726784195f', '196244e5-92dc-4450-aa1a-e33fff633d58', 'voluntary', '2026-09-30 08:18:46.015939+00'),
	('4f956249-631c-4fcb-b74b-6316c1639481', 'a69eafab-eb8a-435c-8e0c-d3b22fa3b8f9', 'b4acf584-9a22-4dd7-9f07-aa04d1103106', NULL, 100.00, 'fc3c775c-b1bd-4791-ae85-98bb2dea4246', 'a419bf0e-402d-4835-a411-0a634ac90fcf', 'voluntary', '2026-09-30 08:41:15.423581+00'),
	('1608de0e-fd8c-4e72-911d-ae6b5f4d6ee6', 'a69eafab-eb8a-435c-8e0c-d3b22fa3b8f9', 'b4acf584-9a22-4dd7-9f07-aa04d1103106', NULL, 200.00, 'c62d9849-de57-4887-9b0d-2c9f26dd8451', '2a382a5e-f668-4e12-bda5-6ef067f89763', 'voluntary', '2026-09-30 08:47:55.755996+00'),
	('6ecf55fd-c85d-4502-a6dd-c03bd0ed0fc3', 'a69eafab-eb8a-435c-8e0c-d3b22fa3b8f9', 'b4acf584-9a22-4dd7-9f07-aa04d1103106', NULL, 580.00, 'a0a448fd-f5b8-41f9-9068-1127464e5efe', '65dad621-b951-44e7-8549-3e0591b96cfb', 'voluntary', '2026-09-30 08:49:48.76956+00'),
	('62dc3970-07ea-468c-b20f-28dd2bce76ed', '80ea84c9-313d-4927-b066-4fcdd6116226', '6e7f94e1-2a55-49b5-b6ee-f637b5500404', '61ec8353-9223-473a-9d7a-ac0a2a3aead0', 2000.00, 'f9a97b0a-f9ae-44c5-b7e5-3765f58addc9', '0005f65d-4b7c-4307-846c-87f9946e452c', 'mandatory', '2026-10-11 14:00:44.040855+00'),
	('2d41f824-3ad4-454d-b2fe-96612670b563', '80ea84c9-313d-4927-b066-4fcdd6116226', '6e7f94e1-2a55-49b5-b6ee-f637b5500404', '61ec8353-9223-473a-9d7a-ac0a2a3aead0', 200.00, 'f9a97b0a-f9ae-44c5-b7e5-3765f58addc9', '0005f65d-4b7c-4307-846c-87f9946e452c', 'late_payment', '2026-10-11 14:00:44.040855+00');


--
-- Data for Name: savings_penalties; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."savings_penalties" ("id", "obligation_id", "rate", "amount", "transaction_id", "charged_at") VALUES
	('0130175f-6fff-410c-b9f4-a3655ebd15e5', '7f6a0d71-60c2-41a2-8297-ab0339814082', 0.1000, 200.00, '6b5dba76-2156-4db4-8399-488c3a82c505', '2026-09-19 18:57:59.328849+00'),
	('aee3ed1a-872e-4674-87cc-9c72271b29b4', '3ee6802f-d7a3-4184-97ef-90ae28f5f916', 0.1000, 200.00, '398ab316-648b-4b95-a030-94a772471f6b', '2026-09-22 12:42:11.127297+00'),
	('3474e99d-fa20-4665-87da-83ae9cc3760a', '6dcf8f9b-14fe-4840-a1dc-fbe3903735bb', 0.1000, 200.00, '65babf8b-1032-4cf7-8438-0b6df3b10cae', '2026-09-22 13:08:22.10156+00'),
	('5767b427-c552-4b2c-b410-0fcc3f96c6ba', 'bd933bd5-4d08-4d1d-a036-9264fb2b7957', 0.1000, 200.00, '2d7c8d68-e239-4282-9995-8240fb46e284', '2026-09-22 13:08:22.10156+00'),
	('a910a448-834b-4c48-b29f-8d6cd028dd5c', '202bf602-7ac9-44b4-81a4-e6be83be8102', 0.1000, 200.00, '20932336-8fc8-491d-baa1-7bac44b251c3', '2026-09-25 17:27:23.440589+00'),
	('5a9470f6-2fdb-4527-a311-4f76313d13ad', '61ec8353-9223-473a-9d7a-ac0a2a3aead0', 0.1000, 200.00, '9527b968-e562-47c0-a30a-61daefc9ed50', '2026-10-11 13:56:45.734596+00'),
	('526608b9-51dd-4d0e-8f61-b121c3e158ee', '0ddd218f-9b52-49fb-8787-42983eb5ee87', 0.1000, 200.00, '2071c21d-2864-469c-bd0f-04bf99ab8bd6', '2026-10-12 12:02:00.082692+00'),
	('4f9774a8-6e5e-4c0f-99d5-53e2e5c8225b', '13255960-92ef-49b0-b74b-7fe7debb35f0', 0.1000, 200.00, '7a42f117-ab6e-4cdf-91b7-0d561b49e982', '2026-10-12 19:53:52.037205+00'),
	('df92e520-536f-4f58-aadd-6a5316c0d0ab', 'df608f6a-0dc9-4f0b-a3ef-f9c0efd004d9', 0.1000, 200.00, 'c3e1e0de-cacc-435f-a1ce-9bedde365f8a', '2026-10-13 05:53:03.385181+00');


--
-- Data for Name: savings_security_locks; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: transaction_entries; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."transaction_entries" ("id", "transaction_id", "account_id", "entry_type", "amount", "created_at") VALUES
	('8976a154-4ce8-4b0a-8f02-2c5a89934123', 'dbab7db5-8470-417d-9c0e-2cd0d34c6bd7', 'fe1846e1-6150-4591-95c0-a9e10ef11993', 'debit', 2000.00, '2026-09-06 10:19:06.701024+00'),
	('ed8ff1a4-dcca-47bc-82cb-3bba4dbbd935', 'dbab7db5-8470-417d-9c0e-2cd0d34c6bd7', 'c48e0136-daf0-4da1-a806-100e3011a783', 'credit', 2000.00, '2026-09-06 10:19:06.701024+00'),
	('381cc2e1-9613-4d90-a036-9083cc0b4097', '910b7e88-ebc8-4567-b937-6fddf185ca96', '1fe1907a-a24d-48d7-b60e-5e69789c855f', 'debit', 2000.00, '2026-09-06 11:16:04.442067+00'),
	('fde2840e-b949-4c1c-b5f9-b9b954f5f78d', '910b7e88-ebc8-4567-b937-6fddf185ca96', '1379e70b-a8c3-40ae-98c1-102c7bd42dbd', 'credit', 2000.00, '2026-09-06 11:16:04.442067+00'),
	('c53e9469-b744-4b40-86df-969a272feef0', 'a0358e7e-1631-4ab3-906d-6c70aee63481', '1379e70b-a8c3-40ae-98c1-102c7bd42dbd', 'debit', 2000.00, '2026-09-06 11:18:11.868169+00'),
	('a39c5152-e7be-4a32-a9c1-64b4d699021f', 'a0358e7e-1631-4ab3-906d-6c70aee63481', '1fe1907a-a24d-48d7-b60e-5e69789c855f', 'credit', 2000.00, '2026-09-06 11:18:11.868169+00'),
	('58d9dd38-7360-4303-bbd0-ba532854c15e', '4dc43676-1e54-4e8e-993c-13930d5e1e18', 'fe1846e1-6150-4591-95c0-a9e10ef11993', 'debit', 2345.00, '2026-09-09 14:21:37.970045+00'),
	('7d82c507-57e9-4d74-b81e-b65cb075501d', '4dc43676-1e54-4e8e-993c-13930d5e1e18', 'c48e0136-daf0-4da1-a806-100e3011a783', 'credit', 2345.00, '2026-09-09 14:21:37.970045+00'),
	('dcc83a35-e0ae-4b4a-9730-26320a7df01f', '35c1df1c-f60f-4316-aec4-13b6d9aeb106', 'fe1846e1-6150-4591-95c0-a9e10ef11993', 'debit', 2000.00, '2026-09-11 10:55:52.018182+00'),
	('f1659e6a-4be5-4f08-9b35-aca2e03497e9', '35c1df1c-f60f-4316-aec4-13b6d9aeb106', 'c48e0136-daf0-4da1-a806-100e3011a783', 'credit', 2000.00, '2026-09-11 10:55:52.018182+00'),
	('b3b0ef37-0ae5-4bfc-9682-0c4e6b56d21f', 'd812c137-313d-4f11-9e29-75d88e3ced85', '1fe1907a-a24d-48d7-b60e-5e69789c855f', 'debit', 2000.00, '2026-09-11 10:56:16.342875+00'),
	('c5d02865-0277-4a08-9af0-a71190e90917', 'd812c137-313d-4f11-9e29-75d88e3ced85', '1379e70b-a8c3-40ae-98c1-102c7bd42dbd', 'credit', 2000.00, '2026-09-11 10:56:16.342875+00'),
	('844f5c92-51af-4ef6-9f89-11e6ab349349', '23eecd03-3c02-4654-a77d-f6603810e25d', 'fe1846e1-6150-4591-95c0-a9e10ef11993', 'debit', 2000.00, '2026-09-19 12:40:37.989294+00'),
	('98951971-0bef-4aa7-8135-7785f4386808', '23eecd03-3c02-4654-a77d-f6603810e25d', 'c48e0136-daf0-4da1-a806-100e3011a783', 'credit', 2000.00, '2026-09-19 12:40:37.989294+00'),
	('22d94a0f-9a69-4f50-94a2-43d695aebe18', '44fa0ffe-6485-4930-b3fa-5d6baeab606a', 'fe1846e1-6150-4591-95c0-a9e10ef11993', 'debit', 2000.00, '2026-09-19 13:15:05.346032+00'),
	('f5098418-5f06-4d34-8a05-a53314a08486', '44fa0ffe-6485-4930-b3fa-5d6baeab606a', '374679e3-6777-4242-beee-055c63520435', 'credit', 2000.00, '2026-09-19 13:15:05.346032+00'),
	('be248c84-465e-492a-b827-cbb244f60ba5', 'ac7a7879-9c87-42c6-9f74-8643457075fc', '1fe1907a-a24d-48d7-b60e-5e69789c855f', 'debit', 2200.00, '2026-09-21 15:36:06.095985+00'),
	('e6bae276-3571-40fc-b9da-13eb99570902', 'f2eaeb97-6212-476e-be28-7ea992948639', '1fe1907a-a24d-48d7-b60e-5e69789c855f', 'debit', 2200.00, '2026-09-22 13:06:15.904186+00'),
	('8c27a7e8-abf3-47e7-9394-7b2f9afa4f89', 'ac7a7879-9c87-42c6-9f74-8643457075fc', '374679e3-6777-4242-beee-055c63520435', 'credit', 2000.00, '2026-09-21 15:36:06.095985+00'),
	('75632609-51ec-4d5e-abbf-97e348049591', 'ac7a7879-9c87-42c6-9f74-8643457075fc', '5e7c51e7-01c5-41d8-972a-4480e1d7474c', 'credit', 200.00, '2026-09-22 13:47:11.081479+00'),
	('273fe1c7-1a77-4dc4-b8eb-ab094655b447', 'f2eaeb97-6212-476e-be28-7ea992948639', 'c48e0136-daf0-4da1-a806-100e3011a783', 'credit', 2000.00, '2026-09-22 13:06:15.904186+00'),
	('0020179e-f29a-443b-9ad6-e2e6eea9b7a6', 'f2eaeb97-6212-476e-be28-7ea992948639', '5e7c51e7-01c5-41d8-972a-4480e1d7474c', 'credit', 200.00, '2026-09-22 13:47:11.081479+00'),
	('880b9618-7236-4ac6-8700-7f122bf9b7e8', 'f33b3c82-b543-409b-b6ad-72ee75bfdac0', 'fe1846e1-6150-4591-95c0-a9e10ef11993', 'debit', 2200.00, '2026-09-22 14:26:33.667288+00'),
	('97fe6d33-0bf7-454c-8f47-df27e336b3b6', 'f33b3c82-b543-409b-b6ad-72ee75bfdac0', '1379e70b-a8c3-40ae-98c1-102c7bd42dbd', 'credit', 2000.00, '2026-09-22 14:26:33.667288+00'),
	('a1e25a7a-e52c-4fb6-ba19-e3cb57cf8b2a', 'f33b3c82-b543-409b-b6ad-72ee75bfdac0', '5e7c51e7-01c5-41d8-972a-4480e1d7474c', 'credit', 200.00, '2026-09-22 14:26:33.667288+00'),
	('152a2c68-71e2-449e-98f4-84e45e4b66bb', '700e7d94-d576-4742-bf75-b00a560031f1', '0c20575a-d65f-443b-9392-4f3c8238c60b', 'debit', 6600.00, '2026-09-22 16:18:39.308957+00'),
	('33e120cc-0665-4c51-831d-fbd7cbad81a3', '700e7d94-d576-4742-bf75-b00a560031f1', 'fe1846e1-6150-4591-95c0-a9e10ef11993', 'credit', 6000.00, '2026-09-22 16:18:39.308957+00'),
	('7960f909-8f9e-4859-9a28-e82b20062608', '700e7d94-d576-4742-bf75-b00a560031f1', '6a2c8c14-430b-4de1-bf34-062f4793e4a3', 'credit', 600.00, '2026-09-22 16:18:39.308957+00'),
	('ce7e922c-3ece-4333-b57d-60462e493d09', '8511fbdd-a716-4570-8b39-3d1ca411f376', 'fe1846e1-6150-4591-95c0-a9e10ef11993', 'debit', 2200.00, '2026-09-26 16:51:55.854226+00'),
	('42a1b19a-e06f-46f8-899d-a12690cbc23a', '8511fbdd-a716-4570-8b39-3d1ca411f376', '0c20575a-d65f-443b-9392-4f3c8238c60b', 'credit', 2200.00, '2026-09-26 16:51:55.854226+00'),
	('0de670a7-efd7-4e65-8fbb-1bd3fb4dc733', '81bed6cf-68fc-4f4c-8452-2bb90e86b135', '106ebef4-6340-4e5f-8147-b863567b5091', 'debit', 1600.00, '2026-09-28 16:44:21.403363+00'),
	('c216a7bd-c05b-4a35-9d82-c28b0e2bc61a', '81bed6cf-68fc-4f4c-8452-2bb90e86b135', 'fe1846e1-6150-4591-95c0-a9e10ef11993', 'credit', 1600.00, '2026-09-28 16:44:21.403363+00'),
	('92ea16d8-fd1e-40b7-be06-d50368816f1d', '196244e5-92dc-4450-aa1a-e33fff633d58', 'fe1846e1-6150-4591-95c0-a9e10ef11993', 'debit', 12400.00, '2026-09-30 08:18:46.015939+00'),
	('ed3bbaf9-c66d-48b6-acd7-26ab957f81ed', '196244e5-92dc-4450-aa1a-e33fff633d58', '1379e70b-a8c3-40ae-98c1-102c7bd42dbd', 'credit', 12400.00, '2026-09-30 08:18:46.015939+00'),
	('87cfe4d5-9314-474e-ba72-57d287eb67de', 'a419bf0e-402d-4835-a411-0a634ac90fcf', 'fe1846e1-6150-4591-95c0-a9e10ef11993', 'debit', 100.00, '2026-09-30 08:41:15.423581+00'),
	('238dc68e-b765-431c-8adf-9e98f4335370', 'a419bf0e-402d-4835-a411-0a634ac90fcf', '1379e70b-a8c3-40ae-98c1-102c7bd42dbd', 'credit', 100.00, '2026-09-30 08:41:15.423581+00'),
	('48b1b467-e8da-4c14-ac97-1c2a1465b1b6', '2a382a5e-f668-4e12-bda5-6ef067f89763', 'fe1846e1-6150-4591-95c0-a9e10ef11993', 'debit', 200.00, '2026-09-30 08:47:55.755996+00'),
	('eb536456-4fec-4a1d-bee6-b2ef9d279a23', '2a382a5e-f668-4e12-bda5-6ef067f89763', '1379e70b-a8c3-40ae-98c1-102c7bd42dbd', 'credit', 200.00, '2026-09-30 08:47:55.755996+00'),
	('0afb5125-7d35-4398-8bdc-6bcd43333e51', '65dad621-b951-44e7-8549-3e0591b96cfb', 'fe1846e1-6150-4591-95c0-a9e10ef11993', 'debit', 580.00, '2026-09-30 08:49:48.76956+00'),
	('fbd5613b-8405-4f0b-893c-e3555c53d0ef', '65dad621-b951-44e7-8549-3e0591b96cfb', '1379e70b-a8c3-40ae-98c1-102c7bd42dbd', 'credit', 580.00, '2026-09-30 08:49:48.76956+00'),
	('362533ae-1d6a-4ab0-b772-f507f04c324d', 'a4e82a41-a3a2-4bdb-82c5-ea870f9a2403', 'fe1846e1-6150-4591-95c0-a9e10ef11993', 'debit', 2200.00, '2026-10-11 13:11:43.266207+00'),
	('6a9e981d-a666-4b37-bd0a-42f6296fc1a9', 'a4e82a41-a3a2-4bdb-82c5-ea870f9a2403', '0c20575a-d65f-443b-9392-4f3c8238c60b', 'credit', 2200.00, '2026-10-11 13:11:43.266207+00'),
	('e470250d-e41e-4e34-bb3c-da10c1d95a63', '0005f65d-4b7c-4307-846c-87f9946e452c', 'fe1846e1-6150-4591-95c0-a9e10ef11993', 'debit', 2200.00, '2026-10-11 14:00:44.040855+00'),
	('6b1938d1-6316-41c4-8fb3-ecc08ed44b22', '0005f65d-4b7c-4307-846c-87f9946e452c', '0543be11-14ad-465c-ad9e-927a81187d82', 'credit', 2000.00, '2026-10-11 14:00:44.040855+00'),
	('4959e2bb-7e76-456c-be5f-da3f35a7bb48', '0005f65d-4b7c-4307-846c-87f9946e452c', '5e7c51e7-01c5-41d8-972a-4480e1d7474c', 'credit', 200.00, '2026-10-11 14:00:44.040855+00');


--
-- Data for Name: user_roles; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."user_roles" ("user_id", "role_id", "assigned_by", "created_at") VALUES
	('96f15dbd-e885-4f42-8f55-492bd72cd515', 'cb6135d8-8402-4bdc-86ff-41617a33f24b', '96f15dbd-e885-4f42-8f55-492bd72cd515', '2026-09-01 19:56:02.267675+00'),
	('64efef4f-1555-4322-80ad-f69e46887516', 'e690e417-ca16-4cfa-9ed2-e0af1cff2c9a', '96f15dbd-e885-4f42-8f55-492bd72cd515', '2026-09-06 09:46:46.985302+00'),
	('a5c1a9c8-6ccd-49c2-a069-2781c83be09d', 'e690e417-ca16-4cfa-9ed2-e0af1cff2c9a', '96f15dbd-e885-4f42-8f55-492bd72cd515', '2026-09-06 11:10:47.715018+00'),
	('5101cac2-a24e-4342-975a-74df63071328', 'e690e417-ca16-4cfa-9ed2-e0af1cff2c9a', '96f15dbd-e885-4f42-8f55-492bd72cd515', '2026-09-11 11:13:02.457996+00'),
	('3f3e0eb5-aeb1-4999-bd98-18543b01b613', 'cb6135d8-8402-4bdc-86ff-41617a33f24b', '3f3e0eb5-aeb1-4999-bd98-18543b01b613', '2026-09-22 15:20:09.895998+00'),
	('99c968a2-142f-4329-935d-ef240a5a40f5', 'e690e417-ca16-4cfa-9ed2-e0af1cff2c9a', '96f15dbd-e885-4f42-8f55-492bd72cd515', '2026-09-25 17:27:16.225866+00'),
	('8a4f38eb-af53-4d05-8ab1-0e332e022710', 'cb6135d8-8402-4bdc-86ff-41617a33f24b', '8a4f38eb-af53-4d05-8ab1-0e332e022710', '2026-09-26 13:27:42.77685+00'),
	('a9e748d4-dc2b-4d5b-9571-2e2f2bc78e0d', 'e690e417-ca16-4cfa-9ed2-e0af1cff2c9a', '3f3e0eb5-aeb1-4999-bd98-18543b01b613', '2026-10-11 13:46:24.918799+00');


--
-- Data for Name: withdrawal_requests; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."withdrawal_requests" ("id", "member_id", "amount", "status", "requested_at", "reviewed_by", "reviewed_at", "paid_at", "reason", "created_at", "updated_at") VALUES
	('5731ca9c-8c4f-40ce-a4ef-85dc1d450da3', 'a69eafab-eb8a-435c-8e0c-d3b22fa3b8f9', 2000.00, 'paid', '2026-09-06 11:16:27.419492+00', '96f15dbd-e885-4f42-8f55-492bd72cd515', '2026-09-06 11:18:11.868169+00', '2026-09-06 11:18:11.868169+00', NULL, '2026-09-06 11:16:27.419492+00', '2026-09-06 11:18:11.868169+00'),
	('f07eb52a-53b9-46f3-9d1a-6ace266d765e', '9b5bf983-6cba-40b9-890d-f1af17041ffa', 8345.00, 'cancelled', '2026-09-21 12:52:11.060758+00', NULL, NULL, NULL, NULL, '2026-09-21 12:52:11.060758+00', '2026-09-21 12:52:25.145815+00'),
	('4e719bc0-05fb-4a60-90e5-03c4177d39df', 'a69eafab-eb8a-435c-8e0c-d3b22fa3b8f9', 4000.00, 'delayed', '2026-09-22 15:00:44.345509+00', '96f15dbd-e885-4f42-8f55-492bd72cd515', '2026-09-22 15:02:37.846583+00', NULL, 'lets wait for some time. cause we are in short of cash', '2026-09-22 15:00:44.345509+00', '2026-09-22 15:02:37.846583+00');



--
-- Data for Name: audit_log_entries; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: custom_oauth_providers; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: flow_state; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

INSERT INTO "auth"."flow_state" ("id", "user_id", "auth_code", "code_challenge_method", "code_challenge", "provider_type", "provider_access_token", "provider_refresh_token", "created_at", "updated_at", "authentication_method", "auth_code_issued_at", "invite_token", "referrer", "oauth_client_state_id", "linking_target_id", "email_optional") VALUES
	('8b619e46-81ed-445e-b938-25df6a4b21cd', '378ef91b-4bc1-4dce-a3c8-fa2abfed13da', '70249ae4-b93a-4668-9a8b-0b61fea48b09', 's256', 'GOA_bT4ghxLFMAkVUNlrRvwfmMqDF0FJGieKO-k9AgI', 'email', '', '', '2026-08-31 17:40:30.459638+00', '2026-08-31 17:40:30.459638+00', 'email/signup', NULL, NULL, NULL, NULL, NULL, false),
	('1e1783e6-ed95-4e38-bffc-f9df16bdc19d', '378ef91b-4bc1-4dce-a3c8-fa2abfed13da', '015f7658-85cd-4d99-9805-43bbc96cfaaa', 's256', '9JhvGObzU-gnQa-X5tJmkml7iWobpOOihY8hwlBAQpY', 'email', '', '', '2026-09-01 07:54:34.167962+00', '2026-09-01 07:54:34.167962+00', 'email/signup', NULL, NULL, NULL, NULL, NULL, false),
	('6917be2f-a0dd-4959-ad83-d47d177eb054', '378ef91b-4bc1-4dce-a3c8-fa2abfed13da', '8b0a9fe8-cd62-4cbb-b800-94ce351cf4a4', 's256', 'k2uKpMQ_LjGnbO0WDwyJPIJ4h3_9Pb3QMJngQe4L06E', 'email', '', '', '2026-09-01 08:07:27.271948+00', '2026-09-01 08:07:27.271948+00', 'email/signup', NULL, NULL, NULL, NULL, NULL, false),
	('0e3be7e6-520c-4723-8508-cd2f2b0aa2ee', '378ef91b-4bc1-4dce-a3c8-fa2abfed13da', '14835363-9762-4971-a082-f9a56a122047', 's256', 'RlIUyBhnpwNHGcfrzUS2F3hOYbmxiA1LBHcm1pE1eVQ', 'email/signup', '', '', '2026-09-01 08:11:07.253426+00', '2026-09-01 08:11:07.253426+00', 'email/signup', NULL, NULL, NULL, NULL, NULL, false),
	('75562a22-cc54-42f8-9381-2e4a14cd6e64', '28f339a2-241d-4b5f-88cf-8df9c2f02d6f', '0caaf24c-d61e-47cc-8369-f494e6c66e58', 's256', 'AsNusYGYOCPH06U7haOgcYpJsWp1ybKLtfjD_Su5ZfI', 'email', '', '', '2026-09-01 08:24:21.431775+00', '2026-09-01 08:24:21.431775+00', 'email/signup', NULL, NULL, NULL, NULL, NULL, false),
	('61ade98e-e1d7-4dc8-9aa6-66c27e0443a9', '28f339a2-241d-4b5f-88cf-8df9c2f02d6f', '4ebee498-697b-4a60-864a-9052f7dc2e5d', 's256', 'TpH4drRZVETZbQaJyUyUW3XgRRDYSIgOxcRWhtZeHiI', 'magiclink', '', '', '2026-09-01 10:18:57.848324+00', '2026-09-01 10:18:57.848324+00', 'magiclink', NULL, NULL, NULL, NULL, NULL, false),
	('ada35772-bd7f-4328-9b57-a9d13ad3f45d', 'efc20a59-8f7b-46c8-8579-ed81eedcc80f', '8dde64d4-2fa5-4192-8c83-9e1aea71b1a3', 's256', 'bQYFItvK-Q-aODhkfx4SE43YrS18sPgn33fM5Tkd7tA', 'email', '', '', '2026-09-01 11:12:19.415953+00', '2026-09-01 11:12:19.415953+00', 'email/signup', NULL, NULL, NULL, NULL, NULL, false),
	('cda81d8e-58fb-414f-a7eb-8dee0ba7b6a0', 'c829df17-cd01-4de7-8601-7d7f8254c0cb', '5e0a78ce-1669-4d06-b0f5-2b8c13a14fae', 's256', 'JFBFHhkDeNS_fpqRG5LeC_EloE8-f5yOUgS5m-u02j4', 'email', '', '', '2026-09-01 20:46:45.469371+00', '2026-09-01 20:46:45.469371+00', 'email/signup', NULL, NULL, NULL, NULL, NULL, false),
	('3a8c8b31-e6fe-4a69-b469-6c7e4fc95b2d', 'c829df17-cd01-4de7-8601-7d7f8254c0cb', '0162823e-e0ce-4af7-9cda-b2e018d965c6', 's256', 'c_QCKYnFWWqL5tCxh4aENt_WuK-sFyyjN5pfpDdtD1Q', 'magiclink', '', '', '2026-09-06 07:09:20.104616+00', '2026-09-06 07:09:20.104616+00', 'magiclink', NULL, NULL, NULL, NULL, NULL, false),
	('0d57d60c-9c34-4f00-bc70-804b3e4b50fa', '64efef4f-1555-4322-80ad-f69e46887516', 'f243ae85-8090-4dab-81fe-3cf3d76f1f71', 's256', 'GGjJI3u1VVo9nR3ABkkDxpQi1MWqIAzpteSQ-LvaWMg', 'email', '', '', '2026-09-06 09:40:24.968879+00', '2026-09-06 09:40:24.968879+00', 'email/signup', NULL, NULL, NULL, NULL, NULL, false),
	('5fd7a7a2-bb4a-4391-a41f-c767b6f1375d', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', '2f084745-1653-4cb4-828b-17d467e06277', 's256', 'AnEIPtTHku_IQsGf8wlu_L65seDPZaDX85t-YvJFBsU', 'email', '', '', '2026-09-06 11:06:34.525742+00', '2026-09-06 11:06:34.525742+00', 'email/signup', NULL, NULL, NULL, NULL, NULL, false),
	('68e2ba05-6fd9-4202-8a61-b5e9247d1b0c', '5101cac2-a24e-4342-975a-74df63071328', '13c08138-bdb9-4259-91c0-169d77440a5e', 's256', 'p_klAiph5hsadchl6fgGQOLVhUEKNgKISz1GDpY8Qao', 'email', '', '', '2026-09-11 11:10:23.263853+00', '2026-09-11 11:10:23.263853+00', 'email/signup', NULL, NULL, NULL, NULL, NULL, false);


--
-- Data for Name: users; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

INSERT INTO "auth"."users" ("instance_id", "id", "aud", "role", "email", "encrypted_password", "email_confirmed_at", "invited_at", "confirmation_token", "confirmation_sent_at", "recovery_token", "recovery_sent_at", "email_change_token_new", "email_change", "email_change_sent_at", "last_sign_in_at", "raw_app_meta_data", "raw_user_meta_data", "is_super_admin", "created_at", "updated_at", "phone", "phone_confirmed_at", "phone_change", "phone_change_token", "phone_change_sent_at", "email_change_token_current", "email_change_confirm_status", "banned_until", "reauthentication_token", "reauthentication_sent_at", "is_sso_user", "deleted_at", "is_anonymous") VALUES
	('00000000-0000-0000-0000-000000000000', '96f15dbd-e885-4f42-8f55-492bd72cd515', 'authenticated', 'authenticated', 'mcnan6@gmail.com', '$2a$06$EzqlFcjz34C2.RG0vFZsr.C3AgucRWKLOGZsGW.aiLgZNT.7cnKce', '2026-09-01 19:40:06.101793+00', NULL, '', NULL, '', NULL, '', '', NULL, '2026-09-30 07:41:09.084327+00', '{"provider": "email", "providers": ["email"]}', '{"email_verified": true}', NULL, '2026-09-01 19:40:06.090804+00', '2026-09-30 19:35:42.410981+00', '251922222222', '2026-09-26 12:40:14.495043+00', '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false),
	('00000000-0000-0000-0000-000000000000', '99c968a2-142f-4329-935d-ef240a5a40f5', 'authenticated', 'authenticated', NULL, '$2a$10$fdBnGBfU9esXmCiQh5hiCew9bBGsRkAnehmKwiQjG2Cq1FwGZM0xi', NULL, NULL, '', NULL, '', NULL, '', '', NULL, '2026-09-25 19:38:03.124668+00', '{"provider": "phone", "providers": ["phone"]}', '{"sub": "99c968a2-142f-4329-935d-ef240a5a40f5", "phone": "+251912345678", "full_name": "test1", "email_verified": false, "phone_verified": false}', NULL, '2026-09-25 17:25:35.910493+00', '2026-09-25 19:38:03.166814+00', '251912345678', '2026-09-25 17:25:36.018749+00', '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false),
	('00000000-0000-0000-0000-000000000000', '3f3e0eb5-aeb1-4999-bd98-18543b01b613', 'authenticated', 'authenticated', 'dir@gmail.com', '$2a$06$7gIcRvo6PALJ5u1K/Uffo.83kYw65QBxJ0W6RdSaxVJWAgmh2QHAe', '2026-09-22 15:18:53.289227+00', NULL, '', NULL, '', NULL, '', '', NULL, '2026-10-11 13:54:21.731553+00', '{"provider": "email", "providers": ["email"]}', '{"email_verified": true}', NULL, '2026-09-22 15:18:53.260018+00', '2026-10-12 07:56:25.310562+00', '251911111111', '2026-09-26 12:34:40.495236+00', '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false),
	('00000000-0000-0000-0000-000000000000', '9f67e506-cdfd-4890-b83c-da752caae614', 'authenticated', 'authenticated', NULL, '$2a$10$lHKjyWLiwk.uck7P0bbvG.qs2EuqJrbBbBw1fm02fNddUvT5BEVVu', NULL, NULL, '', NULL, '', NULL, '', '', NULL, '2026-10-08 04:44:32.292047+00', '{"provider": "phone", "providers": ["phone"]}', '{"sub": "9f67e506-cdfd-4890-b83c-da752caae614", "phone": "+251977764845", "full_name": "abdi", "email_verified": false, "phone_verified": false}', NULL, '2026-09-25 17:10:38.119258+00', '2026-10-08 04:44:32.308759+00', '251977764845', '2026-09-25 17:10:38.191793+00', '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false),
	('00000000-0000-0000-0000-000000000000', '64efef4f-1555-4322-80ad-f69e46887516', 'authenticated', 'authenticated', 'alaziizz67@gmail.com', '$2a$10$IPEKjhxEY0w8xM5xW8LlBOdqyIJizReZ7IUG09CIshAjQFbx3Bg86', '2026-09-06 09:40:57.415612+00', NULL, '', NULL, '', NULL, '', '', NULL, '2026-10-12 22:20:06.881114+00', '{"provider": "email", "providers": ["email"]}', '{"sub": "64efef4f-1555-4322-80ad-f69e46887516", "email": "alaziizz67@gmail.com", "phone": "098686868", "full_name": "Abdulaz", "email_verified": true, "phone_verified": false}', NULL, '2026-09-06 09:40:24.897575+00', '2026-10-12 22:20:06.939825+00', '251721777648', '2026-09-26 15:00:18.723722+00', '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false),
	('00000000-0000-0000-0000-000000000000', 'a9e748d4-dc2b-4d5b-9571-2e2f2bc78e0d', 'authenticated', 'authenticated', NULL, '$2a$10$1rwhlA5U9WpTt7Wxx8z1T.kxIcgF13Z3CIk6wvFfb/z8TdqHtRtTu', NULL, NULL, '', NULL, '', NULL, '', '', NULL, '2026-10-11 13:42:26.857455+00', '{"provider": "phone", "providers": ["phone"]}', '{"sub": "a9e748d4-dc2b-4d5b-9571-2e2f2bc78e0d", "phone": "+251954201924", "full_name": "Tariku Admasu", "email_verified": false, "phone_verified": false}', NULL, '2026-10-11 13:42:26.765978+00', '2026-10-12 09:53:17.068605+00', '251954201924', '2026-10-11 13:42:26.847781+00', '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false),
	('00000000-0000-0000-0000-000000000000', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', 'authenticated', 'authenticated', 'amanuelmesay806@gmail.com', '$2a$06$qD7HuzGwt3do6z0aIDVOaufSgOwcQRlIeGTIFMSHspf//F9pcRE0u', '2026-09-06 11:07:06.35793+00', NULL, '', NULL, '', NULL, '', '', NULL, '2026-10-13 05:53:00.33292+00', '{"provider": "email", "providers": ["email"]}', '{"sub": "a5c1a9c8-6ccd-49c2-a069-2781c83be09d", "email": "amanuelmesay806@gmail.com", "phone": "0935356268", "full_name": "Amanuel Mesay", "email_verified": true, "phone_verified": false}', NULL, '2026-09-06 11:06:34.388191+00', '2026-10-13 05:53:00.366803+00', '251935356268', '2026-09-25 20:33:33.96184+00', '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false),
	('00000000-0000-0000-0000-000000000000', '8a4f38eb-af53-4d05-8ab1-0e332e022710', 'authenticated', 'authenticated', 'admin3@gmail.com', '$2a$10$iQxdQvhSOa5FdfnDJFTGdua0emVpIIPEeJrLYrmDat/NYmIG0S7eO', '2026-09-26 12:42:20.22719+00', NULL, '', NULL, '', NULL, '', '', NULL, '2026-09-26 13:28:02.181446+00', '{"provider": "email", "providers": ["email"]}', '{"email_verified": true}', NULL, '2026-09-26 12:42:20.195584+00', '2026-09-28 16:11:59.542953+00', '251933333333', '2026-09-26 12:44:03.555533+00', '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false),
	('00000000-0000-0000-0000-000000000000', '5101cac2-a24e-4342-975a-74df63071328', 'authenticated', 'authenticated', 'amanuelmesay7@gmail.com', '$2a$10$UCxEsWFgvqyuGHYg2fH42eoUgkIh7M1uupPRNF3Q8pcBH.Fo2YB66', '2026-09-11 11:11:01.547095+00', NULL, '', NULL, '', NULL, '', '', NULL, '2026-09-30 08:00:58.83125+00', '{"provider": "email", "providers": ["email"]}', '{"sub": "5101cac2-a24e-4342-975a-74df63071328", "email": "amanuelmesay7@gmail.com", "phone": "098989899", "full_name": "hang", "email_verified": true, "phone_verified": false}', NULL, '2026-09-11 11:10:23.23739+00', '2026-09-30 08:00:58.854207+00', '251912345677', '2026-09-25 20:36:40.134289+00', '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false);


--
-- Data for Name: identities; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

INSERT INTO "auth"."identities" ("provider_id", "user_id", "identity_data", "provider", "last_sign_in_at", "created_at", "updated_at", "id") VALUES
	('5101cac2-a24e-4342-975a-74df63071328', '5101cac2-a24e-4342-975a-74df63071328', '{"sub": "5101cac2-a24e-4342-975a-74df63071328", "phone": "251912345677", "email_verified": false, "phone_verified": true}', 'phone', '2026-09-25 20:36:40.150427+00', '2026-09-25 20:36:40.15052+00', '2026-09-25 20:36:40.15052+00', 'b1153a92-dbd0-4290-ba36-1892c1cb397b'),
	('96f15dbd-e885-4f42-8f55-492bd72cd515', '96f15dbd-e885-4f42-8f55-492bd72cd515', '{"sub": "96f15dbd-e885-4f42-8f55-492bd72cd515", "email": "mcnan6@gmail.com", "email_verified": false, "phone_verified": false}', 'email', '2026-09-01 19:40:06.099492+00', '2026-09-01 19:40:06.099551+00', '2026-09-01 19:40:06.099551+00', '44408f6b-3099-4ad2-b0bf-0570d830001b'),
	('64efef4f-1555-4322-80ad-f69e46887516', '64efef4f-1555-4322-80ad-f69e46887516', '{"sub": "64efef4f-1555-4322-80ad-f69e46887516", "email": "alaziizz67@gmail.com", "phone": "098686868", "full_name": "Abdulaz", "email_verified": true, "phone_verified": false}', 'email', '2026-09-06 09:40:24.960341+00', '2026-09-06 09:40:24.960399+00', '2026-09-06 09:40:24.960399+00', '40198371-596b-4ad2-b426-a9dd101d3d17'),
	('a5c1a9c8-6ccd-49c2-a069-2781c83be09d', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', '{"sub": "a5c1a9c8-6ccd-49c2-a069-2781c83be09d", "email": "amanuelmesay806@gmail.com", "phone": "0935356268", "full_name": "Amanuel Mesay", "email_verified": true, "phone_verified": false}', 'email', '2026-09-06 11:06:34.511918+00', '2026-09-06 11:06:34.511974+00', '2026-09-06 11:06:34.511974+00', 'd7568092-1d68-40c9-b39f-269cff86b3a9'),
	('5101cac2-a24e-4342-975a-74df63071328', '5101cac2-a24e-4342-975a-74df63071328', '{"sub": "5101cac2-a24e-4342-975a-74df63071328", "email": "amanuelmesay7@gmail.com", "phone": "098989899", "full_name": "hang", "email_verified": true, "phone_verified": false}', 'email', '2026-09-11 11:10:23.258983+00', '2026-09-11 11:10:23.259041+00', '2026-09-11 11:10:23.259041+00', 'aebbfa74-23bd-4533-97c3-932971253983'),
	('3f3e0eb5-aeb1-4999-bd98-18543b01b613', '3f3e0eb5-aeb1-4999-bd98-18543b01b613', '{"sub": "3f3e0eb5-aeb1-4999-bd98-18543b01b613", "email": "dir@gmail.com", "email_verified": false, "phone_verified": false}', 'email', '2026-09-22 15:18:53.281614+00', '2026-09-22 15:18:53.281683+00', '2026-09-22 15:18:53.281683+00', '59474e10-42bf-4354-bb9f-0833df0fbf50'),
	('9f67e506-cdfd-4890-b83c-da752caae614', '9f67e506-cdfd-4890-b83c-da752caae614', '{"sub": "9f67e506-cdfd-4890-b83c-da752caae614", "phone": "+251977764845", "full_name": "abdi", "email_verified": false, "phone_verified": false}', 'phone', '2026-09-25 17:10:38.182657+00', '2026-09-25 17:10:38.182734+00', '2026-09-25 17:10:38.182734+00', 'd4133563-4282-453b-9119-cde50fa86766'),
	('99c968a2-142f-4329-935d-ef240a5a40f5', '99c968a2-142f-4329-935d-ef240a5a40f5', '{"sub": "99c968a2-142f-4329-935d-ef240a5a40f5", "phone": "+251912345678", "full_name": "test1", "email_verified": false, "phone_verified": false}', 'phone', '2026-09-25 17:25:36.005735+00', '2026-09-25 17:25:36.005799+00', '2026-09-25 17:25:36.005799+00', '7d776112-9df0-4031-bbff-e3fad415e3df'),
	('a5c1a9c8-6ccd-49c2-a069-2781c83be09d', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', '{"sub": "a5c1a9c8-6ccd-49c2-a069-2781c83be09d", "phone": "251935356268", "email_verified": false, "phone_verified": true}', 'phone', '2026-09-25 20:30:01.015658+00', '2026-09-25 20:30:01.015758+00', '2026-09-25 20:30:01.015758+00', '2b8ef175-e71f-464e-89e8-7aae39782d66'),
	('3f3e0eb5-aeb1-4999-bd98-18543b01b613', '3f3e0eb5-aeb1-4999-bd98-18543b01b613', '{"sub": "3f3e0eb5-aeb1-4999-bd98-18543b01b613", "phone": "251911111111", "email_verified": false, "phone_verified": true}', 'phone', '2026-09-26 12:34:40.507531+00', '2026-09-26 12:34:40.5076+00', '2026-09-26 12:34:40.5076+00', 'f4ed0d01-aca3-4439-872f-9b17a8335d92'),
	('96f15dbd-e885-4f42-8f55-492bd72cd515', '96f15dbd-e885-4f42-8f55-492bd72cd515', '{"sub": "96f15dbd-e885-4f42-8f55-492bd72cd515", "phone": "251922222222", "email_verified": false, "phone_verified": true}', 'phone', '2026-09-26 12:40:14.502817+00', '2026-09-26 12:40:14.502869+00', '2026-09-26 12:40:14.502869+00', 'cb24d205-87b9-4b3e-91c2-bd8d07279f19'),
	('8a4f38eb-af53-4d05-8ab1-0e332e022710', '8a4f38eb-af53-4d05-8ab1-0e332e022710', '{"sub": "8a4f38eb-af53-4d05-8ab1-0e332e022710", "email": "admin3@gmail.com", "email_verified": false, "phone_verified": false}', 'email', '2026-09-26 12:42:20.219082+00', '2026-09-26 12:42:20.219145+00', '2026-09-26 12:42:20.219145+00', '9de06aed-8d2f-4e31-b0ba-de1601b4633b'),
	('8a4f38eb-af53-4d05-8ab1-0e332e022710', '8a4f38eb-af53-4d05-8ab1-0e332e022710', '{"sub": "8a4f38eb-af53-4d05-8ab1-0e332e022710", "phone": "251933333333", "email_verified": false, "phone_verified": true}', 'phone', '2026-09-26 12:44:03.567388+00', '2026-09-26 12:44:03.56746+00', '2026-09-26 12:44:03.56746+00', '56b56111-f46c-4f47-8a77-c2887412bdfd'),
	('64efef4f-1555-4322-80ad-f69e46887516', '64efef4f-1555-4322-80ad-f69e46887516', '{"sub": "64efef4f-1555-4322-80ad-f69e46887516", "phone": "251721777648", "email_verified": false, "phone_verified": true}', 'phone', '2026-09-26 15:00:18.740132+00', '2026-09-26 15:00:18.740245+00', '2026-09-26 15:00:18.740245+00', '396d545a-137d-423a-87d0-bcc613b19a70'),
	('a9e748d4-dc2b-4d5b-9571-2e2f2bc78e0d', 'a9e748d4-dc2b-4d5b-9571-2e2f2bc78e0d', '{"sub": "a9e748d4-dc2b-4d5b-9571-2e2f2bc78e0d", "phone": "+251954201924", "full_name": "Tariku Admasu", "email_verified": false, "phone_verified": false}', 'phone', '2026-10-11 13:42:26.83341+00', '2026-10-11 13:42:26.83347+00', '2026-10-11 13:42:26.83347+00', 'eca4d31c-9db7-4f7a-afaa-d0ecd97edcb5');


--
-- Data for Name: instances; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: oauth_clients; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: sessions; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

INSERT INTO "auth"."sessions" ("id", "user_id", "created_at", "updated_at", "factor_id", "aal", "not_after", "refreshed_at", "user_agent", "ip", "tag", "oauth_client_id", "refresh_token_hmac_key", "refresh_token_counter", "scopes") VALUES
	('a82c26b5-c0c7-4ca3-8aff-698191d4ed56', '5101cac2-a24e-4342-975a-74df63071328', '2026-09-25 20:44:35.15811+00', '2026-09-26 12:00:26.805726+00', NULL, 'aal1', NULL, '2026-09-26 12:00:26.804896', 'Dart/3.13 (dart:io)', '102.218.51.163', NULL, NULL, NULL, NULL, NULL),
	('5a1e4472-2b00-4fcd-9d93-b88ed5577061', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', '2026-10-02 15:29:08.510488+00', '2026-10-03 10:35:32.755762+00', NULL, 'aal1', NULL, '2026-10-03 10:35:32.755611', 'Dart/3.13 (dart:io)', '102.213.69.9', NULL, NULL, NULL, NULL, NULL),
	('bd852838-2e58-4cc9-9826-a7b8a76bf6f0', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', '2026-10-03 10:37:46.886442+00', '2026-10-03 10:37:46.886442+00', NULL, 'aal1', NULL, NULL, 'Dart/3.13 (dart:io)', '102.213.69.9', NULL, NULL, NULL, NULL, NULL),
	('2764a656-1ace-4d21-807d-78373463ec58', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', '2026-09-30 07:22:44.121272+00', '2026-10-03 14:03:28.781748+00', NULL, 'aal1', NULL, '2026-10-03 14:03:28.781611', 'Dart/3.13 (dart:io)', '196.190.62.6', NULL, NULL, NULL, NULL, NULL),
	('dc0a330c-2505-4ed8-83b0-43c8c50fc10e', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', '2026-09-28 13:17:13.570601+00', '2026-09-29 08:20:32.959143+00', NULL, 'aal1', NULL, '2026-09-29 08:20:32.959029', 'Dart/3.13 (dart:io)', '196.188.181.148', NULL, NULL, NULL, NULL, NULL),
	('2786416a-3132-44ab-8632-b9d9f4bcc282', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', '2026-09-29 19:28:46.645541+00', '2026-09-29 19:28:46.645541+00', NULL, 'aal1', NULL, NULL, 'Dart/3.13 (dart:io)', '102.218.51.46', NULL, NULL, NULL, NULL, NULL),
	('bf300f6c-e893-4843-954b-c42f5bfccb9f', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', '2026-10-03 14:03:43.060821+00', '2026-10-04 09:45:34.674114+00', NULL, 'aal1', NULL, '2026-10-04 09:45:34.674004', 'Dart/3.13 (dart:io)', '102.208.97.59', NULL, NULL, NULL, NULL, NULL),
	('299c163a-099a-4a10-88a0-f10dad3de521', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', '2026-09-28 14:26:52.022114+00', '2026-09-30 07:22:30.871383+00', NULL, 'aal1', NULL, '2026-09-30 07:22:30.871258', 'Dart/3.13 (dart:io)', '196.188.112.63', NULL, NULL, NULL, NULL, NULL),
	('9cb0b80b-6308-4c25-a67b-adb2f970364e', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', '2026-09-30 08:16:03.172222+00', '2026-09-30 09:19:01.893186+00', NULL, 'aal1', NULL, '2026-09-30 09:19:01.887215', 'Dart/3.13 (dart:io)', '102.218.51.167', NULL, NULL, NULL, NULL, NULL),
	('076ae599-5f62-44b3-98bf-e0937bbc5b1d', '64efef4f-1555-4322-80ad-f69e46887516', '2026-10-03 13:20:48.176005+00', '2026-10-08 04:44:15.584832+00', NULL, 'aal1', NULL, '2026-10-08 04:44:15.584668', 'Dart/3.13 (dart:io)', '102.213.68.41', NULL, NULL, NULL, NULL, NULL),
	('61a64991-6765-4d07-ab30-3154fccf10a1', '9f67e506-cdfd-4890-b83c-da752caae614', '2026-10-08 04:44:32.292195+00', '2026-10-08 04:44:32.292195+00', NULL, 'aal1', NULL, NULL, 'Dart/3.13 (dart:io)', '102.213.68.41', NULL, NULL, NULL, NULL, NULL),
	('a1b45fd2-c63f-4bf5-817f-1a9e865b6988', '64efef4f-1555-4322-80ad-f69e46887516', '2026-10-08 04:45:07.022526+00', '2026-10-08 09:50:29.061638+00', NULL, 'aal1', NULL, '2026-10-08 09:50:29.061521', 'Dart/3.13 (dart:io)', '196.188.177.52', NULL, NULL, NULL, NULL, NULL),
	('211a2820-c0b7-415e-b896-71d0b32dc6b6', '96f15dbd-e885-4f42-8f55-492bd72cd515', '2026-09-30 07:41:09.087372+00', '2026-09-30 19:35:42.432145+00', NULL, 'aal1', NULL, '2026-09-30 19:35:42.432021', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36', '102.218.51.85', NULL, NULL, NULL, NULL, NULL),
	('251e972c-e50b-4aba-aeaa-027a781e0d70', '64efef4f-1555-4322-80ad-f69e46887516', '2026-09-26 15:03:22.984294+00', '2026-09-27 12:13:48.79775+00', NULL, 'aal1', NULL, '2026-09-27 12:13:48.797619', 'Dart/3.13 (dart:io)', '102.218.51.188', NULL, NULL, NULL, NULL, NULL),
	('969a86c0-5134-4d3d-a867-7908e2b1bbe8', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', '2026-10-04 09:45:47.44072+00', '2026-10-11 12:56:35.579937+00', NULL, 'aal1', NULL, '2026-10-11 12:56:35.579829', 'Dart/3.13 (dart:io)', '196.191.221.92', NULL, NULL, NULL, NULL, NULL),
	('c3fbc074-049a-4302-92f8-a78baec964d6', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', '2026-10-11 12:56:51.535121+00', '2026-10-11 12:56:51.535121+00', NULL, 'aal1', NULL, NULL, 'Dart/3.13 (dart:io)', '196.191.221.92', NULL, NULL, NULL, NULL, NULL),
	('6ee82a3a-cd4c-4520-a07f-ed842710e049', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', '2026-10-11 13:05:33.160143+00', '2026-10-11 13:05:33.160143+00', NULL, 'aal1', NULL, NULL, 'Dart/3.13 (dart:io)', '196.191.221.92', NULL, NULL, NULL, NULL, NULL),
	('0d38a2c8-70e3-4964-92d0-1f76850f707c', '3f3e0eb5-aeb1-4999-bd98-18543b01b613', '2026-10-01 15:49:48.205134+00', '2026-10-01 20:43:37.230677+00', NULL, 'aal1', NULL, '2026-10-01 20:43:37.230565', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36', '102.213.69.16', NULL, NULL, NULL, NULL, NULL),
	('9d73905e-5f3f-40df-92a3-44d978193076', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', '2026-10-01 15:30:06.62541+00', '2026-10-02 12:51:24.413514+00', NULL, 'aal1', NULL, '2026-10-02 12:51:24.413411', 'Dart/3.13 (dart:io)', '102.213.68.26', NULL, NULL, NULL, NULL, NULL),
	('532bad7f-0190-470e-9cf4-bb33cd456cd2', '9f67e506-cdfd-4890-b83c-da752caae614', '2026-09-25 17:10:38.203365+00', '2026-09-25 17:10:38.203365+00', NULL, 'aal1', NULL, NULL, 'Dart/3.13 (dart:io)', '102.208.96.97', NULL, NULL, NULL, NULL, NULL),
	('824f58d4-877d-4a8f-b578-b12431bed7b6', '64efef4f-1555-4322-80ad-f69e46887516', '2026-09-28 08:29:14.581188+00', '2026-09-28 13:00:50.859938+00', NULL, 'aal1', NULL, '2026-09-28 13:00:50.859829', 'Dart/3.13 (dart:io)', '102.218.51.137', NULL, NULL, NULL, NULL, NULL),
	('a1a63a9f-35f2-4ac1-a72c-8890b28bbf39', '3f3e0eb5-aeb1-4999-bd98-18543b01b613', '2026-10-11 13:10:59.830035+00', '2026-10-12 03:39:03.410316+00', NULL, 'aal1', NULL, '2026-10-12 03:39:03.410213', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Mobile Safari/537.36', '146.59.45.17', NULL, NULL, NULL, NULL, NULL),
	('e5f8caf7-856c-4b92-9cae-0d635c1ff43e', '3f3e0eb5-aeb1-4999-bd98-18543b01b613', '2026-10-11 13:54:21.732301+00', '2026-10-12 07:56:27.623981+00', NULL, 'aal1', NULL, '2026-10-12 07:56:27.623857', 'node', '18.171.217.204', NULL, NULL, NULL, NULL, NULL),
	('43b8f04c-69b7-4b0c-954a-ba1e1be11b7b', 'a9e748d4-dc2b-4d5b-9571-2e2f2bc78e0d', '2026-10-11 13:42:26.857593+00', '2026-10-12 09:53:17.089412+00', NULL, 'aal1', NULL, '2026-10-12 09:53:17.083862', 'Dart/3.13 (dart:io)', '196.190.62.201', NULL, NULL, NULL, NULL, NULL),
	('823e8359-6e24-495e-8867-27509ee31607', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', '2026-10-11 13:17:07.414252+00', '2026-10-12 12:01:33.172405+00', NULL, 'aal1', NULL, '2026-10-12 12:01:33.172256', 'Dart/3.13 (dart:io)', '196.189.145.224', NULL, NULL, NULL, NULL, NULL),
	('3afe8b1f-9942-450c-8087-e46534ebf01f', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', '2026-09-28 10:58:18.8164+00', '2026-09-28 14:26:32.38796+00', NULL, 'aal1', NULL, '2026-09-28 14:26:32.387835', 'Dart/3.13 (dart:io)', '102.213.68.169', NULL, NULL, NULL, NULL, NULL),
	('f26d23f5-c171-48b9-b177-b93e0ebb1c15', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', '2026-10-12 12:01:53.446404+00', '2026-10-12 12:01:53.446404+00', NULL, 'aal1', NULL, NULL, 'Dart/3.13 (dart:io)', '196.189.145.224', NULL, NULL, NULL, NULL, NULL),
	('f105ebea-7640-48e5-8705-344963066090', '64efef4f-1555-4322-80ad-f69e46887516', '2026-10-12 19:53:49.801762+00', '2026-10-12 19:53:49.801762+00', NULL, 'aal1', NULL, NULL, 'Dart/3.13 (dart:io)', '196.188.180.60', NULL, NULL, NULL, NULL, NULL),
	('9920756d-5661-4c5a-adaf-988aaeeba23e', '64efef4f-1555-4322-80ad-f69e46887516', '2026-10-12 22:20:06.881859+00', '2026-10-12 22:20:06.881859+00', NULL, 'aal1', NULL, NULL, 'Dart/3.13 (dart:io)', '196.188.180.60', NULL, NULL, NULL, NULL, NULL),
	('1f112169-7ab8-4d5b-8168-bcacf181afdb', '5101cac2-a24e-4342-975a-74df63071328', '2026-09-11 11:11:01.553234+00', '2026-09-13 11:09:05.46041+00', NULL, 'aal1', NULL, '2026-09-13 11:09:05.460279', 'Dart/3.13 (dart:io)', '102.208.97.29', NULL, NULL, NULL, NULL, NULL),
	('ec627901-bfbb-4c5f-99d1-5aa77a9c0700', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', '2026-10-12 12:01:58.660181+00', '2026-10-13 05:50:19.589148+00', NULL, 'aal1', NULL, '2026-10-13 05:50:19.589021', 'Dart/3.13 (dart:io)', '102.213.68.28', NULL, NULL, NULL, NULL, NULL),
	('b975f7e2-15f9-4ab2-9722-f22f58a72431', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', '2026-10-13 05:53:00.337048+00', '2026-10-13 05:53:00.337048+00', NULL, 'aal1', NULL, NULL, 'Dart/3.13 (dart:io)', '102.213.68.28', NULL, NULL, NULL, NULL, NULL),
	('6bef393a-5040-4c51-8146-bc64c04f36d5', '5101cac2-a24e-4342-975a-74df63071328', '2026-09-19 17:51:39.008859+00', '2026-09-19 19:50:43.674587+00', NULL, 'aal1', NULL, '2026-09-19 19:50:43.674458', 'Dart/3.13 (dart:io)', '102.218.50.186', NULL, NULL, NULL, NULL, NULL),
	('a0dc3f00-bfdc-4026-822b-b29e6a1bd7bd', '5101cac2-a24e-4342-975a-74df63071328', '2026-09-22 17:02:49.905071+00', '2026-09-24 12:23:30.566046+00', NULL, 'aal1', NULL, '2026-09-24 12:23:30.565925', 'Dart/3.13 (dart:io)', '102.213.68.139', NULL, NULL, NULL, NULL, NULL);


--
-- Data for Name: mfa_amr_claims; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

INSERT INTO "auth"."mfa_amr_claims" ("session_id", "created_at", "updated_at", "authentication_method", "id") VALUES
	('9cb0b80b-6308-4c25-a67b-adb2f970364e', '2026-09-30 08:16:03.209576+00', '2026-09-30 08:16:03.209576+00', 'password', '954dd86f-2eea-4fc8-8753-d065df432a6e'),
	('9d73905e-5f3f-40df-92a3-44d978193076', '2026-10-01 15:30:06.669322+00', '2026-10-01 15:30:06.669322+00', 'password', 'aaf0767d-dd4e-4436-9a01-8156da98955d'),
	('532bad7f-0190-470e-9cf4-bb33cd456cd2', '2026-09-25 17:10:38.253723+00', '2026-09-25 17:10:38.253723+00', 'password', 'f12feb97-cb9d-454e-8820-76a05ca3e2d6'),
	('0d38a2c8-70e3-4964-92d0-1f76850f707c', '2026-10-01 15:49:48.269676+00', '2026-10-01 15:49:48.269676+00', 'password', '754773ba-1ea9-4be9-9a31-e1d73a904626'),
	('5a1e4472-2b00-4fcd-9d93-b88ed5577061', '2026-10-02 15:29:08.561659+00', '2026-10-02 15:29:08.561659+00', 'password', 'bdcb8c6d-7b02-4d01-b55d-322192c99975'),
	('bd852838-2e58-4cc9-9826-a7b8a76bf6f0', '2026-10-03 10:37:46.925193+00', '2026-10-03 10:37:46.925193+00', 'password', '5c5a2f6a-0b77-4257-b89c-1bd76038c53a'),
	('a82c26b5-c0c7-4ca3-8aff-698191d4ed56', '2026-09-25 20:44:35.173222+00', '2026-09-25 20:44:35.173222+00', 'password', 'be5836a7-9516-4259-83d8-abe7c0694510'),
	('076ae599-5f62-44b3-98bf-e0937bbc5b1d', '2026-10-03 13:20:48.190194+00', '2026-10-03 13:20:48.190194+00', 'password', '65c63832-3ce8-49e1-93b5-1232aeab1d6d'),
	('bf300f6c-e893-4843-954b-c42f5bfccb9f', '2026-10-03 14:03:43.084067+00', '2026-10-03 14:03:43.084067+00', 'password', '18c8ea22-8307-46f8-a357-47379a800dbb'),
	('969a86c0-5134-4d3d-a867-7908e2b1bbe8', '2026-10-04 09:45:47.47853+00', '2026-10-04 09:45:47.47853+00', 'password', '7d5365c7-ee4b-44ff-9e20-17a90537f183'),
	('61a64991-6765-4d07-ab30-3154fccf10a1', '2026-10-08 04:44:32.317863+00', '2026-10-08 04:44:32.317863+00', 'password', 'fcf6ccdd-8352-4d0a-b3ea-5fc42c92aa36'),
	('a1b45fd2-c63f-4bf5-817f-1a9e865b6988', '2026-10-08 04:45:07.027065+00', '2026-10-08 04:45:07.027065+00', 'password', '17fb035f-682f-4b48-8c10-d84f3a3725d7'),
	('c3fbc074-049a-4302-92f8-a78baec964d6', '2026-10-11 12:56:51.564109+00', '2026-10-11 12:56:51.564109+00', 'password', '75e4a56f-d752-4548-b34f-daf3e49f81f2'),
	('251e972c-e50b-4aba-aeaa-027a781e0d70', '2026-09-26 15:03:23.027828+00', '2026-09-26 15:03:23.027828+00', 'password', 'f1a2d0b8-6258-4f64-8b15-79117f0a489b'),
	('824f58d4-877d-4a8f-b578-b12431bed7b6', '2026-09-28 08:29:14.680786+00', '2026-09-28 08:29:14.680786+00', 'password', '5c40183b-f1cd-4a1b-bf31-f49cb1927df1'),
	('6ee82a3a-cd4c-4520-a07f-ed842710e049', '2026-10-11 13:05:33.200936+00', '2026-10-11 13:05:33.200936+00', 'password', '4bf952d8-64fe-4ca4-85c3-42e7f22619ab'),
	('3afe8b1f-9942-450c-8087-e46534ebf01f', '2026-09-28 10:58:18.826692+00', '2026-09-28 10:58:18.826692+00', 'password', '8e413a11-9be5-40d7-9e31-35c3aa85b6ea'),
	('a1a63a9f-35f2-4ac1-a72c-8890b28bbf39', '2026-10-11 13:10:59.848117+00', '2026-10-11 13:10:59.848117+00', 'password', 'eb365a5f-e07f-4ff1-9ac4-fbea04831a15'),
	('823e8359-6e24-495e-8867-27509ee31607', '2026-10-11 13:17:07.471804+00', '2026-10-11 13:17:07.471804+00', 'password', 'a81332bf-9870-4bfb-904c-90a1f2c2437b'),
	('43b8f04c-69b7-4b0c-954a-ba1e1be11b7b', '2026-10-11 13:42:26.897182+00', '2026-10-11 13:42:26.897182+00', 'password', '7dce0b8f-56cb-4d28-9ba7-321349e5128c'),
	('e5f8caf7-856c-4b92-9cae-0d635c1ff43e', '2026-10-11 13:54:21.794893+00', '2026-10-11 13:54:21.794893+00', 'password', '82926256-d4a2-461b-a29a-137ff7cd90a2'),
	('dc0a330c-2505-4ed8-83b0-43c8c50fc10e', '2026-09-28 13:17:13.591131+00', '2026-09-28 13:17:13.591131+00', 'password', 'f229e0df-39dd-4cdd-b15c-38b0312d577f'),
	('f26d23f5-c171-48b9-b177-b93e0ebb1c15', '2026-10-12 12:01:53.475877+00', '2026-10-12 12:01:53.475877+00', 'password', '03b3aafb-ffa3-4617-8c69-7c20ed905ef6'),
	('ec627901-bfbb-4c5f-99d1-5aa77a9c0700', '2026-10-12 12:01:58.663765+00', '2026-10-12 12:01:58.663765+00', 'password', 'cfc12212-6486-41dd-ab36-774e3115338f'),
	('f105ebea-7640-48e5-8705-344963066090', '2026-10-12 19:53:49.874761+00', '2026-10-12 19:53:49.874761+00', 'password', '381a95c2-e647-4df8-875f-61901b23f002'),
	('9920756d-5661-4c5a-adaf-988aaeeba23e', '2026-10-12 22:20:06.956967+00', '2026-10-12 22:20:06.956967+00', 'password', '643fa23a-f30d-4ad4-8461-cb2becec3d5e'),
	('299c163a-099a-4a10-88a0-f10dad3de521', '2026-09-28 14:26:52.044654+00', '2026-09-28 14:26:52.044654+00', 'password', 'f127a581-a80b-42a9-8303-443f86563635'),
	('b975f7e2-15f9-4ab2-9722-f22f58a72431', '2026-10-13 05:53:00.378541+00', '2026-10-13 05:53:00.378541+00', 'password', 'b8ac6093-68dc-400f-b84b-0edce9b9a3f0'),
	('2786416a-3132-44ab-8632-b9d9f4bcc282', '2026-09-29 19:28:46.755673+00', '2026-09-29 19:28:46.755673+00', 'password', '5f674c83-47f2-45d2-9c94-eb0258b23465'),
	('1f112169-7ab8-4d5b-8168-bcacf181afdb', '2026-09-11 11:11:01.559053+00', '2026-09-11 11:11:01.559053+00', 'otp', '378c7524-daa5-414f-84b4-405607ec5077'),
	('2764a656-1ace-4d21-807d-78373463ec58', '2026-09-30 07:22:44.155642+00', '2026-09-30 07:22:44.155642+00', 'password', 'f15d551b-d6ca-472e-b3f6-c78786cbcf94'),
	('211a2820-c0b7-415e-b896-71d0b32dc6b6', '2026-09-30 07:41:09.211815+00', '2026-09-30 07:41:09.211815+00', 'password', '258cdce4-d5c3-4426-9e22-365640b7df99'),
	('6bef393a-5040-4c51-8146-bc64c04f36d5', '2026-09-19 17:51:39.027032+00', '2026-09-19 17:51:39.027032+00', 'password', 'b73331d2-566d-4384-b5ee-5c3396c97583'),
	('a0dc3f00-bfdc-4026-822b-b29e6a1bd7bd', '2026-09-22 17:02:49.930077+00', '2026-09-22 17:02:49.930077+00', 'password', '140e4661-d742-4ce8-bab8-ade2c83e2ed2');


--
-- Data for Name: mfa_factors; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: mfa_challenges; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: mfa_recovery_code_sets; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: mfa_recovery_codes; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: oauth_authorizations; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: oauth_client_states; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: oauth_consents; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: one_time_tokens; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: refresh_tokens; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

INSERT INTO "auth"."refresh_tokens" ("instance_id", "id", "token", "user_id", "revoked", "created_at", "updated_at", "parent", "session_id") VALUES
	('00000000-0000-0000-0000-000000000000', 227, 'bmxm7ld3qhy7', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', true, '2026-09-28 15:34:13.359296+00', '2026-09-29 08:20:32.933375+00', '7mbjikihsace', 'dc0a330c-2505-4ed8-83b0-43c8c50fc10e'),
	('00000000-0000-0000-0000-000000000000', 225, 'yczbgcuvd6cn', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', true, '2026-09-28 14:26:52.034262+00', '2026-09-30 07:22:30.822741+00', NULL, '299c163a-099a-4a10-88a0-f10dad3de521'),
	('00000000-0000-0000-0000-000000000000', 212, 'hb35qow6pylo', '64efef4f-1555-4322-80ad-f69e46887516', true, '2026-09-26 16:44:24.401667+00', '2026-09-27 12:13:48.749234+00', 'rlygxywtd7tp', '251e972c-e50b-4aba-aeaa-027a781e0d70'),
	('00000000-0000-0000-0000-000000000000', 242, '5rclng6ru5xu', '96f15dbd-e885-4f42-8f55-492bd72cd515', true, '2026-09-30 07:41:09.157171+00', '2026-09-30 08:41:00.557782+00', NULL, '211a2820-c0b7-415e-b896-71d0b32dc6b6'),
	('00000000-0000-0000-0000-000000000000', 214, 'b2z2ag6jnhhx', '64efef4f-1555-4322-80ad-f69e46887516', true, '2026-09-28 08:29:14.638457+00', '2026-09-28 09:37:45.191777+00', NULL, '824f58d4-877d-4a8f-b578-b12431bed7b6'),
	('00000000-0000-0000-0000-000000000000', 244, 'ahsjxa5r3sjn', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', true, '2026-09-30 08:16:03.193251+00', '2026-09-30 09:19:01.823823+00', NULL, '9cb0b80b-6308-4c25-a67b-adb2f970364e'),
	('00000000-0000-0000-0000-000000000000', 218, '6c4mx6c46uh7', '64efef4f-1555-4322-80ad-f69e46887516', false, '2026-09-28 13:00:50.836828+00', '2026-09-28 13:00:50.836828+00', 'l3juaqcwvlvd', '824f58d4-877d-4a8f-b578-b12431bed7b6'),
	('00000000-0000-0000-0000-000000000000', 246, 'ik3iqy7kydlp', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', false, '2026-09-30 09:19:01.842129+00', '2026-09-30 09:19:01.842129+00', 'ahsjxa5r3sjn', '9cb0b80b-6308-4c25-a67b-adb2f970364e'),
	('00000000-0000-0000-0000-000000000000', 248, 'mgyzejcklbxs', '96f15dbd-e885-4f42-8f55-492bd72cd515', true, '2026-09-30 18:37:02.184061+00', '2026-09-30 19:35:42.391537+00', 'wgmvwozlkdky', '211a2820-c0b7-415e-b896-71d0b32dc6b6'),
	('00000000-0000-0000-0000-000000000000', 222, 'h3fh4lu2eaym', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', true, '2026-09-28 13:17:13.583899+00', '2026-09-28 14:19:15.276103+00', NULL, 'dc0a330c-2505-4ed8-83b0-43c8c50fc10e'),
	('00000000-0000-0000-0000-000000000000', 224, 'kgxh27dquzcb', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', false, '2026-09-28 14:26:32.381875+00', '2026-09-28 14:26:32.381875+00', 'pqyac6qzmqjy', '3afe8b1f-9942-450c-8087-e46534ebf01f'),
	('00000000-0000-0000-0000-000000000000', 252, 'y33chjv75tvx', '3f3e0eb5-aeb1-4999-bd98-18543b01b613', true, '2026-10-01 15:49:48.236727+00', '2026-10-01 16:48:33.749402+00', NULL, '0d38a2c8-70e3-4964-92d0-1f76850f707c'),
	('00000000-0000-0000-0000-000000000000', 174, 'dgun3ng37ojw', '5101cac2-a24e-4342-975a-74df63071328', true, '2026-09-22 17:02:49.919547+00', '2026-09-24 12:23:30.533064+00', NULL, 'a0dc3f00-bfdc-4026-822b-b29e6a1bd7bd'),
	('00000000-0000-0000-0000-000000000000', 254, 's34ngjtklu5r', '3f3e0eb5-aeb1-4999-bd98-18543b01b613', true, '2026-10-01 16:48:33.763541+00', '2026-10-01 17:47:12.809388+00', 'y33chjv75tvx', '0d38a2c8-70e3-4964-92d0-1f76850f707c'),
	('00000000-0000-0000-0000-000000000000', 256, 'iqtw5cpsifmm', '3f3e0eb5-aeb1-4999-bd98-18543b01b613', true, '2026-10-01 18:45:57.489125+00', '2026-10-01 19:44:51.597608+00', 'qyqwbhww45dp', '0d38a2c8-70e3-4964-92d0-1f76850f707c'),
	('00000000-0000-0000-0000-000000000000', 258, 'weqi43crqtjj', '3f3e0eb5-aeb1-4999-bd98-18543b01b613', false, '2026-10-01 20:43:37.203833+00', '2026-10-01 20:43:37.203833+00', 'dhdgiqta3m2u', '0d38a2c8-70e3-4964-92d0-1f76850f707c'),
	('00000000-0000-0000-0000-000000000000', 264, 'xoas6wnatuyw', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', false, '2026-10-03 10:35:32.741846+00', '2026-10-03 10:35:32.741846+00', 'q4fj437wjdvh', '5a1e4472-2b00-4fcd-9d93-b88ed5577061'),
	('00000000-0000-0000-0000-000000000000', 268, 'am2565dkyvjq', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', false, '2026-10-03 14:03:28.767185+00', '2026-10-03 14:03:28.767185+00', 'u5omyom5igtx', '2764a656-1ace-4d21-807d-78373463ec58'),
	('00000000-0000-0000-0000-000000000000', 269, 'ffkfqwinvama', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', true, '2026-10-03 14:03:43.074558+00', '2026-10-04 09:45:34.649403+00', NULL, 'bf300f6c-e893-4843-954b-c42f5bfccb9f'),
	('00000000-0000-0000-0000-000000000000', 190, 'iemyssmgvqwr', '9f67e506-cdfd-4890-b83c-da752caae614', false, '2026-09-25 17:10:38.223763+00', '2026-09-25 17:10:38.223763+00', NULL, '532bad7f-0190-470e-9cf4-bb33cd456cd2'),
	('00000000-0000-0000-0000-000000000000', 271, 'n4ewkdjsmol3', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', false, '2026-10-04 09:45:34.662858+00', '2026-10-04 09:45:34.662858+00', 'ffkfqwinvama', 'bf300f6c-e893-4843-954b-c42f5bfccb9f'),
	('00000000-0000-0000-0000-000000000000', 274, 'lhesuyn5fwig', '9f67e506-cdfd-4890-b83c-da752caae614', false, '2026-10-08 04:44:32.307109+00', '2026-10-08 04:44:32.307109+00', NULL, '61a64991-6765-4d07-ab30-3154fccf10a1'),
	('00000000-0000-0000-0000-000000000000', 275, '635aaaf6kbkl', '64efef4f-1555-4322-80ad-f69e46887516', true, '2026-10-08 04:45:07.024764+00', '2026-10-08 09:50:29.032655+00', NULL, 'a1b45fd2-c63f-4bf5-817f-1a9e865b6988'),
	('00000000-0000-0000-0000-000000000000', 199, 'sxnlrhx26fcv', '5101cac2-a24e-4342-975a-74df63071328', true, '2026-09-25 20:44:35.168595+00', '2026-09-26 12:00:26.774933+00', NULL, 'a82c26b5-c0c7-4ca3-8aff-698191d4ed56'),
	('00000000-0000-0000-0000-000000000000', 201, 'l7blndrnsrlc', '5101cac2-a24e-4342-975a-74df63071328', false, '2026-09-26 12:00:26.789992+00', '2026-09-26 12:00:26.789992+00', 'sxnlrhx26fcv', 'a82c26b5-c0c7-4ca3-8aff-698191d4ed56'),
	('00000000-0000-0000-0000-000000000000', 272, 'adp5b4uorx56', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', true, '2026-10-04 09:45:47.467116+00', '2026-10-11 12:56:35.554208+00', NULL, '969a86c0-5134-4d3d-a867-7908e2b1bbe8'),
	('00000000-0000-0000-0000-000000000000', 277, 'peqy2ypqvnlc', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', false, '2026-10-11 12:56:35.565931+00', '2026-10-11 12:56:35.565931+00', 'adp5b4uorx56', '969a86c0-5134-4d3d-a867-7908e2b1bbe8'),
	('00000000-0000-0000-0000-000000000000', 278, 'w3wfvghbgt4w', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', false, '2026-10-11 12:56:51.55256+00', '2026-10-11 12:56:51.55256+00', NULL, 'c3fbc074-049a-4302-92f8-a78baec964d6'),
	('00000000-0000-0000-0000-000000000000', 281, 'sbpiit5bwqxs', '3f3e0eb5-aeb1-4999-bd98-18543b01b613', true, '2026-10-11 13:10:59.840754+00', '2026-10-12 03:38:59.553665+00', NULL, 'a1a63a9f-35f2-4ac1-a72c-8890b28bbf39'),
	('00000000-0000-0000-0000-000000000000', 285, 'izs6gd3nzvku', '3f3e0eb5-aeb1-4999-bd98-18543b01b613', false, '2026-10-12 03:38:59.568788+00', '2026-10-12 03:38:59.568788+00', 'sbpiit5bwqxs', 'a1a63a9f-35f2-4ac1-a72c-8890b28bbf39'),
	('00000000-0000-0000-0000-000000000000', 283, 'lle336ygdr6b', 'a9e748d4-dc2b-4d5b-9571-2e2f2bc78e0d', true, '2026-10-11 13:42:26.879309+00', '2026-10-12 09:53:17.027474+00', NULL, '43b8f04c-69b7-4b0c-954a-ba1e1be11b7b'),
	('00000000-0000-0000-0000-000000000000', 287, '6l2atgrwpuwq', 'a9e748d4-dc2b-4d5b-9571-2e2f2bc78e0d', false, '2026-10-12 09:53:17.056525+00', '2026-10-12 09:53:17.056525+00', 'lle336ygdr6b', '43b8f04c-69b7-4b0c-954a-ba1e1be11b7b'),
	('00000000-0000-0000-0000-000000000000', 291, 'gv24um6eb7ls', '64efef4f-1555-4322-80ad-f69e46887516', false, '2026-10-12 19:53:49.8368+00', '2026-10-12 19:53:49.8368+00', NULL, 'f105ebea-7640-48e5-8705-344963066090'),
	('00000000-0000-0000-0000-000000000000', 293, 'cbvpbt3dfkht', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', false, '2026-10-13 05:50:19.572147+00', '2026-10-13 05:50:19.572147+00', 'uzllizxz2ai4', 'ec627901-bfbb-4c5f-99d1-5aa77a9c0700'),
	('00000000-0000-0000-0000-000000000000', 232, 'bjxyn2q6e2jl', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', false, '2026-09-29 08:20:32.946748+00', '2026-09-29 08:20:32.946748+00', 'bmxm7ld3qhy7', 'dc0a330c-2505-4ed8-83b0-43c8c50fc10e'),
	('00000000-0000-0000-0000-000000000000', 234, '6tn7jae6rxwu', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', false, '2026-09-29 19:28:46.697582+00', '2026-09-29 19:28:46.697582+00', NULL, '2786416a-3132-44ab-8632-b9d9f4bcc282'),
	('00000000-0000-0000-0000-000000000000', 238, 'qmrriywo457p', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', false, '2026-09-30 07:22:30.844768+00', '2026-09-30 07:22:30.844768+00', 'yczbgcuvd6cn', '299c163a-099a-4a10-88a0-f10dad3de521'),
	('00000000-0000-0000-0000-000000000000', 209, 'rlygxywtd7tp', '64efef4f-1555-4322-80ad-f69e46887516', true, '2026-09-26 15:03:23.013043+00', '2026-09-26 16:44:24.389183+00', NULL, '251e972c-e50b-4aba-aeaa-027a781e0d70'),
	('00000000-0000-0000-0000-000000000000', 213, 'hp5tn6tzgnz5', '64efef4f-1555-4322-80ad-f69e46887516', false, '2026-09-27 12:13:48.773039+00', '2026-09-27 12:13:48.773039+00', 'hb35qow6pylo', '251e972c-e50b-4aba-aeaa-027a781e0d70'),
	('00000000-0000-0000-0000-000000000000', 245, '7armcb7l4oyh', '96f15dbd-e885-4f42-8f55-492bd72cd515', true, '2026-09-30 08:41:00.576624+00', '2026-09-30 17:38:07.694767+00', '5rclng6ru5xu', '211a2820-c0b7-415e-b896-71d0b32dc6b6'),
	('00000000-0000-0000-0000-000000000000', 247, 'wgmvwozlkdky', '96f15dbd-e885-4f42-8f55-492bd72cd515', true, '2026-09-30 17:38:07.713621+00', '2026-09-30 18:37:02.169514+00', '7armcb7l4oyh', '211a2820-c0b7-415e-b896-71d0b32dc6b6'),
	('00000000-0000-0000-0000-000000000000', 249, 'cz7gmrrtdbun', '96f15dbd-e885-4f42-8f55-492bd72cd515', false, '2026-09-30 19:35:42.405333+00', '2026-09-30 19:35:42.405333+00', 'mgyzejcklbxs', '211a2820-c0b7-415e-b896-71d0b32dc6b6'),
	('00000000-0000-0000-0000-000000000000', 251, '7lbg2qsdehih', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', true, '2026-10-01 15:30:06.645054+00', '2026-10-01 16:33:30.307786+00', NULL, '9d73905e-5f3f-40df-92a3-44d978193076'),
	('00000000-0000-0000-0000-000000000000', 215, 'l3juaqcwvlvd', '64efef4f-1555-4322-80ad-f69e46887516', true, '2026-09-28 09:37:45.215293+00', '2026-09-28 13:00:50.812922+00', 'b2z2ag6jnhhx', '824f58d4-877d-4a8f-b578-b12431bed7b6'),
	('00000000-0000-0000-0000-000000000000', 255, 'qyqwbhww45dp', '3f3e0eb5-aeb1-4999-bd98-18543b01b613', true, '2026-10-01 17:47:12.824483+00', '2026-10-01 18:45:57.469475+00', 's34ngjtklu5r', '0d38a2c8-70e3-4964-92d0-1f76850f707c'),
	('00000000-0000-0000-0000-000000000000', 217, 'pqyac6qzmqjy', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', true, '2026-09-28 10:58:18.821318+00', '2026-09-28 14:26:32.374662+00', NULL, '3afe8b1f-9942-450c-8087-e46534ebf01f'),
	('00000000-0000-0000-0000-000000000000', 257, 'dhdgiqta3m2u', '3f3e0eb5-aeb1-4999-bd98-18543b01b613', true, '2026-10-01 19:44:51.612079+00', '2026-10-01 20:43:37.188037+00', 'iqtw5cpsifmm', '0d38a2c8-70e3-4964-92d0-1f76850f707c'),
	('00000000-0000-0000-0000-000000000000', 253, 'lw4ki25267ay', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', true, '2026-10-01 16:33:30.325168+00', '2026-10-02 12:51:24.394823+00', '7lbg2qsdehih', '9d73905e-5f3f-40df-92a3-44d978193076'),
	('00000000-0000-0000-0000-000000000000', 223, '7mbjikihsace', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', true, '2026-09-28 14:19:15.296778+00', '2026-09-28 15:34:13.338987+00', 'h3fh4lu2eaym', 'dc0a330c-2505-4ed8-83b0-43c8c50fc10e'),
	('00000000-0000-0000-0000-000000000000', 259, '3ng5665w2ack', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', false, '2026-10-02 12:51:24.404303+00', '2026-10-02 12:51:24.404303+00', 'lw4ki25267ay', '9d73905e-5f3f-40df-92a3-44d978193076'),
	('00000000-0000-0000-0000-000000000000', 107, '6i2fxsmydrer', '5101cac2-a24e-4342-975a-74df63071328', true, '2026-09-11 11:11:01.555171+00', '2026-09-13 11:09:05.418005+00', NULL, '1f112169-7ab8-4d5b-8168-bcacf181afdb'),
	('00000000-0000-0000-0000-000000000000', 108, 'gk7cod2s3sgj', '5101cac2-a24e-4342-975a-74df63071328', false, '2026-09-13 11:09:05.442212+00', '2026-09-13 11:09:05.442212+00', '6i2fxsmydrer', '1f112169-7ab8-4d5b-8168-bcacf181afdb'),
	('00000000-0000-0000-0000-000000000000', 263, 'q4fj437wjdvh', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', true, '2026-10-02 15:29:08.541827+00', '2026-10-03 10:35:32.730984+00', NULL, '5a1e4472-2b00-4fcd-9d93-b88ed5577061'),
	('00000000-0000-0000-0000-000000000000', 265, 'smmjuqaey44t', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', false, '2026-10-03 10:37:46.913324+00', '2026-10-03 10:37:46.913324+00', NULL, 'bd852838-2e58-4cc9-9826-a7b8a76bf6f0'),
	('00000000-0000-0000-0000-000000000000', 239, 'u5omyom5igtx', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', true, '2026-09-30 07:22:44.139209+00', '2026-10-03 14:03:28.749505+00', NULL, '2764a656-1ace-4d21-807d-78373463ec58'),
	('00000000-0000-0000-0000-000000000000', 267, 'lvaxpqdcoeip', '64efef4f-1555-4322-80ad-f69e46887516', true, '2026-10-03 13:20:48.18691+00', '2026-10-03 14:22:54.022012+00', NULL, '076ae599-5f62-44b3-98bf-e0937bbc5b1d'),
	('00000000-0000-0000-0000-000000000000', 270, '35rtlv7pe73o', '64efef4f-1555-4322-80ad-f69e46887516', true, '2026-10-03 14:22:54.032012+00', '2026-10-08 04:44:15.553406+00', 'lvaxpqdcoeip', '076ae599-5f62-44b3-98bf-e0937bbc5b1d'),
	('00000000-0000-0000-0000-000000000000', 176, 'yp7kgbcmbbpj', '5101cac2-a24e-4342-975a-74df63071328', false, '2026-09-24 12:23:30.54401+00', '2026-09-24 12:23:30.54401+00', 'dgun3ng37ojw', 'a0dc3f00-bfdc-4026-822b-b29e6a1bd7bd'),
	('00000000-0000-0000-0000-000000000000', 273, 'krbt4ywdpc73', '64efef4f-1555-4322-80ad-f69e46887516', false, '2026-10-08 04:44:15.569233+00', '2026-10-08 04:44:15.569233+00', '35rtlv7pe73o', '076ae599-5f62-44b3-98bf-e0937bbc5b1d'),
	('00000000-0000-0000-0000-000000000000', 276, 'dk5kg5ntnxcj', '64efef4f-1555-4322-80ad-f69e46887516', false, '2026-10-08 09:50:29.04786+00', '2026-10-08 09:50:29.04786+00', '635aaaf6kbkl', 'a1b45fd2-c63f-4bf5-817f-1a9e865b6988'),
	('00000000-0000-0000-0000-000000000000', 279, 'xvt76qfxxs4g', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', false, '2026-10-11 13:05:33.182417+00', '2026-10-11 13:05:33.182417+00', NULL, '6ee82a3a-cd4c-4520-a07f-ed842710e049'),
	('00000000-0000-0000-0000-000000000000', 284, '6jne7sifzod6', '3f3e0eb5-aeb1-4999-bd98-18543b01b613', true, '2026-10-11 13:54:21.75702+00', '2026-10-12 07:56:25.280677+00', NULL, 'e5f8caf7-856c-4b92-9cae-0d635c1ff43e'),
	('00000000-0000-0000-0000-000000000000', 286, 'nzfav5evb2kh', '3f3e0eb5-aeb1-4999-bd98-18543b01b613', false, '2026-10-12 07:56:25.299332+00', '2026-10-12 07:56:25.299332+00', '6jne7sifzod6', 'e5f8caf7-856c-4b92-9cae-0d635c1ff43e'),
	('00000000-0000-0000-0000-000000000000', 282, 'fvsu7m7iufqi', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', true, '2026-10-11 13:17:07.442507+00', '2026-10-12 12:01:33.132834+00', NULL, '823e8359-6e24-495e-8867-27509ee31607'),
	('00000000-0000-0000-0000-000000000000', 288, 'ngp7qp6axfc3', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', false, '2026-10-12 12:01:33.148107+00', '2026-10-12 12:01:33.148107+00', 'fvsu7m7iufqi', '823e8359-6e24-495e-8867-27509ee31607'),
	('00000000-0000-0000-0000-000000000000', 289, 'kmzqofnruzuo', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', false, '2026-10-12 12:01:53.462119+00', '2026-10-12 12:01:53.462119+00', NULL, 'f26d23f5-c171-48b9-b177-b93e0ebb1c15'),
	('00000000-0000-0000-0000-000000000000', 292, 'bs5mux645glg', '64efef4f-1555-4322-80ad-f69e46887516', false, '2026-10-12 22:20:06.913174+00', '2026-10-12 22:20:06.913174+00', NULL, '9920756d-5661-4c5a-adaf-988aaeeba23e'),
	('00000000-0000-0000-0000-000000000000', 290, 'uzllizxz2ai4', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', true, '2026-10-12 12:01:58.662007+00', '2026-10-13 05:50:19.55908+00', NULL, 'ec627901-bfbb-4c5f-99d1-5aa77a9c0700'),
	('00000000-0000-0000-0000-000000000000', 294, 'k2j6i37gjkdk', 'a5c1a9c8-6ccd-49c2-a069-2781c83be09d', false, '2026-10-13 05:53:00.363402+00', '2026-10-13 05:53:00.363402+00', NULL, 'b975f7e2-15f9-4ab2-9722-f22f58a72431'),
	('00000000-0000-0000-0000-000000000000', 143, 'kffuzduhg3nf', '5101cac2-a24e-4342-975a-74df63071328', true, '2026-09-19 17:51:39.023186+00', '2026-09-19 18:51:13.451537+00', NULL, '6bef393a-5040-4c51-8146-bc64c04f36d5'),
	('00000000-0000-0000-0000-000000000000', 144, 'ym6z3ceb3znx', '5101cac2-a24e-4342-975a-74df63071328', true, '2026-09-19 18:51:13.464266+00', '2026-09-19 19:50:43.623985+00', 'kffuzduhg3nf', '6bef393a-5040-4c51-8146-bc64c04f36d5'),
	('00000000-0000-0000-0000-000000000000', 145, 'nlxmeyn2zvjn', '5101cac2-a24e-4342-975a-74df63071328', false, '2026-09-19 19:50:43.636052+00', '2026-09-19 19:50:43.636052+00', 'ym6z3ceb3znx', '6bef393a-5040-4c51-8146-bc64c04f36d5');


--
-- Data for Name: sso_providers; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: saml_providers; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: saml_relay_states; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: scim_tokens; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: scim_users; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: sso_domains; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: webauthn_challenges; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: webauthn_credentials; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE SET; Schema: auth; Owner: supabase_auth_admin
--

SELECT pg_catalog.setval('"auth"."refresh_tokens_id_seq"', 294, true);


--
-- PostgreSQL database dump complete
--

-- \unrestrict oL7U3QZgRtdSkWblZroboN78R7gyec9bYBKdYwXbmaDM4Dyzb1kImaVBgvEUIOx

RESET ALL;
