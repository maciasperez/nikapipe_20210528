;+
;PURPOSE: Add flag based on tuning
;
;INPUT: The data and kidpar structures
;
;OUTPUT: The falgged data structure.
;
;LAST EDITION: 07/01/2014: creation(adam@lpsc.in2p3.fr)
; Modifications
;  Add flag directoy to the right value and search for largest period (macias@lpsc.in2p3.fr)
;-

pro nika_pipe_tuningflag, param, data, kidpar

;;data.scan_valid =  0.d0 ; init
;;w = where( data.subscan eq 1 and (data.a_masq ne 0 or data.b_masq ne 0),  nw)
;;if nw ne 0 then begin
;;   data[0:max(w)+50].scan_valid =  1
;;endif
;;
;;w = where( data.subscan eq max(data.subscan) and (data.a_masq ne 0 or data.b_masq ne 0),  nw)
;;if nw ne 0 then begin
;;   data[min(w)-50:*].scan_valid =  1
;;endif

   ndata = n_elements(data.scan)-1
   flag = data.scan_valid *0  
 
  if long(param.day[param.iscan]) ge 20130000 then begin ;Not for before Run6
     w1mm = where(kidpar.array eq 1, nw1mm)
     w2mm = where(kidpar.array eq 2, nw2mm)
     
     flag1mm = where(data.a_masq eq 4, nflag1mm)
     if nflag1mm gt 0 then begin
        flag[0,*]=1
        nc = nflag1mm + 1
        bs = lonarr(nc)
        es = lonarr(nc)
        ts = lonarr(nc)

        bs[0]=0
        es[nc-1] = ndata-1
        for i=1,nc-1 do bs[i]=flag1mm[i-1]+50
        for i=0,nc-2 do es[i]=flag1mm[i]-50
        

        for i=0,nc-1 do  if es[i] gt bs[i] then ts[i] = total(1-(data.scan_valid)[0,bs[i]:es[i]])
        maxts = max(ts,pos)
        flag[0,bs[pos]:es[pos]]=0
    endif 


     flag2mm = where(data.b_masq eq 4, nflag2mm)
     if nflag2mm gt 0 then begin
        flag[1,*]=1
        nc = nflag2mm + 1
        bs = lonarr(nc)
        es = lonarr(nc)
        ts = lonarr(nc)

        bs[0]=0
        es[nc-1] = ndata-1
        for i=1,nc-1 do bs[i]=flag2mm[i-1]+50
        for i=0,nc-2 do es[i]=flag2mm[i]-50
        

        for i=0,nc-1 do if es[i] gt bs[i] then ts[i] = total(1-(data.scan_valid)[1,bs[i]:es[i]])
        maxts = max(ts,pos)

        flag[1,bs[pos]:es[pos]]=0
 
      endif 
 
      flag[0,*] = flag[0,*] or data.scan_valid[0]
      flag[1,*] = flag[1,*] or data.scan_valid[1]
 
; Update scan_valid flag   
      data.scan_valid = flag

;     if nflag1mm ne 0 then nika_pipe_addflag, data, 10, wsample=flag1mm
;     if nflag2mm ne 0 then nika_pipe_addflag, data, 10, wsample=flag2mm
  endif

  return
end
