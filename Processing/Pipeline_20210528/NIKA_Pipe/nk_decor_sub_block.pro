;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_decor_sub_block
;
; CATEGORY: toi processing
;
; CALLING SEQUENCE:
;         nk_decor_sub_block, param, info, data, kidpar
; 
; PURPOSE: 
;        Decorrelates kids. compute a common mode per kid derived from the other
;kids that are most correlated  to it
; 
; INPUT: 
;        - param: the reduction parameters structure
;        - info: an information structure to be filled
;        - data: the NIKA general data structure
;        - kidpar: the NIKA general kid structure
; 
; OUTPUT: 
;        - data: 
; 
; KEYWORDS:
;        - sample_index: the sample nums absolute values
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Nov 21st, 2014: creation (Nicolas Ponthieu & Remi Adam - adam@lpsc.in2p3.fr)
;-

pro nk_decor_sub_block, param, info, data, kidpar, $
                        sample_index=sample_index, w1mm=w1mm, w2mm=w2mm, $
                        out_temp_data=out_temp_data, isubscan=isubscan

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   return
endif

;; sanity checks  
if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

nsn = n_elements(data)
if not keyword_set(sample_index) then sample_index = lindgen( nsn)
nwsample = n_elements( sample_index)
if nwsample ne nsn then begin
   nk_error, info, "sample_index and data have incompatible sizes"
   return
endif

if param.decor_elevation and strupcase(info.obs_type) eq "LISSAJOUS" then begin
   nk_build_azel_templates, param, info, sample_index, azel_templates
endif

if info.polar ne 0 then begin
   out_temp_data = {toi:data[0].toi*0.d0, toi_q:data[0].toi_q*0.d0, toi_u:data[0].toi_u*0.d0}
endif else begin
   out_temp_data = {toi:data[0].toi*0.d0}
endelse
out_temp_data = replicate( out_temp_data, nsn)

;; 1mm
if w1mm[0] ne -1 then begin
   nk_get_cm_block, param, info, data.toi[w1mm], $
                    data.flag[w1mm], data.off_source[w1mm], kidpar[w1mm], common_mode_1mm, isubscan=isubscan, $
                    elev=data.el, ofs_el=data.ofs_el
   if info.polar ne 0 then begin
      nk_get_cm_block, param, info, data.toi_q[w1mm], $
                       data.flag[w1mm], data.off_source[w1mm], kidpar[w1mm], common_mode_1mm_q, isubscan=isubscan, $
                       elev=data.el, ofs_el=data.ofs_el
      nk_get_cm_block, param, info, data.toi_u[w1mm], $
                       data.flag[w1mm], data.off_source[w1mm], kidpar[w1mm], common_mode_1mm_u, isubscan=isubscan, $
                       elev=data.el, ofs_el=data.ofs_el
   endif
endif

;; 2mm
if w2mm[0] ne -1 then begin
   nk_get_cm_block, param, info, data.toi[w2mm], $
                    data.flag[w2mm], data.off_source[w2mm], kidpar[w2mm], common_mode_2mm, isubscan=isubscan, $
                    elev=data.el, ofs_el=data.ofs_el
   if info.polar ne 0 then begin
      nk_get_cm_block, param, info, data.toi_q[w2mm], $
                       data.flag[w2mm], data.off_source[w2mm], kidpar[w2mm], common_mode_2mm_q, isubscan=isubscan, $
                       elev=data.el, ofs_el=data.ofs_el
      nk_get_cm_block, param, info, data.toi_u[w2mm], $
                       data.flag[w2mm], data.off_source[w2mm], kidpar[w2mm], common_mode_2mm_u, isubscan=isubscan, $
                       elev=data.el, ofs_el=data.ofs_el
   endif
endif

;; Add azimuth and elevation templates to the decorrelation if requested
if param.decor_elevation and strupcase(info.obs_type) eq "LISSAJOUS" then begin
   templates = dblarr( 1 + 4*param.n_harmonics_azel, nsn)
   templates[1:*,*] = azel_templates
endif else begin
   templates = dblarr(1,nsn)
endelse

;; Decorrelate 1mm
if w1mm[0] ne -1 then begin
   nw1mm=n_elements(w1mm)
   for i=0, nw1mm-1 do begin
      ikid = w1mm[i]
      templates[0,*] = common_mode_1mm[i,*]
      
      wsample = where( data.off_source[ikid] eq 1 and data.flag[ikid] eq 0, nwsample)
      if nwsample lt param.nsample_min_per_subscan then begin
         ;; do not project this subscan for this kid
         data.flag[ikid] = 1
      endif else begin

         ;; Regress the templates and the data off source
         coeff = regress( templates[*,wsample], reform( data[wsample].toi[ikid]), $
                          CHISQ= chi, CONST= const, CORRELATION= corr, $
                          /DOUBLE, FTEST=ftest, MCORRELATION=mcorr, SIGMA=sigma, STATUS=status)
               
         ;; Subtract the templates everywhere
         yfit = dblarr(nsn) + const
         for ii=0, n_elements(coeff)-1 do yfit += coeff[ii]*templates[ii,*]
         data.toi[ikid] -= yfit
         if keyword_set(out_temp_data) then out_temp_data.toi[ikid] = yfit
      endelse
   endfor
endif

;; Decorrelate 2mm
if w2mm[0] ne -1 then begin
   nw2mm = n_elements(w2mm)
   for i=0, nw2mm-1 do begin
      ikid = w2mm[i]
      templates[0,*] = common_mode_2mm[i,*]
      
      wsample = where( data.off_source[ikid] eq 1 and data.flag[ikid] eq 0, nwsample)
      if nwsample lt param.nsample_min_per_subscan then begin
         ;; do not project this subscan for this kid
         data.flag[ikid] = 1
      endif else begin

         ;; Regress the templates and the data off source
         coeff = regress( templates[*,wsample], reform( data[wsample].toi[ikid]), $
                          CHISQ= chi, CONST= const, CORRELATION= corr, $
                          /DOUBLE, FTEST=ftest, MCORRELATION=mcorr, SIGMA=sigma, STATUS=status)
               
         ;; Subtract the templates everywhere
         yfit = dblarr(nsn) + const
         for ii=0, n_elements(coeff)-1 do yfit += coeff[ii]*templates[ii,*]
         data.toi[ikid] -= yfit
         if keyword_set(out_temp_data) then out_temp_data.toi[ikid] = yfit
      endelse
   endfor
endif

;;==============================================================================================
;; Fourier filter
if param.bandpass ne 0 then begin
   ;; Init
   np_bandpass, data.toi[0], !nika.f_sampling, s_out, $
                freqlow=param.freqlow, freqhigh=param.freqhigh, filter=filter
   ;; Filter all kids
   for ikid=0, n_elements(kidpar)-1 do begin
      if kidpar[ikid].type ne 2 then begin
         np_bandpass, data.toi[ikid]-my_baseline(data.toi[ikid]), !nika.f_sampling, s_out, filter=filter
         data.toi[ikid] = s_out

         if info.polar ne 0 then begin
            np_bandpass, data.toi_q[ikid]-my_baseline(data.toi_q[ikid]), !nika.f_sampling, s_out, filter=filter
            data.toi_q[ikid] = s_out
            np_bandpass, data.toi_u[ikid]-my_baseline(data.toi_u[ikid]), !nika.f_sampling, s_out, filter=filter
            data.toi_u[ikid] = s_out
         endif
      endif
   endfor
endif

;;==============================================================================================
;; Polynomial subtraction
if param.polynomial ne 0 then begin
   for lambda=1, 2 do begin
      nk_list_kids, kidpar, lambda=lambda, valid=w1, nvalid=nw1
      if nw1 ne 0 then begin
         index = dindgen( n_elements(data))
         for i=0, nw1-1 do begin
            ikid = w1[i]
            wfit = where( data.flag[ikid] eq 0 and data.off_source[ikid] eq 1, nind)
            if nind eq 0 then begin
;               nk_error, info, "not enough point to subtract a polynomial for kid "+strtrim(ikid,2)
;               return
            endif else begin
               r = poly_fit( index[wfit], data[wfit].toi[ikid], param.polynomial)
               yfit = index*0.d0
               for ii=0, n_elements(r)-1 do yfit += r[ii]*index^ii
               data.toi[ikid] -= yfit

               if info.polar ne 0 then begin
                  r = poly_fit( index[wfit], data[wfit].toi_q[ikid], param.polynomial)
                  yfit = index*0.d0
                  for ii=0, n_elements(r)-1 do yfit += r[ii]*index^ii
                  data.toi_q[ikid] -= yfit

                  r = poly_fit( index[wfit], data[wfit].toi_u[ikid], param.polynomial)
                  yfit = index*0.d0
                  for ii=0, n_elements(r)-1 do yfit += r[ii]*index^ii
                  data.toi_u[ikid] -= yfit
               endif
            endelse
         endfor
      endif
   endfor
endif

end
