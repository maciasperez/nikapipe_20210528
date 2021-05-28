
pro nika_write_kidpar, kidpar, out_fits_file, silent=silent

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nika_write_kidpar, kidpar, out_fits_file"
   return
endif

mwrfits, kidpar, out_fits_file, /create, header1
sxdelpar, header1, "COMMENT"
sxaddpar, header1, "COMMENT", "type is the equivalent of flag. use decode_flag.pro to get further info"
sxaddpar, header1, "COMMENT", "x_pix is the integer x position of the pixel on the grid"
sxaddpar, header1, "COMMENT", "y_pix is the integer y position of the pixel on the grid"
sxaddpar, header1, "COMMENT", "frequ : instrumental parameter"
sxaddpar, header1, "COMMENT", "amplitude: instrumental parameter"
sxaddpar, header1, "COMMENT", "ic: instrumental parameter"
sxaddpar, header1, "COMMENT", "qc: instrumental parameter"
sxaddpar, header1, "COMMENT", "ir: instrumental parameter"
sxaddpar, header1, "COMMENT", "qr: instrumental parameter"
sxaddpar, header1, "COMMENT", "nas_x: [arcsec] Nasmyth coordinate"
sxaddpar, header1, "COMMENT", "nas_y: [arcsec] Nasmyth coordinate"
sxaddpar, header1, "COMMENT", "nas_center_x: [arcsec] Nasmyth center coordinate"
sxaddpar, header1, "COMMENT", "nas_center_y: [arcsec] Nasmyth center coordinate"
sxaddpar, header1, "COMMENT", "alpha: [rad] focal plante orientation"
sxaddpar, header1, "COMMENT", "calib: planet calibration in Jy/Hz"
sxaddpar, header1, "COMMENT", "fwhm: [arcsec] average gaussian FWHM of the detectors"
sxaddpar, header1, 'COMMENT', "flag = 0 : no signal"
sxaddpar, header1, 'COMMENT', "flag = 1 : good kid (single beam)"
sxaddpar, header1, 'COMMENT', "flag = 2 : off resonance"
sxaddpar, header1, 'COMMENT', "flag = 3 : combination of several kids"
sxaddpar, header1, 'COMMENT', "flag = 4 : multiple beams, not separable"
sxaddpar, header1, 'COMMENT', "flag = 5 : strange resonnance"
sxaddpar, header1, 'COMMENT', "flag = 6 : multiple TBC"
sxaddpar, header1, "lambda", 1, '1 or 2 for the 1mm or 2mm matrices'

mwrfits, kidpar, out_fits_file, /create, header1

if not keyword_set(silent) then message, /info, "Wrote "+out_fits_file

end

