function nk_get_all_scan, n2run, verbose = verbose
                                ; FXD April 2020
                                ; given a structure array of runs , produce the entire list of
                                ; scans

                                ; Input: n2run (use get_nika2_run_info
                                ; or get_science_pool_info to produce
                                ; it
                                ; n2run can be just a string array ,
                                ; in that case it is directly the run
                                ; name, 'N2Rall' represents all the runs
  ; FXD May2020
; Output: scan: structure array, one structure per scan, ordered in
; time
if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, 'nk_get_all_scan, n2run [, /verbose]   '
   print, '  (n2run array of structures obtained with get_nika2_run_info), or'
   print, '  an array of strings (e.g. ["N2R12","N2R13"]), or "N2Rall"'
   return, (-1)
endif

n2rtype = size(/type, n2run)
number_of_run = n_elements( n2run)

if n2rtype eq 7 then begin      ; strings
   if strupcase( n2run[0]) eq 'N2RALL'then begin
      get_nika2_run_info, n2runstr
      number_of_run = n_elements( n2runstr)
   endif else begin  ; In this case the polar info is not dealt with properly (to be fixed)
      n2runstr = replicate({ nika2run:'', polar:0},  number_of_run)
      n2runstr.nika2run = n2run
   endelse
endif else n2runstr = n2run
if size(/type, n2runstr) ne 8 then stop, 'Input is incorrect'

nmax = 500000L                  ; 10000 scans per run, 50 runs
ke = -1L
first_ok = 1  ; to init the final structure
for i = 0, number_of_run-1 do begin
   file = '$NIKA_SOFT_DIR/Pipeline/Datamanage/Logbook/' + $
          'Log_Iram_tel_'+n2runstr[i].nika2run+'_v0.save'
   if file_test( file) then begin
      restore, file
      if size( scan, /type) eq 8 then begin
         nsc = n_elements( scan)
         if first_ok eq 1 then begin
            sc = replicate( scan[0], nmax)
            first_ok = 0
         endif
         kb = ke+1
         ke = kb+nsc-1
         if keyword_set( verbose) then print, i, kb, ke, file
         sc[kb:ke] = scan
         sc[kb:ke].nika2run = n2runstr[i].nika2run
         sc[kb:ke].polar = n2runstr[i].polar
      endif else $
         if keyword_set( verbose) then $
            print, 'This file does not contain scans: '+ file
   endif else if keyword_set( verbose) then $
      print, 'This file does not exist: '+file
endfor

if ke ge 0 then begin
   sout = sc[0:ke]
                                ; check names that appear twice
   name = strtrim(sout.day, 2)+'s'+strtrim(sout.scannum, 2)
   final = uniq(name, multisort(sout.day, long(sout.scannum))) ; more accurate
;;;   final = uniq(name, sort(name))
   if n_elements( final) ne n_elements( name) then begin
      message, /info, 'Some confusion in runs, corrected'
   endif
   
   sout = sout[ final]
   
endif else sout = -1

return, sout

end
   
      
