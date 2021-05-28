
pro nika_pipe_speedflag2,  param, data, kidpar


v = sqrt( deriv(data.ofs_az)^2 + deriv(data.ofs_el)^2)*!nika.f_sampling

med  =  median( v)
w    =  where(abs(v) gt 1.5*med or abs(v) lt 0.5*med,  nflag,  comp = cflag)

;nkids =  n_elements(kidpar)
;for i=0, nkids-1 do data.flag[ikid, w] += 1
data[w].flag += 1

end
