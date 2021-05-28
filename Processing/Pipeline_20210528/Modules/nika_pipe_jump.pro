;+
;PURPOSE: Correct for jumps.
;
;INPUT: param file, data file, kidpar file
;
;OUTPUT: corrected data
;
;LAST EDITION: 
;   21/09/2013: Run6 update (adam@lpsc.in2p3.fr)
;-

pro nika_pipe_jump, param, data, kidpar

  fit_length = 100
  jump_length = 50
  thresh = 4
  nfen = 100
  nperc = 10
  ndegree = 1
  

  nkid = n_elements(kidpar)
  
  bidon = ''
  for ikid = 0, nkid-1 do begin
     if kidpar[ikid].type eq 1 then begin
        data_out = remove_jump2(reform(data.RF_dIdQ[ikid]), fit_length, jump_length, thresh, nfen, nperc, ndegree)

        plot, data.RF_dIdQ[ikid]
        oplot, data_out, col=250

        data.RF_dIdQ[ikid] = data_out

        read, bidon, prompt = 'Press enter to go to the next KID and q to quit'
        if bidon eq 'q' then goto, suite
     endif
  endfor

  suite: print, ''
  return
end
