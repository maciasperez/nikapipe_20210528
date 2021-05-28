
pro gather_products
;; Gathers results for delivery to astronomers
;;--------------------------------------------------------------------

spawn, "ls "+!nika.plot_dir+"/*/*/*1mm*v0.fits", map_1mm_list
res_dir = !nika.plot_dir+"/Results_V0"
spawn, "mkdir "+res_dir
nmaps = n_elements( map_1mm_list)

for i=0, nmaps-1 do begin
   dir = file_dirname(map_1mm_list[i])

   lroot = strlen( dir+"/MAPS_1mm_")
   lext  = strlen( "_v0.fits")
   l     = strlen( map_1mm_list[i])

   source = strmid( map_1mm_list[i], lroot, l-lroot-lext)
   project = file_basename(file_dirname(dir))
   file_1mm = map_1mm_list[i]
   file_2mm = dir+"/MAPS_2mm_"+source+"_v0.fits"

   print, ""
   print, "source: ", source
   print, "project: ", project
;   if strtrim( strupcase(source),2) eq 'NGP6_1' then begin
;   endif else begin
      res_dir1 = res_dir+"/"+project+"/"+source
      spawn, "mkdir -p "+res_dir1
      spawn, "cp "+file_1mm+" "+res_dir1+"/."
      spawn, "cp "+file_2mm+" "+res_dir1+"/."
      spawn, "cp "+dir+"/*pdf "+res_dir1+"/."
      spawn, "cp "+dir+"/*csv "+res_dir1+"/."
;   endelse
endfor


end

