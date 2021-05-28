

psi0_deg = 30.d0

p0_list = (dindgen(10)+1)*0.1
np0 = n_elements(p0_list)

npsnr = 50
p_snr = (dindgen(npsnr)+1)/npsnr*10


make_ct, np0, ct

stokes_I = 1.d0
wind, 1, 1, /free, /large
for ip=0, np0-1 do begin
   p0 = p0_list[ip]
   p_res   = dblarr(npsnr)
   psi_res = dblarr(npsnr)
   for i=0, n_elements(p_snr)-1 do begin
      sigma_p = p0/p_snr[i]
      sigma_q = Stokes_I*sigma_p
      montier2d_test, Stokes_I, p0, psi0_deg, sigma_q, pol_deg, alpha_deg
      p_res[i]   = pol_deg
      psi_res[i] = alpha_deg
   endfor
   if ip eq 0 then begin
      plot, p_snr, (p_res-p0)/sigma_p, psym=-8, $
            xtitle='p/sigma_p', ytitle='(p_res-p0)/sigma_p'
      legendastro, "P0 : "+strtrim(p0_list,2), line=0, col=ct, /right
      oplot, [0,100], [0,0], line=2
   endif
   oplot, p_snr, (p_res-p0)/sigma_p, psym=-8, col=ct[ip]
endfor


;; wind, 1, 1, /free, /large
;; plot, p_list/sigma_p, (p_res-p_list)/sigma_p, psym=-8
;; oplot, [0,100], [0,0], line=2

end
