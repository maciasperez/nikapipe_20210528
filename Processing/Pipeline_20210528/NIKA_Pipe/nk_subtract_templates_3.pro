;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_subtract_templates_3
;
; CATEGORY: toi processing
;
; CALLING SEQUENCE:
;         nk_subtract_templates_3, param, info, toi, flag, off_source,
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

pro nk_subtract_templates_3, param, info, toi, flag, off_source, kidpar, templates, out_temp, $
                             out_coeffs=out_coeffs, w8_source_in=w8_source_in, print_status=print_status
;-

if n_params() lt 1 then begin
   dl_unix, 'nk_subtract_templates_3'
   return
endif

;; if param.cpu_time then param.cpu_t0 = systime(0, /sec)

if info.status eq 1 then begin
   if param.silent eq 0 then    message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

nsn = n_elements(toi[0,*])

;; Ensure that "templates" has the correct form for REGRESS
templates_size = size(templates)
if templates_size[0] eq 1 then begin
   templates = reform( templates, [1,nsn])
   templates_size = size(templates)
endif

;; init
out_temp   = toi*0.d0
out_coeffs = dblarr(n_elements(kidpar), templates_size[1] + 1) ; add 1 for the constant

;; Main loop
w1 = where( kidpar.type eq 1, nw1)
for i=0, nw1-1 do begin
   ikid  = w1[i]
   ;; flagged data have either been interpolated and are safe or are due
   ;; to uncertain pointing between subscans, but this does not affect
   ;; their temporal correlation
   ;; 
   ;; July 10th: following Xavier's recommandation,
   ;; intersubscan samples do have higher noise and should be
   ;; discarded from the decorrelation.
   if keyword_set(w8_source_in) then begin
      ;; wsample = where( finite(toi[ikid,*]) and finite(w8_source_in[ikid,*]), nwsample)
      wsample = where( finite(toi[ikid,*]) and finite(w8_source_in[ikid,*]) and flag[ikid,*] eq 0, nwsample)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      if param.test1 then wsample = where( finite(toi[ikid,*]) and $
                                           finite(w8_source_in[ikid,*]) and $
                                           off_source[ikid,*] eq 1 and $
                                           flag[ikid,*] eq 0, nwsample)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

      if nwsample ge param.nsample_min_per_subscan then begin
;;         measure_errors = reform(1.d0/w8_source_in[ikid,wsample],nwsample)

         ;; Take sqrt to be homogeneous to stddev and not variance !
         ;; NP, Sept. 8th, 2020
         measure_errors = sqrt( reform(1.d0/w8_source_in[ikid,wsample],nwsample))
      endif
   endif else begin
      delvarx, measure_errors
      ;; wsample = where( off_source[ikid,*] eq 1 and finite(toi[ikid,*]) eq 1, nwsample)
      wsample = where( off_source[ikid,*] eq 1 and finite(toi[ikid,*]) eq 1 and flag[ikid,*] eq 0, nwsample)
   endelse
   if nwsample lt param.nsample_min_per_subscan then begin
      ;; do not project this subscan for this kid
      flag[ikid,*] = 2L^7
   endif else begin     
      ;; Regress the templates and the data off source
      coeff = regress( templates[*,wsample], reform( toi[ikid,wsample]), $
                       CHISQ= chi, CONST= const, CORRELATION= corr, measure_errors=measure_errors, $
                       /DOUBLE, FTEST=ftest, MCORRELATION=mcorr, SIGMA=sigma, STATUS=status)

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
         if tag_exist(kidpar, 'corr2cm') then kidpar[ikid].corr2cm = coeff[1 < (n_elements(coeff)-1)] ; hardcoded for a test
      endif else begin
; FXD replaced
                                ;stop
         ; by just this message
;         if param.silent eq 0 then message, /info, param.scan+ $
;                  ' No fit obtained for that kid '+strtrim(ikid, 2)
         ;; do not project
         flag[ikid,*] = 2L^7
      endelse

   endelse
endfor

;; Comment out the cpu time estimation because this routine is called
;; too many times.
;; if param.cpu_time then nk_show_cpu_time, param

end
