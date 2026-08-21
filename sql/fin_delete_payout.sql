-- 이체요청 삭제 함수: 본인이 작성한 건만, 지급완료(paid) 제외
-- 사용법: Supabase 대시보드 → SQL Editor → 붙여넣기 → Run
create or replace function public.fin_delete_payout(p_id text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v jsonb;
  v_email text := lower(coalesce(auth.jwt()->>'email',''));
  v_req_email text;
begin
  select to_jsonb(t) into v from public.fin_payouts t where t.id::text = p_id;
  if v is null then
    raise exception '요청을 찾을 수 없어요.';
  end if;
  if coalesce(v->>'status','') = 'paid' then
    raise exception '지급완료된 건은 삭제할 수 없어요.';
  end if;
  v_req_email := lower(coalesce(v->>'requester_email',''));
  if v_email = '' or v_req_email = '' or v_req_email <> v_email then
    raise exception '본인이 작성한 요청만 삭제할 수 있어요.';
  end if;
  delete from public.fin_payouts where id::text = p_id;
end $$;

revoke all on function public.fin_delete_payout(text) from public;
grant execute on function public.fin_delete_payout(text) to authenticated;
