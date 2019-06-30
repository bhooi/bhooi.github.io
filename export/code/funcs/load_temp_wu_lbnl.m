
function temp = load_temp_wu_lbnl(datatimes)
Dir = '~/Desktop/others-papers/PowerGrid/data/LBNL/';
tempdat = readtable([Dir 'KCABERKE57_2015-10-01_2015-10-11.csv']);
temp_times = cellfun(@(x)datenum(x, 'yyyy-mm-dd HH:MM:SS'), tempdat.Time);
temp_times = temp_times(tempdat.TemperatureF > 0);
temp_vals = tempdat.TemperatureF(tempdat.TemperatureF > 0);
temp_unixtime = int32((temp_times - datenum(1970,1,1)) * 86400);
n = length(datatimes);
temp = nan(1, n);

temp_append = [temp_unixtime; Inf];
temp(datatimes <= temp_append(1)) = temp_vals(1);
for i=1:length(temp_vals)
    temp((datatimes >= temp_append(i)) & (datatimes < temp_append(i+1))) = temp_vals(i);
end