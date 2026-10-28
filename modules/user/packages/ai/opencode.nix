# OpenCode AI coding agent.
{ config, pkgs, lib, inputs, ... }:

let
  cfg = config.userSettings.programs.opencode;

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

  # Rules match the whole command, so the trailing `*` is required.
  readOnlyRules = lib.listToAttrs (map
    (cmd: lib.nameValuePair "${cmd}*" (lib.hm.dag.entryAfter [ "*" ] "allow"))
    readOnlyCommands);

  defaultSettings = {
    # Nix manages the version, not opencode itself.
    autoupdate = false;

    share = "disabled";
    username = config.userSettings.name;

    # New sessions start in plan mode (read-only analysis, no edits until you switch agent).
    default_agent = "plan";

    # Local models via Ollama. Wired per-host via `useOllama`
    provider = lib.optionalAttrs cfg.useOllama {
      ollama = {
        npm = "@ai-sdk/openai-compatible";
        name = "Ollama (local)";
        options.baseURL = "http://localhost:11434/v1";
      };
    };

    snapshot = true;
    formatter = true;
    lsp = true;

    tool_output = {
      max_lines = 200;
      max_bytes = 8192;
    };

    compaction = {
      auto = true;
      tail_turns = 15;
    };

    permission = {
      read = {
        "*" = lib.hm.dag.entryBefore [ "*.env" "*.env.*" "*.env.example" ] "allow";
        "*.env" = lib.hm.dag.entryAfter [ "*" ] "deny";
        "*.env.*" = lib.hm.dag.entryAfter [ "*" ] "deny";
        "*.env.example" = lib.hm.dag.entryAfter [ "*.env" "*.env.*" ] "allow";
      };
      glob = "allow";
      grep = "allow";
      list = "allow";
      webfetch = "allow";
      websearch = "allow";
      edit = "ask";
      bash =
        {
          "*" = lib.hm.dag.entryBefore [
            "git status*"
            "git diff*"
            "git log*"
            "git show*"
            "git blame*"
            "git describe*"
            "git rev-parse*"
            "git ls-files*"
            "git ls-tree*"
            "git shortlog*"
            "git remote -v"
            "git config --get*"
            "git tag --list*"
            "git stash list*"
            "git branch --list*"
            "git branch -a"
            "git branch -r"
            "git commit*"
            "nix flake check*"
            "nix flake metadata*"
            "nix eval*"
            "nix path-info*"
            "nix search*"
            "nix why-depends*"
            "nix build* --dry-run*"
            "systemctl status*"
          ] "ask";
        }
        // readOnlyRules
        // {
          "git status*" = lib.hm.dag.entryAfter [ "*" ] "allow";
          "git diff*" = lib.hm.dag.entryAfter [ "*" ] "allow";
          "git log*" = lib.hm.dag.entryAfter [ "*" ] "allow";
          "git show*" = lib.hm.dag.entryAfter [ "*" ] "allow";
          "git blame*" = lib.hm.dag.entryAfter [ "*" ] "allow";
          "git describe*" = lib.hm.dag.entryAfter [ "*" ] "allow";
          "git rev-parse*" = lib.hm.dag.entryAfter [ "*" ] "allow";
          "git ls-files*" = lib.hm.dag.entryAfter [ "*" ] "allow";
          "git ls-tree*" = lib.hm.dag.entryAfter [ "*" ] "allow";
          "git shortlog*" = lib.hm.dag.entryAfter [ "*" ] "allow";
          "git remote -v" = lib.hm.dag.entryAfter [ "*" ] "allow";
          "git config --get*" = lib.hm.dag.entryAfter [ "*" ] "allow";
          "git tag --list*" = lib.hm.dag.entryAfter [ "*" ] "allow";
          "git stash list*" = lib.hm.dag.entryAfter [ "*" ] "allow";
          # Listing branches is read-only; `git branch -D` deletes and still falls through to "*" = ask.
          "git branch --list*" = lib.hm.dag.entryAfter [ "*" ] "allow";
          "git branch -a" = lib.hm.dag.entryAfter [ "*" ] "allow";
          "git branch -r" = lib.hm.dag.entryAfter [ "*" ] "allow";
          # /commit only drafts the message, never runs git commit.
          "git commit*" = lib.hm.dag.entryAfter [ "*" ] "deny";
          "nix flake check*" = lib.hm.dag.entryAfter [ "*" ] "allow";
          "nix flake metadata*" = lib.hm.dag.entryAfter [ "*" ] "allow";
          "nix eval*" = lib.hm.dag.entryAfter [ "*" ] "allow";
          "nix path-info*" = lib.hm.dag.entryAfter [ "*" ] "allow";
          "nix search*" = lib.hm.dag.entryAfter [ "*" ] "allow";
          "nix why-depends*" = lib.hm.dag.entryAfter [ "*" ] "allow";
          "nix build* --dry-run*" = lib.hm.dag.entryAfter [ "*" ] "allow";
          "systemctl status*" = lib.hm.dag.entryAfter [ "*" ] "allow";
        };
    };
  };

  defaultCommands = {
    commit = ''
      ---
      description: Draft a conventional commit message from the staged diff
      ---

      Inspect `git status` and `git diff --staged`, plus `git log --oneline -5` for this repo's recent style.
      Draft ONE conventional commit message: `<type>(<scope>?): <short description>`.
      Types: feat, fix, docs, style, refactor, perf, test, chore. Keep it short, no trailing period,
      no body unless $ARGUMENTS asks for one.
      Reply with ONLY the message. Never run `git commit` or `git add`.
      $ARGUMENTS
    '';

    commit-pt = ''
      ---
      description: Escreve uma mensagem de commit convencional a partir do staged diff
      ---

      Inspeciona `git status` e `git diff --staged`, mais `git log --oneline -5` para apanhar o estilo recente do repo.
      Escreve UMA mensagem conventional-commits: `<tipo>(<scope>?): <descrição curta em português europeu>`.
      Tipos (em inglês): feat, fix, docs, style, refactor, perf, test, chore. Curta, sem ponto final,
      sem corpo a menos que $ARGUMENTS peça um.
      Responde SÓ com a mensagem. Nunca executes `git commit` nem `git add`.
      $ARGUMENTS
    '';
  };

  # https://github.com/ayghri/i-have-adhd: ADHD-friendly output style.
  iHaveAdhdSrc = inputs.i-have-adhd;

  defaultSkills = {
    i-have-adhd = inputs.i-have-adhd + "/skills/i-have-adhd";
    # Official Anthropic skill, on-demand (model loads it for frontend work). No plugin/command/flag needed.
    frontend-design = inputs.anthropics-skills + "/skills/frontend-design";
  };

  defaultExtraCommands = {
    i-have-adhd = iHaveAdhdSrc + "/.opencode/command/i-have-adhd.md";
  };

  # Upstream OpenCode plugin (V1 1.18.29+ and V2): registers skill + /i-have-adhd command, powers always-on via flag file.
  defaultPlugins = [
    (iHaveAdhdSrc + "/.opencode/plugins/i-have-adhd.mjs")
  ];

  # OpenRouter key from agenix secret (decrypted at activation). Fallback to openrouterApiKey option.
  openrouterSecretKey = lib.optionalAttrs (
    config ? age && config.age ? secrets && builtins.hasAttr "openrouter-api-key" config.age.secrets
  ) {
    value = builtins.readFile config.age.secrets.openrouter-api-key.path;
  };
