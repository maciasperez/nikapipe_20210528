;+
; 
; SOFTWARE: 
;        NIKA pipeline
;
; NAME:
; nk_low_level_proc
; 
; PURPOSE: 
;        Read the raw data
; 
; INPUT: 
;        - param: the parameter structure
;        - info: the information structure
;        - data: the nika data structure
;        - kidpar: the kid info structure
;        - amp_modulation: modulation amplitude as given by read_nika_brute
; 
; OUTPUT: 
;        - data: the data structure
;        - kidpar: the KID parameter structure
; 
; KEYWORDS:
; 
; MODIFICATION HISTORY: 
;        - March 2014: Remi Adam & Nicolas Ponthieu
;-
;====================================================================================================

pro nk_low_level_proc, param, info, data, kidpar, amp_modulation, plot=plot

if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

if param.cpu_time then param.cpu_t0 = systime( 0, /sec)

;;------- Flag based on kid type 
loc2 = where(kidpar.type eq 2, nloc2)
loc3 = where(kidpar.type ge 3, nloc3)
if nloc2 ne 0 then nk_add_flag, data, 1, wkid=loc2
if nloc3 ne 0 then nk_add_flag, data, 6, wkid=loc3

;;----------Are we in november 2012? If yes add the ampli modulation
if strmid( string( param.day, format="(I8.8)"), 0, 6) eq '201211' then begin
   the_struc = {amp_mod:0}
   upgrade_struct, kidpar, the_struc, kidpar_bis
   w = where(kidpar.array eq 1, nw)
   if nw ne 0 then kidpar_bis[w].amp_mod = amp_modulation[0]
   w = where(kidpar.array eq 2, nw)
   if nw ne 0 then kidpar_bis[w].amp_mod = amp_modulation[1]
   kidpar = kidpar_bis
endif

if param.cpu_time then nk_show_cpu_time, param, "nk_low_level_proc"

end
