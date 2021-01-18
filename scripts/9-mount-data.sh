#!/usr/bin/env bash

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

cd $ROOT_DIR

mkdir /tmp/parquet
chmod 777 /tmp/parquet

minikube mount ./dataset/ml-20m/:/tmp/data-in &
minikube mount /tmp/parquet:/tmp/data-out &
