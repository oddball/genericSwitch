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

module serialParallelConverterTop#(parameter nbrOfPorts = 1,
                                   parameter parrallelWidth = 512,
                                   parameter serialWidth = 8,
				   parameter bufferAddresses  = 32,
				   parameter addressWidth = $clog2(bufferAddresses))
   (input                            clk,
    input [nbrOfPorts-1:0] 		    pushClk,
    input 				    rstn,
    input [nbrOfPorts-1:0] 		    push,
    input [nbrOfPorts-1:0][serialWidth-1:0] pushData,
    input [nbrOfPorts-1:0] 		    pushDataStartOfFrame,
    input [nbrOfPorts-1:0] 		    pushDataEndOfFrame,
    input [nbrOfPorts-1:0] 		    pushDataError,
    input 				    writeRejected,
    input [addressWidth-1:0] 		    writeAddress,
    output reg 				    writeEnable,
    output reg 				    wroteCell,
    output 				    cell_queue_type writtenCell,
    output reg [parrallelWidth-1:0] 	    writeData,
    output reg [$clog2(nbrOfPorts)-1:0]     writePort,
    output 				    info_type writeInfo
    );

   
   
   wire [nbrOfPorts-1:0] [$clog2(parrallelWidth):0] popDataLength;
   wire [nbrOfPorts-1:0] [parrallelWidth-1 :0] 	    popData;
   wire [nbrOfPorts-1:0] 			    popDataPresent;
   wire [nbrOfPorts-1:0] 			    popDataStartOfFrame;   
   wire [nbrOfPorts-1:0] 			    popDataEndOfFrame;
   wire [nbrOfPorts-1:0] 			    popDataError;
   wire [nbrOfPorts-1:0] 			    empty;
   reg [nbrOfPorts-1:0] 			    pop;
   info_type [nbrOfPorts-1:0] 			    info;
   genvar 					    i;
   
   generate
      for (i=0; i<nbrOfPorts; i++) 
        begin:port
           serialParallelConverter#(
				    // Parameters
				    .parrallelWidth    (parrallelWidth),
				    .serialWidth       (serialWidth))
	   sp(
              // Outputs
	      .popDataStartOfFrame  (popDataStartOfFrame[i]),
              .popData              (popData[i]),
              .popDataPresent       (popDataPresent[i]),              
              .popDataLength        (popDataLength[i]),
              .popDataEndOfFrame    (popDataEndOfFrame[i]),
              .popDataError         (popDataError[i]),
	      .empty                (empty[i]),
              // Inputs
              .clk                  (clk),
              .pushClk              (pushClk[i]),
              .rstn                 (rstn),
              .push                 (push[i]),
              .pushData             (pushData[i]),
              .pushDataStartOfFrame (pushDataStartOfFrame[i]),
              .pushDataEndOfFrame   (pushDataEndOfFrame[i]),
              .pushDataError        (pushDataError[i]),
              .pop                  (pop[i])
              );
           
           assign info[i].length=popDataLength[i];
           assign info[i].dataPresent=popDataPresent[i];
           assign info[i].startOfFrame=popDataStartOfFrame[i];
           assign info[i].endOfFrame=popDataEndOfFrame[i];
           assign info[i].error=popDataError[i];
        end
   endgenerate


   always@*
     begin
	writePort= 0;
	writeEnable = 0;
	wroteCell =0;
	writtenCell =0;
	writeData   =0;
	pop=0;
	writeInfo = 0;
        for(int i=0; i<nbrOfPorts; i++)
          begin
             if(!empty[i])
               begin		  
		  writtenCell.info = info[i];
		  writeInfo = info[i];
		  writtenCell.port = i;
		  writePort= i;
		  writtenCell.address = writeAddress;
		  writeEnable =1;
		  if(writeRejected == 1) 
		    // notice that there is a long combinatorical path here
		    // need to smash this later, if not else for layout
		    begin
		       $display("writeRejected. Add handling for this. broken packet");
		       $stop();
		    end
		  else
		    begin
		       writeData = popData[i];
		       pop[i]=1;
		       wroteCell=1;
		    end // else: !if(writeRejected == 1)
		  break;
               end // if (!empty[i])
          end // for (int i=0; i<nbrOfPorts; i++)	
     end
   
endmodule


// Local Variables:
// verilog-library-directories:("./" "../rtl/" "../genMem/rtl/")
// End:
