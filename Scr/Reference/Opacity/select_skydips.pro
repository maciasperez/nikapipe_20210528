;+
;   AIM: Applying cuts to select skydip scans
;
;   INPUT:
;   skdout : result structure from the multi-skydip scan fit
;   kidpar

;   OUTPUT:
;   list of scans that do not meet the selection criteria in a form of
;   a blacklist file written in "Datamanage" directory 
;
;   LP, April 2018
;---------------------------------------------------------------------------
pro select_skydips, skdout, kidpar, blacklist_file, dtcut=dtcut, rmscut=rmscut, tau3cut=tau3cut, $
                    plotdir = plotdir, plotname=plotname, png=png, ps=ps, pdf=pdf, $
                    blacklist_to_update=blacklist_to_update, $
                    dec2018=dec2018, selected_skydip_list=selected_skydip_list
  
  
  scan_list = skdout.scanname 
  nsc       = n_elements(scan_list)  
  
  
  ;; TEST OF SKDOUT
  if keyword_set(dtcut) and tag_exist(skdout, 'dt')  lt 1  then begin
     print, "No C0 offsets to fit found in skdout"
     stop
  endif
  if keyword_set(rmscut) and tag_exist(skdout, 'rmsa1')  lt 1  then begin
     print, "No data-to-fit scatters found in skdout"
     stop
  endif
  
  if keyword_set(plotdir) then dir=plotdir else dir = !nika.plot_dir
  if keyword_set(plotname) then fname = plotname else fname=''
  if keyword_set(blacklist_to_update) then fname=fname+'_updated'
  
  dt_max   = [10., 10.]
  rms_max  = [10., 10.]
  tau3_max = 3.
  if keyword_set(dtcut) then dt_max = dtcut
  if keyword_set(rmscut) then rms_max = rmscut
  if keyword_set(tau3cut) then tau3_max = tau3cut
  

  plot_color_convention, col_a1, col_a2, col_a3, $
                         col_mwc349, col_crl2688, col_ngc7027, $
                         col_n2r9, col_n2r12, col_n2r14, col_1mm
  
  wind, 1, 1, /free,xsize=1300, ysize=550 
  outfile = dir+'/plot_allskd4_'+fname+'_fitcal'
  outplot, file=outfile, png=png
  my_multiplot, 2, 1, pp, pp1, /rev, gap_y=0.02, gap_x=0.07, xmargin=0.1, ymargin=0.1 ; 1e-6
  
  scanname = skdout.scanname
  
  wtau = where(skdout.taufinal3 gt tau3_max, ntau)
  textcol = intarr(nsc)
  if ntau gt 0 then textcol[wtau] = 250
  ns_max1 = min([nsc, 28])
  ns_max2 = nsc-ns_max1
  
  index = indgen(nsc)
  
  
  if tag_exist(skdout, 'rmsa1') then begin
     plot, skdout.rmsa1, index, yrange = [-1, nsc], xsty = 0, /nodata, $
           xrange = [0, max([skdout.rmsa1, skdout.rmsa2, skdout.rmsa3])*2], ysty = 0, $
           title = 'Skydip dispersion', $
           thick = 2, xtitle = 'Median rms [Hz]', ytitle = 'Scan number', $
           pos=pp1[0, *], noerase=0
     for i =0, nsc-1 do if (i mod 10 eq 0) then oplot, [0, max([skdout.rmsa1, skdout.rmsa2, skdout.rmsa3])], [i,i]
     
     legendastro, reverse( zeropadd( index[0:ns_max1-1], 2)+': '+ $
                           strtrim(string(scanname[0:ns_max1-1]), 2)+' ; tau3='+ $
                           string( skdout[0:ns_max1-1].taufinal3, '(1F6.2)')), $
                  box = 0, /bottom, /right, charsize=0.6, textcol=reverse( textcol[0:ns_max1-1])
     oplot, psym = -8, color = col_a1, skdout.rmsa1, index
     oplot, psym = -8, color = col_a3, skdout.rmsa3, index
     oplot, psym = -8, color = col_a2,  skdout.rmsa2, index
     oplot, rms_max*[1.,1.], [-1, nsc], col=250, thick=2
  endif
  
