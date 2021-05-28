;;
;;
;;
;;    Fit de modele de profile sur la carte de lobe de la Sect. Full Beam pattern
;;
;;    voir production de la carte dans comresult_beammap.pro
;;
;;________________________________________________________________________


;;.r  /home/perotto/NIKA/Processing/Labtools/FR/Beam/fit_gaussian_beam.pro

project_dir  = '/home/perotto/NIKA/Plots/Lobes'
plot_dir     = project_dir+'/Plots/'
png          = 0
ps           = 0

launch_nk    = 0

;; decor method
version      = 2 ;; "CM_ONE_BLOCK"
version      = 3 ;; "CM_ONE_BLOCK" + calib 'NewConv'
;;version      = 4 ;; "CM_KIDS_OUT" + calib 'NewConv'

;; N2R12
project_dir  = '/home/perotto/NIKA/Plots/N2R12/Profiles'
plot_dir     = project_dir+'/Plots/'
png          = 1
ps           = 0

launch_nk    = 0

;; decor method
;;version      = 2 ;; "CM_ONE_BLOCK"
version      = 1 ;; "CM_KIDS_OUT"


;; input_map_files (IN) and profile_fit_files (OUT)
;;---------------------------------------------------------------------------------------------

;; 1./  best file
scan_list = ['20170125s243']
input_map_files = project_dir+'/v_'+strtrim(string(version),2)+'/'+scan_list+'/results.save'
profile_fit_files = project_dir+'/v_'+strtrim(string(version),2)+'/Fit_'+scan_list+'_v2.save'

;; 2. / best scans of Uranus
;; scan_list = ['20170125s223', '20170125s243']
;; input_map_files   = project_dir+'/v_'+strtrim(string(version),2)+'/Combi_Uranus_results.save'
;; profile_fit_files = project_dir+'/v_'+strtrim(string(version),2)+'/Fit_combi_Uranus_results.save'
;; input_map_files   = project_dir+'/v_'+strtrim(string(version),2)+'/Combi_Uranus_results_recal.save'
;; profile_fit_files = project_dir+'/v_'+strtrim(string(version),2)+'/Fit_combi_Uranus_results_recal.save'

;; 3./ best 4 files
;;scan_list   = ['20170125s223', '20170125s243', '20170224s177', '20170226s415']
;;source_list = ['Uranus', 'Uranus', 'Neptune', '3C84']

;;input_map_files   = project_dir+'/v_'+strtrim(string(version),2)+'/Combi_all_results_recal.save'
;;profile_fit_files =
;;project_dir+'/v_'+strtrim(string(version),2)+'/Fit_combi_all_results_recal.save'

;; other individual scans (already processed)
;scan_list = ['20170125s223', '20170224s177', '20170226s415']
;input_map_files = project_dir+'/v_'+strtrim(string(version),2)+'/'+scan_list+'/results.save'
;profile_fit_files = project_dir+'/v_'+strtrim(string(version),2)+'/Fit_'+scan_list+'_v2.save'


;; 4./  all files
n2r9_best_4files = !nika.off_proc_dir+['/kidpar_20170224s177_v2_cm_one_block_FR.fits',$
                                       '/kidpar_20170226s415_v2_skd1_LP.fits', $
                                       '/kidpar_20170226s425_v2_skd1_LP.fits', $
                                       '/kidpar_20170227s84_v2_JFMP.fits']
n2r10_best_4files = !nika.off_proc_dir+"/"+["kidpar_20170419s133_v2_cm_one_block_LP_calib.fits", $
                                            "kidpar_20170420s113_JFMP_v2_cm_one_block_LP_calib.fits",$
                                            "kidpar_20170424s116_v2.fits", $
                                            "kidpar_20170424s123_v2_cm_one_block_LP_calib.fits"]
;; n2r9
scan_list = ['20170226s425', '20170227s84']
source_list = ['3C84', '3C273']
input_kidpar_file = !nika.off_proc_dir+'/kidpar_best3files_FXDC0C1_GaussPhot.fits'
input_map_files = project_dir+'/v_'+strtrim(string(version),2)+'/'+scan_list+'/results.save'
profile_fit_files = project_dir+'/v_'+strtrim(string(version),2)+'/Fit_'+scan_list+'_v2.save'


;; n2r10
;; nb : reanalyser '20170224s177' avec Newconv
;; scan_list = ['20170419s133', '20170420s113', '20170424s116', '20170424s123']
;; input_kidpar_file = !nika.off_proc_dir+"/avg_kidpar_run10_BC_recal.fits"
;; input_map_files = project_dir+'/v_'+strtrim(string(version),2)+'/'+scan_list+'/results.save'
;; profile_fit_files = project_dir+'/v_'+strtrim(string(version),2)+'/Fit_'+scan_list+'_v2.save'

;; Reanalyse '20170224s177' avec Newconv
;; scan_list = ['20170224s177']
;; input_kidpar_file = !nika.off_proc_dir+"/kidpar_best3files_FXDC0C1_GaussPhot_NewConv.fits"
;; input_map_files = project_dir+'/v_'+strtrim(string(version),2)+'/'+scan_list+'/results.save'
;; profile_fit_files = project_dir+'/v_'+strtrim(string(version),2)+'/Fit_'+scan_list+'_v2.save'


;; all Neptune
;; r_in in [8, 9] @ 1mm & r_in in [10, 14] @ 2mm
scan_list = ['20170424s123', '20170224s177', '20170419s133', '20170420s113', '20170424s116']
input_map_files = project_dir+'/v_'+strtrim(string(version),2)+'/'+scan_list+'/results.save'
;;profile_fit_files = project_dir+'/v_'+strtrim(string(version),2)+'/Fit_'+scan_list+'_v2.save'
;;profile_fit_files = project_dir+'/v_'+strtrim(string(version),2)+'/Fit_'+scan_list+'_fixed_rin.save'
profile_fit_files = project_dir+'/v_'+strtrim(string(version),2)+'/Fit_'+scan_list+'_fixed_rin_interval.save'

;; all but N2R10
scan_list = ['20170125s243', '20170224s177', '20170226s415', '20170226s425', '20170227s84']
version   = [2, 3, 2, 4, 4]
suf       = '_'+['v2', 'fixed_rin_interval','v2', 'v2', 'v2']
input_map_files = project_dir+'/v_'+strtrim(string(version),2)+'/'+scan_list+'/results.save'
profile_fit_files = project_dir+'/v_'+strtrim(string(version),2)+'/Fit_'+scan_list+suf+'.save'

