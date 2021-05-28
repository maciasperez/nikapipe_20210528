;+
;
; SOFTWARE: NIKA simulation pipeline
;
; NAME: nks_data
;
; CATEGORY: general,launcher
;
; CALLING SEQUENCE:
;         nks_add_glitch, param, simpar, data, kidpar
; 
;PURPOSE: Add some glithes to the simulated data.
;INPUT: The parameters and the data.
;OUTPUT: Idem with glitches.
;LAST EDITION: 13/04/2012
;LAST EDITOR: Remi ADAM (adam@lpsc.in2p3.fr)
;-

pro nks_add_glitch, param, simpar, data, kidpar
  
  N_pt = n_elements(data)
  N_kid = n_elements(kidpar)

  prob1 = randomn(seed, N_pt, /uniform) ;Uniform entre 0 et 1
  prob2 = randomn(seed, N_pt, /uniform) ;Uniform entre 0 et 1
  
  glitch1 = simpar.glitch_mean + simpar.glitch_stddev*abs(randomn(seed,N_pt))
  glitch2 = simpar.glitch_mean + simpar.glitch_stddev*abs(randomn(seed,N_pt))
  
  glitch1[where(prob1 gt simpar.glitch_rate1mm/!nika.f_sampling)] = 0
  glitch2[where(prob2 gt simpar.glitch_rate2mm/!nika.f_sampling)] = 0

  for ikid=0, N_kid-1 do begin
     if kidpar[ikid].type eq 1 then begin
        if kidpar[ikid].array eq 1 then data.toi[ikid] = data.toi[ikid] + glitch1
        if kidpar[ikid].array eq 2 then data.toi[ikid] = data.toi[ikid] + glitch2
     endif
  endfor

  return
end
