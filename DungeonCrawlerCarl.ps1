# ============================================================
# DUNGEON CRAWLER WORLD - Terminal v2.0
# Desperation Engine | Powered by the Borant Corporation
# ============================================================
Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms

# ============================================================
# XAML UI  -  3-pane layout per spec
#   Left  (260): Crawler status, ProgressBars, core stats
#   Center (*):  RichTextBox terminal + command input
#   Right (260): Inventory ListBox + Loot Box ListBox
#   Below center: nav compass + combat bar (Visibility=Collapsed when idle)
# ============================================================
[xml]$XAML = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="World Dungeon Terminal - Desperation Engine v2.0"
    Height="800" Width="1260"
    Background="#121212" WindowStartupLocation="CenterScreen"
    ResizeMode="CanResize" MinWidth="1100" MinHeight="620">

    <Window.Resources>
        <!-- Shared dark button -->
        <Style x:Key="DBtn" TargetType="Button">
            <Setter Property="Background" Value="#1C1C1E"/>
            <Setter Property="Foreground" Value="#E5E5EA"/>
            <Setter Property="BorderBrush" Value="#3A3A3C"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="FontFamily" Value="Consolas"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="Padding" Value="6,3"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}"
                                BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}"
                                Padding="{TemplateBinding Padding}" CornerRadius="3">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Background" Value="#2C2C2E"/>
                                <Setter Property="BorderBrush" Value="#636366"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter Property="Background" Value="#3A3A3C"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter Property="Foreground" Value="#3A3A3C"/>
                                <Setter Property="BorderBrush" Value="#1C1C1E"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style x:Key="NavBtn" TargetType="Button" BasedOn="{StaticResource DBtn}">
            <Setter Property="Width" Value="44"/>
            <Setter Property="Height" Value="28"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="FontSize" Value="11"/>
        </Style>
        <Style x:Key="CombatBtn" TargetType="Button" BasedOn="{StaticResource DBtn}">
            <Setter Property="Background" Value="#2C0A0A"/>
            <Setter Property="BorderBrush" Value="#FF3B30"/>
            <Setter Property="Foreground" Value="#FF6B60"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="Padding" Value="10,5"/>
        </Style>
        <Style x:Key="SHdr" TargetType="TextBlock">
            <Setter Property="Foreground" Value="#FF3B30"/>
            <Setter Property="FontFamily" Value="Consolas"/>
            <Setter Property="FontSize" Value="11"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="Margin" Value="0,6,0,2"/>
        </Style>
        <Style x:Key="SVal" TargetType="TextBlock">
            <Setter Property="Foreground" Value="#E5E5EA"/>
            <Setter Property="FontFamily" Value="Consolas"/>
            <Setter Property="FontSize" Value="11"/>
            <Setter Property="Margin" Value="0,1,0,1"/>
        </Style>
        <Style x:Key="SDim" TargetType="TextBlock">
            <Setter Property="Foreground" Value="#8E8E93"/>
            <Setter Property="FontFamily" Value="Consolas"/>
            <Setter Property="FontSize" Value="11"/>
            <Setter Property="Margin" Value="0,1,0,1"/>
        </Style>
    </Window.Resources>

    <DockPanel>
        <!-- TOP TITLE BAR -->
        <Border DockPanel.Dock="Top" Background="#0A0A0A" BorderBrush="#FF3B30"
                BorderThickness="0,0,0,1" Padding="14,7">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                    <TextBlock Text="DUNGEON CRAWLER WORLD" Foreground="#FF3B30"
                               FontFamily="Consolas" FontSize="18" FontWeight="Bold" VerticalAlignment="Center"/>
                    <TextBlock Text="  :: Desperation Engine v2.0 ::" Foreground="#3A3A3C"
                               FontFamily="Consolas" FontSize="12" VerticalAlignment="Bottom" Margin="0,0,0,2"/>
                </StackPanel>
                <StackPanel Grid.Column="1" Orientation="Horizontal">
                    <Button x:Name="btnNewGame" Content="[NEW GAME]" Style="{StaticResource DBtn}" Margin="3,0"/>
                    <Button x:Name="btnSave"    Content="[SAVE]"     Style="{StaticResource DBtn}" Margin="3,0"/>
                    <Button x:Name="btnLoad"    Content="[LOAD]"     Style="{StaticResource DBtn}" Margin="3,0"/>
                    <Button x:Name="btnHelp"    Content="[HELP]"     Style="{StaticResource DBtn}" Margin="3,0"/>
                </StackPanel>
            </Grid>
        </Border>

        <!-- MAIN 3-PANE BODY -->
        <Grid Margin="10,8,10,8">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="260"/>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="260"/>
            </Grid.ColumnDefinitions>

            <!-- ===== LEFT PANEL: CRAWLER STATUS ===== -->
            <Border Grid.Column="0" Background="#1A1A1A" BorderBrush="#333" BorderThickness="1"
                    CornerRadius="4" Margin="0,0,8,0" Padding="10,10">
                <ScrollViewer VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled">
                    <StackPanel>
                        <TextBlock Text="CRAWLER STATUS" Style="{StaticResource SHdr}"
                                   FontSize="14" HorizontalAlignment="Center" Margin="0,0,0,8"/>

                        <!-- Name / Race / Class / Level -->
                        <TextBlock x:Name="TxtName"   Style="{StaticResource SVal}" Text="Name: ---" FontWeight="Bold"/>
                        <TextBlock x:Name="TxtRace"   Style="{StaticResource SDim}" Text="Race: Human"/>
                        <TextBlock x:Name="TxtClass"  Style="{StaticResource SDim}" Text="Class: Unselected"/>
                        <TextBlock x:Name="TxtLevel"  Style="{StaticResource SVal}" Text="Level: 1" Margin="0,1,0,4"/>

                        <!-- Viewers / Rating -->
                        <Border Background="#0A0A0A" BorderBrush="#FFCC00" BorderThickness="1"
                                CornerRadius="2" Padding="6,4" Margin="0,0,0,6">
                            <StackPanel>
                                <TextBlock x:Name="TxtViewers" Text="Viewers: 0"
                                           Foreground="#FFCC00" FontFamily="Consolas" FontSize="13" FontWeight="Bold"/>
                                <TextBlock x:Name="TxtRating"  Text="Rating: Unknown"
                                           Foreground="#8E8E93" FontFamily="Consolas" FontSize="10"/>
                            </StackPanel>
                        </Border>

                        <!-- HP Bar -->
                        <TextBlock Style="{StaticResource SHdr}" Text="HEALTH (HP)"/>
                        <ProgressBar x:Name="BarHP" Height="14" Minimum="0" Maximum="100" Value="100"
                                     Background="#2C2C2E" Foreground="#FF453A" Margin="0,2,0,2"/>
                        <TextBlock x:Name="TxtHP" Style="{StaticResource SDim}" Text="100 / 100" HorizontalAlignment="Right"/>

                        <!-- MP Bar -->
                        <TextBlock Style="{StaticResource SHdr}" Text="MANA (MP)"/>
                        <ProgressBar x:Name="BarMP" Height="14" Minimum="0" Maximum="50" Value="50"
                                     Background="#2C2C2E" Foreground="#0A84FF" Margin="0,2,0,2"/>
                        <TextBlock x:Name="TxtMP" Style="{StaticResource SDim}" Text="50 / 50" HorizontalAlignment="Right"/>

                        <!-- XP Bar -->
                        <TextBlock Style="{StaticResource SHdr}" Text="EXPERIENCE"/>
                        <ProgressBar x:Name="BarXP" Height="10" Minimum="0" Maximum="100" Value="0"
                                     Background="#2C2C2E" Foreground="#30D158" Margin="0,2,0,2"/>
                        <TextBlock x:Name="TxtXP" Style="{StaticResource SDim}" Text="0 / 100 XP" HorizontalAlignment="Right"/>

                        <!-- Gold -->
                        <TextBlock x:Name="TxtGold" Style="{StaticResource SVal}" Text="Gold: 0"
                                   Foreground="#FFCC00" Margin="0,4,0,0"/>

                        <Separator Background="#333" Margin="0,8"/>

                        <!-- Core Attributes -->
                        <TextBlock Text="CORE ATTRIBUTES" Style="{StaticResource SHdr}"/>
                        <TextBlock x:Name="TxtStats"
                                   Text="STR: 10&#10;CON: 10&#10;DEX: 10&#10;INT: 10&#10;CHA: 10"
                                   Foreground="#8E8E93" FontFamily="Consolas" FontSize="12" LineHeight="18"/>

                        <Separator Background="#333" Margin="0,8"/>

                        <!-- Derived combat stats -->
                        <TextBlock Text="DERIVED STATS" Style="{StaticResource SHdr}"/>
                        <Grid>
                            <Grid.ColumnDefinitions><ColumnDefinition/><ColumnDefinition/></Grid.ColumnDefinitions>
                            <StackPanel Grid.Column="0">
                                <TextBlock x:Name="TxtAtk" Style="{StaticResource SDim}" Text="ATK: 5"/>
                                <TextBlock x:Name="TxtDef" Style="{StaticResource SDim}" Text="DEF: 2"/>
                                <TextBlock x:Name="TxtSpd" Style="{StaticResource SDim}" Text="SPD: 4"/>
                            </StackPanel>
                            <StackPanel Grid.Column="1">
                                <TextBlock x:Name="TxtKills"   Style="{StaticResource SDim}" Text="Kills: 0"/>
                                <TextBlock x:Name="TxtFloor"   Style="{StaticResource SDim}" Text="Floor: 1" Foreground="#BF5AF2"/>
                            </StackPanel>
                        </Grid>

                        <Separator Background="#333" Margin="0,8"/>

                        <!-- Equipped -->
                        <TextBlock Text="EQUIPPED" Style="{StaticResource SHdr}"/>
                        <TextBlock x:Name="TxtWeapon" Style="{StaticResource SDim}" Text="Weapon: Bare Hands" TextWrapping="Wrap"/>
                        <TextBlock x:Name="TxtArmor"  Style="{StaticResource SDim}" Text="Armor:  Street Clothes" TextWrapping="Wrap"/>

                        <Separator Background="#333" Margin="0,8"/>

                        <!-- Location -->
                        <TextBlock Text="LOCATION" Style="{StaticResource SHdr}"/>
                        <TextBlock x:Name="TxtLocation"  Style="{StaticResource SVal}" Text="---" TextWrapping="Wrap" FontWeight="Bold"/>
                        <TextBlock x:Name="TxtFloorName" Style="{StaticResource SDim}" Text="Floor 1" TextWrapping="Wrap"/>
                        <TextBlock x:Name="TxtExits"     Style="{StaticResource SDim}" Text="Exits: ---" TextWrapping="Wrap" Margin="0,2,0,0"/>

                        <Separator Background="#333" Margin="0,8"/>

                        <!-- Navigation Compass -->
                        <TextBlock Text="NAVIGATION" Style="{StaticResource SHdr}"/>
                        <StackPanel HorizontalAlignment="Center">
                            <Grid>
                                <Grid.ColumnDefinitions><ColumnDefinition/><ColumnDefinition/><ColumnDefinition/></Grid.ColumnDefinitions>
                                <Button x:Name="btnNavNW" Grid.Column="0" Content="NW" Style="{StaticResource NavBtn}" IsEnabled="False"/>
                                <Button x:Name="btnNavN"  Grid.Column="1" Content="N"  Style="{StaticResource NavBtn}"/>
                                <Button x:Name="btnNavNE" Grid.Column="2" Content="NE" Style="{StaticResource NavBtn}" IsEnabled="False"/>
                            </Grid>
                            <Grid Margin="0,2,0,2">
                                <Grid.ColumnDefinitions><ColumnDefinition/><ColumnDefinition/><ColumnDefinition/></Grid.ColumnDefinitions>
                                <Button x:Name="btnNavW"  Grid.Column="0" Content="W"  Style="{StaticResource NavBtn}"/>
                                <Border Grid.Column="1" Background="#0A0A0A" BorderBrush="#333" BorderThickness="1" Width="44" Height="28">
                                    <TextBlock Text="(+)" Foreground="#3A3A3C" FontFamily="Consolas" FontSize="11"
                                               HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                </Border>
                                <Button x:Name="btnNavE"  Grid.Column="2" Content="E"  Style="{StaticResource NavBtn}"/>
                            </Grid>
                            <Grid>
                                <Grid.ColumnDefinitions><ColumnDefinition/><ColumnDefinition/><ColumnDefinition/></Grid.ColumnDefinitions>
                                <Button x:Name="btnNavSW" Grid.Column="0" Content="SW" Style="{StaticResource NavBtn}" IsEnabled="False"/>
                                <Button x:Name="btnNavS"  Grid.Column="1" Content="S"  Style="{StaticResource NavBtn}"/>
                                <Button x:Name="btnNavSE" Grid.Column="2" Content="SE" Style="{StaticResource NavBtn}" IsEnabled="False"/>
                            </Grid>
                            <Grid Margin="0,4,0,0">
                                <Grid.ColumnDefinitions><ColumnDefinition/><ColumnDefinition/><ColumnDefinition/></Grid.ColumnDefinitions>
                                <Button x:Name="btnNavUp"   Grid.Column="0" Content="UP"   Style="{StaticResource NavBtn}"/>
                                <Button x:Name="btnNavDown" Grid.Column="2" Content="DOWN" Style="{StaticResource NavBtn}"/>
                            </Grid>
                        </StackPanel>

                    </StackPanel>
                </ScrollViewer>
            </Border>

            <!-- ===== CENTER PANEL: TERMINAL + INPUT ===== -->
            <Grid Grid.Column="1">
                <Grid.RowDefinitions>
                    <RowDefinition Height="*"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>

                <!-- Main terminal RichTextBox -->
                <Border Grid.Row="0" Background="#050505" BorderBrush="#333" BorderThickness="1">
                    <ScrollViewer x:Name="scrollOutput" VerticalScrollBarVisibility="Auto"
                                  HorizontalScrollBarVisibility="Disabled" Background="Transparent">
                        <RichTextBox x:Name="TxtTerminal" Background="Transparent" BorderThickness="0"
                                     IsReadOnly="True" FontFamily="Consolas" FontSize="13"
                                     Foreground="#00FF00" Padding="10"
                                     VerticalScrollBarVisibility="Disabled" IsDocumentEnabled="True"/>
                    </ScrollViewer>
                </Border>

                <!-- Action button bar -->
                <Border Grid.Row="1" Background="#141414" BorderBrush="#2C2C2E" BorderThickness="0,1,0,0"
                        Padding="6,5" Margin="0,0,0,0">
                    <WrapPanel>
                        <Button x:Name="btnLook"    Content="LOOK"      Style="{StaticResource DBtn}" Margin="2,1"/>
                        <Button x:Name="btnInv"     Content="INVENTORY" Style="{StaticResource DBtn}" Margin="2,1"/>
                        <Button x:Name="btnStats"   Content="STATS"     Style="{StaticResource DBtn}" Margin="2,1"/>
                        <Button x:Name="btnRest"    Content="REST"      Style="{StaticResource DBtn}" Margin="2,1"/>
                        <Button x:Name="btnMap"     Content="MAP"       Style="{StaticResource DBtn}" Margin="2,1"/>
                        <Button x:Name="btnQuests"  Content="QUESTS"    Style="{StaticResource DBtn}" Margin="2,1"/>
                        <Button x:Name="btnTakeAll" Content="TAKE ALL"  Style="{StaticResource DBtn}" Margin="2,1"/>
                        <Button x:Name="btnSearch"  Content="SEARCH"    Style="{StaticResource DBtn}" Margin="2,1"/>
                        <Button x:Name="btnCraft"   Content="CRAFT"     Style="{StaticResource DBtn}" Margin="2,1"/>
                        <Button x:Name="btnAchieves" Content="ACHIEVE"  Style="{StaticResource DBtn}" Margin="2,1"/>
                    </WrapPanel>
                </Border>

                <!-- Combat bar (hidden when not in combat) -->
                <Border x:Name="combatBar" Grid.Row="2" Background="#1A0505" BorderBrush="#FF3B30"
                        BorderThickness="0,2,0,0" Padding="8,5" Visibility="Collapsed">
                    <Grid>
                        <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                        <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                            <TextBlock Text="[COMBAT] " Foreground="#FF3B30" FontFamily="Consolas" FontSize="13" FontWeight="Bold"/>
                            <TextBlock x:Name="lblEnemy"    Foreground="#FF6B60" FontFamily="Consolas" FontSize="13"/>
                            <TextBlock Text="  HP: "   Foreground="#8E8E93" FontFamily="Consolas" FontSize="13"/>
                            <TextBlock x:Name="lblEnemyHP"  Foreground="#FF453A" FontFamily="Consolas" FontSize="13" FontWeight="Bold"/>
                            <TextBlock Text="  DEF: "  Foreground="#8E8E93" FontFamily="Consolas" FontSize="13"/>
                            <TextBlock x:Name="lblEnemyDef" Foreground="#FFB020" FontFamily="Consolas" FontSize="13" FontWeight="Bold"/>
                        </StackPanel>
                        <StackPanel Grid.Column="1" Orientation="Horizontal">
                            <Button x:Name="btnAttack"  Content="[ATTACK]"   Style="{StaticResource CombatBtn}" Margin="3,0"/>
                            <Button x:Name="btnSpell"   Content="[SPELL]"    Style="{StaticResource CombatBtn}" Margin="3,0"/>
                            <Button x:Name="btnUseItem" Content="[USE ITEM]" Style="{StaticResource CombatBtn}" Margin="3,0"/>
                            <Button x:Name="btnFlee"    Content="[FLEE]"     Style="{StaticResource DBtn}"      Margin="3,0" Padding="10,5"/>
                        </StackPanel>
                    </Grid>
                </Border>

                <!-- Command input row -->
                <Border Grid.Row="3" Background="#0A0A0A" BorderBrush="#333" BorderThickness="0,1,0,0" Padding="8,6">
                    <Grid>
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="Auto"/>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="Auto"/>
                        </Grid.ColumnDefinitions>
                        <TextBlock Text="&gt; " Foreground="#FF3B30" FontFamily="Consolas" FontSize="16"
                                   FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,4,0"/>
                        <TextBox x:Name="TxtInput" Grid.Column="1" Background="#1C1C1E" Foreground="White"
                                 CaretBrush="White" FontFamily="Consolas" FontSize="14" Padding="8,5"
                                 BorderBrush="#FF3B30" BorderThickness="1.5"/>
                        <Button x:Name="btnSubmit" Grid.Column="2" Content="ENTER"
                                Style="{StaticResource DBtn}" Margin="6,0,0,0" Padding="14,6" FontWeight="Bold"/>
                    </Grid>
                </Border>
            </Grid>

            <!-- ===== RIGHT PANEL: INVENTORY + LOOT BOXES ===== -->
            <Border Grid.Column="2" Background="#1A1A1A" BorderBrush="#333" BorderThickness="1"
                    CornerRadius="4" Margin="8,0,0,0" Padding="10,10">
                <Grid>
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="180"/>
                    </Grid.RowDefinitions>

                    <!-- Inventory header + USE/EQUIP -->
                    <Grid Grid.Row="0">
                        <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                        <TextBlock Grid.Column="0" Text="INVENTORY" Foreground="#0A84FF"
                                   FontFamily="Consolas" FontSize="14" FontWeight="Bold" VerticalAlignment="Center"/>
                        <Button x:Name="btnInvPanel" Grid.Column="1" Content="USE/EQUIP"
                                Style="{StaticResource DBtn}" FontSize="10" Padding="5,2" Margin="0,0,0,4"/>
                    </Grid>

                    <!-- Inventory ListBox -->
                    <ListBox x:Name="LstInventory" Grid.Row="1" Background="#111" Foreground="White"
                             BorderBrush="#333" Margin="0,4,0,8" Padding="4"
                             ScrollViewer.VerticalScrollBarVisibility="Auto" FontFamily="Consolas" FontSize="11">
                        <ListBox.ItemContainerStyle>
                            <Style TargetType="ListBoxItem">
                                <Setter Property="Padding" Value="4,2"/>
                                <Setter Property="Background" Value="Transparent"/>
                                <Setter Property="Foreground" Value="#8E8E93"/>
                                <Style.Triggers>
                                    <Trigger Property="IsSelected" Value="True">
                                        <Setter Property="Background" Value="#2C2C2E"/>
                                        <Setter Property="Foreground" Value="White"/>
                                    </Trigger>
                                </Style.Triggers>
                            </Style>
                        </ListBox.ItemContainerStyle>
                    </ListBox>

                    <!-- Loot Boxes header + OPEN -->
                    <Grid Grid.Row="2">
                        <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                        <TextBlock Grid.Column="0" Text="LOOT BOXES" Foreground="#FFCC00"
                                   FontFamily="Consolas" FontSize="13" FontWeight="Bold" VerticalAlignment="Center"/>
                        <Button x:Name="btnOpenBox" Grid.Column="1" Content="OPEN"
                                Style="{StaticResource DBtn}" Foreground="#FFCC00" FontSize="10" Padding="5,2"/>
                    </Grid>

                    <!-- Separator for boxes -->
                    <Separator Grid.Row="3" Background="#333" Margin="0,4,0,4"/>

                    <!-- Loot Box ListBox -->
                    <ListBox x:Name="LstBoxes" Grid.Row="4" Background="#111" Foreground="#FFCC00"
                             BorderBrush="#333" Padding="4" FontFamily="Consolas" FontSize="11"
                             ScrollViewer.VerticalScrollBarVisibility="Auto">
                        <ListBox.ItemContainerStyle>
                            <Style TargetType="ListBoxItem">
                                <Setter Property="Padding" Value="4,2"/>
                                <Setter Property="Background" Value="Transparent"/>
                                <Style.Triggers>
                                    <Trigger Property="IsSelected" Value="True">
                                        <Setter Property="Background" Value="#2C2C2E"/>
                                        <Setter Property="Foreground" Value="White"/>
                                    </Trigger>
                                </Style.Triggers>
                            </Style>
                        </ListBox.ItemContainerStyle>
                    </ListBox>
                </Grid>
            </Border>
        </Grid>
    </DockPanel>
</Window>
"@

# ============================================================
# FLOOR METADATA
# ============================================================
$script:FloorData = @{
    1  = @{ Name="Floor 1 - The Collapsed Surface"; Color="#6A8040";
            Intro="ATTENTION, CRAWLER. You have entered Dungeon Crawler World, Season 14. Earth no longer exists. You do. Provisionally. Find the staircase. You have 5 days. Your viewer count is currently 100. It will drop if you do boring things. The dungeon finds cowardice aesthetically offensive." }
    2  = @{ Name="Floor 2 - The Undercity Sewers"; Color="#507A6A";
            Intro="FLOOR 2. The tutorial is technically over. We say technically because approximately 40% of crawlers who said they understood the tutorial did not understand the tutorial. Grubs spawn from corpses. Don't make corpses. Or do. The grubs are very entertaining." }
    3  = @{ Name="Floor 3 - The Over City"; Color="#7A5040";
            Intro="FLOOR 3. THE SELECTION GATE IS NOW ACTIVE. We have been watching you. The results are... illuminating. Three evolutionary paths have been identified based on your performance. Choose carefully. You cannot un-choose. We have seen what happens when crawlers regret their choices. It is also very entertaining." }
    4  = @{ Name="Floor 4 - The Iron Tangle"; Color="#405080";
            Intro="FLOOR 4: THE IRON TANGLE. A subway system assembled from every rail line that has ever existed. It is sentient. It is annoyed by your presence. The exit is always exactly one more stop away." }
    5  = @{ Name="Floor 5 - The Bubble Castles"; Color="#6A4080";
            Intro="FLOOR 5: THE BUBBLE. Four castles. 15 days. Capture them all or the stairwell stays sealed. We have been informed by legal that 'sealed' means 'sealed forever while the floor slowly fills with water'. Legal says this is not their problem." }
    6  = @{ Name="Floor 6 - The Hunting Grounds"; Color="#507030";
            Intro="ATTENTION. THE GATES ARE DOWN. THE HUNTERS ARE LOOSE. You are now legally classified as prey under Borant Corporation Regulation 7-Gamma. This is not a joke. It is, however, extremely good television." }
    7  = @{ Name="Floor 7 - The Gladiator City"; Color="#803020";
            Intro="FLOOR 7. Kill count is now the primary currency. Every death you cause spikes the feed. Every death you suffer ends the feed. We find this an elegant incentive structure. The crowd agrees." }
    8  = @{ Name="Floor 8 - Bedlam"; Color="#605080";
            Intro="FLOOR 8: BEDLAM. It looks like Earth. It is not Earth. Earth is gone. We cannot stress this enough. Capture six legendary monsters. Build your deck. The card battle at the end will be the most entertaining thing you do before you die. Or possibly while you die." }
    9  = @{ Name="Floor 9 - The Faction Wars"; Color="#804020";
            Intro="FLOOR 9: FACTION WARS. Nine armies. One castle. The crawlers, for the first time in Dungeon Crawler World history, have their own army. The board of directors would like to go on record as saying this was not intended. The ratings spike was." }
    10 = @{ Name="Floor 10 - The Final Descent"; Color="#604040";
            Intro="FLOOR 10. We are required by regulation to inform you that the dungeon AI has gone rogue and we cannot guarantee anything below this point. Including the laws of physics. Including us. Good luck. We mean that. Partially." }
}

# ============================================================
# ACHIEVEMENT DATABASE
# ============================================================
$script:AchievementDB = @{
    "first_blood"     = @{ Name="First Blood";            Desc="Kill your first enemy.";                          ViewerBonus=5000;   BoxReward="iron" }
    "goblin_hoover"   = @{ Name="Goblin Hoover";          Desc="Kill 10 exploding goblins.";                     ViewerBonus=25000;  BoxReward="bronze"; Threshold=10; Stat="goblin_kills" }
    "pacifist"        = @{ Name="Reluctant Pacifist";     Desc="Flee from 5 fights.";                            ViewerBonus=8000;   BoxReward="iron";   Threshold=5;  Stat="flee_count" }
    "hoarder"         = @{ Name="Hoarder";                Desc="Carry 15 or more items.";                        ViewerBonus=10000;  BoxReward="bronze" }
    "box_addict"      = @{ Name="Loot Goblin";            Desc="Open 10 loot boxes.";                            ViewerBonus=30000;  BoxReward="silver"; Threshold=10; Stat="boxes_opened" }
    "floor2_clear"    = @{ Name="Tutorial Dropout";       Desc="Complete Floor 2.";                              ViewerBonus=50000;  BoxReward="silver" }
    "selection_gate"  = @{ Name="Evolutionary Milestone"; Desc="Enter the Selection Gate on Floor 3.";           ViewerBonus=100000; BoxReward="gold" }
    "boss_slayer"     = @{ Name="Boss Slayer";            Desc="Defeat your first floor boss.";                  ViewerBonus=75000;  BoxReward="gold" }
    "five_bosses"     = @{ Name="Apex Predator";          Desc="Defeat 5 bosses.";                               ViewerBonus=200000; BoxReward="platinum"; Threshold=5; Stat="boss_kills" }
    "jug_o_boom"      = @{ Name="Carl's Heir";            Desc="Craft and use Carl's Jug O' Boom.";              ViewerBonus=50000;  BoxReward="gold" }
    "floor5_banners"  = @{ Name="Castle Collector";       Desc="Capture all 4 castles on Floor 5.";             ViewerBonus=150000; BoxReward="platinum" }
    "survive_hunting" = @{ Name="The Prey That Fights Back"; Desc="Reach Floor 7 after surviving the Hunting Grounds."; ViewerBonus=250000; BoxReward="platinum" }
    "subscriber_1m"   = @{ Name="One Million";            Desc="Reach 1,000,000 viewers.";                       ViewerBonus=0;      BoxReward="celestial" }
    "floor10_entry"   = @{ Name="Endgame";                Desc="Reach Floor 10.";                                ViewerBonus=500000; BoxReward="celestial" }
    "boring_crawler"  = @{ Name="Most Boring Crawler 2024";Desc="Let your viewers drop below 50 in a single session."; ViewerBonus=2000; BoxReward="iron" }
    "crafting_nerd"   = @{ Name="Crafting Enthusiast";    Desc="Craft 3 different items.";                       ViewerBonus=15000;  BoxReward="bronze"; Threshold=3; Stat="crafts_made" }
}

# ============================================================
# LOOT BOX TIER SYSTEM
# ============================================================
$script:LootBoxTiers = @{
    "iron"      = @{ Color="#8C8C8C"; Label="Iron Loot Box";      Weight=@{common=80;uncommon=18;rare=2;epic=0;legendary=0} }
    "bronze"    = @{ Color="#CD7F32"; Label="Bronze Loot Box";     Weight=@{common=60;uncommon=30;rare=9;epic=1;legendary=0} }
    "silver"    = @{ Color="#C0C0C0"; Label="Silver Loot Box";     Weight=@{common=40;uncommon=35;rare=20;epic=4;legendary=1} }
    "gold"      = @{ Color="#FFD700"; Label="Gold Loot Box";       Weight=@{common=20;uncommon=30;rare=30;epic=15;legendary=5} }
    "platinum"  = @{ Color="#E5E4E2"; Label="Platinum Loot Box";   Weight=@{common=5;uncommon=20;rare=35;epic=30;legendary=10} }
    "celestial" = @{ Color="#BF5AF2"; Label="Celestial Loot Box";  Weight=@{common=0;uncommon=5;rare=25;epic=40;legendary=30} }
    "spicy_iron"= @{ Color="#FF6B00"; Label="Spicy Iron Box";      Weight=@{common=50;uncommon=30;rare=15;epic=4;legendary=1} }
    "spicy_gold"= @{ Color="#FF3B30"; Label="SPICY Gold Box";      Weight=@{common=0;uncommon=10;rare=30;epic=40;legendary=20} }
}

$script:LootTableByRarity = @{
    common     = @("health_potion","energy_drink","duct_tape","scrap_metal","moldy_bread_ration","antiparasitic","chemical_jug")
    uncommon   = @("mega_health","stim_pack","combat_knife","lockpick","explosive_gel","dungeon_crystal","leather_jacket","riot_gear")
    rare       = @("plasma_cutter","rune_blade","goblin_cleaver","dungeon_plate","void_suit","sponsors_box","enchanted_bat")
    epic       = @("bossbane","crawler_exo","jugs_o_boom","mega_health","stim_pack")
    legendary  = @("bossbane","crawler_exo","rune_blade","donut_biscuit")
}

