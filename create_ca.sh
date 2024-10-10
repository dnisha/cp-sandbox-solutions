#!/bin/sh

CA_PRIVATE_KEY='./ca/ca-key'
CA_PUBLIC_KEY='./ca/ca-cert'
CA_PASS='kafka-broker'

openssl req -new -x509 -days 365 -keyout $CA_PRIVATE_KEY -out $CA_PUBLIC_KEY -subj "/C=DE/ST=NRW/L=MS/O=juplo/OU=kafka/CN=Root-CA" -passout pass:$CA_PASS;