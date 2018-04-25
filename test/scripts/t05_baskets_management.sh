#!/bin/sh -ex

chkField(){
    GETTER="$1"
    SETTER="$2"
    # these addresses will be used as baskets
    A1=`ethester new-account -s`
    A2=`ethester new-account -s`
    echo "create new foe account and populate it with some ether"
    FOE=`ethester new-account -s`
    ethester send @run/owner.addr $FOE 1ether
    echo "change basket as owner - legal"
    ethester tran @run/owner.addr @run/WPTokensBaskets.addr WPTokensBaskets.$SETTER $A1
    ethester call @run/WPTokensBaskets.addr WPTokensBaskets.$GETTER --expect $A1
    echo "change basket as not owner - illegal"
    ethester tran $FOE @run/WPTokensBaskets.addr WPTokensBaskets.$SETTER $A2
    ethester call @run/WPTokensBaskets.addr WPTokensBaskets.$GETTER --expect $A1
    echo "change basket as owner - legal"
    ethester tran @run/owner.addr @run/WPTokensBaskets.addr WPTokensBaskets.$SETTER $A2
    ethester call @run/WPTokensBaskets.addr WPTokensBaskets.$GETTER --expect $A2
    echo "change basket to already known address - illegal"
    ethester tran @run/owner.addr @run/WPTokensBaskets.addr WPTokensBaskets.$SETTER $A1
    ethester call @run/WPTokensBaskets.addr WPTokensBaskets.$GETTER --expect $A2
}

chkField team       setTeam
chkField foundation setFoundation
chkField arr        setARR
chkField advisors   setAdvisors
chkField bounty     setBounty
