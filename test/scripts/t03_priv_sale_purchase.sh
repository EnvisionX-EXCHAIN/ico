#!/bin/sh -ex

echo "Compile MultiSigWallet"
make -C .. multisig
echo "Deploy MultiSigWallet"
export ETHESTER_CONTRACT_PATH="$ETHESTER_CONTRACT_PATH:../MultiSigWallet/build"
ethester deploy @run/owner.addr MultiSigWallet '[]' 0 -s > run/multisig.addr

echo "create new investor account and populate it with some ether"
INVESTOR=`ethester new-account -s`
ethester send @run/owner.addr $INVESTOR 3ether
ethester balance $INVESTOR -e 3ether
ethester tran @run/owner.addr @run/PrivateSale.addr PrivateSale.allowInvestor $INVESTOR
ethester call @run/PrivateSale.addr PrivateSale.isInvestorAllowed $INVESTOR -e true

echo "create new foe account and populate it with some ether"
FOE=`ethester new-account -s`
ethester send @run/owner.addr $FOE 3ether
ethester balance $FOE -e 3ether

echo "Set mint agent to PrivateSale"
ethester tran @run/owner.addr @run/Token.addr Token.setMintAgent @run/PrivateSale.addr
ethester call @run/Token.addr Token.mintAgent -e @run/PrivateSale.addr

echo "Set beneficiary address (by default it equals to OWNER) to multisig wallet"
ethester tran @run/owner.addr @run/Beneficiary.addr Beneficiary.setBeneficiary @run/multisig.addr
ethester call @run/Beneficiary.addr Beneficiary.beneficiary -e @run/multisig.addr

# Initial checks:
ethester call @run/Token.addr Token.totalSupply -e 0
ethester balance @run/multisig.addr -e 0

echo "try to purchase (not white listed - will fail)"
ETHESTER_GAS_LIMIT=500000 ethester send $FOE @run/PrivateSale.addr 1ether
echo "check amount of minted tokens"
ethester call @run/Token.addr Token.totalSupply -e 0
ethester balance $FOE --expect-lt 3ether --expect-gt 2ether # gas used
ethester balance @run/multisig.addr -e 0

echo "try to purchase some tokens but supply too few gas - will fail"
ETHESTER_GAS_LIMIT=400000 ethester send $INVESTOR @run/PrivateSale.addr 1ether
echo "check amount of minted tokens"
ethester call @run/Token.addr Token.totalSupply -e 0
ethester call @run/Token.addr Token.balanceOf $INVESTOR -e 0
ethester balance $INVESTOR --expect-lt 3ether --expect-gt 2ether
ethester balance @run/multisig.addr -e 0

echo "purchase some tokens"
ETHESTER_GAS_LIMIT=500000 ethester send $INVESTOR @run/PrivateSale.addr 1ether
echo "check amount of minted tokens"
ethester call @run/Token.addr Token.totalSupply --expect-gt 0
ethester call @run/Token.addr Token.balanceOf $INVESTOR --expect-gt 0
ethester balance @run/multisig.addr -e 1ether
ethester balance $INVESTOR --expect-lt 2ether --expect-gt 1ether

echo "change beneficiary and purchase again"
BENEF=`ethester new-account -s`
ethester tran @run/owner.addr @run/Beneficiary.addr Beneficiary.setBeneficiary $BENEF
ETHESTER_GAS_LIMIT=500000 ethester send $INVESTOR @run/PrivateSale.addr 1ether
ethester balance @run/multisig.addr --expect 1ether
ethester balance $BENEF --expect 1ether
