begin;

/*
  Repayment submissions are deliberately not selectable by the authenticated
  role. Admin pages must therefore use a permission-checked RPC rather than a
  direct PostgREST table query; otherwise a real row is presented as a 404.
*/
create or replace function publbic.get_admin_loan_repayment_detail_v3(
  p_submission_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_actor uuid := private.loan_require_permission_v3('loan.read');
  v_result jsonb;
begin
  select jsonb_build_object(
    'id', rs.id,
    'submission_id', rs.id,
    'reference_number', p.reference_number,
    'payer_name', rs.payer_name,
    'payer_phone', rs.payer_phone,
    'amount', rs.amount,
    'payment_method', rs.payment_method_code,
    'external_reference', rs.external_reference,
    'payment_proof_path', rs.payment_proof_path,
    'payment_date', coalesce(p.submitted_at, p.created_at, rs.submitted_at),
    'submitted_at', rs.submitted_at,
    'status', rs.status,
    'verified_at', rs.verified_at,
    'verified_by_admin_id', rs.verified_by,
    'rejected_reason', rs.rejected_reason,
    'posted_transaction_id', rs.posted_transaction_id,
    'reversed_at', rs.reversed_at,
    'loan', jsonb_build_object(
      'id', l.id,
      'loan_number', l.loan_number,
      'principal', l.principal,
      'outstanding_balance', coalesce((
        select sum(
          greatest(i.total_due - i.paid_amount, 0)
          + greatest(i.late_penalty_amount - i.paid_penalty_amount, 0)
        )
        from public.loan_installments i
        where i.loan_id = l.id
      ), 0),
      'status', l.status,
      'borrower_profile_id', l.borrower_profile_id
    )
  )
  into v_result
  from public.loan_repayment_submissions rs
  join public.loans l on l.id = rs.loan_id
  left join public.payments p on p.id = rs.payment_id
  where rs.id = p_submission_id;

  if v_result is null then
    raise exception 'Loan repayment submission not found';
  end if;

  return v_result || jsonb_build_object('actor', v_actor);
end;
$$;

revoke all on function public.get_admin_loan_repayment_detail_v3(uuid) from public, anon;
grant execute on function public.get_admin_loan_repayment_detail_v3(uuid) to authenticated;

commit;
