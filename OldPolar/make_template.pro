
pro make_template, n_harmonics, omega_deg, t, ampl, drift, beta

omega = omega_deg*!dtor
beta  = omega*0.0d0

; Build template
a0 = (randomu( seed, 1)*ampl)[0]
a1 = (randomn( seed, 1)*drift)[0]

C1 = randomu( seed, n_harmonics) * ampl
C2 = randomn( seed, n_harmonics) * drift
S1 = randomu( seed, n_harmonics) * ampl
S2 = randomn( seed, n_harmonics) * drift

beta = a0 + a1*t
for n=1, n_harmonics do begin
   beta = beta + (c1[n-1]+c2[n-1]*t)*cos(n*omega) + (s1[n-1]+s2[n-1]*t)*sin(n*omega)
endfor

end
