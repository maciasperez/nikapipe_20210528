
day       = '20140127'
scan_num  = 293



;; set diffuse to 1 if your observe a diffuse source
diffuse = 0

;;---------------------------------------
;; Ensure no default values are left from the previous run_XX.pro during
;; observations !
delvarx, param, sn_min, sn_max
;;---------------------------------------

pf             = 1
png            = 1
noskydip       = 1

;; uncomment sn_min and sn_max if problem of tuning in the timeline
;; set numbers accordingly (see timeline plot)
;;sn_min         = 1000
;;sn_max         = 13000

otf_map, scan_num, day, noskydip=noskydip, sn_min=sn_min, sn_max=sn_max, pf=pf, png=png, diffuse=diffuse

end

