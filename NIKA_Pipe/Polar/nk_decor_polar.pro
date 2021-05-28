;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: nk_decor_polar
;
; CATEGORY: general
;
; CALLING SEQUENCE:
;       nk_decor_polar, param, info, data, kidpar, 
;                       data_q=data_q, data_u=data_u
;        
;        
; 
; PURPOSE: 
;        This is the main procedure of the NIKA offline analysis
;        software that reduces the timelines to maps. It works on a single scan.
;        info.map_1mm and info.map_2mm can be passed to nk_average_maps to
;        produce the combined map of several scans.
; 
; INPUT: 
;        - param: the reduction parameters array of structures (one per scan)
;        - info: the array of information structure to be filled (one
;          per scan)
; 
; OUTPUT: 
;        - Q,U data decorrelated
;       
; 
; KEYWORDS: plot
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - 11/07/2014: creation (Alessia Ritacco & Nicolas Ponthieu- ritacco@lpsc.in2p3.fr)
;-
;=========================================================================================================

pro nk_decor_polar, param, info, data, kidpar,$
                    data_q=data_q, data_u=data_u



cos4omega = cos(4.d0*data.c_position)
sin4omega = sin(4.d0*data.c_position)
;; Lockin and substract Q and U common modes

nsn       = n_elements(data)
nsmooth   = 5
index     = lindgen(nsn)
w2        = where((index mod nsmooth) eq 0)
data_copy = data
data      = data[w2]
data_q    = data[w2]
data_u    = data[w2]
;; Deal with bands separately
for lambda=1, 2 do begin
   nk_list_kids, kidpar, lambda=lambda, valid=w1, nvalid=nw1
   ;; wkids = where( kidpar.type eq 1 and kidpar.array eq lambda, nwkids)
   if nw1 ne 0 then begin
      ;;map_w8 = dblarr(nx,info.ny)
      
      message, /info, "Lock-in, lambda = "+Strtrim(lambda,2)+"/ Loop on kids..."
      for i=0, nw1-1 do begin
         percent_status, i, nw1, 10
         ikid  = w1[i] 
         
         toi_t = smooth(data_copy.toi[ikid], nsmooth)
         flag  = smooth(data_copy.flag[ikid], nsmooth)
         toi_q = smooth(cos4omega * data_copy.toi[ikid], nsmooth)
         toi_u = smooth(sin4omega * data_copy.toi[ikid], nsmooth)
         
         data.flag[ikid]   = long(flag[w2] ne 0)                
         data_q.flag[ikid] = data.flag[ikid]
         data_u.flag[ikid] = data.flag[ikid]
                  
         data.toi[ikid]    = toi_t[w2]
         data_q.toi[ikid]  = toi_q[w2]
         data_u.toi[ikid]  = toi_u[w2]                
      endfor
   endif
endfor
;; ***********************************************************

nk_decor, param, info, data, kidpar
param1 = param
param1.decor_method = 'COMMON_MODE_KIDS_OUT'
nk_decor, param, info, data_q, kidpar
nk_decor, param, info, data_u, kidpar

end
