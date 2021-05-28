;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_speed_flag
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

;-

pro nk_speed_flag,  param, info, data, kidpar, $
                    first_subscan_beg_index=first_subscan_beg_index, last_subscan_end_index=last_subscan_end_index

if info.status eq 1 then begin
   if param.silent eq 0 then    message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

if param.cpu_time then param.cpu_t0 = systime(0, /sec)

speed     = sqrt( deriv(data.ofs_az)^2 + deriv(data.ofs_el)^2)*!nika.f_sampling
;speed_tol = 5.0 ; 3.d0 ; tolerate +- 3 arcsec/s speed variation across a subscan

;; Discard the beginning and ending slews of an otf scan if requested.
;; (better for common mode estimation when the source is strong at the center)
;; plot, data.ofs_az, data.ofs_el
if strupcase(info.obs_type) eq "ONTHEFLYMAP" and param.discard_otf_slew then begin

   ;; The slews have different directions: use this to discard them.
   ;; Before computing the slope, rotate the scans to have nearly "horizontal"
   ;; scans on screen, otherwise, for elevation scans typically, the slopes are
   ;; infinitely large and the following does not work.
   c = 0.d0
   a = 0.d0
   for i=min(data.subscan), max(data.subscan) do begin
      w = where( data.subscan eq i, nw)
      if nw ne 0 then begin
         med_speed = median( speed[w])
         w = where( data.subscan eq i and abs(speed-med_speed) le param.speed_tol, nw)
         if nw ne 0 then begin
            i1 = min( w)
            i2 = max( w)
            if (data[i2].ofs_az-data[i1].ofs_az) ne 0 then begin
               ;; Add absolute value to avoid adding !pi/2 and -!pi/2 and finding zero
               ;; in the end whereas the scan is indeed vertical
               a += abs( atan( (data[i2].ofs_el-data[i1].ofs_el)/(data[i2].ofs_az-data[i1].ofs_az)))
               c += 1
            endif
         endif
         ;; flag out anomalous speed
         wcompl = where( data.subscan eq i and abs(speed-median(speed)) gt param.speed_tol, nwcompl)

         ;; if nwcompl ne 0 then oplot, data[wcompl].ofs_az, data[wcompl].ofs_el, psym=1, col=70
         if nwcompl ne 0 then nk_add_flag, data, 11, wsample=wcompl
      endif
   endfor
   ;; average
   a /= c

   dx =  cos(a)*data.ofs_az + sin(a)*data.ofs_el
   dy = -sin(a)*data.ofs_az + cos(a)*data.ofs_el
   slope = deriv(dy)/deriv(dx)

   wf = where( finite(slope))
   delta_slope = slope - median(slope[wf])
   delta_slope_tol = 5*!dtor ; 5 deg tolerance
   ;; 1st slew, from center to bottom left
   wsub1 = where( data.subscan eq 1 and data.scan_valid[0] eq 0, nwsub1)
   if nwsub1 ne 0 then begin
      w = where( (finite(slope) eq 1) and $
                 (data.scan_valid[0] eq 0) and $
                 (abs( delta_slope) ge delta_slope_tol) and $
                 (data.sample lt max( data[wsub1].sample)), nw)
      ;;-----------------------
      ;; Commented out, NP, Dec. 15th, 2014 (removes the entire subscan in
      ;; common cases, while the criterion on speed is enough to discard the slew)
      ;; if nw ne 0 then begin
      ;;    if not keyword_set(first_subscan_beg_index) then first_subscan_beg_index = max(w)
      ;;    data[0:min([max(w),first_subscan_beg_index])].scan_valid = 1 ; set to non zero to discard in nk_cut_scans
      ;; endif
      ;;------------------------
   endif

   ;; Ending slew, from top left to center
   wsublast = where( data.subscan eq max(data.subscan) and data.scan_valid[0] eq 0, nwsublast)
   if nwsublast ne 0 then begin
      w = where( finite(slope) and $
                 (data.scan_valid[0] eq 0) and $
                 abs( delta_slope) ge delta_slope_tol and $
                 data.sample gt mean( data[wsublast].sample), nw)
      ;;-----------------------
      ;; Commented out, NP, Dec. 15th, 2014 (removes the entire subscan in
      ;; common cases, while the criterion on speed is enough to discard the slew)
      ;; if nw ne 0 then begin
      ;;    if not keyword_set(last_subscan_end_index) then last_subscan_end_index = w[0]
      ;;    data[max([w[0],last_subscan_end_index]):*].scan_valid = 1 ; set to non zero to discard in nk_cut_scans
      ;; endif
      ;;------------------------
   endif
