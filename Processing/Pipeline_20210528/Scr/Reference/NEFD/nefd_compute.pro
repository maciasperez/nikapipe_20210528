
;; This script combines several scans into a final map and derives the
;; NEFD with two methods:
;; 1. Fitting the noise on the center flux as a function of the
;; cumulated observation time
;; 2. Measuring the NEFD on jackknife maps
;;-------------------------------------------------------------------

pro nefd_compute, source, raw_tmc, raw_tgb, raw_tmc_corr, raw_tgb_corr, $
                  jk_tmc, jk_tgb, jk_corr_tmc, jk_corr_tgb, tauw8_tmc, tauw8_tgb, $
                  reset=reset, png=png, ps=ps, input_kidpar_file=input_kidpar_file, $
                  project_dir=project_dir, method_num=method_num, $
                  nmc=nmc, quick=quick, preproc=preproc, compute=compute, scan_list=scan_list, $
                  mail=mail, ext=ext, el_min=el_min, el_max=el_max, $
                  tau1_min=tau1_min, tau1_max=tau1_max, scan_min=scan_min, scan_max=scan_max, $
                  ascii_file=ascii_file, v19=v19, polydeg=polydeg, noplot=noplot, boost=boost, $
                  reso=reso, cm_dmin=cm_dmin, freqlow=freqlow, freqhigh=freqhigh, $
                  prefilter=prefilter

if not keyword_set(method_num) then method_num = 2
process = 1
average = 1

ncpu_max = 24

if not keyword_set(png) then png=0
if not keyword_set(ps) then ps=0

if strupcase(source) eq 'G2' then begin
;;    restore, !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R12_v0.save"
;;    db_scan = scan
;;    w = where( strupcase(db_scan.object) eq strupcase(source) and $
;;               db_scan.obstype eq "onTheFlyMap", nw)
;;    scan_list = db_scan[w].day+"s"+strtrim(db_scan[w].scannum,2)
;;    scan_list = scan_list[ where( scan_list ne '20171023s162' and $
;;                                  scan_list ne '20171023s149' and $
;;                                  scan_list ne '20171026s175' and $
;;                                  scan_list ne '20171026s177' and $
;;                                  scan_list ne '20171026s179' and $
;;                                  scan_list ne '20171026s180' and $
;;                                  scan_list ne '20171030s146' and $
;;                                  scan_list ne '20171030s147' and $
;;                                  scan_list ne '20171030s148' and $
;;                                  scan_list ne '20171030s149')]

   ;; limit to "good" opacity scans for a test
   readcol, !nika.soft_dir+"/Labtools/NP/G2/scan_list_tau1mm_max0.35.dat", scan_list, format='A'
   
endif else begin
   restore, !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R9_v0.save"
   db_scan = scan
   w = where( strupcase(db_scan.object) eq strupcase(source) and $
              db_scan.obstype eq "onTheFlyMap", nw)
   scan_list = db_scan[w].day+"s"+strtrim(db_scan[w].scannum,2)
   ;; reject one outlyer with very low time of integration
   scan_list = scan_list[ where(scan_list ne '20170227s394')]
endelse

parallel = 1
spawn, "mkdir -p "+project_dir

;; ;----- plot for talk ----
;; HLS_RA = ten(09., 18., 28.6)*15.
;; HLS_DEC= ten(51., 42., 23.3)
;; nk_fits2grid, project_dir+"/map_signal.fits", grid, header, info_header
;; extast, header, astr
;; map_time_1mm = grid.nhits_1mm/!nika.f_sampling*(!nika.grid_step[0]/grid.map_reso)^2/3600./2.
;; wind, 1, 1, /free, /large
;; outplot, file=source+"_integration_time", png=png, ps=ps
;; himview, map_time_1mm, header, $
;;          title='Time of integration (1mm)', $
;;          colt=39, units='Hours'
;; ad2xy, hls_ra, hls_dec, astr, x_center, y_center
;; phi = dindgen(360)/359.*2*!dpi
;; cosphi = cos(phi)
;; sinphi = sin(phi)
;; for i=1, 6 do $
;;    oplot, x_center+i*60./grid.map_reso*cosphi, $
;;           y_center+i*60./grid.map_reso*sinphi, $
;;           col=255
;; legendastro, ['Tot. obs. time (hours): '+string( sxpar(info_header,"total_ob")/3600.,form='(F5.2)'), $
;;               'Valid obs. time (hours): '+string( sxpar(info_header,"valid_ob")/3600.,form='(F5.2)')], $
;;              textcol=255
;; legendastro, '1 arcmin contours', line=0, col=255, /bottom
;; outplot, /close, /mail
;; 
;; 
;; stop
;; ;------------------------

