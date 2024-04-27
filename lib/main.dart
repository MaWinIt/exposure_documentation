import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:exposure_documentation/diagramm_painter.dart';
import 'package:exposure_documentation/exposure_mode.dart';
import 'package:exposure_documentation/exposure_questions.dart';
import 'package:exposure_documentation/input_block.dart';
import 'package:flutter/material.dart';
import 'package:flutter_signature_pad/flutter_signature_pad.dart';
import 'package:flutter_to_pdf/flutter_to_pdf.dart';

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
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.dark,
        ),
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

  ExportDelegate delegate = ExportDelegate();
  final String resultFrameId = 'frame-id';

  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose(); // Vergessen Sie nicht, die FocusNode zu löschen
    super.dispose();
  }

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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: switch (modeOrder[currentModeIndex]) {
              ExposureMode.preparation => buildInputBlock(
                  onChanged: (answer) =>
                      setCurrentPreparationAnswer(answer: answer),
                  question: preparationQuestions[currentPreparationIndex],
                ),
              ExposureMode.intensityDiagramm => buildIntensityDiagrammScreen(),
              ExposureMode.postProcessing => buildInputBlock(
                  onChanged: (answer) =>
                      setCurrentPostProcessionAnswer(answer: answer),
                  question: postProcessingQuestions[currentPostProcessingIndex],
                ),
              ExposureMode.save => buildEndScreen(),
            },
          ),
        ),
      ),
    );
  }

  Widget buildInputBlock({
    required final String question,
    required final void Function(String)? onChanged,
  }) =>
      Column(
        children: [
          Text(
            question,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: onChanged,
            keyboardType: TextInputType.multiline,
            maxLines: null,
            controller: _controller,
            textInputAction: TextInputAction.done,
            autofocus: true,
            onSubmitted: (value) {
              next();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _focusNode.requestFocus();
              });
            },
            focusNode: _focusNode,
          ),
          const SizedBox(height: 12),
          buildNextButton(),
        ],
      );

  Widget buildNextButton() => ElevatedButton(
        onPressed: () {
          next();
        },
        child: const Text('Weiter'),
      );

  Widget buildIntensityDiagrammScreen() => SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Trage in diesem Diagramm ein, wie der Angstverlauf über die Zeit hinweg war',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox.square(
                  dimension: min(MediaQuery.of(context).size.width,
                          MediaQuery.of(context).size.height) *
                      0.8,
                  child: Signature(
                    strokeWidth: 1,
                    color: Colors.black,
                    key: _sign,
                    backgroundPainter: DiagrammPainter(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () {
                    _sign.currentState?.clear();
                  },
                  child: const Text('Löschen'),
                ),
                buildNextButton(),
              ],
            ),
          ],
        ),
      );

  Widget buildEndScreen() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const Text(
            'Du hast die Dokumentation abgeschlossen. Du kannst sie hier auf deinem Gerät speichern. Verlässt du die Seite, gehen die Daten unwideruflich verloren.',
          ),
          const SizedBox(height: 12),
          buildResult(imageBytes),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () async {
              var bytes = imageBytes;
              final pdf = pw.Document();
              pdf.addPage(
                pw.MultiPage(
                  build: (context) => [
                    pw.Center(
                      child: pw.Text(
                        'Vorbereitung',
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    ...preparation.expand(
                      (input) => [
                        pw.Text(
                          input.question,
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(input.answer),
                        pw.SizedBox(height: 16),
                      ],
                    ),
                  ],
                ),
              );
              pdf.addPage(
                pw.MultiPage(
                  build: (context) => [
                    pw.Center(
                      child: pw.Text(
                        'Nachbereitung',
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    ...bytes != null
                        ? [
                            pw.Image(
                              pw.MemoryImage(bytes),
                              height: 200,
                              width: 200,
                            ),
                            pw.SizedBox(height: 16),
                          ]
                        : [],
                    ...postProcessing.expand(
                      (input) => [
                        pw.Text(
                          input.question,
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(input.answer),
                        pw.SizedBox(height: 16),
                      ],
                    ),
                  ],
                ),
              );

              var savedFile = await pdf.save();
              List<int> fileInts = List.from(savedFile);
              AnchorElement(
                  href:
                      "data:application/octet-stream;charset=utf-16le;base64,${base64.encode(fileInts)}")
                ..setAttribute(
                    "download", "${DateTime.now().millisecondsSinceEpoch}.pdf")
                ..click();
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  Widget buildResult(Uint8List? bytes) => ExportFrame(
        exportDelegate: delegate,
        frameId: resultFrameId,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'Vorbereitung',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...preparation.expand(
              (input) => [
                Text(
                  input.question,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(input.answer),
                const SizedBox(height: 16),
              ],
            ),
            const Center(
              child: Text(
                'Nachbereitung',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...bytes != null
                ? [
                    Center(
                      child: Container(
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Image.memory(bytes),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ]
                : [],
            ...postProcessing.expand(
              (input) => [
                Text(
                  input.question,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(input.answer),
                const SizedBox(height: 16),
              ],
            ),
          ],
        ),
      );
}
