
pro nk_logbook, day

if n_params() lt 1 then begin
   message, /info, "Calling sequence: "
   print, "nk_logbook, day"
   return
endif

;; Ensure correct format for "day"
t = size( day, /type)
if t eq 7 then day = strtrim(day,2) else day = string( day, format="(I8.8)")

;; Get list of today directories
spawn, "ls -d "+!nika.plot_dir+"/Logbook/Scans/"+day+"s*", dir_list

ndir = n_elements(dir_list)
; Sort by reverse chronological order
scnum = strtrim( strmid(file_basename(dir_list),9),  2)
if ndir gt 0 then dir_list = dir_list[ reverse(sort( long(scnum)))]

;; Parameters to log
param_list = ['Scan Num', 'Scan type', 'Source', 'Opacity',  'Quicklook']
tag_list   = ['scan_num', 'scan_type', 'source', 'none', 'none']

;; Create the logbook
get_lun, lu
openw,  lu, !nika.plot_dir+"/Logbook/logbook_"+day+".html"
printf, lu, "<?xml version='1.0' encoding='iso-8859-1' ?>"
printf, lu, "<!DOCTYPE html"
printf, lu, "     PUBLIC '-//W3C//DTD XHTML 1.0 Transitional//EN'"
printf, lu, "     'DTD/xhtml1-transitional.dtd'>"
printf, lu, "<html>"
printf, lu, "<body>"
printf, lu, "<center>"
printf, lu, "<br><br>"
printf, lu, "<b><font size=4> RTA logbook, "+strmid(day,0,4)+"-"+strmid(day,4,2)+"-"+strmid(day,6,2)+"</font></b>"
printf, lu, "<br><br>"
printf, lu, "<table width='80%' border='1'><tbody>"

printf, lu, "<tr align='center'>"
str = ''
for i=0, n_elements(param_list)-1 do str = str+"<td><b>"+param_list[i]+"</b></td>"
printf, lu, str
printf, lu, "</tr>"

;print, dir_list

for idir=0, ndir-1 do begin
   dirname = file_basename( dir_list[idir])
;   spawn, "ls "+dir_list[idir]+"/log_info.save", logfile
;   if logfile[0] ne '' then begin
; FXD recode
   logfile = dir_list[idir]+ '/log_info.save'

   ;; to print results for focus sequences
   focuslogfile = dir_list[idir]+"/focus_nklog_info.save"
   if file_test(focuslogfile) then logfile = focuslogfile
   
   res = file_test( logfile)
   if res eq 1 then begin
      printf, lu, "<tr align='center'>"
      restore, logfile
      tags = tag_names( log_info)
      str = '' ; init
      for i=0, n_elements(param_list)-1 do begin

         w = where( strupcase(tags) eq strupcase(tag_list[i]), nw)
         if nw ne 0 then begin
            if strupcase(param_list[i]) eq "SCAN NUM" then begin
               str = str+"<td>"+strtrim(log_info.(w),2)
               if tag_exist(log_info,'ut') then begin
                  if typename(log_info.ut) eq "STRING" then begin
                     str += '<br>'+log_info.ut
                  endif
               endif
               if tag_exist(log_info,'az') then str += '<br>Az: '+strtrim(string(log_info.az,format='(I)'),2)
               if tag_exist(log_info,'el') then str += '<br>El: '+strtrim(string(log_info.el,format='(I)'),2)
               str += "</td>"
            endif else begin
               str = str+"<td>"+strtrim(log_info.(w),2)+"</td>"
            endelse
         endif else begin

;;             ;;-----------------
;;             if strupcase(param_list[i]) eq "RESULTS" then begin
;;                str = str+"<td align='left'>"
;;                w = where( finite(log_info.result_value), nw)    
;;                if nw ne 0 then begin
;;                   for iw=0, nw-1 do begin
;;                      if log_info.result_value[iw] eq !undef then begin
;;                         str = str+" "+$
;;                               strtrim( log_info.result_name[iw],2)
;;                      endif else begin
;;                         if (abs(log_info.result_value[iw]) ge 1000 or $
;;                             abs(log_info.result_value[iw]) lt 0.01) then $
;;                                format0 = '(E8.1)' else format0 = '(F7.2)'
;;                         
;;                         str = str+" "+$
;;                               strtrim( log_info.result_name[iw],2)+": "+$
;;                               strtrim( string(log_info.result_value[iw],format=format0),2)+"<br>"
;;                      endelse
;;                   endfor
;;                endif
;;                str = str+"</td>"
;; ;               message, /info, "str: "+str
;; ;               stop
;;             endif

            ;;-----------------
            if strupcase(param_list[i]) eq "QUICKLOOK" then $
            str = str+"<td> <a href='./Scans/"+dirname+"/plots_"+dirname+".html'><img src='./Scans/"+dirname+"/plot_"+dirname+".png' height=100</img></a></td>"

            ;;-----------------
;;             if strupcase(param_list[i]) eq "OPACITY" then $
;;                str = str+"<td>Tau (1mm): "+log_info.tau_1mm+"<br> Tau (2mm): "+ $
;;                      log_info.tau_2mm+"</td>"
            if strupcase(param_list[i]) eq "OPACITY" then begin
               if tag_exist(log_info,'tau225') then begin
                  str = str+"<td align='left'>Tau 225GHz: "+log_info.tau225
               endif else begin
                  str = str+$
                        "<td align='left'>Tau   (1mm): "+log_info.tau_1mm+$
                        "<br>Tau   (2mm): "+log_info.tau_2mm
               endelse

               ;if tag_exist( log_info, "atmo_ampli_1mm") then str = str+"<br>Ampl  (1mm): "+log_info.atmo_ampli_1mm
               ;if tag_exist( log_info, "slope_1mm") then str = str+"<br>Slope (1mm): "+log_info.slope_1mm
               ;if tag_exist( log_info, "atmo_ampli_2mm") then str = str +"<br>Ampl  (2mm): "+log_info.atmo_ampli_2mm
               ;if tag_exist( log_info, "slope_2mm") then begin
               ;   str = str+"<br>Slope (2mm): "+log_info.slope_2mm+"</td>"
               ;endif else begin
                  str = str+"</td>"
               ;endelse
            endif

         endelse
      endfor

      printf, lu, str
      printf, lu, "</tr>"
   endif
endfor
printf, lu, "</tbody></table></center></body></html>"
close, lu
free_lun, lu



end
