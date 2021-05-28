

pro pixel_layout, scan_num, day, map_list_out, xmap, ymap, kidpar, nickname, lambda, box, coeff, source_flux, source_flux_units, $
                  output_fits_file=output_fits_file, $
                  png=png, ps=ps, circular=circular, nowarp=nowarp, output_kidpar_fits_file=output_kidpar_fits_file, $
                  el_source=el_source, source=source, delta_out=delta_out, alpha=alpha, $
                  nas_center_x=nas_center_x, nas_center_y=nas_center_y, $ 
                  plot_dir=plot_dir, preview=preview, fit_grid=fit_grid, $
                  nas_x=nas_x, nas_y=nas_y, x_peaks=x_peaks, y_peaks=y_peaks, a_peaks=a_peaks, $
                  raw_x_offset=raw_x_offset, raw_y_offset=raw_y_offset, kidpar_ext=kidpar_ext

if not keyword_set(el_source) then el_source = -1
if not keyword_set(source)    then source = 'None'
if not keyword_set(plot_dir)  then plot_dir = "."

nkids = n_elements( map_list_out[*,0,0])

;; Fit ellipses
beam_guess, map_list_out, xmap, ymap, kidpar, x_peaks, y_peaks, a_peaks, sigma_x, sigma_y, $
            beam_list, theta, rebin=rebin_factor, circular=circular, method='mpfit', /noplot

w1   = where( kidpar.type eq 1, nw1)
w3   = where( kidpar.type eq 3, nw3)
w_on = where( kidpar.type ne 0, nw_on)

;; Keep only valid, combined and non pathological pixels for the plot
fwhm_x   = sigma_x/!fwhm2sigma
fwhm_y   = sigma_y/!fwhm2sigma
fwhm     = sqrt( fwhm_x*fwhm_y)
fwhm_max = 100. ; [arcsec] place holder
w1       = where( kidpar.type eq 1  and $
                  finite(fwhm) eq 1 and $
                  fwhm lt fwhm_max, nw1)
w13      = where( (kidpar.type eq 1 or $
                   kidpar.type eq 3) and $
                  finite(fwhm) eq 1 and $
                  fwhm lt fwhm_max, nw13, compl=w_out, ncompl=nw_out)

;;---------------------------------------------------------------------------
;; FPG in sky coordinates
syms = 2
xra1 = [-1,1]*100
yra1 = [-1,1]*100

xra1 = avg(x_peaks[w13])+[-1,1]*0.6*( max(x_peaks[w13])-min(x_peaks[w13]))
yra1 = avg(y_peaks[w13])+[-1,1.4]*0.6*( max(y_peaks[w13])-min(y_peaks[w13])) ; margin for legend

phi = dindgen(200)/199.*2*!dpi
cosphi = cos(phi)
sinphi = sin(phi)
width = 900
wind, 1, 1, /free, xs=width, ys=width
!p.background = 255
!p.color = 0
plot, x_peaks[w13], y_peaks[w13], psym=3, /iso, title=nickname, xr=xra1, yr=yra1, /xs, /ys, $
      xtitle='Arcsec', ytitle='Arcsec'
legendastro, [strtrim(lambda,2)+" mm", $
         'Source: '+source, $
         'Elevation: '+strtrim(long(el_source),2)+"!uo!n"], $
        /right, chars=2
dx = 1
beam_scale = 0.4
for ikid=0, nkids-1 do begin
   if (kidpar[ikid].type eq 1) or (kidpar[ikid].type eq 3) then begin
      
      if (kidpar[ikid].type eq 1) then !p.color = 0 else !p.color = 250

      xyouts, x_peaks[ikid], y_peaks[ikid], strtrim(kidpar[ikid].numdet,2), chars=1.2, /data
      
      xx1 = beam_scale*fwhm_x[ikid]*cosphi*!fwhm2sigma
      yy1 = beam_scale*fwhm_y[ikid]*sinphi*!fwhm2sigma
      ;; before FP rotation
      x1 =  cos(theta[ikid])*xx1 - sin(theta[ikid])*yy1
      y1 =  sin(theta[ikid])*xx1 + cos(theta[ikid])*yy1
      ;; NO FP rotation
      xx = x1
      yy = y1
      
      oplot, x_peaks[ikid] + xx, y_peaks[ikid] + yy
   endif
endfor
legendastro, [strtrim(lambda,2)+'mm', "", $
              'Valid', 'Combined'], $
             textcol = [!p.color, !p.color, !p.color, 250], chars=2, box=0
outplot, /close, preview=preview

