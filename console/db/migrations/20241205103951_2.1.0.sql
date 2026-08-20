-- +goose Up
-- Postgres versions
insert into public.postgres_versions (major_version, release_date, end_of_life)
  values (17, '2024-09-26', '2029-11-08');


-- +goose Down
delete from public.postgres_versions
where major_version = 17;
