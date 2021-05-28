;+
;PURPOSE: Save the beam in a FITS file for external astronomers
;
;INPUT: the output directory, the radius, the maximum integration
;radius, the beam normalized response profile, the associated error,
;the solid angle covered, the associated error. This for both wavelenghts
;
;OUTPUT: FITS file created in the output directory
;
;KEYWORDS:
;
;LAST EDITION: 
;   23/11/2013: creation (adam@lpsc.in2p3.fr)
;-

pro nika_anapipe_beam2fits, dir, rad, rad_max, beam1mm, beam2mm, err_beam1mm, err_beam2mm, $
                            omega1mm, omega2mm, err_omega1mm, err_omega2mm
  
  file = dir+'/NIKA_beam.fits'
  
  s1mm = {angular_radius:rad,$
          beam:beam1mm,$
          err_beam:err_beam1mm,$
          integrated_angular_radius:rad_max,$
          solid_angle:omega1mm,$
          err_solid_angle:err_omega1mm}
  
  s2mm = {angular_radius:rad,$
          beam:beam2mm,$
          err_beam:err_beam2mm,$
          integrated_angular_radius:rad_max,$
          solid_angle:omega2mm,$
          err_solid_angle:err_omega2mm}
  
  mwrfits, s1mm, file, /create, /silent
  bidon = mrdfits(file, 1, head)

  fxaddpar, head, 'CONT1', 'Angular radius of the beam profile', '[arcsec]'
  fxaddpar, head, 'CONT2', 'Normalized beam response', '[none]'
  fxaddpar, head, 'CONT3', 'Normalized beam response statistical error', '[none]'
  fxaddpar, head, 'CONT4', 'Angular radius up to which the beam is integrated', '[arcsec]'
  fxaddpar, head, 'CONT5', 'Solid angle covered by the beam', '[arcsec x arcsec]'
  fxaddpar, head, 'CONT6', 'Statictical error on the solid angle', '[arcsec x arcsec]'
  head1mm = head
  head2mm = head

  mwrfits, s1mm, file, head1mm, /create, /silent
  mwrfits, s2mm, file, head2mm, /silent

  return
end
