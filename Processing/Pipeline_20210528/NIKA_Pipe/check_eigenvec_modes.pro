
restore, "all_data.save"

nkids = n_elements(residual[*,0])
for ikid=0, nkids-1 do residual[ikid,*] -= avg(residual[ikid,*])

mcorr = correlate( residual)

p=0
!p.charsize=0.6
wind, 1, 1, /free, /large
my_multiplot, 1, 1, ntot=4, pp, pp1, /rev
p++
imview, mcorr, title='mcorr', position=pp1[p,*], /noerase


end

