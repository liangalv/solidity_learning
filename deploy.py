from solcx import compile_standard, install_solc
from web3 import Web3
from dotenv import load_dotenv
import json, os
load_dotenv()#this function loads the .env variables into our script
# we're importing from the solc-x library in order to grab the compiler function
with open("./SimpleStorage.sol", "r") as file:
    simple_storage_file = file.read()
    # we're going to open, this file an then close it
    # we're going to only read from it, and we're going to call it file
    # we're going to read all the contents of this file

install_solc("0.6.0")
# Compile our Solidity
compiled_sol = compile_standard(
    {
        "language": "Solidity",
        "sources": {"SimpleStorage.sol": {"content": simple_storage_file}},
        "settings": {
            "outputSelection": {
                "*": {"*": ["abi", "metadata", "evm.bytecode", "evm.sourceMap"]}
            }
        },
    },
    solc_version="0.6.0",
)

with open("compiled_code.json", "w") as file:
    json.dump(compiled_sol, file)
# this is going to take our compiled_sol json variable and just dump it into the file here
# but it's going to keep it in the json syntax

#get the bytecode 
bytecode = compiled_sol["contracts"]["SimpleStorage.sol"]["SimpleStorage"]["evm"]["bytecode"]["object"]
    #we're walking down the json tree here for the compiled code 


#get the ABI 
ABI = compiled_sol["contracts"]["SimpleStorage.sol"]["SimpleStorage"]["abi"]
#we only need these these two pieces of data to deploy this information onto a blockchain 


#for connecting to ganache 
w3 = Web3(Web3.HTTPProvider("https://rinkeby.infura.io/v3/3c53d9257cdd4f5dbdb83acf67bb3267"))
#this is a loopback address(localhost)
chain_id = 4
my_address = "0x34653514679BaB876076c223A4b6723917C8e0dE"
private_key = os.getenv("PRIVATE_KEY")

SimpleStorage = w3.eth.contract(abi=ABI, bytecode=bytecode)
    #this line of code generates the contract object

#1.now we need to build the contract Deploy transaction 
#2.sign the transaction 
#3.send the transaction 

#Get the latest transaction count
nonce = w3.eth.getTransactionCount(my_address)
    #account nonces just track the number of transactions that have been made 

transaction = SimpleStorage.constructor().buildTransaction({"from": my_address,"gasPrice": w3.eth.gas_price,"chainId":chain_id, "nonce": nonce})
#Simple storage itself doesn't really have a constructor, but there is an implied on for every contract 

#we now need to sign our transaction
signed_txn = w3.eth.account.sign_transaction(transaction,private_key = private_key)
#it's really bad practice to place a private key in your code 

#Send this signed transaction 
tx_hash = w3.eth.send_raw_transaction(signed_txn.rawTransaction)
#we can also wait for for some block confirmations to happen
# this will have the code stop and wait for the transaction hash to go through 
tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash)

#Working with the contract 
    #we always need 2 things 
        #1.Contract Address 
        #2.Contract ABI 
simple_storage = w3.eth.contract(address=tx_receipt.contractAddress,abi=ABI)
#Call -> Simulate making the call and getting a return value 
#Transact-> Actually making a state change to the blockchain 

#Initial value of favourite number 
print(simple_storage.functions.retrieve().call())

#actually intializing the store function 
store_transaction = simple_storage.functions.store(15).buildTransaction({"gasPrice": w3.eth.gas_price,"chainId": chain_id, "from": my_address,"nonce": nonce + 1})
#then we're going to sign the transaction again 
signed_store_txn =w3.eth.account.sign_transaction(store_transaction,private_key=private_key) 
#then we're going to send a raw transaction 
send_store_txn = w3.eth.send_raw_transaction(signed_store_txn.rawTransaction)
tx_receipt = w3.eth.wait_for_transaction_receipt(send_store_txn)

print(simple_storage.functions.retrieve().call())
