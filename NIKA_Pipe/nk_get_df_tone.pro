pro nk_get_df_tone, param, info, data, kidpar, param_d
;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_get_df_tone
;
; CATEGORY:
;
; CALLING SEQUENCE:
;         nk_get_df_tone, param, data, kidpar, param_d
; 
; PURPOSE: 
;        Routine to recompute the df_tone offline
;        the original raw_data df_tone may not be correct
;        First method uses raw data coefficients
;        Second method uses internal consistency with toi        
; 
; INPUT: 
;        - data: the nika data structure
; 
; OUTPUT: 
;        - data.df_tone is modified
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - 18 Nov. 2014: FXD
;        -    Feb. 2015: FXD, added new method + everything in Hz from now on
;        - 24/11/2016:   rewrote sections to remove loops on detectors (HR)
;                        (for non-skydip scans ; still to be done for skydips)
;-
;===============================================================================================

if param.cpu_time then param.cpu_t0 = systime( 0, /sec)

if param.renew_df ge 1 then begin ; computation for both cases: 1 and 2
; Compute the angle between i,q and di,dq +pi/2
   ang = nk_angleiq_didq(data)

; Renormalize frequencies
                                ; Fix for NIKA2 (fxd), it is the same for nika2
   coeff1mm = 1D0/1.4393

   ind = where( kidpar.type le 2,  nind)

   if param.renew_df eq 1 then begin
; Compute df_tone
      if nind ne 0 then begin
;;;         for idet = 0, nind-1 do $
;;;            data.df_tone[ ind[ idet]] = reform( ang[ ind[ idet], *] * $
;;;                                                (param_d[ ind[ idet]].width) )
         nsn = n_elements(data)
         data.df_tone[ind] = ang(ind, *) * rebin(param_d[ind].width, nind, nsn)
      endif
   endif

   if param.renew_df eq 2 then begin 
; Compute df_tone by correlation with TOI (Rf or Pf)
;      print, ':'+strupcase(strtrim(info.obs_type, 2)) +':'
      if nind ne 0 then begin
; All cases except skydip
         if strupcase(strtrim(info.obs_type, 2)) ne 'DIY' then begin
            scansub= where( $
                     data.subscan gt 0 and $
                     data.scan_valid[0] eq 0 and $
                     data.scan_valid[1] eq 0 and $ 
                     data.scan_valid[2] eq 0, nscansub)
;;;                     data.scan_valid[1] eq 0, nscansub)
; Renormalize frequencies

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; rewritten to avoid unnecessary loop:

            w = where(total(data[scansub].flag[ind] eq 0, 2) lt 3, cw)
            if cw gt 0 then kidpar[ind(w)].type = 3
            ind = where(kidpar.type le 2, nind)
            if nind ge 1 then begin
               wdet = where(stddev(data[scansub].toi[ind], dimension=2, /nan) gt 0., cdet)
               if cdet ge 1 then begin
                  wdet = ind(wdet)
                  arr_x = -data[scansub].toi[wdet]
                  w1mm = where(kidpar[wdet].lambda lt 1.5, c1mm)
                  if c1mm gt 0 then arr_x(w1mm, *) *= coeff1mm
                  arr_flag = data[scansub].flag[wdet]
                  arr_y = ang(wdet, *)
                  arr_y = arr_y(*, scansub)
                  coef_a = dblarr(cdet)
                  coef_b = dblarr(cdet)
                  for ikid = 0L, cdet - 1L do begin
                     w = where(arr_flag(ikid, *) eq 0)
                     linpar = linfit(arr_x(ikid, w), arr_y(ikid, w))
                     coef_a(ikid) = linpar(0)
                     coef_b(ikid) = linpar(1)
                  endfor
                  wgood = where(coef_b gt 1.D-6, cgood, complement=wdead, ncomplement=cdead)
                  if cgood gt 0 then begin
                     offset = -coef_a(wgood) / coef_b(wgood)
                     w1mm = where(kidpar[wdet(wgood)].lambda lt 1.5, c1mm)
                     if c1mm gt 0 then offset(w1mm) /= coeff1mm
                     nsn = n_elements(data)
                     ;;message, /info, "fix me: comment out the next line once"
                     ;;message, /info, "the large value of offset for N2R7 has been solved."
                     ;;message, /info, "NP. Dec. 9th, 2016"
                     data.toi[wdet(wgood)] += rebin(offset, cgood, nsn)
                     data.df_tone[wdet(wgood)] = ang(wdet(wgood), *) $
                                                 / rebin(coef_b(wgood), cgood, nsn)
                  endif
                  if cdead gt 0 then begin
                     data.df_tone[wdet(wdead)] = 0.
                     nk_add_flag, data, 16, wkid=wdet(wdead)
                  endif
               endif
            endif
            

