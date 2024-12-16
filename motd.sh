#!/bin/bash
cat > /etc/update-motd.d/10-uname <<'EOF'
#!/bin/bash

# la co ou pas
if ping -qn4c1 1.1.1.1 >/dev/null; then
  internet="1"
fi

# sys info
hostname=$(hostname)
distrib=$(grep 'PRETTY_NAME' /etc/os-release | cut -d '"' -f 2)
kernel=$(uname -r)
uptime=$(uptime -p)
ip=$(hostname -I | cut -d " " -f1)
deb_ver=$(cat /etc/debian_version 2>/dev/null)
datetime=$(date "+%d/%m/%Y - %H:%M:%S")

# info virtu
virt_type=$(systemd-detect-virt | tr '[:lower:]' '[:upper:]')
virt_type=${virt_type:-"UNKNOWN"}
[[ "$virt_type" == "NONE" ]] && virt_type="✖"

# support de la virtu
cpu_virt=$(grep -E 'vmx|svm' /proc/cpuinfo)
cpu_virt=${cpu_virt:+✔}
cpu_virt=${cpu_virt:-"✖"}

# info cpu
cpu_cores=$(grep -c "processor" /proc/cpuinfo)
cpu_model=$(awk -F": " '/model name/ {print $2}' /proc/cpuinfo | uniq)
cpu_freq=$(awk -F": " '/cpu MHz/ {print $2}' /proc/cpuinfo | head -n 1 | awk -F"." '{print $1}')
cpu_cache=$(awk -F": " '/cache size/ {cache=$2} END {print cache}' /proc/cpuinfo | xargs)

# formattage cpu freq et cache
cpu_freq=${cpu_freq:-"N/A"}
cpu_cache=${cpu_cache:-"N/A"}
cpu_info="${cpu_cores} x ${cpu_model} @ ${cpu_freq} MHz"

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
if [[ ! $swaptot -eq "0" ]]; then
  swappercent=$(sed -e "s/..\$/&/;t" -e "s/..\$/.0&/" <<<"$(( 100 * $swapused/$swaptot ))")
fi
#ramusedpercent=0$(bc <<<"scale=3; $ramusedraw/$ramtot") # fuck les dépendances
#ramusedpercent=$(bc <<<"scale=3; $ramusedpercent*100")  # fuck les dépendances
#ramusedpercent=$(echo ${ramusedpercent:0:-2})  # fuck les dépendances

ramusedrawpercent=$(sed -e "s/..\$/&/;t" -e "s/..\$/.0&/" <<<"$(( 100 * $ramusedraw/$ramtot ))")
ramusedpercent=$(sed -e "s/..\$/&/;t" -e "s/..\$/.0&/" <<<"$(( 100 * $ramused/$ramtot ))")


# disk
read -r _ disktotal diskused diskfree diskusedpercent _ <<< $(df -x squashfs -x tmpfs -x devtmpfs -x cifs -x overlay -h --total | grep total)
diskusedpercent=${diskusedpercent::-1}
diskfreepercent=$((100 - diskusedpercent))

# load
read -r load_1min load_5min load_15min _ < /proc/loadavg

# si y'a bc -> calcul de la vrai load
if command -v bc &> /dev/null; then

    load_p_1min=$(echo "scale=1; 100 * $load_1min / $cpu_cores" | bc)
    load_p_5min=$(echo "scale=1; 100 * $load_5min / $cpu_cores" | bc)
    load_p_15min=$(echo "scale=1; 100 * $load_15min / $cpu_cores" | bc)
fi
# ext ip
if [[ $internet == "1" ]]; then
  if command -v curl >/dev/null; then
    ipext=$(curl -4 -sSL 'ifconfig.me')
  elif command -v wget >/dev/null; then
    ipext=$(wget --inet4-only -qO- 'ifconfig.me')
  fi

  ptr=$(host -t PTR ${ipext} | awk '{print $NF}')
  if [[ -z "$ptr" || "$ptr" == *"(NXDOMAIN)"* ]]; then
    ptr="✖"
  fi

fi

# yo
echo ""
echo -e "  Hostname     \e[33m:\e[0m $hostname"
echo -e "  Date/Time    \e[33m:\e[0m $datetime \e[34m█\e[0m\e[37m█\e[0m\e[31m█\e[0m"
echo -e "  Distribution \e[33m:\e[0m $distrib ($deb_ver)"
echo -e "  Kernel       \e[33m:\e[0m $kernel"
echo -e "  CPU          \e[33m:\e[0m $cpu_info (cache: $cpu_cache)"
echo -e "  Charge CP    \e[33m:\e[0m $load_1min $load_p_1min% (1min) / $load_5min $load_p_5min% (5min) / $load_15min $load_p_15min% (15min)"
echo -e "  Virtualizati \e[33m:\e[0m VM: $virt_type | CPU Virtualization: $cpu_virt"
echo -e "  IP           \e[33m:\e[0m Int: $ip | Ext: ${ipext:-"N/A"} | PTR: ${ptr:-"N/A"}"
echo -e "  RAM          \e[33m:\e[0m $ramusedraw$unitname/$ramtot$unitname ($ramusedrawpercent%) | Total (Cache/Buffers/Bata..) : $ramused$unitname/$(($memtotal/$unit))$unitname ($ramusedpercent%) | Swap ($swappercent%)"
echo -e "  Uptime       \e[33m:\e[0m $uptime"
echo -e "  Disk         \e[33m:\e[0m $diskused / $disktotal ($diskusedpercent%) | Free: $diskfree ($diskfreepercent%)"
echo ""
EOF
chmod 755 /etc/update-motd.d/10-uname
