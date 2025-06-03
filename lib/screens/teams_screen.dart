import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:placar_iterativo_app/models/team.dart';
import 'package:placar_iterativo_app/providers/teams_provider.dart';

class TeamsScreen extends StatefulWidget {
  const TeamsScreen({super.key});

  @override
  State<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends State<TeamsScreen> {
  late TeamsNotifier teamsNotifier;

  @override
  void initState() {
    super.initState();
    teamsNotifier = Modular.get<TeamsNotifier>();
    teamsNotifier.addListener(_onTeamsChanged);
  }

  void _onTeamsChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    teamsNotifier.removeListener(_onTeamsChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Gerenciar Times',
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTeamDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (teamsNotifier.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (teamsNotifier.error != null) {
      return Center(
        child: Text('Erro: ${teamsNotifier.error}'),
      );
    }

    final teams = teamsNotifier.teams;
    final teamsList = teams.values.toList();

    if (teamsList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sports_soccer, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Nenhum time cadastrado',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Toque no botão + para adicionar um time',
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return _buildTeamsList(teamsList);
  }

  Widget _buildTeamsList(List<Team> teamsList) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: teamsList.length,
      itemBuilder: (context, index) {
        final team = teamsList[index];
        return _buildTeamCard(context, team);
      },
    );
  }

  Widget _buildTeamCard(BuildContext context, Team team) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: team.color.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: team.color, width: 2),
          ),
          child: Center(
            child: team.imagePath != null
                ? ClipOval(
                    child: Image.file(
                      File(team.imagePath!),
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Text(
                          team.emoji ?? '🏆',
                          style: const TextStyle(fontSize: 24),
                        );
                      },
                    ),
                  )
                : Text(
                    team.emoji ?? '🏆',
                    style: const TextStyle(fontSize: 24),
                  ),
          ),
        ),
        title: Text(
          team.name,
          style: GoogleFonts.roboto(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            if (team.members.isNotEmpty) ...[
              Text(
                'Integrantes: ${team.members.join(', ')}',
                style: GoogleFonts.roboto(fontSize: 14),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              'Vitórias: ${team.wins} | Derrotas: ${team.losses}',
              style: GoogleFonts.roboto(fontSize: 14),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showTeamDialog(context, team),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _showDeleteConfirmation(context, team),
            ),
          ],
        ),
      ),
    );
  }

  void _showTeamDialog(BuildContext context, [Team? team]) {
    final isEditing = team != null;
    final nameController = TextEditingController(text: team?.name ?? '');
    final membersController = TextEditingController(
        text: team?.members.isNotEmpty == true ? team!.members.join(', ') : '');

    String? selectedEmoji = team?.emoji ?? '🏆';
    String? selectedImagePath = team?.imagePath;
    Color selectedColor = team?.color ?? Colors.blue;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(isEditing ? 'Editar Time' : 'Novo Time'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome do Time',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: membersController,
                    decoration: const InputDecoration(
                      labelText: 'Integrantes (separados por vírgula)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Ícone do Time',
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Emoji option
                      ElevatedButton(
                        onPressed: () => _showEmojiPicker(context, (emoji) {
                          setState(() {
                            selectedEmoji = emoji;
                            selectedImagePath = null;
                          });
                        }),
                        child: const Text('Escolher Emoji'),
                      ),
                      // Image option
                      ElevatedButton(
                        onPressed: () => _pickImage().then((path) {
                          if (path != null) {
                            setState(() {
                              selectedImagePath = path;
                              selectedEmoji = null;
                            });
                          }
                        }),
                        child: const Text('Escolher Imagem'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Preview of selected icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: selectedColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: selectedColor, width: 2),
                    ),
                    child: Center(
                      child: selectedImagePath != null
                          ? ClipOval(
                              child: Image.file(
                                File(selectedImagePath!),
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Text(
                                    selectedEmoji ?? '🏆',
                                    style: const TextStyle(fontSize: 36),
                                  );
                                },
                              ),
                            )
                          : Text(
                              selectedEmoji ?? '🏆',
                              style: const TextStyle(fontSize: 36),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Cor do Time',
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Color picker button
                  ElevatedButton(
                    onPressed: () =>
                        _showColorPicker(context, selectedColor, (color) {
                      setState(() {
                        selectedColor = color;
                      });
                    }),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedColor,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: Text(
                      'Selecionar Cor',
                      style: GoogleFonts.roboto(
                        color: selectedColor.computeLuminance() > 0.5
                            ? Colors.black
                            : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Nome do time é obrigatório')),
                    );
                    return;
                  }

                  final members = membersController.text.isEmpty
                      ? <String>[]
                      : membersController.text
                          .split(',')
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .toList();

                  // teamsNotifier is already available as instance variable

                  if (isEditing) {
                    final updatedTeam = team.copyWith(
                      name: name,
                      members: members,
                      emoji: selectedEmoji,
                      imagePath: selectedImagePath,
                      color: selectedColor,
                    );
                    teamsNotifier.updateTeam(updatedTeam);
                  } else {
                    teamsNotifier.createTeam(
                      name: name,
                      members: members,
                      emoji: selectedEmoji,
                      imagePath: selectedImagePath,
                      color: selectedColor,
                    );
                  }

                  Navigator.pop(context);
                },
                child: Text(isEditing ? 'Salvar' : 'Criar'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEmojiPicker(
      BuildContext context, Function(String) onEmojiSelected) {
    final commonEmojis = [
      '🏆',
      '⚽',
      '🏀',
      '🏈',
      '⚾',
      '🥎',
      '🎾',
      '🏐',
      '🏉',
      '🥏',
      '🎱',
      '🏓',
      '🏸',
      '🏒',
      '🏑',
      '🥍',
      '🏏',
      '⛳',
      '🥊',
      '🥋',
      '🎽',
      '🛹',
      '🛼',
      '🛷',
      '⛸️',
      '🥌',
      '🎯',
      '🪀',
      '🪁',
      '🎮',
      '🐶',
      '🐱',
      '🐭',
      '🐹',
      '🐰',
      '🦊',
      '🐻',
      '🐼',
      '🐨',
      '🐯',
      '🦁',
      '🐮',
      '🐷',
      '🐸',
      '🐵',
      '🐔',
      '🐧',
      '🐦',
      '🦆',
      '🦅',
      '🦉',
      '🦇',
      '🐺',
      '🐗',
      '🐴',
      '🦄',
      '🐝',
      '🐛',
      '🦋',
      '🐌',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Escolha um Emoji'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              childAspectRatio: 1,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: commonEmojis.length,
            itemBuilder: (context, index) {
              return InkWell(
                onTap: () {
                  onEmojiSelected(commonEmojis[index]);
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      commonEmojis[index],
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Future<String?> _pickImage() async {
    try {
      if (Theme.of(context).platform == TargetPlatform.android) {
        final ImagePicker picker = ImagePicker();
        final XFile? image =
            await picker.pickImage(source: ImageSource.gallery);
        return image?.path;
      } else {
        // For Windows
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
        );
        return result?.files.single.path;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao selecionar imagem: $e')),
      );
      return null;
    }
  }

  void _showColorPicker(BuildContext context, Color currentColor,
      Function(Color) onColorSelected) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Escolha uma cor'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: currentColor,
            onColorChanged: onColorSelected,
            pickerAreaHeightPercent: 0.8,
            enableAlpha: false,
            displayThumbColor: true,
            paletteType: PaletteType.hsv,
            pickerAreaBorderRadius: const BorderRadius.all(Radius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Selecionar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Team team) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Time'),
        content: Text('Tem certeza que deseja excluir o time ${team.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              teamsNotifier.deleteTeam(team.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}
