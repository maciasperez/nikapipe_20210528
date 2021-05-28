;+
;PURPOSE: Fit a gaussian beam with many parameters, allowing to fixe
;         any of them
;
;INPUT: The map and its resolution
;
;OUTPUT: Print the best fit parameters + keywords
;
;LAST EDITION: 
;   22/08/2013: everything (Remi Adam adam@lpsc.in2p3.fr)
;   25/09/2013: add check on the variance which has to be defined (Remi Adam adam@lpsc.in2p3.fr)
;   07/10/2013: add chi2 and search_box param keywords (Remi Adam
;adam@lpsc.in2p3.fr)
;   18/06/2015: little change fo pixel effect correction
;-

pro nika_pipe_fit_beam, input_map, $             ;Data in a 2d array
                        reso, $                  ;Resolution of the map in arcsec
                        coeff=coeff, $           ;Best fit coefficients:
                        err_coeff=err_coeff,$    ;Best fit coeff erreur
                        rchi2=rchi2,$            ;Reduced chi squarred returned
                        ;;                        coeff[0]   Constant baseline level
                        ;;                        coeff[1]   Peak value
                        ;;                        coeff[2]   Peak (x) -- gaussian sigma
                        ;;                        coeff[3]   Peak (y) -- gaussian sigma
                        ;;                        coeff[4]   Peak centroid (x)
                        ;;                        coeff[5]   Peak centroid (y)
                        ;;                        coeff[6]   Rotation angle (radians) if TILT keyword set
                        best_fit=best_fit, $     ;Best fit map
                        var_map=var_map, $       ;Variance map (for weights)
                        CIRCULAR=CIRCULAR, $     ;If set, then FWHM_x = FWHM_y
                        TILT=TILT, $             ;If set, then the major and minor axes of the peak profile 
                        ;;                        are allowed to rotate with respect to the image axes.
                        ;;                        Coeff[6] will be set to the clockwise rotation angle.
                        silent=silent, $         ;Set this keyword for not printing the best fit results
                        center=center, $         ;Set this keyword to force the fit at the center of the map. 
                        ;;                        If search_box is also set,
                        ;;                        then the location is only forced to be in the box
                        background=background, $ ;If set, the background is fixed to the given value, coeff[0]
                        ampli=ampli, $           ;If set the amplitude is fixed to the given value, coeff[1]
                        FWHM=FWHM,$              ;If set the FWHM is fixed to the given value, both coeff[2,3]
                        search_box=search_box    ;Give the location box allowed for the source (angle unit). If set, center 
  ;;                        becomes the center of the box and thep
  ;;                        position is set free (within the box). 
  
  ;;------- Search_box must be given with center
  if keyword_set(search_box) and not keyword_set(center) then message,'I am lost, you gave a box in which to search but you forgot its center location (keyword center)'

  ;;------- Variables
  nx = (size(input_map))[1]
  ny = (size(input_map))[2]
  
  if nx/2 ne double(nx)/2.0 then center_map_x = (nx-1)/2.0 else center_map_x = nx/2.0
  if ny/2 ne double(ny)/2.0 then center_map_y = (ny-1)/2.0 else center_map_y = ny/2.0

  ;;------- Contraintes sur param
  parinfo = replicate({value:0.D,fixed:0, limited:[0,0], limits:[0.D,0.D]}, 7)

  ;;**************
  ;; Nico, @PICO, Feb. 20th, 2014
  ;;parinfo[2].limited =  [1, 1]
  ;;parinfo[3].limited =  [1, 1]
  ;;parinfo[2].limits = [5, 30]*!fwhm2sigma/reso
  ;;parinfo[3].limits = [5, 30]*!fwhm2sigma/reso
  ;;**************

  if keyword_set(background) then parinfo[0].fixed = 1
  if keyword_set(ampli) then parinfo[1].fixed = 1
  if keyword_set(FWHM) then parinfo[2].fixed = 1
  if keyword_set(FWHM) then parinfo[3].fixed = 1
  if keyword_set(center) then parinfo[4].fixed = 1
  if keyword_set(center) then parinfo[5].fixed = 1
  if keyword_set(search_box) then parinfo[4].limited = [1,1]
  if keyword_set(search_box) then parinfo[4].limits = (center[0]/reso+center_map_x) + search_box[0]/reso/2*[-1,1]
  if keyword_set(search_box) then parinfo[4].fixed = 0
  if keyword_set(search_box) then parinfo[5].limited = [1,1]
  if keyword_set(search_box) then parinfo[5].limits = (center[1]/reso+center_map_x) + search_box[1]/reso/2*[-1,1]
  if keyword_set(search_box) then parinfo[5].fixed = 0
  
  estimates = [0, 1e-2, 15/reso*!fwhm2sigma, 15/reso*!fwhm2sigma, center_map_x, center_map_y, 0] ;Standard guess

  if keyword_set(background) or keyword_set(ampli) or keyword_set(FWHM) or keyword_set(center) then begin
     if keyword_set(background) then estimates[0] = background
     if keyword_set(ampli) then estimates[1] = ampli
     if keyword_set(FWHM) then estimates[2] = FWHM/reso*!fwhm2sigma
     if keyword_set(FWHM) then estimates[3] = FWHM/reso*!fwhm2sigma
     if keyword_set(center) then estimates[4] = center[0]/reso + center_map_x
     if keyword_set(center) then estimates[5] = center[1]/reso + center_map_y
  endif
  
  ;;------- Weight
  if keyword_set(var_map) then begin
     w8 = 1.0/var_map
     novar = where(var_map le 0 or finite(var_map) ne 1, nnovar)
     if nnovar ne 0 then w8[novar] = 0.0
  endif
  
  ;;------- Fit gaussian parameters A
  best_fit = mpfit2dpeak(input_map, coeff, /GAUSSIAN, WEIGHTS=w8, CIRCULAR=CIRCULAR, TILT=TILT, $
                         ESTIMATES=estimates, parinfo=parinfo, QUIET=1, SIGMA=err_coeff, CHISQ=CHISQ, DOF=DOF)

  rchi2 = CHISQ/DOF
  
  ;;----- Convert coeffs to physical values
  coeff[2] *= reso/!fwhm2sigma
  coeff[3] *= reso/!fwhm2sigma
  coeff[4] = (coeff[4]-center_map_x)*reso
  coeff[5] = (coeff[5]-center_map_y)*reso

  ;;----- Fit
  if not keyword_set(silent) then begin
     print, '------------------------------------------'
     print, '--- Single gaussian model ----------------'
     print, '--------- Best fit parametres : ----------'
     print, '--------- Background : ', coeff[0]
     print, '--------- Amplitude : ', coeff[1]
     print, '--------- FWHM along x: ', coeff[2]
     print, '--------- FWHM along y: ', coeff[3]
     print, '--------- FWHM total: ', sqrt(coeff[3]*coeff[2])
     print, '--------- Center along x:', coeff[4], '  arcsec'
     print, '--------- Center along y:', coeff[5], '  arcsec'
     print, '--------- Tilt angle : ', coeff[6]
     print, '------------------------------------------'
  endif
  return
end
