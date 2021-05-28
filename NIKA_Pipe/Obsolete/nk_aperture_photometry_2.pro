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

pro nk_aperture_photometry_2, param, info, grid
  
if n_params() lt 1 then begin
   message, /info, "Calling sequence: "
   print, "nk_aperture_photometry_2, param, info, grid"
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
   if param.plot_ps eq 0 then begin
      wind, 1, 1, /free, /large, title='nk_aperture_photometry'
      if info.polar eq 0 then begin
         my_multiplot, 1, 2, pp, pp1, /rev
      endif else begin
         my_multiplot, 3, 2, pp, pp1, /rev
      endelse
   endif else begin
      pp  = dblarr(2,2,4)
      pp1 = dblarr(2,4)
   endelse
endif

stokes_par = ["I", "Q", "U"]
grid_tags  = tag_names( grid)
info_tags  = tag_names(info)

for lambda=1, 2 do begin
   for istokes=0, 2 do begin

      ;; Check if the map exists (in particular, are we in polarized mode ?)
      wmap = where( strupcase(grid_tags) eq "MAP_"+stokes_par[istokes]+"_"+strtrim(lambda,2)+"MM", nwmap)
      if nwmap ne 0 then begin
         
         ;; Check if the map is not empty (e.g. "one mm only"...)
         whits = where( strupcase(grid_tags) eq "NHITS_"+strtrim(lambda,2)+"MM", nwhits)
         if max( grid.(whits)) gt 0 then begin
            wvar = where( strupcase(grid_tags) eq "MAP_VAR_"+stokes_par[istokes]+"_"+strtrim(lambda,2)+"MM", nwvar)


            ;; Select valid pixels for the integration
            wpix = where( rmap ge param.aperture_photometry_zl_rmin and $
                          rmap le param.aperture_photometry_zl_rmax and $
                          finite(grid.(wvar)) eq 1 and grid.(wvar) gt 0.d0, nwpix)
            
            ;; Init arrays
            avg_flux     = int_rad*0.d0
            avg_flux_err = int_rad*0.d0
      
            if nwpix eq 0 then begin
               nk_error, info, "No valid pixel for aperture photometry at lambda="+strtrim(lambda,2), status=2
            endif else begin
         
               ;; Subtract zero level
               w8 = 1.d0/(grid.(wvar))[wpix]
               s  = (grid.(wmap))[     wpix]

;;wind, 1, 1, /f
;;plot, grid.(wmap)[*,grid.ny/2], /xs
;;oplot, [-1,1]*1000, [1,1]*mean( (grid.(wmap))[wpix]), col=70
;;oplot, [-1,1]*1000, [1,1]*total(w8*s)/total(w8), col=250

               ;;map = grid.(wmap) - mean( (grid.(wmap))[wpix])
               map = grid.(wmap) - total(w8*s)/total(w8)

               ;; Integrate from the center up to various radii
               nr  = n_elements(int_rad)
               phi = dblarr(nr)
               err = dblarr(nr)
               for i=0, nr-1 do begin
                  wdisk = where(rmap le int_rad[i] and $
                                finite(grid.(wvar)) eq 1 and grid.(wvar) gt 0.d0, nwdisk)
                  if nwdisk ne 0 then begin
                     phi[i] = grid.map_reso^2 * total(       (grid.(wmap))[wdisk])
                     err[i] = grid.map_reso^2 * sqrt( total( (grid.(wvar))[wdisk]))
                  endif
               endfor
               phi /= 2.d0*!dpi*(!nika.fwhm_nom[lambda-1]*!fwhm2sigma)^2 ;*anapar.dif_photo.beam_cor.a
               err /= 2.d0*!dpi*(!nika.fwhm_nom[lambda-1]*!fwhm2sigma)^2 ;*anapar.dif_photo.beam_cor.a

         
               ;; Determine the flux at the requested radius
               avg_flux     = interpol(phi, int_rad, param.aperture_photometry_rmeas)
               avg_flux_err = interpol(err, int_rad, param.aperture_photometry_rmeas)

               if param.do_plot ne 0 then begin
                  delvarx, myposition
                  ;if param.plot_png then myposition = reform(pp[istokes,lambda-1,*])
                  myposition = reform(pp[istokes,lambda-1,*])
                  outplot, file=param.plot_dir+'/aperture_photometry_'+$
                           strtrim(param.scan,2)+"_"+stokes_par[istokes]+"_"+$
                           strtrim(lambda,2)+"mm", png=param.plot_png, ps=param.plot_ps
                  ploterror, int_rad, phi, err, psym=-8, position=myposition, $
                             xtitle='Radius', ytitle='Flux [Jy]', /noerase
                  oplot, [1,1]*param.aperture_photometry_rmeas, [-1e4,1e4], col=250
                  oplot, [0, 1e4], [1,1]*avg_flux, col=250
                  oploterror, [param.aperture_photometry_rmeas], [avg_flux], [avg_flux_err], $
                              col=250, psym=8, errcol=250
                  legendastro, 'Stokes '+stokes_par[istokes], box=0
                  outplot, /close
               endif
            endelse

            ;; Store result in info.
            wtag = where( strupcase(info_tags) eq "RESULT_APERTURE_PHOTOMETRY_"+$
                          strupcase(stokes_par[istokes])+"_"+strtrim(lambda,2)+"MM", nwtag)
            info.(wtag) = avg_flux
            wtag = where( strupcase(info_tags) eq "RESULT_APERTURE_PHOTOMETRY_"+$
                          strupcase(stokes_par[istokes])+"_"+strtrim(lambda,2)+"MM_ERR", nwtag)
            info.(wtag) = avg_flux_err
         endif
      
      endif

   endfor                       ; loop on I, Q, U
endfor                          ; loop on lambda


end
