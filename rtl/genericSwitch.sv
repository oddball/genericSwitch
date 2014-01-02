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
`include "genericSwitchDefines.vh"
import genericSwitchPkg::*;

module genericSwitch#(
                      parameter nbrOfPorts = `nbrOfPorts,
                      parameter nbrOfBanks = `nbrOfBanks,
                      parameter addresses  = `addresses,
                      parameter serialWidth = `serialWidth,
                      parameter parrallelWidth = `parrallelWidth,
                      parameter nbrOfVirtualDestPort = `nbrOfVirtualDestPort,//for destination port masks. 
                      parameter nbrOfPortsWidth =$clog2(nbrOfPorts),
                      parameter bankAddresses = addresses / nbrOfBanks,
                      parameter addressWidth = $clog2(addresses))
   (
    input 				     clk,
    input 				     rstn,
    input [nbrOfPorts-1:0][serialWidth-1:0]  pushData,
    input [nbrOfPorts-1:0] 		     pushClk,
    input [nbrOfPorts-1:0] 		     push,
    input [nbrOfPorts-1:0] 		     pushDataStartOfFrame,
    input [nbrOfPorts-1:0] 		     pushDataEndOfFrame,
    input [nbrOfPorts-1:0] 		     pushDataError,
    input [nbrOfPorts-1:0] 		     popClk,
    output [nbrOfPorts-1:0][serialWidth-1:0] popData,
    output [nbrOfPorts-1:0] 		     popDataPresent,
    output [nbrOfPorts-1:0] 		     popDataError,
    output [nbrOfPorts-1:0] 		     popDataStartOfFrame,
    output [nbrOfPorts-1:0] 		     popDataEndOfFrame
    );

   wire [addressWidth-1:0] 		     readAddress;
   wire [addressWidth-1:0] 		     writeAddress;      
   wire                                      writeRejected;
   wire 				     writeEnable;
   wire 				     wroteCell;
   wire [$clog2(nbrOfPorts)-1:0] 	     writePort;
   cell_queue_type writtenCell;
   info_type writeInfo;
   wire [parrallelWidth-1:0] 		     writeData;
   info_type readInfo;
   wire [parrallelWidth-1:0] 		     readData;
   wire [$clog2(nbrOfPorts)-1:0] 	     readPort;
   wire [nbrOfPorts-1:0] 		     psFull;
   wire [addressWidth-1:0] 		     nextReadPtr;
   
   serialParallelConverterTop #(
                                // Parameters
                                .nbrOfPorts     (nbrOfPorts),
                                .parrallelWidth (parrallelWidth),
                                .serialWidth    (serialWidth),
				.bufferAddresses(addresses)
                                )sp(
                                    // Outputs    
				    .writeEnable          (writeEnable),
				    .wroteCell            (wroteCell),
				    .writtenCell          (writtenCell),
                                    .writeData            (writeData),
				    .writeInfo            (writeInfo),
				    .writePort            (writePort),
                                    // Inputs
                                    .clk                  (clk),
                                    .pushClk              (pushClk[nbrOfPorts-1:0]),
                                    .rstn                 (rstn),
                                    .push                 (push[nbrOfPorts-1:0]),
                                    .pushData             (pushData),
                                    .pushDataStartOfFrame (pushDataStartOfFrame[nbrOfPorts-1:0]),
                                    .pushDataEndOfFrame   (pushDataEndOfFrame[nbrOfPorts-1:0]),
                                    .pushDataError        (pushDataError[nbrOfPorts-1:0]),
				    .writeRejected        (writeRejected),
				    .writeAddress         (writeAddress)
				    );
   
   
   pingPongBuffer #(
                    // Parameters
                    .nbrOfPorts         (nbrOfPorts),
                    .parrallelWidth     (parrallelWidth+$bits(info_type)),
                    .nbrOfBanks         (nbrOfBanks),
                    .addresses          (addresses)
		    )buffer(
			    // Outputs           
			    .writeRejected       (writeRejected),
                            .writeAddress        (writeAddress),
                            .readData            ({readData,readInfo}),
			    .nextReadPtr         (nextReadPtr),
                            // Inputs
                            .clk                 (clk),
                            .rstn                (rstn),
                            .writeEnable         (writeEnable),
			    .writeData           ({writeData,writeInfo}),
                            .readAddress         (readAddress),
			    .readEnable          (readEnable),
			    .writePort           (writePort),
			    .readPort            (readPort)
			    );

   
   parallelSerialConverterTop #(
                                // Parameters
                                .nbrOfPorts     (nbrOfPorts),
                                .parrallelWidth (parrallelWidth),
                                .serialWidth    (serialWidth))
   ps(
      .pushData           (readData),
      .pushInfo           (readInfo),
      .popData            (popData),
      .popDataPresent     (popDataPresent[nbrOfPorts-1:0]),
      .popDataStartOfFrame(popDataStartOfFrame[nbrOfPorts-1:0]),
      .popDataEndOfFrame  (popDataEndOfFrame[nbrOfPorts-1:0]),
      .popDataError       (popDataError[nbrOfPorts-1:0]),
      .full               (psFull),
      .clk                (clk),
      .rstn               (rstn),
      .popClk             (popClk[nbrOfPorts-1:0]),
      .push               (readEnable),
      .pushPort           (readPort)
      );
   

   switchControl #(
                   // Parameters
                   .nbrOfPorts          (nbrOfPorts),
                   .nbrOfBanks          (nbrOfBanks),
                   .addresses           (addresses),
                   .serialWidth         (serialWidth),
                   .parrallelWidth      (parrallelWidth),
                   .nbrOfVirtualDestPort(nbrOfVirtualDestPort),
                   .addressWidth        (addressWidth)
                   )control(/*AUTOINST*/
			    // Interfaces
			    .writtenCell	(writtenCell),
			    // Outputs
			    .readAddress	(readAddress[addressWidth-1:0]),
			    .readPort		(readPort[$clog2(nbrOfPorts)-1:0]),
			    .readEnable		(readEnable),
			    // Inputs
			    .clk		(clk),
			    .rstn		(rstn),
			    .wroteCell		(wroteCell),
			    .psFull             (psFull),
			    .readInfo           (readInfo),
			    .nextReadPtr        (nextReadPtr)
			    );


endmodule
