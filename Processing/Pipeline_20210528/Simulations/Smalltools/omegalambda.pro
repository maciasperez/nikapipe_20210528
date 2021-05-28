
function omegalambda, om_b, om_c, m_nu, H0
;+
; NB: fiducial value of the sum of the nu masses: mnu=0.06 ->
; omnu=mnu/93.04 \simeq 0.0006
;-

omnu=m_nu/93.04
Om_L = 1. - (om_b+om_c+omnu)/H0^2*1.e4
return,Om_L
end
