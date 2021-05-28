
pro nasm2azel, elevation_rad, ofs_x, ofs_y, ofs_az, ofs_el

alpha = alpha_nasmyth( elevation_rad)

ofs_az = cos(alpha)*ofs_x - sin(alpha)*ofs_y
ofs_el = sin(alpha)*ofs_x + cos(alpha)*ofs_y

end
