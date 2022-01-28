//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Si2 LAB @NYCU ED430
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2021 Fall
//   Midterm Proejct            : MRA  
//   Author                     : Lin-Hung, Lai
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : MRA.v
//   Module Name : MRA
//   Release version : V1.0 (Release Date: 2021-10)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module MRA(
	// CHIP IO
	clk            	,	
	rst_n          	,	
	in_valid       	,	
	frame_id        ,	
	net_id         	,	  
	loc_x          	,	  
    loc_y         	,
	cost	 		,		
	busy         	,

    // AXI4 IO
	     arid_m_inf,
	   araddr_m_inf,
	    arlen_m_inf,
	   arsize_m_inf,
	  arburst_m_inf,
	  arvalid_m_inf,
	  arready_m_inf,
	
	      rid_m_inf,
	    rdata_m_inf,
	    rresp_m_inf,
	    rlast_m_inf,
	   rvalid_m_inf,
	   rready_m_inf,
	
	     awid_m_inf,
	   awaddr_m_inf,
	   awsize_m_inf,
	  awburst_m_inf,
	    awlen_m_inf,
	  awvalid_m_inf,
	  awready_m_inf,
	
	    wdata_m_inf,
	    wlast_m_inf,
	   wvalid_m_inf,
	   wready_m_inf,
	
	      bid_m_inf,
	    bresp_m_inf,
	   bvalid_m_inf,
	   bready_m_inf 
);
// ===============================================================
//  					Parameter Declaration 
// ===============================================================
parameter ID_WIDTH=4, DATA_WIDTH=128, ADDR_WIDTH=32;    // DO NOT modify AXI4 Parameter
parameter NUM_ROW = 64, NUM_COLUMN = 64; 				
parameter MAX_NUM_MACRO = 15;


// ===============================================================
//  					Input / Output 
// ===============================================================

// << CHIP io port with system >>
input 			  	clk,rst_n;
input 			   	in_valid;
input  [4:0] 		frame_id;
input  [3:0]       	net_id;     
input  [5:0]       	loc_x; 
input  [5:0]       	loc_y; 
output reg [13:0] 	cost;
output reg          busy;       
  
// AXI Interface wire connecttion for pseudo DRAM read/write
/* Hint:
       Your AXI-4 interface could be designed as a bridge in submodule,
	   therefore I declared output of AXI as wire.  
	   Ex: AXI4_interface AXI4_INF(...);
*/

// ------------------------
// <<<<< AXI READ >>>>>
// ------------------------
// (1)	axi read address channel 
output wire [ID_WIDTH-1:0]      arid_m_inf;//fixed
output wire [1:0]            arburst_m_inf;//fixed
output wire [2:0]             arsize_m_inf;//fixed
output wire [7:0]              arlen_m_inf;//fixed
output wire                  arvalid_m_inf;//auto-connected
input  wire                  arready_m_inf;//from slave (used) (state)
output wire [ADDR_WIDTH-1:0]  araddr_m_inf;//auto-connected
// ------------------------
// (2)	axi read data channel 
input  wire [ID_WIDTH-1:0]       rid_m_inf;//don't care
input  wire                   rvalid_m_inf;//from slave (used) (state)
output wire                   rready_m_inf;//auto-connected
input  wire [DATA_WIDTH-1:0]   rdata_m_inf;//auto-connected
input  wire                    rlast_m_inf;//from slave (used) (state)
input  wire [1:0]              rresp_m_inf;//don't care
// ------------------------
// <<<<< AXI WRITE >>>>>
// ------------------------
// (1) 	axi write address channel 
output wire [ID_WIDTH-1:0]      awid_m_inf;
output wire [1:0]            awburst_m_inf;
output wire [2:0]             awsize_m_inf;
output wire [7:0]              awlen_m_inf;
output wire                  awvalid_m_inf;
input  wire                  awready_m_inf;
output wire [ADDR_WIDTH-1:0]  awaddr_m_inf;
// -------------------------
// (2)	axi write data channel 
output wire                   wvalid_m_inf;
input  wire                   wready_m_inf;
output wire [DATA_WIDTH-1:0]   wdata_m_inf;
output wire                    wlast_m_inf;
// -------------------------
// (3)	axi write response channel 
input  wire  [ID_WIDTH-1:0]      bid_m_inf;
input  wire                   bvalid_m_inf;
output wire                   bready_m_inf;
input  wire  [1:0]             bresp_m_inf;
// -----------------------------


// ===============================================================
//  					Variable Declare
// ===============================================================

// Parameter
parameter RESET                       = 0 ;
parameter INPUTMODE                   = 1 ;
parameter READ_MAP_setaddr            = 2 ;
parameter READ_MAP_getdt_f_dram       = 3 ;
parameter READ_MAP_snddt_t_sram       = 4 ;
parameter READ_MAP_snddt_t_sram_last  = 5 ;
parameter ROUTING_trav                = 6 ;
parameter ROUTING_backtrav            = 7 ;
parameter ROUTING_wait_store          = 8 ;
parameter WRITE_MAP_putaddr           = 9 ;
parameter WRITE_MAP_waitdt            = 10;
parameter WRITE_MAP_putdt             = 11;
parameter WRITE_MAP_putdt_last        = 12;
parameter WRITE_MAP_wait_ok           = 13;
parameter OUTPUTMODE                  = 14;
integer i,j;

// Register

// FSM
reg [3:0] state;
reg [3:0] next_state;

reg data_type;

// input register
reg  [4:0] 	frame_id_store;//( A )
reg  [3:0]  net_id_array   [1:15];//( B )
reg  [5:0]  S_loc_x_array  [1:15];//( C )
reg  [5:0]  S_loc_y_array  [1:15];
reg  [5:0]  T_loc_x_array  [1:15];
reg  [5:0]  T_loc_y_array  [1:15];
reg  [3:0]  net_id_pointer;//( D )

reg  [3:0]  cur_id;
	always@(*)begin
		cur_id = net_id_array[net_id_pointer];
	end

// store Start point & Target point
wire [11:0] cur_S,cur_T;
assign cur_S = {S_loc_y_array[net_id_pointer],S_loc_x_array[net_id_pointer]};
assign cur_T = {T_loc_y_array[net_id_pointer],T_loc_x_array[net_id_pointer]};
wire [5:0] cur_S_x,cur_S_y,cur_T_x,cur_T_y;
assign {cur_S_y,cur_S_x} = cur_S;
assign {cur_T_y,cur_T_x} = cur_T;
//

wire [5:0] up_T_x,up_T_y;
assign up_T_x = cur_T[5:0];
assign up_T_y = cur_T[11:6]-1;
wire [5:0] down_T_x,down_T_y;
assign down_T_x = cur_T[5:0];
assign down_T_y = cur_T[11:6]+1;
wire [5:0] left_T_x,left_T_y;
assign left_T_x = cur_T[5:0]-1;
assign left_T_y = cur_T[11:6];
wire [5:0] right_T_x,right_T_y;
assign right_T_x = cur_T[5:0]+1;
assign right_T_y = cur_T[11:6];

