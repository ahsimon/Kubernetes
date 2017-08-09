# Apigee Microgateway for Kubernetes - Minikube
## Presentation

      

The aim behind this project is setup and running an hypothetical Microservice  application using Kubernetes and Apigee Edge Microgateway.

Future versions will be built using the popular service Mesh Istio - Kubernetes.  





**Apigee Edge Microgateway**  hybrid Cloud API management solution that:

-Reduce latency of API transference
-Keep API traffic within the enterprise-approved boundaries for security or compliance purposes.
-Continue processing messages if internet connection is temporarily lost.

The  Kubernetes  architecture is a system for automating deployment, scaling, and management of containerized applications.

**Minikube** is a tool that makes it easy to run Kubernetes locally. Minikube runs a single-node Kubernetes cluster inside a VM on your laptop for users looking to try out Kubernetes or develop with it day-to-day.




## Architecture



## Setup

### Pre-requisites
- Minikube  
- Apigee Edge
- Apigee  organization details with credentials (orgname, env, username, password)

### Local registry

In order to reduce  time and effort deploying  containers.

We will set  the docker daemon on minikube to be able to pull from a local registry  localhost:5000.

This is achieved by actually running a registry on minikube and then setting up a proxy so that the minikube VM port 5000 maps to the registry’s 5000.

- Make sure minikube is up  and running


