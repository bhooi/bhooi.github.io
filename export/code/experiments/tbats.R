library(forecast)
setwd('~/Desktop/bryan-papers/etsbig/code')
args=(commandArgs(T))
print(args)
h = as.integer(args[1])
X = read.csv('../temp/X_in.txt', header=F, stringsAsFactors=F)$V1
X = as.numeric(X)
time = system.time(mod <- tbats(ts(X, frequency=h), use.box.cox=F, use.trend=F, use.damped.trend=F,
                                use.arma.errors=F, seasonal.periods=h))[3]
f = forecast(mod, h=h)
summary(mod)
write.table(f$mean, '../temp/X_out.txt', row.names=F, col.names=F)
write.table(time, '../temp/X_time.txt', row.names=F, col.names=F)