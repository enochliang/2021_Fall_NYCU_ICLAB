module KT(
    clk,
    rst_n,
    in_valid,
    in_x,
    in_y,
    move_num,
    priority_num,
    out_valid,
    out_x,
    out_y,
    move_out
);

//input output declare
input clk,rst_n;
input in_valid;
input [2:0] in_x,in_y;
input [4:0] move_num;
input [2:0] priority_num;

output reg out_valid;
output reg [2:0] out_x,out_y;
output reg [4:0] move_out;


//Definition of states
parameter [1:0]RESET=2'd0;
parameter [1:0]INPUTMODE=2'd1;
parameter [1:0]COMPUTING=2'd2;
parameter [1:0]OUTPUTMODE=2'd3;
//To store states
reg [1:0]state,n_state;


//REGISTERS
reg [4:0]step_num;

reg [4:0]counter;
reg [4:0]counter_line;

reg [2:0]step_history[2:25];
reg [2:0]step_history_line[2:25];
reg step_history_round[2:25];

//reg [2:0]startx,starty;

reg input_start_flag;

//reg [2:0]pre_x,pre_y;

reg [2:0]prior_main;

reg [2:0]position_x[1:25];
reg [2:0]position_y[1:25];

reg [1:0]compstate;
//----------

//---Net---
//Used in INPUTMODE
reg [5:0]delta;
reg [2:0]cur_step;

wire [2:0]xline[1:25];
wire [2:0]yline[1:25];

wire [2:0] pline [2:25];
wire over_signal[2:25];
wor compareline[2:25];

integer i;

genvar pp;
generate
	for (pp=1;pp<26;pp=pp+1)begin
		assign xline[pp]=position_x[pp];
		assign yline[pp]=position_y[pp];
	end
endgenerate

genvar ii,jj;
generate
	for(ii=2;ii<26;ii=ii+1)begin
		for(jj=1;jj<ii;jj=jj+1)begin
			comparing_two_position compare(.in_x1(xline[jj]),.in_y1(yline[jj]),.in_x2(xline[ii]),.in_y2(yline[ii]),.same(compareline[ii]));
		end
	end
endgenerate


always@(*) begin
	delta[5:3] = position_x[counter-1]-position_x[counter-2];
	delta[2:0] = position_y[counter-1]-position_y[counter-2];
	case(delta)
		//0(-1,2)
		6'b111010:begin cur_step = 3'b000; end
		//1(1,2)
		6'b001010:begin cur_step = 3'b001; end
		//2(2,1)
		6'b010001:begin cur_step = 3'b010; end
		//3(2,-1)
		6'b010111:begin cur_step = 3'b011; end
		//4(1,-2)
		6'b001110:begin cur_step = 3'b100; end
		//5(-1,-2)
		6'b111110:begin cur_step = 3'b101; end
		//6(-2,-1)
		6'b110111:begin cur_step = 3'b110; end
		//7(-2,1)
		6'b110001:begin cur_step = 3'b111; end
		//default
		default:begin cur_step = 3'b000;end
	endcase
end
//***************************************************//
//Finite State Machine example
//***************************************************//
//FSM current state assignment
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		state <= RESET;
	end
	else begin
		state <= n_state;
	end
end