;; Param
define_nefd_param, param, method_num, source, project_dir, $
                   input_kidpar_file=input_kidpar_file, $
                   preproc=preproc, v19=v19, polydeg=polydeg, $
                   boost=boost, reso=reso, cm_dmin=cm_dmin, $
                   freqlow=freqlow, freqhigh=freqhigh, $
                   prefilter=prefilter

;; ;; Quick check
;;nk, scan_list[0], param=param, info=info1, grid=grid1
;;nk_grid2info, grid1, info1, /edu
;;stop

if keyword_set(preproc) then param.preproc_copy = 1 else param.preproc_copy = 0
param.preproc_dir = !nika.plot_dir+"/Preproc"
param.source    = source
param.name4file = source

;; Save param for split_for
in_param_file = project_dir+"/"+source+"_"+strtrim(method_num,2)+'_param_method'+strtrim(method_num,2)+'.save'
save, param, file=in_param_file

;; Erase preprocessed data to accept the new fields of grid and info
if keyword_set(reset) then begin
   nscans = n_elements(scan_list)
   for iscan=0, nscans-1 do begin
      spawn, "rm -f "+param.preproc_dir+"/data*"+scan_list[iscan]+".save"
   endfor
endif

;;============================================================
;; Process scans
nscans = n_elements(scan_list)

;; ;;--------------------------------
;; ;; ------- look at stripes ---
;; message, /info, "fix me:"
;; stop
;; scan = '20170228s167'
;; param.plot_ps = 0
;; param.polynomial = 0
;; param.preproc_copy = 1
;; param.corr_block_per_subscan = 1 ; redetermine block of correlated kid per subscan
;; param.decor_all_kids_in_block = 1 ; 1 induces striping (at least if corr_block_per_subscan == 0)
;; param.decor_method = 'common_mode_one_block'
;; delvarx, grid, info, kidpar
;; nk, scan, param=param, data=data, grid=grid, info=info, kidpar=kidpar
;; w1 = where( kidpar.type eq 1 and kidpar.array eq 1, nw1)
;; make_ct, nw1, ct
;; wind, 1, 1, /free
;; plot, data.toi[w1[0]], /xs, yra=minmax(data.toi[w1]), /ys
;; for i=0, nw1-1 do oplot, data.toi[w1[i]], col=ct[i]
;; stop
;; ;;--------------------------------

;obs_nk_ps_2, 0, scan_list, in_param_file
;stop

if compute eq 1 then begin
   if nscans eq 1 then parallel = 0
   if keyword_set(parallel) then begin
      optimize_nproc, nscans, ncpu_max, nproc
      split_for, 0, nscans-1, nsplit = nproc, $
                 commands=['obs_nk_ps_2, i, scan_list, in_param_file'], $
                 varnames=['scan_list', 'in_param_file']
   endif else begin
      for iscan=0, nscans-1 do obs_nk_ps, iscan, scan_list, in_param_file
   endelse
endif

;; Keep only the scans that were processed correctly
keep = intarr(nscans)
for iscan=0, nscans-1 do begin
   if file_test(project_dir+"/v_1/"+scan_list[iscan]+"/info.csv") then keep[iscan]=1
endfor
w = where( keep eq 1, nw)
if nw eq 0 then begin
   message, /info, "No valid scan ?!"
   stop
endif
scan_list = scan_list[w]
nscans = n_elements(scan_list)

