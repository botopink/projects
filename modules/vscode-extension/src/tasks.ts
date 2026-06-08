import * as vscode from "vscode";
import { getBotopinkCliPath } from "./cli";
import { TargetManager } from "./target";

export const BOTOPINK_TASK_TYPE = "botopink";

/** CLI subcommands surfaced as tasks. */
export type BotopinkCommand = "check" | "build" | "test" | "format";

/** Shape of a `botopink` task in `tasks.json` / `taskDefinitions`. */
interface BotopinkTaskDefinition extends vscode.TaskDefinition {
  type: typeof BOTOPINK_TASK_TYPE;
  command: BotopinkCommand;
  /** Optional codegen target (build/test). Falls back to the active target. */
  target?: string;
  /** Optional `--filter <substr>` for `test`. */
  filter?: string;
}

/**
 * Provides VS Code tasks for the `botopink` CLI subcommands.
 *
 * The provider only knows the CLI's argument shape — no `.bp` semantics. The
 * active codegen target (from the status bar / `botopink.json`) is applied to
 * the commands that accept `--target`.
 */
export class BotopinkTaskProvider implements vscode.TaskProvider {
  static readonly problemMatcher = "$botopink";

  constructor(private readonly targets: TargetManager) {}

  async provideTasks(): Promise<vscode.Task[]> {
    const commands: BotopinkCommand[] = ["check", "build", "test", "format"];
    const tasks: vscode.Task[] = [];
    for (const command of commands) {
      const task = await this.buildTask({
        type: BOTOPINK_TASK_TYPE,
        command,
      });
      if (task) {
        tasks.push(task);
      }
    }
    return tasks;
  }

  async resolveTask(task: vscode.Task): Promise<vscode.Task | undefined> {
    const def = task.definition as BotopinkTaskDefinition;
    if (!def.command) {
      return undefined;
    }
    return this.buildTask(def, task.scope);
  }

  /** Builds a concrete shell-backed task for a definition. */
  async buildTask(
    def: BotopinkTaskDefinition,
    scope?: vscode.WorkspaceFolder | vscode.TaskScope,
  ): Promise<vscode.Task | undefined> {
    const cli = await getBotopinkCliPath();
    const args = this.argsFor(def);
    const execution = new vscode.ShellExecution(cli, args);
    const taskScope = scope ?? vscode.TaskScope.Workspace;
    const task = new vscode.Task(
      def,
      taskScope,
      this.label(def),
      BOTOPINK_TASK_TYPE,
      execution,
      def.command === "check" ? [BotopinkTaskProvider.problemMatcher] : [],
    );
    task.group = this.groupFor(def.command);
    return task;
  }

  /** Builds the CLI argument vector for a task definition. */
  private argsFor(def: BotopinkTaskDefinition): string[] {
    const args: string[] = [def.command];
    switch (def.command) {
      case "build":
        args.push("--target", def.target ?? this.targets.target);
        break;
      case "test":
        // Only commonJS / erlang run tests; honour the active target so an
        // erlang project still works, defaulting otherwise.
        args.push("--target", def.target ?? this.targets.target);
        if (def.filter) {
          args.push("--filter", def.filter);
        }
        break;
      case "check":
      case "format":
        // `check` reads botopink.json; `format` rewrites in place.
        break;
    }
    return args;
  }

  private label(def: BotopinkTaskDefinition): string {
    if (def.command === "build" || def.command === "test") {
      return `${def.command} (${def.target ?? this.targets.target})`;
    }
    return def.command;
  }

  private groupFor(command: BotopinkCommand): vscode.TaskGroup | undefined {
    switch (command) {
      case "build":
        return vscode.TaskGroup.Build;
      case "test":
        return vscode.TaskGroup.Test;
      default:
        return undefined;
    }
  }
}
