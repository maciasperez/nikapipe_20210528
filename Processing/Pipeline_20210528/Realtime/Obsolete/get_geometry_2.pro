
;; Center both focal planes on the reference pointing detector, fits the rotation
;; from Nasmyth to (Az,El) and writes down the updated kidpar to disk.
;;------------------------------------------------------------------------------

pro get_geometry_2, param, kidpar1, kidpar2, ptg_numdet_ref, kidpar, $
                    kidref_type_force=kidref_type_force, $
                    quicklook=quicklook

;; Merge both kidpars for convenience
nk1 = n_elements(kidpar1)
nk2 = n_elements(kidpar2)
kidpar = replicate( kidpar1[0], nk1+nk2)
kidpar[0:nk1-1] = kidpar1
kidpar[nk1:*]   = kidpar2

;; Sanity checks
if keyword_set(ptg_numdet_ref) then begin
   w = where( kidpar.numdet eq ptg_numdet_ref, nw)
   if nw eq 0 then message, "ptg_numdet_ref is set as a keyword but no kid has this number in kidpar ?"
   if keyword_set(kidref_type_force) then kidpar[w].type = 1
   if kidpar[w].type ne 1 then message, "ptg_numdet_ref has type /=1 ?! (use /kidref_type_force to bypass this... at your own risk)"
endif

;; If a reference kid has been chosen as Nasmyth center
;; Valid kids only, set others to !values.d_nan to be safe 
w1 = where( kidpar.type eq 1, nw1, compl=wbad, ncompl=nwbad)
w  = where( kidpar.numdet eq ptg_numdet_ref, nw)
if nw eq 0 then message, "No kid = ptg_numdet_ref ?!"
kidpar[w1].nas_x -= kidpar[w[0]].nas_x
kidpar[w1].nas_y -= kidpar[w[0]].nas_y

;; Fit Nasmyth to (Az,el) rotation (both matrices at the same time)
names = strtrim( kidpar[w1].numdet,2)

print, ""
print, "------------------------------------------------"
print, "minmax(kidpar[w1].nas_x): ",       minmax(kidpar[w1].nas_x)
print, "minmax(kidpar[w1].nas_y): ",       minmax(kidpar[w1].nas_y)
print, "minmax(kidpar[w1].x_peak_azel): ", minmax(kidpar[w1].x_peak_azel)
print, "minmax(kidpar[w1].y_peak_azel): ", minmax(kidpar[w1].y_peak_azel)

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
grid_fit_5, kidpar[w1].nas_x, kidpar[w1].nas_y, kidpar[w1].x_peak_azel, kidpar[w1].y_peak_azel, /nowarp, $
            delta_out, alpha_rot_deg, nas_center_x, nas_center_y, xc_0, yc_0, kx, ky, names=names, $
            title = 'grid_fit_5'

kidpar[w1].nas_center_x = nas_center_x
kidpar[w1].nas_center_y = nas_center_y

;;; Write output fits file
;nika_write_kidpar, kidpar, output_kidpar_nickname+".fits"

message, /info, ""
message, /info, "Finished."

end
