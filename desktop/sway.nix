{ pkgs, config, ... }:

{
  wayland.windowManager.sway = {
    enable = true;
    wrapperFeatures.gtk = true;

    config = null;
    extraConfig = ''
    ## Variables ###

    set $mod Mod4

    set $left h
    set $down j
    set $up k
    set $right l

    set $term "alacritty"
    set $menu dmenu_path | dmenu | xargs swaymsg exec --

    set $volup "pamixer -ui 1"
    set $voldown "pamixer -ud 1"
    set $volmute "pamixer --toggle-mute"

    set $play-pause "playerctl play-pause"
    set $next "playerctl next"
    set $prev "playerctl previous"

    set $lightup "light -A 1"
    set $lightdown "light -U 1"

    ## Looks ##

    exec "gsettings set org.gnome.desktop.interface gtk-theme paradise"
    exec "gsettings set org.gnome.desktop.interface icon-theme Papirus-Dark"
    exec "gsettings set org.gnome.desktop.interface cursor-theme retrosmart-xcursor-black-color-shadow"
    exec "gsettings set org.gnome.desktop.interface font-name 'Noto Sans 9'"
    exec "gsettings set org.gnome.desktop.interface document-font-name 'Noto Serif 9'"
    exec "gsettings set org.gnome.desktop.interface monospace-font-name 'envypn 10'"

    output * bg ~/.wallpaper fill

    # Start flavours
    ## Base16 paradise
    # Author: Manas140

    set $base00 #151515
    set $base01 #1f1f1f
    set $base02 #282828
    set $base03 #3b3b3b
    set $base04 #e8e3e3
    set $base05 #e8e3e3
    set $base06 #e8e3e3
    set $base07 #e8e3e3
    set $base08 #b66467
    set $base09 #d9bc8c
    set $base0A #d9bc8c
    set $base0B #8c977d
    set $base0C #8aa6a2
    set $base0D #8da3b9
    set $base0E #a988b0
    set $base0F #d9bc8c
    # End flavours

    client.focused          $base05 $base0B $base00 $base0B $base0B
    client.focused_inactive $base01 $base01 $base05 $base03 $base01
    client.unfocused        $base01 $base00 $base05 $base01 $base01
    client.urgent           $base08 $base08 $base00 $base08 $base08

    default_border pixel 1
    default_floating_border pixel 1
    gaps inner 12

    ## Input ##

    input "1739:32552:MSFT0001:00_06CB:7F28_Touchpad" {
        tap enabled
        natural_scroll disabled
        dwt enabled
        accel_profile "adaptive" # disable mouse acceleration (enabled by default; to set it manually, use "adaptive" instead of "flat")
        pointer_accel -0.1 # set mouse sensitivity (between -1 and 1)
    }

    input * {
        xkb_layout "it"
    }

    focus_follows_mouse no
    floating_modifier $mod normal

    ## Core Keybinds ##

    bindsym $mod+Return exec $term
    bindsym $mod+c exec firefox
    bindsym $mod+q kill
    bindsym $mod+d exec $menu
    bindsym $mod+Shift+c reload
    bindsym $mod+Shift+e exec swaynag -t warning -m 'Exit sway and logout?' -b 'Yes' 'swaymsg exit'

    bindsym $mod+p exec "grimshot --notify save output $XDG_SCREENSHOTS_DIR/Screenshot_$(date '+%Y%m%d-%H%M%S').png"
    bindsym $mod+Shift+p exec "grimshot --notify save area $XDG_SCREENSHOTS_DIR/Screenshot_$(date '+%Y%m%d-%H%M%S').png"
    bindsym $mod+Shift+Alt+p exec "grimshot --notify save window $XDG_SCREENSHOTS_DIR/Screenshot_$(date '+%Y%m%d-%H%M%S').png"

    bindsym --locked XF86AudioRaiseVolume exec $volup
    bindsym --locked XF86AudioLowerVolume exec $voldown
    bindsym --locked XF86AudioMute exec $volmute

    bindsym --locked $mod+XF86AudioMute exec $play-pause
    bindsym --locked $mod+XF86AudioLowerVolume exec $prev
    bindsym --locked $mod+XF86AudioRaiseVolume exec $next
    bindsym --locked XF86AudioPlay exec $play-pause
    bindsym --locked XF86AudioPrev exec $prev
    bindsym --locked XF86AudioNext exec $next

    bindsym --locked XF86MonBrightnessUp exec $lightup
    bindsym --locked XF86MonBrightnessDown exec $lightdown

    ## Movement ##

    bindsym $mod+$left focus left
    bindsym $mod+$down focus down
    bindsym $mod+$up focus up
    bindsym $mod+$right focus right

    bindsym $mod+Shift+$left move left
    bindsym $mod+Shift+$down move down
    bindsym $mod+Shift+$up move up
    bindsym $mod+Shift+$right move right

    ## Workspaces ##

    bindsym $mod+1 workspace number 1
    bindsym $mod+2 workspace number 2
    bindsym $mod+3 workspace number 3
    bindsym $mod+4 workspace number 4
    bindsym $mod+5 workspace number 5
    bindsym $mod+6 workspace number 6
    bindsym $mod+7 workspace number 7
    bindsym $mod+8 workspace number 8
    bindsym $mod+9 workspace number 9
    bindsym $mod+0 workspace number 10

    bindsym $mod+Shift+1 move container to workspace number 1
    bindsym $mod+Shift+2 move container to workspace number 2
    bindsym $mod+Shift+3 move container to workspace number 3
    bindsym $mod+Shift+4 move container to workspace number 4
    bindsym $mod+Shift+5 move container to workspace number 5
    bindsym $mod+Shift+6 move container to workspace number 6
    bindsym $mod+Shift+7 move container to workspace number 7
    bindsym $mod+Shift+8 move container to workspace number 8
    bindsym $mod+Shift+9 move container to workspace number 9
    bindsym $mod+Shift+0 move container to workspace number 10

    bindsym $mod+b splith
    bindsym $mod+v splitv

    bindsym $mod+s layout stacking
    bindsym $mod+w layout tabbed
    bindsym $mod+e layout toggle split

    bindsym $mod+f fullscreen
    bindsym $mod+Shift+space floating toggle
    bindsym $mod+space focus mode_toggle
    bindsym $mod+a focus parent

    bindsym $mod+Shift+minus move scratchpad
    bindsym $mod+minus scratchpad show

    mode "resize" {
        bindsym $left resize shrink width 10px
        bindsym $down resize grow height 10px
        bindsym $up resize shrink height 10px
        bindsym $right resize grow width 10px

        bindsym Left resize shrink width 10px
        bindsym Down resize grow height 10px
        bindsym Up resize shrink height 10px
        bindsym Right resize grow width 10px

        bindsym Return mode "default"
        bindsym Escape mode "default"
    }
    bindsym $mod+r mode "resize"

    ## Rules ##

    # workspace 1 - browser
    assign [app_id="firefox"] 1

    # workspace 2 - terminals

    # workspace 3 - work
    assign [app_id="libreoffice|libreoffice-startcenter"] 3

    # workspace 4 - games
    for_window [class="Steam"] move workspace 4

    # workspace 5 - media

    # workspace 6 - music

    # workspace 7 - chat
    for_window [class="discord"] move workspace 7

    # workspace 8 - downloads
    assign [app_id="deluge"] 8

    # workspace 10 - telegram
    assign [app_id="telegram-desktop"] 10

    # floats, positions, sizes
    for_window [app_id="mpv"] floating enable, move position center
    for_window [app_id="imv"] floating enable, move position center


    ## Bar ##
    bar {
      swaybar_command waybar
    }

    ## Autostart ##

    # exec_always "sh -c 'killall kanshi; exec kanshi'"
    # exec "udiskie -a -n -T -F --no-terminal"
    exec nightlight
    exec mako
    exec "swayidle -w \
      timeout 300 'light -O; light -S 5' resume 'light -I' \
      timeout 600 'swaylock -f' \
      before-sleep 'playerctl -a pause; swaymsg output eDP-1 dpms on; swaylock -f'"

    exec wlsunset
    '';
  };

  home.packages = with pkgs; [
    swaylock
    swayidle
    wl-clipboard
    mako # notification daemon
    alacritty # Alacritty is the default terminal in the config
    dmenu # Dmenu is the default in the config but i recommend wofi since its wayland native
    waybar
    wlsunset
  ];
}
