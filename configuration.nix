{ config, pkgs, ... }:

{
  imports = 
    [
      ./hardware-configuration.nix
    ]

  # Explicit hardware settings
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  hardware.nvidia = {
    modesetting.enable = true;
    open = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelParams = 
    [
      "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
      "nvidia_drm.modeset=1"
    ];

  # Networking
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Brussels";
  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Enable the X11 Windowing system.
  # TODO: You can disable this if you're only using the Wayland session?
  services.xserver.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];

  # Configure keymap in X11.
  services.xserver.xkb = {
    layout = "us";
    variant = "";
    options = "ctrl:nocaps";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  security.rtkit.enable = true;
  #services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Define a user account. Don't forget to set a password with 'passwd'.
  users.users.davelens = {
    isNormalUser = true;
    description = "Dave Lens";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      firefox
      bitwarden
      discord
    ];
  };

  # Enable automatic login for the user.
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "davelens";

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  envirnoment.systemPackages = with pkgs; [
    wget
    neovim
    wezterm
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?

}
