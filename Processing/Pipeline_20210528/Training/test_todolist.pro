

;;===================================================================================
;; 1st observation : OTF_geometry to get a picture of all kids, discard unvalid
;; ones and have a starting point to derive the Focal Plane Geometry
scan_num = 222
day      = '20121122'
lambda   = 1
iram_reduce_map, scan_num, day, lambda, /png

scan_num = 222
day      = '20121122'
lambda   = 2
iram_reduce_map, scan_num, day, lambda, /png

;;===================================================================================
;; If beams are too elliptical, if there are too many "doubles", check zigzag
scan_num   = 222
day        = '20121122'
lambda     = 2
ishift_min = -4
ishift_max = 1
noskydip   = 1
png        = 1
zigzag, scan_num, day, lambda, optimal_shift, $
        ishift_min=ishift_min, ishift_max=ishift_max, $
        noskydip=noskydip, png=png

;;===================================================================================
;; Check how matrices superpose to select the reference pixels
.r define_kidpar

;;===================================================================================
;; Now that the reference pixel has been set, derive the focal plane geometry
;; and fit the Nasmyth to (az,el) center of rotation
;; nas_x_ref and nas_y_ref is passed to otf_geometry rather than numdet_ref to
;; allow for a common reference for both matrices
scan_num = 222
day      = '20121122'

nika_pipe_default_param, scan_num, day, param
param.map.size_ra    = 400.d0
param.map.size_dec   = 400.d0
param.map.reso       = 4.d0
param.decor.method   = 'median_simple'
param.decor.iq_plane.apply = 'no'
param.kid_file.a = "kidpar_ref_1mm_temp.fits"
param.kid_file.b = "kidpar_ref_2mm_temp.fits"
param.source     = "Uranus"

;; Common nasmyth pointing reference to both matrices (numdet 414 @2mm)
;; Check with define_kidpar
lambda = 2
output_kidpar_fits_file = "kidpar_ref_2mm.fits"
otf_geometry, scan_num, day, lambda, param, junk, output_kidpar_fits_file, $
              /logbook, /png, /noskydip

;; Center on ref numdet and update .fits file:
numdet_ref = 414
kidpar = mrdfits( output_kidpar_fits_file, 1)
w = where( kidpar.numdet eq numdet_ref)
nas_x_ref = kidpar[w].nas_x
nas_y_ref = kidpar[w].nas_y
print, "nas_x_ref, nas_y_ref: ", nas_x_ref, nas_y_ref
w1 = where( kidpar.type eq 1, nw1)
kidpar[w1].nas_x  = kidpar[w1].nas_x - nas_x_ref
kidpar[w1].nas_y  = kidpar[w1].nas_y - nas_y_ref
nika_write_kidpar, kidpar, output_kidpar_fits_file

;; force nas_x_ref and nas_y_ref to those derived on the 2mm
lambda = 1
output_kidpar_fits_file = "kidpar_ref_1mm.fits"
otf_geometry, scan_num, day, lambda, param, junk, output_kidpar_fits_file, $
              /logbook, /png, /noskydip, nas_x_ref=nas_x_ref, nas_y_ref=nas_y_ref

;; CHECK
kidpar2 = mrdfits( "kidpar_ref_2mm.fits", 1)
kidpar1 = mrdfits( "kidpar_ref_1mm.fits", 1)
w11 = where( kidpar1.type eq 1)
w12 = where( kidpar2.type eq 1)
col_1mm = 70
col_2mm = 250
chars   = 1.2
xoff    = [kidpar1[w11].nas_x, kidpar2[w12].nas_x]
yoff    = [kidpar1[w11].nas_y, kidpar2[w12].nas_y]
xra     = avg(xoff) + [-1,1]*(max(xoff) - min(xoff))*1.1/2.
yra     = avg(yoff) + [-1,1]*(max(yoff) - min(yoff))*1.1/2.
wind, 1, 1, /free, /large
plot,  xra, yra, /iso, /nodata, xtitle='Arcsec', ytitle='Arcsec', /xs, /ys
oplot, kidpar1[w11].nas_x, kidpar1[w11].nas_y, psym=1, col=col_1mm
oplot, kidpar2[w12].nas_x, kidpar2[w12].nas_y, psym=1, col=col_2mm
oplot, [0,0], yra, line=2
oplot, xra, [0,0], line=2
xyouts, kidpar1[w11].nas_x, kidpar1[w11].nas_y, strtrim(kidpar1[w11].numdet,2), chars=chars, col=col_1mm
xyouts, kidpar2[w12].nas_x, kidpar2[w12].nas_y, strtrim(kidpar2[w12].numdet,2), chars=chars, col=col_2mm
legendastro, ['1mm', '2mm'], textcol=[col_1mm, col_2mm], box=0, /right, chars=2


