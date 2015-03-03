#!/bin/sh
#
# - iptables ruleset generator
#
# - qtables@radom.org
#
# - please make sure to read the readme file
#
# - use this at your own risk.  this is supplied
#   without any warranty stated or implied.  this
#   means you're on your own if you use this software
#


### don't run this as root ###
if [ `whoami` = "root" ]; then
	echo ""
	echo ""
	echo "running quicktables as the root user is not necessary, and it is not a good idea.  there may not be any particular security reason not to run quicktables as root, but it's a good practice to get into"
	echo ""
	echo -n "press enter to continue or hit the ctrl + c keys to exit: "
	read noroot
fi


### user notices ###
echo ""
echo "	use this at your own risk.  this is supplied without any warranty"
echo "	stated or implied.  this means you're on your own if you use this"
echo "	software, and that you will not hold the author responsible for any"
echo "	problems or issues related to the use of this software."
echo ""
echo ""
echo "	although it isn't required that you run the quicktables script on the"
echo "	firewall machine itself, it is recommended.  quicktables will attempt"
echo "	to determine the likely answers to many questions simplifying the entire"
echo "	process.  quicktables is really only able to do this when ran on the"
echo "	firewall machine.  when not running quicktables on the firewall machine"
echo "	itself you may notice things like missing IP addresses in some of the"
echo "	questions.  you will have the opportunity to manually enter any and all"
echo "	IP addresses that quicktables needs to generate the firewall script"
echo ""
echo ""
echo "	please make sure to read the readme file"
echo ""


### set path and other variables ###
export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
out="rc.firewall"
date=`date '+%Y.%m.%d.%S'`


### define regex for ip and interface validation ###
is_ip="grep -Ec '^[1-2]?[0-9]?[0-9]\.[0-2]?[0-9]?[0-9]\.[0-2]?[0-9]?[0-9]\.[0-2]?[0-9]?[0-9](\/[0-3]?[0-9])?$'"
is_if="grep -Ec '^(eth|ppp|wlan|tun)[0-9]$'"

### don't overwrite existing output file if present ###
if [ -f $out ]; then
	echo ""
	echo "$out already exists in your working directory.  if you choose to continue your current $out will be saved as $out-X where X is a number from 1 to 5.  this allows you to run quicktables up to 5 times without it overwriting any existing rc.firewall files.  the oldest rc.firewall script will have the highest number."
	echo ""
	echo -n "do you wish to continue (yes/no) : "
	read continue
	echo ""

	while [ x$continue != "xyes" ] && [ x$continue != "xno" ]; do
		echo ""
		echo "i didn't understand your last answer"
		echo ""
		echo -n "do you wish to continue (yes/no) : "
		read continue
	done

	if [ $continue = "yes" ]; then
		if [ -e $out-5 ]; then rm -f $out-5; fi
		if [ -e $out-4 ]; then mv $out-4 $out-5; fi
		if [ -e $out-3 ]; then mv $out-3 $out-4; fi
		if [ -e $out-2 ]; then mv $out-2 $out-3; fi
		if [ -e $out-1 ]; then mv $out-1 $out-2; fi
		if [ -e $out ]; then mv $out $out-1; fi
	else
		exit 0;
	fi
fi


### path to iptables ###
iptables=`which iptables`
if [ ! -e "$iptables" ]; then
	echo ""
	echo ""
	echo "iptables not found.  iptables probably isn't installed on this system, as i've already checked the normal locations.  please provide the path to iptables now: "
	echo ""
	echo -n "what is the path to iptables: "
	read iptables
	while [ -z "$iptables" ]; do
		echo ""
		echo "i didn't understand your last answer"
		echo ""
		echo -n "what is the path to iptables: "
		read iptables
	done

else
	echo ""
	echo -n "iptables was found at $iptables.  is that the location you wish to use in your firewall script (yes/no) : "
	read continue

	while [ x$continue != "xyes" ] && [ x$continue != "xno" ]; do
		echo ""
		echo "i didn't understand your last answer"
		echo ""
		echo -n "iptables was found at $iptables.  is that the location you wish to use in your firewall script (yes/no) : "
		read continue
	done

	if [ $continue = "no" ]; then
		echo ""
		echo -n "what is the path to iptables: "
		read iptables
		while [ -z "$iptables" ]; do
			echo ""
			echo "i didn't understand your last answer"
			echo ""
			echo -n "what is the path to iptables: "
			read iptables
		done
	fi
fi


### external interface ###
ext_if=`route |grep default |awk '{print $8}'`
echo ""
echo ""
echo -n "i have determined that the interface that connects you to your ISP (untrusted network) is $ext_if.  is this the interface you want to use in your firewall script (yes/no) : "
read continue

while [ x$continue != "xyes" ] && [ x$continue != "xno" ]; do
	echo ""
	echo "i didn't understand your last answer"
	echo ""
	echo -n "is this the interface you want to use in your firewall script (yes/no) : "
	read continue
done

if [ $continue = "no" ]; then
	echo ""
	echo -n "which interface connects you to your ISP (untrusted network): "
	read ext_if
fi

