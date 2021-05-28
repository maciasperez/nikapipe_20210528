;+
; 
; SOFTWARE: 
;        NIKA pipeline
; 
; NAME:
; nk_tuningflag_skydip
;
; PURPOSE: 
;        Detects tunings and updates data.scan_valid accordingly.
; 
; INPUT: 
;        - param: the parameter structure
;        - info: the information structure
; 
; OUTPUT: 
;        - data.scan_valid is modified ([4 and 5 are used here to count
;          notuning phases
; 
; KEYWORDS:
;        NONE
; 
; MODIFICATION HISTORY: 
;        - 13/03/2014: creation from nika_pipe_getdata.pro 
;        (Nicolas Ponthieu - nicolas.ponthieu@obs.ujf-grenoble.fr)
;         - 02/2015 FXD: notuning phases
;-
;====================================================================================================


pro nk_tuningflag_skydip, param, info, data, kidpar

if info.status eq 1 then begin
   if param.silent eq 0 then    message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

if param.cpu_time then param.cpu_t0 = systime(0, /sec)

masqlen = 50  ; mask length for the flag

ndata = n_elements(data.scan)-1
flag = data.scan_valid *0  
nsotto = data.nsotto*0-1

; Not used for NIKA2
; Should be checked for backward compatibility with NIKA runs
if fix(!nika.run) le 12 then begin ; NIKA
   w1mm = where(kidpar.lambda lt 1.5, nw1mm)
   w2mm = where(kidpar.lambda gt 1.5, nw2mm)

   tags = tag_names(data)
   w_a_masq = where( strupcase(tags) eq "A_MASQ", nw_a_masq)
;;   if tag_exist( data, 'a_masq') then begin
   if nw_a_masq ne 0 then begin
      ; FXD: modify formula here
;      flag1mm = where(data.a_masq eq 4, nflag1mm)
      if strupcase(!nika.acq_version) eq "V1" then begin
         flag1mm = where( (byte(data.(w_a_masq)) and 4B) eq 4B, nflag1mm)
      endif else begin
         flag1mm = where( (byte(data.(w_a_masq)) and 32B) eq 32B, nflag1mm)
      endelse
      if nflag1mm gt 0 then begin
         flag[0,*]=1
         nsotto[0,*]=-1         ; tuning phases (good ones start at 0)
         nc = nflag1mm + 1
         bs = lonarr(nc)
         es = lonarr(nc)
         ts = lonarr(nc)
         
         bs[0]=0
         es[nc-1] = ndata-1
         for i=1,nc-1 do bs[i]=(flag1mm[i-1]+ masqlen)>0
         for i=0,nc-2 do es[i]=(flag1mm[i]  - masqlen) < (ndata-1)
         
         
         for i=0,nc-1 do  if es[i] gt bs[i] then $
            ts[i] = total(1-(data.scan_valid)[0,bs[i]:es[i]])
         maxts = max(ts,pos)
         if param.skydip then begin
; In case of skydip keep all subscans instead of the longest one
            for i=0,nc-1 do  if es[i] gt bs[i] then begin
               flag[0,bs[i]:es[i]]=0 
               nsotto[0,bs[i]:es[i]]=i
            endif
         endif else flag[0,bs[pos]:es[pos]]=0 ; normal case
      endif
   endif

   w_b_masq = where( strupcase(tags) eq "B_MASQ", nw_b_masq)
   if nw_b_masq ne 0 then begin
;;   if tag_exist( data, 'b_masq') then begin
;      flag2mm = where(data.b_masq eq 4, nflag2mm)
      if nflag2mm gt 0 then begin
         if strupcase(!nika.acq_version) eq "V1" then begin
            flag2mm = where( (byte( data.b_masq) and 4B) eq 4B, nflag2mm)
         endif else begin
            flag2mm = where( (byte( data.b_masq) and 32B) eq 32B, nflag2mm)
         endelse
         flag[1,*]=1
         nsotto[1,*]=-1         ; tuning phases (good ones start at 0)
         nc = nflag2mm + 1
         bs = lonarr(nc)
         es = lonarr(nc)
         ts = lonarr(nc)
         
         bs[0]=0
         es[nc-1] = ndata-1
         for i=1,nc-1 do bs[i]=(flag2mm[i-1]+ masqlen)>0
         for i=0,nc-2 do es[i]=(flag2mm[i]  - masqlen) < (ndata-1)
         
         for i=0,nc-1 do if es[i] gt bs[i] then $
            ts[i] = total(1-(data.scan_valid)[1,bs[i]:es[i]])
         maxts = max(ts,pos)
         if param.skydip then begin
; In case of skydip keep all subscans instead of the longest one
            for i=0,nc-1 do  if es[i] gt bs[i] then begin
               flag[1,bs[i]:es[i]]=0 
               nsotto[1,bs[i]:es[i]]=i
            endif
         endif else flag[1,bs[pos]:es[pos]]=0 ; normal case
      endif
   endif
   if nw_b_masq ne 0 then begin
;      flag12mm = where(data.b_masq eq 4 or data.a_masq, nflag12mm)
      if strupcase(!nika.acq_version) eq "V1" then begin
         flag12mm = where((byte(data.b_masq) and 4B) eq 4B or byte(data.a_masq), nflag12mm)
      endif else begin
         flag12mm = where((byte(data.b_masq) and 32B) eq 32B or byte(data.a_masq), nflag12mm)
      endelse
      if nflag12mm gt 0 then begin
         flag[2,*]=1
         nsotto[2,*]=-1         ; tuning phases (good ones start at 0)
         nc = nflag12mm + 1
         bs = lonarr(nc)
         es = lonarr(nc)
         ts = lonarr(nc)
         
         bs[0]=0
         es[nc-1] = ndata-1
         for i=1,nc-1 do bs[i]=(flag12mm[i-1]+ masqlen)>0
         for i=0,nc-2 do es[i]=(flag12mm[i]  - masqlen) < (ndata-1)
         
         for i=0,nc-1 do if es[i] gt bs[i] then $
            ts[i] = total(1- $
                          ((data.scan_valid)[0,bs[i]:es[i]] and $
                           (data.scan_valid)[1,bs[i]:es[i]]))
         maxts = max(ts,pos)
         if param.skydip then begin
; In case of skydip keep all subscans instead of the longest one
            for i=0,nc-1 do  if es[i] gt bs[i] then begin
               flag[2,bs[i]:es[i]]=0 
               nsotto[2,bs[i]:es[i]]=i
            endif
         endif else flag[2,bs[pos]:es[pos]]=0 ; normal case
      endif
   endif

;;=========================================================================================
;;===================================== NIKA2 =============================================
;;=========================================================================================
endif else begin
; FXD add all tunings in vector 2  (byte 2 and 3 now used 6/3/2016)
;;    if strupcase(!nika.acq_version) eq "V1" then begin
;;       a=((byte(data.k_flag) and 4B) eq 4B) OR ((byte(data.k_flag) and 8B) eq 8B)
;;    endif else begin
;;       a=((byte(data.k_flag) and 32B) eq 32B) OR ((byte(data.k_flag) and 16B) eq 16B)
;;    endelse

   if strupcase(!nika.acq_version) eq "V3" then begin

      delvarx, ind
      itotsotto = n_elements( data[0].nsotto)-1
      nsotto[itotsotto,*]=-1    ; tuning phases (good ones start at 0)
      quiet_phase = 0
      for isubscan=min(data.subscan), max(data.subscan) do begin
         ;; last sample to consider: last sample of the subscan
         ;; without tuning: start from the end, then go back as far as
         ;; needed (if needed...)
         wsub   = where( data.subscan eq isubscan, nwsub)
         i2     = wsub[nwsub-1]
         status = data[i2].tuning_en_cours
         while status ne 0 and i2 gt wsub[0] do begin
            status = data[i2].tuning_en_cours
            i2--
         endwhile
         
         ;; 1st sample to consider: last tuning of the subscan
         wsub_tune = where( data.subscan eq isubscan and data.tuning_en_cours ne 0, nwsub_tune)
         if nwsub_tune eq 0 then begin
            i1 = wsub[0]
         endif else begin
            i1 = wsub_tune[nwsub_tune-1]
            i1 += 1             ; take margin
         endelse

         if i2 gt i1 then begin
            flag[itotsotto,i1:i2] = 0
            nsotto[itotsotto,i1:i2] = quiet_phase
            quiet_phase++
         endif
      endfor

;;      wind, 1, 1, /free
;;      nsn = n_elements(data)
;;      index = dindgen(nsn)
;;      plot, index, data.el, /xs, /ys, yra=[0, max(data.el)]
;;      oplot, index, float(nsotto[itotsotto,*])/max(nsotto[itotsotto,*]), col=70
;;      legendastro, ['elevation', 'nsotto (norm.)'], textcol=[!p.color, 70]
      
   endif else begin ; acquisition v1 or v2
      ;; NP, Sept. 19th, 2018
      ;; Write it this way to be immune to future changes in flag
      ;; definitions
      ;; See nk_translate_acq_flags
      a = ((byte(data.k_flag) and !nika.tuning_en_cours_flag) eq !nika.tuning_en_cours_flag) OR $
          ((byte(data.k_flag) and !nika.fpga_change_frequence_flag) eq !nika.fpga_change_frequence_flag)
      
      alltuning = total( a, 1) ne 0
      flag12mm = where(alltuning, nflag12mm)
      itotsotto = n_elements( data[0].nsotto)-1
      if nflag12mm gt 0 then begin
         flag[itotsotto,*]=1
         nsotto[itotsotto,*]=-1 ; tuning phases (good ones start at 0)
         nc = nflag12mm + 1
         bs = lonarr(nc)
         es = lonarr(nc)
         ts = lonarr(nc)
         
         bs[0]=0
         es[nc-1] = ndata-1
         for i=1,nc-1 do bs[i]=(flag12mm[i-1]+ masqlen)>0
         for i=0,nc-2 do es[i]=(flag12mm[i]  - masqlen) < (ndata-1)
         for i=0,nc-1 do if es[i] gt bs[i] then $
            ts[i] = total(1-(alltuning)[bs[i]:es[i]])
         maxts = max(ts,pos)
         if param.skydip then begin
; In case of skydip keep all subscans instead of the longest one
            for i=0,nc-1 do  if es[i] gt bs[i] then begin
               flag[itotsotto,bs[i]:es[i]]=0 
               nsotto[itotsotto,bs[i]:es[i]]=i
            endif 
         endif else flag[itotsotto,bs[pos]:es[pos]]=0 ; normal case
      endif
      flag[itotsotto,*] = flag[itotsotto,*] or alltuning
   endelse
   
endelse
flag[0,*] = flag[0,*] or data.scan_valid[0]
flag[1,*] = flag[1,*] or data.scan_valid[1]

; Update scan_valid flag   
data.scan_valid = flag
data.nsotto = nsotto

;; wind, 1, 1, /f
;; plot, data.nsotto[2,*]
;; legendastro, strtrim(n_elements(data))


if param.cpu_time then nk_show_cpu_time, param

end
