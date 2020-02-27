# k8s-lab

A reproducible Kubernetes lab.

## Introduction

The purpose of the project is to help play and experiment with Kubernetes in order to learn its internals while having total access to the control plane. There are easier tools such [minikube](https://github.com/kubernetes/minikube) to build single node Kubernetes, but it miss lot of fun as it doesn't support multiple nodes.

One of the goals is to provide a simple way to create a Kubernetes cluster to play with, break it and start again from scratch easily. In short, reproducibility. To achieve it a bunch of technologies are used:

- [Vagrant](https://www.vagrantup.com/) to manage local infraestructure as code
- [Terraform](https://www.terraform.io/) to manage cloud infraestructure as code
- [Ansible](https://www.ansible.com/) to provision the infrastructure as code
- [Kubeadm](https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm/) to build the Kubernetes cluster

In any case this solution should not be used for production, for that use case you should check great managed Kubernetes services such [GKE](https://cloud.google.com/kubernetes-engine/), [EKS](https://azure.microsoft.com/en-us/services/kubernetes-service/) or [AKS](https://aws.amazon.com/eks/).

## The Kubernetes cluster

The Kubernetes lab it's setup through kubeadm, one of the official Kubernetes deployment tools. It can build a simple single node cluster, up to a high availability cluster. The following cluster topologies are supported playing with the project configuration:

- [Single node](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#control-plane-node-isolation/), everything running in the same node, the workload and even the control plane.
- [multiple node](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/), running the workload across multiple nodes, and a single node for the control plane.
- [High availability](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/ha-topology/), both workload and control plane running in multiple nodes.

The high availability topology implements a [stacked](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/ha-topology/#stacked-etcd-topology/) layout, [external etcd](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/ha-topology/#external-etcd-topology/) layout it's out of scope on this project.

To have high availability in place it's needed a load balacer. This is achieved with a single external [Traefik](https://containo.us/traefik/) service. It implements a TCP load balancer at layer 4 for the control plane. Bear in mind it's not production ready, and ironically it's a single point of failure.

## The infrastructure

The infraestructure could be handled through infrestructure as code tools such Terraform in cloud or Vagrant for local resources. Botch provides a simple and quick way to create the whole cluster resources.

It's still possible to work with bare metal, or even with virtual machines already created manually. The only drawback is that you should create and mantain the Ansible inventory used for the playbook.

### Cloud

There are defined few Terraform templates to create all the infraestructure needed in Azure cloud. Everything concerning Terraform is stored inside the `cloud` folder.

All resources are created in the same resource group with a common prefix, which is based on the Terraform workspace. This is useful to setup and manage more Kubernetes clusters at the same time.

The template `variables.tf` defines all the details of the resources such the network values, VM sizes, images or even the SSH keys. There are VM definitions for each role, the number of the VMs per role will define the Kubernetes cluster layout.

Last but not least, the Terraform state is stored in an Azure blob storage called `miscellany`, please create or update it accordingly to your existing resources.

Once the plan it's applied an Ansible inventory it's created automagically under `out/inventory` folder, used to provision the Kubernetes service and its dependencies.

Warning for sailors! Due to Azure networking implementation Calico CNI is not working properly, please use other CNI provider in AZure such Weave Net.

### Local

The whole cluster is handled though a single Vagrantfile located in the `local` folder, it uses VirtualBox provider.

The Vagrantfile defines a set of variables such network values, boxes or the roles. Each role is defined through a hash dictionary where cpu, memory or
number of instances are specified, the number of the VMs per role will define the Kubernetes cluster layout.

Every VM is provisioned with a simple shell where python is installed in order to be able to process Ansible playbooks. Also the system netplan is patched adding a route for the seconf network interface, this is needed to run Weave Net as CNI provider.

In the last VM stage, the Ansible playbook is launched automatically to provision the Kubernetes cluster, it runs paralelly on all cluster VMs using a dinamic Ansible inventory provided by Vagrant.

## Provisioning the cluster

Once the infraestructure it's ready, as well as the Ansible inventory, the Ansible playbook `playbook/site.yml` can be executed.

To customize the Kubernetes cluster, just define variables to override the default values from the roles, such Kubernetes version, endpoint address and port, or a set of manifests to deploy.

In the deployment manifests list is where it's defined the CNI used, as well as other resources such the dashboard UI.

The playbook installs all the dependencies needed, and finally deploys the Kubernetes components depending the node role defined in the inventory. If it's declared more than one master, the first one will be used to initialize the cluster, and the rest of the masters will join to it afterwards.

Finally, all nodes defined will be jointed as well to the Kubernetes cluster.

After its execution, the Kubernetes cluster should be up & running. Its configuration to connect through kubeclt is available in `out/kube` folder. All master nodes are also setup to run kubectl out of the box.

## Step by step

### Cloud

#### Infrastructure

```
~/workspace$ ssh-keygen -f ~/.ssh/id_rsa_k8s -N ''
Generating public/private rsa key pair.
Your identification has been saved in ~/.ssh/id_rsa_k8s.
Your public key has been saved in ~/.ssh/id_rsa_k8s.pub.
...

~/workspace$ cd cloud

~/workspace/cloud$ terraform workspace new lab
Created and switched to workspace "lab"!
You're now on a new, empty workspace. Workspaces isolate their state,
so if you run "terraform plan" Terraform will not see any existing state
for this configuration.

~/workspace/cloud$ terraform apply
...
Apply complete! Resources: 18 added, 0 changed, 0 destroyed.
Outputs:
masters = [
  "lab-master1.*****.*****.***",
]
nodes = [
  "lab-node1.*****.*****.***",
  "lab-node2.*****.*****.***",
]
traefik = lab-traefik.*****.*****.***
```

#### Provision

```
~/workspace/cloud$ cd ..

~/workspace$ ansible-playbook playbook/site.yml -i out/inventory/lab
PLAY [all]
...
PLAY RECAP
lab-master1.*****.*****.*** : ok=22   changed=16   unreachable=0    failed=0
lab-node1.*****.*****.*** : ok=18   changed=12   unreachable=0    failed=0
lab-node2.*****.*****.*** : ok=17   changed=12   unreachable=0    failed=0
lab-traefik.*****.*****.*** : ok=17   changed=12   unreachable=0    failed=0
```

#### Operation

```
~/workspace$ cp out/kube/config ~/.kube/config

~/workspace$ kubectl get nodes
NAME          STATUS   ROLES    AGE     VERSION
lab-master1   Ready    master   4m57s   v1.17.3
lab-node1     Ready    <none>   4m20s   v1.17.3
lab-node2     Ready    <none>   4m20s   v1.17.3
```

### Local

#### Infrastructure & provision

```
~/workspace$ cd local

~/workspace/local$ vagrant up
Bringing machine 'k8s-master1' up with 'virtualbox' provider...
Bringing machine 'k8s-node1' up with 'virtualbox' provider...
Bringing machine 'k8s-node2' up with 'virtualbox' provider...
Bringing machine 'k8s-traefik' up with 'virtualbox' provider...
...
==> k8s-traefik: Running provisioner: ansible...
Vagrant has automatically selected the compatibility mode '2.0'
according to the Ansible version installed (2.5.1).
    k8s-traefik: Running ansible-playbook...
PLAY [all]
...
PLAY RECAP
k8s-master1                : ok=24   changed=18   unreachable=0    failed=0
k8s-node1                  : ok=20   changed=14   unreachable=0    failed=0
k8s-node2                  : ok=19   changed=14   unreachable=0    failed=0
k8s-traefik                : ok=17   changed=12   unreachable=0    failed=0
```

#### Operation

```
~/workspace/local$ cd ..

~/workspace$ sudo sh -c "echo 10.0.5.30 k8s-traefik >> /etc/hosts"

~/workspace$ cp out/kube/config ~/.kube/config

~/workspace$ kubectl get nodes
NAME          STATUS   ROLES    AGE   VERSION
k8s-master1   Ready    master   44m   v1.17.4
k8s-node1     Ready    <none>   44m   v1.17.4
k8s-node2     Ready    <none>   44m   v1.17.4
```
