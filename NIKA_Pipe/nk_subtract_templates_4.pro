;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_subtract_templates_4
;
; CATEGORY: toi processing
;
; CALLING SEQUENCE:
;         nk_subtract_templates_4, param, info, toi, flag, off_source,
;                                  kidpar, templates, out_temp, out_coeffs=out_coeffs
; 
; PURPOSE: 
;        Regress and subtract templates from data.toi.
;        like nk_subtracte_templates_3, but accounts for NaN's
;        in templates as well
; 
; INPUT: 
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
;        - NP Feb. 25th, 2021
;
;=================================================================================================

pro nk_subtract_templates_4, param, info, toi, flag, off_source, kidpar, templates, out_temp, $
                             out_coeffs=out_coeffs, w8_source_in=w8_source_in, status=status
;-

if n_params() lt 1 then begin
   dl_unix, 'nk_subtract_templates_4'
   return
endif

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

;; init to NaN this time (/= nk_subtract_templates_3)
out_temp   = toi*0.d0 + !values.d_nan
out_coeffs = dblarr(n_elements(kidpar), templates_size[1] + 1) ; add 1 for the constant

;; Restrict to sections where all the templates are defined
template_samples = long( avg( finite(templates), 0))

;; Main loop
w1 = where( kidpar.type eq 1, nw1)
for i=0, nw1-1 do begin
   ikid  = w1[i]

   delvarx, measure_errors

   ;; Determine on which samples to regress
   wsample = where( off_source[ikid,*] eq 1 and $
                    finite(toi[ikid,*]) eq 1 and $
                    ;;flag[ikid,*] eq 0 and $
                    (flag[ikid,*] eq 0 or flag[ikid,*] eq 2L^11) and $
                    template_samples eq 1, nwsample)


   if param.mydebug eq 0418 then toi_copy = toi
   status = 1                   ; init to non zero by default to tell if the fit was not performed

   if nwsample lt param.nsample_min_per_subscan then begin
      ;; do not project this subscan for this kid
;      message, /info, "nwsample lt param.nsample_min_per_subscan for i="+strtrim(i,2)
;      print, "nwsample, nsample_min_per_subscan: ", nwsample, param.nsample_min_per_subscan
;      stop
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

         ;; Subtract everywhere I can, i.e where all templates are defined
         w = where( template_samples eq 1, nw, compl=w_undef, ncompl=nw_undef)
         toi[     ikid,w] -= yfit[w]
         out_temp[ikid,w]  = yfit[w]
         if nw_undef ne 0 then flag[ikid,w_undef] = 2L^7

;;         if param.mydebug eq 0418 then begin
;;            wind, 1, 1, /free, /large
;;            index = lindgen(nsn)
;;            my_multiplot, 1, 3, pp, pp1, /rev
;;            nt = n_elements( templates[*,0])
;;            make_ct, nt, ct
;;            plot, index, templates[0,*], /xs, /ys, position=pp1[0,*], $
;;                  yra=minmax(templates[where(finite(templates))]), /nodata, $
;;                  title='Templates, ikid '+strtrim(ikid,2)
;;            legendastro, psym=1, col=250, "wsample"
;;            for ii=0, nt-1 do begin
;;               oplot, index, templates[ii,*], col=ct[ii]
;;               oplot, index[wsample], templates[ii,wsample], col=ct[ii], psym=1, syms=0.5
;;            endfor
;;            
;;            plot,  index, toi_copy[ikid,*], /xs, /ys, position=pp1[1,*], /noerase
;;            loadct, 7
;;            oplot, index, off_source[ikid,*]*(max(toi_copy[ikid,*])-min(toi_copy[ikid,*]))*0.99 + min(toi[ikid,*]), col=200
;;            loadct, 39
;;            oplot, index[wsample], toi_copy[ikid,wsample], psym=1, syms=0.5, col=70
;;            oplot, index, yfit, col=200, thick=2
;;
;;            if nw_undef ne 0 then oplot, index[w_undef], toi_copy[ikid,w_undef], psym=1, syms=0.5, col=100
;;            wproj = where( flag[ikid,*] eq 0, nwproj)
;;            if nwproj ne 0 then oplot, [index[wproj]], [toi_copy[ikid,wproj]], psym=1, syms=0.5, col=150
;;            legendastro, ['toi', 'wsample', 'yfit', 'undef', 'proj'], $
;;                         col=[!p.color,70,200,100,150], /bottom
;;            loadct, 7 & legendastro, ['off_source'], col=200 & loadct, 39
;;
;;            x = [reform(toi_copy[ikid,*],nsn), reform(toi[ikid,*],nsn)]
;;            yra = minmax( x[where(finite(x))])
;;            plot, index, toi_copy[ikid,*], /xs, /ys, position=pp1[2,*], /noerase, yra=yra
;;            oplot, index, toi[ikid,*], col=250
;;            if nwproj ne 0 then oplot, [index[wproj]], [toi[ikid,wproj]], psym=1, syms=0.5, col=150
;;            legendastro, ['Toi in', 'Toi out', 'Proj'], col=[!p.color, 250, 150], /bottom
;;            stop
;;         endif
         
      endif else begin
         flag[ikid,*] = 2L^7
      endelse
   endelse
endfor


end
