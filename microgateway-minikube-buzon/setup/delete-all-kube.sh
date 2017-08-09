#!/usr/bin/env bash

kubeclt delete -f ./minikube/kube/deployments/apigee-microgateway-default-config.yaml
kubectl delete -f ./minikube/kube/services/buzon-getall-svc-nodeport.yaml
kubectl delete -f ./minikube/kube/pods/buzon-getall-pods.yaml
kubectl delete -f ./minikube/kube/configmaps/apigee-microgateway-default-config.yaml
kubectl delete secret apigee-microgateway-buzon-dev-config
kubeclt delete configmap apigee-microgateway-default-config
