;+
;
; SOFTWARE: management tool
;
; NAME:
;   get_scan_list
;
; CATEGORY: general
;
; CALLING SEQUENCE:
;   scan= nk_get_source_scanlist(source, nscan, obstype = k_obstype, n2run = k_n2run, polar = k_polar)
; PURPOSE: 
;   Produces a complete list of scans related to a given source (and
; possibly a given run)     
; 
; INPUT: 
;       - source  ; String Name of the source
;       
; 
; OUTPUT: 
;       - scan  ; structure array of scans related to the
;         source: scan.scanname gives the list of scan names.
;       - nscan ; number of scans that were found
; 
; KEYWORDS:
;       - obstype  ; default is 'onTheFlyMap'
;         - n2run  ; run name e.g. 'N2R12', default is 'N2Rall' i.e. all runs
;         - polar  ; if set finds polarisation-using scans
; SIDE EFFECT:
;       
; EXAMPLE: 
;   scan= nk_get_source_scanlist('GJ526', nscan)
;   print, nscan, ' scans were found'
;   scan_list = scan.day + 's' + strtrim(scan.scannum,2)
; MODIFICATION HISTORY: 
;        - ; FXD Nov 2020 : introduced to help imcmcall preparation
;================================================================================================
function nk_get_source_scanlist, source, nscan, obstype = k_obstype, n2run = k_n2run, polar = k_polar

  
if not keyword_set( k_obstype) then begin
   obstype = 'onTheFlyMap'
   message, /info,  'Obs type assumed is '+ obstype
endif else obstype = k_obstype  ; default is OTF
if keyword_set( k_n2run) then n2r = k_n2run else n2r = 'N2Rall'                      ; default
if keyword_set( k_polar) then nopolar = 0 else nopolar = 1 ; default

; Get all the runs
get_nika2_run_info, n2r_struct
u = where( n2r_struct.nika2run eq n2r, nu)
IF nu ne 1 then begin ; all runs case
   if n2r ne 'N2Rall' then stop, 'Could not find run '+ n2r
   get_nika2_run_info, n2rstruct
   scanall = nk_get_all_scan( n2rstruct)
endif else begin  ; one run case
   print, 'For this run ', n2r_struct[u[0]].nika2run
   scanall=nk_get_all_scan( n2r_struct[u[0]])
endelse

indscan = nk_select_scan( scanall, source, obstype, nscan, nopolar = nopolar)
if nscan ne 0 then begin
   scan = scanall[indscan]
endif else begin
   scan = ''
   nscan = 0
   if nopolar eq 1 then message, /info, 'No scan found, without option /polar'
endelse

  
  
return, scan
end
