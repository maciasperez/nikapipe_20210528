;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_get_cm_sub_2
;
; CATEGORY: toi processing, subroutine of nk_get_cm
;
; CALLING SEQUENCE:
;
; 
; PURPOSE: 
;        Derives a common mode from all the input kids. Same as nk_get_cm_sub,
;but instead of cross calibrating kids on the first valid kid, I now cross
;calibrate on the median common mode.
; 
; INPUT: 
; 
; OUTPUT: 
;        - common_mode: an average common mode computed from the input
;          toi
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Nov. 16th, 2014: (Nicolas Ponthieu & Remi Adam - adam@lpsc.in2p3.fr)


pro nk_get_cm_sub_2, param, info, toi, flag, off_source, kidpar, common_mode, $
                     w8_source_in=w8_source_in, leg_txt=leg_txt, output_kidpar=output_kidpar, $
                     cm_iter_max=cm_iter_max
;-

if n_params() lt 1 then begin
   dl_unix, 'nk_get_cm_sub_2'
   return
endif

if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

nsn           = n_elements( toi[0,*])
nkids         = n_elements( toi[*,0])
output_kidpar = kidpar

wjunk = where( finite(output_kidpar.noise) eq 0 and output_kidpar.type eq 1, nw)
if nw ne 0 then begin
   nk_error, info, "There are NaN's in kidpar.noise", silent=param.silent
   return
endif

; FXD, July 2020: flag should be reset at each iteration
flagin = flag

;; Cross-calibration common mode
;; median_common_mode = median( toi, dim=1)

;; ;; not used anymore at this stage ?
;; nk_get_median_common_mode, param, info, toi, flag, $
;;                            off_source, kidpar, median_common_mode

;; if param.interactive eq 1 then begin
;;    w1 = where( kidpar.type eq 1, nw1)
;;    make_ct, nw1, ct
;;    yra = [-5,5]
;;    xra = [3500,4500] ; [5200, 5600]
;;    plot, toi[w1[0],*]-toi[w1[0],0], /xs, /ys, xra=xra, yra=yra
;;    for i=0, nw1-1 do oplot, toi[w1[i],*]-toi[w1[i],0], col=ct[i]
;;    oplot, median_common_mode-median_common_mode[0], thick=2
;;    if keyword_set(leg_txt) then legendastro, leg_txt
;;    stop
;; endif

;; Possibility to have a smoother weighting than just 0/1 on/off
;; source
;;w8_source = off_source
if keyword_set(w8_source_in) then begin
   include_measure_errors = 1
   w8_source = w8_source_in
endif else begin
   include_measure_errors = 0
   w8_source = off_source
endelse


n_outlyers = 1 ; init
iter = 0
while n_outlyers ne 0 and iter le param.niter_cm do begin

   n_infinite  = 0
   n_outlyers  = 0 ; reset
   common_mode = dblarr(nsn)
   w8          = dblarr(nsn)
   nhits_cm    = dblarr(nsn)

;; Cross-calibration common mode
;; median_common_mode = median( toi, dim=1)
   w1      = where( output_kidpar.type eq 1, nw1)
   r_res   = dblarr( nw1, 2)
   fit_res = dblarr( nw1,2)
   nk_get_median_common_mode, param, info, toi[w1,*], flag[w1,*], $
                              off_source[w1,*], output_kidpar[w1], median_common_mode, nkids_in_cm

   ;; Discard sections where there are not enough KIDs to trust the
   ;; common mode
   w = where( nkids_in_cm lt param.nmin_kids_in_cm, nw)
   if nw ne 0 then median_common_mode[w] = !values.d_nan

   if param.mydebug eq 0419 then begin
      wind, 1, 1, /free, /large
      ikid = w1[0]
      yra = minmax( toi[w1,*])
      make_ct, nw1, ct
      my_multiplot, 2, 4, pp, pp1, /rev
      plot, toi[ikid,*], /xs, /ys, position=pp[0,0,*], yra=yra, title='toi'
      for i=0, nw1-1 do oplot, toi[w1[i],*], col=ct[i]
      plot, median_common_mode, /xs, /ys, position=pp1[1,*], /noerase, title='median common mode'
   endif

            ;; Commented out NP, Nov. 27th, 2020
