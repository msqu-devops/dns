#!/bin/bash
set -euo pipefail

# dns credentials
HOSTS="srv.mufus.de"
dnstoken=SUP8qJxrMiqDYuyExG1xuZ3AUXLT

# Get Current IPs
current4=$(dig @resolver3.opendns.com myip.opendns.com +short)
current6=$(dig @resolver1.ipv6-sandbox.opendns.com AAAA myip.opendns.com +short)
update=''

# update dyndns
for h in "${HOSTS[@]}"; do
        dns4=$(host -t A "$h" | grep -o -E '([0-9]{1,3}\.){3}[0-9]{1,3}')
        dns6=$(host -t AAAA "$h" | grep -o -E '(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]).){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]).){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))')
        if [ "$current4" != "$dns4" ] || [ "$current6" != "$dns6" ]; then
                if [ -n "$update" ]; then
                        update=x;
                else
                        update="x$update";
                fi
                response=$(curl -s --user "$h:$dnstoken" "https://update.dedyn.io/?myipv4=$current4&myipv6=$current6")
                if ! [[ "$response" =~ "good" || "$response" =~ "nochg" ]]; then
                       echo "DNS update failed for $h: $response"
                fi
        fi
done

if [ -z "$update" ]; then
        WC=$(echo $HOSTS | wc -w)
        echo "No DNS update needed ($WC hosts)"
else
        WC=$(echo $update | wc -c)
        echo "DNS changed for $WC entries to $current4 and $current6"
fi
