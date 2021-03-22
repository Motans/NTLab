library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


entity iq_comp is
  generic(
    word_len        :           natural := 18;
    prec_len        :           natural := 2;
    resize_param    :           natural := 16
  );
  port( 
    clk             :   in      std_logic;
    reset           :   in      std_logic;
    dstrb           :   in      std_logic;
    prec            :   in      std_logic_vector(prec_len-1 downto 0);
    din1_re         :   in      std_logic_vector(word_len-1 downto 0);          -- sfix18_En17
    din1_im         :   in      std_logic_vector(word_len-1 downto 0);          -- sfix18_En17
    dout_re         :   out     std_logic_vector(word_len-1 downto 0);          -- sfix18_En17
    dout_im         :   out     std_logic_vector(word_len-1 downto 0)           -- sfix18_En17
  );
end iq_comp;


architecture iq_comp_arch of iq_comp is
component comp_mult is
    generic(
        word_len    :           natural
    );
    port(
        clk         :   in      std_logic;
        strobe      :   in      std_logic;
        a           :   in      std_logic_vector(word_len-1 downto 0);
        b           :   in      std_logic_vector(word_len-1 downto 0);
        c           :   in      std_logic_vector(word_len-1 downto 0);
        d           :   in      std_logic_vector(word_len-1 downto 0);
        out_re      :   out     std_logic_vector(word_len-1 downto 0);
        out_im      :   out     std_logic_vector(word_len-1 downto 0)
    );
end component;

component shiftr is
    generic(
        word_len    :           natural;
        prec_len    :           natural
    );
    port( 
        clk         :   in      std_logic;
        prec        :   in      std_logic_vector(prec_len-1 downto 0);
        word_in     :   in      std_logic_vector(word_len-1 downto 0);
        word_out    :   out     std_logic_vector(word_len-1 downto 0)
    );
end component;

