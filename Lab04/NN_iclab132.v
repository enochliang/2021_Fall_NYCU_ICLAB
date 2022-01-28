//synopsys translate_off
`include "/usr/synthesis/dw/sim_ver/DW_fp_mult.v"
`include "/usr/synthesis/dw/sim_ver/DW_fp_add.v"
`include "/usr/synthesis/dw/sim_ver/DW_fp_sub.v"
`include "/usr/synthesis/dw/sim_ver/DW_fp_cmp.v"
//synopsys translate_on

module NN(
	// Input signals
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
	// Output signals
	out_valid,
	out
);

//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------

// IEEE floating point paramenters
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch = 2;

// State parameter
parameter [1:0]RESET=2'b00;
parameter [1:0]INPUTWEIGHT=2'b01;
parameter [1:0]INPUTDATA=2'b10;
parameter [1:0]COMPUTE=2'b11;

//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION
//---------------------------------------------------------------------
input  clk, rst_n, in_valid_d, in_valid_t, in_valid_w1, in_valid_w2;
input [inst_sig_width+inst_exp_width:0] data_point, target;
input [inst_sig_width+inst_exp_width:0] weight1, weight2;
output reg	out_valid;
output reg [inst_sig_width+inst_exp_width:0] out;

//---------------------------------------------------------------------
//   WIRE AND REG DECLARATION
//---------------------------------------------------------------------
reg [inst_sig_width+inst_exp_width:0]data_point_array[0:3]; //(A)
reg [inst_sig_width+inst_exp_width:0]target_store; //(B)
reg [inst_sig_width+inst_exp_width:0]weight1_array[0:11]; //(C)
reg [inst_sig_width+inst_exp_width:0]weight2_array[0:2]; //(D)
reg [inst_sig_width+inst_exp_width:0]Eta; //(E)

reg [inst_sig_width+inst_exp_width:0]weightMdata[0:3];//0 1 2 (0)

reg [inst_sig_width+inst_exp_width:0]weightMdata_2[0:1];//1 2 3 (1)

reg [inst_sig_width+inst_exp_width:0]y1,g_diff;//2 3 4 (2)

reg [inst_sig_width+inst_exp_width:0]EtaMdata[0:3];//3 (3)

reg [inst_sig_width+inst_exp_width:0]weight2My1;//3 4 5 (4)
reg [inst_sig_width+inst_exp_width:0]weight2Mg_diff[0:4];//3 4 5 6 7 8 9(5)
reg [inst_sig_width+inst_exp_width:0]gMEta[0:4];//3 4 5 6 7 8 9(6)
reg [inst_sig_width+inst_exp_width:0]y2;//4 5 6(7)
reg [inst_sig_width+inst_exp_width:0]delta2;//7 8 9 (8)

reg [inst_sig_width+inst_exp_width:0]delta1,delta2MgMEta;//8 9 10 (9)

reg [inst_sig_width+inst_exp_width:0]delta1MdataMEta[0:3];//9 10 11 (10)


reg [3:0]counter;

reg [7:0]round_counter;
reg [4:0]epoch_counter;
reg [2:0]four_epoch_flag;

reg in_state;
reg [1:0]state,next_state;
// CL REG
reg [inst_sig_width+inst_exp_width:0]Mult_A_a,Mult_A_b,Mult_B_a,Mult_B_b,Mult_C_a,Mult_C_b,Mult_D_a,Mult_D_b;
wire [inst_sig_width+inst_exp_width:0]Mult_A_z,Mult_B_z,Mult_C_z,Mult_D_z;

wire [inst_sig_width+inst_exp_width:0]Add_A_z,Add_B_z,Add_C_z,Add_D_z;

wire [inst_sig_width+inst_exp_width:0]g_out,g_diff_out;

reg [inst_sig_width+inst_exp_width:0]Mult_E_a,Mult_E_b,Mult_F_a,Mult_F_b,Mult_G_a,Mult_G_b;
wire [inst_sig_width+inst_exp_width:0]Mult_E_z,Mult_F_z,Mult_G_z;