;; Observing conditions
time_gauss_beam    = dblarr(5, nscans)
time_matrix_center = dblarr(5, nscans)
time_geom          = dblarr(   nscans)
eta                = dblarr(5, nscans)
eta_time_geom      = dblarr(5, nscans)
tau                = dblarr(4, nscans)
flux               = dblarr(4, nscans)
err_flux           = dblarr(4, nscans)
flux_center        = dblarr(4, nscans)
err_flux_center    = dblarr(4, nscans)
nefd_center        = dblarr(4, nscans)
elevation          = dblarr(   nscans)
array_col = [100, 250, 200, 70, 250]
array = ['A1', 'A2', 'A3', 'A1&A3', 'A2']
for iscan=0, nscans-1 do begin
   nk_read_csv_2, project_dir+"/v_1/"+scan_list[iscan]+"/info.csv", info
   time_matrix_center[0,iscan] = info.result_time_matrix_center_1
   time_matrix_center[1,iscan] = info.result_time_matrix_center_2
   time_matrix_center[2,iscan] = info.result_time_matrix_center_3
   time_matrix_center[3,iscan] = info.result_time_matrix_center_1mm
   time_matrix_center[4,iscan] = info.result_time_matrix_center_2mm

   nefd_center[0,iscan] = info.result_nefd_center_i1
   nefd_center[1,iscan] = info.result_nefd_center_i2
   nefd_center[2,iscan] = info.result_nefd_center_i3
   nefd_center[3,iscan] = info.result_nefd_center_i_1mm
   
   eta[0,iscan] = info.result_eta_1
   eta[1,iscan] = info.result_eta_2
   eta[2,iscan] = info.result_eta_3
   eta[3,iscan] = info.result_eta_1mm
   eta[4,iscan] = info.result_eta_2mm

   time_gauss_beam[0,iscan] = info.result_t_gauss_beam_1
   time_gauss_beam[1,iscan] = info.result_t_gauss_beam_2
   time_gauss_beam[2,iscan] = info.result_t_gauss_beam_3
   time_gauss_beam[3,iscan] = info.result_t_gauss_beam_1mm
   time_gauss_beam[4,iscan] = info.result_t_gauss_beam_2mm
   
   time_geom[iscan] = info.result_on_source_time_geom

   eta_time_geom[0,iscan] = eta[0,iscan]*info.result_on_source_time_geom
   eta_time_geom[1,iscan] = eta[1,iscan]*info.result_on_source_time_geom
   eta_time_geom[2,iscan] = eta[2,iscan]*info.result_on_source_time_geom
   eta_time_geom[3,iscan] = eta[3,iscan]*info.result_on_source_time_geom
   eta_time_geom[4,iscan] = eta[4,iscan]*info.result_on_source_time_geom

   flux[0,iscan] = info.result_flux_i1
   flux[1,iscan] = info.result_flux_i2
   flux[2,iscan] = info.result_flux_i3
   flux[3,iscan] = info.result_flux_i_1mm

   flux_center[0,iscan] = info.result_flux_center_i1
   flux_center[1,iscan] = info.result_flux_center_i2
   flux_center[2,iscan] = info.result_flux_center_i3
   flux_center[3,iscan] = info.result_flux_center_i_1mm

   err_flux[0,iscan] = info.result_err_flux_i1
   err_flux[1,iscan] = info.result_err_flux_i2
   err_flux[2,iscan] = info.result_err_flux_i3
   err_flux[3,iscan] = info.result_err_flux_i_1mm

   err_flux_center[0,iscan] = info.result_err_flux_center_i1
   err_flux_center[1,iscan] = info.result_err_flux_center_i2
   err_flux_center[2,iscan] = info.result_err_flux_center_i3
   err_flux_center[3,iscan] = info.result_err_flux_center_i_1mm

   tau[0,iscan] = info.result_tau_1mm
   tau[1,iscan] = info.result_tau_2mm
   tau[2,iscan] = info.result_tau_1mm
   tau[3,iscan] = info.result_tau_1mm
   
   elevation[iscan] = info.result_elevation_deg
endfor

