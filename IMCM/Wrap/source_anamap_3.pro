
pro source_anamap_3, grid, grid_jk, header, source, $
                     ra1=ra1, dec1=dec1, ra2=ra2, dec2=dec2, $
                     imr_1mm=imr_1mm, imr_2mm=imr_2mm, $
                     cat_nickname=cat_nickname, $
                     png=png, ps=k_ps, pdf = k_pdf, noplot=noplot, $
                     graph_file = graph_file, $
                     x_in=x_in, y_in=y_in, $
                     simpar=simpar, $
                     background_radius_max=background_radius_max, title=title, $
                     snr_thresh=k_snrth, position=position, $
                     alternate_flux = alternate_flux, $
                     mjy = mjy, param = param, $
                     noiseup = noiseup, k_snr = k_snr, $
                     catall = catall, catmerge = catmerge
  
; Program mostly written by NP, adapted by FXD
if not keyword_set( graph_file) then graph_file = 'source_detect'
if not keyword_set(imr_1mm) then imr_1mm = [-1,1]
if not keyword_set(imr_2mm) then imr_2mm = [-1,1]
if not keyword_set(title)   then title=''
if keyword_set( k_ps) then post = k_ps else post = 0

if keyword_set(ra1) ne keyword_set(dec1) then begin
   message, /info, "ra1 and dec1 keywords must be set together"
   return
endif
if keyword_set(ra2) ne keyword_set(dec2) then begin
   message, /info, "ra2 and dec2 keywords must be set together"
   return
endif
if keyword_set( mjy) then flfa = 1D3 else flfa = 1. ; convert to mJy
!mamdlib.coltable = 39

extast, header, astr
ra_center  = sxpar( header, "crval1")
dec_center = sxpar( header, "crval2")
pixsize = abs(sxpar(header, "cdelt1"))*3600D0 ; in arcsec.
;; Write catalog to disk
if not keyword_set(cat_nickname) then cat_nickname=source+'_catalog'
junk = grid                     ; grid is already truncated, don't do it twice
; Just keep the template truncate_map for later use
nk_truncate_filter_map, param, -1, junk, truncate_map = truncate_map

;;===========================================
;; Matt's detection and photometry

;; mb_extraction_and_mc_g2
if not keyword_set(k_snrth) then snr_thresh = 3. $; 3 ; 4 ; 8. ; to be adjusted
else snr_thresh = k_snrth
;help, k_snrth, snr_thresh

pixsize = grid.map_reso
npix_kernel = 30

map_ext = ["_1mm", '2']
hits_ext = ['_1mm', '_2'] ; no comment :/
cat_file_ext = ['1mm', '2mm']
fwhm = [!nika.fwhm_nom[0], !nika.fwhm_nom[1]]

next = n_elements(map_ext)
my_plot_window = 0

if keyword_set(background_radius_max) then begin
   dist2center = sqrt( grid.xmap^2 + grid.ymap^2)
   background_mask = where( dist2center gt background_radius_max, nwbg)
   if nwbg eq 0 then delvarx, background_mask
endif

if not keyword_set(noplot) then $
   if not keyword_set( k_pdf) and not keyword_set( ps) then wind, 1, 1, /free, /large
if not keyword_set( k_pdf) and not keyword_set( ps) then my_multiplot, 2, 2, pp, pp1, /rev, gap_x=0.05
abs_flux_max = 1d6  ; no limit.
if keyword_set( mjy) then fmt_flux = '(F7.2)' else fmt_flux  = '(F11.5)' ; allow for negative sign
if keyword_set( png) then  outplot, file=graph_file, png=png, thick=thick, charthick=thick ;, ps=post, 
print, graph_file

   
for iext=0, next-1 do begin
   junk = execute( "map      = grid.map_i"+map_ext[iext])
   junk = execute( "noise    = sqrt(grid.map_var_i"+map_ext[iext]+")") ; stddev, not variance
   junk = execute( "hits     = grid.nhits"+hits_ext[iext])
   junk = execute( "map_JK   = grid_jk.map_i"+map_ext[iext])
   junk = execute( "noise_JK = sqrt( grid_jk.map_var_i"+map_ext[iext]+")") ; stddev, not variance
