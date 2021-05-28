
;; 1 to 3 : N2R9
;; 4: dedicated pointing session of N2R10
;; 5: all pointings of N2R10
;; 6: first check Oct. 2017, N2R12 (tech time before the 1st science
;; pool)
;; 8: full pointing session : dat file under nika2-b at /home/perotto/NIKA/Plots/N2R14/Pointing
session_number = 8; 7 ; 6 ;1 ; 6 ; 5 ; 3
png  = 1
mail = 0

case 1 of
   session_number eq 1 : begin
      readcol, !home+"/Pointing_session_preview_25Feb2017_N2R9.dat", scan, az, el, p2cor, p7cor, $
               format='D,D,D,D,D', delim=','
      el = el*!dtor
      az = az*!dtor
      nscans = n_elements(scan)
   end

   session_number eq 2 : begin
      readcol, !home+"/Pointing_session_25_Feb_2017.dat", scan, az, el, p2cor, p7cor, $
               format='D,D,D,D,D', delim=','
      el = el*!dtor
      az = az*!dtor
   end

   session_number eq 3 : begin
      scan_list = '20170225s'+strtrim([409,411,413,415,418,420,$
                                       422,424,426,428,430,432,434,436, $
                                       438,440,442,444,446,448,440],2)

      nscans = n_elements(scan_list)
      el    = dblarr(nscans)
      az    = dblarr(nscans)
      p2cor = dblarr(nscans)
      p7cor = dblarr(nscans)
      for iscan=0, nscans-1 do begin
         restore, !nika.plot_dir+"/v_1/"+scan_list[iscan]+"/results.save"
         el[iscan] = info1.elev*!dtor
         az[iscan] = info1.azimuth_deg*!dtor
         restore, !nika.plot_dir+"/Logbook/Scans/"+scan_list[iscan]+"/log_info.save"
         p2cor[iscan] = log_info.result_value[0]
         p7cor[iscan] = log_info.result_value[1]
      endfor

      openw, 1, "Pointing_session_25_Feb_2017_evening.dat"
      printf, 1, "Scan, az, el, p2cor, p7cor"
      for iscan=0, nscans-1 do begin
         printf, 1, scan_list[iscan]+", "+strtrim(az[iscan]*!radeg,2)+", "+$
                 strtrim(el[iscan]*!radeg,2)+", "+strtrim(p2cor[iscan],2)+", "+$
                 strtrim(p7cor[iscan],2)
      endfor
      close, 1
   end
   
   session_number eq 4: begin
      readcol, "pointing_session_n2r10.dat", scan, az, el, p2cor, p7cor, $
               format='A,D,D,D,D', delim=','
      az = az*!dtor
      el = el*!dtor
      nscans = n_elements(Scan)
   end

   session_number eq 5: begin
      readcol, "pointing_list_n2r10.dat", scan, az, el, p2cor, p7cor, $
               format='A,D,D,D,D', delim=','
      az = az*!dtor
      el = el*!dtor
      nscans = n_elements(Scan)
   end

   ;;---------------------------------------------------------
   ;; N2R12, Oct. 2017: 1st mini session to check (daytime...)
   session_number eq 6:begin
