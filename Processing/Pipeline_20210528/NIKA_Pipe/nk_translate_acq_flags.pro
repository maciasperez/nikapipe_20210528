;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_translate_acq_flags
;
; CATEGORY: ?
;
; CALLING SEQUENCE:
;         nk_translate_acq_flags, data
; 
; PURPOSE: 
;        Translate binary hexadecimal flags from the acquisition
;(tunigs etc...) into named variable for convenience and robustness in
;the pipeline.
;
;        All flag definitions are in NIKA_lib_V2_IRAM/Acquisition/instrument/utils/public_def.h
; 
; INPUT: 
;        - param, info, data, kidpar
; 
; OUTPUT: 
;        - data.tuning_en_cours, data.fpg_change_frequence etc... are changed
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Sept. 19th, 2018: NP
;-

pro nk_translate_acq_flags, param, info, data, kidpar

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_translate_acq_flags, param, info, data, kidpar"
   return
endif

if param.cpu_time then param.cpu_t0 = systime(0, /sec)

if info.status eq 1 then begin
   if param.silent eq 0 then    message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

;; In C, to tell the system that your number is in hexadecimal
;; convention, it starts by '0x'
;;
;; Here Alain uses hexadecimal, that codes numbers on a single
;; digit from 0 (0) to F (16): 0(dec) = 0 (hex), 1=1, ... 9
;; (decimal)=9 (hexadec), 10 (decimal) = A, 11 (decimal) = B, 15
;; (decimal)= F. Then '10' in hexadecimal is 1x16 + 0 = 16.
;; hence FF = 15*16 + 15 = 255

;; Not used in nika2
;; #define     _flag_modulation                    0x03

letters = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', $
           'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U']
nletters = n_elements(letters)
tags = tag_names(data)

case strupcase(!nika.acq_version) of

   "V1": begin
      !nika.fpga_change_frequence_flag = 4B
      !nika.tuning_en_cours_flag       = 8B
      !nika.blanking_synthe_flag       = 2B
   end

   "V2": begin
      !nika.fpga_change_frequence_flag = 16B
      !nika.balayage_en_cours_flag     = 4B
      !nika.tuning_en_cours_flag       = 32B
      !nika.blanking_synthe_flag       = 8B
   end

   "V3": begin
      !nika.fpga_change_frequence_flag = 16B
      !nika.balayage_en_cours_flag     = 4B
      !nika.tuning_en_cours_flag       = 32B
      !nika.blanking_synthe_flag       = 8B
   end

   ;;to try, copy the V1 case
   "ISA": begin
      !nika.fpga_change_frequence_flag = 4B
      !nika.tuning_en_cours_flag       = 8B
      !nika.blanking_synthe_flag       = 2B
   end


   
   else: begin
      txt = "!nika.acq_version = "+!nika.acq_version+" is not valid for this routine, please update"
      message, /info, "!nika.acq_version = "+!nika.acq_version+" is not valid for this routine, please update"
      nk_error, info, txt
      return
   end
endcase

data_tags = tag_names(data)

for ilett=0, nletters-1 do begin
   wtag = where( strupcase(tags) eq letters[ilett]+"_MASQ", nw)
   if nw ne 0 then begin
      ;; #define  _flag_fpga_change_frequence  0x10  /**< flag3 indique le chargement des tones.*/
      w = where( (byte(data.(wtag)) and !nika.fpga_change_frequence_flag) eq !nika.fpga_change_frequence_flag, nw)
      junk = where( strupcase(data_tags) eq strupcase("fpga_change_frequence"), njunk)
      if njunk ne 0 and nw ne 0 then data[w].fpga_change_frequence = 1
      
      ;; #define  _flag_balayage_en_cours  0x04  /**< flag0 ecrit lors du balayage du synthe.*/
      w = where( (byte(data.(wtag)) and !nika.balayage_en_cours_flag) eq !nika.balayage_en_cours_flag, nw)
      junk = where( strupcase(data_tags) eq strupcase("balayage_en_cours_flag"), njunk)
      if njunk ne 0 and nw ne 0 then data[w].balayage_en_cours = 1
      
      ;; #define _flag_tuning_en_cours  0x20 /**< flag4 indique un decalage ou tuning en cours.*/
      w = where( (byte(data.(wtag)) and !nika.tuning_en_cours_flag) and !nika.tuning_en_cours_flag, nw)
      junk = where( strupcase(data_tags) eq strupcase("tuning_en_cours"), njunk)
      if njunk ne 0 and nw ne 0 then data[w].tuning_en_cours = 1
      
      ;; #define _flag_blanking_synthe  0x08  /**< flag1 ecrit lors du balayage du synthe.*/
      w = where( (byte(data.(wtag)) and !nika.blanking_synthe_flag) and !nika.blanking_synthe_flag, nw)
      junk = where( strupcase(data_tags) eq strupcase("blanking_synthe_flag"), njunk)
      if njunk ne 0 and nw ne 0 then data[w].blanking_synthe = 1
   endif
endfor

if param.cpu_time then nk_show_cpu_time, param

end
