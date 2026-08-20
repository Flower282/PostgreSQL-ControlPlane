-- +goose Up
-- Create extensions
create schema if not exists extensions;

create extension if not exists moddatetime schema extensions;

create extension if not exists pgcrypto schema extensions;


-- Projects
create table public.projects (
  project_id bigserial primary key,
  project_name varchar(50) not null unique,
  project_description varchar(150),
  created_at timestamp default current_timestamp,
  updated_at timestamp
);

comment on table public.projects is 'Table containing information about projects';

comment on column public.projects.project_name is 'The name of the project';

comment on column public.projects.project_description is 'A description of the project';

comment on column public.projects.created_at is 'The timestamp when the project was created';

comment on column public.projects.updated_at is 'The timestamp when the project was last updated';

create trigger handle_updated_at
  before update on public.projects for each row
  execute function extensions.moddatetime (updated_at);

insert into public.projects (project_name)
  values ('default');

-- Environments
create table public.environments (
  environment_id bigserial primary key,
  environment_name varchar(20) not null,
  environment_description text,
  created_at timestamp default current_timestamp,
  updated_at timestamp
);

comment on table public.environments is 'Table containing information about environments';

comment on column public.environments.environment_name is 'The name of the environment';

comment on column public.environments.environment_description is 'A description of the environment';

comment on column public.environments.created_at is 'The timestamp when the environment was created';

comment on column public.environments.updated_at is 'The timestamp when the environment was last updated';

create trigger handle_updated_at
  before update on public.environments for each row
  execute function extensions.moddatetime (updated_at);

create index environments_name_idx on public.environments (environment_name);

insert into public.environments (environment_name)
  values ('production');

insert into public.environments (environment_name)
  values ('staging');

insert into public.environments (environment_name)
  values ('test');

insert into public.environments (environment_name)
  values ('dev');

insert into public.environments (environment_name)
  values ('benchmarking');

-- Secrets
create table public.secrets (
  secret_id bigserial primary key,
  project_id bigint references public.projects (project_id),
  secret_type text not null,
  secret_name text not null unique,
  secret_value bytea not null, -- Encrypted data
  created_at timestamp default current_timestamp,
  updated_at timestamp
);

comment on table public.secrets is 'Table containing secrets for accessing cloud providers and servers';

comment on column public.secrets.project_id is 'The ID of the project to which the secret belongs';

comment on column public.secrets.secret_type is 'The type of the secret (e.g., cloud_secret, ssh_key, password)';

comment on column public.secrets.secret_name is 'The name of the secret';

comment on column public.secrets.secret_value is 'The encrypted value of the secret';

comment on column public.secrets.created_at is 'The timestamp when the secret was created';

comment on column public.secrets.updated_at is 'The timestamp when the secret was last updated';

create trigger handle_updated_at
  before update on public.secrets for each row
  execute function extensions.moddatetime (updated_at);

create index secrets_type_name_idx on public.secrets (secret_type, secret_name);

create index secrets_id_project_idx on public.secrets (secret_id, project_id);

create index secrets_project_idx on public.secrets (project_id);

-- +goose StatementBegin
create or replace function add_secret (p_project_id bigint, p_secret_type text, p_secret_name text, p_secret_value json, p_encryption_key text)
  returns bigint
  as $$
declare
  v_inserted_secret_id bigint;
begin
  insert into public.secrets (project_id, secret_type, secret_name, secret_value)
    values (p_project_id, p_secret_type, p_secret_name, extensions.pgp_sym_encrypt(p_secret_value::text, p_encryption_key, 'cipher-algo=aes256'))
  returning
    secret_id into v_inserted_secret_id;
  return v_inserted_secret_id;
end;
$$
language plpgsql;
-- +goose StatementEnd

-- +goose StatementBegin
create or replace function update_secret (p_secret_id bigint, p_secret_type text default null, p_secret_name text default null, p_secret_value json default
  null, p_encryption_key text default null)
  returns table (
    project_id bigint,
    secret_id bigint,
    secret_type text,
    secret_name text,
    created_at timestamp,
    updated_at timestamp,
    used boolean,
    used_by_clusters text,
    used_by_servers text
  )
  as $$
