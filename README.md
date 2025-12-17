# ComfyUI (CPU-only) on Railway (Docker)

Minimal, production-ready **CPU-only** ComfyUI image for Railway. Installs ComfyUI from GitHub and pre-installs **ComfyUI-Manager** (based on the YanWenKun/ComfyUI-Docker `/cpu` approach). This image starts ComfyUI with `--cpu` to avoid any CUDA/GPU usage.

## Railway quick start

1. Create a new Railway project and add a service from this repo.
2. Railway detects the `Dockerfile` and builds automatically.
3. Deploy and open the public URL.

Notes:
- The container listens on `0.0.0.0` and honors Railway `PORT`. If Railway assigns a different `PORT` than `8188`, the container forwards it to ComfyUI internally to keep routing/healthchecks working.
- Recommended Railway deploy healthcheck path: `/api` (ComfyUI does not reliably serve `/` early in startup).

## Environment variables (Railway → Variables)

- `PORT`: Usually set by Railway. If it’s not set, the container defaults to `8188`.
- `OLLAMA_API_URL`: Optional. Base URL of your Ollama instance (for Ollama-related custom nodes).
- `CLI_ARGS`: Optional. Extra args appended to `python main.py`.
- `COMFYUI_ARGS`: Deprecated alias for `CLI_ARGS`.

## Local Docker testing

```bash
docker compose up --build
```

Open `http://localhost:8188`.

Persistent folders (created locally):

- `./data/models` -> `/root/ComfyUI/models`
- `./data/input` -> `/root/ComfyUI/input`
- `./data/output` -> `/root/ComfyUI/output`
- `./data/user` -> `/root/ComfyUI/user` (includes workflows at `user/default/workflows`)

## Storage / persistence on Railway

Railway storage is ephemeral by default. To persist data across deploys/restarts, configure Railway Volumes:

- Docs: https://docs.railway.com/reference/volumes

Recommended persistent directories:

- `/root/ComfyUI/models`
- `/root/ComfyUI/output`
- `/root/ComfyUI/user/default/workflows`

### Railway volume setup (dashboard)

1. Open your Railway service.
2. Go to **Volumes**.
3. Create a volume and mount it to one of the paths above (repeat for each path you want to persist).
4. Redeploy the service.

## Ollama integration (`OLLAMA_API_URL`)

This image provides the `OLLAMA_API_URL` environment variable for **Ollama-related custom nodes** (ComfyUI itself does not call Ollama without a plugin).

Examples:

- Same LAN (Ollama on another PC): `http://192.168.1.50:11434`
- Tailscale (private): `http://100.64.0.10:11434`
- Tunnel (public URL): `https://your-subdomain.example.com`

Quick test:

```bash
curl "$OLLAMA_API_URL/api/tags"
```

## Troubleshooting

- **Healthcheck failed but logs show “Starting server”**: this is usually a `PORT` mismatch or too-short healthcheck window. This image forwards `PORT` -> internal `8188` automatically to avoid port mismatches.
- **Ollama nodes can’t connect**: `OLLAMA_API_URL` must be reachable from Railway; `localhost` will not work.
- **Models/workflows missing after redeploy**: attach Railway volumes to the directories in “Storage”.

## Auto-redeploy on Git push (optional)

This repo includes `.github/workflows/railway-deploy.yml` to trigger Railway deployments from GitHub Actions if your Railway service requires manual “Check for updates”.
