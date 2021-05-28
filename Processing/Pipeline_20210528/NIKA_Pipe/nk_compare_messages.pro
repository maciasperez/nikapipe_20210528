
;; Compare messages and their associated times between AntMD and our
;; data

pro nk_compare_messages, param, scan, position=position, t0=t0, charsize=charsize
  
;;scan = '20160118s120'

nika_file  = !nika.plot_dir+"/Logbook/Scans/"+scan+"/messages.dat"
antmd_file = !nika.plot_dir+"/Logbook/Scans/"+scan+"/antmd_messages.dat"

readcol, nika_file, nika_time, nika_message, $
         delim=',', comment="#", format='A,A', /silent
nnika = n_elements(nika_time)

readcol, antmd_file, ant_time, ant_message, $
         delim=',', comment="#", format='A,A', /silent
nant = n_elements(ant_time)

nika_message = strtrim(nika_message,2)
ant_message = strtrim(ant_message,2)

npts = nnika+nant
civil_time = [nika_time, ant_time]
time = dblarr( npts)
if keyword_set(t0) then time += t0
system = strarr(npts)
system[0:nnika-1] = "Nika"
system[nnika:*]   = "AntMD"
nika_utc = dblarr(nnika)
ant_utc  = dblarr(nant)
for i=0, nnika-1 do begin
   x = strsplit( nika_time[i], ":", /extract)
   time[i] = double(x[0])*3600.d0 + double(x[1])*60.d0 + double(x[2])
   nika_utc[i] = time[i]
endfor
for i=0, nant-1 do begin
   x = strsplit( ant_time[i], ":", /extract)
   time[nnika+i] = double(x[0])*3600.d0 + double(x[1])*60.d0 + double(x[2])
   ant_utc[i] = time[nnika+i]
endfor

;; Loop over the NIKA messages and look the nearest before identical message
t0 = nika_utc[0]
;print, "#message, Tnika - T_ant, Tnika-Tnika(0)"
dt_nika_ant = dblarr( nnika) + !values.d_nan
dt_abs      = dblarr( nnika) + !values.d_nan
for i=0, nnika-1 do begin
   wa = where( strupcase( ant_message) eq strupcase(nika_message[i]), nwa)
   if nwa ne 0 then begin
      dt_all = nika_utc[i]-ant_utc[wa]
      ww = where( dt_all ge 0, nww)
      dt_abs[i] = nika_utc[i]-t0
      dt_nika_ant[i] = min( dt_all[ww])
      if nww ne 0 then dt = strtrim(dt_nika_ant[i],2)+", "+strtrim(dt_abs[i],2) else dt = "?"
      ;print, nika_message[i]+", "+strtrim(dt,2)
   endif else begin
      ;print, nika_message[i]+", ?"
   endelse
endfor

;; Plot
bb = nika_message[UNIQ(nika_message, SORT(nika_message))]
nbb = n_elements(bb)
my_loadct, col
ct = fltarr(nbb)
w = where( strupcase(bb) eq strupcase("backontrack"))
ct[w] = col.black
w = where( strupcase(bb) eq strupcase("scandone"))
ct[w] = col.brown
w = where( strupcase(bb) eq strupcase("scanloaded"))
ct[w] = col.purple
w = where( strupcase(bb) eq strupcase("scanstarted"))
ct[w] = col.brown
w = where( strupcase(bb) eq strupcase("subscanstarted"))
ct[w] = col.darkgreen
w = where( strupcase(bb) eq strupcase("subscandone"))
ct[w] = col.blue
w = where( strupcase(bb) eq strupcase("subscan_tuning"))
ct[w] = col.red

ylog = 1
yra = [1e-2, max(dt_nika_ant)*1.5]

xra = [0, max(dt_abs)]
if keyword_set(position) then noerase=1
;if param.plot_ps eq 0 then wind, 1, 1, /free, /xlarge, iconic=param.iconic
;outplot, file=param.plot_dir+"/check_messages_"+scan, png=param.plot_png, ps=param.plot_ps
plot, xra, yra, /nodata, /xs, /ys, yra=yra, ylog=ylog, $
      xtitle="Elapsed time since NIKA's first message (sec)", ytitle='T!dNika!n - T!dAntMD!n', $
      position=position, noerase=noerase, charsize=charsize
oplot, xra, xra*0 + 0.3
xyouts, 0.01*(max(xra)-min(xra)), 0.32, '300 msec'
for i=0, nnika-1 do begin
   w = where( strupcase(bb) eq strupcase(nika_message[i]),nw)
   oplot, [dt_abs[i]], [dt_nika_ant[i]], psym=8, col=ct[w], syms=0.5
