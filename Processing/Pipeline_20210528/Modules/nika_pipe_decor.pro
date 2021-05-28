;+
;PURPOSE: Remove as much atmospheric noise as possible using
;         decorrelation technics according to the astrophysical 
;         source.
;
;INPUT: The parameter, data and kidpar structures
;
;OUTPUT: The decorrelated data structure.
;
;LAST EDITION: 21/01/2012: creation(adam@lpsc.in2p3.fr)
;              10/01/2014: use an other kidpar with flagged KIDs
;              12/07/2015: add keyword subtract_toi_iter for cmblock decor
;-

pro nika_pipe_decor, param, data, kidpar0, baseline, $
                     extent_source=extent_source, $
                     bypass_error=bypass_error, $
                     pazel=pazel, $
                     silent=silent, $
                     subtract_toi_iter=subtract_toi_iter, $
                     blocv=blocv
  
  ;;---------- Init baseline
  baseline = fltarr( n_elements( kidpar0), n_elements( data))

  ;;########## Flag KIDs that should not be used for decorrelation ##########
  w1mm = where(kidpar0.type eq 1 and kidpar0.array eq 1, nw1mm)
  w2mm = where(kidpar0.type eq 1 and kidpar0.array eq 2, nw2mm)
  
  kidpar = kidpar0
  w_valid_kid = nika_pipe_kid4cm(param, data, kidpar, Nvalid=nv, complement=w_bad_kid, ncomplement=nw_bad_kid)
  
  nrej1mm = 0                   ; default init ?
  nrej2mm = 0                   ; default init ?
  if nw_bad_kid ne 0 then begin
     kidpar[w_bad_kid].type = -1 ;We use only Valid On KIDs and eventually Offs tones
     rej1mm = where(kidpar0[w_bad_kid].type eq 1 and kidpar0[w_bad_kid].array eq 1, nrej1mm)
     rej2mm = where(kidpar0[w_bad_kid].type eq 1 and kidpar0[w_bad_kid].array eq 2, nrej2mm)
  endif
  
  if (not keyword_set(bypass_error) and nw1mm ne 0) then if (nrej1mm eq nw1mm) then $
     message, 'All 1mm KIDs are flagged, no decorrelation is possible'
  if (not keyword_set(bypass_error) and nw2mm ne 0) then if (nrej2mm eq nw2mm) then $
     message, 'All 2mm KIDs are flagged, no decorrelation is possible'
  
  if ((nrej2mm eq nw2mm) or (nrej1mm eq nw1mm)) and (nw1mm ne 0 and nw2mm ne 0) then begin
     message, /info, 'You bypass the fact that no KID is valid, the maps will be empty for this scan'
     goto, the_end
  endif

  ;;########## Decorrelation of the electronic noise in the IQ plane ##########
  case strupcase(param.decor.IQ_plane.apply) of
     ;;-1------- IQ plane decorrelation
     "YES": begin
        for lambda=1, 2 do begin
           woff = where( kidpar.array eq lambda and kidpar.type eq 2, nwoff)
           if nwoff ne 0 then begin
              if not keyword_set( silent) then message,/info, 'The electronic noise is removed in the IQ plane'
              w = where(kidpar.array eq lambda and kidpar.type eq 1, nw)
              df_mod_a = kidpar[w[0]].amp_mod ; (kidpar[where(kidpar.array eq 1)].amp_mod)[0] ;modulation of the tone freq
              nika_pipe_iqdec, param, data.subscan, df_mod_a, kidpar[w], $
                               data.I[w], data.Q[w], data.dI[w], data.dQ[w], RFdIdQ_dec_a
              data.RF_dIdQ[w] = - RFdIdQ_dec_a
           endif else message, /info, 'No OFF tones: the IQ plane decorrelation is not possible at '+strtrim(lambda,2)+'mm'
        endfor
        ;;------- Need to calibrate because new RFdIdQ data
        nika_pipe_opacity, param, data, kidpar, simu=simu, noskydip=noskydip
        nika_pipe_calib, param, data, kidpar, noskydip=noskydip
        nika_pipe_gain_cor, param, data, kidpar, extent_source=extent_source
     end
     
     ;;-2------- No IQ plane decorrelation
     "NO":begin
        if not keyword_set( silent) then $
           message, /info, 'No decorrelation in the IQ plane'
     end
  endcase

  woff = where(kidpar0.type eq 2, nwoff)
  if nwoff ne 0 then toi_off = data.RF_dIdQ[woff]

  ;;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  case strupcase(param.decor.method) of
     ;;======================= No noise removal ============================================
     ;;-1------- No decorrelation
     "NONE": if not keyword_set(silent) then message, /info, "No decorrelation"
     
     ;;================= Single detector based methods =====================================
     ;;-2.1-------- Simple median filter
     "MEDIAN_SIMPLE":begin
        if not keyword_set(silent) then message, /info, "Decorrelation: simple median filter"
        nika_pipe_median_simple_dec, param, data, kidpar, baseline
     end

     ;;-2.2-------- Median filter with a mask on the source
     "MEDIAN":begin
        if not keyword_set(silent) then message, /info, "Decorrelation: median filter with the source masked"
        nika_pipe_mediandec, param, data, kidpar
     end
     
     ;;-2.3-------- Remove the timeline interpolated at the source location
     "SOURCE_INTERPOL":begin
        if not keyword_set(silent) then message, /info, "Decorrelation: remove the TOI interpolated at the source location"
        nika_pipe_interpol_source, param, data, kidpar
     end
     
     ;;-2.4------- Simple baseline subtraction (for reference and
     ;;          perhaps plateau enhancement ?)
     "BASELINE_EDGE":begin
        if not keyword_set(silent) then message, /info, "Subtracting simple baseline fit on the edges of subscans"
        nika_pipe_baseline_subtract, param, data, kidpar, in_frac=param.decor.frac
     end
     
     ;;================= Common-mode based methods =====================================
     ;;-3.1-------- Commmon mode
     "COMMON_MODE":begin
        if not keyword_set(silent) then message, /info, "Decorrelation: simple common mode"
        for lambda=1, 2 do begin
           w = where(kidpar.array eq lambda, nw)
           if nw ne 0 then begin
              TOI =  data.RF_dIdQ[w]
              nika_pipe_cmdec, param, TOI, kidpar[w], data.subscan, silent=silent
              data.RF_dIdQ[w] = TOI
           endif
        endfor
     end
     
     ;;-3.2-------- Common mode with KIDs OFF source
     "COMMON_MODE_KIDS_OUT":begin
        if not keyword_set(silent) then message, /info, "Decorrelation: common mode with KIDs outside the source"
        baseline = data.RF_dIdQ * 0
        if param.decor.common_mode.median eq 'yes' then k_median = 1 else k_median=0
        for lambda=1, 2 do begin
           w = where(kidpar.array eq lambda, nw)
           if nw ne 0 then begin
              TOI = data.RF_dIdQ[w]
              nika_pipe_cmkidout, param, TOI, kidpar[w], data.subscan, data.on_source_dec[w], data.el, data.ofs_el, $ 
                                  baseline_out, atm_temp, $
                                  silent=silent, k_median=k_median
              baseline[w, *] = baseline_out
              data.RF_dIdQ[w] = TOI
           endif
        endfor
     end
     
     ;;-3.3-------- Common mode with source subtracted from first guess map
     "COMMON_MODE_MAP_SUBTRACT":begin
        message, /info, "Decorrelation: common mode the source flagged from a map and subtracted form the TOI"
        nika_pipe_cmmapsubtract, param, data, kidpar
     end
     
     ;;================= Bloc of electronic methods =====================================
     ;;-4.1-------- Common mode with best correlated detectors
     "COMMON_MODE_BLOCK":begin
        if not keyword_set( silent) then $
           message, /info, "Decorrelation: common mode with KIDs outside the source per block of best correlation"
        if keyword_set(subtract_toi_iter) then toi_est = nika_pipe_extract_estimated_toi(param, data, kidpar)
        for lambda=1, 2 do begin
           w = where(kidpar.array eq lambda, nw)
           if nw ne 0 then begin
              TOI = data.RF_dIdQ[w]
              if keyword_set(subtract_toi_iter) then toi_est2 = toi_est[w,*]
              nika_pipe_cmblock, param, TOI, kidpar[w], data.subscan, data.on_source_dec[w], data.el, data.ofs_el, $
                                 baseline, $
                                 silent=silent, toi_est=toi_est2, blocv=blocv
              data.RF_dIdQ[w] = TOI
           endif
        endfor
     end
     
     ;;-4.2-------- Common mode with bloc of electronics
     "COMMON_MODE_BLOCK2":begin
        message, /info,"Decorrelation: common mode with KIDs outside the source per block of electronics a priori"
        nika_pipe_cmblock2, param, data, kidpar, baseline, silent=silent
     end

     ;;================= Multi-templates based methods =====================================
     ;;-5.1------- Decorrelation with all (or part of) the other KIDs of the same array
     "FULL":begin
        message, /info, "Decorrelation: full, uses all the KIDs of the same array"
        for lambda=1, 2 do begin
           w = where(kidpar.array eq lambda, nw)
           if nw ne 0 then begin
              TOI = data.RF_dIdQ[w]
              nika_pipe_fulldec, param, toi, kidpar[w], data.subscan
              data.RF_dIdQ[w] = TOI
           endif
        endfor
     end
          
     ;;================= Dual-band based methods =====================================
     ;;-6.1------- Dual band decorrelation
     "DUAL_BAND_SIMPLE":begin
        message, /info, "Decorrelation: dual-band decorrelation"
        nika_pipe_dualbanddec, param, data, kidpar, silent=silent
     end
     
     ;;-6.2------- Dual band decorrelation
     "DUAL_BAND_FREQ":begin
        message, /info, "Decorrelation: dual-band decorrelation at low frequencies and common mode at higher"
        nika_pipe_dualbandfreqdec, param, data, kidpar, silent=silent
     end
     
     ;;-6.3------- Principal component analysis
     "PCA_2BAND":begin
        message, /info, "Remove principal components computed for both bands"
        nika_pipe_pca2banddec, param, data, kidpar
     end
     
     ;;-6.4-------- The future tSZ method
     "TSZ":begin
        message, /info, "Decorrelation: tSZ method"
        nika_pipe_tszdec, param, data, kidpar, silent=silent
     end
     
     ;;==========================================================================
     ;;==========================================================================
     ;;==========================================================================

     ;;================= Work in progress methods ===============================
     ;;-7.1------- Test decorrelation method
     "TEST":begin
        message, /info, "Decorrelation: test!"
        w1mm = where(kidpar.array eq 1, nw1mm)
        w2mm = where(kidpar.array eq 2, nw2mm)
        kidpar_a = kidpar[w1mm]
        kidpar_b = kidpar[w2mm]
        toi_a = data.rf_didq[w1mm]
        toi_b = data.rf_didq[w2mm]
        nika_pipe_testdec, data.el, data.subscan, kidpar_a, kidpar_b, toi_a, toi_b, toi_out_a, toi_out_b
        data.rf_didq[w2mm] = toi_out_b
        nika_pipe_cmdec, param, toi_a, kidpar_a, data.subscan
        data.rf_didq[w1mm] = toi_a
     end
     
     ;;-7.3------- Principal component analysis
     "PCA_1BAND":begin
        message, /info, "Remove principal components computed band per band"
        nika_pipe_pca1banddec, param, data, kidpar
     end

     ;;-7.4-------- Common mode (idem COMMON_MODE_KIDS_OUT) and gaussian fit of the source
     "COMMON_MODE_GAUSSIAN_FIT":begin
        message, /info, "Decorrelation: common mode and a gaussian fit of the source"
        for lambda=1, 2 do begin
           w = where(kidpar.array eq lambda, nw)
           if nw ne 0 then begin
              TOI =  data.RF_dIdQ[w]
              nika_pipe_cmgaussfit, param, toi, kidpar[w], data
              data.RF_dIdQ[w] = TOI
           endif
        endfor
     end

     ;;-7.5-------- Common mode with KIDs OFF source and Delevation simultaneously
     "LISSOPT":begin
        message, /info, "Decorrelation: common mode with KIDs outside the source per block of best correlation and Delevation/DAz + Twice freq AzEl simultaneously"
        nika_pipe_lissopt, param, data, kidpar, pazel=pazel
     end

     ;;-7.6------- Multi dim decorrelates from pixels far from the source
     ;;           (not via a common mode like common_mode_kids_out)
     ;;"MULTI_KID_OUT":begin
     ;;   message, /info, "Decorrelation: MULTI_KID_OUT"
     ;;   nika_pipe_dec_multikid_out, param, data, kidpar
     ;;end

     ;;-7.7------- Decorrelation with common-mode made with KIDs that
     ;;            are far enough from the decorrelated one
     "COMMON_MODE_KIDS_FAR":begin
        message, /info, "Decorrelation: common mode with KIDs far away in the focal plane"
        for lambda=1, 2 do begin
           w = where(kidpar.array eq lambda, nw)
           if nw ne 0 then begin
              TOI = data.RF_dIdQ[w]
              nika_pipe_cmkidfar, param, toi, kidpar[w], data.subscan, data.on_source_dec[w], data.el, data.ofs_el
              data.RF_dIdQ[w] = TOI
           endif
        endfor
     end
     
  endcase

  if nwoff ne 0 then  data.RF_dIdQ[woff] = toi_off

  the_end:

  return
end
