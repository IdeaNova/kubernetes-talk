# Demo instructions

To run the demo steps as-is, the following is required:

1. bash / unix utilities
2. git
3. Vagrant
4. VirtualBox
5. kubectl
6. node.js
7. npm
8. docker

Downloading and setting up the above is not documented, however, use google to find out on how to set up any of the above in your system.

The demo was prepared and tested on Mac OS X Mojave, and by using the Homebrew packaged distributions of the above tools.

## Demo Steps

1. Go to cluster

    ```:shell
    cd kluster/
    ```

2. Start the cluster of VMs using Vagrant

    ```:shell
    vagrant up
    ```

3. Go to sample-app

    ```:shell
    cd ../sample-app/
    ```

4. Create docker image from sample app

    ```:shell
    VERSION=1.0.0; docker build --build-arg VERSION=${VERSION} -t kubeintro-sample-app:${VERSION} -t kubeintro-sample-app:latest .
    ```

5. Go to kluster

    ```:shell
    cd ../kluster/
    ```

6. Set kubeconfig to point to our cluster

    ```:shell
    export KUBECONFIG=$(pwd)/.kube_config
    ``` 

7. Start the proxy in background

    ```:shell
    kubectl proxy &

8. Install dashboard and copy the token into the clipboard

    ```:shell
    ./install-dashboard.sh
    ```

9. Open dashboard in browser. Log in using the token stored

    ```:shell
    open http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/
    ```

10. Upload images to the worker nodes

    ```:shell
    ./push-docker-images.sh
    ```

11. Create a namespace

    ```:shell
    kubectl apply -f sampleapp-namespace.yaml
    ```

12. Observe namespace. Notice the pods won't start because of images are missing

13. Create a deployment for the sample-app

    ```:shell
    kubectl apply -f sampleapp-deployment.yaml
    ```

14. Observe the deployment under namespace kubeintro.

15. Create a service of the sample-app deployment

    ```:shell
    kubectl apply -f sampleapp-service.yaml
    ```

16. Open the sample app in the proxy url. Refresh the page to notice differnet instances

    ```:shell
    open http://localhost:8001/api/v1/namespaces/kubeintro/services/http:sample-app-service:8080/proxy
    ```

17. Scale down the deployment to a single replica

    ```:shell
    kubectl scale deployment -n kubeintro sample-app-deployment --replicas=1
    ```