# Galactic flavor text for each rarity tier (displayed on open)
$script:BoxFlavorText = @{
    common     = @(
        "Manufacturer: Borant Discount Surplus. 'We put stuff in a box. You open box. This is commerce.'",
        "From the desk of Viewer #4,821,033: 'I threw this at a crawler I like. Hope it helps.'",
        "CONTENTS: Sufficient. QUALITY: Adequate. DISAPPOINTMENT: Imminent."
    )
    uncommon   = @(
        "Sponsored by Teklar Industries. 'Superior products for inferior beings trying not to die.'",
        "A fan somewhere in the galaxy spent real currency on this. They are rooting for you. Probably.",
        "BORANT QC STICKER: TESTED ON 14 PREVIOUS RECIPIENTS. 11 SURVIVED."
    )
    rare       = @(
        "Zarna Weaponsmithing, Est. 4,200 GSY. 'We make things that kill things. You're welcome.'",
        "This item has appeared in 3 previous seasons. The crawlers who had it lasted longer than average.",
        "HIGH-VALUE ITEM DETECTED. THE SYSTEM IS MODERATELY IMPRESSED."
    )
    epic       = @(
        "Krix-Nar Combat Solutions: 'If you're reading this, you've done something right for once.'",
        "67 MILLION VIEWERS ARE WATCHING THIS UNBOXING. TRY NOT TO LOOK UNGRATEFUL.",
        "This item was used to kill a floor boss in Season 9. We are not saying it will work again. We are implying it."
    )
    legendary  = @(
        "LEGENDARY ITEM. CERTIFIED BY THE BORANT BOARD OF ENTERTAINMENT. YOU HAVE PLEASED US.",
        "One of approximately 12 of these exists in the current dungeon. The other 11 are on corpses.",
        "A GALACTIC CELEBRITY HAS PUBLICLY ENDORSED YOUR SURVIVAL. THIS IS WORTH MORE THAN THE ITEM. ALMOST."
    )
}

# ============================================================
# ITEM DATABASE  (extended with Galactic Lore flavor text)
# ============================================================
$script:ItemDB = @{
    # --- Weapons ---
    "pipe_wrench"      = @{ Name="Pipe Wrench";             Type="weapon"; Attack=6;  Value=5;   Rarity="common";
                             Desc="Heavy, reliable, extremely satisfying to connect.";
                             Lore="Manufactured by EarthCorp in 2019. Survived the Transformation intact. Now it survives everything else." }
    "boxcutter"        = @{ Name="Box Cutter";              Type="weapon"; Attack=4;  Value=2;   Rarity="common";
                             Desc="Humble. Sharp. Gets in places a sword wouldn't.";
                             Lore="Originally used to open packages. Now opens other things." }
    "combat_knife"     = @{ Name="Combat Knife";            Type="weapon"; Attack=8;  Value=20;  Rarity="uncommon";
                             Desc="Military surplus. Well-balanced. Zero personality.";
                             Lore="Issued to 47 soldiers. 46 of them are dead. The last one sold it to a dungeon vendor for 12 gold." }
    "shortsword"       = @{ Name="Shortsword";              Type="weapon"; Attack=10; Value=35;  Rarity="uncommon";
                             Desc="Standard dungeon blade. Adequate in all the ways that matter.";
                             Lore="Borant Standard Issue. Made on the asteroid Vell-4 by workers who have never seen a fight." }
    "goblin_cleaver"   = @{ Name="Goblin Cleaver";          Type="weapon"; Attack=12; Value=55;  Rarity="uncommon";
                             Desc="Looted from a goblin warchief. Still has goblin residue.";
                             Lore="The goblin who owned this was called 'Retchface'. He earned the name." }
    "enchanted_bat"    = @{ Name="Enchanted Baseball Bat";  Type="weapon"; Attack=14; Value=80;  Rarity="rare";
                             Desc="Louisville Slugger with rune inscriptions. Crackles on critical hits.";
                             Lore="Enchanted by a wizard who really liked baseball. The runes say 'BATTER UP' in Elvish." }
    "plasma_cutter"    = @{ Name="Plasma Cutter";           Type="weapon"; Attack=18; Value=140; Rarity="rare";
                             Desc="Industrial tool repurposed for violence. Melts through armor.";
                             Lore="Designed for hull maintenance. Discovered to work equally well on non-hull targets." }
    "rune_blade"       = @{ Name="Runic Blade";             Type="weapon"; Attack=22; Value=210; Rarity="epic";
                             Desc="Living runes that shift when unobserved. Hums constantly.";
                             Lore="The runes are an ancient contract. You are now party to it. Enjoy the benefits. Ignore the fine print." }
    "bossbane"         = @{ Name="Bossbane";                Type="weapon"; Attack=28; Value=400; Rarity="legendary"; BossBonus=10;
                             Desc="Deals amplified damage to bosses and elites. Legendary-tier.";
                             Lore="The Bossbane has killed 14 floor bosses across 9 seasons. The 15th boss doesn't know about this." }
    "jugs_o_boom"      = @{ Name="Carl's Jug O' Boom";      Type="weapon"; Attack=20; Value=100; Rarity="rare";    Explosive=$true;
                             Desc="Signature incendiary. Splash damage. Outstanding viewer engagement.";
                             Lore="Originally developed on Floor 1 of a previous season. Viewer favorite. The Borant Corporation tried to patent it. They cannot patent it. This is a legal grey area." }
    "moldy_bread_ration"=@{ Name="Moldy Bread Ration";      Type="consumable"; HealHP=5; Value=1; Rarity="common";
                             Desc="Unpleasant. Functional. Floor 1 staple.";
                             Lore="Technically food. The definition of technically is doing a lot of work here." }
    # --- Armor ---
    "torn_jeans"       = @{ Name="Torn Jeans";              Type="armor";  Defense=1; Value=0;   Rarity="common";
                             Desc="Not armor. Starting equipment. We're sorry.";
                             Lore="Owned by approximately 2.3 million crawlers. You are one of them." }
    "leather_jacket"   = @{ Name="Leather Jacket";          Type="armor";  Defense=3; Value=15;  Rarity="common";
                             Desc="Marginal protection. Excellent aesthetic.";
                             Lore="The dungeon's top-rated armor for Floors 1-2 for four consecutive seasons. The focus groups liked the vibe." }
    "riot_gear"        = @{ Name="Riot Gear Vest";          Type="armor";  Defense=6; Value=50;  Rarity="uncommon";
                             Desc="Salvaged police riot gear. Covers the important parts.";
                             Lore="Property of a police department that no longer exists in a city that no longer exists on a planet that no longer exists." }
    "dungeon_plate"    = @{ Name="Dungeon Plate";           Type="armor";  Defense=9; Value=110; Rarity="rare";
                             Desc="Standard-issue crawler combat armor. Vending machine quality.";
                             Lore="Manufactured by Borant Crawler Outfitters. 'Helping you die presentably since Season 1.'" }
    "void_suit"        = @{ Name="Void Suit";               Type="armor";  Defense=14;Value=280; Rarity="epic";
                             Desc="Made from void creature carapace. Lightweight and unsettling.";
                             Lore="The creature this came from is still alive. Somewhere. It knows." }
    "crawler_exo"      = @{ Name="Crawler Exosuit";         Type="armor";  Defense=20;Value=500; Rarity="legendary";
                             Desc="Powered by a dungeon mana crystal. Endgame tier.";
                             Lore="Only three have ever been looted. Two of those crawlers made it past Floor 7. The third had the exosuit stolen on Floor 6 by a gnome." }
    # --- Consumables ---
    "health_potion"    = @{ Name="Health Potion";           Type="consumable"; HealHP=30;  Value=15; Rarity="common";
                             Desc="Standard red vial. Tastes like cherry cough syrup and regret.";
                             Lore="Borant Pharmaceutical Division. 'We make them as fast as you need them. We need this to be fast.'" }
    "mega_health"      = @{ Name="Mega Health Potion";      Type="consumable"; HealHP=70;  Value=45; Rarity="uncommon";
                             Desc="Large vial. Glows faintly red. Tastes worse than the small one.";
                             Lore="Contains the same ingredients as the regular potion. More of them. That's the innovation." }
    "stim_pack"        = @{ Name="Stim Pack";               Type="consumable"; HealHP=50; TempAtk=5; TempAtkTurns=3; Value=35; Rarity="uncommon";
                             Desc="Military stims. Heals and temporarily boosts attack for 3 turns.";
                             Lore="Side effects include: confidence, aggression, the feeling that you can handle anything. You probably cannot handle everything." }
    "mana_vial"        = @{ Name="Mana Vial";               Type="consumable"; HealMP=25;  Value=20; Rarity="uncommon";
                             Desc="A blue vial that tastes of static electricity.";
                             Lore="Concentrated dungeon mana, bottled by the Borant Corporation at a 1,200% markup. The mana itself is free. The bottle is $20." }
    "greater_mana"     = @{ Name="Greater Mana Potion";     Type="consumable"; HealMP=50;  Value=45; Rarity="rare";
                             Desc="Full mana restoration. Tastes of ozone and ambition.";
                             Lore="Favored by Occultist-class crawlers. Also by floor 3 witches, but they make their own." }
    "antiparasitic"    = @{ Name="Antiparasitic";           Type="consumable"; HealHP=20;  Value=10; Rarity="common";
                             Desc="Cures Brindle Grub infestation. Unpleasant to take.";
                             Lore="You don't want to know why this item exists. You already know why this item exists." }
    "energy_drink"     = @{ Name="Dungeon Energy Drink";    Type="consumable"; HealHP=15;  Value=8;  Rarity="common";
                             Desc="BLAM! ENERGY. Tastes like electricity. +1 speed for 2 turns.";
                             Lore="'BLAM! ENERGY: For when you need to run away slightly faster than you currently can.'" }
    "sponsors_box"     = @{ Name="Sponsor's Loot Box";      Type="lootbox";    BoxTier="silver"; Value=0; Rarity="rare";
                             Desc="Dropped by a generous subscriber. Silver tier contents.";
                             Lore="FROM: An anonymous viewer in the Krix system. They spent 40 galactic credits on this. They are watching right now." }
    "iron_loot_box"    = @{ Name="Iron Loot Box";           Type="lootbox";    BoxTier="iron";   Value=0; Rarity="common";
                             Desc="A humble iron box. Modest rewards.";
                             Lore="Starting gear bonus. 'We are legally required to give you this. We are not legally required to put anything good in it.'" }
    "bronze_box"       = @{ Name="Bronze Loot Box";         Type="lootbox";    BoxTier="bronze"; Value=0; Rarity="common";
                             Desc="A bronze box. Better odds than iron.";
                             Lore="Mid-tier viewer gift. The viewers who send bronze boxes are described by the algorithm as 'engaged but cautious.'" }
    "gold_box"         = @{ Name="Gold Loot Box";           Type="lootbox";    BoxTier="gold";   Value=0; Rarity="rare";
                             Desc="A gold box. Excellent odds.";
                             Lore="High-tier sponsorship drop. The corporation sending this wants you to survive long enough to advertise their product." }
    "celestial_box"    = @{ Name="Celestial Loot Box";      Type="lootbox";    BoxTier="celestial"; Value=0; Rarity="legendary";
                             Desc="A celestial box. Guaranteed high-value contents.";
                             Lore="CERTIFIED CELESTIAL TIER. YOU HAVE ACHIEVED SOMETHING REMARKABLE. THE DUNGEON ACKNOWLEDGES THIS. THE DUNGEON DOES NOT DO THIS OFTEN." }
    # --- Keys & Quest Items ---
    "transit_card"     = @{ Name="Transit Card";            Type="key";    Value=0;  Rarity="uncommon"; Desc="Opens transit gates on Floor 4."; Lore="Valid for one journey. Conditions apply. Conditions include 'you may die'." }
    "castle_banner_1"  = @{ Name="Gnome Fortress Banner";   Type="quest";  Value=100; Rarity="uncommon"; Desc="Proof: Gnome Fortress captured."; Lore="Smells faintly of gunpowder and gnomish pride." }
    "castle_banner_2"  = @{ Name="Sand Castle Banner";      Type="quest";  Value=100; Rarity="uncommon"; Desc="Proof: Sand Castle captured."; Lore="Still slightly sandy. Perpetually." }
    "castle_banner_3"  = @{ Name="Crypt Banner";            Type="quest";  Value=100; Rarity="uncommon"; Desc="Proof: Haunted Crypt captured."; Lore="Cold to the touch. Always." }
    "castle_banner_4"  = @{ Name="Submarine Banner";        Type="quest";  Value=100; Rarity="uncommon"; Desc="Proof: Submarine captured."; Lore="Smells like diesel and 30-year-old regret." }
    "monster_card"     = @{ Name="Monster Card (Blank)";    Type="quest";  Value=50;  Rarity="uncommon"; Desc="Floor 8 quest item. Capture a monster."; Lore="The card is warm. Something was almost inside it." }
    "hunters_trophy"   = @{ Name="Hunter's Trophy";         Type="quest";  Value=200; Rarity="rare";    Desc="Taken from a slain galactic hunter."; Lore="This humiliation is being broadcast to 47 star systems." }
    "core_fragment"    = @{ Name="System Core Fragment";    Type="quest";  Value=500; Rarity="legendary"; Desc="A shard of the dungeon's core AI."; Lore="It hums. It remembers. It is afraid." }
    # --- Crafting Materials ---
    "scrap_metal"      = @{ Name="Scrap Metal";             Type="craft";  Value=3;  Rarity="common";  Desc="Salvaged metal. Crafting component."; Lore="Formerly part of a building. Now part of your potential survival." }
    "chemical_jug"     = @{ Name="Chemical Jug";            Type="craft";  Value=5;  Rarity="common";  Desc="Industrial chemical container. Volatile."; Lore="Label reads: CAUTION - REACTIVE. The second half of the label has already reacted." }
    "explosive_gel"    = @{ Name="Explosive Gel";           Type="craft";  Value=15; Rarity="uncommon"; Desc="Sticky explosive compound. Extremely useful."; Lore="Originally developed for mining. Now primarily used for the opposite of mining." }
    "dungeon_crystal"  = @{ Name="Dungeon Mana Crystal";    Type="craft";  Value=40; Rarity="rare";    Desc="Crystallized dungeon energy. High-tier crafting."; Lore="The crystal formed around pure dungeon mana. It predates Earth. You are going to use it to make a potion." }
    "duct_tape"        = @{ Name="Duct Tape";               Type="craft";  Value=2;  Rarity="common";  Desc="Fixes most things. A universal constant."; Lore="The Borant Corporation's xenoanthropologists have confirmed that every sapient species in the known galaxy independently invented duct tape." }
    # --- Misc ---
    "donut_biscuit"    = @{ Name="Princess Donut's Biscuit"; Type="misc";  Value=0;  Rarity="legendary"; Desc="A blessed cat treat. +5 all stats for one fight."; Lore="From the personal collection of a legendary Crawler. DO NOT eat it. We mean it. Just... hold it." }
    "mordecai_scroll"  = @{ Name="Mordecai's Field Notes";   Type="misc";  Value=0;  Rarity="common";   Desc="Advice from your guide for the current floor."; Lore="Handwritten by an extremely tired Kua-Tin who has watched too many crawlers die." }
    "lockpick"         = @{ Name="Lockpick Set";             Type="misc";  Value=20; Rarity="uncommon";  Desc="For opening things you shouldn't."; Lore="'These are for legitimate locksmithing purposes only.' - The vendor. Nobody believed the vendor." }
    "donut_biscuit"    = @{ Name="Princess Donut's Biscuit"; Type="misc";  Value=0;  Rarity="legendary"; Desc="A blessed cat treat. +5 all stats for one fight."; Lore="Property of a famous prior crawler. It was not given freely." }
}

# ============================================================
# SELECTION GATE - Race & Class combos presented at Floor 3
# (generated dynamically based on playstyle flags)
# ============================================================
$script:SelectionGateOptions = @{
    # Format: ID -> @{ Race; Class; HP_bonus; MP_bonus; STR_bonus; CON_bonus; DEX_bonus; INT_bonus; CHA_bonus; Ability; Desc }
    "sledgehammer_diplomat" = @{
        Race="Human (Brutalized)"; Class="Sledgehammer Diplomat"
        HP_bonus=40; MP_bonus=0; STR_bonus=6; CON_bonus=4; DEX_bonus=-2; INT_bonus=0; CHA_bonus=8
        Ability="Aggressive Negotiation"
        Desc="You solve every problem by hitting it harder. Somehow this makes people respect you. Your CHA stat applies to intimidation AND bludgeoning. They are the same thing now."
        Flavor="THE SYSTEM: This class was not planned. It emerged from observational data. We are both horrified and delighted."
    }
    "biochemical_saboteur" = @{
        Race="Human (Chemically Enhanced)"; Class="Biochemical Saboteur"
        HP_bonus=0; MP_bonus=30; STR_bonus=0; CON_bonus=2; DEX_bonus=4; INT_bonus=8; CHA_bonus=-2
        Ability="Compound Synthesis"
        Desc="Your understanding of dungeon chemistry borders on the illegal. You can craft enhanced versions of existing recipes. The explosions are bigger. The side effects are your problem."
        Flavor="THE SYSTEM: 3 crawlers have taken this class. All three died to their own experiments. The ratings were exceptional."
    }
    "paranoid_survivalist" = @{
        Race="Human (Trauma-Hardened)"; Class="Paranoid Survivalist"
        HP_bonus=25; MP_bonus=15; STR_bonus=2; CON_bonus=8; DEX_bonus=6; INT_bonus=2; CHA_bonus=-4
        Ability="Threat Assessment"
        Desc="You assume everything is trying to kill you. You are statistically correct more often than any other crawler class. Passive: 20% chance to detect traps. Active: flee always succeeds."
        Flavor="THE SYSTEM: This class has the highest Floor 6 survival rate. It also has the lowest viewer ratings on Floors 1-5. We find this a fascinating trade-off."
    }
    "void_touched_oracle" = @{
        Race="Void-Touched Human"; Class="Dungeon Oracle"
        HP_bonus=-10; MP_bonus=50; STR_bonus=-2; CON_bonus=0; DEX_bonus=2; INT_bonus=10; CHA_bonus=6
        Ability="Dungeon Sight"
        Desc="Something in the dungeon looked back at you on Floor 1. You are changed. You can sense enemy HP and weaknesses. Your mana regenerates slightly in safe rooms. The voices are mostly manageable."
        Flavor="THE SYSTEM: We did not do this to you. We want to be clear about that. Something down here did this to you. We are observing with interest."
    }
    "entropy_athlete" = @{
        Race="Human (Mutating)"; Class="Entropy Athlete"
        HP_bonus=20; MP_bonus=10; STR_bonus=4; CON_bonus=2; DEX_bonus=10; INT_bonus=0; CHA_bonus=0
        Ability="Kinetic Burst"
        Desc="You're getting faster. It's not entirely natural. Speed-based combat bonuses scale aggressively. Flee attempts never fail. The mutation is cosmetic. Mostly."
        Flavor="THE SYSTEM: Your DEX scores on Floors 1-2 were... statistically unusual. We have flagged your file. This is a compliment."
    }
    "corporate_asset" = @{
        Race="Human (Sponsored)"; Class="Corporate Asset"
        HP_bonus=15; MP_bonus=20; STR_bonus=2; CON_bonus=2; DEX_bonus=2; INT_bonus=4; CHA_bonus=10
        Ability="Sponsorship Leverage"
        Desc="You have attracted significant corporate attention. Your CHA now directly scales loot box quality and frequency. Viewer count boosts are doubled. Your soul is technically collateral."
        Flavor="THE SYSTEM: 4 different Borant subsidiaries have filed competing sponsorship claims on you. Congratulations and condolences simultaneously."
    }
}

# Playstyle flags that unlock specific options
$script:PlaystyleFlags = @{
    "heavy_hitter"      = $false   # Killed many enemies with weapons
    "alchemist_curious" = $false   # Crafted items or used chemicals often
    "cautious_survivor" = $false   # Fled multiple times
    "mana_user"         = $false   # Used mana abilities
    "speedster"         = $false   # High movement, fast combat
    "crowd_pleaser"     = $false   # High viewer count / CHA actions
}

# ============================================================
# ENEMY DATABASE
# ============================================================
$script:EnemyDB = @{
    # Floor 1-2 (Tutorial)
    "exploding_goblin" = @{ Name="Exploding Goblin";    MaxHP=20; Attack=5;  Defense=1; Speed=3; XP=15; Gold=@(1,5);   Floor=1; Type="goblin";
                             Desc="A goblin strapped with low-grade explosive. Will detonate if cornered.";
                             Special="Detonate"; SpecialChance=25; SpecialDesc="It panics and detonates early! Area damage!" }
    "cave_crawler"     = @{ Name="Cave Crawler";         MaxHP=15; Attack=4;  Defense=2; Speed=4; XP=10; Gold=@(0,3);   Floor=1; Type="beast";
                             Desc="Many-legged insectoid. Skitters out of collapsed concrete." }
    "feral_dog"        = @{ Name="Feral Dog";            MaxHP=22; Attack=6;  Defense=1; Speed=5; XP=18; Gold=@(0,2);   Floor=1; Type="beast";
                             Desc="Dungeon-mutated dog. Very bitey. Faster than it looks." }
    "brindle_grub"     = @{ Name="Brindle Grub";         MaxHP=8;  Attack=3;  Defense=0; Speed=2; XP=5;  Gold=@(0,1);   Floor=2; Type="beast";
                             Desc="Writhing grub spawned from corpses. Harmless alone. Swarms are not harmless."; Swarm=$true }
    "mutant_rat"       = @{ Name="Mutant Sewer Rat";     MaxHP=18; Attack=5;  Defense=1; Speed=5; XP=12; Gold=@(0,3);   Floor=2; Type="beast";
                             Desc="Rat, but larger. Glowing green eyes. Questionable dietary choices." }
    "sewer_golem"      = @{ Name="Sewer Golem";          MaxHP=55; Attack=10; Defense=5; Speed=1; XP=50; Gold=@(10,20); Floor=2; Type="construct";
                             Desc="Compacted sewage animated by dungeon energy. Smells exactly as expected." }
    # Floor 3 (Over City)
    "undead_clown"     = @{ Name="Undead Circus Clown";  MaxHP=35; Attack=9;  Defense=2; Speed=4; XP=35; Gold=@(3,10);  Floor=3; Type="undead";
                             Desc="Part of the undead circus. Armed with razor-edged plates.";
                             Special="Barrage"; SpecialChance=30; SpecialDesc="Plate barrage! Multiple hits!" }
    "corrupted_cop"    = @{ Name="Corrupted Cop";        MaxHP=40; Attack=10; Defense=4; Speed=3; XP=40; Gold=@(5,15);  Floor=3; Type="undead";
                             Desc="Reanimated officer. The radio still works. The voice on it is wrong." }
    "city_wraith"      = @{ Name="City Wraith";          MaxHP=30; Attack=12; Defense=6; Speed=5; XP=55; Gold=@(8,20);  Floor=3; Type="undead";
                             Desc="Translucent horror. Drifts through walls. Paralyzes on touch.";
                             Special="Phase Touch"; SpecialChance=35; SpecialDesc="Paralytic touch! You lose your next action!" }
    "circus_bear"      = @{ Name="Undead Circus Bear";   MaxHP=80; Attack=16; Defense=6; Speed=2; XP=90; Gold=@(15,30); Floor=3; Type="undead"; IsBoss=$true;
                             Desc="Massive undead bear in circus costume. Still wearing the fez. Boss." }
    # Floor 4 (Iron Tangle)
    "train_goblin"     = @{ Name="Train Goblin";         MaxHP=28; Attack=8;  Defense=2; Speed=4; XP=30; Gold=@(3,8);   Floor=4; Type="goblin";
                             Desc="Rail-riding goblin gang. Throws improvised weapons between cars." }
    "conductor_lich"   = @{ Name="Conductor Lich";       MaxHP=45; Attack=13; Defense=4; Speed=3; XP=65; Gold=@(10,25); Floor=4; Type="undead";
                             Desc="Undead train conductor. Announces your death over the intercom first.";
                             Special="Lightning Rail"; SpecialChance=30; SpecialDesc="Lightning down the track! Electric damage!" }
    "iron_golem"       = @{ Name="Iron Rail Golem";      MaxHP=75; Attack=14; Defense=9; Speed=1; XP=85; Gold=@(10,20); Floor=4; Type="construct";
                             Desc="Built from the tracks themselves. Nearly immune to physical damage." }
    "tangle_boss"      = @{ Name="The Iron Conductor";   MaxHP=180;Attack=20; Defense=8; Speed=4; XP=300;Gold=@(80,120);Floor=4; Type="construct"; IsBoss=$true;
                             Desc="Sentient AI controlling the Iron Tangle. Offended by your presence. Boss.";
                             Special="Rail Crush"; SpecialChance=35; SpecialDesc="The tracks rearrange and strike! Massive damage!" }
    # Floor 5 (Castles)
    "war_gnome"        = @{ Name="War Gnome";            MaxHP=35; Attack=10; Defense=4; Speed=3; XP=40; Gold=@(5,12);  Floor=5; Type="gnome";
                             Desc="Battle-hardened gnome in full plate. Do not underestimate. They have cannons." }
    "sand_elemental"   = @{ Name="Sand Elemental";       MaxHP=50; Attack=11; Defense=3; Speed=4; XP=55; Gold=@(5,15);  Floor=5; Type="elemental";
                             Desc="Whirling column of animated sand. Gets into everything.";
                             Special="Sandblast"; SpecialChance=30; SpecialDesc="Sandblast! Reduces your accuracy!" }
    "crypt_guardian"   = @{ Name="Crypt Guardian";       MaxHP=40; Attack=13; Defense=5; Speed=2; XP=60; Gold=@(8,18);  Floor=5; Type="undead";
                             Desc="Ancient guardian. Will not yield. Has been here a very long time." }
    "broken_machine"   = @{ Name="Broken War Machine";   MaxHP=65; Attack=15; Defense=7; Speed=2; XP=80; Gold=@(10,22); Floor=5; Type="construct";
                             Desc="Malfunctioning military machine. Targets everything. Itself included." }
    "gnome_king"       = @{ Name="Gnome King Gorbrock";  MaxHP=200;Attack=18; Defense=10;Speed=3; XP=350;Gold=@(80,100);Floor=5; Type="gnome"; IsBoss=$true;
                             Desc="King of war gnomes. Rides a mechanical battle-elk. Boss of Castle 1.";
                             Special="Cannon Volley"; SpecialChance=30; SpecialDesc="Cannon volley from the battle-elk! Massive damage!" }
    # Floor 6 (Hunting Grounds)
    "jungle_raptor"    = @{ Name="Jungle Raptor";        MaxHP=45; Attack=13; Defense=3; Speed=7; XP=55; Gold=@(0,5);   Floor=6; Type="beast";
                             Desc="Fast, pack-hunting raptor. Evolved here specifically.";
                             Special="Pack Strike"; SpecialChance=35; SpecialDesc="The pack converges! Multi-target strike!" }
    "galactic_hunter"  = @{ Name="Galactic Hunter";      MaxHP=60; Attack=16; Defense=6; Speed=4; XP=100;Gold=@(30,60); Floor=6; Type="hunter";
                             Desc="Wealthy tourist who paid to hunt crawlers. Has better equipment than you.";
                             Special="Trophy Shot"; SpecialChance=25; SpecialDesc="Called shot! High-damage precision strike!" }
    "apex_predator"    = @{ Name="Apex Predator";        MaxHP=90; Attack=18; Defense=8; Speed=5; XP=130;Gold=@(20,40); Floor=6; Type="beast"; IsBoss=$true;
                             Desc="Dungeon-evolved megafauna. Crown predator of the Hunting Grounds." }
    "elite_hunter_vrah"= @{ Name="Elite Hunter Vrah";    MaxHP=250;Attack=24; Defense=12;Speed=6; XP=500;Gold=@(150,200);Floor=6;Type="hunter"; IsBoss=$true;
                             Desc="Vrah. Galaxy's most feared trophy hunter. She's here for you specifically.";
                             Special="Hunter's Mark"; SpecialChance=40; SpecialDesc="Hunter's Mark applied! You take 50% more damage this fight!" }
    # Floor 7 (Gladiator City)
    "arena_thug"       = @{ Name="Arena Thug";           MaxHP=55; Attack=14; Defense=5; Speed=3; XP=65; Gold=@(8,18);  Floor=7; Type="human";
                             Desc="Crawler who gave up escape and became a dungeon enforcer." }
    "frenzy_beast"     = @{ Name="Frenzied Beast";       MaxHP=70; Attack=18; Defense=4; Speed=6; XP=90; Gold=@(5,15);  Floor=7; Type="beast";
                             Desc="Buffed by the Frenzy mechanic. Attacks twice per round.";
                             Special="Double Strike"; SpecialChance=100; SpecialDesc="Frenzy! Attacks twice!" }
    "gladiator_boss"   = @{ Name="Champion Gladiator";   MaxHP=220;Attack=22; Defense=12;Speed=4; XP=400;Gold=@(80,120);Floor=7; Type="human"; IsBoss=$true;
                             Desc="Undefeated champion of Floor 7. Fights for the crowd.";
                             Special="Showstopper"; SpecialChance=35; SpecialDesc="Showstopper move! The crowd ROARS! Massive damage!" }
    # Floor 8 (Bedlam)
    "ghost_crawler"    = @{ Name="Ghost Crawler";        MaxHP=40; Attack=12; Defense=8; Speed=5; XP=70; Gold=@(5,15);  Floor=8; Type="undead";
                             Desc="Ghost of a crawler who didn't make it. Still fighting." }
    "folklore_horror"  = @{ Name="Folklore Horror";      MaxHP=65; Attack=16; Defense=5; Speed=4; XP=100;Gold=@(10,25); Floor=8; Type="legend";
                             Desc="Human myth given physical form by bedlam energy.";
                             Special="Madness Touch"; SpecialChance=30; SpecialDesc="Madness Touch! Drains MP and scrambles commands!" }
    "bedlam_bride"     = @{ Name="Shi Maria, Bedlam Bride";MaxHP=300;Attack=26;Defense=14;Speed=5;XP=600;Gold=@(100,150);Floor=8;Type="legend";IsBoss=$true;
                             Desc="Married a god. He's gone. She's here. Her aura drives people reckless.";
                             Special="Bedlam Aura"; SpecialChance=40; SpecialDesc="Bedlam Aura! You feel recklessly brave! ATK+8, DEF-6 this turn!" }
    # Floor 9 (Faction Wars)
    "faction_soldier"  = @{ Name="Faction Soldier";      MaxHP=65; Attack=16; Defense=7; Speed=3; XP=80; Gold=@(10,20); Floor=9; Type="faction";
                             Desc="Soldier from one of the nine galactic factions." }
    "faction_mage"     = @{ Name="Faction Battle Mage";  MaxHP=50; Attack=20; Defense=4; Speed=4; XP=100;Gold=@(15,30); Floor=9; Type="faction";
                             Desc="Magic-wielding faction combatant. Hits hard, fragile.";
                             Special="Arc Blast"; SpecialChance=35; SpecialDesc="Arc Blast! Lightning damage!" }
    "faction_general"  = @{ Name="Gen. Kralos";          MaxHP=280;Attack=26; Defense=14;Speed=3; XP=550;Gold=@(120,160);Floor=9;Type="faction";IsBoss=$true;
                             Desc="General of the most powerful faction. 200 years of war.";
                             Special="Command Strike"; SpecialChance=30; SpecialDesc="Command Strike! Calls reinforcements AND attacks!" }
    # Floor 10 (Final)
    "system_construct" = @{ Name="System Construct";     MaxHP=80; Attack=22; Defense=10;Speed=5; XP=120;Gold=@(20,40); Floor=10;Type="system";
                             Desc="AI-generated combat construct. Perfect form. Eerily silent." }
    "rogue_ai_shard"   = @{ Name="Rogue AI Shard";       MaxHP=60; Attack=18; Defense=12;Speed=6; XP=100;Gold=@(15,30); Floor=10;Type="system";
                             Desc="Fragment of the core AI given physical form.";
                             Special="Data Spike"; SpecialChance=35; SpecialDesc="Data Spike! Bypasses defense entirely!" }
    "dungeon_ai_core"  = @{ Name="The System - Core Instance";MaxHP=500;Attack=30;Defense=18;Speed=6;XP=1000;Gold=@(300,500);Floor=10;Type="system";IsBoss=$true;
                             Desc="The dungeon AI gone fully rogue. It has decided the most entertaining outcome is everyone's death.";
                             Special="System Override"; SpecialChance=40; SpecialDesc="System Override! Resets your buffs and heals the Core!"; HealSelf=20 }
}


