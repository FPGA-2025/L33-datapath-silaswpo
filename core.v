module Core #(
    parameter BOOT_ADDRESS = 32'h00000000
) (
    input wire clk,
    input wire rst_n,
    output reg  rd_en_o,
    output reg  wr_en_i,
    input  wire [31:0] data_i,
    output reg  [31:0] addr_o,
    output reg  [31:0] data_o
);

    reg [31:0] pc;
    reg [31:0] ir; // instruction register
    reg [31:0] regfile [0:31]; // banco de registradores

    reg [2:0] state;
    localparam FETCH = 3'd0,
               DECODE = 3'd1,
               EXEC = 3'd2,
               MEM_ACCESS = 3'd3,
               MEM_WAIT = 3'd4,
               WRITEBACK = 3'd5;

    wire [5:0] opcode = ir[31:26];
    wire [4:0] rs = ir[25:21];
    wire [4:0] rt = ir[20:16];
    wire [4:0] rd = ir[15:11];
    wire [15:0] imm = ir[15:0];
    wire [25:0] jump_imm = ir[25:0];

    wire [31:0] imm_ext = {{16{imm[15]}}, imm};
    wire [31:0] u_imm_ext = {imm, 16'b0};
    wire [31:0] j_imm_ext = {{6{jump_imm[25]}}, jump_imm, 2'b00};

    reg [31:0] alu_out;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc <= BOOT_ADDRESS;
            state <= FETCH;
            rd_en_o <= 0;
            wr_en_i <= 0;
        end else begin
            case (state)
                FETCH: begin
                    addr_o <= pc;
                    rd_en_o <= 1;
                    wr_en_i <= 0;
                    state <= DECODE;
                end
                DECODE: begin
                    rd_en_o <= 0;
                    ir <= data_i;
                    pc <= pc + 4;
                    state <= EXEC;
                end
                EXEC: begin
                    case (opcode)
                        6'b000000: begin // ADD
                            alu_out <= regfile[rs] + regfile[rt];
                            state <= WRITEBACK;
                        end
                        6'b001000: begin // ADDI
                            alu_out <= regfile[rs] + imm_ext;
                            state <= WRITEBACK;
                        end
                        6'b001011: begin // AUIPC
                            alu_out <= pc + u_imm_ext;
                            state <= WRITEBACK;
                        end
                        6'b000011: begin // JAL
                            regfile[rt] <= pc;
                            pc <= pc + j_imm_ext;
                            state <= FETCH;
                        end
                        6'b100011: begin // LW
                            alu_out <= regfile[rs] + imm_ext;
                            state <= MEM_ACCESS;
                        end
                        6'b101011: begin // SW
                            alu_out <= regfile[rs] + imm_ext;
                            state <= MEM_ACCESS;
                        end
                        default: begin
                            state <= FETCH;
                        end
                    endcase
                end
                MEM_ACCESS: begin
                    addr_o <= alu_out;
                    if (opcode == 6'b100011) begin // LW
                        rd_en_o <= 1;
                        wr_en_i <= 0;
                        state <= MEM_WAIT;
                    end else if (opcode == 6'b101011) begin // SW
                        rd_en_o <= 0;
                        wr_en_i <= 1;
                        data_o <= regfile[rt];
                        state <= FETCH;
                    end
                end
                MEM_WAIT: begin
                    rd_en_o <= 0;
                    state <= WRITEBACK;
                end
                WRITEBACK: begin
                    if (opcode == 6'b000000) // ADD
                        regfile[rd] <= alu_out;
                    else if (opcode == 6'b001000) // ADDI
                        regfile[rt] <= alu_out;
                    else if (opcode == 6'b001011) // AUIPC
                        regfile[rt] <= alu_out;
                    else if (opcode == 6'b100011) // LW
                        regfile[rt] <= data_i;
                    rd_en_o <= 0;
                    wr_en_i <= 0;
                    state <= FETCH;
                end
            endcase
        end
    end
endmodule
