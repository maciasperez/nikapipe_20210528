
reso = 4.d0
scan = '20160313s178'           ; beam map in best focus conditions
;scan = '20160313s176'           ; cross just before a beam map

;; Time sampling
t_shift_min = 0.d0
t_shift_max = 30.d-3
t_step      = 2.d-3
;; make_kid_zigzag_maps, scan, t_shift_min, t_shift_max, t_step, d, t_shift, $
;;                       kids_out=kids_out, input_kidpar_file=input_kidpar_file, reso = reso, el_avg=el_avg
zigzag, scan, t_shift_min, t_shift_max, t_step, d, t_shift, $
        input_kidpar_file=input_kidpar_file, reso = reso, el_avg=el_avg, /kid_maps

const = dblarr(3,2)
slope = dblarr(3,2)
t_opt = dblarr(3)
ndt = n_elements(t_shift)
dt = t_shift*1000 ; msec
for iarray=1, 3 do begin
   w  = (where( d[iarray-1,*] eq min(d[iarray-1,*])))[0]
   w1 = where( dt lt dt[w])
   w2 = where( dt gt dt[w])
      
   t_fit1 = linfit( dt[w1], d[iarray-1,w1])
   t_fit2 = linfit( dt[w2], d[iarray-1,w2])
   t_opt[iarray-1] = (t_fit1[0]-t_fit2[0])/(t_fit2[1]-t_fit1[1])
   const[iarray-1,0] = t_fit1[0]
   const[iarray-1,1] = t_fit2[0]
   slope[iarray-1,0] = t_fit1[1]
   slope[iarray-1,1] = t_fit2[1]
endfor

ct = [70,250,150]
wind, 1, 1, /free
outplot, file='zigzag_'+scan, ps=ps, png=png
plot, dt, d[0,*], /xs, psym=-8, yra=minmax(d), /ys, $
      xtitle='Optimal time shift (msec)', ytitle='Centroids distance'
for iarray=1,3 do oplot, dt, d[iarray-1,*], psym=-8, col=ct[iarray-1]
legendastro, ['A1','A2','A3'], textcol=ct, box=0, /right
for iarray=1, 3 do begin
   oplot, dt, const[iarray-1,0] + slope[iarray-1,0]*dt, col=ct[iarray-1], thick=2
   oplot, dt, const[iarray-1,1] + slope[iarray-1,1]*dt, col=ct[iarray-1], thick=2
endfor
legendastro, "Opt. dt: "+string(t_opt,format='(F5.2)')+" ms", textcol=ct, box=0
outplot, /close


end
