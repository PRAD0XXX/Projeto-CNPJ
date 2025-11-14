# Projeto-CNPJ
Este projeto realiza a consulta dos 200 primeiros CNPJs de empresas localizadas em Barueri (SP) utilizando os Dados Abertos da Receita Federal.
A aplicação faz o download dos arquivos ZIP disponibilizados pela Receita, lê os arquivos de estabelecimentos e retorna os CNPJs encontrados diretamente pela API.

🚀 Tecnologias Utilizadas

Node.js

Express

node-fetch

unzipper

readline

📂 Estrutura do Projeto

Projeto-CNPJ/
├── public/
├── server.mjs
├── package.json
├── package-lock.json
└── README.md

🔎 O que o projeto faz?

Baixa automaticamente todos os 10 arquivos de estabelecimentos (Estabelecimentos0.zip a Estabelecimentos9.zip).

Procura registros cujo código IBGE seja 3505708 (Barueri).

Extrai o CNPJ completo dos registros encontrados.

Retorna até 200 resultados.

Disponibiliza tudo via API.

📡 Endpoint da API

GET /api/barueri

Exemplo de retorno:

{
  "source": "Receita Federal (dados abertos)",
  "ibge_barueri": "3505708",
  "count": 200,
  "items": [
    "12345678000199",
    "98765432000155",
    "... (200 valores)"
  ]
}

🛠️ Como executar o projeto

1. Instale as dependências

npm install

2. Inicie o servidor

node server.mjs

3. Acesse no navegador

http://localhost:3000/api/barueri

🗄️ Sobre o banco de dados

Este projeto não utiliza um banco de dados local.
Ele consulta diretamente os arquivos públicos da Receita Federal, portanto não existe um script SQL para popular o banco — o projeto funciona somente lendo arquivos externos.

📜 Licença

Este projeto é de uso livre para fins de estudo e demonstração.
