# Tons independentes do UpCrush

Substitui a pasta lib pela pasta lib deste ZIP, incluindo services/tones. Esta versão já inclui as correções da assinatura de gerarPickLines e os dados das categorias dentro de ai_service.dart; não depende do ficheiro cantada_categories.dart separado.

## Onde desenvolver cada tom

- romantico_tone.dart: doce, paquerador, conquistador, rizz e punchlines românticas. Mostrado com coração.
- engracado_tone.dart: extrovertido, divertido, rizz e punchlines de humor contextual.
- picante_tone.dart: atrevido, provocador, sugestivo e com malícia; não produz descrições sexuais gráficas.
- misterioso_tone.dart: discreto, romântico e com subtexto; sem mistério vazio.
- toxico_tone.dart: seco, poucas palavras, sarcasmo e limites proporcionais ao contexto.
- flertar_tone.dart: claro, confiante e objetivo.
- charmoso_tone.dart: preservado para compatibilidade; não adiciona botão.

Cada ficheiro contém o seu systemPrompt completo e maxWords: 12. As regras de contexto e formato estão repetidas intencionalmente em cada prompt para permitir desenvolvimento independente. Ao mudar o limite de um tom, atualiza maxWords e a regra HARD LENGTH nesse mesmo ficheiro.

ToneRegistry apenas seleciona o tom e mantém natural como alias de romantico. ToneDefinition contém os dados e a validação de palavras; não acrescenta prompts.

AIService, ConversationStarterService e RomanticImageOpenerService enviam exclusivamente tone.systemPrompt nas instruções da API. A entrada contém apenas os dados da tarefa, idioma, contexto, categoria, quantidade e histórico. O banco de 3000 referências e os prompts românticos comuns foram retirados de AIService; já não influenciam todos os tons. Não há avaliador de personalidade: apenas verificações de formato, comprimento e repetição.

As mensagens acima do limite são rejeitadas, sem truncar frases. O serviço tenta gerar novamente até ao limite de tentativas; se não conseguir, devolve erro em vez de apresentar uma mensagem longa. O histórico interno de AIService separa os tons. Os modelos da versão recebida foram mantidos.

## Validação

Verificados imports relativos, rotas de todos os tons, limite em todos os serviços, exclusividade dos prompts enviados, ícones, chamadas das telas, caminho de modoRapido e preservação dos restantes ficheiros. Foi acrescentada a função gerarRespostaDeOCR que ResultScreen já chamava mas que não existia no serviço recebido.

Flutter/Dart não estão disponíveis neste ambiente. Não foi feita compilação nem chamada real à API. No projeto completo, executa flutter analyze e testa os tons no dispositivo antes de publicar.

## Personalização e variedade

Cada tom ganhou regras próprias, no seu ficheiro, para aproveitar características explicitamente reveladas, comportamentos observáveis e detalhes reais da foto. As metáforas devem nascer desses detalhes, ter uma ligação compreensível e respeitar a personalidade do tom. Não são obrigatórias nem devem inventar fatos sobre a pessoa.

O histórico serve também para evitar repetir a mesma ideia, cenário, metáfora e punchline com palavras diferentes. Isto é uma instrução ao modelo, não uma garantia de eliminação de repetição semântica. Em Iniciar conversa, o histórico passou a conservar as últimas 20 mensagens em vez das primeiras 20.

Não há frases prontas adicionadas ao prompt. Mantêm-se os modelos, a API, o limite validado de 12 palavras, a interface e a pré-geração existentes. A qualidade das respostas ainda precisa ser testada com a API real; não foi medida nesta alteração.

Os botões usam theme/tone_options.dart: Romântico, Engraçado, Flertar 💘, Misterioso e Tóxico. A chave antiga direto resolve para flertar. O prompt foi preservado nesta mudança de nome.
