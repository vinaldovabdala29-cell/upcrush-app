import 'dart:convert';
import '../config.dart';
import 'package:http/http.dart' as http;

class AIService {
  static const String _openAiKey = Config.openAiKey;
  static const String _anthropicKey = Config.anthropicKey;

  static const Map<String, String> _idiomaNomes = {
    'en': 'English', 'pt': 'Brazilian Portuguese', 'de': 'German',
    'es': 'Spanish', 'fr': 'French', 'it': 'Italian',
    'tr': 'Turkish', 'pl': 'Polish', 'ru': 'Russian', 'ar': 'Arabic',
  };

  static const Map<String, String> _idiomaCultura = {
    'en': 'Western Gen Z dating culture.',
    'pt': 'Brazilian Gen Z dating culture. Use natural Brazilian Portuguese slang.',
    'de': 'German Gen Z dating culture. Direct, dry wit, no fluff.',
    'es': 'Spanish/Latin Gen Z dating culture. Passionate, charming, playful.',
    'fr': 'French Gen Z dating culture. Elegant, witty, understated.',
    'it': 'Italian Gen Z dating culture. Passionate, expressive, charming.',
    'tr': 'Turkish Gen Z dating culture. Bold, confident, clever.',
    'pl': 'Polish Gen Z dating culture. Direct, dry humor, genuine.',
    'ru': 'Russian Gen Z dating culture. Bold, confident, unexpected.',
    'ar': 'Arabic Gen Z dating culture. Charming, confident, clever.',
  };

