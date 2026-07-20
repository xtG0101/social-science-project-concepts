create table if not exists public.awareness_survey_submissions (
  id uuid primary key default gen_random_uuid(),
  session_id text not null unique,
  phase text check (phase in ('pre', 'post')),
  q1 integer check (q1 between 1 and 5),
  q2 integer check (q2 between 1 and 5),
  q3 integer check (q3 between 1 and 5),
  q4 integer check (q4 between 1 and 5),
  q5 integer check (q5 between 1 and 5),
  average_score numeric(4, 2),
  age_group text,
  gender text,
  family_status text,
  pre_q1 integer check (pre_q1 between 1 and 5),
  pre_q2 integer check (pre_q2 between 1 and 5),
  pre_q3 integer check (pre_q3 between 1 and 5),
  pre_q4 integer check (pre_q4 between 1 and 5),
  pre_q5 integer check (pre_q5 between 1 and 5),
  pre_average_score numeric(4, 2),
  post_q1 integer check (post_q1 between 1 and 5),
  post_q2 integer check (post_q2 between 1 and 5),
  post_q3 integer check (post_q3 between 1 and 5),
  post_q4 integer check (post_q4 between 1 and 5),
  post_q5 integer check (post_q5 between 1 and 5),
  post_average_score numeric(4, 2),
  average_change numeric(4, 2),
  playtest_feedback text,
  game_completed integer,
  game_rest_attempts integer,
  game_interruptions integer,
  game_fatigue integer,
  game_child integer,
  game_boss integer,
  game_parent_relationship integer,
  pre_saved_at text,
  post_saved_at text,
  client_saved_at text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.awareness_survey_submissions
  add column if not exists age_group text,
  add column if not exists gender text,
  add column if not exists family_status text,
  add column if not exists pre_q1 integer check (pre_q1 between 1 and 5),
  add column if not exists pre_q2 integer check (pre_q2 between 1 and 5),
  add column if not exists pre_q3 integer check (pre_q3 between 1 and 5),
  add column if not exists pre_q4 integer check (pre_q4 between 1 and 5),
  add column if not exists pre_q5 integer check (pre_q5 between 1 and 5),
  add column if not exists pre_average_score numeric(4, 2),
  add column if not exists post_q1 integer check (post_q1 between 1 and 5),
  add column if not exists post_q2 integer check (post_q2 between 1 and 5),
  add column if not exists post_q3 integer check (post_q3 between 1 and 5),
  add column if not exists post_q4 integer check (post_q4 between 1 and 5),
  add column if not exists post_q5 integer check (post_q5 between 1 and 5),
  add column if not exists post_average_score numeric(4, 2),
  add column if not exists average_change numeric(4, 2),
  add column if not exists playtest_feedback text,
  add column if not exists game_completed integer,
  add column if not exists game_rest_attempts integer,
  add column if not exists game_interruptions integer,
  add column if not exists game_fatigue integer,
  add column if not exists game_child integer,
  add column if not exists pre_saved_at text,
  add column if not exists post_saved_at text,
  add column if not exists updated_at timestamptz not null default now();

alter table public.awareness_survey_submissions
  add column if not exists game_boss integer,
  add column if not exists game_parent_relationship integer;

alter table public.awareness_survey_submissions
  alter column phase drop not null,
  alter column q1 drop not null,
  alter column q2 drop not null,
  alter column q3 drop not null,
  alter column q4 drop not null,
  alter column q5 drop not null,
  alter column average_score drop not null;

update public.awareness_survey_submissions target
set
  pre_q1 = source.q1,
  pre_q2 = source.q2,
  pre_q3 = source.q3,
  pre_q4 = source.q4,
  pre_q5 = source.q5,
  pre_average_score = coalesce(source.pre_average_score, source.average_score),
  pre_saved_at = coalesce(source.client_saved_at, target.pre_saved_at)
from (
  select distinct on (session_id)
    session_id, q1, q2, q3, q4, q5, average_score, pre_average_score, client_saved_at
  from public.awareness_survey_submissions
  where phase = 'pre'
  order by session_id, created_at desc
) source
where target.session_id = source.session_id;

update public.awareness_survey_submissions target
set
  post_q1 = source.q1,
  post_q2 = source.q2,
  post_q3 = source.q3,
  post_q4 = source.q4,
  post_q5 = source.q5,
  post_average_score = coalesce(source.post_average_score, source.average_score),
  average_change = source.average_change,
  playtest_feedback = source.playtest_feedback,
  post_saved_at = coalesce(source.client_saved_at, target.post_saved_at),
  game_completed = source.game_completed,
  game_rest_attempts = source.game_rest_attempts,
  game_interruptions = source.game_interruptions,
  game_fatigue = source.game_fatigue,
  game_child = source.game_child,
  game_boss = source.game_boss,
  game_parent_relationship = source.game_parent_relationship
from (
  select distinct on (session_id)
    session_id, q1, q2, q3, q4, q5, average_score, post_average_score,
    average_change, playtest_feedback, client_saved_at, game_completed, game_rest_attempts,
    game_interruptions, game_fatigue, game_child, game_boss, game_parent_relationship
  from public.awareness_survey_submissions
  where phase = 'post'
  order by session_id, created_at desc
) source
where target.session_id = source.session_id;

with keepers as (
  select distinct on (session_id) id
  from public.awareness_survey_submissions
  order by session_id, created_at asc
)
delete from public.awareness_survey_submissions
where id not in (select id from keepers);

create unique index if not exists awareness_survey_submissions_session_id_key
on public.awareness_survey_submissions (session_id);

alter table public.awareness_survey_submissions
  drop column if exists game_self;

create or replace function public.submit_awareness_survey(p_payload jsonb)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if nullif(p_payload->>'session_id', '') is null then
    raise exception 'session_id is required';
  end if;

  insert into public.awareness_survey_submissions (
    session_id,
    phase,
    q1,
    q2,
    q3,
    q4,
    q5,
    average_score,
    age_group,
    gender,
    family_status,
    pre_q1,
    pre_q2,
    pre_q3,
    pre_q4,
    pre_q5,
    pre_average_score,
    post_q1,
    post_q2,
    post_q3,
    post_q4,
    post_q5,
    post_average_score,
    average_change,
    playtest_feedback,
    game_completed,
    game_rest_attempts,
    game_interruptions,
    game_fatigue,
    game_child,
    game_boss,
    game_parent_relationship,
    pre_saved_at,
    post_saved_at,
    client_saved_at,
    updated_at
  )
  values (
    p_payload->>'session_id',
    nullif(p_payload->>'phase', ''),
    nullif(p_payload->>'q1', '')::integer,
    nullif(p_payload->>'q2', '')::integer,
    nullif(p_payload->>'q3', '')::integer,
    nullif(p_payload->>'q4', '')::integer,
    nullif(p_payload->>'q5', '')::integer,
    nullif(p_payload->>'average_score', '')::numeric(4, 2),
    nullif(p_payload->>'age_group', ''),
    nullif(p_payload->>'gender', ''),
    nullif(p_payload->>'family_status', ''),
    nullif(p_payload->>'pre_q1', '')::integer,
    nullif(p_payload->>'pre_q2', '')::integer,
    nullif(p_payload->>'pre_q3', '')::integer,
    nullif(p_payload->>'pre_q4', '')::integer,
    nullif(p_payload->>'pre_q5', '')::integer,
    nullif(p_payload->>'pre_average_score', '')::numeric(4, 2),
    nullif(p_payload->>'post_q1', '')::integer,
    nullif(p_payload->>'post_q2', '')::integer,
    nullif(p_payload->>'post_q3', '')::integer,
    nullif(p_payload->>'post_q4', '')::integer,
    nullif(p_payload->>'post_q5', '')::integer,
    nullif(p_payload->>'post_average_score', '')::numeric(4, 2),
    nullif(p_payload->>'average_change', '')::numeric(4, 2),
    nullif(p_payload->>'playtest_feedback', ''),
    nullif(p_payload->>'game_completed', '')::integer,
    nullif(p_payload->>'game_rest_attempts', '')::integer,
    nullif(p_payload->>'game_interruptions', '')::integer,
    nullif(p_payload->>'game_fatigue', '')::integer,
    nullif(p_payload->>'game_child', '')::integer,
    nullif(p_payload->>'game_boss', '')::integer,
    nullif(p_payload->>'game_parent_relationship', '')::integer,
    nullif(p_payload->>'pre_saved_at', ''),
    nullif(p_payload->>'post_saved_at', ''),
    nullif(p_payload->>'client_saved_at', ''),
    coalesce(nullif(p_payload->>'updated_at', '')::timestamptz, now())
  )
  on conflict (session_id) do update set
    phase = coalesce(excluded.phase, awareness_survey_submissions.phase),
    q1 = coalesce(excluded.q1, awareness_survey_submissions.q1),
    q2 = coalesce(excluded.q2, awareness_survey_submissions.q2),
    q3 = coalesce(excluded.q3, awareness_survey_submissions.q3),
    q4 = coalesce(excluded.q4, awareness_survey_submissions.q4),
    q5 = coalesce(excluded.q5, awareness_survey_submissions.q5),
    average_score = coalesce(excluded.average_score, awareness_survey_submissions.average_score),
    age_group = coalesce(excluded.age_group, awareness_survey_submissions.age_group),
    gender = coalesce(excluded.gender, awareness_survey_submissions.gender),
    family_status = coalesce(excluded.family_status, awareness_survey_submissions.family_status),
    pre_q1 = coalesce(excluded.pre_q1, awareness_survey_submissions.pre_q1),
    pre_q2 = coalesce(excluded.pre_q2, awareness_survey_submissions.pre_q2),
    pre_q3 = coalesce(excluded.pre_q3, awareness_survey_submissions.pre_q3),
    pre_q4 = coalesce(excluded.pre_q4, awareness_survey_submissions.pre_q4),
    pre_q5 = coalesce(excluded.pre_q5, awareness_survey_submissions.pre_q5),
    pre_average_score = coalesce(excluded.pre_average_score, awareness_survey_submissions.pre_average_score),
    post_q1 = coalesce(excluded.post_q1, awareness_survey_submissions.post_q1),
    post_q2 = coalesce(excluded.post_q2, awareness_survey_submissions.post_q2),
    post_q3 = coalesce(excluded.post_q3, awareness_survey_submissions.post_q3),
    post_q4 = coalesce(excluded.post_q4, awareness_survey_submissions.post_q4),
    post_q5 = coalesce(excluded.post_q5, awareness_survey_submissions.post_q5),
    post_average_score = coalesce(excluded.post_average_score, awareness_survey_submissions.post_average_score),
    average_change = coalesce(excluded.average_change, awareness_survey_submissions.average_change),
    playtest_feedback = coalesce(excluded.playtest_feedback, awareness_survey_submissions.playtest_feedback),
    game_completed = coalesce(excluded.game_completed, awareness_survey_submissions.game_completed),
    game_rest_attempts = coalesce(excluded.game_rest_attempts, awareness_survey_submissions.game_rest_attempts),
    game_interruptions = coalesce(excluded.game_interruptions, awareness_survey_submissions.game_interruptions),
    game_fatigue = coalesce(excluded.game_fatigue, awareness_survey_submissions.game_fatigue),
    game_child = coalesce(excluded.game_child, awareness_survey_submissions.game_child),
    game_boss = coalesce(excluded.game_boss, awareness_survey_submissions.game_boss),
    game_parent_relationship = coalesce(excluded.game_parent_relationship, awareness_survey_submissions.game_parent_relationship),
    pre_saved_at = coalesce(excluded.pre_saved_at, awareness_survey_submissions.pre_saved_at),
    post_saved_at = coalesce(excluded.post_saved_at, awareness_survey_submissions.post_saved_at),
    client_saved_at = coalesce(excluded.client_saved_at, awareness_survey_submissions.client_saved_at),
    updated_at = now();
end;
$$;

revoke all on function public.submit_awareness_survey(jsonb) from public;
grant execute on function public.submit_awareness_survey(jsonb) to anon, authenticated;

alter table public.awareness_survey_submissions enable row level security;

drop policy if exists "Allow anonymous survey inserts" on public.awareness_survey_submissions;
drop policy if exists "Allow anonymous survey upserts" on public.awareness_survey_submissions;
drop policy if exists "Allow anonymous survey updates" on public.awareness_survey_submissions;
drop policy if exists "Allow anonymous survey reads for updates" on public.awareness_survey_submissions;

create policy "Allow anonymous survey upserts"
on public.awareness_survey_submissions
for insert
to anon, authenticated
with check (true);

create policy "Allow anonymous survey reads for updates"
on public.awareness_survey_submissions
for select
to anon, authenticated
using (true);

create policy "Allow anonymous survey updates"
on public.awareness_survey_submissions
for update
to anon, authenticated
using (true)
with check (true);

grant usage on schema public to anon, authenticated;
grant select, insert, update on public.awareness_survey_submissions to anon, authenticated;

notify pgrst, 'reload schema';
