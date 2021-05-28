
;; Script to rsync the data during our observations while preserving the IRAM bandwidth.
;; Prescription from Carsten Kramer not to exceed 50Mbit/s


;; #The following command creates a backup of the home directory of tux on a
;; #backup server called jupiter:
;; rsync -Hbaz -e ssh /home/tux/ tux@jupiter:backup
;; 
;; ; Here one wants to backup nika telescope data into sami
;; ; Rsync from bambini to retrive sami data
;; --bwlimit=1000                  ; to limit to 1000kByte/s
;; ; No passwrd needed
;; ;OK: ssh archeops@mrt-nika1.iram.es
;; ; Log on bambini
;; ; rsync raw data
;; rsync -Hbvaz -e ssh archeops@mrt-nika1.iram.es:/home/archeops/NIKA/Data/raw_Y33 /home/archeops/NIKA/Data/
;; rsync -Hbvaz -e ssh archeops@mrt-nika1.iram.es:/NikaData /home/archeops/NIKA/Data/IramImbfits/
;; 
;; ; Log on t21@gra-lx1
;; ; here is an example (with not too many scans)
;; ; H preserves hard link, b is backup, v is verbose, a is archive, z is
;; ; compress during transfer
;; rsync -Hbvaz -e "ssh -l ssh-user" /ncsServer/mrt/ncs/data/20121024/scans/ archeops@mrt-nika1.iram.es:/home/archeops/Data/Iram/Scans/20121024

