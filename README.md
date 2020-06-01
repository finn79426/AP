# AccessPoint4Test

在虛擬機裡面架個無線AP

# Require

- `WiFi Dongle`
- `apt update`
- `apt install hostapd`
- `apt install bridge-utils`

# Usage

```
DHCP Server / Access Point with Internet Connection
Usage: ./ap.sh [-w] [OPTION...] | [-h]
  -h, --help                  Display this help menu
  -w, --wireless              Assign if the network interface DHCP server's going to use is wireless
  -i, --interface TARGET_NIC  The network interface your DHCP server is on (default: eth0, if -w is assigned: wlan0)
  -s, --source NET_NIC        The network interface you have Internet connection on (default: eth1)
  -g, --gateway GW            IP address of the gateway your DHCP server's going to use (default: 10.0.0.1)
Prerequisites:
  Dnsmasq installed with config file "dnsmasq.conf" located in /etc
  Hostapd installed with config file "hostapd.conf" located in /etc/hostapd
  Tested on Kali Linux 2018
```

`./ap.sh -s <Internet Connected Adapter> -i <WiFi Dongle>`

# Case 1: Build a Wireless MitM-able Environment

## Platform

- Laptop: Macbook Air 2017 (Only 1 WiFi Adapter)
- VM: VMware Fusion 11
- Image: Kali Linux 2019.4

## Extra Requirements

- 1 RJ-45 Adapter (Mini DP is Best choice)

## Target

- Build-In WiFi Adapter as Bridge Adapter of VM (Internet Connected)
- RJ-45 Adapter Connect to DUT Device
- WiFi Dongle and RJ-45 in the same network
- WiFi Dongle and RJ-45 can ping to `google.com`

## Steps

1. Set Build-In Adapter as Bridged
2. Set RJ-45 Adapter as Bridged
3. `brctl addbr br0` (`ip addr show` to check)
4. `brctl addif br0 <RJ-45>`
5. Put `./hostapd.conf` to `/etc/hostapd/`
6. `service hostapd restart`
7. Edit `./dnsmasq.conf`, rename the `interface` to RJ-45 Adapter
8. Put `./dnsmasq.conf` to `/etc/`
8. `./ap.sh -s <Build-In> -i br0`

The IP Range of the RJ-45 and WiFi Dongle and the Device connected to WiFi Dongle：`10.0.0.10-15 ==> /28`
Collect all traffic between RJ-45 and WiFi Dongle: Aim at `br0`

- `brctl delif br0` if it is no longer used

---

# Q&A

Q: 我作爲虛擬機 NAT 的網卡明明拿到 ip 了，但卻怎麽 ping 也 ping 不出去，顯示 Network Unreachable 怎麽回事？
A: 估計是因爲頻繁切換 WiFi 導致 NAT 的路由跑掉了，通常輸入以下指令可以解決 `route add default gw 192.168.xx.1`，xx 要根據你的 mask 來改成正確的數字。
