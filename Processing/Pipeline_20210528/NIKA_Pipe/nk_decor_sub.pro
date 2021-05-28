;+
;
; SOFTWARE: NIKA pipeline
;
; NAME:
; nk_decor_sub
;
; CATEGORY: toi processing
;
; CALLING SEQUENCE:
;         nk_decor_sub, param, info, data, kidpar
; 
; PURPOSE: 
;        Decorrelates kids, filters...
;        This is the core of nk_decor.pro that only dispatches per_subscan or not
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
;        - April 09th, 2014: creation (Nicolas Ponthieu & Remi Adam - adam@lpsc.in2p3.fr)
;-

pro nk_decor_sub, param, info, data, kidpar, $
                  sample_index=sample_index, w1mm=w1mm, w2mm=w2mm, $
                  out_temp_data=out_temp_data, $
                  input_cm_1mm=input_cm_1mm, input_cm_2mm=input_cm_2mm

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_decor, param, info, data, kidpar, sample_index=sample_index, w1mm=w1mm, w2mm=w2mm"
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

;;====================================================================================================
;; Select which decorrelation method must be applied
do_1_common_mode      = 0
do_multi_common_modes = 0
case strupcase(param.decor_method) of

   ;;----------------------------------------------------------------------------------
   ;; 1. No decorrelation
   "NONE": begin
   end

   ;;----------------------------------------------------------------------------------
   ;; 2. Simple commmon mode, one per lambda
   "COMMON_MODE":begin
      ;; keep all valid samples, even on source => modify data.off_source
      data.off_source  = 1.d0
      do_1_common_mode = 1
   end
   
   ;;----------------------------------------------------------------------------------
   ;; 3. Common mode with KIDs OFF source, one per lambda
   "COMMON_MODE_KIDS_OUT":begin
      ;; leave data.off_source untouched, precisely to know whether kids are on
      ;; or off source.
      do_1_common_mode = 1
   end
   
   ;;----------------------------------------------------------------------------------
   ;; 4. One common mode per electronic band, no source mask
   "COMMON_MODE_BAND_NO_MASK":begin
      ;; keep all valid samples, even on source => modify data.off_source
      data.off_source       = 1.d0
      do_multi_common_modes = 1
   end
   
   ;;----------------------------------------------------------------------------------
   ;; 5. One common mode per electronic band computed far from the source
   "COMMON_MODE_BAND_MASK":begin
      ;; leave data.off_source untourched
      do_multi_common_modes = 1
   end

   ;;----------------------------------------------------------------------------------
   ;; 6. Subtract the 1mm common mode to the 2mm timelines.
   ;; WARNING: the 1mm common mode is computed on the whole map, but regressed
   ;; only outside the mask when subtracted from the 2mm.
   "DUAL_BAND_DEC":begin
      ;; leave data.off_source untourched
      do_1_common_mode = 1
   end

   ELSE: begin
      nk_error, info, "Unrecognized decorelation method: "+param.decor_method
      return
   end
endcase

;; if requested, discard kids (locally) that spend too much time on source and
;; will therefore give poor contribution to the common mode and will be badly decorrelated.
if param.max_on_source_frac ne 0 then begin
;   kidpar_copy = kidpar
   w = where( kidpar.type eq 1, nw)
   for i=0, nw-1 do begin
      ikid = w[i]
      ;; if total( data.off_source[ikid])/nsn lt (1-param.max_on_source_frac) then kidpar.type = 3
      if total( data.off_source[ikid])/nsn lt (1-param.max_on_source_frac) then begin
         data.flag[ikid] = 1
         print, "ikid "+strtrim(ikid,2)+" spends more than "+strtrim(param.max_on_source_frac,2)+" of its time on the mask."
      endif
   endfor
endif


if keyword_set(input_cm_1mm) and keyword_set(input_cm_2mm) then begin
   if info.polar ne 0 then begin
      nk_error, info, "input_cm not implemented for polarization yet"
      return
   endif
   templates_1mm = input_cm_1mm
   templates_2mm = input_cm_2mm
   n_cm_2mm = 1
   n_cm_1mm = 1

endif else begin

