

;; Script to monitor the flux of source vs time, azimuth, elevation,
;; opacity
;;
;; This script takes result from reduce_all_n2r9 (see the project_dir
;; definition in there).
;;--------------------------------------------------------------------------

pro flux_monitoring_all, project_dir, source_list, tau_max_1mm=tau_max_1mm, $
                         png=png, ps=ps, output_plot_dir=output_plot_dir, combined=combined, $
                         rz=rz

;; I leave these two guys hardcode here, see reduce_all_n2r9
run = 'N2R9'

if not keyword_set(output_plot_dir) then output_plot_dir = "."
spawn, "mkdir -p output_plot_dir"

if not keyword_set(png) then png = 0
if not keyword_set(ps)  then ps  = 0

;; Init arrays
nsources = n_elements(source_list)
nscans = 0
for isource=0, nsources-1 do begin
   source = source_list[isource]
   spawn, "ls -d "+project_dir+"/"+str_replace(source," ", "_")+"/v_1/*", list
   list = file_basename(list)
   for iscan=0, n_elements(list)-1 do begin
      if file_test( project_dir+"/"+str_replace(source," ", "_")+"/v_1/"+list[iscan]+"/results.save") then begin
         if nscans eq 0 then begin
            scan_list   = list[iscan]
         endif else begin
            scan_list = [scan_list, list[iscan]]
         endelse
         nscans++
      endif
   endfor
endfor

;; Match Robert's list:
if keyword_set(rz) then begin
   readcol, !nika.pipeline_dir+"/Scr/Reference/Photometry/ar1forGEsel.LIST", imbfitslist, format='A'
   nn = n_elements(imbfitslist)
   rz_scan_list = strarr(nn)
   l1 = strlen('iram30m-NIKA-1-')
   for i=0, nn-1 do begin
      ll = strlen(imbfitslist[i])
      rz_scan_list[i] = strmid( imbfitslist[i], l1,ll-l1-9)
   endfor
   my_match, scan_list, rz_scan_list, suba, subb
   scan_list = scan_list[suba]
   nscans = n_elements(scan_list)
   print, "after RZ match, nscans = ", nscans
   if nscans eq 0 then begin
      message, /info, "No scan on Robert's list matches scan_list"
      stop
   endif
endif

;; To be improved
if keyword_set(combined) then begin
   nscans = 21 ; CERES + VESTA
endif
scan_source  = strarr(nscans)
elevation    = dblarr(nscans)
tau_res      = dblarr(3,nscans)
flux_res     = dblarr(3,3,nscans)
fwhm_res     = dblarr(3,nscans)
err_flux_res = dblarr(3,3,nscans)
flux_method  = ['FixedFWHM', 'ApPhot', 'FreeFWHM']
all_scans    = strarr(nscans)
keep = lonarr(nscans)
if keyword_set(combined) then begin

   fits_file_list = strarr(nscans)
   for i=0, 3 do begin
      fits_file_list[i] = project_dir+"/BODY_Ceres/MAPS_Ceres_"+strtrim(i,2)+".fits"
      scan_source[i] = "BODY_Ceres"
   endfor
   for i=0, 16 do begin
      fits_file_list[i+4] = project_dir+"/BODY_Vesta/MAPS_Vesta_"+strtrim(i,2)+".fits"
      scan_source[i+4] = "BODY_Vesta"
   endfor

   for p=0, nscans-1 do begin
      fits_file = fits_file_list[p]
      message, /info, fits_file
      nk_fits2grid, fits_file, grid
      aux = mrdfits( fits_file, 18)
      nk_default_param, param
      delvarx, info
      aperture_phot = 1
      param.aperture_photometry_zl_rmin = 100.d0
      param.aperture_photometry_zl_rmax = 200.d0
      param.aperture_photometry_rmeas = 150.d0
      param.aperture_photometry_binwidth = 5
      nk_grid2info, grid, info, /edu, param=param, aperture_phot=aperture_phot
      message, /info, "p = "+strtrim(p,2)

