module SP(
	// Input signals
	clk,
	rst_n,
	cg_en,
	in_valid,
	in_data,
	in_mode,
	// Output signals
	out_valid,
	out_data
);
// PARAMETERs DECLARATION
parameter RESET = 0;
parameter INPUTMODE = 1;
parameter CUMULATE = 2;
parameter OUTPUTMODE = 3;


// INPUT AND OUTPUT DECLARATION  
input		clk;
input		rst_n;
input		in_valid;
input		cg_en;
input [8:0] in_data;
input [2:0] in_mode;

output  		  out_valid;
output signed [9:0] out_data;

wire [8:0] data_tran;


reg [1:0] state;
reg [1:0] next_state;
reg [2:0] mode_s;
reg [3:0] counter;
//----------------------
// FSM
//----------------------


always@( negedge rst_n or posedge clk )begin
	if( !rst_n ) state <= RESET;
	else state <= next_state;
end
always@(*)begin
	if(in_valid) next_state = INPUTMODE;
	else if((state == INPUTMODE) && !in_valid) next_state = CUMULATE;
	else if((state == CUMULATE) && (counter == 11)) next_state = OUTPUTMODE;
	else if((state == OUTPUTMODE) && (counter == 2)) next_state = RESET;
	else next_state = state;
end

//----------------------
// DATA reg
//----------------------

always@(posedge clk)begin
	if((state == RESET) && (in_valid)) mode_s <= in_mode;
end

always@(posedge clk)begin
	if((state == INPUTMODE) && (!in_valid)) counter <= 0;
	else if(state == CUMULATE) begin
		if(counter == 11) counter <= 0;
		else counter <= counter + 1;
	end
	else if(state == OUTPUTMODE) begin
		if(counter == 2) counter <= 0;
		else counter <= counter + 1;
	end
end

input_and_transform T1 (.clk(clk),.in_valid(in_valid),.mode0(mode_s[0]),.mode1(mode_s[1]),.in_data(in_data),.state(state),.out_data(data_tran));
cumulater C1 (.rst_n(rst_n),.clk(clk),.in_valid(in_valid),.in_data(data_tran),.mode2(mode_s[2]),.state(state),.counter(counter),.out_data(out_data),.out_valid(out_valid));


endmodule

