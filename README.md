# cryptostorm Windows client

This repository contains the Perl/Tkx source for the [cryptostorm](https://cryptostorm.is) Windows client.

The client is a small Windows GUI for OpenVPN. It lets users pick a cryptostorm
node, enter their token, choose connection/security options, and connect without
manually editing OpenVPN configs.

The public release is distributed as a Windows installer. The installer bundles
the helper binaries and data files the client needs, including OpenVPN, OpenSSL,
stunnel, Xray, plink, Tcl/Tkx files, images, certificates, keys, translations,
the server list, and TAP driver files.

It is intended to support Windows 7 32-bit through current 64-bit Windows
systems.

See https://cryptostorm.is/windows#widget for the download link and instructions.

-------------------------------------------------------------------------------

## What it does

- Connects to cryptostorm OpenVPN nodes from a simple Windows GUI.
- Supports the ML-DSA-87, Ed25519, Ed448, and secp521r1 TLS profiles.
- Uses current OpenVPN/OpenSSL builds for modern TLS, including hybrid
  post-quantum key exchanges.
- Supports direct OpenVPN, SOCKS proxying, SSH tunneling, stunnel HTTPS,
  and Xray/REALITY obfuscation.
- Handles TAP adapter detection and installation for older and newer Windows
  systems.
- Includes optional DNS leak protection, IPv6 blocking, ad-blocking DNS, a
  killswitch, and TunnelCrack protection options.
- Supports multiple UI languages through `lang.txt`.
- Checks for client updates and server-list updates after connecting.

This version currently uses OpenVPN's TAP driver. DCO and possibly WireGuard
support are planned for a later release.

-------------------------------------------------------------------------------

## Repository layout

- `client.pl`  
  Main client script. Loads state/config/languages/server list, builds the UI,
  handles connect/disconnect/shutdown, and coordinates the other modules.

- `CSConfig.pm`  
  Loads and saves client settings. Also imports older `config.ini` settings into
  the newer JSON config format.

- `Startup.pm`  
  Startup checks and setup: Administrator checks, OS detection, single-instance
  handling, Tk/Tkx setup, version checks, and first window creation.

- `MainWindow.pm`  
  Main UI window: token box, server selector, connect/options buttons, status
  text, progress bar, and log display.

- `OptionsWindow.pm`  
  Options dialog: startup behavior, protocol/tunnel choices, TLS cipher,
  DNS/IPv6/killswitch options, SSH/stunnel/Xray settings, and other advanced
  options.

- `ServerPicker.pm`  
  Server dropdown/list UI

- `LangPicker.pm`  
  Language dropdown UI

- `OpenVPN.pm`  
  Connection logic. Writes the runtime OpenVPN/stunnel/Xray configs, starts the
  selected helpers, launches OpenVPN, watches the log, and reports status/errors
  back to the UI.

- `TapManager.pm`  
  Installs, manages, and validates the TAP adapter used by OpenVPN.

- `PostConnect.pm`  
  Checks for client and node list updates after a successful connection.

- `TrayUI.pm`  
  System tray icon/menu handling.

- `lang.txt`  
  UI translation strings.

-------------------------------------------------------------------------------

## Helper build scripts

The `build*.sh` scripts are used to compile the bundled OpenSSL,
stunnel, OpenVPN, and Xray binaries for wider Windows compatibility. They were
used on an Arch Linux system, mostly because it already had the needed cross
compilers installed.

The general idea is:

- build OpenSSL for 32-bit Windows with MinGW;
- build stunnel against that OpenSSL, with the small Windows socket-pair patch
  used by this client (`stunnel.patch`);
- build OpenVPN against that same OpenSSL and the TAP headers;
- build Xray with a Win7-capable Go toolchain.

The binaries are built to avoid newer Windows runtime DLLs that would break
Windows 7 compatibility.

The SSH client used for tunneling/obfuscation is the 32-bit `plink.exe` from:  
https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html

-------------------------------------------------------------------------------
