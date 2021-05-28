

;;=======================================================================================
;; Define the reference kidpar, check synchronization
;;=======================================================================================
delvarx, param
pf = 0
day      = '20140122'
scan_num = 91
source   = '3C84'

sn_min = 1000
sn_max = 3e4

;; Select pixels and init calibraition, one band at a time
check_sn_range =  0
lambda  = 2
katana, scan_num, day, lambda, source, png=png, in_param=param, pf=pf, check_sn_range=check_sn_range, $
        output_kidpar_fits=kidpar_2mm_infile, sn_min=sn_min, sn_max=sn_max
stop

delvarx, param
lambda  = 1
katana, scan_num, day, lambda, source, png=png, pf=pf, check_sn_range=check_sn_range, $
        output_kidpar_fits=kidpar_1mm_infile, sn_min=sn_min, sn_max=sn_max
stop


;; Overplot both matrices to select the reference detectors
kidpar1 = mrdfits( kidpar_1mm_infile, 1)
kidpar2 = mrdfits( kidpar_2mm_infile, 1)

w11 = where( kidpar1.type eq 1, nw11)
w12 = where( kidpar2.type eq 1, nw12)

col_1mm = 70
col_2mm = 250
chars   = 1.2
xoff    = [kidpar1[w11].nas_x, kidpar2[w12].nas_x]
yoff    = [kidpar1[w11].nas_y, kidpar2[w12].nas_y]
xra     = avg(xoff) + [-1,1]*(max(xoff) - min(xoff))*1.1/2.
yra     = avg(yoff) + [-1,1]*(max(yoff) - min(yoff))*1.1/2.

charsize = 1
wind, 1, 1, /free, /large
plot,  xra, yra, /iso, /nodata, xtitle='Arcsec', ytitle='Arcsec', /xs, /ys, charsize=charsize
oplot, kidpar1[w11].nas_x, kidpar1[w11].nas_y, psym=1, col=col_1mm
oplot, kidpar2[w12].nas_x, kidpar2[w12].nas_y, psym=1, col=col_2mm
oplot, [0,0], yra, line=2
oplot, xra, [0,0], line=2
xyouts, kidpar1[w11].nas_x, kidpar1[w11].nas_y, strtrim(kidpar1[w11].numdet,2), chars=chars, col=col_1mm
xyouts, kidpar2[w12].nas_x, kidpar2[w12].nas_y, strtrim(kidpar2[w12].numdet,2), chars=chars, col=col_2mm
legendastro, ['1mm', '2mm'], col=[col_1mm, col_2mm], line=0, box=0, /right
legendastro, file_basename( [kidpar_1mm_infile,kidpar_2mm_infile]), box=0

;; Choose the reference detectors among valid ones, close to the center
;; and if possible with the 1mm ref kid close to the 2mm ref kid
;; For Uranus 231, this could be 491
;;ptg_numdet_ref = 491 ; 420 (if numdet and Run6 choice, 414 to match raw_num and debugging on run5)

;; Finalize the offsets and rotation parameter estimation
;; Center on ref pixel
ptg_numdet_ref = 494
nika_pipe_default_param, scan_num, day, param

param.kid_file.a  = kidpar_1mm_infile
param.kid_file.b  = kidpar_2mm_infile
nickname = "kidpar_ref_run7_"+day+"s"+strtrim(scan_num,2)
get_geometry, param, nickname, ptg_numdet_ref=ptg_numdet_ref

;; Plot to print
kidpar1 = mrdfits( "kidpar_ref_run7_"+day+"s"+strtrim(scan_num,2)+"_1mm.fits", 1)
kidpar2 = mrdfits( "kidpar_ref_run7_"+day+"s"+strtrim(scan_num,2)+"_2mm.fits", 1)

w11 = where( kidpar1.type eq 1, nw11)
w12 = where( kidpar2.type eq 1, nw12)

col_1mm = 70
col_2mm = 250
chars   = 1.2
xoff    = [kidpar1[w11].nas_x, kidpar2[w12].nas_x]
yoff    = [kidpar1[w11].nas_y, kidpar2[w12].nas_y]
xra     = avg(xoff) + [-1,1]*(max(xoff) - min(xoff))*1.1/2.
yra     = avg(yoff) + [-1,1]*(max(yoff) - min(yoff))*1.1/2.

charsize = 1
wind, 1, 1, /free, /large
plot,  xra, yra, /iso, /nodata, xtitle='Arcsec', ytitle='Arcsec', /xs, /ys, charsize=charsize
oplot, kidpar1[w11].nas_x, kidpar1[w11].nas_y, psym=1, col=col_1mm
oplot, kidpar2[w12].nas_x, kidpar2[w12].nas_y, psym=1, col=col_2mm
oplot, [0,0], yra, line=2
oplot, xra, [0,0], line=2
xyouts, kidpar1[w11].nas_x, kidpar1[w11].nas_y, strtrim(kidpar1[w11].numdet,2), chars=chars, col=col_1mm
xyouts, kidpar2[w12].nas_x, kidpar2[w12].nas_y, strtrim(kidpar2[w12].numdet,2), chars=chars, col=col_2mm
legendastro, ['1mm', '2mm'], col=[col_1mm, col_2mm], line=0, box=0, /right
legendastro, file_basename( [kidpar_1mm_infile,kidpar_2mm_infile]), box=0










;; 1. If happy, then move these new .fits files as reference kidpars in
;; !nika.off_proc_dir and update get_kidpar_ref.pro accordingly.
;; 2. update grid_step in nika_init_structure
;; 3. update !nika.numdet_ref_1mm and 2mm in get_kidpar_ref

;;=========================================================================
;; Edit run_pointing.pro and play

;; Edit run_focus.pro and play

;; Edit run_skydip and play

;; Edit run_otf_map and play

;; Edit run_otf_geometry and play

;; Edit run_focus_liss.pro and play




;; When a skydip is available and kidpar.c0_skydip and kidpar.c1_skydip have
;; been computed, overwrite the reference kidpar in !nika.off_proc_dir.


end
