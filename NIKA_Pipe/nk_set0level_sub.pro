;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_set0level_sub
;
; CATEGORY: toi processing
;
; CALLING SEQUENCE:
;         nk_set0level_sub, param, info, data, kidpar
; 
; PURPOSE: 
;        computes the 0 level
; 
; INPUT: 
; 
; OUTPUT: 
;        - data: 
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - June 10th, 2017: AA+NP

pro nk_set0level_sub, param, info, data, kidpar, wsubscan
;-

if n_params() lt 1 then begin
   dl_unix, 'nk_set0level_sub'
   return
endif

nwsubscan = n_elements(wsubscan)
w1 = where( kidpar.type eq 1, nw1)
if nw1 eq 0 then begin
   nk_error, info, "No valid kid"
   return
endif

;; Locate when we are on source to set these samples to NaN
;; and ignore them in avg
w_on = where( data[wsubscan].off_source[w1] eq 0 or data[wsubscan].flag[w1] ne 0, nw_on, compl=woff, ncompl=nwoff)

if nwoff ne 0 then begin
   toi_stokes = ['toi']

   if info.polar ne 0 and param.force_zero_level_polar ne 0 then begin
      toi_stokes = [toi_stokes, 'toi_q', 'toi_u']
   endif
   nstokes = n_elements(toi_stokes)
   
   for istokes=0, nstokes-1 do begin
      cmd = "toi1 = data[wsubscan]."+toi_stokes[istokes]+"[w1]"
      junk = execute( cmd)
      if nw_on ne 0 then toi1[w_on] = !values.d_nan
      if (size(toi1))[0] lt 2 then message, /info, param.scan
      toi_avg = avg( toi1, 1, /nan) ; one average zero level per kid
      junk = execute( "data[wsubscan]."+toi_stokes[istokes]+"[w1] -= rebin( toi_avg, nw1, nwsubscan)")

;;       ww = where( finite(toi_avg) eq 0, nww)
;;       if nww ne 0 then begin
;;          print, "info.CURRENT_SUBSCAN_NUM: "+strtrim(info.CURRENT_SUBSCAN_NUM,2)
;;          stop
;;       endif
      
   endfor
endif

end
