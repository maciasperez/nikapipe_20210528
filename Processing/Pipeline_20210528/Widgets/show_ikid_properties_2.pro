
pro show_ikid_properties_2

common bt_maps_common

erase

!x.charsize = 1e-10
!y.charsize = 1e-10

wplot = where( kidpar.plot_flag eq 0, nwplot)

nplot_lines = 2
nplot_col   = 2
my_multiplot, /dry, 2, nplot_lines, global_pp, /full

;; Bottom is the median filtered timeline
!p.position = global_pp[0,0,*]
plot, time, data.rf_didq[disp.ikid,*], /xs, /ys, /noerase
leg_txt = "Kid "+strtrim( kidpar[disp.ikid].numdet,2)
if operations.decorr ne 0 then leg_txt = [leg_txt, 'Decorrelated']
legendastro, leg_txt

;; Middle is the decorrelated timeline
!p.position = global_pp[0,1,*]
plot, time, toi_med[disp.ikid,*], /xs, /ys, /noerase
leg_txt = ["Kid "+strtrim( kidpar[disp.ikid].numdet,2), $
           "Median filtered"]
legendastro, leg_txt

if kidpar[disp.ikid].a_peak lt 1e4 then fmt='(F7.2)' else fmt='(E8.1)'
leg_txt = ['Ampl: '+string(kidpar[disp.ikid].a_peak,format=fmt)+" Hz", $
           "FWHM: "+string(kidpar[disp.ikid].fwhm, format='(F5.2)'), $
           "Noise: "+string(kidpar[disp.ikid].noise, format='(F5.2)')+" Hz.Hz!u-1/2!n", $
           "Resp: "+string( kidpar[disp.ikid].response, format='(F5.2)')+" mK.Hz!u-1!n", $
           "Sens: "+string( kidpar[disp.ikid].sensitivity_decorr, format='(F5.2)')+" mK.Hz!u-1/2!n"]
legendastro, leg_txt, /right, box=0, chars=1.3


;; Stats
my_multiplot, /dry, 1, 3, pp, pp1, /full
dx = global_pp[1,0,2]-global_pp[1,0,0]
dy = global_pp[1,1,3]-global_pp[1,0,1]

for i=0, n_elements(pp1[*,0])-1 do $
   pp1[i,*] = pp1[i,*]*[dx,dy,dx,dy] + [global_pp[1,0,0], global_pp[1,0,1], global_pp[1,0,0], global_pp[1,0,1]]

ikid = disp.ikid + 0.01 ; to activate ikid keyword even if disp.ikid=0
bt_nika_histo, 'fwhm',   junk, pp1[2,*], /noerase, k_units='(mm)', ikid=ikid, /light
bt_nika_histo, 'ellipt', junk, pp1[1,*], /noerase, ikid=ikid, /light
bt_nika_histo, 'a_peak', junk, pp1[0,*], /noerase, k_units='(Hz)', name='Peak ampl.', ikid=ikid, /light

!x.charsize = 1
!y.charsize = 1

end