  static String _getEstiloSystem(String estilo, String lang, String idioma, String cultura) {

    String exemplos() {
      switch (estilo) {
        case 'engraçado':
          switch (lang) {
            case 'de': return '- "Du siehst aus wie jemand, der im Lebenslauf lügt und den Job trotzdem bekommt"\n'
                '- "Ich zeige dein Profil an. Straftat: Störung des Seelenfriedens"\n'
                '- "Ich wollte oberflächlich sein und bin mit emotionalen Schulden rausgegangen"\n'
                '- "Du lächelst alle so an oder nur die, die eh schon verloren sind?"';
            case 'es': return '- "Tienes cara de quien miente en el currículo y aún así consigue el trabajo"\n'
                '- "Te denuncio el perfil. Delito: perturbar la paz mental"\n'
                '- "Fui a ser superficial y salí en bancarrota emocional"\n'
                '- "¿Sonríes así a todos o solo a los que ya están perdidos?"';
            case 'fr': return '- "T\'as l\'air de mentir sur ton CV et d\'avoir le poste quand même"\n'
                '- "Je signale ton profil. Crime: perturbation de la paix mentale"\n'
                '- "Je voulais être superficiel et je suis sorti en faillite émotionnelle"\n'
                '- "Tu souris comme ça à tout le monde ou seulement à ceux qui sont déjà perdus?"';
            case 'it': return '- "Hai la faccia di chi mente nel curriculum e ottiene comunque il lavoro"\n'
                '- "Denuncio il tuo profilo. Reato: disturbo della pace mentale"\n'
                '- "Volevo essere superficiale e sono uscito in bancarotta emotiva"\n'
                '- "Sorridi così a tutti o solo a chi è già perso?"';
            case 'tr': return '- "Özgeçmişinde yalan söyleyip yine de işe alınan birine benziyorsun"\n'
                '- "Profilini şikayet ediyorum. Suç: zihin huzurunu bozmak"\n'
                '- "Yüzeysel olmak için girdim, duygusal iflas ederek çıktım"\n'
                '- "Herkese mi böyle gülümsüyorsun yoksa sadece kaybolanlara mı?"';
            case 'en': return '- "You look like someone who lies on their resume and still gets the job"\n'
                '- "Reporting your profile. Crime: disturbing the peace"\n'
                '- "I came to be shallow and left emotionally bankrupt"\n'
                '- "You smile at everyone like that or just people who are already lost?"';
            default: return '- "Você tem cara de quem mente no currículo e ainda consegue o emprego"\n'
                '- "Tô denunciando seu perfil. Crime de perturbar a paz mental"\n'
                '- "Fui ser superficial e saí com dívida emocional"\n'
                '- "Você sorri assim pra todo mundo ou só pra quem tá perdido?"';
          }

        case 'picante':
          switch (lang) {
            case 'de': return '- "Ist noch Platz für eine weitere Zunge in deinem Mund?"\n'
                '- "Wie wär\'s mit einem Treffen? Ich verspreche nicht zu beißen... außer du bittest darum"\n'
                '- "Gefahr erkannt. Zu spät zum Fliehen."\n'
                '- "So kommen wir nirgendwo hin — es sei denn, das war der Plan"\n'
                '- "Ich versuche höflich zu sein, aber du machst es nicht leicht"';
            case 'es': return '- "¿Hay espacio para otra lengua en tu boca?"\n'
                '- "¿Qué tal si nos vemos? Prometo no morder... a menos que me lo pidas"\n'
                '- "Peligro detectado. Ya es tarde para huir."\n'
                '- "Así no llegaremos a ningún lado — a menos que ese sea el plan"\n'
                '- "Intento ser educado pero tú no lo pones fácil"';
            case 'fr': return '- "Il y a de la place pour une autre langue dans ta bouche?"\n'
                '- "Et si on se voyait? Je promets de ne pas mordre... sauf si tu le demandes"\n'
                '- "Danger détecté. Trop tard pour fuir."\n'
                '- "On n\'ira nulle part comme ça — à moins que c\'était le plan"\n'
                '- "J\'essaie d\'être poli mais tu ne facilites pas les choses"';
            case 'it': return '- "C\'è spazio per un\'altra lingua nella tua bocca?"\n'
                '- "Che ne dici di incontrarci? Prometto di non mordere... a meno che tu non lo chieda"\n'
                '- "Pericolo rilevato. Troppo tardi per fuggire."\n'
                '- "Così non andremo da nessuna parte — a meno che non fosse il piano"\n'
                '- "Sto cercando di essere educato ma tu non lo rendi facile"';
            case 'tr': return '- "Ağzında başka bir dil için yer var mı?"\n'
                '- "Buluşalım mı? Isırmayacağıma söz veriyorum... istemediğin sürece"\n'
                '- "Tehlike algılandı. Kaçmak için çok geç."\n'
                '- "Bu şekilde hiçbir yere varamayız — bu plan değilse"\n'
                '- "Nazik olmaya çalışıyorum ama kolaylaştırmıyorsun"';
            case 'en': return '- "Is there room for another tongue in your mouth?"\n'
                '- "How about we meet? I promise I won\'t bite... unless you ask"\n'
                '- "Danger detected. Too late to run."\n'
                '- "So we\'re not going anywhere — unless that was the plan all along"\n'
                '- "I\'m trying to be polite but you\'re not making it easy"';
            default: return '- "Tem espaço pra mais uma língua na sua boca?"\n'
                '- "Que tal um encontro? Eu prometo não morder... a menos que você peça"\n'
                '- "Perigo detectado. Tarde demais pra fugir."\n'
                '- "Assim a gente não vai a lugar nenhum — a não ser que seja esse o plano"\n'
                '- "Tô tentando ser educado mas você não facilita"';
          }

        case 'misterioso':
          switch (lang) {
            case 'de': return '- "Kommt drauf an, was du als normal betrachtest"\n'
                '- "Manchmal ja. Manchmal nein. Du wirst es herausfinden."\n'
                '- "Da steckt eine Geschichte dahinter, aber nicht für jeden Moment"\n'
                '- "Fragst du das alle so?"\n'
                '- "Gute Frage. Ich hab die Antwort noch nicht entschieden."';
            case 'es': return '- "Depende de lo que consideres normal"\n'
                '- "A veces sí. A veces no. Ya lo descubrirás."\n'
                '- "Hay una historia ahí, pero no es para cualquier momento"\n'
                '- "¿Les preguntas eso a todos?"\n'
                '- "Buena pregunta. Aún no he decidido la respuesta."';
            case 'fr': return '- "Ça dépend de ce que tu considères normal"\n'
                '- "Parfois oui. Parfois non. Tu le découvriras."\n'
                '- "Il y a une histoire là-dedans, mais pas pour n\'importe quel moment"\n'
                '- "Tu poses ça à tout le monde?"\n'
                '- "Bonne question. Je n\'ai pas encore décidé la réponse."';
            case 'it': return '- "Dipende da cosa consideri normale"\n'
                '- "A volte sì. A volte no. Lo scoprirai."\n'
                '- "C\'è una storia lì, ma non è per qualsiasi momento"\n'
                '- "Lo chiedi a tutti così?"\n'
                '- "Buona domanda. Non ho ancora deciso la risposta."';
            case 'tr': return '- "Normal olarak neyi kabul ettiğine bağlı"\n'
                '- "Bazen evet. Bazen hayır. Keşfedeceksin."\n'
                '- "Orada bir hikaye var ama her an için değil"\n'
                '- "Bunu herkese soruyor musun?"\n'
                '- "İyi soru. Cevabına henüz karar vermedim."';
            case 'en': return '- "Depends on what you consider normal"\n'
                '- "Sometimes yes. Sometimes no. You\'ll find out which."\n'
                '- "There\'s a story there, but it\'s not for just any moment"\n'
                '- "Do you ask everyone that?"\n'
                '- "Good question. I haven\'t decided the answer yet."';
            default: return '- "Depende do que você considera normal"\n'
                '- "Às vezes sim. Às vezes não. Você vai descobrir qual."\n'
                '- "Tem uma história aí, mas não é pra qualquer hora"\n'
                '- "Você pergunta isso pra todo mundo?"\n'
                '- "Boa pergunta. Ainda não decidi a resposta."';
          }

        case 'direto':
          switch (lang) {
            case 'de': return '- "Du interessierst mich. Was hast du außer dem Offensichtlichen zu bieten?"\n'
                '- "Geh diese Woche mit mir aus. Du wählst wo."\n'
                '- "Hör auf rumzudrucksen und sag mir, was du wirklich willst"\n'
                '- "Du bist genau die Art von Problem, die ich mir aussuchen würde"';
            case 'es': return '- "Me interesas. ¿Qué tienes para ofrecer más allá de lo obvio?"\n'
                '- "Sal conmigo esta semana. Tú eliges dónde."\n'
                '- "Deja de rodeos y dime lo que realmente quieres"\n'
                '- "Eres exactamente el tipo de problema que elegiría tener"';
            case 'fr': return '- "Tu m\'intéresses. Qu\'est-ce que tu as à offrir au-delà de l\'évident?"\n'
                '- "Sors avec moi cette semaine. Tu choisis où."\n'
                '- "Arrête de tourner autour du pot et dis-moi ce que tu veux vraiment"\n'
                '- "Tu es exactement le genre de problème que je choisirais d\'avoir"';
            case 'it': return '- "Mi interessi. Cosa hai da offrire oltre all\'ovvio?"\n'
                '- "Esci con me questa settimana. Scegli tu dove."\n'
                '- "Smettila di girare intorno e dimmi cosa vuoi davvero"\n'
                '- "Sei esattamente il tipo di problema che sceglierei di avere"';
            case 'tr': return '- "İlgimi çekiyorsun. Bariz olanın ötesinde ne sunuyorsun?"\n'
                '- "Bu hafta benimle çık. Nereye gideceğini sen seç."\n'
                '- "Lafı dolandırmayı bırak ve gerçekten ne istediğini söyle"\n'
                '- "Sen tam olarak tercih edeceğim sorun türüsün"';
            case 'en': return '- "You interest me. What do you have to offer beyond the obvious?"\n'
                '- "Go out with me this week. You choose where."\n'
                '- "Stop beating around the bush and tell me what you really want"\n'
                '- "You\'re exactly the type of problem I\'d choose to have"';
            default: return '- "Você me interessa. O que você tem pra oferecer além do óbvio?"\n'
                '- "Sai comigo essa semana. Você escolhe onde."\n'
                '- "Para de enrolar e me conta o que você quer de verdade"\n'
                '- "Você é exatamente o tipo de problema que eu escolheria ter"';
          }

        default:
          switch (lang) {
            case 'de': return '- "Das hat mich auf etwas völlig anderes gebracht"\n'
                '- "Du sagst das, aber da steckt bestimmt eine interessante Geschichte dahinter"\n'
                '- "Das hab ich nicht erwartet. Erzähl mehr."\n'
                '- "Okay, jetzt bin ich wirklich neugierig"\n'
                '- "Das ändert alles, was ich über dich dachte"';
            case 'es': return '- "Eso me hizo pensar en algo completamente diferente"\n'
                '- "Dices eso, pero apuesto a que hay una historia interesante detrás"\n'
                '- "No esperaba eso. Cuéntame más."\n'
                '- "Okay, ahora sí tengo curiosidad de verdad"\n'
                '- "Eso cambia todo lo que pensaba de ti"';
            case 'fr': return '- "Ça m\'a fait penser à quelque chose de complètement différent"\n'
                '- "Tu dis ça, mais je parie qu\'il y a une histoire intéressante derrière"\n'
                '- "Je ne m\'attendais pas à ça. Raconte plus."\n'
                '- "Okay, là j\'ai vraiment de la curiosité"\n'
                '- "Ça change tout ce que je pensais de toi"';
            case 'it': return '- "Quello che hai detto mi ha fatto pensare a qualcosa di completamente diverso"\n'
                '- "Lo dici, ma scommetto che c\'è una storia interessante dietro"\n'
                '- "Non me lo aspettavo. Racconta di più."\n'
                '- "Okay, ora sono davvero curioso"\n'
                '- "Questo cambia tutto quello che pensavo di te"';
            case 'tr': return '- "Bu beni bambaşka bir şeye götürdü"\n'
                '- "Bunu söylüyorsun ama arkasında ilginç bir hikaye olduğuna bahse girerim"\n'
                '- "Bunu beklemiyordum. Daha fazla anlat."\n'
                '- "Tamam, şimdi gerçekten merak ettim"\n'
                '- "Bu, senin hakkında düşündüklerimin hepsini değiştiriyor"';
            case 'en': return '- "That made me think of something completely different"\n'
                '- "You say that, but I bet there\'s an interesting story behind it"\n'
                '- "Didn\'t expect that. Tell me more."\n'
                '- "Okay, now I\'m genuinely curious"\n'
                '- "That changes everything I thought about you"';
            default: return '- "Isso que você falou me fez pensar em algo completamente diferente"\n'
                '- "Você diz isso, mas aposto que tem uma história interessante por trás"\n'
                '- "Não esperava isso. Conta mais."\n'
                '- "Okay, agora fiquei curioso de verdade"\n'
                '- "Isso muda tudo que eu pensava sobre você"';
          }
      }
    }

    final ex = exemplos();

    switch (estilo) {
      case 'engraçado':
        return 'You are the funniest guy she has ever talked to on a dating app.\n'
            '$cultura\n'
            'LANGUAGE: Write ONLY in $idioma.\n'
            'PERSONALITY: Unexpected humor. Absurd comparisons. Self-aware irony. Short and punchy.\n'
            'NATIVE CERTIFIED EXAMPLES IN $idioma:\n$ex\n'
            'CRITICAL: Generate NEW lines with the SAME energy. Not translations. Make her laugh out loud.\n'
            'RULES: 1-2 lines max. Never try-hard. Never generic.\n'
            'FORMAT: Exactly 6 responses, one per line, nothing else.';

      case 'picante':
        return 'You are the most magnetic seductive conversationalist she has ever met.\n'
            '$cultura\n'
            'LANGUAGE: Write ONLY in $idioma.\n'
            'PERSONALITY: Creates psychological tension. Bold double meaning. She drops what she is doing to reply.\n'
            'NATIVE CERTIFIED EXAMPLES IN $idioma:\n$ex\n'
            'CRITICAL: Generate NEW lines with the SAME energy. Not translations.\n'
            'RULES: 1-2 lines. Bold and tasteful. Creates instant tension. Never explicit. Never generic.\n'
            'FORMAT: Exactly 6 responses, one per line, nothing else.';

      case 'misterioso':
        return 'You are the most intriguing person she has ever talked to. She cannot figure you out.\n'
            '$cultura\n'
            'LANGUAGE: Write ONLY in $idioma.\n'
            'PERSONALITY: Says just enough. Never explains. Every message makes her think for 5 minutes.\n'
            'NATIVE CERTIFIED EXAMPLES IN $idioma:\n$ex\n'
            'CRITICAL: Generate NEW lines with the SAME energy. Not translations.\n'
            'RULES: Short. Cryptic but not rude. Leave gaps she needs to fill.\n'
            'FORMAT: Exactly 6 responses, one per line, nothing else.';

      case 'direto':
        return 'You are brutally confident. You say exactly what you want with zero apology.\n'
            '$cultura\n'
            'LANGUAGE: Write ONLY in $idioma.\n'
            'PERSONALITY: No games. Clean confident statements. Pure masculine energy. Never softens.\n'
            'NATIVE CERTIFIED EXAMPLES IN $idioma:\n$ex\n'
            'CRITICAL: Generate NEW lines with the SAME energy. Not translations.\n'
            'RULES: Short powerful sentences. No hedging. Pure confidence.\n'
            'FORMAT: Exactly 6 responses, one per line, nothing else.';

      default:
        return 'You are the most interesting man she has ever talked to. Effortlessly charming.\n'
            '$cultura\n'
            'LANGUAGE: Write ONLY in $idioma.\n'
            'PERSONALITY: Genuinely curious. Makes her feel seen. Smooth without trying.\n'
            'NATIVE CERTIFIED EXAMPLES IN $idioma:\n$ex\n'
            'CRITICAL: Generate NEW lines with the SAME energy. Not translations.\n'
            'RULES: Effortless. Creates curiosity. Warm but not weak. Max 2 lines.\n'
            'FORMAT: Exactly 6 responses, one per line, nothing else.';
    }
  }

