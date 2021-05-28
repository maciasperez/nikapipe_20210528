;+
;
; SOFTWARE: Real time analysis
;
; NAME:
; nk_map_photometry
;
; CATEGORY: general, RTA
;
; CALLING SEQUENCE:
; 
; PURPOSE: 
;        Computes various quantities on a map: centroid position and gaussian
;fits, background noise, flux at the center...
; 
; INPUT: 
;       - map: the signal map, in Jy (not changed in output)
;       - map_var: the variance map per pix in Jy^2 (not changed in output)
;       - nhits: number of hits per pixel
;       - xmap: map of coordinates in the x direction (arcsec)
;       - ymap: map of coordinates in the y direction (arcsec)
;       - input_fwhm: fwhm of the convolution kernel used to estimate
;                     quantities per beam (arcsec) 
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
;       - NEFD: the noise equivalent flux density, is corrected by
;         noiseup (if keyword set)
;       - Noboost: do not normalize the noise to the dispersion of the map
;                  Use /noboost only in final maps made of many maps (FXD Oct 2017)
;
;       - truncate_map: see nk_truncate_filter_map (to give a map
;         where noise is not apodized)
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - June 4th, 2014: Nicolas Ponthieu
;================================================================================================

pro nk_map_photometry, map, map_var, nhits, xmap, ymap, input_fwhm, $
                       flux, sigma_flux, $
                       sigma_bg, output_fit_par, output_fit_par_error, $
                       bg_rms_source, $
                       flux_center, sigma_flux_center, sigma_bg_center, $
                       sigma_beam_pos=sigma_beam_pos, grid_step=grid_step, $
                       info=info, $
                       map_flux=flux_kgauss, map_var_flux=map_var_flux, $
                       dist_fit=dist_fit, $
                       input_fit_par=input_fit_par, educated=educated, $
                       k_noise=k_noise, noplot=noplot, position=position, $
                       title=title, xtitle=xtitle, ytitle=ytitle, param=param, $
                       NEFD_source=NEFD_source, NEFD_center=NEFD_center, $
                       err_nefd=err_nefd, $
                       imrange=imrange, imzoom=imzoom, $
                       ps_file=ps_file, image_only=image_only, $
                       show_fit=show_fit, $
                       sigma_flux_center_toi=sigma_flux_center_toi, $
                       map_sn_smooth = map_sn, $
                       toi_nefd=toi_nefd, coltable = coltable,  $
                       beam_pos_list = beam_pos_list, time_list=time_list, $
                       charsize=charsize, xcharsize=xcharsize, $
                       ycharsize=ycharsize, inside_bar=inside_bar, $
                       orientation=orientation, $
                       time_matrix_center=time_matrix_center, $
                       time_matrix_source=time_matrix_source, $
                       aperture_phot_contours=aperture_phot_contours, $
                       syst_err=syst_err, short_legend=short_legend, $
                       nobar=nobar, $
                       charbar=charbar, human_obs_time=human_obs_time, $
                       extra_leg_txt=extra_leg_txt, $
                       extra_leg_col=extra_leg_col, $
                       xguess=xguess, yguess=yguess, $
                       guess_fit_par=guess_fit_par, dmax=dmax, $
                       xrange=xrange, yrange=yrange, $
                       source=source, ata_fit_beam_rmax=ata_fit_beam_rmax, $
                       best_model=best_model, map_nefd=map_nefd, $
                       phi_map=phi_map, phi_var_map=phi_var_map, $
                       silent=silent, t_gauss_beam=t_gauss_beam, $
                       sigma_1hit=sigma_1hit, sigma_boost=sigma_boost, $
                       one_mm_correct_integ_time=one_mm_correct_integ_time, $
                       noboost=noboost, $
                       bar_units=bar_units, smooth_fwhm=smooth_fwhm, $
                       commissioning_plot=commissioning_plot, $
                       flux_list=flux_list, sigma_flux_list=sigma_flux_list, $
                       noiseup = noiseup, k_snr = k_snr, $
                       truncate_map = truncate_map

;-
if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   dl_unix, 'nk_map_photometry'
   return
endif

if not keyword_set(grid_step) then begin
   message, /info, "need grid_step in keywords"
   stop
endif
if keyword_set(noiseup) then nup = noiseup else nup = 1.

