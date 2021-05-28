function nk_freq_cider_str, data, kidpar, ndeg, freqnorm, indexfit, $
                            xcirc, ycirc, radcirc, verbose = verbose, $
                            xoff = xoff, cfraw = cfraw, $
                            k_deglitch = k_deglitch, $
                            cwidth = k_cwidth, noflag = noflag

; same as freq_cider but with an input structure
; Fit a circle + polynomial to the frequency for indexfit values
; apply the fit to the whole array
; freqnorm is a vector of 3 values (Number of arrays)
; Do only kids not Off reso
; nk_ version is very similar to nika_ version, just an adaptation
; 1-Nov-2017 FXD Deglitch as part of the process.
; 3-Jan-2018 FXD include weighing in the circle fit before deglitching
; Aug-2019 FXD add the x excursion in the output (to detect RTS later)
; verbose=2 to have details
; k_deglitch= 0  ; 0: no deglitching of points deviant from the circle
; otherwise flag points away by k_deglitch*sigma, a value of 5 is a
; strong deglitching, 10-20 is milder.
; Whenever 10 percent or more samples are flagged, the kid is put at
; type 3
; FXD June 2020, add cwidth as an output (on the circle, it is defined
; as the frequency interval between a phase of -pi/2 and +pi/2 on the
; canonical circle)

  nel = n_elements( data)
  ndet= n_elements( data[0].i)
  freq= dblarr( ndet, nel)
  xoff = freq
  cfraw = freq
  xcirc = dblarr( ndet)
  ycirc = xcirc
  radcirc = xcirc
  cwi = xcirc  ; width
  nouseful = 0
  if keyword_set( k_deglitch) then thresh = k_deglitch else thresh = 1D9
  angle = nk_angleiq_didq( data)
  for ik= 0, ndet-1 do begin 
     if kidpar[ ik].type eq 1 then begin ; true kid
        IDa =  reform( data.i[ik])
        QDa =  reform( data.q[ik])
        dIDa = reform( data.di[ik])
        dQDa = reform( data.dq[ik])
        fruse = freqnorm[ kidpar[ ik].array - 1]     
        xc = 0.
        yc = 0.
        radius = 0.
        wei = IDa*0.+1
        bad = where( IDa eq 0. or QDa eq 0. or dIDa eq 0. or dQDa eq 0., nbad)
        if nbad ne 0 then wei[ bad] = 0.
; Gain some time with this test
        IF median( dIDa[ indexfit]) NE 0 OR $
           median( dQDa[ indexfit]) NE 0 THEN BEGIN 
           nindexfit = n_elements( indexfit)
           status = 1
           fit_cider, IDa[ indexfit], QDa[ indexfit], $
                      dIDa[ indexfit], dQDa[ indexfit], ndeg+1, $
                      weight = wei[ indexfit], $
                      coeff, corot, sirot, xc, yc, radius, status = status
; Set the zero frequency in the same way as df_tone (angle=0)
; This is not true anymore, the circle method finds its own zero
;;;           aux = min( abs(angle[ ik, *]), imin)
;;;           coeff[0] = -freq_cider(IDa[ imin], QDa[ imin], $
;;;                                  coeff, corot, sirot, xc, yc, radius)

;Here frequency norm is around 1kHz
           foundcf = -fruse * freq_cider(IDa, QDa, $
                                         coeff, corot, sirot, $
                                         xc, yc, radius, yraw = yraw, xerr)
           ;; disp = stddev( xerr[ indexfit])
           ;; histo_make, $
           ;;    xerr[ indexfit], min = -10*disp, max = +10*disp, $
           ;;    /gauss, n_bin = 301, xarr, yarr, $
           ;;    stat_res, gauss_res ;, /plot
           ;; indexfit2 = where( abs(xerr) lt 5*gauss_res[1], ndg)
           ;; if nindexfit-ndg ne 0 then $
           ;;    print, 'index= '+strtrim( ik, 2)+ $
           ;;             '; Kid numdet= '+ strtrim(kidpar[ ik].numdet, 2),  $
           ;;    ndg,  nindexfit-ndg, gauss_res[1]
           ;; if  (nindexfit-ndg) ge 1 then $
           ;;    print, ' 1st iteration, Toi not clean yet' else $
           ;;       print, '1st iteration, Toi is clean'

