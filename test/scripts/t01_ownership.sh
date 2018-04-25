#!/bin/sh -ex

OWNER1="@run/owner.addr"
OWNER2="@run/owner2.addr"

# create new owner and send some ether to it
ethester new-account -s > run/owner2.addr
ethester send @run/owner.addr @run/owner2.addr 3ether
for i in WPTokensBaskets Token Beneficiary PrivateSale PreSale MainSale; do
    # Check initial owner
    ethester call @run/$i.addr $i.owner -e $OWNER1
    # Change initial owner
    ethester tran $OWNER1 @run/$i.addr $i.setOwner $OWNER2
    # check the owner was changed to owner2
    ethester call @run/$i.addr $i.owner -e $OWNER2
    # try change again as owner1 - this will fail
    ethester tran $OWNER1 @run/$i.addr $i.setOwner $OWNER1
    # check the owner was not changed
    ethester call @run/$i.addr $i.owner -e $OWNER2
    # now change the owner as owner2 - this will succeed
    ethester tran $OWNER2 @run/$i.addr $i.setOwner $OWNER1
    # check the owner is owner1 again
    ethester call @run/$i.addr $i.owner -e $OWNER1
done
# Stop the miner
ethester exec 'miner.stop()' true
