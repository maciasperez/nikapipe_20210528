
;; ;; Quicklook to determine xy ranges
;; spawn, "find "+!nika.plot_dir+" -name *v1.fits -print", map_list
;; nmaps_per_window = 9
;; nmaps = n_elements(map_list)
;; my_multiplot, 1, 1, ntot=nmaps_per_window, pp, pp1, /rev, /full
;; for i=0, nmaps-1 do begin
;;    map = mrdfits( map_list[i], 1, h)
;;    if i mod nmaps_per_window eq 0 then wind, 1, 1, /free, /large
;;    imview, map, position=pp1[i mod nmaps_per_window,*], /noerase, $
;;            legend_text=file_basename(map_list[i]), /nobar
;; endfor


;;----------------------------------------------------------------------------
db_file = '$NIKA_SOFT_DIR/Pipeline/Datamanage/Logbook/' + $
          'Log_Iram_tel_Run11_v1.save'
restore, db_file, /verb

;; Find which projects have been observed
w = where( strupcase( strtrim(scan.obstype,2)) ne 'TRACK', nw)
proj_list = scan[w].projid
proj_list = proj_list[ uniq( proj_list, sort(proj_list))]
nproj = n_elements(proj_list)

niter = 1
;; For each project, find what sources were observed
for iproj=0, nproj-1 do begin

   ;; Replace "-" by "_" in project name
   proj_name = proj_list[iproj]
   a = strsplit( proj_list[iproj], "-", /extract)
   if n_elements(a) eq 2 then proj_name = a[0]+"_"+a[1]
   a = strsplit( proj_list[iproj], "+", /extract)
   if n_elements(a) eq 2 then proj_name = a[0]+"_"+a[1]
   proj_name = strupcase( strtrim(proj_name,2))

   if strupcase(proj_name) ne "T21" then begin

      w = where( strupcase( strtrim(scan.projid,2)) eq strupcase( strtrim(proj_list[iproj],2)), nw)
      proj_dir = !nika.pipeline_dir+"/Scr/Openpool3/"+strtrim(proj_name,2)
      source_list = scan[w].object
      source_list = source_list[ uniq( source_list, sort(source_list))]
      source_list = strupcase( strtrim( source_list, 2))

      ;; Replace the "-" and "+" by "minus" and "plus" in source names
      for i=0, n_elements(source_list)-1 do begin
         source_name = source_list[i]
         a = strsplit( source_list[i], "-", /extract)
         if n_elements(a) eq 2 then source_name = a[0]+"_minus_"+a[1]
         a = strsplit( source_list[i], "+", /extract)
         if n_elements(a) eq 2 then source_name = a[0]+"_plus_"+a[1]
         source_name = strtrim( strupcase(source_name),2)

         wind, 1, 1, /free, /large
         my_multiplot, 2, 2, pp, pp1, /rev 
         outplot, file=proj_name+"/"+source_list[i], png=png, ps=ps
         for iter=0, niter do begin
            file = !nika.plot_dir+"/"+proj_name+"/"+source_list[i]+"/v_1/MAPS_1mm_"+source_list[i]+"_v1_iter_"+strtrim(iter,2)+".fits"
            map1mm = mrdfits( file, 1, h)
            file = !nika.plot_dir+"/"+proj_name+"/"+source_list[i]+"/v_1/MAPS_2mm_"+source_list[i]+"_v1_iter_"+strtrim(iter,2)+".fits"
            map2mm = mrdfits( file, 1, h)
            
            imview, map1mm, position=pp1[2*iter+0,*], title=proj_name+"/"+source_list[i]+' 1mm (iter '+strtrim(iter,2)+')', /noerase
            imview, map2mm, position=pp1[2*iter+1,*], title=proj_name+"/"+source_list[i]+' 2mm (iter '+strtrim(iter,2)+')', /noerase

         endfor
         outplot, /close

;;          printf, u2, "script_"+strtrim(proj_name,2)+"_"+strtrim(source_name,2)+", nscans=nscans_out"
;;          printf, u2, "nscans += nscans_out"
;; 
;;          ;; One script per source
;;          typical_script, proj_dir, source_list[i], source_name, proj_name, $
;;                          preproc_only=preproc_only, niter=niter, short=short

      endfor
   endif
endfor

end
