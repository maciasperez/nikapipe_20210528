;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_compute_ptg_offsets
;
; CATEGORY: ?
;
; CALLING SEQUENCE:
;         nk_compute_ptg_offsets, scan, azel_ptg_offsets [, output_dir=output_dir]
; 
; PURPOSE: 
;       Computes the actual pointing offsets w.r.t the map center for a bright
;       point source.
; 
; INPUT: 
;        - scan: the scan reference YYYYsNNN
; 
; OUTPUT: 
;        - offsets: pointing offsets in arcsec (az,el)
; 
; KEYWORDS:
;        - output_dir: if present, an ascii file containing the offsets is
;          written in this directory. It should then be copied into
;          $OFF_PROC_DIR to be shared with everyone after validation.
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Sept. 9th, 2015: NP
;-

pro nk_compute_ptg_offsets, scan, azel_ptg_offsets, output_dir=output_dir, noplot=noplot

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_compute_ptg_offsets, scan, azel_ptg_offsets, output_dir=output_dir"
   return
endif


;; Define parameters and output directories
nk_default_param, param
param.silent       = 0
param.map_reso     = 2.d0
param.project_dir = !nika.plot_dir+"/ptg_offet_derivation"
param.plot_dir    = param.project_dir+"/Plots"
param.interpol_common_mode = 1

param.do_plot  = 1
if keyword_set(noplot) then param.do_plot = 0
param.plot_png = 0

param.line_filter                  = 0
param.flag_sat                     = 1
param.flag_uncorr_kid              = 1 

param.w8_per_subscan      = 1
param.map_proj = "AZEL"
param.decor_method = "COMMON_MODE_KIDS_OUT"
param.decor_per_subscan = 1
param.decor_elevation   = 1
param.version           = 1
param.delete_all_windows_at_end = 0

param.fine_pointing = 1

param.polar_lockin_freqhigh =  2.d0 ; 2 seems ok on an itensity beam is safer wrt hwp rot freq ; 2.9 ; close to hwp rot freq
param.fourier_opt_sample = 1

nk_init_grid,    param, info, grid
nk_default_mask, param, info, grid, radius=25

param.do_fpc_correction = 0 ; make sure here not to apply a previously derived correction
nk, scan, param=param, grid=grid, info=info

wind, 1, 1, /free, /large, iconic = param.iconic
nk_map_photometry_2, grid, f, sf, sbg, fit_par, lambda=2, /edu, title=scan
azel_ptg_offsets = dblarr(2)
azel_ptg_offsets[0] = -fit_par[4]
azel_ptg_offsets[1] = -fit_par[5]

if keyword_set(output_dir) then begin
   get_lun,  lu
   openw,    lu, output_dir+"/"+strtrim(scan,2)+".dat"
   printf,   lu, "# Delta Azimuth [arcsec], Delta Elevation [arcsec]"
   printf,   lu, strtrim(azel_ptg_offsets[0],2)+", "+strtrim(azel_ptg_offsets[1],2)
   close,    lu
   free_lun, lu
endif

end
            
