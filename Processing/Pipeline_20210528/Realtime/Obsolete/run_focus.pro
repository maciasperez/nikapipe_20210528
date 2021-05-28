;;---------------------------------------
;; Ensure no default values are left from the previous run_XX.pro during
;; observations !
delvarx, param, noimbfits, focusz, fooffset, pf, numdet1, numdet2
;;---------------------------------------

day      =  '20140122'
scan_num = 23

; set online to 1 and edit values if you can't use xml files
; (default) or antennaIMBfits
imbfits    = 0
online     = 1
focusz     = -2.4
fooffset   = [0, 1, 1, -1, -1, 0]


; set to 1 to use RF instead of PF
RF         = 0

; set to 1 to procude plots and logbook
png        = 0


numdet1 = 118
numdet2 = 411
focus, scan_num, day, /online, numdet1=numdet1, numdet2=numdet2, f1, f2, common_mode_radius=30., $
       noskydip=noskydip, png=png, param=param, RF=RF, imbfits=imbfits, fooffset=fooffset, focusz=focusz
end
