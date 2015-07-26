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
  powerManagement.enable = true;
  hardware.bluetooth.enable = true;
  powerManagement.cpuFreqGovernor = "conservative";
  services.acpid.enable = true;
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

  services.acpid.lidEventCommands = ''
    LID_STATE=/proc/acpi/button/lid/LID0/state
    if [ $(/run/current-system/sw/bin/awk '{print $2}' $LID_STATE) = 'closed' ]; then
      systemctl suspend
    fi
  '';
  services.acpid.powerEventCommands = ''
    systemctl suspend
  '';

  hardware.pulseaudio.enable = true;
}