; Plot Deltac0 per scan
  if tag_exist(skdout, 'dt') then begin
     dtall = fltarr(3, nsc)
     dtarr = skdout.dt
     for narr = 1, 3 do begin   ; loop on arrays
        kidall = where( kidpar.type eq 1 and $
                        kidpar.array eq narr, nallkid)       
        
        ;; NP, dec. 2018: add constrain on c0_skydip in kidall def ?!
        ;; TBC !!!
        if keyword_set(dec2018) then $
           kidall = where( kidpar.c0_skydip ne 0 and kidpar.type eq 1 and $
                           kidpar.array eq narr, nallkid)       
        
        for isc = 0, nsc-1 do begin ; Median function does not exclude Nans
           
           u = where( finite( dtarr[ kidall, isc]) eq 1, nu)
           
           ;; NP, dec. 2018: add constrain on c0_skydip in kidall def ?!
           ;; TBC !!!
           if keyword_set(dec2018) then $
              u = where( finite( dtarr[ kidall, isc]) and dtarr[kidall,isc] ne 0, nu)
           
            if nu gt 3 then dtall[narr-1, isc]= $
               median(/double, dtarr[ kidall[ u], isc])
         endfor
     endfor
     
     plot, dtall[ 0, *], index, yrange = [-1, nsc], xsty = 0, /nodata, $
           xrange = [min(dtall), max([min([max(dtall)*2, 60.]), 2.])], ysty = 0, $
           title = 'Skydip offset', $
           thick = 2, xtitle = 'Median dT [K]', ytitle = 'Scan number', pos=pp1[1, *], noerase=1
     for i =0, nsc-1 do if (i mod 10 eq 0) then oplot, [min(dtall), max(dtall)], [i,i]
     
     if ns_max2 gt 0 then $
        legendastro, reverse( zeropadd( index[ns_max1:ns_max1+ns_max2-1], 2)+': '+ $
                              strtrim(string(scanname[ns_max1:ns_max1+ns_max2-1]),2)+' ; tau3='+ $
                              string( skdout[ns_max1:ns_max1+ns_max2-1].taufinal3, '(1F6.2)')), $
                     box = 0, /bottom, /right, charsize=0.6, textcol=reverse(textcol[ns_max1:ns_max1+ns_max2-1])
     
     legendastro, psym = [8, 8, 8], ['Arr1', 'Arr3', 'Arr2'], $
                  colors = [col_a1, col_a3, col_a2], /top, /right
     oplot, psym = -8, color = col_a1, dtall[0, *], indgen(nsc)
     oplot, psym = -8, color = col_a3, dtall[2, *], indgen(nsc)
     oplot, psym = -8, color = col_a2,  dtall[1, *], indgen(nsc)
     oplot, psym = -3, [0, 0], !y.crange, thick = 2
     oplot, psym = -3, dt_max[0]*[1., 1.],   [-1, nsc], col = 250, thick = 2
     oplot, psym = -3, dt_max[0]*[-1., -1.], [-1, nsc], col = 250, thick = 2
     oplot, psym = -3, dt_max[1]*[1., 1.],   [-1, nsc], col = 250, thick = 2, linestyle=2
     oplot, psym = -3, dt_max[1]*[-1., -1.], [-1, nsc], col = 250, thick = 2, linestyle=2
