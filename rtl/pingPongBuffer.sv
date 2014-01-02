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

module pingPongBuffer#(
                       parameter nbrOfPorts = 1,
                       parameter parrallelWidth = 512,
                       parameter nbrOfBanks = 4,
                       parameter addresses  = 32,
                       parameter addressWidth = $clog2(addresses))
   (
    input 			   clk,
    input 			   rstn,
    input [parrallelWidth-1:0] 	   writeData,
    input 			   writeEnable,
    output reg 			   writeRejected,
    output reg [addressWidth-1:0]  writeAddress,
    input [addressWidth-1:0] 	   readAddress,
    input 			   readEnable,
    output [parrallelWidth-1:0]    readData,
    input [$clog2(nbrOfPorts)-1:0] writePort,
    input [$clog2(nbrOfPorts)-1:0] readPort,
    output [addressWidth-1:0] 	   nextReadPtr
    );
   
   localparam nbrOfPortsWidth =$clog2(nbrOfPorts);
   localparam bankAddresses = addresses / nbrOfBanks;

   reg [nbrOfBanks-1:0][$clog2(bankAddresses)-1:0] freeBank;
   wire [nbrOfBanks-1:0] 			   initDoneBank;
   reg [nbrOfBanks-1:0] 			   writeEnableBank;
   reg [nbrOfBanks-1:0][$clog2(bankAddresses)-1:0] writeAddressBank;
   reg [nbrOfBanks-1:0][$clog2(bankAddresses)-1:0] readAddressBank;
   reg [nbrOfBanks-1:0] 			   readEnableBank;
   reg [nbrOfBanks-1:0][parrallelWidth-1:0] 	   readDataBank;   
   reg [(nbrOfBanks)-1:0] 			   readBank;
   reg [(nbrOfBanks)-1:0] 			   readBank_piped;
   reg [nbrOfPorts-1:0] 			   bankFull;
   reg [$clog2(nbrOfBanks)-1:0] 		   leastUsedBank;
   reg [$clog2(bankAddresses)-1:0] 		   least;
   
   assign readBank = readAddress[addressWidth-1:addressWidth-$clog2(nbrOfBanks)];
   
   always@*
     begin
        readEnableBank=0;
        readAddressBank=0;
        if(readEnable==1)
          begin
             readEnableBank[readBank]=1;
             readAddressBank[readBank]=readAddress[$clog2(bankAddresses)-1:0];
          end   
     end
   
   always@*
     begin
        bankFull=0;
        least = {(bankAddresses){1'b1}};
        leastUsedBank=0;
        for(int i=0; i<nbrOfBanks; i++)
          begin
             if((freeBank[i]==0) | (readBank ==i))
               bankFull[i]=1;
             if((freeBank[i] < least) & (readBank !=i))
               begin
                  least = freeBank[i];
                  leastUsedBank=i;
               end
          end
     end
   
   always@*
     begin
        writeRejected=0;
        writeEnableBank=0;
        writeAddress=0;
        if(writeEnable==1)
          begin
             if(bankFull=={nbrOfBanks{1'b1}})
               begin
                  writeRejected=1;
               end
             else
               begin
                  writeEnableBank[leastUsedBank]=1;
                  writeAddress[$clog2(bankAddresses)-1:0] = writeAddressBank[leastUsedBank];
                  writeAddress[addressWidth-1:addressWidth-$clog2(nbrOfBanks)] = leastUsedBank;
               end           
          end
     end
   
   always@(posedge clk or negedge rstn)
     begin
        if(rstn==0)
          begin
             readBank_piped <=0;
          end
        else
          begin
             readBank_piped <=readBank;
          end
     end
   
   assign readData = readDataBank[readBank_piped];
   
   genvar i;
   generate
      for (i=0; i<nbrOfBanks; i++)
        pingPongBufferBank #(
                             .parrallelWidth(parrallelWidth),
                             .bankAddresses(bankAddresses)
			     )bank(
                                   .clk(clk),
                                   .rstn(rstn),
                                   .initDone(initDoneBank[i]),
                                   .free(freeBank[i]),
                                   .writeData(writeData),
                                   .writeEnable(writeEnableBank[i]),
                                   .writeAddress(writeAddressBank[i]),
                                   .readAddress(readAddressBank[i]),
                                   .readEnable(readEnableBank[i]),
                                   .readData(readDataBank[i]));
   endgenerate


   reg [nbrOfPorts-1:0][addressWidth-1:0] lastWriteAddrForPortNbr;

   always@(posedge clk or negedge rstn)
     begin
        if(rstn==0)
          begin
	     for(int i=0;i<nbrOfPorts;i++)
	       lastWriteAddrForPortNbr[i]<=0;	     
          end
        else
	  begin
	     if(writeEnable && !writeRejected)
	       begin
		  lastWriteAddrForPortNbr[writePort]<=writeAddress;
	       end
	  end
     end // always@ (posedge clk or negedge rstn)
   
   
   twoPortMem   #(.addresses  (addresses),
                  .width      (addressWidth)
		  ) nxtCellPtr (.writeAddress(lastWriteAddrForPortNbr[writePort]),		   
				.writeClk(clk),
				.writeEnable(writeEnable && !writeRejected),
				.writeData(writeAddress),
				.readAddress(readAddress),
				.readClk(clk),
				.readEnable(readEnable),
				.readData(nextReadPtr)
				);

endmodule

// Local Variables:
// verilog-library-directories:("./" "../rtl/" "../genMem/rtl/")
// End:
