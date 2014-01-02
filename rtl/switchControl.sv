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

module switchControl#(parameter nbrOfPorts = 1,
                      parameter nbrOfBanks = 4,
                      parameter addresses  = 32,
                      parameter serialWidth = 8,
                      parameter parrallelWidth = 512,
                      parameter nbrOfVirtualDestPort = 32,
                      parameter addressWidth = $clog2(addresses)
                      )
   (
    input 				clk,
    input 				rstn,
    input 				wroteCell,
    input 				cell_queue_type writtenCell,
    input [nbrOfPorts-1:0] 		psFull,
    input [addressWidth-1:0] 		nextReadPtr,
    input 				info_type readInfo,
    output reg [addressWidth-1:0] 	readAddress,
    output reg [$clog2(nbrOfPorts)-1:0] readPort,
    output reg 				readEnable
    );
   
   cell_queue_type inputQueue[$];
   cell_queue_type inComingCell[nbrOfPorts];

   // inputQueue
   always@(posedge clk or negedge rstn)
     begin
	if(!rstn)
	  begin
	     for( int i=0; i<nbrOfPorts;i++)
	       inComingCell[i]<=0;
	  end
	else
	  begin
	     if(wroteCell && writtenCell.info.startOfFrame && !writtenCell.info.endOfFrame)
	       begin
		  inComingCell[writtenCell.port]<=writtenCell;		  
	       end
	     else if(wroteCell && writtenCell.info.startOfFrame && writtenCell.info.endOfFrame)
	       begin
		  inputQueue.push_back(writtenCell);
		  inComingCell[writtenCell.port]<=0;
		  $display("inputQueue.push_back(writtenCell);");
	       end
	     else if(wroteCell && !writtenCell.info.startOfFrame && writtenCell.info.endOfFrame)
	       begin
		  inputQueue.push_back(inComingCell[writtenCell.port]);
		  inComingCell[writtenCell.port]<=0;
		  $display("inputQueue.push_back(inComingCell[writtenCell.port]);");
	       end	     
	  end
     end // always@ (posedge clk or negedge rstn)
   
   



   
   
   cell_queue_type outputQueue[nbrOfPorts][$];

   cell_queue_type item;
   int destPort;

   function int addressLookup(int inputPort);
      // so this will be rather complex. Understatement :)
      return inputPort;
   endfunction

   
   // addressloopkup
   always@(posedge clk)
     begin
	if(inputQueue.size!=0)
	  begin
	     item = inputQueue.pop_front();
	     outputQueue[addressLookup(item.port)].push_back(item);
	  end
     end
   
   reg [$clog2(nbrOfPorts):0] lastServicedPort;
   cell_queue_type outItem;



   // scheduler
   reg [nbrOfPorts-1:0][addressWidth-1:0] lastReadAddrForPortNbr;
   reg [nbrOfPorts-1:0][addressWidth-1:0] n_lastReadAddrForPortNbr;   
   reg [addressWidth-1:0] 		  pipedReadAddress;
   reg 					  pipedReadEnable;
   reg [$clog2(nbrOfPorts)-1:0] 	  pipedReadPort;
   reg [nbrOfPorts-1:0] 		  pktInProgress;
   reg [nbrOfPorts-1:0] 		  n_pktInProgress;

   
   always@(posedge clk or negedge rstn)
     begin
	if(rstn==0)
          begin
	     readAddress<=0;
	     readPort<=0;
	     readEnable<=0;
	     lastServicedPort <={nbrOfPorts+1{1'b1}}; //no port serviced	     
	  end
	else
	  begin
	     readAddress<=0;
	     readPort<=0;
	     readEnable<=0;
	     lastServicedPort <={nbrOfPorts+1{1'b1}}; //no port serviced
	     for( int i=0; i<nbrOfPorts;i++)
	       begin
		  if(i!=lastServicedPort)
		    begin
		       if(~psFull[i] &&  n_pktInProgress[i])
			 begin
			    $display("%t Scheduler servicing output port %d, reading next cell in Frame",$time,i);
			    readEnable<=1;
			    readPort<=i;
			    readAddress<=n_lastReadAddrForPortNbr[i];
			    lastServicedPort<=i;
			    break;
			 end
		       else if(~psFull[i] && outputQueue[i].size()!=0 && n_pktInProgress[i]==0)
			 begin
			    $display("~psFull[i] = %d, outputQueue[i].size() = %d",~psFull[i],outputQueue[i].size());
			    outItem = outputQueue[i].pop_front();		  
			    $display("%t Scheduler servicing output port %d, reading new pkt header at address %d",$time,i,outItem.address);
			    readEnable<=1;
			    readPort<=i;
			    readAddress<=outItem.address;
			    lastServicedPort<=i;
			    break;
			 end
		    end
	       end // for ( int i=0; i<nbrOfPorts;i++)
	  end // else: !if(rstn==0)
     end // always@ (posedge clk or negedge rstn)
   
   
   
   int outputQueueSize[nbrOfPorts];

   always@*
     begin
	for( int i=0; i<nbrOfPorts;i++)
	  outputQueueSize[i]=outputQueue[i].size();
     end


   always@*
     begin
	n_lastReadAddrForPortNbr = lastReadAddrForPortNbr;
	n_pktInProgress = pktInProgress;
	if(pipedReadEnable)
	  begin
	     if(pipedReadEnable)
	       begin
		  n_lastReadAddrForPortNbr[pipedReadPort]<=nextReadPtr;
	       end
	     if(readInfo.startOfFrame)
	       n_pktInProgress[pipedReadPort]<= 1'b1;		  
	     if(readInfo.endOfFrame)
	       n_pktInProgress[pipedReadPort]<= 1'b0;		  
	  end	
     end

   always@(posedge clk or negedge rstn)
     begin
        if(rstn==0)
          begin
	     for(int i=0;i<nbrOfPorts;i++)
	       lastReadAddrForPortNbr[i]<=0;	    
	     pipedReadAddress <= 0;
	     pipedReadEnable <= 0;
	     pipedReadPort <= 0;
	     pktInProgress<= 0;
          end	
        else
	  begin
	     pipedReadEnable <= readEnable;	     
	     if(readEnable)
	       begin
		  pipedReadPort <= readPort;
	       end
	     lastReadAddrForPortNbr <= n_lastReadAddrForPortNbr;

	     pktInProgress<=n_pktInProgress;
	  end
     end // always@ (posedge clk or negedge rstn)







   
endmodule // switchControl


