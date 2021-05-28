;+
pro nk_get_info_tag, info, nickname, array, wtag, wtag_err
;-
if n_params() lt 1 then begin
   dl_unix, 'nk_get_info_tag'
   return
endif
  
info_tags = tag_names(info)

wtag     = where( strupcase(info_tags) eq strupcase(nickname), nwtag)
wtag_err = where( strupcase(info_tags) eq strupcase("err_"+nickname))
if nwtag eq 0 then begin
   tag = nickname+"_"+strtrim(array,2)
   wtag     = where( strupcase(info_tags) eq strupcase(tag), nwtag)
   wtag_err = where( strupcase(info_tags) eq strupcase('result_err_'+nickname+"_"+strtrim(array,2)), nwtag_err)
   if nwtag eq 0 then begin
      tag = nickname+strtrim(array,2)
      wtag     = where( strupcase(info_tags) eq strupcase(tag), nwtag)
      wtag_err = where( strupcase(info_tags) eq strupcase('result_err_'+nickname+strtrim(array,2)), nwtag_err)
      if nwtag eq 0 then begin
         tag = "result_"+nickname
         wtag     = where( strupcase(info_tags) eq strupcase(tag), nwtag)
         wtag_err = where( strupcase(info_tags) eq strupcase('result_err_'+nickname), nwtag_err)
         if nwtag eq 0 then begin
            tag = "result_"+nickname+strtrim(array,2)
            wtag     = where( strupcase(info_tags) eq strupcase(tag), nwtag)
            wtag_err = where( strupcase(info_tags) eq strupcase('result_err_'+nickname+strtrim(array,2)), nwtag_err)
            if nwtag eq 0 then begin
               tag = "result_"+nickname+"_"+strtrim(array,2)
               wtag = where( strupcase(info_tags) eq strupcase(tag), nwtag)
               wtag_err = where( strupcase(info_tags) eq strupcase('result_err_'+nickname+"_"+strtrim(array,2)), nwtag_err)
               if nwtag eq 0 then begin
                  tag = "result_"+nickname
                  wtag     = where( strupcase(info_tags) eq strupcase(tag), nwtag)
                  wtag_err = where( strupcase(info_tags) eq strupcase('result_err_'+nickname), nwtag_err)
               endif
            endif
         endif
      endif
   endif
endif
end
