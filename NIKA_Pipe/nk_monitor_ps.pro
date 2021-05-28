pro nk_monitor_ps, kidpar, param, data, info, $
                   monitps, step = k_step
  
; Monitor point source position and flux as a function of time
; Start from reduced data and output 4 arrays of the  (flux, x, y) and
; associated errors
  
  cho = ['1MM', '2MM', 'A1', 'A3']


  ncho = n_elements( cho)
  
  ntoi = n_elements( data.toi[0])

  quiet = 1
  maxiter = 20               ; 20 is max (CPU intensive for NIKA2 but possible)
  if keyword_set( k_step) then step = k_step else step = 1
  nout = ntoi/step
  sbeg = lindgen( nout)*step
  send = sbeg+(step-1)
  smid = sbeg+ step/2
; Output structure
  monitps = replicate( {subscan:0., scan:0., mjd:0.D0, ofs_az:0., ofs_el:0., $
                        paral:0., sample:0D0, $
                        toi:fltarr(ncho), flag:intarr(ncho)+1, $
                                ; 1 is default (bad)
                        xx: fltarr(ncho), yy:fltarr(ncho), bg:fltarr(ncho), $
                        toierr:fltarr(ncho), $
                        xxerr:fltarr(ncho), yyerr:fltarr(ncho), $
                        bgerr: fltarr(ncho)}, nout)
  monitps.subscan =  (smooth(data.subscan, step))[smid]
  monitps.scan = (smooth(data.scan, step))[smid]
  monitps.mjd = (smooth(data.mjd, step))[smid]
  monitps.ofs_az = (smooth(data.ofs_az, step))[smid]
  monitps.ofs_el = (smooth(data.ofs_el, step))[smid]
  monitps.paral = (smooth(data.paral, step))[smid]
  monitps.sample = nint((smooth(data.sample, step))[smid])
  for icho = 0, ncho-1 do begin
     xtemp = 0.
     ytemp = 0.
     gtemp = 1.
     bgtemp = 0.
     nbadfit = 0L
     case strupcase( cho[ icho]) of
        'A1': indkid = where( kidpar.array eq 1 and kidpar.type eq 1,  nbkid)
        'A2': indkid = where( kidpar.array eq 2 and kidpar.type eq 1,  nbkid)
        'A3': indkid = where( kidpar.array eq 3 and kidpar.type eq 1,  nbkid)
        '1MM': indkid = where( kidpar.lambda le 1.5 and kidpar.type eq 1,  nbkid)
        '2MM': indkid = where( kidpar.lambda gt 1.5 and kidpar.type eq 1,  nbkid)
        else: begin
           print, 'Not a good choice the channel'
           return
        end
     endcase
     fwhm = param.input_fwhm_1mm
     if strupcase( cho[ icho]) eq '2MM'then  fwhm = param.input_fwhm_2mm
     
     if nbkid lt 1 then begin
        print, 'No valid kids found for '+ cho[ icho]
        print, nbkid
        goto, NOKID
     endif
     
; Loop on images
     init=1
     for it = 0,  nout- 1 do begin
;        if it eq 918 then stop
        ib = sbeg[ it]
        ie = send[ it]
        goodim = where( data[ ib:ie].flag[ indkid] eq 0,  ngoodim)
        if ngoodim ne 0 then begin
           if init then begin
              gmax = max( (data[ ib:ie].toi[  indkid])[ goodim]) < 20.
              xmax = 0.
              ymax = 0.
              bgmax = 0.
              init= 0
           endif
           
           findgausscenter, (data[ ib:ie].toi[  indkid])[ goodim], $
                            (data[ ib:ie].flag[ indkid])[ goodim], $
; should be always 0
                            (data[ ib:ie].dra[  indkid])[ goodim], $
                            (data[ ib:ie].ddec[ indkid])[ goodim], $
                            fwhm, $
                            xmax, ymax, gmax, bgmax, $
                            xerr, yerr, gerr, bgerr, $
                            quiet = quiet, maxiter = maxiter
           
           if  gmax ne !undef then begin
              monitps[ it].flag[icho] = 0
              monitps[ it].toi[icho] = gmax
              monitps[ it].xx[icho] = xmax
              monitps[ it].yy[icho] = ymax
              monitps[ it].bg[icho] = bgmax
              monitps[ it].toierr[icho] = gerr
              monitps[ it].xxerr[icho] = xerr
              monitps[ it].yyerr[icho] = yerr
              monitps[ it].bgerr[icho] = bgerr
              xtemp= xmax
              ytemp= ymax
              gtemp= gmax
              bgtemp = bgmax
           endif else begin
              xmax= xtemp
              ymax= ytemp
              gmax= gtemp
              bgmax = bgtemp
;              init = 1          ; force reset instead of using
;              print, it, ib, ie, ' undefined focal plane data'
              nbadfit = nbadfit+1
           endelse
           
        endif                   ; end condition of valid data
        
        
     endfor
     
                                ; sample loop
     print, strtrim( nbadfit, 2)+ ' bad fit samples out of '+ $
            strtrim( nout, 2)+ ' for channel '+ cho[ icho]
     NOKID:
     
  endfor

                                ; icho loop


  return
end
