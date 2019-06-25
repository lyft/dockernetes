FROM fedora:latest
COPY coredns.service /usr/lib/systemd/system/coredns.service
RUN dnf -y install kubernetes etcd
# enable the kubernetes components
RUN systemctl enable kube-proxy && \
    systemctl enable kubelet && \
    systemctl enable etcd && \
    systemctl enable kube-apiserver && \
    systemctl enable kube-controller-manager && \
    systemctl enable kube-scheduler && \
    systemctl enable coredns
# allow privileged containers
RUN echo "KUBE_ALLOW_PRIV=\"--allow-privileged=true\"" >> /etc/kubernetes/config && \
    # default config specifies 2379 & 4001. We only use the former (the latter is a legacy port).
    echo "KUBE_ETCD_SERVERS=\"--etcd-servers=http://127.0.0.1:2379\"" >> /etc/kubernetes/apiserver && \
    # tokencontroller needs the apiserver key and root ca file so coredns (and others) can auth.
    echo "KUBE_CONTROLLER_MANAGER_ARGS=\"--service-account-private-key-file=/var/run/kubernetes/apiserver.key \
        --root-ca-file=/var/run/kubernetes/apiserver.crt\"" >> /etc/kubernetes/controller-manager && \
    # There is a problem where kublet fails to init the top level QOS containers, probably something to do with creating cgroups inside a container
    # for now, disable the cgroups-per-qos and enforce-node-allocatable
    # https://github.com/kubernetes/kubernetes/issues/43704#issuecomment-289484654
    # also, we need to point the dns to the arbitrary chosen IP (10.254.0.10)
    # setting --cluster-domain ensures the correct /etc/resolv.conf search path
    echo "KUBELET_ARGS=\"--cgroup-driver=systemd \
        --cgroups-per-qos=false \
        --enforce-node-allocatable="" \
        --fail-swap-on=false \
        --kubeconfig=/etc/kubernetes/master-kubeconfig.yaml \
        --cluster-dns=10.254.0.10 \
        --cluster-domain=cluster.local\"" >> /etc/kubernetes/kubelet

COPY master-kubeconfig.yaml /etc/kubernetes/master-kubeconfig.yaml
COPY coredns.yaml /etc/kubernetes/manifests/coredns.yaml
