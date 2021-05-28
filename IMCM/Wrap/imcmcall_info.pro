pro imcmcall_info, project_dir, source, method_num, ext, version, info_all, in_scan_list, $
                   chrono = chrono, all = all, $
                   where_scan_not_reduced = where_scan_not_reduced, $
                   param = param

; Program  FXD, from source_ql2,
                                ; Get info structure array out independently of plots
  ; get the used param as well
delvarx, info_all
if not defined(version) then version = 'A'
;; Check which scans were actually processed
dirin = project_dir+'/v_'+ strtrim(version, 2)+'/'
if not defined( in_scan_list) then ls_unix, dirin, in_scan_list, /silent
nscans = n_elements(in_scan_list)
keep = intarr(nscans)
keep2 = intarr(nscans)
keep3 = intarr(nscans)
for iscan=0, nscans-1 do begin
   info_csv_file = dirin + $
                   in_scan_list[iscan]+'/info.csv'
   if file_test(info_csv_file) then keep[iscan] = 1
endfor

w = where( keep eq 1, nw)
print, nw, ' scans could be retrieved out of ', nscans
if nw eq 0 then begin
   message, /info, "No scan was reduced in "+ dirin
   if defined(in_scan_list) then message, /info, 'Maybe ? Do delvarx, in_scan_list'
   return
endif

;; Restrict to reduced files
scan_list = in_scan_list[w]
nscans    = nw
ind_scan = indgen( nscans)      ; make it easier when there is only one scan
if nscans eq 1 then ind_scan = [ind_scan, ind_scan]
for iscan=0, nscans-1 do begin
   info_csv_file = dirin+ $
                   scan_list[iscan]+'/info.csv'
   nk_read_csv_2, info_csv_file, info
   if defined(info_all) eq 0 and size(/type, info) eq 8 then begin
      info0 = info
      info0.result_tau_1mm = -1.
      info_all = replicate(info0, nscans)
   endif
   if size(/type, info) eq 8 then begin
      keep2[w[iscan]] = 1
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
keep3[w[good]] = 1
where_scan_not_reduced = where(keep eq 0 or keep2 eq 0 or keep3 eq 0.)

nscans = ngood
info_all = info_all[ good]
print, ngood, ' scans could be read out of ', ninfo
if keyword_set( chrono) then begin
   info_all = info_all[ multisort( strmid( info_all.scan, 0, 8), $
                                   long( strmid( info_all.scan, 9)))]
   print, 'Chrono: reorder scans according to time'
endif

source_dir = project_dir+'/../../'
imcmin_dir = source_dir+'/imcmin'  ; input files
filpa = imcmin_dir+ '/imcm_input_'+source+'_'+strtrim(method_num, 2)+version+'.txt'
input_txt_file = filpa
@read_imcm_input_txt_file
param.version = version


return
end
