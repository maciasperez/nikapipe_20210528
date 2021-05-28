
;+
;
; SOFTWARE: Real time analysis
;
; NAME: 
; nk_skydip
;
; CATEGORY: general, RTA
;
; CALLING SEQUENCE:
; 
; PURPOSE: 
;        Analyses skydip scans to determine kid coeffs 
;        that will be used later on for the estimation of opacity.Derives telescope pointing offsets.
; 
; INPUT:
;        - scan: e.g. '20140219s41'
; 
; OUTPUT:
; 
; KEYWORDS:
;        - param: the pipeline parameter structure
;        - sav: to save intermediate products
;        - help: call for help
;        - test: debug mode
;        - png, ps : to output plots on disk
;        - conserv : deal with the first data points
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - 22-11-2012 : A. Catalano first version'
;        - 26-11-2012 : A. Catalano second version'
;        - 01-12-2012 : A. Catalano third version'
;        - 28-05-2013 : A. Catalano fourth version'
;        - 06-01-2014 : A. Catalano fifth version'
;        - 20-01-2014 : A. Catalano sixth version' (skydip_new.pro)
;        - 11-06-2014 : Ported to new pipeline format Nicolas Ponthieu
;-
;================================================================================================

pro nk_skydip, scan, param=param, sav=sav, help=help, xml=xml, $
               test=test, png=png, ps=ps, conserv=conserv, kidpar = kidpar

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_skydip, scan, param=param, sav=sav, help=help, xml=xml, $"
   print, "           test=test, png=png, ps=ps, conserv=conserv, kidpar=kidpar"
   return
endif

;Prepare output directory for plots and logbook
output_dir = !nika.plot_dir+"/"+scan
spawn, "mkdir -p "+output_dir


if not keyword_set(param) then nk_default_param, param
nk_default_info, info
nk_update_scan_param, scan, param, info

;;------------------------------------
;; nk_getdata, param, info, data, kidpar
;; lots of things can be expurged from nk_getdata to make things
;; simpler and faster
param.math = "RF" ; to skip the computation of PF and save a bit of time

nk_find_raw_data_file, param.scan_num, param.day, file_scan, imb_fits_file, xml_file, $
                       /silent, noerror=noerror
if strlen( file_scan) eq 0 then begin
   nk_error, info, "No data available for scan "+strtrim(param.day,2)+"s"+strtrim(param.scan_num,2)
   message, /info, info.error_message
   return
endif

param.data_file     = file_scan
param.file_imb_fits = imb_fits_file
;param.plot_png = 1

;; Init !nika
nk_scan2run, param.scan, run
fill_nika_struct, run

;; Retrieve general information from the Antenna IMBfits file
nk_update_scan_info, param, info, xml=xml

;; Read data
cpu_t0 = systime(0, /sec)
;list_data =  'subscan scan el retard 0 ofs_az ofs_el az paral'+$
;             ' scan_st MJD LST SAMPLE B_T_UTC A_T_UTC I Q dI dQ F_TONE DF_TONE'+$
;             ' RF_didq a_masq b_masq c_position c_synchro k_flag MAP_TBM'
list_data =  'subscan scan el retard 0 rf_didq'+$
             ' scan_st SAMPLE B_T_UTC A_T_UTC F_TONE DF_TONE'+$
             ' a_masq b_masq c_position c_synchro k_flag MAP_TBM'
rr = read_nika_brute(file_scan, param_c, kidpar, data, units, $
                     PARAM_D=PARAM_D, LIST_DATA=LIST_DATA, READ_TYPE=12, $
                     INDEXDETECTEURDEBUT=INDEXDETECTEURDEBUT, $
                     NB_DETECTEURS_LU=NB_DETECTEURS_LU, AMP_MODULATION=AMP_MODULATION, /silent)

