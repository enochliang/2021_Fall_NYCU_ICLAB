`include "../00_TESTBED/pseudo_DRAM.sv"
`include "Usertype_PKG.sv"

program automatic PATTERN(input clk, INF.PATTERN inf);
import usertype::*;

//================================
// Variables
//================================
// DRAM
parameter DRAM_p_r = "../00_TESTBED/DRAM/dram.dat";
logic [7:0] golden_DRAM [ ((65536+256*8)-1) : (65536+0) ];
logic [63:0] DRAM_out_temp;
logic [63:0] DRAM_in_temp;

// Variable
parameter PAT_NUM = 6000;
integer pat_cnt;
integer latency;
int gap;
integer t;
int i,j,id_cnt;

// tables
Money pokemon_sell_price;

Money    buy_price;
HP       pkm_buy_hp;
ATK      pkm_buy_atk;
Item_num item_vol;

logic    pkm_or_item;
ATK      role_origin_atk, def_origin_atk, use_bracer_atk;
HP       role_max_hp, def_max_hp;
logic [8:0] use_berry_hp;
EXP      role_full_exp, def_full_exp, use_candy_exp;
logic [8:0] role_act_atk;

EXP      role_earn_exp, def_earn_exp;

// Golden-compute
Player_id golden_id, golden_def_id;
Action    golden_act;
Item      golden_item;
PKM_Type  golden_type;
Money     golden_money;

Player_Info golden_role_info, golden_def_info;

// Golden-out
logic       golden_complete;
Player_Info golden_out_info;
Error_Msg   golden_err;

//================================
// Random Class
//================================

class random_money;
        rand Money ran_money;
        function new (int seed);
            this.srandom(seed);		
        endfunction 
        constraint range{
            // can't overflow
            ran_money inside{[0:65535]};
        }
endclass

class random_id;
        rand Player_id ran_id;
        function new (int seed);
            this.srandom(seed);		
        endfunction 
        constraint range{
            ran_id inside{[0:255]};
        }
endclass

class random_act;
        rand Action ran_act;
        function new (int seed);
            this.srandom(seed);		
        endfunction 
        constraint range{
            ran_act inside{Buy,Sell,Deposit,Use_item,Check,Attack};
        }
endclass

class random_item;
        rand Item ran_item;
        function new (int seed);
            this.srandom(seed);		
        endfunction 
        constraint range{
            ran_item inside{Berry,Medicine,Candy,Bracer};
        }
endclass

class random_type;
        rand PKM_Type ran_type;
        function new (int seed);
            this.srandom(seed);		
        endfunction 
        constraint range{
            ran_type inside{Grass,Fire,Water,Electric};
        }
endclass

class random_yes_no;
        randc logic ran_yn;
        function new (int seed);
            this.srandom(seed);		
        endfunction 
        constraint range{
            ran_yn inside{1,0};
        }
endclass

class random_in_gap;
        rand int ran_igap;
        function new (int seed);
            this.srandom(seed);		
        endfunction 
        constraint range{
            ran_igap inside{[1:5]};
        }
endclass

//================================
// Initial
//================================

initial $readmemh(DRAM_p_r,golden_DRAM);

random_money r_money = new(1);
random_id    r_id    = new(10);
random_act   r_act   = new(3);
random_item  r_item  = new(4);
random_type  r_type  = new(2);

random_yes_no r_yn   = new(5);
random_in_gap r_igap = new(7);

initial begin
    reset_task;

    @(negedge clk);


    //random-id random-action test
    for( pat_cnt = 0 ; pat_cnt < PAT_NUM ; pat_cnt = pat_cnt + 1 ) begin
        put_random_id;
        get_role_info;
        put_random_act;
        
        compute_task;
        
        check_out_task;
        
        $display("\033[0;32mYOU PASS random-id random-action test PATTERN NO.%03d\033[m",pat_cnt);
        
    end

    for( i = 0 ; i < 5 ; i = i + 1 )begin
        for( id_cnt = 0 ; id_cnt < 30 ; id_cnt = id_cnt + 1)begin
            golden_id = id_cnt;
            put_known_id;
            get_role_info;
            for( j = 0 ; j < 220 ; j = j + 1)begin
                
                golden_act = Buy;
                put_known_act;
                golden_item = Candy;
                put_known_item;

                compute_buy_item;
                check_out_task;
                

                golden_act = Use_item;
                put_known_act;
                golden_item = Candy;
                put_known_item;
                compute_use_item;

                check_out_task;
                $display("\033[0;32mYOU PASS all-in-medicine test PATTERN NO.%1d-%02d-%03d\033[m",i,id_cnt,j);
            end
            save_role_info;
        end
    end

    for( i = 0 ; i < 5 ; i = i + 1 )begin
        for( id_cnt = 0 ; id_cnt < 30 ; id_cnt = id_cnt + 1)begin
            golden_id = id_cnt;
            put_known_id;
            get_role_info;
            for( j = 0 ; j < 5 ; j = j + 1)begin
                
                golden_act = Buy;
                put_known_act;
                golden_type = Grass;
                put_known_type;

                compute_buy_pkm;
                check_out_task;
                
                $display("\033[0;32mYOU PASS buy many pokemons test PATTERN NO.%1d-%02d-%03d\033[m",i,id_cnt,j);
            end
            save_role_info;
        end
    end

    pass_task;
end


//=================================
// Tasks
//=================================
task reset_task;begin

    inf.D          = 0;
    inf.id_valid   = 0;
    inf.act_valid  = 0;
    inf.item_valid = 0;
    inf.type_valid = 0;
    inf.amnt_valid = 0;
    inf.rst_n = 1;

    #(1.5);  inf.rst_n = 0;

    #(20.0); inf.rst_n = 1;

end endtask

task put_known_id;begin
    t = r_igap.randomize();
    gap = r_igap.ran_igap;
    repeat(gap)@(negedge clk);

    inf.id_valid = 'd1;
    inf.D.d_id[0] = golden_id;
    @(negedge clk);
    inf.id_valid = 'd0;
    inf.D.d_id[0] = 'dx;
