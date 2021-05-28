
;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_imcm_decorr
;
; CATEGORY: ?
;
; CALLING SEQUENCE:
; 
; PURPOSE: 
; 
; INPUT: 
; 
; OUTPUT: 
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 

pro nk_imcm_decorr, param, info, kidpar, toi, flag, off_source, elevation, $
                    toi_out, out_temp, snr_toi=snr_toi, out_coeffs=out_coeffs, $
                    w8_hfnoise=w8_hfnoise
;-

if n_params() lt 1 then begin
   dl_unix, 'nk_imcm_decorr'
   return
endif

if param.cpu_time then param.cpu_t0 = systime(0, /sec)

nsn = n_elements( toi[0,*])
nkids = n_elements(kidpar)

;; Compute w8_source once for all
if defined(snr_toi) then begin
   w8_source=1.d0/(1.d0+param.k_snr_w8_decor*snr_toi^2)

   ;; Do not defined w8_source = off_source or this leads to division
   ;; by 0 in nk_subtract_templates_3 when computing measure_errors.
;; endif else begin
;;    w8_source = off_source
;; endelse
endif

;; Implement estimation of excess noise, that in general shows up on
;; subscan edges. See Xavier's trick in
;; nk_decor_atmb_per_array.pro for his method #120
if param.subscan_edge_w8 gt 0 then begin
   toih = toi
   w8_hfnoise = toi*0.d0        ; init for convenience
   nsmooth = round( param.subscan_edge_w8_smooth_duration*!nika.f_sampling)
   for iarray=1, 3 do begin
      w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1)

      if nw1 ne 0 then begin
         for i=0, nw1-1 do toih[w1[i],*] = toi[w1[i],*]-smooth( toi[w1[i],*], nsmooth, /edge_mirror)
         hfnoise = smooth( stddev( toih[w1,*], dim=1), nsmooth, /edge_mirror)

         ;; scale to an average single detector and center
         ;;hfnoise[12:nsn-12] = sqrt(nw1) * (hfnoise[12:nsn-12]-avg(hfnoise[12:nsn-12]))
         hfnoise *= sqrt(nw1)
         ;; Normalize to its own stddev
         hfnoise /= stddev( hfnoise)
         ;; Normalize to its average to have something around 1
         hfnoise /= avg( hfnoise)

         ;; Center hfnoise for the w8 formula
         w8_hfnoise[w1,*] = transpose( rebin( $
                            1.d0/(1.d0+param.subscan_edge_w8*((hfnoise-avg(hfnoise))/stddev(hfnoise))^2), nsn, nw1))

         if param.interactive eq 1 then begin
            if defined(my_local_window) eq 0 then begin
               wind, 1, 1, /free, /large
               my_multiplot, 3, 2, pp, pp1, /rev
               my_local_window = !d.window
            endif

            time = dindgen(n_elements(toi[0,*]))/!nika.f_sampling
            ikid = w1[0]
            myavg = avg(toi[ikid,*])
            yra = array2range( toi[ikid,*]-myavg)
            plot, time, toi[ikid,*]-myavg, /xs, position=pp[iarray-1,0,*], /noerase, yra=yra, /ys, $
                  xtitle='Time (sec)'
            wflag = where( flag[ikid,*] ne 0)
            oplot, time[wflag], toi[ikid,wflag]-myavg, psym=1, syms=0.5, col=200
            oplot, time, (-0.5 + (flag[ikid,*] eq 2L^11))*(yra[1]-yra[0])/2., col=70
            legendastro, ['TOI', 'Flag ne 0', 'Anomalous speed'], col=[0,200,70]
            legendastro, ['A'+strtrim(iarray,2), $
                          'Numdet '+strtrim(kidpar[ikid].numdet,2)], /right

            yra = [0, max(hfnoise)>1.5]
            plot,  time, hfnoise, /xs, position=pp[iarray-1,1,*], /noerase, /nodata, yra=yra, $
                   xtitle='Time (sec)'
            oplot, time, hfnoise, col=250
            oplot, time, w8_hfnoise[ikid,*], col=150
            legendastro, ['hfnoise', 'w8_hfnoise'], col=[250,150]
;            stop
         endif
      endif
   endfor

   ;; Account for this weight in w8_source
   if defined(w8_source) then begin
      w8_source *= w8_hfnoise
   endif else begin
      w8_source = w8_hfnoise
   endelse
   delvarx, toih
