#!/bin/bash

basepath=/home/darkstar/netsim

# create the networks
brctl addbr net1
ip link set net1 up

brctl addbr net2
ip link set net2 up

#brctl addbr net3
#ip link set net3 up

#
# CISCO router environment
#

# create the routers
#lxc-create -n router1 -t ${basepath}/lxc/templates/lxc-dynamips -- --basepath=${basepath} --ioscfg=c3640-default --ether=0:0:veth0:net1:10.0.1.1:255.255.255.0 --serial=2:0:veth1:net3:10.0.3.1:255.255.255.0

#lxc-create -n router2 -t ${basepath}/lxc/templates/lxc-dynamips -- --basepath=${basepath} --ioscfg=c3640-default --ether=0:0:veth0:net1:10.0.1.2:255.255.255.0 --ether=0:1:veth1:net2:10.0.2.2:255.255.255.0

#lxc-create -n router3 -t ${basepath}/lxc/templates/lxc-dynamips -- --basepath=${basepath} --ioscfg=c3640-default --ether=0:0:veth0:net2:10.0.2.3:255.255.255.0 --serial=2:0:veth1:net3:10.0.3.3:255.255.255.0

# start everything
#lxc-start -n router1 -d
#lxc-start -n router2 -d
#lxc-start -n router3 -d

#
# ULTRIX environment
#

lxc-create -n router -t ${basepath}/lxc/templates/lxc-dynamips -- --basepath=${basepath} --ioscfg=c3640-default --ether=0:0:veth0:net1:10.0.1.1:255.255.255.0 --ether=0:1:veth1:net2:10.0.2.1:255.255.255.0

lxc-create -n simh1 -t ${basepath}/lxc/templates/lxc-simh -- --basepath=${basepath}  --simhmachine vax --simhos vax-ultrix40 --ether veth0:net1:10.0.1.2:255.255.255.0 --hostname simh1

lxc-create -n simh2 -t ${basepath}/lxc/templates/lxc-simh -- --basepath=${basepath}  --simhmachine vax --simhos vax-ultrix40 --ether veth0:net2:10.0.2.2:255.255.255.0 --hostname simh2

lxc-start -n router -d
lxc-start -n simh1 -d
lxc-start -n simh2 -d