begin
  if p_secret_value is not null and p_encryption_key is null then
    raise exception 'Encryption key must be provided when updating secret value';
  end if;
  update
    public.secrets
  set
    secret_name = coalesce(p_secret_name, public.secrets.secret_name),
    secret_type = coalesce(p_secret_type, public.secrets.secret_type),
    secret_value = case when p_secret_value is not null then
      extensions.pgp_sym_encrypt(p_secret_value::text, p_encryption_key, 'cipher-algo=aes256')
    else
      public.secrets.secret_value
    end
  where
    public.secrets.secret_id = p_secret_id;
  return QUERY
  select
    s.project_id,
    s.secret_id,
    s.secret_type,
    s.secret_name,
    s.created_at,
    s.updated_at,
    s.used,
    s.used_by_clusters,
    s.used_by_servers
  from
    public.v_secrets_list s
  where
    s.secret_id = p_secret_id;
end;
$$
language plpgsql;
-- +goose StatementEnd

-- +goose StatementBegin
create or replace function get_secret (p_secret_id bigint, p_encryption_key text)
  returns json
  as $$
declare
  decrypted_value json;
begin
  select
    extensions.pgp_sym_decrypt(secret_value, p_encryption_key)::json into decrypted_value
  from
    public.secrets
  where
    secret_id = p_secret_id;
  return decrypted_value;
end;
$$
language plpgsql;
-- +goose StatementEnd

-- An example of using a function to insert a secret (value in JSON format)
-- select add_secret(<project_id>, 'ssh_key', '<secret_name>', '{"private_key": "<CONTENT>"}', '<encryption_key>');
-- select add_secret(<project_id>, 'password', '<secret_name>', '{"username": "<CONTENT>", "password": "<CONTENT>"}', '<encryption_key>');
-- select add_secret(<project_id>, 'aws', '<secret_name>', '{"AWS_ACCESS_KEY_ID": "<CONTENT>", "AWS_SECRET_ACCESS_KEY": "<CONTENT>"}', '<encryption_key>');
-- An example of using the function to update a secret
-- select update_secret(<secret_id>, '<new_secret_type>', '<new_secret_name>', '<new_secret_value>', '<encryption_key>');
-- An example of using a function to get a secret
-- select get_secret(<secret_id>, '<encryption_key>');

-- Clusters
create table public.clusters (
  cluster_id bigserial primary key,
  project_id bigint references public.projects (project_id),
  environment_id bigint references public.environments (environment_id),
  secret_id bigint references public.secrets (secret_id),
  cluster_name text not null unique,
  cluster_status text default 'deploying',
  cluster_description text,
  cluster_location text,
  connection_info jsonb,
  extra_vars jsonb,
  inventory jsonb,
  server_count integer default 0,
  postgres_version integer,
  created_at timestamp default current_timestamp,
  updated_at timestamp,
  deleted_at timestamp,
  flags integer default 0
);

comment on table public.clusters is 'Table containing information about Postgres clusters';

comment on column public.clusters.project_id is 'The ID of the project to which the cluster belongs';

comment on column public.clusters.environment_id is 'The environment in which the cluster is deployed (e.g., production, development, etc)';

comment on column public.clusters.cluster_name is 'The name of the cluster (it must be unique)';

comment on column public.clusters.cluster_status is 'The status of the cluster (e.q., deploying, failed, healthy, unhealthy, degraded)';

comment on column public.clusters.cluster_description is 'A description of the cluster (optional)';

comment on column public.clusters.connection_info is 'The cluster connection info';

comment on column public.clusters.extra_vars is 'Extra variables for Ansible specific to this cluster';

comment on column public.clusters.inventory is 'The Ansible inventory for this cluster';

comment on column public.clusters.cluster_location is 'The region/datacenter where the cluster is located';

comment on column public.clusters.server_count is 'The number of servers associated with the cluster';

comment on column public.clusters.postgres_version is 'The Postgres major version';

comment on column public.clusters.secret_id is 'The ID of the secret for accessing the cloud provider';

comment on column public.clusters.created_at is 'The timestamp when the cluster was created';

comment on column public.clusters.updated_at is 'The timestamp when the cluster was last updated';

comment on column public.clusters.deleted_at is 'The timestamp when the cluster was (soft) deleted';

comment on column public.clusters.flags is 'Bitmask field for storing various status flags related to the cluster';

create trigger handle_updated_at
  before update on public.clusters for each row
  execute function extensions.moddatetime (updated_at);

create index clusters_id_project_id_idx on public.clusters (cluster_id, project_id);

create index clusters_project_idx on public.clusters (project_id);

create index clusters_environment_idx on public.clusters (environment_id);

create index clusters_name_idx on public.clusters (cluster_name);

create index clusters_secret_id_idx on public.clusters (secret_id);

-- +goose StatementBegin
create or replace function get_cluster_name ()
  returns text
  as $$
declare
  new_name text;
  counter int := 1;
