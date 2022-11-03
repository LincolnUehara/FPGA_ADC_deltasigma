library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
library work;
use work.custom_adc.all;

ENTITY ADC_top IS

    PORT(
    --input ports
        clk_in      : IN std_logic;	-- 62.5Mhz on Control Demo board
        rstn        : IN std_logic;	 
        analog_cmp  : IN std_logic;	-- from LVDS buffer or external comparitor
    --output ports
        analog_out  : OUT std_logic;	-- feedback to RC network
        sample_rdy  : OUT std_logic;
        digital_out : OUT std_logic_vector(7 downto 0)   -- connected to LED field on control demo bd.
    );
 
END ADC_top;

ARCHITECTURE translated OF ADC_top IS

--**********************************************************************
--
--	Component Declarations
--
--**********************************************************************
component sigmadelta
    GENERIC (
	    ADC_WIDTH       : integer;
	    ACCUM_BITS      : integer;
	    LPF_DEPTH_BITS  : integer
    );
    PORT (
    	clk             : IN  std_logic;
    	rstn            : IN  std_logic;
    	analog_cmp      : IN  std_logic;
    	digital_out     : OUT std_logic_vector(ADC_WIDTH-1 downto 0);
    	analog_out      : OUT std_logic;
    	sample_rdy      : OUT std_logic
    );
end component;
--**********************************************************************
--
--	Internal Signals
--
--**********************************************************************
constant    ADC_WIDTH       : integer := 8;     -- ADC Convertor Bit Precision
constant    ACCUM_BITS      : integer := 10;    -- 2^ACCUM_BITS is decimation rate of accumulator
constant    LPF_DEPTH_BITS  : integer := 3;     -- 2^LPF_DEPTH_BITS is decimation rate of averager
constant    INPUT_TOPOLOGY  : integer := 1;     -- 0: DIRECT: Analog input directly connected to + input of comparitor
                                                -- 1: NETWORK:Analog input connected through R divider to - input of comp.

signal      clk             : std_logic;
signal      analog_out_i    : std_logic;
signal      sample_rdy_i    : std_logic;
signal      digital_out_i   : std_logic_vector(ADC_WIDTH-1 downto 0);
signal      digital_out_abs : std_logic_vector(ADC_WIDTH-1 downto 0);


BEGIN

    clk <= clk_in;


SSD_ADC: entity work.sigmadelta(box_ave)
    GENERIC MAP(
    	ADC_WIDTH       => ADC_WIDTH,
    	ACCUM_BITS      => ACCUM_BITS,
    	LPF_DEPTH_BITS  => LPF_DEPTH_BITS
    )
    PORT MAP(
    	clk             => clk,
    	rstn            => rstn,
    	analog_cmp      => analog_cmp,
    	digital_out     => digital_out_i,
    	analog_out      => analog_out_i,
    	sample_rdy      => sample_rdy_i
	);

    digital_out_abs <= not digital_out_i when (INPUT_TOPOLOGY = 1) else digital_out_i;

--***********************************************************************
--
--  output assignments
--
--***********************************************************************

    digital_out   <= not digital_out_abs;	 -- invert bits for LED display 
    analog_out    <=  analog_out_i;
    sample_rdy    <=  sample_rdy_i;

END translated;
