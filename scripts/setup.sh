#!/usr/bin/env bash

SCRIPTS_DIT="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
ROOT_DIR="$(dirname "$SCRIPTS_DIR")"

cd $ROOT_DIR

function startCluster() {
    echo "Starting minikube cluster ..."
    minikube start --bootstrapper=kubeadm --cpus 4 --memory 8192 --insecure-registry=192.168.0.0/16 --driver=virtualbox
    minikube addons enable registry
    minikube addons enable dashboard
    minikube addons enable metrics-server
    
    kubectl cluster-info
    echo "Minikube cluster started!"
}

function setupChartMuseum() {
    echo "Starting Chart Museum ..."
    cd $ROOT_DIR
    helm plugin install https://github.com/chartmuseum/helm-push
    
    docker run -d \
    --name chartmuseum \
    --restart=always \
    -p 8080:8080 \
    -e DEBUG=1 \
    -e STORAGE=local \
    -e STORAGE_LOCAL_ROOTDIR=/charts \
    -v $(pwd)/helm:/charts \
    chartmuseum/chartmuseum:latest
    
    curl $(minikube ip):8080/index.yaml
    echo "Started Chart Museum!"
}

function installSparkOperator () {
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
}

function mountDataset () {
    cd $ROOT_DIR
    echo "Mounting dataset volumes ..."
    mkdir /tmp/parquet
    chmod 777 /tmp/parquet
    minikube mount ./dataset/ml-20m/:/tmp/data-in &
    minikube mount /tmp/parquet:/tmp/data-out &
    echo "Mounted successfully!"
}

function buildSparkRunner() {
    name="spark-runner"
    cd $ROOT_DIR/docker/${name}
    
    echo "Building spark-runner image ..."
    
    registry="localhost:5000"
    version="0.1"
    
    docker build \
    --build-arg VCS_REF=$(git rev-parse --short HEAD) \
    --build-arg BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ") \
    --build-arg VERSION=0.1 \
    -t ${registry}/${name}:${version} . \
    && docker push ${registry}/${name}:${version} \
    && echo "Build & pushed ${registry}/${name}:${version}"
    
    curl -s $(minikube ip):5000/v2/_catalog | jq
    echo "Built and pushed spark-runner image!"
}

# startCluster
# eval $(minikube docker-env)
# curl -s $(minikube ip):5000/v2/_catalog | jq

# setupChartMuseum
# installSparkOperator
mountDataset
buildSparkRunner