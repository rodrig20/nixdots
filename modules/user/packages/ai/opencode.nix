# OpenCode AI coding agent.
{ config, pkgs, lib, ... }:

let
  cfg = config.userSettings.programs.opencode;

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
      bash = {
        "*" = lib.hm.dag.entryBefore [
          "git status*"
          "git diff*"
          "git log*"
          "git commit*"
          "nix flake check*"
          "nix build* --dry-run*"
        ] "ask";
        "git status*" = lib.hm.dag.entryAfter [ "*" ] "allow";
        "git diff*" = lib.hm.dag.entryAfter [ "*" ] "allow";
        "git log*" = lib.hm.dag.entryAfter [ "*" ] "allow";
        # /commit only drafts the message, never runs git commit.
        "git commit*" = lib.hm.dag.entryAfter [ "*" ] "deny";
        "nix flake check*" = lib.hm.dag.entryAfter [ "*" ] "allow";
        "nix build* --dry-run*" = lib.hm.dag.entryAfter [ "*" ] "allow";
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
in
{
  options.userSettings.programs.opencode = {
    enable = lib.mkEnableOption "OpenCode";

    useOllama = lib.mkEnableOption "Ollama (local) provider for OpenCode";

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
      type = lib.types.attrsOf lib.types.lines;
      default = { };
      description = "Extra commands merged over the default /commit and /commit-pt (opencode/commands/).";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.opencode = {
      enable = true;
      extraPackages = [ pkgs.git ] ++ cfg.extraPackages;
      settings = lib.recursiveUpdate defaultSettings cfg.settings;
      tui = cfg.tui;
      context = cfg.context;
      commands = lib.recursiveUpdate defaultCommands cfg.commands;
    };
  };
}