endif

if param.decor_from_atm eq 1 and $
   param.atm_per_array eq 0 and $
   param.dual_band_1mm_atm eq 0 then begin
;; 1. Estimate atmosphere from all KIDs (both 1 and 2mm)
   if param.log then nk_log, info, "Derive atm_cm from ALL valid kids (1 & 2mm)"
   w1 = where( kidpar.type eq 1, nw1)
   if defined(w8_source) then myw8 = w8_source[w1,*]
   myflag = flag[w1,*]
   nk_get_cm_sub_2, param, info, toi[w1,*], myflag, $
                    off_source[w1,*], kidpar[w1], atm_cm, $
                    w8_source=myw8
   flag[w1,*] = myflag ; update flags
   delvarx, myw8, myflag
endif

;;----------------- Loop over arrays for eletronics related modes -----------------
nkids    = n_elements(kidpar)
toi_out  = dblarr(nkids,nsn)
out_temp = dblarr(nkids,nsn)

subband = kidpar.numdet/80      ; integer division on purpose

;; min number of kids to derive a common mode in a subband if requested
nwbmin = 10                     ; 3

if param.decor_from_atm eq 1 and param.dual_band_1mm_atm eq 1 then begin
   w1mm = where( kidpar.type eq 1 and kidpar.array ne 2, nw1mm)
   if param.log then nk_log, info, "Derive atm_cm for A1 and A3 (dual band) for all array"+strtrim(iarray,2)
   if defined(w8_source) then myw8 = w8_source[w1mm,*]
   myflag = flag[w1mm,*]
   nk_get_cm_sub_2, param, info, toi[w1mm,*], myflag, $
                    off_source[w1mm,*], kidpar[w1mm], atm_cm, w8_source=myw8
   flag[w1,*] = myflag
   delvarx, myflag
endif

which_templates = ''

for iarray=1, 3 do begin
   w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1)
   
   p=-1
   if nw1 ne 0 then begin
      ;; Init the toi that gets cleaner and cleaner
      residual = toi[w1,*]

      ;------------------------------- ATMOSPHERE ----------------------------------------------
      if param.decor_from_atm eq 1 then begin
         
         if param.atm_per_array eq 1 then begin
            if param.log then nk_log, info, "Derive atm_cm for A"+strtrim(iarray,2)
            if defined(w8_source) then myw8 = w8_source[w1,*]
            myflag = flag[w1,*]
            if param.interactive eq 1 then !mydebug.array = iarray
            

;;            if long(info.CURRENT_SUBSCAN_NUM) eq 3 then stop

            nk_get_cm_sub_2, param, info, toi[w1,*], myflag, $
                             off_source[w1,*], kidpar[w1], atm_cm, w8_source=myw8
            flag[w1,*] = myflag
            delvarx, myflag

