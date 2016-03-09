{ config, pkgs, ... }:
rec {
  services.xserver.synaptics = {
    enable = true;
    twoFingerScroll = true;
    palmDetect = false;
    buttonsMap = [ 1 3 2 ];
    fingersMap = [ 1 3 2 ];
    minSpeed = "0.8";
    maxSpeed = "1.4";
    additionalOptions = ''
    MatchDevicePath "/dev/input/event*"
    Option "vendor" "045e"
    Option "product" "07e2"
    '';
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
    HandleLidSwitch=ignore
  '';

  powerManagement.enable = true;
  #powerManagement.powerUpCommands = "";
  #powerManagement.powerDwnCommands = "";
  powerManagement.cpuFreqGovernor = "powersave";

  boot.kernelPackages = pkgs.linuxPackages_4_4;
  nixpkgs.config.packageOverrides = pkgs: {
    linux_4_4 = pkgs.linux_4_4.override {
      kernelPatches = [
        { patch = ./multitouch.patch; name = "multitouch-type-cover";} 
        { patch = ./touchscreen_multitouch_fixes1.patch; name = "multitouch-fixes1";} 
        { patch = ./touchscreen_multitouch_fixes2.patch; name = "multitouch-fixes2";} 
        { patch = ./cam.patch; name = "surfacepro3-cameras"; }
      ];
      extraConfig = ''
        I2C_DESIGNWARE_PLATFORM m
        X86_INTEL_LPSS y
      '';
    };
  };

  systemd.timers.lidcheck = {
    partOf = [ "acpid.service"];
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnUnitActiveSec = "60";
      OnBootSec = "60";
    };
  };
  systemd.services.lidcheck = {
    environment = { DISPLAY = ":0"; };
    description = "ensure sleep when unpowered and lid closed";
    script = services.acpid.lidEventCommands;
  };

  services.acpid.enable = true;
  #on lid event, lock if the lid is closed and we have power;
  # if closed and no power, sleep

  services.acpid.lidEventCommands = ''
    export PATH=/run/current-system/sw/bin
    LID_STATE=$(awk '{ print $2 }' /proc/acpi/button/lid/LID0/state)
    AC_STATE=$(cat /sys/class/power_supply/AC0/online)
    export DISPLAY=':0'
    if [ $LID_STATE = 'closed' ]; then
      xset dpms force off
      xautolock -locknow
      systemctl suspend
      if [ $AC_STATE = '0' ]; then
        systemctl suspend
      fi
    fi

  '';

  services.acpid.acEventCommands = ''
    export PATH=/run/current-system/sw/bin
    AC_STATE=$(cat /sys/class/power_supply/AC0/online)
    if [ $AC_STATE = '0' ]; then
      iw dev wlp1s0 set power_save on
    else
      iw dev wlp1s0 set power_save off
    fi
  '';
}