;;-------------------------------------------------------------------------------------------------
;;Beam width summary
a_fwhm = avg( fwhm[w13])
s_fwhm = stddev( fwhm[w13])
e_min  = a_fwhm - 1*s_fwhm
e_max  = a_fwhm + 1*s_fwhm
hist_bin = stddev(fwhm[w1])/3.d0
wind, 1, 1, /free, /large
outplot, file=plot_dir+"/"+nickname+"_fwhm_histo", png=png, ps=ps
n_histwork, fwhm[w1], bin=hist_bin, /fit, xhist1, yhist1, gpar1, title='FWHM / '+nickname, min=0, max=100
if nw3 ne 0 then n_histwork, fwhm[w3], bin=hist_bin, xhist3, yhist3, title='FWHM (mm)', min=0, max=100
plot,  xhist1, yhist1, psym=10, title='FWHM / '+nickname
if nw3 ne 0 then oplot, xhist3, yhist3, psym=10, col=250
xx = dindgen(1000)/999*(max(xhist1)-min(xhist1)) + min(xhist1)
oplot, xx, gpar1[0]*exp( -(xx-gpar1[1])^2/(2.*gpar1[2]^2))
n_gpar1 = n_elements(gpar1)
txt_leg = ['Gaussian Fit:', 'Amp='+string(gpar1(0),format='(f8.3)')]
if n_gpar1 ge 2 then txt_leg = [txt_leg, 'x0='+string(gpar1(1),format='(f8.3)')]
if n_gpar1 ge 3 then txt_leg = [txt_leg, '!4r!3='+string(gpar1(2),format='(f8.3)')]
if n_gpar1 ge 4 then txt_leg = [txt_leg, 'Cst='+string(gpar1(3),format='(f8.3)')]
legendastro, txt_leg, /right, chars=2
;; legendastro, ['Valid', 'Combined'], col=[!p.color, 250], line=0, chars=2
legendastro, [strtrim(lambda,2)+'mm', "", $
              'Valid', 'Combined'], $
             textcol = [!p.color, !p.color, !p.color, 250], chars=2, box=0
outplot, /close, preview=preview

;;;;-------------------------------------------------------------------------------------------------
;;;; Nasmyth to sky transformation
;;if keyword_set(fit_grid) then begin

ix = kidpar.x_pix
iy = kidpar.y_pix

;;   ;; Derive Nasmyth to (co-el, el) transformation
;;   warpdeg = 4
;;   wfit = where( kidpar.type eq 1 and ix ne !undef and iy ne !undef)
;;   grid_fit_5, ix[wfit], iy[wfit], x_peaks[wfit], y_peaks[wfit], nowarp=nowarp, $
;;               delta_out, alpha_fp_deg, nas_center_x, nas_center_y, xc_0, yc_0, kx, ky, $
;;               n_iter=n_iter, degree=warpdeg, raw_x_offset=raw_x_offset, raw_y_offset=raw_y_offset ;, /noplot

;;grid_fit_5, ix[wfit], iy[wfit], x_peaks[wfit], y_peaks[wfit], nowarp=nowarp, $
;;            delta_out, alpha_fp_deg, nas_center_x, nas_center_y, xc_0, yc_0, kx, ky, $
;;            n_iter=n_iter, degree=warpdeg, raw_x_offset=raw_x_offset, raw_y_offset=raw_y_offset ;, /noplot
;;




;;endif else begin
;;   delta_out    = 1.d0
;;   nas_center_x = 0.0d0
;;   nas_center_y = 0.d0
;;endelse
;;
;;alpha    = alpha_fp_deg*!dtor
;;print, "alpha_fp_deg = ", alpha_fp_deg
;;stop
;;cosalpha = cos(alpha)
;;sinalpha = sin(alpha)
;;
;;nas_center_x = nas_center_x*delta_out
;;nas_center_y = nas_center_y*delta_out
;;nas_x        =  cosalpha*x_peaks + sinalpha*y_peaks + nas_center_x
;;nas_y        = -sinalpha*x_peaks + cosalpha*y_peaks + nas_center_y


;; Nov 19th, 2012
nas_x = x_peaks
nas_y = y_peaks

;; Flag out non valid pixels for now
if nw_out ne 0 then begin
   nas_x[ w_out] = !undef
   nas_y[ w_out] = !undef
endif

;;-------------------------------------------------------------------------------------------------
;; Global plot

