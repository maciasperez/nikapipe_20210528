;+
;
; SOFTWARE: NIKA pipeline
;
; NAME:
; nk_decor_common_block
;
; CATEGORY: toi processing
;
; CALLING SEQUENCE:
;
; PURPOSE: 
;        Decorrelate kids, filters...
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
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - April 09th, 2014: creation (Nicolas Ponthieu & Remi Adam - adam@lpsc.in2p3.fr)
;-

pro nk_decor, param, info, data, kidpar

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_decor, param, info, data, kidpar"
   return
endif

;; sanity checks  
if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

nkids = n_elements(kidpar)

;;-------------------------------------------------------------------------------------------
;; Select which decorrelation method must be applied
do_common_mode_subtraction = 0
case strupcase(param.decor_method) of

   ;; 1. No decorrelation
   "NONE": begin
      if param.silent ne 0 then message, /info, "No decorrelation"
   end

   ;; 2. Simple commmon mode, one per lambda
   "COMMON_MODE":begin
      if not param.silent then message, /info, "Simple common mode on the entire scan"

      ;; keep all valid samples, even on source => modify data.off_source
      data.off_source = 1.d0 ; long( data.flag eq 0)

      if strupcase(param.decor_per_subscan) eq "YES" then begin
         for i=(min(data.subscan)>1), max(data.subscan) do begin
            wsample = where( data.subscan eq i, nwsample)
            data_copy = data[wsample]
            nk_get_cm, param, info, data_copy, kidpar, common_mode
            nk_subtract_templates, param, info, data_copy, kidpar, common_mode[0,*], common_mode[1,*]
            data[wsample].toi = data_copy.toi
         endfor
      endif else begin          ; on the entire scan then
         nk_get_cm, param, info, data, kidpar, common_mode
         nk_subtract_templates, param, info, data, kidpar, common_mode[0,*], common_mode[1,*]
      endelse

   end
   
   ;; 3. Common mode with KIDs OFF source, one per lambda
   "COMMON_MODE_KIDS_OUT":begin
      if not param.silent then message, /info, "Common mode with KIDs outside the source"
      
      if strupcase(param.decor_per_subscan) eq "YES" then begin
         for i=(min(data.subscan)>1), max(data.subscan) do begin
            wsample = where( data.subscan eq i, nwsample)
            data_copy = data[wsample]
            nk_get_cm, param, info, data_copy, kidpar, common_mode
            nk_subtract_templates, param, info, data_copy, kidpar, common_mode[0,*], common_mode[1,*]
            data[wsample].toi = data_copy.toi
         endfor
      endif else begin          ; on the entire scan then
         nk_get_cm, param, info, data, kidpar, common_mode
         nk_subtract_templates, param, info, data, kidpar, common_mode[0,*], common_mode[1,*]
      endelse

   end

    ;; 4. For each kid, find the param.n_corr_bloc_min kids that are
    ;; the most correlated to it and use them to derive the common mode
    ;; off the source
    "COMMON_MODE_BLOCK":begin
       if not param.silent then message, /info, "Common mode block"
 
       ;; I use all kids at both wavelengths indifferently on pupose,
       ;; to try a more pragmatic approach
       nsn = n_elements( data)
       w1 = where( kidpar.type eq 1, nw1)
       
       ;; Kids correlation matrix
       ;; Take the entire set of kids for an easier
       ;; handle of kid numbers
       mcorr = correlate(data.toi)

       ;; Main loop
       for i=0, nw1-1 do begin
          ikid = w1[i]
                
          ;; Search for best set of KIDs to be used for deccorelation, 
          ;; sorted in reverse order of correlation
          corr   = reform( mcorr[ikid,*])
          order  = reverse( sort( corr))
          s_corr = corr[ order]
 
          ;; Build the initial block, excluding ikid itself
          nblock = 0
          j      = 0
          while nblock lt param.n_corr_bloc_min do begin
             jkid = order[j]
             if kidpar[jkid].type eq 1 and jkid ne ikid then begin
                if nblock eq 0 then block = [jkid] else block = [block, jkid]
                nblock += 1
             endif
             j += 1
          endwhile

          ;; Find the average correlation and the dispersion in this
          ;; block
          mean_block = mean(   corr[block])
          std_block  = stddev( corr[block])

          ;; Add kids to the block when they have as good a
          ;; correlation (restart from the current j at the end of the
          ;; previous while loop)
          ;; In nika_pipe_subtract_common_bloc, we used to iterate on
          ;; the estimation of mean_block and std_block. I'm not sure
          ;; it's necessary, so I do not reproduce it here for the moment.
          ok = 1
          while ok eq 1 and j le (nw1-1) do begin
             jkid = order[j]
             if kidpar[jkid].type eq 1 and jkid ne ikid then begin
                if s_corr[j] ge (mean_block-std_block*param.nsigma_corr_bloc) then block = [block, jkid] else ok=0
             endif
             j += 1
          endwhile

          ;; Compute common mode
          ;; Fake subscan to use only the selected kids
          kidpar1      = kidpar
          kidpar1.type = 0
          kidpar1[block].type = 1

          if strupcase(param.decor_per_subscan) eq "YES" then begin
             for i=(min(data.subscan)>1), max(data.subscan) do begin
                wsubscan = where( data.subscan eq i, nwsample)

                ;; Compute common mode on the block thanks to kidpar1
                data_copy = data[wsample]
                nk_get_cm, param, info, data_copy, kidpar1, common_mode


                wsample = where( data.subscan eq i and data.off_source[ikid] eq 1 and data.flag[ikid] eq 0, nwsample)
      ;; Perform the REGRESS
      for i=0, nw1-1 do begin
         ikid  = w1[i]

         ;; Determine samples for which both ikid and ikid0 are off_source
         wsample  = where( data.off_source[ikid] eq 1 and data.flag[ikid] eq 0, nwsample)
         if nwsample eq 0 then begin
            ;; fatal error
            nk_error, info, "no sample for which numdet "+strtrim(ikid,2)+" is off source and flag=0"
            return
         endif
         if nwsample lt 100 then begin
            ;; warning only
            nk_error, info, "Less than 100 samples for which ikid "+strtrim(ikid,2)+" is off source and flag=0", status=2
         endif

         ;; Regress the templates and the data off source
         coeff = regress( templates[*,wsample], reform( data[wsample].toi[ikid]), $
                          CHISQ= chi, CONST= const, CORRELATION= corr, $
                          /DOUBLE, FTEST=ftest, MCORRELATION=mcorr, SIGMA=sigma, STATUS=status, YFIT=yfit)

         ;; Subtract the templates everywhere
         yfit = dblarr(nsn) + const
         for ii=0, n_elements(coeff)-1 do yfit += coeff[ii]*templates[ii,*]
         data.toi[ikid] -= yfit
      endfor
   endif
