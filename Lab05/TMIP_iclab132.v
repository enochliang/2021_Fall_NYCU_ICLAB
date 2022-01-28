module TMIP(
// input signals
    clk,
    rst_n,
    in_valid,
	in_valid_2,
    image,
	img_size,
    template, 
    action,
	
// output signals
    out_valid,
    out_x,
    out_y,
    out_img_pos,
    out_value
);

//===== input =====
input        clk, rst_n, in_valid, in_valid_2;
input [15:0] image, template;
input [4:0]  img_size;
input [1:0]  action;
//===== output =====
output reg        out_valid;
output reg [3:0]  out_x, out_y; 
output reg [7:0]  out_img_pos;
output reg signed[39:0] out_value;
//===== state =====
parameter RESET=0;
parameter INPUTMODE1=1;
parameter INPUTMODE2=2;
parameter JUDGECOMPUTE=3;
parameter POOLINGMODE=4;
parameter FLIPMODE=5;
parameter BRIGHTNESSMODE=6;
parameter CORRELATION=7;
parameter OUTPUTMODE=8;

//--------------------------

//===== register =====
reg [3:0]  state,next_state;
reg [7:0]  addr;					//( A )
reg [15:0] template_store[0:8];		//( B )
reg [4:0]  size;					//( C )

	// Max Pooling
	reg [2:0]  Pooling_flag;		//( E1 )
	reg [8:0]  counter;				//( F )
	reg [15:0] Pooling_cmp;			//( G )
	reg [15:0] Pooling_store;		//( H )
	reg [3:0]  col_counter;		//( I )
	reg [3:0]  row_counter;		//( J )
	reg [7:0]  Pooling_start;		//( K )
	reg [7:0]  Pooling_new_pos;		//( L )

	
	// Horizontal Flip
	reg flip_flag;					//( E2 )
	reg signed [15:0] Swap_array[0:15];	//( M )

	// Brightness Adjustment
	reg [2:0] Brightness_flag;		//( E3 )

	// Cross Correlation
	reg [1:0] cross_direct;			//( N )


	reg  [34:0] cor_reg;  			//( O )
	reg  [34:0] cor_max;			//( P )
	reg  [3:0]  x_max,y_max;
	reg  [7:0]  addr_max;

	reg [7:0] match_addr[1:9];
	reg [3:0] matchnum;

	reg [3:0]brightness_counter;

//===== wire =====
reg  [15:0] Pooling_cmp_out;		//( 1 )

reg  [7:0]  address1;				//( 2 )

wire signed [15:0] data_out_mem_wire;
reg  signed [15:0] data_into_mem_wire;		//( 3 )

reg cen_wire,wen_wire,oen_wire;		//( 4 )


reg  [7:0]  address2;				//( 5 )

wire signed [34:0] data_out_mem_wire_2;
reg  signed [34:0] data_into_mem_wire_2;	//( 6 )

reg cen_wire_2,wen_wire_2,oen_wire_2;//( 7 )




wire signed [15:0] B1out [1:7];
reg  signed [15:0] B1in  [1:7];

wire signed [34:0] cor_out;

integer a;
//----------------------------------