reg [inst_sig_width+inst_exp_width:0]Sub_E_a,Sub_E_b,Sub_F_a;
wire [inst_sig_width+inst_exp_width:0]Sub_E_z,Sub_F_z;

reg [inst_sig_width+inst_exp_width:0] Sub_A_a,Sub_B_a,Sub_C_a,Sub_D_a;
wire [inst_sig_width+inst_exp_width:0] Sub_A_z,Sub_B_z,Sub_C_z,Sub_D_z;
// integer
integer i;


// SUBMODULE
DW_fp_mult_inst Mult_A(.inst_a(Mult_A_a),.inst_b(Mult_A_b),.z_inst(Mult_A_z));
DW_fp_mult_inst Mult_B(.inst_a(Mult_B_a),.inst_b(Mult_B_b),.z_inst(Mult_B_z));
DW_fp_mult_inst Mult_C(.inst_a(Mult_C_a),.inst_b(Mult_C_b),.z_inst(Mult_C_z));
DW_fp_mult_inst Mult_D(.inst_a(Mult_D_a),.inst_b(Mult_D_b),.z_inst(Mult_D_z));

// (static wiring)
DW_fp_add_inst Add_A(.inst_a(weightMdata[0]),.inst_b(weightMdata[1]),.z_inst(Add_A_z));
DW_fp_add_inst Add_B(.inst_a(weightMdata[2]),.inst_b(weightMdata[3]),.z_inst(Add_B_z));
DW_fp_add_inst Add_C(.inst_a(weightMdata_2[0]),.inst_b(weightMdata_2[1]),.z_inst(Add_C_z));
DW_fp_add_inst Add_D(.inst_a(weight2My1),.inst_b(y2),.z_inst(Add_D_z));

ReLU ReLU1(.in(Add_C_z),.out(g_out));
ReLU_diff ReLU_diff1(.in(Add_C_z),.out(g_diff_out));

DW_fp_mult_inst Mult_E(.inst_a(Mult_E_a),.inst_b(Mult_E_b),.z_inst(Mult_E_z));
DW_fp_mult_inst Mult_F(.inst_a(Mult_F_a),.inst_b(Mult_F_b),.z_inst(Mult_F_z));
DW_fp_mult_inst Mult_G(.inst_a(Mult_G_a),.inst_b(Mult_G_b),.z_inst(Mult_G_z));


DW_fp_sub_inst Sub_A(.inst_a(Sub_A_a),.inst_b(delta1MdataMEta[0]),.z_inst(Sub_A_z));
DW_fp_sub_inst Sub_B(.inst_a(Sub_B_a),.inst_b(delta1MdataMEta[1]),.z_inst(Sub_B_z));
DW_fp_sub_inst Sub_C(.inst_a(Sub_C_a),.inst_b(delta1MdataMEta[2]),.z_inst(Sub_C_z));
DW_fp_sub_inst Sub_D(.inst_a(Sub_D_a),.inst_b(delta1MdataMEta[3]),.z_inst(Sub_D_z));

DW_fp_sub_inst Sub_E(.inst_a(Sub_E_a),.inst_b(Sub_E_b),.z_inst(Sub_E_z));
DW_fp_sub_inst Sub_F(.inst_a(Sub_F_a),.inst_b(delta2MgMEta),.z_inst(Sub_F_z));

// setting up state
always@(negedge rst_n or posedge clk)begin
	if(!rst_n)begin
		state <= RESET;
	end
	else begin
		state <= next_state;
	end
