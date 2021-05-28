;+
;PURPOSE: Flag the bad parts of lissajous scans
;
;INPUT: The parameter, data and kidpar structures
;
;OUTPUT: The flagged data structure.
;
;LAST EDITION: ../01/2014: creation (nicolas.ponthieu@obs.ujf-grenoble.fr>).
;                          Sets projection w8's to 0 where the
;                          scan is not in its standard mode.
;              12/02/2014: flag set in data.flag instead of data.w8
;                          and add keyword silent. Change the way of falgging
;-

pro nika_pipe_lissajou_select, param, data, kidpar, $
                               good = good, silent=silent, pazel = pazel

  nsn = n_elements(data)
  index = lindgen(nsn)
  i_up = nsn  ; default
  i_down = -1 ; everything is masked
  
  ;;------- Fit lissajou coordinates around the center of the scan
  i2 = long(nsn*4./5)
  i1 = i2 - nsn/2
  flag = data.ofs_az*0.d0 + 1.d0
  if keyword_set( good) then flag[ good] = 0 else flag[i1:i2] = 0.d0

; Due to pointing problems (missing data), use only non-zero values
  bad = where( data.ofs_az eq 0, nbad)
  pazel = [0D0, 0]
  if nbad ne 0 then flag[ bad] = 1
  nika_fit_sine, index, data.ofs_az, flag, params_az, fit_az, status=status
  if status lt 0 then goto, the_end
  nika_fit_sine, index, data.ofs_el, flag, params_el, fit_el, status=status
  if status lt 0 then goto, the_end
  pazel[*] = [params_az[0], params_el[0]]  ; store for later used

  ;;------- Flag out sections of the scan too far from the fit
  ;;delta_az = data.ofs_az - fit_az
  ;;delta_el = data.ofs_el - fit_el
  ;;rms_az = stddev( delta_az[i1:i2])
  ;;rms_el = stddev( delta_el[i1:i2])
  
  ;;w = where( abs( delta_az) lt 5*rms_az and $
  ;;           abs( delta_el) lt 5*rms_el, nw, compl=wout, ncompl=nwout)
  

;;  message, /info, strtrim(nwout,2)+" samples are out of the regular lissajou pattern and " + $
;;           "flagged to zero for projection"
;;  if nw eq 0 then begin
;;     message, /info, ""
;;     message, /info, "No valid samples (perhaps not a Lissajous scan) ?!"
;;     stop
;;  end
;; if nwout ne 0 then nika_pipe_addflag, data, 8, wsample=wout

  
  ;;------- Flag based on location in the scan
  az_rng = minmax(fit_az)
  el_rng = minmax(fit_el)
  
  scan_valid = data.scan*0
  nsv = n_elements(data[0].scan_valid)
  scan_valid = scan_valid or data.scan_valid[0]
  scan_valid = scan_valid or data.scan_valid[1]

  val_part = where(scan_valid eq 0, nval_part)
  
  if nval_part ne 0 then begin  ;Flag the in a standard way
     i_up = 0
     while ((scan_valid[i_up] ne 0) or $
            (data[i_up].ofs_az lt 2*az_rng[0]/3) or $
            (data[i_up].ofs_az gt 2*az_rng[1]/3) or $
            (data[i_up].ofs_el lt 2*el_rng[0]/3) or $
            (data[i_up].ofs_el gt 2*el_rng[1]/3)) do i_up += 1
     
     i_down = nsn-1
     while ((scan_valid[i_down] ne 0) or $
        (data[i_down].ofs_az lt 2*az_rng[0]/3) or $
        (data[i_down].ofs_az gt 2*az_rng[1]/3) or $
        (data[i_down].ofs_el lt 2*el_rng[0]/3) or $
        (data[i_down].ofs_el gt 2*el_rng[1]/3)) do i_down -= 1

  endif else begin              ;Flag without using scan valid but large loss of (probably) valid data
;     message, /info, '---------------------------------'
;     message, /info, '------- IMPORTANT WARNING -------'
;     message, /info, '---------------------------------'
     message, /info, '------- The declared valid part of the scan is empty.'
;     message, /info, '------- The flag to be applied is found by hand.'
;     message, /info, '---------------------------------'

     nika_pipe_cutscan, param, data, loc_ok, loc_bad=loc_bad

     if loc_ok[0] eq (-1) then begin
        i_up = nsn
        i_down = -1
     endif else begin
        i_up = 0
        condi = 0
        while condi eq 0 do begin
           wi_up = where(loc_ok eq i_up, nwi_up)
           if ((nwi_up eq 1) and $
               (data[i_up].ofs_az gt 2*az_rng[0]/3) and $
               (data[i_up].ofs_az lt 2*az_rng[1]/3) and $
               (data[i_up].ofs_el gt 2*el_rng[0]/3) and $
               (data[i_up].ofs_el lt 2*el_rng[1]/3)) then condi = 1
           i_up += 1
        endwhile
        
        i_down = nsn-1
        condi = 0
        while condi eq 0 do begin
           wi_down = where(loc_ok eq i_down, nwi_down)
           if ((nwi_down eq 1) and $
               (data[i_down].ofs_az gt 2*az_rng[0]/3) and $
               (data[i_down].ofs_az lt 2*az_rng[1]/3) and $
               (data[i_down].ofs_el gt 2*el_rng[0]/3) and $
               (data[i_down].ofs_el lt 2*el_rng[1]/3)) then condi = 1
           i_down -= 1
        endwhile
     endelse

  endelse

the_end:  
w = where(index gt i_up and index lt i_down, nw, compl=wout, ncompl=nwout)
if nwout ne 0 then nika_pipe_addflag, data, 8, wsample=wout
  
end