; 2nd iteration, weigh the circle
; Reweigh the circle fit with foundcf (Must be done before any sigma clipping)
           nbins = 101
           hh = histogram( foundcf[ indexfit], nbins = nbins, $
                           reverse_ind = revind, /nan)
           ww = foundcf[ indexfit]*0.D0
           for ib = 0, nbins-1 do $
              if revind[ib+1] ne revind[ib] then $
                 ww[ revind[ revind[ib]:(revind[ib+1]-1)]] = 1.D0/hh[ib] 

           status = 1
           fit_cider, IDa[ indexfit], QDa[ indexfit], $
                      dIDa[ indexfit], dQDa[ indexfit], ndeg+1, $
                      coeff, corot, sirot, xc, yc, radius, status = status, $
                      weigh = ww*wei[ indexfit]
; Set the zero frequency in the same way as df_tone (angle=0)
; This is not true anymore, the circle method finds its own zero
;;;           aux = min( abs(angle[ ik, *]), imin)
;;;           coeff[0] = -freq_cider(IDa[ imin], QDa[ imin], $
;;;                                  coeff, corot, sirot, xc, yc, radius)
           foundcf = -fruse * freq_cider(IDa, QDa, $
                                         coeff, corot, sirot, xc, yc, radius, $
                                         yraw = yraw, xerr)
           disp = stddev( xerr[ indexfit])
           histo_make, $
              xerr[ indexfit], min = -10*disp, max = +10*disp, $
              /gauss, n_bin = 301, xarr, yarr, $
              stat_res, gauss_res ;, /plot
           idg = where( abs(xerr[ indexfit]) lt 5*gauss_res[1], ndg)
           indexfit2 = indexfit[ idg]
;           print, ndg,  nindexfit-ndg, gauss_res[1]
           if  (nindexfit-ndg) ge 1 and ndg gt 9 then begin
              ;print, '2nd iteration done, but rerun because of glitches'
              hh = histogram( foundcf[ indexfit2], nbins = nbins, $
                              reverse_ind = revind, /nan)
              ww = foundcf[ indexfit2]*0.D0
              for ib = 0, nbins-1 do $
                 if revind[ib+1] ne revind[ib] then $
                    ww[ revind[ revind[ib]:(revind[ib+1]-1)]] = 1.D0/hh[ib] 

; 3rd iteration, weigh the circle after having removed glitches
              status = 1
              fit_cider, IDa[ indexfit2], QDa[ indexfit2], $
                         dIDa[ indexfit2], dQDa[ indexfit2], ndeg+1, $
                         coeff, corot, sirot, xc, yc, radius, status = status, $
                         weigh = ww*wei[ indexfit2]
; Set the zero frequency in the same way as df_tone (angle=0)
; This is not true anymore, the circle method finds its own zero
;;;              aux = min( abs(angle[ ik, *]), imin)
;;;              coeff[0] = -freq_cider(IDa[ imin], QDa[ imin], $
;;;                                     coeff, corot, sirot, xc, yc,
;;;                                     radius)
                                ; FXD Sept 2019: coef[0] is fixed at 0
                                ; (i.e. the center of the resonance)
                                ; see fit_cider, so we depart from the
                                ; previous Pf convention.
              foundcf = -fruse * freq_cider(IDa, QDa, $
                                            coeff, corot, sirot, $
                                            xc, yc, radius, xerr, yraw = yraw)
              disp = stddev( xerr[ indexfit2])
              histo_make, $
                 xerr[ indexfit2], min = -10*disp, max = +10*disp, $
                 /gauss, n_bin = 301, xarr, yarr, $
                 stat_res, gauss_res ;, /plot
              idg = where( abs(xerr[ indexfit2]) lt 5*gauss_res[1], ndg)
              ;indexfit3 = indexfit2[ idg] ; useless
              ;; if keyword_set( verbose) and (nindexfit-ndg) ge 5 then $
              ;;    print, 'index= '+strtrim( ik, 2)+ $
              ;;           '; Kid numdet= '+ strtrim(kidpar[ ik].numdet, 2), $
              ;;           ndg,  nindexfit-ndg, gauss_res[1]
           endif ;else print, '2nd iteration done, Toi is clean'


