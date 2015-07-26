NixOS on a Surface Pro 3
========================

I purchased a Surface Pro 3 in July of 2015, looking for an ultrabook sized machine that had some amount of Linux support.  There are are a few people running Ubuntu/Arch but no recent mentions of this hardware on Nixos.

# What works

In kernel 4.1, most things work as you'd expect with a bit of patching. 4.2
reported some regressions in volume buttons and some other hardware.

## Type Cover

MS introduced a new type cover that has a new USB id. If you happen to have a
newer type cover, it won't work unless you apply the multitouch patch. Loading
hid-multitouch in init lets the typecover work in gummiboot and during kernel
load, so you can type in a passphrase for your encrypted disk.

## Touch Screen

It works with basic evdev support except for the second pen button. Wacom
support is supposed to fix that, but when I enabled it, it just caused the
cursor to jump around when pressed and conflicted with the synaptics
driver on the touch pad. It's not of great interest, so I let it be for now.

## Sound

Yep.

## Wireless

Yep.

## Cameras

With the included patch, both worked in a Hangout in Chrome.

## Bluetooth

Seems to work, I haven't paired any devices but hcitool scans/etc show activity.

## Hardware buttons

Volume and the windows key work. The power button initiates a shutdown
rather than a suspend.

## Suspend

Suspend to ram works. I haven't had a successful resume from hibernation.

# Install

You'll need:
* USB keyboard
* USB thumbdrive and hub or a MicroSD card with the NixOS media on it.
  If you plan on running NixOS from the SD card (it works!), you'll definitely
  need a thumb drive.
* USB ethernet dongle (optional, but allows you to skip wireless setup)

Turn off secureboot by mashing escape as you press the power button and it will
drop you into the firmware setup screen. Disable the secureboot and (optionally)
change the boot order to Usb -> SSD. If you don't do that, in order to boot USB,
you'll need to hold the volume down button while hitting the power button,
releasing when the 'Surface' text appears.

The install itself is typical. If you are installing to the hard drive, shrink
Windows. If installing to the SD card, partition as normal in gdisk. If you
leave windows, the EFI partition will be on /dev/sda2 (mount as /mnt/boot)

After you get to the "nixos-generate-config" step, copy surface.nix and the
patches to /mnt/etc/nixos and include surface.nix in the confguration.nix
imports.

nixos-install will take a while as it will need to compile a new kernel. When
it's over, reboot.

All done.

