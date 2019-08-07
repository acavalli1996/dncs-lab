sudo su

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y tcpdump --assume-yes
apt-get install -y curl --assume-yes
apt-get install traceroute

ip addr add 192.168.20.225/27 broadcast + dev eth1
ip link set eth1 up

ip route replace 192.168.0.0/18 via 192.168.20.254

#ip route replace 192.168.10.0/24 via 192.168.20.254 
#ip route replace 192.168.30.252/30 via 192.168.20.254 
#ip route replace 192.168.40.252/30 via 192.168.20.254 
  