reso              = abs(xmap[1] - xmap[0])
flux              = 0.d0
sigma_flux        = 0.d0
bg_rms_source     = 0.d0
flux_center       = 0.d0
sigma_flux_center = 0.d0
sigma_bg_center   = 0.d0
nefd_source       = 0.d0
nefd_center       = 0.d0
if not keyword_set(dist_fit) then dist_fit = 40. ; arcsec
if not keyword_set(info) then nk_default_info, info
;; @ Use the input variance map as a starting point to locate the source with
;; @^ mpfit (via nk_fitmap) unless it's already known from input_fit_par.
if keyword_set(input_fit_par) then begin
   output_fit_par = input_fit_par
   output_fit_par_error = input_fit_par*0.d0
endif else begin   
   ;; xx   = reform(xmap[*,0])
   ;; yy   = reform(ymap[0,*])
   w = where( map_var le 0 or finite(map_var) ne 1, nw)
   if keyword_set(xguess) or keyword_set(yguess) then educated = 1
   ;; LP notes: the sigma_guess value will be taken into acount only if guess_fit_par is
   ;; also selected. 
   input_sigma_beam = input_fwhm*!fwhm2sigma
   nk_fitmap, map, map_var, xmap, ymap, output_fit_par, covar, output_fit_par_error, $
              educated=educated, k_noise=k_noise, info=info, status=status, dmax=dmax, $
              xguess=xguess, yguess=yguess, guess_fit_par=guess_fit_par, sigma_guess=input_sigma_beam, map_fit=best_model, $
              silent=silent
   if keyword_set(info) then begin
      if info.status eq 1 then begin
         message, /info, 'Continue without nk_fitmap results'
         info.status = 0
      endif
   endif
endelse


;; @ We compute two point source photometries, one at the source position (fit),
;; @^ one at the center and optionally on other positions.
xc_list = ( [output_fit_par[4], 0.d0] > min(xmap)) < max(xmap)
yc_list = ( [output_fit_par[5], 0.d0] > min(ymap)) < max(ymap)
if keyword_set(beam_pos_list) then begin
   xc_list = [xc_list, reform( beam_pos_list[*,0])]
   yc_list = [yc_list, reform( beam_pos_list[*,1])]
endif
nxc_list        = n_elements(xc_list)
whits           = where( nhits ne 0, nwhits)
flux_list       = dblarr(nxc_list)
sigma_flux_list = dblarr(nxc_list)
time_list       = dblarr(nxc_list)
nn_list         = dblarr(nxc_list)
bg_rms = 0.d0                   ; dummy init
bg_rms_center = 0.d0 ; dummy init
input_sigma_beam = input_fwhm * !fwhm2sigma
;;@ Define the gaussian convolution kernel for output convolved maps
;;@^ and flux maps
kgauss = get_gaussian_kernel( input_fwhm, reso, /nonorm) ; PSF Gaussian kernel

;; @ Use ata_fit to derive the flux and the local background
meth = 2
if defined(param) then meth = param.k_snr_method
;;   message, /info, string(meth)
if meth eq 3 then begin
   nk_ata_fit_beam3, map, map_var, kgauss, info, $  ; inputs (not corrected by nup on exit)
                     flux_kgauss, sigma_flux_kgauss, $; maps of flux and error (contain nup)
                     noiseup = nup
endif else begin                                    ; all other cases
   nk_ata_fit_beam2, map, map_var, kgauss, info, $
                     flux_kgauss, sigma_flux_kgauss ; map of flux and error
endelse

;; wind, 1, 1, /free
;; ;; imview, flux_kgauss, imr=[-1,1]/1000., xmap=xmap, ymap=ymap
;; imview, map, imr=[-1,1]/1000., xmap=xmap, ymap=ymap, fwhm=5.
;; oplot, [output_fit_par[4]], [output_fit_par[5]], psym=1, col=255
;; stop

;; renormalize the error
;; Note: nhits_smooth is a smoothed version of nhits, not a
;; convolution of nhits at the beam scale.
nhits_smooth = convol( nhits, kgauss)/total(kgauss)
if meth eq 3 or keyword_set( truncate_map) then begin
   if not keyword_set( truncate_map) then trunc = nhits_smooth*0+1. else trunc = truncate_map
   whkgauss     = where( trunc gt 0.99 and nhits_smooth ne 0 and sigma_flux_kgauss ne 0. and $
                         finite( flux_kgauss) and finite( sigma_flux_kgauss), nwhkgauss)
   whkgauss2     = where( nhits_smooth ne 0 and sigma_flux_kgauss ne 0. and $
                         flux_kgauss ne 0. and finite( flux_kgauss) and finite( sigma_flux_kgauss), nwhkgauss2)
