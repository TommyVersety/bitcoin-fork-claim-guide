#!/bin/bash

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 filename" >&2
  exit 1
fi

PRVKEYS_AND_ADDR_FILE="$1"
TXNID_PRVKEYS_AND_ADDR_KEYS="${1}.transactions"

echo "txn_id,private_key,address" > $TXNID_PRVKEYS_AND_ADDR_KEYS

while read LINE; do

  address=$(cut -d, -f2 <<< $LINE)
  private_key=$(cut -d, -f4 <<< $LINE)
  # get the source transaction id querying the BTC blockchain through blockchain.info
  txn_id=$(curl -s -XGET https://blockchain.info/rawaddr/${address} | jq '.txs[-1].hash')

  if [[ $txn_id == "null" ]]; then
    continue  # skip if the address has no transactions
  else
    txn_id=$(tr -d \" <<< $txn_id)  # remove the surrounding quotes "
  fi

  echo "${txn_id},${private_key},${address}" | tee --append $TXNID_PRVKEYS_AND_ADDR_KEYS

  # don't flood blockchain.info
  sleep 5

done < <(tail -n +2 $PRVKEYS_AND_ADDR_FILE) # skip the header of input file