;      read, "keep: 1 or 0", kk
;      keep[p] = kk
      
      ;; Re-estimate err_flux
      if !db.lvl eq 2 then begin
         xcenter = 0
         ycenter = 0
         rmin_err = 60.
         aphot, grid.map_i1, grid.map_var_i1, grid.xmap, grid.ymap, grid.map_reso, xcenter, ycenter, $
                param.aperture_photometry_rmeas, rmin_err, $
                param.aperture_photometry_zl_rmax, param.aperture_photometry_binwidth, $
                12.5, flux, err_flux, int_rad, phi, err_phi
         info.result_aperture_photometry_I1 = stddev( err_phi[where(int_rad ge rmin_err and $
                                                                    int_rad le param.aperture_photometry_zl_rmax)])
         
         aphot, grid.map_i2, grid.map_var_i2, grid.xmap, grid.ymap, grid.map_reso, xcenter, ycenter, $
                param.aperture_photometry_rmeas, rmin_err, $
                param.aperture_photometry_zl_rmax, param.aperture_photometry_binwidth, $
                18.5, flux, err_flux, int_rad, phi, err_phi
         info.result_aperture_photometry_I2 = stddev( err_phi[where(int_rad ge rmin_err and $
                                                                    int_rad le param.aperture_photometry_zl_rmax)])
         
         aphot, grid.map_i3, grid.map_var_i3, grid.xmap, grid.ymap, grid.map_reso, xcenter, ycenter, $
                param.aperture_photometry_rmeas, rmin_err, $
                param.aperture_photometry_zl_rmax, param.aperture_photometry_binwidth, $
                12.5, flux, err_flux, int_rad, phi, err_phi
         info.result_aperture_photometry_I3 = stddev( err_phi[where(int_rad ge rmin_err and $
                                                                    int_rad le param.aperture_photometry_zl_rmax)])
      endif

      ;; fixed fwhm gauss flux
      flux_res[0,0,p]     = info.result_flux_I1
      flux_res[0,1,p]     = info.result_flux_I2
      flux_res[0,2,p]     = info.result_flux_I3
      err_flux_res[0,0,p] = info.result_err_flux_I1
      err_flux_res[0,1,p] = info.result_err_flux_I2
      err_flux_res[0,2,p] = info.result_err_flux_I3
      
      flux_res[1,0,p]     = info.result_aperture_photometry_I1
      flux_res[1,1,p]     = info.result_aperture_photometry_I2
      flux_res[1,2,p]     = info.result_aperture_photometry_I3
      err_flux_res[1,0,p] = info.result_err_aperture_photometry_I1
      err_flux_res[1,1,p] = info.result_err_aperture_photometry_I2
      err_flux_res[1,2,p] = info.result_err_aperture_photometry_I3
      
      flux_res[2,0,p]     = info.result_peak_1
      flux_res[2,1,p]     = info.result_peak_2
      flux_res[2,2,p]     = info.result_peak_3

      fwhm_res[0,p] = info.result_fwhm_1
      fwhm_res[1,p] = info.result_fwhm_2
      fwhm_res[2,p] = info.result_fwhm_3
         
      elevation[p] = aux.el
      tau_res[0,p] = aux.TAU_260GHZ_AVG
      tau_res[1,p] = aux.TAU_150GHZ_AVG
      tau_res[2,p] = aux.TAU_260GHZ_AVG
   endfor

   
endif else begin

;;    p = 0
;;    for isource=0, nsources-1 do begin
;;       source = source_list[isource]
;;       spawn, "ls -d "+project_dir+"/"+str_replace(source," ", "_")+"/v_1/*", scan_list
;;       scan_list = file_basename(scan_list)
;;   for iscan=0, n_elements(scan_list)-1 do begin
   for iscan=0, nscans-1 do begin
      csv_file = project_dir+"/"+str_replace(source," ", "_")+"/v_1/"+scan_list[iscan]+"/photometry.csv"
