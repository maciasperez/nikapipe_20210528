
;+
;
; SOFTWARE: NIKA simulation pipeline
;
; NAME: nks_add_source_preproc
;
; CATEGORY:
;
; CALLING SEQUENCE:
;         nks_add_source_preproc, simpar, data, kidpar
; 
; PURPOSE: 
;        Adds one or more point sources to the timelines *ALREADY IN JY*.
;        This is a twin routine to nks_add_source, this one is meant as a
;        shortcut and to be used in nk_preproc2maps.
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
; MODIFICATION HITORY: 
;        - Apr 23rd, 2014: creation (Nicolas Ponthieu & Remi Adam - adam@lpsc.in2p3.fr)
;-


FUNCTION point_source, dra, ddec, x_centre, y_centre, sigma_beam, flux
  RETURN, flux * exp(-((dra - x_centre)^2 + (ddec - y_centre)^2)/(2*sigma_beam^2))
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
pro nks_add_source_preproc, param, simpar, info, data, kidpar

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nks_add_source_preproc, simpar, info, data, kidpar"
   return
endif

if simpar.n_ps ge 1 then begin

   nsn   = n_elements(data)
   nkids = n_elements(kidpar)

   for ikid=0, nkids-1 do begin
      if kidpar[ikid].type eq 1 then begin
         
         ;; Point sources
         for is=0, simpar.n_ps-1 do begin
            if kidpar[ikid].array eq 1 then flux = simpar.ps_flux_1mm[is] else flux = simpar.ps_flux_2mm[is]
            
            source_toi_I = point_source( data.dra[ikid], data.ddec[ikid], $
                                         simpar.ps_offset_x[is], simpar.ps_offset_y[is], $
                                         kidpar[ikid].fwhm*!fwhm2sigma, flux)
            data.toi[ikid] += source_toi_I
           ;;------------------------------------------------------------------------------------
            ;; Polarization
            if info.polar ne 0 then begin
               if kidpar[ikid].array eq 1 then flux = simpar.ps_flux_q_1mm[is] else flux = simpar.ps_flux_q_2mm[is]
               source_toi_Q = point_source( data.dra[ikid], data.ddec[ikid], $
                                            simpar.ps_offset_x[is], simpar.ps_offset_y[is], $
                                            kidpar[ikid].fwhm*!fwhm2sigma, flux)
               
               if kidpar[ikid].array eq 1 then flux = simpar.ps_flux_u_1mm[is] else flux = simpar.ps_flux_u_2mm[is]
               source_toi_U = point_source( data.dra[ikid], data.ddec[ikid], $
                                            simpar.ps_offset_x[is], simpar.ps_offset_y[is], $
                                            kidpar[ikid].fwhm*!fwhm2sigma, flux)
               
               data.toi[ikid] += (data.cospolar*source_toi_q + data.sinpolar*source_toi_u)
            endif

            ;; If prism
            if info.polar eq 2 then begin
               if kidpar[ikid].array eq 1 then flux = simpar.ps_flux_1mm[is] else flux = simpar.ps_flux_2mm[is]
               source_toi_I = point_source( data.dra1[ikid], data.ddec1[ikid], $
                                            simpar.ps_offset_x[is], simpar.ps_offset_y[is], $
                                            kidpar[ikid].fwhm*!fwhm2sigma, flux)
               data.toi[ikid] += source_toi_I

               ;; Polarization
               if kidpar[ikid].array eq 1 then flux = simpar.ps_flux_q_1mm[is] else flux = simparr.ps_flux_q_2mm[is]
               source_toi_Q = point_source( data.dra1[ikid], data.ddec1[ikid], $
                                            simpar.ps_offset_x[is], simpar.ps_offset_y[is], $
                                            kidpar[ikid].fwhm*!fwhm2sigma, flux)
               
               if kidpar[ikid].array eq 1 then flux = simpar.ps_flux_u_1mm[is] else flux = simpar.ps_flux_u_2mm[is]
               source_toi_U = point_source( data.dra1[ikid], data.ddec1[ikid], $
                                            simpar.ps_offset_x[is], simpar.ps_offset_y[is], $
                                            kidpar[ikid].fwhm*!fwhm2sigma, flux)
               
               data.toi[ikid] += (data.cospolar*source_toi_q + data.sinpolar*source_toi_u)
            endif
            ;;------------------------------------------------------------------------------------
         endfor
      endif
   endfor
endif

end
