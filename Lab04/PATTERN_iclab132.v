`ifdef RTL
	`timescale 1ns/10ps
	`include "NN.v"  
	`define CYCLE_TIME 20.0
`endif
`ifdef GATE
	`timescale 1ns/10ps
	`include "NN_SYN.v"
	`define CYCLE_TIME 20.0
`endif


module PATTERN(
	// Output signals
	clk,
	rst_n,
	in_valid_d,
	in_valid_t,
	in_valid_w1,
	in_valid_w2,
	data_point,
	target,
	weight1,
	weight2,
	// Input signals
	out_valid,
	out
);
//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch = 2;

//================================================================
//   INPUT AND OUTPUT DECLARATION                         
//================================================================
output reg clk, rst_n, in_valid_d, in_valid_t, in_valid_w1, in_valid_w2;
output reg [inst_sig_width+inst_exp_width:0] data_point, target;
output reg [inst_sig_width+inst_exp_width:0] weight1, weight2;
input	out_valid;
input	[inst_sig_width+inst_exp_width:0] out;

reg [inst_sig_width+inst_exp_width:0]weight1_array[0:11];
reg [inst_sig_width+inst_exp_width:0]weight2_array[0:2];
reg [inst_sig_width+inst_exp_width:0]data_point_array[0:99][0:3];
reg [inst_sig_width+inst_exp_width:0]target_store[0:99];



integer cycles,total_cycles;
integer input_file;

integer gap,a,round_counter,epoch_counter,pat_counter;

parameter Pattern_num = 100;


always #(`CYCLE_TIME/2.0) clk=~clk;
initial clk=0;

initial begin
	rst_n    = 1'b1;
	in_valid_d=1'b0;
	in_valid_t=1'b0;
	in_valid_w1=1'b0;
	in_valid_w2=1'b0;
	data_point=32'd0;
	target=32'd0;
	weight1=32'd0;
	weight2=32'd0;

	force clk=0;
	cycles=0;
	total_cycles=0;
	reset_task;

	input_file=$fopen("../00_TESTBED/input.txt","r");
	@(negedge clk);

	for(pat_counter=0;pat_counter<Pattern_num;pat_counter=pat_counter+1)begin
		data_in;
		for(epoch_counter=0;epoch_counter<25;epoch_counter=epoch_counter+1)begin
			for(round_counter=0;round_counter<100;round_counter=round_counter+1)begin
				put_data_to_design;
				wait_for_the_ans;
				check_ans;
			end
		end
	end


end



task reset_task ;
	begin
		#(10); rst_n = 0;

		#(10);
		if((out !== 0) || (out_valid !== 0)) begin
			$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
			$display ("                                \033[5;31m                           FAIL!                             \033[m                            ");
			$display ("                                \033[0;31m     Output signal should be 0 after initial RESET at %8t    \033[m                            ",$time);
			$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
			#(100);
			$finish ;
		end
		
		#(10); rst_n = 1 ;
		#(3.0); release clk;
	end
endtask

task data_in ;
	begin
		for(i=0;i<12;i=i+1)begin
			if((i>=0)||(i<3))begin
				a = $fscanf(input_file,"%f %f",weight1_array[i],weight2_array[i]);
			end
			else begin
				a = $fscanf(input_file,"%f",weight1_array[i]);
			end
		end
		for(i=0;i<100;i=i+1)begin
			for(j=0;j<4;j=j+1)begin
				if(i==0)begin
					a = $fscanf(input_file,"%f %f",data_point_array[i][j],target_store[i]);
				end
				else begin
					a = $fscanf(input_file,"%f",data_point_array[i][j]);
				end
			end
		end
	end
endtask

task put_data_to_design ;
	begin
		if((epoch_counter==0) && (round_counter==0))begin
			in_valid_w1 = 'b1;
			in_valid_w2 = 'b1;
			for(i=0;i<12;i=i+1)begin
				if((i>=0)||(i<3))begin
					weight1=weight1_array[i];
					weight2=weight2_array[i];
				end
				else begin
					in_valid_w2 = 'b0;
					weight1=weight1_array[i];
				end
				@(negedge clk);
			end
			in_valid_w1 = 'b0;
			repeat(2)@(negedge clk);
		end

		in_valid_d = 'b1;
		in_valid_t = 'b1;
		for(i=0;i<4;i=i+1)begin
			if(i==0)begin
				a = $fscanf(input_file,"%f %f",data_point_array[i],target_store);
				data_point=data_point_array[i];
				target=target_store;
			end
			else begin
				in_valid_t = 'b0;
				a = $fscanf(input_file,"%f",data_point_array[i]);
				data_point=data_point_array[i];
			end
			@(negedge clk);
			in_valid_d = 'b0;
		end
	end
endtask

task wait_for_the_ans ;
	cycles=0;
	begin
		while(out_valid === 0) begin
			cycles=cycles+1;
			if(latency == 300) begin
				$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
				$display ("                                                                                                                                            ");
				$display ("                                \033[5;31m                           FAIL!                             \033[m                               ");
				$display ("                                \033[0;31m                The clock cycles are over 300                \033[m                               ");
				$display ("                                                                                                                                            ");
				$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
				repeat(2)@(negedge clk);
				$finish;
			end
			@(negedge clk);
		end
	end 
endtask

task check_ans ;
	begin
		while(out_valid === 1) begin
			if(out!=target_store)begin
				$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
				$display ("                                                                                                                                            ");
				$display ("                                \033[5;31m                           FAIL!                             \033[m                               ");
				$display ("                                \033[0;31m                  The answer is not correct                  \033[m                               ");
				$display ("                                                                                                                                            ");
				$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
				repeat(2)@(negedge clk);
				$finish;
			end
			@(negedge clk);
		end
	end 
endtask


endmodule
