# Claude Code Instructions

This repo provides reusable dev container infrastructure for coding agents.

## If you're working IN a repo that uses yolobox

You're probably already inside a container. Your environment:
- `/workspace` - your code (git worktree)
- `/venv` - Python virtualenv (persistent)
- `/npm` - npm global packages (persistent)
- `/home/agent` - home directory with auth

Run `make agents` to see running containers.

## If you're setting up yolobox for a new repo

```bash
git submodule add https://github.com/kasima/yolobox.git
echo 'include yolobox/Makefile.agent' > Makefile
make agent-init    # creates AGENTS.md
make dev-image
make worktree-add AGENT=agent-a
make agent-up AGENT=agent-a
```

## Key commands

| Command | What it does |
|---------|--------------|
| `make agent-init` | Create AGENTS.md from template |
| `make dev-image` | Build the container image |
| `make worktree-add AGENT=name` | Create isolated git worktree |
| `make agent-up AGENT=name` | Start a container |
| `make agent-sh AGENT=name` | Shell into container |
| `make agent-stop AGENT=name` | Stop container, keep worktree |
| `make agent-down AGENT=name` | Remove everything |
| `make agents` | List running containers |

See README.md for full documentation.
