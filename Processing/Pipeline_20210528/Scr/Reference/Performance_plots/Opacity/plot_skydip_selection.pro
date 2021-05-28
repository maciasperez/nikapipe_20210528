pro plot_skydip_selection, png=png, ps=ps


  ;;coltab = [210, 250, 75] ; A1, A3, A2

  plot_color_convention, col_a1, col_a2, col_a3, $
                         col_mwc349, col_crl2688, col_ngc7027, $
                         col_n2r9, col_n2r12, col_n2r14
  
  coltab = [col_a1, col_a3, col_a2]

  ;;if keyword_set(ps) then begin 
  ;;endif

  
  ;; plot pour N2R9
  runname = 'N2R9'
  dir     = getenv('HOME')+'/NIKA/Plots/Commissioning_doc/'
  
  dt_max  = 1.6d0 ; K 
  rms_max = 1.5d4 ; Hz
  
;;----------------------------------------------------------------------------------
;; READ  OPACITY ESTIMATION OUTPUTS
;;----------------------------------------------------------------------------------  
  output_dir = getenv('HOME')+'/NIKA/Plots/'+runname+'/Opacity'
  base_file_suffixe = '_ref'
  
  ;; v0
  file_suffixe = base_file_suffixe+'_v0'
  
  testkidpar_file = output_dir+'/kidpar_C0C1_'+strupcase(runname)+strtrim(file_suffixe, 2)+'.fits'
  print, "v0 kidpar = ", testkidpar_file
  kidpar_v0 = mrdfits(testkidpar_file, 1)
  
  testsave_file = output_dir+'/all_skydip_fit_'+strupcase(runname)+strtrim(file_suffixe,2)+'.save'
  print, "v0 skydip struct = ",  testsave_file
  restore, testsave_file, /v
  skdout_v0 = skdout
  
  ;; v1
  suf = '_baseline'
  file_suffixe = base_file_suffixe+suf
  
  testkidpar_file = output_dir+'/kidpar_C0C1_'+strupcase(runname)+strtrim(file_suffixe, 2)+'.fits'
  print, "v1 kidpar = ", testkidpar_file
  kidpar_v1 = mrdfits(testkidpar_file, 1)
  
  testsave_file = output_dir+'/all_skydip_fit_'+strupcase(runname)+strtrim(file_suffixe,2)+'.save'
  print, "v1 skydip struct = ",  testsave_file
  restore, testsave_file, /v
  skdout_v1 = skdout

;;----------------------------------------------------------------------------------
;; PLOT
;;----------------------------------------------------------------------------------  

  
  scan_list = skdout_v0.scanname 
  nsc       = n_elements(scan_list)  
  index_v0  = indgen(nsc)

  my_match, skdout_v1.scanname, scan_list, suba, subb
  index_v1  = index_v0(subb)
  nsc_v1 = n_elements(skdout_v1.scanname)
  
  wind, 1, 1, /free, xsize=600, ysize=400 
  outfile = dir+'plot_skydip_selection_median_rms'
  outplot, file=outfile, png=png, ps=ps, xsize=600, ysize=400, charsize=1, thick=2, charthick=1.2
  
  plot, index_v0, skdout_v0.rmsa1, xrange = [-1, nsc], /xs, /nodata, $
        yrange = [0, max([skdout_v0.rmsa1, skdout_v0.rmsa2, skdout_v0.rmsa3])*1.1d-4], /ys, $
        thick = 2, ytitle = 'Median rms [x 10^4 Hz]', xtitle = 'Skydip scan index'
  oplot, index_v0, skdout_v0.rmsa1*1d-4, psym=4, col=coltab[0], symsize=0.8, thick=2
  oplot, index_v0, skdout_v0.rmsa3*1d-4, psym=4, col=coltab[1], symsize=0.8, thick=2
  oplot, index_v0, skdout_v0.rmsa2*1d-4, psym=4, col=coltab[2], symsize=0.8, thick=2
  oplot, index_v1+1, skdout_v1.rmsa1*1d-4, psym=8, col=coltab[0], symsize=0.8
  oplot, index_v1+1, skdout_v1.rmsa3*1d-4, psym=8, col=coltab[1], symsize=0.8
  oplot, index_v1+1, skdout_v1.rmsa2*1d-4, psym=8, col=coltab[2], symsize=0.8
  oplot, [-1, nsc], [1, 1]*rms_max*1d-4, col=0
  legendastro, ['A1', 'A3', 'A2'], col=coltab, textcol=coltab, box=0
  legendastro, ['v1', 'v2'], col=[0,0], psym=[4, 8], thick=[2, 1], symsize=[0.8, 0.8], box=0, /right
  outplot, /close
  
  dtall_v0 = fltarr(3, nsc)
  dtall_v1 = fltarr(3, nsc_v1)
  dtarr_v0 = skdout_v0.dt
  dtarr_v1 = skdout_v1.dt
  for narr = 1, 3 do begin      ; loop on arrays
     kidall = where( kidpar_v0.type eq 1 and $
                     kidpar_v0.array eq narr, nallkid)       
     
     for isc = 0, nsc-1 do begin ; Median function does not exclude Nans
        u = where( finite( dtarr_v0[ kidall, isc]) eq 1, nu)
        if nu gt 3 then dtall_v0[narr-1, isc]= $
           median(/double, dtarr_v0[ kidall[ u], isc])
     endfor
     kidall = where( kidpar_v1.type eq 1 and $
                     kidpar_v1.array eq narr, nallkid)
     for isc = 0, nsc_v1-1 do begin ; Median function does not exclude Nans
        u = where( finite( dtarr_v1[ kidall, isc]) eq 1, nu)
        if nu gt 3 then dtall_v1[narr-1, isc]= $
           median(/double, dtarr_v1[ kidall[ u], isc])
     endfor
  endfor
  
  
  wind, 1, 1, /free, xsize=600, ysize=400 
  outfile = dir+'plot_skydip_selection_median_dt'
  outplot, file=outfile, png=png, ps=ps, xsize=12, ysize=8, charsize=1, thick=2, charthick=1.2

  subind = [0, 2, 1]
  plot, index_v0, dtall_v0[0, *], xrange = [-1, nsc], /xs, /nodata, $
        yrange = [min([dtall_v0])*1.1, max([dtall_v0])*1.1], /ys, $
        thick = 2, ytitle = 'Median dT [K]', xtitle = 'Skydip scan index'
  for ia=0, 2 do oplot, index_v0, dtall_v0[ia, *], psym=4, col=coltab[subind[ia]], symsize=0.8, thick=2 
  for ia=0, 2 do oplot, index_v1+1, dtall_v1[ia, *], psym=8, col=coltab[subind[ia]], symsize=0.8
 
  oplot, [-1, nsc], [1, 1]*dt_max, col=0
  oplot, [-1, nsc], [-1, -1]*dt_max, col=0
  legendastro, ['A1', 'A3', 'A2'], col=coltab, textcol=coltab, box=0
  outplot, /close

  wind, 1, 1, /free, xsize=600, ysize=400 
  outfile = dir+'plot_skydip_selection_two_crit'
  outplot, file=outfile, png=png, ps=ps, xsize=12, ysize=8, charsize=1, thick=2, charthick=1.2

  rmsall_v0 = transpose([[skdout_v0.rmsa1], [skdout_v0.rmsa2],[skdout_v0.rmsa3]])
  rmsall_v1 = transpose([[skdout_v1.rmsa1], [skdout_v1.rmsa2],[skdout_v1.rmsa3]])
  subind = [0, 2, 1]
  plot,  rmsall_v0[0, *], dtall_v0[0, *], $
         xrange = [min([rmsall_v0])*0.9, $
                   max(rmsall_v0)*1.1], /xs, /nodata, $
         yrange = [min([dtall_v0])*1.1, max([dtall_v0])*1.1], /ys, $
         thick = 2, ytitle = 'Median dT [K]', xtitle = 'Median rms [Hz]', /xlog

  loadct, 0
  polyfill, [min([rmsall_v0])*0.9, max(rmsall_v0)*1.1, max(rmsall_v0)*1.1, min([rmsall_v0])*0.9 ], $
            [dt_max, dt_max,max([dtall_v0])*1.1,max([dtall_v0])*1.1  ], col=230
  polyfill, [min([rmsall_v0])*0.9, max(rmsall_v0)*1.1, max(rmsall_v0)*1.1, min([rmsall_v0])*0.9 ], $
            [-1*dt_max, -1*dt_max, min([dtall_v0])*1.1, min([dtall_v0])*1.1  ], col=230
  
  polyfill, [rms_max,  max(rmsall_v0)*1.1,  max(rmsall_v0)*1.1, rms_max], $
            [min([dtall_v0])*1.1, min([dtall_v0])*1.1,  max([dtall_v0])*1.1, max([dtall_v0])*1.1], col=220, transparent=0.5
  ;;loadct, 39
  plot_color_convention
  plot,  rmsall_v0[0, *], dtall_v0[0, *], $
         xrange = [min([rmsall_v0])*0.9, $
                   max(rmsall_v0)*1.1], /xs, /nodata, $
         yrange = [min([dtall_v0])*1.1, max([dtall_v0])*1.1], /ys, $
         thick = 2, /xlog, /noerase
 
  for ia=0, 2 do oplot,rmsall_v0[ia, *], dtall_v0[ia, *], psym=4, col=coltab[subind[ia]], symsize=0.8, thick=2 
  for ia=0, 2 do oplot,rmsall_v1[ia, *], dtall_v1[ia, *], psym=8, col=coltab[subind[ia]], symsize=0.8
  oplot, [1, 1]*rms_max, [-10, 10], col=0
  oplot, [1, 1d9], [1, 1]*dt_max, col=0
  oplot, [1, 1d9], [-1, -1]*dt_max, col=0
  legendastro, ['A1', 'A3', 'A2'], col=coltab, textcol=coltab, box=0
  legendastro, ['v1', 'v2'], col=[0,0], psym=[4, 8], thick=[2, 1], symsize=[0.8, 0.8], box=0, pos=[rms_max+2000, 8]

  outplot, /close

  print, 'End of plot_skydip_selection'
  print, 'out ?'
  stop


  
end
