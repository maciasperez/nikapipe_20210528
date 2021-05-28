;+
;PURPOSE: This is the main procedure of the pipeline which 
;         reduces NIKA's data to maps.
;
;INPUT: Name of the parmeter file used for the reduction.
;       If this file does not exist or if you want to use a new set of
;       parameters, it has to be created using a script such as
;       ngc1068_v1.pro
;
;OUTPUT: The combined map, from all the scan used (It is also saved as
;        a fits with astrometry).
;
;KEYWORDS:
;   1 - given_head_map: Give a predefined header that you want to use
;       in this keyword
;   2 - simu: Set this keyword if you use the pipeline with simulated data
;   3 - pf: Set this keyword if you want to use a polynomial
;       reconstruction of the resonance frequency instead of the
;       RFdIdQ method
;   4 - ext_params: Give the additional parameters that you want to
;       extract in the data structure when reading the binary data
;   5 - silent: Set this keyword if you do not want to print details
;       about the reading data process
;   6 - noskydip: Set this keyword if you do no want to correct for
;       the opacity from skydips
;   7 - bad_kids: Give the kids numdet that you want to reject
;   8 - add_source: Use this keyword to pass a structure that is used
;       to generate a source map and pur in the data. Only the
;       structure fields corresponding to what is generated are mandatory
;             add_source = {type:'the type of the simulated source', $
;                                             ;Possible values are
;                                             ;'CL', 'PS', 'disk', 'WN', 'Given_Map' 
;                                             ;and all combination written as e.g. 'CL+PS'
;                           SZ:{z:redshift, $ ;
;                               pos:[x_center, y_center], $       ;[arcsec]
;                               calib:[3.4696746,-10.863255]      ;Jy2y 
;                               P0:pressure_normalization, $      ;[keV/cm^3]
;                               rp:caracteristic_radius, $        ;[kpc]
;                               a:a, b:b, c:c, $                  ;Pressure profile slopes
;                               c500:concentration}, $            ;Concentration parameter R500/Rp
;                           PS:{pos:[[x_center1, y_center1], $    ;Position source 1 [arcsec]
;                                    [x_center2, y_center2]], $   ;Position source 2 [arcsec]
;                               flux:[[flux1mm_1, flux2mm_1], $   ;Flux source 1 [Jy]
;                                     [flux1mm_2, flux2mm_2]]}, $ ;Flux source 2 [Jy]
;                           WN:{rms:fluction_rms}, $              ;[Jy/beam]
;                           disk:{radius:disk_radius, $           ;[arcsec]
;                                 pos:[x_center, y_center], $     ;[arcsec]
;                                 flux:[flux1mm, flux2mm]}, $     ;[Jy/beam]
;                           GM:{mapfile:['1mm_fits_file', $       ;
;                                        '2mm_fits_file'], $      ;
;                               relobe:[map_smoothing_1mm, 2mm]}  ;[arcsec]
;                           beam:[12.5, 18.5]}                    ;Beam FWHM [arcsec]
;
;   9 - check_toi_in: Set this keyword to plot the raw (calibrated)
;       TOI and power spectrum
;   10 - check_toi_out: Set this keyword to plot the TOI and power
;        spectrum befor projection
;   11 - azel: Set this keyword if you want the map to be in Azimuth-Elevation and not in R.A.-Dec.
;   12 - kidlist: List of KIDs you want to use for the mapmaking
;   13 - map_per_KID: Set this keyword if you want to produce a scan combined map per detector
;   14 - save_mpkps: Set this keyword if you want to produce also
;        a map per kid per scan
;   15 - png: Set this keyword to save the maps per scan as png
;   16 - ps: Set this keyword to save the maps per scan as ps
;   17 - range_plot_scan_a: Give the range of the 1mm scan maps in this keyword, as a two component vector:[min, max]
;   18 - range_plot_scan_b: Give the range of the 2mm scan maps in this
;        keyword, as a two component vector:[min, max]
;   19 - make_products: Set this keyword to save the TOI and MAPs in FITS
;        for external astronomers
;   20 - var2fits: Set this keyword to save the variance map in fits
;        files instead of the stddev map
;   21 - show_deglitch: set this keyword to compare data before and
;        after deglitching
;   22 - cor_calib: 2 component vector that apply a correctif factor
;        to the calibration (usefull for Run5 and Run6 data that are
;        biased by -5% at 2mm and -30% at 1mm)
;   23 - nocut: set this keyword if you do not want to cut the
;        begining and the end of the scan (often crapy)
;   24 - meas_atm: set this keyword to take a look at the common mode
;        and its power spectrum
;   25 - cf: improved pf method
;   26 - use_noise_from_map: set this keyword if you want to use the
;        noise map computed from the map itself (and not the TOI) for
;        the weights when combining individual scan maps.
;   27 - extent_source: source extention in arcsec. Usefull for gain
;        elevation correction
;   28 - check_flag_cor: set this keyword to check the flagging
;        performed based on the lack of correlation between KIDs
;   29 - check_flag_speed: set this keyword to check the flagging
;        performed based on the scanning speed
;   30 - bypass_error: set this keyword to bypass the error in order
;        to still process all scans
;   31 - no_merge_fig: set this keyword if you do not want to combine
;        figures in one
;   32 - no_acq_flag: set this keyword if you do not want to apply
;        acquisition flags
;   33 - rm_points: set this keyword to the number of points over
;        which the data should be average. This reduces
;        !nika.f_sampling by the same amount
;   34 - make_logbook: set this keyword to produce the logbook
;   35 - plot_decor_toi: produce a plot with all timelines decorrelated
;   36 - acc_flag_lissajous: flag the acceleration above acc_flag_lissajous
;   37 - median_cut: set this keyword to flag uncorrelated KIDs with
;        median less then median_cut=[min_1mm, min_2mm]
;   38 - flag_holes: do not use flagged regions in the reconstructed pointings.
;   39 - filtfact: expected point source filtering factor used to
;        correct measured fluxes in the log
;   40 - JKscan: set this keyword to apply a minus sign in front of
;        the TOI of one scan over JKscan. E.g. if JKscan is 2, the
;        scans are multiplied by -1, -1, 1, 1, -1, -1, 1 ... 
;   41 - clean_save_maps: set this keyword to remove previously
;        produced maps
;   42 - multi_decor: give the number of times you want to do the decorelation
;   43 - nasmyth: set this keyword to make the map in nasmyth system
;   44 - beammap: set this keyword to set the nasmyth detector offset
;        to zero when projecting map
;   45 - all_kid_ok: set this keyword to force kidpar flagged KIDs to
;        be accepted
;   46 - no_calib: set this keyword to work in Hz
;   47 - meas_elec: set this keyword to measure the electronic noise
;        per block
;   48 - brutal_cut: to cut the beg. and end of scan in a brutal way
;   49 - subtract_toi_iter: remove previously estimated TOI for
;        CMBLOCK decorelation
;   50 - rm_part_ss: cut part of subscan at begining and end
;        rm_part_ss = [cut_beg, cut_end] in percent
;   51 - old_method_tau: set this keyword to use the old method for
;        the calculation of tau 
;
;LAST EDITION: 
;   2013: add the possibility to read simulated data (remi.adam@lpsc.in2p3.fr)
;   2013: adapted to Run6 data format (Nicolas.Ponthieu@obs.ujf-grenoble.fr)
;   2013: adapted to opaciy corrections from skydips results
;(catalano@lpsc.in2p3.fr)
;   21/09/2013: possibility to define precisely the header or to use a
;               given one (adam@lpsc.in2p3.fr)
;   20/11/2013: add module for atmospheric noise characterization
;   03/01/2014: add module for gain-elevation correction
;   06/01/2014: flagging and cut of the scan improved
;   07/01/2014: flagging with tuning and anomalous speed added
;   08/01/2014: keyword bypass_error added
;   15/02/2014: Deglitch the data after decorrelation
;   16/02/2014: Force the number of sample to be an even number
;   27/04/2014: add keyword speed_flag_lissajous and median_cut
;   02/07/2104: add restore and saved maps properly
;   02/12/2014: add a SaveMap subdirectory for maps.save per scan
;   03/12/2014: add a flag for the full scan so it does not crash
;   15/12/2014: add keywords nasmyth and beammap no_calib
;   05/01/2015: add keyword meas_elec
;   07/09/2015: opacity can be calculated with the new pipeline method
;-