;; all 
;; scan_list = ['20170125s243', '20170224s177', '20170226s415', '20170226s425', '20170227s84', '20170419s133', '20170420s113', '20170424s116', '20170424s123']
;; version   = [2, 3, 2, 4, 4, 3, 3, 3, 3]
;; suf       = '_'+['v2', 'fixed_rin_interval','v2', 'v2', 'v2', 'fixed_rin_interval', 'fixed_rin_interval', 'fixed_rin_interval', 'fixed_rin_interval']
;; input_map_files = project_dir+'/v_'+strtrim(string(version),2)+'/'+scan_list+'/results.save'
;; profile_fit_files = project_dir+'/v_'+strtrim(string(version),2)+'/Fit_'+scan_list+suf+'.save'


;; all
;; r_in in [6.5, 10.5] @ 1mm & r_in in [9.5, 17.5] @ 2mm
scan_list = ['20170125s243', '20170224s177', '20170226s415', '20170226s425', '20170227s84', '20170419s133', '20170420s113', '20170424s116', '20170424s123']
version   = [2, 3, 2, 4, 4,  3, 3, 3, 3]
suf       = strarr(9)
for i=0,8 do suf[i]='_'+['fixed_rin_interval_2']
input_map_files = project_dir+'/v_'+strtrim(string(version),2)+'/'+scan_list+'/results.save'
profile_fit_files = project_dir+'/v_'+strtrim(string(version),2)+'/Fit_'+scan_list+suf+'.save'


;; N2R12
scan_list = ['20170125s243', '20171025s41']
scan_list = ['20171022s158', '20171023s101', '20171024s105', '20171025s41', '20171025s42', '20171027s49', '20171028s310', '20171029s266']
;;scan_list = ['20171025s42']
version   = 1
input_map_files = project_dir+'/v_'+strtrim(string(version),2)+'/'+scan_list+'/results.save'
profile_fit_files = project_dir+'/v_'+strtrim(string(version),2)+'/Fit_'+scan_list+'.save'

;;input_map_files = project_dir+'/v_'+strtrim(string(version),2)+'/Lobes_N2R12_Combi_Mars.save'
;;profile_fit_files = project_dir+'/v_'+strtrim(string(version),2)+'/Fit_n2r12_combi_mars.save'


;; N2R12 test epaulement sur A2
scan_list = replicate('20171025s41', 4)
version   = [5, 6, 7, 8]
input_map_files = project_dir+'/v_'+strtrim(string(version),2)+'/'+scan_list+'/results.save'
profile_fit_files = project_dir+'/v_'+strtrim(string(version),2)+'/Fit_'+scan_list+'.save'






;; fits (if profile_fit_file not already exists)
;;---------------------------------------------------

;; force repeating the fit
redo_fit = 0

;; fit the main beam FWHM
do_main_beam = 1
optimized_internal_radius = 0

;; fit a 3-Gaussian profile
do_profile = 1

;; plots
;;--------------------------------------------------
;; plot profile per beammap
do_plot_permap = 1

;; plot superimposed profile of all the scans
do_plot_allscans = 1
normalise        = 1
plot_suffixe='_mixed'
plot_suffixe='_v1_n2r8_vs_12'
plot_suffixe='_n2r12'
plot_suffixe='_n2r12_epaule'

;; stat on profile models
;do_stats = 0
;normalise        = 0
;plot_suffixe='_uranus'
;normalise        = 1
;plot_suffixe='_mixed'

;; beam etendue
do_etendue = 0
radius_maximum = 150.0d0        ; arcsec

;;_______________________________________________________________________________________
;;_______________________________________________________________________________________
;;_______________________________________________________________________________________

nscan = n_elements(input_map_files)

if launch_nk gt 0 then begin

   print,"============================================="
   print,''
   print,'  MAP PRODUCTION '
   print,''
   print,"============================================="
   
   if nscan gt 1 then begin
      split_for, 0, nscan-1, nsplit=nscan, $
                 commands=['nk_lobes_sub, i, scan_list, input_kidpar_file=input_kidpar_file, project_dir=project_dir, version=version'], $
                 varnames = ['scan_list', 'input_kidpar_file', 'project_dir', 'version']
   endif else begin
     
      scan = scan_list[0]
      
      
      nk_default_param, param
      param.force_kidpar   = 1
      param.file_kidpar    = input_kidpar_file
      param.decor_cm_dmin  = 100.
      param.output_noise   = 1
      param.do_opacity_correction = 1
      
      if (version eq 2 or version eq 3) then param.decor_method   = "COMMON_MODE_ONE_BLOCK"
      param.version        = version
      
      param.map_reso       = 1.d0
      param.map_xsize      = 600d0
      param.map_ysize      = 600d0
      param.map_proj       = 'azel'
      param.map_smooth_1mm = 0
      param.map_smooth_2mm = 0
      
      param.plot_dir       = project_dir
      param.project_dir    = project_dir

      nk, scan, param=param
      
   endelse
   
endif


