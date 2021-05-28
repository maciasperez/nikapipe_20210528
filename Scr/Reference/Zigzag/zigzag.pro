

;; Computes one map with "forward" subscans only, one with "backward"
;; subscan only and measures the distance between the two centroids
;; for a list of time shifts.
;;------------------------------------------------------------------

pro zigzag, scan, t_shift_min, t_shift_max, t_step, d, t_shift, fwhm_res, plot_dir=plot_dir, pps=pps, $
            input_kidpar_file=input_kidpar_file, kid_maps=kid_maps, reso=reso, el_avg=el_avg, $
            noplot=noplot, out_data_file=out_data_file, in_data_file=in_data_file
  
if not keyword_set(plot_dir) then plot_dir = "."  
spawn, "mkdir "+plot_dir

nsteps = round( (t_shift_max-t_shift_min)/t_step)
t_shift = dindgen(nsteps)*t_step + t_shift_min

;; To be sure that !nika.run won't enter any specific case of a run =< 5
!nika.run = !nika.run > 11

scan2daynum, scan, day, scan_num

nk_default_param, param
param.scan_num        = scan_num
param.day             = day
param.scan            = strtrim(day,2)+"s"+strtrim(scan_num,2)
;;param.math            = "RF"               ; to save time
param.do_plot         = 1
param.flag_uncorr_kid = 0
param.flag_sat        = 1
param.flag_oor        = 1
param.flag_ovlap      = 1
param.fast_deglitch   = 1
param.cpu_time        = 0 ; 1

param.do_opacity_correction = 0

if param.cpu_time then cpu_time_0 = systime( 0, /sec)

nk_default_info, info

imb_fits_file = !nika.imb_fits_dir+"/iram30m-antenna-"+scan+"-imb.fits"
if file_test(imb_fits_file) eq 0 then begin
   message, /info, "copying imbfits file from mrt-lx1"
   spawn, "scp t22@150.214.224.59:/data/ncs/data/"+day+"/scans/"+strtrim(scan_num,2)+"/*antenna*fits $IMB_FITS_DIR/."
endif

nk_update_param_info, param.scan, param, info

;; Pass source to param to have at least an approximate calibration
;; (uncorrected for opacity at this stage, but still better than nothing).
param.source = info.object

;; Read data
param.silent=0
param.do_plot=0
param.decor_method = 'common_mode_kids_out'
param.set_zero_level_per_subscan =  1
param.map_center_ra  =  !values.d_nan
param.map_center_dec =  !values.d_nan
param.map_proj = "azel"
param.interpol_common_mode =  1
param.plot_dir = !nika.plot_dir+"/Zigzag"

;;param.decor_cm_dmin =  40       ; enlarge a bit in case the input kidpar offsets are too approximative
param.mask_default_radius = 40.
param.do_opacity_correction = 0
param.fast_deglitch = 1

spawn, "mkdir -p "+param.plot_dir

if keyword_set(input_kidpar_file) then begin
   param.file_kidpar = input_kidpar_file
   param.force_kidpar = 1
endif

process = 1
if keyword_set(in_data_file) then begin
   if file_test(in_data_file) then begin
      restore, in_data_file
      process = 0
   endif
endif

if process eq 1 then begin
   nk_getdata, param, info, data, kidpar, sn_min=sn_min, sn_max=sn_max, $
               force_file=force_file, xml=xml, read_type=1

   if info.status eq 1 then return
   
   if info.polar ne 0 then begin
      param.polar_lockin_freqlow   = 0.01
      param.polar_lockin_freqhigh = info.hwp_rot_freq - 0.01
      nk_deal_with_hwp_template, param, info, data, kidpar
   endif

   nk_deglitch_fast, param, info, data, kidpar

   if param.do_opacity_correction eq 1 then $
      nk_get_opacity, param, info, data, kidpar

   nk_init_grid_2, param, info, grid
   nk_get_kid_pointing, param, info, data, kidpar
   nk_get_ipix, param, info, data, kidpar, grid
   nk_mask_source, param, info, data, kidpar, grid
   nk_clean_data_2, param, info, data, kidpar, out_temp_data = out_temp_data
;;   nk_set0level,  param,  info,  data,  kidpar
   nk_set0level_2, param, info, data, kidpar
   nk_w8, param, info, data, kidpar

   if keyword_set(out_data_file) then save, data, kidpar, file=out_data_file
endif

toi = data.toi

xra_map = [-400, 400] ; [-200, 200]
if keyword_set(reso) then param.map_reso = reso

nsn = n_elements(toi[0,*])
w8  = fltarr( nsn) + 1.d0
wf = where( (data.subscan mod 2) eq 0, nw, compl=wb)

time = dindgen(nsn)/!nika.f_sampling
flag = data.flag
ofs_az = data.ofs_az            ; backup
ofs_el = data.ofs_el
az     = data.az
el     = data.el
data_w8 = data.w8
paral  = data.paral

