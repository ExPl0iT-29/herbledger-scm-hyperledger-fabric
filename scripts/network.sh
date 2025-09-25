#!/bin/bash

# Get the project root directory
PROJECT_ROOT="/home/explooit/herbchain/herbledger-scm-hyperledger-fabric"

function networkUp() {
  echo "Starting network..."
  export PATH=${PROJECT_ROOT}/bin:$PATH
  cd ${PROJECT_ROOT}
  
  sudo ./scripts/generate-crypto.sh || { echo "Crypto generation failed"; exit 1; }
  docker-compose -f config/docker-compose.yaml up -d || { echo "Docker-compose failed"; exit 1; }
  sleep 5
  ./scripts/create-channel.sh || { echo "Channel creation failed"; exit 1; }
  ./scripts/deploy-chaincode.sh || { echo "Chaincode deployment failed"; exit 1; }
  echo "Network up! Test with ./scripts/test-chaincode.sh"
}

function networkDown() {
  echo "Stopping network..."
  cd ${PROJECT_ROOT}
  docker-compose -f config/docker-compose.yaml down -v
  rm -rf crypto-config network/*.block network/*.tx *.tar.gz
  sudo sed -i '/orderer.example.com/d' /etc/hosts
  sudo sed -i '/peer0.farmer.example.com/d' /etc/hosts
  sudo sed -i '/peer0.processor.example.com/d' /etc/hosts
  sudo sed -i '/peer0.lab.example.com/d' /etc/hosts
  sudo sed -i '/peer0.manufacturer.example.com/d' /etc/hosts
  echo "Network down and cleaned."
}