//FSM next state assignment
always@(*) begin
	if(!rst_n)begin
		n_state = RESET;
	end
	else if(in_valid)begin
		n_state = INPUTMODE;
	end
	else if(step_num==5'd26)begin
		n_state = OUTPUTMODE;
	end
	else begin
		case(state)
		
			RESET: begin
				if(in_valid) begin
					n_state = INPUTMODE;
				end
				else begin
					n_state = RESET;
				end
			end
			
			INPUTMODE: begin
				if(in_valid) begin
					n_state = INPUTMODE;
				end
				else begin
					n_state = COMPUTING;
				end
			end
			
			COMPUTING: begin
				n_state = COMPUTING;
			end
			
			OUTPUTMODE: begin
				if(move_out==5'd25) begin
					n_state = RESET;
				end
				
				else begin
					n_state = OUTPUTMODE;
				end
			end
			
			default: begin
				n_state = state;
			end

		endcase
	end
end 

//Output assignment
always@(posedge clk or negedge rst_n) begin
	if(!rst_n)begin
		out_valid<=1'b0;
		out_x<=3'b000;
		out_y<=3'b000;
		move_out<=5'b00000;
	end
	
	else if(state==RESET)begin
		out_valid<=1'b0;
		out_x<=3'b000;
		out_y<=3'b000;
		move_out<=5'b00000;
	end
	else if(state==OUTPUTMODE)begin
		if(move_out==5'd25)begin
			out_valid<=1'b0;
			move_out<=5'b00000;
			out_x<=5'b00000;
			out_y<=5'b00000;
		end
		else begin
			out_valid<=1'b1;
			move_out<=counter;
			out_x<=xline[counter];
			out_y<=yline[counter];
		end
	end
	else begin
		if((state==COMPUTING) && (step_num==5'd26))begin
			out_valid<=1'b1;
			move_out<=5'b00001;
			out_x<=xline[1];
			out_y<=yline[1];
		end
		else begin
			out_valid<=out_valid;
			move_out<=move_out;
			out_x<=out_x;
			out_y<=out_y;
		end
		
	end
	
end

//REGISTERS assignment
always@(posedge clk or negedge rst_n) begin
	
	if(!rst_n) begin
		step_num<=5'b00000;//1
		counter<=5'b00001;//2
		for(i=2;i<26;i=i+1)begin
			{step_history_round[i],step_history[i][2:0]}<=4'b0000;//3
		end
		
		
		input_start_flag<=1'b0;//6
		
		
		
		prior_main<=3'b000;//9
		
		for(i=1;i<26;i=i+1)begin
			position_x[i]<=0;//10
			position_y[i]<=0;//10
		end
		compstate<=2'b0;
	end
	//INPUTMODE:start~body!!!
	else if(in_valid)begin
		//The first time receiving data
		if(!input_start_flag) begin
			step_num <= move_num;//1
			
			for(i=2;i<26;i=i+1)begin
				step_history[i][2:0]<=priority_num[2:0];
				step_history_round[i]<=1'b0;//3
			end
			
			
			//Turn on the flag after the first input
			input_start_flag <= 1'b1;//6
			prior_main <= priority_num;//9
		end
		//Start storing after the first input
		else begin
			step_num <= step_num;//1
			if(counter>2)begin
				step_history[counter-1][2:0] <= cur_step[2:0];
				if(cur_step[2:0] < prior_main) step_history_round[counter-1] <= 1;
				else step_history_round[counter-1] <= 0;
			end
			
		end
		
		counter <= counter+1;//2
		
		
		position_x[counter]<=in_x;//10
		position_y[counter]<=in_y;//10
		compstate<=2'b0;
	end
	else begin
		case(state)
		
			RESET: begin
				step_num<=5'b00000;//1
				counter<=5'b00001;//2
				for(i=2;i<26;i=i+1)begin
					{step_history_round[i],step_history[i][2:0]}<=4'b0000;//3
				end
				
				input_start_flag<=1'b0;//6
				
				prior_main<=3'b000;//9
				
				for(i=1;i<26;i=i+1)begin
					position_x[i]<=0;//10
					position_y[i]<=0;//10
				end
				compstate<=2'b0;
			end
			//INPUTMODE:end!!!
			INPUTMODE: begin
				step_num<=step_num;//1
				counter<=5'b00001;//2
				{step_history_round[counter-1],step_history[counter-1][2:0]}<={step_history_round[counter-1],cur_step[2:0]};//3
				
				input_start_flag<=1'b0;//6
				
				compstate<=2'b0;
			end
			
			COMPUTING: begin
				if(compstate==2'd0)begin
					//COMPUTING:end
					if(step_num==5'd26)begin
						step_num<=5'b00000;//1
						counter<=counter+1;//2
						
						input_start_flag<=1'b0;//6
						
						prior_main<=3'b000;//9
						
						compstate<=2'b0;
					end
					//COMPUTING:body .if step round
					else if((step_num!=1) && ((step_history[step_num][2:0]==prior_main) && (step_history_round[step_num]))) begin
						
						counter<=5'b00001;//2
						
						input_start_flag<=1'b0;//6
						
						{position_x[step_num-1],position_y[step_num-1]}<=walk(step_history[step_num-1]+1,position_x[step_num-2],position_y[step_num-2]);//10
						
						compstate<=2'd1;
					end
					//COMPUTING:body .if the step is over the range
					else if((position_x[step_num]>4) || (position_y[step_num]>4))begin
						
						counter<=5'b00001;//2
						
						input_start_flag<=1'b0;//6
						
						{position_x[step_num],position_y[step_num]}<=walk(step_history[step_num]+1,position_x[step_num-1],position_y[step_num-1]);//10
						
						compstate<=2'd2;
					end
					//COMPUTING:body .if the block has been stepped
					else if((step_num!=1) && compareline[step_num])begin
						
						counter<=5'b00001;//2
						
						input_start_flag<=1'b0;//6
						
						{position_x[step_num],position_y[step_num]}<=walk(step_history[step_num]+1,position_x[step_num-1],position_y[step_num-1]); //10
						
						compstate<=2'd3;
					end
					//COMPUTING:body .next step
					else begin
						step_num<=step_num+1;//1
						
						counter<=5'b00001;//2
						
						input_start_flag<=1'b0;//6
						
						{position_x[step_num+1],position_y[step_num+1]}<=walk(step_history[step_num+1],position_x[step_num],position_y[step_num]); //10
						
						compstate<=2'd0;
						//$display("next");
					end
				end
				else if(compstate==2'd1)begin
					step_num<=step_num-1;//1
						
					{step_history_round[step_num-1],step_history[step_num-1][2:0]} <= {step_history_round[step_num-1],step_history[step_num-1][2:0]}+4'b0001;//3
					{step_history_round[step_num],step_history[step_num][2:0]} <= {1'b0,step_history[step_num][2:0]};//3
					
					input_start_flag<=1'b0;//6
					
					compstate<=2'd0;
				end
				else if(compstate==2'd2)begin
						
					{step_history_round[step_num],step_history[step_num][2:0]} <= {step_history_round[step_num],step_history[step_num][2:0]} + 1;//3

					input_start_flag<=1'b0;//6
					
					compstate<=2'd0;
				end
				else if(compstate==2'd3)begin
						
					{step_history_round[step_num],step_history[step_num][2:0]} <= {step_history_round[step_num],step_history[step_num][2:0]} + 1;//3

					input_start_flag<=1'b0;//6
					
					compstate<=2'd0;
				end
			end
			
			OUTPUTMODE: begin
				step_num<=5'b00000;//1
				
				if(move_out==5'd25) counter<=5'd1;//2
				else counter<=counter+1;//2
				
				input_start_flag<=1'b0;//6
				
				prior_main<=3'b000;//9
				
				compstate<=2'd0;
			end
			
		endcase
	end
end

function [5:0]walk;
	input [2:0]step;
	input [2:0]x,y;
	begin
		case(step)
			3'b000:walk={x-3'd1,y+3'd2};
			3'b001:walk={x+3'd1,y+3'd2};
			3'b010:walk={x+3'd2,y+3'd1};
			3'b011:walk={x+3'd2,y-3'd1};
			3'b100:walk={x+3'd1,y-3'd2};
			3'b101:walk={x-3'd1,y-3'd2};
			3'b110:walk={x-3'd2,y-3'd1};
			3'b111:walk={x-3'd2,y+3'd1};
		endcase
	end
endfunction

endmodule

module comparing_two_position(in_x1,in_y1,in_x2,in_y2,same);
	input [2:0]in_x1,in_y1,in_x2,in_y2;
	output reg same;
	
	always@(*)begin
		if((in_x1==in_x2) && (in_y1==in_y2))begin
			same=1'b1;
		end
		else begin
			same=1'b0;
		end
	end
endmodule