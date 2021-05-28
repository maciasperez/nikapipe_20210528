
;; Take C0 and C1 coefficients coming from kidpar_skydip and puts them
;; into kidpar

pro skydip_coeffs, kidpar_in_file, kidpar_skydip_file, kidpar_out_file

  
kidpar_skydip = mrdfits( kidpar_skydip_file, 1)
kidpar        = mrdfits( kidpar_in_file, 1)

w1 = where( kidpar_skydip.type eq 1, nw1)
w  = where( kidpar.type eq 1, nw)
kidpar_skydip = kidpar_skydip[w1]
kidpar  = kidpar[w]
my_match, kidpar.numdet, kidpar_skydip.numdet, suba, subb
kidpar.c0_skydip = 0.d0
kidpar.c1_skydip = 0.d0
kidpar[suba].c0_skydip = kidpar_skydip[subb].c0_skydip
kidpar[suba].c1_skydip = kidpar_skydip[subb].c1_skydip

nk_write_kidpar, kidpar, kidpar_out_file

end
