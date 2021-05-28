;+
; PURPOSE: Launch all given scan individually with no need to know what
;         they are
;
; INPUT: The list of scan number and day
;
; OUTPUT: Results in appropriate folder
;
; KEYWORD: - dir: the directory in which to save all this (default is
;           !nika.plot_dir)
;         - rm_toi: set this keyword to remove FITS TOI that are heavy
;         - decor: choose your favorite decorrelation method
;
; MODIFICATIONS:  - 09/01/2014 creation (adam@lpsc.in2p3.fr)
;                 - 30/01/2014 modify default parameters
;                   (macias@lpsc.in2p3.fr)
;                 - 17/02/2013 add keywords and mege pdf
;-

pro nika_pipe_launch_all_scan, scan_num_list, day_list, $
                               dir_plot=dir_plot, $
                               rm_toi=rm_toi, $
                               rm_bp=rm_bp, $
                               rm_fp=rm_fp, $
                               rm_uc=rm_uc, $
                               version=version,$
                               size_map_x=size_map_x,$
                               size_map_y=size_map_y,$
                               coord_map = coord_map, $
                               reso=reso,$
                               decor=decor, $
                               nsig_bloc=nsig_bloc,$
                               nbloc_min=nbloc_min,$
                               d_min=d_min,$
                               d_perscan=d_perscan,$
                               apply_filter=apply_filter,$
                               low_cut_filter=low_cut_filter,$
                               cos_sin=cos_sin,$
                               sens_per_kid=sens_per_kid,$
                               no_flag=no_flag, $
                               silent = silent, $
                               azel = k_azel, $
                               noscanred = noscanred, $
                               allow_shift = allow_shift, $
                               flag_holes = flag_holes, $
                               filtfact = filtfact
  
  ;;------- define lists of planets
  planets = ['Uranus','Jupiter','Saturn','Neptune']
  
  ;;------- set default  directories
  if not keyword_set(dir_plot) then dir = !nika.plot_dir+'/All_Scans' else dir = dir_plot
  if keyword_set(version) then dir = dir_plot+'/'+version
  dir_logfile = dir 
  spawn, 'mkdir -p '+ dir

  ;;------- The list is valid?
  nscan = n_elements(day_list)
  if nscan ne n_elements(scan_num_list) then message,'The number of day must be equal to the number of scan_num'
  
  ;;####### Get list of imb_fits and also check scans exists and overwrite scanlist and daylist
  imb_fits=['']
  new_scan_num_list=[0]
  new_day_list=['']
  for iscan=0, nscan-1 do begin

     nika_find_raw_data_file, scan_num_list[iscan], day_list[iscan], file_scan, imb_fits_file, /silent
     if (file_scan ne '' and imb_fits_file ne '') then begin
        imb_fits=[imb_fits,imb_fits_file]
        new_scan_num_list=[new_scan_num_list,scan_num_list[iscan]]
        new_day_list=[new_day_list,day_list[iscan]]
     endif else begin
        print, "NO FILES for scan "+ strtrim(scan_num_list[iscan],2)+ " for day "+ (day_list[iscan])
     endelse
  endfor

  ;;------- If no file available, error
  nscan = n_elements(new_scan_num_list)
  if nscan le 1 then message, 'No file for any of the requested scans'

  ;;------- Select the initialization
  imb_fits = imb_fits[1:*]
  scan_num_list = new_scan_num_list[1:*]
  day_list = new_day_list[1:*]
  nscan = n_elements(scan_num_list)

  if nscan gt 0 then begin
     ; Skip scan reduction if requested (this option does not work yet)
     if not keyword_set( noscanred) then begin
     ;;####### Launch the pipeline for all scans
     for iscan=0, nscan-1 do begin
 
        print, " --------------------------------------------------------------"
        print, "    Working on scan : "+strtrim(day_list[iscan],2 )+ "   "+strtrim(scan_num_list[iscan],2)+ ' , iscan, nscan = '+strtrim( iscan, 2)+', '+ $
               strtrim( nscan, 2)
        print, "---------------------------------------------------------------"

       ;;------- Select the scan
        scan_num = scan_num_list[iscan]
        day = day_list[iscan]

        ;;------- Get default params accordingly
        nika_pipe_default_param, scan_num, day, param

        ;;------- Define directories and names
        if keyword_set(version) then param.version = version
        param.logfile_dir = dir_logfile
        param.imb_fits_file = imb_fits[iscan]
        ;;nika_pipe_sourcename, param, 'yes', 'yes', 'yes', 'yes', dir_ant=dir
        nika_pipe_sourcename, param, 'yes', 'yes', 'yes', 'no', $
                              dir_ant=dir, silent = silent ;Get the source names in param
        
        ;;------- Get the appropriate map parameters
        if keyword_set(reso) then param.map.reso = reso
        if keyword_set(size_map_x) then param.map.size_ra = size_map_x
        if keyword_set(size_map_y) then param.map.size_dec = size_map_y

        ;;------- Guess if an Az El map is preferred
        lplanets = where(param.source eq planets, nlplanets)
        if nlplanets gt 0 then azel=1 else azel=0
        if keyword_set( k_azel) then azel = 1 ; can override default
        if keyword_set( coord_map) and azel eq 0 then begin
           if size( coord_map, /type) eq 8 then begin
              param.coord_map.ra = coord_map.ra
              param.coord_map.dec = coord_map.dec
           endif else message, 'coord_pointing should be a structure'
        endif

        ;;------- Get the appropriate decorrelation
        if keyword_set(decor) then param.decor.method = decor
        if keyword_set(nbloc_min) then param.decor.common_mode.nbloc_min = nbloc_min
        if keyword_set(nsig_bloc) then param.decor.common_mode.nsig_bloc = nsig_bloc
        if keyword_set(d_min) then param.decor.common_mode.d_min = d_min
        if keyword_set(d_perscan) then param.decor.common_mode.per_subscan = 'no'

        ;;---------- Filtering
        if keyword_set(apply_filter) or keyword_set(low_cut_filter) then param.filter.apply = 'yes'
        if keyword_set(low_cut_filter) then param.filter.low_cut = low_cut_filter
        if keyword_set(cos_sin) then param.filter.cos_sin = 'yes'
        if keyword_set(dist_source_filter) then param.filter.dist_off_source = dist_source_filter

        ;;------- Flag the no correlated KIDs
        if keyword_set(no_flag) then param.flag.uncorr = 'no'
        if strupcase(param.decor.method) eq 'COMMON_MODE_BLOCK' then param.flag.uncorr = 'no'


        ;;------- Launch the pipe
        nika_pipe_launch, param, map_combi, map_list, $
                          /check_flag_cor, $
                          /check_flag_speed, $
                          /meas_atm, $
                          /ps, $
                          /make_products, $
                          /bypass_error, $
                          azel=azel, $
                          /make_log, $
                          /use_noise_from_map,$
                          /no_merge_fig,$
                          /plot_decor_toi, $
                          map_per_KID=sens_per_kid, $
                          silent = silent, $
                          flag_holes = flag_holes, $
                          filtfact = filtfact
                          
