pro convert_rawdata2imbfits,  dir_base = dir_base,  $
                              verb = verb,  imb_dir = imb_dir,  $
                              noimb = noimb,  zdir = zdir, a_only= a_only,$
                         force_files = force_files,  noexe = noexe,  ftp = ftp
;+
; NAME:
;
;  convert_rawdata2imbfits
;
; PURPOSE:
;
;  convert from raw Camadia data to different fits files automatically in a iterative loop
;
;
; CALLING SEQUENCE:
;
; 
;
; INPUTS:
;
;
;
; OPTIONAL INPUTS:
;
;
;
; KEYWORD PARAMETERS:
;
; noexe= don't do anything on files (except reading),
;   just write output log on screens
; ftp : do ftp transfers to Grenoble
;
; OUTPUTS:
;
;
;
; OPTIONAL OUTPUTS:
;
;
;
; COMMON BLOCKS:
;
;
;
; SIDE EFFECTS:
;
;
;
; RESTRICTIONS:
;
;
;
; PROCEDURE:
;
;
;
; EXAMPLE:
;   If one wants to redo the processing one needs to recreate the F_ files
;   Use generate_reproclist
;dir_file = '/home/archeops/NIKA/Data/raw_Y33/Y33_2013_06_13'
;ls_unix, '-1 '+dir_file, fonlist
;generate_reproclist, dir_file+ '/'+ fonlist[30:33]
; convert_rawdata2imbftis
;
;
; MODIFICATION HISTORY:
;   Created by FK, JFMP and FXD, IRAM, June 2012
;-
print, 'Type q in between two file processings to quit the program'
nonrecursive = 1
nostop = 1  ; do not interrupt the process unless something is typed
if not keyword_set( dir_base) then $
   dir_base = '/home/archeops/NIKA/Data/raw_Y33/' ; Run6 early value
if not keyword_set( imb_dir) then imb_dir ='/NikaData/'
if not keyword_set( zdir) then zdir = 'Y33*'  
; Y33 is the new 2013 sami computer (PC-linux)
dowork = 1

WHILE(dowork EQ 1) DO BEGIN

command = 'ls -d ' + dir_base + zdir
spawn, command, result  ;, /sh
result_base = file_basename( result)
if keyword_set( verb) then print, 'result_base is '+ result_base
result_length = long(size(result_base,/N_ELEMENTS))
if keyword_set( verb) then print, 'result_length is '+ strtrim(result_length,2)

i = 0
WHILE (i NE result_length) DO BEGIN
    command = 'ls ' + dir_base + result_base[i]
    spawn, command, result ;, /sh
    daily_length = long(size(result,/N_ELEMENTS))
    if keyword_set( verb) then $
       print, 'daily_length is '+ strtrim(daily_length,2)

    t=0
    if keyword_set( verb) then $
       print, result
    loriginal_files =  where(strmid(result, 0, 2) eq 'F_', norgfiles)
    if norgfiles gt 0 then begin 
      original_files =  result[loriginal_files]
     ;; lprocessed_files =   where(strmid(result, 0, 3) eq 'AB_', nprocfiles)
;;  DEBUGGING
;;      print,  "ALREADY PROCESSED FILES"
;;      print,   result[lprocessed_files]
      nprocfiles = 0
      if nprocfiles gt 0 then begin
       processed_files =  result[lprocessed_files] 
       tlist = [-1]
       for idx = 0, norgfiles -1 do begin 
          setfound =  0
          for idx1 = 0, nprocfiles-1 do begin
             if strmid(processed_files[idx1], 3, $
                       strpos(processed_files[idx1], ".txt")-3 ) eq $
                strmid(original_files[idx], 2, $
                       strlen(original_files[idx])-2 ) then begin
                setfound = 1
             endif
          endfor
          if setfound eq 0 then tlist = [tlist, idx] 
;; DEBUGGING
;;          if setfound eq 1 then print,  "I FOUND A FILE THAT WAS ALREADY DONE  ",  original_files[idx]
       endfor

       if n_elements(tlist) gt 1 then begin
          files_to_process =  dir_base + result_base[i] +  '/' + $
                              original_files[tlist[1: * ]]
         t =  n_elements(files_to_process)
       endif  
      endif else begin
        files_to_process =  dir_base + result_base[i] + '/' + original_files
        t =  n_elements(files_to_process)
      endelse
      

     if keyword_set(force_files)  then begin
       if (nonrecursive eq 1) then begin
         files_to_process = dir_base +force_files
         t = n_elements(files_to_process)
         nonrecursive = 0
       endif 
     endif

; Process data 
;    t = N_ELEMENTS(files_to_process)
    IF (t gt 0) THEN begin
;      files_to_process = files_to_process[1:*]
;      t = t-1
      if keyword_set( verb) then print, 'files_to_process ' + files_to_process

   
    FOR idx=0,t-1 DO BEGIN
       beingread = 1
       if keyword_set( verb) then print,  idx
       
       ;;check_file_fully_copied,  files_to_process[idx]
       
      ;;  while beingread eq 1 do begin
      ;;    spawn, "lsof | grep " + files_to_process[idx],  res
      ;;    if res[0] eq "" then begin
      ;;       beingread = 0
      ;;       endif else print, res
      ;; endwhile
        dirfile =  file_dirname(files_to_process[idx])+"/"
        truefile =  file_basename(files_to_process[idx])
        thefile =  dirfile+ "Y_"+strmid(truefile, 2,  strlen(truefile)-1)
        check_file_fully_copied,  thefile
        convert_raw2imbfits_sub,  thefile, noexe = noexe, $
              verb = verb, imb_dir = imb_dir,  ftp = ftp
        spawn,  "rm -f "+files_to_process[idx]
      ENDFOR
 endif
 endif   

    i = i+1
 ENDWHILE
if keyword_set( verb) then print, 'wait 5'
wait, 5
a = get_kbrd(0)
if strupcase(a) eq 'Q' then goto, STOPPGM
ENDWHILE

STOPPGM: print, 'program ends at user request : '+ a
return

end

