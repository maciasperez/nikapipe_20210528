;+
;PURPOSE: Get the exact tSZ spectrum up to Te = 50 keV
;
;INPUT: tau (sigma_T \int n_e dl), ICM temperature in keV, frequency
;vector (GHz)
;
;LAST EDITION: 
;   09/10/2015: creation
;-

function tabulated_numerical_sz_spectrum, tau_user, TkeV_user, freq_user
  
  ;;Relativistic Corrections to the Sunyaev-Zeldovich Effect for Clusters of Galaxies. V. Numerical Results for High Electron Temperatures
  ;;Naoki Itoh, Satoshi Nozawa
  
  mec2 = 510.998910
  
  readcol, !nika.soft_dir+'/Pipeline/IDLtools/SZspec/sztable1.dat', $
           F='D,D,D,D,D,D,D,D,D,D,D', /silent, v00,v01,v02,v03,v04,v05,v06,v07,v08,v09,v10
  
  readcol, !nika.soft_dir+'/Pipeline/IDLtools/SZspec/sztable2.dat', $
           F='D,D,D,D,D,D,D,D,D,D,D', /silent, v00,v11,v12,v13,v14,v15,v16,v17,v18,v19,v20
  
  readcol, !nika.soft_dir+'/Pipeline/IDLtools/SZspec/sztable3.dat', $
           F='D,D,D,D,D,D,D,D,D,D,D', /silent, v00,v21,v22,v23,v24,v25,v26,v27,v28,v29,v30
  
  readcol, !nika.soft_dir+'/Pipeline/IDLtools/SZspec/sztable4.dat', $
           F='D,D,D,D,D,D,D,D,D,D,D', /silent, v00,v31,v32,v33,v34,v35,v36,v37,v38,v39,v40
  
  readcol, !nika.soft_dir+'/Pipeline/IDLtools/SZspec/sztable5.dat', $
           F='D,D,D,D,D,D,D,D,D,D,D', /silent, v00,v41,v42,v43,v44,v45,v46,v47,v48,v49,v50
  
  freq = v00*!const.k*!const.TCMB/!const.h*1e-9
  
  Tkev = [0.002, 0.004, 0.006, 0.008, 0.010, 0.012, 0.014, 0.016, 0.018, 0.020, $
          0.022, 0.024, 0.026, 0.028, 0.030, 0.032, 0.034, 0.036, 0.038, 0.040, $
          0.042, 0.044, 0.046, 0.048, 0.050, 0.052, 0.054, 0.056, 0.058, 0.060, $
          0.062, 0.064, 0.066, 0.068, 0.070, 0.072, 0.074, 0.076, 0.078, 0.080, $
          0.082, 0.084, 0.086, 0.088, 0.090, 0.092, 0.094, 0.096, 0.098, 0.100]*mec2
  
  DeltaI_over_tau = transpose([[v01], [v02], [v03], [v04], [v05], [v06], [v07], [v08], [v09], [v10], $
                               [v11], [v12], [v13], [v14], [v15], [v16], [v17], [v18], [v19], [v20], $
                               [v21], [v22], [v23], [v24], [v25], [v26], [v27], [v28], [v29], [v30], $
                               [v31], [v32], [v33], [v34], [v35], [v36], [v37], [v38], [v39], [v40], $
                               [v41], [v42], [v43], [v44], [v45], [v46], [v47], [v48], [v49], [v50]])
  
  if Tkev_user gt max(Tkev) then message, 'No tabulated values above '+strtrim(max(Tkev), 2)+' keV'

  if Tkev_user le Tkev[1] then $ ;No table but preciseanalytical form is perfect here
     dI_SZ = rel_corr_batch_kincorr(tau_user, Tkev_user, 0, !const.tcmb, freq_ghz=freq_user, 0, temp=0) $
  else begin 
     xt = dindgen(n_elements(TkeV))
     tpos = interpol(xt, Tkev, TkeV_user)
     yt = dindgen(n_elements(freq))
     fpos = interpol(yt, freq, freq_user)
     
     Itpl = interpolate(DeltaI_over_tau, tpos, fpos, missing=!values.f_nan, /grid)
     dI_SZ = reform(Itpl) * 2.0 * (!const.k*!const.Tcmb)^3 / (!const.h*!const.c*100.0)^2 * tau_user
  endelse
  
  return, dI_SZ
end
