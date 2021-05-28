pro get_beam_parameters, input_map_file, output_profile_file, $
                         do_main_beam=do_main_beam, optimized_internal_radius=optimized_internal_radius, $
                         do_profile=do_profile, delta_radius=delta_radius, do_florian_fit=do_florian_fit

  

  grid1 = 0B
  info1 = 0B
  grid_tot = 0B
  info_tot = 0B
  
  print, 'lecture de ',input_map_file
  restore, input_map_file, /v
  
  res = isa(grid1, /array)
  if res gt 0 then grid_tot=grid1
  res = isa(info1, /array)
  if res gt 0 then info_tot=info1
  res = isa(param1, /array)
  if res gt 0 then param=param1
  
  tags   = ['1', '3', '1MM', '2']
  under  = ['', '', '_', '']
  titles = ['A1', 'A3', 'A1&A3', 'A2']
  smooth = [3., 3., 3., 5.]
  ran    = [-0.3, -0.3, -0.3, -0.5 ]

  fwhm_nomi = [!nika.fwhm_nom[0], !nika.fwhm_nom[0],!nika.fwhm_nom[0],!nika.fwhm_nom[1]]
  
  ntags = n_elements(tags)
  grid_tags = tag_names( grid_tot)
  info_tags = tag_names( info_tot)
  
  xmap = grid_tot.xmap
  ymap = grid_tot.ymap
  
  reso = param.map_reso
  
  fix_fwhm_amplitude = dblarr(4)
  fwhm_x             = dblarr(4)
  fwhm_y             = dblarr(4)
  fwhm               = dblarr(4)
  amplitude          = dblarr(4)
  ;; p[0] : const, p[1] : max
  ;; p[2], p[3] = sig_x, sig_y
  ;; p[4], p[5] = x0, y0
  ;; p[6] : angle
  mainbeam_param           = dblarr(7,  4)
  mainbeam_param_error     = dblarr(7,  4)
  mainbeam_covar           = dblarr(49, 4)
  mainbeam_chi2            = dblarr(4) 
  mainbeam_internal_radius = dblarr(4)
  mainbeam_fraction_flux   = dblarr(4)


  if keyword_set(delta_radius) then begin
     taille_carte = max(sqrt(xmap^2 + ymap^2)/reso)
     nbin = ceil(taille_carte/delta_radius)
  endif else nbin = 225. ;; 100.
  measured_profile_radius  = dblarr(nbin, 4)
  measured_profile         = dblarr(nbin, 4)
  measured_profile_error   = dblarr(nbin, 4)
  threeG_param             = dblarr(7,  4)
  threeG_param_error       = dblarr(7,  4)
  threeG_param_covar       = dblarr(49, 4)
  threeG_chi2              = dblarr(4)
  threeG_param_2           = dblarr(7,  4)
  
  external_radius = 100.
  ;;alpha_flux_cuts = [0.4, 0.4, 0.4, 0.15]
  ;;alpha_flux_cuts = [0.5, 0.5, 0.5, 0.5]
  alpha_flux_cuts = [0.4, 0.4, 0.4, 0.25]
  ;;alpha_flux_cuts = [0.6, 0.6, 0.6, 0.35]
  ;;internal_radii  = [8.5, 8.5, 8.5, 13.5]
  ;;internal_radius_intervals = [2., 2., 2., 4.]
  ;; 2019
  internal_radii  = [8., 8., 8., 16.]
  internal_radius_intervals = [0.25, 0.25, 0.25, 0.25]

  
  ;; limit of the range of threshold flux fraction to be explored 
                                ;min_frac_flux_cuts = [0.1, 0.1, 0.1, 0.01]
                                ;max_frac_flux_cuts = [0.7, 0.7, 0.7, 0.50]
  
  min_frac_flux_cuts = [0.08,  0.08,  0.08,  0.01]
  max_frac_flux_cuts = [0.45, 0.45, 0.45, 0.50]
      
  for itag=0, ntags-1 do begin
     
     ;; read inputs 
     print, 'MAP_I'+under[itag]+strtrim(tags[itag], 2)
     
     wpeak = where(info_tags eq 'RESULT_PEAK_'+strtrim(tags[itag],2) )
     a_peak = info_tot.(wpeak)
     print, "A_peak = ", a_peak
     
     amplitude[itag] = a_peak
     wx = where(info_tags eq 'RESULT_FWHM_X_'+strtrim(tags[itag],2) )
     fwhm_x[itag] = info_tot.(wx)
     wy = where(info_tags eq 'RESULT_FWHM_Y_'+strtrim(tags[itag],2) )
     fwhm_y[itag] = info_tot.(wy)
     w = where(info_tags eq 'RESULT_FWHM_'+strtrim(tags[itag],2) )
     fwhm[itag] = info_tot.(w)
     ;;fwhm[itag]   = sqrt(fwhm_x[itag]*fwhm_y[itag])
     wf = where(info_tags eq 'RESULT_FLUX_I'+under[itag]+strtrim(tags[itag],2), nwf )
     fix_fwhm_amplitude[itag] = info_tot.(wf)
     
     wmap = where(grid_tags eq 'MAP_I'+under[itag]+strtrim(tags[itag], 2), nw)
     map = grid_tot.(wmap)
     wvar = where(grid_tags eq 'MAP_VAR_I'+under[itag]+strtrim(tags[itag], 2), nw)
     var = grid_tot.(wvar)
     
     ;; fit profile
     wtag = where( strupcase(info_tags) eq "RESULT_OFF_X_"+tags[itag], nwtag)
     x0   = info_tot.(wtag)
     wtag = where( strupcase(info_tags) eq "RESULT_OFF_Y_"+tags[itag], nwtag)
     y0   = info_tot.(wtag)
     
     ;; fit FWHM main beam
     ;;-----------------------------------------------------------------------------------
     if do_main_beam gt 0 then begin
        
        print,''
        print,'  Main Beam '
        print,''
        print,"-------------------------------------------"
   
        wtag = where( strupcase(info_tags) eq "RESULT_FLUX_I"+under[itag]+tags[itag], nwtag)
        flux = info_tot.(wtag)
        
        ;; optimized internal radius
        ;;---------------------------------------------------
        if optimized_internal_radius gt 0 then begin
           chi2=0
           flux_threshold=0
           internal_radius=0
           
           fit_main_beam_fwhm, map, var, xmap, ymap, x0, y0, $
                               output_fit_par, output_covar, output_fit_par_error, $
                               internal_radius=internal_radius, external_radius=external_radius, $
                               flux_thresh=flux_threshold, chi2=chi2, $
                               optimise_radius=1, max_flux=flux, $
                               min_internal_radius= internal_radii[itag]- internal_radius_intervals[itag], $
                               max_internal_radius= internal_radii[itag]+ internal_radius_intervals[itag];, $
                               ;k_noise=0.02                 
           
           alp = flux_threshold/float(flux)
           print,"max = ", output_fit_par[1], ", fwhm = ", sqrt( output_fit_par[2]*output_fit_par[3])/!fwhm2sigma, ", chi2 = ", chi2,  ", internal_radius = ", internal_radius, ", alpha cut = ", alp
           print,"errmax = ", output_fit_par_error[1], ", err fwhm_X = ", output_fit_par_error[2]/!fwhm2sigma, ", err fwhm_y = ", output_fit_par_error[3]/!fwhm2sigma
           ;; propagating error on FWHM
           ;; 1) no covar
           err_fwhm1 = (output_fit_par[3]*output_fit_par_error[2]+output_fit_par[2]*output_fit_par_error[3])/(2.d0*sqrt(output_fit_par[2]*output_fit_par[3]))/!fwhm2sigma
           ;; 2) using covar
           aa = [0.d0, 0.D0, output_fit_par[3]/(2.d0*sqrt(output_fit_par[2]*output_fit_par[3])), $
                 output_fit_par[2]/(2.d0*sqrt(output_fit_par[2]*output_fit_par[3])), $
                 0.d0, 0.D0, 0.D0]/!fwhm2sigma
           var_fwhm = aa#output_covar#aa
           err_fwhm2 = sqrt(var_fwhm)
           
           print,"sig(FWHM) = ", err_fwhm1, err_fwhm2
           
        endif else begin
           
           ;; fixed internal radius
           ;;---------------------------------------------------
           ;;alpha_flux_cut = alpha_flux_cuts[itag]
               ;;flux_threshold = alpha_flux_cut*flux
           ;;internal_radius = 0
           internal_radius = internal_radii[itag]
           flux_threshold = 0
           
           chi2=0
           fit_main_beam_fwhm, map, var, xmap, ymap, x0, y0, $
                               output_fit_par, output_covar, output_fit_par_error, $
                               flux_thresh=flux_threshold, internal_radius=internal_radius, $
                               external_radius=external_radius, chi2=chi2
           
           print,"max = ", output_fit_par[1], ", fwhm = ", sqrt( output_fit_par[2]*output_fit_par[3])/!fwhm2sigma, ", chi2 = ", chi2
           ;; propagating error on FWHM
           ;; 1) no covar
           err_fwhm1 = (output_fit_par[3]*output_fit_par_error[2]+output_fit_par[2]*output_fit_par_error[3])/(2.d0*sqrt(output_fit_par[2]*output_fit_par[3]))/!fwhm2sigma
           ;; 2) using covar
           aa = [0.d0, 0.D0, output_fit_par[3]/(2.d0*sqrt(output_fit_par[2]*output_fit_par[3])), $
                 output_fit_par[2]/(2.d0*sqrt(output_fit_par[2]*output_fit_par[3])), $
                 0.d0, 0.D0, 0.D0]/!fwhm2sigma
           var_fwhm = aa#output_covar#aa
           err_fwhm2 = sqrt(var_fwhm)
           
           print,"sig(FWHM) = ", err_fwhm1, err_fwhm2
           
        endelse
        
        mainbeam_param[*, itag]        = output_fit_par
        mainbeam_param_error[*, itag]  = output_fit_par_error
        mainbeam_covar[*, itag]        = reform(output_covar, 49)
        mainbeam_chi2[itag]            = chi2
        mainbeam_internal_radius[itag] = internal_radius 
        mainbeam_fraction_flux[itag]   = flux_threshold
            
     endif ;; fit main beam
     
     
     ;; 3-Gaussian profile
     if do_profile gt 0 then begin

        print,''
        print,'  3G Profiles '
        print,''
        print,"-------------------------------------------"
           
        ;stop
        
        center = [x0, y0]
        if do_main_beam gt 0 then guess_fwhm = sqrt( mainbeam_param[2, itag]*mainbeam_param[3, itag])/!fwhm2sigma else $
           guess_fwhm = 11.
        ;;input_par = [flux*0.95, 0.01, 1d-3, fwhm_nomi[itag], 30., 100., 0.]
        input_par = [flux*0.95, 0.01, 1d-3, guess_fwhm, 30., 100., 0.]
        
        par     = 1
        par_err = 1
        covar   = 1
        chisq   = 1
        beam_profile_3gauss, reso, center, map, var, nbin, output_profile_str, par, par_err, covar, chisq, input_par=input_par, chatty=1
        
        measured_profile_radius[*, itag]      = output_profile_str.r
        measured_profile[*, itag]             = output_profile_str.y
        var_prof = output_profile_str.var
        measured_profile_error[*, itag]       = sqrt(var_prof)
        
        threeG_param[*, itag]       = par
        threeG_param_error[*, itag] = par_err
        threeG_param_covar[*, itag] = reform(covar, 49)
        threeG_chi2[itag]           = chisq

        if do_florian_fit then begin
        ;; comparaison avec methode Florian
        ;;.r  /home/perotto/NIKA/Processing/Labtools/FR/Beam/fit_gaussian_beam.pro
           fit_gaussian_beam, map, reso, p2, yfit=yfit, center = center
           threeG_param_2[*, itag]       = p2
        endif
           
     endif
     
  endfor ;; loop over tags
  
  print, "saving ", output_profile_file
  save, fix_fwhm_amplitude, fwhm_x, fwhm_y, fwhm, amplitude, $
        measured_profile_radius,  measured_profile, measured_profile_error, $
        threeG_param, threeG_param_error, threeG_param_covar, threeG_chi2, threeG_param_2, $
        mainbeam_param, mainbeam_param_error, mainbeam_covar, mainbeam_chi2, $
        mainbeam_internal_radius, mainbeam_fraction_flux, filename=output_profile_file
  
  
  
  
end
