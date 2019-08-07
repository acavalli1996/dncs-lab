# DNCS_LAB
Course of Design of Network and Communication Systems, University of Trento A.Y. 2018-2019

Elena Diana, Andrea Cavalli and Francesco Defilippo

## Index

  * Assignment

  * Network

  * Subnetting

      * Subnets

      * VLANs

      * IP addresses

  * Provisioning scripts

      * router-1

      * router-2

      * switch

      * host-1-b

      * host-1-a

      * host-2-c

  * Test
      
      * How to start

      * ifconfig

      * ping

      * ping -b

      * ovs-vsctl show

      * route -n

      * traceroute

      * arp -n

      * curl

## Assignment

Based the *Vagrantfile* ​and the provisioning scripts available at:
[https://github.com/dustnic/dncs-lab​](https://github.com/dustnic/dncs-lab​) 
the candidate is required to design a functioning network where any host configured and attached to​ *router-1​* (through ​*switch​*) can browse a website hosted on *host-2-c*.
The subnetting needs to be designed to accommodate the following requirement (no need to create more hosts than the one described in the vagrantfile):
- Up to 130 hosts in the same subnet of ​*host-1-a*
- Up to 25 hosts in the same subnet of *host-1-b*
- Consume as few IP addresses as possible

## Network

```


        +-----------------------------------------------------+
        |                                                     |
        |                                                     |eth0
        +--+--+                +------------+             +------------+
        |     |                |            |             |            |
        |     |            eth0|            |eth2     eth2|            |
        |     +----------------+  router-1  +-------------+  router-2  |
        |     |                |            |             |            |
        |     |                |            |             |            |
        |  M  |                +------------+             +------------+
        |  A  |                      |eth1                       |eth1
        |  N  |                      |                           |
        |  A  |                      |                           |
        |  G  |                      |                     +-----+----+
        |  E  |                      |eth1                 |          |
        |  M  |            +-------------------+           |          |
        |  E  |        eth0|                   |           | host-2-c |
        |  N  +------------+      SWITCH       |           |          |
        |  T  |            |                   |           |          |
        |     |            +-------------------+           +----------+
        |  V  |               |eth2         |eth3                |eth0
        |  A  |               |             |                    |
        |  G  |               |             |                    |
        |  R  |               |eth1         |eth1                |
        |  A  |        +----------+     +----------+             |
        |  N  |        |          |     |          |             |
        |  T  |    eth0|          |     |          |             |
        |     +--------+ host-1-a |     | host-1-b |             |
        |     |        |          |     |          |             |
        |     |        |          |     |          |             |
        ++-+--+        +----------+     +----------+             |
        | |                              |eth0                  |
        | |                              |                      |
        | +------------------------------+                      |
        |                                                       |
        |                                                       |
        +-------------------------------------------------------+


```

NOTE: during the development of the project, we did not apply any explicit operation on the interfaces *eth0*, since they are related to the Vagrant environment.

## Subnetting

### Subnets

We divided the network in four subnets:

 * **Subnet-1** includes the interfaces *eth1* of *router-1* and *eth1* of *host-1-a*.
 * **Subnet-2** includes the interfaces *eth1* of *router-1* and *eth1* of *host-1-b*.
 * **Subnet-3** includes the interfaces *eth2* of *router-1* and *eth2* of *router-2*.
 * **Subnet-4** includes the interfaces *eth1* of *router-2* and *eth1* of *host-2-c*.
 
### VLANs 

We configured the *router-1* and the *switch* so that two VLANs can share the single link between these devices.

 * The first VLAN corresponds to *subnet-1* and its VLAN-ID is 10.
 * The second VLAN corresponds to *subnet-2* and its VLAN-ID is 20.

For this reason, the interface *eth1* of *router-1* must be split into two subinterfaces, named respectively *eth1.10* and *eth1.20*.

### IP addresses

According to the assignment, *subnet-1* must be able to contain up to 130 host. Thus it needs at least 131 IP addresses, 130 for the hosts (including *host-1-a*) and one for the router. 
Similarly, *subnet-2* needs at least 26 IP addresses, while *subnet-3* and *subnet-4* need 2 IP addresses each.
Because of these observations, we assigned the IP addresses to the subnets in the following way:

|Subnet|Needed IPs|Netmask|Available IPs|Assigned IP block|
|:----:|:-------:|:-----:|:----------:|:----------------:|
|__Subnet-1__|131|24|2<sup>32-24</sup>-2=254|192.168.10.0/24|
|__Subnet-2__|26|27|2<sup>32-27</sup>-2=30|192.168.20.224/27|
|__Subnet-3__|2|30|2<sup>32-30</sup>-2=2|192.168.30.252/30|
|__Subnet-4__|2|30|2<sup>32-30</sup>-2=2|192.168.40.252/30|

NOTE: In the evaluation of the number *Needed IPs* we did not include the broadcast address and the network address. For this reason, we subtracted two from the number of *Available IPs*, since we considered only the addresses we could assign to the interfaces.

The addresses assigned to each interface in the network are shown in the table below.

|Device|Interface|Subnet|IP Address|
|:----:|:-------:|:-----:|:----------:|
|host-1-a|eth1|1|192.168.10.1/24|
|router-1|eth1.10|1|192.168.10.254/24|
|host-1-b|eth1|2|192.168.20.225/27|
|router-1|eth1.20|2|192.168.20.254/27|
|router-1|eth2|3|192.168.30.253/30|
|router-2|eth2|3|192.168.30.254/30|
|host-2-c|eth1|4|192.168.40.253/30|
|router-2|eth1|4|192.168.40.254/30|

## Provisioning scripts

### router-1

The first part of the script has the purpose to configure the subinterfaces in the router for the VLANs.

We divided the router's interface *eth1* into two subinterfaces, *eth1.10* and *eth1.20*, one for each VLAN. This was done adding two separate links associated to the *eth1* interface and specifying an ID for the respective VLAN.

```
ip link add link eth1 name eth1.10 type vlan id 10
```
```
ip link add link eth1 name eth1.20 type vlan id 20
```

Moreover, an IP address is assigned to every subinterface.
 
```
ip addr add 192.168.10.254/24 broadcast + dev eth1.10
```
```
ip addr add 192.168.20.254/27 broadcast + dev eth1.20
```

The option `broadcast +` sets the standard broadcast address in addition to the IP address. 
Finally, the links are activated by typing:

``` 
ip link set dev eth1.10 up
```
```
ip link set dev eth1.20 up
```
```
ip link set eth1 up
```

We used the same method to configure the router's interface *eth2*, with the difference that this interface does not require a subdivision into subinterfaces.

The remaining part of the script has the purpose to enable the IP forwarding through IPv4, using the command `sysctl net.ipv4.ip_forward=1`, and the purpose to configure the dynamic routing protocol OSPF on the router, using the following commands:

```
sed -i 's/zebra=no/zebra=yes/g' /etc/frr/daemons
sed -i 's/ospfd=no/ospfd=yes/g' /etc/frr/daemons

service frr restart

vtysh -c 'configure terminal' -c 'interface eth2' -c 'ip ospf area 0.0.0.0'
vtysh -c 'configure terminal' -c 'router ospf' -c 'redistribute connected'
```

### router-2

This provisioning script uses exactly the same kinds of commands of the previous script.

### switch

First of all, we created an OVS bridge. We refer to this with the name *switch-dnsc*.

```
ovs-vsctl add-br switch-dnsc
```

Then, we added the switch interface *eth1* to the bridge as a trunk port and set it up.

```
ovs-vsctl add-port switch-dnsc eth1
ip link set dev eth1 up
```

When adding the interfaces *eth2* and *eth3* to the bridge as ports, we specified the VLANs they belong to:

```
ovs-vsctl add-port switch-dnsc eth2 tag=10
ip link set dev eth2 up

ovs-vsctl add-port switch-dnsc eth3 tag=20
ip link set dev eth3 up
```

In the end, we set the system up with the command `ip link set dev ovs-system up`.

### host-1-a

The first two lines of the script assign the chosen IP address to the interface *eth1* of the host and set it up.

```
ip addr add 192.168.10.1/24 broadcast + dev eth1
ip link set eth1 up
```

As in the previous scripts, we added the option `broadcast +` to set the standard broadcast address.
The host needs a default gateway to communicate with the devices outside its subnet, but it already has one. So we specified a static route to the other subnets that uses the IP 192.168.10.254 (IP of *router-1*/*eth1.10*) as the next hop.
This can be done considering each subnet in a separate way:

```
ip route replace 192.168.20.224/27 via 192.168.10.254  
ip route replace 192.168.30.252/30 via 192.168.10.254 
ip route replace 192.168.40.252/30 via 192.168.10.254 
```

or considering them as a bigger single subnet:

```
ip route replace 192.168.0.0/18 via 192.168.10.254
``` 

### host-1-b

This provisioning script uses exactly the same kinds of commands of the previous script.

### host-2-c

We configured this host in the same way of *host-1-a* and *host-1-b*. Moreover, we made *host-2-c* host a website running Nginx in a Docker container:

```
mkdir -p /webpage/html
echo 'There is no sincerer love than the love of food. (G.B.Shaw)' > /webpage/html/index.html

docker run --name webserver -p 80:80 -d -v /webpage/html:/usr/share/nginx/html nginx
docker ps
```

## Test

The following paragraphs report the commands and the tools to test the proper functioning of the network.

### How to start

* Install Virtualbox and Vagrant
* Clone the repository typing `git clone https://github.com/acavalli1996/dncs-lab`
* Change the current folder to the cloned folder *dncs-lab* and launch the Vagrantfile:
```
cd dncs-lab
~/dncs-lab$ vagrant up
```
* Log into the VMs typing: `vagrant ssh router-1` `vagrant ssh router-2` `vagrant ssh switch` `vagrant ssh host-1-a` `vagrant ssh host-1-b` `vagrant ssh host-2-c`

### ifconfig

The command `ifconfig`, launched within each VM, allows to verify the effective actualization of the configuration realized in the provisioning scripts (that means the assignment of the IP addresses to the subnets and to the interfaces).

For example, the expected output for the host *host-1-a* is:

```
[04:14:57 vagrant@host-1-a:~] $ ifconfig
eth0      Link encap:Ethernet  HWaddr 08:00:27:20:c5:44  
          inet addr:10.0.2.15  Bcast:10.0.2.255  Mask:255.255.255.0
          inet6 addr: fe80::a00:27ff:fe20:c544/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:12167 errors:0 dropped:0 overruns:0 frame:0
          TX packets:5214 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000 
          RX bytes:9990831 (9.9 MB)  TX bytes:439490 (439.4 KB)

eth1      Link encap:Ethernet  HWaddr 08:00:27:e8:03:55  
          inet addr:192.168.10.1  Bcast:192.168.10.255  Mask:255.255.255.0
          inet6 addr: fe80::a00:27ff:fee8:355/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:8 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000 
          RX bytes:0 (0.0 B)  TX bytes:648 (648.0 B)

lo        Link encap:Local Loopback  
          inet addr:127.0.0.1  Mask:255.0.0.0
          inet6 addr: ::1/128 Scope:Host
          UP LOOPBACK RUNNING  MTU:65536  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0 
          RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)

```

### ping

To check the correct connection of the devices and the reachability among the hosts, we used the command `ping`.

For example, if we consider *host-1-a* and *host-2-c*, the output should be:

```
[06:19:36 vagrant@host-1-a:~] $ ping 192.168.40.253
PING 192.168.40.253 (192.168.40.253) 56(84) bytes of data.
64 bytes from 192.168.40.253: icmp_seq=1 ttl=62 time=1.65 ms
64 bytes from 192.168.40.253: icmp_seq=2 ttl=62 time=3.18 ms
64 bytes from 192.168.40.253: icmp_seq=3 ttl=62 time=1.24 ms
64 bytes from 192.168.40.253: icmp_seq=4 ttl=62 time=0.791 ms
^C
--- 192.168.40.253 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3005ms
rtt min/avg/max/mdev = 0.791/1.718/3.183/0.900 ms
```

If we consider *host-1-b* and *host-2-c*, the output should be:

```
[06:43:28 vagrant@host-1-b:~] $ ping 192.168.40.253
PING 192.168.40.253 (192.168.40.253) 56(84) bytes of data.
64 bytes from 192.168.40.253: icmp_seq=1 ttl=62 time=1.14 ms
64 bytes from 192.168.40.253: icmp_seq=2 ttl=62 time=1.18 ms
64 bytes from 192.168.40.253: icmp_seq=3 ttl=62 time=1.33 ms
64 bytes from 192.168.40.253: icmp_seq=4 ttl=62 time=1.32 ms
^C
--- 192.168.40.253 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3008ms
rtt min/avg/max/mdev = 1.147/1.248/1.338/0.084 ms
```

If we consider *host-1-b* and *host-1-a*, the output should be:

```
[06:44:15 vagrant@host-1-b:~] $ ping 192.168.10.1
PING 192.168.10.1 (192.168.10.1) 56(84) bytes of data.
64 bytes from 192.168.10.1: icmp_seq=1 ttl=63 time=1.73 ms
64 bytes from 192.168.10.1: icmp_seq=2 ttl=63 time=2.94 ms
64 bytes from 192.168.10.1: icmp_seq=3 ttl=63 time=0.797 ms
64 bytes from 192.168.10.1: icmp_seq=4 ttl=63 time=1.00 ms
^C
--- 192.168.10.1 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3006ms
rtt min/avg/max/mdev = 0.797/1.619/2.945/0.840 ms
```	

### ping -b

To test the effective isolation of the subnets corresponding to the VLANs, we launched a *ping* command to the subnets' broadcast addresses. 
Since *host-1-b* (in VLAN 20) is not in the same broadcast domain of *host-1-a* (in VLAN 10), and vice versa, when we execute this command, the *ping* should not receive any reply. 

So, for *host-1-a* we expect the output:

```
[04:15:01 vagrant@host-1-a:~] $ ping -b 192.168.10.255
WARNING: pinging broadcast address
PING 192.168.10.255 (192.168.10.255) 56(84) bytes of data.
^C
--- 192.168.10.255 ping statistics ---
5 packets transmitted, 0 received, 100% packet loss, time 4036ms
```

For *host-1-b* we expect the output:

```
[05:19:09 vagrant@host-1-b:~] $ ping -b 192.168.20.255
WARNING: pinging broadcast address
PING 192.168.20.255 (192.168.20.255) 56(84) bytes of data.
^C
--- 192.168.20.255 ping statistics ---
8 packets transmitted, 0 received, 100% packet loss, time 7041ms
```

### ovs-vsctl show

To verify that all the ports in the switch have been correctly associated to the right VLAN, the command `ovs-vsctl show` can be used, as it displays the details about the bridges on the switch and about their interfaces.

```
[05:25:21 vagrant@switch:~] $ sudo ovs-vsctl show
1659e6e6-3860-4c83-ac1b-b49fbc3a7d3b
    Bridge switch-dnsc
        Port "eth2"
            tag: 10
            Interface "eth2"
        Port "eth1"
            Interface "eth1"
        Port switch-dnsc
            Interface switch-dnsc
                type: internal
        Port "eth3"
            tag: 20
            Interface "eth3"
    ovs_version: "2.0.2"
```

### route -n

The command `route -n` displays the routing tables of the routers. 

The output should show that *router-1*:

* directly reaches *subnet-1* through the interface *eth1.10*
* directly reaches *subnet-2* through the interface *eth1.20*
* directly reaches *subnet-3* through the interface *eth2*
* reaches *subnet-4* considering 192.168.30.254 (*router-2*/*eth2*) as the IP of its next hop

and that *router-2*:
* reaches *subnet-1* and *subnet-2* considering 192.168.30.253 (*router-1*/*eth2*) as the IP of its next hop
* directly reaches *subnet-3* through the interface *eth2*
* directly reaches *subnet-4* through the interface *eth1*

```
[04:30:39 vagrant@router-1:~] $ route -n
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         10.0.2.2        0.0.0.0         UG    0      0        0 eth0
10.0.2.0        0.0.0.0         255.255.255.0   U     0      0        0 eth0
192.168.10.0    0.0.0.0         255.255.255.0   U     0      0        0 eth1.10
192.168.20.224  0.0.0.0         255.255.255.224 U     0      0        0 eth1.20
192.168.30.252  0.0.0.0         255.255.255.252 U     0      0        0 eth2
192.168.40.252  192.168.30.254  255.255.255.252 UG    20     0        0 eth2

```
```
[06:15:41 vagrant@router-2:~] $ route -n
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         10.0.2.2        0.0.0.0         UG    0      0        0 eth0
10.0.2.0        0.0.0.0         255.255.255.0   U     0      0        0 eth0
192.168.10.0    192.168.30.253  255.255.255.0   UG    20     0        0 eth2
192.168.20.224  192.168.30.253  255.255.255.224 UG    20     0        0 eth2
192.168.30.252  0.0.0.0         255.255.255.252 U     0      0        0 eth2
192.168.40.252  0.0.0.0         255.255.255.252 U     0      0        0 eth1
``` 

### traceroute

Thanks to the `traceroute` tool, it is possible to analyze the route, that is the path followed by the packets in the network in order to reach their final destination.

For example, if we consider *host-1-a*, we obtain:

```
[00:52:29 vagrant@host-1-a:~] $ traceroute 192.168.40.253
traceroute to 192.168.40.253 (192.168.40.253), 30 hops max, 60 byte packets
 1  192.168.10.254 (192.168.10.254)  4.306 ms  2.940 ms  4.250 ms
 2  192.168.30.254 (192.168.30.254)  4.127 ms  4.122 ms  4.235 ms
 3  * 192.168.40.253 (192.168.40.253)  3.844 ms *
```

As it can be noticed, the path of a packet from *host-1-a* (IP 192.168.10.1) to *host-2-c* (IP 192.168.40.253) goes through *router-1* (IP 192.168.10.254) and *router-2* (IP 192.168.30.254)


### arp -n

Another way to verify the isolation of the subnets corresponding to the VLANs is to launch a *ping* command from *host-1-a* to *host-1-b* and then to analyze the ARP cache of *host-1-a* using `arp -n`.

``` 
[06:35:27 vagrant@host-1-a:~] $ arp -n
Address                  HWtype  HWaddress           Flags Mask            Iface
192.168.10.254           ether   08:00:27:9c:23:a9   C                     eth1
10.0.2.2                 ether   52:54:00:12:35:02   C                     eth0
10.0.2.3                 ether   52:54:00:12:35:03   C                     eth0
```

If the two hosts were in the same subnet, they would communicate without passing through *router-1*. Anyway, in the ARP cache, we do not find the IP address of *host-1-b* (IP 192.168.20.225), but we find the IP address and the MAC address of *router-1*/*eth1.10* (IP 192.168.10.254, MAC 08:00:27:9c:23:a9)  

### curl

Finally, to verify that every host in *subnet-1* and *subnet-2* can browse the website on *host-2-c* (IP 192.168.40.253), we launched
`curl 192.168.40.253` from *host-1-a* and from *host-1-b*.
For both the hosts, we expect the output: 

```
[05:17:55 vagrant@host-1-a:~] $ curl 192.168.40.253
There is no sincerer love than the love of food. (G.B.Shaw)
```






















