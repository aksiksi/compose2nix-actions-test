{ ... }:

{
  name = "basic";
  nodes = {
    docker = { pkgs, ... }: {
      imports = [
        ./docker-compose.nix
      ];
      virtualisation.graphics = false;
      system.stateVersion = "23.05";
    };
    podman = { pkgs, ... }: {
      imports = [
        ./podman-compose.nix
      ];
      virtualisation.graphics = false;
      system.stateVersion = "23.05";
    };
  };
  skipLint = true;
  testScript = ''
    start_all()

    d = {"docker": docker, "podman": podman}
    for runtime, m in d.items():
      # Create required directories for Docker Compose volumes and bind mounts.
      m.execute("mkdir -p /mnt/media/Books")
      m.execute("mkdir -p /var/volumes/{jellyseerr,sabnzbd}")

      # Wait for root Compose service to come up.
      m.wait_for_unit(f"{runtime}-compose-myproject-root.target")

      # Wait for each container service.
      m.wait_for_unit(f"{runtime}-myproject-sabnzbd.service")
      m.wait_for_unit(f"{runtime}-jellyseerr.service")

      # Check container state.
      n = m.succeed(f"{runtime} ps --format '{{.ID}}: {{.Names}} - {{.State}}' | grep running | wc -l")
      print("Count: ", n)
  '';
}
