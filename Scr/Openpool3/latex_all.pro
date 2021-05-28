
pro latex_all, reset=reset

spawn, "ls "+!nika.plot_dir+"/*/*/*.tex", list

;dir_list = ['161_14/24528-0136', '222_14/0439+360']

;for idir=0, n_elements(dir_list)-1 do begin
   
;   spawn, "ls "+!nika.plot_dir+"/"+dir_list[idir]+"/*.tex", list

ll = strlen("project_report")

for i=0, n_elements(list)-1 do begin

   junk = file_basename(list[i])
   l = strlen(junk)
   print, strmid(junk,ll,l-ll-4)
   source = strmid(junk,ll+1,l-ll-4-1)
   proj = file_basename(file_dirname( file_dirname(list[i])))

   dat_file = !nika.plot_dir+"/"+proj+"_"+source+"_tex.dat"
   if keyword_set(reset) then begin
      spawn, "rm -f "+dat_file
   endif else begin
      if file_test( dat_file) eq 0 then begin
         spawn, "touch "+dat_file
         
         spawn, "latex "+list[i]
         spawn, "latex "+list[i]
         
         dvifile = file_basename(list[i])
         l = strlen(dvifile)
         nickname = strmid( dvifile, 0, l-4) 
         dvifile = nickname+".dvi"
         spawn, "dvipdf "+dvifile
         spawn, "mv "+nickname+".pdf "+file_dirname(list[i])+"/."
      endif else begin
         print, dat_file+" already exists"
      endelse
   endelse
endfor
;endfor

spawn, "rm -f *aux *log *toc *dvi"

end
