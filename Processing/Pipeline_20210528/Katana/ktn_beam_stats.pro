
pro ktn_beam_stats

common ktn_common

w1 = where( kidpar.type eq 1, nw1)
wplot = where( kidpar.plot_flag eq 0, nwplot)

wind, 1, 1, /free, ys=800
outplot, file=sys_info.plot_dir+"/"+sys_info.nickname+'_beam_histos', png=sys_info.png, ps=sys_info.ps

ww = where( finite( kidpar.fwhm) ne 1 and kidpar.type ne 2, nww)
if nww ne 0 then begin
   kidpar[ww].type = 5
   kidpar[ww].plot_flag = 1
endif

my_multiplot, 1, 5, /rev, pp, pp1, /dry
data_str = {a:kidpar[wplot].fwhm_x, b:kidpar[wplot].fwhm_y}
np_histo, data_str, xhist, yhist, gpar, $
          fcolor=[70,200], colorplot=[70,200], position=pp1[0,*], /blend, fit=disp.histo_fit, /fill, /nolegend, $
          title=sys_info.nickname
leg_txt = ['FWHMx median: '+num2string( median(kidpar[wplot].fwhm_x)), $
           'FWHMy median: '+num2string( median(kidpar[wplot].fwhm_y))]
if disp.histo_fit ne 0 then leg_txt = [leg_txt, $
                                       "", $
                                       'FWHMx avg: '+num2string(gpar[0,1]), $
                                       'FWHMy avg: '+num2string(gpar[1,1])]
legendastro, leg_txt, /right, box=0, chars=1

ktn_histo, 'fwhm',   pp1[1,*], gpar_fwhm,   /noerase, k_units='(arcsec)', fit=disp.histo_fit
ktn_histo, 'ellipt', pp1[2,*], gpar_ellipt, /noerase, fit=disp.histo_fit
ktn_histo, 'a_peak', pp1[3,*], gpar_ampl,   /noerase, k_units='(Hz)', name='Peak ampl.', fit=disp.histo_fit
ktn_histo, 'noise',  pp1[4,*], gpar_noise,  /noerase, k_units='(Hz.Hz!u-1/2!n)', name='Noise', fit=disp.histo_fit
outplot, /close


end
