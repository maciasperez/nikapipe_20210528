
;; Quicklook at standard results per scan to derive a robust list of
;; scans
;;-------------------------------------------------------------------


;version = 5
;rainbow = 1

pro imcm_select_scans, version, rainbow=rainbow
;; dir = !nika.plot_dir+'/imcm_RZprojection_1mm_PosSNR_SmoothDeglitch_NiterCM5_Atm60sec_AllScans_AtmNsmooth_NewDeglitch_4sigma_SubscanEdgeW8_AllScans/'+$
;;      'G2/611/iter0/v_1'

;; dir = !nika.plot_dir+'/imcm_test/G2/15/iter0/v_1'
dir = !nika.plot_dir+'/imcm_test/G2/611/iter0/v_1'

;; pro imcm_select_scans, version, dir, png=png, output_scan_list_file=output_scan_list_file

spawn, "ls "+dir, scan_list

;; this one failed
scan_list = scan_list[ where( scan_list ne '20171028s94')]
nscans = n_elements(scan_list)

; delvarx, info_all
if defined(info_all) eq 0 then begin
   std_red       = dblarr( 3, nscans)
   std2cm        = dblarr( 3, nscans)
   sigma_std_red = dblarr( 3, nscans)
   sigma_std2cm  = dblarr( 3, nscans)
   for iscan=0, nscans-1 do begin
      nk_read_csv_2, dir+"/"+scan_list[iscan]+"/info.csv", info
      if defined(info_all) eq 0 then begin
         info_all = replicate(info, nscans)
      endif
      info_all[iscan] = info

      restore, dir+"/"+scan_list[iscan]+"/results.save"
      for iarray=1, 3 do begin
         w1 = where( kidpar1.type eq 1 and kidpar1.array eq iarray, nw1)
         std_red[       iarray-1, iscan] = avg(     kidpar1[w1].std_red)
         std2cm[        iarray-1, iscan] = avg(     kidpar1[w1].std2cm)
         sigma_std_red[ iarray-1, iscan] = stddev(  kidpar1[w1].std_red)
         sigma_std2cm[  iarray-1, iscan]  = stddev( kidpar1[w1].std2cm)
      endfor
   endfor
endif

if nscans ne n_elements(info_all) then begin
   message, /info, "Incompatible nscans and info_all"
   stop
endif

threshold_correction = 1.8

case version of
   1:begin
      wtau = where( std2cm[0,*] le 0.8 and $
                    std_red[0,*] le 0.3, nwtau, compl=wout, ncompl=nwout)
      cut_def = 'std2cm < 0.8, std_red < 0.3: compatibility with CM'
   end

   2: begin
      wtau = where( std2cm[0,*] le 0.8 and $
                    std_red[0,*] le 0.3 and $
                    info_all.result_ATM_POWER_4HZ_A1 lt 0.01, nwtau, compl=wout, ncompl=nwout)
      cut_def = 'std2cm < 0.8, std_red < 0.3: compatibility with CM + atm_power_4Hz below 0.01'
   end

   3: begin
      wtau = where( info_all.result_tau_1mm le 0.5, nwtau, compl=wout, ncompl=nwout)
      cut_def = 'Tau 1mm <= 0.5'
   end

   4: begin
      wtau = where( info_all.result_tau_1mm/sin(info_all.result_elevation_deg*!dtor) le 0.65, nwtau, compl=wout, ncompl=nwout)
      cut_def = 'Tau_1mm/sin(elev) <= 0.65'
   end

   5: begin
      wtau = where( info_all.result_tau_1mm/sin(info_all.result_elevation_deg*!dtor) le 0.6, nwtau, compl=wout, ncompl=nwout)
      cut_def = 'Tau_1mm/sin(elev) <= 0.60'
   end

   6: begin
      wtau = where( info_all.result_ATM_POWER_60SEC_A1 lt 20, nwtau, compl=wout, ncompl=nwout)
      cut_def = 'Atm power 60s < 20'
   end


   else: begin
      wtau = indgen(nscans) & nwout = 0 & nwtau = n_elements(wtau)
      cut_def = 'all scans, no selection'
   end

endcase


if keyword_set(rainbow) then make_ct, nscans, ct else ct=intarr(nscans)+150
if nwout ne 0 then ct[wout] = 0

