;+
; 
; SOFTWARE: 
;        NIKA pipeline
;
; NAME:
;     nk_acqflag2pipeflag
; 
; PURPOSE: 
;        Passes flags from raw data to pipeline data
; 
; INPUT: 
;        - param: the parameter structure
;        - info: the information structure
;        - data
;        - kidpar
; 
; OUTPUT: 
;        - data.flag is modified
; 
; KEYWORDS:
;        NONE
; 
; MODIFICATION HISTORY: 
;        - 13/03/2014: creation from nika_pipe_getdata.pro 
;        (Nicolas Ponthieu - nicolas.ponthieu@obs.ujf-grenoble.fr)
;-
;====================================================================================================

;; ;; Example of comparison
;; junk = 2L^2 + 2L^3
;; print, junk and 2L^2
;; print, junk and 2L^3
;; ;; but also:
;; print, junk and 5

pro nk_acqflag2pipeflag, param, info, data, kidpar

if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

if param.cpu_time then param.cpu_t0 = systime(0, /sec)

;; flag values in raw data
;; flag_list = [0, 1, 2, 5, 6, 7]
;;----------------------------------------------------------------
;; Update, after discussion with FXD and AB, NP. Dec. 8th, 2015 by
;; mail (Forward from Xavier, Dec. 8th, 2015): 6 is not always good, 7 is obsolete
;flag_list = [2, 3, 5]

flag_list = [2]

; Corrupted data exist for DIY if one keeps k_flag=8, put bit 3 back in the
; game FXD 6/3/2016
if strupcase(strtrim(info.obs_type, 2)) eq 'DIY' then flag_list = [2, 3]

;; Flag values in pipeline data
nflags = n_elements(flag_list)
pipe_flag_list = indgen( nflags) + 12

nsn = n_elements(data)

;; check one by one where data.k_flag contains a power of two
for i=0, n_elements(flag_list)-1 do begin
   powerOfTwo = 2L^flag_list[i]
   
   ;; Check poweroftwo is contained in data.k_flag (and not necessarily equal to
   ;; it, see examples on top of this file)
   flagged = where( (long(data.k_flag) and powerOfTwo) EQ powerOfTwo, nflagged)

   ;; Add the pipeline flag value for samples that have not been already
   ;; flagged with this value
   if nflagged gt 0 then begin   
      powerOfTwo = 2L^pipe_flag_list[i]
      w = where((long((data.flag)[flagged]) and poweroftwo ) eq poweroftwo, nw, comp=wapp, ncomp=nwapp)
      IF nwapp gt 0 then begin    
         flagged = flagged[wapp]
         myflag = data.flag
         myflag[flagged] += poweroftwo
         data.flag = myflag

;;         ;; Take some margin around these tuning flags
;;         ;; NP, Jan 29th, 2016
;;         for ii=0, n_elements(kidpar)-1 do begin
;;            if kidpar[ii].type eq 1 then begin
;;               ww = where((long(data.flag[ii]) and poweroftwo) eq poweroftwo, nww)
;;               if nww ne 0 then begin
;;                  for j=0, nww-1 do begin
;;                     i1 = (ww[j]-50)>0
;;                     i2 = (ww[j]+50)<(nsn-1)
;;                     nk_add_flag, data, poweroftwo, wsample=indgen(i2-i1+1)+i1, wkid=ii
;;                  endfor
;;               endif
;;            endif
;;         endfor
         
         delvarx, myflag
      endif 
   endif
endfor


if param.skydip eq 0 then begin  ; Do not test that for skydips
; FXD: add the special for k_flag ouside the range: k_flag=1 (normal) k_flag=0 (anomalous but correct?)
; This is shown to be useful. For example for scan '20200217s275'
;;; too restrictive
;;;flagged = where( (long(data.k_flag) and 1L) NE 1L, nflagged)
; this is shown to be more relaxed but eliminite beginning of first
; subscan which is still affected (infected) by tunings.
; FXD April 22, 2020 Improve the detection as 32 and 64 are rogue
; k_flag
   kfmod=long(data.k_flag)
   u=where( kfmod and 2L^5,nu)
   if nu ne 0 then kfmod[u]=kfmod[u]-2L^5
   u=where( kfmod and 2L^6,nu)
   if nu ne 0 then kfmod[u]=kfmod[u]-2L^6

; FXD May 2021 In scan '20210116s90' beam map, box 20 (T) looses 60
; kids because the k_flag is 512+1, undo that:
   u=where( kfmod and 2L^9,nu)
   if nu ne 0 then kfmod[u]=kfmod[u]-2L^9

; In case further problems happen, do this
;; jf = intarr( 21)
;; for ifl = 1, 20 do begin
;;    a=(kfmod and 2L^ifl)
;;    c=total(a,2)/2L^ifl
;;    jf[ ifl] = max( c and kidpar.type eq 1)
;;    print, ifl,  jf[ifl]
;; endfor


   
   flagged = where( kfmod gt 1L , nflagged)
   powerOfTwo = 2L^12
   buff = 60L          ; extend the flag to make sure values are back to normal
;; Add the pipeline flag value for samples that have not been already
;; flagged with this value
   if nflagged gt 0 then begin   
      w = where((long((data.flag)[flagged]) and poweroftwo ) eq poweroftwo, $
                nw, comp=wapp, ncomp=nwapp)
      
      if nwapp gt 0 then begin    
         flagged = flagged[wapp]
         myflag = data.flag
         myflag[flagged] += poweroftwo
         data.flag = myflag
         delvarx, myflag
      endif 
   endif
; Extend in samples and for the whole acq box
   imssg = 0
   maxsub = max( data.subscan)
   nbox = max(kidpar.acqbox)-min(kidpar.acqbox)+1
   boxlist = indgen(nbox) + min(kidpar.acqbox)
   for iacq = 0, nbox-1 do begin
      ab = where( kidpar.acqbox eq boxlist[iacq], nab)
      if nab ne 0 then begin
         flaux = long( data.flag[ab])
                                ; The whole box must be weird to be flagged
         bad = where( (total( (flaux and poweroftwo) eq poweroftwo, 1) eq nab ) and $
                      data.subscan ge 2, nbad) ; collective samples (avoid the first subscan)
         savec = fltarr( nsn)
         if nbad ne 0 then begin
            savec[ bad] = 1
            badsub = data[ bad[0]].subscan
            if badsub ne maxsub then begin
               print, 'Unusual blip in the data for box ',  strtrim( boxlist[iacq], 2), $
                      ' at first sample ', strtrim( bad[0], 2), $
                      ', subscan '+strtrim( badsub, 2)+ ' '+ info.scan
               imssg = 1
            endif
         endif
         savec = smooth( savec,  buff) gt 0
         flvec = replicate(1,nab)#savec ; back to individual samples
         flagged = where( flvec, nflagged)
         if nflagged gt 0 then begin   
            w = where((flaux[flagged] and poweroftwo) eq poweroftwo, $
                      nw, comp=wapp, ncomp=nwapp)
            if nwapp gt 0 then begin    
               flagged = flagged[wapp]
               flaux[flagged] += poweroftwo
               data.flag[ab] = flaux
            endif 
         endif
      endif
   endfor
   if imssg eq 1 then message, /info, $
                               param.scan+ ' Flagged correctly in principle'
endif


if param.cpu_time then nk_show_cpu_time, param, "nk_acqflag2pipeflag"

end
