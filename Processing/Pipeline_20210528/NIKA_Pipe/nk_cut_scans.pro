;+
;
; SOFTWARE: NIKA pipeline
;
; NAME:
; nk_cut_scans
;
; CATEGORY: toi processing
;
; CALLING SEQUENCE:
;         nk_cut_scans, param, info, data, kidpar
; 
; PURPOSE: 
;        Discards useless sections of the data.
; 
; INPUT: 
;        - param: the reduction parameters structure
;        - info: an information structure to be filled
;        - data: the NIKA general data structure
;        - kidpar: the NIKA general kid structure
; 
; OUTPUT: 
;        - data: useless sections of data, at the beginning and/or the end of the scan.
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - April 08th, 2014: creation (Nicolas Ponthieu & Remi Adam - adam@lpsc.in2p3.fr)
;-
;============================================================================================

pro nk_cut_scans, param, info, data, kidpar, pipq=pipq

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_cut_scans, param, info, data, kidpar, pipq=pipq"
   return
endif

if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

if param.cpu_time then param.cpu_t0 = systime(0, /sec)

;; Restrict to the largest section without tunings
keep = data.flag[0] * 0
if long(!nika.run) le 12 then begin
   w7 = nk_where_flag( data.flag[0], 7, compl=w)
   keep[w] = 1
endif else begin
   keep[*] = 1
endelse
;; ;;  WARNING : changed by Xavier and Juan
;; w = where( data.scan_valid[0] eq 0 and data.scan_valid[1] eq 0 and data.scan_valid[2] eq 0 and keep eq 1, nw)
;; print,  nw

; FXD, 23/2/2018:
; I noted few samples at the beginning and end to be flagged (all
; kids), So we can remove the end bits which give pb in rf_didq
; conversion
flmin = min( data.flag,dim=1)
nda = n_elements( data)
gdfl = bytarr( nda)
ubeg = where( flmin eq 0, nubeg)
if ubeg[0] gt 0 then gdfl[0: ubeg[0]-1] = 1B
if max(ubeg) lt (nda-1)  then gdfl[ max( ubeg):nda-1] = 1B
;; More generic term for any number of e-boxes, NP, Nov. 2015
;;;;sv = avg( float( data.scan_valid), 0) gt 0 or keep eq 0 ; 'or' is
;;;;                        better than 'and'
sv = avg( float( data.scan_valid), 0) gt 0 or keep eq 0 or (gdfl eq 1B)
w = where( sv eq 0,  nw)

;; if nw gt 21 then begin
;;    ;;  WARNING : changed by Xavier and Juan
;;    ;;  to avoid what looks like left over from tuning
;;    w=w[400:*]
;;    nw = n_elements(w)
;; endif

if nw eq 0 then begin
   nk_error, info, "No sample with data.scan_valid=0 ?!", silent=param.silent
   return
endif else begin
   data = data[w]
   if keyword_set(pipq) then pipq = pipq[*,w]
endelse

; FXD, 23/2/2018:
; I noted few samples at the beginning and end to be flagged (all
; kids), So we can remove the end bits which give pb in rf_didq
; conversion
; Beginning

;; if strlen( param.cut_scan_exec) ne 0 then begin
;;    junk = execute( param.cut_scan_exec)
;;    data = data[0:nsn_max-1]
;;    if keyword_set(pipq) then pipq = pipq[*,0:nsn_max-1]
;; endif

w1 = where( kidpar.type eq 1, nw1)
wspeed = nk_where_flag( data.flag[w1[0]], 11, nflag=n_speed_flag)
speed = sqrt( deriv(data.ofs_az)^2 + deriv(data.ofs_el)^2)*!nika.f_sampling
med_speed = median(speed)
info.median_scan_speed = med_speed
nsn = n_elements(data)
daz_range = max(data.ofs_az)-min(data.ofs_az)
daz_minmax = minmax(data.ofs_az)

