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

module async_fifo#(parameter width = 1,
                   parameter depth = 4
                   )(input  rstn,
		     input  writeClk,
		     input  readClk,
		     input  read,
		     input  write,
		     input[width-1:0]  writeData,
		     output reg [width-1:0] readData, 
		     output reg empty,
		     output reg full
		     );
   // TODO, replace this with a synthesizable version
   reg [width-1:0] 	    fifo[$];
		
   always@(posedge readClk or negedge rstn)
     begin
	if(rstn==0)
	  begin
	     empty <= 1'b1;
	     readData <= 0;
	  end
	else
          begin
	     readData<=fifo[0]; //this prefetch misery should be removed
	     if(read)
	       begin
		  readData <= fifo.pop_front();
	       end
	     if(fifo.size()==0)
	       empty <= 1'b1;
	     else
	       empty <= 1'b0;
	  end
     end
   
   always@(posedge writeClk or negedge rstn)
     begin
	if(rstn==0)
	  begin
	     full <=0;
	  end
	else
          begin
	     if(write)
	       begin
		  fifo.push_back(writeData);
		  if(fifo.size()>=depth)
		    full <= 1'b1;
		  else
		    full <= 1'b0;
	       end
	  end
     end   



endmodule 