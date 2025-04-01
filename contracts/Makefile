MAKEFILE_DIR := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))

include $(MAKEFILE_DIR)/.env

$(MAKEFILE_DIR)/.env:
	@cd $(MAKEFILE_DIR) && cp .env.sample .env

build:
	@cd $(MAKEFILE_DIR) \
		&& git submodule update --init --recursive \
		&& forge build

.PHONY: test
test:
	@cd $(MAKEFILE_DIR) && forge test

testv:
	@cd $(MAKEFILE_DIR) && forge test -vvv

watch:
	@cd $(MAKEFILE_DIR) && forge test -w

watchv:
	@cd $(MAKEFILE_DIR) && forge test -w -vvv

coverage:
	@cd $(MAKEFILE_DIR) && forge coverage

run_local_blockchain: .anvil.pid
	@cd $(MAKEFILE_DIR) && [ -z "$$(pidof anvil)" ] && rm .anvil.pid && $(MAKE) .anvil.pid || return 0
	@cd $(MAKEFILE_DIR) && echo $$(pidof anvil) > .anvil.pid

kill_local_blockchain:
	@cd $(MAKEFILE_DIR) && [ -f .anvil.pid ] && kill "$$(cat .anvil.pid)" && rm .anvil.pid || echo "nothing to kill"

local_deploy: run_local_blockchain
	@cd $(MAKEFILE_DIR) \
		&& while true; do \
		forge script script/LocalDeploy.s.sol \
		  --private-key '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80' \
		  --rpc-url local \
		  --broadcast \
		&& break || sleep 1; done

run: script=
run: build
	@cd $(MAKEFILE_DIR) && [ -z "$${script}" ] \
		&& echo 'You have to specify a script name' \
		&& exit 1 \
		|| exit 0
	@cd $(MAKEFILE_DIR) && [ ! -f "script/$${script}.s.sol" ] \
		&& echo "Unexisting script: script/$${script}.s.sol" \
		&& exit 1 \
		|| exit 0
	@cd $(MAKEFILE_DIR) && $(MAKE) local_deploy \
		&& forge script "script/$${script}.s.sol" \
		  --private-key '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80' \
		  --rpc-url local \
		  --broadcast


.anvil.pid:
	@cd $(MAKEFILE_DIR) \
		&& [ -z "$$(pidof anvil)" ] && \
		anvil \
		  --accounts 1 \
		  --mnemonic 'test test test test test test test test test test test junk' \
			--fork-url mainnet \
			--fork-block-number "${MAINNET_FORK_BLOCK}" \
			--host "${ANVIL_HOST}" --port "${ANVIL_PORT}" \
			--hardfork "${ANVIL_EVM_VERSION}" \
			& echo $$!>.anvil.pid || \
		echo $$(pidof anvil) > .anvil.pid

sepolia_deploy:
	cd $(MAKEFILE_DIR) && @forge script script/SepoliaDeploy.s.sol --rpc-url sepolia --broadcast --verify