;; ;; Shift subscans to solve IRAM synchronization problems but do not
;; ;; wrap around the final subscan to the first one.
;; nshift = long( !nika.subscan_delay_sec*!nika.f_sampling)
;; if nshift ne 0 then begin
;;    nsn    = n_elements(data)
;;    data[nshift:*].subscan = (shift( data.subscan, nshift))[nshift:*]
;; endif

;; Check if this is a polarization scan
nsn = n_elements(data)
if tag_exist( data, "C_POSITION") then begin
   med = median( data.c_position)
   w = where( abs(data.c_position-med) lt 1, nw)
   if float(nw)/nsn lt 0.5 then begin
      if keyword_set(prism) then info.polar = 2 else info.polar = 1
   endif
endif

;; replace rf_didq by toi, adds dra, ddec etc...
nk_update_data_fields, param, info, data

;; Compute the HWP instantaneous angle
if info.polar ne 0 then nk_get_hwp_angle, param, info, data

;; Deal with units convention (numdet, frequencies, parallactic angle, RF/PF...)
nk_data_conventions, param, info, data, kidpar, param_c

;; If a kidpar is passed to nk_getdata, then it replaces the current
;; one given by read_nika_brute
kidpar.numdet = kidpar.raw_num
nk_update_kidpar, param, info, kidpar, param_c

;; Acquisition flags
nk_acqflag2pipeflag, param, info, data, kidpar

;; Flag nan values on some scans
nk_nan_flag, param, info, data, kidpar

;; Flag from scan status
nk_flag_scanst, param, info, data, kidpar

;; Flag from *_masq (detect tunings)
nk_tuningflag, param, info, data, kidpar

;; Dilution flags
nk_tdilflag, param, info, data, kidpar

;; Update kidpar
nkids = n_elements(kidpar)
for ikid=0, nkids-1 do begin
   if min(data.flag[ikid]) ne 0 then kidpar[ikid].type = 3
endfor

;; Reject bad subscans
w = where( data.subscan ge 1, nw)
;; ;;---------------------------
;; print, "fix me:"
;; w = where( data.subscan ge 4, nw)
;; stop
;; ;;------------------------
data = data[w]

;;--------------------------------------

if keyword_set(conserv) then begin
   ;; Remove the starting values that sometimes are bad
   w = where( deriv( data.subscan) ne 0 and data.subscan eq -1, nw)
   if nw ne 0 then data = data[w[0]:*]

   w = where( data.subscan ge 1, nw)
   if nw eq 0 then message, "No subscan ge 1 ?!" else data = data[w]
endif

if info.polar ne 0 then begin
   ;; Determine HWP rotation speed
   nk_get_hwp_rot_freq, data, rot_freq_hz
   param.polar.nu_rot_hwp = rot_freq_hz
   ;; Subtract template
   nika_pipe_hwp_rm, param, kidpar, data, fit
endif

;; ;; Variable Definition
;; final_flag = dblarr(n_elements(kidpar.type))
;; f_tone   = data.f_tone
;; df_tone  = data.df_tone
;; w_on1    = where(kidpar.type eq 1 and kidpar.array eq 1)
;; w_on2    = where(kidpar.type eq 1 and kidpar.array eq 2)
;; f_tone1  = f_tone[w_on1,*]
;; df_tone1 = df_tone[w_on1,*]
;; f_tone2  = f_tone[w_on2,*]
;; df_tone2 = df_tone[w_on2,*]
;; 
;; el   = data.el
;; flag = data.scan_st
;; Loop on the two channels

backot        = intarr( max(data.subscan)+1) - 1 ; init to -1
subscan_f     = intarr( max(data.subscan)+1) - 1 ; init to -1
valid_subscan = indgen( max(data.subscan)+1)

;; Determine "back on track" and "subscan done" boundaries
time = dindgen( n_elements(data))/!nika.f_sampling/60.
for i=min(data.subscan), max(data.subscan) do begin
   w = where( data.scan_st eq 6 and data.subscan eq i, nw)
   if nw ne 0 then backot[i] = w[0]
   w = where( data.scan_st eq 5 and data.subscan eq i, nw)
   if nw ne 0 then subscan_f[i] = w[0]
