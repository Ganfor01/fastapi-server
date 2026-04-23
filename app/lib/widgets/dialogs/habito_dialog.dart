import 'package:flutter/material.dart';

class HabitoData {
  const HabitoData({
    required this.titulo,
    required this.detalle,
    required this.prioridad,
    required this.duracionMinutos,
    required this.sesionesPorSemana,
  });

  final String titulo;
  final String detalle;
  final int prioridad;
  final int duracionMinutos;
  final int sesionesPorSemana;
}

class HabitoDialog extends StatefulWidget {
  const HabitoDialog({super.key});

  @override
  State<HabitoDialog> createState() => _HabitoDialogState();
}

class _HabitoDialogState extends State<HabitoDialog> {
  static const _templates = [
    _HabitTemplate(
      label: 'Gym',
      title: 'Gym',
      detail: 'Fuerza, cardio o movilidad',
      duration: 60,
      sessions: 3,
      priority: 4,
      icon: Icons.fitness_center_rounded,
    ),
    _HabitTemplate(
      label: 'Leer',
      title: 'Leer',
      detail: 'Lectura tranquila para avanzar un poco cada semana',
      duration: 30,
      sessions: 4,
      priority: 3,
      icon: Icons.menu_book_rounded,
    ),
    _HabitTemplate(
      label: 'Estudiar',
      title: 'Estudiar',
      detail: 'Repasar, practicar o avanzar en una materia concreta',
      duration: 90,
      sessions: 4,
      priority: 5,
      icon: Icons.school_rounded,
    ),
    _HabitTemplate(
      label: 'Caminar',
      title: 'Caminar',
      detail: 'Salir a caminar para despejarte y moverte un poco',
      duration: 45,
      sessions: 5,
      priority: 3,
      icon: Icons.directions_walk_rounded,
    ),
  ];

  final _tituloController = TextEditingController();
  final _detalleController = TextEditingController();
  String? _error;
  int _prioridad = 3;
  int _duracion = 60;
  int _sesiones = 3;
  String? _selectedTemplate;

  @override
  void dispose() {
    _tituloController.dispose();
    _detalleController.dispose();
    super.dispose();
  }

  void _aplicarTemplate(_HabitTemplate template) {
    setState(() {
      _selectedTemplate = template.label;
      _tituloController.text = template.title;
      _detalleController.text = template.detail;
      _prioridad = template.priority;
      _duracion = template.duration;
      _sesiones = template.sessions;
      _error = null;
    });
  }

  void _guardar() {
    final titulo = _tituloController.text.trim();
    if (titulo.length < 3) {
      setState(() {
        _error = 'El título debe tener al menos 3 caracteres';
      });
      return;
    }

    Navigator.of(context).pop(
      HabitoData(
        titulo: titulo,
        detalle: _detalleController.text.trim(),
        prioridad: _prioridad,
        duracionMinutos: _duracion,
        sesionesPorSemana: _sesiones,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: const Text('Nuevo hábito'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Empieza rápido con una plantilla o personalízalo a tu gusto.',
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: isDark
                    ? const Color(0xFF98A2B3)
                    : const Color(0xFF667085),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _templates
                  .map(
                    (template) => ChoiceChip(
                      selected: _selectedTemplate == template.label,
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(template.icon, size: 16),
                          const SizedBox(width: 6),
                          Text(template.label),
                        ],
                      ),
                      onSelected: (_) => _aplicarTemplate(template),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _tituloController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Título',
                hintText: 'Ej: Entrenar',
                errorText: _error,
              ),
              onChanged: (_) {
                if (_error != null) {
                  setState(() {
                    _error = null;
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _detalleController,
              decoration: const InputDecoration(
                labelText: 'Detalle',
                hintText: 'Ej: fuerza o correr',
              ),
              minLines: 1,
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _prioridad,
                    decoration: const InputDecoration(labelText: 'Prioridad'),
                    items: const [1, 2, 3, 4, 5]
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text('$item/5'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _prioridad = value;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _duracion,
                    decoration: const InputDecoration(labelText: 'Duración'),
                    items: const [30, 45, 60, 90, 120]
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text('$item min'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _duracion = value;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _sesiones,
              decoration: const InputDecoration(labelText: 'Días por semana'),
              items: const [1, 2, 3, 4, 5, 6, 7]
                  .map(
                    (item) => DropdownMenuItem(value: item, child: Text('$item')),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _sesiones = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _guardar, child: const Text('Guardar')),
      ],
    );
  }
}

class _HabitTemplate {
  const _HabitTemplate({
    required this.label,
    required this.title,
    required this.detail,
    required this.duration,
    required this.sessions,
    required this.priority,
    required this.icon,
  });

  final String label;
  final String title;
  final String detail;
  final int duration;
  final int sessions;
  final int priority;
  final IconData icon;
}
