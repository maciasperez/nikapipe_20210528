;+
;
; SOFTWARE: 
;        NIKA pipeline
;
; NAME: 
;        nk_get_scan_from_imbfits
;
; CATEGORY: 
;        reading, initialization
;
; CALLING SEQUENCE:
;         nk_get_scan_from_imbfits, antenna_file, deltax, deltay, subscan
; 
; PURPOSE: 
;        Extract the scan strategy from the antenna IMBFITS
; 
; INPUT: 
;        - antenna_file: the name of the antenna IMBFITS to be used (string)
; 
; OUTPUT: 
;        - deltax: the scan along x
;        - deltay: the scan along y
;        - subscan: the subscan
; 
; KEYWORDS:
;        - FORCE: Use this keyword to force the list of scans used
;          instead of checking if they are valid
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - 30/03/2014: creation
;-

pro nk_get_scan_from_imbfits, antenna_file, deltax, deltay, subscan

  iext = 0

  deltax = 0d0
  deltay = 0d0
  subscan = 0

  ndeb = 0
  nend = 0
  ss_val = 1

  repeat begin
     readin = mrdfits(antenna_file, iext, hdr, status=status, /silent)
     extna = sxpar(hdr, 'EXTNAME')
     if strtrim(strupcase(extna), 2) eq strupcase('IMBF-ANTENNA') then begin
        nread = n_elements(readin)
        nend = ndeb + nread - 1
        deltax = [deltax, readin.longoff*!radeg*3600]
        deltay = [deltay, readin.latoff*!radeg*3600]
        subscan = [subscan, ss_val+intarr(nread)]
        
        ndeb = nend + 1
        ss_val += 1
     endif
     iext = iext + 1
  endrep until status lt 0
  
  deltax = deltax[1:nend]
  deltay = deltay[1:nend]
  subscan = subscan[1:nend]

end
