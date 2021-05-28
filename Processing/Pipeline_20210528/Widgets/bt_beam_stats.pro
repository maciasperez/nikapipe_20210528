
pro bt_beam_stats

common bt_maps_common

w1 = where( kidpar.type eq 1, nw1)
wplot = where( kidpar.plot_flag eq 0, nwplot)

wind, 1, 1, /free, ys=900
outplot, file=sys_info.plot_dir+"/"+sys_info.nickname+'_beam_histos', png=sys_info.png, ps=sys_info.ps
my_multiplot, 1, 3, /rev, pp, pp1, /dry

;; if total(finite(kidpar[w1].fwhm)) ne nw1 then begin
;;    ww = where( finite(kidpar[w1].fwhm) ne 1 and (kidpar.type eq 1 or kidpar.type eq 3), nww)
;;    if nww ne 0 then begin
;;       print, "Infinite fwhm for kids: ", ww
;;       kidpar[w1[ww]].type = 5
;;       kidpar[w1[ww]].plot_flag = 1
;;    endif
;; 
;; endif

ww = where( finite( kidpar.fwhm) ne 1, nww)
if nww ne 0 then begin
   kidpar[ww].type = 5
   kidpar[ww].plot_flag = 1
endif

bt_nika_histo, 'fwhm', gpar_fwhm, pp1[0,*], noerase=noerase, k_units='(mm)';, /fit
bt_nika_histo, 'ellipt', gpar_ellipt, pp1[1,*], /noerase;, /fit
bt_nika_histo, 'a_peak', gpar_ampl, pp1[2,*], /noerase, k_units='(Hz)', name='Peak ampl.';, /fit

outplot, /close


end
