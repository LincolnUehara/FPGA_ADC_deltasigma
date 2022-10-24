library ieee;
use ieee.std_logic_1164.all;

PACKAGE custom_adc IS

    COMPONENT sigmadelta_box_ave
        GENERIC(
            ADC_WIDTH       : integer := 8;     -- ADC Convertor Bit Precision
            ACCUM_BITS      : integer := 10;    -- 2^ACCUM_BITS is decimation rate of accumulator
            LPF_DEPTH_BITS  : integer := 3      -- 2^LPF_DEPTH_BITS is decimation rate of averager
        );
        PORT(
        --input ports
            clk             : IN std_logic;     -- sample rate clock
            rstn            : IN std_logic;     -- async reset, asserted low
            analog_cmp      : IN std_logic;     -- input from LVDS buffer (comparitor)
        --output ports
            digital_out     : OUT std_logic_vector(ADC_WIDTH-1 downto 0);  -- digital output word of ADC
            analog_out      : OUT std_logic;                        -- feedback to comparitor input RC circuit
            sample_rdy      : OUT std_logic                         -- digital_out is ready
        );
    END COMPONENT;

END custom_adc;
