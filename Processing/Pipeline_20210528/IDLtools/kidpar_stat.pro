
pro kidpar_stat, kidpar_file, kidpar, ps=ps, png=png, planet=planet, plot_dir = plot_dir

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "kidpar_stat, kidpar_file, kidpar, ps=ps, png=png, planet=planet, plot_dir = plot_dir"
   return
endif
   
if not keyword_set(planet) then planet = 'UranusTBC'
if not keyword_set(plot_dir) then begin
   plot_dir = '.'
endif else begin
   spawn, "mkdir -p "+plot_dir
endelse

kidpar = mrdfits( kidpar_file, 1)

loadct, 39
!p.background = 255
!p.color = 0
;;-------------------------------------------
;;------- Pictures of the focal planes ------
;;--------------------------------------------
for iarray = 1, 3 do begin
   w1 = where( kidpar.type eq 1 and kidpar.array eq iarray and kidpar.plot_flag eq 0, nw1, compl=unvalid_kids)

   if nw1 ne 0 then begin
      xcenter_plot = avg( kidpar[w1].nas_x)
      ycenter_plot = avg( kidpar[w1].nas_y)

      delta_x_plot = max( abs(kidpar[w1].nas_x-xcenter_plot))
      delta_y_plot = max( abs(kidpar[w1].nas_y-ycenter_plot))
      delta_x_plot = max( [delta_x_plot, delta_y_plot])
      delta_y_plot = delta_x_plot
      xra_plot     = xcenter_plot + [-1,1]*delta_x_plot*1.2
      yra_plot     = ycenter_plot + [-1,1]*delta_x_plot*1.2

      phi = dindgen(100)/100.*2*!dpi
      cosphi = cos(phi)
      sinphi = sin(phi)

      ;; display diameter = sigma => beam_scale=0.5
      beam_scale = 0.5

      ;; crosses size
      small = 1

      !p.position=0
      !p.multi=0
      if keyword_set(png) or keyword_set(ps) then matrix_plot_png = 1
      field = ['sensitivity_decorr', 'noise', 'a_peak_nasmyth']
      title = ['Sensitivity', 'Noise', 'Amplitude']
      units = ['mJy.s!u1/2!n/Beam', 'Hz', 'Hz']
      tags = tag_names(kidpar)
      for j=0, n_elements(field)-1 do begin
         if not keyword_set(ps) or keyword_set(matrix_plot_png) then wind, 1, 1, /large, /free
         wtag = where( strupcase(tags) eq strupcase(field[j]))
         med = median( kidpar[w1].(wtag))
         zrange = med +[-2, 2]*stddev( kidpar[w1].(wtag))
         zrange = zrange > 0.d0
         outplot, file = plot_dir+'/FP_A'+strtrim(iarray, 2)+"_"+title[j], png = matrix_plot_png
         matrix_plot, [kidpar[w1].nas_x], [kidpar[w1].nas_y], [kidpar[w1].(wtag)], $
                      units=units[j], xra=xra_plot, yra=yra_plot, /iso, $
                      outcolor=outcolor, xtitle='Nasmyth offset x [Arcsec]', ytitle='Nasmyth offset [Arcsec]', $
                      zrange=zrange, small = small, $
                      chars=1.3, nobar=nobar, psym = 1, title=title[j]
         for i=0, n_elements(w1)-1 do begin
            ikid = w1[i]
            xx1 = beam_scale*kidpar[ikid].sigma_x*cosphi
            yy1 = beam_scale*kidpar[ikid].sigma_y*sinphi
            x1  =  cos(kidpar[ikid].theta)*xx1 - sin(kidpar[ikid].theta)*yy1
            y1  =  sin(kidpar[ikid].theta)*xx1 + cos(kidpar[ikid].theta)*yy1
            oplot, [kidpar[ikid].nas_x+x1], [kidpar[ikid].nas_y+y1], col=outcolor[i] ; thick=2
         endfor
         legendastro, [strtrim(file_basename(kidpar_file),2), $
                       'Array '+strtrim(iarray, 2), $
                       string( kidpar[w1[0]].lambda, format='(F4.2)')+" mm"], box = 0
         legendastro, ['Valid kids '+strtrim(nw1, 2), $
                       'Median '+title[j]+' per kid: '+num2string(med)], box = 0, /right
         outplot, /close
      endfor

      ;;--------------------------------
      ;; Electronic boxes
      outplot, file=plot_dir+'/FP_A'+strtrim(iarray, 2)+"_Eboxes", png = matrix_plot_png
      matrix_plot, [kidpar[w1].nas_x], [kidpar[w1].nas_y], [kidpar[w1].acqbox], $
                   units='E-Box', xra=xra_plot, yra=yra_plot, /iso, $
                   outcolor=outcolor, xtitle='Nasmyth offset x [Arcsec]', ytitle='Nasmyth offset [Arcsec]', $
                   zrange=minmax(kidpar.acqbox), small = small, $
                   chars=1.3
      legendastro, [strtrim(file_basename(kidpar_file),2), $
                    'Array '+strtrim(iarray, 2), $
                    string( kidpar[w1[0]].lambda, format='(F4.2)')+" mm"], box = 0
      outplot, /close


      ;; -------------------------------
      ;; beam centroids and numdet

      ;; Global plot (we can zoom on the .ps)
      outplot, file=plot_dir+'/FP_offsets_A'+strtrim(iarray, 2), png = png, ps = ps
      plot, kidpar[w1].nas_x, kidpar[w1].nas_y, psym=1, syms=0.2, /iso, $
            xra=xra_plot, yra=yra_plot, /xs, /ys, $
            xtitle='Nasmyth offset x [Arcsec]', ytitle='Nasmyth offset [Arcsec]', thick=2
      xyouts, kidpar[w1].nas_x, kidpar[w1].nas_y, strtrim(kidpar[w1].numdet,2), chars=0.2, col=250
      legendastro, [strtrim(file_basename(kidpar_file),2), $
                    'Array '+strtrim(iarray, 2), $
                    string( kidpar[w1[0]].lambda, format='(F4.2)')+" mm"], box = 0
      outplot, /close

      ;; Plot by sector to have offsets info available too
      xstart = [-250, -150, -50,  50, 150]
      xend   = [-150,  -50,  50, 150, 250]
      ystart = [-150, -50,  50, 150]
      yend   = [ -50,  50, 150, 250]
      for i=0, n_elements(xstart)-1 do begin
         xra_plot = [xstart[i], xend[i]]
         for j=0, n_elements(ystart)-1 do begin
            yra_plot = [ystart[j], yend[j]]
            
            w2 = where( kidpar.type eq 1 and kidpar.array eq iarray and kidpar.plot_flag eq 0 and $
                        kidpar.nas_x ge xra_plot[0] and kidpar.nas_x le xra_plot[1] and $
                        kidpar.nas_y ge yra_plot[0] and kidpar.nas_y le yra_plot[1], nw2)

            if nw2 ne 0 then begin
               outplot, file=plot_dir+'/FP_offsets_A'+strtrim(iarray, 2)+"_zoom_"+$
                        strtrim(xra_plot[0],2)+"_"+strtrim(xra_plot[1],2)+"_"+$
                        strtrim(yra_plot[0],2)+"_"+strtrim(yra_plot[1],2), png = png, ps = ps
               plot, [kidpar[w2].nas_x], [kidpar[w2].nas_y], psym=1, syms=0.5, /iso, $
                     xra=xra_plot, yra=yra_plot+[-30,0], /xs, /ys, $
                     xtitle='Nasmyth offset x [Arcsec]', ytitle='Nasmyth offset [Arcsec]', $
                     title='Array '+strtrim(iarray,2)
               draw0
               xyouts, kidpar[w2].nas_x, kidpar[w2].nas_y+1, strtrim(kidpar[w2].numdet,2), chars=0.3, col=250
               fmt='(F6.1)'
               xyouts, kidpar[w2].nas_x, kidpar[w2].nas_y-1., $
                       strtrim(string(kidpar[w2].nas_x, format=fmt),2)+", "+$
                       strtrim(string(kidpar[w2].nas_y,format=fmt),2), $
                       col=70, chars=0.3

               plot, kidpar[w1].nas_x, kidpar[w1].nas_y, psym=3, /iso, $
                     xra=[-1,1]*250, yra=[-1,1]*250, /xs, /ys, $
                     position=[0.1, 0.1, 0.2, 0.2], /noerase, xchars=1e-10, ychars=1e-10
               draw0
               plots, [xra_plot[0], xra_plot[0], xra_plot[1], xra_plot[1], xra_plot[0]], $
                      [yra_plot[0], yra_plot[1], yra_plot[1], yra_plot[0], yra_plot[0]], col=250
               outplot, /close

            endif
         endfor
      endfor
      
   endif
