library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity comp_mult is
  generic(
    word_len        :           natural := 18
  );
  port(
    clk             :   in      std_logic;
    strobe          :   in      std_logic;
    a               :   in      std_logic_vector(word_len-1 downto 0);
    b               :   in      std_logic_vector(word_len-1 downto 0);
    c               :   in      std_logic_vector(word_len-1 downto 0);
    d               :   in      std_logic_vector(word_len-1 downto 0);
    out_re          :   out     std_logic_vector(word_len-1 downto 0);
    out_im          :   out     std_logic_vector(word_len-1 downto 0)
  );
end comp_mult;

architecture comp_mult_arch of comp_mult is
component real_mult is
  generic(
    word_len        :           natural
  );
  port(
    word_in1        :   in      std_logic_vector(word_len-1 downto 0);
    word_in2        :   in      std_logic_vector(word_len-1 downto 0);
    word_out        :   out     std_logic_vector(word_len-1 downto 0)
  );
end component;

function sum_sat(a : std_logic_vector(word_len-1 downto 0);
                 b : std_logic_vector(word_len-1 downto 0))
    return std_logic_vector is

    variable res_buf    : signed(word_len downto 0);
    variable res        : signed(word_len-1 downto 0);
  BEGIN
    res     := (others => '0');
    res_buf := resize(signed(a), word_len+1) + resize(signed(b), word_len+1);
    if (res_buf(word_len) /= res_buf(word_len-1)) then --Saturate
        res(word_len-1)          := res_buf(word_len);
        res(word_len-2 downto 0) := (others => res_buf(word_len-1));
    else
        res := res_buf(word_len-1 downto 0);
    end if;
    
    return std_logic_vector(res);
end sum_sat;

function diff_sat(a : std_logic_vector(word_len-1 downto 0);
                  b : std_logic_vector(word_len-1 downto 0))
    return std_logic_vector is

    variable res_buf    : signed(word_len downto 0);
    variable res        : signed(word_len-1 downto 0);
  begin
    res     := (others => '0');
    res_buf := resize(signed(a), word_len+1) - resize(signed(b), word_len+1);
    if (res_buf(word_len) /= res_buf(word_len-1)) then --Saturate
        res(word_len-1)          := res_buf(word_len);
        res(word_len-2 downto 0) := (others => res_buf(word_len-1));
    else
        res := res_buf(word_len-1 downto 0);
    end if;
    
    return std_logic_vector(res);
end diff_sat;

    signal op1          : std_logic_vector(word_len-1 downto 0);        --
    signal op2          : std_logic_vector(word_len-1 downto 0);        -- Real multiplier
    signal prod         : std_logic_vector(word_len-1 downto 0);        --    
  begin
    mult0 : real_mult
        generic map(word_len)
        port map(op1, op2, prod);

    process(clk)
        variable state  : integer range 0 to 5;                         -- Multipliers states

        variable reg_a  : std_logic_vector(word_len-1 downto 0);
        variable reg_b  : std_logic_vector(word_len-1 downto 0);
        variable reg_c  : std_logic_vector(word_len-1 downto 0);
        variable reg_d  : std_logic_vector(word_len-1 downto 0);

        variable res_re : std_logic_vector(word_len-1 downto 0);
        variable res_im : std_logic_vector(word_len-1 downto 0);

        variable ac     : std_logic_vector(word_len-1 downto 0);        -- Res of imag and real
        variable bd     : std_logic_vector(word_len-1 downto 0);        -- part of complex digit
        variable bc     : std_logic_vector(word_len-1 downto 0);        --
        variable ad     : std_logic_vector(word_len-1 downto 0);        --

      begin    
        if (clk'event and clk = '1') then
            if (strobe = '1') then
                state := 0;
                reg_a := a;
                reg_b := b;
                reg_c := c;
                reg_d := d;
            end if;
            
            case state is
                when 0 =>
                    op1   <= reg_a;
                    op2   <= reg_c;
                    state := state + 1;
                when 1 =>
                    ac    := prod;
                    op1   <= reg_a;
                    op2   <= reg_d;
                    state := state + 1;
                when 2 =>
                    ad    := prod;
                    op1   <= reg_b;
                    op2   <= reg_c;
                    state := state + 1;
                when 3 =>
                    bc  := prod;
                    op1 <= reg_b;
                    op2 <= reg_d;
                    state := state + 1;
                when 4 =>
                    bd := prod;
                    out_re <= diff_sat(ac, bd);
                    out_im <= sum_sat(bc, ad);
                    
                    state := state + 1;
                when others =>
            end case;
        end if;
    end process;
end comp_mult_arch;