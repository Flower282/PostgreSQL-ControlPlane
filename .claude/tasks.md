# AI Agent Task Workflow

This file defines how AI agents should execute work in this repository.

## 1. Mission

Deliver safe, minimal, verifiable changes for Autobase across:
- Ansible automation (`automation/`)
- Console runtime (`console/`)
- Console API service (`console/service/`)

## 2. Task Intake Checklist

Before editing code:
1. Identify target domain: automation, console runtime, or Go API service.
2. Find the narrowest entry point (playbook/role, compose file, or Go package).
3. Confirm expected behavior and rollback path.
4. Prefer additive, backward-compatible changes.

## 3. Execution Flow

1. Read context files first:
- `README.md`
- `automation/README.md`
- `console/README.md`
- `console/service/README.md`

2. Locate impacted files:
- For orchestration actions: `automation/playbooks/`
- For reusable provisioning logic: `automation/roles/`
- For API behavior: `console/service/internal/`
- For runtime wiring: `console/docker-compose*.yml`

3. Implement minimal change:
- Keep naming and structure consistent.
- Avoid broad refactors unless explicitly requested.
- Avoid changing unrelated files.

4. Validate:
- Automation changes: run lint/molecule where feasible.
- Go service changes: run `go test` / `go build` where feasible.
- Compose/runtime changes: run compose config checks or startup checks where feasible.

5. Report:
- What changed
- Why it changed
- How it was validated
- Remaining risks or unvalidated areas

## 4. Domain-Specific Routing Rules

### 4.1 Automation Changes

Use this order:
1. Playbook entrypoint in `automation/playbooks/`
2. Role task/default/handler in `automation/roles/`
3. Plugin in `automation/plugins/` only when role/playbook cannot solve it

Always check for paired rollback operations for:
- upgrade
- switchover
- failover

### 4.2 Console Runtime Changes

Primary files:
- `console/docker-compose.yml`
- `console/docker-compose.caddy.yml`
- `console/docker-compose.enterprise*.yml`
- `console/docker-compose.secrets.yml`

Rules:
- Keep secrets handling compatible with `_FILE` pattern.
- Do not hardcode sensitive values.
- Preserve service names/ports unless required.

### 4.3 Console API Service Changes

Primary folders:
- `console/service/api/`
- `console/service/internal/`
- `console/service/middleware/`

Rules:
- Keep API contract and generated swagger outputs aligned.
- Keep business logic in `internal/`, not in transport layer.
- Preserve compatibility of environment variable behavior.

## 5. Quality Bar

A task is complete only if:
1. The requested behavior is implemented.
2. Obvious regressions are checked.
3. Validation steps are executed or clearly documented as not run.
4. The change is scoped and understandable.

## 6. Out-of-Scope Guardrails

- Do not rewrite major architecture without explicit request.
- Do not remove safety checks from cluster operations.
- Do not alter default operational behavior of production paths unless required.
