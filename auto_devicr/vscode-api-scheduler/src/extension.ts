import * as vscode from 'vscode';
import cron from 'node-cron';

let outputChannel: vscode.OutputChannel | null = null;
let scheduledTask: cron.ScheduledTask | null = null;
let sessionCookie: string | null = null;

function getOutputChannel(): vscode.OutputChannel {
  if (!outputChannel) {
    outputChannel = vscode.window.createOutputChannel('API Scheduler');
  }
  return outputChannel;
}

function log(message: string): void {
  const ch = getOutputChannel();
  const timestamp = new Date().toISOString();
  ch.appendLine(`[${timestamp}] ${message}`);
}

async function callApi(): Promise<void> {
  const conf = vscode.workspace.getConfiguration('apiScheduler');
  const url = conf.get<string>('apiUrl') || '';
  const method = conf.get<string>('method') || 'GET';
  const headers = conf.get<Record<string, string>>('headers') || {};
  const body = conf.get<string | null>('body');
  const timeoutMs = conf.get<number>('timeoutMs') || 15000;

  if (!url) {
    vscode.window.showErrorMessage('API Scheduler: Missing apiScheduler.apiUrl');
    log('ERROR: Missing apiScheduler.apiUrl');
    return;
  }

  log(`Calling API ${method} ${url}`);

  // Use fetch built into Node 18+ (VS Code runtime). Avoid extra deps.
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const response = await fetch(url, {
      method,
      headers,
      body: method === 'GET' ? undefined : body ?? undefined,
      signal: controller.signal,
    });
    clearTimeout(timeout);
    const text = await response.text();
    log(`Status: ${response.status} ${response.statusText}`);
    log(`Response: ${text.substring(0, 4000)}`);
    if (!response.ok) {
      vscode.window.showWarningMessage(`API Scheduler: Non-OK status ${response.status}`);
    } else {
      vscode.window.showInformationMessage('API Scheduler: API call succeeded');
    }
  } catch (err: unknown) {
    clearTimeout(timeout);
    const message = err instanceof Error ? err.message : String(err);
    log(`ERROR: ${message}`);
    vscode.window.showErrorMessage(`API Scheduler: ${message}`);
  }
}

async function loginAndStoreCookie(): Promise<void> {
  const conf = vscode.workspace.getConfiguration('apiScheduler');
  const baseUrl = conf.get<string>('baseUrl') || '';
  let username = conf.get<string | null>('username');
  let password = conf.get<string | null>('password');
  const timeoutMs = conf.get<number>('timeoutMs') || 15000;

  if (!baseUrl) {
    vscode.window.showErrorMessage('API Scheduler: Missing baseUrl');
    return;
  }
  if (!username) {
    username = await vscode.window.showInputBox({ prompt: 'Username', ignoreFocusOut: true });
  }
  if (!password) {
    password = await vscode.window.showInputBox({ prompt: 'Password', password: true, ignoreFocusOut: true });
  }
  if (!username || !password) {
    vscode.window.showWarningMessage('API Scheduler: Username or password not provided');
    return;
  }

  const auth = Buffer.from(`${username}:${password}`).toString('base64');
  const url = `${baseUrl}/api/login`;
  log(`Logging in to ${url}`);

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        Accept: '*/*',
        Authorization: `Basic ${auth}`,
      },
      signal: controller.signal,
      redirect: 'manual',
    });
    clearTimeout(timeout);
    const setCookie = response.headers.get('set-cookie');
    if (setCookie) {
      // naive parse for connect.sid=...; take first cookie
      const cookie = setCookie.split(',')[0].split(';')[0];
      sessionCookie = cookie;
      log(`Login success. Stored cookie: ${cookie.substring(0, 40)}...`);
      vscode.window.showInformationMessage('API Scheduler: Login successful');
    } else {
      log('Login response missing set-cookie');
      vscode.window.showWarningMessage('API Scheduler: Login may have failed (no cookie)');
    }
  } catch (e) {
    clearTimeout(timeout);
    const message = e instanceof Error ? e.message : String(e);
    log(`ERROR login: ${message}`);
    vscode.window.showErrorMessage(`API Scheduler: Login failed - ${message}`);
  }
}

