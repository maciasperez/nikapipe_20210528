diff_file =  !nika.save_dir+'/'+ext+'/'+strupcase(source)+'/'+ $
             strtrim(method_num,2)+  $
             '/Plot/Diff_'+strupcase(source)+strtrim(method_num,2)+version
mamdlib_init, 39
if iter_min eq iter_max then goto, skip_stat
itarr = iter_min+1+ indgen(iter_max-iter_min)
; First iteration is not used
nit = n_elements( itarr)
itind = indgen(nit)
if post ge 1 then begin
   fxd_ps, /landscape, /color
endif
!p.charsize = 0.6
syms = 0.6
if post ne 0 then syms = 0.4
colarr = indgen( 4) ; color table index

      ; Mean, (min, max), Median, Stddev
if post eq 0 then prepare_jpgout, 15, xsi=1400,ysi=1000, ct = 39, /norev ;, /icon
!p.multi = [0, 2, 2]
yra = [-3, 3]
plot,  itarr, diff_stat[0, itarr].mean, /nodata, title = file_basename( diff_file), $
       xtitle = 'Iteration', ytitle = 'Diff SNR mean (JK ---)', xs = 0, ys = 0, $
       xra = [-1, max(itarr)+1], yra = yra
oplot, !x.crange, [0, 0], psym = -3  ; draw a zero line
for icol = 0, 3 do oplot, itarr, diff_stat[   icol, itarr].mean, col = 100+50*icol, psym = -8, syms = syms
for icol = 0, 3 do oplot, itarr, diff_stat_jk[icol, itarr].mean, col = 100+50*icol, psym = -4, line = 2, syms = syms
legendastro, ['I1', 'I3', 'I_1mm', 'I_2mm'], psym = [8, 8, 8, 8], col = 100+50*colarr, /bottom, /left

yra = [-5, 5]
plot,  itarr, diff_stat[0, itarr].min, /nodata, title = file_basename( diff_file), $
       xtitle = 'Iteration', ytitle = 'Diff SNR min,max (JK ---)', xs = 0, ys = 0, $
       xra = [-1, max(itarr)+1], yra = yra
oplot, !x.crange, [0, 0], psym = -3  ; draw a zero line
for icol = 0, 3 do oplot, itarr, diff_stat[   icol, itarr].min, col = 100+50*icol, psym = -8, syms = syms
for icol = 0, 3 do oplot, itarr, diff_stat_jk[icol, itarr].min, col = 100+50*icol, psym = -4, line = 2, syms = syms
for icol = 0, 3 do oplot, itarr, diff_stat[   icol, itarr].max, col = 100+50*icol, psym = -8, syms = syms
for icol = 0, 3 do oplot, itarr, diff_stat_jk[icol, itarr].max, col = 100+50*icol, psym = -4, line = 2, syms = syms

yra = [-3, 3]
plot,  itarr, diff_stat[0, itarr].median, /nodata, title = file_basename( diff_file), $
       xtitle = 'Iteration', ytitle = 'Diff SNR median (JK ---)', xs = 0, ys = 0, $
       xra = [-1, max(itarr)+1], yra = yra
oplot, !x.crange, [0, 0], psym = -3  ; draw a zero line
for icol = 0, 3 do oplot, itarr, diff_stat[   icol, itarr].median, col = 100+50*icol, psym = -8, syms = syms
for icol = 0, 3 do oplot, itarr, diff_stat_jk[icol, itarr].median, col = 100+50*icol, psym = -4, line = 2, syms = syms

yra = [-0.1, 1]
plot,  itarr, diff_stat[0, itarr].stddev, /nodata, title = file_basename( diff_file), $
       xtitle = 'Iteration', ytitle = 'Diff SNR stddev (JK ---)', xs = 0, /ys, $
       xra = [-1, max(itarr)+1], yra = yra
oplot, !x.crange, [0, 0], psym = -3  ; draw a zero line
for icol = 0, 3 do oplot, itarr, diff_stat[   icol, itarr].stddev, col = 100+50*icol, psym = -8, syms = syms
for icol = 0, 3 do oplot, itarr, diff_stat_jk[icol, itarr].stddev, col = 100+50*icol, psym = -4, line = 2, syms = syms

filejpg = diff_file+'.jpg'
if post eq 0 then jpgout,  filejpg, /over
if post eq 2 then begin
   fxd_psout, /rotate, save_file= diff_file+'.pdf', /over
   message, /info,  diff_file+'.pdf'+ ' created'
endif
if post eq 1 then begin
   fxd_psout, /rotate, save_file= diff_file+'.ps', /over
   message, /info,  diff_file+'.ps'+ ' created'
endif

skip_stat:  ; do nothing here
