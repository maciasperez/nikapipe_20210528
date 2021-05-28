
;; Recover fig. 3.4 of Dana's thesis
;; Careful with p values she puts in x that are variable and sometimes larger
;; than 1 ?

I0 = 1.d0
p0 = 0.1
psi0_deg = 0.d0

;; ;; 2D likelihoods
;; p0_over_sigma_p = [0.01, 0.5, 1, 5]
;; np = n_elements(p0_over_sigma_p)
;; wind, 1, 1, /free, /large
;; my_multiplot, 4, 2, /rev, pp, pp1
;; p_res   = dblarr(np)
;; psi_res = dblarr(np)
;; for ip=0, np-1 do begin
;;    sigma_p = p0/p0_over_sigma_p[ip]
;;    sigma_q = sigma_p*I0 ; equation (3.20)
;;    montier2d_test, i0, p0, psi0_deg, sigma_q, pol_deg, alpha_deg, $
;;                    /plot, position=pp1[ip,*]
;;    p_res[ip]   = pol_deg
;;    psi_res[ip] = alpha_deg
;; endfor

;; Bias
p_snr_max = 5
p_snr_min = 0.01
npsnr = 100
p0_over_sigma_p = dindgen(npsnr)/(npsnr-1)*(p_snr_max-p_snr_min) + p_snr_min
p_res = dblarr(npsnr)
sigma_p_res = dblarr(npsnr)
;; stop
;; for ip=0, npsnr-1 do begin
;;    sigma_p = p0/p0_over_sigma_p[ip]
;;    sigma_q = sigma_p*I0         ; equation (3.20)
;;    montier2d_test, i0, p0, psi0_deg, sigma_q, pol_deg, alpha_deg
;;    p_res[ip]   = pol_deg
;;    sigma_p_res[ip] = sigma_p
;; endfor

npsnr = 100
snr_list = dindgen(npsnr)/(npsnr-1) * 5
p_res = dblarr(npsnr)
sigma_p = 0.01
p0_res = dblarr(npsnr)
for ip=0, npsnr-1 do begin
   p0 = snr_list[ip]*sigma_p
   p0_res[ip] = p0
   montier2d_test_p, p0, psi0_deg, sigma_p, pol_deg, alpha_deg
   p_res[ip]   = pol_deg
endfor   

wind, 1, 1, /f
yra = [-0.5, 1.6]
plot, p0_res/sigma_p, (p_res-p0_res)/sigma_p, $
      /noerase, xtitle='p snr', ytitle='(p_res-p0)/sigma_p', $
      yra=yra, /ys
legendastro, 'sigma_p: '+strtrim(sigma_p,2), /right
oplot, [0, 10], [0,0], line=2

nmc = 1000
npsnr = 10
p_res = dblarr(npsnr)
















stop



;;=====================================================================================














nmc = 10

;sigma_i = 0.1
;sigma_q = 0.1*sqrt(2)
;sigma_u = sigma_q


psi0_deg = 30.
p0   = 0.5 ;0.1

npsnr = 50
p_snr_max = 5
p_snr = 0.1 + dindgen(npsnr)/(npsnr-1)*p_snr_max

;;------------------------------
psi0 = psi0_deg * !dtor

I0 = 1.d0
Q0 = p0*cos(2*psi0)*I0
U0 = p0*sin(2*psi0)*I0

p_res   = dblarr(npsnr)
psi_res = dblarr(npsnr)
sigma_p_res = dblarr(npsnr)
for ip=0, npsnr-1 do begin
   sigma_p = p0/p_snr[ip]
   sigma_p_res[ip] = sigma_p
   montier2d_test, I0, p0, psi0_deg, sigma_p, pol_deg, alpha_deg
   p_res[ip] = pol_deg
   psi_res[ip] = psi_res[ip]
endfor

wind, 1, 1, /free, /large
my_multiplot, 1, 2, pp, pp1, /rev
plot, p_snr, p_res, xtitle='P SNR', ytitle='P!dres!n', $
      position=pp1[0,*]
plot, p_snr, (p_res-p0)/sigma_p_res, xtitle='P SNR', ytitle='(p-p0)/sigma_p', $
      position=pp1[1,*], /noerase


end
