;+
;
; SOFTWARE: NIKA simulation pipeline
;
; NAME: nks_add_elec
;
; CATEGORY: general,launcher
;
; CALLING SEQUENCE:
;         nks_add_elec, simpar, data, kidpar
; 
; PURPOSE: 
;         The electronic and white noise are added to the TOI here
; INPUT: 
;         Jansky data with source and atmosphere.
;         Simpar
; OUTPUT: 
;         toi with electronic and white noise.
; KEYWORDS: 
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - May 25rd, 2015: creation (Alessia Ritacco & Nicolas
;          Ponthieu - ritacco@lpsc.in2p3.fr)
;          From partial_simu_elec.pro - Remi Adam
;-

pro nks_add_elec, param, simpar, data, kidpar
  
  ;;----------- Detectors info
  N_pt = n_elements(data)
  N_kid = n_elements(kidpar)

  wa_on = where(kidpar.type eq 1 and kidpar.array eq 1)
  wb_on = where(kidpar.type eq 1 and kidpar.array eq 2)

  ;;----------- frequency info
  k = dindgen(N_pt/2+1)/double(N_pt/2) * !nika.f_sampling/2.0
  if ((N_pt mod 2) eq 0) then k=[k, -1*reverse(k[1:N_pt/2-1])]
  if ((N_pt mod 2) eq 1) then k=[k, -1*reverse(k[1:*])]
  
  f1 = !nika.f_sampling/(2.0*N_pt)
  f2 = !nika.f_sampling/2.0
  
  ;;----------- Corelated noise array A, 1/f noise
  cor_a = randomn(seed, N_pt)              
  FT_cor = FFT(cor_a)                      
  FT_cor = FT_cor * abs(k)^simpar.elec_beta 
  FT_cor[0] = 0.0                          
  cor_a = double(FFT(FT_cor,/inverse))     
  norm = stdev(cor_a)
  cor_a = cor_a * simpar.elec_amp_cor1mm / norm * sqrt(simpar.elec_Fref) * $
          sqrt(((f2/simpar.elec_Fref)^(1+2*simpar.elec_beta) - $
                (f1/simpar.elec_Fref)^(1+2*simpar.elec_beta))/(1+2*simpar.elec_beta))
  
  ;;----------- Corelated noise array B, 1/f noise
  cor_b = randomn(seed,N_pt)              
  FT_cor = FFT(cor_b)                      
  FT_cor = FT_cor * abs(k)^simpar.elec_beta 
  FT_cor[0] = 0.0                          
  cor_b = double(FFT(FT_cor,/inverse))     
  norm = stdev(cor_b)
  cor_b = cor_b * simpar.elec_amp_cor2mm / norm * sqrt(simpar.elec_Fref) * $
          sqrt(((f2/simpar.elec_Fref)^(1+2*simpar.elec_beta) - $
                (f1/simpar.elec_Fref)^(1+2*simpar.elec_beta))/(1+2*simpar.elec_beta))
  
  ;;---------- Blocks
  cor_block = randomn(seed, N_pt, 10)
  for iblock=0, 9 do begin
     FT_cor = FFT(cor_block[*,iblock])
     FT_cor = FT_cor * abs(k)^simpar.elec_beta_block
     FT_cor[0] = 0.0
     cor_block[*,iblock] = double(FFT(FT_cor,/inverse))
     norm = stdev(cor_block[*,iblock])
     cor_block[*,iblock] = cor_block[*,iblock] * simpar.elec_amp_block[iblock] / norm * sqrt(simpar.elec_Fref) * $
                           sqrt(((f2/simpar.elec_Fref)^(1+2*simpar.elec_beta_block) - $
                                 (f1/simpar.elec_Fref)^(1+2*simpar.elec_beta_block))/(1+2*simpar.elec_beta_block))
  endfor
  
  ;;----------- Loop for all KIDs
  bloc_value = long(kidpar.numdet)/long(80)
  for ikid=0, N_kid-1 do begin
     if kidpar[ikid].type eq 1 then begin
        ;; ;;----------- Converte to RFdIdQ (uncalibration)
        ;; Commented out NP, May 26th, 2015
        ;; data.toi[ikid] = data.toi[ikid] / kidpar[ikid].calib

        ;;----------- Add noise with electronic noise calib with KID on 0
        dec = randomn(seed, N_pt)
        norm = stddev(dec)
        block_toi = cor_block[*, bloc_value[ikid]]
        case kidpar[ikid].array of
           1: begin
              dec = dec *simpar.elec_amp_dec1mm / norm * sqrt(simpar.elec_Fref) * $
                    sqrt((f2/simpar.elec_Fref) - (f1/simpar.elec_Fref))
              data.toi[ikid] = data.toi[ikid] + (cor_a + dec + block_toi);; /kidpar[ikid].calib_fix_fwhm
           end
           2: begin 
              dec = dec * simpar.elec_amp_dec2mm / norm * sqrt(simpar.elec_Fref) * $
                    sqrt((f2/simpar.elec_Fref) - (f1/simpar.elec_Fref))
              data.toi[ikid] = data.toi[ikid] + (cor_b + dec+ block_toi);; /kidpar[ikid].calib_fix_fwhm
           end
        endcase
        
        ;;------------ toi always start at 0
        ;; Commented out NP, May 26th, 2015
        ;;data.toi[ikid] = data.toi[ikid] - data[0].toi[ikid]

     endif
  endfor

  return
end
