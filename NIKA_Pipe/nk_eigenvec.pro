

pro nk_eigenvec, param, info, kidpar, toi, flag, off_source, toi_out, out_temp


case param.eigenvec_block of
   'array':   block = kidpar.array
   'box':     block = kidpar.acqbox
   'subband': block = kidpar.numdet/80
   else:begin
      message, /info, "param.eigenvec_block = "+strtrim(param.eigenvec_block,2)+" case not implemented"
      stop
   endelse
endcase

u_block  = block[UNIQ(block, SORT(block))]
nblock = n_elements(u_block)

nsn = n_elements(toi[0,*])

nmodes_max = 10

toi_out  = toi*0.d0
out_temp = toi*0.d0
for iblock=0, nblock-1 do begin
   w1 = where( kidpar.type eq 1 and block eq u_block[iblock], nw1)
;;   if nw1 ne 0 then begin
   if nw1 ge 10 then begin
      mytoi        = toi[       w1,*]
      myflag       = flag[      w1,*]
      myoff_source = off_source[w1,*]

      ;; subtract average
      toi_avg = dblarr(nw1)
      for i=0, nw1-1 do begin
         toi_avg[i]  = avg(mytoi[i,*]*myoff_source[i,*]*(myflag[i,*] eq 0))
         mytoi[i,*] -= toi_avg[i]
      endfor

      ;; compute corr matrix and eigenvalues eigenvectors
      corrmatrix  = correlate( mytoi, /double)
      ;; Could not find a smart way to use array multiplication
      ;; while normalizing to the correct number of samples
      ;; (samples in common for each pair of kids), w/o Nan...
      ;; covmatrix = transpose(mytoi*off_source[w1,*]) ##
      ;; (mytoi*off_source[w1,*])
      toi2 = mytoi
      wnan = where( myoff_source eq 0 or myflag ne 0, nwnan)
      if nwnan ne 0 then toi2[wnan] = !values.d_nan
      covmatrix = dblarr(nw1,nw1)
      for i=0, nw1-1 do begin
         for j=0, nw1-1 do begin
            covmatrix[i,j] = avg( toi2[i,*]*toi2[j,*], /NAN, /double)
         endfor
      endfor
      
      ;; Need to interpolate the flagged or masked data to derive
      ;; "modes" or we won't have the correct number of samples
      index = lindgen(nsn)
      for i=0, nw1-1 do begin
         wk = where( myoff_source[i,*] eq 1 and myflag[i,*] eq 0, nwk, compl=wflag, ncompl=nwflag)
         if nwk eq 0 then begin
            message, /info, "all samples on source or flagged for Numdet "+strtrim(kidpar[w1[i]].numdet,2)
            flag[w1[i],*] = 2L^7
         endif else begin
            if nwflag ne 0 then begin
               y = mytoi[i,*]
               y_smooth = smooth( y, long(!nika.f_sampling), /edge_mirror)
               sigma = stddev( y[wk]-y_smooth[wk])
               z = interpol( y_smooth[wk], index[wk], index)
               y[wflag] = z[wflag] + randomn( seed, nwflag)*sigma

               ;; if param.interactive and nwflag gt 2 then begin
               ;;    wind, 1, 1, /free, /large
               ;;    plot, mytoi[i,*], /xs
               ;;    oplot, wflag, mytoi[i,wflag], psym=8, syms=0.5
               ;;    oplot, y_smooth, col=200
               ;;    oplot, z, col=250
               ;;    stop
               ;; endif

               mytoi[i,*] = y
;               mytoi[i,*] = smooth(y,5,/edge_mirror)
            endif
         endelse
      endfor

      do_plot = 0
;      if !mydebug.test ne 0 and kidpar[w1[0]].array eq 1 then do_plot=1

      if do_plot eq 1 then begin
         wind, 1, 1, /free, /large, title='Block '+strtrim(u_block[iblock],2)
         xsep=0.6
         xmargin=0.01
         gap_x = 0.02
         gap_y = 0.02
         !p.charsize = 0.6
         my_multiplot, 1, 1, ntot=nw1, pp, pp1, /rev, $
                       xmin=0.02, xmax=xsep, xmargin=xmargin, $
                       gap_x=gap_x, gap_y=gap_y
         for i=0, nw1-1 do begin
            plot, mytoi[i,*], position=pp1[i,*], /noerase, $
                  title=strtrim(kidpar[w1[i]].numdet,2)
         endfor
      endif

      ;; Derive modes
      eigenvalues = EIGENQL(covMatrix, EIGENVECTORS=eigenvectors, /DOUBLE)

      nmodes_test = 10
      if do_plot eq 1 then begin
         my_multiplot, 1, 1, ntot=nmodes_test+3, pp, pp1, /rev, $
                       xmin=xsep+0.01, xmax=0.95, xmargin=xmargin
         imview, abs(corrmatrix), position=pp1[0,*], /noerase, imr=[0,1]
      endif
  ;;    for nmodes_max=1, nmodes_test do begin
         nmodes = nmodes_max < n_elements(eigenvalues)
         modes = transpose( eigenvectors[*,0:nmodes-1] ## transpose( mytoi))

         ;; Subtract modes to KIDs
         for i=0, nw1-1 do begin
            coeff = regress( modes, reform(mytoi[i,*]), /double, const=const)
            yfit = const + modes##coeff

            toi_out[w1[i],*] = mytoi[i,*] - yfit
            
            ;; Need to put back toi_avg here for the global "output
            ;; template" that will be subtracted from toi in nk_scan_reduce_1
            out_temp[w1[i],*] = yfit + toi_avg[i]
         endfor
         corrmatrix = correlate( toi_out[w1,*], /double)
         if do_plot eq 1 then begin
            imview, abs(corrmatrix), position=pp1[nmodes_max,*], /noerase, $
                    imr=[0,1], title='Nmodes '+strtrim(nmodes_max,2), /nobar
            stop
         endif
;;      endfor

;;      ;; Quick Xcheck
;;      cm = median(toi[w1,*], dim=1)
;;      toi_decor_subband = mytoi
;;      for i=0, nw1-1 do begin
;;         fit = linfit( cm, mytoi[i,*])
;;         toi_decor_subband[i,*] = mytoi[i,*] - (fit[0]+fit[1]*cm)
;;      endfor
;;      imview, abs(correlate(toi_decor_subband,/double)), /noerase, $
;;              imr=[0,1], title='one mode', /nobar, position=pp1[nmodes_max+1,*]
;;
;      print, "ARRAY: ", minmax(kidpar[w1].array)
;      stop

   endif
endfor

end