;;    profile fitting
;;_______________________________________________________________________________________
for iscan =0, nscan-1 do begin
   
   print,"============================================="
   print,''
   print,'  PROFILE FITTING '
   print,''
   print,"============================================="
   
   outfile = profile_fit_files[iscan]
   
   if (file_test(outfile) lt 1 or redo_fit gt 0) then begin
      
      get_beam_parameters, input_map_files[iscan], outfile, $
                           do_main_beam=do_main_beam, optimized_internal_radius=0, $
                           do_profile=do_profile, do_florian_fit=1
      
      
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
      
      ntags = n_elements(tags)
      grid_tags = tag_names( grid_tot)
      info_tags = tag_names( info_tot)
      
      xmap = grid_tot.xmap
      ymap = grid_tot.ymap
      
      
      reso = param.map_reso
      
      ;;alpha_flux_cuts = [0.4, 0.4, 0.4, 0.15]
      ;;alpha_flux_cuts = [0.5, 0.5, 0.5, 0.5]
      alpha_flux_cuts = [0.4, 0.4, 0.4, 0.25]
      ;;alpha_flux_cuts = [0.6, 0.6, 0.6, 0.35]
      
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
      
      nbin = 100.
      measured_profile_radius  = dblarr(nbin, 4)
      measured_profile         = dblarr(nbin, 4)
      measured_profile_error   = dblarr(nbin, 4)
      threeG_param             = dblarr(7,  4)
      threeG_param_error       = dblarr(7,  4)
      threeG_param_covar       = dblarr(49, 4)
      threeG_chi2              = dblarr(4)
      threeG_param_2           = dblarr(7,  4)
      
      external_radius = 100.
      ;;internal_radii  = [8.5, 8.5, 8.5, 12.]
      ;;internal_radius_intervals = [1., 1., 1., 2.]
      
      internal_radii  = [8.5, 8.5, 8.5, 13.5]
      internal_radius_intervals = [2., 2., 2., 4.]
      
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
               ;; fit_main_beam_fwhm, map, var, xmap, ymap, x0, y0, $
               ;;                     output_fit_par, output_covar, output_fit_par_error, $
               ;;                     internal_radius=internal_radius, external_radius=external_radius, $
               ;;                     flux_thresh=flux_threshold, chi2=chi2, $
               ;;                     optimise_radius=1, max_flux=flux, $
               ;;                     min_frac_flux_cut=min_frac_flux_cuts[itag], $
               ;;                     max_frac_flux_cut=max_frac_flux_cuts[itag], $
               ;;                     k_noise=0.02
               fit_main_beam_fwhm, map, var, xmap, ymap, x0, y0, $
                                   output_fit_par, output_covar, output_fit_par_error, $
                                   internal_radius=internal_radius, external_radius=external_radius, $
                                   flux_thresh=flux_threshold, chi2=chi2, $
                                   optimise_radius=1, max_flux=flux, $
                                   min_internal_radius= internal_radii[itag]- internal_radius_intervals[itag], $
                                   max_internal_radius= internal_radii[itag]+ internal_radius_intervals[itag], $
                                   k_noise=0.02                 
               
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
           
            center = [x0, y0]
            if do_main_beam gt 0 then fwhm = sqrt( mainbeam_param[2, itag]*mainbeam_param[3, itag])/!fwhm2sigma else $
               fwhm = 11.
            input_par = [flux*0.95, 0.01, 1d-3, fwhm, 30., 100., 0.]
            
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
            
            ;; comparaison avec methode Florian
            ;;.r  /home/perotto/NIKA/Processing/Labtools/FR/Beam/fit_gaussian_beam.pro
            fit_gaussian_beam, map, reso, p2, yfit=yfit, center = center
            threeG_param_2[*, itag]       = p2
            
         endif
         
      endfor ;; loop over tags
      
      print, "saving ", profile_fit_files[iscan]
      save, measured_profile_radius,  measured_profile, measured_profile_error, $
            threeG_param, threeG_param_error, threeG_param_covar, threeG_chi2, threeG_param_2, $
            mainbeam_param, mainbeam_param_error, mainbeam_covar, mainbeam_chi2, $
            mainbeam_internal_radius, mainbeam_fraction_flux, filename=profile_fit_files[iscan]
      
   endif
   
   
   ;;;
   ;;;
   ;;;
   ;;;
   ;;;       plot
   ;;;
   ;;;_____________________________________________________________________


   if do_plot_permap gt 0 then begin
      
      ;;wind, 1, 1, xsize = 800, ysize = 2000, /free
      ;;my_multiplot, 1, 4,  pp, pp1, /rev, ymargin=0.02, gap_x=0, gap_y=0.06, xmargin = 0.17
      ;;charsz = 0.8
      
      
      wind, 1, 1, xsize = 1200, ysize = 700, /free
      my_multiplot, 2, 2,  pp, pp1, /rev, ymargin=0., gap_x=0.1, gap_y=0.1, xmargin = 0.
      charsz = 0.9
      
      if png eq 1 then begin
         if nscan lt 2 then begin
            rootname = rootname(input_map_files[iscan], cutext='.save')
            plot_file = plot_dir+"/Profile_"+strtrim(rootname, 2)+"_v"+strtrim(string(version), 2)
         endif else begin
            plot_file = plot_dir+"/Profile_"+strtrim(scan_list[iscan], 2)+"_v"+strtrim(string(version), 2)
         endelse
         outplot, file=plot_file, /png
      endif
      
      print, "restoring ", profile_fit_files[iscan]
      restore, profile_fit_files[iscan]
      restore, input_map_files[iscan], /v
      info_tags = tag_names( info_tot)
      
      print, ''
      print, '_________________'
      print, ''
      print, scan_list[iscan]
      r0 = lindgen(999)/2.+ 1.
      
      tags   = ['1', '3', '1MM', '2']
      under  = ['', '', '_', '']
      titles = ['A1', 'A3', 'A1&A3', 'A2']
      ntags  = n_elements(tags)
      
      for itag=0, ntags-1 do begin
         
         rad      = measured_profile_radius[*, itag]
         prof     = measured_profile[*, itag]
         proferr  = measured_profile_error[*, itag]
         
         ;;stop
         max = 2.*max(prof)
         min = max-max*(1d0-1d-7) 
         plot, r0, r0, /ylog, /xlog, yr=[min, max], /ys, xr=[1., 500.], /xs, /nodata, $
               ytitle="Flux (Jy/beam)", xtitle="radius (arcsec)", title=titles[itag], pos=pp1[itag,*], /noerase
         oploterror,rad, prof, rad*0., proferr, psym=8, col=80, errcol=80
         
         mb_p   = mainbeam_param[*, itag]
         mb_err = mainbeam_param_error[*, itag]
         oplot, r0, mb_p[1]*exp(-1.*r0^2/2d0/mb_p[2]/mb_p[3]), col=125, thick=3
         
         
         p = threeG_param[*, itag]
         p_err = threeG_param_error[*, itag]
         
         fit_profile = profile_3gauss(r0,p)
         g1 = p[0]*exp(-(r0-p[6])^2/2.0/(p[3]*!fwhm2sigma)^2)
         g2 = p[1]*exp(-(r0-p[6])^2/2.0/(p[4]*!fwhm2sigma)^2)
         g3 = p[2]*exp(-(r0-p[6])^2/2.0/(p[5]*!fwhm2sigma)^2)
         
         ;;oplot, r0, fit_profile, col=250
         ;;oplot, rad, g1, col=0
         ;;oplot, rad, g2, col=0
         ;;oplot, rad, g3, col=0
         
         p2 = threeG_param_2[*, itag]
         
         fit_profile_2 = fit_triple_beam(r0, p2)
         oplot, r0, fit_profile_2, col=0, thick=3
         oplot, r0, fit_profile, col=250, thick=3

         wpeak = where(info_tags eq 'RESULT_PEAK_'+strtrim(tags[itag],2) )
         a_peak = info_tot.(wpeak)
         wflux = where( strupcase(info_tags) eq "RESULT_FLUX_I"+under[itag]+tags[itag], nwtag)
         flux = info_tot.(wflux)
            
         
         print, '****'
         print, titles[itag]
         print, '-------------'
         print, 'fwhm_fix : '
         print, 'APEAK = ', a_peak
         print, 'FLUX  = ', flux
         print, 'Mainbeam : '
         fwhm = sqrt(mb_p[2]*mb_p[3])/!fwhm2sigma
         print, 'AMP   = ', mb_p[1]
         print, 'FWHM  = ', fwhm
         print, 'error = ', (mb_p[2]*mb_err[3] + mb_p[3]*mb_err[2])/2d0/sqrt(mb_p[2]*mb_p[3])/!fwhm2sigma
         print, 'chi2  = ', mainbeam_chi2[itag]
         print, 'internal radius = ', mainbeam_internal_radius[itag]
         print, ' '
         print, '3Gauss : '
         print,  'AMP = ', p[0]+p[1]+p[2]
         print,  'G1: ', 'amp = '+strtrim(string(p[0], format='(f6.2)'),2)+' pm '+strtrim(string(p_err[0], format='(f6.2)'),2)+', fwhm = '+ strtrim(string(p[3], format='(f6.2)'),2)+' pm '+strtrim(string(p_err[3], format='(f6.2)'),2) 
         print,  'G2: ', 'amp = '+strtrim(string(p[1], format='(f6.2)'),2)+' pm '+strtrim(string(p_err[1], format='(f6.2)'),2)+', fwhm = '+ strtrim(string(p[4], format='(f6.2)'),2)+' pm '+strtrim(string(p_err[4], format='(f6.2)'),2)
         print,  'G3: ', 'amp = '+strtrim(string(p[2], format='(f6.2)'),2)+' pm '+strtrim(string(p_err[2], format='(f6.2)'),2)+', fwhm = '+ strtrim(string(p[5], format='(f6.2)'),2)+' pm '+strtrim(string(p_err[5], format='(f6.2)'),2)
         print,  'par 2 : ', p2
         
         text = ['Main Beam FWHM: '+strtrim(string(fwhm, format='(f6.2)'),2)+' arcsec', $
                 'mask internal radius: '+strtrim(string(mainbeam_internal_radius[itag], format='(f6.1)'),2)+' arcsec', $
                 '', $
                 '3Gauss profile amp, fwhm: ', $
                 '  G1 : '+strtrim(string(p[0], format='(f6.2)'),2)+', '+strtrim(string(abs(p[3]), format='(f6.2)'),2),$
                 '  G2 : '+strtrim(string(p[1], format='(f6.2)'),2)+', '+strtrim(string(abs(p[4]), format='(f6.2)'),2),$
                 '  G3 : '+strtrim(string(p[2], format='(f6.2)'),2)+', '+strtrim(string(abs(p[5]), format='(f6.2)'),2)]
         legendastro, text, textcolor=[125, 125, 0, 250, 250, 250, 250], box=0, pos=[25, max(prof)], charsize=charsz
         
         ;;stop

      endfor ;; end loop on TAGS

      if png eq 1 then outplot, /close
      
   endif
   
   ;;stop
   
