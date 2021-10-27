;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_speed_flag_2
;
; CATEGORY: toi processing
;
; CALLING SEQUENCE:
;         nk_speed_flag, param, info, data, kidpar
; 
; PURPOSE: 
;        Computes instantaneous pointing speed and flags out when the
;speed is too far from the median. This gets rid of intersubscan
;phases, slews etc... when pointing is uncertain and data should not
;be projected
; 
; INPUT: 
;        - param: the reduction parameters structure
;        - info: an information structure to be filled
;        - data: the NIKA general data structure
;        - kidpar: the NIKA general kid structure
; 
; OUTPUT: 
;        - data.flag is modified
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - June 3rd, 2014: creation (Nicolas Ponthieu & Remi Adam -
;          adam@lpsc.in2p3.fr)
;        - Sept 17th, 2014: input adding first_subscan_beg_index,
;          last_subscan_end_index as a Q&D debugging (L. Perotto)
;        - Sept 23rd, 2014: turned into keywords to be compatible with previous
;          runs without poiting reconstruction (NP)
;        - 11/11/14: add "if nw ne 0 then begin"
;        - Dec. 15th, 2014: simplified version, NP.
;-

pro nk_speed_flag_2,  param, info, data, kidpar, $
                      first_subscan_beg_index=first_subscan_beg_index, $
                      last_subscan_end_index=last_subscan_end_index, $
                      pipq=pipq

if info.status eq 1 then begin
   if param.silent eq 0 then    message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

if param.cpu_time then param.cpu_t0 = systime(0, /sec)

nsn   = n_elements(data)
speed = sqrt( deriv(data.ofs_az)^2 + deriv(data.ofs_el)^2)*!nika.f_sampling
;; Solve azimuth sampling issue, FXD + NP, Sept. 18th, 2015
;az_liss = smooth( data.ofs_az, 3)
;el_liss = smooth( data.ofs_el, 3)
;speed = sqrt( deriv(az_liss)^2 + deriv(el_liss)^2)*!nika.f_sampling
;;stop
med_speed = median( speed)

;;----------------- v2 check ---------------
if param.silent eq 0 then begin
   print, "--- nk_speed_flag_2 diagnosis ---"
   print, "param.scan: ", param.scan
   print, "avg(data.el)*!radeg: ", avg(data.el)*!radeg
   print, "minmax(data.ofs_az): ", minmax(data.ofs_az)
   print, "minmax(data.ofs_el): ", minmax(data.ofs_el)
   print, "med_speed: ", med_speed
endif

;;  w = where( data.subscan eq 2)
;;  wind, 1, 1, /f, /large
;;  !p.multi=[0,1,2]
;;  plot, data.ofs_az, data.ofs_el, psym=-4, /iso, xtitle='ofs_az', ytitle='ofs_el'
;;  legendastro, param.scan
;;  plot, speed[w], /xs, psym=-4, xtitle='index', ytitle='speed (Arcsec/s)'
;;  !p.multi=0

;;----------------- v2 check ---------------

;; ;; if param.do_plot ne 0 and param.plot_ps eq 0 then begin
;; ;; ;outplot, file='speed_'+strtrim(param.scan), /png
;; wind, 1, 1, /free, /large
;; plot, speed, /ys, yra=[0,100], title=param.scan, /xs
;; oplot, speed*0 + med_speed, col=250
;; legendastro, 'Median speed: '+strtrim(med_speed,2), box=0, textcol=250
;; stop
;; ;; ;outplot, /close
;; ;; ;stop
;; ;; endif

if strupcase(info.obs_type) eq "ONTHEFLYMAP" then begin

   ;; The slews have different directions: use this to discard them.
   ;;
   ;; Discard them before estimating subscan scanning speeds because in case of
   ;; short subscans, the first and last subscans might be damaged.
   ;;
   ;; Before computing the slope, rotate the scans to have nearly "horizontal"
   ;; scans on screen, otherwise, for elevation scans typically, the slopes are
   ;; infinitely large and the following does not work.
   c = 0.d0
   a = 0.d0
   for i=min(data.subscan), max(data.subscan) do begin
      w = where( data.subscan eq i, nw)
      if nw ne 0 then begin
         ;med_speed = median( speed[w])
         w = where( data.subscan eq i and abs(speed-med_speed) le param.speed_tol, nw)

         if nw ne 0 then begin
            i1 = min( w)
            i2 = max( w)
            if (data[i2].ofs_az-data[i1].ofs_az) ne 0 then begin
               r = (data[i2].ofs_el-data[i1].ofs_el)/(data[i2].ofs_az-data[i1].ofs_az) 
               ;; If the scan is vertical or close to vertical, switch
               ;; (az,el) <--> (x,y) to avoid infinite values
               if abs(r) lt 15 then begin
                  a += atan(r)
               endif else begin
                  r = 1.d0/r
                  a += atan( r) + !dpi/2.
               endelse

               c += 1
            endif

            ;; ;; Check rotation subscan by subscan
            ;; wind, 1, 1, /free, /large
            ;; !p.multi = [0, 2, 2]
            ;; plot, data.ofs_az, data.ofs_el, /iso, title='input ofs_az, ofs_el'
            ;; oplot, data[w].ofs_az, data[w].ofs_el, col = 70, thick = 2
            ;; legendastro, 'Subscan = '+strtrim(i,2), box=0, textcol=2
            ;; plot, speed, /xs, title='speed'
            ;; oplot, w, speed[w], col = 70
            ;; if c ne 0 then a1 = a/c else a1=a
            ;; dx =  cos(a1)*data.ofs_az + sin(a1)*data.ofs_el
            ;; dy = -sin(a1)*data.ofs_az + cos(a1)*data.ofs_el
            ;; plot, dx, dy, /iso, title='rotated ofs_az, ofs_el'
            ;; !p.multi=0
            ;; stop

         endif

      endif
   endfor

   ;; Get the average slope
   if c ne 0 then a /= c

   ;; Rotate accordingly
   dx =  cos(a)*data.ofs_az + sin(a)*data.ofs_el
   dy = -sin(a)*data.ofs_az + cos(a)*data.ofs_el
   slope = atan(deriv(dy)/deriv(dx))*!radeg

   ;; Flag out slews
   wf = where( finite(slope), nwf)
   if nwf gt 3 then delta_slope = slope - median(slope[wf]) $
   else delta_slope = 100.  ; FXD to go through anomalous scans (Nov 2016)
   delta_slope_tol = 20.d0 ; tolerance in degrees

   wsub1 = where( data.subscan eq 1, nwsub1)
   if nwsub1 ne 0 then begin
      i1 = max( data[wsub1].sample)
      ;; take a 5 sec margin at the beginning of the subscan (subscans are bound to be
      ;; longer than a few seconds)
      w = where( abs(delta_slope) gt delta_slope_tol and data.sample lt (i1-5*long(!nika.f_sampling)), nw)
      if nw ne 0 then begin
         if param.silent eq 0 then message, /info, "Found anomalous slope at beginning of subscan (slew)"
         if not keyword_set(first_subscan_beg_index) then first_subscan_beg_index = max(w)
         w = lindgen(min([max(w),first_subscan_beg_index])+1)
         ;data[w].scan_valid = 1 ; will be cut out by nk_cut_scans
         nk_add_flag, data, 8, wsample=w
      endif
   endif

   wsubmax = where( data.subscan eq max(data.subscan), nwsubmax)
   if nwsubmax ne 0 then begin
      i1 = min( data[wsubmax].sample)
      ;; take a 5 sec margin at the end of the subscan (subscans are bound to be
      ;; longer than a few seconds)
      w = where( abs(delta_slope) gt delta_slope_tol and data.sample gt (i1+5*long(!nika.f_sampling)), nw)
      if nw ne 0 then begin
         if param.silent eq 0 then message, /info, "Found anomalous slope at end of subscan (slew)"
         if not keyword_set(last_subscan_end_index) then last_subscan_end_index = w[0]
;;;
;;; test of number of elements because it may happen that cw < 0
cw =  nsn-max([w[0],last_subscan_end_index])
if cw ge 1 then begin
;;;
         w = lindgen(nsn-max([w[0],last_subscan_end_index])) + max([w[0],last_subscan_end_index])
         ;data[w].scan_valid = 1 ; set to non zero to discard in nk_cut_scans
         nk_add_flag, data, 8, wsample=w
;;;FXD August 2017, cut those last points completely as they mess up
;;;the whole thing (not only display)
         data = temporary( data[0:w[0]-1])
         if keyword_set(pipq) then pipq = pipq[*,0:w[0]-1]
endif
;;;
      endif
   endif

   ;; Flag out anomalous speed
   ;; Xavier uses scan_valid[4] sometimes, => do not use avg(scan_valid) anymore
   w = where( data.scan_valid[0] eq 0 and data.scan_valid[1] eq 0, nw)
   med_speed = 0.
   if nw gt 1 then med_speed = median( speed[w])
   if nw eq 1 then med_speed = speed[w[0]]
; message, /info, "fix me: instead of speed tol, apply remi's choice:"
   w = where( abs(speed-med_speed) gt param.speed_tol and $
              data.scan_valid[0] eq 0 and $
              data.scan_valid[1] eq 0, nw)
   if nw ne 0 then nk_add_flag, data, 11, wsample=w
;flag = where(abs(speed) gt 1.5*med_speed or abs(speed) lt 0.5*med_speed, nflag, comp=cflag)
;print, med_speed, 1.5*med_speed, 0.5*med_speed
;stop
;if nflag ne 0 then nk_add_flag, data, 11, wsample=flag
;stop

