;;pro grb1449_730

num_list =  [204, 205, 206, 207, 208, 209, 210, 211, 212, 213, 214, 215]
scan_list = '20141109s'+strtrim( num_list, 2)
nscans = n_elements(scan_list)

source = "GRB1449+730"

;; Define parameters and output directories
nk_default_param, param

;;**************
;; Remove the last subscan that crashes nk_get_cm_sub each time
;;param.cut_scan_exec = "nsn_max = max( where( data.subscan lt max(data.subscan)))"
;;**************

param.source            = source
param.silent            = 1
param.map_reso          = 2.d0
param.map_xsize         = 300.d0
param.map_ysize         = 300.d0
param.glitch_width      = 200 ; improves glitch detection when there's no planet to fear

param.speed_tol =  10.d0

param.project_dir = !nika.plot_dir+"/"+strtrim( strupcase( source),2)
param.plot_dir    = param.project_dir+"/Plots"
param.preproc_dir = param.project_dir+"/Preproc"
param.interpol_common_mode = 1
param.do_plot  = 1
param.plot_png = 0
param.plot_ps  = 0

;;; 1st iteration on a few scans to locate the source
;param.decor_method    = "COMMON_MODE_BAND_MASK"
param.decor_method = "common_mode_kids_out"
param.decor_per_subscan = "yes"
param.polynomial        = 1
param.decor_elevation   = 1
param.version           = 1

nk_init_grid, param, grid
d = sqrt( grid.xmap^2 + grid.ymap^2)
w = where( d lt 20, nw)
grid.mask_source[w] = 0.d0

;; Preproc all files
filing  = 1
preproc = 1
xml =  1
delvarx, simpar

;; ;; nk_reset_filing, param, scan_list
;; nk, scan_list, param=param, filing=filing, preproc=preproc, $
;;     grid=grid, simpar=simpar, no_output_map=no_output_map,  xml = xml
;; 
;; ;; Display result
;; param.do_plot = 1
;; param.plot_ps = 0
;; nk_average_scans, param, scan_list, out, total_obs_time, $
;;                   time_on_source_1mm, time_on_source_2mm, $
;;                   kidpar=kidpar, grid=grid

;; Check another decorrelation
beam_pos_list = [[-50, -30, -10, 10, 30, 50], $
                  [-50, -30, -10, 10, 30, 50]]
param.decor_method = "common_mode_band_mask"
;nk_preproc2maps,  scan_list, param, info, grid
;stop

flux_1mm = [5.d0, 17, -0.79, 3,    7,     2,    21,   13, 8, -5, 6, 12] 
flux_2mm = [3.d0,  5, 0.022, 0.46, 0.88, -0.14, -0.34, 1, 2, 2, -2,  1]
print,  stddev(flux_1mm)/sqrt(n_elements(scan_list))
print,  stddev(flux_2mm)/sqrt(n_elements(scan_list))
;2.1447736
;0.5170784

nk_average_scans, param, scan_list, out, total_obs_time, $
                  time_on_source_1mm, time_on_source_2mm, $
                  kidpar=kidpar, grid=grid, beam_pos_list = beam_pos_list
;; flux center 1mm:
;0.0015708467 +- 0.0011666172
;; flux center 2mm:
;0.00022341955 +- 0.00027540435

;stddev(flux_list):     0.0060617158
;stddev(flux_list):    0.00096446689

;; Prise en compte des differentes d'opacite et d'elevation entre Uranus et le
;; GRB:
el_uranus = 43.*!dtor
el_grb =  25.*!dtor
tau_grb_225 =  0.11
tau_uranus_225 =  0.15 ; au pif pour le moment en interpolatn des 0.2 du debut de la session et des 0.1 de fin de session

corr_grb =  exp(-tau_grb_225)/sin(el_grb)
corr_uranus =  exp(-tau_uranus_225)/sin(el_uranus)
corr = corr_uranus/corr_grb

print,  "-------------------------------"
print,  "Uncorrected for opacity and elevation:"
corr =  1
print,  "fluxes: "
print,  [0.0015708467, 0.00022341955]*corr*1000

print, "stat. error:"
print,  [0.0011666172, 0.00027540435]*corr*1000

print,  "stdev(flux_list) (1sigma):"
print,  [0.0060617158, 0.00096446689] * corr*1000
print,  "stddev flux_center per scan (1sigma)/sqrt(nscans):"
print,  [2.1447736, 0.5170784] * corr

print,  '3 sigma upper limits:'
print,  [0.0060617158, 0.00096446689] * corr * 3
print,  [2.1447736, 0.5170784] * corr * 3
print,  ""
print,  ""



print,  "-------------------------------"
print,  "Corrected for opacity and elevation:"
corr = corr_uranus/corr_grb

print,  "fluxes: "
print,  [0.0015708467, 0.00022341955]*corr*1000

print, "stat. error:"
print,  [0.0011666172, 0.00027540435]*corr*1000

print,  "stdev(flux_list) (1sigma):"
print,  [0.0060617158, 0.00096446689] * corr*1000
print,  "stddev flux_center per scan (1sigma)/sqrt(nscans):"
print,  [2.1447736, 0.5170784] * corr

print,  '3 sigma upper limits:'
print,  [0.0060617158, 0.00096446689] * corr * 3
print,  [2.1447736, 0.5170784] * corr * 3
print,  ""
print,  ""




;; Add a simulated source to see filtering effects:
nks_default_simpar,  simpar,  n_point = 1
simpar.PS_FLUX_1MM = 0.01
simpar.ps_flux_2mm = 0.01
nk_preproc2maps,  scan_list, param, info, grid, simpar = simpar
nk_average_scans, param, scan_list, out, total_obs_time, $
                  time_on_source_1mm, time_on_source_2mm, $
                  kidpar=kidpar, grid=grid, beam_pos_list = beam_pos_list



stop

;; delvarx, simpar
;; ;;-----------------------------
;; ;; add a source to see if i detect it...
;; nks_default_simpar, simpar, n_point=1
;; simpar.ps_flux_1mm = 0.01
;; simpar.ps_flux_2mm = 0.01
;; 
;; ;param.decor_method = "common_mode"
;; 
;; 
;; nk_preproc2maps, scan_list, param, info, grid, simpar=simpar
;; param.do_plot = 1
;; param.plot_ps = 0
;; nk_average_scans, param, scan_list, out, total_obs_time, $
;;                   time_on_source_1mm, time_on_source_2mm, $
;;                   kidpar=kidpar, grid=grid, title_ext='ADDED POINT SOURCE'
;; 
;; 
;; 
;; wind, 1, 1, /free
;; imview, filter_image(out.map_2mm,fwhm=4,/all), xmap=grid.xmap, ymap=grid.ymap
;; 
;; stop

end
