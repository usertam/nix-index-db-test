{ writeTextDir
, system, channel, version
, rev, shortRev, lastModifiedDate
}:

writeTextDir "README.md" ''
  # nix-index-db
  ### ${system}/${channel} @ ${version}
  - Nixpkgs: `${channel}`@[`${shortRev}`](https://github.com/NixOS/nixpkgs/commit/${rev})
  - Platform: `${system}`
  - Date: `${lastModifiedDate}`
''
