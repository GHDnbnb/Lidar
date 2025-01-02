//
// Instruction Memory
//
// Hardik Sharma
// (hsharma@gatech.edu)
`timescale 1ns/1ps
module instruction_memory
#(
    parameter integer  IMEM_ILA_EN                  =  1,
    parameter integer  DATA_WIDTH                   = 32,
    parameter integer  SIZE_IN_BITS                 = 1<<16,
    parameter integer  ADDR_WIDTH                   = $clog2(SIZE_IN_BITS/DATA_WIDTH),
  // Instructions
    parameter integer  CTRL_DATA_WIDTH              = 32,//ghd_add_1127
    parameter integer  INST_DATA_WIDTH              = 32,
    parameter integer  INST_ADDR_WIDTH              = 32,
    parameter integer  INST_WSTRB_WIDTH             = INST_DATA_WIDTH/8,
    parameter integer  INST_BURST_WIDTH             = 8
)
(
  // clk, reset
    input  wire                                         clk,
    input  wire                                         reset,
    
  // Decoder <- imem  
    input  wire  [ CTRL_DATA_WIDTH      -1 : 0 ]        slv_reg2_out,//ghd_add_1127
  // Decoder <- imem
    input  wire                                         s_read_req_b,
    input  wire  [ ADDR_WIDTH           -1 : 0 ]        s_read_addr_b,
    output wire  [ DATA_WIDTH           -1 : 0 ]        s_read_data_b,

  // PCIe -> CL_wrapper AXI4 interface
  // Slave Interface Write Address
    input  wire  [ INST_ADDR_WIDTH      -1 : 0 ]        pci_cl_data_awaddr,
    input  wire  [ INST_BURST_WIDTH     -1 : 0 ]        pci_cl_data_awlen,
    input  wire  [ 3                    -1 : 0 ]        pci_cl_data_awsize,
    input  wire  [ 2                    -1 : 0 ]        pci_cl_data_awburst,
    input  wire                                         pci_cl_data_awvalid,
    output wire                                         pci_cl_data_awready,
  // Slave Interface Write Data
    input  wire  [ INST_DATA_WIDTH      -1 : 0 ]        pci_cl_data_wdata,
    input  wire  [ INST_WSTRB_WIDTH     -1 : 0 ]        pci_cl_data_wstrb,
    input  wire                                         pci_cl_data_wlast,
    input  wire                                         pci_cl_data_wvalid,
    output wire                                         pci_cl_data_wready,
  // Slave Interface Write Response
    output wire  [ 2                    -1 : 0 ]        pci_cl_data_bresp,
    output wire                                         pci_cl_data_bvalid,
    input  wire                                         pci_cl_data_bready,
  // Slave Interface Read Address
    input  wire  [ INST_ADDR_WIDTH      -1 : 0 ]        pci_cl_data_araddr,
    input  wire  [ INST_BURST_WIDTH     -1 : 0 ]        pci_cl_data_arlen,
    input  wire  [ 3                    -1 : 0 ]        pci_cl_data_arsize,
    input  wire  [ 2                    -1 : 0 ]        pci_cl_data_arburst,
    input  wire                                         pci_cl_data_arvalid,
    output wire                                         pci_cl_data_arready,
  // Slave Interface Read Data
    output wire  [ INST_DATA_WIDTH      -1 : 0 ]        pci_cl_data_rdata,
    output wire  [ 2                    -1 : 0 ]        pci_cl_data_rresp,
    output wire                                         pci_cl_data_rlast,
    output wire                                         pci_cl_data_rvalid,
    input  wire                                         pci_cl_data_rready
);

//=============================================================
// Localparams
//=============================================================
  // Width of state
    localparam integer  STATE_W                      = 3;
    localparam integer  ADDR_V                       = 24;//ghd_add_1126
  // States
    localparam integer  IMEM_IDLE                    = 0;
    localparam integer  IMEM_WR_ADDR                 = 1;
    localparam integer  IMEM_WR_DATA                 = 2;
    localparam integer  IMEM_RD_ADDR                 = 3;
    localparam integer  IMEM_RD_REQ                  = 4;
    localparam integer  IMEM_RD_DATA                 = 5;
  // RD count
    localparam          R_COUNT_W                    = INST_BURST_WIDTH + 1;
  // Bytes per word
    localparam BYTES_PER_WORD = DATA_WIDTH / 8;
    localparam BYTE_ADDR_W = $clog2(BYTES_PER_WORD);
//=============================================================

//=============================================================
// Wires/Regs
//=============================================================
  // Host <-> imem
    wire                                        s_req_a;
    wire                                        s_wr_en_a;
    wire [ DATA_WIDTH           -1 : 0 ]        s_read_data_a;
    wire [ ADDR_WIDTH           -1 : 0 ]        s_read_addr_a;
    wire [ DATA_WIDTH           -1 : 0 ]        s_write_data_a;
    wire [ ADDR_WIDTH           -1 : 0 ]        s_write_addr_a;
    reg                                         first_clk;//ghd_add   
  // FSM for writes to instruction memory (imem)
    reg  [ STATE_W              -1 : 0 ]        imem_state_q;
    reg  [ STATE_W              -1 : 0 ]        imem_state_d;
  // writes address for instruction memory (imem)
    reg  [ INST_ADDR_WIDTH      -1 : 0 ]        w_addr_d;
    reg  [ INST_ADDR_WIDTH      -1 : 0 ]        w_addr_q;

  // read address for instruction memory (imem)
    reg  [ INST_ADDR_WIDTH      -1 : 0 ]        r_addr_d;
    reg  [ INST_ADDR_WIDTH      -1 : 0 ]        r_addr_q;
  // read counter
    reg  [ R_COUNT_W            -1 : 0 ]        r_count_d;
    reg  [ R_COUNT_W            -1 : 0 ]        r_count_q;
    reg  [ R_COUNT_W            -1 : 0 ]        r_count_max_d;
    reg  [ R_COUNT_W            -1 : 0 ]        r_count_max_q;

    reg  [ DATA_WIDTH           -1 : 0 ]        _s_read_data_a;
    reg  [ DATA_WIDTH           -1 : 0 ]        _s_read_data_b;
    
  reg  [ INST_ADDR_WIDTH      -1 : 0 ]        r_write_addr_porta;
  reg  [ INST_DATA_WIDTH      -1 : 0 ]        r_write_data_porta;
  reg                                         r_axi_write_wvalid;
//=============================================================

//=============================================================
// Assigns
//=============================================================
    assign s_read_data_a = _s_read_data_a;
    assign s_read_data_b = _s_read_data_b;

//    assign pci_cl_data_awready = imem_state_q == IMEM_WR_ADDR;
    assign pci_cl_data_awready = pci_cl_data_awvalid;//ghd_change_1128
//    assign pci_cl_data_wready = imem_state_q == IMEM_WR_DATA;
    assign pci_cl_data_wready = 1;//ghd_change_1128

    assign pci_cl_data_bvalid = imem_state_q == IMEM_WR_DATA && pci_cl_data_wlast;
    assign pci_cl_data_bresp = 0;

    assign pci_cl_data_arready = imem_state_q == IMEM_RD_ADDR;
    assign pci_cl_data_rvalid = imem_state_q == IMEM_RD_DATA;
    assign pci_cl_data_rlast = imem_state_q == IMEM_RD_DATA && pci_cl_data_rready && r_count_q == r_count_max_q;


    assign s_write_addr_a = w_addr_q[INST_ADDR_WIDTH-1:BYTE_ADDR_W];
    assign s_write_data_a = pci_cl_data_wdata;

    assign s_read_addr_a = r_addr_q[INST_ADDR_WIDTH-1:BYTE_ADDR_W];
    assign s_req_a = ((imem_state_q == IMEM_RD_REQ ||
                     (imem_state_q == IMEM_RD_DATA && pci_cl_data_rready))
                     || (imem_state_q == IMEM_WR_DATA && pci_cl_data_wvalid));
    assign s_wr_en_a = imem_state_q == IMEM_WR_DATA;

    assign pci_cl_data_rdata = s_read_data_a;
    assign pci_cl_data_rresp = 2'b0;
//=============================================================

//=============================================================
// FSM
//=============================================================
  always @(*)
  begin: READ_FSM
    imem_state_d = imem_state_q;
    r_addr_d = r_addr_q;
    r_count_max_d = r_count_max_q;
    r_count_d = r_count_q;
//    w_addr_d = w_addr_q;//ghd_change_1128
    case(imem_state_q)
      IMEM_IDLE: begin
//        first_clk = 0;//ghd_add_1126
        if (pci_cl_data_awvalid)
        begin
          imem_state_d = IMEM_WR_ADDR;
        end else if (pci_cl_data_arvalid)
        begin
          imem_state_d = IMEM_RD_ADDR;
        end
      end
      IMEM_WR_ADDR: begin
//        if (pci_cl_data_awvalid) begin
        if (pci_cl_data_wvalid) begin
//          w_addr_d = pci_cl_data_awaddr;
//          w_addr_d[31:24] = pci_cl_data_awaddr[INST_ADDR_WIDTH-1:ADDR_V];
//          w_addr_d[23:0] = {2'b0 , pci_cl_data_awaddr[ADDR_V-1:BYTE_ADDR_W]};     
//          w_addr_d = w_addr_d + 1;
          imem_state_d = IMEM_WR_DATA;
//          first_clk    = 1;
        end
        else if(!pci_cl_data_awvalid) begin 
          imem_state_d = IMEM_IDLE;
        end
        else
          imem_state_d = IMEM_WR_ADDR;
      end
      IMEM_WR_DATA: begin
        if (slv_reg2_out[0])//ghd_add_1127
//        if (!pci_cl_data_wvalid)
          imem_state_d = IMEM_IDLE;
//        if (pci_cl_data_wvalid)//ghd_change_1128
//          w_addr_d = w_addr_d + BYTES_PER_WORD;//ghd_delete_1126
//          if (first_clk == 1)//ghd_add_1126
//            w_addr_d = {pci_cl_data_awaddr[INST_ADDR_WIDTH-1:ADDR_V] , 2'b0 , pci_cl_data_awaddr[ADDR_V-1:BYTE_ADDR_W]};//ghd_delete_1126
//          else
//            w_addr_d = w_addr_d + 1;//ghd_change_1126//ghd_change_1128
//          first_clk    = 1;
      end
      IMEM_RD_ADDR: begin
        if (pci_cl_data_arvalid) begin
          r_addr_d = pci_cl_data_araddr;
          r_count_max_d = pci_cl_data_arlen;
          r_count_d = 0;
          imem_state_d = IMEM_RD_REQ;
        end
        else
          imem_state_d = IMEM_IDLE;
      end
      IMEM_RD_REQ: begin
        r_addr_d = r_addr_d + BYTES_PER_WORD;
        imem_state_d = IMEM_RD_DATA;
      end
      IMEM_RD_DATA: begin
        if (pci_cl_data_rlast)
          imem_state_d = IMEM_IDLE;
        if (pci_cl_data_rvalid && pci_cl_data_rready) begin
          r_addr_d = r_addr_d + BYTES_PER_WORD;
          r_count_d = r_count_d + 1'b1;
        end
      end
    endcase
  end
  
  always @(posedge clk)//ghd_change_1128
  begin
    if (reset) 
      w_addr_d <= 0;
    else if(slv_reg2_out[0])
      w_addr_d <= 0;
    else if(pci_cl_data_wvalid)
      w_addr_d <= w_addr_d + 1;
	else
      w_addr_d <= w_addr_d;	
  end

  always @(posedge clk)
  begin
    if (reset) 
      imem_state_q <= IMEM_IDLE;
    else
      imem_state_q <= imem_state_d;
  end

  always @(posedge clk)
  begin
    if (reset)
      w_addr_q <= 0;
    else
      w_addr_q <= w_addr_d;
  end

  always @(posedge clk)
  begin
    if (reset)
      r_addr_q <= 0;
    else
      r_addr_q <= r_addr_d;
  end

  always @(posedge clk)
  begin
    if (reset)
      r_count_q <= 0;
    else
      r_count_q <= r_count_d;
  end

  always @(posedge clk)
  begin
    if (reset)
      r_count_max_q <= 0;
    else
      r_count_max_q <= r_count_max_d;
  end
//=============================================================

//=============================================================
// Dual port ram
//=============================================================
  reg  [ DATA_WIDTH -1 : 0 ] mem [ 0 : (1<<ADDR_WIDTH) -1 ];

   always @(posedge clk) r_axi_write_wvalid <= pci_cl_data_wvalid;   
   always @(posedge clk) r_write_data_porta <= pci_cl_data_wdata;
//   always @(posedge clk) r_write_addr_porta <= pci_cl_data_awaddr[INST_ADDR_WIDTH-1:BYTE_ADDR_W];
   always @(posedge clk) r_write_addr_porta <= w_addr_d[ADDR_V-1:0];//ghd_change_1126
  //
 //write data porta
 integer a;//ghd_add
 always @(posedge clk)
  begin: RAM_WRITE_PORT_A
    if(reset)begin//ghd_add
	  for(a=0;a<=31;a=a+1)begin
	    mem[a] <= 0;
	  end
	end else begin
      if (r_axi_write_wvalid) 
        mem[r_write_addr_porta] <= r_write_data_porta;
      else
        mem[r_write_addr_porta] <= mem[r_write_addr_porta];
    end
  end

  always @(posedge clk)
  begin: RAM_WRITE_PORT_B
    if(reset)begin
      _s_read_data_b <= 0;
    end else begin
      if (s_read_req_b) begin
        _s_read_data_b <= mem[s_read_addr_b];
      end
    end
  end
  
  



//		ila_1 imem_ila (
//			.clk(clk), // input wire clk
//			.probe0(r_axi_write_wvalid), // input wire [0:0]  probe0  
//			.probe1(s_read_req_b), // input wire [31:0]  probe1 
//			.probe2(r_write_addr_porta), // input wire [31:0]  probe1 
//			.probe3(r_write_data_porta), // input wire [31:0]  probe2
//			.probe4(s_read_addr_b), // input wire [0:0]  probe4 
//	        .probe5(s_read_data_b), // input wire [7:0]  probe5 
//	        .probe6(slv_reg2_out[0]), // input wire [2:0]  probe6 
//	        .probe7(w_addr_d) // input wire [1:0]  probe7 
//	        .probe8(pci_cl_data_awvalid), // input wire [0:0]  probe8 
//	        .probe9(pci_cl_data_awready), // input wire [0:0]  probe9
//		    .probe10(imem_state_q), // input wire [2:0]  probe10 
//	        .probe11(slv_reg2_out[0]), // input wire [0:0]  probe11 
//	        .probe12(imem_state_d), // input wire [2:0]  probe12
//	        .probe13(pci_cl_data_wdata) // input wire [31:0]  probe12 			
//		);
  
endmodule

