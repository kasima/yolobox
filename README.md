# yolobox

Disposable dev containers for coding agents. Spin up isolated environments, break things, throw them away.

## Prerequisites

- Docker (Engine + buildx)
- Git

## Quick Start (< 5 minutes)

```bash
# 1. Add to your repo (submodule or copy)
git submodule add https://github.com/kasima/yolobox.git

# 2. Create minimal Makefile
cat > Makefile << 'EOF'
include yolobox/Makefile.agent
EOF

# 3. Build the dev image
make dev-image

# 4. Create a worktree and spin up a container
make worktree-add AGENT=agent-a BASE=origin/main
make agent-up AGENT=agent-a

# 5. Shell in
make agent-sh AGENT=agent-a
```

## What You Get

Each agent container has:
- **Python 3.11** with scientific libs (numpy, opencv support)
- **Node.js 22** (configurable)
- **Coding agent CLIs** pre-installed (`claude-code`, `codex`)
- **GitHub CLI** (`gh`)
- **Isolated git worktree** - each agent works on its own branch
- **Persistent volumes** - venv, npm, pip cache survive restarts
- **Host UID mapping** - files are owned by your user, not root

## Configuration

Create `agent.config` in your repo root for project-specific settings:

```bash
# agent.config
DEV_IMAGE=myproject-dev
BASE=origin/main

# Optional: install project requirements into image
# BUILD_ARGS=--build-arg REQUIREMENTS_FILE=requirements.txt
```

Then include it in your Makefile:

```makefile
-include agent.config
include yolobox/Makefile.agent

# Add project-specific targets below
```

## Commands

| Command | Description |
|---------|-------------|
| `make dev-image` | Build the dev container image |
| `make worktree-add AGENT=name` | Create isolated git worktree |
| `make agent-up AGENT=name` | Start container for agent |
| `make agent-sh AGENT=name` | Shell into running container |
| `make agent-stop AGENT=name` | Stop container, keep worktree |
| `make agent-down AGENT=name` | Remove everything (container, volumes, worktree) |
| `make agents` | List running agent containers |

## Multi-Agent Workflow

Run multiple agents in parallel, each on their own branch:

```bash
# Spin up two agents
make worktree-add AGENT=agent-a BASE=origin/main
make worktree-add AGENT=agent-b BASE=origin/main
make agent-up AGENT=agent-a
make agent-up AGENT=agent-b

# Each agent has isolated:
# - Git worktree (worktrees/agent-a, worktrees/agent-b)
# - Python venv (/venv volume)
# - npm packages (/npm volume)
# - pip cache (/pipcache volume)
# - Home directory (/home/agent volume)
```

## Coding Agent Auth

Copy your auth to the container (never baked into images):

```bash
make agent-copy-auth AGENT=agent-a AUTH_JSON=~/.codex/auth.json
```

## Build Options

Customize the image at build time:

```bash
# Skip Node.js (pure Python project)
make dev-image BUILD_ARGS="--build-arg INSTALL_NODE=false"

# Different Node version
make dev-image BUILD_ARGS="--build-arg NODE_VERSION=20.17.0"

# Include project requirements
make dev-image BUILD_ARGS="--build-arg REQUIREMENTS_FILE=requirements.txt"

# Skip coding agent CLIs
make dev-image BUILD_ARGS="--build-arg INSTALL_AGENT_CLI=false"
```

## For Coding Agents

If you're a coding agent (Claude Code, Codex, etc.) and you see yolobox in a repo:

**You're likely already inside a yolobox container.** Check with:
```bash
make agents  # List running containers
```

**Your environment:**
- Working directory: `/workspace` (the git worktree)
- Python venv: `/venv` (persistent across restarts)
- npm packages: `/npm` (persistent)
- pip cache: `/pipcache` (persistent)
- Home directory: `/home/agent` (where auth lives)

**Common tasks:**
```bash
# Install Python packages (persists in /venv)
pip install some-package

# Install npm packages (persists in /npm)
npm i -g some-tool

# Run commands in the container
make agent-sh AGENT=agent-a
```

**If you need to set up a new agent container:**
```bash
make worktree-add AGENT=agent-b BASE=origin/main
make agent-up AGENT=agent-b
```

## License

MIT
