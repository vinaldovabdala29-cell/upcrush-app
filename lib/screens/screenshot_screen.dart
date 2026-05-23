import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ai_service.dart';
import '../services/credits_service.dart';
import '../widgets/paywall_screen.dart';
import 'result_screen.dart';
import '../../../main.dart';

class ScreenshotScreen extends StatefulWidget {
  const ScreenshotScreen({super.key});

  @override
  State<ScreenshotScreen> createState() => _ScreenshotScreenState();
}

class _ScreenshotScreenState extends State<ScreenshotScreen>
    with TickerProviderStateMixin {

  File? _imagemSelecionada;
  bool _analisando = false;
  bool _erro = false;
  String _erroMsg = "";

  late AnimationController _scanController;
  late Animation<double> _scanAnim;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    _scanController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1800))..repeat();
    _scanAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut));

    _pulseController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    WidgetsBinding.instance.addPostFrameCallback((_) => _processarImagem());
  }

  @override
  void dispose() {
    _scanController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _processarImagem() async {
    final picker = ImagePicker();
    try {
      final img = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 85);

      if (img == null) {
        if (mounted) Navigator.pop(context);
        return;
      }

      setState(() {
        _imagemSelecionada = File(img.path);
        _analisando = true;
        _erro = false;
      });

      final bytes = await File(img.path).readAsBytes();
      final base64Image = base64Encode(bytes);

      // Paywall após galeria
      final devePaywall = await CreditsService.shouldShowPaywallAfterScan();
      if (devePaywall && mounted) {
        await Navigator.push(context, MaterialPageRoute(
          fullscreenDialog: true, builder: (_) => const PaywallFlow()));
        final premium = await CreditsService.isPremium();
        if (!premium && mounted) { Navigator.pop(context); return; }
      }
      if (!mounted) return;

      final replies = await AIService.gerarRespostaDeImagem(
        base64Image, "picante", appLang.languageCode);

      if (!mounted) return;

      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => ResultScreen(
          title: appLang.screenshotTitle,
          replies: replies,
          originalPrompt: "imagem:$base64Image",
          ultimaMensagem: "",
          style: "picante",
        ),
      ));
    } catch (e) {
      if (mounted) {
        setState(() {
          _analisando = false;
          _erro = true;
          _erroMsg = "Algo deu errado.\nVerifica a conexão e tenta novamente.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = isDarkModeNotifier.value;
    final bg = isDark ? Colors.black : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1C1C1E);

    return Scaffold(
      backgroundColor: bg,
      appBar: _analisando ? AppBar(
        backgroundColor: bg, elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context)),
        title: Text(appLang.screenshotTitle,
            style: TextStyle(color: textColor, fontWeight: FontWeight.w700)),
      ) : null,
      body: _erro
          ? _buildErro(isDark)
          : _analisando
              ? _buildScanView()
              : const SizedBox.shrink(),
    );
  }

  Widget _buildScanView() {
    return Column(
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_imagemSelecionada != null)
                Image.file(_imagemSelecionada!, fit: BoxFit.cover),
              Container(color: Colors.black.withOpacity(0.45)),
              AnimatedBuilder(
                animation: _scanAnim,
                builder: (context, _) {
                  final w = MediaQuery.of(context).size.width;
                  return Positioned(
                    top: 0, bottom: 0,
                    left: _scanAnim.value * w,
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 20, decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          Colors.transparent,
                          const Color(0xFFFF2D55).withOpacity(0.12)]))),
                      Container(width: 2, color: const Color(0xFFFF2D55)),
                      Container(width: 20, decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          const Color(0xFFFF2D55).withOpacity(0.12),
                          Colors.transparent]))),
                    ]),
                  );
                },
              ),
              Positioned(top: 16, left: 16, child: _corner(top: true, left: true)),
              Positioned(top: 16, right: 16, child: _corner(top: true, left: false)),
              Positioned(bottom: 16, left: 16, child: _corner(top: false, left: true)),
              Positioned(bottom: 16, right: 16, child: _corner(top: false, left: false)),
            ],
          ),
        ),
        Container(
          color: Colors.black,
          padding: EdgeInsets.fromLTRB(24, 20, 24,
              MediaQuery.of(context).padding.bottom + 20),
          child: Column(children: [
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => Opacity(
                opacity: _pulseAnim.value,
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(width: 7, height: 7,
                      decoration: const BoxDecoration(
                          color: Color(0xFFFF2D55), shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  const Text("AI analyzing...", style: TextStyle(
                      color: Color(0xFFFF2D55), fontSize: 13,
                      fontWeight: FontWeight.w600, letterSpacing: 0.3)),
                ]),
              ),
            ),
            const SizedBox(height: 6),
            Text(appLang.screenshotAnalyzingSub, textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white38, fontSize: 12, height: 1.4)),
          ]),
        ),
      ],
    );
  }

  Widget _corner({required bool top, required bool left}) {
    return SizedBox(width: 18, height: 18,
        child: CustomPaint(painter: _CornerPainter(top: top, left: left)));
  }

  Widget _buildErro(bool isDark) {
    final textColor = isDark ? Colors.white70 : Colors.black54;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text("😕", style: TextStyle(fontSize: 52)),
          const SizedBox(height: 20),
          Text(_erroMsg, textAlign: TextAlign.center,
              style: TextStyle(color: textColor, fontSize: 15, height: 1.5)),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              setState(() { _erro = false; _analisando = false; _imagemSelecionada = null; });
              _processarImagem();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF2D55), foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: Text(appLang.errorRetry),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(appLang.errorBack,
                style: TextStyle(color: textColor.withOpacity(0.5))),
          ),
        ]),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final bool top, left;
  _CornerPainter({required this.top, required this.left});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF2D55)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path();
    if (top && left) { path.moveTo(0, size.height); path.lineTo(0, 0); path.lineTo(size.width, 0); }
    else if (top && !left) { path.moveTo(0, 0); path.lineTo(size.width, 0); path.lineTo(size.width, size.height); }
    else if (!top && left) { path.moveTo(0, 0); path.lineTo(0, size.height); path.lineTo(size.width, size.height); }
    else { path.moveTo(0, size.height); path.lineTo(size.width, size.height); path.lineTo(size.width, 0); }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}