;;         if file_test( csv_file) then begin
      nk_read_csv, csv_file, str

;;      print, "atm_quality: "
;;      print, str.atm_quality_1, str.atm_quality_2, str.atm_quality_3
;;      print, "scan quality: "
;;      print, str.scan_quality_1, str.scan_quality_2, str.scan_quality_3
;;      stop
      
      all_scans[  iscan] = scan_list[iscan]
      scan_source[iscan] = source
      
      ;; fixed fwhm gauss flux
      flux_res[0,0,iscan]     = str.flux_I1
      flux_res[0,1,iscan]     = str.flux_I2
      flux_res[0,2,iscan]     = str.flux_I3
      err_flux_res[0,0,iscan] = str.err_flux_I1
      err_flux_res[0,1,iscan] = str.err_flux_I2
      err_flux_res[0,2,iscan] = str.err_flux_I3
      
      flux_res[1,0,iscan]     = str.aperture_photometry_I1
      flux_res[1,1,iscan]     = str.aperture_photometry_I2
      flux_res[1,2,iscan]     = str.aperture_photometry_I3
      err_flux_res[1,0,iscan] = str.err_aperture_photometry_I1
      err_flux_res[1,1,iscan] = str.err_aperture_photometry_I2
      err_flux_res[1,2,iscan] = str.err_aperture_photometry_I3
      
      flux_res[2,0,iscan]     = str.peak_1
      flux_res[2,1,iscan]     = str.peak_2
      flux_res[2,2,iscan]     = str.peak_3
;   err_beam_flux_res[0,iscan] = str.err_peak_1
;   err_beam_flux_res[1,iscan] = str.err_peak_2
;   err_beam_flux_res[2,iscan] = str.err_peak_3

      fwhm_res[0,iscan] = str.fwhm_1
      fwhm_res[1,iscan] = str.fwhm_2
      fwhm_res[2,iscan] = str.fwhm_3
      
      elevation[iscan] = str.elevation_deg
      tau_res[0,iscan] = str.tau_1mm
      tau_res[1,iscan] = str.tau_2mm
      tau_res[2,iscan] = str.tau_1mm
;;         endif
;;      endfor
   endfor
endelse

;; EMIR's theoretical curves (old version in the pipeline)
elev_deg = dindgen(90) + 1
freqs_ghz = !const.c/(!nika.lambda*1e-3) * 1d-9
elmax1mm = 1.567E-06 * freqs_ghz[0]^3 -1.233E-03 * freqs_ghz[0]^2 + 3.194E-01 * freqs_ghz[0] + 2.203E+01
elmax2mm = 1.567E-06 * freqs_ghz[1]^3 -1.233E-03 * freqs_ghz[1]^2 + 3.194E-01 * freqs_ghz[1] + 2.203E+01
rms_El         = 2.5523E-02 * elev_deg^2 - 2.5534 * elev_deg + 1.1937E+02
Aeff0_El       = 8.8466E-06 * elev_deg^2 - 1.2523E-03 * elev_deg + 6.9608E-01
rms_Elmax1mm   = 2.5523E-02 * elmax1mm^2 - 2.5534 * elmax1mm + 1.1937E+02
Aeff0_Elmax1mm = 8.8466E-06 * elmax1mm^2 - 1.2523E-03 * elmax1mm + 6.9608E-01
rms_Elmax2mm   = 2.5523E-02 * elmax2mm^2 - 2.5534 * elmax2mm + 1.1937E+02
Aeff0_Elmax2mm = 8.8466E-06 * elmax2mm^2 - 1.2523E-03 * elmax2mm + 6.9608E-01

