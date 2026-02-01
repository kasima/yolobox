#!/bin/sh
# Developer convenience profile: ensure per-agent venv/npm volumes are active.

# Prefer per-agent Python virtualenv if mounted at /venv
if [ -d /venv ]; then
  if [ ! -x /venv/bin/python ]; then
    echo "[devprofile] Creating Python venv in /venv" >&2
    python3 -m venv /venv || true
  fi
  case :$PATH: in
    *:/venv/bin:*) ;;
    *) export PATH="/venv/bin:$PATH" ;;
  esac
fi

# Prefer per-agent pip cache if mounted at /pipcache
if [ -d /pipcache ]; then
  export PIP_CACHE_DIR=/pipcache
fi

# Prefer per-agent npm prefix if mounted at /npm
if [ -d /npm ]; then
  # Configure npm prefix to /npm if npm exists
  if command -v npm >/dev/null 2>&1; then
    NPM_PREFIX=$(npm config get prefix 2>/dev/null || echo "")
    if [ "$NPM_PREFIX" != "/npm" ]; then
      npm config set prefix /npm >/dev/null 2>&1 || true
    fi
  fi
  case :$PATH: in
    *:/npm/bin:*) ;;
    *) export PATH="/npm/bin:$PATH" ;;
  esac
fi
