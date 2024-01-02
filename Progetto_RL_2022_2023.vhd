----------------------------------------------------------------------------------
-- Company: Politecnico Di Milano
-- Engineer: Alessandro Travaini
-- Cod. Persona: 10742196
-- 
-- Create Date: 02.03.2023 16:40:55
-- Nome progetto: Progetto di reti logiche A.A. 2022-2023
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
-- use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity project_reti_logiche is
    port (
        i_clk : in std_logic;
        i_rst : in std_logic;
        i_start : in std_logic;
        i_w : in std_logic;
        o_z0 : out std_logic_vector(7 downto 0);
        o_z1 : out std_logic_vector(7 downto 0);
        o_z2 : out std_logic_vector(7 downto 0);
        o_z3 : out std_logic_vector(7 downto 0);
        o_done : out std_logic;
        o_mem_addr : out std_logic_vector(15 downto 0);
        i_mem_data : in std_logic_vector(7 downto 0);
        o_mem_we : out std_logic;
        o_mem_en : out std_logic
    );
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is
    TYPE state_type IS (SERIAL_IN_PARALLEL_OUT, FETCH_RAM, READ_RAM_DATA, OUTPUT_DATA, JOB_DONE);
    signal outputSelector : std_logic_vector(1 downto 0) := (others => '0');
    signal ramAddress : std_logic_vector(15 downto 0) := (others => '0');
    signal curr_state : state_type;
    
begin
    
    process(i_clk, i_rst, i_start, i_mem_data)
        variable i : integer := 0;
        variable numFiller : integer := 0;
		variable shift_counter : integer := 0;
		variable myStart : boolean := false;
		variable myInput : std_logic := '0';
		variable shift_register : std_logic_vector(17 downto 0) := (others => '0');
		variable data_read : std_logic_vector(7 downto 0) := (others => '0');
        variable latchOutput_0 : std_logic_vector(7 downto 0) := (others => '0');
        variable latchOutput_1 : std_logic_vector(7 downto 0) := (others => '0');
        variable latchOutput_2 : std_logic_vector(7 downto 0) := (others => '0');
        variable latchOutput_3 : std_logic_vector(7 downto 0) := (others => '0');
        
    begin
    
        if (i_rst = '1') then
			curr_state <= SERIAL_IN_PARALLEL_OUT;
			
			-- Reset variabili shift register
			numFiller := 0;
			shift_counter := 0;
			shift_register := (others => '0');
			myStart := false;
			
			-- Reset segnali di uscita
			o_done <= '0';
			o_z0 <= (others => '0');
			o_z1 <= (others => '0');
			o_z2 <= (others => '0');
			o_z3 <= (others => '0');
            
            -- Reset latch di uscita
            latchOutput_0 := (others => '0');
            latchOutput_1 := (others => '0');
            latchOutput_2 := (others => '0');
            latchOutput_3 := (others => '0');
            
            -- Reset del vettore contenente il selettore dell'uscita
            outputSelector <= (others => '0');
            
            -- Reset del vettore contentente l'indirizzo di RAM
            ramAddress <= (others => '0');
			
        elsif (rising_edge(i_clk)) then
			
			-- Macchina a stati che gestisce il funzionamento del componente.
			case curr_state is
			    -- In questo stato implementa il registro a scorrimento per leggere l'ingresso seriale e convertirlo in parallelo
				when SERIAL_IN_PARALLEL_OUT =>
				    
				    -- Quando l'ingresso i_start si attiva, si inserisce nel registro l'ingresso i_w.
				    -- Quando l'ingresso i_start rimane a 0 si inseriscono zeri nel registro come padding.
				    if(i_start = '1') then
                        myStart := true;
                        myInput := i_w;
                        numFiller := 0;
                    else
                        myInput := '0';
                        -- numFiller tiene conto di quanti bit sono stati aggiunti come padding
                        numFiller := numFiller + 1;
                    end if;
                    
                    -- Questo è il registro a scorrimento con inserimento in coda: ad ogni ciclo di clock il nuovo dato viene scritto sempre in posizione 0.
                    if(myStart = true and shift_counter < 18) then
						for i in 16 downto 0 loop
							shift_register(i+1) := shift_register(i);
						end loop;
						shift_register(0) := myInput;
					
						shift_counter := shift_counter + 1;
					end if;
					
					-- Quando il registro a scorrimento e' pieno (2 bit per il selettore di uscita + 16 bit di indirizzo della RAM = 18 bit totali)
					-- il contenuto del registro e' copiato nei corretti vettori.
					if(shift_counter = 18) then
					    -- Bit per il selettore di uscita
						outputSelector(0) <= shift_register(16);
						outputSelector(1) <= shift_register(17);
						
						-- Bit per l'indirizzo della RAM
						-- Nel vettore dell'indirizzo della RAM vengono scritti degli zeri concatenati ai
						-- bit a partire dall'ultimo indice di padding, individuato dalla variabile numFiller.
						case(numFiller) is 
                            when 0 =>
                                ramAddress <= shift_register(15 downto 0);
                            when 1 =>
                                ramAddress <= "0" & shift_register(15 downto 1);
                            when 2 =>
                                ramAddress <= "00" & shift_register(15 downto 2);
                            when 3 =>
                                ramAddress <= "000" & shift_register(15 downto 3);
                            when 4 =>
                                ramAddress <= "0000" & shift_register(15 downto 4);
                            when 5 =>
                                ramAddress <= "00000" & shift_register(15 downto 5);
                            when 6 =>
                                ramAddress <= "000000" & shift_register(15 downto 6);
                            when 7 =>
                                ramAddress <= "0000000" & shift_register(15 downto 7);
                            when 8 =>
                                ramAddress <= "00000000" & shift_register(15 downto 8);
                            when 9 =>
                                ramAddress <= "000000000" & shift_register(15 downto 9);
                            when 10 =>
                                ramAddress <= "0000000000" & shift_register(15 downto 10);
                            when 11 =>
                                ramAddress <= "00000000000" & shift_register(15 downto 11);
                            when 12 =>
                                ramAddress <= "000000000000" & shift_register(15 downto 12);
                            when 13 =>
                                ramAddress <= "0000000000000" & shift_register(15 downto 13);
                            when 14 =>
                                ramAddress <= "00000000000000" & shift_register(15 downto 14);
                            when 15 =>
                                ramAddress <= "000000000000000" & shift_register(15 downto 15);
                            when 16 =>
                                ramAddress <= "0000000000000000";
                            when others =>
                                ramAddress <= "0000000000000000";
                        end case;
						
						-- Reset delle variabili utilizzate in questo stato
						shift_counter := 0;
                        shift_register := (others => '0');
                        myStart := false;
					
						curr_state <= FETCH_RAM;
					end if;
				
				-- In questo stato si richiede il dato alla RAM
				when FETCH_RAM =>
					o_mem_en <= '1';
					o_mem_we <= '0';
					o_mem_addr <= ramAddress;
					
					curr_state <= READ_RAM_DATA;
				
				-- In questo stato si attende il dato dalla RAM.
				when READ_RAM_DATA =>
					
					o_mem_we <= '0';
                    o_mem_en <= '0';
					
					curr_state <= OUTPUT_DATA;
				
				-- In questo stato avviene la scrittura delle uscite del componente
				when OUTPUT_DATA =>
				    -- Il dato corretto viene effettivamente presentato dalla RAM solo dopo due cicli di clock dalla richiesta,
				    -- per questo la lettura del dato avviene in questo stato e non nel precedente.
					data_read := i_mem_data;
				    
				    -- Tramite questo switch case si scrivono il latch legato all'uscita selezionata dal selettore con il nuovo dato,
				    -- gli altri latch mantengono il dato precedente.
					case outputSelector is
						when "00" =>
							latchOutput_0 := data_read;
							latchOutput_1 := latchOutput_1;
                            latchOutput_2 := latchOutput_2;
                            latchOutput_3 := latchOutput_3;
						when "01" =>
						    latchOutput_0 := latchOutput_0;
							latchOutput_1 := data_read;
							latchOutput_2 := latchOutput_2;
                            latchOutput_3 := latchOutput_3;
						when "10" =>
						    latchOutput_0 := latchOutput_0;
						    latchOutput_1 := latchOutput_1;
							latchOutput_2 := data_read;
							latchOutput_3 := latchOutput_3;
						when "11" =>
						    latchOutput_0 := latchOutput_0;
						    latchOutput_1 := latchOutput_1;
						    latchOutput_2 := latchOutput_2;
							latchOutput_3 := data_read;
						when others =>
							latchOutput_0 := latchOutput_0;
							latchOutput_1 := latchOutput_1;
							latchOutput_2 := latchOutput_2;
							latchOutput_3 := latchOutput_3;
					end case;
					
					-- Scrittura delle uscite del componente
					o_z0 <= latchOutput_0;
					o_z1 <= latchOutput_1;
					o_z2 <= latchOutput_2;
					o_z3 <= latchOutput_3;
					-- Segnalazione dato pronto in uscita
					o_done <= '1';
					
					curr_state <= JOB_DONE;
				
				-- Reset delle variabili utilizzate e ripristino delle uscite
				when JOB_DONE =>
				    
				    -- Le uscite vengono portate a 0
				    o_z0 <= (others => '0');
                    o_z1 <= (others => '0');
                    o_z2 <= (others => '0');
                    o_z3 <= (others => '0');
					-- Chiusura handshake di dato pronto in uscita
				    o_done <= '0';
				    
				    -- Reset dei vettori del selettore di uscita e dell indirizzo della RAM
                    outputSelector <= (others => '0');
                    ramAddress <= (others => '0');
				    
				    curr_state <= SERIAL_IN_PARALLEL_OUT;
				
				-- Questo stato non dovrebbe mai essere raggiunto, ma nel caso lo fosse il componente torna nello stato iniziale
				when others =>
					curr_state <= SERIAL_IN_PARALLEL_OUT;
			end case;
        end if;
    end process;
end Behavioral;