;;stop      
  endif
  !p.multi=0
  outplot, /close
  
  ;; repeat to save an eps plot
  if keyword_set(ps) or keyword_set(pdf) then begin
     
     outplot, file=outfile, ps=ps, xsize=20., ysize=14., charsize=1.0, thick=3.0, charthick=3.0
     my_multiplot, 2, 1, pp, pp1, /rev, gap_y=0.02, gap_x=0.07, xmargin=0.1, ymargin=0.1 ; 1e-6
   
     scanname = skdout.scanname
     
     wtau = where(skdout.taufinal3 gt tau3_max, ntau)
     textcol = intarr(nsc)
     if ntau gt 0 then textcol[wtau] = 250
     ns_max1 = min([nsc, 28])
     ns_max2 = nsc-ns_max1
     
     index = indgen(nsc)
     
     
     if tag_exist(skdout, 'rmsa1') then begin
        plot, skdout.rmsa1, index, yrange = [-1, nsc], xsty = 0, /nodata, $
              xrange = [0, max([skdout.rmsa1, skdout.rmsa2, skdout.rmsa3])*2], ysty = 0, $
              title = 'Skydip dispersion', $
              thick = 2, xtitle = 'Median rms [Hz]', ytitle = 'Scan number', $
              pos=pp1[0, *], noerase=0
        for i =0, nsc-1 do if (i mod 10 eq 0) then oplot, [0, max([skdout.rmsa1, skdout.rmsa2, skdout.rmsa3])], [i,i]
        
        legendastro, reverse( zeropadd( index[0:ns_max1-1], 2)+': '+ $
                              strtrim(string(scanname[0:ns_max1-1]), 2)+' ; tau3='+ $
                              string( skdout[0:ns_max1-1].taufinal3, '(1F6.2)')), $
                     box = 0, /bottom, /right, charsize=0.6, textcol=reverse( textcol[0:ns_max1-1])
        oplot, psym = -8, color = col_a1, skdout.rmsa1, index
        oplot, psym = -8, color = col_a3, skdout.rmsa3, index
        oplot, psym = -8, color = col_a2, skdout.rmsa2, index
        oplot, rms_max*[1.,1.], [-1, nsc], col=240, thick=2, linestyle=2
     endif
     
; Plot Deltac0 per scan
     if tag_exist(skdout, 'dt') then begin
      dtall = fltarr(3, nsc)
      dtarr = skdout.dt
      for narr = 1, 3 do begin  ; loop on arrays
         kidall = where( kidpar.type eq 1 and $
                         kidpar.array eq narr, nallkid)       

         ;; NP, dec. 2018: add constrain on c0_skydip in kidall def ?!
         ;; TBC !!!
         if keyword_set(dec2018) then $
            kidall = where( kidpar.c0_skydip ne 0 and kidpar.type eq 1 and $
                            kidpar.array eq narr, nallkid)       
         
         for isc = 0, nsc-1 do begin ; Median function does not exclude Nans

           u = where( finite( dtarr[ kidall, isc]) eq 1, nu)

            ;; NP, dec. 2018: add constrain on c0_skydip in kidall def ?!
            ;; TBC !!!
            if keyword_set(dec2018) then $
               u = where( finite( dtarr[ kidall, isc]) and dtarr[kidall,isc] ne 0, nu)

            if nu gt 3 then dtall[narr-1, isc]= $
               median(/double, dtarr[ kidall[ u], isc])
         endfor
      endfor
      
      plot, dtall[ 0, *], index, yrange = [-1, nsc], xsty = 0, /nodata, $
            xrange = [min(dtall), max([min([max(dtall)*2, 60.]), 2.])], ysty = 0, $
            title = 'Skydip offset', $
            thick = 2, xtitle = 'Median dT [K]', ytitle = 'Scan number', pos=pp1[1, *], noerase=1
      for i =0, nsc-1 do if (i mod 10 eq 0) then oplot, [min(dtall), max(dtall)], [i,i]

      if ns_max2 gt 0 then $
         legendastro, reverse( zeropadd( index[ns_max1:ns_max1+ns_max2-1], 2)+': '+ $
                               strtrim(string(scanname[ns_max1:ns_max1+ns_max2-1]),2)+' ; tau3='+ $
                               string( skdout[ns_max1:ns_max1+ns_max2-1].taufinal3, '(1F6.2)')), $
                      box = 0, /bottom, /right, charsize=0.6, textcol=reverse(textcol[ns_max1:ns_max1+ns_max2-1])
       
      legendastro, psym = [8, 8, 8], ['Arr1', 'Arr3', 'Arr2'], $
                   colors = [col_a1, col_a3, col_a2], /top, /right
      oplot, psym = -8, color = col_a1, dtall[0, *], indgen(nsc)
      oplot, psym = -8, color = col_a3, dtall[2, *], indgen(nsc)
      oplot, psym = -8, color = col_a2,  dtall[1, *], indgen(nsc)
      oplot, psym = -3, [0, 0], !y.crange, thick = 2
      oplot, psym = -3, dt_max[0]*[1., 1.],   [-1, nsc], col = 240, thick = 2, linestyle=2
      oplot, psym = -3, dt_max[0]*[-1., -1.], [-1, nsc], col = 240, thick = 2, linestyle=2
      oplot, psym = -3, dt_max[1]*[1., 1.],   [-1, nsc], col = 240, thick = 2, linestyle=3
      oplot, psym = -3, dt_max[1]*[-1., -1.], [-1, nsc], col = 240, thick = 2, linestyle=3
