begin;

/*
  PostgreSQL CTEs are scoped to a single statement. V3 queue RPCs calculated a
  total from `q` and then attempted to paginate from `q` in a second statement.
  Rebuild the installed function definitions by duplicating each queue CTE for
  its pagination statement. pg_get_functiondef preserves the established
  signatures, grants, security-definer settings, and query bodies.
*/
do $fix_admin_loan_queue_scope$
declare
  v_function oid;
  v_definition text;
  v_cte text;
  v_cte_start integer;
  v_count_start integer;
  v_rows_start integer;
  v_count_marker constant text := '  select count(*) into v_total from q;';
  v_rows_marker constant text := '  select coalesce(';
  v_repaired integer := 0;
begin
  for v_function in
    select p.oid
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname = any (array[
        'list_admin_guarantor_requests_v3',
        'list_admin_approval_queue_v3',
        'list_admin_disbursement_queue_v3',
        'list_admin_active_loans_v3',
        'list_admin_loan_repayments_v3',
        'list_admin_overdue_loans_v3',
        'list_admin_default_cases_v3',
        'list_admin_recovery_events_v3',
        'list_admin_loan_extensions_v3',
        'list_admin_guarantor_replacements_v3',
        'list_admin_loan_transactions_v3',
        'list_admin_loan_audit_v3'
      ])
  loop
    v_definition := pg_get_functiondef(v_function);
    v_cte_start := position('  with ' in v_definition);
    v_count_start := position(v_count_marker in v_definition);
    v_rows_start := position(
      v_rows_marker in substring(v_definition from v_count_start + char_length(v_count_marker))
    );

    if v_cte_start = 0 or v_count_start = 0 or v_rows_start = 0 then
      raise exception 'Unexpected queue function definition for %; refusing an unsafe rewrite', v_function::regprocedure;
    end if;

    v_cte := substring(v_definition from v_cte_start for v_count_start - v_cte_start);
    v_rows_start := v_count_start + char_length(v_count_marker) + v_rows_start - 1;
    v_definition := overlay(v_definition placing v_cte from v_rows_start for 0);
    execute v_definition;
    v_repaired := v_repaired + 1;
  end loop;

  if v_repaired <> 12 then
    raise exception 'Expected to repair 12 admin loan queue RPCs, repaired %', v_repaired;
  end if;
end;
$fix_admin_loan_queue_scope$;

commit;
