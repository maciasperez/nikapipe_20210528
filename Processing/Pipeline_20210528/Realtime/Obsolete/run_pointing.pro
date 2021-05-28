
;; le fit de la source sur les timelines donne la position de la reference de
;; pointage par rapport a la source. La carte donne la position de la source
;; dans les coordonnees de la reference de pointage. Il y a donc un signe "-"
;; entre les deux conventions

;;---------------------------------------
;; Ensure no default values are left from the previous run_XX.pro during
;; observations !
delvarx, param, numdet1, numdet2, noimbfits, p2cor, p7cor, one_mm_only, two_mm_only, pf, educated
;;---------------------------------------


day      =  20140123
scan_num = 143

; set online to 1 to pass the following values or imbfits to get them
; from the antennaIBMfits
online  = 1
imbfits = 0

; Pointing offsets at the beginning of the scan
;p2cor    = 1d-10
;p7cor    = 1d-10
p2cor    = -4.7
p7cor    = -1.7

; set to 1 to educate the fit around the center of the array
educated = 0

; set to 1 to use RF instead of PF
RF       = 0

; set to 1 to display focal plane
focal    = 0

; set to 1 to produce png and generate the logbook
png      = 0

; set to 1 to ignore tau estimation with skydip coeffs
noskydip = 0

; set to 1 to have a few sanity check plots
check = 0


pointing, scan_num, day, offsets1, offsets2, /online, $
          numdet1=numdet1, numdet2=numdet2, $
          param=param, noskydip=noskydip, png=png, RF=RF, $
          one_mm_only=one_mm_only, two_mm_only=two_mm_only, $
          p2cor=p2cor, p7cor=p7cor, educated=educated, check=check


end


