pro todo_noise, file,  Dir=dir, deltaT = deltaT, select_data = select_data,  amatrix = amatrix, bmatrix = bmatrix
If not keyword_Set(dir) then Dir ='/home/archeops/NIKA/Data/raw_Y33/Y33_2013_06_11/'

Dir_plot = '/home/archeops/NIKA/Plots/Noise/'
dir_plot = dir_plot + file +'/'
spawn, 'mkdir '+ dir_plot



; READING DATA
list_data =  "sample RF_didq  retard 49"
status =   READ_NIKA_BRUTE( dir+file,  param_c,  kidpar,  strdat,  units,  periode,  $
                          list_data = list_data,   read_type =  12,  /silent)
; READ PARAMS
;par1 = mrdfits(dir+file,1,hpar1)
;par2 = mrdfits(dir+file,2,hpar2)

stop

; DO first matrix
; Read DATA 

Nbolo = n_elements(kidpar)
boloname = kidpar.name

; On enleve le primier KID a la main.
if keyword_Set(amatrix) then  listokbolo = where(kidpar.acqbox eq 0 and kidpar.type eq 1,nokbolo)





; Read data as for others



; Define variables

Noisemed = dblarr(nbolo)
noiseint = dblarr(nbolo)
noisemedclean = dblarr(nbolo)
noiseintclean = dblarr(nbolo)
response = dblarr(nbolo)

Bololist = lindgen(nbolo)
;Bololist = listokbolo
Nsmoothh = 5L
nsmoothl = 101L

begidx = 0
endidx = n_elements(datstr)-1

plot, (strdat.rf_didq)[10, begidx:endidx], /xs, /ys

;; Cursor,x1,y
;; Cursor,x2,y
Noisemed =  dblarr(nbolo)
noiseint =  dblarr(nbolo)
noisemedclean =  dblarr(nbolo)
noiseintclean =  dblarr(nbolo)
response =  dblarr(nbolo)

Bololist =  lindgen(nbolo)
;Bololist =
;listokbolo
;                                    
Nsmoothh =  5L
nsmoothl =  101L;

;coor_cursor,  x1, y1
;coor_cursor, x2, y2;

x1 = 0l
x2 = n_elements(strdat.rf_didq)


begidx = long(x1)
endidx = long(x2)



; --- 




if keyword_Set(select_data) then begin
stop
 w = lonarr(nbolo) 
 w[listokbolo] =1 
 for i=0,nokbolo-1 do begin 
  plot, (strdat.rf_didq)[listokbolo[i],*], /xs, /ys
  Dummy = -1
  read,dummy
  w[listokbolo[i]] = dummy
endfor
 listokbolo = where(w eq 1,nokbolo)
endif


;stop
mydata = reform(strdat.rf_didq)
;mydatasml = mydatab
mydatafilt1 = mydata
mydatafilt1bis = mydata
mydatafilt2 = mydata
mydatafilt2bis = mydata
mydatafilt3 = mydata
mydatafilt3bis = mydata
mydatafilt4 = mydata
mydatafilt4bis = mydata


;For ibolo=0, nbolo-1 do mydatasmh[ibolo,*] = smooth(mydata[ibolo,*], Nsmoothh,/edge_truncate)
;for ibolo=0, nbolo-1 do mydatasml[ibolo,*] = smooth(mydata[ibolo,*], nsmoothl,/edge_truncate)

;Mydatafilt =  mydatasmh - mydatasml
ndata = n_elements(mydata[0,*])
Fsampling = 22.0
time = dindgen(ndata)/fsampling
freqlow = 0.001
Freqhigh = 1.0
for ibolo=0, nbolo-1 do mydatafilt1[ibolo,*] = np_bandpass(time, mydata[ibolo,*] ,freqlow,freqhigh);, /force)
Freqlow = 0.0
freqhigh = 1.0
for ibolo=0, nbolo-1 do mydatafilt1bis[ibolo,*] = np_bandpass(time, mydata[ibolo,*] ,freqlow,freqhigh);, /force)
freqlow =  1.0
freqhigh = 2.0
for ibolo=0, nbolo-1 do mydatafilt2[ibolo,*] = np_bandpass(time, mydata[ibolo,*] ,freqlow,freqhigh);, /force)
freqlow = 1.0
freqhigh = 5.0
for ibolo=0, nbolo-1 do mydatafilt2bis[ibolo,*] = np_bandpass(time, mydata[ibolo,*] ,freqlow,freqhigh);, /force)
freqlow =  5.0
freqhigh = 10.0
for ibolo=0, nbolo-1 do mydatafilt3[ibolo,*] = np_bandpass(time, mydata[ibolo,*] ,freqlow,freqhigh);, /force)
freqlow = 5.0
freqhigh = 10.0
for ibolo=0, nbolo-1 do mydatafilt3bis[ibolo,*] = np_bandpass(time, mydata[ibolo,*] ,freqlow,freqhigh);, /force)
freqlow =  10.0
freqhigh = 21.0
For ibolo=0, nbolo-1 do mydatafilt4[ibolo,*] = np_bandpass(time, mydata[ibolo,*] ,freqlow,freqhigh);, /force)
Freqlow = 10.0
freqhigh = 30.0
for ibolo=0, nbolo-1 do mydatafilt4bis[ibolo,*] = np_bandpass(time, mydata[ibolo,*] ,freqlow,freqhigh);, /force)

Mydataclean = mydata

;Power_spec, reform(mydata[0,*]),22.0,pw,fr
;power_spec, reform(mydatasmh[0,*]),22.0,pwsmh,fr
;power_spec, reform(mydatasml[0,*]),22.0,pwsml,fr
;power_spec, reform(mydatafilt[0,*]),22.0,pwfilt,fr

;Filtered_signal=bandpass(time,signal,freqlow,freqhigh)

;Plot, fr, pw, /xs, /ys, /xlog, /ylog 
;oplot, fr, pwsmh, col=2
;oplot, fr, pwsml, col=3
;oplot, fr, pwfilt, col=4, thick=3

stop
;.R
for ibolo=0,nbolo-1 do begin 
;Ibolo = 10

;power_spec, mydatafilt, 22.0, pwcross, fr, cross=ibolo+1
okbol = where(ibolo eq listokbolo,nokbol)

If nokbol gt 0 then begin 
B = where(listokbolo eq ibolo,complement = listcross,ncomplement=ncross)
X = mydatafilt1[listokbolo[listcross],*]
Y = reform( mydatafilt1[ibolo,*],ndata)
Coeff = REGRESS( X, Y,  CHISQ= chi, CONST= const, CORRELATION= corr, /DOUBLE, FTEST=ftest, MCORRELATION=mcorr, SIGMA=sigma, STATUS=status, YFIT=yfit ) 
datafit = y *0.0
X = mydatafilt1bis[listokbolo[listcross],*]
for i=0,ncross-1 do datafit= datafit + coeff[i]*x[i,*]


X = mydatafilt2[listokbolo[listcross],*]
Y = reform( mydatafilt2[ibolo,*],ndata)

Coeff = REGRESS( X, Y,  CHISQ= chi, CONST= const, CORRELATION= corr, /DOUBLE, FTEST=ftest, MCORRELATION=mcorr, SIGMA=sigma, STATUS=status, YFIT=yfit ) 
X = mydatafilt2bis[listokbolo[listcross],*]
for i=0,ncross-1 do datafit = datafit + coeff[i]*x[i,*]

X = mydatafilt3[listokbolo[listcross],*]
Y = reform( mydatafilt3[ibolo,*],ndata)

Coeff = REGRESS( X, Y,  CHISQ= chi, CONST= const, CORRELATION= corr, /DOUBLE, FTEST=ftest, MCORRELATION=mcorr, SIGMA=sigma, STATUS=status, YFIT=yfit ) 
X = mydatafilt3bis[listokbolo[listcross],*]
for i=0,ncross-1 do datafit = datafit + coeff[i]*x[i,*]

X = mydatafilt4[listokbolo[listcross],*]
Y = reform( mydatafilt4[ibolo,*],ndata)

Coeff = REGRESS( X, Y,  CHISQ= chi, CONST= const, CORRELATION= corr, /DOUBLE, FTEST=ftest, MCORRELATION=mcorr, SIGMA=sigma, STATUS=status, YFIT=yfit ) 
X = mydatafilt4bis[listokbolo[listcross],*]
for i=0,ncross-1 do datafit = datafit + coeff[i]*x[i,*]

X = mydata[listokbolo[listcross],*]
Y = reform( mydata[ibolo,*],ndata)

Coeff = REGRESS( X, Y,  CHISQ= chi, CONST= const, CORRELATION= corr, /DOUBLE, FTEST=ftest, MCORRELATION=mcorr, SIGMA=sigma, STATUS=status, YFIT=yfit ) 


Dataraw = reform( mydata[ibolo,*],ndata)
Dataclean = dataraw - datafit

Mydataclean[ibolo,*] = dataclean
;Plot, y, /xs, /ys
;oplot, yfit, col=3
;oplot, dataclean, col=2


Power_spec, dataraw, 23.75, pwdata, fr, logsm=0.01
power_spec, datafit, 23.75, pwdatafit, fr, logsm=0.01
power_spec, dataclean, 23.75, pwdataclean, fr, logsm=0.01

!P.charsize = 1.4

plot, fr, pwdata, /xs, /ys, /ylog,/xlog, thick=2, xtitle='Frequency (Hz)', ytitle='Power', yr=[0.1,10000], xr=[0.01,23.75/2.0], /nodata ,$
      title= strtrim(boloname[ibolo],2)
      
oplot, fr, pwdata, thick=2
oplot, fr, pwdataclean, col=2, thick=2
Oplot, fr, pwdataclean *0.0 + median(pwdataclean),col = 4, thick=3
lfr = where(fr gt 2.0)

noisemedclean[ibolo] = median(pwdataclean[lfr])
noiseintclean[ibolo] = sqrt(int_tabulated(fr,pwdataclean*pwdataclean, /double,/sort))


noisemed[ibolo] = median(pwdata[lfr])
noiseint[ibolo] = sqrt(int_tabulated(fr,pwdata*pwdata, /double,/sort))

;filename = dir_plot + file + '_decorr_'+strtrim(Listokbolo[ibolo],2)+'.jpeg'
filename = dir_plot + file + '_decorr_'+strtrim(boloname[ibolo],2)+'.jpeg'
WRITE_JPEG, filename, TVRD(/TRUE), /TRUE

wait,0.1
endif

endfor
;end

Plotsym, 0, /fill

plot, listokbolo, noisemed, yr=[0,15], /xs, /ys, psym=8, /nodata, xtitle='KID number',ytitle='Median noise ( Hz/sqrt(Hz) )'
oplot, listokbolo, noisemed, psym=8, col=3
oplot, listokbolo, noisemedclean, col=2,psym=8
oplot, listokbolo, noisemedclean *0.0 + median(noisemedclean), col=2
Dir_plot = '/Users/macias/CameraDocuments/NoiseSummaryPlots/'
Filename = dir_plot + file + '_median_noise.jpeg'
WRITE_JPEG, filename, TVRD(/TRUE), /TRUE

stop

Plotsym, 0, /fill

plot, listokbolo,  deltaT/response[listokbolo] , /xs, /ys, psym=8, /nodata, xtitle='KID number',ytitle='Response ( mK / Hz )'
oplot, listokbolo,  deltaT/response[listokbolo],psym=8, col=4 
OPlot, listokbolo, deltaT/response[listokbolo] *0.0 + median(deltaT/response[listokbolo]), col=2
Dir_plot = '/Users/macias/CameraDocuments/NoiseSummaryPlots/'
filename = dir_plot + file + '_response.jpeg'
WRITE_JPEG, filename, TVRD(/TRUE), /TRUE



Plotsym, 0, /fill

plot, listokbolo, noisemedclean[listokbolo]*deltaT/response[listokbolo] , /xs, /ys, psym=8, /nodata, yr=[0,10], $
      xtitle='KID number',ytitle='Response ( mK /sqrt(Hz) )'
oplot, listokbolo, noisemedclean[listokbolo]*deltaT/response[listokbolo], psym=8, col =4
oplot, listokbolo, noisemedclean[listokbolo]*deltaT/response[listokbolo] *0.0 + median(noisemedclean[listokbolo]*deltaT/response[listokbolo]), col=2
Dir_plot = '/Users/macias/CameraDocuments/NoiseSummaryPlots/'
filename = dir_plot + file + '_response_noise.jpeg'
WRITE_JPEG, filename, TVRD(/TRUE), /TRUE


;; Fit entre 0.1 et 2 Hz, coefficients correlations et residu.



return
end

; ================= xxx =====

