import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8000/api',
);

void main() {
  runApp(const RecipeBookApp());
}

class RecipeBookApp extends StatelessWidget {
  const RecipeBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFC25A2B),
      brightness: Brightness.light,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Recipe Book',
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFBF2E8),
        textTheme: Typography.blackMountainView.apply(
              bodyColor: const Color(0xFF2D211C),
              displayColor: const Color(0xFF2D211C),
              fontFamily: 'Georgia',
            ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white.withOpacity(0.88),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xFFE7D4C4)),
          ),
        ),
      ),
      home: const RecipeHomePage(),
    );
  }
}

class RecipeHomePage extends StatefulWidget {
  const RecipeHomePage({super.key});

  @override
  State<RecipeHomePage> createState() => _RecipeHomePageState();
}

class _RecipeHomePageState extends State<RecipeHomePage> {
  final RecipeApi api = RecipeApi();
  final TextEditingController aiController = TextEditingController();

  List<Recipe> recipes = const [];
  ApiHealth? health;
  bool isLoading = true;
  bool isAiLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    refreshData();
  }

  @override
  void dispose() {
    aiController.dispose();
    super.dispose();
  }

  Future<void> refreshData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final results = await Future.wait([
        api.fetchRecipes(),
        api.fetchHealth(),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        recipes = results[0] as List<Recipe>;
        health = results[1] as ApiHealth;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> openRecipeEditor({Recipe? recipe}) async {
    final payload = await showDialog<RecipePayload>(
      context: context,
      builder: (_) => RecipeEditorDialog(recipe: recipe),
    );

    if (payload == null) {
      return;
    }

    try {
      if (recipe == null) {
        await api.createRecipe(payload);
      } else {
        await api.updateRecipe(recipe.id, payload);
      }
      await refreshData();
      if (!mounted) {
        return;
      }
      showAppMessage(recipe == null ? 'Recipe added.' : 'Recipe updated.');
    } catch (error) {
      showAppMessage(error.toString(), isError: true);
    }
  }

  Future<void> deleteRecipe(Recipe recipe) async {
    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete recipe?'),
            content: Text('Remove "${recipe.title}" from the recipe book?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF9F2B2B),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldDelete) {
      return;
    }

    try {
      await api.deleteRecipe(recipe.id);
      await refreshData();
      if (!mounted) {
        return;
      }
      showAppMessage('Recipe deleted.');
    } catch (error) {
      showAppMessage(error.toString(), isError: true);
    }
  }

  Future<void> runAiSearch() async {
    final query = aiController.text.trim();
    if (query.isEmpty) {
      showAppMessage('Type a recipe name first.', isError: true);
      return;
    }

    setState(() {
      isAiLoading = true;
    });

    try {
      final result = await api.searchRecipe(query);
      if (!mounted) {
        return;
      }

      final shouldSave = await showDialog<bool>(
            context: context,
            builder: (_) => AiRecipeDialog(result: result),
          ) ??
          false;

      if (shouldSave) {
        await api.createRecipe(result.recipe.toPayload(createdBy: 'Saved from AI'));
        await refreshData();
        if (!mounted) {
          return;
        }
        showAppMessage('AI recipe saved to your book.');
      }
    } catch (error) {
      showAppMessage(error.toString(), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          isAiLoading = false;
        });
      }
    }
  }

  void showAppMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFF7A2316) : const Color(0xFF2B5E38),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openRecipeEditor(),
        backgroundColor: const Color(0xFFC25A2B),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Recipe'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFBF2E8),
              Color(0xFFF6E6D7),
              Color(0xFFF3D6BB),
            ],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: refreshData,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              children: [
                Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  crossAxisAlignment: WrapCrossAlignment.start,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 540),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Recipe Book',
                                style: theme.textTheme.displaySmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'You can add your own recipes, edit them, delete them, or ask the built-in AI search for another recipe.',
                                style: theme.textTheme.bodyLarge?.copyWith(height: 1.4),
                              ),
                              const SizedBox(height: 20),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  _StatChip(
                                    label: 'Recipes',
                                    value: recipes.length.toString(),
                                    color: const Color(0xFF7C4D2A),
                                  ),
                                  _StatChip(
                                    label: 'Database',
                                    value: health?.databaseMode ?? 'Loading...',
                                    color: const Color(0xFF2B5E38),
                                  ),
                                  _StatChip(
                                    label: 'AI Mode',
                                    value: health?.openAiEnabled == true ? 'Live key ready' : 'Fallback mode',
                                    color: const Color(0xFF6A3E84),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 540),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AI Recipe Search',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Try something like "biryani", "ramen", "sushi bake".',
                                style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                              ),
                              const SizedBox(height: 18),
                              TextField(
                                controller: aiController,
                                onSubmitted: (_) => runAiSearch(),
                                decoration: InputDecoration(
                                  hintText: 'Search for any recipe...',
                                  filled: true,
                                  fillColor: const Color(0xFFFFFBF8),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(18),
                                    borderSide: BorderSide.none,
                                  ),
                                  prefixIcon: const Icon(Icons.auto_awesome),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  FilledButton.icon(
                                    onPressed: isAiLoading ? null : runAiSearch,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFF2D211C),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                                    ),
                                    icon: isAiLoading
                                        ? const SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(Icons.search),
                                    label: Text(isAiLoading ? 'Searching...' : 'Search Recipe'),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: isLoading ? null : refreshData,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Refresh'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (errorMessage != null)
                  Card(
                    color: const Color(0xFFFFE4DE),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(color: Color(0xFF7A2316)),
                      ),
                    ),
                  )
                else if (isLoading)
                  const Padding(
                    padding: EdgeInsets.all(30),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (recipes.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No recipes found yet. Add one or use AI search to save a new recipe.',
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                  )
                else
                  Wrap(
                    spacing: 18,
                    runSpacing: 18,
                    children: recipes
                        .map(
                          (recipe) => SizedBox(
                            width: 340,
                            child: RecipeCard(
                              recipe: recipe,
                              onView: () {
                                showDialog<void>(
                                  context: context,
                                  builder: (_) => RecipeDetailsDialog(recipe: recipe),
                                );
                              },
                              onEdit: () => openRecipeEditor(recipe: recipe),
                              onDelete: () => deleteRecipe(recipe),
                            ),
                          ),
                        )
                        .toList(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RecipeCard extends StatelessWidget {
  const RecipeCard({
    super.key,
    required this.recipe,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  final Recipe recipe;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 180,
                  child: Text(
                    recipe.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                SourceBadge(source: recipe.source),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              recipe.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.45),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _MiniInfo(label: recipe.cuisine),
                _MiniInfo(label: recipe.difficulty),
                _MiniInfo(label: '${recipe.totalMinutes} min'),
                _MiniInfo(label: '${recipe.servings} servings'),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.tonalIcon(
                  onPressed: onView,
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('View'),
                ),
                FilledButton.tonalIcon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
                FilledButton.tonalIcon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  style: FilledButton.styleFrom(
                    foregroundColor: const Color(0xFF8C1D18),
                  ),
                  label: const Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class RecipeDetailsDialog extends StatelessWidget {
  const RecipeDetailsDialog({super.key, required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    recipe.title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  SourceBadge(source: recipe.source),
                ],
              ),
              const SizedBox(height: 12),
              Text(recipe.description),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _MiniInfo(label: recipe.cuisine),
                  _MiniInfo(label: recipe.difficulty),
                  _MiniInfo(label: 'Prep ${recipe.prepMinutes} min'),
                  _MiniInfo(label: 'Cook ${recipe.cookMinutes} min'),
                  _MiniInfo(label: '${recipe.servings} servings'),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Ingredients',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ...recipe.ingredients.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('- $item'),
                  )),
              const SizedBox(height: 18),
              Text(
                'Steps',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ...recipe.steps.asMap().entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('${entry.key + 1}. ${entry.value}'),
                    ),
                  ),
              if (recipe.notes.trim().isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(
                  'Notes',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(recipe.notes),
              ],
              const SizedBox(height: 22),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AiRecipeDialog extends StatelessWidget {
  const AiRecipeDialog({super.key, required this.result});

  final AiRecipeResult result;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('AI Search Result'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  Text(
                    result.recipe.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  SourceBadge(source: result.recipe.source),
                ],
              ),
              const SizedBox(height: 10),
              Text(result.recipe.description),
              const SizedBox(height: 14),
              Text(
                'Provider: ${result.provider}${result.liveModelUsed ? ' (live AI)' : ' (fallback demo mode)'}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              Text('Ingredients', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              ...result.recipe.ingredients.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('- $item'),
                  )),
              const SizedBox(height: 12),
              Text('Steps', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              ...result.recipe.steps.asMap().entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('${entry.key + 1}. ${entry.value}'),
                    ),
                  ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Close'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.pop(context, true),
          icon: const Icon(Icons.save_alt),
          label: const Text('Save to Book'),
        ),
      ],
    );
  }
}

