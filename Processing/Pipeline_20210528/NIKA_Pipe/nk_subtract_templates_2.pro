;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_subtract_templates_2
;
; CATEGORY: toi processing
;
; CALLING SEQUENCE:
;         nk_subtract_templates_2, param, info, data, kidpar, wsample, common_mode
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
;-
;=================================================================================================

pro nk_subtract_templates_2, param, info, data, kidpar, $
                             templates_1mm=templates_1mm, templates_2mm=templates_2mm, $
                             q=q, u=u, out_temp_data=out_temp_data

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_subtract_templates_2, param, info, data, kidpar, $"
   print, "                         templates_1mm=templates_1mm, templates_2mm=templates_2mm, $"
   print, "                         q=q, u=u, out_temp_data=out_temp_data"
   return
endif

if info.status eq 1 then begin
   if param.silent eq 0 then    message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

;if param.cpu_time then param.cpu_t0 = systime(0, /sec)

nsn = n_elements(data)

do_i = 1
if keyword_set(q) then do_i = 0
if keyword_set(u) then do_i = 0

for lambda=1, 2 do begin
   nk_list_kids, kidpar, lambda=lambda, valid=w1, nvalid=nw1
   
   if nw1 ne 0 then begin
      ;; Sanity checks
      if lambda eq 1 and not keyword_set(templates_1mm) then begin
         nk_error, info, "Please provide templates_1mm in input"
         return
      endif
      if lambda eq 2 and not keyword_set(templates_2mm) then begin
         nk_error, info, "Please provide templates_2mm in input"
         return
      endif

      if lambda eq 1 then templates = templates_1mm else templates = templates_2mm

      ;; Ensure that "templates" has the correct form for REGRESS
      s = size(templates)
      if s[0] eq 1 then begin
         templates = reform( templates, [1,nsn])
         s = size(templates)
      endif

      ;; Use arrays to speed things up
      off_source = data.off_source
      flag       = data.flag
      toi        = data.toi
      if keyword_set(q) then toi_q = data.toi_q
      if keyword_set(u) then toi_u = data.toi_u

      ;; Perform the REGRESS
      for i=0, nw1-1 do begin
         ikid  = w1[i]
         ;message, /info, "fix me:"
         ;if ikid eq 92 then stop

         ;; Determine valid samples for the regress
         ;;wsample  = where( data.off_source[ikid] eq 1 and data.flag[ikid] eq 0, nwsample)
         ;;wsample = where( off_source[ikid,*] eq 1 and flag[ikid,*] eq 0,
         ;;nwsample)
         
         ;; flagged data have either been interpolated and are safe or are due
         ;; to uncertain pointing between subscans, but this does not affect their temporal correlation
         wsample = where( off_source[ikid,*] eq 1, nwsample)
         if nwsample lt param.nsample_min_per_subscan then begin
            ;; do not project this subscan for this kid
            data.flag[ikid] = 1
         endif else begin

            ;; Regress the templates and the data off source
            ;; test on do_i and keywords to avoid a duplication of the timeline and
            ;; save time and memory...
            if do_i eq 1 then begin
               coeff = regress( templates[*,wsample], reform( toi[ikid,wsample]), $
                                CHISQ= chi, CONST= const, CORRELATION= corr, $
                                /DOUBLE, FTEST=ftest, MCORRELATION=mcorr, SIGMA=sigma, STATUS=status)
               
               ;; Subtract the templates everywhere
               yfit = dblarr(nsn) + const
               for ii=0, n_elements(coeff)-1 do yfit += coeff[ii]*templates[ii,*]
               data.toi[ikid] -= yfit
               if keyword_set(out_temp_data) then out_temp_data.toi[ikid] = yfit
            endif
            if keyword_set(q) then begin
               coeff = regress( templates[*,wsample], reform( toi_q[ikid,wsample]), $
                                CHISQ= chi, CONST= const, CORRELATION= corr, $
                                /DOUBLE, FTEST=ftest, MCORRELATION=mcorr, SIGMA=sigma, STATUS=status)
               
               ;; Subtract the templates everywhere
               yfit = dblarr(nsn) + const
               for ii=0, n_elements(coeff)-1 do yfit += coeff[ii]*templates[ii,*]
               data.toi_q[ikid] -= yfit
               if keyword_set(out_temp_data) then out_temp_data.toi_q[ikid] = yfit
            endif
            if keyword_set(u) then begin
               coeff = regress( templates[*,wsample], reform( toi_u[ikid,wsample]), $
                                CHISQ= chi, CONST= const, CORRELATION= corr, $
                                /DOUBLE, FTEST=ftest, MCORRELATION=mcorr, SIGMA=sigma, STATUS=status)
               
               ;; Subtract the templates everywhere
               yfit = dblarr(nsn) + const
               for ii=0, n_elements(coeff)-1 do yfit += coeff[ii]*templates[ii,*]
               data.toi_u[ikid] -= yfit
               if keyword_set(out_temp_data) then out_temp_data.toi_u[ikid] = yfit
            endif
         endelse
      endfor

   endif
endfor

;if param.cpu_time then nk_show_cpu_time, param, "nk_subtract_templates_2"
end
