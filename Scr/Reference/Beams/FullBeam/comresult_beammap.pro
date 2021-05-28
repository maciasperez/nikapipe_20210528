;;
;;
;;
;;    Production de la carte de lobe pour la Sect. Full Beam pattern
;;    + fit de model de lobe sur cette carte
;;
;;    pour fit complet du profile voir comresult_profiles.pro
;;
;;________________________________________________________________________

project_dir  = '/home/perotto/NIKA/Plots/Lobes'
plot_dir     = project_dir+'/Plots/'
png          = 1
ps           = 0

plot_variance = 0

launch_nk    = 0


;; decor method
method = 'COMMON_MODE_ONE_BLOCK'
;;method = 'COMMON_MODE_KIDS_OUT'
;;method = 'RAW_MEDIAN'


;; version
;;version      = 1  ;; "CM_KIDS_OUT"
version      = 2  ;; "CM_ONE_BLOCK"
;;version      = 3  ;; "RAW_MEDIAN"
;;version      = 4  ;; "CM_ONE_BLOCK" param JFL
version      = 5  ;; "CM_ONE_BLOCK" debug : correct kidpar

;;input_kidpar_file = !nika.off_proc_dir+'/kidpar_20171025s41_v2_LP_skd_kids_out.fits'
;;input_kidpar_file = !nika.off_proc_dir+'/kidpar_best3files_FXDC0C1_GaussPhot_NewConv.fits'
input_kidpar_file   = !nika.off_proc_dir+'/kidpar_20171025s41_v2_LP_md_recal_calUranus.fits'


;; N2R12
;;project_dir  = '/home/perotto/NIKA/Plots/N2R12/Profiles'
;;plot_dir     = project_dir+'/Plots/'


;; 1./  best file
;;scan_list = ['20170125s243']
;;average      = 0

;;scan_list = ['20170125s243', '20170226s425', '20170227s84']
;;scan_list = ['20170125s243', '20170224s177', '20170419s133', '20170420s113', '20170424s116', '20170424s123']

;; 2. / best scans of Uranus
;;scan_list = ['20170125s223', '20170125s243']

;;average      = 1
;;hetero_combo = 1
;; combi_file   = project_dir+'/v_'+strtrim(string(version),2)+'/Combi_Uranus_results.save'
;; combi_file   = project_dir+'/v_'+strtrim(string(version),2)+'/Combi_Uranus_results_recal.save'

;; 3./ best 4 files
scan_list   = ['20170125s223', '20170125s243', '20170224s177', '20170226s415']
source_list = ['Uranus', 'Uranus', 'Neptune', '3C84']

average          = 1
hetero_combo     = 1
combi_file       = project_dir+'/v_'+strtrim(string(version),2)+'/Combi_all_results_recal.save'

;; NIKA2C
project_dir  = '/home/perotto/NIKA/Plots/Beams/N2R9/'
plot_dir     = project_dir+'/Plots/'
version      = 1

project_dir  = '/home/perotto/NIKA/Plots/Lobes/'
plot_dir     = project_dir+'/Plots/'
combi_file   = project_dir+'/Combi_all_results_recal.save'

;; 4./ N2R12 good beammaps
;;scan_list_mars   = ['20171022s158', '20171023s101', '20171024s105']
;;scan_list_uranus = ['20171025s41', '20171025s42', '20171027s49', '20171028s310', '20171029s266']

;;scan_list = ['20171022s158']
;;scan_list = ['20171025s41']
;;average          = 0
;;hetero_combo     = 0
;scan_list = [scan_list_mars]
;average          = 1
;hetero_combo     = 0
;combi_file       = project_dir+'/v_'+strtrim(string(version),2)+'/Lobes_N2R12_Combi_Mars.save'
;scan_list = scan_list_uranus
;average          = 1
;hetero_combo     = 0
;combi_file       = project_dir+'/v_'+strtrim(string(version),2)+'/Lobes_N2R12_Combi_Uranus.save'

;;scan_list  = [scan_list_mars[1:2], scan_list_uranus]
;;average           = 0
;;_______________________________________________________________________________________



nscan = n_elements(scan_list)