endfor ;; loop over scans


;;    plots & stats
;;_______________________________________________________________________________________

;; superimpose all the profiles
if do_plot_allscans gt 0 then begin
   
   wind, 1, 1, xsize = 1500, ysize = 800, /free
   my_multiplot, 2, 2,  pp, pp1, /rev, ymargin=0., gap_x=0.1, gap_y=0.1, xmargin = 0.
   charsz = 0.9
      
   if png eq 1 then begin
      plot_file = plot_dir+"/Profile_allscans_v"+strtrim(string(version), 2)+plot_suffixe
      if n_elements(version) gt 1 then plot_file = plot_dir+"/Profile_allscans"+plot_suffixe
      outplot, file=plot_file, /png
   endif

   r0 = lindgen(999)/2.+ 1.
   
   tags   = ['1', '3', '1MM', '2']
   under  = ['', '', '_', '']
   titles = ['A1', 'A3', 'A1&A3', 'A2']
   ntags  = n_elements(tags)

   text      = strarr(nscan)
   tab_color = (indgen(nscan)+1L)*250./nscan 

   tab_rad   = dblarr(100, nscan, 4)
   tab_prof  = dblarr(100, nscan, 4)
   tab_var   = dblarr(100, nscan, 4)
   
   for itag=0, ntags-1 do begin
      
      restore, profile_fit_files[0]
      rad = measured_profile_radius[*, itag]
      
      if normalise gt 0 then begin
         min = 1d-4
         max = 10.
      endif else begin
         prof     = measured_profile[*, itag]
         max = 2.*max(prof)
         min = max-max*(1d0-1d-5) 
      endelse
      
      plot, r0, r0, /ylog, /xlog, yr=[min, max], /ys, xr=[1., 500.], /xs, /nodata, $
            ytitle="Flux (Jy/beam)", xtitle="radius (arcsec)", title=titles[itag], pos=pp1[itag,*], /noerase
      
      decal = alog(rad)/2.
      if normalise gt 0 then decal = 0.
      
      for iscan =0, nscan-1 do begin
         print, "restoring ", profile_fit_files[iscan]
         restore, profile_fit_files[iscan], /v

         ;; ancienne convention
         ;; if scan_list[iscan] eq '20170224s177' then begin
         ;;    file = project_dir+'/v_'+strtrim(string(2),2)+'/Fit_'+scan_list[iscan]+'_v2.save'
         ;;    print, "restoring ",file
         ;;    restore, file
         ;; endif
         
         rad      = measured_profile_radius[*, itag]
         prof     = measured_profile[*, itag]
         proferr  = measured_profile_error[*, itag]
         nr = n_elements(rad)
         
         if normalise gt 0 then begin
            norm = max(prof[0:10])
            prof = prof/norm
            proferr = proferr/norm
         endif
       
         oploterror,rad+iscan*decal, prof, rad*0., proferr, psym=8, col=tab_color[iscan], errcol=tab_color[iscan]
         text[iscan] = strtrim(scan_list[iscan],2)

         tab_rad[ 0:nr-1, iscan, itag] = rad[0:nr-1]
         tab_prof[0:nr-1, iscan, itag] = prof[0:nr-1]
         tab_var[ 0:nr-1, iscan, itag] = proferr[0:nr-1]^2

         
      endfor ;; end SCAN loop 
      if itag eq 0 then legendastro, text, textcolor=tab_color, box=0, charsize=charsz, /right

            
   endfor ;; end TAG loop

   if png eq 1 then outplot, /close

   ;;stop

   ;; combined profile
   wind, 1, 1, xsize = 1500, ysize = 800, /free
   my_multiplot, 2, 2,  pp, pp1, /rev, ymargin=0., gap_x=0.1, gap_y=0.1, xmargin = 0.
   charsz = 0.9
   
   if png eq 1 then begin
      ;;plot_file =
      ;;plot_dir+"/Profile_allscans_over_combined_v"+strtrim(string(version),2)+plot_suffixe
      plot_file = plot_dir+"/Profile_allscans_over_median"+plot_suffixe
      outplot, file=plot_file, /png
   endif

   r0 = lindgen(999)/2.+ 1.
   
   tags   = ['1', '3', '1MM', '2']
   under  = ['', '', '_', '']
   titles = ['A1', 'A3', 'A1&A3', 'A2']
   ntags  = n_elements(tags)

   decal = alog(rad)/3.
   text  = strtrim(scan_list,2)

   if normalise gt 0 then decal = 0.
   
   for itag=0, ntags-1 do begin

      med_rad  = dblarr(100)
      med_prof = dblarr(100)
      med_var  = dblarr(100)
      w8   = dblarr(100)

      med_rad  = median(tab_rad(*, *, itag),dimension=2)
      med_prof = median(tab_prof(*, *, itag),dimension=2)
      med_err  = stddev(tab_prof(*, *, itag),dimension=2)
      
      ;; for iscan =0, nscan-1 do begin
      ;;    w8[*]      = 1d0/tab_var[*, iscan, itag]
      ;;    med_rad[*] += tab_rad[*, iscan, itag]*w8[*]
      ;;    med_prof[*] += tab_prof[*, iscan, itag]*w8[*]
      ;;    med_var  += w8
      ;; endfor
      
      ;; w = where(med_var gt 0)
      ;; med_rad(w)  = med_rad(w)/med_var(w)
      ;; med_prof(w) = med_prof(w)/med_var(w)
      ;; med_var(w)  = 1d0/med_var(w)
      ;; med_err     = sqrt(med_var)

            
      ;; plot, r0, r0, yr=[1d-4, 30], /ys, xr=[1., 500.], /xs, /nodata, /xlog, /ylog, $
      ;;       ytitle="Profile ratio", xtitle="radius (arcsec)", title=titles[itag], pos=pp1[itag,*], /noerase     
      ;; oploterror, med_rad, med_prof, med_rad*0., med_err, psym=8, col=80, errcol=80
      
      plot, r0, r0, yr=[0.3, 1.7], /ys, xr=[1., 100.], /xs, /nodata, /xlog, $
            ytitle="Profile ratio", xtitle="radius (arcsec)", title=titles[itag], pos=pp1[itag,*], /noerase
      
      for iscan =0, nscan-1 do begin
         rad  = tab_rad(*, iscan, itag)
         prof = tab_prof(*, iscan, itag)/med_prof
         err  = sqrt(tab_var(*, iscan, itag))/med_prof
         oploterror, rad+iscan*decal, prof, rad*0., err, psym=8, col=tab_color(iscan), errcol=tab_color(iscan)
      endfor

      oplot, r0, r0*0.+1d, col=0
      if itag eq 0 then legendastro, text, textcolor=tab_color, box=0, charsize=charsz
      
   endfor ;; end TAG loop

   if png eq 1 then outplot, /close

   stop
   