endfor

;; keep only valid subscans
keep_subscan = where( backot ne -1 and subscan_f ne -1 and subscan_f gt backot, nsubscans)
if nsubscans eq 0 then begin
   message, /info, "No valid subscan."
   stop
endif
backot        = backot[       keep_subscan]
subscan_f     = subscan_f[    keep_subscan]
valid_subscan = valid_subscan[keep_subscan]

;; Discard the first one that seems always bad ?
w = where( valid_subscan ne 1, nsubscans)
valid_subscan = valid_subscan[w]
backot        = backot[w]
subscan_f     = subscan_f[w]

;; Flag out tunings
masq = double( data.a_masq ne 0 or data.b_masq ne 0)
;; Take some margin
masq = long( smooth( masq, 20) ne 0)

;; Monitoring plot
xra=[0,3]

wind, 1, 1, /free, xs=1200, ys=900, title='nk_skydip '+strtrim(param.scan,2)
outplot, file=output_dir+"/skydip_elevation_"+strtrim(param.scan,2), png=param.plot_png, ps=param.plot_ps, /transp
yra = minmax( data.df_tone[0])
yra = yra + [-1,1]*0.3*(max(yra)-min(yra))
!p.multi = [0,1,2]
plot,time,data.el*180./!pi,thick=2,xtitle='Time (min)',ytitle='Elevation (deg)', /xs, xra=xra
make_ct, nsubscans, ct
for i=0, nsubscans-1 do begin
   w = indgen( subscan_f[i]-backot[i]+1) + backot[i]
   ac_lines, time[ backot[i]],   /vertical, line = 3, col = 70
   ac_lines, time[ subscan_f[i]],/vertical,line=3,col=240
   oplot, time[w], data[w].el*!radeg, psym=1, col=ct[i]
endfor
oplot, time, data.subscan*2

plot, time, data.df_tone[0], /xs, yra=yra, /ys, title='df_tone[0]', xra=xra
for i=0, nsubscans-1 do begin
   oplot, [time[backot[i]]], [data[backot[i]].df_tone[0]], psym=8, col=70
   oplot, [time[subscan_f[i]]], [data[subscan_f[i]].df_tone[0]], psym=8, col=250
   ac_lines, time[ backot[i]],   /vertical, line = 3, col = 70
   ac_lines, time[ subscan_f[i]],/vertical,line=3,col=250
endfor
oplot, time, data.subscan*2e5/max(data.subscan)
;oplot, time, -masq*1e5, col=250
legendastro, ['back on track', 'subscan done', 'valid samples'], psym=[8,8,1], col=[70,250,150], box=0

