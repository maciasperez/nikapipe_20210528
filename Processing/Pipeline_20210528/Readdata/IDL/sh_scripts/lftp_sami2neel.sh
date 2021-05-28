#!/bin/sh
# band limited ftp
#1 path1
#2 path2
#3 local name (complete)

lftp ftp://archeops:crtbt01@share.neel.cnrs.fr << EOF
cd Archeops
cd $1
cd $2
put $3

EOF

