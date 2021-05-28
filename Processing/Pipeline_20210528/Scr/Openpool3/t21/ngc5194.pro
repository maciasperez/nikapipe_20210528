
pro ngc5194, reset=reset, preproc=preproc, average=average

source = 'NGC5194'
obstype = 'onTheFlyMap'  ; could be Lissajous too Insensitive to case
imrange_1mm = [-0.1,1]*0.1    ; Guess the range in Jy/Beam
imrange_2mm = [-0.1,1]*0.03
mapsize = 500. ; Map size in arcsec
avoid_list = ['20150126s44']  ; corrupted file

restore,'$NIKA_SOFT_DIR/Pipeline/Datamanage/Logbook/' + $
        'Log_Iram_tel_Run11_v0.save'
; Example : avoid_list = ['20141113s209', '20141113s210']
indscan = nk_select_scan( scan, source, obstype, nscans, avoid = avoid_list)
print, nscans, ' scans found'
scanl = scan[indscan].day + 's' + strtrim( scan[indscan].scannum,2)
if nscans gt 0 then begin
print, scanl
print, 'Projects found: ', scan[ indscan[uniq( scan[indscan].projid)]].projid
endif

scan_list = scanl
print, '------------------------------'


;; Define parameters and output directories
nk_default_param, param
param.source       = source
param.silent       = 0
param.map_reso     = 2.d0
param.map_xsize    = mapsize
param.map_ysize    = mapsize
param.glitch_width = 100

param.project_dir = !nika.plot_dir+"/"+strtrim( strupcase( source),2)
param.plot_dir    = param.project_dir+"/Plots"
param.preproc_dir = param.project_dir+"/Preproc"
param.up_dir      = param.project_dir+"/UP_files"
param.interpol_common_mode = 1
param.do_plot = 0 ; 1  ; Show plots or not
param.plot_ps = 1

param.flag_sat                     = 1
param.line_filter                  = 1
param.flag_uncorr_kid              = 1
param.corr_block_per_subscan       = 1
param.median_common_mode_per_block = 1
param.polynomial                   = 0

param.w8_per_subscan      = 1
param.kill_noisy_sections = 0  ; 1 for weak sources only

;;; 1st iteration on a few scans to locate the source
param.decor_method = "COMMON_MODE_ONE_BLOCK"
;param.decor_method = "COMMON_MODE_KIDS_OUT"
param.nsigma_corr_block = 2
param.decor_per_subscan = 1
param.decor_elevation   = 1
param.version           = 1
param.delete_all_windows_at_end = 0  ; 1
param.fine_pointing =  1
;param.fine_pointing =  0

nk_init_grid,    param, grid
;nk_default_mask, param, info, grid, d = 40

;; Preproc all files
filing  = 1
;preproc = 1
; To start from scratch do:
if keyword_set(reset) then nk_reset_filing, param, scan_list

param.cpu_time = 0
if keyword_set(preproc) then begin
   nk, scan_list, param=param, filing=filing, grid=grid
endif

;; Display result
if keyword_set(average) then begin
   param.do_plot = 1
   nk_average_scans, param, scan_list, out, total_obs_time, $
                     time_on_source_1mm, time_on_source_2mm, $
                     kidpar=kidpar, grid=grid
endif
stop

;; Smooth maps to have a nicer display
map_sn_1mm_smooth = out.map_1mm*0.d0
map_sn_2mm_smooth = out.map_1mm*0.d0

fwhm = 5. ; arcsec
xra = [-1,1]*3.1*fwhm
yra = xra
xyra2xymaps, xra, yra, param.map_reso, xmap, ymap, nx, ny, xmin, ymin, xgrid, ygrid
sigma_beam = fwhm*!fwhm2sigma
kernel = exp(-(xmap^2+ymap^2)/(2.*sigma_beam^2))
kernel = kernel/total(kernel)

map_conv = convolve( out.map_2mm, kernel)
junk = out.map_2mm*0.d0
w = where( finite( out.map_var_2mm) eq 1 and out.map_var_2mm ne 0, nw)
junk[w] = out.map_var_2mm[w]
map_var_conv = convolve( junk, kernel^2)
;; Signal/Noise smoothed map
map_sn_2mm_smooth[w] = map_conv[w]/sqrt( map_var_conv[w])

