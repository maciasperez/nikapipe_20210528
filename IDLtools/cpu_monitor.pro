
pro cpu_monitor, ytickv, time, date, routine, $
                 dir=dir, col=col, title=title, ps=ps, png=png, $
                 output_plot_file=output_plot_file, zbuffer=zbuffer

if not keyword_set(dir) then dir = '.'
if not keyword_set(output_plot_file) then output_plot_file = 'cpu_monitor_plot'

file = dir+"/cpu_time_summary_file.dat"
if file_test(file) eq 0 then begin
   message, /info, "Please specify dir= to find cpu_time_summary_file.dat"
   message, /info, "by default it should be param.project_dir+'/v_1/'+scan"
   return
endif
readcol, file, routine, time, format = 'AD', delimiter = ','

nr = n_elements(routine)
ytickv = reverse(findgen(nr)/(nr-1))
xra = [-0.1, 1.1]

col = [70, 200, 250]

charsize = 0.7
yra = [-0.1,1.1]
if ps eq 0 then wind, 1, 1, /free, /large
outplot, file=output_plot_file, ps=ps, png=png, zbuffer=zbuffer
!p.multi=[0,2,1]
xra = [-0.7,1]*max(time)
plot, time, ytickv, psym=-8, xtitle = 'time per routine (sec)', $
      xra = xra, /xs, yra=yra, /ys, syms=0.5
oplot, [0,0], [0,1]
for ir = 0, nr-1 do begin
   xyouts, min(xra), ytickv[ir], routine[ir], charsize=charsize, col=col[ir mod 3]
   oplot, [time[ir]], [ytickv[ir]], psym=8, col=col[ir mod 3]
endfor

readcol, dir+"/cpu_date.dat", routine, date, format = 'AD', delimiter = ','
xra = [-0.1,1.1]*max(date)
plot, date, ytickv, psym = -8, xra = xra, title=title, syms=0.5, $
      yra = yra, /ys,  /xs, xtitle = 'time elapsed since entering nk'
oplot, date, ytickv, psym = -8
for ir = 0, nr-1 do begin
   xyouts, min(xra), ytickv[ir], routine[ir], charsize=charsize, col=col[ir mod 3]
   oplot, [date[ir]], [ytickv[ir]], psym=8, col=col[ir mod 3]
endfor
!p.multi = 0
outplot, /close, /verb


end
