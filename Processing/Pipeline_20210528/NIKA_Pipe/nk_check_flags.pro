
;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_check_flags
;
; CATEGORY: ?
;
; CALLING SEQUENCE:
;         nk_check_flags, param, info, data, kidpar
; 
; PURPOSE: 
;        display as, el and kid timelines together with subscan,
;tuning and k_flag information.
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
;        - NP 2016

pro nk_check_flags, param, info, data, kidpar, ikid_list, $
                    xra=xra, list=list, fields=fields, file=file, log_messages=log_messages, $
                    plot_name=plot_name, ext=ext
;-

if n_params() lt 1 then begin
   message, /info, "calling sequence:"
   dl_unix, 'nk_check_flags'
   return
endif

tags = tag_names(data)
wtag = where( strupcase(tags) eq "TOI", nwtag)

nkids = n_elements(ikid_list)

messages = ['scanLoaded']               
messages = [messages, 'scanStarted']    
messages = [messages, 'scanDone']       
messages = [messages, 'subscanStarted'] 
messages = [messages, 'subscanDone']    
messages = [messages, 'backOnTrack']
messages = [messages, 'subscan_tuning'] 
messages = [messages, 'scan_tuning']    
messages = [messages, 'scan_new_file']  

nsn = n_elements(data)
time = dindgen(nsn)/!nika.f_sampling
if not keyword_set(xra) then xra = minmax(time)

;; Flags and messages vs elevation and azimuth
if not keyword_set(fields) then fields = ['ofs_az', 'ofs_el']
nfields = n_elements(fields)
if keyword_set(log_messages) then nplots = nfields+1+nkids else nplots=nfields + nkids
tags = tag_names(data)
;erase
xmin = min(xra)
xmax = max(xra)
wt = where( time ge xmin and time le xmax)
ymin = min(data[wt].(wtag))
ymax = max(data[wt].(wtag))
yra = [ymin, ymax+0.3*(ymax-ymin)]
charsize = 0.6

w_scan_loaded     = where( data.scan_st eq 1, nw_scan_loaded)
w_scan_started    = where( data.scan_st eq 2, nw_scan_started)
w_back_on_track   = where( data.scan_st eq 6, nw_back_on_track)
w_subscan_started = where( data.scan_st eq 4, nw_subscan_started)
w_subscan_done    = where( data.scan_st eq 5, nw_subscan_done)

;; Plot all boxes
letter = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', $
          'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u']
tags = tag_names(data)
nboxes = n_elements(letter)     ; must be 20...

ch_freq_offset_display         = -2  & col_ch_freq=250
tuning_en_cours_offset_display = -3  & col_tuning_en_cours=200
scanloaded_offset_display      = -6   & col_loaded = 100
scanstarted_offset_display     = -7   & col_started = 70
scandone_offset_display        = -4  & col_done = 0
flagsynthe_offset_display      = -5  & col_synthe = 150
thick = 2
w_subscan_started = where( data.scan_st eq 4, nw_subscan_started)
w_subscan_done    = where( data.scan_st eq 5, nw_subscan_done)
nsn = n_elements(data)
time = dindgen(nsn)/!nika.f_sampling

if !nika.plot_window[0] lt 0 then begin
   my_multiplot, 1, 2, pp, pp1, /rev
endif else begin
   my_multiplot, 1, 2, pp, pp1, /rev, $
                 xmin=0.03, xmax=0.4, xmargin=0.01, $
                 ymin=0.5, ymax=0.8, gap_y=0.02
   wset, !nika.plot_window[0]
   charsize = 0.6
endelse
p=0
if param.do_plot ne 0 then begin

   w1 = where( kidpar.type eq 1, nw1)

   nsn = n_elements(data)
   yra = [-7, (max(data.subscan)+1)>15] ; [0, 15]
   time = dindgen(nsn)/!nika.f_sampling
   if param.plot_ps eq 0 and !nika.plot_window[0] lt 0 then wind, 1, 1, /free, /large, iconic = param.iconic
   if not keyword_set(plot_name) then plot_name = param.plot_dir+"/check_flags_brute_"+param.scan
   plot_name += "_"+strtrim(p,2)
   if keyword_set(ext) then plot_name += "_"+ext
   if param.plot_ps eq 0 and !nika.plot_window[0] lt 0 then outplot, file=plot_name, png=param.plot_png, ps=param.plot_ps
   if nw1 ne 0 then begin
      plot, time, ch_freq_offset_display + data.fpga_change_frequence, /xs, yra=yra, /ys, $
            xtitle='time (sec)', ycharsize=1.d-10, $
            xcharsize=charsize, /nodata, position=pp1[0,*], /noerase
