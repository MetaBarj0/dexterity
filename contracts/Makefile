include .env

.env:
	@cp .env.sample .env

build:
	@git submodule update --init --recursive
	@forge build

.PHONY: test
test:
	@forge test

testv:
	@forge test -vvv

watch:
	@forge test -w

watchv:
	@forge test -w -vvv

coverage:
	@forge coverage

run_local_blockchain: .anvil.pid
	@[ -z "$$(pidof anvil)" ] && rm .anvil.pid && $(MAKE) .anvil.pid || return 0
	@echo $$(pidof anvil) > .anvil.pid

kill_local_blockchain:
	@[ -f .anvil.pid ] && kill "$$(cat .anvil.pid)" && rm .anvil.pid || echo "nothing to kill"

local_deploy: run_local_blockchain
	@while true; do forge script script/DeployDexterity.s.sol --rpc-url local --broadcast && break || sleep 1; done

sepolia_deploy:
	@forge script script/DeployDexterity.s.sol --rpc-url sepolia --broadcast --verify

.anvil.pid:
	@[ -z "$$(pidof anvil)" ] && \
		anvil \
			--fork-url mainnet \
			--fork-block-number "${MAINNET_FORK_BLOCK}" \
			--host "${ANVIL_HOST}" --port "${ANVIL_PORT}" \
			--hardfork "${ANVIL_EVM_VERSION}" \
			& echo $$!>.anvil.pid || \
		echo $$(pidof anvil) > .anvil.pid