fmt='(F4.1)'
xfit = dindgen(100)/99.
p=-1
wind, 1, 1, /free, /large
;my_multiplot, 4, 4, pp, pp1, gap_x=0.05, xmargin=0.01, $
;              xmin=0.03, xmax=0.98, /rev
!p.charsize = 0.7
;; plot, info_all.result_tau_1/sin(info_all.result_elevation_deg*!dtor), $
;;       info_all.result_nefd_center_i1, $
;;       psym=8, syms=0.5, position=pp[0,0,*], xtitle='tau/sin(el)', ytitle='NEFD center'
;; nefd0 = avg( info_all.result_nefd_center_i1/exp(info_all.result_tau_1/sin(info_all.result_elevation_deg*!dtor)))
;; oplot, xfit, nefd0*exp(xfit)
;; legendastro, ['A1', 'Rough NEFD!d0!n '+string(nefd0*1000,form=fmt)]

xsep = 0.4
my_multiplot, 1, 3, pp, pp1, xmin=0.05, xmax=xsep, xmargin=0.01, /rev, ymax=0.8, gap_y=0.02
outplot, file='g2_sorted_scan_v'+strtrim(version,2), png=png
!x.charsize = 0.8

xyouts, 0.04, 0.9, 'Version '+strtrim(version,2)+', Keeping '+$
        strtrim(nwtau,2)+"/"+strtrim(nscans,2)+" scans ("+string( float(nwtau)/nscans*100, form='(F5.1)')+"%)", /norm
xyouts, 0.04, 0.87, "Selection criterion:",/norm
xyouts, 0.04, 0.85, cut_def, /norm


p++
x = info_all.result_tau_1mm/sin(info_all.result_elevation_deg*!dtor)
y = info_all.result_nefd_center_i_1mm
plot, x, y, $
      psym=8, syms=0.5, position=pp1[p,*], xtitle='tau/sin(el)', ytitle='NEFD center', /noerase
for i=0, nscans-1 do oplot, [x[i]], [y[i]], psym=8, syms=0.5, col=ct[i]
nefd0_1mm = avg( info_all.result_nefd_center_i_1mm/exp(info_all.result_tau_1mm/sin(info_all.result_elevation_deg*!dtor)))
oplot, xfit, nefd0_1mm*exp(xfit)

nefd0_1mm_wtau = avg( info_all[wtau].result_nefd_center_i_1mm/exp(info_all[wtau].result_tau_1mm/sin(info_all[wtau].result_elevation_deg*!dtor)))
diff = info_all[wtau].result_nefd_center_i_1mm - nefd0_1mm_wtau*exp(info_all[wtau].result_tau_1mm/sin(info_all[wtau].result_elevation_deg*!dtor))
sigma = stddev(diff)
oplot, xfit, nefd0_1mm_wtau*exp(xfit),           col=250, line=3
oplot, xfit, nefd0_1mm_wtau*exp(xfit) + 3*sigma, col=250, line=3
oplot, xfit, nefd0_1mm_wtau*exp(xfit) - 3*sigma, col=250, line=3

oplot, info_all.result_tau_2/sin(info_all.result_elevation_deg*!dtor), $
       info_all.result_nefd_center_i2, psym=8, syms=0.5
nefd0_2mm = avg( info_all.result_nefd_center_i2/exp(info_all.result_tau_2/sin(info_all.result_elevation_deg*!dtor)))
oplot, xfit, nefd0_2mm*exp(xfit)
nefd0_2mm_wtau = avg( info_all[wtau].result_nefd_center_i2/exp(info_all[wtau].result_tau_2/sin(info_all[wtau].result_elevation_deg*!dtor)))
oplot, xfit, nefd0_2mm_wtau*exp(xfit), line=2
if defined(wtau) then oplot, info_all[wtau].result_tau_2/sin(info_all[wtau].result_elevation_deg*!dtor), $
                             info_all[wtau].result_nefd_center_i2, $
                             psym=8, col=150, syms=0.5
if keyword_set(rainbow) then begin
   for i=0, nscans-1 do $
      oplot, [info_all[i].result_tau_2/sin(info_all[i].result_elevation_deg*!dtor)], $
             [info_all[i].result_nefd_center_i2], psym=8, col=ct[i], syms=0.5
