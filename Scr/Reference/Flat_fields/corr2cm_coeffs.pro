
;; Take CORR2CM coefficients coming from kidpar_corr2cm and puts them
;; into kidpar_in to obtain kidpar_out

pro corr2cm_coeffs, kidpar_in, kidpar_corr2cm, kidpar_out

kidpar_out = kidpar_in
w1 = where( kidpar_corr2cm.type eq 1, nw1)
w  = where( kidpar_out.type eq 1, nw)
kidpar_corr2cm = kidpar_corr2cm[w1]
kidpar_out     = kidpar_out[w]
my_match, kidpar_out.numdet, kidpar_corr2cm.numdet, suba, subb
kidpar_out.corr2cm = 0.d0
kidpar_out[suba].corr2cm = kidpar_corr2cm[subb].corr2cm


end
