sudo su

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y tcpdump --assume-yes
apt-get install -y openvswitch-common openvswitch-switch apt-transport-https ca-certificates curl software-properties-common

ovs-vsctl add-br switch-dnsc

ovs-vsctl add-port switch-dnsc eth1
ip link set dev eth1 up

ovs-vsctl add-port switch-dnsc eth2 tag=10
ip link set dev eth2 up

ovs-vsctl add-port switch-dnsc eth3 tag=20
ip link set dev eth3 up

ip link set dev ovs-system up
