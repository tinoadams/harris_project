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
        [gray Images(i).fPoints Images(i).fDesc] = newImage(data);
    end
    data = [];
    gray = [];

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
    bestMatch = struct('bestMatch', 0, 'image', 0, 'count', 0, 'numMatches', 0,...
        'bestTranformInLierCount', [], 'bestTranform', [],...
        'refinedMatches' ,[]);
    pm1 = 0.000001;
    pm0 = 1 - pm1;
    pMin = 0.999;
    min = 1 / ((1 / pMin) - 1)
    p1 = 0.6
    p0 = 0.1;

    alpha = 8;
    beta = 0.3;
    %% Match each image with the following images in the set and record the
    %% best corresponding image in terms of feature matches after RANSAC.
    for i = 1:length(Images) - 1
        bestMatch(i).image = i;
        bestMatch(i).count = 0;
        for j = i + 1:length(Images)
            %% Match features and find RANSAC inliners
            [bestTranformInLierCount bestTranform refinedMatches numMatches] = ransac( ...
                Images(i).fPoints, Images(i).fDesc ...
                ,Images(j).fPoints, Images(j).fDesc ...
            );
            %% Update the best match if we found a better correspondence
            if (bestTranformInLierCount > bestMatch(i).count)
                bestMatch(i).bestMatch = j;
                bestMatch(i).count = bestTranformInLierCount;
                bestMatch(i).bestTranformInLierCount = bestTranformInLierCount;
                bestMatch(i).numMatches = numMatches;
                bestMatch(i).bestTranform = bestTranform;
                bestMatch(i).refinedMatches = refinedMatches;
            end
        end
        pf1 = prob(bestTranformInLierCount, numMatches, p1) * pm1;
        pf0 = prob(bestTranformInLierCount, numMatches, p0) * pm0;
        pf1 / pf0
        bestTranformInLierCount = bestMatch(i).bestTranformInLierCount
        threshold = alpha + beta * bestMatch(i).numMatches
        if (bestTranformInLierCount < threshold)
            fprintf('Dismiss match based on low probability "%s" -> "%s"\n',...
                Images(i).name, bestMatch(i).bestMatch);
            bestMatch(i).bestMatch = 0;
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

function B = prob(x, n, p)
    nFac = factorial(n);
    xFac = factorial(x);
    nx = n - x;
    nxFac = factorial(nx);
    pPow = p^x;
    p1Pow = (1 - p)^(nx);
    B = (nFac / (xFac * nxFac)) * pPow * p1Pow;