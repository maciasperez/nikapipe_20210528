

;; Script to look at all the pointings of the run
;;----------------------------------------------------

pro all_pointings_monitoring

run = 'N2R7'
case 1 of
   run eq 'N2R7': restore, !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R7_v1.save"
   run eq 'N2R9': restore, !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R9_v1.save"
endcase

;; Find which scans were pointings
w = where( scan.obstype eq 'pointing', nw)
scan_list = strtrim(scan[w].day,2)+"s"+strtrim(scan[w].scannum,2)
nscans = n_elements(scan_list)

;; Set png or ps to 1 to save the final output plot
png = 1
ps  = 0

;; Discard black listed kids
blacklist_file = !nika.pipeline_dir+"/Datamanage/blacklist_"+strupcase(run)+".dat"
if file_test( blacklist_file) eq 1 then begin
   readcol, blacklist_file, badscans, format='A', /silent
   my_match, scan_list, badscans, suba, subb, nmatch
   keep = lonarr(nscans) + 1
   if nmatch ne 0 then keep[suba] = 0
   w = where( keep eq 1)
   scan_list = scan_list[w]
   nscans = n_elements(scan_list)
endif

;; Reduce scans that have not been reduced yet
for iscan=0, nscans-1 do begin
   log_file = !nika.plot_dir+"/Logbook/Scans/"+scan_list[iscan]+"/log_info.save"
   if file_test(log_file) eq 0 then nk_rta, scan_list[iscan], /noscp
endfor

;; Retrieve results
p2cor = dblarr(nw)
p7cor = dblarr(nw)
elevation = dblarr(nw)
tau_res       = dblarr(3,nscans)
for iscan=0, nscans-1 do begin
   restore, !nika.plot_dir+"/Logbook/Scans/"+scan_list[iscan]+"/log_info.save"
   p2cor[iscan] = log_info.result_value[0]
   p7cor[iscan] = log_info.result_value[1]
   elevation[iscan] = log_info.mean_elevation
   tau_res[0,iscan]     = log_info.tau_1mm
   tau_res[2,iscan]     = log_info.tau_1mm
   tau_res[1,iscan]     = log_info.tau_2mm
endfor

;; Display all pointings
xmin = -30
xmax = 30
ymin = -30
ymax = 30
wind, 1, 1, /free, /large
outplot, file='Pointing_corrections_'+strupcase(run), png=png, ps=ps
my_multiplot, 2, 2, pp, pp1, /rev, xmargin=0.1, ymargin=0.05, gap_y=0.1, gap_x=0.1
plot, p2cor, psym=8, position=pp[0,0,*], xtitle='Scan index', ytitle='Arcsec'
legendastro, ['Az correction', $
              'Avg: '+num2string( avg(p2cor)), $
              'Std: '+num2string( stddev(p2cor))], box=0
plot, p7cor, psym=8, position=pp[1,0,*], /noerase, xtitle='Scan index', ytitle='Arcsec'
legendastro, ['el correction', $
              'Avg: '+num2string( avg(p7cor)), $
              'Std: '+num2string( stddev(p7cor))], box=0
plot, p2cor, p7cor, psym=8, position=pp[0,1,*], /noerase, $
      xtitle='p2cor (az, arcsec)', ytitle='p7cor (el, arcsec)'
w = where( p2cor ge xmin and p2cor le xmax and $
           p7cor ge ymin and p7cor le ymax, nw)
oplot, p2cor[w], p7cor[w], col=250, psym=1
if nw ne 0 then begin
   plot, p2cor, p7cor, psym=8, position=pp[1,1,*], /noerase, $
         xtitle='p2cor (az, arcsec)', ytitle='p7cor (el, arcsec)', $
         xra=[-30,30], yra=[-30,30], /xs, /ys
   oplot, p2cor[w], p7cor[w], col=250, psym=1
   legendastro, ['Az. Corr. : '+string( avg(p2cor[w]),format='(F5.2)')+" +- "+string(stddev(p2cor[w]),format='(F5.2)'), $
                 'El. Corr. : '+string( avg(p7cor[w]),format='(F5.2)')+" +- "+string(stddev(p7cor[w]),format='(F5.2)')], $
                textcol=250, box=0
                 
endif

;; Pointing corrections vs elevation and opacity
wind, 1, 1, /free, /large
outplot, file='Pointing_corrections_AzElTau'+strupcase(run), png=png, ps=ps
my_multiplot, 2, 2, pp, pp1, /rev, xmargin=0.1, ymargin=0.05, gap_y=0.1, gap_x=0.1
plot, elevation[w], p2cor[w], position=pp[0,0,*], /xs, psym=8, $
      xtitle='Elevation', ytitle='arcsec'
legendastro, 'P2cor (az)', box=0
plot, elevation[w], p7cor[w], position=pp[1,0,*], /xs, psym=8, $
      xtitle='Elevation ', ytitle='arcsec', /noerase
legendastro, 'P7cor (El)', box=0
plot, tau_res[1,w], p2cor[w], position=pp[0,1,*], /xs, psym=8, $
      xtitle='Tau (2mm)', ytitle='arcsec', /noerase
legendastro, 'P2cor (az)', box=0
plot, tau_res[1,w], p7cor[w], position=pp[1,1,*], /xs, psym=8, $
      xtitle='Tau (2mm)', ytitle='arcsec', /noerase
legendastro, 'P7cor (El)', box=0
outplot, /close
my_multiplot, /reset


end
