#!/bin/bash
export PATH=${PWD}/bin:$PATH
rm -rf crypto-config
cryptogen generate --config=./config/crypto-config.yaml --output=crypto-config || { echo "Failed to generate crypto material"; exit 1; }
if [ -d "crypto-config/peerOrganizations/farmer.example.com/users/Admin@farmer.example.com/msp" ]; then
  echo "Crypto material generated in crypto-config/"
else
  echo "Crypto material generation incomplete"
  exit 1
fi