endfor


;; Superpose all arrays and zoom around the center
init_plot=0
ct = [70, 150, 250]
xra = [-1,1]*80
yra = [-1,1]*80
outplot, file=plot_dir+'/FP_all_center', ps=ps, png=png
for iarray = 1, 3 do begin
   w = where( kidpar.array eq iarray and kidpar.type eq 1 and $
              kidpar.nas_x ge xra[0] and kidpar.nas_x le xra[1] and $
              kidpar.nas_y ge yra[0] and kidpar.nas_y le yra[1], nw)
   if nw gt 2 then begin
      if init_plot eq 0 then begin
         plot, kidpar[w].nas_x, kidpar[w].nas_y, psym=1, /iso, $
               syms=0.5, xtitle='Nasmyth x', ytitle='Nasmyth y', title = 'A'+strtrim(iarray, 2), $
               xra = xra, yra = yra, /nodata
         init_plot=1
      endif
      oplot, kidpar[w].nas_x, kidpar[w].nas_y, col=ct[iarray-1], psym=1, syms=0.1
      xyouts, kidpar[w].nas_x, kidpar[w].nas_y, strtrim(kidpar[w].numdet,2), chars=0.3, col=ct[iarray-1]
   endif
   oplot, [0,0], [-1,1]*1e10
   oplot, [-1,1]*1e10, [0,0]
