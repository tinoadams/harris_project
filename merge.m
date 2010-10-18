%
% Merge the two specified images into one image. Using the given matching
% feature points to transform the first image in an attempt to fit it into
% the second image.
%
function [canvas1 canvas2] = merge(Images, imageIndex1, imageIndex2, refinedMatches)
    %% extract needed information for the two image to be merged
    im1 = Images(imageIndex1).data;
    fa = Images(imageIndex1).fPoints;
    da = Images(imageIndex1).fDesc;
    im2 = Images(imageIndex2).data;
    fb = Images(imageIndex2).fPoints;
    db = Images(imageIndex2).fDesc;

    %% plot matches when a gray scale image is given, check Stich.m
    if ~isempty(Images(imageIndex1).gray)
        figure, plotmatches(Images(imageIndex1).gray, Images(imageIndex2).gray, fa, fb, refinedMatches);
    end

    %% transform the first image to fit into the second one
    xa_refinedMatches = fa(1, refinedMatches(1, :))';
    ya_refinedMatches = fa(2, refinedMatches(1, :))';
    xb_refinedMatches = fb(1, refinedMatches(2, :))';
    yb_refinedMatches = fb(2, refinedMatches(2, :))';

    input_points = [xa_refinedMatches, ya_refinedMatches];
    base_points = [xb_refinedMatches, yb_refinedMatches];
%     tform = cp2tform(input_points, base_points, 'affine');
    tform = cp2tform(input_points, base_points, 'projective');
%     tform = cp2tform(input_points, base_points, 'polynomial');
    [trans xdata ydata] = imtransform(im1, tform);

    %% merge the two images
    [n o b] = size(trans);
    [l m z] = size(im2);
    if(xdata(1)<0)
        xdisp = -xdata(1) + 1;
        xdisp = round(xdisp);

        if(ydata(1)<0)
         ydisp = round(-ydata(1) + 1);
         imgsizex = max(n, l+ydisp-1);
         imgsizey = max(o, m+xdisp-1);

         canvas1 = uint8(zeros(imgsizex, imgsizey, z));
         canvas2 = uint8(zeros(imgsizex, imgsizey, z));

         canvas1(1:(n), 1:o, :) = trans;
         canvas2(ydisp:(l+ydisp-1), xdisp:(m+xdisp-1), :)= im2;

        else
         ydisp = round(1+ydata(1));
         imgsizex = max(n+ydisp-1, l);
         imgsizey = max(o, xdisp+m-1);

         canvas1 = uint8(zeros(imgsizex, imgsizey, z));
         canvas2 = uint8(zeros(imgsizex, imgsizey, z));

         canvas1(ydisp:(ydisp+n-1), 1:(o), :) = trans;
         canvas2(1:(l), xdisp:(xdisp+m-1), :)= im2;

        end    
    else
        xdisp = xdata(1) + 1;
        xdisp = round(xdisp);

        if(ydata(1)<0)
         ydisp = round(-ydata(1) + 1);
         imgsizex = max(n, l+ydisp-1);
         imgsizey = max(o+xdisp-1, m);

         canvas1 = uint8(zeros(imgsizex, imgsizey, z));
         canvas2 = uint8(zeros(imgsizex, imgsizey, z));

         canvas1(1:(n), xdisp:(o+xdisp-1), :) = trans;
         canvas2(ydisp:(ydisp+l-1), 1:(m), :)= im2;

        else
         ydisp = round(1+ydata(1));
         imgsizex = max(n+ydisp-1, l);
         imgsizey = max(o+xdisp-1, m);

         canvas1 = uint8(zeros(imgsizex, imgsizey, z));
         canvas2 = uint8(zeros(imgsizex, imgsizey, z));

         canvas1(ydisp:(n+ydisp-1), xdisp:(xdisp+o-1), :) = trans;
         canvas2(1:(l), 1:(m), :)= im2;

        end    
    end    

