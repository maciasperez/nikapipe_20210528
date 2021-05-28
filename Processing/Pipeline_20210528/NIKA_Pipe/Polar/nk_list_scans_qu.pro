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
;         restore list of scans
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

pro nk_list_scans_qu, scan_list, param, map_list_q, map_list_u,$
                      map_list_q_1, map_list_u_1, map_w8_list_q_1,$
                      map_w8_list_u_1, map_xmap, info
                       
if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_list_scans, scan_list, path, map_list, map_w8_list"
   return
endif

nscans = n_elements(scan_list)
for i=0, nscans-1 do begin
   restore, param.project_dir+"/v_1/"+strtrim(scan_list[i],2)+'/results.save'
   dist = sqrt(grid1.xmap^2 + grid1.ymap^2)
   w    = where(dist gt 30.0, comp=ok)
   grid1.map_q_1mm[w] = 0.
   grid1.map_q_2mm[w] = 0.
   grid1.map_u_1mm[w] = 0.
   grid1.map_u_2mm[w] = 0.
   if i eq 0 then begin
      info = info1
      info = replicate(info,nscans)
      info[i] = info1
      npix        = n_elements(grid1.map_q_1mm[ok])
      map_list_q    = dblarr(npix, nscans, 2)
      map_list_u    = dblarr(npix, nscans, 2)
      map_list_q_1  = dblarr(npix, nscans, 2)
      map_list_u_1  = dblarr(npix, nscans, 2)
      map_w8_list_q_1 = dblarr(npix, nscans, 2)
      map_w8_list_u_1 = dblarr(npix, nscans, 2)
     
      map_list_q[*,i,0]    = grid1.map_q_1mm[ok]
      map_list_q[*,i,1]    = grid1.map_q_2mm[ok]
      map_list_u[*,i,0]    = grid1.map_u_1mm[ok]
      map_list_u[*,i,1]    = grid1.map_u_2mm[ok]
      
   endif else begin
      info[i] = info1
  
      map_list_q_1[*,i,0]    = grid1.map_q_1mm[ok]
      map_list_q_1[*,i,1]    = grid1.map_q_2mm[ok]
      map_list_u_1[*,i,0]    = grid1.map_u_1mm[ok]
      map_list_u_1[*,i,1]    = grid1.map_u_2mm[ok]


      map_xmap = grid1.xmap
      map_w8_list_q_1[*,i,0] = grid1.map_w8_q_1mm[ok]
      map_w8_list_q_1[*,i,1] = grid1.map_w8_q_2mm[ok]
      map_w8_list_u_1[*,i,0] = grid1.map_w8_u_1mm[ok]
      map_w8_list_u_1[*,i,1] = grid1.map_w8_u_2mm[ok]


endelse
endfor


end
