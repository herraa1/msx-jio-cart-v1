#!/bin/bash

dir=$1
dst=$2
src=$3
beg=$4
end=$5
exe=$6

wav=${dst%.*}
record_name=${wav/JIOC/J}

do_begin() {
  echo '<openmsx-control>'
}

do_end() {
  echo '</openmsx-control>'
}

do_command() {
  >&2 echo '<command>'"$@"'</command>'
  echo '<command>'"$@"'</command>'
}

#do_begin
do_command 'set renderer SDL'
do_command 'set power on'
sleep 12
do_command "cassetteplayer new $dir/$wav"
do_command 'type "LOAD \"JIOCCAS.BAS\"\r"'
sleep 3 
do_command 'type "SAVE \"CAS:'"${record_name}"'\"\r"'
sleep 16
do_command 'type "BLOAD \"'"${src}"'\"\r"'
sleep 4 
do_command 'type "BSAVE \"CAS:BIN\",'"$beg"','"$end"','"$exe"'\r"'
sleep 27 
do_command 'exit'
#do_end

