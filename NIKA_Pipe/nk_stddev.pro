;$Id: //depot/Release/ENVI50_IDL82/idl/idldir/lib/stddev.pro#1 $
;
; Copyright (c) 1997-2012, Exelis Visual Information Solutions, Inc. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;       NK_STDDEV
;
; PURPOSE:
;       This function computes the standard deviation of an N-element vector.
;
; CATEGORY:
;       Statistics.
;
; CALLING SEQUENCE:
;       Result = stddev(X)
;
; INPUTS:
;       X:      An N-element vector of type integer, float or double.
;
; KEYWORD PARAMETERS:
;       DIMENSION: Set this keyword to a scalar indicating the dimension
;         across which to calculate the stddev. If this keyword is not
;         present or is zero, then the stddev is computed across all
;         dimensions of the input array. If this keyword is present,
;         then the stddev is only calculated only across a single dimension.
;         In this case the result is an array with one less dimension
;         than the input.
;       DOUBLE: IF set to a non-zero value, computations are done in
;               double precision arithmetic.
;       NAN:    If set, treat NaN data as missing.
;
; EXAMPLE:
;       Define the N-element vector of sample data.
;         x = [65, 63, 67, 64, 68, 62, 70, 66, 68, 67, 69, 71, 66, 65, 70]
;       Compute the standard deviation.
;         result = stddev(x)
;       The result should be:
;       8.16292
;
; PROCEDURE:
;       STDDEV calls the IDL function MOMENT.
;
; REFERENCE:
;       APPLIED STATISTICS (third edition)
;       J. Neter, W. Wasserman, G.A. Whitmore
;       ISBN 0-205-10328-6
;
; MODIFICATION HISTORY:
;       Written by:  GSL, RSI, August 1997
;       CT, Dec 2009: (from J. Bailin) Added DIMENSION keyword.
;       FXD, add the flag keyword (used only for nika2). Flag=0 is
;retained valued
;-
function NK_STDDEV, X, DIMENSION=dim, DOUBLE = Double, NAN = NaN, flag = flag

  compile_opt idl2, hidden
  ON_ERROR, 2
if not keyword_set( flag) then begin
   return, sqrt( nk_variance( x, dimension = dim, $
                              double = double, nan = nan))
endif else begin ; force double and nan in that case
   a = double( x)
   u = where( flag ne 0, nu)
   if nu ne 0 then a[ u] = !values.d_nan
   return, sqrt( nk_variance( a, dimension = dim, $
                              /double, /nan))
endelse

END
