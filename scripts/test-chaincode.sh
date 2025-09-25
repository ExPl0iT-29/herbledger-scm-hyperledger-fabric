#!/bin/bash
export FABRIC_CFG_PATH=/etc/hyperledger/fabric
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID=FarmerCollectiveMSP
export CORE_PEER_TLS_ROOTCA_FILE=/crypto-config/peerOrganizations/farmer.example.com/peers/peer0.farmer.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=/crypto-config/peerOrganizations/farmer.example.com/users/Admin@farmer.example.com/msp
export CORE_PEER_ADDRESS=peer0.farmer.example.com:7051
export ORDERER_CA=/crypto-config/ordererOrganizations/orderer.example.com/msp/tlscacerts/tlsca.orderer.example.com-cert.pem

# Test chaincode query
peer chaincode invoke -o orderer.example.com:7050 --tls --cafile $ORDERER_CA \
  -C herbledgerchannel -n herbledger --peerAddresses peer0.farmer.example.com:7051 --tlsRootCertFiles /crypto-config/peerOrganizations/farmer.example.com/peers/peer0.farmer.example.com/tls/ca.crt \
  -c '{"function":"queryBatch","Args":["batch001"]}' || { echo "Failed to query chaincode"; exit 1; }

echo "Chaincode test completed!"