;stop, '1'
   ;; x_in and y_in have priority over ra_in to avoid approximations with cos(dec_center)
   if keyword_set(x_in) and keyword_set(y_in) then begin
      xy2ad, x_in, y_in, astr, ra_in, dec_in
   endif else begin
      if iext eq 0 and keyword_set(ra1) then begin
         ra_in  = ra1
         dec_in = dec1
      endif
      if iext eq 1 and keyword_set(ra2) then begin
         ra_in  = ra2
         dec_in = dec2
      endif
      if defined(ra_in) then ad2xy, ra_in, dec_in, astr, x_in, y_in
   endelse
   
   if max(hits) gt 0 then begin

      ;; Normalize to 1 at center
      ;; *** Should actually normalize to the integral of the gaussian over
      ;; the central pixel ***
      psf = mb_gauss2d( fwhm[iext]*!fwhm2sigma / pixsize, npix_kernel)
      psf = psf/ max(psf)

      ;; Find sources
      ;; w = where( hits le 0, nw)
      ;; if nw ne 0 then begin
      ;;    map[w]    = !values.d_nan
      ;;    map_JK[w] = !values.d_nan
      ;; endif
      wm = where( finite( noise) eq 0 or noise le 0., nwm)
      if nwm ne 0 then begin
         map[wm]    = !values.d_nan
         map_JK[wm] = !values.d_nan
      endif
;stop, '2'
      ;; On data
      
      mb_source_detection, map, noise, psf, header, snr_thresh, $
                           xx, yy, flux, eflux=eflux, background_mask=background_mask

                                ; Get flux from nk_map_photometry as an alternative
      wmb = where( finite(flux) eq 1, nwmb)
      ;; w = where( finite(flux) eq 1 and $
      ;;            finite(eflux) eq 1, nw)
      if nwmb ne 0 then begin
         flux  = flux[ wmb]*flfa
         eflux = eflux[wmb]*flfa
         xx     = xx[    wmb]
         yy     = yy[    wmb]
      endif
      if keyword_set( ra_in) then begin
         xx = x_in
         yy = y_in
         nw = n_elements( xx)
         if ra1[0] le 0 then nw = 0
         print, 'Input positions taken instead of the found ones'
      endif else nw = nwmb
      ncat = nw
;      print, 'ncat = ', ncat
;         dmax_fit = 100
      if keyword_set( noiseup) then nup = noiseup[iext] else nup = 1.
      if param.k_snr_method eq 2 then noboost = 0 else noboost = 1
      if noboost eq 0 then message, /info, 'noboost = '+strtrim(noboost, 2)
      nk_map_photometry, map, noise^2, hits, $
                         grid.xmap, grid.ymap, !nika.fwhm_nom[iext], /edu, $
                         grid_step=!nika.grid_step[iext], $
                         map_flux = map_flux, map_var_flux = map_var_flux, $
                         dmax=background_radius_max, $
                         /noplot, param = param, $
                         noiseup = nup, k_snr = k_snr, $
                         truncate_map = truncate_map, map_sn_smooth = map_sn, $
                         noboost = noboost ; already done the imcmcall main routine (nk_average_scan/nk_snr_flux_map) FXD Jan 2021
       if keyword_set(alternate_flux) then begin
         if nw ne 0 then begin
            flux = map_flux[xx, yy]*flfa
            eflux = sqrt(map_var_flux[xx, yy])*flfa
            if iext eq 0 then begin
               fl1mm = flux
               efl1mm = eflux
            endif else begin
               fl2mm = flux
               efl2mm = eflux
            endelse

            wr = where( finite(flux) eq 1 and $
                       finite(eflux) eq 1, nwr)
            if not keyword_set( ra1) then begin
               if nwr ne 0 then begin
                  flux  = flux[ wr]
                  eflux = eflux[wr]
                  xx     = xx[    wr]
                  yy     = yy[    wr]
                  nw = nwr
               endif else begin
                  flux = [-1]
                  eflux = [-1]
                  xx = 0.
                  yy = 0.
                  nw = 0
               endelse
            endif
         endif
      endif 
      
      if nw eq 0 then print,  'No source found'
      if nw ne 0 then begin
         wf = where( abs(flux) le abs_flux_max and $
                    abs(flux) gt snr_thresh*eflux, nwf)
         
         if not keyword_set( ra1) then begin
            if nwf eq 0 then begin
               print,  'No source above than SNR'
               flux = [-1]
               eflux = [-1]
               xx = 0.
               yy = 0.
               nw = 0
            endif else begin
               flux  = flux[ wf]
               eflux = eflux[wf]
               xx     = xx[    wf]
               yy     = yy[    wf]
               nw = n_elements( flux)
            endelse
         endif
         