class RecipeEditorDialog extends StatefulWidget {
  const RecipeEditorDialog({super.key, this.recipe});

  final Recipe? recipe;

  @override
  State<RecipeEditorDialog> createState() => _RecipeEditorDialogState();
}

class _RecipeEditorDialogState extends State<RecipeEditorDialog> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  late final TextEditingController titleController;
  late final TextEditingController cuisineController;
  late final TextEditingController descriptionController;
  late final TextEditingController prepController;
  late final TextEditingController cookController;
  late final TextEditingController servingsController;
  late final TextEditingController ingredientsController;
  late final TextEditingController stepsController;
  late final TextEditingController notesController;
  late final TextEditingController createdByController;
  String difficulty = 'Easy';

  @override
  void initState() {
    super.initState();
    final recipe = widget.recipe;
    titleController = TextEditingController(text: recipe?.title ?? '');
    cuisineController = TextEditingController(text: recipe?.cuisine ?? '');
    descriptionController = TextEditingController(text: recipe?.description ?? '');
    prepController = TextEditingController(text: '${recipe?.prepMinutes ?? 15}');
    cookController = TextEditingController(text: '${recipe?.cookMinutes ?? 20}');
    servingsController = TextEditingController(text: '${recipe?.servings ?? 4}');
    ingredientsController = TextEditingController(text: recipe?.ingredients.join('\n') ?? '');
    stepsController = TextEditingController(text: recipe?.steps.join('\n') ?? '');
    notesController = TextEditingController(text: recipe?.notes ?? '');
    createdByController = TextEditingController(text: recipe?.createdBy ?? 'Student');
    difficulty = recipe?.difficulty ?? 'Easy';
  }

  @override
  void dispose() {
    titleController.dispose();
    cuisineController.dispose();
    descriptionController.dispose();
    prepController.dispose();
    cookController.dispose();
    servingsController.dispose();
    ingredientsController.dispose();
    stepsController.dispose();
    notesController.dispose();
    createdByController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.recipe != null;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 760),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? 'Edit Recipe' : 'Add Recipe',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    SizedBox(width: 320, child: _buildTextField(titleController, 'Title')),
                    SizedBox(width: 320, child: _buildTextField(cuisineController, 'Cuisine')),
                    SizedBox(
                      width: 320,
                      child: _buildTextField(createdByController, 'Created By'),
                    ),
                    SizedBox(
                      width: 320,
                      child: DropdownButtonFormField<String>(
                        value: difficulty,
                        decoration: _fieldDecoration('Difficulty'),
                        items: const ['Easy', 'Medium', 'Hard']
                            .map((level) => DropdownMenuItem(value: level, child: Text(level)))
                            .toList(),
                        onChanged: (value) => setState(() => difficulty = value ?? 'Easy'),
                      ),
                    ),
                    SizedBox(width: 205, child: _buildNumberField(prepController, 'Prep Minutes')),
                    SizedBox(width: 205, child: _buildNumberField(cookController, 'Cook Minutes')),
                    SizedBox(width: 205, child: _buildNumberField(servingsController, 'Servings')),
                  ],
                ),
                const SizedBox(height: 14),
                _buildTextField(descriptionController, 'Description', maxLines: 3),
                const SizedBox(height: 14),
                _buildTextField(
                  ingredientsController,
                  'Ingredients (one per line)',
                  maxLines: 7,
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  stepsController,
                  'Steps (one per line)',
                  maxLines: 7,
                ),
                const SizedBox(height: 14),
                _buildTextField(notesController, 'Notes', maxLines: 3, requiredField: false),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: submit,
                      child: Text(isEditing ? 'Save Changes' : 'Add Recipe'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    bool requiredField = true,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: (value) {
        if (!requiredField) {
          return null;
        }
        if ((value ?? '').trim().isEmpty) {
          return 'Required';
        }
        return null;
      },
      decoration: _fieldDecoration(label),
    );
  }

  Widget _buildNumberField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      validator: (value) {
        if ((value ?? '').trim().isEmpty) {
          return 'Required';
        }
        if (int.tryParse(value!.trim()) == null) {
          return 'Enter a number';
        }
        return null;
      },
      decoration: _fieldDecoration(label),
    );
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFFFFBF8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }

  void submit() {
    if (!formKey.currentState!.validate()) {
      return;
    }

    final payload = RecipePayload(
      title: titleController.text.trim(),
      cuisine: cuisineController.text.trim(),
      description: descriptionController.text.trim(),
      prepMinutes: int.parse(prepController.text.trim()),
      cookMinutes: int.parse(cookController.text.trim()),
      servings: int.parse(servingsController.text.trim()),
      difficulty: difficulty,
      ingredients: _splitLines(ingredientsController.text),
      steps: _splitLines(stepsController.text),
      notes: notesController.text.trim(),
      createdBy: createdByController.text.trim().isEmpty ? 'Student' : createdByController.text.trim(),
    );

    Navigator.pop(context, payload);
  }

  List<String> _splitLines(String input) {
    return input
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  const _MiniInfo({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF4E4D6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label),
    );
  }
}

