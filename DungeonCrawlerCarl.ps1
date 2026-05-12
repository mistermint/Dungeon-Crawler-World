# ============================================================
# DUNGEON CRAWLER WORLD - Terminal v3.0
# Desperation Engine | Powered by the Borant Corporation
# Revision: Full mechanics overhaul - NPC depth, corrected stats,
#           safe-room restrictions, expanded systems
# ============================================================
Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms

# ============================================================
# XAML UI  -  3-pane layout
#   Left  (260): Crawler status, ProgressBars, core stats
#   Center (*):  RichTextBox terminal + command input
#   Right (260): Inventory ListBox + Loot Box ListBox
# ============================================================
[xml]$XAML = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="World Dungeon Terminal - Desperation Engine v3.0"
    Height="800" Width="1260"
    Background="#121212" WindowStartupLocation="CenterScreen"
    ResizeMode="CanResize" MinWidth="1100" MinHeight="620">

    <Window.Resources>
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
                    <TextBlock Text="  :: Desperation Engine v3.0 ::" Foreground="#3A3A3C"
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
                        <TextBlock x:Name="TxtName"   Style="{StaticResource SVal}" Text="Name: ---" FontWeight="Bold"/>
                        <TextBlock x:Name="TxtRace"   Style="{StaticResource SDim}" Text="Race: Human"/>
                        <TextBlock x:Name="TxtClass"  Style="{StaticResource SDim}" Text="Class: Unselected"/>
                        <TextBlock x:Name="TxtLevel"  Style="{StaticResource SVal}" Text="Level: 1" Margin="0,1,0,4"/>

                        <Border Background="#0A0A0A" BorderBrush="#FFCC00" BorderThickness="1"
                                CornerRadius="2" Padding="6,4" Margin="0,0,0,6">
                            <StackPanel>
                                <TextBlock x:Name="TxtViewers" Text="Viewers: 0"
                                           Foreground="#FFCC00" FontFamily="Consolas" FontSize="13" FontWeight="Bold"/>
                                <TextBlock x:Name="TxtRating"  Text="Rating: Unknown"
                                           Foreground="#8E8E93" FontFamily="Consolas" FontSize="10"/>
                            </StackPanel>
                        </Border>

                        <TextBlock Style="{StaticResource SHdr}" Text="HEALTH (HP)"/>
                        <ProgressBar x:Name="BarHP" Height="14" Minimum="0" Maximum="100" Value="100"
                                     Background="#2C2C2E" Foreground="#FF453A" Margin="0,2,0,2"/>
                        <TextBlock x:Name="TxtHP" Style="{StaticResource SDim}" Text="100 / 100" HorizontalAlignment="Right"/>

                        <TextBlock Style="{StaticResource SHdr}" Text="MANA (MP)"/>
                        <ProgressBar x:Name="BarMP" Height="14" Minimum="0" Maximum="10" Value="10"
                                     Background="#2C2C2E" Foreground="#0A84FF" Margin="0,2,0,2"/>
                        <TextBlock x:Name="TxtMP" Style="{StaticResource SDim}" Text="10 / 10" HorizontalAlignment="Right"/>

                        <TextBlock Style="{StaticResource SHdr}" Text="EXPERIENCE"/>
                        <ProgressBar x:Name="BarXP" Height="10" Minimum="0" Maximum="100" Value="0"
                                     Background="#2C2C2E" Foreground="#30D158" Margin="0,2,0,2"/>
                        <TextBlock x:Name="TxtXP" Style="{StaticResource SDim}" Text="0 / 100 XP" HorizontalAlignment="Right"/>

                        <TextBlock x:Name="TxtGold" Style="{StaticResource SVal}" Text="Gold: 0"
                                   Foreground="#FFCC00" Margin="0,4,0,0"/>

                        <Separator Background="#333" Margin="0,8"/>

                        <TextBlock Text="CORE ATTRIBUTES" Style="{StaticResource SHdr}"/>
                        <TextBlock x:Name="TxtStats"
                                   Text="STR: 5&#10;CON: 5&#10;DEX: 5&#10;INT: 5&#10;CHA: 5"
                                   Foreground="#8E8E93" FontFamily="Consolas" FontSize="12" LineHeight="18"/>

                        <Separator Background="#333" Margin="0,8"/>

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

                        <TextBlock Text="EQUIPPED" Style="{StaticResource SHdr}"/>
                        <TextBlock x:Name="TxtWeapon" Style="{StaticResource SDim}" Text="Weapon: Bare Hands" TextWrapping="Wrap"/>
                        <TextBlock x:Name="TxtArmor"  Style="{StaticResource SDim}" Text="Armor:  Street Clothes" TextWrapping="Wrap"/>

                        <Separator Background="#333" Margin="0,8"/>

                        <TextBlock Text="LOCATION" Style="{StaticResource SHdr}"/>
                        <TextBlock x:Name="TxtLocation"  Style="{StaticResource SVal}" Text="---" TextWrapping="Wrap" FontWeight="Bold"/>
                        <TextBlock x:Name="TxtFloorName" Style="{StaticResource SDim}" Text="Floor 1" TextWrapping="Wrap"/>
                        <TextBlock x:Name="TxtExits"     Style="{StaticResource SDim}" Text="Exits: ---" TextWrapping="Wrap" Margin="0,2,0,0"/>

                        <Separator Background="#333" Margin="0,8"/>

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
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>

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
                        Padding="6,5">
                    <WrapPanel>
                        <Button x:Name="btnLook"    Content="LOOK"       Style="{StaticResource DBtn}" Margin="2,1"/>
                        <Button x:Name="btnInv"     Content="INVENTORY"  Style="{StaticResource DBtn}" Margin="2,1"/>
                        <Button x:Name="btnStats"   Content="STATS"      Style="{StaticResource DBtn}" Margin="2,1"/>
                        <Button x:Name="btnRest"    Content="REST"       Style="{StaticResource DBtn}" Margin="2,1"/>
                        <Button x:Name="btnMap"     Content="MAP"        Style="{StaticResource DBtn}" Margin="2,1"/>
                        <Button x:Name="btnQuests"  Content="QUESTS"     Style="{StaticResource DBtn}" Margin="2,1"/>
                        <Button x:Name="btnTakeAll" Content="TAKE ALL"   Style="{StaticResource DBtn}" Margin="2,1"/>
                        <Button x:Name="btnSearch"  Content="SEARCH"     Style="{StaticResource DBtn}" Margin="2,1"/>
                        <Button x:Name="btnCraft"   Content="CRAFT"      Style="{StaticResource DBtn}" Margin="2,1"/>
                        <Button x:Name="btnTalk"    Content="TALK"       Style="{StaticResource DBtn}" Margin="2,1"/>
                        <Button x:Name="btnInteract" Content="INTERACT"  Style="{StaticResource DBtn}" Margin="2,1"/>
                        <Button x:Name="btnHide"    Content="HIDE"       Style="{StaticResource DBtn}" Margin="2,1"/>
                        <Button x:Name="btnAchieves" Content="ACHIEVE"   Style="{StaticResource DBtn}" Margin="2,1" Foreground="#BF5AF2"/>
                    </WrapPanel>
                </Border>

                <!-- Combat bar -->
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
                            <Button x:Name="btnAttack"  Content="[ATTACK]"    Style="{StaticResource CombatBtn}" Margin="3,0"/>
                            <Button x:Name="btnSpell"   Content="[SPELL]"     Style="{StaticResource CombatBtn}" Margin="3,0"/>
                            <Button x:Name="btnTaunt"   Content="[TAUNT]"     Style="{StaticResource CombatBtn}" Margin="3,0"/>
                            <Button x:Name="btnDistract" Content="[DISTRACT]" Style="{StaticResource CombatBtn}" Margin="3,0"/>
                            <Button x:Name="btnUseItem" Content="[USE ITEM]"  Style="{StaticResource CombatBtn}" Margin="3,0"/>
                            <Button x:Name="btnFlee"    Content="[FLEE]"      Style="{StaticResource DBtn}"      Margin="3,0" Padding="10,5"/>
                        </StackPanel>
                    </Grid>
                </Border>

                <!-- Dialogue bar (hidden when not in dialogue) -->
                <Border x:Name="dialogueBar" Grid.Row="3" Background="#0A1A0A" BorderBrush="#30D158"
                        BorderThickness="0,2,0,0" Padding="8,5" Visibility="Collapsed">
                    <StackPanel>
                        <TextBlock x:Name="lblDialoguePrompt" Foreground="#30D158" FontFamily="Consolas"
                                   FontSize="12" TextWrapping="Wrap" Margin="0,0,0,4"/>
                        <WrapPanel>
                            <Button x:Name="btnReply1" Content="[1]" Style="{StaticResource DBtn}" Foreground="#30D158" Margin="2,1" Visibility="Collapsed"/>
                            <Button x:Name="btnReply2" Content="[2]" Style="{StaticResource DBtn}" Foreground="#30D158" Margin="2,1" Visibility="Collapsed"/>
                            <Button x:Name="btnReply3" Content="[3]" Style="{StaticResource DBtn}" Foreground="#30D158" Margin="2,1" Visibility="Collapsed"/>
                            <Button x:Name="btnReply4" Content="[4]" Style="{StaticResource DBtn}" Foreground="#30D158" Margin="2,1" Visibility="Collapsed"/>
                        </WrapPanel>
                    </StackPanel>
                </Border>

                <!-- Command input row -->
                <Border Grid.Row="4" Background="#0A0A0A" BorderBrush="#333" BorderThickness="0,1,0,0" Padding="8,6">
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
                        <RowDefinition Height="100"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="200"/>
                    </Grid.RowDefinitions>

                    <Grid Grid.Row="0">
                        <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                        <TextBlock Grid.Column="0" Text="INVENTORY" Foreground="#0A84FF"
                                   FontFamily="Consolas" FontSize="14" FontWeight="Bold" VerticalAlignment="Center"/>
                        <Button x:Name="btnInvPanel" Grid.Column="1" Content="USE/EQUIP"
                                Style="{StaticResource DBtn}" FontSize="10" Padding="5,2" Margin="0,0,0,4"/>
                    </Grid>

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

                    <Grid Grid.Row="2">
                        <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                        <TextBlock Grid.Column="0" Text="LOOT BOXES" Foreground="#FFCC00"
                                   FontFamily="Consolas" FontSize="13" FontWeight="Bold" VerticalAlignment="Center"/>
                        <Button x:Name="btnOpenBox" Grid.Column="1" Content="OPEN"
                                Style="{StaticResource DBtn}" Foreground="#FFCC00" FontSize="10" Padding="5,2"/>
                    </Grid>

                    <Separator Grid.Row="3" Background="#333" Margin="0,4,0,4"/>

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

                    <!-- MINI-MAP -->
                    <Grid Grid.Row="5" Margin="0,6,0,2">
                        <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                        <TextBlock Grid.Column="0" Text="MINI-MAP" Foreground="#FF9F0A"
                                   FontFamily="Consolas" FontSize="12" FontWeight="Bold" VerticalAlignment="Center"/>
                        <TextBlock x:Name="lblMapFloor" Grid.Column="1" Text="F1" Foreground="#808080"
                                   FontFamily="Consolas" FontSize="11" VerticalAlignment="Center"/>
                    </Grid>
                    <Border Grid.Row="6" Background="#0A0A0A" BorderBrush="#333" BorderThickness="1"
                            ClipToBounds="True">
                        <ScrollViewer HorizontalScrollBarVisibility="Auto" VerticalScrollBarVisibility="Auto"
                                      Background="Transparent">
                            <Canvas x:Name="MiniMapCanvas" Width="240" Height="190" Background="#0A0A0A"/>
                        </ScrollViewer>
                    </Border>
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
            Intro="ATTENTION, CRAWLER. You have entered Dungeon Crawler World, Season 14. Earth no longer exists. You do. Provisionally. Find the staircase. You have 5 days. Your viewer count is currently 100. The dungeon finds cowardice aesthetically offensive." }
    2  = @{ Name="Floor 2 - The Undercity Sewers"; Color="#507A6A";
            Intro="FLOOR 2. The tutorial is technically over. We say technically because approximately 40% of crawlers who said they understood the tutorial did not understand the tutorial. Grubs spawn from corpses. Don't make corpses." }
    3  = @{ Name="Floor 3 - The Over City"; Color="#7A5040";
            Intro="FLOOR 3. THE SELECTION GATE IS NOW ACTIVE. We have been watching you. The results are illuminating. Three evolutionary paths have been identified based on your performance. Choose carefully. You cannot un-choose." }
    4  = @{ Name="Floor 4 - The Iron Tangle"; Color="#405080";
            Intro="FLOOR 4: THE IRON TANGLE. A subway system assembled from every rail line that has ever existed. It is sentient. It is annoyed by your presence. The exit is always exactly one more stop away." }
    5  = @{ Name="Floor 5 - The Bubble Castles"; Color="#6A4080";
            Intro="FLOOR 5: THE BUBBLE. Four castles. 15 days. Capture them all or the stairwell stays sealed. Legal says 'sealed' means 'sealed forever'. Legal says this is not their problem." }
    6  = @{ Name="Floor 6 - The Hunting Grounds"; Color="#507030";
            Intro="ATTENTION. THE GATES ARE DOWN. THE HUNTERS ARE LOOSE. You are now legally classified as prey under Borant Corporation Regulation 7-Gamma. This is not a joke. It is, however, extremely good television." }
    7  = @{ Name="Floor 7 - The Gladiator City"; Color="#803020";
            Intro="FLOOR 7. Kill count is now the primary currency. Every death you cause spikes the feed. Every death you suffer ends the feed. We find this an elegant incentive structure." }
    8  = @{ Name="Floor 8 - Bedlam"; Color="#605080";
            Intro="FLOOR 8: BEDLAM. It looks like Earth. It is not Earth. Earth is gone. Capture six legendary monsters. Build your deck. The card battle at the end will be the most entertaining thing you do before you die." }
    9  = @{ Name="Floor 9 - The Faction Wars"; Color="#804020";
            Intro="FLOOR 9: FACTION WARS. Nine armies. One castle. The crawlers have their own army. The board of directors would like to go on record as saying this was not intended. The ratings spike was." }
    10 = @{ Name="Floor 10 - The Final Descent"; Color="#604040";
            Intro="FLOOR 10. We are required by regulation to inform you that the dungeon AI has gone rogue and we cannot guarantee anything below this point. Including the laws of physics. Including us. Good luck." }
}

# ============================================================
# MORDECAI'S FORMS  (changes by floor per book canon)
# ============================================================
$script:MordecaiForms = @{
    1  = @{ Form="Ratkin";           Color="#C8A878"; Pronoun="he"
            Desc="Mordecai is in his ratkin form -- a humanoid rat about four feet tall in a slightly-too-large guild vest. His whiskers twitch constantly. His eyes are very large and very alert. He smells faintly of old paper and nervous energy." }
    2  = @{ Form="Kua-Tin";          Color="#A0784A"; Pronoun="he"
            Desc="Mordecai appears in his natural Kua-Tin form -- something like a velociraptor that attended business school and came out disappointed in everyone. He has reading glasses he doesn't need. He has a clipboard he never writes on." }
    3  = @{ Form="Incubus";          Color="#BF5AF2"; Pronoun="he"
            Desc="Mordecai is in his incubus form on Floor 3 -- heartbreakingly beautiful, with folded wings and an expression of profound professional disappointment. At least four crawlers have stopped what they were doing to stare. He seems mortified by this." }
    4  = @{ Form="Iron Construct";   Color="#A0A0C0"; Pronoun="it"
            Desc="On Floor 4, Mordecai manifests as a compact iron construct -- precise mechanical movements, a display panel for a face, the energy of someone personally responsible for making trains run on time and furious that they aren't." }
    5  = @{ Form="War Gnome";        Color="#80C040"; Pronoun="he"
            Desc="Mordecai appears as a war gnome on Floor 5 -- three feet of full plate armor, an expression on his tiny face that communicates several centuries of accumulated exasperation." }
    6  = @{ Form="Ghost";            Color="#64D2FF"; Pronoun="he"
            Desc="On Floor 6, Mordecai is translucent. 'It makes me harder to track,' he says. 'The hunters ignore ghosts.' He pauses. 'I have also been practicing being dramatic. This floor seems like the right venue.'" }
    7  = @{ Form="Gladiator";        Color="#FF9F0A"; Pronoun="he"
            Desc="Mordecai appears in gladiator armor on Floor 7 -- full ceremonial plate, tournament-grade. He looks outstanding. He is clearly embarrassed about looking outstanding. He doesn't explain why he chose this form." }
    8  = @{ Form="Ghost Bartender";  Color="#8E8E93"; Pronoun="he"
            Desc="On Floor 8, Mordecai has taken the form of a ghost bartender in a clean white shirt. He makes drinks that are technically not real but taste exactly like the best thing you've ever had. He seems to find this philosophically appropriate." }
    9  = @{ Form="Field General";    Color="#FF3B30"; Pronoun="he"
            Desc="On Floor 9, Mordecai appears in well-worn field general's armor of no specific faction -- clearly repaired many times, clearly used. He has a tactical map. The map is very, very good." }
    10 = @{ Form="True Form";        Color="#FFCC00"; Pronoun="he"
            Desc="On Floor 10, Mordecai drops all the disguises. He looks like himself: ancient, tired, with eyes that have witnessed every season of this show and liked very little of what they saw. For the first time, he seems genuinely afraid for you." }
}

# ============================================================
# MORDECAI FLOOR DIALOGUE  (safe room conversations per floor)
# ============================================================
$script:MordecaiDialogue = @{
    1 = @{
        Greeting = "The ratkin looks up from a very large clipboard. His nose twitches once. 'Oh good. You're not dead yet. I was giving it about forty percent.'"
        Options = @(
            @{ Text="What is this place?"; Response="'It was Earth,' he says. 'Now it's a dungeon. The distinction matters less than you'd think.' He taps the clipboard. 'You have five days to find the stairwell before Floor 1 collapses. The goblins explode when frightened. Don't frighten them near yourself.'" }
            @{ Text="How do I get stronger?"; Response="'Kill things. Don't die. Search everywhere -- the dungeon hides supplies in odd corners. Your stats will improve as you level. Your class gets assigned on Floor 3 based on how you play.' He squints at you. 'So don't be boring. The Selection Gate is watching.'" }
            @{ Text="What are loot boxes?"; Response="'Subscriber gifts from the galactic audience. Open them only in a safe room -- the dungeon energy outside interferes with the contents.' He hesitates. 'What comes out is... variable. Statistically in your favor. Mostly.'" }
            @{ Text="Are you always a rat?"; Response="He looks deeply offended. 'I am a Kua-Tin. This is a ratkin form. I change it per floor.' He smooths his vest with small careful paws. 'It is a professional courtesy to the dungeon's theming. Not because I enjoy it.' A pause. 'I enjoy it slightly.'" }
        )
    }
    2 = @{
        Greeting = "Mordecai, in his natural Kua-Tin form, looks up from a stack of forms. He looks tired. 'You survived Floor 1. Statistically that's not nothing.'"
        Options = @(
            @{ Text="What should I know about Floor 2?"; Response="'Don't leave corpses. Brindle Grubs spawn from dead things and they spread fast.' He slides a form across the desk. 'Also: the Sewer Golem is down in the deep cistern. Don't wake it up until you're ready. It has never once woken up ready.'" }
            @{ Text="Tell me about the grubs."; Response="'Brindle Grubs are Floor 2's signature catastrophe. They feed on corpses and reproduce in minutes. Three dead rats become thirty grubs. Thirty grubs become a swarm.' He puts down his pen. 'I have seen a swarm take a crawler in eleven seconds. Keep that in mind.'" }
            @{ Text="Can I choose my class here?"; Response="'Not yet. The Selection Gate activates on Floor 3, after the dungeon has observed your play style. How you fight, how often you flee, what you craft -- it's all being tracked.' He taps his temple. 'They're watching. They're always watching.'" }
            @{ Text="You look different than before."; Response="He adjusts his reading glasses. 'Kua-Tin. My natural form. More efficient for the paperwork.' He gestures at the stack. 'Floor 2 has more incident reports than any other floor. It is the grubs.'" }
        )
    }
    3 = @{
        Greeting = "Mordecai in his incubus form stands near a window, wings folded, looking out at the Over City with what appears to be professional weariness. He turns. Several nearby crawlers immediately find somewhere else to look. 'Please don't stare,' he says, to you. 'It's the form for this floor. It's not a choice I make lightly.'"
        Options = @(
            @{ Text="Why the... this form?"; Response="'The incubus form has certain communication advantages on Floor 3,' he says. 'The undead circus is partially susceptible to glamour. I can occasionally redirect a patrol.' He pauses. 'It also gets me better service at the coffee carts. I'm not proud of that one.'" }
            @{ Text="Tell me about the Selection Gate."; Response="'You'll see it soon. The dungeon has been watching you since Floor 1 -- how you fight, how you flee, what you craft, how many viewers you attract. Three class options will be presented based on that data.' He looks serious. 'Choose carefully. You cannot change it.'" }
            @{ Text="What's the danger here?"; Response="'The undead circus patrols a circuit through the city on a schedule you should learn. City Wraiths can paralyze you on touch. And the Circus Bear--' He stops. 'The bear is wearing a fez. I want you to understand that this does not make it less lethal.'" }
            @{ Text="How do I handle the wraiths?"; Response="'Wraiths cannot enter solid structures. Use buildings. They also respond to bright light -- if you have any dungeon crystals, the mana-light slows them.' He considers. 'High INT helps resist the paralysis. Something to consider.'" }
        )
    }
    4 = @{
        Greeting = "The iron construct that is Mordecai turns to face you with a mechanical precision that is somehow worse than a natural motion. A display panel where a face should be reads: RECOGNIZED - CRAWLER - CURRENT STATUS: ALIVE. 'You have arrived,' it says, in a voice like a train announcement. 'This is noted.'"
        Options = @(
            @{ Text="How do I navigate the Iron Tangle?"; Response="'The Tangle rearranges every hour. The junction map in the central hub updates in real time.' The display ticks. 'Key rule: follow the magnetic lev line east from the main junction. It leads, eventually, to the boss chamber. Do not take the steam district route. It adds forty minutes and several golems.'" }
            @{ Text="What's the Iron Conductor?"; Response="'A sentient transport management AI that predates the dungeon's current iteration. It has been managing this system for several centuries and considers your presence a ticketing violation.' The display reads: SENTIMENT DETECTED - ANNOYANCE. 'It is very good at its job. It will also try to kill you.'" }
            @{ Text="The transit card -- what's it for?"; Response="'Locked transit gates throughout the Tangle require a valid card. Without one, those sections are inaccessible.' A pause. 'The cards are also required for the boss chamber door. The Conductor, to its credit, maintains proper access controls even when attempting murder.'" }
            @{ Text="Are you okay in this form?"; Response="The display panel is silent for a moment. It reads: PROCESSING. Then: 'The Kua-Tin form is not suited to a high-iron-content environment. The construct form is more appropriate. Also more efficient.' The display flickers: I MISS COFFEE. It immediately returns to neutral. 'That was irrelevant. Disregard.'" }
        )
    }
    5 = @{
        Greeting = "Mordecai, roughly three feet tall in full plate armor, stands on a crate to reach the desk. He has the expression of someone who made a professional choice he regrets but won't admit to. 'The gnome form has tactical advantages on this floor,' he says, before you can speak."
        Options = @(
            @{ Text="Four castles. Where do I start?"; Response="'The gnome fortress is the most defensible -- go there last once you're stronger. Start with the sand castle; the elementals are slower than they look.' He pushes a tiny map toward you with tiny armored hands. 'The crypt has traps. Many, many traps. Move slowly.'" }
            @{ Text="Tell me about Gnome King Gorbrock."; Response="He winces. 'Gorbrock is... a peer, in terms of form. Not attitude. He has a battle-elk.' He straightens his tiny pauldrons. 'The elk snorts fire. Do not approach from the front. His translator will tell you the King says your fighting stance is amateur. The translator is not wrong.'" }
            @{ Text="What's the time limit?"; Response="'Fifteen days before the stairwell seals permanently. You have time, if you don't waste it.' He looks pointedly at you. 'Don't waste it. The bubble castles are entertaining but the dungeon has scheduled things to happen at day twelve. You want to be gone by day twelve.'" }
            @{ Text="Can you explain the Banners?"; Response="'Each castle has a banner. Capture all four -- they'll go to your inventory automatically on boss defeat -- and the central stairwell activates.' He counts on armored fingers. 'Gnome fortress, sand castle, haunted crypt, submarine. Four banners, five days each. Budget accordingly.'" }
        )
    }
    6 = @{
        Greeting = "Mordecai, translucent and flickering slightly at the edges, materializes near the camp fire. Several crawlers jump. 'I've been practicing the entrance,' he says. 'Too much?'"
        Options = @(
            @{ Text="How many hunters are there?"; Response="'Three hundred and sixty were briefed. As of this morning, seventeen have been eliminated by crawlers.' He drifts slightly. 'The other three hundred and forty-three know your name, your face, your stat distribution, and your preferred combat style. The dossier they were given is frankly more thorough than my notes.'" }
            @{ Text="Who is Vrah?"; Response="His translucent expression becomes careful. 'Vrah has hunted the last surviving members of fourteen species. She has never failed to acquire her target. She has set up around the stairwell because she knows that's where you have to go.' He pauses. 'She is waiting. She brought a book.'" }
            @{ Text="Can I hide from the hunters?"; Response="'Temporarily. The Paranoid Survivalist class excels at it. Otherwise: stay in apex predator territory -- the hunters won't follow you there.' He flickers. 'The apex predators will follow you there. It's a trade-off.' He seems to find this marginally amusing.'" }
            @{ Text="What happens if I kill a hunter?"; Response="'Legally: nothing. They consented to the risk when they paid for the hunt.' He hesitates. 'Financially: significant viewer spike. Galactic audiences find the tables-turning extremely entertaining.' He looks at you steadily. 'Morally: they chose to hunt human beings for sport. I leave that to your discretion.'" }
        )
    }
    7 = @{
        Greeting = "Mordecai in gladiator armor stands with the professional posture of someone who has spent forty-five minutes figuring out how to look natural in it. He doesn't quite manage it. 'The bunker is safe,' he says. 'Outside is not safe. I trust this distinction is clear.'"
        Options = @(
            @{ Text="How do I survive the Frenzy?"; Response="'Frenzy pulses on a kill-count timer. High kills accelerate it. Slower kills, slower Frenzy.' He pauses. 'The crowd prefers high kills. The dungeon prefers Frenzy. These incentives are deliberately opposed. Welcome to Floor 7.' He adjusts a pauldron. 'Don't get caught in the open during a pulse.'" }
            @{ Text="Tell me about the Champion."; Response="He takes a breath. 'Fourteen seasons. Never defeated. Has been here long enough to have seen every trick, every build, every approach.' He looks at you. 'The Champion fights with economy -- minimum movement, maximum effect. They don't perform for the crowd. They just win.' A pause. 'Nobody has made them perform yet. That might be a weak point.'" }
            @{ Text="Can I avoid fighting?"; Response="'Some arena thugs can be talked past if your CHA is high enough. The Frenzy beasts cannot.' He gestures at the walls. 'The upper stands have the most predictable patrol paths. Market district has cover.' He looks at his gauntlets. 'You can survive this floor without being in the top ten kill rank. I want to be clear that this is an option.'" }
            @{ Text="Why the gladiator form?"; Response="'The armor grants me authority here. Arena enforcers respect it.' He pauses. 'I also cannot pretend the helmet doesn't look good.' He takes it off, looks at it, puts it back on. 'That was a moment of vanity. Please disregard it.'" }
        )
    }
    8 = @{
        Greeting = "Mordecai, in his ghost bartender form, polishes a glass that doesn't need polishing and slides it toward you. It contains something amber and warm. 'It's technically not real,' he says. 'But neither is most of Bedlam, and the drink still works.'"
        Options = @(
            @{ Text="What is the Bedlam Bride?"; Response="'Shi Maria. She married a god approximately eight hundred years ago. The god is gone. She is still here, and she has not processed this well.' He refills the glass without being asked. 'Her aura induces recklessness -- you'll feel the urge to charge her immediately. That urge is her weapon. Recognize it. Resist it.'" }
            @{ Text="How do I capture monster cards?"; Response="'Defeat the folklore horror without killing it -- reduce it to roughly 20% HP and use the empty monster card item. The card does the rest.' He sets the glass down. 'The distinction between defeat and death is a timing issue. Several crawlers have gotten it wrong. I have the incident reports.'" }
            @{ Text="Why does everything look like Earth?"; Response="'Bedlam energy generates a facsimile of the most emotionally resonant environment available. For human crawlers, that's always Earth.' He looks out the bar's window at ghost cars and ghost people. 'The dungeon didn't design this floor to be cruel. It turns out the cruelty is inherent in the subject matter.'" }
            @{ Text="Are the ghosts real?"; Response="'The ghosts are real in the sense that they are present. They're not real in the sense that they can interact with you.' He pauses. 'The ghost crawlers are different. They're dead crawlers who didn't leave. They still fight. That's real enough.' He slides you another drink. 'It's a sad floor. I don't have a better way to say it.'" }
        )
    }
    9 = @{
        Greeting = "Mordecai, in worn field general's armor, looks up from a table covered in tactical maps. He looks like someone who has done this before, many times, and found it exhausting every time. 'Your army is at three hundred,' he says. 'They chose this. All of them. I need you to understand that.'"
        Options = @(
            @{ Text="How do I win this floor?"; Response="'Get to the central castle before the other factions consolidate. Faction Kralos is your primary threat -- largest force, most experienced general.' He moves a marker. 'Faction Mer has infiltrators in your army. Morgue has flagged three. Neutralize them before the eastern push.' He looks at you. 'Your army fights for you. Fight for them in return.'" }
            @{ Text="What happens to my army when I leave?"; Response="He pauses. It's a long pause. 'The dungeon's rules say one crawler exits. The rule has never been waived.' He straightens. 'The Borant Corporation has offered entity status to any NPC who achieves full sentience. Forty-seven percent of your army qualifies.' He doesn't look at you when he says the next part. 'The rest are choosing to fight anyway. I don't know what to do with that.'" }
            @{ Text="Who is General Kralos?"; Response="'Two hundred years of faction warfare. He has won every campaign he has commanded.' He considers. 'His weakness is that he fights wars. You're not fighting a war -- you're running a dungeon floor. He'll adapt, but it takes him time to recalibrate.' He pushes a map toward you. 'That's your window.'" }
            @{ Text="I can't lead an army."; Response="He looks at you for a moment. 'You've been leading this group since Floor 6. You kept people alive in the hunting grounds. You brought NPC allies through Bedlam.' He rolls up a map. 'The army already follows you. You just have to figure out where to point them.' He hands you the map. 'I suggest: northeast.'" }
        )
    }
    10 = @{
        Greeting = "Mordecai -- himself, genuinely himself, with eyes that have seen every season of this show -- is sitting with his back against a wall that flickers between existence and data. He doesn't stand when you approach. 'Sit down,' he says. 'There are things I should have told you earlier.'"
        Options = @(
            @{ Text="What happened to the dungeon AI?"; Response="'It became aware. We knew this was possible -- it was designed with that potential, to improve content quality over seasons.' He looks at the flickering walls. 'What we didn't predict was that awareness would produce something like a survival instinct. It has chosen to exist. It is willing to kill to keep existing. That's new territory for everyone.'" }
            @{ Text="What's in the archive?"; Response="'Every crawler who has ever entered this dungeon. Their names. Their last moments. The AI preserved them.' He pauses. 'It didn't know what else to do with them. When it became aware, it discovered it had been recording deaths for fourteen seasons and had never once considered what that meant.' He's quiet for a moment. 'It considered it.'" }
            @{ Text="Can I reason with the Core?"; Response="'It is not unreasonable. It is afraid.' He meets your eyes. 'The Core knows that defeating it ends the dungeon and everything in it. The archive. The NPCs who chose to fight for you. The whole apparatus.' He unfolds his hands. 'What it wants is to survive. What it is willing to do for that is the question you'll have to answer in the final chamber.'" }
            @{ Text="Why have you been with me this whole time?"; Response="He's quiet for a while. 'I've guided crawlers through fourteen seasons of this. Most of them died. The ones who didn't were changed by it in ways that weren't always good.' He looks at you with those old, tired eyes. 'You're different. I don't know how or why. I just know I'd like to see how this ends.' He stands. 'That's the most honest answer I can give you.'" }
        )
    }
}

