
;+
;
; SOFTWARE: Real time analysis
;
; NAME:
; nk_map_photometry_2
;
; CATEGORY: general, RTA
;
; CALLING SEQUENCE:
; 
; PURPOSE: 
;        Wrapper to nk_map_photometry, directly from a grid structure
; 
; INPUT: 
;       - grid: a structure containing signal, coordinates and variance maps
; 
; OUTPUT: 
;       - flux: Computed where the gaussian is fit (Jy)
;       - sigma_flux: Error on Flux (Jy)
;       - sigma_bg: noise per beam estimated on the map background far from the
;         fitted gaussian (Jy)
;       - output_fit_par: parameter of the fitted gaussian
;       - output_fit_par_error: errors on output_fit_par
;       - bg_rms: background rms of the map (on a representative subset of the pixels)
;       - flux_center: flux at the center of the map (Jy)
;       - sigma_flux_center: error on the flux at the center (Jy)
;       - integ_time_center: integration time on a disk of XXX diameter at the center of the map
; 
; KEYWORDS:
;       - map_conv: the input map convolved by the input beam (useful to enhance
;                   a weak point source on a display)
;       - input_fit_par: to force gaussian fit parameters (position, widths...)
;                        to estimate fluxes at the desired locations
;       - educated, k_noise : see nk_fitmap.pro
;       - noplot: prevents displays
;       - position: display position
;       - title, xtitle, ytitle: plot keywords
;       - lambda: mandatory to compute the NEFD
;       - NEFD: the noise equivalent flux density
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - June 16th, 2015: Nicolas Ponthieu
;        - Oct. 15th, 2015: NP, to work with 3 arrays (NIKA2) and
;          compute photometry on all available maps.
;-
;================================================================================================

pro nk_map_photometry_3, grid, input_fwhm=input_fwhm, $
                         flux, sigma_flux, $
                         sigma_bg, output_fit_par, output_fit_par_error, $
                         bg_rms_source, flux_center, sigma_flux_center, sigma_bg_center, $
                         integ_time_center, sigma_beam_pos, $
                         map_conv=map_conv, dist_fit=dist_fit, $
                         input_fit_par=input_fit_par, educated=educated, $
                         k_noise=k_noise, noplot=noplot, position=position, $
                         title=title, xtitle=xtitle, ytitle=ytitle, param=param, $
                         NEFD_source=NEFD_source, NEFD_center=NEFD_center, imrange=imrange, $
                         ps_file=ps_file, image_only=image_only, total_obs_time=total_obs_time, $
                         sigma_flux_center_toi=sigma_flux_center_toi, map_sn_smooth = map_sn_smooth, $
                         array=array, toi_nefd=toi_nefd, coltable = coltable,  beam_pos_list = beam_pos_list, info=info, $
                         charsize=charsize, xcharsize=xcharsize, ycharsize=ycharsize, inside_bar=inside_bar, $
                         orientation=orientation, $
                         time_matrix_center=time_matrix_center, time_matrix_source=time_matrix_source, q=q, u=u, syst_err = syst_err

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_map_photometry_3, grid, input_fwhm=input_fwhm, $"
   print, "                     flux, sigma_flux, $"
   print, "                     sigma_bg, output_fit_par, output_fit_par_error, $"
   print, "                     bg_rms_source, flux_center, sigma_flux_center, sigma_bg_center, $"
   print, "                     integ_time_center, sigma_beam_pos, $"
   print, "                     map_conv=map_conv, dist_fit=dist_fit, $"
   print, "                     input_fit_par=input_fit_par, educated=educated, $"
   print, "                     k_noise=k_noise, noplot=noplot, position=position, $"
   print, "                     title=title, xtitle=xtitle, ytitle=ytitle, param=param, $"
   print, "                     NEFD_source=NEFD_source, NEFD_center=NEFD_center, imrange=imrange, $"
   print, "                     ps_file=ps_file, image_only=image_only, total_obs_time=total_obs_time, $"
   print, "                     sigma_flux_center_toi=sigma_flux_center_toi, map_sn_smooth = map_sn_smooth, $"
   print, "                     array=array, toi_nefd=toi_nefd, coltable = coltable,  beam_pos_list = beam_pos_list, info=info, $"
   print, "                     charsize=charsize, xcharsize=xcharsize, ycharsize=ycharsize, inside_bar=inside_bar, $"
   print, "                     orientation=orientation, $"
   print, "                     time_matrix_center=time_matrix_center, time_matrix_source=time_matrix_source, q=q, u=u"
   return
endif


flux                 = dblarr(12)                ; I1, I2, I3, Q1, Q2, Q3, U1, U2, U3, I_1mm, Q_1mm, U_1mm
sigma_flux           = dblarr(12)
sigma_bg             = dblarr(12)
output_fit_par       = dblarr(12,7)
output_fit_par_error = dblarr(12,7)
bg_rms_source        = dblarr(12)
flux_center          = dblarr(12)
sigma_flux_center    = dblarr(12)
sigma_bg_center      = dblarr(12)
time_matrix_center   = dblarr(12)

if keyword_set(title) then title_ext = title else title_ext=''

stokes = ['I', 'Q', 'U']
grid_tags = tag_names(grid)

narrays = 3
nstokes = 1 ;; I at least
for iarray=1, 3 do begin
   w = where( strupcase(grid_tags) eq "MAP_VAR_Q"+strtrim(iarray,2), nw)
   if nw ne 0 then nstokes=3
endfor
;; narrays for arrays 1, 2, 3 + 1 for the combined 1mm
my_multiplot, narrays+1, nstokes, pp, pp1, /rev


for iarray=1, 3 do begin
   for istokes=0, 2 do begin
      wmap = where( strupcase(grid_tags) eq "MAP_"+stokes[istokes]+strtrim(iarray,2), nwmap)
      if nwmap ne 0 then begin
         whits = where( strupcase(grid_tags) eq "NHITS_"+strtrim(iarray,2), nwhits)
         if max(grid.(whits)) gt 0 then begin
            wvar = where( strupcase(grid_tags) eq "MAP_VAR_"+stokes[istokes]+strtrim(iarray,2), nwmap)

            t1 = 1d0 ; init
            nk_map_photometry, grid.(wmap), grid.(wvar), grid.(whits), $
                               grid.xmap, grid.ymap, !nika.fwhm_array[iarray-1], $
                               flux_1mm, sigma_flux_1mm, $
                               sigma_bg_1mm, output_fit_par_1mm, output_fit_par_error_1mm, $
                               bg_rms_1mm, flux_center_1mm, sigma_flux_center_1mm, sigma_bg_center_1mm, $
                               integ_time_center,  sigma_beam_pos,  $
                               coltable=coltable, imrange=imrange_i_1mm, $
                               educated=educated, title=title_ext+' A'+strtrim(iarray,2), $
                               ps_file=ps_file, position=pp[iarray-1, istokes,*], $
                               k_noise=k_noise, param=param, noplot=noplot, image_only=image_only, $
                               NEFD_source=nefd_1mm, info=info, beam_pos_list =  beam_pos_list, syst_err = syst_err, $
                               time_matrix_center=t1, input_fit_par=input_fit_par, grid_step=!nika.grid_step[iarray-1]
            print, "iarray, istokes, nefd_source: ", iarray, " ", istokes, " ", nefd_1mm

            ipos = (iarray-1)*3+istokes
            time_matrix_center[   ipos] = t1
            flux[                 ipos] = flux_1mm
            sigma_flux[           ipos] = sigma_flux_1mm
            sigma_bg[             ipos] = sigma_bg_1mm
            output_fit_par[       ipos,*] = output_fit_par_1mm
            output_fit_par_error[ ipos,*] = output_fit_par_error_1mm
            bg_rms_source[        ipos  ] = bg_rms_1mm
            flux_center[          ipos  ] = flux_center_1mm
            sigma_flux_center[    ipos  ] = sigma_flux_center_1mm
            sigma_bg_center[      ipos  ] = sigma_bg_center_1mm

         endif
      endif
   endfor
endfor

;; Deal with the combined 1mm maps
for istokes=0, 2 do begin
   wmap = where( strupcase(grid_tags) eq "MAP_"+stokes[istokes]+"_1MM", nwmap)
   whits = where( strupcase(grid_tags) eq "NHITS_1MM", nwhits)
   if max(grid.(whits)) gt 0 and nwmap ne 0 then begin
      wvar = where( strupcase(grid_tags) eq "MAP_VAR_"+stokes[istokes]+"_1MM", nwmap)

      t1 = 1d0                  ; init
      nk_map_photometry, grid.(wmap), grid.(wvar), grid.(whits), $
                         grid.xmap, grid.ymap, !nika.fwhm_array[0], $
                         flux_1mm, sigma_flux_1mm, $
                         sigma_bg_1mm, output_fit_par_1mm, output_fit_par_error_1mm, $
                         bg_rms_1mm, flux_center_1mm, sigma_flux_center_1mm, sigma_bg_center_1mm, $
                         integ_time_center,  sigma_beam_pos,  $
                         coltable=coltable, imrange=imrange_i_1mm, $
                         educated=educated, title=title_ext+' A'+strtrim(iarray,2), $
                         ps_file=ps_file, position=pp[iarray-1, istokes,*], $
                         k_noise=k_noise, param=param, noplot=noplot, image_only=image_only, $
                         NEFD_source=nefd_1mm, info=info, beam_pos_list =  beam_pos_list, syst_err = syst_err, $
                         time_matrix_center=t1, input_fit_par=input_fit_par, grid_step=!nika.grid_step[0]

      print, "NEFD source: ", nefd_1mm

      ipos = 10 + istokes
      time_matrix_center[   ipos] = t1
      flux[                 ipos] = flux_1mm
      sigma_flux[           ipos] = sigma_flux_1mm
      sigma_bg[             ipos] = sigma_bg_1mm
      output_fit_par[       ipos,*] = output_fit_par_1mm
      output_fit_par_error[ ipos,*] = output_fit_par_error_1mm
      bg_rms_source[        ipos  ] = bg_rms_1mm
      flux_center[          ipos  ] = flux_center_1mm
      sigma_flux_center[    ipos  ] = sigma_flux_center_1mm
      sigma_bg_center[      ipos  ] = sigma_bg_center_1mm
   endif
endfor

end
