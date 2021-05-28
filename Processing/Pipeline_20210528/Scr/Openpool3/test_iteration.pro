
;; Trying to iterate automatically while running multiple IDL sessions


;; script_test, /reset
;print, "recode reset on all iterations"
;stop

cpu_t0 = systime( 0, /sec)
iter = 1

for iter=1, 2 do begin
   message, /info, "Starting iteration # "+strtrim(iter,2)
   message, /info, "Starting iteration # "+strtrim(iter,2)
   message, /info, "Starting iteration # "+strtrim(iter,2)

   script_test, param, scan_list, /pre, iter=iter, /map4iter
   nscans = n_elements(scan_list)
   
;; Wait untill all scans have been processed
   spawn, "ls "+param.up_dir+"/OK*dat", ok_list
   while n_elements(ok_list) ne nscans do begin
      print, "waiting for all scans to be processed..."
      wait, 1
      spawn, "ls "+param.up_dir+"/OK*dat", ok_list
   endwhile
   print, "all scans have been processed now"
   
;; Averaging the scans
   average_iter_file = param.project_dir+"/running_iter"+strtrim(iter,2)+".dat"
   goon_file = param.project_dir+"/goon_iter"+strtrim(iter,2)+".dat"
   if file_test(average_iter_file) eq 0 then begin
      print, "Averaging scans..."
      spawn, "touch "+average_iter_file
      script_test, /average, iter=iter
      spawn, "touch "+goon_file
      print, "average done"
   endif
   
   while file_test(goon_file) eq 0 do begin
      print, "waiting for goonfile..."
      wait, 1
   endwhile
   print, "end of iteration "+strtrim(iter,2)+"."
endfor
   
cpu_t1 = systime( 0, /sec)
print, "CPU Time: ", cpu_t1-cpu_t0


;; avec trois scans
;; en bi-IDL: 170 sec
;; en mono IDL: 232
end