;;stop      
   endif
   !p.multi=0
   outplot, /close
   if keyword_set(pdf) then my_epstopdf_converter, outfile

     ;; restore plot aspect
     loadct, 39
     !p.thick = 1.0
     !p.charsize  = 1.0
     !p.charthick = 1.0
     
      
   endif
   message, /info, 'Diagnosis for scan selection (dtall , rms) for A1,A2,A3'
  for i = 0, nsc-1 do $
     print, 'index ', i, ', scan = ', skdout[i].scanname, $
            strjoin( string( dtall[*, i], format = '(3F8.3)')+' ')+ $
            strjoin( string(skdout[i].rmsa1,skdout[i].rmsa2, $
                            skdout[i].rmsa3, format = '(3F8.1)')+' ')
   
   ;;rms_max = 2.*min([median(skdout.rmsa3),median(skdout.rmsa1)])
   ;;dt_max = 2.*min([stddev(dtall[0, *]),stddev(dtall[2, *])])
   print, 'rms_max = ', rms_max
   print, 'dt_max = ', dt_max
   
   wok = where($
         strlen(skdout.scanname[*]) gt 1 and $
         abs(dtall[0, *]) le dt_max[0] and $
         abs(dtall[1, *]) le dt_max[1] and $
         abs(dtall[2, *]) le dt_max[0] and $
         skdout.rmsa1[*] le rms_max[0] and $
         skdout.rmsa2[*] le rms_max[1] and $
         skdout.rmsa3[*] le rms_max[0] and $
         skdout.taufinal3 le tau3_max, nok, compl=wout, ncompl=nout)

   if nok le 2 then begin
      message, /info, 'Bad but desperate: Obliged to keep all skydips '+ strtrim( nok, 2)
      nok = nsc
      wok = indgen( nsc)
      nout = 0
   endif
   
   if keyword_set(selected_skydip_list) then selected_skydip_list = skdout[wok].scanname
   
   if nout gt 0 then begin
      
      print, 'Outlier list: '
      for i=0, nout-1 do print, 'index = ', index[wout[i]], ", name = ", skdout[wout[i]].scanname
      print, '...written in ', blacklist_file

      blacklist =  skdout[wout].scanname
      
      ;; updating a former black list file
      if keyword_set(blacklist_to_update) then begin
         if file_test(blacklist_to_update) lt 1 then begin
            print, "Previous backlist file not found ", blacklist_to_update
            print, "creating a blacklist file anew"       
         endif else begin
            print, "updating ", blacklist_to_update
            ;;cmd =  "cp "+blacklist_to_update+' '+blacklist_file
            ;;spawn, cmd
            readcol, blacklist_to_update, badscans, format='A', /silent
            blacklist = [blacklist, badscans]
         endelse
         ;;openu, lun2, blacklist_file, /get_lun, /append
      endif ;;else openw, lun2, blacklist_file, /get_lun
      
      openw, lun2, blacklist_file, /get_lun
      ;;for i=0, nout-1 do printf, lun2, skdout[wout[i]].scanname
      nout = n_elements(blacklist)
      for i=0, nout-1 do printf, lun2, blacklist[i]
      close, lun2
      free_lun, lun2
   endif else print, 'No outliers: doing nothing'
   
   ;;stop
   
end 
