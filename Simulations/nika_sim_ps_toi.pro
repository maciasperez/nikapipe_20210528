
;; Simulate a perfect point source timeline

pro nika_sim_PS_toi, kidpar, x_0, y_0, amplitude, fwhm_arcsec, el_source_deg, parangle_deg, ps_toi


nkids  = n_elements( kidpar)
nsn    = n_elements(x_0)
ps_toi = dblarr( nkids, nsn)

copar = cos( parangle_deg*!dtor)
sipar = sin( parangle_deg*!dtor)

sigma = fwhm_arcsec*!fwhm2sigma

fpc_x = 0.d0
fpc_y = 0.d0


for ikid=0, nkids-1 do begin
   if kidpar[ikid].type eq 1 then begin
      nika_nasmyth2azel, kidpar[ikid].nas_x, kidpar[ikid].nas_y, $
                         kidpar[ikid].nas_center_x, kidpar[ikid].nas_center_y, $
                         kidpar[ikid].alpha*!radeg, $
                         fpc_x, fpc_y, el_source_deg, dx, dy
      dx    = -dx + x_0
      dy    = -dy + y_0
      dra   =  copar*dx + sipar*dy
      ddec  = -sipar*dx + copar*dy

      ps_toi[ikid,*] = amplitude[ikid] * exp( -(dra^2+ddec^2)/(2.*sigma[ikid]^2))
   endif
endfor

end
