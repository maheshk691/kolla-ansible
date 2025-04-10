
# Kolla-Ansible Multi-Node Deployment (3 Controllers, 1 Compute)




## Tech Stack

**OpesnStack Deployment using:** Kolla-Ansible

**Server OS:** Ubuntu 22.04 LTS

**Tools:** Docker container, Local docker register, Python3, Ansible 2.17 and Virtual machine
 
## Requirements
Design and implement a fully automated deployment of an OpenStack environment using Ansible on an
EC2 instance running Ubuntu Jammy (22.04). The deployed OpenStack must support:

· Compute (Nova)

· Storage (Swift)

· Database (Trove)

. High Availability (HA) Architecture:

. Networking

. Security

. Error Handling and Rollback

. Monitoring and Logging

. Validation
## High Availability (HA) Architecture
Deploy a basic OpenStack environment using Kolla-Ansible.


3 Controller Nodes (HA)

1 Compute Node

Separate internal and external networks with 2 NICs:  ens3 for internal and ens4 for external

Passwordless SSH from the deploy node to all nodes.

![image](https://github.com/user-attachments/assets/729d92ff-af47-4333-a196-4d0a3c89d179)


## Deployment

To deploy this project run

Core OpenStack services: Keystone, Glance, Nova, Neutron, Horizon, Swift and Trove

Monitoring and Logging: 

Deploy OpenStack's Telemetry services Ceilometer, Grafana, and Prometheus for monitoring. 

Deploy centralized logging services like Opensearch and Fluentd

![kolla-ansible-target-openstack](https://github.com/user-attachments/assets/98ad5516-c629-4c2e-90d8-d234edbd1dd2)


## 🖥️ Node Layout

Hostname Role IP (Internal) IP (External)

kolla-controller-3 Controller 10.1.0.167 10.2.0.14

kolla-controller-3 Controller 10.1.0.45 10.2.0.211

kolla-controller-3 Controller 10.1.0.50 10.2.0.203

kolla-compute01 Compute 10.1.0.66 10.2.0.74

kolla jump box Deployment 10.0.0.10 10.2.0.10
## Installtion Setps

Create kolla user 

```bash  
adduser kolla
usermod -aG sudo kolla
echo "kolla ALL=(ALL) NOPASSWD:ALL" | tee /etc/sudoers.d/kola
```

Update the OS and install Python3 and required packages
```bash 
 apt-get update -y
 sudo apt-get install python3-dev libffi-dev gcc libssl-dev python3-selinux python3-setuptools python3-venv -y
 reboot
 ```

 Git clone the repo locally 
```bash 
 pip install -U pip
 pip install git+https://opendev.org/openstack/kolla-ansible@master
 kolla-ansible install-deps
  ```

  I
## Prepare initial configuration Inventory
Inventory

```bash  
cp ~/kolla-venv/share/kolla-ansible/ansible/inventory/* /etc/kolla

  ```
  Full file is in repo as multinode
```bash
vi multinode

# These initial groups are the only groups required to be modified. The
# additional groups are for more control of the environment.
[control]
# These hostname must be resolvable from your deployment host
kolla-controller-1
kolla-controller-2
kolla-controller-3

# The above can also be specified as follows:
#control[01:03]     ansible_user=kolla

# The network nodes are where your l3-agent and loadbalancers will run
# This can be the same as a host in the control group
[network]
kolla-controller-1
kolla-controller-2
kolla-controller-3

[compute]
kolla-compute1

[monitoring]
kolla-controller-1
kolla-controller-2
kolla-controller-3

```

Kolla passwords
Passwords used in our deployment are stored in /etc/kolla/passwords.yml file. All passwords are blank in this file and have to be filled either manually or by running random password generator:
```bash  
kolla-genpwd
  ```

  Create /etc/host file entry for the nodes and public url add it the local jumpbox

  ```bash
  cat /etc/hosts
 sudo tee -a /etc/hosts <<EOF
 ### LIST SERVERS FOR OPENSTACK
 10.1.0.167 kolla-controller-1 kolla-controller-1.internal.test.com
 10.1.0.45  kolla-controller-2 kolla-controller-2.internal.test.com
 10.1.0.50  kolla-controller-3 kolla-controller-3.internal.test.com
 10.1.0.66  kolla-compute1 kolla-compute1.internal.test.com
 10.1.0.10  internal.test.com
 10.2.0.14   kolla-controller-1.public.test.com
 10.2.0.211  kolla-controller-2.public.test.com
 10.2.0.203  kolla-controller-3.public.test.com
 10.2.0.74  kolla-compute1.public.test.com
 10.2.0.10  public.test.com
 EOF
```

Using ansible play book to copy this /etc/hots to all nodes
```bash
ansible-playbook -i multinode add_vip_hosts.yml
```

Create SSL certtifacte for the deployment 

```bash
kolla-ansible certificates -i multimode
```

Copy CA certificated to all nodes
```bash
ansible-playbook -i multinode install-internal-ca.yml
```

Now run the precheck for deployment


Run Bootstrap for the deployment will install docker and required package for kolla-ansible deployment  
```bash
 kolla-ansible bootstrap-servers -i multimode


PLAY RECAP *************************************************************************************************************************************************
kolla-compute1             : ok=36   changed=14   unreachable=0    failed=0    skipped=27   rescued=0    ignored=0
kolla-controller-1         : ok=36   changed=14   unreachable=0    failed=0    skipped=27   rescued=0    ignored=0
kolla-controller-2         : ok=36   changed=14   unreachable=0    failed=0    skipped=27   rescued=0    ignored=0
kolla-controller-3         : ok=36   changed=14   unreachable=0    failed=0    skipped=27   rescued=0    ignored=0
localhost                  : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

```bash
kolla-ansible prechecks -i multimode

TASK [loadbalancer : Checking if kolla_internal_vip_address and kolla_external_vip_address are not pingable from any node] *********************************
ok: [kolla-controller-2] => (item=10.1.0.10)
ok: [kolla-controller-1] => (item=10.1.0.10)
ok: [kolla-controller-3] => (item=10.1.0.10)
ok: [kolla-controller-1] => (item=10.2.0.10)
ok: [kolla-controller-3] => (item=10.2.0.10)
ok: [kolla-controller-2] => (item=10.2.0.10)



PLAY RECAP ******************************************************************************************************************************************************************************************************
kolla-compute1             : ok=20   changed=0    unreachable=0    failed=0    skipped=39   rescued=0    ignored=0
kolla-controller-1         : ok=65  changed=0    unreachable=0    failed=0    skipped=138  rescued=0    ignored=0
kolla-controller-2         : ok=65  changed=0    unreachable=0    failed=0    skipped=125  rescued=0    ignored=0
kolla-controller-3         : ok=65  changed=0    unreachable=0    failed=0    skipped=125  rescued=0    ignored=0
localhost                  : ok=10   changed=0    unreachable=0    failed=0    skipped=13   rescued=0    ignored=0
```

Deploy Kolla-ansbile 

```bash
kolla-ansible deploy -i multimode

PLAY RECAP ******************************************************************************************************************************************************************************************************
kolla-compute1             : ok=46   changed=0    unreachable=0    failed=0    skipped=39   rescued=0    ignored=0
kolla-controller-1         : ok=139  changed=0    unreachable=0    failed=0    skipped=138  rescued=0    ignored=0
kolla-controller-2         : ok=135  changed=0    unreachable=0    failed=0    skipped=125  rescued=0    ignored=0
kolla-controller-3         : ok=135  changed=0    unreachable=0    failed=0    skipped=125  rescued=0    ignored=0
localhost                  : ok=14   changed=0    unreachable=0    failed=0    skipped=13   rescued=0    ignored=0

```
Post deployment check 

```bash
(kolla-venv) kolla@kolla-jumpbox:~$  kolla-ansible post-deploy -i kolla-ansible/multinode
Post-Deploying Playbooks
[WARNING]: Invalid characters were found in group names but not replaced, use -vvvv to see details

PLAY [Creating clouds.yaml file on the deploy node] *************************************************************************************************************************************************************

TASK [Gathering Facts] ******************************************************************************************************************************************************************************************
[WARNING]: Platform linux on host localhost is using the discovered Python interpreter at /home/kolla/kolla-venv/bin/python3.10, but future installation of another Python interpreter could change the meaning
of that path. See https://docs.ansible.com/ansible-core/2.17/reference_appendices/interpreter_discovery.html for more information.
ok: [localhost]

TASK [Create /etc/openstack directory] **************************************************************************************************************************************************************************
changed: [localhost]

TASK [Template out clouds.yaml] *********************************************************************************************************************************************************************************
changed: [localhost]

PLAY [Creating admin openrc file on the deploy node] ************************************************************************************************************************************************************

TASK [Gathering Facts] ******************************************************************************************************************************************************************************************
ok: [localhost]

TASK [Template out admin-openrc.sh] *****************************************************************************************************************************************************************************
changed: [localhost]

TASK [Template out admin-openrc-system.sh] **********************************************************************************************************************************************************************
changed: [localhost]

TASK [Template out public-openrc.sh] ****************************************************************************************************************************************************************************
changed: [localhost]

TASK [Template out public-openrc-system.sh] *********************************************************************************************************************************************************************
changed: [localhost]

TASK [octavia : Template out octavia-openrc.sh] *****************************************************************************************************************************************************************
skipping: [localhost]

PLAY RECAP ******************************************************************************************************************************************************************************************************
localhost                  : ok=8    changed=6    unreachable=0    failed=0    skipped=1    rescued=0    ignored=0

```
