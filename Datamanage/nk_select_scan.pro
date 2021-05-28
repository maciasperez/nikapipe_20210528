function nk_select_scan, scan, source, obstype, nscans, $
                         avoid_scan = list_avoid_scan, $
                         polar = polar,  nopolar = nopolar, $
                         all_sources = all_sources, $
                         n2run = n2run

;FXD nov 2014
; for an array of structures giving scan info select the relevant scans for
; a given source and obstype and avoiding specific scans
                                ; /all_sources, take all the scans of a given type (Jan-2018, FXD)
; Apr 2020 FXD can be now applied across runs
; Example: get_nika2_run_info, n2r
; scan = nk_get_all_scan( n2r)
; then
; index = nk_select_scan(scan,'Uranus','onTheFlyMap')  with
; n2run = 'N2R23' keyword if needed
  

if keyword_set( n2run) then marun = strupcase( strtrim( n2run, 2)) $
  else marun = '*'

if keyword_set( polar) then $
   ind = where( strcompress(strupcase( scan.object), /remove) eq $
                strcompress(strupcase( source), /remove) and $
                strtrim( strupcase(scan.obstype), 2) eq $
                strupcase( obstype) and scan.polar eq 1 and $
                strmatch(scan.nika2run, marun, /fold_case), nind)
if keyword_set(nopolar) then $
   ind = where(  strcompress(strupcase( scan.object), /remove) eq $
                 strcompress(strupcase( source), /remove) and $
                 strtrim( strupcase(scan.obstype), 2) eq $
                 strupcase( obstype) and scan.polar eq 0 and $
                 strmatch(scan.nika2run, marun, /fold_case), nind)
if ((1-keyword_set( polar)) and (1- keyword_set( nopolar))) or $
   ((  keyword_set( polar)) and (   keyword_set( nopolar))) then $
      ind = where(  strcompress(strupcase( scan.object), /remove) eq $
                    strcompress(strupcase( source), /remove) and $
                strtrim( strupcase(scan.obstype), 2) eq $
                strupcase( obstype) and $
                 strmatch(scan.nika2run, marun, /fold_case), nind)

if keyword_set( all_sources) then begin
   if keyword_set( polar) then $
   ind = where( strtrim( strupcase(scan.obstype), 2) eq $
                strupcase( obstype) and scan.polar eq 1 and $
                 strmatch(scan.nika2run, marun, /fold_case), nind)
if keyword_set(nopolar) then $
   ind = where(  strtrim( strupcase(scan.obstype), 2) eq $
                strupcase( obstype) and scan.polar eq 0 and $
                 strmatch(scan.nika2run, marun, /fold_case), nind)
if ((1-keyword_set( polar)) and (1- keyword_set( nopolar))) or $
   ((  keyword_set( polar)) and (   keyword_set( nopolar))) then $
      ind = where(  strtrim( strupcase(scan.obstype), 2) eq $
                strupcase( obstype) and $
                 strmatch(scan.nika2run, marun, /fold_case), nind)
endif

 
indscan = -1
nscans = 0
if nind ne 0 then begin
   scan_list = scan[ind].day+'s'+strtrim( scan[ind].scannum, 2)
   
   bytescan = replicate( 1B, nind)
   
   for i = 0, n_elements( list_avoid_scan)-1 do $
      bytescan = bytescan-[ strmatch(scan_list, list_avoid_scan[i])] 
   indscan = where( bytescan, nscans)
   if nscans ne 0 then indscan = ind[indscan]
endif 

return, indscan
end
