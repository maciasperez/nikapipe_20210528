;+
;PURPOSE: Create FITS file with calibrated TOI and some info
;
;INPUT: parameter structure, data structure and kidpar structure
;
;OUTPUT: FITS file saved in predefined directory
;
;KEYWORDS: none
;
;LAST EDITION: 
;   21/09/2013: creation (adam@lpsc.in2p3.fr)
;   20/11/2013: modification of the format (RA, JFMP, FXD)
;-

pro nika_pipe_toi2fits, param, data, kidpar

  file1mm = param.output_dir+'/IRAM_TOI_'+param.scan_list[param.iscan]+'_1mm.fits'
  file2mm = param.output_dir+'/IRAM_TOI_'+param.scan_list[param.iscan]+'_2mm.fits'
  
  npt = n_elements(data)
  w1mm = where(kidpar.array eq 1, nw1mm)
  w2mm = where(kidpar.array eq 2, nw2mm)
  
  ;;TOI per KID data
  toi1mm = data.rf_didq[w1mm]
  toi2mm = data.rf_didq[w2mm]
  flag1mm = data.flag[w1mm]
  flag2mm = data.flag[w2mm]
  kid_ra1mm = toi1mm*0
  kid_dec1mm = toi1mm*0
  kid_ra2mm = toi2mm*0
  kid_dec2mm = toi2mm*0
  ra_pointing = ten(param.coord_pointing.ra[0],param.coord_pointing.ra[1],param.coord_pointing.ra[2])*15.0
  dec_pointing = ten(param.coord_pointing.dec[0],param.coord_pointing.dec[1],param.coord_pointing.dec[2])   
  i1mm = 0
  i2mm = 0
  for ikid=0, n_elements(kidpar)-1 do begin
     nika_nasmyth2draddec, data.ofs_az, data.ofs_el, data.el, data.paral, $
                           kidpar[ikid].nas_x, kidpar[ikid].nas_y, $
                           0., 0., dra, ddec, nas_x_ref=kidpar[ikid].nas_center_X, $
                           nas_y_ref=kidpar[ikid].nas_center_Y        
     case kidpar[ikid].array of
        1: begin
           if kidpar[ikid].type ne 1 then flag1mm[i1mm,*] = flag1mm[i1mm,*]*0 + 1 ;Make sure unvalid are flagged
           if kidpar[ikid].type ne 2 then kid_dec1mm[i1mm,*] = ddec/3600.0 + dec_pointing
           if kidpar[ikid].type ne 2 then kid_ra1mm[i1mm,*] = dra/3600.0/cos(kid_dec1mm[i1mm,*]*!dpi/180.0) + ra_pointing
           i1mm = i1mm + 1
        end
        2: begin
           if kidpar[ikid].type ne 1 then flag2mm[i2mm,*] = flag2mm[i2mm,*]*0 + 1 ;Make sure unvalid are flagged
           if kidpar[ikid].type ne 2 then kid_dec2mm[i2mm,*] = ddec/3600.0 + dec_pointing
           if kidpar[ikid].type ne 2 then kid_ra2mm[i2mm,*] = dra/3600.0/cos(kid_dec2mm[i2mm,*]*!dpi/180.0) + ra_pointing
           i2mm = i2mm + 1
        end
     endcase
  endfor
  
  ;;KID data
  kid_type1mm = kidpar[w1mm].type
  kid_type2mm = kidpar[w2mm].type
  
  ;;TOI data
  nsample = data.sample
  time = data.b_t_utc
  mjd = data.mjd
  lst = data.lst
  elevation = data.el
  azimuth = data.az
  paralactic_angle = data.paral
  offset_azimuth = data.ofs_az
  offset_elevation = data.ofs_el
  scan = data.scan
  subscan = data.subscan

  ;;------- Make a structure
  timeline_1mm = {toi:fltarr(nw1mm),$
                  flag:intarr(nw1mm),$
                  kid_ra:fltarr(nw1mm),$
                  kid_dec:fltarr(nw1mm),$
                  nsample:0,$
                  time:0d0,$
                  mjd:0d0,$
                  lst:0d0,$
                  elevation:0d0,$
                  azimuth:0d0,$
                  paralactic_angle:0d0,$
                  offset_azimuth:0d0,$
                  offset_elevation:0d0,$
                  subscan:0d0}

  timeline_1mm = replicate(timeline_1mm, npt)

  timeline_1mm.toi = toi1mm
  timeline_1mm.flag = flag1mm
  timeline_1mm.kid_ra = kid_ra1mm
  timeline_1mm.kid_dec = kid_dec1mm
  timeline_1mm.nsample = nsample
  timeline_1mm.time = time
  timeline_1mm.mjd = mjd
  timeline_1mm.lst = lst
  timeline_1mm.elevation = elevation
  timeline_1mm.azimuth = azimuth
  timeline_1mm.paralactic_angle = paralactic_angle
  timeline_1mm.offset_azimuth = offset_azimuth
  timeline_1mm.offset_elevation = offset_elevation
  timeline_1mm.subscan = subscan


  timeline_2mm = {toi:fltarr(nw2mm),$
                  flag:intarr(nw2mm),$
                  kid_ra:fltarr(nw2mm),$
                  kid_dec:fltarr(nw2mm),$
                  nsample:0,$
                  time:0d0,$
                  mjd:0d0,$
                  lst:0d0,$
                  elevation:0d0,$
                  azimuth:0d0,$
                  paralactic_angle:0d0,$
                  offset_azimuth:0d0,$
                  offset_elevation:0d0,$
                  subscan:0d0}

  timeline_2mm = replicate(timeline_2mm, npt)

  timeline_2mm.toi = toi2mm
  timeline_2mm.flag = flag2mm
  timeline_2mm.kid_ra = kid_ra2mm
  timeline_2mm.kid_dec = kid_dec2mm
  timeline_2mm.nsample = nsample
  timeline_2mm.time = time
  timeline_2mm.mjd = mjd
  timeline_2mm.lst = lst
  timeline_2mm.elevation = elevation
  timeline_2mm.azimuth = azimuth
  timeline_2mm.paralactic_angle = paralactic_angle
  timeline_2mm.offset_azimuth = offset_azimuth
  timeline_2mm.offset_elevation = offset_elevation
  timeline_2mm.subscan = subscan

  ;;------- Make header and save fits
  if strupcase(param.math) eq 'RF' then method_flux = 'RFdIdQ'
  if strupcase(param.math) eq 'PF' then method_flux = 'Pf'
  if strupcase(param.math) eq 'CF' then method_flux = 'Cf'
 
  mwrfits, timeline_1mm, file1mm, /create, /silent
  bidon = mrdfits(file1mm, 1, head, /silent)

  fxaddpar, head, 'CONT1', 'Calibrated TOI', '[N_detector, N_sample]'
  fxaddpar, head, 'CONT2', 'Flag TOI', '[N_detector, N_sample]'
  fxaddpar, head, 'CONT3', 'R.A. detectors sky coordinates', '[N_detector, N_sample]'
  fxaddpar, head, 'CONT4', 'Dec. detectors sky coordinates', '[N_detector, N_sample]'
  fxaddpar, head, 'CONT5', 'Sample number', '[N_sample]'
  fxaddpar, head, 'CONT6', 'Scan time', '[N_sample]'
  fxaddpar, head, 'CONT7', 'Modified Julian Day', '[N_sample]'
  fxaddpar, head, 'CONT8', 'LST', '[N_sample]'
  fxaddpar, head, 'CONT9', 'Elevation', '[N_sample]'
  fxaddpar, head, 'CONT10', 'Paralactic angle', '[N_sample]'
  fxaddpar, head, 'CONT11', 'Scan Azimuth Offset', '[N_sample]'
  fxaddpar, head, 'CONT12', 'Scan Elevation Offset', '[N_sample]'
  fxaddpar, head, 'CONT13', 'Subscan number', '[N_sample]'
  fxaddpar, head, 'UNIT1', 'Jansky per beam', ''
  fxaddpar, head, 'UNIT2', 'none', ''
  fxaddpar, head, 'UNIT3', 'degree', ''
  fxaddpar, head, 'UNIT4', 'degree', ''
  fxaddpar, head, 'UNIT5', 'none', ''
  fxaddpar, head, 'UNIT6', 'second', ''
  fxaddpar, head, 'UNIT7', 'Day', ''
  fxaddpar, head, 'UNIT8', 'I do not know', ''
  fxaddpar, head, 'UNIT9', 'radian', ''
  fxaddpar, head, 'UNIT10', 'radian', ''
  fxaddpar, head, 'UNIT11', 'arcsec', ''
  fxaddpar, head, 'UNIT12', 'arcsec', ''
  fxaddpar, head, 'UNIT13', 'none', ''
  fxaddpar, head, 'INFO2.1', '0 = to be projected', ''
  fxaddpar, head, 'INFO2.2', '1 = not to be projected', ''
  fxaddpar, head, 'INFO11', 'With respect to the center of the array', '[N_sample]'
  fxaddpar, head, 'INFO12', 'With respect to the center of the array', '[N_sample]'
  fxaddpar, head, 'RAW2FR', method_flux, 'Method to reconstruct the KID resonance frequency with raw data'

  head_1mm = head
  mwrfits, timeline_1mm, file1mm, head_1mm, /create, /silent

  head_2mm = head
  mwrfits, timeline_2mm, file2mm, head_2mm, /create, /silent

  return
end
