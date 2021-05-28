;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_reset_grid
;
; CATEGORY: ?
;
; CALLING SEQUENCE:
;         nk_reset_grid, grid
; 
; PURPOSE: 
;        Reset output maps in grid
; 
; INPUT: 
;        - grid
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
;        - Jan 2017: NP
;-

pro nk_reset_grid, grid

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_reset_grid, grid"
   return
endif


grid.integ_time = 0.d0
grid.map_i_1mm = 0.d0
;grid.map_i_2mm = 0.d0
grid.map_var_i_1mm = 0.d0
;grid.map_var_i_2mm = 0.d0
grid.nhits_1mm = 0.d0
;grid.nhits_2mm = 0.d0
grid.map_i1 = 0.d0
grid.map_i2 = 0.d0
grid.map_i3 = 0.d0
grid.map_var_i1 = 0.d0
grid.map_var_i2 = 0.d0
grid.map_var_i3 = 0.d0
grid.nhits_1 = 0.d0
grid.nhits_2 = 0.d0
grid.nhits_3 = 0.d0
;; grid.nefd_i1 = 0.d0
;; grid.nefd_i2 = 0.d0
;; grid.nefd_i3 = 0.d0
;; grid.nefd_i_1mm = 0.d0
;; grid.nefd_i_2mm = 0.d0
grid.nvalid_kids1 = 0
grid.nvalid_kids2 = 0
grid.nvalid_kids3 = 0
grid.nvalid_kids_1mm = 0
;grid.nvalid_kids_2mm = 0
grid.iter_mask_1mm = 0.d0
;grid.iter_mask_2mm = 0.d0
map_w8_i1 = 0.d0
map_w8_i2 = 0.d0
map_w8_i3 = 0.d0
map_w8_I_1mm = 0.d0
;;         map_w8_I_2mm = 0.d0
;;         covar_iq1 = 0.d0
;;         covar_iu1 = 0.d0
;;         covar_qu1 = 0.d0
;;         covar_iq2 = 0.d0
;;         covar_iu2 = 0.d0
;;         covar_qu2 = 0.d0
;;         covar_iq3 = 0.d0
;;         covar_iu3 = 0.d0
;;         covar_qu3 = 0.d0
;;         covar_iq_1mm = 0.d0
;;         covar_iu_1mm = 0.d0
;;         covar_qu_1mm = 0.d0
;;         covar_iq_2mm = 0.d0
;;         covar_iu_2mm = 0.d0
;;         covar_qu_2mm = 0.d0

end




