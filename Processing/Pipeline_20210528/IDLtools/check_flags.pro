
pro check_flags, data, ikid_list, xra=xra, list=list, fields=fields, file=file, scan=scan

if n_params() lt 1 then begin
   message, /info, "calling sequence:"
   print, 'check_flags, data, ikid_list, xra=xra'
   return
endif
  
tags = tag_names(data)
wtag = where( strupcase(tags) eq "TOI", nwtag)

nkids = n_elements(ikid_list)
;;!p.multi = [0, 1, nkids]

;; messages = ['scanLoaded:1']               
;; messages = [messages, 'scanStarted:2']    
;; messages = [messages, 'scanDone:3']       
;; messages = [messages, 'subscanStarted:4'] 
;; messages = [messages, 'subscanDone:5']    
;; messages = [messages, 'scanbackOnTrack:6']
;; messages = [messages, 'subscan_tuning:7'] 
;; messages = [messages, 'scan_tuning:8']    
;; messages = [messages, 'scan_new_file:9']  

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
;; my_multiplot, 2, 1, ymin=0.7, pp, pp1
if not keyword_set(fields) then fields = ['ofs_az', 'ofs_el']
nfields = n_elements(fields)
if keyword_set(scan) then nplots = nfields+1 else nplots=nfields
my_multiplot, 1, nplots, pp, pp1, /rev
tags = tag_names(data)
erase
for ifield=0, nfields-1 do begin
   wtag = where( strupcase(tags) eq strupcase(fields[ifield]), nwtag)
   if nwtag eq 0 then begin
      message, /info, "no tag "+fields[ifield]
      return
   endif

   ikid = ikid_list[0]

   xmin = min(xra)
   xmax = max(xra)
   wt = where( time ge xmin and time le xmax)
   ymin = min(data[wt].(wtag))
   ymax = max(data[wt].(wtag))
   yra = [ymin, ymax+0.3*(ymax-ymin)]
   charsize = 0.6
   plot, time, data.(wtag), xtitle='Relative time since first sample (sec)', ytitle=fields[ifield], $
         xra=xra, position=pp1[ifield,*], /noerase, /xs, yra=yra, /ys
;;    for i=1, 9 do begin
;;       w = where( data.scan_st eq i, nw)
;;       if nw ne 0 then begin
;;          for j=0, nw-1 do begin
;;             oplot, [1,1]*time[w[j]], [ymin, ymax]
;;             xyouts, time[w[j]], ymin, messages[i-1], orient=90, chars=0.6
;;          endfor
;;       endif
;;    endfor

   leg_txt = ['Tuning en cours (2!u3!n)']
   ;; flag tuning en cours
   flagged = nk_where_flag( data.k_flag[ikid], 3, nflag=nflagged)
   if nflagged ne 0 then $
      for i=0, nflagged-1 do oplot, [1,1]*time[flagged[i]], [-1e20,ymax], col=200, thick=2

   ;; flag fpga_change_frequence
   leg_txt = [leg_txt, 'FPGA change freq (2!u2!n)']
   flagged = nk_where_flag( data.k_flag[ikid], 2, nflag=nflagged)
   if nflagged ne 0 then $
      for i=0, nflagged-1 do oplot, [1,1]*time[flagged[i]], [-1e20,ymax], col=250, thick=2

   ;; scan loaded
   my_loadct, col
   wd = where( data.scan_st eq 1, nwd)
   if nwd ne 0 then $
      for i=0, nwd-1 do oplot, [1,1]*time[wd[i]], [-1e20,ymax], col=col.purple

   ;; scan started
   wd = where( data.scan_st eq 2, nwd)
   if nwd ne 0 then $
      for i=0, nwd-1 do oplot, [1,1]*time[wd[i]], [-1e20,ymax], col=col.darkgreen

   ;; subscan done
   wd = where( data.scan_st eq 5, nwd)
   if nwd ne 0 then $
      for i=0, nwd-1 do oplot, [1,1]*time[wd[i]], [-1e20,ymax], col=col.blue
   loadct, 39, /silent

   
;;    ;; flag mauvais tuning
;;    flagged = nk_where_flag( data.k_flag[ikid], 5, nflag=nflagged)
;;    if nflagged ne 0 then $
;;       for i=0, nflagged-1 do oplot, [1,1]*time[flagged[i]], [-1e20,ymax], col=70, thick=2

   oplot, time, data.(wtag)
    for i=min(data.subscan), max(data.subscan) do begin
       w = where( data.subscan eq i, nw)
       if nw ne 0 then begin
          j = min(w)
          ;; xyouts, time[j], 0.8*max(data.(wtag)), "Subscan "+strtrim(long(i),2)
          xyouts, time[j], 0.8*max(data.(wtag)), "S"+strtrim(long(i),2)
       endif
    endfor

   ;; LP fix (with Alessandro) 
   ww = where( strupcase(tags) eq "FLAG", nww)
   if nww ne 0 then begin
      w = where( data.flag[ikid] ne 0, nw)
      ;;if nw ne 0 then oplot, time[w], data[w].(wtag), psym=1,col=100
      if nw gt 1 then oplot, time[w], data[w].(wtag), psym=1, col=100
   endif

   legendastro, [leg_txt], line=0, col=[200, 250, 70], box=0
   legendastro, ['flag /= 0'], box=0, /right, psym=1, col=100
   my_loadct, col
   legendastro, ['Scan loaded', 'Scan started', 'Subscan done'], $
                line=0, col=[col.purple, col.darkgreen, col.blue], box=0, /right
   loadct, 39, /silent
   ;; print messages in chronological order
   if keyword_set(file) and ifield eq 0 then begin
      j=0
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
         j++
      endwhile
      close, lu
      free_lun, lu
   endif

   if keyword_set(list) and ifield eq 0 then begin
      j=0
      message, /info, "#time (sec), message"
      while j le (nsn-1) do begin
         if time(j) ge min(xra) and time(j) le max(xra) then begin
            if data[j].scan_st ne 0 then print, time[j], " ", messages[data[j].scan_st-1]
         endif
         j++
      endwhile
   endif

endfor


if keyword_set(scan) then compare_messages, scan, position=pp1[nfields,*], t0=data[0].a_t_utc


;; stop
;; ;; TOI
;; my_multiplot, 1, nkids, ymax=0.6, pp, pp1
;; for ii=0, nkids-1 do begin
;;    ikid = ikid_list[ii]
;; 
;;    wtag = where( strupcase(tags) eq "TOI", nwtag)
;;    if nwtag ne 0 then begin
;;       y = data.toi[ikid]
;;       ytitle = 'data.toi'
;;    endif else begin
;;       y = data.rf_didq[ikid]
;;       ytitle='data.rf_didq'
;;    endelse
;;    
;; ;; Scan status and messages plot
;;    dy = max(y) - min(y)
;;    yra = minmax(y) + [-0.2, 0.2]*dy
;;    y1 = min(yra)
;;    y2 = max(yra) + 0.5*(max(yra)-min(yra))
;;    
;;    ymin = min(y)
;;    ymax = max(y)
;;    yra = [ymin, ymax+0.2*(ymax-ymin)]
;;    charsize = 0.6
;;    ;; outplot, file='Flags_'+scan_type+"_"+suffix, png=png, ps=ps
;;    plot, time, y, /xs, yra=yra, /ys, xra=xra, $
;;          xtitle='time (sec)', ytitle=ytitle, position=pp1[ii,*], /noerase
;; 
;;    leg_txt = ['Tuning en cours (2!u3!n)']
;;    ;; flag tuning en cours
;;    flagged = nk_where_flag( data.k_flag[ikid], 3, nflag=nflagged)
;;    if nflagged ne 0 then $
;;       for i=0, nflagged-1 do oplot, [1,1]*time[flagged[i]], [-1e20,ymax], col=200, thick=2
;; 
;;    ;; flag fpga_change_frequence
;;    leg_txt = [leg_txt, 'FPGA change freq (2!u2!n)']
;;    flagged = nk_where_flag( data.k_flag[ikid], 2, nflag=nflagged)
;;    if nflagged ne 0 then $
;;       for i=0, nflagged-1 do oplot, [1,1]*time[flagged[i]], [-1e20,ymax], col=250, thick=2
;; 
;; ;;    ;; flag mauvais tuning
;; ;;    flagged = nk_where_flag( data.k_flag[ikid], 5, nflag=nflagged)
;; ;;    if nflagged ne 0 then $
;; ;;       for i=0, nflagged-1 do oplot, [1,1]*time[flagged[i]], [-1e20,ymax], col=70, thick=2
;; 
;;    oplot, time, y
;;    for i=1, 9 do begin
;;       w = where( data.scan_st eq i, nw)
;;       if nw ne 0 then begin
;;          for j=0, nw-1 do begin
;;             oplot, [1,1]*time[w[j]], [ymin, ymax]
;;             xyouts, time[w[j]], ymin, messages[i-1], orient=90, chars=0.6
;;          endfor
;;       endif
;;    endfor
;;    for i=min(data.subscan), max(data.subscan) do begin
;;       w = where( data.subscan eq i, nw)
;;       if nw ne 0 then begin
;;          j = min(w)
;;          xyouts, time[j], 0.8*max(y), "Subscan "+strtrim(long(i),2)
;;       endif
;;    endfor
;; 
;;    ww = where( strupcase(tags) eq "FLAG", nww)
;;    if nww ne 0 then begin
;;       w = where( data.flag[ikid] ne 0, nw)
;;       if nw ne 0 then oplot, time[w], y[w], psym=1, col=100
;;    endif
;; 
;;    legendastro, [leg_txt], line=0, col=[250, 200, 70], box=0
;;    legendastro, ['flag /= 0'], box=0, /right, psym=1, col=100
;; endfor
;; !p.multi=0

;outplot, /close

end
