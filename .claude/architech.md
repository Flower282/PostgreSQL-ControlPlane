# Autobase Project Architecture

This document explains the structure of the Autobase repository so an AI agent can quickly understand where core logic lives, how deployment automation is organized, and where to make safe changes.

## 1. Repository Purpose

Autobase is organized as an automation-first platform for provisioning, deploying, operating, and upgrading PostgreSQL clusters.

At a high level, the repository combines:
- Infrastructure automation (mostly Ansible)
- Service runtime components (Go backend in `service/`)
- Supporting runtime environments (Docker-based local stack in `console/`)
- UI and static assets (`ui/`, `images/`)

## 2. Top-Level Layout

- `automation/`: Main Ansible automation framework for cluster lifecycle operations.
- `console/`: Docker Compose-based local/enterprise runtime environment.
- `service/`: Go service implementing API/business logic.
- `ui/`: Frontend application (details live inside this folder).
- `images/`: Image assets and related resources.
- `README.md`, `CONTRIBUTING.md`, `Makefile`: Entry documentation and common developer commands.
- `renovate.json`: Dependency update policy.

## 3. Automation Domain (`automation/`)

This is the largest and most operationally critical area.

### 3.1 Core Configuration Files

- `ansible.cfg`: Global Ansible execution settings.
- `inventory.example`: Example inventory template for environments.
- `requirements.txt` / `requirements.yml`: Python and Ansible Galaxy dependencies.
- `galaxy.yml`, `meta/runtime.yml`: Metadata for role/collection compatibility.
- `tags.md`: Tag strategy and task grouping guidance.
- `changelog.yaml`: Automation-related change tracking.

### 3.2 Playbooks (`automation/playbooks/`)

Playbooks model end-to-end operational flows. Important groups include:
- Cluster deployment and update:
  - `deploy_pgcluster.yml`
  - `config_pgcluster.yml`
  - `update_pgcluster.yml`
- Node lifecycle:
  - `add_node.yml`, `remove_node.yml`
  - `restart_pgnode.yml`, `start_pgnode.yml`, `stop_pgnode.yml`
- Cluster lifecycle operations:
  - `restart_pgcluster.yml`, `start_pgcluster.yml`, `stop_pgcluster.yml`
  - `switchover_pgcluster.yml`, `failover_pgcluster.yml`, `reinit_pgcluster.yml`
- Upgrade and rollback:
  - `pg_upgrade.yml`, `pg_upgrade_rollback.yml`
  - `pg_logical_upgrade.yml`, `pg_logical_switchover.yml`, `pg_logical_switchover_rollback.yml`
- Infrastructure dependencies:
  - `consul_cluster.yml`, `etcd_cluster.yml`, `balancers.yml`, `cloud_resources.yml`
- Decommission:
  - `remove_cluster.yml`

These playbooks are entry points. They usually orchestrate multiple roles with variable-driven behavior.

### 3.3 Roles (`automation/roles/`)

Roles provide modular behavior, grouped by concern:
- OS/system baseline:
  - `common/`, `packages/`, `hostname/`, `timezone/`, `locales/`, `sysctl/`, `swap/`, `mount/`, `firewall/`
- Security/access:
  - `authorized_keys/`, `ssh_keys/`, `sudo/`, `pam_limits/`, `tls_certificate/`
- PostgreSQL stack:
  - `patroni/`, `pgbouncer/`, `postgresql_users/`, `postgresql_databases/`, `postgresql_schemas/`, `postgresql_privs/`, `postgresql_extensions/`
- Backup/restore and WAL tooling:
  - `pgbackrest/`, `pg_probackup/`, `wal_g/`
- Cluster coordination and networking:
  - `etcd/`, `consul/`, `haproxy/`, `keepalived/`, `vip_manager/`, `bind_address/`, `resolv_conf/`, `etc_hosts/`
- Maintenance/operations:
  - `upgrade/`, `update/`, `deploy_finish/`, `pre_checks/`, `postgresql_index_maintenance/`

When changing operational behavior, role tasks/defaults/handlers are usually the safest and most reusable modification points.

### 3.4 Plugins (`automation/plugins/`)

- `modules/`: Custom Ansible modules.
- `callback/`: Custom callback plugins for output/reporting behavior.

Use this area when built-in Ansible modules are not sufficient.

### 3.5 Molecule (`automation/molecule/`)

Scenario-based test suites:
- `default/`
- `pg_upgrade/`
- `redeploy/`
- `tests/`

This is the first place to validate role/playbook changes before real environments.

## 4. Console Runtime (`console/`)

Provides Docker-based runnable environments:
- `docker-compose.yml` and enterprise variants (`docker-compose.enterprise.yml`, SSL and secrets overlays).
- `Dockerfile`, `supervisord.conf`, and runtime helpers.
- `db/`: Containerized PostgreSQL config and startup scripts (`postgresql.conf`, `pg_hba.conf`, `pg_start.sh`, migrations).

Use this area for local integration runs and reproducible environment bootstrapping.

## 5. Service Backend (`service/`)

Go-based backend service:
- `go.mod`: Module dependencies.
- `main.go`: Application entry point.
- `api/`, `internal/`, `middleware/`: API surface, core domain logic, and request middleware.
- `Makefile`, `README.md`, `VERSION`: Build/release metadata and workflows.

Typical code change flow:
1. API contract in `api/`.
2. Business logic in `internal/`.
3. Cross-cutting concerns in `middleware/`.
4. Wiring in `main.go`.

## 6. UI Layer (`ui/`)

Contains the frontend application. Folder internals are not expanded here, but AI agents should:
- Inspect package manager and build scripts first.
- Follow existing component/state conventions.
- Keep API integration aligned with `service/` interfaces.

## 7. Change Strategy for AI Agents

When implementing changes, prefer this order:
1. Identify domain: automation, backend service, console runtime, or UI.
2. Find the smallest stable entry point (playbook, role task, Go package, or compose file).
3. Preserve existing deployment patterns and naming conventions.
4. Validate with the nearest test/lint/run command (Molecule for automation, Go test/build for service, compose checks for console).

## 8. Safety Notes

- Treat `automation/playbooks/` and `automation/roles/` as production-sensitive.
- Avoid broad refactors across many roles unless explicitly required.
- For cluster operations (upgrade/switchover/failover), always align changes with rollback playbooks.
- Keep backward compatibility in inventory variables and role defaults whenever possible.

## 9. Quick Navigation Summary

- Cluster orchestration: `automation/playbooks/`
- Reusable automation logic: `automation/roles/`
- Custom Ansible extensions: `automation/plugins/`
- Automation tests: `automation/molecule/`
- Local runtime stack: `console/`
- Go backend service: `service/`
- Frontend: `ui/`
