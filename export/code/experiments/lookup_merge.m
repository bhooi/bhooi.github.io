
function [min_val, best_temp] = lookup_merge(times, dat)
temp_times = cellfun(@(x)datenum(x, 'yyyy-mm-dd HH:MM:SS'), dat.Time);
for i=1:length(times)
    [min_val(i), min_idx(i)] = min(abs(times(i) - temp_times));
    best_temp(i) = dat.TemperatureF(min_idx(i));
end