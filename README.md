@[TOC]
# 紫光同创PDS软件联合Matlab和Modelsim进行图像仿真（以二值化为例）
# 0 致读者


此篇为专栏[《紫光同创FPGA开发笔记》](https://blog.csdn.net/ryansweet716/category_12470860.html?spm=1001.2014.3001.5482)的第四篇，记录我的学习 **FPGA** 的一些开发过程和心得感悟，刚接触 **FPGA** 的朋友们可以先去此博客 [《FPGA零基础入门学习路线》](http://t.csdnimg.cn/T0Qw2)来做最基础的扫盲。

本篇内容基于笔者实际开发过程和[胡狼FPGA资料](https://blog.csdn.net/weixin_42087978)撰写，将会详细讲解此 **FPGA** 实验的全流程，**诚挚**地欢迎各位读者在评论区或者私信我交流！

***

当我们在使用 **FPGA** 做图像处理的算法时，会遇到一个问题，就是仿真出来的波形无法直观反映我们写的图像算法的效果，直接上板又会遇到屏幕驱动、时序约束等等一系列问题，开发效率很低，毕竟做图像算法肯定要看到图像才有感觉，而不是看一堆波形（**Debug** 除外）。

解决的办法很简单，就是通过修改 **Testbench** 代码让 **Modelsim** 仿真时读取一张图片对其做对应图像算法，然后输出一张做了此图像算法的图片，最后放在 **Matlab** 里面，就可以很直观的看到我们写的图像算法的效果了。

初学者可能有些不解，为何要用 **Matlab** 呢？**Matlab** 在这里主要做的工作是转换图片格式。因为 **verilog** 代码无法直接识别图片的`.jpg`或`.bmp`格式，因此需要使用 **Matlab** 进行格式转换（也可以使用 **Python** 等方法，实测 **Matlab** 上手更简单）。

因此，整体流程大致如下：

1. 将 `.jpg`或`.bmp`格式数据通过 **Matlab** 代码，转换为 **RGB** 纯图像数据（也可以转换为 **mono8** 灰度数据），转存到 `.txt` 文件内。
2. 将 `.txt` 文件激励给到 **verilog** 工程上作为代码输入的激励源，通过工程处理后，生成数据流，使用 **Modelsim** 对话框打印出，同时打印成 `.txt` 文件。
3. 最后将 `.txt` 文件放入 **Matlab** 中，通过 **Matlab** 代码处理后，转换为 `.bmp`文件格式，即可直接查看此图片经过图像算法后的效果

本篇博客将使用**紫光同创 Pango Design Suite 软件**（以下简称 **PDS**），对一张图片做**二值化算法**，并带领大家全过程操作一遍图像仿真的流程。

本文的工程文件**开源地址**如下（基于**PGL50H-6FBG484**，大家 **clone** 到本地就可以直接跑仿真，如果要上板请根据自己的开发板更改约束即可）：

> [https://github.com/ChinaRyan666/PDS_Sim_Binaryzation](https://github.com/ChinaRyan666/PDS_Sim_Binaryzation)











<br/>
<br/>


# 1 实验任务

使用**紫光同创 Pango Design Suite 软件**（以下简称 **PDS**），对一张图片做**二值化算法**，然后联合 **Modelsim** 进行仿真，最后将二值化后的图片导出查看效果。









<br/>
<br/>

# 2 使用 Matlab 进行文件格式转换

## 2.1 图片格式转RGB数据（`.txt`格式）

因为 **verilog** 代码无法直接识别图片的`.jpg`或`.bmp`格式，因此需要使用 **Matlab** 进行格式转换，将 `.jpg`或`.bmp`格式数据通过 **Matlab** 代码，转换为 **RGB** 纯图像数据，转存到 `.txt` 文件内。

**Matlab** 代码编写如下：

```matlab
clc;
clear all;
close all;
Image=imread('test.jpg'); %这部分图片名和图片格式根据自己的来改，支持bmp和jpg格式
figure, imshow(Image);
title('original image');

R=Image(:,:,1);
G=Image(:,:,2);
B=Image(:,:,3);
[row, col] = size(R);

verify_en = 1;
fprintf(' write begin \n ');
fout=fopen('hex_rgb.txt','w'); %转换后输出的txt文件
for i=1:row
    for j=1:col
        if(verify_en)% for simulation
           fprintf(fout,'%02x ',R(i,j));
           fprintf(fout,'%02x ',G(i,j));
           fprintf(fout,'%02x ',B(i,j));  
        else % for c 
           fprintf(fout,'0x%02x, ',R(i,j));
           fprintf(fout,'0x%02x, ',G(i,j));
           fprintf(fout,'0x%02x, ',B(i,j));
        end
      if(j == col)
        fprintf(fout,'\n');    
      end
    end
end
fprintf('write end \n ');

fclose(fout);

if(verify_en)    
    text8 = textread('hex_rgb.txt', '%s' );
    picture = uint8(zeros(row, 3*col));
    for i = 1:row
       for j = 1:3*col
          picture(i,j) = hex2dec(text8((i - 1)  * 3 * col + j));
       end
    end

    r = uint8(zeros(row, col));
    g = uint8(zeros(row, col));
    b = uint8(zeros(row, col));

    for i = 1:row
       k = 0;
       l = 0;
       h = 0;
      for j = 1:3*col       
          if(mod(j,3) == 1)
              k = k +1;
              r(i,k) = picture(i,j);          
          elseif(mod(j,3) == 2)
              l = l +1; 
             g(i,l) = picture(i,j);  
          elseif(mod(j,3) == 0)
             h = h +1;
             b(i,h) = picture(i,j);  
          else
            
          end                
       end
    end

    frame(:, :, 1) = r;
    frame(:, :, 2) = g;
    frame(:, :, 3) = b;
    figure, imshow(frame);
    title('txt rgb image');
end

```

<br/>


## 2.2 RGB数据（`.txt`格式）转图片格式

当 **Modelsim** 仿真结束后，使用 **Modelsim** 对话框打印出图像，打印成 `.txt` 文件。但是我们查看 `.txt` 文件无法直观看到图像算法处理后的效果，需要再放入 **Matlab** 中将`.txt` 文件转换回原来的图片格式，即可查看图像算法处理后的图片。


**Matlab** 代码编写如下：

```matlab
clc;
clear;
close all;

row = 512; %这部分图像分辨率可以自行调整
col = 512;
   
text8 = textread('hex_rgb.txt', '%s' ); %这部分文件名根据自己的来改，以Modelsim生成的为准
picture = uint8(zeros(row, 3*col));
for i = 1:row
   for j = 1:3*col
      picture(i,j) = hex2dec(text8((i - 1)  * 3 * col + j));
   end
end

r = uint8(zeros(row, col));
g = uint8(zeros(row, col));
b = uint8(zeros(row, col));

% for i = 1:row
%    k = 0;
%    l = 0;
%    h = 0;
%   for j = 1:3*col       
%       if(mod(j,3) == 1)
%           k = k +1;
%           r(i,k) = picture(i,j);          
%       elseif(mod(j,3) == 2)
%           l = l +1; 
%          g(i,l) = picture(i,j);  
%       elseif(mod(j,3) == 0)
%          h = h +1;
%          b(i,h) = picture(i,j);  
%       else
% 
%       end                
%    end
% end

k = 1;
rcnt=1;
gcnt=1;
bcnt=1;
for j = 1:3*col       
  if(k == 1)
      r(:,rcnt) = picture(:,j);
      k = 2;
      rcnt = rcnt + 1;          
  elseif(k == 2)
      g(:,gcnt) = picture(:,j);
      k = 3;
      gcnt = gcnt + 1; 
  elseif(k == 3)
      b(:,bcnt) = picture(:,j);
      k = 1;
      bcnt = bcnt + 1;  
  else

  end                
end

frame(:, :, 1) = r;
frame(:, :, 2) = g;
frame(:, :, 3) = b;
figure, imshow(frame);
title('rgb pic image');
imwrite(picture,'rgb_pic.bmp'); %转换后生成的图片文件，格式支持bmp和jpg

```


<br/>

## 2.3 其他转换

 `.jpg`或`.bmp`格式数据可以通过 **Matlab** 代码转换为 **RGB** 纯图像数据，同时也可以转换为 **mono8** 灰度数据。下面给大家编写了转换为**灰度数据**的代码，用法和 **RGB** 数据的一样。

### 2.3.1 图片格式转灰度数据（`.txt`格式）

**Matlab** 代码编写如下：


```matlab
clc;
clear;
close all;

% read gray image
I = imread('cat.bmp') ; %这部分图片名和图片格式根据自己的来改，支持bmp和jpg格式
[row,col] = size(I);

figure;imshow(I);
title('original image');
imwrite(I,'original.bmp'); 

%%%%gray image tranfer to txt and show txt picture
verify_en = 1;
gen_txt_en = 1;
if(gen_txt_en)
fprintf(' write begin \n ');
fout=fopen('hex_gray.txt','w'); %转换后输出的txt文件
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

```

<br/>

### 2.3.2 灰度数据（`.txt`格式）转图片格式

**Matlab** 代码编写如下：


```matlab
clc;
clear;
close all;

row = 276;%这部分图像分辨率可以自行调整
col = 276;
  
text8 = textread('wr_pic.txt', '%s' );%这部分文件名根据自己的来改，以Modelsim生成的为准
picture = uint8(zeros(row, col));
for i = 1:row
   for j = 1:col
      picture(i,j) = hex2dec(text8((i - 1)  * col + j));
   end
end

figure;imshow(picture);
title('test pic image');
imwrite(picture,'test_pic.bmp'); %转换后生成的图片文件，格式支持bmp和jpg

```







<br/>
<br/>

# 3 `二值化处理`简介

**图像二值化**是图像处理中一个非常活跃的分支， 其应用领域非常广泛，特别是在**图像信息压缩**、**边缘提取**和**形状分析**等方面起着重要作用，成为其处理过程中的一个基本手段。

在**传真技术领域**里，文件传真机送的是具有黑白二值信息的文字和图表。在**图像相关**方面，用二值图像进行相关比用灰度级图像进行相关有更好的相关性能和去噪作用。在用硬件实现时可避免乘法运算，从而提高硬件系统的速度和降低成本。在**图像的符号匹配**方面，二值图像比灰度级图像更适合于用符号来表达。二值图既保留了原始图像的主要特征，又使信息量得到了极大的压缩。

不过**二值化处理**使得原本颜色的取值范围从 **256** 种变为 **2** 种，确实是提高了计算速度，但是丢失的信息也多了，因此具体采用什么方式处理，要根据具体情况来选择。


我们都知道，图像是由矩阵构成，矩阵中每个点的 **RGB** 值都不一样，呈现出来的色彩不一样，最终整体呈现给我们的就是一张彩色的图像。所谓 **“二值化处理”** 就是将矩阵中每个点的 **RGB** 值转换为（0,0,0）[黑色] 或者（255,255,255）[白色]。



![在这里插入图片描述](https://img-blog.csdnimg.cn/26fe2756512f43658ff3d02065578968.png#pic_center)









<br/>
<br/>



# 4 程序设计

**二值化处理**的 **Verilog** 代码编写如下：

```
`timescale 1ns / 1ps

module binaryzation
                        #(
                          parameter DATA_WIDTH = 8 //less than or eqeal 32                
                         )
                         (
                          input                     clk_i,                          
                          input                     rst_i,  
                                                                                                       
                          input                     pixel_datav_i,                    
                          input[DATA_WIDTH -1:0]    pixel_data_i,                   
                          input[DATA_WIDTH -1:0]    threshold_i,

                          output                    binaryzation_datav_o,
                          output[DATA_WIDTH -1 : 0] binaryzation_data_o                         
                          );

reg binaryzation_datav = 0;
always@(posedge clk_i)begin
  binaryzation_datav <= pixel_datav_i; 
end

reg[DATA_WIDTH -1 : 0] binaryzation_data = 0;   
always@(posedge clk_i)begin //
  binaryzation_data <= (pixel_data_i > threshold_i) ? 32'hffff_ffff : 0;     
end

assign binaryzation_datav_o = binaryzation_datav;
assign binaryzation_data_o  = binaryzation_data;

endmodule

```







<br/>
<br/>


# 5 仿真验证


## 5.1 编写 TestBench

**代码编写**如下，记得一定要更改读写图片所在的路径（详见代码）！！


```
`timescale 1ns / 1ps

module file_sim_T0();

parameter IMAGE_WIDTH = 276;//这部分图像分辨率根据自己写入的图片修改
parameter IMAGE_HEIGHT = 276;
parameter DATA_WIDTH   = 8;
parameter THRSEHOLD = 128;

reg                     clk_i = 1'b0;
reg                     rst_i = 1'b1;
reg                     datav_i = 1'b0;
reg[DATA_WIDTH -1 : 0]  data_i = 32'd0;


wire                     binaryzation_datav_o;
wire[DATA_WIDTH -1 : 0]  binaryzation_data_o;

reg[31 : 0]  seq_data = 32'd0;
reg          seq_start = 0;

parameter PERIOD = 10;


initial begin
  clk_i = 1'b0;
  #(PERIOD);
  forever
  #(PERIOD) clk_i = ~clk_i;
end

initial begin
  rst_i = 1'b1;
  #100         rst_i = 1'b0;
  #(8*PERIOD) seq_start = 1;
end 

integer file_hex_rd;
integer file_hex_wr;
initial begin
  file_hex_rd = $fopen("D:/xxx/xxx.txt","r");//根据自己写入图片的路径进行修改，前面我们已经将写入的图片转换为了txt格式
  file_hex_wr = $fopen("D:/xxx/xxx.txt","w");//图像算法处理后，读出图片的路径，自己设置
end


reg[1:0] rd_st = 2'd0;
reg[31:0] rd_cnt = 0;
reg[15 : 0] data = 32'd0;
always@(posedge clk_i)begin
  if(rst_i)begin
    data   <= 24'd0;
    rd_cnt <= 32'd0;
    rd_st  <= 2'd0;
  end else begin
    case(rd_st)
    0:begin
      if(seq_start)begin
        if(rd_cnt < IMAGE_WIDTH *  IMAGE_HEIGHT)begin
          $fscanf(file_hex_rd,"%h" ,data) ;
          rd_cnt <= rd_cnt +1;
          rd_st  <= 2'd0;
        end else begin
          rd_st  <= 2'd1;
        end
      end         
    end
    
    1:begin
      rd_st <= 2'd2;
    end

    2:begin
      $fclose(file_hex_rd);
      rd_st  <= 2'd2;
    end    

   endcase   
  end  
end


always@(posedge clk_i)begin
  if(rst_i)begin
    datav_i <= 1'b0;
    data_i  <= 24'd0;
  end else begin
    if(seq_start && (rd_st != 2))begin
      datav_i <= 1'b1;
      data_i  <= data;    
    end else begin
      datav_i <= 1'b0;
      data_i  <= 24'd0;    
    end
  end  
end


//-----------sequence number-------
//always@(posedge clk_i)begin
//  if(rst_i)begin
//    datav_i <= 1'b0;
//    data_i  <= 24'd0;
//  end else begin
//    if(seq_start)begin
//      datav_i  <= 1'b1;
//      data_i   <= seq_data;
//      seq_data <= seq_data + 1;    
//    end else begin
//      datav_i <= 1'b0;
//      data_i  <= 24'd0;    
//    end
//  end  
//end

binaryzation
                        #(
                          .DATA_WIDTH(DATA_WIDTH)                
                         )
                         
                         u0
                         (
                          .clk_i(clk_i),                          
                          .rst_i(rst_i), 
                         			  
                                                                                                       
                          .pixel_datav_i(datav_i),
                          .pixel_data_i(data_i),
                          .threshold_i(THRSEHOLD),                          

                          .binaryzation_datav_o(binaryzation_datav_o),
                          .binaryzation_data_o(binaryzation_data_o)                         
                          );

reg wr_st = 1'b0;
reg[31:0] wr_cnt = 0;
always@(posedge clk_i)begin
  if(rst_i)begin
    wr_cnt  <= 32'd0;
    wr_st <= 1'b0;
  end else begin
    case(wr_st)
    0:begin
      if(wr_cnt < IMAGE_WIDTH *  IMAGE_HEIGHT)begin
        if(binaryzation_datav_o)begin
          $fwrite(file_hex_wr,"%h\n",binaryzation_data_o);
          wr_cnt <= wr_cnt +1;
        end else begin
          
        end
        wr_st <= 1'b0;
      end else begin
        wr_st <= 1'b1;
      end         
    end
    
    1:begin
      $fclose(file_hex_wr);
      wr_st <= 1'b1;
    end

   endcase   
  end  
end

endmodule

```







## 5.2 仿真操作

<br/>

首先我们确认自己已经安装好了 **PDS** 和 **Modelsim**，并已经成功关联（编译仿真库等），详细操作见官方文档，我放在[此工程的开源地址](https://github.com/ChinaRyan666/PDS_Sim_Binaryzation)下了，路径如下：


![在这里插入图片描述](https://img-blog.csdnimg.cn/d6edc2bd3a1443b29c87e7e6c9316150.png#pic_center)
<br/>

接下来我们要准备好一张图片（我这里准备了一张猫的图片），并将其转换为`.txt`格式，这部分的原理在上文已经详细讲解了，本工程使用的 Matlab 转换代码和图片都存放在[此工程的开源地址](https://github.com/ChinaRyan666/PDS_Sim_Binaryzation)下了，路径如下：



![在这里插入图片描述](https://img-blog.csdnimg.cn/52e52ead6c4f47f6bc21929467f6b723.png#pic_center)

<br/>

**接下来点击仿真按钮。**

![在这里插入图片描述](https://img-blog.csdnimg.cn/fb09bc436d924a87aa1efa8875e6d6c2.png#pic_center)

<br/>

接下来 **CMD** 命令行会自动调用 **Modelsim** 并开始执行仿真，仿真波形如下：


![在这里插入图片描述](https://img-blog.csdnimg.cn/ba593002d0b741db9bd86fff28242115.png#pic_center)

<br/>

与此同时，会读出一个最新的经过图像算法处理后的图像数据（`.txt`格式），路径以自己在 **Testbench** 设置的为准，本工程我放在了 **sim** 文件夹下。

![在这里插入图片描述](https://img-blog.csdnimg.cn/3fdcf5110e7043d987321c97a1df16d9.png#pic_center)

<br/>


然后将读出的`.txt`文件复制到 **Matlab** 工程所在的文件夹下。如果原来存在此文件，替换掉即可，因为我们仿真往往是多次的，每次仿真替换一次就行，非常方便。


![在这里插入图片描述](https://img-blog.csdnimg.cn/8bddb4231feb4e648ed0f84f437ffc20.png#pic_center)

<br/>

最后打开`.txt`格式转图片格式的 **Matlab** 程序，点击运行即可。（前提是已经更改好了文件的路径，程序才可以识别到）


![在这里插入图片描述](https://img-blog.csdnimg.cn/eae247f161894f849632d04b9e859916.png#pic_center)

<br/>

**二值化处理后的图片结果就会自动转换，并且弹窗显示。**

![在这里插入图片描述](https://img-blog.csdnimg.cn/4ae9ab63643a4be9ae0fb6b4a68c3781.png#pic_center)

<br/>

**上图是二值化处理后的一张猫的图片，至此本实验仿真验证成功！**




<br/>
<br/>




# 6 总结


本博客详细讲解了如何使用紫光同创 **PDS** 软件联合 **Matlab** 和 **Modelsim** 进行图像仿真（以二值化为例）。整体流程如下：

1. 将 `.jpg`或`.bmp`格式数据通过 **Matlab** 代码，转换为 **RGB** 纯图像数据（也可以转换为 **mono8** 灰度数据），转存到 `.txt` 文件内。
2. 将 `.txt` 文件激励给到 **verilog** 工程上作为代码输入的激励源，通过工程处理后，生成数据流，使用 **Modelsim** 对话框打印出，同时打印成 `.txt` 文件。
3. 最后将 `.txt` 文件放入 **Matlab** 中，通过 **Matlab** 代码处理后，转换为 `.bmp`文件格式，即可直接查看此图片经过图像算法后的效果

本文所涉及的实验是将一张猫的图片转换为了灰度数据（`.txt`格式）后放入 **Verilog** 工程中做的二值化处理，大家有兴趣可以编写屏幕驱动输出的程序，让二值化处理后的图像上板输出到屏幕上显示。之后我会分享使用紫光同创 **PDS** 做的其他图像算法，并上板验证。

希望以上的内容对您有所帮助，**诚挚**地欢迎各位读者在评论区或者私信我交流！




微博：沂舟Ryan ([@沂舟Ryan 的个人主页 - 微博 ](https://weibo.com/u/7619968945))

GitHub：[ChinaRyan666](https://github.com/ChinaRyan666)

微信公众号：**沂舟无限进步**（内含精品资料及详细教程）

如果对您有帮助的话请点赞支持下吧！



**集中一点，登峰造极。**