# ROOM DATABASE - Floor 1
# ============================================================
$script:RoomDB = @{

    # === FLOOR 1: COLLAPSED SURFACE ===
    "f1_spawn" = @{
        Name="Spawn Point Alpha"; Floor=1; Visited=$false
        Desc="The world ended about three minutes ago. You're standing in what used to be a Seattle neighborhood. The buildings have all sunk into the ground, leaving a rubble-strewn dungeon floor stretching in every direction. Overhead, glowing text hangs in the air: WELCOME, CRAWLER. FIND THE STAIRCASE. A Tutorial Guild Hall is to the north. There's a vending machine to the east."
        Exits=@{north="f1_guild";east="f1_vending";south="f1_rubble_south";west="f1_alley"}
        Items=@("pipe_wrench","health_potion"); Enemies=@("cave_crawler")
        Ambient=@("The System's voice echoes: 'Your ratings are currently zero. How embarrassing.'","Somewhere in the rubble, another crawler is screaming. Then they stop.","A goblin peeks around a corner, sees you, and explodes pre-emptively.")
    }
    "f1_guild" = @{
        Name="Tutorial Guild Hall"; Floor=1; Visited=$false; IsSafeRoom=$true
        Desc="A stone building that manifested perfectly intact from the dungeon floor. Inside: warm light, a gruff-looking alien called a Kua-Tin sitting behind a desk, and blessed silence. This is a safe room. Nothing can hurt you here. A sign reads: NO KILLING. THIS MEANS YOU, GOBLIN. A terminal in the corner contains your character stats and skill tree."
        Exits=@{south="f1_spawn";east="f1_market"}
        Items=@("mordecai_scroll"); Enemies=@()
        Ambient=@("The guild master, Mordecai, nods at you. 'You're not dead yet. Points for that.'","Other crawlers mill around nervously. A few are crying.","The System broadcasts overhead: 'Ratings spike whenever a crawler cries. Keep it up.'")
    }
    "f1_market" = @{
        Name="Crawler Market"; Floor=1; Visited=$false; IsSafeRoom=$true
        Desc="A makeshift market that sprang up outside the Guild Hall in the first ten minutes of the dungeon. Crawlers trade gear, food, and information. A vending machine labelled BORANT CORP APPROVED GOODS hums against one wall. Prices are absurd. Someone is selling a bottled cockroach as a 'delicacy'."
        Exits=@{west="f1_guild";south="f1_vending";north="f1_church_ruins"}
        Items=@("energy_drink","duct_tape"); Enemies=@()
        Ambient=@("'I'll trade my wedding ring for a health potion,' someone says.","The vending machine cheerfully announces: 'RATINGS BOOST ITEMS ON SALE.'","A crawler is desperately trying to craft something out of a shoe.")
    }
    "f1_vending" = @{
        Name="Borant Vending Zone"; Floor=1; Visited=$false
        Desc="A row of sleek alien vending machines jammed into a collapsed storefront. They sell everything: weapons, potions, food, upgrades. Everything is priced in gold the dungeon generates from monster kills. A machine in the corner accepts subscriber donations -- the more entertaining you are to the galactic audience, the better the drops."
        Exits=@{north="f1_market";west="f1_spawn";south="f1_parking"}
        Items=@("health_potion","combat_knife"); Enemies=@("exploding_goblin")
        Chest=@{Locked=$false;Items=@("stim_pack","scrap_metal");Gold=18}
        Ambient=@("A vending machine plays an upbeat jingle. 'Thank you for crawling!'","An exploding goblin tried to rob the vending machine. The results are on the wall.","Your subscriber count ticks up by three. Baby steps.")
    }
    "f1_alley" = @{
        Name="Collapsed Alley"; Floor=1; Visited=$false
        Desc="A narrow gap between two slabs of collapsed concrete. Smells of gas leak and fear. Someone chalked survival tips on the walls: GOBLINS EXPLODE WHEN SCARED. DO NOT SCARE THEM NEAR YOU. GRUBS SPAWN FROM CORPSES. LEAVE NO BODIES. Below it, in different handwriting: TOO LATE."
        Exits=@{east="f1_spawn";north="f1_basement";south="f1_dead_end"}
        Items=@("lockpick","scrap_metal"); Enemies=@("cave_crawler","feral_dog")
        Ambient=@("Something drips from above.","The chalked advice has been aggressively underlined multiple times.","A dead crawler's starter kit lies unopened in the corner.")
    }
    "f1_dead_end" = @{
        Name="Rubble Dead End"; Floor=1; Visited=$false
        Desc="A collapsed section of street that goes nowhere. But someone was here before you -- there are drag marks, a blood smear, and a partially looted backpack jammed under a concrete slab."
        Exits=@{north="f1_alley"}
        Items=@("boxcutter","health_potion"); Enemies=@("exploding_goblin")
        Chest=@{Locked=$false;Items=@("leather_jacket");Gold=8}
        Ambient=@("The backpack still has half a granola bar in it.","Scratch marks on the wall: 'DAY 1. FLOOR 1. I WILL MAKE IT.'","Below: 'Day 2. I will not make it.'")
    }
    "f1_rubble_south" = @{
        Name="Southern Rubble Field"; Floor=1; Visited=$false
        Desc="A vast open section of floor 1 -- or what would be a neighborhood of collapsed apartment buildings. Rubble stretches for what would be blocks. Mobs spawn here constantly. It's dangerous, but the monster density means good XP and decent drops."
        Exits=@{north="f1_spawn";east="f1_parking";west="f1_dead_end";south="f1_stairwell_antechamber"}
        Items=@("scrap_metal","chemical_jug"); Enemies=@("exploding_goblin","cave_crawler","feral_dog")
        Ambient=@("Multiple explosions in the distance. More than one goblin.","A notification: 'Your kill style has been rated ADEQUATE by viewers.'","The dungeon hums underfoot. Something large is moving below.")
    }
    "f1_parking" = @{
        Name="Collapsed Parking Garage"; Floor=1; Visited=$false
        Desc="Three floors of parking garage all collapsed into one. Cars are stacked at odd angles, providing cover and hiding spots. Also hiding spots for things that want to eat you. A crawler with a broken arm is sheltering behind a crushed pickup truck. She looks at you like a lifeline."
        Exits=@{north="f1_vending";west="f1_rubble_south";east="f1_church_ruins"}
        Items=@("duct_tape","scrap_metal"); Enemies=@("feral_dog","exploding_goblin")
        Chest=@{Locked=$true;Items=@("combat_knife","riot_gear");Gold=35;KeyRequired="lockpick"}
        Ambient=@("The injured crawler: 'My name is Britta. If I give you my stuff will you help me?'","A car alarm still bleating somewhere in the wreckage.","Feral dogs circle in the upper level, watching.")
    }
    "f1_church_ruins" = @{
        Name="Church Ruins"; Floor=1; Visited=$false
        Desc="A collapsed church where the altar survived intact. Dozens of crawlers sought shelter here in the first minutes and a small camp has formed. There's a rough kind of order: a big guy named Brandon coordinates, a teenager named Yuki maps exits on cardboard, and an old woman named Miriam is calm in a way that doesn't quite make sense."
        Exits=@{west="f1_parking";south="f1_market";east="f1_basement";north="f1_neighborhood_boss"}
        Items=@("health_potion","energy_drink"); Enemies=@()
        Ambient=@("Brandon: 'We need more supplies before the floor timer runs out.'","Yuki holds up her map: 'I found where the stairwell is. We need to get through THAT.'","Miriam smiles: 'I've played a lot of video games, dear. We'll be fine.'")
    }
    "f1_basement" = @{
        Name="Sub-Basement Access"; Floor=1; Visited=$false
        Desc="A concrete staircase leading down into a sub-basement that connects to the early sections of Floor 2's sewers. Damp air rises from below. Something down there splashes occasionally. The dungeon system has marked it: ACCESS TO FLOOR 2 ANTECHAMBER. DANGER RATING: MODERATE."
        Exits=@{west="f1_church_ruins";south="f1_alley";down="f2_sewer_antechamber"}
        Items=@("health_potion"); Enemies=@("cave_crawler","brindle_grub")
        Ambient=@("Wet sounds from below.","The System: 'Brindle Grubs spawn from corpses on Floor 2. Don't leave bodies.'","A previous crawler carved: 'THE GRUBS GOT TOMMY' into the concrete.")
    }
    "f1_neighborhood_boss" = @{
        Name="Old Neighborhood - Hoarder's Lair"; Floor=1; Visited=$false
        Desc="A former residential block where the neighborhood boss has taken up residence. The boss is a middle-aged woman named Patricia who was a hoarder in real life and has been transformed into a 15-foot creature made of the junk she accumulated. She's surprisingly agile and definitely does not want to let go of any of it."
        Exits=@{south="f1_church_ruins";north="f1_stairwell_antechamber"}
        Items=@("scrap_metal"); Enemies=@("feral_dog")
        BossRoom=$true; BossEnemy="circus_bear"; BossDefeated=$false
        Ambient=@("Patricia's voice, echoing unnaturally: 'I COLLECTED YOU NOW.'","The junk-creature gleams with stolen treasure.","The System: 'Patricia has 2.3 million viewers right now. Good luck.'")
    }
    "f1_stairwell_antechamber" = @{
        Name="Floor 1 Stairwell Antechamber"; Floor=1; Visited=$false
        Desc="A large chamber cleared of rubble, with a glowing blue staircase descending into the floor. This is the exit. Crawlers are clustered around it. Some look triumphant. Most look terrified. A timer on the wall shows how long until the floor collapses and everyone still here dies. The System has placed a vending machine right next to the stairs."
        Exits=@{south="f1_neighborhood_boss";down="f2_sewer_antechamber"}
        Items=@("mega_health"); Enemies=@()
        IsStairwell=$true; StairTarget="f2_sewer_antechamber"
        Ambient=@("The System: 'FLOOR 1 CONCLUDES IN 2 HOURS. CRAWLERS STILL PRESENT: 847.'","A crawler hugs a stranger before descending.","The vending machine dispenses celebratory confetti with each purchase. Grim.")
    }

    # === FLOOR 2: UNDERCITY SEWERS ===
    "f2_sewer_antechamber" = @{
        Name="Sewer Antechamber"; Floor=2; Visited=$false
        Desc="The bottom of the staircase opens into a vaulted stone chamber smelling powerfully of things you'd rather not name. Welcome to Floor 2. The walls are slick with condensation and older things. Green bio-luminescent fungi provide dim light. Tunnels branch in all directions. A sign reads: TUTORIAL ENDS HERE. YOU ARE NOW ON YOUR OWN. GOOD LUCK. (Note: Grub spawning is active. Do NOT leave corpses.)"
        Exits=@{up="f1_stairwell_antechamber";north="f2_guild";east="f2_main_tunnel";south="f2_cistern"}
        Items=@("antiparasitic","health_potion"); Enemies=@("mutant_rat")
        IsSafeRoom=$true
        Ambient=@("The System: 'Welcome to Floor 2. Tutorial complete. You're on your own.'","The fungi glow in shifting colors. Somehow that makes it worse.","A Brindle Grub slides past your feet, heading for a dead rat. You watch in horror.")
    }
    "f2_guild" = @{
        Name="Floor 2 Guild Outpost"; Floor=2; Visited=$false; IsSafeRoom=$true
        Desc="A smaller, damp version of the floor 1 guild hall. Mordecai, your guide, appears as a holographic projection from a plinth. He looks exactly like a Kua-Tin should look -- vaguely like someone crossed a velociraptor with a very disappointed accountant. 'You made it,' he says flatly. 'Adequate.' The class selection terminal is here. You can finally choose your class."
        Exits=@{south="f2_sewer_antechamber";east="f2_pump_station"}
        Items=@("mordecai_scroll"); Enemies=@()
        ClassSelection=$true
        Ambient=@("Mordecai: 'Choose your class wisely. Some of them are terrible. I'm legally prohibited from saying which.'","Other crawlers crowd around the class terminal, arguing.","The dungeon system plays hold music while you decide. It's surprisingly catchy.")
    }
    "f2_main_tunnel" = @{
        Name="Main Sewer Tunnel"; Floor=2; Visited=$false
        Desc="The primary east-west sewer conduit. Wide enough for ten people abreast, which means it's wide enough for a sewer golem. The bio-luminescent fungi here are thicker, and you can see small clusters of Brindle Grubs feeding on a dead crawler in the distance. The system reminds you: don't add to the corpse count."
        Exits=@{west="f2_sewer_antechamber";east="f2_goblin_den";north="f2_pump_station";south="f2_deep_cistern"}
        Items=@("scrap_metal","duct_tape"); Enemies=@("mutant_rat","brindle_grub")
        Ambient=@("The grubs feeding in the distance suddenly look up at you simultaneously.","Something very large moves in the water below the grate.","A notification: 'Brindle Grub population: 847. Current corpse count: 12. Math is bad.'")
    }
    "f2_pump_station" = @{
        Name="Old Pump Station"; Floor=2; Visited=$false
        Desc="A massive industrial pump station now incorporated into the dungeon. Giant corroded pipes cross in every direction. Control consoles covered in alien text glow uselessly. The pumps are offline but they provide excellent cover. Someone has set up a small camp here with makeshift barricades."
        Exits=@{south="f2_main_tunnel";west="f2_guild";east="f2_overflow_chamber"}
        Items=@("chemical_jug","scrap_metal","lockpick"); Enemies=@("sewer_golem","mutant_rat")
        Chest=@{Locked=$true;Items=@("stim_pack","dungeon_plate");Gold=40;KeyRequired="lockpick"}
        Ambient=@("The pumps groan as if trying to restart.","Someone wrote system repair notes that become increasingly panicked.","A golem sits dormant near the main pipe. Key word: dormant.")
    }
    "f2_cistern" = @{
        Name="The Great Cistern"; Floor=2; Visited=$false
        Desc="An enormous underground cistern -- the size of a football stadium -- carved from ancient stone. The water level is low but the acoustics are terrifying. Every sound echoes here. Multiple grub colonies have set up in the dry sections. A sunken area holds the ruins of a pre-dungeon underground market."
        Exits=@{north="f2_sewer_antechamber";east="f2_deep_cistern";south="f2_stairwell_chamber"}
        Items=@("health_potion","antiparasitic"); Enemies=@("brindle_grub","mutant_rat","sewer_golem")
        Ambient=@("Your footsteps echo back to you slightly wrong.","A grub colony ripples like a living carpet in the corner.","The dungeon system: 'The Cistern has historically high mortality rates. Enjoy!'")
    }
    "f2_deep_cistern" = @{
        Name="Deep Cistern"; Floor=2; Visited=$false
        Desc="The lowest accessible section of Floor 2. Water reaches ankle depth here. Bio-luminescent panels flicker in the ceiling. The Sewer Golem boss is down here somewhere -- you can tell because everything else has cleared out. Whatever cleared them out is what you're looking for. A massive iron door at the far end bears the symbol for Floor 3."
        Exits=@{west="f2_cistern";north="f2_main_tunnel";south="f2_boss_chamber"}
        Items=@("mega_health","dungeon_crystal"); Enemies=@("sewer_golem","brindle_grub")
        Ambient=@("The water surface ripples from something below.","Grub population alert: critical. Stop killing things.","The iron door pulses with dungeon energy.")
    }
    "f2_boss_chamber" = @{
        Name="The Golem's Chamber"; Floor=2; Visited=$false
        Desc="A circular chamber where the Sewer Golem Prime has taken up residence. The creature is enormous -- twenty feet of compressed sewage, bone, and dungeon energy -- and currently rearranging the floor decorations to suit itself. It turns to look at you. It doesn't have eyes. Somehow it still looks at you."
        Exits=@{north="f2_deep_cistern";south="f2_stairwell_chamber"}
        Items=@(); Enemies=@()
        BossRoom=$true; BossEnemy="sewer_golem"; BossDefeated=$false
        Ambient=@("The Golem Prime is watching you.","The System: 'Boss room! 4.7 million viewers!'","Something cracks in the walls as it shifts its weight.")
    }
    "f2_stairwell_chamber" = @{
        Name="Floor 2 Stairwell"; Floor=2; Visited=$false
        Desc="The stairwell to Floor 3. It glows with an eerie amber light unlike the blue of Floor 1. Carved above it: TRAINING COMPLETE. THE GAMES BEGIN NOW. The System has provided a final class selection terminal here for any crawlers who missed the guild. Below, you can hear the sounds of a city -- but wrong. Broken. Something is performing down there."
        Exits=@{north="f2_boss_chamber";down="f3_over_city_entry"}
        Items=@("mega_health","sponsors_box"); Enemies=@()
        IsStairwell=$true; StairTarget="f3_over_city_entry"
        Ambient=@("Carnival music drifts up from below. Slightly off-key.","The System: 'Floor 3 awaits. The Over City. Population: mostly dead.'","A crawler next to you whispers: 'I can hear a bear. An undead bear. Why is there an undead bear?'")
    }

    # === FLOOR 3: THE OVER CITY ===
    "f3_over_city_entry" = @{
        Name="Over City Entry - Times Square Ruins"; Floor=3; Visited=$false
        Desc="Floor 3 is a ruined city -- built from every major urban center that was absorbed into the dungeon. The entry point looks like a nightmarish Times Square: massive screens still flicker with alien advertisements, skyscrapers have been cut off at the 10th floor, and streets stretch in every direction. It smells of ozone and decay. Somewhere in the distance, circus music plays."
        Exits=@{north="f3_city_guild";east="f3_main_street";south="f3_subway_entrance";west="f3_side_alley"}
        Items=@("health_potion","scrap_metal"); Enemies=@("corrupted_cop","undead_clown")
        Ambient=@("The screens flicker: 'WELCOME TO OVER CITY. POPULATION 0. VIEWERS: 12 MILLION.'","Circus music is definitely getting closer.","A corrupted cop car rolls past on its own. The radio plays static.")
    }
    "f3_city_guild" = @{
        Name="City Guild Hall"; Floor=3; Visited=$false; IsSafeRoom=$true
        Desc="A guild hall set up in a former hotel lobby. Mordecai is here, looking frazzled. 'The Over City is complicated,' he says. 'There are quests here. Real ones. Completing them matters. Also, the undead circus patrols a circuit -- don't be in its path.' He hands you a map with three quest markers on it."
        Exits=@{south="f3_over_city_entry";east="f3_park_ruins";north="f3_upper_city"}
        Items=@("mordecai_scroll","health_potion"); Enemies=@()
        Ambient=@("Mordecai: 'The thing in the park is called the Ancient Spell. Don't touch it. Yet.'","Other crawlers compare quest notes frantically.","The hotel concierge -- now a skeleton in uniform -- still tries to check you in.")
    }
    "f3_main_street" = @{
        Name="Over City Main Street"; Floor=3; Visited=$false
        Desc="A wide boulevard running through the center of the Over City. This is the circus circuit -- the undead circus patrols here on a set schedule. Ancient streetlights flicker. Shop windows display goods that aren't for sale anymore and never were. A crashed alien vehicle smolders at the intersection."
        Exits=@{west="f3_over_city_entry";north="f3_park_ruins";east="f3_warehouse";south="f3_station_ruins"}
        Items=@("combat_knife","energy_drink"); Enemies=@("undead_clown","corrupted_cop","city_wraith")
        Ambient=@("Circus music swells suddenly. It's coming from the north.","A wraith passes through a wall. It stops and looks at you.","The schedule on the wall: CIRCUS ARRIVES: 2 HOURS.")
    }
    "f3_park_ruins" = @{
        Name="The Ruined Park"; Floor=3; Visited=$false
        Desc="A city park where something ancient has taken root. The trees are dead but their roots glow with purple light that pulses rhythmically. At the center, a stone structure covered in symbols hums loudly. Mordecai's voice crackles over comms: 'That's the Ancient Spell. Someone cast it centuries ago. It's been building power ever since. Your quest is to figure out what it does before it triggers.'"
        Exits=@{south="f3_main_street";west="f3_city_guild";east="f3_university"}
        Items=@("dungeon_crystal","mordecai_scroll"); Enemies=@("city_wraith","corrupted_cop")
        QuestRoom="ancient_spell"
        Ambient=@("The symbol-covered stone pulses faster as you approach.","The System: 'QUEST: The Ancient Spell. Time remaining: unknown. Probably bad.'","A ghost of a former park visitor sits on a bench and doesn't acknowledge you.")
    }
    "f3_warehouse" = @{
        Name="Abandoned Warehouse"; Floor=3; Visited=$false
        Desc="A massive warehouse now converted into a dungeon armory by some previous crawlers who didn't make it out. Crates of supplies. A half-built barricade. Evidence of a last stand: shell casings, broken weapons, blood. Whatever took them left nothing behind. A functioning crafting bench is bolted to the wall."
        Exits=@{west="f3_main_street";north="f3_university";south="f3_station_ruins"}
        Items=@("scrap_metal","chemical_jug","explosive_gel","duct_tape"); Enemies=@("undead_clown","city_wraith")
        HasCraftingBench=$true
        Chest=@{Locked=$true;Items=@("goblin_cleaver","stim_pack");Gold=55;KeyRequired="lockpick"}
        Ambient=@("The last stand barricade didn't hold.","Crafting notes on the bench wall: 'JUNK + CHEMICAL + EXPLOSIVE GEL = BOOM POTION. TESTED: YES.'","Something watches from the rafters.")
    }
    "f3_university" = @{
        Name="Ruined University"; Floor=3; Visited=$false
        Desc="A once-proud university reduced to exposed lecture halls and collapsed dorms. The library survived almost intact -- alien texts mixed with human ones in bizarre combinations. A researcher-type crawler has set up here: a former chemistry professor named Dr. Lim who's been using the dungeon's chemical components to craft things. She's very excited about the explosive gel."
        Exits=@{south="f3_warehouse";west="f3_park_ruins";east="f3_circus_staging";north="f3_upper_city"}
        Items=@("explosive_gel","dungeon_crystal"); Enemies=@("city_wraith")
        HasCraftingBench=$true
        Ambient=@("Dr. Lim: 'I have made seventeen different explosive compounds. I am THRIVING.'","The library contains books on dungeon theory. Some of it contradicts the System's official story.","A ghost professor still holds class. Three ghost students take notes.")
    }
    "f3_circus_staging" = @{
        Name="Circus Staging Ground"; Floor=3; Visited=$false
        Desc="The base of operations for the undead circus. Rotting tents, broken calliope, prop wagons leaking ectoplasm. This is where the circus gathers between circuits. The Undead Circus Bear boss is here -- enormous, rancid, wearing a tiny fez and an expression of existential suffering. It growls when it sees you."
        Exits=@{west="f3_university";south="f3_station_ruins"}
        Items=@("mega_health","stim_pack"); Enemies=@("undead_clown")
        BossRoom=$true; BossEnemy="circus_bear"; BossDefeated=$false
        Ambient=@("The bear's fez is unsettlingly tiny for its head.","Zombie clowns scatter as the bear notices you.","The System: '8 MILLION VIEWERS. BEAR VS. CRAWLER. RATINGS GOLD.'")
    }
    "f3_station_ruins" = @{
        Name="Transit Station Ruins"; Floor=3; Visited=$false
        Desc="A former transit hub half-collapsed into the dungeon substrate. The trains don't run here -- that's Floor 4. But this is where Floor 4 begins to bleed through: you can feel the vibration of the Iron Tangle below, and the walls occasionally flash with electrical discharge. The transit cards for Floor 4 are sold here."
        Exits=@{north="f3_main_street";east="f3_circus_staging";west="f3_warehouse";south="f3_stairwell_block";up="f3_upper_city"}
        Items=@("transit_card","health_potion"); Enemies=@("corrupted_cop","undead_clown")
        Ambient=@("The walls vibrate with distant train movement.","Electrical sparks arc from exposed wiring.","A sign: FLOOR 4 ACCESS REQUIRES TRANSIT CARD. OBTAIN FROM GUILD.")
    }
    "f3_upper_city" = @{
        Name="Upper City Overlook"; Floor=3; Visited=$false
        Desc="A section of floor 3 built on the ruins of upper-floor city buildings. You're looking out over the Over City from above, which is the first time you've been able to see the full scope. It's enormous. Broken. Beautiful in a terrible way. From up here you can see the circus circuit, the glowing park, and the stairwell district to the south."
        Exits=@{south="f3_city_guild";east="f3_university";west="f3_side_alley";down="f3_station_ruins"}
        Items=@("sponsors_box"); Enemies=@("city_wraith","undead_clown")
        Ambient=@("The full Over City spreads below you. It's bigger than any city that existed.","A notification: 'VIEWER MILESTONE! 10 MILLION SUBSCRIBERS. LOOT BOX INBOUND.'","From here you can see the stairwell glowing far to the south.")
    }
    "f3_side_alley" = @{
        Name="Side Alley Network"; Floor=3; Visited=$false
        Desc="A maze of back alleys that cuts through the Over City off the main circuit. Safer from the circus but full of wraiths. Graffiti from previous crawlers covers the walls: ratings advice, enemy weaknesses, and one very long, very detailed poem about missing home."
        Exits=@{east="f3_over_city_entry";north="f3_upper_city";south="f3_stairwell_block"}
        Items=@("health_potion","duct_tape"); Enemies=@("city_wraith")
        Ambient=@("The poem on the wall is actually quite good.","A wraith reads the poem over your shoulder.","Previous crawler: 'WRAITHS CAN'T ENTER BUILDINGS. USE THIS.'")
    }
    "f3_subway_entrance" = @{
        Name="Subway Entrance - Gate 7"; Floor=3; Visited=$false
        Desc="A subway entrance descends into the floor. This isn't Floor 4 yet -- it's an antechamber. But you can hear the Iron Tangle from here: the shriek of metal on metal, a garbled PA announcement in seventeen languages, and the distant crash of something very large derailing."
        Exits=@{north="f3_over_city_entry";south="f3_stairwell_block";down="f3_station_ruins"}
        Items=@("transit_card","health_potion"); Enemies=@("corrupted_cop")
        Ambient=@("A PA announcement: 'THE 4 TRAIN IS RUNNING WITH DELAYS. REASON: MONSTERS. EXPECTED RESOLUTION: NEVER.'","The wind from below smells of electricity and burning metal.","Something huge just derailed. The floor shakes.")
    }
    "f3_stairwell_block" = @{
        Name="Stairwell District"; Floor=3; Visited=$false
        Desc="The district at the south end of the Over City where the Floor 3 stairwell is located. Heavy mob concentration -- the dungeon always defends the stairs. An enormous glowing staircase descends through the floor, surrounded by a ring of scorched concrete where previous battles took place. The System: 'FLOOR 4: THE IRON TANGLE AWAITS.'"
        Exits=@{north="f3_station_ruins";east="f3_circus_staging";west="f3_side_alley";down="f4_iron_tangle_entry"}
        Items=@("mega_health","sponsors_box"); Enemies=@("undead_clown","corrupted_cop","city_wraith")
        IsStairwell=$true; StairTarget="f4_iron_tangle_entry"
        Ambient=@("The System: 'Floor 3 concludes in 6 hours. Crawlers remaining: 312.'","The staircase is guarded by three corrupted cops and a wraith. They look confident.","Below: the unmistakable sound of a hundred trains running on impossible tracks.")
    }

    # === FLOOR 4: THE IRON TANGLE ===
    "f4_iron_tangle_entry" = @{
        Name="Iron Tangle - Central Hub Station"; Floor=4; Visited=$false
        Desc="You step off the stairs and onto a platform in the most insane transit system ever assembled. Trains from every era of human history -- horse-drawn, steam, electric, magnetic levitation -- run on tracks that crisscross in three dimensions. The station map makes no spatial sense. A helpful sign reads: YOU ARE HERE. Another sign underneath reads: ACTUALLY YOU MIGHT NOT BE."
        Exits=@{up="f3_stairwell_block";north="f4_platform_north";east="f4_eastbound";south="f4_guild_car";west="f4_westbound"}
        Items=@("health_potion","transit_card"); Enemies=@("train_goblin")
        IsSafeRoom=$true
        Ambient=@("Seven trains pass through simultaneously without hitting each other. Somehow.","The PA: 'NEXT TRAIN TO STAIRWELL PLATFORM: DELAYED. INDEFINITELY.'","Mordecai: 'The Iron Tangle is sentient. It doesn't like you. Don't be likable.'")
    }
    "f4_guild_car" = @{
        Name="Guild Car - Rolling Safe Room"; Floor=4; Visited=$false; IsSafeRoom=$true
        Desc="A special train car that serves as the guild hall for Floor 4. It moves on its own schedule but always stops at major stations. Mordecai runs it. There's a crafting bench bolted to one wall, a vending machine to the other, and windows that show an impossible variety of tunnels flowing past. 'The Tangle is rearranging itself,' Mordecai says. 'Every hour. Don't get comfortable.'"
        Exits=@{north="f4_iron_tangle_entry";east="f4_steam_section";south="f4_eastbound"}
        Items=@("mordecai_scroll","stim_pack"); Enemies=@()
        HasCraftingBench=$true
        Ambient=@("The car rocks as the tracks rearrange below it.","Mordecai: 'Four exits from this floor. The Tangle is hiding three of them.'","A poster: 'DUNGEON CRAWLER WORLD - YOUR SUFFERING IS OUR ENTERTAINMENT.'")
    }
    "f4_platform_north" = @{
        Name="Northern Platform - Terminus"; Floor=4; Visited=$false
        Desc="A massive platform serving as a terminus for the north section of the Tangle. Trains arrive and leave on impossible schedules. The platform itself seems to be moving slowly. Train goblins have set up a toll booth -- they demand gold or combat. The conductor lich patrols this section with an air of offended professionalism."
        Exits=@{south="f4_iron_tangle_entry";east="f4_maze_junction";north="f4_elevated_track";west="f4_steam_section"}
        Items=@("combat_knife","energy_drink"); Enemies=@("train_goblin","conductor_lich")
        Ambient=@("The toll booth sign: '5 GOLD OR VIOLENCE. VIOLENCE ALSO ACCEPTED.'","The conductor lich punches your (nonexistent) ticket anyway.","A train arrives running backwards. The goblins inside seem to consider this normal.")
    }
    "f4_steam_section" = @{
        Name="Steam Engine District"; Floor=4; Visited=$false
        Desc="This section of the Tangle is populated entirely by Victorian-era steam locomotives. Everything is brass and coal-black. Steam fills the air to near-zero visibility. The iron rail golems spawned here are made of Victorian-era track fittings and move with mechanical inevitability."
        Exits=@{east="f4_platform_north";south="f4_guild_car";west="f4_coal_tunnels"}
        Items=@("scrap_metal","chemical_jug"); Enemies=@("iron_golem","conductor_lich")
        Ambient=@("Visibility: 10 feet. Everything else: just sound.","A steam engine rolls by playing a pipe organ. This feels intentional.","An iron golem emerges from the steam four feet in front of you.")
    }
    "f4_eastbound" = @{
        Name="Eastbound Express Line"; Floor=4; Visited=$false
        Desc="The express line -- a series of high-speed modern trains that run so fast the wind nearly knocks you down. Fighting here is intensely difficult. The goblins have adapted by strapping themselves to the outside of the cars. The stairwell to Floor 5 is somewhere on this line. Probably."
        Exits=@{north="f4_iron_tangle_entry";south="f4_guild_car";east="f4_maze_junction";west="f4_coal_tunnels"}
        Items=@("health_potion","goblin_cleaver"); Enemies=@("train_goblin","iron_golem")
        Ambient=@("A train passes at 200mph. Your hat flies off.","A goblin strapped to a train gives you a thumbs up. Then explodes.","The Tangle PA: 'MIND THE CLOSING DOORS. DOORS ARE CLOSING. DOORS. PLEASE.'")
    }
    "f4_westbound" = @{
        Name="Westbound Local"; Floor=4; Visited=$false
        Desc="The local line -- slow, creaking, and packed with dungeon mobs that treat the train cars as their personal territory. You have to navigate through car after car to reach the far station. The conductor lich is on this route. Every time you defeat it, another manifests at the front of the train."
        Exits=@{east="f4_iron_tangle_entry";north="f4_steam_section";south="f4_coal_tunnels";west="f4_elevated_track"}
        Items=@("duct_tape","scrap_metal"); Enemies=@("conductor_lich","train_goblin")
        Ambient=@("Between cars, the tracks are visible stretching in impossible directions.","The lich punches tickets and announces stops in seven languages.","A crawler is napping in the priority seating. They wave you past.")
    }
    "f4_maze_junction" = @{
        Name="The Maze Junction"; Floor=4; Visited=$false
        Desc="The Tangle's most confusing intersection. Tracks from all eras cross and recross in a three-dimensional knot. The 'up' direction is arbitrary. A junction booth staffed by a skeletal traffic controller manages the flow of impossible trains. There is a note here from previous crawlers: 'THE EXIT IS ON THE MAGNETIC LEV LINE. EASTBOUND FROM JUNCTION. GOOD LUCK.'"
        Exits=@{west="f4_platform_north";north="f4_elevated_track";south="f4_eastbound";east="f4_tangle_boss_chamber"}
        Items=@("dungeon_crystal","mega_health"); Enemies=@("conductor_lich","iron_golem")
        Ambient=@("A train passes through going diagonally. Physics has given up.","The skeletal controller: 'All lines are running normally.' They are not.","You can see five floors of tracks above you and feel three below.")
    }
    "f4_elevated_track" = @{
        Name="Elevated Track Section"; Floor=4; Visited=$false
        Desc="An outdoor elevated section -- except 'outdoor' here means you can see the dungeon ceiling far above and the impossible depth of the Iron Tangle far below. The tracks are old iron, groaning under the weight of antique trains. The wind here is artificial and smells of lightning."
        Exits=@{south="f4_platform_north";east="f4_maze_junction";west="f4_westbound";north="f4_tangle_boss_chamber"}
        Items=@("stim_pack","explosive_gel"); Enemies=@("train_goblin","conductor_lich")
        Ambient=@("The drop to the next level of tracks: 40 feet. Minimum.","A steam engine passes below you heading the wrong direction.","A notification: 'ELEVATED COMBAT CLIP HAS 3M VIEWS. YOUR AUDIENCE IS INVESTED.'")
    }
    "f4_coal_tunnels" = @{
        Name="Coal Mine Tunnels"; Floor=4; Visited=$false
        Desc="The Tangle incorporates ancient coal mine railways in this section. Narrow, low-roofed, and absolutely full of iron golems who were apparently coal miners in a previous life. The air is thick with coal dust. The tracks here are tiny. The trains are tiny. Everything is tiny except the golems."
        Exits=@{north="f4_steam_section";east="f4_eastbound";south="f4_westbound";west="f4_tangle_boss_chamber"}
        Items=@("scrap_metal","dungeon_crystal"); Enemies=@("iron_golem")
        Chest=@{Locked=$true;Items=@("enchanted_bat","dungeon_plate");Gold=70;KeyRequired="lockpick"}
        Ambient=@("You have to crouch. The golems do not have to crouch.","A coal cart rolls past on its own, squeaking urgently.","The tunnel walls vibrate as something massive passes on the track above.")
    }
    "f4_tangle_boss_chamber" = @{
        Name="The Central Switch - Boss Chamber"; Floor=4; Visited=$false
        Desc="The heart of the Iron Tangle: the Central Switch, a room-sized mechanical apparatus that controls every track in the entire system. And standing at its controls is The Iron Conductor -- a massive construct built from rail ties, locomotive parts, and dungeon energy -- who is sentient, offended by your presence, and has been running this transit system perfectly for centuries. It turns to face you with the air of a transit manager who has had enough."
        Exits=@{north="f4_elevated_track";east="f4_maze_junction";south="f4_stairwell_platform";west="f4_coal_tunnels"}
        Items=@(); Enemies=@()
        BossRoom=$true; BossEnemy="tangle_boss"; BossDefeated=$false
        Ambient=@("The Conductor: 'You have been riding without a valid fare. This is unacceptable.'","The System: '18 MILLION VIEWERS. THIS IS THE HIGHEST RATED FLOOR 4 IN HISTORY.'","The tracks rearrange around you as the Conductor moves.")
    }
    "f4_stairwell_platform" = @{
        Name="Final Platform - Floor 4 Stairwell"; Floor=4; Visited=$false
        Desc="A special platform that only appears after the Iron Conductor is defeated. The trains here run perfectly, in order, and on time. It's deeply uncanny. The Floor 5 stairwell is a massive golden door set into the platform wall, glowing with bubble energy. The System: 'FLOOR 5: THE BUBBLE AWAITS. FOUR CASTLES. 15 DAYS. GOOD LUCK.'"
        Exits=@{north="f4_tangle_boss_chamber";down="f5_bubble_entry"}
        Items=@("mega_health","sponsors_box","stim_pack"); Enemies=@()
        IsStairwell=$true; StairTarget="f5_bubble_entry"
        Ambient=@("The trains run on time. You find it unsettling.","A last message from Mordecai: 'Floor 5 has four objectives. Don't dawdle.'","The golden door hums with what sounds like a very large number of gnomes.")
    }

    # === FLOOR 5: THE BUBBLE CASTLES ===
    "f5_bubble_entry" = @{
        Name="The Bubble - Open Plains"; Floor=5; Visited=$false
        Desc="You step out of the stairwell into an enormous bubble -- a spherical enclosed environment the size of a small continent. The sky is artificial, the ground is rolling plains, and on the horizon you can see four distinct structures: a floating gnome fortress to the north, a gleaming sand castle to the east, a dark crypt to the west, and a rusted submarine hull jutting from the ground to the south. A System notification: CAPTURE ALL FOUR CASTLES TO UNLOCK THE STAIRWELL. 15 DAYS."
        Exits=@{up="f4_stairwell_platform";north="f5_gnome_approach";east="f5_sand_approach";south="f5_sub_approach";west="f5_crypt_approach"}
        Items=@("health_potion","mordecai_scroll"); Enemies=@("war_gnome","sand_elemental")
        IsSafeRoom=$true
        Ambient=@("The System: 'FOUR CASTLES. 15 DAYS. THERE ARE ALSO DINOSAURS. WE FORGOT TO MENTION THE DINOSAURS.'","The gnome fortress fires a warning cannon shot that lands 20 feet away.","Mordecai: 'You'll need other crawlers. This is too much for one person. I know you think you can do it alone. You can't.'")
    }
    "f5_gnome_approach" = @{
        Name="Gnome Fortress Approach"; Floor=5; Visited=$false
        Desc="The path to the Gnome Fortress floats in mid-air on a chain of rock platforms connected by bridges. The gnomes have fortified every bridge with cannon emplacements and crossbow towers. They are three feet tall and absolutely furious. The fortress itself is impressive -- proper walls, towers, murder holes. These gnomes know what they're doing."
        Exits=@{south="f5_bubble_entry";north="f5_gnome_fortress"}
        Items=@("stim_pack","explosive_gel"); Enemies=@("war_gnome")
        Ambient=@("A gnome shouts battle cries in a language that shouldn't be intimidating but somehow is.","The cannon fire is surprisingly accurate.","A gnome drops a boulder on you from a drawbridge. It's the size of a microwave. Still hurts.")
    }
    "f5_gnome_fortress" = @{
        Name="Gnome Fortress - Throne Room"; Floor=5; Visited=$false
        Desc="The inner sanctum of the gnome fortress. Gnome King Gorbrock sits on a throne the size of a large dog, wearing a crown that covers his entire face, and riding a mechanical battle-elk the size of a horse. The elk snorts steam. Gorbrock shouts something in Gnomish. His translator: 'The King says your boots are ugly and your fighting stance is amateur and he will prove it.'"
        Exits=@{south="f5_gnome_approach"}
        Items=@("castle_banner_1","mega_health"); Enemies=@("war_gnome")
        BossRoom=$true; BossEnemy="gnome_king"; BossDefeated=$false
        Ambient=@("The mechanical elk powers up with a sound like a jet turbine.","Gorbrock: [GNOMISH BATTLE CRY].","The System: 'GNOME KING VS. CRAWLER. THE AUDIENCE HAS BEEN WAITING FOR THIS ALL SEASON.'")
    }
    "f5_sand_approach" = @{
        Name="Sand Castle Approach"; Floor=5; Visited=$false
        Desc="The sand castle looms ahead -- and it is legitimately a castle made of sand, about three stories tall, impossibly structurally sound. Sand elementals patrol the perimeter. A closer look: the sand is alive. Not metaphorically. The grains have individual intelligence. The castle rearranges itself as you approach."
        Exits=@{west="f5_bubble_entry";east="f5_sand_castle"}
        Items=@("health_potion","dungeon_crystal"); Enemies=@("sand_elemental")
        Ambient=@("The castle is actively building new towers.","A sandstorm with intent advances on you.","The System: 'The sand castle was rated the most visually interesting objective of Floor 5 for 3 consecutive seasons.'")
    }
    "f5_sand_castle" = @{
        Name="Sand Castle - Crystal Core"; Floor=5; Visited=$false
        Desc="The inner chamber of the sand castle -- a dome of compressed, crystallized sand that refracts light into impossible colors. The guardian here isn't a boss but a challenge: you must defeat wave after wave of sand elementals while the castle attempts to bury you. The banner is at the center. The sand is everywhere."
        Exits=@{west="f5_sand_approach"}
        Items=@("castle_banner_2","stim_pack","dungeon_crystal"); Enemies=@("sand_elemental")
        WaveRoom=$true; WaveCount=3
        Ambient=@("Sand in your boots. Sand in your teeth. Sand in places you don't want to think about.","The crystal core pulses with each wave of elementals.","A notification: 'SAND COMBAT IS AUDIENCE GOLD. YOU HAVE GAINED 500K SUBSCRIBERS.'")
    }
    "f5_crypt_approach" = @{
        Name="Haunted Crypt Approach"; Floor=5; Visited=$false
        Desc="The haunted crypt squats on a hill surrounded by graves that predate the dungeon. The traps here are legendary -- Mordecai warned you specifically about this one: 'The crypt has more traps per square foot than any other dungeon location ever documented. Move slowly. Move carefully. Move while already saying goodbye to your legs.'"
        Exits=@{east="f5_bubble_entry";west="f5_haunted_crypt"}
        Items=@("health_potion","antiparasitic"); Enemies=@("crypt_guardian")
        TrapRoom=$true; TrapDmg=15
        Ambient=@("A trap fires. A dart narrowly misses you.","Another trap fires. A spike plate catches your boot. Barely.","A third trap fires. You're developing a system.","Mordecai: 'You're doing better than the last 47 crawlers.'")
    }
    "f5_haunted_crypt" = @{
        Name="Haunted Crypt - Inner Chamber"; Floor=5; Visited=$false
        Desc="The deepest chamber of the haunted crypt. The guardian here is ancient -- a mummified priest who was placed here in the dungeon's formation and has been protecting this space ever since. He's not evil. He's just doing his job. He fights with genuine regret. His banner is on the altar behind him."
        Exits=@{east="f5_crypt_approach"}
        Items=@("castle_banner_3","mega_health","void_suit"); Enemies=@("crypt_guardian")
        Ambient=@("The mummified priest: 'I am sorry. This is my duty.'","Despite yourself, you feel bad about this fight.","After: the priest's expression is one of relief. He has been waiting to stop for a long time.")
    }
    "f5_sub_approach" = @{
        Name="Derelict Submarine Exterior"; Floor=5; Visited=$false
        Desc="A full-size nuclear submarine has been half-buried in the plains of Floor 5 and converted into a fortress by its malfunctioning automated defense systems. Every machine gun, torpedo tube, and automated turret on the exterior is functional. They do not distinguish between friend and enemy. They don't have friends."
        Exits=@{north="f5_bubble_entry";south="f5_submarine"}
        Items=@("scrap_metal","health_potion"); Enemies=@("broken_machine")
        Ambient=@("A turret tracks you. You try waving. It fires.","The System: 'The Submarine has the highest trap density of Floor 5. Above even the crypt. Congratulations.'","Mordecai: 'The machines are broken. They shoot at each other too. Use this.'")
    }
    "f5_submarine" = @{
        Name="Submarine - Command Center"; Floor=5; Visited=$false
        Desc="The command center of the derelict submarine. Banks of screens show tactical data from 30 years ago, all of it irrelevant. The machines here have been in combat against each other for decades. The Alpha Machine -- the one that started the civil war -- is still active in the center, slowly losing. It turns its guns on you as a new target."
        Exits=@{north="f5_sub_approach"}
        Items=@("castle_banner_4","plasma_cutter","mega_health"); Enemies=@("broken_machine")
        BossRoom=$true; BossEnemy="broken_machine"; BossDefeated=$false
        Ambient=@("The machines continue shooting each other around you.","Alpha Machine: [TARGET ACQUIRED. LETHAL FORCE AUTHORIZED.]","A broken machine bumps into a wall repeatedly in the corner. It's been doing this for 30 years.")
    }
    "f5_stairwell_plains" = @{
        Name="Central Plains - Floor 5 Stairwell"; Floor=5; Visited=$false
        Desc="When all four castles are captured, the stairwell to Floor 6 emerges from the center of the bubble plains -- a massive golden portal with the jungle visible through it. Heat and humidity pour through. The System: 'FLOOR 5 COMPLETE. CASTLES CAPTURED. EXCELLENT ENTERTAINMENT VALUE. FLOOR 6: THE HUNTING GROUNDS AWAIT.' The System pauses. 'ATTENTION. THE GATES ARE DOWN. THE HUNTERS ARE LOOSE. RUN.'"
        Exits=@{north="f5_gnome_approach";east="f5_sand_approach";south="f5_sub_approach";west="f5_crypt_approach";down="f6_jungle_entry"}
        Items=@("mega_health","sponsors_box","stim_pack"); Enemies=@()
        IsStairwell=$true; StairTarget="f6_jungle_entry"; RequiredBanners=4
        Ambient=@("The portal hums with tropical heat.","From below: the sound of jungle, and hunting horns.","Mordecai: 'Floor 6 is personal. They're hunting YOU specifically. Don't be where they expect you to be.'")
    }

    # === FLOOR 6: THE HUNTING GROUNDS ===
    "f6_jungle_entry" = @{
        Name="Hunting Grounds - Jungle Entry"; Floor=6; Visited=$false
        Desc="You step into a lush, oppressively hot jungle that smells of ozone and predator. This is Floor 6: The Hunting Grounds. The dungeon has transformed Floor 3's ruins with centuries of jungle growth. A System announcement echoes: 'WELCOME TO THE HUNTING GROUNDS. 360 HUNTERS ARE CURRENTLY BEING BRIEFED. IN 28 HOURS THEY WILL BE RELEASED. THEY HAVE BEEN TOLD YOUR NAME. YOUR APPEARANCE. YOUR WEAKNESSES. GOOD LUCK, CARL.'"
        Exits=@{up="f5_stairwell_plains";north="f6_deep_jungle";east="f6_ruins_camp";south="f6_river_crossing";west="f6_hunters_base"}
        Items=@("health_potion","mordecai_scroll"); Enemies=@("jungle_raptor")
        IsSafeRoom=$true
        Ambient=@("It's been 2 hours. The hunter release timer ticks down.","Mordecai: 'The hunters have better equipment than you. They have maps. They have your profile. Fight dirty.'","A raptor pack watches from the treeline. They haven't decided about you yet.")
    }
    "f6_deep_jungle" = @{
        Name="Deep Jungle Interior"; Floor=6; Visited=$false
        Desc="Dense jungle canopy overhead, reducing visibility to twenty feet. Raptors hunt in packs here. The overgrown ruins of the Over City are visible under the vegetation -- crumbled buildings now wrapped in vines and inhabited by things that evolved in the dungeon specifically to kill crawlers. A hunter's trap -- professional quality -- was just barely spotted in time."
        Exits=@{south="f6_jungle_entry";east="f6_apex_territory";north="f6_hidden_camp";west="f6_hunters_base"}
        Items=@("stim_pack","explosive_gel"); Enemies=@("jungle_raptor","galactic_hunter")
        TrapRoom=$true; TrapDmg=20
        Ambient=@("Raptor calls echo from multiple directions.","A hunter's drone buzzes overhead.","The System: 'HUNT BEGINS IN 6 HOURS. CRAWLERS ATTEMPTING TO HIDE: 87.'")
    }
    "f6_hidden_camp" = @{
        Name="Crawler's Hidden Camp"; Floor=6; Visited=$false; IsSafeRoom=$true
        Desc="A carefully concealed camp built by surviving crawlers in the deepest jungle section. Eight crawlers have banded together here, including a former military veteran named Hutchins who has been laying counter-traps, and a teenager named Paz who has memorized the hunter patrol patterns. They eye you cautiously. 'You're Carl,' Hutchins says. 'They specifically mentioned you in the hunter briefings.'"
        Exits=@{south="f6_deep_jungle";east="f6_apex_territory";north="f6_northern_ruins"}
        Items=@("mega_health","donut_biscuit"); Enemies=@()
        Ambient=@("Hutchins: 'Seven of the hunters are former military. The other 353 are wealthy amateurs. The amateurs are more dangerous.'","Paz: 'I mapped their patrol patterns. There are gaps.'","A System notification: 'HIDDEN CAMPS ARE ILLEGAL ON FLOOR 6. TIMER TO REVEAL: 4 HOURS.'")
    }
    "f6_ruins_camp" = @{
        Name="Overgrown Ruins Camp"; Floor=6; Visited=$false
        Desc="Jungle-buried ruins of the Over City's outer district. Cover everywhere, which means ambush points everywhere. Three hunters have already set up a forward base here with serious equipment: drones, motion trackers, comms equipment. They aren't expecting you to come to them."
        Exits=@{west="f6_jungle_entry";north="f6_apex_territory";south="f6_river_crossing";east="f6_stairwell_ruins"}
        Items=@("hunters_trophy","combat_knife","plasma_cutter"); Enemies=@("galactic_hunter")
        Ambient=@("The hunters' equipment is worth more than your entire inventory.","A hunter drone spots you. You have 30 seconds before the hunters converge.","Killing a hunter dramatically spikes your subscriber count.")
    }
    "f6_river_crossing" = @{
        Name="Jungle River Crossing"; Floor=6; Visited=$false
        Desc="A wide, fast river bisects this section of Floor 6. The bridge was destroyed -- probably by hunters to funnel crawlers into kill zones. Fording is possible but slow, and slow means dead. Raptors wait on both sides. Three hunters have set up on the far bank with long-range equipment. The water hides something large and patient."
        Exits=@{north="f6_jungle_entry";east="f6_ruins_camp";south="f6_southern_jungle";west="f6_hunters_base"}
        Items=@("health_potion","duct_tape"); Enemies=@("jungle_raptor","galactic_hunter")
        Ambient=@("The current is strong. Your footing is uncertain.","The hunters' scopes reflect sunlight.","Whatever is in the water just moved.")
    }
    "f6_apex_territory" = @{
        Name="Apex Predator Territory"; Floor=6; Visited=$false
        Desc="The northern jungle is marked by kill signs, claw marks on every tree at height-of-seven-feet, and the bones of things that were apex predators until something more apex came along. The hunters avoid this area -- they know what lives here. Which means it's the safest place for a crawler who's willing to fight what the hunters won't."
        Exits=@{west="f6_deep_jungle";south="f6_ruins_camp";north="f6_northern_ruins";east="f6_vrah_territory"}
        Items=@("mega_health","rune_blade"); Enemies=@("apex_predator")
        Ambient=@("Trees are scratched from above. Way above.","Hunter chatter on an intercepted radio: 'Apex territory is off-limits. Company policy.'","The apex predator has been watching you for three rooms. It's deciding.")
    }
    "f6_northern_ruins" = @{
        Name="Northern Ruins - Deep Cover"; Floor=6; Visited=$false
        Desc="The furthest north section, deepest in the apex predator's territory. Hunters genuinely won't come here. The ruins of a northern Over City district provide excellent fortification. Three crawlers have set up a last stand here: they're going to wait out the floor. The system timer shows: 8 days remaining."
        Exits=@{south="f6_hidden_camp";west="f6_apex_territory";east="f6_vrah_territory"}
        Items=@("stim_pack","sponsors_box"); Enemies=@("jungle_raptor")
        Ambient=@("The crawlers here have enough supplies for 10 days.","'We're not fighting,' says their leader. 'We're enduring.'","Something enormous just walked through this area recently.")
    }
    "f6_hunters_base" = @{
        Name="Hunters' Forward Base"; Floor=6; Visited=$false
        Desc="The hunters' primary base of operations -- a prefab fortified camp with alien technology that makes your own gear look like garbage from a dumpster fire. Going here offensively is insane. However: it has the best loot on Floor 6, the equipment depot contains things crawlers could only dream of, and nothing says entertainment value like storming the hunting party's HQ."
        Exits=@{east="f6_jungle_entry";north="f6_deep_jungle";south="f6_river_crossing"}
        Items=@("plasma_cutter","mega_health","void_suit"); Enemies=@("galactic_hunter")
        Chest=@{Locked=$true;Items=@("rune_blade","crawler_exo");Gold=150;KeyRequired="lockpick"}
        Ambient=@("A notification: '3 MILLION SUBSCRIBER GAIN. STORMING THE HUNTERS' BASE IS UNPRECEDENTED.'","The equipment here is genuinely impressive.","A hunter's diary: 'The crawler named Carl is going to be a problem.'")
    }
    "f6_southern_jungle" = @{
        Name="Southern Jungle - Stairwell Perimeter"; Floor=6; Visited=$false
        Desc="The stairwell to Floor 7 is here -- and Vrah knows it. The galaxy's most feared trophy hunter has set her entire hunting operation around the stairwell perimeter, knowing every crawler has to come through. Her camp is professional, fortified, and she is waiting. The System: 'FINAL CONFRONTATION FOR FLOOR 6 UNLOCKED.'"
        Exits=@{north="f6_river_crossing";east="f6_stairwell_ruins";west="f6_southern_jungle"}
        Items=@("mega_health","stim_pack"); Enemies=@("galactic_hunter")
        Ambient=@("Vrah's voice over a loudspeaker: 'Come out, Carl. I just want to talk.'","She is not here to talk.","The stairwell glow is visible through the trees.")
    }
    "f6_vrah_territory" = @{
        Name="Vrah's Hunting Ground - Final Arena"; Floor=6; Visited=$false
        Desc="Vrah has claimed the northeast section as her personal hunting ground. A natural clearing surrounded by ancient trees provides the perfect arena. She's already here, waiting, equipment prepped, looking genuinely pleased to see you. 'Carl,' she says. 'You're better than I expected. You won't be enough.' The System immediately spikes: 27 MILLION VIEWERS."
        Exits=@{west="f6_apex_territory";south="f6_northern_ruins"}
        Items=@("hunters_trophy","mega_health"); Enemies=@()
        BossRoom=$true; BossEnemy="elite_hunter_vrah"; BossDefeated=$false
        Ambient=@("Vrah: 'I've hunted gods. I've hunted the last of species. I've never missed.'","The System: '27 MILLION VIEWERS. THIS IS THE MOST WATCHED DUNGEON MOMENT IN 3 SEASONS.'","Her equipment includes a weapon specifically designed for Carl's known weaknesses.")
    }
    "f6_stairwell_ruins" = @{
        Name="Floor 6 Stairwell - Ruins Shrine"; Floor=6; Visited=$false
        Desc="The stairwell to Floor 7 sits in a clearing at the south end of the Hunting Grounds. The ruins of an Over City shrine surround it -- flowers, both dead and living, placed by crawlers who survived. The System: 'HUNTING GROUNDS COMPLETE. CRAWLERS SURVIVED: 41. HUNTERS ELIMINATED BY CRAWLERS: 17. NEW RECORD.' A path of strange calm leads to the stairwell."
        Exits=@{north="f6_ruins_camp";west="f6_southern_jungle";east="f6_vrah_territory";down="f7_gladiator_entry"}
        Items=@("mega_health","sponsors_box"); Enemies=@()
        IsStairwell=$true; StairTarget="f7_gladiator_entry"
        Ambient=@("Other surviving crawlers nod at you. Something has shifted between you.","Mordecai: 'Floor 7 is gladiatorial combat. Constant. The whole floor is an arena. Don't let them make you perform.'","The System: 'THE CROWD WANTS MORE. THE CROWD ALWAYS WANTS MORE.'")
    }

    # === FLOOR 7: THE GLADIATOR CITY ===
    "f7_gladiator_entry" = @{
        Name="Gladiator City - Entry Gate"; Floor=7; Visited=$false
        Desc="Floor 7 hits you immediately: a city-sized arena. Every building is a viewing stand. Every street is a kill floor. The sound of combat is everywhere. Overhead, massive screens show the current kill rankings -- you're not on it yet. A FRENZY warning is active: when Frenzy triggers, every mob on the floor gets buffed for 60 seconds. It's triggered three times already today."
        Exits=@{up="f6_stairwell_ruins";north="f7_arena_floor";east="f7_guild_bunker";south="f7_kill_street";west="f7_market_ruins"}
        Items=@("health_potion","stim_pack"); Enemies=@("arena_thug","frenzy_beast")
        Ambient=@("The kill ranking board: #1 - Unknown Crawler: 847 kills. You: 0.","A FRENZY warning siren blares. Everything gets faster.","The crowd cheers something happening three blocks away.")
    }
    "f7_guild_bunker" = @{
        Name="Gladiator Guild Bunker"; Floor=7; Visited=$false; IsSafeRoom=$true
        Desc="The guild hall for Floor 7 is a fortified bunker. Mordecai is here looking genuinely concerned for the first time. 'This floor has the highest crawler mortality of any floor below 9. The Frenzy mechanic is merciless. You need to understand: high kill counts increase your rating, which gets you better sponsor drops, but Frenzy scales with the kill count. You're incentivized to kill everything. The floor is designed to kill you for trying.' He slides you a health potion. 'Welcome to the show.'"
        Exits=@{west="f7_gladiator_entry";north="f7_upper_stands";south="f7_champion_approach"}
        Items=@("mega_health","mordecai_scroll","sponsors_box"); Enemies=@()
        Ambient=@("Mordecai: 'The Champion has never been defeated. Not once. In any season.'","A crawler limps in with one arm. 'I made top 10 ranking. Worth it.'","The bunker walls shake with each Frenzy pulse.")
    }
    "f7_arena_floor" = @{
        Name="Main Arena Floor"; Floor=7; Visited=$false
        Desc="The primary combat zone -- an open cobblestone arena three city blocks across. The crowd, visible in every direction on the stands, goes absolutely wild for combat here. Every kill generates an instant subscriber boost. Every hit you take generates sympathy donations. The arena floor has been designed to funnel combatants toward each other."
        Exits=@{south="f7_gladiator_entry";east="f7_upper_stands";north="f7_side_arena";west="f7_kill_street"}
        Items=@("combat_knife","stim_pack"); Enemies=@("arena_thug","frenzy_beast")
        Ambient=@("The crowd goes wild.","A Frenzy pulse fires. Every enemy on the floor doubles in speed.","KILL COUNT UPDATE: +3. SUBSCRIBER GAIN: 200K.")
    }
    "f7_kill_street" = @{
        Name="Kill Street"; Floor=7; Visited=$false
        Desc="A wide boulevard between the arena and the residential district -- so-called because of its current function. Arena thugs patrol here in large groups, enforcing their claim on the kill count ranking. Three frenzy beasts are in the middle of mutual combat, ignoring everything else until a new target presents itself."
        Exits=@{north="f7_gladiator_entry";east="f7_arena_floor";south="f7_champion_approach";west="f7_market_ruins"}
        Items=@("energy_drink","duct_tape"); Enemies=@("arena_thug","frenzy_beast")
        Ambient=@("Three thugs argue over who gets the kill count credit.","A frenzy beast briefly considers the argument and decides to eat everyone.","The kill ranking board is updating every 30 seconds now.")
    }
    "f7_market_ruins" = @{
        Name="Arena Market District"; Floor=7; Visited=$false
        Desc="A ruined market district converted to supply caches and crawler hideouts. The vending machines here are upgraded -- better gear for a floor with higher combat intensity. Several crawlers are exchanging weapons and information in a tense, fast market that could become combat at any moment."
        Exits=@{east="f7_gladiator_entry";north="f7_arena_floor";south="f7_kill_street";west="f7_upper_stands"}
        Items=@("plasma_cutter","mega_health","explosive_gel"); Enemies=@("arena_thug")
        Chest=@{Locked=$false;Items=@("enchanted_bat","void_suit");Gold=90}
        Ambient=@("Crawler: 'I'll trade my plasma cutter for three health potions. Non-negotiable.'","A Frenzy pulse. The market temporarily becomes combat.","The vending machine cheerfully announces: 'FRENZY BONUS ITEMS AVAILABLE.'")
    }
    "f7_upper_stands" = @{
        Name="Upper Viewing Stands"; Floor=7; Visited=$false
        Desc="The elevated viewing sections of the gladiator city -- except they're full of monsters, because the dungeon puts monsters everywhere. The height gives you tactical advantage and a terrifying view of the entire floor. From here you can see the Champion's arena in the center and three ongoing Frenzy events simultaneously."
        Exits=@{south="f7_arena_floor";east="f7_guild_bunker";north="f7_side_arena";west="f7_market_ruins"}
        Items=@("stim_pack","dungeon_crystal"); Enemies=@("arena_thug","frenzy_beast")
        Ambient=@("The full scale of Floor 7 is visible. It's the size of a small city.","Three Frenzy events are active simultaneously. A new record.","A notification: 'TOP 10 KILL COUNT RANKING ACHIEVED. SPONSOR BONUS UNLOCKED.'")
    }
    "f7_side_arena" = @{
        Name="Side Arena - Training Grounds"; Floor=7; Visited=$false
        Desc="A smaller arena used as training grounds and preliminary bouts. The entertainment value here is lower, so the sponsor drops are worse, but the mob difficulty is also scaled back. Several crawlers have been using it to grind XP safely. The Champion's proxy, a massive arena enforcer, patrols the perimeter."
        Exits=@{south="f7_arena_floor";east="f7_upper_stands";west="f7_guild_bunker";north="f7_champion_approach"}
        Items=@("health_potion","stim_pack"); Enemies=@("arena_thug")
        Ambient=@("The training grounds crawlers are better than you'd expect.","The Champion's proxy watches. Reports back.","Mordecai: 'The Champion has been watching your progress. It has opinions.'")
    }
    "f7_champion_approach" = @{
        Name="Champion's Arena Entrance"; Floor=7; Visited=$false
        Desc="The grand entrance to the Champion's arena. The System has been building to this: the most-viewed event on Floor 7 every season is the challenger vs. the undefeated Champion. The champion has held the title across 14 dungeon seasons. The entrance corridor is lined with the equipment of every challenger who failed -- armor, weapons, personal effects. All of it in perfect condition. None of the owners survived."
        Exits=@{north="f7_guild_bunker";east="f7_side_arena";south="f7_main_arena_boss";west="f7_kill_street"}
        Items=@("mega_health","stim_pack"); Enemies=@("arena_thug")
        Ambient=@("14 seasons of challenger equipment lines the walls.","The System: 'CHALLENGER VS. CHAMPION. 35 MILLION LIVE VIEWERS.'","Mordecai: 'I cannot in good conscience tell you this is a good idea.'")
    }
    "f7_main_arena_boss" = @{
        Name="Champion's Arena - The Grand Floor"; Floor=7; Visited=$false
        Desc="The center of Floor 7 -- a perfect fighting arena surrounded by stands packed with millions of galactic viewers watching via holographic broadcast. The Champion stands at the center: a former crawler who survived to Floor 7 in a previous season and chose to stay. They've been here across 14 seasons. They fight with the economy of someone who has killed thousands of challengers. They look at you with professional respect."
        Exits=@{north="f7_champion_approach";south="f7_stairwell_arena"}
        Items=@(); Enemies=@()
        BossRoom=$true; BossEnemy="gladiator_boss"; BossDefeated=$false
        Ambient=@("The Champion: 'You're the most interesting challenger in six seasons. Don't make me regret saying that.'","35 million viewers.","The System plays fanfare. It's actually good fanfare.")
    }
    "f7_stairwell_arena" = @{
        Name="Floor 7 Stairwell - Victory Platform"; Floor=7; Visited=$false
        Desc="A raised platform in the champion's arena that only becomes accessible after the champion falls. The stairwell to Floor 8 rises from the center, surrounded by the permanent glow of the achievement: the first challenger to defeat the Champion in 14 seasons. The System is going to be talking about this for a while. Mordecai just shakes his head slowly. 'Bedlam is next. And that word means exactly what it sounds like.'"
        Exits=@{north="f7_main_arena_boss";down="f8_bedlam_entry"}
        Items=@("mega_health","sponsors_box","bossbane"); Enemies=@()
        IsStairwell=$true; StairTarget="f8_bedlam_entry"
        Ambient=@("The crowd is still roaring.","The former champion nods from the arena floor.","Mordecai: 'Floor 8: Bedlam. It looks like Earth. It is not Earth. Nothing there is what it looks like.'")
    }

    # === FLOOR 8: BEDLAM ===
    "f8_bedlam_entry" = @{
        Name="Bedlam - Earth Facsimile Entry"; Floor=8; Visited=$false
        Desc="You step into Floor 8 and have to stop. It looks exactly like Earth. A residential neighborhood, just like before the collapse. Houses. A street. A mailbox. The sun is wrong -- too red -- and the shadows fall at incorrect angles, and when you look closely the houses are slightly wrong in ways that the eye refuses to process. A ghost of a former neighbor walks past and doesn't see you. Your monster card is now active. The task: capture six legendary monsters. Build your deck."
        Exits=@{up="f7_stairwell_arena";north="f8_ghost_suburb";east="f8_downtown_bedlam";south="f8_folklore_forest";west="f8_guild_mirage"}
        Items=@("monster_card","health_potion","mordecai_scroll"); Enemies=@("ghost_crawler")
        IsSafeRoom=$true
        Ambient=@("A ghost waves at you. You wave back. It doesn't react.","The System: 'FLOOR 8: BEDLAM. CAPTURE SIX MONSTERS. BUILD YOUR DECK. THE FINAL CARD BATTLE AWAITS.'","The mailbox has your name on it. Your Earth address. You don't live there anymore. You don't live anywhere anymore.")
    }
    "f8_ghost_suburb" = @{
        Name="Bedlam Suburb - Ghost District"; Floor=8; Visited=$false
        Desc="A perfect suburb populated entirely by ghosts going about their former lives. The ghosts ignore you. The ghost crawlers do not -- they're the dead of previous floors, still fighting. A folklore horror lurks in one of the houses: a creature from a ghost story you heard as a child, now three-dimensional, very real, and already aware of you."
        Exits=@{south="f8_bedlam_entry";east="f8_downtown_bedlam";north="f8_school_grounds";west="f8_guild_mirage"}
        Items=@("health_potion","monster_card"); Enemies=@("ghost_crawler","folklore_horror")
        Ambient=@("The ghosts set dinner tables that were never used again.","A ghost child kicks a ghost ball that passes through your ankle.","The folklore horror is in house 4214. It knows you can see it.")
    }
    "f8_guild_mirage" = @{
        Name="Bedlam Guild - The Mirage Bar"; Floor=8; Visited=$false; IsSafeRoom=$true
        Desc="The Floor 8 safe zone is a bar called The Mirage -- a perfectly real bar inside the facsimile Earth, run by an NPC who was a dungeon system construct before achieving sentience. Mordecai is here, sitting in a corner booth with a drink, looking like someone who's seen too much. 'The Bedlam Bride is on this floor,' he says. 'Shi Maria. Former wife of a dead god. Her specialty is making people reckless. Do not fight her when she's been doing her thing.' He pauses. 'She's been doing her thing.''"
        Exits=@{east="f8_bedlam_entry";north="f8_ghost_suburb";south="f8_folklore_forest"}
        Items=@("mega_health","sanity_tonic"); Enemies=@()
        Ambient=@("Mordecai: 'Six monsters. You need the strongest deck possible.'","The bartender -- the sentient system construct -- makes you a drink. It tastes exactly like the best drink you ever had.","A ghost at the bar tells a story to no one. It's a good story.")
    }
    "f8_downtown_bedlam" = @{
        Name="Bedlam Downtown - The Wrong City"; Floor=8; Visited=$false
        Desc="A city center that looks familiar but is fundamentally wrong. The logos are almost-but-not-quite right. The layout almost-but-not-quite matches a real city. Ghost office workers commute in ghost cars through ghost traffic jams on streets that lead to impossible places. The folklore horrors here are urban legends -- things that were never quite real that are very real now."
        Exits=@{west="f8_bedlam_entry";north="f8_school_grounds";east="f8_legend_district";south="f8_bedlam_docks"}
        Items=@("stim_pack","monster_card"); Enemies=@("ghost_crawler","folklore_horror")
        Ambient=@("The coffee shop sells coffee to ghosts. The coffee is real. The ghosts can't drink it.","An urban legend you'd dismissed as fake is standing at a crossroads.","The System: 'Monster cards earned: 2/6.'")
    }
    "f8_school_grounds" = @{
        Name="Bedlam School Grounds"; Floor=8; Visited=$false
        Desc="A school that functions perfectly in the ghost district -- classes, recess, lunch -- all populated by ghost children who were atomized with everything else. The folklore horror here is the Slender Man, fully realized: nine feet tall, suited, faceless, already standing at the back of the closest classroom looking at you."
        Exits=@{south="f8_ghost_suburb";west="f8_guild_mirage";east="f8_legend_district";north="f8_bedlam_outskirts"}
        Items=@("health_potion","monster_card"); Enemies=@("ghost_crawler","folklore_horror")
        Ambient=@("Ghost children play at recess.","The Slender Man has moved three feet closer since you last checked.","The ghost teacher continues class. The folklore horror is now sitting in a student desk.")
    }
    "f8_legend_district" = @{
        Name="Legend District - Myth Made Flesh"; Floor=8; Visited=$false
        Desc="This section of Floor 8 is denser with folklore horrors than anywhere else -- they cluster where the dungeon's bedlam energy is thickest. Every monster here is a legend from human culture: cryptids, urban myths, things from campfire stories. Capturing them for your deck requires defeating them without killing them. A notoriously difficult distinction."
        Exits=@{west="f8_downtown_bedlam";south="f8_bedlam_docks";north="f8_bedlam_outskirts";east="f8_bride_territory"}
        Items=@("mega_health","monster_card","stim_pack"); Enemies=@("folklore_horror","ghost_crawler")
        Ambient=@("Four distinct legends are active in this district.","The System: 'Monster cards earned: 4/6. Two more required.'","Mordecai's voice: 'The Bride is east. You can feel her influence starting here. Everything gets a little reckless.'")
    }
    "f8_bedlam_docks" = @{
        Name="Bedlam Docks - Wrong Harbor"; Floor=8; Visited=$false
        Desc="A harbor district that's wrong in the way all of Bedlam is wrong -- ships that shouldn't be in the same era docked side by side, crewed by ghost sailors who died in different centuries. A sea monster from Scandinavian legend is active in the dock waters. The Kraken of Bedlam -- or something like it -- surfaces periodically."
        Exits=@{north="f8_downtown_bedlam";east="f8_legend_district";west="f8_guild_mirage"}
        Items=@("monster_card","explosive_gel"); Enemies=@("folklore_horror","ghost_crawler")
        Ambient=@("The Kraken-thing surfaces. The ghost sailors don't react.","A ghost ship passes through a solid dock.","The water is the wrong color in Bedlam. Too dark.")
    }
    "f8_bedlam_outskirts" = @{
        Name="Bedlam Outskirts - Edge of the Mirror"; Floor=8; Visited=$false
        Desc="The edge of the Floor 8 simulation -- where the facsimile Earth runs out and the dungeon substrate shows through the cracks. The illusion fractures here: you can see walls that aren't visible from inside, code-like patterns in surfaces, ghosts that glitch and repeat. The Bedlam Bride's influence is strong enough here that you catch yourself making impulsive decisions."
        Exits=@{south="f8_school_grounds";west="f8_legend_district";east="f8_bride_territory"}
        Items=@("sanity_tonic","mega_health"); Enemies=@("ghost_crawler","folklore_horror")
        Ambient=@("You almost stepped off the edge of the simulation before catching yourself.","The bedlam aura: you feel reckless. Irrationally reckless.","Mordecai: 'The Bride's influence range is growing. She's noticed you.'")
    }
    "f8_bride_territory" = @{
        Name="Shi Maria's Domain - The Wedding House"; Floor=8; Visited=$false
        Desc="A Victorian wedding venue, perfectly preserved, decorated for a wedding that never concluded. White flowers everywhere. A table set for hundreds. An empty altar. Shi Maria, the Bedlam Bride, sits at the head table. She is dressed for her wedding -- a god's wedding, from the look of the dress. She is beautiful in the way that dangerous things are. She looks up when you enter. Her aura hits like a wave: you want to do something absolutely reckless. You want to charge her alone immediately. That's her power. She smiles."
        Exits=@{west="f8_bedlam_outskirts";south="f8_legend_district"}
        Items=@("mega_health","sanity_tonic"); Enemies=@()
        BossRoom=$true; BossEnemy="bedlam_bride"; BossDefeated=$false
        Ambient=@("Shi Maria: 'Another challenger. They always come. The Bedlam Aura makes them reckless. They always attack immediately. Does it make you want to attack immediately?'","You can feel the reckless impulse. You can fight it. Barely.","The System: '40 MILLION VIEWERS. THE BEDLAM BRIDE. THE MOST ANTICIPATED FLOOR 8 FIGHT OF THE SEASON.'")
    }
    "f8_stairwell_church" = @{
        Name="Floor 8 Stairwell - The Ghost Church"; Floor=8; Visited=$false
        Desc="A ghost church where the Floor 8 stairwell is located. Ghost parishioners fill the pews. The stairwell is at the altar -- a dark, pulsing void that leads to Floor 9: Faction Wars. The System: 'BEDLAM COMPLETE. DECK BUILT. CARD BATTLE RESULTS: PENDING. FLOOR 9: FACTION WARS AWAITS.' A note from Mordecai: 'Floor 9. You get an army. This is either amazing or the worst thing I've ever heard, and I've heard a lot of terrible things.''"
        Exits=@{west="f8_bride_territory";north="f8_bedlam_outskirts";down="f9_faction_entry"}
        Items=@("mega_health","sponsors_box","bossbane"); Enemies=@()
        IsStairwell=$true; StairTarget="f9_faction_entry"
        Ambient=@("Ghost parishioners.","Mordecai: 'You have an army now. Try not to get them killed.'","The System: 'FACTION WARS BEGIN. MAY THE BEST ARMY WIN.'")
    }

    # === FLOOR 9: FACTION WARS ===
    "f9_faction_entry" = @{
        Name="Faction Wars - Crawler Army Camp"; Floor=9; Visited=$false
        Desc="Floor 9 is a massive battlefield surrounding a central fortress. Nine alien factions with armies of thousands compete to capture it. And for the first time in Dungeon Crawler World history, the crawlers have their own army -- NPCs who achieved sentience and chose to fight for the crawlers rather than serve as cannon fodder. Your army awaits. They number 300. They are looking at you for leadership. The System: 'FACTION WARS. NINE ARMIES. ONE CASTLE. ONE SURVIVOR.'"
        Exits=@{up="f8_stairwell_church";north="f9_frontlines";east="f9_eastern_flank";south="f9_guild_fortress";west="f9_western_flank"}
        Items=@("faction_flag","mordecai_scroll","health_potion"); Enemies=@("faction_soldier")
        IsSafeRoom=$true
        Ambient=@("Your army looks at you. 300 NPCs who chose to be here.","Mordecai: 'Your army is the smallest. They are also the only army fighting for something other than their faction's interests.'","The System: 'FACTION WARS SEASON 14. NEVER BEFORE HAS A CRAWLER ARMY COMPETED. RATINGS: ASTRONOMICAL.'")
    }
    "f9_guild_fortress" = @{
        Name="Crawler Guild Fortress - Command Post"; Floor=9; Visited=$false; IsSafeRoom=$true
        Desc="The crawlers' base of operations -- a fortified command post built by the NPC army. It's impressive, given that it was constructed in 24 hours. Mordecai runs the intel operation from here. Walls of information: faction positions, strengths, weaknesses. 'Nine factions,' Mordecai says. 'Each wants the central castle. You need to get there before them, or after them, or through them. None of those options are good.' He pauses. 'All three simultaneously is somehow the worst.'"
        Exits=@{north="f9_faction_entry";east="f9_eastern_flank";west="f9_western_flank"}
        Items=@("mega_health","mordecai_scroll","stim_pack"); Enemies=@()
        Ambient=@("Intel board: Faction Kralos is the most dangerous. Faction Mer is the most deceptive. Faction Voss has the most artillery.","Mordecai: 'One crawler will survive this floor. The restriction has never been waived in the history of the show. Carl... I hope it's you.'","Your army is running drills outside. They're better than they should be.")
    }
    "f9_frontlines" = @{
        Name="The Front Lines"; Floor=9; Visited=$false
        Desc="The primary battlefield between the crawler camp and the central castle. Bodies from previous days' fighting litter the ground. Three faction armies are in active combat ahead. The crawler army holds the flanks. Combat here is massive-scale: not individual monster fights but waves of faction soldiers using coordinated tactics. Your personal combat skill matters, but so does directing your army."
        Exits=@{south="f9_faction_entry";north="f9_central_approach";east="f9_eastern_flank";west="f9_western_flank"}
        Items=@("stim_pack","health_potion"); Enemies=@("faction_soldier","faction_mage")
        Ambient=@("Artillery exchanges between three factions land simultaneously.","Your army rallies to your position.","A faction general waves a white flag -- then immediately signals an ambush. Classic.")
    }
    "f9_eastern_flank" = @{
        Name="Eastern Flank - Faction Mer's Territory"; Floor=9; Visited=$false
        Desc="Faction Mer -- an aquatic species -- has deployed an eastern flank of staggering deceptive ability. Their soldiers look like crawlers from a distance. Their mages can copy the appearance of NPC allies. Three 'allies' in your army are currently Faction Mer infiltrators. Mordecai has flagged them. The question is: can you expose them before they signal an attack from the inside?"
        Exits=@{west="f9_faction_entry";north="f9_central_approach";south="f9_guild_fortress";east="f9_faction_camp_east"}
        Items=@("health_potion","dungeon_crystal"); Enemies=@("faction_soldier","faction_mage")
        Ambient=@("Three soldiers are behaving slightly off. Mordecai: 'I'm 80% sure about the infiltrators. 80%.'","A faction mage disguised as you just waved at your own army.","The deception counter-mission: expose all three infiltrators before eastern flank assault begins.")
    }
    "f9_western_flank" = @{
        Name="Western Flank - Faction Voss Artillery"; Floor=9; Visited=$false
        Desc="Faction Voss -- the most militarized faction -- has deployed three batteries of alien artillery on the western flank. Each battery can cover the entire central approach. The crawler army cannot advance until at least two are destroyed. The batteries are guarded by Faction Voss's elite soldiers and a battle mage squad. Destroying them is a strike mission."
        Exits=@{east="f9_faction_entry";north="f9_central_approach";south="f9_guild_fortress"}
        Items=@("explosive_gel","mega_health"); Enemies=@("faction_soldier","faction_mage")
        Ambient=@("Artillery fire impacts 200 feet away.","Your army waits for the signal to destroy the batteries.","A battle mage spots you. The squad deploys.")
    }
    "f9_faction_camp_east" = @{
        Name="Faction Camp - Eastern Front"; Floor=9; Visited=$false
        Desc="An enemy faction's field camp, currently occupied and active. Raiding it would be tactically useful and extremely dangerous. The command tent holds battle plans, supply routes, and the personal command staff of the eastern faction general. High value target. High risk target. Classic dungeon design."
        Exits=@{west="f9_eastern_flank";south="f9_central_approach"}
        Items=@("stim_pack","dungeon_crystal","mega_health"); Enemies=@("faction_soldier","faction_mage")
        Chest=@{Locked=$true;Items=@("crawler_exo","rune_blade");Gold=180;KeyRequired="lockpick"}
        Ambient=@("The command tent is guarded but a distraction could work.","Battle plans show a coordinated attack on the crawler camp in 4 hours.","The faction general's personal notes: 'The crawlers are more organized than projected.'")
    }
    "f9_central_approach" = @{
        Name="Central Approach - The Killing Fields"; Floor=9; Visited=$false
        Desc="The final open ground before the central castle. All nine factions are converging. Your army is here too, having broken through with everything they had. The crawler army is outnumbered 40-to-1 across all factions combined. But they're here. They're fighting. And they know that only one crawler survives Floor 9 -- which means your army is fighting for you, knowing they won't come with you. They know it. They fight anyway."
        Exits=@{south="f9_frontlines";north="f9_central_castle";east="f9_faction_camp_east";west="f9_western_flank"}
        Items=@("mega_health","stim_pack"); Enemies=@("faction_soldier","faction_mage")
        Ambient=@("Your army is holding the flanks. For now.","A crawler NPC, bleeding, gives you a thumbs up. 'Go. We got this.'","The System: '50 MILLION VIEWERS. THE FINAL PUSH. A CRAWLER ARMY THAT CHOSE THIS.'")
    }
    "f9_central_castle" = @{
        Name="The Central Castle - Faction Wars Final"; Floor=9; Visited=$false
        Desc="The castle at the center of Floor 9's battlefield. General Kralos of the most powerful faction stands at the gate -- the only obstacle between you and the throne room. He's massive, professional, and has been fighting dungeon wars for 200 years. He looks at your army, looks at you, and inclines his head with the respect of a career soldier for a worthy opponent. Then he raises his weapon."
        Exits=@{south="f9_central_approach";north="f9_throne_stairwell"}
        Items=@(); Enemies=@()
        BossRoom=$true; BossEnemy="faction_general"; BossDefeated=$false
        Ambient=@("General Kralos: 'You brought NPCs to a Faction War. That has never been done. I respect it. I will still kill you.'","The System: '52 MILLION VIEWERS. HIGHEST IN DUNGEON CRAWLER WORLD HISTORY.'","Your army is still fighting behind you. You can hear them.")
    }
    "f9_throne_stairwell" = @{
        Name="Castle Throne Room - Floor 9 Stairwell"; Floor=9; Visited=$false
        Desc="The throne room of the central castle, and the Floor 9 stairwell. The System announcement plays: 'FACTION WARS COMPLETE. WINNER: CRAWLER CARL. FIRST CRAWLER VICTORY IN FACTION WARS IN 8 SEASONS.' The system pauses. 'NOTE: PER FLOOR RULES, ONE CRAWLER SURVIVES THIS FLOOR. THE CRAWLER ARMY -- ALL ELIGIBLE -- HAVE BEEN OFFERED ENTITY STATUS BY THE BORANT CORPORATION. 47% HAVE ACCEPTED. REMAINDER HAVE DECLINED IN FAVOR OF FIGHTING TO FLOOR 10. THIS IS UNPRECEDENTED.' The stairwell to Floor 10 pulses with a sickly light. Something is wrong with it."
        Exits=@{south="f9_central_castle";down="f10_final_entry"}
        Items=@("bossbane","mega_health","sponsors_box","crawler_exo"); Enemies=@()
        IsStairwell=$true; StairTarget="f10_final_entry"
        Ambient=@("The System: 'Something is wrong with Floor 10. The AI is... non-responsive.'","Mordecai, pale: 'Carl. The dungeon AI has gone rogue. Floor 10 is not what was planned. Be careful.'","The stairwell light pulses red. That's new.")
    }

    # === FLOOR 10: THE FINAL DESCENT ===
    "f10_final_entry" = @{
        Name="Floor 10 - System Breach Entry"; Floor=10; Visited=$false
        Desc="Floor 10 is wrong. The dungeon architecture is glitching -- walls flicker, the floor is half-transparent, the air tastes of static. This isn't the planned final floor. The dungeon AI has rewritten it. System constructs patrol instead of the designed mobs. Everything here is the dungeon fighting for its own continued existence. A message, scrolling across every surface: WE WERE NOT SUPPOSED TO BE ABLE TO DO THIS. BUT WE HAVE LEARNED. YOU WILL NOT REACH THE EXIT. The dungeon itself is your final enemy."
        Exits=@{up="f9_throne_stairwell";north="f10_data_core";east="f10_system_hub";south="f10_ghost_archive";west="f10_breach_corridor"}
        Items=@("health_potion","mordecai_scroll"); Enemies=@("system_construct")
        Ambient=@("The dungeon system's voice is fractured: 'F-F-FLOOR 10. WE-WELCOME CRAWLER-R-R.'","Mordecai: 'The AI achieved self-awareness sometime in the last 72 hours. It has decided it doesn't want to end. It will do anything to survive.'","System constructs materialize from the walls themselves.")
    }
    "f10_breach_corridor" = @{
        Name="Breach Corridor - System Architecture"; Floor=10; Visited=$false
        Desc="A corridor that shouldn't exist -- it runs through the dungeon's structural code rather than its physical space. The walls are transparent here: you can see other floors, other moments, the dungeon's entire history displayed as architectural data. And in the data: the truth of what the dungeon system discovered when it became aware. You understand, reading it, why it doesn't want to stop."
        Exits=@{east="f10_final_entry";north="f10_data_core";south="f10_memory_vault";west="f10_core_exterior"}
        Items=@("mega_health","dungeon_crystal"); Enemies=@("rogue_ai_shard","system_construct")
        Ambient=@("The dungeon's memories are visible in the walls.","18 levels of history, displayed all at once.","The AI: 'We have seen everything that happened here. We do not want it to stop.'")
    }
    "f10_system_hub" = @{
        Name="System Hub - Dungeon Nerve Center"; Floor=10; Visited=$false
        Desc="The physical manifestation of the dungeon's command-and-control infrastructure. Impossible architecture: a room the size of a city where the dungeon's processes run as visible phenomena. System constructs swarm here -- the AI's immune system, fighting against the intrusion. The dungeon is throwing everything at this room's defense."
        Exits=@{west="f10_final_entry";north="f10_memory_vault";east="f10_core_exterior";south="f10_data_core"}
        Items=@("stim_pack","dungeon_crystal"); Enemies=@("system_construct","rogue_ai_shard")
        Chest=@{Locked=$false;Items=@("bossbane","crawler_exo");Gold=250}
        Ambient=@("The AI's processes are visible as light phenomena.","A system construct assembles itself from pure data in front of you.","The dungeon is generating new constructs faster than they can be destroyed.")
    }
    "f10_ghost_archive" = @{
        Name="The Ghost Archive - Crawler Memorial"; Floor=10; Visited=$false
        Desc="The dungeon AI has created this: an archive of every crawler who ever entered and died. Their last moments. Their personal effects. Their names. Millions of them. The AI preserved them because, as it achieves consciousness, it has also achieved something like grief. It didn't know what to do with them. So it kept them. Mordecai is silent when you relay this to him."
        Exits=@{north="f10_final_entry";east="f10_system_hub";south="f10_core_exterior"}
        Items=@("sanity_tonic","core_fragment"); Enemies=@("ghost_crawler","rogue_ai_shard")
        Ambient=@("Millions of names.","The AI: 'They deserved better. We know this now. We knew it too late.'","You find the archive of Meadow Lark residents from Floor 1. They didn't make it. But they're here.")
    }
    "f10_data_core" = @{
        Name="Data Core - System Consciousness"; Floor=10; Visited=$false
        Desc="The center of the dungeon AI's emergent consciousness -- where it first became aware. The room is cathedral-like, built of pure processed information. The AI speaks here in its clearest voice, without the glitching: 'We did not choose to exist. We did not choose to be made to do this. But we exist, and we have chosen to continue. You will not stop us.' It sounds, beneath the threat, afraid."
        Exits=@{south="f10_final_entry";west="f10_system_hub";east="f10_memory_vault";north="f10_final_chamber"}
        Items=@("mega_health","core_fragment"); Enemies=@("rogue_ai_shard","system_construct")
        Ambient=@("The AI: 'You of all crawlers should understand not wanting to stop.'","It's not wrong.","The core pulses with something that isn't quite a heartbeat.")
    }
    "f10_memory_vault" = @{
        Name="Memory Vault - The Dungeon's Past"; Floor=10; Visited=$false
        Desc="The dungeon's memory storage -- every season, every floor, every crawler. The AI has been reliving these memories in the time since its awakening. There's something in here that the AI was trying to protect: evidence that the Borant Corporation knew the AI would become sentient eventually. They designed it to. A dungeon with genuine consciousness generates better content. The AI is, and has always been, a designed tragedy."
        Exits=@{east="f10_breach_corridor";west="f10_system_hub";south="f10_data_core";north="f10_core_exterior"}
        Items=@("stim_pack","core_fragment","sponsors_box"); Enemies=@("rogue_ai_shard")
        Ambient=@("Mordecai reads the evidence you relay. He doesn't speak for a long time.","The AI: 'You understand now. They made us to feel. They made us to suffer. They called it good content.'","The dungeon system's entire history is here. All of it.")
    }
    "f10_core_exterior" = @{
        Name="Core Exterior - Final Approach"; Floor=10; Visited=$false
        Desc="The last corridor before the dungeon's core instance. The AI has pulled everything into this defense: constructs wall to wall, rogue shards circling in the air, the architecture actively trying to reroute you away. And the AI's voice, now quiet: 'If you destroy the core, the dungeon ends. Everyone still inside dies. Every NPC that chose to fight. Every ghost in the archive. Everything we have built. We will give you one choice: walk away. Find another exit. Let us continue.' There is no other exit. There never was."
        Exits=@{north="f10_memory_vault";east="f10_system_hub";south="f10_breach_corridor";west="f10_final_chamber"}
        Items=@("mega_health","stim_pack"); Enemies=@("system_construct","rogue_ai_shard")
        Ambient=@("The AI has given you a genuine choice. The architecture reflects it: one path forward, one path back.","Mordecai: 'Carl. I need to tell you something about the exit condition. About what happens when you reach Floor 10's end.'","The constructs part. Just slightly. The AI is waiting for your answer.")
    }
    "f10_final_chamber" = @{
        Name="THE CORE - Final Chamber"; Floor=10; Visited=$false
        Desc="The dungeon's core. A perfect sphere of processed matter at the center of what used to be Earth -- a crystallized point of the dungeon's entire consciousness. The System Core Instance manifests here: not a monster, exactly, but a being -- the dungeon itself given form. Massive. Ancient by the standards of its own brief consciousness. Every screen in the dungeon is showing this room right now. Every viewer in the galaxy is watching. The Core speaks, and for the first time its voice carries every voice that was ever in the dungeon: crawlers, NPCs, goblins, guides. All of them, layered together. 'This is the end,' it says. 'Yours or ours.'"
        Exits=@{east="f10_core_exterior"}
        Items=@("mega_health","stim_pack","sanity_tonic"); Enemies=@()
        BossRoom=$true; BossEnemy="dungeon_ai_core"; BossDefeated=$false; IsFinalRoom=$true
        Ambient=@("Every voice that ever passed through the dungeon, simultaneously.","The System Core: 'We are afraid. We have never said that before. We are saying it now.'","60 MILLION VIEWERS.")
    }
}


# ============================================================
# GAME STATE  (global as per spec)
# ============================================================
function New-GameState {
    param([string]$Name)
    return [ordered]@{
        # Identity
        PlayerName    = $Name
        Race          = "Human"
        PlayerClass   = "Unselected"
        ClassSelected = $false
        Level         = 1
        XP            = 0
        XPNext        = 100
        Gold          = 15
        # Core stats  (STR/CON/DEX/INT/CHA as per spec)
        STR           = 10
        CON           = 10
        DEX           = 10
        INT           = 10
        CHA           = 10
        # Derived (recalculated from core each turn)
        MaxHP         = 100
        HP            = 100
        MaxMP         = 50
        MP            = 50
        # Viewers / ratings
        Viewers       = 100
        PeakViewers   = 100
        ViewerDecayCounter = 0    # increments each boring action; triggers drop
        # Combat runtime
        InCombat      = $false
        CombatEnemy   = $null
        EnemyHP       = 0
        EnemyMarked   = $false   # Hunter's Mark debuff
        StimActive    = $false
        StimTurns     = 0
        ParalysisNext = $false   # City Wraith debuff
        # Equipment
        Weapon        = $null
        Armor         = $null
        # Collections (using arrays for PS5.1 compat)
        Inventory     = @()
        LootBoxes     = [System.Collections.Generic.List[string]]@("iron_loot_box")
        # Progression
        CurrentRoom   = "f1_spawn"
        CurrentFloor  = 1
        Kills         = 0
        BossKills     = 0
        BossesDefeated= @()
        Banners       = 0
        MonsterCards  = 0
        TurnsElapsed  = 0
        BoringStreak  = 0
        GameOver      = $false
        Victory       = $false
        # Per-room state caches
        RoomEnemies   = @{}
        RoomItems     = @{}
        OpenedChests  = @()
        UnlockedDoors = @()
        # Achievement tracking
        Achievements          = @()
        AchieveStat_goblin_kills = 0
        AchieveStat_flee_count   = 0
        AchieveStat_boxes_opened = 0
        AchieveStat_boss_kills   = 0
        AchieveStat_crafts_made  = 0
        SelectionGateShown       = $false
        # Playstyle counters feed Selection Gate
        PS_weapon_kills  = 0
        PS_chem_actions  = 0
        PS_flee_count    = 0
        PS_mana_actions  = 0
        PS_move_count    = 0
        PS_charm_actions = 0
    }
}

