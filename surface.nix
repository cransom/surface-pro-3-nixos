{ config, pkgs, ... }:
{
#  services.xserver.wacom.enable = true;
#  environment.etc."X11/xorg.conf.d/40-ntrig.conf".text = ''
#    Section "InputClass"
#      Identifier "Wacom N-Trig class"
#      MatchProduct "NTRG0001:01"
#      MatchDevicePath "/dev/input/event*"
#      Driver "wacom"
#    EndSection
#  '';
  services.xserver.synaptics = {
    enable = true;
    twoFingerScroll = true;
    palmDetect = true;
    buttonsMap = [ 1 3 2 ];
    fingersMap = [ 1 3 2 ];
    minSpeed = "0.8";
    maxSpeed = "1.4";
  };
  boot.kernelModules = [ "hid-multitouch" ];
  boot.initrd.kernelModules = [ "hid-multitouch" ];
  boot.loader.grub.enable = false;
  boot.loader.gummiboot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  hardware.pulseaudio.enable = true;
  hardware.bluetooth.enable = true;

  #suspend if powerbutton his bumped, rather than shutdown.
  services.logind.extraConfig = ''
  HandlePowerKey=suspend
  '';
  powerManagement.enable = true;
  powerManagement.powerDownCommands = ''
      /run/current-system/sw/bin/date  > /tmp/powerdown
  '';
  #stay sleeping if the lid is closed.
  powerManagement.powerUpCommands = ''
      /run/current-system/sw/bin/date  > /tmp/powerup
      sleep 10
      if $(grep -q closed /proc/acpi/button/lid/LID0/state); then
        systemctl suspend
      fi
  '';

  powerManagement.cpuFreqGovernor = "powersave";
  boot.kernelPackages = pkgs.linuxPackages_4_1;
  nixpkgs.config.packageOverrides = pkgs: {
    linux_4_1 = pkgs.linux_4_1.override {
      kernelPatches = [
        { patch = ./Add-multitouch-support-for-Microsoft-Type-Cover-3.patch; name = "multitouch-type-cover-3"; extraConfig = ''
          I2C_DESIGNWARE_PLATFORM m
          X86_INTEL_LPSS y
        ''; }
        { patch = ./Add-Microsoft-Surface-Pro-3-button-support.patch; name = "sp3-buttons"; }
        { patch = ./Add-Microsoft-Surface-Pro-3-camera-support.patch; name = "surfacepro3-cameras"; }
      ];
    };
  };

  services.acpid.enable = true;
  services.acpid.lidEventCommands = ''
    LID_STATE=/proc/acpi/button/lid/LID0/state
    AC_STATE=$(/run/current-system/sw/bin/cat /sys/class/power_supply/AC0/online)
    if [ $(/run/current-system/sw/bin/awk '{print $2}' $LID_STATE) = 'closed' ]; then
        export DISPLAY=:0
        /home/cransom/Sync/bin/fuzzy_lock.sh
        if [ $AC_STATE = "0" ]; then
          /run/current-system/sw/bin/systemctl suspend
        fi
        /run/current-system/sw/bin/logger "lid closed, screen off"
      else
        /run/current-system/sw/bin/logger "lid opened"
    fi
  '';
#  services.acpid.powerEventCommands = ''
#    /run/current-system/sw/bin/systemctl suspend
#  '';
#  services.acpid.acEventCommands = ''
#    LID_STATE=/proc/acpi/button/lid/LID0/state
#    AC_STATE=$(/run/current-system/sw/bin/cat /sys/class/power_supply/AC0/online)
#    if [ $(/run/current-system/sw/bin/awk '{print $2}' $LID_STATE) = 'closed' ]; then
#      if [ $AC_STATE = '0' ]; then
#        /run/current-system/sw/bin/systemctl hibernate
#      fi
#    fi
#  '';
#
}
