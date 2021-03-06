///////////////////////////////////////////////////////////////////////////////
// vim:set shiftwidth=3 softtabstop=3 expandtab:
// $Id: firewall 2014-07 $
//
// Module: firewall.v
// Project: Firewall DDoS
// Description: Modulo encargado de la deteccion y respuesta defensiva
//              contra ataques DDoS HTTP GET y POST
///////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ps

module fw
   #(
   //REVISAR PARAMETROS
      parameter DATA_WIDTH = 64,
      parameter CTRL_WIDTH = DATA_WIDTH/8,
      parameter UDP_REG_SRC_WIDTH = 2
   )
   (
   // Definicion de entrada de datos a los sub-modulos correspondientes
   // Entrada de datos al sub-modulo de entraccion de cabecera(header extractor)
      input  [DATA_WIDTH-1:0]             in_data_he,
      input  [CTRL_WIDTH-1:0]             in_ctrl_he,
      input                               in_wr_he,
      output                              in_rdy_he,
   // Entrada de datos al sub-modulo de deteccion DDoS
      input  [DATA_WIDTH-1:0]             in_data_ddos,
      input  [CTRL_WIDTH-1:0]             in_ctrl_ddos,
      input                               in_wr_ddos,
      output                              in_rdy_ddos,
   // Entrada de datos al sub-modulo de decision
      input  [DATA_WIDTH-1:0]             in_data_dec,
      input  [CTRL_WIDTH-1:0]             in_ctrl_dec,
      input                               in_wr_dec,
      output                              in_rdy_dec,
      
   // Definicion de la salida de los datos al modulos correspondientes
   // Conexion con el modulo OPL, por lo tanto la definicion es a
   // registros internos, la definicion de las conexiones se realizo en User Data Path
      output [DATA_WIDTH-1:0]             out_data,
      output [CTRL_WIDTH-1:0]             out_ctrl,
      output                              out_wr,
      input                               out_rdy,

      // --- Register interface
    //Registros que sirven para el control interno de los paquetes dentro del modulo
      input                               reg_req_in,
      input                               reg_ack_in,
      input                               reg_rd_wr_L_in,
      input  [`UDP_REG_ADDR_WIDTH-1:0]    reg_addr_in,
      input  [`CPCI_NF2_DATA_WIDTH-1:0]   reg_data_in,
      input  [UDP_REG_SRC_WIDTH-1:0]      reg_src_in,

      output                              reg_req_out,
      output                              reg_ack_out,
      output                              reg_rd_wr_L_out,
      output  [`UDP_REG_ADDR_WIDTH-1:0]   reg_addr_out,
      output  [`CPCI_NF2_DATA_WIDTH-1:0]  reg_data_out,
      output  [UDP_REG_SRC_WIDTH-1:0]     reg_src_out,

      // misc
      input [31:0]                         global_sys_up_time,
      input                                reset,
      input                                clk
   );

   // Define the log2 function
   `LOG2_FUNC

   //------------------------- Signals-------------------------------

   wire [DATA_WIDTH-1:0]         in_fifo_data;
   wire [CTRL_WIDTH-1:0]         in_fifo_ctrl;

   wire                          in_fifo_nearly_full;
   wire                          in_fifo_empty;

   reg                           in_fifo_rd_en;
   reg                           out_wr_int;


   //------------------------- Local assignments -------------------------------

   assign in_rdy     = !in_fifo_nearly_full;
   assign out_wr     = out_wr_int;
   assign out_data   = in_fifo_data;
   assign out_ctrl   = in_fifo_ctrl;


//------------------------- Modules-------------------------------

   fallthrough_small_fifo #(
      .WIDTH(CTRL_WIDTH+DATA_WIDTH),
      .MAX_DEPTH_BITS(2)
   ) input_fifo (
      .din           ({in_ctrl, in_data}),   // Data in
      .wr_en         (in_wr),                // Write enable
      .rd_en         (in_fifo_rd_en),        // Read the next word
      .dout          ({in_fifo_ctrl, in_fifo_data}),
      .full          (),
      .nearly_full   (in_fifo_nearly_full),
      .prog_full     (),
      .empty         (in_fifo_empty),
      .reset         (reset),
      .clk           (clk)
   );
   
 //EXTRACTOR DE CABECERA
   header_e #(
   	.DATA_WIDTH		(DATA_WIDTH),
   	.CTRL_WIDTH		(CTRL_WIDTH),
   	.UDP_REG_SRC_WIDTH	(UDP_REG_SRC_WIDTH)
   ) header_e (
   	//señales de entrada al modulo
   	.in_data		(in_data_he),
      	.in_ctrl		(in_ctrl_he),
      	.in_wr			(in_wr_he),
      	//señales de salida del modulo
      	.dst_ip			(dst_ip),
      	.src_ip			(src_ip),
      	.dst_port		(dst_port),
      	.src_port		(src_port),
      	.proto			(proto),
      	.reset			(reset),
        .clk			(clk)
   );
  
 //DDOS
 
 //TCAM_USR
  
 //TCAM_BL
  
 //DECISION ****************
   decision #(
      .DATA_WIDTH		(DATA_WIDTH),
      .DATA_WIDTH_TCAM 		(DATA_WIDTH_TCAM),
      .CTRL_WIDTH		(CTRL_WIDTH),
      .UDP_REG_SRC_WIDTH	(UDP_REG_SRC_WIDTH)
   ) desicion (
   // Señales de entrada al modulo
   	.in_data		(),
   // Señales de salida del modulo
   );
 //Registros genericos
   generic_regs
   #(
      .UDP_REG_SRC_WIDTH   (UDP_REG_SRC_WIDTH),
      .TAG                 (0),                 // Tag -- eg. MODULE_TAG
      .REG_ADDR_WIDTH      (1),                 // Width of block addresses -- eg. MODULE_REG_ADDR_WIDTH
      .NUM_COUNTERS        (0),                 // Number of counters
      .NUM_SOFTWARE_REGS   (0),                 // Number of sw regs
      .NUM_HARDWARE_REGS   (0)                  // Number of hw regs
   ) module_regs (
      .reg_req_in       (reg_req_in),
      .reg_ack_in       (reg_ack_in),
      .reg_rd_wr_L_in   (reg_rd_wr_L_in),
      .reg_addr_in      (reg_addr_in),
      .reg_data_in      (reg_data_in),
      .reg_src_in       (reg_src_in),

      .reg_req_out      (reg_req_out),
      .reg_ack_out      (reg_ack_out),
      .reg_rd_wr_L_out  (reg_rd_wr_L_out),
      .reg_addr_out     (reg_addr_out),
      .reg_data_out     (reg_data_out),
      .reg_src_out      (reg_src_out),

      // --- counters interface
      .counter_updates  (),
      .counter_decrement(),

      // --- SW regs interface
      .software_regs    (),

      // --- HW regs interface
      .hardware_regs    (),

      .clk              (clk),
      .reset            (reset)
    );

//------------------------- Logic-------------------------------

   always @(*) begin
      // Default values
      out_wr_int = 0;
      in_fifo_rd_en = 0;

      if (!in_fifo_empty && out_rdy) begin
         out_wr_int = 1;
         in_fifo_rd_en = 1;
      end
   end

endmodule
