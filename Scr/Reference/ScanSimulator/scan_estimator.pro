
;; Generic script to simulate a scan pattern
;;------------------------------------------

nk_default_param, scan_params

;; scan_simulator assumes that the scans are in azel, so we need to
;; assume an elevation to rotate the Nasmyth offsets to azel.
elevation_deg = 45.d0


;;------------------------------------------------
;; Scan parameters

;; HLS:
;; @nkotf 8 5 90 0 20 40 azel
nickname       = "test"
x_width        = 8*60.d0 ; 10*60.d0       ; arcsec
y_width        = 5*60.d0 ; 6.d0*60.d0     ; arcsec
y_step         = 20.d0   ; arcsec
x_speed        = 40.d0          ; arcsec/s

;; GASTON
nickname = "gaston"
x_width = 2.*60.*60.            ; 2 deg in arcsec
y_width = 1.*60.*60.            ; 1 deg in arcsec
y_step  = 0.2*60.*60.; arcsec
x_speed = 60.d0          ; arcsec/s


;;------------------------------------------------
y_speed        = 5.d0 ; 3.5d0/3.       ; arcsec/s (approx, deduced from otf scans)
angle_deg      = 0.d0
source_radius  = 10.d0
n_subscans = round( y_width/y_step)
print, "Nsubscans: ", n_subscans
force = 0

scan_params.decor_cm_dmin = source_radius ; to be passed to mask_source
scan_params = create_struct( scan_params, $
                             "f_sampling", !nika.f_sampling, $
                             "n_subscans", n_subscans, $
                             "x_width", x_width, $
                             "x_speed", x_speed, $
                             "y_step", y_step, $
                             "y_speed", y_speed, $
                             "angle_deg", angle_deg, $
                             "x_offset", 0.d0, $
                             "y_offset", 0.d0, $
                             "elevation_deg", elevation_deg)


;;--------------------------------------------------------------------------------------
t_min_subscan = 12.             ; sec : 10 + 2sec margin for uncertain pointing on each end of the subscans
x_speed_max = x_width/t_min_subscan

if x_speed gt x_speed_max then begin
   message, /info, "t_subscan = x_with/x_speed = "+strtrim(x_width/x_speed,2)+" is smaller than 12."
   message, /info, "For this x_width, x_speed_max = "+strtrim(x_speed_max,2)+" arcsec/s"
   message, /info, "Please change x_speed."
   goto, exit
endif

;; Quick estimate of overall parameters
t_subscan = x_width/scan_params.x_speed
t_tot = n_subscans*t_subscan + (n_subscans-1)*y_step/y_speed
if force eq 0 and t_tot ge (20*60.) then begin
   message, /info, "The estimated duration of this scan is "+strtrim(t_tot/60.,2)+" min"
   message, /info, "You should avoid scans larger than 20-25 min, both for tuning and scan processing"
   message, /info, "set force=1 to ignore this warning and relaunch"
   goto, exit
endif

fmt = "(F6.1)"
xsize_arcmin = scan_params.x_width/60.
ysize_arcmin = scan_params.n_subscans*scan_params.y_step/60.
sequence = strtrim(string(xsize_arcmin,form=fmt),2)+" "+$
                strtrim(string(ysize_arcmin,form=fmt),2)+" "+strtrim( string(angle_deg,format=fmt),2)+" 0 "+$
                strtrim(string(scan_params.y_step,form=fmt),2)+" "+strtrim(string(x_speed,form=fmt),2)+" radec"
pako_sequence = "@nkotf "+sequence
outplot_file = "scan_estimator_"+nickname+"_"+strjoin( strsplit( sequence, " ", /reg, /extr), "_")

;; Which kidpar
;; kidpar = mrdfits( !nika.off_proc_dir+"/kidpar_20160122s80_81_82_noskydip_v1.fits", 1, /silent)
;; kidpar = mrdfits( !nika.off_proc_dir+"/kidpar_20160303s89_90_91_noskydip_v2.fits", 1, /silent)
kidpar = mrdfits( !nika.off_proc_dir+"/kidpar_20161010s37_v3_skd8_match_calib_NP_recal_FR.fits", 1, /silent)

;; Display parameters
scan_params.map_xsize = (2*x_width) > 700
scan_params.map_ysize = scan_params.map_xsize
scan_params.map_reso = 2.d0

;; Launch the sim
scan_params.map_proj = 'radec'
nk_default_info, info
delvarx, grid
scan_simulator, scan_params, scan_obs_time, $
                ofs_x, ofs_y, on_source_frac, kidpar, dra, ddec, $
                grid=grid, info=info, on_source_frac_per_subscan=on_source_frac_per_subscan, $
                ofs_x_min=ofs_x_min, ofs_x_max=ofs_x_max, $
                ofs_y_min=ofs_y_min, ofs_y_max=ofs_y_max, nomaps=nomaps

wkref = where( kidpar.numdet eq !nika.ref_det[1], w)

;;-----------------------------------------

;; Derive sensitivity maps (point source measure, i.e. integrated on a
;; main beam) and some quality stats
input_fwhm = 15.d0              ; does not need to match a beam, it's just to smooth the nhits map
nextend = 5
input_sigma_beam = input_fwhm*!fwhm2sigma
nx_kgauss       = 2*long(nextend*input_sigma_beam/scan_params.map_reso/2)+1
ny_kgauss       = 2*long(nextend*input_sigma_beam/scan_params.map_reso/2)+1
xxg               = dblarr(nx_kgauss, ny_kgauss)
yyg               = dblarr(nx_kgauss, ny_kgauss)
for ii=0, nx_kgauss-1 do xxg[ii,*] = (ii-nx_kgauss/2)*scan_params.map_reso
for ii=0, ny_kgauss-1 do yyg[*,ii] = (ii-ny_kgauss/2)*scan_params.map_reso
kgauss = exp(-(xxg^2+yyg^2)/(2.*input_sigma_beam^2)) ; PSF Gaussian kernel

total_cov = dblarr(2)
avg_center_sensitivity = dblarr(2)
nefd = [30., 10.] ; mJy.s^0.5
levels = [1.d0, 5.d0, 10.d0, 20.d0] ; mJy
nlevels = n_elements(levels)
sensitivity_map = dblarr( 2, grid.nx, grid.ny)
sensitivity_surf = dblarr(2, nlevels)
for iband=0, 1 do begin
   if iband eq 0 then nhits = grid.nhits_1mm else nhits = grid.nhits_2mm
   nhits_smooth = convol( nhits, kgauss)/total(kgauss)
   time_smooth = nhits_smooth/scan_params.f_sampling
   time_per_beam = nhits_smooth/!nika.f_sampling*(!nika.grid_step[iband]/grid.map_reso)^2
   w = where( nhits ne 0, nw)
   total_cov[iband] = nw*(grid.map_reso/60.)^2
   sensitivity = nhits*0.d0
   sensitivity[w] = nefd[iband]/sqrt(time_per_beam[w])
   sensitivity_map[iband,*,*] = sensitivity

   w = where( grid.mask_source eq 0)
   avg_center_sensitivity[iband] = avg( sensitivity[w])
   for ilevel=0, nlevels-1 do begin
      w = where( sensitivity le levels[ilevel] and nhits ne 0, nw)
      if nw ne 0 then sensitivity_surf[iband,ilevel] = nw*(grid.map_reso/60.)^2
   endfor
   
endfor

;; Display
phi = dindgen(360)/359.*2*!dpi
fov_radius = 6.5*60./2.
col_fov = 255
title_list = ['1mm sensitivy (mJy)', '2mm sensitivity (mJy)']
wind, 1, 1, /free, /large
my_multiplot, 2, 2, pp, pp1, /rev
for iband=0, 1 do begin
   imview, reform(sensitivity_map[iband,*,*]), xmap=grid.xmap, ymap=grid.ymap, $
           position=pp1[iband,*], title=title_list[iband], /noerase, $
           imrange=[0, max(levels)]
   oplot, ofs_x_min + fov_radius*cos(phi), ofs_y_min + fov_radius*sin(phi), col=col_fov
   oplot, ofs_x_max + fov_radius*cos(phi), ofs_y_min + fov_radius*sin(phi), col=col_fov
   oplot, ofs_x_min + fov_radius*cos(phi), ofs_y_max + fov_radius*sin(phi), col=col_fov
   oplot, ofs_x_max + fov_radius*cos(phi), ofs_y_max + fov_radius*sin(phi), col=col_fov
endfor

print, "x_speed: "+string(x_speed,format=fmt)+" arcsec/s"
print, "x subscan duration (sec): "+string(t_subscan,format=fmt)
print, "N subscans: ", scan_params.n_subscans
print, "total obs time: "+strtrim(round(t_tot),2)+" sec = "+strtrim( round(t_tot/60.),2)+" mn"
print, "total coverage (1,2 mm) (arcmin^2): ", total_cov
for ilevel=0, nlevels-1 do $
   print, "Fraction of the coverage with sensitivity below "+$
          strtrim(levels[ilevel],2)+" mJy: ", reform(sensitivity_surf[*,ilevel]/total_cov)
print, "average sensitivy in a centered disk of "+strtrim( long(source_radius),2)+" arcsec: ", avg_center_sensitivity












stop
;; 
;; 
;; 
;; 
;; 
;; 
;; 
;; readcol, "source_list.dat", source, ra_list, dec_list, flux1mm, flux2mm, $
;;          delimiter=',', comment="#", format="A,A,A"
;; 
;; nsources = n_elements(source)
;; ra  = dblarr(nsources)
;; dec = dblarr(nsources)
;; flux = dblarr(nsources,2)
;; flux[*,0] = flux1mm
;; flux[*,1] = flux2mm
;; for isource = 0, nsources-1 do begin
;;    r = double(strtrim(strsplit( ra_list[isource], ":", /extract),2))
;;    ra[isource] = (r[0] + r[1]/60.d0 + r[2]/3600.d0)*15.d0
;; 
;;    d = double(strtrim(strsplit( dec_list[isource], ":", /extract),2))
;;    dec[isource] = d[0] + d[1]/60.d0 + d[2]/3600.d0
;; endfor
;; 
;; ;; print, "distance (arcmin): ", sqrt( ((ra1-ra2)*cos(dec1*!dtor))^2 + (dec1-dec2)^2)*60.
;; ;;distance (arcmin):        9.1883972
;; 
;; ;print, "avg(ra): ", avg(ra)
;; ;print, "avg(dec): ", sixty(avg(dec))
;; ;stop
;; 
;; ;; Center around their average for convenience
;; ra  -= avg(ra)
;; dec -= avg(dec)
;; ra  *= 3600.d0                   ; deg2arcsec
;; dec *= 3600.d0
;; 
;; ;;------------------------------------
;; ;; Good strategy for a scan in (ra,dec)
;; isource_center = 0
;; ra  -= ra[isource_center]
;; dec -= avg(dec)
;; x_width  = 6.d0*60.d0         ; arcsec
;; y_width  = 2.d0*60.d0         ; arcsec
;; y_step   = 10.d0
;; x_offset = 0.d0
;; y_offset = 0.d0
;; angle_deg = 0.d0
;; x_speed = 30.d0 ; arcsec/s
;; nickname = source[isource_center]+"_south"
;; 
;; ;; ;;------------------------------------
;; ;; ;; Complementing with orthogonal scan
;; ;; ;; Trying to optimize while keeping the same center to avoid overheads (?)
;; ;; isource_center = 0
;; ;; x_width  = 6.d0*60.d0         ; arcsec
;; ;; y_width  = 4.d0*60.d0         ; arcsec
;; ;; y_step   = 10.d0
;; ;; x_offset = 0.d0
;; ;; y_offset = 0.d0
;; ;; angle_deg = 90.d0
;; ;; x_speed = 30.d0 ; arcsec/s
;; ;; nickname = source[isource_center]+"_south"
;; 
;; 
;; 
;; 
;; y_speed = 3.5d0/3.
;; n_subscans = round(y_width/y_step)
;; 
;; ;; average elevation (place holder)
;; elevation_deg = 0. ; to fake a (ra,dec) coordinates and not include a cos(el)*azimuth
;; 
;; 
;; n_subscans = round(y_width/y_step)
;; nk_default_param, scan_params
;; scan_params.decor_cm_dmin = 10. ; to give an extension to the source
;; scan_params = create_struct( scan_params, $
;;                              "f_sampling" , 23.84d0, $  ; Hz
;;                              "x_width"   , x_width, $ ; 400.d0                 ; arcsec
;;                              "y_step"    , y_step, $  ; arcsec
;;                              "x_offset",   x_offset, $ ; arcsec
;;                              "y_offset",   y_offset, $
;;                              "elevation_deg", elevation_deg, $
;;                              "angle_deg"  , angle_deg, $ ; degrees
;;                              "x_speed"   , x_speed, $   ; arcsec/s
;;                              "y_speed"   , y_speed, $   ; arcsec/s, intersubscan, place holder
;;                              "n_subscans" , n_subscans)
;; 
;; 
;; 
;; ;; Which kidpar
;; ;; kidpar = mrdfits( !nika.off_proc_dir+"/kidpar_20160122s80_81_82_noskydip_v1.fits", 1, /silent)
;; ;; kidpar = mrdfits( !nika.off_proc_dir+"/kidpar_20160303s89_90_91_noskydip_v2.fits", 1, /silent)
;; kidpar = mrdfits( !nika.off_proc_dir+"/kidpar_20161010s37_v3_skd8_match_calib_NP_recal_FR.fits", 1, /silent)
;; ;; Display parameters
;; scan_params.map_xsize = (3*x_width) > 700
;; scan_params.map_ysize = scan_params.map_xsize
;; scan_params.map_reso = 2.d0
;; scan_params.decor_cm_dmin = 5.d0 ; < half a beam at 1mm ; for on_source_frac
;; 
;; ;; Launch the sim
;; scan_params.map_proj = 'radec'
;; nk_default_info, info
;; nk_init_grid, scan_params, info, input_grid
;; delvarx, grid
;; scan_simulator, scan_params, scan_obs_time, $
;;                 ofs_x, ofs_y, on_source_frac, kidpar, dra, ddec, $
;;                 grid=grid, info=info, on_source_frac_per_subscan=on_source_frac_per_subscan, $
;;                 ofs_x_min=ofs_x_min, ofs_x_max=ofs_x_max, $
;;                 ofs_y_min=ofs_y_min, ofs_y_max=ofs_y_max, nomaps=nomaps
;; 
;; print, "x_width: "+string( x_width, format=fmt)
;; print, "y_width: "+string( y_width, format=fmt)
;; print, "y_step: "+string( y_step, format=fmt)
;; print, "angle_deg: "+string( angle_deg, format=fmt)
;; print, "x_speed: "+string(x_speed, format=fmt)
;; print, "tsubscan (sec): "+string(x_width/scan_params.x_speed,format=fmt)+" (must be larger than 10)"
;; print, "n_subscans: " , n_subscans
;; print, "ofs_x_min: ", ofs_x_min
;; print, "ofs_x_max: ", ofs_x_max
;; print, "ofs_y_min: ", ofs_y_min
;; print, "ofs_y_max: ", ofs_y_max
;; total_obs_time = scan_obs_time + n_subscans*y_step/y_speed
;; print, "Obs time for this simulated scan: ", string(total_obs_time,format=fmt)+$
;;        " sec = "+strtrim(string(total_obs_time/60.,format=fmt),2)+" min"
;; 
;; ;; sens_1mm = dblarr(grid.nx, grid.ny)
;; ;; w = where( grid.nhits_1mm ne 0)
;; ;; sens_1mm[w] = info.RESULT_NEFD_CENTER_I_1MM/sqrt( grid.nhits_1mm[w]/!nika.f_sampling)*1e3
;; ;; sens_2mm = dblarr(grid.nx, grid.ny)
;; ;; w = where( grid.nhits_2mm ne 0)
;; ;; sens_2mm[w] = info.RESULT_NEFD_CENTER_I_2MM/sqrt( grid.nhits_2mm[w]/!nika.f_sampling)*1e3
;; 
;; nk_map_photometry, grid.map_i_1mm, grid.map_var_i_1mm, grid.nhits_1mm, $
;;                    grid.xmap, grid.ymap, !nika.fwhm_array[0], $
;;                    map_var_flux=map_var_flux, /edu
;; sens_1mm = sqrt( map_var_flux)*1e3 ; Jy to mJy
;; 
;; nk_map_photometry, grid.map_i_2mm, grid.map_var_i_2mm, grid.nhits_2mm, $
;;                    grid.xmap, grid.ymap, !nika.fwhm_array[0], $
;;                    map_var_flux=map_var_flux, /edu
;; sens_2mm = sqrt( map_var_flux)*1e3 ; Jy to mJy
;; 
;; 
;; ;; Sensitivity at the source locations:
;; source_sensitivity = dblarr(nsources,2)
;; for isource=0, nsources-1 do begin
;;    d = sqrt( (grid.xmap-ra[isource])^2 + (grid.ymap-dec[isource])^2)
;;    w = where( d eq min(d))
;;    source_sensitivity[isource,0] = sens_1mm[w]
;;    source_sensitivity[isource,1] = sens_2mm[w]
;;    print, "Sensitivity on "+source[isource]+": "+$
;;           string( source_sensitivity[isource,0],format=fmt)+" mJy (1mm), "+$
;;           string( source_sensitivity[isource,1],format=fmt)+" mJy (2mm)"
;; endfor
;; 
;; 
;; ;;------------------------------------------------------------------------------------
;; ;; Summary plot
;; radius = 6.5*60.d0/2.
;; phi = dindgen(100)/99.*2*!dpi
;; ymid = 0.5
;; !mamdlib.coltable = 39
;; wind, 1, 1, /free, /large
;; outplot, file=outplot_file, png=png, ps=ps
;; my_multiplot, 2, 1, pp, pp1, /rev, ymin=ymid, ymax=0.9
;; imview, sens_1mm, xmap=grid.xmap, ymap=grid.ymap, title='Sensitivity/beam 1mm', $
;;         position=pp1[0,*], /noerase, imrange=imrange1, units='mJy/beam'
;; oplot, ra, dec, col=255, psym=6
;; ;oplot, ofs_x, ofs_y, col=255
;; oplot, [0], [0], psym=1, col=250, syms=2
;; oplot, min(ofs_x) + radius*cos(phi), min(ofs_y) + radius*sin(phi), col=100
;; oplot, max(ofs_x) + radius*cos(phi), max(ofs_y) + radius*sin(phi), col=100
;; xyouts, ra, dec, strtrim(source,2), col=255, chars=0.8
;; 
;; imview, sens_2mm, xmap=grid.xmap, ymap=grid.ymap, title='Sensitivity/beam 2mm', $
;;         position=pp1[1,*], /noerase, imrange=imrange2, units='mJy/beam'
;; oplot, ra, dec, psym=6, col=255
;; ;oplot, ofs_x, ofs_y, col=255, psym=3
;; oplot, [0], [0], psym=1, col=250, syms=2
;; oplot, min(ofs_x) + radius*cos(phi), min(ofs_y) + radius*sin(phi), col=100
;; oplot, max(ofs_x) + radius*cos(phi), max(ofs_y) + radius*sin(phi), col=100
;; xyouts, ra, dec, strtrim(source,2), col=255, chars=0.8
;; my_multiplot, /reset
;; 
;; nsigma = 3
;; number_of_scans = 0
;; for isource=0, nsources-1 do begin
;;    for ilambda=0, 1 do begin
;;       target_sensitivity = flux[isource,ilambda]/nsigma
;; ;      print, source[isource]+" "+strtrim(ilambda+1,2)+" mm target: ", target_sensitivity
;;       nscans = round(source_sensitivity[isource,ilambda]/target_sensitivity)^2
;;       if nscans gt number_of_scans then number_of_scans = nscans
;;    endfor
;; endfor
;; 
;; tmax = number_of_scans*total_obs_time
;; time_hour = (1.d0 + dindgen( round(tmax)))/3600.d0
;; 
;; xra = [0,3]                    ; hours
;; yra = [0,5]
;; thick=2
;; make_ct, nsources, ct
;; line_lambda = [0,2]
;; my_multiplot, 1, 1, pp, pp1, ymax=ymid*0.8, ymin=0.05
;; plot, minmax(time_hour), [0,5], /xs, /ys, $
;;       xtitle='Total obs. time (hours)', ytitle='Signa to Noise', $
;;       /nodata, xra=xra, yra=yra, position=pp1[0,*], /noerase
;; for isource=0, nsources-1 do begin
;;    for ilambda=0, 1 do begin
;;       oplot, time_hour, flux[isource,ilambda]/source_sensitivity[isource,ilambda]*sqrt(time_hour*3600.d0/total_obs_time), $
;;              col=ct[isource], line=line_lambda[ilambda], thick=thick
;;    endfor
;; endfor
;; for isigma=1,5 do oplot, xra, xra*0 + isigma
;; 
;; col = [0]
;; line = [0]
;; source_txt = ['']
;; for i=0, nsources-1 do begin
;;    col = [col, ct[i], ct[i]]
;;    line = [line, 0, 2]
;;    source_txt = [source_txt, $
;;                  source[i]+" "+string(flux[i,0],format='(F5.2)')+" (1mm)", $
;;                  source[i]+" "+string(flux[i,1],format='(F5.2)')+" (2mm)"]
;; endfor
;; col = col[1:*] & line=line[1:*] & source_txt = source_txt[1:*]
;; legendastro, source_txt, thick=thick, $
;;              col=col, line=line, textcol=col, box=0, /right
;; nseq_approx = 10
;; seq_step = max(xra)*3600.d0/nseq_approx
;; nscans_step = round( seq_step/total_obs_time)
;; nscans_display = (indgen(nseq_approx)+1)*nscans_step
;; xseq = nscans_display*total_obs_time/3600.
;; ;yseq = xseq*0. + max(yra)*0.8
;; ;oplot, xseq, yseq, psym=1
;; ;xyouts, xseq, yseq, strtrim( nscans_display, 2)
;; AXIS, XAXIS=1, XTICKS=nseq_approx-1, XTICKV=nscans_display*total_obs_time/3600., XTICKN=strtrim( nscans_display, 2), $
;;          XTITLE='Number of such scans', XCHARSIZE = 0.7
;; legendastro, ['1 scan duration: '+string(total_obs_time/60.,format='(F4.1)')+" mn", $
;;               pako_sequence], box=0, /right, /bottom
;; outplot, /close



exit:


end