//---

//====== data register ======
reg  [127:0] dram_read_in;

reg  [5:0] counter;// ( 1 )

reg tra_cnt;// ( 2 )

reg  [11:0] addr;// ( 3 )
	wire [11:0] up_addr,down_addr,left_addr,right_addr;
	wire [5:0]  addr_x,addr_y,up_addr_x,up_addr_y,down_addr_x,down_addr_y,left_addr_x,left_addr_y,right_addr_x,right_addr_y;
	assign addr_x = addr[5:0];
	assign addr_y = addr[11:6];
	assign up_addr = addr - 12'd64;
	assign up_addr_x = up_addr[5:0];
	assign up_addr_y = up_addr[11:6];
	assign down_addr = addr + 12'd64;
	assign down_addr_x = down_addr[5:0];
	assign down_addr_y = down_addr[11:6];
	assign left_addr = addr - 12'd1;
	assign left_addr_x = left_addr[5:0];
	assign left_addr_y = left_addr[11:6];
	assign right_addr = addr + 12'd1;
	assign right_addr_x = right_addr[5:0];
	assign right_addr_y = right_addr[11:6];
//( 3 )

reg [1:0] cur_step;// ( 4 )



reg  [1:0] tra_map [0:63][0:63];    // ( 5 )

reg start_tra;

wire [127:0] dram_read_out;

genvar a,b;
// tra_map_net
wire [1:0]  tra_map_net [0:63][0:63];
	generate
		for(a=0;a<64;a=a+1)
			for(b=0;b<64;b=b+1)begin
				assign tra_map_net[a][b] = tra_map[a][b];
			end
	endgenerate
//---

// : Check whether this point 1 or 2.
wire tra_map1or2 [0:63][0:63];
	generate
		for(a=0;a<64;a=a+1)
			for(b=0;b<64;b=b+1)begin
				assign tra_map1or2[a][b] = tra_map[a][b][1] ^ tra_map[a][b][0];
			end
	endgenerate
//---

// : When forward traverse touched the target point.
reg touch_flag;
	always@(*)begin
		if      (tra_map_net[up_T_y][up_T_x][1]^tra_map_net[up_T_y][up_T_x][0]) touch_flag = 1;
		else if (tra_map_net[down_T_y][down_T_x][1]^tra_map_net[down_T_y][down_T_x][0]) touch_flag = 1;
		else if (tra_map_net[left_T_y][left_T_x][1]^tra_map_net[left_T_y][left_T_x][0]) touch_flag = 1;
		else if (tra_map_net[right_T_y][right_T_x][1]^tra_map_net[right_T_y][right_T_x][0]) touch_flag = 1;
		else touch_flag = 0;
	end
//





// ===== flags =====

// go back
reg [2:0] go_back_flag ;

always@(*)begin
	if ( !start_tra && tra_map1or2[down_addr_y][down_addr_x] && ( (tra_map_net[down_addr_y][down_addr_x]==cur_step && tra_cnt) || 
			                  										   (tra_map_net[down_addr_y][down_addr_x]!=cur_step && !tra_cnt ) ) &&
		  (addr_y != 63)
			) go_back_flag = 2;//down
	else if  ( !start_tra && tra_map1or2[up_addr_y][up_addr_x] && ( (tra_map_net[up_addr_y][up_addr_x]==cur_step && tra_cnt) || 
		  				  									   (tra_map_net[up_addr_y][up_addr_x]!=cur_step && !tra_cnt ) ) &&
		  (addr_y != 0)
		) go_back_flag = 1;//up
	else if ( !start_tra && tra_map1or2[right_addr_y][right_addr_x] && ( (tra_map_net[right_addr_y][right_addr_x]==cur_step && tra_cnt) || 
							  											 (tra_map_net[right_addr_y][right_addr_x]!=cur_step && !tra_cnt ) ) &&
		  (addr_x != 63)
			) go_back_flag = 4;//right
	else if ( !start_tra && tra_map1or2[left_addr_y][left_addr_x] && ( (tra_map_net[left_addr_y][left_addr_x]==cur_step && tra_cnt) || 
							  										   (tra_map_net[left_addr_y][left_addr_x]!=cur_step && !tra_cnt ) ) &&
		  (addr_x != 0)
			) go_back_flag = 3;//left
	else go_back_flag = 0;
end
//---

// back traverse is finished for a macro.
wire back_tra_end_flag;
	assign back_tra_end_flag = ( (up_addr == cur_S) || (down_addr == cur_S) || (left_addr == cur_S) || (right_addr == cur_S) ) ? 1 : 0;
//---

// whole routing process is finished. 
wire route_fini;
	assign route_fini = ( back_tra_end_flag && (net_id_pointer == 1) ) ? 1 : 0;
//---


// ===== sram =====
reg [1:0] cost_cnt;
reg [3:0] weight_store;
reg weight_store_act_flag,cost_act_flag;


// read_map_sram_flag
reg read_map_sram_flag;
	always@(*)begin
		if(state == WRITE_MAP_waitdt && counter<32) read_map_sram_flag = 1;
		else read_map_sram_flag = 0;
	end
//---

// write_map_sram_flag
reg write_map_sram_flag;
	always@(*)begin
		if ( ((state == READ_MAP_snddt_t_sram) || (state == READ_MAP_snddt_t_sram_last)) && !data_type) write_map_sram_flag = 1;
		else if(state == ROUTING_backtrav && !start_tra) write_map_sram_flag = 1;
		else write_map_sram_flag = 0;
	end
//---

// read_weight_sram_flag
reg read_weight_sram_flag;
	always@(*)begin
		if   (state == ROUTING_backtrav && !start_tra) read_weight_sram_flag = 1;
		else read_weight_sram_flag = 0;
	end
//---

//write_weight_sram_flag
reg write_weight_sram_flag;
	always@(*)begin
		if   ( ((state == READ_MAP_snddt_t_sram) || (state == READ_MAP_snddt_t_sram_last)) && data_type ) write_weight_sram_flag = 1;
		else write_weight_sram_flag = 0;
	end
//---

// map_CEN, map_WEN, map_OEN (OK)
reg  map_CEN,map_WEN,map_OEN;
	always@(*)begin
		if ( read_map_sram_flag ) begin
			map_CEN = 0;
			map_WEN = 1;
			map_OEN = 0;
		end
		else if( write_map_sram_flag ) begin
			map_CEN = 0;
			map_WEN = 0;
			map_OEN = 0;
		end
		else  begin
			map_CEN = 1;
			map_WEN = 0;
			map_OEN = 0;
		end
	end
