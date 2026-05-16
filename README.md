# fooocus-docker

A minimal Docker Compose setup for running [Fooocus](https://github.com/lllyasviel/Fooocus) — an image generation tool built on Stable Diffusion XL — with a persistent data directory for models, configuration, and outputs.

This is just deployment glue. All the heavy lifting is done by the upstream `ghcr.io/lllyasviel/fooocus` image.

## Requirements

- Docker and Docker Compose
- NVIDIA GPU + the [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)
- ~10 GB of disk space for the base SDXL checkpoint (more if you add LoRAs / ControlNets)

## Quick start

```bash
git clone https://github.com/manzolo/fooocus-docker.git
cd fooocus-docker
docker compose up -d
```

Open <http://localhost:7865> in your browser. On the first run Fooocus will download the default SDXL checkpoint into the `fooocus-data` volume — give it a few minutes.

Useful commands:

```bash
docker compose logs -f app                 # follow logs
docker compose down                        # stop
docker compose pull && docker compose up -d   # update to the latest upstream image
```

## How it's wired up

The container expects two distinct roots, and it's worth understanding the split:

| Path inside container | What lives there | Source |
| --- | --- | --- |
| `/content/data` | Models, `config.txt`, anything you want to persist | Named volume `fooocus-data` |
| `/content/app` | Generated outputs, wildcards, bundled safety/SAM/VAE models | Inside the image |

`path_outputs` is intentionally pointed at `/content/app/outputs/` — the in-UI history viewer only works when outputs live under `/content/app`. The volume mount in `docker-compose.yml` documents this with a warning comment.

All other model paths (`path_checkpoints`, `path_loras`, `path_embeddings`, `path_controlnet`, …) are pointed at `/content/data/models/...` via environment variables so they survive image upgrades.

## Configuration

Two ways to tweak Fooocus, and they overlap:

1. **Environment variables in `docker-compose.yml`** — read by `launch.py` at startup. Use `CMDARGS` for command-line flags (e.g. `--listen`, `--port`, `--share`).
2. **`fooocus-data/config.txt`** — JSON file mounted at `/content/data/config.txt`. Edit at runtime to change default models, LoRAs, styles, aspect ratios, etc.

Fooocus drops a `config_modification_tutorial.txt` next to `config.txt` documenting every accepted key — that file is reference-only, don't edit it (the file itself says so at the top).

## Bringing your own models

Drop `.safetensors` files into the appropriate subdirectory of the volume. With the default named volume:

```bash
# Find where Docker put the volume on the host
docker volume inspect fooocus-docker_fooocus-data --format '{{ .Mountpoint }}'

# Then copy models into models/checkpoints/, models/loras/, etc.
```

If you'd rather use a bind mount (e.g. point at an existing model library on the host), swap the volume line in `docker-compose.yml` for something like:

```yaml
    volumes:
      - ./fooocus-data:/content/data
```

## GPU selection

The compose file reserves GPU `0` by default. To pick a different GPU, change `device_ids: ['0']` in `docker-compose.yml`. To use multiple GPUs, list them: `device_ids: ['0', '1']`.

## License

The deployment configuration in this repository is provided as-is. Fooocus itself is licensed under GPL-2.0 — see the [upstream repository](https://github.com/lllyasviel/Fooocus) for details.
