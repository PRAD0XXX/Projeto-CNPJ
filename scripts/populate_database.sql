import express from "express";
import fetch from "node-fetch";
import unzipper from "unzipper";
import readline from "readline";

const app = express();
const PORT = 3000;

app.use(express.static("public"));


const BASE_URL = "https://arquivos.receitafederal.gov.br/dados/cnpj/dados_abertos_cnpj/2025-11";
const IBGE_BARUERI = "3505708";
const MAX_RESULTS = 200;

// Função auxiliar: lê um arquivo dentro do ZIP
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

    if (lineCount % 100000 === 0) {
      console.log(`→ Lidas ${lineCount.toLocaleString()} linhas...`);
    }
  }

  console.log(`✅ Total de registros encontrados neste arquivo: ${results.length}`);
  return results;
}

// Função principal: tenta todos os 10 arquivos até achar os CNPJs de Barueri
async function fetchFirstCNPJsOfBarueri(limit = MAX_RESULTS) {
  const results = [];

  for (let i = 0; i < 10; i++) {
    const url = `${BASE_URL}/Estabelecimentos${i}.zip`;
    console.log(`\n🔍 Tentando arquivo: ${url}`);

    try {
      const response = await fetch(url);
      if (!response.ok) throw new Error(`Erro ao baixar ${url}`);

      const directory = response.body.pipe(unzipper.Parse({ forceStream: true }));

      for await (const entry of directory) {
        const fileName = entry.path;
        if (entry.type === "File" && /ESTABELE/i.test(fileName)) {
          console.log(`→ Lendo arquivo interno: ${fileName}`);
          const found = await parseEstabelecimentosStream(entry, limit - results.length);
          results.push(...found);
          entry.autodrain();

          if (results.length >= limit) {
            console.log("\n✅✅✅ FINALIZADO! Foram encontrados 200 CNPJs de Barueri.");
            console.log("🟢 A consulta foi concluída com sucesso!");
            return results;
          }
        } else {
          entry.autodrain();
        }
      }
    } catch (err) {
      console.error(`⚠️ Erro ao processar ${url}: ${err.message}`);
    }
  }

  console.log("\n🚫 Nenhum CNPJ encontrado nos 10 arquivos.");
  console.log("🟠 A busca foi finalizada, mas não localizou registros de Barueri.");
  return results;
}

// Endpoint da API
app.get("/api/barueri", async (req, res) => {
  console.log("🚀 Iniciando busca pelos primeiros 200 CNPJs de Barueri...");
  const items = await fetchFirstCNPJsOfBarueri();
  console.log("\n📦 Enviando resposta ao navegador...");
  res.json({
    source: "Receita Federal (dados abertos)",
    ibge_barueri: IBGE_BARUERI,
    count: items.length,
    items,
  });
  console.log("✅ Resposta enviada! Processo concluído.");
});

app.listen(PORT, () => {
  console.log(`🌐 Servidor rodando em http://localhost:${PORT}`);
});