//---

// weight_CEN, weight_WEN, weight_OEN (OK)
reg  weight_CEN,weight_WEN,weight_OEN;
	always@(*)begin
		if ( read_weight_sram_flag ) begin
			weight_CEN = 0;
			weight_WEN = 1;
			weight_OEN = 0;
		end
		else if( write_weight_sram_flag ) begin
			weight_CEN = 0;
			weight_WEN = 0;
			weight_OEN = 0;
		end
		else  begin
			weight_CEN = 1;
			weight_WEN = 0;
			weight_OEN = 0;
		end
	end
//---


//map_D
reg [3:0] map_D;
always@(*)begin
	if( ((state == READ_MAP_snddt_t_sram) || (state == READ_MAP_snddt_t_sram_last)) && !data_type ) map_D = dram_read_out[3:0];
	else if( state == ROUTING_backtrav && !start_tra ) map_D = cur_id;
	else map_D = 0;
end

//weight_D
reg [3:0] weight_D;
always@(*)begin
	if( ((state == READ_MAP_snddt_t_sram) || (state == READ_MAP_snddt_t_sram_last)) && data_type ) weight_D = dram_read_out[3:0];
	else weight_D = 0;
end

//map_Q
wire [3:0] map_Q;

//weight_Q
wire [3:0] weight_Q;

wire [12:0] index;
assign index=0;

// ===============================================================
//  					Finite State Machine
// ===============================================================



//state (OK)
always@(negedge rst_n or posedge clk)begin
	if (!rst_n) state <= 0;
	else        state <= next_state;
