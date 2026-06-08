import * as path from "path";
import * as vscode from "vscode";

/** Codegen targets understood by the `botopink` CLI / `botopink.json`. */
export const TARGETS = ["commonJS", "erlang", "beam", "wasm"] as const;
export type Target = (typeof TARGETS)[number];

export const DEFAULT_TARGET: Target = "commonJS";

const STATUS_BAR_PRIORITY = 100;

/**
 * Tracks the active codegen target for the workspace.
 *
 * The target is the source of truth in `botopink.json` (`target` field) at the
 * workspace root. This class mirrors it into a status-bar item and exposes the
 * current value to tasks / CodeLens. Clicking the item lets the user pick a new
 * target, which is written back into `botopink.json` (preserving other fields).
 *
 * The extension carries no compiler knowledge: the list of targets and the JSON
 * shape are configuration, not language semantics.
 */
export class TargetManager {
  private current: Target = DEFAULT_TARGET;
  private readonly statusBarItem: vscode.StatusBarItem;
  private readonly disposables: vscode.Disposable[] = [];

  constructor(private readonly selectCommandId: string) {
    this.statusBarItem = vscode.window.createStatusBarItem(
      vscode.StatusBarAlignment.Right,
      STATUS_BAR_PRIORITY,
    );
    this.statusBarItem.command = selectCommandId;
    this.disposables.push(this.statusBarItem);

    // Re-read the target whenever botopink.json changes on disk.
    const watcher =
      vscode.workspace.createFileSystemWatcher("**/botopink.json");
    watcher.onDidCreate(() => void this.reload());
    watcher.onDidChange(() => void this.reload());
    watcher.onDidDelete(() => void this.reload());
    this.disposables.push(watcher);
  }

  /** Loads the target from `botopink.json` and shows the status-bar item. */
  async init(): Promise<void> {
    await this.reload();
    this.statusBarItem.show();
  }

  get target(): Target {
    return this.current;
  }

  /** Prompts the user to pick a new target and persists it. */
  async pick(): Promise<void> {
    const picked = await vscode.window.showQuickPick([...TARGETS], {
      title: "Botopink codegen target",
      placeHolder: `Current target: ${this.current}`,
    });
    if (!picked) {
      return;
    }
    await this.setTarget(picked as Target);
  }

  /** Writes a target into `botopink.json` (or memory if none) and refreshes. */
  async setTarget(target: Target): Promise<void> {
    this.current = target;
    this.render();
    const uri = this.configUri();
    if (uri) {
      await this.writeConfigTarget(uri, target);
    } else {
      vscode.window.showWarningMessage(
        "No botopink.json found at the workspace root — the target will be passed via --target but not persisted.",
      );
    }
  }

  private async reload(): Promise<void> {
    const uri = this.configUri();
    if (!uri) {
      this.current = DEFAULT_TARGET;
      this.render();
      return;
    }
    try {
      const bytes = await vscode.workspace.fs.readFile(uri);
      const json = JSON.parse(Buffer.from(bytes).toString("utf8")) as {
        target?: string;
      };
      const target = json.target;
      this.current =
        target && (TARGETS as readonly string[]).includes(target)
          ? (target as Target)
          : DEFAULT_TARGET;
    } catch {
      this.current = DEFAULT_TARGET;
    }
    this.render();
  }

  /**
   * Persists `target` into `botopink.json`, preserving the other fields and the
   * existing key order/formatting as much as JSON round-tripping allows.
   */
  private async writeConfigTarget(
    uri: vscode.Uri,
    target: Target,
  ): Promise<void> {
    let parsed: Record<string, unknown> = {};
    try {
      const bytes = await vscode.workspace.fs.readFile(uri);
      parsed = JSON.parse(Buffer.from(bytes).toString("utf8")) as Record<
        string,
        unknown
      >;
    } catch {
      // Treat an unreadable/empty file as an empty object.
      parsed = {};
    }
    parsed.target = target;
    const text = JSON.stringify(parsed, null, 2) + "\n";
    await vscode.workspace.fs.writeFile(uri, Buffer.from(text, "utf8"));
  }

  /** Resolves the workspace-root `botopink.json`, if a workspace is open. */
  private configUri(): vscode.Uri | undefined {
    const folders = vscode.workspace.workspaceFolders;
    if (!folders || folders.length === 0) {
      return undefined;
    }
    return vscode.Uri.file(path.join(folders[0].uri.fsPath, "botopink.json"));
  }

  private render(): void {
    this.statusBarItem.text = `$(target) Botopink: ${this.current}`;
    this.statusBarItem.tooltip = "Click to change the Botopink codegen target";
  }

  dispose(): void {
    for (const d of this.disposables) {
      d.dispose();
    }
  }
}
