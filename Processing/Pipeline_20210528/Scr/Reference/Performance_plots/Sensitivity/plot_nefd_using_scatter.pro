pro plot_nefd_using_scatter, allscan_info, index_select, $
                             outplot_dir = outplot_dir, $
                             png=png, ps=ps, pdf=pdf, $
                             obsdate_stability=obsdate_stability, $
                             obstau_stability=obstau_stability, $
                             nostop = nostop, $
                             output_nefd0 = output_nefd0, $
                             output_mapping_speed0 = output_mapping_speed0, $
                             output_source_list = output_source_list
  
  ;; outplot directory
  if keyword_set(outplot_dir) then dir = outplot_dir else $
     dir     = getenv('NIKA_PLOT_DIR')+'/Performance_plots'

  if keyword_set(nostop) then nostop=1 else nostop=0
  if keyword_set(savefile) then savefile = 1 else savefile = 0


  
  plot_suffixe = ''

  ;; plot aspect
  ;;----------------------------------------------------------------
  
  ;; window size
  wxsize = 1000.
  wysize = 800.
  ;; plot size in files
  pxsize = 22.
  pysize = 16.
  ;; charsize
  charsize  = 1.2
  charthick = 1.0
  mythick = 1.0
  mysymsize   = 0.8
  
  if keyword_set(ps) then begin
     ;; window size
     ps_wxsize = 1100.
     ps_wysize = 800.
     ;; plot size in files
     ps_pxsize = 20.
     ps_pysize = 16.
     ;; charsize
     ps_charsize  = 1.0
     ps_charthick = 3.0
     ps_mythick   = 3.0 
     ps_mysymsize = 1.0
     
  endif

  ;;________________________________________________________________
  ;;
  ;; create result table
  ;;________________________________________________________________
  ;;________________________________________________________________
  scan_info = allscan_info[index_select]
  allsources = strupcase(scan_info.object)
  sources = allsources(uniq(allsources, sort(allsources)))
  nscans = n_elements(scan_info)
  scan_list = scan_info.scan

  if keyword_set(output_source_list) then output_source_list = sources

  flux_1mm     = scan_info.result_flux_i_1mm
  flux_a2      = scan_info.result_flux_i2
  flux_a1      = scan_info.result_flux_i1
  flux_a3      = scan_info.result_flux_i3
  err_flux_1mm = scan_info.result_err_flux_i_1mm
  err_flux_a2  = scan_info.result_err_flux_i2
  err_flux_a1  = scan_info.result_err_flux_i1
  err_flux_a3  = scan_info.result_err_flux_i3
  ;;
  nefd_1mm     = scan_info.result_nefd_i_1mm*1.0d3
  nefd_a2      = scan_info.result_nefd_i2*1.0d3
  nefd_a1      = scan_info.result_nefd_i1*1.0d3
  nefd_a3      = scan_info.result_nefd_i3*1.0d3
  ;;
  eta_a1       = scan_info.result_nkids_valid1/1140.0
  eta_a3       = scan_info.result_nkids_valid3/1140.0
  eta_a2       = scan_info.result_nkids_valid2/616.0
  eta_1mm      = (scan_info.result_nkids_valid1+ scan_info.result_nkids_valid3)/2.d0/1140.0
  ;;
  ms_a1        = !dpi/4.0d0*6.5d0^2*60.0d0^2*eta_a1/nefd_a1^2
  ms_a3        = !dpi/4.0d0*6.5d0^2*60.0d0^2*eta_a3/nefd_a3^2
  ms_a2        = !dpi/4.0d0*6.5d0^2*60.0d0^2*eta_a2/nefd_a2^2
  ms_1mm       = !dpi/4.0d0*6.5d0^2*60.0d0^2*eta_1mm/nefd_1mm^2
  ;;
  tau_1mm      = scan_info.result_tau_1mm
  tau_a2       = scan_info.result_tau_2mm
  tau_a1       = scan_info.result_tau_1
  tau_a3       = scan_info.result_tau_3
  ;;
  elev         = scan_info.result_elevation_deg*!dtor
  obj          = scan_info.object
  day          = scan_info.day
  n2runid      = 0
  ut           = strmid(scan_info.ut, 0, 5)
  ;;
     
  ;; calculate ut_float 
  ut_float    = fltarr(nscans)
  for i=0, nscans-1 do begin
     ut_float[i] = float((STRSPLIT(ut[i], ':', /EXTRACT))[0])+float((STRSPLIT(ut[i], ':', /EXTRACT))[1])/60.
  endfor
     
  if nostop lt 1 then stop

  ;;; condition IRAM
