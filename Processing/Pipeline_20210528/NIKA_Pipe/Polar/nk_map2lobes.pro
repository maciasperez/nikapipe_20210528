;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: nk_map2lobes
;
; CATEGORY:
;
; CALLING SEQUENCE:
;         nk_map2lobes, map_list, map_w8_list, angles_list, map_out
; 
; PURPOSE: 
;        Produces paralactic angle at sveral elevation to study
;        instrumental polarization and orientation of two lobes 
; 
; INPUT: 
;        - map_list: list of maps for different elevation
;        - map_w8_list: list of maps weight
;        - alpha : ref. angle of ref. map
; 
; OUTPUT:  
;        - paralactic angles in function of elevation
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Created Feb. 2014 Alessia Ritacco (ritacco@lpsc.in2p3.fr)
;-

pro nk_map2lobes, map_list_q, map_list_u, map_list_q_1, map_list_u_1,$
                  map_w8_list_q_1, map_w8_list_u_1,$
                  alpha, map_xmap
                       
if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_map2lobes, map_list, map_w8_list, angles_list, map_xmap, map_out "
   return
endif

ata       = dblarr(2,2)
atd       = dblarr(2)
npix      = n_elements(map_list_q_1[*,0,0])
alpha     = dblarr(n_elements(map_list_q_1[0,*,0]))
cos2alpha = dblarr(n_elements(map_list_q_1[0,*,0]))
sin2alpha = dblarr(n_elements(map_list_q_1[0,*,0]))
nscans    = n_elements(map_list_q_1[0,*,0])

for lambda=1,2 do begin
   for i=0, nscans-1 do begin
      ata[0,0] = total(map_w8_list_q_1[*, i, lambda-1]*map_list_q[*, 0, lambda-1]^2) + $
                 total(map_w8_list_u_1[*, i, lambda-1]*map_list_u[*, 0, lambda-1]^2)
      
      ata[1,0] = 0. ;; total(map_w8_list_q_1[*, *, lambda-1])*total(map_w8_list_u_1[*,*,lambda-1])*$
      ;; ((map_list_q[*,0,lambda-1])*(map_list_u[*,0,lambda-1])-$
      ;;  (map_list_q[*,0,lambda-1])*(map_list_q[*,0,lambda-1]))
      
      
      ata[0,1] = ata[1,0]
      ata[1,1] = ata[0,0]
      
      atd[0] = total(map_list_q_1[*,i,lambda-1]*map_list_q[*,0,lambda-1]*$
                     map_w8_list_q_1[*, i, lambda-1]) + $
               total(map_list_u_1[*,i,lambda-1]*map_list_u[*,0,lambda-1]*$
                     map_w8_list_u_1[*, i, lambda-1])
      
      atd[1] = total(map_list_q_1[*,i,lambda-1]*map_list_u[*,0,lambda-1]*$
                     map_w8_list_q_1[*, i, lambda-1])-$
               total(map_list_u_1[*,i,lambda-1]*map_list_q[*,0,lambda-1]*$
                     map_w8_list_u_1[*, i, lambda-1])
      
      atam1    = invert(ata)
      s        = atam1##atd  
      if lambda eq 1 then begin 
         cos2alpha[i] = s[0]
         sin2alpha[i] = s[1]
      endif
      if lambda eq 2 then begin 
         cos2alpha[i] = s[0]
         sin2alpha[i] = s[1]
      endif
      alpha[i] = 0.5*atan(sin2alpha[i],cos2alpha[i])*!radeg
      
      ;; if i eq nscans-1 then stop
      
   endfor
endfor

end
