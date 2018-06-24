#!/bin/bash

if [[ $# -ne 3 ]]; then
  echo "Usage: $0 tran_filename currency exchange_address" >&2
  exit 1
fi

while read LINE; do

  exchange_address="$3"
  tran_id=$(echo $LINE | cut -d, -f1)
  private_key=$(echo $LINE | cut -d, -f2)
  address=$(echo $LINE | cut -d, -f3)
  echo "python ./claimer.py --force --noblock $2 $tran_id $private_key $address $exchange_address"
  echo "sleep 5"

done < <(tail -n +2 ${1}) | tee --append $2
