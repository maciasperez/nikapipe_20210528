
;+
; 
; SOFTWARE: 
;        NIKA pipeline
; 
; NAME:
; nk_show_cpu_time
;
; PURPOSE: 
;        Quick subroutine to display the CPU time used in a routine
;
; Calling sequence:
;        nk_show_cpu_time, param, routine
;
; INPUT: 
;        - param
;        - routine : name of the routine that calls nk_show_cpu_time
; 
; OUTPUT: 
;        - none. A message is printed.
; 
; KEYWORDS:
; 
; MODIFICATION HISTORY: 
;        - July 25th, 2014: (Nicolas Ponthieu -
;          nicolas.ponthieu@obs.ujf-grenoble.fr)
;        - Dec. 8th, 2016: NP: modified so that it determines
;          automatically the routine that calls it.
;-
;====================================================================================================

pro nk_show_cpu_time, param, routine, force=force

if keyword_set(force) then begin
   routine = force
endif else begin
;; ;;-----------------
;;   ;; quick and dirty fix to solve it once for all while not modifying
;;   ;; all the routines that already call it in the old way. NP
;;   ;; Dec. 8th, 2016
   junk = scope_traceback()
   nj   = n_elements(junk)
   j = (nj-2)>0
   routine = (strsplit(file_basename(junk[j]), ".pro", /extract, /regex))[0]
;; ;;--------------
endelse

cpu_t1 = systime( 0, /sec)
print, strupcase(routine)+": CPU time (sec): "+num2string( cpu_t1 - param.cpu_t0)

;; Total time spent in the routine
get_lun, lu
openw, lu, param.cpu_time_summary_file, /append
printf, lu, strupcase(routine)+", "+string(cpu_t1 - param.cpu_t0, form = "(F8.3)")
close, lu
free_lun, lu

;; The previous file notes the time spent in the routine, but it can be confusing when a
;; routine calls multiple subroutines.
;; This file here stores the date when we exit the routine minus the
;; date when we enter nk or nk_rta.
get_lun, lu
openw, lu, param.cpu_date_file, /append
printf, lu, strupcase(routine)+", "+string(cpu_t1-param.cpu_date0, form = "(F8.3)")
close, lu
free_lun, lu



end
