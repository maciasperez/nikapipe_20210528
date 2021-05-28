;+
;PURPOSE: Correct the gain versus elevation dependence from 
;         The gain - elevation correction of the IRAM 30-m telescope
;         Astron. Astrophys. Suppl. Ser. 132, 413{416 (1998)
;
;INPUT: The parameter and the data structures
;
;OUTPUT: The data structure corrected for elevation gain
;
;LAST EDITION: 
;   03/01/2014: creation (adam@lpsc.in2p3.fr)
;   12/01/2014: message added
;   26/01/2014: update the formula using "Antenna Technical Works" -
;               16-April-2012 - Juan Peñalver, Carsten Kramer
;-

pro nika_pipe_gain_cor, param, data, kidpar, extent_source=extent_source, silent=silent

  w1mm = where(kidpar.type ne 2 and kidpar.array eq 1, nw1mm)
  w2mm = where(kidpar.type ne 2 and kidpar.array eq 2, nw2mm)

  elev = data.el*180/!pi
  freqs_ghz = !const.c/(!nika.lambda*1e-3) * 1d-9

  ;;------- Parameter of the fitted model  
  elmax1mm = 1.567E-06 * freqs_ghz[0]^3 -1.233E-03 * freqs_ghz[0]^2 + 3.194E-01 * freqs_ghz[0] + 2.203E+01
  elmax2mm = 1.567E-06 * freqs_ghz[1]^3 -1.233E-03 * freqs_ghz[1]^2 + 3.194E-01 * freqs_ghz[1] + 2.203E+01

  ;;sigma_0 = 0.085               ;best-fit at 245GHz with R=0.9
  ;;sigma_90 = 0.075              ;best-fit at 245GHz with R=0.9
  ;;R = 0.9                       ;R = 0.8-0.9 takes into account the steepness of the reflector and the illumination taper of the receiver so that R * sigma_g is the radio-effective surface deformation (Greve & Hooghoudt 1981)
  ;;sigma_g = sqrt(sigma_0^2 * (cos(elev) - cos(elev_0))^2 + sigma_90^2 * (sin(elev) - sin(elev_0))^2)

  ;;------- Gain model
  rms_El = 2.5523E-02 * elev^2 - 2.5534 * elev + 1.1937E+02
  Aeff0_El = 8.8466E-06 * elev^2 - 1.2523E-03 * elev + 6.9608E-01
  rms_Elmax1mm = 2.5523E-02 * elmax1mm^2 - 2.5534 * elmax1mm + 1.1937E+02
  Aeff0_Elmax1mm = 8.8466E-06 * elmax1mm^2 - 1.2523E-03 * elmax1mm + 6.9608E-01
  rms_Elmax2mm = 2.5523E-02 * elmax2mm^2 - 2.5534 * elmax2mm + 1.1937E+02
  Aeff0_Elmax2mm = 8.8466E-06 * elmax2mm^2 - 1.2523E-03 * elmax2mm + 6.9608E-01

  Aeff_El1mm = Aeff0_EL * exp(-(4*!dpi*rms_el*1d-3/!nika.lambda[0])^2)
  Aeff_El2mm = Aeff0_EL * exp(-(4*!dpi*rms_el*1d-3/!nika.lambda[1])^2)
  Aeff_Elmax1mm = Aeff0_ELmax1mm * exp(-(4*!dpi*rms_elmax1mm*1d-3/!nika.lambda[0])^2)
  Aeff_Elmax2mm = Aeff0_ELmax2mm * exp(-(4*!dpi*rms_elmax2mm*1d-3/!nika.lambda[1])^2)


  G1mm = Aeff_El1mm / Aeff_Elmax1mm
  G2mm = Aeff_El2mm / Aeff_Elmax2mm
  ;;G1mm = exp(-(4*!dpi*R*sigma_g/!nika.lambda[0])^2)
  ;;G2mm = exp(-(4*!dpi*R*sigma_g/!nika.lambda[1])^2)

  if keyword_set(extent_source) then begin ;correct for source extension
     theta = [0,   1,   2,   3,   4,  5,   6,   7,   8,   12, 1000]
     L_ext = [1,0.98,0.93,0.75,0.45,0.3,0.25,0.18,0.12, 0.05, 0.0] ;measured by eye from Fig.3 but it is a correction of the correction so it should be OK

     L1mm_ext = interpol(L_ext, theta, extent_source/!nika.fwhm_nom[0])
     L2mm_ext = interpol(L_ext, theta, extent_source/!nika.fwhm_nom[1])

     G1mm = 1 - L1mm_ext * (1 - G1mm)
     G2mm = 1 - L2mm_ext * (1 - G2mm)
  endif

  if nw1mm ne 0 then G1mm = G1mm ## (dblarr(nw1mm) + 1)
  if nw2mm ne 0 then G2mm = G2mm ## (dblarr(nw2mm) + 1)

  ;;------- Gain correction
  if nw1mm ne 0 then data.RF_dIdQ[w1mm] /= G1mm
  if nw2mm ne 0 then data.RF_dIdQ[w2mm] /= G2mm

  if not keyword_set(silent) then begin
     message, /info, 'Gain-elevation correction applied at 1mm : / '+strtrim(median(G1mm), 2)
     message, /info, 'Gain-elevation correction applied at 2mm : / '+strtrim(median(G2mm), 2)
     message, /info, 'Median elevation : '+strtrim(median(elev),2)+' degrees'
  endif

  return
end