endif
legendastro, ['A1&A3: Rough NEFD!d0!n '+string(nefd0_1mm*1000,form=fmt), $
              'A2    : Rough NEFD!d0!n '+string(nefd0_2mm*1000,form=fmt)]
legendastro, ['fit on all scans', $
              'fit on selected scans'], line=[0,2], /right, col=[0,250]


p++
yra = array2range(info_all.result_tau_1mm)
plot, info_all.tau225, info_all.result_tau_1mm, psym=8, syms=0.5, position=pp1[p,*], /noerase, $
      xtitle='tau225', ytitle='tau1'
for i=0, nscans-1 do oplot, [info_all[i].tau225], [info_all[i].result_tau_1mm], psym=8, syms=0.5, col=ct[i]
;oplot, [0,1], [0,1]*1.28689-0.00012725, col=70, line=2
fit = linfit( info_all.tau225, info_all.result_tau_1mm)
oplot, [0,1], [0,1]*fit[1] + fit[0], col=70
if defined(wtau) then begin
   fit = linfit( info_all[wtau].tau225, info_all[wtau].result_tau_1mm)
   oplot, [0,1], [0,1]*fit[1] + fit[0], col=150
endif

p++
yra = array2range(info_all.result_tau_2)
plot, info_all.tau225, info_all.result_tau_2, psym=8, syms=0.5, position=pp1[p,*], /noerase, $
      xtitle='tau225', ytitle='tau2'
for i=0, nscans-1 do oplot, [info_all[i].tau225], [info_all[i].result_tau_2], psym=8, syms=0.5, col=ct[i]
;oplot, [0,1], [0,1]*1.28689-0.00012725, col=70, line=2
fit = linfit( info_all.tau225, info_all.result_tau_2)
oplot, [0,1], [0,1]*fit[1] + fit[0], col=70
if defined(wtau) then begin
   fit = linfit( info_all[wtau].tau225, info_all[wtau].result_tau_2)
   oplot, [0,1], [0,1]*fit[1] + fit[0], col=150
endif
oplot, [0,1], [0,1]*0.732015+0.0200369, col=250, line=2
fit = linfit( info_all.tau225, info_all.result_tau_2)
oplot, [0,1], [0,1]*fit[1] + fit[0], col=250
if defined(wtau) then begin
   oplot, info_all[wtau].tau225, info_all[wtau].result_tau_2, psym=8, syms=0.5, col=150
   fit = linfit( info_all[wtau].tau225, info_all[wtau].result_tau_2)
   oplot, [0,1], [0,1]*fit[1] + fit[0], col=150
endif
for i=0, nscans-1 do oplot, [info_all[i].tau225], [info_all[i].result_tau_2], psym=8, col=ct[i], syms=0.5
legendastro, ['1mm', '2mm'], col=[70,250]
legendastro, ['Th. fit 1mm', 'Th. fit 2mm'], line=2, col=[70,250], /right

;; my_multiplot, 1, 11, pp, pp1, xmin=xsep+0.1, xmax=0.97, xmargin=0.01, /rev, gap_y=0.01
my_multiplot, 1, 8, pp, pp1, xmin=xsep+0.1, xmax=0.97, xmargin=0.01, /rev, gap_y=0.01, ymargin=0.001, ymin=0.01, ymax=0.99
!x.charsize=0.0001
p=-1

p++
yra = array2range(info_all.result_tau_1mm)
plot, info_all.result_tau_1mm, psym=-8, syms=0.5, position=pp1[p,*], /noerase
for i=0, nscans-1 do oplot, [i], [info_all[i].result_tau_1mm], psym=-8, syms=0.5, col=ct[i]

oplot, info_all.result_tau_2, psym=-8, syms=0.5
for i=0, nscans-1 do oplot, [i], [info_all[i].result_tau_2], psym=-8, syms=0.5, col=ct[i]
legendastro, ['1mm', '2mm']
legendastro, 'tau', /right

;;!;; p++
;;!;; plot, info_all.result_elevation_deg, psym=-8, syms=0.5, position=pp1[p,*], /noerase
;;!;; if defined(wtau) then oplot, wtau, info_all[wtau].result_elevation_deg, psym=8, syms=0.5, col=150
;;!;; if keyword_set(rainbow) then begin
;;!;;    for i=0, nscans-1 do $
;;!;;       oplot, [i], [info_all[i].result_elevation_deg], psym=8, col=ct[i], syms=0.5
;;!;; endif
;;!;; legendastro, /right, 'elevation'

