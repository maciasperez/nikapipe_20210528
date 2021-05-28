;+
;
; SOFTWARE: 
;        NIKA pipeline
;
; NAME: 
;        nk_upgrade_map_struct
;
; CATEGORY: 
;        general, initialization
;
; CALLING SEQUENCE:
;         nk_upgrade_map_struct, param, info, map_struct
; 
; PURPOSE: 
;        Create the map related information structure.
;        Add polarization maps
; 
; INPUT: 
;        - param
; 
; OUTPUT: 
;        - map_struct
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - June 14th, 2014, N. Ponthieu, June 18th, 2014, A. Ritacco
;-

pro nk_upgrade_map_struct, param, map_struct

if n_params() lt 1 then begin
   message, /info, "Calling sequence: "
   print, "nk_upgrade_map_struct, param, info, map_struct"
   return
endif

;; Check if map_struct has already been upgraded
tags = tag_names(map_struct)
w = where( strupcase(tags) eq "MAP_Q_1MM", nw)
if nw eq 0 then begin
   map_struct_out = create_struct( map_struct, $
                                   "map_q_1mm", map_struct.map_i_1mm*0.d0, $
                                   "map_u_1mm", map_struct.map_i_1mm*0.d0, $
                                   "map_q_2mm", map_struct.map_i_1mm*0.d0, $
                                   "map_u_2mm", map_struct.map_i_1mm*0.d0, $
                                   "map_w8_q_1mm", map_struct.map_i_1mm*0.d0, $
                                   "map_w8_u_1mm", map_struct.map_i_1mm*0.d0, $
                                   "map_w8_q_2mm", map_struct.map_i_1mm*0.d0, $
                                   "map_w8_u_2mm", map_struct.map_i_1mm*0.d0)
   map_struct = map_struct_out
endif

end
