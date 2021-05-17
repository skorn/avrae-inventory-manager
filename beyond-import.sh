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
#characterData=$(cat char)

wallet=$(echo $characterData | jq -c '.data.currencies | [to_entries | .[] | .key |= ascii_upcase | select(.value > 0) | .value = {"Count": .value, "Weight": 0.02, "Cost": (if .key == "CP" then 0.01 else (if .key == "SP" then 0.1 else (if .key == "EP" then 0.5 else (if .key == "GP" then 1.0 else (if .key == "PP" then 10 else -1 end) end) end) end)  end)}] | from_entries')

inventory=""
items=$(echo $characterData | jq -rc '.data.inventory[]
  | . |= if .definition.name == "Arrows" then .definition.name = "Arrow" else . end
  | . |= if .definition.name == "Leather" then .definition.name = "Leather Armor" else . end
  | . |= if .definition.name == "Rope, Hempen (50 feet)" then .definition.name = "Hempen Rope (50 feet)" else . end
  | . |= if .definition.name == "Rope, Silk (50 feet)" then .definition.name = "Silk Rope (50 feet)" else . end
  | . |= if .definition.name == "Mirror, Steel" then .definition.name = "Steel Mirror" else . end
  | . |= if .definition.name == "Lantern, Hooded" then .definition.name = "Hooded Lantern" else . end
  | . |= if .definition.name == "Lantern, Bullseye" then .definition.name = "Bullseye Lantern" else . end
  | . |= if .definition.name == "Ball Bearings (bag of 1,000)" then .quantity = .quantity/1000 else . end
  | . |= if .definition.name == "Clothes, Common" then .definition.name = "Common Clothes" else . end
  | "\"\(.definition.name)\": {\"Count\": \(.quantity).0}"' | sed 's/\\//g' | sort | uniq -c )
for itemRaw in $items; do
  number=$(echo $itemRaw | sed 's/^ *//;s/ .*//')
  if [[ $number =~ ^[1-9] ]]; then
    itemFormatted=$(echo $itemRaw | sed "s/^ *$number //;s/Count\": 1/Count\\\": $number/")
  else
    itemFormatted=$(echo $itemRaw | sed "s/^ *$number //")
  fi
  inventory="$inventory, $itemFormatted"
done
inventory=$(echo $inventory | sed 's/^, //')
output="{\"Wallet\": $wallet, \"Carried\": {$inventory}}"

echo $output | jq -c | sed 's/"/\\"/g'
IFS=$OLDIFS
