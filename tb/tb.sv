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


timeunit 1ns;
timeprecision 1ps;

class switchFrame;
   byte    data[$];
   integer destPort;
   integer srcPort;
endclass

interface pushPortInterface;
   parameter serialWidth = 8;
   parameter nbrOfPorts = 1;
   localparam nbrOfPortsWidth =$clog2(nbrOfPorts);
   logic   pushClk;
   logic [serialWidth-1:0] pushData;
   logic                   push;
   logic                   pushDataStartOfFrame;
   logic                   pushDataEndOfFrame;
   logic 		   pushDataError;
endinterface

interface popPortInterface;
   parameter serialWidth = 8;
   logic                   clk;
   logic [serialWidth-1:0] popData;
   logic                   pop;
   logic                   popDataPresent;
   logic                   popDataStartOfFrame;
   logic                   popDataEndOfFrame;
endinterface

class portPushDriver;
   virtual 		   pushPortInterface intf;
   integer 		   srcPort;
   function new(virtual pushPortInterface intf,integer srcPort);
      this.intf=intf;
      this.srcPort=srcPort;
      intf.pushData=0;
      intf.push=0;
      intf.pushDataStartOfFrame=0;
      intf.pushDataEndOfFrame=0;
      intf.pushDataError=0;
   endfunction // new

   task pushFrame(switchFrame pkt);
      intf.pushData=0;
      intf.push=0;
      intf.pushDataStartOfFrame=0;
      intf.pushDataEndOfFrame=0;
      for (int i = 0; i < pkt.data.size; i++)
        begin
           intf.push=1;
           if(i==0)
             intf.pushDataStartOfFrame=1;
           else
             intf.pushDataStartOfFrame=0;
           if(i==pkt.data.size-1)
             intf.pushDataEndOfFrame=1;
           else
             intf.pushDataEndOfFrame=0;
           
           intf.pushData = pkt.data[i];//.pop_front();
           @(posedge intf.pushClk);
        end // for (int i = 0; i < pkt.data.size; i++)
      intf.pushData=0;
      intf.push=0;
      intf.pushDataStartOfFrame=0;
      intf.pushDataEndOfFrame=0;
   endtask

endclass // portPushDriver

class portPopDriver;
   virtual popPortInterface intf;
   integer destPort;
   function new(virtual popPortInterface intf,integer destPort);
      this.intf=intf;
      this.destPort=destPort;
      intf.pop=0;
   endfunction

   task popFrame(output switchFrame pkt);
      intf.pop=1;
      while(intf.popDataPresent==0)
        @(posedge intf.clk); 
      while(intf.popDataPresent)
        begin
           
           pkt.data.push_back(intf.popData);
           @(posedge intf.clk);
        end
      intf.pop=0;
      pkt.destPort=destPort;
   endtask
   
endclass // portPopDriver


class genericSwitchEnv;
   // contains references to all interfaces in tb
   int nbrOfPorts;
   int nbrOfBanks;
   int addresses;
   int serialWidth;
   int parrallelWidth;
   int nbrOfVirtualDestPort;
   int nbrOfPortsWidth;
   int bankAddresses;
   int addressWidth;
   portPushDriver pushDriver[];
   portPopDriver popDriver[];

   function new(int nbrOfPorts);
      pushDriver = new[nbrOfPorts];
      popDriver= new[nbrOfPorts];
   endfunction // new
endclass

class sequenceBase;
   genericSwitchEnv env;
   string name;
   function new(genericSwitchEnv env,string name);
      this.env = env;
      this.name = name;
   endfunction // new

   virtual task run();
   endtask
   
   
endclass


class sequenceBasic extends sequenceBase;
   switchFrame pkt;
   function new(genericSwitchEnv env,string name);
      super.new(env,name);
      pkt=new();
      for(int j=0; j <2; j++)
	for(int i=0; i <64; i++)
          pkt.data.push_back(i);
   endfunction // new

   virtual task run();
      $display("%t starting sequence %s",$time,name);
      $display("%t pkt.data.size = %d",$time,pkt.data.size);
      fork
         for(int i=0; i <env.nbrOfPorts; i++)
           begin
              pkt.destPort=i;
              pkt.srcPort=i;
              env.pushDriver[i].pushFrame(pkt);
           end
      join
      $display("%t ended sequence %s",$time,name); 
   endtask // run
   
   
