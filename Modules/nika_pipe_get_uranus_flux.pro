;+
;PURPOSE: Compute the expected flux of Uranus based on its brigthness
;         temperature model and the NIKA BP
;
;INPUT: the wavelength in mm and the diameter of Uranus
;
;OUTPUT: The expected flux
;
;LAST EDITION: 10/02/2014: creation(adam@lpsc.in2p3.fr)
;-

function nika_pipe_get_uranus_flux, lambda_mm, diam_planet_arcsec, $
                                    mmwv=mmwv, run=run, T_bright=T_bright, neptune=neptune
  
  if not keyword_set(mmwv) then mmwv = 1.0 ;Default value for mm of water vapor
  bp_file = !nika.soft_dir+'/Pipeline/Calibration/BP/NIKA_bandpass_Run7.fits'
  if keyword_set(run) then begin
     if run eq '5' then bp_file = !nika.soft_dir+'/Run5_pipeline/Calibration/BP/NIKA_bandpass_Run5.fits'
     if run eq '6' then bp_file = !nika.soft_dir+'/Run6_pipeline/Calibration/BP/NIKA_bandpass_Run6.fits'
  endif

  ;;------- Get the bandpass
  case round(lambda_mm) of
     1: begin
        mpi = mrdfits(bp_file, 1, head, /silent)
        BP = mpi.nikatrans
        freq = mpi.freq
        freq = freq[1:*] * 1d9  ;to GHz and bug for f=0
        BP = BP[1:*]
     end
     
     2:begin
        mpi = mrdfits(bp_file, 2, head, /silent)
        BP = mpi.nikatrans
        freq = mpi.freq
        freq = freq[1:*] * 1d9  ;to GHz and bug for f=0
        BP = BP[1:*]
     end
  endcase
    
  ;;------- Get atmospheric opacity
  restore, !nika.soft_dir+'/Run5_Pipeline/Calibration/Atmo/atm_pardo.save'
  opa_atmo = mmwv*(h2olin + h2ocont + h2oisot) + o2lin + drycont + o2isot + minor + meteor ;Atmo contribution
  freq_atmo = fr * 1e9
  opa_atmo = opa_atmo[0:150]    ;Cuts because bug at the end
  freq_atmo = freq_atmo[0:150]
  
  opa_atmo = interpol(opa_atmo, freq_atmo, freq)
  
  ;;------- Get brightness temperature model and deduce flux
  if keyword_set(neptune) then name_pl = 'Neptune' else  name_pl = 'Uranus'
  readcol, !nika.soft_dir+'/Pipeline/Calibration/Planet_Brightness/'+name_pl+'_flux_model.csv', $
           freq_temp, T_bright, tot_flux, T_rj, format='(A,F,F)'

  ;;T_planet = interpol(T_rj, freq_temp*1d9, freq)
  T_planet = interpol(T_bright, freq_temp*1d9, freq)
  T_bright = int_tabulated(freq, T_planet*BP*exp(-opa_atmo)/freq^2)/int_tabulated(freq,BP*exp(-opa_atmo)/freq^2) 

  ;;phi = 2*(freq)^2/!const.c^2 *!const.k*T_planet*1e26*!pi*(diam_planet_arcsec/2.0/3600.0/180*!pi)^2 
  phi = 2*!const.h*(freq)^3/!const.c^2/(exp(!const.h*freq/!const.k/T_planet) - 1)* $
        !pi*(diam_planet_arcsec/2.0/3600.0/180*!pi)^2 *1e26
  
  ;;------- Computes the coeffs
  flux_jy = int_tabulated(freq, phi*BP*exp(-opa_atmo)/freq^2)/int_tabulated(freq,BP*exp(-opa_atmo)/freq^2) 
  
  return, flux_jy
end
