;;Simulation of the atmospheric noise in the TOI
;;The noise is assumed to be A0(t) + A1(t) * (X-X0) + A2(t) * (Y-Y0)

pro genere_atmo,x_on_a,y_on_a,x_off_a,y_off_a,x_on_b,y_on_b,x_off_b,y_off_b,param, A0, A1, A2, x_rel, y_rel
  
;;;;;;;;;;;;; EVOLUTION TEMPORELLE DE L'ATMOSPHERE ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  x0_a = avg([x_on_a[*,0], x_off_a[*,0]]) ;Center off the matrix A
  y0_a = avg([y_on_a[*,0], y_off_a[*,0]]) ;
  x0_b = avg([x_on_b[*,0], x_off_b[*,0]]) ;Center off the matrix B
  y0_b = avg([y_on_a[0,*], y_off_a[0,*]]) ;
  
  x_on_a_rel = reform(x_on_a[*,0])-x0_a   ;Distance from 
  y_on_a_rel = reform(y_on_a[*,0])-y0_a   ;the center
  x_off_a_rel = reform(x_off_a[*,0])-x0_a ;for all 
  y_off_a_rel = reform(y_off_a[*,0])-y0_a ;KIDs
  x_on_b_rel = reform(x_on_b[*,0])-x0_b   ;
  y_on_b_rel = reform(y_on_b[*,0])-y0_b   ;
  x_off_b_rel = reform(x_off_b[*,0])-x0_b ;
  y_off_b_rel = reform(y_off_b[*,0])-y0_b ;
  
  x_rel = {on_a:x_on_a_rel,off_a:x_off_a_rel,on_b:x_on_b_rel,off_b:x_off_b_rel} ;Distance from the center for each KID
  y_rel = {on_a:y_on_a_rel,off_a:y_off_a_rel,on_b:y_on_b_rel,off_b:y_off_b_rel} ;during the scan

;Toute la carte atmospherique est simulee par un plan qui evolue
;dans le temps: A0(t) + A1(t) (x_i - x0) + A2(t) (y_i - y0)
;avec l'orientation du plan fixee: atan(A2/A1) = constant
  N_pt = n_elements(x_on_a[0,*])
  f1 = param.freq_ech/(2*N_pt)
  f2 = param.freq_ech/2

  ki = dindgen(N_pt) - N_pt/2.0
  k = ki
  k(0:N_pt/2.0-1) = ki(N_pt/2.0:N_pt-1)
  k(N_pt/2.0:N_pt-1) = ki(0:N_pt/2.0-1)

  A0 = randomn(seed,N_pt)     
  FT_A0 = FFT(A0,/double)
  FT_A0 = FT_A0 * abs(k)^param.alpha
  FT_A0[0] = 0.0
  A0 = float(FFT(FT_A0,/inverse,/double))
  A0 = A0/stdev(A0)*param.T_fluc*sqrt(param.f_ref)*sqrt(((f2/param.f_ref)^(1+2*param.alpha)-(f1/param.f_ref)^(1+2*param.alpha))/(1+2*param.alpha))

  A1 = randomn(seed,N_pt)
  FT_A1 = FFT(A1,/double)
  FT_A1 = FT_A1 * abs(k)^(param.alpha*0.7)
  FT_A1[0] = 0.0
  A1 = float(FFT(FT_A1,/inverse,/double))
  A1 = A1/stdev(A1)*stdev(A0)/100d/max(x_rel.on_a)
  
  A2 = randomn(seed)*A1         ;A2/A1 is constant <=> the direction of the plan is fixed

  return
end
