module Memory #(
    parameter MEMORY_FILE = "",
    parameter MEMORY_SIZE = 4096
)(
    input  wire        clk,
    input  wire        rd_en_i,
    input  wire        wr_en_i,
    input  wire [31:0] addr_i,
    input  wire [31:0] data_i,
    output wire [31:0] data_o,
    output wire        ack_o
);

    reg [31:0] memory [0:(MEMORY_SIZE/4)-1];

    initial begin
        if (MEMORY_FILE != "")
            $readmemh(MEMORY_FILE, memory);
    end

    assign data_o = rd_en_i ? memory[addr_i[31:2]] : 32'bz;
    assign ack_o = 1'b1; // sempre pronto (como especificado)

    always @(posedge clk) begin
        if (wr_en_i)
            memory[addr_i[31:2]] <= data_i;
    end

endmodule