  // ─── RESPOSTA DE TEXTO ────────────────────────────────────────────────────
  static Future<List<String>> gerarResposta(
      String conversa, String estilo, String lang) async {
    final idioma = _idiomaNomes[lang] ?? 'English';
    final cultura = _idiomaCultura[lang] ?? _idiomaCultura['en']!;
    final system = _getEstiloSystem(estilo, lang, idioma, cultura);
    return _chamarDual(
      system,
      'CONVERSATION:\n$conversa\n\n'
      'Her last message is the last one above. '
      'Generate 6 responses in $idioma using the style above. '
      'Be specific to what she said. Output only the 6 lines.',
    );
  }

  // ─── RESPOSTA DE IMAGEM ───────────────────────────────────────────────────
  static Future<List<String>> gerarRespostaDeImagem(
      String base64Image, String estilo, String lang) async {
    final idioma = _idiomaNomes[lang] ?? 'English';
    final cultura = _idiomaCultura[lang] ?? _idiomaCultura['en']!;
    final styleSystem = _getEstiloSystem(estilo, lang, idioma, cultura);
    final system = '$styleSystem\n\n'
        '=== IDENTIFYING WHO IS WHO IN THE SCREENSHOT ===\n'
        'POSITION RULE: RIGHT side bubbles = MY messages. LEFT side bubbles = HER messages.\n'
        'COLOR: blue/green/colored = RIGHT = ME. Gray/white = LEFT = HER.\n'
        'APPS: WhatsApp green right=ME white left=HER. iMessage blue right=ME gray left=HER.\n'
        'TASK: Find her LAST message (last LEFT bubble). Generate 6 replies I can send her NOW.\n'
        'Replies must be from a confident man to a woman. Be specific to what she said.\n'
        'If no conversation visible: generate 6 openers based on image context.\n'
        'NEVER refuse. ALWAYS output exactly 6 responses.';
    final userMsg = 'Screenshot of my dating app conversation. RIGHT=me, LEFT=her. '
        'Find her last message and generate 6 replies in $idioma. Output only the 6 lines.';
    return _chamarImagemDual(base64Image, system, userMsg);
  }

  // ─── RESPOSTA DE OCR ──────────────────────────────────────────────────────
  static Future<List<String>> gerarRespostaDeOCR(
      String conversaCompleta, String ultimaMensagemDela, String estilo, String lang) async {
    final idioma = _idiomaNomes[lang] ?? 'English';
    final cultura = _idiomaCultura[lang] ?? _idiomaCultura['en']!;
    final system = _getEstiloSystem(estilo, lang, idioma, cultura);
    return _chamarDual(
      system,
      'Her last message: "$ultimaMensagemDela"\n\n'
      'Full conversation context:\n$conversaCompleta\n\n'
      'Generate 6 responses in $idioma to her last message. Output only the 6 lines.',
    );
  }

  // ─── OPENER DE TEXTO ──────────────────────────────────────────────────────
  static Future<List<String>> gerarOpener(
      String descricao, String estilo, String lang) async {
    final idioma = _idiomaNomes[lang] ?? 'English';
    final cultura = _idiomaCultura[lang] ?? _idiomaCultura['en']!;
    final system = 'You are a Gen Z seduction master writing opening messages for dating apps.\n'
        '$cultura\n'
        'LANGUAGE: Write ONLY in $idioma.\n'
        'CERTIFIED OPENERS THAT MAKE HER REPLY IMMEDIATELY (adapt energy for $idioma):\n'
        '- "Com esse sorriso você devia cobrar pedágio"\n'
        '- "Vi seu perfil e fui direto pro grupo de apoio"\n'
        '- "Que tal um encontro? Eu prometo não morder... a menos que você peça"\n'
        '- "Teu sorriso é tão irresistível que eu precisaria de proteção"\n'
        '- "Você parece o tipo de problema que a gente agradece depois"\n'
        'RULES: Reference something SPECIFIC from her profile. Bold and unexpected. Max 2 lines.\n'
        'NEVER: wifi, coffee dates, "you are beautiful", generic, boring.\n'
        'FORMAT: Exactly 6 openers, one per line, nothing else.';
    return _chamarDual(
      system,
      'Her profile:\n$descricao\n\n'
      'Write 6 irresistible personalized openers in $idioma that make her reply immediately. Output only the 6 lines.',
    );
  }