;; p++
;; matrix_plot, info_all.result_elevation_deg, info_all.result_tau_1mm, info_all.result_nefd_center_i_1mm, $
;;              position=pp1[p,*], /noerase, xtitle='elevation', ytitle='tau 1mm', /black_and_white
;; loadct, 39
;; oplot, info_all[wtau].result_elevation_deg, info_all[wtau].result_tau_1mm, psym=8, col=150
;; legendastro, 'NEFD 1mm'
;; 
;; 
;; p++
;; matrix_plot, info_all.result_elevation_deg, info_all.result_tau_1mm, info_all.result_nefd_center_i2, $
;;              position=pp1[p,*], /noerase, xtitle='elevation', ytitle='tau 1mm', /black_and_white
;; loadct, 39
;; oplot, info_all[wtau].result_elevation_deg, info_all[wtau].result_tau_1mm, psym=8, col=150
;; legendastro, 'NEFD 2mm'

p++
yra = [0, max(info_all.result_nefd_center_i_1mm)*1.3]
plot, info_all.result_nefd_center_i_1mm, psym=-8, syms=0.5, yra=yra, /xs, /ys, $
      position=pp1[p,*], /noerase
for i=0, nscans-1 do oplot, [i], [info_all[i].result_nefd_center_i_1mm], psym=8, col=ct[i], syms=0.5
legendastro, /right, 'NEFD center 1&2 mm'
for i=0, nscans-1 do oplot, [i], [info_all[i].result_nefd_center_i2], psym=8, col=ct[i], syms=0.5


;; p++
;; yra = array2range([info_all.result_sigma_boost_i1])
;; plot, info_all.result_sigma_boost_i1, psym=-8, syms=0.5, yra=yra, /xs, /ys, $
;;       position=pp1[p,*], /noerase, xtitle='scan index', ytitle='sigma boost'
;; oplot, wtau, info_all[wtau].result_sigma_boost_i1, psym=8, syms=0.5, col=150
;; legendastro, 'A1'
;; 
;; p++
;; yra = array2range([info_all.result_sigma_boost_i2])
;; plot, info_all.result_sigma_boost_i2, psym=-8, syms=0.5, yra=yra, /xs, /ys, $
;;       position=pp1[p,*], /noerase, xtitle='scan index', ytitle='sigma boost'
;; oplot, wtau, info_all[wtau].result_sigma_boost_i2, psym=8, syms=0.5, col=150
;; legendastro, 'A2'
;; 
;; p++
;; yra = array2range([info_all.result_sigma_boost_i3])
;; plot, info_all.result_sigma_boost_i3, psym=-8, syms=0.5, yra=yra, /xs, /ys, $
;;       position=pp1[p,*], /noerase, xtitle='scan index', ytitle='sigma boost'
;; oplot, wtau, info_all[wtau].result_sigma_boost_i3, psym=8, syms=0.5, col=150
;; legendastro, 'A3'

p++
array_col = [70, 250, 100]
yra = array2range( std_red[0,*])
plot, std_red[0,*], psym=-8, syms=0.5, /xs, yra=yra, /ys, $
      position=pp1[p,*], /noerase
for i=0, nscans-1 do oplot, [i], [std_red[0,i]], psym=8, col=ct[i], syms=0.5
legendastro, 'A1'
legendastro, /right, 'std_red'

p++
yra = array2range( std2cm[0,*]) ; std2cm[0,wtau])
plot, std2cm[0,*], psym=-8, syms=0.5, /xs, yra=yra, /ys, $
      position=pp1[p,*], /noerase
for i=0, nscans-1 do oplot, [i], [std2cm[0,i]], psym=8, col=ct[i], syms=0.5
legendastro, 'A1'
legendastro, /right, 'std2cm'
;for iarray=1, 3 do oploterror, std2cm[iarray-1,*], sigma_std2cm[iarray-1,*], psym=8, syms=0.5, col=array_col[iarray-1], errcol=array_col[iarray-1]

