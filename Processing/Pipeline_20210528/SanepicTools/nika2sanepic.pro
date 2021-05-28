
pro nika2sanepic, scan_num, day, $
                  kidpar_1mm_fits_file=kidpar_1mm_fits_file, kidpar_2mm_fits_file=kidpar_2mm_fits_file, $
                  sample_min=sample_min, sample_max=sample_max, pf=pf

nika_pipe_default_param, scan_num, day, param
if keyword_set(kidpar_1mm_fits_file) then param.kid_file.a = kidpar_1mm_fits_file
if keyword_set(kidpar_2mm_fits_file) then param.kid_file.b = kidpar_2mm_fits_file

;; Put to SANEPIC format
nika_pipe_getdata, param, data, kidpar, /nocut, ext_params='MJD', pf=pf

;; problem at scan start for Lissajou

;;plot, data.ofs_az
if not keyword_set(sample_min) then sample_min = 0
if not keyword_set(sample_max) then sample_max = n_elements(data)-1
data = data[sample_min:sample_max]

;; Calibrate timelines
nika_pipe_opacity, param, data, kidpar
nika_pipe_calib,   param, data, kidpar

ntime = n_elements(data)
nDet  = n_elements(kidpar)
if keyword_set(pf) then begin
   fileout = "nika_sanepic_"+day+"_"+strtrim(scan_num,2)+"_PF.fits"
endif else begin
   fileout = "nika_sanepic_"+day+"_"+strtrim(scan_num,2)+".fits"
endelse

MESSAGE, "Creating "+fileout, /INFORMATION

;; Creating the primary header (progagated keywords)'
MKHDR,header,'',/EXTEND
SXADDPAR,header,'EQUINOX',   2000,'[yr] Equinox of equatorial coordinates'
SXADDPAR,header,'RESTWAV',   2d-3,'[m] Rest Wavelength'
SXADDPAR,header,'TIMESYS',  'UTC','All dates are in UTC time'
SXADDPAR,header,'CREATOR',  'IDL','Generator of this product'
SXADDPAR,header,'INSTRUME', 'NIKA','Instrument attached to this product'
SXADDPAR,header,'OBJECT',   'Favorite','Target name'
SXADDPAR,header,'TELESCOP', 'IRAM 30m','Name of telescope'
SXADDPAR,header,'OBSERVER', 'Me','Observer name'
WRITEFITS,fileout,0,header

;; Writing signal
MESSAGE, "  Creating signal",/INFORMATION
signal = transpose(data.rf_didq) ; RANDOMU(seed,[nTime,nDet])*1D
 
MKHDR,header,signal,/image,/extend
SXADDPAR,header,'EXTNAME','signal'
SXADDPAR,header,'UNIT','Jy/beam'
SXADDHIST,'Signal for each bolo vs Integration number',header,/COMMENT
SXADDHIST,'NAXIS1 bolometer (corresponding to channel offset table)',header,/COMMENT
SXADDHIST,'NAXIS2 time axis',header,/COMMENT
WRITEFITS,fileout,signal,header,/APPEND

;; Writing Mask
MESSAGE, "  Creating mask", /INFORMATION
mask = transpose( data.flag) ; (RANDOMU(seed,[nTime,nDet]) GT 0.9)*1
 
MKHDR,header,mask,/image,/extend
SXADDPAR,header,'EXTNAME','mask'
SXADDHIST,'Mask for each bolo vs Integration number',header,/COMMENT
SXADDHIST,'NAXIS1 bolometer (corresponding to channel offset table)',header,/COMMENT
SXADDHIST,'NAXIS2 time axis',header,/COMMENT
SXADDHIST,'0 is good, otherwise flagged',header, /COMMENT
WRITEFITS,fileout,mask,header,/APPEND

;; Writing Channel Names corresponding to the signal NAXIS1 axis
FXBHMAKE,header,nDet,"channels"
chan = kidpar.name ; STRARR(nDet)
FXBADDCOL,1,header,chan[0],'name','Channel Name',TUNIT='NONE'
FXBCREATE,unit,fileout,header
FXBWRITM,unit,1,chan
FXBFINISH,unit

;; Writing time
MESSAGE, "  Creating time",/INFORMATION
MJD = data[0].mjd*86400.d0 + dindgen(ntime)/!nika.f_sampling
MKHDR,header,MJD,/image,/extend
SXADDHIST,'MJD time vs Integration number',header,/COMMENT
SXADDPAR,header,'EXTNAME','time'
SXADDPAR,header,'UNIT','s'
WRITEFITS,fileout,MJD,header,/APPEND

; Write Position information, two posibilities (one or the other, or both)
MESSAGE, "  Creating lon/lat array (either equatorial or galactic)",/INFORMATION

ra  = transpose(data.rf_didq)*0.d0
dec = ra*0.d0
for ikid=0, ndet-1 do begin
   if kidpar[ikid].type eq 1 then begin
      nika_nasmyth2draddec, data.ofs_az, data.ofs_el, data.el, data.paral, kidpar[ikid].nas_x, kidpar[ikid].nas_y, $
                            0., 0., dra, ddec, nas_x_ref=kidpar[ikid].nas_center_X, nas_y_ref=kidpar[ikid].nas_center_Y
      ra[ *,ikid] = dra
      dec[*,ikid] = ddec
   endif
endfor

;; convert to degrees
dec_source = ten(51,42,23.3)
RA  = ten(9,18,28.6)*15. + RA/3600.d0
DEC = dec_source + cos(dec_source*!dtor)*DEC/3600.d0

;;RA = RANDOMU(seed,[nTime,nDet])*1D
MKHDR,header,RA,/image,/extend
SXADDPAR,header,'EXTNAME','lon'
SXADDPAR,header,'UNIT','deg'
SXADDHIST,'RA or gal_lon for each bolo vs Integration number',header,/COMMENT
SXADDHIST,'NAXIS1 bolometer (corresponding to channel offset table)',header,/COMMENT
SXADDHIST,'NAXIS2 time axis',header,/COMMENT
WRITEFITS,fileout,RA,header,/APPEND

;;DEC = RANDOMU(seed,[nTime,nDet])*1D
MKHDR,header,DEC,/image,/extend
SXADDPAR,header,'EXTNAME','lat'
SXADDPAR,header,'UNIT','deg'
SXADDHIST,'DEC or gal_lat for each bolo vs Integration number',header,/COMMENT
SXADDHIST,'NAXIS1 bolometer (corresponding to channel offset table)',header,/COMMENT
SXADDHIST,'NAXIS2 time axis',header,/COMMENT
WRITEFITS,fileout,DEC,header,/APPEND

;; MESSAGE, '... AND/OR lon/lat/pos_angle position of a reference pixel and offsets',/INFORMATION
;; 
;; RA   = RANDOMU(seed, nTime)*1D
;; DEC  = RANDOMU(seed, nTime)*1D
;; PHI  = RANDOMU(seed, nTime)*1D
;; 
;; FXBHMAKE,header,ntime,"refPos"
;; FXBADDCOL,1,header,0.D,'lon','Longitude',TUNIT='deg'
;; FXBADDCOL,2,header,0.D,'lat','Latitude', TUNIT='deg'
;; FXBADDCOL,3,header,0.D,'phi','Frame Rotation Angle',TUNIT='deg'
;; FXBCREATE,unit,fileout,header
;; FXBWRITM,unit,[1,2,3],RA,DEC,PHI
;; FXBFINISH,unit

;; ;; channels offets, can be different that the data nDet, must contains
;; ;; all chan in the channels extension
;; ;; for the channels to be indexed
;; chan = STRARR(nDet*2)
;; FOR iChan = 0, nDet*2-1 DO chan[iChan] =  "Nika_"+STRTRIM(STRING(iChan),2)
;; dX  = RANDOMU(seed, nDet*2)*1D
;; dY  = RANDOMU(seed, nDet*2)*1D
;; 
;; FXBHMAKE,header,nDet*2,"offsets"
;; FXBADDCOL,1,header,chan[0],'NAMES','Channel Name',TUNIT='NONE'
;; FXBADDCOL,2,header,0.D,'dX','X offsets',TUNIT='arcsec'
;; FXBADDCOL,3,header,0.D,'dY','Y offsets',TUNIT='arcsec'
;;  
;; FXBCREATE,unit,fileout,header
;; FXBWRITM,unit,1,chan
;; FXBWRITM,unit,2,dX
;; FXBWRITM,unit,3,dY
;; FXBFINISH,unit

end
