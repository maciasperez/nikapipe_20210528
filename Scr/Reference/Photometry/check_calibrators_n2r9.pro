
;; Compare measured fluxes on a list of calibrators to their expected
;; value
;; hacked from Labtools/NP/Dev/redo_secondary_calibrators_n2r4.pro
;;
;; Maps must have been previously reduced.
;;------------------------------------------------------------------------

pro check_calibrators_n2r9, input_dir, flux_type, method, nickname, $
                            png=png, ps=ps, $
                            zl_rmin=zl_rmin, zl_rmax=zl_rmax, $
                            rmeas=rmeas, binwidth=binwidth

run = 'N2R9'

aperture_photometry = 0
case strupcase(flux_type) of
   strupcase('aphot'): begin
      aperture_photometry = 1
      nk_default_param, param
      if keyword_set(zl_rmin)  then param.aperture_photometry_zl_rmin  = zl_rmin
      if keyword_set(zl_rmax)  then param.aperture_photometry_zl_rmax  = zl_rmax
      if keyword_set(rmeas)    then param.aperture_photometry_rmeas    = rmeas
      if keyword_set(binwidth) then param.aperture_photometry_binwidth = binwidth
   end
   strupcase('fixed_fwhm_gauss'): print, 'flux_type: fixed_fwhm_gauss'
   strupcase('free_gauss'): print, 'flux_type: free_gauss'
   else: begin
      message, /info, "You must set flux_type to either 'aphot', 'fixed_fwhm_gauss' or 'free_gauss'"
   end
endcase

if not keyword_set(day_min) then day_min = 0

;; Update with the relevant data base file
db_file = !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R9_v0.save"

;; Demonstration only: replace by the relevant list of sources and
;; their associated fluxes
csv_flux_file = !nika.pipeline_dir+"/Scr/Reference/Photometry/calibrators_fluxes.csv"
readcol, csv_flux_file, $
         source, run_num, date, flux1, flux2, flux3, delim=',', comment='/', $
         format='A,A,A,D,D,D'
;; discard Mars for now because of its multiple entries in the csv file
w = where( strupcase( run_num) eq "RUN09" and $
           strupcase( source) ne "MARS" and $
           strupcase( source) ne "PALLAS" and $
           strupcase( source) ne "LUTETIA" and $
           strupcase( source) ne "CRL618" and $
           strupcase( source) ne "NEPTUNE", nw)
if nw eq 0 then message, "No run09 in "+csv_flux_file
run_num = run_num[w]
date    = date[w]

ref = create_struct( "source", 'a', $
                     "flux1", 0.d0, "flux2", 0.d0, "flux3", 0.d0, $
                     "err_flux1", 0.d0, "err_flux2", 0.d0, "err_flux3", 0.d0)

