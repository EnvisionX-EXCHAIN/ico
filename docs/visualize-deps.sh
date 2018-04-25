#!/bin/sh -e

PATTERN='^.*contract ([^ ]+) is ([^\{]+) *\{.*$'

echo "\
digraph G{
  label = \"Contracts inheritance\";
  rankdir = BT;\n"

for i in ../contracts/*.sol; do
    FLAT=`tr -d "\n" < "$i" | sed -r 's/ +/ /g'`
    echo "$FLAT" | egrep -q "$PATTERN" || continue
    echo "$FLAT" | sed -r "s/$PATTERN/\\1 \\2/" | tr -d ,
done | \
    while LINE=`line`; do
        set $LINE
        C="$1"
        shift
        while [ -n "$1" ]; do
            echo "  $C -> $1;"
            shift
        done
    done

echo "}"
