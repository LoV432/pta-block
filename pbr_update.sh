#!/bin/ash

# An OpenWRT script that fetches IPs/Domains from multiple sources and adds them to a PBR rule named "pta-block".
# To use this script, you need to setup a VPN connection and install the PBR package on your OpenWRT. 
# Then create a rule named "pta-block" in PBR which is routed through the VPN. 
# The script requires the following dependencies:
# - whois
# - curl

# Guides on how to setup VPN:
# - https://openwrt.org/docs/guide-user/services/vpn/wireguard/client
# - https://openwrt.org/docs/guide-user/services/vpn/openvpn/client-luci

# You can read more about PBR at https://docs.openwrt.melmac.net/pbr/
# PS: You should try your best to use https://docs.openwrt.melmac.net/pbr/#UseDNSMASQnftsetsSupport


if ! [ -x "$(command -v whois)" ] || ! [ -x "$(command -v curl)" ]; then
    echo "Error: whois or curl is not installed."
    exit 1
fi

lov432_domains=""   # Anything from https://github.com/LoV432/pta-block/tree/master/domains
lov432_asns=""      # Anything from https://github.com/LoV432/pta-block/tree/master/asns
v2fly_domains=""    # Anything from https://github.com/v2fly/domain-list-community/tree/master/data
domains=""          # Add any hardcoded domains here
ips=""              # Add any hardcoded IPs here

# Fetch domains
for fetch_domain in $lov432_domains; do
        fetch_domain=$(curl -s "https://raw.githubusercontent.com/LoV432/pta-block/master/domains/$fetch_domain" | tr '\n' ' ')
        domains="$domains $fetch_domain"
done

# Fetch asn ips from radb
for asn_domain in $lov432_asns; do
    asns=$(curl -s "https://raw.githubusercontent.com/LoV432/pta-block/master/asns/$asn_domain" | tr '\n' ' ')
    for asn in $asns; do
        asn_ips=$(whois -h whois.radb.net -- "-i origin $asn" | grep '^route:' | tr -d 'routes: ' | tr '\n' ' ')
        ips="$ips $asn_ips"
    done
done

# Fetch domains from v2fly
for fetch_domain in $v2fly_domains; do
        fetch_domain=$(curl -s "https://raw.githubusercontent.com/v2fly/domain-list-community/master/data/$fetch_domain" | tr '\n' ' ')
        domains="$domains $fetch_domain"
done

finalDomains="$domains $ips"

rulenum=$(uci show pbr | grep 'pta-block' | sed 's/.*\@//;s/\.name.*//'); uci set pbr.@"$rulenum".dest_addr="$finalDomains"
uci commit pbr
service pbr restart


echo
echo "List Updated"
echo