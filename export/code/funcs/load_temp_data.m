function [temp, precip2] = load_temp_data(n)
tab = readtable('../data/CMU_data/temp/pittsburgh_temp_hourly.csv');
good = strcmp('53', cellfun(@(x)(x(end-1:end)), tab.DATE, 'UniformOutput', false));
sub = tab(good, :);
start_date = find(strcmp(sub.DATE, '7/29/16 0:53'));
sub = sub(start_date:start_date+n-1, :);
temp = cellfun(@str2num, sub.HOURLYDRYBULBTEMPF)';
precip = sub.HOURLYPrecip;
precip2 = nan(size(precip));
for i=1:length(precip)
    if strcmp(precip{i}, 'T') % handle the "trace" value (i.e. very little rain)
        precip2(i) = 0;
    elseif precip{i}(end) == 's'
        precip2(i) = str2num(precip{i}(1:end-1));
    else
        precip2(i) = str2num(precip{i});
    end
end
