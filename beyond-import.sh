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

wallet=$(echo $characterData | jq -c '.data.currencies | [to_entries | .[] | .key |= ascii_upcase | select(.value > 0) | .value = {"Count": .value, "Weight": 0.02, "Cost": (if .key == "CP" then 0.01 else (if .key == "SP" then 0.1 else (if .key == "EP" then 0.5 else (if .key == "GP" then 1.0 else (if .key == "PP" then 10 else -1 end) end) end) end)  end)}] | from_entries')

inventory=""
items=$(echo $characterData | jq -rc '.data.inventory[].definition | "\"\(.name)\": {\"Count\": XXX.0, \"Cost\": \(.cost), \"Weight\": \(.weight)}"' | sed 's/\\//g' | sort | uniq -c )
for itemRaw in $items; do
  number=$(echo $itemRaw | sed 's/^ *//;s/ .*//')
  itemFormatted=$(echo $itemRaw | sed "s/^ *$number //;s/XXX/$number/")
  inventory="$inventory, $itemFormatted"
done
inventory=$(echo $inventory | sed 's/^, //')
output="{\"Wallet\": $wallet, \"Carried\": {$inventory}}"

echo $output | jq -c | sed 's/"/\\"/g'
IFS=$OLDIFS
