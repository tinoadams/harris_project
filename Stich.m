function Stich(directory, resize)
    clc
    directory = 'imageSet1/';
    resize = 1;
%     directory = 'imageSet2/';
%     resize = .25;
%     directory = 'Abbey/';
%     resize = .75;

    %% Read all files and produce initial set of feature points and descriptors
    files = dir([directory '*.jpg']);
    Images = struct('name', [], 'data', [],'gray', [], 'fPoints', [], 'fDesc', []);
    for i = 1 : numel(files)
        Images(i).name = [directory files(i).name];
%         Images(i).data = imresize(imread(Images(i).name), resize);
%         [Images(i).gray Images(i).fPoints Images(i).fDesc] = newImage(Images(i).data);
        data = imresize(imread(Images(i).name), resize);
        [Images(i).gray Images(i).fPoints Images(i).fDesc] = newImage(data);
    end
    data = [];
    gray = [];

    %% Stich images until no more pairs are left
    numImages = length(Images);
    numStiched = 0;
    while numImages > 1
        %% find best matches amongst all images
        bestMatch = bestMatches(Images);

        %% use the first match (highest correspondence to another image)
        imageIndex1 = bestMatch(1).image;
        imageIndex2 = bestMatch(1).bestMatch;

        %% check if we found an appropriate match
        if (imageIndex2 > 0)
            fprintf('Stiching images "%s" and "%s"\n',...
                Images(imageIndex1).name, Images(imageIndex2).name);
            refinedMatches = bestMatch(1).refinedMatches
            if (isempty(Images(imageIndex1).data))
                Images(imageIndex1).data = imresize(imread(Images(imageIndex1).name), resize);
            end
            if (isempty(Images(imageIndex2).data))
                Images(imageIndex2).data = imresize(imread(Images(imageIndex2).name), resize);
            end
            [canvas1 canvas2] = merge(Images, imageIndex1, imageIndex2, refinedMatches);
            combImage = blend(canvas1, canvas2);
            
            numStiched = numStiched + 1;
        else
            fprintf('No match found for image "%s"\n', Images(imageIndex1).name);
        end    
        
        %% remove merged images
        Images(imageIndex1) = [];
        numImages = numImages - 1;
        if (imageIndex2 > 0)
            Images(imageIndex2 - 1) = [];

            % add resulting image to set
            i = numImages;
            Images(i).name = ['stiched ' numStiched];
            Images(i).data = combImage;
            [Images(i).gray Images(i).fPoints Images(i).fDesc] = newImage(combImage);
        end
    end

    % The last image in the set is the final stich
    figure, imshow(Images(numImages).data);

%
% Find feature points and descriptor for given image
%
function [gray fPoints fDesc] = newImage(data)
    %% Convert image data into gray scale if possible
    if (size(data, 3) > 2)
        gray = rgb2gray(data);
    else
        gray = data;
    end
    
    %% calculate sift feature points and descriptors
    [fPoints fDesc] = vl_sift(single(gray));
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