endif ;; plot_all_scans


;;;
;;;
;;;     stats and beam etendue
;;;
;;;_______________________________________________________________________________________________
;; stabilite des parametres des modeles
if do_stats gt 0 then begin
   
   wind, 1, 1, xsize = 1500, ysize = 800, /free
   my_multiplot, 2, 2,  pp, pp1, /rev, ymargin=0., gap_x=0.1, gap_y=0.1, xmargin = 0.
   charsz = 0.9
      
   if png eq 1 then begin
      plot_file = plot_dir+"/Profile_fit_allscans_v"+strtrim(string(version), 2)+plot_suffixe
      if n_elements(version) gt 1 then plot_file = plot_dir+"/Profile_fit_allscans"+plot_suffixe
      outplot, file=plot_file, /png
   endif

   r0 = lindgen(999)/2.+ 1.
   
   tags   = ['1', '3', '1MM', '2']
   under  = ['', '', '_', '']
   titles = ['A1', 'A3', 'A1&A3', 'A2']
   ntags  = n_elements(tags)

   text      = strarr(nscan)
   tab_color = (indgen(nscan)+1L)*250./nscan 

   ;; nparams = 7, ntags = 4
   tab_3g_par  = dblarr(7, nscan, 4)
   tab_3g_err  = dblarr(7, nscan, 4)
   tab_3g_par2 = dblarr(7, nscan, 4)
   tab_mb_par  = dblarr(7, nscan, 4)
   tab_mb_err  = dblarr(7, nscan, 4)
   tab_mb_ir   = dblarr(1, nscan, 4) ;; internal radius
   
   for itag=0, ntags-1 do begin
      
      restore, profile_fit_files[0]
      
      
      if normalise gt 0 then begin
         min = 1d-4
         max = 4.
      endif else begin
         max = 2.*max(mainbeam_param[1, itag])
         min = max-max*(1d0-1d-5) 
      endelse
      
      plot, r0, r0, /ylog, /xlog, yr=[min, max], /ys, xr=[1., 500.], /xs, /nodata, $
            ytitle="Flux (Jy/beam)", xtitle="radius (arcsec)", title=titles[itag], pos=pp1[itag,*], /noerase
      
      for iscan =0, nscan-1 do begin
         print, "restoring ", profile_fit_files[iscan]
         restore, profile_fit_files[iscan], /v

         ;; ancienne convention
         ;; if scan_list[iscan] eq '20170224s177' then begin
         ;;    file = project_dir+'/v_'+strtrim(string(2),2)+'/Fit_'+scan_list[iscan]+'_v2.save'
         ;;    print, "restoring ",file
         ;;    restore, file
         ;; endif

         
         mb_p   = mainbeam_param[*, itag]
         mb_err = mainbeam_param_error[*, itag]

         norm = 1d0
         if normalise gt 0 then norm = mb_p[1]
         
         p = threeG_param[*, itag]
         p_err = threeG_param_error[*, itag]

         ;; 3-Gauss method LP
         fit_profile = profile_3gauss(r0,p)/norm ;; profile from fit params

         ;; 3-Gauss method FR
         p2 = threeG_param_2[*, itag]
         fit_profile_2 = fit_triple_beam(r0, p2)/norm


         oplot, r0, mb_p[1]*exp(-1.*r0^2/2d0/mb_p[2]/mb_p[3])/norm, col=tab_color[iscan], thick=1, linestyle=2
         oplot, r0, fit_profile, col=tab_color[iscan], thick=2


         tab_3g_par[*, iscan, itag]  = p
         tab_3g_err[*, iscan, itag]  = p_err
         tab_3g_par2[*, iscan, itag] = p2
         tab_mb_par[*, iscan, itag]  = mb_p
         tab_mb_err[*, iscan, itag]  = mb_err
         tab_mb_ir[0, iscan, itag]   = mainbeam_internal_radius[itag]

         
         text[iscan] = strtrim(scan_list[iscan],2)

      endfor ;; end SCAN loop 
      if itag eq 0 then legendastro, text, textcolor=tab_color, box=0, charsize=charsz, /right

            
   endfor ;; end TAG loop

   if png eq 1 then outplot, /close

   ;;stop

   ;; combined profile & histograms
   ;;----------------------------------------
   ;; if png eq 1 then begin
   ;;    ;;plot_file =
   ;;    ;;plot_dir+"/Profile_allscans_over_combined_v"+strtrim(string(version),2)+plot_suffixe
   ;;    plot_file = plot_dir+"/Profile_allscans_over_median_v"+plot_suffixe
   ;;    outplot, file=plot_file, /png
   ;; endif
   
   ;; histograms
   params  = ['3Gauss_FWHM_1', '3Gauss_FWHM_2', '3Gauss_FWHM_3', "MainBeam_FWHM", "Mainbeam_ellip", "MainBeam_FWHM_XY"]
   nparams = 7

   tab_xtitle = ["G1-FWHM (arcsec)", "G2-FWHM (arcsec)", "G3-FWHM (arcsec)", "Main Beam FWHM (arcsec)", 'Main Beam ellipticity', '2D Main Beam FWHM (arcsec)']
   
   tab_params = dblarr(nparams, nscan, 4)
   ;; fill in the table

   ;; 1st G FWHM
   tab_params[0, *, *] = tab_3g_par[3, *, *]
   ;; 2nd and 3rd G FWHM
   for itag=0, ntags-1 do begin
      min = abs(min([tab_3g_par[4, *, itag], tab_3g_par[5, *, itag]], dimension=1, /abs))      
      tab_params[1, *, itag] = min
      max = abs(max([tab_3g_par[4, *, itag], tab_3g_par[5, *, itag]], dimension=1, /abs))      
      tab_params[2, *, itag] = max
   endfor

   ;; Main Beam geometrical FWHM
   tab_params[3, *, *] = sqrt(tab_mb_par[2, *, *]*tab_mb_par[3, *, *])/!fwhm2sigma
   ;; Main Beam ellipticity
   for itag=0, ntags-1 do begin
      ga = max([tab_mb_par[2, *, itag], tab_mb_par[3, *, itag]], dimension=1)
      pa = min([tab_mb_par[2, *, itag], tab_mb_par[3, *, itag]], dimension=1)
      tab_params[4, *, itag] = ga/pa
   endfor
   tab_params[5, *, *] = tab_mb_par[2, *, *]/!fwhm2sigma
   tab_params[6, *, *] = tab_mb_par[3, *, *]/!fwhm2sigma
      ;;endfor
   ;;endfor

   
   for ipar=0, nparams-2 do begin

      print, ' '
      print, "----------------"
      print, params[ipar]
      
      wind, 1, 1, xsize = 1000, ysize = 650, /free
      my_multiplot, 2, 2,  pp, pp1, /rev, ymargin=0., gap_x=0.1, gap_y=0.1, xmargin = 0.
      charsz = 0.9
      ps_thick = 1.
      
      if png eq 1 then begin
         plot_file = plot_dir+"/Profile_fit_allscans"+plot_suffixe+"_histogram_"+params
         ;;outplot, file=plot_file, /png
      endif
      r0 = lindgen(999)/2.+ 1.
      
      tags   = ['1', '3', '1MM', '2']
      under  = ['', '', '_', '']
      titles = ['A1', 'A3', 'A1&A3', 'A2']
      ntags  = n_elements(tags)
      
      text  = strtrim(scan_list,2)
      
      for itag=0, ntags-1 do begin
         
         ;; mb_profiles = dblarr(999, nscan)
         ;; g3_profiles = dblarr(999, nscan)
         ;; if normalise gt 0 then begin
         ;;    for i=0, nscan-1 do mb_profiles[*, i] = exp(-1.*r0^2/2d0/tab_mb_par[2, i, itag]/tab_mb_par[3, i, itag])
         ;;    for i=0, nscan-1 do g3_profiles[*, i] = profile_3gauss(r0,tab_3g_par[*, i, itag])/tab_mb_par[1, i, itag]
         ;; endif else begin
         ;;    for i=0, nscan-1 do mb_profiles[*, i] = tab_mb_par[1, i, itag]*exp(-1.*r0^2/2d0/tab_mb_par[2, i, itag]/tab_mb_par[3, i, itag])
         ;;    for i=0, nscan-1 do g3_profiles[*, i] = profile_3gauss(r0,tab_3g_par[*, i, itag])
         ;; endelse
         
         ;; med_mb_prof = median(mb_profiles,dimension=2)
         ;; med_3g_prof = median(g3_profiles,dimension=2)
      
          
         ;; plot, r0, r0, yr=[1d-4, 30], /ys, xr=[1., 500.], /xs, /nodata, /xlog, /ylog, $
         ;;       ytitle="Profile ratio", xtitle="radius (arcsec)", title=titles[itag], pos=pp1[itag,*], /noerase     
         ;; oplot, r0, med_mb_prof, col=80
         ;; oplot, r0, med_3g_prof, col=250
         
         ;; plot, r0, r0, yr=[0.3, 1.7], /ys, xr=[1., 100.], /xs, /nodata, /xlog, $
         ;;       ytitle="Profile ratio", xtitle="radius (arcsec)", title=titles[itag], pos=pp1[itag,*], /noerase
         
         ;; for iscan =0, nscan-1 do begin
         
         ;;    ;oplot, r0, mb_profiles[*, iscan]/med_mb_prof , col=tab_color(iscan)
         ;;    oplot, r0, g3_profiles[*, iscan]/med_3g_prof , col=tab_color(iscan), thick=2
         ;; endfor
         
         ;; oplot, r0, r0*0.+1d, col=0
         ;; if itag eq 0 then legendastro, text, textcolor=tab_color,
         ;; box=0, charsize=charsz

         print, "---> A"+tags[itag]
     
         f = [reform(tab_params[ipar, *, itag])]
         fcol = 80
         if ipar eq 5 then begin
            f = CREATE_STRUCT('h1', dblarr(nscan), 'h2', dblarr(nscan))
            f.h1 = reform(tab_params[5, *, itag])
            f.h2 = reform(tab_params[6, *, itag])
            ;;help, f, /str
            fcol=[200, 80]
         endif
         
         ;;emin = mini[itag]
         ;;emax = maxi[itag]
         ;;bin  = binsi[itag]
         
         np_histo, f, out_xhist, out_yhist, out_gpar, fcol=fcol, fit=0, noerase=1, position=pp1[itag,*], nolegend=1, colorfit=250, thickfit=2*ps_thick, nterms_fit=3, xtitle=tab_xtitle(ipar)

         if ipar lt 7 then begin
            print, mean(f)
            print, median(f)
            print, stddev(f)
         endif else begin
            print, mean(f.(0))
            print, stddev(f.(0))
            print, mean(f.(1))
            print, stddev(f.(1))
         endelse
         print, ' '
            
            
         
      
      endfor ;; end TAG loop

      if png eq 1 then outplot, /close

   endfor ;; end PARAM loop

   wd, /a
   stop
   