if launch_nk gt 0 then begin
   
   if nscan gt 1 then begin
      split_for, 0, nscan-1, nsplit=nscan, $
                 commands=['nk_lobes_sub, i, scan_list, input_kidpar_file=input_kidpar_file, project_dir=project_dir, version=version'+$
                          ', method=method'], $
                 varnames = ['scan_list', 'input_kidpar_file', 'project_dir', 'version', 'method']
   endif else begin
      
      scan = scan_list[0]
      
      
      nk_default_param, param
      param.decor_cm_dmin  = 100.
      param.output_noise   = 1
      param.do_opacity_correction = 1

      
      param.decor_method   = method
            
      param.map_reso       = 1.d0
      param.map_xsize      = 600d0
      param.map_ysize      = 600d0
      param.map_proj       = 'azel'
            
      

      ;; parametres de JFL
      ;; nk_default_param, param
      ;; param.decor_cm_dmin = 90.0
      ;; param.map_proj = 'AZEL'
      ;; param.new_deglitch = 0
      ;; param.glitch_nsigma=5
      ;; param.do_opacity_correction = 2      ;; diff
      ;; param.map_reso = 1.0d0            
      ;; param.map_xsize = 400                ;; diff
      ;; param.map_ysize = 400
      ;; param.decor_method = "COMMON_MODE_ONE_BLOCK"
      ;; param.decor_per_subscan = 1
      ;; param.decor_elevation = 1
      ;; param.w8_per_subscan = 1             ;; diff
      ;; param.set_zero_level_per_subscan = 1
      ;; param.fine_pointing = 0
      ;; param.do_aperture_photometry=1
      ;; param.flag_uncorr_kid=0
      ;; param.flag_sat =1
      ;; param.flag_oor =1                    ;; diff
      ;; param.flag_ovlap=1
      ;; param.interpol_common_mode=1
      ;; param.do_plot =1
      ;; param.do_tel_gain_corr = 2           ;; diff

      ;; 
      param.force_kidpar   = 1
      param.file_kidpar    = input_kidpar_file
      param.map_smooth_1mm = 0
      param.map_smooth_2mm = 0
      
      param.plot_dir       = project_dir
      param.project_dir    = project_dir
      
      param.version        = version
      
      nk, scan, param=param
      
   endelse
   
endif

;;
;;   COMBINAISON
;;______________________________________________________________________________________
if average gt 0 then begin

   if file_test(combi_file) lt 1 then begin
      
      nk_default_param, param
      param.force_kidpar   = 1
      param.file_kidpar    = !nika.off_proc_dir+'/kidpar_best3files_FXDC0C1_GaussPhot.fits'