stop
        
        ;;------- Produce some maps
        nika_anapipe_default_param, anapar
        anapar.flux_map.relob.a = 10
        anapar.flux_map.relob.b = 10
        anapar.noise_map.relob.a = 10
        anapar.noise_map.relob.b = 10
        anapar.time_map.relob.a = 10
        anapar.time_map.relob.b = 10
        anapar.snr_map.relob.a = 10
        anapar.snr_map.relob.b = 10

        anapar.noise_meas.apply = 'yes'
        if keyword_set(sens_per_kid) then anapar.noise_meas.per_kid = 'yes'

        nika_anapipe_launch, param, anapar, /indiv_scan, silent = silent
        
 ;       nika_anapipe_launch, param, anapar, /indiv_scan

        ;;------- For now delete the combined map because useless
        spawn, 'rm -rf '+dir+'/'+param.name4file+'/IRAM_MAP_'+param.name4file+'_combined_1mm.fits'
        spawn, 'rm -rf '+dir+'/'+param.name4file+'/IRAM_MAP_'+param.name4file+'_combined_2mm.fits'
        if keyword_set(rm_toi) then spawn, 'rm -rf '+dir+'/'+param.name4file+'/IRAM_TOI_*.fits'
        if keyword_set(rm_bp) then spawn, 'rm -rf '+dir+'/'+param.name4file+'/NIKA_bandpass.fits'
        if keyword_set(rm_fp) then spawn, 'rm -rf '+dir+'/'+param.name4file+'/NIKA_focal_plane.fits'
        if keyword_set(rm_uc) then spawn, 'rm -rf '+dir+'/'+param.name4file+'/NIKA_unit_conversion.fits'
     endfor  ; end loop on scans
  endif ;end case of noscanred


     ;;####### Get all the sources and their folder
     cmd = "find "+dir+" -type d -print"
     spawn, cmd, folder
     wfolder = where(folder ne dir, nwfolder)
     if nwfolder ne 0 then folder = folder[wfolder]
     nsource = n_elements(folder)
     
     ;;####### Combine scans in folders
     for isource=0, nsource-1 do begin
        ;;------- Get the scans of the source
        cmd = "find "+folder[isource]+" -name 'IRAM_MAP*1mm.fits' -print"
        spawn, cmd, FITS_map1mm
        cmd = "find "+folder[isource]+" -name 'IRAM_MAP*2mm.fits' -print"
        spawn, cmd, FITS_map2mm

        nscan = n_elements(FITS_map1mm)
        if nscan ne n_elements(FITS_map2mm) then message, /info, $
           'The number of maps is different for 1mm and 2mm !' ;This should never happen
        
        ;;------- Get the scan number and day from the file name
        len = strlen(FITS_map1mm[0])
        scan_num_source = long(strmid(FITS_map1mm, len-13, 4))
        day_source = strmid(FITS_map1mm, len-22, 8)

        ;;------- Get the last param file
        cmd = "find "+folder[isource]+"/param*.save -print"
        spawn, cmd, param_file
        restore, param_file
        param0 = param
        
        ;;------- Init the map_list
        map0 = mrdfits(FITS_map1mm[0], 0, head)
        extast, head, astrometry
        nx = astrometry.naxis[0]
        ny = astrometry.naxis[0]
        map0 = dblarr(nx, ny)
        maps = {A:{Jy:map0, var:map0, noise_map:map0, time:map0}, $
                B:{Jy:map0, var:map0, noise_map:map0, time:map0}}
        map_list = replicate(maps, nscan)
        
        kid_used_1mm = intarr(nscan, 400) 
        kid_used_2mm = intarr(nscan, 400)

        ;;------- Get a param file and update it knowing all the scans used
        nika_pipe_default_param, scan_num_source, day_source, param
        param.version = param0.version
        param.output_dir = param0.output_dir
        param.name4file = param0.name4file
        param.source = param0.source
        param.map.size_ra = param0.map.size_ra
        param.map.size_dec = param0.map.size_dec
        param.map.reso = param0.map.reso
        param.coord_map.ra = param0.coord_map.ra
        param.coord_map.dec = param0.coord_map.dec
        param.coord_pointing.ra = param0.coord_pointing.ra
        param.coord_pointing.dec = param0.coord_pointing.dec
        param.coord_source.ra = param0.coord_source.ra
        param.coord_source.dec = param0.coord_source.dec

        ;;------- Fill the map list with all scans
        for iscan=0, nscan-1 do begin
           info1mm = mrdfits(FITS_map1mm[iscan], 1, head)
           info2mm = mrdfits(FITS_map2mm[iscan], 1, head)
           kid_used_1mm[iscan, *] = info1mm.KID_USED
           kid_used_2mm[iscan, *] = info2mm.KID_USED
           param.scan_list[iscan] = info1mm.SCAN_USED
           param.integ_time[iscan] = info1mm.TIME_INTEG
           param.tau_list.a[iscan] = info1mm.TAU_ZENITH
           param.tau_list.b[iscan] = info2mm.TAU_ZENITH
           param.scan_type[iscan] = info1mm.SCAN_TYPE
           
           flux1mm = mrdfits(folder[isource]+'/MAPS_'+param.scan_list[iscan]+'_1mm_'+param.name4file+'_'+param.version+'.fits', 0, head)
           flux2mm = mrdfits(folder[isource]+'/MAPS_'+param.scan_list[iscan]+'_2mm_'+param.name4file+'_'+param.version+'.fits', 0, head)
           noise1mm = mrdfits(folder[isource]+'/MAPS_'+param.scan_list[iscan]+'_1mm_'+param.name4file+'_'+param.version+'.fits', 1, head)
           noise2mm = mrdfits(folder[isource]+'/MAPS_'+param.scan_list[iscan]+'_2mm_'+param.name4file+'_'+param.version+'.fits', 1, head)
           noise_fm1mm = mrdfits(folder[isource]+'/MAPS_'+param.scan_list[iscan]+'_1mm_'+param.name4file+'_'+param.version+'.fits', 2, head)
           noise_fm2mm = mrdfits(folder[isource]+'/MAPS_'+param.scan_list[iscan]+'_2mm_'+param.name4file+'_'+param.version+'.fits', 2, head)
           time1mm = mrdfits(folder[isource]+'/MAPS_'+param.scan_list[iscan]+'_1mm_'+param.name4file+'_'+param.version+'.fits', 3, head)
           time2mm = mrdfits(folder[isource]+'/MAPS_'+param.scan_list[iscan]+'_2mm_'+param.name4file+'_'+param.version+'.fits', 3, head)
           
           maps = {A:{Jy:flux1mm, var:noise1mm^2, noise_map:noise_fm1mm, time:time1mm}, $
                   B:{Jy:flux2mm, var:noise2mm^2, noise_map:noise_fm2mm, time:time2mm}}
           map_list[iscan] = maps
        endfor

        ;;------- Combine all scans
        nika_pipe_combimap, map_list, map_combi, /use_noise_from_map
        
        ;;------- Save as FITS accordingly
        nika_pipe_map2fits, param, map_combi, map_list, astrometry, $
                            kid_used_1mm, kid_used_2mm, /make_products
        
        ;;------- Launch some analysis
        nika_anapipe_default_param, anapar
        anapar.flux_map.relob.a = 10
        anapar.flux_map.relob.b = 10
        anapar.noise_map.relob.a = 10
        anapar.noise_map.relob.b = 10
        anapar.time_map.relob.a = 10
        anapar.time_map.relob.b = 10
        anapar.snr_map.relob.a = 10
        anapar.snr_map.relob.b = 10
        anapar.noise_meas.jk.relob.a = 10
        anapar.noise_meas.jk.relob.b = 10
        
        anapar.ps_photo.apply = 'yes'
        anapar.ps_photo.allow_shift = 'no'
        if keyword_set( allow_shift) then anapar.ps_photo.allow_shift = 'yes'
        anapar.ps_photo.per_scan='yes'
        anapar.ps_photo.beam.a = !nika.fwhm_nom[0]
        anapar.ps_photo.beam.b = !nika.fwhm_nom[1]
        
        anapar.noise_meas.apply='yes'

        nika_anapipe_launch, param, anapar, /make_logbook, $
                             filtfact = filtfact, silent = silent
        
        ;;------- Remove unwanted fits and param file
        spawn, 'rm -rf '+dir+'/'+param.name4file+'/MAPS_*.fits'
        spawn, 'rm -rf '+dir+'/'+param.name4file+'/MAPS_*.fits'
