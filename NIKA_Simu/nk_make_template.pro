;+
;
; SOFTWARE: NIKA simulation pipeline
;
; NAME: nk_make_template
;
; CATEGORY:
;
; CALLING SEQUENCE:
;         nk_make_template, param, data, kidpar
; 
; PURPOSE: 
;         make a template of HWP harmonics.
; INPUT: 
;        - n_harmonics: number of HWP harmonics
;        - omega_deg: HWP rotation frequency
; 
; OUTPUT: 
;        - beta
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - May 24, 2015: creation (Alessia Ritacco & Nicolas Ponthieu
;          - ritacco@lpsc.in2p3.fr)
;-

pro nk_make_template, param, data, kidpar

n_harmonics = param.polar_n_template_harmonics
nsn   = n_elements( data)
nkids = n_elements(kidpar)
t = dindgen(nsn)/!nika.f_sampling
ampl = 100
drift = 0.01
;; omega = (2*!dpi*param.polar_nu_rot_hwp*t) mod (2*!dpi)
beta  = data.c_position*0.0d0
beta_coeff = randomn( seed, nkids) ; HWP template amplitudes

; Build template
a0 = (randomu( seed, 1)*ampl)[0]
a1 = (randomn( seed, 1)*drift)[0]

C1 = randomu( seed, n_harmonics) * ampl
C2 = randomn( seed, n_harmonics) * drift
S1 = randomu( seed, n_harmonics) * ampl
S2 = randomn( seed, n_harmonics) * drift

beta = a0 + a1*t
;; for n=1, n_harmonics-1 do beta = beta + (c1[n-1]+c2[n-1]*t)*cos(n*data.c_position) + (s1[n-1]+s2[n-1]*t)*sin(n*data.c_position)
for n=1, n_harmonics do beta = beta + (c1[n-1]+c2[n-1]*t)*cos(n*data.c_position) + (s1[n-1]+s2[n-1]*t)*sin(n*data.c_position)

for ikid=0, nkids-1 do data.toi[ikid,*] = data.toi[ikid,*] + beta_coeff[ikid]*beta

end
