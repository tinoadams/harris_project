function Stitch(directory, resize)
    clc
    directory = 'imageSet1/';
    resize = 1;
    directory = 'imageSet3/';
    resize = .25;
%     directory = 'Abbey/';
%     resize = .75;
%     directory = 'Ali1/';
%     resize = .5;

    %% Read all files and produce initial set of feature points and descriptors
    files = dir([directory '*.jpg']);
    Images = struct('name', [], 'data', [],'gray', [], 'fPoints', [], 'fDesc', []);
    for i = 1 : numel(files)
        Images(i).name = [directory files(i).name];
%         Images(i).data = imresize(imread(Images(i).name), resize);
%         [Images(i).gray Images(i).fPoints Images(i).fDesc] = newImage(Images(i).data);
        data = imresize(imread(Images(i).name), resize);
        [Images(i).gray Images(i).fPoints Images(i).fDesc] = newImage(Images(i).name, data);
    end
    data = [];

    %% Stitch images until no more pairs are left
    numImages = length(Images);
    numStitched = 0;
    while numImages > 1
        %% find best matches amongst all images
        bestMatch = bestMatches(Images);

        %% use the first match (highest correspondence to another image)
        imageIndex1 = bestMatch(1).image;
        imageIndex2 = bestMatch(1).bestMatch;

        %% check if we found an appropriate match
        if (imageIndex2 > 0)
            fprintf('Stitching images "%s" and "%s"\n',...
                Images(imageIndex1).name, Images(imageIndex2).name);
            if (isempty(Images(imageIndex1).data))
                Images(imageIndex1).data = imresize(imread(Images(imageIndex1).name), resize);
            end
            if (isempty(Images(imageIndex2).data))
                Images(imageIndex2).data = imresize(imread(Images(imageIndex2).name), resize);
            end
            [canvas1 canvas2] = merge(Images, imageIndex1, imageIndex2, bestMatch(1).refinedMatches);
            combImage = blend(canvas1, canvas2);
        else
            fprintf('No match found for image "%s"\n', Images(imageIndex1).name);
        end    
        
        %% remove merged images and add stitched image
        Images(imageIndex1) = [];
        numImages = numImages - 1;
        if (imageIndex2 > 0)
            Images(imageIndex2 - 1) = [];

            % add resulting image to set
            numStitched = numStitched + 1;
            i = numImages;
            Images(i).name = sprintf('stitched %d', numStitched);
            Images(i).data = combImage;
            [Images(i).gray Images(i).fPoints Images(i).fDesc] = newImage(Images(i).name, combImage);
        end
    end

    % The last image in the set is the final stitch
    figure, imshow(Images(numImages).data);

%
% Find feature points and descriptor for given image
%
function [gray fPoints fDesc] = newImage(name, data)
    %% Convert image data into gray scale if possible
    if (size(data, 3) > 2)
        gray = rgb2gray(data);
    else
        gray = data;
    end
    
    %% calculate sift feature points and descriptors
    [fPoints fDesc] = vl_sift(single(gray));
    fprintf('Loading image "%s" with %d SIFT features\n', name, size(fPoints, 2));
    % comment the next line to plot the RANSAC matches in merge.m
    gray = [];
 
function image = blend(canvas1, canvas2)
    canvassub = imsubtract(canvas1, canvas2);
%     canvassub = canvas1;
%     figure,imshow(canvas1);
%     figure,imshow(canvas2);
%     figure,imshow(canvassub);
%             [imgSizeX imgSizeY] = size(canvas1);
%             combImage = uint8(zeros(imgSizeX, imgSizeY, size(images(imageIndex1).data, 3)));
    image = imadd(canvassub,canvas2);