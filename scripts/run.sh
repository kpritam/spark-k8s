#!/usr/bin/env bash

SCRIPTS_DIT="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
ROOT_DIR="$(dirname "$SCRIPTS_DIR")"

cd $ROOT_DIR

function buildAppImage () {
    cd $ROOT_DIR
    echo "Building sbt transform-movie-ratings docker image ..."
    
    sbt -DbaseRegistry=$(minikube ip):5000 clean docker
    
    version=$(sbt -error showVersion)
    relativeRegistry="localhost:5000"
    docker tag  kpritam/transform-movie-ratings:${version} ${relativeRegistry}/kpritam/transform-movie-ratings:${version}
    docker push ${relativeRegistry}/kpritam/transform-movie-ratings:${version}
    
    curl -s $(minikube ip):5000/v2/_catalog | jq
    echo "Built and pushed transform-movie-ratings image!"
}

function publishAppChart () {
    cd $ROOT_DIR
    echo "Creating helm chart ..."
    # create and push helm chart
    name="transform-movie-ratings"
    
    rm -rf output/${name}
    mkdir output/${name}
    cp -r helm/ output/${name}/
    cat helm/values-minikube.yaml >> output/${name}/values.yaml
    cd output
    
    export HELM_REPO_USE_HTTP="true"
    helm repo add chartmuseum http://$(minikube ip):8080
    echo "Pushing helm chart ..."
    helm push --force ${name}/ chartmuseum
    
    echo "Created and pushed helm chart!"
}

function installApp () {
    cd $ROOT_DIR
    helm upgrade movie-ratings-transform \
    ./helm \
    -f ./helm/values-minikube.yaml \
    --namespace=spark-apps \
    --install \
    --force
    
    helm repo update
    helm upgrade movie-ratings-transform \
    chartmuseum/kpritam-transform-movie-ratings \
    --namespace=spark-apps \
    --install \
    --force
}

# eval $(minikube docker-env)
# curl -s $(minikube ip):5000/v2/_catalog | jq
# buildAppImage
# publishAppChart
installApp