nshifts = n_elements(t_shift)
d = dblarr(3,nshifts)
fwhm_res = dblarr(3,nshifts)
for it=0, nshifts-1 do begin
   time1 = time + t_shift[it]
   
   data.ofs_az = interpol( ofs_az, time, time1)
   data.ofs_el = interpol( ofs_el, time, time1)
   data.az     = interpol( az,     time, time1)
   data.el     = interpol( el,     time, time1)
   data.paral  = interpol( paral,  time, time1)
   nsnflag = round( t_shift[it]*!nika.f_sampling) > 1

   data.flag = flag
   data[0:nsnflag-1].flag       += 1
   data[nsn-nsnflag:nsn-1].flag += 1

   xra = xra_map
   yra = xra_map
   param.map_xsize = (xra[1]-xra[0])*1.1
   param.map_ysize = (yra[1]-yra[0])*1.1
   nk_init_grid_2, param, info, grid_azel
   wkill = where( finite(data.ofs_az) eq 0 or finite(data.ofs_el) eq 0, nwkill)
   ix    = (data.ofs_az - grid_azel.xmin)/grid_azel.map_reso
   iy    = (data.ofs_el - grid_azel.ymin)/grid_azel.map_reso
   if nwkill ne 0 then begin
      ix[wkill] = -1
      iy[wkill] = -1
   endif
   ipix = double( long(ix) + long(iy)*grid_azel.nx)
   w = where( long(ix) lt 0 or long(ix) gt (grid_azel.nx-1) or $
              long(iy) lt 0 or long(iy) gt (grid_azel.ny-1), nw)
   if nw ne 0 then ipix[w] = !values.d_nan ; for histogram
   ipix_azel = ipix

   ;; Compute Individual kid maps in (Az,el)
   if keyword_set(kid_maps) then begin
      get_bolo_maps_6, toi, ipix_azel, w8, kidpar, grid_azel, map_list_azel, nhits_azel
      save, kidpar, grid_azel, map_list_azel, nhits_azel, $
            file='maps_tshift_'+strtrim(t_shift[it],2)+"_reso_"+strtrim(grid_azel.map_reso,2)+".save"
   endif
   
   ;; Combined map with earlier kidpar
   param.map_proj = "azel"
   nk_get_kid_pointing, param, info, data, kidpar
   nk_get_ipix, param, info, data, ikidpar, grid_azel

   data.w8 = data_w8
   data[wf].w8 = 0.d0
   grid0 = grid_azel
   nk_projection_4, param, info, data, kidpar, grid0

   data.w8 = data_w8
   data[wb].w8 = 0.d0
   grid1 = grid_azel
   nk_projection_4, param, info, data, kidpar, grid1

   grid_tags = tag_names(grid_azel)
   for iarray=1, 3 do begin
      if iarray eq 2 then fwhm=!nika.fwhm_nom[1] else fwhm=!nika.fwhm_nom[0]
      wh = where( strupcase(grid_tags) eq "NHITS_"+strtrim(iarray,2), nwh)
      if nwh ne 0 then begin
         wi   = where( strupcase(grid_tags) eq "MAP_I"+strtrim(iarray,2), nwi)
         wvar = where( strupcase(grid_tags) eq "MAP_VAR_I"+strtrim(iarray,2), nwvar)
         if defined(pp) then position=pp[iarray-1,0,*]
         nk_map_photometry, grid0.(wi), grid0.(wvar), grid0.(wh), grid0.xmap, grid0.ymap, fwhm, $
                            flux, sigma_flux, sigma_bg, output_fit_par0, noplot=noplot, educated=educated, position=position, $
                            title='I1 odd shift='+strtrim(t_shift[it],2), charsize=charsize, charbar=charsize, $
                            grid_step=!nika.grid_step[iarray-1]
         if defined(pp) then position=pp[iarray-1,1,*]
         nk_map_photometry, grid1.(wi), grid1.(wvar), grid1.(wh), grid1.xmap, grid1.ymap, fwhm, $
                            flux, sigma_flux, sigma_bg, output_fit_par1, noplot=noplot, educated=educated, position=position, $
                            title='I1 even shift='+strtrim(t_shift[it],2), charsize=charsize, charbar=charsize, $
                            grid_step=!nika.grid_step[iarray-1]
         d[iarray-1,it] = sqrt( (output_fit_par0[4]-output_fit_par1[4])^2 + $
                                (output_fit_par0[5]-output_fit_par1[5])^2)

;;         ;; measure the combined FWHM
;;         nk_average_grids, grid0, grid1, grid_avg
;;         nk_map_photometry, grid_avg.(wi), grid_avg.(wvar), grid_avg.(wh), grid_avg.xmap, grid_avg.ymap, fwhm, $
;;                            flux, sigma_flux, sigma_bg, output_fit_par, noplot=noplot, educated=educated, position=position, $
;;                            title='I1 even shift='+strtrim(t_shift[it],2), charsize=charsize, charbar=charsize
;;         fwhm_res[iarray-1,it] = sqrt( output_fit_par[2]*output_fit_par[3])/!fwhm2sigma

         print, ""
         print, "A"+strtrim(iarray,2)+", tshift: "+strtrim(t_shift[it],2)
         print, "x,y center forward  : ", output_fit_par0[4:5]
         print, "x,y center backward : ", output_fit_par1[4:5]
;;         print, "fwhm: ", fwhm_res[iarray-1,it]
         
      endif
   endfor
   
endfor

save, t_shift, d, file='zigzag_results_'+scan+'.save'

if file_test('zigzag_results_'+scan+'.save') eq 0 then begin
   openw, 1, "failures.dat", /append
   printf, 1, "cound not save zigzag results for scan "+scan
   close, 1
endif

end
