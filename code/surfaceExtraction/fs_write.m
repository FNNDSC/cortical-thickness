function fs_write( filename, coord, tri)
% coord: N*3
% tri: M*3

v=size(coord,1);
t=size(tri,1);

fid = fopen(filename, 'wb', 'b') ;
magic = 16777214;
b1 = bitand(bitshift(magic, -16), 255) ;
b2 = bitand(bitshift(magic, -8), 255) ;
b3 = bitand(magic, 255) ;
fwrite(fid, [b1 b2 b3], 'uchar') ;
fwrite(fid, ['Created by SurfStat on ' datestr(now) char(10) char(10)], 'char');
fwrite(fid, [v t], 'int32') ;
fwrite(fid, coord', 'float') ;
fwrite(fid, tri'-1, 'int32') ;
fclose(fid);