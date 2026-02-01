# Example Makefile for a Node.js project using yolobox

-include agent.config
include yolobox/Makefile.agent

# Project-specific targets

test:
	docker exec -it $(AGENT) bash -lc "cd /workspace && npm test"

build:
	docker exec -it $(AGENT) bash -lc "cd /workspace && npm run build"

lint:
	docker exec -it $(AGENT) bash -lc "cd /workspace && npm run lint"