;         order = reverse(sort(flux))
         if not keyword_set( ra1) then begin
            order = reverse( sort( xx)) ; sort by RA
            flux  = flux[ order]
            eflux = eflux[order]
            xx     = xx[    order]
            yy     = yy[    order]
         endif
         
      endif 
      ;; On JK
      mb_source_detection, map_JK, noise_JK, psf, header, snr_thresh, $
                           x_jk, y_jk, flux_jk, $
                           eflux=eflux_jk, background_mask=background_mask

      if keyword_set( noiseup) then nup = noiseup[iext] else nup = 1
      nk_map_photometry, map_JK, noise_JK^2, hits, $
                         grid.xmap, grid.ymap, !nika.fwhm_nom[iext], /edu, $
                         grid_step=!nika.grid_step[iext], $
                         map_flux = map_flux_JK, map_var_flux = map_var_flux_JK, $
                         dmax=background_radius_max, /noplot, $
                         param = param, noiseup = nup, k_snr = k_snr, $
                         truncate_map = truncate_map, $
                         map_sn_smooth = map_sn_JK, noboost = noboost ; already done the imcmcall main routine (nk_average_scan/nk_snr_flux_map) FXD Jan 2021
      if keyword_set(alternate_flux) then begin
;         dmax_fit = 100
         if keyword_set( ra1) then begin
            if nw ne 0 then begin
               flux_jk = map_flux_JK[xx, yy] * flfa
               eflux_jk = sqrt(map_var_flux_JK[xx, yy]) * flfa
            endif
         endif else begin
            nwjk = total( finite(x_jk))
            if nwjk ne 0 then begin
               flux_jk = map_flux_JK[x_jk, y_jk] * flfa
               eflux_jk = sqrt(map_var_flux_JK[x_jk, y_jk]) * flfa
            endif
         endelse
      endif
      
      ;; Back to sky coordinates for the detected sources
      if nw ne 0 then xy2ad, xx, yy, astr, ra, dec else delvarx, ra
      if nw ne 0 and not keyword_set( ra1) then begin  ; don't do blind catalogs when coordinates are inputs


         openw, lu, cat_nickname+"_Blind_"+cat_file_ext[iext]+".dat", /get_lu
         printf, lu, " #,   ra(deg),  dec(deg), ra,         dec,        flux"+cat_file_ext[iext]+", err_flux"+cat_file_ext[iext]+', SNR'
         fmt_coord = '(F9.5)'
         
         for i=0, nw-1 do begin
            rd = ra[i]
            dd = dec[i]
            myra  = sixty( rd/15.)
            mydec = sixty( dd)
            str = string(i,'(I3)')+", "+string(ra[i],form=fmt_coord)+", "+string(dec[i],form=fmt_coord)+", "+$
                  string(myra[0],form='(I2.2)')+":"+string(myra[1],form='(I2.2)')+":"+zeropadd(strtrim(string(myra[2],form='(F4.1)'),2), 4)+", "
            if dd gt 0 then str += "+"+string(mydec[0],form='(I2.2)') else str += "-"+string(abs(mydec[0]),form='(I2.2)')
            str += ":"+string(abs(mydec[1]),form='(I2.2)')+":"+zeropadd(string(abs(mydec[2]),form='(F4.1)'), 4)+", "+$
                   string(flux[i],form=fmt_flux)+", "+string(eflux[i],form=fmt_flux)+', '+string(flux[i]/eflux[i], form = '(1F6.1)')
            printf, lu, str
                                ;     message, /info, strtrim(i+1,2)+"/"+strtrim(n_elements(ra),2)+": "+str
         endfor
         close, lu
         free_lun, lu
         message, /info, "Wrote "+cat_nickname+"_Blind_"+cat_file_ext[iext]+".dat"
      endif
      
      ;; If input positions are provided, compute the fluxes at these exact locations
      if defined(ra1) then begin
         if ra1[0] ge 0. then begin
            mb_source_detection, map, noise, psf, header, snr_thresh, $
                                 junk, junk1, flux_nominal_pos, $
                                 x_in=x_in, y_in=y_in, $
                                 eflux=eflux_in, background_mask=background_mask
            
            wmb = where( finite(flux_nominal_pos) eq 0 or $
                         finite(eflux_in) eq 0, nwmb)
            flux_nominal_pos = flux_nominal_pos*flfa
            eflux_in = eflux_in*flfa
            if not keyword_set( ra1) then begin
               if nwmb ne 0 then begin
                  flux_nominal_pos[wmb] = 0.d0
                  eflux_in[        wmb] = 0.d0
               endif
               wmba = where( abs(flux_nominal_pos) gt abs_flux_max, nwmba)
               if nw ne 0 then begin
                  flux_nominal_pos[wmba] = 0.d0
                  eflux_in[        wmba] = 0.d0
               endif
            endif else begin    ; nominal case
               flux = flux_nominal_pos
               eflux = eflux_in
            endelse
            if iext eq 0 then begin
               fl1mm = flux
               efl1mm = eflux
            endif else begin
               fl2mm = flux
               efl2mm = eflux
            endelse
            
            openw, lu, cat_nickname+"_InputPos_"+cat_file_ext[iext]+".dat", /get_lu
            printf, lu, "# ra(deg), dec(deg), ra, dec, flux"+cat_file_ext[iext]+", err_flux"+cat_file_ext[iext]
            for i=0, nw-1 do begin
               rd = ra_in[i]
               dd = dec_in[i]
               myra  = sixty( rd/15.)
               mydec = sixty( dd)
               str = string(i,'(I3)')+", "+string(ra_in[i],form=fmt_coord)+", "+string(dec_in[i],form=fmt_coord)+", "+$
                     string(myra[0],form='(I2.2)')+":"+string(myra[1],form='(I2.2)')+":"+strtrim(string(myra[2],form='(F4.1)'),2)+", "
               
               if dd gt 0 then str += "+"+string(mydec[0],form='(I2.2)') else str += "-"+string(abs(mydec[0]),form='(I2.2)')
               str += ":"+string(abs(mydec[1]),form='(I2.2)')+":"+string(abs(mydec[2]),form='(F4.1)')+", "+$
                      string(flux_nominal_pos[i],form=fmt_flux)+", "+string(eflux_in[i],form=fmt_flux)
               printf, lu, str
            endfor 
            close, lu
            free_lun, lu
            message, /info, "Wrote "+cat_nickname+"_InputPos_"+ $
                     cat_file_ext[iext]+".dat"
         endif
      endif 
      
      

