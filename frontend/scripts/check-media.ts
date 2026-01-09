import { properties } from "../src/data/properties";

const urls = new Map<string, { property: string; type: "capa" | "galeria" }>();

properties.forEach((property) => {
  urls.set(property.image, { property: property.title, type: "capa" });
  property.gallery.forEach((item) => {
    urls.set(item.url, { property: property.title, type: "galeria" });
  });
});

async function checkUrl(url: string, info: { property: string; type: "capa" | "galeria" }) {
  try {
    const response = await fetch(url, { method: "HEAD" });
    if (!response.ok) {
      console.error(`✗ ${info.property} (${info.type}) → ${url} [${response.status}]`);
      return false;
    }
    console.log(`✓ ${info.property} (${info.type}) → ${url}`);
    return true;
  } catch (error) {
    console.error(`✗ ${info.property} (${info.type}) → ${url} [${(error as Error).message}]`);
    return false;
  }
}

(async () => {
  let ok = true;
  for (const [url, info] of urls.entries()) {
    const result = await checkUrl(url, info);
    ok = ok && result;
  }

  if (!ok) {
    console.error("Algumas URLs falharam na verificação.");
    process.exitCode = 1;
  } else {
    console.log("Todas as URLs responderam com sucesso.");
  }
})();
