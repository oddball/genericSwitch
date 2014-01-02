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

module parallelSerialConverter#(
                                parameter parrallelWidth = 512,
                                parameter serialWidth = 8,
                                parameter addresses = parrallelWidth/serialWidth)
   (
    input 			  clk,
    input 			  rstn,
    input 			  push,
    input [parrallelWidth-1:0] 	  pushData,
    input 			  info_type pushInfo,
    input 			  popClk,
    output reg [serialWidth-1 :0] popData,
    output reg 			  popDataPresent,
    output reg 			  popDataStartOfFrame,
    output reg 			  popDataEndOfFrame,
    output reg 			  popDataError,
    output reg 			  full
    );
   
   wire [parrallelWidth-1:0] 	  readData;
   info_type readInfo;   
   reg [$clog2(addresses)-1:0] 	  counter;
   reg [$clog2(addresses)-1:0] 	  n_counter;
   reg 				  pop;
   async_fifo#(.width(parrallelWidth+$bits(info_type)),
	       .depth(10) //4) debug todo
	       )fifo(.rstn(rstn),
		     .writeClk(clk),
		     .readClk(popClk),
		     .read(pop),
		     .write(push),
		     .writeData({pushData,pushInfo}),
		     .readData({readData,readInfo}), 
		     .empty(empty),
		     .full(full)
		     );

   typedef enum 		  {idle, sending} state_type;
   state_type state, n_state;

   always@(posedge popClk or negedge rstn)
     begin
        if(rstn==0)
          begin
	     counter <= 0;
	     state <= idle;
          end
        else
          begin
	     counter <= n_counter;
	     state <= n_state;
          end	
     end

   always@*
     begin
	popDataError = 0;
	popDataPresent = 0;
	popData = 0;
	popDataStartOfFrame = 0;
	popDataEndOfFrame = 0;
	n_counter = counter;
	n_state =state;
	pop = 0;
	if(state == idle)
	  begin
	     if(!empty)
	       begin
		  n_state = sending;
	       end	     
	  end
	else if(state == sending)
	  begin
	     popDataPresent = 1'b1;
	     popData = readData[counter*serialWidth +: serialWidth];
	     if(readInfo.startOfFrame && counter == 0 )
	       popDataStartOfFrame = 1;	     
	     if(counter == readInfo.length && readInfo.endOfFrame)
	       begin
		  n_state = idle;
		  pop =1;
		  n_counter = 0;		  
		  popDataEndOfFrame = 1;
	       end
	     else if(counter==addresses-1)
	       begin
		  n_counter = 0;
		  pop =1;
	       end
	     else
	       begin
		  n_counter = counter+1;
	       end
	  end
     end // always@ *
   
   
endmodule

// Local Variables:
// verilog-library-directories:("../rtl/" "../genMem/rtl/")
// End:
