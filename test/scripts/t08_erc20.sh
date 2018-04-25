#!/bin/sh -ex

echo "create new investor account and populate it with some ether"
INVESTOR=`ethester new-account -s`
ethester send @run/owner.addr $INVESTOR 3ether
ethester tran @run/owner.addr @run/PrivateSale.addr PrivateSale.allowInvestor $INVESTOR

echo "send some ether to basket accounts"
ethester send @run/owner.addr @run/team.addr       100finney
ethester send @run/owner.addr @run/foundation.addr 100finney
ethester send @run/owner.addr @run/arr.addr        100finney
ethester send @run/owner.addr @run/advisors.addr   100finney
ethester send @run/owner.addr @run/bounty.addr     100finney

echo "create some new accounts which will be used to transfer tokens"
Holder1=`ethester new-account -s`
ethester send @run/owner.addr $Holder1 100finney
Holder2=`ethester new-account -s`
ethester send @run/owner.addr $Holder2 100finney

echo "Set mint agent to PrivateSale"
ethester tran @run/owner.addr @run/Token.addr Token.setMintAgent @run/PrivateSale.addr
ethester call @run/Token.addr Token.mintAgent --expect @run/PrivateSale.addr

echo "create beneficiary account"
BENEFICIARY=`ethester new-account -s`
ethester tran @run/owner.addr @run/Beneficiary.addr Beneficiary.setBeneficiary $BENEFICIARY

echo "purchase some tokens"
export ETHESTER_GAS_LIMIT=500000
ethester send $INVESTOR @run/PrivateSale.addr 1ether
echo "check amount of minted tokens"
ethester call @run/Token.addr Token.totalSupply --expect-gt 0 > run/supply
ethester call @run/Token.addr Token.balanceOf $INVESTOR --expect-gt 0 > run/tokens
ethester balance $BENEFICIARY --expect 1ether

echo "Finish minting"
ethester tran @run/owner.addr @run/Token.addr Token.finishMinting

echo "purchase again - must fail"
ethester send $INVESTOR @run/PrivateSale.addr 1ether
echo "check amount of minted tokens"
ethester call @run/Token.addr Token.totalSupply --expect @run/supply
ethester call @run/Token.addr Token.balanceOf $INVESTOR --expect @run/tokens
ethester balance $BENEFICIARY --expect 1ether

## ------------------------------------------------------------
## Main test

set +x

## Usage: $0 ACCOUNT -> EXT
erc20_balance(){
    ethester call @run/Token.addr Token.balanceOf $1
}

## Usage: $0 ACCOUNT VALUE_EXT
assertBalance(){
    echo "Assert balance of $1 is $2 EXT..."
    ethester call @run/Token.addr Token.balanceOf $1 --expect $2
}

## Usage: $0 FROM TO VALUE SUCCESS
erc20_transfer(){
    echo "Check transfer of $3 EXT from $1 to $2 - must $4..."
    B1=`erc20_balance "$1"`
    B2=`erc20_balance "$2"`
    ethester tran $1 @run/Token.addr Token.transfer $2 $3
    if [ "$4" = "FAIL" ]; then
        assertBalance $1 $B1
        assertBalance $2 $B2
        return 0
    fi
    EXPECT=`python -c "print $B2 + $3"`
    assertBalance $2 $EXPECT
}

## Usage: $0 SENDER FROM TO VALUE SUCCESS
erc20_transferFrom(){
    echo "Check transfer of $4 EXT from $2 to $3 - must $5..."
    B1=`erc20_balance "$2"`
    B2=`erc20_balance "$3"`
    ethester tran $1 @run/Token.addr Token.transferFrom $2 $3 $4
    if [ "$5" = "FAIL" ]; then
        assertBalance $2 $B1
        assertBalance $3 $B2
        return 0
    fi
    EXPECT=`python -c "print $B2 + $4"`
    assertBalance $3 $EXPECT
}

## Usage: $0 FROM TO VALUE
erc20_approve(){
    echo "Approve $2 to send $3 EXT"
    ethester tran $1 @run/Token.addr Token.approve $2 $3
}

assertBalance $Holder1 0
erc20_transfer @run/team.addr $Holder1 100 FAIL

erc20_transfer @run/foundation.addr $Holder1 100 FAIL

erc20_transfer @run/arr.addr $Holder1 100 OK

erc20_transfer $Holder1 $Holder2 50 OK
assertBalance $Holder1 50
assertBalance $Holder2 50

erc20_transferFrom $Holder2 $Holder1 $Holder2 10 FAIL
erc20_approve $Holder1 $Holder2 25
erc20_transferFrom $Holder2 $Holder1 $Holder2 10 OK
erc20_transferFrom $Holder2 $Holder1 $Holder2 10 OK
erc20_transferFrom $Holder2 $Holder1 $Holder2 10 FAIL
erc20_transferFrom $Holder2 $Holder1 $Holder2 5 OK
erc20_transferFrom $Holder2 $Holder1 $Holder2 5 FAIL

assertBalance $Holder1 25
assertBalance $Holder2 75
