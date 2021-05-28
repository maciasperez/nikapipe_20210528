;+
;PURPOSE: This procedure add the source in the simulated data.
;INPUT: The empty data and the pointing.
;OUTPUT: The data with a source in the TOI
;LAST EDITION: 
;   09/06/2013: Remi ADAM (adam@lpsc.in2p3.fr)
;   27/09/2013: add beam with error beam source (adam@lpsc.in2p3.fr)
;   23/01/2014: remove M500 and change the tSZ simulation to the one
;               used in the MCMC
;-

pro partial_simu_source, param, data, kidpar
  
  N_pt = n_elements(data)
  N_kid = n_elements(kidpar)

  pos_main = [-ten(param.coord_source.ra[0],param.coord_source.ra[1],param.coord_source.ra[2])*15.0 + $    
              ten(param.coord_pointing.ra[0],param.coord_pointing.ra[1],param.coord_pointing.ra[2])*15.0, $ 
              ten(param.coord_source.dec[0],param.coord_source.dec[1],param.coord_source.dec[2]) - $
              ten(param.coord_pointing.dec[0],param.coord_pointing.dec[1],param.coord_pointing.dec[2])]*3600.0
  
  ;;######################### SZ profile ###########################
  if param.caract_source.type eq 'cluster' or param.caract_source.type eq 'cluster+ps' then begin 
     nika_nasmyth2draddec, data.ofs_az, data.ofs_el, data.el, data.paral, 0.0, 0.0, 0., 0., dra, ddec
     beam1mm = param.caract_source.beam.a
     beam2mm = param.caract_source.beam.b
     fov = 2*max([[max(dra)-min(dra)], [max(ddec)-min(ddec)]])
     reso = long(beam1mm/5)
     y2jy1mm = param.kCMBperY.A*param.KRJperKCMB.A*param.JYperKRJ.A
     y2jy2mm = param.kCMBperY.B*param.KRJperKCMB.B*param.JYperKRJ.B
     if param.caract_source.type eq 'cluster' then begin 
        P0 = param.caract_source.P0
        rs = param.caract_source.rs
        alpha = param.caract_source.a
        beta = param.caract_source.b
        gamma = param.caract_source.c
        concentration = param.caract_source.conc
        redshift = param.caract_source.z
     endif
     if param.caract_source.type eq 'cluster+ps' then begin 
        P0 = param.caract_source.cluster.P0
        rs = param.caract_source.cluster.rs
        alpha = param.caract_source.cluster.a
        beta = param.caract_source.cluster.b
        gamma = param.caract_source.cluster.c
        concentration = param.caract_source.cluster.conc
        redshift = param.caract_source.cluster.z
     endif
     profile = partial_simu_szprofile(P0, rs, alpha, beta, gamma, concentration, redshift, $
                                      beam1mm, beam2mm, fov, reso, y2jy1mm, y2jy2mm)
  endif
  
  ;;######################### Cluster lensing  ###########################
  if param.caract_source.type eq 'cluster_lensing' then begin 
     map = simu_clusterlens(param.caract_source, param.map)
  endif
  
  ;;####################################################
  for ikid=0, N_kid-1 do begin
     if kidpar[ikid].type eq 1 then begin
        nika_nasmyth2draddec, data.ofs_az, data.ofs_el, data.el, data.paral, $
                              kidpar[ikid].nas_x, kidpar[ikid].nas_y, $
                              0., 0., dra, ddec, $
                              nas_x_ref=kidpar[ikid].nas_center_X, nas_y_ref=kidpar[ikid].nas_center_Y
        
        case strupcase(param.caract_source.type) of
           
           ;;---------------- Case of the point source
           "POINT_SOURCE":begin
              case kidpar[ikid].array of
                 1: begin
                    flux = param.caract_source.flux.A
                    beam = param.caract_source.beam.A
                 end
                 2:begin
                    flux = param.caract_source.flux.B
                    beam = param.caract_source.beam.B
                 end
              endcase
              source = flux * exp(-((ddec - pos_main[1])^2 + (dra - pos_main[0])^2) / (2*(beam*!fwhm2sigma)^2))
           end

           ;;---------------- Case of the point source + error beam
           "POINT_SOURCE_EB":begin
              case kidpar[ikid].array of
                 1: begin
                    flux = param.caract_source.flux.A
                    beam1 = param.caract_source.beam1.A
                    beam2 = param.caract_source.beam2.A
                    beam3 = param.caract_source.beam3.A
                    amp1 = param.caract_source.amp1.A
                    amp2 = param.caract_source.amp2.A
                    amp3 = param.caract_source.amp3.A
                 end
                 2:begin
                    flux = param.caract_source.flux.B
                    beam1 = param.caract_source.beam1.B
                    beam2 = param.caract_source.beam2.B
                    beam3 = param.caract_source.beam3.B
                    amp1 = param.caract_source.amp1.B
                    amp2 = param.caract_source.amp2.B
                    amp3 = param.caract_source.amp3.B
                 end
              endcase
              source = flux*amp1*exp(-((ddec-pos_main[1])^2+(dra-pos_main[0])^2)/(2*(beam1*!fwhm2sigma)^2)) + $
                       flux*amp2*exp(-((ddec-pos_main[1])^2+(dra-pos_main[0])^2)/(2*(beam2*!fwhm2sigma)^2)) + $
                       flux*amp3*exp(-((ddec-pos_main[1])^2+(dra-pos_main[0])^2)/(2*(beam3*!fwhm2sigma)^2))
           end
           
           ;;---------------- Case of cluster with gNFW model
           "CLUSTER":begin
              case kidpar[ikid].array of
                 1: profile_here = profile.A
                 2: profile_here = profile.B
              endcase
              dist_source = sqrt((ddec - pos_main[1])^2 + (dra - pos_main[0])^2)
              source = interpol(profile_here, profile.r, dist_source)
           end
           
           ;;---------------- Case of cluster with gNFW model + point source
           "CLUSTER+PS":begin
              case kidpar[ikid].array of
                 1: begin
                    flux = param.caract_source.ps.flux.A
                    beam = param.caract_source.beam.A
                    profile_here = profile.A
                 end
                 2:begin
                    flux = param.caract_source.ps.flux.B
                    beam = param.caract_source.beam.B 
                    profile_here = profile.B
                 end
              endcase
              ps = flux*exp(-((ddec-param.caract_source.ps.loc.y)^2 + (dra-param.caract_source.ps.loc.x)^2)/ $
                            (2*(beam*!fwhm2sigma)^2))
              dist_clust = sqrt((ddec - pos_main[1])^2 + (dra - pos_main[0])^2)
              source = interpol(profile_here, profile.r, dist_clust) + ps
           end

           ;;---------------- Case of a disk
           "DISK":begin
              case kidpar[ikid].array of
                 1: flux = param.caract_source.flux.A
                 2: flux = param.caract_source.flux.B
              endcase
              source = ddec*0.0
              d_centre = sqrt((ddec - pos_main[1])^2 + (dra - pos_main[0])^2)
              loc = where(d_centre le param.caract_source.radius, nloc)
              if nloc ne 0 then source[loc] = flux
           end

           ;;---------------- Case of lensing
           "CLUSTER_LENSING":begin        
              case kidpar[ikid].array of
                 1: beam = param.caract_source.beam.A
                 2: beam = param.caract_source.beam.B
              endcase      
              source = simu_map2toi(map, param.map.reso, dra, ddec, lobe_arcsec=beam)
              case kidpar[ikid].array of
                 1: source *= param.KRJperKCMB.A * param.JYperKRJ.A
                 2: source *= param.KRJperKCMB.B * param.JYperKRJ.B
              endcase
           end

           ;;---------------- Case of TOI from existing MAP
           "GIVEN_MAP":begin
              case kidpar[ikid].array of
                 1: begin
                    map = mrdfits(param.caract_source.mapfile1mm, 0, head,/silent)
                    relob = param.caract_source.relob.A
                 end
                 2: begin
                    map = mrdfits(param.caract_source.mapfile2mm, 0, head,/silent)
                    relob = param.caract_source.relob.B
                 end
              endcase
              EXTAST, head, astr
              reso = astr.cdelt[1]*3600
              source = simu_map2toi(map, reso, dra, ddec, lobe_arcsec=relob)
           end

        endcase

        data.RF_dIdQ[ikid] = data.RF_dIdQ[ikid] + source
     endif
  endfor
  
  ;;########################### Include the plateau as a basic cross talk
  if ((param.plateau.A ne 0) and (param.plateau.B ne 0)) then begin
     total_flux_1mm = total(data.RF_dIdQ[where(kidpar.type eq 1 and kidpar.array eq 1)], 1)
     total_flux_2mm = total(data.RF_dIdQ[where(kidpar.type eq 1 and kidpar.array eq 2)], 1)

     for ikid=0, N_kid-1 do begin
        if kidpar[ikid].type eq 1 then begin
           case kidpar[ikid].array of
              1: data.RF_dIdQ[ikid] = data.RF_dIdQ[ikid] + param.plateau.A*total_flux_1mm
              2: data.RF_dIdQ[ikid] = data.RF_dIdQ[ikid] + param.plateau.B*total_flux_2mm
           endcase
        endif
     endfor
  endif

  return
end
