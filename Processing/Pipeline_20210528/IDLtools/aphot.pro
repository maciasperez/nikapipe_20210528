

;+
;
; SOFTWARE: NIKA pipeline
;
; NAME:
; aphot
;
; CATEGORY:
;
; CALLING SEQUENCE:
;         aphot
; 
; PURPOSE: 
;        Derives aperture photometry around a input position
; 
; INPUT: 
;        - map, map_var, xmap, ymap, radius_meas, radius_bg
; 
; OUTPUT: 
;        - the integrated flux
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Feb. 2017, NP, from nk_aperture_photometry_3


pro aphot, map_in, map_var, xmap, ymap, reso, xcenter, ycenter, $
           radius_meas, radius_bg_min, radius_bg_max, bin_width, input_fwhm, $
           flux, err_flux, int_rad, phi, err, $
           noplot=noplot, bg_mask=bg_mask, pp1=pp1, $
           title=title, imrange=imrange, omega_90=omega_90, $
           flps = flps, eflps = eflps
;-
  
if n_params() lt 1 then begin
   dl_unix, 'aphot'
   return
endif

result = -1.d0
flux = -1.d0  ; default values
err_flux = 1D20                 ; default values

rmap = sqrt( (xmap-xcenter)^2 + (ymap-ycenter)^2)  
loc0 = where(rmap ge radius_bg_min and rmap le radius_bg_max, nloc0)
if nloc0 eq 0 then begin
   message, /info, "no pixel lies between radius_bg_min="+strtrim(radius_bg_min,2)+$
            " and radius_bg_max="+strtrim(radius_bg_max,2)
   return
endif

;; Radii of integration
nx = n_elements(xmap[*,0])
ny = n_elements(ymap[0,*])
;; int_rad = dindgen(long(max([nx,ny])/2.)*reso/bin_width)*bin_width
;; Limit integration to radius_bg_max that should be the largest inner
;; circle to the map. Otherwise, we'll try to integrate over
;; rings that are not completely covered by the map and this will bias
;; the estimation: the aperture flux makes sense only when integraed
;; on full rings.
int_rad = dindgen( long(radius_bg_max/bin_width))*bin_width

npix = long(nx) * long(ny)

;; Select valid pixels for background estimation and subtraction
;; Accept a mask here to estimate the background outside diffuse
;; emission if any.
if not keyword_set(bg_mask) then bg_mask = xmap*0.d0
wpix_bg = where( rmap ge radius_bg_min and $
                 rmap le radius_bg_max and $
                 finite(map_var) eq 1 and $
                 map_var gt 0.d0 and $
                 bg_mask eq 0.d0, nwpix_bg)

pcharsize_old = !p.charsize
!p.charsize = 0.7

if nwpix_bg eq 0 then begin
   ;; nk_error, info, "No valid pixel for aperture photometry"
   message, /info, "No valid pixel for aperture photometry"
   goto, ciao
endif else begin
   ;; Init arrays
   avg_flux     = int_rad*0.d0
   avg_flux_err = int_rad*0.d0

   ;; Subtract zero level
   w8  = 1.d0/map_var[wpix_bg]
   s   = map_in[ wpix_bg]
   map = map_in - total(w8*s)/total(w8)

   ;; Integrate from the center up to various radii
   nr  = n_elements(int_rad)
   phi = dblarr(nr)
   err = dblarr(nr)
   for i=0, nr-1 do begin
      wdisk = where(rmap le int_rad[i] and $
                    finite(map_var) eq 1 and map_var gt 0.d0, nwdisk)
      if nwdisk ne 0 then begin
         phi[i] = reso^2 * total(       map[wdisk])
         err[i] = reso^2 * sqrt( total( map_var[wdisk]))
      endif
   endfor
   ;; phi /= 2.d0*!dpi*(input_fwhm*!fwhm2sigma)^2
   ;; err /= 2.d0*!dpi*(input_fwhm*!fwhm2sigma)^2

   ;; Account for calibration in fixed FWHM gaussian beam vs solid
   ;; angle at 90 arcsec
   if keyword_set(omega_90) then begin
      phi     /=  omega_90
      err     /=  omega_90
; FXD old: does not seem correct
      ;; flux     *= 2.d0*!dpi*(input_fwhm*!fwhm2sigma)^2 / omega_90
      ;; err_flux *= 2.d0*!dpi*(input_fwhm*!fwhm2sigma)^2 / omega_90
   endif else begin
      phi /= 2.d0*!dpi*(input_fwhm*!fwhm2sigma)^2
      err /= 2.d0*!dpi*(input_fwhm*!fwhm2sigma)^2
   endelse
   
   
   ;; Determine the flux at the requested radius
   flux     = interpol(phi, int_rad, radius_meas)
   err_flux = interpol(err, int_rad, radius_meas)

   if not keyword_set(noplot) then begin
      if not keyword_set(pp1) then my_multiplot, 1, 2, pp, pp1, /rev

      w = where( finite(map_var) and map_var ne 0)
      if not keyword_set(imrange) then imrange = [-1,1]*2*stddev(map[w])
      imview, map, xmap=xmap, ymap=ymap, position=pp1[0,*], colt=1, imr=imrange, /noerase, $
              charsize=!p.charsize, charbar=!p.charsize, /nobar, title=title
      oplot, [xcenter], [ycenter], psym=1, col=255, syms=2
      psi = dindgen(100)/99.*2*!dpi
      oplot, xcenter + radius_bg_min*cos(psi), $
             ycenter + radius_bg_min*sin(psi), col=150,  thick = 1.5 ; can be masked by the radius_meas line if thick is not thick enough
      oplot, xcenter + radius_bg_max*cos(psi), $
             ycenter + radius_bg_max*sin(psi), col=150, line=2
      oplot, xcenter + radius_meas*cos(psi), $
             ycenter + radius_meas*sin(psi), col=250
      legendastro, ['bg rmin '+strtrim(long(radius_bg_min),2), $
                    'bg rmax '+strtrim(long(radius_bg_max),2), $
                    'meas '+strtrim(long(radius_meas),2)], col=[150,150,250], line=[0,2,1]
      
      ploterror, int_rad, phi, err, psym=-8, syms=0.5, position=pp1[1,*], $
                 xtitle='Radius [arcsec]', title='Flux (Ap., PS) [Jy]', /noerase, ystyle = 16
      oplot, [1,1]*radius_bg_min, [-1e4,1e4], col=150, line = 0
      oplot, [1,1]*radius_bg_max, [-1e4,1e4], col=150, line = 2
      oplot, [1,1]*radius_meas, [-1e4,1e4], col=250, line = 1
      oplot, [0, 1e4], [1,1]*flux, col=250
      oploterror, [radius_meas], [flux], [err_flux], $
                  col=250, psym=8, errcol=250
      if keyword_set( flps) then begin
         oploterror, [radius_meas], [flps], [eflps], $
                     col=100, psym=8, errcol=100
      endif
      if keyword_set(title) then legendastro, title, /right,/bottom, box=0
   endif      
endelse

!p.charsize = pcharsize_old

ciao:

end
