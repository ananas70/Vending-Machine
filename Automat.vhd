library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
  
entity Automat is
port(
    Clk             : in std_logic;
    nRst            : in std_logic; -- Negative reset
    bancnota_in     : in integer;
    rest            : out unsigned(0 to 1):= (others => '0');
    -- 00   : nimic
    -- 01   : 1 leu
    -- 10   : 5 lei
    elibereaza_suc  : out unsigned(0 to 1):= (others => '0');
    -- 00   : NU elibereaza suc
    -- 01   : bautura 1
    -- 10   : bautura 2
    rest_indisponibil : out std_logic;
    suma_depasita    : out std_logic ;
    cere_produs      : in unsigned(0 to 1):= (others => '0');
    -- 00 : nu cere produs
    -- 01 : primul produs
    -- 10 : al doilea produs
    cere_rest        : in std_logic);
    -- 0  : NU a cerut rest
    -- 1  : a cerut rest
    
end entity;

  
  
architecture Behavioral of Automat is


    --DECLARATII
    -- Starile prin care trece aparatul
    type t_State is (idle, introdu_bani, rest_calculeaza, rest_5, rest_1);
    signal State : t_State;
    
    type Bancnote_Array is array (natural range <>) of integer;
    shared variable suma_din_aparat : Bancnote_Array(1 to 3) := (10, 10, 0);  -- Index 1 pentru 1 leu, 2 pentru 5 lei, 3 pentru 10 lei 
    -- suma totala stocata in aparat (din ea o sa dea si rest)

    shared variable NR_ITERATIONS : integer;    -- variabila folosita atunci cand eliberam rest

    --  PROCEDURI
    -- Procedura care verifica daca avem sa ii dam rest utilizatorului
    procedure verifica_rest (signal bancnota_introdusa: in integer;
                             variable suma_utilizator: in integer;
                             variable are_rest : out boolean) is 
    begin
    
        -- verificam 2 tipuri de rest:
            --  1. restul dupa ce ia o bautura: rest necesar =  suma acumulata + banconota - 3 lei
            --  2. restul pt. cazul in care doreste toata suma inapoi: rest necesar = suma acumulata + bancnota;
            
        if (suma_din_aparat(1) >= suma_utilizator or (suma_utilizator mod 5 = 0 and suma_din_aparat(2) >= suma_utilizator / 5) or (suma_utilizator mod 5 <= suma_din_aparat(1))) then 
            are_rest := true;          
        else 
            are_rest := false;
        end if;
    end procedure;

