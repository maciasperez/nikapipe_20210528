; Take a list of scans and make maps per subscan. Deduce if the source
; is moving or not. Here is the analysis part (after the processing
; part in anom_refrac)
pro anom_refrac_analyse, scan_list, source, obstype, $
                         n2run, inft, $
                         plot = k_plot, jpg = k_jpg
  
  nk_default_param, param
  param.project_dir = param.dir_save+ '/'+ source
  param.do_opacity_correction = 6
  param.iconic = 1
  param.map_proj = 'AZEL'
  param.version = '4'           ; '4' with pipeline improved corrections
  param.silent = 1
  nscans = n_elements( scan_list)
  for isc = 0, nscans-1 do begin
     outdir = param.project_dir+"/v_"+strtrim(param.version,2)+ $
              "/"+strtrim(scan_list[ isc],2)
     nk_read_csv_2, outdir+'/info.csv', info1
     if isc eq 0 then begin     ; init
        nsubscan = info1.nsubscans+1
        inft = replicate( info1, nsubscan+1-1, nscans) ; the whole pointing, then 4 subscans
        ntag = n_tags( info1)
     endif
     for itag = 0, ntag-1 do inft[0, isc].(itag) = info1.(itag)
     for isub = 1, nsubscan-1 do begin
        outdir = param.project_dir+"/v_"+strtrim(param.version,2)+ $
                 "/"+strtrim(scan_list[ isc],2)+ $
                 '/sub'+strtrim(isub+1,2)
        nk_read_csv_2, outdir+'/info.csv', info1
        for itag = 0, ntag-1 do inft[isub, isc].(itag) = info1.(itag)
     endfor
  endfor
  print, '1mm ----flux [Jy], dx [arcsec], dy [arcsec], scan+subscans-------'
  print, ' dx,dy in AzEl coordinates with respect to the scan average'
  for isc = 0, nscans-1 do print, isc, inft[0, isc].object, scan_list[ isc], $
                                  inft[*, isc].result_flux_i_1mm,  format = '(I3,A10,A14,8F7.3)'
  for isc = 0, nscans-1 do print,isc, inft[*, isc].result_off_x_1mm-inft[0, isc].result_off_x_1mm,  format = '(I3,5F7.1)'
  for isc = 0, nscans-1 do print,isc, inft[*, isc].result_off_y_1mm-inft[0, isc].result_off_y_1mm,  format = '(I3,5F7.1)'
  print, '2mm --------------------'
  for isc = 0, nscans-1 do print, isc, inft[0, isc].object, scan_list[ isc], $
                                  inft[*, isc].result_flux_i_2mm,  format = '(I3,A10,A14,8F7.3)'
  for isc = 0, nscans-1 do print, isc, inft[*, isc].result_off_x_2mm-inft[0, isc].result_off_x_2mm,  format = '(I3, 5F7.1)'
  for isc = 0, nscans-1 do print,isc, inft[*, isc].result_off_y_2mm-inft[0, isc].result_off_y_2mm,  format = '(I3,5F7.1)'

  dlim = 10.                    ; aberrant points above 10 arcseconds
  flim = .5                     ; only sources with flux above that are used
  f1 = reform(replicate(1.,nsubscan-1)#inft[0, *].result_flux_i_1mm)
  f2 = reform(replicate(1.,nsubscan-1)#inft[0, *].result_flux_i_2mm)
  x1 = reform(inft[1:nsubscan-1, *].result_off_x_1mm- $
              replicate(1.,nsubscan-1)#inft[0, *].result_off_x_1mm)
  x2 = reform(inft[1:nsubscan-1, *].result_off_x_2mm- $
              replicate(1.,nsubscan-1)#inft[0, *].result_off_x_2mm)
  u = where(x1 eq 0 or abs(x1) gt dlim or f1 lt flim or f2 lt flim, nu)
  if nu ne 0 then x1[u] = !values.f_nan
; zero is obtained when a subscan could not be reduced.
  u = where(x2 eq 0 or abs(x2) gt dlim or f1 lt flim or f2 lt flim, nu)
  if nu ne 0 then x2[u] = !values.f_nan
  y1 = reform(inft[1:nsubscan-1, *].result_off_y_1mm- $
              replicate(1.,nsubscan-1)#inft[0, *].result_off_y_1mm)
  y2 = reform(inft[1:nsubscan-1, *].result_off_y_2mm- $
              replicate(1.,nsubscan-1)#inft[0, *].result_off_y_2mm)
  u = where(y1 eq 0 or abs(y1) gt dlim or f1 lt flim or f2 lt flim, nu)
  if nu ne 0 then y1[u] = !values.f_nan
  u = where(y2 eq 0 or abs(y2) gt dlim or f1 lt flim or f2 lt flim, nu)
  if nu ne 0 then y2[u] = !values.f_nan
; do now the distance
  d1 = sqrt(x1^2+y1^2)
  d2 = sqrt(x2^2+y2^2)


  if keyword_set( k_plot) then begin
     if keyword_set( k_jpg) then begin
        prepare_jpgout, 1, ct = 39, /norev, /icon
        prepare_jpgout, 2, ct = 39, /norev, /icon
        prepare_jpgout, 3, ct = 39, /norev, /icon
     endif
     
     wshet, 1
     xra = [-4, 4]*2.5
     yra = xra
     !p.multi = [0, 2, 2]
     plot, psym = 4, x1, x2, /iso, xsty = 0, ysty = 0, $
           title = source+ ' Run:'+n2run, $
           xtitle = 'DeltaX 1mm [arcsec]', ytitle = 'DeltaX 2mm [arcsec]', $
           xra = xra, yra = xra
     plot, psym = 4, y1, y2, /iso, xsty = 0, ysty = 0, $
           xtitle = 'DeltaY 1mm [arcsec]', ytitle = 'DeltaY 2mm [arcsec]', $
           xra = yra, yra = yra
     plot, psym = 4, x1, y1, /iso, xsty = 0, ysty = 0, $
           xtitle = 'DX1', ytitle = 'DY1', $
           xra = xra, yra = yra
     plot, psym = 4, x2, y2, /iso, xsty = 0, ysty = 0, $
           xtitle = 'DX2', ytitle = 'DY2', $
           xra = xra, yra = yra
     if keyword_set( k_jpg) then begin
        jpgfile = !nika.plot_dir+'/Test_AnomRefrac1_'+source+'_'+obstype+ '_'+n2run +'_'+ param.version+ '.jpg'
        print, 'Making jpg files : '+ jpgfile
        jpgout, jpgfile ,/over
     endif
     
; Show histograms
     wshet, 2
     nbi = nint(1000.*(nscans/300.))
     !p.multi = [0, 2, 2]
     histo_make, x1, xarr, yarr, sres, gres, /plot, /stat, /gauss, /nan, $
                 minval = xra[0], maxval = xra[1], n_bins = nbi, $
                 xtitle = 'DX1', ytitle = 'Number of occurences', $
                 /legend, xsty = 0, $
                 title = source+ ' '+obstype+ ' Run:'+n2run
     histo_make, y1, xarr, yarr, sres, gres, /plot, /stat, /gauss, /nan, $
                 minval = xra[0], maxval = xra[1], n_bins = nbi, $
                 xtitle = 'DY1', ytitle = 'Number of occurences', $
                 /legend, xsty = 0
     histo_make, x2, xarr, yarr, sres, gres, /plot, /stat, /gauss, /nan, $
                 minval = xra[0], maxval = xra[1], n_bins = nbi, $
                 xtitle = 'DX2', ytitle = 'Number of occurences', $
                 /legend, xsty = 0
     histo_make, y2, xarr, yarr, sres, gres, /plot, /stat, /gauss, /nan, $
                 minval = xra[0], maxval = xra[1], n_bins = nbi, $
                 xtitle = 'DY2', ytitle = 'Number of occurences', $
                 /legend, xsty = 0

     if keyword_set( k_jpg) then jpgout, !nika.plot_dir+'/Test_AnomRefrac2_'+source+'_'+obstype+ '_'+n2run +'_'+ param.version+ '.jpg',/over

     wshet, 3
     !p.multi = [0, 2, 2]
     plot, psym = 4, d1, d2, /iso, xsty = 0, ysty = 0, $
           title = source+ ' Run:'+n2run, subtitle = obstype, $
           xtitle = 'D1 [arcsec]', ytitle = 'D2 [arcsec]', $
           xra = [0, 10], yra = [0, 10]
     histo_make, d1, xarr, yarr, sres, gres, /plot, /stat,  /nan, $
                 minval = 0.000001, maxval = 10, n_bins = 33, $
                 xtitle = 'D1', ytitle = 'Number of occurences', $
                 xsty = 0
     !p.multi = [1, 2, 2]
     histo_make, d2, xarr, yarr, sres, gres, /plot, /stat, /nan, $
                 minval = 0.000001, maxval = 10, n_bins = 33, $
                 xtitle = 'D2', ytitle = 'Number of occurences', $
                 xsty = 0
     if keyword_set( k_jpg) then jpgout, !nika.plot_dir+'/Test_AnomRefrac3_'+source+'_'+obstype+ '_'+n2run +'_'+ param.version+ '.jpg',/over

  endif

; When are the bad pointings occurring?
  dbad = 2.5                    ; limit over which one considers a bad pointing
  x1 = reform(inft[1:nsubscan-1, *].result_off_x_1mm- $
              replicate(1.,nsubscan-1)#inft[0, *].result_off_x_1mm)
  x2 = reform(inft[1:nsubscan-1, *].result_off_x_2mm- $
              replicate(1.,nsubscan-1)#inft[0, *].result_off_x_2mm)
  y1 = reform(inft[1:nsubscan-1, *].result_off_y_1mm- $
              replicate(1.,nsubscan-1)#inft[0, *].result_off_y_1mm)
  y2 = reform(inft[1:nsubscan-1, *].result_off_y_2mm- $
              replicate(1.,nsubscan-1)#inft[0, *].result_off_y_2mm)
  d1 = sqrt(x1^2+y1^2)
  d2 = sqrt(x2^2+y2^2)

  u = where( d1 gt dbad and f1 gt flim and f2 gt flim, nu)
  if nu ne 0 then begin
     v = u/(nsubscan-1)
     vun = v[ uniq(v)]
     nvun = n_elements( vun)
     stop
     for ivun = 0, nvun-1 do $
        print, source, ' Anomalous scan ', scan_list[ vun[ ivun]], $
               d1[ *, vun[ivun]], $
               format = '(A10,A15,A13,A1,20F6.2)'
  endif else print, 'No anomalous scan'


  return
end
