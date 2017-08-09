#!/usr/bin/env bash

kubectl delete -f ./minikube/kube/services/buzon-getall-svc-nodeport.yaml
kubectl delete -f ./minikube/kube/pods/buzon-getall-pods.yaml