;print, "Sources found on the 1mm map: "+strtrim(n_elements(flux_1mm),2)
;print, "Sources found on the 1mm JK map: "+strtrim(n_elements(flux_jk_1mm),2)

;; ;; Back to sky coordinates
;; extast, header, astr
;; xy2ad, x_1mm, y_1mm, astr, ra1, dec1
;; xy2ad, x_2mm, y_2mm, astr, ra2, dec2

      if iext eq 0 then imrange = imr_1mm else imrange = imr_2mm
      if not keyword_set(noplot) then begin
         ;; Display
;;          if my_plot_window eq 0 then begin
;;             wind, 1, 1, /free, /large
;;             my_plot_window = !d.window
;;             outplot, file=source+"_SourcesDetect", png=png, ps=ps
;;             my_multiplot, 2, 2, pp, pp1, /rev
;;          endif
         
;;          r = fwhm[iext]/2.
;;          phi = dindgen(100)/99*2*!dpi
;;          !mamdlib.coltable=0
;;          col_source=250
;;          thick=2
;;          leg_txt = ['Blind detect.'] & leg_col=[col_source]
;;          mymap = map
;;          w = where( finite(mymap) eq 0, nw)
;;          if nw ne 0 then mymap[w] = 0.d0
;;          himview, mymap, header, position=pp[iext,0,*], title=title+" Map "+map_ext[iext], imr=imrange, /noerase, fwhm=fwhm[iext]
;;          if defined(ra_in) then begin
;;             leg_txt = [leg_txt,'Input pos.']
;;             leg_col = [leg_col, 70]
;;             oplot, x_in, y_in, psym=1, col=70, syms=2
;;          endif
;;          for i=0, n_elements(x)-1 do begin
;;             oplot, x[i]+r*cos(phi), y[i]+r*sin(phi), col=col_source
;;             xyouts, x[i]+r/sqrt(2), y[i]+r/sqrt(2), col=col_source, strtrim(i,2), charsize=0.5
;;          endfor
;;          legendastro, leg_txt, textcol=leg_col
;;          
;;          mymap = map_jk
;;          w = where( finite(mymap) eq 0, nw)
;;          if nw ne 0 then mymap[w] = 0.d0
;;          himview, mymap, header, position=pp[iext,1,*], title=title+'JK '+map_ext[iext], $
;;                   imr=imrange, /noerase, fwhm=fwhm[iext]
;;          for i=0, n_elements(x_jk)-1 do oplot, x_jk[i]+r*cos(phi), y_jk[i]+r*sin(phi), col=col_source, thick=thick
;;          if keyword_set(ra_in) then oplot, x_in, y_in, psym=1, col=70, syms=2
;;          legendastro, leg_txt, textcol=leg_col
;;       endif

         r = fwhm[iext]/2.
         phi = dindgen(100)/99*2*!dpi
         mymap = map
         mymap_JK = map_JK
         ;; min_noise = min( noise[ where(noise gt 0.)])
         ;; w = where( finite(mymap) eq 0 and noise gt 5.*min_noise, nw)
         ;; if nw ne 0 then mymap[w] = 0.d0
         w = where( finite(mymap) eq 0 or finite(mymap_JK) eq 0 or $
                    finite( noise) eq 0 or noise le 0., nw)
         if nw ne 0 then begin
            mymap[w]    = 0.
            mymap_JK[w]    = 0.
         endif
