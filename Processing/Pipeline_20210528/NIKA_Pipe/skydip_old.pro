pro skydip_old, scan_num, day, kidpar, sav=sav, help=help, test=test, png=png, ps=ps, polar=polar, pf=pf
;*******************************SKYDIP FOR NIKA*********************************
if keyword_set(help) then begin
    print, 'NAME       : skydip'
    print, ''
    print, 'PURPOSE    : Measuring the air mass dependance of the atmosferic emission obtained by performing an elevation scan by leaving the azimuth constant and scanning the elevation'
    print, ''
    print, 'CALL  : skydip,day,scan_num,kidpar,sav=sav,help=help,test=test'
    print, ''
    print, ''
    print, ' INPUTS:'
    print, ' day = Day of the obsarvation -string (Ex:''20121122'')   '
    print, ' scan_num  = Number of scan - integer (Ex: 120)   '
    print, ''
    print, ' OUTPUTS :'
    print, '   kidpar = updated kidpar structure with skydip coefficients'
    print, ''
    print, ' HISTORY : '
    print, '     - 22-11-2012 : first version'
    print, '     - 26-11-2012 : second version'
    print, '     - 01-12-2012 : third version'
    print, '     - 28-05-2013 : fourth version'
    print, '     - 06-01-2014 : fifth version'
    print, ''
    print, '    AUTHOR : '
    print, '     Andrea Catalano'
    print, ''
    print, '   CALL THE HELP AS ''skydip,/HELP'' '
        goto, fin
     endif
;
;/////////////////                                                         
;Preliminary Cecks                                                                  
;/////////////////   
if (N_PARAMS() LT 2) then begin
    if N_PARAMS() EQ 1 then print, '!!please provide number of the scan!!'
    if N_PARAMS() EQ 0 then print, '!!please provide the DAY of the scan!!'
    goto,fin
 endif
;                                                                                               

;; Prepare output directory for plots and logbook
output_dir = !nika.plot_dir+"/"+day+"_"+strtrim(scan_num,2)
spawn, "mkdir -p "+output_dir

if n_elements(test) lt 1 then test=0
;                                                                                              
;//////////                                
;read data                                                                                
;//////////                                        
nika_pipe_default_param, scan_num, day, param
if keyword_set(polar) then ext_params='c_position c_synchro' else delvarx, ext_params
nika_pipe_getdata, param, data, kidpar, /nocut, ext_params=ext_params, pf=pf

if keyword_set(polar) then begin
   ;; Determine HWP rotation speed
   get_hwp_rot_freq, data, rot_freq_hz
   param.polar.nu_rot_hwp = rot_freq_hz
   ;; Determine angle
   nika_pipe_get_hwp_angle, param, data, kidpar
   ;; Subtract template
   nika_pipe_hwp_rm, param, kidpar, data, fit
endif

;
;Variable Definition
;to fill the kidpar at the end/////////////
final_flag=dblarr(n_elements(kidpar.type))
;//////////////////////////////////////////
f_tone=data.f_tone
df_tone=data.df_tone
w_on1=where(kidpar.type eq 1 and kidpar.array eq 1)
w_on2=where(kidpar.type eq 1 and kidpar.array eq 2)
f_tone1=f_tone[w_on1,*]
df_tone1=df_tone[w_on1,*]
f_tone2=f_tone[w_on2,*]
df_tone2=df_tone[w_on2,*]
;
el=data.el
flag=data.scan_st
;/////////////////////////////////////////////
; cicle on the two channels
voie=[1,2]
for nz=0,1 do begin
   channel=voie(nz)
;
;///////////////////////////////////                                               
;Parameters and variable definitions                                               
;//////////////////////////////////                                                    
   if channel eq 2 then begin
      df_tone=df_tone2
      df_tone=df_tone;*1000.                   
      f_tone=f_tone2;*1000.
      tit='2MM'
      kid=n_elements(f_tone(*,0))
   endif
   if channel eq 1 then begin
      df_tone=df_tone1
      df_tone=df_tone; *1000.                    
      f_tone=f_tone1;*1000.
      tit='1MM'
      kid=n_elements(f_tone(*,0))
   endif
;/////////////////////////////////////////////////////////
; Shift of the Flag Vector for the loss of syncronization                          
   shi=100  ; PLEASE VERIFY THAT A SHIFT = 0 IS OK
   shifted=shift(flag,-shi)
;/////////////////////////////////////////////////////////
   scan_l=where(shifted eq 1)
   scan_s=where(shifted eq 2)
   scan_f=where(shifted eq 3)
   subscan_s=where(shifted eq 4)
   subscan_f=where(shifted eq 5)
   backot=where(shifted eq 6)
   subtun=where(shifted eq 7)
   stun=where(shifted eq 8)
;                                                                                  
   ell=dblarr(n_elements(subscan_s))
