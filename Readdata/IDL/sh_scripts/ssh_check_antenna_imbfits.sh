#!/bin/sh
#1 filename
ssh -t -t t21@gra-lx1.iram.es << EOF
./ssh_check_file.sh $1
exit
EOF