endfor

end


;;**********************
;;**********************

                data[wsample].toi = data_copy.toi
             endfor
          endif else begin      ; on the entire scan then
             nk_get_cm, param, info, data, kidpar, common_mode
             nk_subtract_templates, param, info, data, kidpar, common_mode[0,*], common_mode[1,*]
          endelse

                
         
          stop
       endfor
    

;;           ;;First bloc with the min number of KIDs allowed
;;           bloc = where(corr gt s_corr[param.decor.common_mode.nbloc_min+1] and corr ne 1, nbloc)
;;           ;;Then add KIDs and test if correlated enough  
;;           sd_bloc = stddev(corr[bloc])
;;           mean_bloc = mean(corr[bloc])
;;           iter = param.decor.common_mode.nbloc_min+1
;;           test = 'ok'
;;           while test eq 'ok' and iter lt nw1-2 do begin
;;              if s_corr[iter] lt mean_bloc-param.decor.common_mode.nsig_bloc*sd_bloc $
;;              then test = 'pas_ok' $
;;              else bloc = where(corr gt s_corr[param.decor.common_mode.nbloc_min+iter] and corr ne 1, nbloc)
;;              iter += 1
;;           endwhile
;;      
;;      ;;------- Build the appropriate noise template
;;      hit_b = lonarr(nsn)        ;Number of hit in the block common mode timeline 
;;      cm_b = dblarr(nsn)         ;Block common mode ignoring the source
;;      for j=0, nbloc-1 do begin
;;         cm_b += (atm_x_calib[bloc[j],0] + atm_x_calib[bloc[j],1]*rf_didq[bloc[j],*]) * w8source[bloc[j],*]
;;         hit_b += w8source[bloc[j],*]
;;      endfor
;;      
;;      loc_hit_b = where(hit_b ge 1, nloc_hit_b, COMPLEMENT=loc_no_hit_b, ncompl=nloc_no_hit_b)
;;      if nloc_hit_b ne 0 then cm_b[loc_hit_b] = cm_b[loc_hit_b]/hit_b[loc_hit_b]
;;      if nloc_no_hit_b ne 0 then cm_b[loc_no_hit_b] = !values.f_nan
;; 
;;      ;;------- If holes, interpolates
;;      if nloc_no_hit_b ne 0 then begin
;;         if nloc_hit_b eq 0 then message, 'You need to reduce param.decor.common_mode.d_min. ' + $
;;                                          'It is so large that not even a single KID used in the ' + $
;;                                          'common-mode can be assumed be off-source'
;;         warning = 'yes'
;;         indice = dindgen(nsn)
;;         cm_b = interpol(cm_b[loc_hit_b], indice[loc_hit_b], indice, /quadratic)
;;      endif
;;      
;;      ;;------- cross calibrate template on kid far from the source
;;      fit = linfit(cm_b[w], rf_didq[ikid,w])
;;      
;;      ;;------- apply model to the whole subscan to interpolate the source
;;      TOI_out[ikid,*] = rf_didq[ikid,*] - (fit[0] +fit[1]*cm_b)
;;      base[ikid,*]    = fit[0] +fit[1]*cm_b
;; 
;;   endfor
;; 
;;   RF_dIdQ = TOI_out
;; 
;; end
 
 
;; ;;*************************************************************************************
   end

   ELSE: begin
      nk_error, info, "Unrecognized decorelation method: "+param.decor_method
      return
   end