for lambda=1, 2 do begin
   nk_list_kids, kidpar, lambda=lambda, valid=w1, nval=nw1
   tit = strtrim(lambda,2)+"MM"
   if nw1 ne 0 then begin

      dft       = dblarr(nw1,nsubscans)
      ft        = dblarr(nw1,nsubscans)
      er        = dblarr(nw1,nsubscans)
      tau       = dblarr(nw1)
      K         = dblarr(nw1)
      fto       = dblarr(nw1)   
      ell       = dblarr(nsubscans)
      junk_chi2 = dblarr(nw1)

      ;; Andrea's 'der' parameter
      ;der = 30
      der = 0

      make_ct, nsubscans, ct
      for j=0,nw1-1 do begin
         ikid = w1[j]
         for i=0,nsubscans-1 do begin
            ;; Restrict to the fraction of the subscan after the last tuning and
            ;; before subscandone

            ;; Because of the convolution on masq to take margin around the
            ;; tunings, some samples at the end of the current subscan can be
            ;; flagged out by the tuning of the next scan.
            ;; Here, I therefore take either subscan_f or the last valid sample
            ;; of the subscan as the end limit.
            junk = where( data.subscan eq valid_subscan[i] and masq eq 0, nj)
            if nj eq 0 then begin
               message, /info, "all samples flagged out by tuning for subscan "+strtrim(valid_subscan[i],2)+" ?!"
               return
            endif
            tmax = min( [max(time[junk]), time[subscan_f[i]]])

            ;; Determine the last sample hurt by a tuning
            junk = where( data.subscan eq valid_subscan[i] and masq ne 0 and time le tmax, nj)
            if nj eq 0 then begin
               imax = min( where(data.subscan eq valid_subscan[i]))
            endif else begin
               imax = max(junk)
            endelse

            ;; Select samples between the last sample hurt by a tuning and the
            ;; last valid sample of the subscan
            w = where( data.flag[ikid] eq 0 and data.subscan eq valid_subscan[i] and $
                       time ge time[backot[i]+der] and time le tmax and $
                       data.sample gt data[imax].sample, nw)

            if nw eq 0 then begin
               message, /info, "No valid sample for kid "+strtrim(ikid,2)+" and subscan "+strtrim(valid_subscan[i],2)
               stop
            endif else begin
               ;; Populate arrays
               ell[i]   = mean(data[w].el)
               dft[j,i] = mean(data[w].df_tone[ikid])
               ft[j,i]  = mean(data[w].f_tone[ikid])
               er[j,i]  = sqrt( stddev(data[w].f_tone[ikid])^2 + stddev(data[w].df_tone[ikid])^2)
         
                                ;plot,  time,    el*180./!pi,thick=2,xtitle='Time (min)',ytitle='Elevation (deg)'
                                ;oplot, time[w], el[w]*180./!dpi, psym=1, col=ct[i]
               if j eq 0 then oplot, time[w], data[w].df_tone[0], psym=1, col=150
            endelse
         endfor
         if j eq 0 then outplot, /close

         ;; FIT SESSION
         ffrx=-1.*(ft(j,*)+dft(j,*))
         ffrx=reform(ffrx)
         air_mass=1./sin(ell)
         taup=0.
         tatm=270.
         if lambda eq 1 then p_start=[1600,0.1,-2.0d9]
         if lambda eq 2 then p_start=[500,0.08,-1.4d9]
         e_r=1.d3
         parinfo = replicate({fixed:0, limited:[1,1], limits:[0.,0.]}, n_elements(p_start))
         ;if lambda eq 1 then parinfo[0].limits=[800.,2500]
         ;if lambda eq 2 then parinfo[0].limits=[300.,1500]
         if lambda eq 1 then parinfo[0].limits=[1000.,  2000.]
         if lambda eq 2 then parinfo[0].limits=[350., 3000.]
         parinfo[1].limits=[0.0,1.]
         parinfo[2].limits=[-1.d10,-1.d8]                                                    
         fito = mpfitfun("tau_model2", air_mass, ffrx, e_r,p_start, /quiet, parinfo=parinfo)
         tau[j] = fito(1)
         K[j]   = fito(0)
         fto[j] = fito(2)

         fittt=fto[j]+k[j]*270.d0*(1.d0-exp(-air_mass*tau[j]))
         junk_chi2[j] = total( (ffrx-fittt)^2)
         if test eq 1 then begin
            window,5
            !P.multi=[0,1,1]
            plot,air_mass,ffrx,/yst,title="kid "+strtrim(j,2)+", Numdet: "+strtrim(ikid,2)
            oplot,air_mass,fittt,col=250,line=2
            xyouts,0.2,0.8,tau[j],/norm
            xyouts,0.2,0.7,fto[j],/norm
            xyouts,0.2,0.6,k[j],/norm
            
            wait,0.1
         endif
      endfor ; loop on kids

      m = median( junk_chi2)

      ;; Discard outlyer values of tau
      ;idx1  = where(sqrt((tau-mean(tau))^2) lt 3*stddev(tau), nidx1)
      ;idx1 = where(junk_chi2 le m, nidx1)
      idx1 = where( abs(tau-mean(tau)) lt 0.7*stddev(tau), nidx1)
      tau_v = tau(idx1)
      Const = K(idx1)
      f_to  = fto(idx1)
      
      ;; FIT Function
      FIT_func = dblarr( nidx1, nsubscans)
      for i=0,nidx1-1 do FIT_func[i,*] = f_to[i] + Const[i]*Tatm*((1.-exp(-1.*air_mass*tau_v[i])))
         
      ;; Save intermediate results
      if keyword_set(sav) then save,filename='skydip'+param.day+strtrim(param.scan_num,2)+tit+'.save',air_mass,ft,dft,idx1,fit_func

      ;; SECOND FIT AFTER FIXING TAU
      tau_fix = mean(tau_v)
      fi      = dblarr(nidx1)
      ki      = dblarr(nidx1)
      
      p_start=[1.d2,tau_fix,-1.d9]
      e_r=1.d3
      parinfo = replicate({fixed:0, limited:[1,1], limits:[0.,0.]}, n_elements(p_start))
      parinfo[0].limits=[0.,1.d5]
      parinfo[1].limits=[tau_fix-tau_fix*0.001,tau_fix+tau_fix*0.001]
      parinfo[2].limits=[-1.d10,0.]
      
      for j=0, nidx1-1 do begin
         fff=f_to[j]+Const[j]*Tatm*((1.-exp(-1.*air_mass*tau_fix)))
         fit1 = mpfitfun("tau_model2", air_mass, fff, e_r,p_start, /quiet ,parinfo=parinfo)
         fi[j]=fit1[2]
         Ki[j]=fit1[0]
         if test eq 1 then begin
            fitt_t=fi[j]+ki[j]*270.d0*(1.d0-exp(-air_mass*tau_fix))
            window,6
            plot,air_mass,fff,/yst
            oplot,air_mass,fitt_t,col=250,line=2
            xyouts,0.2,0.4,tau_fix,/norm
            xyouts,0.2,0.3,fi[j],/norm
            xyouts,0.2,0.2,ki[j],/norm
            wait,0.1
         endif
         kidpar[w1[idx1[j]]].c0_skydip = fi[j]
         kidpar[w1[idx1[j]]].c1_skydip = ki[j]
      endfor

      if lambda eq 1 then begin
         skydip_final1={channel:tit ,scan_number:param.scan_num , day:param.day , valid_kid:w1[idx1] , par1:fi , par2:ki , par3:tau_fix}
         skydip_res1mm={fit1mm:fit_func, am1mm:air_mass , ft1mm:ft , dft1mm:dft ,idx1mm:idx1 , tau1mm:tau_v}
      endif else begin
         skydip_final2={channel:tit ,scan_number:param.scan_num , day:param.day , valid_kid:w1[idx1] , par1:fi , par2:ki , par3:tau_fix}
         skydip_res2mm={fit2mm:fit_func, am2mm:air_mass , ft2mm:ft , dft2mm:dft ,idx2mm:idx1 , tau2mm:tau_v}
      endelse

   endif                        ; valid kids at lambda