map_conv = convolve( out.map_1mm, kernel)
junk = out.map_1mm*0.d0
w = where( finite( out.map_var_1mm) eq 1 and out.map_var_1mm ne 0, nw)
junk[w] = out.map_var_1mm[w]
map_var_conv = convolve( junk, kernel^2)
map_sn_1mm_smooth[w] = map_conv[w]/sqrt( map_var_conv[w])

wind, 1, 1, /free, /large
my_multiplot, 2, 3, pp, pp1, gap_x=0.1, xmargin=0.1, /rev
educated = 1
coltable=4
lambda      = 1
NEFD_source = 1
NEFD_center = 0

nk_map_photometry, out.map_1mm, out.map_var_1mm, out.nhits_1mm, $
                   grid.xmap, grid.ymap, !nika.fwhm_nom[0], $
                   flux_1mm, sigma_flux_1mm, $
                   sigma_bg, output_fit_par, output_fit_par_error, $
                   bg_rms_source, flux_center, $
                   sigma_flux_center, sigma_bg_center, $
                   integ_time_center, $
                   educated=educated, $
                   k_noise=k_noise, position=pp1[0,*], $
                   title=param.source+' 1mm', $
                   xtitle=xtitle, ytitle=ytitle, param=param, $
                   NEFD_source=NEFD_source, NEFD_center=NEFD_center, $
                   imrange=imrange_1mm, $
                   total_obs_time=total_obs_time, $
                   lambda=lambda, input_fit_par=input_fit_par, $
                   sigma_flux_center_toi=sigma_flux_center_toi, $
                   toi_nefd=toi_nefd, coltable = coltable


lambda      = 2
NEFD_source = 1
NEFD_center = 0
nk_map_photometry, out.map_2mm, out.map_var_2mm, out.nhits_2mm, $
                   grid.xmap, grid.ymap, !nika.fwhm_nom[1], $
                   flux_2mm, sigma_flux_2mm, $
                   sigma_bg, output_fit_par, output_fit_par_error, $
                   bg_rms_source, flux_center, $
                   sigma_flux_center, sigma_bg_center, $
                   integ_time_center, $
                   educated=educated, $
                   k_noise=k_noise, position=pp1[1,*], $
                   title=param.source+' 2mm', $
                   xtitle=xtitle, ytitle=ytitle, param=param, $
                   NEFD_source=NEFD_source, NEFD_center=NEFD_center, $
                   imrange=imrange_2mm, $
                   lambda=lambda, input_fit_par=input_fit_par, $
                   sigma_flux_center_toi=sigma_flux_center_toi, $
                   toi_nefd=toi_nefd, coltable = coltable

imview, out.map_1mm, fwhm=10./param.map_reso, xmap=grid.xmap, ymap=grid.ymap, $
        position=pp1[2,*], /noerase, imrange=imrange_1mm, $
        title=param.source+' 1mm (smooth)'
oplot, [0], [0], psym=1, col=255
imview, out.map_2mm, fwhm=10./param.map_reso, xmap=grid.xmap, ymap=grid.ymap, $
        position=pp1[3,*], /noerase, imrange=imrange_2mm, $
        title=param.source+' 2mm (smooth)'
oplot, [0], [0], psym=1, col=255

imview, map_sn_1mm_smooth, xmap=grid.xmap, ymap=grid.ymap, $
        position=pp1[4,*], /noerase, imrange=[-1,1]*4, title='S/N 1mm smooth'
imview, map_sn_2mm_smooth, xmap=grid.xmap, ymap=grid.ymap, $
        position=pp1[5,*], /noerase, imrange=[-1,1]*4, title='S/N 2mm smooth'

if param.plot_png eq 1 then $
   jpgout,  param.project_dir+'/Plots/'+source+ '_'+ scan_list[0]+'_'+ $
          strtrim( n_elements(scan_list),2)+'scans.jpg', /over


end
