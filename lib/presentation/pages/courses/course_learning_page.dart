import 'package:flutter/material.dart';

class CourseLearningPage extends StatefulWidget {
  const CourseLearningPage({super.key});

  @override
  State<CourseLearningPage> createState() => _CourseLearningPageState();
}

class _CourseLearningPageState extends State<CourseLearningPage> {
  int _activeModule = 0;
  int _activeLesson = 0;
  final List<Map<String, dynamic>> _modules = [
    {
      'id': 1,
      'title': 'Introduction to React',
      'lessons': [
        {'id': 1, 'type': 'video', 'title': 'Welcome to the Course', 'duration': '05:30', 'isPreview': true},
        {'id': 2, 'type': 'reading', 'title': 'Setting Up Your Development Environment', 'duration': '15 min read'},
        {'id': 3, 'type': 'video', 'title': 'Creating Your First React App', 'duration': '12:15'},
      ]
    },
    {
      'id': 2,
      'title': 'Components, Props, and State',
      'lessons': [
        {'id': 1, 'type': 'video', 'title': 'Understanding Functional Components', 'duration': '18:40'},
        {'id': 2, 'type': 'reading', 'title': 'Passing Data with Props', 'duration': '20 min read'},
      ]
    }
  ];

  void _selectLesson(int moduleIndex, int lessonIndex) {
    setState(() {
      _activeModule = moduleIndex;
      _activeLesson = lessonIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    final module = _modules[_activeModule];
    final lesson = module['lessons'][_activeLesson];

    return Scaffold(
      appBar: AppBar(
        title: Text(module['title']),
      ),
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 300,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(right: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _modules.length,
              itemBuilder: (context, mi) {
                final m = _modules[mi];
                return ExpansionTile(
                  initiallyExpanded: mi == _activeModule,
                  title: Text('Module ${m['id']}: ${m['title']}', style: Theme.of(context).textTheme.titleMedium),
                  children: List.generate(m['lessons'].length, (li) {
                    final l = m['lessons'][li];
                    final isActive = mi == _activeModule && li == _activeLesson;
                    return ListTile(
                      leading: Icon(l['type'] == 'video' ? Icons.play_circle_outline : Icons.article_outlined),
                      title: Text(l['title']),
                      subtitle: Text(l['duration']),
                      selected: isActive,
                      onTap: () => _selectLesson(mi, li),
                    );
                  }),
                );
              },
            ),
          ),

          // Main content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(lesson['title'], style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 12),
                  if (lesson['type'] == 'video')
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(
                        color: Colors.black12,
                        child: const Center(child: Icon(Icons.play_circle_fill, size: 64)),
                      ),
                    ),
                  if (lesson['type'] == 'reading')
                    Expanded(
                      child: SingleChildScrollView(
                        child: Text('Reading content placeholder for "${lesson['title']}"', style: Theme.of(context).textTheme.bodyLarge),
                      ),
                    ),

                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          // previous
                          if (_activeLesson > 0) {
                            _selectLesson(_activeModule, _activeLesson - 1);
                          }
                        },
                        icon: const Icon(Icons.chevron_left),
                        label: const Text('Previous'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          // mark complete -> next
                          final mi = _activeModule;
                          final li = _activeLesson;
                          if (li < _modules[mi]['lessons'].length - 1) {
                            _selectLesson(mi, li + 1);
                          } else if (mi < _modules.length - 1) {
                            _selectLesson(mi + 1, 0);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Course completed")));
                          }
                        },
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Mark as Complete'),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          // next
                          final mi = _activeModule;
                          final li = _activeLesson;
                          if (li < _modules[mi]['lessons'].length - 1) {
                            _selectLesson(mi, li + 1);
                          } else if (mi < _modules.length - 1) {
                            _selectLesson(mi + 1, 0);
                          }
                        },
                        icon: const Icon(Icons.chevron_right),
                        label: const Text('Next'),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
