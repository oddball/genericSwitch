// Copyright (C) 2012 Andreas Lindh and/or his subsidiary(-ies).
// All rights reserved.
// Contact: andreas.lindh( @ )hiced.com
//
// This file is part of genericSwitch.
// genericSwitch is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// genericSwitch is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with genericSwitch.  If not, see <http://www.gnu.org/licenses/>.
//
// Other Usage
// Alternatively, this file may be used in accordance with the terms and
// conditions contained in a signed written agreement between you and Andreas Lindh.
`timescale 1 ns/1 ps

import genericSwitchPkg::*;

module serialParallelConverter#(
                                parameter parrallelWidth = 512,
                                parameter serialWidth = 8)
   
   (
    input 			      clk,
    input 			      pushClk,
    input 			      rstn,
    input 			      push,
    input [serialWidth-1:0] 	      pushData,
    input 			      pushDataStartOfFrame,
    input 			      pushDataEndOfFrame,
    input 			      pushDataError,
    input 			      pop,
    output [parrallelWidth-1 :0]      popData,
    output 			      popDataPresent,
    output 			      popDataStartOfFrame,
    output [$clog2(parrallelWidth):0] popDataLength,
    output 			      popDataEndOfFrame,
    output 			      popDataError,
    output reg 			      empty
    );
   
   localparam addresses = parrallelWidth/serialWidth;

   wire 			      full;
   bit [parrallelWidth-1 :0] 	      writeData,n_writeData;
   bit [$clog2(addresses)-1:0] 	      writeAddress,n_writeAddress;
   reg 				      writeEnable,n_writeEnable;
   info_type info;
   info_type n_info;
   info_type popInfo;
   //wire 			      n_empty;
   
   always@(posedge pushClk or negedge rstn)
     begin
        if(rstn==0)
          begin
             info<=0;
             writeAddress<=0;
	     writeData<=0;
	     writeEnable<=0;
          end
        else
          begin
             info<=n_info;
             writeAddress<=n_writeAddress;
	     writeData <=n_writeData;
	     writeEnable <=n_writeEnable;
          end
     end




   
   always@* // push
     begin
        n_writeEnable=0;
	n_writeData =writeData;
        n_writeData[writeAddress*serialWidth +: serialWidth]=pushData;
        n_info=info;
	n_info.dataPresent=0;
        if(push)
          begin
	     if(writeAddress==0)
	       begin
		  n_info.startOfFrame= pushDataStartOfFrame;
		  n_info.error = pushDataError;		  
	       end
	     else
	       begin
		  n_info.startOfFrame=n_info.startOfFrame | pushDataStartOfFrame;
		  n_info.error = n_info.error | pushDataError;
	       end
             n_info.dataPresent=0;
             n_info.length = writeAddress;
             n_info.endOfFrame = pushDataEndOfFrame;             
             if((writeAddress== addresses-1) || pushDataEndOfFrame)
               begin
		  n_info.dataPresent=1;
		  n_writeEnable=1;
                  n_writeAddress = 0;		  
               end
             else
	       begin
                  n_writeAddress = writeAddress+1;
               end
          end
     end

   // synopsys translate_off
   always@* 
     begin
	if(writeEnable && full)
	  $display("%t Error. Pushing but FIFO is full",$time); 
     end
   // synopsys translate_on

   
   
   async_fifo#(.width(parrallelWidth+$bits(info_type)),
	       .depth(4)
	       )fifo(.rstn(rstn),
		     .writeClk(pushClk),
		     .readClk(clk),
		     .read(pop),
		     .write(writeEnable),
		     .writeData({writeData,info}&{parrallelWidth+$bits(info_type){writeEnable}}),
		     .readData({popData,popInfo}), 
		     .empty(empty),
		     .full(full)
		     );




   
   assign popDataPresent = popInfo.dataPresent;
   assign popDataStartOfFrame = popInfo.startOfFrame;
   assign popDataLength = popInfo.length;
   assign popDataEndOfFrame = popInfo.endOfFrame ;
   assign popDataError = popInfo.error;
   
endmodule



// Local Variables:
// verilog-library-directories:("../rtl/" "../genMem/rtl/")
// End:


