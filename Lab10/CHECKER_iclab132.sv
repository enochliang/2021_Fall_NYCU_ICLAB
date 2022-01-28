//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//
//   File Name   : CHECKER.sv
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module Checker(input clk, INF.CHECKER inf);
import usertype::*;

covergroup Spec1 @(negedge clk && inf.out_valid);
       coverpoint inf.out_info[31:28] {
              option.at_least = 20 ;
              bins stage0 = { 'd0 } ;
		bins stage1 = { 'd1 } ;
		bins stage2 = { 'd2 } ;
		bins stage3 = { 'd4 } ;
       }
       coverpoint inf.out_info[27:24] {
              option.at_least = 20 ;
              bins type0 = { 'd0 } ;
		bins type1 = { 'd1 } ;
		bins type2 = { 'd2 } ;
		bins type3 = { 'd4 } ;
              bins type4 = { 'd8 } ;
       }

endgroup : Spec1

covergroup Spec2 @(posedge clk && inf.id_valid);
   	coverpoint inf.D.d_id[0] {
   		option.at_least = 1 ;
   		option.auto_bin_max = 256 ;
   	}
endgroup : Spec2

covergroup Spec3 @(posedge clk && inf.act_valid);
   	coverpoint inf.D.d_act[0] {
   		option.at_least = 5 ;
   		bins act[] = (Buy, Sell, Deposit, Use_item, Check, Attack => Buy, Sell, Deposit, Use_item, Check, Attack ) ;
   	}
endgroup : Spec3

covergroup Spec4 @(negedge clk && inf.out_valid);
	coverpoint inf.complete {
		option.at_least = 200 ;
		bins b0 = { 1'b0 } ;
		bins b1 = { 1'b1 } ;
	}
endgroup : Spec4

covergroup Spec5 @(negedge clk && inf.out_valid);
	coverpoint inf.err_msg {
		option.at_least = 20 ;
		bins e1 = {Already_Have_PKM } ;	
		bins e2 = {Out_of_money} ;
		bins e3 = {Bag_is_full} ;
		bins e4 = {Not_Having_PKM} ;
              bins e5 = {Has_Not_Grown} ;
              bins e6 = {Not_Having_Item} ;
              bins e7 = {HP_is_Zero} ;
	}
endgroup : Spec5
//declare other cover group



//declare the cover group 
//Spec1 cov_inst_1 = new();
Spec1 Cov_1 = new();
Spec2 Cov_2 = new();
Spec3 Cov_3 = new();
Spec4 Cov_4 = new();
Spec5 Cov_5 = new();

//************************************ below assertion is to check your pattern ***************************************** 
//                                          Please finish and hand in it
// This is an example assertion given by TA, please write the required assertions below
//  assert_interval : assert property ( @(posedge clk)  inf.out_valid |=> inf.id_valid == 0 [*2])
//  else
//  begin
//  	$display("Assertion X is violated");
//  	$fatal; 
//  end

//write other assertions

// ASSERTION 1 (design)
always@(negedge inf.rst_n) begin
       #(1.0);
       Assertion_1 : assert ((inf.out_valid === 'd0) && (inf.err_msg === 'd0) && (inf.complete === 'd0) && (inf.out_info === 'd0))
       else begin
              $display("Assertion 1 is violated");
              $fatal;
       end
end

// ASSERTION 2 (design)
ASSERTION_2 : assert property ( @(posedge clk) ((inf.out_valid === 'd1) && (inf.complete === 1)) |-> (inf.err_msg === No_Err) )
else begin
	$display("Assertion 2 is violated");
	$fatal; 
end

// ASSERTION 3 (design)
ASSERTION_3 : assert property ( @(posedge clk) ((inf.out_valid === 'd1) && (inf.complete === 0)) |-> (inf.out_info === 'd0) )
else begin
	$display("Assertion 3 is violated");
	$fatal; 
end

logic first_id_flag;
logic in_flag, obj_flag, atk_flag, single_in_flag;
assign in_flag = ( inf.id_valid || inf.act_valid || inf.item_valid || inf.type_valid || inf.amnt_valid );
assign obj_flag = ( inf.item_valid || inf.type_valid || inf.amnt_valid );
assign atk_flag = ( inf.D.d_act[0] === Attack);
assign single_in_flag = ( inf.D.d_act[0] === Sell || inf.D.d_act[0] === Check);

always@(negedge inf.rst_n or posedge clk)begin
       if(!inf.rst_n) first_id_flag <= 1;
       else if(inf.act_valid) first_id_flag <= 0;
       else if(inf.out_valid)  first_id_flag <= 1;
end

// ASSERTION 4 (pattern)
ASSERTION_4_id_to_act : assert property ( @(posedge clk) ((inf.id_valid === 1) && (first_id_flag === 1))  |->  ##[1:5] ( in_flag === 0 ) ##1 ( inf.act_valid === 1 ) )
else begin
	$display("Assertion 4 is violated");
	$fatal;
end
ASSERTION_4_act_to_inst : assert property ( @(posedge clk) ( (inf.act_valid === 1) && !single_in_flag)  |->  ##[1:5] ( in_flag === 0 ) ##1 (( obj_flag === 1 ) || (inf.id_valid === 1)) )
else begin
	$display("Assertion 4 is violated");
	$fatal;
end

// ASSERTION 5 (pattern)
ASSERTION_5 : assert property ( @(posedge clk) ( $onehot({inf.id_valid, inf.act_valid, inf.item_valid, inf.type_valid, inf.amnt_valid}) || !in_flag ) )
else begin
	$display("Assertion 5 is violated");
	$fatal;
end

// ASSERTION 6 (design)
ASSERTION_6 : assert property ( @(posedge clk) ( inf.out_valid===1 ) |=> ( inf.out_valid===0 ) )
else begin
	$display("Assertion 6 is violated");
	$fatal;
end

// ASSERTION 7 inf.id_valid === 1 || inf.act_valid === 1
ASSERTION_7_1 : assert property ( @(posedge clk) ( inf.out_valid===1 )  |->  ##[2:10] (in_flag === 1) )
else begin
	$display("Assertion 7 is violated");
	$fatal;
end
ASSERTION_7_2 : assert property ( @(posedge clk) ( inf.out_valid===1 )  |=> !in_flag )
else begin
	$display("Assertion 7 is violated");
	$fatal;
end

// ASSERTION 8
ASSERTION_8_1 : assert property ( @(posedge clk) ( inf.act_valid===1 && single_in_flag===1 )  |=>  ##[1:1200] ( inf.out_valid===1 ) )
else begin
	$display("Assertion 8 is violated");
	$fatal;
end
ASSERTION_8_2 : assert property ( @(posedge clk) ( inf.id_valid===1 && first_id_flag===0 )  |=>  ##[1:1200] ( inf.out_valid===1 ) )
else begin
	$display("Assertion 8 is violated");
	$fatal;
end
ASSERTION_8_3 : assert property ( @(posedge clk) ( obj_flag===1 )  |=>  ##[1:1200] ( inf.out_valid===1 ) )
else begin
	$display("Assertion 8 is violated");
	$fatal;
end


endmodule