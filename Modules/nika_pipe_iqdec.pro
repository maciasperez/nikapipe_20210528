pro nika_pipe_iqdec, param, subscan, df, kidpar, I_in, Q_in, dI_in, dQ_in, RFdIdQ_dec
  
  ;;--------------- First rotate and normalise all the resonances to the same location in IQ plane
  nika_pipe_iqrot, I_in, Q_in, dI_in, dQ_in, I_rot, Q_rot, dI_rot, dQ_rot
  
  ;;############################## DECORRELATION #####################################
  N_pt = n_elements(I_in[0,*])           ;Nombre de sampling
  w_on = where(kidpar.type eq 1, n_on)   ;Number of detector ON
  w_off = where(kidpar.type eq 2, n_off) ;Number of detector OFF
  n_kid = n_elements(I_in[*,0])          ;Number of detector in the array
  
  I_dec = dblarr(n_kid,N_pt)    ;TOI after decorrelation
  Q_dec = dblarr(n_kid,N_pt)
  dI_dec = dblarr(n_kid,N_pt)
  dQ_dec = dblarr(n_kid,N_pt)
  
  ;;############################## Case of all the scan at once
  if param.decor.IQ_plane.per_subscan eq 'no' then begin
     
     templates_I = dblarr(n_off, N_pt)   ;I have to do this otherwise
     templates_Q = dblarr(n_off, N_pt)   ;REGRESS gets angry
     templates_dI = dblarr(n_off, N_pt)  ;
     templates_dQ = dblarr(n_off, N_pt)  ;
     templates_I[*,*] = I_rot[w_off,*]   ;The template is all OFF res tones
     templates_Q[*,*] = Q_rot[w_off,*]   ;
     templates_dI[*,*] = dI_rot[w_off,*] ;
     templates_dQ[*,*] = dQ_rot[w_off,*] ;
     
     ;;Build a single common mode
     if param.decor.IQ_plane.one_mode eq 'yes' then begin
        templates_I = sum(templates_I, 0)/n_off
        templates_Q = sum(templates_Q, 0)/n_off
        templates_dI = sum(templates_dI, 0)/n_off
        templates_dQ = sum(templates_dQ, 0)/n_off
     endif
     
     for ikid=0, n_kid-1 do begin 
        y_I = reform(I_rot[ikid,*])
        y_Q = reform(Q_rot[ikid,*])
        y_dI = reform(dI_rot[ikid,*])
        y_dQ = reform(dQ_rot[ikid,*])
        
        coeff_I = regress(templates_I, y_I,  CHISQ= chi, CONST= const_I, CORRELATION= corr, $
                          /DOUBLE, FTEST=ftest, MCORRELATION=mcorr, SIGMA=sigma, STATUS=status, YFIT=yfit_I)
        coeff_Q = regress(templates_Q, y_Q,  CHISQ= chi, CONST= const_Q, CORRELATION= corr, $
                          /DOUBLE, FTEST=ftest, MCORRELATION=mcorr, SIGMA=sigma, STATUS=status, YFIT=yfit_Q)
        coeff_dI = regress(templates_dI, y_dI,  CHISQ= chi, CONST= const_dI, CORRELATION= corr, $
                           /DOUBLE, FTEST=ftest, MCORRELATION=mcorr, SIGMA=sigma, STATUS=status, YFIT=yfit_dI)
        coeff_dQ = regress(templates_dQ, y_dQ,  CHISQ= chi, CONST= const_dQ, CORRELATION= corr, $
                           /DOUBLE, FTEST=ftest, MCORRELATION=mcorr, SIGMA=sigma, STATUS=status, YFIT=yfit_dQ)
        
        I_dec[ikid,*] = I_rot[ikid,*] - yfit_I + mean(I_rot[ikid,*])
        Q_dec[ikid,*] = Q_rot[ikid,*] - yfit_Q + mean(Q_rot[ikid,*])
        dI_dec[ikid,*] = dI_rot[ikid,*] - yfit_dI + mean(dI_rot[ikid,*])
        dQ_dec[ikid,*] = dQ_rot[ikid,*] - yfit_dQ + mean(dQ_rot[ikid,*])
     endfor
  endif

  ;;############################## Case per subscan
  if param.decor.IQ_plane.per_subscan eq 'yes' then begin
     for isubscan=(min(subscan)>0), max(subscan) do begin
        wsubscan = where(subscan eq isubscan, nwsubscan)
        if nwsubscan ne 0 then begin
           templates_I = dblarr(n_off, nwsubscan)            ;I have to do this otherwise
           templates_Q = dblarr(n_off, nwsubscan)            ;REGRESS gets angry
           templates_dI = dblarr(n_off, nwsubscan)           ;
           templates_dQ = dblarr(n_off, nwsubscan)           ;
           templates_I[*,*] = (I_rot[w_off,*])[*,wsubscan]   ;The template is all OFF res tones
           templates_Q[*,*] = (Q_rot[w_off,*])[*,wsubscan]   ;The template is all OFF res tones
           templates_dI[*,*] = (dI_rot[w_off,*])[*,wsubscan] ;The template is all OFF res tones
           templates_dQ[*,*] = (dQ_rot[w_off,*])[*,wsubscan] ;The template is all OFF res tones
                
           ;;Build a single common mode
           if param.decor.IQ_plane.one_mode eq 'yes' then begin
              templates_I = sum(templates_I, 0)/n_off
              templates_Q = sum(templates_Q, 0)/n_off
              templates_dI = sum(templates_dI, 0)/n_off
              templates_dQ = sum(templates_dQ, 0)/n_off
           endif

           for ikid=0, n_kid-1 do begin 
              y_I = reform(I_rot[ikid,wsubscan])
              y_Q = reform(Q_rot[ikid,wsubscan])
              y_dI = reform(dI_rot[ikid,wsubscan])
              y_dQ = reform(dQ_rot[ikid,wsubscan])

              coeff_I = regress(templates_I, y_I,  CHISQ= chi, CONST= const_I, CORRELATION= corr, $
                                /DOUBLE, FTEST=ftest, MCORRELATION=mcorr, SIGMA=sigma, STATUS=status, YFIT=yfit_I)
              coeff_Q = regress(templates_Q, y_Q,  CHISQ= chi, CONST= const_Q, CORRELATION= corr, $
                                /DOUBLE, FTEST=ftest, MCORRELATION=mcorr, SIGMA=sigma, STATUS=status, YFIT=yfit_Q)
              coeff_dI = regress(templates_dI, y_dI,  CHISQ= chi, CONST= const_dI, CORRELATION= corr, $
                                 /DOUBLE, FTEST=ftest,MCORRELATION=mcorr,SIGMA=sigma,STATUS=status, YFIT=yfit_dI)
              coeff_dQ = regress(templates_dQ, y_dQ,  CHISQ=chi, CONST=const_dQ, CORRELATION= corr, $
                                 /DOUBLE, FTEST=ftest,MCORRELATION=mcorr,SIGMA=sigma,STATUS=status, YFIT=yfit_dQ)
              
              I_dec[ikid,wsubscan] = I_rot[ikid,wsubscan] - reform(yfit_I) + mean(I_rot[ikid,wsubscan])
              Q_dec[ikid,wsubscan] = Q_rot[ikid,wsubscan] - reform(yfit_Q) + mean(Q_rot[ikid,wsubscan])
              dI_dec[ikid,wsubscan] = dI_rot[ikid,wsubscan] - reform(yfit_dI) + mean(dI_rot[ikid,wsubscan])
              dQ_dec[ikid,wsubscan] = dQ_rot[ikid,wsubscan] - reform(yfit_dQ) + mean(dQ_rot[ikid,wsubscan])
           endfor
           
        endif
     endfor
  endif
  
   ;;############################## Case the parameter is not right
   if param.decor.IQ_plane.per_subscan ne 'yes' $
      and param.decor.IQ_plane.per_subscan ne 'no' then begin
      message,/info,"You need to tell me if you want to decorrelate per subscan or all the timeline at once"
      message,/info,"For this, set param.decor.IQ_plane.per_subscan to 'yes' or 'no'"
      message,"Here param.decor.IQ_plane.per_subscan = '"+strtrim(param.decor.IQ_dec.per_subscan,2)+"'"
   endif


  ;;--------------- Compute the new RFdIdQ, electronic noise free (hopefully)
  nika_pipe_iq2rfdidq, df, I_dec, Q_dec, dI_dec, dQ_dec, RFdIdQ_dec, shift_nb=49

  return
end
