#!/bin/bash

# colour part
Black='\033[0;30m'        # Black
Red='\033[0;31m'          # Red
RedBlink='\033[31;5m'     # Red Blink
Green='\033[0;32m'        # Green
GreenBlink='\033[32;5m'   # Green Blink
Brown='\033[0;33m'        # Brown
BrownBlink='\033[33;5m'   # Brown Blink
Blue='\033[0;34m'         # Blue
BlueBlink='\033[34;5m'    # Blue Blink
Purple='\033[0;35m'       # Purple
PurpleBlink='\033[35;5m'  # Purple Blink
NC='\033[0m' # No Color
Bold='\033[1m'
Blink='\033[5m'


# Variables
CLOUDNS_API_ID=${CLOUDNS_API_ID:-}
CLOUDNS_PASSWORD=${CLOUDNS_PASSWORD:-}
CLOUDNS_STRING=${CLOUDNS_STRING:-}
SLEEP_INFITY=${SLEEP_INFITY:=true}

# Create array
IFS=',' read -r -a array <<< "${CLOUDNS_STRING}"

cloudns_lookup() {
  HOSTNAME=$(echo ${array[0]} | cut -f1 -d.)
  DOMAIN=$(echo ${array[0]} | cut -f2- -d.)
  CLOUDNS_API=$(curl --silent -d auth-id=${CLOUDNS_API_ID} -d auth-password=${CLOUDNS_PASSWORD} -d domain-name=${DOMAIN} -d host=${HOSTNAME} -d type=a https://api.cloudns.net/dns/records.json | jq -r '.[].record')
  echo -e "${Brown} ClouDNS API: ${NC}" ${CLOUDNS_API}
}

current_ip() {
  CURRENTIP=$(dig @208.67.222.222 A myip.opendns.com +short -4)
  echo -e "${Blue} Current IP: ${NC}" ${CURRENTIP}
}

die() {
    echo "$1"
    exit 1
}

dig_lookup() {
  DNSENTRY=$(dig +short ${array[0]} @185.136.96.66)
  echo -e "${Purple} Dig Lookup: ${NC}" ${DNSENTRY}
}

wait-for-url() {
    timeout -s TERM 45 bash -c \
    'while [[ "$(curl -s -o /dev/null -L -w ''%{http_code}'' ${0})" != "200" ]];\
    do echo "Waiting for ${0}" && sleep 2;\
    done' ${1}
    #curl -I $1
    curl $1
}

run() {
  if [[ -z "$CLOUDNS_STRING" ]]; then
    echo -e "${Red} Required string not set! ${NC}"
    echo -e "${RedBlink} CLOUDNS_STRING is empty ${NC}"
    exit 1
  fi
  while (( ${#array[@]} ))
  do
    echo -e "${Green} Processing: ${NC}" ${array[0]}
    # pre check
    if [[ -z "$CLOUDNS_API_ID" ]] || [[ -z "$CLOUDNS_PASSWORD" ]]; then
        echo -e "${Purple} No ClouDNS Credentials provided ${NC}"
        dig_lookup
        OLD_IP=${DNSENTRY}
    else
        cloudns_lookup
        OLD_IP=${CLOUDNS_API}
    fi
    # get current IP
    current_ip
    # check if we need to update
    if [[ -z "$CURRENTIP" ]] || [[ -z "$OLD_IP" ]];then
        echo -e "${Red} One of the needed IPs is zero, can't compare ${NC}"
    elif [ "$CURRENTIP" != "$OLD_IP" ]; then
          wait-for-url https://ipv4.cloudns.net/api/dynamicURL/?q=${array[1]}
      else
        echo -e "${Green} Everything already OK ${NC}"
      fi
    array=( "${array[@]:2}" )
  done
  if [[ "$SLEEP_INFITY" = "true" ]]; then
    echo -e "${Green} I'm resting in peace, chill out! ${NC}"
    sleep infinity
  fi
}

run
