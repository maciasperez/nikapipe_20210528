function modified_atm_ratio, tau1, alpha=alpha, use_taua3=use_taua3

  ;;tau1=[0.1, 0.2, 0.5, 1., 1.2]
  
  tau2 = tau1 ;; initialising

  ;; placeholder values
  ;; to be fitted from N2R9 calibration data
  ;;if keyword_set(use_taua3) then alp=0.168d0 else alp=0.168d0
  if keyword_set(use_taua3) then alp=0.192d0 else alp=0.192d0
  if keyword_set(alpha) then alp=alpha
  
  ;; ATM model
  tau_model_file = '/home/macias/NIKA/Processing/Pipeline/Datamanage/tau_arrays_April_2018.dat'
  readcol, tau_model_file, tau1_model, tau2_model, tau3_model, format='D, D, D', /silent

  if keyword_set(use_taua3) then tau1_model = tau3_model
  
  mod_atm_r = tau2_model/tau1_model + alp

  mod_atm_ratio = interpol(mod_atm_r, tau1_model, tau1 )

  tau2 = mod_atm_ratio*tau1

  ;; test
  ;;plot, tau1_model, mod_atm_r
  ;;oplot, tau1_model, tau2_model/tau1_model, col=80
  ;;oplot, tau1, mod_atm_ratio, col=250, psym=8
  ;;oplot, tau1, tau2/tau1, col=150, psym=4, thick=2


  return, mod_atm_ratio
end
