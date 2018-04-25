TESTS = \
	t01_ownership \
	t02_priv_sale_investors \
	t03_priv_sale_purchase \
	t04_mint_agent_setup \
	t05_baskets_management \
	t06_benef_manage \
	t07_token_freeze \
	t08_erc20

.PHONY: all blockchain deployAll attach clean $(TESTS)

all: $(TESTS)
	@echo "\n*** DONE ***\n"

export ETHESTER_GETH_IPC = run/geth.ipc
export ETHESTER_CONTRACT_PATH = ../build
export ETHESTER_DUMP_DIR = run
export ETHESTER_LOGLEVEL = info

## --------------------------------------------------------------------
## Tests

## Check contracts ownership logic
t01_ownership:
	@echo "\n*** TEST $@ ***\n"
	$(MAKE) blockchain
	$(MAKE) deployAll
	scripts/t01_ownership.sh

## Check investors white list for PrivateSale
t02_priv_sale_investors:
	@echo "\n*** TEST $@ ***\n"
	$(MAKE) blockchain
	$(MAKE) deployAll
	scripts/t02_priv_sale_investors.sh

## Check PrivateSale purchase logic
t03_priv_sale_purchase:
	@echo "\n*** TEST $@ ***\n"
	$(MAKE) blockchain
	$(MAKE) deployAll
	scripts/t03_priv_sale_purchase.sh

## Check min agent management logic
t04_mint_agent_setup:
	@echo "\n*** TEST $@ ***\n"
	$(MAKE) blockchain
	$(MAKE) deployAll
	scripts/t04_mint_agent_setup.sh

## Check baskets management logic
t05_baskets_management:
	@echo "\n*** TEST $@ ***\n"
	$(MAKE) blockchain
	$(MAKE) deployAll
	scripts/t05_baskets_management.sh

## Check beneficiary management logic
t06_benef_manage:
	@echo "\n*** TEST $@ ***\n"
	$(MAKE) blockchain
	$(MAKE) deployAll
	scripts/t06_benef_manage.sh

## Check tokens freeze logic
t07_token_freeze:
	@echo "\n*** TEST $@ ***\n"
	$(MAKE) blockchain
	$(MAKE) deployAll
	scripts/t07_token_freeze.sh

## Check ERC20 interface
t08_erc20:
	@echo "\n*** TEST $@ ***\n"
	$(MAKE) blockchain
	$(MAKE) deployAll
	scripts/t08_erc20.sh

## --------------------------------------------------------------------
## Service targets

# Deploy all contracts and check their initial consistency
deployAll:
	# Create backup owner account with empty password
	ethester new-account -s > run/backup-owner.addr
	# Create team address with empty password (for EXT tokens)
	ethester new-account -s > run/team.addr
	# Create foundation address with empty password (for EXT tokens)
	ethester new-account -s > run/foundation.addr
	# Create referral address with empty password (for EXT tokens)
	ethester new-account -s > run/arr.addr
	# Create advisor address with empty password (for EXT tokens)
	ethester new-account -s > run/advisors.addr
	# Create bounty address with empty password (for EXT tokens)
	ethester new-account -s > run/bounty.addr
	# Deploy contracts
	ethester deploy -s @run/owner.addr WPTokensBaskets \
		@run/team.addr @run/foundation.addr @run/arr.addr \
		@run/advisors.addr @run/bounty.addr > run/WPTokensBaskets.addr
	ethester deploy -s @run/owner.addr Token \
		@run/WPTokensBaskets.addr > run/Token.addr
	ethester deploy -s @run/owner.addr Beneficiary > run/Beneficiary.addr
	ethester deploy -s @run/owner.addr PrivateSale \
		@run/Token.addr @run/Beneficiary.addr > run/PrivateSale.addr
	ethester deploy -s @run/owner.addr PreSale \
		@run/Token.addr @run/Beneficiary.addr \
		@run/PrivateSale.addr > run/PreSale.addr
	ethester deploy -s @run/owner.addr MainSale \
		@run/Token.addr @run/Beneficiary.addr @run/PreSale.addr \
		> run/MainSale.addr
	# Check WPTokensBaskets contract key fields
	ethester call @run/WPTokensBaskets.addr WPTokensBaskets.team       -e @run/team.addr
	ethester call @run/WPTokensBaskets.addr WPTokensBaskets.foundation -e @run/foundation.addr
	ethester call @run/WPTokensBaskets.addr WPTokensBaskets.arr        -e @run/arr.addr
	ethester call @run/WPTokensBaskets.addr WPTokensBaskets.advisors   -e @run/advisors.addr
	ethester call @run/WPTokensBaskets.addr WPTokensBaskets.bounty     -e @run/bounty.addr
	# Check Token contract key fields
	ethester call @run/Token.addr Token.mintAgent       -e @run/owner.addr
	ethester call @run/Token.addr Token.name            -e 'EnvisionX EXCHAIN Token'
	ethester call @run/Token.addr Token.symbol          -e EXT
	ethester call @run/Token.addr Token.decimals        -e 18
	ethester call @run/Token.addr Token.wpTokensBaskets -e @run/WPTokensBaskets.addr
	# Check Beneficiary contract key fields
	ethester call @run/Beneficiary.addr Beneficiary.beneficiary -e @run/owner.addr
	# Check PrivateSale contract key fields
	ethester call @run/PrivateSale.addr PrivateSale.beneficiary -e @run/owner.addr
	# Check PreSale contract key fields
	ethester call @run/PreSale.addr PreSale.beneficiary -e @run/owner.addr
	# Check MainSale contract key fields
	ethester call @run/MainSale.addr MainSale.beneficiary -e @run/owner.addr

## Setup brand new blockchain and new account with some ether.
## Account address is written to run/owner.addr
blockchain: clean
	mkdir -p run/data
	nohup geth --datadir=run --dev --rpc >> run/geth.log 2>&1 & \
		echo $$! > run/pid
	sleep 3s # warming up
	# Start miner and mine some ether...
	ethester exec "miner.start()" null
	sleep 5s
	# Save account address
	ethester exec 'eth.accounts[0]' -s > run/owner.addr
	ethester balance @run/owner.addr --expect-gt 3ether

attach:
	geth attach run/geth.ipc

clean:
	test -f run/pid && kill -9 `cat run/pid` || true
	rm -rf run
