
;; NET is in microK/sqrt(Hz)

pro nk_noise_1d, n_samples, f_sample, noise, noise_model, freq, $
                 net=net, fknee=fknee, alpha=alpha, white_noise=white_noise

if n_params() lt 1 then begin
   message, /info, "calling sequence: "
   print, "nk_noise_1d, n_samples, f_sample, noise, noise_model, freq, net=net, fknee=fknee, alpha=alpha, white_noise=white_noise"
   return
endif

if not keyword_set(fknee) then fknee = 0.0d0
if not keyword_set(net)   then net   = 1.0d0
if not keyword_set(alpha) then alpha = 0.0d0

delta_t  = 1.0d0/f_sample
delta_nu = 1./(n_samples*delta_t)

n_mid = n_samples/2             ; integer
freq = dblarr(n_samples)
freq[0:n_mid]   = dindgen(n_mid+1)
freq[n_mid+1:*] = -reverse( dindgen( n_samples-n_mid-1)+1)
freq = freq/(n_samples/f_sample)

noise_model = freq*0.d0
w = where( freq ne 0, nw)

;; If NET was in microK.sqrt(sec), then NET here would be (NET*sqrt(2.d0))
if keyword_set(white_noise) then begin
   noise_model[w] = dblarr(nw) + NET ; *sqrt(2.d0)
endif else begin
   noise_model[w] = sqrt( ( 1.d0 + (fknee/abs(freq[w]))^alpha )) * NET ; * sqrt(2.d0)
endelse

noise = fft( randomn( seed, n_samples), /double)
noise = noise * noise_model * sqrt(f_sample)
noise = double( fft( noise, /double, /inv))

end
