
day      = '20140127'

scan_num = 190
p2cor    = -5.3
p7cor    = -1.2

;;---------------------------------------
;; Ensure no default values are left from the previous run_XX.pro during
;; observations !
delvarx, param, sn_min, sn_max, numdet1_in, numdet2_in
;;---------------------------------------

;sn_min = 2500
;sn_max = 7000


pf       = 1
png      = 0
noskydip = 1

one_mm_only = 0
two_mm_only = 0
polar =1
ps=0
;; to decorrelate from elevation in Lissajour mode too
;param.fit_elevation = "yes"

;focus_liss, day, scan_num, 0.2, p2cor=1e-10, p7cor=1e-10, png=png, param=param, noskydip=noskydip, pf=pf

numdet1_in = 5
numdet2_in = 494
pointing_liss, day, scan_num, p2cor=p2cor, p7cor=p7cor, numdet1_in=numdet1_in, numdet2_in=numdet2_in, $
               png=png, ps=ps, noimbfits=noimbfits, common_mode_radius=common_mode_radius, $
               polar=polar, noskydip=noskydip, pf=pf, sn_min=sn_min, sn_max=sn_max, $
               one_mm_only=one_mm_only, two_mm_only=two_mm_only
 

end