endif ;; end do_stats



;;;
;;;
;;;     beam etendue
;;;
;;;_______________________________________________________________________________________________
if do_etendue gt 0 then begin
   
   wind, 1, 1, xsize = 1500, ysize = 800, /free
   my_multiplot, 2, 2,  pp, pp1, /rev, ymargin=0., gap_x=0.1, gap_y=0.1, xmargin = 0.
   charsz = 0.9
      
   if png eq 1 then begin
      plot_file = plot_dir+"/Profile_fit_allscans_v"+strtrim(string(version), 2)+plot_suffixe
      if n_elements(version) gt 1 then plot_file = plot_dir+"/Profile_fit_allscans"+plot_suffixe
      outplot, file=plot_file, /png
   endif

   r0 = lindgen(999)/2.+ 1.
   
   tags   = ['1', '3', '1MM', '2']
   under  = ['', '', '_', '']
   titles = ['A1', 'A3', 'A1&A3', 'A2']
   ntags  = n_elements(tags)

   fwhm_nomi = [!nika.fwhm_nom[0]+dblarr(3), !nika.fwhm_nom[1]]
   
   text      = strarr(nscan)
   tab_color = (indgen(nscan)+1L)*250./nscan 

   ;; nparams = 7, ntags = 4
   tab_3g_par  = dblarr(7, nscan, 4)
   tab_3g_err  = dblarr(7, nscan, 4)
   tab_3g_par2 = dblarr(7, nscan, 4)
   tab_mb_par  = dblarr(7, nscan, 4)
   tab_mb_err  = dblarr(7, nscan, 4)
   tab_mb_ir   = dblarr(1, nscan, 4) ;; internal radius
   
   for itag=0, ntags-1 do begin
      
      restore, profile_fit_files[0]
      
      
      if normalise gt 0 then begin
         min = 1d-4
         max = 4.
      endif else begin
         max = 2.*max(mainbeam_param[1, itag])
         min = max-max*(1d0-1d-5) 
      endelse
      
      plot, r0, r0, /ylog, /xlog, yr=[min, max], /ys, xr=[1., 500.], /xs, /nodata, $
            ytitle="Flux (Jy/beam)", xtitle="radius (arcsec)", title=titles[itag], pos=pp1[itag,*], /noerase
      
      for iscan =0, nscan-1 do begin
         print, "restoring ", profile_fit_files[iscan]
         restore, profile_fit_files[iscan], /v

         ;; ancienne convention
         ;; if scan_list[iscan] eq '20170224s177' then begin
         ;;    file = project_dir+'/v_'+strtrim(string(2),2)+'/Fit_'+scan_list[iscan]+'_v2.save'
         ;;    print, "restoring ",file
         ;;    restore, file
         ;; endif

         
         mb_p   = mainbeam_param[*, itag]
         mb_err = mainbeam_param_error[*, itag]

         norm = 1d0
         if normalise gt 0 then norm = mb_p[1]
         
         p = threeG_param[*, itag]
         p_err = threeG_param_error[*, itag]

         ;; 3-Gauss method LP
         fit_profile = profile_3gauss(r0,p)/norm ;; profile from fit params

         ;; 3-Gauss method FR
         p2 = threeG_param_2[*, itag]
         fit_profile_2 = fit_triple_beam(r0, p2)/norm


         oplot, r0, mb_p[1]*exp(-1.*r0^2/2d0/mb_p[2]/mb_p[3])/norm, col=tab_color[iscan], thick=1, linestyle=2
         oplot, r0, fit_profile, col=tab_color[iscan], thick=2


         tab_3g_par[*, iscan, itag]  = p
         tab_3g_err[*, iscan, itag]  = p_err
         tab_3g_par2[*, iscan, itag] = p2
         tab_mb_par[*, iscan, itag]  = mb_p
         tab_mb_err[*, iscan, itag]  = mb_err
         tab_mb_ir[0, iscan, itag]   = mainbeam_internal_radius[itag]

         
         text[iscan] = strtrim(scan_list[iscan],2)

      endfor ;; end SCAN loop 
      if itag eq 0 then legendastro, text, textcolor=tab_color, box=0, charsize=charsz, /right

            
   endfor ;; end TAG loop

   if png eq 1 then outplot, /close

   ;;stop

   ;; combined profile & histograms
   ;;----------------------------------------
   ;; if png eq 1 then begin
   ;;    ;;plot_file =
   ;;    ;;plot_dir+"/Profile_allscans_over_combined_v"+strtrim(string(version),2)+plot_suffixe
   ;;    plot_file = plot_dir+"/Profile_allscans_over_median_v"+plot_suffixe
   ;;    outplot, file=plot_file, /png
   ;; endif
   
   ;; histograms
   params  = ['method 1', 'method 2', 'method 3', 'method 4', 'method 5', 'scatter']
   nparams = 6

   tab_xtitle = ['3Gaussian Beam Efficiency',  '3Gaussian Beam Efficiency', '3Gaussian Beam Efficiency',  '3Gaussian Beam Efficiency', '3Gaussian Beam Efficiency', '3Gaussian Beam Efficiency']
   
   tab_params = dblarr(nparams, nscan, 4)
   ;; fill in the table

   
   r = lindgen(9999)/10. ;; 0-->16.7 arcmin
   un = dblarr(1201)+1d0
   x  = lindgen(1201)-600.
   xm = x#un 
   ym = transpose(xm)
   d  = sqrt(xm^2 + ym^2) 
   
   for iscan=0, nscan-1 do begin
      restore, input_map_files(iscan)
      grid_tags = tag_names( grid1)
      info_tags = tag_names( info1)
      xmap = grid1.xmap
      ymap = grid1.ymap
      restore, profile_fit_files[iscan]

      for itag=0, ntags-1 do begin
        
         ;; method 1: axi-circular main beam
         w = where(r le radius_maximum, nw)
         om_mb0  = total(exp(-1.*r[w]^2/2d0/(tab_3g_par[3, iscan, itag]*!fwhm2sigma)^2)*r[w])*(r[1]-r[0])*2.d0*!dpi
         prof   = profile_3gauss(r, tab_3g_par[*, iscan, itag])
         prof   = prof/max(prof)
         om_tot = total(prof[w]*r[w])*(r(1)-r(0))*2.d0*!dpi
         tab_params[0, iscan, itag] = om_mb0/om_tot
         
         ;; method 1b: axi-circular main beam of nominal FWHM [12.5, 18.5]
         om_mb00  = total(exp(-1.*r[w]^2/2d0/(fwhm_nomi[itag]*!fwhm2sigma)^2)*r[w])*(r(1)-r(0))*2.d0*!dpi
         tab_params[1, iscan, itag] = om_mb00/om_tot

         ;; method 2: 2D Gaussian Main Beam
         wd = where(d le radius_maximum, nwd)
         par = tab_mb_par[*, iscan, itag]
         par[1] = 1.d0 ;; normalised
         par[0] = 0.d0 ;; sans piedestal
         mb = nika_gauss2(xm, ym, par)
         ;;rm = sqrt((xm-tab_mb_par[4, iscan, itag])^2+(ym-tab_mb_par[5, iscan, itag])^2)
         om_mb = total(mb[wd]) ;; arcsec^2
         tab_params[2, iscan, itag] = om_mb/om_tot
         
         ;; measured beam map
         wmap = where(grid_tags eq 'MAP_I'+under[itag]+strtrim(tags[itag], 2), nw)
         map = grid1.(wmap)
         ;;wvar = where(grid_tags eq 'MAP_VAR_I'+under[itag]+strtrim(tags[itag], 2), nw)
         ;;var = grid1.(wvar)
         ;;w=where(finite(var) gt 0 and var lt median(var))
         ;;om_tot_ = total(map[w]/var[w])/total(1d0/var[w])/max(map[w])
         wtag = where( strupcase(info_tags) eq "RESULT_OFF_X_"+tags[itag], nwtag)
         x0   = info1.(wtag)
         wtag = where( strupcase(info_tags) eq "RESULT_OFF_Y_"+tags[itag], nwtag)
         y0   = info1.(wtag)
         dmap = sqrt((xmap-x0)^2+(ymap-y0)^2)
         w=where(dmap le radius_maximum )
         om_tot_ = total(map[w])/max(map[w])
         tab_params[3, iscan, itag] = om_mb/om_tot_

         ;; measured profile
         prof = measured_profile[*, itag]
         r    = MEASURED_PROFILE_RADIUS[*, itag]
         w = where(r le radius_maximum, nwr)
         om_tot__ = total(prof[w]*r[w])*(r(1)-r(0))*2.d0*!dpi/max(prof)
         tab_params[4, iscan, itag] = om_mb00/om_tot__

         
         scat = stddev([om_mb0/om_tot, om_mb/om_tot, om_mb/om_tot_, om_mb/om_tot__])
         tab_params[5, iscan, itag] = scat
         
         
      endfor
   endfor


   ;; print results

   print,''
   print,'--------------------------------'
   print,''
   print,'Beam efficiency'
   print,''
   print,'-------------------------------'
   for iscan = 0, nscan-1 do begin
      print,'===='
      print,scan_list[iscan]
      print,'===='
      for itag = 0, ntags-1 do begin
         print, 'Array ', tags[itag]
         ;print,'--> Using a fitted total beam and a single fwhm main beam'
         ;print,tab_params[0, iscan, itag]
         ;print,'--> Using a fitted total beam and a single nominal fwhm main beam'
         ;print,tab_params[1, iscan, itag]
         ;print,'--> Using a fitted total beam and a 2D Gaussian main beam'
         ;print,tab_params[2, iscan, itag]
         ;print,'--> Using the total beam measured in the map and a 2D Gaussian main beam'
         ;print,tab_params[3, iscan, itag]
         ;print,'--> Using the total beam measured in the profile and a single nominal fwhm main beam'
         print,tab_params[4, iscan, itag]
      endfor
      
   endfor
   print,''
   print,'--------------------------------'
   print,''
   stop
   


   
   for ipar=0, nparams-2 do begin

      print, ' '
      print, "----------------"
      print, params[ipar]
      
      wind, 1, 1, xsize = 1000, ysize = 650, /free
      my_multiplot, 2, 2,  pp, pp1, /rev, ymargin=0., gap_x=0.1, gap_y=0.1, xmargin = 0.
      charsz = 0.9
      ps_thick = 1.
      
      if png eq 1 then begin
         plot_file = plot_dir+"/Profile_fit_allscans"+plot_suffixe+"_histogram_"+params
         ;;outplot, file=plot_file, /png
      endif
      r0 = lindgen(999)/2.+ 1.
      
      tags   = ['1', '3', '1MM', '2']
      under  = ['', '', '_', '']
      titles = ['A1', 'A3', 'A1&A3', 'A2']
      ntags  = n_elements(tags)
      
      text  = strtrim(scan_list,2)
      
      for itag=0, ntags-1 do begin
         
         ;; mb_profiles = dblarr(999, nscan)
         ;; g3_profiles = dblarr(999, nscan)
         ;; if normalise gt 0 then begin
         ;;    for i=0, nscan-1 do mb_profiles[*, i] = exp(-1.*r0^2/2d0/tab_mb_par[2, i, itag]/tab_mb_par[3, i, itag])
         ;;    for i=0, nscan-1 do g3_profiles[*, i] = profile_3gauss(r0,tab_3g_par[*, i, itag])/tab_mb_par[1, i, itag]
         ;; endif else begin
         ;;    for i=0, nscan-1 do mb_profiles[*, i] = tab_mb_par[1, i, itag]*exp(-1.*r0^2/2d0/tab_mb_par[2, i, itag]/tab_mb_par[3, i, itag])
         ;;    for i=0, nscan-1 do g3_profiles[*, i] = profile_3gauss(r0,tab_3g_par[*, i, itag])
         ;; endelse
         
         ;; med_mb_prof = median(mb_profiles,dimension=2)
         ;; med_3g_prof = median(g3_profiles,dimension=2)
      
          
         ;; plot, r0, r0, yr=[1d-4, 30], /ys, xr=[1., 500.], /xs, /nodata, /xlog, /ylog, $
         ;;       ytitle="Profile ratio", xtitle="radius (arcsec)", title=titles[itag], pos=pp1[itag,*], /noerase     
         ;; oplot, r0, med_mb_prof, col=80
         ;; oplot, r0, med_3g_prof, col=250
         
         ;; plot, r0, r0, yr=[0.3, 1.7], /ys, xr=[1., 100.], /xs, /nodata, /xlog, $
         ;;       ytitle="Profile ratio", xtitle="radius (arcsec)", title=titles[itag], pos=pp1[itag,*], /noerase
         
         ;; for iscan =0, nscan-1 do begin
         
         ;;    ;oplot, r0, mb_profiles[*, iscan]/med_mb_prof , col=tab_color(iscan)
         ;;    oplot, r0, g3_profiles[*, iscan]/med_3g_prof , col=tab_color(iscan), thick=2
         ;; endfor
         
         ;; oplot, r0, r0*0.+1d, col=0
         ;; if itag eq 0 then legendastro, text, textcolor=tab_color,
         ;; box=0, charsize=charsz

         print, "---> A"+tags[itag]
     
         f = [reform(tab_params[ipar, *, itag])]
         fcol = 80
                  
         ;;emin = mini[itag]
         ;;emax = maxi[itag]
         ;;bin  = binsi[itag]
         
         np_histo, f, out_xhist, out_yhist, out_gpar, fcol=fcol, fit=0, noerase=1, position=pp1[itag,*], nolegend=1, colorfit=250, thickfit=2*ps_thick, nterms_fit=3, xtitle=tab_xtitle(ipar)

         
         print, 'mean = ', mean(f)
         print, 'median = ', median(f)
         print, 'stddev = ', stddev(f)
         print, ' '
            
            
         
      
      endfor ;; end TAG loop

      if png eq 1 then outplot, /close

   endfor ;; end PARAM loop

   stop
   wd, /a
   
   
endif ;; end do_etendue







end
