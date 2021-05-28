function tau_model2, x, p
;                                                                       
;return, p(2)+p(1)*270.d0*x*p(0)
return, p(2)+p(0)*270.d0*(1.d0-exp(-x*p(1)))
;                                                                      
end
