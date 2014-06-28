## netsim

A simple framework for simulating small and large networks.

## Requirements

Currently, you should have at least the following:

* python 2.x
* lxc containers

For simulating VAXen etc.

* simh 4.0 beta (note that versions 3.x will not work out of the box)

For simulating Cisco routers:

* dynamips (I use 0.2.11)

You might also want to download the following archive which contains the larger binary files

* ka655x.bin from simh (note that this file is probably (c) by DEC)
* a few sample disk files, currently I only have one with Ultrix 4.0 for VAX installed. (note that this is probably also (c) DEC)
* A Cisco IOS image for your favorite router (I use the C3640 with the c3640-js-m.124-3g image). This is definitely (c) Cisco

You can download the archive here: http://goo.gl/do4yUn (~70 mb, uncompresses to a few hundred mb in sparse files)

## Usage

Unpack the binary files on top of your netsim checkout. The VAX microcode goes into `simh/roms`, the simh disks go into `simh/disks`, and the IOS image(s) go into `ios/images`.

Check out the sample script `mk_universe.sh` on how to use the framework.

Basically, you set up containers with the included lxc setup scripts from `lxc/templates`. You connect them to bridges which simulate the networks between the routers/machines.

Currently the following two container types are supported

###dynamips based Cisco router

You need a config file under `ios/configs` which looks like this

    # select the image under ios/images/
    ios_image=c3640-js-m.124-3g.bin
    
    # memory size for the router in MB
    ios_memory=128
    
    # router model
    ios_model=3600
    
    # idlepc value
    ios_idlepc=0x605f115c
    
    # additional command line args (for port cards)
    ios_params="-p 0:NM-4E -p 1:NM-4E -p 2:NM-4T"

The config file defines the required settings. You can leave out the `ios_idlepc` if you don't have/want/need it. All other variables are required.

Then, start your container (where `${netsim}` is the directory where you have your netsim checkout):

    lxc-create -n router1 -t ${netsim}/lxc/templates/lxc-dynamips -- 
        --basepath=${netsim} --ioscfg=c3640-default --ether=<etherdef> --serial=<serialdef>

The `<etherdev>` argument works like this: `<router-slot>:<router-port>:<interfacename>:<bridge>:<ip>:<netmask>`

* `<router-slot>` and `<router-port>` define the slot/port the network connects to
* `<interfacename>` is an arbitrary (but short) name for the virtual ethernet interface of your container
* `<bridge>` is the bridge device in the global network namespace (you have to create this beforehand!). Note that these (right now) need to be in the root namespace. Someone should fix lxc to support veth pairs in 2 different namespaces ;-)
* `<ip>` and `<netmask>` should be obvious

The `<serialdef>` argument works similar, but it is used to connect routers via virtual serial ports (slot 2 in the config file above, for example). It has the same syntax: `<router-slot>:<router-port>:<interfacename>:<bridge>:<ip>:<netmask>` and simulates a serial link over a veth pair. The reason it is separate is that we might want to define the encapsulation here in the future.

### simh based simulator

For now I only added the VAX simulator. It works similar to the dynamips-based container but simulates a single-attached machine (you could call it a *VM*). The syntax is as follows:
    lxc-create -n myvax -t ${netsim}/lxc/templates/lxc-simh -- 
        --basepath=${netsim} --simhmachine vax --simhos vax-ultrix40
        --ether <etherdef> --hostname ultrix

The parameters are as follows:

* `<basepath>` is the path to your netsim checkout
* `<simhmachine>` selects the base config from `simh/configs`, in this case `machine-vax` (i.e. it prepends `machine-` to the file name). See below for the format of the config file.
* `<simhos>` selects the OS part of the config. Also see below.
* `<ether>` defines the ethernet link. It only supports one ethernet link (in simh, this is `qe0`). The format is `<interfacename>:<bridge>:<ip>:<netmask>` with the same meaning as above for Cisco/dynamips routers
* `<hostname>` sets the hostname for the VM. It is optional, and when left out the hostname defaults to the name of the container.

The machine config file should define these variables:

    # SimH config for a VAX box
    
    # the simh binary to use
    simh_binary="vax"
    
    # the microcode (if any) from simh/roms directory. OPTIONAL.
    simh_rom_file="ka655x.bin"
    
    # base config for this machine
    simh_base_config="
    ; SimH config file for MicroVAX 3800
    
    load -r ka655x.bin
    
    ; set VAX bootloader to autoboot
    dep bdr 0
    
    attach NVR nvram.bin
    
    set CPU 64m
    set CPU conhalt
    set CPU idle=all
    
    set TTI 7b
    set TTO 7b
    
    ; set RQ0 ra70
    set RQ1 dis
    set RQ2 dis
    set RQ3 CDROM
    
    set TQ tk50
    set TQ1 dis
    set TQ2 dis
    set TQ3 dis
    
    set LPT dis
    set RL dis
    set TS dis
    "

