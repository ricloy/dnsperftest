#!/usr/bin/bash

[ -x /usr/bin/bc ] || { echo "bc was not found. Please install bc."; exit 1; }
{ [ -x /usr/bin/drill ] && dig=/usr/bin/drill; } || { [ -x /usr/bin/dig ] && dig=/usr/bin/dig; } || { echo "dig was not found. Please install dnsutils."; exit 1; }

PROVIDERS=("1.1.1.1#cloudflare"
"4.2.2.1#level3"
"8.8.8.8#google"
"9.9.9.9#quad9"
"80.80.80.80#freenom"
"208.67.222.123#opendns"
"199.85.126.20#norton"
"185.228.168.168#cleanbrowsing"
"77.88.8.7#yandex"
"176.103.130.132#adguard"
"156.154.70.3#neustar"
"8.26.56.26#comodo");

# Domains to test. Duplicated domains are ok
DOMAINS2TEST=(www.google.com
amazon.com
facebook.com
www.instagram.com
whatsapp.com
www.youtube.com
www.reddit.com
wikipedia.org
twitter.com
gmail.com
www.google.it
www.repubblica.it
www.corriere.it
www.lemonde.fr
www.elmundo.es
www.baidu.com);

randomised_domain_indexes=$(for ((i=0;i<${#DOMAINS2TEST[@]};i++)); do echo $i; done | sort -R)
randomised_DNS_indexes=$(for ((i=0;i<${#PROVIDERS[@]};i++)); do echo $i; done | sort -R)

for i in $randomised_DNS_indexes; do
    p=${PROVIDERS[i]};
    pip=${p%%#*};
    pname=${p##*#};
    ftime=0;
    
    min=9999;
    max=0;
    
    printf "%-18s" "$pname";
    for j in $randomised_domain_indexes; do
        ttime=$($dig +tries=1 +time=2 +stats @$pip ${DOMAINS2TEST[j]} |grep "Query time:" | cut -d : -f 2- | cut -d " " -f 2)
        if [ -z "$ttime" ]; then
	        #let's have time out be 1s = 9999ms
	        ttime=9999;
        elif [ "x$ttime" = "x0" ]; then
	        ttime=1;
        fi

        ftime=$((ftime + ttime));
	if (( ttime > max)); then
		max=$ttime;
	fi
	if ((ttime < min)); then
		min=$ttime;
	fi
    done
    avg=$(bc -lq <<< "scale=2; $ftime/${#DOMAINS2TEST[@]}");
  
    echo "avg: $avg ms (min: $min ms; max: $max ms)";
done | sort -n -k3
