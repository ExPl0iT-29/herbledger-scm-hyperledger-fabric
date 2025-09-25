#!/bin/bash
# Set absolute path to avoid $PWD issues with sudo
export FABRIC_CFG_PATH=/home/explooit/herbchain/herbledger-scm-hyperledger-fabric/config
export PATH=/home/explooit/herbchain/herbledger-scm-hyperledger-fabric/bin:$PATH
export ORDERER_CA=/home/explooit/herbchain/herbledger-scm-hyperledger-fabric/crypto-config/ordererOrganizations/orderer.example.com/msp/tlscacerts/tlsca.orderer.example.com-cert.pem

# Debug: Verify paths
echo "FABRIC_CFG_PATH=$FABRIC_CFG_PATH"
echo "Config file exists:"
ls -l $FABRIC_CFG_PATH/configtx.yaml || { echo "Error: configtx.yaml not found"; exit 1; }

# Verify crypto material
if [ ! -d "/home/explooit/herbchain/herbledger-scm-hyperledger-fabric/crypto-config/peerOrganizations/farmer.example.com/users/Admin@farmer.example.com/msp" ]; then
  echo "Error: Crypto material missing for farmer.example.com"
  exit 1
fi

# Generate genesis and channel tx (no sudo needed for configtxgen)
./bin/configtxgen -profile OrdererGenesis -channelID system-channel -outputBlock /home/explooit/herbchain/herbledger-scm-hyperledger-fabric/network/genesis.block || { echo "Failed to generate genesis block"; exit 1; }
./bin/configtxgen -profile HerbLedgerChannel -outputCreateChannelTx /home/explooit/herbchain/herbledger-scm-hyperledger-fabric/network/herbledger-channel.tx -channelID herbledgerchannel || { echo "Failed to generate channel tx"; exit 1; }

# Create channel
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID=FarmerCollectiveMSP
export CORE_PEER_MSPCONFIGPATH=/home/explooit/herbchain/herbledger-scm-hyperledger-fabric/crypto-config/peerOrganizations/farmer.example.com/users/Admin@farmer.example.com/msp
export CORE_PEER_ADDRESS=peer0.farmer.example.com:7051
export CORE_PEER_TLS_ROOTCA_FILE=/home/explooit/herbchain/herbledger-scm-hyperledger-fabric/crypto-config/peerOrganizations/farmer.example.com/peers/peer0.farmer.example.com/tls/ca.crt
sudo ./bin/peer channel create -o orderer.example.com:7050 -c herbledgerchannel -f /home/explooit/herbchain/herbledger-scm-hyperledger-fabric/network/herbledger-channel.tx --tls --cafile $ORDERER_CA || { echo "Failed to create channel"; exit 1; }

# Join peers
orgs=("farmer.example.com:7051:FarmerCollectiveMSP" "processor.example.com:9051:ProcessorMSP" "lab.example.com:11051:LabMSP" "manufacturer.example.com:13051:ManufacturerMSP")
for org in "${orgs[@]}"; do
  IFS=':' read -r domain port mspid <<< "$org"
  export CORE_PEER_LOCALMSPID=$mspid
  export CORE_PEER_TLS_ROOTCA_FILE=/home/explooit/herbchain/herbledger-scm-hyperledger-fabric/crypto-config/peerOrganizations/$domain/peers/peer0.$domain/tls/ca.crt
  export CORE_PEER_MSPCONFIGPATH=/home/explooit/herbchain/herbledger-scm-hyperledger-fabric/crypto-config/peerOrganizations/$domain/users/Admin@$domain/msp
  export CORE_PEER_ADDRESS=peer0.$domain:$port
  sudo ./bin/peer channel join -b /home/explooit/herbchain/herbledger-scm-hyperledger-fabric/network/herbledgerchannel.block || { echo "Failed to join $domain to channel"; exit 1; }
done
echo "Channel created and joined!"