;;   flag = flagin  ; re-init
   for i=0, nw1-1 do begin
      ikid = w1[i]

      if output_kidpar[ikid].type eq 1 then begin
         ;; Keep the intersubscan samples, otherwise the common mode will
         ;; never be defined on both ends of subscans which would put
         ;; lots of NaN's in the TOIs.
         ;; These samples will not be projected in the end and may be
         ;; discarded during the decorrelation later on.
         ;;
         ;; wsample = where( off_source[ikid,*] ne 0 and $
         ;;                  finite(w8_source[ikid,*]) and $
         ;;                  w8_source[ikid,*] gt 0D0 and $ ; FXD added 17/08, OK?
         ;;                  (flag[ikid,*] eq 0 or flag[ikid,*] eq 2L^11), nwsample)
         ;; Keep glitch-flagged and interpolated samples at this
         ;; stage: otherwise, common glitches will create an
         ;; artificial hole in the common mode. In any case, these
         ;; flagged and interpolated samples are not very noisy when
         ;; averaged alltogether in the commone mode (NP, Nov. 28th, 2020)
         wsample = where( off_source[ikid,*] ne 0 and $
                          finite(w8_source[ikid,*]) and $
                          w8_source[ikid,*] gt 0D0 and $    ; FXD added 17/08, OK?
                          finite( median_common_mode) and $ ; added NP, Feb. 26th, 2021 (for nk_imcm_mask in particuler, method 676)
                          (flag[ikid,*] eq 0 or flag[ikid,*] eq 2L^11 or flag[ikid,*] eq 1), nwsample)

;;         wsample = where( off_source[ikid,*] ne 0, nwsample)
         
         if nwsample eq 0 then begin
            ;; do not project this KID for this (sub)scan
            flag[ikid,*] = 2L^7
            output_kidpar[ikid].type = 3
         endif else begin
            
            ;; Cross calibrate ikid on the median common mode
            if include_measure_errors then begin
               ;;measure_errors=1.d0/w8_source[ikid,wsample]
               ;; Take sqrt to be homogeneous to stddev and not
               ;; variance ! NP, Sept. 8th, 2020
               measure_errors = sqrt( 1.d0/w8_source[ikid,wsample])
            endif else begin
               delvarx, measure_errors
            endelse

            ;; use poly_fit rather than linfit to get a clear "status"
            ;; revert "x" and "y" to account for standard dev correctly
            ;; w.r.t the fitting routine.
            r = poly_fit( median_common_mode[wsample], toi[ikid,wsample], 1, $
                          measure_errors=measure_errors, status=status)
            if status ne 0 then begin
               n_infinite++
               flag[ikid,*] = 2L^7
               output_kidpar[ikid].type = 3
               ;; comment out NP march 2019: the kid may be unvalid just for
               ;; the current subscan due to masks but valid for the rest of
               ;; the scan => do not discard it completely at this stage.
               ;;kidpar[ikid].type = 3
            endif else begin
               fit = dblarr(2)
               fit[1] = 1.d0/r[1]
               fit[0] = -r[0]/r[1]
               if param.mydebug eq 1 or param.mydebug eq 0419 then begin
                  r_res[i,*]   = [r[0],r[1]]
                  myfit = linfit( median_common_mode[wsample], toi[ikid,wsample])
                  fit_res[i,*] = [myfit[0],myfit[1]]
               endif
               ;; add to common mode only if the sample is off source
               if tag_exist(kidpar,'corr2cm') then kidpar[ikid].corr2cm = fit[1]
               common_mode[wsample] += (fit[0] + fit[1]*toi[ikid,wsample])*w8_source[ikid,wsample]/kidpar[ikid].noise^2
               w8[         wsample] +=                                     w8_source[ikid,wsample]/kidpar[ikid].noise^2
               nhits_cm[   wsample] += 1.d0
               
               ;; wind, 1, 1, /free, /large
               ;; nplots = 3
               ;; p=0
               ;; xra = [0, n_elements(toi[0,*])]
               ;; my_multiplot, 1, nplots, pp, pp1, /rev
               ;; plot, toi[ikid,*], /xs, /ys, position=pp1[p,*], title=strtrim(ikid,2), xra=xra
               ;; oplot, wsample, toi[ikid,wsample], col=150
               ;; legendastro, ['toi '+strtrim(ikid,2), 'wsample'], textcol=[0,150]
               ;; p++
               ;; plot, w8_source[ikid,*], /xs, /ys, position=pp1[p,*], /noerase, yra=[0,2], xra=xra
               ;; oplot, w8 gt 0, col=250
               ;; legendastro, ['w8_source', 'sample w8'], col=[0,250]
               ;; p++
               ;; plot, common_mode, /xs, /ys, title=strtrim(ikid,2), position=pp1[p,*], /noerase, xra=xra
               ;; legendastro, 'current common mode'
               ;; stop
            endelse
         endelse
      endif
   endfor

   woutlyers = where( abs( r_res[*,0] - avg(r_res[*,0])) gt 5*stddev( r_res[*,0]) or $
                      abs( r_res[*,1] - avg(r_res[*,1])) gt 5*stddev( r_res[*,1]) or $
                      sign(r_res[*,1]) ne sign( avg(r_res[*,1])), n_outlyers)

   if param.silent eq 0 and n_infinite ne 0 then begin
      message,  /info, strtrim(n_infinite,2)+" kids could not be regressed on the common mode and have been discarded, " + param.scan
   endif

   if param.mydebug eq 0419 then begin
      plot, common_mode, /xs, /ys, position=pp[0,1,*], /noerase, title='common mode before /w8'
      plot, w8, /xs, /ys, position=pp[0,2,*], /noerase, title='w8'
      plot, nhits_cm, /xs, /ys, position=pp[0,3,*], /noerase, title='Nhits'
      stop
   endif

