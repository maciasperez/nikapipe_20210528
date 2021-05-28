
;; Compares quickly the beam positions, calibrations and FWHM between two
;; kidpars
;; copied from NP/Dev, 24 Oct. 2016
;;
;; LP, update on Feb. 16, 2017 
;;-----------------------------------------------------------------------

pro compare_kidpar_plot, kidpar_file_list, zoom_coord=zoom_coord, savepng=savepng, saveps=saveps, file_suffixe=file_suffixe, nobeam=nobeam, plot_histo=plot_histo, plot_ellipticity=plot_ellipticity, nickname=nickname, suffixename=suffixename, wikitable=wikitable, out_plot_dir=out_plot_dir, pycard=pycard

  if keyword_set(wikitable) then wikistyle=1 else wikistyle = 0
  if keyword_set(out_plot_dir) then plotdir = out_plot_dir+'/' else plotdir=''
  if keyword_set(pycard) then saveps=1
  
  dostat = 0
  if keyword_set(plot_histo) then dostat=1
  
  ;; blacklist_a3 = [6187, 6581, 7152, 7153, 7468, 7478, 7477]
  
  ;;dir     = getenv('NIKA_DIR')+'/Plots/Run18/Geometries/'
  ;;kp_list = dir+["kidpar_20161010s19_v0.fits", "kidpar_20161010s19_v1_LP.fits", "kidpar_20161010s37_v0_LP.fits"]
  ;;kp_list = dir+["kidpar_20161010s19_v0.fits", "kidpar_20161010s19_v1_LP.fits", "kidpar_20161009s333_v0_LP.fits"]
  ;;kp_list = dir+["kidpar_20161010s37_v2_FR.fits", "kidpar_20161010s37_v2_LP.fits"]
  ;;kp_list = dir+["kidpar_20161010s37_v3.fits","kidpar_20161031s231_v2_LP.fits"]

  kp_list = kidpar_file_list
  
  ;; outplot file suffixe
  suf = ''
  if keyword_set(file_suffixe) then suf=file_suffixe

  
  zoom_halfside = 100.

  plot_color_convention, col_a1, col_a2, col_a3, $
                         col_mwc349, col_crl2688, col_ngc7027, $
                         col_n2r9, col_n2r12, col_n2r14, col_1mm
  color_list  = [30, 160, 85, 238, 50, 118]
  ;;color_list = [70, 250, 150, 20]
 
  nkp = n_elements(kp_list)
  if nkp le 4 then color_list = color_list[0:nkp-1] $
  else color_list = (indgen(nkp)+1.)*250./nkp

  if keyword_set(savepng) then png=1
  if keyword_set(saveps) then begin
     ps=1
     ps_xsize    = 20       ;; in cm
     ps_ysize    = 18       ;; in cm
     ps_charsize = 1.
     ps_yoffset  = 0.
     ps_thick    = 4.
  endif else ps_thick=1;1.7
  
  phi    = dindgen(100)/99.*2*!dpi
  cosphi = cos(phi)
  sinphi = sin(phi)


  if wikistyle then begin
     !p.multi=[0, 3, 1]
     wind, 1, 1, /free, xsize=1300, ysize=450
     outplot, file=plotdir+'plot_compare_kidpars'+suf, png=png, $
              ps=ps, xsize=22., ysize=8., charsize=ps_charsize, thick=ps_thick
     csize=1.1
  endif
  
  for iarray = 1, 3 do begin
     
     ;; setting the plot
     if wikistyle lt 1 then begin
        wind, 1, 1, /free, xsize=700, ysize=650
        outplot, file=plotdir+'plot_compare_kidpars_A'+strtrim(iarray,2)+suf, png=png, $
                 ps=ps, xsize=ps_xsize, ysize=ps_ysize, charsize=ps_charsize, thick=ps_thick
        csize=1.0
     endif
     kpfile = kp_list[0]
     kp = mrdfits(kpfile, 1)
     w1 = where( kp.type eq 1 and kp.array eq iarray, nw1)
    
     if nw1 ne 0 then begin
        xra0 = minmax( [kp[w1].nas_x, kp[w1].nas_y])
        xra = xra0 + [-1,1]*0.1*(xra0[1]-xra0[0])
        yra = xra0 + [-1, 2]*0.1*(xra0[1]-xra0[0])
        if keyword_set(zoom_coord) then begin
           xra = zoom_coord[0] + [-1,1]*zoom_halfside
           yra = zoom_coord[1] + [-1,1]*zoom_halfside
        endif
        plot, kp[w1].nas_x, kp[w1].nas_y, $
              /iso, title='A'+strtrim(iarray,2), $
              xtitle='Nasmyth offset x', ytitle='Nasmyth offset y', xra=xra, yra=yra, /xs, /ys, /nodata, charsize=csize
     endif
     
     ;; loop on kidpars
     for ikp = 0, nkp-1 do begin
        kpfile = kp_list[ikp]
        if ikp ne 0 then kp = mrdfits(kpfile, 1)
        w1 = where( kp.type eq 1 and kp.array eq iarray, nw1)
        if nw1 ne 0 then begin
           ixra = minmax( [kp[w1].nas_x, kp[w1].nas_y])
           ixra = ixra + [-1,1]*0.2*(ixra[1]-ixra[0])
           iyra = ixra
           
           if not(keyword_set(nobeam)) then begin
              ;;if ikp eq 0  then oplot, kp[w1].nas_x, kp[w1].nas_y, psym=7, col=color_list[0]
              for i=0, nw1-1 do begin
                 ikid = w1[i]
                 a = kp[ikid].fwhm_x/2.*!fwhm2sigma
                 b = kp[ikid].fwhm_y/2.*!fwhm2sigma
                 theta = kp[ikid].theta
                 
                 oplot, kp[ikid].nas_x + $
                        a*cosphi*cos(theta) + b*sinphi*sin(theta), $
                        kp[ikid].nas_y + $
                        (-sin(theta))*cosphi*a + cos(theta)*sinphi*b, col=color_list[ikp];, thick=ps_thick+(nkp-ikp)
              endfor
           endif else oplot, kp[w1].nas_x, kp[w1].nas_y, psym=8, col=color_list[ikp], symsize=0.7
           oplot, [kp[w1[0]].nas_center_x], [kp[w1[0]].nas_center_y], $
                  psym=1, col=color_list[ikp], syms=2;, thick=2

        endif
     endfor
     if keyword_set(zoom_coord) then begin
        wall = where( kp.array eq iarray and $
                      kp.nas_x gt xra[0] and kp.nas_x lt xra[1] and $
                      kp.nas_y gt yra[0] and kp.nas_y lt yra[1], nwall)
        xyouts, kp[wall].nas_x, kp[wall].nas_y + 2., $
                strtrim(kp[wall].numdet,2), chars=0.7, col=0
     endif

     leg_tab = strarr(nkp)
     for ii = 0, nkp-1 do leg_tab[ii] = FILE_BASENAME(kp_list[ii], '.fits')
     ;; shorter names
     if keyword_set(nickname) then for ii = 0, nkp-1 do leg_tab[ii] = (strsplit( leg_tab[ii], '_', /extract))[1] 
     if keyword_set(suffixename) then begin
        for ii = 0, nkp-1 do begin
           namesplit = strsplit( leg_tab[ii], '_', /extract)
           leg_tab[ii] = namesplit[n_elements(namesplit)-1]
        endfor
     endif
     
     if wikistyle lt 1 then begin
        legendastro, leg_tab, line=0, col=color_list, box=0, /trad
        outplot, /close
     endif
     
  endfor
  if wikistyle gt 0 then begin
     legendastro, leg_tab, line=0, col=color_list, box=0, /trad, charsize=0.6
     outplot, /close
     !p.multi=0
  endif
  if keyword_set(saveps) then !p.thick = 1.
  

  ;; 
  ;; 
  ;;   histograms
  ;;______________________________________________________________________
  
  if dostat gt 0 then begin
     ;;wd, /a
     
     ;; FWHM
     ;;--------------------------------------------------------------------------------
     wind, 1, 1, xsize = 1200, ysize =  500, /free, title="FWHM"
     my_multiplot, 3, 1, pp, pp1, /rev, ymargin=0.08, gap_x=0.08, xmargin = 0.06
     
     outplot, file=plotdir+'plot_histo_fwhm'+suf, png=png, $
              ps=ps, xsize=ps_xsize, ysize=ps_ysize, charsize=ps_charsize, thick=ps_thick
     
     array = [1, 3, 2]
     
     fmin  = [7., 7., 13.]
     fmax  = [18.,18.,23.]
     fmin  = [8., 8., 15.]
     fmax  = [14.,14.,20.]
     nbins = [100., 100., 100.]

     avgs = fltarr(3, nkp)
     meds = fltarr(3,nkp)
     sigs = fltarr(3,nkp)
     gpar_center = fltarr(3, nkp)
     gpar_sigma  = fltarr(3, nkp)
     nkids = lonarr(3, nkp)
     
     for ilam=0, 2 do begin
        iarray = array[ilam]
        
        noerase = 1
        
        emin = fmin[ilam]
        emax = fmax[ilam]
        nbin = nbins[ilam]
        binz = (emax - emin)/(nbin-1)
        ebin  = indgen(nbin)*binz + emin
                
        ;; plot, ebin, ebin*0., xtitle = "FWHM [arcsec]", /nodata, yr=[0, 90], /ys, $
        ;;       ytitle='# in A'+strtrim(iarray,2), $
        ;;       xr=[emin, emax], /xs, noerase=noerase,
        ;;       position=pp1[ilam,*]

        if wikistyle gt 0 then begin
           print, '{| class="wikitable" style="vertical-align:bottom; text-align:right; color: black; width: 95%;"'
           print, '|- style = "text-align:center; background-color: #d3d9df;"'
           print, '| colspan="12" | Comparison of geometries'
           print, '|- style = "text-align:center;"'
           print, '| colspan="5" | Basic facts'
           print, '| colspan="3" | # selected KIDs'
           print, '| colspan="3" | Median FWHM'
           print, '|'
           print, '|-'
           print, '| style="width: 10%" | Scan ID'
           print, '| style="width: 7%"  | Source'
           print, '| style="width: 7%"  | UT'
           print, '| style="width: 5%"  | elev'
           print, '| style="width: 6%"  | tau225'
           print, '| style="width: 9%"  | A1'
           print, '| style="width: 9%"  | A3'
           print, '| style="width: 9%"  | A2'
           print, '| style="width: 9%"  | A1'
           print, '| style="width: 9%"  | A3'
           print, '| style="width: 9%"  | A2'
           print, '| style="width: 40%" | Plots'
           print, '|-'
        endif
        
        for ikp = 0, nkp-1 do begin
           kpfile = kp_list[ikp]
           kp = mrdfits(kpfile, 1)
           w1 = where( kp.type eq 1 and kp.array eq iarray, nw1)
           if nw1 gt 0 then begin
              nkids[ilam, ikp] = nw1
              
              f  = kp[w1].fwhm
              hist = histogram(f, min=emin, max=emax, nbins=nbin)
              
              ;;hist = [hist, 0.]
              x = fltarr(2 * nbin)
              x[2 * indgen(nbin)]     = ebin
              x[2 * indgen(nbin) + 1] = ebin
              y = fltarr(2 * nbin)
              y[2 * indgen(nbin)]     = hist
              y[2 * indgen(nbin) + 1] = hist
              y = shift(y, 1)
              
                                ;oplot, x, y, col=color_list[ikp], thick=2.
              np_histo, [f], xh_res, yh_res, gpar_res, min=emin, max=emax, xrange=[emin, emax], fcol=color_list[ikp], /fit, noerase=noerase, position=pp1[ilam,*], /nolegend, colorfit=250, thickfit=2
              
              avgs[ilam, ikp] = mean(f)
              meds[ilam, ikp] = median(f)
              sigs[ilam, ikp] = stddev(f)
              gpar_center[ilam, ikp] = gpar_res[1]
              gpar_sigma[ ilam, ikp] = gpar_res[2]
           endif else print, 'no valid KIDs'
        endfor
        
        if ilam eq 0 then begin
           leg_tab = strarr(nkp)
           for ii = 0, nkp-1 do leg_tab[ii] = FILE_BASENAME(kp_list[ii], '.fits')
           if keyword_set(nickname) then for ii = 0, nkp-1 do leg_tab[ii] = (strsplit( leg_tab[ii], '_', /extract))[1] 
           legendastro, leg_tab, line=0, col=color_list, box=0, /trad
          
        endif
     endfor
     
     print, ''
     print, 'Number of valid kids'
     for ik=0, nkp-1 do begin
        print, ''
        print, 'kidpar: ',  FILE_BASENAME(kp_list[ik], '.fits')
        for i=0, 2 do begin
           print, 'A',strtrim(string(array[i]),2),' #kids = ', strtrim(string(nkids[i,ik], format='(f6.0)'),2)
        endfor
     endfor
     print, ''
     print, 'FWHM stat. [arcsec]'
     for ik=0, nkp-1 do begin
        print, ''
        print, 'kidpar: ',  FILE_BASENAME(kp_list[ik], '.fits')
        for i=0, 2 do begin
           print, 'A',strtrim(string(array[i]),2),' med fwhm  = ', strtrim(string(meds[i,ik], format='(f6.1)'),2), $
                  ', avg fwhm = ', strtrim(string(avgs[i,ik], format='(f6.1)'),2), $
                  ', rms = ' ,strtrim(string(sigs[i, ik], format='(f6.1)'),2), $
                  ', G fit = ',strtrim(string(gpar_center[i, ik], format='(f6.1)'),2), ' pm ', strtrim(string(gpar_sigma[i, ik], format='(f6.1)'),2) 
           
           
        endfor
     endfor
        
     outplot, /close

     ;; combined results
     errstat = dblarr(3)
     errsyst = dblarr(3)
     fwhm    = dblarr(3)
     for ilam=0, 2 do begin
        errstat[ilam] = sqrt(1d0/total(1d0/sigs[ilam,*]^2))
        fwhm[ilam]    = errstat[ilam]^2*total(meds[ilam,*]/sigs[ilam,*]^2)
        errsyst[ilam] = stddev(meds[ilam,*])
     endfor
     print, ''
     print, 'Combined results'
     for i=0, 2 do begin
        print, 'A',strtrim(string(array[i]),2),' fwhm = ', strtrim(string(fwhm[i], format='(f6.1)'),2), $
               ' pm ', strtrim(string(errstat[i], format='(f6.1)'),2), ' (stat.) pm ', strtrim(string(errsyst[i], format='(f6.1)'),2), ' (syst.)' 
     endfor
    
     if wikistyle gt 0 then begin
        for ik=0, nkp-1 do begin
           print,'|-'
           print,'|'+ FILE_BASENAME(kp_list[ik], '.fits')
           print,'|'
           print,'|'
           print,'|'
           print,'|'
           print,'| '+strtrim(string(nkids[0,ik], format='(f6.0)'),2)
           print,'| '+strtrim(string(nkids[1,ik], format='(f6.0)'),2)
           print,'| '+strtrim(string(nkids[2,ik], format='(f6.0)'),2)
           print,'| '+strtrim(string(meds[0,ik], format='(f6.1)'),2)+'+-'+strtrim(string(sigs[0, ik], format='(f6.1)'),2)
           print,'| '+strtrim(string(meds[1,ik], format='(f6.1)'),2)+'+-'+strtrim(string(sigs[1, ik], format='(f6.1)'),2)
           print,'| '+strtrim(string(meds[2,ik], format='(f6.1)'),2)+'+-'+strtrim(string(sigs[2, ik], format='(f6.1)'),2)
           print,'|'
        endfor
        print, '|}'
        
     endif


     
  endif

  if keyword_set(plot_ellipticity) then begin
     ;; ellipticity
     ;;--------------------------------------------------------------------------------
     wind, 1, 1, xsize = 1200, ysize =  500, /free, title="ellipticity"
     my_multiplot, 3, 1, pp, pp1, /rev, ymargin=0.08, gap_x=0.08, xmargin = 0.06
     outplot, file=plotdir+'plot_histo_ellipticity'+suf, png=png, $
              ps=ps, xsize=ps_xsize, ysize=ps_ysize, charsize=ps_charsize, thick=ps_thick
     
     array = [1, 3, 2]
     
     meds = fltarr(3,nkp)
     sigs = fltarr(3,nkp)
     
     fmin = [0, 0, 0]
     fmax = [0.5, 0.5, 0.25]
     nbins = [51., 51., 31.]
     
     for ilam=0, 2 do begin
        iarray = array[ilam]
        
        noerase = 1
        if ilam eq 0 then noerase=0

        emin = fmin[ilam]
        emax = fmax[ilam]
        nbin = nbins[ilam]
        binz = (emax-emin)/(nbin-1)
 
        ebin = indgen(nbin)*binz+emin
        
        plot, ebin, ebin*0., xtitle = "(a-b)/a", /nodata, yr=[0, 90], /ys, $
              ytitle='# in A'+strtrim(iarray,2), noerase=noerase, position=pp1[ilam,*]
        for ikp = 0, nkp-1 do begin
           kpfile = kp_list[ikp]
           kp = mrdfits(kpfile, 1)
           w1 = where( kp.type eq 1 and kp.array eq iarray, nw1)
           
           e = dblarr(nw1)
           for i=0, nw1-1 do begin
              ikid = w1[i]
              e[i] = (max([kp[ikid].fwhm_x, kp[ikid].fwhm_y]) - min([kp[ikid].fwhm_x, kp[ikid].fwhm_y])) / max([kp[ikid].fwhm_x, kp[ikid].fwhm_y])
           endfor

           e2 = kp[w1].ellipt-1.
           
           hist = histogram(e, nbins=nbin, min=0, max=0.5)
           hist2 = histogram(e2, nbins=nbin, min=0, max=0.5)
           
           ;;hist = [hist, 0.]
           x = fltarr(2 * nbin)
           x[2 * indgen(nbin)]     = ebin
           x[2 * indgen(nbin) + 1] = ebin
           y = fltarr(2 * nbin)
           y[2 * indgen(nbin)]     = hist
           y[2 * indgen(nbin) + 1] = hist
           y = shift(y, 1)
           
           y2 = fltarr(2 * nbin)
           y2[2 * indgen(nbin)]     = hist2
           y2[2 * indgen(nbin) + 1] = hist2
           y2 = shift(y2, 1)
           
           ;;oplot, x, y, col=color_list[ikp], thick=2.
           oplot, x, y2, col=color_list[ikp], thick=2.
           
           meds[ilam, ikp] = median(e2)
           sigs[ilam, ikp] = stddev(e2)
           
        endfor

        if ilam eq 0 then begin
           leg_tab = strarr(nkp)
           for ii = 0, nkp-1 do leg_tab[ii] = FILE_BASENAME(kp_list[ii], '.fits')
           if keyword_set(nickname) then for ii = 0, nkp-1 do leg_tab[ii] = (strsplit( leg_tab[ii], '_', /extract))[1] 
           legendastro, leg_tab, line=0, col=color_list, box=0, /trad
          
        endif
     endfor
     
     print, ''
     print, 'Ellipticity stat. '
     for ik=0, nkp-1 do begin
        print, ''
        print, 'kidpar: ',  FILE_BASENAME(kp_list[ik], '.fits')
        for i=0, 2 do begin
           print, 'A',strtrim(string(array[i]),2),' 1-e = ', strtrim(string(meds[i,ik], format='(f6.2)'),2), $
                  ' pm ', strtrim(string(sigs[i, ik], format='(f6.2)'),2)
        endfor
     endfor

     
     outplot, /close
     ;;stop

     
  endif


  if keyword_set(pycard) then spawn, "python3 ${NIKA_PIPELINE_DIR}/../Labtools/LP/pytools/compare_kidpar_plot.py"

  
  
end
