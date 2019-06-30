library(forecast)
setwd('~/Desktop/bryan-papers/etsbig/code')
args=(commandArgs(T))
print(args)
h = as.integer(args[1])
old <- Sys.time()
X = read.csv('../temp/X_in.txt', header=F, stringsAsFactors=F)$V1
cat(sprintf("time after input is %f\n", Sys.time() - old))
X = as.numeric(X)
time = system.time(mod <- stlf(ts(X, frequency=h), etsmodel='ZAA'))[3]
# time = system.time(mod <- HoltWinters(ts(X, frequency=h)))[3]
cat(sprintf("time after algorithm is %f\n", Sys.time() - old))
f = forecast(mod, h=h)
cat(sprintf("time after forecast is %f\n", Sys.time() - old))
summary(mod)
write(round(f$mean, digits=3), '../temp/X_out.txt', ncolumns=1)
write(time, '../temp/X_time.txt', ncolumns=1)