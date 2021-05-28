
;; Compare measured fluxes on a list of calibrators to their expected
;; value
;; hacked from Labtools/NP/Dev/redo_secondary_calibrators_n2r4.pro
;;
;; Maps must have been previously reduced.
;;------------------------------------------------------------------------

pro nefd_vs_tau, input_dir, source_list, nickname=nickname, $
                 png=png, ps=ps

run = 'N2R9'

;; Try to look at NEFD vs tau
project_dir = !nika.plot_dir+"/N2R9v2Allskd_FXD_GaussPhot"
method = "common_mode_kids_out"

;; Allocate arrays
nscans_tot = 0
nsources_eff = 0
nsources = n_elements(source_list)
for isource=0, nsources-1 do begin
   source = source_list[isource]
   source_dir = input_dir+"/"+str_replace(source," ", "_")
   spawn, "ls -d "+source_dir+"/v_1/*", dir_list
   if dir_list[0] ne '' then begin
      scan_list = file_basename(dir_list)
      nscans = n_elements(scan_list)
      print, "source, nscans: ", source, nscans
      nscans_tot += nscans
      nsources_eff++
   endif
endfor

mystr = create_struct("source", '', $
                      'tau1', 0.d0, $
                      'tau2', 0.d0, $
                      'el', 0.d0, $
                      'nefd1', 0.d0, $
                      'nefd2', 0.d0)
mystr = replicate(mystr, nscans_tot)

col1 = 70
col2 = 250

psym1 = 5
psym2 = 6
col = [col1,col2]
; xtitle = '!7t!3/sin!7d!3'
; ytitle = 'NEFD (mJy.s!u1/2!n)'
xtitle = 'Tau/sin(elevation)'
ytitle = 'NEFD (mJy x sqrt(s))'

;; MOU ref value:
pwv = 2.d0                      ; mm

;; From Pablo's email, March. 13th
;;tau1_mou = 0.075*pwv + 0.001
;;tau2_mou = 0.025*pwv + 0.001

;; From Laurence's estimation, March. 14th
tau1_mou = 0.08*pwv + 0.01
tau2_mou = 0.04*pwv + 0.02 

wind, 1, 1, /free, /large
isource_eff = 0
iscan_tot = 0
my_multiplot, 1, 1, ntot=nsources_eff, pp, pp1, /rev
outplot, file=input_dir+'/NEFD_vs_tau_sources_'+nickname, png=png, ps=ps
for isource=0, nsources-1 do begin
   source = source_list[isource]
   source_dir = input_dir+"/"+str_replace(source," ", "_")
   spawn, "ls -d "+source_dir+"/v_1/*", dir_list
   if dir_list[0] ne '' then begin
      scan_list = file_basename(dir_list)
      nscans = n_elements(scan_list)
      for iscan=0, nscans-1 do begin
         nk_read_csv, source_dir+"/v_1/"+scan_list[iscan]+"/photometry.csv", str
         mystr[iscan_tot].source = str_replace(source," ", "_")
         mystr[iscan_tot].tau1  = str.tau_1mm
         mystr[iscan_tot].tau2  = str.tau_2mm
         mystr[iscan_tot].el    = str.elevation_deg*!dtor
         mystr[iscan_tot].nefd1 = str.nefd_i1*1000
         mystr[iscan_tot].nefd2 = str.nefd_i2*1000
         iscan_tot++
      end

      wsource = where( mystr.source eq str_replace(source," ", "_"))
      x = dindgen(100)/99.*2
      fit1 = linfit( exp(mystr[wsource].tau1/sin(mystr[wsource].el)), mystr[wsource].nefd1)
      fit2 = linfit( exp(mystr[wsource].tau2/sin(mystr[wsource].el)), mystr[wsource].nefd2)

      mou_nefd1 = fit1[0] + fit1[1]*exp(tau1_mou/sin(60.*!dtor))
      mou_nefd2 = fit2[0] + fit2[1]*exp(tau2_mou/sin(60.*!dtor))

      yra = [0, max([mystr[wsource].nefd1,mystr[wsource].nefd2])]*1.5
      xra = [0, max([mystr[wsource].tau2/sin(mystr[wsource].el), $
                     mystr[wsource].tau1/sin(mystr[wsource].el)])]*1.2
      plot,  mystr[wsource].tau1/sin(mystr[wsource].el), mystr[wsource].nefd1, xtitle=xtitle, ytitle=ytitle, /nodata, $
             yra=yra, /ys, title=source, position=pp1[isource_eff,*], /noerase, xra=xra, /xs       ;, $
