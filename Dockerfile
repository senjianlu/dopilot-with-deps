# syntax=docker/dockerfile:1.7

ARG DOPILOT_BASE_IMAGE=rabbir/dopilot:latest

FROM ${DOPILOT_BASE_IMAGE}

ARG INSTALL_PLAYWRIGHT_BROWSERS=false

WORKDIR /app

ENV PIP_DEFAULT_TIMEOUT=240 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_PROGRESS_BAR=off \
    PIP_RETRIES=20

COPY requirements.txt constraints.txt /tmp/dopilot-with-deps/

RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --prefer-binary --retries 20 --timeout 240 \
      -c /tmp/dopilot-with-deps/constraints.txt \
      -r /tmp/dopilot-with-deps/requirements.txt \
    && pip check \
    && python - <<'PY'
import dopilot_agent
import dopilot_protocol
import dopilot_server

print("dopilot runtime imports ok")
PY

RUN if [ "${INSTALL_PLAYWRIGHT_BROWSERS}" = "true" ]; then \
      python -m playwright install --with-deps chromium; \
    fi