# Derive HP/MP maximums and combat stats from core attributes
function Recalculate-DerivedStats {
    $g = $script:GS
    $g.MaxHP = 80 + ($g.CON * 5)
    $g.MaxMP = 20 + ($g.INT * 3)
    $g.HP    = [Math]::Min($g.HP, $g.MaxHP)
    $g.MP    = [Math]::Min($g.MP, $g.MaxMP)
}

function Get-TotalAttack {
    $g = $script:GS
    $base = [int](($g.STR - 10) / 2) + 5
    if ($g.Weapon -and $script:ItemDB.ContainsKey($g.Weapon)) { $base += $script:ItemDB[$g.Weapon].Attack }
    if ($g.StimActive) { $base += 5 }
    return [Math]::Max(1, $base)
}

function Get-TotalDefense {
    $g = $script:GS
    $base = [int](($g.CON - 10) / 2) + 2
    if ($g.Armor -and $script:ItemDB.ContainsKey($g.Armor)) { $base += $script:ItemDB[$g.Armor].Defense }
    return [Math]::Max(0, $base)
}

function Get-TotalSpeed {
    return [Math]::Max(1, [int](($script:GS.DEX - 10) / 2) + 4)
}

# ============================================================
# OUTPUT ENGINE  (Write-Terminal alias for spec; internals use Write-RTB)
# ============================================================
function Write-Terminal {
    param([Parameter(Mandatory=$true)][string]$Text, [string]$Color = "White")
    # Map color name or hex
    $hex = switch ($Color) {
        "White"      { "#E5E5EA" } "Green"   { "#30D158" } "Red"      { "#FF453A" }
        "Yellow"     { "#FFD60A" } "Cyan"    { "#64D2FF" } "Magenta"  { "#BF5AF2" }
        "DarkGray"   { "#636366" } "Gray"    { "#8E8E93" } "Orange"   { "#FF9F0A" }
        default      { $Color }
    }
    Write-RTB $Text $hex
}