while [ `echo $ext_if |eval $is_if` != "1" ]; do
	echo ""
	echo "$ext_if doesn't seem like a valid interface name"
	echo ""
	echo -n "which interface connects you to your ISP (untrusted network): "
	read ext_if
done


### nat ###
echo ""
echo ""
echo "nat, or network address translation, allows you to connect multiple computers on a private network to the internet using a single internet IP address.  if you have multiple computers and want to use your linux system as a router you need to answer yes to the next question"
echo ""
echo -n "would you like to use NAT (yes/no) : "
read nat

while [ x$nat != "xyes" ] && [ x$nat != "xno" ]; do
	echo ""
	echo "i didn't understand your last answer"
	echo ""
	echo -n "would you like to use NAT (yes/no) : "
	read nat
done

if [ $nat = "yes" ]; then
	echo ""
	echo -n "your internal interface connects your computer to your LAN (trusted network).  which interface is your internal interface: "
	read int_if

	while [ -z "$int_if" ]; do
		echo ""
		echo "i didn't understand your last answer"
		echo ""
		echo -n "which interface is your internal interface: "
		read int_if
	done

	while [ `echo $int_if |eval $is_if` != "1" ]; do
		echo ""
		echo "$int_if doesn't seem like a valid interface"
		echo ""
		echo -n "which interface is your internal interface: "
        read int_if
	done

	echo ""
	echo "we now need to know what network(s) to nat.  if your internal ip address is 192.168.0.10 and your netmask is 255.255.255.0 you would answer 192.168.0.0/24 to this question."
	echo ""
	echo -n "what network(s) would you like to nat: "
	read masq_nets

	while [ -z "$masq_nets" ]; do
		echo ""
		echo "i didn't understand your last answer"
		echo -n "what networks would you like to nat: "
		read masq_nets
	done

	echo ""
	echo "a static IP address is one that is assigned specifically to your internet account, and never changes.  a dynamic IP address is one that is usually assigned by your ISP.  If you're using a static IP address you would know that.  If you're using a cable modem, or your basic residential DSL or dialup service your IP address is most likely dynamic.  if you're unsure please answer dynamic to the following question"
	echo ""
	echo -n "is your internet IP address a dynamic or static address (dynamic/static) : "
	read masq_type

	while [ -z $masq_type ]; do
		echo ""
		echo "i didn't understand your last answer"
		echo ""
		echo -n "is your internet IP address a dynamic or static address (dynamic/static) : "
		read masq_type
	done

	while [ x$masq_type != "xdynamic" ] && [ x$masq_type != "xstatic" ]; do
		echo ""
		echo "i didn't understand your last answer"
		echo ""
		echo -n "is your internet IP address a dynamic or static address (dynamic/static) : "
		read masq_type
	done

	if [ $masq_type = "static" ]; then
		ext_addr=`ifconfig $ext_if |grep inet |cut -f2 -d: |cut -f1 -d" "`
		echo ""
		echo -n "i see that your internet IP address is $ext_addr.  is this the static IP address you wish to use for nat (yes/no) : "
		read match_static

		while [ -z $match_static ] ; do
			echo ""
			echo "i didn't understand your last answer"
			echo ""
			echo -n "is $ext_addr the static IP address you wish to use for nat (yes/no) : "
			read match_static
		done

		if [ x$match_static != "xyes" ] && [ x$match_static != "xno" ]; then
			echo ""
			echo "i didn't understand your last answer"
			echo ""
			echo -n "is $ext_addr the static IP address you wish to use for nat (yes/no) : "
			read match_static
		fi

		if [ $match_static = "yes" ]; then
			export static_ip=$ext_addr
		else
			echo ""
			echo -n "what is the static IP address you want to use for nat : "
			read static_ip

			while [ -z $static_ip ]; do
				echo ""
				echo "i didn't understand your last answer"
				echo ""
				echo -n "what is the static IP address you want to use for nat : "
				read static_ip
			done

			while [ `echo $static_ip |eval $is_ip` != "1" ]; do
				echo ""
				echo "$static_ip doesn't seem to be a valid IP address"
				echo ""
				echo -n "what is the static IP address you want to use for nat : "
			done
		fi
	fi
fi


### icmp ###
echo ""
echo ""
echo -n "would you like your internet IP address to be pingable (yes/no) : "
read icmp

while [ -z $icmp ]; do
	echo ""
	echo "i didn't understand your last answer"
	echo ""
	echo -n "would you like your internet IP address to be pingable (yes/no) : "
	read icmp
done

while [ x$icmp != "xyes" ] && [ x$icmp != "xno" ]; do
	echo ""
	echo "i didn't understand your last answer"
	echo ""
	echo -n "would you like your internet IP address to be pingable (yes/no) : "
	read icmp
done

echo ""
echo ""
echo "icmp has many messages that are generated by a type field.  certain types of icmp messages have no business coming into the average network.  saying yes to the following question will block incoming icmp types redirect, router advertisement, router solicitation, address mask request, and address mask reply from the internet.  if you don't know what any of this means then you should also answer yes to the following question."
echo ""
echo -n "would you like to use icmp type restriction to block unwanted icmp types from the internet (yes/no) : "
read icmp_type_block

