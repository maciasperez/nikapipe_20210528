;+
;
; SOFTWARE: 
;        NIKA pipeline
;
; NAME: 
;        nk_init_output_maps
;
; CATEGORY: 
;        general, initialization
;
; CALLING SEQUENCE:
;         nk_init_output_maps, grid, output_maps
; 
; PURPOSE: 
;        Creates the output map structure of the pipeline.
; 
; INPUT: 
;        - grid
; 
; OUTPUT: 
;        - output_maps
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - June 16th, 2016, N. Ponthieu
;-

pro nk_init_output_maps, info, grid, output_maps

if n_params() lt 1 then begin
   message, /info, "Calling sequence: "
   print, "nk_init_output_maps, info, grid, output_maps"
   return
endif

output_maps = {map_i_1mm:grid.xmap*0.d0, $
               map_i_2mm:grid.xmap*0.d0, $
               map_var_i_1mm:grid.xmap*0.d0, $
               map_var_i_2mm:grid.xmap*0.d0, $
               nhits_1mm:grid.xmap*0.d0, $
               nhits_2mm:grid.xmap*0.d0, $
               xmap:grid.xmap, $
               ymap:grid.ymap, $
               mask_source:grid.mask_source, $
               xmin:grid.xmin, $
               ymin:grid.ymin, $
               nx:grid.nx, $
               ny:grid.ny, $
               map_reso:grid.map_reso}


if info.polar ne 0 then $
   output_maps = create_struct( output_maps, $
                                "map_q_1mm", grid.xmap*0.d0, $
                                "map_q_2mm", grid.xmap*0.d0, $
                                "map_var_q_1mm", grid.xmap*0.d0, $
                                "map_var_q_2mm", grid.xmap*0.d0, $
                                "map_u_1mm", grid.xmap*0.d0, $
                                "map_u_2mm", grid.xmap*0.d0, $
                                "map_var_u_1mm", grid.xmap*0.d0, $
                                "map_var_u_2mm", grid.xmap*0.d0, $
                                "map_ipol_1mm", grid.xmap*0.d0, $
                                "map_ipol_2mm", grid.xmap*0.d0, $
                                "map_var_ipol_1mm", grid.xmap*0.d0, $
                                "map_var_ipol_2mm", grid.xmap*0.d0)
end