endfor
legendastro, bb[0:1], textcol=ct[0:1], /bottom, chars=0.6
legendastro, bb[1:2], textcol=ct[1:2], /bottom, chars=0.6, /center
legendastro, bb[3:*], textcol=ct[3:*], /bottom, chars=0.6, /right
loadct, 39

;; ;; last know message
;; my_message = strtrim( strupcase(['scanLoaded', 'scanStarted', 'backOnTrack', 'subscan_tuning', $
;;                                  'subscanDone', 'subscanStarted', 'scanDone']), 2)
;; nmess = n_elements( my_message)


;; for i=0, nmess-1 do begin
;;    print, my_message[i]
;;    ;; loop for a message in nika data
;;    w = where( strupcase(nika_message) eq my_message[i], nw)
;;    if nw ne 0 then begin
;;       ;; if present, look for the same message in AntMD
;;       wa = where( strupcase( ant_message) eq my_message[i], nwa)
;;       if nwa ne 0 then begin
;;          ;; for all similar messages in nika, look for the closest in Antmd
;;          for j=0, nw-1 do begin
;;             dt_all = nika_utc[w[j]]-ant_utc[wa]
;;             ww = where( dt_all ge 0, nw)
;;             dt = min( dt_all[ww])
;;             print, nika_message[w[j]]+", "+strtrim(dt,2)
;;          endfor
;;       endif
;;    endif
;;    print, ""
;; endfor


;; ;; All messages in chronological order
;; mess = [nika_message, ant_message]
;; order  = sort(time)
;; time   = time[order]
;; mess   = mess[order]
;; system = system[order]
;; civil_time = civil_time[order]
;; 
;; openw, lu, "all_messages_"+scan+".dat", /get_lun
;; for i=0, npts-1 do begin
;;    if i ge 1 then dt = time[i] - time[i-1] else dt = 0
;; ;   print, system[i]+": "+mess[i]+", "+civil_time[i]+", "+strtrim(dt,2)
;;    if strupcase(system[i]) eq "NIKA" then $
;;       space = '                                    ' else space =''
;;    printf, lu, space+system[i]+": "+mess[i]+", "+civil_time[i];+", "+strtrim(dt,2)
;; endfor
;; close, lu
;; free_lun, lu




;; ;; subscanstarted only
;; w = where( strtrim(strupcase(mess),2) eq strupcase("subscanStarted"), nw)
;; for ii=0, nw-1 do begin
;;    i = w[ii]
;;    if ii eq 0 then t=time[i]
;;    dt = time[i]-t
;;    ;print, system[i]+": "+mess[i]+", "+civil_time[i]+", "+strtrim(dt,2)
;;  ;  if strupcase(system[i]) eq "NIKA" then print, system[i]+": "+mess[i]+", "+civil_time[i]+", "+strtrim(dt,2)
;;    if strupcase(system[i]) eq "NIKA" then printf, lu, system[i]+": "+mess[i]+", "+civil_time[i]+", "+strtrim(dt,2)
;;    t = time[i]
;; endfor
;; printf, lu, ""
;; 
;; ;; subscandone only
;; w = where( strtrim(strupcase(mess),2) eq strupcase("subscandone"), nw)
;; for ii=0, nw-1 do begin
;;    i = w[ii]
;;    if ii eq 0 then t=time[i]
;;    dt = time[i]-t
;;    ;print, system[i]+": "+mess[i]+", "+civil_time[i]+", "+strtrim(dt,2)
;;    ;if strupcase(system[i]) eq "NIKA" then print, system[i]+": "+mess[i]+", "+civil_time[i]+", "+strtrim(dt,2)
;;    if strupcase(system[i]) eq "NIKA" then printf, lu, system[i]+": "+mess[i]+", "+civil_time[i]+", "+strtrim(dt,2)
;;    t = time[i]
;; endfor
;; printf, lu, ""
;; 
;; ;; backontrack only
;; w = where( strtrim(strupcase(mess),2) eq strupcase("backontrack"), nw)
;; for ii=0, nw-1 do begin
;;    i = w[ii]
;;    if ii eq 0 then t=time[i]
;;    dt = time[i]-t
;;    ;print, system[i]+": "+mess[i]+", "+civil_time[i]+", "+strtrim(dt,2)
;;    ;if strupcase(system[i]) eq "NIKA" then print, system[i]+": "+mess[i]+", "+civil_time[i]+", "+strtrim(dt,2)
;;    if strupcase(system[i]) eq "NIKA" then printf, lu, system[i]+": "+mess[i]+", "+civil_time[i]+", "+strtrim(dt,2)
;;    t = time[i]
;; endfor
;; close, lu
;; free_lun, lu
 
end




