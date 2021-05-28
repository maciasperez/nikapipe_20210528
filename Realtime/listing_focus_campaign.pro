pro listing_focus_campaign
  
  ;; listing of the focus campaign
  ;;
  ;; Aim of the focus campaign : characterize how the focus evolves
  ;; accross NIKA2 field of view 
  ;;
  ;; 2 focus campaigns were conducted on the 24th and 25th of January
  ;;
  ;; referent person: Jean-Francois Lestrade, Laurence Perotto

  print,"********************************************************"
  print," HOW TO RUN A NEW FOCUS CAMPAIGN "
  print,''
  print,'1/ source selection:'
  print,'------------------------'
  print,'Choose a bright point source of several Jy (e.g. 3C273)'
  print,"PAKO> source 3C273"
  print,"PAKO> track"
  print,"PAKO> start"
  print,''
  print,'2/ pointing correction:'
  print,'------------------------'
  print,'pointing lissajous seems more reliable as the reference pixel is currently (25/01) off-centered'
  print,"PAKO>@nkpoint l"
  print,"PAKO>@nkpoint b"
  print,"     in case of poor fit with a lissajous, try resorting to the 'common_mode_kids_out' method"
  print,"IDL> nk_rta, 'scan', /mask"
  print,"PAKO>set pointing xx yy"
  print,''
  print,'3/ best focus at the array center f_0:'
  print,'----------------------------------------'
  print,"PAKO>offset 0. 0. \sys nasmyth"
  print,"PAKO>@focusOTF"
  print,"     enter 0 as the center focus f. It will run 5 scans at focus f-0.8; f-0.4; f; f+0.4; f+0.8"
  print,"analyse each scan individualy using:"
  print,"IDL> nk_rta, 'scan', /nas"
  print,"     once the 5 scans are reduced, run:"
  print,"IDL> nk_focus_liss_old, '20160125s'+strtrim([1,2,3,4,5], 2), /nas"
  print,''
  print,'4/ best focus across the field-of-view f_{off-center}:'
  print,'--------------------------------------------------------'
  print,"PAKO>offset xoff yoff \sys nasmyth"
  print,"PAKO>@focusOTF"
  print,"     enter 0 as the center focus f."
  print,"     analyse each scan individualy using:"
  print,"IDL> nk_rta, 'scan', /nas, /xyguess, /largemap"
  print,"     once the 5 scans are reduced, run:"
  print,"IDL> nk_focus_liss_old, '20160125s'+strtrim([1,2,3,4,5], 2), /nas, /xyguess"
  print,"     Please keep track of the (xoff, yoff) in TAPAS for easier analysis of the campaign results"
  print,"     the list of nasmyth coordinates to be explored can be read on the A2 printed sheet"
  print,"     In case the focus@1mm and the focus@2mm are very discrepant, the focus exploration bin (-0.8, +0.8) may be not sufficient to fit simultaneously f_1 and f_2. Relaunch using f=<f_2>, the focus@2mm value from the previous focus campaign measurements:"
  print,"PAKO>@focusOTF"
  print,"     enter <f_2> as the center focus f."
  print,''
  print,'5/ monitoring of the focus slow variation:'
  print,'--------------------------------------------------------'
  print,'since we are interested in the difference between f_0 and various f_{off-center}, f_0 should be regularly checked (every point or every other point depending on its stability)'
  print,'re-iterate 3/ from time to time'
  print, ''
  print,"********************************************************"
end
 
