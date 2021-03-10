library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity sin_t is
  generic(
    dig_size    : natural := 16;
    acc_size    : natural := 16;
    quant_size  : natural := 12;
    F_s         : natural := 44100;
    amp_quant   : integer := 2;
    offset      : integer := 2**15 / 2
  );
  port(
    clk       : in std_logic;
    Rs        : in std_logic;
    phase_inc : in std_logic_vector(acc_size-1 downto 0);
    sin_out   : out std_logic_vector(dig_size-1 downto 0)
  );
end sin_t;


architecture sin_t_arch of sin_t is
component nco is
  generic(
    dig_size    : natural;
    acc_size    : natural;
    quant_size  : natural;
    F_s         : natural
  );
  port(
    clk         : in std_logic;
    Rs          : in std_logic;
    phase_inc   : in std_logic_vector(acc_size-1 downto 0);
    sin_out     : out std_logic_vector(dig_size-1 downto 0)
  );
end component;

    signal nco_sin : std_logic_vector(dig_size-1 downto 0) := std_logic_vector(to_signed(0, dig_size));
  begin
    nco0: nco 
        generic map(dig_size, acc_size, quant_size, F_s)
        port map(clk, Rs, phase_inc, nco_sin);

    sin_out <= std_logic_vector(
        shift_right(signed(nco_sin), amp_quant) + to_signed(offset, dig_size)
    );
end sin_t_arch;