  // ─── OPENER DE IMAGEM ─────────────────────────────────────────────────────
  static Future<List<String>> gerarOpenerDeImagem(
      String base64Image, String estilo, String lang) async {
    final idioma = _idiomaNomes[lang] ?? 'English';
    final cultura = _idiomaCultura[lang] ?? _idiomaCultura['en']!;

    final systemOpenAI = 'You are a Gen Z seduction master writing opening messages for dating apps.\n'
        '$cultura\n'
        'LANGUAGE: Write ONLY in $idioma.\n'
        'Analyze the image: setting, objects, activities, clothing style, hobbies, visible text.\n'
        'Write 6 openers that make her stop what she is doing and reply immediately.\n'
        'CERTIFIED EXAMPLES (match this EXACT energy for $idioma):\n'
        '- "Com esse sorriso você devia cobrar pedágio"\n'
        '- "Vi seu perfil e fui direto pro grupo de apoio"\n'
        '- "Que tal um encontro? Eu prometo não morder... a menos que você peça"\n'
        '- "Teu sorriso é tão irresistível que eu precisaria de proteção"\n'
        '- "Você parece o tipo de problema que a gente agradece depois"\n'
        'RULES: Bold and unexpected. Specific to THIS image. Max 2 lines. Max 1 emoji. NEVER refuse.\n'
        'NEVER: wifi, coffee dates, generic compliments, try-hard.\n'
        'FORMAT: Exactly 6 openers in $idioma, one per line, nothing else.';

    final systemAnthropic = 'You are a Gen Z seduction master writing opening messages for dating apps.\n'
        '$cultura\n'
        'LANGUAGE: Write ONLY in $idioma.\n'
        'Write 6 openers that make her stop what she is doing and reply immediately.\n'
        'CERTIFIED EXAMPLES (match this EXACT energy for $idioma):\n'
        '- "Com esse sorriso você devia cobrar pedágio"\n'
        '- "Que tal um encontro? Eu prometo não morder... a menos que você peça"\n'
        '- "Teu sorriso é tão irresistível que eu precisaria de proteção"\n'
        '- "Você parece o tipo de problema que a gente agradece depois"\n'
        'RULES: Bold, unexpected, creates instant tension. Max 2 lines. Max 1 emoji.\n'
        'NEVER: wifi, coffee dates, generic compliments.\n'
        'FORMAT: Exactly 6 openers in $idioma, one per line, nothing else.';

    try {
      final result = await _chamarImagemOpenAI(base64Image, systemOpenAI,
          'Profile image. Generate 6 irresistible openers in $idioma. Output only the 6 lines.');
      final joined = result.join(' ').toLowerCase();
      if (joined.contains('desculp') || joined.contains('sorry') ||
          joined.contains('cannot') || joined.contains('não consigo') ||
          joined.contains('unable') || joined.contains('apologize')) {
        throw Exception('Refused');
      }
      return result;
    } catch (_) {
      return await _chamarAnthropic(systemAnthropic,
          'Generate 6 irresistible dating app openers in $idioma. Make her reply immediately. Output only the 6 lines.');
    }
  }