in
{
  options.userSettings.programs.opencode = {
    enable = lib.mkEnableOption "OpenCode";

    useOllama = lib.mkEnableOption "Ollama (local) provider for OpenCode";

    openrouterApiKey = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "OpenRouter API key. Falls back to agenix secret secrets/openrouter-api-key.age if set.";
    };

    cli = lib.mkOption {
      type = lib.types.attrs;
      default = { theme = { name = "stylix"; mode = "system"; }; };
      description = "CLI-specific config (OpenCode 2 cli.json): terminal client settings (theme, keybinds).";
    };

    settings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Extra settings merged over the recommended opencode defaults (opencode.json).";
    };

    tui = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "TUI-only config (tui.json). Theme is handled by Stylix, leave empty unless keybinds are needed.";
    };

    context = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Global context for OpenCode (AGENTS.md). Empty by default.";
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Additional packages appended to the default CLI deps exposed to OpenCode.";
    };

    commands = lib.mkOption {
      type = lib.types.either (lib.types.attrsOf (lib.types.oneOf [
        lib.types.lines
        lib.types.path
        lib.types.str
      ])) lib.types.path;
      default = { };
      description = "Extra commands merged over the defaults (/commit, /commit-pt, /i-have-adhd). Accepts inline content or a path to a command file.";
    };

    skills = lib.mkOption {
      type = lib.types.either (lib.types.attrsOf (lib.types.oneOf [
        lib.types.lines
        lib.types.path
        lib.types.str
      ])) lib.types.path;
      default = { };
      description = "Extra skills merged over the defaults (i-have-adhd, frontend-design). Accepts inline SKILL.md content or a path to a skill file/directory.";
    };

    iHaveAdhdAlwaysOn = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Inject the i-have-adhd ruleset on every turn via ~/.config/opencode/.i-have-adhd-always (requires the upstream plugin). Per-session opt-out still works with \"stop adhd mode\" / \"normal mode\". Set to false and rebuild to disable permanently.";
    };
  };

  config = lib.mkIf cfg.enable {
    age.secrets.openrouter-api-key = {
      file = ../../../../secrets/openrouter-api-key.age;
    };
    programs.opencode = {
      enable = true;
      extraPackages = [ pkgs.git ] ++ cfg.extraPackages;
      settings =
        (lib.recursiveUpdate defaultSettings cfg.settings)
        // {
          plugin = defaultPlugins ++ (cfg.settings.plugin or [ ]);
        }
        // lib.optionalAttrs (openrouterSecretKey ? null && openrouterSecretKey.value != null) {
          provider = {
            openrouter = {
              npm = "@ai-sdk/openai-compatible";
              name = "OpenRouter";
              options = {
                baseURL = "https://openrouter.ai/api/v1";
                apiKey = openrouterSecretKey.value or cfg.openrouterApiKey;
              };
            };
          };
        };
      cli = cfg.cli;
      tui = cfg.tui;
      context = cfg.context;
      commands =
        if builtins.isAttrs cfg.commands then
          lib.recursiveUpdate (defaultCommands // defaultExtraCommands) cfg.commands
        else
          cfg.commands;
      skills =
        if builtins.isAttrs cfg.skills then
          lib.recursiveUpdate defaultSkills cfg.skills
        else
          cfg.skills;
    };

    # Always-on flag read by the upstream plugin every turn. Presence = on; disable via `iHaveAdhdAlwaysOn = false` + rebuild.
    xdg.configFile."opencode/.i-have-adhd-always" = lib.mkIf cfg.iHaveAdhdAlwaysOn {
      text = "";
    };
  };
}