;;       ;; Produce the results file
;;       scan_list = '20171021s'+strtrim([176,179,182,183,185,186,187, $
;;                                       188,189,190,191],2)
;; 
;;       nscans = n_elements(scan_list)
;;       el    = dblarr(nscans)
;;       az    = dblarr(nscans)
;;       p2cor = dblarr(nscans)
;;       p7cor = dblarr(nscans)
;;       for iscan=0, nscans-1 do begin
;;          restore, !nika.plot_dir+"/v_1/"+scan_list[iscan]+"/results.save"
;;          el[iscan] = info1.elev*!dtor
;;          az[iscan] = info1.azimuth_deg*!dtor
;;          restore, !nika.plot_dir+"/Logbook/Scans/"+scan_list[iscan]+"/log_info.save"
;;          p2cor[iscan] = log_info.result_value[0]
;;          p7cor[iscan] = log_info.result_value[1]
;;       endfor
;;       openw, 1, "pointing_list_n2r12_1.dat"
;;       printf, 1, "Scan, az, el, p2cor, p7cor"
;;       for iscan=0, nscans-1 do begin
;;          printf, 1, scan_list[iscan]+", "+strtrim(az[iscan]*!radeg,2)+", "+$
;;                  strtrim(el[iscan]*!radeg,2)+", "+strtrim(p2cor[iscan],2)+", "+$
;;                  strtrim(p7cor[iscan],2)
;;       endfor
;;       close, 1
;;       spawn, "cat pointing_list_n2r12_1.dat"
;;       stop

      ;; Read the results file
      readcol, "pointing_list_n2r12_1.dat", scan, az, el, p2cor, p7cor, $
               format='A,D,D,D,D', delim=','
      az = az*!dtor
      el = el*!dtor
      nscans = n_elements(scan)
   end

   session_number eq 7:begin
      ;; Produce the results file
      scan_list = '20171024s'+strtrim([197,201,207,208,214,215,216,$
                                       217,218,219,223,224,225,226,$
                                       228,229,230,231,232],2)
      scan_list = [scan_list, $
                   '20171025s'+strtrim([1,2,3,4,11,12,13,15,16,$
                                        17,21,22,24,25,27,28,30,$
                                        31,33,34,35],2)]
      nscans = n_elements(scan_list)
;;       ncpu_max = 24
;;       optimize_nproc, nscans, ncpu_max, nproc
;;       split_for, 0, nscans-1, nsplit = nproc, $
;;                  commands=['my_nk_rta, i, scan_list'], $
;;                  varnames=['scan_list']

;;       el    = dblarr(nscans)
;;       az    = dblarr(nscans)
;;       p2cor = dblarr(nscans)
;;       p7cor = dblarr(nscans)
;;       for iscan=0, nscans-1 do begin
;;          restore, !nika.plot_dir+"/v_1/"+scan_list[iscan]+"/results.save"
;;          el[iscan] = info1.elev*!dtor
;;          az[iscan] = info1.azimuth_deg*!dtor
;;          restore, !nika.plot_dir+"/Logbook/Scans/"+scan_list[iscan]+"/log_info.save"
;;          p2cor[iscan] = log_info.result_value[0]
;;          p7cor[iscan] = log_info.result_value[1]
;;       endfor
;;       openw, 1, "pointing_list_n2r12_2.dat"
;;       printf, 1, "Scan, az, el, p2cor, p7cor"
;;       for iscan=0, nscans-1 do begin
;;          printf, 1, scan_list[iscan]+", "+strtrim(az[iscan]*!radeg,2)+", "+$
;;                  strtrim(el[iscan]*!radeg,2)+", "+strtrim(p2cor[iscan],2)+", "+$
;;                  strtrim(p7cor[iscan],2)
;;       endfor
;;       close, 1
;      spawn, "cat pointing_list_n2r12_2.dat"
;      stop
      
      ;; Read the results file
      readcol, "pointing_list_n2r12_2.dat", scan, az, el, p2cor, p7cor, $
               format='A,D,D,D,D', delim=','
      az = az*!dtor
      el = el*!dtor
      nscans = n_elements(scan)
   end
   
   session_number eq 8:begin
      ;; Produce the results file
      scan_list = '20171024s'+strtrim([197,201,207,208,214,215,216,$
                                       217,218,219,223,224,225,226,$
                                       228,229,230,231,232],2)
      scan_list = [scan_list, $
                   '20171025s'+strtrim([1,2,3,4,11,12,13,15,16,$
                                        17,21,22,24,25,27,28,30,$
                                        31,33,34,35],2)]
      nscans = n_elements(scan_list)
;;       ncpu_max = 24
;;       optimize_nproc, nscans, ncpu_max, nproc
;;       split_for, 0, nscans-1, nsplit = nproc, $
;;                  commands=['my_nk_rta, i, scan_list'], $
;;                  varnames=['scan_list']

