
pro ktn_ikid_properties

common ktn_common

erase

!x.charsize = 1e-10
!y.charsize = 1e-10

plot_name = "kid_"+strtrim( kidpar[disp.ikid].numdet,2)

wplot = where( kidpar.plot_flag eq 0, nwplot)

nplot_lines = 2
nplot_col   = 2
my_multiplot, /dry, 2, nplot_lines, global_pp, /full, /rev

;; Top left: kid map
position = global_pp[0,0,*]
udgrade = 2 ; disp.rebin_factor
wind, 0, 1
imview, reform(disp.map_list[disp.ikid,*,*]), xmap=disp.xmap, ymap=disp.ymap, udgrade=2, $
        legend_text=['Numdet : '+strtrim(kidpar[disp.ikid].numdet,2), $
                     'Flag = '+strtrim(kidpar[disp.ikid].type,2)], $
        charsize=1e-10, title='Coeff applied', leg_color=disp.textcol, position=position, /noerase
leg_txt = ['Ampl: '+string(kidpar[disp.ikid].a_peak,format=fmt)+" Hz", $
           "FWHM: "+string(kidpar[disp.ikid].fwhm, format='(F5.2)'), $
           "Noise: "+string(kidpar[disp.ikid].noise, format='(F5.2)')+" Hz.Hz!u-1/2!n", $
           "Resp: "+string( kidpar[disp.ikid].response, format='(F5.2)')+" mK.Hz!u-1!n", $
           "Sens: "+string( kidpar[disp.ikid].sensitivity_decorr, format='(F5.2)')+" mK.Hz!u-1/2!n"]
legendastro, leg_txt, /bottom, box=0, chars=1.3, textcol=255

wx = where( disp.x_cross gt !undef, nwx)
if nwx ne 0 then oplot, disp.x_cross[wx], disp.y_cross[wx], psym=1, thick=2, syms=2
!p.position =0

;; Bottom left is the FP
position = global_pp[0,1,*]
xcenter_plot = avg( kidpar[wplot].x_peak)
ycenter_plot = avg( kidpar[wplot].y_peak)
xra_plot = xcenter_plot + [-1,1]*max( abs(kidpar[wplot].x_peak-xcenter_plot))*1.2
yra_plot = ycenter_plot + [-1,1]*max( abs(kidpar[wplot].y_peak-ycenter_plot))*1.2
ktn_quickview_display, xra_plot, yra_plot, position=position, ikid_in=disp.ikid+0.1, /noerase, /only

;; ;; Top right is the timeline
;; my_multiplot, 1, 4, pp, pp1, /rev, /full, /dry
;; dx = global_pp[1,0,2]-global_pp[1,0,0]
;; dy = global_pp[1,0,3]-global_pp[1,1,1]
;; for i=0, n_elements(pp1[*,0])-1 do $
;;    pp1[i,*] = pp1[i,*]*[dx,dy,dx,dy] + [global_pp[1,1,0], global_pp[1,1,1], global_pp[1,1,0], global_pp[1,1,1]]
;; plot, time, data.toi[disp.ikid], /xs, position=pp1[0,*], /noerase
;; 
;; ;; Then beam stats
;; ikid = disp.ikid + 0.01 ; to activate ikid keyword even if disp.ikid=0
;; ktn_histo, 'fwhm',   pp1[1,*], junk, /noerase, k_units='(mm)', ikid=ikid, /light
;; ktn_histo, 'ellipt', pp1[2,*], junk, /noerase, ikid=ikid, /light
;; ktn_histo, 'a_peak', pp1[3,*], junk, /noerase, k_units='(Hz)', name='Peak ampl.', ikid=ikid, /light

!x.charsize = 1
!y.charsize = 1

end
