#!/bin/bash

api_host="https://api.digitalocean.com/v2"
remove_duplicates=${REMOVE_DUPLICATES:-"true"}

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

        if [ $(echo "$record_id" | wc -l) -ge 2 ]; then :
            if [[ "${remove_duplicates}" == "true" ]]; then :
                echo "'$sub' domain name has duplicate A DNS records, removing duplicates"
                record_id_to_delete=$(echo "$record_id"| tail -n +2)
                record_id=$(echo "$record_id"| head -1)
                record_data=$(echo "$record_data"| head -1)

                while IFS= read -r line; do
                    curl -s -X DELETE \
                        -H "Content-Type: application/json" \
                        -H "Authorization: Bearer $DIGITALOCEAN_TOKEN" \
                        "$dns_list/$line" &> /dev/null
                done <<< "$record_id_to_delete"
            else :
                echo "Unable to update '$sub' domain name as it has duplicate A DNS records. Set REMOVE_DUPLICATES='true' to remove them."
                continue
            fi
        fi

        if [ $(echo "$record_id6" | wc -l) -ge 2 ]; then :
            if [[ "${remove_duplicates}" == "true" ]]; then :
                echo "'$sub' domain name has duplicate AAAA DNS records, removing duplicates"
                record_id6_to_delete=$(echo "$record_id6"| tail -n +2)
                record_id6=$(echo "$record_id6"| head -1)
                record_data6=$(echo "$record_data6"| head -1)

                while IFS= read -r line; do
                    curl -s -X DELETE \
                        -H "Content-Type: application/json" \
                        -H "Authorization: Bearer $DIGITALOCEAN_TOKEN" \
                        "$dns_list/$line" &> /dev/null
                done <<< "$record_id6_to_delete"
            else :
                echo "Unable to update '$sub' domain name as it has duplicate AAAA DNS records. Set REMOVE_DUPLICATES='true' to remove them."
                continue
            fi
        fi

        # re-enable glob expansion
        set +f

        data="{\"type\": \"A\", \"name\": \"$sub\", \"data\": \"$ip\"}"
        data6="{\"type\": \"AAAA\", \"name\": \"$sub\", \"data\": \"$ip6\"}"
        url="$dns_list/$record_id"
        url6="$dns_list/$record_id6"

        if [[ -z $record_id ]]; then
            echo "No A record found with '$sub' A domain name. Creating record, sending data=$data to url=$url"

            new_record=$(curl -s -X POST \
                -H "Content-Type: application/json" \
                -H "Authorization: Bearer $DIGITALOCEAN_TOKEN" \
                -d "$data" \
                "$url")

            record_data=$(echo $new_record| jq -r ".data")
        fi

        if [[ "$ip" != "$record_data" ]]; then
            echo "existing A DNS record address ($record_data) doesn't match current IP ($ip), sending data=$data to url=$url"

            curl -s -X PUT \
                -H "Content-Type: application/json" \
                -H "Authorization: Bearer $DIGITALOCEAN_TOKEN" \
                -d "$data" \
                "$url" &> /dev/null
        else
            echo "existing A DNS record address ($record_data) did not need updating"
        fi

        if [[ -z $record_id6 ]]; then
            echo "No AAAA record found with '$sub' domain name. Creating record, sending data=$data6 to url=$url6"

            new_record6=$(curl -s -X POST \
                -H "Content-Type: application/json" \
                -H "Authorization: Bearer $DIGITALOCEAN_TOKEN" \
                -d "$data6" \
                "$url6")

            record_data6=$(echo $new_record6| jq -r ".data")
        fi

        if [[ "$ip6" != "$record_data6" ]]; then
            echo "existing AAAA DNS record address ($record_data6) doesn't match current IP ($ip6), sending data=$data6 to url=$url6"

            curl -s -X PUT \
                -H "Content-Type: application/json" \
                -H "Authorization: Bearer $DIGITALOCEAN_TOKEN" \
                -d "$data6" \
                "$url6" &> /dev/null
        else
            echo "existing AAAA DNS record address ($record_data6) did not need updating"
        fi
        if [ "$SLEEP" = true ] ; then
            sleep infinity
        fi
    done

fi
