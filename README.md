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

# 3. Create AGENTS.md for coding agents (optional)
make agent-init

# 4. Build the dev image
make dev-image

# 5. Create a worktree and spin up a container (defaults to current HEAD)
make worktree-add AGENT=agent-a
make agent-up AGENT=agent-a

# 6. Shell in
make agent-sh AGENT=agent-a
```

## Setting Up With a Coding Agent

Tell your coding agent (Claude Code, Codex, etc.):

> Add yolobox (github.com/kasima/yolobox) as a submodule and set it up so I can run `make agent-up`

The agent will handle the git submodule, Makefile creation, image build, and container setup.

## What You Get

Each agent container has:
- **Configurable base image** (default: `python:3.11-bookworm`; swap for any Debian-based image)
- **Node.js 22** (optional, configurable version)
- **Coding agent CLIs** pre-installed (`claude-code`, `codex`)
- **GitHub CLI** (`gh`)
- **Passwordless sudo** for installing packages interactively
- **Claude Code auth** auto-mounted from `~/.claude` on the host (no login needed)
- **Isolated git worktree** - each agent works on its own branch
- **Persistent volumes** - venv, npm, pip cache survive restarts
- **Host UID mapping** - files are owned by your user, not root

## Configuration

Create `agent.config` in your repo root for project-specific settings:

```bash
# agent.config
# DEV_IMAGE is auto-derived from your project directory name (e.g. myproject-dev)
# Override here only if you need a specific name:
# DEV_IMAGE=myproject-dev

BASE=origin/main   # override default HEAD

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
| `make agent-init` | Create AGENTS.md from template |
| `make worktree-add AGENT=name [BASE=ref]` | Create isolated git worktree (BASE defaults to HEAD) |
| `make agent-up AGENT=name` | Start container for agent (uses git worktree) |
| `make agent-up-direct AGENT=name` | Start container with live project mounted directly (no worktree) |
| `make agent-sh AGENT=name` | Shell into running container |
| `make agent-stop AGENT=name` | Stop container, keep worktree |
| `make agent-down AGENT=name` | Remove everything (container, volumes, worktree) |
| `make agents` | List running agent containers |

## Single-Agent / Experimentation Workflow

For poking around without branch isolation, skip the worktree step and mount the live project directly:

```bash
make dev-image
make agent-up-direct AGENT=lab
make agent-sh AGENT=lab
```

Changes you make in `/workspace` inside the container are immediately reflected on the host, and vice versa.

## Multi-Agent Workflow

Run multiple agents in parallel, each on their own branch:

```bash
# Spin up two agents (from current HEAD by default, or specify BASE)
make worktree-add AGENT=agent-a
make worktree-add AGENT=agent-b BASE=origin/main
make agent-up AGENT=agent-a
make agent-up AGENT=agent-b

# Each agent has completely isolated volumes, namespaced by image+agent name:
# myproject-dev-agent-a-venv, myproject-dev-agent-b-venv, etc.
```

Volume names are prefixed with the image name (`DEV_IMAGE`) so agents across different projects never share volumes, even if they share the same agent name.

## Coding Agent Auth

**Claude Code:** Your host `~/.claude` directory is automatically mounted into the container. Claude Code auth works immediately with no extra steps.

**Codex:** Copy auth from your host:
```bash
make agent-copy-codex-auth AGENT=agent-a
```

## Build Options

Customize the image at build time:

```bash
# Use a different base image (e.g. Node.js only, no Python)
make dev-image BUILD_ARGS="--build-arg BASE_IMAGE=node:22-bookworm --build-arg INSTALL_NODE=false"

# Skip Node.js (pure Python project)
make dev-image BUILD_ARGS="--build-arg INSTALL_NODE=false"

# Different Node version
make dev-image BUILD_ARGS="--build-arg NODE_VERSION=20.17.0"

# Include project requirements baked into the image
make dev-image BUILD_ARGS="--build-arg REQUIREMENTS_FILE=requirements.txt"

# Extra pip packages baked into the image
make dev-image BUILD_ARGS="--build-arg EXTRA_PIP_PACKAGES='pytest ipython'"

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
- Working directory: `/workspace` (the git worktree or live project mount)
- Python venv: `/venv` (persistent across restarts)
- npm packages: `/npm` (persistent)
- pip cache: `/pipcache` (persistent)
- Home directory: `/home/agent` (where auth lives)

**Common tasks:**
```bash
# Install Python packages (persists in /venv)
pip install some-package

# Install system packages (passwordless sudo available)
sudo apt-get install some-package

# Install npm packages (persists in /npm)
npm i -g some-tool
```

**If you need to set up a new agent container:**
```bash
make worktree-add AGENT=agent-b              # from current HEAD
make worktree-add AGENT=agent-b BASE=main    # or specify a branch
make agent-up AGENT=agent-b
```

## License

MIT
