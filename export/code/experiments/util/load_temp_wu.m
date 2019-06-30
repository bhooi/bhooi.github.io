%fname1 is filename for CMU weather station, which we choose first
%fname2 is filename for Shadyside weather station, which we use if CMU is
% unavailable 
function temp = load_temp_wu(fname1, fname2, timestamp)
times = cellfun(@(x)datenum(x, 'mm/dd/yyyy HH:MM'), timestamp);
dat1 = readtable(['../data/CMU_data/temp/' fname1]);
[min_val1, best_temp1] = lookup_merge(times, dat1);
temp = best_temp1;
if ~isempty(fname2)
    dat2 = readtable(['../data/CMU_data/temp/' fname2]);
    [~, best_temp2] = lookup_merge(times, dat2);
    missing_idx = (min_val1 > (1/24/12)); % if dat1 has no timestamp within 5 minutes, use temp2 instead
    temp(missing_idx) = best_temp2(missing_idx);
end
end

