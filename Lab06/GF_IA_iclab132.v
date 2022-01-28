//synopsys translate_off
`include "GF2k.v"
//synopsys translate_on

module GF_IA (
input in_valid,
input [4:0] in_data,
input [2:0] deg,
input [5:0] poly,
input rst_n,
input clk,
output reg [4:0] out_data,
output reg out_valid
);
parameter RESET = 0;
parameter INPUTMODE = 1;
parameter COMPUTE = 2;
parameter OUTPUTMODE = 3;


// =========================================
// Input Register
// =========================================
reg [4:0] Matrix [0:3];
reg [5:0] Poly;
reg [2:0] Deg;

// =========================================
// State Register
// =========================================
reg [1:0] state;
reg [3:0] counter;

// =========================================
// Wire
// =========================================
reg [1:0] next_state;
reg [4:0] select_out;
reg [4:0] select_in_div;
reg [4:0] select_Det;

wire [1:0] ad_2,bc_2,Det_2;
wire [1:0] R_2;
wire [2:0] ad_3,bc_3,Det_3;
wire [2:0] R_3;
wire [3:0] ad_4,bc_4,Det_4;
wire [3:0] R_4;
wire [4:0] ad_5,bc_5,Det_5;
wire [4:0] R_5;

integer i;

/* always@(negedge rst_n or posedge clk)begin
    $write("state : %1d , ",state);
    $write("Deg : %1d , ",Deg);
    $write("counter : %2d , ",counter);
    $write("in_valid : %1d , ",in_valid);
    $write("out_valid : %1d , ",out_valid);
    for(i=0;i<4;i=i+1)begin
        $write("M[%1d] : %2d , ",i,Matrix[i]);
    end
    $write("s div : %2d , ",select_in_div);
    $write("s out : %2d , ",select_out);

    $write("Det : %2d , ",select_Det);

    $display();
end */

// =========================================
// Finite State Machine
// =========================================
// Setting state
always@(negedge rst_n or posedge clk)begin
    if(!rst_n) state <= RESET;
    else state <= next_state;
end
// counter
always@(negedge rst_n or posedge clk)begin
    if(!rst_n) counter <= 0;
    else if (in_valid && (state == RESET)) counter <= counter+1;
    else if (state == RESET) counter <= 0;
    else if (counter==9) counter <= 0;
    else counter <= counter+1;
end
// Setting next state
always@(*)begin
    if(!rst_n) next_state = RESET;
    else if( (state == RESET) && in_valid ) next_state = INPUTMODE;
    else if( (state == INPUTMODE) && !in_valid ) next_state = COMPUTE;
    else if (state == COMPUTE) next_state = OUTPUTMODE;
    else if (counter==9) next_state = RESET;
    else next_state = state;
end
// Matrix
always@(posedge clk)begin
    if(in_valid)begin
        Matrix[3] <= in_data ;
        Matrix[2] <= Matrix[3] ;
        Matrix[1] <= Matrix[2] ;
        Matrix[0] <= Matrix[1] ;
    end
end
// Poly , Deg
always@(posedge clk)begin
    if(in_valid && (state == RESET))begin
        Poly <= poly;
        Deg <= deg;
    end
end



// =========================================
// Output Data
// =========================================
// out_data
always@(negedge rst_n or posedge clk)begin
    if(!rst_n) out_data <= 0;
    else if (counter==5) out_data <= select_out;
    else if (counter==6) out_data <= select_out;
    else if (counter==7) out_data <= select_out;
    else if (counter==8) out_data <= select_out;
    else if (counter==9) out_data <= 0;
end
// out_valid
always@(negedge rst_n or posedge clk)begin
    if(!rst_n) out_valid <= 0;
    else if (counter==5) out_valid <= 1;
    else if (counter==9) out_valid <= 0;
end

// =========================================
// Wiring
// =========================================
// select_out
always@(*)begin
    if(select_Det==0)begin
        select_out=0;
    end
    else begin
        case(Deg)
            2:select_out={3'b0,R_2};
            3:select_out={2'b0,R_3};
            4:select_out={1'b0,R_4};
            5:select_out=R_5;
            default:select_out=0;
        endcase
    end
    
end
// select_in_div
always@(*)begin
    case(counter)
        5:select_in_div=Matrix[3];
        6:select_in_div=Matrix[1];
        7:select_in_div=Matrix[2];
        8:select_in_div=Matrix[0];
        default:select_in_div=0;
    endcase
end
// select_Det
always@(*)begin
    case(Deg)
        2:select_Det={3'b0,Det_2};
        3:select_Det={2'b0,Det_3};
        4:select_Det={1'b0,Det_4};
        5:select_Det=Det_5;
        default:select_Det=0;
    endcase
end

// =========================================
// IPs
// =========================================

GF2k #( 2 , 2 ) M1_d2 (.POLY(Poly[2:0]),.IN1(Matrix[0][1:0]),.IN2(Matrix[3][1:0]),.RESULT(ad_2));
GF2k #( 2 , 2 ) M2_d2 (.POLY(Poly[2:0]),.IN1(Matrix[1][1:0]),.IN2(Matrix[2][1:0]),.RESULT(bc_2));
GF2k #( 2 , 1 ) S1_d2 (.POLY(Poly[2:0]),.IN1(ad_2),.IN2(bc_2),.RESULT(Det_2));
GF2k #( 2 , 3 ) D2_d2 (.POLY(Poly[2:0]),.IN1(select_in_div[1:0]),.IN2(Det_2),.RESULT(R_2));


GF2k #( 3 , 2 ) M1_d3 (.POLY(Poly[3:0]),.IN1(Matrix[0][2:0]),.IN2(Matrix[3][2:0]),.RESULT(ad_3));
GF2k #( 3 , 2 ) M2_d3 (.POLY(Poly[3:0]),.IN1(Matrix[1][2:0]),.IN2(Matrix[2][2:0]),.RESULT(bc_3));
GF2k #( 3 , 1 ) S1_d3 (.POLY(Poly[3:0]),.IN1(ad_3),.IN2(bc_3),.RESULT(Det_3));
GF2k #( 3 , 3 ) D2_d3 (.POLY(Poly[3:0]),.IN1(select_in_div[2:0]),.IN2(Det_3),.RESULT(R_3));


GF2k #( 4 , 2 ) M1_d4 (.POLY(Poly[4:0]),.IN1(Matrix[0][3:0]),.IN2(Matrix[3][3:0]),.RESULT(ad_4));
GF2k #( 4 , 2 ) M2_d4 (.POLY(Poly[4:0]),.IN1(Matrix[1][3:0]),.IN2(Matrix[2][3:0]),.RESULT(bc_4));
GF2k #( 4 , 1 ) S1_d4 (.POLY(Poly[4:0]),.IN1(ad_4),.IN2(bc_4),.RESULT(Det_4));
GF2k #( 4 , 3 ) D2_d4 (.POLY(Poly[4:0]),.IN1(select_in_div[3:0]),.IN2(Det_4),.RESULT(R_4));


GF2k #( 5 , 2 ) M1_d5 (.POLY(Poly),.IN1(Matrix[0]),.IN2(Matrix[3]),.RESULT(ad_5));
GF2k #( 5 , 2 ) M2_d5 (.POLY(Poly),.IN1(Matrix[1]),.IN2(Matrix[2]),.RESULT(bc_5));
GF2k #( 5 , 1 ) S1_d5 (.POLY(Poly),.IN1(ad_5),.IN2(bc_5),.RESULT(Det_5));
GF2k #( 5 , 3 ) D2_d5 (.POLY(Poly),.IN1(select_in_div[4:0]),.IN2(Det_5),.RESULT(R_5));

endmodule



