function fmeas = compute_fmeasure(pred, truth)

fmeas = 2 * length(intersect(pred, truth)) / (length(pred) + length(truth));

end