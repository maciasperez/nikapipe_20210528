pro nika_find_raw_data_file, scan_num, day, file, imb_fits_file, xml_file, $
                             silent=silent, xml=xml, noerror=noerror, $
                             status = status

on_error, 2
status = 0
if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nika_find_raw_data_file, scan_num, day, file, imb_fits_file, xml_file, $"
   print, "                     noerror=noerror, silent=silent"
   return
endif

;; Ensure correct format for "day"
t = size( day, /type)
if t eq 7 then day = strtrim(day,2) else day = string( day, format="(I8.8)")

ok = 1 ; default

date = strmid(day,0,4)+"_"+strmid(day,4,2)+"_"+strmid(day,6,2)

; FXD, May 2013, add the Z constraint (because in 2012 A and B fits files
; exist also)
cmd = "find "+!nika.raw_acq_dir+" -name '*"+date+"*' | grep _"+string( scan_num, format='(I4.4)')

;;Correction pour que le run5 marche toujours (Remi Adam)
if strmid(date,0,7) eq '2012_11' then cmd = "find "+!nika.raw_acq_dir+" -name '*"+date+"*' | grep _"+string( scan_num, format='(I4.4)')+' | grep Z_'

; Correction for run7 and beyond: X files (Needed because other files F_... may
;still be present in realtime)

if long(strmid(date,0,4)) ge 2014 then begin
   if !nika.run eq 11 or !nika.run eq 10 or !nika.run eq 8 then cmd = "find "+!nika.raw_acq_dir+" -name '*"+date+"*' | grep _"+string( scan_num, format='(I4.4)')+' | grep /X_' else cmd = "find "+!nika.raw_acq_dir+" -name '*"+date+"*' | grep _"+string( scan_num, format='(I4.4)')+' | grep /Y_'
   if !nika.run eq '10' and !nika.new_find_data_method eq 1 then begin
      mydate = str_replace(date,'_','')
      mydate = str_replace(mydate,'_','')
      if mydate lt 20141115 then acqmac ='35' else acqmac = '9'
      
      raw_dir = !nika.raw_acq_dir+'/raw_X'+acqmac+'/X'+acqmac+'_'+date+'/'
      ;; cmd = "find "+raw_dir+ " -name '*"+date+"*' | grep _"+ $
      ;;       string( scan_num, format='(I4.4)')+' | grep /X_'
      cmd = "ls -1 "+raw_dir+"X_"+date+"*_"+zeropadd(scan_num,4)+"*"
      
   endif 
endif

spawn, cmd, file

n = where(file_basename(file_dirname(file)) ne '.AppleDouble' and $
          strmatch(file,'*/._*') ne 1 and $
          strmatch(file, '*~') ne 1,  nok)
if nok eq 0 then message, 'Only temporary file found' else file = file[n]

if n_elements(file) gt 1 then begin
   fn = file_basename(file)
   lrf = where(strmatch(strmid(fn,22,4),zeropadd(scan_num,4)) and $
               strmid( fn, 0, 1, /reverse_offset) ne '~',nlrf)
   if nlrf ne 1 then stop else file = file[lrf] 
endif
if n_elements(file) eq 0 then stop

file = file[0]
maindir = strmid(file_basename(file_dirname(file)),0,2)
okdir = where(maindir eq 'L_',nokdir)
if nokdir gt 0 then file = file[okdir]

if file[0] eq "" then begin
   if not keyword_set(noerror) then begin 
      message, /info, ""
      message, /info, cmd+" FAILED"
      message, /info, "No data file found for scan_num="+strtrim(scan_num,2)+", day="+day
   endif 
   status = -1
   return
endif

n = where(file_basename(file_dirname(file)) ne '.AppleDouble' and strmatch(file,'*/._*') ne 1, nw)
if nw eq 0 then begin
   if not keyword_set(noerror) then begin 
      message, /info, ""
      message, /info, cmd+" FAILED"
      message, "No data file without .AppleDouble found for scan_num="+strtrim(scan_num,2)+", day="+day
   endif
endif else begin
      file = file[n]
      ;; in Run5, there are observations of a source whose name contains 221, which                                              
      ;; is also a scan number...                                                                                                
      ;; => Need to check here                                                                                                   
      i     = 0
      found = 0
      while (found eq 0) and (i lt nw) do begin
         dir = file_dirname( file[i])
         l   = strlen( dir+"/Z_2012_11_23_19h19m37_")
         num = strmid( file[i], l, 4)
         if num eq string( scan_num, format="(I4.4)") then begin
            file  = file[i]
            found = 1
         endif
         i++
      endwhile
endelse

;; IMBfits file
cmd = "find "+!nika.imb_fits_dir+" -name '*"+day+"s"+strtrim(scan_num,2)+"-*' -print"
spawn, cmd, imb_fits_file
;; Deal with .Appledouble issue
n = where(file_basename(file_dirname(imb_fits_file)) ne '.AppleDouble' and $
          strmatch(imb_fits_file,'*/._*') ne 1 and $
          strmatch(imb_fits_file, '*~') ne 1)
imb_fits_file = imb_fits_file[n]

;; to make sure
imb_fits_file = imb_fits_file[0]

;; XML file (from Run7 on)
if keyword_set(xml) then begin
   nika_find_xml_file, scan_num, day, xml_file, /silent
endif else begin
   xml_file = ""
endelse

if not keyword_set(silent) then begin
   message, /info, "Data file found   : "+file
   message, /info, "IMBfits file found: "+imb_fits_file
   if keyword_set(xml) then message, /info, "PaKO XML file found: "+xml_file
endif

return
end
