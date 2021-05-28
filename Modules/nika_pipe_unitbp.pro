
pro nika_pipe_unitbp, KRJperKCMB, KCMBperY, mmwv=mmwv, no_bandpass=no_bandpass
  
  if not keyword_set(mmwv) then mmwv = 1.0 ;Default vlaue for mm of water vapor

;Get units assuming Dirac function for band pass first
  nu = {A:!const.c*1d-6/!nika.lambda[0], B:!const.c*1d-6/!nika.lambda[1]}

  KRJperKCMB = {A:(!const.h/!const.k*1d9*nu.A/!const.TCMB)^2.0 * exp(!const.h/!const.k*1d9*nu.A/!const.TCMB) / (exp(!const.h/!const.k*1d9*nu.A/!const.TCMB)-1.0)^2.0, $
                B:(!const.h/!const.k*1d9*nu.B/!const.TCMB)^2.0 * exp(!const.h/!const.k*1d9*nu.B/!const.TCMB) / (exp(!const.h/!const.k*1d9*nu.B/!const.TCMB)-1.0)^2.0}

  KCMBperY = {A:-!const.TCMB*(4 - (!const.h/!const.k*1d9*nu.A/!const.TCMB)/tanh( (!const.h/!const.k*1d9*nu.A/!const.TCMB)/2)),$
              B:-!const.TCMB*(4 - (!const.h/!const.k*1d9*nu.B/!const.TCMB)/tanh( (!const.h/!const.k*1d9*nu.B/!const.TCMB)/2))}

;##########################################################################

