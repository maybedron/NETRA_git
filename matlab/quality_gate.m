function [isGradable, sharpnessScore, enhancedImg] = quality_gate(imgPath)
img = imread(imgPath);
gray = rgb2gray(img);

lapKernel = fspecial('laplacian', 0.2);
lapImg = imfilter(double(gray), lapKernel);
sharpnessScore = var(lapImg(:));

SHARPNESS_THRESHOLD = 15;
isGradable = sharpnessScore > SHARPNESS_THRESHOLD;

enhancedGray = adapthisteq(gray, 'ClipLimit', 0.02, 'Distribution', 'rayleigh');

enhancedImg = img;
for c = 1:3
    channel = double(img(:,:,c));
    gainMap = double(enhancedGray) ./ (double(gray) + eps);
    enhancedImg(:,:,c) = uint8(min(255, channel .* gainMap));
end

fprintf('Sharpness: %.2f | Gradable: %d\n', sharpnessScore, isGradable);
end