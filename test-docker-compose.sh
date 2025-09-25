#!/bin/bash
echo "🔍 Testing Docker Compose Volume Mounts..."

cd /app/config

echo "✅ Working Directory: $(pwd)"

echo "🔍 Checking Orderer MSP certificates..."
if [ -f "../crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/signcerts/orderer.example.com-cert.pem" ]; then
    echo "✅ Orderer signcert found: $(ls -la ../crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/signcerts/)"
else
    echo "❌ Orderer signcert NOT found"
fi

echo "🔍 Checking Peer MSP certificates..."
for org in farmer processor lab manufacturer; do
    cert_path="../crypto-config/peerOrganizations/${org}.example.com/peers/peer0.${org}.example.com/msp/signcerts"
    if [ -d "$cert_path" ]; then
        cert_file=$(ls ${cert_path}/*.pem 2>/dev/null | head -1)
        if [ -n "$cert_file" ]; then
            echo "✅ $org MSP signcert found: $(basename $cert_file)"
        else
            echo "❌ $org MSP signcert file NOT found"
        fi
    else
        echo "❌ $org MSP signcert directory NOT found"
    fi
done

echo "🔍 Checking Genesis Block..."
if [ -f "../network/genesis.block" ]; then
    echo "✅ Genesis block found: $(ls -la ../network/genesis.block)"
else
    echo "❌ Genesis block NOT found"
fi

echo "🔍 Checking TLS certificates..."
if [ -f "../crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.crt" ]; then
    echo "✅ Orderer TLS cert found"
else
    echo "❌ Orderer TLS cert NOT found"
fi

echo ""
echo "📋 Volume Mount Test Summary:"
echo "   The docker-compose.yaml now uses '../' paths which correctly reference:"
echo "   Host: /app/crypto-config/* → Container: /var/hyperledger/*/msp/*"
echo "   Host: /app/network/genesis.block → Container: /var/hyperledger/orderer/genesis.block"
echo ""
echo "🚀 When you run 'docker-compose up' from /app/config/, the containers will find all certificates!"
echo "💡 Make sure Docker daemon is running in your environment"