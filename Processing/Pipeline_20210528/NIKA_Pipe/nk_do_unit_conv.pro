;+
;PURPOSE: Integrate spectra over the bandpasses in order to provide
;         unit conversion coefficients
;
;INPUT: - lambda_mm: the wavelenght in mm
;       - bp_file: the bandpass fits file (string)
;
;OUTPUT: - Kcmb2Krj: Kelvin CMB to Kelvin RJ
;        - Ytsz2Kcmb: tSZ Compton parameter to Kelvin CMB
;        - JyPerSr2Ytsz: Jy per sr to tSZ Compton parameter
;        - Yksz2Kcmb: kSZ Compton parameter to Kelvin CMB
;        - JyPerSr2Yksz: Jy per sr to kSZ Compton parameter
;        - colcor_dust: dust color correction (spectrum nu^beta x B_nu(T))
;        - colcor_radio: radio color correction (spectrum nu^alpha)
;
;LAST EDITION: 
;   2013: Creation (adam@lpsc.in2p3.fr)
;   25/01/2014: cleaning and correcting the color corrections
;   14/01/2015: add calculation of Ytsz2JyPerSr
;-

;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_do_unit_conv
;
; CATEGORY: ?
;
; CALLING SEQUENCE:
; nk_do_unit_conv, lambda_mm, bp_file, Kcmb2Krj, Ytsz2Kcmb, Yksz2Kcmb, $
;                  Ytsz2JyPerSr,colcor_dust, colcor_radio, mmwv=mmwv, $
;                  no_bandpass=no_bandpass, beta_dust=beta_dust, T_dust=T_dust
;                  alpha_radio=alpha_radio, t_kev=t_kev, v_kmps=v_kmps, diffuse=diffuse
;
; PURPOSE: 
;        compute units conversions
; 
; INPUT: 
; 
; OUTPUT: 
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Sept. 11th, 2015: Strict copy of old nika_pipe_unit_conv.pro
;-


