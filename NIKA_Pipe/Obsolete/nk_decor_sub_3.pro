;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_decor_sub_3
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

pro nk_decor_sub_3, param, info, data, kidpar, $
                    sample_index=sample_index, w1mm=w1mm, w2mm=w2mm, $
                    out_temp_data=out_temp_data, kid_corr_block=kid_corr_block

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_decor_sub_3, param, info, data, kidpar, $"
   print, "                sample_index=sample_index, w1mm=w1mm, w2mm=w2mm, $"
   print, "                out_temp_data=out_temp_data"
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
      ;; leave data.off_source untouched
      do_multi_common_modes = 1
   end

   ;;----------------------------------------------------------------------------------
   ;; 6. Determine blocks of maximally correlated kids to compute a common mode
   ;; per such block. (outside the source)
   "COMMON_MODE_ONE_BLOCK":begin
      ;; leave data.off_source untouched and leave do_1_common_mode and
      ;; do_multi_common_modes to 0.
   end

   ELSE: begin
      nk_error, info, "Unrecognized decorelation method: "+param.decor_method
      return
   end
endcase

if strupcase(param.decor_method) eq "COMMON_MODE_ONE_BLOCK" then begin
   
;;--------------------------
   message, /info, "fix me: remove all this"
   atm_x_calib = nika_pipe_atmxcalib(data.toi, 1-data.off_source)
   mcorr = correlate(data.toi)
   wnan = where(finite(mcorr) ne 1, nwnan)
   if nwnan ne 0 then mcorr[wnan] = -1
   nkids = n_elements(kidpar)
   score = intarr( nkids, nkids) ; nombre de fois ou un kid est correle au kid courant
;;----------------------------
         
   for lambda=1, 2 do begin
      if lambda eq 1 then w1 = w1mm else w1 = w2mm
      
      if w1[0] ne -1 then begin
         nw1 = n_elements(w1)

         ;; Estimate the median common mode with all valid kids like remi, not
         ;; only those of the maximally correlated block
         median_common_mode = median( data.toi[w1], dim=1)

         for i=0, nw1-1 do begin
            ikid = w1[i]
            
            ;;-------------------------------------------------------
            ;; Compare my block computed on the entire scan to the one
            ;; computed scan by scan a la Remi.
            
            corr = reform(mcorr[ikid,*])
            wbad = where(kidpar.type ne 1 or kidpar.array ne kidpar[ikid].array, nwbad) ; Force rejected KIDs not to be correlated
            if nwbad ne 0 then corr[wbad] = -1
            s_corr = corr[reverse(sort(corr))] ;Sorted by best correlation                                                            
   
            ;;First block with the min number of KIDs allowed                                                                          
            block = where(corr gt s_corr[param.n_corr_block_min+1] and corr ne 1, nblock)
            ;;Then add KIDs and test if correlated enough                                                                             
            sd_block = stddev(corr[block])
            mean_block = mean(corr[block])

            iter = 1            ; 2
            test = 'ok'
            while test eq 'ok' and (param.n_corr_block_min+iter) lt nw1-2 do begin
               if s_corr[param.n_corr_block_min+iter] lt mean_block-param.nsigma_corr_block*sd_block $
               then test = 'pas_ok' $
               else block = where(corr gt s_corr[param.n_corr_block_min+iter] and corr ne 1, nblock)
               iter += 1
            endwhile

            block_remi = block
            score[ikid,block_remi] += 1

            ;;-------------------------------------------------------

            ;wb = where( kid_corr_block[ikid,*] ne -1, nblock)
            ;block = reform(kid_corr_block[ikid,wb])
            ;print, "block_remi numdet: ", kidpar[block_remi].numdet
            ;print, "block numdet:      ", kidpar[block].numdet

            ;; nk_get_cm_sub_2, param, info, data.toi[block], data.flag[block], $
            ;;                  data.off_source[block], kidpar[block],
                                      ;;                  common_mode
            
            ;nk_get_cm_sub_3, param, info, data.toi[block], data.flag[block], $
            ;                 data.off_source[block], kidpar[block], common_mode, coeffs, $
            ;                 median_common_mode=median_common_mode
