# How to synchronize data processing quick output to the web (/ on first dir, no / on second dir)
rsync -Hbva -e "ssh -l ssh-user" /home/archeops/NIKA/Plots/ t21@mrt-lx1.iram.es:/mrt-lx1/var/www/Devices/NIKA/Run6 >> /home/archeops/temp/log/rsync_web.log 2>&1
# do that every 15 minutes
# and a kill of rsync every 5 minutes
/usr/bin/pkill rsync