begin
  loop
    new_name := 'postgres-cluster-' || to_char(counter, 'FM00');
    -- Check if such a cluster name already exists
    if not exists (
      select
        1
      from
        public.clusters
      where
        cluster_name = new_name) then
    return new_name;
  end if;
  counter := counter + 1;
end loop;
end;
$$
language plpgsql;
-- +goose StatementEnd

-- Servers
create table public.servers (
  server_id bigserial primary key,
  cluster_id bigint references public.clusters (cluster_id),
  server_name text not null,
  server_location text,
  server_role text default 'N/A',
  server_status text default 'N/A',
  ip_address inet not null,
  timeline bigint,
  lag bigint,
  tags jsonb,
  pending_restart boolean default false,
  created_at timestamp default current_timestamp,
  updated_at timestamp
);

comment on table public.servers is 'Table containing information about servers within a Postgres cluster';

comment on column public.servers.cluster_id is 'The ID of the cluster to which the server belongs';

comment on column public.servers.server_name is 'The name of the server';

comment on column public.servers.server_location is 'The region/datacenter where the server is located';

comment on column public.servers.server_role is 'The role of the server (e.g., primary, replica)';

comment on column public.servers.server_status is 'The current status of the server';

comment on column public.servers.ip_address is 'The IP address of the server';

comment on column public.servers.timeline is 'The timeline of the Postgres';

comment on column public.servers.lag is 'The lag in MB of the Postgres';

comment on column public.servers.tags is 'The tags associated with the server';

comment on column public.servers.pending_restart is 'Indicates whether a restart is pending for the Postgres';

comment on column public.servers.created_at is 'The timestamp when the server was created';

comment on column public.servers.updated_at is 'The timestamp when the server was last updated';

create trigger handle_updated_at
  before update on public.servers for each row
  execute function extensions.moddatetime (updated_at);

create unique index servers_cluster_id_ip_address_idx on public.servers (cluster_id, ip_address);

-- +goose StatementBegin
create or replace function update_server_count ()
  returns trigger
  as $$
begin
  update
    public.clusters
  set
    server_count = (
      select
        count(*)
      from
        public.servers
      where
        public.servers.cluster_id = new.cluster_id)
  where
    cluster_id = new.cluster_id;
  return NEW;
end;
$$
language plpgsql;
-- +goose StatementEnd

-- Trigger to update server_count on changes in servers
create trigger update_server_count_trigger
  after insert or update or delete on public.servers for each row
  execute function update_server_count ();

-- Secrets view
create view public.v_secrets_list as
select
  s.project_id,
  s.secret_id,
  s.secret_name,
  s.secret_type,
  s.created_at,
  s.updated_at,
  case when count(c.secret_id) > 0 then
    true
  else
    false
  end as used,
  coalesce(string_agg(distinct c.cluster_name, ', '), '') as used_by_clusters
from
  public.secrets s
  left join lateral (
    select
      cluster_name,
      secret_id
    from
      public.clusters
    where
      secret_id = s.secret_id
      and project_id = s.project_id) c on true
group by
  s.project_id,
  s.secret_id,
  s.secret_name,
  s.secret_type,
  s.created_at,
  s.updated_at;


-- Operations
create table public.operations (
  id bigserial,
  project_id bigint references public.projects (project_id),
  cluster_id bigint references public.clusters (cluster_id),
  docker_code varchar(80) not null,
  cid uuid,
  operation_type text not null,
  operation_status text not null check (operation_status in ('in_progress', 'success', 'failed')),
  operation_log text,
  created_at timestamp with time zone default current_timestamp,
  updated_at timestamp with time zone
);

comment on table public.operations is 'Table containing logs of operations performed on clusters';

comment on column public.operations.id is 'The ID of the operation from the backend';

comment on column public.clusters.project_id is 'The ID of the project to which the operation belongs';

comment on column public.operations.cluster_id is 'The ID of the cluster related to the operation';

comment on column public.operations.docker_code is 'The CODE of the operation related to the docker daemon';

comment on column public.operations.cid is 'The correlation_id related to the operation';

comment on column public.operations.operation_type is 'The type of operation performed (e.g., deploy, edit, update, restart, delete, etc.)';

comment on column public.operations.operation_status is 'The status of the operation (in_progress, success, failed)';

comment on column public.operations.operation_log is 'The log details of the operation';

comment on column public.operations.created_at is 'The timestamp when the operation was created';

comment on column public.operations.updated_at is 'The timestamp when the operation was last updated';

create trigger handle_updated_at
  before update on public.operations for each row
  execute function extensions.moddatetime (updated_at);

