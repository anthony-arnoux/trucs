#!/bin/bash
cat > /etc/update-motd.d/10-uname <<'EOF'
#!/bin/bash

# y'a internet ou pas
if $(ping -qn4c1 1.1.1.1 >/dev/null); then
  internet="1"
fi

# DEBIAN VERSION & CO
hostname=$(hostname)
distrib=$(grep 'PRETTY_NAME' /etc/os-release | cut -d '"' -f 2)
kernel=$(uname -r)
uptime=$(uptime -p)
ip=$(hostname -I | cut -d " " -f1)
deb_ver=$(cat /etc/debian_version &> /dev/null)
datetime=$(date "+%d/%m/%Y - %H:%M:%S")

if which figlet &> /dev/null; then
  hostname_figlet=$(figlet $(hostname))
fi

# VM
virt_type=$(systemd-detect-virt 2>/dev/null)
if [[ -z "$virt_type" ]]; then
  virt_type="" # no
else
  virt_type=" VM : \xE2\x9C\x94"
fi

# VIRT
cpu_virt=$(cat /proc/cpuinfo | grep 'vmx\|svm')
if [[ -z "$cpu_virt" ]]; then
  cpu_virt="" # no
else
  cpu_virt=" virt tech : \xE2\x9C\x94"
fi

# CPU
cpu_model_number="$(grep "processor" /proc/cpuinfo | wc -l ) x $(grep "model name" /proc/cpuinfo | uniq | awk -F": " '{print $2}')"

# RAM
unit=1024 #Mo
unitname="Mo"
unitgo=10024 #Go
unitgoname="Go" # sa fé reflaichir
memtotal=$(grep -w MemTotal /proc/meminfo | awk {'print $2'})

## Récupération
memfree=$(grep -w MemFree /proc/meminfo | awk {'print $2'})
memcached=$(grep -w Cached /proc/meminfo | awk {'print $2'})
membuffed=$(grep -w Buffers /proc/meminfo | awk {'print $2'})
memreclaimable=$(grep -w SReclaimable /proc/meminfo | awk {'print $2'})

swaptot=$(grep -w SwapTotal /proc/meminfo | awk {'print $2'})
swapfree=$(grep -w SwapFree /proc/meminfo | awk {'print $2'})

## Traitement / calculs scientifiques tah HEC
memused=$(( $memtotal - $memfree ))
memusednocache=$(( $memused - $memcached ))
memusednocachenobuffers=$(( $memusednocache - $membuffed ))
memusednocachenobuffersnoclaim=$(( $memusednocachenobuffers - $memreclaimable ))
ramusedraw=$(($memusednocachenobuffersnoclaim/$unit))
ramtot=$(($memtotal/$unit))
ramused=$(($memused/$unit))

swapused=$(( $swaptot - $swapfree ))
if [[ ! -z $swaptot ]]; then
  swappercent=$(sed -e "s/..\$/&/;t" -e "s/..\$/.0&/" <<<"$(( 100 * $swapused/$swaptot ))")
fi
#ramusedpercent=0$(bc <<<"scale=3; $ramusedraw/$ramtot") # fuck les dépendances
#ramusedpercent=$(bc <<<"scale=3; $ramusedpercent*100")  # fuck les dépendances
#ramusedpercent=$(echo ${ramusedpercent:0:-2})  # fuck les dépendances

ramusedrawpercent=$(sed -e "s/..\$/&/;t" -e "s/..\$/.0&/" <<<"$(( 100 * $ramusedraw/$ramtot ))")
ramusedpercent=$(sed -e "s/..\$/&/;t" -e "s/..\$/.0&/" <<<"$(( 100 * $ramused/$ramtot ))")

# Récuperer l'usage disque cumul
read garbage disktotal diskused diskfree diskusedpercent <<< $(df -h --total | grep total)
diskusedpercent=$(echo $diskusedpercent | awk -F' ' {'print $1'})
diskusedpercent=$(echo ${diskusedpercent:0:-1})
diskfreepercent=$(( 100 - $diskusedpercent ))

# Récupérer le loadavg
read one five fifteen rest < /proc/loadavg

# Pour récuperer l'ipv4 externe -> curl ou wget
if [[ $internet = "1" ]]; then
  if which curl &> /dev/null; then
    ipext=$(curl -4 -sSL 'ifconfig.me')
  elif which wget &> /dev/null; then
    ipext=$(wget --inet4-only -qO- 'ifconfig.me')
  fi
  ptr=$(host -t PTR ${ipext} | awk {'print $NF'})
fi

if [[ ! -z $ipext ]]; then
  ipext="${ipext} ✔ "
fi

# Affichage
echo ""
echo -e "  Nom d'hôte   \e[33m:\e[0m $hostname"
echo -e "  Date/Heure   \e[33m:\e[0m $datetime \e[34m█\e[0m\e[37m█\e[0m\e[31m█\e[0m"
echo -e "  Distribution \e[33m:\e[0m $distrib ($deb_ver)"
echo -e "  Kernel       \e[33m:\e[0m $kernel"
echo -e "  CPU          \e[33m:\e[0m $cpu_model_number $virttech $virt_type $cpu_virt"
echo -e "  Charge CPU   \e[33m:\e[0m $one (1min) / $five (5min) / $fifteen (15min)"
echo -e "  Adresse IP   \e[33m:\e[0m $ip | $ipext | $ptr"
echo -e "  RAM          \e[33m:\e[0m $ramusedraw$unitname/$ramtot$unitname ($ramusedrawpercent%) | Total (Cache/Buffers/Bata..) : $ramused$unitname/$(($memtotal/$unit))$unitname ($ramusedpercent%) | Swap ($swappercent%)"
echo -e "  Uptime       \e[33m:\e[0m $uptime"
echo -e "  Disque       \e[33m:\e[0m $diskused/$disktotal ($diskusedpercent%) | Libre : $diskfree ($diskfreepercent%)"
echo ""
EOF
chmod 755 /etc/update-motd.d/10-uname
