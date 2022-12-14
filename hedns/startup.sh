#!/bin/bash

die() {
    echo "$1"
    exit 1
}

test -z $HOSTS && die "HOSTS not set!"
test -z $HOST_KEY && die "HOST_KEY not set!"

# Get Current IPs
current4=$(curl -4 -s http://checkip.dns.he.net | grep -o -E '([0-9]{1,3}\.){3}[0-9]{1,3}')
current6=$(curl -6 -s http://checkip.dns.he.net | grep -o -E '(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]).){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]).){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))')

for h in $HOSTS; do
        dns4=$(host -t A $h | grep -o -E '([0-9]{1,3}\.){3}[0-9]{1,3}')
        if [ "$current4" != "$dns4" ]; then
                if [ ! -z $update ]; then
                        update=x;
                else
                        update="x$update";
                fi
                r4=$(curl -s -4 "http://$h:$HOST_KEY@dyn.dns.he.net/nic/update?hostname=$h")
                if ! [[ "$r4" =~ "good" || "$r4" =~ "nochg" ]]; then
                       echo "DNS update failed for $h: $r4"
                fi
        fi
        dns6=$(host -t AAAA $h | grep -o -E '(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]).){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]).){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))')
        if [ "$current6" != "$dns6" ]; then
                if [ ! -z $update ]; then
                        update=x;
                else
                        update="x$update";
                fi
                r6=$(curl -s -6 "http://$h:$HOST_KEY@dyn.dns.he.net/nic/update?hostname=$h")
                if ! [[ "$r6" =~ "good" || "$r6" =~ "nochg" ]]; then
                      echo "DNS update failed for $h: $r6"
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