endif ; OTF scan


;; Flag out anomalous speed other scans than OTF
if strupcase(info.obs_type) eq  "POINTING" then begin
   for i=min(data.subscan), max(data.subscan) do begin
      w = where( data.subscan eq i and speed gt 0.1, nw) ; discard potential 0 values in the first subscan
      
      ;; take margin because edges can screw up both the average and the
      ;; median :(
      if nw eq 0 then begin
         ww = where( data.subscan eq i)
         nk_add_flag, data, 11, wsample=ww
      endif else begin
         i1 = min(w) + ((nw/5)>2) ; integer div on purpose
         i2 = max(w) - ((nw/5)>2) ; integer div on purpose
         w = where( data.subscan eq i and speed gt 0.1 and $
                    data.sample ge data[i1].sample and data.sample le data[i2].sample, nw)
         ;; Slight smooth of speed to improve regularity
         ;; sm_speed =  smooth(speed, 2)
         ;; avg_sm_speed = avg( sm_speed[w])
         ;; w = where( data.subscan eq i and abs(sm_speed-avg_sm_speed) gt param.speed_tol, nw)
         w = where( data.subscan eq i and ( abs( speed-med_speed) gt param.speed_tol), nw)
         if nw ne 0 then nk_add_flag, data, 11, wsample=w
      endelse
   endfor
endif

if strupcase(info.obs_type) eq   "LISSAJOUS" then begin
;;   if long(!nika.run) eq 8 then begin
;;      w1 = where( abs(speed) gt   3*med or abs(speed) lt 0.1*med, nw1, comp=cflag)
;;      avg_speed   = avg( speed[cflag])
;;      sigma_speed = stddev( speed[cflag])
;;      w           = where( abs(speed-avg_speed) gt 3*sigma_speed, nw)
;;      if nw ne 0 then nk_add_flag, data, 11, wsample=w
;;   endif else begin
   w = where(data.scan ne 0,  nw)
   if nw eq 0 then begin
      nk_error,  info,  "All data have data.scan = 0"
      return
   endif else begin
      ;; Fit around the center to be in the stationary section
      i1 = min(w) + nw/4
      i2 = max(w) - nw/4
      flag = intarr( n_elements(data)) + 1
      flag[i1:i2] = 0
      nika_fit_sine, data.sample-min(data.sample), data.ofs_az, flag, params_az, fit_az, status=status
      if status ne 0 then info.liss_freq_az = params_az[0] else begin
         info.status = 1
         message, /info, 'Bad Az lissajous fit'
         return
      endelse

      nika_fit_sine, data.sample-min(data.sample), data.ofs_el, flag, params_el, fit_el, status=status
      if status ne 0 then info.liss_freq_el = params_el[0] else begin
         info.status = 1
         message, /info, 'Bad El lissajous fit'
         return
      endelse

      dist_fit = sqrt( (data.ofs_az-fit_az)^2 + (data.ofs_el-fit_el)^2)
      w = where( dist_fit gt param.pointing_accuracy_tol, nw, compl=wcompl)
      if nw ne 0 then nk_add_flag, data, 8, wsample=w

      if param.do_plot ne 0 then begin
         loadct, 39, /silent
         outplot, file=param.plot_dir+"/speed_flags", png=param.plot_png, ps=param.plot_ps
         !p.multi=[0,1,2]
         if param.plot_ps eq 0 then wind, 1, 1, /free, /large
         index = lindgen(n_elements(data))
         plot,  index, data.ofs_az, thick=3, /xs, title="nk_speed_flag_2 / "+param.scan+", ofs_az", yrange=[-100, 150], /ys
         w = where( flag eq 0, nw)
         if nw gt 1 then oplot, index[w], data[w].ofs_az, psym=1, col=70
         w = where( data.flag[0] eq 0, nw)
         if nw gt 1 then oplot, index[w], data[w].ofs_az, psym = 3, col = 150, thick = 3
         oplot, index, fit_az, col=70
         legendastro, ['Raw data', 'Samples to fit', 'Projected unless other flag'], col=[!p.color, 70, 150], line=0, box=0
         
         plot,  index, data.ofs_el, thick=3, /xs, title="nk_speed_flag_2 / "+param.scan+", ofs_el", yrange=[-100, 150], /ys
         w = where( flag eq 0, nw)
         if nw gt 1 then oplot, index[w], data[w].ofs_el, psym=1, col=70
         w = where( data.flag[0] eq 0, nw)
         if nw gt 1 then oplot, index[w], data[w].ofs_el, psym = 3, col = 150, thick = 3
         oplot, index, fit_el, col=70
         legendastro, ['Raw data', 'Samples to fit', 'Projected unless other flag'], col=[!p.color, 70, 150], line=0, box=0
         outplot, /close
      endif

   endelse
endif

if param.cpu_time then nk_show_cpu_time, param

end
