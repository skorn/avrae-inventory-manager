#!/usr/bin/env bash
OLDIFS=$IFS
IFS=$'\n'

if ! command -v jq >/dev/null; then
  echo "Please install jq to manage json parsing"
  exit 1
fi

beyondLink=$1 #ddb.ac/characters/49184306/DquLus
characterNumber=$(echo "$beyondLink" | sed 's|^.*characters/||;s|/.*||')

characterData=$(curl -s https://character-service.dndbeyond.com/character/v3/character/$characterNumber)

output=$(echo $characterData | jq -r '.data.currencies | "CP: \(.cp).0|0.01|0.02||SP: \(.sp).0|0.1|0.02||EP: \(.ep).0|0.5|0.02||GP: \(.gp).0|1.0|0.02||PP: \(.pp).0|10|0.02"')

items=$(echo $characterData | jq -r '.data.inventory[].definition | "\(.name): XXX.0|\(.cost)|\(.weight)"' | sort | uniq -c )
for itemRaw in $items; do
  number=$(echo $itemRaw | sed 's/^ *//;s/ .*//')
  itemFormatted=$(echo $itemRaw | sed "s/^ *$number //;s/XXX/$number/")
  output="$output||$itemFormatted"
done
output=$(echo $output | sed 's/^||//')

echo $output
IFS=$OLDIFS
