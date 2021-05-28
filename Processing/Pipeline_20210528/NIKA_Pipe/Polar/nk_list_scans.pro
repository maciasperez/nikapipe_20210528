;+
;
; SOFTWARE: NIKA simulation pipeline
;
; NAME: nk_list_scans
;
; CATEGORY:
;
; CALLING SEQUENCE:
;         nk_list_scans, scan_list, map_list, map_w8_list
; 
; PURPOSE: 
;        
;         restore list of scans done at fixed position of the HWP
; 
; INPUT: 
;        - scan_list   : list of scans 
;        
; OUTPUT:  
;        - map_list    : map structure restored for each scan
;        - map_w8_list : noise map of inverse of variance 
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Created Oct. 2014 Alessia Ritacco (ritacco@lpsc.in2p3.fr)
;-

pro nk_list_scans, scan_list, param, map_list, map_w8_list, map_xmap
                       
if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_list_scans, scan_list, path, map_list, map_w8_list"
   return
endif

nscans = n_elements(scan_list)

for i=0, nscans-1 do begin
   restore, param.project_dir+"/v_1/"+strtrim(scan_list[i],2)+'/results.save'
   if i eq 0 then begin
      npix        = n_elements(grid1.map_i_1mm)
      map_list    = dblarr(npix, nscans, 2)
      map_w8_list = dblarr(npix, nscans, 2)
   endif
   map_list[*,i,0]    = grid1.map_i_1mm
   map_list[*,i,1]    = grid1.map_i_2mm
   map_xmap = grid1.xmap
   map_w8_list[*,i,0] = grid1.map_w8_1mm
   map_w8_list[*,i,1] = grid1.map_w8_2mm
   
endfor


end
