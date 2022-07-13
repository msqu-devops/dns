# -*- coding: utf-8 -*-
# pylint: disable=locally-disabled, multiple-statements
# pylint: disable=fixme, line-too-long, invalid-name
# pylint: disable=W0703

""" ClouDNS updater script for container format. Settings file. """

__author__ = 'EA1HET'
__date__ = "27/12/2019"

from os import environ, path
from environs import Env


ENV_FILE = path.join(path.abspath(path.dirname(__file__)), '.env')

try:
    ENVIR = Env()
    ENVIR.read_env()
except Exception as e:
    print('Warning: .env file not found: %s' % e)


class Config:
    """
    This is the generic loader that sets common attributes

    :param: None
    :return: None
    """
    if environ.get('URL_CDNS'):
        url_cdns = ENVIR('URL_CDNS')

    if environ.get('URL_IPIO'):
        url_ipio = ENVIR('URL_IPIO')

    if environ.get('LOG_FILE'):
        log_file = ENVIR('LOG_FILE')

    if environ.get('LOG_FILE'):
        log_file = ENVIR('LOG_FILE')

    if environ.get('HOSTNAME'):
        hostname = ENVIR('HOSTNAME')

    if environ.get('SLEEPTIME'):
        sleeptime = int(ENVIR('SLEEPTIME'))