endif ; OTF scan

;plot, data.ofs_az, data.ofs_el
;w=where(data.flag[2] eq 0, nw) & print, nw
;oplot, data[w].ofs_az, data[w].ofs_el, psym=1, col=70

;; Flag out anomalous speed other scans than OTF
w_valid = where( data.scan_valid[0] eq 0)
med = median( speed[w_valid])
cflag = lindgen( n_elements(data)) ; init, default for skydip
;;if strupcase(info.obs_type) eq    "POINTING" then w1 = where( abs(speed) gt 1.5*med or abs(speed) lt 0.5*med, nw1, comp=cflag)
if strupcase(info.obs_type) eq    "POINTING" then begin
;   plot, speed, /xs, yra = [0, 20], /ys
   for i=min(data.subscan), max(data.subscan) do begin
      w = where( data.subscan eq i and speed gt 0.1, nw) ; discard potential 0 values in the first subscan

      ;; take margin because edges can screw up both the average and the
      ;; median :(
      if nw eq 0 then begin
         error_message = "No data for subscan number "+strtrim(i,  2)+" ?! => exiting"
         nk_error,  info,  error_message
         return
      endif
      if nw lt 100 then begin
         error_message = "Less than 100 samples for subscan number "+strtrim(i,  2)+" ?! => exiting"
         nk_error,  info,  error_message
         return
      endif
      i1 = min(w) + ((nw/5)>2) ; integer div on purpose
      i2 = max(w) - ((nw/5)>2) ; integer div on purpose
      w = where( data.subscan eq i and speed gt 0.1 and $
                 data.sample ge data[i1].sample and data.sample le data[i2].sample, nw)

      ;;avg_speed =  avg( speed[w])
      ;; Sligth smooth of speed to improve regularity
      sm_speed =  smooth(speed, 2)
      avg_sm_speed = avg( sm_speed[w])
      ;w = where( data.subscan eq i and abs(speed-avg_speed) gt param.speed_tol, nw)
      w = where( data.subscan eq i and abs(sm_speed-avg_sm_speed) gt param.speed_tol, nw)
      if nw ne 0 then begin
         nk_add_flag,  data,  11,  wsample=w
;         oplot, w, speed[w], psym = 1, col = 250
      endif
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
      info.liss_freq_az = params_az[0]
      nika_fit_sine, data.sample-min(data.sample), data.ofs_el, flag, params_el, fit_el, status=status
      info.liss_freq_el = params_el[0]
      w = where( abs(data.ofs_az-fit_az) gt param.pointing_accuracy_tol, nw, compl=wcompl)
      if nw ne 0 then nk_add_flag,  data,  11,  wsample=w
   endelse
;;   endelse
endif

;; Check
;;****** this plot is now in nk_cut_scans. *****
;; if param.do_plot ne 0 then begin
;;    wind, 1, 1, /free, xs=1200
;;    outplot, file=param.plot_dir+'/speed_flag', png=param.plot_png, ps=param.plot_ps
;;    !p.multi=[0,3,1]
;;    plot, data.ofs_az, data.ofs_el, /iso, xtitle='az', ytitle='el'
;;    if nw  ne 0 then oplot, data[w].ofs_az, data[w].ofs_el, psym=1, col=250
;;    legendastro, ['Speed flag'], line=0, col=[250], box=0
;; 
;;    t = lindgen( n_elements(data))/!nika.f_sampling
;;    plot, t, data.ofs_az, /xs, xtitle='Time (sec)', ytitle='Az'
;;    if nw  ne 0 then oplot, t[w], data[w].ofs_az, psym=1, col=250
;; 
;;    plot, t, data.ofs_el, /xs, xtitle='Time (sec)', ytitle='El'
;;    if nw  ne 0 then oplot, t[w], data[w].ofs_el, psym=1, col=250
;;    !p.multi=0
;;    outplot, /close
;; endif

if param.cpu_time then nk_show_cpu_time, param, "nk_speed_flag"

end
