module MAZE(
    //Input Port
    clk,
    rst_n,
    in_valid,
    in,
    //Output Port
    out_valid,
    out
);

	input            clk, rst_n, in_valid, in;
    output reg		 out_valid;
    output reg [1:0] out;
    
	integer i,j;
	
	//Registers
	reg [1:0]state,next_state;
	
	reg MAZE[0:18][0:18];					//[row][colume]				(0)
	reg [4:0]rownum_counter;				//Value:0~16  				(1)
	reg [4:0]colnum_counter;				//Value:0~16  
	
	reg [4:0]current_rownum;				//(2)
	reg [4:0]current_colnum;
	reg [1:0]step_array[0:79];				//Size:80(0~79)  Value:0~3	(3)
	
	reg [6:0]stepnum_counter;				//Value:0~80				(4)
	
	reg [6:0]output_counter;				//Value:0~80
	reg out_state_flag;
	
	reg [3:0]branch_pointer;				//Value:0~15				(5)
	reg [6:0]branch_stepnum_array[0:15];	//Size:16					(6)
	reg [4:0]branch_rownum_array[0:15];		//(7)
	reg [4:0]branch_colnum_array[0:15];		//(8)
	reg branch_flag;						//(9)

	
	reg [3:0]checkwall;
	reg [2:0]checkwalltonum;
	
	//state parameter
	parameter [1:0]RESET=2'b00;
	parameter [1:0]INPUTMODE=2'b01;
	parameter [1:0]COMPUTE=2'b10;
	parameter [1:0]OUTPUTMODE=2'b11;

	//========== FSM ==========
	//---------- State assign ----------
	always@(negedge rst_n or posedge clk)begin
		if(!rst_n)begin
			state <= RESET;
		end
		else begin
			state <= next_state;
		end
	end
	//---------- Next State assign ----------
	always@(*)begin
		if(in_valid)begin
			next_state=INPUTMODE;
		end
		else if((state==INPUTMODE) && !in_valid)begin
			next_state=COMPUTE;
		end
		else if((state==COMPUTE) && (current_rownum==17) && (current_colnum==17))begin
			next_state=OUTPUTMODE;
		end
		else if((state==OUTPUTMODE) && (output_counter==stepnum_counter-1) && (out_state_flag))begin
			next_state=RESET;
		end
		else next_state=state;
	end
	//---------- Output assign ----------
	always@(negedge rst_n or posedge clk)begin
		if(!rst_n)begin
			out<=2'b00;
			out_state_flag<=0;
			output_counter<=0;
		end
		else begin
			case(state)
				COMPUTE:begin
					if((current_rownum==17) && (current_colnum==17))begin
						out<=step_array[output_counter];
						out_state_flag<=0;
						output_counter<=0;
					end
					else begin
						out<=2'b00;
						out_state_flag<=0;
						output_counter<=0;
					end
				end
				OUTPUTMODE:begin
					if((output_counter==stepnum_counter-1) && (out_state_flag))begin
						out<=0;
						out_state_flag<=0;
						output_counter<=0;
					end
					else if(out_state_flag)begin
						out<=step_array[output_counter+1];
						out_state_flag<=0;
						output_counter<=output_counter+1;
					end
					else begin
						out<=step_array[output_counter];
						out_state_flag<=1;
						output_counter<=output_counter;
					end
				end
				default:out<=2'b00;
			endcase
		end
	end
	always@(negedge rst_n or posedge clk)begin
		if(!rst_n)begin
			out_valid<=1'b0;
		end
		else begin
			case(state)
				COMPUTE:begin
					if ((current_rownum==17) && (current_colnum==17))begin
						out_valid<=1'b1;
					end
					else out_valid<=1'b0;
				end
				OUTPUTMODE:begin
					if((output_counter==stepnum_counter-1) && (out_state_flag))begin
						out_valid<=1'b0;
					end
					else begin
						out_valid<=1'b1;
					end
				end
				default:out_valid<=1'b0;
			endcase
		end
	end


	//----------Register assign----------

	// MAZE (0)
	always@(negedge rst_n or posedge clk)begin
		if(!rst_n)begin
			for(i=0;i<19;i=i+1)begin
				for(j=0;j<19;j=j+1)begin
					MAZE[i][j]<=0;
				end
			end
		end
		else if(in_valid)begin
			MAZE[rownum_counter][colnum_counter]<=in;
		end
		else begin
			case(state)
				RESET:begin
					for(i=0;i<19;i=i+1)begin
						for(j=0;j<19;j=j+1)begin
							MAZE[i][j]<=0;
						end
					end
				end
				COMPUTE:begin
					//If right side is road
					if(checkwall[0]==1)begin
						MAZE[current_rownum][current_colnum+1]<=1'b0;
					end
					//If down side is road
					else if(checkwall[1]==1)begin
						MAZE[current_rownum+1][current_colnum]<=1'b0;
					end
					//If left side is road
					else if(checkwall[2]==1)begin
						MAZE[current_rownum][current_colnum-1]<=1'b0;
					end
					//If up side is road
					else if(checkwall[3]==1)begin
						MAZE[current_rownum-1][current_colnum]<=1'b0;
					end
					//If stuck
					else begin end
				end
				default:begin end
			endcase
		end
	end

	// colnum_counter , rownum_counter (1)
	always@(negedge rst_n or posedge clk)begin
		if(!rst_n)begin
			colnum_counter <= 5'b00001;
			rownum_counter <= 5'b00001;
		end
		else begin
			case(state)
				RESET:begin
					//RESET -> INPUTMODE
					if(in_valid)begin
						colnum_counter <= colnum_counter+1;
						rownum_counter <= rownum_counter;
					end
					//RESET
					else begin
						colnum_counter <= 5'b00001;
						rownum_counter <= 5'b00001;
					end
				end
				INPUTMODE:begin
					//INPUTMODE -> COMPUTE
					if((colnum_counter==17) && (rownum_counter==17))begin
						colnum_counter <= 5'b00001;
						rownum_counter <= 5'b00001;
					end
					//INPUTMODE (row change)
					else if(colnum_counter==17)begin
						colnum_counter <= 5'b00001;
						rownum_counter <= rownum_counter+1;
					end
					//INPUTMODE (colume change)
					else begin
						colnum_counter <= colnum_counter+1;
						rownum_counter <= rownum_counter;
					end
				end
				default:begin
					colnum_counter <= colnum_counter;
					rownum_counter <= rownum_counter;
				end
			endcase
		end
	end

	// current_rownum , current_colnum (2) stepnum_counter (4)
	always@(negedge rst_n or posedge clk)begin
		if(!rst_n)begin
			current_rownum <= 5'b00001;
			current_colnum <= 5'b00001;

			stepnum_counter <= 7'b0000000;
		end
		else begin
			case(state)
				RESET:begin
					current_rownum <= 5'b00001;
					current_colnum <= 5'b00001;

					stepnum_counter <= 7'b0000000;
				end
				COMPUTE:begin
					if((current_rownum==17) && (current_colnum==17))begin
						current_rownum <= current_rownum;
						current_colnum <= current_colnum;

						stepnum_counter <= stepnum_counter;
					end
					//If right side is road
					else if(checkwall[0]==1)begin
						current_rownum <= current_rownum;
						current_colnum <= current_colnum+2;
						
						stepnum_counter <= stepnum_counter+1;
					end
					//If down side is road
					else if(checkwall[1]==1)begin
						current_rownum <= current_rownum+2;
						current_colnum <= current_colnum;

						stepnum_counter <= stepnum_counter+1;
					end
					//If left side is road
					else if(checkwall[2]==1)begin
						current_rownum <= current_rownum;
						current_colnum <= current_colnum-2;

						stepnum_counter <= stepnum_counter+1;
					end
					//If up side is road
					else if(checkwall[3]==1)begin
						current_rownum <= current_rownum-2;
						current_colnum <= current_colnum;

						stepnum_counter <= stepnum_counter+1;
					end
					//If stuck
					else begin
						current_rownum <= branch_rownum_array[branch_pointer];
						current_colnum <= branch_colnum_array[branch_pointer];

						stepnum_counter <= branch_stepnum_array[branch_pointer];
					end
				end
				default:begin
					current_rownum <= current_rownum;
					current_colnum <= current_colnum;

					stepnum_counter <= stepnum_counter;
				end
			endcase
		end
	end

	//step_array (3)
	always@(negedge rst_n or posedge clk)begin
		if(!rst_n)begin
			for(i=0;i<80;i=i+1)begin
				step_array[i]<=2'b00;
			end
		end
		else begin
			case(state)
				RESET:begin
					for(i=0;i<80;i=i+1)begin
						step_array[i]<=2'b00;
					end
				end
				COMPUTE:begin
					if((current_rownum==17) && (current_colnum==17))begin
						
					end
					//If right side is road
					else if(checkwall[0]==1)begin
						step_array[stepnum_counter]<=2'b00;
					end
					//If down side is road
					else if(checkwall[1]==1)begin
						step_array[stepnum_counter]<=2'b01;
					end
					//If left side is road
					else if(checkwall[2]==1)begin
						step_array[stepnum_counter]<=2'b10;
					end
					//If up side is road
					else if(checkwall[3]==1)begin
						step_array[stepnum_counter]<=2'b11;
					end
					//If stuck
					else begin
						
					end
				end
				default:begin
					
				end
			endcase
		end
	end

	//branch_pointer (5) , branch_stepnum_array (6) , branch_rownum_array (7) , branch_colnum_array (8) , branch_flag (9)
	always@(negedge rst_n or posedge clk)begin
		if(!rst_n)begin
			branch_pointer<=0;
			for(i=0;i<16;i=i+1)begin
				branch_stepnum_array[i]<=0;
				branch_rownum_array[i]<=0;
				branch_colnum_array[i]<=0;
			end
			branch_flag<=0;
		end
		else begin
			case(state)
				RESET:begin
					branch_pointer<=0;
					for(i=0;i<16;i=i+1)begin
						branch_stepnum_array[i]<=0;
						branch_rownum_array[i]<=0;
						branch_colnum_array[i]<=0;
					end
					branch_flag<=0;
				end
				COMPUTE:begin
					if(branch_flag)begin
						case(checkwalltonum)
							//stuck
							3'd0:begin
								if(branch_pointer==0)begin
									branch_pointer<=branch_pointer;
									branch_flag<=0;
								end
								else begin
									branch_pointer<=branch_pointer-1;
									branch_flag<=branch_flag;
								end
								
							end

							3'd1:begin
								branch_pointer<=branch_pointer;
								
								branch_flag<=branch_flag;
							end	

							//branch
							3'd2:begin
								branch_pointer<=branch_pointer+1;
								branch_stepnum_array[branch_pointer+1]<=stepnum_counter;
								branch_rownum_array[branch_pointer+1]<=current_rownum;
								branch_colnum_array[branch_pointer+1]<=current_colnum;
								branch_flag<=1;
							end

							3'd3:begin
								branch_pointer<=branch_pointer+1;
								branch_stepnum_array[branch_pointer+1]<=stepnum_counter;
								branch_rownum_array[branch_pointer+1]<=current_rownum;
								branch_colnum_array[branch_pointer+1]<=current_colnum;
								branch_flag<=1;
							end

							3'd4:begin
								branch_pointer<=branch_pointer+1;
								branch_stepnum_array[branch_pointer+1]<=stepnum_counter;
								branch_rownum_array[branch_pointer+1]<=current_rownum;
								branch_colnum_array[branch_pointer+1]<=current_colnum;
								branch_flag<=1;
							end

							default:begin end
						endcase
					end
					else begin
						case(checkwalltonum)
							//stuck
							3'd0:begin end
							
							3'd1:begin
								branch_pointer<=branch_pointer;
								
								branch_flag<=branch_flag;
							end

							//branch
							3'd2:begin
								branch_pointer<=branch_pointer+1;
								branch_stepnum_array[branch_pointer+1]<=stepnum_counter;
								branch_rownum_array[branch_pointer+1]<=current_rownum;
								branch_colnum_array[branch_pointer+1]<=current_colnum;
								branch_flag<=1;
							end

							3'd3:begin
								branch_pointer<=branch_pointer+1;
								branch_stepnum_array[branch_pointer+1]<=stepnum_counter;
								branch_rownum_array[branch_pointer+1]<=current_rownum;
								branch_colnum_array[branch_pointer+1]<=current_colnum;
								branch_flag<=1;
							end

							3'd4:begin
								branch_pointer<=branch_pointer+1;
								branch_stepnum_array[branch_pointer+1]<=stepnum_counter;
								branch_rownum_array[branch_pointer+1]<=current_rownum;
								branch_colnum_array[branch_pointer+1]<=current_colnum;
								branch_flag<=1;
							end

							default:begin end
						endcase
					end
				end
				default:begin
					
				end
			endcase
		end
	end
	
	always@(*)begin
		checkwall={MAZE[current_rownum-1][current_colnum],MAZE[current_rownum][current_colnum-1],MAZE[current_rownum+1][current_colnum],MAZE[current_rownum][current_colnum+1]};
	end

	always@(*)begin
		case(checkwall)
			//stuck
			4'b0000:checkwalltonum=3'd0;
			
			4'b0001:checkwalltonum=3'd1;
			4'b0010:checkwalltonum=3'd1;
			4'b0100:checkwalltonum=3'd1;
			4'b1000:checkwalltonum=3'd1;

			//branch
			4'b0011:checkwalltonum=3'd2;
			4'b0101:checkwalltonum=3'd2;
			4'b0110:checkwalltonum=3'd2;
			4'b1001:checkwalltonum=3'd2;
			4'b1010:checkwalltonum=3'd2;
			4'b1100:checkwalltonum=3'd2;

			4'b0111:checkwalltonum=3'd3;
			4'b1011:checkwalltonum=3'd3;
			4'b1101:checkwalltonum=3'd3;
			4'b1110:checkwalltonum=3'd3;

			4'b1111:checkwalltonum=3'd4;
		endcase
	end

endmodule
