# Coding And Change Conventions

This document describes repository conventions for AI agents.

## 1. General Conventions

- Prefer small, focused commits and minimal diff scope.
- Keep existing naming, file layout, and style.
- Do not reformat unrelated files.
- Preserve backward compatibility where possible.
- Avoid introducing new dependencies unless justified.

## 2. Automation (Ansible) Conventions

- Prefer role-based implementation over monolithic playbook logic.
- Use variables/defaults instead of hardcoded constants.
- Keep idempotency: repeated runs should converge to same state.
- Keep distro/version compatibility in mind (Debian/Ubuntu/RHEL-family).
- Keep upgrade/failover/switchover logic conservative and reversible.

Recommended touch points:
- Role tasks: `automation/roles/<role>/tasks/`
- Role defaults: `automation/roles/<role>/defaults/`
- Role handlers: `automation/roles/<role>/handlers/`

## 3. Go Service Conventions

- Keep request handling and business logic separated.
- Place core logic in `console/service/internal/`.
- Keep middleware concerns in `console/service/middleware/`.
- Keep API schema updates aligned with swagger generation process.
- Preserve env var compatibility (`PG_CONSOLE_*` and `_FILE` behavior).

## 4. Docker/Runtime Conventions

- Keep compose overlays purpose-specific.
- Prefer environment-driven config over image changes.
- Keep secrets out of plain text whenever possible.
- Preserve existing startup and restart behavior.

## 5. Documentation Conventions

When behavior changes, update nearby docs in the same change when practical:
- Root platform behavior: `README.md`
- Console runtime usage: `console/README.md`
- Service behavior/config: `console/service/README.md`
- Automation workflow details: `automation/README.md`

## 6. Validation Conventions

Use nearest relevant validation:
- Automation:
  - make targets from root `Makefile` (lint/tests/molecule)
- Service:
  - `go test ./...`
  - `go build`
- Runtime:
  - `docker compose config`
  - targeted `docker compose up` checks when needed

If validation cannot be run, explicitly state what was skipped and why.

## 7. Safety Conventions

- Avoid destructive operations unless explicitly requested.
- Keep rollback paths intact for cluster lifecycle changes.
- Do not weaken auth, TLS, or secret handling defaults.