;;;            for idet = 0, nind-1 do begin
;;;               idt = ind[ idet]
;;;               if kidpar[ idt].lambda lt 1.5 then $
;;;                  coeff = -coeff1mm else coeff = -1.
;;;               if stddev( data[ scansub].toi[ idt]) gt 0. then begin

            ;; ;;-----
            ;; wind, 1, 1, /free, /large
            ;; !p.multi=[0,1,3]
            ;; plot,  ang[idt,scansub], /xs
            ;; oplot, ang[idt,scansub], thick=3
            ;; 
            ;; plot,  coeff*data[ scansub].toi[idt], /xs
            ;; oplot, coeff*data[ scansub].toi[idt], thick=3
            ;; 
            ;; w = where( data[ scansub].flag[ idt] ne 0, nw, compl=wgood)
            ;; oplot, w, data[scansub[w]].toi[idt], psym=1, col=100
            ;; 
            ;; linpar = linfit( coeff*data[ scansub].toi[ idt], $
            ;;                  ang[ idt, scansub])
            ;; fit = linfit( coeff*data[ scansub[wgood]].toi[idt], ang[idt, scansub[wgood]])
            ;; plot, coeff*data[ scansub].toi[idt], ang[idt,scansub], psym=1, /xs, /ys
            ;; oplot, coeff*data[ scansub].toi[idt], linpar[0] + linpar[1]*coeff*data[ scansub].toi[idt], col=250
            ;; oplot, coeff*data[ scansub].toi[idt], fit[0] + fit[1]*coeff*data[ scansub].toi[idt], col=150
            ;; legendastro, [strtrim(linpar,2), strtrim(fit,2)], box=0
            ;; !p.multi=0
            ;; 
            ;; stop
            ;; ;;-----

            ;; Discard flagged data in the fit, NP. Sept. 20th, 2016
            ;; linpar = linfit( coeff*data[ scansub].toi[ idt], ang[ idt, scansub])
;;;                  w = where( data[ scansub].flag[idt] eq 0, nw)
;;;                  if nw lt 3 then begin
;;;                     kidpar[idt].type = 3
;;;                  endif else begin
;;;                     linpar = linfit( coeff*data[ scansub[w]].toi[ idt], ang[ idt, scansub[w]])
;;;                     if linpar[1] gt 1D-6 then begin
            ;; Correct the zero point of data.toi to match the df_tone zero point
;;;                        data.toi[ idt] = data.toi[ idt]+ linpar[0]/linpar[1]/coeff
            ;; Correct the df_tone to be calibrated as a toi in Hz
;;;                        data.df_tone[ idt] = reform( ang[ idt, *]) / (linpar[1])
;;;                     endif else begin
;;;                        data.df_tone[ idt] = 0.
;;;                        nk_add_flag, data, 16, wkid=idt
;;;                     endelse
;;;                  endelse
;;;               endif
;;;            endfor
            endif else begin
               
               if param.silent eq 0 then message, /info, 'Case of a skydip'
                                ; Case of a skydip
                                ; by default put undefined values
               data.df_tone = !values.d_nan
               nsub = max( data.subscan)
               nphase = max( data.nsotto)
               ind1 = where( kidpar.type eq 1 and kidpar.lambda lt 1.5,  nind1)
               ind2 = where( kidpar.type eq 1 and kidpar.lambda gt 1.5,  nind2)
               itotsotto = n_elements( data[0].nsotto)-1


;;               wind, 1, 1, /free, /large
;;               !p.multi=[0,1,3]
;;               nsn = n_elements(data)
;;               index = dindgen(nsn)
;;               plot, index, data.el, /xs, /ys, yra=[0, max(data.el)]
;;               oplot, index, float(data.nsotto[itotsotto,*])/max(data.nsotto[itotsotto,*]), col=70
;;               legendastro, ['elevation', 'data.nsotto[itotsotto,*] (norm.)'], textcol=[!p.color, 70]
;;
;;               w1 = where( kidpar.type eq 1, nw1)
;;               make_ct, nw1, ct
;;               plot, index, ang[w1[0],*], /xs, yra=[0, max(ang[w1,*])], /ys, psym=4, $
;;                     ytitle='Angle iq didq (rad)'
;;               for i=0, nw1-1 do oplot, index, ang[w1[i],*], col=ct[i], psym=3
;;               stop

               for iphase = 0, nphase do begin
