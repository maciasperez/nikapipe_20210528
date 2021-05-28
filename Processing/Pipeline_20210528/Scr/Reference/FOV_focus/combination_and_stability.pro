pro combination_and_stability

  project_dir    = !nika.plot_dir+"/fov_focus_2"

  savepng = 0
  suffixe = ''
  
  list_sequence = [['20170419s'+strtrim([133, 134, 135, 136, 137], 2)], $
                   ['20170226s'+strtrim([415, 416, 417, 418, 419],2)], $
                   ['20170424s'+strtrim([123, 124, 125, 126, 127],2)], $
                   ['20170422s'+strtrim([61, 62, 63, 64, 65],2)], $
                   ['20170421s'+strtrim([160, 161, 162, 163, 164],2)], $
                   ['20170420s'+strtrim([113, 114, 115, 116, 117],2)]]

  flag_sequence = [1, 1, 1, 0, 1, 1]

  wseq = where(flag_sequence gt 0, nseq)


  
  list_kidpar_file = [!nika.off_proc_dir+"/kidpar_20170419s133_v2_cm_one_block_LP_calib.fits", $
                      !nika.off_proc_dir+"/kidpar_20170226s415_FXDC0C1_GaussPhot.fits", $
                      !nika.off_proc_dir+"/kidpar_20170424s123_v2_cm_one_block_LP_calib.fits", $
                      !nika.off_proc_dir+"/kidpar_20170422s61_v2_cm_one_block_LP_calib.fits", $
                      !nika.off_proc_dir+"/kidpar_20170421s160_v2_cm_one_block_LP_calib.fits", $
                      !nika.off_proc_dir+"/kidpar_20170420s113_JFMP_v2_cm_one_block_LP_calib.fits"]

  list_kidpar_file = [!nika.off_proc_dir+"/kidpar_20170419s133_v2_cm_one_block_LP.fits", $
                      !nika.off_proc_dir+"/kidpar_20170226s415_FXDC0C1_GaussPhot.fits", $
                      !nika.off_proc_dir+"/kidpar_20170424s123_v2_cm_one_block_LP_calib.fits", $
                      !nika.off_proc_dir+"/kidpar_20170422s61_v2_cm_one_block_LP_calib.fits", $
                      !nika.off_proc_dir+"/kidpar_20170421s160_v2_cm_one_block_LP_calib.fits", $
                      !nika.off_proc_dir+"/kidpar_20170420s113_JFMP_v2_cm_one_block_LP_calib.fits"]

  do_median  = 0
  do_stddev  = 0
  do_mv      = 0
  do_mv_err  = 1
  do_1d_plot = 0

  plot_histo = 0
  
  if do_mv_err gt 0 then do_mv = 1


  
  ;; union of the kidpars
  numdets = ''
  arrays  = ''
  nas_xs  = ''
  nas_ys  = '' 
  for ikp = 0, nseq-1 do begin
     print, list_kidpar_file[wseq[ikp]]
     kp = mrdfits(list_kidpar_file[wseq[ikp]], 1)
     numdets = [numdets, kp.numdet]
     arrays  = [arrays, kp.array]
     nas_xs  = [nas_xs, kp.nas_x]
     nas_ys  = [nas_ys, kp.nas_y]
  endfor
  numdets = numdets[1:*]
  arrays  = arrays[ 1:*]
  nas_xs  = nas_xs[ 1:*]
  nas_ys  = nas_ys[ 1:*]
  wsort   = UNIQ(numdets, SORT(numdets))
  numdets = numdets[wsort]
  arrays  = arrays[ wsort]
  nas_xs  = nas_xs[ wsort]
  nas_ys  = nas_ys[ wsort]

  
  nkids = lonarr(3)
  for ilam=0, 2 do begin
     w = where(arrays eq ilam+1, nw)
     nkids[ilam] = nw
  endfor
  nkids = max(nkids)

  z_peak_tab = fltarr(nkids, 3, nseq)+!VALUES.F_NAN
  z_flux_tab = fltarr(nkids, 3, nseq)+!VALUES.F_NAN
  z_fwhm_tab = fltarr(nkids, 3, nseq)+!VALUES.F_NAN

  err_peak_tab = fltarr(nkids, 3, nseq)+!VALUES.F_NAN
  err_flux_tab = fltarr(nkids, 3, nseq)+!VALUES.F_NAN
  err_fwhm_tab = fltarr(nkids, 3, nseq)+!VALUES.F_NAN

  nas_x_tab   = dblarr(nkids, 3, nseq)+!VALUES.F_NAN
  nas_y_tab   = dblarr(nkids, 3, nseq)+!VALUES.F_NAN
  
  debug = 0
  
  for iseq = 0, nseq-1 do begin
     scan_list = list_sequence[*, wseq[iseq]]
     nscans = n_elements(scan_list)
     
     kp = mrdfits(list_kidpar_file[wseq[iseq]], 1)
     
     
     ;; debug
     if debug gt 0 then begin
        wind, 1, 1, /free, xsize=900, ysize=750, title=strtrim(scan_list[0],2)+'_'+strtrim(scan_list[nscans-1],2)
        outplot, file=output_plot_file, png=png
        my_multiplot, 3, 3, pp, pp1, ymargin=0.08, gap_x=0.08, xmargin = 0.06
        charsize = 0.8
        order = [1, 3, 2]
        ss = [0.4, 0.5, 0.4]
        print, "***"
        print,"sequence: ",strtrim(scan_list[0],2)+'_'+strtrim(scan_list[nscans-1],2) 
     endif
     ;;
     
     for ilam = 0, 2 do begin
        iarray = ilam+1
        w1 = where(kp.type eq 1 and kp.array eq iarray)
        output_file = project_dir+'/fov_focus_'+strtrim(scan_list[0],2)+'_'+strtrim(scan_list[nscans-1],2)+'_A'+strtrim(iarray,2)+'.save'
        restore, output_file
        warray = where(arrays eq iarray, nw)
        print, nw
        my_match, numdets[warray], numdet, suba, subb
        z_peak_tab[  suba,ilam,iseq] = dz_peak[subb]
        z_flux_tab[  suba,ilam,iseq] = dz_flux[subb]
        z_fwhm_tab[  suba,ilam,iseq] = dz_fwhm[subb]
        err_peak_tab[suba,ilam,iseq] = s_peak[ subb]
        err_flux_tab[suba,ilam,iseq] = s_flux[ subb]
        err_fwhm_tab[suba,ilam,iseq] = s_fwhm[ subb]

        nas_x_tab[suba, ilam, iseq]  = kp[w1[subb]].nas_x
        nas_y_tab[suba, ilam, iseq]  = kp[w1[subb]].nas_y

        ;; debug
        if debug gt 0 then begin
           print,"A",strtrim(iarray,2)
           ;; matrix_plot,nas_xs[warray[suba]], nas_ys[warray[suba]], z_peak_tab[  suba,ilam,iseq], $
           ;;             position=pp[ilam,0,*], title='Peak focus A'+strtrim(iarray,2), /noerase, $
           ;;             charsize=charsize, xra=xra, yra=yra, zra=[-0.4, 0.4], format='(f6.2)',/iso, symsize=ss[iarray-1]
           ;; matrix_plot, nas_xs[warray[suba]], nas_ys[warray[suba]],z_flux_tab[  suba,ilam,iseq], $
           ;;              position=pp[ilam,1,*], title='Flux focus A'+strtrim(iarray,2), /noerase, $
           ;;              charsize=charsize, xra=xra, yra=yra, zra=[-0.4, 0.4], format='(f6.2)', /iso, symsize=ss[iarray-1]
           ;; matrix_plot, nas_xs[warray[suba]], nas_ys[warray[suba]], z_fwhm_tab[  suba,ilam,iseq],  $
           ;;              position=pp[ilam,2,*], title='FWHM focus A'+strtrim(iarray,2), /noerase, $
           ;;              charsize=charsize, xra=xra, yra=yra,
           ;;              zra=[-0.4, 0.4], format='(f6.2)', /iso,
           ;;              symsize=ss[iarray-1]
           matrix_plot,nas_xs[warray[suba]], nas_ys[warray[suba]], err_peak_tab[  suba,ilam,iseq], $
                       position=pp[ilam,0,*], title='Peak focus A'+strtrim(iarray,2), /noerase, $
                       charsize=charsize, xra=xra, yra=yra, zra=[-0.1, 0.2], format='(f6.2)',/iso, symsize=ss[iarray-1]
           matrix_plot, nas_xs[warray[suba]], nas_ys[warray[suba]],err_flux_tab[  suba,ilam,iseq], $
                        position=pp[ilam,1,*], title='Flux focus A'+strtrim(iarray,2), /noerase, $
                        charsize=charsize, xra=xra, yra=yra, zra=[-0.1, 0.2], format='(f6.2)', /iso, symsize=ss[iarray-1]
           matrix_plot, nas_xs[warray[suba]], nas_ys[warray[suba]], err_fwhm_tab[  suba,ilam,iseq],  $
                        position=pp[ilam,2,*], title='FWHM focus A'+strtrim(iarray,2), /noerase, $
                        charsize=charsize, xra=xra, yra=yra, zra=[-0.1, 0.2], format='(f6.2)', /iso, symsize=ss[iarray-1]

           w=where(finite(err_flux_tab[*, ilam, iseq]) eq 1., ndef)
           print,"finite = ", ndef
           w=where(err_flux_tab[*, ilam, iseq] eq 0., nzero) 
           print,"zero = ", nzero
           print,"---"
        endif
        ;;
        
     endfor
  endfor

  if debug then stop

  ;; median surfaces
  ;;__________________________________

  if do_median gt 0 then  begin
     
     output_plot_file =  project_dir+'/fov_focus_median_'+strtrim(nseq,2)+suffixe
     
     png=savepng

     med_z_peak = dblarr(nkids, 3)-10.
     med_z_flux = dblarr(nkids, 3)-10.
     med_z_fwhm = dblarr(nkids, 3)-10.
     
     med_stddev_z = dblarr(nkids, 3)-10.
     
     zra=[-0.4, 0.4]
     
     wind, 1, 1, /free, xsize=900, ysize=740
     outplot, file=output_plot_file, png=png
     my_multiplot, 3, 3, pp, pp1, ymargin=0.08, gap_x=0.08, xmargin = 0.06
     charsize = 0.8
     order = [1, 3, 2]
     ss = [0.4, 0.5, 0.4]
     for ilam=0, 2 do begin
        iarray = order[ilam]
        print, '***'
        print, 'Array ', strtrim(iarray,2)
        
        warray = where(arrays eq iarray, nwarray)
        nas_xa = nas_xs[warray]
        nas_ya = nas_ys[warray]
        
        for ik=0, nkids-1 do begin
           w=where(finite(z_peak_tab[ik,iarray-1,*]) eq 1, nw)
           if nw gt 0 then med_z_peak[ik, iarray-1] = median(z_peak_tab[ik,iarray-1,w])
           w=where(finite(z_flux_tab[ik,iarray-1,*]) eq 1, nw)
           if nw gt 0 then med_z_flux[ik, iarray-1] = median(z_flux_tab[ik,iarray-1,w])
           w=where(finite(z_fwhm_tab[ik,iarray-1,*]) eq 1, nw)
           if nw gt 0 then med_z_fwhm[ik, iarray-1] = median(z_fwhm_tab[ik,iarray-1,w])
           ;;
           w=where(finite(nas_x_tab[ik,iarray-1,*]) eq 1, nw)
           if nw gt 0 then nas_xa[ik] = median(nas_x_tab[ik,iarray-1,w])
           w=where(finite(nas_y_tab[ik,iarray-1,*]) eq 1, nw)
           if nw gt 0 then nas_ya[ik] = median(nas_y_tab[ik,iarray-1,w])
        endfor

        wdef = where(med_z_fwhm[*, iarray-1] gt -10. and med_z_flux[*, iarray-1] gt -10. and med_z_flux[*, iarray-1] gt -10., nwdef)
        for ik =0, nwdef-1 do begin
           ii = wdef[ik]
           med_stddev_z[ii, iarray-1] = stddev([med_z_fwhm[ii, iarray-1], med_z_flux[ii, iarray-1], med_z_peak[ii, iarray-1]])
        endfor
        


        
        wdef = where(med_z_peak[*, iarray-1] gt -10.)
        xra = minmax(nas_xa[wdef])
        xra = xra + [-1,1]*0.1*(xra[1]-xra[0])
        yra = minmax(nas_ya[wdef])
        yra = yra + [-1,1]*0.1*(yra[1]-yra[0])
        
        if plot_histo gt 0 then begin
           ;;
           nbin = 20
           emin = -0.8
           emax = 0.5
           binz = (emax - emin)/(nbin-1)
           ebin  = indgen(nbin)*binz + emin
           ;;
           wdef = where( med_z_peak[*, iarray-1] gt -10., nwdef)
           f = med_z_peak[wdef, iarray-1]
           np_histo, [f], xhist_res, yhist_res, gpar_res, min=emin, max=emax,  xrange=[emin, emax], fcol=80, /fit, noerase=1, position=pp[ilam,0, *], /nolegend, colorfit=250, thickfit=2
          
           ;;
           wdef = where( med_z_flux[*, iarray-1] gt -10., nwdef)
           f = med_z_flux[wdef, iarray-1]
           ;;np_histo, [f], xhist_res, yhist_res, gpar_res, min=emin,
           ;;max=emax, xrange=[emin, emax], fcol=color_list[ikp],
           ;;/fit, noerase=noerase, position=pp1[ilam,*], /nolegend,
           ;;colorfit=250, thickfit=2
           np_histo, [f], xhist_res, yhist_res, gpar_res, min=emin, max=emax,  xrange=[emin, emax], fcol=80, /fit, noerase=1, position=pp[ilam,1, *], /nolegend, colorfit=250, thickfit=2
           ;;
           wdef = where( med_z_fwhm[*, iarray-1] gt -10., nwdef)
           f = med_z_fwhm[wdef, iarray-1]
           ;;np_histo, [f], xhist_res, yhist_res, gpar_res, min=emin,
           ;;max=emax, xrange=[emin, emax], fcol=color_list[ikp],
           ;;/fit, noerase=noerase, position=pp1[ilam,*], /nolegend,
           ;;colorfit=250, thickfit=2
           np_histo, [f], xhist_res, yhist_res, gpar_res, min=emin, max=emax,  xrange=[emin, emax], fcol=80, /fit, noerase=1, position=pp[ilam,2, *], /nolegend, colorfit=250, thickfit=2
        endif else begin
           
           ;; PEAK
           wdef = where( med_z_peak[*, iarray-1] gt -1. and med_z_peak[*, iarray-1] lt 0.2, nwdef)
           f = med_z_peak[wdef, iarray-1]
           matrix_plot,nas_xa[wdef], nas_ya[wdef], med_z_peak[wdef, iarray-1] , $
                       position=pp[ilam,0,*], title='Peak focus A'+strtrim(iarray,2), /noerase, $
                       charsize=charsize, xra=xra, yra=yra, zra=zra, format='(f6.2)',/iso, symsize=ss[iarray-1]
           
           wmax = where(med_z_peak[wdef, iarray-1] eq min(med_z_peak[wdef, iarray-1]), nmax)
           print, "max defocus Peak = ",strtrim(med_z_peak[wdef[wmax], iarray-1],2), " pour ", strtrim(nas_xa[wdef[wmax]],2),', ',strtrim(nas_ya[wdef[wmax]],2)
           wdef = where(med_z_peak[*, iarray-1] gt -10., nwdef)
           med = median(med_z_peak[wdef, iarray-1])
           print, "median defocus = ", strtrim(med,2)
           print, '---'
           
           ;; FLUX
           wdef = where( med_z_flux[*, iarray-1]  gt -1. and med_z_flux[*, iarray-1] lt 0.2, nw)
           matrix_plot, nas_xa[wdef], nas_ya[wdef],med_z_flux[wdef, iarray-1], $
                        position=pp[ilam,1,*], title='Flux focus A'+strtrim(iarray,2), /noerase, $
                        charsize=charsize, xra=xra, yra=yra, zra=zra, format='(f6.2)', /iso, symsize=ss[iarray-1]
           wmax = where(med_z_flux[wdef, iarray-1] eq min(med_z_flux[wdef, iarray-1]), nmax)
           print, "max defocus Flux = ",strtrim(med_z_flux[wdef[wmax], iarray-1],2), " pour ", strtrim(nas_xa[wdef[wmax]],2),', ',strtrim(nas_ya[wdef[wmax]],2)
           wdef = where(med_z_flux[*, iarray-1] gt -10., nwdef)
           med = median(med_z_flux[wdef, iarray-1])
           print, "median defocus = ", strtrim(med,2)
           print, '---'
           
           
           ;; FWHM
           wdef = where( med_z_fwhm[*, iarray-1]  gt -1. and med_z_fwhm[*, iarray-1] lt 0.2, nw)
           matrix_plot, nas_xa[wdef], nas_ya[wdef],med_z_fwhm[wdef, iarray-1], $
                        position=pp[ilam,2,*], title='FWHM focus A'+strtrim(iarray,2), /noerase, $
                        charsize=charsize, xra=xra, yra=yra, zra=zra, format='(f6.2)', /iso, symsize=ss[iarray-1]
           wmax = where(med_z_fwhm[wdef, iarray-1] eq min(med_z_fwhm[wdef, iarray-1]), nmax)
           print, "max defocus FWHM = ",strtrim(med_z_fwhm[wdef[wmax], iarray-1],2), " pour ", strtrim(nas_xa[wdef[wmax]],2),', ',strtrim(nas_ya[wdef[wmax]],2)
           wdef = where(med_z_fwhm[*, iarray-1] gt -10., nwdef)
           med = median(med_z_fwhm[wdef, iarray-1])
           print, "median defocus = ", strtrim(med,2)
           print, '---'
           print, ' '
           print, ' '

     endelse
        
        ;;stop
     endfor
     outplot, /close


     ;; stddev of the 3 median surface estimates
     output_plot_file =  project_dir+'/fov_focus_median_stddev_'+strtrim(nseq,2)+suffixe
     wind, 1, 1, /free, xsize=850, ysize=500
     outplot, file=output_plot_file, png=png
     my_multiplot, 3, 2, pp, pp1, ymargin=0.08, gap_x=0.08, xmargin = 0.06
     
     for ilam=0, 2 do begin
        iarray = order[ilam]
        wdef = where(med_z_fwhm[*, iarray-1] gt -10. and med_z_flux[*, iarray-1] gt -10. and med_z_flux[*, iarray-1] gt -10., nwdef)
        matrix_plot, nas_xa[wdef], nas_ya[wdef],med_stddev_z[wdef, iarray-1], $
                     position=pp[ilam,1,*], title='STDDEV A'+strtrim(iarray,2), /noerase, $
                     charsize=charsize, xra=xra, yra=yra, zra=[0, 0.1], format='(f6.2)', /iso, symsize=ss[iarray-1]
        
        f = med_stddev_z[wdef, iarray-1]
        np_histo, [f], xhist_res, yhist_res, gpar_res, min=0, max=0.3,  xrange=[-0.01, 0.2], fcol=80, /fit, noerase=1, position=pp[ilam,0, *], /nolegend, colorfit=250, thickfit=2

        print, '  '
        print, 'A', strtrim(iarray,2)
        med = median(med_stddev_z[wdef, iarray-1])
        print, "median error = ", strtrim(med,2)
        print,'---'
        
     endfor
     outplot, /close

     
  endif
  
  
  ;; stddev surfaces
  ;;__________________________________

  if do_stddev gt 0 then begin
     
     output_plot_file =  project_dir+'/fov_focus_stddev_'+strtrim(nseq,2)+suffixe
     
     png=savepng
     
     zra=[0., 0.2]
     
     wind, 1, 1, /free, xsize=900, ysize=750
     outplot, file=output_plot_file, png=png
     my_multiplot, 3, 3, pp, pp1, ymargin=0.08, gap_x=0.08, xmargin = 0.06
     charsize = 0.8
     order = [1, 3, 2]
     ss = [0.4, 0.5, 0.4]
     for ilam=0, 2 do begin
        iarray = order[ilam]
        print, '***'
        print, 'Array ', strtrim(iarray,2)
        
        warray = where(arrays eq iarray, nwarray)
        nas_xa = nas_xs[warray]
        nas_ya = nas_ys[warray]
        
        sig_z_peak = dblarr(nkids)+10.
        sig_z_flux = dblarr(nkids)+10.
        sig_z_fwhm = dblarr(nkids)+10.
        
        for ik=0, nkids-1 do begin
           w=where(finite(z_peak_tab[ik,iarray-1,*]) eq 1, nw)
           if nw gt 0 then sig_z_peak[ik] = stddev(z_peak_tab[ik,iarray-1,w])
           w=where(finite(z_flux_tab[ik,iarray-1,*]) eq 1, nw)
           if nw gt 0 then sig_z_flux[ik] = stddev(z_flux_tab[ik,iarray-1,w])
           w=where(finite(z_fwhm_tab[ik,iarray-1,*]) eq 1, nw)
           if nw gt 0 then sig_z_fwhm[ik] = stddev(z_fwhm_tab[ik,iarray-1,w])
           ;;
           w=where(finite(nas_x_tab[ik,iarray-1,*]) eq 1, nw)
           if nw gt 0 then nas_xa[ik] = median(nas_x_tab[ik,iarray-1,w])
           w=where(finite(nas_y_tab[ik,iarray-1,*]) eq 1, nw)
           if nw gt 0 then nas_ya[ik] = median(nas_y_tab[ik,iarray-1,w])
        endfor
        
        wdef = where(sig_z_peak lt 10.)
        xra = minmax(nas_xa[wdef])
        xra = xra + [-1,1]*0.1*(xra[1]-xra[0])
        yra = minmax(nas_ya[wdef])
        yra = yra + [-1,1]*0.1*(yra[1]-yra[0])
        
        sig_cut = 1.
        
        ;; Sigma(z)/1-z
        if do_median gt 0 then begin
           ;;
           wmed = where(med_z_peak[*, iarray-1] lt 0.2, nwmed, complement=wnomed)
           sig_z_peak[wmed] = sig_z_peak[wmed]/(1d0-med_z_peak[wmed, iarray-1])
           sig_z_peak[wnomed] = 10.
           ;;
           wmed = where(med_z_flux[*, iarray-1] lt 0.2, nwmed, complement=wnomed)
           sig_z_flux[wmed] = sig_z_flux[wmed]/(1d0 - med_z_flux[wmed, iarray-1])
           sig_z_flux[wnomed] = 10.
           ;;
           wmed = where(med_z_fwhm[*, iarray-1] lt 0.2, nwmed, complement=wnomed)
           sig_z_fwhm[wmed] = sig_z_fwhm[wmed]/(1d0-med_z_fwhm[wmed, iarray-1])
           sig_z_fwhm[wnomed] = 10.
           zra=[0., 0.2]
           sig_cut = 2.
        endif

        
        ;; PEAK
        ;;wdef = where( med_z_peak gt -1. and med_z_peak lt 0.2,
        ;;nwdef)
        wdef = where( sig_z_peak lt sig_cut, nwdef)
        matrix_plot,nas_xa[wdef], nas_ya[wdef], sig_z_peak[wdef] , $
                    position=pp[ilam,0,*], title='Peak focus A'+strtrim(iarray,2), /noerase, $
                    charsize=charsize, xra=xra, yra=yra, zra=zra, format='(f6.2)',/iso, symsize=ss[iarray-1]
        
        wmax = where(sig_z_peak[wdef] eq max(sig_z_peak[wdef]), nmax)
        print, "max stddev Peak = ",sig_z_peak[wdef[wmax]], " pour ", nas_xa[wdef[wmax]],', ',nas_ya[wdef[wmax]]
        print, "median stddev = ", median(sig_z_peak[wdef])
        
        ;; FLUX
        ;;wdef = where( med_z_flux  gt -1. and med_z_flux lt 0.2, nw)
        wdef = where( sig_z_flux lt sig_cut, nwdef)
        matrix_plot, nas_xa[wdef], nas_ya[wdef],sig_z_flux[wdef], $
                     position=pp[ilam,1,*], title='Flux focus A'+strtrim(iarray,2), /noerase, $
                     charsize=charsize, xra=xra, yra=yra, zra=zra, format='(f6.2)', /iso, symsize=ss[iarray-1]
        wmax = where(sig_z_flux[wdef] eq max(sig_z_flux[wdef]), nmax)
        print, "max stddev Flux = ",sig_z_flux[wdef[wmax]], " pour ", nas_xa[wdef[wmax]],', ',nas_ya[wdef[wmax]]
        print, "median stddev = ", median(sig_z_flux[wdef])
        
        ;; FWHM
        ;;wdef = where( med_z_fwhm  gt -1. and med_z_fwhm lt 0.2, nw)
        wdef = where( sig_z_fwhm  lt sig_cut , nw)
        matrix_plot, nas_xa[wdef], nas_ya[wdef],sig_z_fwhm[wdef], $
                     position=pp[ilam,2,*], title='FWHM focus A'+strtrim(iarray,2), /noerase, $
                     charsize=charsize, xra=xra, yra=yra, zra=zra, format='(f6.2)', /iso, symsize=ss[iarray-1]
        wmax = where(sig_z_fwhm[wdef] eq max(sig_z_fwhm[wdef]), nmax)
        print, "max stddev FWHM = ",sig_z_fwhm[wdef[wmax]], " pour ", nas_xa[wdef[wmax]],', ',nas_ya[wdef[wmax]]
        print, "median stddev = ", median(sig_z_fwhm[wdef])
        print, ' '
        
        ;;stop
     endfor
     outplot, /close
     
  endif


  ;; mv-combined surfaces
  ;;__________________________________

  if do_mv gt 0 then  begin
     
     output_plot_file =  project_dir+'/fov_focus_mv_'+strtrim(nseq,2)+suffixe
     
     png=0

     mv_z_peak = dblarr(nkids, 3)-10.
     mv_z_flux = dblarr(nkids, 3)-10.
     mv_z_fwhm = dblarr(nkids, 3)-10.
     
     mv_err_z_peak = dblarr(nkids, 3)-10.
     mv_err_z_flux = dblarr(nkids, 3)-10.
     mv_err_z_fwhm = dblarr(nkids, 3)-10.

     mv_stddev_z = dblarr(nkids, 3)-10.
          
     zra=[-0.4, 0.4]
     
     wind, 1, 1, /free, xsize=900, ysize=750
     outplot, file=output_plot_file, png=png
     my_multiplot, 3, 3, pp, pp1, ymargin=0.08, gap_x=0.08, xmargin = 0.06
     charsize = 0.8
     order = [1, 3, 2]
     ss = [0.4, 0.5, 0.4]
     for ilam=0, 2 do begin
        iarray = order[ilam]
        print, '***'
        print, 'Array ', strtrim(iarray,2)
        
        warray = where(arrays eq iarray, nwarray)
        nas_xa = nas_xs[warray]
        nas_ya = nas_ys[warray]
        
        for ik=0, nkids-1 do begin
           w=where(finite(z_peak_tab[ik,iarray-1,*]) eq 1 and $
                   finite(err_peak_tab[ik, iarray-1, *]) eq 1 and $
                   err_peak_tab[ik, iarray-1, *] gt 1d-8, nw)
           if nw gt 0 then begin
              mv_z_peak[ik, iarray-1] = total(z_peak_tab[ik,iarray-1,w]/err_peak_tab[ik, iarray-1, w]^2)
              mv_err_z_peak[ik, iarray-1] = total(1.d0/err_peak_tab[ik, iarray-1, w]^2)
           endif
           w=where(finite(z_flux_tab[ik,iarray-1,*]) eq 1 and $
                   finite(err_flux_tab[ik, iarray-1, *]) eq 1 and $
                   err_flux_tab[ik, iarray-1, *] gt 1d-8, nw)
           if nw gt 0 then begin
              mv_z_flux[ik, iarray-1] = total(z_flux_tab[ik,iarray-1,w]/err_flux_tab[ik, iarray-1, w]^2)
              mv_err_z_flux[ik, iarray-1] = total(1.d0/err_flux_tab[ik, iarray-1, w]^2)
           endif
           w=where(finite(z_fwhm_tab[ik,iarray-1,*]) eq 1 and $
                   finite(err_fwhm_tab[ik, iarray-1, *]) eq 1 and $
                   err_fwhm_tab[ik, iarray-1, *] gt 1d-8, nw)
           if nw gt 0 then begin
              mv_z_fwhm[ik, iarray-1] = total(z_fwhm_tab[ik,iarray-1,w]/err_fwhm_tab[ik, iarray-1, w]^2)
              mv_err_z_fwhm[ik, iarray-1] = total(1.d0/err_fwhm_tab[ik, iarray-1, w]^2)
           endif
           ;;
           w=where(finite(nas_x_tab[ik,iarray-1,*]) eq 1, nw)
           if nw gt 0 then nas_xa[ik] = median(nas_x_tab[ik,iarray-1,w])
           w=where(finite(nas_y_tab[ik,iarray-1,*]) eq 1, nw)
           if nw gt 0 then nas_ya[ik] = median(nas_y_tab[ik,iarray-1,w])
        endfor

        ;; normalise
        w = where( mv_err_z_peak[*, iarray-1] gt 1d-8, nw)
        if nw gt 0 then begin
           mv_z_peak[w, iarray-1] = mv_z_peak[w, iarray-1]/mv_err_z_peak[w, iarray-1]
           mv_err_z_peak[w, iarray-1] = sqrt(1.d0/mv_err_z_peak[w, iarray-1])
        endif
        w = where( mv_err_z_flux[*, iarray-1] gt 1d-8, nw)
        if nw gt 0 then begin
           mv_z_flux[w, iarray-1] = mv_z_flux[w, iarray-1]/mv_err_z_flux[w, iarray-1]
           mv_err_z_flux[w, iarray-1] = sqrt(1.d0/mv_err_z_flux[w, iarray-1])
        endif
        w = where( mv_err_z_fwhm[*, iarray-1] gt 1d-8, nw)
        if nw gt 0 then begin
           mv_z_fwhm[w, iarray-1] = mv_z_fwhm[w, iarray-1]/mv_err_z_fwhm[w, iarray-1]
           mv_err_z_fwhm[w, iarray-1] = sqrt(1.d0/mv_err_z_fwhm[w, iarray-1])
        endif

        
        wdef = where(mv_z_fwhm[*, iarray-1] gt -10. and mv_z_flux[*, iarray-1] gt -10. and mv_z_flux[*, iarray-1] gt -10., nwdef)
        for ik =0, nwdef-1 do begin
           ii = wdef[ik]
           mv_stddev_z[ii, iarray-1] = stddev([mv_z_fwhm[ii, iarray-1], mv_z_flux[ii, iarray-1], mv_z_peak[ii, iarray-1]])
        endfor

        
        wdef = where(mv_z_peak[*, iarray-1] gt -10.)
        xra = minmax(nas_xa[wdef])
        xra = xra + [-1,1]*0.1*(xra[1]-xra[0])
        yra = minmax(nas_ya[wdef])
        yra = yra + [-1,1]*0.1*(yra[1]-yra[0])
        
        
        ;; PEAK
        wdef = where( mv_z_peak[*, iarray-1] gt -1. and mv_z_peak[*, iarray-1] lt 0.4, nwdef)
        matrix_plot,nas_xa[wdef], nas_ya[wdef], mv_z_peak[wdef, iarray-1] , $
                    position=pp[ilam,0,*], title='Peak focus A'+strtrim(iarray,2), /noerase, $
                    charsize=charsize, xra=xra, yra=yra, zra=zra, format='(f6.2)',/iso, symsize=ss[iarray-1]
        
        wmax = where(mv_z_peak[wdef, iarray-1] eq min(mv_z_peak[wdef, iarray-1]), nmax)
        print, "max defocus Peak = ",strtrim(mv_z_peak[wdef[wmax], iarray-1], 2), " pour ", strtrim(nas_xa[wdef[wmax]],2),', ',strtrim(nas_ya[wdef[wmax]],2)
        wdef = where( mv_z_peak[*, iarray-1] gt -10., nwall)
        med = median(mv_z_peak[wdef, iarray-1])
        print, "median defocus = ", strtrim(med,2)
        wdef = where( mv_z_peak[*, iarray-1] gt -10 and mv_z_peak[*, iarray-1] le -0.2, nwdef)
        print, "nk kid of z \ge -0.2 = ", nwdef/float(nwall)
        print, '----'
        
        ;; FLUX
        wdef = where( mv_z_flux[*, iarray-1]  gt -1. and mv_z_flux[*, iarray-1] lt 0.4, nw)
        matrix_plot, nas_xa[wdef], nas_ya[wdef],mv_z_flux[wdef, iarray-1], $
                     position=pp[ilam,1,*], title='Flux focus A'+strtrim(iarray,2), /noerase, $
                     charsize=charsize, xra=xra, yra=yra, zra=zra, format='(f6.2)', /iso, symsize=ss[iarray-1]
        wmax = where(mv_z_flux[wdef, iarray-1] eq min(mv_z_flux[wdef, iarray-1]), nmax)
        print, "max defocus Flux = ",strtrim(mv_z_flux[wdef[wmax], iarray-1],2), " pour ", strtrim(nas_xa[wdef[wmax]],2),', ',strtrim(nas_ya[wdef[wmax]],2)
        wdef = where( mv_z_flux[*, iarray-1] gt -10., nwall)
        med = median(mv_z_flux[wdef, iarray-1])
        print, "median defocus = ", strtrim(med,2)
        wdef = where( mv_z_flux[*, iarray-1] gt -10 and mv_z_flux[*, iarray-1] le -0.2, nwdef)
        print, "nk kid of z \ge -0.2 = ", nwdef/float(nwall)
        print, '----'
        
        ;; FWHM
        wdef = where( mv_z_fwhm[*, iarray-1]  gt -1. and mv_z_fwhm[*, iarray-1] lt 0.4, nw)
        matrix_plot, nas_xa[wdef], nas_ya[wdef],mv_z_fwhm[wdef, iarray-1], $
                     position=pp[ilam,2,*], title='FWHM focus A'+strtrim(iarray,2), /noerase, $
                     charsize=charsize, xra=xra, yra=yra, zra=zra, format='(f6.2)', /iso, symsize=ss[iarray-1]
        wmax = where(mv_z_fwhm[wdef, iarray-1] eq min(mv_z_fwhm[wdef, iarray-1]), nmax)
        print, "max defocus FWHM = ",strtrim(mv_z_fwhm[wdef[wmax], iarray-1],2), " pour ", strtrim(nas_xa[wdef[wmax]],2),', ',strtrim(nas_ya[wdef[wmax]],2)
        wdef = where( mv_z_fwhm[*, iarray-1] gt -10., nwall)
        med = median(mv_z_fwhm[wdef, iarray-1])
        print, "median defocus = ", strtrim(med,2)
        wdef = where( mv_z_fwhm[*, iarray-1] gt -10 and mv_z_fwhm[*, iarray-1] le -0.2, nwdef)
        print, "nk kid of z \ge -0.2 = ", nwdef/float(nwall)
        print, '----'
        print, ' '
        print, ' '
        
        ;;stop
     endfor
     outplot, /close
     
     output_plot_file =  project_dir+'/fov_focus_mv_stddev_'+strtrim(nseq,2)+suffixe
     wind, 1, 1, /free, xsize=850, ysize=500
     outplot, file=output_plot_file, png=png
     my_multiplot, 3, 2, pp, pp1, ymargin=0.08, gap_x=0.08, xmargin = 0.06
     
     for ilam=0, 2 do begin
        iarray = order[ilam]
        wdef = where(mv_z_fwhm[*, iarray-1] gt -10. and mv_z_flux[*, iarray-1] gt -10. and mv_z_flux[*, iarray-1] gt -10., nwdef)
        matrix_plot, nas_xa[wdef], nas_ya[wdef],mv_stddev_z[wdef, iarray-1], $
                     position=pp[ilam,1,*], title='STDDEV A'+strtrim(iarray,2), /noerase, $
                     charsize=charsize, xra=xra, yra=yra, zra=[0, 0.1], format='(f6.2)', /iso, symsize=ss[iarray-1]
        
        f = mv_stddev_z[wdef, iarray-1]
        np_histo, [f], xhist_res, yhist_res, gpar_res, min=0, max=0.3,  xrange=[-0.01, 0.2], fcol=80, /fit, noerase=1, position=pp[ilam,0, *], /nolegend, colorfit=250, thickfit=2

        print, '  '
        print, 'A', strtrim(iarray,2)
        med = median(mv_stddev_z[wdef, iarray-1])
        print, "median error = ", strtrim(med,2)
        print,'---'
        
     endfor
     outplot, /close
     
  endif
  

  ;; mv-combined surfaces
  ;;__________________________________

  if do_mv_err gt 0 then  begin

     wd, /a
     
     output_plot_file =  project_dir+'/fov_focus_mv_error_'+strtrim(nseq,2)+suffixe
     
     png=savepng

     zra=[0., 0.06]
     
     wind, 1, 1, /free, xsize=900, ysize=750
     outplot, file=output_plot_file, png=png
     my_multiplot, 3, 3, pp, pp1, ymargin=0.08, gap_x=0.08, xmargin = 0.06
     charsize = 0.8
     order = [1, 3, 2]
     ss = [0.4, 0.5, 0.4]
     for ilam=0, 2 do begin
        iarray = order[ilam]
        print, '***'
        print, 'Array ', strtrim(iarray,2)
        
        warray = where(arrays eq iarray, nwarray)
        nas_xa = nas_xs[warray]
        nas_ya = nas_ys[warray]
        
        wdef = where(mv_z_peak[*, iarray-1] gt -10.)
        xra = minmax(nas_xa[wdef])
        xra = xra + [-1,1]*0.1*(xra[1]-xra[0])
        yra = minmax(nas_ya[wdef])
        yra = yra + [-1,1]*0.1*(yra[1]-yra[0])
        
        
        ;; PEAK
        wdef = where( mv_err_z_peak[*, iarray-1] gt 1d-6 and mv_err_z_peak[*, iarray-1] lt 0.4, nwdef)
        matrix_plot,nas_xa[wdef], nas_ya[wdef], mv_err_z_peak[wdef, iarray-1] , $
                    position=pp[ilam,0,*], title='Peak focus A'+strtrim(iarray,2), /noerase, $
                    charsize=charsize, xra=xra, yra=yra, zra=zra, format='(f6.2)',/iso, symsize=ss[iarray-1]
        
        ;; FLUX
        wdef = where( mv_err_z_flux[*, iarray-1]  gt 1d-6 and mv_err_z_flux[*, iarray-1] lt 0.4, nw)
        matrix_plot, nas_xa[wdef], nas_ya[wdef],mv_err_z_flux[wdef, iarray-1], $
                     position=pp[ilam,1,*], title='Flux focus A'+strtrim(iarray,2), /noerase, $
                     charsize=charsize, xra=xra, yra=yra, zra=zra, format='(f6.2)', /iso, symsize=ss[iarray-1]
                
        ;; FWHM
        wdef = where( mv_err_z_fwhm[*, iarray-1]  gt 1d-6 and mv_err_z_fwhm[*, iarray-1] lt 0.4, nw)
        matrix_plot, nas_xa[wdef], nas_ya[wdef],mv_err_z_fwhm[wdef, iarray-1], $
                     position=pp[ilam,2,*], title='FWHM focus A'+strtrim(iarray,2), /noerase, $
                     charsize=charsize, xra=xra, yra=yra, zra=zra, format='(f6.2)', /iso, symsize=ss[iarray-1]

        w = where(mv_err_z_peak[*, iarray-1] le 1d-6 and mv_err_z_peak[*, iarray-1] gt -10., nw)
        print,nw
        w = where(mv_err_z_flux[*, iarray-1] le 1d-6 and mv_err_z_flux[*, iarray-1] gt -10., nw)
        print,nw
        w = where(mv_err_z_fwhm[*, iarray-1] le 1d-6 and mv_err_z_fwhm[*, iarray-1] gt -10., nw)
        print,nw
        ;;stop
     endfor
     outplot, /close

     avg_mv_err_z = dblarr(nkids, 3)-10.

     output_plot_file =  project_dir+'/fov_focus_averaged_mv_error_'+strtrim(nseq,2)+suffixe
     wind, 1, 1, /free, xsize=850, ysize=500
     outplot, file=output_plot_file, png=png
     my_multiplot, 3, 2, pp, pp1, ymargin=0.08, gap_x=0.08, xmargin = 0.06
     
     for ilam=0, 2 do begin
        iarray = order[ilam]
        wdef = where(mv_err_z_fwhm[*, iarray-1] gt -10. and mv_err_z_flux[*, iarray-1] gt -10. and mv_err_z_flux[*, iarray-1] gt -10., nwdef)
        for ik =0, nwdef-1 do begin
           ii = wdef[ik]
           avg_mv_err_z[ii, iarray-1] = sqrt(mv_err_z_fwhm[ii, iarray-1]^2+mv_err_z_flux[ii, iarray-1]^2+mv_err_z_peak[ii, iarray-1]^2)/3.
        endfor
        matrix_plot, nas_xa[wdef], nas_ya[wdef],avg_mv_err_z[wdef, iarray-1], $
                     position=pp[ilam,1,*], title='AVG MV ERROR A'+strtrim(iarray,2), /noerase, $
                     charsize=charsize, xra=xra, yra=yra, zra=[0, 0.05], format='(f6.2)', /iso, symsize=ss[iarray-1]
        f = avg_mv_err_z[wdef, iarray-1]
        np_histo, [f], xhist_res, yhist_res, gpar_res, min=0, max=0.08, binsize=0.005, xrange=[-0.001, 0.08], fcol=80, /fit, noerase=1, position=pp[ilam,0, *], /nolegend, colorfit=250, thickfit=2
        
        print, '  '
        print, 'A', strtrim(iarray,2)
        med = median(avg_mv_err_z[wdef, iarray-1])
        print, "median error = ", strtrim(med,2)
        print,'---'
     endfor
     outplot, /close



     
  endif


  ;; 1D plots
  ;;__________________________________
  
  if do_1d_plot gt 0 then  begin

     all_kids = 0
     two_diam = 1
     
     if all_kids then begin
        
        output_plot_file =  project_dir+'/fov_focus_1D_'+strtrim(nseq,2)+suffixe
        
        png=savepng
        
        color_tab = [50, 80, 150, 200, 250]
        if nseq gt 5 then color_tab = indgen(nseq)*255/nseq + 150./nseq
        
        wind, 1, 1, /free, xsize=900, ysize=750
        outplot, file=output_plot_file, png=png
        my_multiplot, 3, 3, pp, pp1, ymargin=0.08, gap_x=0.08, xmargin = 0.06
        charsize = 0.8
        order = [1, 3, 2]
        pick_d1_min = [0., 0., -10.]
        pick_d1_max = [10, 10., 10.]
        pick_d2_min = [5., 5., -10.]
        pick_d2_max = [15., 15., 10.]
        
        for ilam=0, 2 do begin
           iarray = order[ilam]
           print, '***'
           print, 'Array ', strtrim(iarray,2)
           
           warray = where(arrays eq iarray, nwarray)
           nas_xa = nas_xs[warray]
           nas_ya = nas_ys[warray]
           
           for ik=0, nkids-1 do begin
              w=where(finite(nas_x_tab[ik,iarray-1,*]) eq 1, nw)
              if nw gt 0 then nas_xa[ik] = median(nas_x_tab[ik,iarray-1,w])
              w=where(finite(nas_y_tab[ik,iarray-1,*]) eq 1, nw)
              if nw gt 0 then nas_ya[ik] = median(nas_y_tab[ik,iarray-1,w])
           endfor
           
           ;; all the kids 
           nn = nkids
           if iarray eq 2 then nn=600
           ind = indgen(nn)
           plot, ind, ind, col=0,  position=pp[ilam,0,*], /nodata, /noerase, yr=[-0.4, 0.4], /ys
           for iseq = 0, nseq-1 do begin
              z_peak = z_peak_tab[*,iarray-1,iseq]
              w=where(finite(z_peak))
              oplot, ind[w], z_peak[w], psym=8, col=color_tab[iseq], symsize=0.5
           endfor
           plot, ind, ind, col=0,  position=pp[ilam,1,*], /nodata, /noerase, yr=[-0.4, 0.4], /ys
           for iseq = 0, nseq-1 do begin
              z_flux = z_flux_tab[*,iarray-1,iseq]
              w=where(finite(z_flux))
              oplot, ind[w], z_flux[w], psym=8, col=color_tab[iseq], symsize=0.5
           endfor
           plot, ind, ind, col=0,  position=pp[ilam,2,*], /nodata, /noerase, yr=[-0.4, 0.4], /ys
           for iseq = 0, nseq-1 do begin
              z_fwhm = z_fwhm_tab[*,iarray-1,iseq]
              w=where(finite(z_fwhm))
              oplot, ind[w], z_fwhm[w], psym=8, col=color_tab[iseq], symsize=0.5
           endfor
           
        endfor
        outplot, /close
        stop

     endif

     if two_diam gt 0 then begin


        yra = [-0.7, 0.4]
        
        ;; STABILITY along A VERTICAL DIAMETER
        ;;----------------------------------------------------------------------------
        output_plot_file =  project_dir+'/fov_focus_1D_Vdiam_'+strtrim(nseq,2)+suffixe
        
        png=savepng
        
        color_tab = [50, 80, 150, 200, 250]
        if nseq gt 5 then color_tab = indgen(nseq)*255/nseq + 150./nseq
        legtext = strarr(nseq)
        for i=0, nseq-1 do legtext[i]= strtrim(list_sequence[0, wseq[i]], 2)
        
        wind, 1, 1, /free, xsize=900, ysize=750
        outplot, file=output_plot_file, png=png
        my_multiplot, 3, 3, pp, pp1, ymargin=0.08, gap_x=0.08, xmargin = 0.06
        charsize = 0.8
        order = [1, 3, 2]
        pick_d1_min = [0., 0., -10.]
        pick_d1_max = [10, 10., 10.]
        pick_d2_min = [5., 5., -10.]
        pick_d2_max = [15., 15., 10.]
        
        for ilam=0, 2 do begin
           iarray = order[ilam]
           print, '***'
           print, 'Array ', strtrim(iarray,2)
           
           warray = where(arrays eq iarray, nwarray)
           nas_xa = nas_xs[warray]
           nas_ya = nas_ys[warray]
           
           for ik=0, nkids-1 do begin
              w=where(finite(nas_x_tab[ik,iarray-1,*]) eq 1, nw)
              if nw gt 0 then nas_xa[ik] = median(nas_x_tab[ik,iarray-1,w])
              w=where(finite(nas_y_tab[ik,iarray-1,*]) eq 1, nw)
              if nw gt 0 then nas_ya[ik] = median(nas_y_tab[ik,iarray-1,w])
           endfor
           
           ;; 2 perpendicular diameters
           alp = 12.*!dtor
           calp = cos(alp)
           salp = sin(alp)
           rnas_xa = calp*nas_xa+salp*nas_ya
           rnas_ya = calp*nas_ya-salp*nas_xa
           
           wd1 = where(rnas_xa lt pick_d1_max[ilam] and rnas_xa gt pick_d1_min[ilam], nwd1)
           wd2 = where(rnas_ya lt pick_d2_max[ilam] and rnas_ya gt pick_d2_min[ilam], nwd2)
           
           ;; output_plot_file =  project_dir+'/fov_focus_stability_check_d1'
           ;; outplot, file=output_plot_file, png=1
           ;; diam = fltarr(n_elements(nas_xa))+1
           ;; diam(wd1) = 2
           ;; matrix_plot,nas_xa, nas_ya, diam, /iso, /nobar, xtitle="Offset X (arcsec)", ytitle="Offset Y (arcsec)"
           ;; outplot, /close
           ;; output_plot_file =  project_dir+'/fov_focus_stability_check_d2'
           ;; outplot, file=output_plot_file, png=1
           ;; diam = fltarr(n_elements(nas_xa))+1
           ;; diam(wd2) = 2
           ;; matrix_plot,nas_xa, nas_ya, diam, /iso, /nobar, xtitle="Offset X (arcsec)", ytitle="Offset Y (arcsec)"
           ;; outplot, /close
           ;; stop
           
           plot, nas_ya[wd1], nas_ya[wd1], col=0,  position=pp[ilam,0,*], /nodata, /noerase, $
                 yr=yra, /ys, xr=[-200, 200], /xs, xtitle='Offset Y (arcsec)', ytitle="defocus Z (mm)", title="APeak-based results for A"+strtrim(iarray,2), charsize=0.7 
           for iseq = 0, nseq-1 do begin
              z_peak = z_peak_tab[*,iarray-1,iseq]
              nas_x  = nas_x_tab[ *,iarray-1,iseq]
              nas_y  = nas_y_tab[ *,iarray-1,iseq]
              rnas_x = calp*nas_x+salp*nas_y
              rnas_y = calp*nas_y-salp*nas_x
              wd1_ = where(rnas_x lt pick_d1_max[ilam] and rnas_x gt pick_d1_min[ilam], nwd1)
              wd2_ = where(rnas_y lt pick_d2_max[ilam] and rnas_y gt pick_d2_min[ilam], nwd2)
              
              oplot, nas_y[wd1_], z_peak[wd1_], col=color_tab[iseq] , psym=8, symsize=0.5, linestyle=1
                                ;oplot, nas_xa[wd2], z_peak[wd2], psym=1, col=color_tab[iseq], symsize=0.5
           endfor
           

           ;;
           plot,nas_ya[wd1], nas_ya[wd1], col=0,  position=pp[ilam,1,*], /nodata, /noerase, $
                yr=yra, /ys, xr=[-200, 200], /xs, xtitle='Offset Y (arcsec)', ytitle="defocus Z (mm)", title="Flux-based results for A"+strtrim(iarray,2)  , charsize=0.7 
           for iseq = 0, nseq-1 do begin
              z_flux = z_flux_tab[*,iarray-1,iseq]
              nas_x  = nas_x_tab[ *,iarray-1,iseq]
              nas_y  = nas_y_tab[ *,iarray-1,iseq]
              rnas_x = calp*nas_x+salp*nas_y
              rnas_y = calp*nas_y-salp*nas_x
              wd1_ = where(rnas_x lt pick_d1_max[ilam] and rnas_x gt pick_d1_min[ilam], nwd1)
              wd2_ = where(rnas_y lt pick_d2_max[ilam] and rnas_y gt pick_d2_min[ilam], nwd2)
              oplot, nas_y[wd1_], z_flux[wd1_], col=color_tab[iseq], psym=8, symsize=0.5, linestyle=1
                                ;oplot, nas_xa[wd2], z_flux[wd2], psym=1, col=color_tab[iseq], symsize=0.5
           endfor
           
           ;;
           plot, nas_ya[wd1], nas_ya[wd1], col=0,  position=pp[ilam,2,*], /nodata, /noerase, $
                 yr=yra, /ys, xr=[-200, 200], /xs, xtitle='Offset Y (arcsec)', ytitle="defocus Z (mm)", title="FWHM-based results for A"+strtrim(iarray,2) , charsize=0.7 
           for iseq = 0, nseq-1 do begin
              z_fwhm = z_fwhm_tab[*,iarray-1,iseq]
              nas_x  = nas_x_tab[ *,iarray-1,iseq]
              nas_y  = nas_y_tab[ *,iarray-1,iseq]
              rnas_x = calp*nas_x+salp*nas_y
              rnas_y = calp*nas_y-salp*nas_x
              wd1_ = where(rnas_x lt pick_d1_max[ilam] and rnas_x gt pick_d1_min[ilam], nwd1)
              wd2_ = where(rnas_y lt pick_d2_max[ilam] and rnas_y gt pick_d2_min[ilam], nwd2)
              oplot, nas_y[wd1_], z_fwhm[wd1_], col=color_tab[iseq], psym=8, symsize=0.5, linestyle=1
                                ;oplot, nas_xa[wd2], z_fwhm[wd2], psym=1, col=color_tab[iseq], symsize=0.5
           endfor
           
           if iarray eq 1 then begin
              legendastro, legtext[0:2], textcolor=color_tab[0:2], box = 0, chars = 0.6, pos=[-160., -0.4]
              legendastro, legtext[3:*], textcolor=color_tab[3:*], box = 0, chars = 0.6, pos=[10., -0.4]
           endif
        endfor
        outplot, /close
                               

         ;; STABILITY ALONG A HORIZONTAL DIAMETER
        ;;----------------------------------------------------------------------------
        output_plot_file =  project_dir+'/fov_focus_1D_Hdiam_'+strtrim(nseq,2)+suffixe
        
        png=savepng
        
        color_tab = [50, 80, 150, 200, 250]
        if nseq gt 5 then color_tab = indgen(nseq)*255/nseq + 150./nseq
        
        legtext = strarr(nseq)
        for i=0, nseq-1 do legtext[i]= strtrim(list_sequence[0, wseq[i]], 2)
        
        wind, 1, 1, /free, xsize=900, ysize=750
        outplot, file=output_plot_file, png=png
        my_multiplot, 3, 3, pp, pp1, ymargin=0.08, gap_x=0.08, xmargin = 0.06
        charsize = 0.8
        order = [1, 3, 2]
        pick_d1_min = [0., 0., -10.]
        pick_d1_max = [10, 10., 10.]
        pick_d2_min = [5., 5., -10.]
        pick_d2_max = [15., 15., 10.]
        
        for ilam=0, 2 do begin
           iarray = order[ilam]
           print, '***'
           print, 'Array ', strtrim(iarray,2)
           
           warray = where(arrays eq iarray, nwarray)
           nas_xa = nas_xs[warray]
           nas_ya = nas_ys[warray]
           
           for ik=0, nkids-1 do begin
              w=where(finite(nas_x_tab[ik,iarray-1,*]) eq 1, nw)
              if nw gt 0 then nas_xa[ik] = median(nas_x_tab[ik,iarray-1,w])
              w=where(finite(nas_y_tab[ik,iarray-1,*]) eq 1, nw)
              if nw gt 0 then nas_ya[ik] = median(nas_y_tab[ik,iarray-1,w])
           endfor
           
           ;; 2 perpendicular diameters
           alp = 12.*!dtor
           calp = cos(alp)
           salp = sin(alp)
           rnas_xa = calp*nas_xa+salp*nas_ya
           rnas_ya = calp*nas_ya-salp*nas_xa
           
           wd1 = where(rnas_xa lt pick_d1_max[ilam] and rnas_xa gt pick_d1_min[ilam], nwd1)
           wd2 = where(rnas_ya lt pick_d2_max[ilam] and rnas_ya gt pick_d2_min[ilam], nwd2)
           
          
           plot, nas_ya[wd1], nas_ya[wd1], col=0,  position=pp[ilam,0,*], /nodata, /noerase, $
                 yr=yra, /ys, xr=[-200, 200], /xs, xtitle='Offset X (arcsec)', ytitle="defocus Z (mm)", title="APeak-based results for A"+strtrim(iarray,2), charsize=0.7 
           for iseq = 0, nseq-1 do begin
              z_peak = z_peak_tab[*,iarray-1,iseq]
              nas_x  = nas_x_tab[ *,iarray-1,iseq]
              nas_y  = nas_y_tab[ *,iarray-1,iseq]
              rnas_x = calp*nas_x+salp*nas_y
              rnas_y = calp*nas_y-salp*nas_x
              wd1_ = where(rnas_x lt pick_d1_max[ilam] and rnas_x gt pick_d1_min[ilam], nwd1)
              wd2_ = where(rnas_y lt pick_d2_max[ilam] and rnas_y gt pick_d2_min[ilam], nwd2)
              
              ;oplot, nas_y[wd1_], z_peak[wd1_], col=color_tab[iseq] , psym=8, symsize=0.5, linestyle=1
              oplot, nas_x[wd2_], z_peak[wd2_], psym=8, col=color_tab[iseq], symsize=0.5
           endfor
           plot,nas_ya[wd1], nas_ya[wd1], col=0,  position=pp[ilam,1,*], /nodata, /noerase, $
                yr=yra, /ys, xr=[-200, 200], /xs, xtitle='Offset X (arcsec)', ytitle="defocus Z (mm)", title="Flux-based results for A"+strtrim(iarray,2)  , charsize=0.7
           for iseq = 0, nseq-1 do begin
              z_flux = z_flux_tab[*,iarray-1,iseq]
              nas_x  = nas_x_tab[ *,iarray-1,iseq]
              nas_y  = nas_y_tab[ *,iarray-1,iseq]
              rnas_x = calp*nas_x+salp*nas_y
              rnas_y = calp*nas_y-salp*nas_x
              wd1_ = where(rnas_x lt pick_d1_max[ilam] and rnas_x gt pick_d1_min[ilam], nwd1)
              wd2_ = where(rnas_y lt pick_d2_max[ilam] and rnas_y gt pick_d2_min[ilam], nwd2)
              ;oplot, nas_y[wd1_], z_flux[wd1_], col=color_tab[iseq], psym=8, symsize=0.5, linestyle=1
              oplot, nas_x[wd2_], z_flux[wd2_], psym=8, col=color_tab[iseq], symsize=0.5
           endfor
           plot, nas_ya[wd1], nas_ya[wd1], col=0,  position=pp[ilam,2,*], /nodata, /noerase, $
                 yr=yra, /ys, xr=[-200, 200], /xs, xtitle='Offset X (arcsec)', ytitle="defocus Z (mm)", title="FWHM-based results for A"+strtrim(iarray,2) , charsize=0.7 
           for iseq = 0, nseq-1 do begin
              z_fwhm = z_fwhm_tab[*,iarray-1,iseq]
              nas_x  = nas_x_tab[ *,iarray-1,iseq]
              nas_y  = nas_y_tab[ *,iarray-1,iseq]
              rnas_x = calp*nas_x+salp*nas_y
              rnas_y = calp*nas_y-salp*nas_x
              wd1_ = where(rnas_x lt pick_d1_max[ilam] and rnas_x gt pick_d1_min[ilam], nwd1)
              wd2_ = where(rnas_y lt pick_d2_max[ilam] and rnas_y gt pick_d2_min[ilam], nwd2)
              ;oplot, nas_y[wd1_], z_fwhm[wd1_], col=color_tab[iseq], psym=8, symsize=0.5, linestyle=1
              oplot, nas_x[wd2_], z_fwhm[wd2_], psym=8, col=color_tab[iseq], symsize=0.5
           endfor

           if iarray eq 1 then begin
              legendastro, legtext[0:2], textcolor=color_tab[0:2], box = 0, chars = 0.6
              legendastro, legtext[3:*], textcolor=color_tab[3:*], box = 0, chars = 0.6, /right
           endif
        endfor
        
        outplot, /close


        ;; STABILITY ALONG A VERTICAL BAND
        ;;----------------------------------------------------------------------------
        output_plot_file =  project_dir+'/fov_focus_1D_Vband_'+strtrim(nseq,2)+suffixe
        
        png=savepng
        
        color_tab = [50, 80, 150, 200, 250]
        if nseq gt 5 then color_tab = indgen(nseq)*255/nseq + 150./nseq

        legtext = strarr(nseq)
        for i=0, nseq-1 do legtext[i]= strtrim(list_sequence[0, wseq[i]], 2)
        
        wind, 1, 1, /free, xsize=900, ysize=750
        outplot, file=output_plot_file, png=png
        my_multiplot, 3, 3, pp, pp1, ymargin=0.08, gap_x=0.08, xmargin = 0.06
        charsize = 0.8
        order = [1, 3, 2]
        pick_d1_min = [-20, -20, -25.]
        pick_d1_max = [20, 20., 35.]
        pick_d2_min = [-20., -20., -25.]
        pick_d2_max = [25., 25., 35.]
        step = [10., 10., 15.]
        
        for ilam=0, 2 do begin
           iarray = order[ilam]
           print, '***'
           print, 'Array ', strtrim(iarray,2)
           
           warray = where(arrays eq iarray, nwarray)
           nas_xa = nas_xs[warray]
           nas_ya = nas_ys[warray]
           
           for ik=0, nkids-1 do begin
              w=where(finite(nas_x_tab[ik,iarray-1,*]) eq 1, nw)
              if nw gt 0 then nas_xa[ik] = median(nas_x_tab[ik,iarray-1,w])
              w=where(finite(nas_y_tab[ik,iarray-1,*]) eq 1, nw)
              if nw gt 0 then nas_ya[ik] = median(nas_y_tab[ik,iarray-1,w])
           endfor
           
           ;; 2 perpendicular diameters
           alp = 12.*!dtor
           calp = cos(alp)
           salp = sin(alp)
           rnas_xa = calp*nas_xa+salp*nas_ya
           rnas_ya = calp*nas_ya-salp*nas_xa
           
           wd1 = where(rnas_xa lt pick_d1_max[ilam] and rnas_xa gt pick_d1_min[ilam], nwd1)
           wd2 = where(rnas_ya lt pick_d2_max[ilam] and rnas_ya gt pick_d2_min[ilam], nwd2)

           ;; output_plot_file =  project_dir+'/fov_focus_stability_check_D1'
           ;; outplot, file=output_plot_file, png=1
           ;; diam = fltarr(n_elements(nas_xa))+1
           ;; diam(wd1) = 2
           ;; matrix_plot,nas_xa, nas_ya, diam, /iso, /nobar, xtitle="Offset X (arcsec)", ytitle="Offset Y (arcsec)"
           ;; outplot, /close
           ;; output_plot_file =  project_dir+'/fov_focus_stability_check_D2'
           ;; outplot, file=output_plot_file, png=1
           ;; diam = fltarr(n_elements(nas_xa))+1
           ;; diam(wd2) = 2
           ;; matrix_plot,nas_xa, nas_ya, diam, /iso, /nobar, xtitle="Offset X (arcsec)", ytitle="Offset Y (arcsec)"
           ;; outplot, /close
           ;; stop
           
           plot, nas_ya[wd1], nas_ya[wd1], col=0,  position=pp[ilam,0,*], /nodata, /noerase, $
                 yr=yra, /ys, xr=[-200, 200], /xs, xtitle='Offset Y (arcsec)', ytitle="defocus Z (mm)", title="APeak-based results for A"+strtrim(iarray,2), charsize=0.7  
           for iseq = 0, nseq-1 do begin
              z_peak = z_peak_tab[*,iarray-1,iseq]
              nas_x  = nas_x_tab[ *,iarray-1,iseq]
              nas_y  = nas_y_tab[ *,iarray-1,iseq]
              rnas_x = calp*nas_x+salp*nas_y
              rnas_y = calp*nas_y-salp*nas_x
              wd1_ = where(rnas_x lt pick_d1_max[ilam] and rnas_x gt pick_d1_min[ilam], nwd1)
              wd2_ = where(rnas_y lt pick_d2_max[ilam] and rnas_y gt pick_d2_min[ilam], nwd2)
              diam_1 = dblarr(30)
              ytab   = lindgen(32.)*500./31. - 250.
              yy     = dblarr(30)
              for ip = 1, 30 do begin
                 w=where(nas_y[wd1_] lt ytab[ip+1] and nas_y[wd1_] ge ytab[ip], nw)
                 if nw gt 0 then diam_1[ip-1] = median(z_peak[wd1_[w]])
                 if nw gt 0 then yy[    ip-1] = median(nas_y[wd1_[w]])
              endfor            
              oplot, yy, diam_1, col=color_tab[iseq] , psym=8, symsize=0.5, linestyle=1
           endfor
           z_peak = mv_z_peak[*,iarray-1]
           s_peak = mv_err_z_peak[*, iarray-1]
           diam_1 = dblarr(30)
           ytab   = lindgen(32.)*500./31. - 250.
           yy     = dblarr(30)
           err    = dblarr(30)
           for ip = 1, 30 do begin
              w=where(nas_ya[wd1] lt ytab[ip+1] and nas_ya[wd1] ge ytab[ip], nw)
              if nw gt 0 then diam_1[ip-1] = median(z_peak[wd1[w]])
              if nw gt 0 then yy[    ip-1] = median(nas_ya[wd1[w]])
              if nw gt 0 then err[   ip-1] = median(s_peak[wd1[w]]) ;/sqrt(nw)
           endfor            
           oploterror, yy, diam_1, yy*0., err, col=0, errcol=0, psym=4, symsize=0.5
           ;;
           plot,nas_ya[wd1], nas_ya[wd1], col=0,  position=pp[ilam,1,*], /nodata, /noerase, $
                yr=yra, /ys, xr=[-200, 200], /xs, xtitle='Offset Y (arcsec)', ytitle="defocus Z (mm)", title="Flux-based results for A"+strtrim(iarray,2)  , charsize=0.7  
           for iseq = 0, nseq-1 do begin
              z_flux = z_flux_tab[*,iarray-1,iseq]
              nas_x  = nas_x_tab[ *,iarray-1,iseq]
              nas_y  = nas_y_tab[ *,iarray-1,iseq]
              rnas_x = calp*nas_x+salp*nas_y
              rnas_y = calp*nas_y-salp*nas_x
              wd1_ = where(rnas_x lt pick_d1_max[ilam] and rnas_x gt pick_d1_min[ilam], nwd1)
              wd2_ = where(rnas_y lt pick_d2_max[ilam] and rnas_y gt pick_d2_min[ilam], nwd2)
              diam_1 = dblarr(30)
              ytab   = lindgen(32.)*500./31. - 250.
              yy     = dblarr(30)
              for ip = 1, 30 do begin
                 w=where(nas_y[wd1_] lt ytab[ip+1] and nas_y[wd1_] ge ytab[ip], nw)
                 if nw gt 0 then diam_1[ip-1] = median(z_flux[wd1_[w]])
                 if nw gt 0 then yy[    ip-1] = median(nas_y[wd1_[w]])
              endfor            
              oplot, yy, diam_1, col=color_tab[iseq] , psym=8, symsize=0.5, linestyle=1
           endfor
           z_flux = mv_z_flux[*,iarray-1]
           s_flux = mv_err_z_flux[*, iarray-1]
           diam_1 = dblarr(30)
           ytab   = lindgen(32.)*500./31. - 250.
           yy     = dblarr(30)
           err    = dblarr(30)
           for ip = 1, 30 do begin
              w=where(nas_ya[wd1] lt ytab[ip+1] and nas_ya[wd1] ge ytab[ip], nw)
              if nw gt 0 then diam_1[ip-1] = median(z_flux[wd1[w]])
              if nw gt 0 then yy[    ip-1] = median(nas_ya[wd1[w]])
              if nw gt 0 then err[   ip-1] = median(s_flux[wd1[w]]);/sqrt(nw)
           endfor            
           oploterror, yy, diam_1, yy*0., err, col=0, errcol=0, psym=4, symsize=0.5
           
           ;;
           plot, nas_ya[wd1], nas_ya[wd1], col=0,  position=pp[ilam,2,*], /nodata, /noerase, $
                 yr=yra, /ys, xr=[-200, 200], /xs, xtitle='Offset Y (arcsec)', ytitle="defocus Z (mm)", title="FWHM-based results for A"+strtrim(iarray,2) , charsize=0.7  
           for iseq = 0, nseq-1 do begin
              z_fwhm = z_fwhm_tab[*,iarray-1,iseq]
              nas_x  = nas_x_tab[ *,iarray-1,iseq]
              nas_y  = nas_y_tab[ *,iarray-1,iseq]
              rnas_x = calp*nas_x+salp*nas_y
              rnas_y = calp*nas_y-salp*nas_x
              wd1_ = where(rnas_x lt pick_d1_max[ilam] and rnas_x gt pick_d1_min[ilam], nwd1)
              wd2_ = where(rnas_y lt pick_d2_max[ilam] and rnas_y gt pick_d2_min[ilam], nwd2)
              diam_1 = dblarr(30)
              ytab   = lindgen(32.)*500./31. - 250.
              yy     = dblarr(30)
              for ip = 1, 30 do begin
                 w=where(nas_y[wd1_] lt ytab[ip+1] and nas_y[wd1_] ge ytab[ip], nw)
                 if nw gt 0 then diam_1[ip-1] = median(z_fwhm[wd1_[w]])
                 if nw gt 0 then yy[    ip-1] = median(nas_y[wd1_[w]])
              endfor            
              oplot, yy, diam_1, col=color_tab[iseq] , psym=8, symsize=0.5, linestyle=1
           endfor
           z_fwhm = mv_z_fwhm[*,iarray-1]
           s_fwhm = mv_err_z_fwhm[*, iarray-1]
           diam_1 = dblarr(30)
           ytab   = lindgen(32.)*500./31. - 250.
           yy     = dblarr(30)
           err    = dblarr(30)
           for ip = 1, 30 do begin
              w=where(nas_ya[wd1] lt ytab[ip+1] and nas_ya[wd1] ge ytab[ip], nw)
              if nw gt 0 then diam_1[ip-1] = median(z_fwhm[wd1[w]])
              if nw gt 0 then yy[    ip-1] = median(nas_ya[wd1[w]])
              if nw gt 0 then err[   ip-1] = median(s_fwhm[wd1[w]]);/sqrt(nw)
           endfor            
           oploterror, yy, diam_1, yy*0., err, col=0, errcol=0, psym=4, symsize=0.5
           if iarray eq 1 then begin
              legendastro, legtext[0:2], textcolor=color_tab[0:2], box = 0, chars = 0.6, pos=[-160., -0.4]
              legendastro, [legtext[3:*],'combined'], textcolor=[color_tab[3:*], 0], box = 0, chars = 0.6, pos=[10., -0.4]
           endif
        endfor
        outplot, /close
                                ;stop

        ;; STABILITY ALONG A HORIZONTAL BAND
        ;;----------------------------------------------------------------------------
        output_plot_file =  project_dir+'/fov_focus_1D_Hband_'+strtrim(nseq,2)+suffixe
        
        png=savepng
        
        color_tab = [50, 80, 150, 200, 250]
        if nseq gt 5 then color_tab = indgen(nseq)*255/nseq + 150./nseq

        legtext = strarr(nseq)
        for i=0, nseq-1 do legtext[i]= strtrim(list_sequence[0, wseq[i]], 2)
        
        wind, 1, 1, /free, xsize=900, ysize=750
        outplot, file=output_plot_file, png=png
        my_multiplot, 3, 3, pp, pp1, ymargin=0.08, gap_x=0.08, xmargin = 0.06
        charsize = 0.8
        order = [1, 3, 2]
        pick_d1_min = [-20, -20, -25.]
        pick_d1_max = [20, 20., 35.]
        pick_d2_min = [-20., -20., -25.]
        pick_d2_max = [25., 25., 35.]
        step = [10., 10., 15.]
        
        for ilam=0, 2 do begin
           iarray = order[ilam]
           print, '***'
           print, 'Array ', strtrim(iarray,2)
           
           warray = where(arrays eq iarray, nwarray)
           nas_xa = nas_xs[warray]
           nas_ya = nas_ys[warray]
           
           for ik=0, nkids-1 do begin
              w=where(finite(nas_x_tab[ik,iarray-1,*]) eq 1, nw)
              if nw gt 0 then nas_xa[ik] = median(nas_x_tab[ik,iarray-1,w])
              w=where(finite(nas_y_tab[ik,iarray-1,*]) eq 1, nw)
              if nw gt 0 then nas_ya[ik] = median(nas_y_tab[ik,iarray-1,w])
           endfor
           
           ;; 2 perpendicular diameters
           alp = 12.*!dtor
           calp = cos(alp)
           salp = sin(alp)
           rnas_xa = calp*nas_xa+salp*nas_ya
           rnas_ya = calp*nas_ya-salp*nas_xa
           
           wd1 = where(rnas_xa lt pick_d1_max[ilam] and rnas_xa gt pick_d1_min[ilam], nwd1)
           wd2 = where(rnas_ya lt pick_d2_max[ilam] and rnas_ya gt pick_d2_min[ilam], nwd2)

           plot, nas_ya[wd1], nas_ya[wd1], col=0,  position=pp[ilam,0,*], /nodata, /noerase, $
                 yr=yra, /ys, xr=[-200, 200], /xs, xtitle='Offset X (arcsec)', ytitle="defocus Z (mm)", title="APeak-based results for A"+strtrim(iarray,2), charsize=0.7  
           for iseq = 0, nseq-1 do begin
              z_peak = z_peak_tab[*,iarray-1,iseq]
              nas_x  = nas_x_tab[ *,iarray-1,iseq]
              nas_y  = nas_y_tab[ *,iarray-1,iseq]
              rnas_x = calp*nas_x+salp*nas_y
              rnas_y = calp*nas_y-salp*nas_x
              wd1_ = where(rnas_x lt pick_d1_max[ilam] and rnas_x gt pick_d1_min[ilam], nwd1)
              wd2_ = where(rnas_y lt pick_d2_max[ilam] and rnas_y gt pick_d2_min[ilam], nwd2)
              diam_1 = dblarr(30)
              ytab   = lindgen(32.)*500./31. - 250.
              yy     = dblarr(30)
              for ip = 1, 30 do begin
                 w=where(nas_x[wd2_] lt ytab[ip+1] and nas_x[wd2_] ge ytab[ip], nw)
                 if nw gt 0 then diam_1[ip-1] = median(z_peak[wd2_[w]])
                 if nw gt 0 then yy[    ip-1] = median(nas_x[wd2_[w]])
              endfor            
              oplot, yy, diam_1, col=color_tab[iseq] , psym=8, symsize=0.5, linestyle=1
           endfor
           z_peak = mv_z_peak[*,iarray-1]
           s_peak = mv_err_z_peak[*, iarray-1]
           diam_1 = dblarr(30)
           ytab   = lindgen(32.)*500./31. - 250.
           yy     = dblarr(30)
           err    = dblarr(30)
           for ip = 1, 30 do begin
              w=where(nas_xa[wd2] lt ytab[ip+1] and nas_xa[wd2] ge ytab[ip], nw)
              if nw gt 0 then diam_1[ip-1] = median(z_peak[wd2[w]])
              if nw gt 0 then yy[    ip-1] = median(nas_xa[wd2[w]])
              if nw gt 0 then err[   ip-1] = median(s_peak[wd2[w]]);/sqrt(nw)
           endfor            
           oploterror, yy, diam_1, yy*0., err, col=0, errcol=0, psym=4, symsize=0.5

           
           plot,nas_ya[wd1], nas_ya[wd1], col=0,  position=pp[ilam,1,*], /nodata, /noerase, $
                yr=yra, /ys, xr=[-200, 200], /xs, xtitle='Offset X (arcsec)', ytitle="defocus Z (mm)", title="Flux-based results for A"+strtrim(iarray,2)  , charsize=0.7  
           for iseq = 0, nseq-1 do begin
              z_flux = z_flux_tab[*,iarray-1,iseq]
              nas_x  = nas_x_tab[ *,iarray-1,iseq]
              nas_y  = nas_y_tab[ *,iarray-1,iseq]
              rnas_x = calp*nas_x+salp*nas_y
              rnas_y = calp*nas_y-salp*nas_x
              wd1_ = where(rnas_x lt pick_d1_max[ilam] and rnas_x gt pick_d1_min[ilam], nwd1)
              wd2_ = where(rnas_y lt pick_d2_max[ilam] and rnas_y gt pick_d2_min[ilam], nwd2)
              diam_1 = dblarr(30)
              ytab   = lindgen(32.)*500./31. - 250.
              yy     = dblarr(30)
              for ip = 1, 30 do begin
                 w=where(nas_x[wd2_] lt ytab[ip+1] and nas_x[wd2_] ge ytab[ip], nw)
                 if nw gt 0 then diam_1[ip-1] = median(z_flux[wd2_[w]])
                 if nw gt 0 then yy[    ip-1] = median(nas_x[wd2_[w]])
              endfor            
              oplot, yy, diam_1, col=color_tab[iseq] , psym=8, symsize=0.5, linestyle=1
           endfor
           z_flux = mv_z_flux[*,iarray-1]
           s_flux = mv_err_z_flux[*, iarray-1]
           diam_1 = dblarr(30)
           ytab   = lindgen(32.)*500./31. - 250.
           yy     = dblarr(30)
           err    = dblarr(30)
           for ip = 1, 30 do begin
              w=where(nas_xa[wd2] lt ytab[ip+1] and nas_xa[wd2] ge ytab[ip], nw)
              if nw gt 0 then diam_1[ip-1] = median(z_flux[wd2[w]])
              if nw gt 0 then yy[    ip-1] = median(nas_xa[wd2[w]])
              if nw gt 0 then err[   ip-1] = median(s_flux[wd2[w]]);/sqrt(nw)
           endfor            
           oploterror, yy, diam_1, yy*0., err, col=0, errcol=0, psym=4, symsize=0.5

           ;;
           plot, nas_ya[wd1], nas_ya[wd1], col=0,  position=pp[ilam,2,*], /nodata, /noerase, $
                 yr=yra, /ys, xr=[-200, 200], /xs, xtitle='Offset X (arcsec)', ytitle="defocus Z (mm)", title="FWHM-based results for A"+strtrim(iarray,2) , charsize=0.7  
           for iseq = 0, nseq-1 do begin
              z_fwhm = z_fwhm_tab[*,iarray-1,iseq]
              nas_x  = nas_x_tab[ *,iarray-1,iseq]
              nas_y  = nas_y_tab[ *,iarray-1,iseq]
              rnas_x = calp*nas_x+salp*nas_y
              rnas_y = calp*nas_y-salp*nas_x
              wd1_ = where(rnas_x lt pick_d1_max[ilam] and rnas_x gt pick_d1_min[ilam], nwd1)
              wd2_ = where(rnas_y lt pick_d2_max[ilam] and rnas_y gt pick_d2_min[ilam], nwd2)
              diam_1 = dblarr(30)
              ytab   = lindgen(32.)*500./31. - 250.
              yy     = dblarr(30)
              for ip = 1, 30 do begin
                 w=where(nas_x[wd2_] lt ytab[ip+1] and nas_x[wd2_] ge ytab[ip], nw)
                 if nw gt 0 then diam_1[ip-1] = median(z_fwhm[wd2_[w]])
                 if nw gt 0 then yy[    ip-1] = median(nas_x[wd2_[w]])
              endfor            
              oplot, yy, diam_1, col=color_tab[iseq] , psym=8, symsize=0.5, linestyle=1
           endfor
           z_fwhm = mv_z_fwhm[*,iarray-1]
           s_fwhm = mv_err_z_fwhm[*, iarray-1]
           diam_1 = dblarr(30)
           ytab   = lindgen(32.)*500./31. - 250.
           yy     = dblarr(30)
           err    = dblarr(30)
           for ip = 1, 30 do begin
              w=where(nas_xa[wd2] lt ytab[ip+1] and nas_xa[wd2] ge ytab[ip], nw)
              if nw gt 0 then diam_1[ip-1] = median(z_fwhm[wd2[w]])
              if nw gt 0 then yy[    ip-1] = median(nas_xa[wd2[w]])
              if nw gt 0 then err[   ip-1] = median(s_fwhm[wd2[w]]);/sqrt(nw)
           endfor            
           oploterror, yy, diam_1, yy*0., err, col=0, errcol=0, psym=4, symsize=0.5

           if iarray eq 1 then begin
              legendastro, legtext[0:2], textcolor=color_tab[0:2], box = 0, chars = 0.6;, /bottom
              legendastro, [legtext[3:*],'combined'], textcolor=[color_tab[3:*], 0], box = 0, chars = 0.6, /right;, /bottom
           endif
        endfor
        
        outplot, /close
                                ;stop
     endif
        
  endif

  


  
stop
  
end
