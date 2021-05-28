#!/bin/sh
# 1 is initial directory
# 2 is filename



scp $1/$2 archeops@bambini.grenoble.cnrs.fr:/home/archeops/temp/transfer/$2
#ssh archeops@bambini.grenoble.cnrs.fr 'scp /home/archeops/temp/transfer/\"$2"\ nika@lpsc-ssh.in2p3.fr:/data3/NIKA/data-nika/Raw_data/Run7/raw_X10/'

exit
EOF

