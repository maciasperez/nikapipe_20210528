;; 04/01/2017: Copie du script eponyme dans Labtools/NP/Dev/


;scan = '20161209s239'
;scan = '20161210s312'
scan = '20170124s186'
scan = '20170125s223'

ptg_numdet_ref = 823
source = "Uranus"
beam_maps_dir = "$HOME/NIKA/Plots/Run20/Beammaps_run21"

skydip_id = '20170124s189'
;;skydip_id = '20170125s248'
;;nk_rta, skydip_id

prepare   = 1
beams     = 1
merge     = 1
select    = 1
finalize  = 1
iteration = 2
if iteration eq 1 then begin
   delvarx, input_kidpar_file
endif else begin
   if scan eq '20170124s186' then input_kidpar_file = "kidpar_20170124s186_v0_withskydip.fits"
   if scan eq '20170125s223' then input_kidpar_file = "kidpar_20170125s223_v0_withskydip.fits"
   if scan eq '20170125s223' then input_kidpar_file = "kidpar_20170125s223_v0_withskydip_"+skydip_id+".fits"
endelse
make_geometry_5, scan, ptg_numdet_ref=ptg_numdet_ref, iteration=iteration, $
                 source=source, beam_maps_dir=beam_maps_dir, input_kidpar_file=input_kidpar_file, $
                 prepare=prepare, beams=beams, merge=merge, select=select, finalize=finalize

;;stop

if iteration eq 1 then begin
;; Compare to the kidpar of the previous run to check if everything
;; has changed
   kidpar_ref_file = !nika.off_proc_dir+"/kidpar_20161010s37_v3_skd8_match_calib_NP_recal_FR.fits"
   kidpar_file     = "kidpar_"+scan+"_v0.fits"

   ;;lp_compare_kidpars, [kidpar_ref_file, kidpar_file]

   
   kidpar_ref = mrdfits( kidpar_ref_file, 1)
   kidpar     = mrdfits( kidpar_file, 1)


   ;; FLag out outlyers
   ;; w1ref = where( kidpar_ref.type eq 1, nw1ref)
;;    w1    = where( kidpar.type eq 1, nw1)
;;    kidpar = kidpar[w1]
;;    kidpar_ref = kidpar_ref[w1ref]
;;    my_match, kidpar_ref.numdet, kidpar.numdet, suba, subb
;;    kidpar_ref = kidpar_ref[suba]
;;    kidpar     = kidpar[subb]
   
;; ; print, minmax(kidpar_ref.numdet-kidpar.numdet)
;;    kid_dist = sqrt( (kidpar_ref.nas_x-kidpar.nas_x)^2 + $
;;                     (kidpar_ref.nas_y-kidpar.nas_y)^2)
   ;;wind, 1, 1, /free
   ;;plot, kid_dist
   
   ;; flagging
   ;;w = where( kid_dist gt 3, nw)
   ;;if nw ne 0 then kidpar[w].type = 4
   
;; Add skydip coeffs

   ;; 1/ using co, c1 from a recent skydip

   ;; nk_default_param, param
   ;; nk_default_info, info
   ;; scan2daynum, skydip_id, day, scan_num
   ;; param.plot_dir = !nika.plot_dir+"/Logbook/Scans/"+skydip_id
   ;; in_kidpar_file = "kidpar_20170125s223_v0.fits"
   ;; nk_skydip_4, scan_num, day, param, info, kidpar, data, dred, input_kidpar_file = in_kidpar_file, raw_acq_dir=raw_acq_dir
   ;; nk_write_kidpar, kidpar, "kidpar_"+skydip_id+".fits"
     
   ;;restore, '/home/perotto/NIKA/Plots/Run20/v_1/'+skydip_id+'/results.save', /v
   kidpar1 = mrdfits("kidpar_"+skydip_id+".fits", 1)
   w1sd = where( kidpar1.type eq 1, nw1ref)
   w1    = where( kidpar.type eq 1, nw1)
   kidpar = kidpar[w1]
   kidpar1 = kidpar1[w1sd]
   my_match, kidpar1.numdet, kidpar.numdet, suba, subb
   kidpar.c0_skydip = 0.d0
   kidpar.c1_skydip = 0.d0
   kidpar[subb].c0_skydip = kidpar1[suba].c0_skydip
   kidpar[subb].c1_skydip = kidpar1[suba].c1_skydip
;;
;; nk_write_kidpar, kidpar, "kidpar_"+scan+"_v0_withskydip_"+skydip_id+".fits"
   
   ;; 2/ using former coeff
   ;; w1ref = where( kidpar_ref.type eq 1, nw1ref)
   ;; w1    = where( kidpar.type eq 1, nw1)
   ;; kidpar = kidpar[w1]
   ;; kidpar_ref = kidpar_ref[w1ref]
   ;; my_match, kidpar_ref.numdet, kidpar.numdet, suba, subb
   ;; kidpar.c0_skydip = 0.d0
   ;; kidpar.c1_skydip = 0.d0
   ;; kidpar[subb].c0_skydip = kidpar_ref[suba].c0_skydip
   ;; kidpar[subb].c1_skydip = kidpar_ref[suba].c1_skydip

   
;;
;; nk_write_kidpar, kidpar, "kidpar_"+scan+"_v0_withskydip.fits"

   stop
;; all done for iteration 1
;;______________________________________________________________________
endif else begin
   
   
   
;;______________________________________________________________________
;;   
;; Calibration and flat fields
;;
   ;; comparing calib_fix_fwhm and calib
   kidpar = mrdfits( "kidpar_"+scan+"_v2.fits", 1)
   w1 = where( kidpar.type eq 1, nw1)
   iref = 100
   wind, 1, 1, /free, /large
   !p.multi=[0,1,3]
;;.r 
   for iarray=1, 3 do begin
      w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1)
      plot,  kidpar[w1].calib_fix_fwhm/median(kidpar[w1].calib_fix_fwhm), /xs, /nodata, ytitle="normalised calib coef A"+strtrim(string(iarray), 2), charsize=2
      oplot,  kidpar[w1].calib_fix_fwhm/median(kidpar[w1].calib_fix_fwhm), col=70
      oplot, kidpar[w1].calib/median(kidpar[w1].calib), col=250
      if iarray eq 1 then legendastro, ['calib_fix_fwhm', 'calib'], line=0, col=[70, 250], box=0, /trad
   endfor
;;end
   !p.multi=0
   stop
   ;;png = +'/home/perotto/NIKA/Plots/Run20/calib_to_calib_fix_fwhm_'+strtrim(scan,2)+'.png'
   ;;WRITE_PNG, png, TVRD(/TRUE)
   

   ;; calculate corr2cm and plot the flats
   ;;check_flatfields, scan, beam_maps_dir+"/kidpar_"+scan+"_v2.fits"
   check_flatfields, scan, "/home/perotto/NIKA/Plots/Run20/kidpar_"+scan+"_v2.fits"
   
   
   
   
   
   stop

;;______________________________________________________________________________
;;
;; Check which of (az,el) or Nasmyth offsets are the most distorted to
;; track down bug in coordinate conversion to match RZ's accuracy
iarray = 1
w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1)
kidpar1 = kidpar[w1]

;;***** Nasmyth
;; take a kid close to the center as origin
d = kidpar1.nas_x^2 + kidpar1.nas_y^2
w = (where( d eq min(d)))[0]
kidpar1.nas_x -= kidpar1[w].nas_x
kidpar1.nas_y -= kidpar1[w].nas_y

;; !nika.grid_step = [9.3, 11.1, 9.7] ; see Nika2Run1/check_grid_step + Xavier's email of Dec. 29th, 2015
; step = !nika.grid_step[iarray-1]
; step = 13.5 ; 14.
step = 9.7
;; alpha = (90.d0-76.2-1.75)*!dtor
alpha = (90.d0-76.2)*!dtor
if iarray eq 2 then alpha = (90.d0-77.7)*!dtor ; xavier
x =  cos(alpha)*kidpar1.nas_x + sin(alpha)*kidpar1.nas_y
y = -sin(alpha)*kidpar1.nas_x + cos(alpha)*kidpar1.nas_y

;;***** AzEl
d = kidpar1.x_peak_azel^2 + kidpar1.y_peak_azel^2
w = (where( d eq min(d)))[0]
kidpar1.x_peak_azel -= kidpar1[w].x_peak_azel
kidpar1.y_peak_azel -= kidpar1[w].y_peak_azel

;; !nika.grid_step = [9.3, 11.1, 9.7] ; see Nika2Run1/check_grid_step + Xavier's email of Dec. 29th, 2015
; step = !nika.grid_step[iarray-1]
; step = 13.5 ; 14.
step = 9.7
;; alpha = (90.d0-76.2-1.75)*!dtor
alpha = -20*!dtor
if iarray eq 2 then alpha = (90.d0-77.7)*!dtor ; xavier
x =  cos(alpha)*kidpar1.x_peak_azel + sin(alpha)*kidpar1.y_peak_azel
y = -sin(alpha)*kidpar1.x_peak_azel + cos(alpha)*kidpar1.y_peak_azel


xra = minmax(x/step)
yra = minmax(y/step)

xra = [-1,1]*20
yra = [-1,1]*20

wind, 1, 1, /free
plot, x/step, y/step, psym=1, /iso, xra=xra, yra=yra, /xs, /ys, title=strtrim(step,2)
for i=min(floor(x/step)), max( round(x/step)) do oplot, [1,1]*i, yra
for i=min(floor(y/step)), max( round(y/step)) do oplot, xra, [1,1]*i
oplot, x/step, y/step, psym=1, thick=2

w = where( abs(x/step) lt 10 and abs(y/step) lt 10, nw)
nsteps = 20
step_list = 9. + dindgen(nsteps)/(nsteps-1)*2
dist_list = step_list*0.d0
for istep=0, nsteps-1 do begin
   step = step_list[istep]
   x_int = round(x/step)
   y_int = round(y/step)

   plot, x/step, y/step, psym=1, /iso, xra=xra, yra=yra, /xs, /ys, title=strtrim(step,2)
   for i=min(floor(x/step)), max( round(x/step)) do oplot, [1,1]*i, yra
   for i=min(floor(y/step)), max( round(y/step)) do oplot, xra, [1,1]*i
   oplot, x_int, y_int, col=250, psym=8
   oplot, x/step, y/step, psym=1, thick=2

   d = sqrt( (x/step-x_int)^2 + (y/step-y_int)^2)
   dist_list[istep] = total( d[w])
endfor

wind, 2, 2, /free
plot, step_list, dist_list, psym=-1

xra = [-1,1]*20
yra = [-1,1]*20
step = 9.85
;; min(dist_list): 70.3312
wind, 1, 1, /free
plot, x/step, y/step, psym=1, /iso, xra=xra, yra=yra, /xs, /ys, title=strtrim(step,2)
for i=min(floor(x/step)), max( round(x/step)) do oplot, [1,1]*i, yra
for i=min(floor(y/step)), max( round(y/step)) do oplot, xra, [1,1]*i
oplot, x/step, y/step, psym=1, thick=2
   


endelse




end
