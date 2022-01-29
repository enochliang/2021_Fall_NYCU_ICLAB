//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2021 Final Project: Customized ISA Processor 
//   Author              : Hsi-Hao Huang
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : CPU.v
//   Module Name : CPU.v
//   Release version : V1.0 (Release Date: 2021-May)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module CPU(

				clk,
			  rst_n,
  
		   IO_stall,

         awid_m_inf,
       awaddr_m_inf,
       awsize_m_inf,
      awburst_m_inf,
        awlen_m_inf,
      awvalid_m_inf,
      awready_m_inf,
                    
        wdata_m_inf,
        wlast_m_inf,
       wvalid_m_inf,
       wready_m_inf,
                    
          bid_m_inf,
        bresp_m_inf,
       bvalid_m_inf,
       bready_m_inf,
                    
         arid_m_inf,
       araddr_m_inf,
        arlen_m_inf,
       arsize_m_inf,
      arburst_m_inf,
      arvalid_m_inf,
                    
      arready_m_inf, 
          rid_m_inf,
        rdata_m_inf,
        rresp_m_inf,
        rlast_m_inf,
       rvalid_m_inf,
       rready_m_inf 

);
// Input port
input  wire clk, rst_n;
// Output port
output reg  IO_stall;

parameter ID_WIDTH = 4 , ADDR_WIDTH = 32, DATA_WIDTH = 16, DRAM_NUMBER=2, WRIT_NUMBER=1;

// AXI Interface wire connecttion for pseudo DRAM read/write
/* Hint:
  your AXI-4 interface could be designed as convertor in submodule(which used reg for output signal),
  therefore I declared output of AXI as wire in CPU
*/

// axi write address channel 
output  wire [WRIT_NUMBER * ID_WIDTH-1:0]        awid_m_inf;
output  wire [WRIT_NUMBER * ADDR_WIDTH-1:0]    awaddr_m_inf;
output  wire [WRIT_NUMBER * 3 -1:0]            awsize_m_inf;
output  wire [WRIT_NUMBER * 2 -1:0]           awburst_m_inf;
output  wire [WRIT_NUMBER * 7 -1:0]             awlen_m_inf;
output  wire [WRIT_NUMBER-1:0]                awvalid_m_inf;
input   wire [WRIT_NUMBER-1:0]                awready_m_inf;
// axi write data channel 
output  wire [WRIT_NUMBER * DATA_WIDTH-1:0]     wdata_m_inf;
output  wire [WRIT_NUMBER-1:0]                  wlast_m_inf;
output  wire [WRIT_NUMBER-1:0]                 wvalid_m_inf;
input   wire [WRIT_NUMBER-1:0]                 wready_m_inf;
// axi write response channel
input   wire [WRIT_NUMBER * ID_WIDTH-1:0]         bid_m_inf;
input   wire [WRIT_NUMBER * 2 -1:0]             bresp_m_inf;
input   wire [WRIT_NUMBER-1:0]             	   bvalid_m_inf;
output  wire [WRIT_NUMBER-1:0]                 bready_m_inf;
// -----------------------------
// axi read address channel 
output  wire [DRAM_NUMBER * ID_WIDTH-1:0]       arid_m_inf;
output  wire [DRAM_NUMBER * ADDR_WIDTH-1:0]   araddr_m_inf;
output  wire [DRAM_NUMBER * 7 -1:0]            arlen_m_inf;
output  wire [DRAM_NUMBER * 3 -1:0]           arsize_m_inf;
output  wire [DRAM_NUMBER * 2 -1:0]          arburst_m_inf;
output  wire [DRAM_NUMBER-1:0]               arvalid_m_inf;
input   wire [DRAM_NUMBER-1:0]               arready_m_inf;
// -----------------------------
// axi read data channel 
input   wire [DRAM_NUMBER * ID_WIDTH-1:0]         rid_m_inf;
input   wire [DRAM_NUMBER * DATA_WIDTH-1:0]     rdata_m_inf;
input   wire [DRAM_NUMBER * 2 -1:0]             rresp_m_inf;
input   wire [DRAM_NUMBER-1:0]                  rlast_m_inf;
input   wire [DRAM_NUMBER-1:0]                 rvalid_m_inf;
output  wire [DRAM_NUMBER-1:0]                 rready_m_inf;
// -----------------------------

//
//
// 
/* Register in each core:
  There are sixteen registers in your CPU. You should not change the name of those registers.
  TA will check the value in each register when your core is not busy.
  If you change the name of registers below, you must get the fail in this lab.
*/

reg signed [15:0] core_r0 , core_r1 , core_r2 , core_r3 ;
reg signed [15:0] core_r4 , core_r5 , core_r6 , core_r7 ;
reg signed [15:0] core_r8 , core_r9 , core_r10, core_r11;
reg signed [15:0] core_r12, core_r13, core_r14, core_r15;





