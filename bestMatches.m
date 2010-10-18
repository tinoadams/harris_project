%
% Returns a structure with information about which of the given images
% have good correspondences in terms of descriptor matches after RANSAC.
%
function bestMatch = bestMatches(Images)
    % structure that is returned
    bestMatch = struct('bestMatch', 0, 'image', 0, 'count', 0, 'numMatches', 0,...
        'bestTranformInLierCount', [], 'bestTranform', [],...
        'refinedMatches' ,[]);
    % Static probabilstic value from the Brown Lowe paper
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
        %% Determine how probable the match is
        threshold = alpha + beta * bestMatch(i).numMatches;
        if (bestMatch(i).bestTranformInLierCount < threshold)
            fprintf('Dismiss match based on low probability (%d / %f) "%s" -> "%s"\n',...
                bestMatch(i).bestTranformInLierCount, threshold,...
                Images(i).name, Images(bestMatch(i).bestMatch).name);
            bestMatch(i).bestMatch = 0;
        end
    end
    
    [values,index] = sort([bestMatch.count], 'descend');
    bestMatch = bestMatch(index);
   