

pro nk_eigenvec_block, param, info, kidpar, toi, flag, off_source, toi_out, out_temp

nsn = n_elements(toi[0,*])

toi_out  = toi*0.d0
out_temp = toi*0.d0


;; place holders
nmodes_max     = 10
corr_threshold = 0.3

for iarray=1, 3 do begin
   w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1)
   if nw1 ge 10 then begin
      mytoi        = toi[       w1,*]
      myflag       = flag[      w1,*]
      myoff_source = off_source[w1,*]
      numdet       = kidpar[w1].numdet
      
      ;; subtract average
      toi_avg = dblarr(nw1)
      for i=0, nw1-1 do begin
         toi_avg[i]  = avg(mytoi[i,*]*myoff_source[i,*]*(myflag[i,*] eq 0))
         mytoi[i,*] -= toi_avg[i]
      endfor
      
      corrmatrix  = correlate( mytoi, /double)

      for i=0, nw1-1 do begin
         wblock = where( abs(corrmatrix[i,*]) gt corr_threshold and $
                         numdet ne numdet[i], nwblock)
         if nwblock ge 10 then begin
            toi2        = mytoi[       wblock,*]
            flag2       = myflag[      wblock,*]
            off_source2 = myoff_source[wblock,*]

            wnan = where( off_source2 eq 0 or myflag ne 0, nwnan)
            if nwnan ne 0 then toi2[wnan] = !values.d_nan
            covmatrix = dblarr(nwblock,nwblock)
            for ii=0, nwblock-1 do begin
               for jj=0, nwblock-1 do begin
                  covmatrix[ii,jj] = avg( toi2[ii,*]*toi2[jj,*], /NAN, /double)
               endfor
            endfor

            ;; Need to interpolate the flagged or masked data to derive
            ;; "modes" or we won't have the correct number of samples
            index = lindgen(nsn)
            for ii=0, nwblock-1 do begin
               wk = where( off_source2[ii,*] eq 1 and flag2[ii,*] eq 0, nwk, compl=wflag, ncompl=nwflag)
               if nwk eq 0 then begin
                  message, /info, "all samples on source or flagged for Numdet "+strtrim(kidpar[w1[i]].numdet,2)
                  flag2[ii,*] = 2L^7
               endif else begin
                  if nwflag ne 0 then begin
                     y = toi2[ii,*]
                     y_smooth = smooth( y, long(!nika.f_sampling), /edge_mirror)
                     sigma = stddev( y[wk]-y_smooth[wk])
                     z = interpol( y_smooth[wk], index[wk], index)
                     y[wflag] = z[wflag] + randomn( seed, nwflag)*sigma
                     toi2[ii,*] = y
                  endif
               endelse
            endfor
            
            ;; Derive modes
            eigenvalues = EIGENQL(covMatrix, EIGENVECTORS=eigenvectors, /DOUBLE)
            nmodes = nmodes_max < n_elements(eigenvalues)
            modes = transpose( eigenvectors[*,0:nmodes-1] ## transpose( toi2))
            
            ;; Regress on the modes
            coeff = regress( modes, reform(mytoi[i,*]), /double, const=const)
            yfit = const + modes##coeff
            toi_out[w1[i],*] = mytoi[i,*] - yfit

            ;; Need to put back toi_avg here for the global "output
            ;; template" that will be subtracted from toi in nk_scan_reduce_1
            out_temp[w1[i],*] = yfit + toi_avg[i]
         endif

      endfor
   endif
endfor

end

