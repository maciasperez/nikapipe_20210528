;+
; 
; SOFTWARE: 
;        NIKA pipeline
; NAME:
; nk_flag_scanst
; 
; PURPOSE: 
;        Flags unvalid samples (out of subscans, unvalid...)
; 
; INPUT: 
;        - param: the parameter structure
;        - info: the information structure
;        - data
;        - kidpar
; 
; OUTPUT: 
;        - data: the data structure
;        - kidpar: the KID parameter structure
; 
; KEYWORDS:
;        NONE
; 
; MODIFICATION HISTORY: 
;        - 13/03/2014: creation from nika_pipe_getdata.pro 
;        (Remi Adam & Nicolas Ponthieu - nicolas.ponthieu@obs.ujf-grenoble.fr)
;-
;====================================================================================================

pro nk_flag_scanst, param, info, data, kidpar

if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

if param.cpu_time then param.cpu_t0 = systime(0, /sec)

;; scan start
myflag = long(data.scan_st *0)

;; print, '1, total(myflag): ', total(myflag)

;; Number of subscans
goodscan = where( data.scan eq median( data.scan), ngoodscan)
if ngoodscan ne 0 then nsub = long( max( data[ goodscan].subscan))

;; Set myflag to 1 for all samples before scan started
w = where(data.scan_st eq param.scanst_scanstarted,nw)
if nw gt 0 then begin
   myflag[0:(w[0]-1)>0]=1
   begscan = (w[0]-1)>0
endif else begin
   begscan=0
endelse
;; print, '2, total(myflag): ', total(myflag)

;; Set myflag to 1 for all samples after scan done
w = where(data.scan_st eq param.scanst_scandone,nw)
;; if nw gt 0 then begin
;;    endscan = w[nw-1]
;;    if endscan gt begscan then myflag[w[nw-1]:*]=1
;; endif
;;R.A. 04/07/2014 rustine si le scandone se produit au debut
last_subscan_start = max(where(data.scan_st eq param.scanst_subscanstarted, nlast_sss))
if nlast_sss ne 0 and w[0] gt last_subscan_start[0] then begin
   if nw gt 0 then begin
      endscan = w[nw-1]
      if endscan gt begscan then myflag[w[nw-1]:*]=1
   endif
endif
;; print, '3, total(myflag): ', total(myflag)

;; Set myflag to 1 for all samples before subscanstarted
w = where(data.scan_st eq param.scanst_subscanstarted,nw)
if nw gt 0 then begin
   begsubscan = w[0]-1 
   if w[0] ne 0 then myflag[0:(w[0]-1)>0]=1
endif else begin
   begsubscan = 0
endelse
;; print, '4, total(myflag): ', total(myflag)

;; Set myflag to 1 for all samples after subscandone
w = where(data.scan_st eq param.scanst_subscandone,nw)

;; if nw gt 0 then begin
;;    endsubscan = w[nw-1]
;;    if  ((endsubscan gt begsubscan) and (endsubscan gt begscan)) then  myflag[w[nw-1]:*]=1
;; endif
if nw gt 0 then begin
   endsubscan = w[nw-1]
   ;; FXD 16 May 2014
   if  ((endsubscan gt begsubscan) and (endsubscan gt begscan) $
        and data[ endsubscan].subscan eq nsub) then  myflag[w[nw-1]:*]=1
    ;; This line below used to cut the last subscan of a multiple subscan scan.
   ;; if  ((endsubscan gt begsubscan) and (endsubscan gt begscan)) then
   ;; myflag[w[nw-1]:*]=1
endif
;; print, '5, total(myflag): ', total(myflag)
;stop
w =where(myflag eq 1, nw)
if nw gt 0 then begin
   ;; update scan_valid
   myflag = data.scan_valid
   myflag[*,w] = myflag[*,w] or 1
   data.scan_valid = myflag

   ;;update kids flags
   myflag = data.flag
   poweroftwo = 2l^18
   l = where( (myflag[*,w] and poweroftwo ) eq poweroftwo, nl, comp=wapp,ncomp=nwapp)
   tflag =  myflag[*,w]
   if nwapp gt 0 then tflag[wapp] += poweroftwo
   myflag[*,w] = tflag
   data.flag = myflag
   delvarx, flag, myflag, tflag
endif

; Flag data with wrong pointing on RUN8
badlist = where(data.scan lt 1, nbadlist)
;; change flag 9 to 18 to match Remi's choice, NP, Aug. 26th, 2015
;if nbadlist gt 0 then nk_add_flag, data, 9, wsample=badlist
if nbadlist gt 0 then nk_add_flag, data, 18, wsample=badlist

if param.cpu_time then nk_show_cpu_time, param
end
