;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_subtract_templates_accel
;
; CATEGORY: toi processing
;
; CALLING SEQUENCE:
;         nk_subtract_templates_accel, param, info, toi, flag, off_source,
;                                  kidpar, templates, out_temp, out_coeffs=out_coeffs
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
;        - templates_1mm and templates_2mm : the templates that should be
;          regressed and subtracted from the TOI's.
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - April 08th, 2014: creation (Nicolas Ponthieu & Remi Adam -
;          adam@lpsc.in2p3.fr)
;        - Oct. 27th, 2014: NP, use matrix operations to speed things up
;          compared to the loop on kids and the use of "regress".
;=================================================================================================

pro nk_subtract_templates_accel, param, info, toi, flag, off_source, kidpar, $
                                 templates, out_temp, accelsm, out_coeffs=out_coeffs, $
                                 w8_source_in=w8_source_in
;-

if n_params() lt 1 then begin
   dl_unix, 'nk_subtract_templates_accel'
   return
endif

if info.status eq 1 then begin
   if param.silent eq 0 then    message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

nsn = n_elements(toi[0,*])

;; Ensure that "templates" have the correct form for REGRESS
templates_size = size(templates)
if templates_size[0] eq 1 then begin
   templates = reform( templates, [1,nsn])
   templates_size = size(templates)
endif

;; init
out_temp   = toi*0.d0
out_coeffs = dblarr(n_elements(kidpar), templates_size[1] + 1) ; add 1 for the constant

; Smooth and discretize
lacc2 = long(accelsm/2)
indsm = lindgen( nsn/lacc2) * lacc2
tempsm = (smooth( templates, [1, accelsm], /edge_truncate))[*,indsm]
toism = (smooth( toi, [1, accelsm], /edge_truncate))[*,indsm]
if keyword_set(w8_source_in) then $
   w8_source_insm = (smooth( w8_source_in, [1, accelsm], /edge_truncate))[*,indsm]
flagsm = (smooth( double(flag ne 0), [1, accelsm], /edge_truncate))[*,indsm]
off_sourcesm = (smooth( double(off_source eq 1), [1, accelsm], /edge_truncate))[*,indsm]

;; Main loop
w1 = where( kidpar.type eq 1, nw1)
for i=0, nw1-1 do begin
   ikid  = w1[i]
   ;; intersubscan samples do have higher noise and should be
   ;; discarded from the decorrelation.
   if keyword_set(w8_source_in) then begin
      wsample = where( finite(toism[ikid,*]) and finite(w8_source_insm[ikid,*]) $
                       and flagsm[ikid,*] lt 0.5, nwsample)
      if nwsample*lacc2 ge param.nsample_min_per_subscan then begin
         measure_errors = sqrt( reform(1.d0/w8_source_insm[ikid,wsample], nwsample))
      endif
   endif else begin
      delvarx, measure_errors
      wsample = where( off_sourcein[ikid,*] gt 0.5 and finite(toism[ikid,*]) eq 1 $
                       and flagsm[ikid,*] lt 0.5, nwsample)
   endelse
   ;; Regress the templates and the data off source
                                ; that should go much faster with the resampling
   if nwsample gt templates_size[1] then begin ; are there enough samples?
      coeff = regress( tempsm[*,wsample], reform( toism[ikid,wsample]), $
                       CHISQ= chi, CONST= const, CORRELATION= corr, $
                       measure_errors=measure_errors, $
                       /DOUBLE, FTEST=ftest, MCORRELATION=mcorr, $
                       SIGMA=sigma, STATUS=status)
      
      if status eq 0 then begin
         ;; Subtract the templates everywhere
         out_coeffs[ikid,0]   = const
         out_coeffs[ikid,1:*] = coeff[*]
         if param.no_const_in_regress eq 0 then begin
            yfit = const + templates##coeff
         endif else begin
            yfit = templates##coeff
         endelse
         
         toi[     ikid,*] -= yfit
         out_temp[ikid,*]  = yfit
      endif else begin
; FXD replaced
                                ; by just this message
         ;; do not project
         flag[ikid,*] = 2L^7
      endelse
   endif else begin ; case of not enough samples
      flag[ikid,*] = 2L^7
   endelse
endfor 


end
