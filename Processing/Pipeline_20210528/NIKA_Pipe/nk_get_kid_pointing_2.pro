
;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_get_kid_pointing_2
;
; CATEGORY:
;
; CALLING SEQUENCE:
;         nk_get_kid_pointing_2
; 
; PURPOSE: 
;        Computes kids individual pointing in Ra and Dec
; 
; INPUT: 
;        - param: the reduction parameters structure
;        - info: an information structure to be filled
;        - data: the nika data structure
;        - kidpar: the kids strucutre
; 
; OUTPUT: 
;        - data.dra, data.ddec
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Apr 17th, 2018: NP + AA
;-
;===============================================================================================

pro nk_get_kid_pointing_2, param, info, data, kidpar

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_get_kid_pointing_2, param, info, data, kidpar"
   return
endif

if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

if param.cpu_time then param.cpu_t0 = systime(0, /sec)

if param.zigzag_correction eq 1 then begin
   nsn = n_elements(data)
   time = dindgen(nsn)/!nika.f_sampling
   
   ;; ;; The delay between NIKA2 and the telescope must be applied
   ;; ;; only to the a_t_uc which is the reference time and because,
   ;; ;; even if there's a time difference in utc between the
   ;; ;; different boxes, the *measurements* are all taken
   ;; ;; simultaneouly
   ;; ;; NP, Aug. 11th, 2016
   ;; w1 = where( kidpar.type eq 1, nw1)
   
   ;; Not so sure anymore... trying a zigzag per array util we
   ;; understand why (NP, Sept. 19, 2016)
   ofs_az = data.ofs_az
   ofs_el = data.ofs_el
   az     = data.az
   el     = data.el
   paral  = data.paral
   ;; avoid the loop to save time with interpol and
   ;; nk_get_kid_pointing
   if (!nika.zigzag[1] eq !nika.zigzag[0]) and $
      (!nika.zigzag[2] eq !nika.zigzag[0]) then begin
      w1 = where( kidpar.type eq 1, nw1)
      if nw1 ne 0 then begin
         time1 = time + !nika.zigzag[0]
         data.ofs_az = interpol( ofs_az, time, time1)
         data.ofs_el = interpol( ofs_el, time, time1)
         data.az     = interpol( az,     time, time1)
         data.el     = interpol( el,     time, time1)
         data.paral  = interpol( paral,  time, time1)
         nk_get_kid_pointing, param, info, data, kidpar
         
         nsnflag = round( !nika.zigzag[0]*!nika.f_sampling) > 1
         ;data[0:nsnflag-1].flag[w1]       += 1
         ;data[nsn-nsnflag:nsn-1].flag[w1] += 1
         ;NP, Nov. 28th, 2020
         nk_add_flag, data, 9, wsample=lindgen(nsnflag), wkid=w1
         nk_add_flag, data, 9, wsampl=lindgen(nsn-1-(nsn-nsnflag)+1)+(nsn-nsnflag), wkid=w1

      endif
   endif else begin
      for iarray=1, 3 do begin
         w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1)
         if nw1 ne 0 then begin
            time1 = time + !nika.zigzag[iarray-1]
            data.ofs_az = interpol( ofs_az, time, time1)
            data.ofs_el = interpol( ofs_el, time, time1)
            data.az     = interpol( az,     time, time1)
            data.el     = interpol( el,     time, time1)
            data.paral  = interpol( paral,  time, time1)
            nk_get_kid_pointing, param, info, data, kidpar
            
            nsnflag = round( !nika.zigzag[iarray-1]*!nika.f_sampling) > 1
            ;data[0:nsnflag-1].flag[w1]       += 1
            ;data[nsn-nsnflag:nsn-1].flag[w1] += 1
            ;NP, Nov. 28th, 2020
            nk_add_flag, data, 9, wsample=lindgen(nsnflag), wkid=w1
            nk_add_flag, data, 9, wsampl=lindgen(nsn-1-(nsn-nsnflag)+1)+(nsn-nsnflag), wkid=w1
         endif
      endfor
   endelse
   
endif else begin
   nk_get_kid_pointing, param, info, data, kidpar
endelse


if param.cpu_time then nk_show_cpu_time, param


end
