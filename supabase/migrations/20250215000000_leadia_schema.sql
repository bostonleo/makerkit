-- Leadia MVP: narratives, versions, evaluations, clarifying Q&A, resume uploads, payments
-- Keep existing users/tasks; add Leadia tables.

create type narrative_status as enum ('in_progress', 'ready', 'finalized');
create type evaluation_source as enum ('generated', 'user_edited');

create table if not exists public.narratives (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  purchase_id uuid,
  status narrative_status not null default 'in_progress',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.narrative_versions (
  id uuid primary key default gen_random_uuid(),
  narrative_id uuid not null references public.narratives(id) on delete cascade,
  content text not null,
  version_number int not null default 1,
  created_at timestamptz not null default now()
);

create table if not exists public.evaluation_runs (
  id uuid primary key default gen_random_uuid(),
  narrative_version_id uuid not null references public.narrative_versions(id) on delete cascade,
  completeness int not null,
  causality int not null,
  reflection int not null,
  authenticity int not null,
  narrative_flow int not null,
  passed boolean not null,
  source evaluation_source not null default 'generated',
  created_at timestamptz not null default now()
);

create table if not exists public.clarifying_questions (
  id uuid primary key default gen_random_uuid(),
  narrative_version_id uuid not null references public.narrative_versions(id) on delete cascade,
  question_text text not null,
  target_parameter text,
  created_at timestamptz not null default now()
);

create table if not exists public.clarifying_answers (
  id uuid primary key default gen_random_uuid(),
  clarifying_question_id uuid not null references public.clarifying_questions(id) on delete cascade,
  answer_text text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.resume_uploads (
  id uuid primary key default gen_random_uuid(),
  narrative_id uuid not null references public.narratives(id) on delete cascade,
  file_key text not null,
  extracted_text text,
  created_at timestamptz not null default now()
);

create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  stripe_payment_id text unique,
  amount_cents int,
  narrative_credits int not null default 1,
  created_at timestamptz not null default now()
);

-- RLS
alter table public.narratives enable row level security;
alter table public.narrative_versions enable row level security;
alter table public.evaluation_runs enable row level security;
alter table public.clarifying_questions enable row level security;
alter table public.clarifying_answers enable row level security;
alter table public.resume_uploads enable row level security;
alter table public.payments enable row level security;

create policy "Users can manage own narratives"
  on public.narratives for all using (auth.uid() = user_id);

create policy "Users can manage narrative_versions of own narratives"
  on public.narrative_versions for all
  using (exists (select 1 from public.narratives n where n.id = narrative_id and n.user_id = auth.uid()));

create policy "Users can read evaluation_runs of own narratives"
  on public.evaluation_runs for select
  using (exists (
    select 1 from public.narrative_versions nv
    join public.narratives n on n.id = nv.narrative_id
    where nv.id = narrative_version_id and n.user_id = auth.uid()
  ));

create policy "Users can manage clarifying_questions of own narratives"
  on public.clarifying_questions for all
  using (exists (
    select 1 from public.narrative_versions nv
    join public.narratives n on n.id = nv.narrative_id
    where nv.id = narrative_version_id and n.user_id = auth.uid()
  ));

create policy "Users can manage clarifying_answers for own questions"
  on public.clarifying_answers for all
  using (exists (
    select 1 from public.clarifying_questions cq
    join public.narrative_versions nv on nv.id = cq.narrative_version_id
    join public.narratives n on n.id = nv.narrative_id
    where cq.id = clarifying_question_id and n.user_id = auth.uid()
  ));

create policy "Users can manage resume_uploads of own narratives"
  on public.resume_uploads for all
  using (exists (select 1 from public.narratives n where n.id = narrative_id and n.user_id = auth.uid()));

create policy "Users can read own payments"
  on public.payments for select using (auth.uid() = user_id);
create policy "Service role can insert payments"
  on public.payments for insert with check (true);

-- Storage bucket for resumes (run in Supabase dashboard or via API if needed)
-- insert into storage.buckets (id, name, public) values ('resumes', 'resumes', false);
-- storage policies: allow insert/select when narrative belongs to auth.uid()
