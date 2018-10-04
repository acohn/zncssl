#!/bin/sh


cat /letsencrypt/live/${SSL_HOST}/privkey.pem /letsencrypt/live/${SSL_HOST}/fullchain.pem > /znc-data/znc.pem
