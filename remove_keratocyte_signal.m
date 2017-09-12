[fname,pathname] = uigetfile('*.tif');

%%
reader = bfGetReader(fullfile(pathname,fname));

%%
sizeZ = reader.getSizeZ();
sizeC = reader.getSizeC();
sizeX = reader.getSizeX();
sizeY = reader.getSizeY();
sizeT = reader.getSizeT();

%%
for iT = 1:sizeT
    fname = sprintf('kerats_removed/t_%02i.tif',iT);
    savefname = initAppendFile(fullfile(pathname,fname));
    for iZ = 1:sizeZ
        im1 = bf_getFrame(reader,iZ,1,iT);
        im2 = bf_getFrame(reader,iZ,2,iT);
        [~,imBW] = trackingImPreprocessBackgroundSub(im1);
        if sum(imBW(:))>0
            im2(imBW) = 0;
        end
        imwritemulti(im2,savefname);
    end
end


%%
reader = bfGetReader(fullfile(pathname,'test_myosignal_kerats_removed_t1to12_cropped.tif'));
