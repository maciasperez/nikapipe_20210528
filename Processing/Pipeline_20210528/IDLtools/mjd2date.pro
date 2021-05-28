FUNCTION MJD2DATE, mjd

;+
; NAME:
;      MJD2DATE
; PURPOSE:
;      convert modified julian day to standard IRAM formatted day
;      
; CALLING SEQUENCE:
;      DATE = MJD2DATE( mjd)
; INPUT:
;	  MJD : decimal value of modified julian day (JD-2450000)
;      
; OUTPUT: example
;   DATE= '2014-02-19T00:44:46.875' ;/ observation start in TIMESYS system
;
; RESTRICTIONS:
;       Same as those of called routine DAYCNV from the astron library
;
; PROCEDURES CALLED:
;       DAYCNV
;
; REVISION HISTORY
;       Written, FXD 2014 June from mjd2datehr (Jacques Delabrouille)
;
;-

DAYCNV, DOUBLE(mjd)+2400000.5d0, year, month, day, hour
hos = sixty( hour)
return, strtrim( year, 2)+'-'+zeropadd( month, 2)+'-'+ zeropadd( day, 2)+ $
       'T'+zeropadd( fix( hos[0]), 2)+':'+zeropadd( fix(hos[1]), 2)+':'+ $
       zeropadd( string( hos[2], format = '(F6.3)'), 6)
END