;            stop

            hit_b = lonarr(nsn) ;Number of hit in the block common mode timeline                                             
            common_mode = dblarr(nsn)  ;Block common mode ignoring the source                                                       
            for j=0, nblock-1 do begin
               common_mode += (atm_x_calib[block[j],0] + atm_x_calib[block[j],1]*data.toi[block[j]]) * data.off_source[block[j]]
               hit_b += data.off_source[block[j],*]
            endfor
            loc_hit_b = where(hit_b ge 1, nloc_hit_b, COMPLEMENT=loc_no_hit_b, ncompl=nloc_no_hit_b)
            if nloc_hit_b ne 0 then common_mode[loc_hit_b] = common_mode[loc_hit_b]/hit_b[loc_hit_b]
            if nloc_no_hit_b ne 0 then common_mode[loc_no_hit_b] = !values.f_nan
            if nloc_no_hit_b ne 0 then begin
               if nloc_hit_b eq 0 then message, 'You need to reduce param.decor.common_mode.d_min. ' + $
                                                'It is so large that not even a single KID used in the ' + $
                                                'common-mode can be assumed be off-source'
               warning = 'yes'
               indice = dindgen(nsn)
               common_mode = interpol(common_mode[loc_hit_b], indice[loc_hit_b], indice, /quadratic)
            endif

            if param.decor_elevation and strupcase(info.obs_type) eq "LISSAJOUS" then begin
               templates        = dblarr( 1 + 4*param.n_harmonics_azel, nsn)
               templates[0,*]   = common_mode
               templates[1:*,*] = azel_templates
            endif else begin
               ;; Ensure that templates as the correct form for regress
               s = size( common_mode)
               if s[0] eq 1 then templates = reform( common_mode, [1, nsn])
            endelse

            ;; Determine valid samples for the regress
            wsample = where( data.off_source[ikid] eq 1, nwsample)
            if nwsample lt param.nsample_min_per_subscan then begin
               ;; do not project this subscan for this kid
               data.flag[ikid] = 1
            endif else begin

               ;; Regress the templates and the data off source
               coeff = regress( templates[*,wsample], reform( data[wsample].toi[ikid]), $
                                CONST= const, /DOUBLE, STATUS=status)
               
               ;; Subtract the templates everywhere
               yfit = dblarr(nsn) + const
               for ii=0, n_elements(coeff)-1 do yfit += coeff[ii]*templates[ii,*]
               data.toi[ikid] -= yfit
               if keyword_set(out_temp_data) then out_temp_data.toi[ikid] = yfit
            endelse
         endfor
      endif
   endfor


endif else begin
   ;; Regress all kids on the same common modes

;;-------------------------------------
   if do_1_common_mode then begin
      ;; compute common mode off source

      ;; Intensity
      if w1mm[0] ne -1 then begin
         nk_get_cm_sub_2, param, info, data.toi[w1mm], data.flag[w1mm], data.off_source[w1mm], kidpar[w1mm], common_mode_1mm
         common_mode_1mm = reform( common_mode_1mm, 1, nsn)
         n_cm_1mm = 1
      endif
      if w2mm[0] ne -1 then begin
         nk_get_cm_sub_2, param, info, data.toi[w2mm], data.flag[w2mm], data.off_source[w2mm], kidpar[w2mm], common_mode_2mm
         common_mode_2mm = reform( common_mode_2mm, 1, nsn)
         n_cm_2mm = 1
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

;;-----------------------------------------------------------------------------
;; Add azimuth and elevation templates to the decorrelation if requested
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



;; Decorrelate all kids from the same template(s)

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
endelse

end
