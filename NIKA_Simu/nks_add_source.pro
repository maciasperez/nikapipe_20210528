
;+
;
; SOFTWARE: NIKA simulation pipeline
;
; NAME: nks_add_source
;
; CATEGORY:
;
; CALLING SEQUENCE:
;         nks_add_source, simpar, data, kidpar
; 
; PURPOSE: 
;        Adds one or more point sources to the timelines.
;        These point sources do not comme from a map but are computed
;        analytically with each kid individual pointing.
; 
; INPUT: 
;        - simpar: the simulation parameter structure
;        - data: the data structure
;        - kidpar : the kid structure
; 
; OUTPUT: 
;        - data
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Apr 23rd, 2014: creation (Nicolas Ponthieu & Remi Adam - adam@lpsc.in2p3.fr)
;-

;;=======================================================================
FUNCTION point_source, dra, ddec, ra_source_offset, dec_source_offset, sigma_beam, flux
  ;; we're still in orthonormal coordinates at this stage of
  ;; the pipeline.
  ;; the true conversion from offsets to absolute Ra and Dec is done
  ;; later on before projection in nk_get_ipix.
  RETURN, flux * exp(-((dra - ra_source_offset)^2 + (ddec -dec_source_offset)^2)/(2*sigma_beam^2))
END


;;=======================================================================
FUNCTION disk_source, ddec, dra, x_centre, y_centre, radius, flux
  source = dblarr(n_elements(ddec))
  d_centre = sqrt((ddec - y_centre)^2 + (dra - x_centre)^2)
  loc = where(d_centre le radius, nloc)
  if nloc ne 0 then source[loc] = flux
  RETURN, source
END 

;;=======================================================================
pro nks_add_source, param, simpar, info, data, kidpar, astr=astr

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nks_add_source, simpar, info, data, kidpar"
   return
endif
;; info.polar = 0
if simpar.n_ps ge 1 then begin

   nsn   = n_elements(data)
   nkids = n_elements(kidpar)

   ;; Point sources
   for is=0, simpar.n_ps-1 do begin

      for iarray=1, 3 do begin
         w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1)
         if nw1 ne 0 then begin
            
            if iarray eq 2 then begin
               flux = simpar.ps_flux_2mm[is]
               fwhm = !nika.fwhm_nom[1]
               if info.polar eq 1 then begin
                  flux_q = simpar.ps_flux_q_1mm[is]
                  flux_u = simpar.ps_flux_u_1mm[is]
               endif
            endif else begin
               flux = simpar.ps_flux_1mm[is]
               fwhm = !nika.fwhm_nom[0]
               if info.polar eq 1 then begin
                  flux_q = simpar.ps_flux_q_2mm[is]
                  flux_u = simpar.ps_flux_u_2mm[is]
               endif
            endelse
            
            ;; We're still in orthonormal coordinates and in
            ;; arcsec at this stage of the pipeline. The conversion to
            ;; true absolute ra and dec is done later on when we
            ;; compute the pixel addresses in nk_get_ipix
            ;; => Take simpar.ps_offset_x and simpar.ps_offset_y here, 
            ;; but careful : info.longobj and info.latobj might be
            ;; different from the map center given by astr.crval
            source_toi_I = point_source( data.dra[w1], data.ddec[w1], $
                                         simpar.ps_offset_x[is] + (astr.crval[0]-info.longobj)*3600.d0*cos(astr.crval[1]*!dtor), $
                                         simpar.ps_offset_y[is] + (astr.crval[1]-info.latobj )*3600.d0, $
                                         fwhm*!fwhm2sigma, flux)

            data.toi[w1] += source_toi_I

            ;; Polarization
            if info.polar ne 0 then begin
               if iarray eq 3 then  begin
                  pol_sign = -1.d0
               endif else begin
                  pol_sign =  1.d0
               endelse
               
               source_toi_Q = pol_sign*point_source( data.dra[w1], data.ddec[w1], $
                                                     simpar.ps_offset_x[is], simpar.ps_offset_y[is], $
                                                     fwhm*!fwhm2sigma, flux_q)
               
               source_toi_U = pol_sign*point_source( data.dra[w1], data.ddec[w1], $
                                                     simpar.ps_offset_x[is], simpar.ps_offset_y[is], $
                                                     fwhm*!fwhm2sigma, flux_u)
               data.toi[w1] += (dblarr(nw1+1) # data.cospolar)*source_toi_q + $
                               (dblarr(nw1+1) # data.sinpolar)*source_toi_u
            endif
         endif
      endfor
   endfor
endif


end
