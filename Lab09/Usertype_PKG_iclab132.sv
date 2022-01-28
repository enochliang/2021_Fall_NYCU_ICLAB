//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   2021 ICLAB Fall Course
//   Lab09      : PSG
//   Author     : Chih-Wei Peng
//                
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : Usertype_PKG.sv
//   Module Name : usertype
//   Release version : v1.0 (Release Date: Nov-2021)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

`ifndef USERTYPE
`define USERTYPE

package usertype;

typedef enum logic  [3:0] { No_action	= 4'd0 ,
                            Buy			= 4'd1 ,
							Sell		= 4'd2 ,
							Deposit		= 4'd4 , 
							Use_item	= 4'd6 ,
							Check 		= 4'd8 ,
							Attack      = 4'd10
							}  Action ;
							
typedef enum logic  [3:0] { No_Err       		= 4'd0 ,
                            Already_Have_PKM	= 4'd1 ,
							Out_of_money		= 4'd2 ,
							Bag_is_full			= 4'd4 , 
							Not_Having_PKM	    = 4'd6 ,
						    Has_Not_Grown	    = 4'd8 ,
							Not_Having_Item		= 4'd10 ,
							HP_is_Zero			= 4'd13
							}  Error_Msg ;

typedef enum logic  [3:0] { No_type			= 4'd0 ,
							Grass		 	= 4'd1 ,
							Fire	     	= 4'd2 ,
                            Water	     	= 4'd4 , 
							Electric     	= 4'd8 
							}  PKM_Type ;

typedef enum logic  [3:0] { No_stage		= 4'd0 ,
							Lowest		 	= 4'd1 ,
							Middle	     	= 4'd2 ,
                            Highest	     	= 4'd4  
							}  Stage ;
							
typedef enum logic  [3:0] { No_item			= 4'd0 ,
							Berry	       	= 4'd1 ,
							Medicine      	= 4'd2 ,
							Candy			= 4'd4 ,
                            Bracer	     	= 4'd8
							}  Item ;

typedef logic [7:0] Player_id;
typedef logic [3:0] Item_num;
typedef logic [15:0] Money;
typedef logic [7:0] HP;
typedef logic [7:0] ATK;
typedef logic [7:0] EXP;

typedef struct packed {
	Item_num	berry_num;
	Item_num	medicine_num;
	Item_num	candy_num;
	Item_num	bracer_num;
	Money		money;
} Bag_Info; 

typedef struct packed {
	Stage		stage;
	PKM_Type	pkm_type;
	HP			hp;
	ATK			atk;
	EXP			exp;
} PKM_Info; 

typedef struct packed {
	Bag_Info	bag_info;
	PKM_Info	pkm_info;
} Player_Info; 

typedef union packed{ 
	Money		d_money;
	Player_id	[1:0]d_id;
    Action		[3:0]d_act;
	Item		[3:0]d_item;
	PKM_Type	[3:0]d_type;
} DATA;

//################################################## Don't revise the code above

//#################################
// Type your user define type here
//#################################
typedef enum logic  [3:0] { IDLE				= 4'd0 ,
                            BUY_wait	        = 4'd1 ,
							BUY_item	        = 4'd2 ,
							BUY_pkg	        	= 4'd3 ,
							SELL	       		= 4'd4 ,
							DEPOSIT_wait	    = 4'd5 ,
							DEPOSIT_money       = 4'd6 ,
							CHECK       		= 4'd7 ,
							USE_wait       		= 4'd8 ,
							USE_item       		= 4'd9 ,
							ATTACK_wait       	= 4'd10,
							ATTACK_prepare_opp  = 4'd11,
							ATTACK_put_opp      = 4'd12,
							ATTACK_wait_opp     = 4'd13,
							ATTACK_opp     		= 4'd14,
							OUTPUTMODE			= 4'd15
							}  state_t ;

typedef enum logic  [2:0] { IDLE_empty			= 3'd0 ,
                            IDLE_hold	        = 3'd1 ,
							FETCH_role_put	    = 3'd2 ,
							FETCH_role_wait	    = 3'd3 ,
							CHANGE_role_wait    = 3'd4 ,
							WRITE_def_put	    = 3'd5 ,
							WRITE_def_wait      = 3'd6 ,
							COMPUTE      		= 3'd7 
							}  bridge_state_t ;
//################################################## Don't revise the code below

endpackage
import usertype::*; //import usertype into $unit

`endif

