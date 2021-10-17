---------------------------------------------------------------------------------------------------
-- 
-- top_labo_3.vhd
--
-- Pierre Langlois
-- 2021/10/17 pour le laboratoire #3 INF3500, le probl�me des feux de circulation
-- intesection Chemin C�te Sainte-Catherine (CCSC) et Avenue Vincent D'Indy (AVDI)
--
-- Digilent Basys 3 Artix-7 FPGA Trainer Board 
--
---------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;  
use work.utilitaires_inf3500_pkg.all;
use work.all;

entity top_labo_3 is
    port(
        clk : in std_logic;                        -- l'horloge de la carte � 100 MHz
        sw : in std_logic_vector(15 downto 0);     -- les 16 commutateurs
        led : out std_logic_vector(15 downto 0);   -- les 16 LED
        seg : out std_logic_vector(7 downto 0);    -- les cathodes partag�es des quatre symboles � 7 segments + point
        an : out std_logic_vector(3 downto 0);     -- les anodes des quatre symboles � 7 segments + point
        btnC : in std_logic;                       -- bouton du centre
        btnU : in std_logic;                       -- bouton du haut
        btnL : in std_logic;                       -- bouton de gauche
        btnR : in std_logic;                       -- bouton de droite
        btnD : in std_logic                        -- bouton du bas
    );
end;

architecture arch of top_labo_3 is

signal clk_1_Hz : std_logic;
signal FCE : std_logic_vector(5 downto 0); -- feux du CCSC vers l'est
signal FCO : std_logic_vector(7 downto 0); -- feux du CCSC vers l'ouest
signal FA : std_logic_vector(5 downto 0);  -- feux de l'AVDI
signal decompte_pietons : BCD1;
signal decompte_pietons_allume : std_logic;

signal symboles : quatre_symboles;
signal feux_CCSC_est_reconnectes : segments;   -- pour le CCSC vers l'est
signal feux_CCSC_ouest_reconnectes : segments; -- pour le CCSC vers l'ouest
signal feux_AVDI_reconnectes : segments;       -- pour l'AVDI

begin

    -- g�n�ration de l'horloge � 1 Hz du circuit
    clk_inst_1_Hz : entity generateur_horloge_precis(arch) generic map (100e6, 1) port map (clk, clk_1_Hz);
    
    -- affichage de l'horloge de 1 Hz sur une LED - sanity check
    led(15) <= clk_1_Hz;

    -- bouton reset - sanity check
    led(14) <= btnC;

    -- bouton activer - sanity check
    led(13) <= btnU;

    -- bouton appel_pieton - sanity check
    led(12) <= btnD;

    -- instantiation du module de contr�le des feux de circulation
    entite_principale : entity feux_circulation(arch)
        generic map (
            DUREE_ROUGE_PARTOUT => 3,
            DUREE_JAUNE => 1,
            DUREE_VERT => 10,
            DUREE_PIETONS => 15
        )
        port map (
            clk_1_Hz => clk_1_Hz,
            reset => btnC,
            activer => btnU,
            bouton_appel_pieton => btnD,
            feux_CCSC_est => FCE,
            feux_CCSC_ouest => FCO,
            feux_AVDI => FA,
            decompte_pietons => decompte_pietons,
            decompte_pietons_allume => decompte_pietons_allume
        );
        
        
    -- correction des connections pour l'affichage � 7 segments
    -- correspondances entre bits et segments:
    --
    --      0
    --     ---  
    --  5 |   | 1
    --     ---     <- segment du centre : bit 6
    --  4 |   | 2
    --     ---
    --      3    o <- point: bit 7
    --
    -- FCE | feux CCSC est,   bits 5:0 sont (rouge, jaune, vert, silhouette, main, appel-pi�ton)
    -- FCO | feux CCSC ouest, bits 7:0 sont (fleche-gauche-rouge, fleche-gauche-verte, rouge, jaune, fl�che-tout-droit, silhouette, main, appel-pi�ton)
    -- FA  | AVDI,            bits 5:0 sont (rouge, jaune, vert, silhouette, main, appel-pi�ton)
    feux_CCSC_est_reconnectes <= FCE(0) & FCE(4) & '0' & '0' & FCE(3) & FCE(2) & FCE(1) & FCE(5);
    feux_CCSC_ouest_reconnectes <= FCO(0) & FCO(4) & FCO(7) & FCO(6) & FCO(3) & FCO(2) & FCO(1) & FCO(5);
    feux_AVDI_reconnectes <= FA(0) & FA(4) & '0' & '0' & FA(3) & FA(2) & FA(1) & FA(5);
    
        
    -- connexion des symboles de l'affichage quadruple � 7 segments
    -- l'affichage fonctionne avec des polarit�s invers�es, donc '0' pour allumer et '1' pour �teindre
    symboles(3) <= not(feux_CCSC_est_reconnectes);
    symboles(2) <= not(feux_CCSC_ouest_reconnectes);
    symboles(1) <= not(feux_AVDI_reconnectes);
    symboles(0) <= hex_to_7seg(decompte_pietons) or not(decompte_pietons_allume);    -- �teindre tout (donc forcer des '1') si decompte_rue_allume = '0'
        
   -- Circuit pour s�rialiser l'acc�s aux quatre symboles � 7 segments.
   -- L'affichage contient quatre symboles chacun compos� de sept segments et d'un point.
    process(all)
    variable clkCount : unsigned(19 downto 0) := (others => '0');
    begin
        if rising_edge(clk) then
            clkCount := clkCount + 1;           
        end if;
        case clkCount(clkCount'left downto clkCount'left - 1) is     -- L'horloge de 100 MHz est ramen�e � environ 100 Hz en la divisant par 2^19
            when   "00" => an <= "1110"; seg <= symboles(0);
            when   "01" => an <= "1101"; seg <= symboles(1);
            when   "10" => an <= "1011"; seg <= symboles(2);
            when others => an <= "0111"; seg <= symboles(3);
        end case;
    end process;
        
end arch;