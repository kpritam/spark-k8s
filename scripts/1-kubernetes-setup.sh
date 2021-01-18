#!/usr/bin/env bash

# brew cask install minikube
# brew cask install VirtualBox
# brew install kubernetes-cli

minikube start --bootstrapper=kubeadm --cpus 4 --memory 8192 --insecure-registry=192.168.0.0/16 --driver=virtualbox

minikube addons enable registry
minikube addons enable dashboard

kubectl cluster-info