ref = replicate( ref, nw+1)
ref[0:nw-1].source = source[w]
ref[0:nw-1].flux1 = flux1[w]
ref[0:nw-1].flux2 = flux2[w]
ref[0:nw-1].flux3 = flux3[w]
;; Add Pluto and its unresolved partner Charon (See JFL's email, March 3rd, 2017)
ref[nw].source = "Pluto"
ref[nw].flux1 = 18.07*1e-3
ref[nw].flux2 =  6.34*1e-3
ref[nw].flux3 = 18.58*1e-3

; Take Xavier's value for MWC349
w = where( strupcase(ref.source) eq 'MWC349')
ref[w].flux1 = 2.12
ref[w].flux2 = 1.46
ref[w].flux3 = 2.12

;; Errors on these fluxes (JFL's email, March 12th, 2017)
w = where( strupcase(ref.source) eq "URANUS" or $
           strupcase(ref.source) eq "NEPTUNE" or $
           strupcase(ref.source) eq "PLUTO" or $
           strupcase(ref.source) eq "CERES" or $
           strupcase(ref.source) eq "VESTA", nw)
if nw ne 0 then begin
   ref[w].err_flux1 = 0.05*ref[w].flux1
   ref[w].err_flux2 = 0.05*ref[w].flux2
   ref[w].err_flux3 = 0.05*ref[w].flux3
endif
w = where( strupcase(ref.source) eq "MWC349", nw)
if nw ne 0 then begin
   ref[w].err_flux1 = 0.09*ref[w].flux1
   ref[w].err_flux2 = 0.19*ref[w].flux2
   ref[w].err_flux3 = 0.09*ref[w].flux3
endif
w = where( strupcase(ref.source) eq "CRL2688", nw)
if nw ne 0 then begin
   ref[w].err_flux1 = 0.08*ref[w].flux1
   ref[w].err_flux2 = 0.18*ref[w].flux2
   ref[w].err_flux3 = 0.08*ref[w].flux3
endif
w = where( strupcase(ref.source) eq "NGC7027", nw)
if nw ne 0 then begin
   ref[w].err_flux1 = 0.03*ref[w].flux1
   ref[w].err_flux2 = 0.05*ref[w].flux2
   ref[w].err_flux3 = 0.03*ref[w].flux3
endif

w = where( strupcase(ref.source) eq "CERES", nw)
if nw ne 0 then ref[w].source = "BODY Ceres"
w = where( strupcase(ref.source) eq "VESTA", nw)
if nw ne 0 then ref[w].source = "BODY Vesta"
source_list = ref.source

;; Get results
nsources = n_elements(source_list)
flux     = dblarr(4,nsources)
err_flux = dblarr(4,nsources)
for isource=0, nsources-1 do begin
   source = source_list[isource]
   source_dir = input_dir+"/"+str_replace(source," ", "_")
   message, /info, source_dir+"/MAPS_out_v1.fits"
   nk_fits2grid, source_dir+"/MAPS_out_v1.fits", grid
   nk_grid2info, grid, info, param=param, /educated, $
                 aperture_photometry=aperture_photometry, $
                 title=source, nickname=source, source=source

   case strupcase(flux_type) of
      'APHOT':begin
         flux[    0,isource] = info.result_aperture_photometry_i1
         flux[    1,isource] = info.result_aperture_photometry_i2
         flux[    2,isource] = info.result_aperture_photometry_i3
         flux[    3,isource] = info.result_aperture_photometry_i_1mm
         err_flux[0,isource] = info.result_err_aperture_photometry_i1
         err_flux[1,isource] = info.result_err_aperture_photometry_i2
         err_flux[2,isource] = info.result_err_aperture_photometry_i3
         err_flux[3,isource] = info.result_err_aperture_photometry_i_1mm
      end
      strupcase('fixed_fwhm_gauss'): begin
         flux[0,isource]     = info.result_flux_i1
         flux[1,isource]     = info.result_flux_i2
         flux[2,isource]     = info.result_flux_i3
         flux[3,isource]     = info.result_flux_i_1mm
         err_flux[0,isource] = info.result_err_flux_i1
         err_flux[1,isource] = info.result_err_flux_i2
         err_flux[2,isource] = info.result_err_flux_i3
         err_flux[3,isource] = info.result_err_flux_i_1mm
      end
      strupcase('free_gauss'):begin
         flux[0,isource]     = info.result_peak_1
         flux[1,isource]     = info.result_peak_2
         flux[2,isource]     = info.result_peak_3
         flux[3,isource]     = info.result_peak_1mm
;         err_flux[0,isource] = info.result_err_peak_i1
;         err_flux[1,isource] = info.result_err_peak_i2
;         err_flux[2,isource] = info.result_err_peak_i3
;         err_flux[3,isource] = info.result_err_peak_i_1mm
      end
   endcase
endfor

;; flux summary plot
if keyword_set(ps) eq 0 then wind, 1, 1, /free, /large
outplot, file=input_dir+'/Calibrators_'+strupcase(run)+'_'+nickname+"FluxType_"+strtrim(flux_type,2), png=png, ps=ps
my_multiplot, 2, 2, pp, pp1, /rev, ymargin=0.1, gap_y=0.07, xmargin=0.07, gap_x=0.05
xtickv = dindgen(nsources)/(nsources-1)
xra = [-0.1, 1.1]
xcharsize = 1d-10 ; 0.7
nika_color = [100, 250, 200]
ref_color   = 70
nika_sym    = [4, 1, 1]
ref_sym     = 4
ref_thick   = 1
nika_thick = 2

;; A1 and A3 on the same plot
yra1 = [-1,1]*50                ; max( [reform(flux, n_elements(flux))])*[-1, 1.2]
yra1 = [-1,max(flux)]*1.2
xra = [-0.1, 1.1]
for iarray=1, 3, 2 do begin
   if iarray eq 1 then $
      plot, xtickv, flux[iarray-1,*], $
            /xs, psym=nika_sym[0], ytitle='Flux (Jy)', xtickv=xtickv, xra=xra, yra=yra1, $
            xticks=nsources-1, xtickname=source_list, position=pp[0,0,*], /noerase, $
            xcharsize=xcharsize, title=nickname, /ys, /nodata
   
   oploterror, xtickv, flux[iarray-1,*], err_flux[iarray-1,*], $
               psym=nika_sym[iarray-1], col=nika_color[iarray-1], $
               errcol=nika_color[iarray-1], thick=nika_thick
;   xyouts, xtickv, min(yra1)+0.02*(yra1[1]-yra1[0]), source_list, orient=90, chars=0.6, /data
endfor
oploterror, xtickv, ref.flux1, ref.err_flux1, psym=ref_sym, col=ref_color, thick=ref_thick, symsize=2
legendastro, ['NIKA2 A1', 'NIKA2 A3', 'REF'], box=0, $
             psym=[nika_sym[0], nika_sym[2], ref_sym], col=[nika_color[0],nika_color[2],ref_color], $
             textcol=[nika_color[0],nika_color[2],ref_color]
legendastro, method, box=0, /right
legendastro, flux_type, box=0, /right, /bottom

for iarray=1, 3, 2 do begin
   if iarray eq 1 then $
      plot, xra, [1,1], $
            /xs, ytitle='Ratio to prediction', xra=xra, yra=[0,2], $
            position=pp[1,0,*], /noerase, $
            xcharsize=xcharsize, title=nickname, /ys
   
   oploterror, xtickv, flux[iarray-1,*]/ref.flux1, $
               (ref.flux1*err_flux[iarray-1,*]+flux[iarray-1,*]*ref.err_flux1)/(flux[iarray-1,*]*ref.flux1), $
               psym=nika_sym[iarray-1], col=nika_color[iarray-1], $
               errcol=nika_color[iarray-1], thick=nika_thick
;   xyouts, xtickv, min(yra1)+0.02*(yra1[1]-yra1[0]), source_list, orient=90, chars=0.6, /data
endfor
legendastro, ['NIKA2 A1', 'NIKA2 A3', 'REF'], box=0, $
             psym=[nika_sym[0], nika_sym[2], ref_sym], col=[nika_color[0],nika_color[2],ref_color], $
             textcol=[nika_color[0],nika_color[2],ref_color]
legendastro, method, box=0, /right
legendastro, flux_type, box=0, /right, /bottom

iarray=2
plot, xtickv, flux[iarray-1,*], $
      /xs, psym=nika_sym[0], ytitle='Flux (Jy)', xtickv=xtickv, xra=xra, yra=yra1, $
      xticks=nsources-1, xtickname=source_list, position=pp[0,1,*], /noerase, $
      xcharsize=xcharsize, title=nickname, /ys, /nodata
oploterror, xtickv, flux[iarray-1,*], err_flux[iarray-1,*], $
            psym=nika_sym[iarray-1], col=nika_color[iarray-1], $
            errcol=nika_color[iarray-1], thick=nika_thick
;xyouts, xtickv, min(yra1)+0.02*(yra1[1]-yra1[0]), source_list, orient=90, chars=0.6, /data
oploterror, xtickv, ref.flux2, ref.err_flux2, psym=ref_sym, col=ref_color, thick=ref_thick, symsize=2
legendastro, ['NIKA2 A2', 'REF'], box=0, $
             psym=[nika_sym[1], ref_sym], col=[nika_color[1],ref_color], $
             textcol=[nika_color[1],ref_color]
legendastro, method, box=0, /right
legendastro, flux_type, box=0, /right, /bottom

plot, xra, [1,1], $
      /xs, ytitle='Ratio to prediction', xra=xra, yra=[0,2], $
      position=pp[1,1,*], /noerase, $
      xcharsize=xcharsize, title=nickname, /ys

oploterror, xtickv, flux[iarray-1,*]/ref.flux2, $
            (ref.flux2*err_flux[iarray-1,*]+flux[iarray-1,*]*ref.err_flux2)/(flux[iarray-1,*]*ref.flux2), $
            psym=nika_sym[iarray-1], col=nika_color[iarray-1], $
            errcol=nika_color[iarray-1], thick=nika_thick
;xyouts, xtickv, min(yra1)+0.02*(yra1[1]-yra1[0]), source_list, orient=90, chars=0.6, /data
legendastro, ['NIKA2 A1', 'NIKA2 A3', 'REF'], box=0, $
             psym=[nika_sym[0], nika_sym[2], ref_sym], col=[nika_color[0],nika_color[2],ref_color], $
             textcol=[nika_color[0],nika_color[2],ref_color]
legendastro, method, box=0, /right
legendastro, flux_type, box=0, /right, /bottom
outplot, /close




end
