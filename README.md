# kolla-ansible

![image](https://github.com/user-attachments/assets/08689b21-5a8e-49e8-a98b-9d870b3ef70d)


🧱 Kolla-Ansible Multi-Node Deployment (3 Controllers, 1 Compute)
🧭 Objective
Deploy a basic OpenStack environment using Kolla-Ansible, with:

3 Controller Nodes (HA)

1 Compute Node

Separate internal and external networks

Core OpenStack services: Keystone, Glance, Nova, Neutron, Horizon, Cinder

🖥️ Node Layout
Hostname	Role	IP (Internal)	IP (External)
controller01	Controller	10.0.0.11	192.168.0.11
controller02	Controller	10.0.0.12	192.168.0.12
controller03	Controller	10.0.0.13	192.168.0.13
compute01	Compute	10.0.0.21	192.168.0.21
deploy	Deployment	10.0.0.10	192.168.0.10
📦 Requirements
On All Nodes
Ubuntu 22.04 / CentOS 9 Stream

At least 2 NICs: eth0 for internal, eth1 for external

Passwordless SSH from deploy node to all others

🛠️ Pre-Setup Steps
1. Install Dependencies on the Deploy Node
bash
Copy
Edit
sudo apt update
sudo apt install -y python3-dev libffi-dev gcc libssl-dev python3-pip
sudo pip3 install -U pip
pip install kolla-ansible ansible
2. Create Kolla Directories
bash
Copy
Edit
sudo mkdir -p /etc/kolla
sudo chown $USER:$USER /etc/kolla
cp -r /usr/local/share/kolla-ansible/etc_examples/kolla/* /etc/kolla
cp /usr/local/share/kolla-ansible/ansible/inventory/multinode .
📝 Configure Inventory File (multinode)
Example:

ini
Copy
Edit
[control]
controller01 ansible_host=10.0.0.11
controller02 ansible_host=10.0.0.12
controller03 ansible_host=10.0.0.13

[compute]
compute01 ansible_host=10.0.0.21

[monitoring]
controller01

[deployment]
localhost       ansible_connection=local
🔧 Configure Global Settings (/etc/kolla/globals.yml)
yaml
Copy
Edit
kolla_base_distro: "ubuntu"
kolla_install_type: "binary"

network_interface: "eth0"         # Internal interface
neutron_external_interface: "eth1" # External interface for Floating IPs

kolla_internal_vip_address: "10.0.0.100"
kolla_external_vip_address: "192.168.0.100"

enable_haproxy: "yes"
enable_cinder: "yes"
enable_horizon: "yes"
enable_neutron_provider_networks: "yes"

nova_compute_virt_type: "kvm"
🔐 Generate Passwords
bash
Copy
Edit
kolla-genpwd
🧪 Prechecks
bash
Copy
Edit
kolla-ansible -i multinode bootstrap-servers
kolla-ansible -i multinode prechecks
🚀 Deploy OpenStack
bash
Copy
Edit
kolla-ansible -i multinode deploy
📈 Post Deployment
Initialize OpenStack Environment
bash
Copy
Edit
kolla-ansible post-deploy
source /etc/kolla/admin-openrc.sh
Verify
bash
Copy
Edit
openstack service list
openstack network agent list
🌐 Access Horizon
URL: http://192.168.0.100/horizon

Username: admin

Password: (found in /etc/kolla/passwords.yml → keystone_admin_password)

📡 Network Configuration (Neutron)
Internal: VXLAN (overlay via eth0)

External: Flat network via eth1

Provider Network: setup in neutron with flat type

Example:

bash
Copy
Edit
openstack network create --provider-network-type flat --provider-physical-network physnet1 --external public
openstack subnet create --network public --subnet-range 192.168.0.0/24 --gateway 192.168.0.1 --no-dhcp public-subnet