;;             wind, 1, 1, /free, /large
;;             my_multiplot, 1, 2, pp, pp1, /rev
;;             make_ct, nw1, ct
;;             toi1 = toi
;;             for i=0, nw1-1 do toi1[w1[i],*] -= median( toi1[w1[i],*])
;;             yra = array2range( toi1[w1,*])
;;             plot, toi1[w1[0],*], /xs, yra=yra, /ys, position=pp1[0,*], $
;;                   title='A'+strtrim(iarray,2)+", subscan "+strtrim( long(info.CURRENT_SUBSCAN_NUM),2)
;;             for i=0, nw1-1 do oplot, toi1[w1[i],*], col=ct[i]
;;             plot, atm_cm, /xs, position=pp1[1,*], /noerase
;;             legendastro, 'atm_cm'
;; stop



            if param.atm_nsmooth ne 0 then atm_cm = smooth( atm_cm, param.atm_nsmooth)
            ;; wind, 1, 1, /free, /large
            ;; atm_cm_sm = smooth( atm_cm, 24, /edge_mirr)
            ;; np_bandpass, atm_cm-my_baseline(atm_cm,b=0.01), !nika.f_sampling, s_out, freqhigh=1.
            ;; plot, atm_cm, /xs, /ys, xra=[0,1000]
            ;; oplot, atm_cm_sm, col=70
            ;; oplot, s_out, col=250
            ;; stop

         endif

         if param.include_elevation_in_decor_templates eq 1 then begin
            which_templates += 'elevation, atm'
            if param.log then nk_log, info, "add elevation in the list of decorrelation templates"
            atm_temp = dblarr(2,nsn)
            atm_temp[0,*] = atm_cm
            atm_temp[1,*] = elevation
         endif else begin
            which_templates += 'atm'
            atm_temp = dblarr(1,nsn)
            atm_temp[0,*] = atm_cm
         endelse

         ;; @ 1. Subtract atmosphere from all KIDs
         if param.log then nk_log, info, "subtract "+which_templates+" from toi"
         if defined(w8_source) then myw8 = w8_source[w1,*]
         myflag = flag[w1,*]

         nk_subtract_templates_3, param, info, residual, myflag, off_source[w1,*], $
                                  kidpar[w1], atm_temp, out_temp1, out_coeffs=out_coeffs, $
                                  w8_source=myw8

         flag[w1,*] = myflag    ; update flags 
         delvarx, myw8, myflag
      endif


      if param.show_toi_corr_matrix then begin
         corr_mat0 = abs(correlate( toi[w1,*]))
         corr_mat1 = abs(correlate( residual))
      endif

      ;----------------------------ELECTRONIC BOXES ----------------------------------------------
      ;; @ 2. 1st estimate of mode per electronic box
      if param.decor_from_box_modes eq 1 then begin
         if defined(w8_source) then myw8 = w8_source[w1,*]
         myflag = flag[w1,*]
         nk_get_one_mode_per_box, param, info, residual, myflag, off_source[w1,*], kidpar[w1], $
                                  common_mode_per_box, acq_box_out, w8_source=myw8
         flag[w1,*] = myflag
         delvarx, myw8, myflag
         ;; @ 3. subtract box modes
         if param.regress_all_box_modes eq 1 then begin
            if param.log then nk_log, info, "Regress each KID on all the el. box modes at the same time"
            if defined(w8_source) then myw8 = w8_source[w1,*]
            myflag = flag[w1,*]
            nk_subtract_templates_3, param, info, residual, myflag, off_source[w1,*], $
                                     kidpar[w1], common_mode_per_box, w8_source=myw8
            flag[w1,*] = myflag ; update flags 
            delvarx, myw8, myflag
         endif else begin
            if param.log then nk_log, info, "Regress each KID on its own el. box mode only"
            for i=0, nw1-1 do begin
               ikid = w1[i]
               wb = where( acq_box_out eq kidpar[ikid].acqbox)
               junk = residual[i,*]
               myflag = flag[ikid,*]
               if defined(w8_source) then myw8 = w8_source[ikid,*]
               nk_subtract_templates_3, param, info, junk, myflag, off_source[ikid,*], $
                                        kidpar[ikid], common_mode_per_box[wb,*], w8_source=myw8
               delvarx, myw8
               flag[ikid,*] = myflag
               residual[i,*] = junk
            endfor
         endelse
         if param.show_toi_corr_matrix then corr_mat2 = abs( correlate( residual))
      endif

      ;;----------------------------- SUBBANDS ----------------------------------------------
      if param.decor_all_subbands eq 1 then begin
         if param.log then nk_log, info, "Derive one mode per subband"
         ;; @ 4. 1st estimate of modes per subband
         ;; @^ restrict to subbands of the current array
         sb = subband[w1]
         b = sb[ uniq( sb, sort(sb))]
         nsubbands=0
         for ib=0, n_elements(b)-1 do begin
            wb = where( kidpar[w1].numdet/80 eq b[ib], nwb)
            if nwb ge nwbmin then nsubbands++
         endfor

         subband_num   = intarr(nsubbands)
         subband_modes = dblarr(nsubbands,nsn)
         isubband = 0
         for ib=0, n_elements(b)-1 do begin
            wb = where( kidpar[w1].numdet/80 eq b[ib], nwb)
            if nwb eq 0 then message, "something wrong with subbands..."
            if nwb ge nwbmin then begin
               subband_num[isubband] = b[ib]
;               if iarray eq 1 then print, "subband_num[isubband], nwb: ", subband_num[isubband], nwb
               if defined(w8_source) then myw8 = w8_source[w1[wb],*]
               myflag = flag[w1[wb],*]
               nk_get_cm_sub_2, param, info, residual[wb,*], myflag, $
                                off_source[w1[wb],*], kidpar[w1[wb]], subband_cm, w8_source=myw8
               subband_modes[isubband,*] = subband_cm
               flag[w1[wb],*] = myflag
               isubband++
            endif
         endfor
         delvarx, myw8
;         if param.interactive eq 1 then print, "subband_num: ", subband_num
      endif
;stop

      ;; @ 5. Decorrelate from atm (and elevation if requested) and all
      ;; @^ modes at the same time by default
      if param.decor_from_atm       eq 1 then nt = n_elements(atm_temp[*,0]) else nt = 0
      if param.decor_from_box_modes eq 1 then begin
         nboxes = n_elements(acq_box_out)
         which_templates += ', el. box modes'
      endif else begin
         nboxes = 0
      endelse
      if param.decor_all_subbands eq 0 then begin
         nsubbands = 0
      endif else begin
         which_templates += ', subbands'
      endelse

      if param.nharm_multi_sinfit gt 0 then begin
;;         if param.trigo_modes_period_arcsec gt 0 then begin
;;            param.nharm_multi_sinfit = round( info.subscan_arcsec/param.trigo_modes_period_arcsec)
;;            message, /info, "param.trigo_modes_period: "+strtrim(param.trigo_modes_period_arcsec,2)
;;            message, /info, "param.nharm_multi_sinfit: "+strtrim(param.nharm_multi_sinfit,2)
;;            stop
;;         endif
         which_templates += ', baseline + trigo. modes'
         n_trigo_modes = 1 + 2*param.nharm_multi_sinfit
      endif else begin
         n_trigo_modes = 0
      endelse
      templates = dblarr(nboxes+nt+nsubbands + n_trigo_modes, nsn)
      if nt        ge 1 then templates[0:nt-1,         *] = atm_temp
      if nboxes    ge 1 then templates[nt:nt+nboxes-1, *] = common_mode_per_box
      if nsubbands ge 1 then templates[nt+nboxes:nt+nboxes+nsubbands-1,    *] = subband_modes
      if n_trigo_modes ge 1 then begin
         x = dindgen(nsn)
         for iharm=0, param.nharm_multi_sinfit-1 do begin
            templates[nt+nboxes+nsubbands + 2*iharm,     *] = cos(2.d0*!dpi/(nsn-1)*x*(iharm+1))
            templates[nt+nboxes+nsubbands + 2*iharm + 1, *] = sin(2.d0*!dpi/(nsn-1)*x*(iharm+1))
         endfor
         templates[nt+nboxes+nsubbands + 2*param.nharm_multi_sinfit, *] = x
      endif

      if param.log then nk_log, info, "restore toi"
      residual = toi[w1,*]      ; re-init for the global decorrelation
      if param.log then nk_log, info, "decorrelate from "+which_templates+" all together"
      if defined(w8_source) then myw8 = w8_source[w1,*]
      myflag = flag[w1,*]

;;       if info.CURRENT_SUBSCAN_NUM ge 2 then begin
;;          wind, 1, 1, /free, /large
;;          print, "subscan = "+strtrim(info.CURRENT_SUBSCAN_NUM,2)
;;          my_multiplot, 1, 1, ntot=n_elements(templates[*,0]), pp, pp1, /rev
;;          for i=0, n_elements(templates[*,0])-1 do plot, templates[i,*], posi=pp1[i,*], /noerase
;;          stop
;;       endif
      nk_subtract_templates_3, param, info, residual, myflag, off_source[w1,*], $
                               kidpar[w1], templates, out_temp1, out_coeffs=out_coeffs, $
                               w8_source=myw8, /print_status
      flag[w1,*] = myflag

      
;         if param.interactive eq 1 then begin
;            toi_junk = toi
;            toi[w1,*] = residual
;            @quick_toi_plot_33.pro
;            stop
;
;            @quick_toi_plot_34.pro
;            message, /info, "just after all templates subtraction"
;            stop
;         endif

;;       if param.interactive eq 1 and iarray eq 1 then begin
;; ;         if !mydebug.subscan ge 7 and !mydebug.subscan le 9 then begin
;;          @quick_toi_plot_4.pro
;; ;      endif
;;       endif

;;       if param.interactive eq 1 then begin
;;          message, /info, "hello"
;;          numdet_ref = 2260
;;          ikid = where( kidpar.numdet eq numdet_ref)
;;          plot, toi[ikid,*], /xs
;;          j = where( kidpar[w1].numdet eq numdet_ref)
;;          plot, residual[j,*], /xs
;;          stop
;;       endif


      alpha = out_coeffs
      if param.show_toi_corr_matrix then corr_mat3 = abs(correlate(residual))

      ;;------------------------- Iteration loop ---------------------
      ;; Iterate on the determination of modes and simultaneous
      ;; decorrelation on all modes at the same time
      if param.niter_atm_el_box_modes gt 1 then begin
         ntemplates = n_elements(templates[*,0])
         all_out_common_modes = dblarr(param.niter_atm_el_box_modes, ntemplates, nsn)

         alpha_all = dblarr(nw1, 1+ntemplates, param.niter_atm_el_box_modes)
         alpha_all[*,*,0] = out_coeffs           

         iter = 0
         all_out_common_modes[iter,*,*]   = templates
         resid_rms = dblarr( param.niter_atm_el_box_modes, nw1)
         resid_rms[iter,*] = stddev(residual,dim=2)

         for iter=1, param.niter_atm_el_box_modes-1 do begin
            blabla = "Iterating on common modes: A"+strtrim(iarray,2)+" iter "+strtrim(iter,2)+"/"+strtrim(param.niter_atm_el_box_modes-1,2)
            if param.log then nk_log, info, blabla
            message, /info, blabla
            
            ;; Build new estimates of common modes with out_coeffs and TOI's
            ata = alpha##transpose(alpha)
            atam1 = invert(ata)
            atd = toi[w1,*]##transpose(alpha)
            out_common_modes = transpose(atam1##transpose(atd))
            
            all_out_common_modes[iter,*,*] = out_common_modes[1:*,*,*]
            
            residual = toi[w1,*]
            templates = out_common_modes[1:*,*] ; get rid of the constant terms for "regress.pro"
            ;; Use nk_subtract_templates_3 to determine alpha at each
            ;; iteration and take the last decorrelation when we exit
            ;; this loop.
            myflag = flag[w1,*]
            nk_subtract_templates_3, param, info, residual, myflag, off_source[w1,*], $
                                     kidpar[w1], templates, out_temp1, out_coeffs=alpha, w8_source=myw8
            alpha_all[*,*,iter] = alpha
            flag[w1,*] = myflag

            resid_rms[iter,*] = stddev(residual,dim=2)
            if param.show_toi_corr_matrix then begin
               junk = execute("corr_mat"+strtrim(iter+3,2)+" = abs(correlate(residual))")
            endif
         endfor
      endif
      if defined(alpha_all) then junk = execute( "alpha_all_"+strtrim(iarray,2)+" = alpha_all")

      ;; update correlation coeffs to atm
      kidpar[w1].corr2cm = alpha[*,1]

      ;;================================================================================================
      ;;========================================= PLOTS ================================================
      ;;================================================================================================

;      if param.do_plot and param.show_decorr_residuals then begin
;         @nk_imcm_decorr_aux_plot1
;      endif
;      if param.do_plot and param.show_mode_convergence then begin
;         @nk_imcm_decorr_aux_plot2
;      endif
;;      if param.do_plot and param.show_toi_corr_matrix then begin
;;         @nk_imcm_decorr_aux_plot3
;;         stop
;;      endif

      ;;---- Final successive decor per subband to test
      delvarx, myw8
      do_last_subband_decor = 0 ; default
      if param.common_mode_subband_1mm eq 1 and (iarray eq 1 or iarray eq 3) then do_last_subband_decor = 1
      if param.common_mode_subband_2mm eq 1 and (iarray eq 2)                then do_last_subband_decor = 1

      if do_last_subband_decor eq 1 then begin
         if param.log then nk_log, info, "decorr each KID from the common mode of its subband for A"+strtrim(iarray,2)
         subband1 = kidpar[w1].numdet/80 ; int division on purpose
         b = subband1[ uniq( subband1, sort(subband1))]
         nb = n_elements(b)
         for ib=0, nb-1 do begin
            wb = where( subband1 eq b[ib], nwb)
            ;;            if b[ib] eq 7 then begin
            ;;            if b[ib] eq 9 then begin
            ;;               stop
            ;;               wind, 1, 1, /f
            ;;               make_ct, nwb, ct
            ;;               plot, toi[w1[wb[0]],*], /xs, yra=array2range(toi[w1[wb],*]), /ys
            ;;               for iii=0, nwb-1 do oplot, toi[w1[wb[iii]],*], col=ct[iii]
            ;;               print, w1[wb]
            ;;               stop
            ;;            endif
            if nwb ge nwbmin then begin ; otherwise, no common mode and no decorrelation are possible
               if defined(w8_source) then myw8 = w8_source[w1[wb],*]
               myflag = flag[w1[wb],*]
               nk_get_cm_sub_2, param, info, residual[wb,*], myflag, $
                                off_source[w1[wb],*], kidpar[w1[wb]], subband_cm, w8_source=myw8
               junk_b = residual[wb,*]
               flag[w1[wb],*] = myflag

               myflag = flag[w1[wb],*]
               nk_subtract_templates_3, param, info, junk_b, myflag, off_source[w1[wb],*], $
                                        kidpar[w1[wb]], subband_cm, out_cm, w8_source=myw8
               flag[w1[wb],*] = myflag
               residual[wb,*] = junk_b
               out_temp1[wb,*] += out_cm
               delvarx, myw8, myflag

;;                for iii=0, nwb-1 do begin
;;                   if 1.d0/stddev(residual[wb[iii],*])^2 gt 1d5 then begin
;;                      message, /info, "HERE"
;;                      print, b[ib], iii, 1.d0/stddev(residual[wb[iii],*])^2
;; stop
;;                   endif
;;                endfor

;               print, b[ib], nwb

            endif
         endfor
      endif

      ;;--------------------- End of Iteration loop on modes
      ;;                      ---------------------
      toi_out[w1,*] = residual
      out_temp[w1,*] = out_temp1

   endif ; nw1 /= 0
endfor   ; loop over arrays


;; save, alpha_1, alpha_2, alpha_3, file=param.output_dir+"/alpha_all.save"

;; if param.plot_ps eq 0 and param.plot_z eq 0 then wind, 1, 1, /free, /large
;; array_col = [70, 250, 100]
;; psym = -8
;; syms = 0.5
;; outplot, file=param.project_dir+'/Plots/corr2cm_to_calib_fix_fwhm_'+param.scan, $
;;          png=param.plot_png, ps=param.plot_ps, z=param.plot_z
;; for iarray=1, 3 do begin
;;    w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1)
;;    if iarray eq 1 then nika_title, info, /all else title=''
;; 
;;    ;; full scan corr2cm
;;    my_multiplot, 3, 2, pp, pp1, /rev, gap_x=0.05
;;    np_histo, kidpar[w1].corr2cm, position=pp[iarray-1,0,*], $
;;              /noerase, /fill, fcol=array_col[iarray-1], /fit, title=title, $
;;              xtitle='full scan corr2cm'
;;    legendastro, ['A'+strtrim(iarray,2), $
;;                  'full scan corr2cm']
;; 
;;    ;; ratio to calib_fix_fwhm, renorm to averages to see relative
;;    ;; variations
;;    a = kidpar[w1].corr2cm       /avg( kidpar[w1].corr2cm)
;;    b = kidpar[w1].calib_fix_fwhm/avg( kidpar[w1].calib_fix_fwhm)
;;    yra = [-1,1]*3
;;    plot, a/b, $
;;          /noerase, position=pp[iarray-1,1,*], psym=psym, syms=syms, $
;;          ytitle='full scan corr2cm/calib_fix_fwhm', yra=yra, /ys, /xs
;;    oplot, a/b, col=array_col[iarray-1], psym=psym, syms=syms
;;    legendastro, 'A'+strtrim(iarray,2), textcol=array_col[iarray-1]
;; endfor
;; outplot, /close, /verb

;; nk_show_toi_corr_matrix, param, info, toi_out, kidpar, imrange=imrange_corr_mat, /subbands, /abs
;; stop

;; ;; @ update kidpar.calib_fix_fwhm with corr2cm if requested
;; stop
;; if param.recal_on_atm eq 1 then begin
;;    for iarray=1, 3 do begin
;;       w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1)
;;       a = kidpar[w1].corr2cm       /avg( kidpar[w1].corr2cm)
;;       b = kidpar[w1].calib_fix_fwhm/avg( kidpar[w1].calib_fix_fwhm)
;;       w = where( a/b gt 0, nw, compl=wcompl, ncompl=nwcompl)
;;       kidpar[w1[w]].calib_fix_fwhm *= (a/b)[w]
;;       if nwcompl ne 0 then kidpar[w1[wcompl]].type = 3
;;    endfor
;; endif

if param.cpu_time then nk_show_cpu_time, param

end
