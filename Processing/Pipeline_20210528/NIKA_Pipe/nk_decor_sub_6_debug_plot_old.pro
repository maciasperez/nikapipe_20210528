

n_templates = n_elements(templates[*,0])
make_ct, n_templates, ct
w1 = where( kidpar.type eq 1 and kidpar.array eq 1, nw1)
ikid = w1[0]
wind, 1, 1, /free, /large
ysep = 0.4
xsep = 0.5
xmargin = 0.01
my_multiplot, 1, 2, pp, pp1, ymin=ysep, ntot=n_templates, /rev, /full, /dry, ymax=0.97
for i=0, n_templates-1 do begin &$
   plot, out_coeffs[ikid,i]*templates[i,*], /xs, /ys, /noerase, position=pp1[i,*], $
         charsize = 1d-10 &$
   legendastro, [strtrim(i,2), strtrim(out_coeffs[ikid,i],2)] &$
endfor

my_multiplot, 2, 2, pp, pp1, ymax=ysep, ymin=0.02, xmax=xsep, xmargin=xmargin, xmin=0.1, $
              /full, /dry, /rev
plot, toi[ikid,*], /xs, /ys, position=pp[0,0,*], /noerase, chars=0.6
for i=0, n_templates-1 do oplot, out_coeffs[ikid,i]*templates[i,*], col=ct[i]
oplot, out_temp[ikid,*], col=0, thick=2

plot, toi[ikid,*]-out_temp[ikid,*], /xs, /ys, position=pp[0,1,*], /noerase
legendastro, strtrim(stddev( toi[ikid,*]-out_temp[ikid,*]),2)

my_multiplot, 1, 1, pp, pp1, xmin=xsep, xmargin=xmargin, ymax=ysep, xmax=0.97
power_spec, toi[ikid,*]-out_temp[ikid,*], !nika.f_sampling, pw, freq
plot_oo, freq, pw, /xs, /ys, /noerase, position=pp1[0,*], chars=0.6

;; successive decorrelation to avoid very different
;; magnitudes in coefficients
junk = junk_copy
nk_subtract_templates_3, param, info, junk, flag, off_source, $
                         kidpar, templates[0:1,*], out_coeffs=out_coeffs1
nk_subtract_templates_3, param, info, junk, flag, off_source, $
                         kidpar, templates[2:*,*], out_temp, out_coeffs=out_coeffs

wind, 1, 1, /free, /large, xpos=100
my_multiplot, 1, 2, pp, pp1, ymin=ysep, ntot=n_templates, /rev, /full, /dry, ymax=0.97
for i=0, 1 do begin &$
   plot, out_coeffs1[ikid,i]*templates[i,*], /xs, /ys, /noerase, position=pp1[i,*], $
         charsize = 1d-10 &$
   legendastro, [strtrim(i,2), strtrim(out_coeffs1[ikid,i],2)] &$
endfor
for i=2, n_templates-1 do begin &$
   plot, out_coeffs[ikid,i-2]*templates[i,*], /xs, /ys, /noerase, position=pp1[i,*], $
         charsize = 1d-10 &$
   legendastro, [strtrim(i,2), strtrim(out_coeffs[ikid,i-2],2)] &$
endfor
my_multiplot, 2, 2, pp, pp1, ymax=ysep, ymin=0.02, xmax=xsep, xmargin=xmargin, xmin=0.1, $
              /full, /dry, /rev
plot, junk[ikid,*], /xs, /ys, position=pp[0,1,*], /noerase
legendastro, strtrim(stddev( junk[ikid,*]),2)
my_multiplot, 1, 1, pp, pp1, xmin=xsep, xmargin=xmargin, ymax=ysep, xmax=0.97
power_spec, junk[ikid,*], !nika.f_sampling, pw, freq
plot_oo, freq, pw, /xs, /ys, /noerase, position=pp1[0,*], chars=0.6

if param.method_num eq 80 then stop