;         stop, '3'
         if keyword_set( k_pdf) then begin
;            fxd_ps, /portrait, /color
            himview, mymap, header, /noerase, fwhm=fwhm[iext], colt=4, $
                     imrange=imrange, title = title+ ' ' + cat_file_ext[iext], $
                     postscript = graph_file+'_'+ cat_file_ext[iext]+'.ps', /noclose
;            print, 'Open ps '+graph_file+'_'+ cat_file_ext[iext]+'.ps'
         endif else begin
            himview, mymap, header, /noerase, fwhm=fwhm[iext], colt=4, $
                     position=pp[iext,0,*], imrange=imrange, $
                     title = title+ ' ' + cat_file_ext[iext]
            loadct, 39
         endelse
         col_source=100
         for i=0, n_elements(xx)-1 do begin
            oplot, xx[i]+r*cos(phi), yy[i]+r*sin(phi), col=col_source
            xyouts, xx[i]+r/sqrt(2), yy[i]+r/sqrt(2), col=col_source, strtrim(i,2), charsize=0.5
         endfor
         ad2xy, astr.crval[0], astr.crval[1], astr, xc, yc
         if keyword_set(background_radius_max) then begin
            oplot, xc + background_radius_max*cos(phi)/grid.map_reso, yc + background_radius_max*sin(phi)/grid.map_reso, col=255
         endif
;         if keyword_set( k_pdf) then fxd_psout, save_file = graph_file+'_'+ cat_file_ext[iext]+'.pdf', /over
         if keyword_set( k_pdf) then close_imview
         ;; w = where( finite(mymap_JK) eq 0and noise gt 5.*min_noise, nw)
         ;; if nw ne 0 then mymap_JK[w] = 0.d0
         if keyword_set( k_pdf) then begin
;            fxd_ps, /portrait, /color
            himview, mymap_JK, header, /noerase, fwhm=fwhm[iext], colt=4, $
                     imrange=imrange, title = title+ ' JK '+ ' ' + cat_file_ext[iext], $
                     postscript = graph_file+'_JK_'+ cat_file_ext[iext]+'.ps', /noclose
         endif else begin
            himview, mymap_JK, header, /noerase, fwhm=fwhm[iext], colt=4, $
                     position=pp[iext,1,*], imrange=imrange, $
                     title = title+ ' JK '+ ' ' + cat_file_ext[iext]
            loadct, 39
         endelse
         
         col_source=100
         for i=0, n_elements(xx)-1 do begin
            oplot, xx[i]+r*cos(phi), yy[i]+r*sin(phi), col=col_source
            xyouts, xx[i]+r/sqrt(2), yy[i]+r/sqrt(2), col=col_source, strtrim(i,2), charsize=0.5
         endfor