;      nika_title, info, /all
      oplot, time, ch_freq_offset_display + data.fpga_change_frequence, col=col_ch_freq, thick=thick
      oplot, time, tuning_en_cours_offset_display + data.tuning_en_cours, col=col_tuning_en_cours, thick=thick
      oplot, time, flagsynthe_offset_display + data.blanking_synthe, col=col_synthe, thick=thick

      oplot, time, scanloaded_offset_display+ long(data.scan_st eq 1), col=col_loaded, thick=thick
      oplot, time, scanstarted_offset_display+ long(data.scan_st eq 1), col=col_started, thick=thick
      oplot, time, scandone_offset_display+ long(data.scan_st eq 1), col=col_done, thick=thick

      oplot, time, data.subscan, thick=thick
      for i=min(data.subscan), max(data.subscan) do begin
         ww = where( data.subscan eq i, nww)
         ;; if nww ne 0 then xyouts, time[ww[0]], i+0.1, 'Subsc. '+strtrim(long(i),2), chars=0.6
         if nww ne 0 then xyouts, time[ww[0]], i+0.1, strtrim(long(i),2), chars=0.6
      endfor
            
      col = [col_ch_freq, col_tuning_en_cours, col_loaded, col_started, col_done, col_synthe]
      ;; legendastro, ['change freq', 'tuning en cours', $
      ;;               'scan loaded', 'scan started', 'scan done', 'flag_synthe'], $
      ;;              textcol = col, charsize=charsize

      legendastro, ['change freq', 'tuning en cours'], textcol=col[0:1], charsize=charsize
      legendastro, ['scan loaded', 'scan started'],    textcol=col[2:3], charsize=charsize, /center, /top
      legendastro, ['scan done', 'flag_synthe'],       textcol=col[3:*], charsize=charsize, /right

      
;;       if nw_subscan_started ne 0 then begin
;;          for i=0, nw_subscan_started-1 do oplot, time[w_subscan_started[i]]*[1,1], [-1,1]*1e20, col=150
;;       endif
;;       if nw_subscan_done ne 0 then begin
;;          for i=0, nw_subscan_done-1 do oplot, time[w_subscan_done[i]]*[1,1], [-1,1]*1e20, col=70
;;       endif
;;      
;;      for i=min(data.subscan), max(data.subscan) do begin
;;         ww = where( data.subscan eq i, nww)
;;         if nww ne 0 then begin
;;            xyouts, time[ww[0]], max(yra)*0.8, strtrim( long(i),2)
;;            oplot, time[ww[0]]*[1,1], [-1,1]*1e20, thick=(i eq 1 or i eq 2)*2, col=70
;;         endif
;;      endfor
;;      stop
      
;;      ;; Elvin messages
;;      if nw_back_on_track ne 0 then begin
;;         for i=0, nw_back_on_track-1 do oplot, time[w_back_on_track[i]]*[1,1], [-1,1]*1e20
;;      endif
;;      if nw_subscan_started ne 0 then begin
;;         for i=0, nw_subscan_started-1 do oplot, time[w_subscan_started[i]]*[1,1], [-1,1]*1e20, col=150
;;      endif
;;      if nw_subscan_done ne 0 then begin
;;         for i=0, nw_subscan_done-1 do oplot, time[w_subscan_done[i]]*[1,1], [-1,1]*1e20, col=70
;;      endif
;;      if nw_scan_loaded ne 0 then begin
;;         for i=0, nw_scan_loaded-1 do oplot, time[w_scan_loaded[i]]*[1,1], [-1,1]*1e20, col=70
;;      endif
   endif
   
;;   if param.do_plot ne 0 then nika_title, info, /all
;   outplot, /close
endif

;; print messages in chronological order
if keyword_set(file) then begin
   j=0L
   openw, lu, file, /get_lun
   printf, lu, "#NIKA a_t_utc, message"
   while j le (nsn-1) do begin
      if time(j) ge min(xra) and time(j) le max(xra) then begin
         hour = strtrim(long( data[j].a_t_utc/3600.d0),2)
         min  = strtrim(long( (data[j].a_t_utc - hour*3600.d0)/60.d0),2)
         sec = string( data[j].a_t_utc - hour*3600.d0 -min*60.d0, format='(F6.3)')
                                ;if data[j].scan_st ne 0 then printf, lu, strtrim(time[j],2)+", "+$
                                ;                                     messages[data[j].scan_st-1]
         if data[j].scan_st ne 0 then $
            printf, lu, hour+":"+min+":"+sec+", "+messages[data[j].scan_st-1]
      endif
      j += 1L
   endwhile
   close, lu
   free_lun, lu
endif

if keyword_set(list) then begin
   j=0
   message, /info, "#time (sec), message"
   while j le (nsn-1) do begin
      if time(j) ge min(xra) and time(j) le max(xra) then begin
         if data[j].scan_st ne 0 then print, time[j], " ", messages[data[j].scan_st-1]
      endif
      j++
   endwhile
endif

;message, /info, "fix me: set back log_messages when possible"
if keyword_set(log_messages) and param.do_plot eq 1 then begin
;   if param.plot_ps eq 0 then wind, 1, 1, /free, /xlarge, iconic = param.iconic
   nk_compare_messages, param, param.scan, t0=data[0].a_t_utc, position=pp1[1,*], charsize=charsize
endif
;stop
outplot, /close

end