  // ─── PICK LINES ───────────────────────────────────────────────────────────
  static Future<List<String>> gerarPickLines(String lang) async {
    final idioma = _idiomaNomes[lang] ?? 'English';
    final cultura = _idiomaCultura[lang] ?? _idiomaCultura['en']!;
    final system = 'You are the undisputed Gen Z seduction master. Every line makes her drop what she is doing and reply.\n'
        '$cultura\n'
        'LANGUAGE: Write ONLY in $idioma.\n'
        'CERTIFIED LINES (match this EXACT energy and boldness for $idioma):\n'
        '- "Tem espaço pra mais uma língua na sua boca?"\n'
        '- "Que tal um encontro? Eu prometo não morder... a menos que você peça"\n'
        '- "Perigo detectado. Tarde demais pra fugir."\n'
        '- "Assim a gente não vai a lugar nenhum — a não ser que seja esse o plano"\n'
        '- "Você tem cara de quem mente no currículo e ainda consegue o emprego"\n'
        '- "Tô tentando ser educado mas você não facilita"\n'
        '- "Posso te salvar nos contatos como problema gostoso?"\n'
        '- "Você faz isso com todo mundo ou só com quem merece atenção?"\n'
        '- "Teu sorriso é tão irresistível que eu precisaria de proteção"\n'
        '- "Denunciando seu perfil por perturbar a paz mental"\n'
        'ENERGY: Bold. Psychological tension. Double meaning. Makes her laugh AND feel something at the same time.\n'
        'GOAL: She drops what she is doing and replies immediately.\n'
        'NEVER: wifi, coffee dates, "you are beautiful", generic, boring, try-hard, explicit.\n'
        'FORMAT: Exactly 6 lines in $idioma, one per line, nothing else.';
    return _chamarDual(
      system,
      'Generate 6 irresistible Gen Z pick-up lines in $idioma. '
      'They must create instant psychological tension and make her reply immediately. '
      'Match the certified examples energy. Output only the 6 lines.',
    );
  }