;       title=source+" "+strtrim(string(ref[wsource].flux1,form='(F5.2)'),2)+$
;       " Jy (1mm) / "+strtrim(string(ref[wsource].flux2,form='(F5.2)'),2)+" Jy (2mm)"
      oplot, mystr[wsource].tau1/sin(mystr[wsource].el), mystr[wsource].nefd1, col=col1, psym=psym1
      oplot, x, fit1[0] + fit1[1]*exp(x), col=col1
      oplot, mystr[wsource].tau2/sin(mystr[wsource].el), mystr[wsource].nefd2, col=col2, psym=psym2
      oplot, x, fit2[0] + fit2[1]*exp(x), col=col2
      oplot, [tau1_mou, tau2_mou]/sin(60.*!dtor), [mou_nefd1, mou_nefd2], psym=8
      form = '(F6.2)'
      legendastro, ['A1: '+strtrim( string(fit1[0],form=form),2)+" + "+strtrim( string(fit1[1],form=form),2)+" exp(tau/sin(el))", $
                    'A2: '+strtrim( string(fit2[0],form=form),2)+" + "+strtrim( string(fit2[1],form=form),2)+" exp(tau/sin(el))", $
                    'NEFD 1 (2mm pwv, el=60 deg.): '+strtrim( string(mou_nefd1,form='(F4.1)'),2), $
                    'NEFD 2 (2mm pwv, el=60 deg.): '+strtrim( string(mou_nefd2,form='(F4.1)'),2)], $
                   col=[col, !p.color, !p.color], textcol=[col, !p.color, !p.color], $
                   psym=[psym1, psym2, 8, 8]
      isource_eff++
   endif
endfor
outplot, /close

;; General plot with all scans
fit1 = linfit( exp(mystr.tau1/sin(mystr.el)), mystr.nefd1)
fit2 = linfit( exp(mystr.tau2/sin(mystr.el)), mystr.nefd2)

mou_nefd1 = fit1[0] + fit1[1]*exp(tau1_mou/sin(60.*!dtor))
mou_nefd2 = fit2[0] + fit2[1]*exp(tau2_mou/sin(60.*!dtor))

yra = [0, max([mystr.nefd1,mystr.nefd2])]*1.5
wind, 1, 1, /free
outplot, file=input_dir+'/NEFD_vs_tau_'+nickname, png=png, ps=ps
plot,  mystr.tau1/sin(mystr.el), mystr.nefd1, xtitle=xtitle, ytitle=ytitle, /nodata, $
       yra=yra, /ys, title='All scans'
oplot, mystr.tau1/sin(mystr.el), mystr.nefd1, col=col1, psym=psym1
oplot, x, fit1[0] + fit1[1]*exp(x), col=col1
oplot, mystr.tau2/sin(mystr.el), mystr.nefd2, col=col2, psym=psym2
oplot, x, fit2[0] + fit2[1]*exp(x), col=col2
oplot, [tau1_mou,tau2_mou]/sin(60.*!dtor), [mou_nefd1, mou_nefd2], psym=8
form = '(F6.2)'
legendastro, ['A1: '+strtrim( string(fit1[0],form=form),2)+" + "+strtrim( string(fit1[1],form=form),2)+" exp(tau/sin(el))", $
              'A2: '+strtrim( string(fit2[0],form=form),2)+" + "+strtrim( string(fit2[1],form=form),2)+" exp(tau/sin(el))", $
              'NEFD 1 (2mm pwv, el=60 deg.): '+strtrim( string(mou_nefd1,form='(F4.1)'),2), $
              'NEFD 2 (2mm pwv, el=60 deg.): '+strtrim( string(mou_nefd2,form='(F4.1)'),2)], $
             col=[col, !p.color, !p.color], textcol=[col, !p.color, !p.color], $
             psym=[psym1, psym2, 8, 8]
outplot, /close

wind, 1, 1, /free
outplot, file=input_dir+'/tau1_tau2_'+nickname, png=png, ps=ps
plot,  mystr.tau1, mystr.tau2, xtitle='Tau 1mm', ytitle='Tau 2mm', $
       title='All scans', psym=5
fit = linfit( mystr.tau1, mystr.tau2)
oplot, [0,2], fit[0] + fit[1]*[0,2]
legendastro, 'Fit Tau2 = '+strtrim(string( fit[0],form='(F5.3)'),2)+" + "+strtrim( string(fit[1],form='(F5.2)'),2)+" x Tau1mm"
outplot, /close


end