function sum_sat(a : std_logic_vector(word_len+resize_param-1 downto 0);
                 b : std_logic_vector(word_len+resize_param-1 downto 0))
    return std_logic_vector is

    constant size       : natural := word_len + resize_param;
    variable res_buf    : signed(size downto 0);
    variable res        : signed(size-1 downto 0);
  BEGIN
    res     := (others => '0');
    res_buf := resize(signed(a), size+1) + resize(signed(b), size+1);
    if (res_buf(size) /= res_buf(size-1)) then --Saturate
        res(size-1)          := res_buf(size);
        res(size-2 downto 0) := (others => res_buf(size-1));
    else
        res := res_buf(size-1 downto 0);
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

    signal a            :   std_logic_vector(word_len-1 downto 0);                      -- Signals for multiplier
    signal b            :   std_logic_vector(word_len-1 downto 0);                      -- 
    signal c            :   std_logic_vector(word_len-1 downto 0);                      -- 
    signal d            :   std_logic_vector(word_len-1 downto 0);                      -- 
    signal prod_re      :   std_logic_vector(word_len-1 downto 0);                      -- 
    signal prod_im      :   std_logic_vector(word_len-1 downto 0);                      --
        

    signal shiftr_in    :   std_logic_vector(word_len + resize_param - 1 downto 0);     -- Shifter signals
    signal shiftr_out   :   std_logic_vector(word_len + resize_param - 1 downto 0);     --

    signal clk_intern   :   std_logic;                                                  -- Service signals
    signal strobe_mult  :   std_logic;                                                  -- 

  begin
    clk_intern <= clk;
    comp_mult0: comp_mult
        generic map(word_len)
        port map(clk_intern, strobe_mult, a, b, c, d, prod_re, prod_im);
    
    shiftr0: shiftr
        generic map(word_len + resize_param, prec_len)
        port map(clk_intern, prec, shiftr_in, shiftr_out);
    
    iq0 : process(clk, reset)
        variable state          :   integer range 0 to 15 := 0;

        variable din_re         :   std_logic_vector(word_len-1 downto 0);
        variable din_im         :   std_logic_vector(word_len-1 downto 0);

        variable cm1_re         :   std_logic_vector(word_len-1 downto 0) := (others => '0');
        variable cm1_im         :   std_logic_vector(word_len-1 downto 0) := (others => '0');

        variable sub_re         :   std_logic_vector(word_len-1 downto 0);
        variable sub_im         :   std_logic_vector(word_len-1 downto 0);

        variable conv1_re       :   std_logic_vector(word_len + resize_param - 1 downto 0);
        variable conv1_im       :   std_logic_vector(word_len + resize_param - 1 downto 0);

        variable shift_re       :   std_logic_vector(word_len + resize_param - 1 downto 0);
        variable sum_buf_re     :   std_logic_vector(word_len + resize_param - 1 downto 0) := (others => '0');
        variable sum_buf_im     :   std_logic_vector(word_len + resize_param - 1 downto 0) := (others => '0');

        variable sum_re         :   std_logic_vector(word_len + resize_param - 1 downto 0);
        variable sum_im         :   std_logic_vector(word_len + resize_param - 1 downto 0);

        variable conv2_re       :   std_logic_vector(word_len-1 downto 0);
        variable conv2_im       :   std_logic_vector(word_len-1 downto 0);

        variable conj_re        :   std_logic_vector(word_len-1 downto 0);
        variable conj_im        :   std_logic_vector(word_len-1 downto 0);
        variable conj_im_buf    :   signed(word_len downto 0);
      begin
        if (reset = '1') then
            state       := 0;
            cm1_re      := (others => '0');
            cm1_im      := (others => '0');
            sum_buf_re  := (others => '0');
            sum_buf_im  := (others => '0');
            dout_re     <= (others => '0');
            dout_im     <= (others => '0');
        elsif (clk'event and clk = '1') then
            if (dstrb = '1') then
                state := 0;
                din_re := din1_re;
                din_im := din1_im;
            end if;

            case state is
                when 0 =>                                   -- Sub results of cm1 and din1
                    sub_re := diff_sat(din_re, cm1_re);
                    sub_im := diff_sat(din_im, cm1_im);

                    dout_re <= sub_re;
                    dout_im <= sub_im;

                    state := state + 1;
                when 1 =>                                   -- Start multiplication cm2
                    a <= sub_re;
                    b <= sub_im;
                    c <= sub_re;
                    d <= sub_im;

                    strobe_mult <= '1';
                    state := state + 1;
                when 2 | 3 | 4 | 5 =>                       -- Multiplictaion in 4 cycles
                    strobe_mult <= '0';
                    state := state + 1;
                when 6 =>
                    conv1_re := prod_re & 
                                std_logic_vector(to_unsigned(0, resize_param));
                    conv1_im := prod_im & 
                                std_logic_vector(to_unsigned(0, resize_param));
                    
                    shiftr_in <= conv1_re;
                    state := state + 1;
                when 7 =>                                   -- Programmable right shift imag part
                    shift_re := shiftr_out;
                    shiftr_in <= conv1_im;

                    state := state + 1;
                when 8 =>                                   -- Sum res(i) and buf res(i-1) and buffering
                    sum_re := sum_buf_re;
                    sum_im := sum_buf_im;

                    sum_buf_re := sum_sat(shift_re, sum_buf_re);
                    sum_buf_im := sum_sat(shiftr_out, sum_buf_im);
                    
                    state := state + 1;
                when 9 =>                                  -- Convert result of sum and conj
                    conv2_re := sum_re(word_len + resize_param - 1 downto resize_param);
                    conv2_im := sum_im(word_len + resize_param - 1 downto resize_param);

                    conj_re := din_re;

                    conj_im := (others => '0');
                    conj_im_buf := -resize(signed(din_im), word_len+1);
                    if (conj_im_buf(word_len) /= conj_im_buf(word_len-1)) then --Saturate
                        conj_im(word_len-1)          := conj_im_buf(word_len);
                        conj_im(word_len-2 downto 0) := (others => conj_im_buf(word_len-1));
                    else
                        conj_im := std_logic_vector(
                            conj_im_buf(word_len-1 downto 0));
                    end if;
                    
                    state := state + 1;
                when 10 =>                                  -- Start multiplication cm1
                    a <= conj_re;
                    b <= conj_im;
                    c <= conv2_re;
                    d <= conv2_im;

                    strobe_mult <= '1';
                    state := state + 1;
                when 11 | 12 | 13 | 14 =>                        -- Multiplication cm1
                    strobe_mult <= '0';
                    state := state + 1;
                when 15 =>
                    cm1_re := prod_re;
                    cm1_im := prod_im;
            end case;
        end if;
    end process;
end iq_comp_arch;