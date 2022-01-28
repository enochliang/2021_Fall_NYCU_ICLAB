`ifdef RTL
	`timescale 1ns/1ps
	`include "CDC.v"
	`define CYCLE_TIME_clk1 14.1
	`define CYCLE_TIME_clk2 2.5
	`define CYCLE_TIME_clk3 2.7
`endif
`ifdef GATE
	`timescale 1ns/1ps
	`include "CDC_SYN.v"
	`define CYCLE_TIME_clk1 14.1
	`define CYCLE_TIME_clk2 2.5
	`define CYCLE_TIME_clk3 2.7
`endif

module PATTERN(clk_1,clk_2,clk_3,rst_n,in_valid,mode,CRC,message,out_valid,out
	
);

output reg clk_1,clk_2,clk_3;
output reg rst_n;
output reg in_valid;
output reg mode;
output reg [59:0] message;
output reg CRC;


input out_valid;
input[59:0] out;


//================================================================
// parameters & integer
//================================================================
parameter tot_pat_num = 500;
integer gap;
integer pat_cnt;
integer i;
integer latency;
integer seed;
//================================================================
// wire & registers 
//================================================================
reg [59:0] MESSAGE_c,OUT_c,DN_c,DR_c;//,DN_t,DR_t
reg [8:0] POLY_c;
reg MODE_c;
reg CRC_c;
//================================================================
// initial
//================================================================
always #(`CYCLE_TIME_clk1/2.0) clk_1 = ~clk_1;
initial clk_1 = 0;

always #(`CYCLE_TIME_clk2/2.0) clk_2 = ~clk_2;
initial clk_2 = 0;

always #(`CYCLE_TIME_clk3/2.0) clk_3 = ~clk_3;
initial clk_3 = 0;

initial begin
	rst_n = 1'b1;
	in_valid = 1'b0;
	mode = 1'bx;
	message = 'dx;
	CRC = 1'bx;

	force clk_1 = 0;
	force clk_2 = 0;
	force clk_3 = 0;

	RESET_task;
	seed = 100;

	MODE_c = 0;
	CRC_c = 0;
	$display("mode = %d , CRC = %d",MODE_c,CRC_c);
	TEST_A_CONDI_task;
	MODE_c = 0;
	CRC_c = 1;
	$display("mode = %d , CRC = %d",MODE_c,CRC_c);
	TEST_A_CONDI_task;
	MODE_c = 1;
	CRC_c = 0;
	$display("mode = %d , CRC = %d",MODE_c,CRC_c);
	TEST_A_CONDI_task;
	MODE_c = 1;
	CRC_c = 1;
	$display("mode = %d , CRC = %d",MODE_c,CRC_c);
	TEST_A_CONDI_task;
	PASS_task;

end
//================================================================
// task
//================================================================

task RESET_task;
begin
	#(10);
	rst_n = 1'b0;
	#(10);
	if( ( out !== 0 ) || ( out_valid !== 0 ) )begin
	$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
	$display ("                                \033[5;31m                           FAIL!                             \033[m                            ");
	$display ("                                \033[0;31m     Output signal should be 0 after initial RESET at %8t    \033[m                            ",$time);
	$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
	$finish;
	end
	#(10);
	rst_n = 1'b1;
	#(3.0);
	release clk_1;
	release clk_2;
	release clk_3;
	end
endtask

task TEST_A_CONDI_task;
begin
	for( pat_cnt = 0 ; pat_cnt < tot_pat_num ; pat_cnt = pat_cnt + 1 ) begin
		INPUT_task;
		CALCULATE_task;
		WAIT_OUTPUT_task;
		$display("\033[0;32mPass PATTERN NO.%3d\033[m",pat_cnt);
	end
end
endtask

task INPUT_task;
begin
	gap = $urandom_range(1,3);
	
	if(!CRC_c) POLY_c = 9'b100110001;
	else if(CRC_c) POLY_c = 9'b000101011;
	
	if(!MODE_c) begin
		if(CRC_c) begin
			MESSAGE_c[59:55] = 0;
			for (i=0;i<55;i=i+1)begin
				seed = $urandom(seed);
				MESSAGE_c[i] = $urandom(seed) % 'd2;
			end
		end
		else if(!CRC_c) begin
			MESSAGE_c[59:52] = 0;
			for (i=0;i<52;i=i+1)begin
				seed = $urandom(seed);
				MESSAGE_c[i] = $urandom(seed) % 'd2;
			end
		end
	end
	else if(MODE_c) begin
		for (i=0;i<60;i=i+1)begin
			seed = $urandom(seed);
			MESSAGE_c[i] = $urandom(seed) % 'd2;
		end
	end
	
	repeat(gap)@(negedge clk_1);
	message = MESSAGE_c;
	mode = MODE_c;
	CRC = CRC_c;
	in_valid = 1'b1;
	if((out_valid !== 0) || (out !== 0))begin
		$display("--------------------------------------------------------------------------------------------------");
		$display("                               \033[5;31m              FAIL !              \033[m                                 ");
		$display("                       \033[0;31m    OUTPUTs should be 0 when in_valid is high.    \033[m                         ");
		$display("--------------------------------------------------------------------------------------------------");
		$finish;
	end
	@(negedge clk_1);
	message = 'dx;
	mode = 1'bx;
	CRC = 1'bx;
	in_valid = 1'b0;