//========== Behavioral ==========//

	/* always@(posedge clk or negedge rst_n)begin
		
		for (a=0;a<9;a=a+1)begin
			$write("S[%1d]:%d  ",a,Swap_array[a]);
		end
		$write("c1:%1d ,w1:%1d ,o1:%1d ,",cen_wire,wen_wire,oen_wire);
		$display();
		$write("state:%1d ,",state);
		$write("addr:%3d ,",addr);
		$write("Pool_f:%1d ,",Pooling_flag);
		$write("Flip_f:%1d ,",flip_flag);
		$write("data_out1:%6d ,",data_out_mem_wire);
		$write("data_into1:%6d ,",data_into_mem_wire);
		$write("Pooling_cmp:%6d ,",Pooling_cmp);
		//$write("data_out2:%5d ,",data_out_mem_wire_2);
		//$write("data_into2:%5d ,",data_into_mem_wire_2);
		//$write("size:%2d ,",size);
		//$write("cor_out:%11d ,",cor_out);
		$write("counter:%3d ,",counter);
		$write("col_counter:%2d , row_counter:%2d",col_counter,row_counter);
		//$write("out_x:%2d, out_y:%2d",out_x, out_y);
		//$write("out_valid:%3d ,",out_valid);
		//$write("out_value:%11d ,",out_value);
		//$write("c2:%1d ,w2:%1d ,o2:%1d ,",cen_wire_2,wen_wire_2,oen_wire_2);
		$write("address1:%3d" ,address1);
		//$write("address2:%3d" ,address2);
		$display();
		//$display("state:%1d , addr:%3d , counter:%3d , size:%2d , cross_direct:%1d , row_counter:%2d , col_counter:%2d",state,addr,counter,size,cross_direct,row_counter,col_counter);
	end */

	// Output Assignment
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			out_x       <= 0;
			out_y       <= 0;
			out_valid   <= 0;
			out_img_pos <= 0;
			out_value   <= 0;
		end
		else if(state == OUTPUTMODE) begin

			if((counter>0) && (((counter<257)&&(size==16))||((counter<65)&&(size==8))||((counter<17)&&(size==4))) )begin
				out_valid   <= 1;
				out_value   <= data_out_mem_wire_2;
				out_x       <= x_max;
				out_y       <= y_max;
			end
			else begin
				out_valid   <= 0;
				out_value   <= 0;
				out_x       <= 0;
				out_y       <= 0;
			end

			if((addr>0) && (addr<matchnum))begin
				out_img_pos <= match_addr[addr];
			end
			else begin
				out_img_pos <= 0;
			end
		end 
	end



	// set state	(checked)
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			state<=RESET;
		end
		else begin
			state<=next_state;
		end
	end
	// set next_state      (TODO)
	always@(*) begin
		if(!rst_n) begin
			next_state=RESET;
		end
		else if(in_valid)begin
			next_state=INPUTMODE1;
		end
		else if(in_valid_2)begin
			next_state=INPUTMODE2;
		end
		else begin
			case(state)
				INPUTMODE2:begin
					next_state=JUDGECOMPUTE;
				end
				JUDGECOMPUTE:begin
					next_state=POOLINGMODE;
				end
				POOLINGMODE:begin
					//skip pooling
					if 		(Pooling_flag==0) next_state=FLIPMODE;
					//pooling finish
					else if ((col_counter==7) && (row_counter==7) && (size==16) && (counter==5)) next_state=POOLINGMODE;
					else if ((col_counter==3) && (row_counter==3) && (size==8) && (counter==5))  next_state=FLIPMODE;
					//continue pooling
					else next_state=POOLINGMODE;
				end
				FLIPMODE:begin
					//skip flip
					if 		(flip_flag==0) next_state=BRIGHTNESSMODE;
					//flip finish
					else if ((row_counter==15) && (size==16) && (counter==32) ) next_state=BRIGHTNESSMODE;
					else if ((row_counter==7) && (size==8) && (counter==16))   next_state=BRIGHTNESSMODE;
					else if ((row_counter==3) && (size==4) && (counter==8))    next_state=BRIGHTNESSMODE;
					//continue flipping
					else    next_state=FLIPMODE;
				end
				BRIGHTNESSMODE:begin
					//skip brightness adjustment
					if 		(Brightness_flag==0) next_state=CORRELATION;
					//brightness adjustment finished
					else if ( (size==16) && (brightness_counter==15) && (counter==32)) next_state=CORRELATION;
					else if ( (size==8) && (brightness_counter==3) && (counter==32))   next_state=CORRELATION;
					else if ( (size==4) && (brightness_counter==0) && (counter==32))    next_state=CORRELATION;
					else next_state=BRIGHTNESSMODE;
				end
				CORRELATION:begin
					if((addr!=0) && (counter==5) && (cross_direct==3)) next_state=OUTPUTMODE;
					else next_state=CORRELATION;
				end
				OUTPUTMODE:begin
					if(	((counter==257)&&(size==16))||((counter==65)&&(size==8))||((counter==17)&&(size==4)) ) next_state=RESET;
					else next_state=OUTPUTMODE;
				end
				default:begin
					next_state=state;
				end
			endcase
		end
	end

	// ( A )
	//addr       (TODO)
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			addr<=0;
		end
		else if (in_valid)begin
			addr<=addr+1;
		end
		else begin
			case(state)
				RESET:begin
					addr<=0;
				end
				JUDGECOMPUTE:begin
					addr<=0;
				end
				POOLINGMODE:begin
					//skip pooling
					if      (Pooling_flag==0) addr<=0;
					//pooling finish
					else if ((col_counter==7) && (row_counter==7) && (size==16) && (counter==5)) addr<=0;
					else if ((col_counter==3) && (row_counter==3) && (size==8) && (counter==5)) addr<=0;
					//pooling move to right
					else if (counter==0) addr<=addr+1;
					//pooling move down
					else if (counter==1) addr<=addr+size;
					//pooling move to left
					else if (counter==2) addr<=addr-1;
					//pooling move to new position (prepare to write the pooling max number)
					else if (counter==3) addr<=Pooling_new_pos;
					//pooling move to next start point
					else if (counter==5) addr<=Pooling_start;
				end
				FLIPMODE:begin
					//skip flip
					if      (!flip_flag) addr<=0;
					//flip finish
					else if ((size==16) && (counter==32) && (row_counter==15))  addr<=0;
					else if ((size==8) && (counter==16) && (row_counter==7))    addr<=0;
					else if ((size==4) && (counter==8) && (row_counter==3))     addr<=0;
					//flip row change
					else if ((size==16) && (counter==32) && (row_counter!=15))  addr<=addr+size;
					else if ((size==8) && (counter==16) && (row_counter!=7))    addr<=addr+size;
					else if ((size==4) && (counter==8) && (row_counter!=3))     addr<=addr+size;
					//flip column change
					else if ((size==16) && (counter<15))                            addr<=addr+1;
					else if ((size==16) && (counter>16) && (counter!=32))           addr<=addr-1;
					else if ((size==8) && (counter<7))                              addr<=addr+1;
					else if ((size==8) && (counter>8) && (counter!=16))             addr<=addr-1;
					else if ((size==4) && (counter<3))                              addr<=addr+1;
					else if ((size==4) && (counter>4) && (counter!=8))              addr<=addr-1;
					
				end
				BRIGHTNESSMODE:begin
					//skip BRIGHTNESSMODE
					if      (Brightness_flag==0) addr<=0;
					//BRIGHTNESSMODE finished
					else if ( (size==16) && (brightness_counter==15) && (counter==32))  addr<=0;
					else if ( (size==8) && (brightness_counter==3) && (counter==32))    addr<=0;
					else if ( (size==4) && (brightness_counter==0) && (counter==32))    addr<=0;

					//BRIGHTNESSMODE column change and row change
					else if ((counter<15) || (counter>16))         addr<=addr+1;
					//BRIGHTNESSMODE back to the head of the row
					else if (counter==16)                                          addr<=addr-15;
				end
				CORRELATION:begin
					//first correlation block finished
					if((addr==0) && (counter==11))addr<=addr+1;
					//correlation block finished
					else if((addr!=0) && (counter==5))begin
						if (cross_direct==0) addr<=addr+1;
						if (cross_direct==1) addr<=addr+size;
						if (cross_direct==2) addr<=addr-1;
						//correlation mode finish
						if (cross_direct==3) addr<=0;
					end
				end
				OUTPUTMODE:begin
					addr<=addr+1;
				end

			endcase
		end
	end

	// ( B )
	//template_store(checked)
	always@(posedge clk) begin
		if(in_valid)begin
			if(addr<'d9)begin
				template_store[0]<=template_store[1];
				template_store[1]<=template_store[2];
				template_store[2]<=template_store[3];
				template_store[3]<=template_store[4];
				template_store[4]<=template_store[5];
				template_store[5]<=template_store[6];
				template_store[6]<=template_store[7];
				template_store[7]<=template_store[8];
				template_store[8]<=template;
			end
		end
	end

	// ( C )
	//size(checked)
	always@(posedge clk) begin
		if(in_valid)begin
			if(addr=='d0)begin
				size<=img_size;
			end
		end
		else if(state==POOLINGMODE)begin
			if      ((col_counter==7) && (row_counter==7) && (size==16) && (counter==5)) size<=size>>1;
			else if ((col_counter==3) && (row_counter==3) && (size==8) && (counter==5)) size<=size>>1;
		end
	end

	// ( E1 )( E2 )( E3 )
	//Pooling_flag,flip_flag,Brightness_flag
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n)begin
			Pooling_flag<=0;
			flip_flag<=0;
			Brightness_flag<=0;
		end
		else if(in_valid_2)begin
			if      (action==2'd1) Pooling_flag<=Pooling_flag+1;
			else if (action==2'd2) flip_flag<=~flip_flag;
			else if (action==2'd3) Brightness_flag<=Brightness_flag+1;
		end
		else begin
			case(state)
				RESET:begin
					Pooling_flag<=0;
					flip_flag<=0;
					Brightness_flag<=0;
				end
				JUDGECOMPUTE:begin
					case(size)
						5'b10000:if(Pooling_flag>1) Pooling_flag<=3'd2;
						5'b01000:if(Pooling_flag>0) Pooling_flag<=3'd1;
						5'b00100:Pooling_flag<=3'd0;
					endcase
				end
				POOLINGMODE:begin
					if      ((col_counter==7) && (row_counter==7) && (size==16) && (counter==5)) Pooling_flag <= Pooling_flag-1;
					else if ((col_counter==3) && (row_counter==3) && (size==8) && (counter==5)) Pooling_flag <= Pooling_flag-1;
				end
				FLIPMODE:begin
					if      ((size==16) && (counter==32) && (row_counter==15))  flip_flag<=0;
					else if ((size==8) && (counter==16) && (row_counter==7))    flip_flag<=0;
					else if ((size==4) && (counter==8) && (row_counter==3))     flip_flag<=0;
				end
			endcase
		end
	end

	// ( F )
	//counter
	always@(posedge clk) begin
		if(state==JUDGECOMPUTE)begin
			counter<=0;
		end
		else if(state==POOLINGMODE)begin
			if      (Pooling_flag==0) counter<=0;
			else if (counter==5)      counter<=0;
			else    counter<=counter+1;
		end
		else if(state==FLIPMODE)begin
			if(!flip_flag)counter<=0;
			else begin
				case(size)
					'd16:begin
						if (counter==32) counter<=0;
						else counter<=counter+1;
					end
					'd8:begin
						if (counter==16) counter<=0;
						else counter<=counter+1;
					end
					'd4:begin
						if (counter==8) counter<=0;
						else counter<=counter+1;
					end
				endcase
			end
		end
		else if(state==BRIGHTNESSMODE)begin
			if (counter==32) counter<=0;
			else counter<=counter+1;
		end
		else if(state==CORRELATION)begin
			//first correlation block finished
			if ((addr==0) && (counter==11))    counter<=0;
			//correlation block finished
			else if((addr!=0) && (counter==5)) counter<=0;
			//correlation continue
			else counter<=counter+1;
		end
		else if(state==OUTPUTMODE)begin
			counter<=counter+1;
		end
	end

	// ( G )
	//Pooling_cmp
	always@(posedge clk) begin
		if(state==JUDGECOMPUTE)begin
			Pooling_cmp<=16'b1000000000000000;
		end
		else if(state==POOLINGMODE)begin
			if((counter>1) && (counter<5)) Pooling_cmp<=Pooling_cmp_out;
			else if (counter==5) Pooling_cmp<=16'b1000000000000000;
			else if ((col_counter==7) && (row_counter==7) && (size==16) && (counter==5)) Pooling_cmp<=16'b1000000000000000;
			else if ((col_counter==3) && (row_counter==3) && (size==8) && (counter==5))  Pooling_cmp<=16'b1000000000000000;
			
		end
	end

	// ( H )
	//Pooling_store
	always@(posedge clk) begin
		if(state==POOLINGMODE)begin
			if((counter>0) && (counter<5)) Pooling_store<=data_out_mem_wire;
		end
	end

	// ( I )
	//col_counter
	always@(posedge clk) begin
		if(state==JUDGECOMPUTE)begin
			col_counter<=0;
		end
		if(state==POOLINGMODE)begin
			//skip pooling
			if      (Pooling_flag==0) col_counter<=0;
			//pooling finished
			else if ( ((col_counter==7) && (size==16) && (counter==5)) || ((col_counter==3) && (size==8) && (counter==5)) ) col_counter<=0;
			//pooling block column change
			else if ( counter==5 ) col_counter<=col_counter+1;
		end
		else if(state==CORRELATION)begin
			//first correlation block finished
			if ( ((addr==0) && (counter==11)) || ((addr!=0) && (counter==5) && (cross_direct==0)) )    col_counter<=col_counter+1;
			//correlation block finished
			else if((addr!=0) && (counter==5) && (cross_direct==2)) col_counter<=col_counter-1;
		end
	end

	// ( J )
	//row_counter
	always@(posedge clk) begin
		case(state)
			JUDGECOMPUTE:row_counter<=0;
			POOLINGMODE:begin
				//skip pooling
				if      (Pooling_flag==0) row_counter<=0;
				//pooling finished
				else if ( ((col_counter==7) && (row_counter==7) && (size==16) && (counter==5)) || ((col_counter==3) && (row_counter==3) && (size==8) && (counter==5)) ) row_counter<=0;
				//pooling block row change
				else if ( ((col_counter==7) && (size==16) && (counter==5)) || ((col_counter==3) && (size==8) && (counter==5)) ) row_counter<=row_counter+1;
			end
			FLIPMODE:begin
				//skip flip
				if      (!flip_flag)                                       row_counter <= 0 ;
				//flip finished
				else if ((row_counter==15) && (size==16) && (counter==32)) row_counter <= 0;
				else if ((row_counter==7) && (size==8) && (counter==16))   row_counter <= 0;
				else if ((row_counter==3) && (size==4) && (counter==8))    row_counter <= 0;
				//flip row change
				else if ((size==16) && (counter==32))                          row_counter <= row_counter+1;
				else if ((size==8) && (counter==16))                           row_counter <= row_counter+1;
				else if ((size==4) && (counter==8))                            row_counter <= row_counter+1;
			end
			BRIGHTNESSMODE:begin
				//skip BRIGHTNESSMODE
				if      ( Brightness_flag == 0 )                               row_counter <= 0 ;
				//BRIGHTNESSMODE finished
				else if ( (size==16) && (brightness_counter==15) && (counter==32))  row_counter <= 0;
				else if ( (size==8) && (brightness_counter==3) && (counter==32))    row_counter <= 0;
				else if ( (size==4) && (brightness_counter==0) && (counter==32))    row_counter <= 0;
				//BRIGHTNESSMODE row change
				else if ((size==16) && (counter==32))                          row_counter <= row_counter+1;
				else if ((size==8) && (counter==16))                           row_counter <= row_counter+1;
				else if ((size==4) && (counter==8))                            row_counter <= row_counter+1;
			end
			CORRELATION:begin
				//correlation block finished
				if((addr!=0) && (counter==5) && (cross_direct==1)) row_counter<=row_counter+1;
			end
		endcase
	end

	// ( K )
	//Pooling_start
	always@(posedge clk) begin
		if(state==JUDGECOMPUTE)begin
			Pooling_start<=0;
		end
		if(state==POOLINGMODE)begin
			//pooling finished
			if      ((col_counter==7) && (row_counter==7) && (size==16) && (counter==5)) Pooling_start <= 0;
			else if ((col_counter==3) && (row_counter==3) && (size==8) && (counter==5))  Pooling_start <= 0;
			//pooling change the next start point to new block row
			else if ((col_counter==7) && (size==16) && (counter==2)) Pooling_start <= Pooling_start + size + 2;
			else if ((col_counter==3) && (size==8) && (counter==2))  Pooling_start <= Pooling_start + size + 2;
			//pooling change the next start point (block column change) 
			else if (counter==2) Pooling_start<=Pooling_start+2;
		end
	end

	// ( L )
	//Pooling_new_pos (the address to store pooled pixel)
	always@(posedge clk) begin
		if(state==JUDGECOMPUTE)begin
			Pooling_new_pos <= 0;
		end
		if(state==POOLINGMODE)begin
			//pooling finished
			if      ((col_counter==7) && (row_counter==7) && (size==16) && (counter==5)) Pooling_new_pos <= 0;
			else if ((col_counter==3) && (row_counter==3) && (size==8) && (counter==5))  Pooling_new_pos <= 0;
			//pooling small block finished, and new position add one (the address of pooled image's pixel)
			else if (counter==5) Pooling_new_pos <= Pooling_new_pos+1;
		end
	end
	
	// ( M )
	//Swap_array (TODO)
	always@(posedge clk) begin
		if(state==FLIPMODE)begin
			Swap_array[0]  <= data_out_mem_wire;
			Swap_array[1]  <= Swap_array[0];
			Swap_array[2]  <= Swap_array[1];
			Swap_array[3]  <= Swap_array[2];
			Swap_array[4]  <= Swap_array[3];
			Swap_array[5]  <= Swap_array[4];
			Swap_array[6]  <= Swap_array[5];
			Swap_array[7]  <= Swap_array[6];
			Swap_array[8]  <= Swap_array[7];
			Swap_array[9]  <= Swap_array[8];
			Swap_array[10] <= Swap_array[9];
			Swap_array[11] <= Swap_array[10];
			Swap_array[12] <= Swap_array[11];
			Swap_array[13] <= Swap_array[12];
			Swap_array[14] <= Swap_array[13];
			Swap_array[15] <= Swap_array[14];
		end
		if(state==BRIGHTNESSMODE)begin
			Swap_array[0]<=data_out_mem_wire;
			if(Brightness_flag>0) Swap_array[1] <= B1out[1];
			else                  Swap_array[1] <= Swap_array[0];
			if(Brightness_flag>1) Swap_array[2] <= B1out[2];
			else                  Swap_array[2] <= Swap_array[1];
			if(Brightness_flag>2) Swap_array[3] <= B1out[3];
			else                  Swap_array[3] <= Swap_array[2];
			if(Brightness_flag>3) Swap_array[4] <= B1out[4];
			else                  Swap_array[4] <= Swap_array[3];
			if(Brightness_flag>4) Swap_array[5] <= B1out[5];
			else                  Swap_array[5] <= Swap_array[4];
			if(Brightness_flag>5) Swap_array[6] <= B1out[6];
			else                  Swap_array[6] <= Swap_array[5];
			if(Brightness_flag==7)Swap_array[7] <= B1out[7];
			else                  Swap_array[7] <= Swap_array[6];
			Swap_array[8]<= Swap_array[7];
			Swap_array[9]<= Swap_array[8];
			Swap_array[10]<=Swap_array[9];
			Swap_array[11]<=Swap_array[10];
			Swap_array[12]<=Swap_array[11];
			Swap_array[13]<=Swap_array[12];
			Swap_array[14]<=Swap_array[13];
			Swap_array[15]<=Swap_array[14];
		end
		if(state==CORRELATION)begin
			if((addr==0) && (counter==1)) Swap_array[0]<=0;
			else if((addr==0) && (counter==2)) Swap_array[1]<=0;
			else if((addr==0) && (counter==3)) Swap_array[2]<=0;
			else if((addr==0) && (counter==4)) Swap_array[3]<=0;
			else if((addr==0) && (counter==5)) Swap_array[4]<=data_out_mem_wire;
			else if((addr==0) && (counter==6)) Swap_array[5]<=data_out_mem_wire;
			else if((addr==0) && (counter==7)) Swap_array[6]<=0;
			else if((addr==0) && (counter==8)) Swap_array[7]<=data_out_mem_wire;
			else if((addr==0) && (counter==9)) Swap_array[8]<=data_out_mem_wire;

			else if((addr==0) && (counter==11))begin
				Swap_array[0]<=Swap_array[1];
				Swap_array[1]<=Swap_array[2];
				Swap_array[3]<=Swap_array[4];
				Swap_array[4]<=Swap_array[5];
				Swap_array[6]<=Swap_array[7];
				Swap_array[7]<=Swap_array[8];
			end

			//template move
			else if(counter==5)begin
				case(cross_direct)
					2'd0:begin
						Swap_array[0]<=Swap_array[1];
						Swap_array[1]<=Swap_array[2];
						Swap_array[3]<=Swap_array[4];
						Swap_array[4]<=Swap_array[5];
						Swap_array[6]<=Swap_array[7];
						Swap_array[7]<=Swap_array[8];
					end
					2'd1:begin
						Swap_array[0]<=Swap_array[3];
						Swap_array[3]<=Swap_array[6];
						Swap_array[1]<=Swap_array[4];
						Swap_array[4]<=Swap_array[7];
						Swap_array[2]<=Swap_array[5];
						Swap_array[5]<=Swap_array[8];
					end
					2'd2:begin
						Swap_array[2]<=Swap_array[1];
						Swap_array[1]<=Swap_array[0];
						Swap_array[5]<=Swap_array[4];
						Swap_array[4]<=Swap_array[3];
						Swap_array[8]<=Swap_array[7];
						Swap_array[7]<=Swap_array[6];
					end
				endcase
			end

			// need to pick the pixels of right side
			else if (!row_counter[0] && (col_counter!=0)) begin
				if(counter==1)begin
					if( (row_counter==0) || ((col_counter==15) && (size==16)) || ((col_counter==7) && (size==8)) || ((col_counter==3) && (size==4)) ) Swap_array[2]<=0;
					else Swap_array[2]<=data_out_mem_wire;
				end
				if(counter==2)begin
					if( ((col_counter==15) && (size==16)) || ((col_counter==7) && (size==8)) || ((col_counter==3) && (size==4)) )Swap_array[5]<=0;
					else Swap_array[5]<=data_out_mem_wire;
				end
				if(counter==3)begin
					if( ((col_counter==15) && (size==16)) || ((col_counter==7) && (size==8)) || ((col_counter==3) && (size==4)) )Swap_array[8]<=0;
					else Swap_array[8]<=data_out_mem_wire;
				end
			end
			// need to pick the pixels of left side
			else if (  row_counter[0] && ( ((col_counter!=15) && (size==16)) || ((col_counter!=7) && (size==8)) || ((col_counter!=3) && (size==4)) ) ) begin
				if(counter==1)begin
					if(col_counter==0) Swap_array[0]<=0;
					else Swap_array[0]<=data_out_mem_wire;
				end
				if(counter==2)begin
					if(col_counter==0)Swap_array[3]<=0;
					else Swap_array[3]<=data_out_mem_wire;
				end
				if(counter==3)begin
					if( (col_counter==0) || ((row_counter==15) && (size==16)) || ((row_counter==7) && (size==8)) || ((row_counter==3) && (size==4)) )Swap_array[6]<=0;
					else Swap_array[6]<=data_out_mem_wire;
				end
			end
			// need to pick the pixels of down side
			else if ( (!row_counter[0] && (col_counter==0)) || (row_counter[0] && ( ((col_counter==15) && (size==16)) || ((col_counter==7) && (size==8)) || ((col_counter==3) && (size==4)) ) ) ) begin
				if(counter==1)begin
					if((col_counter==0) || ((row_counter==15) && (size==16)) || ((row_counter==7) && (size==8)) || ((row_counter==3) && (size==4))) Swap_array[6]<=0;
					else Swap_array[6]<=data_out_mem_wire;
				end
				if(counter==2)begin
					if( ((row_counter==15) && (size==16)) || ((row_counter==7) && (size==8)) || ((row_counter==3) && (size==4)) )Swap_array[7]<=0;
					else Swap_array[7]<=data_out_mem_wire;
				end
				if(counter==3)begin
					if( ((col_counter==15) && (size==16)) || ((col_counter==7) && (size==8)) || ((col_counter==3) && (size==4)) )Swap_array[8]<=0;
					else Swap_array[8]<=data_out_mem_wire;
				end
			end
		end
	end
	
	// ( N )
	//cross_direct
	always@(posedge clk) begin
		case(state)
			RESET: cross_direct<=0;
			CORRELATION:begin
				if      ( (addr!=0) && (counter==5) && (cross_direct==0) && ( ((col_counter==14) && (size==16)) || ((col_counter==6) && (size==8)) || ((col_counter==2) && (size==4)) ) ) cross_direct<=1;
				//cross_correlation at the end
				else if ( (addr==13) && (counter==5) && (cross_direct==2) && (size==4))   cross_direct<=3;
				else if ( (addr==57) && (counter==5) && (cross_direct==2) && (size==8))   cross_direct<=3;
				else if ( (addr==241) && (counter==5) && (cross_direct==2) && (size==16)) cross_direct<=3;
				
				else if ( (addr!=0) && (counter==5) && (cross_direct==2) && (col_counter==1) ) cross_direct<=1;
				else if ( (addr!=0) && (counter==5) && (cross_direct==1) && (col_counter==0)) cross_direct<=0;
				else if ( (addr!=0) && (counter==5) && (cross_direct==1)) cross_direct<=2;
				

			end
		endcase
	end

	// ( O )
	//cor_reg
	always@(posedge clk) begin
		case(state)
			CORRELATION:begin
				if( (addr==0) && (counter==10) ) cor_reg<=cor_out;
				else if ( (addr!=0) && (counter==4) ) cor_reg<=cor_out;
			end
		endcase
	end
	
	// ( P )
	//cor_max
	always@(posedge clk) begin
		case(state)
			CORRELATION:begin
				if( (addr==0) && (counter==11) )begin
					cor_max<=cor_reg;
					x_max<=row_counter;
					y_max<=col_counter;
					addr_max<=addr;
				end
				else if ( (addr!=0) && (counter==5) ) begin
					if(cor_max[34] && !cor_reg[34])begin
						cor_max<=cor_reg;
						x_max<=row_counter;
						y_max<=col_counter;
						addr_max<=addr;
					end
					if(!cor_max[34] && !cor_reg[34] && (cor_max<cor_reg) )begin
						cor_max<=cor_reg;
						x_max<=row_counter;
						y_max<=col_counter;
						addr_max<=addr;
					end
					if(cor_max[34] && cor_reg[34] && (cor_max[33:0]<cor_reg[33:0]) )begin
						cor_max<=cor_reg;
						x_max<=row_counter;
						y_max<=col_counter;
						addr_max<=addr;
					end
				end
			end
		endcase
	end

	always@(posedge clk)begin
		if(state==OUTPUTMODE)begin
			if((counter==0) && (size==16))begin
				if(x_max==0 && y_max==0)begin
					match_addr[1]<=addr_max;
					match_addr[2]<=addr_max+1;
					match_addr[3]<=addr_max+size;
					match_addr[4]<=addr_max+size+1;
					matchnum<=5;
				end
				if(x_max==15 && y_max==0)begin
					match_addr[1]<=addr_max-size;
					match_addr[2]<=addr_max-size+1;
					match_addr[3]<=addr_max;
					match_addr[4]<=addr_max+1;
					matchnum<=5;
				end
				if(x_max==0 && y_max==15)begin
					match_addr[1]<=addr_max-1;
					match_addr[2]<=addr_max;
					match_addr[3]<=addr_max+size-1;
					match_addr[4]<=addr_max+size;
					matchnum<=5;
				end
				if(x_max==15 && y_max==15)begin
					match_addr[1]<=addr_max-size-1;
					match_addr[2]<=addr_max-size;
					match_addr[3]<=addr_max-1;
					match_addr[4]<=addr_max;
					matchnum<=5;
				end

				if(x_max==0 && (y_max>0 && y_max<15) )begin
					match_addr[1]<=addr_max-1;
					match_addr[2]<=addr_max;
					match_addr[3]<=addr_max+1;
					match_addr[4]<=addr_max+size-1;
					match_addr[5]<=addr_max+size;
					match_addr[6]<=addr_max+size+1;
					matchnum<=7;
				end
				if(x_max==15 && (y_max>0 && y_max<15) )begin
					match_addr[1]<=addr_max-size-1;
					match_addr[2]<=addr_max-size;
					match_addr[3]<=addr_max-size+1;
					match_addr[4]<=addr_max-1;
					match_addr[5]<=addr_max;
					match_addr[6]<=addr_max+1;
					matchnum<=7;
				end
				if( (x_max>0 && x_max<15) && y_max==0)begin
					match_addr[1]<=addr_max-size;
					match_addr[2]<=addr_max-size+1;
					match_addr[3]<=addr_max;
					match_addr[4]<=addr_max+1;
					match_addr[5]<=addr_max+size;
					match_addr[6]<=addr_max+size+1;
					matchnum<=7;
				end
				if( (x_max>0 && x_max<15) && y_max==15)begin
					match_addr[1]<=addr_max-size-1;
					match_addr[2]<=addr_max-size;
					match_addr[3]<=addr_max-1;
					match_addr[4]<=addr_max;
					match_addr[5]<=addr_max+size-1;
					match_addr[6]<=addr_max+size;
					matchnum<=7;
				end
				if( (x_max>0 && x_max<15) && (y_max>0 && y_max<15) )begin
					match_addr[1]<=addr_max-size-1;
					match_addr[2]<=addr_max-size;
					match_addr[3]<=addr_max-size+1;
					match_addr[4]<=addr_max-1;
					match_addr[5]<=addr_max;
					match_addr[6]<=addr_max+1;
					match_addr[7]<=addr_max+size-1;
					match_addr[8]<=addr_max+size;
					match_addr[9]<=addr_max+size+1;
					matchnum<=10;
				end
			end
			if((counter==0) && (size==8))begin
				if(x_max==0 && y_max==0)begin
					match_addr[1]<=addr_max;
					match_addr[2]<=addr_max+1;
					match_addr[3]<=addr_max+size;
					match_addr[4]<=addr_max+size+1;
					matchnum<=5;
				end
				if(x_max==7 && y_max==0)begin
					match_addr[1]<=addr_max-size;
					match_addr[2]<=addr_max-size+1;
					match_addr[3]<=addr_max;
					match_addr[4]<=addr_max+1;
					matchnum<=5;
				end
				if(x_max==0 && y_max==7)begin
					match_addr[1]<=addr_max-1;
					match_addr[2]<=addr_max;
					match_addr[3]<=addr_max+size-1;
					match_addr[4]<=addr_max+size;
					matchnum<=5;
				end
				if(x_max==7 && y_max==7)begin
					match_addr[1]<=addr_max-size-1;
					match_addr[2]<=addr_max-size;
					match_addr[3]<=addr_max-1;
					match_addr[4]<=addr_max;
					matchnum<=5;
				end

				if(x_max==0 && (y_max>0 && y_max<7) )begin
					match_addr[1]<=addr_max-1;
					match_addr[2]<=addr_max;
					match_addr[3]<=addr_max+1;
					match_addr[4]<=addr_max+size-1;
					match_addr[5]<=addr_max+size;
					match_addr[6]<=addr_max+size+1;
					matchnum<=7;
				end
				if(x_max==7 && (y_max>0 && y_max<7) )begin
					match_addr[1]<=addr_max-size-1;
					match_addr[2]<=addr_max-size;
					match_addr[3]<=addr_max-size+1;
					match_addr[4]<=addr_max-1;
					match_addr[5]<=addr_max;
					match_addr[6]<=addr_max+1;
					matchnum<=7;
				end
				if( (x_max>0 && x_max<7) && y_max==0)begin
					match_addr[1]<=addr_max-size;
					match_addr[2]<=addr_max-size+1;
					match_addr[3]<=addr_max;
					match_addr[4]<=addr_max+1;
					match_addr[5]<=addr_max+size;
					match_addr[6]<=addr_max+size+1;
					matchnum<=7;
				end
				if( (x_max>0 && x_max<7) && y_max==7)begin
					match_addr[1]<=addr_max-size-1;
					match_addr[2]<=addr_max-size;
					match_addr[3]<=addr_max-1;
					match_addr[4]<=addr_max;
					match_addr[5]<=addr_max+size-1;
					match_addr[6]<=addr_max+size;
					matchnum<=7;
				end
				if( (x_max>0 && x_max<7) && (y_max>0 && y_max<7) )begin
					match_addr[1]<=addr_max-size-1;
					match_addr[2]<=addr_max-size;
					match_addr[3]<=addr_max-size+1;
					match_addr[4]<=addr_max-1;
					match_addr[5]<=addr_max;
					match_addr[6]<=addr_max+1;
					match_addr[7]<=addr_max+size-1;
					match_addr[8]<=addr_max+size;
					match_addr[9]<=addr_max+size+1;
					matchnum<=10;
				end
			end
			if((counter==0) && (size==4))begin
				if(x_max==0 && y_max==0)begin
					match_addr[1]<=addr_max;
					match_addr[2]<=addr_max+1;
					match_addr[3]<=addr_max+size;
					match_addr[4]<=addr_max+size+1;
					matchnum<=5;
				end
				if(x_max==3 && y_max==0)begin
					match_addr[1]<=addr_max-size;
					match_addr[2]<=addr_max-size+1;
					match_addr[3]<=addr_max;
					match_addr[4]<=addr_max+1;
					matchnum<=5;
				end
				if(x_max==0 && y_max==3)begin
					match_addr[1]<=addr_max-1;
					match_addr[2]<=addr_max;
					match_addr[3]<=addr_max+size-1;
					match_addr[4]<=addr_max+size;
					matchnum<=5;
				end
				if(x_max==3 && y_max==3)begin
					match_addr[1]<=addr_max-size-1;
					match_addr[2]<=addr_max-size;
					match_addr[3]<=addr_max-1;
					match_addr[4]<=addr_max;
					matchnum<=5;
				end

				if(x_max==0 && (y_max>0 && y_max<3) )begin
					match_addr[1]<=addr_max-1;
					match_addr[2]<=addr_max;
					match_addr[3]<=addr_max+1;
					match_addr[4]<=addr_max+size-1;
					match_addr[5]<=addr_max+size;
					match_addr[6]<=addr_max+size+1;
					matchnum<=7;
				end
				if(x_max==3 && (y_max>0 && y_max<3) )begin
					match_addr[1]<=addr_max-size-1;
					match_addr[2]<=addr_max-size;
					match_addr[3]<=addr_max-size+1;
					match_addr[4]<=addr_max-1;
					match_addr[5]<=addr_max;
					match_addr[6]<=addr_max+1;
					matchnum<=7;
				end
				if( (x_max>0 && x_max<3) && y_max==0)begin
					match_addr[1]<=addr_max-size;
					match_addr[2]<=addr_max-size+1;
					match_addr[3]<=addr_max;
					match_addr[4]<=addr_max+1;
					match_addr[5]<=addr_max+size;
					match_addr[6]<=addr_max+size+1;
					matchnum<=7;
				end
				if( (x_max>0 && x_max<3) && y_max==3)begin
					match_addr[1]<=addr_max-size-1;
					match_addr[2]<=addr_max-size;
					match_addr[3]<=addr_max-1;
					match_addr[4]<=addr_max;
					match_addr[5]<=addr_max+size-1;
					match_addr[6]<=addr_max+size;
					matchnum<=7;
				end
				if( (x_max>0 && x_max<3) && (y_max>0 && y_max<3) )begin
					match_addr[1]<=addr_max-size-1;
					match_addr[2]<=addr_max-size;
					match_addr[3]<=addr_max-size+1;
					match_addr[4]<=addr_max-1;
					match_addr[5]<=addr_max;
					match_addr[6]<=addr_max+1;
					match_addr[7]<=addr_max+size-1;
					match_addr[8]<=addr_max+size;
					match_addr[9]<=addr_max+size+1;
					matchnum<=10;
				end
			end
		end
	end

	always@(posedge clk)begin
		case(state)
			RESET:brightness_counter<=0;
			BRIGHTNESSMODE:begin
				if(counter==32)brightness_counter<=brightness_counter+1;
			end
		endcase
	end

//========== Sub module ==========

//SRAM
RAISH image_SRAM_16bits(
   .Q(data_out_mem_wire),
   .CLK(clk),
   .CEN(cen_wire),
   .WEN(wen_wire),
   .A(address1),
   .D(data_into_mem_wire),
   .OEN(oen_wire)
);

// ( 1 )
//Pooling_cmp_out
always@(*)begin
	if(Pooling_cmp[15] && !Pooling_store[15]) Pooling_cmp_out=Pooling_store;
	else if(!Pooling_cmp[15] && Pooling_store[15]) Pooling_cmp_out=Pooling_cmp;
	else if(!Pooling_cmp[15] && !Pooling_store[15]) begin
		if (Pooling_cmp > Pooling_store) Pooling_cmp_out=Pooling_cmp;
		else  Pooling_cmp_out=Pooling_store;
	end
	else begin
		if (Pooling_cmp[14:0] > Pooling_store[14:0]) Pooling_cmp_out=Pooling_cmp;
		else  Pooling_cmp_out=Pooling_store;
	end
end

// ( 2 )
//address1
always@(*)begin
	if(in_valid)begin
		//write pixel into memory
		address1=addr;
	end
	else begin
		case(state)
			POOLINGMODE:begin
				//read from memory
				if(counter<4) address1=addr;
				//write pooling max number into memory
				else if(counter==5) address1=Pooling_new_pos;
				//no input/output
				else address1=0;
			end
			FLIPMODE:begin
				address1=addr;
			end
			BRIGHTNESSMODE:begin
				address1=addr;
			end
			CORRELATION:begin
				///address1=addr;/////////////////////////////////////////////////////////////////////////////
				if(addr==0)begin
					//read
					if     (counter==0)address1=0;
					else if(counter==1)address1=0;
					else if(counter==2)address1=0;
					else if(counter==3)address1=0;
					else if(counter==4)address1=addr;
					else if(counter==5)address1=addr+1;
					else if(counter==6)address1=0;
					else if(counter==7)address1=addr+size;
					else if(counter==8)address1=addr+size+1;
					//write
					else if(counter==11)address1=addr;
					else address1=0;
				end
				else begin
					// need to pick the pixels of right side
					if (!row_counter[0] && (col_counter!=0)) begin
						if(counter==0)begin
							if( (row_counter==0) || ((col_counter==15) && (size==16)) || ((col_counter==7) && (size==8)) || ((col_counter==3) && (size==4)) ) address1=0;
							else address1=addr-size+1;
						end
						else if(counter==1)begin
							if( ((col_counter==15) && (size==16)) || ((col_counter==7) && (size==8)) || ((col_counter==3) && (size==4)) ) address1=0;
							else address1=addr+1;
						end
						else if(counter==2)begin
							if( ((col_counter==15) && (size==16)) || ((col_counter==7) && (size==8)) || ((col_counter==3) && (size==4)) ) address1=0;
							else address1=addr+size+1;
						end
						else address1=addr;
					end
					// need to pick the pixels of left side
					else if (  row_counter[0] && ( ((col_counter!=15) && (size==16)) || ((col_counter!=7) && (size==8)) || ((col_counter!=3) && (size==4)) ) ) begin
						if(counter==0)begin
							if(col_counter==0) address1=0;
							else address1=addr-size-1;
						end
						else if(counter==1)begin
							if(col_counter==0) address1=0;
							else address1=addr-1;
						end
						else if(counter==2)begin
							if( ((row_counter==15) && (size==16)) || ((row_counter==7) && (size==8)) || ((row_counter==3) && (size==4)) ) address1=0;
							else address1=addr+size-1;
						end
						else address1=addr;
					end
					// need to pick the pixels of down side
					else if ( (!row_counter[0] && (col_counter==0)) || (row_counter[0] && ( ((col_counter==15) && (size==16)) || ((col_counter==7) && (size==8)) || ((col_counter==3) && (size==4)) ) ) ) begin
						if(counter==0)begin
							if(col_counter==0) address1=0;
							else address1=addr+size-1;
						end
						else if(counter==1)begin
							if( ((row_counter==15) && (size==16)) || ((row_counter==7) && (size==8)) || ((row_counter==3) && (size==4)) ) address1=0;
							else address1=addr+size;
						end
						else if(counter==2)begin
							if( ((col_counter==15) && (size==16)) || ((col_counter==7) && (size==8)) || ((col_counter==3) && (size==4)) ) address1=0;
							else address1=addr+size+1;
						end
						else address1=addr;
					end
					else begin
						address1=0;
					end
				end
			end
			default:begin
				address1=0;
			end
		endcase
	end
end

// ( 3 )
//data_into_mem_wire (TODO)
always@(*)begin
	if(in_valid)begin
		// write image data into memory
		data_into_mem_wire=image;
	end
	else begin
		case(state)
			POOLINGMODE:begin
				// write pooling max number into memory
				if   (counter==5)data_into_mem_wire=Pooling_cmp_out;
				// no input
				else data_into_mem_wire=0;
			end
			FLIPMODE:begin
				// write inverse pixel into memory
				if      ((counter>16) && (size==16)) data_into_mem_wire = Swap_array[15];
				else if ((counter>8) && (size==8))   data_into_mem_wire = Swap_array[7];
				else if ((counter>4) && (size==4))   data_into_mem_wire = Swap_array[3];
				// no input
				else    data_into_mem_wire=0;
			end
			BRIGHTNESSMODE:begin
				// write inverse pixel into memory
				if      (counter>16) data_into_mem_wire = Swap_array[15];
				// no input
				else    data_into_mem_wire=0;
			end
			default:data_into_mem_wire=0;
		endcase
	end
end


//( 4 )
//cen_wire,wen_wire,oen_wire (TODO)
always@(*)begin
	if(in_valid)begin
		//W
		cen_wire='b0;
		wen_wire='b0;
		oen_wire='b0;
	end
	else begin
		case(state)
			POOLINGMODE:begin
				if(Pooling_flag==0)begin
					//Z
					cen_wire='b1;
					wen_wire='b0;
					oen_wire='b0;
				end
				else if(counter==5)begin
					//W
					cen_wire='b0;
					wen_wire='b0;
					oen_wire='b0;
				end
				else if(counter==4)begin
					//Z
					cen_wire='b1;
					wen_wire='b0;
					oen_wire='b0;
				end
				else begin
					//R
					cen_wire='b0;
					wen_wire='b1;
					oen_wire='b0;
				end
			end
			FLIPMODE:begin
				if(flip_flag==0)begin
					//Z
					cen_wire='b1;
					wen_wire='b0;
					oen_wire='b0;
				end
				else if(size=='d16)begin
					if(counter<16)begin
						//R
						cen_wire='b0;
						wen_wire='b1;
						oen_wire='b0;
					end
					else if(counter>16)begin
						//W
						cen_wire='b0;
						wen_wire='b0;
						oen_wire='b0;
					end
					else begin
						//Z
						cen_wire='b1;
						wen_wire='b0;
						oen_wire='b0;
					end
				end
				else if(size=='d8)begin
					if(counter<8)begin
						//R
						cen_wire='b0;
						wen_wire='b1;
						oen_wire='b0;
					end
					else if(counter>8)begin
						//W
						cen_wire='b0;
						wen_wire='b0;
						oen_wire='b0;
					end
					else begin
						//Z
						cen_wire='b1;
						wen_wire='b0;
						oen_wire='b0;
					end
				end
				else begin
					if(counter<4)begin
						//R
						cen_wire='b0;
						wen_wire='b1;
						oen_wire='b0;
					end
					else if(counter>4)begin
						//W
						cen_wire='b0;
						wen_wire='b0;
						oen_wire='b0;
					end
					else begin
						//Z
						cen_wire='b1;
						wen_wire='b0;
						oen_wire='b0;
					end
				end
			end
			BRIGHTNESSMODE:begin
				if(Brightness_flag==0)begin
					//Z
					cen_wire='b1;
					wen_wire='b0;
					oen_wire='b0;
				end
				else if(counter<16)begin
					//R
					cen_wire='b0;
					wen_wire='b1;
					oen_wire='b0;
				end
				else if(counter>16)begin
					//W
					cen_wire='b0;
					wen_wire='b0;
					oen_wire='b0;
				end
				else begin
					//Z
					cen_wire='b1;
					wen_wire='b0;
					oen_wire='b0;
				end
			end
			CORRELATION:begin
				if((addr==0) && (counter<9))begin
					//R
					cen_wire='b0;
					wen_wire='b1;
					oen_wire='b0;
				end
				/* else if((addr==0) && (counter==11))begin
					//W
					cen_wire='b0;
					wen_wire='b0;
					oen_wire='b0;
				end */
				else if((addr!=0) && (counter<3))begin
					//R
					cen_wire='b0;
					wen_wire='b1;
					oen_wire='b0;
				end
				/* else if((addr!=0) && (counter==5))begin
					//W
					cen_wire='b0;
					wen_wire='b0;
					oen_wire='b0;
				end */
				else begin
					//Z
					cen_wire='b1;
					wen_wire='b0;
					oen_wire='b0;
				end
			end
			default:begin
				//Z
				cen_wire='b1;
				wen_wire='b0;
				oen_wire='b0;
			end
		endcase
	end
end



RAISH_2 image_SRAM_35bits(
   .Q(data_out_mem_wire_2),
   .CLK(clk),
   .CEN(cen_wire_2),
   .WEN(wen_wire_2),
   .A(address2),
   .D(data_into_mem_wire_2),
   .OEN(oen_wire_2)
);

//( 5 )
//address2
always@(*)begin
	case(state)
		CORRELATION:begin
			if( (addr==0) && (counter==11) ) address2=addr;
			else if ( (addr!=0) && (counter==5) ) address2=addr;
			else address2=0;
		end
		OUTPUTMODE:begin
			address2=addr;
		end
		default:begin
			address2=0;
		end
	endcase
end

//( 6 )
//data_into_mem_wire_2
always@(*)begin
	case(state)
		CORRELATION:begin
			if( (addr==0) && (counter==11) ) data_into_mem_wire_2=cor_reg;
			else if ( (addr!=0) && (counter==5) ) data_into_mem_wire_2=cor_reg;
			else data_into_mem_wire_2=0;
		end
		default:begin
			data_into_mem_wire_2=0;
		end
	endcase
end


//( 7 )
//cen_wire_2,wen_wire_2,oen_wire_2
always@(*)begin
	case(state)
		CORRELATION:begin
			if( (addr==0) && (counter==11) )begin
				//W
				cen_wire_2='b0;
				wen_wire_2='b0;
				oen_wire_2='b0;
			end
			else if ( (addr!=0) && (counter==5) )begin
				//W
				cen_wire_2='b0;
				wen_wire_2='b0;
				oen_wire_2='b0;
			end
			else begin
				//Z
				cen_wire_2='b1;
				wen_wire_2='b0;
				oen_wire_2='b0;
			end
		end
		OUTPUTMODE:begin
			if( (addr<256 && size==16) || (addr<64 && size==8) || (addr<16 && size==4) )begin
				//R
				cen_wire_2='b0;
				wen_wire_2='b1;
				oen_wire_2='b0;
			end
			else begin
				//Z
				cen_wire_2='b1;
				wen_wire_2='b0;
				oen_wire_2='b0;
			end
		end
		default:begin
			//Z
			cen_wire_2='b1;
			wen_wire_2='b0;
			oen_wire_2='b0;
		end
	endcase
end





genvar i;
generate
	for(i=1;i<8;i=i+1)begin
		Brightness_Adjustor B1(.input_pixel(B1in[i]),.output_pixel(B1out[i]));
	end
endgenerate


//B1in[1:7]
always@(*)begin
	case(Brightness_flag)
		'd0:begin
			B1in[1]=0;
			B1in[2]=0;
			B1in[3]=0;
			B1in[4]=0;
			B1in[5]=0;
			B1in[6]=0;
			B1in[7]=0;
		end
		'd1:begin
			B1in[1]=Swap_array[0];
			B1in[2]=0;
			B1in[3]=0;
			B1in[4]=0;
			B1in[5]=0;
			B1in[6]=0;
			B1in[7]=0;
		end
		'd2:begin
			B1in[1]=Swap_array[0];
			B1in[2]=Swap_array[1];
			B1in[3]=0;
			B1in[4]=0;
			B1in[5]=0;
			B1in[6]=0;
			B1in[7]=0;
		end
		'd3:begin
			B1in[1]=Swap_array[0];
			B1in[2]=Swap_array[1];
			B1in[3]=Swap_array[2];
			B1in[4]=0;
			B1in[5]=0;
			B1in[6]=0;
			B1in[7]=0;
		end
		'd4:begin
			B1in[1]=Swap_array[0];
			B1in[2]=Swap_array[1];
			B1in[3]=Swap_array[2];
			B1in[4]=Swap_array[3];
			B1in[5]=0;
			B1in[6]=0;
			B1in[7]=0;
		end
		'd5:begin
			B1in[1]=Swap_array[0];
			B1in[2]=Swap_array[1];
			B1in[3]=Swap_array[2];
			B1in[4]=Swap_array[3];
			B1in[5]=Swap_array[4];
			B1in[6]=0;
			B1in[7]=0;
		end
		'd6:begin
			B1in[1]=Swap_array[0];
			B1in[2]=Swap_array[1];
			B1in[3]=Swap_array[2];
			B1in[4]=Swap_array[3];
			B1in[5]=Swap_array[4];
			B1in[6]=Swap_array[5];
			B1in[7]=0;
		end
		'd7:begin
			B1in[1]=Swap_array[0];
			B1in[2]=Swap_array[1];
			B1in[3]=Swap_array[2];
			B1in[4]=Swap_array[3];
			B1in[5]=Swap_array[4];
			B1in[6]=Swap_array[5];
			B1in[7]=Swap_array[6];
		end
	endcase
end

Cross_Correlation C1(.in0(Swap_array[0]),.in1(Swap_array[1]),.in2(Swap_array[2]),.in3(Swap_array[3]),.in4(Swap_array[4]),
					 .in5(Swap_array[5]),.in6(Swap_array[6]),.in7(Swap_array[7]),.in8(Swap_array[8]),
					 .p0(template_store[0]),.p1(template_store[1]),.p2(template_store[2]),.p3(template_store[3]),.p4(template_store[4]),
					 .p5(template_store[5]),.p6(template_store[6]),.p7(template_store[7]),.p8(template_store[8]),.out(cor_out));


endmodule


module Brightness_Adjustor(input_pixel,output_pixel);

	input [15:0] input_pixel;
	output reg [15:0] output_pixel;

	always@(*)begin
		if(input_pixel[15]) output_pixel={1'b1,input_pixel[15:1]}+16'd50;
		else output_pixel={1'b0,input_pixel[15:1]}+16'd50;
	end

endmodule


module Cross_Correlation(in0,in1,in2,in3,in4,in5,in6,in7,in8,p0,p1,p2,p3,p4,p5,p6,p7,p8,out);

	input signed [15:0]in0,in1,in2,in3,in4,in5,in6,in7,in8;
	input signed [15:0]p0,p1,p2,p3,p4,p5,p6,p7,p8;
	output reg signed[34:0]out;
	reg signed[31:0] m0,m1,m2,m3,m4,m5,m6,m7,m8;
	reg signed[34:0] a0,a1,a2,a3,a4;

	/* assign m0=in0*p0;
	assign m1=in1*p1;
	assign m2=in2*p2;
	assign m3=in3*p3;
	assign m4=in4*p4;
	assign m5=in5*p5;
	assign m6=in6*p6;
	assign m7=in7*p7;
	assign m8=in8*p8;

	assign a0={m1[31],m1[31],m1[31],m1}+{m4[31],m4[31],m4[31],m4};
	assign a1={m0[31],m0[31],m0[31],m0}+{m3[31],m3[31],m3[31],m3};
	assign a2={m2[31],m2[31],m2[31],m2}+{m5[31],m5[31],m5[31],m5};
	assign a3={m6[31],m6[31],m6[31],m6}+{m8[31],m8[31],m8[31],m8};
	assign a4={m7[31],m7[31],m7[31],m7};

	assign out=(((a3+a4)+(a1+a2))+a0); */

	always@(*)begin
		m0=in0*p0;
		m1=in1*p1;
		m2=in2*p2;
		m3=in3*p3;
		m4=in4*p4;
		m5=in5*p5;
		m6=in6*p6;
		m7=in7*p7;
		m8=in8*p8;

		a0={m1[31],m1[31],m1[31],m1}+{m4[31],m4[31],m4[31],m4};
		a1={m0[31],m0[31],m0[31],m0}+{m3[31],m3[31],m3[31],m3};
		a2={m2[31],m2[31],m2[31],m2}+{m5[31],m5[31],m5[31],m5};
		a3={m6[31],m6[31],m6[31],m6}+{m8[31],m8[31],m8[31],m8};
		a4={m7[31],m7[31],m7[31],m7};

		out=(((a3+a4)+(a1+a2))+a0);
	end

endmodule