async function extendDevice(): Promise<void> {
  const conf = vscode.workspace.getConfiguration('apiScheduler');
  const baseUrl = conf.get<string>('baseUrl') || '';
  const deviceId = conf.get<string | number | null>('deviceId');
  const hour = conf.get<number>('extendHour') || 1;
  const timeoutMs = conf.get<number>('timeoutMs') || 15000;

  if (!baseUrl || !deviceId) {
    vscode.window.showErrorMessage('API Scheduler: baseUrl or deviceId missing');
    return;
  }
  if (!sessionCookie) {
    await loginAndStoreCookie();
    if (!sessionCookie) {
      return;
    }
  }

  const url = `${baseUrl}/api/userdevice/${deviceId}`;
  log(`PATCH extend device ${deviceId} by ${hour}h`);

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const response = await fetch(url, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json;charset=UTF-8',
        Accept: 'application/json, text/plain, */*',
        Cookie: sessionCookie,
        Origin: baseUrl,
      },
      body: JSON.stringify({ command: 'extend', hour }),
      signal: controller.signal,
    });
    clearTimeout(timeout);
    const text = await response.text();
    log(`Extend status: ${response.status}`);
    log(`Extend response: ${text.substring(0, 2000)}`);
    if (!response.ok) {
      vscode.window.showWarningMessage(`API Scheduler: Extend non-OK ${response.status}`);
    } else {
      vscode.window.showInformationMessage('API Scheduler: Extend OK');
    }
  } catch (e) {
    clearTimeout(timeout);
    const message = e instanceof Error ? e.message : String(e);
    log(`ERROR extend: ${message}`);
    vscode.window.showErrorMessage(`API Scheduler: Extend failed - ${message}`);
  }
}

function scheduleDaily(): void {
  const conf = vscode.workspace.getConfiguration('apiScheduler');
  const cronExpr = conf.get<string>('cron') || '0 9 * * *';
  if (scheduledTask) {
    scheduledTask.stop();
    scheduledTask.destroy();
    scheduledTask = null;
  }
  try {
    scheduledTask = cron.schedule(cronExpr, () => {
      void extendDevice();
    }, { timezone: Intl.DateTimeFormat().resolvedOptions().timeZone });
    log(`Scheduled daily job with cron: ${cronExpr}`);
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    log(`ERROR scheduling: ${message}`);
    vscode.window.showErrorMessage(`API Scheduler: Invalid cron '${cronExpr}'`);
  }
}

export function activate(context: vscode.ExtensionContext): void {
  const conf = vscode.workspace.getConfiguration('apiScheduler');
  const enableOnStartup = conf.get<boolean>('enableOnStartup') || false;

  const runNow = vscode.commands.registerCommand('apiScheduler.runNow', async () => {
    getOutputChannel().show(true);
    await extendDevice();
  });

  const loginCmd = vscode.commands.registerCommand('apiScheduler.login', async () => {
    getOutputChannel().show(true);
    await loginAndStoreCookie();
  });

  const toggleSchedule = vscode.commands.registerCommand('apiScheduler.toggleSchedule', () => {
    getOutputChannel().show(true);
    if (scheduledTask) {
      scheduledTask.stop();
      scheduledTask.destroy();
      scheduledTask = null;
      log('Stopped scheduled job');
      vscode.window.showInformationMessage('API Scheduler: Schedule stopped');
    } else {
      scheduleDaily();
      vscode.window.showInformationMessage('API Scheduler: Schedule started');
    }
  });

  const openOutput = vscode.commands.registerCommand('apiScheduler.openOutput', () => {
    getOutputChannel().show(true);
  });

  context.subscriptions.push(runNow, loginCmd, toggleSchedule, openOutput);

  if (enableOnStartup) {
    scheduleDaily();
  }
}

export function deactivate(): void {
  if (scheduledTask) {
    scheduledTask.stop();
    scheduledTask.destroy();
    scheduledTask = null;
  }
  if (outputChannel) {
    outputChannel.dispose();
    outputChannel = null;
  }
}