;;===================================================================================
;; Sensitivity + Sanity check: the planet maps should look nice
scan_num   = 222
day        = '20121122'
png        = 1
noskydip   = 1
nika_pipe_default_param, scan_num, day, param
param.map.size_ra    = 400.d0
param.map.size_dec   = 400.d0
param.map.reso       = 4.d0
;param.decor.method   = 'median_simple'
param.decor.method   = 'COMMON_MODE_KIDS_OUT'
param.decor.common_mode.d_min = 20.

param.decor.iq_plane.apply = 'no'
param.kid_file.a = "kidpar_ref_1mm.fits"
param.kid_file.b = "kidpar_ref_2mm.fits"
otf_map, scan_num, day, /logbook, png=png, ps=ps, param=param, noskydip=noskydip


;;===================================================================================
;; Cross
old_common_mode = 0
two_mm_only = 0
one_mm_only = 0
png         = 1

day         = '20121122'
scan_num    = 224

numdet1     = 8 ; ref pixel at 1mm
numdet2     = 414 ; ref pixel at 2mm
force = 1
noskydip = 1
; day to day says : 0.3, 1.4

nika_pipe_default_param, scan_num, day, param
param.map.size_ra    = 100.d0
param.map.size_dec   = 100.d0
param.map.reso       = 5.d0
param.decor.method   = 'COMMON_MODE_KIDS_OUT' ; 'median_simple'
param.decor.common_mode.d_min = 20.
param.decor.iq_plane.apply = 'no'
;param.kid_file.a = "" ; "kidpar_ref_1mm.fits"
;param.kid_file.b = "" ; "kidpar_ref_2mm.fits"

check=1
cross, scan_num, day, numdet1, numdet2, off1, off2, two_mm_only=two_mm_only, png=png, param=param, $
       check=check, tau_force=tau_force, fast=fast, logbook=logbook, old_common_mode=old_common_mode, force=force, noskydip=noskydip


;;===================================================================================
;; Focus
day      = '20121122'
scan_num = 220
numdet1  = 8
numdet2  = 414
; lobook says -1.4, here find -1.4 @1mm, -1.5@2mm

nika_pipe_default_param, scan_num, day, param
;param.kid_file.a = "kidpar_ref_1mm.fits"
;param.kid_file.b = "kidpar_ref_2mm.fits"
focus, day, scan_num, numdet1, numdet2, param=param, /tau_force, /log, /png, /common_mode

;;===================================================================================
;; trying the lissajou cross+focus merge

scan_num_list   = [222, 222, 222] ; to be replaced by the 3 appropriate scans at different focus
day             = '20121122'
debug = 1
png             = 1
noskydip        = 1
nika_pipe_default_param, scan_num_list[0], day, param
param.map.size_ra    = 200.d0
param.map.size_dec   = 200.d0
param.map.reso       = 2.d0
;; Keep otf_map parameters for this scan, just to see the planet
param.decor.method   = 'common_mode_kids_out'
param.decor.common_mode.d_min = 20.
param.decor.iq_plane.apply = 'no'
param.kid_file.a = "kidpar_ref_1mm.fits"
param.kid_file.b = "kidpar_ref_2mm.fits"
ptg_lissajou, scan_num_list, day, debug=debug, png=png, noskydip=noskydip, param=param


;;===================================================================================
;; Skydip
day='20130611'
scan_num=159
;scan_num=23
;/////////////                                                
;
skydip,!nika.run,day,scan_num,skydip_res1,skydip_res2,sav=0;,/test
;
;stop
path = !nika.off_proc_dir
save,filename=path + '/Run'+!nika.run+'_calib_skydip'+day+'.save',skydip_res1,skydip_res2
;
end
