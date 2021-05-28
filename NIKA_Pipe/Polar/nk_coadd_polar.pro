;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: nk_data_coadd
;
; CATEGORY: general
;
; CALLING SEQUENCE:
;         nk_data_coadd, param, info, data, kidpar, map_1mm=map_1mm, map_2mm=map_2mm
; 
; PURPOSE: 
;        This is the main procedure of the NIKA offline analysis
;        software that reduces the timelines to maps. It works on a single scan.
;        info.map_1mm and info.map_2mm can be passed to nk_average_maps to
;        produce the combined map of several scans.
; 
; INPUT: 
;        - param: the reduction parameters array of structures (one per scan)
;        - info: the array of information structure to be filled (one
;          per scan)
; 
; OUTPUT: 
;        - info.mapXX are modified
;        - map_1mm, map_2mm: maps of this scan
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - 12/06/2014: creation (Nicolas Ponthieu & Alessia Ritacco - ritacco@lpsc.in2p3.fr)
;-
;=========================================================================================================

pro nk_coadd_polar, param, info, data, kidpar, map_1mm=map_1mm, $
                    map_q_1mm=map_q_1mm,map_u_1mm=map_u_1mm,$
                    map_2mm=map_2mm, map_q_2mm=map_q_2mm,$
                    map_u_2mm=map_u_2mm
  
  if info.status eq 1 then begin
     if param.silent eq 0 then    message, /info, "info.status = 1 from the beginning => exiting"
     return
  endif
  nsn = n_elements(data)
;; Handle the flag of pieces of scan
  nk_cut_scans, param, info, data, kidpar

;; Discard sections when the telescope is not moving at
;;regular speed (inter subscans, approach phases, slew...)
  nk_speed_flag, param, info, data, kidpar

;; Calibrate the data 
  nk_calibration, param, info, data, kidpar

;; Deglitch the data
  nk_deglitch, param, info, data, kidpar

;; Remove jumps from the data
;;nk_jump, param, info, data, kidpar

;; Flag KIDs
;; nk_flag_bad_kid, param, info, data, kidpar

;; Produce calibrated data in fits files
;; nk_toi2fits, param, info, data, kidpar

;; Loop over iterations
  data_copy = data
  for iiter=0, param.niter - 1 do begin
     
     ;; Restore un-decorrelated data at each iteration for now
     data = data_copy

     ;; Reset maps at each iteration
     info.map_1mm     = 0.d0
     info.map_q_1mm   = 0.d0
     info.map_u_1mm   = 0.d0
     info.nhits_1mm   = 0.d0
     info.map_w8_1mm  = 0.d0
     info.map_var_1mm = 0.d0
     info.map_2mm     = 0.d0
     info.map_q_2mm   = 0.d0
     info.map_u_2mm   = 0.d0
     info.nhits_2mm   = 0.d0
     info.map_w8_2mm  = 0.d0
     info.map_var_2mm = 0.d0
     
     ;; Define which parts of the maps must be masked for common mode estimation
     ;; info.mask_source must be 1 outside the source, 0 on source
     nk_mask_source, param, info, data, kidpar

     ;; Treat the noise (decorrelation and filtering)
     nk_decor, param, info, data, kidpar

     ;; Re-deglitch the data to improve after atmosphere subtraction
     nk_deglitch, param, info, data, kidpar

     ;; Zero level
     ;; nk_0level, param, info, data, kidpar

     ;; Compute inverse variance weights for TOIs
     nk_w8, param, info, data, kidpar
     nkids     = n_elements(kidpar)
     ;;========== Subtract low frequencies before fiting out the
     ;;template (it should improve)
     
     low_freq = data.toi*0.d0   ; init
     freqhigh = 1.d0
     np_bandpass, dblarr(nsn), !nika.f_sampling, freqhigh=freqhigh, filter=filter
     for i=0, nkids-1 do begin
        if kidpar[i].type eq 1 then begin
           np_bandpass, data.toi[i], !nika.f_sampling, s_out, filter=filter
           low_freq[i,*]    = s_out
           data.toi[i] -= s_out
        endif
     endfor
     ;; Determine HWP rotation speed
     nk_get_hwp_rot_freq, data, rot_freq_hz
     param.polar_nu_rot_hwp = rot_freq_hz

     ;; Subtract HWP template
     nk_hwp_rm, param, kidpar, data

     ;; Restore low frequencies
     data.toi += low_freq
     delvarx, low_freq          ; save memory

     ;;========= Obtain the maps I,Q,U
     nk_polar_maps, param, info, data, kidpar, maps_S0, maps_S1, maps_S2,$
                    maps_covar, azel=azel, nasmyth=nasmyth

     ;; replace NaN by zeros for the subtraction below
     wnan = where( finite( maps_S0) ne 1, nwnan)
     if nwnan ne 0 then maps_S0[wnan] = 0.d0
     wnan = where( finite( maps_S1) ne 1, nwnan)
     if nwnan ne 0 then maps_S1[wnan] = 0.d0
     wnan = where( finite( maps_S2) ne 1, nwnan)
     if nwnan ne 0 then maps_S2[wnan] = 0.d0
     
     xmin = info.xmin
     ymin = info.ymin
     nx   = info.nx
     ny   = info.ny

     map_i_1mm = reform( maps_S0[*,0], nx, ny)
     map_q_1mm = reform( maps_S1[*,0], nx, ny)
     map_u_1mm = reform( maps_S2[*,0], nx, ny)
     map_i_2mm = reform( maps_S0[*,1], nx, ny)
     map_q_2mm = reform( maps_S1[*,1], nx, ny)
     map_u_2mm = reform( maps_S2[*,1], nx, ny)
