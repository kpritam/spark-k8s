#!/usr/bin/env bash

cd ${BASH_SOURCE%/*}

echo "Creating spark-operator and spark-apps namespaces"
kubectl create namespace spark-operator
kubectl create namespace spark-apps

echo "Creating spark service account in spark-operator namespace"
kubectl create serviceaccount spark --namespace=spark-operator

echo "Creating clusterrolebinding in spark-operator namespace"
kubectl create clusterrolebinding spark-operator-role \
 --clusterrole=edit \
 --serviceaccount=spark-operator:spark \
 --namespace=spark-operator

echo "Installing spark-on-k8s-operator"
helm repo add spark-operator https://googlecloudplatform.github.io/spark-on-k8s-operator
helm repo update

helm install spark spark-operator/spark-operator --namespace spark-operator --set webhook.enable=true,sparkJobNamespace=spark-apps,logLevel=3

echo "Listing all pods from spark-operator namespace"
kubectl get all -n spark-operator




