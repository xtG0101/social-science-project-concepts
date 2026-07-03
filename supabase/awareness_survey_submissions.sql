create table if not exists public.awareness_survey_submissions (
  id uuid primary key default gen_random_uuid(),
  session_id text not null,
  phase text not null check (phase in ('pre', 'post')),
  q1 integer not null check (q1 between 1 and 5),
  q2 integer not null check (q2 between 1 and 5),
  q3 integer not null check (q3 between 1 and 5),
  q4 integer not null check (q4 between 1 and 5),
  q5 integer not null check (q5 between 1 and 5),
  average_score numeric(4, 2) not null,
  pre_average_score numeric(4, 2),
  post_average_score numeric(4, 2),
  average_change numeric(4, 2),
  game_completed integer,
  game_rest_attempts integer,
  game_interruptions integer,
  game_fatigue integer,
  game_child integer,
  game_boss integer,
  game_parent_relationship integer,
  client_saved_at text,
  created_at timestamptz not null default now()
);

alter table public.awareness_survey_submissions
  add column if not exists game_boss integer;

alter table public.awareness_survey_submissions
  add column if not exists game_parent_relationship integer;

alter table public.awareness_survey_submissions
  drop column if exists game_self;

alter table public.awareness_survey_submissions enable row level security;

drop policy if exists "Allow anonymous survey inserts" on public.awareness_survey_submissions;

create policy "Allow anonymous survey inserts"
on public.awareness_survey_submissions
for insert
to anon
with check (true);

grant insert on public.awareness_survey_submissions to anon;
