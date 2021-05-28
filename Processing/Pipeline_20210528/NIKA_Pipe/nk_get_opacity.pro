;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_get_opacity
;
; CATEGORY: general
;
; CALLING SEQUENCE:
;         nk_get_opacity, param, info, data, kidpar
; 
; PURPOSE: 
;        Computes current opacity.
; 
; INPUT: 
;        - param: the reduction parameters structure
;        - info: an information structure to be filled
;        - data: the general NIKA strucutre containing time ordered information
;        - kidpar: the general NIKA structure containing kid related information
; 
; OUTPUT: 
;        - data: data.toi is modified
;        (only if method is do_opacity_correction=2)
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - 17/03/2014: creation (Nicolas Ponthieu & Remi Adam -
;          adam@lpsc.in2p3.fr) from (old nika_pipe_opacity.pro and nika_pipe_calib.pro)
;          02/2015: FXD renew_df=2 method
;        - 05/2015: AR simpar added

pro nk_get_opacity, param, info, data, kidpar, simpar=simpar

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_get_opacity param, info, data, kidpar"
   return
endif
routine = "nk_get_opacity"

if param.cpu_time then param.cpu_t0 = systime(0, /sec)

kidpar.tau_skydip = 0.d0 ; init
;; if keyword_set(simpar) then begin
;;    opacity_1mm = simpar.atm_tau1mm
;;    opacity_2mm = simpar.atm_tau2mm
;;    message, /info, 'Opacity simulated at 1mm: '+ strtrim(opacity_1mm, 2)
;;    message, /info, 'Opacity simulated at 2mm: '+ strtrim(opacity_2mm, 2)
;; 
;;    ;; update kidpar
;;    m1 = where( kidpar.array eq 1)
;;    m2 = where( kidpar.array eq 2)
;;    kidpar[m1].tau_skydip = opacity_1mm
;;    kidpar[m2].tau_skydip = opacity_2mm
;; 
;; endif else begin

if param.do_opacity_correction eq 0 then return
;;-----------------------------------------------------------

nsn  = n_elements(data)
nkid = n_elements(kidpar) 

;help, !nika.run
;stop
if long(!nika.run) eq 5 then begin
   ;; Apply patch for run 5 if necessary
   nk_run5_opacity_patch, param, info, data, kidpar
endif else begin
   if param.renew_df le 1 then begin ; Old method
      w    = where( data.el ne 0)
      am = mean(1./sin( data[w].el),/nan)
      
      T_atm   = 270.
      ind     = where(abs(kidpar.c0_skydip) gt 0, nind)
      if nind eq 0 then begin
         if param.rta eq 1 then begin
            kidpar.tau_skydip =  0.d0 ; bypass, no prob for RTA
            goto, ciao
         endif else begin
            nk_error, info, "All kids have c0_skydip=0"
            if param.silent eq 0 then message, /info, info.error_message
            return
         endelse
      endif
      
      df_tone = data.df_tone
      f_tone  = data.f_tone  
      
      for i=0, n_elements(ind)-1 do begin
         ikid = ind[i]
         ;; c0 = abs(mean(f_tone(ikid,shi:nsn-shi)) + $
         ;;          mean(df_tone(ikid,shi:nsn-shi)) - $
         ;;          abs(kidpar[ikid].c0_skydip))
         c0 = abs(median(f_tone(ikid,*)) + $
                  median(df_tone(ikid,*)) - $
                  abs(kidpar[ikid].c0_skydip))
         c1 = kidpar[ikid].c1_skydip*T_atm
         if (c0/c1) lt 1 and (c0/c1) ge 0 then kidpar[ikid].tau_skydip = -1.*(1./am*alog(1.-c0/c1))
      endfor   
      ;; Compute tau at both wavelengths
      for lambda=1, 2 do begin
         wkids = where( kidpar.array eq lambda and kidpar.tau_skydip ne 0.d0, nwkids)
         if nwkids lt 5 then begin
            if not keyword_set( silent) then $
               message, /info, "Not enough valid measurements of tau at "+ $
                        strtrim(lambda,2)+" mm (or only one band in the data) ?!"
         endif else begin
            np_histo, kidpar[wkids].tau_skydip, x, y, gpar, bin=bin, /fit, /noplot, /noprint
            
            ;; Put the same tau to all kids for the current lambda
            wlambda = where( kidpar.array eq lambda)
            gpar[1] = gpar[1]>0 ; truncate to avoid amplifying light (FXD)
            kidpar[wlambda].tau_skydip = gpar[1]
            if lambda eq 1 then info.result_tau_1mm = gpar[1] else info.result_tau_2mm = gpar[1]
            if not param.silent  then $
               message,/info,'======= Opacity found at '+strtrim(lambda,2)+'mm :'+num2string(gpar[1])
            if lambda eq 1 then info.result_tau_1mm = gpar[1] else info.result_tau_2mm = gpar[1]
         endelse
      endfor
   endif else begin
