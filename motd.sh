#!/bin/bash
cat > /etc/update-motd.d/10-uname <<'EOF'
#!/bin/bash

# y'a internet ou pas + ip + ping
pingoutput=$(ping -qn4c1 1.1.1.1 2>&1 | tail -n 1)
latency=$(echo "$pingoutput" | awk -F'/' '{ print $6 }')
if [[ -n "$latency" ]]; then
  latency=$(echo "$latency" | cut -d"." -f1)
  internet="1"
  if which curl &> /dev/null; then
    ipext=$(curl -4 -sSL 'ifconfig.me')
  elif which wget &> /dev/null; then
    ipext=$(wget --inet4-only -qO- 'ifconfig.me')
  fi
  ptr=$(host -t PTR ${ipext} | awk {'print $NF'})
else
  internet="0"
fi

# DEBIAN VERSION & CO
hostname=$(hostname)
distrib=$(lsb_release -s -d | tail)
kernel=$(uname -r)
uptime=$(uptime -p)
ip=$(hostname -I | cut -d " " -f1)
deb_ver=$(cat /etc/debian_version)
datetime=$(date "+%d/%m/%Y - %H:%M:%S")

if which figlet &> /dev/null; then
  hostname_figlet=$(figlet $(hostname))
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
swappercent=$(sed -e "s/..\$/&/;t" -e "s/..\$/.0&/" <<<"$(( 100 * $swapused/$swaptot ))")
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

# Affichage
echo ""
echo -e "  Nom d'hôte   \e[33m:\e[0m $hostname"
echo -e "  Date/Heure   \e[33m:\e[0m $datetime \e[34m█\e[0m\e[37m█\e[0m\e[31m█\e[0m"
echo -e "  Distribution \e[33m:\e[0m $distrib ($deb_ver)"
echo -e "  Kernel       \e[33m:\e[0m $kernel"
echo -e "  CPU          \e[33m:\e[0m $cpu_model_number"
echo -e "  Charge CPU   \e[33m:\e[0m $one (1min) / $five (5min) / $fifteen (15min)"
echo -e "  Adresse IP   \e[33m:\e[0m $ip | $ipext | $ptr | $latency ms"
echo -e "  RAM          \e[33m:\e[0m $ramusedraw$unitname/$ramtot$unitname ($ramusedrawpercent%) | Total (Cache/Buffers/Bata..) : $ramused$unitname/$(($memtotal/$unit))$unitname ($ramusedpercent%) | Swap ($swappercent%)"
echo -e "  Uptime       \e[33m:\e[0m $uptime"
echo -e "  Disque       \e[33m:\e[0m $diskused/$disktotal ($diskusedpercent%) | Libre : $diskfree ($diskfreepercent%)"
echo ""
EOF
chmod 755 /etc/update-motd.d/10-uname
