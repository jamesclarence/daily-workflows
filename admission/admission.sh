#!/bin/bash

FILE=ftp://camdenhie.careevolution.com/ReportSnapshots/2014-06-08/United-Lourdes.csv

cat ftp.config | \
curl --ssl-reqd -K - $FILE | \
Rscript test.R
