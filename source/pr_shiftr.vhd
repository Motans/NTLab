library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


entity shiftr is
  generic(
    word_len    :           natural := 18;
    prec_len    :           natural := 3
  );
  port( 
    clk         :   in      std_logic;
    prec        :   in      std_logic_vector(prec_len-1 downto 0);
    word_in     :   in      std_logic_vector(word_len-1 downto 0);
    word_out    :   out     std_logic_vector(word_len-1 downto 0)
  );
end shiftr;


architecture shiftr_arch of shiftr is
  begin
    process(clk)
      begin
        if(clk'event and clk = '1') then
            word_out <= std_logic_vector(
                shift_right(signed(word_in),
                            8 + to_integer(unsigned(prec))));
        end if;
    end process;
end shiftr_arch;