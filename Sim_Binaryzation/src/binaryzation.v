`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 沂舟无限进步
// Engineer：蔡杰涛
// Create Date: 2023年10月24日
// Module Name: binaryzation
// Function：二值化算法
//////////////////////////////////////////////////////////////////////////////////

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