while [ -z $icmp_type_block ]; do
	echo ""
	echo "i didn't understand your last answer"
	echo ""
	echo -n "would you like to use icmp type restriction to block unwanted icmp types from the internet (yes/no) : "
	read icmp_type_block
done

while [ x$icmp_type_block != "xyes" ] && [ x$icmp_type_block != "xno" ]; do
	echo ""
	echo "i didn't understand your last answer"
	echo ""
	echo -n "would you like to use icmp type restriction to block unwanted icmp types from the internet (yes/no) : "
	read icmp_type_block
done


### tcp allows - INPUT chain ###
echo ""
echo ""
echo "if you run any services on your firewall machine you need to allow connections to their ports.  this option is mostly for standalone non-nat setups or for allowing ident requests to a nat aware identd running on your firewall. answering no closes all ports on the firewall machine itself."
echo ""
echo -n "would you like to open any tcp ports to the firewall (yes/no) : "
read tcp_in_fw

while [ x$tcp_in_fw != "xyes" ] && [ x$tcp_in_fw != "xno" ]; do
	echo ""
	echo "i didn't understand your last answer"
	echo ""
	echo -n "would you like to open any tcp ports to the firewall (yes/no) : "
	read tcp_in_fw
done

if [ $tcp_in_fw = "yes" ]; then
	echo ""
	echo "to open multiple ports simply seperate them with a space ( 22 25 993 )"
	echo ""
	echo -n "what tcp port(s) would you like open on the firewall : "
	read tcp_input
	while [ -z "$tcp_input" ]; do
		echo ""
		echo "i didn't understand your last answer"
		echo -n "what tcp port(s) would you like open on the firewall : "
		read tcp_input
	done
fi


### udp allows - INPUT chain ###
echo ""
echo ""
echo -n "would you like to open any udp ports to the firewall (yes/no) : "
read udp_in_fw

while [ x$udp_in_fw != "xyes" ] && [ x$udp_in_fw != "xno" ]; do
	echo ""
	echo "i didn't understand your last answer"
	echo ""
	echo -n "would you like to open any udp ports to the firewall (yes/no) : "
	read udp_in_fw
done

if [ $udp_in_fw = "yes" ]; then
	echo ""
	echo "to open multiple ports simply seperate them with a space ( 69 514 )"
	echo ""
	echo -n "what udp port(s) would you like open on the firewall : "
	read udp_input
	while [ -z "$udp_input" ]; do
		echo ""
		echo "i didn't understand your last answer"
		echo -n "what udp port(s) would you like open on the firewall : "
		read udp_input
	done
fi


### load some modules ###
if [ $nat = "yes" ]; then
	echo ""
	echo ""
	echo "i recommend answering yes to the following question."
	echo ""
	echo -n "would you like to load the ftp nat and conntrack kernel modules if they are available (yes/no) : "
	read ftp_mod
	echo ""

	while [ x$ftp_mod != "xyes" ] && [ x$ftp_mod != "xno" ]; do
		echo ""
		echo "i didn't understand your last answer"
		echo ""
		echo -n "would you like to load the ftp nat and conntrack kernel modules if they are available (yes/no) : "
		read ftp_mod
	done

	echo ""
	echo ""
	echo "if hosts on your network will be connecting to irc servers answer yes to the following question"
	echo ""
	echo -n "would you like to load the irc nat and conntrack kernel modules if they are available (yes/no) : "
	read irc_mod
	echo ""

	while [ x$irc_mod != "xyes" ] && [ x$irc_mod != "xno" ]; do
		echo ""
		echo "i didn't understand your last answer"
		echo ""
		echo -n "would you like to load the irc nat and conntrack kernel modules if they are available (yes/no) : "
		read irc_mod
	done
fi


### reserved private networks and explicit host drops ###
echo ""
echo ""
echo "certain networks have been set aside as private networks, and they shouldn't be routed across the internet.  if you're using quicktables as an internet firewall or internet firewall and nat script then you will want to answer yes to the following question.  if you're using quicktables on a private lan (10.0.0.0/8 172.16.0.0/12 192.168.0.0/16) then you'll want to answer no to the following question."
echo ""
echo -n "do you want to block internet access from reservced private networks (yes/no) : "
read block_private

while [ -z "block_private" ]; do
	echo ""
	echo "i didn't understand your last answer"
	echo ""
	echo -n "do you want to block internet access from reserved private networks (yes/no) : "
	read block_private
done

while [ x$block_private != "xyes" ] && [ x$block_private != "xno" ]; do
	echo ""
	echo "i didn't understand your last answer"
	echo ""
	echo -n "do you want to block internet access from reserved private networks (yes/no) : "
	read block_private
done

echo ""
echo ""
echo "blocked hosts will not have access to any ports including those that are open or being forwarded.  hit enter to skip blocking any hosts or networks"
echo ""
echo -n "enter the ip address(es) and/or network address(es) to completely block. : "
read blocked
echo ""


### logging ###
echo ""
echo ""
echo "logging dropped packets creates a record of the packet.  it can also generate a lot of logging.  iptables uses kern.info for syslogging"
echo ""
echo -n "would you like to log dropped packets (yes/no) : "
read log_packets
echo ""

while [ x$log_packets != "xyes" ] && [ x$log_packets != "xno" ]; do
	echo ""
	echo "i didn't understand your last answer"
	echo ""
	echo -n "would you like to log dropped packets (yes/no) : "
	read log_packets
	echo ""
done

if [ $log_packets = "yes" ]; then
	echo ""
	echo "quicktables supports multiple levels of logging.  level 1 logs all dropped packets to ports 0 through 1024.  level 2 logs all dropped packets to ports 0 through 65535"
	echo ""
	echo -n "which log level do you wish to use (1/2) : "
	read log_level

	while [ x$log_level != "x1" ] && [ x$log_level != "x2" ]; do
		echo ""
		echo "i didn't understand your last answer"
		echo ""
		echo -n "which log level do you wish to use (1/2) : "
		read log_level
	done
fi


### squid ###
echo ""
echo ""
echo "squid is a web proxy cache.  answering yes to the following question will configure quicktables to transparently proxy all outbound http requests through squid without requiring any browser configuration.  if you have no idea what this means answer no to the following question."
echo ""
echo -n "do you wish to use squid (yes/no) : "
read squid

while [ x$squid != "xyes" ] && [ x$squid != "xno" ]; do
	echo ""
	echo "i didn't understand your last answer"
	echo ""
	echo -n "do you wish to use squid (yes/no) : "
	read squid
done

if [ $squid = "yes" ]; then
	echo ""
	echo -n "what is the IP address of the squid machine : "
	read squid_ip
	while [ -z "$squid_ip" ]; do
		echo ""
		echo -n "what is the IP address of the squid machine : "
		read squid_ip
	done
	while [ `echo $squid_ip |eval $is_ip` != "1" ]; do
		echo ""
		echo "$squid_ip doesn't seem to be a valid IP address"
		echo ""
		echo -n "what is the IP address of the squid machine : "
		read squid_ip
	done

	echo ""
	echo -n "what port is squid listening on : "
	read squid_port
	while [ -z "$squid_port" ]; do
		echo ""
		echo "i didn't understand your last answer"
		echo ""
		echo -n "what port is squid listening on : "
		read squid_port
	done

	echo ""
	echo "the interface that the \"to-be-proxied requests\" will be received on is the interface on the squid machine that the clients will use to connect"
	echo ""
	echo -n "which interface will the to-be-proxied requests be received on : "
	read squid_if
	while [ -z $squid_if ]; do
		echo ""
		echo "i didn't understand your last answer"
		echo ""
		echo -n "which interface will the to-be-proxied requests be received on : "
		read squid_if
	done

	while [ `echo $squid_if |eval $is_if` != "1" ]; do
		echo ""
		echo "$squid_if doesn't seem like a valid interface"
		echo ""
		echo -n "which interface will the to-be-proxied requests be received on : "
		read squid_if
	done

	echo ""
	echo "i need to know where on the network your web proxy resides.  if you run squid on the firewall machine itself answer yes to the following question.  if it runs on any other machine answer no."
	echo ""
	echo -n "do you run squid on the firewall machine itself (yes/no) : "
	read squid_fw
	while [ -z "$squid_fw" ]; do
		echo ""
		echo "i didn't understand your last answer"
		echo ""
		echo -n "do you run squid on the firewall machine itself (yes/no) : "
		read squid_fw
	done
	while [ x$squid_fw != "xyes" ] && [ x$squid_fw != "xno" ]; do
		echo ""
		echo "i didn't understand your last answer"
		echo ""
		echo -n "do you run squid on the firewall machine itself (yes/no) : "
		read squid_fw
	done
	if [ $squid_fw = "no" ]; then
		echo ""
		echo "since squid is not running on the firewall machine itself i need to know the IP address of the machine running the quicktables firewall.  this will be the IP address on the interface that the clients will be talking to.  most likely it would be your clients default gateway address."
		echo ""
		echo -n "what is the quicktables firewall machine IP address : "
		read squid_fw_ip
		while [ -z "$squid_fw_ip" ]; do
			echo ""
			echo "i didn't understand your last answer"
			echo ""
			echo -n "what is the quicktables firewall machine IP address : "
			read squid_fw_ip
		done
		while [ `echo $squid_fw_ip |eval $is_ip` != "1" ]; do
			echo ""
			echo "$squid_fw_ip doesn't seem to be a valid IP address"
			echo ""
			echo -n "what is the quicktables firewall machine IP address : "
			read squid_fw_ip
		done

		echo ""
		echo "since squid is not running on the firewall machine itself i need to know the network address(es) of the clients that will be using the squid proxy.  seperate multiple network addresses with a space (192.168.0.0/24 172.16.16.0/24)"
		echo ""
		echo -n "what client network address(es) will be using the squid proxy : "
		read squid_nets
		while [ -z "$squid_nets" ]; do
			echo ""
			echo "i didn't understand your last answer"
			echo ""
			echo -n "what client network address(es) will be using the squid proxy : "
			read squid_nets
		done
	fi
fi


