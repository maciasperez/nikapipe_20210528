
pro remove_string
  common ql_maps_common

toi1 = toi_med*0.0d0
for i=0, nkids-1 do toi1[i,*] = toi1[i,*] + coeff[*,i]#toi_med

get_bolo_maps, toi1, x_0, y_0, reso_map, xmap, ymap, kidpar, map_list_out, w8=w8

sigma = 10.0d0
map_list_out_1 = map_list_out   ; init
for ikid=0, nkids-1 do begin
   percent_status, ikid, nkids, 5
   if kidpar[ikid].type eq 1 or kidpar[ikid].type eq 3 then begin
      map = reform( map_list_out[ikid,*,*])
      
      w = where( map eq max(map))
      x0 = (xmap[w])[0]
      y0 = (ymap[w])[0]
      beam = exp( -( (xmap-x0)^2+(ymap-y0)^2)/(2.*sigma^2))

      w = where( beam lt 0.2, nw)
      if nw ne 0 then begin
         s = stddev( map[w])
         mask = map*0.
         mask[w] = 1.
         
         ;; fit string
         w1  = where( beam lt 0.2 and map gt 2*s, nw1)
         if nw1 ne 0 then begin
            fit = linfit( xmap[w1], ymap[w1])
            alpha = -atan(fit[1])

            ;; Rotate map to align with the string and get ipix
            qd_map, x_0, y_0, toi1[ikid,*], reso_map, xmap, ymap, map1, w8=w8, alpha_deg=alpha*!radeg, ipix=ipix

            ;; Determine string profile
            w8_avg          = avg( mask, 0)
            string_prof_avg = avg( mask*map1, 0)/w8_avg
            map2 = map1*0.0d0
            for i=0, nx-1 do map2[i,*] = string_prof_avg

            ;; Subtract string profile from input timeline
            qd_map, x_0, y_0, toi1[ikid,*]-map2[ipix], reso_map, xmap, ymap, map2, w8=w8

            map_list_out_1[ikid,*,*] = map2
            if ikid eq 33 then stop
         endif
      endif
   endif
endfor

map_list_out = map_list_out_1
show_matrix, map_list_out

end
