-------------------------------------------------------------------------------
-- Integrated Counter & Seven Segment Testbench
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity seven_seg_tb is
end seven_seg_tb;

architecture arch of seven_seg_tb is

    -- Component Declarations
    component generic_counter is
        generic (
            max_count : integer := 3
        );
        port (
            clk    : in  std_logic; 
            reset  : in  std_logic;
            output : out std_logic
        );  
    end component;

    component generic_adder_beh is
        generic (
            bits : integer := 4
        );
        port (
            a    : in  std_logic_vector(bits-1 downto 0);
            b    : in  std_logic_vector(bits-1 downto 0);
            cin  : in  std_logic;
            sum  : out std_logic_vector(bits-1 downto 0);
            cout : out std_logic
        );
    end component;

    component seven_seg is
        port (
            clk           : in  std_logic;
            reset         : in  std_logic;
            bcd           : in  std_logic_vector(3 downto 0);
            seven_seg_out : out std_logic_vector(6 downto 0)
        );  
    end component;

    -- Testbench Signals (Matching waveform signal names)
    constant period       : time := 20 ns;                                              
    signal clk            : std_logic := '0';
    signal reset          : std_logic := '1';
    signal enable         : std_logic;
    signal sum            : std_logic_vector(3 downto 0);
    signal sum_sig        : std_logic_vector(3 downto 0) := "1111";
    signal seven_seg_out  : std_logic_vector(6 downto 0);

begin

    ---------------------------------------------------------------------------
    -- Clock & Reset Processes
    ---------------------------------------------------------------------------
    clock: process
    begin
        clk <= not clk;
        wait for period / 2;
    end process; 

    async_reset: process
    begin
        wait for 2 * period; -- Hold reset high for 40 ns
        reset <= '0';
        wait;
    end process; 

    ---------------------------------------------------------------------------
    -- Component Instantiations & Logic (Matching Block Diagram)
    ---------------------------------------------------------------------------
    -- 1. Counter (generates enable pulse every 4 clock cycles / 80 ns)
    counter_inst : generic_counter
        generic map (
            max_count => 3
        )
        port map (
            clk    => clk,
            reset  => reset,
            output => enable
        );

    -- 2. Adder (adds 1 to sum_sig)
    adder_inst : generic_adder_beh
        generic map (
            bits => 4
        )
        port map (
            a    => sum_sig,
            b    => "0001",
            cin  => '0',
            sum  => sum,
            cout => open
        );

    -- 3. Sum Register Process (updates on enable, resets/rolls over to 15)
    sum_register : process(clk, reset)
    begin
        if reset = '1' then
            sum_sig <= "1111";  -- 15 in decimal
        elsif rising_edge(clk) then
            if enable = '1' then
                if sum_sig = "1001" then  -- Rollover after 9 back to 15
                    sum_sig <= "1111";
                else
                    sum_sig <= sum;
                end if;
            end if;
        end if;
    end process;

    -- 4. Seven Segment Decoder
    seven_seg_inst : seven_seg  
        port map (        
            clk           => clk,
            reset         => reset,
            bcd           => sum_sig,
            seven_seg_out => seven_seg_out
        );

end arch;