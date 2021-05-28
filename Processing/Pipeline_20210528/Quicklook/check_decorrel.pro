
;; Quick look at cryostat fluctuations and how to decorrelate them


;; Check for magnetic jumps
dir =  "/home/archeops/NIKA/Data/raw_Y9/Y9_2013_06_06"

file = dir+"/Y_2013_06_06_10h11m05_I"

list_data = "RF_didq retard "+strtrim( !nika.retard,2)
rr = read_nika_brute(file, param_c, kidpar, data, units, $
                     list_data=list_data, read_type=12, indexdetecteurdebut=indexdetecteurdebut, $
                     nb_detecteurs_lu=nb_detecteurs_lu, amp_modulation=amp_modulation, silent=1)

data.rf_didq = -data.rf_didq  ; to have positive peaks
time = dindgen( n_elements(data))/!nika.f_sampling

w1 = where( kidpar.type eq 1, nw1)

;; quicklook
make_ct, nw1, ct
wind, 1, 1, /free
plot, time,  data.rf_didq[w1[0]] - data[0].rf_didq[w1[0]], /nodata,  xtitle = 'Time [sec]'
for i=0, nw1-1 do begin
   ikid = w1[i]
   oplot, data.rf_didq[w1[i]]- data[0].rf_didq[w1[i]], col=ct[i]
   print, "ikid = ", ikid
endfor

;; Decorrelate from the first 3 kids (e.g.)
templates =  data.rf_didq[w1[0:2]]
qd_decorrel_3,  data.rf_didq,  templates,  toi_out,  /verb

wind, 1, 1, /large, /free
!p.multi = [0, 1, 2]
plot, data.rf_didq[w1[10]]
plot, toi_out[w1[10], *]
!p.multi = 0


end
   

