#!/bin/bash

cat ftp.config | \
curl --ssl-reqd -K - | \
Rscript test.R
