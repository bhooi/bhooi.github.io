function err = mse_ratio(Irhat, Iihat, Ir, Ii)

err = sqrt(mean(([Irhat Iihat] - [Ir Ii]).^2)) / sqrt(mean(([Ir Ii]).^2));

end