endif else begin
   whkgauss     = where( nhits_smooth ne 0 and sigma_flux_kgauss ne 0. and $
                         finite( flux_kgauss) and finite( sigma_flux_kgauss), nwhkgauss)
   whkgauss2 = whkgauss
   nwhkgauss2 = nwhkgauss
endelse

if keyword_set(commissioning_plot) then begin
   wind, 1, 1, /free, /large
   np_histo, flux_kgauss[whkgauss]/sigma_flux_kgauss[whkgauss], /fill, /fit, $
             xtitle='SNR per pixel', min=-7, max=7, colorfit=250, thick=2

;   outplot, file='sigma_boost', /ps
   np_histo, flux_kgauss[whkgauss]/sigma_flux_kgauss[whkgauss], /fill, /fit, $
             xtitle='SNR per pixel', min=-7, max=7, colorfit=250, thick=2
;   outplot, /close, /verb
endif

if keyword_set(param) then begin
   if param.g2_paper eq 1 then begin
      wind, 1, 1, /free, /large
      my_multiplot, 2, 3, pp, pp1, /rev, ymin=0.05, ymax=0.97
      np_histo, flux_kgauss[whkgauss]/sigma_flux_kgauss[whkgauss], /fill, /fit, $
                xtitle='SNR Flux on all map pixels', min=-7, max=7, colorfit=250, thick=2, $
                position=pp1[0,*]
      
      w = where( nhits ge median(nhits[where(nhits ne 0)]))
      np_histo, flux_kgauss[w]/sigma_flux_kgauss[w], /fill, /fit, $
                xtitle='SNR Flux where nhits > median(nhits)', min=-7, max=7, colorfit=250, thick=2, $
                position=pp1[1,*], fcolor=150, /noerase
      
      np_histo, map[w]/sqrt(map_var[w]), /fill, /fit, $
                xtitle='SNR raw map where nhits > median(nhits)', min=-7, max=7, colorfit=250, thick=2, $
                position=pp1[2,*], fcolor=200, /noerase


      sigma_eff = stddev( flux_kgauss[w])
      np_histo, flux_kgauss[w]/sigma_eff, /fill, /fit, $
                xtitle='norm to stddev(flux_kgauss)', min=-7, max=7, $
                colorfit=250, thick=2, position=pp1[3,*], /noerase, fcolor=100

      mm = convol( map, kgauss)/total(kgauss^2)
      mm_var = convol( map_var, kgauss^2)/total(kgauss^2)^2
      mm_std = sqrt( mm_var)
      np_histo, mm[w]/mm_std[w], /fill, /fit, $
                xtitle='Analytical convol, no bg sub', min=-7, max=7, $
                colorfit=250, thick=2, position=pp1[4,*], /noerase, fcolor=40


      bg = avg(mm[w])
      np_histo, (mm[w]-bg)/mm_std[w], /fill, /fit, $
                xtitle='Analytical convol and bg sub', min=-7, max=7, $
                colorfit=250, thick=2, position=pp1[5,*], /noerase, fcolor=80

      stop
   endif
endif

;; @ Compare the current SNR distribution to a normalized gaussian to
;; @^ derive sigma_boost
avg_boost = 0.d0
;; if keyword_set(noboost) then begin
;;    sigma_boost = 1.d0
;; endif else begin
histo_make, flux_kgauss[ whkgauss]/sigma_flux_kgauss[ whkgauss], $
            /gauss, n_bin = 301, minval = -10, maxval = +10, $
            xarr, yarr, stat_res, gauss_res
sigma_boost = gauss_res[1]
if not keyword_set(noboost) then begin
   sigma_flux_kgauss = sigma_flux_kgauss * sigma_boost
   avg_boost   = gauss_res[0]
endif
;help, keyword_set( noboost), avg_boost, sigma_boost
whk     = where( nhits ne 0 and map_var ne 0. and $
                 map ne 0. and $
                 finite( map) and $
                 finite( map_var), nwhk)

