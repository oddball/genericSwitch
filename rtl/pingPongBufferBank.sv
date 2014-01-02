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

module pingPongBufferBank#(
                           parameter parrallelWidth = 512,
                           parameter nbrOfBanks = 4,
                           parameter bankAddresses = 8)
   (
    input                              clk, 
    input                              rstn,
    output [$clog2(bankAddresses)-1:0] free,
    output reg                         initDone,
    input [parrallelWidth-1:0]         writeData,
    input                              writeEnable,
    output [$clog2(bankAddresses)-1:0] writeAddress,
    input [$clog2(bankAddresses)-1:0]  readAddress,
    input                              readEnable,
    output [parrallelWidth-1:0]        readData
    );


   reg [$clog2(bankAddresses)-1:0]     address;
   reg [$clog2(bankAddresses)-1:0]     nxtAddress;  

   assign writeAddress = address;

   //TODO: replace this with something synthesizable
   reg [$clog2(bankAddresses)-1:0]     freeAddressContainer[$]; 
   always@(posedge clk or negedge rstn)
     begin
        if(rstn==0)
          begin
             freeAddressContainer = {};// clear
             for(int i=1; i<bankAddresses; i++)
               freeAddressContainer.push_front(i);
             nxtAddress<=0;
             initDone<=0;
          end
        else
          begin
             initDone<=1;
             if(writeEnable && readEnable)
               begin           
                  $error("Something is wrong. Can't do write and read at the same time");
               end                
             else if(writeEnable==1)
               begin
                  nxtAddress<=freeAddressContainer.pop_back();
               end                
             else if(readEnable==1)
               begin
                  freeAddressContainer.push_back(readAddress);
                  nxtAddress<=nxtAddress;
               end
             else
               begin
                  nxtAddress<=nxtAddress;
               end
          end
     end
   
   assign free = freeAddressContainer.size;
   
   
   
   always@*
     begin
        if(writeEnable==1)
          begin
             address = nxtAddress;
          end
        else if(readEnable==1)
          begin
             address = readAddress;
          end
        else
          begin
             address = 0;
          end        
     end
   
   onePortMem#(
               // Parameters
               .addresses(bankAddresses),
               .width    (parrallelWidth))mem(/*AUTOINST*/
                                              // Outputs
                                              .readData (readData),
                                              // Inputs
                                              .readEnable       (readEnable),
                                              .address          (address),
                                              .clk              (clk),
                                              .writeEnable      (writeEnable),
                                              .writeData        (writeData));
endmodule


// Local Variables:
// verilog-library-directories:("../rtl/" "../genMem/rtl/")
// End:
