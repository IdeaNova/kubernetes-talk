# Demo instructions

To run the demo steps as-is, the following is required:

1. `bash` / `unix utilities`. The sample commands use `bash` syntax.
2. `git`
3. `Vagrant`
4. `VirtualBox`
5. `kubectl`
6. `node.js`
7. `npm`
8. `docker`
9. `octant`

Downloading and setting up the above is not documented. Use google to find out on how to set up any of the above in your system.

The demo was prepared and tested on `macOS Big Sur`, and by using the `Homebrew` packaged distributions of the above tools.

## Preparation

Run local docker [registry](https://docs.docker.com/registry/deploying/), and configure local to use `192.168.56.1:5000` as an [insecure registry](https://docs.docker.com/registry/insecure/). This configuration is needed so that you can push locally built images to the local registry.

```:shell
docker run -d -p 5000:5000 --restart=always --name registry registry:2
```

## Demo Steps

1. Go to cluster

    ```:shell
    cd kluster
    ```

2. Start the cluster of VMs using Vagrant.

    ```:shell
    vagrant up
    ```

3. This will take several minutes, so prepare the app in the mean while. Go to sample-app

    ```:shell
    cd ../sample-app/
    ```

4. Create docker image from sample app

    ```:shell
    VERSION=1.0.0; REG=192.168.56.1:5000; docker build --build-arg VERSION=${VERSION} -t $REG/kubeintro-sample-app:${VERSION} -t $REG/kubeintro-sample-app:latest .
    ```

5. Push the image to the local registry:

    ```:shell
    docker push $REG/kubeintro-sample-app:$VERSION
    ```

6. Go back to the cluster

    ```:shell
    cd ../kluster
    ```

7. Once kluster is ready, the kluster configuration file is going to be under ~tmp/.kube_config. Merge this cluster configuation to the default config file (`~/.kube/config`).

    ```:shell
    env KUBECONFIG=tmp/.kube_config:~/.kube/config kubectl config view --flatten | tee ~/.kube/config > /dev/null
    ```

8. Start the proxy in background

    ```:shell
    kubectl proxy &
    ```

9. Launch octant and observe the cluster

    ```:shell
    octant
    ```

10. Deploy the app to the cluster

    ```:shell
    kubectl apply  -f ../sample-app/sample-app.yml
    ```

11. Observe the deployed artifacts under the namespace `kubeintro`.

12. Open the sample app in the proxy url. Refresh the page to notice differnet instances

    ```:shell
    open http://localhost:8001/api/v1/namespaces/kubeintro/services/http:sample-app-service:8080/proxy
    ```

13. Scale down the deployment to a single replica

    ```:shell
    kubectl scale deployment -n kubeintro sample-app-deployment --replicas=1
    ```

## Clean up

Shutdown vagrant vms, kube-proxy and remove docker registry.

```:shell
vagrant destroy -f
pkill kubectl
docker rm -f registry
```