class SourceBadge extends StatelessWidget {
  const SourceBadge({super.key, required this.source});

  final String source;

  @override
  Widget build(BuildContext context) {
    final color = switch (source) {
      'default' => const Color(0xFF7C4D2A),
      'user' => const Color(0xFF2B5E38),
      _ => const Color(0xFF6A3E84),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        source.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class RecipeApi {
  final http.Client _client = http.Client();

  Future<List<Recipe>> fetchRecipes() async {
    final response = await _client.get(Uri.parse('$apiBaseUrl/recipes'));
    _ensureSuccess(response);
    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
    return data.map((item) => Recipe.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<ApiHealth> fetchHealth() async {
    final response = await _client.get(Uri.parse('$apiBaseUrl/health'));
    _ensureSuccess(response);
    return ApiHealth.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Recipe> createRecipe(RecipePayload payload) async {
    final response = await _client.post(
      Uri.parse('$apiBaseUrl/recipes'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload.toJson()),
    );
    _ensureSuccess(response);
    return Recipe.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Recipe> updateRecipe(String id, RecipePayload payload) async {
    final response = await _client.put(
      Uri.parse('$apiBaseUrl/recipes/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload.toJson()),
    );
    _ensureSuccess(response);
    return Recipe.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> deleteRecipe(String id) async {
    final response = await _client.delete(Uri.parse('$apiBaseUrl/recipes/$id'));
    _ensureSuccess(response);
  }

  Future<AiRecipeResult> searchRecipe(String query) async {
    final response = await _client.post(
      Uri.parse('$apiBaseUrl/ai/search'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'query': query}),
    );
    _ensureSuccess(response);
    return AiRecipeResult.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    String message = 'Request failed with ${response.statusCode}';
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final detail = body['detail'];
      if (detail is String && detail.trim().isNotEmpty) {
        message = detail;
      }
    } catch (_) {
      // Keep the default message if the backend did not return JSON.
    }
    throw Exception(message);
  }
}

class ApiHealth {
  const ApiHealth({
    required this.status,
    required this.databaseMode,
    required this.openAiEnabled,
  });

  final String status;
  final String databaseMode;
  final bool openAiEnabled;

  factory ApiHealth.fromJson(Map<String, dynamic> json) {
    return ApiHealth(
      status: json['status'] as String? ?? 'unknown',
      databaseMode: json['database_mode'] as String? ?? 'unknown',
      openAiEnabled: json['openai_enabled'] as bool? ?? false,
    );
  }
}

class AiRecipeResult {
  const AiRecipeResult({
    required this.recipe,
    required this.provider,
    required this.liveModelUsed,
  });

  final Recipe recipe;
  final String provider;
  final bool liveModelUsed;

  factory AiRecipeResult.fromJson(Map<String, dynamic> json) {
    return AiRecipeResult(
      recipe: Recipe.fromJson(json['recipe'] as Map<String, dynamic>),
      provider: json['provider'] as String? ?? 'unknown',
      liveModelUsed: json['live_model_used'] as bool? ?? false,
    );
  }
}

class Recipe {
  const Recipe({
    required this.id,
    required this.title,
    required this.cuisine,
    required this.description,
    required this.prepMinutes,
    required this.cookMinutes,
    required this.servings,
    required this.difficulty,
    required this.ingredients,
    required this.steps,
    required this.notes,
    required this.createdBy,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String cuisine;
  final String description;
  final int prepMinutes;
  final int cookMinutes;
  final int servings;
  final String difficulty;
  final List<String> ingredients;
  final List<String> steps;
  final String notes;
  final String createdBy;
  final String source;
  final String createdAt;
  final String updatedAt;

  int get totalMinutes => prepMinutes + cookMinutes;

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] as String,
      title: json['title'] as String,
      cuisine: json['cuisine'] as String,
      description: json['description'] as String,
      prepMinutes: json['prep_minutes'] as int,
      cookMinutes: json['cook_minutes'] as int,
      servings: json['servings'] as int,
      difficulty: json['difficulty'] as String,
      ingredients: (json['ingredients'] as List<dynamic>).map((item) => item.toString()).toList(),
      steps: (json['steps'] as List<dynamic>).map((item) => item.toString()).toList(),
      notes: json['notes'] as String? ?? '',
      createdBy: json['created_by'] as String? ?? 'User',
      source: json['source'] as String? ?? 'user',
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
    );
  }

  RecipePayload toPayload({String? createdBy}) {
    return RecipePayload(
      title: title,
      cuisine: cuisine,
      description: description,
      prepMinutes: prepMinutes,
      cookMinutes: cookMinutes,
      servings: servings,
      difficulty: difficulty,
      ingredients: ingredients,
      steps: steps,
      notes: notes,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}

class RecipePayload {
  const RecipePayload({
    required this.title,
    required this.cuisine,
    required this.description,
    required this.prepMinutes,
    required this.cookMinutes,
    required this.servings,
    required this.difficulty,
    required this.ingredients,
    required this.steps,
    required this.notes,
    required this.createdBy,
  });

  final String title;
  final String cuisine;
  final String description;
  final int prepMinutes;
  final int cookMinutes;
  final int servings;
  final String difficulty;
  final List<String> ingredients;
  final List<String> steps;
  final String notes;
  final String createdBy;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'cuisine': cuisine,
      'description': description,
      'prep_minutes': prepMinutes,
      'cook_minutes': cookMinutes,
      'servings': servings,
      'difficulty': difficulty,
      'ingredients': ingredients,
      'steps': steps,
      'notes': notes,
      'created_by': createdBy,
    };
  }
}
