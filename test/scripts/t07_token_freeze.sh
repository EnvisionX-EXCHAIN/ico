#!/bin/sh

## Since we refactored Token contract and isFrozenPure() function
## doesn't exist anymore, disable this test.
## See commit f8d7f511d15fa4c8966c7bd4399f95fcf23390bb
exit 0

Token=`cat run/Token.addr`

## Arguments:
##   1. MINTING_FINISHED - true/false;
##   2. MINTING_FINISHED_DATE - date&time when minting was finished;
##   3. CURRENT_DATE      - current date&time;
##   4. BASKET_TYPE       - 0..7 (according to Enums.BasketType);
##   5. TEAM_TOTAL_MINTED - total amount of EXTwei minted for team;
##   6. TEAM_SPENT      - amount of EXTwei already spent by team;
##   7. TOKENS_VALUE    - amount of EXTwei to transfer;
##   8. EXPECTED_RETURN - true/false.
checkFreeze(){
    echo "Check Token.isFrozenPure($1,$2,$3,$4,$5,$6,$7) is $8..."
    A2=`date -u -d "$2" +%s`
    A3=`date -u -d "$3" +%s`
    CALL="isFrozenPure($1,$A2,$A3,$4,$5,$6,$7)"
    echo "ret=contract.$CALL;" | bin/withContractAssert.sh Token $Token "$8"
    if [ "$?" != 0 ]; then
        echo "  real call was: Token.$CALL;" 1>&2
        exit 1
    fi
}

## Return unix timestamp of given week since Unix Epoch
week(){
    echo "@`expr $1 \* 604800`"
}

echo "\n*** Team: Veeeery small fractions ***\n"
checkFreeze true '@0' `week 24` 1 100 0 25 false
checkFreeze true '@0' `week 24` 1 1000 0 250 false
checkFreeze true '@0' `week 24` 1 10000 0 2500 false
checkFreeze true '@0' `week 24` 1 100000 0 25000 false
checkFreeze true '@0' `week 24` 1 1000000 0 250000 false
checkFreeze true '@0' `week 24` 1 10000000 0 2500000 false
checkFreeze true '@0' `week 24` 1 100000000 0 25000000 false
checkFreeze true '@0' `week 24` 1 1000000000 0 250000000 false
checkFreeze true '@0' `week 24` 1 10000000000 0 2500000000 false
checkFreeze true '@0' `week 24` 1 100000000000 0 25000000000 false
checkFreeze true '@0' `week 24` 1 1000000000000 0 250000000000 false
checkFreeze true '@0' `week 24` 1 100 25 1 true
checkFreeze true '@0' `week 24` 1 1000 250 1 true
checkFreeze true '@0' `week 24` 1 10000 2500 1 true
checkFreeze true '@0' `week 24` 1 100000 25000 1 true
checkFreeze true '@0' `week 24` 1 1000000 250000 1 true
checkFreeze true '@0' `week 24` 1 10000000 2500000 1 true
checkFreeze true '@0' `week 24` 1 100000000 25000000 1 true
checkFreeze true '@0' `week 24` 1 1000000000 250000000 1 true
checkFreeze true '@0' `week 24` 1 10000000000 2500000000 1 true
checkFreeze true '@0' `week 24` 1 100000000000 25000000000 1 true
checkFreeze true '@0' `week 24` 1 1000000000000 250000000000 1 true

echo "\n*** Minting is in progress ***\n"
for i in `seq 0 10 100`; do
    for j in `seq 0 7`; do
        checkFreeze false '@0' `week 100` $j 100 0 $i true
    done
done

echo "\n*** Team basket checks ***\n"
for i in `seq 0 10 100`; do
    checkFreeze true '@0' `week 0` 1 100 0 $i true
done
for i in `seq 0 5 100`; do
    checkFreeze true '@0' `week 23` 1 100 0 $i true
done
for i in `seq 0 5 100`; do
    test $i -le 25 && EXPECT=false || EXPECT=true
    checkFreeze true '@0' `week 24` 1 100 0 $i $EXPECT
done
for i in `seq 0 5 100`; do
    test $i -le 25 && EXPECT=false || EXPECT=true
    checkFreeze true '@0' `week 47` 1 100 0 $i $EXPECT
done
for i in `seq 0 5 100`; do
    test $i -le 50 && EXPECT=false || EXPECT=true
    checkFreeze true '@0' `week 48` 1 100 0 $i $EXPECT
done
for i in `seq 0 5 100`; do
    test $i -le 50 && EXPECT=false || EXPECT=true
    checkFreeze true '@0' `week 71` 1 100 0 $i $EXPECT
done
for i in `seq 0 5 100`; do
    test $i -le 75 && EXPECT=false || EXPECT=true
    checkFreeze true '@0' `week 72` 1 100 0 $i $EXPECT
done
for i in `seq 0 5 100`; do
    test $i -le 75 && EXPECT=false || EXPECT=true
    checkFreeze true '@0' `week 95` 1 100 0 $i $EXPECT
done
for i in `seq 0 5 100`; do
    checkFreeze true '@0' `week 96` 1 100 0 $i false
done

echo "\n*** Foundation basket checks ***\n"
for i in `seq 0 10 100`; do
    checkFreeze true '@0' `week 0` 2 100 0 $i true
done
for i in `seq 0 5 100`; do
    checkFreeze true '@0' `week 47` 2 100 0 $i true
done
for i in `seq 0 5 100`; do
    checkFreeze true '@0' `week 48` 2 100 0 $i false
done

echo "\n*** All unfrozen ***\n"
for i in `seq 0 20 100`; do
    for j in `seq 0 7`; do
        checkFreeze true '@0' `week 100` $j 100 0 $i false
    done
done
