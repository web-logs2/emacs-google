import { bridgeAppRegist } from "https://deno.land/x/websocket_bridge@0.0.1/mod.ts";
import puppeteer from "https://deno.land/x/puppeteer@16.2.0/mod.ts";

const bridge = bridgeAppRegist(onMessage);

const executablePath = await getEmacsVar("google-puppeteer-executable-path");

const userDataDir = await getEmacsVar("google-puppeteer-user-data-dir");

const debug = await getEmacsVar("google-puppeteer-debug");
const headless = debug == "null";

console.log(`debug is: ${debug}`);
console.log(`executablePath is: ${executablePath}`);
console.log(`userDataDir is: ${userDataDir}`);
console.log(`headless is: ${headless}`);

function isString(s) {
  return typeof s === "string";
}

async function getEmacsVar(varName: string) {
  const varValue = await bridge.getEmacsVar(varName);
  if (isString(varValue)) {
    return varValue.replaceAll('"', "");
  }
  return varValue;
}

const browser = await puppeteer.launch({
  headless: headless,
  executablePath: executablePath,
  userDataDir: userDataDir,
});

const page = await browser.newPage();

bridge.messageToEmacs("Google for Websocket-bridge started.");

async function onMessage(message: string) {
  console.log(message);
  const [funcName, funcArgs] = JSON.parse(message)[1];
  if (funcName == "search") {
    await page.goto(`https://google.com/search?q=${funcArgs}`);
    await page.waitForSelector(".LC20lb", { visible: true });
    const searchResults = await page.$$eval(".LC20lb", (els) =>
      els.map((e) => ({
        title: e.innerText,
        link: decodeURI(e.parentNode.href),
        summary: e.parentNode.parentNode.parentNode.parentNode.innerText,
      }))
    );
    const resultsStr = JSON.stringify(searchResults)
      .replaceAll('"', '\\"')
      .replaceAll("#", "")
      .replaceAll("\n", "");
    bridge.evalInEmacs(`(google-show-results \"${resultsStr}\")`);
  }
}
