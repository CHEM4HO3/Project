clc;
% clear;
close all;

% % Create connection with database
% conn = sqlite("database.sqlite", "connect");
% 
% %% Player Attributes PCA for dimension reduction %%
% % get player attributes
% player_attribute = sqlread(conn,"Player_Attributes");
% 
% % convert string data into numbers
% player_attribute.preferred_foot(player_attribute.preferred_foot == "left") = 0;
% player_attribute.preferred_foot(player_attribute.preferred_foot == "right") = 1;
% player_attribute.preferred_foot = str2double(player_attribute.preferred_foot);
% 
% player_attribute.attacking_work_rate(player_attribute.attacking_work_rate == "low") = 0;
% player_attribute.attacking_work_rate(player_attribute.attacking_work_rate == "medium") = 1;
% player_attribute.attacking_work_rate(player_attribute.attacking_work_rate == "high") = 2;
% player_attribute.attacking_work_rate(player_attribute.attacking_work_rate == "None") = missing;
% player_attribute.attacking_work_rate = str2double(player_attribute.attacking_work_rate);
% 
% player_attribute.defensive_work_rate(player_attribute.defensive_work_rate == "low") = 0;
% player_attribute.defensive_work_rate(player_attribute.defensive_work_rate == "medium") = 1;
% player_attribute.defensive_work_rate(player_attribute.defensive_work_rate == "high") = 2;
% player_attribute.defensive_work_rate(player_attribute.defensive_work_rate == "None") = missing;
% player_attribute.defensive_work_rate = str2double(player_attribute.defensive_work_rate);
% 
% % run player attributes though PCA analysis using cross validation
% player_matrix = double(player_attribute{:,5:end});
% playerVariableNames = player_attribute.Properties.VariableNames;
% [t_player, p_player, r2_player, res_x_player, A_player] = pca_crossvalid(player_matrix);
% 
% % output component loading plots
% for i = 1:size(p_player,2)
%     figure;
%     bar(categorical(playerVariableNames(5:end)),p_player(:,i));
%     title(sprintf('Player Component %d', i))
% end
%     
% %% Team attributes PCA for dimension reduction %%
% % get team attributes
% team_attributes_query = "SELECT id, team_fifa_api_id, team_api_id, date, buildUpPlaySpeed, buildUpPlayPassing, chanceCreationPassing, chanceCreationCrossing, chanceCreationShooting, defencePressure, defenceAggression, defenceTeamWidth FROM Team_Attributes";
% team_attribute = fetch(conn,team_attributes_query);
% 
% % run team attributes though PCA with cross validation
% team_matrix = double(team_attribute{:,5:end});
% teamVariableNames = team_attribute.Properties.VariableNames;
% [t_team, p_team, r2_team, res_x_team, A_team] = pca_crossvalid(team_matrix);
% 
% % output component loading plots
% for i = 1:size(p_team,2)
%     figure;
%     bar(categorical(teamVariableNames(5:end)),p_team(:,i));
%     title(sprintf('Team Component %d', i))
% end
% 
% %% Run match data through ANN %%
% % get match data 
% match_query = ['SELECT id, ',...
% 	'date, ',...
% 	'match_api_id, ',...
% 	'home_team_api_id, ',...
% 	'away_team_api_id, ',...
% 	'home_team_goal, ',...
% 	'away_team_goal, ',...
% 	'home_player_1, ',...
% 	'home_player_2, ',...
% 	'home_player_3, ',...
% 	'home_player_4, ',...
% 	'home_player_5, ',...
% 	'home_player_6, ',...
% 	'home_player_7, ',...
% 	'home_player_8, ',...
% 	'home_player_9, ',...
% 	'home_player_10, ',...
% 	'home_player_11, ',...
% 	'away_player_1, ',...
% 	'away_player_2, ',...
% 	'away_player_3, ',...
% 	'away_player_4, ',...
% 	'away_player_5, ',...
% 	'away_player_6, ',...
% 	'away_player_7, ',...
% 	'away_player_8, ',...
% 	'away_player_9, ',...
% 	'away_player_10, ',...
% 	'away_player_11 ',...
% 'FROM Match ',...
% 'WHERE home_player_1 IS NOT NULL ',...
% 	'AND home_player_2 IS NOT NULL ',...
% 	'AND home_player_3 IS NOT NULL ',...
% 	'AND home_player_4 IS NOT NULL ',...
% 	'AND home_player_5 IS NOT NULL ',...
% 	'AND home_player_6 IS NOT NULL ',...
% 	'AND home_player_7 IS NOT NULL ',...
% 	'AND home_player_8 IS NOT NULL ',...
% 	'AND home_player_9 IS NOT NULL ',...
% 	'AND home_player_10 IS NOT NULL ',...
% 	'AND home_player_11 IS NOT NULL ',...
% 	'AND away_player_1 IS NOT NULL ',...
% 	'AND away_player_2 IS NOT NULL ',...
% 	'AND away_player_3 IS NOT NULL ',...
% 	'AND away_player_4 IS NOT NULL ',...
% 	'AND away_player_5 IS NOT NULL ',...
% 	'AND away_player_6 IS NOT NULL ',...
% 	'AND away_player_7 IS NOT NULL ',...
% 	'AND away_player_8 IS NOT NULL ',...
% 	'AND away_player_9 IS NOT NULL ',...
% 	'AND away_player_10 IS NOT NULL ',...
% 	'AND away_player_11 IS NOT NULL'];
% match = fetch(conn,match_query);
% 
% % convert string dates to dates 
% player_attribute.date = datetime(player_attribute.date, "InputFormat","yyyy-mm-dd hh:mm:ss");
% team_attribute.date = datetime(team_attribute.date, "InputFormat","yyyy-mm-dd hh:mm:ss");
% match.date = datetime(match.date, "InputFormat","yyyy-mm-dd hh:mm:ss");
% 
% % initialize variables and only use 5000 matches
% i = 1;
% variables = zeros(5000, (A_player*11*2 + A_team*2));
% outcome = zeros(5000, 2);
% skip = false;
% 
% % shuffle data to get first 5000 valid matches
% match = match(randperm(height(match)),:);
% 
% 
% % Make ANN input matrix with home and away team's attributes andplayer attributes and make output matrix based on the home and away score
% % dont include match if team or player attributes is not from this year
% for row_index = 1:height(match)
%     row = match(row_index,:);
% 
%     team_match = team_attribute(team_attribute.team_api_id == row.home_team_api_id,:);
%     team_date_match = team_match(team_match.date.Year == row.date.Year,:);
%     if(height(team_date_match) == 0)
%         continue;
%     end
%     if(height(team_date_match) > 1)
%         [~, index] = min(abs(team_date_match.date - row.date));
%         team_date_match = team_date_match(index,:);
%     end
%     index = find(team_attribute{:,1} == team_date_match{1,1});
%     variables(i,1:A_team) = t_team(index, :);
%     
%     for player_index = 1:11
%         player_match = player_attribute(player_attribute.player_api_id == row{1,7+player_index},:);
%         player_date_match = player_match(player_match.date.Year == row.date.Year,:);
%         if(height(player_date_match) == 0)
%             skip = true;
%             break;
%         end
%         if(height(player_date_match) > 1)
%             [~, index] = min(abs(player_date_match.date - row.date));
%             player_date_match = player_date_match(index,:);
%         end
%         index = find(player_attribute{:,1} == player_date_match{1,1});
%         variables(i,A_team+1+(player_index-1)*A_player:A_team+player_index*A_player) = t_player(index, :);
%     end
%     if skip
%         skip = false;
%         continue;
%     end
% 
% 
%     team_match = team_attribute(team_attribute.team_api_id == row.away_team_api_id,:);
%     team_date_match = team_match(team_match.date.Year == row.date.Year,:);
%     if(height(team_date_match) == 0)
%         continue;
%     end
%     if(height(team_date_match) > 1)
%         [~, index] = min(abs(team_date_match.date - row.date));
%         team_date_match = team_date_match(index,:);
%     end
%     index = find(team_attribute{:,1} == team_date_match{1,1});
%     variables(i,A_team+1+A_player*11:2*A_team+A_player*11) = t_team(index, :);
%     
%     for player_index = 1:11
%         player_match = player_attribute(player_attribute.player_api_id == row{1,18+player_index},:);
%         player_date_match = player_match(player_match.date.Year == row.date.Year,:);
%         if(height(player_date_match) == 0)
%             skip = true;
%             break;
%         end
%         if(height(player_date_match) > 1)
%             [~, index] = min(abs(player_date_match.date - row.date));
%             player_date_match = player_date_match(index,:);
%         end
%         index = find(player_attribute{:,1} == player_date_match{1,1});
%         variables(i,1+2*A_team+A_player*11+(player_index-1)*A_player:2*A_team+A_player*11+player_index*A_player) = t_player(index, :);
%     end
%     if skip
%         skip = false;
%         continue;
%     end
%     outcome(i,:) = [row.home_team_goal row.away_team_goal];
%     i = i+1;
%     if(i > 5000)
%         break
%     end
% end
% 
% 
% % run data though ANN with 100 hidden nodes
% net = feedforwardnet(80,'trainlm');
% net.layers{1}.transferFcn = 'logsig';
% net = train(net, variables', outcome');