;         if keyword_set( k_pdf) then fxd_psout, save_file = graph_file+'_JK_'+ cat_file_ext[iext]+'.pdf', /over
         if keyword_set( k_pdf) then close_imview
      endif
   endif

                                ; Make an histogram of S/N
   if keyword_set( k_pdf) then begin
      fxd_ps, /portrait
      !p.multi = [0, 1, 2]
      whk = where( truncate_map gt 0.99 and map_sn ne 0, nwhk)
      if nwhk gt 30 then histo_make, map_sn[ whk],  /gauss, n_bin = 301, $
                                     minval = -10, maxval = +10, /legend, $
                                     title = file_basename( graph_file)+ $
                                     '_HistoSN_'+ cat_file_ext[iext], $
                                     xarr, yarr, stat_res, gauss_res, /plot, size = 0.5 $
      else print, 'not enough valid pixel to do the map S/N histogram'
      whk = where( truncate_map gt 0.99 and map_sn_JK ne 0, nwhk)
      if nwhk gt 30 then histo_make, map_sn_JK[ whk],  /gauss, n_bin = 301, $
                                     minval = -10, maxval = +10, /legend, $
                                     title = 'JK '+ file_basename( graph_file) $
                                     +'_HistoSN_'+ cat_file_ext[iext], $
                                     xarr, yarr, stat_res, gauss_res, /plot $
      else print, 'not enough valid pixel to do the map S/N JK histogram'
      fxd_psout, save_file = $
                 graph_file+'_HistoSN_'+ cat_file_ext[iext]+'.pdf', /over
   endif

endfor                          ; end loop on iext

;;if post eq 2 then fxd_psout, save_file=graph_file+'.pdf', /over else $
if keyword_set(k_pdf) then begin
                                ; transform .ps into .pdf
   for iext = 0, next-1 do begin
      command = 'ps2pdf '+ graph_file+'_'+ cat_file_ext[iext]+'.ps ' + graph_file+'_'+ cat_file_ext[iext]+'.pdf'
      spawn, command, res
      command = 'ps2pdf '+ graph_file+'_JK_'+ cat_file_ext[iext]+'.ps ' + graph_file+'_JK_'+ cat_file_ext[iext]+'.pdf'
      spawn, command, res
   endfor
                                ; unite pdf
   allpdf = strjoin( [graph_file+'_'+ cat_file_ext+'.pdf', graph_file+'_JK_'+ cat_file_ext+'.pdf']+' ')
   command = 'pdfunite '+ allpdf+ ' '+graph_file+ '.pdf'
   spawn, 'which pdfunite', res
   if strlen( strtrim(res, 2)) gt 0 then $
      spawn, command, res else print, 'Try installing pdfunite '
                                ; Delete all intermediate files
   for iext = 0, next-1 do begin
      command = 'rm -f '+ graph_file+'_'+ cat_file_ext[iext]+'.ps ' + graph_file+'_'+ cat_file_ext[iext]+'.pdf'
      spawn, command, res
      command = 'rm -f '+ graph_file+'_JK_'+ cat_file_ext[iext]+'.ps ' + graph_file+'_JK_'+ cat_file_ext[iext]+'.pdf'
      spawn, command, res
   endfor

   allpdf = strjoin( [graph_file+'_HistoSN_'+ cat_file_ext+'.pdf']+' ')
   command = 'pdfunite '+ allpdf+ ' '+graph_file+ '_HistoSN.pdf'
   spawn, 'which pdfunite', res
   if strlen( strtrim(res, 2)) gt 0 then $
      spawn, command, res else print, 'Try installing pdfunite '
                                ; Delete all intermediate files
   for iext = 0, next-1 do begin
      command = 'rm -f '+ graph_file+'_HistoSN_'+ cat_file_ext[iext]+'.pdf'
      spawn, command, res
   endfor
endif else begin
   outplot, /close, /verb
endelse

