import express from "express";
import fetch from "node-fetch";
import unzipper from "unzipper";
import readline from "readline";

const app = express();
const PORT = 3000;

const ROOT_URL = "https://arquivos.receitafederal.gov.br/dados/cnpj/dados_abertos_cnpj/";
const IBGE_BARUERI = "3505708";
const MAX_RESULTS = 200;

// Função que descobre automaticamente a pasta mais recente
async function getLatestFolder() {
  const response = await fetch(ROOT_URL);
  const html = await response.text();

  const regex = /href="(\d{4}-\d{2})\/"/g;
  const folders = [...html.matchAll(regex)].map(m => m[1]);

  if (folders.length === 0) throw new Error("Nenhuma pasta encontrada no diretório da Receita.");

  // Ordena descrescente e pega a mais nova
  folders.sort().reverse();

  console.log(`📁 Última pasta encontrada: ${folders[0]}`);
  return folders[0];
}

// Lê arquivo interno dentro do ZIP
async function parseEstabelecimentosStream(entry, limit) {
  const results = [];
  const rl = readline.createInterface({
    input: entry,
    crlfDelay: Infinity,
  });

  let lineCount = 0;

  for await (const line of rl) {
    lineCount++;
    const codigoMunicipio = line.slice(674, 682).trim();

    if (codigoMunicipio === IBGE_BARUERI) {
      const cnpjBase = line.slice(3, 11).trim();
      const cnpjOrdem = line.slice(11, 15).trim();
      const cnpjDv = line.slice(15, 17).trim();
      const cnpjCompleto = `${cnpjBase}${cnpjOrdem}${cnpjDv}`;
      results.push(cnpjCompleto);

      if (results.length >= limit) break;
    }
  }

  return results;
}

// Função principal
async function fetchFirstCNPJsOfBarueri(limit = MAX_RESULTS) {
  const latestFolder = await getLatestFolder();
  const results = [];

  for (let i = 0; i < 10; i++) {
    const url = `${ROOT_URL}${latestFolder}/Estabelecimentos${i}.zip`;
    console.log(`🔍 Tentando arquivo: ${url}`);

    try {
      const response = await fetch(url);
      if (!response.ok) throw new Error(`Erro ao baixar ${url}`);

      const directory = response.body.pipe(unzipper.Parse({ forceStream: true }));

      for await (const entry of directory) {
        const name = entry.path;
        if (entry.type === "File" && /ESTABELE/i.test(name)) {
          const found = await parseEstabelecimentosStream(entry, limit - results.length);
          results.push(...found);

          if (results.length >= limit) return results;
        }
      }

    } catch (err) {
      console.error(`⚠️ Erro no arquivo ${i}:`, err.message);
    }
  }

  return results;
}

// Endpoint da API
app.get("/api/barueri", async (req, res) => {
  try {
    const items = await fetchFirstCNPJsOfBarueri();
    res.json({
      source: "Receita Federal (dados abertos)",
      ibge_barueri: IBGE_BARUERI,
      count: items.length,
      items,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.listen(PORT, () => {
  console.log(`🌐 Servidor rodando em http://localhost:${PORT}`);
});
