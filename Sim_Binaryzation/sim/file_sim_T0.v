`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 沂舟无限进步
// Engineer：蔡杰涛
// Create Date: 2023年10月24日
// Module Name: binaryzation
// Function：二值化算法
//////////////////////////////////////////////////////////////////////////////////


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
  file_hex_rd = $fopen("D:/Github/PDS_Sim_Binaryzation/Sim_Binaryzation/sim/hex_gray.txt","r");//根据自己写入图片的路径进行修改，前面我们已经将写入的图片转换为了txt格式
  file_hex_wr = $fopen("D:/Github/PDS_Sim_Binaryzation/Sim_Binaryzation/sim/wr_pic.txt","w");//图像算法处理后，读出图片的路径，自己设置 
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
