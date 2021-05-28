
pro nika_logbook_sub, scan_num, day

;; Ensure correct format for "day"
t = size( day, /type)
if t eq 7 then day = strtrim(day,2) else day = string( day, format="(I8.8)")

logbook_output_dir = !nika.plot_dir+"/Logbook/Scans/"+day+"s"+strtrim(scan_num,2)
spawn, "mkdir -p "+logbook_output_dir

get_lun,  lu
openw,  lu, logbook_output_dir+"/plots_"+day+"s"+strtrim(scan_num,2)+".html"
printf, lu, "<?xml version='1.0' encoding='iso-8859-1' ?>"
printf, lu, "<!DOCTYPE html"
printf, lu, "     PUBLIC '-//W3C//DTD XHTML 1.0 Transitional//EN'"
printf, lu, "     'DTD/xhtml1-transitional.dtd'>"
printf, lu, "<html>"
printf, lu, "<body>"
printf, lu, "<a href='../logbook_"+day+".html'>Back to "+day+" logbook</a>"
printf, lu, "<center>"
printf, lu, "<br><br>"
printf, lu, "<table width='80%'><tbody>"

spawn, "ls "+!nika.plot_dir+"/Scans/"+day+"s"+strtrim(scan_num, 2)+"/*png", png_list
png_list = file_basename(png_list)

stop
if png_list[0] ne '' then begin
   n_png = n_elements(png_list)
   height_list = [replicate(300,n_png)]

   n_plot_x = 1 ; init
   n_plot_y = 1
   my_multiplot, n_plot_x, n_plot_y, pp, pp1, ntot=n_png

   p = 0
   for j=0, n_plot_y-1 do begin
      printf, lu, "<tr align='center'>"
      for i=0, n_plot_x-1 do begin
         if p lt n_png then printf, lu, "<td><a href='./"+png_list[p]+"'><img src='./"+png_list[p]+"' height="+strtrim(height_list[p],2)+"></a></td>"
         p += 1
      endfor
      printf, lu, "</tr>"
   endfor
      
endif ;; png_list[0] ne ''
printf, lu, "</tbody></table></center></body></html>"
close, lu
free_lun,  lu


end
