import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/music_quest_service.dart';
import '../models/models.dart';
import '../l10n/app_localizations.dart';
import '../widgets/widgets.dart';

class MusicQuestsScreen extends StatefulWidget {
  const MusicQuestsScreen({super.key});

  @override
  State<MusicQuestsScreen> createState() => _MusicQuestsScreenState();
}

class _MusicQuestsScreenState extends State<MusicQuestsScreen> {
  StreamSubscription? _subscription;
  bool _isLoading = true;
  List<MusicQuestInstance> _activeQuests = [];
  Map<String, MusicQuestProgress> _activeProgress = {};
  List<MusicQuestInstance> _completedQuests = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _initialize() async {
    final questService = Provider.of<MusicQuestService>(context, listen: false);

    // Wait for service if not yet initialized
    if (!questService.isInitialized) {
      // Small delay loop or just wait if initialize() was already called in main.dart
      // Since it's called in main.dart, it should be ready soon.
      int retries = 0;
      while (!questService.isInitialized && retries < 10) {
        await Future.delayed(const Duration(milliseconds: 200));
        retries++;
      }
    }

    await _loadData();

    _subscription = questService.onQuestUpdated.listen((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final questService = Provider.of<MusicQuestService>(context, listen: false);
    
    final active = questService.getActiveQuests();
    final progress = await questService.getAllActiveProgress();
    final completed = await questService.getCompletedQuests();

    if (mounted) {
      setState(() {
        _activeQuests = active;
        _activeProgress = progress;
        _completedQuests = completed;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.musicalQuests),
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                if (_activeQuests.isEmpty && _completedQuests.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Text(l10n.noQuests),
                    ),
                  )
                else ...[
                  if (_activeQuests.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: SectionHeader(title: l10n.inProgress),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final quest = _activeQuests[index];
                            return QuestCard(
                              instance: quest,
                              progress: _activeProgress[quest.definitionId],
                            );
                          },
                          childCount: _activeQuests.length,
                        ),
                      ),
                    ),
                  ],
                  if (_completedQuests.isNotEmpty) ...[
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    SliverToBoxAdapter(
                      child: SectionHeader(title: l10n.completedStatus),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final quest = _completedQuests[index];
                            return Opacity(
                              opacity: 0.8,
                              child: QuestCard(
                                instance: quest,
                              ),
                            );
                          },
                          childCount: _completedQuests.length,
                        ),
                      ),
                    ),
                  ],
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
    );
  }
}