;Get units with the band pass (modifies the above values if needed)
  if not keyword_set(no_bandpass) then begin
     
     ;Get the bandpass
     restore, !nika.soft_dir+'/Pipeline/Run5/Calibration/BP/mspec_1mm.save'
     BP_a = m_spec[1:*]         ;Subtract noise level by hand
     BP_a[0:40] = 0.0           ;Set to 0 the unrealistic absorb
     BP_a[97:*] = 0.0           ;Set to 0 the unrealistic absorb
     freq_a = freq[1:*] * 1d9   ;to GHz and bug for f=0
     
     restore, !nika.soft_dir+'/Pipeline/Run5/Calibration/BP/mspec_2mm.save'
     BP_b = m_spec[1:*]   ;Subtract noise level by hand
     BP_b[0:25] = 0.0     ;Set to 0 the unrealistic absorb
     BP_b[52:*] = 0.0     ;Set to 0 the unrealistic absorb
     freq_b = freq[1:*] * 1d9   ;to GHz and bug for f=0
     
     ;Get atmospheric opacity
     restore, !nika.soft_dir+'/Pipeline/Run5/Calibration/Atmo/atm_pardo.save'
     opa_atmo = mmwv*(h2olin + h2ocont + h2oisot) + o2lin + drycont + o2isot + minor + meteor ;Atmo contribution
     freq_atmo = fr * 1e9
     opa_atmo = opa_atmo[0:150] ;Cuts because bug at the end
     freq_atmo = freq_atmo[0:150]
     
     opa_atmo_a = interpol(opa_atmo, freq_atmo, freq_a)
     opa_atmo_b = interpol(opa_atmo, freq_atmo, freq_b)
     
     ;Compute spectrums over the BP(atmo + instru)
     ;........ Deriv of the blackbody taken at Tcmb
     dBdT_a = 2*!const.h^2*freq_a^4/!const.k/!const.c^2/!const.TCMB^2 * $
              EXP(!const.h/!const.k*freq_a/!const.TCMB) / (EXP(!const.h/!const.k*freq_a/!const.TCMB) - 1)^2
     dBdT_b = 2*!const.h^2*freq_b^4/!const.k/!const.c^2/!const.TCMB^2 * $
              EXP(!const.h/!const.k*freq_b/!const.TCMB) / (EXP(!const.h/!const.k*freq_b/!const.TCMB) - 1)^2 
     ;........ SZ function
     sz_func_a = !const.TCMB * ((!const.h/!const.k*freq_a/!const.TCMB) * $
                                (exp(!const.h/!const.k*freq_a/!const.TCMB) + 1) / $
                                (exp(!const.h/!const.k*freq_a/!const.TCMB) - 1) - 4)
     sz_func_b = !const.TCMB * ((!const.h/!const.k*freq_b/!const.TCMB) * $
                                (exp(!const.h/!const.k*freq_b/!const.TCMB) + 1) / $
                                (exp(!const.h/!const.k*freq_b/!const.TCMB) - 1) - 4) 
     ;........ BlackBody in RJ regime
     dRJdT_a = 2*freq_a^2*!const.k/!const.c^2
     dRJdT_b = 2*freq_b^2*!const.k/!const.c^2
     ;........ Grey Body (dBdT at Tdust)
     beta = 1.6       
     Tdust = 17.0
     f0 = 1e9
     norm = 0.44*1e-7           ;We then have 1 MJy/sr at 140GHz
     dust_a = norm*(freq_a/f0)^beta * 2*!const.h^2*freq_a^4/!const.k/!const.c^2/Tdust^2 * $
              EXP(!const.h/!const.k*freq_a/Tdust) / (EXP(!const.h/!const.k*freq_a/Tdust) - 1)^2
     dust_b = norm*(freq_b/f0)^beta * 2*!const.h^2*freq_b^4/!const.k/!const.c^2/Tdust^2 * $
              EXP(!const.h/!const.k*freq_b/Tdust) / (EXP(!const.h/!const.k*freq_b/Tdust) - 1)^2
     
     ;Computes the coeffs
     int_cmb_a = int_tabulated(freq_a, dBdT_a * BP_a * exp(-opa_atmo_a)) ;W/K_CMB
     int_cmb_b = int_tabulated(freq_b, dBdT_b * BP_b * exp(-opa_atmo_b))
     
     int_rj_a = int_tabulated(freq_a, dRJdT_a * BP_a * exp(-opa_atmo_a)) ;W/K_RJ
     int_rj_b = int_tabulated(freq_b, dRJdT_b * BP_b * exp(-opa_atmo_b)) 

     int_sz_a = int_tabulated(freq_a, dBdT_a * sz_func_a * BP_a * exp(-opa_atmo_a)) ;W/y
     int_sz_b = int_tabulated(freq_b, dBdT_b * sz_func_b * BP_b * exp(-opa_atmo_b))
     
     int_dust_a = int_tabulated(freq_a, dust_a * BP_a * exp(-opa_atmo_a)) ;W/K_dust
     int_dust_b = int_tabulated(freq_b, dust_b * BP_b * exp(-opa_atmo_b))
     
     KRJperKCMB = {A:int_cmb_a/int_rj_a,$
                   B:int_cmb_b/int_rj_b} ;[KRJ/KCMB]
     KCMBperY = {A:int_sz_a/int_cmb_a,$
                 B:int_sz_b/int_cmb_b} ;[KCMB/Y]
     KDUSTperKRJ = {A:int_rj_a/int_dust_a,$
                    B:int_rj_b/int_dust_b} ;[Kdust/KRJ]
     
     ;Computes the flux for a given source
     ;F0 = 77.8                  ;mJy
     ;nu0 = 1e9                  ;Ghz
     ;pente = -0.58
     ;
     ;phi_a = int_tabulated(freq_a, F0*(freq_a/nu0)^pente * BP_a * exp(-opa_atmo_a)) /$
     ;        int_tabulated(freq_a, BP_a * exp(-opa_atmo_a)) 
     ;
     ;phi_b = int_tabulated(freq_b, F0*(freq_b/nu0)^pente * BP_b * exp(-opa_atmo_b)) /$
     ;        int_tabulated(freq_b, BP_b * exp(-opa_atmo_b)) 

  endif

  return
end
