;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_define_kid_corr_block
;
; CATEGORY: toi processing, subroutine of nk_decor
;
; CALLING SEQUENCE:
;
; 
; PURPOSE: 
;        Determines blocks of kids that must be used to estimate common modes
;for the decorrelation
; 
; INPUT: 
; 
; OUTPUT: 
;        kid_corr_block: a (nkid,nkid) array, with 1 where kids must be taken
;for the decorrelation, 0 otherwise.
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Apr. 8th, 2016: NP
;-

pro nk_define_kid_corr_block, param, info, data, kidpar, kid_corr_block

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_define_kid_corr_block, param, info, data, kidpar, kid_corr_block"
   return
endif

if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

nkids = n_elements(kidpar)
kid_corr_block = intarr(nkids,nkids)

;; Classic common modes
if strupcase(param.decor_method) eq "COMMON_MODE" or $
   strupcase(param.decor_method) eq "COMMON_MODE_KIDS_OUT" then begin
   for iarray=1, 3 do begin
      w1 = where(kidpar.type eq 1 and kidpar.array eq iarray, nw1)
      if nw1 ne 0 then begin
         for i=0, nw1-1 do kid_corr_block[w1[i],w1] = 1
      endif
   endfor
endif

;; For SZ and polarization, decorrelate the 2mm from the 1mm
if strupcase(param.decor_method) eq "DUAL_BAND" then begin
   w13 = where( kidpar.type eq 1 and (kidpar.array eq 1 or kidpar.array eq 3), nw13)
   if nw13 eq 0 then begin
      txt = "no kids at 1mm for this observation => can't use dual_band decorrelation"
      nk_error, info, txt
      return
   endif else begin
      for iarray=1, 3 do begin
         w1 = where(kidpar.type eq 1 and kidpar.array eq iarray, nw1)
         if nw1 ne 0 then begin
            for i=0, nw1-1 do kid_corr_block[w1[i],w13] = 1
         endif
      endfor
   endelse
endif

;; Take kids of the same box
if strupcase(param.decor_method) eq "COMMON_MODE_BOX" then begin
   w1 = where( kidpar.type eq 1, nw1)
   for i=0, nw1-1 do begin
      ikid = w1[i]
      w = where( kidpar.acqbox eq kidpar[ikid].acqbox, nw)
      kid_corr_block[ikid,w] = 1
   endfor
endif

;; Kids in the same multiplexing frequency band
if strupcase(param.decor_method) eq "COMMON_MODE_SUBBAND" then begin
   w1 = where( kidpar.type eq 1, nw1)
   band = long( kidpar.numdet/80.)
   for i=0, nw1-1 do begin
      ikid = w1[i]
      w = where( band eq band[ikid] and kidpar.type eq 1, nw)
      if nw ne 0 then kid_corr_block[ikid,w] = 1
   endfor
endif

end
