;+
;PURPOSE: Provide point source photometry centered on given positions
;
;INPUT: A parameter structure containing what you want to compute
;
;OUTPUT: Depends on the param (e.g. profile, flux, ...)
;
;KEYWORDS:
;
;LAST EDITION: 
;   03/10/2013: creation (adam@lpsc.in2p3.fr)
;   08/11/14: fuxes printed in mJy instead of Jy
;   19/06/15: correct a coordinate bug (cos(declinaison) was missing)
;   06/07/15: fit the background within 3 FWHM when position is fixed
;-

pro nika_anapipe_psphoto, param, anapar, $
                          indiv_scan=indiv_scan, $
                          make_logbook=make_logbook, $
                          filtfact=filtfact
  
  mydevice = !d.name

  ;;Distance rescaling of R.A. differences : cos(declinaison)
  ra_corr = cos(ten(param.coord_map.dec[0], $
                    param.coord_map.dec[1], $
                    param.coord_map.dec[2])*!pi/180.0)

  fmt = '(1F10.4)'              ; format for fluxes
  fmta = '(1F10.1)'             ; format for position (arcsec)
  if not keyword_set(indiv_scan) then my_other_name = '' else my_other_name = '_'+param.scan_list[0]

  ;; Filter factor for V1 data release
  if keyword_set(filtfact) then ffi = filtfact else ffi = [1D0, 1D0]

  ;;------- Get the maps
  maps_1mm = mrdfits(param.output_dir+'/MAPS_1mm_'+param.name4file+'_'+param.version+'.fits',4,head_1mm,/SILENT)
  noises_1mm = mrdfits(param.output_dir+'/MAPS_1mm_'+param.name4file+'_'+param.version+'.fits',6,head_1mm,/SILENT)
  maps_2mm = mrdfits(param.output_dir+'/MAPS_2mm_'+param.name4file+'_'+param.version+'.fits',4,head_2mm,/SILENT)
  noises_2mm = mrdfits(param.output_dir+'/MAPS_2mm_'+param.name4file+'_'+param.version+'.fits',6,head_2mm,/SILENT)

  map_1mm = mrdfits(param.output_dir+'/MAPS_1mm_'+param.name4file+'_'+param.version+'.fits',0,head_1mm,/SILENT)
  noise_1mm = mrdfits(param.output_dir+'/MAPS_1mm_'+param.name4file+'_'+param.version+'.fits',2,head_1mm,/SILENT)
  map_2mm = mrdfits(param.output_dir+'/MAPS_2mm_'+param.name4file+'_'+param.version+'.fits',0,head_2mm,/SILENT)
  noise_2mm = mrdfits(param.output_dir+'/MAPS_2mm_'+param.name4file+'_'+param.version+'.fits',2,head_2mm,/SILENT)
  
  EXTAST, head_1mm, astr
  reso = astr.cdelt[1]*3600
  coord_ref = astr.crval        ;coord of ref pixel (deg)
  refpix = astr.crpix           ;reference pixel
  nx = astr.naxis[0]            ;pixel nb along x
  ny = astr.naxis[1]            ;pixel nb along y
  xmap = (dindgen(nx)-nx/2)*reso # replicate(1, ny)
  ymap = (dindgen(ny)-ny/2)*reso ## replicate(1, nx)

  coord_map = coord_ref + [refpix[0]-((nx-1)/2.0+1), -refpix[1]+((ny-1)/2.0+1)]*reso/3600.0

  ;;------- Loop over all centers
  if anapar.ps_photo.method eq 'default' then anapar.ps_photo.nb_source = 1 ;force only 1 ps_photo for default
  
  SET_PLOT, 'PS'
  device,/color, bits_per_pixel=256, filename=param.output_dir+'/'+param.name4file+'_PointSourcePhotoCheckFit.ps'
  for ic=0, anapar.ps_photo.nb_source - 1 do begin

     ;;------- Case of default: only 1 ps_photo centered on [0,0]
     if anapar.ps_photo.method eq 'default' then center0 = [0.0, 0.0]
     
     ;;------- Case of center shift given directly as offsets
     if anapar.ps_photo.method eq 'offset' then center0 = anapar.ps_photo.offset[ic,*]
     
     ;;------- Case of center shift computed from coordinates
     if anapar.ps_photo.method eq 'coord' then begin
        center0 = [(-ten(anapar.ps_photo.coord[ic].ra[0],anapar.ps_photo.coord[ic].ra[1],anapar.ps_photo.coord[ic].ra[2])*15.0 + coord_map[0])*ra_corr, $
                   ten(anapar.ps_photo.coord[ic].dec[0],anapar.ps_photo.coord[ic].dec[1],anapar.ps_photo.coord[ic].dec[2]) - coord_map[1]]*3600.0
     endif

     ;;------- Case of bug
     if anapar.ps_photo.method ne 'coord' and anapar.ps_photo.method ne 'offset' and $
        anapar.ps_photo.method ne 'default'then begin
        message, 'The method is either "coord" (you give the center R.A. Dec. coordinates)'
        message, 'or "offset" (you give the arcsec offset with respect to the map center)'
        message, 'or "default" (only one point source photometry centered on the map center)'
     endif
     
     ;;------- If shift allowed then start from center but find best center
     if anapar.ps_photo.allow_shift eq 'yes' then center = 0 else center = center0 ;no center given

     ;;------- If allowed radius given then set outside map to 0     
     if finite(anapar.ps_photo.search_box[0]) eq 1 and finite(anapar.ps_photo.search_box[1]) eq 1 then begin
        center = center0        ;center keyword is the box center when used with search_box
        search_box = anapar.ps_photo.search_box
     endif

     ;;------- Define where the zero level loc
     var_map1mm = noise_1mm^2
     var_map2mm = noise_2mm^2
     if anapar.ps_photo.allow_shift ne 'yes' and anapar.ps_photo.local_bg eq 'yes' then begin
        rsource = sqrt((xmap-center[0])^2+(ymap-center[1])^2)
        wbg1mm = where(rsource gt 3 * anapar.ps_photo.beam.a, nwbg1mm)
        wbg2mm = where(rsource gt 3 * anapar.ps_photo.beam.b, nwbg2mm)
        if nwbg1mm ne 0 then var_map1mm[wbg1mm] = !values.f_nan
        if nwbg2mm ne 0 then var_map2mm[wbg2mm] = !values.f_nan
     endif
     
     ;;------- Compute the fluxes
     nika_pipe_fit_beam, map_1mm, reso, $
                         coeff=coeff_1mm, best_fit=map_flux_model_a, $
                         var_map=var_map1mm,$
                         /CIRCULAR, center=center, err_coeff=err_coeff_1mm, rchi2=chi2_1mm,$
                         FWHM=anapar.ps_photo.beam.a, search_box=search_box,/silent
     avg_flux_1mm = coeff_1mm[1]
     avg_err_flux_1mm = err_coeff_1mm[1]
     avg_chi2_1mm = chi2_1mm
     avg_loc_1mm = coeff_1mm[4:5]-center0
     
     nika_pipe_fit_beam, map_2mm, reso, $
                         coeff=coeff_2mm, best_fit=map_flux_model_b, $
                         var_map=var_map2mm,$
                         /CIRCULAR, center=center, err_coeff=err_coeff_2mm, rchi2=chi2_2mm, $
                         FWHM=anapar.ps_photo.beam.b, search_box=search_box, /silent
     avg_flux_2mm = coeff_2mm[1]
     avg_err_flux_2mm = err_coeff_2mm[1]
     avg_chi2_2mm = chi2_2mm
     avg_loc_2mm = coeff_2mm[4:5]-center0
     
     !p.multi = [0,3,2]
     dispim_bar, filter_image(map_1mm,fwhm=10.0/reso,/all), /asp, /noc, title='PS'+strtrim(ic,2)+', combined', cr=minmax(filter_image(map_1mm,fwhm=10.0/reso,/all))
     dispim_bar, filter_image(map_flux_model_a,fwhm=10.0/reso,/all), /asp, /noc, cr=minmax(filter_image(map_1mm,fwhm=10.0/reso,/all))
     dispim_bar, filter_image(map_1mm-map_flux_model_a+coeff_1mm[0],fwhm=10.0/reso,/all), /asp, /noc, cr=minmax(filter_image(map_1mm,fwhm=10.0/reso,/all))
     dispim_bar, filter_image(map_2mm,fwhm=10.0/reso,/all), /asp, /noc, cr=minmax(filter_image(map_2mm,fwhm=10.0/reso,/all))
     dispim_bar, filter_image(map_flux_model_b,fwhm=10.0/reso,/all), /asp, /noc, cr=minmax(filter_image(map_2mm,fwhm=10.0/reso,/all))
     dispim_bar, filter_image(map_2mm-map_flux_model_b+coeff_2mm[0],fwhm=10.0/reso,/all), /asp, /noc, cr=minmax(filter_image(map_2mm,fwhm=10.0/reso,/all))
     !p.multi = 0

     ;;------- Idem for all scan
     nb_scan = n_elements(maps_1mm[0,0,*])
     
     flux_scans_1mm = dblarr(nb_scan)
     err_flux_scans_1mm = dblarr(nb_scan)
     chi2_scans_1mm = dblarr(nb_scan)
     loc_scans_1mm = dblarr(nb_scan,2)

     flux_scans_2mm = dblarr(nb_scan)
     err_flux_scans_2mm = dblarr(nb_scan)
     chi2_scans_2mm = dblarr(nb_scan)
     loc_scans_2mm = dblarr(nb_scan,2)

     if anapar.ps_photo.per_scan eq 'yes' then begin
        for iscan=0, nb_scan-1 do begin

           var_map1mm_iscan = noises_1mm[*,*,iscan]^2
           var_map2mm_iscan = noises_2mm[*,*,iscan]^2
           if anapar.ps_photo.allow_shift ne 'yes' and anapar.ps_photo.local_bg eq 'yes' then begin
              if nwbg1mm ne 0 then var_map1mm_iscan[wbg1mm] = !values.f_nan
              if nwbg2mm ne 0 then var_map2mm_iscan[wbg2mm] = !values.f_nan
           endif
           
           nika_pipe_fit_beam, maps_1mm[*,*,iscan], reso, $
                               coeff=coeff_gauss1mm, best_fit=map_flux_model_a, $
                               var_map=var_map1mm_iscan,$
                               /CIRCULAR, center=center, err_coeff=err_coeff_1mm, rchi2=chi2_1mm, $
                               FWHM=anapar.ps_photo.beam.a, search_box=search_box, /silent
           flux_scans_1mm[iscan] = coeff_gauss1mm[1]
           err_flux_scans_1mm[iscan] = err_coeff_1mm[1]
           chi2_scans_1mm[iscan] = chi2_1mm
           loc_scans_1mm[iscan,*] = coeff_gauss1mm[4:5] - center0
           
           nika_pipe_fit_beam, maps_2mm[*,*,iscan], reso, $
                               coeff=coeff_gauss2mm, best_fit=map_flux_model_b, $
                               var_map=var_map2mm_iscan,$
                               /CIRCULAR, center=center, err_coeff=err_coeff_2mm, rchi2=chi2_2mm, $
                               FWHM=anapar.ps_photo.beam.b, search_box=search_box, /silent
           flux_scans_2mm[iscan] = coeff_gauss2mm[1]
           err_flux_scans_2mm[iscan] = err_coeff_2mm[1]
           chi2_scans_2mm[iscan] = chi2_2mm
           loc_scans_2mm[iscan,*] = coeff_gauss2mm[4:5] - center0

           ;;!p.multi = [0,3,2]
           ;;dispim_bar, maps_1mm[*,*,iscan], /asp, /noc,title='PS'+strtrim(ic,2)+', Scan'+strtrim(iscan,2)
           ;;dispim_bar, map_flux_model_a, /asp, /noc
           ;;dispim_bar, maps_1mm[*,*,iscan]-map_flux_model_a, /asp, /noc
           ;;dispim_bar, maps_2mm[*,*,iscan], /asp, /noc
           ;;dispim_bar, map_flux_model_b, /asp, /noc
           ;;dispim_bar, maps_2mm[*,*,iscan]-map_flux_model_b, /asp, /noc
           ;;!p.multi = 0
        endfor

        ;;----- Plot dispersion
        label = indgen(nb_scan)+1
        !p.multi = [0,2,3]
        ploterror, label, flux_scans_1mm, err_flux_scans_1mm, xtitle='Scan label', ytitle='Flux (Jy)', $
                   xstyle=1, /nodata, charsize=1.5, charthick=3, title='1mm', xr=[0,nb_scan+1]
        oploterror, label, flux_scans_1mm, err_flux_scans_1mm, psym=8, col=250, thick=3, ERRTHICK=2, ERRcol=250
        ploterror, label, flux_scans_2mm, err_flux_scans_2mm, xtitle='Scan label', ytitle='Flux (Jy)', $
                   xstyle=1, /nodata, charsize=1.5, charthick=3, title='2mm', xr=[0,nb_scan+1]
        oploterror, label, flux_scans_2mm, err_flux_scans_2mm, psym=8, col=250, thick=3, ERRTHICK=2, ERRcol=250

        plot, label, loc_scans_1mm[*,0], xtitle='Scan label', ytitle='X offset (arcsec)', $
              xstyle=1, /nodata, charsize=1.5, charthick=3, xr=[0,nb_scan+1]
        oplot, label, loc_scans_1mm[*,0], col=250, psym=8, thick=3
        plot, label, loc_scans_2mm[*,0], xtitle='Scan label', ytitle='X offset (arcsec)', $
              xstyle=1, /nodata, charsize=1.5, charthick=3, xr=[0,nb_scan+1]
        oplot, label, loc_scans_2mm[*,0], col=250, psym=8, thick=3

        plot, label, loc_scans_1mm[*,1], xtitle='Scan label', ytitle='Y offset (arcsec)', $
              xstyle=1, /nodata, charsize=1.5, charthick=3, xr=[0,nb_scan+1]
        oplot, label, loc_scans_1mm[*,1], col=250, psym=8, thick=3
        plot, label, loc_scans_2mm[*,1], xtitle='Scan label', ytitle='Y offset (arcsec)', $
              xstyle=1, /nodata, charsize=1.5, charthick=3, xr=[0,nb_scan+1]
        oplot, label, loc_scans_2mm[*,1], col=250, psym=8, thick=3
        !p.multi = 0

        print,'================== Point source photometry dispersion ========================'
        print, '====== Flux 1mm: '+strtrim(stddev(flux_scans_1mm)/mean(flux_scans_1mm)*100,2)+'%'
        print, '====== Flux 2mm: '+strtrim(stddev(flux_scans_2mm)/mean(flux_scans_2mm)*100,2)+'%'
        print, '====== Offs 1mm: '+strtrim(stddev(sqrt(loc_scans_1mm[*,0]^2 + loc_scans_1mm[*,1]^2)),2)+' arcsec'
        print, '====== Offs 2mm: '+strtrim(stddev(sqrt(loc_scans_2mm[*,0]^2 + loc_scans_2mm[*,1]^2)),2)+' arcsec'
     endif

     ;;------ R.A. Dec. coordinates given
     ra = SIXTY((coord_map[0] - center0[0]/3600.0/ra_corr)/15.0)
     dec = SIXTY(coord_map[1] + center0[1]/3600.0)

     ;;------- Print the results
     print, '----------------------------------------------'
     print, '--- Given center [R.A., Dec.] = ['+trim(ra[0],2)+' h '+trim(ra[1],2)+' m '+trim(ra[2],2)+' s,  '+$
            trim(dec[0],2)+' deg '+trim(dec[1],2)+' arcmin '+trim(dec[2],2)+' arcsec]'
     print, '----------------------------------------------'
     print, '--- Flux found at 1mm (uncorrected for filtering) ---'
     print, 'Average map flux:'
     print, '   '+string(1e3*avg_flux_1mm, format = fmt)+' mJy  +/- '+$
            string(avg_err_flux_1mm*1e3, format = fmt)+ $
            ' (stat.)    with chi2 = '+ $
            string(avg_chi2_1mm, format = fmt)+$
            '   found at ['+ $
            string(avg_loc_1mm[0], format = fmta)+','+ $
            string(avg_loc_1mm[1], format = fmta)+ $
            '] arcsec from the given center'
     if anapar.ps_photo.per_scan eq 'yes' then begin
        flux1mm_moy = mean(flux_scans_1mm)
        err1mm_moy = stddev(flux_scans_1mm)/sqrt(n_elements(flux_scans_1mm))

        print, 'Flux moyen +/- disp./racine(N):'
        print, '   '+string(flux1mm_moy*1e3,  format = fmt)+' mJy +/-'+string(err1mm_moy*1e3,  format = fmt)
        print, 'Flux per scan:'
        print, '   '+string(flux_scans_1mm*1e3,  format = fmt)+' mJy'
        print, 'Erreur per scan (stat.):'
        print, '   '+string(err_flux_scans_1mm*1e3,  format = fmt)+' mJy'
        print, 'Reduced chi2:'
        print, '   '+string(chi2_scans_1mm,  format = fmt)
        print, 'Shift along x from the given position'
        print, '   '+string(loc_scans_1mm[*,0], format = fmta)+' arcsec'
        print, 'Shift along y from the given position'
        print, '   '+string(loc_scans_1mm[*,1],  format = fmta)+' arcsec'
     endif

     print, '--- Flux found at 2mm (uncorrected for filtering) ---'
     print, 'Average map flux:'
     print, '   '+string(avg_flux_2mm*1e3,  format = fmt)+' mJy  +/- '+$
            string(avg_err_flux_2mm*1e3, format = fmt)+' (stat.)    with chi2 = '+string(avg_chi2_2mm, format = fmt)+$
            '   found at ['+string(avg_loc_2mm[0], format = fmta)+','+ $
            string(avg_loc_2mm[1], format = fmta)+ $
            '] arcsec from the given center'
     if anapar.ps_photo.per_scan eq 'yes' then begin
        flux2mm_moy = mean(flux_scans_2mm)
        err2mm_moy = stddev(flux_scans_2mm)/sqrt(n_elements(flux_scans_2mm))

        print, 'Flux moyen +/- disp./racine(N):'
        print, '   '+string(flux2mm_moy*1e3,  format = fmt)+' mJy +/-'+string(err2mm_moy*1e3,  format = fmt)
        print, 'Flux per scan:'
        print, '   '+string(flux_scans_2mm*1e3,  format = fmt)+' mJy'
        print, 'Erreur per scan (stat.):'
        print, '   '+string(err_flux_scans_2mm*1e3,  format = fmt)+' mJy'
        print, 'Reduced chi2:'
        print, '   '+string(chi2_scans_2mm,  format = fmt)
        print, 'Shift along x from the given position'
        print, '   '+string(loc_scans_2mm[*,0],  format = fmta)+' arcsec'
        print, 'Shift along y from the given position'
        print, '   '+string(loc_scans_2mm[*,1],  format = fmta)+' arcsec'
     endif
     print, '----------------------------------------------'

     if keyword_set(make_logbook) then begin
        file = param.output_dir+'/flux_source_'+strtrim(ic,2)+'.csv'
        openw,1,file
        printf, 1, ' Scan Number, '+' Source, '+' RA, '+' DEC, '+' F1mm, '+' Error F1mm, '+' Off_x 1mm, '+' Off_y 1mm, '+' Chi2/NDF 1mm, '+' F2mm, '+' Error F2mm, '+' Off_x 2mm, '+' Off_y 2mm, '+' Chi2/NDF 2mm '

        for iscan=0, nb_scan-1 do begin
           printf, 1, strtrim(param.scan_list[iscan],2)+', '+ $
                   param.source+', '+$
                   trim(ra[0],2)+'h'+trim(ra[1],2)+'m'+trim(ra[2],2)+'s'+', '+$
                   trim(dec[0],2)+'deg'+trim(dec[1],2)+'arcmin'+trim(dec[2],2)+'arcsec'+', '+$
                   strtrim(flux_scans_1mm[iscan]*1e3/ffi[0],2)+', '+ $
                   strtrim(err_flux_scans_1mm[iscan]*1e3/ffi[0],2)+', '+ $
                   strtrim(loc_scans_1mm[iscan,0],2)+', '+ $
                   strtrim(loc_scans_1mm[iscan,1],2)+', '+ $
                   strtrim(chi2_scans_1mm[iscan,0],2)+', '+ $
                   strtrim(flux_scans_2mm[iscan]*1e3/ffi[1],2)+', '+ $
                   strtrim(err_flux_scans_2mm[iscan]*1e3/ffi[1],2)+', '+ $
                   strtrim(loc_scans_2mm[iscan,0],2)+', '+ $
                   strtrim(loc_scans_2mm[iscan,1],2)+', '+ $
                   strtrim(chi2_scans_2mm[iscan,0],2)     
        endfor

        printf, 1, 'Combined, '+ $
                param.source+ ', '+$
                trim(ra[0],2)+'h'+trim(ra[1],2)+'m'+trim(ra[2],2)+'s'+', '+$
                trim(dec[0],2)+'deg'+trim(dec[1],2)+'arcmin'+trim(dec[2],2)+'arcsec'+', '+$
                strtrim(avg_flux_1mm*1d3/ffi[0],2)+', '+ $
                strtrim(avg_err_flux_1mm*1d3/ffi[0],2)+', '+ $
                strtrim(avg_loc_1mm[0],2)+', '+ $
                strtrim(avg_loc_1mm[1],2)+', '+ $
                strtrim(avg_chi2_1mm,2)+', '+ $
                strtrim(avg_flux_2mm*1d3/ffi[1],2)+', '+ $
                strtrim(avg_err_flux_2mm*1d3/ffi[1],2)+', '+ $
                strtrim(avg_loc_2mm[0],2)+', '+ $
                strtrim(avg_loc_2mm[1],2)+', '+ $
                strtrim(avg_chi2_2mm,2)     
        close,1

        file = param.output_dir+'/flux_source_'+strtrim(ic,2)+'.txt'
        openw,1,file
        printf, '1', '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%'
        printf, '1', 'R.A.', trim(ra[0],2)+' h '+trim(ra[1],2)+' m '+trim(ra[2],2)+' s'
        printf, '1', 'Dec.', trim(dec[0],2)+' deg '+trim(dec[1],2)+' arcmin '+trim(dec[2],2)+' arcsec'
        printf, '1', '================================================================'
        printf, '1', '===== 1.25 mm channel ====='
        printf, '1', '----- Averaged map: '
        printf, '1', '---------- Flux = '+strtrim(avg_flux_1mm*1e3/ffi[0])+' mJy  +/- '+strtrim(avg_err_flux_1mm*1e3/ffi[0],2)+' (stat.)'
        if anapar.ps_photo.per_scan eq 'yes' then $
           printf, '1', '---------- Flux moyen +/- disp./sqrt(N) = '+$
                   string(flux1mm_moy*1e3/ffi[0], format=fmt)+' mJy +/-'+string(err1mm_moy*1e3/ffi[0], format=fmt)

        printf, '1', '---------- Reduced chi2 = '+strtrim(avg_chi2_1mm,2)
        printf, '1', '---------- Offset = ['+strtrim(avg_loc_1mm[0],2)+','+strtrim(avg_loc_1mm[1],2)+'] arcsec from the center'
        printf, '1', '===== 2.05 mm channel ====='
        printf, '1', '----- Averaged map: '
        printf, '1', '---------- Flux = '+strtrim(avg_flux_2mm*1e3/ffi[1])+' mJy  +/- '+strtrim(avg_err_flux_2mm*1e3/ffi[1],2)+' (stat.)'
        if anapar.ps_photo.per_scan eq 'yes' then $
           printf, '1', '---------- Flux moyen +/- disp./sqrt(N) = '+$
                   string(flux2mm_moy*1e3/ffi[1], format=fmt)+' mJy +/-'+string(err2mm_moy*1e3/ffi[1], format=fmt)
        
        printf, '1', '---------- Reduced chi2 = '+strtrim(avg_chi2_2mm,2)
        printf, '1', '---------- Offset = ['+strtrim(avg_loc_2mm[0],2)+','+strtrim(avg_loc_2mm[1],2)+'] arcsec from the center'
        close,1

     endif 

  endfor

  device,/close
  ps2pdf_crop, param.output_dir+'/'+param.name4file+'_PointSourcePhotoCheckFit'
  set_plot, mydevice

  return
end
