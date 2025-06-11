import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:placar_iterativo_app/models/team.dart';
import 'package:placar_iterativo_app/services/backup_service.dart';
import 'package:placar_iterativo_app/providers/teams_provider.dart';
import 'package:placar_iterativo_app/providers/tournament_provider.dart';
import 'package:placar_iterativo_app/utils/responsive_utils.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final BackupService _backupService = BackupService();
  late TeamsNotifier _teamsNotifier;
  late TournamentNotifier _tournamentNotifier;
  bool _isLoading = false;
  String? _statusMessage;
  bool _importTournaments = true;

  @override
  void initState() {
    super.initState();
    _teamsNotifier = Modular.get<TeamsNotifier>();
    _tournamentNotifier = Modular.get<TournamentNotifier>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup e Restauração'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: ResponsiveUtils.getPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildExportSection(),
            const SizedBox(height: 32),
            _buildImportSection(),
            const SizedBox(height: 24),
            if (_statusMessage != null) _buildStatusMessage(),
            if (_isLoading) _buildLoadingIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              Icons.backup,
              size: 48,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 8),
            Text(
              'Sistema de Backup',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Exporte seus dados para usar em outros dispositivos ou faça backup de segurança.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.upload,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Exportar Dados',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _exportTeamsOnly,
                icon: const Icon(Icons.group),
                label: const Text('Exportar Apenas Times'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _exportComplete,
                icon: const Icon(Icons.backup),
                label: const Text('Exportar Tudo (Times + Torneios)'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.download,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Importar Dados',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _importTeams,
                icon: const Icon(Icons.group),
                label: const Text('Importar Times'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    _isLoading ? null : () => _showImportCompleteDialog(),
                icon: const Icon(Icons.restore),
                label: const Text('Importar Tudo'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusMessage() {
    return Card(
      color:
          _statusMessage!.contains('Erro') ? Colors.red[50] : Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              _statusMessage!.contains('Erro')
                  ? Icons.error
                  : Icons.check_circle,
              color:
                  _statusMessage!.contains('Erro') ? Colors.red : Colors.green,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _statusMessage!,
                style: TextStyle(
                  color: _statusMessage!.contains('Erro')
                      ? Colors.red[800]
                      : Colors.green[800],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Processando...'),
          ],
        ),
      ),
    );
  }

  Future<void> _exportTeamsOnly() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final exportResult = await _backupService.exportTeamsOnly();
      final jsonContent = exportResult['jsonContent'] as String;
      final teams = exportResult['teams'] as List<Team>;
      final filename =
          'teams_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final filePath =
          await _backupService.saveBackupFile(jsonContent, filename, teams);

      setState(() {
        _statusMessage =
            'Times exportados com sucesso!\nArquivo salvo em: $filePath';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Erro ao exportar times: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _exportComplete() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final exportResult = await _backupService.exportComplete();
      final jsonContent = exportResult['jsonContent'] as String;
      final teams = exportResult['teams'] as List<Team>;
      final filename =
          'complete_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final filePath =
          await _backupService.saveBackupFile(jsonContent, filename, teams);

      setState(() {
        _statusMessage =
            'Backup completo exportado com sucesso!\nArquivo salvo em: $filePath';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Erro ao exportar backup completo: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _importTeams() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'zip'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _isLoading = true;
          _statusMessage = null;
        });

        final file = File(result.files.single.path!);
        final importResult = await _backupService.importTeamsFromFile(file);

        // Reload teams to update the UI
        if (importResult.success) {
          await _teamsNotifier.reloadTeams();
        }

        setState(() {
          _statusMessage = importResult.message;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Erro ao importar times: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showImportCompleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Importar Backup Completo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Selecione o que deseja importar:'),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Times'),
              subtitle: const Text('Obrigatório'),
              value: true,
              onChanged: null, // Desabilitado
              controlAffinity: ListTileControlAffinity.leading,
            ),
            CheckboxListTile(
              title: const Text('Torneios'),
              subtitle: const Text('Opcional'),
              value: _importTournaments,
              onChanged: (value) {
                setState(() {
                  _importTournaments = value!;
                });
                Navigator.of(context).pop();
                _showImportCompleteDialog();
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _importComplete();
            },
            child: const Text('Importar'),
          ),
        ],
      ),
    );
  }

  Future<void> _importComplete() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'zip'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _isLoading = true;
          _statusMessage = null;
        });

        final file = File(result.files.single.path!);
        final importResult = await _backupService.importCompleteFromFile(
          file,
          importTournaments: _importTournaments,
        );

        setState(() {
          _statusMessage = importResult.message;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Erro ao importar backup: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
