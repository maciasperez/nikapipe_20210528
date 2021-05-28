;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_decor_sub_2
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

pro nk_decor_sub_2, param, info, data, kidpar, $
                    sample_index=sample_index, w1mm=w1mm, w2mm=w2mm, $
                    out_temp_data=out_temp_data
  
on_error, 2

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_decor_2, param, info, data, kidpar, sample_index=sample_index, w1mm=w1mm, w2mm=w2mm"
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

   ELSE: begin
      nk_error, info, "Unrecognized decorelation method: "+param.decor_method
      return
   end
endcase

;;-------------------------------------
if do_1_common_mode then begin
   ;; compute common mode off source

   ;; Intensity
   if w1mm[0] ne -1 then begin
      nk_get_cm_sub_2, param, info, data.toi[w1mm], data.flag[w1mm], data.off_source[w1mm], kidpar[w1mm], common_mode_1mm
      common_mode_1mm = reform( common_mode_1mm, 1, nsn)
   endif
   if w2mm[0] ne -1 then begin
      nk_get_cm_sub_2, param, info, data.toi[w2mm], data.flag[w2mm], data.off_source[w2mm], kidpar[w2mm], common_mode_2mm
      common_mode_2mm = reform( common_mode_2mm, 1, nsn)
   endif    

   ;; Polarization
   if info.polar ne 0 then begin
      if w1mm[0] ne -1 then begin
         nk_get_cm_sub_2, param, info, data.toi_q[w1mm], data.flag[w1mm], data.off_source[w1mm], kidpar[w1mm], common_mode_1mm_q
         common_mode_1mm_q = reform( common_mode_1mm_q, 1, nsn)
         nk_get_cm_sub_2, param, info, data.toi_u[w1mm], data.flag[w1mm], data.off_source[w1mm], kidpar[w1mm], common_mode_1mm_u
         common_mode_1mm_u = reform( common_mode_1mm_u, 1, nsn)
      endif
      if w2mm[0] ne -1 then begin
         nk_get_cm_sub_2, param, info, data.toi_q[w2mm], data.flag[w2mm], data.off_source[w2mm], kidpar[w2mm], common_mode_2mm_q
         common_mode_2mm_q = reform( common_mode_2mm_q, 1, nsn)
         nk_get_cm_sub_2, param, info, data.toi_u[w2mm], data.flag[w2mm], data.off_source[w2mm], kidpar[w2mm], common_mode_2mm_u
         common_mode_2mm_u = reform( common_mode_2mm_u, 1, nsn)
      endif      
   endif

   n_cm_1mm = 1
   n_cm_2mm = 1
endif

;;-------------------------------------
if do_multi_common_modes then begin

   if w1mm[0] ne -1 then begin
      block_value = long(kidpar[w1mm].numdet)/long(80)
      ;; some blocks may be empty, e.g. if kids have been flagged...
      n_cm_1mm = 0
      for iblock=min(block_value), max(block_value) do begin
         w = where( block_value eq iblock, nw)
         if nw ne 0 then n_cm_1mm++
      endfor
      
      ;; Compute one common mode per block
      common_mode_1mm = dblarr( n_cm_1mm, nsn)
      if info.polar ne 0 then begin
         common_mode_1mm_q = common_mode_1mm
         common_mode_1mm_u = common_mode_1mm
      endif
      icm = 0
      for iblock=min(block_value), max(block_value) do begin
         w = where( block_value eq iblock, nw)
         if nw ne 0 then begin
            nk_get_cm_sub_2, param, info, data.toi[w1mm[w]], data.flag[w1mm[w]], data.off_source[w1mm[w]], kidpar[w1mm[w]], cm
            common_mode_1mm[icm,*] = cm
            if info.polar ne 0 then begin
               nk_get_cm_sub_2, param, info, data.toi_q[w1mm[w]], data.flag[w1mm[w]], data.off_source[w1mm[w]], kidpar[w1mm[w]], cm_q
               common_mode_1mm_q[icm,*] = cm_q
               nk_get_cm_sub_2, param, info, data.toi_u[w1mm[w]], data.flag[w1mm[w]], data.off_source[w1mm[w]], kidpar[w1mm[w]], cm_u
               common_mode_1mm_u[icm,*] = cm_u
            endif

            icm++
         endif
      endfor
   endif

   if w2mm[0] ne -1 then begin
      block_value = long(kidpar[w2mm].numdet)/long(80)
      ;; some blocks may be empty, e.g. if kids have been flagged...
      n_cm_2mm = 0
      for iblock=min(block_value), max(block_value) do begin
         w = where( block_value eq iblock, nw)
         if nw ne 0 then n_cm_2mm++
      endfor
      
      ;; Compute one common mode per block
      common_mode_2mm = dblarr( n_cm_2mm, nsn)
      if info.polar ne 0 then begin
         common_mode_2mm_q = common_mode_2mm
         common_mode_2mm_u = common_mode_2mm
      endif
      icm = 0
      for iblock=min(block_value), max(block_value) do begin
         w = where( block_value eq iblock, nw)
         if nw ne 0 then begin
            nk_get_cm_sub_2, param, info, data.toi[w2mm[w]], data.flag[w2mm[w]], data.off_source[w2mm[w]], kidpar[w2mm[w]], cm
            common_mode_2mm[icm,*] = cm

            if info.polar ne 0 then begin
               nk_get_cm_sub_2, param, info, data.toi_q[w2mm[w]], data.flag[w2mm[w]], data.off_source[w2mm[w]], kidpar[w2mm[w]], cm_q
               common_mode_2mm_q[icm,*] = cm_q
               nk_get_cm_sub_2, param, info, data.toi_u[w2mm[w]], data.flag[w2mm[w]], data.off_source[w2mm[w]], kidpar[w2mm[w]], cm_u
               common_mode_2mm_u[icm,*] = cm_u
            endif

            icm++
         endif
      endfor
   endif
endif

;;-------------------------------------
if param.decor_elevation and strupcase(info.obs_type) eq "LISSAJOUS" then begin

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

endif else begin
   if defined(common_mode_1mm) then templates_1mm = common_mode_1mm
   if defined(common_mode_2mm) then templates_2mm = common_mode_2mm
endelse

;;-------------------------------------
;; Perform decorrelation on I

nk_subtract_templates_2, param, info, data, kidpar, $
                         templates_1mm=templates_1mm, templates_2mm=templates_2mm, $
                         out_temp_data=out_temp_data

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
