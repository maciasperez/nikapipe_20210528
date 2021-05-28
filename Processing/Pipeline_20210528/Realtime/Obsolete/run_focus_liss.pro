
day            = '20140123'
scan_num_list  = 124 + indgen(5)

focus          =  -0.8
list_foc_shift = [0.0, -0.6, -1.2, 0.6, 1.2]

; set to 1 if the source is centered to save time
fast = 1

; set to 1 to output .png and logbook
png = 1

; set to 1 to use RF instead of PF
RF = 0

;; to decorrelate from elevation in Lissajous mode too
;param.fit_elevation = "yes"

no_acq_flag = 0
focus_list = focus + list_foc_shift
focus_liss, day, scan_num, focus_list=focus_list, png=png, fast=fast, no_acq_flag=no_acq_flag, RF=RF, /online
            


end
