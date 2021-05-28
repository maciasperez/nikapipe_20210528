;+
;PURPOSE: Fit the main beam + the plateau modeled as a disk convolved
;         with a gaussian
;
;INPUT: resolution, map_flux and noise_map 
;
;OUTPUT: print the best fit values
;
;KEYWORDS: see below
;
;LAST EDITION: 
;   25/09/2013: creation (adam@lpsc.in2p3.fr with help from Lilian Sanselm)
;   26/09/2013: add parinfo keywords (adam@lpsc.in2p3.fr)
;-

function fit_plateau_plus_main_beam, x, p
  return, p[0] + p[1]*exp(-x^2/2.0/(p[2]*!fwhm2sigma)^2) + p[3]*(erf(-(x-p[4])/2/p[5])+1)/2
end

pro nika_anapipe_fitplateau, reso, map, noise_map, $
                             coeff=coeff, $
                             ;;                        coeff[0]   Constant baseline level
                             ;;                        coeff[1]   Gaussian peak value
                             ;;                        coeff[2]   Gaussian FWHM value
                             ;;                        coeff[3]   Plateau amplitude
                             ;;                        coeff[4]   Plateau angular extension
                             ;;                        coeff[5]   Plateau decay length
                             center=center, $         ;Provides the center of the source (arcsec)
                             best_fit=best_fit, $     ;Best fit map
                             silent=silent, $         ;Set this keyword for not printing the best fit results
                             background=background, $ ;If set, the background is fixed to the given value,coeff[0]
                             gauss_amp=gauss_amp, $   ;If set the amplitude is fixed to the given value, coeff[1]
                             FWHM=FWHM, $             ;If set the FWHM is fixed to the given value,coeff[2]
                             p_amp=p_amp,$            ;If set the plateau amplitude is fixed,coeff[3]
                             p_size=p_size,$          ;If set the size of the plateau is fixed,coeff[4]
                             p_sharp=p_sharp          ;If set the decay length of the plateau is fixed,coeff[5]
  
  ;;------- Variables theta
  nx = (size(map))[1]
  ny = (size(map))[2]

  xmap = (replicate(1, ny) ## dindgen(nx)) - (nx-1)/2.0
  ymap = (replicate(1, nx) #  dindgen(ny)) - (ny-1)/2.0
  if keyword_set(center) then xmap -= center[0]/reso
  if keyword_set(center) then xmap -= center[1]/reso
  rmap = sqrt(xmap^2 + ymap^2)  
  
  p0 = [0.0, 1.0, 15.0/reso, 0.1, 60.0/reso, 10.0/reso] ;First guess param

  ;;------- Contraintes sur param
  parinfo = replicate({value:0.D,fixed:0}, 6)

  if keyword_set(background) then parinfo[0].fixed = 1
  if keyword_set(background) then parinfo[0].value = background
  if keyword_set(background) then p0[0] = background
  if keyword_set(gauss_amp) then parinfo[1].fixed = 1
  if keyword_set(gauss_amp) then parinfo[1].value = gauss_amp
  if keyword_set(gauss_amp) then p0[1] = gauss_amp
  if keyword_set(FWHM) then parinfo[2].fixed = 1 
  if keyword_set(FWHM) then parinfo[2].value = FWHM/reso
  if keyword_set(FWHM) then p0[2] = FWHM/reso
  if keyword_set(p_amp) then parinfo[3].fixed = 1
  if keyword_set(p_amp) then parinfo[3].value = p_amp
  if keyword_set(P_amp) then p0[3] = p_amp
  if keyword_set(p_size) then parinfo[4].fixed = 1 
  if keyword_set(p_size) then parinfo[4].value = p_size/reso
  if keyword_set(p_size) then p0[4] = p_size/reso
  if keyword_set(p_sharp) then parinfo[5].fixed = 1 
  if keyword_set(p_sharp) then parinfo[5].value = p_sharp/reso
  if keyword_set(p_sharp) then p0[5] = p_sharp/reso
    
  ;;----- Fit the model
  error = noise_map
  bad_loc = where(finite(error) ne 1 or error le 0, nbad_loc)
  if nbad_loc ne 0 then error[bad_loc] = max(error,/nan)*1e5

  coeff = mpfitfun('fit_plateau_plus_main_beam', rmap, map, error, p0, $
                   parinfo=parinfo, yfit=best_fit, AUTODERIVATIVE=1, /QUIET)

  ;;----- Change pixels to arcsec
  coeff[2] *= reso
  coeff[4] *= reso
  coeff[5] *= reso

  ;;----- Fit
  if not keyword_set(silent) then begin
     print, '------------------------------------------'
     print, '--- Main beam + plateau model ------------'
     print, '--------- Best fit parametres : ----------'
     print, '--------- Background : ', coeff[0]
     print, '--------- Amplitude of the main beam : ', coeff[1]
     print, '--------- FWHM of the main beam: ', coeff[2]
     print, '--------- Amplitude of the plateau: ', coeff[3]
     print, '--------- Extension of the plateau:', coeff[4], '  arcsec'
     print, '--------- Sharpness of the plateau:', coeff[5], '  arcsec'
     print, '------------------------------------------'
  endif

  return
end
