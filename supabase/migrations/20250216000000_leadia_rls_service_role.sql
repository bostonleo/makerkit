-- Allow backend (service_role key) to manage Leadia tables when RLS is evaluated.
-- auth.role() = 'service_role' when the request uses the service_role API key.
-- If you still get RLS errors, ensure backend .env uses SUPABASE_SERVICE_ROLE_KEY (not the anon key).

create policy "Service role can manage narratives"
  on public.narratives for all using (auth.role() = 'service_role') with check (auth.role() = 'service_role');

create policy "Service role can manage narrative_versions"
  on public.narrative_versions for all using (auth.role() = 'service_role') with check (auth.role() = 'service_role');

create policy "Service role can manage evaluation_runs"
  on public.evaluation_runs for all using (auth.role() = 'service_role') with check (auth.role() = 'service_role');

create policy "Service role can manage clarifying_questions"
  on public.clarifying_questions for all using (auth.role() = 'service_role') with check (auth.role() = 'service_role');

create policy "Service role can manage clarifying_answers"
  on public.clarifying_answers for all using (auth.role() = 'service_role') with check (auth.role() = 'service_role');

create policy "Service role can manage resume_uploads"
  on public.resume_uploads for all using (auth.role() = 'service_role') with check (auth.role() = 'service_role');

create policy "Service role can manage payments"
  on public.payments for all using (auth.role() = 'service_role') with check (auth.role() = 'service_role');