-- add created_at as part of the primary key to be able to create a hypertable
alter table only public.operations
  add constraint operations_pkey primary key (created_at, id);

create index operations_project_id_idx on public.operations (project_id);

create index operations_cluster_id_idx on public.operations (cluster_id);

create index operations_project_cluster_id_idx on public.operations (project_id, cluster_id, created_at);

create index operations_project_cluster_id_operation_type_idx on public.operations (project_id, cluster_id, operation_type, created_at);

-- Check if the timescaledb extension is available and create hypertable if it is
-- +goose StatementBegin
do $$
begin
  if exists (
    select
      1
    from
      pg_extension
    where
      extname = 'timescaledb') then
  -- Convert the operations table to a hypertable
  perform
    create_hypertable ('public.operations', 'created_at', chunk_time_interval => interval '1 month');
  -- Check if the license allows compression policy
  if current_setting('timescaledb.license', true) = 'timescale' then
    -- Enable compression on the operations hypertable, segmenting by project_id and cluster_id
    alter table public.operations set (timescaledb.compress, timescaledb.compress_orderby = 'created_at desc, id desc, operation_type, operation_status', timescaledb.compress_segmentby = 'project_id, cluster_id');
    -- Compressing chunks older than one month
    perform
      add_compression_policy ('public.operations', interval '1 month');
  else
    raise notice 'Timescaledb license does not support compression policy. Skipping compression setup.';
  end if;
else
  raise notice 'Timescaledb extension is not available. Skipping hypertable and compression setup.';
end if;
end
$$;
-- +goose StatementEnd

create or replace view public.v_operations as
select
  op.project_id,
  op.cluster_id,
  op.id,
  op.created_at as "started",
  op.updated_at as "finished",
  op.operation_type as "type",
  op.operation_status as "status",
  cl.cluster_name as "cluster",
  env.environment_name as "environment"
from
  public.operations op
  join public.clusters cl on op.cluster_id = cl.cluster_id
  join public.projects pr on op.project_id = pr.project_id
  join public.environments env on cl.environment_id = env.environment_id;

-- Postgres versions
create table public.postgres_versions (
  major_version integer primary key,
  release_date date,
  end_of_life date
);

comment on table public.postgres_versions is 'Table containing the major PostgreSQL versions supported by the autobase';

comment on column public.postgres_versions.major_version is 'The major version of PostgreSQL';

comment on column public.postgres_versions.release_date is 'The release date of the PostgreSQL version';

comment on column public.postgres_versions.end_of_life is 'The end of life date for the PostgreSQL version';

insert into public.postgres_versions (major_version, release_date, end_of_life)
  values (10, '2017-10-05', '2022-11-10'),
  (11, '2018-10-18', '2023-11-09'),
  (12, '2019-10-03', '2024-11-14'),
  (13, '2020-09-24', '2025-11-13'),
  (14, '2021-09-30', '2026-11-12'),
  (15, '2022-10-13', '2027-11-11'),
  (16, '2023-09-14', '2028-11-09');

-- Settings
create table public.settings (
  id bigserial primary key,
  setting_name text not null unique,
  setting_value jsonb not null,
  created_at timestamp default current_timestamp,
  updated_at timestamp
);

comment on table public.settings is 'Table containing configuration parameters, including console and other component settings';

comment on column public.settings.setting_name is 'The key of the setting';

comment on column public.settings.setting_value is 'The value of the setting';

comment on column public.settings.created_at is 'The timestamp when the setting was created';

comment on column public.settings.updated_at is 'The timestamp when the setting was last updated';

create trigger handle_updated_at
  before update on public.settings for each row
  execute function extensions.moddatetime (updated_at);

create index settings_name_idx on public.settings (setting_name);

-- +goose Down
-- Drop triggers
drop trigger update_server_count_trigger on public.servers;

drop trigger handle_updated_at on public.servers;

drop trigger handle_updated_at on public.clusters;

drop trigger handle_updated_at on public.environments;

drop trigger handle_updated_at on public.projects;

drop trigger handle_updated_at on public.secrets;

drop trigger handle_updated_at on public.operations;

-- Drop functions
drop function update_server_count;

drop function get_secret;

drop function add_secret;

drop function get_cluster_name;

-- Drop views
drop view public.v_operations;

drop view public.v_secrets_list;

-- Drop tables
drop table public.postgres_versions;

drop table public.operations;

drop table public.servers;

drop table public.clusters;

drop table public.secrets;

drop table public.environments;

drop table public.projects;

drop table public.settings;

