
pro nk_force_white_noise, param, info, data, kidpar

  w1 = where( kidpar.type eq 1, nw1)
  nsn = n_elements(data)

  x = randomn( seed, nsn*nw1) * param.force_white_noise
  for i=0, nw1-1 do begin
     ikid = w1[i]
     data.toi[ikid] = x[i*nsn:(i+1)*nsn-1]
  endfor

  end

  