endclass




module tb;
   
   parameter nbrOfPorts = `nbrOfPorts;
   parameter nbrOfBanks = `nbrOfBanks;
   parameter addresses  = `addresses;
   parameter serialWidth = `serialWidth;
   parameter parrallelWidth = `parrallelWidth;
   parameter nbrOfVirtualDestPort = `nbrOfVirtualDestPort;//for destination port masks. 
   parameter nbrOfPortsWidth =$clog2(nbrOfPorts);     //Auto-calculated, user dont touch
   parameter bankAddresses = addresses / nbrOfBanks;  //Auto-calculated, user dont touch
   parameter addressWidth = $clog2(addresses);       //Auto-calculated, user dont touch

   
   initial assert( nbrOfPorts > 1 ) else $display("nbrOfPorts needs to be greater than 1");



   
   reg tmp_clk;

   /*AUTOREGINPUT*/
   // Beginning of automatic reg inputs (for undeclared instantiated-module inputs)
   reg clk;                    // To DUT of genericSwitch.v
   reg [nbrOfPorts-1:0] pop;                    // To DUT of genericSwitch.v
   reg [nbrOfPorts-1:0] popClk;                 // To DUT of genericSwitch.v
   reg [nbrOfPorts-1:0] push;                   // To DUT of genericSwitch.v
   reg [nbrOfPorts-1:0] pushClk;                // To DUT of genericSwitch.v
   reg [nbrOfPorts-1:0] [serialWidth-1:0] pushData;// To DUT of genericSwitch.v
   reg [nbrOfPorts-1:0] 		  pushDataEndOfFrame;     // To DUT of genericSwitch.v
   reg [nbrOfPorts-1:0] 		  pushDataError;          // To DUT of genericSwitch.v
   reg [nbrOfPorts-1:0] 		  pushDataStartOfFrame;   // To DUT of genericSwitch.v
   reg 					  rstn;                   // To DUT of genericSwitch.v
   // End of automatics
   /*AUTOWIRE*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire [nbrOfPorts-1:0] [serialWidth-1:0] popData;// From DUT of genericSwitch.v
   wire [nbrOfPorts-1:0] 		   popDataEndOfFrame;     // From DUT of genericSwitch.v
   wire [nbrOfPorts-1:0] 		   popDataError;          // From DUT of genericSwitch.v
   wire [nbrOfPorts-1:0] 		   popDataPresent;        // From DUT of genericSwitch.v
   wire [nbrOfPorts-1:0] 		   popDataStartOfFrame;   // From DUT of genericSwitch.v
   // End of automatics
   





   
   genericSwitch #(/*AUTOINSTPARAM*/
                   // Parameters
                   .nbrOfPorts          (nbrOfPorts),
                   .nbrOfBanks          (nbrOfBanks),
                   .addresses           (addresses),
                   .serialWidth         (serialWidth),
                   .parrallelWidth      (parrallelWidth),
                   .nbrOfVirtualDestPort(nbrOfVirtualDestPort),
                   .nbrOfPortsWidth     (nbrOfPortsWidth),
                   .bankAddresses       (bankAddresses),
                   .addressWidth        (addressWidth)
		   )DUT (/*AUTOINST*/
                         // Outputs
                         .popData            (popData/*[nbrOfPorts-1:0][serialWidth-1:0]*/),
                         .popDataPresent     (popDataPresent[nbrOfPorts-1:0]),
                         .popDataError       (popDataError[nbrOfPorts-1:0]),
                         .popDataStartOfFrame(popDataStartOfFrame[nbrOfPorts-1:0]),
                         .popDataEndOfFrame  (popDataEndOfFrame[nbrOfPorts-1:0]),
                         // Inputs
                         .clk                (clk),
                         .rstn               (rstn),
                         .pushData           (pushData/*[nbrOfPorts-1:0][serialWidth-1:0]*/),
                         .pushClk            (pushClk[nbrOfPorts-1:0]),
                         .push               (push[nbrOfPorts-1:0]),
                         .pushDataStartOfFrame(pushDataStartOfFrame[nbrOfPorts-1:0]),
                         .pushDataEndOfFrame (pushDataEndOfFrame[nbrOfPorts-1:0]),
                         .pushDataError      (pushDataError[nbrOfPorts-1:0]),
                         .popClk             (popClk[nbrOfPorts-1:0])
			 );
   
   initial
     begin
	rstn <= 1;
	#3;
        rstn <= 0;       
        tmp_clk <= 1;
        #3;
        rstn <= 1;
        forever
          #1 tmp_clk <=~tmp_clk;
     end

   initial
     begin
        clk <=0;
        forever
          begin
             //(((32/8)/2)/2)=1 then we have the same clk
             repeat(((parrallelWidth/serialWidth)/nbrOfPorts)/2)
               begin
                  @(posedge tmp_clk);
               end
             clk <=~clk;
          end
     end
   
   assign pushClk = {nbrOfPorts{clk}};
   assign popClk= {nbrOfPorts{clk}};

   virtual pushPortInterface pushIntf[nbrOfPorts];
   virtual popPortInterface popIntf[nbrOfPorts];

   genvar  i;
   generate 
      for (i=0 ; i <nbrOfPorts ; i++)
        begin
           pushPortInterface my_pushIntf();
           popPortInterface my_popIntf();
           initial pushIntf[i] = my_pushIntf;
           initial popIntf[i] = my_popIntf;      
           always@*
             begin
                my_pushIntf.pushClk=pushClk[i];
                pushData[i]=my_pushIntf.pushData;
                push[i]=my_pushIntf.push;
                pushDataStartOfFrame[i]=my_pushIntf.pushDataStartOfFrame;
                pushDataEndOfFrame[i]=my_pushIntf.pushDataEndOfFrame;
		pushDataError[i]=my_pushIntf.pushDataError;
                my_popIntf.clk=clk;
                my_popIntf.popData=popData[i];
                pop[i]=my_popIntf.pop;
                my_popIntf.popDataPresent=popDataPresent[i];
                my_popIntf.popDataStartOfFrame=popDataStartOfFrame[i];
                my_popIntf.popDataEndOfFrame=popDataEndOfFrame[i];
             end
        end 
   endgenerate;
   
   
   genericSwitchEnv env;
   sequenceBasic testcaseBasic;
   
   initial
     begin
        $timeformat(-9,3,"ns",0);
        $display("%t initial",$time);
        $display("%t get_initial_random_seed = %d",$time,$get_initial_random_seed());
        // hookup the env
        env = new(nbrOfPorts);
        env.nbrOfPorts = nbrOfPorts;
        env.nbrOfBanks = nbrOfBanks;
        env.addresses  = addresses;
        env.serialWidth = serialWidth;
        env.parrallelWidth = parrallelWidth;
        env.nbrOfVirtualDestPort = nbrOfVirtualDestPort;
        env.nbrOfPortsWidth =nbrOfPortsWidth;
        env.bankAddresses = bankAddresses;
        env.addressWidth = addressWidth;
        $display("%t create drivers",$time);
        for(int i=0; i <nbrOfPorts; i++)
          begin
             env.pushDriver[i] = new(pushIntf[i],i);
             env.popDriver[i] = new(popIntf[i],i);
          end        
        repeat(10)
          begin
             @(posedge clk);
          end

        testcaseBasic =new(env,"testcaseBasic");
        $display("%t Start sequence",$time);
        fork       
           testcaseBasic.run();
           # 1us;
        join
	# 10us;
        $display("%t Done",$time);          
        $stop();
     end

   




   
   
endmodule


// Local Variables:
// verilog-library-directories:("." "../rtl/" "../genMem/rtl/")
// End:
