function [bestTranformInLierCount bestTranform refinedMatches numMatches] = ransac(fa, da, fb, db)
warning('off');

% find matching descriptors
% m = min([size(da, 2) size(db, 2)]);
% [matches scores] = vl_ubcmatch(da(:, 1:m), db(:, 1:m));
[matches scores] = vl_ubcmatch(da, db);

% bestTranformInLierCount = 0;
% bestTranform = zeros(6, 1);
% bestInlier = zeros(9, 1);

I1Columns = fa(1:2,matches(1,:));
I2Columns = fb(1:2,matches(2,:));

% plotmatches(im1,im2,fa,fb,matches);
% toc
% return ;

distanceThreshold = 10;
bestTranformInLierCount = 0 ;


for i=1:500
    
    %Selecting 3 Random Points for Transformation
    p1 = randi(size(I1Columns,2));
    p2 = randi(size(I1Columns,2));
    p3 = randi(size(I1Columns,2));
    
    %Computing Transformation Based On The Points Above
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
     
    % Finding the transformation matrix
    X = A\B;
    
    It = [X(1),X(2)
          X(3),X(4)] * I1Columns ;
    
    It(1,:)=It(1,:) + X(5);
    It(2,:)=It(2,:) + X(6);
    
    % Computing the SSD Distance between expected points
    % and 
    
    ItDiff = I2Columns - It;
    
    Dist = sqrt(diag(ItDiff' * ItDiff));
    
    
    % Excluing the outlier from inlier 
    % based on the specified threshold 
    Inlier = Dist < distanceThreshold;
    
    % Number of successfull transfered points
    trInlierCount = sum(Inlier);
    
    % Comparing the number
    if max(trInlierCount,bestTranformInLierCount)==trInlierCount
        bestTranformInLierCount=trInlierCount;
        bestTranform = X;
        bestInlier=Inlier;
    end
    
    
end

% Showing only inlier
numMatches = size(matches, 2);
refinedMatches = matches(:,find(bestInlier>0));
