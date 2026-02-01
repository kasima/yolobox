# Example Makefile for a Python project using yolobox

-include agent.config
include yolobox/Makefile.agent

# Project-specific targets

test:
	docker exec -it $(AGENT) bash -lc "cd /workspace && pytest"

lint:
	docker exec -it $(AGENT) bash -lc "cd /workspace && ruff check ."

typecheck:
	docker exec -it $(AGENT) bash -lc "cd /workspace && mypy ."
