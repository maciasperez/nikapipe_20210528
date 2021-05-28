;+
;PURPOSE: Remove a straight line as a baseline per subscan
;         See also nika_pipe_rmbaseline for another determination
;
;INPUT: The parameter, data and kidpar structures
;
;OUTPUT: The decorrelated data structure.
;
;LAST EDITION: 
;-

pro nika_pipe_baseline_subtract, param, data, kidpar, in_frac=in_frac, show=show

  ;;fraction of samples used to fit the baseline on the edges
  if keyword_set(in_frac) then frac = in_frac else frac = 0.1

  if keyword_set(show) then begin
     time = dindgen( n_elements(data))/!nika.f_sampling
     wind, 1, 1, /free, /large
     !p.multi=[0,1,2]
  endif

  for isubscan=min(data.subscan), max(data.subscan) do begin
     w = where( data.subscan eq isubscan, nw)
     if nw gt long(2.5*!nika.f_sampling) then begin
        for ikid=0, n_elements(kidpar)-1 do begin
           n1 = round( nw*frac)
           x1 = lindgen(n1)
           x2 = lindgen(n1) + nw-n1
           fit = linfit( [x1, x2], [data[w[x1]].rf_didq[ikid], data[w[x2]].rf_didq[ikid]])
           baseline = fit[0] + fit[1]*dindgen(nw)

           if keyword_set(show) then begin
              stop
              plot, time[w], data[w].rf_didq[ikid], title="Numdet "+strtrim( kidpar[ikid].numdet,2)
              oplot, time[w], baseline, col=70
              plot, time[w], data[w].rf_didq[ikid]-baseline, title='Diff'
              cont_plot
           endif

           data[w].rf_didq[ikid] -= baseline
        endfor
     endif
  endfor

end