p++
yra = array2range( info_all.result_ATM_POWER_60SEC_A1)
plot, info_all.result_ATM_POWER_60SEC_A1, psym=-8, syms=0.5, /xs, yra=yra, /ys, $
      position=pp1[p,*], /noerase
a = avg( info_all.result_ATM_POWER_60SEC_A1)
sigma = stddev( info_all.result_ATM_POWER_60SEC_A1)
for i=0, nscans-1 do oplot, [i], [info_all[i].result_ATM_POWER_60SEC_A1], psym=8, col=ct[i], syms=0.5
;oplot, [-1,1]*1d10, [1,1]*a, col=70
;for i=-5, 5 do oplot, [-1,1]*1d10, [1,1]*a + i*sigma, line=2, col=70
legendastro, ['A1 atm power 60 sec']
legendastro, /right, 'Jy/beam.Hz!u-1/2!n'

p++
yra = array2range( info_all.result_ATM_POWER_4HZ_A1)
plot, info_all.result_ATM_POWER_4HZ_A1, psym=-8, syms=0.5, /xs, yra=yra, /ys, $
      position=pp1[p,*], /noerase
for i=0, nscans-1 do oplot, [i], [info_all[i].result_ATM_POWER_4Hz_A1], psym=8, col=ct[i], syms=0.5
legendastro, 'A1 atm power > 4Hz'
legendastro, /right, 'Jy/beam.Hz!u-1/2!n'

;;!;; p++
;;!;; yra = array2range( [info_all.RESULT_NKIDS_VALID1]) ; , info_all.RESULT_NKIDS_VALID2, info_all.RESULT_NKIDS_VALID3])
;;!;; plot, info_all.RESULT_NKIDS_VALID1, psym=-8, syms=0.5, /xs, yra=yra, /ys, $
;;!;;       position=pp1[p,*], /noerase
;;!;; if keyword_set(rainbow) then begin
;;!;;    for i=0, nscans-1 do $
;;!;;       oplot, [i], [info_all[i].RESULT_NKIDS_VALID1], psym=-8, col=ct[i], syms=0.5
;;!;; endif
;;!;; legendastro, 'A1 Valid kids'


p++
yra = array2range( info_all.result_sky_noise_power_1)
plot, info_all.result_sky_noise_power_1, psym=-8, syms=0.5, /xs, yra=yra, /ys, $
      position=pp1[p,*], /noerase
for i=0, nscans-1 do oplot, [i], [info_all[i].result_sky_noise_power_1], psym=8, col=ct[i], syms=0.5
legendastro, 'sky noise power RATIO lf/hf'

p++
yra = array2range( info_all.result_err_flux_center_i1)
plot, info_all.result_err_flux_center_i1, psym=-8, syms=0.5, /xs, yra=yra, /ys, $
      position=pp1[p,*], /noerase
for i=0, nscans-1 do oplot, [i], [info_all[i].result_err_flux_center_i1], psym=8, col=ct[i], syms=0.5
legendastro, 'err flux center_i'

outplot, /close, /verb


;; wind, 1, 1, /free, /large
;; my_multiplot, 2, 2, pp, pp1, /rev
;; for iarray=1, 3 do begin
;;    nk_get_info_tag, info_all, 'sky_noise_power', iarray, wskynoise
;;    nk_get_info_tag, info_all, 'flux_center_i', iarray, wflux, werr_flux
;;    ;; x = info_all.(wskynoise)/max(info_all.(wskynoise))
;;    x = info_all.(wskynoise)
;;    plot, x, info_all.(werr_flux), $
;;          psym=8, syms=0.5, position=pp1[iarray,*], /noerase, $
;;          xtitle='sky noise power ratio', ytitle='err flux center'
;;    fit = linfit( x, info_all.(werr_flux))
;;    x = dindgen(100)/99*(max(x)-min(x)) + min(x)
;;    oplot, x, fit[0] + fit[1]*x, col=250
;;    legendastro, strtrim(fit,2), col=250, /right
;;    legendastro, 'A'+strtrim(iarray,2)
;; endfor
;; 

if keyword_set(output_scan_list_file) then begin
   openw, 1, output_scan_list_file
   for i=0, nwtau-1 do printf, 1, scan_list[wtau[i]]
   close, 1
endif


end


