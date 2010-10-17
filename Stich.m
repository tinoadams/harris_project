function Stich(directory, resize)
    clc
    directory = 'imageSet1/';
    resize = 1;
%     directory = 'imageSet2/';
%     resize = .25;
%     directory = 'imageSet3/';
%     resize = .25;

    %% Read all files and produce initial set of feature points and descriptors
    files = dir([directory '*.jpg']);
    Images = struct('name', [], 'data', [],'gray', [], 'fPoints', [], 'fDesc', []);
    for i = 1 : numel(files)
        Images(i).name = [directory files(i).name];
        Images(i).data = imresize(imread(Images(i).name), resize);
        [Images(i).gray Images(i).fPoints Images(i).fDesc] = newImage(Images(i).data);
    end

    %% Stich images until no more pairs are left
    numImages = length(Images);
    numStiched = 0;
    while numImages > 1
        %% find best matches amongst all images
        bestMatch = bestmatches(Images);

        %% use the first match (highest correspondence to another image)
        imageIndex1 = bestMatch(1).image;
        imageIndex2 = bestMatch(1).bestMatch;
        % check if we found an appropriate match
        if (imageIndex2 > 0)
            fprintf('Stiching images "%s" and "%s"\n',...
                Images(imageIndex1).name, Images(imageIndex2).name);
%             bestTranformInLierCount = bestMatch(1).bestTranformInLierCount
%             bestTranform = bestMatch(1).bestTranform
            refinedMatches = bestMatch(1).refinedMatches
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
function [gray fPoints fDesc] = newImage(data)
    if (size(data, 3) > 2)
        gray = rgb2gray(data);
    else
        gray = data;
    end
    
    % calculate sift feature points and descriptors
    [fPoints fDesc] = vl_sift(single(gray));

%
% Returns a structure with information about which of the given images
% have good correspondences in terms of descriptor matches after RANSAC.
%
function bestMatch = bestmatches(Images)
    bestMatch = struct('bestMatch', 0, 'image', 0, 'count', 0,...
        'bestTranformInLierCount', [], 'bestTranform', [],...
        'refinedMatches' ,[]);
    for i = 1:length(Images) - 1
        bestMatch(i).image = i;
        bestMatch(i).count = 0;
        for j = i + 1:length(Images)
            [bestTranformInLierCount bestTranform refinedMatches] = ransac( ...
                Images(i).fPoints, Images(i).fDesc ...
                ,Images(j).fPoints, Images(j).fDesc ...
            );
            if (bestTranformInLierCount > bestMatch(i).count)
                bestMatch(i).bestMatch = j;
                bestMatch(i).count = bestTranformInLierCount;
                bestMatch(i).bestTranformInLierCount = bestTranformInLierCount;
                bestMatch(i).bestTranform = bestTranform;
                bestMatch(i).refinedMatches = refinedMatches;
            end
        end
    end
    
    [values,index] = sort([bestMatch.count], 'descend');
    bestMatch = bestMatch(index);
    
function image = blend(canvas1, canvas2)
    canvassub = imsubtract(canvas1, canvas2);
%     canvassub = canvas1;
%     figure,imshow(canvas1);
%     figure,imshow(canvas2);
%     figure,imshow(canvassub);
%             [imgSizeX imgSizeY] = size(canvas1);
%             combImage = uint8(zeros(imgSizeX, imgSizeY, size(images(imageIndex1).data, 3)));
    image = imadd(canvassub,canvas2);

