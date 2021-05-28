
;+
;
; SOFTWARE: NIKA simulation pipeline
;
; NAME: nks_gen_uncorr_noise
;
; CATEGORY:
;
; CALLING SEQUENCE:
;         nks_add_uncorr_noise, simpar, data, kidpar
; 
; PURPOSE: 
;        Adds uncorrelated noise to kid timelines
; 
; INPUT: 
;        - simpar: the simulation parameter structure
;        - data: the data structure
;        - kidpar : the kid structure
; 
; OUTPUT: 
;        - data
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Jan 19th, 2021: NP, adpated from nks_add_uncorr_noise


pro nks_gen_uncorr_noise, nsn, param, simpar, info,  kidpar, noise_toi
;-

if n_params() lt 1 then begin
   dl_unix, 'nks_gen_uncorr_noise'
   return
endif

if simpar.white_noise or (simpar.kid_net ne 0 and $
                          simpar.kid_fknee ne 0 and $
                          simpar.kid_alpha_noise ne 0) then begin

   nkids = n_elements(kidpar)
   noise_toi = dblarr(nkids, nsn)

   for ikid=0, nkids-1 do begin
      if kidpar[ikid].type eq 1 then begin
         ;; Jan 2021: kidpar.noise is now in Jy/beam, it is an rms so convert it back to NET=sqrt(rms^2/fsamp) in Jy/beam. s1/2
         NET = kidpar[ikid].noise/ sqrt(!nika.f_sampling)
         nks_noise_1d, nsn, !nika.f_sampling, noise, noise_model, freq, $
                       net=NET, fknee=simpar.kid_fknee, $
                       alpha=simpar.kid_alpha_noise, white_noise=simpar.white_noise
         noise_toi[ikid,*] = noise
      endif
   endfor
endif


end
