;+
;PURPOSE: The electronic and white noise are added to the TOI here
;INPUT: Jansky data with source and atmosphere.
;OUTPUT: RFdIdQ with electronic and white noise.
;LAST EDITION: 04/02/2012
;LAST EDITOR: Remi ADAM (adam@lpsc.in2p3.fr)
;-

pro partial_simu_elec, param, data, kidpar
  
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
  FT_cor = FT_cor * abs(k)^param.elec.beta 
  FT_cor[0] = 0.0                          
  cor_a = double(FFT(FT_cor,/inverse))     
  norm = stdev(cor_a)
  cor_a = cor_a * param.elec.amp_cor[0] / norm * sqrt(param.elec.f_ref) * $
          sqrt(((f2/param.elec.f_ref)^(1+2*param.elec.beta) - $
                (f1/param.elec.f_ref)^(1+2*param.elec.beta))/(1+2*param.elec.beta))
  
  ;;----------- Corelated noise array B, 1/f noise
  cor_b = randomn(seed,N_pt)              
  FT_cor = FFT(cor_b)                      
  FT_cor = FT_cor * abs(k)^param.elec.beta 
  FT_cor[0] = 0.0                          
  cor_b = double(FFT(FT_cor,/inverse))     
  norm = stdev(cor_b)
  cor_b = cor_b * param.elec.amp_cor[1] / norm * sqrt(param.elec.f_ref) * $
          sqrt(((f2/param.elec.f_ref)^(1+2*param.elec.beta) - $
                (f1/param.elec.f_ref)^(1+2*param.elec.beta))/(1+2*param.elec.beta))
  
  ;;---------- Blocks
  cor_block = randomn(seed, N_pt, 10)
  for iblock=0, 9 do begin
     FT_cor = FFT(cor_block[*,iblock])
     FT_cor = FT_cor * abs(k)^param.elec.beta_block
     FT_cor[0] = 0.0
     cor_block[*,iblock] = double(FFT(FT_cor,/inverse))
     norm = stdev(cor_block[*,iblock])
     cor_block[*,iblock] = cor_block[*,iblock] * param.elec.amp_block[iblock] / norm * sqrt(param.elec.f_ref) * $
                           sqrt(((f2/param.elec.f_ref)^(1+2*param.elec.beta_block) - $
                                 (f1/param.elec.f_ref)^(1+2*param.elec.beta_block))/(1+2*param.elec.beta_block))
  endfor
  
  ;;----------- Loop for all KIDs
  bloc_value = long(kidpar.numdet)/long(80)
  for ikid=0, N_kid-1 do begin
     if kidpar[ikid].type eq 1 then begin
        ;;----------- Converte to RFdIdQ (uncalibration)
        data.RF_dIdQ[ikid] = data.RF_dIdQ[ikid] / kidpar[ikid].calib

        ;;----------- Add noise with electronic noise calib with KID on 0
        dec = randomn(seed, N_pt)
        norm = stddev(dec)
        block_toi = cor_block[*, bloc_value[ikid]]
        case kidpar[ikid].array of
           1: begin
              dec = dec * param.elec.amp_dec[0] / norm * sqrt(param.elec.f_ref) * $
                    sqrt((f2/param.elec.f_ref) - (f1/param.elec.f_ref))
              data.RF_dIdQ[ikid] = data.RF_dIdQ[ikid] + (cor_a + dec + block_toi)/kidpar[ikid].calib
           end
           2: begin 
              dec = dec * param.elec.amp_dec[1] / norm * sqrt(param.elec.f_ref) * $
                    sqrt((f2/param.elec.f_ref) - (f1/param.elec.f_ref))
              data.RF_dIdQ[ikid] = data.RF_dIdQ[ikid] + (cor_b + dec+ block_toi)/kidpar[ikid].calib
           end
        endcase
        
        ;;------------ RFdIdQ always start at 0
        data.RF_dIdQ[ikid] = data.RF_dIdQ[ikid] - data[0].RF_dIdQ[ikid]

     endif
  endfor

  return
end