if keyword_set( catall) and not keyword_set( ra_in) then begin
   psou = replicate({id:-1, ra:0D0, dec:0D0, ras:'', decs:'', $
                     fl1:0D0, efl1:0D0, snr1:0D0, $
                     fl2:0D0, efl2:0D0, snr2:0D0}, 1000)
   file1mm = cat_nickname+"_Blind_"+ cat_file_ext[0]+".dat"
   file2mm = cat_nickname+"_Blind_"+ cat_file_ext[1]+".dat"
   nid1mm = 0  ; Default
   nid2mm = 0
   nid1 = -1
   nid2 = -1
   if file_test( file1mm) then begin
      readcol, file1mm, id, ra, dec, ras, decs, fl, efl, snr, format='A,D,D,A,A,D,D,D', comment='#', /silent, delim=','
      nid1mm = n_elements( id)
      nid1 = nid1mm-1
      psou[0:nid1].id = id+1000
      psou[0:nid1].ra = ra
      psou[0:nid1].dec = dec
      psou[0:nid1].ras = ras
      psou[0:nid1].decs = decs
      psou[0:nid1].fl1 = fl
      psou[0:nid1].efl1 = efl
      psou[0:nid1].snr1 = snr
   endif else message, /info, 'No file at 1mm? '+ file1mm
   if file_test( file2mm) then begin
      readcol, file2mm, id, ra, dec, ras, decs, fl, efl, snr, format='A,D,D,A,A,D,D,D', comment='#', /silent, delim=','
      nid2mm = n_elements( id)
      nid2 = nid1mm+nid2mm-1
      if nid2mm gt 0 then begin
         psou[nid1mm:nid2].id = id+2000
         psou[nid1mm:nid2].ra = ra
         psou[nid1mm:nid2].dec = dec
         psou[nid1mm:nid2].ras = ras
         psou[nid1mm:nid2].decs = decs
         psou[nid1mm:nid2].fl2 = fl
         psou[nid1mm:nid2].efl2 = efl
         psou[nid1mm:nid2].snr2 = snr
      endif 
   endif else begin
      nid2 = nid1
      message, /info, 'No file at 2mm? '+ file2mm
   endelse
   
   if nid2 ge 0 then begin
      psou = psou[0:nid2]
      psou = psou[ multisort( psou.ra, psou.dec)]
   endif
   listout = strarr(nid2+2)     ; nid2+1 sourcs + header line
   listout[0] = $
      '   #,   ra(deg),  dec(deg),          ra,          dec,     fl1,    efl1,   snr1,      fl2,     efl2,   snr2'
   fmt_coord = '(F9.5)'
   fmt_flux =  '(F7.2)'
   fmt_flux2 =  '(F8.3)'
   if nid2 ge 0 then begin
      for i = 0, nid2 do $      ; Mistake corrected that was suppressing the first source (Oct 14, 2020)
         listout[i+1] = string(psou[i].id,'(I4)')+', ' + string(psou[i].ra,form=fmt_coord)+', ' + string(psou[i].dec,form=fmt_coord)+', '+$
         psou[i].ras+ ', '+ psou[i].decs+ ', '+  $
         string( psou[i].fl1, form=fmt_flux) + ', ' + string( psou[i].efl1, form=fmt_flux)+', '+ $
         string( psou[i].snr1, form = '(1F6.1)')+ ', ' + $
         string( psou[i].fl2, form=fmt_flux2) + ', ' + string( psou[i].efl2, form=fmt_flux2)+', '+ $
         string( psou[i].snr2, form = '(1F6.1)')
   endif
   write_file, catall, listout, /del
endif