;;;-------------------------------------------------------------------
  print,""
  print,"condition IRAM"
  print,"---------------------------------------------------"
  output_pwv = 1.0d0
  atm_model_mdp, tau_1, tau_2, tau_3, tau_225, atm_em_1, atm_em_2, atm_em_3, output_pwv=output_pwv, /nostop
  w=where(output_pwv eq 2., nn)

  atm_tau1   = avg([tau_1[w],tau_3[w]])
  atm_tau2   = tau_2[w]
  atm_tau_a1 = tau_1[w]
  atm_tau_a3 = tau_3[w]
  print,"tau_1 @ 2mm pwv = ", atm_tau_a1
  print,"tau_3 @ 2mm pwv  = ", atm_tau_a3
  print,"tau_1mm @ 2mm pwv  = ", atm_tau1
  print,"tau_2mm @ 2mm pwv  = ", atm_tau2

  ;; corrected opacity uncertainties
  ;; -------------------------------------
  delta_a = 0.03
  print, 'opacity relative uncertainties = ', delta_a * atm_tau1 / sin(60.*!dtor)*100.0
  print, 'opacity relative uncertainties = ', delta_a * atm_tau2 / sin(60.*!dtor)*100.0


  ;;________________________________________________________________
  ;;
  ;;
  ;;          OUTPUTS
  ;;
  ;;________________________________________________________________
  ;;________________________________________________________________
  nefd0_tab   = dblarr(4, 2)
  nefdA_tab   = dblarr(4, 2)
  ms0_tab     = dblarr(4, 2)
  msA_tab     = dblarr(4, 2)
  
  print, ''
  print, ' A1 '
  print, '-----------------------'
  atm_trans = exp(-tau_a1/sin(elev))
  w_atmtrans = where(atm_trans gt 0.5 and atm_trans le 1.0 and nefd_a1 gt 0.0, nn)
  ;;
  nefd0_tab[0, 0] = median(nefd_a1[w_atmtrans]*atm_trans[w_atmtrans])
  nefdA_tab[0, 0] = nefd0_tab[0, 0]*exp(atm_tau_a1/sin(60.0d0*!dtor))
  nefd0_tab[0, 1] = stddev(nefd_a1[w_atmtrans]*atm_trans[w_atmtrans])
  nefdA_tab[0, 1] = nefd0_tab[0, 1]*exp(atm_tau_a1/sin(60.0d0*!dtor))
  ms0_tab[0, 0]   = median(ms_a1[w_atmtrans]/atm_trans[w_atmtrans]^2)
  ms0_tab[0, 1]   = stddev(ms_a1[w_atmtrans]/atm_trans[w_atmtrans]^2)
  ;;
  print, 'nscans = ', nn
  print, ''
  print, 'NEFD_0 median = ', nefd0_tab[0, 0]
  print, 'NEFD 0 mean = ', mean(nefd_a1[w_atmtrans]*atm_trans[w_atmtrans])
  print, 'NEFD 0 rms = ', nefd0_tab[0, 1]
  print, 'NEFD IRAM = ', nefdA_tab[0, 0], '+-', nefdA_tab[0, 1] 
  print, ''
  print, 'ETA median = ',median(eta_a1[w_atmtrans])
  print, 'ETA mean = ', mean(eta_a1[w_atmtrans])
  print, 'rms ETA  = ', stddev(eta_a1[w_atmtrans])
  print, ''
  print, 'MS median = ',  ms0_tab[0, 0]
  print, 'MS mean = ',  mean(ms_a1[w_atmtrans]/atm_trans[w_atmtrans]^2)
  print, 'rms MS = ',  ms0_tab[0, 1]

  print, ''
  print, ' A3 '
  print, '-----------------------'
  atm_trans = exp(-tau_a3/sin(elev))
  w_atmtrans = where(atm_trans gt 0.5 and atm_trans le 1.0 and nefd_a3 gt 0.0, nn)
  ;;
  nefd0_tab[1, 0] = median(nefd_a3[w_atmtrans]*atm_trans[w_atmtrans])
  nefdA_tab[1, 0] = nefd0_tab[1, 0]*exp(atm_tau_a3/sin(60.0d0*!dtor))
  nefd0_tab[1, 1] = stddev(nefd_a3[w_atmtrans]*atm_trans[w_atmtrans])
  nefdA_tab[1, 1] = nefd0_tab[1, 1]*exp(atm_tau_a3/sin(60.0d0*!dtor))
  ms0_tab[1, 0]   = median(ms_a3[w_atmtrans]/atm_trans[w_atmtrans]^2)
  ms0_tab[1, 1]   = stddev(ms_a3[w_atmtrans]/atm_trans[w_atmtrans]^2)
  ;;
  print, 'nscans = ', nn
  print, ''
  print, 'NEFD_0 median = ', nefd0_tab[1, 0]
  print, 'NEFD 0 mean = ', mean(nefd_a3[w_atmtrans]*atm_trans[w_atmtrans])
  print, 'NEFD 0 rms = ', nefd0_tab[1, 1]
  print, 'NEFD IRAM = ', nefdA_tab[1, 0], '+-', nefdA_tab[1, 1] 
  print, ''
  print, 'ETA median = ',median(eta_a3[w_atmtrans])
  print, 'ETA mean = ', mean(eta_a3[w_atmtrans])
  print, 'rms ETA  = ', stddev(eta_a3[w_atmtrans])
  print, ''
  print, 'MS median = ',  ms0_tab[1, 0]
  print, 'MS mean = ',  mean(ms_a3[w_atmtrans]/atm_trans[w_atmtrans]^2)
  print, 'rms MS = ',  ms0_tab[1, 1]
  
  print, ''
  print, ''
  print, ' 1mm '
  print, '-----------------------'
  atm_trans = exp(-tau_1mm/sin(elev))
  w_atmtrans = where(atm_trans gt 0.5 and atm_trans le 1.0 and nefd_1mm gt 0.0, nn)
  ;;
  nefd0_tab[2, 0] = median(nefd_1mm[w_atmtrans]*atm_trans[w_atmtrans])
  nefdA_tab[2, 0] = nefd0_tab[2, 0]*exp(atm_tau1/sin(60.0d0*!dtor))
  nefd0_tab[2, 1] = stddev(nefd_1mm[w_atmtrans]*atm_trans[w_atmtrans])
  nefdA_tab[2, 1] = nefd0_tab[2, 1]*exp(atm_tau1/sin(60.0d0*!dtor))
  ms0_tab[2, 0]   = median(ms_1mm[w_atmtrans]/atm_trans[w_atmtrans]^2)
  ms0_tab[2, 1]   = stddev(ms_1mm[w_atmtrans]/atm_trans[w_atmtrans]^2)
  ;;
  print, 'nscans = ', nn
  print, ''
  print, 'NEFD_0 median = ', nefd0_tab[2, 0]
  print, 'NEFD 0 mean = ', mean(nefd_1mm[w_atmtrans]*atm_trans[w_atmtrans])
  print, 'NEFD 0 rms = ', nefd0_tab[2, 1]
  print, 'NEFD IRAM = ', nefdA_tab[2, 0], '+-', nefdA_tab[2, 1] 
  print, ''
  print, 'ETA median = ',median(eta_1mm[w_atmtrans])
  print, 'ETA mean = ', mean(eta_1mm[w_atmtrans])
  print, 'rms ETA  = ', stddev(eta_1mm[w_atmtrans])
  print, ''
  print, 'MS median = ',  ms0_tab[2, 0]
  print, 'MS mean = ',  mean(ms_1mm[w_atmtrans]/atm_trans[w_atmtrans]^2)
  print, 'rms MS = ',  ms0_tab[2, 1]
  print, ''
  
  print, ''
  print, ' 2mm '
  print, '-----------------------'
  atm_trans = exp(-tau_a2/sin(elev))
  w_atmtrans = where(atm_trans gt 0.5 and atm_trans le 1.0 and nefd_a2 gt 0.0, nn)
  ;;
  nefd0_tab[3, 0] = median(nefd_a2[w_atmtrans]*atm_trans[w_atmtrans])
  nefdA_tab[3, 0] = nefd0_tab[3, 0]*exp(atm_tau2/sin(60.0d0*!dtor))
  nefd0_tab[3, 1] = stddev(nefd_a2[w_atmtrans]*atm_trans[w_atmtrans])
  nefdA_tab[3, 1] = nefd0_tab[3, 1]*exp(atm_tau2/sin(60.0d0*!dtor))
  ms0_tab[3, 0]   = median(ms_a2[w_atmtrans]/atm_trans[w_atmtrans]^2)
  ms0_tab[3, 1]   = stddev(ms_a2[w_atmtrans]/atm_trans[w_atmtrans]^2)
  ;;
  print, 'nscans = ', nn
  print, ''
  print, 'NEFD_0 median = ', nefd0_tab[3, 0]
  print, 'NEFD 0 mean = ', mean(nefd_a2[w_atmtrans]*atm_trans[w_atmtrans])
  print, 'NEFD 0 rms = ', nefd0_tab[3, 1]
  print, 'NEFD IRAM = ', nefdA_tab[3, 0], '+-', nefdA_tab[3, 1] 
  print, ''
  print, 'ETA median = ',median(eta_a2[w_atmtrans])
  print, 'ETA mean = ', mean(eta_a2[w_atmtrans])
  print, 'rms ETA  = ', stddev(eta_a2[w_atmtrans])
  print, ''
  print, 'MS median = ',  ms0_tab[3, 0]
  print, 'MS mean = ',  mean(ms_a2[w_atmtrans]/atm_trans[w_atmtrans]^2)
  print, 'rms MS = ',  ms0_tab[3, 1]
  
  if keyword_set(output_nefd0) then output_nefd0 = nefd0_tab
  if keyword_set(output_mapping_speed0) then output_mapping_speed0 = ms0_tab 
  
  
  
  ;;________________________________________________________________
  ;;
  ;;
  ;;          PLOTS
  ;;
  ;;________________________________________________________________
  ;;________________________________________________________________
  
     
  plot_color_convention, col_a1, col_a2, col_a3, $
                         col_mwc349, col_crl2688, col_ngc7027, $
                         col_n2r9, col_n2r12, col_n2r14, col_1mm
  


       
     ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  
  wind, 1, 1, /free, xsize=wxsize, ysize=wysize 
  outfile = dir+'/plot_nefd_vs_obstau'+plot_suffixe
  outplot, file=outfile, png=png, xsize=pxsize, ysize=pysize, charsize=charsize, thick=mythick, charthick=charthick
        
  !p.multi=[0,2,2]
  
  ;; 1mm
  ;;----------------------------------------------------------
  print, ''
  print, ' A1&A3 '
  print, '-----------------------'
  ymax = 120.
  ymin = 0.
  xmax = 0.9
  xmin = 0.
  obs_tau = tau_1mm/sin(elev)
       
  plot, obs_tau, nefd_1mm, /xs, yr=[ymin, ymax], $
        xr=[xmin,xmax], $
        xtitle='!7s!3/sin(el)', ytitle='NEFD [mJy.s^0.5]', /ys, /nodata
  
  w = where(nefd_1mm gt 0.0, nn)
  if nn gt 0 then oplot, obs_tau[w], nefd_1mm[w], psym=cgsymcat('FILLEDCIRCLE', thick=2), col=col_1mm, symsize=0.5
  ;;
  obstau = dindgen(1000)/1000.
  oplot, obstau, nefd0_tab[2, 0]*exp(obstau), col=90
  ;;
  xyouts, xmax-(xmax-xmin)*0.2, ymax-(ymax-ymin)*0.1, 'A1&A3', col=0 
  
          
  ;; A1
  ;;----------------------------------------------------------
  print, ''
  print, ' A1 '
  print, '-----------------------'
  ymax = 120.
  ymin = 0.
  obs_tau = tau_a1/sin(elev)
  xmin = 0.0
  xmax = 0.9
  
  plot, obs_tau, nefd_a1, /xs, yr=[ymin, ymax], $
        xr=[xmin,xmax], $
        xtitle='!7s!3/sin(el)', ytitle='NEFD [mJy.s^0.5]', /ys, /nodata
  
  w = where(nefd_a1 gt 0.0, nn)
  if nn gt 0 then oplot, obs_tau[w], nefd_a1[w], psym=cgsymcat('FILLEDCIRCLE', thick=2), col=col_1mm,symsize=0.5
  ;;
  obstau = dindgen(1000)/1000.
  oplot, obstau, nefd0_tab[0, 0]*exp(obstau), col=90
  ;;
  xyouts, xmax-(xmax-xmin)*0.13, ymax-(ymax-ymin)*0.13, 'A1', col=0
     
          
  ;; A3
  ;;----------------------------------------------------------
  print, ''
  print, ' A3 '
  print, '-----------------------'
  ymax = 120.
  ymin = 0.
  obs_tau = tau_a3/sin(elev)
  xmin = 0.0
  xmax = 0.9

  plot, obs_tau, nefd_a3, /xs, yr=[ymin, ymax], $
        xr=[xmin,xmax], $
        xtitle='!7s!3/sin(el)', ytitle='NEFD [mJy.s^0.5]', /ys, /nodata
  ;;
  w = where(nefd_a3 gt 0.0, nn)
  if nn gt 0 then oplot, obs_tau[w], nefd_a3[w], psym=cgsymcat('FILLEDCIRCLE', thick=2), col=col_1mm, symsize=0.5
  ;;
  obstau = dindgen(1000)/1000.
  oplot, obstau, nefd0_tab[1, 0]*exp(obstau), col=90
  ;;
  xyouts, xmax-(xmax-xmin)*0.13, ymax-(ymax-ymin)*0.13, 'A3', col=0
        
  ;; A2
  ;;----------------------------------------------------------
  print, ''
  print, ' A2 '
  print, '-----------------------'
  ymax = 40.
  ymin = 0.
  obs_tau = tau_a2/sin(elev)
  xmin = 0.0
  xmax = 0.6

  plot, obs_tau, nefd_a2, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
        xtitle='!7s!3/sin(el)', ytitle='NEFD [mJy.s^0.5]', /ys, /nodata
  
  w = where(nefd_a2 gt 0.0, nn)
  if nn gt 0 then oplot,obs_tau[w], nefd_a2[w], psym=cgsymcat('FILLEDCIRCLE', thick=2), col=col_a2, symsize=0.5
  ;;
  obstau = dindgen(1000)/1000.
  oplot, obstau, nefd0_tab[3, 0]*exp(obstau), col=90
  ;;
  xyouts, xmax-(xmax-xmin)*0.13, ymax-(ymax-ymin)*0.13, 'A2', col=0
  
  outplot, /close
  !p.multi = 0
  
  if keyword_set(ps) then begin

     outfile = dir+'/plot_nefd_vs_obstau'+plot_suffixe
     outplot, file=outfile, ps=ps, xsize=ps_pxsize, ysize=ps_pysize, charsize=ps_charsize, thick=ps_mythick, charthick=ps_charthick

     my_multiplot, 2, 2, pp, pp1, /rev, gap_y=0.1, gap_x=0.1, xmargin=0.1, ymargin=0.1 ; 1e-6
     
     ymax = 120.
     ymin = 0.
     xmax = 0.9
     xmin = 0.
     obs_tau = tau_1mm/sin(elev)
     
     plot, obs_tau, nefd_1mm, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='!7s!3/sin(el)', ytitle='NEFD [mJy.s^0.5]', /ys, /nodata, pos=pp1[0, *]
     
     w = where(nefd_1mm gt 0.0, nn)
     if nn gt 0 then oplot, obs_tau[w], nefd_1mm[w], psym=cgsymcat('FILLEDCIRCLE', thick=2*ps_mythick), col=col_1mm, symsize=0.5*ps_mysymsize
     ;;
     obstau = dindgen(1000)/1000.
     oplot, obstau, nefd0_tab[2, 0]*exp(obstau), col=90
     ;;
     xyouts, xmax-(xmax-xmin)*0.2, ymax-(ymax-ymin)*0.1, 'A1&A3', col=0 
     
     ymax = 120.
     ymin = 0.
     obs_tau = tau_a1/sin(elev)
     xmin = 0.0
     xmax = 0.9
     
     plot, obs_tau, nefd_a1, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='!7s!3/sin(el)', ytitle='NEFD [mJy.s^0.5]', /ys, /nodata, pos=pp1[1, *], noerase=1
     
     w = where(nefd_a1 gt 0.0, nn)
     if nn gt 0 then oplot, obs_tau[w], nefd_a1[w], psym=cgsymcat('FILLEDCIRCLE', thick=2*ps_mythick), col=col_1mm,symsize=0.5*ps_mysymsize
     ;;
     obstau = dindgen(1000)/1000.
     oplot, obstau, nefd0_tab[0, 0]*exp(obstau), col=90
     ;;
     xyouts, xmax-(xmax-xmin)*0.13, ymax-(ymax-ymin)*0.13, 'A1', col=0
     
     
     ymax = 120.
     ymin = 0.
     obs_tau = tau_a3/sin(elev)
     xmin = 0.0
     xmax = 0.9
     
     plot, obs_tau, nefd_a3, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='!7s!3/sin(el)', ytitle='NEFD [mJy.s^0.5]', /ys, /nodata, pos=pp1[2, *], noerase=1
     ;;
     w = where(nefd_a3 gt 0.0, nn)
     if nn gt 0 then oplot, obs_tau[w], nefd_a3[w], psym=cgsymcat('FILLEDCIRCLE', thick=2*ps_mythick), col=col_1mm, symsize=0.5*ps_mysymsize
     ;;
     obstau = dindgen(1000)/1000.
     oplot, obstau, nefd0_tab[1, 0]*exp(obstau), col=90
     ;;
     xyouts, xmax-(xmax-xmin)*0.13, ymax-(ymax-ymin)*0.13, 'A3', col=0
     
     ymax = 40.
     ymin = 0.
     obs_tau = tau_a2/sin(elev)
     xmin = 0.0
     xmax = 0.6
     
     plot, obs_tau, nefd_a2, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='!7s!3/sin(el)', ytitle='NEFD [mJy.s^0.5]', /ys, /nodata, pos=pp1[3, *], noerase=1
     
     w = where(nefd_a2 gt 0.0, nn)
     if nn gt 0 then oplot,obs_tau[w], nefd_a2[w], psym=cgsymcat('FILLEDCIRCLE', thick=2.*ps_mythick), col=col_a2, symsize=0.5*ps_mysymsize
     ;;
     obstau = dindgen(1000)/1000.
     oplot, obstau, nefd0_tab[3, 0]*exp(obstau), col=90
     ;;
     xyouts, xmax-(xmax-xmin)*0.13, ymax-(ymax-ymin)*0.13, 'A2', col=0
     outplot, /close
     !p.multi=0
     
     if keyword_set(pdf) then begin
        ;;suf = ['_a1', '_a2', '_a3', '_1mm']
        ;;for i=0, 3 do begin
        ;;spawn, 'epspdf --bbox '+dir+'/plot_nefd_vs_obstau'+plot_suffixe+'.eps'
        ;;endfor
        my_epstopdf_converter, dir+'/plot_nefd_vs_obstau'+plot_suffixe
     endif
     ;; restore plot default characteristics
     !p.thick = 1.0
     !p.charsize  = 1.0
     !p.charthick = 1.0
  endif
        
  
  ;;
  ;;   NEFD COLOR-CODED FROM THE SOURCE
  ;;
  ;;_____________________________________________________________________________________
  colors  = [10, 118, 35, 165, 90, 230, 50, 115, 80, 180, 240, 140, 95, 65, 60, 5]

  nsources = n_elements(sources)
  colors  = colors[0:nsources-1]

  wind, 1, 1, /free, xsize=wxsize, ysize=wysize 
  outfile = dir+'/plot_nefd_vs_obstau_sources'+plot_suffixe
  outplot, file=outfile, png=png, xsize=pxsize, ysize=pysize, charsize=charsize, thick=mythick, charthick=charthick
        
  !p.multi=[0,2,2]
  
  ;; 1mm
  ;;----------------------------------------------------------
  print, ''
  print, ' A1&A3 '
  print, '-----------------------'
  ymax = 120.
  ymin = 0.
  xmax = 0.9
  xmin = 0.
  obs_tau = tau_1mm/sin(elev)
       
  plot, obs_tau, nefd_1mm, /xs, yr=[ymin, ymax], $
        xr=[xmin,xmax], $
        xtitle='!7s!3/sin(el)', ytitle='NEFD [mJy.s^0.5]', /ys, /nodata
  
  for u = 0, nsources-1 do begin
     w = where(strupcase(obj) eq strupcase(sources[u]) and nefd_1mm gt 0.0, nn)
     if nn gt 0 then oplot, obs_tau[w], nefd_1mm[w], psym=cgsymcat('FILLEDCIRCLE', thick=2), col=colors[u], symsize=mysymsize
  endfor
  ;;
  obstau = dindgen(1000)/1000.
  oplot, obstau, nefd0_tab[2, 0]*exp(obstau), col=90
  ;;
  xyouts, xmax-(xmax-xmin)*0.2, ymax-(ymax-ymin)*0.1, 'A1&A3', col=0 
  
  legendastro, sources, col=colors, textcol=0,  psym=8, box=0, charsize=charsize*0.8
        
  ;; A1
  ;;----------------------------------------------------------
  print, ''
  print, ' A1 '
  print, '-----------------------'
  ymax = 120.
  ymin = 0.
  obs_tau = tau_a1/sin(elev)
  xmin = 0.0
  xmax = 0.9
  
  plot, obs_tau, nefd_a1, /xs, yr=[ymin, ymax], $
        xr=[xmin,xmax], $
        xtitle='!7s!3/sin(el)', ytitle='NEFD [mJy.s^0.5]', /ys, /nodata
  
  for u = 0, nsources-1 do begin
     w = where(strupcase(obj) eq strupcase(sources[u]) and nefd_a1 gt 0.0, nn)
     if nn gt 0 then oplot, obs_tau[w], nefd_a1[w], psym=cgsymcat('FILLEDCIRCLE', thick=2), col=colors[u], symsize=mysymsize
  endfor
  ;;
  obstau = dindgen(1000)/1000.
  oplot, obstau, nefd0_tab[0, 0]*exp(obstau), col=90
  ;;
  xyouts, xmax-(xmax-xmin)*0.13, ymax-(ymax-ymin)*0.13, 'A1', col=0
     
          
  ;; A3
  ;;----------------------------------------------------------
  print, ''
  print, ' A3 '
  print, '-----------------------'
  ymax = 120.
  ymin = 0.
  obs_tau = tau_a3/sin(elev)
  xmin = 0.0
  xmax = 0.9

  plot, obs_tau, nefd_a3, /xs, yr=[ymin, ymax], $
        xr=[xmin,xmax], $
        xtitle='!7s!3/sin(el)', ytitle='NEFD [mJy.s^0.5]', /ys, /nodata
  ;;
  for u = 0, nsources-1 do begin
     w = where(strupcase(obj) eq strupcase(sources[u]) and nefd_a3 gt 0.0, nn)
     if nn gt 0 then oplot, obs_tau[w], nefd_a3[w], psym=cgsymcat('FILLEDCIRCLE', thick=2), col=colors[u], symsize=mysymsize
  endfor
  ;;
  obstau = dindgen(1000)/1000.
  oplot, obstau, nefd0_tab[1, 0]*exp(obstau), col=90
  ;;
  xyouts, xmax-(xmax-xmin)*0.13, ymax-(ymax-ymin)*0.13, 'A3', col=0
        
  ;; A2
  ;;----------------------------------------------------------
  print, ''
  print, ' A2 '
  print, '-----------------------'
  ymax = 40.
  ymin = 0.
  obs_tau = tau_a2/sin(elev)
  xmin = 0.0
  xmax = 0.6

  plot, obs_tau, nefd_a2, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
        xtitle='!7s!3/sin(el)', ytitle='NEFD [mJy.s^0.5]', /ys, /nodata

  for u = 0, nsources-1 do begin
     w = where(strupcase(obj) eq strupcase(sources[u]) and nefd_a2 gt 0.0, nn)
     if nn gt 0 then oplot, obs_tau[w], nefd_a2[w], psym=cgsymcat('FILLEDCIRCLE', thick=2), col=colors[u], symsize=mysymsize
  endfor
  ;;
  obstau = dindgen(1000)/1000.
  oplot, obstau, nefd0_tab[3, 0]*exp(obstau), col=90
  ;;
  xyouts, xmax-(xmax-xmin)*0.13, ymax-(ymax-ymin)*0.13, 'A2', col=0
  
  outplot, /close
  !p.multi = 0
  
  if keyword_set(ps) then begin

     outfile = dir+'/plot_nefd_vs_obstau_sources'+plot_suffixe
     outplot, file=outfile, ps=ps, xsize=ps_pxsize, ysize=ps_pysize, charsize=ps_charsize, thick=ps_mythick, charthick=ps_charthick

     my_multiplot, 2, 2, pp, pp1, /rev, gap_y=0.1, gap_x=0.1, xmargin=0.1, ymargin=0.1 ; 1e-6
     
     ymax = 120.
     ymin = 0.
     xmax = 0.9
     xmin = 0.
     obs_tau = tau_1mm/sin(elev)
     
     plot, obs_tau, nefd_1mm, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='!7s!3/sin(el)', ytitle='NEFD [mJy.s^0.5]', /ys, /nodata, pos=pp1[0, *]

     for u = 0, nsources-1 do begin
        w = where(strupcase(obj) eq strupcase(sources[u]) and nefd_1mm gt 0.0, nn)
        if nn gt 0 then oplot, obs_tau[w], nefd_1mm[w], psym=cgsymcat('FILLEDCIRCLE', thick=2), col=colors[u], symsize=mysymsize
     endfor
     ;;
     obstau = dindgen(1000)/1000.
     oplot, obstau, nefd0_tab[2, 0]*exp(obstau), col=90
     ;;
     xyouts, xmax-(xmax-xmin)*0.2, ymax-(ymax-ymin)*0.1, 'A1&A3', col=0 
     
     
     ymax = 120.
     ymin = 0.
     obs_tau = tau_a1/sin(elev)
     xmin = 0.0
     xmax = 0.9
     
     plot, obs_tau, nefd_a1, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='!7s!3/sin(el)', ytitle='NEFD [mJy.s^0.5]', /ys, /nodata, pos=pp1[1, *], noerase=1
     for u = 0, nsources-1 do begin
        w = where(strupcase(obj) eq strupcase(sources[u]) and nefd_a1 gt 0.0, nn)
        if nn gt 0 then oplot, obs_tau[w], nefd_a1[w], psym=cgsymcat('FILLEDCIRCLE', thick=2), col=colors[u], symsize=mysymsize
     endfor
     ;;
     obstau = dindgen(1000)/1000.
     oplot, obstau, nefd0_tab[0, 0]*exp(obstau), col=90
     ;;
     xyouts, xmax-(xmax-xmin)*0.13, ymax-(ymax-ymin)*0.13, 'A1', col=0
     ;;legendastro, sources, col=colors, textcol=0,  psym=8, box=0, charsize=ps_charsize*0.8
     
     
     ymax = 120.
     ymin = 0.
     obs_tau = tau_a3/sin(elev)
     xmin = 0.0
     xmax = 0.9
     
     plot, obs_tau, nefd_a3, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='!7s!3/sin(el)', ytitle='NEFD [mJy.s^0.5]', /ys, /nodata, pos=pp1[2, *], noerase=1
     ;;
     for u = 0, nsources-1 do begin
        w = where(strupcase(obj) eq strupcase(sources[u]) and nefd_a3 gt 0.0, nn)
        if nn gt 0 then oplot, obs_tau[w], nefd_a3[w], psym=cgsymcat('FILLEDCIRCLE', thick=2), col=colors[u], symsize=mysymsize
     endfor
     ;;
     obstau = dindgen(1000)/1000.
     oplot, obstau, nefd0_tab[1, 0]*exp(obstau), col=90
     ;;
     xyouts, xmax-(xmax-xmin)*0.13, ymax-(ymax-ymin)*0.13, 'A3', col=0
     ;;legendastro, sources, col=colors, textcol=0,  psym=8, box=0, charsize=charsize*0.8
          
     ymax = 40.
     ymin = 0.
     obs_tau = tau_a2/sin(elev)
     xmin = 0.0
     xmax = 0.6
     
     plot, obs_tau, nefd_a2, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='!7s!3/sin(el)', ytitle='NEFD [mJy.s^0.5]', /ys, /nodata, pos=pp1[3, *], noerase=1
     
     for u = 0, nsources-1 do begin
        w = where(strupcase(obj) eq strupcase(sources[u]) and nefd_a2 gt 0.0, nn)
        if nn gt 0 then oplot, obs_tau[w], nefd_a2[w], psym=cgsymcat('FILLEDCIRCLE', thick=2), col=colors[u], symsize=mysymsize
     endfor
     ;;
     obstau = dindgen(1000)/1000.
     oplot, obstau, nefd0_tab[3, 0]*exp(obstau), col=90
     ;;
     xyouts, xmax-(xmax-xmin)*0.13, ymax-(ymax-ymin)*0.13, 'A2', col=0
     legendastro, sources, col=colors, textcol=0,  psym=8, box=0, charsize=ps_charsize*0.8
     
     outplot, /close
     !p.multi=0
     
     if keyword_set(pdf) then begin
        ;;suf = ['_a1', '_a2', '_a3', '_1mm']
        ;;for i=0, 3 do begin
        ;;spawn, 'epspdf --bbox '+dir+'/plot_nefd_vs_obstau_sources'+plot_suffixe+'.eps'
        ;;endfor
        my_epstopdf_converter, dir+'/plot_nefd_vs_obstau_sources'+plot_suffixe
     endif
     ;; restore plot default characteristics
     !p.thick = 1.0
     !p.charsize  = 1.0
     !p.charthick = 1.0
  endif


    
end
