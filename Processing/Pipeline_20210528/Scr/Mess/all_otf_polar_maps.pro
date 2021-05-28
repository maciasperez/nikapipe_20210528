
delvarx, sn_min, sn_max

pf = 1

;; Run7
day      = '20140126'
;scan_num = 186

source   = "Crab"
scan_num_list = [215,216,217,218,219,220,221,222,223,225,226,227,229,230]
nscans= n_elements(scan_num_list)

scan_num=223
;for iscans=0,nscans-1 do begin
 ;  scan_num = scan_num_list[iscans]
   nika_pipe_default_param, scan_num, day, param

;; uncomment sn_min and sn_max if problem of tuning in the timeline
;; set numbers accordingly (see timeline plot)
;sn_min = 
;sn_max = 


   otf_polar_maps, scan_num, day, maps_s0_lockin, maps_s1_lockin, maps_s2_lockin, $
                maps_s0_coadd, maps_s1_coadd, maps_s2_coadd, $
                param=param, $
                sn_min=sn_min, sn_max=sn_max, png=png, xmap=xmap, ymap=ymap

  stop
;endfor

end