;;                scansub1= where( $
;;                         data.scan_valid[0] eq 0 and $
;; ;                        data.scan_valid[1] eq 0 and $ 
;;                         data.nsotto[0, *] eq iphase, $
;;                         nscansub1)
;;                scansub2= where( $
;; ;                        data.scan_valid[0] eq 0 and $
;;                         data.scan_valid[1] eq 0 and $ 
;;                         data.nsotto[1, *] eq iphase, $
;;                         nscansub2)
                  scansub = where( $
                            data.scan_valid[itotsotto] eq 0 and $
                            data.nsotto[itotsotto, *] eq iphase, $
                            nscansub)
                  scansub1 = scansub & nscansub1 = nscansub
                  scansub2 = scansub & nscansub2 = nscansub

                  if nscansub1 ge 200 then begin
                     my_n = 0
                     for idet = 0, nind1-1 do begin
                        idt = ind1[ idet]
                        coeff = -coeff1mm
                        if stddev( data[ scansub1].toi[ idt]) gt 0. then begin
                           ismallang = where( abs(ang[ idt, scansub1]) lt param.flag_sat_val, $
                                              nismallang)
                           ;wind, 1, 1, /free
                           ;plot, ang[idt,scansub1], title=idt
                           ;stop
                           chisqr = 0.
                           if nismallang gt 10 then begin
                              linpar = linfit( coeff*data[ scansub1[ ismallang]].toi[ idt], $
                                               ang[ idt, scansub1[ ismallang]], chisqr = chisqr)
                           endif else begin
                              linpar = [0, 0]
                           endelse
                           if linpar[1] gt 1D-6 $
                              and chisqr lt 20*!nika.f_sampling and chisqr gt 0. then begin
; Do NOT Correct the zero point of data.toi to match the df_tone zero point
                                ;                 stop
; Correct the df_tone to be calibrated as a toi in Hz (see nk_data_conventions)
;Used till 17/12/2015
                              ;; data[ scansub1[ismallang]].df_tone[ idt] = $
                              ;;       reform( ang[ idt, scansub1[ ismallang]]) / (linpar[1])
                              data[ scansub1[ismallang]].df_tone[ idt] = $
                                 -(data[ scansub1[ismallang]].toi[ idt]+ linpar[0]/linpar[1]/coeff) ; true Hz with proper zero
                              my_n++
                           endif
                        endif
                     endfor
                     ;print, "param.flag_sat_val, my_n: ", param.flag_sat_val, my_n
                     ;stop
                  endif
                  
                  if nscansub2 ge 200 then begin
                     for idet = 0, nind2-1 do begin
                        idt = ind2[ idet]
                        coeff = -1.
                        
                        if stddev( data[ scansub2].toi[ idt]) gt 0. then begin
                           ismallang = where( abs(ang[ idt, scansub2]) lt param.flag_sat_val, nismallang)
                           chisqr = 0.
                           if nismallang gt 10 then $
                              linpar = linfit( coeff*data[ scansub2[ ismallang]].toi[ idt], $
                                               ang[ idt, scansub2[ ismallang]], chisqr = chisqr) else linpar = [0, 0]
                           if linpar[1] gt 1D-6 $
                              and chisqr lt 20*!nika.f_sampling and chisqr gt 0. then begin
; Do NOT Correct the zero point of data.toi to match the df_tone zero point
                              
; Correct the df_tone to be calibrated as a toi in Hz (see nk_data_conventions)
;Used till 17/12/2015
                              ;; data[ scansub2[ismallang]].df_tone[ idt] = $
                              ;;       reform( ang[ idt, scansub2[ ismallang]]) / (linpar[1])
                              data[ scansub2[ismallang]].df_tone[ idt] = $
                                 -(data[ scansub2[ismallang]].toi[ idt]+ linpar[0]/linpar[1]/coeff) ; true Hz with proper zero
                           endif
                        endif
                     endfor
                  endif
               endfor           ; end of iphase

; Blank data if tuning did not work well
            ind = where( kidpar.type eq 1,  nind)
            for idet = 0, nind-1 do begin
               idt = ind[ idet]
               bad = where( data.subscan ge 1 and $
                            (byte(data.k_flag[ idt]) and !nika.tuning_en_cours_flag) eq !nika.tuning_en_cours_flag, nbad)
               if nbad ne 0 then data[ bad].df_tone[ idt] = !values.d_nan ; blanck everything
            endfor
         endelse
      endif
   endif
endif

if param.cpu_time then nk_show_cpu_time, param, "nk_get_df_tone"
  
return
end
