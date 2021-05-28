
pro optimize_nproc, njobs, ncpu_max, ncpu_opt

if n_params() lt 1 then begin
   message, /info, "calling sequence:"
   print, "optimize_nproc, njobs, ncpu_max, ncpu_opt"
   return
endif
  
t = dblarr(ncpu_max)
for i=1, ncpu_max do begin
   njobs_per_proc = long( float(njobs)/i)
   rest = njobs - njobs_per_proc*i
   t[i-1] = njobs_per_proc + rest
endfor

w = where( t eq min(t), nw)
ncpu_opt = w[0] + 1

end
