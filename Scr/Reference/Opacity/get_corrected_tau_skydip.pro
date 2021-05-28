pro get_corrected_tau_skydip, in_tau_skydip, out_tau_nika

  ;; fit using fit_nika2_opacity_model.pro
  
  ;; a1, a2, a3, 1mm

  ;; MWC349 rms min
  ;;a = [1.37, 1.04, 1.25, 1.265]
  ;;b = [0.0, -0.01, -0.04,-0.04 ]
  ;; MWC349 chi2 min
  ;a = [1.355, 1.1, 1.235,  1.29]
  ;b = [0.0, -0.02, -0.03, -0.03 ]


  ;; MWC349 + CRL2688 + NGC7027
  ;; rms : 25, 75
  ;a = [1.40,  1.08,   1.31,  1.31 ]
  ;b = [-0.07, -0.05,  -0.12, -0.08]
  ;; chi2: 25, 75
  ;a = [1.42,  1.10,   1.29,  1.34 ]
  ;b = [-0.05, -0.05,  -0.13, -0.09]
  ;; rms : 20, 90
  ;;a = [1.35,    1.04,   1.24,   1.26 ]
  ;;b = [-0.007, -0.013,  -0.05, -0.03]
  ;; chi2: 20, 90
  ;a = [1.35,  1.09,   1.23,  1.30 ]
  ;b = [0.00, -0.02,  -0.03, -0.03]

  ;; final test
  ;a = [1.36, 1.05,   1.25,  1.28 ]
  ;b = [0.0, -0.015, -0.04, -0.03 ]

  ;; single-parameter relation
  a = [1.36, 1.03, 1.23, 1.27]
  b = [0.0,  0.0,  0.0,  0.0 ]
  
  out_tau_nika = in_tau_skydip
  for ilam = 0, 3 do begin
     out_tau_nika[*, ilam] = in_tau_skydip[*, ilam]*a[ilam] + b[ilam]
  endfor

end
  
