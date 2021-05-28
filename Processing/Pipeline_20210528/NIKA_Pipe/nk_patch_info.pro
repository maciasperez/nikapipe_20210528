

;; update new redundant fields of info for convenience

pro nk_patch_info, info


;; Create new info structure if needed
if tag_exist( info, 'result_flux_i4') eq 0 then begin

   info_in = info
   nk_default_info, info
   tags_in = tag_names(info_in)
   tags = tag_names( info)
   for itag=0, n_elements(tags_in)-1 do begin
      w = where( strupcase(tags) eq strupcase(tags_in[itag]))
      info.(w) = info_in.(itag)
   endfor

   
;; Tags that depend on lambda or array and the stokes param
   stokes_tags = 'RESULT_'+['FLUX', 'ERR_FLUX', 'FLUX_CENTER', 'ERR_FLUX_CENTER', $
                            'APERTURE_PHOTOMETRY', 'ERR_APERTURE_PHOTOMETRY', $
                            'NEFD', 'NEFD_CENTER', 'ERR_NEFD', 'ERR_FLUX_LIST', 'SIGMA_BOOST']
   stokes = ['I', 'Q', 'U']
   tag_list = ['']
   for istokes=0,2 do begin
      for itag=0, n_elements(stokes_tags)-1 do begin
         cmd = "info."+stokes_tags[itag]+"_"+strtrim(stokes[istokes],2)+'4 = '+$
               "info."+stokes_tags[itag]+"_"+strtrim(stokes[istokes],2)+"_1mm"
         junk = execute(cmd)

         cmd = "info."+stokes_tags[itag]+"_"+strtrim(stokes[istokes],2)+"_2mm = "+$
               "info."+stokes_tags[itag]+"_"+strtrim(stokes[istokes],2)+'2'
      endfor
   endfor

;; Tags that do not depend on Stokes parameters
   tag_list_1 = 'RESULT_'+['POL_DEG', 'ERR_POL_DEG', 'POL_ANGLE', 'ERR_POL_ANGLE', $
                           'POL_DEG_CENTER', 'ERR_POL_DEG_CENTER', 'POL_ANGLE_CENTER', 'ERR_POL_ANGLE_CENTER', $
                           'OFF_X', 'OFF_Y', 'FWHM_X', 'FWHM_Y', 'FWHM', 'PEAK', 'TAU', $
                           'OPT_FOCUS', 'ERR_OPT_FOCUS', 'COMM_GLI', 'COMM_JUM', 'ON_SOURCE_FRAC_ARRAY', $
                           'ATM_QUALITY', 'SCAN_QUALITY', 'GEOM_TIME_CENTER', $
                           'TIME_MATRIX_CENTER', 'ETA', 'T_GAUSS_BEAM', 'ANOM_REFRAC_SCATTER']

   for itag=0, n_elements(tag_list_1)-1 do begin
      cmd = "info."+tag_list_1[itag]+"_4 = info."+tag_list_1[itag]+"_1mm"
      junk = execute(cmd)

      cmd = "info."+tag_list_1[itag]+"_2mm = info."+tag_list_1[itag]+'_2'
      junk = execute(cmd)
   endfor
endif

end

