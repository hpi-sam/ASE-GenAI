{}:

let
  hashes = import ./hashes.nix;
  # nixos-24.05
  ref = "2527da1ef492c495d5391f3bcf9c1dd9f4514e32";
  hash = "06cvqh2a6z9fccf6wkch60z6s5jxwvhayjr16kmqm2vdzwnra4sx";

  fetchCommit = fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/${ref}.tar.gz";
    sha256 = "${hash}";
  };
in

# Keep line 12 as it is! Only modify it by running update-default-nix.py. The updating script depends on the next line being as it is on line 12.
import fetchCommit { }