;  needed?      spawn, 'rm -rf '+dir+'/'+param.name4file+'/param*.save'
        spawn, 'rm -rf '+dir+'/'+param.name4file+'/anapar*.save'
        spawn, 'rm -rf '+dir+'/'+param.name4file+'/map_per_KID*.save'
        spawn, 'rm -rf '+dir+'/'+param.name4file+'/kidpar*.save'
        spawn, 'rm -rf '+dir+'/'+param.name4file+'/*sensitivity_1mm.pdf'
        spawn, 'rm -rf '+dir+'/'+param.name4file+'/*sensitivity_2mm.pdf'
        spawn, 'rm -rf '+dir+'/'+param.name4file+'/*sensitivity_all_KIDs.pdf'
        
        ;;------- Merge PDFs
        my_dear = dir+'/'+param.name4file+'/'
        
        spawn, 'pdftk '+my_dear+param.name4file+'_time*s*1mm.pdf cat output '+my_dear+param.name4file+'_time_1mm_all_scans.pdf'
        spawn, 'rm -rf '+my_dear+param.name4file+'_time*s*1mm.pdf'
        spawn, 'pdftk '+my_dear+param.name4file+'_stddev*s*1mm.pdf cat output '+my_dear+param.name4file+'_stddev_1mm_all_scans.pdf'
        spawn, 'rm -rf '+my_dear+param.name4file+'_stddev*s*1mm.pdf'
        spawn, 'pdftk '+my_dear+param.name4file+'_SNR*s*1mm.pdf cat output '+my_dear+param.name4file+'_SNR_1mm_all_scans.pdf'
        spawn, 'rm -rf '+my_dear+param.name4file+'_SNR*s*1mm.pdf'
        spawn, 'pdftk '+my_dear+param.name4file+'_flux*s*1mm.pdf cat output '+my_dear+param.name4file+'_flux_1mm_all_scans.pdf'
        spawn, 'rm -rf '+my_dear+param.name4file+'_flux*s*1mm.pdf'
        spawn, 'pdftk '+my_dear+param.name4file+'_time*s*2mm.pdf cat output '+my_dear+param.name4file+'_time_2mm_all_scans.pdf'
        spawn, 'rm -rf '+my_dear+param.name4file+'_time*s*2mm.pdf'
        spawn, 'pdftk '+my_dear+param.name4file+'_stddev*s*2mm.pdf cat output '+my_dear+param.name4file+'_stddev_2mm_all_scans.pdf'
        spawn, 'rm -rf '+my_dear+param.name4file+'_stddev*s*2mm.pdf'
        spawn, 'pdftk '+my_dear+param.name4file+'_SNR*s*2mm.pdf cat output '+my_dear+param.name4file+'_SNR_2mm_all_scans.pdf'
        spawn, 'rm -rf '+my_dear+param.name4file+'_SNR*s*2mm.pdf'
        spawn, 'pdftk '+my_dear+param.name4file+'_flux*s*2mm.pdf cat output '+my_dear+param.name4file+'_flux_2mm_all_scans.pdf'
        spawn, 'rm -rf '+my_dear+param.name4file+'_flux*s*2mm.pdf'        

        spawn, 'pdftk '+my_dear+param.name4file+'_*s*_NEFD_all1mm.pdf cat output '+my_dear+param.name4file+'_NEFD_1mm_all_scans.pdf'
        spawn, 'rm -rf '+my_dear+param.name4file+'_*s*_NEFD_all1mm.pdf'
        spawn, 'pdftk '+my_dear+param.name4file+'_*s*_sensitivity_all1mm.pdf cat output '+my_dear+param.name4file+'_sensitivity_1mm_all_scans.pdf'
        spawn, 'rm -rf '+my_dear+param.name4file+'_*s*_sensitivity_all1mm.pdf'

        spawn, 'pdftk '+my_dear+param.name4file+'_*s*_NEFD_all2mm.pdf cat output '+my_dear+param.name4file+'_NEFD_2mm_all_scans.pdf'
        spawn, 'rm -rf '+my_dear+param.name4file+'_*s*_NEFD_all2mm.pdf'
        spawn, 'pdftk '+my_dear+param.name4file+'_*s*_sensitivity_all2mm.pdf cat output '+my_dear+param.name4file+'_sensitivity_2mm_all_scans.pdf'
        spawn, 'rm -rf '+my_dear+param.name4file+'_*s*_sensitivity_all2mm.pdf'

        spawn, 'pdftk '+my_dear+'map_1mm_scan_*.pdf cat output '+my_dear+'map_1mm_all_scans.pdf'
        spawn, 'rm -rf '+my_dear+'map_1mm_scan_*.pdf'
        spawn, 'pdftk '+my_dear+'map_2mm_scan_*.pdf cat output '+my_dear+'map_2mm_all_scans.pdf'
        spawn, 'rm -rf '+my_dear+'map_2mm_scan_*.pdf' 
        spawn, 'pdftk '+my_dear+'check_atm_cm_*.pdf cat output '+my_dear+'check_atm_cm_all_scans.pdf'
        spawn, 'rm -rf '+my_dear+'check_atm_cm*s*.pdf'
        spawn, 'pdftk '+my_dear+'check_flag_corr*.pdf cat output '+my_dear+'check_flag_corr_all_scans.pdf'
        spawn, 'rm -rf '+my_dear+'check_flag_corr*s*.pdf'
        spawn, 'pdftk '+my_dear+'check_flag_speed*.pdf cat output '+my_dear+'check_flag_speed_all_scans.pdf'
        spawn, 'rm -rf '+my_dear+'check_flag_speed*s*.pdf'
        spawn, 'pdftk '+my_dear+'check_corr_matrix*.pdf cat output '+my_dear+'check_corr_matrix_all_scans.pdf'
        spawn, 'rm -rf '+my_dear+'check_corr_matrix*s*.pdf'
        spawn, 'pdftk '+my_dear+'check_TOI_PS*.pdf cat output '+my_dear+'check_TOI_PS_all_scans.pdf'
        spawn, 'rm -rf '+my_dear+'check_TOI_PS*s*.pdf'

        ;;------- Move all pdfs into a common directory
        spawn, 'mkdir '+my_dear+'Figures/'
        spawn, '/bin/mv -f '+my_dear+'*.pdf  '+my_dear+'Figures'

     endfor

  endif
 

  return
end