module input_and_transform(clk,in_valid,mode0,mode1,in_data,state,out_data);
	// PARAMETERs DECLARATION
	parameter RESET = 0;
	parameter INPUTMODE = 1;
	parameter CUMULATE = 2;
	parameter OUTPUTMODE = 3;
	integer i;

	input clk,in_valid,mode0,mode1;
	input [8:0] in_data;
	input [1:0] state;
	output wire signed [8:0] out_data;
	reg out_valid;

	reg [8:0] data_1 [0:8];
	reg [8:0] data_t;

	reg signed [8:0] max,min;
	wire signed [9:0] sum;
	assign sum = {max[8],max} + {min[8],min};
	wire signed [8:0] half_sum;
	assign half_sum = (sum[9]==1'b1) ? (sum[9:1] + sum[0]) : sum[9:1] ;

	wire signed [8:0] data_cmp;
	
	reg [8:0] num;
	reg [8:0] dec_num;
	reg [8:0] data_t_to_1;

	assign out_data = (mode1) ? (data_1[0] - half_sum) : data_1[0];
	assign data_cmp = data_t_to_1;
	// num , dec_num;
	always@(*)begin
		if(data_t[8])begin
			case(data_t[3:0])
				4'd3 :   num = 9'd0;
				4'd4 :   num = 9'd511;
				4'd5 :   num = 9'd510;
				4'd6 :   num = 9'd509;
				4'd7 :   num = 9'd508;
				4'd8 :   num = 9'd507;
				4'd9 :   num = 9'd506;
				4'd10:   num = 9'd505;
				4'd11:   num = 9'd504;
				4'd12:   num = 9'd503;
				default: num = 9'd0;
			endcase
			case(data_t[7:4])
				4'd3 :   dec_num = 9'd0 ;
				4'd4 :   dec_num = 9'd502;
				4'd5 :   dec_num = 9'd492;
				4'd6 :   dec_num = 9'd482;
				4'd7 :   dec_num = 9'd472;
				4'd8 :   dec_num = 9'd462;
				4'd9 :   dec_num = 9'd452;
				4'd10:   dec_num = 9'd442;
				4'd11:   dec_num = 9'd432;
				4'd12:   dec_num = 9'd422;
				default: dec_num = 9'd0 ;
			endcase
		end
		else begin
			case(data_t[3:0])
				4'd3 :   num = 9'd0;
				4'd4 :   num = 9'd1;
				4'd5 :   num = 9'd2;
				4'd6 :   num = 9'd3;
				4'd7 :   num = 9'd4;
				4'd8 :   num = 9'd5;
				4'd9 :   num = 9'd6;
				4'd10:   num = 9'd7;
				4'd11:   num = 9'd8;
				4'd12:   num = 9'd9;
				default: num = 9'd0;
			endcase
			case(data_t[7:4])
				4'd3 :   dec_num = 9'd0 ;
				4'd4 :   dec_num = 9'd10;
				4'd5 :   dec_num = 9'd20;
				4'd6 :   dec_num = 9'd30;
				4'd7 :   dec_num = 9'd40;
				4'd8 :   dec_num = 9'd50;
				4'd9 :   dec_num = 9'd60;
				4'd10:   dec_num = 9'd70;
				4'd11:   dec_num = 9'd80;
				4'd12:   dec_num = 9'd90;
				default: dec_num = 9'd0 ;
			endcase
		end
	end
	//data_t_to_1
	always@(*)begin
		if(mode0) data_t_to_1 = num + dec_num;
		else  data_t_to_1 = data_t;
	end

	

	//data_1
	always@(posedge clk)begin
		if(state == INPUTMODE)begin
			data_1[8] <= data_t_to_1;
			for(i=1;i<9;i=i+1) data_1[i-1] <= data_1[i];
		end
		else if(state == CUMULATE)begin
			data_1[8] <= data_t_to_1;
			for(i=1;i<9;i=i+1) data_1[i-1] <= data_1[i];
		end
	end
	//data_t
	always@(posedge clk)begin
		if(in_valid) data_t <= in_data;
	end
	//max,min;
	always@(posedge clk)begin
		if(state == RESET)begin
			max <= 9'b100000000;
			min <= 9'b011111111;
		end
		else if(state == INPUTMODE)begin
			if(data_cmp > max) max <= data_cmp;
			if(data_cmp < min) min <= data_cmp;
		end
	end


endmodule

module cumulater(rst_n,clk,in_valid,in_data,mode2,state,counter,out_data,out_valid);
	// PARAMETERs DECLARATION
	parameter RESET = 0;
	parameter INPUTMODE = 1;
	parameter CUMULATE = 2;
	parameter OUTPUTMODE = 3;
	integer i;

	input rst_n,clk,in_valid;
	input [8:0] in_data;
	input mode2;
	input [1:0] state;
	input [3:0] counter;

	output reg signed [9:0] out_data;
	output reg out_valid;

	reg signed [8:0] data_t1;
	reg signed [8:0] data_t2;
	wire signed [10:0] cumu_num;
	assign cumu_num = {data_t1[8],data_t1,1'b0} + {data_t2[8],data_t2[8],data_t2};
	wire signed [10:0] cumu_result;
	assign cumu_result = cumu_num / 3;
	wire signed [10:0] A,B,C;
	wire signed [10:0] seq_sum;
	assign seq_sum = A + B + C;

	reg [9:0] data_3 [0:8];

	reg flag_1,flag_2;
	reg [3:0] max_seq_num;
	reg signed [10:0] max_seq_value;

	assign A = {data_3[8][9],data_3[8]};
	assign B = {data_3[7][9],data_3[7]};
	assign C = {data_3[6][9],data_3[6]};
	//out_data
	always@(negedge rst_n or posedge clk)begin
		if(!rst_n) out_data <= 0;
		else if (((state == CUMULATE) && counter == 11) || ((state == OUTPUTMODE) && counter != 2)) out_data <= data_3[max_seq_num];
		else if ((state == OUTPUTMODE) && counter == 2) out_data <= 0;
	end
	//out_valid
	always@(negedge rst_n or posedge clk)begin
		if(!rst_n) out_valid <= 0;
		else if ((state == CUMULATE) && counter == 11) out_valid <= 1;
		else if ((state == OUTPUTMODE) && counter == 2) out_valid <= 0;
	end

	// data_t1 , data_t2
	always@(posedge clk)begin
		if((state == CUMULATE) && !flag_1)begin
			if(mode2) data_t1 <= in_data;
			data_t2 <= in_data;
		end
		else if(state == CUMULATE)begin
			if(mode2) data_t1 <= cumu_result[9:0];
			data_t2 <= in_data;
		end
	end
	// data_3
	always@(posedge clk)begin
		if((state == CUMULATE) && flag_1 && (counter < 10))begin
			if(mode2)begin
				data_3[8] <= cumu_result[9:0];
			end
			else begin
				data_3[8] <= {data_t2[8],data_t2};
			end
			for(i=1;i<9;i=i+1) data_3[i-1] <= data_3[i] ;
		end
	end
	// flag_1
	always@(posedge clk)begin
		if((state == INPUTMODE) && !in_valid) flag_1 <= 0;
		else if((state == CUMULATE) && (flag_1 == 0)) flag_1 <= 1;
		else if((state == CUMULATE) && (counter == 11)) flag_1 <= 0;
	end

	// flag_2
	always@(posedge clk)begin
		if((state == INPUTMODE) && !in_valid) flag_2 <= 0;
		else if((state == CUMULATE) && (counter == 3)) flag_2 <= 1;
		else if((state == CUMULATE) && (counter == 11)) flag_2 <= 0;
	end
	// max_seq_num
	always@(posedge clk)begin
		if((state == CUMULATE) && flag_2)begin
			if((seq_sum > max_seq_value) && counter != 11)begin
				case(counter)
					4 :max_seq_num <= 0;
					5 :max_seq_num <= 1;
					6 :max_seq_num <= 2;
					7 :max_seq_num <= 3;
					8 :max_seq_num <= 4;
					9 :max_seq_num <= 5;
					10:max_seq_num <= 6;
				endcase
			end
			else if(counter == 11) max_seq_num <= max_seq_num + 1;
		end
		else if(state == OUTPUTMODE)begin
			max_seq_num <= max_seq_num + 1;
		end
	end
	// max_seq_value
	always@(posedge clk)begin
		if((state == INPUTMODE) && !in_valid) max_seq_value <= 11'b10000000000;
		else if((state == CUMULATE) && flag_2)begin
			if(seq_sum > max_seq_value)begin
				max_seq_value <= seq_sum;
			end
		end
	end

endmodule