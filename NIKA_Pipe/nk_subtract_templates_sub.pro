;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_subtract_templates_sub
;
; CATEGORY: toi processing
;
; CALLING SEQUENCE:
;         nk_subtract_templates_sub
; 
; PURPOSE: 
;        Regress and subtract templates from data.toi
; 
; INPUT: 
;        - param: the reduction parameters structure
;        - info: an information structure to be filled
;        - data: the NIKA general data structure
;        - kidpar: the NIKA general kid structure
; 
; OUTPUT: 
;        - templates_1mm and templates_2mm: templates to be subtracted at 1 and 2mm
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - April 08th, 2014: creation (Nicolas Ponthieu & Remi Adam - adam@lpsc.in2p3.fr)
;-
;=================================================================================================

pro nk_subtract_templates_sub, info, toi, flag, off_source, templates

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_subtract_templates_sub, info, toi, flag, off, templates_1mm, templates_2mm"
   return
endif

if info.status eq 1 then begin
   if param.silent eq 0 then    message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

nsn = n_elements( toi[0,*])
nkids = n_elements( toi[*,0])

for ikid=0, nkids-1 do begin
   ;; Determine "good" samples
   wsample  = where( off_source[ikid,*] eq 1 and $
                     flag[      ikid,*] eq 0, nwsample)
   if nwsample eq 0 then begin
      ;; fatal error
      nk_error, info, "no sample for which numdet "+strtrim(ikid,2)+" is off source and flag=0"
      return
   endif
   if nwsample lt 100 then begin
      ;; warning only
      nk_error, info, "Less than 100 samples for which ikid "+strtrim(ikid,2)+" is off source and flag=0", status=2
   endif
   
   ;; Regress the templates on the data off source
   y = reform( toi[ikid,wsample])
   coeff = regress( templates[*,wsample], y, $
                    CHISQ= chi, CONST= const, CORRELATION= corr, $
                    /DOUBLE, FTEST=ftest, MCORRELATION=mcorr, SIGMA=sigma, STATUS=status, YFIT=yfit)

   ;; Subtract the templates on the entire subscan
   yfit = dblarr(nsn) + const
   for ii=0, n_elements(coeff)-1 do yfit += coeff[ii]*templates[ii,*]
   toi[ikid,*] -= yfit

endfor


end
