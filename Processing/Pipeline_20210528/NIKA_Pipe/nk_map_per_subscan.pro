;+
;
; SOFTWARE: 
;        NIKA pipeline
;
; NAME: 
;        nk_map_per_subscan
;
; CATEGORY: 
;        processing, monitoring
;
; CALLING SEQUENCE:
;         nk_map_per_subscan, param, info, data, kidpar, grid
; 
; PURPOSE: 
;        Make one map per subscan.
; 
; INPUT: 
;       
; OUTPUT: 
;        - maps are saved in
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - March 2018: FXD + NP
;-

pro nk_map_per_subscan, param, info, data, kidpar, grid, $
                        xguess=xguess, yguess=yguess, $
                        header=header

if n_params() lt 1 then begin
   message, /info, "Callling sequence:"
   print, "nk_map_per_subscan, param, info, data, kidpar, grid"
   return
endif

if param.cpu_time then param.cpu_t0 = systime(0, /sec)

flag_copy = data.flag
data1     = data

if param.check_anom_refrac then begin
   nsub = max(data.subscan)-2+1
   x = dblarr(4,nsub) + !values.d_nan
   y = dblarr(4,nsub) + !values.d_nan
endif

for isub=2, max( data.subscan) do begin
   w = where( data1.subscan eq isub, nw, compl=wout)
   if nw ge 70 then begin       ; at least 3 seconds of data
      data1[wout].flag = 1
      info1 = info
      grid1 = grid
      param1 = param
      param1.nhits_min_bg_var_map = 1 ; to be safe
      param1.educated = 1             ; make sure
      param1.do_plot=0
      param1.output_dir = param.output_dir+ $
                          '/sub'+strtrim(isub,2)
      spawn, 'mkdir -p ' + param1.output_dir
      nk_projection_4, param1, info1, data1, kidpar, grid1

      if param.check_anom_refrac_nosave eq 1 then begin
         nk_grid2info, grid1, info1, /edu, /noplot
      endif else begin
         info1.result_total_obs_time = n_elements(data1)/!nika.f_sampling
         w1 = where( kidpar.type eq 1, nw1)
         ikid = w1[0]
         junk = nk_where_flag( data1.flag[ikid], [0, 8,11], ncompl=ncompl)
         info1.result_valid_obs_time = ncompl/!nika.f_sampling
         nk_save_scan_results_3, param1, info1, data1, kidpar, grid1, $
                                 xguess=xguess, yguess=yguess, $
                                 header=header
      endelse
      
      x[0,isub-2] = info1.result_off_x_1
      y[0,isub-2] = info1.result_off_y_1

      x[1,isub-2] = info1.result_off_x_2
      y[1,isub-2] = info1.result_off_y_2

      x[2,isub-2] = info1.result_off_x_3
      y[2,isub-2] = info1.result_off_y_3

      x[3,isub-2] = info1.result_off_x_1mm
      y[3,isub-2] = info1.result_off_y_1mm

      ;; reset flags
      data1.flag = flag_copy
   endif
endfor

if param.check_anom_refrac then begin
   if param.do_plot ne 0 then begin
      if param.plot_ps eq 0 then wind, 1, 1, /free
      w = where( finite(x[0,*]), nw)
      if nw lt 2 then begin
         message, /info, "Less than two centroids could be fit on maps per subscan"
         return
      endif

      info.result_ANOM_REFRAC_SCATTER_1   = sqrt( total( (x[0,w]-avg(x[0,w]))^2 + (y[0,w]-avg(y[0,w]))^2))
      info.result_ANOM_REFRAC_SCATTER_2   = sqrt( total( (x[1,w]-avg(x[1,w]))^2 + (y[1,w]-avg(y[1,w]))^2))
      info.result_ANOM_REFRAC_SCATTER_3   = sqrt( total( (x[2,w]-avg(x[2,w]))^2 + (y[2,w]-avg(y[2,w]))^2))
      info.result_ANOM_REFRAC_SCATTER_1mm = sqrt( total( (x[3,w]-avg(x[3,w]))^2 + (y[3,w]-avg(y[3,w]))^2))

      fmt = '(F5.2)'
      !p.multi=0
      plot, x[0,w], y[0,w], $
            xra=minmax([reform(x[1,w]), reform(x[3,w])]), $
            yra=minmax([reform(y[1,w]), reform(y[3,w])]), $
            /xs, /ys, $
            xtitle='Arcsec', ytitle='Arcsec', /nodata
      oplot, x[3,w], y[3,w], psym=8, col=70;, syms=0.5
      oplot, x[1,w], y[1,w], psym=8, col=250;, syms=0.5
      legendastro, ['Scatter rms 1mm: '+string(info.result_ANOM_REFRAC_SCATTER_1mm,form=fmt), $
                    'Scatter rms 2mm: '+string(info.result_ANOM_REFRAC_SCATTER_2,form=fmt)], $
                   col=[70, 250]
   endif
endif

if param.cpu_time then nk_show_cpu_time, param
end
