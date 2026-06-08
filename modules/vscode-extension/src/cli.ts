import * as fs from "fs";
import * as path from "path";
import * as vscode from "vscode";

const EXTENSION_NS = "botopink";
const DEFAULT_CLI_BIN = "botopink";

/**
 * Resolves the `botopink` CLI command.
 *
 * Mirrors the `botopink-lsp` resolution style in `extension.ts`: reads the
 * `botopink.cliPath` setting, resolves a relative path against the open
 * workspace folders, and otherwise falls back to the bare `botopink` name so
 * the PATH lookup applies.
 */
export async function getBotopinkCliPath(): Promise<string> {
  const configured = getConfiguredCliPath();
  const workspaceFolders = vscode.workspace.workspaceFolders;
  if (!configured) {
    return DEFAULT_CLI_BIN;
  }
  if (path.isAbsolute(configured)) {
    return configured;
  }
  if (workspaceFolders) {
    for (const folder of workspaceFolders) {
      const candidate = path.resolve(folder.uri.fsPath, configured);
      if (await fileExists(candidate)) {
        return candidate;
      }
    }
  }
  // Relative path that did not resolve to a file — let the shell try it.
  return configured;
}

function getConfiguredCliPath(): string | undefined {
  const value = vscode.workspace.getConfiguration(EXTENSION_NS).get("cliPath");
  if (typeof value !== "string" || value.trim().length === 0) {
    return undefined;
  }
  return value;
}

function fileExists(filePath: string): Promise<boolean> {
  return new Promise<boolean>((resolve) => {
    fs.stat(filePath, (err, stat) => {
      resolve(err == null && stat.isFile());
    });
  }).catch(() => false);
}

let outputChannel: vscode.OutputChannel | undefined;

/** Lazily-created shared OutputChannel for `botopink` CLI runs. */
export function getOutputChannel(): vscode.OutputChannel {
  if (!outputChannel) {
    outputChannel = vscode.window.createOutputChannel("Botopink");
  }
  return outputChannel;
}

export function disposeOutputChannel(): void {
  outputChannel?.dispose();
  outputChannel = undefined;
}

/** The directory a CLI command should run in (workspace root), if any. */
export function workspaceCwd(): string | undefined {
  return vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
}
