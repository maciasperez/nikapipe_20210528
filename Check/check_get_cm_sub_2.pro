
;; Uranus
scan = '20141109s198'

nk_default_param, param
param.no_opacity_correction = 0
param.decor_method          = 'common_mode_kids_out'
param.decor_per_subscan = "no"
param.fine_pointing         = 1

nk_init_grid, param, grid
nk_default_mask, param, info, grid

nk, scan, param=param, grid=grid, /xml, info=info
print, info.tau_1mm, info.tau_2mm








;; ;; Uranus
;; scan = '20141109s232'
;; nk, scan, param=param, grid=grid, /xml, info=info
;; print, info.tau_1mm, info.tau_2mm


end
