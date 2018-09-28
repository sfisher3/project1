
/*
 * ANDES Lab - University of California, Merced
 * This class provides the basic functions of a network node.
 *
 * @author UCM ANDES Lab
 * @date   2013/09/03
 *
 */
#include <Timer.h>
#include "includes/command.h"
#include "includes/packet.h"
#include "includes/CommandMsg.h"
#include "includes/sendInfo.h"
#include "includes/channels.h"


module Node{
   uses interface Boot;

   uses interface SplitControl as AMControl;

   uses interface Receive;

   uses interface SimpleSend as Sender;

   uses interface CommandHandler;

   uses interface Timer<TMilli> as Timer;

   uses interface List<uint16_t> as neighbor_list;
}

implementation{
   pack sendPackage;

   // Prototypes
   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);

   event void Boot.booted(){
      call AMControl.start();
      dbg(GENERAL_CHANNEL, "Booted\n");
   }

   event void AMControl.startDone(error_t err){
      if(err == SUCCESS){
         dbg(GENERAL_CHANNEL, "Radio On\n");
         call Timer.startPeriodic(1000);
      }else{
         //Retry until successful
         call AMControl.start();
      }
   }

   event void AMControl.stopDone(error_t err){}

   event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
      dbg(GENERAL_CHANNEL, "Packet Received\n");
      if(len==sizeof(pack)){
         pack* myMsg=(pack*) payload;

         if (myMsg->seq == 100) //for NEIGHBOR DISCOVERY
         {
            switch (myMsg->protocol)
            {
               case PROTOCOL_PING:
                  makePack(&sendPackage, TOS_NODE_ID, myMsg->src, 1, PROTOCOL_PINGREPLY, 100, -1, PACKET_MAX_PAYLOAD_SIZE);
call Sender.send(sendPackage, myMsg->src);
                  dbg (GENERAL_CHANNEL, "%d received Neighbor Ping, responding back to %d\n", TOS_NODE_ID, myMsg->src);
                  return msg;
               case PROTOCOL_PINGREPLY:
                  call neighbor_list.pushfront(myMsg->src);
                  dbg(GENERAL_CHANNEL, "%d received Neighbor Ping from %d\n", TOS_NODE_ID, myMsg->src);
                  return msg;
            }
         }


         if (myMsg->dest == TOS_NODE_ID)
         {
            //DESTINATION MATCHES SOURCE, DONE
            dbg(GENERAL_CHANNEL, "Package Payload: %s\n",myMsg->payload);
            dbg(GENERAL_CHANNEL,"\n\nFOUND\n\n");
         }
         else
         {
            if (myMsg->TTL == 0)
            {
              //PACKET TIMED OUT
            }
            else
            {
               dbg(GENERAL_CHANNEL,"Not Correct, Rebroadcast\n");
               //DECREMENT TTL, REBROADCAST PACKET
               myMsg->TTL--;
               call Sender.send(*myMsg, AM_BROADCAST_ADDR);
            }

         }
         return msg;
      }
}


         if (myMsg->dest == TOS_NODE_ID)
         {
            //DESTINATION MATCHES SOURCE, DONE
            dbg(GENERAL_CHANNEL, "Package Payload: %s\n",myMsg->payload);
            dbg(GENERAL_CHANNEL,"\n\nFOUND\n\n");
         }
         else
         {
            if (myMsg->TTL == 0)
            {
              //PACKET TIMED OUT
            }
            else
            {
               dbg(GENERAL_CHANNEL,"Not Correct, Rebroadcast\n");
               //DECREMENT TTL, REBROADCAST PACKET
               myMsg->TTL--;
               call Sender.send(*myMsg, AM_BROADCAST_ADDR);
            }

         }
         return msg;
      }
      dbg(GENERAL_CHANNEL, "Unknown Packet Type %d\n", len);
      return msg;
   }


   event void CommandHandler.ping(uint16_t destination, uint8_t *payload){
      dbg(GENERAL_CHANNEL, "PING EVENT \n");
      //TTL = # NODES + 1
      makePack(&sendPackage, TOS_NODE_ID, destination, 17, 0, 0, payload, PACKET_MAX_PAYLOAD_SIZE);
      call Sender.send(sendPackage, AM_BROADCAST_ADDR);
   }

   event void CommandHandler.printNeighbors(){}

   event void CommandHandler.printRouteTable(){}

   event void CommandHandler.printLinkState(){}

   event void CommandHandler.printDistanceVector(){}

   event void CommandHandler.setTestServer(){}

   event void CommandHandler.setTestClient(){}

   event void CommandHandler.setAppServer(){}

   event void CommandHandler.setAppClient(){}

   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length){
      Package->src = src;
      Package->dest = dest;
      Package->TTL = TTL;
      Package->seq = seq;
      Package->protocol = protocol;
      if (payload != -1) memcpy(Package->payload, payload, length);
   }

   event void Timer.fired()
   {
      dbg(GENERAL_CHANNEL, "\n--------------\nNeighbor List: %d\n------------\n", TOS_NODE_ID);
      while (!(call neighbor_list.isEmpty()))
      {
          dbg (GENERAL_CHANNEL, " %d\n", (call neighbor_list.popfront()));
      }
      makePack(&sendPackage, TOS_NODE_ID, AM_BROADCAST_ADDR, 1, PROTOCOL_PING, 100, -1, PACKET_MAX_PAYLOAD_SIZE);
      call Sender.send(sendPackage, AM_BROADCAST_ADDR);
   }
}

