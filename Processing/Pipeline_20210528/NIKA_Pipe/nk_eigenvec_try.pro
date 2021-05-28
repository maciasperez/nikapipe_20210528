

pro nk_eigenvec_try, param, info, data, input_kidpar

for iarray=1, 3 do begin

   w1 = where( input_kidpar.type eq 1 and input_kidpar.array eq iarray, nw1)
   array = input_kidpar[w1].acqbox
   box = array[UNIQ(array, SORT(array))]
   nbox = n_elements(box)
   
   nmodes_max = 10
   for ibox=0, nbox-1 do begin
      w1 = where( input_kidpar.type eq 1 and input_kidpar.acqbox eq box[ibox], nkids)
      if nkids ne 0 then begin
         toi    = data.toi[w1]
         kidpar = input_kidpar[w1]
;         flag   = data.flag[w1]
;         off_source = data.off_source[w1]

         ;; subtract average
         for ikid=0, nkids-1 do toi[ikid,*] -= avg(toi[ikid,*])
         ;; compute corr matrix and eigenvalues eigenvectors
         covmatrix  = correlate( toi, /double, /covar)
         eigenvalues = EIGENQL(covMatrix, EIGENVECTORS=eigenvectors, /DOUBLE)
         ;; Derive modes
         nmodes = nmodes_max < n_elements(eigenvalues)
         modes = transpose( eigenvectors[*,0:nmodes-1] ## transpose( toi))

         ;; Subtract modes to KIDs
         for ikid=0, nkids-1 do begin
            coeff = regress( modes, reform(toi[ikid,*]), /double, const=const)
            yfit = const + modes##coeff
;            mytoi[i,*] -= yfit
            toi[ikid,*] -= yfit
         endfor
;         corrmatrix = correlate( mytoi, /double)
;         p++
;         imview, abs(corrmatrix), position=pp1[p,*], /noerase, imr=[0,1], title='box '+strtrim(box[ibox],2)
         data.toi[w1] = toi
      endif
   endfor
endfor


end

