import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

Future<void> openReportPdf(BuildContext context, String base64Pdf) async {
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);

  if (base64Pdf.isEmpty) {
    messenger.showSnackBar(const SnackBar(content: Text('Report PDF was not generated.')));
    return;
  }

  try {
    base64Decode(base64Pdf);
    await navigator.push(
      MaterialPageRoute(
        settings: const RouteSettings(name: '/report-ready'),
        builder: (_) => ReportReadyPage(base64Pdf: base64Pdf),
      ),
    );
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('Unable to open report PDF: $e')));
  }
}

class ReportReadyPage extends StatefulWidget {
  final String base64Pdf;
  const ReportReadyPage({required this.base64Pdf, super.key});

  @override
  State<ReportReadyPage> createState() => _ReportReadyPageState();
}

class _ReportReadyPageState extends State<ReportReadyPage> {
  late final PdfDocumentRefData _documentRef;

  @override
  void initState() {
    super.initState();
    final bytes = base64Decode(widget.base64Pdf);
    _documentRef = PdfDocumentRefData(bytes, sourceName: 'report-pdf-${DateTime.now().microsecondsSinceEpoch}', allowDataOwnershipTransfer: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report PDF')),
      body: PdfDocumentViewBuilder(
        documentRef: _documentRef,
        builder: (context, document) {
          if (document == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final pageCount = document.pages.length;
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            itemCount: pageCount,
            itemBuilder: (context, index) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Page ${index + 1}/$pageCount', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 520,
                    child: PdfPageView(document: document, pageNumber: index + 1),
                  ),
                  const SizedBox(height: 24),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