Aeff_El1mm    = Aeff0_EL * exp(-(4*!dpi*rms_el*1d-3/!nika.lambda[0])^2)
Aeff_El2mm    = Aeff0_EL * exp(-(4*!dpi*rms_el*1d-3/!nika.lambda[1])^2)
Aeff_Elmax1mm = Aeff0_ELmax1mm * exp(-(4*!dpi*rms_elmax1mm*1d-3/!nika.lambda[0])^2)
Aeff_Elmax2mm = Aeff0_ELmax2mm * exp(-(4*!dpi*rms_elmax2mm*1d-3/!nika.lambda[1])^2)

emir_tel_gain_1mm = Aeff_El1mm / Aeff_Elmax1mm
emir_tel_gain_2mm = Aeff_El2mm / Aeff_Elmax2mm

;; 
;; ;;------- Gain correction
;; if keyword_set(undo) then begin ; for simulations
;;    if nw1mm ne 0 then data.toi[w1mm] *= G1mm
;;    if nw2mm ne 0 then data.toi[w2mm] *= G2mm
;; endif else begin
;;    if nw1mm ne 0 then data.toi[w1mm] /= G1mm
;;    if nw2mm ne 0 then data.toi[w2mm] /= G2mm
;; endelse


;; wind, 1, 1, /free, /large
;; my_multiplot, 1, 3, pp, pp1, /rev
;; bin = 0.05
;; for iarray=1, 3 do np_histo, reform(flux_res[0,iarray-1,*]), bin=bin, position=pp1[iarray-1,*], /noerase
;; stop

;; ;; ;;---------------------------
;; ;; junk = where( elevation lt 35, njunk)
;; isource = 0
;; junk = where( scan_source eq source_list[isource],njunk)
;; ;wind, 1, 1, /free, /large
;; my_multiplot, 1, 1, pp, pp1, /rev, ntot=njunk
;; imrange = [-1,1]*0.1
;; aphot_res = dblarr(nscans)
;; keep = lonarr(nscans)
;; for ijunk=0, njunk-1 do begin
;;    wind, 1, 1, /free
;;    iscan = junk[ijunk]
;;    file = project_dir+"/"+str_replace(source," ", "_")+"/v_1/"+scan_list[iscan]+"/results.save"
;;    if file_test(file) then begin
;;       restore, file
;; ;      imview, grid1.map_i1, xmap=grid1.xmap, ymap=grid1.ymap, position=pp1[ijunk,*], /noerase, $
;; ;              imrange=imrange
;; 
;;       radius_meas   = 60 ; 50
;;       radius_bg_min = 80 ; 90 ; 50
;;       radius_bg_max = 120 ; 100
;;       aphot, grid1.map_i1, grid1.map_var_i1, grid1.xmap, grid1.ymap, grid1.map_reso, $
;;              0, 0, radius_meas, radius_bg_min, radius_bg_max, 5., 18., flux, err_flux, imrange=[-1.,1.]*0.1, $
;;              title=scan_list[iscan]
;;       aphot_res[iscan] = flux
;; ;      read, "keep 1, leave 0: ", k
;; ;      keep[iscan] = k
;; ;      stop
;;    endif
;; endfor
;; ;print, "avg(flux_res[0,0,junk]): ", strtrim(avg(flux_res[0,0,junk]),2)+" +- "+strtrim( stddev(flux_res[0,0,junk])/avg(flux_res[0,0,junk]),2)
;; ;print, "avg(aphot) : ", strtrim(avg(aphot_res),2)+" +- "+strtrim( stddev(aphot_res)/avg(aphot_res), 2)
;; ;stop
;; restore, "keep.save"
;; 
;; stop
;; ;; ;;---------------------------

if not keyword_set(tau_max_1mm) then tau_max_1mm = 0.3
deg = 2
col_fit = 0
ifm = 0                         ; 1 ; 0 ; flux_method
if !db.lvl ge 1 then ifm = 1

if !db.lvl eq 3 then begin
   ifm = 0
   restore, "keep.save"
   tau_res[0,where(keep eq 0)] = 1.
endif


yra = [0.8,1.2] ; [0.8, 1.2]
xra = [10,90]
make_ct, nsources, ct

;; ;; Build error bars based on the flux dispersion at a given opacity
;; tau_bin = 0.05
;; for isource=0, nsources-1 do begin
;;    wsource = where( scan_source eq source_list[isource], nwsource)
;;    mytau = reform( tau_res[0,wsource])
;;    for iarray=1, 3 do begin
;;       myflux = flux_res[ifm,iarray-1,wsource]
;;       myerrflux = myflux*0.d0
;;       tau1 = (mytau-min(mytau))/tau_bin
;;       h = histogram( mytau, bin=tau_bin, reverse_ind=R)
;;       for i=0, n_elements(h)-1 do begin
;;          IF R[i] NE R[i+1] THEN begin
;;             myerrflux[R[R[I] : R[i+1]-1]] = stddev( myflux[R[R[I] : R[i+1]-1]])
;;          endif
;;       endfor
;;       err_flux_res[ifm,iarray-1,wsource] = myerrflux
;;    endfor
;; endfor

;; Normalize all fluxes
for isource=0, nsources-1 do begin
   wsource = where( scan_source eq source_list[isource], nwsource)
   wref = where( scan_source eq source_list[isource] and abs(elevation-60) lt 5 and $
                 tau_res[0,*] le tau_max_1mm)
   for iarray=1, 3 do begin
      flux_ref = avg(flux_res[ifm,iarray-1,wref])
      flux_res[    ifm,iarray-1,wsource] /= flux_ref
      err_flux_res[ifm,iarray-1,wsource] /= flux_ref
   endfor
endfor

;;------------------------------
;; ;; Plot all results vs time
;; wind, 1, 1, /free, /large
;; my_multiplot, 1, 3, pp, pp1, /rev, gap_y=0.05
;; !p.charsize = 0.6
;; for iarray=1, 3 do begin
;;    for isource=0, nsources-1 do begin
;;       w = where( scan_source eq source_list[isource], nw)
;;       if nw ne 0 then begin
;;          scan_list = all_scans[w]
;;          day_list = lonarr(nw)
;;          num_list = lonarr(nw)
;;          for is=0, nw-1 do begin
;;             scan2daynum, scan_list[is], day, num
;;             day_list[is] = long(day)
;;             num_list[is] = long(num)
;;          endfor
;;          mynum = double(day_list)*1000 + num_list
;;          order = sort(mynum)
;;          scan_list = scan_list[order]
;; 
;;          flux     = flux_res[     ifm,iarray-1,w[order]]
;;          err_flux = err_flux_res[ ifm,iarray-1,w[order]]
;;          tau      = tau_res[                   w[order]]
;; 
;;          if isource eq 0 then begin
;;             plot, flux, psym=4, xtitle='Scan index', ytitle='Flux (Jy)', $
;;                   position=pp1[iarray-1,*], /noerase
;;             legendastro, 'A'+strtrim(iarray,2)
;;          endif
;;          oplot, flux, psym=1, col=ct[isource]
;;       
;;          w1 = where( tau le tau_max_1mm, nw1)
;;          if nw1 ne 0 then oplot, [w1], flux[w1], psym=5, col=ct[isource]
;;       endif
;;       legendastro, source_list, textcol=ct
;;       legendastro, [flux_method[ifm], "Array "+strtrim(iarray,2)], /right
;;    endfor
;; endfor
;; stop
;;------------------------------

