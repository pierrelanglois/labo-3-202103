-------------------------------------------------------------------------------
--
-- INF3500 | laboratoire #3 | automne 2021
--
-- v. 1.1 2021-10-17 Pierre Langlois : intersection Chemin Côte Sainte-Catherine (CCSC) et Avenue Vincent D'Indy (AVDI)
--
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.utilitaires_inf3500_pkg.all;
use ieee.math_real.all;

entity feux_circulation is
    generic (
        DUREE_ROUGE_PARTOUT : positive := 3;               -- durée des feux rouges dans toutes les directions, en secondes
        DUREE_JAUNE : positive := 1;                       -- durée d'un feu jaune, en secondes
        DUREE_VERT : positive := 20;                       -- durée d'un feu vert, en secondes
        DUREE_PIETONS : positive := 15                     -- durée du feu pour les piétons, en secondes
    );
    port (
        clk_1_Hz : in std_logic;                           -- horloge à 1 Hz
        reset : in std_logic;                              -- '1' pour réinitialiser la machine
        activer : in std_logic;                            -- '1' pour activer la séquence des états
        bouton_appel_pieton : in std_logic;                -- '1' pour demander la phase pour les piétons

        feux_CCSC_est : out std_logic_vector(5 downto 0);  -- feux sur Cote-Sainte-Catherine direction est (rouge, jaune, vert, silhouette, main, appel-piéton)
        feux_CCSC_ouest : out std_logic_vector(7 downto 0);-- feux sur Cote-Sainte-Catherine direction ouest
                                                           -- (fleche-gauche-rouge, fleche-gauche-verte, rouge, jaune, flèche-tout-droit, silhouette, main, appel-piéton)
        feux_AVDI : out std_logic_vector(5 downto 0);      -- feux sur Vincent D'Indy direction nord (rouge, jaune, vert, silhouette, main, appel-piéton)
        decompte_pietons : out BCD1;                       -- le chiffre du décompte pour les piétons
        decompte_pietons_allume : out std_logic            -- '1' pour allumer le décompte, '0' pour l'éteindre
    );
end feux_circulation;

architecture arch of feux_circulation is

-- constantes pour l'assignation des valeurs de sortie
constant ROUGE            : std_logic_vector(2 downto 0) := "100";
constant JAUNE            : std_logic_vector(2 downto 0) := "010";
constant VERT             : std_logic_vector(2 downto 0) := "001";
constant TOUT_DROIT       : std_logic_vector(2 downto 0) := "001";
constant FLECHE_G_ROUGE   : std_logic_vector(1 downto 0) := "10";
constant FLECHE_G_VERTE   : std_logic_vector(1 downto 0) := "01";
constant SILHOUETTE       : std_logic_vector(1 downto 0) := "10";
constant MAIN             : std_logic_vector(1 downto 0) := "01";
constant APPEL_PIETON     : std_logic                    := '1';

type type_etat is (Stop, Vert_CCSC, Jaune_CCSC, Vert_AVDI, Jaune_AVDI);
signal etat : type_etat := Stop;

begin
    
    -- processus pour la séquence des états
    process(all)
    variable compte : natural range 0 to maximum(DUREE_VERT, maximum(DUREE_JAUNE, maximum(DUREE_ROUGE_PARTOUT, DUREE_PIETONS)));
    begin
        if (reset = '1') then
            etat <= Stop;
        elsif rising_edge(clk_1_Hz) then
            case etat is
                when Stop =>
                    if activer = '1' then
                        etat <= Vert_CCSC;
                        compte := DUREE_VERT;
                    end if;
                when Vert_CCSC =>
                    compte := compte - 1;
                    if compte = 0 then
                        etat <= Jaune_CCSC;
                        compte := DUREE_JAUNE;
                    end if;
                when Jaune_CCSC =>
                    compte := compte - 1;
                    if compte = 0 then
                        etat <= Vert_AVDI;
                        compte := DUREE_VERT;
                    end if;
                when Vert_AVDI =>
                    compte := compte - 1;
                    if compte = 0 then
                        etat <= Jaune_AVDI;
                        compte := DUREE_JAUNE;
                    end if;
                when Jaune_AVDI =>
                    compte := compte - 1;
                    if compte = 0 then
                        etat <= Vert_CCSC;
                        compte := DUREE_VERT;
                    end if;
                when others =>
                    etat <= Stop;
            end case;
        end if;
    end process; 
    
    process(all)
    begin
    
        -- valeurs par défaut pour les décomptes
        decompte_pietons <= to_unsigned(0, decompte_pietons'length);
        decompte_pietons_allume <= '1';
    
        -- assignations aux feux
        case etat is
        
            when Vert_CCSC =>
                feux_CCSC_est   <= VERT & MAIN & not(APPEL_PIETON);
                feux_CCSC_ouest <= FLECHE_G_ROUGE & TOUT_DROIT & MAIN & not(APPEL_PIETON);
                feux_AVDI       <= ROUGE & MAIN & not(APPEL_PIETON);
                
            when Jaune_CCSC =>
                feux_CCSC_est   <= JAUNE & MAIN & not(APPEL_PIETON);
                feux_CCSC_ouest <= FLECHE_G_ROUGE & JAUNE & MAIN & not(APPEL_PIETON);
                feux_AVDI       <= ROUGE & MAIN & not(APPEL_PIETON);
                
            when Vert_AVDI =>
                feux_CCSC_est   <= ROUGE & MAIN & not(APPEL_PIETON);
                feux_CCSC_ouest <= FLECHE_G_ROUGE & ROUGE & MAIN & not(APPEL_PIETON);
                feux_AVDI       <= VERT & MAIN & not(APPEL_PIETON);
                
            when Jaune_AVDI =>
                feux_CCSC_est   <= ROUGE & MAIN & not(APPEL_PIETON);
                feux_CCSC_ouest <= FLECHE_G_ROUGE & ROUGE & MAIN & not(APPEL_PIETON);
                feux_AVDI       <= JAUNE & MAIN & not(APPEL_PIETON);
                
            -- état par défaut de sécurité, qui inclut l'état Stop
            when others =>
                feux_CCSC_est   <= (ROUGE and clk_1_Hz) & MAIN & not(APPEL_PIETON);
                feux_CCSC_ouest <= (FLECHE_G_ROUGE and clk_1_Hz) & (ROUGE and clk_1_Hz) & MAIN & not(APPEL_PIETON);
                feux_AVDI       <= (ROUGE and clk_1_Hz) & MAIN & not(APPEL_PIETON);
                
        end case;
        
    end process;
    
end arch;