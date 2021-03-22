library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity real_mult is
  generic(
    word_len    :           natural := 18
  );
  port(
    word_in1    :   in      std_logic_vector(word_len-1 downto 0);
    word_in2    :   in      std_logic_vector(word_len-1 downto 0);
    word_out    :   out     std_logic_vector(word_len+1 downto 0)
  );
end real_mult;


architecture real_mult_arch of real_mult is
    signal mult_res : signed(2*word_len - 1 downto 0);
  begin
    mult_res <= signed(word_in1) * signed(word_in2);

    word_out <= std_logic_vector(
        mult_res(2*word_len - 1 downto word_len-2));
end real_mult_arch;