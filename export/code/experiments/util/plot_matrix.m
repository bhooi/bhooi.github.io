function plot_matrix(A, name)
if nargin < 2
    name = '';
end
scale = max(size(A));
sz1 = size(A,1) / scale * 12;
sz2 = size(A,2) / scale * 12;
imagesc(A);
set(gca, 'CLim', [0, max(max(A))]);
redColorMap = [ones(1, 128), linspace(1, 0, 128)];
greenColorMap = [linspace(0, 1, 128), linspace(1, 0, 128)];
blueColorMap = [linspace(0, 1, 128), ones(1, 128)];
colorMap = [redColorMap; greenColorMap; blueColorMap]';
colormap(colorMap);
h = colorbar;
set(h, 'ylim', [0 max(max(A))]);
set(gcf,'PaperUnits','inches','PaperPosition',[1 1 2+sz2 2+sz1])
title(sprintf('%s (%d x %d)\n', name, size(A,1), size(A,2)), 'FontSize', 30);
% set(gcf,'PaperUnits','inches','PaperPosition', [1 1 10 4])
end