;;--------------------
;; Check that all arrays return the same t_obs
if not keyword_set(noplot) then begin
   wind, 1, 1, /free
   outplot, file='integration_time', png=png
   plot, indgen(nscans), [100,150], /nodata, /ys, $
         xtitle='Scan index', ytitle='sec', title='T!dobs!n (should be the same for all)', /xs
   for iarray=1, 4 do begin
      oplot, indgen(nscans), time_matrix_center[iarray-1,*]/eta[iarray-1,*], $
             col=array_col[iarray-1]
   endfor
   oplot, indgen(nscans), time_geom, col=0
   legendastro, ['A1 TMatCen/eta', 'A2 TMatCen/eta', 'A3 TMatCen/eta', 'A1&A3 TMatCen/eta', 'T. Geom'], $
                textcol=[array_col,0]
   leg_txt = 'A1/time_geom = '+string(avg( time_matrix_center[0,*]/eta[0,*] / time_geom),form='(F5.2)')
   for iarray=2, 4 do begin
      leg_txt = [leg_txt, $
                 'A'+strtrim(iarray,2)+"/time_geom = "+$
                 string( avg( time_matrix_center[iarray-1,*]/eta[iarray-1,*] / time_geom), form='(F5.2)')]
   endfor
   legendastro, leg_txt, /right, textcol=array_col
   outplot, /close, mail=mail
   
;;---------------------
;; What time integration should we consider for the NEFd
   if ps eq 0 then begin
      wind, 1, 1, /free, /large
   endif
   my_multiplot, 2, 4, pp, pp1, /rev, gap_y=0.02
   file = project_dir+"/"+source+"_"+strtrim(method_num,2)+'_time_of_integration'
   if defined(ext) then file += "_"+ext
   outplot, file=file, ps=ps, png=png
   array_sim = [2, 4, 5, 6, 7]
   yra = [50,150]
   for iarray=1, 4 do begin
      if iarray eq 4 then begin
         xtitle='scan index'
         xcharsize = 0.6
      endif else begin
         xcharsize=1d-10
         delvarx, xtitle
      endelse
      plot, time_matrix_center[iarray-1,*], yra=yra, /ys, /nodata, $
            ytitle='Integration time (sec)', xtitle=xtitle, /xs, $
            position=pp[0,iarray-1,*], /noerase, xcharsize=xcharsize
      oplot, time_matrix_center[iarray-1,*], psym=-array_sim[iarray-1], col=250
      oplot, time_gauss_beam[iarray-1,*],    psym=-array_sim[iarray-1], col=70
      oplot, eta_time_geom[iarray-1,*],      psym=-array_sim[iarray-1], col=150
      if iarray le 3 then begin
         legendastro, 'A'+strtrim(iarray,2)
      endif else begin
         legendastro, 'A1&A3'
      endelse
      legendastro, ['Time Matrix Center', 'Eta x Time Geom', 'Time gauss beam'], $
                   line=0, col=[250,150,70], /right, textcol=col
      
      plot, time_matrix_center[iarray-1,*], yra, /xs, /ys, /nodata, $
            xtitle='time', ytitle='time', position=pp[1,iarray-1,*], /noerase
      oplot, time_matrix_center[iarray-1,*], time_gauss_beam[iarray-1,*], $
             col=70, psym=1
      fit_beam = linfit(  time_matrix_center[iarray-1,*], time_gauss_beam[iarray-1,*])
      oplot, [0,100], fit_beam[0] + fit_beam[1]*[0,100]
      oplot, time_matrix_center[iarray-1,*], eta_time_geom[iarray-1,*], psym=1, col=150
      fit_geom = linfit( time_matrix_center[iarray-1,*], eta_time_geom[iarray-1,*])
      oplot, [0,100], fit_geom[0] + fit_geom[1]*[0,100]
      legendastro, [strtrim(fit_beam[1],2), strtrim(fit_geom[1],2)], $
                   textcol=[70,150], /bottom, /right
   endfor
   outplot, /close, /v

   delvarx, position, noerase
   if ps eq 0 then begin
      wind, 1, 1, /free, /large
      my_multiplot, 2, 3, pp, pp1, /rev, gap_y=0.05, gap_x=0.05
      plot_file = project_dir+"/"+source+"_"+strtrim(method_num,2)+"_summary"
      if defined(ext) then plot_file += "_"+ext
      outplot, file=plot_file, png=png
      noerase = 1
   endif
   if ps eq 0 then position=pp[0,0,*]
   outplot, file=project_dir+"/"+source+"_"+strtrim(method_num,2)+'_array_eff', ps=ps
   plot, eta[0,*], /xs, yra=[0,1], /ys, /nodata, ytitle='Eta', position=position, noerase=noerase
   for i=0, 2 do oplot, eta[i,*], col=array_col[i]
   legendastro, array[0:2], col=array_col[0:2], textcol=array_col[0:2], line=0
   if ps eq 1 then outplot, /close, /v

   if ps eq 0 then position=pp[0,1,*]
   outplot, file=project_dir+"/"+source+"_"+strtrim(method_num,2)+'_opacity', ps=ps
   plot, tau[0,*], /xs, yra=[0,0.3], /ys, /nodata, ytitle='Opacity', position=position, noerase=noerase, $
         thick=2
   for i=0, 1 do oplot, tau[i,*], col=array_col[i], thick=2
   legendastro, ['Tau 1mm: '+strtrim(avg(tau[0,*]),2), $
                 'Tau 2mm: '+strtrim(avg(tau[1,*]),2)], $
                col=array_col[0:1], textcol=array_col[0:1], line=0, thick=2, charthick=2
   if ps eq 1 then outplot, /close, /v

   if ps eq 0 then position=pp[0,2,*]
   outplot, file=project_dir+"/"+source+"_"+strtrim(method_num,2)+'_elevation', ps=ps
   plot, elevation, /xs, yra=[0,90], ytitle='Elevation', position=position, noerase=noerase, $
         thick=2
   legendastro, 'Avg(elevation): '+strtrim(avg(elevation),2), charthick=2
   if ps eq 1 then outplot, /close, /v

   if ps eq 0 then position=pp[1,0,*]
   outplot, file=project_dir+"/"+source+"_"+strtrim(method_num,2)+'_flux', ps=ps
   ploterror, flux[0,*], err_flux[0,*], /xs, yra=minmax(flux)*[0.8,1.2], $
              ytitle='Flux', position=position, noerase=noerase, /nodata
   for i=0, 2 do oploterror, flux[i,*], err_flux[i,*], psym=8, $
                             syms=0.5, col=array_col[i], errcol=array_col[i]
   legendastro, strtrim([avg(flux[0,*]),avg(flux[1,*]), avg(flux[2,*])],2)
   if ps eq 1 then outplot, /close, /v

   if ps eq 0 then position=pp[1,1,*]
   outplot, file=project_dir+"/"+source+"_"+strtrim(method_num,2)+'_flux_center', ps=ps
   ploterror, flux_center[0,*], err_flux_center[0,*], /xs, yra=minmax(flux_center)*[0.8,1.2], $
              ytitle='Flux_center', position=position, noerase=noerase, /nodata
   for i=0, 2 do oploterror, flux_center[i,*], err_flux_center[i,*], psym=8, $
                             syms=0.5, col=array_col[i], errcol=array_col[i]
   legendastro, strtrim([avg(flux_center[0,*]),avg(flux_center[1,*]), avg(flux_center[2,*])],2)
   if ps eq 1 then outplot, /close, /v

   if ps eq 0 then position=pp[1,2,*]
   outplot, file=project_dir+"/"+source+"_"+strtrim(method_num,2)+'_time_matrix_center', ps=ps
   plot, time_matrix_center[0,*], yra=minmax(time_matrix_center)*[0.8,1.2], /ys, title='time matrix center', $
         position=position, /noerase, /xs
   for iarray=1, 4 do oplot, time_matrix_center[iarray-1,*], col=array_col[iarray-1]
   legendastro, ['A1', 'A2', 'A3', 'A1&A3'], col=array_col[0:3], textcol=array_col[0:3]
   if ps eq 1 then outplot, /close, /v
   outplot, /close, /v, mail=mail
   !p.multi=0

   wind, 1, 1, /free
   tau_over_sin_elev = dindgen(100)/99
   my_multiplot, 1, 2, pp, pp1, /rev
   plot, tau[0,*]/sin(elevation*!dtor), nefd_center[3,*], $
         ytitle='NEFD', position=pp1[0,*], /nodata
   oplot, tau[0,*]/sin(elevation*!dtor), nefd_center[3,*], psym=8, syms=0.5, col=200
   fit = linfit( exp(tau[0,*]/sin(elevation*!dtor)), nefd_center[3,*])
   oplot, tau_over_sin_elev, fit[0] + fit[1]*exp(tau_over_sin_elev), col=250
   ampl = avg( nefd_center[3,*]/exp(tau[0,*]/sin(elevation*!dtor)))
   oplot, tau_over_sin_elev, ampl*exp(tau_over_sin_elev), col=70
   legendastro, [strtrim(fit,2),strtrim(ampl,2)], textcol=[250,250,70], /bottom
   legendastro, '1mm', psym=8, col=200, textcol=200

   nefd0_all_scans_1mm = ampl
   
   plot, tau[1,*]/sin(elevation*!dtor), nefd_center[1,*], /nodata, $
         xtitle='tau/sin(elev)', ytitle='NEFD', position=pp1[1,*], /noerase
   oplot, tau[1,*]/sin(elevation*!dtor), nefd_center[1,*], psym=8, syms=0.5, col=100
   fit = linfit( exp(tau[1,*]/sin(elevation*!dtor)), nefd_center[1,*])
   oplot, tau_over_sin_elev, fit[0] + fit[1]*exp(tau_over_sin_elev), col=250
   ampl = avg( nefd_center[1,*]/exp(tau[1,*]/sin(elevation*!dtor)))
   oplot, tau_over_sin_elev, ampl*exp(tau_over_sin_elev), col=70
   legendastro, [strtrim(fit,2),strtrim(ampl,2)], textcol=[250,250,70], /bottom
   legendastro, '2mm', psym=8, col=100, textcol=100

   nefd0_all_scans_2mm = ampl
   
endif

;;-----------------------------------------------------
;; Combine scans

if not keyword_set(el_min) then el_min =  0
if not keyword_set(el_max) then el_max = 90
w = where( elevation ge el_min and elevation le el_max, nscans)
scan_list = scan_list[w]

if el_min eq 0 and el_max eq 90 then begin
;; dans le cas d'HLS
   if not keyword_set(tau1_min) then tau1_min = 0
   if not keyword_set(tau1_max) then tau1_max = 1
   w = where( tau[0,*] ge tau1_min and tau[0,*] le tau1_max, nscans)
   scan_list = scan_list[w]
endif

thick = 2
symsize = 1
;; Fitting directly the zenith tau and accounting for the different
;; elevations and opacities that are combined
tau_w8 = 1
nk_average_scans, param, scan_list, grid_tot, $
                  info=info_tau_w8, output_fits_file=project_dir+"/map_signal.fits", $
                  /cumul, sigma_flux_center_cumul=sigma_flux_center_cumul, $
                  time_center_cumul=time_center_cumul, time_gauss_beam_cumul=time_gauss_beam_cumul, $
                  tau_w8=tau_w8, noplot=noplot
sigma_flux_center_cumul *= 1000. ; Jy to mJy

nefd_plot, file=project_dir+'/'+source+"_"+strtrim(method_num,2)+'_sigma_vs_time_matrix_center_tau_w8', $
           time_center_cumul, sigma_flux_center_cumul, $
           nefd_tauw8_tmc, comment='time_matrix_center/corr^2', source=source, $
           thick=thick, symsize=symsize, png=png, mail=mail, noplot=noplot

nefd_plot, file=project_dir+'/'+source+"_"+strtrim(method_num,2)+'_sigma_vs_time_gauss_beam_tau_w8', $
           time_gauss_beam_cumul, sigma_flux_center_cumul, $
           nefd_tauw8_tgb, comment='time_gauss_beam/corr^2', source=source, $
           thick=thick, symsize=symsize, png=png, mail=mail, noplot=noplot

;; Jack-knife map that has been properly weighted in nk_average_scans:
;; the fact that the sum is done alternatively and in chronological
;; order is also better than randomizing the scan_list. Indeed, the +-
;; 1 weight applied to two consecutive scans with approximately the
;; same observing conditions ensures a better subtraction of the
;; signal seen at these opacities and elevations.
nk_fits2grid, project_dir+"/map_signal_JK.fits", grid_jk
wind, 1, 1, /free, /large
nk_grid2info, grid_jk, info_jk, /edu, title='JK'

