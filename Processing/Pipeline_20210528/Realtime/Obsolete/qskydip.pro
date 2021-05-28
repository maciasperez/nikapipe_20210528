pro qskydip, day, scan_num, save = save

skydip,!nika.run,day,scan_num,skydip_res1,skydip_res2,sav=0;,/test
;
path = !nika.off_proc_dir
if keyword_set(save) then save,filename=path + '/Run'+!nika.run+'_calib_skydip'+day+'.save',skydip_res1,skydip_res2

end
