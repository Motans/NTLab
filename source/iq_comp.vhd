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
    
    process(clk, dstrb, reset)
        variable state      :   integer range 0 to 15;

        variable cm1_re     :   std_logic_vector(word_len-1 downto 0);
        variable cm1_im     :   std_logic_vector(word_len-1 downto 0);

        variable sub_re     :   std_logic_vector(word_len-1 downto 0);
        variable sub_im     :   std_logic_vector(word_len-1 downto 0);

        variable conv1_re   :   std_logic_vector(word_len + resize_param - 1 downto 0);
        variable conv1_im   :   std_logic_vector(word_len + resize_param - 1 downto 0);

        variable shift_re   :   std_logic_vector(word_len + resize_param - 1 downto 0);
        variable sum_buf_re :   std_logic_vector(word_len + resize_param - 1 downto 0);
        variable sum_buf_im :   std_logic_vector(word_len + resize_param - 1 downto 0);

        variable sum_re     :   std_logic_vector(word_len + resize_param - 1 downto 0);
        variable sum_im     :   std_logic_vector(word_len + resize_param - 1 downto 0);

        variable conv2_re   :   std_logic_vector(word_len-1 downto 0);
        variable conv2_im   :   std_logic_vector(word_len-1 downto 0);

        variable conj_re    :   std_logic_vector(word_len-1 downto 0);
        variable conj_im    :   std_logic_vector(word_len-1 downto 0);
      begin
        if (reset = '1') then
            state       := 0;
            cm1_re      := std_logic_vector(to_signed(0, word_len));
            cm1_im      := std_logic_vector(to_signed(0, word_len));
            sum_buf_re  := std_logic_vector(to_signed(0, word_len + resize_param));
            sum_buf_im  := std_logic_vector(to_signed(0, word_len + resize_param)); 
        elsif (dstrb = '1') then
            state := 0;
        elsif (clk'event and clk = '1') then
            case state is
                when 0 =>                                   -- Sub results of cm1 and din1
                    sub_re := std_logic_vector(
                        signed(din1_re) - signed(cm1_re));
                    sub_im := std_logic_vector(
                        signed(din1_im) - signed(cm1_im));

                    dout_re <= sub_re;
                    dout_re <= sub_im;

                    state := state + 1;
                when 1 =>                                   -- Start multiplication cm2
                    a <= sub_re;
                    b <= sub_im;
                    c <= sub_re;
                    d <= sub_im;

                    strobe_mult <= clk_intern;
                    state := state + 1;
                when 2 | 3 | 4 =>                           -- Multiplictaion in 4 cycles
                    strobe_mult <= '0';
                    state := state + 1;
                when 5 =>                                   -- Resize vector to + resize param, and data to high part
                    conv1_re := prod_re & 
                                std_logic_vector(to_unsigned(0, resize_param));
                    conv1_im := prod_im & 
                                std_logic_vector(to_unsigned(0, resize_param));

                    state := state + 1;
                when 6 =>                                   -- Programmable right shift real part
                    shiftr_in <= conv1_re;
                    shift_re := shiftr_out;

                    state := state + 1;
                when 7 =>                                   -- Programmable right shift imag part
                    shiftr_in <= conv1_im;

                    state := state + 1;
                when 8 =>                                   -- Sum res and buf res(-1) and buffering
                    sum_re := std_logic_vector(
                        signed(shift_re) + signed(sum_buf_re));
                    sum_im := std_logic_vector(
                        signed(shiftr_out) + signed(sum_buf_im));

                    sum_buf_re := sum_re;
                    sum_buf_im := sum_im;
                    
                    state := state + 1;
                when 9 =>                                  -- Convert result of sum
                    conv2_re := sum_re(word_len + resize_param - 1 downto resize_param);
                    conv2_im := sum_im(word_len + resize_param - 1 downto resize_param);

                    state := state + 1;
                when 10 =>                                  -- Conjunction comlex digit
                    conj_re := din1_re;
                    conj_im := std_logic_vector(
                        -signed(din1_im));

                    state := state + 1;
                when 11 =>                                  -- Start multiplication cm1
                    a <= conj_re;
                    b <= conj_im;
                    c <= conv2_re;
                    d <= conv2_im;

                    strobe_mult <= clk_intern;
                    state := state + 1;
                when 12 | 13 | 14 =>                        -- Multiplication cm1
                    strobe_mult <= '0';
                    state := state + 1;
                when 15 =>
                    cm1_re := prod_re;
                    cm1_im := prod_im;
            end case;
        end if;
    end process;
end iq_comp_arch;