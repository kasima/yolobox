# yolobox Setup Guide

Detailed guide for setting up and operating dev containers for multiple coding agents.

## Prerequisites

- Docker installed (Engine + buildx)
- Git
- Run all commands from your repo root

## Installation

### Option A: Git Submodule (recommended)

```bash
git submodule add https://github.com/yourorg/yolobox.git
```

### Option B: Direct Copy

```bash
git clone https://github.com/yourorg/yolobox.git
rm -rf yolobox/.git
```

## Configuration

### Minimal Setup

Create a `Makefile` in your repo root:

```makefile
include yolobox/Makefile.agent
```

### With Project Config

Create `agent.config`:

```bash
# Required
DEV_IMAGE=myproject-dev

# Base branch for new worktrees (default: origin/main)
BASE=origin/main

# Build args (optional)
# BUILD_ARGS=--build-arg REQUIREMENTS_FILE=requirements.txt
```

Create `Makefile`:

```makefile
-include agent.config
include yolobox/Makefile.agent

# Project-specific targets
test:
	docker exec -it $(AGENT) bash -lc "cd /workspace && pytest"
```

## Building the Image

### Default Build

```bash
make dev-image
```

### With Project Requirements

```bash
make dev-image BUILD_ARGS="--build-arg REQUIREMENTS_FILE=requirements.txt"
```

### Custom Node Version

```bash
make dev-image BUILD_ARGS="--build-arg NODE_VERSION=20.17.0"
```

### Pure Python (no Node.js)

```bash
make dev-image BUILD_ARGS="--build-arg INSTALL_NODE=false"
```

### Pin CLI Versions

```bash
make dev-image BUILD_ARGS="--build-arg CODEX_VERSION=1.2.3 --build-arg CLAUDE_CODE_VERSION=0.4.0"
```

## Working with Agents

### Create and Start

```bash
# Create isolated worktree
make worktree-add AGENT=agent-a BASE=origin/main

# Start container
make agent-up AGENT=agent-a

# Shell in
make agent-sh AGENT=agent-a
```

### Inside the Container

```bash
# Python (uses persistent /venv)
python --version
pip install some-package  # Persists across restarts

# Node (uses persistent /npm)
node --version
npm i -g some-tool  # Persists across restarts

# Git (working on isolated worktree)
git status
git checkout -b feature/my-work
```

### Multiple Agents

```bash
# Start multiple agents in parallel
make worktree-add AGENT=agent-a BASE=origin/main
make worktree-add AGENT=agent-b BASE=origin/main
make agent-up AGENT=agent-a
make agent-up AGENT=agent-b

# Each has isolated volumes
# agent-a-venv, agent-a-npm, agent-a-pipcache, agent-a-home
# agent-b-venv, agent-b-npm, agent-b-pipcache, agent-b-home
```

### List Running Agents

```bash
make agents
# or
make ps
```

## Coding Agent Setup

### Install/Update CLIs

CLIs are pre-installed in the image. To update in a running container:

```bash
make agent-setup-tools AGENT=agent-a
```

### Copy Authentication

Never bake auth into images. Copy at runtime:

```bash
make agent-copy-auth AGENT=agent-a AUTH_JSON=~/.codex/auth.json
```

## Cleanup

### Stop Container (keep worktree and home)

```bash
make agent-stop AGENT=agent-a
```

This removes:
- Container
- pip cache volume
- venv volume
- npm volume

But keeps:
- Git worktree
- Home volume (with auth)

### Full Teardown

```bash
make agent-down AGENT=agent-a
```

Removes everything including worktree and home volume.

## Architecture

### Container Mounts

| Mount | Purpose |
|-------|---------|
| `/workspace` | Git worktree (your code) |
| `/venv` | Python virtualenv (persistent) |
| `/npm` | npm global prefix (persistent) |
| `/pipcache` | pip cache (persistent) |
| `/home/agent` | Home directory (persistent) |

### Security

- Containers run as your host UID:GID (files are owned by you)
- `--cap-drop=ALL` removes all capabilities
- `--security-opt no-new-privileges:true` prevents privilege escalation
- Auth is never baked into images

### Profile Scripts

Two scripts run on shell login:

1. **threads.sh** - Auto-scales OMP/BLAS threads to CPU count
2. **devprofile.sh** - Configures venv, npm, pip cache paths

## Troubleshooting

### "I have no name!" in shell

This shouldn't happen with current setup, but if it does:

```bash
docker exec -u 0 agent-a bash -c "echo 'agent:x:$(id -u):$(id -g):::/bin/bash' >> /etc/passwd"
```

### Permission denied on worktree files

Ensure container runs as your UID:

```bash
docker exec agent-a id
# Should show your host UID:GID
```

### Volumes not persisting

Check volume exists:

```bash
docker volume ls | grep agent-a
```

### Rebuilding after requirements change

```bash
make dev-image BUILD_ARGS="--build-arg REQUIREMENTS_FILE=requirements.txt"
make agent-stop AGENT=agent-a
make agent-up AGENT=agent-a
```
