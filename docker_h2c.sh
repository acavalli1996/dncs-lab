sudo su

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y apt-transport-https ca-certificates curl software-properties-common --assume-yes --force-yes
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update
apt-get install -y docker-ce=18.06.1~ce~3-0~ubuntu jq --assume-yes --force-yes
apt-get install -y curl --assume-yes
apt-get install traceroute

ip addr add 192.168.40.253/30 broadcast + dev eth1
ip link set eth1 up

ip route replace 192.168.0.0/18 via 192.168.40.254 
#ip route replace 192.168.10.0/24 via 192.168.40.254 
#ip route replace 192.168.20.224/27 via 192.168.40.254 
#ip route replace 192.168.30.252/30 via 192.168.40.254 


#docker rm $(docker ps -a -q)

mkdir -p /webpage/html
echo 'There is no sincerer love than the love of food. (G.B.Shaw)' > /webpage/html/index.html

docker run --name webserver -p 80:80 -d -v /webpage/html:/usr/share/nginx/html nginx
docker ps




