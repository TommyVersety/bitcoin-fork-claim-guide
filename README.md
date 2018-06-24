# bitcoin-fork-claim-guide

## Introduction

### What is this about?

This guide is meant help you claim airdropped coins forked from bitcoin (BTC). Well known bitcoin forks are Bitcoin Cash (BCH), Bitcoin Gold (BTG). There are many more forks. Although most of these forked coins have very little value relative to bitcoin, you can still make some free money out of thin air!

In order to claim your forked coins, you must have held bitcoins in a wallet you control. For this guide, I will assume you held your bitcoins in **[Trezor](https://trezor.io/)**, **[Ledger](https://www.ledgerwallet.com/)** or **[Keepkey](https://www.keepkey.com/)** hardware wallets. However, it does apply to other wallets as well.

### Do I really have free money lying around in the different blockchains?

Use [findmycoins.ninja](http://www.findmycoins.ninja/) to find out if you really have forked coins lying around in blockchains. Paste the Bitcoin addresses you used for transacting and the website will show you how much of each fork you possess. Note the forked coins you are able to claim.

## First steps

Before you begin the process of claim your airdropped forked coins, make sure you:

- **create a brand new wallet with a fresh set of 12/18/24 word seed (optional but highly recommended)**
  - **transfer your bitcoins and other coins (LTC, ETH, etc) to this new wallet**
- have a good grasp of Linux/Unix/MacOS command line

## Claiming your forked coins

### 00. Install the packages required for your OS

I am assuming you are using a Debian based Linux distro. If you are using something else, like MacOS or another Linux distro, I leave it to your capable hands and intellect to install equivalent packages.

```console
sudo apt install git jq
```

### 01. Generate the list of Path/Address/Public Key/Private Key

We will use [iancoleman/bip39](https://github.com/iancoleman/bip39) git repo to generate the list of  Path/Address/Public Key/Private Key

```console
git clone https://github.com/iancoleman/bip39.git
cd bip39
```

Open the `bip39-standalone.html` file in the `bip39` directory using Google Chrome or Firefox (or any other browser)

Under the **Mnemonic** section of the html page, enter your 12/18/24 word seed in **BIP39 Mnemonic** textbox. If you also use a passphrase, enter the passphrase in **BIP39 Passphrase (optional)**

Under the **Derivation Path** section of the html page, make sure **BIP44** tab is selcted. (Leave the other settings as default unless you have multiple accounts.)

Under the **Derived Addresses** section of the html page, select the **CSV** tab. Depening on how many addresses you have used for your transactions, add a higher number in the **Show** textbox and click **more rows**.

Copy all the contents of the CSV and and save it in a plain text file. Let's call this file `my-non-segwit-addresses.csv`.

Go to the **Derivation Path** section again and select the **BIP49** tab. Go to the **Derived Addresses** section and copy all the contents of the CSV in a file called `my-segwit-addresses.csv`

(Keep these CSV files secure since they contain your private keys.)

### 02. Get the list of tranaction ids from CSV files created above

Save the script below in a file called `generate-txn-list.sh` and make it executable `chmod +x generate-txn-list.sh`

```bash
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
```

Use the script above to generate 2 more files containing the transactions.

```console
./generate-txn=list.sh my-non-segwit-addresses.csv
./generate-txn=list.sh my-segwit-addresses.csv
```

Now you will end up with 2 more files called `my-non-segwit-addresses.csv.transactions` and `my-segwit-addresses.csv.transactions`. These are the files we will use in the next step.

### 03. Create the script to generate batch jobs for transferring the forked coins

In this section we will create the script to generate batch jobs for claiming the forked coins for every address/private key/transaction id combo to send them to a destination address (an exchange address)

Save the script below in a file called `generate-batch-jobs.sh` and make it executable `chmod +x generate-batch-jobs.sh`

```bash
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
````

### 04. Generate batch jobs for the forked coins you want to claim and send

For this task we will use [ymgve/bitcoin_fork_claimer](https://github.com/ymgve/bitcoin_fork_claimer) git repo. First, check [bitcoin_fork_claimer README](https://github.com/ymgve/bitcoin_fork_claimer/blob/master/README.md) to get the ticker for the fork you want to claim. For this example, let's say you want to claim Bitcoin Private (BTCP). Get an account at an [exchange](#exchanges-to-dump-your-forked-coins) and get a deposit address for BTCP.

Generate the batch jobs for claiming BTCP (use `generate-batch-jobs.sh` script from previous step):

```console
# Replace <exchange_address> with the BTCP desposit address of your exchange (DOUBLE CHECK THE ADDRESS)
./generate-batch-jobs.sh my-non-segwit-addresses.csv.transactions BTCP <exchange_address>
./generate-batch-jobs.sh my-segwit-addresses.csv.transactions BTCP <exchange_address>
```

After running the commands above you will end up with a file called `BTCP` in the same directory. (Note that for this example the file is `BTCP` because we are claiming BTCP. If you claiming some other coin like BIFI, the file will be `BIFI`.)

We will need to use the [ymgve/bitcoin_fork_claimer](https://github.com/ymgve/bitcoin_fork_claimer) git repo to claim the forked coin BTCP.

```console
git clone https://github.com/ymgve/bitcoin_fork_claimer.git
cd bitcoin_fork_claimer
# move the BTCP file to this directory
mv ../path/to/BTCP .
```

Check [findmycoins.ninja](http://www.findmycoins.ninja/) and find out which of your addresses contains BTCP you are able to claim. Open `BTCP` file with an editor and remove lines containing addresses which does not have BTCP you are able to claim. (You may skip this step but it will take a long time for the batch jobs in `BTCP` file to complete.)

Now you are able to claim and send to the exchange address.

```console
bash ./BTCP
```

As the batch jobs in `BTCP` file runs, look for outputs like "YOU ARE ABOUT TO SEND" and "OUR TRANSACTION IS IN THEIR MEMPOOL, TRANSACTION ACCEPTED! YAY!". At this point check your exchange and see if they show up in the deposit page.

(Note than I have used BTCP as an example. You are able to claim other forked coins as well as long as it is supported in [ymgve/bitcoin_fork_claimer](https://github.com/ymgve/bitcoin_fork_claimer/blob/master/README.md))

## Exchanges to dump your forked coins

Before depositing your forked coins in an exchange, make sure if the exchange allows you to trade anonymously or they require you to verify your identity.

| Forked coin           | Exchanges |
|-----------------------|-----------|
|B2X - Segwit 2X         | https://exrates.me |
|BBC - Big Bitcoin       | https://tradesatoshi.com |
|BCA - Bitcoin Atom      | Check https://coinmarketcap.com/ -> Bitcoin Atom -> Markets |
|BCD - Bitcoin Diamond   | Check https://coinmarketcap.com/ -> Bitcoin Diamond -> Markets |
|BCH - Bitcoin Cash      | Check https://coinmarketcap.com/ -> Bitcoin Cash -> Markets |
|BCI - Bitcoin Interest  | Check https://coinmarketcap.com/ -> Bitcoin Interest -> Markets |
|BCX - Bitcoin X         | Check https://coinmarketcap.com/ -> BitcoinX -> Markets |
|BICC - BitClassic Coin  | https://www.topbtc.com |
|BIFI - Bitcoin File     | https://gate.io/ |
|BTCP - Bitcoin Private  | Check https://coinmarketcap.com/ -> Bitcoin Private -> Markets |
|BTF - Bitcoin Faith     | https://www.btctrade.im |
|BTG - Bitcoin Gold      | Check https://coinmarketcap.com/ -> Bitcoin Diamond -> Markets |
|BTW - Bitcoin World     | https://www.btctrade.im |
|BTP - Bitcoin Pay       | https://www.btctrade.im |
|BTX - Bitcore           | Check https://coinmarketcap.com/ -> Bitcore -> Markets |
|GOD - Bitcoin God       | Check https://coinmarketcap.com/ -> Bitcoin God -> Markets |
|LBTC - Lightning Bitcoin| Check https://coinmarketcap.com/ -> Lightning Bitcoin -> Markets |
|SBTC - Super Bitcoin    | Check https://coinmarketcap.com/ -> Super Bitcoin -> Markets |


## Disclaimer

This guide is to be used at your own risk. Do not hold me responsible for any mishaps not just limited to the following:

- confusing ticker of one coin with another
- sending coins to the wrong address
- having your private keys or 12/18/24 word seeds compromised
- not being able to withdraw funds from exchange due to verification

## Donations

Really appreciate your donations which can sent to

BTC: 38uvDLV4GzcAB7qMUEM5chqivESqNPWPZW

LTC: MRAwH2WHUprCn5RcpKWKMkfaUJicTpsbWr
