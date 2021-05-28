;+
;
; SOFTWARE: NIKA simulation pipeline
;
; NAME: nk_map_angle_done2
;
; CATEGORY:
;
; CALLING SEQUENCE:
;         nk_map_angle_done2, map_list, map_w8_list, angles_list, map_out
; 
; PURPOSE: 
;        Produces combined map from the input map restored for fixed position of the HWP
; 
; INPUT: 
;        - map_list: list of maps for different angles
;        - map_w8_list: list of maps weight
;        - angles_list: list of angles fixed
; 
; OUTPUT:  
;        - map_out: maps in outputs for I,Q,U stokes parameters 
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

pro nk_map_angle_done2, map_list, map_w8_list, angles_list, map_xmap, map_out 
                       
if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_map_angle_done2, map_list, map_w8_list, angles_list, map_xmap, map_out "
   return
endif

ata    = dblarr(3,3)
atd    = dblarr(3)
npix   = n_elements(map_list[*,0,0])

map_out_i = dblarr(npix,3)
map_out_q = dblarr(npix,3)
map_out_u = dblarr(npix,3)

;; init map_out
map_out_i_1mm = map_xmap*0.d0
map_out_q_1mm = map_xmap*0.d0
map_out_u_1mm = map_xmap*0.d0

map_out_i_2mm = map_xmap*0.d0
map_out_q_2mm = map_xmap*0.d0
map_out_u_2mm = map_xmap*0.d0

cos4omega   = cos(4*angles_list)
sin4omega   = sin(4*angles_list)

nscans = n_elements(angles_list)
mask = map_out_i_1mm*0.d0
for lambda=1,2 do begin
   for ipix=0L, npix-1 do begin

      ;; Restrict to pixels covered with the four angles, otherwise the matrix
      ;; is not regular
      if total( map_w8_list[ipix,*,lambda-1] ne 0) eq nscans then begin
         ata[0,0] = total( map_w8_list[ipix, *, lambda-1])
         ata[0,1] = total( map_w8_list[ipix, *, lambda-1]*cos4omega) 
         ata[0,2] = total( map_w8_list[ipix, *, lambda-1]*sin4omega) 
         ata[1,1] = total( map_w8_list[ipix, *, lambda-1]*cos4omega^2)
         ata[1,2] = total( map_w8_list[ipix, *, lambda-1]*sin4omega*cos4omega)
         ata[2,2] = total( map_w8_list[ipix, *, lambda-1]*sin4omega^2)

         ata[1,0] = ata[0,1]
         ata[2,0] = ata[0,2]
         ata[2,1] = ata[1,2] 

         atd[0]   = total( map_list[ipix, *, lambda-1]*map_w8_list[ipix, *, lambda-1]) 
         atd[1]   = total( map_list[ipix, *, lambda-1]*map_w8_list[ipix, *, lambda-1]*cos4omega) 
         atd[2]   = total( map_list[ipix, *, lambda-1]*map_w8_list[ipix, *, lambda-1]*sin4omega)
         atam1    = invert(ata)
         signal   = atam1##atd  
         
         if lambda eq 1 then begin 
            map_out_i_1mm[ipix] = signal[0]
            map_out_q_1mm[ipix] = signal[1]
            map_out_u_1mm[ipix] = signal[2]
            if signal[1] ne 0 and signal[2] eq 0 then stop
         endif
         if lambda eq 2 then begin 
            map_out_i_2mm[ipix] = signal[0]
            map_out_q_2mm[ipix] = signal[1]
            map_out_u_2mm[ipix] = signal[2]
         endif
      endif
   endfor
endfor

wind, 1, 1, /free, xs=1200, ys=900
my_multiplot, 3, 2, pp, pp1, /rev
imview, map_out_i_1mm, imrange=[-1,1]*0.5, position=pp1[0,*]
imview, map_out_q_1mm, imrange=[-1,1]*0.1, position=pp1[1,*], /noerase
imview, map_out_u_1mm, imrange=[-1,1]*0.1, position=pp1[2,*], /noerase
imview, map_out_i_2mm, imrange=[-1,1]*0.3, position=pp1[3,*], /noerase
imview, map_out_q_2mm, imrange=[-1,1]*0.3*0.5, position=pp1[4,*], /noerase
imview, map_out_u_2mm, imrange=[-1,1]*0.3*0.5, position=pp1[5,*], /noerase

end
