function tau_model4sim, x, p
;                                                                       
return, p(2)+p(0)*270.d0*(1.d0-exp(-x*p(1)))
;                                                                      
end