end
endtask

task CALCULATE_task;
begin
	if(!MODE_c && !CRC_c)begin
		DN_c = {MESSAGE_c[51:0],8'd0};
		DR_c = {POLY_c,51'd0};
		for(i=59;i>7;i=i-1)begin
			if(DN_c[i]) DN_c = DN_c ^ DR_c;
			DR_c = {1'b0,DR_c[59:1]} ;
		end
		OUT_c = {MESSAGE_c[51:0],8'd0} ^ DN_c;
	end
	else if(!MODE_c && CRC_c)begin
		DN_c = {MESSAGE_c[54:0],5'd0};
		DR_c = {POLY_c[5:0],54'd0};
		for(i=59;i>4;i=i-1)begin
			if(DN_c[i]) begin
				DN_c = DN_c ^ DR_c;
				OUT_c[i] = 1;
			end
			else begin
				OUT_c[i] = 0;
			end
			DR_c = {1'b0,DR_c[59:1]} ;
		end
		OUT_c = {MESSAGE_c[54:0],5'd0} ^ DN_c;
	end
	else if(MODE_c && !CRC_c)begin
		DN_c = MESSAGE_c;
		DR_c = {POLY_c,51'd0};
		for(i=59;i>7;i=i-1)begin
			if(DN_c[i]) DN_c = DN_c ^ DR_c;
			DR_c = {1'b0,DR_c[59:1]} ;
		end
		//pass
		if(DN_c[7:0] === 0)begin
			for(i=0;i<60;i=i+1)begin
				OUT_c[i] = 0;
			end
		end
		//not pass
		else begin
			for(i=0;i<60;i=i+1)begin
				OUT_c[i] = 1;
			end
		end
	end
	else if(MODE_c && CRC_c)begin
		DN_c = MESSAGE_c;
		DR_c = {POLY_c[5:0],54'd0};
		for(i=59;i>4;i=i-1)begin
			if(DN_c[i]) DN_c = DN_c ^ DR_c;
			DR_c = {1'b0,DR_c[59:1]} ;
		end
		//pass
		if(DN_c[4:0] === 0)begin
			for(i=0;i<60;i=i+1) begin
				OUT_c[i] = 0;
			end
		end
		else begin
			for(i=0;i<60;i=i+1) begin
				OUT_c[i] = 1;
			end
		end
	end

	//testing
	/* if(!CRC_c)begin
		DN_t = OUT_c;
		DR_t = {POLY_c,51'd0};
		for(i=59;i>7;i=i-1)begin
			if(DN_t[i]) DN_t = DN_t ^ DR_t;
			DR_t = {1'b0,DR_t[59:1]} ;
		end
	end
	else if(CRC_c)begin
		DN_t = OUT_c;
		DR_t = {POLY_c[5:0],54'd0};
		for(i=59;i>4;i=i-1)begin
			if(DN_t[i]) DN_t = DN_t ^ DR_t;
			DR_t = {1'b0,DR_t[59:1]} ;
		end
	end */

end
endtask

task WAIT_OUTPUT_task;
begin
	latency = 0;
	while(out_valid === 0)begin
		latency = latency + 1;
		CHECK_LAT_task;
		@(negedge clk_3);
	end
	while(out_valid === 1)begin
		CHECK_OUTPUT_task;
		@(negedge clk_3);
	end
end
endtask

task CHECK_LAT_task;
begin
	if(latency === 400)begin
		$display("--------------------------------------------------------------------------------------------------");
		$display("                               \033[5;31m              FAIL !              \033[m                                 ");
		$display("                               \033[0;31m    latency is over 400 cycles    \033[m                                 ");
		$display("--------------------------------------------------------------------------------------------------");
		$finish;
	end
end
endtask

task CHECK_OUTPUT_task;
begin
	if( out !== OUT_c) begin
		$display("--------------------------------------------------------------------------------------------------");
		$display("                               \033[5;31m              FAIL !              \033[m                                 ");
		$display("                               \033[0;31m          Output Error !          \033[m                                 ");
		$display("                               \033[0;31m   Yours : %15h , Golden : %15h   \033[m                                 ",out,OUT_c);
		$display("--------------------------------------------------------------------------------------------------");
		$finish;
	end
end
endtask

task PASS_task;
begin
	$display("--------------------------------------------------------------------------------------------------");
	$display("                               \033[5;32m         CONGRADULATION !         \033[m                                 ");
	$display("                               \033[0;32m      You pass all PATTERNs !     \033[m                                 ");
	$display("--------------------------------------------------------------------------------------------------");
	$finish;
end
endtask

endmodule
