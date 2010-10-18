%
% RANSAC to select a set of inliers that are compatible with a
% homography between the images.
%
function [bestTranformInLierCount bestTranform refinedMatches numMatches] = ransac(fa, da, fb, db)
    warning('off');

    % find matching descriptors
    [matches scores] = vl_ubcmatch(da, db);

    I1Columns = fa(1:2,matches(1,:));
    I2Columns = fb(1:2,matches(2,:));

    distanceThreshold = 10;
    bestTranformInLierCount = 0 ;

    %% Repeat 500 times to find the solution which produces the most inliners
    for i=1:500

        %% Selecting 3 Random Points for Transformation
        p1 = randi(size(I1Columns,2));
        p2 = randi(size(I1Columns,2));
        p3 = randi(size(I1Columns,2));

        %% Computing Transformation Based On The Points Above
        A = [ I1Columns(1,p1),I1Columns(2,p1),0,0,1,0
              0,0,I1Columns(1,p1),I1Columns(2,p1),0,1
              I1Columns(1,p2),I1Columns(2,p2),0,0,1,0
              0,0,I1Columns(1,p2),I1Columns(2,p2),0,1
              I1Columns(1,p3),I1Columns(2,p3),0,0,1,0
              0,0,I1Columns(1,p3),I1Columns(2,p3),0,1];


        B = [I2Columns(1,p1)
             I2Columns(2,p1)
             I2Columns(1,p2)
             I2Columns(2,p2)
             I2Columns(1,p3)
             I2Columns(2,p3)];

        %% Finding the transformation matrix
        X = A\B;

        %% Computing the SSD Distance between expected points
        It = [X(1),X(2)
              X(3),X(4)] * I1Columns ;
        It(1,:)=It(1,:) + X(5);
        It(2,:)=It(2,:) + X(6);

        ItDiff = I2Columns - It;
        Dist = sqrt(diag(ItDiff' * ItDiff));

        %% Exclude outlier from inlier based on the specified threshold 
        Inlier = Dist < distanceThreshold;

        %% Update the best solution if we found a more accurate tranformation
        trInlierCount = sum(Inlier);
        if max(trInlierCount,bestTranformInLierCount)==trInlierCount
            bestTranformInLierCount=trInlierCount;
            bestTranform = X;
            bestInlier=Inlier;
        end


    end

    %% Return only inliners
    numMatches = size(matches, 2);
    refinedMatches = matches(:,find(bestInlier>0));
