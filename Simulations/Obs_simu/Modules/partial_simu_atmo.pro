;+
;PURPOSE: Add the atmosphere to the simulated data.
;INPUT: The parameters and the data without noise.
;OUTPUT: The simulated data with atmosphere.
;LAST EDITION: 04/02/2012
;LAST EDITOR: Remi ADAM (adam@lpsc.in2p3.fr)
;-

pro partial_simu_atmo, param, data, kidpar

  N_pt = n_elements(data)
  w_on = where(kidpar.type eq 1, n_on) ;Number of detector ON 

  time = dindgen(N_pt)/(!nika.f_sampling)

  nika_sky_noise_2, time, kidpar[w_on].nas_x*param.atmo.cloud_alt*!dpi/3600.0/180.0,$
                    kidpar[w_on].nas_y*param.atmo.cloud_alt*!dpi/3600.0/180.0,$
                    param.atmo.cloud_vx, param.atmo.cloud_vy, param.atmo.alpha, param.atmo.cloud_map_reso, $
                    sky_noise, disk_convolve=param.atmo.disk_convolve

  ;;---------- Normalized atmospheric noise (cut for non periodicity)
  for ik=0, n_on-1 do sky_noise[ik,*] = sky_noise[ik,*]/stddev(sky_noise[ik,*])
  
  for ikid=0, n_on-1 do begin
     ;;------------- Opacity attenuation
     data.RF_dIdQ[w_on[ikid]] = data.RF_dIdQ[w_on[ikid]] * exp(-kidpar[w_on[ikid]].tau0/sin(data.el))

     ;;------------- Add the atmospheric noise
     case kidpar[w_on[ikid]].array of 
        1: begin
           Fatmo_0 = param.atmo.F_0[0] 
           Fatmo_el = param.atmo.F_el[0]
        end
        2: begin
           Fatmo_0 = param.atmo.F_0[1]
           Fatmo_el = param.atmo.F_el[1]
        end
     endcase
     bruit_f = Fatmo_0 * sky_noise[ikid,*] * (1 - exp(-kidpar[w_on[ikid]].tau0/sin(data.el)))
     bruit_el = Fatmo_el * (exp(-kidpar[w_on[ikid]].tau0/sin(mean(data.el))) - $
                            exp(-kidpar[w_on[ikid]].tau0/sin(data.el)))
     data.RF_dIdQ[w_on[ikid]] = data.RF_dIdQ[w_on[ikid]] + bruit_f + bruit_el
  endfor

  return
end
