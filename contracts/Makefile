include .env

.env:
	@cp .env.sample .env

build:
	@forge build

.PHONY: test
test:
	@forge test

testv:
	@forge test -vv

watch:
	@forge test -w

watchv:
	@forge test -w -vv

dry_deploy:
	@forge script script/Dexterity.s.sol --rpc-url sepolia

sepolia_deploy:
	@forge script script/Dexterity.s.sol --rpc-url sepolia --broadcast --verify