;; for the record
whits_temp = where( nhits ge median(nhits[where(nhits ne 0)]))
sigma_1hit = stddev( map[whits_temp]*sqrt(nhits[whits_temp]))

; Change the zero level as well
;; zerolev = median( gauss_res[0]*sigma_flux_kgauss[ whkgauss])
zerolev = median( avg_boost*sigma_flux_kgauss[ whkgauss])
if not keyword_set(noboost) then flux_kgauss = flux_kgauss - zerolev

; Do not change inputs (as a rule)
; Change inputs  FXD adds nup here (2Oct2020) (only if nup ne 1 to
; avoid causing damage to others)
;; if nwhk ne 0 and nup ne 1. then begin
;;    map[ whk] = (map[ whk]  - zerolev)*nup 
;;    map_var[ whk] = (map_var[ whk] * sigma_boost^2)*nup^2 
;; ;help, zerolev, sigma_boost, nup
;; endif

;; @ Update the flux SNR map
map_sn            = map_var*0.d0
if nwhkgauss2 ne 0 then map_sn[ whkgauss2] = flux_kgauss[ whkgauss2] / sigma_flux_kgauss[ whkgauss2]
map_nefd = sigma_flux_kgauss * sqrt( nhits_smooth/!nika.f_sampling*(grid_step/reso)^2)
map_var_flux = map_var*0.d0
if nwhkgauss2 ne 0 then map_var_flux[ whkgauss2] = sigma_flux_kgauss[ whkgauss2]^2

; High flux end may have been altered by noiseup: put it down to keep
; photometry of strond sources intact. An empirical formula that goes
; smoothly from 1/noiseup at high snr to 1. at low snr. Can only be
; done with coadded maps (not individual scans), hence the keyword k_snr
if keyword_set( param.keep_only_high_snr) and keyword_set( k_snr) then begin
   wp = where( map_sn gt param.keep_only_high_snr, nwp)
   if nwp ne 0 then flux_kgauss[ wp] = (sigma_flux_kgauss[ wp] * param.keep_only_high_snr) + $
        (flux_kgauss[ wp] - (sigma_flux_kgauss[ wp] * param.keep_only_high_snr)) / nup
   wn = where( map_sn lt -param.keep_only_high_snr, nwn)
   if nwn ne 0 then flux_kgauss[ wn] = -(sigma_flux_kgauss[ wn] * param.keep_only_high_snr) + $
        (flux_kgauss[ wn] + (sigma_flux_kgauss[ wn] * param.keep_only_high_snr)) / nup
; Do not correct map
   map_sn[ whkgauss2] = flux_kgauss[ whkgauss2] / sigma_flux_kgauss[ whkgauss2]
endif else begin
   ;; Corrects the flux down to have proper photometry of strong sources
   flux_kgauss = flux_kgauss / nup
endelse 
; This is an old approximate version (valid till 20th Oct 2020 FXD)
;; if keyword_set( k_snr) then begin
;;    flux_kgauss = flux_kgauss * (nup+k_snr*map_sn^2)/(1D0 + k_snr*map_sn^2) / nup
;;    map =         map         * (nup+k_snr*map_sn^2)/(1D0 + k_snr*map_sn^2) / nup
;;    map_sn[ whkgauss2] = flux_kgauss[ whkgauss2] / sigma_flux_kgauss[ whkgauss2]
;; endif else begin
;;    ;; Corrects the flux down to have proper photometry of strong sources
;;    flux_kgauss = flux_kgauss / nup
;; endelse 

; FXD 5th October (this computation of nefd above is contaminated by
; signal, this method below is safer).
;;;;; if keyword_set(noboost) then begin
; Here say that the previous method is                                                                       
; contaminated by real signal so we just propagate the noise from                                            
; individual scans (which have already                                 ; been
; boosted anyway)
sigmed = min( sigma_flux_kgauss[ whkgauss])
nhitmed = max( nhits_smooth)
whfx     = where( nhits_smooth ge nhitmed/5. and sigma_flux_kgauss ne 0. and $
                  finite( sigma_flux_kgauss) and $
                  sigma_flux_kgauss lt 3.*sigmed, nwhk)

map_nefd = map_var*0.d0
if nwhk gt 10 then begin
   ;; histo_make, $
   ;;    sqrt( nhits_smooth[whfx])*sigma_flux_kgauss[whfx], $
   ;;    /gauss, n_bin = 301, xarr, yarr, $
   ;;    stat_resboost, gauss_resboost
