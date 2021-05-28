;+
;
; SOFTWARE: 
;        NIKA pipeline
;
; NAME: 
;        nk_get_svn_rev
;
; CATEGORY: 
;
; CALLING SEQUENCE:
;         nk_get_svn_rev, rev
; 
; PURPOSE: 
;        Find the current svn revision
; 
; INPUT: 
;        None     
;  
; OUTPUT: 
;        - rev: The current SVN revision number
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - April 10th, 2015: NP
;        - July 8th, 2015: search the revision from !nika.soft_dir
;-

pro nk_get_svn_rev, rev
  spawn, "svn info "+!nika.soft_dir+" > bidon.dat"
  spawn, "grep -i revision bidon.dat", rev
  spawn, "rm -f bidon.dat"
  a = strsplit( rev, ":", /extract)
  rev = long( strtrim( a[1],2))
end
