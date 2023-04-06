clc;
clear;
close all;

conn = sqlite("database.sqlite", "connect");
player = sqlread(conn,"Player");
player_attribute = sqlread(conn,"Player_Attributes");

player_attribute.preferred_foot(player_attribute.preferred_foot == "left") = 0;
player_attribute.preferred_foot(player_attribute.preferred_foot == "right") = 1;
player_attribute.preferred_foot = str2double(player_attribute.preferred_foot);

player_attribute.attacking_work_rate(player_attribute.attacking_work_rate == "low") = 0;
player_attribute.attacking_work_rate(player_attribute.attacking_work_rate == "medium") = 1;
player_attribute.attacking_work_rate(player_attribute.attacking_work_rate == "high") = 2;
player_attribute.attacking_work_rate(player_attribute.attacking_work_rate == "None") = missing;
player_attribute.attacking_work_rate = str2double(player_attribute.attacking_work_rate);

player_attribute.defensive_work_rate(player_attribute.defensive_work_rate == "low") = 0;
player_attribute.defensive_work_rate(player_attribute.defensive_work_rate == "medium") = 1;
player_attribute.defensive_work_rate(player_attribute.defensive_work_rate == "high") = 2;
player_attribute.defensive_work_rate(player_attribute.defensive_work_rate == "None") = missing;
player_attribute.defensive_work_rate = str2double(player_attribute.defensive_work_rate);

player_matrix = double(player_attribute{:,5:end});
[t, p, r2, res_x, A] = pca_crossvalid(player_matrix);