;param.file_kidpar    = !nika.off_proc_dir+'/kidpar_20170125s243_v2_skd1.fits'
      param.decor_cm_dmin  = 100.
      param.output_noise   = 1
      param.do_opacity_correction = 1

      if version eq 2 then param.decor_method   = "COMMON_MODE_ONE_BLOCK"
      param.version        = version
      
      param.map_reso       = 1.d0
      param.map_xsize      = 600d0
      param.map_ysize      = 600d0
      param.map_proj       = 'azel'
      param.map_smooth_1mm = 0
      param.map_smooth_2mm = 0
      
      param.do_plot = 0
      
      param.plot_dir       = project_dir
      param.project_dir    = project_dir

      if hetero_combo lt 1 then begin
         nk_average_scans, param, scan_list, grid_tot, info=info_tot, /noplot
      endif else begin
         nk_average_hetero_scans, param, scan_list, grid_tot, info=info_tot, /noplot
      endelse
         
      save, param, scan_list, grid_tot, info_tot, filename=combi_file
   endif

  
   restore, combi_file, /v
   tags   = ['1', '3', '1MM', '2']
   under  = ['', '', '_', '']
   titles = ['A1', 'A3', 'A1&A3', 'A2']
   smooth = [3., 3., 3., 5.]
   ran    = [-0.3, -0.3, -0.3, -0.5 ]
   
   ntags = n_elements(tags)
   grid_tags = tag_names( grid_tot)
   info_tags = tag_names( info_tot)
   
   xmap = grid_tot.xmap
   ymap = grid_tot.ymap
   
   wind, 1, 1, xsize = 800, ysize = 650, /free, title='combo'
   my_multiplot, 2, 2,  pp, pp1, /rev, ymargin=0.08, gap_x=0.08, gap_y=0.08, xmargin = 0.08
   
   reso = param.map_reso
   
   if png eq 1 then outplot, file=plot_dir+"/Lobe_map_"+strtrim(param.source, 2)+"_v"+strtrim(string(param.version), 2)+"_dB", /png

   ;;alpha_flux_cuts = [0.4, 0.4, 0.4, 0.15]
   ;;alpha_flux_cuts = [0.5, 0.5, 0.5, 0.5]
   alpha_flux_cuts = [0.4, 0.4, 0.4, 0.25]
   ;;alpha_flux_cuts = [0.6, 0.6, 0.6, 0.35]

   internal_radius = [8.5d0, 8.5d0, 8.5d0, 13.5d0]
   
   for i=0, ntags-1 do begin
      print, 'MAP_I'+under[i]+strtrim(tags[i], 2)
      
      wpeak = where(info_tags eq 'RESULT_PEAK_'+strtrim(tags[i],2) )
      a_peak = info_tot.(wpeak)

      print, "A_peak = ", a_peak
      
      wmap = where(grid_tags eq 'MAP_I'+under[i]+strtrim(tags[i], 2), nw)
      map = grid_tot.(wmap)
      map1 = map/a_peak
      wvar = where(grid_tags eq 'MAP_VAR_I'+under[i]+strtrim(tags[i], 2), nw)
      var = grid_tot.(wvar)
      var1 = var/a_peak^2
      w = where( var1 gt 0, nw, compl=wcompl, ncompl=nwcompl)
      var_med = median( var1[w])
      imrange = [-1,1]*4.*stddev( map[where( var le var_med and var gt 0)])
      imrange = [-500.*stddev( map[where( var le var_med and var gt 0)]), 1d]
      imrange = [-10d, 1d]
                                ;imrange=0
      ;; Define the gaussian convolution kernel for output convolved maps
      input_sigma_beam = smooth[i]*!fwhm2sigma
      nx_beam_w8       = 2*long(4*input_sigma_beam/reso/2)+1
      ny_beam_w8       = 2*long(4*input_sigma_beam/reso/2)+1
      xx               = dblarr(nx_beam_w8, ny_beam_w8)
      yy               = dblarr(nx_beam_w8, ny_beam_w8)
      for ii=0, nx_beam_w8-1 do xx[ii,*] = (ii-nx_beam_w8/2)*reso
      for ii=0, ny_beam_w8-1 do yy[*,ii] = (ii-ny_beam_w8/2)*reso
      beam_w8  = exp(-(xx^2+yy^2)/(2.*input_sigma_beam^2))
      beam_w8  = beam_w8/total(beam_w8)
      map_conv = convol( map1, beam_w8)
      
      ;; imview, alog(abs(map_conv)), xmap=xmap, ymap=ymap, position= pp1[i, *], $
      ;;         /noerase, imrange=imrange, title=titles[i], charsize=0.8, charbar=0.7, $
      ;;         xtitle='az', ytitle='el', coltable=39
      
      ;; plot en dB
      d = sqrt(xmap^2 + ymap^2)
      apeak = max(map_conv(where(d lt 40.)))
      map_conv = map_conv/apeak
      map_db = 10.d0*alog(abs(map_conv))/alog(10.d0)
      imrange = [-44., 0.]
      
      ;;
      
      imview, map_db, xmap=xmap, ymap=ymap, position= pp1[i, *], $
              /noerase, imrange=imrange, title=titles[i], charsize=0.9, $
              charbar=0.7, formatbar='(f6.0)', nbvaluebar=4., unitsbar='dB', $
              xtitle='azimuth (arcsec)', ytitle='elevation (arcsec)', coltable=39

      ;;stop 
      ;;rad = xmap[300, *]
      ;;plot, rad, map_db[300,*]


      
      ;; profile
      ;;_________________________________________________________________________      

      ;; Fit only near the very center and far from it to
      ;; avoid side lobes
      wtag = where( strupcase(info_tags) eq "RESULT_FLUX_I"+under[i]+tags[i], nwtag)
      flux = info_tot.(wtag)
      wtag = where( strupcase(info_tags) eq "RESULT_OFF_X_"+tags[i], nwtag)
      x0   = info_tot.(wtag)
      wtag = where( strupcase(info_tags) eq "RESULT_OFF_Y_"+tags[i], nwtag)
      y0   = info_tot.(wtag)   
      
      ;; optimise the cut radius
      ;;------------------------------------------------------
      ;; d    = sqrt( (xmap-x0)^2 + (ymap-y0)^2)
      ;; rbg  = 100.
      ;; alpha_flux_cuts = indgen(51)/50.
      ;; ntest = n_elements(alpha_flux_cuts)
      ;; max = max(map(where(d le 40.)))
      ;; fit_apeak = dblarr(ntest)
      ;; fit_fwhm  = dblarr(ntest)
      ;; fit_chi2  = dblarr(ntest)
      ;; for ia= 0, ntest-1 do begin
      ;;    alpha_flux_cut = alpha_flux_cuts[ia]
      ;;    wfit = where( (map gt alpha_flux_cut*flux and d le rbg) or (d ge rbg and var lt mean(var)), nwfit, compl=wout)
      ;;    map_var0 = var
      ;;    map_var0[wout] = 0.d0
      ;;    nk_fitmap, map, map_var0, xmap, ymap, output_fit_par, covar, output_fit_par_error, $
      ;;               educated=educated, k_noise=k_noise, info=info_out, status=status, dmax=dmax, $
      ;;               xguess=xguess, yguess=yguess, guess_fit_par=guess_fit_par, sigma_guess=input_sigma_beam, map_fit=best_model
      ;;    ww = where(map_var0 gt 0., ndata)
      ;;    chi2 = total((map[ww]-best_model[ww])^2/map_var0[ww])/(ndata-7.)
      ;;    print,"max = ", output_fit_par[1], ", fwhm = ", sqrt( output_fit_par[2]*output_fit_par[3])/!fwhm2sigma, ", chi2 = ", chi2
      ;;    fit_apeak[ia] = output_fit_par[1]
      ;;    fit_fwhm[ia]  = sqrt( output_fit_par[2]*output_fit_par[3])/!fwhm2sigma
      ;;    fit_chi2[ia]  = chi2
      ;; endfor
      ;;

      ;; fixed internal radius
      ;;---------------------------------------------------
      alpha_flux_cut = alpha_flux_cuts[i]
      flux_threshold = alpha_flux_cut*flux

      chi2=1.
      ;;fit_main_beam_fwhm, map, var, xmap, ymap, x0, y0, $
      ;;                    output_fit_par, output_covar, output_fit_par_error, $
      ;;                    flux_thresh=flux_threshold, external_radius=100., chi2=chi2

      fit_main_beam_fwhm, map, var, xmap, ymap, x0, y0, $
                          output_fit_par, output_covar, output_fit_par_error, $
                          internal_radius=internal_radius[i], external_radius=150., chi2=chi2
      
      print,"max = ", output_fit_par[1], ", fwhm = ", sqrt( output_fit_par[2]*output_fit_par[3])/!fwhm2sigma, ", chi2 = ", chi2
            
   endfor
   if png eq 1 then outplot, /close

   stop

   ;; cartes de variance
   ;;-----------------------------------------------------------------------------------------
   wind, 1, 1, xsize = 800, ysize = 650, /free, title='var combo'
   my_multiplot, 2, 2,  pp, pp1, /rev, ymargin=0.08, gap_x=0.08, gap_y=0.08, xmargin = 0.08
   
   if png eq 1 then outplot, file=plot_dir+"/Lobe_varmap_"+strtrim(param.source, 2)+"_v"+strtrim(string(param.version), 2), /png
   
   for i=0, ntags-1 do begin
      print, 'MAP_I'+under[i]+strtrim(tags[i], 2)
      
      wpeak = where(info_tags eq 'RESULT_PEAK_'+strtrim(tags[i],2) )
      a_peak = info_tot.(wpeak)
      
      wmap = where(grid_tags eq 'MAP_I'+under[i]+strtrim(tags[i], 2), nw)
      map = grid_tot.(wmap)/a_peak
      wvar = where(grid_tags eq 'MAP_VAR_I'+under[i]+strtrim(tags[i], 2), nw)
      var = grid_tot.(wvar)/a_peak^2
      w = where( var gt 0, nw, compl=wcompl, ncompl=nwcompl)
      var_med = median( var[w])
      imrange = [-1,1]*stddev( map[where( var le var_med and var gt 0)])
      imrange = 0
      
      ;; Define the gaussian convolution kernel for output convolved maps
      input_sigma_beam = smooth[i]*!fwhm2sigma
      nx_beam_w8       = 2*long(4*input_sigma_beam/reso/2)+1
      ny_beam_w8       = 2*long(4*input_sigma_beam/reso/2)+1
      xx               = dblarr(nx_beam_w8, ny_beam_w8)
      yy               = dblarr(nx_beam_w8, ny_beam_w8)
      for ii=0, nx_beam_w8-1 do xx[ii,*] = (ii-nx_beam_w8/2)*reso
      for ii=0, ny_beam_w8-1 do yy[*,ii] = (ii-ny_beam_w8/2)*reso
      beam_w8 = exp(-(xx^2+yy^2)/(2.*input_sigma_beam^2))
      beam_w8 = beam_w8/total(beam_w8)
      map     = convol( map, beam_w8)
      
      imview, var, xmap=xmap, ymap=ymap, position= pp1[i, *], $
              /noerase, imrange=imrange, title=titles[i], charsize=0.8, charbar=0.7, $
              xtitle='az', ytitle='el', coltable=39
   endfor

    
   if png eq 1 then outplot, /close
   stop
