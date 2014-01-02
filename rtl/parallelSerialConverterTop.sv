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

module parallelSerialConverterTop#(
                                   parameter nbrOfPorts = 1,
                                   parameter parrallelWidth = 512,
                                   parameter serialWidth = 8)
   (
    input 				      clk,
    input 				      rstn,
    input [nbrOfPorts-1:0] 		      popClk,
    input 				      push,
    input [$clog2(nbrOfPorts)-1:0] 	      pushPort,
    input [parrallelWidth-1:0] 		      pushData,
    input 				      info_type pushInfo,
    output [nbrOfPorts-1:0][serialWidth-1 :0] popData,
    output [nbrOfPorts-1:0] 		      popDataPresent,
    output [nbrOfPorts-1:0] 		      popDataStartOfFrame,
    output [nbrOfPorts-1:0] 		      popDataEndOfFrame,
    output [nbrOfPorts-1:0] 		      popDataError,
    output [nbrOfPorts-1:0] 		      full
    );
   
   
   genvar                                     i;   
   reg [nbrOfPorts-1:0] 		      pushVector;


   
   always@(posedge clk or negedge rstn)
     begin
        if(rstn==0)
          begin
	     pushVector <= 0;
          end
        else
          begin
	     pushVector=0;
	     pushVector[pushPort]=push;
          end	
     end
   
   generate
      for (i=0; i<nbrOfPorts; i++) 
        begin:port
           parallelSerialConverter#(
                                    // Parameters
                                    .parrallelWidth    (parrallelWidth),
                                    .serialWidth       (serialWidth)
				    )
	   ps(
              .popData               (popData[i]),
              .popDataPresent        (popDataPresent[i]),
              .popDataStartOfFrame   (popDataStartOfFrame[i]),
              .popDataEndOfFrame     (popDataEndOfFrame[i]),
              .popDataError          (popDataError[i]),
	      .full                  (full[i]),
              .clk                   (clk),
              .popClk                (popClk[i]),
              .rstn                  (rstn),
              .push                  (pushVector[i]),
              .pushData              (pushData),
              .pushInfo              (pushInfo)
              );
        end
   endgenerate
   
   
endmodule
