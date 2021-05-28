pro ang_dist, z, h, om, ol, k, Dang

IF n_params() LT 1 THEN BEGIN
   print, 'ang_dist, z, h, omegam, omegal, k (-1, 0 or 1), Dang (en pc)'
   GOTO, closing
ENDIF

; LP: la vitesse de la lumiere c'est c=299792.458 ; km/s (PDG 2008) !!!
c = 3.0d5
;parametre du hubble en km/s/Mpc
h0 = h*100
ok = 1-ol-om

if n_elements(z) eq 1 then begin
    
    if z eq 0.0d0 then begin
        Dang = 0
    endif else begin
        
        nint = 1000l
        u = (dindgen(nint+1)/double(nint))*z+1.0d0
        
        if k eq 0 then begin
            I = int_tabulated(u, 1/sqrt(ol+om*u*u*u))
            Dang = c/h0/(1+z)*I*1.0d6
        endif
        
        if k eq -1 then begin
            I = int_tabulated(u, sin(sqrt(ok)/sqrt(ol-ok*u*u+om*u*u*u)))
            Dang = c/h0/(1+z)/sqrt(ok)*I*1.0d6
        endif
        
        if k eq 1 then begin
            I = int_tabulated(u, sinh(sqrt(abs(ok))/sqrt(ol-ok*u*u+om*u*u*u)))
            Dang = c/h0/(1+z)/sqrt(abs(ok))*I*1.0d6
        endif
    endelse 
    
endif else begin
 
    Dang = z*0
    
    for idx = 0, n_elements(z)-1 do begin
        if z[idx] eq 0.0d0 then begin
            Dang[idx] = 0
        endif else begin
            nint = 1000l
            u = (dindgen(nint+1)/double(nint))*z[idx]+1.0d0
            
            if k eq 0 then begin
                I = int_tabulated(u, 1/sqrt(ol+om*u*u*u))
                Dang[idx] = c/h0/(1+z[idx])*I*1.0d6            
            endif
            
            if k eq -1 then begin
                I = int_tabulated(u, sin(sqrt(ok)/sqrt(ol-ok*u*u+om*u*u*u)))
                Dang[idx] = c/h0/(1+z[idx])/sqrt(ok)*I*1.0d6
            endif
            
            if k eq 1 then begin
                I = int_tabulated(u, sinh(sqrt(abs(ok))/sqrt(ol-ok*u*u+om*u*u*u)))
                Dang[idx] = c/h0/(1+z[idx])/sqrt(abs(ok))*I*1.0d6
            endif
        endelse 
    endfor
    
endelse

closing:
return

end
