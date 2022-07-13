#!/bin/bash

api_host="https://api.digitalocean.com/v2"

die() {
    echo "$1"
    exit 1
}

test -z $DIGITALOCEAN_TOKEN && die "DIGITALOCEAN_TOKEN not set!"
test -z $DOMAIN && die "DOMAIN not set!"
test -z $NAME && die "NAME not set!"

dns_list="$api_host/domains/$DOMAIN/records"

domain_records=$(curl --doh-url https://1.1.1.1/dns-query -s -X GET \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $DIGITALOCEAN_TOKEN" \
    $dns_list)

ip="$(dig @208.67.222.222 A myip.opendns.com +short -4)"
ip6="$(dig @2620:0:ccc::2 AAAA myip.opendns.com +short -6)"

echo "DNS returned following:"
echo $ip
echo $ip6

if [[ -n $ip ]]; then
    # disable glob expansion
    set -f

    for sub in ${NAME//;/ }; do
        record_id=$(echo $domain_records| jq ".domain_records[] | select(.type == \"A\" and .name == \"$sub\") | .id")
        record_id6=$(echo $domain_records| jq ".domain_records[] | select(.type == \"AAAA\" and .name == \"$sub\") | .id")
        record_data=$(echo $domain_records| jq -r ".domain_records[] | select(.type == \"A\" and .name == \"$sub\") | .data")
        record_data6=$(echo $domain_records| jq -r ".domain_records[] | select(.type == \"AAAA\" and .name == \"$sub\") | .data")
        echo "DO API returned following:"
        echo $record_data
        echo $record_data6

        # re-enable glob expansion
        set +f

        data="{\"type\": \"A\", \"name\": \"$sub\", \"data\": \"$ip\"}"
        data6="{\"type\": \"AAAA\", \"name\": \"$sub\", \"data\": \"$ip6\"}"
        url="$dns_list/$record_id"
        url6="$dns_list/$record_id6"

        if [[ -z $record_id ]]; then
            echo "No record found with '$sub' domain name. Creating record, sending data=$data to url=$url"

            new_record=$(curl -s -X POST \
                -H "Content-Type: application/json" \
                -H "Authorization: Bearer $DIGITALOCEAN_TOKEN" \
                -d "$data" \
                "$url")

            record_data=$(echo $new_record| jq -r ".data")
        fi

        if [[ "$ip" != "$record_data" ]]; then
            echo "existing DNS record address ($record_data) doesn't match current IP ($ip), sending data=$data to url=$url"

            curl -s -X PUT \
                -H "Content-Type: application/json" \
                -H "Authorization: Bearer $DIGITALOCEAN_TOKEN" \
                -d "$data" \
                "$url" &> /dev/null
        else
            echo "existing DNS record address ($record_data) did not need updating"
        fi

        if [[ -z $record_id6 ]]; then
            echo "No record found with '$sub' domain name. Creating record, sending data=$data6 to url=$url6"

            new_record6=$(curl -s -X POST \
                -H "Content-Type: application/json" \
                -H "Authorization: Bearer $DIGITALOCEAN_TOKEN" \
                -d "$data6" \
                "$url6")

            record_data6=$(echo $new_record6| jq -r ".data")
        fi

        if [[ "$ip6" != "$record_data6" ]]; then
            echo "existing DNS record address ($record_data6) doesn't match current IP ($ip6), sending data=$data6 to url=$url6"

            curl -s -X PUT \
                -H "Content-Type: application/json" \
                -H "Authorization: Bearer $DIGITALOCEAN_TOKEN" \
                -d "$data6" \
                "$url6" &> /dev/null
        else
            echo "existing DNS record address ($record_data6) did not need updating"
        fi
        if [ "$SLEEP" = true ] ; then
            sleep infinity
        fi
    done

fi