;; Derive NEFD0 from these maps accouting for the ponderation by the
;; integration time, the opacity and the elevation
nefd_a1 = info_tau_w8.result_err_flux_center_i1    * sqrt( time_center_cumul[nscans-1,0])
nefd_a2 = info_tau_w8.result_err_flux_center_i2    * sqrt( time_center_cumul[nscans-1,0])
nefd_a3 = info_tau_w8.result_err_flux_center_i3    * sqrt( time_center_cumul[nscans-1,0])
nefd_1mm = info_tau_w8.result_err_flux_center_i_1mm * sqrt( time_center_cumul[nscans-1,0])

nefd_jk_a1  = info_jk.result_err_flux_center_i1    * sqrt( time_center_cumul[nscans-1,0])
nefd_jk_a2  = info_jk.result_err_flux_center_i2    * sqrt( time_center_cumul[nscans-1,0])
nefd_jk_a3  = info_jk.result_err_flux_center_i3    * sqrt( time_center_cumul[nscans-1,0])
nefd_jk_1mm = info_jk.result_err_flux_center_i_1mm * sqrt( time_center_cumul[nscans-1,0])

;; Output results
jk_res_file = project_dir+"/"+source+"_"+strtrim(method_num,2)+"_jk_sigma_center" ;.dat"
if defined(ext) then jk_res_file += "_"+ext+".dat" else jk_res_file += ".dat"
openw,  lu, jk_res_file, /get_lun
printf, lu, project_dir
printf, lu, "Flux A1 tau_w8: "+$
        string( info_tau_w8.result_flux_i1*1000,form=fmt)+$
        " +- "+string(    info_tau_w8.result_err_flux_i1*1000,form=fmt)
printf, lu, "Flux A2 tau_w8: "+$
        string( info_tau_w8.result_flux_i2*1000,form=fmt)+$
        " +- "+string(    info_tau_w8.result_err_flux_i2*1000,form=fmt)
printf, lu, "Flux A3 tau_w8: "+$
        string( info_tau_w8.result_flux_i3*1000,form=fmt)+$
        " +- "+string(    info_tau_w8.result_err_flux_i3*1000,form=fmt)
printf, lu, "Flux A_1mm tau_w8: "+$
        string( info_tau_w8.result_flux_i_1mm*1000,form=fmt)+$
        " +- "+string( info_tau_w8.result_err_flux_i_1mm*1000,form=fmt)
printf, lu, ""

printf, lu, "NEFD's (accounting effective integration time, opacity and elevation):"
print, lu, ""
printf, lu, "nefd_a1  = "+string( nefd_a1*1000,  form='(F5.2)')  
printf, lu, "nefd_a2  = "+string( nefd_a2*1000,  form='(F5.2)')  
printf, lu, "nefd_a3  = "+string( nefd_a3*1000,  form='(F5.2)')  
printf, lu, "nefd_1mm = "+string( nefd_1mm*1000, form='(F5.2)')
printf, lu, ""
printf, lu, "nefd_jk_a1  = "+string( nefd_jk_a1*1000,  form='(F5.2)')  
printf, lu, "nefd_jk_a2  = "+string( nefd_jk_a2*1000,  form='(F5.2)')  
printf, lu, "nefd_jk_a3  = "+string( nefd_jk_a3*1000,  form='(F5.2)')  
printf, lu, "nefd_jk_1mm = "+string( nefd_jk_1mm*1000, form='(F5.2)')
i = 3
printf, lu, "NEFD sigma vs sqrt(t mat cent) A"+strtrim(i+1,2)+": "+strtrim(nefd_tauw8_tmc[i],2)
printf, lu, "NEFD sigma vs sqrt(t gauss beam) A"+strtrim(i+1,2)+": "+strtrim(nefd_tauw8_tgb[i],2)
printf, lu, ""
printf, lu, "NEFD_0, fit on all scans vs tau/sin(el):"
printf, lu, "nefd_1mm: "+string( nefd0_all_scans_1mm*1000, form='(F5.2)')
printf, lu, "nefd_2mm: "+string( nefd0_all_scans_2mm*1000, form='(F5.2)')
close, lu
free_lun, lu
spawn, "cat "+jk_res_file

exitmail, file=jk_res_file, message=source+"_"+strtrim(method_num,2)+"-"+file_basename(project_dir)

end