;;========================================= renew_df=2 method ===========================================
      scansub= where( $
               data.subscan gt 0 and $
               data.scan_valid[0] eq 0 and $
               data.scan_valid[1] eq 0 and $
               data.el gt 0, nscansub)
      am = 1./sin( data[ scansub].el)
      taumed = dblarr( nkid)
      rms = taumed
      ; default opacity correction is one
      opacorrall = fltarr( n_elements( data), nkid)+1.
      tauall     = opacorrall*0.d0
      gk = where( kidpar.type eq 1 and kidpar.c0_skydip lt 0 $
                  and kidpar.c1_skydip gt 0, ngk)
      if ngk eq 0 then begin
         if param.rta eq 1 then begin
            kidpar.tau_skydip =  0.d0 ; bypass, no prob for RTA
            goto, ciao
         endif else begin
            nk_error, info, "All kids have c0_skydip=0"
            if param.silent eq 0 then message, /info, info.error_message
            return
         endelse
      endif
      nmedopa = param.median_continuous_opa_samples ; should be 101 typically
      for idt = 0, ngk-1 do begin
         idet = gk[ idt]

         ;; Mask out the source to try
         if param.mask_source_opacity eq 1 then begin
            scansub= where( $
                     data.subscan gt 0 and $
                     data.scan_valid[0] eq 0 and $
                     data.scan_valid[1] eq 0 and $
                     data.el gt 0 and data.off_source[idet] eq 1, nscansub)
            am = 1./sin( data[ scansub].el)
            message, /info, "There's a median and a comment about this already below"
            message, /info, "check this"
            message, /info, "compute an opacity correction for A1 and A3 independently too"
         endif
         
         taufit2, am, data[ scansub].f_tone[ idet]+ $
                  data[scansub].df_tone[ idet], $
                  -kidpar[ idet].c0_skydip, $
                  kidpar[ idet].c1_skydip, $
                  taumedk, taumeank, frfit, rmsk, $
                  opacorr = opacorr, /silent, tau=taudet
         taumed[ idet] = taumedk
         rms[ idet] = rmsk
         ; avoid point sources
         if nmedopa gt 2 then begin
            opacorrall[ scansub, idet] = median( opacorr, nmedopa < (n_elements( opacorr)/2))
            tauall[scansub,idet]       = median( taudet, nmedopa < (n_elements( opacorr)/2))
         endif else begin
            opacorrall[ scansub, idet] = opacorr
            tauall[scansub,idet]       = taudet
         endelse
      endfor


      goodkid = where( rms gt 0)
      gkid1 = where( kidpar.type eq 1 and kidpar.lambda lt 1.5 $
                     and rms gt 0, ngkid1)
      gkida1 = where( kidpar.type eq 1 and kidpar.array eq 1 $
                     and rms gt 0, ngkida1)
      gkida3 = where( kidpar.type eq 1 and kidpar.array eq 3 $
                     and rms gt 0, ngkida3)
      gkid2 = where( kidpar.type eq 1 and kidpar.lambda gt 1.5 $
                     and rms gt 0, ngkid2)
      kid1 = where( kidpar.type eq 1 and kidpar.lambda lt 1.5, nkid1)
      kida1 = where( kidpar.type eq 1 and kidpar.array eq 1, nkida1)
      kida3 = where( kidpar.type eq 1 and kidpar.array eq 3, nkida3)
      kid2 = where( kidpar.type eq 1 and kidpar.lambda gt 1.5, nkid2)
      if ngkid1 lt 5 then begin
         if not keyword_set( silent) then $
            message, /info, 'Not enough valid measurements of tau at '+ $
                     '1 mm (or only one band in the data, or skydip coefficients are wrong) ?!'
         tau1 = 0               ; Default value
         taua1 = 0          
         taua3 = 0          
      endif else begin 
         tau1 = median( taumed[ gkid1])
         disptau1 = stddev( taumed[ gkid1])