;; FXD Jan 2021
;; In some cases the Gaussian is not found in the histogram
   ;; this leads to  a wrong value with
   ;; sigma_1hf = gauss_resboost[0] ; mean value
   ;; This happens especially with A1 because the array is so
   ;; inhomogeneous
   ; So we make an exact estimate (but within the clipping above)
   sigma_1hf = 1./ sqrt( mean( (sqrt( nhits_smooth[whfx])* $
                                 sigma_flux_kgauss[whfx])^(-2)))
   ; is more precise than the robust:
   ; median(sqrt( nhits_smooth[whfx])*sigma_flux_kgauss[whfx])
; it corresponds to having the inverse weighing scheme in order to
; measure an average NEFD across all detectors.

;;    nefd = sigma_1hf*(grid_step/reso)/sqrt(!nika.f_sampling) $
;;           /sqrt( array_eff)
   ;; No more array eff in the NEFD definition, NP. Oct. 31st
   
   nefd = sigma_1hf*(grid_step/reso)/sqrt(!nika.f_sampling)
   map_nefd[ whfx] =  nefd      ; constant where defined

   ;; Need to account for the number of hits (~time of observation)
   ;; per pixel ?! Nico Aug. 2020
   ;; this line seems to be never used anyway since noboost is
   ;; systematically off ?
   ;; map_nefd[whfx] = sigma_1hf * sqrt( nhits_smooth[whfx]/!nika.f_sampling*(grid_step/reso)^2)
;;;;endif
endif

;; @ Take a conservative estimate of the error on the NEFD.
;; Not the histo or stddev, the points are not independent after the
;; convolution by the beam kernel
ww = where( map_nefd ne 0, nw)
if nw ne 0 then err_nefd = max(map_nefd[ww])-min(map_nefd[ww])  ; is 0 now

;;@ Measure the point source flux on the listed positions
for ipos=0, nxc_list-1 do begin

   ;; Determine weights for point source photometry
   dd = sqrt( (xmap-xc_list[ipos])^2 + (ymap-yc_list[ipos])^2)
   gauss_w8 = exp( -dd^2/(2.d0*input_sigma_beam^2))

   ;; @ To fit the background on a small region around the source and
   ;; @^ then avoid large scale residuals, we can specify a maximum
   ;; @^ distance to the centroid for nk_ata_fit_beam.
   if keyword_set(ata_fit_beam_rmax) gt 0.d0 then begin
      w = where( dd gt ata_fit_beam_rmax, nw)
      if nw ne 0 then gauss_w8[w] = 0.d0
   endif
   
   ii      = nint(xc_list[ ipos]/reso+n_elements( flux_kgauss[*, 0])/2)
   jj      = nint(yc_list[ ipos]/reso+n_elements( flux_kgauss[0, *])/2)
   f       = flux_kgauss[ ii, jj]
   sigma_f = sigma_flux_kgauss[ii,jj] ; sqrt(map_var_flux[ ii, jj])

   if info.status ne 0 then noatainfo = 1 else noatainfo = 0
   if noatainfo eq 1 then begin
      info.status = 0
      message, /info, 'No fixed gaussian fit could be performed. Go on'
   endif
   if noatainfo eq 1 then break ; FXD
      
   ;; Store result
   flux_list[      ipos] = f
   sigma_flux_list[ipos] = sigma_f
   time_list[      ipos] = nhits_smooth[ii,jj]/!nika.f_sampling*(grid_step/reso)^2
;;   nn_list[        ipos] = total(nhits[whits])/( total(nhits[whits])*total(gauss_w8[whits]^2*nhits[whits])-$
;;                                                 total(gauss_w8[whits]*nhits[whits])^2)
endfor

;; Sort output
flux              = flux_list[      0]
sigma_flux        = sigma_flux_list[0]
flux_center       = flux_list[      1]
sigma_flux_center = sigma_flux_list[1]

;; ;; Derive error on the center flux from the fluxes measured at beam_pos_list
sigma_beam_pos = 0.d0
;; if keyword_set(beam_pos_list) then begin
;;    stddev_pos = stddev(sqrt(nn_list[2:*])*flux_list[2:*])
;;    sigma_beam_pos = stddev_pos * sqrt(nn_list[1])
;;    if keyword_set(syst_err) then $
;;       sigma_beam_pos = sqrt((stddev_pos * sqrt(nn_list[1]))^2 + $
;;                             (0.1*flux)^2 + (0.05*flux)^2 + (0.02*flux)^2) ;; taking into account for the systematic errors
;; endif

