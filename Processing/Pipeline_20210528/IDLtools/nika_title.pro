
;+
pro nika_title, info, object=object, ut=ut, scan=scan, az=az, el=el, all=all, $
                charsize=charsize, title=title, right=right, silent=silent
;-

if n_params() lt 1 then begin
   dl_unix, 'nika_title'
   return
endif
  
if keyword_set(all) then begin
   object = 1
   ut = 1
   scan = 1
   az = 1
   el = 1
endif

if not keyword_set(title) then title = ''

if keyword_set(scan)      then title = info.scan+' '+title
if keyword_set(object)    then title = info.object+' '+title
if keyword_set(az)        then title = 'az'+strtrim( round(info.azimuth_deg),2)+' '+title
if keyword_set(el)        then title = 'el'+strtrim( round(info.result_elevation_deg), 2)+' '+title
if keyword_set(ut) and tag_exist(info,'UT') then title = info.ut+' '+title

title = strtrim(title,2)

if not keyword_set(silent) then begin
   x = !x.window[0]
   y = !y.window[1]+(!y.window[1]-!y.window[0])*0.01
   if keyword_set(right) then x = !x.window[0] + (!x.window[1]-!x.window[0])*0.9
   xyouts, x, y, /normal, title, charsize=charsize
endif

end
