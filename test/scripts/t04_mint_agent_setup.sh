#!/bin/sh -ex

echo "Check initial value"
ethester call @run/Token.addr Token.mintAgent --expect @run/owner.addr

echo "Create new account - custom mint agent address"
MAGENT=`ethester new-account -s`

echo "Change initial mint agent value"
ethester tran @run/owner.addr @run/Token.addr Token.setMintAgent $MAGENT
echo "check the value was changed"
ethester call @run/Token.addr Token.mintAgent --expect $MAGENT

echo "create new foe account and populate it with some ether"
FOE=`ethester new-account -s`
ethester send @run/owner.addr $FOE 1ether

echo "try change again as foe - this will fail"
ethester tran $FOE @run/Token.addr Token.setMintAgent $FOE
echo "check the mint agent was not changed"
ethester call @run/Token.addr Token.mintAgent --expect $MAGENT

echo "now change as owner - this will succeed"
ethester tran @run/owner.addr @run/Token.addr Token.setMintAgent @run/owner.addr
echo "check the value is equals to owner again"
ethester call @run/Token.addr Token.mintAgent --expect @run/owner.addr