; Some kids can perturb the mean (for high opacity case), so opt for
; the median (FXD 27/8/2020) which is more robust, Case in hand: scan = '20170424s58'
         opacorr1 = median( opacorrall[*, gkid1], dim = 2)
;;;         opacorr1 = mean( opacorrall[*, gkid1], dim = 2)
; all kids at 1mm will be corrected with the same opacity correction
         tau1alt = alog(median(opacorr1)) / median(am)

         if ngkida1 gt 5 then begin
            taua1 = median( taumed[ gkida1])
            disptaua1 = stddev( taumed[ gkida1])
            opacorra1 = median( opacorrall[*, gkida1], dim = 2)
;;;;            opacorra1 = mean( opacorrall[*, gkida1], dim = 2)
            taua1alt = alog(median(opacorra1)) / median(am)
         endif else begin
            taua1     = 0.d0
            disptaua1 = 0.d0
            opacorra1 = 0.d0
            taua1alt  = 0.d0
         endelse

         if ngkida3 gt 5 then begin
            taua3 = median( taumed[ gkida3])
            disptaua3 = stddev( taumed[ gkida3])
            opacorra3 = median( opacorrall[*, gkida3], dim = 2)
;;;;;            opacorra3 = mean( opacorrall[*, gkida3], dim = 2)
            taua3alt = alog(median(opacorra3)) / median(am)
         endif else begin
            taua3     = 0.d0
            disptaua3 = 0.d0
            opacorra3 = 0.d0
            taua3alt  = 0.d0
         endelse
;; Put the same tau to all kids for the 1mm
         wlambda = where( kidpar.lambda lt 1.5)
         kidpar[wlambda].tau_skydip = tau1
         info.result_tau_1mm = tau1
         info.result_tau_1 = taua1
         info.result_tau_3 = taua3
;;         if not param.silent  then $
;;            message,/info, $
;;                    '=== Zenith opacity, 2 methods, and disp. found at 1 mm: '+ $
;;                    strjoin( string( tau1, tau1alt, disptau1, format = '(3F8.3)'))

         ;;---------------------------------------
         ;; Apply the opacity correction to TOIS
         if param.do_opacity_correction eq 2 then $
            data.toi[kid1] *= opacorr1 ## (dblarr( nkid1)+1)
         if (param.do_opacity_correction eq 4 or $
             param.do_opacity_correction eq 5) then begin
            if nkida1 gt 0 then data.toi[kida1] *= opacorra1 ## (dblarr( nkida1)+1)
            if nkida3 gt 0 then data.toi[kida3] *= opacorra3 ## (dblarr( nkida3)+1)
         endif
         if (param.do_opacity_correction eq 6) then begin
            ;; apply the correction to tau1 derived in the
            ;; commissioning report
            ;; Laurence's latest estimation, Oct. 25th, 2018
            ;; A1, A2, A3, A1&A3
            ;; a = [1.36d0, 1.03d0, 1.23d0, 1.27d0]
            if nkida1 gt 0 then data.toi[kida1] *= (opacorra1^1.36d0) ## (dblarr( nkida1)+1)
            if nkida3 gt 0 then data.toi[kida3] *= (opacorra3^1.23d0) ## (dblarr( nkida3)+1)
            if nkida1 gt 0 then kidpar[kida1].tau_skydip *= 1.36
            if nkida3 gt 0 then kidpar[kida3].tau_skydip *= 1.23
            info.result_tau_1mm = tau1  * 1.27d0
            info.result_tau_1   = taua1 * 1.36d0
            info.result_tau_3   = taua3 * 1.23d0
            disptau1            = disptau1 * 1.27d0
         endif
         ;;---------------------------------------
         
         if not param.silent  then $
            message,/info, $
                    '=== Zenith opacity, and dispersion at 1 mm: '+ $
                    strjoin( string( info.result_tau_1, disptau1, format = '(3F8.3)'))

      endelse
      if not param.silent  then $
         message,/info,'=== Zenith opacity measured at 225GHz     : '+  $
                 string( info.tau225, format = '(1F8.3)')
      if ngkid2 lt 5 then begin
         if not keyword_set( silent) then $
            message, /info, 'Not enough valid measurements of tau at '+ $
                     '2 mm (or only one band in the data) ?!'
         tau2 = 0               ; default value
      endif else begin 
         tau2 = median( taumed[ gkid2])
         disptau2 = stddev( taumed[ gkid2])
         opacorr2 = median( opacorrall[*, gkid2], dim = 2)
