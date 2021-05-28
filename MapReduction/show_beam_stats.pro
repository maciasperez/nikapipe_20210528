
pro show_beam_stats

common ql_maps_common

wind, 1, 1, /free, ys=900
outplot, file=nickname+'_beam_histos', png=png, ps=ps
!p.multi=[0,1,3]
w = where( kidpar.type eq 1, nw)
fwhm = sqrt( sigma_x_1*sigma_y_1)/!fwhm2sigma
if total(finite(fwhm[w])) ne nw then begin
   ww = where( finite(fwhm) ne 1 and (kidpar.type eq 1 or kidpar.type eq 3))
   print, "Infinite fwhm for kids: ", ww
   stop
endif else begin
   n_histwork, fwhm[w], bin=stddev( fwhm[w])/3.d0, /fit, xhist, yhist, gpar_fwhm, charsize=1.3, /fill
   legendastro, [box+strtrim(lambda,2)+'mm', $
                 'FWHM (mm)', 'Nvalid='+strtrim(nw1,2)], chars=1.5, box=0
endelse

ellipt = fwhm*0.
ellipt[w] = sigma_x_1[w]/sigma_y_1[w]
n_histwork, ellipt[w], bin=stddev(ellipt[w])/3., /fit, xhist, yhist, gpar_ellipt, charsize=1.3, /fill
legendastro, [box+strtrim(lambda,2)+'mm', $
              'Ellipt=FWHM!dx!n/FWHM!dy!n', 'Nvalid='+strtrim(nw1,2)], box=0, chars=1.5

n_histwork, a_peaks_1[w], xhist, yhist, gpar_ampl, bin=stddev(a_peaks_1[w])/3., title='Peak Amplitude (Hz)', /fit, charsize=1.3, /fill
legendastro, [box+strtrim(lambda,2)+'mm', $
              'Nvalid='+strtrim(nw1,2)], chars=1.5, box=0
!p.multi=0
outplot, /close


end
