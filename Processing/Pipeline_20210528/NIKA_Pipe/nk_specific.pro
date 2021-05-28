
pro nk_specific, param, info, data, kidpar, grid, grid2, grid3, info2, info3


if strupcase(param.specific_reduction) eq "SATURN_MOONS" then begin

   ;; Subtract saturn template from TOIs
   restore, param.saturn_azel_template_file

   ;; Rotate it into radec coordinates and read it
   template_toi = data.toi
   for lambda=1, 2 do begin
      w1 = where( round(kidpar.lambda) eq lambda and kidpar.type eq 1, nw1)
      if nw1 ne 0 then begin
         if lambda eq 1 then begin
            nk_shear_rotate, saturn.map_i_1mm, saturn.nx, saturn.ny, -info.paral, template
         endif else begin
            nk_shear_rotate, saturn.map_i2, saturn.nx, saturn.ny, -info.paral, template
         endelse
         
         nk_map2toi_3, param, info, template, data.ipix[w1], toi1
         template_toi[w1,*] = toi1
      endif
   endfor

   ;; prevoir de rescaler le template
   w1 = where( kidpar.type eq 1, nw1)
   data2 = data ; clumsy, but pragmatic
   for i=0, nw1-1 do begin
      ikid = w1[i]
      fit = linfit( data.toi[ikid], template_toi[ikid,*])
      data2.toi[ikid] = data.toi[ikid] - (fit[0]+fit[1]*template_toi[ikid,*])
   endfor
;   wind, 1, 1, /free, /large
;   plot, data.toi[ikid], /xs
;   oplot, template_toi[ikid,*], col=250
   
   ;; Project maps centered on Titan and Iapetus
   if finite(param.new_map_center_ra) eq 1 and strupcase(param.map_proj) eq "RADEC" then begin
      nk_project_auxillary_grids, param, info, data2, kidpar, grid2, info2, $
                                  ra_c= param.new_map_center_ra, $
                                  dec_c=param.new_map_center_dec
   endif
   if finite(param.new_map_center_ra1) eq 1 and strupcase(param.map_proj) eq "RADEC" then begin
      nk_project_auxillary_grids, param, info, data2, kidpar, grid3, info3, $
                                  ra_c= param.new_map_center_ra1, $
                                  dec_c=param.new_map_center_dec1
   endif
   
endif
end
