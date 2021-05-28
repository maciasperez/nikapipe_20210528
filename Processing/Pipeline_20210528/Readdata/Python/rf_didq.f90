!!$
!!$  Module to transform I,Q, dI and dQ into kid resonance frequency estimate
!!$  Compile using : f2py -c -m kidreso rf_didq.f90 
!!$
module kidreso
  contains

!!$    
!!$ Subroutine to compute RF_DIDQ following Calvo et al. and R. Adam's IDL code 
!!$

  subroutine test()
    print*, "HELLO"    

  end subroutine test

 !!$ RF_didq 
  subroutine rf_didq(delta_f, nkids, nsamples, I, Q, dI,dQ, rf)
    implicit none
    real(8), intent(in) :: delta_f
    !f2py intent(in) :: delta_f
    real(8), intent(in), dimension(0:nkids-1,0:nsamples-1) :: I, Q, dI,dQ 
    integer(4), intent(in) :: nkids, nsamples
    !f2py intent(in) :: I,Q,dI,dQ
    !f2py integer intent(hide), depend(I) :: nkids=shape(I,0), nsamples=shape(I,1)
   
    real(8), intent(inout), dimension(0:nkids-1,0:nsamples-1) :: rf
    !f2py intent(in,out) :: rf

    real(8), dimension(:), allocatable :: dIsm, dQsm
    real(8) :: delta_I,delta_Q

    integer(4) :: idx, jdx

    allocate(dIsm(0:nsamples-1),dQsm(0:nsamples-1))
       
    rf = 0.0
    do idx=0,nkids-1
       call smooth(dI(idx,0:),101,dIsm)
       call smooth(dQ(idx,0:),101,dQsm)

       do jdx=1,nsamples-1
          delta_I = I(idx,jdx)-I(idx,jdx-1)
          delta_Q = Q(idx,jdx)-Q(idx,jdx-1)
          
          rf(idx,jdx)  = rf(idx,jdx-1) + delta_f* (delta_I * dIsm(jdx-1) + &
          delta_Q * dQsm(jdx-1))/(dIsm(jdx-1) * dIsm(jdx-1) + dQsm(jdx-1) *dQsm(jdx-1))
       end do
       
       !! shift rf_didq
       do jdx = 0, nsamples - 50
          rf(idx,jdx) = rf(idx,jdx+50)
       enddo

    end do

    return
  end subroutine rf_didq

  subroutine smooth(data,nsmooth, datasm)
    implicit none 
    integer(4), intent(in) :: nsmooth
    real(8), intent(in), dimension(0:) :: data
    real(8), intent(out), dimension(0:) :: datasm
    integer(4) :: idx, ndata, begidx, endidx,npts

    ndata = size(data)
    do idx=0, ndata-1
       begidx = idx - nsmooth/2
       if (begidx < 0) begidx = 0
       endidx = idx + nsmooth/2
       if (endidx > ndata-1) endidx = ndata-1
       npts = endidx -begidx +1
       datasm(idx) = sum(data(begidx:endidx))/real(npts)
    end do 
  end subroutine smooth

end module kidreso

!!$ Original IDL version from R. Adam
!!$pro my_iq2rfdidq, df, I, Q, dI, dQ, RFdIdQ
!!$  
!!$  N_pt = n_elements(I[0,*])
!!$  n_kid = n_elements(I[*,0])
!!$    
!!$  RFdIdQ = dblarr(n_kid, N_pt)
!!$
!!$  for ikid=0, n_kid-1 do begin
!!$
!!$     moy_dI = smooth(dI[ikid,*],101)
!!$     moy_dQ = smooth(dQ[ikid,*],101)
!!$   
!!$     for m=0ll, N_pt-1 do begin
!!$
!!$;     if m lt 50 then begin                    ;On fait une dérivé glissante en moyennant sur 101 point autour du point considere
!!$;        moy_dI = total(dI[0:m+50])/(m+51) ;cas ou la valeur considérée est < 50: on moyenne sur moins de 51 a 101 point
!!$;        moy_dQ = total(dQ[0:m+50])/(m+51)
!!$;     endif
!!$;     if (m ge 50 and m le N_pt-51) then begin
!!$;        moy_dI = total(dI[m-50:m+50])/101 ;Tout va bien il y a assez de points pour sommer
!!$;        moy_dQ = total(dQ[m-50:m+50])/101
!!$;     endif
!!$;     if m gt N_pt-51 then begin
!!$;        moy_dI = total(dI[m-50:N_pt-1])/(50+N_pt-m) ;cas ou la valeur considérée est > N_pt-50: on moyenne sur moins de 101 a 51 point
!!$;        moy_dQ = total(dQ[m-50:N_pt-1])/(50+N_pt-m)
!!$;     endif
!!$
!!$        if (m eq 0) then delta_I = 0d else delta_I = I[ikid,m] - I[ikid,m-1]
!!$        if (m eq 0) then delta_Q = 0d else  delta_Q = Q[ikid,m] - Q[ikid,m-1]
!!$
!!$        if (m eq 0) then RFdIdQ[ikid,m] = 0d else RFdIdQ[ikid,m] = RFdIdQ[ikid,m-1] + df * (delta_I*moy_dI[m-1] + delta_Q*moy_dQ[m-1])/(moy_dI[m-1]^2.0 + moy_dQ[m-1]^2.0)
!!$     endfor
!!$     
!!$     RFdIdQ[ikid,*] = shift(RFdIdQ[ikid,*], 49)
!!$
!!$  endfor
!!$
!!$end
