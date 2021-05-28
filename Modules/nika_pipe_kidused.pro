;+
;PURPOSE: Establish the list of KIDs used
;
;INPUT: The parameter, data and kidpar structures
;
;OUTPUT: The list of KIDs (also input if iscan ne 0).
;
;LAST EDITION: 
;   17/12/2013: creation (adam@lpsc.in2p3.fr)
;-

pro nika_pipe_kidused, param, data, kidpar, kid_used_1mm, kid_used_2mm
  
  ;;------- Define the array at the first scan
  if param.iscan eq 0 then begin
     kid_used_1mm = intarr(n_elements(param.scan_list), 400) -1 ;Up to 400 detectors
     kid_used_2mm = intarr(n_elements(param.scan_list), 400) -1 ;Up to 400 detectors
  endif
  
  ;;------- In case relaunched with new scans
  if n_elements(kid_used_1mm[*,0]) lt n_elements(param.scan_list) then $
     kid_used_1mm = [kid_used_1mm, intarr(n_elements(param.scan_list) - n_elements(kid_used_1mm[*,0]), 400) -1]
  if n_elements(kid_used_2mm[*,0]) lt n_elements(param.scan_list) then $
     kid_used_2mm = [kid_used_2mm, intarr(n_elements(param.scan_list) - n_elements(kid_used_2mm[*,0]), 400) -1]

  ;;------- Search for KIDs that are projected (contain at list one valid sample)
  flag = intarr(n_elements(kidpar)) + 1
  for ikid=0, n_elements(kidpar) -1 do begin
     loc_uf = where(data.flag[ikid] eq 0, nuf) ;Valid sample
     if nuf gt 0 then flag[ikid] = 0           ;if more than 0 valid sample, KID is used
  endfor
  
  ;;------- Fill the list
  list1mm = where(kidpar.array eq 1 and flag eq 0, nlist1mm)
  list2mm = where(kidpar.array eq 2 and flag eq 0, nlist2mm)
  
  if nlist1mm ne 0 then numdet1mm = kidpar[list1mm].numdet
  if nlist2mm ne 0 then numdet2mm = kidpar[list2mm].numdet
  
  if nlist1mm ne 0 then kid_used_1mm[param.iscan, 0:nlist1mm-1] = numdet1mm
  if nlist2mm ne 0 then kid_used_2mm[param.iscan, 0:nlist2mm-1] = numdet2mm
  
  return
end