### do it ###
echo "#!/bin/sh" >> $out
echo "#" >> $out
echo "# generated by $0 on $date" >> $out
echo "#" >> $out
echo "" >> $out


echo "# set a few variables" >> $out
echo "echo \"\"" >> $out
echo "echo \"	setting global variables\"" >> $out
echo "echo \"\"" >> $out
echo "export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin" >> $out
echo "iptables=\"$iptables\"" >> $out

echo "" "" >> $out

echo "# adjust /proc" >> $out
echo "echo \"	applying general security settings to /proc filesystem\"" >> $out
echo "echo \"\"" >> $out
echo "if [ -e /proc/sys/net/ipv4/tcp_syncookies ]; then echo 1 > /proc/sys/net/ipv4/tcp_syncookies; fi" >> $out
echo "if [ -e /proc/sys/net/ipv4/conf/all/rp_filter ]; then echo 1 > /proc/sys/net/ipv4/conf/all/rp_filter; fi" >> $out


if [ $nat = "yes" ]; then
	echo "if [ -e /proc/sys/net/ipv4/ip_forward ]; then echo 1 > /proc/sys/net/ipv4/ip_forward; fi" >> $out

	if [ $irc_mod = "yes" ]; then
		echo "" "" >> $out
		echo "# load some modules" >> $out
		echo "if [ -e /lib/modules/\`uname -r\`/kernel/net/ipv4/netfilter/ip_nat_irc.o ]; then modprobe ip_nat_irc; fi" >> $out
		echo "if [ -e /lib/modules/\`uname -r\`/kernel/net/ipv4/netfilter/ip_conntrack_irc.o ]; then modprobe ip_conntrack_irc; fi" >> $out
	fi

	if [ $ftp_mod = "yes" ]; then
		if [ $irc_mod = "no" ]; then
			echo "" "" >> $out
			echo "# load some modules" >> $out
		fi

	echo "if [ -e /lib/modules/\`uname -r\`/kernel/net/ipv4/netfilter/ip_conntrack_ftp.o ]; then modprobe ip_conntrack_ftp; fi" >> $out
	echo "if [ -e /lib/modules/\`uname -r\`/kernel/net/ipv4/netfilter/ip_nat_ftp.o ]; then modprobe ip_nat_ftp; fi" >>$out

	fi
fi


echo "" "" >> $out


echo "# flush any existing chains and set default policies" >> $out
echo "\$iptables -F INPUT" >> $out
echo "\$iptables -F OUTPUT" >> $out
echo "\$iptables -P INPUT DROP" >> $out
echo "\$iptables -P OUTPUT ACCEPT" >> $out


echo "" "" >> $out


if [ $nat = "yes" ]; then
	echo "# setup nat" >> $out
	echo "echo \"	applying nat rules\"" >> $out
	echo "echo \"\"" >> $out
	echo "\$iptables -F FORWARD" >> $out
	echo "\$iptables -F -t nat" >> $out
	echo "\$iptables -P FORWARD DROP" >> $out
	echo "\$iptables -A FORWARD -i $int_if -j ACCEPT" >> $out
	echo "\$iptables -A INPUT -i $int_if -j ACCEPT" >> $out
	echo "\$iptables -A OUTPUT -o $int_if -j ACCEPT" >> $out
	echo "\$iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT" >> $out

	if [ $masq_type = "dynamic" ]; then
		for network in $masq_nets; do
			echo "\$iptables -t nat -A POSTROUTING -s $network -o $ext_if -j MASQUERADE" >> $out
		done
	fi
	if [ $masq_type = "static" ]; then
		for network in $masq_nets; do
			echo "\$iptables -t nat -A POSTROUTING -s $network -o $ext_if -j SNAT --to-source $static_ip" >> $out
		done
	fi

	echo "" "" >> $out
fi


echo "# allow all packets on the loopback interface" >> $out
echo "\$iptables -A INPUT -i lo -j ACCEPT" >> $out
echo "\$iptables -A OUTPUT -o lo -j ACCEPT" >> $out


echo "" "" >> $out


echo "# allow established and related packets back in" >> $out
echo "\$iptables -A INPUT -i $ext_if -m state --state ESTABLISHED,RELATED -j ACCEPT" >> $out


echo "" "" >> $out

if [ $block_private = "yes" ]; then
	echo "# blocking reserved private networks incoming from the internet" >> $out
	echo "echo \"	applying incoming internet blocking of reserved private networks\"" >> $out
	echo "echo \"\"" >> $out
	echo "\$iptables -I INPUT -i $ext_if -s 10.0.0.0/8 -j DROP" >> $out
	echo "\$iptables -I INPUT -i $ext_if -s 172.16.0.0/12 -j DROP" >> $out
	echo "\$iptables -I INPUT -i $ext_if -s 192.168.0.0/16 -j DROP" >> $out
	echo "\$iptables -I INPUT -i $ext_if -s 127.0.0.0/8 -j DROP" >> $out
	if [ $nat = "yes" ]; then
		echo "\$iptables -I FORWARD -i $ext_if -s 10.0.0.0/8 -j DROP" >> $out
		echo "\$iptables -I FORWARD -i $ext_if -s 172.16.0.0/12 -j DROP" >> $out
		echo "\$iptables -I FORWARD -i $ext_if -s 192.168.0.0/16 -j DROP" >> $out
		echo "\$iptables -I FORWARD -i $ext_if -s 127.0.0.0/8 -j DROP" >> $out
	fi
	echo "" "" >> $out
fi

if [ ! -z "$blocked" ]; then
	echo "# blocked hosts" >> $out
	echo "echo \"	dropping all packets from blocked hosts\"" >> $out
	echo "echo \"\"" >> $out
	for host in $blocked; do
		echo "\$iptables -I INPUT -s $host -j DROP" >> $out
	done
	if [ $nat = "yes" ]; then
		for host in $blocked; do
			echo "\$iptables -I FORWARD -s $host -j DROP" >> $out
		done
	fi
	echo "" "" >> $out
fi

if [ -f /etc/qblock ]; then
	echo "# quickblock entries from /etc/qblock" >> $out
	echo "echo \"	applying packet blocks from quickblock entries\"" >> $out
	echo "echo \"\"" >> $out
	for address in `cat /etc/qblock`; do
		echo "\$iptables -I INPUT -s $address -j DROP" >> $out
	done
	if [ $nat = "yes" ]; then
		for address in `cat /etc/qblock`; do
			echo "\$iptables -I FORWARD -s $address -j DROP" >> $out
		done
	fi
	echo "" "" >> $out
fi


### outbound drops ###
echo ""
echo ""
echo "blocking services will prevent clients on the trusted side of the quicktables machine from accessing a certain service.  a common use for this feature would be to block clients on your internal network from accessing services like ICQ and P2P services.  if you're uncertain about using this option answer no to the following question."
echo ""
echo -n "do you wish to block outbound access to any services (yes/no) : "
read out_block

while [ -z $out_block ]; do
	echo ""
	echo "i didn't understand your last answer"
	echo ""
	echo -n "do you wish to block outbound access to any services (yes/no) : "
	read out_block
done

while [ x$out_block != "xyes" ] && [ x$out_block != "xno" ]; do
	echo ""
	echo "i didn't understand your last answer"
	echo ""
	echo -n "do you wish to block outbound access to any services (yes/no) : "
	read out_block
done

if [ $out_block = "yes" ]; then
	echo "# outbound blocks and exceptions" >> $out
	echo "echo \"	applying outbound blocks and exceptions\"" >> $out
	echo "echo \"\"" >> $out
fi

while [ $out_block = "yes" ]; do
	export dst_port_block=""
	export dst_port_block_proto=""
	export dst_port_block_exclude=""
	export dst_port_block_exclude_address=""
	echo ""
	echo "many common service ports are listed in /etc/services.  please consult this file or your favorite search engine to determine what service runs on what port."
	echo ""
	echo -n "what single destination port would you like to block : "
	read dst_port_block

	while [ -z $dst_port_block ]; do
		echo ""
		echo "i didn't understand your last answer"
		echo ""
		echo -n "what single destination port would you like to block : "
		read dst_port_block
	done

	echo ""
	echo -n "what protocol do you wish to block (tcp/udp) : "
	read dst_port_block_proto

	while [ -z $dst_port_block_proto ]; do
		echo ""
		echo "i didn't understand your last answer"
		echo ""
		echo -n "what protocol do you wish to block (tcp/udp) : "
		read dst_port_block_proto
	done

	while [ x$dst_port_block_proto != "xtcp" ] && [ x$dst_port_block_proto != "xudp" ]; do
		echo ""
		echo "i didn't understand your last answer"
		echo ""
		echo -n "what protocol do you wish to block (tcp/udp) : "
		read dst_port_block_proto
	done

	echo ""
	echo "if you wish to exclude any host from this you may enter a single IP address which will not be affected by this service block."
	echo ""
	echo -n "would you like to exclude any host from this service block (yes/no) : "
	read dst_port_block_exclude

	while [ -z $dst_port_block_exclude ]; do
		echo ""
		echo "i didn't understand your last answer"
		echo ""
		echo -n "would you like to exclude any host from this service block (yes/no) : "
		read dst_port_block_exclude
	done

	while [ x$dst_port_block_exclude != "xyes" ] && [ x$dst_port_block_exclude != "xno" ]; do
		echo ""
		echo "i didn't understand your last answer"
		echo ""
		echo -n "would you like to exclude any host from this service block (yes/no) : "
		read dst_port_block_exclude
	done

	if [ $dst_port_block_exclude = "yes" ]; then
		echo ""
		echo -n "what single IP address would you like to exclude : "
		read dst_port_block_exclude_address

		while [ -z $dst_port_block_exclude_address ]; do
			echo ""
			echo "i didn't understand your last answer"
			echo ""
			echo -n "what single IP address would you like to exclude : "
			read dst_port_block_exclude_address
		done

		while [ `echo $dst_port_block_exclude_address |eval $is_ip` != "1" ]; do
			echo ""
			echo "$dst_port_block_exclude_address doesn't seem to be a valid IP address"
			echo ""
			echo -n "what single IP address would you like to exclude : "
			read dst_port_block_exclude_address
		done
	fi

	if [ $nat = "yes" ]; then
		echo "\$iptables -I FORWARD -i $int_if -p $dst_port_block_proto --dport $dst_port_block -j DROP" >> $out
	fi
	echo "\$iptables -I OUTPUT -p $dst_port_block_proto --dport $dst_port_block -j DROP" >> $out

	if [ $dst_port_block_exclude = "yes" ]; then
		if [ $nat = "yes" ]; then
			echo "\$iptables -I FORWARD -i $int_if -s $dst_port_block_exclude_address -p $dst_port_block_proto --dport $dst_port_block -j ACCEPT" >> $out
		fi
		echo "\$iptables -I OUTPUT -s $dst_port_block_exclude_address -p $dst_port_block_proto --dport $dst_port_block -j ACCEPT" >> $out
	fi

	echo ""
	echo -n "do you wish to block outbound access to another service (yes/no) : "
	read out_block

	if [ $out_block = "no" ]; then
		echo "" "" >> $out
	fi
