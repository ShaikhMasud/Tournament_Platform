import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

import '../providers/results_providers.dart';

class ResultsScreen extends ConsumerStatefulWidget {
  const ResultsScreen({super.key, required this.tournamentId, required this.tournamentName});

  final String tournamentId;
  final String tournamentName;

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  bool _isDownloading = false;

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(tournamentResultsProvider(widget.tournamentId));

    return Scaffold(
      appBar: AppBar(title: Text('Results — ${widget.tournamentName}')),
      body: resultsAsync.when(
        data: (doc) {
          if (doc == null) {
            return const Center(child: Text('No results available.'));
          }
          return _buildDocumentView(doc);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Error: $e', style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(tournamentResultsProvider(widget.tournamentId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentView(dynamic doc) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _iconForStatus(doc.status),
              size: 80,
              color: _colorForStatus(doc.status),
            ),
            const SizedBox(height: 24),
            Text(
              _titleForStatus(doc.status),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _subtitleForStatus(doc.status),
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (doc.isReady) ...[
              ElevatedButton.icon(
                onPressed: _isDownloading ? null : () => _downloadPdf(doc.downloadUrl!),
                icon: _isDownloading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download),
                label: Text(_isDownloading ? 'Downloading...' : 'Download PDF'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 48),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => ref.read(tournamentResultsProvider(widget.tournamentId).notifier).request(),
                icon: const Icon(Icons.refresh),
                label: const Text('Regenerate'),
              ),
            ] else if (doc.isPending) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(tournamentResultsProvider(widget.tournamentId).notifier).checkStatus(),
                child: const Text('Check Status'),
              ),
            ] else if (doc.isFailed) ...[
              Text(doc.errorMessage ?? 'Unknown error', style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.read(tournamentResultsProvider(widget.tournamentId).notifier).request(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _downloadPdf(String url) async {
    setState(() => _isDownloading = true);
    try {
      final dio = Dio();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/results_${widget.tournamentName}.pdf');
      await dio.download(url, file.path);
      await OpenFilex.open(file.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  IconData _iconForStatus(String status) {
    switch (status) {
      case 'ready':
        return Icons.picture_as_pdf;
      case 'pending':
      case 'generating':
        return Icons.hourglass_empty;
      case 'failed':
        return Icons.error_outline;
      default:
        return Icons.description;
    }
  }

  Color _colorForStatus(String status) {
    switch (status) {
      case 'ready':
        return Colors.green;
      case 'pending':
      case 'generating':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _titleForStatus(String status) {
    switch (status) {
      case 'ready':
        return 'Results PDF Ready!';
      case 'pending':
        return 'PDF Generation Pending';
      case 'generating':
        return 'Generating PDF...';
      case 'failed':
        return 'Generation Failed';
      default:
        return 'Unknown Status';
    }
  }

  String _subtitleForStatus(String status) {
    switch (status) {
      case 'ready':
        return 'Your results PDF is ready for download.';
      case 'pending':
        return 'Your results are being processed. Please wait.';
      case 'generating':
        return 'This may take a moment...';
      case 'failed':
        return 'An error occurred. Please try again.';
      default:
        return '';
    }
  }
}
