;+
;
; SOFTWARE: NIKA pipeline
;
; NAME:
; nk_aperture_photometry
;
; CATEGORY: ?
;
; CALLING SEQUENCE:
;         nk_aperture_photometry
; 
; PURPOSE: 
;        Derives aperture photometry at the map center
; 
; INPUT: 
;        - param, grid, info
; 
; OUTPUT: 
;        - info: updated with the status, error message and photometry results
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - August, 20th, 2015: Adapted from nika_anapipe_difphoto, R. Adam and
;          N. Ponthieu
;-

pro nk_aperture_photometry, param, info, grid

  message, /info, "Obsolete routine, archived for convenience only"
  return


  
if n_params() lt 1 then begin
   message, /info, "Calling sequence: "
   print, "nk_aperture_photometryo, param, info, grid"
   return
endif

rmap = sqrt(grid.xmap^2 + grid.ymap^2)  
loc0 = where(rmap ge param.aperture_photometry_zl_rmin and rmap le param.aperture_photometry_zl_rmax, nloc0)
if nloc0 eq 0 then begin
   nk_error, info, "no pixel lies between param.aperture_photometry_zl_rmin="+strtrim(param.aperture_photometry_zl_rmin,2)+$
             " and param.aperture_photometry_zl_rmax="+strtrim(param.aperture_photometry_zl_rmax,2)
   return
endif

;; Radii of integration
int_rad = dindgen(long(max([grid.nx,grid.ny])*grid.map_reso/param.aperture_photometry_binwidth/2.0))*param.aperture_photometry_binwidth

npix = long(grid.nx) * long(grid.ny)
if info.polar eq 0 then nstokes=1 else nstokes=3

;; Determine photometry
if param.do_plot ne 0 then begin
   if param.plot_ps eq 0 then wind, 1, 1, /free, /large, title='nk_aperture_photometry'
   my_multiplot, nstokes, 2, pp, pp1, /rev
endif

stokes_par = ["I", "Q", "U"]
for lambda=1, 2 do begin

   ;; Init maps
   if lambda eq 1 then begin
      if info.polar ne 0 then begin
         maps = dblarr( npix, 6)
         maps[*,2] = grid.map_q_1mm
         maps[*,3] = grid.map_var_q_1mm
         maps[*,4] = grid.map_u_1mm
         maps[*,5] = grid.map_var_u_1mm
      endif else begin
         maps = dblarr( npix, 2)
      endelse
      maps[*,0] = grid.map_i_1mm
      maps[*,1] = grid.map_var_i_1mm
   endif else begin
      if info.polar ne 0 then begin
         maps = dblarr( npix, 6)
         maps[*,2] = grid.map_q_2mm
         maps[*,3] = grid.map_var_q_2mm
         maps[*,4] = grid.map_u_2mm
         maps[*,5] = grid.map_var_u_2mm
      endif else begin
         maps = dblarr( npix, 2)
      endelse
      maps[*,0] = grid.map_i_2mm
      maps[*,1] = grid.map_var_i_2mm
   endelse

   ;; Loop on I, Q, U
   for istokes=0, nstokes-1 do begin

      ;; Select valid pixels for the integration
      wpix = where( rmap ge param.aperture_photometry_zl_rmin and $
                    rmap le param.aperture_photometry_zl_rmax and $
                    ;; check variance too
                    finite(maps[*,2*istokes+1]) eq 1 and maps[*,2*istokes+1] gt 0.d0, nwpix)
      
      ;; Init arrays
      avg_flux     = int_rad*0.d0
      avg_flux_err = int_rad*0.d0
      
      if nwpix eq 0 then begin
         nk_error, info, "No valid pixel for aperture photometry at lambda="+strtrim(lambda,2), status=2
      endif else begin
         
         ;; Subtract zero level
         maps[*,2*istokes] -= mean( maps[wpix,2*istokes])
         
         ;; Discard unvalid pixels
         wnovar = where(finite(maps[*,2*istokes+1]) ne 1 or maps[*,2*istokes+1] le 0, nwnovar)
         if nwnovar ne 0 then begin
            maps[wnovar, 2*istokes]   = 0.d0
            maps[wnovar, 2*istokes+1] = 0.d0
         endif
  
         ;; Integrate from the center up to various radii
         nr  = n_elements(int_rad)
         phi = dblarr(nr)
         err = dblarr(nr)
         for i=0, nr-1 do begin
            loc_sum = where(rmap le int_rad[i], nloc)
            if nloc ne 0 then begin
               phi[i] = total(maps[loc_sum,2*istokes])*grid.map_reso^2
               err[i] = sqrt( total( maps[loc_sum,2*istokes+1]))*grid.map_reso^2
            endif
         endfor
         phi /= 2.d0*!dpi*(!nika.fwhm_nom[lambda-1]*!fwhm2sigma)^2 ;*anapar.dif_photo.beam_cor.a
         err /= 2.d0*!dpi*(!nika.fwhm_nom[lambda-1]*!fwhm2sigma)^2 ;*anapar.dif_photo.beam_cor.a
         
         ;; Determine the flux at the requested radius
         avg_flux     = interpol(phi, int_rad, param.aperture_photometry_rmeas)
         avg_flux_err = interpol(err, int_rad, param.aperture_photometry_rmeas)

         if param.do_plot ne 0 then begin
            outplot, file=param.plot_dir+'/aperture_photometry_'+$
                     strtrim(param.scan,2)+"_"+stokes_par[istokes]+"_"+strtrim(lambda,2)+"mm", png=param.plot_png, ps=param.plot_ps
            ploterror, int_rad, phi, err, psym=-8, $;position=pp[istokes,lambda-1,*], /noerase, $
                       title='Istokes = '+strtrim(istokes,2)+" "+strtrim(lambda,2)+"mm", $
                       xtitle='Radius', ytitle='Flux [Jy]', chars=1
            oplot, [1,1]*param.aperture_photometry_rmeas, [-1e4,1e4], col=250
            oplot, [0, 1e4], [1,1]*avg_flux, col=250
            oploterror, [param.aperture_photometry_rmeas], [avg_flux], [avg_flux_err], $
                        col=250, psym=8, errcol=250
            outplot, /close
         endif
      endelse

      ;; Put results into info
      if lambda eq 1 then begin
         case istokes of
            0:begin
               info.result_aperture_photometry_I_1mm     = avg_flux
               info.result_aperture_photometry_I_1mm_err = avg_flux_err
            end
            1:begin
               info.result_aperture_photometry_Q_1mm     = avg_flux
               info.result_aperture_photometry_Q_1mm_err = avg_flux_err
            end
            2:begin
               info.result_aperture_photometry_U_1mm     = avg_flux
               info.result_aperture_photometry_U_1mm_err = avg_flux_err
            end
         endcase
      endif else begin
         case istokes of
            0:begin
               info.result_aperture_photometry_I_2mm     = avg_flux
               info.result_aperture_photometry_I_2mm_err = avg_flux_err
            end
            1:begin
               info.result_aperture_photometry_Q_2mm     = avg_flux
               info.result_aperture_photometry_Q_2mm_err = avg_flux_err
            end
            2:begin
               info.result_aperture_photometry_U_2mm     = avg_flux
               info.result_aperture_photometry_U_2mm_err = avg_flux_err
            end
         endcase
      endelse
      
   endfor                       ; loop on I, Q, U
endfor                          ; loop on lambda



end
