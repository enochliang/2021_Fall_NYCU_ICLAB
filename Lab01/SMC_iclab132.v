module SMC(
  // Input signals
    mode,
    W_0, V_GS_0, V_DS_0,
    W_1, V_GS_1, V_DS_1,
    W_2, V_GS_2, V_DS_2,
    W_3, V_GS_3, V_DS_3,
    W_4, V_GS_4, V_DS_4,
    W_5, V_GS_5, V_DS_5,   
  // Output signals
    out_n
);

//================================================================
//   INPUT AND OUTPUT DECLARATION                         
//================================================================
input [2:0] W_0, V_GS_0, V_DS_0;
input [2:0] W_1, V_GS_1, V_DS_1;
input [2:0] W_2, V_GS_2, V_DS_2;
input [2:0] W_3, V_GS_3, V_DS_3;
input [2:0] W_4, V_GS_4, V_DS_4;
input [2:0] W_5, V_GS_5, V_DS_5;
input [1:0] mode;
//output [8:0] out_n;         							// use this if using continuous assignment for out_n  // Ex: assign out_n = XXX;
output reg [9:0] out_n; 								// use this if using procedure assignment for out_n   // Ex: always@(*) begin out_n = XXX; end

//================================================================
//    Wire & Registers 
//================================================================
// Declare the wire/reg you would use in your circuit
// remember 
// wire for port connection and cont. assignment
// reg for proc. assignment
wire [9:0]line_A_0,line_A_1,line_A_2,line_A_3,line_A_4,line_A_5;
wire [9:0]line_B_0,line_B_1,line_B_2,line_B_3,line_B_4,line_B_5;
wire [9:0]line_out;

//================================================================
//    DESIGN
//================================================================
// --------------------------------------------------
// write your design here
// --------------------------------------------------
ID_gm_Calculation ID_gm_Calculation_A(.W_0(W_0),.V_GS_0(V_GS_0),.V_DS_0(V_DS_0),.output_line_0(line_A_0),
                                      .W_1(W_1),.V_GS_1(V_GS_1),.V_DS_1(V_DS_1),.output_line_1(line_A_1),
                                      .W_2(W_2),.V_GS_2(V_GS_2),.V_DS_2(V_DS_2),.output_line_2(line_A_2),
                                      .W_3(W_3),.V_GS_3(V_GS_3),.V_DS_3(V_DS_3),.output_line_3(line_A_3),
                                      .W_4(W_4),.V_GS_4(V_GS_4),.V_DS_4(V_DS_4),.output_line_4(line_A_4),
                                      .W_5(W_5),.V_GS_5(V_GS_5),.V_DS_5(V_DS_5),.output_line_5(line_A_5),.mode(mode[0]));

Sorting Sorting_A(.i0(line_A_0),.i1(line_A_1),.i2(line_A_2),.i3(line_A_3),.i4(line_A_4),.i5(line_A_5),
                  .n0(line_B_0),.n1(line_B_1),.n2(line_B_2),.n3(line_B_3),.n4(line_B_4),.n5(line_B_5));

MAX_min_Calculation MAX_min_Calculation_A(.mode(mode),.n0(line_B_0),.n1(line_B_1),.n2(line_B_2),.n3(line_B_3),.n4(line_B_4),.n5(line_B_5),.out_n(line_out));

always@(*)begin
out_n=line_out;
end

endmodule








//================================================================
//   SUB MODULE
//================================================================

// module BBQ (meat,vagetable,water,cost);
// input XXX;
// output XXX;
// 
// endmodule

// --------------------------------------------------
// Example for using submodule 
// BBQ bbq0(.meat(meat_0), .vagetable(vagetable_0), .water(water_0),.cost(cost[0]));
// --------------------------------------------------
// Example for continuous assignment
// assign out_n = XXX;
// --------------------------------------------------
// Example for procedure assignment
// always@(*) begin 
// 	out_n = XXX; 
// end
// --------------------------------------------------
// Example for case statement
// always @(*) begin
// 	case(op)
// 		2'b00: output_reg = a + b;
// 		2'b10: output_reg = a - b;
// 		2'b01: output_reg = a * b;
// 		2'b11: output_reg = a / b;
// 		default: output_reg = 0;
// 	endcase
// end
// --------------------------------------------------

