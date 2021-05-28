pro nika_pipe_flag_scanst, param, data, kidpar

  ;; scan start
  myflag = long(data.scan_st *0)

; Number of subscan
  goodscan = where( data.scan eq median( data.scan), ngoodscan)
  if ngoodscan ne 0 then nsub = long( max( data[ goodscan].subscan))

; scan started
  w = where(data.scan_st eq param.scanst.scanstarted,nw)
  if nw gt 0 then begin

     myflag[0:w[0]-1]=1
     begscan = w[0]-1
  endif else begin
   begscan=0
  endelse
  
; scan done
  w = where(data.scan_st eq param.scanst.scandone,nw)
  ;;R.A. 04/07/2014 rustine si le scandone se produit au debut
  last_subscan_start = max(where(data.scan_st eq param.scanst.subscanstarted, nlast_sss))
  if nlast_sss ne 0 and w[0] gt last_subscan_start[0] then begin
     if nw gt 0 then begin
        endscan = w[nw-1]
        if endscan gt begscan then myflag[w[nw-1]:*]=1
     endif 
  endif

  w = where(data.scan_st eq param.scanst.subscanstarted,nw)
  if nw gt 0 then begin
     begsubscan = w[0]-1 
     if w[0] ne 0 then myflag[0:w[0]-1]=1
  endif else begin
     begsubscan = 0
  endelse 
  
  w = where(data.scan_st eq param.scanst.subscandone,nw)
  if nw gt 0 then begin
    endsubscan = w[nw-1]
    ;; FXD 16 May 2014
    if  ((endsubscan gt begsubscan) and (endsubscan gt begscan) $
        and data[ endsubscan].subscan eq nsub) then  myflag[w[nw-1]:*]=1
    ;; This line below used to cut the last subscan of a multiple subscan scan.
    ;; if  ((endsubscan gt begsubscan) and (endsubscan gt begscan)) then  myflag[w[nw-1]:*]=1
  endif
  
  ;; set flags to zero for all KIDS
  w =where(myflag eq 1, nw)

  if nw gt 0 then begin
; update scan_valid flag
     myflag = data.scan_valid
     myflag[*,w] = myflag[*,w] or 1
     data.scan_valid = myflag

; update kids flag
     myflag = data.flag
     poweroftwo = 2l^18
     l = where( (myflag[*,w] and poweroftwo ) eq poweroftwo, nl, comp=wapp,ncomp=nwapp)
     tflag =  myflag[*,w]
     if nwapp gt 0 then tflag[wapp] += poweroftwo
     myflag[*,w] = tflag
     data.flag = myflag
     delvarx, flag, myflag, tflag
  endif

  ;;--------------------------------------------------
  ;; Commented out now that we interpolate the pointing using imbfits and
  ;; nika_pipe_corpointing_2.pro
  ;; Flag data with wrong pointing on RUN8
  badlist = where(data.scan eq 0,nbadlist)
  if nbadlist gt 0 then data[badlist].flag += 2L^18
  ;;--------------------------------------------------

  return
end
