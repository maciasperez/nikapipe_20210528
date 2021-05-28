;+
; 
; SOFTWARE: 
;        NIKA pipeline
; 
; NAME:
; nk_restore_pointing_2
;
; PURPOSE: 
;        Interpolates missing pointing data with those of the
;        antennaimbfits for all types of scans. This is a cleaner
;        version of the old (<Aug. 4th 2016, rev 12152) chain of
;        nk_otf_antenna2pointing and nk_restore_pointing that showed
;        redundant operations.
;        In this version, holes may be less well treated. You may have
;        a look at nk_otf_pointing_restore then.
; 
; INPUT: 
;        - param: the parameter structure
;        - info: the information structure
;        - data
;        - kidpar
; 
; OUTPUT: 
;        - data: the data structure
;        - kidpar: the KID parameter structure
; 
; KEYWORDS:
;        NONE
; 
; MODIFICATION HISTORY: 
;        - Aug. 4th, 2016: NP
;-
;====================================================================================================

pro nk_restore_pointing_2, param, info, data, kidpar

if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

if param.cpu_time then param.cpu_t0 = systime(0, /sec)

;; Retrieve missing pointing data for all kinds of scans
nk_otf_antenna2pointing, param, info, data, kidpar, int_holes, plot=param.do_plot

;; Discard slew and interpolate missing pointing for Lissajous scans
if strupcase(info.obs_type) eq "LISSAJOUS" then begin

   nsn = n_elements(data)
   index = lindgen(nsn)
   i_up = nsn                   ; default
   i_down = -1                  ; everything is masked
   
   ;; Fit Lissajous coordinates around the center of the scan
   ;i2 = long(nsn*4./5)
   ;i1 = i2 - nsn/2
   i2 = long(nsn*2./3.)
   i1 = i2 - nsn/3
   flag = data.ofs_az*0.d0 + 1.d0
   flag[i1:i2] = 0
   
   ;; Due to pointing problems (missing data), use only non-zero values and take
   ;; 2 sec margin
   bad = where( data.scan eq 0, nbad)
   if nbad ne 0 then begin
      ;; flag[ bad] = 1
      nmargin = 2*long(!nika.f_sampling)
      bad = [min(bad)-(indgen(nmargin)+1), bad, max(bad)+indgen(nmargin)+1]
      flag[bad] = 1
      nk_add_flag, data, 9, wsample=bad
   endif

   ;; Fit sines on azimuth and elevation
   nika_fit_sine, index, data.ofs_az, flag, params_az, fit_az, status=status
   if status lt 0 then begin
      nk_error, info, "could not fit data.ofs_az with a sine"
      return
   endif
   info.liss_freq_az = params_az[0]
   nika_fit_sine, index, data.ofs_el, flag, params_el, fit_el, status=status
   if status lt 0 then begin
      nk_error, info, "could not fit data.ofs_el with a sine"
      return
   endif
   info.liss_freq_el = params_el[0]

   ;; The slew is defined as the outlyer section of the scan
   az_min = min( fit_az)
   az_max = max( fit_az)
   az_margin = (az_max-az_min)*0.02
   el_min = min( fit_el)
   el_max = max( fit_el)
   el_margin = (el_max-el_min)*0.02
   w_off = where( data.ofs_az ge (az_max+az_margin) or data.ofs_az le (az_min-az_margin) or $
                  data.ofs_el ge (el_max+el_margin) or data.ofs_el le (el_min-el_margin), nw_off)
   if nw_off ne 0 then begin
      ;; Discard all the beginning of the scan until the slew
      if min(w_off) ne 0 then wsample = [lindgen(min(w_off)), w_off] else wsample=w_off
      nwsample = n_elements(wsample)
      nk_add_flag, data, 8, wsample=wsample
   endif else begin
      nwsample = 0
   endelse

   
   if param.do_plot ne 0 then begin
      data1 = data
   endif
   
   ;; Interpolate missing data
   ;; w9 = nika_pipe_wflag( data.flag[0], 9, nflag=nw9, compl=w9compl, ncompl=nw9compl)
   w9 = nk_where_flag( data.flag[0], 9, nflag=nw9, compl=w9compl, ncompl=nw9compl)

   if (nw9 ne 0) and (strupcase(!nika.acq_version) ne "ISA") then begin
      data[w9].ofs_az = fit_az[w9]
      data[w9].ofs_el = fit_el[w9]

      data[w9].el      = interpol( data[w9compl].el,      data[w9compl].a_t_utc, data[w9].a_t_utc)
      data[w9].paral   = interpol( data[w9compl].paral,   data[w9compl].a_t_utc, data[w9].a_t_utc)
      data[w9].subscan = interpol( data[w9compl].subscan, data[w9compl].a_t_utc, data[w9].a_t_utc)
      data[w9].scan    = interpol( data[w9compl].scan,    data[w9compl].a_t_utc, data[w9].a_t_utc)

      ;; restore pointing flag for projection
      ;; if param.flag_holes ne 0 then data[w9].flag -= 2L^9
      if param.flag_holes eq 0 then data[w9].flag -= 2L^9
   endif

   if param.do_plot ne 0 then begin
      
      ;; Which samples are not missing or have been filled and are not in the slew
      junk = intarr( nsn)
      ;; w8 = nika_pipe_wflag( data.flag[0], 8, nflag=nw8)
      w8 = nk_where_flag( data.flag[0], 8, nflag=nw8)
      if nw8 ne 0 then junk[w8] = 1
      
      ;;w9 = nika_pipe_wflag( data.flag[0], 9, nflag=nw9)
      w9 = nk_where_flag( data.flag[0], 9, nflag=nw9)
      if nw9 ne 0 then junk[w9] = 1
      wproj = where( junk eq 0, nwproj)

      ;; Plot
      index = lindgen( nsn)
      if not param.plot_ps then wind, 1, 1, /free, /large, iconic = param.iconic
      outplot, file=param.output_dir+"/restore_pointing", png=param.plot_png, ps=param.plot_ps
      !p.multi=[0,1,2]
      plot,  index, data1.ofs_az, thick=3, /xs, title="nk_restore_pointing / "+param.scan+", ofs_az", yrange=[-100, 150], /ys
      w = where( flag eq 0, nw)
      oplot, index[w], data1[w].ofs_az, psym=1, col=70
      oplot, index, fit_az, col=70
      if nwsample ne 0 then oplot, index[wsample], data1[wsample].ofs_az, psym=1, col=200
      if nwproj ne 0 then oplot, index[wproj], data[wproj].ofs_az, psym=3, col=150, thick=3
      legendastro, ['Raw data', 'Samples to fit', 'Slew', 'Projected unless other flag'], col=[!p.color, 70, 200, 150], line=0, box=0

      plot,  index, data1.ofs_el, thick=3, /xs, title="nk_restore_pointing / "+param.scan+", ofs_el"
      w = where( flag eq 0, nw)
      oplot, index[w], data1[w].ofs_el, psym=1, col=70
      oplot, index, fit_el, col=70
      if nwsample ne 0 then oplot, index[wsample], data1[wsample].ofs_el, psym=1, col=200
      if nwproj ne 0 then oplot, index[wproj], data[wproj].ofs_el, psym=3, col=150, thick=3
      outplot, /close
   endif

endif

if param.cpu_time then nk_show_cpu_time, param

end