//===== ID_gm_Calculation =====
module ID_gm_Calculation(W_0,V_GS_0,V_DS_0,output_line_0,
                         W_1,V_GS_1,V_DS_1,output_line_1,
                         W_2,V_GS_2,V_DS_2,output_line_2,
                         W_3,V_GS_3,V_DS_3,output_line_3,
                         W_4,V_GS_4,V_DS_4,output_line_4,
                         W_5,V_GS_5,V_DS_5,output_line_5,mode);

  input wire [2:0]W_0,V_GS_0,V_DS_0,W_1,V_GS_1,V_DS_1,W_2,V_GS_2,V_DS_2,W_3,V_GS_3,V_DS_3,W_4,V_GS_4,V_DS_4,W_5,V_GS_5,V_DS_5;
  input wire mode;
  output wire [9:0]output_line_0,output_line_1,output_line_2,output_line_3,output_line_4,output_line_5;

  wire [9:0]result_line_0,result_line_1,result_line_2,result_line_3,result_line_4,result_line_5;
  reg [9:0]result_0,result_1,result_2,result_3,result_4,result_5;

  assign output_line_0=result_0;
  assign output_line_1=result_1;
  assign output_line_2=result_2;
  assign output_line_3=result_3;
  assign output_line_4=result_4;
  assign output_line_5=result_5;

  ID_gm_Calculator_unit ID_gm_Calculator_unit_0(.w(W_0),.v_gs(V_GS_0),.v_ds(V_DS_0),.id_gm_select(mode),.result(result_line_0)),
                        ID_gm_Calculator_unit_1(.w(W_1),.v_gs(V_GS_1),.v_ds(V_DS_1),.id_gm_select(mode),.result(result_line_1)),
                        ID_gm_Calculator_unit_2(.w(W_2),.v_gs(V_GS_2),.v_ds(V_DS_2),.id_gm_select(mode),.result(result_line_2)),
                        ID_gm_Calculator_unit_3(.w(W_3),.v_gs(V_GS_3),.v_ds(V_DS_3),.id_gm_select(mode),.result(result_line_3)),
                        ID_gm_Calculator_unit_4(.w(W_4),.v_gs(V_GS_4),.v_ds(V_DS_4),.id_gm_select(mode),.result(result_line_4)),
                        ID_gm_Calculator_unit_5(.w(W_5),.v_gs(V_GS_5),.v_ds(V_DS_5),.id_gm_select(mode),.result(result_line_5));

  always@(*)begin
    result_0=result_line_0;
    result_1=result_line_1;
    result_2=result_line_2;
    result_3=result_line_3;
    result_4=result_line_4;
    result_5=result_line_5;
  end

endmodule


//===== ID_gm_Calculator_unit =====
module ID_gm_Calculator_unit (w,v_gs,v_ds,id_gm_select,result);

  input wire [2:0]w,v_gs,v_ds;
  input wire id_gm_select;
  output reg [9:0]result;
  
  wire [9:0]id,gm;

  id_Calculator id_Calculator_A(.w(w),.v_gs(v_gs),.v_ds(v_ds),.id(id));
  gm_Calculator gm_Calculator_A(.w(w),.v_gs(v_gs),.v_ds(v_ds),.gm(gm));

  always@(*)begin
    case(id_gm_select)
      1'b0:begin
        //gm
        result=gm;
      end
      1'b1:begin
        //id
        result=id;
      end 
    endcase	  
  end

endmodule


//===== id_Calculator =====
module id_Calculator (w,v_gs,v_ds,id);

  input wire [2:0]w,v_gs,v_ds;
  output reg [9:0]id;

  integer tmp_int;

  always@(*)
    if((v_gs-1)>v_ds)
      begin
        //Triode
        //tmp_int=$floor((w*(2*(v_gs-1)-v_ds)*v_ds)/3);
        //id=tmp_int;
        id=(w*(2*(v_gs-1)-v_ds)*v_ds)/3;
		//id=10'b0000000000;
      end
    else
      begin
        //Saturation
        //tmp_int=$floor((w*((v_gs-1)**2))/3);
        //id=tmp_int;
        id=(w*((v_gs-1)**2))/3;
		//id=10'b0000000000;
      end

endmodule


//===== gm_Calculator =====
module gm_Calculator (w,v_gs,v_ds,gm);

  input wire [2:0]w,v_gs,v_ds;
  output reg [9:0]gm;

  integer tmp_int;

  always@(*)
    if((v_gs-1)>v_ds)
      begin
        //Triode
        //tmp_int=$floor((2*w*v_ds)/3);
        //gm=tmp_int;
        gm=(2*w*v_ds)/3;
      end
    else
      begin
        //Saturation
        //tmp_int=$floor((2*w*(v_gs-1))/3);
        //gm=tmp_int;
        gm=(2*w*(v_gs-1))/3;
      end

endmodule


//===== Sorting =====
module Sorting(i0,i1,i2,i3,i4,i5,n0,n1,n2,n3,n4,n5);
  input wire [9:0]i0,i1,i2,i3,i4,i5;
  output wire [9:0]n0,n1,n2,n3,n4,n5;

  reg [9:0] tmp [0:5];
  reg [9:0] swp;
  integer i,j;

  assign n0=tmp[0];
  assign n1=tmp[1];
  assign n2=tmp[2];
  assign n3=tmp[3];
  assign n4=tmp[4];
  assign n5=tmp[5];


  always@(*)begin
    tmp[0]=i0;
    tmp[1]=i1;
    tmp[2]=i2;
    tmp[3]=i3;
    tmp[4]=i4;
    tmp[5]=i5;

    for (i=0;i<5;i=i+1)begin
      for (j=0;j<5-i;j=j+1)begin
        if(tmp[j]<tmp[j+1])begin
          swp=tmp[j];
		  tmp[j]=tmp[j+1];
          tmp[j+1]=swp;
          end
      end
    end
  end

endmodule



//===== MAX_min_Calculation =====
module MAX_min_Calculation(mode,n0,n1,n2,n3,n4,n5,out_n);

  input wire [1:0]mode;
  input wire [9:0]n0,n1,n2,n3,n4,n5;
  output reg [9:0]out_n;

  always@(*)begin
    case(mode)
      2'b00:out_n=n3+n4+n5;
      2'b01:out_n=(3*n3)+(4*n4)+(5*n5);
      2'b10:out_n=n0+n1+n2;
      2'b11:out_n=(3*n0)+(4*n1)+(5*n2);
	endcase
  end

endmodule