;+
;
; SOFTWARE: 
;        NIKA pipeline
;
; NAME: 
;        nk_add_qu_to_grid
;
; CATEGORY: 
;        general, initialization
;
; CALLING SEQUENCE:
;         nk_add_qu_to_grid, param, info, grid
; 
; PURPOSE: 
;        Create the map related information structure.
;        Add polarization maps
; 
; INPUT: 
;        - param
; 
; OUTPUT: 
;        - grid
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - June 14th, 2014, N. Ponthieu, June 18th, 2014, A. Ritacco
;        - Oct. 2015: adpated to NIKA2, NP + AR
;-

pro nk_add_qu_to_grid, param, grid

if n_params() lt 1 then begin
   message, /info, "Calling sequence: "
   print, "nk_add_qu_to_grid, param, grid"
   return
endif

tags = tag_names(grid)
w = where( strupcase(tags) eq "MAP_Q_1MM", nw)
if nw eq 0 then begin
   grid_out = create_struct( grid, $
                             "map_q_1mm", grid.map_i_1mm*0.d0, $
                             "map_u_1mm", grid.map_i_1mm*0.d0, $
                             "map_q_2mm", grid.map_i_1mm*0.d0, $
                             "map_u_2mm", grid.map_i_1mm*0.d0, $
                             "map_w8_q_1mm", grid.map_i_1mm*0.d0, $
                             "map_w8_u_1mm", grid.map_i_1mm*0.d0, $
                             "map_w8_q_2mm", grid.map_i_1mm*0.d0, $
                             "map_w8_u_2mm", grid.map_i_1mm*0.d0, $
                             "map_var_q_1mm", grid.map_i_1mm*0.d0, $
                             "map_var_u_1mm", grid.map_i_1mm*0.d0, $
                             "map_var_q_2mm", grid.map_i_1mm*0.d0, $
                             "map_var_u_2mm", grid.map_i_1mm*0.d0, $
                             "map_q1", grid.map_i_1mm*0.d0, $
                             "map_u1", grid.map_i_1mm*0.d0, $
                             "map_q2", grid.map_i_1mm*0.d0, $
                             "map_u2", grid.map_i_1mm*0.d0, $
                             "map_q3", grid.map_i_1mm*0.d0, $
                             "map_u3", grid.map_i_1mm*0.d0, $
                             "map_w8_q1", grid.map_i_1mm*0.d0, $
                             "map_w8_u1", grid.map_i_1mm*0.d0, $
                             "map_w8_q2", grid.map_i_1mm*0.d0, $
                             "map_w8_u2", grid.map_i_1mm*0.d0, $
                             "map_w8_q3", grid.map_i_1mm*0.d0, $
                             "map_w8_u3", grid.map_i_1mm*0.d0, $
                             "map_var_q1", grid.map_i_1mm*0.d0, $
                             "map_var_u1", grid.map_i_1mm*0.d0, $
                             "map_var_q2", grid.map_i_1mm*0.d0, $
                             "map_var_u2", grid.map_i_1mm*0.d0, $
                             "map_var_q3", grid.map_i_1mm*0.d0, $
                             "map_var_u3", grid.map_i_1mm*0.d0, $
                             "iq_lkg_1", grid.map_i_1mm*0.d0, $
                             "iu_lkg_1", grid.map_i_1mm*0.d0, $
                             "iq_lkg_2", grid.map_i_1mm*0.d0, $
                             "iu_lkg_2", grid.map_i_1mm*0.d0,  $
                             "iq_lkg_3", grid.map_i_1mm*0.d0, $
                             "iu_lkg_3", grid.map_i_1mm*0.d0) ;, $
;;                              "nefd_q1", grid.map_i_1mm*0.d0, $
;;                              "nefd_q2", grid.map_i_1mm*0.d0, $
;;                              "nefd_q3", grid.map_i_1mm*0.d0, $
;;                              "nefd_q_1mm", grid.map_i_1mm*0.d0, $
;; ;                             "nefd_q_2mm", grid.map_i_1mm*0.d0, $
;;                              "nefd_u1", grid.map_i_1mm*0.d0, $
;;                              "nefd_u2", grid.map_i_1mm*0.d0, $
;;                              "nefd_u3", grid.map_i_1mm*0.d0, $
;;                              "nefd_u_1mm", grid.map_i_1mm*0.d0);, $
;; ;                             "nefd_u_2mm", grid.map_i_1mm*0.d0)

   grid = grid_out
endif

end