endfor                          ; loop on lambda

;; Histogram and results
am1=skydip_res1mm.am1mm
am2=skydip_res2mm.am2mm
ft1mm=skydip_res1mm.ft1mm
dft1mm=skydip_res1mm.dft1mm
fit1mm=skydip_res1mm.fit1mm
id1mm=skydip_res1mm.idx1mm
ft2mm=skydip_res2mm.ft2mm
dft2mm=skydip_res2mm.dft2mm
fit2mm=skydip_res2mm.fit2mm
id2mm=skydip_res2mm.idx2mm
tau1mm=skydip_res1mm.tau1mm
tau2mm=skydip_res2mm.tau2mm

!P.multi=[0,1,2]
wind, 1, 1, /free, title=' SKYDIP FIT Results',xsize=1200,ysize=400
outplot, file=output_dir+'/skydip_results_'+strtrim(scan,2), png=param.plot_png, ps=param.plot_ps, /transp
plot,am1,fit1mm(0,*)-min(fit1mm(0,*)),xtitle='Air Mass',ytitle='Ftone (Hz)',charsize=1,/nodata
for i=0,n_elements(id1mm)-1 do begin
   ffr=-1.*(ft1mm(id1mm(i),*)+dft1mm(id1mm(i),*))
   ffr=reform(ffr)              ;-ffr(0)
   oplot,am1,ffr-min(ffr),thick=1,col=70
   oplot,am1,fit1mm(i,*)-min(fit1mm(i,*)),line=2,thick=1
