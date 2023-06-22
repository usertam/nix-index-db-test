{ writeTextDir
, system, channel, version
, rev, shortRev, lastModifiedDate
}:

writeTextDir "README.md" ''
  # nix-index-db
  ### ${system} / ${channel} @ ${version}
  - Nixpkgs: `${channel}` @ [`${shortRev}`](https://github.com/NixOS/nixpkgs/commit/${rev})
  - Platform: `${system}`
  - Date: `${builtins.substring 0 4 lastModifiedDate}-${builtins.substring 4 2 lastModifiedDate}-${builtins.substring 6 2 lastModifiedDate}`
''