;;-------------------------------------------------------------
;; Check
if param.do_plot ne 0 and param.plot_z eq 0 then begin
   if (param.plot_ps ne 1) and (param.plot_z ne 1) and !nika.plot_window[0] lt 0 then $
      wind, 1, 1, /free, /large, title='nk_cut_scans', iconic = param.iconic

   leg_txt = ''
   textcol = !p.color

   col_speed = 70
   ;; wspeed = nika_pipe_wflag( data.flag[w1[0]], 11,
   ;; nflag=n_speed_flag)
   if n_speed_flag ne 0 then begin
      leg_txt = [leg_txt, 'Speed flags']
      textcol = [textcol, col_speed]
   endif

   if !nika.plot_window[0] lt 0 then begin
      outplot, file=param.plot_dir+'/speed_flag_'+strtrim(param.scan,2), png=param.plot_png, ps=param.plot_ps
      !p.multi=[0,2,2]
      t = lindgen( n_elements(data))/!nika.f_sampling
      ytitle='Az. offset'   
      if strupcase(info.systemof) eq "PROJECTION" then begin
         if strtrim(strupcase(info.ctype1),2) eq "GLON" then begin
            ytitle='GLON offset'
         endif else begin
            ytitle='R.A. offset'
         endelse
      endif
      plot, t, data.ofs_az, /xs, xtitle='Time (sec)', ytitle=ytitle ;, title=param.scan
      if n_speed_flag  gt 1 then oplot, t[wspeed], data[wspeed].ofs_az, psym=1, col=col_speed
      legendastro,  'Anomalous speed flag', psym = 1, col = 70, box = 0
      if float(n_speed_flag)/nsn gt 0.2 then $
         legendastro, ['Anomalous speed on more than 20% of the scan', $
                       'Pb. with Elvin ?!'], thick=2, col=250
      
      nika_title, info, /ut, /az, /el, /scan

      ytitle='El. offset'   
      if strupcase(info.systemof) eq "PROJECTION" then begin
         if strtrim(strupcase(info.ctype1),2) eq "GLON" then begin
            ytitle='GLAT offset'
         endif else begin
            ytitle='Dec. offset'
         endelse
      endif
      plot, t, data.ofs_el, /xs, xtitle='Time (sec)', ytitle=ytitle ;, title=param.scan
      if n_speed_flag  gt 1 then oplot, t[wspeed], data[wspeed].ofs_el, psym=1, col=col_speed
      legendastro,  'Anomalous speed flag', psym = 1, col = 70, box = 0
      if float(n_speed_flag)/nsn gt 0.2 then $
         legendastro, ['Anomalous speed on more than 20% of the scan', $
                       'Pb. with Elvin ?!'], thick=2, col=250
      nika_title, info, /ut, /az, /el, /scan
      

      ytitle = 'El. offset'
      xtitle = 'Az. offset'
      if strupcase(info.systemof) eq "PROJECTION" then begin
         if strtrim(strupcase(info.ctype1),2) eq "GLON" then begin
            xtitle = 'GLON offset'
            ytitle = 'GLAT offset'
         endif else begin
            ytitle = 'Dec. offset'
            xtitle = 'Ra. offset'
         endelse
      endif
      plot, data.ofs_az, data.ofs_el, /iso, xtitle=xtitle, ytitle=ytitle, $ ;title=param.scan, $
            xra=minmax(data.ofs_az)+[-1,1]*0.2*daz_range, /xs
      if n_speed_flag  gt 1 then oplot, data[wspeed].ofs_az, data[wspeed].ofs_el, psym=1, col=col_speed
      if leg_txt[0] ne '' then legendastro, leg_txt, textcol=textcol
      legendastro,  'Anomalous speed flag', psym = 1, col = 70, box = 0,  /right
      nika_title, info, /ut, /az, /el, /scan

      np_histo, speed, /fill, fcol=70, xtitle='Speed arcsec/s', max=200, bin=1.
      legendastro, 'Median speed: '+strtrim(med_speed,2), box=0, textcol=250
      nika_title, info, /ut, /az, /el, /scan
      !p.multi=0
      outplot, /close

   endif else begin
      wset, !nika.plot_window[0]
      charsize = 0.6
      plot, data.ofs_az, data.ofs_el, /iso, xtitle=xtitle, ytitle=ytitle, $
            xra=minmax(data.ofs_az)+[-1,1]*0.2*daz_range, /xs, /noerase, $
            yra=[min(data.ofs_el)-100, max(data.ofs_el) + 50], /ys, $
            charsize=charsize, position=[0.45, 0.5, 0.7, 0.95]
      if n_speed_flag  gt 1 then oplot, data[wspeed].ofs_az, data[wspeed].ofs_el, psym=1, col=col_speed
      if leg_txt[0] ne '' then legendastro, leg_txt, textcol=textcol
      legendastro,  'Anomalous speed flag', psym = 1, col = 70, box = 0,  /right, $
                    charsize=charsize
      legendastro, 'Median speed: '+strtrim(string(med_speed,form='(F6.2)'),2)+" arcsec/s", $
                   chars=0.6, /bottom


      if float(n_speed_flag)/nsn gt 0.2 then begin
         legendastro, ['Anomalous speed',$
                       'on more than 20% of the scan', $
                       'Pb. with Elvin ?!', "", "if you think it's ok though, just press ,c"], charthick=2, col=250
         message, /info, "It seems pointing data are missing"
         message, /info, "press .c to proceed anyway, but be careful."
         stop
      endif
      
   endelse

endif

if param.cpu_time then nk_show_cpu_time, param

end
