# ATN setup

Group of helpers to download, setup and work within the ATN environment

The repository contains several helper scripts to prepare the environment for the ATN
kernel module.

## Initial preparation
Two or more nodes are required to test ATN functionality. This could be physical appliances or virtual VMs.
It's **ultimate important** to make sure there is a **direct Ethernet connection between the nodes**
since the implementation is based on LLC encapsulation and not using TCP/IP.

So any combination of the below, is expected not to work:

* Public cloud instances (unless they are based on the same dedicated host; a feature that needs to be enabled)
* Nodes behind any kind of firewall or NAT

To help out with environement preparation there is a script 'vbox_prepare.sh'.

This script will prepare 2 VMs running Ubuntu 18.04 Server. Second VM is created
as a Linked Clone from original VM.
Default user is 'test'. Password for 'test' and 'root' is 'test'

After machines are running the 'setup.sh' script from this repository need to be run on every machine. It will
prepare source code base and tools used during build and run. There are several ways to get it. You could
download it directly from here. Or clone complete git.

For example:
```sh
wget https://github.com/viaBlock/atn_setup/raw/master/setup.sh
chmod a+x setup.sh
./setup.sh
```
This will download all main repositories needed to run the code

## Working with the ATN stack
The main code is located in atn/. It contains kernel modules code, interface headers, simple test echo tool
and scripts to build, load and run.
### To build the code just run:
```sh
cd atn
make all
```

Descriptions of the atn/:
** test/chatapp.c - source code for test client. After build tool would be called test/chatapp.
Usage: test/chatapp [-sidv] [-l addr] [-r addr] [-m len] [msg]
  -s|--server  - start server
  -l|--local   - local address (must be specified for server and client)
  -r|--remote  - remote address (server address for clients)
  -i|--inet    - use IPv4 stack instead of ATN (emulate using IPv4 instead of ATN)
  -d|--dgram   - use DGRAM socket instead of RAW (not used for ATN)
  -v|--verbose - be verbose about data sent and received (show more debugs about data sent)
  -m|--msglen  - use random date of specified len
  msg          - optional message to send, use full MTU if neither msg or msglen specified

### To run test:

So the simple scenario requires server and client parts. Server is started in background and waiting for
requests from any client. Clients are talking to server via CLNP:

** Server instance (run from project root) specified with -s parameter:
```sh
./atn/test/chatapp -s -l <ATN address>
```
Server instance will receive message from client and send it back unmodified to the same client that originates the message

*** Client instance:
```sh
./atn/test/chatapp -l <client ATN address> -r <server ATN address> <msg1>
```
Client instance will perform verification between original message and reply from the server.

## Source code base
Original source code is stored inside git repository hosted on GitHub:
https://github.com/viablock/atn.git

There is no need to download code directly since the script [setup.sh](https://github.com/viaBlock/atn_setup/raw/master/setup.sh) will
automatically do it.

## Setup packet dump

TCPDUMP might be used for capturing packets sent/received by local host.
Please replace <if name> with proper interface which is used to connect to ATN network.
```sh
sudo /usr/sbin/tcpdump -U -q -e -i <if name> -nN -vvv -w clnp.pcap clnp &
```
The command above must be run on every host to capture complete traffic.

Packets would be captured on-fly and writtent to file clnp.pcap. The file could be later
used as an input to other network tools for advanced analyze.
For example wireshark:
```sh
wireshark clnp.pcap
```

## Hints on disabling IPv6
IPv6 protocol always assing network address to any interface available by default in most distros.
The easiest way is to disable this by using sysctl configurations. Just put this content into
**/etc/sysctl.d/99-disable-ipv6.conf** and restart the machine.

```sh
net.ipv6.conf.all.autoconf=0
net.ipv6.conf.all.accepot_ra=0
net.ipv6.conf.all.disable_ipv6=1
```

You could replace 'all' in the confiuguration with network interface used for ATN. This might be important if machine
still need to comunicated with IPv6 network.

## Simplified way to test
Special script 'run_test.sh' is created to run the majority of the above steps. It will build all software pieces, prepare kernel by loading
all required modules, and will run the 'chatapp' with the provided parameters. The parameters are very similar to chatapp.
run_test.sh is using chatapp as a core, but also helps out with build, cleanup and packet capturing and
simplified ATN address specification.

Usage: run_test.sh [-snt] -l addr [-r addr] msg1 [msg2 msg3 ...]
  -s   - start server
  -l   - local address (must be specified for server and client)
  -r   - remote address (server address for clients)
  -n   - do not clean/compile code
  -t   - run tcpdump in background
  msgX - messages to send out. Every message would be a space separated

### Server side:
```sh
./atn/run_test.sh -s -l <ifname or ATN address>
```

### Client side:
```sh
./atn/run_test.sh -l <ifname or ATN address> -r <server ATN address> <msg1> [<msg2> <msg3> ...]
```

For example if we are running with our VMs prepared with vbox_prepare.sh script:
On first VM (server, MAC address 080020BF3122, server ATN would be FA0000000000000000AAAA000000080020BF3122):
```sh
./atn/run_test.sh -s -l enp0s8
```
On second and all other VMs (clients, client ATN would be FA0000000000000000AAAA000000XXXXXXXXXXXX, where *XXXXXXXXXXXX* represent client MAC address for enp0s8 interface):
```sh
./atn/run_test.sh -l enp0s8 -r FA0000000000000000AAAA000000080020BF3122 <msg1>
```
