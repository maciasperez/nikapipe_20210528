
pro nk_logbook_sub, scan_num, day

if n_params() lt 1 then begin
   message, /info, "calling sequence"
   print, "nk_logbook_sub, scan_num, day"
   return
endif

;; Ensure correct format for "day"
t = size( day, /type)
if t eq 7 then day = strtrim(day,2) else day = string( day, format="(I8.8)")

scan = day+"s"+strtrim(scan_num,2)

logbook_output_dir = !nika.plot_dir+"/Logbook/Scans/"+scan
spawn, "mkdir -p "+logbook_output_dir

get_lun,  lu
openw,  lu, logbook_output_dir+"/plots_"+scan+".html"
printf, lu, "<?xml version='1.0' encoding='iso-8859-1' ?>"
printf, lu, "<!DOCTYPE html"
printf, lu, "     PUBLIC '-//W3C//DTD XHTML 1.0 Transitional//EN'"
printf, lu, "     'DTD/xhtml1-transitional.dtd'>"
printf, lu, "<html>"
printf, lu, "<body>"
printf, lu, "<a href='../../logbook_"+day+".html'>Back to "+day+" logbook</a>"
printf, lu, "<center>"
printf, lu, "<br><br>"
printf, lu, "<table width='80%'><tbody>"

loc_dir = "."
spawn, "ls "+logbook_output_dir+"/*png", png_list
png_list = file_basename(png_list)
png_list = loc_dir+"/"+png_list
if png_list[0] ne '' then begin
   n_png = n_elements(png_list)
   height_list = [replicate(150,n_png)]

   ;; Display all plots in reduced format, 3 per line
   for j=0, n_png-1 do begin
      if j mod 3 eq 0 then printf, lu, "<tr align='center'>"
      printf, lu, "<td><a href='"+png_list[j]+"'><img src='"+png_list[j]+"' height="+strtrim(height_list[j],2)+"></a></td>"
      if j mod 3 eq 2 or j eq (n_png-1) then printf, lu, "</tr>"
   endfor      
endif

;; ;; convert .eps to .jpg if any
;; spawn, "ls "+logbook_output_dir+"/*eps", eps_list
;; eps_list = file_basename(eps_list)
;; if eps_list[0] ne '' then begin
;;    for i=0, n_elements(eps_list)-1 do begin
;;       l = strlen(eps_list[i])
;;       spawn, "convert "+logbook_output_dir+"/"+eps_list[i]+" "+$
;;              logbook_output_dir+"/"+strmid(eps_list[i],0,l-4)+".jpg"
;;    endfor
;; endif

;; spawn, "ls "+logbook_output_dir+"/*jpg", jpg_list
;; jpg_list = file_basename(jpg_list)
;; jpg_list = loc_dir+"/"+jpg_list
;; if jpg_list[0] ne '' then begin
;;    n_jpg = n_elements(jpg_list)
;;    height_list = [replicate(150,n_jpg)]
;; 
;;    ;; Display all plots in reduced format, 3 per line
;;    for j=0, n_jpg-1 do begin
;;       if j mod 3 eq 0 then printf, lu, "<tr align='center'>"
;;       printf, lu, "<td><a href='"+jpg_list[j]+"'><img src='"+jpg_list[j]+"' height="+strtrim(height_list[j],2)+"></a></td>"
;;       if j mod 3 eq 2 or j eq (n_jpg-1) then printf, lu, "</tr>"
;;    endfor      
;; endif

printf, lu, "</tbody></table></center></body></html>"
close, lu
free_lun,  lu


end
