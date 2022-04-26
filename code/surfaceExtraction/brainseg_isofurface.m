function brainseg_isofurface(seg, seglabel, output, varargin)

smooth_param=3;
isothres=0.5;

for i=1:length(varargin)
    smooth_param=varargin{1};
    isothres=varargin{2};
end

rawhdr=load_nifti_hdr(seg); 
segvol=load_nifti(seg);

binvol=segvol.vol; 
binvol(:,:,:)=0;
for i=seglabel
    binvol(segvol.vol==i)=1;
end

svol=smooth3(binvol,'box',smooth_param);  
fv=isosurface(svol,isothres);

coordvox=fv.vertices(:,[2 1 3]);        
coordras=rawhdr.vox2ras*[(coordvox-1)'; ones(1,size(coordvox,1))];

fs_write(output, coordras(1:3,:)',fv.faces);   