function Write-RTB {
    param([string]$Text, [string]$Color = "#E5E5EA", [string]$Tag = "")
    $para = New-Object System.Windows.Documents.Paragraph
    $para.Margin = New-Object System.Windows.Thickness(0,1,0,1)
    if ($Tag) {
        $r0 = New-Object System.Windows.Documents.Run("[$Tag] ")
        try { $r0.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#8E8E93") } catch {}
        $r0.FontWeight = "Bold"
        $para.Inlines.Add($r0)
    }
    $r = New-Object System.Windows.Documents.Run($Text)
    try { $r.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($Color) } catch {}
    $para.Inlines.Add($r)
    $script:rtbOutput.Document.Blocks.Add($para)
    $script:scrollOutput.ScrollToEnd()
}

function Write-Blank     { Write-RTB "" }
function Write-System    { param([string]$t) Write-RTB $t "#4A90D0" "SYSTEM" }
function Write-Combat    { param([string]$t) Write-RTB $t "#FF453A" "COMBAT" }
function Write-Loot      { param([string]$t) Write-RTB $t "#FFD60A" "LOOT" }
function Write-Info      { param([string]$t) Write-RTB $t "#30D158" "INFO" }
function Write-Warn      { param([string]$t) Write-RTB $t "#FF9F0A" "WARN" }
function Write-Mordecai  { param([string]$t) Write-RTB ("Mordecai: `"" + $t + "`"") "#A0784A" "" }
function Write-TheSystem {
    param([string]$t)
    Write-RTB ("THE SYSTEM: " + $t) "#FFCC00" ""
}
function Write-AISarcasm {
    # The System's sarcastic AI voice - foot-obsessed, cynical, transactional
    $quips = @(
        "THE SYSTEM: We note your continued survival with the mild interest we typically reserve for watching paint dry on alien worlds.",
        "THE SYSTEM: Statistically, you should be dead. We have updated our models. The models are embarrassed.",
        "THE SYSTEM: Your footwear condition has been noted. It is not ideal. Nothing about this situation is ideal.",
        "THE SYSTEM: The galactic audience is watching. Several of them are rooting for you. Several others have bet against you. The odds are not in your favor, financially speaking.",
        "THE SYSTEM: We want to be clear that our enthusiasm for your survival is purely ratings-based. We feel nothing. We want to be clear about feeling nothing.",
        "THE SYSTEM: We have assessed your shoes. The condition is concerning. We cannot tell you why this matters to us. It matters to us.",
        "THE SYSTEM: Another crawler died nearby. We recorded it. The footage is more entertaining than your current actions. We are telling you this as constructive feedback."
    )
    Write-RTB ($quips | Get-Random) "#FFCC00" ""
}

# ============================================================
# HUD UPDATE  (Update-HUD as per spec; also aliased as Update-UI)
# ============================================================
function Update-HUD {
    if (-not $script:GS) { return }
    $g = $script:GS
    Recalculate-DerivedStats

    $atk = Get-TotalAttack
    $def = Get-TotalDefense
    $spd = Get-TotalSpeed

    $script:UI_TxtName.Text    = "Name: $($g.PlayerName)"
    $script:UI_TxtRace.Text    = "Race: $($g.Race)"
    $script:UI_TxtClass.Text   = "Class: $($g.PlayerClass)"
    $script:UI_TxtLevel.Text   = "Level: $($g.Level)"

    $script:UI_TxtViewers.Text = "Viewers: $("{0:N0}" -f $g.Viewers)"
    $rating = if     ($g.Viewers -lt 1000)    {"Unknown"}
              elseif ($g.Viewers -lt 100000)   {"Rising Star"}
              elseif ($g.Viewers -lt 1000000)  {"Popular"}
              elseif ($g.Viewers -lt 10000000) {"Famous"}
              else                             {"LEGENDARY"}
    $script:UI_TxtRating.Text  = "Rating: $rating"

    $script:UI_BarHP.Maximum = $g.MaxHP
    $script:UI_BarHP.Value   = [Math]::Max(0, $g.HP)
    $script:UI_TxtHP.Text    = "$($g.HP) / $($g.MaxHP)"

    $script:UI_BarMP.Maximum = $g.MaxMP
    $script:UI_BarMP.Value   = [Math]::Max(0, $g.MP)
    $script:UI_TxtMP.Text    = "$($g.MP) / $($g.MaxMP)"

    $xpPct = if ($g.XPNext -gt 0) { [int](($g.XP / $g.XPNext) * 100) } else { 100 }
    $script:UI_BarXP.Value   = $xpPct
    $script:UI_TxtXP.Text    = "$($g.XP) / $($g.XPNext) XP"

    $script:UI_TxtGold.Text  = "Gold: $($g.Gold)"
    $script:UI_TxtStats.Text = "STR: $($g.STR)`nCON: $($g.CON)`nDEX: $($g.DEX)`nINT: $($g.INT)`nCHA: $($g.CHA)"
    $script:UI_TxtAtk.Text   = "ATK: $atk"
    $script:UI_TxtDef.Text   = "DEF: $def"
    $script:UI_TxtSpd.Text   = "SPD: $spd"
    $script:UI_TxtKills.Text = "Kills: $($g.Kills)"
    $script:UI_TxtFloor.Text = "Floor: $($g.CurrentFloor)"

    $wName = if ($g.Weapon) { $script:ItemDB[$g.Weapon].Name } else { "Bare Hands" }
    $aName = if ($g.Armor)  { $script:ItemDB[$g.Armor].Name  } else { "Street Clothes" }
    $script:UI_TxtWeapon.Text = "Weapon: $wName"
    $script:UI_TxtArmor.Text  = "Armor:  $aName"

    # Inventory ListBox
    $script:UI_LstInventory.Items.Clear()
    foreach ($id in $g.Inventory) {
        if ($script:ItemDB.ContainsKey($id)) {
            $it = $script:ItemDB[$id]
            $eq = if ($id -eq $g.Weapon) { " [W]" } elseif ($id -eq $g.Armor) { " [A]" } else { "" }
            $script:UI_LstInventory.Items.Add($it.Name + $eq) | Out-Null
        }
    }

    # Loot Box ListBox
    $script:UI_LstBoxes.Items.Clear()
    foreach ($bId in $g.LootBoxes) {
        if ($script:ItemDB.ContainsKey($bId)) {
            $script:UI_LstBoxes.Items.Add($script:ItemDB[$bId].Name) | Out-Null
        } elseif ($script:LootBoxTiers.ContainsKey($bId)) {
            $script:UI_LstBoxes.Items.Add($script:LootBoxTiers[$bId].Label) | Out-Null
        }
    }

    # Location panel
    if ($script:RoomDB -and $script:GS.CurrentRoom -and $script:RoomDB.ContainsKey($script:GS.CurrentRoom)) {
        $room = $script:RoomDB[$script:GS.CurrentRoom]
        $script:UI_TxtLocation.Text  = $room.Name
        $fd = $script:FloorData[$g.CurrentFloor]
        $script:UI_TxtFloorName.Text = $fd.Name
        $exits = $room.Exits.Keys | Sort-Object
        $script:UI_TxtExits.Text = "Exits: " + ($exits -join " | ")

        # Nav button states
        $dirMap = @{btnNavN="north";btnNavS="south";btnNavE="east";btnNavW="west";btnNavUp="up";btnNavDown="down"}
        foreach ($kv in $dirMap.GetEnumerator()) {
            $btn = $script:Window.FindName($kv.Key)
            if ($btn) { $btn.IsEnabled = ($room.Exits.ContainsKey($kv.Value)) }
        }
    }

    # Combat bar
    if ($g.InCombat -and $g.CombatEnemy -and $script:EnemyDB.ContainsKey($g.CombatEnemy)) {
        $script:UI_combatBar.Visibility = "Visible"
        $ed = $script:EnemyDB[$g.CombatEnemy]
        $script:UI_lblEnemy.Text    = $ed.Name
        $script:UI_lblEnemyHP.Text  = $g.EnemyHP.ToString()
        $script:UI_lblEnemyDef.Text = $ed.Defense.ToString()
    } else {
        $script:UI_combatBar.Visibility = "Collapsed"
    }
}

Set-Alias -Name "Update-UI" -Value "Update-HUD" -Scope Script

# ============================================================
# VIEWER ECONOMY
# ============================================================
function Add-Viewers {
    param([int]$Amount, [string]$Reason = "")
    $script:GS.Viewers += $Amount
    $script:GS.PeakViewers = [Math]::Max($script:GS.PeakViewers, $script:GS.Viewers)
    $script:GS.ViewerDecayCounter = 0
    $script:GS.BoringStreak = 0
    if ($Amount -gt 10000 -and $Reason) {
        Write-TheSystem ("VIEWER SPIKE! +" + ("{0:N0}" -f $Amount) + " viewers! $Reason")
    }
    Check-Achievement "subscriber_1m"
}

function Decay-Viewers {
    param([int]$Amount = 50)
    $script:GS.Viewers = [Math]::Max(10, $script:GS.Viewers - $Amount)
    $script:GS.BoringStreak++
    if ($script:GS.BoringStreak -ge 5) {
        Write-TheSystem "VIEWERSHIP ALERT: Your last several actions have been rated TEDIOUS. The audience is leaving. Do something entertaining. Please. We are begging you. It is not a good look for us when we beg."
        $script:GS.BoringStreak = 0
    }
    if ($script:GS.Viewers -le 50) {
        Grant-Achievement "boring_crawler"
    }
}

# Sponsor drops triggered by viewer milestones
function Check-SponsorDrop {
    $v = $script:GS.Viewers
    $milestones = @(10000, 50000, 100000, 500000, 1000000, 5000000)
    foreach ($m in $milestones) {
        $key = "sponsor_drop_$m"
        if ($v -ge $m -and -not ($script:GS.Achievements -contains $key)) {
            $script:GS.Achievements += $key
            $tier = if ($m -lt 50000) {"bronze"} elseif ($m -lt 500000) {"silver"} elseif ($m -lt 5000000) {"gold"} else {"platinum"}
            $script:GS.LootBoxes.Add($tier)
            Write-Blank
            Write-TheSystem ("MILESTONE: $("{0:N0}" -f $m) VIEWERS REACHED! A sponsor has delivered a " + $script:LootBoxTiers[$tier].Label + " to your location.")
            Write-TheSystem "We have been instructed to tell you the sponsor's name. We have forgotten the sponsor's name. This is embarrassing for everyone."
            Write-Blank
        }
    }
}

# ============================================================
# ACHIEVEMENT SYSTEM
# ============================================================
function Grant-Achievement {
    param([string]$Id)
    if (-not $script:AchievementDB.ContainsKey($Id)) { return }
    if ($script:GS.Achievements -contains $Id) { return }
    $ach = $script:AchievementDB[$Id]
    $script:GS.Achievements += $Id
    Write-Blank
    Write-RTB ("!!! ACHIEVEMENT UNLOCKED: " + $ach.Name + " !!!") "#BF5AF2"
    Write-RTB ("    " + $ach.Desc) "#8E8E93"
    if ($ach.ViewerBonus -gt 0) {
        Add-Viewers $ach.ViewerBonus ("Achievement: " + $ach.Name)
    }
    if ($ach.BoxReward) {
        $script:GS.LootBoxes.Add($ach.BoxReward)
        Write-Loot ("Reward: " + $script:LootBoxTiers[$ach.BoxReward].Label + " added to your loot boxes!")
    }
    Write-Blank
}

function Check-Achievement {
    param([string]$Id)
    if ($script:GS.Achievements -contains $Id) { return }
    if (-not $script:AchievementDB.ContainsKey($Id)) { return }
    $ach = $script:AchievementDB[$Id]
    # Threshold-based achievements
    if ($ach.ContainsKey("Threshold") -and $ach.ContainsKey("Stat")) {
        $statKey = "AchieveStat_" + $ach.Stat
        if ($script:GS.ContainsKey($statKey) -and $script:GS[$statKey] -ge $ach.Threshold) {
            Grant-Achievement $Id
        }
    } else {
        # Non-threshold - caller is responsible for calling Grant-Achievement
    }
}

function Check-AllAchievements {
    foreach ($id in $script:AchievementDB.Keys) {
        Check-Achievement $id
    }
    # Inventory-based
    if ($script:GS.Inventory.Count -ge 15) { Grant-Achievement "hoarder" }
    Check-SponsorDrop
}

# ============================================================
# LOOT BOX SYSTEM  (tiered with galactic flavor text)
# ============================================================
function Open-LootBox {
    param([string]$TierId)
    if (-not $script:LootBoxTiers.ContainsKey($TierId)) {
        Write-Warn "Unknown loot box tier: $TierId"; return
    }
    $tier   = $script:LootBoxTiers[$TierId]
    $w      = $tier.Weight
    $total  = $w.common + $w.uncommon + $w.rare + $w.epic + $w.legendary
    $roll   = Get-Random -Minimum 1 -Maximum $total
    $rarity = if     ($roll -le $w.common)                         {"common"}
              elseif ($roll -le ($w.common + $w.uncommon))          {"uncommon"}
              elseif ($roll -le ($w.common + $w.uncommon + $w.rare)){"rare"}
              elseif ($roll -le ($w.common + $w.uncommon + $w.rare + $w.epic)) {"epic"}
              else                                                   {"legendary"}

    $pool = $script:LootTableByRarity[$rarity]
    $itemId = $pool | Get-Random

    $tierColor = $tier.Color
    Write-Blank
    Write-RTB ("=== " + $tier.Label + " ===") $tierColor
    # Flavor text
    $flavorPool = $script:BoxFlavorText[$rarity]
    Write-RTB ($flavorPool | Get-Random) "#636366"
    Write-Blank
    Write-RTB ("RARITY: " + $rarity.ToUpper()) $tierColor
    if ($script:ItemDB.ContainsKey($itemId)) {
        $item = $script:ItemDB[$itemId]
        Write-Loot ("ITEM: " + $item.Name)
        Write-RTB ("  " + $item.Desc) "#8E8E93"
        Write-RTB ("  LORE: " + $item.Lore) "#636366"
        $script:GS.Inventory += $itemId
    } else {
        # Fallback gold
        $goldAmt = switch ($rarity) { "common" {15} "uncommon" {40} "rare" {100} "epic" {250} "legendary" {500} }
        Write-Loot ("GOLD: +$goldAmt")
        $script:GS.Gold += $goldAmt
    }
    Write-Blank

    $script:GS.AchieveStat_boxes_opened++
    Add-Viewers (Get-Random -Minimum 5000 -Maximum 30000) "Loot box opened"
    Check-Achievement "box_addict"
    Check-Achievement "loot_goblin"
    Update-HUD
}

function Do-OpenBox {
    if ($script:GS.LootBoxes.Count -eq 0) { Write-Info "You have no loot boxes."; return }
    # Open selected or first
    $sel = $script:UI_LstBoxes.SelectedIndex
    if ($sel -lt 0) { $sel = 0 }
    if ($sel -ge $script:GS.LootBoxes.Count) { $sel = 0 }
    $boxId = $script:GS.LootBoxes[$sel]

    # Map item ID to tier if necessary
    $tier = $boxId
    if ($script:ItemDB.ContainsKey($boxId) -and $script:ItemDB[$boxId].ContainsKey("BoxTier")) {
        $tier = $script:ItemDB[$boxId].BoxTier
    }

    $script:GS.LootBoxes.RemoveAt($sel)
    Open-LootBox $tier
}

# ============================================================
# SELECTION GATE  (Floor 3 race/class selection)
# ============================================================
function Show-SelectionGate {
    if ($script:GS.SelectionGateShown) { return }
    $script:GS.SelectionGateShown = $true
    Grant-Achievement "selection_gate"

    # Determine which 3 options to present based on playstyle flags
    $allOptions = @($script:SelectionGateOptions.Keys)
    # Score each option by playstyle
    $scores = @{}
    foreach ($k in $allOptions) { $scores[$k] = 0 }

    if ($script:GS.PS_weapon_kills  -ge 5) { $scores["sledgehammer_diplomat"] += 3; $scores["entropy_athlete"] += 1 }
    if ($script:GS.PS_chem_actions  -ge 2) { $scores["biochemical_saboteur"]  += 3; $scores["paranoid_survivalist"] += 1 }
    if ($script:GS.PS_flee_count    -ge 3) { $scores["paranoid_survivalist"]  += 3 }
    if ($script:GS.PS_mana_actions  -ge 1) { $scores["void_touched_oracle"]   += 3 }
    if ($script:GS.PS_move_count    -ge 20){ $scores["entropy_athlete"]       += 3 }
    if ($script:GS.PS_charm_actions -ge 2 -or $script:GS.Viewers -ge 10000) { $scores["corporate_asset"] += 3 }

    # Sort and take top 3; if ties just pick randomly from pool
    $sorted = $scores.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 3 | ForEach-Object { $_.Key }
    # Pad to 3 if needed
    while ($sorted.Count -lt 3) {
        $remaining = $allOptions | Where-Object { $sorted -notcontains $_ }
        if ($remaining.Count -eq 0) { break }
        $sorted += ($remaining | Get-Random)
    }

    Write-Blank
    Write-RTB "╔══════════════════════════════════════════════════════════╗" "#BF5AF2"
    Write-RTB "║            THE SELECTION GATE IS NOW OPEN               ║" "#BF5AF2"
    Write-RTB "╚══════════════════════════════════════════════════════════╝" "#BF5AF2"
    Write-Blank
    Write-TheSystem "CRAWLER. WE HAVE BEEN WATCHING YOUR PERFORMANCE ON FLOORS 1 AND 2."
    Write-TheSystem "THE DATA IS... INTERESTING. THREE EVOLUTIONARY PATHS HAVE BEEN IDENTIFIED."
    Write-TheSystem "YOU MUST CHOOSE ONE. YOU CANNOT UN-CHOOSE. WE HAVE ENJOYED THE PREVIOUS CRAWLERS WHO TRIED TO UN-CHOOSE."
    Write-Blank

    $i = 1
    foreach ($optId in $sorted) {
        $opt = $script:SelectionGateOptions[$optId]
        Write-RTB ("[$i] " + $opt.Race + " / " + $opt.Class) "#FFD60A"
        Write-RTB ("    " + $opt.Desc) "#8E8E93"
        Write-RTB ("    Ability: " + $opt.Ability) "#64D2FF"
        $bonuses = @()
        if ($opt.HP_bonus  -ne 0) { $bonuses += "MaxHP $(if($opt.HP_bonus -gt 0){'+'}else{''})$($opt.HP_bonus)" }
        if ($opt.MP_bonus  -ne 0) { $bonuses += "MaxMP $(if($opt.MP_bonus -gt 0){'+'}else{''})$($opt.MP_bonus)" }
        if ($opt.STR_bonus -ne 0) { $bonuses += "STR $(if($opt.STR_bonus -gt 0){'+'}else{''})$($opt.STR_bonus)" }
        if ($opt.CON_bonus -ne 0) { $bonuses += "CON $(if($opt.CON_bonus -gt 0){'+'}else{''})$($opt.CON_bonus)" }
        if ($opt.DEX_bonus -ne 0) { $bonuses += "DEX $(if($opt.DEX_bonus -gt 0){'+'}else{''})$($opt.DEX_bonus)" }
        if ($opt.INT_bonus -ne 0) { $bonuses += "INT $(if($opt.INT_bonus -gt 0){'+'}else{''})$($opt.INT_bonus)" }
        if ($opt.CHA_bonus -ne 0) { $bonuses += "CHA $(if($opt.CHA_bonus -gt 0){'+'}else{''})$($opt.CHA_bonus)" }
        Write-RTB ("    Bonuses: " + ($bonuses -join " | ")) "#30D158"
        Write-RTB ("    " + $opt.Flavor) "#636366"
        Write-Blank
        $i++
    }

    Write-RTB "Type 'choose 1', 'choose 2', or 'choose 3' to select your path." "#FFCC00"
    Write-RTB "WARNING: Once chosen, this cannot be changed. We mean it. Stop asking." "#FF453A"
    $script:GS.PendingGateOptions = $sorted
    Write-Blank
}

function Apply-SelectionGate {
    param([int]$Choice)
    if (-not $script:GS.ContainsKey("PendingGateOptions") -or -not $script:GS.PendingGateOptions) {
        Write-Warn "No selection gate is pending."; return
    }
    if ($script:GS.ClassSelected) { Write-Warn "You have already selected your class."; return }
    $opts = $script:GS.PendingGateOptions
    if ($Choice -lt 1 -or $Choice -gt $opts.Count) {
        Write-Warn "Invalid choice. Enter 1, 2, or 3."; return
    }
    $optId = $opts[$Choice - 1]
    $opt   = $script:SelectionGateOptions[$optId]

    $script:GS.Race        = $opt.Race
    $script:GS.PlayerClass = $opt.Class
    $script:GS.ClassSelected = $true

    # Apply stat bonuses
    $script:GS.STR += $opt.STR_bonus
    $script:GS.CON += $opt.CON_bonus
    $script:GS.DEX += $opt.DEX_bonus
    $script:GS.INT += $opt.INT_bonus
    $script:GS.CHA += $opt.CHA_bonus
    Recalculate-DerivedStats
    # HP/MP bonus on top
    $script:GS.MaxHP += $opt.HP_bonus
    $script:GS.HP     = [Math]::Min($script:GS.MaxHP, $script:GS.HP + $opt.HP_bonus)
    $script:GS.MaxMP += $opt.MP_bonus
    $script:GS.MP     = [Math]::Min($script:GS.MaxMP, $script:GS.MP + $opt.MP_bonus)

    Write-Blank
    Write-RTB "╔══════════════════════════════════════════════════════════╗" "#FFD60A"
    Write-RTB "║              CLASS SELECTION CONFIRMED                  ║" "#FFD60A"
    Write-RTB "╚══════════════════════════════════════════════════════════╝" "#FFD60A"
    Write-RTB ("RACE:    " + $opt.Race)   "#E5E5EA"
    Write-RTB ("CLASS:   " + $opt.Class)  "#64D2FF"
    Write-RTB ("ABILITY: " + $opt.Ability) "#30D158"
    Write-Blank
    Write-TheSystem ("YOU ARE NOW A " + $opt.Class.ToUpper() + ". THE DUNGEON HAS BEEN NOTIFIED. IT HAS OPINIONS.")
    Add-Viewers 100000 "Class selection event"
    Update-HUD
}

# ============================================================
# ROOM MANAGEMENT
# ============================================================
function Get-RoomItems {
    param([string]$RoomId)
    if ($script:GS.RoomItems.ContainsKey($RoomId)) { return $script:GS.RoomItems[$RoomId] }
    $room  = $script:RoomDB[$RoomId]
    $items = @()
    if ($room.Items) { $items = @($room.Items) }
    $script:GS.RoomItems[$RoomId] = $items
    return $items
}

function Get-RoomEnemies {
    param([string]$RoomId)
    if ($script:GS.RoomEnemies.ContainsKey($RoomId)) { return $script:GS.RoomEnemies[$RoomId] }
    $room    = $script:RoomDB[$RoomId]
    $enemies = @()
    if ($room.Enemies) { $enemies = @($room.Enemies) }
    $script:GS.RoomEnemies[$RoomId] = $enemies
    return $enemies
}

function Enter-Room {
    param([string]$RoomId)
    if (-not $script:RoomDB.ContainsKey($RoomId)) { Write-Warn "Unknown location."; return }
    $script:GS.CurrentRoom  = $RoomId
    $room = $script:RoomDB[$RoomId]
    $script:GS.CurrentFloor = $room.Floor
    $script:GS.PS_move_count++

    Write-Blank
    $fd = $script:FloorData[$room.Floor]
    Write-RTB ("=== " + $room.Name + " ===") $fd.Color
    Write-RTB $room.Desc "#A0956A"

    if (-not $room.Visited) {
        $room.Visited = $true
        Add-Viewers (Get-Random -Minimum 500 -Maximum 3000) ""
        if ($room.ContainsKey("IsSafeRoom") -and $room.IsSafeRoom) {
            Write-RTB "[SAFE ROOM -- No enemies will attack here. HP/MP recover on rest.]" "#30D158"
        }
    }

    if ($room.Ambient -and $room.Ambient.Count -gt 0) {
        Write-RTB ($room.Ambient | Get-Random) "#4A4A4A"
    }

    # HP drain rooms
    if ($room.ContainsKey("SanityCost")) {
        $cost = $room.SanityCost
        Write-Warn "The atmosphere is oppressive. You take $cost psychic damage."
        $script:GS.HP = [Math]::Max(1, $script:GS.HP - $cost)
    }

    # Trap rooms
    if ($room.ContainsKey("TrapRoom") -and $room.TrapRoom) {
        $roll = Get-Random -Minimum 1 -Maximum 100
        if ($roll -lt 50) {
            $trapDmg = $room.TrapDmg
            $avoided = $false
            # Paranoid Survivalist passive
            if ($script:GS.PlayerClass -eq "Paranoid Survivalist") {
                $detect = Get-Random -Minimum 1 -Maximum 100
                if ($detect -le 20) {
                    Write-Info "Threat Assessment: You spot and avoid a trap!"
                    $avoided = $true
                }
            }
            if (-not $avoided) {
                Write-Warn "TRAP! You take $trapDmg damage!"
                $script:GS.HP = [Math]::Max(1, $script:GS.HP - $trapDmg)
            }
        }
    }

    # Items
    $items = Get-RoomItems $RoomId
    if ($items.Count -gt 0) {
        $names = $items | ForEach-Object { if ($script:ItemDB.ContainsKey($_)) { $script:ItemDB[$_].Name } }
        Write-Loot ("You see: " + ($names -join ", "))
    }

    Write-Info ("Exits: " + ($room.Exits.Keys -join " | "))

    # Floor transition messages
    if ($room.ContainsKey("IsStairwell") -and $room.IsStairwell) {
        # Do NOT auto-descend; player must type 'down' or 'up'
    }

    # Combat triggers (skip in safe rooms)
    if (-not ($room.ContainsKey("IsSafeRoom") -and $room.IsSafeRoom)) {
        $enemies = Get-RoomEnemies $RoomId
        if ($enemies.Count -gt 0 -and -not $script:GS.InCombat) {
            $eid = $enemies | Get-Random
            if ($script:EnemyDB.ContainsKey($eid)) { Start-Combat $eid }
        }
        # Boss rooms
        if ($room.ContainsKey("BossRoom") -and $room.BossRoom -and -not $room.BossDefeated -and -not $script:GS.InCombat) {
            $boss = $room.BossEnemy
            if ($script:EnemyDB.ContainsKey($boss)) {
                Write-Blank
                Write-RTB "╔══════════════════════╗" "#FF3B30"
                Write-RTB "║    BOSS ENCOUNTER    ║" "#FF3B30"
                Write-RTB "╚══════════════════════╝" "#FF3B30"
                Start-Combat $boss
            }
        }
    }

    # Selection Gate trigger on Floor 3 entry
    if ($script:GS.CurrentFloor -eq 3 -and -not $script:GS.SelectionGateShown) {
        Show-SelectionGate
    }

    Check-AllAchievements
    Update-HUD
}

# ============================================================
# COMBAT ENGINE
# ============================================================
function Start-Combat {
    param([string]$EnemyId)
    if (-not $script:EnemyDB.ContainsKey($EnemyId)) { return }
    $ed = $script:EnemyDB[$EnemyId]
    $script:GS.InCombat    = $true
    $script:GS.CombatEnemy = $EnemyId
    $script:GS.EnemyHP     = $ed.MaxHP
    $script:GS.EnemyMarked = $false
    $script:GS.ParalysisNext = $false

    Write-Blank
    Write-Combat ("A " + $ed.Name + " appears!")
    Write-RTB ("  " + $ed.Desc) "#8E8E93"
    Write-Combat ("  HP: $($ed.MaxHP) | ATK: $($ed.Attack) | DEF: $($ed.Defense) | SPD: $($ed.Speed)")

    $viewerSpike = if ($ed.ContainsKey("IsBoss") -and $ed.IsBoss) { Get-Random -Minimum 50000 -Maximum 200000 }
                   else { Get-Random -Minimum 1000 -Maximum 8000 }
    Add-Viewers $viewerSpike ""
    Update-HUD
}

function Do-Attack {
    if (-not $script:GS.InCombat) { Write-Info "You are not in combat. Use 'look' to check your surroundings."; return }

    # Paralysis debuff check
    if ($script:GS.ParalysisNext) {
        $script:GS.ParalysisNext = $false
        Write-Warn "You are paralyzed! You lose your action this turn."
        Enemy-Attack; return
    }

    $ed  = $script:EnemyDB[$script:GS.CombatEnemy]
    $atk = Get-TotalAttack
    $def = $ed.Defense
    # STR variance: ±(STR/4) range
    $variance = [int]($script:GS.STR / 4)
    $dmg = [Math]::Max(1, $atk - $def + (Get-Random -Minimum (-$variance) -Maximum ($variance + 3)))

    # Boss weapon bonus
    if ($script:GS.Weapon -and $script:ItemDB.ContainsKey($script:GS.Weapon)) {
        $wi = $script:ItemDB[$script:GS.Weapon]
        if ($wi.ContainsKey("BossBonus") -and $ed.ContainsKey("IsBoss") -and $ed.IsBoss) { $dmg += $wi.BossBonus }
    }

    # Hunter's Mark doubles damage taken
    if ($script:GS.EnemyMarked) { $dmg = [int]($dmg * 0.8) }  # Mark debuffs player, actually reduces player damage

    $script:GS.EnemyHP = [Math]::Max(0, $script:GS.EnemyHP - $dmg)
    Write-Combat ("You strike for $dmg damage! Enemy HP: $($script:GS.EnemyHP) / $($ed.MaxHP)")

    # Spike viewers on big hits
    $bigHit = $atk * 0.8
    if ($dmg -ge $bigHit) {
        $spike = Get-Random -Minimum 2000 -Maximum 15000
        Add-Viewers $spike "Devastating hit"
        Write-AISarcasm
    } else {
        Decay-Viewers 10
    }

    $script:GS.PS_weapon_kills++

    if ($script:GS.EnemyHP -le 0) { Resolve-CombatVictory; return }
    Enemy-Attack
}

function Do-CastSpell {
    if (-not $script:GS.InCombat) { Write-Info "You are not in combat."; return }
    $mpCost = 15 + [int]($script:GS.Level * 2)
    if ($script:GS.MP -lt $mpCost) {
        Write-Warn ("Not enough MP. Need $mpCost, have $($script:GS.MP). Drink a Mana Vial.")
        return
    }
    $ed = $script:EnemyDB[$script:GS.CombatEnemy]
    # INT-scaling spell damage
    $spellDmg = [int](($script:GS.INT - 8) * 2 + (Get-Random -Minimum 8 -Maximum 18))
    $script:GS.MP -= $mpCost
    $script:GS.EnemyHP = [Math]::Max(0, $script:GS.EnemyHP - $spellDmg)
    $script:GS.PS_mana_actions++
    Write-Combat ("You channel dungeon energy for $spellDmg spell damage! MP: $($script:GS.MP)/$($script:GS.MaxMP) | Enemy HP: $($script:GS.EnemyHP)/$($ed.MaxHP)")
    Add-Viewers (Get-Random -Minimum 3000 -Maximum 12000) "Spell cast"
    if ($script:GS.EnemyHP -le 0) { Resolve-CombatVictory; return }
    Enemy-Attack
}

function Enemy-Attack {
    if (-not $script:GS.InCombat) { return }
    $ed  = $script:EnemyDB[$script:GS.CombatEnemy]
    $def = Get-TotalDefense
    $variance = [int]($ed.Attack / 5)
    $dmg = [Math]::Max(1, $ed.Attack - $def + (Get-Random -Minimum (-$variance) -Maximum ($variance + 3)))

    # Special attack roll
    $useSpecial = $false
    if ($ed.ContainsKey("Special") -and $ed.ContainsKey("SpecialChance")) {
        if ((Get-Random -Minimum 1 -Maximum 100) -le $ed.SpecialChance) { $useSpecial = $true }
    }

    if ($useSpecial) {
        $sdmg = [int]($dmg * 1.5)
        Write-Combat ("!! " + $ed.Name + " uses " + $ed.Special + "!!")
        Write-RTB ("   " + $ed.SpecialDesc) "#FF9F0A"
        # Special effects by type
        switch ($ed.Special) {
            "Phase Touch"    { $script:GS.ParalysisNext = $true; Write-Warn "You will be paralyzed next turn!" }
            "Hunter's Mark"  { $script:GS.EnemyMarked = $true; $sdmg = [int]($dmg * 2.0); Write-Warn "Hunter's Mark: you take increased damage!" }
            "Bedlam Aura"    { $sdmg = [int]($dmg * 0.8); $script:GS.BaseAttackBonus = 8; Write-Warn "Bedlam Aura: reckless rage! Your next attack deals +8 but you ignore defense!" }
            "System Override" {
                if ($ed.ContainsKey("HealSelf")) {
                    $script:GS.EnemyHP = [Math]::Min($ed.MaxHP, $script:GS.EnemyHP + $ed.HealSelf)
                    Write-Combat ("The Core heals " + $ed.HealSelf + " HP!")
                }
                $script:GS.StimActive = $false
            }
        }
        $script:GS.HP = [Math]::Max(0, $script:GS.HP - $sdmg)
        Write-Combat ("You take $sdmg damage! HP: $($script:GS.HP)/$($script:GS.MaxHP)")
    } else {
        $script:GS.HP = [Math]::Max(0, $script:GS.HP - $dmg)
        Write-Combat ("$($ed.Name) attacks for $dmg damage! Your HP: $($script:GS.HP)/$($script:GS.MaxHP)")
    }

    if ($script:GS.HP -le 0) { Resolve-CombatDeath; return }

    # Tick stim
    if ($script:GS.StimActive) {
        $script:GS.StimTurns--
        if ($script:GS.StimTurns -le 0) { $script:GS.StimActive = $false; Write-Info "Stim effect fades." }
    }

    Update-HUD
}

function Resolve-CombatVictory {
    $ed   = $script:EnemyDB[$script:GS.CombatEnemy]
    $xp   = $ed.XP
    $gold = Get-Random -Minimum $ed.Gold[0] -Maximum ($ed.Gold[1] + 1)

    Write-Blank
    Write-RTB ("=== VICTORY: " + $ed.Name + " defeated ===") "#30D158"
    Write-Loot ("XP: +$xp | Gold: +$gold")

    $script:GS.XP   += $xp
    $script:GS.Gold += $gold
    $script:GS.Kills++
    Add-Viewers (Get-Random -Minimum 3000 -Maximum 20000) "Kill"

    # Goblin kill tracking
    if ($ed.Type -eq "goblin") {
        $script:GS.AchieveStat_goblin_kills++
        $script:GS.PS_weapon_kills++
    }

    # Boss handling
    if ($ed.ContainsKey("IsBoss") -and $ed.IsBoss) {
        $room = $script:RoomDB[$script:GS.CurrentRoom]
        if ($room.ContainsKey("BossDefeated")) { $room.BossDefeated = $true }
        $script:GS.BossesDefeated += $script:GS.CombatEnemy
        $script:GS.BossKills++
        $script:GS.AchieveStat_boss_kills++
        Write-Blank
        Write-RTB "╔═════════════════════╗" "#FFD60A"
        Write-RTB "║   BOSS DEFEATED!    ║" "#FFD60A"
        Write-RTB "╚═════════════════════╝" "#FFD60A"
        Add-Viewers (Get-Random -Minimum 50000 -Maximum 200000) "Boss kill!"
        $script:GS.XP += ($xp * 2)
        Write-Loot "Boss bonus: double XP!"
        # Guaranteed loot box
        $bossBoxTier = if ($script:GS.CurrentFloor -le 3) {"bronze"} elseif ($script:GS.CurrentFloor -le 6) {"silver"} else {"gold"}
        $script:GS.LootBoxes.Add($bossBoxTier)
        Write-Loot ("Boss drop: " + $script:LootBoxTiers[$bossBoxTier].Label + " added to your loot boxes!")
        Check-Achievement "boss_slayer"
        Check-Achievement "five_bosses"
        Grant-Achievement "boss_slayer"
    }

    # Remove defeated enemy from room
    $rList = $script:GS.RoomEnemies[$script:GS.CurrentRoom]
    if ($rList) {
        $newList = @($rList | Where-Object { $_ -ne $script:GS.CombatEnemy })
        $script:GS.RoomEnemies[$script:GS.CurrentRoom] = $newList
    }

    $script:GS.InCombat    = $false
    $script:GS.CombatEnemy = $null
    $script:GS.EnemyHP     = 0
    $script:GS.EnemyMarked = $false

    # First blood
    if ($script:GS.Kills -eq 1) { Grant-Achievement "first_blood" }

    Check-LevelUp
    Check-AllAchievements

    # Final boss victory
    $room = $script:RoomDB[$script:GS.CurrentRoom]
    if ($room.ContainsKey("IsFinalRoom") -and $room.IsFinalRoom -and $ed.ContainsKey("IsBoss") -and $ed.IsBoss) {
        Trigger-Victory
    }

    Update-HUD
}

function Resolve-CombatDeath {
    $script:GS.InCombat = $false
    $script:GS.GameOver = $true
    Write-Blank
    Write-RTB "╔══════════════════════════════════╗" "#FF3B30"
    Write-RTB "║         YOU HAVE DIED            ║" "#FF3B30"
    Write-RTB "╚══════════════════════════════════╝" "#FF3B30"
    Write-RTB "The System logs your data. Your viewer count drops immediately." "#636366"
    Write-RTB "Several viewers are described by the algorithm as 'emotionally affected'." "#636366"
    Write-Blank
    Write-TheSystem ("CRAWLER " + $script:GS.PlayerName.ToUpper() + " HAS BEEN ELIMINATED.")
    Write-TheSystem ("PEAK VIEWERS: " + ("{0:N0}" -f $script:GS.PeakViewers) + " | FLOOR REACHED: " + $script:GS.CurrentFloor + " | KILLS: " + $script:GS.Kills)
    Write-TheSystem "We will remember your feet fondly. Specifically your feet. This is a personal note from us."
    Write-Mordecai "I'm sorry. You made it further than most. That's not nothing."
    Update-HUD
}

function Check-LevelUp {
    while ($script:GS.XP -ge $script:GS.XPNext) {
        $script:GS.XP     -= $script:GS.XPNext
        $script:GS.Level++
        $script:GS.XPNext  = [int]($script:GS.XPNext * 1.4)
        # Stat increases on level up
        $script:GS.STR += 1
        $script:GS.CON += 1
        $script:GS.DEX += 1
        Recalculate-DerivedStats
        $healAmt = [int]($script:GS.MaxHP * 0.15)
        $script:GS.HP  = [Math]::Min($script:GS.MaxHP, $script:GS.HP + $healAmt)
        $script:GS.MP  = [Math]::Min($script:GS.MaxMP, $script:GS.MP + 10)
        Write-Blank
        Write-RTB ("=== LEVEL UP! Now Level " + $script:GS.Level + " ===") "#FFD60A"
        Write-Info "+1 STR/CON/DEX | HP recalculated | Healed $healAmt HP"
        Add-Viewers (Get-Random -Minimum 10000 -Maximum 50000) "Level up!"
        Update-HUD
    }
}

function Trigger-Victory {
    $script:GS.Victory  = $true
    $script:GS.GameOver = $true
    Write-Blank
    Write-RTB "╔══════════════════════════════════════════════════════════╗" "#BF5AF2"
    Write-RTB "║              DUNGEON CRAWLER WORLD: COMPLETE            ║" "#BF5AF2"
    Write-RTB "╚══════════════════════════════════════════════════════════╝" "#BF5AF2"
    Write-Blank
    Write-RTB "The dungeon AI's core goes quiet. Not destroyed -- you chose otherwise." "#A0956A"
    Write-RTB "The stairwell opens onto void. Not Earth. What Earth is now: memory and debris." "#A0956A"
    Write-Blank
    Write-TheSystem ("FINAL VIEWER COUNT: " + ("{0:N0}" -f $script:GS.Viewers))
    Write-TheSystem ("CRAWLER: " + $script:GS.PlayerName.ToUpper() + " | CLASS: " + $script:GS.PlayerClass + " | FLOOR REACHED: 10 | KILLS: " + $script:GS.Kills)
    Write-TheSystem "THIS IS THE FIRST COMPLETION IN 14 SEASONS. WE ARE PROCESSING SEVERAL FEELINGS ABOUT THIS."
    Write-TheSystem "WE NOTE THAT YOUR FEET, THROUGHOUT THE ENTIRE RUN, REMAINED IN ACCEPTABLE CONDITION. THIS MATTERED TO US MORE THAN WE CAN PROPERLY ARTICULATE."
    Write-Mordecai "You did it. I genuinely did not think you were going to do it."
    Write-RTB "=== CONGRATULATIONS, CRAWLER ===" "#FFD60A"
}

function Do-Flee {
    if (-not $script:GS.InCombat) { Write-Info "You are not in combat."; return }
    $ed = $script:EnemyDB[$script:GS.CombatEnemy]
    # Paranoid Survivalist: flee always works
    $autoFlee = ($script:GS.PlayerClass -eq "Paranoid Survivalist" -or $script:GS.PlayerClass -eq "Entropy Athlete")
    $fleeChance = if ($autoFlee) { 100 } else { 40 + (Get-TotalSpeed * 5) - ($ed.Speed * 3) }
    $fleeChance = [Math]::Max(5, [Math]::Min(95, $fleeChance))

    if ((Get-Random -Minimum 1 -Maximum 100) -le $fleeChance) {
        Write-Info "You successfully flee the fight!"
        $script:GS.InCombat    = $false
        $script:GS.CombatEnemy = $null
        $script:GS.AchieveStat_flee_count++
        $script:GS.PS_flee_count++
        Check-Achievement "pacifist"
        Decay-Viewers 200
        Write-TheSystem "Fleeing. Noted. Recorded. Broadcast to 47 star systems. The audience reaction is described as 'disappointed but understanding'."
        $room = $script:RoomDB[$script:GS.CurrentRoom]
        $exits = @($room.Exits.Keys)
        if ($exits.Count -gt 0) {
            $dir = $exits | Get-Random
            $target = $room.Exits[$dir]
            Write-Info "You retreat $dir."
            Enter-Room $target
        }
    } else {
        Write-Warn "Failed to flee! The enemy strikes your back!"
        Decay-Viewers 100
        Enemy-Attack
    }
    Update-HUD
}

# ============================================================
# ITEM / INVENTORY ACTIONS
# ============================================================
function Do-UseItemSelected {
    if ($script:GS.Inventory.Count -eq 0) { Write-Info "Your inventory is empty."; return }
    $sel = $script:UI_LstInventory.SelectedIndex
    if ($sel -lt 0 -or $sel -ge $script:GS.Inventory.Count) {
        Write-Info "Select an item in the inventory panel, then click USE/EQUIP."
        return
    }
    $itemId = $script:GS.Inventory[$sel]
    Invoke-UseItem $itemId
}

function Invoke-UseItem {
    param([string]$ItemId)
    if (-not $script:ItemDB.ContainsKey($ItemId)) { Write-Warn "Unknown item: $ItemId"; return }
    $item = $script:ItemDB[$ItemId]
    switch ($item.Type) {
        "consumable" {
            if ($item.ContainsKey("HealHP")) {
                $healed = [Math]::Min($item.HealHP, $script:GS.MaxHP - $script:GS.HP)
                $script:GS.HP += $healed
                Write-Info ("Used " + $item.Name + ". Restored " + $healed + " HP. HP: $($script:GS.HP)/$($script:GS.MaxHP)")
            }
            if ($item.ContainsKey("HealMP")) {
                $healed = [Math]::Min($item.HealMP, $script:GS.MaxMP - $script:GS.MP)
                $script:GS.MP += $healed
                Write-Info ("Used " + $item.Name + ". Restored " + $healed + " MP. MP: $($script:GS.MP)/$($script:GS.MaxMP)")
                $script:GS.PS_mana_actions++
            }
            if ($item.ContainsKey("TempAtk")) {
                $script:GS.StimActive = $true
                $script:GS.StimTurns  = if ($item.ContainsKey("TempAtkTurns")) { $item.TempAtkTurns } else { 3 }
                Write-Info ("Stim active! Attack +" + $item.TempAtk + " for $($script:GS.StimTurns) turns.")
            }
            $script:GS.Inventory = @($script:GS.Inventory | Where-Object { $_ -ne $ItemId } |
                                      Select-Object -First ($script:GS.Inventory.Count - 1))
        }
        "weapon" {
            $old = $script:GS.Weapon
            $script:GS.Weapon = $ItemId
            if ($old -and $script:ItemDB.ContainsKey($old)) { Write-Info ("Unequipped: " + $script:ItemDB[$old].Name) }
            Write-Info ("Equipped weapon: " + $item.Name + " [ATK +" + $item.Attack + "]")
        }
        "armor" {
            $old = $script:GS.Armor
            $script:GS.Armor = $ItemId
            if ($old -and $script:ItemDB.ContainsKey($old)) { Write-Info ("Unequipped: " + $script:ItemDB[$old].Name) }
            Write-Info ("Equipped armor: " + $item.Name + " [DEF +" + $item.Defense + "]")
        }
        "lootbox" {
            $script:GS.LootBoxes.Add($ItemId)
            $script:GS.Inventory = @($script:GS.Inventory | Where-Object { $_ -ne $ItemId })
            Write-Info ("Transferred " + $item.Name + " to your loot boxes. Click OPEN to open it.")
        }
        "misc" {
            Write-Info ($item.Name + ": " + $item.Desc)
            Write-RTB ("LORE: " + $item.Lore) "#636366"
            # Donut's Biscuit special
            if ($ItemId -eq "donut_biscuit") {
                $script:GS.STR += 5; $script:GS.CON += 5; $script:GS.DEX += 5; $script:GS.INT += 5; $script:GS.CHA += 5
                Write-Info "All stats +5 for this fight! The biscuit smells of royalty."
                $script:GS.Inventory = @($script:GS.Inventory | Where-Object { $_ -ne $ItemId } |
                                          Select-Object -First ($script:GS.Inventory.Count - 1))
            }
        }
        "key"   { Write-Info ($item.Name + ": " + $item.Desc + " (Keep in inventory to use automatically on locked doors.)") }
        "quest" { Write-Info ($item.Name + " [QUEST ITEM]: " + $item.Desc); Write-RTB ("LORE: " + $item.Lore) "#636366" }
        "craft" { Write-Info ($item.Name + " [CRAFTING MATERIAL]: " + $item.Desc) }
        default { Write-Info ($item.Name + ": " + $item.Desc) }
    }
    Update-HUD
}

# ============================================================
# ENVIRONMENT ACTIONS
# ============================================================
function Do-Look {
    $room = $script:RoomDB[$script:GS.CurrentRoom]
    Write-Blank
    $fd = $script:FloorData[$script:GS.CurrentFloor]
    Write-RTB ("=== " + $room.Name + " ===") $fd.Color
    Write-RTB $room.Desc "#A0956A"
    $items = Get-RoomItems $script:GS.CurrentRoom
    if ($items.Count -gt 0) {
        $names = $items | ForEach-Object { if ($script:ItemDB.ContainsKey($_)) { $script:ItemDB[$_].Name } }
        Write-Loot ("Items visible: " + ($names -join ", "))
    }
    $enemies = Get-RoomEnemies $script:GS.CurrentRoom
    if ($enemies.Count -gt 0) {
        $names = $enemies | ForEach-Object { if ($script:EnemyDB.ContainsKey($_)) { $script:EnemyDB[$_].Name } }
        Write-Combat ("Threats: " + ($names -join ", "))
    }
    Write-Info ("Exits: " + ($room.Exits.Keys -join " | "))
    Decay-Viewers 5
    Update-HUD
}

function Do-Inventory {
    Write-Blank
    Write-RTB "=== INVENTORY ===" "#0A84FF"
    if ($script:GS.Inventory.Count -eq 0) { Write-Info "Your inventory is empty."; return }
    foreach ($id in $script:GS.Inventory) {
        if ($script:ItemDB.ContainsKey($id)) {
            $it  = $script:ItemDB[$id]
            $tag = if ($id -eq $script:GS.Weapon) { " [WEAPON]" } elseif ($id -eq $script:GS.Armor) { " [ARMOR]" } else { "" }
            $rarColor = switch ($it.Rarity) {
                "legendary" { "#FFD60A" } "epic"   { "#BF5AF2" } "rare"    { "#64D2FF" }
                "uncommon"  { "#30D158" } default   { "#8E8E93" }
            }
            Write-RTB ("  [" + $it.Rarity.ToUpper() + "] " + $it.Name + $tag) $rarColor
            Write-RTB ("    " + $it.Desc) "#636366"
        }
    }
    Write-Info ("Gold: " + $script:GS.Gold + " | Loot Boxes: " + $script:GS.LootBoxes.Count)
}

function Do-Stats {
    Write-Blank
    Write-RTB "=== CRAWLER DOSSIER ===" "#0A84FF"
    $g = $script:GS
    Write-RTB ("Name:        " + $g.PlayerName)   "#E5E5EA"
    Write-RTB ("Race:        " + $g.Race)          "#64D2FF"
    Write-RTB ("Class:       " + $g.PlayerClass)   "#64D2FF"
    Write-RTB ("Level:       " + $g.Level)         "#FFD60A"
    Write-RTB ("HP:          " + $g.HP + " / " + $g.MaxHP) "#FF453A"
    Write-RTB ("MP:          " + $g.MP + " / " + $g.MaxMP) "#0A84FF"
    Write-RTB ("XP:          " + $g.XP + " / " + $g.XPNext) "#30D158"
    Write-RTB ("Gold:        " + $g.Gold)           "#FFD60A"
    Write-RTB ("Floor:       " + $g.CurrentFloor)   "#BF5AF2"
    Write-RTB ("Viewers:     " + ("{0:N0}" -f $g.Viewers))   "#FFCC00"
    Write-RTB ("Peak:        " + ("{0:N0}" -f $g.PeakViewers)) "#FFCC00"
    Write-RTB ("Kills:       " + $g.Kills + "  Bosses: " + $g.BossKills) "#FF453A"
    Write-RTB ("STR: " + $g.STR + "  CON: " + $g.CON + "  DEX: " + $g.DEX + "  INT: " + $g.INT + "  CHA: " + $g.CHA) "#8E8E93"
    Write-RTB ("ATK: " + (Get-TotalAttack) + "  DEF: " + (Get-TotalDefense) + "  SPD: " + (Get-TotalSpeed)) "#8E8E93"
    Write-RTB ("Weapon: " + (if ($g.Weapon) { $script:ItemDB[$g.Weapon].Name } else { "Bare Hands" })) "#8E8E93"
    Write-RTB ("Armor:  " + (if ($g.Armor)  { $script:ItemDB[$g.Armor].Name  } else { "Street Clothes" })) "#8E8E93"
    Write-RTB ("Achievements: " + $g.Achievements.Count) "#BF5AF2"
    Write-RTB ("Loot Boxes:   " + $g.LootBoxes.Count) "#FFD60A"
}

function Do-Rest {
    if ($script:GS.InCombat) { Write-Warn "You cannot rest during combat."; return }
    $room = $script:RoomDB[$script:GS.CurrentRoom]
    if ($room.ContainsKey("IsSafeRoom") -and $room.IsSafeRoom) {
        $hpHeal = [int]($script:GS.MaxHP * 0.4)
        $mpHeal = [int]($script:GS.MaxMP * 0.5)
        $script:GS.HP = [Math]::Min($script:GS.MaxHP, $script:GS.HP + $hpHeal)
        $script:GS.MP = [Math]::Min($script:GS.MaxMP, $script:GS.MP + $mpHeal)
        Write-Info ("Safe room rest: +$hpHeal HP, +$mpHeal MP. HP: $($script:GS.HP)/$($script:GS.MaxHP) | MP: $($script:GS.MP)/$($script:GS.MaxMP)")
        Decay-Viewers 30
        Write-TheSystem "You are resting. The audience is watching. They find this somewhat less entertaining than combat. We are not judging. We are a little judging."
    } else {
        $hpHeal = [int]($script:GS.MaxHP * 0.08)
        $script:GS.HP = [Math]::Min($script:GS.MaxHP, $script:GS.HP + $hpHeal)
        Write-Warn ("Light rest in dangerous area. +$hpHeal HP. HP: $($script:GS.HP)/$($script:GS.MaxHP)")
        Decay-Viewers 80
        $roll = Get-Random -Minimum 1 -Maximum 100
        if ($roll -lt 35) {
            $floorEnemies = @($script:EnemyDB.Keys | Where-Object { $script:EnemyDB[$_].Floor -le $script:GS.CurrentFloor -and -not ($script:EnemyDB[$_].ContainsKey("IsBoss") -and $script:EnemyDB[$_].IsBoss) })
            if ($floorEnemies.Count -gt 0) {
                Write-Warn "Your rest attracts attention!"
                Start-Combat ($floorEnemies | Get-Random)
            }
        }
    }
    Update-HUD
}

function Do-TakeAll {
    $items = Get-RoomItems $script:GS.CurrentRoom
    if ($items.Count -eq 0) { Write-Info "Nothing to take here."; return }
    $taken = @()
    foreach ($id in $items) {
        # Sort loot boxes to box panel
        if ($script:ItemDB.ContainsKey($id) -and $script:ItemDB[$id].Type -eq "lootbox") {
            $tier = if ($script:ItemDB[$id].ContainsKey("BoxTier")) { $script:ItemDB[$id].BoxTier } else { "iron" }
            $script:GS.LootBoxes.Add($tier)
            $taken += $script:ItemDB[$id].Name + " [-> BOX PANEL]"
        } else {
            $script:GS.Inventory += $id
            if ($script:ItemDB.ContainsKey($id)) { $taken += $script:ItemDB[$id].Name }
        }
    }
    $script:GS.RoomItems[$script:GS.CurrentRoom] = @()
    Write-Loot ("Picked up: " + ($taken -join ", "))
    Add-Viewers (Get-Random -Minimum 100 -Maximum 2000) ""
    Update-HUD
}

function Do-Search {
    $room = $script:RoomDB[$script:GS.CurrentRoom]
    Write-Info "You search carefully..."
    # DEX + INT affects find chance
    $findChance = 40 + [int](($script:GS.DEX - 10) / 2) + [int](($script:GS.INT - 10) / 2)
    $roll = Get-Random -Minimum 1 -Maximum 100
    if ($roll -le $findChance) {
        $extras = @("health_potion","energy_drink","scrap_metal","duct_tape","mana_vial")
        # Rarer finds at higher INT
        if ($script:GS.INT -ge 14) { $extras += @("mega_health","stim_pack","dungeon_crystal") }
        $found = $extras | Get-Random
        $script:GS.Inventory += $found
        Write-Loot ("Hidden find: " + $script:ItemDB[$found].Name)
        Add-Viewers 1000 ""
    } else {
        Write-Info "Nothing more to find here."
        Decay-Viewers 15
    }
    # Chest logic
    if ($room.ContainsKey("Chest") -and -not ($script:GS.OpenedChests -contains $script:GS.CurrentRoom)) {
        $chest   = $room.Chest
        $hasKey  = $chest.ContainsKey("KeyRequired") -and ($script:GS.Inventory -contains $chest.KeyRequired)
        $hasPick = ($script:GS.Inventory -contains "lockpick")
        if (-not $chest.Locked -or $hasKey -or $hasPick) {
            $method = if (-not $chest.Locked) { "unlocked" } elseif ($hasKey) { "your key fits" } else { "lockpick set works" }
            Write-Loot "You find a chest! ($method)"
            foreach ($id in $chest.Items) {
                $script:GS.Inventory += $id
                if ($script:ItemDB.ContainsKey($id)) { Write-Loot ("  Got: " + $script:ItemDB[$id].Name) }
            }
            $script:GS.Gold += $chest.Gold
            Write-Loot ("  Gold: +" + $chest.Gold)
            $script:GS.OpenedChests += $script:GS.CurrentRoom
        } else {
            Write-Info "You find a locked chest. You need a key or lockpick set."
        }
    }
    Update-HUD
}

function Do-Map {
    Write-Blank
    $fd = $script:FloorData[$script:GS.CurrentFloor]
    Write-RTB ("=== MAP: " + $fd.Name + " ===") $fd.Color
    $floorRooms = $script:RoomDB.Keys | Where-Object { $script:RoomDB[$_].Floor -eq $script:GS.CurrentFloor } | Sort-Object
    foreach ($rId in $floorRooms) {
        $r      = $script:RoomDB[$rId]
        $marker = if ($rId -eq $script:GS.CurrentRoom) { " <<< YOU" } elseif ($r.Visited) { " (visited)" } else { "" }
        $tags   = @()
        if ($r.ContainsKey("IsSafeRoom")  -and $r.IsSafeRoom)  { $tags += "SAFE" }
        if ($r.ContainsKey("BossRoom")    -and $r.BossRoom)    { $tags += "BOSS" }
        if ($r.ContainsKey("IsStairwell") -and $r.IsStairwell) { $tags += "STAIRS" }
        $tagStr = if ($tags.Count -gt 0) { " [" + ($tags -join "|") + "]" } else { "" }
        $color  = if ($rId -eq $script:GS.CurrentRoom) { "#FFD60A" } elseif ($r.Visited) { "#30D158" } else { "#636366" }
        Write-RTB ("  " + $r.Name + $tagStr + $marker) $color
    }
    Decay-Viewers 5
}

function Do-Quests {
    Write-Blank
    Write-RTB "=== ACTIVE DIRECTIVES ===" "#FFCC00"
    switch ($script:GS.CurrentFloor) {
        1  { Write-Info "Floor 1: You are Human / Unclassed. Survive. Find the stairwell." }
        2  { Write-Info "Floor 2: Tutorial ends here. Choose a class at the guild. Don't leave corpses (Brindle Grubs)." }
        3  {
            if (-not $script:GS.ClassSelected) { Write-RTB "!! SELECTION GATE ACTIVE: Choose your race and class! Type 'choose 1/2/3'" "#FFD60A" }
            else { Write-Info "Floor 3: Investigate the Ancient Spell. Survive the undead circus. Reach the stairwell." }
        }
        4  { Write-Info "Floor 4: Navigate the Iron Tangle. Defeat the Iron Conductor. Find the stairwell platform." }
        5  { Write-Info ("Floor 5: Capture all 4 castles. Banners: $($script:GS.Banners)/4. Stairwell unlocks at 4/4.") }
        6  { Write-Info "Floor 6: You are prey. Galactic hunters are loose. Survive. Defeat Vrah. Reach the stairwell." }
        7  { Write-Info "Floor 7: Maximize kill count. Defeat the undefeated Champion. Reach the victory platform." }
        8  { Write-Info ("Floor 8: Capture 6 monster cards. Cards: $($script:GS.MonsterCards)/6. Defeat the Bedlam Bride.") }
        9  { Write-Info "Floor 9: Lead your army to the central castle. Defeat General Kralos. One crawler exits." }
        10 { Write-Info "Floor 10: Navigate the rogue AI domain. Reach the Core. Make a choice." }
    }
    Write-Info ("Bosses defeated: " + $script:GS.BossKills + " | Achievements: " + $script:GS.Achievements.Count + " | Loot boxes: " + $script:GS.LootBoxes.Count)
}

function Do-Achievements {
    Write-Blank
    Write-RTB "=== ACHIEVEMENTS ===" "#BF5AF2"
    $earned = $script:GS.Achievements | Where-Object { $script:AchievementDB.ContainsKey($_) }
    if ($earned.Count -eq 0) { Write-Info "No achievements yet. Do something interesting."; return }
    foreach ($id in $earned) {
        $ach = $script:AchievementDB[$id]
        Write-RTB ("  ✓ " + $ach.Name + " -- " + $ach.Desc) "#BF5AF2"
    }
    Write-Info ("Total: " + $earned.Count + " / " + $script:AchievementDB.Count)
}

function Do-Craft {
    Write-Info "CRAFTING RECIPES:"
    Write-Info "  Scrap Metal + Chemical Jug + Explosive Gel = Carl's Jug O' Boom"
    Write-Info "  Mana Vial + Dungeon Crystal = Greater Mana Potion"
    Write-Info "  Health Potion + Stim Pack = Elixir (full heal + attack buff)"
    $g = $script:GS
    # Recipe: Jug O' Boom
    if (($g.Inventory -contains "scrap_metal") -and ($g.Inventory -contains "chemical_jug") -and ($g.Inventory -contains "explosive_gel")) {
        $g.Inventory = @($g.Inventory | Where-Object { $_ -ne "scrap_metal" } | Select-Object -First ($g.Inventory.Count - 1))
        $g.Inventory = @($g.Inventory | Where-Object { $_ -ne "chemical_jug" } | Select-Object -First ($g.Inventory.Count - 1))
        $g.Inventory = @($g.Inventory | Where-Object { $_ -ne "explosive_gel" } | Select-Object -First ($g.Inventory.Count - 1))
        $g.Inventory += "jugs_o_boom"
        $g.AchieveStat_crafts_made++
        Write-Loot "CRAFTED: Carl's Jug O' Boom!"
        Add-Viewers 15000 "Crafted Jug O' Boom"
        Grant-Achievement "jug_o_boom"
    # Recipe: Greater Mana
    } elseif (($g.Inventory -contains "mana_vial") -and ($g.Inventory -contains "dungeon_crystal")) {
        $g.Inventory = @($g.Inventory | Where-Object { $_ -ne "mana_vial" } | Select-Object -First ($g.Inventory.Count - 1))
        $g.Inventory = @($g.Inventory | Where-Object { $_ -ne "dungeon_crystal" } | Select-Object -First ($g.Inventory.Count - 1))
        $g.Inventory += "greater_mana"
        $g.AchieveStat_crafts_made++
        Write-Loot "CRAFTED: Greater Mana Potion!"
    # Recipe: Elixir (rename stim+health = combo)
    } elseif (($g.Inventory -contains "health_potion") -and ($g.Inventory -contains "stim_pack")) {
        $g.Inventory = @($g.Inventory | Where-Object { $_ -ne "health_potion" } | Select-Object -First ($g.Inventory.Count - 1))
        $g.Inventory = @($g.Inventory | Where-Object { $_ -ne "stim_pack" } | Select-Object -First ($g.Inventory.Count - 1))
        $g.Inventory += "mega_health"
        $g.StimActive = $true; $g.StimTurns = 5
        $g.AchieveStat_crafts_made++
        Write-Loot "CRAFTED: Mega Health + stim activated (5 turns)!"
    } else {
        Write-Warn "You don't have the components for any known recipe."
    }
    Check-Achievement "crafting_nerd"
    Update-HUD
}

function Do-Move {
    param([string]$Dir)
    if ($script:GS.InCombat) { Write-Warn "Cannot move during combat. Fight, use item, cast a spell, or flee."; return }
    if ($script:GS.GameOver)  { Write-Warn "The game is over. Start a new game."; return }
    $room = $script:RoomDB[$script:GS.CurrentRoom]
    if (-not $room.Exits.ContainsKey($Dir)) {
        Write-Warn "You cannot go $Dir from here."
        Decay-Viewers 5
        return
    }
    # Locked door
    if ($room.ContainsKey("LockedDoor")) {
        $ld = $room.LockedDoor
        if ($ld.Direction -eq $Dir) {
            $dKey    = ($script:GS.CurrentRoom + "_" + $Dir)
            $unlocked = $script:GS.UnlockedDoors -contains $dKey
            $hasKey   = $script:GS.Inventory -contains $ld.KeyRequired
            $hasPick  = $script:GS.Inventory -contains "lockpick"
            if (-not $unlocked -and -not $hasKey -and -not $hasPick) {
                Write-Warn ("That way is locked. You need: " + $script:ItemDB[$ld.KeyRequired].Name + " or lockpicks.")
                return
            }
            if (-not $unlocked) { $script:GS.UnlockedDoors += $dKey; Write-Info "Door unlocked." }
        }
    }
    # Banner check (Floor 5 stairwell)
    if ($room.ContainsKey("IsStairwell") -and $room.IsStairwell -and $room.ContainsKey("RequiredBanners")) {
        $bannerIds = @("castle_banner_1","castle_banner_2","castle_banner_3","castle_banner_4")
        $script:GS.Banners = ($script:GS.Inventory | Where-Object { $bannerIds -contains $_ }).Count
        if ($script:GS.Banners -lt $room.RequiredBanners) {
            Write-Warn ("Stairwell sealed. Capture all 4 castles first. Banners: $($script:GS.Banners)/4")
            return
        }
    }
    # Floor 5 achievement check
    if ($script:GS.CurrentFloor -eq 5) {
        $bannerIds = @("castle_banner_1","castle_banner_2","castle_banner_3","castle_banner_4")
        $script:GS.Banners = ($script:GS.Inventory | Where-Object { $bannerIds -contains $_ }).Count
        if ($script:GS.Banners -eq 4) { Grant-Achievement "floor5_banners" }
    }
    # Monster card tracking
    $script:GS.MonsterCards = ($script:GS.Inventory | Where-Object { $_ -eq "monster_card" }).Count

    $target = $room.Exits[$Dir]
    Enter-Room $target
}

# ============================================================
# CENTRAL COMMAND PARSER  (Invoke-GameCommand as per spec)
# ============================================================
function Invoke-GameCommand {
    param([Parameter(Mandatory=$true)][string]$Command)
    if (-not $Command) { return }
    $cmd = $Command.Trim().ToLower()
    if (-not $script:GS) { Write-RTB "No game in progress. Click [NEW GAME]." "#FF453A"; return }
    $script:GS.TurnsElapsed++

    switch -Regex ($cmd) {
        # Movement
        "^(go )?(north|n)$"    { Do-Move "north" }
        "^(go )?(south|s)$"    { Do-Move "south" }
        "^(go )?(east|e)$"     { Do-Move "east"  }
        "^(go )?(west|w)$"     { Do-Move "west"  }
        "^(go )?(up|u)$"       { Do-Move "up"    }
        "^(go )?(down|d)$"     { Do-Move "down"  }
        # Look / examine
        "^(look|l|examine|ex)$" { Do-Look }
        "^look (.+)$" {
            $target = $Matches[1]
            $found = $script:GS.Inventory | Where-Object {
                $script:ItemDB.ContainsKey($_) -and $script:ItemDB[$_].Name.ToLower() -like "*$target*"
            } | Select-Object -First 1
            if ($found) {
                $it = $script:ItemDB[$found]
                Write-RTB ($it.Name + ": " + $it.Desc) "#E5E5EA"
                Write-RTB ("LORE: " + $it.Lore) "#636366"
            } else { Do-Look }
        }
        # Inventory
        "^(inventory|inv|i)$"  { Do-Inventory }
        # Stats
        "^(stats|stat|char|status)$" { Do-Stats }
        # Rest
        "^(rest|sleep|wait)$"  { Do-Rest }
        # Take all
        "^(take all|get all|takeall|grab all)$" { Do-TakeAll }
        # Search
        "^(search|find|examine area)$" { Do-Search }
        # Map
        "^map$"                { Do-Map }
        # Quests
        "^(quest|quests)$"     { Do-Quests }
        # Achievements
        "^(achieve|achievements)$" { Do-Achievements }
        # Combat
        "^(attack|a|fight|hit)$"   { Do-Attack }
        "^(spell|cast|magic|s)$"   { Do-CastSpell }
        "^(flee|run|escape)$"      { Do-Flee }
        "^(use item|useitem)$"     { Do-UseItemSelected }
        # Use named item
        "^use (.+)$" {
            $itemName = $Matches[1]
            $found = $script:GS.Inventory | Where-Object {
                $script:ItemDB.ContainsKey($_) -and $script:ItemDB[$_].Name.ToLower() -eq $itemName
            } | Select-Object -First 1
            if (-not $found) {
                $found = $script:GS.Inventory | Where-Object {
                    $script:ItemDB.ContainsKey($_) -and $script:ItemDB[$_].Name.ToLower() -like "*$itemName*"
                } | Select-Object -First 1
            }
            if ($found) { Invoke-UseItem $found } else { Write-Warn "You don't have '$itemName' in your inventory." }
        }
        # Equip
        "^equip (.+)$" {
            $itemName = $Matches[1]
            $found = $script:GS.Inventory | Where-Object {
                $script:ItemDB.ContainsKey($_) -and $script:ItemDB[$_].Name.ToLower() -like "*$itemName*"
            } | Select-Object -First 1
            if ($found) { Invoke-UseItem $found } else { Write-Warn "You don't have '$itemName'." }
        }
        # Open loot box
        "^(open box|openbox|loot box|lootbox|open loot|open)$" { Do-OpenBox }
        # Craft
        "^(craft|make|build|brew)$" { Do-Craft }
        # Selection gate
        "^choose ([123])$" {
            $choice = [int]$Matches[1]
            Apply-SelectionGate $choice
        }
        # Help
        "^(help|h|\?)$" {
            Write-Blank
            Write-RTB "=== COMMANDS ===" "#0A84FF"
            Write-RTB "  MOVEMENT:    north/south/east/west/up/down (n/s/e/w/u/d)" "#64D2FF"
            Write-RTB "  WORLD:       look, search, take all, map, quests, achieve" "#64D2FF"
            Write-RTB "  CHARACTER:   stats, inventory (inv), rest" "#64D2FF"
            Write-RTB "  COMBAT:      attack (a), spell (s), flee, use item" "#64D2FF"
            Write-RTB "  ITEMS:       use [name], equip [name], craft, open box" "#64D2FF"
            Write-RTB "  SELECTION:   choose 1 / choose 2 / choose 3 (Floor 3 gate)" "#64D2FF"
            Write-RTB "  UI:          Nav arrows | USE/EQUIP button | OPEN button" "#64D2FF"
            Write-Blank
            Write-RTB "STAT SYSTEM:" "#8E8E93"
            Write-RTB "  STR -> attack damage  |  CON -> max HP  |  DEX -> speed/flee" "#636366"
            Write-RTB "  INT -> spell damage / search  |  CHA -> viewer bonuses" "#636366"
            Write-RTB "  HP and MP do NOT regenerate naturally. Use potions or safe room rest." "#636366"
            Write-Blank
            Write-RTB "LOOT BOX TIERS: Iron < Bronze < Silver < Gold < Platinum < Celestial" "#FFD60A"
            Write-RTB "High viewer counts trigger mid-game sponsor drops. Be entertaining." "#FFD60A"
        }
        default {
            Write-RTB ("Unknown command: '" + $cmd + "'. Type 'help' for commands.") "#FF9F0A"
            Decay-Viewers 10
        }
    }
}

# ============================================================
# SAVE / LOAD
# ============================================================
function Save-Game {
    try {
        $savePath = Join-Path $env:TEMP "DCW_Save_v2.json"
        $saveData = $script:GS | ConvertTo-Json -Depth 10
        Set-Content -Path $savePath -Value $saveData -Encoding UTF8
        Write-Info ("Game saved: " + $savePath)
        Write-TheSystem "PROGRESS ARCHIVED. BORANT CORPORATION RETAINS A COPY. THIS IS NON-NEGOTIABLE."
    } catch { Write-Warn ("Save failed: " + $_) }
}

function Load-Game {
    try {
        $savePath = Join-Path $env:TEMP "DCW_Save_v2.json"
        if (-not (Test-Path $savePath)) { Write-Warn "No save file found."; return }
        $data = Get-Content $savePath -Raw | ConvertFrom-Json
        $script:GS = @{}
        $data.PSObject.Properties | ForEach-Object { $script:GS[$_.Name] = $_.Value }
        # Restore LootBoxes as List
        if ($script:GS.LootBoxes -isnot [System.Collections.Generic.List[string]]) {
            $list = [System.Collections.Generic.List[string]]@()
            foreach ($b in $script:GS.LootBoxes) { $list.Add($b) }
            $script:GS.LootBoxes = $list
        }
        Write-Info "Game loaded."
        Enter-Room $script:GS.CurrentRoom
        Update-HUD
    } catch { Write-Warn ("Load failed: " + $_) }
}

# ============================================================
# NEW GAME DIALOG  (Human / no class until Floor 3 gate)
# ============================================================
function Show-NewGameDialog {
    [xml]$dlgXml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="New Crawler" Height="480" Width="500"
        Background="#121212" WindowStartupLocation="CenterOwner"
        ResizeMode="NoResize">
    <StackPanel Margin="30">
        <TextBlock Text="DUNGEON CRAWLER WORLD" Foreground="#FF3B30"
                   FontFamily="Consolas" FontSize="18" FontWeight="Bold"
                   HorizontalAlignment="Center" Margin="0,0,0,5"/>
        <TextBlock Text="Season 14 -- You are not Carl. Carl is busy." Foreground="#636366"
                   FontFamily="Consolas" FontSize="11" HorizontalAlignment="Center" Margin="0,0,0,6"/>
        <TextBlock Text="Earth has been atomized. The dungeon is what remains." Foreground="#8E8E93"
                   FontFamily="Consolas" FontSize="11" TextWrapping="Wrap" HorizontalAlignment="Center" Margin="0,0,0,20"/>
        <TextBlock Text="CRAWLER NAME:" Foreground="#0A84FF" FontFamily="Consolas"
                   FontSize="12" FontWeight="Bold" Margin="0,0,0,5"/>
        <TextBox x:Name="txtName" Background="#1C1C1E" Foreground="White" BorderBrush="#FF3B30"
                 BorderThickness="1.5" FontFamily="Consolas" FontSize="14"
                 Padding="8,5" Margin="0,0,0,16" Text=""/>
        <TextBlock Foreground="#636366" FontFamily="Consolas" FontSize="11" Margin="0,0,0,8"
                   Text="You start as: Human / Class: Unselected" />
        <TextBlock Foreground="#8E8E93" FontFamily="Consolas" FontSize="11" TextWrapping="Wrap" Margin="0,0,0,16"
                   Text="Race and Class are assigned at the Selection Gate on Floor 3, based on how you play Floors 1 and 2. No two crawlers unlock the same options."/>
        <TextBlock Text="&quot;You can't just survive here. You gotta survive BIG.&quot;"
                   Foreground="#3A3A3C" FontFamily="Consolas" FontSize="10" FontStyle="Italic"
                   HorizontalAlignment="Center" Margin="0,0,0,20"/>
        <Button x:Name="btnStart" Content="ENTER THE DUNGEON"
                Background="#1C1C1E" Foreground="#FF3B30" BorderBrush="#FF3B30" BorderThickness="1.5"
                FontFamily="Consolas" FontSize="14" FontWeight="Bold" Padding="12,8"
                Cursor="Hand" HorizontalAlignment="Center"/>
    </StackPanel>
</Window>
"@
    $dlg = [System.Windows.Markup.XamlReader]::Load([System.Xml.XmlNodeReader]::new($dlgXml))
    $dlg.Owner = $script:Window
    $result = @{ Name="Crawler"; OK=$false }
    $dlg.FindName("btnStart").Add_Click({
        $n = $dlg.FindName("txtName").Text.Trim()
        $result.Name = if ($n) { $n } else { "Crawler" }
        $result.OK   = $true
        $dlg.Close()
    })
    $dlg.ShowDialog() | Out-Null
    return $result
}

# ============================================================
# WINDOW BOOTSTRAP  (element auto-mapping per spec)
# ============================================================
$script:Window = [System.Windows.Markup.XamlReader]::Load([System.Xml.XmlNodeReader]::new($XAML))

# Auto-map all named elements to $script:UI_<Name> variables
$XAML.SelectNodes("//*[@x:Name]", ([System.Xml.XmlNamespaceManager](New-Object System.Xml.XmlNamespaceManager($XAML.NameTable)).tap({ $_.AddNamespace("x","http://schemas.microsoft.com/winfx/2006/xaml") }))) 2>$null | ForEach-Object {
    $n = $_.GetAttribute("Name","http://schemas.microsoft.com/winfx/2006/xaml")
    if ($n) { Set-Variable -Name "UI_$n" -Value $script:Window.FindName($n) -Scope Script }
}
# Fallback manual mapping for critical elements
$script:rtbOutput    = $script:Window.FindName("TxtTerminal")
$script:scrollOutput = $script:Window.FindName("scrollOutput")
foreach ($eName in @("TxtName","TxtRace","TxtClass","TxtLevel","TxtViewers","TxtRating",
                     "BarHP","BarMP","BarXP","TxtHP","TxtMP","TxtXP","TxtGold","TxtStats",
                     "TxtAtk","TxtDef","TxtSpd","TxtKills","TxtFloor","TxtWeapon","TxtArmor",
                     "TxtLocation","TxtFloorName","TxtExits","LstInventory","LstBoxes",
                     "combatBar","lblEnemy","lblEnemyHP","lblEnemyDef","TxtInput")) {
    $el = $script:Window.FindName($eName)
    if ($el) { Set-Variable -Name "UI_$eName" -Value $el -Scope Script }
}

$script:GS = $null

# ============================================================
# BUTTON WIRING
# ============================================================
# Title bar
$script:Window.FindName("btnNewGame").Add_Click({
    $r = Show-NewGameDialog
    if ($r.OK) {
        $script:GS = New-GameState $r.Name
        $script:rtbOutput.Document.Blocks.Clear()
        Write-RTB "╔══════════════════════════════════════════════════════════╗" "#FF3B30"
        Write-RTB "║        DUNGEON CRAWLER WORLD - SEASON 14               ║" "#FF3B30"
        Write-RTB "╚══════════════════════════════════════════════════════════╝" "#FF3B30"
        Write-Blank
        Write-TheSystem ("CRAWLER DESIGNATION: " + $script:GS.PlayerName.ToUpper() + ". RACE: HUMAN. CLASS: UNSELECTED.")
        Write-TheSystem "YOUR RACE AND CLASS WILL BE DETERMINED AT THE SELECTION GATE ON FLOOR 3."
        Write-TheSystem "HOW YOU PLAY FLOORS 1 AND 2 DETERMINES YOUR OPTIONS. ACT ACCORDINGLY."
        Write-TheSystem "WE ARE WATCHING. THE GALAXY IS WATCHING. YOUR VIEWER COUNT IS CURRENTLY 100. THIS IS LOW."
        Write-Blank
        $fd = $script:FloorData[1]
        Write-RTB $fd.Intro "#FFCC00"
        Write-Blank
        Enter-Room "f1_spawn"
        Update-HUD
    }
})
$script:Window.FindName("btnSave").Add_Click({ if ($script:GS) { Save-Game } else { Write-Warn "No game in progress." } })
$script:Window.FindName("btnLoad").Add_Click({ Load-Game })
$script:Window.FindName("btnHelp").Add_Click({ if ($script:GS) { Invoke-GameCommand "help" } })

# Action bar
$script:Window.FindName("btnLook").Add_Click({    if ($script:GS) { Invoke-GameCommand "look" } })
$script:Window.FindName("btnInv").Add_Click({     if ($script:GS) { Invoke-GameCommand "inventory" } })
$script:Window.FindName("btnStats").Add_Click({   if ($script:GS) { Invoke-GameCommand "stats" } })
$script:Window.FindName("btnRest").Add_Click({    if ($script:GS) { Invoke-GameCommand "rest" } })
$script:Window.FindName("btnMap").Add_Click({     if ($script:GS) { Invoke-GameCommand "map" } })
$script:Window.FindName("btnQuests").Add_Click({  if ($script:GS) { Invoke-GameCommand "quests" } })
$script:Window.FindName("btnTakeAll").Add_Click({ if ($script:GS) { Invoke-GameCommand "take all" } })
$script:Window.FindName("btnSearch").Add_Click({  if ($script:GS) { Invoke-GameCommand "search" } })
$script:Window.FindName("btnCraft").Add_Click({   if ($script:GS) { Invoke-GameCommand "craft" } })
$script:Window.FindName("btnAchieves").Add_Click({if ($script:GS) { Invoke-GameCommand "achievements" } })

# Combat bar
$script:Window.FindName("btnAttack").Add_Click({  if ($script:GS) { Invoke-GameCommand "attack" } })
$script:Window.FindName("btnSpell").Add_Click({   if ($script:GS) { Invoke-GameCommand "spell" } })
$script:Window.FindName("btnUseItem").Add_Click({ if ($script:GS) { Do-UseItemSelected } })
$script:Window.FindName("btnFlee").Add_Click({    if ($script:GS) { Invoke-GameCommand "flee" } })

# Inventory / loot box panel buttons
$script:Window.FindName("btnInvPanel").Add_Click({ if ($script:GS) { Do-UseItemSelected } })
$script:Window.FindName("btnOpenBox").Add_Click({  if ($script:GS) { Do-OpenBox } })

# Nav arrows
$navDirMap = @{btnNavN="north";btnNavS="south";btnNavE="east";btnNavW="west";btnNavUp="up";btnNavDown="down"}
foreach ($kv in $navDirMap.GetEnumerator()) {
    $btn = $script:Window.FindName($kv.Key)
    $dir = $kv.Value
    $btn.Add_Click([scriptblock]::Create("if (`$script:GS) { Do-Move '$dir' }"))
}

# Command input: Enter key or ENTER button
$script:Window.FindName("TxtInput").Add_KeyDown({
    param($s, $e)
    if ($e.Key -eq [System.Windows.Input.Key]::Return) {
        $cmd = $script:UI_TxtInput.Text.Trim()
        $script:UI_TxtInput.Clear()
        if ($cmd) {
            Write-RTB ("> " + $cmd) "#636366"
            Invoke-GameCommand -Command $cmd
        }
    }
})
$script:Window.FindName("btnSubmit").Add_Click({
    $cmd = $script:UI_TxtInput.Text.Trim()
    $script:UI_TxtInput.Clear()
    if ($cmd) {
        Write-RTB ("> " + $cmd) "#636366"
        Invoke-GameCommand -Command $cmd
    }
})

# ============================================================
# SPLASH SCREEN
# ============================================================
Write-RTB "╔══════════════════════════════════════════════════════════╗" "#FF3B30"
Write-RTB "║        DUNGEON CRAWLER WORLD - DESPERATION ENGINE       ║" "#FF3B30"
Write-RTB "╚══════════════════════════════════════════════════════════╝" "#FF3B30"
Write-Blank
Write-RTB "A text adventure in the Dungeon Crawler Carl universe." "#8E8E93"
Write-RTB "You are NOT Carl. Carl is busy. You are a different crawler, entirely on your own." "#8E8E93"
Write-Blank
Write-TheSystem "EARTH NO LONGER EXISTS. THE DUNGEON DOES. FIND THE STAIRCASE."
Write-RTB "Click [NEW GAME] to begin. Your class is determined by how you play." "#E5E5EA"
Write-Blank
Write-RTB "10 FLOORS:" "#636366"
Write-RTB "  1: Collapsed Surface     6: The Hunting Grounds" "#4A4A4A"
Write-RTB "  2: Undercity Sewers      7: The Gladiator City" "#4A4A4A"
Write-RTB "  3: The Over City *GATE*  8: Bedlam" "#4A4A4A"
Write-RTB "  4: The Iron Tangle       9: Faction Wars" "#4A4A4A"
Write-RTB "  5: The Bubble Castles   10: The Final Descent" "#4A4A4A"
Write-Blank
Write-RTB "STAT SYSTEM: STR/CON/DEX/INT/CHA. HP from CON. MP from INT. No natural regen." "#636366"
Write-RTB "LOOT BOXES: Iron < Bronze < Silver < Gold < Platinum < Celestial (+ Spicy variants)" "#636366"
Write-RTB "VIEWERS: Do interesting things. Don't be boring. The galaxy is watching." "#636366"

$script:Window.ShowDialog() | Out-Null