endif






;;
;;  PLOT DES SCANS INDIVIDUELS
;;________________________________________________________________________________________________
calib_dir = !nika.pipeline_dir+'/Calibration/Beam/'

;; lobes_n1r8 = calib_dir+['NIKA_beam_Run8_best1mm.fits','NIKA_beam_Run8_best2mm.fits']
;; ff = mrdfits(lobes_n1r8[0], 1)
;; rad  = ff.angular_radius
;; beam = ff.beam
;; err_beam = ff.err_beam
;; int_rad = ff.integrated_angular_radius
;; solang  = ff.solid_angle
;; err_solang = ff.err_solid_angle

;; ff = mrdfits(lobes_n1r8[0], 2)
;; rad2  = ff.angular_radius
;; beam2 = ff.beam
;; err_beam2 = ff.err_beam
;; int_rad2 = ff.integrated_angular_radius
;; solang2  = ff.solid_angle
;; err_solang2 = ff.err_solid_angle

alpha_flux_cuts = [0.35, 0.35, 0.35, 0.15]
alpha_flux_cuts = [0.33, 0.33, 0.33, 0.09]
alpha_flux_cuts = [0.47, 0.47, 0.34, 0.07]

internal_radius =[8.5d0, 8.5d0, 8.5d0, 13.5d0]