```  
  minikube start
```
Use the following commands to setup a local registry for minikube:
```
docker run -d -p 5000:5000 --restart=always --name registry registry:2
```
Create a registry (a replication-controller and a service) and create a proxy to make sure the minikube VM’s 5000 is proxied to the registry service’s 5000
```
  kubectl create -f kube-registry.yaml
```
(Grab kube-registry.yaml from: https://gist.github.com/coco98/b750b3debc6d517308596c248daf3bb1 on github.)

At this point, ```minikube ssh && curl localhost:5000``` should work and give you a response from the docker registry.

Run following command for mapping the host 5000 to minikube  registry pods

```
kubectl port-forward --namespace kube-system \
$(kubectl get po -n kube-system | grep kube-registry-v0 | \
awk '{print $1;}') 5000:5000
```
After this, from the host ```curl -iv http://localhost:5000/v2/_catalog ``` should return a valid response from the docker registry running on minikube!


Non-linux people needs to map docker-machine’s 5000 to the host’s 5000 (no garantie)

```
ssh -i ~/.docker/machine/machines/default/id_rsa \
-R 5000:localhost:5000 \
docker@$(docker-machine ip)
```


 ### Build

- Build local docker containers  ```/microgateway-kubernetes-buzon```

```
  ./build-docker.sh
```



- Push the images in the  local  registry

```
  docker push localhost:5000/edgemicro

  docker push localhost:5000/buzon-getall
```


- Replace the microgateway docker image in ```minikube\kube\pods\buzon-getall-pods.yaml``` with the new docker images



  #### Configuration

For Apigee microgateway to run on Minikube we need two set of informations:

- Organization details: (orgname, env, username, password)
- Microgateway configuration: (max_connections, log level, plugins)

We will use **Kubernetes secrets** to store organization details and attach it to the microservice.

We can have different secrets for each  environment in the kube namespace. This will provide us flexibility to select right  environment for the microservices during deploy time. As result of which we can have: prod/test/dev env setup for the microservice in kube cluster.
We will use **Kubernetes configmap** to store Microgateway configuration and attach it to the microservice during deploy time.

We can have multiple configmap in our kube namespace. This provide us flexibility to categorize our microservices into logical groups having similar microgateway configuration.

Run the following commands to create a secret for the org/env pair and to create a configmap with default microgateway configuration.

Before running this command please update the ```minikube/kube/secrets/config.txt``` with right credentials:

```
kubectl create secret generic apigee-microgateway-buzon-dev-config --from-file=minikube/kube/secrets/config.txt
```

Run the following command to create a default configuration map in Minikube
Before running this command please have a look at ``` minikube/kube/configmaps/apigee-microgateway-default-config.yaml```


```
kubectl create -f minikube/kube/configmaps/apigee-microgateway-default-config.yaml

```



### Deploy  Microgateway in Apigee Edge
In this section we :

- Deploy Apigee microservice buzon-getall proxy
- Enable OAuth2 Authorization
- Deploy  buzon-getall microservice in minikube


A **microgateway-aware proxy** - This is a special proxy that Edge Microgateway can discover upon startup. Microgateway-aware proxies have a naming convention that you must follow: the name must being with edgemicro_. For example edgemicro_getall. When Edge Microgateway starts, it retrieves from Edge a list of microgateway-aware proxies from the same Edge organization and environment that you specified when you started Edge Microgateway.

For each microgateway-aware proxy, Edge Microgatway retrieves the target URL of the proxy and its base path. Microgateway-aware proxies also provide a convenient way to associate analytics data generated by Edge Microgateway with a proxy on the Edge platform. As the Microgateway handles API calls, it asynchronously pushes analytics data to Edge. Analytics data will show up in the Edge Analytics UI under the microgateway-aware proxy name(s), as it does for any other proxy.

A **product, developer, and developer app** - Edge Microgateway uses products, developers, and developer apps to enable OAuth2 access token or API key security. When Edge Microgateway starts, it downloads all of the product configurations from your Apigee Edge organization. It uses this information to verify API calls made through Edge Microgateway with API keys or OAuth2 access tokens.

Let's deploy buzon-getall proxy in our Apigee organization, in the right environment which is specified in the kube secret that is attached to  the buzon-getall microservice.

Follow the instructions bellow -
1. Goto http://edge-ui:port/login
2. Goto develop-> API proxies
3. Click on create proxy
4. Select **Reverse proxy**
   In the Build a Proxy wizard, select Reverse proxy (most common).
5. Click next   

In the Details page of the wizard, configure as follows:

  -Proxy name: **edgemicro_getall**
  -Proxy Base Path **/getall**
  -Existing API: **http://localhost**

   Since microgateway and buzon-getall microservice are both running in same POD, they can communicate over local network interface.

6. Click next  

7. Select **Pass through** authorization
8. Click next  
8. Select the environment where you want to deploy the proxy(same environment which is mentioned in the secret)
9. Click **Build and Deploy**


11. Create a product
Create a product that contains two proxies:

-A microgateway-aware proxy: **edgemicro_hello**

- The authentication proxy that was installed by Edge Microgateway: **edgemicro-auth**

In the Edge UI (Classic version), go to **Publish > Products**.

In the Products page, click **+ Product**. Fill out the Product

Details page as follows:

Name: EdgeMicroTestProduct

Display Name: EdgeMicroTestProduct

Environment: test and prod

Access: Public

Key Approval Type: Automatic

Resources:

  API Proxy: Select edgemicro_hello

  Revision: 1

  Resource Path: /**

  Click Import Resource.


In Resources, click +API Proxy
  Select edgemicro-auth
  Click Save.
12. Create a test developer
13. Go to Publish > Developers.
    In the Products page, click + Developer.
    Fill out the dialog to create a test developer.
14. Create a developer app
    You are going to use the client credentials from this app to make secure API calls through Edge Microgateway:

15. Go to Publish > Developer Apps.
    In the Developer Apps page,

    click + Developer App.

    Fill out the Developer App page as follows:

      Name: EdgeMicroTestApp

      Display Name: EdgeMicroTestApp

      Developer: If you created a test developer, select it.

      Or, you can use any existing developer for the purpose of this tutorial.

      Credentials:
      Select Expiration: Never.

      Click + Product and select EdgeMicroTestProduct (the product you just created)

      Click Save.
      You're back in the Developer Apps list page.

16. Select the app you just created, EdgeMicroTestApp.

17. Click Show next to the Consumer Key and Consumer Secret. It will be used as: [client_id]:[client_secret]




### Create pods and services in minikube
At second part we create pods and services with the Apigee microgateway
* Before to continue please verify, if addon-manager, ingress are enabled in Minikube.

```
minikube addons list

minikube addons enable addon-manager
minikube addons enable ingress

```

Notice that we have attached two volumes to the POD, which are basically the configuration for runtime.


Lets deploy the buzon-getall microservice. Run the bellow command

```
./setup/create-buzon-getall.sh
```

This will create and kube service and kube POD for buzon-getall microservice

Now microservice buzon-getall is protected by Apigee microgateway. Microgateway will pull the proxies configured for that environment.

### OAuth2 Authorization
This section we :
- Hit the microservice  we just deployed
- Get valid Authorization TOKEN from apigee UI and make succesfull calls.
- Generate traffic and see analytics for the microservice in apigee UI

Lets hit this microservice and see a glimps of API managment in action.

Open  the minikube dashboard

```
minikube dashboard
minikube service buzon-getall-svc-nodeport --url

```

Make calls
```
curl -i http://minikube-ingress/getall
```

You should be see Authorization failures '''{"error":"missing_authorization","error_description":"Missing Authorization header"}'''


The error occurs because you did not send a valid API key or access token with the request. By default, Edge Microgateway requires either an API key or an access token on every API call.



Make call below in order to obtain a valid access token and include it with the request.

```
curl -i -X POST --user [client_id]:[client_secret] "http://edge-ui:port/edgemicro-auth/token" -d '{"grant_type": "client_credentials"}' -H "Content-Type: application/json"

```

With an access token in hand, you can now make the API call securely. For example:

```
curl -i -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJhcHBsaWNhdGlvbl
9uYW1lIjoiYmU2YmZjYjAtMWQ0Ni00Y2IxLWFiNGQtZTMxNzRlNTAyMDZkIiwiY2xpZW50X2lkIjoiOGxTTTVIRHdyM
VhIT1ZwbmhURExhYW9FVG5STVpwWk0iLCJzY29wZXMiOltdLCJhcGlfcHJvZHVjdF9saXN0IjpbIk1pY3JvZ2F0ZXdh
eVRlQcm9kdWN0Il0sImCI6MTQzNTM0NzY5MiwiZXhwIjoxNDM1MzQ5NDkxfQ.PN30Y6uK1W1f2ONPEsBDB_BT31c6
IsjWGfwpz-p6Vak8r767tAT4mQAjuBpQYv7_IU4DxSrnxXQ_q536QYCP4p4YKfBvyqbnW0Rb2CsPFziy_n8HIczsWO
s0p4czcK63SjONaUpxV9DbfGVJ_-WrSdqrqJB5syorD2YYJPSfrCcgKm-LpJc6HCylElFDW8dHuwApaWcGRSV3l5Wx
4A8Rr-WhTIxDTX7TxkrfI4THgXAo37p3au3_7DPB_Gla5dWTzV4j93xLbXPUbwTHzpaUCFzmPnVuYM44FW5KgvBrV0
64RgPmIFUxSqBWGQU7Z1w2qFmWuaDljrMDoLEreI2g" http://minikube-ingress/getall
```


### References

https://github.com/kubernetes/minikube
http://docs.apigee.com/microgateway/content/edge-microgateway-home
https://apigee.com/about/blog/engineering/tutorial-deploying-apigee-edge-microgateway
https://github.com/kidiyoor/microgateway-kubernetes-demo