;; Plot and fit
if ps eq 0 then wind, 1, 1, /free, /large
help, png, ps
stop
outplot, file=project_dir+"/gain_elevation_tau", png=png, ps=ps
my_multiplot, 2, 3, pp, epp1, /rev, gap_y=0.01, ymargin=0.05
!p.charsize = 0.6
for iarray=1, 3 do begin
   if iarray eq 3 then xtitle='Elevation (deg)' else delvarx, xtitle
   plot, elevation, flux_res[ifm,iarray-1,*], /nodata, $
         xtitle=xtitle, ytitle='Source Flux / avg( Source flux)', yra=yra, /ys, $
         position=pp[0,iarray-1,*], /noerase, xra=xra, /xs
   oplot, [-1, 100], [1,1], line=2

   if iarray eq 1 or iarray eq 3 then oplot, elev_deg, emir_tel_gain_1mm, col=100 else oplot, elev_deg, emir_tel_gain_2mm, col=100

   el_fit = dindgen(100)
   w = where( tau_res[0,*] le tau_max_1mm, nw)
   fit = poly_fit(elevation[w], flux_res[ifm,iarray-1,w], deg, measure_err=err_flux_res[ifm,iarray-1,w], chisq=chisq)
   yfit = el_fit*0.d0
   for i=0, deg do yfit += fit[i]*el_fit^i
   oplot, el_fit, yfit, thick=2
   nddl = nw-(deg+1)
   xyouts, 40, 1.1 + 0.03*2, "Red. Chisq = "+strtrim(chisq/nddl,2)

   for isource=0, nsources-1 do begin
      w = where( scan_source eq source_list[isource], nw)
      if !db.lvl ge 2 then w = where( scan_source eq source_list[isource] and $
                                             err_flux_res[ifm,iarray-1,*]/flux_res[ifm,iarray-1,*] le 0.2, nw)
      if nw ne 0 then begin
         oplot, elevation[w], flux_res[ifm,iarray-1,w], psym=1, col=ct[isource]
         oploterror, elevation[w], flux_res[ifm,iarray-1,w], err_flux_res[ifm,iarray-1,w], errcol=ct[isource], psym=1
         w1 = where( scan_source eq source_list[isource] and $
                     tau_res[0,*] le tau_max_1mm, nw1)
         if !db.lvl ge 2 then w1 = where( scan_source eq source_list[isource] and $
                                                 tau_res[0,*] le tau_max_1mm and $
                                                 err_flux_res[ifm,iarray-1,*]/flux_res[ifm,iarray-1,*] le 0.2, nw1)
         if nw1 ne 0 then begin
            oplot, elevation[w1], flux_res[ifm,iarray-1,w1], psym=5, col=ct[isource], thick=2
            fit = poly_fit(elevation[w1], flux_res[ifm,iarray-1,w1], deg, measure_err=err_flux_res[ifm,iarray-1,w1], chisq=chisq)

            yfit = el_fit*0.d0
            yth = elevation[w1]*0.d0
            for i=0, deg do begin
               yfit += fit[i]*el_fit^i
               yth[i] += fit[i]*elevation[w1[i]]
            endfor
            oplot, el_fit, yfit, col=ct[isource], thick=1
            legendastro, ['','',string(reform(fit),form='(F7.4)')], textcol=col_fit
            nddl = nw1-(deg+1)
            xyouts, 40, 1.1 + 0.03*isource, "Red. Chisq = "+strtrim(chisq/nddl,2), col=ct[isource]
         endif
      endif
      legendastro, source_list, textcol=ct
      legendastro, [flux_method[ifm], "Array "+strtrim(iarray,2)], /right
   endfor
endfor

xra = [0, max(tau_res)]*1.1
for iarray=1, 3 do begin
   if iarray eq 3 then xtitle='Opacity' else delvarx, xtitle
   plot, tau_res[iarray-1,*], flux_res[ifm,iarray-1,*], /nodata, $
         xtitle=xtitle, ytitle='Source Flux / avg( Source flux)', yra=yra, /ys, $
         position=pp[1,iarray-1,*], /noerase, xra=xra, /xs
   oplot, [-1, 100], [1,1]
   for isource=0, nsources-1 do begin
      w = where( scan_source eq source_list[isource], nw)
      if nw ne 0 then begin
         oplot, tau_res[iarray-1,w], flux_res[ifm,iarray-1,w], psym=1, col=ct[isource]
      endif
      w = where( scan_source eq source_list[isource] and tau_res[0,*] le tau_max_1mm, nw)
      if nw ne 0 then oplot, tau_res[iarray-1,w], flux_res[ifm,iarray-1,w], psym=5, col=ct[isource], thick=2
   endfor
   legendastro, source_list, textcol=ct
   legendastro, [flux_method[ifm], "Array "+strtrim(iarray,2)], /right
endfor
outplot, /close, /verb
my_multiplot, /reset
stop

;; FWHM vs tau (to see if flux dispersion on Uranus at high tau can be
;; attributed to increased FWHM due anomalous refraction correlated to
;; high opacity)
if ps eq 0 then wind, 1, 1, /free, /large
outplot, file=project_dir+"/fwhm_elevation_tau", png=png, ps=ps
my_multiplot, 2, 3, pp, epp1, /rev, gap_y=0.01, ymargin=0.05
yra = [0.9, 1.1]
for iarray=1, 3 do begin
   if iarray eq 3 then xtitle='Elevation (deg)' else delvarx, xtitle
   plot, elevation, fwhm_res[iarray-1,*]/avg(fwhm_res[iarray-1,*]), /nodata, $
         xtitle=xtitle, ytitle='FWHM/avg(FWHM)', yra=yra, /ys, $
         position=pp[0,iarray-1,*], /noerase
   oplot, [-1, 100], [1,1]
   for isource=0, nsources-1 do begin
      w = where( scan_source eq source_list[isource], nw)
      flux_ref = avg(fwhm_res[iarray-1,w])
      if nw ne 0 then begin
         oplot, elevation[w], fwhm_res[iarray-1,w]/flux_ref, psym=1, col=ct[isource]
      endif
      w = where( scan_source eq source_list[isource] and tau_res[0,*] le tau_max_1mm, nw)
      if nw ne 0 then oplot, elevation[w], fwhm_res[iarray-1,w]/flux_ref, psym=5, col=ct[isource], thick=2
   endfor
   legendastro, source_list, textcol=ct
   legendastro, [flux_method[ifm], "Array "+strtrim(iarray,2)], /right
endfor

for iarray=1, 3 do begin
   if iarray eq 3 then xtitle='Opacity' else delvarx, xtitle
   plot, tau_res[iarray-1,*], fwhm_res[iarray-1,*]/avg(fwhm_res[iarray-1,*]), /nodata, $
         xtitle='Opacity', ytitle='FWHM/avg(FWHM)', yra=yra, /ys, $
         position=pp[1,iarray-1,*], /noerase
   oplot, [-1, 100], [1,1]
   for isource=0, nsources-1 do begin
      w = where( scan_source eq source_list[isource], nw)
      flux_ref = avg(fwhm_res[iarray-1,w])
      if nw ne 0 then begin
         oplot, tau_res[iarray-1,w], fwhm_res[iarray-1,w]/flux_ref, psym=1, col=ct[isource]
      endif
      w = where( scan_source eq source_list[isource] and tau_res[0,*] le tau_max_1mm, nw)
      if nw ne 0 then oplot, tau_res[iarray-1,w], fwhm_res[iarray-1,w]/flux_ref, psym=5, col=ct[isource], thick=2
   endfor
   legendastro, source_list, textcol=ct
   legendastro, [flux_method[ifm], "Array "+strtrim(iarray,2)], /right
endfor
outplot, /close, /verb
my_multiplot, /reset

;; Flux vs FWHM
wind, 1, 1, /free, /large
my_multiplot, 1, 3, pp, pp1, /rev
for iarray=1, 3 do begin
   plot, fwhm_res[iarray-1,*], flux_res[ifm,iarray-1,*], psym=8, $
         position=pp1[iarray-1,*], /noerase, $
         xtitle='FWHM', ytitle='Flux'
   fit = linfit(fwhm_res[iarray-1,*], flux_res[ifm,iarray-1,*])
   oplot, [-1,100], fit[0] + fit[1]*[-1,100]
   legendastro, "A"+strtrim(iarray,2)
   legendastro, strtrim(fit,2), /bottom
endfor

stop

end
