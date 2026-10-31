---
name: copilot-device
description: Manual workflow for the device checkout without a usable Git remote. Use only when the user asks for the transport task, response, or publish flow.
disable-model-invocation: true
---

# Copilot device workflow

This skill belongs to the checkout that has no working Git remote. It is not
part of the normal NixOS build flow. Invoke it manually; do not auto-apply it.

## Files

- `scripts/wassos_transport/` - the task printer behind `uv run x`.
- `scripts/repo_config/` - the publish helper behind `uv run publish`.
- `response.md` - empty sample for a short response.

## Commands

- `uv sync` once.
- `uv run x` prints the current task. It does not modify files.
- To change the task, edit `scripts/wassos_transport/__init__.py`.
- `uv run publish -m "message" [--body "body"]` publishes staged files. The
  helper reads `git diff --cached`; stage only the intended files.
- Do not run other Git commands while publication is in progress.

## Response

- `response.md` is an empty sample. Fill it with the short response to hand
  back.
- Stage it and publish it with `uv run publish -m "..."`.
- Keep secrets and host diagnostics out of the response.

## Rules

- The repository `AGENTS.md` and `.agents/skills/` still apply.
- Never run `nh`, `nixos-rebuild`, `sudo`, or `sops` here.