pro nk_do_unit_conv, lambda_mm, bp_file, $
                     Kcmb2Krj, Ytsz2Kcmb, Yksz2Kcmb, Ytsz2JyPerSr,$ ; Yksz2JyPerSr, $
                     colcor_dust, colcor_radio, $
                     mmwv=mmwv, $                   ;Precipitable water vapor (default is 1mm)
                     no_bandpass=no_bandpass, $     ;To be set is the bandpass are not used
                     beta_dust=beta_dust, $         ;Grey body spectral index
                     T_dust=T_dust, $               ;Grey body temperature
                     alpha_radio=alpha_radio, $     ;Power law spectrum index
                     t_kev=t_kev, $                 ;Galaxy cluster temperature in KeV
                     v_kmps=v_kmps,$                ;Galaxy cluster velocity in km/s
                     diffuse=diffuse                ;The source is extended
  
  if not keyword_set(beta_dust) then beta_dust = 1.6
  if not keyword_set(T_dust) then T_dust = 17.0
  if not keyword_set(alpha_radio) then alpha_radio = -0.7

  nu_GHz = !const.c*1d-6/lambda_mm

  ;;############## Get units assuming Dirac function for band pass first
  if keyword_set(no_bandpass) then begin
     Kcmb2Krj = 1.d0/rj2thermo(nu_GHz)
     colcor_dust = 1.0
     colcor_radio = 1.0

     Icmb = 2*!const.h*(nu_ghz*1d9)^3/!const.c^2 / (exp(!const.h*(nu_ghz*1d9)/!const.k/!cst.TCMB) - 1)

     ;;------- tSZ including relativistic correction
     if keyword_set(t_kev) then begin
        cor_tsz = rel_corr_batch_kincorr(1.0, t_kev, 1.0, !const.tcmb, freq_ghz=nu_ghz, 1) / $
                  rel_corr_batch_kincorr(1.0, t_kev, 1.0, !const.tcmb, freq_ghz=nu_ghz, 0)
     endif else cor_tsz = 1.0
     
     Ytsz2Kcmb = -cor_tsz * !cst.TCMB*(4.d0 - (!const.h/!const.k*1d9*nu_GHz/!cst.TCMB)/$
                                       tanh((!const.h/!const.k*1d9*nu_GHz/!cst.TCMB)/2.d0))
     
     Ytsz2JyPerSr = - cor_tsz * 1d26* Icmb * (!const.h/!const.k*(nu_ghz*1d9)/!cst.TCMB)^4 * $
                    exp(!const.h/!const.k*(nu_ghz*1d9)/!cst.TCMB) / $
                    (exp(!const.h/!const.k*(nu_ghz*1d9)/!cst.TCMB) - 1)^2 * $
                    (4.d0 - (!const.h/!const.k*(nu_ghz*1d9)/!cst.TCMB)/$
                     tanh((!const.h/!const.k*(nu_ghz*1d9)/!cst.TCMB)/2.d0))

     ;;------- kSZ Relativistic correction
     if keyword_set(v_kmps) then begin
        if not keyword_set(t_kev) then message, 'For kSZ relativistic correction one need both T_e and V'
        cor_ksz = rel_corr_batch_kincorr(1.0, t_kev, v_kmps, !const.tcmb, freq_ghz=nu_ghz, 3) / $
                  rel_corr_batch_kincorr(1.0, t_kev, v_kmps, !const.tcmb, freq_ghz=nu_ghz, 2)
     endif else cor_ksz = 1.0

     Yksz2Kcmb = cor_ksz * !cst.TCMB
     
     ;;Yksz2JyPerSr = cor_ksz* 1d26 * Icmb * (!const.h/!const.k*(nu_ghz*1d9)/!cst.TCMB)^4 * $
     ;;               exp(!const.h/!const.k*(nu_ghz*1d9)/!cst.TCMB) / $
     ;;               (exp(!const.h/!const.k*(nu_ghz*1d9)/!cst.TCMB) - 1)^2
     
  endif
  
  ;;############## Get units assuming Dirac function for band pass first
  if not keyword_set(no_bandpass) then begin
     ;;------- Get units with the band pass (modifies the above values if needed)
     if not keyword_set(mmwv) then mmwv = 1.0 ;Default value for mm of water vapor
     
     ;;------- Get the bandpass
     case round(lambda_mm) of
        1: begin
           mpi = mrdfits(bp_file, 1, head, /silent)
           BP = mpi.nikatrans
           freq = mpi.freq
           freq = freq[1:*] * 1d9 ;to GHz and bug for f=0
           BP = BP[1:*]
        end
        
        2:begin
                                ;mpi = mrdfits(bp_file, 3, head, /silent)
           mpi = mrdfits(bp_file, 2, head, /silent)
           BP = mpi.nikatrans
           freq = mpi.freq
           freq = freq[1:*] * 1d9 ;to GHz and bug for f=0
           BP = BP[1:*]
        end
     endcase
     
     ;;------- Get atmospheric opacity
     restore, !nika.pipeline_dir+"/Photometry/atm_pardo.save"
     opa_atmo = mmwv*(h2olin + h2ocont + h2oisot) + o2lin + drycont + o2isot + minor + meteor ;Atmo contribution
     freq_atmo = fr * 1e9
     opa_atmo = opa_atmo[0:150] ;Cuts because bug at the end
     freq_atmo = freq_atmo[0:150]
     opa_atmo = interpol(opa_atmo, freq_atmo, freq)
     
     ;;------- Compute spectrums over the BP
     ;;....... BlackBody at Tcmb
     Icmb = 2*!const.h*freq^3/!const.c^2 / (exp(!const.h*freq/!const.k/!cst.TCMB) - 1)

     Icmb_nu = 2*!const.h*(nu_ghz*1d9)^3/!const.c^2 / (exp(!const.h*(nu_ghz*1d9)/!const.k/!cst.TCMB) - 1)

     ;;....... Derivative of the blackbody taken at Tcmb
     dBBdT = 2*!const.h^2*freq^4/!const.k/!const.c^2/!cst.TCMB^2 * $
             EXP(!const.h/!const.k*freq/!cst.TCMB) / (EXP(!const.h/!const.k*freq/!cst.TCMB) - 1)^2
     
     dBBdT_nu = 2*!const.h^2*(nu_ghz*1d9)^4/!const.k/!const.c^2/!cst.TCMB^2 * $
                EXP(!const.h/!const.k*(nu_ghz*1d9)/!cst.TCMB) / $
                (EXP(!const.h/!const.k*(nu_ghz*1d9)/!cst.TCMB) - 1)^2

     ;;....... BlackBody in RJ regime
     dRJdT = 2*freq^2*!const.k/!const.c^2

     dRJdT_nu = 2*(nu_ghz*1d9)^2*!const.k/!const.c^2

     ;;....... Grey Body
     dust = (freq)^beta_dust * 2*!const.h*freq^3/!const.c^2 / (EXP(!const.h/!const.k*freq/T_dust) - 1)
     
     dust_nu = (nu_ghz*1d9)^beta_dust * 2*!const.h*(nu_ghz*1d9)^3/!const.c^2 / $
               (EXP(!const.h/!const.k*(nu_ghz*1d9)/T_dust) - 1)
     
     ;;........ Power law spectrum (synchrotron is default)
     radio = (freq)^alpha_radio
     radio_nu = (nu_ghz*1d9)^alpha_radio
     
     ;;....... tSZ function
     ;;dTcmb = y x tszKcmb [Kcmb]
     tszKcmb = -!cst.TCMB*(4.d0 - (!const.h/!const.k*freq/!cst.TCMB)/$
                           tanh((!const.h/!const.k*freq/!cst.TCMB)/2.d0))
     
     tszKcmb_nu = -!cst.TCMB*(4.d0 - (!const.h/!const.k*1d9*nu_GHz/!cst.TCMB)/$
                              tanh((!const.h/!const.k*1d9*nu_GHz/!cst.TCMB)/2.d0))

     ;;dI = y x tszI [Jy/sr]
     tszI = dBBdT * tszKcmb
     

     tszI = - 1d26* Icmb * (!const.h/!const.k*freq/!cst.TCMB)^4 * exp(!const.h/!const.k*freq/!cst.TCMB) / $
            (exp(!const.h/!const.k*freq/!cst.TCMB) - 1)^2 * $
            (4.d0 - (!const.h/!const.k*freq/!cst.TCMB)/$
             tanh((!const.h/!const.k*freq/!cst.TCMB)/2.d0))
     
     tszI_nu = - 1d26* Icmb * (!const.h/!const.k*(nu_ghz*1d9)/!cst.TCMB)^4 * $
               exp(!const.h/!const.k*(nu_ghz*1d9)/!cst.TCMB) / $
               (exp(!const.h/!const.k*(nu_ghz*1d9)/!cst.TCMB) - 1)^2 * $
               (4.d0 - (!const.h/!const.k*(nu_ghz*1d9)/!cst.TCMB)/$
                tanh((!const.h/!const.k*(nu_ghz*1d9)/!cst.TCMB)/2.d0))
     
     ;;Relativistic correction
     if keyword_set(t_kev) then begin
        cor_tsz = rel_corr_batch_kincorr(1.0, t_kev, 1.0, !const.tcmb, freq_ghz=freq*1e-9, 1) / $
                  rel_corr_batch_kincorr(1.0, t_kev, 1.0, !const.tcmb, freq_ghz=freq*1e-9, 0)
     endif else cor_tsz = freq*0+1
     tszkCMB *= cor_tsz
     tszkCMB_nu *= interpol(cor_tsz, freq, nu_ghz*1d9)
     tszI *= cor_tsz
     tszI_nu *= interpol(cor_tsz, freq, nu_ghz*1d9)

     ;;....... kSZ function
     ;;dTcmb = y x tszKcmb [Kcmb]
     kszKcmb = 1 + freq*0
     
     kszKcmb_nu = !cst.tcmb
     
     ;;dI = y x kszI [Jy/sr]
     ;;kszI = 1d26 * Icmb * (!const.h/!const.k*freq/!cst.TCMB)^4 * exp(!const.h/!const.k*freq/!cst.TCMB) / $
     ;;       (exp(!const.h/!const.k*freq/!cst.TCMB) - 1)^2
     ;;
     ;;kszI_nu = 1d26 * Icmb * (!const.h/!const.k*(nu_ghz*1d9)/!cst.TCMB)^4 * $
     ;;          exp(!const.h/!const.k*(nu_ghz*1d9)/!cst.TCMB) / $
     ;;          (exp(!const.h/!const.k*(nu_ghz*1d9)/!cst.TCMB) - 1)^2

     ;;Relativistic correction
     if keyword_set(v_kmps) then begin
        if not keyword_set(t_kev) then message, 'For kSZ relativistic correction one need both T_e and V'
        cor_ksz = rel_corr_batch_kincorr(1.0, t_kev, v_kmps, !const.tcmb, freq_ghz=freq*1e-9, 3) / $
                  rel_corr_batch_kincorr(1.0, t_kev, v_kmps, !const.tcmb, freq_ghz=freq*1e-9, 2)
     endif else cor_ksz = freq*0+1
     kszKcmb *= cor_ksz
     kszKcmb_nu *= interpol(cor_ksz, freq, nu_ghz*1d9)
     ;;kszI *= cor_ksz
     ;;kszI_nu *= interpol(cor_ksz, freq, nu_ghz*1d9)

     ;;------- Computes the coeffs
     if not keyword_set(diffuse) then fxd_factor = 1.0/freq^2 else fxd_factor = 1.0
     int_tsz   = int_tabulated(freq, dBBdT  * BP*fxd_factor * exp(-opa_atmo) * tszKcmb) ;[W/y_tSZ]
     int_ksz   = int_tabulated(freq, dBBdT  * BP*fxd_factor * exp(-opa_atmo) * kszKcmb) ;[W/y_kSZ]
     int_cmb  = int_tabulated(freq,  dBBdT  * BP*fxd_factor * exp(-opa_atmo))           ;[W/Kcmb]
     int_rj   = int_tabulated(freq,  dRJdT  * BP*fxd_factor * exp(-opa_atmo))           ;[W/Krj]
     int_dust = int_tabulated(freq,  dust   * BP*fxd_factor * exp(-opa_atmo))           ;[W]
     int_radio = int_tabulated(freq, radio  * BP*fxd_factor * exp(-opa_atmo))           ;[W]
     
     Kcmb2Krj = int_cmb/int_rj   ;[Krj/Kcmb]
     Ytsz2Kcmb = int_tsz/int_cmb ;[Kcmb/y_tsz]
     Yksz2Kcmb = int_ksz/int_cmb ;[Kcmb/y_ksz]
     Ytsz2JyPerSr = int_tabulated(freq, tszI * BP*fxd_factor * exp(-opa_atmo)) / $
                    int_tabulated(freq, BP*fxd_factor * exp(-opa_atmo)) ;[(Jy/sr)/y_tsz]
     ;;Yksz2JyPerSr =              ;[(Jy/sr)/y_ksz]

     colcor_dust = (int_dust / dust_nu) / (int_rj / dRJdT_nu)
     colcor_radio = (int_radio / radio_nu) / (int_rj / dRJdT_nu)
  endif
  
  return
end
