{ config, lib, pkgs, ... }:

# The desktop chosen in the installer (snapos.desktop). Every choice gets the
# SnapOS look (red Colloid or Breeze, red Papirus icons, the SnapOS
# wallpaper, dark or light), the lightdm login screen, and the SnapOS programs
# started at login: SnapGuard's watcher, the update check and SnapHelper.

with lib;
let
  cfg = config.snapos;
  desk = cfg.desktop;
  light = cfg.appearance == "light";
  mode = if light then "light" else "dark";

  redIcons  = pkgs.papirus-icon-theme.override { color = "red"; };
  gtkTheme  = if light then "SnapOS-Light" else "Colloid-Red-Dark";
  iconName  = if light then "Papirus-Light" else "Papirus-Dark";
  wallpaper = "${pkgs.snapos-backgrounds}/share/backgrounds/snapos/snapos-${mode}.jpeg";

  # Colors shared by the Hyprland pieces (bar, launcher, notifications).
  accent = "e22a1c";
  bg     = if light then "ece9e5" else "121212";
  fg     = if light then "000000" else "e8e8e8";
  dim    = if light then "c9c4be" else "333333";

  # The icons of the Hyprland bar: the SnapOS programs pinned like on
  # Budgie's dock (menu, defender, browser, programs store, terminal).
  papirusApps = "${redIcons}/share/icons/Papirus/48x48/apps";
  barIcons = pkgs.runCommand "snapos-bar-icons" { nativeBuildInputs = [ pkgs.librsvg ]; } ''
    mkdir -p $out
    cp ${../../branding/icons}/snapos-48.png $out/menu.png
    cp ${../../branding/icons}/snapguard-${if light then "light" else "dark"}-48.png $out/snapguard.png
    for i in firefox org.gnome.Software kitty; do
      rsvg-convert -w 48 -h 48 ${papirusApps}/$i.svg -o $out/$i.png
    done
  '';
  launcher = "wofi --show drun --conf /etc/xdg/wofi/config --style /etc/xdg/wofi/style.css";

  # ---- Hyprland: a complete, keyboard-driven desktop out of the box ----------
  hyprlandConf = pkgs.writeText "hyprland.conf" ''
    # SnapOS Hyprland. Super is the main key: Super+Enter terminal, Super+D
    # launcher, Super+Q close, Super+E files, Super+1..9 workspaces,
    # Super+Shift+1..9 move a window there, Super+L lock, Print screenshot.
    monitor = , preferred, auto, 1

    exec-once = waybar
    exec-once = mako
    exec-once = hyprpaper
    exec-once = nm-applet --indicator
    exec-once = snapguard-watch
    exec-once = snapupdate --autostart
    exec-once = snaphelper --first-run

    env = XCURSOR_SIZE, 24
    env = GTK_THEME, ${gtkTheme}

    input {
        kb_layout = ${config.services.xserver.xkb.layout}
        kb_variant = ${config.services.xserver.xkb.variant}
        follow_mouse = 1
        touchpad {
            natural_scroll = true
            disable_while_typing = false
        }
    }

    general {
        gaps_in = 6
        gaps_out = 12
        border_size = 2
        col.active_border = rgb(${accent})
        col.inactive_border = rgb(${dim})
        layout = dwindle
    }

    decoration {
        rounding = 8
    }

    animations {
        enabled = true
    }

    dwindle {
        preserve_split = true
    }

    misc {
        disable_hyprland_logo = true
        disable_splash_rendering = true
    }

    # SnapOS windows float in the middle of the screen, like on the other
    # desktops; everything else tiles.
    windowrule = match:class ^(snaphelper|snapupdate|snapguard-gui|snapconfig|snapctl|org\.snapos\..*)$, float on, center on
    windowrule = match:class ^(pavucontrol|nm-connection-editor)$, float on, center on

    $mod = SUPER
    bind = $mod, RETURN, exec, kitty
    bind = $mod, D, exec, ${launcher}
    bind = $mod, E, exec, thunar
    bind = $mod, Q, killactive,
    bind = $mod, F, fullscreen,
    bind = $mod, V, togglefloating,
    bind = $mod, L, exec, hyprlock
    bind = $mod SHIFT, E, exit,
    bind = , Print, exec, grim -g "$(slurp)" - | wl-copy
    bind = $mod, left, movefocus, l
    bind = $mod, right, movefocus, r
    bind = $mod, up, movefocus, u
    bind = $mod, down, movefocus, d
    bind = $mod, 1, workspace, 1
    bind = $mod, 2, workspace, 2
    bind = $mod, 3, workspace, 3
    bind = $mod, 4, workspace, 4
    bind = $mod, 5, workspace, 5
    bind = $mod, 6, workspace, 6
    bind = $mod, 7, workspace, 7
    bind = $mod, 8, workspace, 8
    bind = $mod, 9, workspace, 9
    bind = $mod SHIFT, 1, movetoworkspace, 1
    bind = $mod SHIFT, 2, movetoworkspace, 2
    bind = $mod SHIFT, 3, movetoworkspace, 3
    bind = $mod SHIFT, 4, movetoworkspace, 4
    bind = $mod SHIFT, 5, movetoworkspace, 5
    bind = $mod SHIFT, 6, movetoworkspace, 6
    bind = $mod SHIFT, 7, movetoworkspace, 7
    bind = $mod SHIFT, 8, movetoworkspace, 8
    bind = $mod SHIFT, 9, movetoworkspace, 9
    bindm = $mod, mouse:272, movewindow
    bindm = $mod, mouse:273, resizewindow
    bindel = , XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+
    bindel = , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
    bindl = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
    bindel = , XF86MonBrightnessUp, exec, brightnessctl set 5%+
    bindel = , XF86MonBrightnessDown, exec, brightnessctl set 5%-
  '';

  hyprpaperConf = pkgs.writeText "hyprpaper.conf" ''
    preload = ${wallpaper}
    wallpaper = , ${wallpaper}
    splash = false
  '';

  hyprlockConf = pkgs.writeText "hyprlock.conf" ''
    background {
        path = ${wallpaper}
        blur_passes = 2
    }
    input-field {
        size = 260, 48
        outline_thickness = 2
        outer_color = rgb(${accent})
        inner_color = rgb(${bg})
        font_color = rgb(${fg})
        placeholder_text = <i>Password</i>
    }
  '';

  waybarConfig = pkgs.writeText "waybar-config" (builtins.toJSON {
    layer = "top";
    position = "bottom";
    height = 45;
    spacing = 2;
    modules-left = [ "image#menu" "image#snapguard" "image#firefox" "image#software" "image#terminal" "wlr/taskbar" ];
    modules-center = [ "hyprland/workspaces" ];
    modules-right = [ "tray" "network" "pulseaudio" "battery" "clock" ];
    "image#menu" = { path = "${barIcons}/menu.png"; size = 28; on-click = launcher; tooltip = false; };
    "image#snapguard" = { path = "${barIcons}/snapguard.png"; size = 26; on-click = "snapguard-gui"; tooltip = false; };
    "image#firefox" = { path = "${barIcons}/firefox.png"; size = 26; on-click = "firefox"; tooltip = false; };
    "image#software" = { path = "${barIcons}/org.gnome.Software.png"; size = 26; on-click = "gnome-software"; tooltip = false; };
    "image#terminal" = { path = "${barIcons}/kitty.png"; size = 26; on-click = "kitty"; tooltip = false; };
    "wlr/taskbar" = { format = "{icon}"; icon-size = 24; icon-theme = iconName; on-click = "activate"; on-click-middle = "close"; tooltip-format = "{title}"; };
    "hyprland/workspaces" = { format = "{id}"; on-click = "activate"; };
    clock = { format = "{:%H:%M}"; format-alt = "{:%a %d %b %Y}"; tooltip-format = "{:%A, %d %B %Y}"; };
    network = { format-wifi = "  {essid}"; format-ethernet = "  wired"; format-disconnected = "  offline"; on-click = "nm-connection-editor"; };
    pulseaudio = { format = "  {volume}%"; format-muted = "  muted"; on-click = "pavucontrol"; };
    battery = { format = "  {capacity}%"; format-charging = "  {capacity}%"; };
    tray = { spacing = 8; icon-size = 20; };
  });

  waybarStyle = pkgs.writeText "waybar-style.css" ''
    * { font-family: "DejaVu Sans", "Symbols Nerd Font", sans-serif; font-size: 13px; min-height: 0; }
    window#waybar { background: #${bg}; color: #${fg}; border-top: 1px solid #${accent}; }
    #image { padding: 0 8px; }
    #image.menu { padding: 0 10px 0 12px; }
    #taskbar { margin-left: 6px; }
    #taskbar button { padding: 0 6px; border-bottom: 3px solid transparent; }
    #taskbar button.active { border-bottom: 3px solid #${accent}; }
    #workspaces button { padding: 0 8px; color: #${fg}; border-bottom: 3px solid transparent; }
    #workspaces button.active { color: #${accent}; border-bottom: 3px solid #${accent}; }
    #clock, #network, #pulseaudio, #battery, #tray { padding: 0 10px; }
    #clock { font-weight: bold; padding-right: 16px; }
  '';

  wofiConfig = pkgs.writeText "wofi-config" ''
    show=drun
    width=520
    height=380
    prompt=Run
    allow_images=true
    insensitive=true
  '';

  wofiStyle = pkgs.writeText "wofi-style.css" ''
    window { background-color: #${bg}; border: 2px solid #${accent}; border-radius: 10px; color: #${fg}; }
    #input { margin: 8px; border: 1px solid #${dim}; border-radius: 6px; background-color: #${bg}; color: #${fg}; }
    #entry:selected { background-color: #${accent}; color: #ffffff; border-radius: 6px; }
  '';

  makoConfig = pkgs.writeText "mako-config" ''
    background-color=#${bg}
    text-color=#${fg}
    border-color=#${accent}
    border-size=2
    border-radius=8
    default-timeout=6000
    font=DejaVu Sans 11
  '';

  # The Hyprland session: the SnapOS configuration is copied to the user's
  # folder the first time, so it can be changed afterwards.
  hyprlandSession = pkgs.writeShellScriptBin "snapos-hyprland-session" ''
    d="''${XDG_CONFIG_HOME:-$HOME/.config}/hypr"
    if [ ! -e "$d/hyprland.conf" ]; then
      mkdir -p "$d"
      cp /etc/snapos/hypr/hyprland.conf /etc/snapos/hypr/hyprpaper.conf /etc/snapos/hypr/hyprlock.conf "$d/"
      chmod u+w "$d"/*.conf
    fi
    # start-hyprland sets the session up the way Hyprland expects (0.50+)
    exec ${pkgs.hyprland}/bin/start-hyprland
  '';
  hyprlandSessionPackage = pkgs.runCommand "snapos-hyprland-session" { passthru.providedSessions = [ "snapos-hyprland" ]; } ''
    mkdir -p $out/share/wayland-sessions
    cat > $out/share/wayland-sessions/snapos-hyprland.desktop <<EOF
    [Desktop Entry]
    Name=Hyprland (SnapOS)
    Comment=Tiling Wayland desktop, keyboard-driven
    Exec=${hyprlandSession}/bin/snapos-hyprland-session
    Type=Application
    DesktopNames=Hyprland
    EOF
  '';

  # ---- Plasma and Xfce: the look applied on the first login -------------------
  # plasma-apply-* and xfconf-query only work inside a session, so a small
  # autostart entry applies the wallpaper and theme once per user.
  plasmaLook = pkgs.writeShellScriptBin "snapos-plasma-look" ''
    dir="''${XDG_CONFIG_HOME:-$HOME/.config}/snapos"
    mkdir -p "$dir"
    marker="$dir/plasma-look-done"
    [ -e "$marker" ] && exit 0
    exec >> "$dir/plasma-look.log" 2>&1
    # the shell must be up before it can be told anything
    for i in $(seq 1 60); do
      ${pkgs.systemd}/bin/busctl --user list 2>/dev/null | grep -q org.kde.plasmashell && break
      sleep 2
    done
    sleep 5
    ${pkgs.kdePackages.plasma-workspace}/bin/plasma-apply-lookandfeel -a ${if light then "org.kde.breeze.desktop" else "org.kde.breezedark.desktop"}
    ${pkgs.kdePackages.plasma-workspace}/bin/plasma-apply-wallpaperimage ${wallpaper} || exit 1
    # the panel like Budgie's dock: 45 pixels, the SnapOS programs pinned
    ${pkgs.systemd}/bin/busctl --user call org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell evaluateScript s '
      var ps = panels();
      for (var i = 0; i < ps.length; i++) {
        ps[i].location = "bottom";
        ps[i].height = 45;
        var ws = ps[i].widgets("org.kde.plasma.icontasks");
        for (var j = 0; j < ws.length; j++) {
          ws[j].currentConfigGroup = ["General"];
          ws[j].writeConfig("launchers", ["applications:snapguard.desktop", "applications:firefox.desktop", "applications:org.gnome.Software.desktop", "applications:org.kde.konsole.desktop"]);
        }
      }' && touch "$marker"
  '';
  xfceLook = pkgs.writeShellScriptBin "snapos-xfce-look" ''
    dir="''${XDG_CONFIG_HOME:-$HOME/.config}/snapos"
    mkdir -p "$dir"
    marker="$dir/xfce-look-done"
    [ -e "$marker" ] && exit 0
    exec >> "$dir/xfce-look.log" 2>&1
    q=${pkgs.xfconf}/bin/xfconf-query
    # the desktop must be up; the wallpaper is set per monitor and workspace
    for i in $(seq 1 60); do
      ${pkgs.procps}/bin/pgrep -x xfdesktop >/dev/null && break
      sleep 2
    done
    sleep 3
    $q -c xsettings -p /Net/ThemeName -n -t string -s ${gtkTheme}
    $q -c xsettings -p /Net/IconThemeName -n -t string -s ${iconName}
    $q -c xfwm4 -p /general/theme -n -t string -s ${gtkTheme}
    ok=0
    monitors=$(${pkgs.xorg.xrandr}/bin/xrandr --listmonitors 2>/dev/null | awk 'NR > 1 { print $NF }')
    echo "monitors: $monitors"
    for m in $monitors; do
      for w in 0 1 2 3; do
        b="/backdrop/screen0/monitor$m/workspace$w"
        $q -c xfce4-desktop -p "$b/last-image" -n -t string -s ${wallpaper} && ok=1
        $q -c xfce4-desktop -p "$b/image-style" -n -t int -s 5 || true
      done
    done
    $q -c xfce4-desktop -l -v
    [ "$ok" = 1 ] && touch "$marker"
  '';
  autostart = name: exec: ''
    [Desktop Entry]
    Type=Application
    Name=${name}
    Exec=${exec}
    Terminal=false
    X-GNOME-Autostart-enabled=true
  '';
in {
  options.snapos.desktop = mkOption {
    type = types.enum [ "budgie" "plasma" "xfce" "hyprland" ];
    default = "budgie";
    description = "The desktop: Budgie (the default), KDE Plasma, Xfce or Hyprland. Chosen in the installer; change it in local.nix and run snapos rebuild.";
  };

  config = mkMerge [
    {
      services.xserver.enable = true;
      services.xserver.displayManager.lightdm.enable = true;
      services.desktopManager.gnome.enable = mkForce false;
      services.desktopManager.budgie.enable = desk == "budgie";
      services.desktopManager.plasma6.enable = desk == "plasma";
      services.xserver.desktopManager.xfce.enable = desk == "xfce";
      programs.hyprland = { enable = desk == "hyprland"; xwayland.enable = true; };

      services.displayManager.defaultSession = {
        budgie = "budgie-desktop";
        plasma = "plasmax11";
        xfce = "xfce";
        hyprland = "snapos-hyprland";
      }.${desk};
    }

    (mkIf (desk == "budgie") {
      # The dock: 45 pixels high, with the defender, the browser, the programs
      # store and the terminal pinned. (NixOS pins a media player by default.)
      services.desktopManager.budgie.extraGSettingsOverrides = ''
        [com.solus-project.icon-tasklist:Budgie]
        pinned-launchers=["snapguard.desktop", "firefox.desktop", "org.gnome.Software.desktop", "org.gnome.Terminal.desktop"]

        [com.solus-project.budgie-panel.panel:Budgie]
        size=45
      '';
      environment.budgie.excludePackages = [
        (pkgs.runCommand "nixos-background-info" { } "mkdir -p $out")
      ];
      programs.dconf.profiles.user.databases = [
        { settings."com/solus-project/budgie-panel".dark-theme = !light; }
      ];
    })

    (mkIf (desk == "plasma") {
      environment.etc."xdg/kdeglobals".text = ''
        [General]
        ColorScheme=${if light then "BreezeLight" else "BreezeDark"}
        AccentColor=226,42,28

        [Icons]
        Theme=${iconName}

        [KDE]
        LookAndFeelPackage=${if light then "org.kde.breeze.desktop" else "org.kde.breezedark.desktop"}
      '';
      environment.etc."xdg/autostart/snapos-plasma-look.desktop".text = autostart "SnapOS look" "${plasmaLook}/bin/snapos-plasma-look";
      environment.systemPackages = [ pkgs.kdePackages.kate pkgs.kdePackages.dolphin pkgs.kdePackages.konsole ];
    })

    (mkIf (desk == "xfce") {
      environment.etc."xdg/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml".text = ''
        <?xml version="1.0" encoding="UTF-8"?>
        <channel name="xsettings" version="1.0">
          <property name="Net" type="empty">
            <property name="ThemeName" type="string" value="${gtkTheme}"/>
            <property name="IconThemeName" type="string" value="${iconName}"/>
          </property>
          <property name="Gtk" type="empty">
            <property name="CursorThemeName" type="string" value="Adwaita"/>
          </property>
        </channel>
      '';
      environment.etc."xdg/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml".text = ''
        <?xml version="1.0" encoding="UTF-8"?>
        <channel name="xfwm4" version="1.0">
          <property name="general" type="empty">
            <property name="theme" type="string" value="${gtkTheme}"/>
          </property>
        </channel>
      '';
      # The panel the first time a user logs in: one bar at the bottom, 45
      # pixels, with the menu, the SnapOS programs, the open windows, the
      # tray and the clock (p=12 is the bottom edge).
      environment.etc."xdg/xfce4/panel/default.xml".text = ''
        <?xml version="1.0" encoding="UTF-8"?>
        <channel name="xfce4-panel" version="1.0">
          <property name="configver" type="int" value="2"/>
          <property name="panels" type="array">
            <value type="int" value="1"/>
            <property name="dark-mode" type="bool" value="${if light then "false" else "true"}"/>
            <property name="panel-1" type="empty">
              <property name="position" type="string" value="p=12;x=0;y=0"/>
              <property name="length" type="uint" value="100"/>
              <property name="position-locked" type="bool" value="true"/>
              <property name="size" type="uint" value="45"/>
              <property name="icon-size" type="uint" value="0"/>
              <property name="plugin-ids" type="array">
                <value type="int" value="1"/>
                <value type="int" value="2"/>
                <value type="int" value="3"/>
                <value type="int" value="4"/>
                <value type="int" value="5"/>
                <value type="int" value="6"/>
                <value type="int" value="7"/>
                <value type="int" value="8"/>
                <value type="int" value="9"/>
                <value type="int" value="10"/>
                <value type="int" value="11"/>
              </property>
            </property>
          </property>
          <property name="plugins" type="empty">
            <property name="plugin-1" type="string" value="whiskermenu"/>
            <property name="plugin-2" type="string" value="launcher">
              <property name="items" type="array"><value type="string" value="snapguard.desktop"/></property>
            </property>
            <property name="plugin-3" type="string" value="launcher">
              <property name="items" type="array"><value type="string" value="firefox.desktop"/></property>
            </property>
            <property name="plugin-4" type="string" value="launcher">
              <property name="items" type="array"><value type="string" value="org.gnome.Software.desktop"/></property>
            </property>
            <property name="plugin-5" type="string" value="launcher">
              <property name="items" type="array"><value type="string" value="xfce4-terminal.desktop"/></property>
            </property>
            <property name="plugin-6" type="string" value="tasklist">
              <property name="show-labels" type="bool" value="false"/>
              <property name="grouping" type="bool" value="true"/>
            </property>
            <property name="plugin-7" type="string" value="separator">
              <property name="expand" type="bool" value="true"/>
              <property name="style" type="uint" value="0"/>
            </property>
            <property name="plugin-8" type="string" value="systray">
              <property name="square-icons" type="bool" value="true"/>
            </property>
            <property name="plugin-9" type="string" value="pulseaudio"/>
            <property name="plugin-10" type="string" value="clock">
              <property name="digital-layout" type="uint" value="3"/>
              <property name="digital-time-format" type="string" value="%H:%M"/>
            </property>
            <property name="plugin-11" type="string" value="actions"/>
          </property>
        </channel>
      '';
      environment.etc."xdg/autostart/snapos-xfce-look.desktop".text = autostart "SnapOS look" "${xfceLook}/bin/snapos-xfce-look";
      environment.systemPackages = [ pkgs.xfce4-whiskermenu-plugin ];
    })

    (mkIf (desk == "hyprland") {
      environment.etc."snapos/hypr/hyprland.conf".source = hyprlandConf;
      environment.etc."snapos/hypr/hyprpaper.conf".source = hyprpaperConf;
      environment.etc."snapos/hypr/hyprlock.conf".source = hyprlockConf;
      environment.etc."xdg/waybar/config".source = waybarConfig;
      environment.etc."xdg/waybar/style.css".source = waybarStyle;
      environment.etc."xdg/wofi/config".source = wofiConfig;
      environment.etc."xdg/wofi/style.css".source = wofiStyle;
      environment.etc."xdg/mako/config".source = makoConfig;
      services.displayManager.sessionPackages = [ hyprlandSessionPackage ];
      fonts.packages = [ pkgs.nerd-fonts.symbols-only ];
      environment.systemPackages = with pkgs; [
        waybar wofi mako hyprpaper hyprlock kitty networkmanagerapplet pavucontrol
        brightnessctl grim slurp wl-clipboard thunar
      ];
      # Hyprland is Wayland-only; Firefox and GTK programs run natively on it.
      environment.sessionVariables.NIXOS_OZONE_WL = "1";
    })
  ];
}