; test if bad fit is found
           bad = where( 1-finite( foundcf[ indexfit]) or $
                        abs(xerr[ indexfit]) ge thresh*gauss_res[1], nbad)
           bb =  where( 1-finite( foundcf[ indexfit]) or $
                        abs(xerr[ indexfit]) ge 5.*gauss_res[1], nbb)
           if nbad ne 0 and keyword_set( k_deglitch) then $
                 foundcf[ indexfit[bad]] = !values.d_nan ; preferable for NIKA2 
;;;           if ik eq 1491 then stop
           if nbb gt 0.1*nindexfit then begin ; too many bad values (in the 5 sigma sense)
              foundcf[ indexfit] = !values.d_nan ; Reject that kid
                                ;completely
              kidpar[ ik].type = 3
              nouseful = nouseful + 1
           endif
           freq[ ik, *] = foundcf
;if ik eq 587 then stop 
           xoff[ ik, *] = xerr
           cfraw[ ik, *] = yraw
           xcirc[ ik] = xc
           ycirc[ ik] = yc
           radcirc[ ik] = radius
           cwi[ ik] = -2. * fruse * coeff[ 1]  ; sign is empirical
           ;; cwi[ ik] = 2. * fruse * $
           ;;            total( coeff[ indgen((ndeg+1)/2)*2+1])
; coeff[1]+coeff[3]...
; This formula can be obtained by taking the -pi/2 and pi/2 points, in
; terms of frequency,
                                ; this does not work if the circle
                                ; phases are not covered properly (the
                                ; non linear parts covered by coeff
                                ; are somewhat uncertain and the sum
                                ; can diverge).
                                ; we decide to take the robust linear
                                ; evaluation which is the dominant term
           
           if keyword_set( verbose) and nbb ge 3*alog10(nindexfit)  then $
              if verbose ge 2 then message, /info, 'index= '+strtrim( ik, 2)+ $
                       '; Kid numdet= '+ strtrim(kidpar[ ik].numdet, 2)+ $
                       ' has '+ strtrim( nbb)+' (k_deglitch sigma) glitches'
; several glitches can happen, they are false positives
           if keyword_set( verbose) and nbb gt 0.1*nindexfit then $
              if verbose ge 2 then message, /info, '      and is not used'
       ENDIF  else nouseful = nouseful + 1  ; Kid where all dI, dQ data are zero
     endif ; Do not count the kids already excluded else nouseful = nouseful + 1
  endfor   

;  stop
; Last sample is sometimes strange (unknown reason), flag it!
  freq[*, nel-1] = !values.d_nan
; Change value of flag for glitched samples
  badall = where( finite( freq) eq 0, nbadall)
  if nbadall ne 0 and not keyword_set( noflag) then begin
     nk_add_flag, data, 0, w2d_k_s=badall
     freq[ badall] = 0.         ; to avoid  adding nan
  endif
  freq[*, nel-1] = freq[*, nel-2] ; to make it smooth (no impact on pipeline as it is flagged)
  k_cwidth = cwi
  if nouseful eq ndet then $
     message, /info, 'No useful I,Q data' ; end case when calculation is useful
  if keyword_set( verbose) then message, /info, strtrim(nouseful, 2)+' useless kids'
  return, freq
end
