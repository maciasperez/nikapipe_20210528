#!/bin/sh
#1 date
#2 first scan
#3 last scan




ssh -t -t t21@gra-lx1.iram.es << EOF
./ssh_for_imbfits.sh $1 $2 $3 
exit
EOF