;;-------------------------------------
   if do_1_common_mode then begin
      ;; compute common mode off source

      ;; Intensity
      if w1mm[0] ne -1 then begin
         
         ;;compute the 1mm common mode on the entire map if "dual_band_dec"
         ;;but preserve "off source" information for the regress in nk_subtract_templates
         if strupcase(param.decor_method) eq "DUAL_BAND_DEC" then begin
            off_source_1mm = data.off_source[w1mm]*0.d0 + 1.d0
         endif else begin
            off_source_1mm = data.off_source[w1mm]
         endelse

         ;;nk_get_cm_sub_2, param, info, data.toi[w1mm], data.flag[w1mm], data.off_source[w1mm], kidpar[w1mm], common_mode_1mm
         ;; nk_get_cm_sub_2, param, info, data.toi[w1mm], data.flag[w1mm],
         ;; off_source_1mm, kidpar[w1mm], common_mode_1mm

         ;; NP, June 10th, 2015:
         ;; flags are updated in case a kid gets infinite regress coefficients on
         ;; the common mode.
         flag = data.flag[w1mm]
         nk_get_cm_sub_2, param, info, data.toi[w1mm], flag, off_source_1mm, kidpar[w1mm], common_mode_1mm
         data.flag[w1mm] = flag
         common_mode_1mm = reform( common_mode_1mm, 1, nsn)
      endif
      if w2mm[0] ne -1 then begin

         ;message, /info, "fix me:"
         ;if min(data.subscan) eq 16 then stop
         
         ;;nk_get_cm_sub_2, param, info, data.toi[w2mm], data.flag[w2mm], data.off_source[w2mm], kidpar[w2mm], common_mode_2mm
         flag = data.flag[w2mm]
         nk_get_cm_sub_2, param, info, data.toi[w2mm], flag, data.off_source[w2mm], kidpar[w2mm], common_mode_2mm
         data.flag[w2mm] = flag
         common_mode_2mm = reform( common_mode_2mm, 1, nsn)
      endif    

      if strupcase(param.decor_method) eq "DUAL_BAND_DEC" then common_mode_2mm = common_mode_1mm

      ;; Polarization
      if info.polar ne 0 then begin
         if w1mm[0] ne -1 then begin
            ;;nk_get_cm_sub_2, param, info, data.toi_q[w1mm], data.flag[w1mm], data.off_source[w1mm], kidpar[w1mm], common_mode_1mm_q
            flag = data.flag[w1mm]
            nk_get_cm_sub_2, param, info, data.toi_q[w1mm], flag, data.off_source[w1mm], kidpar[w1mm], common_mode_1mm_q
            common_mode_1mm_q = reform( common_mode_1mm_q, 1, nsn)

            ;;nk_get_cm_sub_2, param, info, data.toi_u[w1mm], data.flag[w1mm], data.off_source[w1mm], kidpar[w1mm], common_mode_1mm_u
            nk_get_cm_sub_2, param, info, data.toi_u[w1mm], flag, data.off_source[w1mm], kidpar[w1mm], common_mode_1mm_u
            data.flag[w1mm] = flag
            common_mode_1mm_u = reform( common_mode_1mm_u, 1, nsn)
         endif
         if w2mm[0] ne -1 then begin
            ;;nk_get_cm_sub_2, param, info, data.toi_q[w2mm], data.flag[w2mm], data.off_source[w2mm], kidpar[w2mm], common_mode_2mm_q
            flag = data.flag[w2mm]
            nk_get_cm_sub_2, param, info, data.toi_q[w2mm], flag, data.off_source[w2mm], kidpar[w2mm], common_mode_2mm_q
            common_mode_2mm_q = reform( common_mode_2mm_q, 1, nsn)
            ;;nk_get_cm_sub_2, param, info, data.toi_u[w2mm], data.flag[w2mm], data.off_source[w2mm], kidpar[w2mm], common_mode_2mm_u
            nk_get_cm_sub_2, param, info, data.toi_u[w2mm], flag, data.off_source[w2mm], kidpar[w2mm], common_mode_2mm_u
            data.flag[w2mm] = flag
            common_mode_2mm_u = reform( common_mode_2mm_u, 1, nsn)
         endif
;;      if strupcase(param.decor_method) eq "DUAL_BAND_DEC" then begin
;;         common_mode_2mm_q = common_mode_1mm_q
;;         common_mode_2mm_u = common_mode_1mm_u
;;      endif
      endif

      n_cm_1mm = 1
      n_cm_2mm = 1
   endif

;;========================================================================================================
   if do_multi_common_modes then begin
      ;;----------------------------------------------
      ;; Common modes per instrumental electronic band
      if strupcase(param.decor_method) eq "COMMON_MODE_BAND_NO_MASK" or $
         strupcase(param.decor_method) eq "COMMON_MODE_BAND_MASK" then begin
         if w1mm[0] ne -1 then begin
            nk_get_common_mode_band, param, info, kidpar[w1mm], data.toi[w1mm], $
                                     data.flag[w1mm], data.off_source[w1mm], common_mode_1mm
            if info.polar ne 0 then begin
               nk_get_common_mode_band, param, info, kidpar[w1mm], data.toi_q[w1mm], $
                                        data.flag[w1mm], data.off_source[w1mm], common_mode_1mm_q
               nk_get_common_mode_band, param, info, kidpar[w1mm], data.toi_u[w1mm], $
                                        data.flag[w1mm], data.off_source[w1mm], common_mode_1mm_u
            endif
            n_cm_1mm = n_elements( common_mode_1mm[*,0])
         endif

         if w2mm[0] ne -1 then begin
            nk_get_common_mode_band, param, info, kidpar[w2mm], data.toi[w2mm], $
                                     data.flag[w2mm], data.off_source[w2mm], common_mode_2mm
            if info.polar ne 0 then begin
               nk_get_common_mode_band, param, info, kidpar[w2mm], data.toi_q[w2mm], $
                                        data.flag[w2mm], data.off_source[w2mm], common_mode_2mm_q
               nk_get_common_mode_band, param, info, kidpar[w2mm], data.toi_u[w2mm], $
                                        data.flag[w2mm], data.off_source[w2mm], common_mode_2mm_u
            endif
            n_cm_2mm = n_elements( common_mode_2mm[*,0])
         endif
      endif
   endif

endelse

;;-----------------------------------------------------------------------------
;; Add azimuth and elevation templates to the decorrelation if requested
if (param.decor_elevation eq 1) and (param.lab eq 0) then begin
   if strupcase(info.obs_type) eq "LISSAJOUS" then begin
      
      if w1mm[0] ne -1 then begin
         templates_1mm = dblarr( n_cm_1mm + 4*param.n_harmonics_azel, nsn)
         for i=0, n_cm_1mm-1 do begin
            templates_1mm[i,*] = common_mode_1mm[i,*]
         endfor
         templates_1mm[n_cm_1mm:*,*] = azel_templates
      endif
      
      if w2mm[0] ne -1 then begin
         templates_2mm = dblarr( n_cm_2mm + 4*param.n_harmonics_azel, nsn)
         for i=0, n_cm_2mm-1 do begin
            templates_2mm[i,*] = common_mode_2mm[i,*]
         endfor
         templates_2mm[n_cm_2mm:*,*] = azel_templates
      endif
   endif else begin ; otf etc...
      if w1mm[0] ne -1 then begin
         templates_1mm = dblarr( n_cm_1mm + 1, nsn)
         for i=0, n_cm_1mm-1 do begin
            templates_1mm[i,*] = common_mode_1mm[i,*]
         endfor
         templates_1mm[n_cm_1mm,*] = data.el
      endif
      
      if w2mm[0] ne -1 then begin
         templates_2mm = dblarr( n_cm_2mm + 1, nsn)
         for i=0, n_cm_2mm-1 do begin
            templates_2mm[i,*] = common_mode_2mm[i,*]
         endfor
         templates_2mm[n_cm_2mm,*] = data.el
      endif

   endelse

endif else begin
   if defined(common_mode_1mm) then templates_1mm = common_mode_1mm
   if defined(common_mode_2mm) then templates_2mm = common_mode_2mm
endelse

if param.decor_accel eq 1 then begin

   speed        = sqrt( deriv(data.ofs_az)^2 + deriv(data.ofs_el)^2)
   acceleration = deriv(speed)
stop
   if w1mm[0] ne -1 then begin
      tt = templates_1mm
      nt = n_elements(templates_1mm[*,0])
      templates_1mm = dblarr( nt+1, nsn)
      for i=0, nt-1 do begin
         templates_1mm[i,*] = tt[i,*]
      endfor
      templates_1mm[nt,*] = acceleration
   endif

   if w2mm[0] ne -1 then begin
      tt = templates_2mm
      nt = n_elements(templates_2mm[*,0])
      templates_2mm = dblarr( nt+1, nsn)
      for i=0, nt-1 do begin
         templates_2mm[i,*] = tt[i,*]
      endfor
      templates_2mm[nt,*] = acceleration
   endif
endif
;;------------------------------------------------------------------------------
;; Perform decorrelation on I
;if defined(templates_1mm) eq 0 or defined(templates_2mm) eq 0 then stop

nk_subtract_templates_2, param, info, data, kidpar, $
                         templates_1mm=templates_1mm, templates_2mm=templates_2mm, $
                         out_temp_data=out_temp_data


;; nw1mm = n_elements(w1mm)
;; make_ct, nw1mm, ct
;; wind, 1, 1, /free
;; !p.multi=[0,1,2]
;; for i=0, nw1mm-1 do begin
;;    ikid = w1mm[i]
;;    plot, data1.toi[ikid], /xs, title="kid "+strtrim(ikid,2)+", subscan "+strtrim(data1[0].subscan,2)
;;    oplot, out_temp_data.toi[ikid], col=250
;;    plot, data1.toi[ikid]-out_temp_data.toi[ikid]
;;    cont_plot, nostop=nostop
;; endfor
;; stop

;; Perform decorrelation on Q and U
if info.polar ne 0 then begin
   if param.decor_elevation and strupcase(info.obs_type) eq "LISSAJOUS" then begin

      if w1mm[0] ne -1 then begin
         templates_1mm_q = dblarr( n_cm_1mm + 4*param.n_harmonics_azel, nsn)
         templates_1mm_u = dblarr( n_cm_1mm + 4*param.n_harmonics_azel, nsn)
         for i=0, n_cm_1mm-1 do begin
            templates_1mm_q[i,*] = common_mode_1mm_q[i,*]
            templates_1mm_u[i,*] = common_mode_1mm_u[i,*]
         endfor
         templates_1mm_q[n_cm_1mm:*,*] = azel_templates
         templates_1mm_u[n_cm_1mm:*,*] = azel_templates
      endif
      
      if w2mm[0] ne -1 then begin
         templates_2mm_q = dblarr( n_cm_2mm + 4*param.n_harmonics_azel, nsn)
         templates_2mm_u = dblarr( n_cm_2mm + 4*param.n_harmonics_azel, nsn)
         for i=0, n_cm_2mm-1 do begin
            templates_2mm_q[i,*] = common_mode_2mm_q[i,*]
            templates_2mm_u[i,*] = common_mode_2mm_u[i,*]
         endfor
         templates_2mm_q[n_cm_2mm:*,*] = azel_templates
         templates_2mm_u[n_cm_2mm:*,*] = azel_templates
      endif
      
   endif else begin
      if defined(common_mode_1mm_q) then templates_1mm_q = common_mode_1mm_q
      if defined(common_mode_1mm_u) then templates_1mm_u = common_mode_1mm_u
      if defined(common_mode_2mm_q) then templates_2mm_q = common_mode_2mm_q
      if defined(common_mode_2mm_u) then templates_2mm_u = common_mode_2mm_u
   endelse

   nk_subtract_templates_2, param, info, data, kidpar, /Q, $
                          templates_1mm=templates_1mm_q, templates_2mm=templates_2mm_q, $
                          out_temp_data=out_temp_data_q
   nk_subtract_templates_2, param, info, data, kidpar, /U, $
                          templates_1mm=templates_1mm_u, templates_2mm=templates_2mm_u, $
                          out_temp_data=out_temp_data_u
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
               r = poly_fit( index[wfit], data[wfit].toi[ikid], $
                             param.polynomial,  status = status)
               
               yfit = index*0.d0
               if status eq 0 then $
                  for ii=0, n_elements(r)-1 do yfit += r[ii]*index^ii
               data.toi[ikid] -= yfit

               if info.polar ne 0 then begin
                  r = poly_fit( index[wfit], data[wfit].toi_q[ikid], $
                                param.polynomial,  status = status)
                  yfit = index*0.d0
                  if status eq 0 then $
                     for ii=0, n_elements(r)-1 do yfit += r[ii]*index^ii
                  data.toi_q[ikid] -= yfit

                  r = poly_fit( index[wfit], data[wfit].toi_u[ikid], $
                                param.polynomial, status = status)
                  yfit = index*0.d0
                  if status eq 0 then $
                     for ii=0, n_elements(r)-1 do yfit += r[ii]*index^ii
                  data.toi_u[ikid] -= yfit
               endif
            endelse
         endfor
      endif
   endfor
endif

end
