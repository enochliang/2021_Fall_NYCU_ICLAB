
module bridge(input clk, INF.bridge_inf inf);

typedef enum logic  [2:0] { IDLE				= 3'd0 ,
                            INPUTMODE	        = 3'd1 ,
							READ_DRAM_put_addr	= 3'd2 ,
							READ_DRAM_wait_dt	= 3'd3 , 
							WRITE_DRAM_put_addr	= 3'd4 ,
							WRITE_DRAM_put_dt	= 3'd5 ,
							WRITE_DRAM_wait_ok  = 3'd6 ,
							OUTPUTMODE			= 3'd7 
							}  state_t ;


//================================================================
// logic 
//================================================================
state_t state, next_state;
logic mode_s;
logic [7:0]  addr_s;
logic [63:0] data_s;
//================================================================
// design 
//================================================================
always_ff@(negedge inf.rst_n or posedge clk)begin
	if(!inf.rst_n) state <= IDLE;
	else state <= next_state;
end
always_comb begin
	if(!inf.rst_n) next_state = IDLE;
	else if(inf.C_in_valid) next_state = INPUTMODE;
	else begin
		case(state)
			INPUTMODE:begin
				if(mode_s) next_state = READ_DRAM_put_addr;
				else next_state = WRITE_DRAM_put_addr;
			end
			READ_DRAM_put_addr:begin
				if(inf.AR_READY) next_state = READ_DRAM_wait_dt;
				else next_state = state;
			end
			WRITE_DRAM_put_addr:begin
				if(inf.AW_READY) next_state = WRITE_DRAM_put_dt;
				else next_state = state;
			end
			READ_DRAM_wait_dt:begin
				if(inf.R_VALID) next_state = OUTPUTMODE;
				else next_state = state;
			end
			WRITE_DRAM_put_dt:begin
				if(inf.W_READY) next_state = WRITE_DRAM_wait_ok;
				else next_state = state;
			end
			WRITE_DRAM_wait_ok:begin
				if(inf.B_VALID && (inf.B_RESP == 2'b00)) next_state = OUTPUTMODE;
				else next_state = state;
			end
			OUTPUTMODE:next_state = IDLE;
			default:next_state = state;
		endcase
	end
end


always_ff@(posedge clk)begin
	if(inf.C_in_valid) mode_s <= inf.C_r_wb;
end

always_ff@(posedge clk) begin
	if(inf.C_in_valid) addr_s <= inf.C_addr;
end

always_ff@(negedge inf.rst_n or posedge clk) begin
	if(!inf.rst_n) data_s <= 0;
	else begin
		if(inf.C_in_valid && !inf.C_r_wb) data_s <= inf.C_data_w;
		if((state == READ_DRAM_wait_dt) && inf.R_VALID) data_s <= inf.R_DATA;
	end
end

always_ff@(negedge inf.rst_n or posedge clk) begin
	if(!inf.rst_n) inf.C_out_valid <= 1'b0;
	else begin
		if(inf.C_out_valid == 1) inf.C_out_valid <= 1'b0;
		if(next_state == OUTPUTMODE) inf.C_out_valid <= 1'b1;
	end
end

always_comb begin
	inf.C_data_r = data_s;

	if(state == READ_DRAM_put_addr) inf.AR_VALID = 1'b1;
	else inf.AR_VALID = 1'b0;
	
	if(state == WRITE_DRAM_put_addr) inf.AW_VALID = 1'b1;
	else inf.AW_VALID = 1'b0;
	
	if(state == READ_DRAM_wait_dt) inf.R_READY = 1'b1;
	else inf.R_READY = 1'b0;
	
	if(state == WRITE_DRAM_put_dt) inf.W_VALID = 1'b1;
	else inf.W_VALID = 1'b0;
	
	inf.W_DATA = data_s;
	
	if(state == WRITE_DRAM_wait_ok) inf.B_READY = 1'b1;
	else inf.B_READY = 1'b0;
end


	
always_ff@(negedge inf.rst_n or posedge clk)begin
	if(!inf.rst_n)begin
		inf.AR_ADDR <= 0;
	end
	else if(next_state == READ_DRAM_put_addr) inf.AR_ADDR <= {6'b100000,addr_s,3'b000};
end
always_ff@(negedge inf.rst_n or posedge clk)begin
	if(!inf.rst_n)begin
		inf.AW_ADDR <= 0;
	end
	else if(next_state == WRITE_DRAM_put_addr) inf.AW_ADDR <= {6'b100000,addr_s,3'b000};
end

endmodule