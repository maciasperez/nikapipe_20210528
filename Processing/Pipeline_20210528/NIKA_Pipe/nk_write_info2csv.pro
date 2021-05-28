; Procedure to make info_all and save it in a csv file

pro nk_write_info2csv, project_dir, version, in_scan_list, info_all, source
; Procedure taken from source_ql2

delvarx, info_all
;; Check which scans were actually processed
nscans = n_elements(in_scan_list)
keep = intarr(nscans)
for iscan=0, nscans-1 do begin
   info_csv_file = project_dir+'/v_'+ strtrim(version, 2)+'/' + $
                   in_scan_list[iscan]+'/info.csv'
   if file_test(info_csv_file) then keep[iscan] = 1
endfor

w = where( keep eq 1, nw)
message, /info, strtrim(nw, 2)+ $
         ' scans could be retrieved out of '+ strtrim( nscans, 2)
if nw eq 0 then begin
   message, /info, 'No scan was reduced'
   return
endif

;; Restrict to reduced files
scan_list = in_scan_list[w]
nscans    = nw
ind_scan = indgen( nscans)      ; make it easier when there is only one scan
if nscans eq 1 then ind_scan = [ind_scan, ind_scan]
for iscan=0, nscans-1 do begin
   info_csv_file = project_dir+'/v_'+ strtrim(version, 2)+'/' + $
                   scan_list[iscan]+'/info.csv'
   nk_read_csv_2, info_csv_file, info
   if defined(info_all) eq 0 and size(/type, info) eq 8 then begin
      info0 = info
      info0.result_tau_1mm = -1.
      info_all = replicate(info0, nscans)
   endif
   if size(/type, info) eq 8 then begin
      tagn = tag_names( info_all)
      tagn2 = tag_names( info)
      for i = 0, n_tags( info_all[0])-1 do begin
         u = where( strmatch( tagn2, tagn[i]), nu)
         if nu eq 1 then info_all[iscan].(i) = info.(u[0])
      endfor
   endif
   
endfor
ninfo = n_elements( info_all)
good = where( info_all.result_tau_1mm gt 0., ngood)
if ngood eq 0 then begin
   message, /info, 'No valid scan with correct opacity, use 225GHz instead !'
   info_all.result_tau_1mm = info_all.tau225
   info_all.result_tau_1 = info_all.tau225
   info_all.result_tau_3 = info_all.tau225
   info_all.result_tau_2mm = info_all.tau225*0.6 ; approx.
   info_all.result_tau_2 = info_all.tau225*0.6
endif
good = where( info_all.result_tau_1mm gt 0., ngood)
if ngood eq 0 then stop, 'Not enough info_all data'
nscans = ngood
info_all = info_all[ good]
print, ngood, ' scans could be read out of ', ninfo
if keyword_set( chrono) then begin
   info_all = info_all[ multisort( strmid( info_all.scan, 0, 8), $
                                   long( strmid( info_all.scan, 9)))]
   print, 'Chrono: reorder scans according to time'
endif

; Save as a csv file
filecsv_out = project_dir+'/info_all_'+source+'_v'+version+'.csv'
; does not work  if object is different from source:
; filecsv_out = project_dir+'/info_all_'+info_all[0].object+'_v'+version+'.csv'
; TESTING
;filecsv_out = project_dir+'/info_TEST_all_'+info_all[0].object+'_v'+version+'.csv'
list = strarr( nscans)
tagn = tag_names( info_all[0])
ntag = n_tags( info_all[0])

FOR ifl = 0, nscans-1 DO BEGIN
   bigstr = string( info_all[ ifl].(0))
   FOR itag = 1, ntag-1 DO bigstr = bigstr + ' , ' + string( info_all[ ifl].(itag))
   list[ ifl] = bigstr
ENDFOR
bigstr = tagn[ 0]
FOR itag = 1, ntag-1 DO bigstr = bigstr + ' , ' + string( tagn[itag])

list = [ bigstr, list]
write_file, filecsv_out, list, /delete
message, /info, 'Written file: '+ filecsv_out
return
end
