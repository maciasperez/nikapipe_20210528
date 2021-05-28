
;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_mdc
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

pro nk_mdc, param, info, kidpar, toi, flag, off_source, elevation, $
                    toi_out, out_temp, snr_toi=snr_toi, out_coeffs=out_coeffs
;-

if n_params() lt 1 then begin
   dl_unix, 'nk_mdc'
   return
endif

if param.cpu_time then param.cpu_t0 = systime(0, /sec)

nsn = n_elements( toi[0,*])

;; Compute w8_source once for all
if defined(snr_toi) then begin
   w8_source=1.d0/(1.d0+param.k_snr_w8_decor*snr_toi^2)
endif

if param.decor_from_atm eq 1 and param.atm_per_array eq 0 then begin
   txt = "Not updated for nk_mdc, still copy and paste from nk_imcm_decorr"
   nk_error, info, txt
   return
;;   
;;;; 1. Estimate atmosphere from all KIDs (both 1 and 2mm)
;;   if param.log then nk_log, info, "Derive atm_cm from ALL valid kids (1 & 2mm)"
;;   w1 = where( kidpar.type eq 1, nw1)
;;   if defined(w8_source) then myw8 = w8_source[w1,*]
;;   myflag = flag[w1,*]
;;   nk_get_cm_sub_2, param, info, toi[w1,*], myflag, $
;;                    off_source[w1,*], kidpar[w1], atm_cm, $
;;                    w8_source=myw8
;;   flag[w1,*] = myflag ; update flags
;;   delvarx, myw8, myflag
endif

;;----------------- Loop over arrays for eletronics related modes -----------------
nkids    = n_elements(kidpar)
toi_out  = dblarr(nkids,nsn)
out_temp = dblarr(nkids,nsn)

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

            ;; 1st rough estimate with all valid kids
            nk_get_cm_sub_2, param, info, toi[w1,*], myflag, $
                             off_source[w1,*], kidpar[w1], atm_cm, $
                             w8_source=myw8

            ;; Look for tiny glitches that have not been detected on
            ;; individual TOI's
            if param.deglitch_atm_cm eq 1 then begin
               sigma2cm = dblarr(n_elements(kidpar)) - 1 ; init to negative to make ensure the "where sigma gt ..."
               for i=0, nw1-1 do begin
                  ikid = w1[i]
                  woff = where( off_source[ikid,*] eq 1, nwoff)
                  fit = linfit( atm_cm[woff], toi[ikid,woff])
                  y = toi[ikid,woff] - fit[0] - fit[1]*atm_cm[woff]
                  np_histo, y, xh, yh, gpar, /fit, /noplot, /noprint, /force
                  sigma2cm[ikid] = gpar[2]
                  w = where( abs(y-avg(y)) gt 3*gpar[2], nw)
                  ;; Take margin w.r.t to pure gaussian noise that
                  ;; would call for only 1% data at more than 3sigma
                  if float(nw)/nwoff gt 0.02 then kidpar[ikid].type=12
               endfor
               ;; flag out noisy kids as well
               np_histo, sigma2cm[w1], xh, yh, gpar, /fit, /force, /noprint, /noplot
               ww = where( sigma2cm gt (gpar[1]+3*gpar[2]), nww)
               if nww ne 0 then kidpar[ww].type = 12

               junk = where(kidpar.type eq 12, njunk) ;  or sigma2cm gt (gpar[1]+3*gpar[2]), njunk)
               message, /info, "rejected "+strtrim(njunk,2)+"/"+strtrim(nw1,2)+" kids for array "+strtrim(iarray,2)+" to derive atm_cm"

