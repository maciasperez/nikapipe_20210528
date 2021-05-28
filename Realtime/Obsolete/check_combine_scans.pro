
;;; On crosses to be fast first
;scan_list = '20140123s'+strtrim([136,137,138],2)
;combine_scans, scan_list, /diffuse


;rta_map, '20140127', 290, maps, rms, /pf, /fast, /no_acq

;; On APM
reset = 0
;reset = 1
no_acq = 0
scan_list = '20140127s'+strtrim([290, 291, 292, 293],2)
combine_scans, scan_list, reset=reset


end
