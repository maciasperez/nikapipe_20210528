
pro plot_fp_pos

common ql_maps_common

xcenter_plot = avg( x_peaks_1[wplot])
ycenter_plot = avg( y_peaks_1[wplot])
xra_plot = xcenter_plot + [-1,1]*max( abs(x_peaks_1[wplot]-xcenter_plot))*1.2
yra_plot = ycenter_plot + [-1,1]*max( abs(y_peaks_1[wplot]-ycenter_plot))*1.2

get_x0y0, x_peaks_1[wplot], y_peaks_1[wplot], xc0, yc0, ww
ibol_ref = wplot[ww]

phi = dindgen(100)/100.*2*!dpi
cosphi = cos(phi)
sinphi = sin(phi)
wind, 3, 1, /large
!p.position=0
!p.multi=0
outplot, file=plot_dir+"/"+nickname+"_FocalPlane", png=png, ps=ps

plot, x_peaks_1[wplot], y_peaks_1[wplot], psym=1, /iso, xtitle='mm', ytitle='mm', $
      title=nickname, xra=xra_plot, yra=yra_plot
oplot, [xc0], [yc0], psym=4, col=200

;; matrix plot to get outcolor
zrange = avg_noise_estim_decorr+[-3,3]*std_noise_estim_decorr

matrix_plot, x_peaks_1[wplot], y_peaks_1[wplot], noise_estim_decorr[wplot], $
             units='mK/sqrt(Hz)', xra=xra_plot, yra=yra_plot, /xs, /ys, /iso, $
             outcolor=outcolor, xtitle='mm', ytitle='mm', zrange=zrange, my_simsize=0.1, $
             title=nickname, chars=1.3


beam_scale = 0.5 * 0.5/!fwhm2sigma ; 0.2/fwhm pour l'avoir en FWHM, 0.5 pour le Rayon et pas le diametre

;; for i=0, n_elements(wplot)-1 do begin
;;    ikid = wplot[i]
;;    xx1 = beam_scale*sigma_x_1[ikid]*cosphi
;;    yy1 = beam_scale*sigma_y_1[ikid]*sinphi
;;    ;; before FP rotation
;;    x1 =  cos(theta_1[ikid])*xx1 - sin(theta_1[ikid])*yy1
;;    y1 =  sin(theta_1[ikid])*xx1 + cos(theta_1[ikid])*yy1
;;    oplot, x_peaks_1[ikid]+x1, y_peaks_1[ikid]+y1, col=250
;; endfor

for i=0, n_elements(wplot)-1 do begin
   ikid = wplot[i]
   xx1 = beam_scale*sigma_x_1[ikid]*cosphi
   yy1 = beam_scale*sigma_y_1[ikid]*sinphi
   ;; before FP rotation                                                                                                                                                    
   x1 =  cos(theta_1[ikid])*xx1 - sin(theta_1[ikid])*yy1
   y1 =  sin(theta_1[ikid])*xx1 + cos(theta_1[ikid])*yy1

   ;polyfill, x_peaks_1[ikid] + x1, y_peaks_1[ikid] + y1, col=outcolor[i]
   oplot, x_peaks_1[ikid]+x1, y_peaks_1[ikid]+y1, col=outcolor[i] ; thick=2
endfor

if nw3 ne 0 then oplot, x_peaks_1[w3], y_peaks_1[w3], psym=1, col=250
;;xyouts, x_peaks_1[wplot]+1, y_peaks_1[wplot]+1, strtrim(kidpar[wplot].numdet,2), chars=1.2

xyouts, x_peaks_1[wplot]-5, y_peaks_1[wplot], strtrim(kidpar[wplot].name,2);, chars=1.4
xyouts, x_peaks_1[wplot]-5, y_peaks_1[wplot]-3, string( noise_estim_decorr[wplot],format="(F5.2)");, chars=1.4

legendastro, [box+strtrim(lambda,2)+'mm', $
              'Approx center kid = '+strtrim( kidpar[ibol_ref].numdet,2), $
              'xc0 = '+strtrim(xc0,2), $
              'yc0 = '+strtrim(yc0,2), $
              "", $
              'Response: '+string(avg_response,format="(F5.2)")+' +- '+string(std_response,format="(F4.2)"), $
              'Raw noise (5Hz) '+string( avg_noise_estim_5hz_nodecorr, format="(F5.2)")+' +- '+string(std_noise_estim_5hz_nodecorr,format="(F4.2)"), $
              'Decorr noise (all freq) '+string( avg_noise_estim_decorr, format="(F5.2)")+' +- '+string(std_noise_estim_decorr,format="(F4.2)")], $
             chars=1.5
legendastro, [box+strtrim(lambda,2)+'mm', $
              'Nvalid='+strtrim(nw1,2), $
              'Beam scale: 0.5 FWHM'], /right, chars=1.5

outplot, /close
loadct, 39

;;--------------------------------------------------------
;; Display comments if any

;; Get top right corner position
xxc = max(xra_plot)
yyc = max(yra_plot)

rr = convert_coord( xxc, yyc, /to_device)
xmargin = !d.x_size-rr[0]

read_txt_file, out_comments_file, out_comments

!p.position = [(rr[0]+xmargin*0.1)/!d.x_size, 0, $
               (rr[0]+xmargin*0.9)/!d.x_size, rr[1]/!d.y_size]
plot, [0,1],[0,1],/noerase, /nodata, xs=4, ys=4
legendastro, out_comments, box=0, chars=1.5, /right
!p.position = fltarr(4)


;; Display power spectra
wind, 2, 2, /free, /large
outplot, file=plot_dir+"/"+nickname+"_PowSpec", png=png, ps=ps

my_list = [0, 20, 40, 82]
!p.multi=[0,2,2]
for i=0, n_elements(my_list)-1 do begin
   w = where( kidpar[w1].name eq "KA"+string(my_list[i],format="(I3.3)"), nw)
   print, ""
   print, i, nw
   if nw ne 0 then begin
      plot_oo, freq, pw_nodecorr[w1[w],*], xra=minmax(freq), /xs, ytitle='Hz/sqrt(Hz)'
      oplot, freq, pw_decorr[w1[w],*], col=250
      legendastro, [kidpar[w1[w]].name, $
                    'No Decorrelation', $
                    'Decorrelation'], $
                   textcol = [!p.color, !p.color, 250], $
                   col=[!p.color, !p.color, 250], line=0, box=0, chars=1.5
   endif
endfor
!p.multi=0
outplot, /close

end
