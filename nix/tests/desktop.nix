{ pkgs }:

# One VM per desktop: the system boots, a user is logged in automatically,
# the desktop's own processes are up, the SnapOS look and programs are in
# place, and the update guard approves a system once someone has logged in.
let
  mk = { name, desktop, appearance ? "dark", processes, extra ? "", vm ? { }, autoLogin ? true, login ? "" }:
    pkgs.testers.runNixOSTest {
      name = "snapos-${name}";

      nodes.machine = { lib, ... }: {
        imports = [ ../../configuration.nix ];

        networking.hostName = lib.mkForce "machine";
        snapos.desktop = desktop;
        snapos.appearance = appearance;

        virtualisation.memorySize = 3072;
        virtualisation.cores = 2;
        virtualisation.resolution = { x = 1280; y = 800; };

        users.users.tester = {
          isNormalUser = true;
          password = "tester";
          extraGroups = [ "wheel" ];
        };
        services.displayManager.autoLogin = {
          enable = autoLogin;
          user = "tester";
        };
      } // vm;

      testScript = ''
        machine.start()
        machine.wait_for_unit("multi-user.target")
        machine.sleep(30)
        machine.execute("cat /proc/cmdline > /tmp/cmdline.txt; uname -r > /tmp/kernel.txt; ps -eo user,comm,args > /tmp/ps.txt")
        machine.execute("systemctl status display-manager --no-pager > /tmp/dm-status.txt 2>&1")
        machine.execute("journalctl -b --no-pager > /tmp/journal.txt")
        machine.execute("tar czf /tmp/xlogs.tgz /var/log/lightdm /var/log/X.0.log /home/*/.xsession-errors /home/*/.config/snapos/*.log 2>/dev/null; true")
        for f in ["cmdline.txt", "kernel.txt", "ps.txt", "dm-status.txt", "journal.txt", "xlogs.tgz"]:
            machine.copy_from_vm("/tmp/" + f)
        machine.screenshot("01-state")
        machine.wait_for_unit("display-manager.service")
        ${login}
        for p in ${builtins.toJSON processes}:
            machine.wait_until_succeeds("pgrep -u tester -f " + p, timeout=300)
        machine.sleep(30)
        machine.screenshot("02-desktop")
        machine.execute("(echo 'variant: ${name}'; free -m; echo; echo running services: $(systemctl list-units --type=service --state=running --no-legend | wc -l); echo processes: $(ps -e | wc -l)) > /tmp/metrics.txt")
        machine.copy_from_vm("/tmp/metrics.txt")
        machine.succeed("grep -q ${appearance} /etc/snapos/appearance")
        machine.succeed("test -f /etc/xdg/autostart/snaphelper.desktop")
        machine.succeed("test -s /run/current-system/sw/share/snapos/helper/snappy-declares.gif")
        machine.succeed("snapos help")
        machine.succeed("snapguard status")
        machine.succeed("grep -q 'PRETTY_NAME=\"SnapOS ' /etc/os-release")
        ${extra}
        machine.execute("tar czf /tmp/xlogs.tgz /var/log/lightdm /var/log/X.0.log /home/*/.xsession-errors /home/*/.config/snapos/*.log /tmp/*.log /tmp/hypr-*.txt 2>/dev/null; true")
        machine.copy_from_vm("/tmp/xlogs.tgz")

        # The update guard: a new system is approved once a user has logged in
        # (tester is logged in by autologin), and a system that never got
        # approved is undone at the next boot.
        machine.succeed("systemctl is-enabled snapos-update-guard snapos-update-approve")
        machine.succeed("printf 'previous=1\\nattempts=0\\nname=test-release\\n' > /var/lib/snapos/update/update-pending")
        machine.succeed("systemctl restart snapos-update-guard")
        machine.succeed("grep -q '^attempts=1' /var/lib/snapos/update/update-pending")
        machine.succeed("systemctl restart snapos-update-approve")
        machine.wait_until_succeeds("test ! -e /var/lib/snapos/update/update-pending", timeout=120)
        machine.succeed("printf 'previous=1\\nattempts=1\\nname=test-release\\n' > /var/lib/snapos/update/update-pending")
        machine.succeed("SNAPOS_GUARD_NO_REBOOT=1 snapos guard boot")
        machine.succeed("test ! -e /var/lib/snapos/update/update-pending")
        machine.succeed("grep -q test-release /var/lib/snapos/update/update-rolled-back")
      '';
    };

  gsettings = "sudo -u tester env DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus gsettings get";

  # The VM has no internet, so ClamAV gets a tiny signature database written by
  # hand. The point is to prove the wiring: clamd, its socket, and SnapGuard
  # reading a private file of a normal user.
  antivirus = pkgs.testers.runNixOSTest {
    name = "snapos-antivirus";

    nodes.machine = { lib, ... }: {
      imports = [ ../../configuration.nix ];

      networking.hostName = lib.mkForce "machine";

      virtualisation.memorySize = 3072;
      virtualisation.cores = 2;

      users.users.tester = {
        isNormalUser = true;
        password = "tester";
      };
    };

    testScript = ''
      machine.start()
      machine.wait_for_unit("multi-user.target")

      machine.succeed("echo harmless > /tmp/fake.bin && echo clean > /tmp/clean.txt && chmod 644 /tmp/fake.bin /tmp/clean.txt")
      machine.succeed("mkdir -p /var/lib/clamav")
      machine.succeed("echo \"$(md5sum /tmp/fake.bin | cut -d' ' -f1):$(stat -c %s /tmp/fake.bin):SnapOS.Test.Fake-1\" > /var/lib/clamav/test.hdb")
      machine.succeed("chown -R clamav:clamav /var/lib/clamav")
      home = machine.succeed("su tester -c 'echo $HOME'").strip()
      private = home + "/private"
      machine.succeed("install -d -m 700 -o tester " + private + " && cp /tmp/fake.bin " + private + "/ && chown tester " + private + "/fake.bin")

      machine.succeed("systemctl restart clamav-daemon")
      machine.wait_until_succeeds("test -S /run/clamav/clamd.ctl", timeout=180)
      machine.execute("systemctl status clamav-daemon clamav-freshclam --no-pager > /tmp/clam-units.txt 2>&1; journalctl -u clamav-daemon --no-pager > /tmp/clam-journal.txt 2>&1")

      # 1. through the daemon, as a normal user, on a file only that user can read
      status, out = machine.execute("su tester -c 'snapguard status'")
      print(out)
      assert "ACTIVE" in out, out
      assert "running" in out, out
      status, out = machine.execute("su tester -c 'snapguard scan " + private + "/fake.bin'")
      print(out)
      assert status == 1, (status, out)
      assert "SnapOS.Test.Fake-1" in out, out
      status, out = machine.execute("su tester -c 'snapguard scan /tmp/clean.txt'")
      print(out)
      assert status == 0, (status, out)

      # 2. daemon down: SnapGuard must fall back to the stand-alone scanner
      machine.succeed("systemctl stop clamav-daemon")
      status, out = machine.execute("su tester -c 'snapguard scan " + private + "/fake.bin'")
      print(out)
      assert status == 1, (status, out)
      assert "SnapOS.Test.Fake-1" in out, out
    '';
  };