;; check for holes and average
   w = where( w8 eq 0 or nhits_cm lt param.nmin_kids_in_cm, nw, compl=wkeep, ncompl=nwkeep)
   info.COMMON_MODE_INTERPOLATED_SAMPLES = nw
   if nw eq 0 then begin
      ;; no holes, hence normalize everywhere
      common_mode /= w8
   endif else begin
      ;; holes, hence normalize only where I can divide by something != 0
      common_mode[wkeep] /= w8[wkeep]

      ;; If the user asked to interpol holes, then do it
      if param.interpol_common_mode then begin
         common_mode = interpol( common_mode[wkeep], wkeep, lindgen(n_elements(common_mode)))
      endif else begin
         ;; If you want to keep holes, then ok but I put NaN in holes
         if param.keep_holes_in_common_mode eq 1 then begin
            common_mode[w] = !values.d_nan
         endif else begin
            ;; If not, then return an error message and stop for safety
            nk_error, info, "There are "+strtrim(nw,2)+" holes in the derived common_mode"
            stop
            return
         endelse
      endelse
   endelse

   if param.mydebug eq 0419 then begin
      plot, common_mode, /xs, /ys, position=pp1[3,*], /noerase, title='common mode final'
      stop
   endif

   if n_outlyers ne 0 then begin
      output_kidpar[w1[woutlyers]].type = 3
      flag[w1[woutlyers],*] = 2L^7
      
      if param.mydebug eq 1 then begin
         wind, 1, 1, /free, /large
         my_multiplot, 3, 2, pp, pp1, /rev
         plot, common_mode, /xs, /ys, position=pp1[0,*], /noerase, title='iter_cm '+strtrim(iter,2)
         np_histo, r_res[*,0], /force, /fill, position=pp1[1,*], /noerase, fcol=150, /fit, /noprint
         plot, r_res[*,0], /xs, /ys, position=pp1[1,*], /noerase
         for i=-5, 0 do oplot, r_res[*,0]*0 + avg(r_res[*,0]) + i*stddev(r_res[*,0]), line=2, col=70
         for i=0, 5  do oplot, r_res[*,0]*0 + avg(r_res[*,0]) + i*stddev(r_res[*,0]), col=70
         legendastro, 'polyfit const'
         if n_outlyers ne 0 then oplot, [woutlyers], r_res[woutlyers,0], psym=8, col=250
         
         np_histo, r_res[*,1], /force, /fill, position=pp1[2,*], /noerase, fcol=150, /fit, /noprint
         plot, r_res[*,1], /xs, /ys, position=pp1[2,*], /noerase
         for i=-5, 0 do oplot, r_res[*,1]*0 + avg(r_res[*,1]) + i*stddev(r_res[*,1]), line=2, col=70
         for i=0, 5  do oplot, r_res[*,1]*0 + avg(r_res[*,1]) + i*stddev(r_res[*,1]), col=70
         legendastro, 'polyfit slope'
         if n_outlyers ne 0 then oplot, [woutlyers], r_res[woutlyers,1], psym=8, col=250
         
         plot, fit_res[*,0], /xs, /ys, position=pp1[3,*], /noerase
         legendastro, 'linfit const'
         w = where( abs( fit_res[*,0] - avg(fit_res[*,0])) gt 5*stddev( fit_res[*,0]), nw)
         if nw ne 0 then oplot, [w], fit_res[w,0], psym=8, col=70
         plot, fit_res[*,1], /xs, /ys, position=pp1[4,*], /noerase
         legendastro, 'linfit slope'
         w = where( abs( fit_res[*,1] - avg(fit_res[*,1])) gt 5*stddev( fit_res[*,1]), nw)
         if nw ne 0 then oplot, [w], fit_res[w,1], psym=8, col=70
      endif
   endif

   ;; Comment out NP, Nov. 27th, 2020: It hasn't been used this
   ;; way for ages and now, we'd rather discard outlyer KIDs
   ;; and restart from scratch the iteration
;;   ;; if we iterate on the common mode
;;   median_common_mode = common_mode
iter++
endwhile



end
