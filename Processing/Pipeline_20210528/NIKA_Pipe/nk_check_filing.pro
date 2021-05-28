;+
;
; SOFTWARE:
;
; NAME:
; nk_check_filing
;
; CATEGORY: general
;
; CALLING SEQUENCE:
;        nk_check_filing, scan, process_file
; 
; PURPOSE: 
;        Checks if the UP_ file of a raw data file exists and that no
;        other process is currently operating on this file and returns
;        process_file=1 if yes.
; 
; INPUT: 
;      - scan
; 
; OUTPUT: 
;     - process_file
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - June 14th, 2014: Nicolas Ponthieu
;-
;================================================================================================

pro nk_check_filing, param, scan, process_file, dry=dry

bp_file = param.project_dir+"/UP_files/BP_"+scan+".dat"
ok_file = param.project_dir+"/UP_files/OK_"+scan+".dat"
param.bp_file    = bp_file
param.ok_file    = ok_file

if (file_test(ok_file) eq 0) and (file_test(bp_file) eq 0) then process_file=1 else process_file=0

;; Create the BeingProcessed file to prevent anyother process to
;; reduce this scan at the same time
if process_file eq 1 and (not keyword_set(dry)) then spawn, "touch "+bp_file

end
