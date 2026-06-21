# dopilot-with-deps

[English](README.md) | 简体中文

`dopilot-with-deps` 是 dopilot 的运行时扩展镜像仓库。它不 fork dopilot 源码，
而是基于已发布的 dopilot 镜像，安装 `requirements.txt` 中列出的额外 Python
依赖，然后推送：

```text
rabbir/dopilot-with-deps:latest
rabbir/dopilot-with-deps:<dopilot-or-custom-sha>
```

配合现有 dopilot Compose 栈使用：

```bash
cd deploy/docker
DOPILOT_IMAGE=rabbir/dopilot-with-deps:latest docker compose pull
DOPILOT_IMAGE=rabbir/dopilot-with-deps:latest docker compose up -d
```

## 文件

| 文件 | 用途 |
| --- | --- |
| `Dockerfile` | 继承 `rabbir/dopilot` 并安装额外依赖。 |
| `requirements.txt` | 给爬虫 / Python 脚本运行时使用的额外依赖。 |
| `constraints.txt` | 保护 dopilot 自身运行依赖的兼容性约束。 |
| `.github/workflows/docker.yml` | 构建并推送 `rabbir/dopilot-with-deps`。 |

## 运行敏感依赖

`requirements.txt` 中带 `[dopilot runtime-sensitive]` 的注释是警告标记。
GitHub 会把这些注释行渲染为灰色。它下面的依赖与 dopilot 自身运行依赖有交集。

这些依赖是 dopilot server、migrate 或 agent 运行需要的。修改它们可能影响 dopilot
程序本身；改 `requirements.txt` 或 `constraints.txt` 前需要反复确认并重新测试。

当前运行敏感依赖：

| 依赖 | 为什么敏感 |
| --- | --- |
| `psycopg[binary]` | dopilot 为可复现构建固定为 `psycopg[binary]==3.3.4`。 |
| `pydantic` | dopilot API schema 与 FastAPI runtime 使用它。 |
| `sqlalchemy` | dopilot 当前支持 SQLAlchemy 2.0.x。 |
| `scrapy` | dopilot 内置 Scrapy agent runtime 使用它。 |
| `httpx` | dopilot server/agent HTTP client 使用它。 |

`constraints.txt` 会有意收窄部分用户依赖范围。例如 `requirements.txt` 中写的是
`sqlalchemy>=2.0,<3`，但 `constraints.txt` 会限制在 `<2.1`，因为 dopilot 当前只
支持 SQLAlchemy 2.0.x。

## GitHub Actions 配置

在其他命名空间使用前，请替换或确认 workflow 中的这些环境变量：

```yaml
env:
  DOCKER_IMAGE: rabbir/dopilot-with-deps
  DOPILOT_BASE_IMAGE_DEFAULT: rabbir/dopilot:latest
  DOCKER_PLATFORMS: linux/amd64
```

需要配置的仓库 secrets：

| Secret | 用途 |
| --- | --- |
| `DOCKERHUB_USERNAME` | 有推送权限的 Docker Hub 用户名。 |
| `DOCKERHUB_TOKEN` | 有权限推送到 `rabbir/dopilot-with-deps` 的 Docker Hub token。 |

手动构建：

1. 打开 `docker` workflow。
2. 执行 `workflow_dispatch`。
3. 按需设置 `dopilot_base_image`、`image_tag` 和
   `install_playwright_browsers`。

从 dopilot 自动触发构建：

本 workflow 监听类型为 `dopilot-image-built` 的 `repository_dispatch`。上游
dopilot workflow 需要发送：

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

发送方仓库需要一个能对 `senjianlu/dopilot-with-deps` 调用
`repository_dispatch` 的 token，可保存为
`DOPILOT_WITH_DEPS_DISPATCH_TOKEN`。

## Playwright 浏览器

默认只安装 Python Playwright 包，不安装浏览器二进制。需要浏览器时启用 build arg：

```bash
docker build \
  --build-arg INSTALL_PLAYWRIGHT_BROWSERS=true \
  -t rabbir/dopilot-with-deps:local \
  .
```

GitHub workflow 也暴露了同名开关 `install_playwright_browsers`。安装浏览器会显著
增大镜像体积，只有运行脚本确实需要容器内浏览器时再打开。
