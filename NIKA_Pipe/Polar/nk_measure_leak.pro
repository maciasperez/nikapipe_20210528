; written from FXD/SCR/N2Rall/Polar/measure_leakage.pro
; Comments to come, nsubm= size of sub map where the coefficients are computed.
pro nk_measure_leak, grid, nsubm, j1, j2, leakcoeff, verbose = verb

  tagn = tag_names( grid)
  maptag = where( tagn eq 'MAP_I1' or tagn eq 'MAP_I2' or tagn eq 'MAP_I3' or $
                  tagn eq 'MAP_I_1MM' or tagn eq 'MAP_I_2MM', nmaptag)
  maptag = maptag[ sort( tagn[maptag])] ; make sure of the order I1, I2, I3
  if nmaptag ne 5 then message, 'Grid is incorrect for I'

  qutag = [where( tagn eq 'MAP_Q1'), $
           where( tagn eq 'MAP_U1'), $
           where( tagn eq 'MAP_Q2'), $
           where( tagn eq 'MAP_U2'), $
           where( tagn eq 'MAP_Q3'), $
           where( tagn eq 'MAP_U3'), $
           where( tagn eq 'MAP_Q_1MM'), $
           where( tagn eq 'MAP_U_1MM'), $
           where( tagn eq 'MAP_Q_2MM'), $
           where( tagn eq 'MAP_U_2MM')]
  nqutag = n_elements( qutag)
  if nqutag ne 10 then message, 'Grid is incorrect for Q,U'
  leakcoeff = replicate( {coeff : fltarr(2, 6), $ ; 6 coefficients
                          coeffun : fltarr(2, 6), $ ; uncertainty
                          xmean: fltarr(2), $       ; for Q and U leakage
                          ymean: fltarr(2), $
                          xnas:fltarr(2, 2), $ ; two polars x positions per Q, 2 per U
                          ynas:fltarr(2, 2)}, nmaptag)

  nmap = n_elements(grid.(maptag[0])[*, 0])
  index = lindgen( nmap, nmap)
  j1 = nmap/2- nsubm/2
  j2 = nmap/2+ nsubm/2
  subind = index[j1:j2, j1:j2]
  nsub = n_elements( subind)
  reso = grid.map_reso

  nk_grid2grad, grid, grad, /norm
  indmapuse = indgen( nmaptag)  ;[0, 2]            ; A1, A3
  nuse = n_elements( indmapuse)
  for narr = 0, nuse-1 do begin ; A1 and A3 or all
     indmap = indmapuse[ narr]

     index = lindgen( nmap, nmap)
     subind = index[j1:j2, j1:j2]
     nsub = n_elements( subind)

; regress with 2nd derivatives too
; Try a regress Q= c0 B+ c1 MX + c2 MY + c3 MXX + c4 MXY + c5 MYY
     xx = dblarr( 6, nsub)
     xx[0, *] = reform( grad[ indmap].mapi[j1:j2, j1:j2], nsub)
;imview, 1./((mapi[j1:j2, j1:j2] ge 0.02)>1D-4)
     xx[1, *] = reform( grad[ indmap].mapx[j1:j2, j1:j2], nsub)
     xx[2, *] = reform( grad[ indmap].mapy[j1:j2, j1:j2], nsub)
     xx[3, *] = reform( grad[ indmap].mapxx[j1:j2, j1:j2], nsub)
     xx[4, *] = reform( grad[ indmap].mapxy[j1:j2, j1:j2], nsub)
     xx[5, *] = reform( grad[ indmap].mapyy[j1:j2, j1:j2], nsub)
     maxmap = max( grid.(maptag[ narr]))
     for iqu = 0, 1 do begin    ; loop on Q and U leakage
        yy = dblarr( nsub)
        yy[*] = reform( grid.(qutag[iqu+narr*2])[j1:j2, j1:j2]/maxmap, nsub)
        result = REGRESS(xx, yy, SIGMA=sigma, CONST=cc, yfit = yyfit)
        leakcoeff[narr].coeff[iqu, *]= result
        leakcoeff[narr].coeffun[iqu, *]= sigma
        mapfit = reform( yyfit, nsubm, nsubm)
        if keyword_set( verb) then begin 
           print, '--------------------------------------------------'
           print, tagn[ maptag[narr]], ' ', tagn[ qutag[ iqu+narr*2]]
           print, 'Coeff, Uncertainties, Constant'
           print, reform(result), sigma, cc, format = '(6F9.5)'
           print, 'min, max, stddev, Before After'
           print, [minmax(yy), stddev( yy)], format = '(3F9.5)'
           print, [minmax( yy-yyfit), stddev( yy-yyfit)], format = '(3F9.5)'
        endif
        
        leakcoeff[narr].xmean[iqu] = leakcoeff[narr].coeff[iqu, 3]/ $
                                     leakcoeff[narr].coeff[iqu, 1]
        leakcoeff[narr].ymean[iqu] = leakcoeff[narr].coeff[iqu, 5]/ $
                                     leakcoeff[narr].coeff[iqu, 2]
        leakcoeff[narr].xnas[iqu, 0] = leakcoeff[narr].xmean[iqu]- $
                                       leakcoeff[narr].coeff[iqu, 1]/2.
        leakcoeff[narr].xnas[iqu, 1] = leakcoeff[narr].xmean[iqu]+ $
                                       leakcoeff[narr].coeff[iqu, 1]/2.
        leakcoeff[narr].ynas[iqu, 0] = leakcoeff[narr].ymean[iqu]- $
                                       leakcoeff[narr].coeff[iqu, 2]/2.
        leakcoeff[narr].ynas[iqu, 1] = leakcoeff[narr].ymean[iqu]+ $
                                       leakcoeff[narr].coeff[iqu, 2]/2.
        if keyword_set( verb) then begin 
           print, 'xmean, ymean, consistency '
           print, leakcoeff[narr].xmean[iqu], leakcoeff[narr].ymean[iqu], format = '(2F9.5)'
           print, leakcoeff[narr].xnas[ iqu, 1]*leakcoeff[narr].coeff[iqu, 2] + $
                  leakcoeff[narr].ynas[iqu, 0]*leakcoeff[narr].coeff[iqu, 1], $
                  leakcoeff[narr].coeff[iqu, 4], format = '(2F9.5)'
        endif
     endfor

  endfor                        ; end loop on array

  return
end
