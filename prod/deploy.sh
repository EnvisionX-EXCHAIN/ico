#!/bin/sh -e

##
## Deploy and setup EnvisionX contracts.
##

# Check args
if [ -z "$1" ]; then
    echo "Usage: $0 CONFIG_FILE" 1>&2
    exit 1
fi

# Load config file
. `readlink -f "$1"`

# Variables below are used in helper scripts:
export ETHESTER_GETH_IPC
export ETHESTER_CONTRACT_PATH=../build
export ETHESTER_ACCOUNT_PASSWORD
export ETHESTER_GAS_PRICE
export ETHESTER_GAS_LIMIT
export ETHESTER_LOGLEVEL=info
# Average block time in Rinkeby network is ~15 seconds
export ETHESTER_TIMEOUT=300

rm -rf run
mkdir -p run

## ------------------------------------------------------------
## Utility functions

# Usage: log MESSAGE
log(){
    echo `date '+%F %T'` "$@"
}

## ------------------------------------------------------------
## Here live dragons

log "Compiling the source"
make -s -C ../ all

log "Deploy WPTokensBaskets"
ethester -v deploy -s $OWNER WPTokensBaskets \
    $TEAM_BASKET $FOUNDATION_BASKET $ARR_BASKET \
    $ADVISORS_BASKET $BOUNTY_BASKET \
    > run/WPTokensBaskets.addr
ethester call -q @run/WPTokensBaskets.addr WPTokensBaskets.owner      --expect $OWNER
ethester call -q @run/WPTokensBaskets.addr WPTokensBaskets.team       --expect $TEAM_BASKET
ethester call -q @run/WPTokensBaskets.addr WPTokensBaskets.foundation --expect $FOUNDATION_BASKET
ethester call -q @run/WPTokensBaskets.addr WPTokensBaskets.arr        --expect $ARR_BASKET
ethester call -q @run/WPTokensBaskets.addr WPTokensBaskets.advisors   --expect $ADVISORS_BASKET
ethester call -q @run/WPTokensBaskets.addr WPTokensBaskets.bounty     --expect $BOUNTY_BASKET

log "Deploy Token"
ethester -v deploy -s $OWNER Token @run/WPTokensBaskets.addr > run/Token.addr
ethester call -q @run/Token.addr Token.owner           --expect $OWNER
ethester call -q @run/Token.addr Token.mintAgent       --expect $OWNER
ethester call -q @run/Token.addr Token.name            --expect "EnvisionX EXCHAIN Token"
ethester call -q @run/Token.addr Token.symbol          --expect "EXT"
ethester call -q @run/Token.addr Token.decimals        --expect 18
ethester call -q @run/Token.addr Token.wpTokensBaskets --expect @run/WPTokensBaskets.addr

log "Deploy Beneficiary"
ethester -v deploy -s $OWNER Beneficiary > run/Beneficiary.addr
ethester call -q @run/Beneficiary.addr Beneficiary.owner       --expect $OWNER
ethester call -q @run/Beneficiary.addr Beneficiary.beneficiary --expect $OWNER

log "Deploy PrivateSale"
ethester -v deploy -s $OWNER PrivateSale \
    @run/Token.addr @run/Beneficiary.addr \
    > run/PrivateSale.addr
ethester call -q @run/PrivateSale.addr PrivateSale.owner       --expect $OWNER
ethester call -q @run/PrivateSale.addr PrivateSale.token       --expect @run/Token.addr
ethester call -q @run/PrivateSale.addr PrivateSale.beneficiary --expect $OWNER

if [ -n "$BENEFICIARY" ]; then
    log "Setting beneficiary to $BENEFICIARY"
    ethester tran $OWNER @run/Beneficiary.addr Beneficiary.setBeneficiary $BENEFICIARY
    ethester call -q @run/Beneficiary.addr Beneficiary.beneficiary --expect $BENEFICIARY
    ethester call -q @run/PrivateSale.addr PrivateSale.beneficiary --expect $BENEFICIARY
else
    BENEFICIARY="$OWNER"
fi

log "Setting mint agent to PrivateSale (`cat run/PrivateSale.addr`)"
ethester tran $OWNER @run/Token.addr Token.setMintAgent @run/PrivateSale.addr
ethester call -q @run/Token.addr Token.mintAgent --expect @run/PrivateSale.addr

for i in WPTokensBaskets Token Beneficiary PrivateSale; do
    ethester tran $OWNER @run/$i.addr $i.setOwner $NEW_OWNER
    ethester call -q @run/$i.addr $i.owner --expect $NEW_OWNER
done

set +x
log "All checks passed.
Deployed contracts are:
   WPTokensBaskets        `cat run/WPTokensBaskets.addr`
   Token                  `cat run/Token.addr`
   Beneficiary            `cat run/Beneficiary.addr`
   PrivateSale            `cat run/PrivateSale.addr`

Related accounts:
   Owner                  $NEW_OWNER
   Beneficiary            $BENEFICIARY
   Mint Agent             `cat run/PrivateSale.addr`

Baskets:
   Team                   $TEAM_BASKET
   Foundation             $FOUNDATION_BASKET
   Referral               $ARR_BASKET
   Advisors               $ADVISORS_BASKET
   Bounty                 $BOUNTY_BASKET
"
