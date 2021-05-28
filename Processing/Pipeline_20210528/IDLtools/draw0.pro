
pro draw0, col=col, _extra=_extra

  oplot, [0,0], [-1,1]*1e20, col=col, _extra=_extra
  oplot, [-1,1]*1e20, [0,0], col=col, _extra=_extra
end