done


echo "# icmp" >> $out
echo "echo \"	applying icmp rules\"" >> $out
echo "echo \"\"" >> $out
echo "\$iptables -A OUTPUT -p icmp -m state --state NEW -j ACCEPT" >> $out
echo "\$iptables -A INPUT -p icmp -m state --state ESTABLISHED,RELATED -j ACCEPT" >> $out

if [ $icmp = "yes" ]; then
	echo "\$iptables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 1/s -i $ext_if -j ACCEPT" >> $out
else
	echo "\$iptables -A INPUT -p icmp --icmp-type echo-request -i $ext_if -j DROP" >> $out
fi

echo "" "" >> $out


if [ $icmp_type_block = "yes" ]; then
	export icmp_type="redirect router-advertisement router-solicitation address-mask-request address-mask-reply"
	echo "# apply icmp type match blocking" >> $out
	echo "echo \"	applying icmp type match blocking\"" >> $out
	echo "echo \"\"" >> $out
	for type in $icmp_type; do
		echo "\$iptables -I INPUT -p icmp --icmp-type $type -j DROP" >> $out
	done
echo "" "" >> $out

fi

if [ $squid = "yes" ]; then
	echo "# squid" >> $out
	echo "echo \"	applying squid rules\"" >> $out
	echo "echo \"\"" >> $out
	if [ $squid_fw = "yes" ]; then
		echo "\$iptables -t nat -A PREROUTING -i $squid_if -p tcp --dport 80 -j REDIRECT --to-port $squid_port" >> $out
	fi
	if [ $squid_fw = "no" ]; then
		echo "\$iptables -t nat -A PREROUTING -i $squid_if -s ! $squid_ip -p tcp --dport 80 -j DNAT --to $squid_ip:$squid_port" >> $out
		for s_net in $squid_nets; do
			echo "\$iptables -t nat -A POSTROUTING -o $squid_if -s $s_net -d $squid_ip -j SNAT --to $squid_fw_ip" >> $out
			echo "\$iptables -A FORWARD -s $s_net -d $squid_ip -i $squid_if -o $squid_if -p tcp --dport $squid_port -j ACCEPT" >> $out
		done
	fi
echo "" "" >> $out
fi


if [ $tcp_in_fw = "yes" ]; then
	echo "# open ports to the firewall" >> $out
	echo "echo \"	applying the open port(s) to the firewall rules\"" >> $out
	echo "echo \"\"" >> $out
	for port in $tcp_input; do
	echo "\$iptables -A INPUT -p tcp --dport $port -j ACCEPT" >> $out
	done
	if [ $udp_in_fw = "no" ]; then
		echo "" "" >> $out
	fi
fi


if [ $udp_in_fw = "yes" ] && [ $tcp_in_fw = "no" ]; then
	echo "# open ports to the firewall" >> $out
fi

if [ $udp_in_fw = "yes" ]; then
	for port in $udp_input; do
		echo "\$iptables -A INPUT -p udp --dport $port -j ACCEPT" >> $out
	done
	if [ $tcp_in_fw = "no" ]; then
		echo "" >> $out
	fi
fi


