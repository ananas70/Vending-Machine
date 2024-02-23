library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
  
entity AutomatTb is
end entity;
  
architecture sim of AutomatTb is
  
    constant ClockFrequencyHz : integer := 100; -- 100 Hz
    constant ClockPeriod : time := 1000 ms / ClockFrequencyHz;
  
      signal Clk, nRst: std_logic := '0';
      signal bancnota_in: integer := 0;
      signal cere_produs: unsigned(0 to 1):= (others => '0');
      signal cere_rest: std_logic := '0';
      signal rest_indisponibil, suma_depasita: std_logic;
      signal elibereaza_suc, rest: unsigned(0 to 1);
begin
  
    i_Automat : entity work.Automat(Behavioral)
    port map (
      Clk => Clk,
      nRst => nRst,
      bancnota_in => bancnota_in,
      rest => rest,
      elibereaza_suc => elibereaza_suc,
      rest_indisponibil => rest_indisponibil,
      suma_depasita => suma_depasita,
      cere_produs => cere_produs,
      cere_rest => cere_rest
      );
  
    -- Clock process
    process
    begin
        Clk <= '0';
        wait for 5 ns;
        Clk <= '1';
        wait for 5 ns;
    end process;

    process is
    begin
        nRst <= '0';  -- Activeaza semnalul de reset
        cere_rest <= '0';
        cere_produs <= "00";
        wait for 10 ns;
        nRst <= '1';  -- Dezactiveaza semnalul de reset
        wait for 10 ns;
        
        -- TEST
        bancnota_in <= 10;
        wait for 10 ns;
        cere_produs <= "01";
        wait for 10 ns;
        bancnota_in <= 0;
        cere_produs <= "00";
        cere_rest <= '1';
        wait for 10 ns;
        cere_rest <= '0';
        -- TEST

        wait;
    end process;
  
end architecture;