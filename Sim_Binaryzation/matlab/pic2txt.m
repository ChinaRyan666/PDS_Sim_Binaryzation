clc;
clear;
% close all;

% read gray image¯¸
I = imread('cat.bmp') ;
[row,col] = size(I);

figure;imshow(I);
title('original image');
imwrite(I,'original.bmp'); 

%%%%gray image tranfer to txt and show txt picture
verify_en = 1;
gen_txt_en = 1;
if(gen_txt_en)
fprintf(' write begin \n ');
fout=fopen('hex_gray.txt','w'); 
for i=1:row
    for j=1:col
        if(verify_en)
           fprintf(fout,'%0x ',I(i,j));%used for verilog simulation
        else
           fprintf(fout,'0x%0x, ',I(i,j));%used for c
        end
      if(j == col)
        fprintf(fout,'\n');    
      end
    end
end
fprintf('write end \n ');

fclose(fout);
end

if(verify_en)    
    text8 = textread('hex_gray.txt', '%s' );
    picture = uint8(zeros(row, col));
    for i = 1:row
       for j = 1:col
          picture(i,j) = hex2dec(text8((i - 1)  * col + j));
       end
    end

figure;imshow(picture);
title('txt gray image');
imwrite(picture,'txt_gray.bmp'); 
end
