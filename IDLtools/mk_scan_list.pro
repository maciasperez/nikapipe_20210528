FUNCTION mk_scan_list, index_begin, index_end, index_step, exclude= exclude
;+
; NAME: MK_SCAN_LIST
;
;
;
; PURPOSE:
; make a list from index_begin to index_end with optional index_step
; exclude few numbers from that list
; useful to select scans in IRAM or POM2 list
;
;
;
; CATEGORY: tools
;
;
;
; CALLING SEQUENCE:
;   out= mk_scan_list(index_begin, index_end [, index_step, exclude=
;    exclude])
;
; 
; INPUTS:
;   index_begin, index_end  ; two integers or long
;
;
;
; OPTIONAL INPUTS:
;   index_step :   integer 1 or more
;
;
;	
; KEYWORD PARAMETERS:
;   exclude  : vector of long
;
;
;
; OUTPUTS:
;   out    : vector of long
;
;
;
; OPTIONAL OUTPUTS:
;
;
;
; COMMON BLOCKS:
;
;
;
; SIDE EFFECTS:
;
;
;
; RESTRICTIONS:
;
;
;
; PROCEDURE:
;
;
;
; EXAMPLE:
;    list_scan= MK_SCAN_LIST(7312, 7327, exclude= [7314, 7326] )
; IDL> print, list_scan
;        7312        7313        7315        7316        7317        7318
;        7319        7320        7321        7322        7323        7324
;        7325        7327
;
;
; MODIFICATION HISTORY:
; FXD Sep 98
;
;-
;-----------------------------------------------------------
; common blocks 
;-----------------------------------------------------------
 COMMON SESSION_BLOCK, SESSION_MODE, ERROR_CURRENT, STATUS_BOOL 
;-----------------------------------------------------------
; on error conditions
;-----------------------------------------------------------
  ON_ERROR, ERROR_CURRENT
  
;-----------------------------------------------------------
; initialization
;-----------------------------------------------------------
 ROUTINE_NAME = 'MK_SCAN_LIST'
 VERSION = '1.0'
 CATEGORY='?'
 STATUS = ['SUCCESS', 'S', ROUTINE_NAME + ' V.' + VERSION, CATEGORY] 

;-----------------------------------------------------------
; parameters check
;-----------------------------------------------------------
list= -1 
 IF N_PARAMS() LT 2 THEN BEGIN
   PRINT, 'CALLING SEQUENCE: ', $
          ' out= mk_scan_list(index_begin, index_end [, index_step, exclude='
   PRINT, '                     exclude])'
   STATUS(0) = ['PARAMETER MISSING', 'E']
   GOTO, CLOSING
 ENDIF
 
if n_params() eq 2 then index_step = 1
list= index_begin+ $
         index_step* lindgen( long((index_end- index_begin)/ index_step)+ 1)

IF KEYWORD_SET( exclude) THEN BEGIN
  nex= N_ELEMENTS( exclude)
  FOR iex= 0, nex- 1 DO BEGIN
    u= WHERE( list EQ exclude( iex), nu)
    IF nu EQ 0 THEN PRINT, ' W - This scan is not in the list ', exclude( iex)
    IF nu NE 0 THEN BEGIN
       v= WHERE( list NE exclude( iex), nv)
       list= list[ v]
    ENDIF
  ENDFOR 
ENDIF

;-----------------------------------------------------------
; closing
;-----------------------------------------------------------

 CLOSING:
 IF (STRMID(STATUS(1),0,1) NE 'S') THEN $
    PRINT, STATUS(2),' - ', STATUS(1), ' - ', STATUS(0)
 
 RETURN, list
 
 END
