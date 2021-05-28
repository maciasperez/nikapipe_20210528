;+
; AIM: output basic information on science pools (on all of them starting from N2R9
; by default)
;
; science_pool_info contains:
; -- the list of NIKA2 run ID
; -- the list of cryo run ID
; -- the list of reference kidpars
;
; DEPENDENCY: use get_nika2_run_info
;-

pro get_science_pool_info, science_pool_info, first_nika2_run=first_nika2_run, last_nika2_run=last_nika2_run, include_all = include_all

  get_nika2_run_info, nika2run_info

  deb = 0
  fin = n_elements(nika2run_info)-1
  if keyword_set(first_nika2_run) then begin
     test = where(nika2run_info.nika2run eq first_nika2_run, n)
     if n gt 0 then deb = test[0]
  endif
  if keyword_set(last_nika2_run) then begin
     test = where(nika2run_info.nika2run eq last_nika2_run, n)
     if n gt 0 then fin = test[0]
  endif
  nika2run_info = nika2run_info[deb:fin]

  ;; discard technical campaigns
  index_technical = where(strmatch(nika2run_info.comment, 'technical*') eq 1 and $
                          strmatch(nika2run_info.comment, '*reference*') eq 0 and $
                          strmatch(nika2run_info.comment, '*verification*', /fold_case) eq 0, compl=indok)
  nika2run_info = nika2run_info[indok]

  ;; discard runs with problems
  exclude = 1
  if keyword_set(include_all) then exclude = 0
  if exclude gt 0 then begin
     index_bad = where(strmatch(nika2run_info.comment, '*bad*') eq 1 or $
                       strmatch(nika2run_info.comment, '*problem*') eq 1, complement = indok)
     nika2run_info = nika2run_info[indok]
  endif

  nruns = n_elements(nika2run_info)
; The commented part is now done in get_nika2_run_info FXD
  science_pool_info = nika2run_info
;  science_pool_info = create_struct(nika2run_info[0], 'kidpar_ref', '')
;  science_pool_info = replicate(science_pool_info, nruns)
;
;  tags = TAG_NAMES(nika2run_info)
;  for i=0, n_elements(tags)-1 do science_pool_info.(i) =nika2run_info.(i)  
;  
;  for irun = 0, nruns-1 do begin
;     nk_get_kidpar_ref, '100',science_pool_info[irun].firstday, info, kidpar_file
;     science_pool_info[irun].kidpar_ref = kidpar_file
;  endfor

  
  return
end
