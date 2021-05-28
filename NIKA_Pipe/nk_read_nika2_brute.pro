;+
; 
; SOFTWARE: 
;        NIKA pipeline
; 
; NAME:
; nk_read_nika2_brute
;
; PURPOSE: 
;        - Wrapper to read_nika_brute to gather data from multiple
;          boxes into a single structure
; 
; INPUT: 
;        - param: the parameter structure
;        - info: the information structure
; 
; OUTPUT: 
;        - data: the data structure
;        - kidpar: the KID parameter structure
; 
; KEYWORDS:
; 
; MODIFICATION HISTORY: 
;        - Sept. 28th, 2015: NP
;-
;====================================================================================================

pro nk_read_nika2_brute, scan, param_c, kidpar, data, units, param_d=param_d, $
                         list_data=list_data, list_detector=list_detector, $
                         read_type=read_type, read_array=read_array, silent=silent, $
                         amp_modulation=amp_modulation, rr=rr

  
if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_read_nika2_brute, scan, param_c, kidpar, data, units, param_d=param_d, $"
   print, "                     list_data=list_data, list_detector=list_detector, $"
   print, "                     read_type=read_type, read_array=read_array, /silent, $"
   print, "                     amp_modulation=amp_modulation, rr=rr"
   return
endif

scan2daynum, scan, day, scan_num
yyyy  = strmid(day,0,4)
mm    = strmid(day,4,2)
dd    = strmid(day,6,2)

ikid_min = [1600, 0,    4800]
ikid_max = [4799, 1599, 7999]

;; Init number of samples and list_detector
if keyword_set(list_detector) then begin
   ;; do nohting and read the requested list_detector
endif else begin
   ;; Get list_detector from the first file since they're all
   ;; the same in A1, A2, A3
   file = !nika.raw_acq_dir+"/X_"+yyyy+"_"+mm+"_"+dd+"_A1_"+string(scan_num,format='(I4.4)')
   nb_tot_samples = read_nika( file, param_c, param_d, data, silent=1, no_data=1)
   if nb_tot_samples ne 0 then begin
      if read_type gt 99 then begin
         ;; read all kids then...
      endif else begin
         if read_type le 9 then begin
            type_list = read_type
         endif else begin
            t1 = long(read_type/10)
            t2 = read_type - 10*t1
            type_list = [t1, t2]
         endelse
         
         w = where(param_d.type eq type_list[0], nw)
         if nw ne 0 then keep = w else keep = [-1]
         if n_elements(type_list) eq 2 then begin
            w1 = where( param_d.type eq type_list[1], nw1)
            if nw1 ne 0 then keep = [keep, w1]
         endif
         if keep[0] ne -1 then begin
            if defined(list_detector) eq 0 then begin
               list_detector = keep
            endif else begin
               list_detector = [list_detector, keep]
            endelse
            print, file
            help, list_detector
            
         endif else begin
            message, /info, "No valid kid to read in "+file
            return
         endelse 
      endelse
   endif
endelse                         ; list_detector

;; Init the output structure
nkids = n_elements(list_detector)
data = create_struct( "I", dblarr(nkids), $
                      "Q", dblarr(nkids), $
                      "DI", dblarr(nkids), $
                      "DQ", dblarr(nkids), $
                      "F_TONE", dblarr(nkids), $
                      "DF_TONE", dblarr(nkids), $
                      "K_FLAG", dblarr(nkids), $
                      "RF_DIDQ", dblarr(nkids), $
                      "subscan", 0.d0, $
                      "scan", 0d0, $
                      "el", 0.d0, $
                      "ofs_az", 0.d0, $
                      "ofs_el", 0.d0, $
                      "az", 0.d0, $
                      "paral", 0.d0, $
                      "scan_st", 0.d0, $
                      "mjd", 0.d0, $
                      "lst", 0.d0, $
                      "sample", 0.d0, $
                      "a_masq", 0.d0, $
                      "b_masq", 0.d0, $
                      "ra", 0.d0, $
                      "dec", 0.d0, $
                      "a_t_utc", 0.d0, $
                      "b_t_utc", 0.d0, $
                      "scan_valid", intarr(25))

;; ;;-----------------------------------
;; message, /info, "fix me:"
;; for iarray=1, 3 do begin
;;    file = !nika.raw_acq_dir+"/X_"+yyyy+"_"+mm+"_"+dd+"_A"+strtrim(iarray,2)+"_"+string(scan_num,format='(I4.4)')
;;    message, /info, "Reading "+file+"..."
;;    delvarx, list_detector
;;    rr = read_nika_brute(file, param_c, kidpar1, data1, units, param_d=param_d, $
;;                         list_data=list_data, list_detector=list_detector, $
;;                         read_type=read_type, read_array=read_array, /silent, amp_modulation=amp_modulation)
;;    help, param_d
;; endfor
;; stop
;; 
;; ;;-----------------------------------

;; Loop over matrix files
init_data = 0
for iarray=1, 3 do begin

   ;; Read the file only if kids are requested in list_detector
   wkids = where( list_detector ge ikid_min[iarray-1] and list_detector le ikid_max[iarray-1], nwkids)
   if nwkids ne 0 then begin
      
      file = !nika.raw_acq_dir+"/X_"+yyyy+"_"+mm+"_"+dd+"_A"+strtrim(iarray,2)+"_"+string(scan_num,format='(I4.4)')
      message, /info, "Reading "+file+"..."
      rr = read_nika_brute(file, param_c, kidpar1, data1, units, param_d=param_d, $
                           list_data=list_data, list_detector=list_detector[wkids], $
                           read_type=read_type, read_array=read_array, /silent, amp_modulation=amp_modulation)

      if rr le 0 then begin
         message, /info, "No useful data in "+file
         return
      endif
      
      if defined(kidpar) then begin
         k  = kidpar[0]
         nk = n_elements(kidpar)
         k1 = replicate( k, nk+n_elements(kidpar1))
         k[0:nk-1] = kidpar
         k[nk:*]   = kidpar1

         kidpar = k
      endif else begin
         ;; init
         kidpar = kidpar1
      endelse

      if init_data eq 0 then begin
         nsn = n_elements(data1)
         data = replicate(data,nsn)
         
         data.subscan    = data1.subscan   
         data.scan       = data1.scan      
         data.el         = data1.el        
         data.ofs_az     = data1.ofs_az    
         data.ofs_el     = data1.ofs_el    
         data.az         = data1.az        
         data.paral      = data1.paral     
         data.scan_st    = data1.scan_st   
         data.mjd        = data1.mjd       
         data.lst        = data1.lst       
         data.sample     = data1.sample    
         data.a_masq     = data1.a_masq    
         data.b_masq     = data1.b_masq    
         data.ra         = data1.ra        
         data.dec        = data1.dec       
         data.a_t_utc    = data1.a_t_utc   
         data.b_t_utc    = data1.b_t_utc   
         data.scan_valid = data1.scan_valid

         init_data = 1
      endif

      data.I[       wkids] = data1.I
      data.Q[       wkids] = data1.Q
      data.DI[      wkids] = data1.DI
      data.DQ[      wkids] = data1.DQ
      data.F_TONE[  wkids] = data1.F_TONE
      data.DF_TONE[ wkids] = data1.DF_TONE
      data.K_FLAG[  wkids] = data1.K_FLAG
      data.RF_DIDQ[ wkids] = data1.RF_DIDQ
      
      delvarx, data1
   endif
   
endfor

end