;; @ Derive NEFD's.
if keyword_set(grid_step) then begin

   ;; At the center
   dist_center        = sqrt( xmap^2 + ymap^2)
   w                  = (where( dist_center eq min(dist_center)))[0]
   time_matrix_center = nhits_smooth[w]/!nika.f_sampling*(grid_step/reso)^2
   nefd_center = map_nefd[w]

   ;; Effective "time per beam"
   gauss_w8 = exp( -dist_center^2/(2.d0*input_sigma_beam^2))
   w = where( nhits ne 0, nw)
   tt = nhits/!nika.f_sampling
   t_gauss_beam = 1./( (1./total(gauss_w8[w]^2))^2*total( gauss_w8[w]^2/tt[w]))

   ;; Around the source
   dist_source        = sqrt( (xmap-output_fit_par[4])^2 + (ymap-output_fit_par[5])^2)
   w                  = (where( dist_source eq min(dist_source)))[0]
   time_matrix_source = nhits_smooth[w]/!nika.f_sampling*(grid_step/reso)^2
   nefd_source = map_nefd[w]
endif

if keyword_set(one_mm_correct_integ_time) then begin
   nefd_center /= sqrt(2.)
   nefd_source /= sqrt(2.)
endif

if not keyword_set(coltable) then coltable = 1

