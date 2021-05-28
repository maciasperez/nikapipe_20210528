
;; Quick and dirty baseline from first last sample

function qd_baseline, d

n = n_elements(d)
b = (d[n-1]-d[0])/double(n-1)*dindgen(n) + d[0]

return, b

end

