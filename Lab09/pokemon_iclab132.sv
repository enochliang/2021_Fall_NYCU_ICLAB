`include "Usertype_PKG.sv"

module pokemon(input clk, INF.pokemon_inf inf);
import usertype::*;


//================================================================
// logic 
//================================================================

// ### STATE REG ###
	state_t state;
	state_t next_state;
	bridge_state_t bridge_state, next_bridge_state;


// ### DATA REG ###
	DATA inst_s;
	Item inst_item;
	PKM_Type inst_type;
	Money inst_money;
	Player_id role_id_s, def_id_s;
	Player_Info role_info_s, def_info_s;
	logic change_flag;

// ### flags ###
	logic sell_flag, atk_flag, out_flag, bridge_flag;

// ### DATA WIRE ###
	PKM_Info new_grass, new_fire, new_water, new_electric;
	Item_num next_berry_num, next_medicine_num, next_candy_num, next_bracer_num;
	Money role_next_money,buy_item_money,buy_pkm_money;
	Money price_item, price_pkm, price_sell_pkm;
	HP use_berry_hp, use_medicine_hp, max_hp;
	ATK origin_atk, use_bracer_atk;
	logic [8:0] act_atk;
	EXP role_full_exp,def_full_exp,use_candy_exp;
	EXP role_earn_exp,def_earn_exp;

	//after battle
	EXP after_battle_atk_exp,after_battle_def_exp;
	HP after_atk_hp;
	ATK after_battle_role_atk,after_battle_def_atk;
	Stage after_battle_role_stage,after_battle_def_stage;

//  ### OUTPUT REG ###
/*	inf.err_msg, inf.complete, inf.out_valid, inf.out_info,
    inf.C_addr, inf.C_r_wb, inf.C_in_valid, inf.C_data_w     */





//================================================================
// design 
//================================================================

// ===== STATE REG =====

//state
always_ff@(negedge inf.rst_n or posedge clk) begin
	if(!inf.rst_n) state <= IDLE;
	else state <= next_state;
end
always_comb begin
	if(!inf.rst_n) next_state = IDLE;
	else begin
		case(state)
			BUY_item, BUY_pkg, SELL, DEPOSIT_money, CHECK, USE_item:begin
				if(bridge_state == COMPUTE) next_state = OUTPUTMODE;
				else next_state = state;
			end
			IDLE:begin
				if(inf.act_valid)begin
					case(inf.D.d_act[0])
						Buy     : next_state = BUY_wait;
						Sell    : next_state = SELL;
						Deposit : next_state = DEPOSIT_wait;
						Use_item: next_state = USE_wait;
						Check   : next_state = CHECK;
						Attack  : next_state = ATTACK_wait;
						default : next_state = state;
					endcase
				end
				else next_state = state;
			end
			BUY_wait          :begin
				if      (inf.item_valid)next_state = BUY_item;
				else if (inf.type_valid)next_state = BUY_pkg;
				else    next_state = state;
			end
			DEPOSIT_wait      :
				begin if(inf.amnt_valid) next_state = DEPOSIT_money;           else next_state = state; end
			USE_wait          :
				begin if(inf.item_valid) next_state = USE_item;                else next_state = state; end

			// wait for defender id
			ATTACK_wait       :
				begin if(inf.id_valid) next_state = ATTACK_prepare_opp;        else next_state = state; end

			// Wait for bridge ready for read defender info from DRAM.
			ATTACK_prepare_opp:
				begin if(bridge_state == COMPUTE) next_state = ATTACK_put_opp; else next_state = state; end

			// Put addr to bridge to read the defender info fom DRAM.
			ATTACK_put_opp    :next_state = ATTACK_wait_opp;

			// Wait for bridge to get the defender info. (when C_out_valid == 1, get the defender info from bridge)
			ATTACK_wait_opp   :begin if(inf.C_out_valid) next_state = ATTACK_opp;             else next_state = state; end

			// Attack the defender when bridge state is COMPUTE. End when the write back of defender info finished.
			ATTACK_opp        :begin if((bridge_state == WRITE_def_wait) && (inf.C_out_valid)) next_state = OUTPUTMODE;else next_state = state; end
			OUTPUTMODE        :begin
				if(inf.out_valid) next_state = IDLE;
				else next_state = state;
			end
			default:next_state = state;
		endcase
	end
end
//bridge_state
always_ff@(negedge inf.rst_n or posedge clk) begin
	if(!inf.rst_n) bridge_state <= IDLE_empty;
	else bridge_state <= next_bridge_state;
end
always_comb begin
	case(bridge_state)
		// IDLE without a role info.
		IDLE_empty:begin if(inf.id_valid)next_bridge_state = FETCH_role_wait; else next_bridge_state = bridge_state; end
		// IDLE with a role info.
		IDLE_hold:begin
			if(inf.id_valid)next_bridge_state = CHANGE_role_wait;
			else begin
				if((state == BUY_item)||(state == BUY_pkg)||(state == SELL)||(state == DEPOSIT_money)||(state == CHECK)||(state == USE_item)) next_bridge_state = COMPUTE;
				else next_bridge_state = bridge_state;
			end
		end
		// Write back the old role info to bridge, and waiting for bridge be finished.(flag == 0, put addr to bridge)
		CHANGE_role_wait:begin if(inf.C_out_valid)next_bridge_state = FETCH_role_put; else next_bridge_state = bridge_state; end
		// Putting addr to bridge to read the new role info.(1 cycle)
		FETCH_role_put:next_bridge_state = FETCH_role_wait;
		// Waiting for bridge reading the new role info from DRAM.
		FETCH_role_wait:begin if(inf.C_out_valid)next_bridge_state = COMPUTE; else next_bridge_state = bridge_state; end
		// Ready for compute after all fetch/store of info.
		COMPUTE:begin
			if((state == BUY_item) || (state == BUY_pkg) || (state == SELL) || (state == DEPOSIT_money) || (state == USE_item) || (state == CHECK)) next_bridge_state = IDLE_hold;
			else if(state == ATTACK_opp) next_bridge_state = WRITE_def_put;
			else next_bridge_state = bridge_state;
		end
		// Putting addr and defender info to bridge to write back the defender info.
		WRITE_def_put: begin
			if(!bridge_flag)next_bridge_state = WRITE_def_wait;
			else next_bridge_state = bridge_state;
		end
		// Waiting for bridge finishing the write back of defender info.
		WRITE_def_wait:begin if(inf.C_out_valid) next_bridge_state = IDLE_hold;else next_bridge_state = bridge_state; end
		default:next_bridge_state = bridge_state;
	endcase
end

always_ff@(posedge clk)begin
	if((bridge_state == COMPUTE) && (state == ATTACK_opp)) bridge_flag <= 1;
	if(bridge_flag) bridge_flag <= 0;
end

//---------------------



// ===== DATA REG =====

always_ff@(negedge inf.rst_n or posedge clk)begin
	if(!inf.rst_n) change_flag <= 0;
	else begin
		if(state == IDLE && inf.id_valid)change_flag <= 1;
		else if(state == OUTPUTMODE)change_flag <= 0;
	end
end
always_ff@(posedge clk)begin
	if(inf.type_valid)inst_type <= inf.D.d_type[0];
end
always_ff@(posedge clk)begin
	if(inf.item_valid)inst_item <= inf.D.d_item[0];
end
always_ff@(posedge clk)begin
	if(inf.amnt_valid)inst_money <= inf.D.d_money;
end
//role_id_s
always_ff@(posedge clk) begin
	if((state == IDLE) && inf.id_valid) role_id_s <= inf.D.d_id[0];
end
//def_id_s
always_ff@(posedge clk) begin
	if((state == ATTACK_wait) && inf.id_valid) def_id_s <= inf.D.d_id[0];
end

//role_info_s
always_ff@(posedge clk) begin
	case(bridge_state)
		FETCH_role_wait:begin
			// When we want to fetch a new role info, and bridge have done.
			if(inf.C_out_valid && change_flag)
				role_info_s <= {inf.C_data_r[7:0],
								inf.C_data_r[15:8],
								inf.C_data_r[23:16],
								inf.C_data_r[31:24],
								inf.C_data_r[39:32],
								inf.C_data_r[47:40],
								inf.C_data_r[55:48],
								inf.C_data_r[63:56]};
		end
		COMPUTE:begin
			// Computing
			case(state)

				BUY_item     :begin
					role_info_s.bag_info.money <= buy_item_money;

					if(inst_item == Berry)    role_info_s.bag_info.berry_num    <= next_berry_num;
					if(inst_item == Medicine) role_info_s.bag_info.medicine_num <= next_medicine_num;
					if(inst_item == Candy)    role_info_s.bag_info.candy_num    <= next_candy_num;
					if(inst_item == Bracer)   role_info_s.bag_info.bracer_num   <= next_bracer_num;
				end

				BUY_pkg      :begin
					role_info_s.bag_info.money <= buy_pkm_money;
					if(role_info_s.pkm_info == 0 && !(role_info_s.bag_info.money < price_pkm))begin
						if(inst_type == Grass)    role_info_s.pkm_info <= new_grass;
						if(inst_type == Fire)     role_info_s.pkm_info <= new_fire;
						if(inst_type == Water)    role_info_s.pkm_info <= new_water;
						if(inst_type == Electric) role_info_s.pkm_info <= new_electric;
					end
				end

				SELL         :begin

					role_info_s.bag_info.money <= price_sell_pkm + role_info_s.bag_info.money;

					if(price_sell_pkm != 0) role_info_s.pkm_info <= 0;

				end

				DEPOSIT_money:role_info_s.bag_info.money <= inst_money + role_info_s.bag_info.money;

				USE_item     :begin
					if(inst_item == Berry)   begin
						role_info_s.pkm_info.hp           <= use_berry_hp;
						role_info_s.bag_info.berry_num    <= next_berry_num;
					end
					if(inst_item == Medicine)begin
						role_info_s.pkm_info.hp           <= use_medicine_hp;
						role_info_s.bag_info.medicine_num <= next_medicine_num;
					end
					if(inst_item == Candy)   begin
						role_info_s.pkm_info.exp          <= use_candy_exp;
						role_info_s.bag_info.candy_num    <= next_candy_num;
						if((role_info_s.pkm_info.stage != Highest) && (role_info_s.pkm_info.exp + 15 > role_full_exp) && (role_info_s.bag_info.candy_num != 0))begin
							case(role_info_s.pkm_info.stage)
								Lowest:begin
									case(role_info_s.pkm_info.pkm_type)
										Grass:   begin role_info_s.pkm_info.hp <= 192; role_info_s.pkm_info.atk <= 94 ; end
										Fire:    begin role_info_s.pkm_info.hp <= 177; role_info_s.pkm_info.atk <= 96 ; end
										Water:   begin role_info_s.pkm_info.hp <= 187; role_info_s.pkm_info.atk <= 89 ; end
										Electric:begin role_info_s.pkm_info.hp <= 182; role_info_s.pkm_info.atk <= 97 ; end
										No_type: begin role_info_s.pkm_info.hp <= 0;   role_info_s.pkm_info.atk <= 0  ; end
									endcase
									role_info_s.pkm_info.stage <= Middle;
								end
								Middle:begin
									case(role_info_s.pkm_info.pkm_type)
										Grass:   begin role_info_s.pkm_info.hp <= 254; role_info_s.pkm_info.atk <= 123 ; end
										Fire:    begin role_info_s.pkm_info.hp <= 225; role_info_s.pkm_info.atk <= 127 ; end
										Water:   begin role_info_s.pkm_info.hp <= 245; role_info_s.pkm_info.atk <= 113 ; end
										Electric:begin role_info_s.pkm_info.hp <= 235; role_info_s.pkm_info.atk <= 124 ; end
										No_type: begin role_info_s.pkm_info.hp <= 0;   role_info_s.pkm_info.atk <= 0  ; end
									endcase
									role_info_s.pkm_info.stage <= Highest;
								end
							endcase
						end
					end
					if(inst_item == Bracer)  begin
						role_info_s.pkm_info.atk          <= use_bracer_atk;
						role_info_s.bag_info.bracer_num   <= next_bracer_num;
					end
				end

				ATTACK_opp   :begin
					role_info_s.pkm_info.exp <= after_battle_atk_exp;
					role_info_s.pkm_info.atk <= after_battle_role_atk;
					role_info_s.pkm_info.stage <= after_battle_role_stage;
					if((((role_info_s.pkm_info.stage != Highest) && (role_info_s.pkm_info.exp + role_earn_exp > role_full_exp))
					|| (role_info_s.pkm_info.stage == Highest)) && !((role_info_s.pkm_info.hp == 0) || (def_info_s.pkm_info.hp == 0)))begin
						case(role_info_s.pkm_info.stage)
							Lowest:begin
								case(role_info_s.pkm_info.pkm_type)
									Grass:   role_info_s.pkm_info.hp <= 192;
									Fire:    role_info_s.pkm_info.hp <= 177;
									Water:   role_info_s.pkm_info.hp <= 187;
									Electric:role_info_s.pkm_info.hp <= 182;
									No_type: role_info_s.pkm_info.hp <= 0;
								endcase
							end
							Middle:begin
								case(role_info_s.pkm_info.pkm_type)
									Grass:   role_info_s.pkm_info.hp <= 254;
									Fire:    role_info_s.pkm_info.hp <= 225;
									Water:   role_info_s.pkm_info.hp <= 245;
									Electric:role_info_s.pkm_info.hp <= 235;
									No_type: role_info_s.pkm_info.hp <= 0;
								endcase
							end
						endcase
					end
				end

			endcase
		end
	endcase
end

//def_info_s
always_ff@(posedge clk) begin
	if( (state == ATTACK_wait_opp) && inf.C_out_valid)
		def_info_s <= { inf.C_data_r[7:0],
						inf.C_data_r[15:8],
						inf.C_data_r[23:16],
						inf.C_data_r[31:24],
						inf.C_data_r[39:32],
						inf.C_data_r[47:40],
						inf.C_data_r[55:48],
						inf.C_data_r[63:56]};
	else if( ((bridge_state == COMPUTE) || (bridge_state == IDLE_hold)) && (state == ATTACK_opp)) begin
		def_info_s.pkm_info.exp <= after_battle_def_exp;
		def_info_s.pkm_info.hp <= after_atk_hp;
		def_info_s.pkm_info.atk <= after_battle_def_atk;
		def_info_s.pkm_info.stage <= after_battle_def_stage;
	end
end

//------------------------

// ===== OUTPUT REG =====

/*	inf.err_msg, inf.complete, inf.out_valid, inf.out_info,
    inf.C_addr, inf.C_r_wb, inf.C_in_valid, inf.C_data_w     */

// inf.err_msg, inf.complete, inf.out_valid, inf.out_info,
always_ff@(negedge inf.rst_n or posedge clk)begin
	if(!inf.rst_n) begin
		inf.err_msg <= No_Err;
		inf.complete <= 0;
		inf.out_info <= 0;
	end
	else begin
		if(bridge_state == COMPUTE)begin
			case(state)

				BUY_item     :begin
					if(role_info_s.bag_info.money < price_item) begin
						inf.err_msg <= Out_of_money;
						inf.complete <= 0;
						inf.out_info <= 0;
					end
					else if(((role_info_s.bag_info.berry_num == 15) && (inst_item == Berry))||
							((role_info_s.bag_info.medicine_num == 15) && (inst_item == Medicine))||
							((role_info_s.bag_info.candy_num == 15) && (inst_item == Candy))||
							((role_info_s.bag_info.bracer_num == 15) && (inst_item == Bracer))  )
							begin
								inf.err_msg <= Bag_is_full;
								inf.complete <= 0;
								inf.out_info <= 0;
							end
					else begin
						inf.err_msg <= No_Err;
						inf.complete <= 1;
					end
				end

				BUY_pkg      :begin
					if(role_info_s.bag_info.money < price_pkm)begin
						inf.err_msg <= Out_of_money;
						inf.complete <= 0;
						inf.out_info <= 0;
					end
					else if(role_info_s.pkm_info != 0)begin
						inf.err_msg <= Already_Have_PKM;
						inf.complete <= 0;
						inf.out_info <= 0;
					end
					else begin
						inf.err_msg <= No_Err;
						inf.complete <= 1;
					end
				end

				SELL         :begin
					if(role_info_s.pkm_info == 0)begin
						inf.err_msg <= Not_Having_PKM;
						inf.complete <= 0;
						inf.out_info <= 0;
					end
					else if(role_info_s.pkm_info.stage == Lowest)begin
						inf.err_msg <= Has_Not_Grown;
						inf.complete <= 0;
						inf.out_info <= 0;
					end
					else begin
						inf.err_msg <= No_Err;
						inf.complete <= 1;
						inf.out_info[31:0] <= role_info_s.pkm_info;
					end
				end

				USE_item     :begin
					if(role_info_s.pkm_info == 0)begin
						inf.err_msg <= Not_Having_PKM;
					end
					else if(((role_info_s.bag_info.berry_num == 0) && (inst_item == Berry))||
							((role_info_s.bag_info.medicine_num == 0) && (inst_item == Medicine))||
							((role_info_s.bag_info.candy_num == 0) && (inst_item == Candy))||
							((role_info_s.bag_info.bracer_num == 0) && (inst_item == Bracer))  )
							begin
								inf.err_msg <= Not_Having_Item;
							end
					else begin
						inf.err_msg <= No_Err;
					end
				end

				ATTACK_opp   :begin
					if(role_info_s.pkm_info == 0 || def_info_s.pkm_info == 0) begin
						inf.err_msg <= Not_Having_PKM;
					end
					else if(role_info_s.pkm_info.hp == 0 || def_info_s.pkm_info.hp == 0) begin
						inf.err_msg <= HP_is_Zero;
					end
					else begin
						inf.err_msg <= No_Err;
					end
				end

				default : inf.err_msg <= No_Err;

			endcase
		end
		if((state == OUTPUTMODE) && !out_flag && !sell_flag)begin
			//if no error
			if(inf.err_msg == No_Err)begin
				if(!atk_flag)inf.out_info <= role_info_s;
				else inf.out_info <= {role_info_s.pkm_info,def_info_s.pkm_info};
				inf.complete <= 1;
			end
			//if error
			else begin
				inf.complete <= 0;
				inf.out_info <= 0;
			end
		end
		if((state == OUTPUTMODE) && !out_flag && sell_flag)begin
			//if no error
			if(inf.err_msg == No_Err) inf.out_info[63:32] <= role_info_s.bag_info;
		end
	end
end

always_ff@(negedge inf.rst_n or posedge clk)begin
	if(!inf.rst_n)begin
		inf.out_valid <= 0;
	end
	else begin
		if(state == OUTPUTMODE && !out_flag) inf.out_valid <= 1;
		else inf.out_valid <= 0;
	end
end


always_ff@(posedge clk)begin
	if(state == IDLE) sell_flag <= 0;
	if(state == SELL) sell_flag <= 1;
end
always_ff@(posedge clk)begin
	if(state == IDLE) atk_flag <= 0;
	if(state == ATTACK_opp) atk_flag <= 1;
end
always_ff@(posedge clk)begin
	if(state == OUTPUTMODE) out_flag <= 1;
	else out_flag <= 0;
end

always_ff@(negedge inf.rst_n or posedge clk)begin
	if(!inf.rst_n) begin
		inf.C_addr <= 0;
		inf.C_r_wb <= 0;
		inf.C_in_valid <= 0;
		inf.C_data_w <= 0;
	end
	else begin
		// read role from
		if((bridge_state == IDLE_empty) && inf.id_valid)begin
			inf.C_addr <= inf.D.d_id[0];
			inf.C_r_wb <= 1;
			inf.C_in_valid <= 1;
			inf.C_data_w <= 0;
		end
		if((bridge_state == CHANGE_role_wait) && inf.C_out_valid)begin
			inf.C_addr <= role_id_s;
			inf.C_r_wb <= 1;
			inf.C_in_valid <= 1;
			inf.C_data_w <= 0;
		end

		// read defender info signal
		if(state == ATTACK_prepare_opp && bridge_state == COMPUTE)begin
			inf.C_addr <= def_id_s;
			inf.C_r_wb <= 1;
			inf.C_in_valid <= 1;
			inf.C_data_w <= 0;
		end

		// write back old role
		if((bridge_state == IDLE_hold) && inf.id_valid)begin
			inf.C_addr <= role_id_s;
			inf.C_r_wb <= 0;
			inf.C_in_valid <= 1;
			{inf.C_data_w[7:0],
			inf.C_data_w[15:8],
			inf.C_data_w[23:16],
			inf.C_data_w[31:24],
			inf.C_data_w[39:32],
			inf.C_data_w[47:40],
			inf.C_data_w[55:48],
			inf.C_data_w[63:56]} <= {role_info_s[63:16],origin_atk,role_info_s[7:0]};//{role_info_s.bag_info, role_info_s.pkm_info.stage, role_info_s.pkm_info.pkm_type, role_info_s.pkm_info.hp, origin_atk, role_info_s.pkm_info.exp};
		end

		//write back def
		if((bridge_state == WRITE_def_put) && bridge_flag)begin
			inf.C_addr <= def_id_s;
			inf.C_r_wb <= 0;
			inf.C_in_valid <= 1;
			{inf.C_data_w[7:0],
			inf.C_data_w[15:8],
			inf.C_data_w[23:16],
			inf.C_data_w[31:24],
			inf.C_data_w[39:32],
			inf.C_data_w[47:40],
			inf.C_data_w[55:48],
			inf.C_data_w[63:56]} <= def_info_s;
		end

		if(inf.C_in_valid) inf.C_in_valid <= 0;
	end
end



// ----------------------

// ===== DATA WIRE =====

//---pkm_info---
//new_grass, new_fire, new_water, new_electric;
always_comb begin
	new_grass.stage = Lowest;
	new_grass.pkm_type = Grass;
	new_grass.hp = 'd128;
	new_grass.atk = 'd63;
	new_grass.exp = 'd0;
	new_fire.stage = Lowest;
	new_fire.pkm_type = Fire;
	new_fire.hp = 'd119;
	new_fire.atk = 'd64;
	new_fire.exp = 'd0;
	new_water.stage = Lowest;
	new_water.pkm_type = Water;
	new_water.hp = 'd125;
	new_water.atk = 'd60;
	new_water.exp = 'd0;
	new_electric.stage = Lowest;
	new_electric.pkm_type = Electric;
	new_electric.hp = 'd122;
	new_electric.atk = 'd65;
	new_electric.exp = 'd0;
end

//---item_num---
//next_berry_num, next_medicine_num, next_candy_num, next_bracer_num;
always_comb begin
	case(state)
		BUY_item:begin
			if(role_info_s.bag_info.money < 'd16) next_berry_num = role_info_s.bag_info.berry_num;
			else if(role_info_s.bag_info.berry_num == 'd15) next_berry_num = 'd15;
			else next_berry_num = role_info_s.bag_info.berry_num + 1;
		end
		USE_item:begin
			if(role_info_s.pkm_info == 0) next_berry_num = role_info_s.bag_info.berry_num;
			else if(role_info_s.bag_info.berry_num == 'd0) next_berry_num = 'd0;
			else next_berry_num = role_info_s.bag_info.berry_num - 1;
		end
		default:next_berry_num = role_info_s.bag_info.berry_num;
	endcase
end
always_comb begin
	case(state)
		BUY_item:begin
			if(role_info_s.bag_info.money < 'd128) next_medicine_num = role_info_s.bag_info.medicine_num;
			else if(role_info_s.bag_info.medicine_num == 'd15) next_medicine_num = 'd15;
			else next_medicine_num = role_info_s.bag_info.medicine_num + 1;
		end
		USE_item:begin
			if(role_info_s.pkm_info == 0) next_medicine_num = role_info_s.bag_info.medicine_num;
			else if(role_info_s.bag_info.medicine_num == 'd0) next_medicine_num = 'd0;
			else next_medicine_num = role_info_s.bag_info.medicine_num - 1;
		end
		default:next_medicine_num = role_info_s.bag_info.medicine_num;
	endcase

end
always_comb begin
	case(state)
		BUY_item:begin
			if(role_info_s.bag_info.money < 'd300) next_candy_num = role_info_s.bag_info.candy_num;
			else if(role_info_s.bag_info.candy_num == 'd15) next_candy_num = 'd15;
			else next_candy_num = role_info_s.bag_info.candy_num + 1;
		end
		USE_item:begin
			if(role_info_s.pkm_info == 0) next_candy_num = role_info_s.bag_info.candy_num;
			else if(role_info_s.bag_info.candy_num == 'd0) next_candy_num = 'd0;
			else next_candy_num = role_info_s.bag_info.candy_num - 1;
		end
		default:next_candy_num = role_info_s.bag_info.candy_num;
	endcase
end
always_comb begin
	case(state)
		BUY_item:begin
			if(role_info_s.bag_info.money < 'd64) next_bracer_num = role_info_s.bag_info.bracer_num;
			else if(role_info_s.bag_info.bracer_num == 'd15) next_bracer_num = 'd15;
			else next_bracer_num = role_info_s.bag_info.bracer_num + 1;
		end
		USE_item:begin
			if(role_info_s.pkm_info == 0) next_bracer_num = role_info_s.bag_info.bracer_num;
			else if(role_info_s.bag_info.bracer_num == 'd0) next_bracer_num = 'd0;
			else next_bracer_num = role_info_s.bag_info.bracer_num - 1;
		end
		default:next_bracer_num = role_info_s.bag_info.bracer_num;
	endcase
end

//---money---
//buy_item_money
always_comb begin
	// if you don't have enough money to buy an item
	if(role_info_s.bag_info.money < price_item)
		buy_item_money = role_info_s.bag_info.money;
	else if(((role_info_s.bag_info.berry_num == 15) && (inst_item == Berry))||
			((role_info_s.bag_info.medicine_num == 15) && (inst_item == Medicine))||
			((role_info_s.bag_info.candy_num == 15) && (inst_item == Candy))||
			((role_info_s.bag_info.bracer_num == 15) && (inst_item == Bracer))  )
		buy_item_money = role_info_s.bag_info.money;
	// buy an item
	else 
		buy_item_money = role_info_s.bag_info.money - price_item;
end
//buy_pkm_money
always_comb begin
	// if you don't have enough money to buy a pkm
	if(role_info_s.bag_info.money < price_pkm)
		buy_pkm_money = role_info_s.bag_info.money;
	else if(role_info_s.pkm_info != 0)
		buy_pkm_money = role_info_s.bag_info.money;
	// buy an item
	else
		buy_pkm_money = role_info_s.bag_info.money - price_pkm;
end
//price_item
always_comb begin
	case(inst_item)
		Berry   :price_item = 'd16;
		Medicine:price_item = 'd128;
		Candy   :price_item = 'd300;
		Bracer  :price_item = 'd64;
		default :price_item = 'd0;
	endcase
end
//price_pkm
always_comb begin
	case(inst_type)
		Grass   :price_pkm = 'd100;
		Fire    :price_pkm = 'd90;
		Water   :price_pkm = 'd110;
		Electric:price_pkm = 'd120;
		default :price_pkm = 'd0;
	endcase
end
//price_sell_pkm
always_comb begin
	case({role_info_s.pkm_info.stage,role_info_s.pkm_info.pkm_type})
		{Middle,Grass}    :price_sell_pkm = 'd510;
		{Middle,Fire}     :price_sell_pkm = 'd450;
		{Middle,Water}    :price_sell_pkm = 'd500;
		{Middle,Electric} :price_sell_pkm = 'd550;
		{Highest,Grass}   :price_sell_pkm = 'd1100;
		{Highest,Fire}    :price_sell_pkm = 'd1000;
		{Highest,Water}   :price_sell_pkm = 'd1200;
		{Highest,Electric}:price_sell_pkm = 'd1300;
		default :price_sell_pkm = 'd0;
	endcase
end

//---hp---
//after_atk_hp(attack:defender)
always_comb begin
	if((role_info_s.pkm_info.hp == 0) || (def_info_s.pkm_info.hp == 0)) after_atk_hp = def_info_s.pkm_info.hp; // If someone has no HP.
	else if(((def_info_s.pkm_info.stage != Highest) && (def_info_s.pkm_info.exp + def_earn_exp > def_full_exp)))begin
		case(def_info_s.pkm_info.stage)
			Lowest:begin
				case(def_info_s.pkm_info.pkm_type)
					Grass:   after_atk_hp = 192;
					Fire:    after_atk_hp = 177;
					Water:   after_atk_hp = 187;
					Electric:after_atk_hp = 182;
					default: after_atk_hp = 0;
				endcase
			end
			Middle:begin
				case(def_info_s.pkm_info.pkm_type)
					Grass:   after_atk_hp = 254;
					Fire:    after_atk_hp = 225;
					Water:   after_atk_hp = 245;
					Electric:after_atk_hp = 235;
					default: after_atk_hp = 0;
				endcase
			end
			default: after_atk_hp = def_info_s.pkm_info.hp;
		endcase
	end
	else if(def_info_s.pkm_info.hp < act_atk) after_atk_hp = 0;
	else after_atk_hp = def_info_s.pkm_info.hp - act_atk;
end
//use_berry_hp(use_berry:role)
always_comb begin
	if(role_info_s.bag_info.berry_num == 'd0) use_berry_hp = role_info_s.pkm_info.hp; // If you don't have any berries.
	else if(role_info_s.pkm_info.hp + 'd32 > max_hp) use_berry_hp = max_hp;
	else use_berry_hp = role_info_s.pkm_info.hp + 'd32;
end
//use_medicine_hp
always_comb begin
	if(role_info_s.bag_info.medicine_num == 'd0) use_medicine_hp = role_info_s.pkm_info.hp; // If you don't have any medicines.
	else use_medicine_hp = max_hp;
end
//max_hp(use_berry,use_medicine:role)
always_comb begin
	case({role_info_s.pkm_info.stage,role_info_s.pkm_info.pkm_type})
		{Lowest,Grass}    :max_hp='d128;
		{Lowest,Fire}     :max_hp='d119;
		{Lowest,Water}    :max_hp='d125;
		{Lowest,Electric} :max_hp='d122;
		{Middle,Grass}    :max_hp='d192;
		{Middle,Fire}     :max_hp='d177;
		{Middle,Water}    :max_hp='d187;
		{Middle,Electric} :max_hp='d182;
		{Highest,Grass}   :max_hp='d254;
		{Highest,Fire}    :max_hp='d225;
		{Highest,Water}   :max_hp='d245;
		{Highest,Electric}:max_hp='d235;
		default:max_hp='d0;
	endcase
end

//---atk---
//act_atk
//(attack;The actual demage to the defender)
always_comb begin
	case({role_info_s.pkm_info.pkm_type,def_info_s.pkm_info.pkm_type})
		{Fire,Grass}    :act_atk = role_info_s.pkm_info.atk << 1;
		{Water,Fire}    :act_atk = role_info_s.pkm_info.atk << 1;
		{Electric,Water}:act_atk = role_info_s.pkm_info.atk << 1;
		{Grass,Water}   :act_atk = role_info_s.pkm_info.atk << 1;
		{Electric,Fire} :act_atk = role_info_s.pkm_info.atk;
		{Water,Electric}:act_atk = role_info_s.pkm_info.atk;
		{Fire,Electric} :act_atk = role_info_s.pkm_info.atk;
		{Grass,Electric}:act_atk = role_info_s.pkm_info.atk;
		default:act_atk = role_info_s.pkm_info.atk >> 1;
	endcase
end
//origin_atk
//(attack;The origin point of attack power without any bracer)
always_comb begin
	case({role_info_s.pkm_info.stage,role_info_s.pkm_info.pkm_type})
		{Lowest,Grass}    :origin_atk='d63 ;
		{Lowest,Fire}     :origin_atk='d64 ;
		{Lowest,Water}    :origin_atk='d60 ;
		{Lowest,Electric} :origin_atk='d65 ;
		{Middle,Grass}    :origin_atk='d94 ;
		{Middle,Fire}     :origin_atk='d96 ;
		{Middle,Water}    :origin_atk='d89 ;
		{Middle,Electric} :origin_atk='d97 ;
		{Highest,Grass}   :origin_atk='d123;
		{Highest,Fire}    :origin_atk='d127;
		{Highest,Water}   :origin_atk='d113;
		{Highest,Electric}:origin_atk='d124;
		default:origin_atk='d0;
	endcase
end
//use_bracer_atk
always_comb begin
	if((role_info_s.pkm_info == 0) || (role_info_s.bag_info.bracer_num == 'd0) || (role_info_s.pkm_info.atk > origin_atk)) use_bracer_atk = role_info_s.pkm_info.atk; // If you have use a bracer or you don't have any bracers.
	else  use_bracer_atk = role_info_s.pkm_info.atk + 'd32;
end

//role_full_exp
always_comb begin
	case({role_info_s.pkm_info.stage,role_info_s.pkm_info.pkm_type})
		{Lowest,Grass}    :role_full_exp='d31;
		{Lowest,Fire}     :role_full_exp='d29;
		{Lowest,Water}    :role_full_exp='d27;
		{Lowest,Electric} :role_full_exp='d25;
		{Middle,Grass}    :role_full_exp='d62;
		{Middle,Fire}     :role_full_exp='d58;
		{Middle,Water}    :role_full_exp='d54;
		{Middle,Electric} :role_full_exp='d50;
		default:role_full_exp='d0;
	endcase
end
//def_full_exp
always_comb begin
	case({def_info_s.pkm_info.stage,def_info_s.pkm_info.pkm_type})
		{Lowest,Grass}    :def_full_exp='d31;
		{Lowest,Fire}     :def_full_exp='d29;
		{Lowest,Water}    :def_full_exp='d27;
		{Lowest,Electric} :def_full_exp='d25;
		{Middle,Grass}    :def_full_exp='d62;
		{Middle,Fire}     :def_full_exp='d58;
		{Middle,Water}    :def_full_exp='d54;
		{Middle,Electric} :def_full_exp='d50;
		default:def_full_exp='d0;
	endcase
end
//after_battle_atk_exp(attack)
//after_battle_role_atk,after_battle_role_stage;
always_comb begin
	if((role_info_s.pkm_info.hp == 0) || (def_info_s.pkm_info.hp == 0)) begin
		after_battle_atk_exp = role_info_s.pkm_info.exp;// someone doesn't have any hp, or someone doesn't have pokemon.
		after_battle_role_atk = role_info_s.pkm_info.atk;
		after_battle_role_stage = role_info_s.pkm_info.stage;
	end
	else if(((role_info_s.pkm_info.stage != Highest) && (role_info_s.pkm_info.exp + role_earn_exp > role_full_exp)) || (role_info_s.pkm_info.stage == Highest)) begin
		after_battle_atk_exp = 0;
		case(role_info_s.pkm_info.stage)
			Lowest:begin
				case(role_info_s.pkm_info.pkm_type)
					Grass:   after_battle_role_atk = 94;
					Fire:    after_battle_role_atk = 96;
					Water:   after_battle_role_atk = 89;
					Electric:after_battle_role_atk = 97;
					default: after_battle_role_atk = 0;
				endcase
				after_battle_role_stage = Middle;
			end
			Middle:begin
				case(role_info_s.pkm_info.pkm_type)
					Grass:   after_battle_role_atk = 123;
					Fire:    after_battle_role_atk = 127;
					Water:   after_battle_role_atk = 113;
					Electric:after_battle_role_atk = 124;
					default: after_battle_role_atk = 0;
				endcase
				after_battle_role_stage = Highest;
			end
			default:begin
				after_battle_role_atk = origin_atk;
				after_battle_role_stage = role_info_s.pkm_info.stage;
			end
		endcase
	end
	else begin
		after_battle_atk_exp = role_info_s.pkm_info.exp + role_earn_exp;
		after_battle_role_atk = origin_atk;
		after_battle_role_stage = role_info_s.pkm_info.stage;
	end
end
//after_battle_def_exp(attack)
//after_battle_def_atk,after_battle_def_stage;
always_comb begin
	if((role_info_s.pkm_info.hp == 0) || (def_info_s.pkm_info.hp == 0))begin
		after_battle_def_exp = def_info_s.pkm_info.exp;// someone doesn't have any hp, or someone doesn't have pokemon.
		after_battle_def_atk = def_info_s.pkm_info.atk;
		after_battle_def_stage = def_info_s.pkm_info.stage;
	end
	else if(((def_info_s.pkm_info.stage != Highest) && (def_info_s.pkm_info.exp + def_earn_exp > def_full_exp)) || (def_info_s.pkm_info.stage == Highest)) begin
		after_battle_def_exp = 0;
		case(def_info_s.pkm_info.stage)
			Lowest:begin
				case(def_info_s.pkm_info.pkm_type)
					Grass:   after_battle_def_atk = 94;
					Fire:    after_battle_def_atk = 96;
					Water:   after_battle_def_atk = 89;
					Electric:after_battle_def_atk = 97;
					default: after_battle_def_atk = 0;
				endcase
				after_battle_def_stage = Middle;
			end
			Middle:begin
				case(def_info_s.pkm_info.pkm_type)
					Grass:   after_battle_def_atk = 123;
					Fire:    after_battle_def_atk = 127;
					Water:   after_battle_def_atk = 113;
					Electric:after_battle_def_atk = 124;
					default: after_battle_def_atk = 0;
				endcase
				after_battle_def_stage = Highest;
			end
			default:begin
				after_battle_def_atk = def_info_s.pkm_info.atk;
				after_battle_def_stage = def_info_s.pkm_info.stage;
			end
		endcase
	end
	else begin
		after_battle_def_exp = def_info_s.pkm_info.exp + def_earn_exp;
		after_battle_def_atk = def_info_s.pkm_info.atk;
		after_battle_def_stage = def_info_s.pkm_info.stage;
	end
end
//use_candy_exp(use_candy)
always_comb begin
	if(role_info_s.bag_info.candy_num == 'd0) use_candy_exp = role_info_s.pkm_info.exp; // If you don't have any candies.
	else if((role_info_s.pkm_info.stage == Highest) || (role_info_s.pkm_info.exp + 'd15 > role_full_exp)) use_candy_exp = 0;
	else  use_candy_exp = role_info_s.pkm_info.exp + 'd15;
end
//role_earn_exp(attack)
always_comb begin
	case(def_info_s.pkm_info.stage)
		Lowest :role_earn_exp = 'd16;
		Middle :role_earn_exp = 'd24;
		Highest:role_earn_exp = 'd32;
		default:role_earn_exp = 'd0;
	endcase
end
//def_earn_exp(attack)
always_comb begin
	case(role_info_s.pkm_info.stage)
		Lowest :def_earn_exp = 'd8;
		Middle :def_earn_exp = 'd12;
		Highest:def_earn_exp = 'd16;
		default:def_earn_exp = 'd0;
	endcase
end
//---------------------------
endmodule