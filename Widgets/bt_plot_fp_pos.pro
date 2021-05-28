pro bt_plot_fp_pos

common bt_maps_common

w1    = where( kidpar.type eq 1, nw1, compl=unvalid_kids)
w3    = where( kidpar.type eq 3, nw3)
w5    = where( kidpar.type eq 5, nw5)
if nw5 ne 0 then kidpar[w5].plot_flag = 1
wplot = where( kidpar.plot_flag eq 0, nwplot)

xcenter_plot = avg( kidpar[wplot].nas_x)
ycenter_plot = avg( kidpar[wplot].nas_y)
xra_plot = xcenter_plot + [-1,1]*max( abs(kidpar[wplot].nas_x-xcenter_plot))*1.2
yra_plot = ycenter_plot + [-1,1]*max( abs(kidpar[wplot].nas_y-ycenter_plot))*1.2

;; add space for legend box
yra_plot = yra_plot + [0, (max(yra_plot)-min(yra_plot))*0.2]

get_x0y0, kidpar[wplot].nas_x, kidpar[wplot].nas_y, xc0, yc0, ww
ibol_ref = wplot[ww]

phi = dindgen(100)/100.*2*!dpi
cosphi = cos(phi)
sinphi = sin(phi)
wind, 3, 1, /large
!p.position=0
!p.multi=0
outplot, file=sys_info.plot_dir+"/"+sys_info.nickname+"_FocalPlane", png=sys_info.png, ps=sys_info.ps

plot, [kidpar[wplot].nas_x], [kidpar[wplot].nas_y], psym=1, /iso, xtitle='mm', ytitle='mm', $
      title=sys_info.nickname, xra=xra_plot, yra=yra_plot, /xs, /ys
oplot, [xc0], [yc0], psym=4, col=200

;; matrix plot to get outcolor
zrange = avg( kidpar[wplot].sensitivity_decorr) +[-3,3]*stddev( kidpar[wplot].sensitivity_decorr)

matrix_plot, [kidpar[wplot].nas_x], [kidpar[wplot].nas_y], [kidpar[wplot].sensitivity_decorr], $
             units='mK/sqrt(Hz)', xra=xra_plot, yra=yra_plot, /xs, /ys, /iso, $
             outcolor=outcolor, xtitle='Arcsec', ytitle='Arcsec', zrange=zrange, my_simsize=0.1, $
             title=sys_info.nickname, chars=1.3


;;beam_scale = 0.5 * 0.5/!fwhm2sigma ; 0.2/fwhm pour l'avoir en FWHM, 0.5 pour le Rayon et pas le diametre

;;**********
;;**********
;;outcolor = outcolor*0.d0
;;**********
;;**********

for i=0, n_elements(wplot)-1 do begin
   ikid = wplot[i]
   xx1 = disp.beam_scale*kidpar[ikid].sigma_x*cosphi
   yy1 = disp.beam_scale*kidpar[ikid].sigma_y*sinphi
   ;; before FP rotation
   x1 =  cos(kidpar[ikid].theta)*xx1 - sin(kidpar[ikid].theta)*yy1
   y1 =  sin(kidpar[ikid].theta)*xx1 + cos(kidpar[ikid].theta)*yy1

   ;polyfill, nas_xs_1[ikid] + x1, nas_ys_1[ikid] + y1, col=outcolor[i]
   oplot, [kidpar[ikid].nas_x+x1], [kidpar[ikid].nas_y+y1], col=outcolor[i] ; thick=2
endfor

if nw3 ne 0 then oplot, [kidpar[w3].nas_x], [kidpar[w3].nas_y], psym=1, col=250

;;stop
xoffset = kidpar[wplot].sigma_x/2./2.
yoffset = kidpar[wplot].sigma_y/2./3.
;xyouts, col=!p.color, kidpar[wplot].nas_x-xoffset, kidpar[wplot].nas_y+yoffset,   strtrim(kidpar[wplot].name,2)
;xyouts, col=!p.color, kidpar[wplot].nas_x-xoffset, kidpar[wplot].nas_y-yoffset, "s= "+strtrim(string( kidpar[wplot].sensitivity_decorr,format="(F5.2)"),2)
;xyouts, col=!p.color, kidpar[wplot].nas_x-xoffset, kidpar[wplot].nas_y-3*yoffset, "N="+strtrim(string( kidpar[wplot].noise,format="(F5.2)"),2)


sys_info.avg_noise   = avg( kidpar[wplot].noise)
sys_info.sigma_noise = stddev( kidpar[wplot].noise)
sys_info.avg_sensitivity_decorr   = avg(    kidpar[wplot].sensitivity_decorr)
sys_info.sigma_sensitivity_decorr = stddev( kidpar[wplot].sensitivity_decorr)

legendastro, [sys_info.ext, $
              'Approx center kid = '+strtrim( kidpar[ibol_ref].numdet,2), $
              'xc0 = '+strtrim(xc0,2), $
              'yc0 = '+strtrim(yc0,2), $
              "", $
              "T!dplanet!n = "+string( sys_info.t_planet, format='(F4.2)')+" K!dRJ!n", $
              ;'Response: '+string(sys_info.avg_response,format="(F5.2)")+' +- '+string(sys_info.sigma_response,format="(F4.2)")+" mK/Hz", $
              'Noise: '+string(sys_info.avg_noise,format="(F5.2)")+' +- '+string(sys_info.sigma_noise,format="(F4.2)")+" Hz/Hz!u1/2!n", $
              'Sensitivity: '+string( sys_info.avg_sensitivity_decorr, format="(F5.2)")+' +- '+$
              string( sys_info.sigma_sensitivity_decorr,format="(F5.2)")+" mK/Hz!u1/2!n"], $
             chars=1.5
legendastro, [sys_info.ext, $
              'Nvalid='+strtrim(nw1,2), $
              'Beam display diameter: 0.5 FWHM'], /right, chars=1.5

outplot, /close
loadct, 39

;;--------------------------------------------------------
;; Display comments if any

;; Get top right corner position
xxc = max(xra_plot)
yyc = max(yra_plot)

rr = convert_coord( xxc, yyc, /to_device)
xmargin = !d.x_size-rr[0]

if file_search(sys_info.comments_file) ne "" then begin
   read_txt_file, sys_info.comments_file, out_comments

   !p.position = [(rr[0]+xmargin*0.1)/!d.x_size, 0, $
                  (rr[0]+xmargin*0.9)/!d.x_size, rr[1]/!d.y_size]
   plot, [0,1],[0,1],/noerase, /nodata, xs=4, ys=4
   legendastro, out_comments, box=0, chars=1.5, /right
   !p.position = fltarr(4)
endif



end
