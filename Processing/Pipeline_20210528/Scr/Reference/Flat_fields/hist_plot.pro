PRO HIST_PLOT, DATA, MIN=MIN_VALUE, MAX=MAX_VALUE, noplot=noplot, $
               BINSIZE=BINSIZE, NORMALIZE=NORMALIZE, dostat=dostat, fitgauss=fitgauss, FILL=FILL, $
               X=X,Y=Y, HIST=HIST, _EXTRA=EXTRA_KEYWORDS

;- Check arguments
if n_params() ne 1 then message, 'Usage: HIST_PLOT, DATA'
if n_elements(data) eq 0 then message, 'DATA is undefined'

;- Check keywords

if n_elements(min_value) eq 0 then min_value = min(data)
if n_elements(max_value) eq 0 then max_value = max(data)
if n_elements(binsize) eq 0 then $
  binsize = (max_value - min_value) * 0.01
binsize = binsize > ((max_value - min_value) * 1.0e-5)

;- Compute histogram
hist = histogram(float(data), binsize=binsize, $
  min=min_value, max=max_value)


hist = [hist, 0L]
nhist = n_elements(hist)

;- Normalize histogram if required
if keyword_set(normalize) then $
  hist = hist / float(n_elements(data))

;- Compute bin values
bins = lindgen(nhist) * binsize + min_value

;- Create plot arrays
;x = make_array(2 * nhist,/float)
x = fltarr(2 * nhist)
x[2 * lindgen(nhist)] = bins
x[2 * lindgen(nhist) + 1] = bins

y = fltarr(2 * nhist)
;y = make_array(2 * nhist,/float)

y[2 * lindgen(nhist)] = hist
y[2 * lindgen(nhist) + 1] = hist
y = shift(y, 1)

;- Plot the histogram

if not keyword_set(noplot) then plot, x, y, _extra=extra_keywords

if keyword_set(dostat) then begin

   
gpar=fltarr(3)

sum=total(hist)
GPAR[0]=float(SUM[0])

mom=moment(data,sdev=sdev)

GPAR[1]=float(mom[0])
GPAR[2]=float(sdev)

print, "mean = ", gpar[1]
print, "med  = ", median(data)

GPAR[1]=float(median(data))

if keyword_set(fitgauss) then begin
   binCenters = bins + (binsize / 2.0)
   yfit = GaussFit(bincenters, hist, GPAR, NTERMS=3)
endif



; trace la gaussienne
gauss = exp(-1.*(x - GPAR[1])^2/2./GPAR[2]^2)*max(hist);/GPAR[2]/sqrt(2.*!dpi)

oplot,x,gauss,color=50

legendastro,['N='+string(sum), $
             'm='+string(gpar[1]), $
             'RMS='+string(gpar[2])],/right,/top,/trad


endif


;- Fill the histogram if required
if keyword_set(fill) then $
  polyfill, [x, x[0]], [y, y[0]], _extra=extra_keywords


END
