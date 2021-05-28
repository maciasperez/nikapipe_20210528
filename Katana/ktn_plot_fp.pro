pro ktn_plot_fp

common ktn_common

w1    = where( kidpar.type eq 1, nw1, compl=unvalid_kids)
w3    = where( kidpar.type eq 3, nw3)
w5    = where( kidpar.type eq 5, nw5)
if nw5 ne 0 then kidpar[w5].plot_flag = 1
wplot = where( kidpar.plot_flag eq 0, nwplot)

xcenter_plot = avg( kidpar[wplot].nas_x)
ycenter_plot = avg( kidpar[wplot].nas_y)
;xra_plot     = xcenter_plot + [-1,1]*max( abs(kidpar[wplot].nas_x-xcenter_plot))*1.2
;yra_plot     = ycenter_plot + [-1,1]*max( abs(kidpar[wplot].nas_y-ycenter_plot))*1.2
;yra_plot     = yra_plot + [0, (max(yra_plot)-min(yra_plot))*0.2]

delta_x_plot = max( abs(kidpar[wplot].nas_x-xcenter_plot))
delta_y_plot = max( abs(kidpar[wplot].nas_y-ycenter_plot))
delta_x_plot = max( [delta_x_plot, delta_y_plot])
delta_y_plot = delta_x_plot
xra_plot     = xcenter_plot + [-1,1]*delta_x_plot*1.2
yra_plot     = ycenter_plot + [-1,1]*delta_x_plot*1.2

get_x0y0, kidpar[wplot].nas_x, kidpar[wplot].nas_y, xc0, yc0, ww
ibol_ref = wplot[ww]

;; Plot
phi = dindgen(100)/100.*2*!dpi
cosphi = cos(phi)
sinphi = sin(phi)
zrange = avg( kidpar[wplot].sensitivity_decorr) +[-3,3]*stddev( kidpar[wplot].sensitivity_decorr)
zrange = zrange > 0.d0


;;-----------------------
;; One color per feedline
incolor = fltarr(n_elements(wplot))
nobar=1
nbox = max(kidpar.acqbox)-min(kidpar.acqbox)+1
boxlist = indgen(nbox)+min(kidpar.acqbox)
make_ct, nbox, ct
for i=0, nbox-1 do begin
   w = where(kidpar[wplot].acqbox eq boxlist[i], nw)
   if nw ne 0 then incolor[w]=ct[i]
endfor
;;-----------------------

wind, 3, 1, /large
!p.position=0
!p.multi=0
outplot, file=sys_info.plot_dir+"/"+sys_info.nickname+"_FocalPlane", png=sys_info.png, ps=sys_info.ps
matrix_plot, [kidpar[wplot].nas_x], [kidpar[wplot].nas_y], [kidpar[wplot].sensitivity_decorr], $
             units='mJy.s!u1/2!n/Beam', xra=xra_plot, yra=yra_plot, $
             outcolor=outcolor, xtitle='Arcsec', ytitle='Arcsec', zrange=zrange, /small, $
             title=sys_info.nickname, chars=1.3, incolor=incolor, nobar=nobar
for i=0, n_elements(wplot)-1 do begin
   ikid = wplot[i]
   xx1 = disp.beam_scale*kidpar[ikid].sigma_x*cosphi
   yy1 = disp.beam_scale*kidpar[ikid].sigma_y*sinphi
   x1  =  cos(kidpar[ikid].theta)*xx1 - sin(kidpar[ikid].theta)*yy1
   y1  =  sin(kidpar[ikid].theta)*xx1 + cos(kidpar[ikid].theta)*yy1
   oplot, [kidpar[ikid].nas_x+x1], [kidpar[ikid].nas_y+y1], col=outcolor[i] ; thick=2
endfor
legendastro, ['Approx center kid = '+strtrim( kidpar[ibol_ref].numdet,2), $
              'xc0 = '+strtrim(xc0,2), $
              'yc0 = '+strtrim(yc0,2), $
              "", $
              'Kid Noise (median, not corrected for tau): '+$
              string(sys_info.avg_noise,format="(F5.2)")+' +- '+$
              string(sys_info.sigma_noise,format="(F4.2)")+" Hz/Hz!u1/2!n", $
              'Sensitivity (median, not corrected for tau): '+$
              num2string(sys_info.avg_sensitivity_decorr)+' +- '+$
              num2string(sys_info.sigma_sensitivity_decorr)+" mJy.s!u1/2!n/Beam"], $
             box=0, charsize=1
junk = where(kidpar.plot_flag eq 0, nplot)
legendastro, ['Nvalid='+strtrim(nw1,2), $
              "Ndisplayed="+strtrim(nplot,2), $
              'Beam display diameter: sigma'], /right, box=0, charsize=1

outplot, /close
loadct, 39

;; ;; Redo this plot for the Concerto proposal:
;; my_png = 0 & my_ps  = 0
;; my_ps  = 1 & my_png = 0
;; outplot, file="NIKA2_FP", png=my_png, ps=my_ps, thick=3, charthick=3
;; 
;; plot, [-1,1]*120, [-120,150], /iso, /xs, /ys, /nodata, xtitle='mm', ytitle='mm'
;; for i=0, n_elements(wplot)-1 do begin
;;    ikid = wplot[i]
;;    xx1 = disp.beam_scale*kidpar[ikid].sigma_x*cosphi
;;    yy1 = disp.beam_scale*kidpar[ikid].sigma_y*sinphi
;;    x1  =  cos(kidpar[ikid].theta)*xx1 - sin(kidpar[ikid].theta)*yy1
;;    y1  =  sin(kidpar[ikid].theta)*xx1 + cos(kidpar[ikid].theta)*yy1
;;    oplot, [kidpar[ikid].nas_x+x1], [kidpar[ikid].nas_y+y1], col=70
;; endfor
;; legendastro, ['Beam display diameter: !7r!3'], /right, box=0, charsize=1
;; outplot, /close

;; ;; Display comments if any
;; ;; Get top right corner position
;; xxc = max(xra_plot)
;; yyc = max(yra_plot)
;; 
;; rr = convert_coord( xxc, yyc, /to_device)
;; xmargin = !d.x_size-rr[0]
;; 
;; if file_search(sys_info.comments_file) ne "" then begin
;;    read_txt_file, sys_info.comments_file, out_comments
;; 
;;    !p.position = [(rr[0]+xmargin*0.1)/!d.x_size, 0, $
;;                   (rr[0]+xmargin*0.9)/!d.x_size, rr[1]/!d.y_size]
;;    plot, [0,1],[0,1],/noerase, /nodata, xs=4, ys=4
;;    legendastro, out_comments, box=0, chars=1.5, /right
;;    !p.position = fltarr(4)
;; endif



end
