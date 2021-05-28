#!/bin/sh
#1 option
#2 chemin fichier brute
#3 param nom
#4 dossier jour
#5 nom fichier brute



ftp -niv share.neel.cnrs.fr << EOF
user archeops crtbt01
cd Archeops
mkdir $1
cd $1
mkdir $2
cd $2
bi
put $3 $4
EOF

