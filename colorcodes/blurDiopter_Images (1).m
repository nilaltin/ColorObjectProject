% blurDiopters
%
% Starts with Ione's original code (very slightly modified), followed by a
% faster way to convolve.  The trick is use a 1 diopter filter (disc) and
% convolve it with subsampled images for larger diopters and then
% upsampling back to the original size.
%
% Only works for multiple factors of the starting blur factor (1 diopters
% here).
clear

imgDir = 'C:\Users\Ione Fine\Documents\code\nil_color\BOiS_Images';

% load in the image
drawit = 0;
imgAng = 20;  % image visual angle (square image, degrees)
grayflag = 1;

folderList = dir('C:\Users\Ione Fine\Documents\code\nil_color\BOiS_Images');
folderList = folderList(3:end); % weird hack

for f = 1:length(folderList) % 
    disp(['converting images in folder ',  num2str(f)])
    % images containing the object
    % load the full image
    img_filenames = dir([folderList(f).folder, '\', folderList(f).name, '/*DxO.png']);
    for i = 1:length(img_filenames)
            disp(['converting image ',  num2str(i)])
    fullImg = imread([img_filenames(f).folder, '\', img_filenames(i).name]);

    if grayflag
        fullImg = mean(fullImg,3); % make it grayscale
    end
    fullImg = double(fullImg)./255;
    sz = size(fullImg,1);

    [x,y] = meshgrid(linspace(-imgAng/2,imgAng/2,sz));
    ds = x(1,2)-x(1,1); % what the pixel resolution in degrees

    % modeling blur as a disk
    % https://pmc.ncbi.nlm.nih.gov/articles/PMC5946648/
    scFac = .0561; % mysterious scale factor from paper
    Dlist = 0:2:8;  % diopters of anismetropia we are modeling
    for d = 1:length(Dlist)
        rad(d) = 3.34*Dlist(d)*scFac/2; % radius of blur circle
    end
    [RX, RY]= meshgrid(-max(rad)*1.5:ds:max(rad)*1.5);
    Borig = zeros(size(RX));

    % blur for each diopter level
    for d = 1:length(Dlist)
        clear B;
        B = Borig;
        if Dlist(d)==0
            ctr = floor(size(Borig)/2);
            B(ctr(1), ctr(2)) = 1;
        else
            B(RX(:).^2+RY(:).^2<rad(d).^2) = 1;
        end
        B = B/sum(B(:));
        clear aImg; % needed because otherwise the uint are inherited and cause issues
        if grayflag
            aImg =conv2(fullImg, B, 'valid');
        else
            
            for c = 1:3 % go through rgb in turn
                aImg(:, :, c) =conv2(fullImg(:, :, c), B, 'valid');
            end
        end

        aImg = uint8(aImg*255);
        if drawit
            figure(d+1)
            image(aImg);
            if grayflag; colormap(gray); end
            title(['(1) diopters = ', num2str(Dlist(d))])
            axis equal;  axis tight; drawnow;
            pause
        end
        if grayflag
            filename = [img_filenames(i).name(1:end-4), '_Gray_D', num2str(Dlist(d)), '.png'];
        else
            filename = [img_filenames(i).name(1:end-4), '_Color_D', num2str(Dlist(d)), '.png'];
        end
        imwrite(aImg, [img_filenames(f).folder,'\',filename], 'BitDepth', 8);
    end
    end
end
