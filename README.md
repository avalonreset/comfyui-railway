# ComfyUI (CPU-only) on Railway (Docker)

Minimal, production-ready **CPU-only** ComfyUI image for Railway. Installs ComfyUI from GitHub and pre-installs **ComfyUI-Manager** (based on the YanWenKun/ComfyUI-Docker `/cpu` approach). This image starts ComfyUI with `--cpu` to avoid any CUDA/GPU usage.

## Railway quick start

1. Create a new Railway project and add a service from this repo.
2. Railway detects the `Dockerfile` and builds automatically.
3. Ensure the service exposes `PORT` (Railway sets this automatically). The container listens on `0.0.0.0`.
4. Add persistent storage by attaching volumes (see "Storage"). Without volumes, models/workflows are lost on redeploy.
5. Deploy and open the public URL. ComfyUI runs on port `8188` (or `PORT` if Railway overrides it).

Railway deploy healthcheck:
- Set **Healthcheck Path** to `/api` (ComfyUI does not reliably serve `/`).

## Auto-redeploy on Git push (reliable)

If your Railway service is not automatically redeploying on GitHub pushes (common when the service shows an **Upstream Repo** + **Check for updates** button), use GitHub Actions to trigger a deploy.

This repo includes `.github/workflows/railway-deploy.yml`, which supports two trigger methods:

### Option A: Deploy Hook URL (simplest, if available)

1. In Railway, open your service → **Deployments** (or **Settings**) → create/copy a **Deploy Hook** URL.
2. In GitHub, add a repo secret named `RAILWAY_DEPLOY_HOOK_URL` containing that URL.
3. Push to `main`. GitHub Actions will call the hook and Railway will build/deploy.

Workflow file: `.github/workflows/railway-deploy.yml`

### Option B: Railway CLI token (works even if you can’t find hooks)

1. Create a Railway API token and add it as a GitHub repo secret: `RAILWAY_TOKEN`
2. Add these GitHub repo secrets (IDs are in your Railway dashboard URL):
   - `RAILWAY_PROJECT_ID`
   - `RAILWAY_SERVICE_ID`
3. Push to `main`. GitHub Actions will run `railway up` to trigger a deploy.

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

## Ollama integration (`OLLAMA_API_URL`)

This image provides the `OLLAMA_API_URL` environment variable for **Ollama-related custom nodes** (ComfyUI itself does not call Ollama without a plugin).

### How it works

- You run **ComfyUI on Railway**.
- You run **Ollama on your machine** (or another server).
- You set `OLLAMA_API_URL` to a URL that is reachable *from Railway*.

### Local testing (Ollama on your machine)

Set:

- `OLLAMA_API_URL=http://host.docker.internal:11434`

The included `docker-compose.yml` sets this by default and adds `extra_hosts` for Linux.

### Railway (Ollama on your local machine)

Railway cannot directly reach `localhost` on your laptop. You must make Ollama reachable from the internet (or via a private network) and then set:

- `OLLAMA_API_URL=https://<reachable-ollama-url>`

Common options:

- Use a tunnel (Cloudflare Tunnel, ngrok) to expose `http://localhost:11434`
- Use a VPN overlay (Tailscale) and point Railway to a reachable endpoint
- Run Ollama on a remote machine and open port `11434` to Railway (not recommended without network controls)

#### Examples

- Same LAN (Ollama on another PC): `http://192.168.1.50:11434`
- Tailscale (private): `http://100.64.0.10:11434`
- ngrok/Cloudflare Tunnel (public URL): `https://your-subdomain.example.com`

#### Firewall / port requirements

- Ollama must listen on an address reachable by Railway (not `127.0.0.1`).
- Ensure inbound TCP `11434` is allowed on the Ollama host (or tunnel handles it).

If Ollama is only listening on localhost, configure it to listen on your LAN/VPN interface (example):

```bash
OLLAMA_HOST=0.0.0.0 ollama serve
```

#### Test the connection before using ComfyUI nodes

From your own machine, verify Ollama responds:

```bash
curl http://localhost:11434/api/tags
```

Then verify the exact URL you plan to put in `OLLAMA_API_URL` responds:

```bash
curl "$OLLAMA_API_URL/api/tags"
```

Security note: If you expose Ollama publicly, protect it (auth/allowlists) and assume anything reachable can be called by your ComfyUI workflows.

## Storage / persistence on Railway

Railway storage is ephemeral by default. To persist data across deploys/restarts, configure Railway Volumes:

- Docs: https://docs.railway.com/reference/volumes

Recommended persistent directories:

- `/root/ComfyUI/models`
- `/root/ComfyUI/output`
- `/root/ComfyUI/user/default/workflows`

What persists where:

- Models (checkpoints/loras/etc): `/root/ComfyUI/models`
- Workflows: `/root/ComfyUI/user/default/workflows`
- Outputs (generated images): `/root/ComfyUI/output`

### Railway volume setup (dashboard)

1. Open your Railway service.
2. Go to **Volumes**.
3. Create a volume and mount it to one of the paths above (repeat for each path you want to persist).
4. Redeploy the service.

If you can only attach one volume, prioritize `/root/ComfyUI/user/default/workflows` so saved workflows survive deploys.

## Environment variables

- `PORT`: Port to listen on. Railway usually sets this; the container uses `8188` if it is not set.
- `OLLAMA_API_URL`: Base URL of your Ollama instance (for Ollama custom nodes). You typically set this manually.
- `CLI_ARGS`: Extra CLI args appended to `python main.py` (example: `--enable-cors-header`).
- `COMFYUI_ARGS`: Deprecated alias for `CLI_ARGS`.

## Troubleshooting

- **Service deploys but page won't load**: verify Railway assigned `PORT` and the service listens on `0.0.0.0` (this image does).
- **Healthcheck failing**: the container healthcheck fetches `/` on `127.0.0.1:$PORT` and checks for the `ComfyUI` HTML title.
- **Ollama nodes can't connect**: `OLLAMA_API_URL` must be reachable from Railway; `localhost` will not work.
- **Models/workflows missing after redeploy**: attach volumes to the paths listed in "Storage".
