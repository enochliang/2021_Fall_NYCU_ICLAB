module CLK_1_MODULE(// Input signals
			clk_1,
			clk_2,
			in_valid,
			rst_n,
			message,
			mode,
			CRC,
			// Output signals
			clk1_0_message,
			clk1_1_message,
			clk1_CRC,
			clk1_mode,
			clk1_control_signal,
			clk1_flag_0,
			clk1_flag_1,
			clk1_flag_2,
			clk1_flag_3,
			clk1_flag_4,
			clk1_flag_5,
			clk1_flag_6,
			clk1_flag_7,
			clk1_flag_8,
			clk1_flag_9
			);
//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION                         
//---------------------------------------------------------------------			
input clk_1; 
input clk_2;	
input rst_n;
input in_valid;
input[59:0]message;
input CRC;
input mode;

output [59:0] clk1_0_message;//use
output reg [59:0] clk1_1_message;
output clk1_CRC;//use
output clk1_mode;//use
output reg [9 :0] clk1_control_signal;
output clk1_flag_0;//use
output clk1_flag_1;
output clk1_flag_2;
output clk1_flag_3;
output clk1_flag_4;
output clk1_flag_5;
output clk1_flag_6;
output clk1_flag_7;
output clk1_flag_8;
output clk1_flag_9;

//---------------------------------------------------------------------
// PARAMETER DECLARATION
//---------------------------------------------------------------------
parameter IDLE = 0;
parameter INPUTMODE = 0;
//---------------------------------------------------------------------
// REG & WIRE DECLARATION
//---------------------------------------------------------------------
reg [1:0] state;
reg [1:0] next_state;

reg [59:0] message_s;
reg CRC_s;
reg mode_s;
reg flag_s;

//---------------------------------------------------------------------
// FSM
//---------------------------------------------------------------------
always@(negedge rst_n or posedge clk_1)begin
	if(!rst_n) state = IDLE;
	else state = next_state;
end
always@(*)begin
	if(!rst_n) next_state = IDLE;
	else if(in_valid) next_state = INPUTMODE;
	else if(state == INPUTMODE) next_state = IDLE;
	else next_state = state;
end

//---------------------------------------------------------------------
// OUTPUT reg
//---------------------------------------------------------------------
always@(negedge rst_n or posedge clk_1)begin
	if(!rst_n) message_s <= 0;
	else if(in_valid) message_s <= message;
	else if(state == INPUTMODE) message_s <= 0;
end
always@(negedge rst_n or posedge clk_1)begin
	if(!rst_n) CRC_s <= 0;
	else if(in_valid) CRC_s <= CRC;
	else if(state == INPUTMODE) CRC_s <= 0;
end
always@(negedge rst_n or posedge clk_1)begin
	if(!rst_n) mode_s <= 0;
	else if(in_valid) mode_s <= mode;
	else if(state == INPUTMODE) mode_s <= 0;
end
always@(negedge rst_n or posedge clk_1)begin
	if(!rst_n) flag_s <= 0;
	else if(in_valid) flag_s <= 1;
	else if(state == INPUTMODE) flag_s <= 0;
end

//---------------------------------------------------------------------
// SUBMODULEs
//---------------------------------------------------------------------
genvar i;
generate
	for(i=0;i<60;i=i+1)begin
		syn_XOR s1 (.IN(message_s[i]),.OUT(clk1_0_message[i]),.TX_CLK(clk_1),.RX_CLK(clk_2),.RST_N(rst_n));
	end
endgenerate
//todo
syn_XOR crc1 (.IN(CRC_s),.OUT(clk1_CRC),.TX_CLK(clk_1),.RX_CLK(clk_2),.RST_N(rst_n));
syn_XOR mode1 (.IN(mode_s),.OUT(clk1_mode),.TX_CLK(clk_1),.RX_CLK(clk_2),.RST_N(rst_n));
syn_XOR flag1 (.IN(flag_s),.OUT(clk1_flag_0),.TX_CLK(clk_1),.RX_CLK(clk_2),.RST_N(rst_n));
	
endmodule







module CLK_2_MODULE(// Input signals
			clk_2,
			clk_3,
			rst_n,
			clk1_0_message,
			clk1_1_message,
			clk1_CRC,
			clk1_mode,
			clk1_control_signal,
			clk1_flag_0,
			clk1_flag_1,
			clk1_flag_2,
			clk1_flag_3,
			clk1_flag_4,
			clk1_flag_5,
			clk1_flag_6,
			clk1_flag_7,
			clk1_flag_8,
			clk1_flag_9,
			
			// Output signals
			clk2_0_out,
			clk2_1_out,
			clk2_CRC,
			clk2_mode,
			clk2_control_signal,
			clk2_flag_0,
			clk2_flag_1,
			clk2_flag_2,
			clk2_flag_3,
			clk2_flag_4,
			clk2_flag_5,
			clk2_flag_6,
			clk2_flag_7,
			clk2_flag_8,
			clk2_flag_9
		  
			);
//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION                         
//---------------------------------------------------------------------			
input clk_2;	
input clk_3;	
input rst_n;

input [59:0] clk1_0_message;
input [59:0] clk1_1_message;
input clk1_CRC;
input clk1_mode;
input [9  :0] clk1_control_signal;
input clk1_flag_0;
input clk1_flag_1;
input clk1_flag_2;
input clk1_flag_3;
input clk1_flag_4;
input clk1_flag_5;
input clk1_flag_6;
input clk1_flag_7;
input clk1_flag_8;
input clk1_flag_9;


output [59:0] clk2_0_out;//use
output reg [59:0] clk2_1_out;
output clk2_CRC;//use
output clk2_mode;//use
output reg [9  :0] clk2_control_signal;
output clk2_flag_0;//use
output clk2_flag_1;
output clk2_flag_2;
output clk2_flag_3;
output clk2_flag_4;
output clk2_flag_5;
output clk2_flag_6;
output clk2_flag_7;
output clk2_flag_8;
output clk2_flag_9;


//---------------------------------------------------------------------
// PARAMETER DECLARATION
//---------------------------------------------------------------------
parameter IDLE = 0;
parameter COMPUTE = 1;
parameter OUTPUTMODE = 2;

integer j;
//---------------------------------------------------------------------
// REG & WIRE DECLARATION
//---------------------------------------------------------------------
//FSM
reg [2:0] state,next_state;

//DATA
reg [1:0]cnt;

reg [59:0]DN_c;
reg [8:0]DR_c;

reg [59:0] message_s;
reg CRC_s;
reg mode_s;

reg [59:0] message_o;
reg CRC_o;
reg mode_o;
reg flag_o;

wire [8:0] DN_DRxor;
wire [59:0] msg_or_in;
reg [59:0] msg;

//---------------------------------------------------------------------
// FSM
//---------------------------------------------------------------------
always@(negedge rst_n or posedge clk_2)begin
	if(!rst_n) state <= IDLE;
	else state <= next_state;
