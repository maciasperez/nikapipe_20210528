

pro auto_nk_rta, iconic = iconic, catch_up=catch_up

spawn, "touch bidon.dat"
spawn, "ls -rlt bidon.dat", bidon
nk_get_file_date, bidon[0], start_time
spawn, "rm -f bidon.dat"
  
;; Data directory
;; nika2_dir = "/home/nika2/NIKA/Data/run13_X/scan_24X"
nika2_dir = "/home/nika2/NIKA/Data/run15_X/scan_24X"
  
;; ;; to train
;; nika2_dir = "."

mydir     = !nika.plot_dir+"/Temp_files"
spawn, "mkdir "+mydir

l_tot = strlen( mydir+"/F_2015_10_17_A0_0094")
l1    = strlen( mydir+'/F_2015_10_17_A0_')
l2    = strlen( mydir+'/F_')

n_ref = 0
n = n_ref
;; Every second, I check if a new scan has appeared
while n eq n_ref do begin

   ;; F_ files are produce when a scan is done.
   ;; Copy F files into mydir
   spawn, "rsync -avuzq "+nika2_dir+"/F* "+mydir+"/. 2> /dev/null"
   
   ;; List F_ files currently present in mydir.
   spawn, "ls -rlt "+mydir+"/F* 2> /dev/null", list
   n = n_elements(list)
   
   ;; Test these files
   if strlen(list[0]) ne 0 then begin
      for ifile=0, n_elements(list)-1 do begin
         
         ;; Deduce scan from file name
         myscan   = strmid( list[ifile], l1, 4)
         date     = strmid( list[ifile], l2, 10)
         day      = str_replace(date,"_","",/global)
         scan_num = long( myscan)
         scan     = day+"s"+strtrim(scan_num,2)

         done_file = mydir+"/D_"+scan
         bp_file   = mydir+"/BP_"+scan
         
         ;; Check if the file is new and needs to be processed
         ;; Add a condition on file_date for convenience if nk_rta
         ;; crashes and auto_nk_rta has to be relaunched without
         ;; reprocessing previous scans
         if keyword_set(catch_up) then begin
            file_date = start_time
         endif else begin
            nk_get_file_date, list[ifile], file_date
         endelse
         if file_test(done_file) eq 0 and file_test(bp_file) eq 0 and file_date ge start_time then begin
            delvarx, param
            
            print, "new scan found: ", scan
            print, "Launch nk_rta on it"
            spawn, "touch "+bp_file
            nk_rta, scan, param=param, iconic = iconic
            
            ;; Write a "done" file
            ;print, "Writing the 'done' file"
            spawn, "touch "+done_file
            spawn, "rm -f "+bp_file
            
            ;; rsync the logbook
            ;print, "rsync'ing logbook"
            spawn, "rsync -avuzq $NIKA_PLOT_DIR/Logbook t22@mrt-lx1.iram.es:./samuel/. 2> /dev/null"
         endif
      endfor
   endif

   ;; Update n_ref
   n_ref = n
   
   print, "waiting for a new file to appear..."
   wait, 1
endwhile


end