end endtask
task put_known_act;begin
    t = r_igap.randomize();
    gap = r_igap.ran_igap;

    repeat(gap)@(negedge clk);
    
    inf.act_valid = 'd1;
    inf.D.d_act[0] = golden_act;
    @(negedge clk);
    inf.act_valid = 'd0;
    inf.D.d_act[0] = 'dx;

end endtask
task put_known_item;begin
    t = r_igap.randomize();
    gap = r_igap.ran_igap;
    repeat(gap)@(negedge clk);
    
    inf.item_valid = 'd1;
    inf.D.d_item[0] = golden_item;
    @(negedge clk);
    inf.item_valid = 'd0;
    inf.D.d_item[0] = 'dx;

end endtask
task put_known_type;begin
    t = r_igap.randomize();
    gap = r_igap.ran_igap;
    repeat(gap)@(negedge clk);

    
    inf.type_valid = 'd1;
    inf.D.d_type[0] = golden_type;
    @(negedge clk);
    inf.type_valid = 'd0;
    inf.D.d_type[0] = 'dx;

end endtask


task put_random_id;begin
    t = r_igap.randomize();
    gap = r_igap.ran_igap;

    repeat(gap)@(negedge clk);
    
    t = r_id.randomize();
    golden_id = r_id.ran_id;
    
    inf.id_valid = 'd1;
    inf.D.d_id[0] = golden_id;
    @(negedge clk);
    inf.id_valid = 'd0;
    inf.D.d_id[0] = 'dx;

end endtask
task put_random_act;begin
    t = r_igap.randomize();
    gap = r_igap.ran_igap;

    repeat(gap)@(negedge clk);

    t = r_act.randomize();
    golden_act = r_act.ran_act;
    while( ((pokemon_sell_price + golden_role_info.bag_info.money) > 'hffff) && (golden_act === Sell) ) begin
        t = r_act.randomize();
        golden_act = r_act.ran_act;
    end
    
    inf.act_valid = 'd1;
    inf.D.d_act[0] = golden_act;
    @(negedge clk);
    inf.act_valid = 'd0;
    inf.D.d_act[0] = 'dx;

end endtask
task put_random_def_id;begin
    t = r_igap.randomize();
    gap = r_igap.ran_igap;
    repeat(gap)@(negedge clk);
    
    t = r_id.randomize();
    golden_def_id = r_id.ran_id;
    while(golden_def_id === golden_id) begin
        t = r_id.randomize();
        golden_def_id = r_id.ran_id;
    end
    
    inf.id_valid = 'd1;
    inf.D.d_id[0] = golden_def_id;
    @(negedge clk);
    inf.id_valid = 'd0;
    inf.D.d_id[0] = 'dx;

end endtask
task put_random_item;begin
    t = r_igap.randomize();
    gap = r_igap.ran_igap;
    repeat(gap)@(negedge clk);

    t = r_item.randomize();
    golden_item = r_item.ran_item;
    
    inf.item_valid = 'd1;
    inf.D.d_item[0] = golden_item;
    @(negedge clk);
    inf.item_valid = 'd0;
    inf.D.d_item[0] = 'dx;

end endtask
task put_random_type;begin
    t = r_igap.randomize();
    gap = r_igap.ran_igap;
    repeat(gap)@(negedge clk);

    t = r_type.randomize();
    golden_type = r_type.ran_type;
    
    inf.type_valid = 'd1;
    inf.D.d_type[0] = golden_type;
    @(negedge clk);
    inf.type_valid = 'd0;
    inf.D.d_type[0] = 'dx;

end endtask
task put_random_money;begin
    t = r_igap.randomize();
    gap = r_igap.ran_igap;
    repeat(gap)@(negedge clk);

    t = r_money.randomize();
    golden_money = r_money.ran_money;
    while((golden_money + golden_role_info.bag_info.money) > 'hffff) begin
        t = r_money.randomize();
        golden_money = r_money.ran_money;
    end

    inf.amnt_valid = 'd1;
    inf.D.d_money = golden_money;
    @(negedge clk);
    inf.amnt_valid = 'd0;
    inf.D.d_money = 'dx;

end endtask

// access DRAM info
task get_role_info;begin
    DRAM_out_temp = {golden_DRAM[ (65536+golden_id*8)+7 ],
                     golden_DRAM[ (65536+golden_id*8)+6 ],
                     golden_DRAM[ (65536+golden_id*8)+5 ],
                     golden_DRAM[ (65536+golden_id*8)+4 ],
                     golden_DRAM[ (65536+golden_id*8)+3 ],
                     golden_DRAM[ (65536+golden_id*8)+2 ],
                     golden_DRAM[ (65536+golden_id*8)+1 ],
                     golden_DRAM[ (65536+golden_id*8)+0 ]};
    golden_role_info = {DRAM_out_temp[7:0],
                        DRAM_out_temp[15:8],
                        DRAM_out_temp[23:16],
                        DRAM_out_temp[31:24],
                        DRAM_out_temp[39:32],
                        DRAM_out_temp[47:40],
                        DRAM_out_temp[55:48],
                        DRAM_out_temp[63:56]};
    
    case({golden_role_info.pkm_info.stage,golden_role_info.pkm_info.pkm_type})
		{Middle,Grass}    :pokemon_sell_price = 'd510;
		{Middle,Fire}     :pokemon_sell_price = 'd450;
		{Middle,Water}    :pokemon_sell_price = 'd500;
		{Middle,Electric} :pokemon_sell_price = 'd550;
		{Highest,Grass}   :pokemon_sell_price = 'd1100;
		{Highest,Fire}    :pokemon_sell_price = 'd1000;
		{Highest,Water}   :pokemon_sell_price = 'd1200;
		{Highest,Electric}:pokemon_sell_price = 'd1300;
		default :pokemon_sell_price = 'd0;
	endcase
    if(golden_role_info.pkm_info !== 0)begin
        get_role_origin_atk;
        golden_role_info.pkm_info.atk = role_origin_atk;
    end
    

end endtask
task get_def_info;begin
    DRAM_out_temp = {golden_DRAM[ (65536+golden_def_id*8)+7 ],
                     golden_DRAM[ (65536+golden_def_id*8)+6 ],
                     golden_DRAM[ (65536+golden_def_id*8)+5 ],
                     golden_DRAM[ (65536+golden_def_id*8)+4 ],
                     golden_DRAM[ (65536+golden_def_id*8)+3 ],
                     golden_DRAM[ (65536+golden_def_id*8)+2 ],
                     golden_DRAM[ (65536+golden_def_id*8)+1 ],
                     golden_DRAM[ (65536+golden_def_id*8)+0 ]};
    golden_def_info = {DRAM_out_temp[7:0],
                        DRAM_out_temp[15:8],
                        DRAM_out_temp[23:16],
                        DRAM_out_temp[31:24],
                        DRAM_out_temp[39:32],
                        DRAM_out_temp[47:40],
                        DRAM_out_temp[55:48],
                        DRAM_out_temp[63:56]};
    if(golden_def_info.pkm_info !== 0)begin
        get_def_origin_atk;
        golden_def_info.pkm_info.atk = def_origin_atk;
    end
    
end endtask
task save_role_info;begin
    {DRAM_in_temp[7:0],
     DRAM_in_temp[15:8],
     DRAM_in_temp[23:16],
     DRAM_in_temp[31:24],
     DRAM_in_temp[39:32],
     DRAM_in_temp[47:40],
     DRAM_in_temp[55:48],
     DRAM_in_temp[63:56]} = golden_role_info;

    {golden_DRAM[ (65536+golden_id*8)+7 ],
     golden_DRAM[ (65536+golden_id*8)+6 ],
     golden_DRAM[ (65536+golden_id*8)+5 ],
     golden_DRAM[ (65536+golden_id*8)+4 ],
     golden_DRAM[ (65536+golden_id*8)+3 ],
     golden_DRAM[ (65536+golden_id*8)+2 ],
     golden_DRAM[ (65536+golden_id*8)+1 ],
     golden_DRAM[ (65536+golden_id*8)+0 ]} = DRAM_in_temp;
end endtask
task save_def_info;begin
    {DRAM_in_temp[7:0],
     DRAM_in_temp[15:8],
     DRAM_in_temp[23:16],
     DRAM_in_temp[31:24],
     DRAM_in_temp[39:32],
     DRAM_in_temp[47:40],
     DRAM_in_temp[55:48],
     DRAM_in_temp[63:56]} = golden_def_info;
     
    {golden_DRAM[ (65536+golden_def_id*8)+7 ],
     golden_DRAM[ (65536+golden_def_id*8)+6 ],
     golden_DRAM[ (65536+golden_def_id*8)+5 ],
     golden_DRAM[ (65536+golden_def_id*8)+4 ],
     golden_DRAM[ (65536+golden_def_id*8)+3 ],
     golden_DRAM[ (65536+golden_def_id*8)+2 ],
     golden_DRAM[ (65536+golden_def_id*8)+1 ],
     golden_DRAM[ (65536+golden_def_id*8)+0 ]} = DRAM_in_temp;
end endtask

// get role or def detail info
task get_role_origin_atk;begin
    case({golden_role_info.pkm_info.stage,golden_role_info.pkm_info.pkm_type})
		{Lowest,Grass}    :role_origin_atk='d63 ;
		{Lowest,Fire}     :role_origin_atk='d64 ;
		{Lowest,Water}    :role_origin_atk='d60 ;
		{Lowest,Electric} :role_origin_atk='d65 ;
		{Middle,Grass}    :role_origin_atk='d94 ;
		{Middle,Fire}     :role_origin_atk='d96 ;
		{Middle,Water}    :role_origin_atk='d89 ;
		{Middle,Electric} :role_origin_atk='d97 ;
		{Highest,Grass}   :role_origin_atk='d123;
		{Highest,Fire}    :role_origin_atk='d127;
		{Highest,Water}   :role_origin_atk='d113;
		{Highest,Electric}:role_origin_atk='d124;
        default:role_origin_atk='d0;
	endcase
end endtask
task get_def_origin_atk;begin
    case({golden_def_info.pkm_info.stage,golden_def_info.pkm_info.pkm_type})
		{Lowest,Grass}    :def_origin_atk='d63 ;
		{Lowest,Fire}     :def_origin_atk='d64 ;
		{Lowest,Water}    :def_origin_atk='d60 ;
		{Lowest,Electric} :def_origin_atk='d65 ;
		{Middle,Grass}    :def_origin_atk='d94 ;
		{Middle,Fire}     :def_origin_atk='d96 ;
		{Middle,Water}    :def_origin_atk='d89 ;
		{Middle,Electric} :def_origin_atk='d97 ;
		{Highest,Grass}   :def_origin_atk='d123;
		{Highest,Fire}    :def_origin_atk='d127;
		{Highest,Water}   :def_origin_atk='d113;
		{Highest,Electric}:def_origin_atk='d124;
	endcase
end endtask
task get_role_max_hp;begin
    case({golden_role_info.pkm_info.stage,golden_role_info.pkm_info.pkm_type})
		{Lowest,Grass}    :role_max_hp='d128;
		{Lowest,Fire}     :role_max_hp='d119;
		{Lowest,Water}    :role_max_hp='d125;
		{Lowest,Electric} :role_max_hp='d122;
		{Middle,Grass}    :role_max_hp='d192;
		{Middle,Fire}     :role_max_hp='d177;
		{Middle,Water}    :role_max_hp='d187;
		{Middle,Electric} :role_max_hp='d182;
		{Highest,Grass}   :role_max_hp='d254;
		{Highest,Fire}    :role_max_hp='d225;
		{Highest,Water}   :role_max_hp='d245;
		{Highest,Electric}:role_max_hp='d235;
	endcase
end endtask
task get_def_max_hp;begin
    case({golden_def_info.pkm_info.stage,golden_def_info.pkm_info.pkm_type})
		{Lowest,Grass}    :def_max_hp='d128;
		{Lowest,Fire}     :def_max_hp='d119;
		{Lowest,Water}    :def_max_hp='d125;
		{Lowest,Electric} :def_max_hp='d122;
		{Middle,Grass}    :def_max_hp='d192;
		{Middle,Fire}     :def_max_hp='d177;
		{Middle,Water}    :def_max_hp='d187;
		{Middle,Electric} :def_max_hp='d182;
		{Highest,Grass}   :def_max_hp='d254;
		{Highest,Fire}    :def_max_hp='d225;
		{Highest,Water}   :def_max_hp='d245;
		{Highest,Electric}:def_max_hp='d235;
	endcase
end endtask
task get_role_full_exp;begin
    case({golden_role_info.pkm_info.stage,golden_role_info.pkm_info.pkm_type})
		{Lowest,Grass}    :role_full_exp='d31;
		{Lowest,Fire}     :role_full_exp='d29;
		{Lowest,Water}    :role_full_exp='d27;
		{Lowest,Electric} :role_full_exp='d25;
		{Middle,Grass}    :role_full_exp='d62;
		{Middle,Fire}     :role_full_exp='d58;
		{Middle,Water}    :role_full_exp='d54;
		{Middle,Electric} :role_full_exp='d50;
	endcase
end endtask
task get_def_full_exp;begin
    case({golden_def_info.pkm_info.stage,golden_def_info.pkm_info.pkm_type})
		{Lowest,Grass}    :def_full_exp='d31;
		{Lowest,Fire}     :def_full_exp='d29;
		{Lowest,Water}    :def_full_exp='d27;
		{Lowest,Electric} :def_full_exp='d25;
		{Middle,Grass}    :def_full_exp='d62;
		{Middle,Fire}     :def_full_exp='d58;
		{Middle,Water}    :def_full_exp='d54;
		{Middle,Electric} :def_full_exp='d50;
	endcase
end endtask
task get_role_act_atk;begin
    case({golden_role_info.pkm_info.pkm_type,golden_def_info.pkm_info.pkm_type})
		{Fire,Grass}:    role_act_atk = golden_role_info.pkm_info.atk << 1;
		{Water,Fire}:    role_act_atk = golden_role_info.pkm_info.atk << 1;
		{Electric,Water}:role_act_atk = golden_role_info.pkm_info.atk << 1;
		{Grass,Water}:   role_act_atk = golden_role_info.pkm_info.atk << 1;
		{Electric,Fire}: role_act_atk = golden_role_info.pkm_info.atk;
		{Water,Electric}:role_act_atk = golden_role_info.pkm_info.atk;
		{Fire,Electric}: role_act_atk = golden_role_info.pkm_info.atk;
		{Grass,Electric}:role_act_atk = golden_role_info.pkm_info.atk;
		default:         role_act_atk = golden_role_info.pkm_info.atk >> 1;
	endcase
end endtask

task get_role_earn_exp;begin
    case(golden_def_info.pkm_info.stage)
		Lowest :role_earn_exp = 'd16;
		Middle :role_earn_exp = 'd24;
		Highest:role_earn_exp = 'd32;
	endcase
end endtask
task get_def_earn_exp;begin
    case(golden_role_info.pkm_info.stage)
		Lowest :def_earn_exp = 'd8;
		Middle :def_earn_exp = 'd12;
		Highest:def_earn_exp = 'd16;
	endcase
end endtask


task compute_task;begin
    
    case(golden_act)
        Buy		:begin
            pkm_or_item = r_yn.ran_yn;
            if(!pkm_or_item)begin//buy pkm
                put_random_type;
                //compute
                compute_buy_pkm;
            end
            else begin//buy item
                put_random_item;
                //compute
                compute_buy_item;
            end
        end
        Sell	:begin
            //compute
            if(pokemon_sell_price === 0)begin // if you can't sell pkm.
                if(golden_role_info.pkm_info === 0) golden_err = Not_Having_PKM;
                else if(golden_role_info.pkm_info.stage === Lowest) golden_err = Has_Not_Grown;

                golden_out_info = 0;
                golden_complete = 0;
            end
            else begin
                golden_role_info.bag_info.money = golden_role_info.bag_info.money + pokemon_sell_price;
                golden_out_info = golden_role_info;
                golden_role_info.pkm_info = 'd0;

                golden_complete = 1;
                golden_err = No_Err;
            end
        end
        Deposit	:begin
            put_random_money;
            //compute
            golden_role_info.bag_info.money = golden_role_info.bag_info.money + golden_money;
            
            golden_out_info = golden_role_info;
            golden_complete = 1;
            golden_err = No_Err;
        end
        Use_item:begin
            put_random_item;
            //compute
            compute_use_item;
        end
        Check 	:begin
            //compute
            golden_out_info = golden_role_info;
            golden_complete = 1;
            golden_err = No_Err;
        end
        Attack  :begin
            put_random_def_id;
            get_def_info;
            //compute
            compute_attack;
            save_def_info;
        end
    endcase
    save_role_info;
end endtask


task compute_buy_pkm;begin

    case(golden_type)
        Grass:   begin
            pkm_buy_hp = 'd128;
            pkm_buy_atk = 'd63;
            buy_price = 'd100;
        end
        Fire:    begin
            pkm_buy_hp = 'd119;
            pkm_buy_atk = 'd64;
            buy_price = 'd90;
        end
        Water:   begin
            pkm_buy_hp = 'd125;
            pkm_buy_atk = 'd60;
            buy_price = 'd110;
        end
        Electric:begin
            pkm_buy_hp = 'd122;
            pkm_buy_atk = 'd65;
            buy_price = 'd120;
        end
    endcase


    if((golden_role_info.bag_info.money >= buy_price) && (golden_role_info.pkm_info === 0))begin
        golden_role_info.bag_info.money = golden_role_info.bag_info.money - buy_price;
        golden_role_info.pkm_info.stage = Lowest;
        golden_role_info.pkm_info.pkm_type = golden_type;
        golden_role_info.pkm_info.hp = pkm_buy_hp;
        golden_role_info.pkm_info.atk = pkm_buy_atk;
        golden_role_info.pkm_info.exp = 0;

        golden_err = No_Err;
        golden_complete = 1;

        //set output
        golden_out_info = golden_role_info;
    end
    else if(golden_role_info.bag_info.money < buy_price)begin
        golden_err = Out_of_money;
        golden_complete = 0;

        //set output
        golden_out_info = 0;
    end
    else begin
        golden_err = Already_Have_PKM;
        golden_complete = 0;

        //set output
        golden_out_info = 0;
    end

end endtask
task compute_buy_item;begin

    case(golden_item)
        Berry: begin
            buy_price = 'd16;
            item_vol = golden_role_info.bag_info.berry_num;
        end
        Medicine: begin
            buy_price = 'd128;
            item_vol = golden_role_info.bag_info.medicine_num;
        end
        Candy: begin
            buy_price = 'd300;
            item_vol = golden_role_info.bag_info.candy_num;
        end
        Bracer: begin
            buy_price = 'd64;
            item_vol = golden_role_info.bag_info.bracer_num;
        end
    endcase

    if(golden_role_info.bag_info.money < buy_price)begin // You don't have enough money.
        golden_err = Out_of_money;
        golden_complete = 0;

        // set output
        golden_out_info = 0;
    end
    else if(item_vol === 15)begin // Bag is full
        golden_err = Bag_is_full;
        golden_complete = 0;

        // set output
        golden_out_info = 0;
    end
    else begin // Buy item successfully
        golden_role_info.bag_info.money = golden_role_info.bag_info.money - buy_price;
        case(golden_item)
            Berry: golden_role_info.bag_info.berry_num = item_vol + 1;
            Medicine: golden_role_info.bag_info.medicine_num = item_vol + 1;
            Candy: golden_role_info.bag_info.candy_num = item_vol + 1;
            Bracer: golden_role_info.bag_info.bracer_num = item_vol + 1;
        endcase

        golden_err = No_Err;
        golden_complete = 1;

        // set output
        golden_out_info = golden_role_info;
    end

end endtask
task compute_use_item;begin
    get_role_origin_atk;
    get_role_max_hp;
    get_role_full_exp;
    
    case(golden_item)
        Berry:    item_vol = golden_role_info.bag_info.berry_num;
        Medicine: item_vol = golden_role_info.bag_info.medicine_num;
        Candy:    item_vol = golden_role_info.bag_info.candy_num;
        Bracer:   item_vol = golden_role_info.bag_info.bracer_num;
    endcase
    use_berry_hp = golden_role_info.pkm_info.hp + 'd32;
    use_bracer_atk = role_origin_atk + 'd32;
    use_candy_exp = golden_role_info.pkm_info.exp + 'd15;
    if((item_vol !== 0) && (golden_role_info.pkm_info !== 0))begin
        case(golden_item)
            Berry:    begin
                golden_role_info.bag_info.berry_num = item_vol - 1;
                if(use_berry_hp > role_max_hp) golden_role_info.pkm_info.hp = role_max_hp;
                else golden_role_info.pkm_info.hp = use_berry_hp;
            end
            Medicine: begin
                golden_role_info.bag_info.medicine_num = item_vol - 1;
                golden_role_info.pkm_info.hp = role_max_hp;
            end
            Candy:    begin
                golden_role_info.bag_info.candy_num = item_vol - 1;
                if( golden_role_info.pkm_info.stage !== Highest )begin //if pokemon is not highest stage, it's exp can be added.
                    if(use_candy_exp > role_full_exp) role_evolution;       // evolution.
                    else golden_role_info.pkm_info.exp = use_candy_exp;     // normal exp up.
                end
            end
            Bracer:   begin
                golden_role_info.bag_info.bracer_num = item_vol - 1;
                golden_role_info.pkm_info.atk = use_bracer_atk;
            end
        endcase
        
        golden_err = No_Err;
        golden_complete = 1;

        //set output
        golden_out_info = golden_role_info;
    end
    else if(golden_role_info.pkm_info === 0)begin //not complete
        golden_err = Not_Having_PKM;
        golden_complete = 0;

        //set output
        golden_out_info = 0;
    end
    else begin //not complete
        golden_err = Not_Having_Item;
        golden_complete = 0;

        //set output
        golden_out_info = 0;
    end
    
end endtask
task compute_attack;begin
    get_role_act_atk;
    get_role_origin_atk;

    get_role_full_exp;
    get_def_full_exp;

    get_role_earn_exp;
    get_def_earn_exp;

    if((golden_def_info.pkm_info === 0) || (golden_role_info.pkm_info === 0))begin
        golden_err = Not_Having_PKM;
        golden_complete = 0;

        //set output
        golden_out_info = 0;
    end
    else if((golden_def_info.pkm_info.hp === 0) || (golden_role_info.pkm_info.hp === 0))begin
        golden_err = HP_is_Zero;
        golden_complete = 0;

        //set output
        golden_out_info = 0;
    end
    else begin
        if(role_act_atk > golden_def_info.pkm_info.hp) golden_def_info.pkm_info.hp = 0;
        else golden_def_info.pkm_info.hp = golden_def_info.pkm_info.hp - role_act_atk;
        golden_role_info.pkm_info.atk = role_origin_atk;//restore attack power to original mode.

        if( golden_role_info.pkm_info.stage !== Highest )begin //if pokemon is not highest stage, it's exp can be added.
            if(golden_role_info.pkm_info.exp + role_earn_exp > role_full_exp) role_evolution;// role evolution
            else golden_role_info.pkm_info.exp = golden_role_info.pkm_info.exp + role_earn_exp;                              // role normal exp up.
        end
        if( golden_def_info.pkm_info.stage !== Highest )begin //if defender's pokemon is not highest stage, it's exp can be added.
            if(golden_def_info.pkm_info.exp + def_earn_exp > def_full_exp) def_evolution;// role evolution
            else golden_def_info.pkm_info.exp = golden_def_info.pkm_info.exp + def_earn_exp;// role normal exp up.
        end

        golden_err = No_Err;
        golden_complete = 1;
        

        //set output
        golden_out_info[63:32] = golden_role_info.pkm_info;
        golden_out_info[31:0] = golden_def_info.pkm_info;
    end
end endtask

task role_evolution;begin
    golden_role_info.pkm_info.exp = 0;
    if( golden_role_info.pkm_info.stage === Lowest ) golden_role_info.pkm_info.stage = Middle;
    else if( golden_role_info.pkm_info.stage === Middle ) golden_role_info.pkm_info.stage = Highest;
    get_role_origin_atk;
    get_role_max_hp;
    golden_role_info.pkm_info.hp = role_max_hp;
    golden_role_info.pkm_info.atk = role_origin_atk;
end endtask
task def_evolution;begin
    golden_def_info.pkm_info.exp = 0;
    if( golden_def_info.pkm_info.stage === Lowest ) golden_def_info.pkm_info.stage = Middle;
    else if( golden_def_info.pkm_info.stage === Middle ) golden_def_info.pkm_info.stage = Highest;
    get_def_origin_atk;
    get_def_max_hp;
    golden_def_info.pkm_info.hp = def_max_hp;
    golden_def_info.pkm_info.atk = def_origin_atk;
end endtask

task check_out_task; begin
    latency = 0;
    
    while(inf.out_valid === 0) begin
        @(negedge clk);
    end
    if(inf.out_valid === 1)begin
        if( !((inf.out_info === golden_out_info) && (inf.err_msg === golden_err) && (inf.complete === golden_complete)) )begin
            $display("==================================================================================");
            $display("             \033[0;31m                          Fail !!                \033[m                    ");
            $display("             \033[0;31m                       OUTPUT ERROR              \033[m                    ");
            $display("             \033[0;31m               YOURS  out:  %16h                 \033[m                    ",inf.out_info);
            $display("             \033[0;31m               GOLDEN out:  %16h                 \033[m                    ",golden_out_info);
            $display("             \033[0;31m               GOLDEN out:  stage: %1h type: %1h HP: %2h ATK: %2h EXP: %2h            \033[m                    ",
            golden_out_info.pkm_info.stage,
            golden_out_info.pkm_info.pkm_type,
            golden_out_info.pkm_info.hp,
            golden_out_info.pkm_info.atk,
            golden_out_info.pkm_info.exp);
            $display("             \033[0;31m                            berry: %1h medi: %1h ca: %1h bra: %1h mon: %4h            \033[m                    ",
            golden_out_info.bag_info.berry_num,
            golden_out_info.bag_info.medicine_num,
            golden_out_info.bag_info.candy_num,
            golden_out_info.bag_info.bracer_num,
            golden_out_info.bag_info.money);
            $display("             \033[0;31m               YOURS err :  %4b                  \033[m                    ",inf.err_msg);
            $display("             \033[0;31m               GOLDEN err:  %4b                  \033[m                    ",golden_err);
            $display("             \033[0;31m               YOURS complete :  %b              \033[m                    ",inf.complete);
            $display("             \033[0;31m               GOLDEN complete:  %b              \033[m                    ",golden_complete);
            $display("==================================================================================");

            $finish;
        end
    end
    @(negedge clk);
end endtask

//This task can be used when pass the pattern
task pass_task;
    $display("                                                             \033[33m`-                                                                            ");        
    $display("                                                             /NN.                                                                           ");        
    $display("                                                            sMMM+                                                                           ");        
    $display(" .``                                                       sMMMMy                                                                           ");        
    $display(" oNNmhs+:-`                                               oMMMMMh                                                                           ");        
    $display("  /mMMMMMNNd/:-`                                         :+smMMMh                                                                           ");        
    $display("   .sNMMMMMN::://:-`                                    .o--:sNMy                                                                           ");        
    $display("     -yNMMMM:----::/:-.                                 o:----/mo                                                                           ");        
    $display("       -yNMMo--------://:.                             -+------+/                                                                           ");        
    $display("         .omd/::--------://:`                          o-------o.                                                                           ");        
    $display("           `/+o+//::-------:+:`                       .+-------y                                                                            ");        
    $display("              .:+++//::------:+/.---------.`          +:------/+                                                                            ");        
    $display("                 `-/+++/::----:/:::::::::::://:-.     o------:s.          \033[37m:::::----.           -::::.          `-:////:-`     `.:////:-.    \033[33m");        
    $display("                    `.:///+/------------------:::/:- `o-----:/o          \033[37m.NNNNNNNNNNds-       -NNNNNd`       -smNMMMMMMNy   .smNNMMMMMNh    \033[33m");        
    $display("                         :+:----------------------::/:s-----/s.          \033[37m.MMMMo++sdMMMN-     `mMMmMMMs      -NMMMh+///oys  `mMMMdo///oyy    \033[33m");        
    $display("                        :/---------------------------:++:--/++           \033[37m.MMMM.   `mMMMy     yMMM:dMMM/     +MMMM:      `  :MMMM+`     `    \033[33m");        
    $display("                       :/---///:-----------------------::-/+o`           \033[37m.MMMM.   -NMMMo    +MMMs -NMMm.    .mMMMNdo:.     `dMMMNds/-`      \033[33m");        
    $display("                      -+--/dNs-o/------------------------:+o`            \033[37m.MMMMyyyhNMMNy`   -NMMm`  sMMMh     .odNMMMMNd+`   `+dNMMMMNdo.    \033[33m");        
    $display("                     .o---yMMdsdo------------------------:s`             \033[37m.MMMMNmmmdho-    `dMMMdooosMMMM+      `./sdNMMMd.    `.:ohNMMMm-   \033[33m");        
    $display("                    -yo:--/hmmds:----------------//:------o              \033[37m.MMMM:...`       sMMMMMMMMMMMMMN-  ``     `:MMMM+ ``      -NMMMs   \033[33m");        
    $display("                   /yssy----:::-------o+-------/h/-hy:---:+              \033[37m.MMMM.          /MMMN:------hMMMd` +dy+:::/yMMMN- :my+:::/sMMMM/   \033[33m");        
    $display("                  :ysssh:------//////++/-------sMdyNMo---o.              \033[37m.MMMM.         .mMMMs       .NMMMs /NMMMMMMMMmh:  -NMMMMMMMMNh/    \033[33m");        
    $display("                  ossssh:-------ddddmmmds/:----:hmNNh:---o               \033[37m`::::`         .::::`        -:::: `-:/++++/-.     .:/++++/-.      \033[33m");        
    $display("                  /yssyo--------dhhyyhhdmmhy+:---://----+-                                                                                  ");        
    $display("                  `yss+---------hoo++oosydms----------::s    `.....-.                                                                       ");        
    $display("                   :+-----------y+++++++oho--------:+sssy.://:::://+o.                                                                      ");        
    $display("                    //----------y++++++os/--------+yssssy/:--------:/s-                                                                     ");        
    $display("             `..:::::s+//:::----+s+++ooo:--------+yssssy:-----------++                                                                      ");        
    $display("           `://::------::///+/:--+soo+:----------ssssys/---------:o+s.``                                                                    ");        
    $display("          .+:----------------/++/:---------------:sys+----------:o/////////::::-...`                                                        ");        
    $display("          o---------------------oo::----------::/+//---------::o+--------------:/ohdhyo/-.``                                                ");        
    $display("          o---------------------/s+////:----:://:---------::/+h/------------------:oNMMMMNmhs+:.`                                           ");        
    $display("          -+:::::--------------:s+-:::-----------------:://++:s--::------------::://sMMMMMMMMMMNds/`                                        ");        
    $display("           .+++/////////////+++s/:------------------:://+++- :+--////::------/ydmNNMMMMMMMMMMMMMMmo`                                        ");        
    $display("             ./+oo+++oooo++/:---------------------:///++/-   o--:///////::----sNMMMMMMMMMMMMMMMmo.                                          ");        
    $display("                o::::::--------------------------:/+++:`    .o--////////////:--+mMMMMMMMMMMMMmo`                                            ");        
    $display("               :+--------------------------------/so.       +:-:////+++++///++//+mMMMMMMMMMmo`                                              ");        
    $display("              .s----------------------------------+: ````` `s--////o:.-:/+syddmNMMMMMMMMMmo`                                                ");        
    $display("              o:----------------------------------s. :s+/////--//+o-       `-:+shmNNMMMNs.                                                  ");        
    $display("             //-----------------------------------s` .s///:---:/+o.               `-/+o.                                                    ");        
    $display("            .o------------------------------------o.  y///+//:/+o`                                                                          ");        
    $display("            o-------------------------------------:/  o+//s//+++`                                                                           ");        
    $display("           //--------------------------------------s+/o+//s`                                                                                ");        
    $display("          -+---------------------------------------:y++///s                                                                                 ");        
    $display("          o-----------------------------------------oo/+++o                                                                                 ");        
    $display("         `s-----------------------------------------:s   ``                                                                                 ");        
    $display("          o-:::::------------------:::::-------------o.                                                                                     ");        
    $display("          .+//////////::::::://///////////////:::----o`                                                                                     ");        
    $display("          `:soo+///////////+++oooooo+/////////////:-//                                                                                      ");        
    $display("       -/os/--:++/+ooo:::---..:://+ooooo++///////++so-`                                                                                     ");        
    $display("      syyooo+o++//::-                 ``-::/yoooo+/:::+s/.                                                                                  ");        
    $display("       `..``                                `-::::///:++sys:                                                                                ");        
    $display("                                                    `.:::/o+  \033[37m                                                                              ");	
    $display("********************************************************************");
    $display("                        \033[0;38;5;219mCongratulations!\033[m      ");
    $display("                 \033[0;38;5;219mYou have passed all patterns!\033[m");
    $display("********************************************************************");
    $finish;
endtask

//This task can be used when fail the pattern
task fail_task; 
    $display("\033[33m	                                                         .:                                                                                         ");      
    $display("                                                   .:                                                                                                 ");
    $display("                                                  --`                                                                                                 ");
    $display("                                                `--`                                                                                                  ");
    $display("                 `-.                            -..        .-//-                                                                                      ");
    $display("                  `.:.`                        -.-     `:+yhddddo.                                                                                    ");
    $display("                    `-:-`             `       .-.`   -ohdddddddddh:                                                                                   ");
    $display("                      `---`       `.://:-.    :`- `:ydddddhhsshdddh-                       \033[31m.yhhhhhhhhhs       /yyyyy`       .yhhy`   +yhyo           \033[33m");
    $display("                        `--.     ./////:-::` `-.--yddddhs+//::/hdddy`                      \033[31m-MMMMNNNNNNh      -NMMMMMs       .MMMM.   sMMMh           \033[33m");
    $display("                          .-..   ////:-..-// :.:oddddho:----:::+dddd+                      \033[31m-MMMM-......     `dMMmhMMM/      .MMMM.   sMMMh           \033[33m");
    $display("                           `-.-` ///::::/::/:/`odddho:-------:::sdddh`                     \033[31m-MMMM.           sMMM/.NMMN.     .MMMM.   sMMMh           \033[33m");
    $display("             `:/+++//:--.``  .--..+----::://o:`osss/-.--------::/dddd/             ..`     \033[31m-MMMMysssss.    /MMMh  oMMMh     .MMMM.   sMMMh           \033[33m");
    $display("             oddddddddddhhhyo///.-/:-::--//+o-`:``````...------::dddds          `.-.`      \033[31m-MMMMMMMMMM-   .NMMN-``.mMMM+    .MMMM.   sMMMh           \033[33m");
    $display("            .ddddhhhhhddddddddddo.//::--:///+/`.````````..``...-:ddddh       `.-.`         \033[31m-MMMM:.....`  `hMMMMmmmmNMMMN-   .MMMM.   sMMMh           \033[33m");
    $display("            /dddd//::///+syhhdy+:-`-/--/////+o```````.-.......``./yddd`   `.--.`           \033[31m-MMMM.        oMMMmhhhhhhdMMMd`  .MMMM.   sMMMh```````    \033[33m");
    $display("            /dddd:/------:://-.`````-/+////+o:`````..``     `.-.``./ym.`..--`              \033[31m-MMMM.       :NMMM:      .NMMMs  .MMMM.   sMMMNmmmmmms    \033[33m");
    $display("            :dddd//--------.`````````.:/+++/.`````.` `.-      `-:.``.o:---`                \033[31m.dddd`       yddds        /dddh. .dddd`   +ddddddddddo    \033[33m");
    $display("            .ddddo/-----..`........`````..```````..  .-o`       `:.`.--/-      ``````````` \033[31m ````        ````          ````   ````     ``````````     \033[33m");
    $display("             ydddh/:---..--.````.`.-.````````````-   `yd:        `:.`...:` `................`                                                         ");
    $display("             :dddds:--..:.     `.:  .-``````````.:    +ys         :-````.:...```````````````..`                                                       ");
    $display("              sdddds:.`/`      ``s.  `-`````````-/.   .sy`      .:.``````-`````..-.-:-.````..`-                                                       ");
    $display("              `ydddd-`.:       `sh+   /:``````````..`` +y`   `.--````````-..---..``.+::-.-``--:                                                       ");
    $display("               .yddh``-.        oys`  /.``````````````.-:.`.-..`..```````/--.`      /:::-:..--`                                                       ");
    $display("                .sdo``:`        .sy. .:``````````````````````````.:```...+.``       -::::-`.`                                                         ");
    $display(" ````.........```.++``-:`        :y:.-``````````````....``.......-.```..::::----.```  ``                                                              ");
    $display("`...````..`....----:.``...````  ``::.``````.-:/+oosssyyy:`.yyh-..`````.:` ````...-----..`                                                             ");
    $display("                 `.+.``````........````.:+syhdddddddddddhoyddh.``````--              `..--.`                                                          ");
    $display("            ``.....--```````.```````.../ddddddhhyyyyyyyhhhddds````.--`             ````   ``                                                          ");
    $display("         `.-..``````-.`````.-.`.../ss/.oddhhyssssooooooossyyd:``.-:.         `-//::/++/:::.`                                                          ");
    $display("       `..```````...-::`````.-....+hddhhhyssoo+++//////++osss.-:-.           /++++o++//s+++/                                                          ");
    $display("     `-.```````-:-....-/-``````````:hddhsso++/////////////+oo+:`             +++::/o:::s+::o            \033[31m     `-/++++:-`                              \033[33m");
    $display("    `:````````./`  `.----:..````````.oysso+///////////////++:::.             :++//+++/+++/+-            \033[31m   :ymMMMMMMMMms-                            \033[33m");
    $display("    :.`-`..```./.`----.`  .----..`````-oo+////////////////o:-.`-.            `+++++++++++/.             \033[31m `yMMMNho++odMMMNo                           \033[33m");
    $display("    ..`:..-.`.-:-::.`        `..-:::::--/+++////////////++:-.```-`            +++++++++o:               \033[31m hMMMm-      /MMMMo  .ssss`/yh+.syyyyyyyyss. \033[33m");
    $display("     `.-::-:..-:-.`                 ```.+::/++//++++++++:..``````:`          -++++++++oo                \033[31m:MMMM:        yMMMN  -MMMMdMNNs-mNNNNNMMMMd` \033[33m");
    $display("        `   `--`                        /``...-::///::-.`````````.: `......` ++++++++oy-                \033[31m+MMMM`        +MMMN` -MMMMh:--. ````:mMMNs`  \033[33m");
    $display("           --`                          /`````````````````````````/-.``````.::-::::::/+                 \033[31m:MMMM:        yMMMm  -MMMM`       `oNMMd:    \033[33m");
    $display("          .`                            :```````````````````````--.`````````..````.``/-                 \033[31m dMMMm:`    `+MMMN/  -MMMN       :dMMNs`     \033[33m");
    $display("                                        :``````````````````````-.``.....````.```-::-.+                  \033[31m `yNMMMdsooymMMMm/   -MMMN     `sMMMMy/////` \033[33m");
    $display("                                        :.````````````````````````-:::-::.`````-:::::+::-.`             \033[31m   -smNMMMMMNNd+`    -NNNN     hNNNNNNNNNNN- \033[33m");
    $display("                                `......../```````````````````````-:/:   `--.```.://.o++++++/.           \033[31m      .:///:-`       `----     ------------` \033[33m");
    $display("                              `:.``````````````````````````````.-:-`      `/````..`+sssso++++:                                                        ");
    $display("                              :`````.---...`````````````````.--:-`         :-````./ysoooss++++.                                                       ");
    $display("                              -.````-:/.`.--:--....````...--:/-`            /-..-+oo+++++o++++.                                                       ");
    $display("             `:++/:.`          -.```.::      `.--:::::://:::::.              -:/o++++++++s++++                                                        ");
    $display("           `-+++++++++////:::/-.:.```.:-.`              :::::-.-`               -+++++++o++++.                                                        ");
    $display("           /++osoooo+++++++++:`````````.-::.             .::::.`-.`              `/oooo+++++.                                                         ");
    $display("           ++oysssosyssssooo/.........---:::               -:::.``.....`     `.:/+++++++++:                                                           ");
    $display("           -+syoooyssssssyo/::/+++++/+::::-`                 -::.``````....../++++++++++:`                                                            ");
    $display("             .:///-....---.-..-.----..`                        `.--.``````````++++++/:.                                                               ");
    $display("                                                                   `........-:+/:-.`                                                            \033[37m      ");
	$finish;
endtask

endprogram

