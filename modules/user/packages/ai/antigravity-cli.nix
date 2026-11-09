# Google Antigravity CLI coding agent.
{ config, pkgs, lib, inputs, ... }:

let
  cfg = config.userSettings.programs.antigravity-cli;

  # Read-only commands. Excluded on purpose: `cd` (use the bash tool's `workdir`, which takes an absolute path), plus `find`, `sed`, `awk`, `env` and `printenv`.
  readOnlyCommands = [
    "apropos"
    "arch"
    "b2sum"
    "base32"
    "base64"
    "basename"
    "blkid"
    "cat"
    "cksum"
    "cmp"
    "column"
    "comm"
    "cut"
    "date"
    "df"
    "diff"
    "dirname"
    "dmidecode"
    "du"
    "echo"
    "expr"
    "false"
    "file"
    "findmnt"
    "fmt"
    "fold"
    "free"
    "getconf"
    "getent"
    "getfacl"
    "grep"
    "groups"
    "head"
    "hostname"
    "iconv"
    "id"
    "info"
    "join"
    "jq"
    "locale"
    "logname"
    "ls"
    "lsblk"
    "lscpu"
    "lspci"
    "lsusb"
    "man"
    "md5sum"
    "mountpoint"
    "nl"
    "nm"
    "nproc"
    "numfmt"
    "objdump"
    "od"
    "paste"
    "pgrep"
    "printf"
    "ps"
    "pwd"
    "readelf"
    "readlink"
    "realpath"
    "rev"
    "rg"
    "seq"
    "sha1sum"
    "sha256sum"
    "sha512sum"
    "shuf"
    "sleep"
    "sort"
    "stat"
    "strings"
    "sum"
    "tac"
    "tail"
    "tr"
    "tree"
    "true"
    "tsort"
    "tty"
    "type"
    "uname"
    "unexpand"
    "uniq"
    "uptime"
    "users"
    "wc"
    "whatis"
    "which"
    "who"
    "whoami"
    "xxd"
  ];

  defaultPermissions = {
    allow =
      (map (cmd: "command(${cmd}*)") readOnlyCommands)
      ++ [
        "command(git status*)"
        "command(git diff*)"
        "command(git log*)"
        "command(git show*)"
        "command(git blame*)"
        "command(git describe*)"
        "command(git rev-parse*)"
        "command(git ls-files*)"
        "command(git ls-tree*)"
        "command(git shortlog*)"
        "command(git remote -v*)"
        "command(git config --get*)"
        "command(git tag --list*)"
        "command(git stash list*)"
        "command(git branch --list*)"
        "command(git branch -a*)"
        "command(git branch -r*)"
        "command(nix flake check*)"
        "command(nix flake metadata*)"
        "command(nix eval*)"
        "command(nix path-info*)"
        "command(nix search*)"
        "command(nix why-depends*)"
        "command(nix build* --dry-run*)"
        "command(systemctl status*)"
      ];
    ask = [
      "command(*)"
      "read_url(*)"
      "execute_url(*)"
    ];
    deny = [
      "command(git commit*)"
      "read_file(*.env)"
      "read_file(*.env.*)"
    ];
  };

  defaultSettings = {
    # New sessions start in plan mode (read-only analysis, no edits until you switch agent/mode).
    agentMode = "plan";

    # Trust current user's nixdots workspace by default
    trustedWorkspaces = [
      "/home/${config.userSettings.name}/nixdots"
    ];
  };

  defaultCommands = {
    commit = {
      description = "Draft a conventional commit message from the staged diff";
      prompt = ''
        Repository state (output included below):

        !{git status --short}
        !{git diff --staged}

        Recent style:

        !{git log --oneline -5}

        From the output above, draft ONE conventional commit message: `<type>(<scope>?): <short description>`.
        Types: feat, fix, docs, style, refactor, perf, test, chore. Keep it short, no trailing period,
        no body unless {{args}} asks for one.
        Reply with ONLY the message. Never run `git commit` or `git add`.
        {{args}}
      '';
    };

    commit-pt = {
      description = "Escreve uma mensagem de commit convencional a partir do staged diff";
      prompt = ''
        Estado do repositório (output incluído abaixo):

        !{git status --short}
        !{git diff --staged}

        Estilo recente:

        !{git log --oneline -5}

        A partir do output acima, escreve UMA mensagem conventional-commits: `<tipo>(<scope>?): <descrição curta em português europeu>`.
        Tipos (em inglês): feat, fix, docs, style, refactor, perf, test, chore. Curta, sem ponto final,
        sem corpo a menos que {{args}} peça um.
        Responde SÓ com a mensagem. Nunca executes `git commit` nem `git add`.
        {{args}}
      '';
    };
  };

  defaultSkills = {
    i-have-adhd = inputs.i-have-adhd + "/skills/i-have-adhd";
    frontend-design = inputs.anthropics-skills + "/skills/frontend-design";
  };

  finalGeminiContext = lib.concatStringsSep "\n\n" (lib.optional (cfg.context != "") cfg.context);

  defaultPackage =
    if inputs ? antigravity-nix && inputs.antigravity-nix ? packages && inputs.antigravity-nix.packages ? ${pkgs.system}
    then inputs.antigravity-nix.packages.${pkgs.system}.google-antigravity-cli
    else pkgs.antigravity-cli;

  normalizedCommands = lib.mapAttrs (name: cmd:
    if builtins.isAttrs cmd then cmd
    else {
      description = "Custom ${name} command";
      prompt = cmd;
    }
  ) cfg.commands;
