
pro nika_logbook, day

if n_params() lt 1 then begin
   message, /info, "Calling sequence: "
   print, "nika_logbook, day"
   return
endif

;; Ensure correct format for "day"
t = size( day, /type)
if t eq 7 then day = strtrim(day,2) else day = string( day, format="(I8.8)")

;; Get list of today directories
spawn, "ls -d "+!nika.plot_dir+"/"+day+"s*", dir_list
;print, dir_list
ndir = n_elements(dir_list)
; Try to sort by scan number
scnum = strtrim( strmid(file_basename(dir_list),9),  2)
if ndir gt 0 then dir_list = dir_list[ sort( long(scnum))]

;; Parameters to log
param_list = ['Scan Num', 'Scan type', 'Source', 'Elevation',      'Opacity', 'Results', 'Quicklook']
tag_list   = ['scan_num', 'scan_type', 'source', 'mean_elevation', 'none',    'none',    'none']

;; Create the logbook
openw, 1, !nika.plot_dir+"/logbook_"+day+".html"
printf, 1, "<?xml version='1.0' encoding='iso-8859-1' ?>"
printf, 1, "<!DOCTYPE html"
printf, 1, "     PUBLIC '-//W3C//DTD XHTML 1.0 Transitional//EN'"
printf, 1, "     'DTD/xhtml1-transitional.dtd'>"
printf, 1, "<html>"
printf, 1, "<body>"
printf, 1, "<center>"
printf, 1, "<br><br>"
printf, 1, "<b><font size=4> RTA logbook, "+strmid(day,0,4)+"-"+strmid(day,4,2)+"-"+strmid(day,6,2)+"</font></b>"
printf, 1, "<br><br>"
printf, 1, "<table width='80%' border='1'><tbody>"

printf, 1, "<tr align='center'>"
str = ''
for i=0, n_elements(param_list)-1 do str = str+"<td><b>"+param_list[i]+"</b></td>"
printf, 1, str
printf, 1, "</tr>"

stop

for idir=0, ndir-1 do begin
   dirname = file_basename( dir_list[idir])
;   spawn, "ls "+dir_list[idir]+"/log_info.save", logfile
;   if logfile[0] ne '' then begin
; FXD recode
   logfile = dir_list[idir]+ '/log_info.save'
   res = file_test( logfile)
   if res eq 1 then begin
      printf, 1, "<tr align='center'>"
      restore, logfile
      tags = tag_names( log_info)
      str = '' ; init
      for i=0, n_elements(param_list)-1 do begin

         w = where( strupcase(tags) eq strupcase(tag_list[i]), nw)
         if nw ne 0 then begin
            str = str+"<td>"+strtrim(log_info.(w),2)+"</td>"
         endif else begin

            ;;-----------------
            if strupcase(param_list[i]) eq "RESULTS" then begin
               str = str+"<td>"
               w = where( finite(log_info.result_value), nw)    
               if nw ne 0 then begin
                  for iw=0, nw-1 do begin
                     if log_info.result_value[iw] eq !undef then begin
                        str = str+" "+$
                              strtrim( log_info.result_name[iw],2)
                     endif else begin
                        if (abs(log_info.result_value[iw]) ge 1000 or $
                            abs(log_info.result_value[iw]) lt 0.01) then $
                               format0 = '(E8.1)' else format0 = '(F7.2)'
                        
                        str = str+" "+$
                              strtrim( log_info.result_name[iw],2)+": "+$
                              strtrim( string(log_info.result_value[iw],format=format0),2)+"<br>"
                     endelse
                  endfor
               endif
               str = str+"</td>"
            endif

            ;;-----------------
            if strupcase(param_list[i]) eq "QUICKLOOK" then $
               ;str = str+"<td> <a href='"+ dirname+ "/plots_"+day+"_"+ $
               ;      strtrim(log_info.scan_num,2)+".html'>Quicklook</a></td>"
               str = str+"<td> <a href='"+ dirname+ "/plots_"+day+"s"+ $
                     strtrim(log_info.scan_num,2)+".html'><img src='"+ dirname+ "/plot_"+day+"s"+strtrim(log_info.scan_num,2)+".png' height=100</img></a></td>"

; FXD: need relative paths
;;str = str+"<td> <a href='"+dir_list[idir]+"/plots_"+day+"_"+strtrim(log_info.scan_num,2)+".html'>Quicklook</a></td>"


            ;;-----------------
            if strupcase(param_list[i]) eq "OPACITY" then $
               str = str+"<td>Tau (1mm): "+log_info.tau_1mm+"<br> Tau (2mm): "+ $
                     log_info.tau_2mm+"</td>"



         endelse
      endfor

      printf, 1, str
      printf, 1, "</tr>"
   endif
endfor
printf, 1, "</tbody></table></center></body></html>"
close, 1



end