if [ $nat = "yes" ]; then
	echo ""
	echo ""
	echo -n "would you like to forward ports from one or more external IP addresses to one or more internal IP addresses (yes/no) : "
	read port_forward

	while [ x$port_forward != "xyes" ] && [ x$port_forward != "xno" ]; do
		echo ""
		echo "i didn't understand your last answer"
		echo ""
		echo -n "would you like to forward ports to an internal machine (yes/no) : "
		read port_forward
		echo ""
	done

	if [ $port_forward = "yes" ]; then
		ext_addr=`ifconfig $ext_if |grep inet |cut -f2 -d: |cut -f1 -d" "`
		echo "# open and forward ports to the internal machine(s)" >> $out
		echo "echo \"	applying port forwarding rules\"" >> $out
		echo "echo \"\"" >> $out
	fi

	while [ $port_forward = "yes" ]; do
			echo ""
			echo -n "i see that your internet IP address is $ext_addr.  is this the destination address you want to match for this port forwarding (yes/no) : "
			read ext_match

			while [ x$ext_match != "xyes" ] && [ x$ext_match != "xno" ]; do
				echo ""
				echo "i didn't understand your last answer"
				echo ""
				echo -n "i see that your internet IP address is $ext_addr.  is this the destination address you want to match for this port forwarding (yes/no) : "
				read ext_match
			done

			if [ $ext_match = "no" ]; then
				echo -n "what destination address would you like to match for this port forward : "
				read ext_addr

				while [ -z "$ext_addr" ]; do
					echo ""
					echo "i didn't understand your last answer"
					echo ""
					echo -n "what destination address would you like to match for this port forward : "
					read ext_addr
				done

				while [ `echo $ext_addr |eval $is_ip` != "1" ]; do
					echo ""
					echo "$ext_addr doesn't seem to be a valid IP address"
					echo ""
					echo -n "what destination address would you like to match for this port forward : "
					read ext_addr
				done

			fi

			while [ -z "$ext_addr" ]; do
				echo ""
				echo "i didn't understand your last answer"
				echo ""
				echo -n "what destination address would you like to match for this port forward : "
				read ext_addr
			done

			while [ `echo $ext_addr |eval $is_ip` != "1" ]; do
				echo ""
				echo "$ext_addr doesn't seem to be a valid IP address"
				echo ""
				echo -n "what destination address would you like to match for this port forward : "
				read ext_addr
			done

		echo ""
		echo -n "what destination port or range (1-1024) of ports would you like to match : "
		read ext_port

		while [ -z "$ext_port" ]; do
			echo ""
			echo "i didn't understand your last answer"
			echo ""
			echo -n "what destination port or range of ports would you like to match : "
			read ext_port
		done

		echo ""
		echo -n "what internal address would you like to forward port $ext_port to : "
		read int_addr

		while [ -z "$int_addr" ]; do
			echo ""
			echo "i didn't understand your last answer"
			echo ""
			echo -n "what internal address would you like to forward external port $ext_port with destination address $ext_addr to : "
			read int_addr
		done

		echo ""
		echo -n "what internal port or range of ports would you like to forward external port $ext_port with destination address $ext_addr to : "
		read int_port

		while [ -z "$int_port" ]; do
			echo ""
			echo "i didn't understand your last answer"
			echo ""
			echo -n "what internal port or range of ports would you like to forward external port $ext_port with destination address $ext_addr to : "
			read int_port
		done

		echo ""
		echo -n "which protocol are we forwarding (tcp/udp) : "
		read protocol

		while [ -z "$protocol" ]; do
			echo ""
			echo "i didn't understand your last answer"
			echo ""
			echo -n "which protocol are we forwarding (tcp/udp) : "
			read protocol
		done

		while [ x$protocol != "xtcp" ] && [ x$protocol != "xudp" ]; do
			echo ""
			echo "i didn't understand your last answer"
			echo ""
			echo -n "which protocol are we forwarding (tcp/udp) : "
			read protocol
		done

		echo "\$iptables -A FORWARD -i $ext_if -p $protocol --dport $int_port -j ACCEPT" >> $out
		echo "\$iptables -t nat -A PREROUTING -i $ext_if -p $protocol -d $ext_addr --dport $ext_port -j DNAT --to-destination $int_addr:$int_port" >> $out

		echo ""
		echo ""
		echo -n "would you like to setup another port forward (yes/no) : "
		read port_forward
	done
	echo "" >> $out

fi

if [ $log_packets = "yes" ]; then
	echo "# logging" >> $out
	echo "echo \"	applying logging rules\"" >> $out
	echo "echo \"\"" >> $out
	if [ $log_level = "1" ]; then
		echo "\$iptables -A INPUT -i $ext_if -p tcp -m limit --limit 1/s --dport 0:1024 -j LOG --log-prefix \"tcp connection: \"" >> $out
		echo "\$iptables -A INPUT -i $ext_if -p udp -m limit --limit 1/s --dport 0:1024 -j LOG --log-prefix \"udp connection: \"" >> $out
	fi
	if [ $log_level = "2" ]; then
		echo "\$iptables -A INPUT -i $ext_if -p tcp -m limit --limit 1/s --dport 0:65535 -j LOG --log-prefix \"tcp connection: \"" >> $out
		echo "\$iptables -A INPUT -i $ext_if -p udp -m limit --limit 1/s --dport 0:65535 -j LOG --log-prefix \"udp connection: \"" >> $out
	fi
fi

echo "" "" >> $out


echo "# drop all other packets" >> $out
echo "echo \"	applying default drop policies\"" >> $out
echo "echo \"\"" >> $out
echo "\$iptables -A INPUT -i $ext_if -p tcp --dport 0:65535 -j DROP" >> $out
echo "\$iptables -A INPUT -i $ext_if -p udp --dport 0:65535 -j DROP" >> $out


echo "" "" >> $out


echo "echo \"### quicktables is loaded ###\"" >> $out
echo "echo \"\"" >> $out


chmod 700 $out


echo ""
echo "	your firewall script has been written to $out"
echo ""

echo -n "thanks for using quicktables.  hit enter to exit."
read thanks
