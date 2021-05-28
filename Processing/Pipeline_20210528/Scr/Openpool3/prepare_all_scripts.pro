
; Generates scripts for all projects and their sources

;preproc_only      = 1
;average_only      = 0
niter             = 0
short             = 0
list_results_only = 0
version           = 0
keep_current_result = 0 ; do not run the script if the map_*version.fits already exist (batch mode)
;;--------------------------------------------------------------------

db_file = '$NIKA_SOFT_DIR/Pipeline/Datamanage/Logbook/' + $
          'Log_Iram_tel_Run11_v1.save'
restore, db_file, /verb

;; Find which projects have been observed
w = where( strupcase( strtrim(scan.obstype,2)) ne 'TRACK', nw)
proj_list = scan[w].projid
proj_list = proj_list[ uniq( proj_list, sort(proj_list))]
nproj = n_elements(proj_list)

get_lun, u_preproc
get_lun, u_average
get_lun, u_iterate

openw,   u_preproc, !nika.pipeline_dir+"/Scr/Openpool3/all_projects_preproc.pro"
printf,  u_preproc, "pro all_projects_preproc, list_results_only=list_results_only"

openw,   u_average, !nika.pipeline_dir+"/Scr/Openpool3/all_projects_average.pro"
printf,  u_average, "pro all_projects_average, list_results_only=list_results_only"

openw,   u_iterate, !nika.pipeline_dir+"/Scr/Openpool3/all_projects_iterate.pro"
printf,  u_iterate, "pro all_projects_iterate, list_results_only=list_results_only"

;; endif else begin
;;    openw,   u_preproc, !nika.pipeline_dir+"/Scr/Openpool3/all_projects.pro"
;;    printf,  u_preproc, "pro all_projects, list_results_only=list_results_only"
;; endelse

nscans_per_proj = intarr(nproj)
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

      printf, u_preproc, "project_"+proj_name+", nscans=nscans, list_results_only=list_results_only, /preproc"
      printf, u_average, "project_"+proj_name+", nscans=nscans, list_results_only=list_results_only, /average"
      printf, u_iterate, "project_"+proj_name+", nscans=nscans, list_results_only=list_results_only, /preproc, /subtract"

      ;; Make the project directory
      w = where( strupcase( strtrim(scan.projid,2)) eq strupcase( strtrim(proj_list[iproj],2)), nw)
      proj_dir = !nika.pipeline_dir+"/Scr/Openpool3/"+strtrim(proj_name,2)
      spawn, "mkdir -p "+proj_dir

      source_list = scan[w].object
      source_list = source_list[ uniq( source_list, sort(source_list))]
      source_list = strupcase( strtrim( source_list, 2))

      ;; Create the project routine
      get_lun, u2
      openw,  u2, proj_dir+"/project_"+proj_name+".pro"
      printf, u2, "pro project_"+proj_name+", nscans=nscans, list_results_only=list_results_only, $"
      printf, u2, "                           preproc=preproc, average=average, subtract_maps=subtract_maps, reset=reset"

      ;; Replace the "-" and "+" by "minus" and "plus" in source names if
      ;; needed
      printf, u2, "nscans = 0"
      for i=0, n_elements(source_list)-1 do begin

         case strupcase( strtrim(source_list[i],2)) of
            "MARS":    goto, ciao
            "URANUS":  goto, ciao
            "SATURN":  goto, ciao
            "JUPITER": goto, ciao
            else:begin
               source_name = source_list[i]
               a = strsplit( source_list[i], "-", /extract)
               if n_elements(a) eq 2 then source_name = a[0]+"_minus_"+a[1]
               a = strsplit( source_list[i], "+", /extract)
               if n_elements(a) eq 2 then source_name = a[0]+"_plus_"+a[1]
               source_name = strtrim( strupcase(source_name),2)
               
               printf, u2, "script_"+strtrim(proj_name,2)+"_"+strtrim(source_name,2)+$
                       ", nscans=nscans_out, list_results_only="+strtrim(list_results_only,2)+$
                       ", keep_current_result="+strtrim(keep_current_result,2)+", preproc=preproc, average=average, subtract_maps=subtract_maps, reset=reset"
               ;;printf, u2, "nscans += nscans_out"
               
               ;; One script per source
               typical_script, proj_dir, source_list[i], source_name, proj_name, $
                               preproc_only=preproc_only, niter=niter, short=short, version=version, $
                               keep_current_result=keep_current_result, average_only=average_only

            end
         endcase
         ciao:
      endfor

      printf, u2, ""
      printf, u2, "end"
      close, u2
      free_lun, u2
   endif
endfor


printf,   u_preproc, "end"
close,    u_preproc
free_lun, u_preproc

printf,   u_average, "end"
close,    u_average
free_lun, u_average

printf,   u_iterate, "end"
close,    u_iterate
free_lun, u_iterate


end

