.PHONY: all build multisig docs clean test gist

all: build

build:
	mkdir -p build
	solc -o build --bin --abi --overwrite contracts/*.sol

multisig:
	mkdir -p MultiSigWallet/build
	solc -o MultiSigWallet/build --bin --abi --overwrite MultiSigWallet/contracts/*.sol

docs:
	$(MAKE) -C docs

clean:
	rm -rf build MultiSigWallet/build gist
	$(MAKE) -C docs $@
	$(MAKE) -C test $@
	$(MAKE) -C rinkeby $@

test: clean all
	$(MAKE) -C test

gist:
	mkdir -p gist
	echo 'pragma solidity ^0.4.20;' > gist/EnvisionX_EXCHAIN_Token.sol
	cat contracts/GenesisProtected.sol contracts/Ownable.sol \
		contracts/ERC20Interface.sol \
		contracts/Enums.sol contracts/WPTokensBaskets.sol \
		contracts/SafeMath.sol contracts/Token.sol | \
		egrep -v ^import | egrep -v ^pragma >> gist/EnvisionX_EXCHAIN_Token.sol
	echo 'pragma solidity ^0.4.20;' > gist/EnvisionX_WPBaskets.sol
	cat contracts/GenesisProtected.sol contracts/Ownable.sol \
		contracts/Enums.sol contracts/WPTokensBaskets.sol |\
		egrep -v ^import | egrep -v ^pragma >> gist/EnvisionX_WPBaskets.sol
	echo 'pragma solidity ^0.4.20;' > gist/EnvisionX_Beneficiary.sol
	cat contracts/GenesisProtected.sol contracts/Ownable.sol \
		contracts/Killable.sol contracts/Beneficiary.sol |\
		egrep -v ^import | egrep -v ^pragma >> gist/EnvisionX_Beneficiary.sol
	echo 'pragma solidity ^0.4.20;' > gist/EnvisionX_PrivateSale.sol
	cat contracts/GenesisProtected.sol contracts/Ownable.sol \
		contracts/Enums.sol contracts/WPTokensBaskets.sol \
		contracts/SafeMath.sol contracts/ERC20Interface.sol contracts/Token.sol \
		contracts/Killable.sol contracts/Beneficiary.sol \
		contracts/TokenSale.sol contracts/PrivateSale.sol |\
		egrep -v ^import | egrep -v ^pragma >> gist/EnvisionX_PrivateSale.sol
	for i in contracts/*.sol; do \
	   echo $$i | egrep -w -q 'PreSale|MainSale' && continue; \
	   cat $$i; \
	done | egrep -v ^import | egrep -v ^pragma > gist/EXCHAIN_TokenSale.sol
