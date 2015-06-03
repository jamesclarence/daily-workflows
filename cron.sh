#!/bin/bash

source $HOME/app/.profile
cd $HOME/app/
srm -sr ./tmp/*
srm -sr ./output/*
node app.js