if keyword_set( catall) and keyword_set( ra1) then begin
   nid = ncat
   if nid ne 0 then begin
      psou = replicate({id:-1, ra:0D0, dec:0D0, ras:'', decs:'', fl1:0D0, efl1:0D0, snr1:0D0, fl2:0D0, efl2:0D0, snr2:0D0}, nid)
      psou.id = indgen( nid)
      psou.ra = ra_in
      psou.dec = dec_in
      for i = 0, nid-1 do begin
         myra  = sixty( ra_in[i]/15.)
         mydec = sixty( dec_in[i])
         ras = string(myra[0],form='(I2.2)')+":"+string(myra[1],form='(I2.2)')+":"+zeropadd(strtrim(string(myra[2],form='(F4.1)'),2), 4)
         sign = '+'
         if  dec_in[i] lt 0 then sign = '-'
         decs = sign+string(abs(mydec[0]),form='(I2.2)')+":"+string(abs(mydec[1]),form='(I2.2)')+":"+zeropadd(string(abs(mydec[2]),form='(F4.1)'), 4)   
         psou[i].ras = ras
         psou[i].decs = decs
      endfor
      
      psou.fl1 = fl1mm
      psou.efl1 = efl1mm
      psou.snr1 = fl1mm/efl1mm
      psou.fl2 = fl2mm
      psou.efl2 = efl2mm
      psou.snr2 = fl2mm/efl2mm
      psou = psou[ multisort( psou.ra, psou.dec)]
      listout = strarr(nid +1)
      listout[0] = $
         '   #,   ra(deg),  dec(deg),         ra,         dec,     fl1,    efl1,   snr1,      fl2,     efl2,   snr2'
      fmt_coord = '(F9.5)'
      fmt_flux =  '(F7.2)'
      fmt_flux2 =  '(F8.3)'
      for i = 0, nid-1 do $
         listout[i+1] = string(psou[i].id,'(I4)')+', ' + string(psou[i].ra,form=fmt_coord)+', ' + string(psou[i].dec,form=fmt_coord)+', '+$
         psou[i].ras+ ', '+ psou[i].decs+ ', '+  $
         string( psou[i].fl1, form=fmt_flux) + ', ' + string( psou[i].efl1, form=fmt_flux)+', '+ $
         string( psou[i].snr1, form = '(1F6.1)')+ ', ' + $
         string( psou[i].fl2, form=fmt_flux2) + ', ' + string( psou[i].efl2, form=fmt_flux2)+', '+ $
         string( psou[i].snr2, form = '(1F6.1)')
      write_file, catall, listout, /del            
   endif
   
endif 

if keyword_set( catmerge) and defined( psou) then begin
   nid = n_elements( psou)
                                ; Make a merged catalog where a 2mm
                                ; source too close to a 1mm source is
                                ; deleted from the initial fusion psou
                                ; catalog
   keepsou = bytarr(nid)+1
                                ; Loop on 2mm items
   wh2 = where( psou.efl1 le 0., nwh2)
   wh1 = where( psou.efl2 le 0., nwh1)
   ad2xy, psou.ra, psou.dec, astr, xx, yy
   if nwh1 ne 0 then begin
      for iwh2 = 0, nwh2-1 do begin
                                ; search for nearby 1mm source
         di = pixsize*sqrt((xx[ wh2[ iwh2]] - xx[ wh1])^2+(yy[ wh2[ iwh2]] - yy[ wh1])^2)
         if min(di) lt fwhm[1]/2. then keepsou[ wh2[ iwh2]] = 0B  ; Test if the 2 mm is closed by half a FWHM_2mm to a 1mm source
      endfor
   endif
   whk = where( keepsou, nwhk)
   listout = strarr(nwhk +1)
   listout[0] = $
         '   #,   ra(deg),  dec(deg),         ra,         dec,     fl1,    efl1,   snr1,      fl2,     efl2,   snr2'
   if nwhk gt 0 then begin
      psm = psou[ whk]
      fmt_coord = '(F9.5)'
      fmt_flux =  '(F7.2)'
      fmt_flux2 =  '(F8.3)'
      for i = 0, nwhk-1 do $
         listout[i+1] = string(psm[i].id,'(I4)')+', ' + string(psm[i].ra,form=fmt_coord)+', ' + string(psm[i].dec,form=fmt_coord)+', '+$
         psm[i].ras+ ', '+ psm[i].decs+ ', '+  $
         string( psm[i].fl1, form=fmt_flux) + ', ' + string( psm[i].efl1, form=fmt_flux)+', '+ $
         string( psm[i].snr1, form = '(1F6.1)')+ ', ' + $
         string( psm[i].fl2, form=fmt_flux2) + ', ' + string( psm[i].efl2, form=fmt_flux2)+', '+ $
         string( psm[i].snr2, form = '(1F6.1)')
   endif
   write_file, catmerge, listout, /del            
endif

exit:
end
