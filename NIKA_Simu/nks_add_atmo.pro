;+
;
; SOFTWARE: 
;           NIKA Simulations Pipeline
; NAME:
;           nks_add_atmo.pro    
; 
; PURPOSE: 
;           Add the atmosphere to the simulated data.
; INPUT: 
;           The parameters and the data without noise.
; OUTPUT: 
;           The simulated data with atmosphere.
; KEYWORDS:
;           NONE
; EXAMPLE:
;
; MODIFICATION HISTORY: 
;           22/05/2015: Alessia Ritacco (ritacco@lpsc.in2p3.fr) 
;           creation from partial_simu_atmo.pro (Remi ADAM - adam@lpsc.in2p3.fr)
;
;-

pro nks_add_atmo, param, simpar, data, kidpar

  N_pt = n_elements(data)
  w_on = where(kidpar.type eq 1, n_on) ;Number of detector ON 

  time = dindgen(N_pt)/(!nika.f_sampling)
  
  nk_sky_noise, time, kidpar[w_on].nas_x*simpar.atm_cloud_alt*!dpi/3600.0/180.0,$
                kidpar[w_on].nas_y*simpar.atm_cloud_alt*!dpi/3600.0/180.0,$
                simpar.atm_cloud_vx, simpar.atm_cloud_vy, simpar.atm_alpha,$
                simpar.atm_cloud_reso, $
                sky_noise, /disk_convolve

  ;;---------- Normalized atmospheric noise (cut for non periodicity)
  for ik=0, n_on-1 do sky_noise[ik,*] = sky_noise[ik,*]/stddev(sky_noise[ik,*])
  
  for ikid=0, n_on-1 do begin
     ;;------------- Opacity attenuation
     data.toi[w_on[ikid]] = data.toi[w_on[ikid]] * exp(-kidpar[w_on[ikid]].tau_skydip/sin(data.el))
    
     ;;------------- Add the atmospheric noise
     case kidpar[w_on[ikid]].array of 
        1: begin
           Fatmo_0 = simpar.atm_F01mm[0] 
           Fatmo_el = simpar.atm_Fel1mm[0]
        end
        2: begin
           Fatmo_0 = simpar.atm_F02mm[0]
           Fatmo_el = simpar.atm_Fel2mm[0]
        end
     endcase
     bruit_f = Fatmo_0 * sky_noise[ikid,*] * (1 - exp(-kidpar[w_on[ikid]].tau_skydip/sin(data.el)))
     bruit_el = Fatmo_el * (exp(-kidpar[w_on[ikid]].tau_skydip/sin(mean(data.el))) - $
                            exp(-kidpar[w_on[ikid]].tau_skydip/sin(data.el)))
     data.toi[w_on[ikid]] = data.toi[w_on[ikid]] + bruit_f + bruit_el
     
  endfor

  return
end