;
stop                                                                                  
;////////////////////////////////////                                              
;Creating another flag for bad pixels                                              
   flagkids=dblarr(kid)
   for i=0,kid-1 do begin
      aa=abs(stddev(df_tone(i,*)))
      if aa gt 0 then begin 
         flagkids(i)=0
      endif else begin 
         flagkids(i)=1
         if channel eq 1 then final_flag[w_on1(i)]=0.
         if channel eq 2 then final_flag[w_on2(i)]=0.
      endelse
   endfor
   flagkid=where(flagkids eq 0)
   fl=n_elements(flagkid)
;
;///////////////////////////////////                                               
;Parameters and variable definitions                                               
;//////////////////////////////////                 
;                               
   dft=dblarr(fl,n_elements(subscan_s))
   ft=dblarr(fl,n_elements(subscan_s))
   tau=dblarr(fl)
   K=dblarr(fl)
   fto=dblarr(fl)
;                                                                                  
;                                                                                  
;stop                                                                              
;//////////////////////////////////////////                                        
; Preliminary plot session and average data                                        
;//////////////////////////////////////////                                        
   window,0,title='SKYDIP '+' Date '+day+' Scan Num'+string(scan_num),xsize=1200,ysize=400
   !P.Multi=[0,1,1]
   sample_freq=!nika.f_sampling ; Hz
   time=findgen(n_elements(el))/sample_freq
   time=time/60.
   outplot, file=output_dir+"/skydip_elevation", png=png, ps=ps, /transp
   plot,time,el*180./!pi,thick=2,xtitle='Time (min)',ytitle='Elevation (deg)'
   ac_lines,time(backot(0)),line=0,/vertical ;changed from v1!!!!
   ac_lines,time(scan_f(0)),line=0,/vertical
   for i=0, n_elements(subscan_s)-1 do begin
      ac_lines, time(subscan_s(i)), /vertical, line = 3, col = 70
      ac_lines,time(subscan_f(2*i+1)),/vertical,line=3,col=240
   endfor
   outplot, /close

;   ac_lines,time(subscan_s),/vertical,line=3,col=70
;
   idx=dblarr(n_elements(subscan_s))
   for j=0,fl-1 do begin
      for i=0,n_elements(subscan_s)-1 do begin
;j=10                                                                             
;i=9                                                                               
;     print,subscan_s(i),subscan_f(2*i+1)                                          
;         ac_lines, time(subscan_s(i)), /vertical, line = 3, col = 70
;         ac_lines,time(subscan_f(2*i+1)),/vertical,line=3,col=240
;stop

         ell(i)=mean(el(subscan_s(i):subscan_f(2*i+1)))
         dft(j,i)=mean(df_tone(flagkid(j),subscan_s(i):subscan_f(2*i+1)))
         ft(j,i)=mean(f_tone(flagkid(j),subscan_s(i):subscan_f(2*i+1)))
;                                                                                  
;                                                                                  
         if test eq 1 then begin
            window,4
            !P.multi=[0,2,1]
            plot,reform(df_tone(flagkid(j),subscan_s(i):subscan_f(2*i+1)))
            plot,reform(f_tone(flagkid(j),subscan_s(i):subscan_f(2*i+1)))
            oplot,reform(f_tone(flagkid(j),subscan_s(i):subscan_f(2*i+1))),color=250,thick=5
            wait,1
         endif
;                                                                                  
      endfor
;
;
;////////////                                                                      
;FIT SESSION                                                                       
;///////////                                                                   
      ffrx=-1.*(ft(j,*)+dft(j,*)) ;-ft(j,0))                                
      ffrx=reform(ffrx)           ;-ffrx(0)
      air_mass=1./sin(ell)
;
      if test eq 1 then begin
         window,5
         !P.multi=[0,1,1]
         plot,air_mass,ffrx,/yst
         wait,0.5
      endif
;                                                                                
      taup=0.
      tatm=270.
      p_start=[1.d2,0.5,-1.5d9] ;,1.d5]                                            
      e_r=1.d3                  ;1KHz f tone error
      parinfo = replicate({fixed:0, limited:[1,1], limits:[0.,0.]}, n_elements(p_start))
; 
      parinfo[0].limits=[0,1.d5]
      parinfo[1].limits=[0.,1.]
      parinfo[2].limits=[-1.d10,-1.d9]                                                    
      fito = mpfitfun("tau_model2", air_mass, ffrx, e_r,p_start, /quiet, parinfo=parinfo)
      tau(j)=fito(1)
      K(j)=fito(0)
      fto(j)=fito(2)            ;      
   endfor
;stop
;                                                  
   idx1=where(sqrt((tau-mean(tau))^2) lt 0.7*stddev(tau))
   tau_v=tau(idx1)
   Const=K(idx1)
   f_to=fto(idx1)