in
{
  desktop = mk {
    name = "desktop"; desktop = "budgie";
    processes = [ "'labwc|budgie-wm'" "'budgie-panel|budgie-desktop'" ];
    extra = ''
      machine.succeed("${gsettings} org.gnome.desktop.peripherals.touchpad disable-while-typing | grep -q false")
      machine.succeed("${gsettings} org.gnome.desktop.interface gtk-theme | grep -q Colloid-Red-Dark")
      machine.succeed("${gsettings} org.gnome.desktop.interface color-scheme | grep -q prefer-dark")
    '';
  };
  plasma = mk {
    name = "plasma"; desktop = "plasma";
    processes = [ "plasmashell" "kwin_x11" ];
    extra = ''
      machine.succeed("grep -q 'ColorScheme=BreezeDark' /etc/xdg/kdeglobals")
      machine.succeed("grep -q 'Theme=Papirus-Dark' /etc/xdg/kdeglobals")
      # the first-login script applied the SnapOS wallpaper and look
      machine.wait_until_succeeds("su tester -c 'test -e ~/.config/snapos/plasma-look-done'", timeout=240)
      machine.succeed("su tester -c 'grep -rq snapos-dark.jpeg ~/.config/plasma-org.kde.plasma.desktop-appletsrc'")
      machine.succeed("su tester -c 'grep -q applications:snapguard.desktop ~/.config/plasma-org.kde.plasma.desktop-appletsrc'")
    '';
  };
  xfce = let
    xq = "su tester -c 'DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus DISPLAY=:0 xfconf-query";
  in mk {
    name = "xfce"; desktop = "xfce"; appearance = "light";
    processes = [ "xfce4-panel" "xfwm4" "xfdesktop" ];
    extra = ''
      machine.succeed("grep -q 'SnapOS-Light' /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml")
      machine.wait_until_succeeds("su tester -c 'test -e ~/.config/snapos/xfce-look-done'", timeout=240)
      machine.succeed("${xq} -c xfce4-desktop -l -v | grep -q snapos-light.jpeg'")
      machine.succeed("${xq} -c xsettings -p /Net/ThemeName | grep -q SnapOS-Light'")
      machine.succeed("${xq} -c xfce4-panel -p /panels/panel-1/position | grep -q p=12'")
      machine.succeed("${xq} -c xfce4-panel -p /plugins/plugin-1 | grep -q whiskermenu'")
    '';
  };
  # The login screen: no automatic login, the greeter is photographed, then
  # the password is typed as a person would.
  login = mk {
    name = "login"; desktop = "budgie"; autoLogin = false;
    processes = [ "budgie-panel" ];
    login = ''
      machine.wait_until_succeeds("pgrep -f slick-greeter", timeout=300)
      machine.sleep(20)
      machine.screenshot("01-login")
      machine.send_chars("tester\n")
    '';
  };
  hyprland = mk {
    name = "hyprland"; desktop = "hyprland";
    processes = [ "Hyprland" "waybar" "mako" ];
    vm = {
      # no GPU in the VM: a virtio display with software rendering
      virtualisation.qemu.options = [ "-vga none -device virtio-gpu-pci" ];
      environment.variables.WLR_RENDERER_ALLOW_SOFTWARE = "1";
      environment.variables.AQ_NO_ATOMIC = "1";
    };
    extra = ''
      machine.succeed("test -f /etc/snapos/hypr/hyprland.conf")
      machine.succeed("grep -q 'snapguard-watch' /etc/snapos/hypr/hyprland.conf")
      machine.wait_until_succeeds("su tester -c 'test -f ~/.config/hypr/hyprland.conf'", timeout=120)
      # what Hyprland shows: layers (the bar), clients, and the bar and
      # wallpaper programs run again with their output kept
      hy = "su tester -c 'export XDG_RUNTIME_DIR=/run/user/$(id -u); export HYPRLAND_INSTANCE_SIGNATURE=$(ls $XDG_RUNTIME_DIR/hypr | head -1); export WAYLAND_DISPLAY=$(ls $XDG_RUNTIME_DIR | grep -E ^wayland-[0-9]+$ | head -1); "
      machine.execute(hy + "hyprctl layers > /tmp/hypr-layers.txt; hyprctl clients > /tmp/hypr-clients.txt; hyprctl monitors > /tmp/hypr-monitors.txt; hyprctl hyprpaper listloaded > /tmp/hypr-paper.txt 2>&1'")
      machine.execute(hy + "grim /tmp/grim.png'")
      machine.copy_from_vm("/tmp/grim.png")
      machine.execute(hy + "pkill waybar; pkill hyprpaper; (timeout 25 waybar -l debug > /tmp/waybar.log 2>&1 &); (timeout 25 hyprpaper > /tmp/hyprpaper.log 2>&1 &)'")
      machine.sleep(15)
      machine.screenshot("03-restarted")
      # the same bar with the smallest possible configuration, at the top and at the bottom
      machine.execute("printf '{ \"layer\": \"top\", \"position\": \"top\", \"height\": 40, \"modules-center\": [\"clock\"] }' > /tmp/top.json; printf '{ \"layer\": \"top\", \"position\": \"bottom\", \"height\": 40, \"modules-center\": [\"clock\"] }' > /tmp/bottom.json; printf 'window#waybar { background: #e22a1c; color: #ffffff; }' > /tmp/bar.css; chmod 644 /tmp/top.json /tmp/bottom.json /tmp/bar.css")
      machine.execute(hy + "pkill waybar; (timeout 20 waybar -l debug -c /tmp/top.json -s /tmp/bar.css > /tmp/waybar-top.log 2>&1 &)'")
      machine.sleep(10)
      machine.screenshot("04-bar-top")
      machine.execute(hy + "pkill waybar; (timeout 20 waybar -l debug -c /tmp/bottom.json -s /tmp/bar.css > /tmp/waybar-bottom.log 2>&1 &)'")
      machine.sleep(10)
      machine.screenshot("05-bar-bottom")
      machine.execute(hy + "hyprctl layers > /tmp/hypr-layers2.txt'")
      machine.succeed("grep -q waybar /tmp/hypr-layers.txt")
    '';
  };
  inherit antivirus;
}