;if keyword_set(fit_grid) then begin
   width = 900
   wind, 1, 1, /free, xs=1200, ys=width
   !p.background = 255
   !p.color = 0
   outplot, file=plot_dir+"/"+nickname+"_FPG", png=png, ps=ps
   x_width = max( nas_x[w13]) - min( nas_x[w13])
   y_width = max( nas_y[w13]) - min( nas_y[w13])
   xra1    = avg( nas_x[w13])+[-1,1]*0.6*x_width
   yra1    = avg( nas_y[w13])+[-1,1.6]*0.6*y_width

   ;; Normalize detector response to the median to monitor flat field from
   ;; one OTF_Geometry to the next
   mm = median( a_peaks[w13])
   matrix_plot, nas_x[w13], nas_y[w13], a_peaks[w13]/mm, $
                units="Norm. to Median", xra=xra1, yra=yra1, /xs, /ys, /iso, $
                outcolor=outcolor, title=day+"_"+string(scan_num,format="(I4.4)")+$
                "/ Median Peak value: "+string(mm,format="(F8.2)")+" Hz", $
                xtitle='Arcsec', ytitle='Arcsec'
                
   legendastro, [strtrim(lambda,2)+" mm", $
;            'Rot. (ClockWise): '+string(alpha_fp_deg,format='(F6.2)')+'!uo!n', $
 ;           'Magnif : '+string(delta_out,format="(F5.2)"), $
            'Source: '+source, $
            'Elevation: '+strtrim(long(el_source),2)+"!uo!n"], $
           /right, chars=2
 ;  legendastro, ['Matrix center', 'Nasmyth Rot. center'], psym=[1,1], syms=[3,3], col=[70,0], box=0
   dx = 1
   beam_scale = !fwhm2sigma
   for ii=0, nw13-1 do begin
      ikid = w13[ii]
      if (kidpar[ikid].type eq 1) then !p.color = 0 else !p.color = 250

         xx1 = beam_scale*fwhm_x[ikid]*cosphi*!fwhm2sigma
         yy1 = beam_scale*fwhm_y[ikid]*sinphi*!fwhm2sigma
         ;; before FP rotation
         x1 =  cos(theta[ikid])*xx1 - sin(theta[ikid])*yy1
         y1 =  sin(theta[ikid])*xx1 + cos(theta[ikid])*yy1
         ex = max(xx1) * [ cos(theta[ikid]), sin(theta[ikid])]
         ey = max(yy1) * [-sin(theta[ikid]), cos(theta[ikid])]
         ;; FP rotation
         xx = x1 ; cos(-alpha)*x1 - sin(-alpha)*y1
         yy = y1 ; sin(-alpha)*x1 + cos(-alpha)*y1
         ex1 = ex[0] ; [ cos(-alpha)*ex[0] - sin(-alpha)*ex[1], sin(-alpha)*ex[0] + cos(-alpha)*ex[1]]
         ey1 = ey[0] ; [ cos(-alpha)*ey[0] - sin(-alpha)*ey[1], sin(-alpha)*ey[0] + cos(-alpha)*ey[1]]

         polyfill, nas_x[ikid] + xx, nas_y[ikid] + yy, col=outcolor[ii]
         oplot, nas_x[ikid] + xx, nas_y[ikid] + yy, thick=2
         xyouts, nas_x[ikid], nas_y[ikid], strtrim(kidpar[ikid].numdet,2), chars=1.2, /data, charthick=2
   endfor
;   oplot, [nas_center_x], [nas_center_y], psym=1, syms=3, col=70, thick=2
   oplot, [0], [0], psym=1, syms=3, thick=2 ; matrix center
   outplot, /close, preview=preview

   ;; Stat on Calibration
   wind, 1, 2, /free, /large
   outplot, file=plot_dir+'/'+nickname+"_kids_calib", png=png, ps=ps
   hh = a_peaks[w1]/source_flux ; Hz/Jy
   n_histwork, hh, bin=stddev(hh)/4., xhist, yhist, gpar, /fit, /nolegend, $
               title='Kids Calib '+nickname
   legendastro, [strtrim(lambda,2)+" mm", "", $
                 "Nvalid = "+strtrim(nw1,2), $
                 "Avg. Resp "+strtrim(gpar[1],2)+" Hz/Jy", $
                 "!7r!3 = "+strtrim(gpar[2],2)+" Hz/Jy"], chars=1.5
   outplot, /close

;endif

;;================================================================================================================================
;; Write output file
if keyword_set(output_fits_file) then begin

   str = {pos_index:0, n_comp:1, numdet:intarr(4), coeff:dblarr(4), $
          ;magnif:delta_out, $         ;nas_center_x:nas_center_x, nas_center_y:nas_center_y, $
          nas_x:0.0d0, nas_y:0.0d0, $ ; end of variables for Alain
          flag:0, multiple:0, other_dets:intarr(4), ix:-1, iy:-1, ix_pos:-1, iy_pos:-1, $
          fwhm_1:0.0d0, fwhm_2:0.0d0, theta:0.0d0, calib:0.0d0, atm_x_calib:0.d0, $
          el_source:el_source};, x_peaks:0.d0, y_peaks:0.d0, alpha:alpha_fp_deg*!dtor, }

   ;; Off resonance
   w_off = where( kidpar.type eq 2, nw_off)
   if nw_off gt 16 then message, /info, "Warning : Nw_off = "+strtrim( nw_off, 2)+" > 16"

   ;; npos = 144 + nw_off
   ilambda = where( !nika.lambda eq lambda)
   ngmax   = !nika.array[ilambda].ngrid_nodes_max 
   npos    = ngmax + nw_off
   str     = replicate( str, npos)

   str.pos_index = indgen(npos)
   for i=0, nw_off-1 do begin
      str[ngmax+i].numdet[0] = kidpar[w_off[i]].numdet
      str[ngmax+i].flag      = 2
   endfor
   
   ix_pos    = lonarr(npos) - 1
   iy_pos    = lonarr(npos) - 1
   pix_index = lonarr(npos) - 1
   
   ix_pos[w13]    = long(ix[w13] - min( ix[w13]))
   iy_pos[w13]    = long(iy[w13] - min( iy[w13]))
   pix_index[w13] = (ix_pos + 12*iy_pos)[w13]

   ;; Grid pixels
   for i=0, 143 do begin
      wpix = where( pix_index eq i, nwpix)
      
      if nwpix eq 0 then str[i].n_comp = 0
      
      if nwpix eq 1 then begin
         str[i].ix_pos = ix_pos[wpix]
         str[i].iy_pos = iy_pos[wpix]
         
         wcoeff = where( coeff[*,wpix] ne 0.d0, n_wcoeff)
         str[i].n_comp = n_wcoeff
         for j=0, n_wcoeff-1 do begin
            str[i].coeff[j]  = coeff[ wcoeff[j], wpix]
            str[i].numdet[j] = kidpar[wcoeff[j]].numdet
         endfor
         
         str[i].nas_x   = nas_x[wpix]
         str[i].nas_y   = nas_y[wpix]
;         str[i].x_peaks = x_peaks[wpix] ; redundant, but leave for Xavier's compatibility
;         str[i].y_peaks = y_peaks[wpix] ; redundant, but leave for Xavier's compatibility
         
         str[i].flag   = kidpar[wpix].type
         str[i].ix     = ix[wpix]
         str[i].iy     = iy[wpix]
         str[i].fwhm_1 = fwhm_x[wpix]
         str[i].fwhm_2 = fwhm_y[wpix]
         str[i].theta  = theta[wpix] ;- alpha_fp_deg*!dtor
         str[i].calib  = source_flux/a_peaks[wpix]
         str[i].atm_x_calib = str[i].calib ; place holder
      endif
      
      if nwpix gt 1 then begin
         print, "multiple  :"
         str[i].multiple = 1
         for j=0, nwpix-1 do str[i].other_dets[j] = kidpar[wpix[j]].numdet
      endif
   endfor

   ;; Init header
   mwrfits, str, !nika.off_proc_dir+"/"+output_fits_file, /create, header
   sxdelpar, header, 'COMMENT'
   sxaddpar, header, 'COMMENT', 'pos_index is the grid position, going from 0 to 143 for ON kids'
   sxaddpar, header, 'COMMENT', 'pos_index larger or equal to '+strtrim(ngmax,2)+' are for OFF-resonance kids'
   sxaddpar, header, 'COMMENT', 'n_comp is then number of kids combined for the current pos_index'
   sxaddpar, header, 'COMMENT', 'numdet are the detector numbers that are combined for the current pos_index'
   sxaddpar, header, 'COMMENT', 'multiple : 1 if another kid is located at the same pos_index'
   sxaddpar, header, 'COMMENT', 'other_dets : list of other kids at this pos_index if multiple=1'
   sxaddpar, header, 'COMMENT', 'coeff are the weights to apply linearly to each numdet'
   sxaddpar, header, 'COMMENT', 'magnif is the magnification in arcsec/grid step to go from Nasmyth to Sky coordinates'
   ;sxaddpar, header, 'COMMENT', 'alpha [Rad] is defined by the equation below :'
   sxaddpar, header, 'COMMENT', 'nas_x, nas_y are in ARCSEC in Nasmyth coordinates'
   sxaddpar, header, 'COMMENT', 'They approximately relate x,y offsets on the sky via:'
   ;sxaddpar, header, 'COMMENT', '|xc| = | cos(pi/2-elevation+alpha) -sin(pi/2-elevation+alpha)| |nas_x-nas_center_x|'
   ;sxaddpar, header, 'COMMENT', '|yc| = | sin(pi/2-elevation+alpha)  cos(pi/2-elevation+alpha)| |nas_y-nas_center_y|'
   sxaddpar, header, 'COMMENT', '|xc| = | cos(pi/2-elevation) -sin(pi/2-elevation)| nas_x'
   sxaddpar, header, 'COMMENT', '|yc| = | sin(pi/2-elevation)  cos(pi/2-elevation)| nas_y'
   sxaddpar, header, 'COMMENT', 'ix is the integer position along x on the grid corresponding to pos_index. It can be positive and negative'
   sxaddpar, header, 'COMMENT', 'iy is the integer position along y on the grid corresponding to pos_index. It can be positive and negative'
   sxaddpar, header, 'COMMENT', 'ix_pos is the integer position along x on the grid corresponding to pos_index in [0,11]'
   sxaddpar, header, 'COMMENT', 'iy_pos is the integer position along y on the grid corresponding to pos_index in [0,11]'
   sxaddpar, header, 'COMMENT', 'theta is the orientation of the beam main axis w.r.t. x'
   sxaddpar, header, 'COMMENT', 'FWHM_1 is the FWHM of the main axis of the beam'
   sxaddpar, header, 'COMMENT', 'FWHM_2 is the fwhm in the orthogonal direction to fwhm_1'
   sxaddpar, header, 'COMMENT', 'Calib is in Jy/Hz'
   sxaddpar, header, 'COMMENT', "flag = 0 : no signal"
   sxaddpar, header, 'COMMENT', "flag = 1 : good kid (single beam)"
   sxaddpar, header, 'COMMENT', "flag = 2 : off resonance"
   sxaddpar, header, 'COMMENT', "flag = 3 : combination of several kids"
   sxaddpar, header, 'COMMENT', "flag = 4 : multiple beams, not separable"
   sxaddpar, header, 'COMMENT', "flag = 5 : strange resonnance"
   sxaddpar, header, 'COMMENT', "flag = 6 : multiple TBC"

   ;; Write fits files
   mwrfits, str,  !nika.off_proc_dir+"/"+output_fits_file, /create, header
   print, ""
   print, "Wrote "+ !nika.off_proc_dir+"/"+output_fits_file

   ;;mwrfits, kidpar, output_kidpar_fits_file, /create
   kidpar_ext = {name:'a', numdet:0, type:0, x_pix:0, y_pix:0, frequ:0, amplitude:0, ic:0, qc:0, ir:0, qr:0, $
                 nas_x:0.d0, nas_y:0.d0, $;alpha:alpha_fp_deg*!dtor, $;nas_center_x:nas_center_x, nas_center_y:nas_center_y, 
                 calib:1.d0, atm_x_calib:0.d0, fwhm:0.d0, fwhm_x:0.d0, fwhm_y:0.d0, lambda:0, box:'Z', units:source_flux_units, $;, magnif:delta_out, 
                 s1:0.d0, s2:0.d0, a_peaks:0.d0};x_peaks:0.d0, y_peaks:0.d0, 
   kidpar_ext = replicate( kidpar_ext, nkids)
   tags     = tag_names(kidpar)
   tags_ext = tag_names(kidpar_ext)
   my_match, tags, tags_ext, suba, subb
   for i=0, n_elements(suba)-1 do kidpar_ext.(subb[i]) = kidpar.(suba[i])

;   kidpar_ext.x_peaks      = x_peaks
;   kidpar_ext.y_peaks      = y_peaks
   kidpar_ext.a_peaks      = a_peaks
   kidpar_ext.nas_x        = nas_x
   kidpar_ext.nas_y        = nas_y
   kidpar_ext.calib        = source_flux/a_peaks
   kidpar_ext.atm_x_calib  = kidpar_ext.calib ; place holder
   kidpar_ext.fwhm         = fwhm
   kidpar_ext.fwhm_x       = fwhm_x
   kidpar_ext.fwhm_y       = fwhm_y
   kidpar_ext.lambda       = lambda
   kidpar_ext.box          = box
   kidpar_ext.units        = source_flux_units

endif

end
