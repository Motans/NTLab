library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity test_bench is
end test_bench;


architecture test_bench_arch of test_bench is
component sin_t is
  generic(
    dig_size    : integer;
    amp         : real;
    dc          : real;
    table_size  : integer
  );
  port(
    clk     : in std_logic;
    Rs      : in std_logic;
    freq    : in std_logic_vector(dig_size-1 downto 0);
    sin_out : out std_logic_vector(dig_size-1 downto 0)
  );
end component;

component dc_remove is
  generic(
    dig_size : integer
  );
  port(
    clk         : in std_logic;
    Rs          : in std_logic;
    filter_in   : in std_logic_vector(dig_size-1 downto 0);
    alpha       : in std_logic_vector(dig_size-1 downto 0);
    filter_out  : out std_logic_vector(dig_size-1 downto 0)
  );
end component;

procedure clk_event(signal clk: out std_logic; constant FREQ: real; constant N: natural) is
    constant PERIOD    : time := 1 sec / FREQ;        -- Full period
    constant HIGH_TIME : time := PERIOD / 2;          -- High time
    constant LOW_TIME  : time := PERIOD - HIGH_TIME;  -- Low time; always >= HIGH_TIME

  begin
    for i in 0 to N-1 loop
        clk <= '1';
        wait for HIGH_TIME;
        clk <= '0';
        wait for LOW_TIME;
    end loop;
end procedure;

    constant DIG_SIZE   : integer := 16;
    constant TABLE_SIZE : integer := 2048;
    
    signal clk          : std_logic := '0';
    signal Rs           : std_logic := '1';
    signal freq         : std_logic_vector(DIG_SIZE-1 downto 0) := 
        std_logic_vector(to_signed(512, DIG_SIZE));
    signal sin_x        : std_logic_vector(DIG_SIZE-1 downto 0) := 
        std_logic_vector(to_signed(0, DIG_SIZE));
    signal filter_out   : std_logic_vector(DIG_SIZE-1 downto 0);
    signal alpha        : std_logic_vector(DIG_SIZE-1 downto 0) := 
        std_logic_vector(to_signed(32505, DIG_SIZE));
  begin
    clk_event(clk, 100.0, 1024);
    Rs <= '0';
    sin_t0: sin_t 
        generic map(
            dig_size    => DIG_SIZE,
            amp         => 0.25,
            dc          => 0.5,
            table_size  => TABLE_SIZE
        )
        port map(clk, Rs, freq, sin_x);
    
    filter: dc_remove
        generic map(DIG_SIZE)
        port map(clk, Rs, sin_x, alpha, filter_out);

end test_bench_arch;