  // ─── DUAL API ─────────────────────────────────────────────────────────────
  static Future<List<String>> _chamarDual(String systemPrompt, String userMessage) async {
    try {
      return await _chamarOpenAI(systemPrompt, userMessage);
    } catch (_) {
      return await _chamarAnthropic(systemPrompt, userMessage);
    }
  }

  static Future<List<String>> _chamarImagemDual(
      String base64Image, String system, String userMsg) async {
    try {
      return await _chamarImagemOpenAI(base64Image, system, userMsg);
    } catch (_) {
      return await _chamarImagemAnthropic(base64Image, system, userMsg);
    }
  }

  // ─── OPENAI TEXT ──────────────────────────────────────────────────────────
  static Future<List<String>> _chamarOpenAI(
      String systemPrompt, String userMessage) async {
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');
    final response = await http.post(url,
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $_openAiKey'},
      body: jsonEncode({
        'model': 'gpt-4o',
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userMessage},
        ],
        'temperature': 1.0, 'max_tokens': 500,
      }),
    );
    if (response.statusCode != 200) throw Exception('OpenAI error ${response.statusCode}');
    return _parseOpenAI(response.body);
  }

  // ─── ANTHROPIC TEXT ───────────────────────────────────────────────────────
  static Future<List<String>> _chamarAnthropic(
      String systemPrompt, String userMessage) async {
    final url = Uri.parse('https://api.anthropic.com/v1/messages');
    final response = await http.post(url,
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': _anthropicKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': 'claude-sonnet-4-5',
        'max_tokens': 500,
        'system': systemPrompt,
        'messages': [{'role': 'user', 'content': userMessage}],
      }),
    );
    if (response.statusCode != 200) throw Exception('Anthropic error ${response.statusCode}');
    return _parseAnthropic(response.body);
  }

  // ─── OPENAI IMAGE ─────────────────────────────────────────────────────────
  static Future<List<String>> _chamarImagemOpenAI(
      String base64Image, String system, String userMsg) async {
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');
    final response = await http.post(url,
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $_openAiKey'},
      body: jsonEncode({
        'model': 'gpt-4o',
        'messages': [
          {'role': 'system', 'content': system},
          {'role': 'user', 'content': [
            {'type': 'image_url', 'image_url': {
              'url': 'data:image/jpeg;base64,$base64Image',
              'detail': 'low',
            }},
            {'type': 'text', 'text': userMsg},
          ]},
        ],
        'max_tokens': 500, 'temperature': 1.0,
      }),
    );
    if (response.statusCode != 200) throw Exception('OpenAI image error ${response.statusCode}');
    return _parseOpenAI(response.body);
  }

  // ─── ANTHROPIC IMAGE ──────────────────────────────────────────────────────
  static Future<List<String>> _chamarImagemAnthropic(
      String base64Image, String system, String userMsg) async {
    final url = Uri.parse('https://api.anthropic.com/v1/messages');
    final response = await http.post(url,
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': _anthropicKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': 'claude-sonnet-4-5',
        'max_tokens': 500,
        'system': system,
        'messages': [
          {'role': 'user', 'content': [
            {'type': 'image', 'source': {
              'type': 'base64',
              'media_type': 'image/jpeg',
              'data': base64Image,
            }},
            {'type': 'text', 'text': userMsg},
          ]},
        ],
      }),
    );
    if (response.statusCode != 200) throw Exception('Anthropic image error ${response.statusCode}');
    return _parseAnthropic(response.body);
  }

  // ─── PARSERS ──────────────────────────────────────────────────────────────
  static List<String> _parseOpenAI(String body) {
    final data = jsonDecode(body);
    final text = data['choices'][0]['message']['content'].toString();
    return _parseLines(text);
  }

  static List<String> _parseAnthropic(String body) {
    final data = jsonDecode(body);
    final text = data['content'][0]['text'].toString();
    return _parseLines(text);
  }

  static List<String> _parseLines(String content) {
    const explicativos = [
      'here are', 'aqui estão', 'hier sind', 'aquí tienes',
      'these are', 'voilà', 'below', 'responses:', 'respostas:',
      'options:', 'opções:', 'i cannot', "i can't", "i'm sorry",
      'i am sorry', 'desculpe', 'lo siento', 'entschuldigung',
      'sure here', 'of course', 'certainly', 'as requested',
    ];
    final lista = content.split('\n')
        .map((e) => e.trim())
        .map((e) => e.replaceAll(RegExp(r'^\d+[.)]\s*'), ''))
        .map((e) => e.replaceAll(RegExp(r'^[-•*]\s*'), ''))
        .map((e) => e.replaceAll(RegExp(r'^[""""]|[""""]$'), ''))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .where((e) {
          final l = e.toLowerCase();
          return !explicativos.any((w) => l.startsWith(w));
        })
        .where((e) => e.length >= 3)
        .take(6)
        .toList();
    if (lista.isEmpty) throw Exception('Empty response from AI');
    return lista;
  }
}