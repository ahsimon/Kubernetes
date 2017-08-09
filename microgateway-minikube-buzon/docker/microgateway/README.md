Kubernetes Minikube version of apigee microgateway 

Can be run in other platforms too by attaching volume mount for 

1) /opt/apigeee/edgemicro/configmap

containing config.txt

EDGEMICRO_USERNAME=user@apigee.com

EDGEMICRO_PASSWORD=********

EDGEMICRO_ORG=org

EDGEMICRO_ENV=env


2)/root/.edgemicro/configmap

containing default.yaml file of apigee microgateway
