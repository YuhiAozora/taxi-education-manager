import 'package:flutter/material.dart';
import '../models/education_item.dart';
import '../models/learning_record.dart';
import '../services/database_service.dart';

class EducationDetailScreen extends StatefulWidget {
  final EducationItem educationItem;

  const EducationDetailScreen({
    super.key,
    required this.educationItem,
  });

  @override
  State<EducationDetailScreen> createState() => _EducationDetailScreenState();
}

class _EducationDetailScreenState extends State<EducationDetailScreen> {
  late DateTime _startTime;
  bool _showQuiz = false;
  int _currentQuestionIndex = 0;
  int? _selectedAnswerIndex;
  bool _showExplanation = false;
  int _correctAnswers = 0;
  final List<int?> _userAnswers = [];

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _userAnswers.addAll(List.filled(widget.educationItem.quizQuestions.length, null));
  }

  Future<void> _startQuiz() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('クイズを開始'),
        content: Text('${widget.educationItem.quizQuestions.length}問のクイズを開始します。\n理解度を確認しましょう。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('開始'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _showQuiz = true;
        _currentQuestionIndex = 0;
        _selectedAnswerIndex = null;
        _showExplanation = false;
        _correctAnswers = 0;
      });
    }
  }

  void _selectAnswer(int index) {
    if (_showExplanation) return;

    setState(() {
      _selectedAnswerIndex = index;
      _userAnswers[_currentQuestionIndex] = index;
    });
  }

  void _checkAnswer() {
    if (_selectedAnswerIndex == null) return;

    final question = widget.educationItem.quizQuestions[_currentQuestionIndex];
    if (_selectedAnswerIndex == question.correctAnswerIndex) {
      _correctAnswers++;
    }

    setState(() {
      _showExplanation = true;
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < widget.educationItem.quizQuestions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswerIndex = _userAnswers[_currentQuestionIndex];
        _showExplanation = false;
      });
    } else {
      _completeQuiz();
    }
  }

  Future<void> _completeQuiz() async {
    final endTime = DateTime.now();
    final duration = endTime.difference(_startTime).inMinutes.clamp(1, 9999);
    
    final currentUser = DatabaseService.getCurrentUser();
    if (currentUser == null) return;

    final record = LearningRecord(
      id: '',
      userId: currentUser.id,
      educationItemId: widget.educationItem.id,
      completedAt: endTime,
      durationMinutes: duration,
      notes: '学習完了',
    );

    await DatabaseService.saveLearningRecord(record);

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _correctAnswers >= widget.educationItem.quizQuestions.length * 0.7
                  ? Icons.emoji_events
                  : Icons.check_circle,
              color: _correctAnswers >= widget.educationItem.quizQuestions.length * 0.7
                  ? Colors.amber
                  : Colors.green,
              size: 32,
            ),
            const SizedBox(width: 8),
            const Text('学習完了'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('お疲れ様でした!'),
            const SizedBox(height: 16),
            _buildResultRow('正解数', '$_correctAnswers / ${widget.educationItem.quizQuestions.length}'),
            _buildResultRow('正解率', '${(_correctAnswers / widget.educationItem.quizQuestions.length * 100).toStringAsFixed(0)}%'),
            _buildResultRow('学習時間', '$duration分'),
            const SizedBox(height: 16),
            if (_correctAnswers >= widget.educationItem.quizQuestions.length * 0.7)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '合格基準（70%）を達成しました!',
                        style: TextStyle(color: Colors.green),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '再度学習して理解を深めましょう',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('完了'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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

  @override
  Widget build(BuildContext context) {
    if (_showQuiz) {
      return _buildQuizView();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('教育内容'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          widget.educationItem.category,
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.educationItem.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.timer, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            '約${widget.educationItem.estimatedMinutes}分',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.quiz, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            'クイズ${widget.educationItem.quizQuestions.length}問',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Content
              Text(
                widget.educationItem.description,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.8,
                ),
              ),
              const SizedBox(height: 24),
              
              // Key points
              if (widget.educationItem.keyPoints.isNotEmpty) ...[
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lightbulb, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            Text(
                              '重要ポイント',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...widget.educationItem.keyPoints.map((point) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '• ',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  point,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              
              // Start quiz button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _startQuiz,
                  icon: const Icon(Icons.quiz),
                  label: const Text(
                    'クイズで理解度チェック',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuizView() {
    // データチェック
    if (widget.educationItem.quizQuestions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('クイズ')),
        body: const Center(
          child: Text('クイズが登録されていません'),
        ),
      );
    }

    if (_currentQuestionIndex >= widget.educationItem.quizQuestions.length) {
      return Scaffold(
        appBar: AppBar(title: const Text('クイズ')),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final question = widget.educationItem.quizQuestions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / widget.educationItem.quizQuestions.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('クイズ ${_currentQuestionIndex + 1}/${widget.educationItem.quizQuestions.length}'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('クイズを中断'),
                content: const Text('クイズを中断しますか?\n進捗は保存されません。'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('続ける'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        _showQuiz = false;
                      });
                    },
                    child: const Text('中断'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: Colors.grey.shade200,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        question.question,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ...List.generate(question.options.length, (index) {
                    final isSelected = _selectedAnswerIndex == index;
                    final isCorrect = index == question.correctAnswerIndex;
                    
                    Color? backgroundColor;
                    Color? borderColor;
                    
                    if (_showExplanation) {
                      if (isCorrect) {
                        backgroundColor = Colors.green.shade50;
                        borderColor = Colors.green;
                      } else if (isSelected) {
                        backgroundColor = Colors.red.shade50;
                        borderColor = Colors.red;
                      }
                    } else if (isSelected) {
                      backgroundColor = Colors.blue.shade50;
                      borderColor = Colors.blue;
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () => _selectAnswer(index),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            border: Border.all(
                              color: borderColor ?? Colors.grey.shade300,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? (borderColor ?? Colors.blue)
                                      : Colors.white,
                                  border: Border.all(
                                    color: borderColor ?? Colors.grey.shade400,
                                    width: 2,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    String.fromCharCode(65 + index),
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.grey.shade600,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  question.options[index],
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                              if (_showExplanation && isCorrect)
                                const Icon(Icons.check_circle, color: Colors.green),
                              if (_showExplanation && isSelected && !isCorrect)
                                const Icon(Icons.cancel, color: Colors.red),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  
                  if (_showExplanation) ...[
                    const SizedBox(height: 24),
                    Card(
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info, color: Colors.blue.shade700),
                                const SizedBox(width: 8),
                                Text(
                                  '解説',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              question.explanation,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 100), // ボタン用のスペース
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, -2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _showExplanation
                      ? _nextQuestion
                      : (_selectedAnswerIndex != null ? _checkAnswer : null),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _showExplanation
                        ? (_currentQuestionIndex < widget.educationItem.quizQuestions.length - 1
                            ? '次の問題へ'
                            : '結果を見る')
                        : '回答する',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
