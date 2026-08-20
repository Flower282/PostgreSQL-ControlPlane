# AI Agent Runbook

Practical commands and workflows for this repository.

## 1. Repository Bootstrap

From repository root:

```bash
make bootstrap
```

For development bootstrap:

```bash
make bootstrap-dev
```

Reinitialize environment:

```bash
make reinitialization
# or
make reinitialization-dev
```

## 2. Automation Validation

Run full automation checks:

```bash
make tests
```

Run faster checks:

```bash
make tests-fast
```

Common cleanup:

```bash
make clean
```

## 3. Console Runtime (Docker Compose)

From `console/` directory:

Basic stack:

```bash
docker compose up -d
```

With Caddy/SSL:

```bash
docker compose -f docker-compose.caddy.yml up -d
```

With secrets overlay:

```bash
docker compose -f docker-compose.yml -f docker-compose.secrets.yml up -d
```

Render/evaluate compose config without starting services:

```bash
docker compose config
```

## 4. Console API Service (Go)

From `console/service/` directory:

Ensure dependencies are tidy:

```bash
make ensure_deps
```

Build service binary:

```bash
make build
```

Generate Swagger server stubs:

```bash
make swagger_install
make swagger
```

Optional all-in-one build path:

```bash
make build_in_docker
```

## 5. Change Workflows

### 5.1 Automation Change Workflow

1. Edit target role/playbook.
2. Run focused lint/molecule checks if available.
3. Run broader `make tests` when change is significant.
4. Verify rollback-related playbooks if touching upgrade/switchover/failover paths.

### 5.2 Service Change Workflow

1. Edit `console/service/internal/` and related API layer.
2. Regenerate swagger code if API contract changed.
3. Build and test Go service.
4. Validate runtime behavior with console stack if needed.

### 5.3 Runtime/Compose Change Workflow

1. Edit compose file(s) in `console/`.
2. Run `docker compose config` for syntax/merge validation.
3. Start minimal stack and verify health.

## 6. Operational Safety Checklist

Before finalizing any change:

- Confirm no hardcoded secrets.
- Confirm no unreviewed destructive commands.
- Confirm compatibility with existing env vars and defaults.
- Confirm docs are updated when behavior changed.
- Confirm validation steps and outcomes are recorded.

## 7. Notes For Agents

- If a folder referenced by high-level docs is missing in local checkout (for example `ui/`), treat it as not available in this workspace and avoid assumptions.
- Prefer conservative changes in automation paths because they affect production cluster lifecycle operations.
