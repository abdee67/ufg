begin;

/* Private evidence storage for member loan-repayment submissions. The Flutter
   client writes only to loan_payments/{auth.uid()}/..., never to a public URL. */
insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'payment-proofs',
  'payment-proofs',
  false,
  10485760,
  array[
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/webp',
    'application/pdf'
  ]
)
on conflict (id) do update set
  public=false,
  file_size_limit=10485760,
  allowed_mime_types=array[
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/webp',
    'application/pdf'
  ];

drop policy if exists "loan_payment_proofs_insert_own" on storage.objects;
create policy "loan_payment_proofs_insert_own"
on storage.objects for insert
to authenticated
with check (
  bucket_id='payment-proofs'
  and (storage.foldername(name))[1]='loan_payments'
  and (storage.foldername(name))[2]=auth.uid()::text
);

drop policy if exists "loan_payment_proofs_select_own_or_admin" on storage.objects;
create policy "loan_payment_proofs_select_own_or_admin"
on storage.objects for select
to authenticated
using (
  bucket_id='payment-proofs'
  and (
    (storage.foldername(name))[1]='loan_payments'
    and (storage.foldername(name))[2]=auth.uid()::text
    or private.current_user_is_admin()
  )
);

commit;