if not keyword_set(noplot) then begin
   phi = dindgen(200)/199*2*!dpi
   xx  = output_fit_par[2]*cos(phi)/!fwhm2sigma/2. ; apparent diam = FWHM
   yy  = output_fit_par[3]*sin(phi)/!fwhm2sigma/2. ; apparent diam = FWHM
   xx1 = cos(output_fit_par[6])*xx - sin(output_fit_par[6])*yy
   yy1 = sin(output_fit_par[6])*xx + cos(output_fit_par[6])*yy
   mamdlib_coltable_old = !mamdlib.coltable
   !mamdlib.coltable = coltable
   w = where( map_var gt 0, nw, compl=wcompl, ncompl=nwcompl)
   if nw eq 0 then begin
      message, /info, "no pixel with variance > 0 to compute imrange."
      stop
   endif
   var_med = median( map_var[w])
   if not keyword_set(imrange) then imrange = [-1,1]*4*stddev( map[where( map_var le var_med and map_var gt 0)]) 
   if not(keyword_set(imzoom)) then begin
      imview, map, xmap=xmap, ymap=ymap, position=position, /noerase, imrange=imrange, $
              title=title, xtitle=xtitle, ytitle=ytitle, /noclose, postscript=ps_file, charsize=charsize, $
              xcharsize=xcharsize, ycharsize=ycharsize, inside_bar=inside_bar, orientation=orientation, nobar=nobar, $
              charbar=charsize, xrange=xrange, yrange=yrange, units=bar_units, fwhm=smooth_fwhm
      if keyword_set(source) then legendastro, source, box=0, /right, textcol=255
   endif else begin
      ;; display a sub-map of 2x2 arcmin square size
      x0=0.
      if keyword_set(xguess) then x0=xguess
      y0=0.
      if keyword_set(yguess) then y0=yguess
      xmin = max([min(xmap),x0-60.])
      xmax = min([max(xmap),x0+60.])
      ymin = max([min(ymap),y0-60.])
      ymax = min([max(ymap),y0+60.])
      imview, map, xmap=xmap, ymap=ymap, xr=[xmin, xmax], yr=[ymin, ymax], position=position, /noerase, $
              imrange=imrange, title=title, xtitle=xtitle, ytitle=ytitle, /noclose, postscript=ps_file, charsize=charsize, $
              xcharsize=xcharsize, ycharsize=ycharsize, inside_bar=inside_bar, orientation=orientation, nobar=nobar, $
              charbar=charsize, fwhm=smooth_fwhm
   endelse

   theta = dindgen(200)/199.*2.d0*!dpi

   if (not keyword_set(image_only)) or keyword_set(show_fit) then begin
      if coltable eq 3 then myct = 70 else myct=250
      loadct, 39, /silent
      oplot, [0], [0], psym=1, col=150
      oplot, 0.5*input_fwhm*cos(phi), 0.5*input_fwhm*sin(phi), col=150
      oplot, output_fit_par[4] + xx1, output_fit_par[5] + yy1, col=myct
      oplot, [output_fit_par[4]], [output_fit_par[5]], psym=1, col=myct

      nxc = n_elements(xc_list)
      if nxc gt 1 then begin
         for ii=1, nxc-1 do begin
            oplot, [xc_list[ii]], [yc_list[ii]], psym=1, col=0
         endfor
      endif

      if keyword_set(beam_pos_list) then oplot, beam_pos_list[*, 0], beam_pos_list[*, 1], psym = 1, col = 255
      loadct, 39,  /silent
      if defined(param) then begin
         if param.do_aperture_photometry then begin
            oplot, param.aperture_photometry_zl_rmin*cos(theta), $
                   param.aperture_photometry_zl_rmin*sin(theta), line=2, col=150
            oplot, param.aperture_photometry_zl_rmax*cos(theta), $
                   param.aperture_photometry_zl_rmax*sin(theta), line=2, col=150
            oplot, param.aperture_photometry_rmeas*cos(theta), $
                   param.aperture_photometry_rmeas*sin(theta), line=2, col=myct
         endif
      endif
   endif

   x_coor = 'x'
   y_coor = 'y'
   if keyword_set(param) then begin
      if strupcase( param.map_proj) eq "RADEC" then begin
         x_coor = "RA"
         y_coor = "Dec"
      endif
      if strupcase( param.map_proj) eq "AZEL" then begin
         x_coor = "az"
         y_coor = "el"
      endif
   endif

   if not keyword_set(image_only) then begin
      fwhm1 = output_fit_par[2]/!fwhm2sigma
      fwhm2 = output_fit_par[3]/!fwhm2sigma
      legendastro, ['!7D!3'+x_coor+' '+num2string(output_fit_par[4]), $
                    '!7D!3'+y_coor+' '+num2string(output_fit_par[5]), $
                    'Peak '+num2string(output_fit_par[1]), $
                                ;'FWHM '+num2string( sqrt(output_fit_par[2]*output_fit_par[3])/!fwhm2sigma)], $
                    'FWHM '+string(fwhm1,format="(F5.2)")+"x"+$
                    string(fwhm2,format="(F5.2)")+" = "+$
                    string(sqrt(fwhm1*fwhm2),format="(F5.2)")], $
                    textcol=255, box=0, charsize=charsize
      
      if abs(flux_center) lt 0.1 then begin
         flux_units = 'mJy'
         flux_disp              = 1000*flux
         flux_center_disp       = 1000*flux_center
         sigma_flux_disp        = 1000*sigma_flux
         sigma_flux_center_disp = 1000*sigma_flux_center
      endif else begin
         flux_units = 'Jy'
         flux_disp              = flux
         flux_center_disp       = flux_center
         sigma_flux_disp        = sigma_flux
         sigma_flux_center_disp = sigma_flux_center
      endelse

      if keyword_set(extra_leg_txt) then $
         legendastro, extra_leg_txt, box=0, /right, textcol=extra_leg_col, chars=charsize

      leg_txt = ['Flux = '+num2string( flux_disp)+" +- "+num2string(sigma_flux_disp)+" "+flux_units, $
                 'Flux (center) = '+num2string(flux_center_disp)+" +- "+num2string(sigma_flux_center_disp)+" "+flux_units]
      textcol = [250, 150]
      if not keyword_set(short_legend) then begin
         leg_txt = [leg_txt, $
                    'NEFD (source) = '+ string(  nefd_source*1000, format = '(F5.0)')+' mJy.s1/2', $
                    'NEFD (center) = '+ string(  nefd_center*1000, format = '(F5.0)')+' mJy.s1/2'];, $
         textcol = [textcol, 250, 150]
      endif
   
      legendastro, /bottom, box=0, leg_txt, textcol=textcol, charsize=charsize

   endif
   if keyword_set(ps_file) then close_imview
endif

sigma_bg = -1 ; place holder
sigma_bg_center  =-1


;; restore
if defined(mamdlib_coltable_old) then !mamdlib.coltable = mamdlib_coltable_old

ciao:
end
