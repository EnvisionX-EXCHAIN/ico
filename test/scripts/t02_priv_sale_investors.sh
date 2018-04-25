#!/bin/sh -ex

# create new investor account and populate it with some ether
INVESTOR=`ethester new-account -s`
ethester send @run/owner.addr $INVESTOR 3ether
ethester call @run/PrivateSale.addr PrivateSale.isInvestorAllowed $INVESTOR -e false
# register investor
ethester tran @run/owner.addr @run/PrivateSale.addr PrivateSale.allowInvestor $INVESTOR
ethester call @run/PrivateSale.addr PrivateSale.isInvestorAllowed $INVESTOR -e true
# try to de-register investor from not owner account (will fail)
ethester tran $INVESTOR @run/PrivateSale.addr PrivateSale.denyInvestor $INVESTOR
ethester call @run/PrivateSale.addr PrivateSale.isInvestorAllowed $INVESTOR -e true
# de-register investor
ethester tran @run/owner.addr @run/PrivateSale.addr PrivateSale.denyInvestor $INVESTOR
ethester call @run/PrivateSale.addr PrivateSale.isInvestorAllowed $INVESTOR -e false
# try to register investor from not owner account (will fail)
ethester tran $INVESTOR @run/PrivateSale.addr PrivateSale.allowInvestor $INVESTOR
ethester call @run/PrivateSale.addr PrivateSale.isInvestorAllowed $INVESTOR -e false
