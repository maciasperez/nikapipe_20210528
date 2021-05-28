;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_set0level_check
;
; CATEGORY: toi processing
;
; CALLING SEQUENCE:
;         nk_set0level_check, param, info, data, kidpar
; 
; PURPOSE: 
;        computes the 0 level
; 
; INPUT: 
; 
; OUTPUT: 
;        - kidpar is changed if no data available for a kid 
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - March 2020, FXD

pro nk_set0level_check, param, info, data, kidpar, wsubscan
;-

if n_params() lt 1 then begin
   dl_unix, 'nk_set0level_check'
   return
endif

nwsubscan = n_elements(wsubscan)
w1 = where( kidpar.type eq 1, nw1)
if nw1 eq 0 then begin
   nk_error, info, "No valid kid"
   return
endif

toi_stokes = ['toi']
if info.polar ne 0 and param.force_zero_level_polar ne 0 then begin
   toi_stokes = [toi_stokes, 'toi_q', 'toi_u']
endif
nstokes = n_elements(toi_stokes)

for istokes=0, nstokes-1 do begin
   junk = execute( "toi1 = data[wsubscan]."+toi_stokes[istokes]+"[w1]")
   if (size(toi1))[0] lt 2 then message, /info, param.scan
   toi_avg = avg( toi1, 1, /nan) ; one average zero level per kid
   winf = where( finite(toi_avg) ne 1, nwinf)
   if nwinf ne 0 then kidpar[w1[winf]].type = 4
endfor

end
