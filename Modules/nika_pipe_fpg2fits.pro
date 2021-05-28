;+
;PURPOSE: Make the Focal Plane geometry in a fits file
;
;INPUT: parameter structure, data structure and kidpar structure
;
;OUTPUT: FITS file saved in predefined directory
;
;KEYWORDS: none
;
;LAST EDITION: 
;   23/11/2013: creation (adam@lpsc.in2p3.fr)
;-

pro nika_pipe_fpg2fits, param, data, kidpar

  ;;------- Organize the data
  w1mm = where(kidpar.array eq 1, n1mm)
  w2mm = where(kidpar.array eq 2, n2mm)
  type1mm = kidpar[w1mm].type
  type2mm = kidpar[w2mm].type
  wout1mm = where(type1mm ne 1, nwout1mm)
  wout2mm = where(type2mm ne 1, nwout2mm)

  numdet1mm = kidpar[w1mm].numdet
  locx1mm = kidpar[w1mm].nas_x
  locy1mm = kidpar[w1mm].nas_y
  beam1mm = kidpar[w1mm].fwhm
  beamx1mm = kidpar[w1mm].fwhm_x
  beamy1mm = kidpar[w1mm].fwhm_y
  if nwout1mm ne 0 then begin
     locx1mm[wout1mm] = !values.f_nan
     locy1mm[wout1mm] = !values.f_nan
     beam1mm[wout1mm] = !values.f_nan
     beamx1mm[wout1mm] = !values.f_nan
     beamy1mm[wout1mm] = !values.f_nan
  endif

  numdet2mm = kidpar[w2mm].numdet
  locx2mm = kidpar[w2mm].nas_x
  locy2mm = kidpar[w2mm].nas_y
  beam2mm = kidpar[w2mm].fwhm
  beamx2mm = kidpar[w2mm].fwhm_x
  beamy2mm = kidpar[w2mm].fwhm_y
  if nwout2mm ne 0 then begin
     locx2mm[wout2mm] = !values.f_nan
     locy2mm[wout2mm] = !values.f_nan
     beam2mm[wout2mm] = !values.f_nan
     beamx2mm[wout2mm] = !values.f_nan
     beamy2mm[wout2mm] = !values.f_nan
  endif

  ;;------- Create the FITS
  file = param.output_dir+'/NIKA_focal_plane.fits'

  fpg1mm = {numdet:numdet1mm,$
            nasmyth_offset_x:locx1mm,$
            nasmyth_offset_y:locy1mm,$
            beam_fwhm:beam1mm,$
            beam_fwhm_x:beamx1mm,$
            beam_fwhm_y:beamy1mm}
  fpg2mm = {numdet:numdet2mm,$
            nasmyth_offset_x:locx2mm,$
            nasmyth_offset_y:locy2mm,$
            beam_fwhm:beam2mm,$
            beam_fwhm_x:beamx2mm,$
            beam_fwhm_y:beamy2mm}

  mwrfits, fpg1mm, file, /create, /silent
  bidon = mrdfits(file, 1, head, /silent)
  
  head1mm = head
  fxaddpar, head1mm, 'CONT1', 'KIDs number at 1mm', '[N_KIDs]'
  fxaddpar, head1mm, 'CONT2', 'KIDs nasmyth offset along X at 1mm', '[N_KIDs]'
  fxaddpar, head1mm, 'CONT3', 'KIDs nasmyth offset along Y at 1mm', '[N_KIDs]'
  fxaddpar, head1mm, 'CONT4', 'KIDs gaussian beam FWHM at 1mm', '[N_KIDs]'
  fxaddpar, head1mm, 'CONT5', 'KIDs gaussian beam FWHM along X at 1mm', '[N_KIDs]'
  fxaddpar, head1mm, 'CONT6', 'KIDs gaussian beam FWHM along Y at 1mm', '[N_KIDs]'
  head2mm = head
  fxaddpar, head2mm, 'CONT1', 'KIDs number at 2mm', '[N_KIDs]'
  fxaddpar, head2mm, 'CONT2', 'KIDs nasmyth offset along X at 2mm', '[N_KIDs]'
  fxaddpar, head2mm, 'CONT3', 'KIDs nasmyth offset along Y at 2mm', '[N_KIDs]'
  fxaddpar, head2mm, 'CONT4', 'KIDs gaussian beam FWHM at 2mm', '[N_KIDs]'
  fxaddpar, head2mm, 'CONT5', 'KIDs gaussian beam FWHM along X at 2mm', '[N_KIDs]'
  fxaddpar, head2mm, 'CONT6', 'KIDs gaussian beam FWHM along Y at 2mm', '[N_KIDs]'

  mwrfits, fpg1mm, file, head1mm, /create, /silent
  mwrfits, fpg2mm, file, head2mm, /silent


  return
end
