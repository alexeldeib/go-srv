#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

if [ -z "${LOCATION}" ]; then
    echo "env var LOCATION is required"
    exit 1
fi

if [ -z "${NAME}" ]; then
    echo "env var NAME is required"
    exit 2
fi

az group create -l "${LOCATION}" -n ${NAME}
az aks create \
    -g ${NAME} \
    -n ${NAME} \
    -l "${LOCATION}"  \
    --node-count 3 \
    --node-vm-size Standard_D16s_v3 \
    --node-osdisk-size 1023 \
    -k 1.17.3 \
    --network-plugin azure \
    --enable-vmss \
    --load-balancer-sku standard

# expose server on :8080
kubectl apply -f server.yaml

# wait for pods up
kubectl wait --for=condition=Ready pod -l app=http

echo "You should ensure your ingress IP is ready before proceeding"
sleep 10

echo -e "Press any key to continue"
read -n 1 -s -r

# manually wait until ingress IP is ready, then
INGRESS_IP="$(kubectl get svc http -o jsonpath="{.status.loadBalancer.ingress[0].ip}")"

# load testing client
go get -u github.com/codesenberg/bombardier

# load test 
bombardier -c 125 -n 1000000 "http://${INGRESS_IP}:8080"

# replace IP in client invocation for pod
sed -i "s/INGRESSIP/${INGRESS_IP}/g"

# apply client, wait for it to run once
kubectl apply -f client.yaml

# this will output results from bombardier
kubectl logs <CLIENT_POD> 
