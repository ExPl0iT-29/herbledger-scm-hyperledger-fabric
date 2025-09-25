#!/bin/bash
export FABRIC_CFG_PATH=config
export ORDERER_CA=/crypto-config/ordererOrganizations/orderer.example.com/msp/tlscacerts/tlsca.orderer.example.com-cert.pem

# Package chaincode
cd /work/chaincode/herbledger
go mod tidy
cd /work
peer lifecycle chaincode package herbledger.tar.gz --path ./chaincode/herbledger --lang golang --label herbledger_1.0 || { echo "Failed to package chaincode"; exit 1; }

# Install on peers
orgs=("farmer.example.com:7051:FarmerCollectiveMSP" "processor.example.com:9051:ProcessorMSP" "lab.example.com:11051:LabMSP" "manufacturer.example.com:13051:ManufacturerMSP")
for org in "${orgs[@]}"; do
  IFS=':' read -r domain port mspid <<< "$org"
  export CORE_PEER_LOCALMSPID=$mspid
  export CORE_PEER_TLS_ROOTCA_FILE=/crypto-config/peerOrganizations/$domain/peers/peer0.$domain/tls/ca.crt
  export CORE_PEER_MSPCONFIGPATH=/crypto-config/peerOrganizations/$domain/users/Admin@$domain/msp
  export CORE_PEER_ADDRESS=peer0.$domain:$port
  peer lifecycle chaincode install herbledger.tar.gz || { echo "Failed to install chaincode on $domain"; exit 1; }
done

# Get package ID
export CORE_PEER_LOCALMSPID=FarmerCollectiveMSP
export CORE_PEER_MSPCONFIGPATH=/crypto-config/peerOrganizations/farmer.example.com/users/Admin@farmer.example.com/msp
export CORE_PEER_ADDRESS=peer0.farmer.example.com:7051
export CORE_PEER_TLS_ROOTCA_FILE=/crypto-config/peerOrganizations/farmer.example.com/peers/peer0.farmer.example.com/tls/ca.crt
PACKAGE_ID=$(peer lifecycle chaincode queryinstalled | awk -F, '/herbledger_1.0/ {print $2}' | cut -d: -f2 | head -1) || { echo "Failed to get package ID"; exit 1; }

# Approve for orgs
for org in "${orgs[@]}"; do
  IFS=':' read -r domain port mspid <<< "$org"
  export CORE_PEER_LOCALMSPID=$mspid
  export CORE_PEER_TLS_ROOTCA_FILE=/crypto-config/peerOrganizations/$domain/peers/peer0.$domain/tls/ca.crt
  export CORE_PEER_MSPCONFIGPATH=/crypto-config/peerOrganizations/$domain/users/Admin@$domain/msp
  export CORE_PEER_ADDRESS=peer0.$domain:$port
  peer lifecycle chaincode approveformyorg -o orderer.example.com:7050 --channelID herbledgerchannel --name herbledger --version 1.0 --package-id $PACKAGE_ID --sequence 1 --tls --cafile $ORDERER_CA || { echo "Failed to approve chaincode for $mspid"; exit 1; }
done

# Commit chaincode
peer lifecycle chaincode commit -o orderer.example.com:7050 --channelID herbledgerchannel --name herbledger --version 1.0 --sequence 1 --tls --cafile $ORDERER_CA \
  --peerAddresses peer0.farmer.example.com:7051 --tlsRootCertFiles /crypto-config/peerOrganizations/farmer.example.com/peers/peer0.farmer.example.com/tls/ca.crt \
  --peerAddresses peer0.processor.example.com:9051 --tlsRootCertFiles /crypto-config/peerOrganizations/processor.example.com/peers/peer0.processor.example.com/tls/ca.crt \
  --peerAddresses peer0.lab.example.com:11051 --tlsRootCertFiles /crypto-config/peerOrganizations/lab.example.com/peers/peer0.lab.example.com/tls/ca.crt \
  --peerAddresses peer0.manufacturer.example.com:13051 --tlsRootCertFiles /crypto-config/peerOrganizations/manufacturer.example.com/peers/peer0.manufacturer.example.com/tls/ca.crt || { echo "Failed to commit chaincode"; exit 1; }
echo "Chaincode deployed!"