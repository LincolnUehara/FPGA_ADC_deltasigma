library ieee;
use ieee.std_logic_1164.all;

PACKAGE custom_adc_filter IS

    COMPONENT adc_filter
        GENERIC(
            ADC_WIDTH       : integer := 8;	-- ADC Convertor Bit Precision
            LPF_DEPTH_BITS  : integer := 3	-- 2^LPF_DEPTH_BITS is decimation rate of averager
        );
        PORT(
        --input ports
            clk             : IN std_logic;	-- sample rate clock
            rstn            : IN std_logic;	-- async reset, asserted low
            sample          : IN std_logic;	-- raw_data_in is good on rising edge, 
            raw_data_in     : IN std_logic_vector(ADC_WIDTH-1 downto 0);	-- raw_data input
        --output ports
            ave_data_out    : OUT std_logic_vector(ADC_WIDTH-1 downto 0);	-- ave data output
            data_out_valid  : OUT std_logic	-- ave_data_out is valid, single pulse
        );
    END COMPONENT;

END custom_adc_filter;
