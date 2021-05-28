;+
;PURPOSE: Fit the beam with 3 gaussian components
;
;INPUT: resolution, map_flux and noise_map 
;
;OUTPUT: print the best fit values
;
;KEYWORDS: 
;   - best_fit: the best fit map
;   - coeff: the best fit coefficients
;   - center: the shift of the source from the map center
;   - silent: set this keyword if you do not want to print anything
;
;LAST EDITION: 
;   25/09/2013: creation (adam@lpsc.in2p3.fr)
;-

function fit_triple_gaussian_beam, x, p
  return, p[0]*exp(-x^2/2/(p[1]*!fwhm2sigma)^2) + $
          p[2]*exp(-x^2/2/(p[3]*!fwhm2sigma)^2) + $
          p[4]*exp(-x^2/2/(p[5]*!fwhm2sigma)^2) 
end

pro nika_anapipe_triple_beam_fit, reso, map, noise_map, $
                                  coeff=coeff, $
                                  ;;                        coeff[0]   Gaussian1 peak value
                                  ;;                        coeff[1]   Gaussian1 FWHM value
                                  ;;                        coeff[2]   Gaussian2 peak value
                                  ;;                        coeff[3]   Gaussian2 FWHM value
                                  ;;                        coeff[4]   Gaussian3 peak value
                                  ;;                        coeff[5]   Gaussian3 FWHM value
                                  center=center, $         ;Provides the center of the source (arcsec)
                                  best_fit=best_fit, $     ;Best fit map
                                  silent=silent, $         ;Set this keyword for not printing the best fit results
                                  amp1=amp1, $             ;If set the amplitude of gaussian 1 fixed, coeff[0]
                                  FWHM1=FWHM1, $           ;If set the FWHM of gaussian 1 fixed,coeff[1]
                                  amp2=amp2, $             ;If set the amplitude of gaussian 2 fixed, coeff[2]
                                  FWHM2=FWHM2, $           ;If set the FWHM of gaussian 2 fixed,coeff[3]
                                  amp3=amp3, $             ;If set the amplitude of gaussian 3 fixed, coeff[4]
                                  FWHM3=FWHM3              ;If set the FWHM of gaussian 3 fixed,coeff[5]

  ;;------- Variables theta
  nx = (size(map))[1]
  ny = (size(map))[2]

  xmap = (replicate(1, ny) ## dindgen(nx)) - (nx-1)/2.0
  ymap = (replicate(1, nx) #  dindgen(ny)) - (ny-1)/2.0
  if keyword_set(center) then xmap -= center[0]/reso
  if keyword_set(center) then xmap -= center[1]/reso
  rmap = sqrt(xmap^2 + ymap^2)  
  
  p0 = [1.0, 15.0/reso, 0.1, 60.0/reso, 0.01, 200.0/reso]

  ;;------- Contraintes sur param
  parinfo = replicate({value:0.D,fixed:0}, 6)

  if keyword_set(amp1) then parinfo[0].fixed = 1
  if keyword_set(amp1) then parinfo[0].value = amp1
  if keyword_set(amp1) then p0[0] = amp1
  if keyword_set(FWHM1) then parinfo[1].fixed = 1
  if keyword_set(FWHM1) then parinfo[1].value = FWHM1/reso
  if keyword_set(FWHM1) then p0[1] = FWHM1/reso
  if keyword_set(amp2) then parinfo[2].fixed = 1 
  if keyword_set(amp2) then parinfo[2].value = amp2
  if keyword_set(amp2) then p0[2] = amp2
  if keyword_set(FWHM2) then parinfo[3].fixed = 1
  if keyword_set(FWHM2) then parinfo[3].value = FWHM2/reso
  if keyword_set(FWHM2) then p0[3] = FWHM2/reso
  if keyword_set(amp3) then parinfo[4].fixed = 1 
  if keyword_set(amp3) then parinfo[4].value = amp3
  if keyword_set(amp3) then p0[4] = amp3
  if keyword_set(FWHM3) then parinfo[5].fixed = 1 
  if keyword_set(FWHM3) then parinfo[5].value = FWHM3/reso
  if keyword_set(FWHM3) then p0[5] = FWHM3/reso
    
  ;;----- Fit the model
  error = noise_map
  bad_loc = where(finite(error) ne 1 or error le 0, nbad_loc)
  if nbad_loc ne 0 then error[bad_loc] = max(error,/nan)*1e5

  coeff = mpfitfun('fit_triple_gaussian_beam', rmap, map, error, p0, $
                   parinfo=parinfo, yfit=best_fit, AUTODERIVATIVE=1, /QUIET)
  
  ;;----- Change pixels to arcsec
  coeff[1] *= reso
  coeff[3] *= reso
  coeff[5] *= reso

  ;;----- Fit
  if not keyword_set(silent) then begin
     print, '------------------------------------------'
     print, '--- Triple gaussian beam model -----------'
     print, '--------- Best fit parametres : ----------'
     print, '--------- Amplitude of the main beam : ', coeff[0]
     print, '--------- FWHM of the main beam: ', coeff[1], '  arcsec'
     print, '--------- Amplitude of the second beam: ', coeff[2]
     print, '--------- FWHM of the second beam: ', coeff[3], '  arcsec'
     print, '--------- Amplitude of the second beam: ', coeff[4]
     print, '--------- FWHM of the second beam: ', coeff[5], '  arcsec'
     print, '------------------------------------------'
  endif

  return
end
