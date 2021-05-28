;+
;
; NAME: 
; nk_reset_filing
;
; CATEGORY: general, RTA
;
; CALLING SEQUENCE:
;       nk_reset_filing, scan_list
; 
; PURPOSE: 
;        Erases all the Being Processed or "OK" files to restart all over.
; 
; INPUT: 
;       - param: the pipeline parameter structure
;       - scan_list: list of scans to reprocess
;
; OUTPUT: 
;       - None
;
; KEYWORDS:
;
; SIDE EFFECT:
;       files are created and written on disk
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - June 14th, 2014: Nicolas Ponthieu
;        - Nov. 14th, 2014: NP: reverse the way "filing" works:
;          process by default unless already processed and marked
;"ok". This way, we can update the scan list a posteriori, without
;needing to reset the entire scan_list.
;-
;================================================================================================

pro nk_reset_filing, param, scan_list

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_reset_filing, param, scan_list"
   return
endif

;; (re-)init the error report file
error_report_file = param.project_dir+"/error_report.dat"
spawn, "rm -f "+error_report_file

;; rm scan by scan to restrict to the requested scan list and not to
;; erase preprocessed files from another source in the same project dir...
nscans = n_elements( scan_list)
for iscan=0, nscans-1 do begin
   scan = strtrim(scan_list[iscan],2)
   spawn, "rm -f "+param.project_dir+"/UP_files/OK_"+strtrim(scan,2)+".dat"
   spawn, "rm -f "+param.project_dir+"/UP_files/BP_"+strtrim(scan,2)+".dat"
endfor



end
