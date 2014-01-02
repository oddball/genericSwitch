package genericSwitchPkg;
`include "genericSwitchDefines.vh"

   parameter nbrOfPorts = `nbrOfPorts;
   parameter nbrOfBanks = `nbrOfBanks;
   parameter addresses  = `addresses;
   parameter serialWidth = `serialWidth;
   parameter parrallelWidth = `parrallelWidth;
   parameter nbrOfVirtualDestPort = `nbrOfVirtualDestPort;//for destination port masks. 
   
   typedef struct packed {
      bit [$clog2(parrallelWidth)-1:0] length;
      bit                              dataPresent;
      bit                              startOfFrame;
      bit                              endOfFrame;
      bit                              error;
   } info_type;
   
   typedef struct                      packed {
      bit [parrallelWidth-1:0]         data;
      bit [$clog2(parrallelWidth):0]   length;
      bit                              startOfFrame;
      bit                              endOfFrame;
      bit                              error;
   } cell_type;
   
   typedef struct                      packed {
      bit [$clog2(nbrOfPorts)-1:0]     port;
      bit [$clog2(addresses)-1:0]      address;
      info_type                        info;
   } cell_queue_type;


   
endpackage