;               wind, 1, 1, /free, /large
;               !p.multi=[0,1,2]
;               np_histo, sigma2cm, xh, yh, gpar, /fit, /force
;               plot, sigma2cm, /xs
;               oplot, sigma2cm*0 + gpar[1] + 3*gpar[2]
;               oplot, sigma2cm*0 + gpar[1] - 3*gpar[2]
;               !p.multi=0
;stop

               ;; Improved derivation of the atmosphere template
               if defined(w8_source) then myw8 = w8_source[w1,*]
               myflag = flag[w1,*]
               if defined(w8_source) then myw8 = w8_source[w11,*]
               w11 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw11)
               nk_get_cm_sub_2, param, info, toi[w11,*], myflag, $
                                off_source[w11,*], kidpar[w11], atm_cm1, $
                                w8_source=myw8

;;               wind, 1, 1, /free, /large
;;               plot, cm, /xs, /ys
;;               oplot, atm_cm1, col=250

               ;; Deglitch the common mode and apply to all kids
               qd_deglitch, atm_cm1, param.glitch_width, param.glitch_nsigma, atm_cm_out, flag0, $
                            deglitch_nsamples_margin=param.deglitch_nsamples_margin
               wflag = where( flag0 ne 0, nwflag, compl=wk)
               flag_temp = flag*0 ; to match size(TOI)
               flag_temp[w1,*]  = myflag
               if nwflag ne 0 then begin
                  wa = where( kidpar.array eq iarray, nwa)
                  ;index = lindgen(n_elements(toi[0,*]))
                  for i=0, nwa-1 do begin
                     if kidpar[i].type eq 1 or kidpar[i].type eq 12 then begin
                        flag_temp[i,wflag] = 1
                        y = toi[i,*]
                        y_smooth = smooth(y,long(!nika.f_sampling),/edge_mirror)
                        
                        sigma = stddev( y-y_smooth)
                        y[wflag] = y_smooth[wflag] + randomn( seed, nwflag)*sigma

                        ;; if kidpar[i].numdet eq 2826 then begin
                        ;;    plot,  index, toi[i,*], /xs, xra=[4800,5000]
                        ;;    oplot, index, y_smooth, col=150
                        ;;    oplot, index, y, psym=1, col=250
                        ;;    stop
                        ;; endif
                        toi[i,*] = y
                     endif
                  endfor
               endif

               ;; update flags
               myflag = flag_temp[w1,*]

               ;; Update atm_cm for the rest of this routine
               atm_cm = atm_cm_out

               ;; Now that atm_cm has been derived with the "best"
               ;; kids, restore kidpar.type to try to save the
               ;; outliers with their box or subband modes.
               w12 = where(kidpar.type eq 12, nw12)
               if nw12 ne 0 then kidpar[w12].type = 1

               ;; make_ct, nw1, ct
               ;; for i=0, nw1-1 do begin &$
               ;;    fit = linfit( atm_cm1, toi[w1[i],*]) &$
               ;;    oplot, (toi[w1[i],*]-fit[0])/fit[1], col=ct[i] &$
               ;; endfor
            endif

            ;; Upate flags
            flag[w1,*] = myflag

            delvarx, myw8, myflag
         endif

         if param.include_elevation_in_decor_templates eq 1 then begin
            which_templates = 'elevation, atm'
            if param.log then nk_log, info, "add elevation in the list of decorrelation templates"
            atm_temp = dblarr(2,nsn)
            atm_temp[0,*] = atm_cm
            atm_temp[1,*] = elevation
         endif else begin
            which_templates = 'atm'
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
         flag[w1,*] = myflag ; update flags 
         delvarx, myw8, myflag

;;         if param.interactive eq 1 then begin
;;            toi_junk = toi
;;            toi[w1,*] = residual
;;;;            @quick_toi_plot_33.pro
;;            @quick_toi_plot_subbands.pro
;;            stop
;;            toi = toi_junk
;;            message, /info, "just after atm_cm subtraction"
;;            stop
;;         endif
      endif

      if param.show_toi_corr_matrix then begin
         corr_mat0 = abs(correlate( toi[w1,*]))
         corr_mat1 = abs(correlate( residual))
      endif

      ;;============== nk_get_corr_block_2 =================
      mcorr = correlate( residual)
      wnan  = where(finite(mcorr) ne 1, nwnan)
      if nwnan ne 0 then mcorr[wnan] = -1

      kid2kid_dist = dblarr(nw1,nw1)
      for i=0, nw1-1 do begin
         for j=0, nw1-1 do begin
            kid2kid_dist[i,j] = sqrt( (kidpar[w1[i]].nas_x-kidpar[w1[j]].nas_x)^2 + $
                                      (kidpar[w1[i]].nas_y-kidpar[w1[j]].nas_y)^2)
         endfor
      endfor

;;      corr_thres   = 0.5
;;      kid_min_dist = 30. ; arcsec
;;      ;; make a copy of residual here otherwise it is changed in the
;;      ;; loop over KIDs and kids are therefore not decorrelated from
;;      ;; the correct timelines.
;;      residual_copy = residual
;;      ;; decorrelate KIDs that actually are correlated to other
;;      ;; KIDs... leave the cleaning of the others for later.
;;
;;      stop
;;
;;
;;;;      for i=0, nw1-1 do begin
;;;;         print, strtrim(i,2)+"/"+strtrim(nw1-1,2)
;;;;         w1k = where( abs(mcorr[i,*]) ge corr_thres and kid2kid_dist[i,*] gt kid_min_dist, nw1k)
;;;;         if nw1k ne 0 then begin
;;;;            measure_errors = nk_stddev(residual_copy[w1k,*], dim=2)
;;;;            coeffs = regress( residual_copy[w1k,*], reform(residual[i,*]), $
;;;;                              CHISQ= chi, CONST= const, CORRELATION= corr, measure_errors=measure_errors, $
;;;;                              /DOUBLE, FTEST=ftest, SIGMA=sigma, STATUS=status)
;;;;            residual[i,*] -= (const + residual_copy[w1k,*]##coeffs)
;;;;         endif
;;;;      endfor
;;;;

      mcorr = correlate( residual)
      wnan  = where(finite(mcorr) ne 1, nwnan)
      if nwnan ne 0 then mcorr[wnan] = -1
      
      residual_copy = residual
      kid2kid_dist_min = 30. ; place holder
      for i=0, nw1-1 do begin
         print, strtrim(i,2)+"/"+strtrim(nw1-1,2)

         ;; Search for best set of KIDs to be used for deccorelation
         corr = reform(mcorr[i,*])
         
         ;; Do not consider KIDs that are too close to avoid filtering
         ;; out the source
         wdist = where( kid2kid_dist[i,*] lt kid2kid_dist_min, nwdist)
         if nwdist ne 0 then corr[wdist] = -1
   
         ;; Sort by order of maximum correlation
         s_corr = corr[reverse(sort(corr))]
   
         ;; First block with the requested min number of KIDs
         block = where(corr gt s_corr[param.n_corr_block_min+1] and corr ne 1, nblock)
         
         ;; Determine the common mode of this block
         nk_get_cm_sub_2, param, info, residual_copy[block,*], flag[w1[block],*], off_source[w1[block],*], kidpar[w1[block]], cm
         
         ;; subtract from the current kid
         fit = linfit( cm, residual[i,*])
         residual[i,*] -= (fit[0] + fit[1]*cm)
      endfor

      if param.show_toi_corr_matrix then begin
         corr_mat2 = abs(correlate( residual))
         wind, 1, 1, /free, /large
         my_multiplot, 2, 2, pp, pp1, /rev
         imview, abs(corr_mat0), position=pp1[0,*], imrange=[0,1], title='raw A'+strtrim(iarray,2)
         imview, abs(corr_mat1), position=pp1[1,*], imrange=[0,1], title='atm subtracted', /noerase
         imview, abs(corr_mat2), position=pp1[2,*], imrange=[0,1], title='multi decorr', /noerase
         stop
      endif
      ;;===============================

   endif
endfor

if param.cpu_time then nk_show_cpu_time, param

end
