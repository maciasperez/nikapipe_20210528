
;; Center both focal planes on the reference pointing detector, fits the rotation
;; from Nasmyth to (Az,El) and writes down the updated kidpar to disk.
;;------------------------------------------------------------------------------

pro get_geometry_3, kidpar, ptg_numdet_ref, $
                    kidref_type_force=kidref_type_force, charsize = charsize, $
                    quicklook=quicklook, noplot=noplot, distance=distance, xfit=xfit, yfit=yfit, $
                    no_ref_center=no_ref_center, position=position

;; If a reference kid has been chosen as Nasmyth center
;; Valid kids only, set others to !values.d_nan to be safe 
w1 = where( kidpar.type eq 1, nw1, compl=wbad, ncompl=nwbad)

;; Deal with numdet ref if available
if not keyword_set(no_ref_center) then begin
   w = where( kidpar.numdet eq ptg_numdet_ref, nw)
   if nw eq 0 then begin
      message, /info, "No kid as a numdet matching the input ptg_numdet_ref: "+strtrim(ptg_numdet_ref,2)
   endif else begin
      w  = where( kidpar.numdet eq ptg_numdet_ref, nw)
      if keyword_set(kidref_type_force) then kidpar[w].type = 1
      if kidpar[w].type ne 1 then begin
         message, "ptg_numdet_ref has type /=1 ?! (use /kidref_type_force to bypass this... at your own risk)"
         return
      endif
      if nw eq 0 then message, "No kid = ptg_numdet_ref ?!"
      kidpar[w1].nas_x -= kidpar[w[0]].nas_x
      kidpar[w1].nas_y -= kidpar[w[0]].nas_y
   endelse
endif

;; Fit Nasmyth to (Az,el) rotation (both matrices at the same time)
;; names = strtrim( kidpar[w1].numdet,2)

if keyword_set(quicklook) then begin
   ;; Quicklook to double check for outlyers
   wind, 1, 1, /free, xs=1200, ys=800
   !p.multi=[0,2,1]
   plot, kidpar[w1].nas_x, kidpar[w1].nas_y,             psym=1, /iso, title='Nasmyth'
   legendastro, [strtrim(lambda,2)+"mm", " ", "All valid kids"], box=0
   plot, kidpar[w1].x_peak_azel, kidpar[w1].y_peak_azel, psym=1, /iso, title='Az,el'
   legendastro, [strtrim(lambda,2)+"mm", " ", "All valid kids"], box=0
   !p.multi=0
endif

;; Fit rotation and mangnification
distance = kidpar.nas_x*0.d0
grid_fit_5, kidpar[w1].nas_x, kidpar[w1].nas_y, kidpar[w1].x_peak_azel, kidpar[w1].y_peak_azel, /nowarp, $
            delta_out, alpha_rot_deg, nas_center_x, nas_center_y, xc_0, yc_0, kx, ky, xfit, yfit, names=names, $
            title = 'grid_fit_5', noplot=noplot, distance=dd, charsize = charsize, $
            xtitle = 'Az (arcsec)', ytitle = 'El (arcsec)', position=position
distance[w1] = dd

kidpar[w1].nas_center_x = nas_center_x
kidpar[w1].nas_center_y = nas_center_y

end
