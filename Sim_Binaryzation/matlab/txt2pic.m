clc;
clear;
% close all;

row = 276;
col = 276;
  
text8 = textread('wr_pic.txt', '%s' );
picture = uint8(zeros(row, col));
for i = 1:row
   for j = 1:col
      picture(i,j) = hex2dec(text8((i - 1)  * col + j));
   end
end

figure;imshow(picture);
title('test pic image');
imwrite(picture,'test_pic.bmp'); 

