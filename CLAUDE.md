# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A thin Docker Compose wrapper around the upstream Fooocus image (`ghcr.io/lllyasviel/fooocus`). There is **no application source code here** — only deployment config and a persisted data directory. Upstream project: https://github.com/lllyasviel/Fooocus.

## Commands

```bash
docker compose up -d           # start (web UI on http://localhost:7865)
docker compose logs -f app     # follow logs
docker compose down            # stop
docker compose pull && docker compose up -d   # update the upstream image
```

Requires an NVIDIA GPU with the NVIDIA Container Toolkit installed — `docker-compose.yml` reserves `device_ids: ['0']` with `compute, utility` capabilities.

## Layout & path conventions

The container expects two distinct roots, and confusing them is the most common source of breakage:

- `/content/data` — host-mounted (named volume `fooocus-data` → `./fooocus-data/`). Holds models, the user-editable `config.txt`, and the tutorial file. Survives image upgrades.
- `/content/app` — inside the container image. Holds `outputs/`, `wildcards/`, and the safety_checker/sam/vae models that ship with Fooocus.

`path_outputs` **must stay under `/content/app`** or the in-UI history log breaks (see comment in `docker-compose.yml`). All other model paths are pointed at `/content/data/models/...` via env vars in `docker-compose.yml` so they persist.

## Configuration

Two ways to set paths/defaults, and they overlap:

1. **`docker-compose.yml` env vars** (`path_checkpoints`, `path_loras`, ..., `CMDARGS`) — read by Fooocus's `launch.py` at startup.
2. **`fooocus-data/config.txt`** — JSON file mounted at `/content/data/config.txt`. Editable at runtime.

When changing paths or defaults, prefer editing `config.txt`. **Never edit `config_modification_tutorial.txt`** — it's reference-only (the file itself says so at the top); changes there have no effect. Use it as the schema reference for what keys `config.txt` accepts (default model, LoRAs, styles, aspect ratios, etc.).

## Outputs

Generated images land in the named volume at `fooocus-data/outputs/<YYYY-MM-DD>/`. These are user artifacts — do not delete or restructure them without asking.

