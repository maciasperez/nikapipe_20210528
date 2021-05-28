;-
;  Correcting factor to the beam efficiency as given in Perotto+2019
;  to account for the power stemming from beyond 180''
;
;  Input: cutting radius in arcsec : 180'' <  rcut <  3000''
;
;  Output: correcting factor eta_rcut =  [1+0m_{180<r<rcut}/Om_180]^{-1}
;
;  Keyword: if spillover=1, the contribution from the rearward and
;  forward scattering and spillover (\eta_fss and \eta_rss) are
;  accounted for
;
;  Example : be_factor = beam_efficiency_correction(240)
;            eta_390   = beam_efficiency_correction(390.0d0)
;            eta_4pi   = beam_efficiency_correction(3000.0d0, spillover=1)
;            
;
;  first creation by LP, April 2019
;+

function beam_efficiency_correction, rcut, spillover=spillover

  ;; KRAMER+2013
  freq_ck   = [145.0d0, 210.0d0, 230.0d0, 280.0d0]
  fwhm_0_ck = [16.0d0, 11.0d0, 10.4d0, 8.4d0]
  fwhm_1_ck = [85.0d0, 65.0d0, 56.5d0, 50.0d0]
  fwhm_2_ck = [350.0d0, 250.0d0, 217.0d0, 175.0d0]
  fwhm_3_ck = [1200.0d0, 860.0d0, 761.0d0, 620.0d0]
  a0_ck = [1.0d0, 1.0d0, 1.0d0, 1.0d0]
  a1_ck = [8.0d-4, 1.9d-3, 2.0d-3, 2.0d-3]
  a2_ck = [2.5d-4, 3.5d-4, 4.1d-4, 5.0d-4]
  a3_ck = [1.6d-5, 2.2d-5, 3.5d-5, 5.5d-5]
  a0_ck = a0_ck-a1_ck-a2_ck-a3_ck

  beff_ck = [0.74, 0.63, 0.59, 0.49]

  nfreq_ck = n_elements(freq_ck)

  ;; extropol to NIKA2 freq (k estimates from Kramer+2013)
  k = [2400.0, 13000.0, 50000.0, 175000.0]
  
  freq0  = [150d0, 260d0]
  fwhm_0 = k[0]/freq0
  fwhm_1 = k[1]/freq0
  fwhm_2 = k[2]/freq0
  fwhm_3 = k[3]/freq0
  a0 = [1.0d0,  1.0d0]
  a1 = [8.0d-4, 2.0d-3]
  a2 = [2.5d-4, 4.5d-4]
  a3 = [1.6d-5, 4.5d-5]
  a0 = a0-a1-a2-a3

  om_180_paper = [445.0d0, 235.0d0] ;; arcsec^2 (Perotto+2019, JFL study using beam profile (aka prof2))

  ;; rearward and forward scattering and spillover
  ;; \eta_fss and (1-F_eff) as given in Kramer+2013
  eta_fss  = [0.02, 0.09]
  eta_rss  = [0.07, 0.10] ;; 8% at 230GHz and 13% at 280GHz
  eta_rfss = [0.09, 0.19] ;; sum of the two above
  om_rfss = om_180_paper*eta_rfss

  
  ;; 0MEGA at rcut
  ;;-----------------------------------------------------------------------
  sidesize = 6001
  vect = dindgen(sidesize)-sidesize/2.
  un = dblarr(sidesize)+1.0d0
  xmap = un#vect
  ymap = transpose(xmap)
  rmap = sqrt(xmap^2 + ymap^2)
  dx = 1.

  be_factor_1 = dblarr(2) ;; for cross-check
  be_factor_2 = dblarr(2) ;; output
  be_factor_3 = dblarr(2) ;; output with spillover and scattering 
  
  for ff = 0, 1 do begin 
     
     print, ''
     print, 'FREQ = ', freq0[ff]
     print, '-----------------------------'

     ;; main beam + 3 error beams (model of Kramer+2013)
     fullb = a0[ff]*exp(-rmap^2/2.0d0/(fwhm_0[ff]*!fwhm2sigma)^2) $
             + a1[ff]*exp(-rmap^2/2.0d0/(fwhm_1[ff]*!fwhm2sigma)^2) $
             + a2[ff]*exp(-rmap^2/2.0d0/(fwhm_2[ff]*!fwhm2sigma)^2) $
             + a3[ff]*exp(-rmap^2/2.0d0/(fwhm_3[ff]*!fwhm2sigma)^2) 

     ;; check the impact of the grid on the precision
     print, 'Main beam : ', total(a0[ff]*exp(-rmap^2/2.0d0/(fwhm_0[ff]*!fwhm2sigma)^2)*dx^2)
     print, 'verif     : ', a0[ff]*2.0d0*!dpi*(fwhm_0[ff]*!fwhm2sigma)^2  
     print, '3rd error beam : ', total(a3[ff]*exp(-rmap^2/2.0d0/(fwhm_3[ff]*!fwhm2sigma)^2)*dx^2)
     print, 'verif     : ', a3[ff]*2.0d0*!dpi*(fwhm_3[ff]*!fwhm2sigma)^2  
     
     ;; consistency checks (recalcul P_i and compare to Kramer+2013)
     P0 = total(a0[ff]*exp(-rmap^2/2.0d0/(fwhm_0[ff]*!fwhm2sigma)^2)*dx^2)/total(fullb*dx^2)
     P1 = total(a1[ff]*exp(-rmap^2/2.0d0/(fwhm_1[ff]*!fwhm2sigma)^2)*dx^2)/total(fullb*dx^2)
     P2 = total(a2[ff]*exp(-rmap^2/2.0d0/(fwhm_2[ff]*!fwhm2sigma)^2)*dx^2)/total(fullb*dx^2)
     P3 = total(a3[ff]*exp(-rmap^2/2.0d0/(fwhm_3[ff]*!fwhm2sigma)^2)*dx^2)/total(fullb*dx^2)
     
     print, "P0["+strtrim(string(freq0[ff]), 2)+"] = ", P0
     print, "P1["+strtrim(string(freq0[ff]), 2)+"] = ", P1
     print, "P2["+strtrim(string(freq0[ff]), 2)+"] = ", P2
     print, "P3["+strtrim(string(freq0[ff]), 2)+"] = ", P3

     ;;  Om_180_kramer
     w_180 = where(rmap le 180.)
     om_180_kramer = total(fullb[w_180]*dx^2)
     print, "Om_180_Kramer+2013["+strtrim(string(freq0[ff]), 2)+"] = ", om_180_kramer

     ;; Om_rcut
     w_max = where(rmap le rcut)
     om_cut_kramer = total(fullb[w_max]*dx^2)
     print, "Om_cut_kramer+2013["+strtrim(string(freq0[ff]), 2)+"] = ", om_cut_kramer

     ;; Om_{180<r<rcut} = Om_reste
     w_reste = where(rmap gt 180.0d0 and rmap le rcut)
     om_reste = total(fullb[w_reste]*dx^2)
     print, "Om_reste["+strtrim(string(freq0[ff]), 2)+"] = ", om_reste
     
     be_factor_1[ff] = om_180_kramer/om_cut_kramer

     be_factor_2[ff] = 1.0d0/(1.0d0+(om_reste/om_180_paper[ff]))

     print, "(Om_180/Om_cut)_Kramer+2013["+strtrim(string(freq0[ff]), 2)+"] = ", be_factor_1[ff]
     print, "[1. + Om_reste/Om_180_paper]^{-1}["+strtrim(string(freq0[ff]), 2)+"] = ",be_factor_2[ff]

     be_factor_3[ff] = 1.0d0/(1.0d0+(om_reste/om_180_paper[ff])+(om_rfss[ff]/om_180_paper[ff]))
     
     endfor    

  be_factor = be_factor_2
  if keyword_set(spillover) then begin
     print, "factor 4pi with spillover = ", be_factor_3
     be_factor = be_factor_3
  endif

  return, be_factor

  
end