end
//next_state
always@(*)begin
	case(state)
		RESET:begin
			if(in_valid)next_state = INPUTMODE;
			else next_state = state;
		end
		INPUTMODE:begin
			if(!in_valid)next_state = READ_MAP_setaddr;
			else next_state = state;
		end
		READ_MAP_setaddr:begin
			if(arready_m_inf) next_state = READ_MAP_getdt_f_dram;
			else next_state = state;
		end
		READ_MAP_getdt_f_dram:begin
			if(rvalid_m_inf)begin
				if (rlast_m_inf)next_state = READ_MAP_snddt_t_sram_last;
				else next_state = READ_MAP_snddt_t_sram;
			end 
			else next_state = state;            
		end
		READ_MAP_snddt_t_sram:begin
			if(counter == 31) next_state = READ_MAP_getdt_f_dram;
			else next_state = state;
		end
		READ_MAP_snddt_t_sram_last:begin
			if(counter == 31)begin
				if ( data_type ) next_state = ROUTING_trav;
				else next_state = READ_MAP_setaddr;
			end
			else next_state = state;
		end
		ROUTING_trav:begin
			if(touch_flag) next_state = ROUTING_backtrav;
			else next_state = state;
		end
		ROUTING_backtrav:begin
			if     ( route_fini ) next_state = WRITE_MAP_putaddr;
			else if( back_tra_end_flag ) next_state = ROUTING_wait_store;
			else next_state = state;
		end
		ROUTING_wait_store:begin
			if(cost_cnt == 2) next_state = ROUTING_trav;
			else next_state = state;
		end
		WRITE_MAP_putaddr:begin
			if(awready_m_inf) next_state = WRITE_MAP_waitdt;
			else next_state = state;
		end
		WRITE_MAP_waitdt:begin
			if(counter == 33)begin
				if   ( addr == 12'hfff ) next_state = WRITE_MAP_putdt_last;
				else next_state = WRITE_MAP_putdt;
			end
			else next_state = state;
		end
		WRITE_MAP_putdt:begin
			if(wready_m_inf) next_state = WRITE_MAP_waitdt;
			else next_state = state;
		end
		WRITE_MAP_putdt_last:begin
			if(wready_m_inf) next_state = WRITE_MAP_wait_ok;
			else next_state = state;
		end
		WRITE_MAP_wait_ok:begin
			if((bresp_m_inf==0) && bvalid_m_inf ) next_state = OUTPUTMODE;
			else next_state = state;
		end
		OUTPUTMODE : next_state = RESET;
		default : next_state = state;
	endcase
end

//data_type (OK)
always@(posedge clk)begin
	if(state == RESET) data_type <= 0;
	if( (state == READ_MAP_snddt_t_sram_last) && (counter == 31) )begin
		if(data_type) data_type <= 0;
		else data_type <= 1;
	end
end
// ===============================================================
//  					Input Register
// ===============================================================

// ( A ) (OK)
// frame_id_store
always@(posedge clk)begin
	if (in_valid)begin
		frame_id_store <= frame_id;
	end
end

// ( B ) (OK)
// net_id_array
always@(posedge clk)begin
	if (in_valid && (tra_cnt == 0))begin
		net_id_array[1]  <= net_id;
		net_id_array[2]  <= net_id_array[1];
		net_id_array[3]  <= net_id_array[2];
		net_id_array[4]  <= net_id_array[3];
		net_id_array[5]  <= net_id_array[4];
		net_id_array[6]  <= net_id_array[5];
		net_id_array[7]  <= net_id_array[6];
		net_id_array[8]  <= net_id_array[7];
		net_id_array[9]  <= net_id_array[8];
		net_id_array[10] <= net_id_array[9];
		net_id_array[11] <= net_id_array[10];
		net_id_array[12] <= net_id_array[11];
		net_id_array[13] <= net_id_array[12];
		net_id_array[14] <= net_id_array[13];
		net_id_array[15] <= net_id_array[14];
	end
end

// ( C ) (OK)
// S_loc_x_array , S_loc_y_array
always@(posedge clk)begin
	if (in_valid && (tra_cnt == 0))begin
		S_loc_x_array[1]  <= loc_x;
		S_loc_x_array[2]  <= S_loc_x_array[1];
		S_loc_x_array[3]  <= S_loc_x_array[2];
		S_loc_x_array[4]  <= S_loc_x_array[3];
		S_loc_x_array[5]  <= S_loc_x_array[4];
		S_loc_x_array[6]  <= S_loc_x_array[5];
		S_loc_x_array[7]  <= S_loc_x_array[6];
		S_loc_x_array[8]  <= S_loc_x_array[7];
		S_loc_x_array[9]  <= S_loc_x_array[8];
		S_loc_x_array[10] <= S_loc_x_array[9];
		S_loc_x_array[11] <= S_loc_x_array[10];
		S_loc_x_array[12] <= S_loc_x_array[11];
		S_loc_x_array[13] <= S_loc_x_array[12];
		S_loc_x_array[14] <= S_loc_x_array[13];
		S_loc_x_array[15] <= S_loc_x_array[14];

		S_loc_y_array[1]  <= loc_y;
		S_loc_y_array[2]  <= S_loc_y_array[1];
		S_loc_y_array[3]  <= S_loc_y_array[2];
		S_loc_y_array[4]  <= S_loc_y_array[3];
		S_loc_y_array[5]  <= S_loc_y_array[4];
		S_loc_y_array[6]  <= S_loc_y_array[5];
		S_loc_y_array[7]  <= S_loc_y_array[6];
		S_loc_y_array[8]  <= S_loc_y_array[7];
		S_loc_y_array[9]  <= S_loc_y_array[8];
		S_loc_y_array[10] <= S_loc_y_array[9];
		S_loc_y_array[11] <= S_loc_y_array[10];
		S_loc_y_array[12] <= S_loc_y_array[11];
		S_loc_y_array[13] <= S_loc_y_array[12];
		S_loc_y_array[14] <= S_loc_y_array[13];
		S_loc_y_array[15] <= S_loc_y_array[14];
	end
	if (in_valid && (tra_cnt == 1))begin
		T_loc_x_array[1]  <= loc_x;
		T_loc_x_array[2]  <= T_loc_x_array[1];
		T_loc_x_array[3]  <= T_loc_x_array[2];
		T_loc_x_array[4]  <= T_loc_x_array[3];
		T_loc_x_array[5]  <= T_loc_x_array[4];
		T_loc_x_array[6]  <= T_loc_x_array[5];
		T_loc_x_array[7]  <= T_loc_x_array[6];
		T_loc_x_array[8]  <= T_loc_x_array[7];
		T_loc_x_array[9]  <= T_loc_x_array[8];
		T_loc_x_array[10] <= T_loc_x_array[9];
		T_loc_x_array[11] <= T_loc_x_array[10];
		T_loc_x_array[12] <= T_loc_x_array[11];
		T_loc_x_array[13] <= T_loc_x_array[12];
		T_loc_x_array[14] <= T_loc_x_array[13];
		T_loc_x_array[15] <= T_loc_x_array[14];

		T_loc_y_array[1]  <= loc_y;
		T_loc_y_array[2]  <= T_loc_y_array[1];
		T_loc_y_array[3]  <= T_loc_y_array[2];
		T_loc_y_array[4]  <= T_loc_y_array[3];
		T_loc_y_array[5]  <= T_loc_y_array[4];
		T_loc_y_array[6]  <= T_loc_y_array[5];
		T_loc_y_array[7]  <= T_loc_y_array[6];
		T_loc_y_array[8]  <= T_loc_y_array[7];
		T_loc_y_array[9]  <= T_loc_y_array[8];
		T_loc_y_array[10] <= T_loc_y_array[9];
		T_loc_y_array[11] <= T_loc_y_array[10];
		T_loc_y_array[12] <= T_loc_y_array[11];
		T_loc_y_array[13] <= T_loc_y_array[12];
		T_loc_y_array[14] <= T_loc_y_array[13];
		T_loc_y_array[15] <= T_loc_y_array[14];
	end
end

// ( D )
// net_id_pointer
always@(negedge rst_n or posedge clk)begin
	if(!rst_n)begin
		net_id_pointer <= 0;
	end
	else begin
		if (state == OUTPUTMODE) net_id_pointer <= 0;
		if (in_valid && (tra_cnt == 0))    net_id_pointer <= net_id_pointer + 1;
		if (state == ROUTING_wait_store && (cost_cnt == 1)) net_id_pointer <= net_id_pointer - 1;
	end
end

// ===============================================================
//  					Data Register
// ===============================================================

always@(posedge clk)begin
	if( (state == WRITE_MAP_waitdt) && (counter > 0) && (counter < 33) )begin
		dram_read_in[3:0]     <= dram_read_in[7:4]     ;
		dram_read_in[7:4]     <= dram_read_in[11:8]    ;
		dram_read_in[11:8]    <= dram_read_in[15:12]   ;
		dram_read_in[15:12]   <= dram_read_in[19:16]   ;
		dram_read_in[19:16]   <= dram_read_in[23:20]   ;
		dram_read_in[23:20]   <= dram_read_in[27:24]   ;
		dram_read_in[27:24]   <= dram_read_in[31:28]   ;
		dram_read_in[31:28]   <= dram_read_in[35:32]   ;
		dram_read_in[35:32]   <= dram_read_in[39:36]   ;
		dram_read_in[39:36]   <= dram_read_in[43:40]   ;
		dram_read_in[43:40]   <= dram_read_in[47:44]   ;
		dram_read_in[47:44]   <= dram_read_in[51:48]   ;
		dram_read_in[51:48]   <= dram_read_in[55:52]   ;
		dram_read_in[55:52]   <= dram_read_in[59:56]   ;
		dram_read_in[59:56]   <= dram_read_in[63:60]   ;
		dram_read_in[63:60]   <= dram_read_in[67:64]   ;
		dram_read_in[67:64]   <= dram_read_in[71:68]   ;
		dram_read_in[71:68]   <= dram_read_in[75:72]   ;
		dram_read_in[75:72]   <= dram_read_in[79:76]   ;
		dram_read_in[79:76]   <= dram_read_in[83:80]   ;
		dram_read_in[83:80]   <= dram_read_in[87:84]   ;
		dram_read_in[87:84]   <= dram_read_in[91:88]   ;
		dram_read_in[91:88]   <= dram_read_in[95:92]   ;
		dram_read_in[95:92]   <= dram_read_in[99:96]   ;
		dram_read_in[99:96]   <= dram_read_in[103:100] ;
		dram_read_in[103:100] <= dram_read_in[107:104] ;
		dram_read_in[107:104] <= dram_read_in[111:108] ;
		dram_read_in[111:108] <= dram_read_in[115:112] ;
		dram_read_in[115:112] <= dram_read_in[119:116] ;
		dram_read_in[119:116] <= dram_read_in[123:120] ;
		dram_read_in[123:120] <= dram_read_in[127:124] ;
		dram_read_in[127:124] <= map_Q;
	end
end


// ( 1 )
//counter
always@(negedge rst_n or posedge clk)begin
	if(!rst_n)begin
		counter <= 0;
	end
	else begin
		//Reset counter
		if      (state == OUTPUTMODE) counter <= 0;
		// if we are sending data to sram, counter +1 for each clk from 0 to 31.
		if ( ( state == READ_MAP_snddt_t_sram_last ) || ( state == READ_MAP_snddt_t_sram ) ) begin
			if ( counter == 31 ) counter <= 0;
			else counter <= counter + 1;
		end
		if ( state == ROUTING_wait_store ) begin
			counter <= 0;
		end
		if ( state == WRITE_MAP_waitdt ) begin
			if ( counter == 33 ) counter <= 0;
			else counter <= counter + 1;
		end
	end
	
	//--------fini---------
	
end

// ( 2 )
//tra_cnt
always@(negedge rst_n or posedge clk)begin
	if(!rst_n) tra_cnt <= 0;
	else begin
		if (in_valid)begin
			if      (tra_cnt == 0) tra_cnt <= 1;
			else if (tra_cnt == 1) tra_cnt <= 0;
		end
		if (state == ROUTING_trav)begin
			if      (tra_cnt == 0) tra_cnt <= 1;
			else if (tra_cnt == 1) tra_cnt <= 0;
		end
		if (state == ROUTING_backtrav)begin
			if      (!start_tra && (tra_cnt == 0)) tra_cnt <= 1;
			else if (!start_tra && (tra_cnt == 1)) tra_cnt <= 0;
		end
		if (state == ROUTING_wait_store)begin
			tra_cnt <= 0;
		end
		if (state == OUTPUTMODE) tra_cnt <= 0;
	end
end

// ( 3 )
// addr
always@(negedge rst_n or posedge clk)begin
	if(!rst_n)begin
		addr <= 0;
	end
	else begin
		// Reset addr
		//if ( ( state == READ_MAP_setaddr ) && arready_m_inf) addr <= 0;

		// When send data into sram addr keep +1 for each time
		if ( (state == READ_MAP_snddt_t_sram) || (state == READ_MAP_snddt_t_sram_last) ) begin
			// When I finish sending map & weight, preparing to route, put first start point to addr.
			if( (state == READ_MAP_snddt_t_sram_last) && (counter == 31) && data_type) addr <= {cur_S_y,cur_S_x};
			// otherwise, addr keep +1
			else addr <= addr + 1;
		end

		// if the traversing end, set addr to target address.
		if( (state == ROUTING_trav) && touch_flag ) addr <= cur_T;

		// 
		if( (state == ROUTING_backtrav) )begin
			// When the address is on the target point
			if(start_tra)begin
				if     (tra_map1or2[up_addr_y][up_addr_x])       addr <= up_addr;
				else if(tra_map1or2[down_addr_y][down_addr_x])   addr <= down_addr;
				else if(tra_map1or2[left_addr_y][left_addr_x])   addr <= left_addr;
				else if(tra_map1or2[right_addr_y][right_addr_x]) addr <= right_addr;
			end
			else if(!back_tra_end_flag)begin
				if      (go_back_flag == 1) addr <= up_addr;
				else if (go_back_flag == 2) addr <= down_addr;
				else if (go_back_flag == 3) addr <= left_addr;
				else if (go_back_flag == 4) addr <= right_addr;
			end
		end
		//prepare to traverse
		if((state == ROUTING_wait_store) && (cost_cnt == 2)) addr <= cur_S;
		
		//
		if(state == WRITE_MAP_putaddr && awready_m_inf ) addr <= 0;
		if(state == WRITE_MAP_waitdt && (counter < 32) && (addr != 12'hfff) ) addr <= addr + 1;
		if(state == WRITE_MAP_putdt_last) addr <= 0;
		if(state == OUTPUTMODE) addr <= 0;
	end
end

// ( 4 )
// cur_step
always@(negedge rst_n or posedge clk)begin
	// Reset start_tra
	if(!rst_n) cur_step <= 0;
	else begin
		// When I was send data to sram
		if( ((state == READ_MAP_snddt_t_sram) || (state == READ_MAP_snddt_t_sram_last)) && !data_type )begin
			// if this block is not macro, put 3 in to tra_map
			if((dram_read_out[3:0]!=0) && addr_x!=0 && addr_y!=0 && addr_x!=63 && addr_y!=63 ) cur_step <= 1;
		end

		// When traversing forward
		if(state == ROUTING_trav)begin
			if     ( !touch_flag && tra_cnt == 1 && cur_step == 1) cur_step <= 2;
			else if( !touch_flag && tra_cnt == 1 && cur_step == 2) cur_step <= 1;
			else if( touch_flag && cur_step == 1 && tra_cnt == 0) cur_step <= 2;
			else if( touch_flag && cur_step == 2 && tra_cnt == 0) cur_step <= 1;
		end
		if( (state == ROUTING_backtrav) )begin
			if     ( !start_tra && !back_tra_end_flag && tra_cnt == 0 && cur_step == 1 ) cur_step <= 2;
			else if( !start_tra && !back_tra_end_flag && tra_cnt == 0 && cur_step == 2 ) cur_step <= 1;
		end
	end
end


// ( 5 )
// tra_map
always@(posedge clk)begin
	case(state)
		READ_MAP_snddt_t_sram, READ_MAP_snddt_t_sram_last:begin
			if(!data_type)begin
				if(dram_read_out[3:0]!=0) tra_map[addr_y][addr_x] <= 3;
				else tra_map[addr_y][addr_x] <= 0;
			end
		end
		ROUTING_trav, ROUTING_wait_store:begin
			if(start_tra && (state==ROUTING_trav))begin
				if((tra_map_net[addr_y+1][addr_x]==0)) tra_map[addr_y+1][addr_x] <= 1;
				if((tra_map_net[addr_y-1][addr_x]==0)) tra_map[addr_y-1][addr_x] <= 1;
				if((tra_map_net[addr_y][addr_x+1]==0)) tra_map[addr_y][addr_x+1] <= 1;
				if((tra_map_net[addr_y][addr_x-1]==0)) tra_map[addr_y][addr_x-1] <= 1;
			end
			for(i=0;i<64;i=i+1)begin
				for(j=0;j<64;j=j+1)begin
					// if the point is on the border of traversed place, traverse that.
					if(tra_map_net[i][j]==0 && !touch_flag && (state==ROUTING_trav))begin
						if(i==0 && j==0 && (tra_map1or2[i+1][j] || tra_map1or2[i][j+1]) ) tra_map[i][j] <= cur_step; //ul
						if(i==0 && j!=0 && j!=63 && (tra_map1or2[i][j-1] || tra_map1or2[i+1][j] || tra_map1or2[i][j+1]) ) tra_map[i][j] <= cur_step; //uu
						if(i==0 && j==63 && (tra_map1or2[i+1][j] || tra_map1or2[i][j-1]) ) tra_map[i][j] <= cur_step; //ur
						if(i!=0 && i!=63 && j==0 && (tra_map1or2[i-1][j] || tra_map1or2[i+1][j] || tra_map1or2[i][j+1])) tra_map[i][j] <= cur_step; //ll
						if(i==63 && j==0 && (tra_map1or2[i-1][j] || tra_map1or2[i][j+1]) ) tra_map[i][j] <= cur_step; //dl
						if(i==63 && j!=0 && j!=63 && (tra_map1or2[i-1][j] || tra_map1or2[i][j-1] || tra_map1or2[i][j+1])) tra_map[i][j] <= cur_step; //dd
						if(i==63 && j==63 && (tra_map1or2[i-1][j] || tra_map1or2[i][j-1]) ) tra_map[i][j] <= cur_step; //dr
						if(i!=0 && i!=63 && j==63 && (tra_map1or2[i-1][j] || tra_map1or2[i+1][j] || tra_map1or2[i][j-1])) tra_map[i][j] <= cur_step; //rr
						if(i!=0 && i!=63 && j!=0 && j!=63 && (tra_map1or2[i-1][j] || tra_map1or2[i+1][j] || tra_map1or2[i][j-1] || tra_map1or2[i][j+1])) tra_map[i][j] <= cur_step;
					end
					else if(state==ROUTING_wait_store)begin
						if(tra_map1or2[i][j]) tra_map[i][j] <= 0;
					end
				end
			end
		end
		ROUTING_backtrav:begin
			if(!start_tra || route_fini) tra_map[addr_y][addr_x] <= 3;
		end
	endcase

	//-------fini-------
end

// ( 6 )
// start_tra
always@(negedge rst_n or posedge clk)begin
	// Reset start_tra
	if(!rst_n) start_tra <= 0;
	else begin
		// When I was send data to sram
		if( ((state == READ_MAP_snddt_t_sram) || (state == READ_MAP_snddt_t_sram_last)) && !data_type )begin
			// if this block is not macro, put 3 in to tra_map
			if((dram_read_out[3:0]!=0) && addr_x!=0 && addr_y!=0 && addr_x!=63 && addr_y!=63 ) start_tra <= 1;
		end

		// When traversing forward
		if(state == ROUTING_trav)begin
			if(start_tra) start_tra <= 0;
			else if(touch_flag) start_tra <= 1;
		end
		if( (state == ROUTING_backtrav) )begin
			if(start_tra) start_tra <= 0;
			else if( back_tra_end_flag ) begin
				if(net_id_pointer != 1) start_tra <= 1;
			end
		end
	end
end




// ===============================================================
//  					Output Register
// ===============================================================

//cost (OK)
always@(negedge rst_n or posedge clk)begin
	if(!rst_n) cost <= 0;
	else if(state == RESET) cost <= 0;
	else if(cost_act_flag) cost <= cost + weight_store;
end

//busy
always@(negedge rst_n or posedge clk)begin
	if(!rst_n) busy <= 0;
	else if(!in_valid && (state == INPUTMODE)) busy <= 1;
	else if((state == WRITE_MAP_wait_ok) && (bresp_m_inf==0)) busy <= 0;
end

// ===============================================================
//  					SRAM 
// ===============================================================
//cost_cnt
always@(negedge rst_n or posedge clk)begin
	if(!rst_n) cost_cnt <= 0;
	else if ( (state == ROUTING_backtrav) && back_tra_end_flag) cost_cnt <= 1;
	else begin
		if ( cost_cnt == 1 ) cost_cnt <= 2;
		if ( cost_cnt == 2 ) cost_cnt <= 0;
	end
end

//weight_store
always@(negedge rst_n or posedge clk)begin
	if(!rst_n) weight_store <= 0;
	else if (state == RESET) weight_store <= 0;
	else if ( weight_store_act_flag ) weight_store <= weight_Q;
	else if ( !weight_store_act_flag ) weight_store <= 0;
end

//weight_store_act_flag
always@(negedge rst_n or posedge clk)begin
	if(!rst_n) weight_store_act_flag <= 0;
	else begin
		if ( read_weight_sram_flag && (weight_store_act_flag == 0) ) weight_store_act_flag <= 1;
		if ( !read_weight_sram_flag && (weight_store_act_flag == 1) ) weight_store_act_flag <= 0;
		if (state == OUTPUTMODE) weight_store_act_flag <= 0;
	end
end

//cost_act_flag
always@(negedge rst_n or posedge clk)begin
	if(!rst_n) cost_act_flag <= 0;
	else begin
		if ( weight_store_act_flag && (cost_act_flag == 0) ) cost_act_flag <= 1;
		if ( !weight_store_act_flag && (cost_act_flag == 1) ) cost_act_flag <= 0;
		if ( state == OUTPUTMODE ) cost_act_flag <= 0;
	end
	//if (state == RESET) cost_act_flag <= 0;
	
end


RAISH1 SRAM_MAP(
	.Q(map_Q),
	.CLK(clk),
	.CEN(map_CEN),
	.WEN(map_WEN),
	.A(addr),
	.D(map_D),
	.OEN(map_OEN)
);
RAISH1 SRAM_WEIGHT(
	.Q(weight_Q),
	.CLK(clk),
	.CEN(weight_CEN),
	.WEN(weight_WEN),
	.A(addr),
	.D(weight_D),
	.OEN(weight_OEN)
);

// ===============================================================
//  					AXI4 Interfaces
// ===============================================================

// You can desing your own module here
AXI4_READ INF_AXI4_READ(
	.clk(clk),.rst_n(rst_n),.curr_state(state),.index(index),.data_type(data_type) ,.frame_id_reg(frame_id_store) ,.dram_read_out(dram_read_out),
	.arid_m_inf(arid_m_inf),
	.arburst_m_inf(arburst_m_inf), .arsize_m_inf(arsize_m_inf), .arlen_m_inf(arlen_m_inf), 
	.arvalid_m_inf(arvalid_m_inf), .arready_m_inf(arready_m_inf), .araddr_m_inf(araddr_m_inf),
	.rid_m_inf(rid_m_inf),
	.rvalid_m_inf(rvalid_m_inf), .rready_m_inf(rready_m_inf), .rdata_m_inf(rdata_m_inf),
	.rlast_m_inf(rlast_m_inf), .rresp_m_inf(rresp_m_inf)
);
// You can desing your own module here
AXI4_WRITE INF_AXI4_WRITE(
	.clk(clk),.rst_n(rst_n),.curr_state(state),.index(index),.frame_id_reg(frame_id_store) , .dram_read_in(dram_read_in),
	.awid_m_inf(awid_m_inf),
	.awburst_m_inf(awburst_m_inf), .awsize_m_inf(awsize_m_inf), .awlen_m_inf(awlen_m_inf),
	.awvalid_m_inf(awvalid_m_inf), .awready_m_inf(awready_m_inf), .awaddr_m_inf(awaddr_m_inf),
   	.wvalid_m_inf(wvalid_m_inf), .wready_m_inf(wready_m_inf),
	.wdata_m_inf(wdata_m_inf), .wlast_m_inf(wlast_m_inf),
    .bid_m_inf(bid_m_inf),
   	.bvalid_m_inf(bvalid_m_inf), .bready_m_inf(bready_m_inf), .bresp_m_inf(bresp_m_inf)
);

endmodule


// ############################################################################
//  					AXI4 Interfaces Module
// ############################################################################
// =========================================
// Read Data from DRAM 
// =========================================
module AXI4_READ(
	clk,rst_n,curr_state, index, data_type, frame_id_reg, dram_read_out, 
	arid_m_inf,
	arburst_m_inf, arsize_m_inf, arlen_m_inf, 
	arvalid_m_inf, arready_m_inf, araddr_m_inf,
	rid_m_inf,
	rvalid_m_inf, rready_m_inf, rdata_m_inf,
	rlast_m_inf, rresp_m_inf
);
parameter ID_WIDTH=4, DATA_WIDTH=128, ADDR_WIDTH=32;    // DO NOT modify


// (0)	CHIP IO
input clk,rst_n,data_type;
input [3:0] curr_state;
input [12:0] index;
input [4:0] frame_id_reg;
output reg [DATA_WIDTH-1:0] dram_read_out; // ( a )

// ------------------------
// (1)	axi read address channel 
output wire [ID_WIDTH-1:0]      arid_m_inf;//fixed
output wire [1:0]            arburst_m_inf;//fixed
output wire [2:0]             arsize_m_inf;//fixed
output wire [7:0]              arlen_m_inf;//fixed
output reg                   arvalid_m_inf;// ( A )
input  wire                  arready_m_inf;//from slave
output wire [ADDR_WIDTH-1:0]  araddr_m_inf;// ( B )
// ------------------------
// (2)	axi read data channel 
input  wire [ID_WIDTH-1:0]       rid_m_inf;//don't care
input  wire                   rvalid_m_inf;//from slave
output reg                    rready_m_inf;// ( C )
input  wire [DATA_WIDTH-1:0]   rdata_m_inf;//from slave
input  wire                    rlast_m_inf;//from slave
input  wire [1:0]              rresp_m_inf;//from slave
// ------------------------

// Parameter
parameter RESET                       = 0 ;
parameter INPUTMODE                   = 1 ;
parameter READ_MAP_setaddr            = 2 ;
parameter READ_MAP_getdt_f_dram       = 3 ;
parameter READ_MAP_snddt_t_sram       = 4 ;
parameter READ_MAP_snddt_t_sram_last  = 5 ;
parameter ROUTING_trav                = 6 ;
parameter ROUTING_backtrav            = 7 ;
parameter ROUTING_wait_store          = 8 ;
parameter WRITE_MAP_putaddr           = 9 ;
parameter WRITE_MAP_waitdt            = 10;
parameter WRITE_MAP_putdt             = 11;
parameter WRITE_MAP_putdt_last        = 12;
parameter WRITE_MAP_wait_ok           = 13;
parameter OUTPUTMODE                  = 14;

reg [15:0] frame_addr;// ( 1 )
//reg [4:0]  counter;// ( 2 )

// ***********************
// axi_master read_request
// ***********************

// ( a )
always@(posedge clk)begin
	if((curr_state == READ_MAP_getdt_f_dram) && rvalid_m_inf) dram_read_out <= rdata_m_inf;
	if( (curr_state == READ_MAP_snddt_t_sram) || (curr_state == READ_MAP_snddt_t_sram_last) )begin
		dram_read_out[3:0]     <= dram_read_out[7:4]     ;
		dram_read_out[7:4]     <= dram_read_out[11:8]    ;
		dram_read_out[11:8]    <= dram_read_out[15:12]   ;
		dram_read_out[15:12]   <= dram_read_out[19:16]   ;
		dram_read_out[19:16]   <= dram_read_out[23:20]   ;
		dram_read_out[23:20]   <= dram_read_out[27:24]   ;
		dram_read_out[27:24]   <= dram_read_out[31:28]   ;
		dram_read_out[31:28]   <= dram_read_out[35:32]   ;
		dram_read_out[35:32]   <= dram_read_out[39:36]   ;
		dram_read_out[39:36]   <= dram_read_out[43:40]   ;
		dram_read_out[43:40]   <= dram_read_out[47:44]   ;
		dram_read_out[47:44]   <= dram_read_out[51:48]   ;
		dram_read_out[51:48]   <= dram_read_out[55:52]   ;
		dram_read_out[55:52]   <= dram_read_out[59:56]   ;
		dram_read_out[59:56]   <= dram_read_out[63:60]   ;
		dram_read_out[63:60]   <= dram_read_out[67:64]   ;
		dram_read_out[67:64]   <= dram_read_out[71:68]   ;
		dram_read_out[71:68]   <= dram_read_out[75:72]   ;
		dram_read_out[75:72]   <= dram_read_out[79:76]   ;
		dram_read_out[79:76]   <= dram_read_out[83:80]   ;
		dram_read_out[83:80]   <= dram_read_out[87:84]   ;
		dram_read_out[87:84]   <= dram_read_out[91:88]   ;
		dram_read_out[91:88]   <= dram_read_out[95:92]   ;
		dram_read_out[95:92]   <= dram_read_out[99:96]   ;
		dram_read_out[99:96]   <= dram_read_out[103:100] ;
		dram_read_out[103:100] <= dram_read_out[107:104] ;
		dram_read_out[107:104] <= dram_read_out[111:108] ;
		dram_read_out[111:108] <= dram_read_out[115:112] ;
		dram_read_out[115:112] <= dram_read_out[119:116] ;
		dram_read_out[119:116] <= dram_read_out[123:120] ;
		dram_read_out[123:120] <= dram_read_out[127:124] ;
		dram_read_out[127:124] <= 4'b0000;
	end
end

// ( A )
//arvalid_m_inf
always@(*)begin
	if(curr_state == READ_MAP_setaddr) arvalid_m_inf = 1;
	else arvalid_m_inf = 0;
end

// ( B )
//araddr_m_inf
assign araddr_m_inf = (!data_type) ? {16'h0001,{frame_addr + index}} : {16'h0002,{frame_addr + index}} ;
//index : from 0~2047 (each time + 8) (but we use burst so it always be 0)

// ( C )
//rready_m_inf
always@(*)begin
	if(curr_state == READ_MAP_getdt_f_dram) rready_m_inf = 1;
	else rready_m_inf = 0;
end




// ( 1 )
// frame_addr : the start point of each frame_id
always@(*)begin
	case(frame_id_reg)
		0:  frame_addr = 16'h0000;
		1:  frame_addr = 16'h0800;
		2:  frame_addr = 16'h1000;
		3:  frame_addr = 16'h1800;
		4:  frame_addr = 16'h2000;
		5:  frame_addr = 16'h2800;
		6:  frame_addr = 16'h3000;
		7:  frame_addr = 16'h3800;
		8:  frame_addr = 16'h4000;
		9:  frame_addr = 16'h4800;
		10: frame_addr = 16'h5000;
		11: frame_addr = 16'h5800;
		12: frame_addr = 16'h6000;
		13: frame_addr = 16'h6800;
		14: frame_addr = 16'h7000;
		15: frame_addr = 16'h7800;
		16: frame_addr = 16'h8000;
		17: frame_addr = 16'h8800;
		18: frame_addr = 16'h9000;
		19: frame_addr = 16'h9800;
		20: frame_addr = 16'ha000;
		21: frame_addr = 16'ha800;
		22: frame_addr = 16'hb000;
		23: frame_addr = 16'hb800;
		24: frame_addr = 16'hc000;
		25: frame_addr = 16'hc800;
		26: frame_addr = 16'hd000;
		27: frame_addr = 16'hd800;
		28: frame_addr = 16'he000;
		29: frame_addr = 16'he800;
		30: frame_addr = 16'hf000;
		31: frame_addr = 16'hf800;
		default:frame_addr = 16'h0000;
	endcase
end

// << Burst & ID >>
assign arid_m_inf = 4'd0; 			// fixed id to 0 
assign arburst_m_inf = 2'd1;		// fixed mode to INCR mode 
assign arsize_m_inf = 3'b100;		// fixed size to 2^4 = 16 Bytes 

assign arlen_m_inf = 8'd127;			// 32* (16 Bytes) = 4096 bits = 1 map
// ***********************
// axi_master read_catch
// ***********************


endmodule

// =========================================
// Write Data to DRAM 
// =========================================
module AXI4_WRITE(
	clk,rst_n,curr_state, index, frame_id_reg, dram_read_in, 
	awid_m_inf,
	awburst_m_inf,awsize_m_inf,awlen_m_inf,
	awvalid_m_inf, awready_m_inf, awaddr_m_inf,
   	wvalid_m_inf,wready_m_inf,
	wdata_m_inf, wlast_m_inf,
    bid_m_inf,
   	bvalid_m_inf, bready_m_inf, bresp_m_inf

);
parameter ID_WIDTH=4, DATA_WIDTH=128, ADDR_WIDTH=32;    // DO NOT modify

// (0)	CHIP IO
input clk,rst_n;
input [3:0] curr_state;
input [12:0] index;
input [4:0] frame_id_reg;
input [DATA_WIDTH-1:0] dram_read_in;
// ------------------------
// (1) 	axi write address channel 
output wire [ID_WIDTH-1:0]      awid_m_inf;//fixed
output wire [1:0]            awburst_m_inf;//fixed
output wire [2:0]             awsize_m_inf;//fixed
output wire [7:0]              awlen_m_inf;//fixed
output reg                   awvalid_m_inf;// ( A )
input  wire                  awready_m_inf;
output wire [ADDR_WIDTH-1:0]  awaddr_m_inf;// ( B )
// -------------------------

// (2)	axi write data channel 
output reg                    wvalid_m_inf;// ( C )
input  wire                   wready_m_inf;//from slave
output wire [DATA_WIDTH-1:0]   wdata_m_inf;// ( D )
output reg                     wlast_m_inf;// ( E )
// -------------------------

// (3)	axi write response channel 
input  wire  [ID_WIDTH-1:0]      bid_m_inf;
input  wire                   bvalid_m_inf;//from slave
output reg                    bready_m_inf;// ( F )
input  wire  [1:0]             bresp_m_inf;//from slave
// ------------------------

// Parameter
parameter RESET                       = 0 ;
parameter INPUTMODE                   = 1 ;
parameter READ_MAP_setaddr            = 2 ;
parameter READ_MAP_getdt_f_dram       = 3 ;
parameter READ_MAP_snddt_t_sram       = 4 ;
parameter READ_MAP_snddt_t_sram_last  = 5 ;
parameter ROUTING_trav                = 6 ;
parameter ROUTING_backtrav            = 7 ;
parameter ROUTING_wait_store          = 8 ;
parameter WRITE_MAP_putaddr           = 9 ;
parameter WRITE_MAP_waitdt            = 10;
parameter WRITE_MAP_putdt             = 11;
parameter WRITE_MAP_putdt_last        = 12;
parameter WRITE_MAP_wait_ok           = 13;
parameter OUTPUTMODE                  = 14;

reg [15:0] frame_addr;//( 1 )

reg [DATA_WIDTH-1:0] data_wire;
// *************************
// axi_master write request
// *************************

// ( A )
//awvalid_m_inf
always@(*)begin
	if(curr_state == WRITE_MAP_putaddr) awvalid_m_inf = 1;
	else awvalid_m_inf = 0;
end

// ( B )
//awaddr_m_inf
assign awaddr_m_inf = {16'h0001,{frame_addr + index}};

// ( C )
//wvalid_m_inf
always@(*)begin
	if ( (curr_state == WRITE_MAP_putdt) || (curr_state == WRITE_MAP_putdt_last) ) wvalid_m_inf = 1;
	else wvalid_m_inf = 0;
end

// ( D )
//wdata_m_inf
assign wdata_m_inf = data_wire;
always@(*)begin
	data_wire = dram_read_in;
end

// ( E )
//wlast_m_inf
always@(*)begin
	if(curr_state == WRITE_MAP_putdt_last) wlast_m_inf = 1;
	else wlast_m_inf = 0;
end


// ( F )
//bready_m_inf
always@(*)begin
	if(curr_state == WRITE_MAP_wait_ok) bready_m_inf = 1;
	else bready_m_inf = 0;
end


// ( 1 )
always@(*)begin
	case(frame_id_reg)
		0:  frame_addr = 16'h0000;
		1:  frame_addr = 16'h0800;
		2:  frame_addr = 16'h1000;
		3:  frame_addr = 16'h1800;
		4:  frame_addr = 16'h2000;
		5:  frame_addr = 16'h2800;
		6:  frame_addr = 16'h3000;
		7:  frame_addr = 16'h3800;
		8:  frame_addr = 16'h4000;
		9:  frame_addr = 16'h4800;
		10: frame_addr = 16'h5000;
		11: frame_addr = 16'h5800;
		12: frame_addr = 16'h6000;
		13: frame_addr = 16'h6800;
		14: frame_addr = 16'h7000;
		15: frame_addr = 16'h7800;
		16: frame_addr = 16'h8000;
		17: frame_addr = 16'h8800;
		18: frame_addr = 16'h9000;
		19: frame_addr = 16'h9800;
		20: frame_addr = 16'ha000;
		21: frame_addr = 16'ha800;
		22: frame_addr = 16'hb000;
		23: frame_addr = 16'hb800;
		24: frame_addr = 16'hc000;
		25: frame_addr = 16'hc800;
		26: frame_addr = 16'hd000;
		27: frame_addr = 16'hd800;
		28: frame_addr = 16'he000;
		29: frame_addr = 16'he800;
		30: frame_addr = 16'hf000;
		31: frame_addr = 16'hf800;
		default:frame_addr = 16'h0000;
	endcase
end



// << Burst & ID >>
assign awid_m_inf = 4'd0;
assign awburst_m_inf = 2'd1;
assign awsize_m_inf = 3'b100;

assign awlen_m_inf = 8'd127;
// *************************
// axi_master write send
// *************************

endmodule