;;       el    = dblarr(nscans)
;;       az    = dblarr(nscans)
;;       p2cor = dblarr(nscans)
;;       p7cor = dblarr(nscans)
;;       for iscan=0, nscans-1 do begin
;;          restore, !nika.plot_dir+"/v_1/"+scan_list[iscan]+"/results.save"
;;          el[iscan] = info1.elev*!dtor
;;          az[iscan] = info1.azimuth_deg*!dtor
;;          restore, !nika.plot_dir+"/Logbook/Scans/"+scan_list[iscan]+"/log_info.save"
;;          p2cor[iscan] = log_info.result_value[0]
;;          p7cor[iscan] = log_info.result_value[1]
;;       endfor
;;       openw, 1, "pointing_list_n2r12_2.dat"
;;       printf, 1, "Scan, az, el, p2cor, p7cor"
;;       for iscan=0, nscans-1 do begin
;;          printf, 1, scan_list[iscan]+", "+strtrim(az[iscan]*!radeg,2)+", "+$
;;                  strtrim(el[iscan]*!radeg,2)+", "+strtrim(p2cor[iscan],2)+", "+$
;;                  strtrim(p7cor[iscan],2)
;;       endfor
;;       close, 1
;      spawn, "cat pointing_list_n2r12_2.dat"
;      stop
      
      ;; Read the results file
      readcol, "pointing_list_n2r14.dat", scan, az, el, p2cor, p7cor, $
               format='A,D,D,D,D', delim=' '
      az = az*!dtor
      el = el*!dtor
      nscans = n_elements(scan)
   end
endcase

;; Fit a Nasmyth pointing offset
cos_el = cos(el)
sin_el = sin(el)
atam1 = dblarr(2,2)
atd = dblarr(2)
atam1[0,0] = 1.d0/nscans
atam1[1,1] = 1.d0/nscans

atd[0] = total( cos_el*p2cor - sin_el*p7cor)
atd[1] = total( sin_el*p2cor + cos_el*p7cor)
s = atam1##atd
print, "session number: ", session_number
print, "If rotation by elevation:"
print, "Nasmyth offset x: ", s[0]
print, "Nasmyth offset y: ", s[1]


x = dindgen(90)*!dtor

fmt = "(F6.2)"
wind, 1, 1, /free, /large
outplot, file='Nasmyth_offsets_session_'+strtrim(session_number,2), png=png, ps=ps
my_multiplot, 2, 2, pp, pp1, /rev, gap_x=0.1, ymargin=0.1
plot, el*!radeg, p2cor, psym=8, xtitle='Elevation (deg)', ytitle='p2cor (arcsec)', $
      position=pp1[0,*]
oplot, x*!radeg, cos(x)*s[0] + sin(x)*s[1], col=250
legendastro, ['Nas. Offset x: '+string(s[0],form=fmt), $
              'Nas. Offset y: '+string(s[1],form=fmt)], textcol=250
plot, el*!radeg, p7cor, psym=8, xtitle='Elevation (deg)', ytitle='p7cor (arcsec)', $
      position=pp1[1,*], /noerase
oplot, x*!radeg, -sin(x)*s[0] + cos(x)*s[1], col=250
legendastro, ['Nas. Offset x: '+string(s[0],form=fmt), $
              'Nas. Offset y: '+string(s[1],form=fmt)], textcol=250

plot, az*!radeg, p2cor, psym=8, xtitle='Azimuth (deg)', ytitle='p2cor (arcsec)', $
      position=pp1[2,*], /noerase
plot, az*!radeg, p7cor, psym=8, xtitle='Azimuth (deg)', ytitle='p7cor (arcsec)', $
      position=pp1[3,*], /noerase
outplot, /close, /verb, mail=mail


;; session number:        1
;; If rotation by Elevation (deg):
;; Nasmyth offset x:       -16.735541
;; Nasmyth offset y:       -2.0422719

;; session number:        2
;; If rotation by Elevation (deg):
;; Nasmyth offset x:       -17.378760
;; Nasmyth offset y:       -4.9228255

;; session number:        3
;; If rotation by Elevation (deg):
;; Nasmyth offset x:       -18.790257
;; Nasmyth offset y:       -4.9724187

end
