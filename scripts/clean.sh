#!/usr/bin/env bash

rm -rf /tmp/parquet
mkdir /tmp/parquet
chmod 777 /tmp/parquet
minikube stop
minikube delete

pkill -f minikube

docker rm -f $(docker ps -aq)