for iscan =0, nscan-1 do begin

   scan = scan_list[iscan]

   print, 'lecture de ', project_dir+'/v_'+strtrim(string(version),2)+'/'+scan+'/results.save'
   restore, project_dir+'/v_'+strtrim(string(version),2)+'/'+scan+'/results.save', /v
   
   tags   = ['1', '3', '1MM', '2']
   under  = ['', '', '_', '']
   titles = ['A1', 'A3', 'A1&A3', 'A2']
   smooth = [3., 3., 3., 5.]
   ran    = [-0.3, -0.3, -0.3, -0.5 ]
   
   ntags = n_elements(tags)
   grid_tags = tag_names( grid1)
   info_tags = tag_names( info1)

   xmap = grid1.xmap
   ymap = grid1.ymap
   
   wind, 1, 1, xsize = 800, ysize = 650, /free, title=scan
   my_multiplot, 2, 2,  pp, pp1, /rev, ymargin=0.08, gap_x=0.08, gap_y=0.08, xmargin = 0.08
   
   reso = param1.map_reso
   
   if png eq 1 then outplot, file=plot_dir+"/Lobe_map_"+strtrim(scan,2)+"_v"+strtrim(string(param1.version),2), /png
   
   for i=0, ntags-1 do begin
      print, 'MAP_I'+under[i]+strtrim(tags[i], 2)

      wpeak = where(info_tags eq 'RESULT_PEAK_'+strtrim(tags[i],2) )
      a_peak = info1.(wpeak)
      
      wmap = where(grid_tags eq 'MAP_I'+under[i]+strtrim(tags[i], 2), nw)
      map = grid1.(wmap)
      map1 = map/a_peak
      wvar = where(grid_tags eq 'MAP_VAR_I'+under[i]+strtrim(tags[i], 2), nw)
      var = grid1.(wvar)
      var1 = var/a_peak^2
      w = where( var1 gt 0, nw, compl=wcompl, ncompl=nwcompl)
      var_med = median( var1[w])
      imrange = [-1,1]*4.*stddev( map[where( var1 le var_med and var1 gt 0)])
      imrange = [-500.*stddev( map1[where( var1 le var_med and var1 gt 0)]), 1d]
      imrange = [-10d, 1d]
                                ;imrange=0
      ;; Define the gaussian convolution kernel for output convolved maps
      input_sigma_beam = smooth[i]*!fwhm2sigma
      nx_beam_w8       = 2*long(4*input_sigma_beam/reso/2)+1
      ny_beam_w8       = 2*long(4*input_sigma_beam/reso/2)+1
      xx               = dblarr(nx_beam_w8, ny_beam_w8)
      yy               = dblarr(nx_beam_w8, ny_beam_w8)
      for ii=0, nx_beam_w8-1 do xx[ii,*] = (ii-nx_beam_w8/2)*reso
      for ii=0, ny_beam_w8-1 do yy[*,ii] = (ii-ny_beam_w8/2)*reso
      beam_w8 = exp(-(xx^2+yy^2)/(2.*input_sigma_beam^2))
      beam_w8 = beam_w8/total(beam_w8)
      map_conv     = convol( map1, beam_w8)
      
      ;;imview, alog(abs(map_conv)), xmap=xmap, ymap=ymap, position= pp1[i, *], $
      ;;        /noerase, imrange=imrange, title=titles[i], charsize=0.8, charbar=0.7, $
      ;;        xtitle='az', ytitle='el', coltable=39

      ;; plot en dB
      d = sqrt(xmap^2 + ymap^2)
      apeak = max(map_conv(where(d lt 40.)))
      map_conv = map_conv/apeak
      map_db = 10.d0*alog(abs(map_conv))/alog(10.d0)
      imrange = [-44., 0.]
      
      ;;
      
      imview, map_db, xmap=xmap, ymap=ymap, position= pp1[i, *], $
              /noerase, imrange=imrange, title=titles[i], charsize=0.9, $
              charbar=0.7, formatbar='(f6.0)', nbvaluebar=4., unitsbar='dB', $
              xtitle='azimuth (arcsec)', ytitle='elevation (arcsec)', coltable=39


      
      wtag = where( strupcase(info_tags) eq "RESULT_OFF_X_"+tags[i], nwtag)
      x0   = info1.(wtag)
      wtag = where( strupcase(info_tags) eq "RESULT_OFF_Y_"+tags[i], nwtag)
      y0   = info1.(wtag)

         
      wtag = where( strupcase(info_tags) eq "RESULT_FLUX_I"+under[i]+tags[i], nwtag)
      flux = info1.(wtag)
                 
         ;; optimized internal radius
         ;;---------------------------------------------------      
         ;; chi2=0
         ;; flux_thresh=0
         ;; internal_radius=0
         ;; fit_main_beam_fwhm, map, var, xmap, ymap, x0, y0, $
         ;;                     output_fit_par, output_covar, output_fit_par_error, $
         ;;                     internal_radius=internal_radius, external_radius=external_radius, $
         ;;                     flux_thresh=flux_thresh, chi2=chi2, $
         ;;                     optimise_radius=1, max_flux=flux
         
         ;; alp = flux_thresh/float(flux)
         
         ;; print,"max = ", output_fit_par[1], ", fwhm = ", sqrt( output_fit_par[2]*output_fit_par[3])/!fwhm2sigma, ", chi2 = ", chi2,  ", internal_radius = ", internal_radius, ", alpha cut = ", alp
         
         
         ;; if i eq 3 then begin
         ;;    d    = sqrt( (xmap-x0)^2 + (ymap-y0)^2)
         ;;    rbg  = 100.
         ;;    alpha_flux_cuts = indgen(51)/100.+0.05
         ;;    ntest = n_elements(alpha_flux_cuts)
         ;;    max = max(map(where(d le 40.)))
         ;;    fit_apeak = dblarr(ntest)
         ;;    fit_fwhm  = dblarr(ntest)
         ;;    fit_chi2  = dblarr(ntest)
         ;;    for ia= 0, ntest-1 do begin
         ;;       alpha_flux_cut = alpha_flux_cuts[ia]
         ;;       wfit = where( (map gt alpha_flux_cut*flux and d le rbg) or (d ge rbg and var lt mean(var)), nwfit, compl=wout)
         ;;       map_var0 = var
         ;;       map_var0[wout] = 0.d0
         ;;       nk_fitmap, map, map_var0, xmap, ymap, output_fit_par, covar, output_fit_par_error, $
         ;;                  educated=educated, k_noise=k_noise, info=info_out, status=status, dmax=dmax, $
         ;;                  xguess=xguess, yguess=yguess, guess_fit_par=guess_fit_par, sigma_guess=input_sigma_beam, map_fit=best_model
         ;;       ww = where(map_var0 gt 0., ndata)
         ;;       chi2 = total((map[ww]-best_model[ww])^2/map_var0[ww])/(ndata-7.)
         ;;       print,"max = ", output_fit_par[1], ", fwhm = ", sqrt( output_fit_par[2]*output_fit_par[3])/!fwhm2sigma, ", chi2 = ", chi2
         ;;       fit_apeak[ia] = output_fit_par[1]
         ;;       fit_fwhm[ia]  = sqrt( output_fit_par[2]*output_fit_par[3])/!fwhm2sigma
         ;;       fit_chi2[ia]  = chi2
         ;;    endfor
         ;; endif
         
         
         ;; fixed internal radius
         ;;---------------------------------------------------
         alpha_flux_cut = alpha_flux_cuts[i]
         flux_threshold = alpha_flux_cut*flux
         
         chi2=1
         ;;fit_main_beam_fwhm, map, var, xmap, ymap, x0, y0, $
         ;;                    output_fit_par, output_covar, output_fit_par_error, $
         ;;                    flux_thresh=flux_threshold, external_radius=100., chi2=chi2

         fit_main_beam_fwhm, map, var, xmap, ymap, x0, y0, $
                             output_fit_par, output_covar, output_fit_par_error, $
                             internal_radius=internal_radius[i], external_radius=100., chi2=chi2

         
         print,"max = ", output_fit_par[1], ", fwhm = ", sqrt( output_fit_par[2]*output_fit_par[3])/!fwhm2sigma, ", chi2 = ", chi2
          
   endfor
   
   if png eq 1 then outplot, /close


   if plot_variance gt 0 then begin
      wind, 1, 1, xsize = 800, ysize = 650, /free, title=scan
      my_multiplot, 2, 2,  pp, pp1, /rev, ymargin=0.08, gap_x=0.08, gap_y=0.08, xmargin = 0.08
      
      if png eq 1 then outplot, file=plot_dir+"/Lobe_varmap_"+strtrim(scan,2)+"_v"+strtrim(string(param1.version),2), /png
      
      for i=0, ntags-1 do begin
         print, 'MAP_I'+under[i]+strtrim(tags[i], 2)
         
         wpeak = where(info_tags eq 'RESULT_PEAK_'+strtrim(tags[i],2) )
         a_peak = info1.(wpeak)
         
         wmap = where(grid_tags eq 'MAP_I'+under[i]+strtrim(tags[i], 2), nw)
         map = grid1.(wmap)/a_peak
         wvar = where(grid_tags eq 'MAP_VAR_I'+under[i]+strtrim(tags[i], 2), nw)
         var = grid1.(wvar)/a_peak^2
         w = where( var gt 0, nw, compl=wcompl, ncompl=nwcompl)
         var_med = median( var[w])
         imrange = [-1,1]*stddev( map[where( var le var_med and var gt 0)])
         imrange=0
         
         ;; Define the gaussian convolution kernel for output convolved maps
         input_sigma_beam = smooth[i]*!fwhm2sigma
         nx_beam_w8       = 2*long(4*input_sigma_beam/reso/2)+1
         ny_beam_w8       = 2*long(4*input_sigma_beam/reso/2)+1
         xx               = dblarr(nx_beam_w8, ny_beam_w8)
         yy               = dblarr(nx_beam_w8, ny_beam_w8)
         for ii=0, nx_beam_w8-1 do xx[ii,*] = (ii-nx_beam_w8/2)*reso
         for ii=0, ny_beam_w8-1 do yy[*,ii] = (ii-ny_beam_w8/2)*reso
         beam_w8 = exp(-(xx^2+yy^2)/(2.*input_sigma_beam^2))
         beam_w8 = beam_w8/total(beam_w8)
         map     = convol( map, beam_w8)
         
         imview, var, xmap=xmap, ymap=ymap, position= pp1[i, *], $
                 /noerase, imrange=imrange, title=titles[i], charsize=0.8, charbar=0.7, $
                 xtitle='az', ytitle='el', coltable=39
      endfor
      
      if png eq 1 then outplot, /close
   endif
   
   if ps gt 0 then begin
      ps_root = plot_dir+"/Lobe_"+strtrim(scan,2)+"_map_"
      for i=0, ntags-1 do begin
         ps_file = ps_root+strtrim(tags[i], 2)+'.ps'
         
         print, 'MAP_I'+strtrim(tags[i], 2)
         wmap = where(grid_tags eq 'MAP_I'+under[i]+strtrim(tags[i], 2), nw)
         map = grid1.(wmap)
         wvar = where(grid_tags eq 'MAP_VAR_I'+under[i]+strtrim(tags[i], 2), nw)
         var = grid1.(wvar)
         w = where( var gt 0, nw, compl=wcompl, ncompl=nwcompl)
         var_med = median( var[w])
         imrange = [-1,1]*4.*stddev( map[where( var le var_med and var gt 0)])
         imrange = [1.-7, 2.]
                                ;imrange=0
         ;; Define the gaussian convolution kernel for output convolved maps
         input_sigma_beam = smooth[i]*!fwhm2sigma
         nx_beam_w8       = 2*long(4*input_sigma_beam/reso/2)+1
         ny_beam_w8       = 2*long(4*input_sigma_beam/reso/2)+1
         xx               = dblarr(nx_beam_w8, ny_beam_w8)
         yy               = dblarr(nx_beam_w8, ny_beam_w8)
         for ii=0, nx_beam_w8-1 do xx[ii,*] = (ii-nx_beam_w8/2)*reso
         for ii=0, ny_beam_w8-1 do yy[*,ii] = (ii-ny_beam_w8/2)*reso
         beam_w8 = exp(-(xx^2+yy^2)/(2.*input_sigma_beam^2))
         beam_w8 = beam_w8/total(beam_w8)
         map     = convol( map, beam_w8)
         
         imview, alog(abs(map)), xmap=xmap, ymap=ymap, position= pp1[i, *], $
                 /noerase, imrange=imrange, title=titles[i], charsize=0.8, charbar=0.7, xtitle='az', ytitle='el', postscript=ps_file
      endfor
                                ;close_imview
   endif
   
   ;;stop
   
endfor

stop

;spawn, 'cp '+project_dir+'/v_1/'+scan+'/results.save '+calib_dir+'NIKA2_Lobes_v0.save'


end
