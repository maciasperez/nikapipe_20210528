#!/bin/sh
# 1 is initial directory -1
# 2 is the directory end
# 3 is filename



scp -C $1/$2/$3 archeops@bambini.grenoble.cnrs.fr:/home/archeops/temp/transfer/$3
ssh archeops@bambini.grenoble.cnrs.fr "scp /home/archeops/temp/transfer/\"$3\" nika@lpsc-ssh.in2p3.fr:/data3/NIKA/data-nika/Raw_data/Run7/raw_X10/\"$2\"/\"$3\""


exit
EOF

