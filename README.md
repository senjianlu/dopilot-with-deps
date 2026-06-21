# dopilot-with-deps

English | [简体中文](README.zh-CN.md)

`dopilot-with-deps` is a small runtime-overlay image for dopilot. It does not
fork dopilot source code. It starts from a published dopilot image, installs the
extra Python dependencies listed in `requirements.txt`, then pushes:

```text
rabbir/dopilot-with-deps:latest
rabbir/dopilot-with-deps:<dopilot-or-custom-sha>
```

Use it with the existing dopilot Compose stack:

```bash
cd deploy/docker
DOPILOT_IMAGE=rabbir/dopilot-with-deps:latest docker compose pull
DOPILOT_IMAGE=rabbir/dopilot-with-deps:latest docker compose up -d
```

## Files

| File | Purpose |
| --- | --- |
| `Dockerfile` | Extends `rabbir/dopilot` and installs the extra dependencies. |
| `requirements.txt` | Extra dependencies requested for scraper/script runtime use. |
| `constraints.txt` | Compatibility guard for dependencies dopilot itself needs. |
| `.github/workflows/docker.yml` | Builds and pushes `rabbir/dopilot-with-deps`. |

## Runtime-sensitive dependencies

In `requirements.txt`, comments marked `[dopilot runtime-sensitive]` are warning
markers. GitHub renders those comment lines in muted gray. The dependency below
such a marker overlaps with packages dopilot itself uses.

Changing these dependencies can affect dopilot server, migrate, or agent startup.
Review them repeatedly before changing `requirements.txt` or `constraints.txt`.

Current runtime-sensitive set:

| Dependency | Why it is sensitive |
| --- | --- |
| `psycopg[binary]` | dopilot pins `psycopg[binary]==3.3.4` for reproducible builds. |
| `pydantic` | Used by dopilot API schemas and FastAPI runtime. |
| `sqlalchemy` | dopilot currently supports SQLAlchemy 2.0.x. |
| `scrapy` | Used by dopilot's bundled Scrapy agent runtime. |
| `httpx` | Used by dopilot server/agent HTTP clients. |

`constraints.txt` intentionally narrows some requested ranges. For example,
`requirements.txt` asks for `sqlalchemy>=2.0,<3`, but `constraints.txt` keeps it
below `2.1` because dopilot currently supports SQLAlchemy 2.0.x.

## GitHub Actions setup

Replace or confirm these workflow values before using this in another namespace:

```yaml
env:
  DOCKER_IMAGE: rabbir/dopilot-with-deps
  DOPILOT_BASE_IMAGE_DEFAULT: rabbir/dopilot:latest
  DOCKER_PLATFORMS: linux/amd64
```

Required repository secrets:

| Secret | Purpose |
| --- | --- |
| `DOCKERHUB_USERNAME` | Docker Hub username with push access. |
| `DOCKERHUB_TOKEN` | Docker Hub access token with push access to `rabbir/dopilot-with-deps`. |

Manual build:

1. Open the `docker` workflow.
2. Run `workflow_dispatch`.
3. Optionally set `dopilot_base_image`, `image_tag`, and
   `install_playwright_browsers`.

Automatic build from dopilot:

The workflow listens for `repository_dispatch` with type
`dopilot-image-built`. The upstream dopilot workflow should send:

```json
{
  "event_type": "dopilot-image-built",
  "client_payload": {
    "dopilot_sha": "full git sha",
    "dopilot_base_image": "rabbir/dopilot:<12-char-sha>",
    "install_playwright_browsers": "false"
  }
}
```

The sending repository needs a token that can call `repository_dispatch` on
`senjianlu/dopilot-with-deps`. Store it as a secret such as
`DOPILOT_WITH_DEPS_DISPATCH_TOKEN`.

## Playwright browsers

By default this image installs the Python Playwright package only. Browser
binaries are not installed unless the build arg is enabled:

```bash
docker build \
  --build-arg INSTALL_PLAYWRIGHT_BROWSERS=true \
  -t rabbir/dopilot-with-deps:local \
  .
```

The GitHub workflow exposes the same switch as `install_playwright_browsers`.
Installing browsers makes the image much larger, so keep it off unless your
runtime scripts need Playwright browser binaries inside the container.
