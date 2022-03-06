#!/bin/bash

killall sclang
killall jackd
killall aj-snapshot 

jackd -P 95 -d alsa -d hw:USB -p 128 -n 2 &

wait 5 &

aj-snapshot -d full.snap &

sclang macro_MAIN.scd &
