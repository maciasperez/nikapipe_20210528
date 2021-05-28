

;+
;
; SOFTWARE: Real time analysis: derives telescope pointing offsets
;
; NAME: 
; nk_otf_pointing_restore
;
; CATEGORY:
;
; CALLING SEQUENCE:
; 
; PURPOSE: 
;        Replace missing pointing data by interpolation (if holes are smaller
;        than 2 subscans). Does nothing to lissajous scans
; 
; INPUT: 
;      - param, info, data, kidpar
; 
; OUTPUT: 
; 
; KEYWORDS:
;       - flag_holes: if set, missing data will remain flagged rather than being
;         revalidated for projection.
;       - plot: shows a few plots
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - nika_pipe_otf_pointing_restore : Created by Laurence Perotto (LPSC)
;        - June 12th, 2014: Ported to the new pipeline format, not
;          checked yet. N. Ponthieu
;
;-
;================================================================================================

pro nk_otf_pointing_restore, param, info, data, kidpar, int_holes, first_subscan_beg_index, last_subscan_end_index, plot=plot, chatty=chatty


if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_otf_pointing_restore, param, data, kidpar, plot=plot, chatty=chatty"
   return
endif

if info.status eq 1 then begin
   if param.silent eq 0 then    message, /info, "info.status = 1 from the beginning => exiting"
   return
endif


code = "NK_OTF_POINTING_RESTORE >> "
bav = 0
if keyword_set(chatty) then bav=1


nkids = n_elements( kidpar)
nsp   = n_elements(data)
index = lindgen(nsp)