;;       stop
;;       wind, 1, 1, /free, xs=1600, ys=1000
;; ;   my_multiplot, 3, 3, pp, pp1, /rev
;;        my_multiplot, 3, 2, pp, pp1, /rev
;;        imview, map_i_1mm, xmap=xmap, ymap=ymap, position=pp1[0,*], title='T 1mm '
;;        imview, map_q_1mm, xmap=xmap, ymap=ymap, position=pp1[1,*], imrange=[-1,1]*0.5,$
;;                title='Q 1mm ', /noerase
;;        imview, map_u_1mm, xmap=xmap, ymap=ymap, position=pp1[2,*], imrange=[-1,1]*0.5,$
;;                /noerase, title='U 1mm '
;;        imview, map_i_2mm, xmap=xmap, ymap=ymap, position=pp1[3,*], /noerase, title='T 2mm'
     
;;        imview, map_q_2mm, xmap=xmap, ymap=ymap, position=pp1[4,*], imrange=[-1,1]*0.1,$
;;                /noerase, title='Q 2mm '
;;        imview, map_u_2mm, xmap=xmap, ymap=ymap, position=pp1[5,*], imrange=[-1,1]*0.1,$
;;                /noerase, title='U 2mm '
;; stop


     
     ;; Project the data onto maps
     nk_projection_polar, param, info, data, kidpar
     
     ;; Average maps over scans
     if info.status ne 1 then begin  
        map_1mm   = info.map_1mm*0.d0
        map_q_1mm = info.map_q_1mm*0.d0
        map_u_1mm = info.map_u_1mm*0.d0
        map_2mm   = info.map_2mm*0.d0
        map_q_2mm = info.map_q_2mm*0.d0
        map_u_2mm = info.map_u_2mm*0.d0
        
        w = where( info.map_w8_1mm ne 0, nw)
        if nw ne 0 then begin
           info.map_1mm[w]     = info.map_1mm[w]  /info.map_w8_1mm[w]
           info.map_q_1mm[w]   = info.map_q_1mm[w]/info.map_w8_1mm[w]
           info.map_u_1mm[w]   = info.map_u_1mm[w]/info.map_w8_1mm[w]
           info.map_var_1mm[w] =              1.d0/info.map_w8_1mm[w]
        endif
        w = where( info.map_w8_2mm ne 0, nw)
        if nw ne 0 then begin
           info.map_2mm[w]     = info.map_2mm[w]  /info.map_w8_2mm[w]
           info.map_q_2mm[w]   = info.map_q_2mm[w]/info.map_w8_2mm[w]
           info.map_u_2mm[w]   = info.map_u_2mm[w]/info.map_w8_2mm[w]
           info.map_var_2mm[w] =             1.0d0/info.map_w8_2mm[w]
        endif


        wind, 1, 1, /free, /xlarge
        my_multiplot, 3, 3, pp, pp1
        imview, map_1mm,     xmap=info.xmap, ymap=info.ymap, $
                title='I_1mm iter='+strtrim(iiter,2), position=pp1[0,*]
        imview, map_q_1mm,     xmap=info.xmap, ymap=info.ymap, $
                title='Q_1mm iter='+strtrim(iiter,2), position=pp1[1,*], /noerase
        imview, map_u_1mm,     xmap=info.xmap, ymap=info.ymap, $
                title='U_1mm iter='+strtrim(iiter,2), position=pp1[2,*], /noerase
        imview, map_2mm,     xmap=info.xmap, ymap=info.ymap, $
                title='2mm iter='+strtrim(iiter,2), position=pp1[3,*], /noerase
        imview, map_q_2mm,     xmap=info.xmap, ymap=info.ymap, $
                title='1mm iter='+strtrim(iiter,2), position=pp1[4,*], /noerase
        imview, map_u_2mm,     xmap=info.xmap, ymap=info.ymap, $
                title='1mm iter='+strtrim(iiter,2), position=pp1[5,*], /noerase
        imview, info.mask_source, xmap=info.xmap, ymap=info.ymap, $
                title='mask', position=pp1[6,*], /noerase

     endif
     
     
     
     ;; Update mask_source for an iteration
     nk_update_source_mask, param, info, data, kipdar
  endfor                        ;iteration loop

  
end
