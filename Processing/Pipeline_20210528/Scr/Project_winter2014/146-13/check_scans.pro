
day = 20140222
scan_num = 346
scan_num = 349
scan_num = 310

scan_num2 = [310,311,312,320,321,322,323,324,329,331,332,333,334,336,337,338,339,340,346,347,349]
nscans = n_elements( scan_num2)
for i=0, nscans-1 do begin
   scan_num = scan_num2[i]

   ikid = 0
   
   nika_pipe_default_param, scan_num, day, param
   nika_pipe_getdata, param, data, kidpar, /one
   nika_pipe_valid_scan, param, data, kidpar
   
   wind, 1, 1, /free, /large
   !p.multi=[0,2,2]
   plot, data.ofs_az, data.ofs_el, /iso, title=strtrim(scan_num,2), $
         xtitle='ofs_az', ytitle='ofs_el'
   plot, data.subscan, xtitle='Subscan'
   plot, data.rf_didq[ikid]
   legendastro, 'ikid '+strtrim(ikid,2)
   !p.multi=0
   png, strtrim(scan_num,2)+".png"
endfor

;; 320, 339, 340, 346, 347, 349

end