;;
;;   CHECKING THE SCAN IS OF OTF TYPE 
;;___________________________________________________________________________
if strtrim( strupcase( info.obs_type),2) eq "ONTHEFLYMAP" then begin

   ;; working sample interval 
   w    = where( data.scan_valid[0] eq 0 and data.scan_valid[1] eq 0, nw, compl=w_out, ncompl=n_out)
   ibeg = w[0]
   iend = w[nw-1]

   ;; flag out zero values at the end of the scan
   ind = nw-1
   while (data[w[ind]].ofs_az eq 0 and data[w[ind]].ofs_el eq 0) do begin     
      iend=iend-1
      ind=ind-1
      IF (iend eq ibeg) THEN BREAK
   endwhile
   
   ;; flag out holes 
   ;; antenna2pointing flagged missing samples in the imbfits pointing
   ;; by adding 2L^9 
   ;; in case of param.flag_holes > 0, this flag also accounts for
   ;; original missing data.
   ;;w1         = where( kidpar.type eq 1, nw1)
   ;;flag       = data.flag[w1[0]]
   ;;w_holes_w  = nika_pipe_wflag( flag[w], 9, nflag=nflag)
   ;; => using int_holes instead
   w_holes_w  = where(int_holes[w] gt 0, nflag )

   if nflag gt 0 then begin
      ;; STARTING THE RESTORATION
      if bav then print, code
      if bav then print, code, nflag, " flagged samples to restore"
      
      w_holes = w[w_holes_w]
      flag = lonarr(nsp)
      flag[w_holes] = 1L
      if n_out gt 0 then flag[w_out] = 1L
      
      
      ;; CONVERTING ofs_az and ofs_el in x (triangular wave-like)
      ;; and y (step-like) signal 
      ;; (hence straightening otf scan if needed)
      junk = mrdfits( param.file_imb_fits,2,hdr,/sil)
      projection = sxpar( hdr, 'SYSTEMOF',/silent)
      if bav gt 0 then print,code, "projection type is ", projection         
      scan_type = 'type'
      otf_pointing_azel2xy, data.ofs_az, data.ofs_el, flag, projection, x, y, angle, signe, scan_type=scan_type
      if bav gt 0 then print,code, "type of OTF scan is ", scan_type
      
      
      ;; plot,x[w], y[w]
      ;; oplot,x[ibeg:iend], y[ibeg:iend], col=250
      ;; print,"angle = ", angle/!dtor
      ;; print,"signe = ", signe
      ;; stop


      ;; MAIN ROUTINE PERFORMING THE RESTORATION
      otf_pointing_restore, x, y, flag, x_restored, y_restored, outflag_restored, first_subscan_beg_index, last_subscan_end_index, ind_beg_scan=ibeg, ind_end_scan=iend, chatty=chatty, debug=debug
      if x_restored(0) eq -1 then begin
         return
      endif
      if keyword_set(plot) then begin

         wind, 1, 1, /free, /large, iconic = param.iconic
         !p.multi=[0,1,2]
         plot,index, x, col=0, xr=[ibeg,iend], yr=[-330,250],/ys, /xs, ytitle="azimuth [arcsec]", xtitle="sample"  
         oplot,index, x_restored,col=250
         oplot,outflag_restored*10.,col=50
         
         plot,index, y, col=0, xr=[ibeg,iend], yr=[-330,250],/ys, /xs, ytitle="azimuth [arcsec]", xtitle="sample"  
         oplot,index, y_restored,col=250
         oplot,outflag_restored*10.,col=50
         !p.multi=0
         
      endif

      ;; preparing plotting
      xrmin0=nsp-1
      xrmin1=nsp-1
      xrmin2=nsp-1
      xrmax0=0
      xrmax1=0
      xrmax2=0

      
      ;; ACCOUNTING FOR RESTORED DATA IF GOOD ENOUGH 
      ;;-----------------------------------------------------------------------------------------------
      ;; convention : 
      ;;       outflag = n :  n is the number of missing subscan
      ;;       extrema (beginning or ends) within the holes 
      ;;               --> n=0   : valid sample or no missing subscan
      ;;                           beginnings/ends. 
      ;;                           nothing to be done: the
      ;;                           interpolation already done by antenna2pointing is sufficient
      ;;               --> 0<n<3 : 1 or 2 missing extrema :
      ;;                           let's use the restored pointing
      ;;               --> n>=3  : more than 3 missing extrema, too
      ;;                           much lost information to garantee a precise
      ;;                           restoration : flagging out the data
      ;;                           is advised
      ;;-------------------------------------------------------------------------------------------------
      w0 = where(outflag_restored eq 0, n0) 
      if (n0 gt 0) then begin
         w_no_miss_ext = where(flag[w0] gt 0, n_no_miss_ext)
         if bav then print,code
         if bav then print,code, strtrim(string(n_no_miss_ext),2)," samples have already been properly interpolated using antenna2pointing_2 (no missing subscan extrema there)"  
         if (n_no_miss_ext gt 0) then begin
            if param.flag_holes lt 1 then begin
               ;; removing the flag
               if bav then print,code,"removing the flag..." 
               data[w0[w_no_miss_ext]].flag -= 2L^9
            endif
            ;; for plotting purpose only
            xrmin0 = index[w0[w_no_miss_ext[0]]]
            xrmax0 = index[w0[w_no_miss_ext[n_no_miss_ext-1]]]
         endif
      endif
      
      w_restored = where(outflag_restored[ibeg:iend] gt 0, n_restored) + ibeg
      

      ;; for restoration or plotting only
      ;;------------------------------------------------------------
      ;; flag_scan = 0 : on subscan
      ;; flag_scan = 1 : entre 2 subscans (critere "speedflag")
      ;; flag_scan = 3 : zone a ajouter pour l'elevation
      ;; flag_scan = 2 : zone a enlever pour l'azymuth 
      otf_pointing_flag_subscan, x_restored, y_restored, flag_scan,  i_begs, i_ends_az, i_ends_el, model=1
      myflag_scanst = lonarr(nsp)
      myflag_scanst[i_begs] = 1L
      myflag_scanst[i_ends_el] = 2L
      myflag_scanst[i_ends_az] = 3L
      

      
      if (n_restored gt 0) then begin
         ;; treating restored holes
         ;;-------------------------------------------------------------------------------
         if bav then print,code
         if bav then print,code," treating ",strtrim(string(n_restored),2)," restored samples..."  
         
         ;; flagging impacted subscans 
         ;;-------------------------------------------------------------------------------
         ;; myflag = outflag_restored
         ;; ;; if a subscan beginning is missing, the whole subscan is to restore
         ;; w_begs = where(data[w_restored].scan_st eq param.scanst.subscanstarted,n_begs)
         ;; if (n_begs gt 0) then begin
         ;;  ;; cut beginnings, searching for corresponding ends
         ;;    w_miss_begs = w_restored[w_begs]
         ;;    for i_beg = 0, n_begs-1 do begin
         ;;       i_ends_after = where(data[w_miss_begs[i_beg]:*].scan_st eq param.scanst.subscandone, n_ends_after)
         ;;       if n_ends_after gt 0 then begin
         ;;          i_closest_end = w_miss_begs[i_beg]+min(i_ends_after)
         ;;          if (myflag[i_closest_end] lt 1) then begin
         ;;             myflag[w_miss_begs[i_beg]:i_closest_end] = myflag[w_miss_begs[i_beg]] ; use replicate ?
         ;;          endif
         ;;       endif
         ;;    endfor
         ;; endif
         ;; ;; if a subscan end is missing, the whole subscan is to restore
         ;; w_ends = where(data[w_restored].scan_st eq param.scanst.subscandone,n_ends)
         ;; if (n_ends gt 0) then begin
         ;;    ;; missing ends, searching for corresponding beginnings
         ;;    w_miss_ends = w_restored[w_ends]
         ;;    for i_end = 0, n_ends-1 do begin 
         ;;       i_begs_before = where(data[0:w_miss_ends[i_end]].scan_st eq param.scanst.subscanstarted,n_begs_before)
         ;;       if n_begs_before gt 0 then begin
         ;;          i_closest_beg = max(i_begs_before)
         ;;          if (myflag[i_closest_beg] lt 1) then begin
         ;;             myflag[i_closest_beg:w_miss_ends[i_end]] = myflag[w_miss_ends[i_end]] ; use replicate ?
         ;;          endif
         ;;       endif
         ;;    endfor
         ;; endif
         
         ;; the same as what is commented above but in using my own
         ;; begins and ends flagging routine (a la "speedflag")   
         ;;-------------------------------------------------------------------------------
         myflag = intarr(nsp)
         myflag[ibeg:iend] = outflag_restored[ibeg:iend]
         
         

         ;; if a subscan beginning is missing, the whole subscan is to restore
         w_begs = where(myflag_scanst[w_restored] eq 1,n_begs)
         if (n_begs gt 0) then begin
            ;; cut beginnings, searching for corresponding ends
            w_miss_begs = w_restored[w_begs]
            for i_beg = 0, n_begs-1 do begin
               i_ends_after = where(myflag_scanst[w_miss_begs[i_beg]:*] eq 3, n_ends_after)
               if n_ends_after gt 0 then begin
                  i_closest_end = w_miss_begs[i_beg]+min(i_ends_after)
                  if (myflag[i_closest_end] lt 1) then begin
                     myflag[w_miss_begs[i_beg]:i_closest_end] = myflag[w_miss_begs[i_beg]] ; use replicate ?
                  endif
               endif
            endfor
         endif
         ;; if a subscan end is missing, the whole subscan is to restore
         w_ends = where(myflag_scanst[w_restored] eq 3,n_ends)
         if (n_ends gt 0) then begin
            ;; missing ends, searching for corresponding beginnings
            w_miss_ends = w_restored[w_ends]
            for i_end = 0, n_ends-1 do begin 
               i_begs_before = where(myflag_scanst[0:w_miss_ends[i_end]] eq 1,n_begs_before)
               if n_begs_before gt 0 then begin
                  i_closest_beg = max(i_begs_before)
                  if (myflag[i_closest_beg] lt 1) then begin
                     myflag[i_closest_beg:w_miss_ends[i_end]] = myflag[w_miss_ends[i_end]] ; use replicate ?
                  endif
               endif
            endfor
         endif

         
         w_myrestored = where(myflag gt 0, n_myrestored)
         if bav then print,code
         if bav then print,code," after accounting for all impacted subscans,", strtrim(string(n_myrestored),2), " samples need a restoration ..."  
         ;;
         ;; RESTORING
         ;;-------------------------------------------------------------------------------
         w_safe = where((myflag gt 0) and (myflag lt 3), n_safe)
         if bav then print,code
         if bav then print,code, n_safe, " will be restored"
         if (n_safe gt 0) then begin
            x[w_safe] = x_restored[w_safe]
            y[w_safe] = y_restored[w_safe]
            if bav then print,code,"removing the flag..." 
            data[w_safe].flag -= 2L^9
            ;; for plotting purpose only
            xrmin1 = index[w_safe[0]]
            xrmax1 = index[w_safe[n_safe-1]]
         endif
         ;;
         w_bad = where(myflag ge 3, n_bad)
         if bav then print,code
         if bav then print,code, n_bad, " can not be safely restored"  
         if (n_bad gt 0) then begin
            ;; restoring anyway (should be better than before)
            x[w_bad] = x_restored[w_bad]
            y[w_bad] = y_restored[w_bad]
            ;; however, the data is still flagged out
            ;; for plotting purpose only
            if n_safe ne 0 then xrmin2 = index[w_safe[0]]
            if n_safe ne 0 then xrmax2 = index[w_safe[n_safe-1]]
         endif
      endif

      
      if keyword_set(plot) then begin
         ;; keeping original data to plot
         az_ori = data.ofs_az
         el_ori = data.ofs_el
      endif
      
      ;; ROTATING BACK (x,y) TO (az,el)  
      otf_pointing_xy2azel, x, y, angle, signe, az, el
      data.ofs_az = az
      data.ofs_el = el
      az=0B
      el=0B
      



      if keyword_set(plot) then begin
         
         xrmin = min([xrmin0,xrmin1,xrmin2])
         xrmax = max([xrmax0, xrmax1, xrmax2])
         if xrmax eq 0 then xrmax=nsp-1 else xrmax=min([xrmax+500, nsp-1])
         if xrmin eq nsp-1 then xrmin=0 else xrmin=max([xrmin-500, 0])
         
         ;;i_ends = where(data.scan_st eq param.scanst.subscandone, n_ends)
         ;;i_begs = where(data.scan_st eq param.scanst.subscanstarted, n_begs)
         i_ends = where(myflag_scanst eq 3, n_ends)
         i_begs = where(myflag_scanst eq 1, n_begs)

         wind, 1, 1, /free, /large, iconic = param.iconic
         !p.multi=[0,1,2]
         plot,index,data.ofs_el,col=0,ytitle="el",/nodata, xr=[xrmin, xrmax]
         oplot,index,el_ori,col=250
         oplot,index,data.ofs_el,col=50 ;,linestyle=2 
         oplot, index[i_begs], data[i_begs].ofs_el, col=80, psym=4
         oplot, index[i_ends], data[i_ends].ofs_el, col=25, psym=1
         legendastro,['apres antenna2pointing_2','apres otf_pointing_restore','subscan begins', 'subscan ends'],col=[250,50,80,25],textcolor=[250,50, 80, 25], psym=[0,0,4,1], linestyle=[0,0,0,0],box=0
         ;;
         plot,index,data.ofs_az,col=0,ytitle="az",/nodata, yr=[-210,210], xr=[xrmin, xrmax]
         oplot,index,az_ori,col=250
         oplot,index,data.ofs_az,col=50 ;,linestyle=2 
         oplot, index[i_begs], data[i_begs].ofs_az, col=80, psym=4
         oplot, index[i_ends], data[i_ends].ofs_az, col=25, psym=1
         !p.multi=0
         

      endif

      ;;stop

   endif else begin
;      if not param.silent then print,code," no holes....I do nothing."
   endelse
   
endif else begin
;   if not param.silent then print,code," not an OTF scan....I do nothing."
endelse

  
end
