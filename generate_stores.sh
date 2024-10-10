#!/bin/sh

ALIAS='kafka1'
ALIAS_DIR="./$ALIAS"
KEY_STORE="$ALIAS_DIR/kafka.server.keystore.jks"
TRUST_STORE="$ALIAS_DIR/kafka.server.truststore.jks"
TRUST_STORE_PASS='kafka-broker'
KEY_STORE_PASS='kafka-broker'
CA_PASS='kafka-broker'
CA_PUBLIC_KEY='./ca/ca-cert'  # Path to CA certificate
CA_PRIVATE_KEY='./ca/ca-key'   # Path to CA private key
CSR_FILE="$ALIAS_DIR/cert-file"
SIGNED_CERT="$ALIAS_DIR/cert-signed"
DNS='kafka1'

# Create alias directory
mkdir -p "$ALIAS_DIR"

# Create trust store
keytool -keystore "$TRUST_STORE" -storepass "$TRUST_STORE_PASS" -import -alias ca-root -file "$CA_PUBLIC_KEY" -noprompt

# Create key store
keytool -keystore "$KEY_STORE" -storepass "$KEY_STORE_PASS" -alias "$ALIAS" -validity 365 -keyalg RSA -genkeypair -keypass "$KEY_STORE_PASS" -dname "CN=$ALIAS,OU=kafka,O=juplo,L=MS,ST=NRW,C=DE"

# Generate CSR
keytool -alias "$ALIAS" -keystore "$KEY_STORE" -certreq -file "$CSR_FILE" -storepass "$KEY_STORE_PASS" -keypass "$KEY_STORE_PASS"

# Create a temporary file for the extensions
EXTFILE=$(mktemp)
echo "[SAN]" > "$EXTFILE"
echo "subjectAltName=DNS:$DNS,DNS:localhost" >> "$EXTFILE"

# Sign the certificate
openssl x509 -req -CA "$CA_PUBLIC_KEY" -CAkey "$CA_PRIVATE_KEY" -in "$CSR_FILE" -out "$SIGNED_CERT" -days 365 -CAcreateserial -passin pass:"$CA_PASS" -extensions SAN -extfile "$EXTFILE"

# Check if signed certificate was created successfully
if [ ! -f "$SIGNED_CERT" ]; then
    echo "Error: Signed certificate not created."
    exit 1
fi

# Clean up the temporary file
rm "$EXTFILE"

# Import CA public key to keystore
keytool -importcert -keystore "$KEY_STORE" -alias ca-root -file "$CA_PUBLIC_KEY" -storepass "$KEY_STORE_PASS" -keypass "$KEY_STORE_PASS" -noprompt

# Import signed certificate to key store
keytool -keystore "$KEY_STORE" -alias "$ALIAS" -import -file "$SIGNED_CERT" -storepass "$KEY_STORE_PASS" -keypass "$KEY_STORE_PASS" -noprompt

rm -f .srl