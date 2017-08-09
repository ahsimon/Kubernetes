#!/usr/bin/env bash


kubectl create -f ./minikube/kube/services/buzon-getall-svc-nodeport.yaml
kubectl create -f ./minikube/kube/pods/buzon-getall-pods.yaml