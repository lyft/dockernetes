# Dockernetes

Runs kubernetes inside a docker container.

Dockernetes is designed to be used for testing kubernetes applications in an isolated environment. It works on systems like Travis CI that do not support launching a Virtual Machine (thus, cannot use Minikube).

It is **not** safe for production use.

Currently, dockernetes provides no knobs for custom configuring the k8s cluster.

## Launching Dockernetes

To launch pods, the dockernetes container needs docker. Running docker inside the container requires generous privileges. 

To launch dockernetes, start the dockernetes container with generous privileges.

```
docker run \
  --detach \
  --privileged \
  --volume /var/lib/docker \
  --volume /lib/modules:/lib/modules \
  lyft/dockernetes:1.10.1-v0.1 /sbin/init
```

Once launched, shell into the container with `docker exec -it <container_id> /bin/sh` and run commands like ``kubectl cluster-info``  

Kubernetes boots in the container via [systemd](https://www.freedesktop.org/wiki/Software/systemd/). From inside the container, you can check if kubernetes has finished launching by running the following command.

``systemctl is-active --quiet multi-user.target``

# How we use dockernetes at Lyft

We include a kubernetes manifest in our github repo.

We have a target `make k8s_test` that does the following:

  1. Launch dockernetes (and mount the repo into the dockernetes container).

  1. `docker exec` into the dockernetes container and:

     1. Wait for kubernetes to launch with `systemctl is-active --quiet multi-user.target`.

     1. Run `kubectl apply -f { /path/to/mounted/k8s/manifest.yaml }`.

With this, our resources are created inside dockernetes. We can check the output of a running pod or exec into a pod and run commands. 

# Why not just use Minikube?

While Minikube is a great tool for local development, we had trouble getting it running in our CI system (Travis). Many CI systems don't allow spinning up a VM inside your job (even if they did, it's likely to be slow). At one time, Minikube supported a system called "localkube" which had been leveraged to handle this case, but that feature has since been deprecated.

While there is still bare-metal support in Minikube, we had trouble getting it running inside a container. Minikube leverages something called "pre-flight checks" that ensure certain criteria are met before launching your cluster. One such check is to ensure the ``br_netfilter`` kernel module is enabled by checking the file ``/proc/sys/net/bridge/bridge-nf-call-iptables``. That file wont exist inside your container, even if ``br_netfilter`` kernel module is enabled, because the ``br_netfilter`` kernel module is not namespace aware. 

https://github.com/lxc/lxd/issues/3306#issuecomment-303549292

We spent some time in the Minikube codebase, hoping to modify the pre-flight check. It began to feel as though we were hacking Minikube to work in an environment that it isn't designed for (inside a docker container).

# Why do we need another K8s-in-docker solution?

There are already two kubernetes SIGs that support running kubernetes in docker.

https://github.com/kubernetes-sigs/kubeadm-dind-cluster

https://github.com/kubernetes-sigs/kind

These projects are each geared toward simulating a multi-node kubernetes cluster (where one container represents each node). There is logic that runs on the host machine to configure the communication between nodes. This is great for testing how your system reacts to a node failure, but we had no need for that.

For testing our kubernetes native tools, all we need is a single node k8s deployment. This simpler cluster deployment provides a faster launch time with fewer failure points.

In Travis CI, we're able to launch kubernetes in about 30 seconds (with opportunities for further reductions).
