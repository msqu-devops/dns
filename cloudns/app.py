# -*- coding: utf-8 -*-
# pylint: disable=locally-disabled, multiple-statements
# pylint: disable=fixme, line-too-long, invalid-name
# pylint: disable=W0703

""" ClouDNS updater script for container format. App file. """

__author__ = 'EA1HET'
__date__ = "27/12/2019"

import socket
import requests
import settings
from sys import exit
from time import sleep
from datetime import datetime


try:
    url_cdns = settings.Config.url_cdns
    url_ipio = settings.Config.url_ipio
    log_file = settings.Config.log_file
    hostname = settings.Config.hostname
    sleeptime = settings.Config.sleeptime
except Exception as e:
    print('Unexpected: %s' % e)
    exit(1)


def read_ip_from_log_file():
    """
    Reads log file and gets last IP address logged. In case there's no IP to get, a symbolic
    IP address is returned (0.0.0.0) to force a ClouDNS request for update.

    :param: None.
    :return: An IP address, as string.
    """
    try:
        with open(log_file, 'a+') as f:
            lines = f.read().splitlines()
            if not lines:
                lastline_ip = '0.0.0.0'
                return lastline_ip
            else:
                lastline_ip = lines[-1]
                return lastline_ip[27:]
    except Exception as e:
        print('Error %s' % e)
        exit(1)


def check_actual_ip(i):
    """
    Check current apparent IP address and writes log with it.

    :param: A counter to print nice information traces in stdout.
    :return: An IP address, as string.
    """
    resp = requests.get(url=url_ipio).json()
    linea_log = str(datetime.utcnow().isoformat(timespec='seconds') + ' (UTC): ' + resp['ip'])
    with open(log_file, 'a') as f:
        f.write(linea_log + '\r\n')
    print(linea_log + ' (# %s) ' % i)
    return resp['ip']


def update_ip(ip):
    """
    CloudDNS update request via HTTP API call, only if local IP and IP on ClouDNS are different.

    :param: An IP address, as string.
    :return: None.
    """
    ip_in_cdns = socket.gethostbyname(hostname)

    if ip_in_cdns == ip:
        print('Update: Actual IP is the same than ClouDNS. ClouDNS update call not executed.')
    else:
        try:
            requests.get(url=url_cdns, timeout=(2, 10))
            print('Update: IP updated in ClouDNS')
        except Exception as e:
            print('Error %s' % e)
            exit(1)


def main():
    counter = 0
    while True:
        try:
            counter += 1
            ip_prev = read_ip_from_log_file()
            ip_now = check_actual_ip(counter)
            if ip_prev != ip_now:
                update_ip(ip_now)
        except Exception as e:
            print('Error %s' % e)

        try:
            sleep(sleeptime)
        except KeyboardInterrupt:
            print('Manually stopped the program.')
            exit(1)
        except Exception as e:
            print('Error %s' % e)
            exit(1)


if __name__ == '__main__':
    main()