;                                                                     
;////////////////////                                                              
;FIT Function                                                              
;////////////////////                                                              
;   !P.multi=[0,1,2]
;stop
   FIT_func=dblarr(n_elements(idx1),n_elements(ffrx))
   for i=0,n_elements(idx1)-1 do FIT_func(i,*)=f_to(i)+Const(i)*Tatm*((1.-exp(-1.*air_mass(*)*tau_v(i))))
;
;Save intermediate results**************************************************************
   ss=string(scan_num)
   ss=strtrim(ss,2)
   if keyword_set(sav) then save,filename='skydip'+day+ss+tit+'.save',air_mass,ft,dft,idx1,fit_func
;***************************************************************************************                  
; SECOND FIT AFTER FIXING TAU                                                    
;tau_fix=!histo.gauss_par(1)
   tau_fix=mean(tau_v)
;                                                                                  
   fi=dblarr(n_elements(const))
   ki=dblarr(n_elements(const))
;                                                                                  
   p_start=[1.d2,tau_fix,-1.d9]
   e_r=1.d3
   parinfo = replicate({fixed:0, limited:[1,1], limits:[0.,0.]}, n_elements(p_start))
;parinfo[1].fixed=1                                                                
   parinfo[0].limits=[0.,1.d5]
   parinfo[1].limits=[tau_fix-tau_fix*0.01,tau_fix+tau_fix*0.01]
   parinfo[2].limits=[-1.d10,0.]
;                                                                                  
   for j=0,n_elements(const)-1 do begin
      fff=f_to(j)+Const(j)*Tatm*((1.-exp(-1.*air_mass(*)*tau_fix)))
      fit1 = mpfitfun("tau_model2", air_mass, fff, e_r,p_start, /quiet ,parinfo=parinfo)
      fi(j)=fit1(2)
      Ki(j)=fit1(0)
      if channel eq 1 then begin 
         kidpar(w_on1(flagkid(idx1(j)))).c0_skydip=fit1(2)
         kidpar(w_on1(flagkid(idx1(j)))).c1_skydip=fit1(0)
      endif
      if channel eq 2 then begin 
         kidpar(w_on2(flagkid(idx1(j)))).c0_skydip=fit1(2)
         kidpar(w_on2(flagkid(idx1(j)))).c1_skydip=fit1(0)
      endif
   endfor
;                                                                                  
   if channel eq 1 then  begin 
      skydip_final1={channel:tit ,scan_number:scan_num , day:day , valid_kid:flagkid(idx1) , par1:fi , par2:ki , par3:tau_fix}
      skydip_res1mm={fit1mm:fit_func , am1mm:air_mass , ft1mm:ft , dft1mm:dft ,idx1mm:idx1 , tau1mm:tau_v}
   endif
; 
   if channel eq 2 then begin
      skydip_final2={channel:tit ,scan_number:scan_num , day:day , valid_kid:flagkid(idx1) , par1:fi , par2:ki , par3:tau_fix}
      skydip_res2mm={fit2mm:fit_func , am2mm:air_mass , ft2mm:ft , dft2mm:dft ,idx2mm:idx1 , tau2mm:tau_v}
   endif
endfor                                                                                 
;    
;////////////////////                                                              
;HISTOGRAM and RESULT                                                              
;////////////////////                                                              
;variables
am1=skydip_res1mm.am1mm
am2=skydip_res2mm.am2mm
;
ft1mm=skydip_res1mm.ft1mm
dft1mm=skydip_res1mm.dft1mm
fit1mm=skydip_res1mm.fit1mm
id1mm=skydip_res1mm.idx1mm
ft2mm=skydip_res2mm.ft2mm
dft2mm=skydip_res2mm.dft2mm
fit2mm=skydip_res2mm.fit2mm
id2mm=skydip_res2mm.idx2mm
;
tau1mm=skydip_res1mm.tau1mm
tau2mm=skydip_res2mm.tau2mm
;

!P.multi=[0,1,2]
;                                                                                  
window,channel,title=' SKYDIP FIT Results',xsize=1200,ysize=400
outplot, file=output_dir+'/skydip_results', png=png, ps=ps, /transp
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
   oplot,am2,ffr-min(ffr),thick=1,col=240
   oplot,am2,fit2mm(i,*)-min(fit2mm(i,*)),line=2,thick=1
endfor
legendastro,['1mm Channel','2mm Channel'],col=[70,250],box=1,line=[0,0],/fill,charsize=0.8,/left,/top
;
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
nika_get_log_info, scan_num, day, data, log_info, kidpar=kidpar
log_info.scan_type = 'skydip'
if keyword_set(polar) then log_info.scan_type = 'skydip_polar'
log_info.result_name[ 0] = 'Tau_1mm'
log_info.result_value[0] = string(dd[1],format='(F5.2)')
log_info.result_name[ 1] = 'Tau_2mm'
log_info.result_value[1] = string(dd[0],format='(F5.2)')

;; Create a html page with plots from this scan
nika_logbook_sub, scan_num, day

fin:
!p.multi=0
end