Especially note the multi-line variable `simh_base_config` which is basically a rudimentary simh configuration file for that machine. Note that disks and ethernet will be defined later by the template, and finally a "boot cpu" line will also be added. The NVRAM should always be called nvram.bin as that is the name the lxc-scripts use to set everything up.

The second config file depends on the OS you want to boot that machine with. Here's a short example:
    # SimH OS config file

    # the NVRAM file to use from simh/nvram/    
    simh_nvram_file="nvram-vax-ultix40.bin"
    
    # the disk type and file to use. disks are in simh/disks
    simh_disk0_type="ra70"
    simh_disk0_controller="RQ0"
    simh_disk0_file="ra70-vax-ultix40.dsk"
    
    # patch the bootdisk, if possible/required
    # params are
    # $1 basedir, where bin/inject.py can be found
    # $2 = path to disk image
    # $3 = hostname
    # $4 = ip address
    # $5 = netmask
    
    simh_patch_bootdisk()
    {
        basedir=$1
        disk=$2
        name=$3
        ip=$4
        netmask=$5
    
        ....
    }

The `simh_nvram_file` is optional and specifies a pre-existing NVRAM file. This can be useful for setting the boot device beforehand. `simh_disk0_xxx` and `simh_disk1_xxx` (not used here) define the first one or two disk(s) to attach. Here, it's a single disk of type `ra70`, attached to `RQ0`.

The `simh_patch_bootdisk()` function is important for *injecting* the configuration into the machine. As Linux cannot mount such an old UFS filesystem read/write (r/o works though) we need a clever way of injecting the config. See the next section below on how to do it

If you want to see an example, just look at the full config file and the bin/inject.py script.

## Config injection
To configure networking on the copied disk file, we use a trick

* First, install your OS using any method you want. This will be your "master" or "template" disk. I installed Ultrix 4 using this method: http://goo.gl/nRm4E3
* Then, boot the "master" disk and create a new file, say, `/etc/configure`, with exactly 1024 hash characters. Make it executable and start it from your `/etc/rc.local` during early boot (or whatever mechanism your guest OS uses for configuration). This should not have any implications as the file is treated as a single line of comments. My `rc.local` for ultrix 4.0 looks like this:

        # @(#)rc.local  2.11    (ULTRIX)        1/25/90
        /bin/hostname ultrix
        #/etc/ifconfig HDWR `/bin/hostname` broadcast NETNUM.0 netmask 255.0
        sh /etc/customize
        /etc/ifconfig lo0 localhost
        #/etc/bscconfig dup0 bsc 1
        ...
* shut down the emulation and make a copy of the disk file
* then, in your `simh_patch_bootdisk()` function, use the `bin/inject.py` script to replace the 1024-byte block of hash characters with a (generated) config file.

    **Note**: Your config file must also be exactly 1024 bytes in size. Otherwise it will be filled up at the end with hashes

* Note that the `inject.py` script does minimal error checking. If two or more blocks of 1024 hash characters exist (e.g. because you created the file in `/tmp` and then copied it to `/etc` instead of moving it), it will happily replace all with your config.


## Running your containers
Just use `lxc-start` to start up your containers. They will have a full init based runtime system and even have busybox installed (although it's commented out in `/etc/inittab`). If you start it in the background you should connect to its console via `lxc-console -n <name> -t 0`

**Note**: Please shut down the simh based VMs manually before running `lxc-stop` on them, otherwise you might corrupt your disks

## TODO
Some TODOs:

* more error checking, both in the lxc-scripts, and in the inject.py script.
* add more config options to the router and simh, like default gateway and maybe even DNS or something. Right now you need to launch your containers and configure these things from within. Unless you destroy your containers, everything will be persistent though.
* More simh based machines (PDP11? more VAXen?) and operating systems (VMS? 4.xBSD?) Ideas can be found here: http://gunkies.org/wiki/Main_Page
* QEmu VMs (windows? DOS?)
* HP router/switch simulator? (it's based on QEmu)
* NetApp simulator? (this should be fun ... very difficult to customize I think)
* ...etc...