endfor
for i=0,n_elements(id2mm)-1 do begin
   ffr=-1.*(ft2mm(id2mm(i),*)+dft2mm(id2mm(i),*))
   ffr=reform(ffr)              ;-ffr(0)
   oplot,am2,ffr-min(ffr),thick=1,col=250
   oplot,am2,fit2mm(i,*)-min(fit2mm(i,*)),line=2,thick=1
endfor
legendastro,['1mm Channel','2mm Channel'],col=[70,250],box=1,line=[0,0],/fill,charsize=0.8,/left,/top

binn1=stddev(tau1mm)/2.
binn2=stddev(tau2mm)/2.
n_histwork,tau1mm,x,y,gpar,bin=binn1,/fit,/noplot
sigma1mm=gpar(2)
n_histwork,tau2mm,x,y,gpar,bin=binn2,/fit,/noplot
sigma2mm=gpar(2)



;Convert a number to a string with a fixed number of significant digits.
number=[mean(tau1mm),sigma1mm,mean(tau2mm),sigma2mm]
digits=2
dd=strarr(n_elements(number))
for i=0,n_elements(number)-1 do begin
   expon=fix(alog10(number(i)))
   if (number(i) lt 1) then expon=expon-1
   c=round(number(i)/10.0^(expon-(digits-1)))*10.0^(expon-(digits-1))
   if (c gt 10^(digits-1)) then dd(i) = strn(round(c)) $
   else dd(i) = strn(string(c,format='(f20.'+strn(digits-1-expon)+')'))
endfor
;***********************************************************************
n_histwork,tau1mm,x,y,gpar,bin=binn1,xr=[0,1],yr=[0,40],/fill,fcolor=70,xtitle='Sky Opacity',ytitle='Histo'
n_histwork,tau2mm,/overplot,/fill,fcolor=250,x,y,gpar,bin=binn2
legendastro,['1mm Channel','2mm Channel'],col=[70,250],box=1,line=[0,0],/fill,charsize=0.8,/left,/top
xyouts,0.78,0.4,'!4s!3 = '+dd(0)+' +/- '+dd(1),col=70,/norm
xyouts,0.78,0.35,'!4s!3 = '+dd(2)+' +/- '+dd(3),col=250,/norm
outplot, /close

;; Get useful information for the logbook
nika_get_log_info, param.scan_num, param.day, data, log_info, kidpar=kidpar
log_info.scan_type = 'skydip'
if keyword_set(polar) then log_info.scan_type = 'skydip_polar'
log_info.result_name[ 0] = 'Tau_1mm'
log_info.result_value[0] = string(dd[1],format='(F5.2)')
log_info.result_name[ 1] = 'Tau_2mm'
log_info.result_value[1] = string(dd[0],format='(F5.2)')

;; Create a html page with plots from this scan
nika_logbook_sub, param.scan_num, param.day

;; Save output
nk_write_kidpar, kidpar, !nika.save_dir+"/skydip_kidpar_"+strtrim(param.day,2)+"s"+strtrim(param.scan_num,2)+".fits", /silent

!p.multi=0

end