pro nika_pipe_launch, param, map_combi, map_list, $
                      given_head_map=given_head_map, $
                      simu=simu,$                                 
                      pf=pf,$                                     
                      ext_params=ext_params,$                     
                      silent=silent,$                             
                      noskydip=noskydip,$                         
                      bad_kids=bad_kids,$                         
                      add_source=add_source,$ 
                      check_toi_in=check_toi_in,$
                      check_toi_out=check_toi_out,$
                      azel=azel,$                                 
                      kidlist=kidlist,$                           
                      map_per_KID=map_per_KID,$                   
                      save_mpkps=save_mpkps,$ 
                      png=png,$                                   
                      ps=ps,$                                     
                      range_plot_scan_a=range_plot_scan_a,$       
                      range_plot_scan_b=range_plot_scan_b,$
                      make_products=make_products,$
                      var2fits=var2fits,$
                      show_deglitch=show_deglitch,$
                      cor_calib=cor_calib,$
                      nocut=nocut,$
                      meas_atm=meas_atm,$
                      cf=cf,$
                      use_noise_from_map=use_noise_from_map,$
                      extent_source=extent_source,$
                      check_flag_cor=check_flag_cor,$
                      check_flag_speed=check_flag_speed,$
                      bypass_error=bypass_error,$
                      no_merge_fig=no_merge_fig,$
                      no_acq_flag=no_acq_flag,$
                      rm_points=rm_points, $
                      make_logbook=make_logbook,$
                      plot_decor_toi=plot_decor_toi, $
                      acc_flag_lissajous=acc_flag_lissajous, $
                      median_cut=median_cut, $
                      flag_holes=flag_holes, $
                      filtfact=filtfact, $
                      JKscan=JKscan, $
                      clean_save_maps=clean_save_maps, $
                      multi_decor=multi_decor, $
                      no_speedflag=no_speedflag, $
                      nasmyth=nasmyth, $
                      beammap=beammap, $
                      all_kid_ok=all_kid_ok, $
                      no_calib=no_calib, $
                      meas_elec=meas_elec, $
                      brutal_cut=brutal_cut, $
                      subtract_toi_iter=subtract_toi_iter, $
                      rm_part_ss=rm_part_ss, $
                      old_method_tau=old_method_tau, $
                      lsw_fwhm=lsw_fwhm, $
                      blocv=blocv
  
  ;;========== Defines new keywords
  if keyword_set(save_mpkps) then map_per_kid = 1 ;Force map_per_kid defined if we save the map per kids per scan
  if not keyword_set(silent) then verb = 1        ;Some routines use verb instead of silent

  ;;========== Guess if need to reset coordinates and param or not for each scan in case not provided
  if ten(param.coord_pointing.ra[0],param.coord_pointing.ra[1],param.coord_pointing.ra[2])*15.0 eq 0 $
     and ten(param.coord_pointing.dec[0],param.coord_pointing.dec[1],param.coord_pointing.dec[2]) eq 0 then $
        reset_coord_pointing = 'yes' else reset_coord_pointing = 'no'
  if ten(param.coord_source.ra[0],param.coord_source.ra[1],param.coord_source.ra[2])*15.0 eq 0 $
     and ten(param.coord_source.dec[0],param.coord_source.dec[1],param.coord_source.dec[2]) eq 0 then $
        reset_coord_source = 'yes' else reset_coord_source = 'no'
  
  if param.source eq '' then reset_source = 'yes' else reset_source = 'no'
  if param.name4file eq '' then reset_name4file = 'yes' else reset_name4file = 'no'
  if param.output_dir eq '.' then reset_output_dir = 'yes' else reset_output_dir = 'no'
  if param.logfile_dir eq '.' then reset_logfile_dir = 'yes' else reset_logfile_dir = 'no'
  
  ;;========== Set the astrometry unless provided 
  nika_pipe_def_header, param, astrometry, given_head_map=given_head_map, simu=simu, azel=azel
  
  ;;========== Create a simulated map if required (done here because unit conversion coefficients are needed)
  if keyword_set(add_source) then nika_pipe_simu_fits_map, add_source, astrometry, param.output_dir

  ;;========== Clean the saved maps
  if keyword_set(clean_save_maps) then spawn, 'rm '+param.output_dir+'/SaveMap/maps_*.save'

  ;;========== Get the maps for individual scans 
  nscans = n_elements(param.scan_list) ;Number of scans
  for iscan = 0 , nscans - 1 do begin
     param.iscan = iscan
     
     ;;------- Test if maps already exist
     spawn, "ls "+param.output_dir+"/SaveMap/maps_"+param.day[param.iscan]+"_"+strtrim(param.scan_num[param.iscan],2)+".save", save_map_name
     if save_map_name ne '' then message, /info, '--------------'
     if save_map_name ne '' then message, /info, 'Restoring map '+save_map_name
     if save_map_name ne '' then message, /info, '--------------'
     if save_map_name ne '' then goto, restoring_maps
     
     ;;------- Reset the coordinates if needed
     if reset_coord_pointing eq 'yes'  then param.coord_pointing.ra *= 0
     if reset_coord_pointing eq 'yes'  then param.coord_pointing.dec *= 0
     if reset_coord_source   eq 'yes'  then param.coord_source.ra *= 0
     if reset_coord_source   eq 'yes'  then param.coord_source.dec *= 0
     
     ;;------- Get the data
     if keyword_set(simu) then restore, param.output_dir+'/TOI_'+param.name4file+'_'+param.version+'_s'+$
                                        string(param.iscan, format="(I4.4)")+'.save'
     
     nika_pipe_getdata, param, data, kidpar, pf=pf, ext_params=ext_params, silent=silent, $
                        make_products=make_products, simu=simu, no_acq_flag=no_acq_flag
     
     ;;-------- Restaure OFF and bad KIDs
     if keyword_set(all_kid_ok) then begin
        wnan = where(finite(kidpar.nas_x) ne 1, nwnan)
        if nwnan ne 0 then kidpar[wnan].nas_x = 0
        wnan = where(finite(kidpar.nas_y) ne 1, nwnan)
        if nwnan ne 0 then kidpar[wnan].nas_y = 0
        kidpar.type = 1
     endif

     ;;------- Jack-Knife in TOI and other buisiness
     if keyword_set(JKscan) then data.RF_dIdQ *= (-1)^(iscan/long(JKscan))
     if keyword_set(JKscan) then print, 'TOI multiplied by '+ strtrim((-1)^(iscan/long(JKscan)), 2)
     
     ;;------- Transform a bit the data
     if keyword_set(rm_points) then data = nika_pipe_rmpoints(data, rm_points)
     Npt = n_elements(data)
     if long(Npt)/long(2) ne double(Npt)/double(2) then data = data[1:*] ;I want even number of samples
     
     ;;------- Get source name from IMB_FITS if not given by user
     nika_pipe_sourcename, param, reset_source, reset_name4file, reset_output_dir, reset_logfile_dir
     
     ;;------- Correct the pointing from antenna data
     ;;nika_pipe_corpointing, param, data, kidpar, simu=simu, azel=azel, w_ok=w_nocut
     ;;nika_pipe_valid_scan, param, data, kidpar
     nika_pipe_corpointing_2, param, data, kidpar, flag_holes=flag_holes, silent=silent
     
     ;;------- Cut the scan (flag) and select lissajous
     param.scan_type[param.iscan] = nika_pipe_findtypescan(param, data, silent=silent)
     
     if param.scan_type[param.iscan] eq 'lissajous' and not keyword_set(nocut) then $ 
        nika_pipe_lissajou_select, param, data, kidpar, $
                                   silent=silent, pazel=pazel
     
     nika_pipe_cutscan, param, data, loc_ok, loc_bad=loc_bad, brutal=brutal_cut, rm_part_ss=rm_part_ss ;, /safe
     if not keyword_set(nocut) and loc_bad[0] ne -1 then nika_pipe_addflag, data, 8, wsample=loc_bad
     wcut = nika_pipe_wflag(data.flag[0], [7,8], nflag=nflag, comp=w_nocut, ncomp=nw_nocut)

     ;;------- Add speed flags
     if not keyword_set(no_speedflag) then nika_pipe_speedflag, param, data, $
        check=check_flag_speed, ps=ps, no_merge_fig=no_merge_fig, $
        acc_flag_lissajous=acc_flag_lissajous, w_nocut=w_nocut
     
     ;;------- Get the on-source positions
     nika_pipe_onsource, param, data, kidpar, astrometry, azel=azel
     
     ;;----- Calibrate the data 
     if param.glitch.iq eq 0 then nika_pipe_opacity, param, data, kidpar, $
        simu=simu, noskydip=noskydip, old_method=old_method_tau
     if param.glitch.iq eq 0 then if not keyword_set(no_calib) then nika_pipe_calib, param, data, kidpar, noskydip=noskydip
     if (param.glitch.iq eq 0 and not keyword_set(simu)) then nika_pipe_gain_cor, param, data, kidpar,$
        extent_source=extent_source, silent=silent
     
     ;;------- Add a source by hand if requested 
     if keyword_set(add_source) then nika_pipe_addsource, param, data, kidpar
     
     ;;------- Check raw TOI
     if keyword_set(check_toi_in) then nika_pipe_checktoi, param, data[w_nocut], kidpar, /raw
     
     ;;------- Deglitch the data
     nika_pipe_deglitch, param, data, kidpar, show=show_deglitch
     if param.glitch.iq eq 1 then nika_pipe_opacity, param, data, kidpar, $
        simu=simu, noskydip=noskydip, old_method=old_method_tau
     if param.glitch.iq eq 1 then if not keyword_set(no_calib) then nika_pipe_calib, param, data, kidpar, $
        noskydip=noskydip
     if (param.glitch.iq eq 1 and not keyword_set(simu)) then nika_pipe_gain_cor, param, data, kidpar,$
        extent_source=extent_source

     ;;========== Do the following unless the scan is entirely flagged
     if param.flag.scan[param.iscan] lt 1 then begin
        ;;------- Calibration correction
        if keyword_set(cor_calib) then data.RF_dIdQ[where(kidpar.array eq 1)] *= cor_calib[0]
        if keyword_set(cor_calib) then data.RF_dIdQ[where(kidpar.array eq 2)] *= cor_calib[1]

        ;;------- Produce calibrated data in fits files, a log and the FPG
        if keyword_set(make_products) then nika_pipe_toi2fits, param, data, kidpar
        if keyword_set(make_products) then nika_pipe_fpg2fits, param, data, kidpar

        ;;------- The data can be cut once saved for astronomers
        data = data[w_nocut]
        Npt = n_elements(data)
        if long(Npt)/long(2) ne double(Npt)/double(2) then data = data[1:*] ;I want even number of samples
        if (param.scan_type[param.iscan] eq 'lissajous') and (param.pointing.fake_subscan eq 'yes') then $
           data = nika_pipe_subscan4lissajous(data, factor=param.pointing.liss_cross, silent=silent) ;Here the subscans are changed

        param.integ_time[iscan] = n_elements(data)/!nika.f_sampling
        
        ;;------- Flag KIDs that are far from the resonance, jumps, bad KIDs
        if not keyword_set(simu) then nika_pipe_outofres, param, data, kidpar, $
           bypass_error=bypass_error, verb=verb
        nika_pipe_flagkid, param, data, kidpar, bad_kids=bad_kids, show=check_flag_cor, $
                           ps=ps, no_merge_fig=no_merge_fig, silent=silent, median_cut=median_cut

        ;;------- Measure the atmospheric noise and check x_correlations
        if keyword_set(meas_atm) then nika_pipe_measure_atmo, param, data, kidpar, $
           ps=ps, no_merge_fig=no_merge_fig

        ;;------- Flag subscans which are too short
        nika_pipe_flagshortsubscan, param, kidpar, data

        ;;------- Filter the data before decorrelation
        if param.filter.pre eq 'yes' then nika_pipe_prefilter, param, data, kidpar
        
        ;;------- Decorrelate the data from the noise
        nika_pipe_decor, param, data, kidpar, extent_source=extent_source, $
                         bypass_error=bypass_error, pazel=pazel,subtract_toi_iter=subtract_toi_iter, blocv=blocv
        
        ;;------- Measure the bloc electronic noise
        if keyword_set(meas_elec) then nika_pipe_fit_elec_noise, param, data, kidpar

        ;;------- Remove straight baseline
        if param.decor.baseline[0] gt 0 then nika_pipe_rmbaseline, param, data, kidpar

        ;;------- Multi decorrelation
        if keyword_set(multi_decor) then for id=1, multi_decor do begin
           nika_pipe_decor, param, data, kidpar, extent_source=extent_source, $
                            bypass_error=bypass_error, pazel=pazel,subtract_toi_iter=subtract_toi_iter, blocv=blocv
           if param.decor.baseline[0] gt 0 then nika_pipe_rmbaseline, param, data, kidpar
        endfor

        ;;------- Filter the data (lines and low freq)
        nika_pipe_filter, param, data, kidpar

        ;;------- Re-deglitch the data
        nika_pipe_deglitch, param, data, kidpar, show=show_deglitch

        ;;------- Remove the zero level per TOI
        nika_pipe_set0level, param, data, kidpar

        ;;------- Get weight TOI
        nika_pipe_w8toi, param, data, kidpar
        
        ;;------- Check TOI before map
        if keyword_set(check_toi_out) then nika_pipe_checktoi, param, data, kidpar
        if keyword_set(plot_decor_toi) then nika_pipe_plotdecortoi, param, data, kidpar, $
           no_merge_fig=no_merge_fig
        
        ;;------- Find out the list of KIDs used
        nika_pipe_kidused, param, data, kidpar, kid_used_1mm, kid_used_2mm      
        
        ;;------- Compute individual maps  
        nika_pipe_map, param, data, kidpar, maps, $
                       kidlist=kidlist, map_per_KID=map_per_KID, azel=azel, nasmyth=nasmyth, $
                       map_per_scan_per_kid=map_per_scan_per_kid, astr=astrometry, $
                       /undef_var2nan, bypass_error=bypass_error, $
                       beammap=beammap
        
        spawn, "mkdir -p "+param.output_dir+'/SaveMap'
        save, file=param.output_dir+"/SaveMap/maps_"+param.day[param.iscan]+"_"+strtrim(param.scan_num[param.iscan],2)+".save",  maps, kidpar, kid_used_1mm, kid_used_2mm
        
        ;;------- Restore maps if present
        restoring_maps: if save_map_name ne '' then begin
           restore, save_map_name
           nika_find_raw_data_file, param.scan_num[param.iscan], param.day[param.iscan], file_scan, imb_fits_file, /silent
           param.imb_fits_file = imb_fits_file[0]
           nika_pipe_corpointing_2, param, data, kidpar, flag_holes=flag_holes, coord_only=1
        endif     
        
        ;;------- Compute a noise map from the map itself
        nika_pipe_noise_from_map, param, maps, astrometry=astrometry
        
        ;;------- Compute the NEFD per scan
        nika_pipe_nefd, param, kidpar, maps, silent=silent
        nika_pipe_nefd, param, kidpar, maps, /from_toi, silent=silent
        
        ;;------- Plot the maps
        nika_pipe_plotmaps, param, kidpar, astrometry, maps, $
                            ps=ps, png=png, range_plot_scan_a=range_plot_scan_a,$
                            range_plot_scan_b=range_plot_scan_b,$
                            no_merge_fig=no_merge_fig

        ;;------- Individual map list and plot       
        if iscan eq 0 then map_list = replicate(maps, nscans)
        map_list[iscan] = maps
        
        ;;------- Make the logfile
        if keyword_set(make_logbook) then nika_pipe_makelog, param, filtfact = filtfact

        ;;------- Print the scan number
        message, /info, 'Map computed for the scan '+strtrim(iscan+1,2)+'/'+$
                 strtrim(nscans,2)+' -- '+strtrim(param.scan_list[param.iscan])
        message, /info, 'Integration time: '+strtrim(param.integ_time[iscan],2)+' seconds'
        print, ' '
        print, ' '
     endif                      ; avoiding bad scans
     
     ;;------- Reset the structure !nika
     reset_nika_struct
  endfor  
  
  ;;####### Combine maps
  ;;---------- Keep good scans only before combining
  okscans = where(param.flag.scan lt 1, nokscans)
  if nokscans gt 0 then begin 
     nika_pipe_combimap, map_list[okscans], map_combi, use_noise_from_map=use_noise_from_map
     if keyword_set(lsw_fwhm) then nika_pipe_combimap_lsw, map_list[okscans], map_combi, lsw_fwhm/param.map.reso
     
     nika_pipe_noise_from_map, param, map_combi, astrometry=astrometry
  endif 

  ;;####### Save the param, map per KIDs, map per KIDs and per detectors
  save, filename=param.output_dir+'/param_'+param.name4file+'_'+param.version+'.save', param
  
  if keyword_set(map_per_KID) then begin
     save,filename=param.output_dir+'/map_per_KID_'+param.name4file+'_'+param.version+'.save', map_per_KID
     save,filename=param.output_dir+'/kidpar_'+param.name4file+'_'+param.version+'.save', kidpar
  endif
  if keyword_set(save_mpkps) then begin
     save,filename=param.output_dir+'/map_per_scan_per_kid_'+param.name4file+'_'+param.version+'.save', $
          map_per_scan_per_kid
     save,filename=param.output_dir+'/kidpar_'+param.name4file+'_'+param.version+'.save', kidpar
  endif
  
  ;;####### Save the maps as a FITS file
  nika_pipe_map2fits, param, map_combi, map_list, astrometry, $
                      kid_used_1mm, kid_used_2mm, $
                      var2fits=var2fits, make_products=make_products, cp_scan=no_merge_fig
  
  return
end