endcase

;;-------------------------------------------------------------------------------------------
;; Fourier filter
if param.bandpass ne 0 then begin
   ;; Init
   np_bandpass, data.toi[0], !nika.f_sampling, s_out, $
                freqlow=param.freqlow, freqhigh=param.freqhigh, filter=filter
   ;; Filter all kids
   for ikid=0, n_elements(kidpar)-1 do begin
      if kidpar[ikid].type ne 2 then begin
         np_bandpass, data.toi[0]-my_baseline(data.toi[0]), !nika.f_sampling, s_out, filter=filter
         data.toi[ikid] = s_out
      endif
   endfor
endif

;;-------------------------------------------------------------------------------------------
;; Decorrelate from elevation templates
if strupcase(info.obs_type) eq "LISSAJOUS" and param.decor_elevation then begin
   nsn       = n_elements(data)
   index     = dindgen( nsn)
   templates = dblarr(8,nsn)
   templates[0,*] = sin(      info.liss_freq_az*index)
   templates[1,*] = cos(      info.liss_freq_az*index)
   templates[2,*] = sin(      info.liss_freq_el*index)
   templates[3,*] = cos(      info.liss_freq_el*index)
   templates[4,*] = sin( 2.d0*info.liss_freq_az*index)
   templates[5,*] = cos( 2.d0*info.liss_freq_az*index)
   templates[6,*] = sin( 2.d0*info.liss_freq_el*index)
   templates[7,*] = cos( 2.d0*info.liss_freq_el*index)

   nk_subtract_templates, param, info, data, kidpar, templates, templates
endif

;;-------------------------------------------------------------------------------------------
;; Monitor the atmosphere via the common mode if requested
if param.do_meas_atmo ne 0 then begin
   if defined(common_mode) eq 0 then begin
      nk_error, info, "common_mode has not been computed"
      return
   endif
   nk_measure_atmo, param, info, data, kidpar, common_mode
endif

end
