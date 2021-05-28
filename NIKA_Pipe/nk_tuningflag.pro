;+
; 
; SOFTWARE: 
;        NIKA pipeline
;
; NAME:
; nk_tuningflag
; 
; PURPOSE: 
;        Detects tunings and updates data.scan_valid accordingly.
; 
; INPUT: 
;        - param: the parameter structure
;        - info: the information structure
; 
; OUTPUT: 
;        - data.scan_valid is modified
; 
; KEYWORDS:
;        NONE
; 
; MODIFICATION HISTORY: 
;        - 13/03/2014: creation from nika_pipe_getdata.pro 
;        (Nicolas Ponthieu - nicolas.ponthieu@obs.ujf-grenoble.fr)
;        - March 2020: FXD add more robustness
;-
;====================================================================================================


pro nk_tuningflag, param, info, data, kidpar

if info.status eq 1 then begin
   if param.silent eq 0 then    message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

if param.cpu_time then param.cpu_t0 = systime(0, /sec)

;; Not for before Run6
if long(param.day) lt 20130000 then return

letter = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', $
          'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't']

;; ;; Sept. 16 : T box does not work and crashes this code that will help
;; ;; find the longest section between two tunings : remove if from the
;; ;; analysis for the moment
;; if !nika.run eq '18' then begin
;;    letter = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', $
;;              'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's']
;;    w = where( kidpar.acqbox eq 19, nw)
;;    if nw ne 0 then kidpar[w].type = 3
;; endif

ndata = n_elements(data.scan)-1
flag = data.scan_valid *0  
tags = tag_names(data)
if strupcase( param.math) eq 'RF' then buff = 50L else buff = 1L

for ibox = 0, n_elements(letter)-1 do begin
   ll = letter[ibox]
   w_a_masq = where( strupcase(tags) eq strupcase(ll+"_MASQ"), nw_a_masq)
   if nw_a_masq ne 0 then begin
      ; FXD: modify formula here
;      flag1mm = where(data.(w_a_masq) eq 4, nflag1mm)
;      flag1mm = where( (byte(data.(w_a_masq)) and 4B) eq 4B, nflag1mm)
; FXD NP March 2020
      flag1mm = where( (long(data.(w_a_masq)) and long(!nika.fpga_change_frequence_flag)) $
                eq long(!nika.fpga_change_frequence_flag), nflag1mm)
      if nflag1mm gt 0 then begin
         flag[ibox,*]=1
         nc = nflag1mm + 1
         bs = lonarr(nc)
         es = lonarr(nc)
         ts = lonarr(nc)
         
         bs[0]    = 0
         es[nc-1] = ndata-1
;;;         for i=1,nc-1 do bs[i] = flag1mm[i-1]+50
;;;         for i=0,nc-2 do es[i] = flag1mm[i]  -50
;;;         for i=0,nc-1 do  if es[i] gt bs[i] then ts[i] = total(1-(data.scan_valid$
         bs(1L:*) = buff + flag1mm(0L:nc-2L)
; FXD correct the sign Apr 22, 2020: as noted by Juan
         es(0L:nc-2L) = -buff + flag1mm(0L:nc-2L)
         w_ts = where(es gt bs, c_ts)
         for k_ts = 0L, c_ts - 1L do ts(w_ts(k_ts)) = $
            total(1-(data.scan_valid)[ibox,bs(w_ts(k_ts)):es(w_ts(k_ts))])
;;;
         maxts = max(ts,pos)
         flag[ibox,bs[pos]:es[pos]] = 0
         flag[ibox, *] =  flag[ibox, *] or data.scan_valid[ibox]
      endif
   endif
endfor

;; Update scan_valid flag   
data.scan_valid = flag

; Special processing for the focus track sequence
if strupcase( strtrim( info.obs_type, 2)) eq 'FOCUS' then begin
   index = data.sample - data[0].sample
   w4 = where( data.scan_st eq 4, nw4)
   w5 = where( data.scan_st eq 5, nw5)
   sbeg = w4
   send = lonarr(nw4)
   for i=0, nw4-1 do begin
      w = where( w5 gt w4[i], nw)
      if i eq (nw4-1) and nw eq 0 then send[i] = max(index) else $
         send[i] = min(w5[w])
   endfor
   nsubscan = nint(max( data.subscan)) ; subscans starts at 1
   if nsubscan ne nw4+1 then message, 'Check why'
   for isubscan = 2, nsubscan do begin ; first subscan is tuning
      i1 = sbeg[ isubscan-2]
      i2 = send[ isubscan-2]
      if i2 gt i1 then begin
         u = where( data.subscan eq isubscan and $
                    (data.scan_valid[0] ne 0 or $
                     index lt i1 or index gt i2) , nu)
;Not ready yet         data[u].scan_valid[0] = 1 ; flag bad periods
      endif
   endfor
endif


if param.cpu_time then nk_show_cpu_time, param, "nk_tuningflag"
end
