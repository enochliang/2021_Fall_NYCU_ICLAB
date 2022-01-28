module GF2k
#( parameter DEG = 2 , parameter OP = 0)
(
input  [DEG:0]   POLY,
input  [DEG-1:0] IN1,
input  [DEG-1:0] IN2,
output [DEG-1:0] RESULT
);

    generate
        if(OP==0 || OP==1)begin
            assign RESULT=IN1^IN2;
        end
        else if(OP==2)begin
            GF2k_mult #(DEG) M1(.POLY(POLY),.IN1(IN1),.IN2(IN2),.RESULT(RESULT));
        end
        else if(OP==3)begin
            GF2k_div #(DEG) D1(.POLY(POLY),.IN1(IN1),.IN2(IN2),.RESULT(RESULT));
        end
        
    endgenerate

endmodule





//----------Multiplier Modules------------
module GF2k_mult
#( parameter DEG = 2)
(
input  [DEG:0]   POLY,
input  [DEG-1:0] IN1,
input  [DEG-1:0] IN2,
output [DEG-1:0] RESULT
);



    genvar i;
    generate
        if(DEG==2)begin
            wire [2:0]temp_1;
            wire [2:0]temp_2;
            wire [2:0]temp_3;

            assign temp_1 = (IN2[0]==1) ? {1'b0,IN1} : 0;
            assign temp_2 = (IN2[1]==1) ? {IN1,1'b0} : 0;
            assign temp_3 = temp_1 ^ temp_2 ;

            assign RESULT = (temp_3[2]==1) ? (temp_3[1:0] ^ POLY[1:0]) : temp_3[1:0];
        end
        else begin
            GF2k_mult_small #(DEG) small_mult ( .POLY(POLY), .IN1(IN1), .IN2(IN2), .RESULT(RESULT) );
        end

    endgenerate

endmodule

module GF2k_mult_small
#( parameter DEG = 2)
(
input  [DEG:0]   POLY,
input  [DEG-1:0] IN1,
input  [DEG-1:0] IN2,
output [DEG-1:0] RESULT
);
genvar i;
    generate
        wire [2*DEG-2:0] temp_3;//to store the result of galois multipition.
        for(i=0;i<DEG;i=i+1)begin:loop_A
            
            wire [DEG-1+i:0]temp_1;//to store IN1<<i
            wire [DEG-1+i:0]temp_2;//to store the temparary galois sum during the computation of galois multipition. 
            if(i==0) begin
                assign temp_2 = (IN2[i]==1) ? IN1 : 0 ;
            end
            else begin
                assign temp_1=(IN1<<i);
                assign temp_2 = (IN2[i]==1) ? {1'b0,loop_A[i-1].temp_2}^temp_1 : {1'b0,loop_A[i-1].temp_2} ;
                
                if(i==DEG-1)begin
                    assign temp_3=temp_2;
                end
            end
        end
        for(i=0;i<DEG-1;i=i+1)begin:loop_B
            wire [2*DEG-3-i:0] temp_4;
            wire [2*DEG-3-i:0] temp_5;
            if(i==0)begin
                assign temp_4 = POLY[DEG-1:0] << (DEG-2) ;//size:2D-2
                assign temp_5 = ( temp_3[2*DEG-2]==1) ? temp_4^temp_3[2*DEG-3:0] : temp_3[2*DEG-3:0];
            end
            else begin
                assign temp_4 = loop_B[i-1].temp_4 >> 1 ;//size:2D-2
                assign temp_5 = ( loop_B[i-1].temp_5[2*DEG-2-i] == 1 ) ? temp_4^loop_B[i-1].temp_5[2*DEG-3-i:0] : loop_B[i-1].temp_5[2*DEG-3-i:0];
                if(i==DEG-2) assign RESULT = temp_5;
            end
        end

    endgenerate

endmodule
//======================================================



//----------Divider Modules------------
module GF2k_div
#( parameter DEG = 2)
(
input  [DEG:0]   POLY,
input  [DEG-1:0] IN1,
input  [DEG-1:0] IN2,
output [DEG-1:0] RESULT
);

wire  [DEG-1:0] DR;
wire  [DEG-1:0] rr;

    generate
        assign RESULT = (IN2==1) ? IN1 : rr ;
        
        GF2k_inv #(DEG) inv(.POLY(POLY),.IN(IN2),.RESULT(DR));
        GF2k_mult #(DEG) mul(.POLY(POLY),.IN1(IN1),.IN2(DR),.RESULT(rr));
        
    endgenerate

endmodule


module GF2k_inv
#(parameter DEG = 2)
(
input  [DEG:0]   POLY,
input  [DEG-1:0] IN,
output [DEG-1:0] RESULT
);

    genvar i;
    generate
        if(DEG==2)begin
            //wire [DEG-1:0]Q1;
            wire [DEG-1:0]R1;
            wire [DEG-1:0]MQ1;
            wire [DEG-1:0]mql_1;
            GF2k_inv_first #(DEG) D1 ( .DN(POLY) , .DR(IN) , .R(R1) , .MQ_out(MQ1) , .mql_out(mql_1) );
            assign RESULT = MQ1;
        end
        if(DEG==3)begin
            //wire [DEG-1:0]Q1;
            wire [DEG-1:0]R1;
            wire [DEG-1:0]MQ1;
            wire [DEG-1:0]mql_1;

            //wire [DEG-1:0]Q2;
            wire [DEG-1:0]R2;
            wire [DEG-1:0]MQ2;
            wire [DEG-1:0]mql_2;
            
            GF2k_inv_first #(DEG) D1 ( .DN(POLY) , .DR(IN) , .R(R1) , .MQ_out(MQ1) , .mql_out(mql_1) );
            GF2k_inv_small #(DEG) D2 ( .mql_in(MQ1) , .mqh_in(mql_1) , .DN(IN) , .DR(R1), .R(R2) , .MQ_out(MQ2) , .mql_out(mql_2) );
            
            assign RESULT = ( R1==1 ) ? MQ1 : MQ2 ;
        end
        else if(DEG==4)begin
            //wire [DEG-1:0]Q1;
            wire [DEG-1:0]R1;
            wire [DEG-1:0]MQ1;
            wire [DEG-1:0]mql_1;

            //wire [DEG-1:0]Q2;
            wire [DEG-1:0]R2;
            wire [DEG-1:0]MQ2;
            wire [DEG-1:0]mql_2;

            //wire [DEG-1:0]Q3;
            wire [DEG-1:0]R3;
            wire [DEG-1:0]MQ3;
            wire [DEG-1:0]mql_3;
            
            GF2k_inv_first #(DEG) D1 ( .DN(POLY) , .DR(IN) , .R(R1) , .MQ_out(MQ1) , .mql_out(mql_1) );
            GF2k_inv_small #(DEG) D2 ( .mql_in(MQ1) , .mqh_in(mql_1) , .DN(IN) , .DR(R1), .R(R2) , .MQ_out(MQ2) , .mql_out(mql_2) );
            GF2k_inv_small #(DEG) D3 ( .mql_in(MQ2) , .mqh_in(mql_2) , .DN(R1) , .DR(R2), .R(R3) , .MQ_out(MQ3) , .mql_out(mql_3) );

            assign RESULT = ( R1==1 ) ? MQ1 : (( R2==1 ) ? MQ2 : MQ3 );
        end
        else if(DEG==5)begin
            //wire [DEG-1:0]Q1;
            wire [DEG-1:0]R1;
            wire [DEG-1:0]MQ1;
            wire [DEG-1:0]mql_1;

            //wire [DEG-1:0]Q2;
            wire [DEG-1:0]R2;
            wire [DEG-1:0]MQ2;
            wire [DEG-1:0]mql_2;

            //wire [DEG-1:0]Q3;
            wire [DEG-1:0]R3;
            wire [DEG-1:0]MQ3;
            wire [DEG-1:0]mql_3;

            //wire [DEG-1:0]Q4;
            wire [DEG-1:0]R4;
            wire [DEG-1:0]MQ4;
            wire [DEG-1:0]mql_4;
            
            GF2k_inv_first #(DEG) D1 ( .DN(POLY) , .DR(IN) , .R(R1) , .MQ_out(MQ1) , .mql_out(mql_1) );
            GF2k_inv_small #(DEG) D2 ( .mql_in(MQ1) , .mqh_in(mql_1) , .DN(IN) , .DR(R1), .R(R2) , .MQ_out(MQ2) , .mql_out(mql_2) );
            GF2k_inv_small #(DEG) D3 ( .mql_in(MQ2) , .mqh_in(mql_2) , .DN(R1) , .DR(R2), .R(R3) , .MQ_out(MQ3) , .mql_out(mql_3) );
            GF2k_inv_small #(DEG) D4 ( .mql_in(MQ3) , .mqh_in(mql_3) , .DN(R2) , .DR(R3), .R(R4) , .MQ_out(MQ4) , .mql_out(mql_4) );

            assign RESULT = ( R1==1 ) ? MQ1 : (( R2==1 ) ? MQ2 : (( R3==1 ) ? MQ3 : MQ4) );
        end
        else if(DEG==6)begin
            //wire [DEG-1:0]Q1;
            wire [DEG-1:0]R1;
            wire [DEG-1:0]MQ1;
            wire [DEG-1:0]mql_1;

            //wire [DEG-1:0]Q2;
            wire [DEG-1:0]R2;
            wire [DEG-1:0]MQ2;
            wire [DEG-1:0]mql_2;

            //wire [DEG-1:0]Q3;
            wire [DEG-1:0]R3;
            wire [DEG-1:0]MQ3;
            wire [DEG-1:0]mql_3;

            //wire [DEG-1:0]Q4;
            wire [DEG-1:0]R4;
            wire [DEG-1:0]MQ4;
            wire [DEG-1:0]mql_4;

            //wire [DEG-1:0]Q5;
            wire [DEG-1:0]R5;
            wire [DEG-1:0]MQ5;
            wire [DEG-1:0]mql_5;
            
            GF2k_inv_first #(DEG) D1 ( .DN(POLY) , .DR(IN) , .R(R1) , .MQ_out(MQ1) , .mql_out(mql_1) );
            GF2k_inv_small #(DEG) D2 ( .mql_in(MQ1) , .mqh_in(mql_1) , .DN(IN) , .DR(R1), .R(R2) , .MQ_out(MQ2) , .mql_out(mql_2) );
            GF2k_inv_small #(DEG) D3 ( .mql_in(MQ2) , .mqh_in(mql_2) , .DN(R1) , .DR(R2), .R(R3) , .MQ_out(MQ3) , .mql_out(mql_3) );
            GF2k_inv_small #(DEG) D4 ( .mql_in(MQ3) , .mqh_in(mql_3) , .DN(R2) , .DR(R3), .R(R4) , .MQ_out(MQ4) , .mql_out(mql_4) );
            GF2k_inv_small #(DEG) D5 ( .mql_in(MQ4) , .mqh_in(mql_4) , .DN(R3) , .DR(R4), .R(R5) , .MQ_out(MQ5) , .mql_out(mql_5) );

            assign RESULT = ( R1==1 ) ? MQ1 : (( R2==1 ) ? MQ2 : (( R3==1 ) ? MQ3 : (( R4==1 ) ? MQ4 : MQ5)) );
        end
        else if(DEG==7)begin
            //wire [DEG-1:0]Q1;
            wire [DEG-1:0]R1;
            wire [DEG-1:0]MQ1;
            wire [DEG-1:0]mql_1;

            //wire [DEG-1:0]Q2;
            wire [DEG-1:0]R2;
            wire [DEG-1:0]MQ2;
            wire [DEG-1:0]mql_2;

            //wire [DEG-1:0]Q3;
            wire [DEG-1:0]R3;
            wire [DEG-1:0]MQ3;
            wire [DEG-1:0]mql_3;

            //wire [DEG-1:0]Q4;
            wire [DEG-1:0]R4;
            wire [DEG-1:0]MQ4;
            wire [DEG-1:0]mql_4;

            //wire [DEG-1:0]Q5;
            wire [DEG-1:0]R5;
            wire [DEG-1:0]MQ5;
            wire [DEG-1:0]mql_5;

            //wire [DEG-1:0]Q6;
            wire [DEG-1:0]R6;
            wire [DEG-1:0]MQ6;
            wire [DEG-1:0]mql_6;
            
            GF2k_inv_first #(DEG) D1 ( .DN(POLY) , .DR(IN) , .R(R1) , .MQ_out(MQ1) , .mql_out(mql_1) );
            GF2k_inv_small #(DEG) D2 ( .mql_in(MQ1) , .mqh_in(mql_1) , .DN(IN) , .DR(R1), .R(R2) , .MQ_out(MQ2) , .mql_out(mql_2) );
            GF2k_inv_small #(DEG) D3 ( .mql_in(MQ2) , .mqh_in(mql_2) , .DN(R1) , .DR(R2), .R(R3) , .MQ_out(MQ3) , .mql_out(mql_3) );
            GF2k_inv_small #(DEG) D4 ( .mql_in(MQ3) , .mqh_in(mql_3) , .DN(R2) , .DR(R3), .R(R4) , .MQ_out(MQ4) , .mql_out(mql_4) );
            GF2k_inv_small #(DEG) D5 ( .mql_in(MQ4) , .mqh_in(mql_4) , .DN(R3) , .DR(R4), .R(R5) , .MQ_out(MQ5) , .mql_out(mql_5) );
            GF2k_inv_small #(DEG) D6 ( .mql_in(MQ5) , .mqh_in(mql_5) , .DN(R4) , .DR(R5), .R(R6) , .MQ_out(MQ6) , .mql_out(mql_6) );

            assign RESULT = ( R1==1 ) ? MQ1 : (( R2==1 ) ? MQ2 : (( R3==1 ) ? MQ3 : (( R4==1 ) ? MQ4 : (( R5==1 ) ? MQ5 : MQ6))) );
        end
        else if(DEG==8)begin
            //wire [DEG-1:0]Q1;
            wire [DEG-1:0]R1;
            wire [DEG-1:0]MQ1;
            wire [DEG-1:0]mql_1;

            //wire [DEG-1:0]Q2;
            wire [DEG-1:0]R2;
            wire [DEG-1:0]MQ2;
            wire [DEG-1:0]mql_2;

            //wire [DEG-1:0]Q3;
            wire [DEG-1:0]R3;
            wire [DEG-1:0]MQ3;
            wire [DEG-1:0]mql_3;

            //wire [DEG-1:0]Q4;
            wire [DEG-1:0]R4;
            wire [DEG-1:0]MQ4;
            wire [DEG-1:0]mql_4;

            //wire [DEG-1:0]Q5;
            wire [DEG-1:0]R5;
            wire [DEG-1:0]MQ5;
            wire [DEG-1:0]mql_5;

            //wire [DEG-1:0]Q6;
            wire [DEG-1:0]R6;
            wire [DEG-1:0]MQ6;
            wire [DEG-1:0]mql_6;

            //wire [DEG-1:0]Q7;
            wire [DEG-1:0]R7;
            wire [DEG-1:0]MQ7;
            wire [DEG-1:0]mql_7;
            
            GF2k_inv_first #(DEG) D1 ( .DN(POLY) , .DR(IN) , .R(R1) , .MQ_out(MQ1) , .mql_out(mql_1) );
            GF2k_inv_small #(DEG) D2 ( .mql_in(MQ1) , .mqh_in(mql_1) , .DN(IN) , .DR(R1), .R(R2) , .MQ_out(MQ2) , .mql_out(mql_2) );
            GF2k_inv_small #(DEG) D3 ( .mql_in(MQ2) , .mqh_in(mql_2) , .DN(R1) , .DR(R2), .R(R3) , .MQ_out(MQ3) , .mql_out(mql_3) );
            GF2k_inv_small #(DEG) D4 ( .mql_in(MQ3) , .mqh_in(mql_3) , .DN(R2) , .DR(R3), .R(R4) , .MQ_out(MQ4) , .mql_out(mql_4) );
            GF2k_inv_small #(DEG) D5 ( .mql_in(MQ4) , .mqh_in(mql_4) , .DN(R3) , .DR(R4), .R(R5) , .MQ_out(MQ5) , .mql_out(mql_5) );
            GF2k_inv_small #(DEG) D6 ( .mql_in(MQ5) , .mqh_in(mql_5) , .DN(R4) , .DR(R5), .R(R6) , .MQ_out(MQ6) , .mql_out(mql_6) );
            GF2k_inv_small #(DEG) D7 ( .mql_in(MQ6) , .mqh_in(mql_6) , .DN(R5) , .DR(R6), .R(R7) , .MQ_out(MQ7) , .mql_out(mql_7) );

            assign RESULT = ( R1==1 ) ? MQ1 : (( R2==1 ) ? MQ2 : (( R3==1 ) ? MQ3 : (( R4==1 ) ? MQ4 : (( R5==1 ) ? MQ5 : (( R6==1 ) ? MQ6 : MQ7)))) );
        end
    endgenerate

endmodule



module GF2k_inv_first
#(parameter DEG = 2)
(
input  [DEG:0]   DN,
input  [DEG-1:0] DR,
//output [DEG-1:0] Q,
output [DEG-1:0] R,
output [DEG-1:0] MQ_out,
output [DEG-1:0] mql_out
);

    genvar i;
    generate
        for(i=0;i<DEG+1;i=i+1)begin:loop_A
            wire [2*DEG-1-i:0] a ;
            wire [2*DEG-1-i:0] b ;
            wire [DEG-1:0] mqh_temp;
            wire [DEG-1:0] MQ_temp;

            if(i==0) begin
                //assign a//DN
                assign a [2*DEG-1-i:DEG+1] = 0 ;
                assign a [DEG:0] = DN ;
                //assign b//DR
                assign b [2*DEG-1:DEG] = DR;
                assign b [DEG-1:0] = 0 ;

                //assign Q_a//
                //subtract
                
                assign mqh_temp = 0;
                assign MQ_temp = 0;
            end
            else begin
                //assign b//
                assign b = loop_A[i-1].b >> 1 ;
                //assign a//
                //subtract
                assign a = ((loop_A[i-1].a ^ loop_A[i-1].b) < loop_A[i-1].a) ? loop_A[i-1].a ^ loop_A[i-1].b : loop_A[i-1].a ;
                /* if(i!=DEG)begin
                    assign Q[DEG-i] = ((a ^ b)<a) ? 1 : 0 ;
                end */
                
                assign mqh_temp = ((a ^ b)<a) ? loop_A[i-1].MQ_temp : loop_A[i-1].mqh_temp ;
                assign MQ_temp = ((a ^ b)<a) ? ( mqh_temp ^ (1 << (DEG-i)) ) : loop_A[i-1].MQ_temp ;

                if(i==DEG)begin
                    assign R = ((a ^ b)<a) ? (a ^ b) : a ;
                    assign MQ_out = MQ_temp ;
                    assign mql_out = 1 ;
                end
            end
        end
    endgenerate

endmodule

module GF2k_inv_small
#(parameter DEG = 2)
(
input  [DEG-1:0] mql_in,
input  [DEG-1:0] mqh_in,
input  [DEG-1:0] DN,
input  [DEG-1:0] DR,
//output [DEG-1:0] Q,
output [DEG-1:0] R,
output [DEG-1:0] MQ_out,
output [DEG-1:0] mql_out
);

    genvar i;
    generate
        
        for(i=0;i<DEG;i=i+1)begin:loop_B
            wire [2*DEG-2-i:0] c ;
            wire [2*DEG-2-i:0] d ;
            wire [DEG-1:0] mqh_temp;
            wire [DEG-1:0] MQ_temp;

            
            if(i==0) begin
                //assign c//DN
                assign c [2*DEG-2:DEG] = 0 ;
                assign c [DEG-1:0] = DN ;
                //assign d//DR
                assign d [2*DEG-2:DEG-1] = DR [DEG-1:0] ;
                assign d [DEG-2:0] = 0 ;
                //assign Q_a//
                //subtract
                //assign Q[DEG-1] = ((c ^ d)<c) ? 1 : 0 ;

                assign mqh_temp=mqh_in;
                assign MQ_temp =mqh_in;
                
            end
            else begin
                //assign d//
                assign d = loop_B[i-1].d >> 1 ;
                //assign c//
                assign c = ((loop_B[i-1].c ^ loop_B[i-1].d) < loop_B[i-1].c) ? loop_B[i-1].c ^ loop_B[i-1].d : loop_B[i-1].c ;
                //subtract
                //assign Q[DEG-1-i] = ((c ^ d)<c) ? 1 : 0 ;
                

                assign mqh_temp = ((c ^ d)<c) ? loop_B[i-1].MQ_temp : loop_B[i-1].mqh_temp ;
                assign MQ_temp = ((c ^ d)<c) ? ( mqh_temp ^ (mql_in << (DEG-1-i)) ) : loop_B[i-1].MQ_temp ;

                if(i==DEG-1)begin
                    assign R = ((c ^ d)<c) ? (c ^ d) : c ;
                    assign MQ_out = MQ_temp ;
                    assign mql_out = mql_in ;
                end
            end
        end
    endgenerate

endmodule
//=======================================================