end
// setting up next state(Todo)
always@(*)begin
	if(!rst_n)begin
		next_state = RESET;
	end
	else if(in_valid_w1)begin
		next_state = INPUTWEIGHT;
	end
	else if(in_valid_d)begin
		if (counter==3)begin
			next_state = COMPUTE;
		end
		else begin
			next_state = INPUTDATA;
		end
	end
	else if((state == COMPUTE) && counter=='d13)begin
		next_state = RESET;
	end
	else begin
		next_state = state;
	end
end
// out
always@(negedge rst_n or posedge clk)begin
	if(!rst_n)begin
		out<=0;
	end
	else begin
		case(state)
			RESET:begin
				out<=0;
			end
			COMPUTE:begin
				if(counter=='d12)begin
					out<=y2;
				end
				else if(counter=='d13)begin
					out<=0;
				end
			end
		endcase
	end
end
// out_valid
always@(negedge rst_n or posedge clk)begin
	if(!rst_n)begin
		out_valid<=0;
	end
	else begin
		case(state)
			RESET:begin
				out_valid<=0;
			end
			COMPUTE:begin
				if(counter=='d12)begin
					out_valid<=1'b1;
				end
				else if(counter=='d13)begin
					out_valid<=0;
				end
			end
		endcase
	end
end

//round_counter,epoch_counter,four_epoch_flag;
always@(negedge rst_n or posedge clk)begin
	if(!rst_n)begin
		round_counter<=0;
		epoch_counter<=0;
		four_epoch_flag<=0;
	end
	else begin
		case(state)
			RESET:begin
				if(four_epoch_flag==3'd4)begin
					four_epoch_flag<=0;
				end
				if(round_counter=='d100)begin
					round_counter<=0;
				end
				if(epoch_counter=='d25)begin
					epoch_counter<=0;
					four_epoch_flag<=0;
				end
			end
			COMPUTE:begin
				if((counter=='d13) && (round_counter=='d99))begin
					epoch_counter<=epoch_counter+1;
					four_epoch_flag<=four_epoch_flag+1;
				end
				if(counter=='d13)begin
					round_counter<=round_counter+1;
				end
			end
		endcase
	end
end



//data_point_array(A)
always@(negedge rst_n or posedge clk)begin
	if(!rst_n)begin
		for(i=0;i<4;i=i+1)begin
			data_point_array[i]<=0;
		end
	end
	else if(in_valid_d)begin
		data_point_array[counter]<=data_point;
	end
	else begin
		case(state)
			RESET:begin
				for(i=0;i<4;i=i+1)begin
					data_point_array[i]<=0;
				end
			end
		endcase
	end
end

//target_store(B)
always@(negedge rst_n or posedge clk)begin
	if(!rst_n)begin
		target_store<=0;
	end
	else if(in_valid_t)begin
		target_store<=target;
	end
	else begin
		case(state)
			RESET:begin
				target_store<=0;
			end
		endcase
	end
end

//weight1_array(C)
always@(negedge rst_n or posedge clk)begin
	if(!rst_n)begin
		for(i=0;i<12;i=i+1)begin
			weight1_array[i]<=0;
		end
	end
	else if(in_valid_w1)begin
		weight1_array[counter]<=weight1;
	end
	else begin
		case(state)
			RESET:begin
				if(epoch_counter=='d25)begin
					for(i=0;i<12;i=i+1)begin
						weight1_array[i]<=0;
					end
				end
			end
			COMPUTE:begin
				case(counter)
					32'd10:begin
						weight1_array[0]<=Sub_A_z;
						weight1_array[1]<=Sub_B_z;
						weight1_array[2]<=Sub_C_z;
						weight1_array[3]<=Sub_D_z;
					end
					32'd11:begin
						weight1_array[4]<=Sub_A_z;
						weight1_array[5]<=Sub_B_z;
						weight1_array[6]<=Sub_C_z;
						weight1_array[7]<=Sub_D_z;
					end
					32'd12:begin
						weight1_array[8]<=Sub_A_z;
						weight1_array[9]<=Sub_B_z;
						weight1_array[10]<=Sub_C_z;
						weight1_array[11]<=Sub_D_z;
					end
				endcase
			end
		endcase
	end
end

//weight2_array(D)
always@(negedge rst_n or posedge clk)begin
	if(!rst_n)begin
		for(i=0;i<3;i=i+1)begin
			weight2_array[i]<=0;
		end
	end
	else if(in_valid_w2)begin
		weight2_array[counter]<=weight2;
	end
	else begin
		case(state)
			RESET:begin
				if(epoch_counter=='d25)begin
					for(i=0;i<3;i=i+1)begin
						weight2_array[i]<=0;
					end
				end
			end
			COMPUTE:begin
				case(counter)
					32'd9:begin
						weight2_array[0]<=Sub_F_z;
					end
					32'd10:begin
						weight2_array[1]<=Sub_F_z;
					end
					32'd11:begin
						weight2_array[2]<=Sub_F_z;
					end
				endcase
			end
		endcase
	end
end

//Eta(Todo)(E)
always@(negedge rst_n or posedge clk)begin
	if(!rst_n)begin
		Eta<=32'h358637BD;
	end
	else begin
		case(state)
			RESET:begin
				if(four_epoch_flag==3'd4)begin
					Eta[30:23]<=Eta[30:23]-8'd1;
				end
				if(epoch_counter==25)begin
					Eta<=32'h358637BD;
				end
			end
		endcase
	end
end


//weightMdata (0)
always@(negedge rst_n or posedge clk)begin
	if(!rst_n)begin
		for(i=0;i<4;i=i+1)begin
			weightMdata[i]<=0;
		end
	end
	else begin
		case(state)
			RESET:begin
				for(i=0;i<4;i=i+1)begin
					weightMdata[i]<=0;
				end
			end
			COMPUTE:begin
				case(counter)
					32'd0:begin
						weightMdata[0]<=Mult_A_z;
						weightMdata[1]<=Mult_B_z;
						weightMdata[2]<=Mult_C_z;
						weightMdata[3]<=Mult_D_z;
					end
					32'd1:begin
						weightMdata[0]<=Mult_A_z;
						weightMdata[1]<=Mult_B_z;
						weightMdata[2]<=Mult_C_z;
						weightMdata[3]<=Mult_D_z;
					end
					32'd2:begin
						weightMdata[0]<=Mult_A_z;
						weightMdata[1]<=Mult_B_z;
						weightMdata[2]<=Mult_C_z;
						weightMdata[3]<=Mult_D_z;
					end
				endcase
			end
		endcase
	end	
end

//weightMdata_2 (1)
always@(negedge rst_n or posedge clk)begin
	if(!rst_n)begin
		for(i=0;i<2;i=i+1)begin
			weightMdata_2[i]<=0;
		end
	end
	else begin
		case(state)
			RESET:begin
				for(i=0;i<2;i=i+1)begin
					weightMdata_2[i]<=0;
				end
			end
			COMPUTE:begin
				case(counter)
					32'd1:begin
						weightMdata_2[0]<=Add_A_z;
						weightMdata_2[1]<=Add_B_z;
					end
					32'd2:begin
						weightMdata_2[0]<=Add_A_z;
						weightMdata_2[1]<=Add_B_z;
					end
					32'd3:begin
						weightMdata_2[0]<=Add_A_z;
						weightMdata_2[1]<=Add_B_z;
					end
				endcase
			end
		endcase
	end	
end

//y1,g_diff (2)
always@(negedge rst_n or posedge clk)begin
	if(!rst_n)begin
		y1<=0;
		g_diff<=0;
	end
	else begin
		case(state)
			RESET:begin
				y1<=0;
				g_diff<=0;
			end
			COMPUTE:begin
				case(counter)
					32'd2:begin
						y1<=g_out;
						g_diff<=g_diff_out;
					end
					32'd3:begin
						y1<=g_out;
						g_diff<=g_diff_out;
					end
					32'd4:begin
						y1<=g_out;
						g_diff<=g_diff_out;
					end
				endcase
			end
		endcase
	end	
end

//EtaMdata (3)
always@(negedge rst_n or posedge clk)begin
	if(!rst_n)begin
		for(i=0;i<4;i=i+1)begin
			EtaMdata[i]<=0;
		end
	end
	else begin
		case(state)
			RESET:begin
				for(i=0;i<4;i=i+1)begin
					EtaMdata[i]<=0;
				end
			end
			COMPUTE:begin
				case(counter)
					32'd3:begin
						EtaMdata[0]<=Mult_A_z;
						EtaMdata[1]<=Mult_B_z;
						EtaMdata[2]<=Mult_C_z;
						EtaMdata[3]<=Mult_D_z;
					end
				endcase
			end
		endcase
	end	
end

//weight2My1,weight2Mg_diff[0:4],gMEta[0:4],delta2,y2 (4)(5)(6)(7)(8)
always@(negedge rst_n or posedge clk)begin
	if(!rst_n)begin
		weight2My1<=0;
		for(i=0;i<5;i=i+1)begin
			weight2Mg_diff[i]<=0;
			gMEta[i]<=0;
		end
		y2<=0;
		delta2<=0;
	end
	else begin
		case(state)
			RESET:begin
				weight2My1<=0;
				for(i=0;i<5;i=i+1)begin
					weight2Mg_diff[i]<=0;
					gMEta[i]<=0;
				end
				y2<=0;
				delta2<=0;
			end
			COMPUTE:begin
				case(counter)
					32'd3:begin
						weight2My1<=Mult_E_z;
						weight2Mg_diff[0]<=Mult_F_z;
						gMEta[0]<=Mult_G_z;
						y2<=0;
					end
					32'd4:begin
						weight2My1<=Mult_E_z;
						y2<=Add_D_z;

						weight2Mg_diff[0]<=Mult_F_z;
						weight2Mg_diff[1]<=weight2Mg_diff[0];

						gMEta[0]<=Mult_G_z;
						gMEta[1]<=gMEta[0];
					end
					32'd5:begin
						weight2My1<=Mult_E_z;
						y2<=Add_D_z;

						weight2Mg_diff[0]<=Mult_F_z;
						weight2Mg_diff[1]<=weight2Mg_diff[0];
						weight2Mg_diff[2]<=weight2Mg_diff[1];

						gMEta[0]<=Mult_G_z;
						gMEta[1]<=gMEta[0];
						gMEta[2]<=gMEta[1];
					end
					32'd6:begin
						y2<=Add_D_z;

						weight2Mg_diff[1]<=weight2Mg_diff[0];
						weight2Mg_diff[2]<=weight2Mg_diff[1];
						weight2Mg_diff[3]<=weight2Mg_diff[2];

						gMEta[1]<=gMEta[0];
						gMEta[2]<=gMEta[1];
						gMEta[3]<=gMEta[2];
					end
					32'd7:begin
						delta2<=Sub_E_z;

						
						weight2Mg_diff[2]<=weight2Mg_diff[1];
						weight2Mg_diff[3]<=weight2Mg_diff[2];
						weight2Mg_diff[4]<=weight2Mg_diff[3];

						gMEta[2]<=gMEta[1];
						gMEta[3]<=gMEta[2];
						gMEta[4]<=gMEta[3];
						
					end
					32'd8:begin
						weight2Mg_diff[3]<=weight2Mg_diff[2];
						weight2Mg_diff[4]<=weight2Mg_diff[3];

						gMEta[3]<=gMEta[2];
						gMEta[4]<=gMEta[3];
					end
					32'd9:begin
						weight2Mg_diff[4]<=weight2Mg_diff[3];

						gMEta[4]<=gMEta[3];
					end
				endcase
			end
		endcase
	end	
end

//delta1,delta2MgMEta(9)
always@(negedge rst_n or posedge clk)begin
	if(!rst_n)begin
		delta1<=0;
		delta2MgMEta<=0;
	end
	else begin
		case(state)
			RESET:begin
				delta1<=0;
				delta2MgMEta<=0;
			end
			COMPUTE:begin
				case(counter)
					32'd8:begin
						delta1<=Mult_E_z;
						delta2MgMEta<=Mult_F_z;
					end
					32'd9:begin
						delta1<=Mult_E_z;
						delta2MgMEta<=Mult_F_z;
					end
					32'd10:begin
						delta1<=Mult_E_z;
						delta2MgMEta<=Mult_F_z;
					end
				endcase
			end
		endcase
	end	
end

//delta1MdataMEta[0:3](10)
always@(negedge rst_n or posedge clk)begin
	if(!rst_n)begin
		for(i=0;i<4;i=i+1)begin
			delta1MdataMEta[i]<=0;
		end
	end
	else begin
		case(state)
			RESET:begin
				for(i=0;i<4;i=i+1)begin
					delta1MdataMEta[i]<=0;
				end
			end
			COMPUTE:begin
				case(counter)
					32'd9:begin
						delta1MdataMEta[0]<=Mult_A_z;
						delta1MdataMEta[1]<=Mult_B_z;
						delta1MdataMEta[2]<=Mult_C_z;
						delta1MdataMEta[3]<=Mult_D_z;
					end
					32'd10:begin
						delta1MdataMEta[0]<=Mult_A_z;
						delta1MdataMEta[1]<=Mult_B_z;
						delta1MdataMEta[2]<=Mult_C_z;
						delta1MdataMEta[3]<=Mult_D_z;
					end
					32'd11:begin
						delta1MdataMEta[0]<=Mult_A_z;
						delta1MdataMEta[1]<=Mult_B_z;
						delta1MdataMEta[2]<=Mult_C_z;
						delta1MdataMEta[3]<=Mult_D_z;
					end
				endcase
			end
		endcase
	end	
end



//wiring MultABCD
always@(*)begin
	case(state)
		COMPUTE:begin
			case(counter)
				32'd0:begin
					Mult_A_a=weight1_array[0];
					Mult_B_a=weight1_array[1];
					Mult_C_a=weight1_array[2];
					Mult_D_a=weight1_array[3];
					Mult_A_b=data_point_array[0];
					Mult_B_b=data_point_array[1];
					Mult_C_b=data_point_array[2];
					Mult_D_b=data_point_array[3];
				end
				32'd1:begin
					Mult_A_a=weight1_array[4];
					Mult_B_a=weight1_array[5];
					Mult_C_a=weight1_array[6];
					Mult_D_a=weight1_array[7];
					Mult_A_b=data_point_array[0];
					Mult_B_b=data_point_array[1];
					Mult_C_b=data_point_array[2];
					Mult_D_b=data_point_array[3];
				end
				32'd2:begin
					Mult_A_a=weight1_array[8];
					Mult_B_a=weight1_array[9];
					Mult_C_a=weight1_array[10];
					Mult_D_a=weight1_array[11];
					Mult_A_b=data_point_array[0];
					Mult_B_b=data_point_array[1];
					Mult_C_b=data_point_array[2];
					Mult_D_b=data_point_array[3];
				end

				32'd3:begin
					Mult_A_a=Eta;
					Mult_B_a=Eta;
					Mult_C_a=Eta;
					Mult_D_a=Eta;
					Mult_A_b=data_point_array[0];
					Mult_B_b=data_point_array[1];
					Mult_C_b=data_point_array[2];
					Mult_D_b=data_point_array[3];
				end

				32'd9:begin
					Mult_A_a=delta1;
					Mult_B_a=delta1;
					Mult_C_a=delta1;
					Mult_D_a=delta1;
					Mult_A_b=EtaMdata[0];
					Mult_B_b=EtaMdata[1];
					Mult_C_b=EtaMdata[2];
					Mult_D_b=EtaMdata[3];
				end
				32'd10:begin
					Mult_A_a=delta1;
					Mult_B_a=delta1;
					Mult_C_a=delta1;
					Mult_D_a=delta1;
					Mult_A_b=EtaMdata[0];
					Mult_B_b=EtaMdata[1];
					Mult_C_b=EtaMdata[2];
					Mult_D_b=EtaMdata[3];
				end
				32'd11:begin
					Mult_A_a=delta1;
					Mult_B_a=delta1;
					Mult_C_a=delta1;
					Mult_D_a=delta1;
					Mult_A_b=EtaMdata[0];
					Mult_B_b=EtaMdata[1];
					Mult_C_b=EtaMdata[2];
					Mult_D_b=EtaMdata[3];
				end
				default:begin
					Mult_A_a=0;
					Mult_B_a=0;
					Mult_C_a=0;
					Mult_D_a=0;
					Mult_A_b=0;
					Mult_B_b=0;
					Mult_C_b=0;
					Mult_D_b=0;
				end
			endcase
		end
		default:begin
			Mult_A_a=0;
			Mult_B_a=0;
			Mult_C_a=0;
			Mult_D_a=0;
			Mult_A_b=0;
			Mult_B_b=0;
			Mult_C_b=0;
			Mult_D_b=0;
		end
	endcase
end

//wiring MultEFG
always@(*)begin
	case(state)
		COMPUTE:begin
			case(counter)
				32'd3:begin
					Mult_E_a=weight2_array[0];
					Mult_F_a=weight2_array[0];
					Mult_G_a=Eta;
					Mult_E_b=y1;
					Mult_F_b=g_diff;
					Mult_G_b=y1;
				end
				32'd4:begin
					Mult_E_a=weight2_array[1];
					Mult_F_a=weight2_array[1];
					Mult_G_a=Eta;
					Mult_E_b=y1;
					Mult_F_b=g_diff;
					Mult_G_b=y1;
				end
				32'd5:begin
					Mult_E_a=weight2_array[2];
					Mult_F_a=weight2_array[2];
					Mult_G_a=Eta;
					Mult_E_b=y1;
					Mult_F_b=g_diff;
					Mult_G_b=y1;
				end
				32'd8:begin
					Mult_E_a=delta2;
					Mult_F_a=delta2;
					Mult_G_a=0;
					Mult_E_b=weight2Mg_diff[4];
					Mult_F_b=gMEta[4];
					Mult_G_b=0;
				end
				32'd9:begin
					Mult_E_a=delta2;
					Mult_F_a=delta2;
					Mult_G_a=0;
					Mult_E_b=weight2Mg_diff[4];
					Mult_F_b=gMEta[4];
					Mult_G_b=0;
				end
				32'd10:begin
					Mult_E_a=delta2;
					Mult_F_a=delta2;
					Mult_G_a=0;
					Mult_E_b=weight2Mg_diff[4];
					Mult_F_b=gMEta[4];
					Mult_G_b=0;
				end
				default:begin
					Mult_E_a=0;
					Mult_F_a=0;
					Mult_G_a=0;
					Mult_E_b=0;
					Mult_F_b=0;
					Mult_G_b=0;
				end
			endcase
		end
		default:begin
			Mult_E_a=0;
			Mult_F_a=0;
			Mult_G_a=0;
			Mult_E_b=0;
			Mult_F_b=0;
			Mult_G_b=0;
		end
	endcase
end

//wiring SubABCD
always@(*)begin
	case(state)
		COMPUTE:begin
			case(counter)
				4'd10:begin
					Sub_A_a=weight1_array[0];
					Sub_B_a=weight1_array[1];
					Sub_C_a=weight1_array[2];
					Sub_D_a=weight1_array[3];
				end
				4'd11:begin
					Sub_A_a=weight1_array[4];
					Sub_B_a=weight1_array[5];
					Sub_C_a=weight1_array[6];
					Sub_D_a=weight1_array[7];
				end
				4'd12:begin
					Sub_A_a=weight1_array[8];
					Sub_B_a=weight1_array[9];
					Sub_C_a=weight1_array[10];
					Sub_D_a=weight1_array[11];
				end
				default:begin
					Sub_A_a=0;
					Sub_B_a=0;
					Sub_C_a=0;
					Sub_D_a=0;
				end
			endcase
		end
		default:begin
			Sub_A_a=0;
			Sub_B_a=0;
			Sub_C_a=0;
			Sub_D_a=0;
		end
	endcase
end

//wiring SubE
always@(*)begin
	case(state)
		COMPUTE:begin
			case(counter)
				4'd7:begin
					Sub_E_a=y2;
					Sub_E_b=target_store;
				end
				default:begin
					Sub_E_a=0;
					Sub_E_b=0;
				end
			endcase
		end
		default:begin
			Sub_E_a=0;
			Sub_E_b=0;
		end
	endcase
end
//wiring SubF
always@(*)begin
	case(state)
		COMPUTE:begin
			case(counter)
				4'd9:begin
					Sub_F_a=weight2_array[0];
				end
				4'd10:begin
					Sub_F_a=weight2_array[1];
				end
				4'd11:begin
					Sub_F_a=weight2_array[2];
				end
				default:begin
					Sub_F_a=0;
				end
			endcase
		end
		default:begin
			Sub_F_a=0;
		end
	endcase
end

//counter
always@(negedge rst_n or posedge clk)begin
	if(!rst_n)begin
		counter<=0;
	end
	else begin
		case(state)
			RESET:begin
				if(in_valid_w1)begin
					counter<=counter+1;
				end
				else if(in_valid_d)begin
					counter<=counter+1;
				end
				else begin
					counter<=0;
				end
			end
			INPUTWEIGHT:begin
				if(!in_valid_w1 && !in_valid_d)begin
					counter<=0;
				end
				else if(in_valid_d)begin
					counter<=counter+1;
				end
				else if(in_valid_w1)begin
					counter<=counter+1;
				end
			end
			INPUTDATA:begin
				if(in_valid_d && (counter==3))begin
					counter<=0;
				end
				else begin
					counter<=counter+1;
				end
			end
			COMPUTE:begin
				if(counter==13)begin
					counter<=0;
				end
				else begin
					counter<=counter+1;
				end
			end
		endcase
	end	
end

endmodule




//---------------------------------------------------------------------
//   DesignWare
//---------------------------------------------------------------------
module DW_fp_mult_inst(inst_a,inst_b,z_inst);
	
	// IEEE floating point paramenters
	parameter inst_sig_width = 23;
	parameter inst_exp_width = 8;
	parameter inst_ieee_compliance = 0;
	parameter inst_arch = 2;

	// INPUT AND OUTPUT DECLARATION
	input [inst_sig_width+inst_exp_width:0]inst_a,inst_b;
	output [inst_sig_width+inst_exp_width:0]z_inst;


	DW_fp_mult #(inst_sig_width,inst_exp_width,inst_ieee_compliance)
		M1 ( .a(inst_a), .b(inst_b), .rnd(3'b000), .z(z_inst));

endmodule

module DW_fp_add_inst(inst_a,inst_b,z_inst);

	// IEEE floating point paramenters
	parameter inst_sig_width = 23;
	parameter inst_exp_width = 8;
	parameter inst_ieee_compliance = 0;
	parameter inst_arch = 2;

	// INPUT AND OUTPUT DECLARATION
	input [inst_sig_width+inst_exp_width:0]inst_a,inst_b;
	output [inst_sig_width+inst_exp_width:0]z_inst;

	DW_fp_add #(inst_sig_width,inst_exp_width,inst_ieee_compliance)
		A1 ( .a(inst_a), .b(inst_b), .rnd(3'b000), .z(z_inst));

endmodule

module DW_fp_sub_inst(inst_a,inst_b,z_inst);

	// IEEE floating point paramenters
	parameter inst_sig_width = 23;
	parameter inst_exp_width = 8;
	parameter inst_ieee_compliance = 0;
	parameter inst_arch = 2;

	// INPUT AND OUTPUT DECLARATION
	input [inst_sig_width+inst_exp_width:0]inst_a,inst_b;
	output [inst_sig_width+inst_exp_width:0]z_inst;

	DW_fp_sub #(inst_sig_width,inst_exp_width,inst_ieee_compliance)
		S1 ( .a(inst_a), .b(inst_b), .rnd(3'b000), .z(z_inst));

endmodule

module ReLU(in,out);

	parameter inst_sig_width = 23;
	parameter inst_exp_width = 8;
	parameter ieee_compliance = 0;
	// INPUT AND OUTPUT DECLARATION
	input [inst_sig_width+inst_exp_width:0]in;
	output [inst_sig_width+inst_exp_width:0]out;
	
	DW_fp_cmp #(inst_sig_width, inst_exp_width, ieee_compliance)
		R1 ( .a(in), .b(32'd0), .zctr(1'b0), .z1(out));

endmodule

module ReLU_diff(in,out);

	parameter inst_sig_width = 23;
	parameter inst_exp_width = 8;
	parameter ieee_compliance = 0;
	// INPUT AND OUTPUT DECLARATION
	input [inst_sig_width+inst_exp_width:0]in;
	output reg[inst_sig_width+inst_exp_width:0]out;
	wire aeqb_inst,altb_inst,agtb_inst;

	always@(*)begin
		if(agtb_inst)begin
			out=32'b00111111100000000000000000000000;
		end
		else begin
			out=32'd0;
		end
	end


	DW_fp_cmp #(inst_sig_width, inst_exp_width, ieee_compliance)
		RD1 ( .a(in), .b(32'd0), .zctr(1'b1), .agtb(agtb_inst) );

endmodule