begin
  
    process(Clk, nRst, State, bancnota_in) is
        variable suma_utilizator : integer := 0;
        variable un_produs_eliberat : boolean;
        variable are_rest : boolean;        -- va fi asignata in procedura
        variable bancnote_5 : integer := 0; -- Pentru procedura de eliberare a restului
        variable bancnote_1 : integer := 0; -- Pentru procedura de eliberare a restului
    
    begin
        if rising_edge(Clk) then
            if nRst = '0' then
                State   <= idle;
            else
                case State is
                    when idle =>
                        elibereaza_suc <= "00";
                        rest <= "00";
                        State   <= introdu_bani;
                        rest_indisponibil <= '0';
                        suma_depasita <= '0';
                        suma_utilizator := 0;
                        State   <= introdu_bani;
                        
                    when introdu_bani =>
                        elibereaza_suc <= "00";  --resetare
                        rest <= "00";   --resetare
                       
                        if(cere_produs = "00" and cere_rest = '0') then
                            rest <= "00";
                            --Doar ACUMULEAZA bani cand nu cere nici produs, nici rest
                            if(bancnota_in = 0) then
                                    State <= introdu_bani;
                            else       
                                if(suma_utilizator + bancnota_in > 15) then
                                    -- a depasit suma de 15 lei
                                    suma_depasita <= '1';
                                    State <= introdu_bani;
                                else 

                                    verifica_rest(bancnota_in, suma_utilizator, are_rest);
    
                                    if(are_rest = false) then
                                        --nu are rest sa ii dea
                                        rest_indisponibil <= '1';
                                        State <= introdu_bani;
                                    else 
                                        -- are rest
                                        -- isi TRANSFERA TOTI BANII in suma_din_aparat (actualizeaza bancnotele de 1, 5 si 10 lei)
                                        -- actualizeaza suma_utilizator cu noua bancnota
                                         if(bancnota_in = 1) then
                                                suma_din_aparat(1) := suma_din_aparat(1) + 1; -- Update 1 lei count
                                            elsif(bancnota_in = 5) then
                                                suma_din_aparat(2) := suma_din_aparat(2) + 1; -- Update 5 lei count
                                            elsif(bancnota_in = 10) then
                                                suma_din_aparat(3) := suma_din_aparat(3) + 1; -- Update 10 lei count
                                          end if;
                                        suma_utilizator := suma_utilizator + bancnota_in;
                                        
                                    end if;
                                 end if;
                               end if;  
                                     
                        elsif(cere_produs = "01" or cere_produs = "10") then
                            -- A cerut SUC
                            --> elibereaza bautura
                            rest <= "00";
                            if(suma_utilizator < 3) then
                                --Nu isi permite sa cumpere un suc
                                elibereaza_suc <= "00";
                                rest <= "00";
                                State <= introdu_bani; --Ramane in aceeasi stare
                            
                            elsif(suma_utilizator >= 3) then
                                -- Isi permite sa cumpere un suc
                                elibereaza_suc <= cere_produs;
                                suma_utilizator := suma_utilizator - 3;
                                un_produs_eliberat := true;
                                State <= introdu_bani;
                                
                        end if;

                     elsif(cere_rest = '1') then
       
                        State <= rest_calculeaza;
                        
                end if;
                        
                     when rest_calculeaza =>
                        rest <= "00";   --resetare
                        if (suma_utilizator = 0) then
                            --am terminat de dat rest
                            State <= introdu_bani;
                        else 
            
                            if (suma_utilizator mod 5 = 0 and suma_din_aparat(2) * 5 >= suma_utilizator) then
                                --Ii dam DOAR bancnote de 5
                                NR_ITERATIONS := suma_utilizator / 5;
                                State <= rest_5;
                                
                            else
                                if(suma_din_aparat(2) = 0) then 
                                    -- Nu mai avem bancnote de 5, ii dam doar de 1
                                    NR_ITERATIONS := suma_utilizator;
                                    State <= rest_1;
                                else 
                                
                                    bancnote_5 := suma_utilizator / 5;
                                    
                                    if(bancnote_5 /= 0 and suma_din_aparat(2) > 0) then
                                        -- Ii dam CÂTE PUTEM de 5
                                        if(suma_din_aparat(2) >= bancnote_5) then
                                            -- e un rest gen 13 lei
                                            NR_ITERATIONS := bancnote_5;
                                            State <= rest_5;
                                        else    
                                            -- ii dam cate de 5 avem in aparat
                                            NR_ITERATIONS := suma_din_aparat(2);
                                            State <= rest_5;  
                                        end if;      
                                    else
                                        -- I-am dat cate de 5 am putut, acum ii dam de 1
                                        NR_ITERATIONS := suma_utilizator;
                                        State <= rest_1;
                                    end if;   
                            end if;
                        end if;
                    end if;
                     
                     
                     when rest_5 =>
                        if( NR_ITERATIONS = 0 or suma_utilizator = 0) then
                            -- Am terminat
                            rest <= "00";
                            State <= rest_calculeaza;
                        else
                            rest <= "10"; -- 5 lei
                            suma_din_aparat(2) := suma_din_aparat(2) - 1;
                            suma_utilizator := suma_utilizator - 5; 
                            NR_ITERATIONS := NR_ITERATIONS - 1;
                            State <= rest_5;
                        end if;
                        
                    when rest_1 =>
                    if( NR_ITERATIONS = 0 or suma_utilizator = 0) then
                        -- Am terminat
                        rest <= "00";
                        State <= rest_calculeaza;
                    else
                        rest <= "01"; -- 1 leu
                        suma_din_aparat(1) := suma_din_aparat(1) - 1;
                        suma_utilizator := suma_utilizator - 1; 
                        NR_ITERATIONS := NR_ITERATIONS - 1;
                        State <= rest_1;
                    end if;
                    
                end case;
  
            end if;
        end if;
    end process;
  
end architecture; 