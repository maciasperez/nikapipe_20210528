
day            = '20140127'

scan_num       = 253
source         = 'Uranus'

;;---------------------------------------
;; Ensure no default values are left from the previous run_XX.pro during
;; observations !
delvarx, param, sn_min, sn_max
;;---------------------------------------

no_acq_flag    = 0
fast           = 1
png            = 1
noskydip       = 1
;sn_min         = 1400
;sn_max         = 16000

output_kidpar_nickname = "kidpar_"+strtrim(day,2)+"s"+strtrim(scan_num,2)
otf_geometry, day, scan_num, noskydip=noskydip, sn_min=sn_min, sn_max=sn_max, $
              RF=RF, output_kidpar_nickname=output_kidpar_nickname, png=png, source=source, $
              one_mm_only=one_mm_only, two_mm_only=two_mm_only, fast=fast, no_acq_flag=no_acq_flag

end

