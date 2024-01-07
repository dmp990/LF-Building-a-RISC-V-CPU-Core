\m4_TLV_version 1d: tl-x.org
\SV
   // This code can be found in: https://github.com/stevehoover/LF-Building-a-RISC-V-CPU-Core/risc-v_shell.tlv
   
   m4_include_lib(['https://raw.githubusercontent.com/stevehoover/LF-Building-a-RISC-V-CPU-Core/main/lib/risc-v_shell_lib.tlv'])

   m4_test_prog()

\SV
   m4_makerchip_module   // (Expanded in Nav-TLV pane.)
   /* verilator lint_on WIDTH */
\TLV
   $reset = *reset;
   
   
   // PC logic
   $pc[31:0] = >>1$next_pc;
   //$next_pc[31:0] = $reset ? 32'b0 : 32'b100 + $pc;
   $next_pc[31:0] =
       $reset ? 32'b0 :
       $taken_br || $is_jal ? $br_tgt_pc :
       $is_jalr ? $jalr_tgt_pc : 
       32'b100 + $pc;
   
   // Instruction Memory
   //`READONLY_MEM($addr, $$read_data[31:0])
   `READONLY_MEM($pc, $$instr[31:0]);
   
   // Decode Logic: Instruction Type
   $is_i_instr = $instr[6:2] ==? 5'b00000 ||
                 $instr[6:2] ==? 5'b00001 ||
                 $instr[6:2] ==? 5'b00100 ||
                 $instr[6:2] ==? 5'b00110 ||
                 $instr[6:2] ==? 5'b11001;
   
   $is_r_instr = $instr[6:2] ==? 5'b01011 ||
                 $instr[6:2] ==? 5'b01100 ||
                 $instr[6:2] ==? 5'b01110 ||
                 $instr[6:2] ==? 5'b10100;
   
   $is_s_instr = $instr[6:5] ==? 2'b01 &&
                 ($instr[4:2] ==? 3'b000 ||
                 $instr[4:2] ==? 3'b001);
   
   $is_b_instr = $instr[6:5] ==? 2'b11 &&
                 $instr[4:2] ==? 3'b000;
   
   $is_j_instr = $instr[6:5] ==? 2'b11 &&
                 $instr[4:2] ==? 3'b011;
   
   $is_u_instr = $instr[6:2] ==? 5'b0x101;
   
   
   // Decode Logic: Instruction Fields
   $rs1[4:0] = $instr[19:15];
   $rs2[4:0] = $instr[24:20];
   $rd[4:0] = $instr[11:7];
   $funct3[2:0] = $instr[14:12];
   $opcode[6:0] = $instr[6:0];
   
   $rs1_valid = $is_r_instr || $is_i_instr || $is_s_instr || $is_b_instr;
   $rs2_valid = $is_r_instr || $is_s_instr || $is_b_instr;
   $rd_valid = $is_r_instr || $is_i_instr || $is_u_instr || $is_j_instr;
   $funct3_valid = $is_r_instr || $is_i_instr || $is_s_instr || $is_b_instr;
   $imm_valid = !$is_r_instr;
   
   $imm[31:0] = $is_i_instr ? { {21{$instr[31]}}, $instr[30:20] } :
                $is_s_instr ? { {21{$instr[31]}}, $instr[30:25], $instr[11:7] } :
                $is_b_instr ? { {20{$instr[31]}}, $instr[7], $instr[30:25], $instr[11:8], 1'b0 } :
                $is_u_instr ? { $instr[31], $instr[30:20], $instr[19:12], 12'b0 } :
                $is_j_instr ? { {12{$instr[31]}}, $instr[19:12], $instr[20], $instr[30:25], $instr[24:21], 1'b0 } :
                             32'b0; // Default
   
   // Decode Logic: Instruction
   $dec_bits[10:0] = { $instr[30], $funct3, $opcode };
   
   $is_beq = $dec_bits ==? 11'bx_000_1100011;
   $is_bne = $dec_bits ==? 11'bx_001_1100011;
   $is_blt = $dec_bits ==? 11'bx_100_1100011;
   $is_bge = $dec_bits ==? 11'bx_101_1100011;
   $is_bltu = $dec_bits ==? 11'bx_110_1100011;
   $is_bgeu = $dec_bits ==? 11'bx_111_1100011;
   $is_addi = $dec_bits ==? 11'bx_000_0010011;
   $is_add = $dec_bits ==? 11'b0_000_0110011;
   // Chapter 5: Extensions
   $is_lui = $dec_bits ==? 11'bx_xxx_0110111;
   $is_auipc = $dec_bits ==? 11'bx_xxx_0010111;
   $is_jal = $dec_bits ==? 11'bx_xxx_1101111;
   $is_jalr = $dec_bits ==? 11'bx_000_1100111;
   $is_slti = $dec_bits ==? 11'bx_010_0010011;
   $is_sltiu = $dec_bits ==? 11'bx_011_0010011;
   $is_xori = $dec_bits ==? 11'bx_100_0010011;
   $is_ori = $dec_bits ==? 11'bx_110_0010011;
   $is_andi = $dec_bits ==? 11'bx_111_0010011;
   $is_slli = $dec_bits ==? 11'b0_001_0010011;
   $is_srli = $dec_bits ==? 11'b0_101_0010011;
   $is_srai = $dec_bits ==? 11'b1_101_0010011;
   $is_sub = $dec_bits ==? 11'b1_000_0110011;
   $is_sll = $dec_bits ==? 11'b0_001_0110011;
   $is_slt = $dec_bits ==? 11'b0_010_0110011;
   $is_sltu = $dec_bits ==? 11'b0_011_0110011;
   $is_xor = $dec_bits ==? 11'b0_100_0110011;
   $is_srl = $dec_bits ==? 11'b0_101_0110011;
   $is_sra = $dec_bits ==? 11'b1_101_0110011;
   $is_or = $dec_bits ==? 11'b0_110_0110011;
   $is_and = $dec_bits ==? 11'b0_111_0110011;
   
   $is_load = $dec_bits ==? 11'bx_xxx_0000011; // Treat all loads same, assign based on opcode only
   
   // Subexpressions needed by the ALU
   // Set if less than unsigned, Set if less than immediate unsigned
   $sltu_rslt[31:0] = { 31'b0, $src1_value < $src2_value };
   $sltiu_rslt[31:0] = { 31'b0, $src1_value < $imm };
   
   // SRA and SRAI (shift right arithmetic)
   // sign-extended src1
   $sext_src1[63:0] = { {32{$src1_value[31]}}, $src1_value };
   // 64-bit sign extended result, to be truncated
   $sra_rslt[63:0] = $sext_src1 >> $src2_value[4:0];
   $srai_rslt[63:0] = $sext_src1 >> $imm[4:0];
   
   // Arithmetic Logic Unit
   $result[31:0] =
       $is_addi ? $src1_value + $imm :
       $is_add ? $src1_value + $src2_value :
       $is_andi ? $src1_value & $imm :
       $is_ori ? $src1_value | $imm :
       $is_xori ? $src1_value ^ $imm :
       $is_slli ? $src1_value << $imm[4:0] :
       $is_srli ? $src1_value >> $imm[4:0] :
       $is_and ? $src1_value & $src2_value :
       $is_or ? $src1_value | $src2_value :
       $is_xor ? $src1_value ^ $src2_value :
       $is_sub ? $src1_value - $src2_value :
       $is_sll ? $src1_value << $src2_value[4:0] :
       $is_srl ? $src1_value >> $src2_value[4:0] :
       $is_sltu ? $sltu_rslt :
       $is_sltiu ? $sltiu_rslt :
       $is_lui ? { $imm[31:12], 12'b0 } :
       $is_auipc ? $pc + $imm :
       $is_jal ? $pc + 32'd4 :
       $is_jalr ? $pc + 32'd4 :
       $is_slt ? ( ( $src1_value[31] == $src2_value[31] ) ?
                     $sltu_rslt :
                     { 31'b0, $src1_value[31] } ) :
       $is_slti ? ( ( $src1_value[31] == $imm[31] ) ?
                     $sltiu_rslt :
                     { 31'b0, $src1_value[31] } ) :
       $is_sra ? $sra_rslt :
       $is_srai ? $srai_rslt :
       $is_load || $is_s_instr ? $src1_value + $imm : // load/store otherwise do not utilize ALU, hence can use the ALU to calculate the address
       32'b0; // Default
   
   // Branch Logic
   $taken_br =
       $is_beq ? ($src1_value == $src2_value) :
       $is_bne ? ($src1_value != $src2_value) :
       $is_blt ? (($src1_value < $src2_value) ^ ($src1_value[31] != $src2_value[31])) :
       $is_bge ? (($src1_value >= $src2_value) ^ ($src1_value[31] != $src2_value[31])) :
       $is_bltu ? ($src1_value < $src2_value) :
       $is_bgeu ? ($src1_value >= $src2_value) :
       1'b0; // Default for non-branching instructions
   
   $br_tgt_pc[31:0] = $pc + $imm;
   
   // Jump Logic
   $jalr_tgt_pc[31:0] = $src1_value + $imm;
   
   // Addressing Memory
   // the address is computed based on values from a source register
   // and an offset (often zero) provided as an immediate
   // addr = rs1 + imm
   
   // Loads
   // load instructions take the form: LOAD rd, imm(rs1)
   // uses the I-type instruction format
   // rd <- DMem[addr] (wher addr = rs1 + imm)
   
   // Stores
   // store instructions take the form: STORE rs2, imm(rs1)
   // has its own the S-type instruction format
   // DMem[addr] <= rs2 (wher addr = rs1 + imm)
   
   
   // Suppress log warnings
   `BOGUS_USE($rd $rd_valid $rs1 $rs1_valid $rs2 $rs2_valid $funct3 $funct3_valid $opcode $imm_valid $imm)
   `BOGUS_USE($is_beq $is_bne $is_blt $is_bge $is_bltu $is_bgeu $is_addi $is_add)
   // Assert these to end simulation (before Makerchip cycle limit).
   m4+tb()
   *failed = *cyc_cnt > M4_MAX_CYC;
   
   // Register File Read & Write
   //m4+rf(32, 32, $reset, $wr_en, $wr_index[4:0], $wr_data[31:0], $rd1_en, $rd1_index[4:0], $rd1_data, $rd2_en, $rd2_index[4:0], $rd2_data)
   m4+rf(32, 32, $reset, $rd !== 32'b0 ? $rd_valid : 1'b0, $rd, $is_load ? $ld_data : $result, $rs1_valid, $rs1, $src1_value, $rs2_valid, $rs2, $src2_value)
   //m4+dmem(32, 32, $reset, $addr[4:0], $wr_en, $wr_data[31:0], $rd_en, $rd_data)
   m4+dmem(32, 32, $reset, $result[6:2], $is_s_instr, $src2_value, $is_load, $ld_data[31:0])
   m4+cpu_viz()
\SV
   endmodule
