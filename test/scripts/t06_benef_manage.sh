#!/bin/sh -ex

checkVal(){
    ethester call @run/Beneficiary.addr Beneficiary.beneficiary --expect $1
    ethester call @run/PrivateSale.addr PrivateSale.beneficiary --expect $1
    ethester call @run/PreSale.addr PreSale.beneficiary --expect $1
    ethester call @run/MainSale.addr MainSale.beneficiary --expect $1
}

echo "Check initial value"
checkVal @run/owner.addr

echo "Create new account - custom beneficiary address"
BENEF=`ethester new-account -s`

echo "Change initial beneficiary value"
ethester tran @run/owner.addr @run/Beneficiary.addr Beneficiary.setBeneficiary $BENEF
echo "check the value was changed"
checkVal $BENEF

echo "create new foe account and populate it with some ether"
FOE=`ethester new-account -s`
ethester send @run/owner.addr $FOE 1ether

echo "try change again as foe - this will fail"
ethester tran $FOE @run/Beneficiary.addr Beneficiary.setBeneficiary $FOE
echo "check the mint agent was not changed"
checkVal $BENEF

echo "now change as owner - this will succeed"
ethester tran @run/owner.addr @run/Beneficiary.addr Beneficiary.setBeneficiary @run/owner.addr
echo "check the value is equals to owner again"
checkVal @run/owner.addr
