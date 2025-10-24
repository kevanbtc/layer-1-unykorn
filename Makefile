# Unykorn L1 - Makefile for managing Besu and Polygon-Edge networks
# Usage: make <target>
# Run 'make help' to see all available commands

.PHONY: help besu-init besu-up besu-down besu-logs besu-clean edge-init edge-up edge-down edge-logs edge-clean test-rpc clean-all

# Default target
.DEFAULT_GOAL := help

##@ General

help: ## Display this help message
	@echo ""
	@echo "═══════════════════════════════════════════════════════════"
	@echo "  Unykorn L1 - Layer 1 Blockchain Management"
	@echo "═══════════════════════════════════════════════════════════"
	@echo ""
	@echo "Usage: make <target>"
	@echo ""
	@echo "Targets:"
	@awk 'BEGIN {FS = ":.*##"; printf ""} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
	@echo ""

##@ Hyperledger Besu (QBFT Consensus)

besu-init: ## Initialize Besu network (generate keys + genesis)
	@echo "🔧 Initializing Besu network..."
	@docker-compose -f docker/docker-compose.besu.yml run --rm besu-init
	@echo "✅ Besu initialization complete!"

besu-up: ## Start Besu network (4 validators + RPC node)
	@echo "🚀 Starting Besu network..."
	@docker-compose -f docker/docker-compose.besu.yml up -d
	@echo "✅ Besu network running!"
	@echo "   RPC: http://localhost:8545"
	@echo "   Chain ID: 7777"
	@echo ""
	@echo "Run 'make test-rpc' to verify"

besu-down: ## Stop Besu network
	@echo "⏹️  Stopping Besu network..."
	@docker-compose -f docker/docker-compose.besu.yml down
	@echo "✅ Besu network stopped"

besu-logs: ## View Besu logs (all containers)
	@docker-compose -f docker/docker-compose.besu.yml logs -f

besu-clean: ## Remove Besu data and keys (DESTRUCTIVE)
	@echo "⚠️  WARNING: This will delete all Besu blockchain data and keys!"
	@read -p "Press Enter to continue or Ctrl+C to cancel..."
	@docker-compose -f docker/docker-compose.besu.yml down -v
	@rm -rf data/besu-* scripts/keys/besu
	@echo "✅ Besu data cleaned"

besu-restart: besu-down besu-up ## Restart Besu network

##@ Polygon-Edge (IBFT Consensus)

edge-init: ## Initialize Polygon-Edge network (generate keys + genesis)
	@echo "🔧 Initializing Polygon-Edge network..."
	@docker-compose -f docker/docker-compose.edge.yml run --rm edge-init
	@echo "✅ Polygon-Edge initialization complete!"

edge-up: ## Start Polygon-Edge network (3 validators + RPC node)
	@echo "🚀 Starting Polygon-Edge network..."
	@docker-compose -f docker/docker-compose.edge.yml up -d
	@echo "✅ Polygon-Edge network running!"
	@echo "   RPC: http://localhost:8545"
	@echo "   Chain ID: 7777"
	@echo ""
	@echo "Run 'make test-rpc' to verify"

edge-down: ## Stop Polygon-Edge network
	@echo "⏹️  Stopping Polygon-Edge network..."
	@docker-compose -f docker/docker-compose.edge.yml down
	@echo "✅ Polygon-Edge network stopped"

edge-logs: ## View Polygon-Edge logs (all containers)
	@docker-compose -f docker/docker-compose.edge.yml logs -f

edge-clean: ## Remove Polygon-Edge data and keys (DESTRUCTIVE)
	@echo "⚠️  WARNING: This will delete all Polygon-Edge blockchain data and keys!"
	@read -p "Press Enter to continue or Ctrl+C to cancel..."
	@docker-compose -f docker/docker-compose.edge.yml down -v
	@rm -rf data/edge-* scripts/keys/edge
	@echo "✅ Polygon-Edge data cleaned"

edge-restart: edge-down edge-up ## Restart Polygon-Edge network

##@ Testing & Utilities

test-rpc: ## Test RPC endpoint (check chain ID)
	@echo "🔍 Testing RPC at http://localhost:8545..."
	@curl -s -X POST http://localhost:8545 \
		-H "Content-Type: application/json" \
		-d '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' \
		| grep -q "0x1e61" && echo "✅ RPC is responding! Chain ID: 7777 (0x1e61)" \
		|| (echo "❌ RPC test failed. Is the network running? Try 'make besu-up' or 'make edge-up'" && exit 1)

test-block: ## Get latest block number
	@echo "📊 Fetching latest block number..."
	@curl -s -X POST http://localhost:8545 \
		-H "Content-Type: application/json" \
		-d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'
	@echo ""

test-peers: ## Check peer count
	@echo "👥 Checking peer count..."
	@curl -s -X POST http://localhost:8545 \
		-H "Content-Type: application/json" \
		-d '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}'
	@echo ""

ps: ## Show running containers
	@docker ps --filter "name=besu" --filter "name=edge" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

##@ Cleanup

clean-all: ## Stop all networks and remove ALL data (DESTRUCTIVE)
	@echo "⚠️  WARNING: This will stop all networks and delete ALL data!"
	@read -p "Press Enter to continue or Ctrl+C to cancel..."
	@docker-compose -f docker/docker-compose.besu.yml down -v 2>/dev/null || true
	@docker-compose -f docker/docker-compose.edge.yml down -v 2>/dev/null || true
	@rm -rf data/ scripts/keys/
	@echo "✅ All data cleaned"

##@ Development

dev-container: ## Open VS Code Dev Container
	@code .
	@echo "💡 Reopen in container: Ctrl+Shift+P → 'Dev Containers: Reopen in Container'"

docs: ## Open documentation in browser
	@echo "📚 Opening documentation..."
	@start WELCOME.md || open WELCOME.md || xdg-open WELCOME.md

##@ Docker Management

docker-prune: ## Prune unused Docker resources
	@echo "🧹 Pruning unused Docker resources..."
	@docker system prune -f
	@echo "✅ Docker cleanup complete"

docker-logs-besu: ## Follow logs for specific Besu validator
	@docker logs -f besu-validator-0

docker-logs-edge: ## Follow logs for specific Edge validator
	@docker logs -f edge-validator-1