in
{
  options.userSettings.programs.antigravity-cli = {
    enable = lib.mkEnableOption "Google Antigravity CLI";

    package = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      default = null;
      description = "Package to use for Antigravity CLI. Defaults to inputs.antigravity-nix or pkgs.antigravity-cli.";
    };

    defaultModel = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Default model for Antigravity CLI (exported as GEMINI_MODEL).";
    };

    mutableSettings = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to merge settings and MCP servers into writable files at activation.";
    };

    settings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Extra settings merged over the recommended antigravity-cli defaults (settings.json).";
    };

    permissions = lib.mkOption {
      type = lib.types.submodule {
        options = {
          allow = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Extra permissions to allow without prompting.";
          };
          ask = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Extra permissions to ask before executing.";
          };
          deny = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Extra permissions to deny.";
          };
        };
      };
      default = { };
      description = "Extra permissions merged with the defaults.";
    };

    context = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Global context for Antigravity CLI (~/.gemini/AGENTS.md / GEMINI.md).";
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Additional packages appended to the default CLI deps exposed to Antigravity CLI.";
    };

    commands = lib.mkOption {
      type = lib.types.attrsOf (lib.types.oneOf [
        (lib.types.submodule {
          options = {
            prompt = lib.mkOption {
              type = lib.types.str;
              description = "Prompt executed when the command is run.";
            };
            description = lib.mkOption {
              type = lib.types.str;
              description = "One-line description for the command.";
            };
          };
        })
        lib.types.lines
        lib.types.str
      ]);
      default = { };
      description = "Extra custom commands (/commit, /commit-pt, etc.).";
    };

    skills = lib.mkOption {
      type = lib.types.either (lib.types.attrsOf (lib.types.either lib.types.lines lib.types.path)) lib.types.path;
      default = { };
      description = "Extra skills merged over the defaults (i-have-adhd, frontend-design).";
    };

    mcpServers = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "MCP servers configuration written to ~/.gemini/config/mcp_config.json.";
    };


  };

  config = lib.mkIf cfg.enable {
    programs.antigravity-cli = {
      enable = true;
      package = if cfg.package != null then cfg.package else defaultPackage;
      mutableSettings = cfg.mutableSettings;
      defaultModel = cfg.defaultModel;
      settings = lib.recursiveUpdate defaultSettings cfg.settings;
      permissions = {
        allow = defaultPermissions.allow ++ (cfg.permissions.allow or [ ]);
        ask = defaultPermissions.ask ++ (cfg.permissions.ask or [ ]);
        deny = defaultPermissions.deny ++ (cfg.permissions.deny or [ ]);
      };
      commands = defaultCommands // normalizedCommands;
      skills =
        if builtins.isAttrs cfg.skills then
          lib.recursiveUpdate defaultSkills cfg.skills
        else
          cfg.skills;
      context = lib.optionalAttrs (finalGeminiContext != "") {
        GEMINI = finalGeminiContext;
      };

      mcpServers = cfg.mcpServers;
    };

    home.packages = [ pkgs.git ] ++ cfg.extraPackages;

    # Upstream plugin for Antigravity
    home.file.".gemini/config/plugins/i-have-adhd" = {
      source = inputs.i-have-adhd;
      recursive = true;
    };
  };
}
