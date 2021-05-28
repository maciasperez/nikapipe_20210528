function tau_model4sim2, x, p
;                                                                       
  return, p[4]+p[0]*270.d0*( p[3]*(1.d0-exp(-x*p[2])) + $
                             (1-p[3])*(1.d0-exp(-x*p[1])))
;                                                                      
end
