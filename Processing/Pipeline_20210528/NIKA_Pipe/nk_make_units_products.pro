
pro nk_make_units_products, param, info, data, kidpar

coeff1mm = {Kcmb2Krj:param.KRJperKCMB_1mm, $
            y2Kcmb:param.y2Kcmb_1mm, $
            Krj2JyperB:param.JYperKRJ_1mm,$
            JYperB2JYperSr:param.JYperB2JYperSr_1mm}

coeff2mm = {Kcmb2Krj:param.KRJperKCMB_2mm, $
            y2Kcmb:param.y2Kcmb_2mm, $
            Krj2JyperB:param.JYperKRJ_2mm,$
            JYperB2JYperSr:param.JYperB2JYperSr_2mm}

mwrfits, coeff1mm, param.output_dir+'/NIKA_unit_conversion.fits', /create, /silent
bidon = mrdfits(param.output_dir+'/NIKA_unit_conversion.fits',1,head_coeff, /silent)
head1mm = head_coeff
fxaddpar, head1mm, 'CONT1', 'K_CMB to K_RJ at 1mm', ''
fxaddpar, head1mm, 'CONT2', 'y Compton to K_CMB at 1mm', ''
fxaddpar, head1mm, 'CONT3', 'K_RJ to Jy/Beam at 1mm', ''
fxaddpar, head1mm, 'CONT4', 'Jy/Beam to Jy/sr at 1mm', ''
head2mm = head_coeff
fxaddpar, head2mm, 'CONT1', 'K_CMB to K_RJ at 2mm', ''
fxaddpar, head2mm, 'CONT2', 'y Compton to K_CMB at 2mm', ''
fxaddpar, head2mm, 'CONT3', 'K_RJ to Jy/Beam at 2mm', ''
fxaddpar, head2mm, 'CONT4', 'Jy/Beam to Jy/sr at 2mm', ''

mwrfits, coeff1mm, param.output_dir+'/NIKA_unit_conversion.fits',head1mm, /create, /silent
mwrfits, coeff2mm, param.output_dir+'/NIKA_unit_conversion.fits',head2mm, /silent
   
spawn, "/bin/cp -f "+bandpass_file+' '+param.output_dir+'/NIKA_bandpass.fits'

end