end
always@(*)begin
	if(!rst_n) next_state = IDLE;
	else if(cnt == 2) next_state = COMPUTE;
	else if(state == COMPUTE) begin
		if( !mode_s && !CRC_s && (DN_c[51:0] == 52'hfffffffffffff)) next_state = OUTPUTMODE;
		else if( !mode_s && CRC_s && (DN_c[54:0] == 55'h7fffffffffffff)) next_state = OUTPUTMODE;
		else if( mode_s && !CRC_s && (DN_c[51:0] == 0)) next_state = OUTPUTMODE;
		else if( mode_s && CRC_s && (DN_c[54:0] == 0)) next_state = OUTPUTMODE;
		else next_state = state;
	end
	else if(state == OUTPUTMODE) next_state = IDLE;
	else next_state = state;
end
//---------------------------------------------------------------------
// DATA reg
//---------------------------------------------------------------------
//cnt
always@(negedge rst_n or posedge clk_2)begin
	if(!rst_n) cnt <= 0;
	else if(clk1_flag_0) cnt <= 1;
	else if(cnt == 1) cnt <= 2;
	else if(cnt == 2) cnt <= 0;
end

assign DN_DRxor = DN_c[59:51] ^ DR_c;
assign msg_or_in = msg | clk1_0_message;

always@(negedge rst_n or posedge clk_2)begin
	if(!rst_n) msg <= 0;
	else if((state == IDLE) && (cnt != 2)) msg <= msg_or_in;
	else if(cnt == 2) msg <= 0;
end
//DN_c
always@(posedge clk_2)begin
	if(cnt == 2) begin
		if( !mode_s && !CRC_s ) DN_c <= {msg_or_in[51:0],8'd0};
		else if( !mode_s && CRC_s ) DN_c <= {msg_or_in[54:0],5'd0};
		else if( mode_s ) DN_c <= msg_or_in;
	end
	else if(state == COMPUTE) begin
		if(!mode_s)begin
			if (!DN_DRxor[8]) begin
				DN_c[59:52] <= DN_DRxor[7:0];
				DN_c[51:0] <= {DN_c[50:0],1'b1};
			end
			else begin
				DN_c[59:0] <= {DN_c[58:0],1'b1};
			end
		end
		if(mode_s)begin
			if (!DN_DRxor[8]) begin
				DN_c[59:52] <= DN_DRxor[7:0];
				DN_c[51:0] <= {DN_c[50:0],1'b0};
			end
			else begin
				DN_c[59:0] <= {DN_c[58:0],1'b0};
			end
		end
	end
	else if(state == OUTPUTMODE) begin
		DN_c <= 0;
	end
end

//DR_c
always@(posedge clk_2)begin
	if(cnt == 2) begin
		if( !CRC_s ) DR_c <= 9'b100110001;
		else if( CRC_s ) DR_c <= 9'b101011000;
	end
end
/* always@(posedge clk_2)begin
	$write("state:%d ,",state);
	$write("clk1_flag_0:%1d ,",clk1_flag_0);
	$write("DN:%15h ,",DN_c);
	$write("DR:%15h ,",DR_c);
	$write("msg:%15h ,",message_s);
	$display();
end */

//message_s
always@(posedge clk_2)begin
	if(cnt == 2) begin
		if( !mode_s && !CRC_s ) message_s <= {msg_or_in[51:0],8'd0};
		else if( !mode_s && CRC_s ) message_s <= {msg_or_in[54:0],5'd0};
		else if( mode_s ) message_s <= msg_or_in;
	end
	else if(state == OUTPUTMODE) begin
		message_s <= 0;
	end
end

always@(negedge rst_n or posedge clk_2)begin
	if(!rst_n)begin
		CRC_s <= 0;
		mode_s <= 0;
	end
	else if(state == IDLE)begin
		CRC_s <= clk1_CRC | CRC_s;
		mode_s <= clk1_mode | mode_s;
	end
	else if(state == OUTPUTMODE)begin
		CRC_s <= 0;
		mode_s <= 0;
	end
end

//message_o
always@(negedge rst_n or posedge clk_2)begin
	if(!rst_n) message_o <= 0;
	else if(state == COMPUTE)begin
		if( (mode_s==0) && (CRC_s==0) && (DN_c[51:0] == 52'hfffffffffffff)) begin
			message_o <= {message_s[59:8],DN_c[59:52]};
		end
		else if( (mode_s==0) && (CRC_s==1) && (DN_c[54:0] == 55'h7fffffffffffff)) begin
			message_o <= {message_s[59:5],DN_c[59:55]};
		end
		else if( (mode_s==1) && (CRC_s==0) && (DN_c[51:0] == 0))begin
			if(DN_c[59:52] == 0) message_o <= 0;
			else for(j=0;j<60;j=j+1) message_o[j] <= 1;
		end
		else if( (mode_s==1) && (CRC_s==1) && (DN_c[54:0] == 0))begin
			if(DN_c[59:55] == 0) message_o <= 0;
			else for(j=0;j<60;j=j+1) message_o[j] <= 1;
		end
	end
	else if(state == OUTPUTMODE) message_o <= 0;
end
//CRC_o,mode_o,flag_o
always@(negedge rst_n or posedge clk_2)begin
	if(!rst_n) begin
		CRC_o <= 0;
		mode_o <= 0;
		flag_o <= 0;
	end
	else if(state == COMPUTE)begin
		if( (mode_s==0) && (CRC_s==0) && (DN_c[51:0] == 52'hfffffffffffff)) begin
			CRC_o <= CRC_s;
			mode_o <= mode_s;
			flag_o <= 1;
		end
		else if( (mode_s==0) && (CRC_s==1) && (DN_c[54:0] == 55'h7fffffffffffff)) begin
			CRC_o <= CRC_s;
			mode_o <= mode_s;
			flag_o <= 1;
		end
		else if( (mode_s==1) && (CRC_s==0) && (DN_c[51:0] == 0))begin
			CRC_o <= CRC_s;
			mode_o <= mode_s;
			flag_o <= 1;
		end
		else if( (mode_s==1) && (CRC_s==1) && (DN_c[54:0] == 0))begin
			CRC_o <= CRC_s;
			mode_o <= mode_s;
			flag_o <= 1;
		end
	end
	else if(state == OUTPUTMODE) begin
		CRC_o <= 0;
		mode_o <= 0;
		flag_o <= 0;
	end
end


//---------------------------------------------------------------------
// SUBMODULEs
//---------------------------------------------------------------------
genvar i;
generate
	for(i=0;i<60;i=i+1)begin
		syn_XOR s1 (.IN(message_o[i]),.OUT(clk2_0_out[i]),.TX_CLK(clk_2),.RX_CLK(clk_3),.RST_N(rst_n));
	end
endgenerate
//todo
syn_XOR crc1 (.IN(CRC_o),.OUT(clk2_CRC),.TX_CLK(clk_2),.RX_CLK(clk_3),.RST_N(rst_n));
syn_XOR mode1 (.IN(mode_o),.OUT(clk2_mode),.TX_CLK(clk_2),.RX_CLK(clk_3),.RST_N(rst_n));
syn_XOR flag1 (.IN(flag_o),.OUT(clk2_flag_0),.TX_CLK(clk_2),.RX_CLK(clk_3),.RST_N(rst_n));

endmodule



module CLK_3_MODULE(// Input signals
			clk_3,
			rst_n,
			clk2_0_out,
			clk2_1_out,
			clk2_CRC,
			clk2_mode,
			clk2_control_signal,
			clk2_flag_0,
			clk2_flag_1,
			clk2_flag_2,
			clk2_flag_3,
			clk2_flag_4,
			clk2_flag_5,
			clk2_flag_6,
			clk2_flag_7,
			clk2_flag_8,
			clk2_flag_9,
			
			// Output signals
			out_valid,
			out
		  
			);
//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION                         
//---------------------------------------------------------------------			
input clk_3;	
input rst_n;

input [59:0] clk2_0_out;
input [59:0] clk2_1_out;
input clk2_CRC;
input clk2_mode;
input [9  :0] clk2_control_signal;
input clk2_flag_0;
input clk2_flag_1;
input clk2_flag_2;
input clk2_flag_3;
input clk2_flag_4;
input clk2_flag_5;
input clk2_flag_6;
input clk2_flag_7;
input clk2_flag_8;
input clk2_flag_9;

output reg out_valid;
output reg [59:0]out; 		

//---------------------------------------------------------------------
// PARAMETER DECLARATION
//---------------------------------------------------------------------
parameter IDLE = 0;
parameter OUTPUTMODE = 1;


//---------------------------------------------------------------------
// REG & WIRE DECLARATION
//---------------------------------------------------------------------
reg state;
reg next_state;

reg [1:0]cnt;

reg [59:0]msg;
wire [59:0] msg_or_in;
//---------------------------------------------------------------------
// FSM
//---------------------------------------------------------------------
always@(negedge rst_n or posedge clk_3)begin
	if(!rst_n) state = IDLE;
	else state = next_state;
end
always@(*)begin
	if(cnt == 2) next_state = OUTPUTMODE;
	else if(state == OUTPUTMODE) next_state = IDLE;
	else next_state = state;
end

//---------------------------------------------------------------------
// Reg & Wire
//---------------------------------------------------------------------
assign msg_or_in = msg | clk2_0_out;
always@(negedge rst_n or posedge clk_3)begin
	if(!rst_n)begin
		msg <= 0;
	end
	else if(state == IDLE)begin
		msg <= msg_or_in;
	end
	else if(state == OUTPUTMODE)begin
		msg <= 0;
	end
end

always@(negedge rst_n or posedge clk_3)begin
	if(!rst_n)begin
		cnt <= 0;
	end
	else if(clk2_flag_0)begin
		cnt <= 1;
	end
	else if(cnt == 1)begin
		cnt <= 2;
	end
	else if(cnt == 2)begin
		cnt <= 0;
	end
end
//---------------------------------------------------------------------
// Output
//---------------------------------------------------------------------


always@(negedge rst_n or posedge clk_3)begin
	if(!rst_n)begin
		out_valid <= 0;
		out <= 0;
	end
	else if(cnt == 2)begin
		out_valid <= 1;
		out <= msg;
	end
	else if(state == OUTPUTMODE)begin
		out_valid <= 0;
		out <= 0;
	end
end

/* always@(negedge rst_n or posedge clk_3)begin
	$write("in:%15h ,",clk2_0_out);
	$write("state:%d ,",state);
	$write("cnt:%d ,",cnt);
	$display();
end */

endmodule


