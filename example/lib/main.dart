import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:missing_plugin_exception_detective/missing_plugin_exception_detective.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _detective = MissingPluginExceptionDetective();
  DiagnosticResult? _lastResult;
  bool _isScanning = false;
  bool _isMonitoring = false;
  StreamSubscription<PluginIssue>? _monitoringSubscription;
  final List<PluginIssue> _runtimeIssues = [];

  @override
  void initState() {
    super.initState();
    _runInitialScan();
  }

  @override
  void dispose() {
    _monitoringSubscription?.cancel();
    super.dispose();
  }

  Future<void> _runInitialScan() async {
    setState(() {
      _isScanning = true;
    });

    try {
      final result = await _detective.diagnose(
        projectPath: Directory.current.path,
        includeResolutions: true,
      );
      
      setState(() {
        _lastResult = result;
        _isScanning = false;
      });
    } catch (e) {
      setState(() {
        _isScanning = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Scan failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startMonitoring() {
    if (_isMonitoring) return;

    setState(() {
      _isMonitoring = true;
      _runtimeIssues.clear();
    });

    _monitoringSubscription = _detective.monitorRuntime().listen(
      (issue) {
        setState(() {
          _runtimeIssues.add(issue);
        });
      },
      onError: (error) {
        setState(() {
          _isMonitoring = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Monitoring failed: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );
  }

  void _stopMonitoring() {
    _monitoringSubscription?.cancel();
    _monitoringSubscription = null;
    setState(() {
      _isMonitoring = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Missing Plugin Exception Detective',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin Detective Demo'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildControlButtons(),
              const SizedBox(height: 20),
              Expanded(
                child: _buildResultsSection(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Missing Plugin Exception Detective',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Detect, analyze, and resolve Flutter plugin initialization issues',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButtons() {
    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: _isScanning ? null : _runInitialScan,
          icon: _isScanning 
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.search),
          label: Text(_isScanning ? 'Scanning...' : 'Run Scan'),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: _isMonitoring ? _stopMonitoring : _startMonitoring,
          icon: Icon(_isMonitoring ? Icons.stop : Icons.monitor),
          label: Text(_isMonitoring ? 'Stop Monitoring' : 'Start Monitoring'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _isMonitoring ? Colors.red : Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildResultsSection() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Static Analysis', icon: Icon(Icons.analytics)),
              Tab(text: 'Runtime Monitoring', icon: Icon(Icons.monitor_heart)),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildStaticAnalysisTab(),
                _buildRuntimeMonitoringTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaticAnalysisTab() {
    if (_lastResult == null) {
      return const Center(
        child: Text('No scan results yet. Run a scan to see results.'),
      );
    }

    final result = _lastResult!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(result),
          const SizedBox(height: 16),
          if (result.issues.isNotEmpty) _buildIssuesSection(result.issues),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(DiagnosticResult result) {
    final statusColor = result.status == DiagnosticStatus.healthy 
      ? Colors.green 
      : result.status == DiagnosticStatus.warning 
        ? Colors.orange 
        : Colors.red;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  result.status == DiagnosticStatus.healthy 
                    ? Icons.check_circle 
                    : Icons.warning,
                  color: statusColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Status: ${result.status.name.toUpperCase()}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildSummaryRow('Scanned Plugins', '${result.scannedPlugins.length}'),
            _buildSummaryRow('Issues Found', '${result.issues.length}'),
            _buildSummaryRow('Scan Duration', '${result.scanDuration.inMilliseconds}ms'),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildIssuesSection(List<PluginIssue> issues) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Issues Found (${issues.length})',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...issues.map((issue) => _buildIssueCard(issue)),
      ],
    );
  }

  Widget _buildIssueCard(PluginIssue issue) {
    final severityColor = issue.severity == IssueSeverity.critical 
      ? Colors.red 
      : issue.severity == IssueSeverity.high 
        ? Colors.orange 
        : issue.severity == IssueSeverity.medium 
          ? Colors.yellow[700] 
          : Colors.blue;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ExpansionTile(
        leading: Icon(
          Icons.warning,
          color: severityColor,
        ),
        title: Text(
          issue.pluginName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(issue.description),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIssueDetail('Type', issue.issueType.name),
                _buildIssueDetail('Severity', issue.severity.name),
                _buildIssueDetail('Platforms', issue.affectedPlatforms.join(', ')),
                if (issue.resolutionSteps != null && issue.resolutionSteps!.isNotEmpty)
                  _buildResolutionSteps(issue.resolutionSteps!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIssueDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildResolutionSteps(List<ResolutionStep> steps) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Text(
          'Resolution Steps:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        ...steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Text('${index + 1}. ${step.title}: ${step.description}'),
          );
        }),
      ],
    );
  }

  Widget _buildRuntimeMonitoringTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isMonitoring ? Icons.monitor_heart : Icons.monitor_heart_outlined,
                color: _isMonitoring ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                _isMonitoring ? 'Monitoring Active' : 'Monitoring Inactive',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _isMonitoring ? Colors.green : Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Runtime Issues Detected (${_runtimeIssues.length})',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _runtimeIssues.isEmpty
              ? Center(
                  child: Text(
                    _isMonitoring 
                      ? 'No runtime issues detected yet...' 
                      : 'Start monitoring to detect runtime issues',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
              : ListView.builder(
                  itemCount: _runtimeIssues.length,
                  itemBuilder: (context, index) {
                    return _buildIssueCard(_runtimeIssues[index]);
                  },
                ),
          ),
        ],
      ),
    );
  }
}
