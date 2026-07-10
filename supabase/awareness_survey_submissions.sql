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
  add column if not exists playtest_feedback text,
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
    average_change, client_saved_at, game_completed, game_rest_attempts,
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

alter table public.awareness_survey_submissions enable row level security;

drop policy if exists "Allow anonymous survey inserts" on public.awareness_survey_submissions;
drop policy if exists "Allow anonymous survey upserts" on public.awareness_survey_submissions;
drop policy if exists "Allow anonymous survey updates" on public.awareness_survey_submissions;

create policy "Allow anonymous survey upserts"
on public.awareness_survey_submissions
for insert
to anon
with check (true);

create policy "Allow anonymous survey updates"
on public.awareness_survey_submissions
for update
to anon
using (true)
with check (true);

grant insert, update on public.awareness_survey_submissions to anon;