//###########################################
//
// Wrtie down your design below
//
//###########################################
wire [3:0]     page_cnnt;
wire [15:0] WB_data_cnnt;
wire        WB_done_cnnt;
wire      miss_flag_cnnt;
wire       add_addr_cnnt;

wire          inst_valid;
wire          data_valid;

wire [15:0]                    cur_inst;
wire [2:0]                  inst_opcode;
wire [3:0]    inst_rs, inst_rt, inst_rd;
wire                          inst_func;
wire signed [15:0]             inst_imm;
wire [15:0]                   inst_addr;
wire signed [15:0]         ram_data_out;
wire [15:0]               data_ram_addr;

wire        [1:0]          alu_op;
wire signed [15:0]        alu_out;
wire signed [11:0]       pc_add_1;
//####################################################
//               reg & wire
//####################################################
reg [2:0] state, next_state;
parameter core_IDLE  = 0;
parameter core_IF    = 1;
parameter core_ID    = 2;
parameter core_EX    = 3;
parameter core_MEM   = 4;
parameter core_FLUSH = 5;
parameter core_DONE  = 6;

reg signed [15:0] I1_reg, I2_reg, O_reg;

reg signed [11:0] pc, next_pc;
reg signed [15:0]  w_MEM_data;
reg           fetch_inst_flag;
reg        [3:0]      pat_cnt;

reg           fetch_data_flag;



//####################################################
//               MODULEs
//####################################################
Cache_inst C_inst(

                         .clk(clk),
                     .rst_n(rst_n),
                
        .in_valid(fetch_inst_flag),
                  .in_pc(pc[10:0]),
            .out_valid(inst_valid),
                .out_ins(cur_inst),

          .arid_m_inf(arid_m_inf[7:4]),
    .araddr_m_inf(araddr_m_inf[63:32]),
       .arlen_m_inf(arlen_m_inf[13:7]),
      .arsize_m_inf(arsize_m_inf[5:3]),
    .arburst_m_inf(arburst_m_inf[3:2]),
      .arvalid_m_inf(arvalid_m_inf[1]),
      .arready_m_inf(arready_m_inf[1]),

            .rid_m_inf(rid_m_inf[7:4]),
      .rdata_m_inf(rdata_m_inf[31:16]),
        .rresp_m_inf(rresp_m_inf[3:2]),
          .rlast_m_inf(rlast_m_inf[1]),
        .rvalid_m_inf(rvalid_m_inf[1]),
        .rready_m_inf(rready_m_inf[1])

);

Cache_data C_data(

                  .clk(clk),
              .rst_n(rst_n),

     .WB_done(WB_done_cnnt),
   .add_addr(add_addr_cnnt),
 .miss_flag(miss_flag_cnnt),
       .page_out(page_cnnt),
     .WB_data(WB_data_cnnt),
         
                     .in_valid(fetch_data_flag),
    .in_write(inst_opcode[1] && inst_opcode[0]),
                        .in_addr(data_ram_addr),
                            .in_dat(w_MEM_data),
                         .out_valid(data_valid),
                         .out_dat(ram_data_out),

          .arid_m_inf(arid_m_inf[3:0]),
     .araddr_m_inf(araddr_m_inf[31:0]),
        .arlen_m_inf(arlen_m_inf[6:0]),
      .arsize_m_inf(arsize_m_inf[2:0]),
    .arburst_m_inf(arburst_m_inf[1:0]),
      .arvalid_m_inf(arvalid_m_inf[0]),
      .arready_m_inf(arready_m_inf[0]),

            .rid_m_inf(rid_m_inf[3:0]),
       .rdata_m_inf(rdata_m_inf[15:0]),
        .rresp_m_inf(rresp_m_inf[1:0]),
          .rlast_m_inf(rlast_m_inf[0]),
        .rvalid_m_inf(rvalid_m_inf[0]),
        .rready_m_inf(rready_m_inf[0])

);

Write_Data_Bridge w_DRAM(
                   .clk(clk),
               .rst_n(rst_n),
  
  .miss_flag(miss_flag_cnnt),
            .page(page_cnnt),
      .WB_data(WB_data_cnnt),
         .done(WB_done_cnnt),
    .add_addr(add_addr_cnnt),
      
           awid_m_inf(awid_m_inf),
       awaddr_m_inf(awaddr_m_inf),
       awsize_m_inf(awsize_m_inf),
     awburst_m_inf(awburst_m_inf),
         awlen_m_inf(awlen_m_inf),
     awvalid_m_inf(awvalid_m_inf),
     awready_m_inf(awready_m_inf),
  
         wdata_m_inf(wdata_m_inf),
         wlast_m_inf(wlast_m_inf),
       wvalid_m_inf(wvalid_m_inf),
       wready_m_inf(wready_m_inf),
  
             bid_m_inf(bid_m_inf),
         bresp_m_inf(bresp_m_inf),
       bvalid_m_inf(bvalid_m_inf),
       bready_m_inf(bready_m_inf)
);

ALU alu(
  .Op(alu_op),
  .I1(I1_reg),
  .I2(I2_reg),
  .O(alu_out)
);

//####################################################
//               assign
//####################################################
assign inst_opcode = cur_inst[15:13];
assign     inst_rs = cur_inst[12:9];
assign     inst_rt = cur_inst[8:5];
assign     inst_rd = cur_inst[4:1];
assign   inst_func = cur_inst[0];
assign    inst_imm = {11{cur_inst[4]},cur_inst[4:0]};
assign   inst_addr = {3{cur_inst[12]},cur_inst[12:0]};

assign data_ram_addr = O_reg;

assign      alu_op = (inst_opcode[2:1] == 2'b00) ? {inst_opcode[0],inst_func} : 2'b00 ;
assign    pc_add_1 = pc + 1;
//####################################################
//               FSM
//####################################################

//state
always@(negedge rst_n or posedge clk)begin
  if(!rst_n) state <= core_IDLE;
  else       state <= next_state;
end
always@(*)begin
  case(state)
    core_IDLE:
      next_state = core_IF;
    core_IF  : begin
        if(inst_valid)begin
            if(inst_opcode == 3'b101)// J type end
                if({pat_cnt[3],pat_cnt[0]} == 2'b11)
                    next_state = core_FLUSH;
                else
                    next_state = core_DONE;
            else
                next_state = core_ID;
        end
        else
            next_state = core_IF;
    end
    core_ID  : begin
        if(inst_opcode[2])begin// beq end
            if({pat_cnt[3],pat_cnt[0]} == 2'b11)// pat_cnt == 9
                next_state = core_FLUSH;
            else
                next_state = core_DONE;
        end
        else if(inst_opcode[1])// load, store
            next_state = core_MEM;
        else
            next_state = core_EX;
    end
    core_EX  :begin
        if({pat_cnt[3],pat_cnt[0]} == 2'b11)// arith end
            next_state = core_FLUSH;
        else
            next_state = core_DONE;
    end
    core_MEM : begin// load, store end
        if(data_valid)begin
            if({pat_cnt[3],pat_cnt[0]} == 2'b11)// pat_cnt == 9
                next_state = core_FLUSH;
            else
                next_state = core_DONE;
        end
        else
            next_state = core_MEM;
    end
    core_FLUSH:begin
        if(data_valid)
            next_state = core_DONE;
        else
            next_state = core_FLUSH;
    end
    core_DONE:next_state = core_IF;
    default : next_state = state;
  endcase
end

//core_r
always@(negedge rst_n or posedge clk)begin
    if(!rst_n)begin
        core_r0  <= 0;
        core_r1  <= 0;
        core_r2  <= 0;
        core_r3  <= 0;
        core_r4  <= 0;
        core_r5  <= 0;
        core_r6  <= 0;
        core_r7  <= 0;
        core_r8  <= 0;
        core_r9  <= 0;
        core_r10 <= 0;
        core_r11 <= 0;
        core_r12 <= 0;
        core_r13 <= 0;
        core_r14 <= 0;
        core_r15 <= 0;
    end
    else begin
        if(state == core_EX)begin
            case(inst_rd)
                4'd0 : core_r0  <= O_reg;
                4'd1 : core_r1  <= O_reg;
                4'd2 : core_r2  <= O_reg;
                4'd3 : core_r3  <= O_reg;
                4'd4 : core_r4  <= O_reg;
                4'd5 : core_r5  <= O_reg;
                4'd6 : core_r6  <= O_reg;
                4'd7 : core_r7  <= O_reg;
                4'd8 : core_r8  <= O_reg;
                4'd9 : core_r9  <= O_reg;
                4'd10: core_r10 <= O_reg;
                4'd11: core_r11 <= O_reg;
                4'd12: core_r12 <= O_reg;
                4'd13: core_r13 <= O_reg;
                4'd14: core_r14 <= O_reg;
                4'd15: core_r15 <= O_reg;
            endcase
        end
        if((state == core_MEM) && data_valid)begin
            case(inst_rd)
                4'd0 : core_r0  <= ;
                4'd1 : core_r1  <= ;
                4'd2 : core_r2  <= ;
                4'd3 : core_r3  <= ;
                4'd4 : core_r4  <= ;
                4'd5 : core_r5  <= ;
                4'd6 : core_r6  <= ;
                4'd7 : core_r7  <= ;
                4'd8 : core_r8  <= ;
                4'd9 : core_r9  <= ;
                4'd10: core_r10 <= ;
                4'd11: core_r11 <= ;
                4'd12: core_r12 <= ;
                4'd13: core_r13 <= ;
                4'd14: core_r14 <= ;
                4'd15: core_r15 <= ;
            endcase
        end
    end
end

//I1_reg, I2_reg
always@(negedge rst_n or posedge clk)begin
  if(!rst_n)begin
    I1_reg <= 0;
    I2_reg <= 0;
  end
  else begin
    if(next_state == core_ID)begin
      if((inst_opcode[2:1] == 2'b00) || (inst_opcode == 3'b100))begin//arith or beq
        case(inst_rs)
          4'd0 : I1_reg <= core_r0 ;
          4'd1 : I1_reg <= core_r1 ;
          4'd2 : I1_reg <= core_r2 ;
          4'd3 : I1_reg <= core_r3 ;
          4'd4 : I1_reg <= core_r4 ;
          4'd5 : I1_reg <= core_r5 ;
          4'd6 : I1_reg <= core_r6 ;
          4'd7 : I1_reg <= core_r7 ;
          4'd8 : I1_reg <= core_r8 ;
          4'd9 : I1_reg <= core_r9 ;
          4'd10: I1_reg <= core_r10;
          4'd11: I1_reg <= core_r11;
          4'd12: I1_reg <= core_r12;
          4'd13: I1_reg <= core_r13;
          4'd14: I1_reg <= core_r14;
          4'd15: I1_reg <= core_r15;
        endcase
        case(inst_rt)
          4'd0 : I1_reg <= core_r0 ;
          4'd1 : I1_reg <= core_r1 ;
          4'd2 : I1_reg <= core_r2 ;
          4'd3 : I1_reg <= core_r3 ;
          4'd4 : I1_reg <= core_r4 ;
          4'd5 : I1_reg <= core_r5 ;
          4'd6 : I1_reg <= core_r6 ;
          4'd7 : I1_reg <= core_r7 ;
          4'd8 : I1_reg <= core_r8 ;
          4'd9 : I1_reg <= core_r9 ;
          4'd10: I1_reg <= core_r10;
          4'd11: I1_reg <= core_r11;
          4'd12: I1_reg <= core_r12;
          4'd13: I1_reg <= core_r13;
          4'd14: I1_reg <= core_r14;
          4'd15: I1_reg <= core_r15;
        endcase
      end
      if(inst_opcode[2:1] == 2'b01)begin//load, store
        case(inst_rs)
          4'd0 : I1_reg <= core_r0 ;
          4'd1 : I1_reg <= core_r1 ;
          4'd2 : I1_reg <= core_r2 ;
          4'd3 : I1_reg <= core_r3 ;
          4'd4 : I1_reg <= core_r4 ;
          4'd5 : I1_reg <= core_r5 ;
          4'd6 : I1_reg <= core_r6 ;
          4'd7 : I1_reg <= core_r7 ;
          4'd8 : I1_reg <= core_r8 ;
          4'd9 : I1_reg <= core_r9 ;
          4'd10: I1_reg <= core_r10;
          4'd11: I1_reg <= core_r11;
          4'd12: I1_reg <= core_r12;
          4'd13: I1_reg <= core_r13;
          4'd14: I1_reg <= core_r14;
          4'd15: I1_reg <= core_r15;
        endcase
        I2_reg <= inst_imm;
      end
    end
  end
end

//O_reg
always@(negedge rst_n or posedge clk)begin
  if(!rst_n)
    O_reg <= 0;
  else if ((next_state == core_EX) || (next_state == core_MEM))
    O_reg <= alu_out;
end

// pc
always@(negedge rst_n or posedge clk)begin
  if(!rst_n)
    pc <= 0;
  else if(next_state == core_IF)
    pc <= next_pc;
end
always@(*)begin
  if(inst_opcode[2:1] == 2'b10)begin
    if(inst_opcode[0])
      next_pc = {1'b0,inst_addr[10:1]};
    else begin
        if(inst_rs == inst_rt)
            next_pc = pc_add_1 + inst_imm;
        else
            next_pc = pc_add_1;
    end
  end
  else begin
    next_pc = pc_add_1;
  end
end

//w_MEM_data
always@(negedge rst_n or posedge clk)begin
  if(!rst_n) w_MEM_data <= 0;
  else if(inst_opcode == 3'b011)begin
    case(inst_rt)
      4'd0 : w_MEM_data <= core_r0 ;
      4'd1 : w_MEM_data <= core_r1 ;
      4'd2 : w_MEM_data <= core_r2 ;
      4'd3 : w_MEM_data <= core_r3 ;
      4'd4 : w_MEM_data <= core_r4 ;
      4'd5 : w_MEM_data <= core_r5 ;
      4'd6 : w_MEM_data <= core_r6 ;
      4'd7 : w_MEM_data <= core_r7 ;
      4'd8 : w_MEM_data <= core_r8 ;
      4'd9 : w_MEM_data <= core_r9 ;
      4'd10: w_MEM_data <= core_r10;
      4'd11: w_MEM_data <= core_r11;
      4'd12: w_MEM_data <= core_r12;
      4'd13: w_MEM_data <= core_r13;
      4'd14: w_MEM_data <= core_r14;
      4'd15: w_MEM_data <= core_r15;
    endcase
  end
end

//fetch_inst_flag
always@(negedge rst_n or posedge clk)begin
    if(!rst_n)
        fetch_inst_flag <= 0;
    else if((next_state == core_IF) && (state != core_IF))
        fetch_inst_flag <= 1;
    else if(fetch_inst_flag)
        fetch_inst_flag <= 0;
end

//pat_cnt
always@(negedge rst_n or posedge clk)begin
    if(!rst_n) pat_cnt <= 9;
    else if(next_state == core_DONE)begin
        if(pat_cnt[3] && pat_cnt[0])
            pat_cnt <= 0;
        else
            pat_cnt <= pat_cnt + 1;
    end
end

endmodule



module Cache_inst(

             clk;
           rst_n;

        in_valid;
           in_pc;
       out_valid;
         out_ins;

      arid_m_inf;
    araddr_m_inf;
     arlen_m_inf;
    arsize_m_inf;
   arburst_m_inf;
   arvalid_m_inf;
   arready_m_inf;

       rid_m_inf;
     rdata_m_inf;
     rresp_m_inf;
     rlast_m_inf;
    rvalid_m_inf;
    rready_m_inf;

);
  // global
  input   wire                clk;
  input   wire              rst_n;
  // core signal
  input   wire           in_valid;
  input   wire [10:0]       in_pc;
  output  reg           out_valid;
  output  reg  [15:0]     out_ins;

  // axi read address channel 
  output  wire [ID_WIDTH-1:0]        arid_m_inf;//fix
  output  wire [ADDR_WIDTH-1:0]    araddr_m_inf;
  output  wire [6:0]                arlen_m_inf;//fix
  output  wire [2:0]               arsize_m_inf;//fix
  output  wire [1:0]              arburst_m_inf;//fix
  output  wire                    arvalid_m_inf;
  input   wire                    arready_m_inf;
  // -----------------------------
  // axi read data channel 
  input   wire [ID_WIDTH-1:0]         rid_m_inf;
  input   wire [DATA_WIDTH-1:0]     rdata_m_inf;
  input   wire [1:0]                rresp_m_inf;
  input   wire                      rlast_m_inf;
  input   wire                     rvalid_m_inf;
  output  wire                     rready_m_inf;

  // wire
  wire [6:0]            read_addr;
  wire [15:0]       out_sram_data;//sram_d
  wire [15:0]        in_sram_data;//sram_d

  // FSM
  reg [2:0]     state, next_state;
  parameter cache_IDLE_empty  = 0;
  parameter cache_IDLE_ready  = 1;
  parameter cache_HIT         = 2;
  parameter cache_SEND_ADDR   = 3;
  parameter cache_WAIT_DRAM   = 4;
  parameter cache_OUTPUT      = 5;
  // register
  reg [3:0]                  page;
  reg [6:0]              cur_addr;

  

  RAISH SRAM_inst(.Q(out_sram_data),
                  .CLK(clk),
                  .CEN(1'b0),
                  .WEN(!((state == cache_WAIT_DRAM) && rvalid_m_inf)),
                  .A(read_addr),
                  .D(in_sram_data),
                  .OEN(1'b0)
                  );

  // assign
  assign arid_m_inf = 0;//fix
  assign araddr_m_inf = {20'h00001,page,cur_addr,1'b0};
  assign arlen_m_inf = 7'b1111111;//fix
  assign arsize_m_inf = 3'b001;//fix
  assign arburst_m_inf = 2'b01;//fix
  assign arvalid_m_inf = (state == cache_SEND_ADDR) ? 1 : 0 ;
  assign rready_m_inf = (state == cache_WAIT_DRAM) ? 1 : 0 ;
  assign read_addr = (next_state == cache_HIT) ? in_pc[6:0] : cur_addr;

  assign in_sram_data = rdata_m_inf;

  always@(negedge rst_n or posedge clk)begin
    if(!rst_n) state <= cache_IDLE_empty;
    else       state <= next_state;
  end
  always@(*)begin
    case(state)
      cache_IDLE_empty:begin
        if(in_valid)
          next_state = cache_SEND_ADDR;
        else
          next_state = cache_IDLE_empty;
      end
      cache_IDLE_ready:begin
        if(in_valid)begin
          if(in_pc[10:7] == page)
            next_state = cache_HIT;
          else
            next_state = cache_SEND_ADDR;
        end
        else next_state = cache_IDLE_ready;
      end
      cache_HIT: next_state = cache_OUTPUT;
      cache_SEND_ADDR:begin
        if(arready_m_inf)
          next_state = cache_WAIT_DRAM;
        else
          next_state = cache_SEND_ADDR;
      end
      cache_WAIT_DRAM:begin
        if(rlast_m_inf)
          next_state = cache_OUTPUT;
        else
          next_state = cache_WAIT_DRAM;
      end
      cache_OUTPUT: next_state = cache_IDLE_ready;
    endcase
  end

  //page
  always@(negedge rst_n or posedge clk)begin
    if(!rst_n)
      page <= 0;
    else if(next_state == cache_SEND_ADDR)
      page <= in_pc[10:7];
  end
  //cur_addr
  always@(negedge rst_n or posedge clk)begin
    if(!rst_n)
      cur_addr <= 0;
    else if(state == cache_WAIT_DRAM && rvalid_m_inf)
      cur_addr <= cur_addr + 1;
    else if(state == cache_OUTPUT)
      cur_addr <= 0;
  end
  //out_valid
  always@(negedge rst_n or posedge clk)begin
    if(!rst_n)
      out_valid <= 0;
    else if(next_state == cache_OUTPUT)
      out_valid <= 1;
    else
      out_valid <= 0;
  end
  //out_ins
  always@(negedge rst_n or posedge clk)begin
    if(!rst_n)
      out_ins <= 0;
    else if((state == cache_WAIT_DRAM) && rvalid_m_inf && (in_pc[6:0] == cur_addr))
      out_ins <= rdata_m_inf;
    else if(state == cache_HIT)
      out_ins <= out_sram_data;
  end

endmodule


module Cache_data(

             clk,
           rst_n,

         WB_done,
        add_addr,
       miss_flag,
        page_out,
         WB_data,

        in_flush,
        in_valid,
        in_write,
         in_addr,
          in_dat,
       out_valid,
         out_dat,

      arid_m_inf,
    araddr_m_inf,
     arlen_m_inf,
    arsize_m_inf,
   arburst_m_inf,
   arvalid_m_inf,
   arready_m_inf,

       rid_m_inf,
     rdata_m_inf,
     rresp_m_inf,
     rlast_m_inf,
    rvalid_m_inf,
    rready_m_inf

);
  // global
  input   wire                clk;
  input   wire              rst_n;
  // write_bridge signal
  input   wire            WB_done;
  input   wire           add_addr;
  output  wire          miss_flag;
  output  wire [3:0]     page_out;
  output  wire [15:0]     WB_data;
  // core signal
  input   wire           in_flush;
  input   wire           in_valid;
  input   wire           in_write;
  input   wire [10:0]     in_addr;
  input   wire [15:0]      in_dat;
  output  reg           out_valid;
  output  reg  [15:0]     out_dat;
  
  // axi read address channel 
  output  wire [ID_WIDTH-1:0]        arid_m_inf;//fix
  output  wire [ADDR_WIDTH-1:0]    araddr_m_inf;
  output  wire [6:0]                arlen_m_inf;//fix
  output  wire [2:0]               arsize_m_inf;//fix
  output  wire [1:0]              arburst_m_inf;//fix
  output  wire                    arvalid_m_inf;
  input   wire                    arready_m_inf;
  // -----------------------------
  // axi read data channel 
  input   wire [ID_WIDTH-1:0]         rid_m_inf;
  input   wire [DATA_WIDTH-1:0]     rdata_m_inf;
  input   wire [1:0]                rresp_m_inf;
  input   wire                      rlast_m_inf;
  input   wire                     rvalid_m_inf;
  output  wire                     rready_m_inf;

  // wire
  wire [6:0]            read_addr;
  wire [15:0]       out_sram_data;//sram_d
  wire [15:0]        in_sram_data;

  // FSM
  reg [2:0]     state, next_state;
  parameter cache_IDLE_empty  = 0;
  parameter cache_IDLE_ready  = 1;
  parameter cache_HIT         = 2;
  parameter cache_MISS        = 3;
  parameter cache_SEND_ADDR   = 4;
  parameter cache_WAIT_DRAM   = 5;
  parameter cache_OUTPUT      = 6;
  // register
  reg [3:0]                  page;
  reg [6:0]              cur_addr;
  reg                     rw_flag; //read:0, write:1

  
  RAISH SRAM_data(.Q(out_sram_data),
                  .CLK(clk),
                  .CEN(1'b0),
                  .WEN(!((state == cache_WAIT_DRAM) && rvalid_m_inf) || !((next_state == cache_HIT) && in_write)),
                  .A(read_addr),
                  .D(in_sram_data),
                  .OEN(1'b0)
                  );

  // assign
  assign miss_flag = (next_state == cache_MISS) ? 1 : 0;
  assign page_out = page;
  assign WB_data = out_sram_data;

  assign arid_m_inf    = 0;//fix
  assign araddr_m_inf  = {20'h00001,page,cur_addr,1'b0};
  assign arlen_m_inf   = 7'b1111111;//fix
  assign arsize_m_inf  = 3'b001;//fix
  assign arburst_m_inf = 2'b01;//fix
  assign arvalid_m_inf = (state == cache_SEND_ADDR) ? 1 : 0 ;

  assign rready_m_inf  = (state == cache_WAIT_DRAM) ? 1 : 0 ;

  assign read_addr     = (next_state == cache_HIT) ? in_addr[6:0] : cur_addr;
  assign in_sram_data  = (rw_flag && (cur_addr == in_addr[6:0])) ? in_dat : rdata_m_inf ;


  always@(negedge rst_n or posedge clk)begin
    if(!rst_n) state <= cache_IDLE_empty;
    else       state <= next_state;
  end
  always@(*)begin
    case(state)
      cache_IDLE_empty:begin
        if(in_valid)
          next_state = cache_SEND_ADDR;
        else
          next_state = cache_IDLE_empty;
      end
      cache_IDLE_ready:begin
        if(in_valid)begin
          if((in_addr[10:7] == page) && !in_flush)
            next_state = cache_HIT;
          else
            next_state = cache_MISS;
        end
        else next_state = cache_IDLE_ready;
      end
      cache_HIT: next_state = cache_OUTPUT;
      cache_MISS:begin
        if(WB_done)begin
          if(!in_flush)
            next_state = cache_SEND_ADDR;
          else
            next_state = cache_OUTPUT;
        end
        else
          next_state = cache_MISS;
      end
      cache_SEND_ADDR:begin
        if(arready_m_inf)
          next_state = cache_WAIT_DRAM;
        else
          next_state = cache_SEND_ADDR;
      end
      cache_WAIT_DRAM:begin
        if(rlast_m_inf)
          next_state = cache_OUTPUT;
        else
          next_state = cache_WAIT_DRAM;
      end
      cache_OUTPUT: next_state = cache_IDLE_ready;
      
      cache_HIT: next_state = cache_OUTPUT;
      cache_SEND_ADDR:
      default: next_state = state;
    endcase
  end

  //page
  always@(negedge rst_n or posedge clk)begin
    if(!rst_n)
      page <= 0;
    else if(next_state == cache_SEND_ADDR)
      page <= in_addr[10:7];
  end
  //cur_addr
  always@(negedge rst_n or posedge clk)begin
    if(!rst_n)
      cur_addr <= 0;
    else begin
      if(((state == cache_WAIT_DRAM) && rvalid_m_inf) || (state == cache_MISS && add_addr))
        cur_addr <= cur_addr + 1;
      if(state == cache_OUTPUT || (state == cache_MISS && WB_done))
        cur_addr <= 0;
    end
  end
  always@(posedge clk)begin
    if(in_valid) rw_flag <= in_write;
  end
  

  //out_valid
  always@(negedge rst_n or posedge clk)begin
    if(!rst_n)
      out_valid <= 0;
    else if(next_state == cache_OUTPUT)
      out_valid <= 1;
    else
      out_valid <= 0;
  end
  //out_ins
  always@(negedge rst_n or posedge clk)begin
    if(!rst_n)
      out_dat <= 0;
    else if((state == cache_WAIT_DRAM) && rvalid_m_inf && (in_addr[6:0] == cur_addr))
      out_dat <= rdata_m_inf;
    else if((state == cache_HIT) && !rw_flag)
      out_dat <= out_sram_data;
  end

endmodule


module Write_Data_Bridge(
                   clk,
                 rst_n,

             miss_flag,
                  page,
               WB_data,
                  done,
              add_addr,

            awid_m_inf,
          awaddr_m_inf,
          awsize_m_inf,
         awburst_m_inf,
           awlen_m_inf,
         awvalid_m_inf,
         awready_m_inf,

           wdata_m_inf,
           wlast_m_inf,
          wvalid_m_inf,
          wready_m_inf,

             bid_m_inf,
           bresp_m_inf,
          bvalid_m_inf,
          bready_m_inf
);
  // global
  input               clk;
  input             rst_n;

  input         miss_flag;
  input [3:0]        page;//from data_cache
  input [15:0]    WB_data;//from data_cache
  output             done;//to data_cache
  output         add_addr;//to data_cache

  // axi write address channel 
  output  wire [WRIT_NUMBER * ID_WIDTH-1:0]        awid_m_inf;//fix
  output  wire [WRIT_NUMBER * ADDR_WIDTH-1:0]    awaddr_m_inf;
  output  wire [WRIT_NUMBER * 3 -1:0]            awsize_m_inf;//fix
  output  wire [WRIT_NUMBER * 2 -1:0]           awburst_m_inf;//fix
  output  wire [WRIT_NUMBER * 7 -1:0]             awlen_m_inf;//fix
  output  wire [WRIT_NUMBER-1:0]                awvalid_m_inf;
  input   wire [WRIT_NUMBER-1:0]                awready_m_inf;
  // axi write data channel 
  output  wire [WRIT_NUMBER * DATA_WIDTH-1:0]     wdata_m_inf;
  output  wire [WRIT_NUMBER-1:0]                  wlast_m_inf;
  output  wire [WRIT_NUMBER-1:0]                 wvalid_m_inf;
  input   wire [WRIT_NUMBER-1:0]                 wready_m_inf;
  // axi write response channel
  input   wire [WRIT_NUMBER * ID_WIDTH-1:0]         bid_m_inf;
  input   wire [WRIT_NUMBER * 2 -1:0]             bresp_m_inf;
  input   wire [WRIT_NUMBER-1:0]             	   bvalid_m_inf;
  output  wire [WRIT_NUMBER-1:0]                 bready_m_inf;

  // register
  reg [1:0] state, next_state;
  parameter Bridge_IDLE      = 0;
  parameter Bridge_SEND_ADDR = 1;
  parameter Bridge_WRITEBACK = 2;
  parameter Bridge_WAIT_RESP = 3;

  reg [6:0] counter;

  // assign
  assign done = (state == Bridge_WAIT_RESP && bvalid_m_inf) ? 1 : 0;
  assign add_addr = ((next_state == Bridge_WRITEBACK) && (awready_m_inf || wready_m_inf)) ? 1 : 0;

  assign awid_m_inf = 0;//fix
  assign awaddr_m_inf = {20'h00001,page,7'd0,1'b0};
  assign awsize_m_inf = 3'b001;//fix
  assign awburst_m_inf = 2'b01;//fix
  assign awlen_m_inf = 7'b1111111;//fix
  assign awvalid_m_inf = (state == Bridge_WRITEBACK) ? 1 : 0;

  assign wdata_m_inf = WB_data;
  assign wlast_m_inf = (counter == 7'b1111111) ? 1 : 0;
  assign wvalid_m_inf = (state == Bridge_WRITEBACK) ? 1 : 0;

  assign bready_m_inf = (state == Bridge_WAIT_RESP) ? 1 : 0;

  // state
  always@(negedge rst_n or posedge clk)begin
    if(!rst_n) state <= Bridge_IDLE;
    else       state <= next_state;
  end
  // next_state
  always@(*)begin
    case(state)
      Bridge_IDLE:begin
        if(miss_flag)
          next_state = Bridge_SEND_ADDR;
        else
          next_state = Bridge_IDLE;
      end
      Bridge_SEND_ADDR:begin
        if(awready_m_inf)
          next_state = Bridge_WRITEBACK;
        else
          next_state = Bridge_SEND_ADDR;
      end
      Bridge_WRITEBACK:begin
        if(wready_m_inf && wlast_m_inf)
          next_state = Bridge_WAIT_RESP;
        else
          next_state = Bridge_WRITEBACK;
      end
      Bridge_WAIT_RESP:begin
        if(bvalid_m_inf)
          next_state = Bridge_IDLE;
        else
          next_state = Bridge_WAIT_RESP;
      end
      default: next_state = state;
    endcase
  end

  always@(negedge rst_n or posedge clk)begin
    if(!rst_n)
      counter <= 0;
    else if(wready_m_inf)
      counter <= counter + 1;
  end

endmodule

module ALU(
  Op,
  I1,
  I2,
  O,
)
  input             [1:0]  Op;
  input      signed [15:0] I1;//rs
  input      signed [15:0] I2;//rt
  output reg signed [15:0]  O;

  always@(*)begin
    case(Op)
      2'b00:
        O = I1 + I2 ;
      2'b01:
        O = I1 - I2 ;
      2'b10:begin
        if(I1<I2)
          O = 16'd1 ;
        else
          O = 16'd0 ;
      end
      2'b11:
        O = I1 * I2 ;
    endcase
  end

endmodule


