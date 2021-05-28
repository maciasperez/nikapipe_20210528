pro nika_printlog, a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, $
              a13, a14, a15, a16, a17, a18, a19, $
              silent= silent, screenonly=screenonly
; Print on screen and on logfile
; /silent means: print only on logfile and not on screen
; /screeonly means: print on screen only
;------------------------------------------------------------
; common blocks 
;------------------------------------------------------------
 
; environment parameters 
 COMMON SESSION_BLOCK, SESSION_MODE, ERROR_CURRENT, STATUS_BOOL
 
;------------------------------------------------------------
; on error conditions
;------------------------------------------------------------
 ON_ERROR,  ERROR_CURRENT
 
;------------------------------------------------------------
; initialization
;------------------------------------------------------------
 
 ROUTINE_NAME = 'NIKA_PRINTLOG'
 VERSION = '1.0' 
 CATEGORY = 'III-5-c'  ; ?
 STATUS = ['SUCCESS', 'S', ROUTINE_NAME+ ' V.' + VERSION, CATEGORY]
 
;------------------------------------------------------------
; parameters check
;------------------------------------------------------------
 
 IF N_PARAMS() LT 1 THEN BEGIN
   PRINT, 'CALLING SEQUENCE: ', $ 
    'nika_printlog, a0, a1,...a19, /silent'
   STATUS(0) = ['PARAMETER MISSING', 'E']
   GOTO, CLOSING
 ENDIF

npr= n_params()
COMMAND= ' '
for ipr= 0, npr- 1 do command= command+ ', a'+ strtrim(ipr, 2)

if npr ne 0 then begin
  pr_command= 'print'+ command
  if not keyword_set( silent) then b= execute(pr_command)
  log_command='info2_logfile'+ command
  if not keyword_set( screenonly) then b= execute(log_command)
endif

CLOSING:
IF (STRMID(STATUS(1),0,1) NE 'S') THEN print, status
 
return
end  
