;+
;
; SOFTWARE: NIKA pipeline
;
; NAME:
;     nk_add_flag
;
; CATEGORY: toi processing
;
; CALLING SEQUENCE:
;         nk_add_flag, data, flag_num, wsample=wsample, wkid=wkid, w2d_k_s=w2d_k_s
; 
; PURPOSE: 
;        Adds 2L^flag_num to the relevant samples, unless they have
;already been flagged with the same flag_num
; 
; INPUT: 
;        - data
;        - flag_num:
;  0: glitch
;  1: off resonance
;  2: saturated kid
;  3: out of resonance kid
;  4: Resonance overlap
;  5: Cross talking detector
;  6: Anomalous detector, to be discarded
;  7: rf_didq not well computed
;  8: Not a proper part of the scan
;  9: Interpolated missing data (large pointing error)
; 10: kid tuning
; 11: Anomalous scan speed
; 12: frequency scanning
; 13: frequency scanning blanking
; 14: FPGA frequency change
; 15: tuning error
; 16: Wrong resonance
; 17: Lost resonance
; 18: scan status
; 19: Dilution temperature glitch
; 20: Jump in the toi
; 
; OUTPUT: 
;        - data.flag is modified
; 
; KEYWORDS:
;        - wsample: subset of samples to be considered (default: all
;          samples)
;        - wkid: subset of kids to be considered (default: all kids)
;        - w2d_k_s: global index in the data.flag array of pairs of
;            KIDs and samples to be considered (no default)
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - June 3rd, : Nicolas Ponthieu & Remi Adam - adam@lpsc.in2p3.fr
;          - Oct 24th: remove keywords that can be misinterprated (e.g. kid=0,
;            was considered as "all kids". The same for wsample)
;        - Nov. 9, 2016: replace loop on KIDs for more efficient array operations (HR)


;; Confirm comparison syntax
;; poweroftwo = [2L^0, 2L^2, 2L^8, 2L^11]
;; vec = [poweroftwo, 2L^8 + 2L^2 + 2L^6]
;; for i=0, 11 do begin
;;    print,  "i: "+string(i,form='(I2.2)')+", ", (vec and 2L^i) eq 2L^i
;; endfor

pro nk_add_flag, data, flag_num, wsample=wsample, wkid=wkid, w2d_k_s=w2d_k_s
;-

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   dl_unix, 'nk_add_flag'
   return
endif

nsn   = n_elements(data)
nkids = n_elements( (data.toi)[*,0])

;; use defined instead of keyword_set to allow "0" as an input.
if defined(wsample) eq 0 then wsample = lindgen(nsn)
if defined(wkid)    eq 0 then wkid    = lindgen( nkids)

;;; replacement:
;;powerOfTwo = byte(2L^flag_num)
powerOfTwo = 2L^flag_num

if defined(w2d_k_s) then begin
   arr_all = data.flag
   flag_vect = arr_all(w2d_k_s)
   deja_flag = where((LONG(flag_vect) AND powerOfTwo) EQ powerOfTwo, ndeja_flag, $
                     comp=pas_flag, ncomp=npas_flag)
   if npas_flag ge 1 then begin
      flag_vect(pas_flag) += long(powerOfTwo)
      arr_all(w2d_k_s) = flag_vect
      data.flag = arr_all
   endif
endif else begin
   arr_allkids = data[wsample].flag
   flag_array = arr_allkids(wkid, *)
   deja_flag = where((LONG(flag_array) AND powerOfTwo) EQ powerOfTwo, ndeja_flag, $
                     comp=pas_flag, ncomp=npas_flag)
   if npas_flag ge 1 then begin
      flag_array(pas_flag) += long(powerOfTwo)
      arr_allkids(wkid, *) = flag_array
      data[wsample].flag = arr_allkids
   endif
endelse

end
