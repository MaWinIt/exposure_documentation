import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html';
import 'dart:typed_data';
import 'dart:ui';

import 'package:exposure_documentation/exposure_mode.dart';
import 'package:exposure_documentation/exposure_questions.dart';
import 'package:exposure_documentation/input_block.dart';
import 'package:flutter/material.dart';
import 'package:flutter_signature_pad/flutter_signature_pad.dart';

import 'package:pdf/widgets.dart' as pw;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<InputBlock> preparation = preparationQuestions
      .map((question) => InputBlock(question: question, answer: ''))
      .toList();
  int currentPreparationIndex = 0;

  List<InputBlock> postProcessing = postProcessingQuestions
      .map((question) => InputBlock(question: question, answer: ''))
      .toList();
  int currentPostProcessingIndex = 0;

  List<ExposureMode> modeOrder = [
    ExposureMode.preparation,
    ExposureMode.intensityDiagramm,
    ExposureMode.postProcessing,
    ExposureMode.save,
  ];
  int currentModeIndex = 0;

  final TextEditingController _controller = TextEditingController();
  final GlobalKey<SignatureState> _sign = GlobalKey<SignatureState>();
  Uint8List? imageBytes;

  void next() async {
    _controller.clear();
    switch (modeOrder[currentModeIndex]) {
      case ExposureMode.preparation:
        if (currentPreparationIndex + 1 < preparation.length) {
          increasePreparationIndex();
        } else {
          increaseCurrentModeIndex();
        }
      case ExposureMode.intensityDiagramm:
        imageBytes = (await (await _sign.currentState?.getData())
                ?.toByteData(format: ImageByteFormat.png))
            ?.buffer
            .asUint8List();
        increaseCurrentModeIndex();
      case ExposureMode.postProcessing:
        if (currentPostProcessingIndex + 1 < postProcessing.length) {
          increasePostProcessionIndex();
        } else {
          increaseCurrentModeIndex();
        }
      case ExposureMode.save:
    }
  }

  void increasePreparationIndex() {
    setState(() {
      currentPreparationIndex++;
    });
  }

  void setCurrentPreparationAnswer({required final String answer}) {
    setState(() {
      preparation[currentPreparationIndex].answer = answer;
    });
  }

  void increasePostProcessionIndex() {
    setState(() {
      currentPostProcessingIndex++;
    });
  }

  void setCurrentPostProcessionAnswer({required final String answer}) {
    setState(() {
      postProcessing[currentPostProcessingIndex].answer = answer;
    });
  }

  void increaseCurrentModeIndex() {
    setState(() {
      currentModeIndex++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Exposure documentation'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            children: switch (modeOrder[currentModeIndex]) {
              ExposureMode.preparation => buildInputBlock(
                  onChanged: (answer) =>
                      setCurrentPreparationAnswer(answer: answer),
                  question: preparationQuestions[currentPreparationIndex],
                ),
              ExposureMode.intensityDiagramm => buildIntensityDiagrammScreen(),
              ExposureMode.postProcessing => buildInputBlock(
                  onChanged: (answer) =>
                      setCurrentPreparationAnswer(answer: answer),
                  question: postProcessingQuestions[currentPostProcessingIndex],
                ),
              ExposureMode.save => buildEndScreen(),
            },
          ),
        ),
      ),
    );
  }

  List<Widget> buildInputBlock({
    required final String question,
    required final void Function(String)? onChanged,
  }) =>
      [
        Text(question),
        const SizedBox(height: 12),
        TextField(
          onChanged: onChanged,
          keyboardType: TextInputType.multiline,
          maxLines: null,
          controller: _controller,
        ),
        const SizedBox(height: 12),
        Expanded(child: Container()),
        buildNextButton(),
      ];

  Widget buildNextButton() => ElevatedButton(
        onPressed: () {
          next();
        },
        child: const Text('Weiter'),
      );

  List<Widget> buildIntensityDiagrammScreen() => [
        Expanded(
          child: Signature(
            strokeWidth: 0.5,
            color: Colors.black,
            onSign: () {
              final sign = _sign.currentState;
              debugPrint('${sign?.points.length} points in the signature');
            },
            key: _sign,
          ),
        ),
        buildNextButton(),
      ];

  List<Widget> buildEndScreen() => [
        const Text(
          'Du hast die Dokumentation abgeschlossen. Du kannst sie hier auf deinem Gerät speichern. Verlässt du die Seite, gehen die Daten unwideruflich verloren.',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            ElevatedButton(
              onPressed: () {
                _sign.currentState?.clear();
              },
              child: const Text('Löschen'),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () async {
                var bytes = imageBytes;
                final pdf = pw.Document();
                pdf.addPage(
                  pw.Page(
                    build: (context) => pw.Column(
                      children: [
                        pw.Center(
                          child: pw.Text('Vorbereitung'),
                        ),
                        ...preparation.expand(
                          (input) => [
                            pw.Text(input.question),
                            pw.Text(input.answer),
                          ],
                        ),
                        pw.Center(
                          child: pw.Text('Nachbereitung'),
                        ),
                        bytes != null
                            ? pw.Image(pw.MemoryImage(bytes))
                            : pw.Container(),
                        ...postProcessing.expand(
                          (input) => [
                            pw.Text(input.question),
                            pw.Text(input.answer),
                          ],
                        ),
                      ],
                    ),
                  ),
                );

                var savedFile = await pdf.save();
                List<int> fileInts = List.from(savedFile);
                AnchorElement(
                    href:
                        "data:application/octet-stream;charset=utf-16le;base64,${base64.encode(fileInts)}")
                  ..setAttribute("download",
                      "${DateTime.now().millisecondsSinceEpoch}.pdf")
                  ..click();
              },
              child: const Text('Speichern'),
            ),
          ],
        ),
      ];
}
