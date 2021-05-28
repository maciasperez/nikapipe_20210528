
pro nika_pipe_noisew8, param, data, kidpar

nsn = n_elements(data)
total_obs_time = nsn/!nika.f_sampling

data.w8 = 0.d0 ; init
for ikid=0, n_elements(kidpar)-1 do begin
   if kidpar[ikid].type eq 1 then begin
      ;; In theory, sigma2 = total(pw^2) * total_obs_time
      ;; here kidpar.noise is the average noise above 4hz.
      ;; if we consider it as white noise, total(pw^2) =
      ;; n_elements(pw)*kidpar.noise^2 = (nsn/2)*kidpar.noise^2
      sigma2 = (nsn/2.)*(kidpar[ikid].calib*kidpar[ikid].noise)^2 / total_obs_time ; (Jy/Hz x Hz/sqrt(Hz))^2 x time = Jy^2
      
      ;; weight by inverse variance
      data.w8[ikid] = (1.d0/sigma2) * double(data.flag[ikid] eq 0)
   endif
endfor

end
