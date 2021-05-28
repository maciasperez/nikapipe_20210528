
;+
;
; SOFTWARE: NIKA pipeline
;
; NAME:
; nk_coadd_array2lambda.pro
;
; CATEGORY:
;
; CALLING SEQUENCE:
;         nk_coadd_arrays2lambda, grid, grid_out
; 
; PURPOSE: 
;        Combine maps of array 1 and 3 into '1mm' maps, copies
;        maps of array 2 into fields '2mm'
; 
; INPUT: 
; 
; OUTPUT: 
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Dec. 28th, 2015, NP
;-

pro nk_coadd_arrays2lambda, grid, grid_out

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, 'nk_coadd_array2lambda.pro, grid, grid_out'
   return
endif


;; init (default, do nothing for NIKA1)
grid_out = grid
grid_tags = tag_names(grid)
nika2 = 0
polar = 0

w = where( strupcase( grid_tags) eq "MAP_Q_1MM", nw)
if nw ne 0 then polar = 1

w8_i1 = dblarr( grid.nx, grid.ny)
w8_q1 = dblarr( grid.nx, grid.ny)
w8_u1 = dblarr( grid.nx, grid.ny)
w = where( strupcase( grid_tags) eq "NHITS_1", nw)
if nw ne 0 then begin
   nika2 = 1
   grid_out.nhits_1mm  = grid.nhits_1

   w = where( grid.map_var_i1 ne 0, nw)
   if nw ne 0 then w8_i1[w] = 1.d0/(grid.map_var_i1)[w]
   grid_out.map_i_1mm  = grid.map_i1*w8_i1
   
   if polar eq 1 then begin
      w = where( grid.map_var_q1 ne 0, nw)
      if nw ne 0 then w8_q1[w] = 1.d0/(grid.map_var_q1)[w]
      grid_out.map_q_1mm  = grid.map_q1*w8_q1

      w = where( grid.map_var_u1 ne 0, nw)
      if nw ne 0 then w8_u1[w] = 1.d0/(grid.map_var_u1)[w]
      grid_out.map_u_1mm  = grid.map_u1*w8_u1
   endif
endif
   
w = where( strupcase( grid_tags) eq "NHITS_3", nw)
w8_i3 = dblarr( grid.nx, grid.ny)
w8_q3 = dblarr( grid.nx, grid.ny)
w8_u3 = dblarr( grid.nx, grid.ny)
if nw ne 0 then begin
   grid_out.nhits_1mm  += grid.nhits_3

   w = where( grid.map_var_i3 ne 0, nw)
   if nw ne 0 then w8_i3[w] = 1.d0/(grid.map_var_i3)[w]
   grid_out.map_i_1mm += grid.map_i3*w8_i3

   ;; The relative sign of Array 3 compared to Array 1 is now accounted for in
   ;; nk_lockin.pro (NP, Feb. 10th, 2016)
   if polar eq 1 then begin
      w = where( grid.map_var_q3 ne 0, nw)
      if nw ne 0 then w8_q3[w] = 1.d0/(grid.map_var_q3)[w]
      grid_out.map_q_1mm += grid.map_q3*w8_q3
      
      w = where( grid.map_var_u3 ne 0, nw)
      if nw ne 0 then w8_u3[w] = 1.d0/(grid.map_var_u3)[w]
      grid_out.map_u_1mm += grid.map_u3*w8_u3
   endif
endif

;; average
w8 = w8_i1 + w8_i3
w = where( w8 ne 0, nw)
if nw ne 0 then begin
   map = grid_out.map_i_1mm
   map[w] /= w8[w]
   grid_out.map_i_1mm = map
   map_var=map*0.
   map_var[w] = 1.d0/w8[w]
   grid_out.map_var_i_1mm = map_var
endif

w8 = w8_q1 + w8_q3
w = where( w8 ne 0, nw)
if nw ne 0 then begin
   map = grid_out.map_q_1mm
   map[w] /= w8[w]
   grid_out.map_q_1mm = map
   map_var=map*0.
   map_var[w] = 1.d0/w8[w]
   grid_out.map_var_q_1mm = map_var
endif

w8 = w8_u1 + w8_u3
w = where( w8 ne 0, nw)
if nw ne 0 then begin
   map = grid_out.map_u_1mm
   map[w] /= w8[w]
   grid_out.map_u_1mm = map
   map_var=map*0.
   map_var[w] = 1.d0/w8[w]
   grid_out.map_var_u_1mm = map_var
endif

;; 2mm
if nika2 eq 1 then begin
   w = where( strupcase( grid_tags) eq "NHITS_2", nw)
   if nw ne 0 then begin
      grid_out.nhits_2mm     = grid.nhits_2
      grid_out.map_i_2mm     = grid.map_i2
      grid_out.map_var_i_2mm = grid.map_var_i2
      grid_out.map_w8_2mm    = grid.map_w8_i2
      if polar eq 1 then begin
         grid_out.map_q_2mm     = grid.map_q2
         grid_out.map_var_q_2mm = grid.map_var_q2
         grid_out.map_w8_q_2mm  = grid.map_w8_q2
         grid_out.map_u_2mm     = grid.map_u2
         grid_out.map_var_u_2mm = grid.map_var_u2
         grid_out.map_w8_u_2mm  = grid.map_w8_u2
      endif
   endif
endif

end