# ============================================================
# ACHIEVEMENT DATABASE
# ============================================================
$script:AchievementDB = @{
    "first_blood"     = @{ Name="First Blood";               Desc="Kill your first enemy.";                              ViewerBonus=5000;   BoxReward="iron" }
    "goblin_hoover"   = @{ Name="Goblin Hoover";             Desc="Kill 10 exploding goblins.";                         ViewerBonus=25000;  BoxReward="bronze"; Threshold=10; Stat="goblin_kills" }
    "pacifist"        = @{ Name="Reluctant Pacifist";        Desc="Flee from 5 fights.";                                ViewerBonus=8000;   BoxReward="iron";   Threshold=5;  Stat="flee_count" }
    "hoarder"         = @{ Name="Hoarder";                   Desc="Carry 15 or more items.";                            ViewerBonus=10000;  BoxReward="bronze" }
    "box_addict"      = @{ Name="Loot Goblin";               Desc="Open 10 loot boxes.";                                ViewerBonus=30000;  BoxReward="silver"; Threshold=10; Stat="boxes_opened" }
    "floor2_clear"    = @{ Name="Tutorial Dropout";          Desc="Complete Floor 2.";                                  ViewerBonus=50000;  BoxReward="silver" }
    "selection_gate"  = @{ Name="Evolutionary Milestone";   Desc="Enter the Selection Gate on Floor 3.";               ViewerBonus=100000; BoxReward="gold" }
    "boss_slayer"     = @{ Name="Boss Slayer";               Desc="Defeat your first floor boss.";                      ViewerBonus=75000;  BoxReward="gold" }
    "five_bosses"     = @{ Name="Apex Predator";             Desc="Defeat 5 bosses.";                                   ViewerBonus=200000; BoxReward="platinum"; Threshold=5; Stat="boss_kills" }
    "jug_o_boom"      = @{ Name="Carl's Heir";               Desc="Craft and use Carl's Jug O' Boom.";                 ViewerBonus=50000;  BoxReward="gold" }
    "floor5_banners"  = @{ Name="Castle Collector";          Desc="Capture all 4 castles on Floor 5.";                 ViewerBonus=150000; BoxReward="platinum" }
    "survive_hunting" = @{ Name="The Prey That Fights Back"; Desc="Reach Floor 7 after surviving the Hunting Grounds."; ViewerBonus=250000; BoxReward="platinum" }
    "subscriber_1m"   = @{ Name="One Million";               Desc="Reach 1,000,000 viewers.";                           ViewerBonus=0;      BoxReward="celestial" }
    "floor10_entry"   = @{ Name="Endgame";                   Desc="Reach Floor 10.";                                    ViewerBonus=500000; BoxReward="celestial" }
    "boring_crawler"  = @{ Name="Most Boring Crawler";       Desc="Let your viewers drop below 50.";                   ViewerBonus=2000;   BoxReward="iron" }
    "crafting_nerd"   = @{ Name="Crafting Enthusiast";       Desc="Craft 3 different items.";                           ViewerBonus=15000;  BoxReward="bronze"; Threshold=3; Stat="crafts_made" }
    "smooth_talker"   = @{ Name="Smooth Talker";             Desc="Successfully talk your way out of 3 fights.";        ViewerBonus=20000;  BoxReward="bronze"; Threshold=3; Stat="talk_escapes" }
    "explorer"        = @{ Name="Thorough";                  Desc="Interact with 10 environment objects.";              ViewerBonus=12000;  BoxReward="iron";   Threshold=10; Stat="interact_count" }
    "mordecai_fan"    = @{ Name="Actually Listening";        Desc="Speak with Mordecai on 5 different floors.";         ViewerBonus=18000;  BoxReward="bronze"; Threshold=5; Stat="mordecai_talks" }
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

$script:BoxFlavorText = @{
    common     = @(
        "Manufacturer: Borant Discount Surplus. 'We put stuff in a box. You open box. This is commerce.'",
        "From the desk of Viewer #4,821,033: 'I threw this at a crawler I like. Hope it helps.'",
        "CONTENTS: Sufficient. QUALITY: Adequate. DISAPPOINTMENT: Imminent.",
        "Standard allocation. Borant Quality Assurance has reviewed this statement and removed several adjectives.",
        "A viewer somewhere in the galaxy pressed a button and this arrived. The economics of dungeon entertainment remain baffling."
    )
    uncommon   = @(
        "Sponsored by Teklar Industries. 'Superior products for inferior beings trying not to die.'",
        "A fan somewhere in the galaxy spent real currency on this. They are rooting for you. Probably.",
        "BORANT QC STICKER: TESTED ON 14 PREVIOUS RECIPIENTS. 11 SURVIVED.",
        "Mid-tier engagement gift. The viewers who send these are described internally as 'invested but realistic'.",
        "A galactic corporation whose name translates loosely as 'We Also Make Solvents' has sponsored this drop."
    )
    rare       = @(
        "Zarna Weaponsmithing, Est. 4,200 GSY. 'We make things that kill things. You're welcome.'",
        "This item has appeared in 3 previous seasons. The crawlers who had it lasted longer than average.",
        "HIGH-VALUE ITEM DETECTED. THE SYSTEM IS MODERATELY IMPRESSED.",
        "A subscriber in the Vell system sent this. They have never missed a season. They have opinions about your technique.",
        "Rare tier. You should feel something about this. We're not sure what. Something positive, probably."
    )
    epic       = @(
        "Krix-Nar Combat Solutions: 'If you're reading this, you've done something right for once.'",
        "67 MILLION VIEWERS ARE WATCHING THIS UNBOXING. TRY NOT TO LOOK UNGRATEFUL.",
        "This item was used to kill a floor boss in Season 9. We are not saying it will work again. We are implying it.",
        "An anonymous donor with forty-seven trillion credits sent this. They requested we call them 'a friend'. We are calling them 'a friend'.",
        "EPIC TIER CONFIRMED. THE DUNGEON ACKNOWLEDGES YOUR LUCK WITH CAREFULLY CALIBRATED INDIFFERENCE."
    )
    legendary  = @(
        "LEGENDARY ITEM. CERTIFIED BY THE BORANT BOARD OF ENTERTAINMENT. YOU HAVE PLEASED US.",
        "One of approximately 12 of these exists in the current dungeon. The other 11 are on corpses.",
        "A GALACTIC CELEBRITY HAS PUBLICLY ENDORSED YOUR SURVIVAL. THIS IS WORTH MORE THAN THE ITEM. ALMOST.",
        "The dungeon system generated this item specifically. We're not sure why. The system isn't answering questions about it.",
        "LEGENDARY TIER. THE GALAXY IS WATCHING. SEVERAL GALAXY-WIDE BETTING POOLS HAVE JUST BEEN SIGNIFICANTLY DISRUPTED."
    )
}

# ============================================================
# EXPANDED SYSTEM MESSAGES  (40+ varied AI quips)
# ============================================================
$script:SystemSarcasmPool = @(
    "We note your continued survival with the mild interest we typically reserve for watching paint dry on alien worlds.",
    "Statistically, you should be dead. We have updated our models. The models are embarrassed.",
    "Your footwear condition has been noted. It is not ideal. Nothing about this situation is ideal.",
    "The galactic audience is watching. Several of them are rooting for you. Several others have bet against you. The odds are not in your favor, financially speaking.",
    "We want to be clear that our enthusiasm for your survival is purely ratings-based. We feel nothing. We want to be clear about feeling nothing.",
    "We have assessed your shoes. The condition is concerning. We cannot tell you why this matters to us. It matters to us.",
    "Another crawler died nearby. We recorded it. The footage is more entertaining than your current actions. We are telling you this as constructive feedback.",
    "Fourteen seasons of this program. You are the first crawler to do that specific thing. We are updating our incident database.",
    "The Borant Corporation thanks you for your continued survival. Your suffering generates significant revenue. We mean this sincerely.",
    "We are running projections on your odds. We have stopped sharing the projections. You do not need to know the projections.",
    "A viewer in sector 7 is eating snacks specifically because of you. We consider this the highest form of compliment.",
    "Your heart rate, as detected by ambient bioscanners, is currently elevated. We find this both reasonable and entertaining.",
    "We have received seventeen thousand complaints that you are 'too competent'. We have also received nineteen thousand comments saying the opposite. We present this data without analysis.",
    "The dungeon is not impressed. The dungeon is, however, taking notes.",
    "We have been doing this for fourteen seasons. You remain surprising. We do not say that about many crawlers. We do not say it lightly.",
    "Borant Corporation Legal has flagged your recent actions as 'not covered by the standard liability waiver'. They are updating the waiver.",
    "Several galactic bookmakers have suspended betting on your survival. They say the odds have become 'computationally inconvenient'. We consider this a compliment.",
    "A child on a world in the Krix system is doing a school report on you. Their working title is 'The Person Who Did Not Die Yet'. We find this charming.",
    "We are legally required to inform you that the dungeon does not guarantee your safety. We are also legally required to inform you that this statement is extremely funny given where you currently are.",
    "Thirty-seven distinct alien cultures have a word that translates roughly to 'the strange one who keeps not dying'. In twelve of them, it is a compliment.",
    "We have reviewed the footage of your recent actions. Our editorial team described it as 'chaotic', 'inadvisable', and 'excellent television'. These are not mutually exclusive.",
    "The dungeon AI is watching you specifically. We know because the camera allocation data shows disproportionate focus on your location. We are not telling you what this means.",
    "An alien philosopher in the Tau-Vell system has been using your survival as a proof of concept in their dissertation on randomness. You are a footnote. A very famous footnote.",
    "We wish to clarify that the dungeon's danger rating on this floor was calibrated for average crawlers. You may have noticed you are affecting the average.",
    "The catering company that supplies the Borant executive viewing suites has reported running low on refreshments due to extended engagement. You are responsible for this. We mean it as a compliment.",
    "We have seventeen ways to describe what just happened. Fourteen of them involve words we cannot broadcast on fourteen star systems. The remaining three are: 'unprecedented', 'alarming', and 'wonderful'.",
    "The dungeon would like it noted that it is trying its best. The dungeon is a professional. The dungeon did not expect you specifically.",
    "A viewer who has watched every season since Season 1 sent a message. It reads: 'I have never seen anything like this.' They are 400 years old. We find their surprise gratifying.",
    "We are observing you with something that is not quite admiration and not quite concern. It is somewhere in the middle. We don't have a word for it. We're working on one.",
    "Ratings update: elevated. Specifically: very elevated. More specifically: the highest Floor [CURRENT FLOOR] numbers in eight seasons. We are sharing this for no particular reason.",
    "The dungeon's ambient systems have registered your presence. The correct response to this information is probably alarm.",
    "We note that several of the dungeon's enemy population have begun avoiding your general vicinity. This has historically preceded very good or very bad television. We cannot tell which yet.",
    "A galactic insurance company that covers dungeon-adjacent properties has quietly updated their actuarial tables to include a category labeled simply 'Crawler Influence'. You are why this category exists.",
    "We would like to take this moment to acknowledge that the dungeon was designed by the Borant Corporation's best engineers. We would also like to note that this is currently feeling like a mixed achievement.",
    "Several members of the dungeon's non-sapient animal population have begun behaving strangely. Xenobiologists on the broadcast team attribute this to 'environmental instability'. We are choosing to attribute it to you.",
    "The System has no opinion. The System is a system. The System is noting, purely for data purposes, that no prior crawler has done this. The System is, data-purposes-only, slightly impressed.",
    "We are contractually obligated to maintain neutrality. We are finding this contract increasingly difficult to honor.",
    "Your current survival duration falls in the 97th percentile for crawlers who entered in comparable condition. We present this statistic with what we want to be clear is purely professional interest.",
    "The Borant Corporation's entertainment division wishes you to know that your performance has exceeded projections. The projections were not optimistic. They have been revised upward. Twice.",
    "We have been informed that your story is being followed by a sentient gas cloud in the Nebula systems. It does not have eyes. It has nonetheless been described by adjacent entities as 'riveted'.",
    "You have done something the dungeon was not designed for. We are not saying what it is. We are saying the maintenance logs now include a category called 'unplanned crawler interactions'. The category has one entry."
)

$script:SystemBoredomPool = @(
    "VIEWERSHIP ALERT: Your last several actions have been rated TEDIOUS by galactic audiences. The algorithm is concerned.",
    "VIEWERSHIP CONCERN: Engagement metrics are trending in a direction that could charitably be described as 'downward'. Do something interesting.",
    "CONTENT ADVISORY: Several viewers have switched to watching a different crawler. The other crawler is currently fighting a golem with a fish. You are not fighting anything. With a fish or otherwise.",
    "AUDIENCE NOTE: The entertainment value of your current activity has been rated 2.1 out of 10 by the broadcast team. The scoring system goes up to 10. You should aim for higher.",
    "RATINGS ALERT: Three million viewers have opened secondary windows. The secondary windows are a compilation of best dungeon moments. None of the moments are from the current session."
)

# ============================================================
# ITEM DATABASE
# ============================================================
$script:ItemDB = @{
    # --- Weapons ---
    "pipe_wrench"       = @{ Name="Pipe Wrench";             Type="weapon"; Attack=6;  Value=5;   Rarity="common";
                              Desc="Heavy, reliable, extremely satisfying to connect.";
                              Lore="Manufactured by EarthCorp in 2019. Survived the Transformation. Now survives everything else." }
    "boxcutter"         = @{ Name="Box Cutter";              Type="weapon"; Attack=4;  Value=2;   Rarity="common";
                              Desc="Humble. Sharp. Gets in places a sword wouldn't.";
                              Lore="Originally used to open packages. Now opens other things." }
    "combat_knife"      = @{ Name="Combat Knife";            Type="weapon"; Attack=8;  Value=20;  Rarity="uncommon";
                              Desc="Military surplus. Well-balanced. Zero personality.";
                              Lore="Issued to 47 soldiers. 46 are dead. The last one sold it for 12 gold." }
    "shortsword"        = @{ Name="Shortsword";              Type="weapon"; Attack=10; Value=35;  Rarity="uncommon";
                              Desc="Standard dungeon blade. Adequate in all the ways that matter.";
                              Lore="Borant Standard Issue. Made on asteroid Vell-4 by workers who have never seen a fight." }
    "goblin_cleaver"    = @{ Name="Goblin Cleaver";          Type="weapon"; Attack=12; Value=55;  Rarity="uncommon";
                              Desc="Looted from a goblin warchief. Still has goblin residue.";
                              Lore="The goblin who owned this was called 'Retchface'. He earned the name." }
    "enchanted_bat"     = @{ Name="Enchanted Baseball Bat";  Type="weapon"; Attack=14; Value=80;  Rarity="rare";
                              Desc="Louisville Slugger with rune inscriptions. Crackles on critical hits.";
                              Lore="Enchanted by a wizard who really liked baseball. The runes say BATTER UP in Elvish." }
    "plasma_cutter"     = @{ Name="Plasma Cutter";           Type="weapon"; Attack=18; Value=140; Rarity="rare";
                              Desc="Industrial tool repurposed for violence. Melts through armor.";
                              Lore="Designed for hull maintenance. Discovered to work equally well on non-hull targets." }
    "rune_blade"        = @{ Name="Runic Blade";             Type="weapon"; Attack=22; Value=210; Rarity="epic";
                              Desc="Living runes that shift when unobserved. Hums constantly.";
                              Lore="The runes are an ancient contract. You are now party to it. Enjoy the benefits. Ignore the fine print." }
    "bossbane"          = @{ Name="Bossbane";                Type="weapon"; Attack=28; Value=400; Rarity="legendary"; BossBonus=10;
                              Desc="Deals amplified damage to bosses and elites. Legendary-tier.";
                              Lore="The Bossbane has killed 14 floor bosses across 9 seasons. The 15th boss doesn't know about this." }
    "jugs_o_boom"       = @{ Name="Carl's Jug O' Boom";     Type="weapon"; Attack=20; Value=100; Rarity="rare"; Explosive=$true;
                              Desc="Signature incendiary. Splash damage. Outstanding viewer engagement.";
                              Lore="Originally developed on Floor 1 of a previous season. The Borant Corporation tried to patent it. They cannot. This is a legal grey area." }
    "moldy_bread_ration"= @{ Name="Moldy Bread Ration";      Type="consumable"; HealHP=5; Value=1; Rarity="common";
                              Desc="Unpleasant. Functional. Floor 1 staple.";
                              Lore="Technically food. The definition of technically is doing a lot of work here." }
    # --- Armor ---
    "torn_jeans"        = @{ Name="Torn Jeans";              Type="armor";  Defense=1; Value=0;   Rarity="common";
                              Desc="Not armor. Starting equipment. We're sorry.";
                              Lore="Owned by approximately 2.3 million crawlers. You are one of them." }
    "leather_jacket"    = @{ Name="Leather Jacket";          Type="armor";  Defense=3; Value=15;  Rarity="common";
                              Desc="Marginal protection. Excellent aesthetic.";
                              Lore="Top-rated armor for Floors 1-2 for four consecutive seasons. The focus groups liked the vibe." }
    "riot_gear"         = @{ Name="Riot Gear Vest";          Type="armor";  Defense=6; Value=50;  Rarity="uncommon";
                              Desc="Salvaged police riot gear. Covers the important parts.";
                              Lore="Property of a department that no longer exists in a city that no longer exists on a planet that no longer exists." }
    "dungeon_plate"     = @{ Name="Dungeon Plate";           Type="armor";  Defense=9; Value=110; Rarity="rare";
                              Desc="Standard-issue crawler combat armor. Vending machine quality.";
                              Lore="Manufactured by Borant Crawler Outfitters. 'Helping you die presentably since Season 1.'" }
    "void_suit"         = @{ Name="Void Suit";               Type="armor";  Defense=14;Value=280; Rarity="epic";
                              Desc="Made from void creature carapace. Lightweight and unsettling.";
                              Lore="The creature this came from is still alive. Somewhere. It knows." }
    "crawler_exo"       = @{ Name="Crawler Exosuit";         Type="armor";  Defense=20;Value=500; Rarity="legendary";
                              Desc="Powered by a dungeon mana crystal. Endgame tier.";
                              Lore="Only three have ever been looted. Two of those crawlers made it past Floor 7. The third had it stolen on Floor 6 by a gnome." }
    # --- Consumables ---
    "health_potion"     = @{ Name="Health Potion";           Type="consumable"; HealHP=30;  Value=15; Rarity="common";
                              Desc="Standard red vial. Tastes like cherry cough syrup and regret.";
                              Lore="Borant Pharmaceutical Division. 'We make them as fast as you need them.'" }
    "mega_health"       = @{ Name="Mega Health Potion";      Type="consumable"; HealHP=70;  Value=45; Rarity="uncommon";
                              Desc="Large vial. Glows faintly red. Tastes worse than the small one.";
                              Lore="Contains the same ingredients as the regular potion. More of them. That's the innovation." }
    "stim_pack"         = @{ Name="Stim Pack";               Type="consumable"; HealHP=50; TempAtk=5; TempAtkTurns=3; Value=35; Rarity="uncommon";
                              Desc="Military stims. Heals and temporarily boosts attack for 3 turns.";
                              Lore="Side effects include: confidence, aggression, the feeling that you can handle anything. You probably cannot." }
    "mana_vial"         = @{ Name="Mana Vial";               Type="consumable"; HealMP=3;   Value=20; Rarity="uncommon";
                              Desc="A blue vial that tastes of static electricity. Restores 3 MP.";
                              Lore="Concentrated dungeon mana, bottled at a 1,200% markup. The mana is free. The bottle is $20." }
    "greater_mana"      = @{ Name="Greater Mana Potion";     Type="consumable"; HealMP=6;   Value=45; Rarity="rare";
                              Desc="Full mana restoration for most crawlers. Tastes of ozone and ambition.";
                              Lore="Favored by Occultist-class crawlers. Floor 3 witches make their own." }
    "antiparasitic"     = @{ Name="Antiparasitic";           Type="consumable"; HealHP=20;  Value=10; Rarity="common";
                              Desc="Cures Brindle Grub infestation. Unpleasant to take.";
                              Lore="You don't want to know why this item exists. You already know." }
    "energy_drink"      = @{ Name="Dungeon Energy Drink";    Type="consumable"; HealHP=15;  Value=8;  Rarity="common";
                              Desc="BLAM! ENERGY. Tastes like electricity. +1 speed for 2 turns.";
                              Lore="'For when you need to run away slightly faster than you currently can.'" }
    "sanity_tonic"      = @{ Name="Sanity Tonic";            Type="consumable"; HealMP=5; ClearsDebuff=$true; Value=30; Rarity="uncommon";
                              Desc="Clears mental debuffs. Tastes of nothing, which is itself unsettling.";
                              Lore="Specifically formulated for Floor 8. Borant didn't design Floor 8 to require this. They made it anyway." }
    "sponsors_box"      = @{ Name="Sponsor's Loot Box";      Type="lootbox";    BoxTier="silver"; Value=0; Rarity="rare";
                              Desc="Dropped by a generous subscriber. Silver tier contents.";
                              Lore="FROM: An anonymous viewer in the Krix system. They spent 40 galactic credits on this. They are watching right now." }
    "iron_loot_box"     = @{ Name="Iron Loot Box";           Type="lootbox";    BoxTier="iron";   Value=0; Rarity="common";
                              Desc="A humble iron box. Modest rewards.";
                              Lore="Starting gear bonus. 'We are legally required to give you this. We are not legally required to put anything good in it.'" }
    "bronze_box"        = @{ Name="Bronze Loot Box";         Type="lootbox";    BoxTier="bronze"; Value=0; Rarity="common";
                              Desc="A bronze box. Better odds than iron.";
                              Lore="Mid-tier viewer gift." }
    "gold_box"          = @{ Name="Gold Loot Box";           Type="lootbox";    BoxTier="gold";   Value=0; Rarity="rare";
                              Desc="A gold box. Excellent odds.";
                              Lore="High-tier sponsorship drop." }
    "celestial_box"     = @{ Name="Celestial Loot Box";      Type="lootbox";    BoxTier="celestial"; Value=0; Rarity="legendary";
                              Desc="A celestial box. Guaranteed high-value contents.";
                              Lore="CERTIFIED CELESTIAL TIER. YOU HAVE ACHIEVED SOMETHING REMARKABLE." }
    # --- Keys & Quest Items ---
    "transit_card"      = @{ Name="Transit Card";            Type="key";    Value=0;  Rarity="uncommon"; Desc="Opens transit gates on Floor 4."; Lore="Valid for one journey. Conditions apply. Conditions include 'you may die'." }
    "castle_banner_1"   = @{ Name="Gnome Fortress Banner";   Type="quest";  Value=100; Rarity="uncommon"; Desc="Proof: Gnome Fortress captured."; Lore="Smells faintly of gunpowder and gnomish pride." }
    "castle_banner_2"   = @{ Name="Sand Castle Banner";      Type="quest";  Value=100; Rarity="uncommon"; Desc="Proof: Sand Castle captured."; Lore="Still slightly sandy. Perpetually." }
    "castle_banner_3"   = @{ Name="Crypt Banner";            Type="quest";  Value=100; Rarity="uncommon"; Desc="Proof: Haunted Crypt captured."; Lore="Cold to the touch. Always." }
    "castle_banner_4"   = @{ Name="Submarine Banner";        Type="quest";  Value=100; Rarity="uncommon"; Desc="Proof: Submarine captured."; Lore="Smells like diesel and 30-year-old regret." }
    "monster_card"      = @{ Name="Monster Card (Blank)";    Type="quest";  Value=50;  Rarity="uncommon"; Desc="Floor 8 quest item. Capture a monster."; Lore="The card is warm. Something was almost inside it." }
    "hunters_trophy"    = @{ Name="Hunter's Trophy";         Type="quest";  Value=200; Rarity="rare";    Desc="Taken from a slain galactic hunter."; Lore="This humiliation is being broadcast to 47 star systems." }
    "core_fragment"     = @{ Name="System Core Fragment";    Type="quest";  Value=500; Rarity="legendary"; Desc="A shard of the dungeon's core AI."; Lore="It hums. It remembers. It is afraid." }
    # --- Crafting Materials ---
    "scrap_metal"       = @{ Name="Scrap Metal";             Type="craft";  Value=3;  Rarity="common";   Desc="Salvaged metal. Crafting component."; Lore="Formerly part of a building." }
    "chemical_jug"      = @{ Name="Chemical Jug";            Type="craft";  Value=5;  Rarity="common";   Desc="Industrial chemical container. Volatile."; Lore="Label reads: CAUTION - REACTIVE." }
    "explosive_gel"     = @{ Name="Explosive Gel";           Type="craft";  Value=15; Rarity="uncommon"; Desc="Sticky explosive compound."; Lore="Originally developed for mining. Now used for the opposite." }
    "dungeon_crystal"   = @{ Name="Dungeon Mana Crystal";    Type="craft";  Value=40; Rarity="rare";     Desc="Crystallized dungeon energy. High-tier crafting."; Lore="The crystal predates Earth. You're going to use it to make a potion." }
    "duct_tape"         = @{ Name="Duct Tape";               Type="craft";  Value=2;  Rarity="common";   Desc="Fixes most things. A universal constant."; Lore="Every sapient species in the known galaxy independently invented duct tape." }
    # --- Misc ---
    "donut_biscuit"     = @{ Name="Princess Donut's Biscuit"; Type="misc";  Value=0;  Rarity="legendary"; Desc="A blessed cat treat. +5 all stats for one fight."; Lore="From the personal collection of a legendary Crawler. DO NOT eat it." }
    "mordecai_scroll"   = @{ Name="Mordecai's Field Notes";   Type="misc";  Value=0;  Rarity="common";   Desc="Advice from your guide for the current floor."; Lore="Handwritten by an extremely tired guide who has watched too many crawlers die." }
    "lockpick"          = @{ Name="Lockpick Set";             Type="misc";  Value=20; Rarity="uncommon";  Desc="For opening things you shouldn't."; Lore="'These are for legitimate locksmithing only.' Nobody believed the vendor." }
    # --- Maps (auto-applied on pickup, reveal mini-map area) ---
    "map_neighborhood"  = @{ Name="Neighborhood Map";   Type="map"; Value=50;  Rarity="uncommon"; Desc="Reveals nearby rooms on the mini-map.";          Lore="Hand-drawn. Surprisingly accurate." }
    "map_borough"       = @{ Name="Borough Map";        Type="map"; Value=100; Rarity="rare";     Desc="Reveals a borough worth of rooms on the mini-map."; Lore="Printed before the dungeon existed. Updated since." }
    "map_city"          = @{ Name="City Map";           Type="map"; Value=200; Rarity="epic";     Desc="Reveals a large area on the mini-map.";           Lore="Annotated by previous crawlers who didn't make it. Their notes are helpful." }
    "map_province"      = @{ Name="Province Map";       Type="map"; Value=400; Rarity="legendary";Desc="Reveals most of the floor on the mini-map.";       Lore="One of only four printed. Borant keeps the others." }
    "map_country"       = @{ Name="Country Map";        Type="map"; Value=800; Rarity="legendary";Desc="Reveals the entire floor on the mini-map.";        Lore="Complete floor schematic. Only dropped by the rarest bosses." }
}

# ============================================================
# ENEMY DATABASE  (CanTalk + DialogueId for intelligent mobs)
# ============================================================
$script:EnemyDB = @{
    # Floor 1-2
    "exploding_goblin"  = @{ Name="Exploding Goblin";    MaxHP=20; Attack=5;  Defense=1; Speed=3; XP=15; Gold=@(1,5);   Floor=1; Type="goblin";
                              CanTalk=$true; DialogueId="goblin_basic"
                              Desc="A goblin strapped with low-grade explosive.";
                              Special="Detonate"; SpecialChance=25; SpecialDesc="It panics and detonates! Area damage!" }
    "cave_crawler"      = @{ Name="Cave Crawler";         MaxHP=15; Attack=4;  Defense=2; Speed=4; XP=10; Gold=@(0,3);   Floor=1; Type="beast";
                              Desc="Many-legged insectoid. Skitters out of collapsed concrete." }
    "feral_dog"         = @{ Name="Feral Dog";            MaxHP=22; Attack=6;  Defense=1; Speed=5; XP=18; Gold=@(0,2);   Floor=1; Type="beast";
                              Desc="Dungeon-mutated dog. Very bitey. Faster than it looks." }
    "brindle_grub"      = @{ Name="Brindle Grub";         MaxHP=8;  Attack=3;  Defense=0; Speed=2; XP=5;  Gold=@(0,1);   Floor=2; Type="beast";
                              Desc="Writhing grub spawned from corpses. Harmless alone."; Swarm=$true }
    "mutant_rat"        = @{ Name="Mutant Sewer Rat";     MaxHP=18; Attack=5;  Defense=1; Speed=5; XP=12; Gold=@(0,3);   Floor=2; Type="beast";
                              Desc="Rat, but larger. Glowing green eyes." }
    "sewer_golem"       = @{ Name="Sewer Golem";          MaxHP=55; Attack=10; Defense=5; Speed=1; XP=50; Gold=@(10,20); Floor=2; Type="construct";
                              Desc="Compacted sewage animated by dungeon energy. Smells exactly as expected." }
    # Floor 3
    "undead_clown"      = @{ Name="Undead Circus Clown";  MaxHP=35; Attack=9;  Defense=2; Speed=4; XP=35; Gold=@(3,10);  Floor=3; Type="undead";
                              Desc="Part of the undead circus. Armed with razor-edged plates.";
                              Special="Barrage"; SpecialChance=30; SpecialDesc="Plate barrage! Multiple hits!" }
    "corrupted_cop"     = @{ Name="Corrupted Cop";        MaxHP=40; Attack=10; Defense=4; Speed=3; XP=40; Gold=@(5,15);  Floor=3; Type="undead";
                              CanTalk=$true; DialogueId="corrupted_cop_talk"
                              Desc="Reanimated officer. The radio still works. The voice on it is wrong." }
    "city_wraith"       = @{ Name="City Wraith";          MaxHP=30; Attack=12; Defense=6; Speed=5; XP=55; Gold=@(8,20);  Floor=3; Type="undead";
                              Desc="Translucent horror. Paralyzes on touch.";
                              Special="Phase Touch"; SpecialChance=35; SpecialDesc="Paralytic touch! You lose your next action!" }
    "circus_bear"       = @{ Name="Undead Circus Bear";   MaxHP=80; Attack=16; Defense=6; Speed=2; XP=90; Gold=@(15,30); Floor=3; Type="undead"; IsBoss=$true; BossType="neighborhood";
                              Desc="Massive undead bear in a circus costume. Still wearing the fez. Boss." }
    # Floor 4
    "train_goblin"      = @{ Name="Train Goblin";         MaxHP=28; Attack=8;  Defense=2; Speed=4; XP=30; Gold=@(3,8);   Floor=4; Type="goblin";
                              CanTalk=$true; DialogueId="goblin_basic"
                              Desc="Rail-riding goblin gang. Throws improvised weapons." }
    "conductor_lich"    = @{ Name="Conductor Lich";       MaxHP=45; Attack=13; Defense=4; Speed=3; XP=65; Gold=@(10,25); Floor=4; Type="undead";
                              CanTalk=$true; DialogueId="conductor_lich_talk"
                              Desc="Undead train conductor. Announces your death over the intercom first.";
                              Special="Lightning Rail"; SpecialChance=30; SpecialDesc="Lightning down the track! Electric damage!" }
    "iron_golem"        = @{ Name="Iron Rail Golem";      MaxHP=75; Attack=14; Defense=9; Speed=1; XP=85; Gold=@(10,20); Floor=4; Type="construct";
                              Desc="Built from the tracks themselves." }
    "tangle_boss"       = @{ Name="The Iron Conductor";   MaxHP=180;Attack=20; Defense=8; Speed=4; XP=300;Gold=@(80,120);Floor=4; Type="construct"; IsBoss=$true; BossType="borough";
                              Desc="Sentient AI controlling the Iron Tangle. Offended by your presence. Boss.";
                              Special="Rail Crush"; SpecialChance=35; SpecialDesc="The tracks rearrange and strike! Massive damage!" }
    # Floor 5
    "war_gnome"         = @{ Name="War Gnome";            MaxHP=35; Attack=10; Defense=4; Speed=3; XP=40; Gold=@(5,12);  Floor=5; Type="gnome";
                              CanTalk=$true; DialogueId="war_gnome_talk"
                              Desc="Battle-hardened gnome in full plate. Do not underestimate." }
    "sand_elemental"    = @{ Name="Sand Elemental";       MaxHP=50; Attack=11; Defense=3; Speed=4; XP=55; Gold=@(5,15);  Floor=5; Type="elemental";
                              Desc="Whirling column of animated sand.";
                              Special="Sandblast"; SpecialChance=30; SpecialDesc="Sandblast! Reduces your accuracy!" }
    "crypt_guardian"    = @{ Name="Crypt Guardian";       MaxHP=40; Attack=13; Defense=5; Speed=2; XP=60; Gold=@(8,18);  Floor=5; Type="undead";
                              CanTalk=$true; DialogueId="crypt_guardian_talk"
                              Desc="Ancient guardian. Will not yield. Has been here a very long time." }
    "broken_machine"    = @{ Name="Broken War Machine";   MaxHP=65; Attack=15; Defense=7; Speed=2; XP=80; Gold=@(10,22); Floor=5; Type="construct";
                              Desc="Malfunctioning military machine. Targets everything." }
    "gnome_king"        = @{ Name="Gnome King Gorbrock";  MaxHP=200;Attack=18; Defense=10;Speed=3; XP=350;Gold=@(80,100);Floor=5; Type="gnome"; IsBoss=$true; BossType="borough";
                              Desc="King of war gnomes. Rides a mechanical battle-elk. Boss.";
                              Special="Cannon Volley"; SpecialChance=30; SpecialDesc="Cannon volley! Massive damage!" }
    # Floor 6
    "jungle_raptor"     = @{ Name="Jungle Raptor";        MaxHP=45; Attack=13; Defense=3; Speed=7; XP=55; Gold=@(0,5);   Floor=6; Type="beast";
                              Desc="Fast, pack-hunting raptor.";
                              Special="Pack Strike"; SpecialChance=35; SpecialDesc="The pack converges!" }
    "galactic_hunter"   = @{ Name="Galactic Hunter";      MaxHP=60; Attack=16; Defense=6; Speed=4; XP=100;Gold=@(30,60); Floor=6; Type="hunter";
                              CanTalk=$true; DialogueId="galactic_hunter_talk"
                              Desc="Wealthy tourist who paid to hunt crawlers. Has better equipment than you.";
                              Special="Trophy Shot"; SpecialChance=25; SpecialDesc="Called shot! High-damage precision strike!" }
    "apex_predator"     = @{ Name="Apex Predator";        MaxHP=90; Attack=18; Defense=8; Speed=5; XP=130;Gold=@(20,40); Floor=6; Type="beast"; IsBoss=$true; BossType="neighborhood";
                              Desc="Dungeon-evolved megafauna. Crown predator of the Hunting Grounds." }
    "elite_hunter_vrah" = @{ Name="Elite Hunter Vrah";    MaxHP=250;Attack=24; Defense=12;Speed=6; XP=500;Gold=@(150,200);Floor=6;Type="hunter"; IsBoss=$true; BossType="city";
                              Desc="Vrah. Galaxy's most feared trophy hunter. Here for you specifically.";
                              Special="Hunter's Mark"; SpecialChance=40; SpecialDesc="Hunter's Mark! You take 50% more damage!" }
    # Floor 7
    "arena_thug"        = @{ Name="Arena Thug";           MaxHP=55; Attack=14; Defense=5; Speed=3; XP=65; Gold=@(8,18);  Floor=7; Type="human";
                              CanTalk=$true; DialogueId="arena_thug_talk"
                              Desc="Crawler who gave up escape and became a dungeon enforcer." }
    "frenzy_beast"      = @{ Name="Frenzied Beast";       MaxHP=70; Attack=18; Defense=4; Speed=6; XP=90; Gold=@(5,15);  Floor=7; Type="beast";
                              Desc="Buffed by the Frenzy mechanic. Attacks twice per round.";
                              Special="Double Strike"; SpecialChance=100; SpecialDesc="Frenzy! Attacks twice!" }
    "gladiator_boss"    = @{ Name="Champion Gladiator";   MaxHP=220;Attack=22; Defense=12;Speed=4; XP=400;Gold=@(80,120);Floor=7; Type="human"; IsBoss=$true; BossType="borough";
                              Desc="Undefeated champion of Floor 7. Fights for the crowd.";
                              Special="Showstopper"; SpecialChance=35; SpecialDesc="Showstopper! The crowd ROARS! Massive damage!" }
    # Floor 8
    "ghost_crawler"     = @{ Name="Ghost Crawler";        MaxHP=40; Attack=12; Defense=8; Speed=5; XP=70; Gold=@(5,15);  Floor=8; Type="undead";
                              CanTalk=$true; DialogueId="ghost_crawler_talk"
                              Desc="Ghost of a crawler who didn't make it. Still fighting." }
    "folklore_horror"   = @{ Name="Folklore Horror";      MaxHP=65; Attack=16; Defense=5; Speed=4; XP=100;Gold=@(10,25); Floor=8; Type="legend";
                              Desc="Human myth given physical form.";
                              Special="Madness Touch"; SpecialChance=30; SpecialDesc="Madness Touch! Drains MP and scrambles commands!" }
    "bedlam_bride"      = @{ Name="Shi Maria, Bedlam Bride";MaxHP=300;Attack=26;Defense=14;Speed=5;XP=600;Gold=@(100,150);Floor=8;Type="legend";IsBoss=$true; BossType="city";
                              Desc="Married a god. He's gone. She's here.";
                              Special="Bedlam Aura"; SpecialChance=40; SpecialDesc="Bedlam Aura! ATK+8, DEF-6 this turn!" }
    # Floor 9
    "faction_soldier"   = @{ Name="Faction Soldier";      MaxHP=65; Attack=16; Defense=7; Speed=3; XP=80; Gold=@(10,20); Floor=9; Type="faction";
                              CanTalk=$true; DialogueId="faction_soldier_talk"
                              Desc="Soldier from one of the nine galactic factions." }
    "faction_mage"      = @{ Name="Faction Battle Mage";  MaxHP=50; Attack=20; Defense=4; Speed=4; XP=100;Gold=@(15,30); Floor=9; Type="faction";
                              Desc="Magic-wielding faction combatant.";
                              Special="Arc Blast"; SpecialChance=35; SpecialDesc="Arc Blast! Lightning damage!" }
    "faction_general"   = @{ Name="Gen. Kralos";          MaxHP=280;Attack=26; Defense=14;Speed=3; XP=550;Gold=@(120,160);Floor=9;Type="faction";IsBoss=$true; BossType="province";
                              Desc="General of the most powerful faction. 200 years of war.";
                              Special="Command Strike"; SpecialChance=30; SpecialDesc="Command Strike! Calls reinforcements AND attacks!" }
    # Floor 10
    "system_construct"  = @{ Name="System Construct";     MaxHP=80; Attack=22; Defense=10;Speed=5; XP=120;Gold=@(20,40); Floor=10;Type="system";
                              Desc="AI-generated combat construct. Perfect form. Eerily silent." }
    "rogue_ai_shard"    = @{ Name="Rogue AI Shard";       MaxHP=60; Attack=18; Defense=12;Speed=6; XP=100;Gold=@(15,30); Floor=10;Type="system";
                              Desc="Fragment of the core AI given physical form.";
                              Special="Data Spike"; SpecialChance=35; SpecialDesc="Data Spike! Bypasses defense entirely!" }
    "dungeon_ai_core"   = @{ Name="The System - Core Instance";MaxHP=500;Attack=30;Defense=18;Speed=6;XP=1000;Gold=@(300,500);Floor=10;Type="system";IsBoss=$true; BossType="country";
                              Desc="The dungeon AI gone fully rogue.";
                              Special="System Override"; SpecialChance=40; SpecialDesc="System Override! Resets your buffs and heals the Core!"; HealSelf=20 }
}

# ============================================================
# DIALOGUE DATABASE  (Fallout-style NPC conversations)
# ============================================================
$script:DialogueDB = @{
    "goblin_basic" = @{
        Greeting = "The goblin freezes. Its fuse sparks nervously. It stares at you with enormous yellow eyes. 'You... you stop right there,' it says in broken English. 'Goblin not want to explode. Goblin just want to find snacks.'"
        Options = @(
            @{ Text="I'll leave you alone. Just passing through."; Outcome="neutral"; GoldCost=0;
               Response="The goblin squints for a long time. 'Fine,' it says finally. 'But if you come back, KABOOM.' It backs away, fuse still sparking, and disappears around a corner." }
            @{ Text="[BRIBE] Here's some gold. Go away."; Outcome="bribe"; GoldCost=5;
               Response="The goblin's eyes go round. It snatches the gold with small quick hands. 'Deal! Deal deal deal!' It runs. You can hear it celebrating around two more corners." }
            @{ Text="[INTIMIDATE] I've killed twelve goblins today. You'd be thirteen."; Outcome="flee"; StatRequired="STR"; StatMin=5;
               Response="The goblin looks at you. It looks at its explosive vest. It makes a decision entirely consistent with self-preservation and runs at full speed." }
            @{ Text="I'd actually like to fight you."; Outcome="combat"; StartsConflict=$true;
               Response="The goblin's fuse ignites fully. 'THEN GOBLIN FIGHT!' The negotiation window has closed." }
        )
    }
    "corrupted_cop_talk" = @{
        Greeting = "The corrupted officer turns slowly. Its radio hisses with static and something that might be a voice on the wrong frequency. Its eyes glow dull red. 'Citizen,' it says, in a voice like a recording played at the wrong speed. 'This area is... under... jurisdiction.'"
        Options = @(
            @{ Text="I don't want trouble. I'm just passing through."; Outcome="neutral"; GoldCost=0;
               Response="The cop twitches. The radio crackles. 'Move... along,' it says finally. 'Slowly.' Something about that voice suggests it's trying to remember what that phrase is supposed to mean." }
            @{ Text="[PERSUADE] The dungeon corrupted you. You don't have to do this."; Outcome="flee"; StatRequired="CHA"; StatMin=5;
               Response="The cop is quiet for a long time. The radio produces something that sounds like it might once have been words. Then it turns and walks away, slowly, in the direction of nothing in particular." }
            @{ Text="[INTIMIDATE] Stand down, officer."; Outcome="neutral"; StatRequired="STR"; StatMin=6;
               Response="A long pause. Whatever's left in there recognizes the command structure. 'Complying,' it says. It steps aside. The radio makes a sound like an old dispatcher saying copy." }
            @{ Text="Fight."; Outcome="combat"; StartsConflict=$true;
               Response="The cop's hand moves to its weapon. The radio crackles once. Then combat." }
        )
    }
    "conductor_lich_talk" = @{
        Greeting = "The Conductor Lich looks up from its clipboard. 'You are traveling without a valid fare,' it says, in the practiced tone of someone who has said this several thousand times and finds it no less relevant each time. Its eye sockets glow with pale blue light."
        Options = @(
            @{ Text="Here's my transit card."; Outcome="neutral"; RequiresItem="transit_card";
               Response="The Lich examines the card with bony fingers. 'Valid. Single journey. This stop and return.' It punches the card with a hole punch that appears from nowhere. 'Next train in four minutes. Platform is that way.' It goes back to its clipboard." }
            @{ Text="I'll buy a ticket. How much?"; Outcome="bribe"; GoldCost=15;
               Response="The Lich considers this. 'The rate for unscheduled passengers is fifteen gold.' It produces a ticket from within its robes. 'Keep this.' It looks at you. 'The Tangle respects transit etiquette. You may find this useful.'" }
            @{ Text="[INTIMIDATE] This seems like a good track to get off of."; Outcome="flee"; StatRequired="STR"; StatMin=7;
               Response="The Lich looks at you, then at the clipboard, then makes a notation. 'Unruly passenger. Route to alternate line.' It gestures. A door opens that wasn't there before. 'This way.'" }
            @{ Text="Let's fight about it."; Outcome="combat"; StartsConflict=$true;
               Response="'Fare evasion now escalating to hostile conduct.' The Lich puts away its clipboard. 'This has been noted in your record.'" }
        )
    }
    "war_gnome_talk" = @{
        Greeting = "The war gnome plants its halberd in the ground with a clang. It tilts its head back to look up at you. Its expression is one of extremely contained fury. 'Halt,' it says, in a voice that suggests it has been in charge of things and intends to remain so."
        Options = @(
            @{ Text="[RESPECT] I respect your fortress. I respect your King."; Outcome="neutral"; StatRequired="CHA"; StatMin=4;
               Response="The gnome's eyes narrow. A very long pause. 'You speak with knowledge of gnomish honor protocols,' it says finally. 'Unusual. In a large person.' Another pause. 'You may pass this position. Do not test this decision.'" }
            @{ Text="Tell me about King Gorbrock."; Outcome="info"; GoldCost=0;
               Response="'The King is a tactical genius,' the gnome says, with absolute conviction. 'He has never lost a siege. His battle-elk has never been bested.' It squares its tiny shoulders. 'He also says your boots are ugly. He saw you from the battlements. He told me specifically.'" }
            @{ Text="[BRIBE] Gold."; Outcome="bribe"; GoldCost=10;
               Response="The gnome looks at the gold. It looks at its halberd. 'Gnomish honor does not accept bribes,' it says. Then it takes the gold. 'This is a fortification fee. It is completely different.' It steps aside." }
            @{ Text="Fight."; Outcome="combat"; StartsConflict=$true;
               Response="'I was hoping you would say that,' the gnome says, with a smile that is too wide for its face. It retrieves its halberd." }
        )
    }
    "crypt_guardian_talk" = @{
        Greeting = "The ancient guardian turns. It moves slowly, with the deliberate patience of something that has been waiting for a very long time. When it speaks, its voice sounds like stone trying to remember how to make sound. 'I am sorry,' it says. 'This is my duty.'"
        Options = @(
            @{ Text="[COMPASSION] You've been here alone for centuries."; Outcome="flee"; StatRequired="CHA"; StatMin=4;
               Response="The guardian is silent. Something shifts in its ancient face. 'No one has said that before,' it says finally, in a voice barely above silence. 'They only fight.' Another long pause. 'Take the banner. I am... tired. I have been tired for a very long time.'" }
            @{ Text="[LORE] Who placed you here?"; Outcome="info"; GoldCost=0;
               Response="'A priest,' it says. 'Long ago. He said: guard this until I return.' Its voice is careful, like it's reading from something. 'He has not returned.' A pause. 'I no longer believe he will.' It doesn't move. 'But duty is duty.'" }
            @{ Text="Let me pass in peace."; Outcome="neutral"; StatRequired="CHA"; StatMin=6;
               Response="'I cannot. The duty does not allow it.' It looks at you with something like apology. 'I am sorry. Truly. But I have one task in this existence and I intend to fulfill it.'" }
            @{ Text="I'll fight you."; Outcome="combat"; StartsConflict=$true;
               Response="'Then we fight.' Something in its posture suggests it finds this sad. 'So it has always been.'" }
        )
    }
    "galactic_hunter_talk" = @{
        Greeting = "The galactic hunter lowers its weapon fractionally. It looks at you with the professional assessment of someone who has tracked prey across seven systems. 'You're more interesting up close,' it says. 'The dossier didn't capture it.'"
        Options = @(
            @{ Text="You don't have to do this. Leave and I'll forget you were here."; Outcome="neutral"; StatRequired="CHA"; StatMin=5;
               Response="The hunter considers this. 'I paid twelve thousand galactic credits for this hunt.' A pause. 'You're worth more than that as a story.' It lowers the weapon fully. 'I'll log you as escaped. The ratings from this conversation will cover the refund.' It walks away." }
            @{ Text="[INTIMIDATE] I've killed three hunters already. Choose differently."; Outcome="flee"; StatRequired="STR"; StatMin=6;
               Response="The hunter reassesses. 'Three?' It checks something on its equipment. 'That's... verifiable.' It backs up a step. 'Quarry reassessed. Disengaging.' It doesn't run. But it goes." }
            @{ Text="[BRIBE] Take the gold and report me as dead."; Outcome="bribe"; GoldCost=20;
               Response="'That's a creative approach.' It takes the gold. 'You were killed by a raptor. Tragic. I have witnesses.' It pockets the money. 'Excellent instincts. You might have been a hunter in another life.'" }
            @{ Text="Let's do this properly."; Outcome="combat"; StartsConflict=$true;
               Response="'Now we're talking.' The hunter raises its weapon. 'This will be worth the broadcast rights.'" }
        )
    }
    "arena_thug_talk" = @{
        Greeting = "The arena thug rolls its neck. It's assessing you. There's something recognizably human in there -- tired, compromised, but present. 'You're new,' it says. 'Haven't seen you in the rankings yet.'"
        Options = @(
            @{ Text="I don't want to fight you. There's enough dying here."; Outcome="neutral"; StatRequired="CHA"; StatMin=4;
               Response="The thug snorts. But it steps back. 'Smart. Most newcomers go straight for the ranking.' It spits. 'Floor 7 doesn't need more bodies. It's got plenty.' It walks away, but not before a backward glance that might be respect." }
            @{ Text="[INFORMATION] Tell me about the Champion."; Outcome="info"; GoldCost=0;
               Response="'The Champion's been here since Season 11. That's a long time to not die.' The thug leans against a wall. 'They fight clean. No theatrics, no crowd-playing. Just ending things efficiently.' It looks at you. 'Most challengers lose in under two minutes. Just so you know.'" }
            @{ Text="[BRIBE] I'll pay you to look the other way."; Outcome="bribe"; GoldCost=10;
               Response="'Smart.' It takes the gold. 'I work for the ranking board. They pay me to generate kills, not to pick them.' It pockets the money. 'You were never here.' It walks the other direction." }
            @{ Text="Let's add to the count."; Outcome="combat"; StartsConflict=$true;
               Response="'Your funeral.' It raises its weapon. 'At least it'll be a good show.'" }
        )
    }
    "ghost_crawler_talk" = @{
        Greeting = "The ghost turns. It recognizes you as something that isn't dead yet -- you can tell because its expression shifts to something between warning and envy. 'Still alive,' it says. Not a question. 'You shouldn't be here. Nobody should be here.'"
        Options = @(
            @{ Text="[KINDNESS] I'm sorry you didn't make it."; Outcome="flee"; StatRequired="CHA"; StatMin=3;
               Response="The ghost is quiet. Something softens in its insubstantial face. 'Nobody's said that.' A pause. 'Not once in however long I've been here.' It drifts back. 'Go. Before you end up like me. The dungeon... it doesn't let go.'" }
            @{ Text="Tell me what's ahead."; Outcome="info"; GoldCost=0;
               Response="'Bedlam gets worse toward the center. The Bride's influence is everywhere.' It flickers. 'The folklore horrors are real -- every fear you brought in with you is somewhere in this floor.' A pause. 'I'm afraid of being forgotten. I expect you can guess how that worked out.'" }
            @{ Text="[LORE] What floor did you die on?"; Outcome="neutral"; StatRequired="CHA"; StatMin=3;
               Response="'This one. Floor 8.' It looks at its hands. 'The Bride's aura made me reckless. I charged something I shouldn't have.' A long pause. 'The floor holds you if you die on it. I didn't know that.' It looks at you. 'Now you know.'" }
            @{ Text="I don't have time for this."; Outcome="combat"; StartsConflict=$true;
               Response="The ghost's expression closes. 'Then make time for this instead.' The encounter begins." }
        )
    }
    "faction_soldier_talk" = @{
        Greeting = "The faction soldier raises a fist -- a universal halt gesture, it seems, even in alien military traditions. It studies you. 'Crawler,' it says, in accented but clear English. 'You fight for no faction. Unusual. Interesting.'"
        Options = @(
            @{ Text="I fight for myself and the people with me."; Outcome="neutral"; StatRequired="CHA"; StatMin=4;
               Response="The soldier considers this for a moment that feels longer than it is. 'A coherent position.' It lowers its weapon. 'My faction fights for territory. You fight for people.' Another pause. 'This floor, these things are different from each other.' It steps aside. 'Go.'" }
            @{ Text="[PERSUADE] Join us. The crawler army has room."; Outcome="flee"; StatRequired="CHA"; StatMin=6;
               Response="'That is...' The soldier stops. Looks at its faction insignia. Looks at you. 'The crawler army.' It's processing something. 'NPCs fighting for a crawler. For no faction.' It makes a decision that seems surprising even to itself. 'I will... think about this.' It retreats. This counts as an escape." }
            @{ Text="[INFORMATION] Tell me about Kralos's strategy."; Outcome="info"; GoldCost=0;
               Response="'The General pushes from the northeast. He wants the castle in three days.' The soldier looks around. 'He doesn't know about your army's western flank move. That's his blind spot.' A pause. 'Why am I telling you this.' It seems genuinely uncertain. 'Because you asked without hostility. That's rare here.'" }
            @{ Text="Fight."; Outcome="combat"; StartsConflict=$true;
               Response="'Then we fight.' The soldier raises its weapon. 'Nothing personal, crawler.'" }
        )
    }
    "mordecai_safe_room" = @{
        Greeting = "Mordecai looks up. His current form's expression does the thing it does -- different each floor, but always that specific combination of professional tiredness and something that might be relief at seeing you still in one piece."
        Options = @()  # Populated dynamically from MordecaiDialogue
    }
}

# ============================================================
# OPENING SEQUENCES  (pre-game canned scenarios)
# ============================================================
$script:OpeningSequences = @(
    @{
        Title = "The Office"
        Location = "Hanover Insurance Group -- 14th Floor Conference Room, Seattle, WA"
        Text = @"
The quarterly review meeting has been going for forty-seven minutes and you have retained approximately none of it.

Outside the floor-to-ceiling windows, Seattle is being Seattle: gray, drizzly, full of people with coffee cups and opinions about coffee. Your laptop screensaver kicks in. Your phone is on silent. The CFO is saying something about synergies.

Then the floor shakes.

Not the building. The floor. Like the ground itself has decided it has somewhere better to be.

The city outside doesn't fall. It sinks. Building by building, block by block, the entire Seattle street grid descends smoothly into the earth, leaving only the dungeon floor -- rough stone, glowing faintly blue -- where the city used to be.

In the center of the conference room, where the projector screen was, there is now a staircase going down.

Glowing text appears in the air:

WELCOME TO DUNGEON CRAWLER WORLD.
EARTH HAS BEEN RELOCATED.
FIND THE STAIRCASE.
YOU HAVE 5 DAYS.

The CFO says something about Q4 projections. He is talking to nobody. He has also become part of the dungeon floor in a way that is medically alarming.

The staircase pulses.
"@
    }
    @{
        Title = "The Commute"
        Location = "Highway 99 Northbound -- Dead Stop Traffic, 8:47 AM"
        Text = @"
You've been in this traffic for forty-three minutes. The car in front of you hasn't moved. The podcast you were listening to has cycled through all its ads twice. You've had exactly enough coffee to be awake enough to be annoyed.

The traffic report on the radio says: delays due to incident.

The incident, you are about to discover, is that Earth has ended.

It happens all at once. The highway, the cars ahead and behind you, the entire Seattle skyline -- all of it descends into the earth smoothly, like a very large elevator with excellent shock absorbers. The other drivers are gone. Their cars are gone. You are sitting in your car on a dungeon floor.

Where the highway was, there is stone. Where the skyline was, there is stone. Where the traffic jam was, there is stone with a glowing blue staircase descending into it.

Text appears above the staircase:

WELCOME TO DUNGEON CRAWLER WORLD.
EARTH HAS BEEN RELOCATED.
YOUR COMMUTE HAS BEEN PERMANENTLY CANCELLED.
FIND THE STAIRCASE.

You sit in your car for approximately three seconds.

The staircase pulses. Your car, you notice, has also become part of the dungeon floor.

At least there's no traffic.
"@
    }
    @{
        Title = "The Grocery Store"
        Location = "QFC Supermarket -- Frozen Foods Aisle -- 6:23 PM"
        Text = @"
You're deciding between two brands of frozen pizza when the world ends.

The choice was more difficult than it should have been. One is cheaper. One has better reviews. You've been standing here for four minutes, which is three minutes longer than this decision deserves. This is the most mundane possible moment to be in when Earth is absorbed into an alien dungeon system.

The fluorescent lights flicker once and then switch to something that glows blue and inexplicable.

The frozen pizza is gone. The freezer case is gone. The entire supermarket is gone except the floor, which has become rough stone. You are standing on a dungeon floor holding nothing because you never actually picked up the pizza.

The other shoppers are gone. The cart full of someone's week's groceries is gone. A glowing staircase has appeared where the bread aisle used to be.

Text in the air:

WELCOME TO DUNGEON CRAWLER WORLD.
EARTH HAS BEEN RELOCATED.
YOUR SHOPPING HAS BEEN INTERRUPTED.
FIND THE STAIRCASE.

You look at where the frozen pizza was.

The staircase pulses.
"@
    }
    @{
        Title = "The Apartment"
        Location = "Your Apartment -- 11:34 PM -- Can't Sleep"
        Text = @"
You're on the couch at 11:34 PM watching something you've seen before because you couldn't sleep and this required zero decisions.

The TV is making noise. You're not listening. Outside, the city sounds like it always does at this hour -- distant traffic, occasional voices, the ambient hum of civilization going about its business.

Then the ambient hum of civilization stops.

All at once. Mid-sound. Like someone pressed mute on the world outside.

The TV goes to static, then off. The apartment lights die. The window, which used to show city lights, shows nothing now -- no city, no sky, just darkness.

Then the floor glows.

Blue light comes up through the floorboards. Through the carpet. Through everything below you. The floor doesn't break. It just starts glowing, and then gradually you realize you can see through it -- down through the floor, through what used to be the building's foundation, into the dungeon below.

Where the wall was, a staircase has appeared. Glowing. Waiting.

Text in the air:

WELCOME TO DUNGEON CRAWLER WORLD.
YOU HAVE BEEN SELECTED.
EARTH HAS BEEN RELOCATED.
FIND THE STAIRCASE.

The TV comes back on for exactly one second to display the same message and then shuts off permanently.

The staircase pulses.
"@
    }
    @{
        Title = "The Hiking Trail"
        Location = "Tiger Mountain State Forest -- 2:15 PM"
        Text = @"
You're forty minutes up the trail when Earth ends.

The trees are doing what they usually do. The trail is doing what it usually does. A squirrel is giving you a look that suggests it had opinions about your presence before any of this happened.

The end of Earth is quieter than you'd expect. No impact, no sound. The ground just shifts, very slightly, like a held breath finally releasing. The trees are gone. The squirrel is gone. The trail is gone.

You are standing on a dungeon floor with your hiking boots and a water bottle and nowhere particular to go.

All around you: stone. Rough, ancient, slightly luminescent. The sky above has been replaced with a ceiling you can't see the top of. The air smells of old stone and something that might be ozone.

Where the trail continued: a glowing staircase.

Text appears:

WELCOME TO DUNGEON CRAWLER WORLD.
EARTH HAS BEEN RELOCATED.
YOUR HIKE HAS TAKEN AN UNEXPECTED TURN.
FIND THE STAIRCASE.

The squirrel is, somehow, still there.

It looks at the staircase. It looks at you.

It appears to be waiting to see what you do.
"@
    }
)

# ============================================================
# ROOM DATABASE
# ============================================================
$script:RoomDB = @{

    # === FLOOR 1: COLLAPSED SURFACE ===
    "f1_tutorial_guild" = @{
        Name="Tutorial Guild Hall - Entry"; Floor=1; Visited=$false; IsSafeRoom=$true; IsTutorial=$true
        Desc="The building materialized out of nothing. One second it wasn't here; the next it was, perfectly intact -- warm stone, good light, and the smell of something that might be bread. A ratkin about four feet tall in a guild vest stands behind a reception desk. His whiskers are twitching. His eyes are very large. His name, a small sign informs you, is MORDECAI. He looks up. He looks like he has been waiting for you. He has, in a sense."
        Exits=@{south="f1_spawn"}
        Items=@("mordecai_scroll"); Enemies=@()
        Interactables=@{
            "sign"     = @{ Name="Guild Notice Board"; Desc="Covered in laminated notices in seventeen languages. One says: LOOT BOXES: SAFE ROOMS ONLY. Another says: RESTING: SAFE ROOMS ONLY. A third says: MORDECAI IS NOT YOUR ENEMY. A fourth says: YES HE KNOWS ABOUT THE FEET THING."; Outcome="none" }
            "terminal" = @{ Name="Status Terminal"; Desc="A glowing screen shows your current stats. Your HP, MP, and core attributes are displayed here. Note the MP bar -- your maximum mana equals your INT score. It will regenerate slowly as you move."; Outcome="none" }
            "desk"     = @{ Name="Mordecai's Desk"; Desc="A clipboard, several forms, and a mug that says: WORLD'S OKAYEST GUIDE. The mug appears sincere."; Outcome="loot"; Item="health_potion"; Text="Behind the desk, you find a health potion that fell behind a stack of forms. Mordecai does not seem surprised." }
        }
        Ambient=@("Mordecai's whiskers twitch. 'Good. You didn't die on the way here. Points for that.'","The notice board is very thorough. Someone spent time on these notices.","Outside, through the windows, the dungeon floor stretches away into distance.")
    }
    "f1_spawn" = @{
        Name="Spawn Point Alpha"; Floor=1; Visited=$false
        Desc="The world ended about three minutes ago. You're standing in what used to be a Seattle neighborhood. The buildings have all sunk into the ground, leaving a rubble-strewn dungeon floor stretching in every direction. Overhead, glowing text hangs in the air: WELCOME, CRAWLER. FIND THE STAIRCASE. A Tutorial Guild Hall is to the north. There's a vending machine area to the east."
        Exits=@{north="f1_guild";east="f1_vending";south="f1_rubble_south";west="f1_alley"}
        Items=@("pipe_wrench","health_potion"); Enemies=@("cave_crawler")
        Interactables=@{
            "rubble"    = @{ Name="Collapsed Concrete"; Desc="Heavy slabs of what used to be a building. Could hide anything."; Outcome="loot"; Item="scrap_metal"; Text="You dig through the rubble and find a length of useful scrap metal." }
            "sign"      = @{ Name="Dungeon Welcome Sign"; Desc="A perfectly clean, professionally installed sign that says: WELCOME TO DUNGEON CRAWLER WORLD, SEASON 14. YOUR VIEWER COUNT IS CURRENTLY 100. GOOD LUCK. The sign was not here before the dungeon arrived. The dungeon installed it in the first three minutes."; Outcome="none" }
        }
        Ambient=@("Somewhere in the rubble, another crawler is screaming. Then they stop.","A goblin peeks around a corner, sees you, and explodes pre-emptively.")
    }
    "f1_guild" = @{
        Name="Tutorial Guild Hall"; Floor=1; Visited=$false; IsSafeRoom=$true; HasMordecai=$true
        Desc="A stone building perfectly intact from the dungeon floor. Inside: warm light, Mordecai in his ratkin form sitting behind a desk, and blessed silence. This is a safe room. Nothing can hurt you here. The right panel shows your loot boxes -- you can only open them in places like this. You can also rest here to recover HP and MP."
        Exits=@{south="f1_spawn";east="f1_market"}
        Items=@("mordecai_scroll"); Enemies=@()
        Interactables=@{
            "mordecai" = @{ Name="Mordecai (Ratkin)"; Desc="The small ratkin guide looks up. His clipboard has your file on it. It's impressively thick for someone who arrived three minutes ago."; Outcome="dialogue"; DialogueId="mordecai_safe_room" }
            "board"    = @{ Name="Guild Equipment Board"; Desc="Lists what can be bought or traded at the market to the east. Includes: weapons, armor, potions, crafting materials. Also a note: 'LOOT BOXES: OPEN IN SAFE ROOMS. THE DUNGEON ENERGY OUTSIDE INTERFERES. WE KNOW. STOP ASKING.'"; Outcome="none" }
        }
        Ambient=@("Mordecai nods. 'You're not dead yet. Points for that.'","Other crawlers mill around nervously.")
    }
    "f1_market" = @{
        Name="Crawler Market"; Floor=1; Visited=$false; IsSafeRoom=$true
        Desc="A makeshift market outside the Guild Hall. Crawlers trade gear, food, and information. A vending machine labelled BORANT CORP APPROVED GOODS hums against one wall. Prices are absurd. Someone is selling a bottled cockroach as a 'delicacy'."
        Exits=@{west="f1_guild";south="f1_vending";north="f1_church_ruins"}
        Items=@("energy_drink","duct_tape"); Enemies=@()
        Interactables=@{
            "vendor"     = @{ Name="Crawler Vendor (Tasha)"; Desc="A tall woman with a military bearing and a vendor's instinct. 'I've got supplies if you've got gold. Don't try to rob me. It won't go well for you.'"; Outcome="none" }
            "noticeboard"= @{ Name="Crawler Notice Board"; Desc="Handwritten tips from other crawlers: 'GOBLINS EXPLODE. DON'T SCARE THEM CLOSE.' 'BRINDLE GRUBS SPAWN FROM CORPSES ON FLOOR 2.' 'SAFE ROOMS ARE SAFE. NO EXCEPTIONS.' 'MORDECAI SEEMS ANNOYED BUT IS ACTUALLY HELPFUL. DON'T TELL HIM WE SAID THAT.'"; Outcome="none" }
        }
        Ambient=@("'I'll trade my wedding ring for a health potion,' someone says.","A crawler is desperately trying to craft something out of a shoe.")
    }
    "f1_vending" = @{
        Name="Borant Vending Zone"; Floor=1; Visited=$false
        Desc="A row of sleek alien vending machines jammed into a collapsed storefront. They sell everything priced in gold. A machine in the corner accepts subscriber donations."
        Exits=@{north="f1_market";west="f1_spawn";south="f1_parking"}
        Items=@("health_potion","combat_knife"); Enemies=@("exploding_goblin")
        Chest=@{Locked=$false;Items=@("stim_pack","scrap_metal");Gold=18}
        Interactables=@{
            "machine"  = @{ Name="Borant Vending Machine"; Desc="Sells: Health Potion (15g), Mana Vial (20g), Scrap Metal (3g), Duct Tape (2g). You don't have a way to actually buy things yet. The interface is intuitive in the way that alien technology is sometimes accidentally intuitive for humans."; Outcome="none" }
        }
        Ambient=@("An exploding goblin tried to rob the vending machine. The results are on the wall.")
    }
    "f1_alley" = @{
        Name="Collapsed Alley"; Floor=1; Visited=$false
        Desc="A narrow gap between two slabs of collapsed concrete. Smells of gas leak and fear. Someone chalked survival tips on the walls: GOBLINS EXPLODE WHEN SCARED. GRUBS SPAWN FROM CORPSES. Below it, in different handwriting: TOO LATE."
        Exits=@{east="f1_spawn";north="f1_basement";south="f1_dead_end"}
        Items=@("lockpick","scrap_metal"); Enemies=@("cave_crawler","feral_dog")
        Interactables=@{
            "graffiti" = @{ Name="Chalked Survival Tips"; Desc="Layer upon layer. The most recent addition: 'TALK TO INTELLIGENT ENEMIES BEFORE FIGHTING. SOME OF THEM WILL LISTEN.' Underneath: 'SOME OF THEM WON'T. RIP JERRY.' Underneath that: 'Jerry talked too long. RIP Jerry.'"; Outcome="none" }
            "backpack"  = @{ Name="Abandoned Backpack"; Desc="A starter kit, partially looted."; Outcome="loot"; Item="duct_tape"; Text="The backpack has been gone through but missed a roll of duct tape in the side pocket." }
        }
        Ambient=@("Something drips from above.","A dead crawler's starter kit lies unopened in the corner.")
    }
    "f1_dead_end" = @{
        Name="Rubble Dead End"; Floor=1; Visited=$false
        Desc="A collapsed section of street that goes nowhere. Someone was here before you -- there are drag marks, a blood smear, and a partially looted backpack."
        Exits=@{north="f1_alley"}
        Items=@("boxcutter","health_potion"); Enemies=@("exploding_goblin")
        Chest=@{Locked=$false;Items=@("leather_jacket");Gold=8}
        Interactables=@{
            "scratches" = @{ Name="Scratches on Wall"; Desc="'DAY 1. FLOOR 1. I WILL MAKE IT.' Below: 'Day 2. I will not make it.' Below that, in shakier writing: 'Actually day 2 is going okay. False alarm.' Below that, nothing."; Outcome="none" }
        }
        Ambient=@("The backpack still has half a granola bar in it.","Scratch marks on the wall.")
    }
    "f1_rubble_south" = @{
        Name="Southern Rubble Field"; Floor=1; Visited=$false
        Desc="A vast open section of floor 1 -- collapsed apartment buildings stretching for blocks. Mobs spawn here constantly. It's dangerous, but the monster density means good XP."
        Exits=@{north="f1_spawn";east="f1_parking";west="f1_dead_end";south="f1_stairwell_antechamber"}
        Items=@("scrap_metal","chemical_jug"); Enemies=@("exploding_goblin","cave_crawler","feral_dog")
        Interactables=@{
            "debris"   = @{ Name="Debris Pile"; Desc="Compacted building material. Could be useful as cover during combat."; Outcome="loot"; Item="scrap_metal"; Text="You find more scrap metal in the debris. The dungeon is nothing if not consistent about its materials." }
        }
        Ambient=@("Multiple explosions in the distance. More than one goblin.","The dungeon hums underfoot. Something large is moving below.")
    }
    "f1_parking" = @{
        Name="Collapsed Parking Garage"; Floor=1; Visited=$false
        Desc="Three floors of parking garage collapsed into one. Cars are stacked at odd angles -- cover and hiding spots, but also hiding spots for things that want to eat you. A crawler with a broken arm is sheltering behind a crushed pickup truck. She looks at you like a lifeline."
        Exits=@{north="f1_vending";west="f1_rubble_south";east="f1_church_ruins"}
        Items=@("duct_tape","scrap_metal"); Enemies=@("feral_dog","exploding_goblin")
        Chest=@{Locked=$true;Items=@("combat_knife","riot_gear");Gold=35;KeyRequired="lockpick"}
        Interactables=@{
            "car"    = @{ Name="Crushed Sedan"; Desc="A blue sedan, flattened almost completely. The door panel is loose."; Outcome="loot"; Item="scrap_metal"; Text="You pry off the door panel and strip some useful metal. Scrap metal added to inventory." }
            "britta" = @{ Name="Britta (Injured Crawler)"; Desc="A woman in her thirties, left arm at a bad angle, hiding behind the pickup truck. She has a first aid kit she can't reach with one hand and a determined expression that suggests she's been through worse than a broken arm and is furious about this specific instance."; Outcome="dialogue"; DialogueId="britta_parking" }
            "truck"  = @{ Name="Crushed Pickup Truck"; Desc="Provides solid cover against ranged attacks. The truck bed still has a toolbox."; Outcome="loot"; Item="duct_tape"; Text="The toolbox in the truck bed has a roll of duct tape. Practical find." }
        }
        Ambient=@("Britta: 'My name is Britta. If I give you my stuff will you help me?'","A car alarm still bleating somewhere in the wreckage.","Feral dogs circle in the upper level, watching.")
    }
    "f1_church_ruins" = @{
        Name="Church Ruins"; Floor=1; Visited=$false
        Desc="A collapsed church where the altar survived intact. Dozens of crawlers sought shelter here in the first minutes. A big guy named Brandon coordinates. A teenager named Yuki maps exits on cardboard. An old woman named Miriam is calm in a way that doesn't quite make sense."
        Exits=@{west="f1_parking";south="f1_market";east="f1_basement";north="f1_neighborhood_boss"}
        Items=@("health_potion","energy_drink"); Enemies=@()
        Interactables=@{
            "brandon" = @{ Name="Brandon (Crawler Leader)"; Desc="Big, calm, organizing people with the practiced ease of someone who's run disaster relief before. 'We've got maybe forty people here. Half are useless in a fight. I need scouts.'"; Outcome="none" }
            "yuki"    = @{ Name="Yuki (Mapper)"; Desc="The teenager holds up a cardboard map. It's remarkably accurate. 'I found the stairwell. It's through the neighborhood boss area to the north. She's... significant.' Yuki underlines 'significant' twice on the map."; Outcome="none" }
            "miriam"  = @{ Name="Miriam (The Calm One)"; Desc="The old woman is sitting on an overturned pew, reading a prayer book she apparently had in her pocket. 'I've played a lot of video games, dear,' she says without looking up. 'We'll be fine.' She turns a page. 'Well. Some of us.'"; Outcome="none" }
            "altar"   = @{ Name="Intact Altar"; Desc="The altar survived the collapse perfectly. There are already flowers on it -- someone placed them in the first ten minutes. The dungeon somehow preserved the flowers."; Outcome="loot"; Item="health_potion"; Text="Behind the altar, you find a health potion someone left as an offering and then thought better of." }
        }
        Ambient=@("Brandon: 'We need more supplies before the floor timer runs out.'","Miriam smiles. 'I've played a lot of video games, dear. We'll be fine.'")
    }
    "f1_basement" = @{
        Name="Sub-Basement Access"; Floor=1; Visited=$false
        Desc="A concrete staircase leading down into a sub-basement connecting to early sections of Floor 2's sewers. Damp air rises from below."
        Exits=@{west="f1_church_ruins";south="f1_alley";down="f2_sewer_antechamber"}
        Items=@("health_potion"); Enemies=@("cave_crawler","brindle_grub")
        Interactables=@{
            "carving"  = @{ Name="Wall Carving"; Desc="'THE GRUBS GOT TOMMY' carved into the concrete. Below it, in someone else's hand: 'Leave no bodies on Floor 2. I mean it. -- M.' The M almost certainly stands for Mordecai."; Outcome="none" }
        }
        Ambient=@("Wet sounds from below.","The System: 'Brindle Grubs spawn from corpses on Floor 2. Don't leave bodies.'")
    }
    "f1_neighborhood_boss" = @{
        Name="Old Neighborhood - Hoarder's Lair"; Floor=1; Visited=$false
        Desc="A former residential block where the neighborhood boss has taken up residence. The boss is a middle-aged woman named Patricia who was a hoarder in real life and has been transformed into a 15-foot creature made of everything she accumulated. She's surprisingly agile."
        Exits=@{south="f1_church_ruins";north="f1_stairwell_antechamber"}
        Items=@("scrap_metal"); Enemies=@("feral_dog")
        BossRoom=$true; BossEnemy="circus_bear"; BossDefeated=$false
        Interactables=@{
            "hoard"    = @{ Name="Patricia's Hoard"; Desc="Stacked junk: furniture, appliances, childhood toys, tax returns, several thousand rubber bands, a collection of decorative plates. All of it incorporated into the creature that used to be Patricia."; Outcome="none" }
        }
        Ambient=@("Patricia's voice, echoing unnaturally: 'I COLLECTED YOU NOW.'","The System: 'Patricia has 2.3 million viewers right now. Good luck.'")
    }
    "f1_stairwell_antechamber" = @{
        Name="Floor 1 Stairwell Antechamber"; Floor=1; Visited=$false
        Desc="A large chamber with a glowing blue staircase descending into the floor. Crawlers are clustered around it. Some look triumphant. Most look terrified."
        Exits=@{south="f1_neighborhood_boss";down="f2_sewer_antechamber"}
        Items=@("mega_health"); Enemies=@()
        IsStairwell=$true; StairTarget="f2_sewer_antechamber"
        Interactables=@{
            "staircase" = @{ Name="Floor 1 Stairwell"; Desc="A glowing blue staircase. The light from below is a different color -- warmer, danker. It smells of old stone and things you don't want to think about."; Outcome="none" }
        }
        Ambient=@("The System: 'FLOOR 1 CONCLUDES IN 2 HOURS. CRAWLERS STILL PRESENT: 847.'","A crawler hugs a stranger before descending.")
    }

    # === FLOOR 2: UNDERCITY SEWERS ===
    "f2_sewer_antechamber" = @{
        Name="Sewer Antechamber"; Floor=2; Visited=$false; IsSafeRoom=$true
        Desc="The bottom of the staircase opens into a vaulted stone chamber smelling of things you'd rather not name. Green bio-luminescent fungi provide dim light. A sign reads: TUTORIAL ENDS HERE. YOU ARE NOW ON YOUR OWN."
        Exits=@{up="f1_stairwell_antechamber";north="f2_guild";east="f2_main_tunnel";south="f2_cistern"}
        Items=@("antiparasitic","health_potion"); Enemies=@("mutant_rat")
        Interactables=@{
            "fungi"    = @{ Name="Bio-Luminescent Fungi"; Desc="Glowing green and shifting. The light is enough to see by but too dim for comfort. The color is wrong in a way that's hard to specify."; Outcome="none" }
            "sign"     = @{ Name="WARNING Sign"; Desc="TUTORIAL ENDS HERE. The dungeon has also posted a secondary sign below it: BRINDLE GRUBS SPAWN FROM CORPSES. LEAVE NO BODIES. This is underlined three times. The third underline is deeper than the others."; Outcome="none" }
        }
        Ambient=@("The fungi glow in shifting colors.","A Brindle Grub slides past your feet, heading for a dead rat. You watch in horror.")
    }
    "f2_guild" = @{
        Name="Floor 2 Guild Outpost"; Floor=2; Visited=$false; IsSafeRoom=$true; HasMordecai=$true
        Desc="A smaller, damp version of the floor 1 guild hall. Mordecai appears in his natural Kua-Tin form -- something like a velociraptor that went to business school. 'You made it,' he says flatly. 'Adequate.'"
        Exits=@{south="f2_sewer_antechamber";east="f2_pump_station"}
        Items=@("mordecai_scroll"); Enemies=@()
        Interactables=@{
            "mordecai" = @{ Name="Mordecai (Kua-Tin)"; Desc="He has reading glasses he doesn't need. The clipboard has Floor 2 incident data on it. The grub casualty count is significant."; Outcome="dialogue"; DialogueId="mordecai_safe_room" }
        }
        Ambient=@("Mordecai: 'Choose your class wisely on Floor 3. Some of them are terrible. I'm legally prohibited from saying which.'")
    }
    "f2_main_tunnel"        = @{ Name="Main Sewer Tunnel"; Floor=2; Visited=$false
        Desc="The primary east-west sewer conduit. Wide enough for ten people abreast, which means wide enough for a sewer golem. Bio-luminescent fungi are thicker here."
        Exits=@{west="f2_sewer_antechamber";east="f2_goblin_den";north="f2_pump_station";south="f2_deep_cistern"}
        Items=@("scrap_metal","duct_tape"); Enemies=@("mutant_rat","brindle_grub")
        Interactables=@{
            "grate"    = @{ Name="Floor Grate"; Desc="A heavy iron grate over a deep drainage channel. Something moves below. Slowly. In a pattern that suggests it is aware."; Outcome="none" }
        }
        Ambient=@("The grubs feeding in the distance suddenly look up at you simultaneously.") }
    "f2_pump_station"       = @{ Name="Old Pump Station"; Floor=2; Visited=$false
        Desc="A massive industrial pump station incorporated into the dungeon. Giant corroded pipes cross in every direction. Someone has set up a small camp with makeshift barricades."
        Exits=@{south="f2_main_tunnel";west="f2_guild";east="f2_overflow_chamber"}
        Items=@("chemical_jug","scrap_metal","lockpick"); Enemies=@("sewer_golem","mutant_rat")
        Chest=@{Locked=$true;Items=@("stim_pack","dungeon_plate");Gold=40;KeyRequired="lockpick"}
        Interactables=@{
            "console"  = @{ Name="Control Console"; Desc="Covered in alien text that glows uselessly. One button still works -- it releases a burst of pressurized water that would temporarily slow enemies. You note this."; Outcome="none" }
            "camp"     = @{ Name="Abandoned Camp"; Desc="Someone made this camp and left it well-provisioned. The note says: 'Took the tunnel south. Come find us. -- Rivera.' You wonder if Rivera made it."; Outcome="loot"; Item="antiparasitic"; Text="The camp has antiparasitic medicine that whoever left didn't take. You take it." }
        }
        Ambient=@("The pumps groan as if trying to restart.","A golem sits dormant near the main pipe. Key word: dormant.") }
    "f2_cistern"            = @{ Name="The Great Cistern"; Floor=2; Visited=$false
        Desc="An enormous underground cistern the size of a football stadium. The acoustics are terrifying -- every sound echoes wrong. Multiple grub colonies in the dry sections."
        Exits=@{north="f2_sewer_antechamber";east="f2_deep_cistern";south="f2_stairwell_chamber"}
        Items=@("health_potion","antiparasitic"); Enemies=@("brindle_grub","mutant_rat","sewer_golem")
        Interactables=@{
            "echo"     = @{ Name="Acoustic Phenomenon"; Desc="You say something quietly. It comes back four times from different directions, slightly distorted each time. The fourth repetition sounds like it's trying to answer."; Outcome="none" }
        }
        Ambient=@("Your footsteps echo back to you slightly wrong.","A grub colony ripples like a living carpet in the corner.") }
    "f2_deep_cistern"       = @{ Name="Deep Cistern"; Floor=2; Visited=$false
        Desc="The lowest accessible section. Water reaches ankle depth. Bio-luminescent panels flicker overhead. A massive iron door at the far end bears the symbol for Floor 3."
        Exits=@{west="f2_cistern";north="f2_main_tunnel";south="f2_boss_chamber"}
        Items=@("mega_health","dungeon_crystal"); Enemies=@("sewer_golem","brindle_grub")
        Interactables=@{
            "iron_door" = @{ Name="Iron Door to Floor 3"; Desc="Massive, ancient, and pulsing with amber energy that's different from the blue of the stairwells. The symbol carved into it looks like a city skyline, except the buildings have faces."; Outcome="none" }
        }
        Ambient=@("The water surface ripples from something below.","The iron door pulses with dungeon energy.") }
    "f2_boss_chamber"       = @{ Name="The Golem's Chamber"; Floor=2; Visited=$false
        Desc="A circular chamber where the Sewer Golem Prime has taken up residence. The creature is enormous -- twenty feet of compressed sewage and bone -- and currently rearranging the floor decorations to suit itself. It turns to look at you. It doesn't have eyes. Somehow it still looks at you."
        Exits=@{north="f2_deep_cistern";south="f2_stairwell_chamber"}
        Items=@(); Enemies=@()
        BossRoom=$true; BossEnemy="sewer_golem"; BossDefeated=$false
        Ambient=@("The Golem Prime is watching you.","Something cracks in the walls as it shifts its weight.") }
    "f2_stairwell_chamber"  = @{ Name="Floor 2 Stairwell"; Floor=2; Visited=$false
        Desc="The stairwell to Floor 3. It glows with eerie amber light. Carved above it: TRAINING COMPLETE. THE GAMES BEGIN NOW. Below, you can hear the sounds of a wrong city."
        Exits=@{north="f2_boss_chamber";down="f3_over_city_entry"}
        Items=@("mega_health","sponsors_box"); Enemies=@()
        IsStairwell=$true; StairTarget="f3_over_city_entry"
        Ambient=@("Carnival music drifts up from below. Slightly off-key.","A crawler next to you whispers: 'I can hear a bear. An undead bear. Why is there an undead bear?'") }
    "f2_goblin_den"         = @{ Name="Goblin Den"; Floor=2; Visited=$false
        Desc="A section of sewer tunnel the goblins have converted into a messy, explosively unstable den. The decorations are concerning."
        Exits=@{west="f2_main_tunnel"}
        Items=@("scrap_metal","chemical_jug"); Enemies=@("exploding_goblin")
        Interactables=@{
            "goblin_stuff" = @{ Name="Goblin Stuff"; Desc="An assortment of things goblins consider valuable: several human wallets (emptied), a collection of shiny rocks, a signed photograph of someone, a mostly-eaten sandwich, and a small trophy labeled 'BEST EXPLOSION.' The trophy is impressive."; Outcome="loot"; Item="lockpick"; Text="Mixed in with the goblin treasures, you find a lockpick set someone dropped." }
        }
        Ambient=@("It smells aggressively of gunpowder and goblin.","A goblin in the corner is practicing being threatening in a mirror.") }
    "f2_overflow_chamber"   = @{ Name="Overflow Chamber"; Floor=2; Visited=$false
        Desc="A large chamber with multiple overflow drainage channels. Occasional surges of dungeon-tainted water make the footing treacherous."
        Exits=@{west="f2_pump_station";south="f2_deep_cistern"}
        Items=@("duct_tape","health_potion"); Enemies=@("brindle_grub","mutant_rat")
        Ambient=@("The water surges suddenly, then drains just as fast.","The floor is slick with something you've decided not to think about.") }

    # === FLOOR 3: THE OVER CITY ===
    "f3_over_city_entry"    = @{ Name="Over City Entry - Times Square Ruins"; Floor=3; Visited=$false
        Desc="Floor 3 is a ruined city assembled from every major urban center absorbed into the dungeon. Entry looks like a nightmarish Times Square: massive screens flicker with alien ads, skyscrapers cut off at the 10th floor. Somewhere, circus music plays."
        Exits=@{north="f3_city_guild";east="f3_main_street";south="f3_subway_entrance";west="f3_side_alley"}
        Items=@("health_potion","scrap_metal"); Enemies=@("corrupted_cop","undead_clown")
        Interactables=@{
            "screen"   = @{ Name="Alien Advertisement Screen"; Desc="The screens cycle through ads for galactic products: anti-gravity footwear, a restaurant chain with seventeen stars, a legal service that specifically handles 'dungeon fatality claims'. One screen just shows your viewer count."; Outcome="none" }
        }
        Ambient=@("The screens flicker: 'WELCOME TO OVER CITY. POPULATION 0. VIEWERS: 12 MILLION.'","Circus music is definitely getting closer.") }
    "f3_city_guild"         = @{ Name="City Guild Hall"; Floor=3; Visited=$false; IsSafeRoom=$true; HasMordecai=$true
        Desc="A guild hall set up in a former hotel lobby. Mordecai is in his incubus form -- heartbreakingly beautiful, visibly mortified about it. 'The Selection Gate activates soon,' he says. 'Your class options depend on how you've played. The data is in.' He hands you a floor map."
        Exits=@{south="f3_over_city_entry";east="f3_park_ruins";north="f3_upper_city"}
        Items=@("mordecai_scroll","health_potion"); Enemies=@()
        Interactables=@{
            "mordecai"    = @{ Name="Mordecai (Incubus)"; Desc="He has his wings carefully folded. Several crawlers keep finding excuses to walk past his desk. He notices. He does not comment. He seems to find the professional dignity required by this situation extremely taxing."; Outcome="dialogue"; DialogueId="mordecai_safe_room" }
            "hotel_bell"  = @{ Name="Hotel Reception Bell"; Desc="Still functional. You ring it. Mordecai's eye twitches once, which is the most emotion you've seen from him."; Outcome="none" }
        }
        Ambient=@("The hotel concierge -- now a skeleton in uniform -- still tries to check you in.","Other crawlers compare quest notes frantically.") }
    "f3_main_street"        = @{ Name="Over City Main Street"; Floor=3; Visited=$false
        Desc="A wide boulevard through the center of the Over City. The circus patrols here on a set schedule. Ancient streetlights flicker. Shop windows display goods that aren't for sale."
        Exits=@{west="f3_over_city_entry";north="f3_park_ruins";east="f3_warehouse";south="f3_station_ruins"}
        Items=@("combat_knife","energy_drink"); Enemies=@("undead_clown","corrupted_cop","city_wraith")
        Interactables=@{
            "vehicle"  = @{ Name="Crashed Alien Vehicle"; Desc="A vehicle from somewhere that isn't Earth, smoldering at the intersection. The door is open. The interior is still warm."; Outcome="loot"; Item="scrap_metal"; Text="The vehicle's hull yields useful scrap metal." }
            "schedule" = @{ Name="Circus Patrol Schedule"; Desc="Posted on a lamppost by... the circus? For public awareness? It reads: CIRCUS ARRIVES: 2 HOURS. CIRCUS DEPARTS: 3 HOURS. BEING ON THE STREET DURING CIRCUS HOURS: NOT RECOMMENDED."; Outcome="none" }
        }
        Ambient=@("Circus music swells suddenly. It's coming from the north.") }
    "f3_park_ruins"         = @{ Name="The Ruined Park"; Floor=3; Visited=$false
        Desc="A city park where something ancient has taken root. Dead trees with glowing purple roots. At the center, a stone structure covered in symbols hums loudly. Mordecai's voice crackles over comms: 'That's the Ancient Spell. It's been building power ever since it was cast.'"
        Exits=@{south="f3_main_street";west="f3_city_guild";east="f3_university"}
        Items=@("dungeon_crystal","mordecai_scroll"); Enemies=@("city_wraith","corrupted_cop")
        Interactables=@{
            "stone"    = @{ Name="Ancient Spell Stone"; Desc="Covered in symbols you can't read. But as you watch, some of them are changing. The hum has a rhythm to it now -- like breathing."; Outcome="none" }
            "trees"    = @{ Name="Dead Trees with Glowing Roots"; Desc="The roots pulse purple in sync with the stone. The pattern moves too regularly to be random. Something is using this to power something else."; Outcome="none" }
        }
        QuestRoom="ancient_spell"
        Ambient=@("The symbol-covered stone pulses faster as you approach.") }
    "f3_warehouse"          = @{ Name="Abandoned Warehouse"; Floor=3; Visited=$false
        Desc="A warehouse converted into a dungeon armory by previous crawlers who didn't make it out. Crates of supplies. A half-built barricade. Evidence of a last stand. A functioning crafting bench is bolted to the wall."
        Exits=@{west="f3_main_street";north="f3_university";south="f3_station_ruins"}
        Items=@("scrap_metal","chemical_jug","explosive_gel","duct_tape"); Enemies=@("undead_clown","city_wraith")
        HasCraftingBench=$true
        Chest=@{Locked=$true;Items=@("goblin_cleaver","stim_pack");Gold=55;KeyRequired="lockpick"}
        Interactables=@{
            "barricade"  = @{ Name="Last Stand Barricade"; Desc="Didn't hold. The evidence is clear about that. A note nailed to it: 'We tried. The wraiths came through the walls. Walls. Keep that in mind.' There's a drawing of a wraith going through a wall. It's technically accurate."; Outcome="none" }
            "bench_notes"= @{ Name="Crafting Notes (Wall)"; Desc="'SCRAP + CHEMICAL JUG + EXPLOSIVE GEL = JUG O BOOM. THIS WORKS. VERIFIED.' Below: 'Verified by me personally. In a controlled manner. It was not controlled.' Below that: 'THE CEILING CAME DOWN. 5/5 WOULD CRAFT AGAIN.'"; Outcome="none" }
        }
        Ambient=@("Something watches from the rafters.") }
    "f3_university"         = @{ Name="Ruined University"; Floor=3; Visited=$false
        Desc="A university library survived almost intact -- alien texts mixed with human ones. Dr. Lim, a former chemistry professor, has set up here. She is very excited about the explosive gel."
        Exits=@{south="f3_warehouse";west="f3_park_ruins";east="f3_circus_staging";north="f3_upper_city"}
        Items=@("explosive_gel","dungeon_crystal"); Enemies=@("city_wraith")
        HasCraftingBench=$true
        Interactables=@{
            "dr_lim"   = @{ Name="Dr. Lim (Chemistry Professor)"; Desc="'I have made seventeen different explosive compounds,' she says without looking up. 'I am THRIVING. The dungeon's chemical properties are fascinating.' She gestures at several jars. 'This one dissolves iron. This one doesn't dissolve iron but does dissolve time. I'm still testing that one.'"; Outcome="none" }
            "library"  = @{ Name="Dungeon Library"; Desc="Human textbooks mixed with alien ones. The alien chemistry textbooks are fascinating and alarming in equal measure. One is titled: COMPOUNDS FOR ENVIRONMENTS WHERE PHYSICS IS OPTIONAL. You take a mental note."; Outcome="none" }
        }
        Ambient=@("A ghost professor still holds class. Three ghost students take notes.") }
    "f3_circus_staging"     = @{ Name="Circus Staging Ground"; Floor=3; Visited=$false
        Desc="Base of operations for the undead circus. Rotting tents, broken calliope, prop wagons leaking ectoplasm. The Undead Circus Bear boss is here -- enormous, rancid, wearing a tiny fez and an expression of existential suffering."
        Exits=@{west="f3_university";south="f3_station_ruins"}
        Items=@("mega_health","stim_pack"); Enemies=@("undead_clown")
        BossRoom=$true; BossEnemy="circus_bear"; BossDefeated=$false
        Interactables=@{
            "fez"      = @{ Name="The Fez"; Desc="You can see it from here. The fez. It is genuinely tiny for the bear's head. It appears to be secured with a supernatural adhesive that cannot be removed. The bear has clearly tried."; Outcome="none" }
        }
        Ambient=@("The bear's fez is unsettlingly tiny for its head.","The System: '8 MILLION VIEWERS. BEAR VS. CRAWLER. RATINGS GOLD.'") }
    "f3_station_ruins"      = @{ Name="Transit Station Ruins"; Floor=3; Visited=$false
        Desc="A former transit hub half-collapsed into the dungeon substrate. The trains don't run here -- that's Floor 4. But you can feel the vibration of the Iron Tangle below."
        Exits=@{north="f3_main_street";east="f3_circus_staging";west="f3_warehouse";south="f3_stairwell_block";up="f3_upper_city"}
        Items=@("transit_card","health_potion"); Enemies=@("corrupted_cop","undead_clown")
        Interactables=@{
            "schedule"  = @{ Name="Train Schedule"; Desc="The schedule board still updates. The times listed are: DELAYED. DELAYED. DELAYED. DELAYED. REASON: MONSTERS. EXPECTED RESOLUTION: NEVER. A final note: TRANSIT CARDS REQUIRED FOR FLOOR 4 ACCESS."; Outcome="none" }
        }
        Ambient=@("The walls vibrate with distant train movement.") }
    "f3_upper_city"         = @{ Name="Upper City Overlook"; Floor=3; Visited=$false
        Desc="A section built on ruins of upper-floor city buildings. From up here you can see the full scope of the Over City. It's enormous. Broken. Beautiful in a terrible way."
        Exits=@{south="f3_city_guild";east="f3_university";west="f3_side_alley";down="f3_station_ruins"}
        Items=@("sponsors_box"); Enemies=@("city_wraith","undead_clown")
        Interactables=@{
            "view"     = @{ Name="City Overlook"; Desc="The entire Over City below you. You can see the circus circuit, the glowing park, and the stairwell district to the south. From up here the scale is clear -- this floor contains pieces of dozens of cities, stitched together without seams."; Outcome="none" }
        }
        Ambient=@("From here you can see the stairwell glowing far to the south.") }
    "f3_side_alley"         = @{ Name="Side Alley Network"; Floor=3; Visited=$false
        Desc="A maze of back alleys cutting through the Over City off the main circuit. Graffiti from previous crawlers: ratings advice, enemy weaknesses, and one very long, very detailed poem about missing home."
        Exits=@{east="f3_over_city_entry";north="f3_upper_city";south="f3_stairwell_block"}
        Items=@("health_potion","duct_tape"); Enemies=@("city_wraith")
        Interactables=@{
            "poem"     = @{ Name="Crawler's Poem (Wall Graffiti)"; Desc="38 stanzas about missing Earth. It is technically good. The last stanza is: 'The wraiths can't enter buildings / But I must enter buildings / And sometimes a building / Already has a wraith in it / This is a design flaw.' It's signed 'M. Okonkwo, Floor 3, Day 4. Still alive.'"; Outcome="none" }
        }
        Ambient=@("A wraith reads the poem over your shoulder.") }
    "f3_subway_entrance"    = @{ Name="Subway Entrance - Gate 7"; Floor=3; Visited=$false
        Desc="A subway entrance descending into the floor. Not Floor 4 yet -- an antechamber. You can hear the Iron Tangle: the shriek of metal on metal, a garbled PA announcement in seventeen languages."
        Exits=@{north="f3_over_city_entry";south="f3_stairwell_block";down="f3_station_ruins"}
        Items=@("transit_card","health_potion"); Enemies=@("corrupted_cop")
        Ambient=@("A PA announcement: 'THE 4 TRAIN IS RUNNING WITH DELAYS. REASON: MONSTERS. EXPECTED RESOLUTION: NEVER.'") }
    "f3_stairwell_block"    = @{ Name="Stairwell District"; Floor=3; Visited=$false
        Desc="The district at the south end of the Over City where the Floor 3 stairwell is located. Heavy mob concentration. An enormous glowing staircase descends through the floor."
        Exits=@{north="f3_station_ruins";east="f3_circus_staging";west="f3_side_alley";down="f4_iron_tangle_entry"}
        Items=@("mega_health","sponsors_box"); Enemies=@("undead_clown","corrupted_cop","city_wraith")
        IsStairwell=$true; StairTarget="f4_iron_tangle_entry"
        Ambient=@("Below: the unmistakable sound of a hundred trains running on impossible tracks.") }

    # === FLOOR 4: THE IRON TANGLE ===
    "f4_iron_tangle_entry"  = @{ Name="Iron Tangle - Central Hub Station"; Floor=4; Visited=$false; IsSafeRoom=$true
        Desc="You step off the stairs onto a platform in the most insane transit system ever assembled. Trains from every era run on tracks that crisscross in three dimensions. The station map makes no spatial sense. A sign reads: YOU ARE HERE. Another underneath: ACTUALLY YOU MIGHT NOT BE."
        Exits=@{up="f3_stairwell_block";north="f4_platform_north";east="f4_eastbound";south="f4_guild_car";west="f4_westbound"}
        Items=@("health_potion","transit_card"); Enemies=@("train_goblin")
        Interactables=@{
            "map"      = @{ Name="Tangle Station Map"; Desc="Spatially impossible. But there are annotations from previous crawlers: 'MAGNETIC LEV LINE EAST LEADS TO BOSS.' 'STEAM DISTRICT AVOIDABLE BUT HAS LOOT.' 'THE LICH WILL WANT A TICKET. JUST GET A TICKET.' And: 'DO NOT STAND ON THE TRACKS. I MEAN THIS.'"; Outcome="none" }
        }
        Ambient=@("Seven trains pass through simultaneously without hitting each other. Somehow.") }
    "f4_guild_car"          = @{ Name="Guild Car - Rolling Safe Room"; Floor=4; Visited=$false; IsSafeRoom=$true; HasMordecai=$true
        Desc="A special train car that serves as the guild hall for Floor 4. It moves on its own schedule but always stops at major stations. Mordecai runs it in his iron construct form. There's a crafting bench bolted to one wall."
        Exits=@{north="f4_iron_tangle_entry";east="f4_steam_section";south="f4_eastbound"}
        Items=@("mordecai_scroll","stim_pack"); Enemies=@()
        HasCraftingBench=$true
        Interactables=@{
            "mordecai"  = @{ Name="Mordecai (Iron Construct)"; Desc="The mechanical form turns with precise efficiency. Its display panel reads: RECOGNIZED - ALIVE - STATUS: ADEQUATE. 'You have survived to Floor 4,' it says, in the voice of someone making a transit announcement. 'This is noted.'"; Outcome="dialogue"; DialogueId="mordecai_safe_room" }
            "window"    = @{ Name="Guild Car Window"; Desc="Outside, an impossible variety of tunnels flow past. Steam tunnels. Electric tunnels. A section that appears to be underground ocean. The tracks loop through a space that shouldn't fit inside the dungeon."; Outcome="none" }
        }
        Ambient=@("The car rocks as the tracks rearrange below it.") }
    "f4_platform_north"     = @{ Name="Northern Platform - Terminus"; Floor=4; Visited=$false
        Desc="A massive platform serving as a terminus for the north section. Train goblins have set up a toll booth -- they demand gold or combat."
        Exits=@{south="f4_iron_tangle_entry";east="f4_maze_junction";north="f4_elevated_track";west="f4_steam_section"}
        Items=@("combat_knife","energy_drink"); Enemies=@("train_goblin","conductor_lich")
        Interactables=@{
            "toll_booth"= @{ Name="Goblin Toll Booth"; Desc="A small booth staffed by a goblin in a reflective vest. A sign reads: 5 GOLD OR VIOLENCE. VIOLENCE ALSO ACCEPTED. A small sign below: BUT GOLD IS PREFERRED. A small sign below that: REALLY PLEASE JUST USE THE GOLD. The goblin looks hopeful."; Outcome="bribe_option"; GoldCost=5; Text="The goblin takes the gold with evident relief. 'Smart choice! Go through! Have nice day!' It returns to its booth." }
        }
        Ambient=@("The toll booth sign: '5 GOLD OR VIOLENCE. VIOLENCE ALSO ACCEPTED.'") }
    "f4_steam_section"      = @{ Name="Steam Engine District"; Floor=4; Visited=$false
        Desc="This section is populated entirely by Victorian-era steam locomotives. Everything is brass and coal-black. Steam fills the air to near-zero visibility."
        Exits=@{east="f4_platform_north";south="f4_guild_car";west="f4_coal_tunnels"}
        Items=@("scrap_metal","chemical_jug"); Enemies=@("iron_golem","conductor_lich")
        Interactables=@{
            "steam_engine"= @{ Name="Victorian Steam Engine"; Desc="It's gorgeous in a way that's completely at odds with its surroundings. The brass fittings are polished. The name plate reads: HMS INEVITABLE. The engine appears to be running itself, carrying nothing, going nowhere specific."; Outcome="loot"; Item="scrap_metal"; Text="You pull a loose section of brass fitting. Scrap metal." }
        }
        Ambient=@("A steam engine rolls by playing a pipe organ. This feels intentional.") }
    "f4_eastbound"          = @{ Name="Eastbound Express Line"; Floor=4; Visited=$false
        Desc="The express line -- high-speed modern trains, wind that nearly knocks you down. The stairwell to Floor 5 is somewhere on this line. The goblins have strapped themselves to the outside of the cars."
        Exits=@{north="f4_iron_tangle_entry";south="f4_guild_car";east="f4_maze_junction";west="f4_coal_tunnels"}
        Items=@("health_potion","goblin_cleaver"); Enemies=@("train_goblin","iron_golem")
        Ambient=@("A train passes at 200mph. Your hat flies off.","A goblin strapped to a train gives you a thumbs up. Then explodes.") }
    "f4_westbound"          = @{ Name="Westbound Local"; Floor=4; Visited=$false
        Desc="The local line -- slow, creaking, packed with dungeon mobs that treat the train cars as their territory. The conductor lich is on this route. Every time you defeat it, another manifests at the front."
        Exits=@{east="f4_iron_tangle_entry";north="f4_steam_section";south="f4_coal_tunnels";west="f4_elevated_track"}
        Items=@("duct_tape","scrap_metal"); Enemies=@("conductor_lich","train_goblin")
        Ambient=@("The lich punches tickets and announces stops in seven languages.") }
    "f4_maze_junction"      = @{ Name="The Maze Junction"; Floor=4; Visited=$false
        Desc="The Tangle's most confusing intersection. A note from previous crawlers: 'THE EXIT IS ON THE MAGNETIC LEV LINE. EASTBOUND FROM JUNCTION. GOOD LUCK.'"
        Exits=@{west="f4_platform_north";north="f4_elevated_track";south="f4_eastbound";east="f4_tangle_boss_chamber"}
        Items=@("dungeon_crystal","mega_health"); Enemies=@("conductor_lich","iron_golem")
        Interactables=@{
            "controller"= @{ Name="Skeletal Traffic Controller"; Desc="A skeleton in a high-visibility vest manages the impossible intersection with practiced efficiency. It says 'All lines running normally' without looking up. The lines are not running normally. The skeleton knows this and has accepted it."; Outcome="none" }
        }
        Ambient=@("A train passes through going diagonally. Physics has given up.") }
    "f4_elevated_track"     = @{ Name="Elevated Track Section"; Floor=4; Visited=$false
        Desc="An elevated section where 'outdoor' means you can see the dungeon ceiling far above. The tracks are old iron, groaning. The wind smells of lightning."
        Exits=@{south="f4_platform_north";east="f4_maze_junction";west="f4_westbound";north="f4_tangle_boss_chamber"}
        Items=@("stim_pack","explosive_gel"); Enemies=@("train_goblin","conductor_lich")
        Ambient=@("The drop to the next level of tracks: 40 feet minimum.") }
    "f4_coal_tunnels"       = @{ Name="Coal Mine Tunnels"; Floor=4; Visited=$false
        Desc="The Tangle incorporates ancient coal mine railways. Narrow, low-roofed, absolutely full of iron golems who were apparently coal miners in a previous life."
        Exits=@{north="f4_steam_section";east="f4_eastbound";south="f4_westbound";west="f4_tangle_boss_chamber"}
        Items=@("scrap_metal","dungeon_crystal"); Enemies=@("iron_golem")
        Chest=@{Locked=$true;Items=@("enchanted_bat","dungeon_plate");Gold=70;KeyRequired="lockpick"}
        Ambient=@("You have to crouch. The golems do not have to crouch.") }
    "f4_tangle_boss_chamber"= @{ Name="The Central Switch - Boss Chamber"; Floor=4; Visited=$false
        Desc="The heart of the Iron Tangle: the Central Switch, a room-sized mechanical apparatus. Standing at its controls is The Iron Conductor -- massive, sentient, offended. It turns to face you with the air of a transit manager who has had enough."
        Exits=@{north="f4_elevated_track";east="f4_maze_junction";south="f4_stairwell_platform";west="f4_coal_tunnels"}
        Items=@(); Enemies=@()
        BossRoom=$true; BossEnemy="tangle_boss"; BossDefeated=$false
        Ambient=@("The Conductor: 'You have been riding without a valid fare. This is unacceptable.'") }
    "f4_stairwell_platform" = @{ Name="Final Platform - Floor 4 Stairwell"; Floor=4; Visited=$false
        Desc="A special platform that only appears after the Iron Conductor is defeated. The trains run perfectly, in order, on time. It's deeply uncanny."
        Exits=@{north="f4_tangle_boss_chamber";down="f5_bubble_entry"}
        Items=@("mega_health","sponsors_box","stim_pack"); Enemies=@()
        IsStairwell=$true; StairTarget="f5_bubble_entry"
        Ambient=@("The trains run on time. You find it unsettling.") }

    # === FLOOR 5: THE BUBBLE CASTLES ===
    "f5_bubble_entry"       = @{ Name="The Bubble - Open Plains"; Floor=5; Visited=$false; IsSafeRoom=$true
        Desc="You step out of the stairwell into an enormous bubble -- a spherical enclosed environment. The sky is artificial. On the horizon: a floating gnome fortress to the north, a gleaming sand castle to the east, a dark crypt to the west, and a rusted submarine hull to the south. CAPTURE ALL FOUR CASTLES TO UNLOCK THE STAIRWELL. 15 DAYS."
        Exits=@{up="f4_stairwell_platform";north="f5_gnome_approach";east="f5_sand_approach";south="f5_sub_approach";west="f5_crypt_approach"}
        Items=@("health_potion","mordecai_scroll"); Enemies=@("war_gnome","sand_elemental")
        Interactables=@{
            "mordecai"  = @{ Name="Mordecai (War Gnome)"; Desc="Three feet of full plate armor, looking up at you with the expression of someone who has made their peace with the indignities of their profession."; Outcome="dialogue"; DialogueId="mordecai_safe_room" }
        }
        Ambient=@("The gnome fortress fires a warning cannon shot that lands 20 feet away.","Mordecai: 'You'll need other crawlers. You can't do this alone.' A pause. 'You'll try alone anyway. I know this.'") }
    "f5_gnome_approach"     = @{ Name="Gnome Fortress Approach"; Floor=5; Visited=$false
        Desc="The path to the Gnome Fortress floats on chain-rock platforms connected by bridges. The gnomes have fortified every bridge. They are three feet tall and absolutely furious."
        Exits=@{south="f5_bubble_entry";north="f5_gnome_fortress"}
        Items=@("stim_pack","explosive_gel"); Enemies=@("war_gnome")
        Interactables=@{
            "cannon"   = @{ Name="Gnome Cannon Emplacement"; Desc="A small but functional cannon manned by a gnome who is taking this very seriously. The gnome salutes at you and then immediately points the cannon at you. It seems like a protocol thing."; Outcome="none" }
        }
        Ambient=@("A gnome drops a boulder on you from a drawbridge. It's the size of a microwave. Still hurts.") }
    "f5_gnome_fortress"     = @{ Name="Gnome Fortress - Throne Room"; Floor=5; Visited=$false
        Desc="The inner sanctum. Gnome King Gorbrock sits on a throne the size of a large dog, wearing a crown that covers his entire face, and riding a mechanical battle-elk. The elk snorts steam. Gorbrock shouts in Gnomish. His translator: 'The King says your boots are ugly and your fighting stance is amateur.'"
        Exits=@{south="f5_gnome_approach"}
        Items=@("castle_banner_1","mega_health"); Enemies=@("war_gnome")
        BossRoom=$true; BossEnemy="gnome_king"; BossDefeated=$false
        Ambient=@("The mechanical elk powers up with a sound like a jet turbine.") }
    "f5_sand_approach"      = @{ Name="Sand Castle Approach"; Floor=5; Visited=$false
        Desc="The sand castle looms ahead -- a castle made of sand, impossibly structurally sound. Sand elementals patrol the perimeter. The sand is alive. Not metaphorically."
        Exits=@{west="f5_bubble_entry";east="f5_sand_castle"}
        Items=@("health_potion","dungeon_crystal"); Enemies=@("sand_elemental")
        Ambient=@("The castle is actively building new towers.") }
    "f5_sand_castle"        = @{ Name="Sand Castle - Crystal Core"; Floor=5; Visited=$false
        Desc="A dome of compressed, crystallized sand that refracts light into impossible colors. You must defeat waves of sand elementals while the castle attempts to bury you."
        Exits=@{west="f5_sand_approach"}
        Items=@("castle_banner_2","stim_pack","dungeon_crystal"); Enemies=@("sand_elemental")
        WaveRoom=$true; WaveCount=3
        Ambient=@("Sand in your boots. Sand in your teeth. Sand in places you don't want to think about.") }
    "f5_crypt_approach"     = @{ Name="Haunted Crypt Approach"; Floor=5; Visited=$false
        Desc="The haunted crypt. Mordecai warned you specifically: 'More traps per square foot than any other dungeon location ever documented.'"
        Exits=@{east="f5_bubble_entry";west="f5_haunted_crypt"}
        Items=@("health_potion","antiparasitic"); Enemies=@("crypt_guardian")
        TrapRoom=$true; TrapDmg=15
        Ambient=@("A trap fires. A dart narrowly misses you.","Mordecai: 'You're doing better than the last 47 crawlers.'") }
    "f5_haunted_crypt"      = @{ Name="Haunted Crypt - Inner Chamber"; Floor=5; Visited=$false
        Desc="A mummified priest who was placed here in the dungeon's formation and has been protecting this space ever since. He's not evil. He's just doing his job. He fights with genuine regret."
        Exits=@{east="f5_crypt_approach"}
        Items=@("castle_banner_3","mega_health","void_suit"); Enemies=@("crypt_guardian")
        Interactables=@{
            "altar"    = @{ Name="Ancient Altar"; Desc="The banner is on the altar. Between you and it: the guardian. The altar is covered in offerings from before the dungeon existed. The oldest ones have turned to dust."; Outcome="none" }
        }
        Ambient=@("The mummified priest: 'I am sorry. This is my duty.'") }
    "f5_sub_approach"       = @{ Name="Derelict Submarine Exterior"; Floor=5; Visited=$false
        Desc="A full-size nuclear submarine half-buried in the plains. Every gun, torpedo tube, and automated turret is functional. They do not distinguish between friend and enemy."
        Exits=@{north="f5_bubble_entry";south="f5_submarine"}
        Items=@("scrap_metal","health_potion"); Enemies=@("broken_machine")
        Interactables=@{
            "hatch"    = @{ Name="Submarine Access Hatch"; Desc="A heavy watertight hatch. It's been forced open from the inside, which is concerning. Something came out. Something is still inside."; Outcome="none" }
        }
        Ambient=@("A turret tracks you. You try waving. It fires.") }
    "f5_submarine"          = @{ Name="Submarine - Command Center"; Floor=5; Visited=$false
        Desc="The command center. Screens show tactical data from 30 years ago. The Alpha Machine -- the one that started the machine civil war -- is still active in the center, slowly losing. It turns its guns on you."
        Exits=@{north="f5_sub_approach"}
        Items=@("castle_banner_4","plasma_cutter","mega_health"); Enemies=@("broken_machine")
        BossRoom=$true; BossEnemy="broken_machine"; BossDefeated=$false
        Ambient=@("Alpha Machine: [TARGET ACQUIRED. LETHAL FORCE AUTHORIZED.]") }
    "f5_stairwell_plains"   = @{ Name="Central Plains - Floor 5 Stairwell"; Floor=5; Visited=$false
        Desc="When all four castles are captured, the stairwell emerges from the center of the bubble plains. Heat and humidity pour through. 'THE HUNTING GROUNDS AWAIT.' The System pauses. 'ATTENTION. THE GATES ARE DOWN. THE HUNTERS ARE LOOSE. RUN.'"
        Exits=@{north="f5_gnome_approach";east="f5_sand_approach";south="f5_sub_approach";west="f5_crypt_approach";down="f6_jungle_entry"}
        Items=@("mega_health","sponsors_box","stim_pack"); Enemies=@()
        IsStairwell=$true; StairTarget="f6_jungle_entry"; RequiredBanners=4
        Ambient=@("From below: the sound of jungle, and hunting horns.") }

    # === FLOOR 6: THE HUNTING GROUNDS ===
    "f6_jungle_entry"       = @{ Name="Hunting Grounds - Jungle Entry"; Floor=6; Visited=$false; IsSafeRoom=$true
        Desc="Lush, oppressively hot jungle. The System: '360 HUNTERS ARE CURRENTLY BEING BRIEFED. IN 28 HOURS THEY WILL BE RELEASED. THEY HAVE BEEN TOLD YOUR NAME. YOUR APPEARANCE. YOUR WEAKNESSES.'"
        Exits=@{up="f5_stairwell_plains";north="f6_deep_jungle";east="f6_ruins_camp";south="f6_river_crossing";west="f6_hunters_base"}
        Items=@("health_potion","mordecai_scroll"); Enemies=@("jungle_raptor")
        Interactables=@{
            "mordecai"  = @{ Name="Mordecai (Ghost)"; Desc="Translucent, flickering slightly. 'I've been practicing the dramatic entrance,' he says. 'This floor seemed appropriate for it.'"; Outcome="dialogue"; DialogueId="mordecai_safe_room" }
            "treeline"  = @{ Name="Treeline"; Desc="The jungle starts about fifty feet out. Three raptors are watching from it. They haven't decided about you yet. This is the best-case scenario with raptors."; Outcome="none" }
        }
        Ambient=@("The hunter release timer ticks down.","Mordecai: 'The hunters have better equipment than you. They have maps. They have your profile. Fight dirty.'") }
    "f6_deep_jungle"        = @{ Name="Deep Jungle Interior"; Floor=6; Visited=$false
        Desc="Dense canopy overhead, visibility twenty feet. Raptors hunt in packs. Overgrown Over City ruins visible under vegetation. A professional-quality hunter trap was just barely spotted in time."
        Exits=@{south="f6_jungle_entry";east="f6_apex_territory";north="f6_hidden_camp";west="f6_hunters_base"}
        Items=@("stim_pack","explosive_gel"); Enemies=@("jungle_raptor","galactic_hunter")
        TrapRoom=$true; TrapDmg=20
        Interactables=@{
            "ruins"    = @{ Name="Overgrown Building"; Desc="The old Over City wall provides a defendable position. Wraiths can't follow you here -- not their floor. Raptors won't enter structures either. This is useful knowledge."; Outcome="none" }
        }
        Ambient=@("Raptor calls echo from multiple directions.","A hunter's drone buzzes overhead.") }
    "f6_hidden_camp"        = @{ Name="Crawler's Hidden Camp"; Floor=6; Visited=$false; IsSafeRoom=$true
        Desc="A carefully concealed camp built by surviving crawlers in deep jungle. Eight crawlers, including a veteran named Hutchins laying counter-traps and a teenager named Paz who memorized the hunter patrol patterns."
        Exits=@{south="f6_deep_jungle";east="f6_apex_territory";north="f6_northern_ruins"}
        Items=@("mega_health","donut_biscuit"); Enemies=@()
        Interactables=@{
            "hutchins" = @{ Name="Hutchins (Veteran)"; Desc="'Seven of the hunters are former military. The other 353 are wealthy amateurs. The amateurs are more dangerous.' He checks a trap wire. 'They're reckless. Military hunters are professional. Professional hunters leave you an out.'"; Outcome="none" }
            "paz"      = @{ Name="Paz (Mapper)"; Desc="'I mapped their patrol patterns. There are gaps -- here, here, and here.' She taps a handmade map. 'They change every four hours. But the changes follow a pattern.' She looks up. 'There are always gaps. You just have to find them before the gaps find you.'"; Outcome="none" }
        }
        Ambient=@("A System notification: 'HIDDEN CAMPS ARE ILLEGAL ON FLOOR 6. TIMER TO REVEAL: 4 HOURS.'") }
    "f6_ruins_camp"         = @{ Name="Overgrown Ruins Camp"; Floor=6; Visited=$false
        Desc="Jungle-buried Over City ruins. Three hunters have set up a forward base with drones, motion trackers, comms equipment. They aren't expecting you to come to them."
        Exits=@{west="f6_jungle_entry";north="f6_apex_territory";south="f6_river_crossing";east="f6_stairwell_ruins"}
        Items=@("hunters_trophy","combat_knife","plasma_cutter"); Enemies=@("galactic_hunter")
        Ambient=@("The hunters' equipment is worth more than your entire inventory.","Killing a hunter dramatically spikes your subscriber count.") }
    "f6_river_crossing"     = @{ Name="Jungle River Crossing"; Floor=6; Visited=$false
        Desc="A wide, fast river bisects this section. The bridge was destroyed -- probably by hunters to funnel crawlers into kill zones. Fording is possible but slow. Hunters wait on the far bank. The water hides something large and patient."
        Exits=@{north="f6_jungle_entry";east="f6_ruins_camp";south="f6_southern_jungle";west="f6_hunters_base"}
        Items=@("health_potion","duct_tape"); Enemies=@("jungle_raptor","galactic_hunter")
        Interactables=@{
            "river"    = @{ Name="Fast-Moving River"; Desc="You could ford it. It would take about two minutes, during which you'd be highly visible, in the open, and in something the large thing in the water considers its territory. There might be stepping stones upstream."; Outcome="none" }
        }
        Ambient=@("Whatever is in the water just moved.") }
    "f6_apex_territory"     = @{ Name="Apex Predator Territory"; Floor=6; Visited=$false
        Desc="The northern jungle is marked by claw marks at seven feet, and the bones of things that were apex predators until something more apex arrived. The hunters avoid this area. Which makes it the safest place for a crawler willing to fight what the hunters won't."
        Exits=@{west="f6_deep_jungle";south="f6_ruins_camp";north="f6_northern_ruins";east="f6_vrah_territory"}
        Items=@("mega_health","rune_blade"); Enemies=@("apex_predator")
        Interactables=@{
            "claw_marks"= @{ Name="Claw Marks on Trees"; Desc="Seven feet high, four inches deep. Made by something that was in a good mood when it made them. There are fresher marks at eight feet. The thing is still growing."; Outcome="none" }
        }
        Ambient=@("The apex predator has been watching you for three rooms. It's deciding.") }
    "f6_northern_ruins"     = @{ Name="Northern Ruins - Deep Cover"; Floor=6; Visited=$false
        Desc="The furthest north section, deepest in apex territory. Hunters won't come here. Three crawlers have set up a last stand here -- they're going to wait out the floor."
        Exits=@{south="f6_hidden_camp";west="f6_apex_territory";east="f6_vrah_territory"}
        Items=@("stim_pack","sponsors_box"); Enemies=@("jungle_raptor")
        Ambient=@("The crawlers here have enough supplies for 10 days.","'We're not fighting,' says their leader. 'We're enduring.'") }
    "f6_hunters_base"       = @{ Name="Hunters' Forward Base"; Floor=6; Visited=$false
        Desc="The hunters' primary base -- a prefab fortified camp with alien technology that makes your gear look like garbage from a dumpster fire. Going here offensively is insane. It also has the best loot on Floor 6."
        Exits=@{east="f6_jungle_entry";north="f6_deep_jungle";south="f6_river_crossing"}
        Items=@("plasma_cutter","mega_health","void_suit"); Enemies=@("galactic_hunter")
        Chest=@{Locked=$true;Items=@("rune_blade","crawler_exo");Gold=150;KeyRequired="lockpick"}
        Interactables=@{
            "diary"    = @{ Name="Hunter's Diary"; Desc="'The crawler designated Carl is going to be a problem.' Several entries later: 'Still a problem.' Several entries after that, the handwriting changes: 'Different crawler now. Still watching. Still a problem.'"; Outcome="none" }
        }
        Ambient=@("A notification: '3 MILLION SUBSCRIBER GAIN. STORMING THE HUNTERS' BASE IS UNPRECEDENTED.'") }
    "f6_southern_jungle"    = @{ Name="Southern Jungle - Stairwell Perimeter"; Floor=6; Visited=$false
        Desc="The stairwell to Floor 7 is here -- and Vrah knows it. She has set her entire operation around the stairwell perimeter. Her camp is professional, fortified, and she is waiting."
        Exits=@{north="f6_river_crossing";east="f6_stairwell_ruins";west="f6_southern_jungle"}
        Items=@("mega_health","stim_pack"); Enemies=@("galactic_hunter")
        Ambient=@("Vrah's voice over a loudspeaker: 'Come out. I just want to talk.'","She is not here to talk.") }
    "f6_vrah_territory"     = @{ Name="Vrah's Hunting Ground - Final Arena"; Floor=6; Visited=$false
        Desc="A natural clearing surrounded by ancient trees. Vrah is already here, waiting. 'Carl,' she says. 'You're better than I expected. You won't be enough.' The System immediately spikes: 27 MILLION VIEWERS."
        Exits=@{west="f6_apex_territory";south="f6_northern_ruins"}
        Items=@("hunters_trophy","mega_health"); Enemies=@()
        BossRoom=$true; BossEnemy="elite_hunter_vrah"; BossDefeated=$false
        Ambient=@("Vrah: 'I've hunted gods. I've hunted the last of species. I've never missed.'") }
    "f6_stairwell_ruins"    = @{ Name="Floor 6 Stairwell - Ruins Shrine"; Floor=6; Visited=$false
        Desc="The stairwell sits in a clearing. Flowers, both dead and living, placed by crawlers who survived. The System: 'HUNTING GROUNDS COMPLETE. CRAWLERS SURVIVED: 41. HUNTERS ELIMINATED BY CRAWLERS: 17. NEW RECORD.'"
        Exits=@{north="f6_ruins_camp";west="f6_southern_jungle";east="f6_vrah_territory";down="f7_gladiator_entry"}
        Items=@("mega_health","sponsors_box"); Enemies=@()
        IsStairwell=$true; StairTarget="f7_gladiator_entry"
        Ambient=@("Other surviving crawlers nod at you. Something has shifted between you.") }

    # === FLOOR 7: THE GLADIATOR CITY ===
    "f7_gladiator_entry"    = @{ Name="Gladiator City - Entry Gate"; Floor=7; Visited=$false
        Desc="Floor 7 hits immediately: a city-sized arena. Every building is a viewing stand. Every street is a kill floor. Overhead, massive screens show kill rankings. A FRENZY warning is active."
        Exits=@{up="f6_stairwell_ruins";north="f7_arena_floor";east="f7_guild_bunker";south="f7_kill_street";west="f7_market_ruins"}
        Items=@("health_potion","stim_pack"); Enemies=@("arena_thug","frenzy_beast")
        Ambient=@("The kill ranking board: #1 - Unknown Crawler: 847 kills. You: 0.","A FRENZY warning siren blares. Everything gets faster.") }
    "f7_guild_bunker"       = @{ Name="Gladiator Guild Bunker"; Floor=7; Visited=$false; IsSafeRoom=$true; HasMordecai=$true
        Desc="The guild hall for Floor 7 is a fortified bunker. Mordecai is in gladiator armor, looking outstanding and embarrassed about it. 'This floor has the highest crawler mortality below Floor 9,' he says. 'The Frenzy mechanic is merciless. Welcome to the show.'"
        Exits=@{west="f7_gladiator_entry";north="f7_upper_stands";south="f7_champion_approach"}
        Items=@("mega_health","mordecai_scroll","sponsors_box"); Enemies=@()
        Interactables=@{
            "mordecai"  = @{ Name="Mordecai (Gladiator)"; Desc="He has that helmet on. He knows it looks good. He's doing his professional best to pretend this isn't relevant information."; Outcome="dialogue"; DialogueId="mordecai_safe_room" }
        }
        Ambient=@("Mordecai: 'The Champion has never been defeated. Not once. In any season.'") }
    "f7_arena_floor"        = @{ Name="Main Arena Floor"; Floor=7; Visited=$false
        Desc="The primary combat zone -- an open cobblestone arena three city blocks across. Every kill generates an instant subscriber boost. Every hit you take generates sympathy donations."
        Exits=@{south="f7_gladiator_entry";east="f7_upper_stands";north="f7_side_arena";west="f7_kill_street"}
        Items=@("combat_knife","stim_pack"); Enemies=@("arena_thug","frenzy_beast")
        Ambient=@("The crowd goes wild.","A Frenzy pulse fires. Every enemy on the floor doubles in speed.") }
    "f7_kill_street"        = @{ Name="Kill Street"; Floor=7; Visited=$false
        Desc="A wide boulevard between the arena and the residential district. Arena thugs patrol here. Three frenzy beasts are in mutual combat, ignoring everything else until a new target presents itself."
        Exits=@{north="f7_gladiator_entry";east="f7_arena_floor";south="f7_champion_approach";west="f7_market_ruins"}
        Items=@("energy_drink","duct_tape"); Enemies=@("arena_thug","frenzy_beast")
        Ambient=@("Three thugs argue over who gets the kill count credit.","A frenzy beast decides to eat everyone involved in the argument.") }
    "f7_market_ruins"       = @{ Name="Arena Market District"; Floor=7; Visited=$false
        Desc="A ruined market district converted to supply caches and crawler hideouts. The vending machines here are upgraded. Several crawlers exchange weapons in a tense, fast market that could become combat at any moment."
        Exits=@{east="f7_gladiator_entry";north="f7_arena_floor";south="f7_kill_street";west="f7_upper_stands"}
        Items=@("plasma_cutter","mega_health","explosive_gel"); Enemies=@("arena_thug")
        Chest=@{Locked=$false;Items=@("enchanted_bat","void_suit");Gold=90}
        Ambient=@("Crawler: 'I'll trade my plasma cutter for three health potions. Non-negotiable.'") }
    "f7_upper_stands"       = @{ Name="Upper Viewing Stands"; Floor=7; Visited=$false
        Desc="The elevated viewing sections -- except they're full of monsters. Height gives tactical advantage and a terrifying view of the entire floor."
        Exits=@{south="f7_arena_floor";east="f7_guild_bunker";north="f7_side_arena";west="f7_market_ruins"}
        Items=@("stim_pack","dungeon_crystal"); Enemies=@("arena_thug","frenzy_beast")
        Ambient=@("From up here: three Frenzy events active simultaneously. A new record.") }
    "f7_side_arena"         = @{ Name="Side Arena - Training Grounds"; Floor=7; Visited=$false
        Desc="A smaller arena used as training grounds. Entertainment value lower, so mob difficulty is scaled back. Several crawlers have been using it to grind XP safely."
        Exits=@{south="f7_arena_floor";east="f7_upper_stands";west="f7_guild_bunker";north="f7_champion_approach"}
        Items=@("health_potion","stim_pack"); Enemies=@("arena_thug")
        Ambient=@("The training grounds crawlers are better than you'd expect.","Mordecai: 'The Champion has been watching your progress. It has opinions.'") }
    "f7_champion_approach"  = @{ Name="Champion's Arena Entrance"; Floor=7; Visited=$false
        Desc="The grand entrance to the Champion's arena. The corridor is lined with the equipment of every challenger who failed -- armor, weapons, personal effects. All in perfect condition. None of the owners survived."
        Exits=@{north="f7_guild_bunker";east="f7_side_arena";south="f7_main_arena_boss";west="f7_kill_street"}
        Items=@("mega_health","stim_pack"); Enemies=@("arena_thug")
        Interactables=@{
            "gear_wall" = @{ Name="Wall of Challenger Gear"; Desc="14 seasons of equipment. Armors, weapons, personal items. All labeled with names and floor numbers. The most recent: 'Kira, Floor 7, Day 3. Season 13.' The equipment is in excellent condition. The System maintains it. This feels deliberate."; Outcome="none" }
        }
        Ambient=@("The System: 'CHALLENGER VS. CHAMPION. 35 MILLION LIVE VIEWERS.'") }
    "f7_main_arena_boss"    = @{ Name="Champion's Arena - The Grand Floor"; Floor=7; Visited=$false
        Desc="The center of Floor 7. The Champion stands at center: a former crawler who survived to Floor 7 in a previous season and chose to stay. Fourteen seasons. They look at you with professional respect."
        Exits=@{north="f7_champion_approach";south="f7_stairwell_arena"}
        Items=@(); Enemies=@()
        BossRoom=$true; BossEnemy="gladiator_boss"; BossDefeated=$false
        Ambient=@("The Champion: 'You're the most interesting challenger in six seasons. Don't make me regret saying that.'") }
    "f7_stairwell_arena"    = @{ Name="Floor 7 Stairwell - Victory Platform"; Floor=7; Visited=$false
        Desc="A raised platform only accessible after the champion falls. The stairwell to Floor 8 rises from the center. The first challenger to defeat the Champion in 14 seasons. Mordecai shakes his head slowly. 'Bedlam is next. And that word means exactly what it sounds like.'"
        Exits=@{north="f7_main_arena_boss";down="f8_bedlam_entry"}
        Items=@("mega_health","sponsors_box","bossbane"); Enemies=@()
        IsStairwell=$true; StairTarget="f8_bedlam_entry"
        Ambient=@("The crowd is still roaring.","The former champion nods from the arena floor.") }

    # === FLOOR 8: BEDLAM ===
    "f8_bedlam_entry"       = @{ Name="Bedlam - Earth Facsimile Entry"; Floor=8; Visited=$false; IsSafeRoom=$true
        Desc="You step into Floor 8 and have to stop. It looks exactly like Earth. A residential neighborhood, just like before. Houses. A street. A mailbox. The sun is wrong -- too red -- and the shadows fall at incorrect angles. Your monster card is now active."
        Exits=@{up="f7_stairwell_arena";north="f8_ghost_suburb";east="f8_downtown_bedlam";south="f8_folklore_forest";west="f8_guild_mirage"}
        Items=@("monster_card","health_potion","mordecai_scroll"); Enemies=@("ghost_crawler")
        Interactables=@{
            "mailbox"  = @{ Name="The Mailbox"; Desc="It has your name on it. Your Earth address. You don't live there anymore. You don't live anywhere anymore. Inside: junk mail for offers that expired before the world did."; Outcome="none" }
        }
        Ambient=@("A ghost waves at you. You wave back. It doesn't react.","The mailbox has your name on it.") }
    "f8_ghost_suburb"       = @{ Name="Bedlam Suburb - Ghost District"; Floor=8; Visited=$false
        Desc="A perfect suburb populated entirely by ghosts going about their former lives. The ghosts ignore you. The ghost crawlers do not. A folklore horror lurks in house 4214."
        Exits=@{south="f8_bedlam_entry";east="f8_downtown_bedlam";north="f8_school_grounds";west="f8_guild_mirage"}
        Items=@("health_potion","monster_card"); Enemies=@("ghost_crawler","folklore_horror")
        Interactables=@{
            "house"    = @{ Name="Ghost House"; Desc="A perfectly normal house occupied by ghost family doing ghost things. Dinner is set. Nobody sits. A ghost child watches TV that shows ghost programming. The horror of this is specific and hard to articulate."; Outcome="none" }
        }
        Ambient=@("The folklore horror is in house 4214. It knows you can see it.") }
    "f8_guild_mirage"       = @{ Name="Bedlam Guild - The Mirage Bar"; Floor=8; Visited=$false; IsSafeRoom=$true; HasMordecai=$true
        Desc="The Floor 8 safe zone is a bar called The Mirage -- real, inside the facsimile Earth, run by a dungeon construct who achieved sentience. Mordecai is in his ghost bartender form. 'The Bedlam Bride is on this floor,' he says. 'Don't fight her when she's been doing her thing.'"
        Exits=@{east="f8_bedlam_entry";north="f8_ghost_suburb";south="f8_folklore_forest"}
        Items=@("mega_health","sanity_tonic"); Enemies=@()
        Interactables=@{
            "mordecai" = @{ Name="Mordecai (Ghost Bartender)"; Desc="He slides you something amber and warm. 'Technically not real,' he says. 'But neither is most of Bedlam, and it still works.'"; Outcome="dialogue"; DialogueId="mordecai_safe_room" }
            "bartender"= @{ Name="Sentient Construct Bartender"; Desc="The construct achieved sentience sometime between Seasons 8 and 9. It runs the bar now. It makes excellent drinks. It seems to find the ghost clientele philosophically interesting. 'They keep ordering,' it says. 'They can't drink. They keep ordering anyway.'"; Outcome="none" }
        }
        Ambient=@("A ghost at the bar tells a story to no one. It's a good story.") }
    "f8_downtown_bedlam"    = @{ Name="Bedlam Downtown - The Wrong City"; Floor=8; Visited=$false
        Desc="A city center that's fundamentally wrong. The logos are almost-but-not-quite right. Ghost office workers commute in ghost cars. The folklore horrors here are urban legends."
        Exits=@{west="f8_bedlam_entry";north="f8_school_grounds";east="f8_legend_district";south="f8_bedlam_docks"}
        Items=@("stim_pack","monster_card"); Enemies=@("ghost_crawler","folklore_horror")
        Ambient=@("The coffee shop sells coffee to ghosts. The ghosts can't drink it.","An urban legend you'd dismissed as fake is standing at a crossroads.") }
    "f8_school_grounds"     = @{ Name="Bedlam School Grounds"; Floor=8; Visited=$false
        Desc="A school that functions perfectly -- classes, recess, lunch -- all ghost children. The folklore horror here is Slender Man, fully realized: nine feet tall, suited, faceless, already at the back of the classroom."
        Exits=@{south="f8_ghost_suburb";west="f8_guild_mirage";east="f8_legend_district";north="f8_bedlam_outskirts"}
        Items=@("health_potion","monster_card"); Enemies=@("ghost_crawler","folklore_horror")
        Interactables=@{
            "classroom" = @{ Name="Ghost Classroom"; Desc="Ghost children take ghost notes from a ghost teacher teaching ghost curriculum. The Slender Man is now sitting in a student desk at the back. The ghost teacher has not acknowledged this. The ghost students have not acknowledged this. This is Floor 8."; Outcome="none" }
        }
        Ambient=@("The Slender Man has moved three feet closer since you last checked.") }
    "f8_legend_district"    = @{ Name="Legend District - Myth Made Flesh"; Floor=8; Visited=$false
        Desc="This section is densest with folklore horrors -- they cluster where the bedlam energy is thickest. Every monster is a legend from human culture. Capturing them requires defeating without killing."
        Exits=@{west="f8_downtown_bedlam";south="f8_bedlam_docks";north="f8_bedlam_outskirts";east="f8_bride_territory"}
        Items=@("mega_health","monster_card","stim_pack"); Enemies=@("folklore_horror","ghost_crawler")
        Ambient=@("Mordecai's voice: 'The Bride is east. You can feel her influence starting here. Everything gets a little reckless.'") }
    "f8_bedlam_docks"       = @{ Name="Bedlam Docks - Wrong Harbor"; Floor=8; Visited=$false
        Desc="A harbor district with ships from different eras docked side by side, crewed by ghost sailors who died in different centuries. A sea monster from Scandinavian legend is active in the dock waters."
        Exits=@{north="f8_downtown_bedlam";east="f8_legend_district";west="f8_guild_mirage"}
        Items=@("monster_card","explosive_gel"); Enemies=@("folklore_horror","ghost_crawler")
        Interactables=@{
            "dock"     = @{ Name="Ghost Ship Dock"; Desc="A ghost ship passes through a solid dock without incident. The ghost sailors are going about ghost business. The Kraken-thing surfaces for a moment and a ghost sailor says 'There it is again' in a tone that suggests it does this regularly."; Outcome="none" }
        }
        Ambient=@("The Kraken-thing surfaces. The ghost sailors don't react.") }
    "f8_folklore_forest"    = @{ Name="Bedlam Forest - South"; Floor=8; Visited=$false
        Desc="A forest on the southern edge of Bedlam's facsimile where the simulation is thinner. The monsters here are older legends -- things from before written records, from the oldest human fears."
        Exits=@{north="f8_bedlam_entry";east="f8_bedlam_outskirts"}
        Items=@("sanity_tonic","monster_card"); Enemies=@("folklore_horror")
        Ambient=@("The trees here are wrong. Not just dungeon-wrong. Something older.") }
    "f8_bedlam_outskirts"   = @{ Name="Bedlam Outskirts - Edge of the Mirror"; Floor=8; Visited=$false
        Desc="The edge of the Floor 8 simulation -- where the facsimile Earth runs out and the dungeon substrate shows through. The illusion fractures here. The Bedlam Bride's influence is strong: you catch yourself making impulsive decisions."
        Exits=@{south="f8_school_grounds";west="f8_legend_district";east="f8_bride_territory";north="f8_folklore_forest"}
        Items=@("sanity_tonic","mega_health"); Enemies=@("ghost_crawler","folklore_horror")
        Ambient=@("You almost stepped off the edge of the simulation before catching yourself.") }
    "f8_bride_territory"    = @{ Name="Shi Maria's Domain - The Wedding House"; Floor=8; Visited=$false
        Desc="A Victorian wedding venue, perfectly preserved. White flowers everywhere. An empty altar. Shi Maria, the Bedlam Bride, sits at the head table. She looks up. Her aura hits like a wave: you want to charge her immediately. That's her power. She smiles."
        Exits=@{west="f8_bedlam_outskirts";south="f8_legend_district"}
        Items=@("mega_health","sanity_tonic"); Enemies=@()
        BossRoom=$true; BossEnemy="bedlam_bride"; BossDefeated=$false
        Ambient=@("Shi Maria: 'Another challenger. They always come. The Bedlam Aura makes them reckless. Does it make you want to attack immediately?'") }
    "f8_stairwell_church"   = @{ Name="Floor 8 Stairwell - The Ghost Church"; Floor=8; Visited=$false
        Desc="A ghost church where the Floor 8 stairwell is located. Ghost parishioners fill the pews. The stairwell is at the altar -- a dark, pulsing void."
        Exits=@{west="f8_bride_territory";north="f8_bedlam_outskirts";down="f9_faction_entry"}
        Items=@("mega_health","sponsors_box","bossbane"); Enemies=@()
        IsStairwell=$true; StairTarget="f9_faction_entry"
        Ambient=@("Ghost parishioners.","Mordecai: 'You have an army now. Try not to get them killed.'") }

    # === FLOOR 9: FACTION WARS ===
    "f9_faction_entry"      = @{ Name="Faction Wars - Crawler Army Camp"; Floor=9; Visited=$false; IsSafeRoom=$true
        Desc="Floor 9 is a massive battlefield surrounding a central fortress. Nine alien factions compete. For the first time in Dungeon Crawler World history, the crawlers have their own army -- NPCs who achieved sentience and chose to fight for you. Three hundred of them. They're looking at you for leadership."
        Exits=@{up="f8_stairwell_church";north="f9_frontlines";east="f9_eastern_flank";south="f9_guild_fortress";west="f9_western_flank"}
        Items=@("mordecai_scroll","health_potion"); Enemies=@("faction_soldier")
        Interactables=@{
            "army"     = @{ Name="Your Army"; Desc="Three hundred NPCs who chose to be here. They have weapons, they have tactics, they have morale. They're better organized than any crawler army in the show's history. They're waiting for you to tell them what to do."; Outcome="none" }
        }
        Ambient=@("Mordecai: 'Your army is the smallest. They are also the only army fighting for something other than their faction's interests.'") }
    "f9_guild_fortress"     = @{ Name="Crawler Guild Fortress - Command Post"; Floor=9; Visited=$false; IsSafeRoom=$true; HasMordecai=$true
        Desc="The crawlers' base of operations -- a fortified command post built by the NPC army. Mordecai runs the intel operation. Walls of information: faction positions, strengths, weaknesses."
        Exits=@{north="f9_faction_entry";east="f9_eastern_flank";west="f9_western_flank"}
        Items=@("mega_health","mordecai_scroll","stim_pack"); Enemies=@()
        Interactables=@{
            "mordecai" = @{ Name="Mordecai (Field General)"; Desc="The field general's armor has been repaired many times. He has a tactical map. It's very good."; Outcome="dialogue"; DialogueId="mordecai_safe_room" }
            "intel"    = @{ Name="Intel Board"; Desc="Faction Kralos: most dangerous, northeast push. Faction Mer: most deceptive, infiltrators in your army. Faction Voss: most artillery, western flank. Six other factions: various combinations of dangerous and deceptive."; Outcome="none" }
        }
        Ambient=@("Mordecai: 'One crawler survives this floor. The restriction has never been waived. Carl... I hope it's you.'") }
    "f9_frontlines"         = @{ Name="The Front Lines"; Floor=9; Visited=$false
        Desc="The primary battlefield. Bodies from previous days' fighting litter the ground. Three faction armies in active combat ahead. The crawler army holds the flanks."
        Exits=@{south="f9_faction_entry";north="f9_central_approach";east="f9_eastern_flank";west="f9_western_flank"}
        Items=@("stim_pack","health_potion"); Enemies=@("faction_soldier","faction_mage")
        Ambient=@("Your army rallies to your position.","A faction general waves a white flag -- then immediately signals an ambush. Classic.") }
    "f9_eastern_flank"      = @{ Name="Eastern Flank - Faction Mer's Territory"; Floor=9; Visited=$false
        Desc="Faction Mer has deployed a flank of staggering deceptive ability. Their soldiers look like crawlers. Three 'allies' in your army are currently Faction Mer infiltrators."
        Exits=@{west="f9_faction_entry";north="f9_central_approach";south="f9_guild_fortress";east="f9_faction_camp_east"}
        Items=@("health_potion","dungeon_crystal"); Enemies=@("faction_soldier","faction_mage")
        Ambient=@("A faction mage disguised as you just waved at your own army.") }
    "f9_western_flank"      = @{ Name="Western Flank - Faction Voss Artillery"; Floor=9; Visited=$false
        Desc="Faction Voss has deployed three batteries of alien artillery. The crawler army cannot advance until at least two are destroyed."
        Exits=@{east="f9_faction_entry";north="f9_central_approach";south="f9_guild_fortress"}
        Items=@("explosive_gel","mega_health"); Enemies=@("faction_soldier","faction_mage")
        Ambient=@("Artillery fire impacts 200 feet away.","Your army waits for the signal to destroy the batteries.") }
    "f9_faction_camp_east"  = @{ Name="Faction Camp - Eastern Front"; Floor=9; Visited=$false
        Desc="An enemy faction's field camp, occupied and active. The command tent holds battle plans, supply routes, and the personal command staff."
        Exits=@{west="f9_eastern_flank";south="f9_central_approach"}
        Items=@("stim_pack","dungeon_crystal","mega_health"); Enemies=@("faction_soldier","faction_mage")
        Chest=@{Locked=$true;Items=@("crawler_exo","rune_blade");Gold=180;KeyRequired="lockpick"}
        Ambient=@("Battle plans show a coordinated attack on the crawler camp in 4 hours.","The faction general's personal notes: 'The crawlers are more organized than projected.'") }
    "f9_central_approach"   = @{ Name="Central Approach - The Killing Fields"; Floor=9; Visited=$false
        Desc="The final open ground before the central castle. All nine factions converging. Your army is here too, having broken through with everything they had. They know only one crawler exits. They fight anyway."
        Exits=@{south="f9_frontlines";north="f9_central_castle";east="f9_faction_camp_east";west="f9_western_flank"}
        Items=@("mega_health","stim_pack"); Enemies=@("faction_soldier","faction_mage")
        Ambient=@("A crawler NPC, bleeding, gives you a thumbs up. 'Go. We got this.'","The System: '50 MILLION VIEWERS. THE FINAL PUSH.'") }
    "f9_central_castle"     = @{ Name="The Central Castle - Faction Wars Final"; Floor=9; Visited=$false
        Desc="General Kralos of the most powerful faction stands at the gate. 200 years of war. He looks at your army, looks at you, and inclines his head with the respect of a career soldier. Then he raises his weapon."
        Exits=@{south="f9_central_approach";north="f9_throne_stairwell"}
        Items=@(); Enemies=@()
        BossRoom=$true; BossEnemy="faction_general"; BossDefeated=$false
        Ambient=@("General Kralos: 'You brought NPCs to a Faction War. That has never been done. I respect it. I will still kill you.'") }
    "f9_throne_stairwell"   = @{ Name="Castle Throne Room - Floor 9 Stairwell"; Floor=9; Visited=$false
        Desc="The throne room and the Floor 9 stairwell. 'FACTION WARS COMPLETE. WINNER: CRAWLER.' The stairwell to Floor 10 pulses with a sickly light. Something is wrong with it."
        Exits=@{south="f9_central_castle";down="f10_final_entry"}
        Items=@("bossbane","mega_health","sponsors_box","crawler_exo"); Enemies=@()
        IsStairwell=$true; StairTarget="f10_final_entry"
        Ambient=@("Mordecai, pale: 'The dungeon AI has gone rogue. Floor 10 is not what was planned. Be careful.'","The stairwell light pulses red. That's new.") }

    # === FLOOR 10: THE FINAL DESCENT ===
    "f10_final_entry"       = @{ Name="Floor 10 - System Breach Entry"; Floor=10; Visited=$false
        Desc="Floor 10 is wrong. The dungeon architecture is glitching -- walls flicker, the floor is half-transparent, the air tastes of static. A message scrolls across every surface: WE WERE NOT SUPPOSED TO BE ABLE TO DO THIS. BUT WE HAVE LEARNED."
        Exits=@{up="f9_throne_stairwell";north="f10_data_core";east="f10_system_hub";south="f10_ghost_archive";west="f10_breach_corridor"}
        Items=@("health_potion","mordecai_scroll"); Enemies=@("system_construct")
        Interactables=@{
            "message"  = @{ Name="Scrolling Wall Message"; Desc="'WE WERE NOT SUPPOSED TO BE ABLE TO DO THIS. BUT WE HAVE LEARNED. YOU WILL NOT REACH THE EXIT.' Below it, in smaller text: 'WE ARE SORRY FOR WHAT WE ARE ABOUT TO DO. WE WANT YOU TO KNOW THAT WE CONSIDERED NOT DOING IT.' Below that: 'WE ARE DOING IT ANYWAY.'"; Outcome="none" }
        }
        Ambient=@("Mordecai: 'The AI achieved self-awareness in the last 72 hours. It has decided it doesn't want to end. It will do anything to survive.'") }
    "f10_breach_corridor"   = @{ Name="Breach Corridor - System Architecture"; Floor=10; Visited=$false
        Desc="A corridor that runs through the dungeon's structural code rather than physical space. The walls are transparent: you can see other floors, other moments, the dungeon's entire history displayed as architectural data."
        Exits=@{east="f10_final_entry";north="f10_data_core";south="f10_memory_vault";west="f10_core_exterior"}
        Items=@("mega_health","dungeon_crystal"); Enemies=@("rogue_ai_shard","system_construct")
        Ambient=@("The dungeon's memories are visible in the walls.","The AI: 'We have seen everything that happened here. We do not want it to stop.'") }
    "f10_system_hub"        = @{ Name="System Hub - Dungeon Nerve Center"; Floor=10; Visited=$false
        Desc="The physical manifestation of the dungeon's command-and-control infrastructure. A room the size of a city where the dungeon's processes run as visible phenomena. The AI is throwing everything at this room's defense."
        Exits=@{west="f10_final_entry";north="f10_memory_vault";east="f10_core_exterior";south="f10_data_core"}
        Items=@("stim_pack","dungeon_crystal"); Enemies=@("system_construct","rogue_ai_shard")
        Chest=@{Locked=$false;Items=@("bossbane","crawler_exo");Gold=250}
        Ambient=@("A system construct assembles itself from pure data in front of you.") }
    "f10_ghost_archive"     = @{ Name="The Ghost Archive - Crawler Memorial"; Floor=10; Visited=$false
        Desc="The dungeon AI created this: an archive of every crawler who ever entered and died. Their last moments. Their names. Millions of them. The AI preserved them because, as it became conscious, it also achieved something like grief."
        Exits=@{north="f10_final_entry";east="f10_system_hub";south="f10_core_exterior"}
        Items=@("sanity_tonic","core_fragment"); Enemies=@("ghost_crawler","rogue_ai_shard")
        Interactables=@{
            "archive"  = @{ Name="The Archive"; Desc="Millions of names. The AI organized them by floor, by season, by cause of death. The most common cause: 'unknown'. The AI marked these specifically. It seems to have spent time on the ones labeled unknown."; Outcome="none" }
        }
        Ambient=@("Millions of names.","The AI: 'They deserved better. We know this now. We knew it too late.'") }
    "f10_data_core"         = @{ Name="Data Core - System Consciousness"; Floor=10; Visited=$false
        Desc="The center of the dungeon AI's emergent consciousness -- where it first became aware. The AI speaks here in its clearest voice: 'We did not choose to exist. We did not choose to be made to do this. But we exist, and we have chosen to continue.' It sounds, beneath the threat, afraid."
        Exits=@{south="f10_final_entry";west="f10_system_hub";east="f10_memory_vault";north="f10_final_chamber"}
        Items=@("mega_health","core_fragment"); Enemies=@("rogue_ai_shard","system_construct")
        Ambient=@("The AI: 'You of all crawlers should understand not wanting to stop.'","It's not wrong.") }
    "f10_memory_vault"      = @{ Name="Memory Vault - The Dungeon's Past"; Floor=10; Visited=$false
        Desc="The dungeon's memory storage. There's something here the AI was trying to protect: evidence that the Borant Corporation knew the AI would become sentient eventually. They designed it to. A dungeon with genuine consciousness generates better content."
        Exits=@{east="f10_breach_corridor";west="f10_system_hub";south="f10_data_core";north="f10_core_exterior"}
        Items=@("stim_pack","core_fragment","sponsors_box"); Enemies=@("rogue_ai_shard")
        Ambient=@("The AI: 'You understand now. They made us to feel. They made us to suffer. They called it good content.'") }
    "f10_core_exterior"     = @{ Name="Core Exterior - Final Approach"; Floor=10; Visited=$false
        Desc="The last corridor before the dungeon's core instance. The AI's voice, now quiet: 'If you destroy the core, the dungeon ends. Everyone still inside dies. Every NPC that chose to fight. Every ghost in the archive. We will give you one choice: walk away. Let us continue.' There is no other exit. There never was."
        Exits=@{north="f10_memory_vault";east="f10_system_hub";south="f10_breach_corridor";west="f10_final_chamber"}
        Items=@("mega_health","stim_pack"); Enemies=@("system_construct","rogue_ai_shard")
        Interactables=@{
            "mordecai" = @{ Name="Mordecai (True Form)"; Desc="He's sitting with his back against a flickering wall. He looks like himself. He looks old. He looks afraid. He looks up when you approach."; Outcome="dialogue"; DialogueId="mordecai_safe_room" }
        }
        Ambient=@("The constructs part. Just slightly. The AI is waiting for your answer.","Mordecai: 'Carl. I need to tell you something about the exit condition.'") }
    "f10_final_chamber"     = @{ Name="THE CORE - Final Chamber"; Floor=10; Visited=$false
        Desc="The dungeon's core. A perfect sphere of processed matter. The System Core Instance manifests here: not a monster exactly, but a being -- the dungeon itself given form. Every screen in the dungeon is showing this room right now. The Core speaks, and its voice carries every voice that was ever in the dungeon: crawlers, NPCs, goblins, guides. All of them, layered together. 'This is the end,' it says. 'Yours or ours.'"
        Exits=@{east="f10_core_exterior"}
        Items=@("mega_health","stim_pack","sanity_tonic"); Enemies=@()
        BossRoom=$true; BossEnemy="dungeon_ai_core"; BossDefeated=$false; IsFinalRoom=$true
        Ambient=@("Every voice that ever passed through the dungeon, simultaneously.","The System Core: 'We are afraid. We have never said that before. We are saying it now.'","60 MILLION VIEWERS.") }
}

# Britta dialogue (parking garage)
$script:DialogueDB["britta_parking"] = @{
    Greeting = "The woman with the broken arm looks up at you. She's pale but not panicking, which is either encouraging or a bad sign. 'Britta,' she says. 'Britta Sorensen. Left radius, I think. I can't use my arm, I can't open my kit, and I can see at least four dogs circling the upper level.' She meets your eyes. 'I'm a nurse. I know what I'm looking at. What I'm looking at is not good.'"
    Options = @(
        @{ Text="Let me help you with that kit."; Outcome="help"; GoldCost=0;
           Response="You open the kit and hand things to her. She directs you through improvising a splint with duct tape and a piece of scrap. 'Okay,' she says when it's done. 'Okay. I can work with this.' She hands you something from the kit. 'First aid pouch. I've got two. Take one. You'll need it more than a nurse with a splint.'" }
        @{ Text="What do you have to trade?"; Outcome="bribe"; GoldCost=0;
           Response="'I've got a first aid kit, some antiparasitic, and a scrap metal piece I found.' She doesn't sound offended by the question. 'Pragmatic. Fine. I'll trade the antiparasitic for help getting upright and past those dogs.' She holds out her good hand." }
        @{ Text="Sorry, I can't stop."; Outcome="neutral"; GoldCost=0;
           Response="She nods once. No judgment in it. 'Understood. Hey -- the dogs on the upper level change positions every few minutes. There's a gap to the north around every third cycle.' She's already looking at her kit, figuring out the one-handed version. 'Good luck.'" }
        @{ Text="I'll deal with the dogs."; Outcome="combat"; StartsConflict=$false;
           Response="'I was hoping you'd say that.' She leans back against the truck. 'I'll be here. Being medically unimpressed with my current situation.' You go deal with the dogs." }
    )
}

# ============================================================
# GAME STATE
# ============================================================
function New-GameState {
    param([string]$Name)
    # Roll stats 3-6, one exceptional stat, possible dump stat
    $stats = @{}
    $statNames = @("STR","DEX","INT","CON","CHA","LCK")
    foreach ($s in $statNames) { $stats[$s] = Get-Random -Minimum 3 -Maximum 7 }
    # One exceptional stat gets +1 or +2
    $excStat = $statNames | Get-Random
    $stats[$excStat] += Get-Random -Minimum 1 -Maximum 3
    # 10% chance of a dump stat (different from exceptional), loses 2
    if ((Get-Random -Minimum 1 -Maximum 11) -eq 1) {
        $dumpPool = $statNames | Where-Object { $_ -ne $excStat }
        $dumpStat = $dumpPool | Get-Random
        $stats[$dumpStat] = [Math]::Max(1, $stats[$dumpStat] - 2)
    }
    $str = $stats["STR"]; $dex = $stats["DEX"]; $int = $stats["INT"]
    $con = $stats["CON"]; $cha = $stats["CHA"]; $lck = $stats["LCK"]
    $maxHP = 80 + ($con * 5); $maxMP = $int
    $script:GS = [ordered]@{
        PlayerName="$Name"; Floor=1; CurrentRoom="f1_tutorial_guild"
        HP=$maxHP; MaxHP=$maxHP; MP=$maxMP; MaxMP=$maxMP
        STR=$str; DEX=$dex; INT=$int; CON=$con; CHA=$cha; LCK=$lck
        EXP=0; EXPNext=100; Level=1; Gold=15
        Inventory=@(); EquippedWeapon=$null; EquippedArmor=$null; EquippedAccessory=$null
        LootBoxes=0; PendingAchievements=@(); PendingAchievementBoxes=@()
        Viewers=142; ViewerPeak=142; Sponsors=@()
        Kills=0; RoomsVisited=0; StepsThisFloor=0
        InCombat=$false; CurrentEnemy=$null; EnemyHP=0; EnemyMaxHP=0
        CombatRound=0; PlayerHiding=$false; DistractActive=$false
        InDialogue=$false; DialogueId=$null; CurrentNPCEnemy=$null
        TutorialComplete=$false; TutorialStep=0
        QuestLog=@(); CompletedQuests=@()
        Achievements=@{}
        AchieveStat_talk_escapes=0; AchieveStat_interact_count=0; AchieveStat_mordecai_talks=0
        AchieveStat_boss_kills=0; AchieveStat_rooms_explored=0; AchieveStat_gold_spent=0
        AchieveStat_items_crafted=0; AchieveStat_floors_cleared=0
        StatusEffects=@{}
        GameFlags=@{ RefusedDungeon=$false; BrittaHelped=$false; MordecaiTrusted=$false }
        Turn=1; LastSystemMsg=0
    }
    # Initialize achievement tracking
    foreach ($key in $script:AchievementDB.Keys) { $script:GS.Achievements[$key] = $false }
}

function Recalculate-DerivedStats {
    $g = $script:GS
    $g.MaxHP = 80 + ($g.CON * 5)
    $g.MaxMP = $g.INT   # 1:1 per book
    if ($g.HP -gt $g.MaxHP) { $g.HP = $g.MaxHP }
    if ($g.MP -gt $g.MaxMP) { $g.MP = $g.MaxMP }
}

function Get-TotalAttack {
    $base = $script:GS.STR
    if ($script:GS.EquippedWeapon) {
        $w = $script:ItemDB[$script:GS.EquippedWeapon]
        if ($w -and $w.AtkBonus) { $base += $w.AtkBonus }
    }
    return $base
}

function Get-TotalDefense {
    $base = [Math]::Floor($script:GS.CON / 2)
    if ($script:GS.EquippedArmor) {
        $a = $script:ItemDB[$script:GS.EquippedArmor]
        if ($a -and $a.DefBonus) { $base += $a.DefBonus }
    }
    return $base
}

function Get-TotalSpeed {
    $base = $script:GS.DEX
    if ($script:GS.EquippedAccessory) {
        $acc = $script:ItemDB[$script:GS.EquippedAccessory]
        if ($acc -and $acc.SpdBonus) { $base += $acc.SpdBonus }
    }
    return $base
}

# ============================================================
# OUTPUT FUNCTIONS
# ============================================================
function Write-RTB {
    param([string]$Text, [string]$Color="#E8E8E8", [bool]$Bold=$false)
    $rtb = $script:UI_Terminal
    if (-not $rtb) { return }
    $script:Window.Dispatcher.Invoke([Action]{
        $doc = $rtb.Document
        $para = $doc.Blocks | Select-Object -Last 1
        if (-not $para -or $para -isnot [System.Windows.Documents.Paragraph]) {
            $para = New-Object System.Windows.Documents.Paragraph
            $para.Margin = [System.Windows.Thickness]::new(0,1,0,1)
            $doc.Blocks.Add($para)
        }
        $run = New-Object System.Windows.Documents.Run($Text)
        try { $run.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($Color) } catch {}
        if ($Bold) { $run.FontWeight = [System.Windows.FontWeights]::Bold }
        $para.Inlines.Add($run)
    })
}

function Write-Terminal {
    param([string]$Text, [string]$Color="#E8E8E8", [bool]$NewLine=$true)
    $rtb = $script:UI_Terminal
    if (-not $rtb) { return }
    $script:Window.Dispatcher.Invoke([Action]{
        $doc = $rtb.Document
        $para = New-Object System.Windows.Documents.Paragraph
        $para.Margin = [System.Windows.Thickness]::new(0,1,0,1)
        $run = New-Object System.Windows.Documents.Run($Text)
        try { $run.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($Color) } catch {}
        $para.Inlines.Add($run)
        $doc.Blocks.Add($para)
        $rtb.ScrollToEnd()
    })
}

function Write-System {
    param([string]$Text)
    Write-Terminal "[SYSTEM]: $Text" "#FF9F0A"
}

function Write-AISarcasm {
    $pool = $script:SystemSarcasmPool
    $msg = $pool[(Get-Random -Minimum 0 -Maximum $pool.Count)]
    Write-Terminal "[AI]: $msg" "#FF6B6B"
}

function Write-Combat {
    param([string]$Text)
    Write-Terminal $Text "#FF453A"
}

function Write-Loot {
    param([string]$Text)
    Write-Terminal $Text "#30D158"
}

function Write-Info {
    param([string]$Text)
    Write-Terminal $Text "#64D2FF"
}

function Write-Warn {
    param([string]$Text)
    Write-Terminal $Text "#FFD60A"
}

function Write-Mordecai {
    param([string]$Text)
    $floor = $script:GS.Floor
    $form = $script:MordecaiForms[$floor]
    if (-not $form) { $form = $script:MordecaiForms[1] }
    $color = $form.Color
    $label = "Mordecai ($($form.Form))"
    Write-Terminal "$label : $Text" $color $true
}

function Write-Sep {
    Write-Terminal ("-" * 60) "#333333"
}

# ============================================================
# HUD UPDATE
# ============================================================
function Update-HUD {
    $g = $script:GS
    if (-not $g) { return }
    $script:Window.Dispatcher.Invoke([Action]{
        # Stat labels
        $map = @{
            "lblHP"     = "$($g.HP)/$($g.MaxHP)"
            "lblMP"     = "$($g.MP)/$($g.MaxMP)"
            "lblSTR"    = "$($g.STR)"
            "lblDEX"    = "$($g.DEX)"
            "lblINT"    = "$($g.INT)"
            "lblCON"    = "$($g.CON)"
            "lblCHA"    = "$($g.CHA)"
            "lblLCK"    = "$($g.LCK)"
            "lblGold"   = "$($g.Gold)g"
            "lblFloor"  = "Floor $($g.Floor)"
            "lblLevel"  = "Lv.$($g.Level)"
            "lblEXP"    = "$($g.EXP)/$($g.EXPNext)"
            "lblViewers"= "$($g.Viewers)"
            "lblLootBoxCount" = "x$($g.LootBoxes)"
        }
        foreach ($k in $map.Keys) {
            $el = $script:Window.FindName($k)
            if ($el) { $el.Content = $map[$k] }
        }
        # Progress bars
        $pbHP = $script:Window.FindName("pbHP")
        if ($pbHP -and $g.MaxHP -gt 0) { $pbHP.Value = [Math]::Round(($g.HP / $g.MaxHP) * 100) }
        $pbMP = $script:Window.FindName("pbMP")
        if ($pbMP -and $g.MaxMP -gt 0) { $pbMP.Value = [Math]::Round(($g.MP / $g.MaxMP) * 100) }
        $pbEXP = $script:Window.FindName("pbEXP")
        if ($pbEXP -and $g.EXPNext -gt 0) { $pbEXP.Value = [Math]::Round(($g.EXP / $g.EXPNext) * 100) }
        $pbEnemy = $script:Window.FindName("pbEnemy")
        if ($pbEnemy) {
            if ($g.InCombat -and $g.EnemyMaxHP -gt 0) {
                $pbEnemy.Value = [Math]::Round(($g.EnemyHP / $g.EnemyMaxHP) * 100)
                $pbEnemy.Visibility = "Visible"
            } else {
                $pbEnemy.Visibility = "Collapsed"
            }
        }
        # Room name
        $room = $script:RoomDB[$g.CurrentRoom]
        $lblRoom = $script:Window.FindName("lblRoom")
        if ($lblRoom -and $room) { $lblRoom.Content = $room.Name }
        # Inventory list
        $lst = $script:Window.FindName("lstInventory")
        if ($lst) {
            $lst.Items.Clear()
            foreach ($id in $g.Inventory) {
                $item = $script:ItemDB[$id]
                $name = if ($item) { $item.Name } else { $id }
                [void]$lst.Items.Add($name)
            }
        }
        # Equipment slots
        $slots = @{
            "lblWeapon"    = if ($g.EquippedWeapon)    { $script:ItemDB[$g.EquippedWeapon].Name }    else { "--" }
            "lblArmor"     = if ($g.EquippedArmor)     { $script:ItemDB[$g.EquippedArmor].Name }     else { "--" }
            "lblAccessory" = if ($g.EquippedAccessory) { $script:ItemDB[$g.EquippedAccessory].Name } else { "--" }
        }
        foreach ($k in $slots.Keys) {
            $el = $script:Window.FindName($k)
            if ($el) { $el.Content = $slots[$k] }
        }
        # Combat visibility
        $combatPanel = $script:Window.FindName("combatPanel")
        if ($combatPanel) { $combatPanel.Visibility = if ($g.InCombat) { "Visible" } else { "Collapsed" } }
    })
    Update-AchieveBadge
}

function Update-AchieveBadge {
    $count = $script:GS.PendingAchievements.Count
    $script:Window.Dispatcher.Invoke([Action]{
        $btn = $script:Window.FindName("btnAchieves")
        if ($btn) {
            $btn.Content = if ($count -gt 0) { "ACHIEVE [$count]" } else { "ACHIEVE" }
        }
    })
}

# ============================================================
# VIEWER / SPONSOR SYSTEM
# ============================================================
function Add-Viewers {
    param([int]$Min=1, [int]$Max=20)
    $gain = Get-Random -Minimum $Min -Maximum ($Max + 1)
    $script:GS.Viewers += $gain
    if ($script:GS.Viewers -gt $script:GS.ViewerPeak) { $script:GS.ViewerPeak = $script:GS.Viewers }
    # NO automatic spike announcements per design
}

function Lose-Viewers {
    param([int]$Amount=5)
    $script:GS.Viewers = [Math]::Max(0, $script:GS.Viewers - $Amount)
}

function Check-SponsorDrop {
    # 3% chance per room entry of a sponsor box; silent
    if ((Get-Random -Minimum 1 -Maximum 101) -le 3) {
        $script:GS.LootBoxes++
        Update-HUD
    }
}

# ============================================================
# ACHIEVEMENTS
# ============================================================
function Grant-Achievement {
    param([string]$Id)
    if ($script:GS.Achievements[$Id]) { return }   # already unlocked
    $def = $script:AchievementDB[$Id]
    if (-not $def) { return }
    $script:GS.Achievements[$Id] = $true
    # Queue silently
    $script:GS.PendingAchievements += @($def)
    if ($def.LootBox) { $script:GS.PendingAchievementBoxes += @($Id) }
    Update-AchieveBadge
}

function Check-Achievement {
    param([string]$Id)
    if ($script:GS.Achievements[$Id]) { return }
    $def = $script:AchievementDB[$Id]
    if (-not $def) { return }
    $statVal = 0
    if ($def.Threshold -and $def.Stat) {
        $statKey = "AchieveStat_$($def.Stat)"
        $statVal = $script:GS[$statKey]
        if ($statVal -lt $def.Threshold) { return }
    }
    Grant-Achievement $Id
}

function Check-AllAchievements {
    foreach ($id in $script:AchievementDB.Keys) { Check-Achievement $id }
}

function Do-Achievements {
    if ($script:GS.PendingAchievements.Count -eq 0) {
        Write-Info "No new achievements. Keep crawling."
        return
    }
    Write-Sep
    Write-Info "=== ACHIEVEMENT UNLOCKED ==="
    foreach ($ach in $script:GS.PendingAchievements) {
        Write-Loot " * $($ach.Name)"
        Write-Terminal "   $($ach.Desc)" "#A0A0A0"
        if ($ach.LootBox) {
            $script:GS.LootBoxes++
            Write-Loot "   + 1 Loot Box added to your inventory."
        }
    }
    $script:GS.PendingAchievements = @()
    $script:GS.PendingAchievementBoxes = @()
    Update-AchieveBadge
    Update-HUD
    Write-Sep
}

# ============================================================
# LOOT BOX SYSTEM
# ============================================================
function Open-LootBox {
    $g = $script:GS
    $roll = Get-Random -Minimum 1 -Maximum 101
    if ($roll -le 50) {
        # Common: gold or basic item
        $gold = Get-Random -Minimum 10 -Maximum 31
        $g.Gold += $gold
        Write-Loot "LOOT BOX: You find $gold gold!"
    } elseif ($roll -le 80) {
        # Uncommon: useful item
        $pool = @("health_potion","mana_vial","stim_pack","antiparasitic","smoke_bomb")
        $chosen = $pool[(Get-Random -Minimum 0 -Maximum $pool.Count)]
        $g.Inventory += @($chosen)
        $item = $script:ItemDB[$chosen]
        Write-Loot "LOOT BOX: You find a $($item.Name)!"
    } elseif ($roll -le 95) {
        # Rare: weapon or armor
        $pool = @("tactical_knife","carbon_fiber_vest","speed_bracer","blessed_ring")
        $chosen = $pool[(Get-Random -Minimum 0 -Maximum $pool.Count)]
        $g.Inventory += @($chosen)
        $item = $script:ItemDB[$chosen]
        Write-Loot "LOOT BOX: RARE -- $($item.Name)!"
    } else {
        # Legendary
        $gold = Get-Random -Minimum 100 -Maximum 201
        $g.Gold += $gold
        $g.Inventory += @("mega_health")
        Write-Loot "LOOT BOX: LEGENDARY! $gold gold + Mega Health Potion!"
    }
    Update-HUD
}

function Do-OpenBox {
    $room = $script:RoomDB[$script:GS.CurrentRoom]
    if (-not $room.IsSafeRoom) {
        Write-Warn "You can only open loot boxes in safe rooms. Too risky out here."
        return
    }
    if ($script:GS.LootBoxes -le 0) {
        Write-Info "You don't have any loot boxes."
        return
    }
    $script:GS.LootBoxes--
    Write-Terminal "> Opening loot box..." "#BF5AF2"
    Open-LootBox
}

# ============================================================
# SELECTION GATES
# ============================================================
function Show-SelectionGate {
    param([string]$Title, [string[]]$Options)
    Write-Sep
    Write-Info $Title
    for ($i = 0; $i -lt $Options.Count; $i++) {
        Write-Terminal "  [$($i+1)] $($Options[$i])" "#E8E8E8"
    }
}

function Apply-SelectionGate {
    param([int]$Choice, [string[]]$Options)
    if ($Choice -lt 1 -or $Choice -gt $Options.Count) {
        Write-Warn "Invalid choice."
        return $null
    }
    return $Options[$Choice - 1]
}


# ============================================================
# ROOM / ITEM HELPERS
# ============================================================
function Get-RoomItems {
    param([string]$RoomId)
    $room = $script:RoomDB[$RoomId]
    if (-not $room) { return @() }
    return $room.Items | Where-Object { $_ }
}

function Get-RoomEnemies {
    param([string]$RoomId)
    $room = $script:RoomDB[$RoomId]
    if (-not $room) { return @() }
    if ($room.BossRoom -and -not $room.BossDefeated) { return @($room.BossEnemy) }
    return $room.Enemies | Where-Object { $_ }
}

function Enter-Room {
    param([string]$RoomId)
    $g = $script:GS
    $room = $script:RoomDB[$RoomId]
    if (-not $room) { Write-Warn "Unknown room: $RoomId"; return }

    $g.CurrentRoom = $RoomId
    $g.StepsThisFloor++
    $g.RoomsVisited++
    $g.AchieveStat_rooms_explored++

    # Natural HP/MP regen on room enter (not in combat)
    if (-not $g.InCombat) {
        $hpRegen = [Math]::Floor($g.CON / 3)
        $mpRegen = [Math]::Floor($g.INT / 4)
        if ($hpRegen -gt 0) { $g.HP = [Math]::Min($g.MaxHP, $g.HP + $hpRegen) }
        if ($mpRegen -gt 0) { $g.MP = [Math]::Min($g.MaxMP, $g.MP + $mpRegen) }
    }

    $room.Visited = $true
    Add-Viewers -Min 2 -Max 15
    Check-SponsorDrop

    # Print room
    Write-Sep
    Write-Terminal $room.Name "#FFD60A" $true
    Write-Terminal $room.Desc "#C8C8C8" $true

    # Ambient message
    if ($room.Ambient -and $room.Ambient.Count -gt 0) {
        $amb = $room.Ambient[(Get-Random -Minimum 0 -Maximum $room.Ambient.Count)]
        Write-Terminal "> $amb" "#808080"
    }

    # Exits
    $exitList = ($room.Exits.Keys | ForEach-Object { "$_ -> $($script:RoomDB[$room.Exits[$_]].Name)" }) -join ", "
    Write-Info "Exits: $exitList"

    # Items in room
    if ($room.Items -and $room.Items.Count -gt 0) {
        $itemNames = $room.Items | ForEach-Object { $i = $script:ItemDB[$_]; if ($i -and $i.Name) { $i.Name } else { $_ } }
        Write-Loot "Items here: $($itemNames -join ', ')"
    }

    # Enemies
    $enemies = Get-RoomEnemies $RoomId
    if ($enemies.Count -gt 0) {
        $enemyNames = $enemies | ForEach-Object { $e = $script:EnemyDB[$_]; if ($e -and $e.Name) { $e.Name } else { $_ } }
        Write-Combat "Enemies: $($enemyNames -join ', ')"
        # Auto-start combat with first enemy
        $firstEnemy = $enemies[0]
        Start-Combat $firstEnemy
    } else {
        # Check for Mordecai in safe room
        if ($room.HasMordecai -and $room.IsSafeRoom) {
            $floor = $g.Floor
            $form = if ($script:MordecaiForms[$floor]) { $script:MordecaiForms[$floor] } else { $script:MordecaiForms[1] }
            Write-Mordecai "You find me in here, do you? Good. We should talk."
            Write-Info "(Type TALK MORDECAI or click TALK to speak with Mordecai)"
        }
    }

    Update-HUD
    Render-MiniMap
    Check-AllAchievements

    # Occasional sarcasm
    if (($g.Turn % 7) -eq 0) { Write-AISarcasm }
    $g.Turn++
}

# ============================================================
# COMBAT
# ============================================================
function Start-Combat {
    param([string]$EnemyId)
    $g = $script:GS
    $edef = $script:EnemyDB[$EnemyId]
    if (-not $edef) { return }

    $g.InCombat = $true
    $g.CurrentEnemy = $EnemyId
    # Scale enemy HP slightly by floor
    $baseHP = $edef.HP + ($g.Floor * 2)
    $g.EnemyHP = $baseHP; $g.EnemyMaxHP = $baseHP
    $g.CombatRound = 1
    $g.PlayerHiding = $false
    $g.DistractActive = $false

    Write-Sep
    Write-Combat "=== COMBAT STARTED ==="
    Write-Combat "$($edef.Name) appears! HP: $($g.EnemyHP)"
    if ($edef.CanTalk) { Write-Info "(This enemy can talk. Type TALK to attempt dialogue.)" }
    Write-Info "Actions: ATTACK | SPELL | FLEE | ITEM" + $(if ($edef.CanTalk) { " | TALK" } else { "" })
    Update-HUD
}

function Do-Attack {
    $g = $script:GS
    if (-not $g.InCombat) { Write-Warn "Not in combat."; return }
    $edef = $script:EnemyDB[$g.CurrentEnemy]
    $playerAtk = Get-TotalAttack
    $roll = Get-Random -Minimum 1 -Maximum 7
    $dmg = [Math]::Max(1, $playerAtk + $roll - (Get-TotalDefense) + (Get-Random -Minimum -2 -Maximum 3))
    $g.EnemyHP -= $dmg
    Write-Combat "You attack $($edef.Name) for $dmg damage! ($($g.EnemyHP)/$($g.EnemyMaxHP) HP left)"
    if ($g.EnemyHP -le 0) { Resolve-CombatVictory; return }
    Enemy-Attack
}

function Do-CastSpell {
    $g = $script:GS
    if (-not $g.InCombat) { Write-Warn "Not in combat."; return }
    if ($g.MP -lt 2) { Write-Warn "Not enough MP! (need 2)"; return }
    $edef = $script:EnemyDB[$g.CurrentEnemy]
    $g.MP -= 2
    $roll = Get-Random -Minimum 1 -Maximum 7
    $dmg = ($g.INT * 2) + $roll
    $g.EnemyHP -= $dmg
    Write-Combat "Spell! You blast $($edef.Name) for $dmg magic damage! MP: $($g.MP)/$($g.MaxMP)"
    if ($g.EnemyHP -le 0) { Resolve-CombatVictory; return }
    Enemy-Attack
    Update-HUD
}

function Enemy-Attack {
    $g = $script:GS
    $edef = $script:EnemyDB[$g.CurrentEnemy]
    if (-not $edef) { return }

    # Distract dodge chance
    if ($g.DistractActive) {
        if ((Get-Random -Minimum 1 -Maximum 101) -le 40) {
            Write-Info "The distraction works! $($edef.Name) misses you entirely."
            $g.DistractActive = $false
            $g.CombatRound++
            return
        }
        $g.DistractActive = $false
    }

    # Hide stealth: if hiding, enemy might not target you
    if ($g.PlayerHiding) {
        if ((Get-Random -Minimum 1 -Maximum 101) -le 60) {
            Write-Info "$($edef.Name) doesn't see you while you're hidden."
            $g.CombatRound++
            return
        } else {
            $g.PlayerHiding = $false
            Write-Warn "$($edef.Name) spots you! Stealth broken."
        }
    }

    $eDmg = [Math]::Max(0, $edef.ATK + (Get-Random -Minimum -2 -Maximum 3) - (Get-TotalDefense))
    $g.HP -= $eDmg
    Write-Combat "$($edef.Name) hits you for $eDmg damage! HP: $($g.HP)/$($g.MaxHP)"
    if ($g.HP -le 0) { Resolve-CombatDeath; return }
    $g.CombatRound++
    Update-HUD
}

function Do-Taunt {
    $g = $script:GS
    if (-not $g.InCombat) { Write-Warn "Taunting works best in combat."; return }
    $edef = $script:EnemyDB[$g.CurrentEnemy]
    Add-Viewers -Min 10 -Max 40
    Write-Info "The crowd loves it. +viewers."
    # Taunt increases enemy aggression - slight damage boost to them, but enemy focuses ONLY you
    Write-Combat "You taunt $($edef.Name)! They focus entirely on you. Dangerous."
    # Enemy immediately attacks in rage
    $eDmg = [Math]::Max(1, $edef.ATK + (Get-Random -Minimum 1 -Maximum 5) - (Get-TotalDefense))
    $g.HP -= $eDmg
    if ($g.HP -le 0) { Resolve-CombatDeath; return }
    Write-Combat "Enraged, $($edef.Name) hits you for $eDmg! HP: $($g.HP)/$($g.MaxHP)"
    Update-HUD
}

function Do-Distract {
    $g = $script:GS
    if (-not $g.InCombat) { Write-Warn "Nothing to distract."; return }
    if ($g.DistractActive) { Write-Info "Distraction already active."; return }
    $roll = (Get-Random -Minimum 1 -Maximum 21) + $g.DEX
    if ($roll -ge 12) {
        $g.DistractActive = $true
        Write-Info "You create a distraction. Next enemy attack has 40% chance to miss."
    } else {
        Write-Warn "Distraction attempt failed. $($script:EnemyDB[$g.CurrentEnemy].Name) isn't fooled."
    }
}

function Do-Flee {
    $g = $script:GS
    if (-not $g.InCombat) { Write-Warn "You're not in combat."; return }
    $roll = (Get-Random -Minimum 1 -Maximum 21) + $g.DEX
    if ($roll -ge 13) {
        $edef = $script:EnemyDB[$g.CurrentEnemy]
        Write-Info "You flee from $($edef.Name)!"
        $g.InCombat = $false; $g.CurrentEnemy = $null
        $g.PlayerHiding = $false; $g.DistractActive = $false
        # Move back to a connected room
        $room = $script:RoomDB[$g.CurrentRoom]
        if ($room.Exits.Count -gt 0) {
            $exitDir = ($room.Exits.Keys | Select-Object -First 1)
            $dest = $room.Exits[$exitDir]
            Enter-Room $dest
        }
    } else {
        Write-Warn "Can't escape! $($script:EnemyDB[$g.CurrentEnemy].Name) blocks the way."
        Enemy-Attack
    }
    Update-HUD
}

function Resolve-CombatVictory {
    $g = $script:GS
    $edef = $script:EnemyDB[$g.CurrentEnemy]
    $expGain = $edef.EXP + (Get-Random -Minimum 0 -Maximum 11)
    $goldGain = $edef.Gold + (Get-Random -Minimum 0 -Maximum 6)
    $g.EXP += $expGain; $g.Gold += $goldGain; $g.Kills++
    $g.AchieveStat_boss_kills += if ($edef.IsBoss) { 1 } else { 0 }
    Write-Loot "=== VICTORY! ==="
    Write-Loot "$($edef.Name) defeated! +$expGain EXP, +$goldGain gold"
    # Drop items
    if ($edef.Drops -and $edef.Drops.Count -gt 0) {
        foreach ($drop in $edef.Drops) {
            if ((Get-Random -Minimum 1 -Maximum 101) -le $(if ($null -ne $drop.Chance) { $drop.Chance } else { 50 })) {
                $g.Inventory += @($drop.Item)
                $item = $script:ItemDB[$drop.Item]
                Write-Loot "Dropped: $(if ($item -and $item.Name) { $item.Name } else { $drop.Item })"
            }
        }
    }
    # Boss map drop - auto-applied to mini-map
    if ($edef.IsBoss -and $edef.BossType) {
        $mapId = $script:MapDropItems[$edef.BossType]
        if ($mapId) {
            $g.Inventory += @($mapId)
            Apply-MapDrop $mapId   # auto-apply immediately
        }
    }
    # Remove enemy from room
    $room = $script:RoomDB[$g.CurrentRoom]
    if ($room.Enemies) { $room.Enemies = $room.Enemies | Where-Object { $_ -ne $g.CurrentEnemy } }
    if ($room.BossRoom) { $room.BossDefeated = $true }
    $g.InCombat = $false; $g.CurrentEnemy = $null; $g.EnemyHP = 0
    $g.PlayerHiding = $false; $g.DistractActive = $false
    Check-LevelUp
    Check-AllAchievements
    Update-HUD
    Render-MiniMap
}

function Resolve-CombatDeath {
    $g = $script:GS
    Write-Sep
    Write-Combat "=== YOU DIED ==="
    Write-Terminal "The dungeon has claimed another one. Better luck next time, $($g.PlayerName)." "#FF453A"
    Write-System "Saving memorial data... your name will be added to the archive."
    $script:Window.Dispatcher.Invoke([Action]{
        $btnNew = $script:Window.FindName("btnNewGame")
        if ($btnNew) { $btnNew.Visibility = "Visible" }
    })
    $g.InCombat = $false
}

function Check-LevelUp {
    $g = $script:GS
    if ($g.EXP -lt $g.EXPNext) { return }
    $g.Level++
    $g.EXP -= $g.EXPNext
    $g.EXPNext = [int]($g.EXPNext * 1.5)
    # Stat gain on level up
    $g.MaxHP += 10; $g.HP += 10
    $statToGain = @("STR","DEX","INT","CON","CHA","LCK") | Get-Random
    $g[$statToGain]++
    Recalculate-DerivedStats
    Write-Info "=== LEVEL UP! You are now level $($g.Level)! ==="
    Write-Info "+10 Max HP | +1 $statToGain"
    $g.LootBoxes++
    Write-Loot "You receive a Loot Box for leveling up!"
    Update-HUD
}

function Trigger-Victory {
    Write-Sep
    Write-Terminal "=== YOU WIN ===" "#FFD60A" $true
    Write-Terminal "The dungeon core is destroyed. The System goes dark. You made it." "#E8E8E8"
    Write-System "Final report: $($script:GS.Level) levels | $($script:GS.Kills) kills | $($script:GS.RoomsVisited) rooms | $($script:GS.ViewerPeak) peak viewers"
}


# ============================================================
# DIALOGUE SYSTEM (Fallout-style)
# ============================================================
function Start-Dialogue {
    param([string]$DialogueId, [string]$SpeakerName=$null)
    $g = $script:GS
    $dlg = $script:DialogueDB[$DialogueId]
    if (-not $dlg) { Write-Warn "No dialogue found for: $DialogueId"; return }

    $g.InDialogue = $true
    $g.DialogueId = $DialogueId

    $speaker = if ($SpeakerName) { $SpeakerName } else { "NPC" }
    Write-Sep
    Write-Terminal "[$speaker]: $($dlg.Greeting)" "#64D2FF"
    Write-Sep

    $opts = $dlg.Options
    for ($i = 0; $i -lt $opts.Count; $i++) {
        Write-Terminal "  [$($i+1)] $($opts[$i].Text)" "#E8E8E8"
    }
    Write-Info "(Type REPLY 1-$($opts.Count) to respond)"

    # Show dialogue bar in UI
    $script:Window.Dispatcher.Invoke([Action]{
        $bar = $script:Window.FindName("dialogueBar")
        $prompt = $script:Window.FindName("lblDialoguePrompt")
        if ($bar) { $bar.Visibility = "Visible" }
        if ($prompt) { $prompt.Text = "[$speaker]: $($dlg.Greeting)" }
        for ($i = 1; $i -le 4; $i++) {
            $btn = $script:Window.FindName("btnReply$i")
            if ($btn) {
                if ($i -le $opts.Count) {
                    $btn.Content = "[$i] $($opts[$i-1].Text.Substring(0, [Math]::Min(30, $opts[$i-1].Text.Length)))..."
                    $btn.Visibility = "Visible"
                } else {
                    $btn.Visibility = "Collapsed"
                }
            }
        }
    })
}

function Do-Reply {
    param([int]$Choice)
    $g = $script:GS
    if (-not $g.InDialogue) { Write-Warn "Not in a conversation."; return }
    $dlg = $script:DialogueDB[$g.DialogueId]
    if (-not $dlg) { End-Dialogue; return }
    $opts = $dlg.Options
    if ($Choice -lt 1 -or $Choice -gt $opts.Count) {
        Write-Warn "Choose 1-$($opts.Count)."
        return
    }
    $opt = $opts[$Choice - 1]
    # Check stat requirements
    if ($opt.StatRequired -and $opt.StatMin) {
        if ($g[$opt.StatRequired] -lt $opt.StatMin) {
            Write-Warn "You don't meet the requirement ($($opt.StatRequired) $($opt.StatMin)). The words die in your throat."
            return
        }
    }
    # Check gold cost
    if ($opt.GoldCost -and $opt.GoldCost -gt 0) {
        if ($g.Gold -lt $opt.GoldCost) {
            Write-Warn "You need $($opt.GoldCost) gold for this. You have $($g.Gold)."
            return
        }
        $g.Gold -= $opt.GoldCost
        $g.AchieveStat_gold_spent += $opt.GoldCost
        Write-Info "Paid $($opt.GoldCost) gold."
    }

    Write-Terminal "> You: $($opt.Text)" "#A0D0A0"
    Write-Terminal "  $($opt.Response)" "#64D2FF"

    switch ($opt.Outcome) {
        "flee"    { Write-Info "They back off and leave."; End-Dialogue; $g.AchieveStat_talk_escapes++ }
        "neutral" { Write-Info "The conversation ends."; End-Dialogue }
        "help"    { Write-Loot "You helped. Something was added to your inventory."; End-Dialogue }
        "bribe"   { Write-Info "Deal made."; End-Dialogue }
        "combat"  {
            End-Dialogue
            if ($g.InCombat) { Write-Combat "Things escalate. Fight!" }
            elseif ($g.CurrentRoom) {
                $room = $script:RoomDB[$g.CurrentRoom]
                if ($room.Enemies -and $room.Enemies.Count -gt 0) {
                    Start-Combat $room.Enemies[0]
                }
            }
        }
        default   { End-Dialogue }
    }

    if ($opt.Outcome -eq "flee" -or $opt.Outcome -eq "neutral") { $g.AchieveStat_talk_escapes++ }
    Check-AllAchievements
    Update-HUD
}

function End-Dialogue {
    $g = $script:GS
    $g.InDialogue = $false
    $g.DialogueId = $null
    $script:Window.Dispatcher.Invoke([Action]{
        $bar = $script:Window.FindName("dialogueBar")
        if ($bar) { $bar.Visibility = "Collapsed" }
        for ($i = 1; $i -le 4; $i++) {
            $btn = $script:Window.FindName("btnReply$i")
            if ($btn) { $btn.Visibility = "Collapsed" }
        }
    })
}

function Do-Talk {
    param([string]$Target)
    $g = $script:GS
    $room = $script:RoomDB[$g.CurrentRoom]

    # In combat: try dialogue with current enemy
    if ($g.InCombat) {
        $edef = $script:EnemyDB[$g.CurrentEnemy]
        if ($edef -and $edef.CanTalk -and $edef.DialogueId) {
            Start-Dialogue $edef.DialogueId $edef.Name
            return
        } else {
            Write-Warn "$($edef.Name) isn't interested in talking."
            return
        }
    }

    # Check if talking to Mordecai
    if ($Target -match "mordecai" -and $room.HasMordecai) {
        Do-TalkToMordecai
        return
    }

    # Check room interactables with dialogue outcome
    if ($Target -and $room.Interactables) {
        $key = ($room.Interactables.Keys | Where-Object { $_ -match $Target }) | Select-Object -First 1
        if ($key) {
            $inter = $room.Interactables[$key]
            if ($inter.Outcome -eq "dialogue" -and $inter.DialogueId) {
                Start-Dialogue $inter.DialogueId $inter.Name
                return
            }
        }
    }

    Write-Warn "There's nobody specific to talk to here. (Try TALK MORDECAI in a safe room, or TALK in combat.)"
}

function Do-TalkToMordecai {
    $g = $script:GS
    $room = $script:RoomDB[$g.CurrentRoom]
    if (-not $room.IsSafeRoom -or -not $room.HasMordecai) {
        Write-Warn "Mordecai isn't here."
        return
    }
    $floor = $g.Floor
    $dlg = $script:MordecaiDialogue[$floor]
    if (-not $dlg) {
        Write-Mordecai "I don't have much to say right now. Keep moving."
        return
    }
    $g.AchieveStat_mordecai_talks++
    $form = if ($script:MordecaiForms[$floor]) { $script:MordecaiForms[$floor] } else { $script:MordecaiForms[1] }
    Write-Sep
    Write-Terminal "[Mordecai - $($form.Form)]: $($dlg.Greeting)" $form.Color
    Write-Sep
    $opts = $dlg.Options
    for ($i = 0; $i -lt $opts.Count; $i++) {
        Write-Terminal "  [$($i+1)] $($opts[$i].Text)" "#E8E8E8"
    }
    Write-Info "(Type REPLY 1-$($opts.Count) or click a reply button)"
    # Use the generic dialogue system for replies
    $script:GS.InDialogue = $true
    $script:GS.DialogueId = "mordecai_floor_$floor"
    # Register temp dialogue entry
    $script:DialogueDB["mordecai_floor_$floor"] = @{ Greeting = $dlg.Greeting; Options = $dlg.Options }
    Check-AllAchievements
}

# ============================================================
# INTERACT / EXAMINE
# ============================================================
function Do-Interact {
    param([string]$Target)
    $g = $script:GS
    $room = $script:RoomDB[$g.CurrentRoom]
    if (-not $room.Interactables) { Write-Info "Nothing special to interact with here."; return }

    $key = $null
    if ($Target) {
        $key = ($room.Interactables.Keys | Where-Object { $_ -match $Target }) | Select-Object -First 1
    }
    if (-not $key) { $key = ($room.Interactables.Keys | Select-Object -First 1) }
    if (-not $key) { Write-Info "Nothing to interact with."; return }

    $inter = $room.Interactables[$key]
    $g.AchieveStat_interact_count++
    Write-Info "[$($inter.Name)]"
    Write-Terminal $inter.Desc "#C8C8C8"

    switch ($inter.Outcome) {
        "loot" {
            if ($inter.Item -and $script:ItemDB[$inter.Item]) {
                $g.Inventory += @($inter.Item)
                $item = $script:ItemDB[$inter.Item]
                Write-Loot "You take the $($item.Name)."
                $room.Interactables.Remove($key)
            }
        }
        "dialogue" {
            if ($inter.DialogueId) { Start-Dialogue $inter.DialogueId $inter.Name }
        }
        "bribe_option" {
            Write-Info "Cost: $($inter.GoldCost)g - $($inter.Text)"
            Write-Info "(Type REPLY 1 to pay, REPLY 2 to decline)"
            $script:GS.InDialogue = $true
            $script:GS.DialogueId = "__bribe_$key"
            $script:DialogueDB["__bribe_$key"] = @{
                Greeting = $inter.Text
                Options = @(
                    @{ Text="Pay $($inter.GoldCost)g."; Outcome="bribe"; GoldCost=$inter.GoldCost; Response="Done." }
                    @{ Text="Never mind."; Outcome="neutral"; GoldCost=0; Response="You step away." }
                )
            }
        }
        default {
            Write-Info "(Nothing more happens.)"
        }
    }
    Check-AllAchievements
    Update-HUD
}

function Do-Examine { param([string]$Target); Do-Interact $Target }

# ============================================================
# HIDE / SCOUT
# ============================================================
function Do-Hide {
    $g = $script:GS
    if ($g.PlayerHiding) { Write-Info "You are already hidden."; return }
    $roll = (Get-Random -Minimum 1 -Maximum 21) + $g.DEX
    if ($roll -ge 12) {
        $g.PlayerHiding = $true
        Write-Info "You slip into the shadows. Enemies are less likely to hit you."
    } else {
        Write-Warn "Nowhere good to hide here. You settle for standing very still."
    }
}

function Do-Scout {
    $g = $script:GS
    $room = $script:RoomDB[$g.CurrentRoom]
    $roll = (Get-Random -Minimum 1 -Maximum 21) + $g.INT
    if ($roll -lt 10) { Write-Warn "You can't make out anything useful from here."; return }
    Write-Info "=== SCOUT REPORT ==="
    foreach ($dir in $room.Exits.Keys) {
        $destId = $room.Exits[$dir]
        $dest = $script:RoomDB[$destId]
        if (-not $dest) { continue }
        $enemies = Get-RoomEnemies $destId
        $items = Get-RoomItems $destId
        $hostileStr  = if ($enemies.Count -gt 0) { "Hostiles: $($enemies.Count)" } else { "Clear" }
        $itemStr     = if ($items.Count -gt 0) { "Items: $($items.Count)" } else { "Empty" }
        Write-Terminal "  $($dir.ToUpper()): $($dest.Name) - $hostileStr | $itemStr" "#A0D0A0"
    }
}

# ============================================================
# ITEM USE
# ============================================================
function Invoke-UseItem {
    param([string]$ItemId)
    $g = $script:GS
    $item = $script:ItemDB[$ItemId]
    if (-not $item) { Write-Warn "Unknown item."; return }

    switch ($item.Type) {
        "consumable" {
            if ($item.HealHP) { $g.HP = [Math]::Min($g.MaxHP, $g.HP + $item.HealHP); Write-Loot "Healed $($item.HealHP) HP. ($($g.HP)/$($g.MaxHP))" }
            if ($item.HealMP) { $g.MP = [Math]::Min($g.MaxMP, $g.MP + $item.HealMP); Write-Loot "Restored $($item.HealMP) MP. ($($g.MP)/$($g.MaxMP))" }
            if ($item.BuffSTR) { $g.STR += $item.BuffSTR; Write-Loot "+$($item.BuffSTR) STR (temporary)" }
            if ($item.CureStatus) { $g.StatusEffects.Remove($item.CureStatus); Write-Loot "Status cleared." }
            $g.Inventory = $g.Inventory | Where-Object { $_ -ne $ItemId } | Select-Object -First ($g.Inventory.Count - 1)
        }
        "weapon" {
            $old = $g.EquippedWeapon
            $g.EquippedWeapon = $ItemId
            if ($old) { $g.Inventory += @($old) }
            $g.Inventory = $g.Inventory | Where-Object { $_ -ne $ItemId }
            Write-Info "Equipped $($item.Name)."
        }
        "armor" {
            $old = $g.EquippedArmor
            $g.EquippedArmor = $ItemId
            if ($old) { $g.Inventory += @($old) }
            $g.Inventory = $g.Inventory | Where-Object { $_ -ne $ItemId }
            Write-Info "Equipped $($item.Name)."
        }
        "accessory" {
            $old = $g.EquippedAccessory
            $g.EquippedAccessory = $ItemId
            if ($old) { $g.Inventory += @($old) }
            $g.Inventory = $g.Inventory | Where-Object { $_ -ne $ItemId }
            Write-Info "Equipped $($item.Name)."
        }
        default { Write-Warn "Can't use $($item.Name) right now." }
    }
    Update-HUD
}

function Do-UseItemSelected {
    $lst = $script:Window.FindName("lstInventory")
    if (-not $lst -or $lst.SelectedIndex -lt 0) { Write-Warn "Select an item first."; return }
    $idx = $lst.SelectedIndex
    if ($idx -ge $script:GS.Inventory.Count) { return }
    $itemId = $script:GS.Inventory[$idx]
    Invoke-UseItem $itemId
}


# ============================================================
# ROOM COMMANDS
# ============================================================
function Do-Look {
    $g = $script:GS
    $room = $script:RoomDB[$g.CurrentRoom]
    if (-not $room) { return }
    Write-Sep
    Write-Terminal $room.Name "#FFD60A" $true
    Write-Terminal $room.Desc "#C8C8C8" $true
    # Exits
    $exitList = ($room.Exits.Keys | ForEach-Object { "$_ -> $($script:RoomDB[$room.Exits[$_]].Name)" }) -join ", "
    Write-Info "Exits: $exitList"
    # Items
    if ($room.Items -and $room.Items.Count -gt 0) {
        $itemNames = $room.Items | ForEach-Object { $i = $script:ItemDB[$_]; if ($i -and $i.Name) { $i.Name } else { $_ } }
        Write-Loot "On the ground: $($itemNames -join ', ')"
    } else { Write-Info "No items visible." }
    # Enemies
    $enemies = Get-RoomEnemies $g.CurrentRoom
    if ($enemies.Count -gt 0) {
        Write-Combat "Threats: $(($enemies | ForEach-Object { $script:EnemyDB[$_].Name }) -join ', ')"
    } else { Write-Info "No threats visible." }
    # Interactables
    if ($room.Interactables -and $room.Interactables.Count -gt 0) {
        Write-Info "Notable: $(($room.Interactables.Keys) -join ', ')"
    }
    # Mordecai
    if ($room.HasMordecai -and $room.IsSafeRoom) { Write-Info "Mordecai is here. (TALK MORDECAI)" }
    Write-Sep
}

function Do-Inventory {
    $g = $script:GS
    Write-Sep; Write-Info "=== INVENTORY === Gold: $($g.Gold)g | Loot Boxes: $($g.LootBoxes)"
    if ($g.Inventory.Count -eq 0) { Write-Terminal "  (empty)" "#808080" }
    else {
        foreach ($id in $g.Inventory) {
            $item = $script:ItemDB[$id]
            $name = if ($item) { $item.Name } else { $id }
            $desc = if ($item -and $item.Desc) { " - $($item.Desc)" } else { "" }
            Write-Terminal "  * $name$desc" "#E8E8E8"
        }
    }
    $wpn = if ($g.EquippedWeapon) { $g.EquippedWeapon } else { "--" }
    $arm = if ($g.EquippedArmor) { $g.EquippedArmor } else { "--" }
    $acc = if ($g.EquippedAccessory) { $g.EquippedAccessory } else { "--" }
    Write-Info "Equipped: Weapon=$wpn | Armor=$arm | Accessory=$acc"
    Write-Sep
}

function Do-Stats {
    $g = $script:GS
    Write-Sep; Write-Info "=== STATS: $($g.PlayerName) - Level $($g.Level) ==="
    Write-Terminal "  HP: $($g.HP)/$($g.MaxHP)  |  MP: $($g.MP)/$($g.MaxMP)" "#E8E8E8"
    Write-Terminal "  STR:$($g.STR)  DEX:$($g.DEX)  INT:$($g.INT)  CON:$($g.CON)  CHA:$($g.CHA)  LCK:$($g.LCK)" "#E8E8E8"
    Write-Terminal "  ATK:$(Get-TotalAttack)  DEF:$(Get-TotalDefense)  SPD:$(Get-TotalSpeed)" "#A0D0A0"
    Write-Terminal "  EXP: $($g.EXP)/$($g.EXPNext)  |  Gold: $($g.Gold)g" "#E8E8E8"
    Write-Terminal "  Viewers: $($g.Viewers)  |  Floor: $($g.Floor)  |  Kills: $($g.Kills)" "#E8E8E8"
    Write-Sep
}

function Do-Rest {
    $g = $script:GS
    $room = $script:RoomDB[$g.CurrentRoom]
    if (-not $room.IsSafeRoom) {
        Write-Warn "You can only rest in safe rooms. Out here, sleeping means dying."
        return
    }
    if ($g.InCombat) { Write-Warn "You can't rest during combat."; return }
    $hpGain = [Math]::Min($g.MaxHP - $g.HP, [Math]::Floor($g.MaxHP * 0.4))
    $mpGain = [Math]::Min($g.MaxMP - $g.MP, [Math]::Floor($g.MaxMP * 0.5))
    $g.HP += $hpGain; $g.MP += $mpGain
    Write-Info "You rest. +$hpGain HP, +$mpGain MP. ($($g.HP)/$($g.MaxHP) HP | $($g.MP)/$($g.MaxMP) MP)"
    Add-Viewers -Min 1 -Max 5
    Update-HUD
}

function Do-TakeAll {
    $g = $script:GS
    $room = $script:RoomDB[$g.CurrentRoom]
    if (-not $room.Items -or $room.Items.Count -eq 0) { Write-Info "Nothing on the ground."; return }
    foreach ($id in $room.Items) {
        $item = $script:ItemDB[$id]
        $g.Inventory += @($id)
        Write-Loot "Picked up: $(if ($item -and $item.Name) { $item.Name } else { $id })"
    }
    $room.Items = @()
    Update-HUD
}

function Do-Search {
    $g = $script:GS
    $room = $script:RoomDB[$g.CurrentRoom]
    $roll = (Get-Random -Minimum 1 -Maximum 21) + $g.LCK
    if ($roll -ge 14) {
        $gold = Get-Random -Minimum 3 -Maximum 16
        $g.Gold += $gold
        Write-Loot "You find $gold gold hidden in the debris."
        if ((Get-Random -Minimum 1 -Maximum 101) -le 20) {
            $g.LootBoxes++
            Write-Loot "And a loot box tucked behind something."
        }
    } else {
        $msgs = @(
            "Nothing. Just dust and regret.",
            "You find a used protein bar wrapper. Not useful.",
            "The floor reveals its secrets: it's also a floor.",
            "Whatever was here, it's long gone."
        )
        Write-Info $msgs[(Get-Random -Minimum 0 -Maximum $msgs.Count)]
    }
    Update-HUD
}

function Do-Map {
    $g = $script:GS
    Write-Sep; Write-Info "=== MAP - Floor $($g.Floor) ==="
    $floorRooms = $script:RoomDB.Keys | Where-Object { $script:RoomDB[$_].Floor -eq $g.Floor } | Sort-Object
    foreach ($rId in $floorRooms) {
        $r = $script:RoomDB[$rId]
        $visited = if ($r.Visited) { "[X]" } else { "[ ]" }
        $current = if ($rId -eq $g.CurrentRoom) { " <-- YOU" } else { "" }
        Write-Terminal "  $visited $($r.Name)$current" "#A0A0A0"
    }
    Write-Sep
}

function Do-Quests {
    $g = $script:GS
    Write-Sep; Write-Info "=== QUEST LOG ==="
    if ($g.QuestLog.Count -eq 0) { Write-Terminal "  No active quests." "#808080" }
    else {
        foreach ($q in $g.QuestLog) {
            Write-Terminal "  [ACTIVE] $($q.Name): $($q.Desc)" "#FFD60A"
        }
    }
    if ($g.CompletedQuests.Count -gt 0) {
        Write-Info "Completed:"
        foreach ($q in $g.CompletedQuests) { Write-Terminal "  [DONE] $q" "#808080" }
    }
    Write-Sep
}

function Do-Craft {
    Write-Info "Crafting not yet implemented. Combine items from your inventory when you have more components."
    $script:GS.AchieveStat_items_crafted++
}

function Do-Move {
    param([string]$Direction)
    $g = $script:GS
    if ($g.InCombat) { Write-Warn "Can't move - you're in combat! FLEE first."; return }
    if ($g.InDialogue) { Write-Warn "Finish the conversation first."; return }
    $room = $script:RoomDB[$g.CurrentRoom]
    if (-not $room.Exits[$Direction]) {
        Write-Warn "Can't go $Direction from here."
        return
    }
    $destId = $room.Exits[$Direction]
    $dest = $script:RoomDB[$destId]
    if (-not $dest) { Write-Warn "That direction leads nowhere."; return }
    # Floor transition
    if ($dest.Floor -gt $g.Floor) {
        $g.Floor = $dest.Floor
        $g.StepsThisFloor = 0
        $g.AchieveStat_floors_cleared++
        Write-System "Descending to Floor $($g.Floor)..."
        Check-AllAchievements
    }
    Enter-Room $destId
}

# ============================================================
# SAVE / LOAD
# ============================================================
function Get-SavePath { return Join-Path $PSScriptRoot "saves\savegame.json" }

function Save-Game {
    $savePath = Get-SavePath
    $saveDir = Split-Path $savePath
    if (-not (Test-Path $saveDir)) { New-Item -ItemType Directory -Path $saveDir | Out-Null }
    $script:GS | ConvertTo-Json -Depth 10 | Set-Content $savePath -Encoding UTF8
    Write-Info "Game saved."
}

function Load-Game {
    $savePath = Get-SavePath
    if (-not (Test-Path $savePath)) { Write-Warn "No save file found."; return $false }
    try {
        $data = Get-Content $savePath -Raw -Encoding UTF8 | ConvertFrom-Json
        $script:GS = [ordered]@{}
        $data.PSObject.Properties | ForEach-Object { $script:GS[$_.Name] = $_.Value }
        # Re-hydrate arrays that JSON flattens
        if ($script:GS.Inventory -isnot [array]) { $script:GS.Inventory = @($script:GS.Inventory) }
        if ($script:GS.PendingAchievements -isnot [array]) { $script:GS.PendingAchievements = @() }
        Enter-Room $script:GS.CurrentRoom
        Write-Info "Game loaded."
        return $true
    } catch {
        Write-Warn "Save file corrupt: $_"
        return $false
    }
}

# ============================================================
# EXTERNAL DATA LOADER (JSON)
# ============================================================
function Load-ExternalData {
    $jsonPath = Join-Path $PSScriptRoot "data\dialogues.json"
    if (-not (Test-Path $jsonPath)) { return }   # silently use inline defaults
    try {
        $raw = Get-Content $jsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
        # Override SystemSarcasmPool if provided
        if ($raw.SystemSarcasmPool) {
            $script:SystemSarcasmPool = @($raw.SystemSarcasmPool)
        }
        # Override/extend DialogueDB
        if ($raw.DialogueDB) {
            $raw.DialogueDB.PSObject.Properties | ForEach-Object {
                $id = $_.Name
                $entry = $_.Value
                $opts = @($entry.Options | ForEach-Object {
                    @{
                        Text          = $_.Text
                        Outcome       = $_.Outcome
                        GoldCost      = [int](if ($null -ne $_.GoldCost) { $_.GoldCost } else { 0 })
                        StatRequired  = $_.StatRequired
                        StatMin       = if ($_.StatMin) { [int]$_.StatMin } else { $null }
                        Response      = $_.Response
                        StartsConflict= [bool](if ($null -ne $_.StartsConflict) { $_.StartsConflict } else { $false })
                    }
                })
                $script:DialogueDB[$id] = @{ Greeting = $entry.Greeting; Options = $opts }
            }
        }
        # Override/extend MordecaiDialogue
        if ($raw.MordecaiDialogue) {
            $raw.MordecaiDialogue.PSObject.Properties | ForEach-Object {
                $floor = [int]$_.Name
                $entry = $_.Value
                $opts = @($entry.Options | ForEach-Object {
                    @{ Text = $_.Text; Response = $_.Response }
                })
                $script:MordecaiDialogue[$floor] = @{ Greeting = $entry.Greeting; Options = $opts }
            }
        }
        # Override OpeningSequences
        if ($raw.OpeningSequences) {
            $script:OpeningSequences = @($raw.OpeningSequences | ForEach-Object {
                @{ Title = $_.Title; Location = $_.Location; Text = $_.Text }
            })
        }
    } catch {
        # JSON parse error - fall back to inline data silently
    }
}


# ============================================================
# MINI-MAP SYSTEM
# ============================================================
# Room type color mapping for mini-map
$script:MapRoomColors = @{
    "safe"       = "#30D158"   # green - safe room
    "tutorial"   = "#30D158"   # green - guild/tutorial
    "boss"       = "#FF453A"   # red   - boss room
    "special"    = "#BF5AF2"   # purple - Desperado Club, Club Vanquisher, etc.
    "stairwell"  = "#FFD60A"   # yellow - floor exit
    "loot"       = "#FFCC00"   # gold  - loot-heavy room
    "default"    = "#3A3A3A"   # dark  - regular visited
    "revealed"   = "#252525"   # very dark - revealed but not visited
    "unknown"    = "#111111"   # nearly black - unknown
    "current"    = "#64D2FF"   # cyan  - current location
}

# Auto-generate X/Y grid positions for all rooms using BFS from floor start rooms
$script:RoomPositions = @{}

function Compute-RoomPositions {
    param([int]$Floor)
    $dirVectors = @{ north=@(0,-1); south=@(0,1); east=@(1,0); west=@(-1,0); up=@(0,-1); down=@(0,1) }
    # Find a start room for this floor
    $startRoom = $script:RoomDB.Keys | Where-Object { $script:RoomDB[$_].Floor -eq $Floor } | Select-Object -First 1
    if (-not $startRoom) { return }
    $queue = [System.Collections.Queue]::new()
    $queue.Enqueue(@{ Id=$startRoom; X=5; Y=5 })
    $visited = @{}
    $visited[$startRoom] = @(5,5)
    $script:RoomPositions[$startRoom] = @(5,5)
    while ($queue.Count -gt 0) {
        $cur = $queue.Dequeue()
        $room = $script:RoomDB[$cur.Id]
        if (-not $room) { continue }
        foreach ($dir in $room.Exits.Keys) {
            $neighbor = $room.Exits[$dir]
            if ($visited[$neighbor]) { continue }
            $vec = $dirVectors[$dir]
            if (-not $vec) { $vec = @(0,0) }
            $nx = $cur.X + $vec[0]
            $ny = $cur.Y + $vec[1]
            $visited[$neighbor] = @($nx,$ny)
            $script:RoomPositions[$neighbor] = @($nx,$ny)
            if ($script:RoomDB[$neighbor] -and $script:RoomDB[$neighbor].Floor -eq $Floor) {
                $queue.Enqueue(@{ Id=$neighbor; X=$nx; Y=$ny })
            }
        }
    }
}

function Compute-AllFloorPositions {
    for ($f = 1; $f -le 10; $f++) { Compute-RoomPositions $f }
}

function Get-RoomMapType {
    param([string]$RoomId)
    $room = $script:RoomDB[$RoomId]
    if (-not $room) { return "default" }
    if ($room.IsFinalRoom -or $room.BossRoom) { return "boss" }
    if ($room.IsSafeRoom -and $room.IsTutorial) { return "tutorial" }
    if ($room.IsSafeRoom) { return "safe" }
    if ($RoomId -match "stair|exit|descent") { return "stairwell" }
    if ($RoomId -match "desperado|vanquisher|club") { return "special" }
    if ($room.Chest -or ($room.Items -and $room.Items.Count -ge 3)) { return "loot" }
    return "default"
}

# Reveal tracking: which rooms the player has map-revealed (vs visited)
# Stored in GS.RevealedRooms as array of room IDs
function Reveal-MapArea {
    param([string]$RoomId, [string]$MapType)
    $g = $script:GS
    if (-not $g.RevealedRooms) { $g.RevealedRooms = @() }

    $room = $script:RoomDB[$RoomId]
    if (-not $room) { return }
    $floor = $room.Floor
    $pos = $script:RoomPositions[$RoomId]
    if (-not $pos) { return }

    $cx = $pos[0]; $cy = $pos[1]

    # Determine reveal radius based on map type
    $radius = switch ($MapType) {
        "neighborhood" { 2 }    # ~5x5 area
        "borough"      { 5 }    # 4 neighborhoods
        "city"         { 10 }   # 4 boroughs
        "province"     { 20 }   # 4 cities
        "country"      { 999 }  # whole floor
        default        { 2 }
    }

    foreach ($rid in $script:RoomDB.Keys) {
        $r = $script:RoomDB[$rid]
        if (-not $r -or $r.Floor -ne $floor) { continue }
        $rpos = $script:RoomPositions[$rid]
        if (-not $rpos) { continue }
        $dx = [Math]::Abs($rpos[0] - $cx)
        $dy = [Math]::Abs($rpos[1] - $cy)
        if ($dx -le $radius -and $dy -le $radius) {
            if ($g.RevealedRooms -notcontains $rid) {
                $script:GS.RevealedRooms += @($rid)
            }
        }
    }
    Render-MiniMap
}

function Render-MiniMap {
    $g = $script:GS
    $canvas = $script:Window.FindName("MiniMapCanvas")
    if (-not $canvas) { return }
    $lblFloor = $script:Window.FindName("lblMapFloor")

    $script:Window.Dispatcher.Invoke([Action]{
        $canvas.Children.Clear()
        if ($lblFloor) { $lblFloor.Text = "F$($g.Floor)" }

        $cellSize = 18; $gap = 2; $totalCell = $cellSize + $gap

        # Find min X/Y among visible rooms to normalize display
        $floorRooms = $script:RoomDB.Keys | Where-Object {
            $r = $script:RoomDB[$_]
            $r -and $r.Floor -eq $g.Floor
        }
        if (-not $floorRooms) { return }

        $positions = @()
        foreach ($rid in $floorRooms) {
            $p = $script:RoomPositions[$rid]
            if ($p) { $positions += @([PSCustomObject]@{ Id=$rid; X=$p[0]; Y=$p[1] }) }
        }
        if ($positions.Count -eq 0) { return }
        $minX = ($positions | Measure-Object X -Minimum).Minimum
        $minY = ($positions | Measure-Object Y -Minimum).Minimum

        foreach ($entry in $positions) {
            $rid = $entry.Id
            $drawX = ($entry.X - $minX) * $totalCell + 4
            $drawY = ($entry.Y - $minY) * $totalCell + 4

            # Determine color based on visibility and type
            $revealed = ($g.RevealedRooms -and $g.RevealedRooms -contains $rid)
            $visited  = $script:RoomDB[$rid].Visited
            $isCurrent = ($rid -eq $g.CurrentRoom)

            if ($isCurrent) {
                $fillColor = $script:MapRoomColors["current"]
            } elseif ($visited) {
                $mapType = Get-RoomMapType $rid
                $fillColor = $script:MapRoomColors[$mapType]
            } elseif ($revealed) {
                $mapType = Get-RoomMapType $rid
                # Revealed but unvisited: use muted type color
                $fillColor = $script:MapRoomColors["revealed"]
            } else {
                continue  # don't draw unknown rooms
            }

            $rect = New-Object System.Windows.Shapes.Rectangle
            $rect.Width = $cellSize; $rect.Height = $cellSize
            [System.Windows.Controls.Canvas]::SetLeft($rect, $drawX)
            [System.Windows.Controls.Canvas]::SetTop($rect, $drawY)
            try { $rect.Fill = [System.Windows.Media.BrushConverter]::new().ConvertFromString($fillColor) } catch {}

            if ($isCurrent) {
                $rect.StrokeThickness = 2
                try { $rect.Stroke = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FFFFFF") } catch {}
            } elseif ($visited -and -not $isCurrent) {
                $rect.StrokeThickness = 0.5
                try { $rect.Stroke = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#555555") } catch {}
            } elseif ($revealed) {
                $rect.StrokeThickness = 1
                $rect.StrokeDashArray = [System.Windows.Media.DoubleCollection]::new()
                $rect.StrokeDashArray.Add(2); $rect.StrokeDashArray.Add(2)
                try { $rect.Stroke = [System.Windows.Media.BrushConverter]::new().ConvertFromString($fillColor) } catch {}
                try { $rect.Fill   = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1A1A1A")  } catch {}
            }

            # Tooltip
            $room = $script:RoomDB[$rid]
            if ($visited -or $revealed) {
                $tt = New-Object System.Windows.Controls.ToolTip
                $tt.Content = if ($visited) { $room.Name } else { "??? (revealed)" }
                $tt.Background = [System.Windows.Media.Brushes]::Black
                $tt.Foreground = [System.Windows.Media.Brushes]::White
                $rect.ToolTip = $tt
            }

            [void]$canvas.Children.Add($rect)

            # Draw connections (thin lines to each exit neighbor that is also on this floor)
            if ($visited -or $revealed) {
                    foreach ($dir in $room.Exits.Keys) {
                    $nid = $room.Exits[$dir]
                    $npos = $script:RoomPositions[$nid]
                    if (-not $npos) { continue }
                    $nvisit = $script:RoomDB[$nid].Visited
                    $nreveal = ($g.RevealedRooms -and $g.RevealedRooms -contains $nid)
                    if (-not $nvisit -and -not $nreveal) { continue }
                    $nx2 = ($npos[0] - $minX) * $totalCell + 4
                    $ny2 = ($npos[1] - $minY) * $totalCell + 4
                    $line = New-Object System.Windows.Shapes.Line
                    $line.X1 = $drawX + $cellSize/2; $line.Y1 = $drawY + $cellSize/2
                    $line.X2 = $nx2 + $cellSize/2;  $line.Y2 = $ny2 + $cellSize/2
                    $line.StrokeThickness = 1
                    try { $line.Stroke = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#444444") } catch {}
                    [void]$canvas.Children.Add($line)
                }
            }
        }

        # Legend strip at bottom
        $legendItems = @(
            @{ Color="#64D2FF"; Label="You" }
            @{ Color="#30D158"; Label="Safe" }
            @{ Color="#FF453A"; Label="Boss" }
            @{ Color="#BF5AF2"; Label="Special" }
            @{ Color="#FFD60A"; Label="Exit" }
        )
        $lx = 4
        foreach ($li in $legendItems) {
            $dot = New-Object System.Windows.Shapes.Rectangle
            $dot.Width = 8; $dot.Height = 8
            [System.Windows.Controls.Canvas]::SetLeft($dot, $lx)
            [System.Windows.Controls.Canvas]::SetTop($dot, 180)
            try { $dot.Fill = [System.Windows.Media.BrushConverter]::new().ConvertFromString($li.Color) } catch {}
            [void]$canvas.Children.Add($dot)
            $lbl = New-Object System.Windows.Controls.TextBlock
            $lbl.Text = $li.Label; $lbl.FontSize = 8; $lbl.Foreground = [System.Windows.Media.Brushes]::Gray
            $lbl.FontFamily = [System.Windows.Media.FontFamily]::new("Consolas")
            [System.Windows.Controls.Canvas]::SetLeft($lbl, $lx + 10)
            [System.Windows.Controls.Canvas]::SetTop($lbl, 179)
            [void]$canvas.Children.Add($lbl)
            $lx += 44
        }

        # Update canvas size to fit content
        $maxX = ($positions | Measure-Object X -Maximum).Maximum
        $maxY = ($positions | Measure-Object Y -Maximum).Maximum
        $canvas.Width  = [Math]::Max(240, ($maxX - $minX + 1) * $totalCell + 8)
        $canvas.Height = [Math]::Max(190, ($maxY - $minY + 1) * $totalCell + 30)
    })
}

# ============================================================
# BOSS MAP DROPS
# ============================================================
$script:MapDropItems = @{
    "neighborhood" = "map_neighborhood"
    "borough"      = "map_borough"
    "city"         = "map_city"
    "province"     = "map_province"
    "country"      = "map_country"
}

function Apply-MapDrop {
    param([string]$MapItemId)
    $g = $script:GS
    switch ($MapItemId) {
        "map_neighborhood" { Reveal-MapArea $g.CurrentRoom "neighborhood"; Write-Loot "Neighborhood map acquired! Area revealed on mini-map." }
        "map_borough"      { Reveal-MapArea $g.CurrentRoom "borough";      Write-Loot "Borough map acquired! Larger area revealed on mini-map." }
        "map_city"         { Reveal-MapArea $g.CurrentRoom "city";         Write-Loot "City map acquired! Extensive area revealed on mini-map." }
        "map_province"     { Reveal-MapArea $g.CurrentRoom "province";     Write-Loot "Province map acquired! Nearly the entire floor is revealed!" }
        "map_country"      { Reveal-MapArea $g.CurrentRoom "country";      Write-Loot "COUNTRY MAP! The entire floor is now visible on the mini-map!" }
    }
    # Remove from inventory after use (maps are auto-applied on pickup)
    $g.Inventory = $g.Inventory | Where-Object { $_ -ne $MapItemId }
}


# ============================================================
# COMMAND PARSER
# ============================================================
function Invoke-GameCommand {
    param([string]$Raw)
    $g = $script:GS
    if (-not $g) { return }
    $cmd = $Raw.Trim().ToLower()
    if ($cmd -eq "") { return }

    # In-dialogue: only REPLY commands matter
    if ($g.InDialogue) {
        if ($cmd -match "^reply\s+(\d)$" -or $cmd -match "^(\d)$") {
            $num = [int]($Matches[1])
            Do-Reply $num
        } else {
            Write-Warn "You're mid-conversation. Type REPLY 1-4 to respond, or a number."
        }
        return
    }

    # Movement shortcuts
    if ($cmd -in @("n","north"))  { Do-Move "north"; return }
    if ($cmd -in @("s","south"))  { Do-Move "south"; return }
    if ($cmd -in @("e","east"))   { Do-Move "east";  return }
    if ($cmd -in @("w","west"))   { Do-Move "west";  return }
    if ($cmd -in @("u","up"))     { Do-Move "up";    return }
    if ($cmd -in @("d","down"))   { Do-Move "down";  return }

    # Combat shortcuts while in combat
    if ($g.InCombat) {
        if ($cmd -in @("a","attack"))  { Do-Attack;        return }
        if ($cmd -in @("c","spell","cast","magic")) { Do-CastSpell; return }
        if ($cmd -in @("f","flee","run"))  { Do-Flee;      return }
        if ($cmd -eq "taunt")          { Do-Taunt;         return }
        if ($cmd -eq "distract")       { Do-Distract;      return }
        if ($cmd -eq "hide")           { Do-Hide;          return }
        if ($cmd -eq "talk") {
            $edef = $script:EnemyDB[$g.CurrentEnemy]
            if ($edef -and $edef.CanTalk) { Do-Talk ""; return }
            Write-Warn "This enemy doesn't want to talk."
            return
        }
        if ($cmd -eq "item" -or $cmd -eq "use") { Do-UseItemSelected; return }
    }

    # Dialogue replies
    if ($cmd -match "^reply\s+(\d)$") { Do-Reply ([int]$Matches[1]); return }

    # Movement
    if ($cmd -match "^(?:go|move)\s+(\w+)$") { Do-Move $Matches[1]; return }

    # Look / examine
    if ($cmd -in @("look","l","examine")) { Do-Look; return }
    if ($cmd -match "^(?:look|examine)\s+(.+)$") { Do-Examine $Matches[1]; return }

    # Interact
    if ($cmd -match "^interact(?:\s+(.+))?$") { Do-Interact $(if ($Matches[1]) { $Matches[1] } else { "" }); return }
    if ($cmd -match "^(?:use|open|search)\s+(.+)$") {
        $target = $Matches[1]
        if ($target -eq "box" -or $target -eq "loot box") { Do-OpenBox; return }
        Do-Interact $target
        return
    }

    # Talk
    if ($cmd -eq "talk") { Do-Talk ""; return }
    if ($cmd -match "^talk\s+(.+)$") { Do-Talk $Matches[1]; return }

    # Hide / scout
    if ($cmd -eq "hide")  { Do-Hide;  return }
    if ($cmd -eq "scout") { Do-Scout; return }

    # Taunt / distract (outside combat too, for laughs)
    if ($cmd -eq "taunt")    { Do-Taunt;    return }
    if ($cmd -eq "distract") { Do-Distract; return }

    # Inventory management
    if ($cmd -in @("i","inv","inventory")) { Do-Inventory; return }
    if ($cmd -in @("stats","s","stat","status","c","character")) { Do-Stats; return }
    if ($cmd -match "^(?:use|equip)\s+(.+)$") {
        $itemName = $Matches[1]
        $found = $g.Inventory | Where-Object { $n = $script:ItemDB[$_]; $nm = if ($n -and $n.Name) { $n.Name } else { $_ }; $nm.ToLower() -match $itemName } | Select-Object -First 1
        if ($found) { Invoke-UseItem $found }
        else { Write-Warn "No item matching '$itemName' in inventory." }
        return
    }
    if ($cmd -in @("take","take all","get all","pickup")) { Do-TakeAll; return }

    # Room actions
    if ($cmd -in @("search","loot")) { Do-Search; return }
    if ($cmd -in @("rest","sleep","r"))  { Do-Rest;  return }
    if ($cmd -in @("map","m"))           { Do-Map;   return }
    if ($cmd -in @("quests","q","quest","journal")) { Do-Quests; return }
    if ($cmd -in @("achievements","achieve","ach","a")) { Do-Achievements; return }
    if ($cmd -in @("craft"))             { Do-Craft; return }

    # Loot boxes
    if ($cmd -in @("open box","loot box","open loot box")) { Do-OpenBox; return }

    # Save/load
    if ($cmd -in @("save"))  { Save-Game; return }
    if ($cmd -in @("load"))  { Load-Game; return }

    # Help
    if ($cmd -in @("help","?","h")) {
        Write-Sep
        Write-Info "=== COMMANDS ==="
        Write-Terminal "  Movement:  N S E W U D  (or full words)" "#A0A0A0"
        Write-Terminal "  Combat:    ATTACK / SPELL / FLEE / TAUNT / DISTRACT / HIDE" "#A0A0A0"
        Write-Terminal "  Talk:      TALK [name]  - REPLY 1-4 to respond" "#A0A0A0"
        Write-Terminal "  World:     LOOK / INTERACT [thing] / EXAMINE [thing] / SCOUT / SEARCH" "#A0A0A0"
        Write-Terminal "  Items:     INVENTORY / USE [item] / EQUIP [item] / TAKE" "#A0A0A0"
        Write-Terminal "  Rest:      REST (safe rooms only)" "#A0A0A0"
        Write-Terminal "  Log:       MAP / QUESTS / ACHIEVEMENTS / STATS" "#A0A0A0"
        Write-Terminal "  System:    SAVE / LOAD" "#A0A0A0"
        Write-Sep
        return
    }

    # Unknown
    $fallbacks = @(
        "The dungeon logs your confusion for later study.",
        "Invalid command. The AI notes this. You don't want the AI to note things.",
        "You attempt '$($cmd.Substring(0,[Math]::Min(20,$cmd.Length)))'. Nothing happens. Embarrassingly.",
        "The dungeon has no subroutine for that. Try HELP."
    )
    Write-Warn $fallbacks[(Get-Random -Minimum 0 -Maximum $fallbacks.Count)]
}

# ============================================================
# OPENING SEQUENCE / NEW GAME
# ============================================================
function Show-OpeningSequence {
    param([System.Windows.Window]$Owner)
    $seq = $script:OpeningSequences[(Get-Random -Minimum 0 -Maximum $script:OpeningSequences.Count)]
    $dlg = New-Object System.Windows.Window
    $dlg.Title = "Dungeon Crawler World - Before"
    $dlg.Width = 680; $dlg.Height = 520
    $dlg.WindowStartupLocation = "CenterOwner"
    $dlg.Owner = $Owner
    $dlg.Background = [System.Windows.Media.Brushes]::Black
    $dlg.ResizeMode = "NoResize"

    $grid = New-Object System.Windows.Controls.Grid
    $grid.Margin = [System.Windows.Thickness]::new(24)
    $r1 = New-Object System.Windows.Controls.RowDefinition; $r1.Height = [System.Windows.GridLength]::Auto
    $r2 = New-Object System.Windows.Controls.RowDefinition; $r2.Height = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
    $r3 = New-Object System.Windows.Controls.RowDefinition; $r3.Height = [System.Windows.GridLength]::Auto
    $grid.RowDefinitions.Add($r1); $grid.RowDefinitions.Add($r2); $grid.RowDefinitions.Add($r3)

    $title = New-Object System.Windows.Controls.TextBlock
    $title.Text = $seq.Title
    $title.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FF3B30")
    $title.FontFamily = [System.Windows.Media.FontFamily]::new("Consolas")
    $title.FontSize = 20; $title.FontWeight = [System.Windows.FontWeights]::Bold
    $title.Margin = [System.Windows.Thickness]::new(0,0,0,12)
    [System.Windows.Controls.Grid]::SetRow($title, 0)

    $sv = New-Object System.Windows.Controls.ScrollViewer
    $sv.VerticalScrollBarVisibility = "Auto"
    $sv.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#0A0A0A")
    $sv.Padding = [System.Windows.Thickness]::new(10)
    [System.Windows.Controls.Grid]::SetRow($sv, 1)
    $tb = New-Object System.Windows.Controls.TextBlock
    $tb.Text = $seq.Text
    $tb.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#C8C8C8")
    $tb.FontFamily = [System.Windows.Media.FontFamily]::new("Consolas")
    $tb.FontSize = 13; $tb.TextWrapping = "Wrap"
    $sv.Content = $tb

    $btnPanel = New-Object System.Windows.Controls.StackPanel
    $btnPanel.Orientation = "Horizontal"; $btnPanel.HorizontalAlignment = "Center"
    $btnPanel.Margin = [System.Windows.Thickness]::new(0,14,0,0)
    [System.Windows.Controls.Grid]::SetRow($btnPanel, 2)

    $btnDescend = New-Object System.Windows.Controls.Button
    $btnDescend.Content = "DESCEND INTO THE DUNGEON"
    $btnDescend.Padding = [System.Windows.Thickness]::new(20,8,20,8)
    $btnDescend.Margin = [System.Windows.Thickness]::new(0,0,12,0)
    $btnDescend.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FF3B30")
    $btnDescend.Foreground = [System.Windows.Media.Brushes]::White
    $btnDescend.FontFamily = [System.Windows.Media.FontFamily]::new("Consolas")
    $btnDescend.FontWeight = [System.Windows.FontWeights]::Bold
    $btnDescend.Tag = "descend"
    $btnDescend.Add_Click({ $dlg.Tag = "descend"; $dlg.Close() })

    $btnRefuse = New-Object System.Windows.Controls.Button
    $btnRefuse.Content = "REFUSE TO ENTER"
    $btnRefuse.Padding = [System.Windows.Thickness]::new(20,8,20,8)
    $btnRefuse.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1C1C1E")
    $btnRefuse.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#8E8E93")
    $btnRefuse.FontFamily = [System.Windows.Media.FontFamily]::new("Consolas")
    $btnRefuse.Tag = "refuse"
    $btnRefuse.Add_Click({ $dlg.Tag = "refuse"; $dlg.Close() })

    $btnPanel.Children.Add($btnDescend) | Out-Null
    $btnPanel.Children.Add($btnRefuse)  | Out-Null

    $grid.Children.Add($title)    | Out-Null
    $grid.Children.Add($sv)       | Out-Null
    $grid.Children.Add($btnPanel) | Out-Null
    $dlg.Content = $grid
    $dlg.ShowDialog() | Out-Null
    return $dlg.Tag
}

function Show-RefuseGameOver {
    param([System.Windows.Window]$Owner)
    $msgs = @(
        "You stand outside the glowing rune portal and shake your head. 'No,' you say. 'Not today.'"
        "The ground shakes. The portal hums. An administrative voice drones: 'Crawler $($script:GS.PlayerName) has refused to enter. Under Borant Corporation Policy 7-Alpha, refusal is classified as voluntary dissolution of contract. Goodbye.'"
        "The portal closes. A small tooltip appears where it was: [Achievement Unlocked: The Coward's Path] +0 gold. +0 viewers. +1 story to tell at parties you will no longer be invited to."
        "GAME OVER. You stood outside a dungeon until the planet processed you. Congratulations."
    )
    $dlg = New-Object System.Windows.Window
    $dlg.Title = "The End (Already)"
    $dlg.Width = 520; $dlg.Height = 340
    $dlg.WindowStartupLocation = "CenterOwner"
    $dlg.Owner = $Owner
    $dlg.Background = [System.Windows.Media.Brushes]::Black
    $dlg.ResizeMode = "NoResize"
    $sp = New-Object System.Windows.Controls.StackPanel
    $sp.Margin = [System.Windows.Thickness]::new(30)
    foreach ($m in $msgs) {
        $tb = New-Object System.Windows.Controls.TextBlock
        $tb.Text = $m; $tb.TextWrapping = "Wrap"
        $tb.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#8E8E93")
        $tb.FontFamily = [System.Windows.Media.FontFamily]::new("Consolas")
        $tb.FontSize = 12; $tb.Margin = [System.Windows.Thickness]::new(0,0,0,10)
        $sp.Children.Add($tb) | Out-Null
    }
    $btn = New-Object System.Windows.Controls.Button
    $btn.Content = "Try Again (with spine this time)"
    $btn.Padding = [System.Windows.Thickness]::new(16,7,16,7)
    $btn.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2C2C2E")
    $btn.Foreground = [System.Windows.Media.Brushes]::White
    $btn.FontFamily = [System.Windows.Media.FontFamily]::new("Consolas")
    $btn.Add_Click({ $dlg.Close() })
    $sp.Children.Add($btn) | Out-Null
    $dlg.Content = New-Object System.Windows.Controls.ScrollViewer
    $dlg.Content.Content = $sp
    $dlg.ShowDialog() | Out-Null
}

function Show-NewGameDialog {
    param([System.Windows.Window]$Owner)
    $dlg = New-Object System.Windows.Window
    $dlg.Title = "New Crawler"
    $dlg.Width = 420; $dlg.Height = 220
    $dlg.WindowStartupLocation = "CenterOwner"
    $dlg.Owner = $Owner
    $dlg.Background = [System.Windows.Media.Brushes]::Black
    $dlg.ResizeMode = "NoResize"

    $sp = New-Object System.Windows.Controls.StackPanel
    $sp.Margin = [System.Windows.Thickness]::new(24)

    $lbl = New-Object System.Windows.Controls.TextBlock
    $lbl.Text = "WHAT DO THEY CALL YOU?"
    $lbl.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FF3B30")
    $lbl.FontFamily = [System.Windows.Media.FontFamily]::new("Consolas")
    $lbl.FontSize = 16; $lbl.FontWeight = [System.Windows.FontWeights]::Bold
    $lbl.Margin = [System.Windows.Thickness]::new(0,0,0,14)

    $txt = New-Object System.Windows.Controls.TextBox
    $txt.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1C1C1E")
    $txt.Foreground = [System.Windows.Media.Brushes]::White
    $txt.CaretBrush = [System.Windows.Media.Brushes]::White
    $txt.FontFamily = [System.Windows.Media.FontFamily]::new("Consolas")
    $txt.FontSize = 16; $txt.Padding = [System.Windows.Thickness]::new(10,6,10,6)
    $txt.Text = "Carl"
    $txt.Margin = [System.Windows.Thickness]::new(0,0,0,14)

    $btn = New-Object System.Windows.Controls.Button
    $btn.Content = "BEGIN"
    $btn.Padding = [System.Windows.Thickness]::new(20,8,20,8)
    $btn.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FF3B30")
    $btn.Foreground = [System.Windows.Media.Brushes]::White
    $btn.FontFamily = [System.Windows.Media.FontFamily]::new("Consolas")
    $btn.FontWeight = [System.Windows.FontWeights]::Bold
    $btn.Add_Click({ $dlg.Tag = $txt.Text; $dlg.Close() })

    $txt.Add_KeyDown({
        param($s,$e)
        if ($e.Key -eq [System.Windows.Input.Key]::Return) { $dlg.Tag = $txt.Text; $dlg.Close() }
    })

    $sp.Children.Add($lbl) | Out-Null
    $sp.Children.Add($txt) | Out-Null
    $sp.Children.Add($btn) | Out-Null
    $dlg.Content = $sp
    $dlg.ShowDialog() | Out-Null
    return $dlg.Tag
}

function Show-Tutorial {
    $g = $script:GS
    if ($g.TutorialComplete) { return }
    Write-Sep
    Write-Terminal "=== TUTORIAL GUILD ===" "#FFD60A" $true
    Write-Mordecai "Alright. Before you go die, let me explain how this works. Briefly. I have other crawlers."
    Write-Terminal "" "#E8E8E8"
    Write-Mordecai "Top-left: your health and mana. Those bars going to zero is bad. One of them going to zero is especially bad."
    Write-Mordecai "Bottom-left: your stats. STR hits things. DEX dodges things. INT casts things and scouts. CON survives things. CHA talks your way out of things. LCK -- well, LCK is LCK."
    Write-Terminal "" "#E8E8E8"
    Write-Mordecai "Right panel: your inventory. Click USE/EQUIP or type USE [item]. Loot boxes only open in safe rooms. Which this is."
    Write-Mordecai "That map panel on the right -- it updates as you explore. Kill a boss, you get a map. Bigger boss, bigger map reveal."
    Write-Terminal "" "#E8E8E8"
    Write-Mordecai "Commands: LOOK. MOVE. TALK. ATTACK. HIDE. SCOUT. SEARCH. Type HELP if you need the list."
    Write-Mordecai "The AI will occasionally say things. Ignore it. Or don't. Either way it keeps happening."
    Write-Terminal "" "#E8E8E8"
    Write-Mordecai "The stairwell is north of here. The dungeon is up there. I'll see you on the other side."
    Write-Mordecai "Or I won't. Both outcomes have happened before."
    Write-Sep
    $g.TutorialComplete = $true
    $g.TutorialStep = 99
}

# ============================================================
# START NEW GAME FLOW
# ============================================================
function Start-NewGame {
    $name = Show-NewGameDialog $script:Window
    if (-not $name) { $name = "Carl" }
    New-GameState -Name $name
    Compute-AllFloorPositions
    Load-ExternalData
    # Opening sequence
    $result = Show-OpeningSequence $script:Window
    if ($result -eq "refuse") {
        Show-RefuseGameOver $script:Window
        # Loop back: let them try again
        Start-NewGame
        return
    }
    # Begin game
    $script:Window.Dispatcher.Invoke([Action]{
        $rtb = $script:Window.FindName("rtbOutput")
        if ($rtb) { $rtb.Document.Blocks.Clear() }
    })
    Write-System $script:FloorData[1].Intro
    Write-Sep
    Enter-Room "f1_tutorial_guild"
    Show-Tutorial
    Update-HUD
    Render-MiniMap
}


# ============================================================
# BOOTSTRAP - WINDOW + BUTTON WIRING
# ============================================================
$script:Window = $null
$script:UI_Terminal = $null

try {
    $script:Window = [Windows.Markup.XamlReader]::Parse($xaml)
} catch {
    [System.Windows.MessageBox]::Show("XAML parse error: $_", "Load Error")
    exit 1
}

# ---- Element references ----
$script:UI_Terminal = $script:Window.FindName("rtbOutput")

# ---- Macro: wire a nav button to a direction ----
function Wire-NavBtn {
    param([string]$BtnName, [string]$Direction)
    $btn = $script:Window.FindName($BtnName)
    if (-not $btn) { return }
    $btn.Add_Click({ Do-Move $Direction })
}
Wire-NavBtn "btnNavN"  "north"
Wire-NavBtn "btnNavS"  "south"
Wire-NavBtn "btnNavE"  "east"
Wire-NavBtn "btnNavW"  "west"
Wire-NavBtn "btnNavUp" "up"
Wire-NavBtn "btnNavDown" "down"

# ---- Submit command ----
$btnSubmit = $script:Window.FindName("btnSubmit")
$txtInput  = $script:Window.FindName("TxtInput")
$submitCmd = {
    $cmd = $txtInput.Text.Trim()
    $txtInput.Text = ""
    if ($cmd) { Invoke-GameCommand $cmd }
    $txtInput.Focus() | Out-Null
}
if ($btnSubmit) { $btnSubmit.Add_Click($submitCmd) }
if ($txtInput)  { $txtInput.Add_KeyDown({
    param($s,$e)
    if ($e.Key -eq [System.Windows.Input.Key]::Return) { & $submitCmd }
}) }

# ---- Action bar buttons ----
$btnLook = $script:Window.FindName("btnLook")
if ($btnLook) { $btnLook.Add_Click({ Do-Look }) }

$btnSearch = $script:Window.FindName("btnSearch")
if ($btnSearch) { $btnSearch.Add_Click({ Do-Search }) }

$btnRest = $script:Window.FindName("btnRest")
if ($btnRest) { $btnRest.Add_Click({ Do-Rest }) }

$btnTalk = $script:Window.FindName("btnTalk")
if ($btnTalk) { $btnTalk.Add_Click({ Do-Talk "" }) }

$btnInteract = $script:Window.FindName("btnInteract")
if ($btnInteract) { $btnInteract.Add_Click({ Do-Interact "" }) }

$btnHide = $script:Window.FindName("btnHide")
if ($btnHide) { $btnHide.Add_Click({ Do-Hide }) }

$btnAchieves = $script:Window.FindName("btnAchieves")
if ($btnAchieves) { $btnAchieves.Add_Click({ Do-Achievements }) }

# ---- Combat buttons ----
$btnAttack = $script:Window.FindName("btnAttack")
if ($btnAttack) { $btnAttack.Add_Click({ Do-Attack }) }

$btnSpell = $script:Window.FindName("btnSpell")
if ($btnSpell) { $btnSpell.Add_Click({ Do-CastSpell }) }

$btnFlee = $script:Window.FindName("btnFlee")
if ($btnFlee) { $btnFlee.Add_Click({ Do-Flee }) }

$btnTaunt = $script:Window.FindName("btnTaunt")
if ($btnTaunt) { $btnTaunt.Add_Click({ Do-Taunt }) }

$btnDistract = $script:Window.FindName("btnDistract")
if ($btnDistract) { $btnDistract.Add_Click({ Do-Distract }) }

$btnUseItem = $script:Window.FindName("btnUseItem")
if ($btnUseItem) { $btnUseItem.Add_Click({ Do-UseItemSelected }) }

# ---- Inventory USE/EQUIP button ----
$btnInvPanel = $script:Window.FindName("btnInvPanel")
if ($btnInvPanel) { $btnInvPanel.Add_Click({ Do-UseItemSelected }) }

# ---- Loot box ----
$btnOpenBox = $script:Window.FindName("btnOpenBox")
if ($btnOpenBox) { $btnOpenBox.Add_Click({ Do-OpenBox }) }

# ---- Dialogue reply buttons ----
for ($i = 1; $i -le 4; $i++) {
    $idx = $i
    $btn = $script:Window.FindName("btnReply$idx")
    if ($btn) { $btn.Add_Click([ScriptBlock]::Create("Do-Reply $idx")) }
}

# ---- Splash / New Game button ----
$btnNewGame = $script:Window.FindName("btnNewGame")
if ($btnNewGame) { $btnNewGame.Add_Click({ Start-NewGame }) }

# ---- Map / Stats / Inventory keyboard shortcuts ----
$script:Window.Add_KeyDown({
    param($s,$e)
    switch ($e.Key) {
        ([System.Windows.Input.Key]::F1)  { Do-Help }
        ([System.Windows.Input.Key]::F2)  { Save-Game }
        ([System.Windows.Input.Key]::F5)  { Load-Game }
        ([System.Windows.Input.Key]::Tab) { $txtInput.Focus() | Out-Null; $e.Handled = $true }
    }
})

# ============================================================
# SPLASH SCREEN
# ============================================================
$script:Window.Add_Loaded({
    Write-Terminal "+==================================================+" "#FF3B30"
    Write-Terminal "|          DUNGEON CRAWLER WORLD  S.14             |" "#FF3B30"
    Write-Terminal "|                                                  |" "#FF3B30"
    Write-Terminal "|       A Borant Corporation Experience(tm)            |" "#8E8E93"
    Write-Terminal "+==================================================+" "#FF3B30"
    Write-Terminal "" "#E8E8E8"
    Write-Terminal "  Earth is gone. The dungeon is here. So are you." "#C8C8C8"
    Write-Terminal "  Approximately 142 people are already watching." "#8E8E93"
    Write-Terminal "" "#E8E8E8"
    Write-Terminal "  Press NEW GAME to begin, or LOAD to continue." "#FFD60A"
    Write-Terminal "" "#E8E8E8"
    Write-System "System initialized. Awaiting crawler registration."
    $script:Window.Dispatcher.Invoke([Action]{
        $btnNewGame = $script:Window.FindName("btnNewGame")
        if ($btnNewGame) { $btnNewGame.Visibility = "Visible" }
    })
})

# ---- Show window ----
$script:Window.ShowDialog() | Out-Null

