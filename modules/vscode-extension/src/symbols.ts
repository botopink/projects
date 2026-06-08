import * as vscode from "vscode";

/**
 * Fetches document symbols for a `.bp` document.
 *
 * The extension owns no compiler knowledge: symbols come from `botopink-lsp`
 * via the standard `documentSymbol` request. Going through
 * `vscode.executeDocumentSymbolProvider` (rather than the raw LanguageClient)
 * lets VS Code route to the registered LSP and normalises the response into
 * `DocumentSymbol`s, while staying resilient if the server is still starting.
 */
export async function fetchDocumentSymbols(
  uri: vscode.Uri,
): Promise<vscode.DocumentSymbol[]> {
  const result = await vscode.commands.executeCommand<
    vscode.DocumentSymbol[] | vscode.SymbolInformation[]
  >("vscode.executeDocumentSymbolProvider", uri);
  if (!result || result.length === 0) {
    return [];
  }
  // The provider may return either flat SymbolInformation or hierarchical
  // DocumentSymbols; we only consume the DocumentSymbol shape.
  if (isDocumentSymbolArray(result)) {
    return result;
  }
  return [];
}

function isDocumentSymbolArray(
  symbols: vscode.DocumentSymbol[] | vscode.SymbolInformation[],
): symbols is vscode.DocumentSymbol[] {
  return (
    symbols.length > 0 && "range" in symbols[0] && "children" in symbols[0]
  );
}

/** Walks a symbol tree depth-first, yielding every symbol. */
export function* flattenSymbols(
  symbols: vscode.DocumentSymbol[],
): Generator<vscode.DocumentSymbol> {
  for (const symbol of symbols) {
    yield symbol;
    if (symbol.children && symbol.children.length > 0) {
      yield* flattenSymbols(symbol.children);
    }
  }
}

/**
 * Test blocks are exposed by the LSP as `Method` symbols whose name is the test
 * string (landed in tooling-update F3).
 */
export function isTestSymbol(symbol: vscode.DocumentSymbol): boolean {
  return symbol.kind === vscode.SymbolKind.Method;
}

/** `fn main` is exposed as a `Function` symbol named `main`. */
export function isMainSymbol(symbol: vscode.DocumentSymbol): boolean {
  return symbol.kind === vscode.SymbolKind.Function && symbol.name === "main";
}