endfor
outplot, /close

;;---------------------------------------------
;;------- Histograms of kid properties --------
;;---------------------------------------------


if not keyword_set(ps) then wind, 1, 1, /free, /large

for iarray=1, 3 do begin
   w  = where( kidpar.array eq iarray, nw)
   w1 = where( kidpar.array eq iarray and kidpar.type eq 1 and kidpar.plot_flag eq 0, nw1)
   print, "Array: "+strtrim(iarray,2)+": N on "+strtrim(nw,2)+", N valid: "+strtrim(nw1,2)
   if nw1 ne 0 then begin
      outplot, file=plot_dir+'/fwhm_A'+strtrim(iarray,2), png=png, ps=ps
      np_histo, kidpar[w1].fwhm, /fill, fcol=70, title='Array '+strtrim(iarray,2)+" / FWHM", xtitle='Arcsec'
      legendastro, 'Median: '+num2string( median(kidpar[w1].fwhm)), box=0
      outplot, /close

      outplot, file=plot_dir+'/Sensitivity_A'+strtrim(iarray,2), png=png, ps=ps
      np_histo, kidpar[w1].sensitivity_decorr, /fill, fcol=70, title='Array '+strtrim(iarray,2)+" / Sensitivity", $
                xtitle='mJy.s!u1/2!n/Beam'
      legendastro, 'Median: '+num2string( median(kidpar[w1].sensitivity_decorr)), box=0
      outplot, /close
      
      outplot, file=plot_dir+'/Noise_above_4Hz_A'+strtrim(iarray,2), png=png, ps=ps
      np_histo, kidpar[w1].noise, /fill, fcol=70, title='Array '+strtrim(iarray,2)+" / Noise above 4Hz", xtitle='Hz/Hz!u-1/2!n'
      legendastro, 'Median: '+num2string( median(kidpar[w1].noise)), box=0
      outplot, /close

      outplot, file=plot_dir+'/Noise_1Hz_A'+strtrim(iarray,2), png=png, ps=ps
      np_histo, kidpar[w1].noise_1hz, /fill, fcol=70, title='Array '+strtrim(iarray,2)+" / Noise around 1Hz", xtitle='Hz/Hz!u-1/2!n'
      legendastro, 'Median: '+num2string( median(kidpar[w1].noise_1hz)), box=0
      outplot, /close

      outplot, file=plot_dir+'/Noise_2Hz_A'+strtrim(iarray,2), png=png, ps=ps
      np_histo, kidpar[w1].noise_2hz, /fill, fcol=70, title='Array '+strtrim(iarray,2)+" / Noise around 2Hz", xtitle='Hz/Hz!u-1/2!n'
      legendastro, 'Median: '+num2string( median(kidpar[w1].noise_2hz)), box=0
      outplot, /close

      outplot, file=plot_dir+'/Noise_10Hz_A'+strtrim(iarray,2), png=png, ps=ps
      np_histo, kidpar[w1].noise_10hz, /fill, fcol=70, title='Array '+strtrim(iarray,2)+" / Noise around 10Hz", xtitle='Hz/Hz!u-1/2!n'
      legendastro, 'Median: '+num2string( median(kidpar[w1].noise_10hz)), box=0
      outplot, /close

      outplot, file=plot_dir+'/'+planet+'_amplitude_A'+strtrim(iarray,2), png=png, ps=ps
      np_histo, kidpar[w1].a_peak_nasmyth, /fill, fcol=70, title='Array '+strtrim(iarray,2)+" / "+planet+" Amplitude", xtitle='Hz'
      legendastro, 'Median: '+num2string( median(kidpar[w1].a_peak_nasmyth)), box=0
      outplot, /close

      outplot, file=plot_dir+'/'+planet+'_SignalToNoise_A'+strtrim(iarray,2), png=png, ps=ps
      np_histo, kidpar[w1].a_peak_nasmyth/kidpar[w1].noise, /fill, fcol=70, $
                title='Array '+strtrim(iarray,2)+" / "+planet+" S/N", xtitle=''
      legendastro, 'Median: '+num2string( median(kidpar[w1].a_peak_nasmyth/kidpar[w1].noise)), box=0
      outplot, /close
   endif
endfor

end
