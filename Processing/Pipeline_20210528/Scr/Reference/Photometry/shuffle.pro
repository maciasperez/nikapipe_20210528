function shuffle, array
  
  na = n_elements(array)
  arr = array
  for i= 0, na-1 do begin
     ind = na-1-i
     toswap = arr[ind]
     pos = long(ind*randomu(seed))
     ;;print, pos
     arr[ind] = arr[pos]
     arr[pos] = toswap
     
  endfor

  array=arr
  return, array
end
