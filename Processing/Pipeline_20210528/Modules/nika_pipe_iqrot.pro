pro nika_pipe_iqrot, I, Q, dI, dQ, I_rot, Q_rot, dI_rot, dQ_rot

  n_kid = n_elements(I[*,0])
  N_pt = n_elements(I[0,*])

  ;;Mean phase, amplitude, I and Q per KID
  phi_moy = dblarr(n_kid)
  amp_moy = dblarr(n_kid)

  for ikid = 0, n_kid-1 do begin
     I_moy = mean(I[ikid,*])
     Q_moy = mean(Q[ikid,*])
     phi_moy[ikid] = atan(Q_moy, I_moy)
     amp_moy[ikid] = sqrt(I_moy^2.0 + Q_moy^2.0)
  endfor

  ;;Rotation and normalisation
  I_rot = dblarr(n_kid,N_pt)
  Q_rot = dblarr(n_kid,N_pt)
  dI_rot = dblarr(n_kid,N_pt)
  dQ_rot = dblarr(n_kid,N_pt)

  for ikid = 0, n_kid-1 do begin
     I_rot[ikid,*] = (cos(phi_moy[ikid])*I[ikid,*] + sin(phi_moy[ikid])*Q[ikid,*])/amp_moy[ikid]
     Q_rot[ikid,*] = (-sin(phi_moy[ikid])*I[ikid,*] + cos(phi_moy[ikid])*Q[ikid,*])/amp_moy[ikid]
     dI_rot[ikid,*] = (cos(phi_moy[ikid])*dI[ikid,*] + sin(phi_moy[ikid])*dQ[ikid,*])/amp_moy[ikid]
     dQ_rot[ikid,*] = (-sin(phi_moy[ikid])*dI[ikid,*] + cos(phi_moy[ikid])*dQ[ikid,*])/amp_moy[ikid]
  endfor


end