;;;;;         opacorr2 = mean( opacorrall[*, gkid2], dim = 2)
         ;; LP, May 2018, To be tested
         if param.do_opacity_correction eq 5 then begin
            ;; using tau A1
            ;;modified_atm_r = modified_atm_ratio(taumed[gkida1])##(dblarr(n_elements(data))+1)
            ;;extrapol_tau2am = modified_atm_r*alog(opacorrall[*,gkida1])
            ;; using tau A3
            if nkida3 gt 0 then begin
               modified_atm_r = modified_atm_ratio(taumed[gkida3], /use_taua3)##(dblarr(n_elements(data))+1)
               extrapol_tau2am = modified_atm_r*alog(opacorrall[*,gkida3])
               opacorr2 = mean( exp(extrapol_tau2am), dim=2)
            endif
         endif
         
; all kids at 2mm will be corrected with the same opacity correction
         tau2alt = alog(median(opacorr2)) / median(am)
         ;; Put the same tau to all kids for the 2mm
         wlambda = where( kidpar.lambda gt 1.5)
         kidpar[wlambda].tau_skydip = tau2
         info.result_tau_2mm = tau2
         info.result_tau_2 = tau2  ; identical

;;message, /info, "fix me:"
;;save, file='opacities_'+param.scan+'.save'
;;stop
         ;;---------------------------------------
         ;; Apply the opacity correction to TOIS
         if param.do_opacity_correction eq 2 or $
            param.do_opacity_correction eq 4 or $
            param.do_opacity_correction eq 5 then $
               data.toi[kid2] *= opacorr2 ## (dblarr( nkid2)+1)
         
         if param.do_opacity_correction eq 6 then begin
            ;; Laurence's latest estimation, Oct. 25th, 2018
            ;; A1, A2, A3, A1&A3
            ;; a = [1.36d0, 1.03d0, 1.23d0, 1.27d0]
            data.toi[kid2] *= (opacorr2^1.03d0) ## (dblarr( nkid2)+1)
            kidpar[kid2].tau_skydip *= 1.03
            info.result_tau_2mm = tau2*1.03
            info.result_tau_2   = tau2*1.03 ; identical
            disptau2            = disptau2*1.03
         endif

         if not param.silent then $
            message,/info, $
                    '=== Zenith opacity, and dispersion at 2 mm: '+ $
                    strjoin( string( info.result_tau_2, disptau2, format = '(3F8.3)'))

         
      endelse

;       if param.do_plot eq 1 then $
          ;nk_check_tau_variations, param, info, data, kidpar, $
          ;                         tauall, taua1, tau2, taua3, $
          ;                         opacorrall, opacorra1, opacorr2, opacorra3
          ;stop
          
   endelse                      ; end case of renew df =2


endelse                         ; end case of all runs after the 5th
;; endelse
ciao:
if param.cpu_time then nk_show_cpu_time, param

end
