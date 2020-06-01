#!/bin/bash
# DHCP Server / Access Point with Internet Connection
# Author: Erebus
# Version: v1.0
# Last update: 2019/3/6

trap CTRL_C SIGINT

usage()
{
    echo "DHCP Server / Access Point with Internet Connection"
    echo "Usage: $0 [-w] [OPTION...] | [-h]"
    echo "  -h, --help                  Display this help menu"
    echo "  -w, --wireless              Assign if the network interface DHCP server's going to use is wireless"
    echo "  -i, --interface TARGET_NIC  The network interface your DHCP server is on (default: eth0, if -w is assigned: wlan0)"
    echo "  -s, --source NET_NIC        The network interface you have Internet connection on (default: eth1)"
    echo "  -g, --gateway GW            IP address of the gateway your DHCP server's going to use (default: 10.0.0.1)"
    echo "Prerequisites:"
    echo "  Dnsmasq installed with config file \"dnsmasq.conf\" located in /etc"
    echo "  Hostapd installed with config file \"hostapd.conf\" located in /etc/hostapd"
    echo "  Tested on Kali Linux 2018"
}


CTRL_C() {
    printf "\nSIGINT caught..."
    echo "End all running services"
    service dnsmasq stop
    if [[ $WIRELESS = true ]]; then
        service hostapd stop
        service network-manager restart
    fi
    echo DONE
    exit
}


RULE_ESTABLISH()
{
	# Flush all existing firewall rules to ensure that the firewall
	# is not blocking us from forwarding packets between the two interfaces
	sudo iptables -t nat -F
	sudo iptables -F
	# In order to be able to translate addresses between the two interfaces
	# Enable masquerading (NAT) in the linux kernel
	sudo iptables -t nat -A POSTROUTING -o $NET_NIC -j MASQUERADE
	# Enable forward between two interfaces
	sudo iptables -A FORWARD -i $TARGET_NIC -o $NET_NIC -j ACCEPT

	# Enable the kernel to forward packets between interfaces
	echo '1' > /proc/sys/net/ipv4/ip_forward
}


NET_SETUP()
{
	# Renew the network interface to make sure it is connected to the internet
    	#dhclient -r $NET_NIC
	dhclient $NET_NIC
	# Enable and set up the network interface your DHCP's going to use
	ifconfig $TARGET_NIC up
	ifconfig $TARGET_NIC $GW/24
	#ifconfig $TARGET_NIC inet6 add 2001::1/64
	# Assign the specified network interface and gateway to dnsmasq config file
	sudo sed -i "s/^interface.*/interface=$TARGET_NIC/g" /etc/dnsmasq.conf
	sudo sed -i "s/^dhcp-option=3.*/dhcp-option=3, $GW/g" /etc/dnsmasq.conf
    sudo sed -i "s/^dhcp-option=6.*/dhcp-option=6, $GW/g" /etc/dnsmasq.conf
    if [[ $WIRELESS == true ]];	then
    	sudo sed -i "s/^interface.*/interface=$TARGET_NIC/g" /etc/hostapd/hostapd.conf
    fi
}


SERVICE_START()
{
	# Enable the DHCP server
	service dnsmasq restart
	if [[ $WIRELESS == true ]];	then
		# Kill the processes that will interfere with the AP and start up the AP
		airmon-ng check kill
		hostapd /etc/hostapd/hostapd.conf
	fi
    # Keep the script running
    while :; do
        sleep 5
    done
}


TARGET_NIC="eth0"
NET_NIC="eth1"
GW="10.0.0.1"
WIRELESS=false

while [ "$1" != "" ]; do
    case $1 in
        -w | --wireless )       WIRELESS=true
                                TARGET_NIC="wlan0"
                                ;;
        -i | --interface )      shift
                                if [[ ! -d "/sys/class/net/$1" ]]; then
                                    echo "Interface \"$1\" not exist!"
                                    exit 1
                                fi
                                TARGET_NIC=$1
                                ;;
        -s | --source )     	shift
                                if [[ ! -d "/sys/class/net/$1" ]]; then
                                    echo "Interface \"$1\" not exist!"
                                    exit 1
                                fi
                                NET_NIC=$1
                                ;;
        -g | --gateway )        shift
                                GW=$1
                                ;;
        -h | --help )           usage
                                exit
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done

echo "Enabling NAT and IP forward..."
RULE_ESTABLISH
echo "Setting up the network interface and config file..."
NET_SETUP
echo "Enabling DHCP Server"
if [[ $WIRELESS == true ]]; then
    SSID=$(sed -n 's/^ssid=*//p' /etc/hostapd/hostapd.conf)
    echo "Enabling Access Point as SSID \"$SSID\""
fi
SERVICE_START
