> [!NOTE]
> **This is the staging repository for SnapOS.** New features and fixes are developed and tested here first. When an update is verified it is carried over to [SnapOS](https://github.com/Juco7L7/SnapOS), the repository that ships the installer ISO.

<p align="center">
  <img src="docs/desktop.png" alt="The SnapOS desktop: red Snappy wallpaper, a terminal with fastfetch, and the SnapGuard window" width="720">
</p>

<h1 align="center">SnapOS</h1>

<p align="center">A bridge from Ubuntu-like systems to NixOS: the power of a declarative system, with plain commands.</p>

> [!CAUTION]
> **Flashing the ISO: use [balenaEtcher](https://etcher.balena.io).** Select the ISO, select your USB drive, click *Flash!* and wait for the validation to finish. Do not copy the file onto the drive by hand, and do not use "ISO mode" tools (in Rufus, choose *DD Image mode*). If the boot stops with `unable to read id index table`, the download or the USB drive is damaged: compare the SHA-256 of the file with the one on the release page, then download and flash again.

> [!WARNING]
> **Versions before V2.0 (V1 and V1.1) should not be used any more.** They run
> NixOS 24.11 with Linux 6.6.94, a base that stopped receiving security fixes
> on 30 June 2025, and their Debian layer ran install scripts with more power
> than they need. V2.0 and later run NixOS 26.05 with Linux 6.18 and update
> themselves. Install the latest release from the Releases page.

---

SnapOS is NixOS underneath and an everyday desktop on top. NixOS describes the
whole system in a file and can undo any change, but its commands and its
language are a wall for someone who comes from Ubuntu, Mint or Debian. SnapOS
keeps the habits you already have (`install`, `remove`, `search`, `update`)
under one command, `snapos`, and shows you the declarative way behind them, so
you can cross over to NixOS at your own pace.

It ships a defender (SnapGuard), a browser (SnapWeb), a guided installer, four
desktops in a dark or light look, real `.deb` support and updates that undo
themselves when they fail.

## The idea: you declare, you do not install

<p align="center">
  <img src="branding/snappy-declares.gif" alt="Snappy writes apps into configuration.nix with a pencil, then rebuilds the system" width="640">
</p>

On most systems you install things one by one and the computer slowly turns
into a pile of changes nobody remembers. SnapOS is **declarative**: one file,
`configuration.nix`, lists what the system is (its programs, services, look and
settings), and a **rebuild** makes the computer match the file.

Add a name to the list and rebuild: the program is there. Remove the name and
rebuild: it is gone, with nothing left behind. Every rebuild is kept as a
**generation**, so you can always go back to the system you had before.

You do not have to edit the file by hand to start. The `snapos` commands below
edit it and rebuild for you, and you can open it any time with `snapos config`
to see what they wrote.

## What you get

- **One file describes the system**, and plain commands edit it for you:
  `snapos add`, `snapos remove`, `snapos rebuild`.
- **Every change can be undone**: each rebuild is a generation you can go back
  to, from the terminal or from the boot menu.
- **Updates that undo themselves** when the new system does not start.
- **SnapGuard**, the defender, based on ClamAV, in real time. Threats go to
  quarantine and nothing is deleted without your approval.
- **SnapWeb**, the browser: official Firefox with a dark and red look.
- **Real `.deb` support**: open a `.deb` file and SnapOS scans it, then
  installs it in a Debian layer with everything it needs.
- **Software**: GNOME Software with Flatpak and Flathub.
- **Four desktops**: Budgie (the default), KDE Plasma, Xfce or Hyprland, all
  with the SnapOS look in dark or light.
- **A guided installer** in eleven steps, in English or Portuguese, for
  x86_64 PCs (BIOS and UEFI) and ARM64 computers (UEFI); it can also run
  without questions.
- **SnapHelper**, a short tour that opens the first time you log in.
- **Small C tools** for everything, in [`src/`](src/).

## Install

<p align="center">
  <img src="branding/snappy-install.gif" alt="Snappy walks through the eleven installer steps" width="640">
</p>

1. Download the ISO from the Releases page: `snapos-installer.iso` for
   x86_64 PCs, `snapos-installer-aarch64.iso` for ARM64 computers.
2. Write it to a USB drive with balenaEtcher.
3. Boot from the USB drive. The installer starts by itself.

The installer has eleven steps, in English or Portuguese: network, keyboard,
language, time zone, disk, account, desktop, look (dark or light), graphics, a
review, and the installation. The Wi-Fi network you choose is kept, so the
installed system connects by itself.

If SnapOS is already installed, the installer offers **Update SnapOS (keeps
your files)**.

**ARM64.** The ARM64 image is for computers that boot by UEFI (ARM laptops,
mini PCs and boards with a UEFI firmware). It is the same SnapOS. Boards that
need a vendor image instead of UEFI (most Raspberry Pi setups) are not covered.

**Installing without questions.** A USB stick (or a small image) labelled
`SNAPOS_ANSWERS` with a file `snapos-answers.env` answers everything, and the
installer runs on its own:

```
LANG=en
KEYMAP=us
LOCALE=en_US.UTF-8
TIMEZONE=UTC
DISK=sda
USERNAME=snap
PASSWORD=change-me
HOSTNAME=snapos
DESKTOP=budgie
LOOK=dark
GRAPHICS=auto
```

## Desktops

<p align="center">
  <img src="docs/desktops.gif" alt="The four SnapOS desktops, Budgie, KDE Plasma, Xfce and Hyprland, in the dark look" width="720">
</p>

The installer asks which desktop you want:

| Desktop | What it is |
| --- | --- |
| **Budgie** (default) | simple and light; a dock with the defender, browser, store and terminal |
| **KDE Plasma** | full-featured and highly configurable; the same programs pinned to the panel |
| **Xfce** | classic and very light; a bottom panel with the same programs |
| **Hyprland** | tiling and keyboard-driven, Wayland only: Super+Enter terminal, Super+D launcher, Super+Q close, Super+1..9 workspaces, Super+H minimized windows; a bottom bar and title bars with close, maximize and minimize come set up |

All four get the red icons, the SnapOS wallpaper, the same login screen,
SnapGuard, SnapHelper and the updater. To switch later, change
`snapos.desktop` in `/etc/snapos/local.nix` and run `snapos rebuild`.

## Dark or light

<p align="center">
  <img src="branding/snappy-appearance.gif" alt="Snappy next to a SnapOS desktop that switches between dark and light" width="640">
</p>

The installer asks whether you want a dark or a light desktop. The theme,
icons, wallpaper, login screen, the SnapGuard shield and SnapWeb all follow it.
To switch later, change `snapos.appearance` in `/etc/snapos/local.nix` and run
`snapos rebuild`.

## Coming from Ubuntu

<p align="center">
  <img src="branding/snappy-commands.gif" alt="Snappy lists the apt commands next to their snapos equivalents" width="640">
</p>

There is no `apt` on SnapOS. The same habits have these names:

| You used to type | On SnapOS | What happens |
| --- | --- | --- |
| `apt search vlc` | `snapos find vlc` | searches the programs SnapOS can install |
| `apt install vlc` | `snapos add vlc` | declares the program and rebuilds |
| `apt remove vlc` | `snapos remove vlc` | takes it out of the declaration and rebuilds |
| `apt list --installed` | `snapos list` | the programs this system declares |
| `apt autoremove`, `apt clean` | `snapos gc` | frees disk space |
| `apt upgrade` | `snapos update` | installs the latest SnapOS release and newer packages |
| installing something just to try it | `snapos shell vlc` | uses it without installing |
| a `.deb` file | `snap-deb FILE.deb` | scans it and installs it in the Debian layer |

`snapos help` prints this list. `snapos` asks for root through `sudo` on its
own when a command needs it.

## Installing programs

<p align="center">
  <img src="branding/snappy-programs.gif" alt="Snappy searches for a program, adds it, the system rebuilds and the program opens" width="640">
</p>

```bash
snapos find vlc        # look for it (the first search takes a minute)
snapos add vlc         # install: declared in configuration.nix, then a rebuild
snapos remove vlc      # uninstall
snapos list            # what is declared
```

`snapos add` checks that the name exists before it touches anything. What it
writes is the same list you can edit by hand:

```nix
environment.systemPackages = with pkgs; [
  curl
  git
  snapweb
  vlc
];
```

**Trying without installing.** `snapos shell python3` opens a shell that has
the program; type `exit` and it is gone. `snapos try cowsay hello` runs a
program once. Nothing is added to your system, and both use the same versions
an install would.

**Why not `nix-env -i`?** It looks like `apt install`, but what it installs is
outside the system description: rebuilds do not know it, updates skip it and it
keeps disk space alive. On SnapOS the shell stops `nix-env -i`, explains this
and points to `snapos add` and `snapos shell`.

Programs that are not in the list can also come from **Software** (GNOME
Software with Flatpak and Flathub) or from a **`.deb` file** (see below).

## Changing the system

```bash
snapos config                 # open configuration.nix in your editor
snapos diff                   # what would change, without applying anything
snapos rebuild                # apply the configuration now
snapos rebuild --next-boot    # apply it at the next start only
snapos rebuild --trace        # show the full error when a build fails
snapos log                    # the output of the last rebuild
```

`snapos rebuild` applies changes to the running system. For changes to the
kernel, drivers or the boot loader use `--next-boot`: the running system is
left alone and the new one starts after a restart, so a bad change cannot take
the screen away while you work.

When a rebuild fails the system is not changed. Nix error messages are short;
`--trace` shows where the error comes from.

Settings the installer chose (desktop, look, keyboard, user) live in
`/etc/snapos/local.nix`. The system lives in `/etc/snapos`; `/etc/nixos`
points there, so NixOS tools work too.

## Undoing and cleaning

<p align="center">
  <img src="branding/snappy-undo.gif" alt="Snappy shows three generations, goes back one with snapos rollback and removes the oldest with snapos gc" width="640">
</p>

```bash
snapos generations     # the systems you can go back to
snapos rollback        # go back to the system before the last rebuild
snapos gc              # free disk space: drop systems older than 14 days
snapos gc --all        # keep only the current system
```

Every generation is also an entry in the boot menu: if the desktop does not
come up, restart and pick an older one there.

Generations take disk space, which is the usual surprise for someone new to
NixOS. SnapOS removes generations older than 14 days every week on its own;
`snapos gc` does it now and says how much space it freed. After a rollback
your files in `/etc/snapos` still hold the change that was undone: fix it
before the next rebuild.

## Updates

<p align="center">
  <img src="branding/snappy-updates.gif" alt="Snappy walks through the four steps of snapos update and the automatic rollback" width="640">
</p>

At every login SnapOS looks for a newer release. If there is one, a window
shows its notes and an **Install now** button. Installing runs `snapos update`
in a terminal, in four steps:

1. **Checking**: the computer is x86_64 or aarch64, `/nix` has room, the
   release is not older than the installed one (`--force` overrides), and the
   release ships its source package with a checksum.
2. **Downloading**: the source package is fetched and its SHA-256 compared
   with the checksum the release carries; a mismatch stops everything.
3. **Keeping your files**: `configuration.nix`, `local.nix`, the hardware
   file, the graphics mode and your `.deb` files are carried over.
4. **Building the next system**: the new system is built and made the default
   for the *next* start only; what is running is not touched.

Then you restart. Until you do, the login window says the release is installed
and offers **Restart now**. The new system gets one try: it is approved the
moment a normal user logs in. If it never reaches the login screen, or nobody
manages to log in within ten minutes, SnapOS goes back to the previous
generation by itself on the next start and tells you at login.

**The desktop and the programs update too.** Between SnapOS releases the same
check looks for newer packages on the NixOS branch SnapOS is built from: the
desktop you chose (Budgie, Plasma, Xfce or Hyprland), the browser, the kernel
and everything else, with their security fixes. When the packages here are
more than a week old and newer ones exist, the login window offers **Package
updates**; `snapos update` installs them the same safe way, for the next start
and with the automatic way back. A later SnapOS release never brings older
packages than the ones you already have.

**One release for every computer.** An update does not download an image: it
downloads the release's source and builds the system for the computer it runs
on, so an x86_64 PC and an ARM64 computer update from the same release. On
ARM64 the system calls itself `SnapOS 2.4 ARM` (in `snapos version`,
`fastfetch` and `/etc/os-release`).

The check compares the version that is running with the latest release and
does not need the GitHub API. When GitHub cannot be reached the window says so
instead of claiming the system is up to date. `snapos update check` only asks;
`snapos version` shows what is running.

## Debian packages (.deb)

<p align="center">
  <img src="branding/snappy-deb.gif" alt="Snappy opens a .deb, SnapGuard scans it, and it becomes part of SnapOS" width="640">
</p>

Programs that only exist as a `.deb` work too. Double-click the file (or run
`snap-deb FILE.deb`) and this happens:

1. **SnapGuard scans the file.** A threat goes to quarantine and nothing is
   installed. A file that cannot be scanned is refused unless you insist.
2. **The file is declared**: copied to `/etc/snapos/debs/`. A newer version of
   the same package replaces the older one.
3. **The rebuild installs it in the Debian layer**, a small real Debian
   (Debian 13) in `/var/lib/snapdeb`. It is created the first time you add a
   `.deb`, from the official Debian archive with its signatures checked, and
   downloads about 300 MB once. Inside it, Debian's own `apt` installs the
   package and the libraries it needs.
4. **The program is exported**: its menu entry, icon and command appear on the
   desktop like any other. It runs inside the layer with your home folder,
   screen, sound and settings.

```bash
snap-deb list                   # declared .deb files and their state
snap-deb remove discord         # take one out (then: snapos rebuild)
snap-deb run discord            # start a program from the layer by hand
snap-deb shell                  # a shell inside the Debian layer
snap-deb status                 # the layer: Debian version, packages, tools
```

The layer runs programs, not services: a `.deb` that installs a system service
(a VPN, Docker, a driver) is refused with a message, because it would install
but never work; look for that software with `snapos find` instead. It is a
compatibility layer, not a sandbox: a program in it reads and writes your files
like a native one, which is why SnapGuard scans every `.deb` first. On an ARM64
computer the layer takes `arm64` packages.

## SnapGuard

<p align="center">
  <img src="branding/snappy-defends.gif" alt="Snappy contains a threat and moves it to quarantine" width="640">
</p>

SnapGuard combines ClamAV, a SnapOS hash list and a trust list. When a scan
finds a threat, the file is moved to quarantine and its execute bits are
removed. You then choose to **keep and trust** it or **delete** it; nothing is
deleted without your approval.

It works in real time: from the moment you log in, every file that lands in
`Downloads` is scanned as soon as it is complete, and a USB drive is scanned
when you plug it in. A threat is contained at once and a notification tells
you.

```bash
snapguard                       # the window: quick scan, folders, quarantine
snapguard scan ~/Downloads      # scan from the command line
snapguard status                # engine, database and real-time protection
snapguard list                  # what is in quarantine
snapguard restore NAME          # or: delete NAME, trust PATH
```

The virus database downloads on the first boot with internet. See
[docs/SECURITY.md](docs/SECURITY.md) for the design.

## Every command

| Command | Description |
| --- | --- |
| `snapos find NAME` | search for a program |
| `snapos add NAME` / `remove NAME` | install or uninstall (declares, then rebuilds) |
| `snapos list` | the programs this system declares |
| `snapos shell NAME` / `try NAME` | use a program without installing it |
| `snapos config` | open `configuration.nix` in your editor |
| `snapos diff` | what a rebuild would change |
| `snapos rebuild` | apply the configuration (`--next-boot`, `--trace`) |
| `snapos rollback` / `generations` | go back, or list what you can go back to |
| `snapos gc` | free disk space (`--all` keeps only the current system) |
| `snapos log` | the output of the last rebuild |
| `snapos update` / `update check` / `version` | SnapOS releases and package updates |
| `snapos doctor` | check graphics, boot, network and antivirus problems |
| `snap-deb FILE.deb` | scan a `.deb`, then add it (also what double-clicking one does) |
| `snap-deb list` / `remove NAME` / `run CMD` / `shell` / `status` | the Debian layer |
| `snapctl run PROGRAM` | run a program and draft it for the declaration |
| `snapctl save` / `discard` / `status` | keep or drop drafted programs |
| `snapguard`, `snapguard scan PATH`, `snapguard status` | the defender |
| `snapweb` | the web browser |
| `snaphelper` | the tour that opens at the first login |
| `snappy` / `snappy feed` / `snappy pet` | the mascot |
| `fastfetch` | system information |

## Learning NixOS from here

Each `snapos` command is a short name for a NixOS command. When you are ready
for the real ones, they work on SnapOS too:

| SnapOS | What it runs |
| --- | --- |
| `snapos rebuild` | `nixos-rebuild switch --flake path:/etc/snapos#snapos` |
| `snapos rebuild --next-boot` | `nixos-rebuild boot --flake ...` |
| `snapos rebuild --trace` | `nixos-rebuild switch --flake ... --show-trace` |
| `snapos diff` | `nixos-rebuild build`, then `nix store diff-closures` |
| `snapos rollback` | `nixos-rebuild switch --rollback` |
| `snapos generations` | `nixos-rebuild list-generations` |
| `snapos gc` | `nix-collect-garbage --delete-older-than 14d` |
| `snapos gc --all` | `nix-collect-garbage -d` |
| `snapos find NAME` | `nix search` |
| `snapos shell NAME` | `nix shell` |
| `snapos try NAME` | `nix run` |
| `snapos add NAME` | a line in `environment.systemPackages`, then a rebuild |

On ARM64 the system is `snapos-aarch64` instead of `snapos`. Options for
`configuration.nix` are listed at [search.nixos.org](https://search.nixos.org).

## Build it yourself

You need Nix with flakes enabled.

```bash
nix build .#iso             # the installer image of this machine's architecture
nix build .#toplevel        # the installed system
make all gui && make test   # the C tools and their tests
```

Apps that SnapOS ships in its own version live in [`custom-apps/`](custom-apps/).
Each folder there becomes a package automatically; SnapWeb is one of them.

CI builds both images, boots every desktop in a virtual machine in both looks
through the login screen, and on ARM64 installs SnapOS unattended in a virtual
machine and boots the result.

## Repository layout

| Path | Contents |
| --- | --- |
| `configuration.nix` | the system declaration and the program list |
| `flake.nix` | the systems and images for x86_64 and ARM64, the package set, checks |
| `nix/modules/` | desktops, theme, defender, hardware and defaults |
| `nix/iso.nix` | the installer image |
| `nix/installer/` | the installer |
| `nix/pkgs/` | SnapOS packages: tools, SnapGuard window, icons, wallpapers |
| `nix/tests/` | virtual machine tests |
| `custom-apps/` | apps SnapOS ships in its own version (SnapWeb) |
| `src/` | the C tools |
| `security/` | SnapGuard signature list, allowlist and the Debian archive keyring |
| `docs/` | the security design and pictures |
| `branding/` | logo, icons, wallpapers, animations, fastfetch configuration |
| `tests/` | tests for the C tools and the repository |
| `.github/workflows/` | ISO builds (x86_64, ARM64), desktop tests, SnapGuard and Debian layer tests |

## License

MIT, see [LICENSE](LICENSE).

---

SnapOS was created as the final project (TCC) of a 15-year-old student. The goal
is to give you total control of your system while shipping an OS with strong
built-in security, good performance, and a friendlier learning curve than Nix.

AI assisted (Sonnet 5, Fable 5.1)