% predScores = net(variables');
% predScores = max(predScores, 0);
% predScores = round(predScores);


%Engine
[uxy, jnk, idx] = unique([outcome(:,1),predScores(1,:)'],'rows');
szscale = histcounts(idx,length(unique(idx)));
p = polyfit(outcome(:,1), predScores(1,:).',1);
x = linspace(0,max(outcome(:,1)));
y = polyval(p, x);
figure
scatter(uxy(:,1),uxy(:,2),25,szscale,'filled')
xlabel("Target");
ylabel("Outcome");
colorbar
hold on
plot(x,y)
legend('Data', 'Line of Fit')
title('Actual Score vs Predicted Score for Home Team')

[uxy, jnk, idx] = unique([outcome(:,2),predScores(2,:)'],'rows');
szscale = histcounts(idx,length(unique(idx)));
p = polyfit(outcome(:,1), predScores(1,:).',1);
x = linspace(0,max(outcome(:,1)));
y = polyval(p, x);
figure
scatter(uxy(:,1),uxy(:,2),25,szscale,'filled')
xlabel("Target");
ylabel("Outcome");
colorbar
hold on
plot(x,y)
legend('Data', 'Line of Fit')
title('Actual Score vs Predicted Score for Away Team')

e = predScores - outcome';
figure
histogram(e(1,:));
title('Error between actual value and expected for Home Team');

figure
histogram(e(2,:));
title('Error between actual value and expected for Away Team');

performanceHome = 1 - sum(sum(e(1,:).*e(1,:), "omitnan"),"omitnan")./sum(sum(outcome(:,1).*outcome(:,1), "omitnan"),"omitnan")
performanceAway = 1 - sum(sum(e(2,:).*e(2,:), "omitnan"),"omitnan")./sum(sum(outcome(:,2).*outcome(:,2), "omitnan"),"omitnan")




