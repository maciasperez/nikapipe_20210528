
;; Check for magnetic jumps

file = "/home/archeops/NIKA/Data/raw_Y9/Y9_2013_06_05/Y_2013_06_05_15h48m37_0075_I_1418+546"

list_data = "subscan scan RF_didq retard "+strtrim(!nika.retard,2)+" ofs_az ofs_el"
rr = read_nika_brute(file, param_c, kidpar, data, units, $
                     list_data=list_data, read_type=12, indexdetecteurdebut=indexdetecteurdebut, $
                     nb_detecteurs_lu=nb_detecteurs_lu, amp_modulation=amp_modulation, silent=1)

data.rf_didq = -data.rf_didq  ; to have positive peaks

w1 = where( kidpar.type eq 1, nw1)

;; quicklook
make_ct, nw1, ct
wind, 1, 1, /free
plot, data.rf_didq[w1[0]] - data[0].rf_didq[w1[0]], /nodata
for i=0, nw1-1 do begin
   ikid = w1[i]
   oplot, data.rf_didq[w1[i]]- data[0].rf_didq[w1[i]], col=ct[i]
   print, "ikid = ", ikid
endfor

time = dindgen( n_elements(data))/!nika.f_sampling

wind, 1, 1, /free
plot, data.rf_didq[w1[0]] - data[0].rf_didq[w1[0]], /nodata
for i=281, nw1-1 do begin
   ikid = w1[i]
   plot, data.rf_didq[ikid]- data[0].rf_didq[ikid], col=ct[i]
   legendastro, ["ikid: "+strtrim( ikid,2), $
                 "numdet: "+strtrim( kidpar[ikid].numdet,2)], box=0, /right
   stop
endfor

; 350, 350

; 12, 25 et tous les autres... : decrochement
; 6  bizarre
; 67, 69

; i=237, ikid=293, numdet=41
; numdet = 52, 78

numdet = 5
numdet = 1
numdet = 60
ikid=where( kidpar.numdet eq numdet)

ikid = 293

ikid = where( kidpar.numdet eq 78) & ikid = ikid[0]
ikid = 339
plot, time, data.rf_didq[ikid]- data[0].rf_didq[ikid], xtitle='Time [sec]', ytitle='RF dIdQ'
legendastro, ["ikid: "+strtrim( ikid,2), $
              "numdet: "+strtrim( kidpar[ikid].numdet,2)], box=0, /right, chars=1.5


end
   
