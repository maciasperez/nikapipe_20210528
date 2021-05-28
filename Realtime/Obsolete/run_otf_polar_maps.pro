
delvarx, sn_min, sn_max, scan_num

pf = 1

;; Run7
day      = '20140127'
scan_num = 265
source   = " Uranus "
png=0

;; uncomment sn_min and sn_max if problem of tuning in the timeline
;; set numbers accordingly (see timeline plot)
;sn_min = 
;sn_max = 


otf_polar_maps, scan_num, day, maps_s0_lockin, maps_s1_lockin, maps_s2_lockin, $
                maps_s0_coadd, maps_s1_coadd, maps_s2_coadd, $
                param=param, $
                sn_min=sn_min, sn_max=sn_max, png=png, xmap=xmap, ymap=ymap

end
