begin;

/* Backfill the earlier mobile flow which inserted pending repayments directly
   into payments, before the V3 repayment-submission intake RPC was adopted. */
insert into public.loan_repayment_submissions (
  loan_id, payment_id, borrower_type, payer_profile_id, payer_name, payer_phone,
  amount, payment_method_code, external_reference, payment_proof_path, status,
  submitted_by, submitted_at
)
select
  l.id,
  p.id,
  case when l.outsider_loan_application_id is null then 'member'::public.loan_borrower_type else 'outsider'::public.loan_borrower_type end,
  p.payer_profile_id,
  coalesce(profile.full_name, 'Unknown payer'),
  profile.phone,
  round(p.amount, 2),
  case when lower(pm.code) = 'bank_transfer' then 'bank' else lower(pm.code) end,
  nullif(trim(p.external_reference), ''),
  nullif(trim(p.payment_proof_path), ''),
  'pending',
  p.payer_profile_id,
  coalesce(p.created_at, now())
from public.payments p
join public.loans l on l.id = p.purpose_id
join public.payment_methods pm on pm.id = p.payment_method_id
left join public.profiles profile on profile.id = p.payer_profile_id
where p.purpose_type = 'loan_repayment'
  and p.status = 'pending'
  and p.payer_profile_id is not null
  and l.outsider_loan_application_id is null
  and l.borrower_profile_id = p.payer_profile_id
  and p.amount > 0
  and lower(pm.code) in ('cash', 'bank', 'wallet', 'bank_transfer')
  and not exists (
    select 1 from public.loan_repayment_submissions rs where rs.payment_id = p.id
  );

commit;
