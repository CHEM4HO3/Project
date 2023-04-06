function [t, p, r2, res_x, A] = pca_crossvalid(data)


X = (data - mean(data))./std(data);

% Create the subsets for cross-validation

% NOTE that the number of subsets G has been chosen to divide evenly in the
% data set... If it was not, we would round up or down and the last subset
% would absorb the "difference."

G = 6; % <-- number of subsets to be usedsubsets
blocks = round(length(X)/G); % <-- How many points in each testing set
X_unshuffled = X;
X = X(randperm(length(X)),:); % <-- Shuffle the data to randomize 

% "train" and "test" are 3D matrices (arrays).
% ROW --> the observation as we know it already
% COLUMN --> the variable as we know it already
% PANE (depth dimension) --> there is a pane for each group in G

% For THIS example: 
% train is 138 x 9 x 4
% test is 46 x 9 x 4

% Example: Call an entire training set for subgroup g as train(:,:,g)

train = zeros((G-1)*blocks,size(X,2),G);
test = zeros(blocks,size(X,2),G);

for i = 1:G
    
    S = X;
    S(blocks*(i-1)+1:blocks*i,:) = [];
    train(:,:,i) = S; % <-- This is a weird one, but MATLAB won't let you delete rows from a 3D array
    test(:,:,i) = X(blocks*(i-1)+1:blocks*i,:);

end

% OK, that should have made you the data sets automatically for training
% and testing. You can use those as you proceed.


% % ----------------------------------------------------------------------- %
% % YOUR CODE STARTS HERE %
% % ----------------------------------------------------------------------- %
q2 = zeros(size(X,2),1);
var_x = sum(sum(X.*X, "omitnan"),"omitnan");

for A = 1:size(X,2)
    press = 0;
    for j = 1:G
        [~, p, ~] = nipalspca(train(:,:,j),A);
        t_test = test(:,:,j) * p;
        E = test(:,:,j) - t_test * p';
        press = press + sum(sum(E.*E, "omitnan"),"omitnan");
    end
%     press = sum(sse);
    [~, ~, r2] = nipalspca(X,A);
    q2(A) = 1 - (press/var_x);
    fprintf('A = %d\n',A);
%     fprintf('Q2 = %f\n', q2(A))
%     fprintf('r2 = %f\n', r2);
%     fprintf('\n');
    if(A > 1)
      per_change = (q2(A) - q2(A-1)) / q2(A-1);
      if(per_change < 0.01)
          break;
      end
    end
end
A = A-1;

[t, p, r2, res_x] = nipalspca(X_unshuffled,A);